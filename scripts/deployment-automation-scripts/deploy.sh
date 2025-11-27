#!/bin/bash

set -e
source "$(dirname "$0")/config.sh"

# Validate TF backend bucket
if [ -z "$TF_STATE_BUCKET_NAME" ]; then
  echo "❌ ERROR: TF_STATE_BUCKET_NAME is required"; exit 1
fi

echo "Deploying WordPress Infrastructure..."
echo "Backend region: $TF_STATE_BUCKET_REGION"
echo "Deployment region: ${AWS_REGION:-<not-set>}"

echo "Checking backend S3 bucket..."
if ! aws s3 ls "s3://$TF_STATE_BUCKET_NAME" --region "$TF_STATE_BUCKET_REGION" >/dev/null 2>&1; then
  echo "Creating backend bucket..."
  aws s3 mb "s3://$TF_STATE_BUCKET_NAME" --region "$TF_STATE_BUCKET_REGION"
  aws s3api put-bucket-versioning --bucket "$TF_STATE_BUCKET_NAME" --versioning-configuration Status=Enabled --region "$TF_STATE_BUCKET_REGION"
fi

declare -A STACK_VARS

# GLOBAL IAM
STACK_VARS["global/iam"]="\
  -var primary_region=$PRIMARY_REGION \
  -var dr_region=$DR_REGION \
  -var primary_media_s3_bucket=$PRIMARY_MEDIA_S3_BUCKET \
  -var dr_media_s3_bucket=$DR_MEDIA_S3_BUCKET"

# GLOBAL OAC (no vars needed)
STACK_VARS["global/oac"]=""

# PRIMARY NETWORK + RDS
STACK_VARS["primary/network_rds"]="\
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
  -var provided_ssl_certificate_arn=$DR_ALB_SSL_CERTIFICATE_ARN"

# GLOBAL CloudFront + DNS
STACK_VARS["global/cdn_dns"]="\
  -var-file=cdn_dns.tfvars \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION \
  -var provided_ssl_certificate_arn=$CLOUDFRONT_SSL_CERTIFICATE_ARN \
  -var hosted_zone_id=$HOSTED_ZONE_ID \
  -var primary_domain=$PRIMARY_DOMAIN"

# PRIMARY ECS
STACK_VARS["primary/ecs"]="\
  -var-file=ecs.tfvars \
  -var primary_domain=$PRIMARY_DOMAIN \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION"

# DR ECS
STACK_VARS["dr/ecs"]="\
  -var-file=ecs.tfvars \
  -var primary_domain=$PRIMARY_DOMAIN \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION"

# -----------------------------
# Function to deploy a stack
# -----------------------------
deploy_stack() {
  local stack="$1"
  echo "🟦 Deploying: $stack"

  terraform -chdir="environments/$stack" init -reconfigure -upgrade \
    -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
    -backend-config="key=environments/$stack/terraform.tfstate" \
    -backend-config="region=$TF_STATE_BUCKET_REGION"

  terraform -chdir="environments/$stack" apply \
    ${STACK_VARS[$stack]} \
    -auto-approve

  echo "✅ Done: $stack"
}

# -----------------------------
# DEPLOY ORDER
# -----------------------------

deploy_stack "global/iam"
deploy_stack "global/oac"
deploy_stack "primary/network_rds"
deploy_stack "dr/network"
deploy_stack "primary/s3"
deploy_stack "primary/alb"
deploy_stack "dr/read_replica_rds"
deploy_stack "dr/s3"
deploy_stack "dr/alb"
deploy_stack "global/cdn_dns"

# Build CloudFront ARNs
MEDIA_ARN=$(terraform -chdir="environments/global/cdn_dns" output -raw media_distribution_arn)
APP_ARN=$(terraform -chdir="environments/global/cdn_dns" output -raw app_distribution_arn 2>/dev/null || echo "")
CF_ARNS_JSON=$(jq -nc --arg m "$MEDIA_ARN" --arg a "$APP_ARN" '[ $m, $a ] | map(select(. != ""))')

echo "Pushing Docker images to ECR..."
./scripts/deployment-automation-scripts/pull-docker-hub-to-ecr.sh $PRIMARY_REGION "primary"
./scripts/deployment-automation-scripts/pull-docker-hub-to-ecr.sh $DR_REGION "dr"
PRIMARY_ECR_IMAGE_URI=$(cat scripts/runtime/primary-ecr-image-uri)
DR_ECR_IMAGE_URI=$(cat scripts/runtime/dr-ecr-image-uri)

# Inject ECR images
STACK_VARS["primary/ecs"]+=" -var ecr_image_uri=$PRIMARY_ECR_IMAGE_URI"
STACK_VARS["dr/ecs"]+=" -var ecr_image_uri=$DR_ECR_IMAGE_URI"

deploy_stack "primary/ecs"
deploy_stack "dr/ecs"

# Update S3 bucket policy after ECS
S3_VPC_ENDPOINT_ID=$(terraform -chdir="environments/primary/ecs" output -raw s3_vpc_endpoint_id)
STACK_VARS["primary/s3"]+=" \
  -var cloudfront_distribution_arns=$CF_ARNS_JSON \
  -var ecs_task_role_arn=$ECS_ROLE_ARN \
  -var s3_vpc_endpoint_id=$S3_VPC_ENDPOINT_ID"

deploy_stack "primary/s3"

echo "🎉 Deployment complete!"
