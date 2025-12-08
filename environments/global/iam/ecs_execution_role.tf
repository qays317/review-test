/*
===================================================================================================================================================================
===================================================================================================================================================================
      The following execution role will be used by ECS service to set up the task:
        -pull Docker images from ECR
        -Creates CloudWatch log groups and streams
        -Retrieves secrets from Secrets Manager to inject into containers 
        -Sets up networking and task infrastructure
      It will be used before container starts (during task setup)
      Not available to the application code
      ECS Service → Uses Execution Role → Pulls image → Gets secrets → Creates container
===================================================================================================================================================================
===================================================================================================================================================================
*/

module "ecs_execution" {
  source = "../../../modules/iam"

  role_name = "ecs-execution-role"
  assume_role_services = ["ecs-tasks.amazonaws.com"]
  policy_name = "ecs-execution-policy"

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
        "arn:aws:secretsmanager:${var.primary_region}:${data.aws_caller_identity.current.account_id}:secret:${var.rds_identifier}-secret*",
        "arn:aws:secretsmanager:${var.dr_region}:${data.aws_caller_identity.current.account_id}:secret:${var.rds_identifier}-dr-replica-secret*"
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
