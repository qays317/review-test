output "s3_vpc_endpoint_id" {
    value = aws_vpc_endpoint.main["s3"].id
}