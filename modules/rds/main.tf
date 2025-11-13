//==========================================================================================================================================
//                                                   Subnet Group + RDS Instance
//==========================================================================================================================================

resource "aws_db_subnet_group" "wordpress" {
  name = "${var.rds.identifier}-subnet-group"
  subnet_ids = [for subnet_name in var.rds.subnets_names : var.subnets[subnet_name]]
}

resource "aws_db_instance" "rds" {
  identifier = var.rds.identifier
  engine = "mysql"
  engine_version = var.rds.engine_version
  instance_class = var.rds.instance_class
  multi_az = var.rds.multi_az 
  vpc_security_group_ids = [var.security_groups[var.rds.security_group_name]]
  db_subnet_group_name = aws_db_subnet_group.wordpress.name
  publicly_accessible = false
  allocated_storage = 20    
  storage_type = "gp2"             
  storage_encrypted = false
  username = var.rds.username     
  db_name = var.rds.db_name
  manage_master_user_password = true  
  backup_retention_period = 7
  skip_final_snapshot = true
  tags = {
    project = "wordpress"
    component = "secret"
  }
}


//==========================================================================================================================================
//                                                    Secrets + Secrets Manager Endpoint
//==========================================================================================================================================

# Generate WordPress application user password - for WordPress application database access
resource "random_password" "wordpress" {
  length = 16
  special = true
}

# Create WordPress-specific secret
resource "aws_secretsmanager_secret" "wordpress" {
  name = "${var.rds.identifier}-wordpress-secret"
  description = "WordPress database credentials for ${var.rds.identifier}"
  recovery_window_in_days = 0  # Force immediate deletion (without scheduling)
  tags = {
    Project = "wordpress"
    Component = "secret"
  }
}

# Store WordPress credentials
resource "aws_secretsmanager_secret_version" "wordpress" {
  secret_id = aws_secretsmanager_secret.wordpress.id
  secret_string = jsonencode({
    username = var.rds.db_username
    password = random_password.wordpress.result
    dbname = var.rds.db_name
    host = split(":", aws_db_instance.rds.endpoint)[0]  # Remove :3306
    port = aws_db_instance.rds.port
  })
}

data "aws_region" "current" {}  

# VPC Endpoint for Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id = var.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids = var.private_subnets_ids
  security_group_ids = [var.security_groups[var.secretsmanager_endpoint_sg_name]]
  private_dns_enabled = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"     // Anyone in the VPC
        Action = "secretsmanager:GetSecretValue"
        Resource = [
          aws_secretsmanager_secret.wordpress.arn,
          aws_db_instance.rds.master_user_secret[0].secret_arn     
        ]
      }
    ]
  })
  tags = { Name = "secretsmanager-endpoint" }
}


/*
//==========================================================================================================================================
//                                                            Lambda
//==========================================================================================================================================
*/

# CloudWatch Log Group for Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name = "/aws/lambda/wordpress-db-setup"
  retention_in_days = 7
  tags = { Name = "lambda-db-setup-logs" }
}

resource "aws_lambda_function" "lambda" {
  filename = "../../../scripts/lambda/db-setup.zip"      # ZIP file containing Python code
  function_name = "wordpress-db-setup"    
  role = var.lambda_role_arn
  handler = "lambda_function.lambda_handler"          # Entry point in Python code
  runtime = "python3.9"
  timeout = 900
  source_code_hash = filebase64sha256("../../../scripts/lambda/db-setup.zip")    # Detecting code changes and redeploying Lambda

  vpc_config {
    subnet_ids = var.private_subnets_ids
    security_group_ids = [var.security_groups[var.lambda_security_group_name]]
  }

  environment {
    variables = {
      MASTER_SECRET_ARN = aws_db_instance.rds.master_user_secret[0].secret_arn
      WORDPRESS_SECRET_ARN = aws_secretsmanager_secret.wordpress.arn
    }
  }

  depends_on = [   # For function creation
    aws_cloudwatch_log_group.lambda_logs,
    aws_db_instance.rds,
    aws_secretsmanager_secret_version.wordpress,
    aws_vpc_endpoint.secretsmanager,
  ]
}

# Invoke Lambda function after RDS is ready
resource "aws_lambda_invocation" "lambda" {    
  function_name = aws_lambda_function.lambda.function_name
  input = jsonencode({})

  depends_on = [   # For function execution
    aws_db_instance.rds,
    aws_secretsmanager_secret_version.wordpress,
    aws_lambda_function.lambda
  ]
}


//==========================================================================================================================================
//                                                          Bastion Host
//==========================================================================================================================================
/*
resource "aws_instance" "bastion_host" {
  ami = var.bastion_host.ami
  instance_type = var.bastion_host.instance_type
  key_name = var.bastion_host.key_name
  subnet_id = var.subnets[var.bastion_host.subnet_name].id
  vpc_security_group_ids = [aws_security_group.main[var.bastion_host.security_group_name].id]

  iam_instance_profile = aws_iam_instance_profile.bastion_profile[var.bastion_host.name].name
  
  associate_public_ip_address = var.bastion_host.associate_public_ip_address
  user_data = templatefile("../../scripts/bastion_host_setup.tpl", {
    wordpress_secret_arn = aws_secretsmanager_secret.wordpress_credentials.arn
    rds_master_secret_arn = aws_db_instance.rds.master_user_secret[0].secret_arn
    region = data.aws_region.current.name
  })
  depends_on = [
    aws_db_instance.rds,
    aws_secretsmanager_secret.wordpress_credentials,
    aws_iam_instance_profile.bastion_profile,
    aws_iam_role_policy.bastion_secrets_policy
  ]
  tags = { Name = var.bastion_host.name }
}

# IAM role for bastion host
resource "aws_iam_role" "bastion_role" {
  name = var.bastion_host.iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Secrets Manager access
resource "aws_iam_role_policy" "bastion_secrets_policy" {
  name = "${bastion_host.name}-secrets-policy"
  role = aws_iam_role.bastion_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.wordpress_credentials.arn,
          aws_db_instance.rds.master_user_secret[0].secret_arn
        ]
      }
    ]
  })
}

# IAM instance profile for bastion host
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${bastion_host.name}-profile"
  role = aws_iam_role.bastion_role.name
}
*/