//==========================================================================================================================================
//                                                         /modules/alb/variables.tf
//==========================================================================================================================================

variable "vpc_id" {
    type = string
}

variable "target_group" {
    type = object({
        name = string
        health_check_enabled = bool
        health_check_interval = number
        health_check_timeout = number
        healthy_threshold = number
        unhealthy_threshold = number
        matcher = string
    })
}

variable "public_subnet_ids" {
    type = list(string)
}

variable "alb_name" {
    type = string
}

variable "alb_security_group_id" {
    type = string
}

variable "ssl_certificate_arn" {
    type = string
}
