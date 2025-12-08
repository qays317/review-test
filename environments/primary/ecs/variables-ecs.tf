//=============================================================================================================
//     ECS Variables
//=============================================================================================================

variable "ecs_security_group_config" {
  type        = map(object({
    ingress = map(object({
      from_port = number
      to_port = number
      ip_protocol = string
      source_security_group_name = optional(string)
      cidr_block = optional(string)
    }))
    egress = optional(map(object({
      from_port = number
      to_port = number
      ip_protocol = string
      cidr_block = string
    })))
  }))
}

variable "ecr_image_uri" {
  type = string
  default = ""
}

variable "ecs_cluster_name_config" {
  type = string
}

variable "ecs_task_definition_config" {
  type = map(object({
    family = string
    cpu = string
    memory = string
    rds_name = string
  }))
}

variable "ecs_service_config" {
  type = map(object({
    cluster = string
    task_definition = string
    desired_count = number
    network_configuration = object({
      security_group_name = string
    })
  }))
}

variable "vpc_endpoints_config" {
  type = map(object({
    service_name = string
    vpc_endpoint_type = string
  }))
}

variable "primary_media_s3_bucket" {
  type = string
}

variable "primary_domain" {
  type = string
}
