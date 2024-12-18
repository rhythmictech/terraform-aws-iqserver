resource "aws_security_group" "elb" {
  name_prefix = "${var.name}-elb-sg-"
  description = "Inbound ELB"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    var.elb_additional_sg_tags,
    { "Name" : "${var.name}-elb-sg" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "elb_egress" {
  description              = "Allow traffic from the ELB to the instances"
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elb.id
  source_security_group_id = aws_security_group.this.id
  to_port                  = 80
  type                     = "egress"
}

resource "aws_security_group_rule" "elb_ingress" {
  count = length(var.elb_allowed_cidr_blocks) > 0 ? 1 : 0

  cidr_blocks       = var.elb_allowed_cidr_blocks #tfsec:ignore:AWS006
  description       = "Allow traffic from the allowed ranges"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.elb.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_lb" "this" {
  name_prefix                      = "${substr(var.name, 0, 5)}-"
  drop_invalid_header_fields       = true
  enable_cross_zone_load_balancing = "true"
  internal                         = var.elb_internal
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.elb.id]
  subnets                          = var.elb_subnets
  tags                             = var.tags

  access_logs {
    bucket  = var.access_logs_bucket
    enabled = var.access_logs_enabled
    prefix  = var.access_logs_prefix
  }
}

resource "aws_lb_listener" "this" {
  certificate_arn   = var.elb_certificate
  load_balancer_arn = aws_lb.this.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = aws_lb_target_group.this.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "this" {
  name_prefix = "${substr(var.name, 0, 5)}-"
  # Nexus has a bad time if two instances are running at once, so the deregistration delay needs to be short
  deregistration_delay = 10
  port                 = "80"
  protocol             = "HTTP"
  tags                 = var.tags
  vpc_id               = var.vpc_id

  health_check {
    healthy_threshold = 2
    interval          = 15
    matcher           = "200-299,302"
    protocol          = "HTTP"
    port              = "80"
  }

  lifecycle {
    create_before_destroy = true
  }
}
