/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                                   ECS Cluster
===================================================================================================================================================================
===================================================================================================================================================================
*/

# Enable Container Insights at account level
resource "aws_ecs_account_setting_default" "container_insights" {
  name = "containerInsights"
  value = "enabled"
}

resource "aws_ecs_cluster" "wordpress" {
    name = var.ecs_cluster_name 
    
    setting {
      name  = "containerInsights"
      value = "enabled"
    }
    
    tags = { Name = var.ecs_cluster_name  }
}

data "aws_region" "current" {}

locals {
  container_definitions = {
    for k, v in var.ecs_task_definition : k => jsonencode([{
      name = "wordpress-container"
      image = var.ecr_image_uri
      portMappings = [{ containerPort = 80, protocol = "tcp" }]

      environment = [
        {
          name = "AWS_REGION"          # Required for AWS SDK
          value = data.aws_region.current.name
        },
        {
          name = "AWS_S3_BUCKET"       # Used by AS3CF, WP Offload Media needs bucket name
          value = var.s3_bucket_name
        },  
        {
          name = "WORDPRESS_URL"
          value = "https://${var.primary_domain}"
        },
        {
          name  = "WORDPRESS_ADMIN_URL"
          value = "https://admin.${var.primary_domain}"
        },
        {
          name  = "CLOUDFRONT_DOMAIN"
          value = var.primary_domain
        }
      ]

      secrets = [
        {
          name = "WORDPRESS_DB_HOST"
          valueFrom = "${var.wordpress_secret_arn}:host::"
        },
        {
          name = "WORDPRESS_DB_NAME"
          valueFrom = "${var.wordpress_secret_arn}:dbname::"
        },
        {
          name = "WORDPRESS_DB_USER"
          valueFrom = "${var.wordpress_secret_arn}:username::"
        },
        {
          name = "WORDPRESS_DB_PASSWORD"
          valueFrom = "${var.wordpress_secret_arn}:password::"
        }
      ]
      
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = "/ecs/${v.family}"
          "awslogs-region" = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }])
  }
}

resource "aws_ecs_task_definition" "main" {
  for_each = var.ecs_task_definition
    family = each.value.family
    network_mode = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    cpu = each.value.cpu
    memory = each.value.memory
    execution_role_arn = var.ecs_execution_role_arn
    task_role_arn = var.ecs_task_role_arn
    container_definitions = local.container_definitions[each.key]
    tags = { 
      Name = each.key
      project = "wordpress"
      principal = "ecs"
    }
}

resource "aws_ecs_service" "main" {
  for_each = var.ecs_service
    name = each.key
    cluster = aws_ecs_cluster.wordpress.id
    task_definition = aws_ecs_task_definition.main[each.value.task_definition].arn
    desired_count = each.value.desired_count
    launch_type = "FARGATE"
    enable_execute_command = true
    propagate_tags = "SERVICE"
    tags = {
      project = "wordpress"
      principal = "ecs"
    }

    network_configuration {
      subnets = var.private_subnets_ids
      security_groups = [var.security_groups[each.value.network_configuration.security_group_name]]
      assign_public_ip = false
    }

    load_balancer {
      target_group_arn = var.target_group_arn
      container_name = "wordpress-container"
      container_port = 80
    }
}



/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                               VPC Endpoints
===================================================================================================================================================================
===================================================================================================================================================================
*/

# Get private route table for Gateway endpoints
data "aws_route_tables" "private" {
  vpc_id = var.vpc_id
  filter {
    name = "tag:Name"
    values = ["*private*", "*Private*"]
  }
}

# VPC Endpoints
resource "aws_vpc_endpoint" "main" {
  for_each = var.vpc_endpoints
    vpc_id = var.vpc_id
    service_name = each.value.service_name
    vpc_endpoint_type = each.value.vpc_endpoint_type
    # Interface endpoints use subnets and security groups
    subnet_ids = each.value.vpc_endpoint_type == "Interface" ? var.private_subnets_ids : null
    security_group_ids = each.value.vpc_endpoint_type == "Interface" ? [var.vpc_endpoints_security_group_id] : null
    private_dns_enabled = each.value.vpc_endpoint_type == "Interface" ? true : null
    # Gateway endpoints use route tables
    route_table_ids = each.value.vpc_endpoint_type == "Gateway" ? data.aws_route_tables.private.ids : null
    # Tag
    tags = { Name = "${each.key}-endpoint" }
}


/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                          CloudWatch Log Group
===================================================================================================================================================================
===================================================================================================================================================================
*/

# CloudWatch Log Group for ECS tasks
resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each = var.ecs_task_definition
    name = "/ecs/${each.value.family}"
    retention_in_days = 7
    tags = { Name = "${each.key}-logs" }
  }


/*
===================================================================================================================================================================
===================================================================================================================================================================
                                                           CloudWatch Alarm
===================================================================================================================================================================
===================================================================================================================================================================
*/

# CloudWatch alarm to monitor ECS service health via ALB target group
resource "aws_cloudwatch_metric_alarm" "ecs_health_alarm" {
  alarm_name = "wordpress-health-alarm"
  alarm_description = "Monitor healthy ECS tasks"
  namespace = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"
  statistic = "Average"
  threshold = 2
  comparison_operator = "LessThanThreshold"
  period = 60
  evaluation_periods = 1
  treat_missing_data = "breaching"
  alarm_actions = []
  dimensions = {
    TargetGroup = var.target_group_arn_suffix
    LoadBalancer = var.load_balancer_arn_suffix
  }
  tags = { Name = "wordpress-health-alarm" }
}


