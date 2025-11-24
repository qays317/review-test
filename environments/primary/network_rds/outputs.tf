output "vpc_id" {
    value = module.network.vpc_id
}

output "vpc_cidr" {
    value = module.network.vpc_cidr
}

output "subnets" {
    value = module.network.subnets
}

output "private_subnets_ids" {
    value = module.network.private_subnets_ids
}

output "public_subnets_ids" {
    value = module.network.public_subnets_ids
}




output "rds_name" {
    value = module.rds.rds_name
}

output "wordpress_secret_arn" {
    value = module.rds.wordpress_secret_arn
}


