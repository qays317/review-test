module "s3_replication" {
  source = "../../../modules/iam"

  role_name = "s3-cross-region-replication-role"
  assume_role_services = ["s3.amazonaws.com"]
  policy_name = "s3-cross-region-replication-policy"
  
  managed_policy_arns = []

  inline_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ]
      Resource = [
        "arn:aws:s3:::${var.primary_media_s3_bucket}/*"
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ]
      Resource = [
        "arn:aws:s3:::${var.dr_media_s3_bucket}/*"
      ]
    }
  ]
}