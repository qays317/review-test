//==========================================================================================================================================
//                                                       /modules/vpc/variables.tf
//==========================================================================================================================================

variable "vpc" {
    type = object({
        name = string
        cidr_block = string
    })
}

variable "subnet" {
    type = map(object({
        cidr_block = string
        availability_zone = string
        map_public_ip_on_launch = bool
    }))
}

variable "route_table" {
    type = map(object({
        routes = optional(map(object({
            cidr_block = string
            gateway = optional(bool, false)
            nat_gateway = optional(bool, false)
        })))
        subnets_names = list(string)
    }))
}