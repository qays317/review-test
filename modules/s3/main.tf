//==========================================================================================================================================
//                                                                 S3
//==========================================================================================================================================

# S3 Bucket for WordPress Media
resource "aws_s3_bucket" "wordpress_media" {
  bucket = var.s3_bucket_name
  tags = { 
    Name = var.s3_bucket_name
    Description = "WordPress media storage"
    Project = "wordpress"
    Component = "s3"
  }
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

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Conditional bucket policy builder: CloudFront + ECS role + VPCE (only when values provided)
locals {
  # Accept either full distribution ARNs or just distribution IDs; normalize to ARNs.
  cf_arns = [
    for did in coalesce(var.cloudfront_distribution_arns, []) : (
      startswith(did, "arn:aws:cloudfront::") ?
      did :
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${did}"
    )
  ]

  cloudfront_statement = flatten([
    for arn in local.cf_arns : [
      {
        Sid = "AllowCloudFrontGetObject-${replace(arn, ":", "-")}"
        Effect = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.wordpress_media.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn"     = arn
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  ])

  # ECS task role statement (if provided)
  ecs_statement = var.ecs_task_role_arn != "" ? [
    {
      Sid       = "AllowEcsTaskRoleAccess"
      Effect    = "Allow"
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
    }
  ] : []

  # VPCE statement (if provided) — use the correct variable name
  vpce_statement = var.s3_vpc_endpoint_id != "" ? [
    {
      Sid       = "AllowVPCEAccess"
      Effect    = "Allow"
      Principal = "*"
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
  statements = concat(local.cloudfront_statement, local.ecs_statement, local.vpce_statement)
}

resource "aws_s3_bucket_policy" "wordpress_media" {
  count  = length(local.statements) > 0 ? 1 : 0
  bucket = aws_s3_bucket.wordpress_media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = local.statements
  })
}