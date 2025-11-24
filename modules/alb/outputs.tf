//==========================================================================================================================================
//                                                         /modules/alb/outputs.tf
//==========================================================================================================================================

output "target_group_arn" {                                     # For ECS service load balancer configuration
    value = aws_lb_target_group.wordpress.arn
}

output "target_group_arn_suffix" {                              # For CloudWatch Alarm
    value = aws_lb_target_group.wordpress.arn_suffix
}

output "alb_dns_name" {                                         # For CloudFront distribution origin 
    value = aws_lb.wordpress.dns_name                               
}

output "alb_arn_suffix" {                                       # For CloudWatch Alarm        
    value = aws_lb.wordpress.arn_suffix           
}

output "alb_zone_id" {                                          # For Route 53 admin subdomain record
    value = aws_lb.wordpress.zone_id
}