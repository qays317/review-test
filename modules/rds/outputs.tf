//==========================================================================================================================================
//                                                         /modules/rds/outputs.tf
//==========================================================================================================================================

output "rds_identifier" {                                      # For DR read replica
    value = aws_db_instance.rds.identifier
}

output "wordpress_secret_id" {                                 # For referencing in DR region
    value = aws_secretsmanager_secret.wordpress.id
}

output "wordpress_secret_arn" {                                # For container secrets injection
    value = aws_secretsmanager_secret.wordpress.arn
}
