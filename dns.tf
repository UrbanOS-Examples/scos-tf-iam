locals {
  cidr_octet_1 = "${element("${split(".", "${var.vpc_cidr}")}", 0)}"
  cidr_octet_2 = "${element("${split(".", "${var.vpc_cidr}")}", 1)}"
  reverse_cidr = "${local.cidr_octet_2}.${local.cidr_octet_1}"
}

resource "aws_route53_zone" "public_hosted_reverse_zone" {
  name              = "${local.reverse_cidr}.in-addr.arpa"
  vpc_id            = "${var.vpc_id}"
  force_destroy     = true

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route53_record" "freeipa_master_host_record" {
  zone_id = "${var.zone_id}"
  name    = "${var.iam_hostname_prefix}-master"
  type    = "A"
  ttl     = 5
  records = ["${aws_instance.freeipa_master.private_ip}"]
}

resource "aws_route53_record" "freeipa_replica_host_record" {
  count   = "${var.freeipa_replica_count}"
  zone_id = "${var.zone_id}"
  name    = "${var.iam_hostname_prefix}-replica-${count.index}"
  type    = "A"
  ttl     = 5
  records = ["${element("${aws_instance.freeipa_replica.*.private_ip}", "${count.index}")}"]
}

resource "aws_route53_record" "keycloak_host_record" {
  count   = "${var.deploy_keycloak}"
  zone_id = "${var.zone_id}"
  name    = "${var.iam_hostname_prefix}-oauth"
  type    = "A"
  ttl     = 5
  records = ["${aws_instance.keycloak_server.private_ip}"]
}

resource "aws_route53_record" "keycloak_lb_record" {
  count   = "${var.deploy_keycloak}"
  zone_id = "${var.zone_id}"
  name    = "oauth"
  type    = "A"

  alias {
    name                   = "${aws_alb.keycloak.dns_name}"
    zone_id                = "${aws_alb.keycloak.zone_id}"
    evaluate_target_health = false
  }
}

locals {
  freeipa_master_octet_4 = "${element("${split(".", "${aws_instance.freeipa_master.private_ip}")}", 3)}"
  freeipa_master_octet_3 = "${element("${split(".", "${aws_instance.freeipa_master.private_ip}")}", 2)}"
}

resource "aws_route53_record" "freeipa_master_host_reverse_record" {
  zone_id = "${aws_route53_zone.public_hosted_reverse_zone.zone_id}"
  name    = "${local.freeipa_master_octet_4}.${local.freeipa_master_octet_3}"
  type    = "PTR"
  ttl     = 5
  records = ["${var.iam_hostname_prefix}-master.${var.zone_name}"]
}

resource "aws_route53_record" "freeipa_replica_host_reverse_record" {
  count   = "${var.freeipa_replica_count}"
  zone_id = "${aws_route53_zone.public_hosted_reverse_zone.zone_id}"
  # Terraform is unable to do a functional "map" transform on a list, so this cannot be broken out of the resource definition because it depends on `count.index` to parse the octets
  name    = "${element("${split(".", "${element("${aws_instance.freeipa_replica.*.private_ip}", "${count.index}")}")}", 3)}.${element("${split(".", "${element("${aws_instance.freeipa_replica.*.private_ip}", "${count.index}")}")}", 2)}"
  type    = "PTR"
  ttl     = 5
  records = ["${var.iam_hostname_prefix}-replica-${count.index}.${var.zone_name}"]
}
