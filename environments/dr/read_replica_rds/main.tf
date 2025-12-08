data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/dr/network/terraform.tfstate"
    region = var.state_bucket_region
  }
}

# Remote state for primary RDS (to get WordPress secret)
data "terraform_remote_state" "primary_rds" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key = "environments/primary/network_rds/terraform.tfstate"
    region = var.state_bucket_region
  }
}

# Get primary RDS instance info
data "aws_db_instance" "primary" {
  db_instance_identifier = data.terraform_remote_state.primary_rds.outputs.rds_identifier
  provider = aws.primary
}

resource "aws_db_instance" "read_replica" {
  identifier = "${data.terraform_remote_state.primary_rds.outputs.rds_identifier}-dr-replica"
  
  replicate_source_db = data.aws_db_instance.primary.db_instance_arn
  
  # Instance configuration
  instance_class = "db.t3.micro"
  
  # Network configuration
  db_subnet_group_name = aws_db_subnet_group.rr.name
  vpc_security_group_ids = [aws_security_group.rr.id]
  
  # Read replicas inherit most settings from source
  skip_final_snapshot = true
  
  tags = {
    Name = "WordPress-DR-ReadReplica"
    Environment = "DR"
  }
}

# Subnet group for DR
resource "aws_db_subnet_group" "rr" {
  name = "wordpress-dr-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets_ids
  
  tags = {
    Name = "WordPress DR DB subnet group"
  }
}

# Security group for RDS
resource "aws_security_group" "rr" {
  name_prefix = "wordpress-rds-dr-"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }
  
  tags = {
    Name = "WordPress-RDS-DR-SG"
  }
}

# Get primary WordPress secret to copy credentials
data "aws_secretsmanager_secret_version" "primary_wordpress" {
  provider = aws.primary
  secret_id = data.terraform_remote_state.primary_rds.outputs.wordpress_secret_id
}

# Create DR secret with same WordPress credentials
resource "aws_secretsmanager_secret" "rr" {
  name = "${data.terraform_remote_state.primary_rds.outputs.rds_identifier}-dr-replica-secret"
  description = "WordPress database credentials for DR"
  recovery_window_in_days = 0
}

# Store same WordPress credentials but with DR database host
resource "aws_secretsmanager_secret_version" "rr" {
  secret_id = aws_secretsmanager_secret.rr.id
  secret_string = jsonencode({
    username = jsondecode(data.aws_secretsmanager_secret_version.primary_wordpress.secret_string).username
    password = jsondecode(data.aws_secretsmanager_secret_version.primary_wordpress.secret_string).password
    dbname = jsondecode(data.aws_secretsmanager_secret_version.primary_wordpress.secret_string).dbname
    host = split(":", aws_db_instance.read_replica.endpoint)[0]
    port = aws_db_instance.read_replica.port
  })
}
