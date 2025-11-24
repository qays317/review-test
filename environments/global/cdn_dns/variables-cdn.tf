variable "cloudfront_distribution_config" {
    type = map(object({
        s3_bucket_name = optional(string)
        alb_origin = optional(bool)
        s3_origin = optional(bool)
        price_class = string
        cache_behavior = object({
          allowed_methods = list(string)
          cached_methods = list(string)
          ttl_min = number
          ttl_default = number
          ttl_max = number
          forward_headers = optional(list(string))
          forward_cookies = optional(string)
          forward_query_string = optional(bool)
        })
    }))
}

variable "provided_ssl_certificate_arn" {                
    type = string
}

variable "hosted_zone_id" {                    
    type = string
}

variable "primary_domain" {
    type = string
}