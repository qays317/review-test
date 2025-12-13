# stacks_config.sh

declare -A STACK_VARS

# GLOBAL IAM
STACK_VARS["global/iam"]="\
  -var primary_region=$PRIMARY_REGION \
  -var dr_region=$DR_REGION \
  -var rds_identifier=$RDS_IDENTIFIER \
  -var primary_media_s3_bucket=$PRIMARY_MEDIA_S3_BUCKET \
  -var dr_media_s3_bucket=$DR_MEDIA_S3_BUCKET"

# GLOBAL OAC (no vars needed)
STACK_VARS["global/oac"]=""

# PRIMARY NETWORK + RDS
STACK_VARS["primary/network_rds"]="\
  -var rds_identifier=$RDS_IDENTIFIER \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION \
  -var-file=network_rds.tfvars" 

# DR NETWORK
STACK_VARS["dr/network"]="-var-file=network.tfvars"

# PRIMARY S3
STACK_VARS["primary/s3"]="\
  -var s3_bucket_name=$PRIMARY_MEDIA_S3_BUCKET"

# PRIMARY ALB
STACK_VARS["primary/alb"]="\
  -var-file=alb.tfvars \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION \
  -var primary_domain=$PRIMARY_DOMAIN \
  -var hosted_zone_id=$HOSTED_ZONE_ID \
  -var certificate_sans=$CERTIFICATE_SANs \
  -var provided_ssl_certificate_arn=$PRIMARY_ALB_SSL_CERTIFICATE_ARN"
   

# DR Read Replica RDS
STACK_VARS["dr/read_replica_rds"]="\
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION"

# DR S3
STACK_VARS["dr/s3"]="\
  -var s3_bucket_name=$DR_MEDIA_S3_BUCKET \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION"

# DR ALB
STACK_VARS["dr/alb"]="\
  -var-file=alb.tfvars \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION \
  -var primary_domain=$PRIMARY_DOMAIN \
  -var hosted_zone_id=$HOSTED_ZONE_ID \
  -var certificate_sans=$CERTIFICATE_SANs \
  -var provided_ssl_certificate_arn=$DR_ALB_SSL_CERTIFICATE_ARN"

# GLOBAL CloudFront + DNS
STACK_VARS["global/cdn_dns"]="\
  -var-file=cdn_dns.tfvars \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION \
  -var provided_ssl_certificate_arn=$CLOUDFRONT_SSL_CERTIFICATE_ARN \
  -var hosted_zone_id=$HOSTED_ZONE_ID \
  -var primary_domain=$PRIMARY_DOMAIN \
  -var certificate_sans=$CERTIFICATE_SANs"

# PRIMARY ECS
STACK_VARS["primary/ecs"]="\
  -var-file=ecs.tfvars \
  -var primary_domain=$PRIMARY_DOMAIN \
  -var primary_media_s3_bucket=$PRIMARY_MEDIA_S3_BUCKET \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION"

# DR ECS
STACK_VARS["dr/ecs"]="\
  -var-file=ecs.tfvars \
  -var primary_domain=$PRIMARY_DOMAIN \
  -var dr_media_s3_bucket=$DR_MEDIA_S3_BUCKET \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION"
