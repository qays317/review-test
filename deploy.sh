#!/bin/bash

set -e  # Exit on any error

# Configuration - BUCKET_NAME should be set as environment variable
REGION="eu-central-1"

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ ERROR: BUCKET_NAME environment variable is required"
    echo "Local: export BUCKET_NAME=your-bucket-name"
    echo "GitHub: Set BUCKET_NAME in workflow environment"
    exit 1
fi

echo "Deploying WordPress Infrastructure..."
echo "Using S3 bucket: $BUCKET_NAME"

# Check if bucket exists, create if not
if ! aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    echo "Creating S3 bucket: $BUCKET_NAME"
    aws s3 mb "s3://$BUCKET_NAME" --region $REGION
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
    echo "✅ S3 bucket created and versioning enabled"
else
    echo "✅ S3 bucket already exists"
fi

deploy_environment() {
    local env_name=$1
    local env_var_file=$2
    echo "Deploying $env_name..."
    
    # Always override backend config with variables
    terraform -chdir="environments/$env_name" init -reconfigure -upgrade \
        -backend-config="bucket=$BUCKET_NAME" \
        -backend-config="key=environments/$env_name.tfstate" \
        -backend-config="region=$REGION"

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
CLOUDFRONT_ARN=$(terraform -chdir="environments/global/cdn_dns" output -raw media_distribution_arn)
terraform -chdir="environments/primary/s3" apply \
  -var-file="s3.tfvars" \
  -var="cloudfront_media_distribution_arn=$CLOUDFRONT_ARN" \
  -var="state_bucket=$BUCKET_NAME" \
  -auto-approve

deploy_environment "primary/ecs" "ecs.tfvars"
deploy_environment "dr/ecs" "ecs.tfvars"

echo "✅ Deployment complete!"