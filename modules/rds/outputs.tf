//==========================================================================================================================================
//                                                         /modules/rds/outputs.tf
//==========================================================================================================================================

output "rds_name" {                                             # For ECS task definition
    value = aws_db_instance.rds.identifier
}

output "wordpress_secret_arn" {                                 # For ECS execution role policy, container secrets injection, 
    value = aws_secretsmanager_secret.wordpress.arn
}
