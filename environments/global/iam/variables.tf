variable "primary_region" {
    type = string
}

variable "dr_region" {
    type = string
}

variable "primary_media_s3_bucket" {
    type = string
}

variable "dr_media_s3_bucket" {
    type = string
}

data "aws_caller_identity" "current" {}