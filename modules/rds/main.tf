//==========================================================================================================================================
//                                                   Subnet Group + RDS Instance
//==========================================================================================================================================

resource "aws_db_subnet_group" "wordpress" {
  name = "${var.rds_identifier}-subnet-group"
  subnet_ids = [for subnet_name in var.rds.subnets_names : var.subnets[subnet_name]]
}

resource "aws_db_instance" "rds" {
  identifier = var.rds_identifier
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
}

resource "null_resource" "tag_rds_master_secret" {
  triggers = {
    secret = aws_db_instance.rds.master_user_secret[0].secret_arn
  }

  provisioner "local-exec" {
    command = <<EOT
aws secretsmanager tag-resource \
  --secret-id ${aws_db_instance.rds.master_user_secret[0].secret_arn} \
  --tags Key=Project,Value=wordpress Key=Component,Value=rds-auth
EOT
  }
}


//==========================================================================================================================================
//                                                    Secrets + Secrets Manager Endpoint
//==========================================================================================================================================

resource "aws_secretsmanager_secret" "wordpress" {
  name = "${var.rds_identifier}-secret"
  description = "WordPress database credentials"
  recovery_window_in_days = 0
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
        Effect    = "Allow"
        Principal = "*"
        Action = "secretsmanager:*"
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
  filename = "${path.module}/lambda/db-setup.zip"     # ZIP file containing Python code
  function_name = "wordpress-db-setup"    
  role = var.lambda_role_arn
  handler = "lambda_function.lambda_handler"          # Entry point in Python code
  runtime = "python3.9"
  timeout = 900
  source_code_hash = filebase64sha256("${path.module}/lambda/db-setup.zip")   # Detecting code changes and redeploying Lambda

  vpc_config {
    subnet_ids = var.private_subnets_ids
    security_group_ids = [var.security_groups[var.lambda_security_group_name]]
  }

  environment {
    variables = {
      MASTER_SECRET_ARN = aws_db_instance.rds.master_user_secret[0].secret_arn
      WORDPRESS_SECRET_NAME = "${var.rds_identifier}-secret"
      DB_HOST = split(":", aws_db_instance.rds.endpoint)[0]
      DB_PORT = tostring(aws_db_instance.rds.port)
      WORDPRESS_DB_NAME  = var.rds.db_name
      WORDPRESS_DB_USER  = var.rds.db_username
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_vpc_endpoint.secretsmanager,
    null_resource.tag_rds_master_secret
  ]

}

resource "null_resource" "invoke_lambda_after_creation" {
  depends_on = [
    aws_lambda_function.lambda
  ]

  provisioner "local-exec" {
    command = "aws lambda invoke --function-name wordpress-db-setup /tmp/lambda_output.json"
  }
}
