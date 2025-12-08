//==========================================================================================================================================
//                                                       /modules/vpc/outputs.tf
//==========================================================================================================================================

output "vpc_id" {
  value = aws_vpc.wordpress.id
}

output "vpc_cidr" {                                             # to be referenced by RDS security group
  value = aws_vpc.wordpress.cidr_block 
}

output "private_subnets_ids" {                                  # used for Secrets Manager endpoint, Lambda, ECS tasks, VPC endpoints
  value = [ for k, v in aws_subnet.main : v.id 
            if v.map_public_ip_on_launch == false ]
}

output "public_subnets_ids" {                                   # used in ALB
  value = [ for k, v in aws_subnet.main : v.id 
            if v.map_public_ip_on_launch == true ]
}

output "subnets" {                                              # Used in RDS subnet group
  value = { for k, v in aws_subnet.main : k => v.id }
}