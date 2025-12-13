############################################
#  AWS Regions
############################################
PRIMARY_REGION="us-east-1"
DR_REGION="ca-central-1"

############################################
#  Terraform Backend Config
############################################
TF_STATE_BUCKET_NAME="terraform-state-101120255"
TF_STATE_BUCKET_REGION="eu-central-1"

############################################
#  Docker / Container Config
############################################
DOCKERHUB_IMAGE="qaysalnajjad/ecs-wordpress-app:v3.6"
ECR_REPO_NAME="ecs-wordpress-app"

############################################
#  Media S3 buckets
############################################
PRIMARY_MEDIA_S3_BUCKET=""
DR_MEDIA_S3_BUCKET=""

############################################
#  Media S3 buckets
############################################
RDS_IDENTIFIER="wordpress-rds"

############################################
#  Domain and hosted zone
############################################
PRIMARY_DOMAIN="" # Primary custom domain without www (e.g., yourdomain.com)
HOSTED_ZONE_ID=""


############################################
#  SSL certificates
############################################
PRIMARY_ALB_SSL_CERTIFICATE_ARN=""
DR_ALB_SSL_CERTIFICATE_ARN=""
CLOUDFRONT_SSL_CERTIFICATE_ARN=""

