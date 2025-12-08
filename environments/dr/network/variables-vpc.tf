//=============================================================================================================
//     Network Variables
//=============================================================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

variable "vpc_config" {
    type = object({
        name = string
        cidr_block = string
    })
} 

locals {
  az_map = {
    "A" = data.aws_availability_zones.available.names[0]
    "B" = data.aws_availability_zones.available.names[1]
  }
  subnet_config = {
    DR-Pub-A ={
        cidr_block = "172.16.0.0/20"
        availability_zone = local.az_map["A"]
        map_public_ip_on_launch = true
    }
    DR-Pub-B ={
        cidr_block = "172.16.16.0/20"
        availability_zone = local.az_map["B"]
        map_public_ip_on_launch = true
    }
    DR-Prv-A ={
        cidr_block = "172.16.48.0/20"
        availability_zone = local.az_map["A"]
        map_public_ip_on_launch = false
    }
    DR-Prv-B ={
        cidr_block = "172.16.64.0/20"
        availability_zone = local.az_map["B"]
        map_public_ip_on_launch = false
    }
  }
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

