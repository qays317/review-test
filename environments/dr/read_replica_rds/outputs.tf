output "wordpress_secret_arn" {
    value = aws_secretsmanager_secret.rr.arn
}