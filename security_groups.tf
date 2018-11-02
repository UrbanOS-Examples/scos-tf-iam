resource "aws_security_group" "freeipa_server_sg" {
  name   = "FreeIPA Server SG"
  vpc_id = "${var.vpc_id}"

  tags {
    Name = "IAM directory traffic"
  }
}

resource "aws_security_group_rule" "freeipa_from_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  description       = "Allow traffic from self"
  security_group_id = "${aws_security_group.freeipa_server_sg.id}"
}

resource "aws_security_group_rule" "freeipa_from_alm" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${var.management_cidr}"]
  description       = "Allow all traffic from admin VPC."
  security_group_id = "${aws_security_group.freeipa_server_sg.id}"
}

resource "aws_security_group_rule" "freeipa_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound from freeipa servers"
  security_group_id = "${aws_security_group.freeipa_server_sg.id}"
}

resource "aws_security_group_rule" "freeipa_tcp_ingress" {
  count             = "${length(split(",", local.tcp_ports))}"
  type              = "ingress"
  from_port         = "${element(split(",", local.tcp_ports), count.index)}"
  to_port           = "${element(split(",", local.tcp_ports), count.index)}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.realm_cidr}"]
  description       = "Allow inbound tcp port ${element(split(",", local.tcp_ports), count.index)}"
  security_group_id = "${aws_security_group.freeipa_server_sg.id}"
}

resource "aws_security_group_rule" "freeipa_udp_ingress" {
  count             = "${length(split(",", local.udp_ports))}"
  type              = "ingress"
  from_port         = "${element(split(",", local.udp_ports), count.index)}"
  to_port           = "${element(split(",", local.udp_ports), count.index)}"
  protocol          = "udp"
  cidr_blocks       = ["${var.realm_cidr}"]
  description       = "Allow inbound udp port ${element(split(",", local.udp_ports), count.index)}"
  security_group_id = "${aws_security_group.freeipa_server_sg.id}"
}

resource "aws_security_group_rule" "freeipa_allow_keycloak" {
  count                    = "${var.deploy_keycloak}"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = "${aws_security_group.keycloak_server_sg.id}"
  description              = "Allow keycloak to communicate with freeipa"
  security_group_id        = "${aws_security_group.freeipa_server_sg.id}"
}

resource "aws_security_group" "keycloak_server_sg" {
  count  = "${var.deploy_keycloak}"
  name   = "Keycloak Server SG"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow traffic from self"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.management_cidr}"]
    description = "Allow all traffic from admin VPC"
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.freeipa_server_sg.id}"]
    description     = "Allow all traffic from the FreeIPA servers"
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = ["${aws_security_group.keycloak_lb_sg.id}"]
    description     = "Allow all traffic from the keycloak loadbalancer"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "IAM OAuth internal"
  }
}

resource "aws_security_group" "keycloak_lb_sg" {
  count  = "${var.deploy_keycloak}"
  name   = "Keycloak Loadbalancer SG"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow traffic from self"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow keycloak http traffic"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow keycloak https traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "IAM OAuth external"
  }
}
