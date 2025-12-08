output "vpc_id" {
    value = module.network.vpc_id
}

output "vpc_cidr" {
    value = module.network.vpc_cidr
}

output "public_subnets_ids" {
    value = module.network.public_subnets_ids
}

output "private_subnets_ids" {
    value = module.network.private_subnets_ids
}

