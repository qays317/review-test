############################################
#  AWS Regions
############################################
PRIMARY_REGION="us-east-1"
DR_REGION="ca-central-1"

############################################
#  Terraform Backend Config
############################################
TF_STATE_BUCKET_NAME="terraform-state-10112025"
TF_STATE_BUCKET_REGION="eu-central-1"

############################################
#  Docker / Container Config
############################################
DOCKERHUB_IMAGE="qaysalnajjad/ecs-wordpress-app:v3.4"
ECR_REPO_NAME="ecs-wordpress-app"

############################################
#  Media S3 buckets
############################################
PRIMARY_MEDIA_S3_BUCKET="wordpress-media-primary-200"
DR_MEDIA_S3_BUCKET="wordpress-media-dr-200"

############################################
#  Media S3 buckets
############################################
RDS_IDENTIFIER="wordpress-rds"

############################################
#  Domain and hosted zone
############################################
PRIMARY_DOMAIN="qays.cloud" # Primary custom domain without www (e.g., yourdomain.com)
HOSTED_ZONE_ID="Z03824873AC3XLDK55Q1"


############################################
#  SSL certificates
############################################
PRIMARY_ALB_SSL_CERTIFICATE_ARN="arn:aws:acm:us-east-1:127214183643:certificate/6cf17bfe-0c45-4195-9a30-35265c9a338a"
DR_ALB_SSL_CERTIFICATE_ARN=""
CLOUDFRONT_SSL_CERTIFICATE_ARN="arn:aws:acm:us-east-1:127214183643:certificate/6cf17bfe-0c45-4195-9a30-35265c9a338a"

