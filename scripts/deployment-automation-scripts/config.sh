############################################
#  AWS Regions
############################################
PRIMARY_REGION="us-east-1"
DR_REGION="ca-central-1"

############################################
#  Terraform Backend Config
############################################
TF_STATE_BUCKET_NAME="github-state-bucket-261120255"
TF_STATE_BUCKET_REGION="eu-central-1"

############################################
#  Docker / Container Config
############################################
DOCKERHUB_IMAGE="qaysalnajjad/ecs-wordpress-app:v2.3"
ECR_REPO_NAME="ecs-wordpress-app"

############################################
#  Media S3 buckets
############################################
PRIMARY_MEDIA_S3_BUCKET="wordpress-media-2001"
DR_MEDIA_S3_BUCKET="wordpress-media-dr-2001"

############################################
#  Domain and hosted zone
############################################
PRIMARY_DOMAIN="rqays.com" # Primary custom domain without www (e.g., yourdomain.com)
HOSTED_ZONE_ID="Z046647128J97ELQJFGYW"


############################################
#  SSL certificates
############################################
PRIMARY_ALB_SSL_CERTIFICATE_ARN="arn:aws:acm:us-east-1:156166604445:certificate/a0b247b3-045d-4db9-8eae-7474cdf613e0"
DR_ALB_SSL_CERTIFICATE_ARN=""
CLOUDFRONT_SSL_CERTIFICATE_ARN="arn:aws:acm:us-east-1:156166604445:certificate/a0b247b3-045d-4db9-8eae-7474cdf613e0"

