alb_security_group_config = {
    ALB-SG = {
        ingress = {/*
            https_cloudfront = {
                from_port = 443
                to_port = 443
                ip_protocol = "tcp"
                prefix_list_ids = ["pl-38a64351"]
            }*/
            https_admin = {
                from_port = 443
                to_port = 443
                ip_protocol = "tcp"
                cidr_block = "0.0.0.0/0"
            }
        }
        egress = {
            ecs_access = {
                from_port = 80
                to_port = 80
                ip_protocol = "tcp"
                vpc_cidr = true
            }
        }
    }
}

target_group_config = {
    name = "wordpress-tg"
    health_check_enabled = true
    health_check_interval = 30
    health_check_timeout = 10
    healthy_threshold = 2
    unhealthy_threshold = 5
    matcher = "200,302"
} 

alb_name = "wordpress-alb"
