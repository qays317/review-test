output "read_replica_rds_name" {
    value = aws_db_instance.read_replica.identifier
}

output "wordpress_secret_arn" {
    value = aws_secretsmanager_secret.wordpress_dr.arn
}