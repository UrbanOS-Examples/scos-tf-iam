resource "aws_lb" "ldap_lb" {
  name               = "${terraform.workspace}-ldap-lb"
  internal           = "true"
  load_balancer_type = "network"
  subnets            = var.subnet_ids
}

resource "aws_lb_listener" "ldaps" {
  load_balancer_arn = aws_lb.ldap_lb.arn
  port              = 636
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  protocol          = "TLS"
  certificate_arn   = var.alb_certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap_tg[0].arn
  }
}

resource "aws_lb_listener" "ldap_http" {
  load_balancer_arn = aws_lb.ldap_lb.arn
  port              = 80
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  protocol          = "TLS"
  certificate_arn   = var.alb_certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap_web_tg[0].arn
  }
}

resource "aws_lb_listener" "ldap_https" {
  load_balancer_arn = aws_lb.ldap_lb.arn
  port              = 443
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  protocol          = "TLS"
  certificate_arn   = var.alb_certificate

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap_web_tg[0].arn
  }
}

resource "aws_lb_listener" "ldap" {
  load_balancer_arn = aws_lb.ldap_lb.arn
  port              = 389
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ldap_tg[0].arn
  }
}

resource "aws_lb_target_group" "ldap_tg" {
  count    = 1
  name     = "ldap-target-group"
  vpc_id   = var.vpc_id
  port     = 389
  protocol = "TCP"
}

resource "aws_lb_target_group" "ldap_web_tg" {
  count    = 1
  name     = "ldap-web-target-group"
  vpc_id   = var.vpc_id
  port     = 443
  protocol = "TLS"
}

resource "aws_lb_target_group_attachment" "ldap" {
  target_group_arn = aws_lb_target_group.ldap_tg[0].arn
  target_id        = aws_instance.freeipa_master.id
  port             = 389
}

resource "aws_lb_target_group_attachment" "ldap_web" {
  target_group_arn = aws_lb_target_group.ldap_web_tg[0].arn
  target_id        = aws_instance.freeipa_master.id
  port             = 443
}

resource "aws_route53_record" "ldap" {
  zone_id = var.zone_id
  name    = "${var.iam_hostname_prefix}-master"
  type    = "A"

  alias {
    name                   = aws_lb.ldap_lb.dns_name
    zone_id                = aws_lb.ldap_lb.zone_id
    evaluate_target_health = false
  }

  lifecycle {
    ignore_changes = [
      name,
      allow_overwrite,
    ]
  }
}

