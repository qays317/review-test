ecs_security_group_config = {
    wordpress-service-SG = {
        ingress = {
            http = {
                from_port = 80
                to_port = 80 
                ip_protocol = "tcp"
                source_security_group_name = "ALB-SG"
            }
        }
        egress = {
            all = {
                from_port = 0
                to_port = 0
                ip_protocol = "-1"
                cidr_block = "0.0.0.0/0"
            }
        }
    }
    vpc-endpoints-SG = {
        ingress = {
            https = {
                ip_protocol = "tcp"
                from_port = 443
                to_port = 443
                //cidr_block = "172.16.0.0/16"
                source_security_group_name = "wordpress-service-SG"
            }
        }
    }
}

ecs_cluster_name_config = "wordpress-cluster"

ecs_task_definition_config = {
    wordpress-task-definition = {
        family = "wordpress-task"
        cpu = "1024"
        memory = "2048"
        rds_name = "mysql"
    }
}

ecs_service_config = {
    wordpress-service = {
        cluster = "wordpress-cluster"
        task_definition = "wordpress-task-definition"
        desired_count = 2
        network_configuration = {
          security_group_name = "wordpress-service-SG"
        }
    }
}

vpc_endpoints_config = {
    logs = {
        service_name = "com.amazonaws.us-east-1.logs"
        vpc_endpoint_type = "Interface"
    }
    s3 = {
        service_name = "com.amazonaws.us-east-1.s3"
        vpc_endpoint_type = "Gateway"
    }
    ecs = {
        service_name = "com.amazonaws.us-east-1.ecs"
        vpc_endpoint_type = "Interface"
    }
    sts = {
        service_name = "com.amazonaws.us-east-1.sts"
        vpc_endpoint_type = "Interface"
    }
    monitoring = {
        service_name = "com.amazonaws.us-east-1.monitoring"
        vpc_endpoint_type = "Interface"
    }
    ecr_api = {
        service_name = "com.amazonaws.us-east-1.ecr.api"
        vpc_endpoint_type = "Interface"
    }
    ecr_dkr = {
        service_name = "com.amazonaws.us-east-1.ecr.dkr"
        vpc_endpoint_type = "Interface"
    }
    ssmmessages = {
        service_name = "com.amazonaws.us-east-1.ssmmessages"
        vpc_endpoint_type = "Interface"
    }
    ssm = {
        service_name = "com.amazonaws.us-east-1.ssm"
        vpc_endpoint_type = "Interface"
    }
    ec2messages = {
        service_name = "com.amazonaws.us-east-1.ec2messages"
        vpc_endpoint_type = "Interface"
    }
}
