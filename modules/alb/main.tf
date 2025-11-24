//==========================================================================================================================================
//                                                               ALB
//==========================================================================================================================================

resource "aws_lb_target_group" "wordpress" {
  name = var.target_group.name
  vpc_id = var.vpc_id
  port = 80
  protocol = "HTTP"
  target_type = "ip"
  health_check {
    enabled = var.target_group.health_check_enabled
    path = "/"
    port = "traffic-port"
    protocol = "HTTP"
    healthy_threshold = var.target_group.healthy_threshold
    unhealthy_threshold = var.target_group.unhealthy_threshold
    interval = var.target_group.health_check_interval
    timeout = var.target_group.health_check_timeout
    matcher = var.target_group.matcher
  }
  tags = { Name = var.target_group.name }
}

resource "aws_lb" "wordpress" {
  name = var.alb_name
  load_balancer_type = "application"
  internal = false
  subnets = var.public_subnet_ids
  security_groups = [var.alb_security_group_id]
  tags = { Name = var.alb_name }
}

resource "aws_lb_listener" "wordpress" {
  load_balancer_arn = aws_lb.wordpress.arn
  
  port = 443
  protocol = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = var.ssl_certificate_arn
  
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}


