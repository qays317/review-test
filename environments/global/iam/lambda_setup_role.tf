module "lambda_db_setup" {
  source = "../../../modules/iam"

  role_name = "lambda-wordpress-db-setup-role"
  assume_role_services = ["lambda.amazonaws.com"]
  policy_name = "lambda-wordpress-db-setup-policy"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
  
  inline_policy_statements = [
    # Logs
    {
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = ["arn:aws:logs:${var.primary_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/wordpress-db-setup*"]
    },

    # RDS auth secret (master password)
    {
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = ["arn:aws:secretsmanager:${var.primary_region}:${data.aws_caller_identity.current.account_id}:secret:*"],
      Condition = {
        StringEquals = {
          "aws:ResourceTag/Project" = "wordpress",
          "aws:ResourceTag/Component" = "rds-auth"
        }
      }
    },

    # Allow creating the WordPress DB secret
    {
      Effect = "Allow"
      Action = [
        "secretsmanager:PutSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = ["arn:aws:secretsmanager:${var.primary_region}:${data.aws_caller_identity.current.account_id}:secret:${var.rds_identifier}-secret*"],
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
