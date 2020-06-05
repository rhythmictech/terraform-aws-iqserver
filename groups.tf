resource "aws_security_group" "this" {
  name_prefix = "${var.name}-iqserver-sg-"
  description = "Attached to all iqserver instances"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    { "Name" : "${var.name}-iqserver-sg" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# TODO this can probably be tightened up..
resource "aws_security_group_rule" "allow_all" {
  cidr_blocks       = ["0.0.0.0/0"] #tfsec:ignore:AWS007
  description       = "Allow outbound egress so iqserver can download rules"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.this.id
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "allow_inbound_http_from_lb" {
  description              = "Allow traffic from the load balancer"
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = aws_security_group.elb.id
  to_port                  = 80
  type                     = "ingress"
}
