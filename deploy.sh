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

export -f deploy_environment
export BACKEND_REGION
export BUCKET_NAME
export AWS_REGION
export AWS_DEFAULT_REGION="$AWS_REGION"


parallel --jobs 2 --ungroup --tag deploy_environment ::: "global/iam" "global/oac"

#deploy_environment "global/iam"
ECS_ROLE_ARN=$(terraform -chdir="environments/global/iam" output -raw ecs_task_role_arn 2>/dev/null || echo "")
echo "Captured ECS_ROLE_ARN=$ECS_ROLE_ARN"
echo "Captured CF ARNs: $CF_ARNS_JSON"

parallel --jobs 2 --ungroup --tag deploy_environment ::: "primary/network_rds" "dr/network" :::+ "network_rds.tfvars" "network.tfvars"

parallel --jobs 2 --ungroup --tag deploy_environment ::: "primary/s3" "primary/alb" :::+ "s3.tfvars" "alb.tfvars"

parallel --jobs 3 --ungroup --tag deploy_environment ::: "dr/read_replica_rds" "dr/certificate" "dr/s3" :::+ "read_replica_rds.tfvars" "certificate.tfvars" "s3.tfvars"

deploy_environment "dr/alb" "alb.tfvars"

deploy_environment "global/cdn_dns" "cdn_dns.tfvars"

# collect ARNs (media + app)
MEDIA_ARN=$(terraform -chdir="environments/global/cdn_dns" output -raw media_distribution_arn)
APP_ARN=$(terraform -chdir="environments/global/cdn_dns" output -raw app_distribution_arn 2>/dev/null || echo "")

# build JSON list with jq (only include non-empty items)
CF_ARNS_JSON=$(jq -nc --arg m "$MEDIA_ARN" --arg a "$APP_ARN" '[ $m, $a ] | map(select(. != ""))')


parallel --jobs 2 --ungroup --tag deploy_environment ::: "primary/ecs" "dr/ecs" :::+ "ecs.tfvars" "ecs.tfvars" 

S3_VPC_ENDPOINT_ID=$(terraform -chdir="environments/primary/ecs" output -raw s3_vpc_endpoint_id 2>/dev/null || echo "")
echo "Captured S3_VPC_ENDPOINT_ID=$S3_VPC_ENDPOINT_ID"


echo "Re-applying S3 to update bucket policies with CloudFront and ECS role..."
terraform -chdir="environments/primary/s3" init -reconfigure -upgrade -backend-config="bucket=$BUCKET_NAME" -backend-config="key=environments/primary/s3.tfstate" -backend-config="region=$BACKEND_REGION"
terraform -chdir="environments/primary/s3" apply \
  -var-file="s3.tfvars" \
  -var="cloudfront_distribution_arns=${CF_ARNS_JSON}" \
  -var="ecs_task_role_arn=${ECS_ROLE_ARN}" \
  -var="s3_vpc_endpoint_id=${S3_VPC_ENDPOINT_ID}" \
  -var="state_bucket=$BUCKET_NAME" \
  -auto-approve

echo "✅ Deployment complete!"