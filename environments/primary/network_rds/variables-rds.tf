//=============================================================================================================
//   RDS Variables
//=============================================================================================================

variable "rds_security_group_config" {
    type = map(object({
        vpc_name = string
        ingress = optional(map(object({
            ip_protocol = string
            from_port = number
            to_port = number
            cidr_block = optional(string)
            vpc_cidr = optional(bool)
            source_security_group_name = optional(string)
        })))
        egress = optional(map (object({
            ip_protocol = string
            from_port = number
            to_port = number
            cidr_block = optional(string)
            vpc_cidr = optional(bool)
            source_security_group_name = optional(string)
        })) )
    }))
}

variable "rds_identifier" {
    type = string
}

variable "rds_config" {
    type = object({
        engine_version = string
        instance_class = string 
        multi_az = bool  
        security_group_name = string
        username = string 
        db_username = string 
        db_name = string
        subnets_names = list(string)
    })
}

variable "secretsmanager_endpoint_sg_name" {
    type = string
}

variable "lambda_security_group_name" {
    type = string
}
