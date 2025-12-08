//==========================================================================================================================================
//                                                         /modules/sg/variables.tf
//==========================================================================================================================================

variable "vpc_id" {
    type = string
}

variable "vpc_cidr" {
    type = string
    default = ""
}

variable "stage_tag" {
    type = string
}

variable "security_group" {
    type = map(object({
        ingress = optional (map(object({
            from_port = number
            to_port = number
            ip_protocol = string
            cidr_block = optional(string)
            vpc_cidr = optional(bool)
            source_security_group_name = optional(string)
            prefix_list_ids = optional (list(string))
        })))
        egress = optional(map(object({
            from_port = number
            to_port = number
            ip_protocol = string
            cidr_block = optional(string)
            vpc_cidr = optional(bool)
            source_security_group_name = optional(string)
            prefix_list_ids = optional (list(string))
        })))
        tags = optional(map(string))
    }))  
}

variable "external_security_groups" {
    description = "Map of external security group IDs for cross-environment references"
    type = map(string)
    default = {}
}