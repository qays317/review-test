//=============================================================================================================
//     Infrastructure Variables
//=============================================================================================================

vpc_config = {
    name = "WordPress-DR-VPC"
    cidr_block = "172.16.0.0/16"    
}

route_table_config = {
    DR-Public-RT = {
        routes = {
            default = {
                cidr_block = "0.0.0.0/0"
                gateway = true
            }
        }
        subnets_names = ["DR-Pub-A", "DR-Pub-B"]
    }
    DR-Private-RT = {
        subnets_names = ["DR-Prv-A", "DR-Prv-B"]
    }
}

