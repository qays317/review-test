//==========================================================================================================================================
//                                                         /modules/acm/variables.tf
//==========================================================================================================================================

variable "domain_name" {
  type = string
}

variable "subject_alternative_names" {
  type = list(string)
}

variable "hosted_zone_id" {
  type = string
}

variable "environment" {
  type = string
}