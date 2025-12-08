//=============================================================================================================
//     Infrastructure Variables
//=============================================================================================================

vpc_config = {
    name = "WordPress-VPC"
    cidr_block = "172.16.0.0/16"    
}

route_table_config = {
    Public-RT = {
        routes = {
            default = {
                cidr_block = "0.0.0.0/0"
                gateway = true
            }
        }
        subnets_names = ["Pub-A", "Pub-B"]
    }
    Private-RT = {
        routes = {}
        subnets_names = ["Prv-A", "Prv-B"]
    }
}


//=============================================================================================================
//     RDS Variables Values
//=============================================================================================================

rds_security_group_config = {
    RDS-SG = {
        vpc_name = "VPC-1"
        ingress= {
            mysql_access = {
                ip_protocol = "tcp"
                from_port = 3306
                to_port = 3306
                vpc_cidr = true
            }
        }
    }
    Lambda-SG = {
        vpc_name = "VPC-1"
        egress = {
            mysql_access = {
                ip_protocol = "tcp"
                from_port = 3306
                to_port = 3306
                source_security_group_name = "RDS-SG"
            }
            https_access = {                       
                ip_protocol = "tcp"
                from_port = 443
                to_port = 443
                source_security_group_name = "SecretsManager-Endpoint-SG"
            }
        }
    }
    SecretsManager-Endpoint-SG = {
        vpc_name = "VPC-1"
        ingress = {
            https_access = {
                ip_protocol = "tcp"
                from_port = 443
                to_port = 443
                vpc_cidr = true
            }
        }
    }
}

rds_config = {
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    username = "dbadmin"        # Replace with your DB admin username
    db_username = "dbuser"      # Replace with your DB username
    db_name = "wordpressDB" 
    multi_az = false
    subnets_names = ["Prv-A", "Prv-B"]
    security_group_name = "RDS-SG"
}

secretsmanager_endpoint_sg_name = "SecretsManager-Endpoint-SG"

lambda_security_group_name = "Lambda-SG"

