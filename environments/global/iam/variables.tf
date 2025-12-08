variable "primary_region" {
    type = string
}

data "aws_caller_identity" "current" {}

variable "dr_region" {
    type = string
}

variable "rds_identifier" {
    type = string
}

variable "primary_media_s3_bucket" {
    type = string
}

variable "dr_media_s3_bucket" {
    type = string
}