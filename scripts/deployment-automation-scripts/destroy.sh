#!/bin/bash

set -e

# Load shared configuration
source "$(dirname "$0")/config.sh"


if [ -z "$TF_STATE_BUCKET_NAME" ]; then
    echo "❌ ERROR: TF_STATE_BUCKET_NAME variable is required"
    echo "Set TF_STATE_BUCKET_NAME in config.sh"
    exit 1
fi

echo "🔥 Starting AWS ECS WordPress Infrastructure Destruction..."
echo "⚠️  WARNING: This will destroy ALL resources created by deploy.sh"
echo "⚠️  This action is IRREVERSIBLE!"
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Destruction cancelled."
    exit 1
fi
echo ""
echo "🔥 Destroying resources in reverse order..."
echo ""


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
  -var ssl_certificate_arn=$PRIMARY_ALB_SSL_CERTIFICATE_ARN"

# DR Read Replica RDS
STACK_VARS["dr/read_replica_rds"]="
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
  -var ssl_certificate_arn=$DR_ALB_SSL_CERTIFICATE_ARN"

# GLOBAL CloudFront + DNS
STACK_VARS["global/cdn_dns"]="\
  -var-file=cdn_dns.tfvars \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION \
  -var ssl_certificate_arn=$CLOUDFRONT_SSL_CERTIFICATE_ARN \
  -var hosted_zone_id=$HOSTED_ZONE_ID \
  -var primary_domain=$PRIMARY_DOMAIN"

# PRIMARY ECS
STACK_VARS["primary/ecs"]="\
  -var-file=ecs.tfvars \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION"

# DR ECS
STACK_VARS["dr/ecs"]="\
  -var-file=ecs.tfvars \
  -var state_bucket_name=$TF_STATE_BUCKET_NAME \
  -var state_bucket_region=$TF_STATE_BUCKET_REGION"

# -----------------------------
# Function to destroy a stack
# -----------------------------
destroy_stack() {
  local stack="$1"
  echo "🟦 Destroying: $stack"

  terraform -chdir="environments/$stack" init -reconfigure \
    -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
    -backend-config="key=environments/$stack/terraform.tfstate" \
    -backend-config="region=$TF_STATE_BUCKET_REGION"

  terraform -chdir="environments/$stack" destroy \
    ${STACK_VARS[$stack]} \
    -auto-approve

  echo "✅ Done: $stack"
}

# -----------------------------
# DESTROY ORDER
# -----------------------------

destroy_stack "dr/ecs"
destroy_stack "primary/ecs"

if [[ -f "runtime/primary-ecr-image-uri" ]]; then
    PRIMARY_ECR_IMAGE_URI=$(cat runtime/primary-ecr-image-uri)
    PRIMARY_IMAGE_TAG="${PRIMARY_ECR_IMAGE_URI##*:}"
    echo "Loaded image for cleanup: $PRIMARY_ECR_IMAGE_URI"
    aws ecr batch-delete-image \
      --repository-name "$ECR_REPO_NAME" \
      --image-ids imageTag="$PRIMARY_IMAGE_TAG" \
      --region "$PRIMARY_REGION" || true
else
    echo "No runtime ECR image state found in primary environment — skipping image cleanup."
fi

if [[ -f "runtime/dr-ecr-image-uri" ]]; then
    DR_ECR_IMAGE_URI=$(cat runtime/dr-ecr-image-uri)
    DR_IMAGE_TAG="${DR_ECR_IMAGE_URI##*:}"
    echo "Loaded image for cleanup: $DR_ECR_IMAGE_URI"
    aws ecr batch-delete-image \
      --repository-name "$ECR_REPO_NAME" \
      --image-ids imageTag="$DR_IMAGE_TAG" \
      --region "$DR_REGION" || true
else
    echo "No runtime ECR image state found in DR environment — skipping image cleanup."
fi

if [[ -d "${RUNTIME_DIR}" ]]; then
    echo "Removing runtime directory..."
    rm -rf "${RUNTIME_DIR}" || true
else
    echo "Runtime directory does not exist — nothing to remove."
fi

destroy_stack "global/cdn_dns"
destroy_stack "dr/alb"
destroy_stack "dr/s3"
destroy_stack "dr/read_replica_rds"
destroy_stack "primary/alb"
destroy_stack "primary/s3"
destroy_stack "dr/network"
destroy_stack "primary/network_rds"
destroy_stack "global/oac"
destroy_stack "global/iam"

echo ""
echo "🎉 All resources have been successfully destroyed!"
echo ""
echo "Note: Some resources like S3 buckets with versioning enabled"
echo "may require manual cleanup if they contain data."
