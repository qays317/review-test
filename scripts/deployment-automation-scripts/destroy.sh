#!/bin/bash

set -e

# Load shared configuration
source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/stacks_config.sh" 

if [ -z "$TF_STATE_BUCKET_NAME" ]; then
    echo "❌ ERROR: TF_STATE_BUCKET_NAME variable is required"
    echo "Set TF_STATE_BUCKET_NAME in config.sh"
    exit 1
fi

echo "🔥 Starting AWS ECS WordPress Infrastructure Destruction..."
echo "⚠️  WARNING: This will destroy ALL resources created by deploy.sh"
echo "⚠️  This action is IRREVERSIBLE!"
echo ""

# Skip confirmation when running in CI
if [[ "$CI" == "true" ]]; then
  confirm="yes"
else
  read -p "Are you sure? (yes/no): " confirm
fi

if [[ "$confirm" != "yes" ]]; then
  echo "❌ Destruction cancelled."
  exit 1
fi

echo ""
echo "🔥 Destroying resources in reverse order..."
echo ""

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

echo "🧹 Removing DB bootstrap Lambda to shorten teardown time..."
terraform -chdir="environments/primary/network_rds" destroy \
  -target=aws_lambda_function.lambda \
  -target=aws_cloudwatch_log_group.lambda_logs \
  -target=null_resource.invoke_lambda_after_creation \
  -target=null_resource.tag_rds_master_secret \
  -auto-approve || true

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
