data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "lambda_db_setup" {
  source = "../../../modules/iam"

  role_name = "lambda-wordpress-db-setup-role"
  policy_name = "lambda-wordpress-db-setup-policy"
  assume_role_services = ["lambda.amazonaws.com"]
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"]
  inline_policy_statements = [
    # Logs
    {
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/wordpress-db-setup*"]
    },

    # RDS auth secret (master password)
    {
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"]
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project" = "wordpress",
          "aws:ResourceTag/Component" = "secret"
        }
      }
    },

    # Allow creating the WordPress DB secret
    {
      Effect = "Allow"
      Action = [
        "secretsmanager:CreateSecret",
        "secretsmanager:PutSecretValue",
        "secretsmanager:TagResource"
      ]
      Resource = ["*"]
    },

    # VPC Networking for Lambda
    {
      Effect = "Allow"
      Action = [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ]
      Resource = ["*"]
    }
  ]

}



/*
===================================================================================================================================================================
===================================================================================================================================================================
      The following execution role will be used by ECS service to set up the task:
        -pull Docker images from Docker Hub
        -Creates CloudWatch log groups and streams
        -Retrieves secrets from Secrets Manager to inject into containers 
        -Sets up networking and task infrastructure
      It will be used before container starts (during task setup)
      Not available to the application code
      ECS Service → Uses Execution Role → Pulls image → Gets secrets → Creates container
===================================================================================================================================================================
===================================================================================================================================================================
*/

# IAM role for ECS execution

module "ecs_execution" {
  source = "../../../modules/iam"
  role_name = "ecs-execution-role"
  policy_name = "ecs-execution-policy"
  assume_role_services = ["ecs-tasks.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

  inline_policy_statements = [
    {
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = [
        "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:mysql-wordpress-secret-*",
        "arn:aws:secretsmanager:ca-central-1:${data.aws_caller_identity.current.account_id}:secret:mysql-dr-replica-wordpress-secret-*"
      ]
    },
    {
      Effect = "Allow"
      Action = [
        "secretsmanager:ListSecrets"
      ]
      Resource = ["*"]
    }
  ]
}

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

# IAM role for ECS tasks to access S3 and CloudFront. WordPress application will use this

module "ecs_task" {
  source = "../../../modules/iam"
  role_name = "ecs-task-role"
  policy_name = "ecs-task-policy"
  assume_role_services = ["ecs-tasks.amazonaws.com"]
  
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
        "arn:aws:s3:::wordpress-media-prod-200",
        "arn:aws:s3:::wordpress-media-prod-200/*",
        "arn:aws:s3:::wordpress-media-dr-200",
        "arn:aws:s3:::wordpress-media-dr-200/*"
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
