//=============================================================================================================
//     Network Variables
//=============================================================================================================

variable "vpc_config" {
    type = object({
        name = string
        cidr_block = string
    })
}

variable "subnet_config" {
    type = map(object({
        cidr_block = string
        availability_zone = string
        map_public_ip_on_launch = bool
    }))
}

variable "route_table_config" {
    type = map(object({
        routes = optional(map(object({
            cidr_block = string
            gateway = optional(bool)
            nat_gateway = optional(bool)
            network_firewall = optional(bool)
        })))
        subnets_names = list(string)
    })) 
}

