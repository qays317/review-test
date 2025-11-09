#!/bin/bash

set -e

# Configuration - BUCKET_NAME should be set as environment variable
REGION="eu-central-1"

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ ERROR: BUCKET_NAME environment variable is required"
    echo "Local: export BUCKET_NAME=your-bucket-name"
    echo "GitHub: Set BUCKET_NAME in workflow environment"
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

destroy_environment() {
    local env_name=$1
    local env_var_file=$2
    
    echo "Destroying $env_name..."
    
    terraform -chdir="environments/$env_name" init -reconfigure \
        -backend-config="bucket=$BUCKET_NAME" \
        -backend-config="key=environments/$env_name.tfstate" \
        -backend-config="region=$REGION"

    if [ -z "$env_var_file" ]; then    
        if ! terraform -chdir="environments/$env_name" destroy -var="state_bucket=$BUCKET_NAME" -auto-approve; then
            echo "❌ Failed to destroy $env_name"
            exit 1
        fi
        echo "✅ $env_name destroyed successfully"
    else
        if ! terraform -chdir="environments/$env_name" destroy -var-file="$env_var_file" -var="state_bucket=$BUCKET_NAME" -auto-approve; then
            echo "❌ Failed to destroy $env_name"
            exit 1
        fi
        echo "✅ $env_name destroyed successfully"
    fi
}


#destroy_environment "dr/ecs" "ecs.tfvars"
#destroy_environment "primary/ecs" "ecs.tfvars"

#destroy_environment "dr/s3" "s3.tfvars"

#destroy_environment "global/cdn_dns" "cdn_dns.tfvars"

#destroy_environment "dr/alb" "alb.tfvars"
#destroy_environment "dr/certificate" "certificate.tfvars"
#destroy_environment "dr/read_replica_rds" "read_replica_rds.tfvars"
#destroy_environment "dr/network" "network.tfvars"

#destroy_environment "primary/alb" "alb.tfvars"
#destroy_environment "primary/s3" "s3.tfvars"
#destroy_environment "primary/network_rds" "network_rds.tfvars"

destroy_environment "global/oac" 
destroy_environment "global/iam" 


echo ""
echo "🎉 All resources have been successfully destroyed!"
echo ""
echo "Note: Some resources like S3 buckets with versioning enabled"
echo "may require manual cleanup if they contain data."