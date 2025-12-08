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

output "rds_identifier" {
    value = module.rds.rds_identifier
}

output "wordpress_secret_id" {
    value = module.rds.wordpress_secret_id
}

output "wordpress_secret_arn" {
    value = module.rds.wordpress_secret_arn
}

