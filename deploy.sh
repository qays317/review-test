#!/bin/bash

set -e  # Exit on any error

# Configuration
# BACKEND_REGION is where Terraform state (S3 backend) lives. Default to eu-central-1 (DR region).
BACKEND_REGION="${BACKEND_REGION:-eu-central-1}"

# Deployment region for AWS CLI / Terraform provider is taken from AWS_REGION environment variable
# (the GitHub Actions job should set AWS_REGION=us-east-1 for primary deployment).
# If not set, Terraform/AWS CLI will fall back to default region behavior.
if [ -z "${AWS_REGION:-}" ]; then
  echo "WARNING: AWS_REGION not set, AWS CLI/terraform will use its default region behavior."
else
  echo "Deployment AWS region (AWS_REGION) = ${AWS_REGION}"
fi

# BUCKET_NAME (S3 for Terraform state) must be set as environment variable (we will create it in BACKEND_REGION)
if [ -z "$BUCKET_NAME" ]; then
    echo "❌ ERROR: BUCKET_NAME environment variable is required"
    echo "Local: export BUCKET_NAME=your-bucket-name"
    echo "GitHub: Set BUCKET_NAME in workflow environment"
    exit 1
fi

echo "Deploying WordPress Infrastructure..."
echo "Using S3 backend region (state): $BACKEND_REGION"
echo "Using deployment region (AWS_REGION): ${AWS_REGION:-<not-set>}"
echo "Using S3 bucket: $BUCKET_NAME"

# Check if bucket exists in BACKEND_REGION, create if not
if ! aws s3 ls "s3://$BUCKET_NAME" --region "$BACKEND_REGION" 2>/dev/null; then
    echo "Creating S3 bucket: $BUCKET_NAME in region $BACKEND_REGION"
    aws s3 mb "s3://$BUCKET_NAME" --region "$BACKEND_REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled --region "$BACKEND_REGION"
    echo "✅ S3 bucket created and versioning enabled in $BACKEND_REGION"
else
    echo "✅ S3 bucket already exists in $BACKEND_REGION"
fi

deploy_environment() {
    local env_name=$1
    local env_var_file=$2
    echo "Deploying $env_name..."
    
    # Use BACKEND_REGION for backend-config so state is stored in BACKEND_REGION.
    terraform -chdir="environments/$env_name" init -reconfigure -upgrade \
        -backend-config="bucket=$BUCKET_NAME" \
        -backend-config="key=environments/$env_name.tfstate" \
        -backend-config="region=$BACKEND_REGION"

    if [ -z "$env_var_file" ]; then    
        if ! terraform -chdir="environments/$env_name" apply -var="state_bucket=$BUCKET_NAME" -auto-approve; then
            echo "❌ Failed to deploy $env_name"
            exit 1
        fi
        echo "✅ $env_name deployed successfully"
    else
        if ! terraform -chdir="environments/$env_name" apply -var-file="$env_var_file" -var="state_bucket=$BUCKET_NAME" -auto-approve; then
            echo "❌ Failed to deploy $env_name"
            exit 1
        fi
        echo "✅ $env_name deployed successfully"
    fi
}

# Deploy sequence (unchanged)
deploy_environment "global/iam" 
deploy_environment "global/oac" 

deploy_environment "primary/network_rds" "network_rds.tfvars"
deploy_environment "primary/s3" "s3.tfvars"
deploy_environment "primary/alb" "alb.tfvars"

deploy_environment "dr/network" "network.tfvars"
deploy_environment "dr/read_replica_rds" "read_replica_rds.tfvars"
deploy_environment "dr/s3" "s3.tfvars"
deploy_environment "dr/certificate" "certificate.tfvars"
deploy_environment "dr/alb" "alb.tfvars"

deploy_environment "global/cdn_dns" "cdn_dns.tfvars"

# collect ARNs (media + app)
MEDIA_ARN=$(terraform -chdir="environments/global/cdn_dns" output -raw media_distribution_arn)
APP_ARN=$(terraform -chdir="environments/global/cdn_dns" output -raw app_distribution_arn 2>/dev/null || echo "")

# build JSON list with jq (only include non-empty items)
CF_ARNS_JSON=$(jq -nc --arg m "$MEDIA_ARN" --arg a "$APP_ARN" '[ $m, $a ] | map(select(. != ""))')

# then pass when applying s3
terraform -chdir="environments/primary/s3" apply \
  -var-file="s3.tfvars" \
  -var="cloudfront_distribution_arns=${CF_ARNS_JSON}" \
  -var="state_bucket=$BUCKET_NAME" \
  -auto-approve
terraform -chdir="environments/dr/s3" apply \
  -var-file="s3.tfvars" \
  -var="cloudfront_distribution_arns=${CF_ARNS_JSON}" \
  -var="state_bucket=$BUCKET_NAME" \
  -auto-approve

deploy_environment "primary/ecs" "ecs.tfvars"
deploy_environment "dr/ecs" "ecs.tfvars"

echo "✅ Deployment complete!"