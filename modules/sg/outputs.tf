//==========================================================================================================================================
//                                                         /modules/sg/outputs.tf
//==========================================================================================================================================

output "rds_security_groups" {
    value = { for k, v in aws_security_group.main : k => v.id
              if lookup( v.tags, "Stage", "") == "RDS" }
}

output "alb_security_group_id" {
    value = try([ for k, v in aws_security_group.main : v.id
                  if lookup( v.tags, "Stage", "") == "ALB"][0], null )
}

output "ecs_security_groups" {
    value = try({for k, v in aws_security_group.main : k => v.id
                  if lookup( v.tags, "Stage", "") == "ECS"}, null) 
}

output "vpc_endpoints_security_group_id" {
    value = try([ for k, v in aws_security_group.main : v.id
                  if lookup( v.tags, "Name", "") == "vpc-endpoints-SG"][0], null ) 
}