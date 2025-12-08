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
                source_security_group_name = "wordpress-service-SG"
            }
        }
    }
}

ecr_image_uri = ""

ecs_cluster_name_config = "wordpress-cluster"

ecs_task_definition_config = {
    wordpress-task-definition = {
        family = "wordpress-task"
        cpu = "1024"
        memory = "2048"
    }
}

ecs_service_config = {
    wordpress-service = {
        cluster = "wordpress-cluster"
        task_definition = "wordpress-task-definition"
        desired_count = 0
        network_configuration = {
          security_group_name = "wordpress-service-SG"
        }
    }
}

vpc_endpoints_config = {
    logs = {
        service_name = "com.amazonaws.ca-central-1.logs"
        vpc_endpoint_type = "Interface"
    }
    s3 = {
        service_name = "com.amazonaws.ca-central-1.s3"
        vpc_endpoint_type = "Gateway"
    }
    ecs = {
        service_name = "com.amazonaws.ca-central-1.ecs"
        vpc_endpoint_type = "Interface"
    }
    sts = {
        service_name = "com.amazonaws.ca-central-1.sts"
        vpc_endpoint_type = "Interface"
    }
    monitoring = {
        service_name = "com.amazonaws.ca-central-1.monitoring"
        vpc_endpoint_type = "Interface"
    }
    ecr_api = {
        service_name = "com.amazonaws.ca-central-1.ecr.api"
        vpc_endpoint_type = "Interface"
    }
    ecr_dkr = {
        service_name = "com.amazonaws.ca-central-1.ecr.dkr"
        vpc_endpoint_type = "Interface"
    }
    ssmmessages = {
        service_name = "com.amazonaws.ca-central-1.ssmmessages"
        vpc_endpoint_type = "Interface"
    }
    ssm = {
        service_name = "com.amazonaws.ca-central-1.ssm"
        vpc_endpoint_type = "Interface"
    }
    ec2messages = {
        service_name = "com.amazonaws.ca-central-1.ec2messages"
        vpc_endpoint_type = "Interface"
    }
    secretsmanager = {
        service_name = "com.amazonaws.ca-central-1.secretsmanager"
        vpc_endpoint_type = "Interface"
    }
}






