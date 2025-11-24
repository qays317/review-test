/*
===================================================================================================================================================================
===================================================================================================================================================================
      * ECS Task Role for WordPress application runtime access to AWS services.
      * Database credentials are injected as environment variables by Execution Role (no Secrets Manager access needed)
      * It will be used after container starts (during application runtime)
      * Available inside the container
      * WordPress App → Uses Task Role → Uploads to S3 → Invalidates CloudFront cache
===================================================================================================================================================================
===================================================================================================================================================================
*/

module "ecs_task" {
  source = "../../../modules/iam"

  role_name = "ecs-task-role"
  assume_role_services = ["ecs-tasks.amazonaws.com"]
  policy_name = "ecs-task-policy"
  
  managed_policy_arns = []

  inline_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:GetBucketAcl",
        "s3:GetBucketCORS",
        "s3:GetBucketPolicy",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketOwnershipControls",
        "s3:CreateMultipartUpload",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload",
        "s3:PutObjectTagging"
      ]
      Resource = [
        "arn:aws:s3:::${var.primary_media_s3_bucket}",
        "arn:aws:s3:::${var.primary_media_s3_bucket}/*",
        "arn:aws:s3:::${var.dr_media_s3_bucket}",
        "arn:aws:s3:::${var.dr_media_s3_bucket}/*"
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "s3:ListAllMyBuckets"
      ]
      Resource = ["*"]
    }
  ]
}
