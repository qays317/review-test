//==========================================================================================================================================
//                                                                  s3
//==========================================================================================================================================

# S3 Bucket for WordPress Media
resource "aws_s3_bucket" "wordpress_media" {
  bucket = var.s3_bucket_name
  tags = { 
    Name = var.s3_bucket_name
    Description = "WordPress media storage"
  }
  force_destroy = true
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Configuratio
resource "aws_s3_bucket_lifecycle_configuration" "wordpress_media" {
  bucket = aws_s3_bucket.wordpress_media.id  
  rule {
    id = "intelligent_tiering"
    status = "Enabled"
    filter {
      prefix = ""   
    }
    transition {
      days = 0                       
      storage_class = "INTELLIGENT_TIERING" 
    }
  }
}

data "aws_caller_identity" "current" {}

# Conditional bucket policy builder: CloudFront + ECS role + VPCE (only when values provided)
locals {
  cloudfront_statement = (
    var.cloudfront_media_distribution_arn != ""
  ) ? [
    {
      Sid = "AllowCloudFrontGetObject-${replace(var.cloudfront_media_distribution_arn, ":", "-")}"
      Effect = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.wordpress_media.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = var.cloudfront_media_distribution_arn
          "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }
  ] : []

  ecs_vpce_statement = (
    var.ecs_task_role_arn != "" && var.s3_vpc_endpoint_id != ""
  ) ? [
    {
      Sid    = "AllowEcsViaVpce"
      Effect = "Allow"
      Principal = { AWS = var.ecs_task_role_arn }
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.wordpress_media.arn,
        "${aws_s3_bucket.wordpress_media.arn}/*"
      ]
      Condition = {
        StringEquals = {
          "aws:SourceVpce" = var.s3_vpc_endpoint_id
        }
      }
    }
  ] : []

  # Final combined statements for the bucket policy
  statements = concat(local.cloudfront_statement, local.ecs_vpce_statement)

}

resource "aws_s3_bucket_policy" "wordpress_media" {
  count  = length(local.statements) > 0 ? 1 : 0
  
  bucket = aws_s3_bucket.wordpress_media.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = local.statements
  })
}