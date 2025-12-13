############################################
#  AWS Regions
############################################
PRIMARY_REGION="us-east-1"
DR_REGION="ca-central-1"

############################################
#  Terraform Backend Config
############################################
TF_STATE_BUCKET_NAME="terraform-state-1011202555"
TF_STATE_BUCKET_REGION="eu-central-1"

############################################
#  Docker / Container Config
############################################
DOCKERHUB_IMAGE="qaysalnajjad/ecs-wordpress-app:v3.6"
ECR_REPO_NAME="ecs-wordpress-app"

############################################
#  Media S3 buckets
############################################
PRIMARY_MEDIA_S3_BUCKET="wordpress-media-primary-2004"
DR_MEDIA_S3_BUCKET="wordpress-media-dr-2004"

############################################
#  Media S3 buckets
############################################
RDS_IDENTIFIER="wordpress-rds"

############################################
#  Domain and hosted zone
############################################
HOSTED_ZONE_ID="Z0201471MCIEQVEUEMQF"
PRIMARY_DOMAIN="rqays.com" # Primary custom domain without www (e.g., yourdomain.com)
CERTIFICATE_SANs='["*.rqays.com"]'



############################################
#  SSL certificates
############################################
PRIMARY_ALB_SSL_CERTIFICATE_ARN="arn:aws:acm:us-east-1:174512274809:certificate/b2f577f7-ea2d-4035-9d6a-07fb27dbf637"
DR_ALB_SSL_CERTIFICATE_ARN=""
CLOUDFRONT_SSL_CERTIFICATE_ARN="arn:aws:acm:us-east-1:174512274809:certificate/b2f577f7-ea2d-4035-9d6a-07fb27dbf637"

