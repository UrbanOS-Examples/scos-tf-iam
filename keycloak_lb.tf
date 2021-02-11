resource "aws_alb_target_group" "keycloak" {
  count    = var.deploy_keycloak ? 1 : 0
  name     = "keycloak-lb-tg-${terraform.workspace}"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/auth/admin/master/console"
    matcher             = "302"
    protocol            = "HTTP"
  }
}

resource "aws_alb_target_group_attachment" "keycloak_private" {
  count            = var.deploy_keycloak ? 1 : 0
  target_group_arn = aws_alb_target_group.keycloak[0].arn
  target_id        = aws_instance.keycloak_server[0].id
  port             = 8080

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb" "keycloak" {
  count              = var.deploy_keycloak ? 1 : 0
  name               = "keycloak-lb-${terraform.workspace}"
  load_balancer_type = "application"
  internal           = true
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.keycloak_lb_sg[0].id]
}

resource "aws_alb_listener" "keycloak_https" {
  count             = var.deploy_keycloak ? 1 : 0
  load_balancer_arn = aws_alb.keycloak[0].arn
  certificate_arn   = var.alb_certificate
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.keycloak[0].arn
  }
}

resource "aws_alb_listener" "keycloak_http" {
  count             = var.deploy_keycloak ? 1 : 0
  load_balancer_arn = aws_alb.keycloak[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

