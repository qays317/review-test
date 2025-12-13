variable "provided_ssl_certificate_arn" {                
    type = string
    default = ""
}

variable "certificate_sans" {
  type = list(string)
  default = [ "" ]
}

variable "hosted_zone_id" {                    
    type = string
}

variable "primary_domain" {
    type = string
}