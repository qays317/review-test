output "lambda_db_setup_role_arn" {
    value = module.lambda_db_setup.role_arn
}

output "ecs_execution_role_arn" {
    value = module.ecs_execution.role_arn
}

output "ecs_task_role_arn" {
    value = module.ecs_task.role_arn 
}

output "s3_replication_role_arn" {
    value = module.s3_replication.role_arn
}