#!/usr/bin/env bash
set -euo pipefail
trap 'echo "ERROR at line $LINENO"; exit 1' ERR

# Mirror Docker Hub image -> ECR 
# Usage:
#   DOCKERHUB_IMAGE=qaysalnajjad/ecs-wordpress-app:v2.3 ECR_REPO_NAME=ecs-wordpress-app ./scripts/push-dockerhub-to-ecr.sh
#
# Optional env for Docker Hub auth:
#   DOCKERHUB_USERNAME and DOCKERHUB_TOKEN

source "$(dirname "$0")/config.sh"

AWS_REGION=$1
ENVIRONMENT=$2

# Sanity checks
command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found in PATH"; exit 2; }
command -v aws >/dev/null 2>&1 || { echo "ERROR: aws CLI not found in PATH"; exit 2; }

echo "Mirroring image from Docker Hub -> ECR"
echo "  Docker Hub image: $DOCKERHUB_IMAGE"
echo "  ECR repo name:    $ECR_REPO_NAME"
echo "  AWS region:       $AWS_REGION"

# Resolve AWS account id
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
if [ -z "$ACCOUNT_ID" ]; then
  echo "ERROR: could not determine AWS account ID. Check AWS credentials."
  exit 3
fi

ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Optional Docker Hub login to avoid rate-limits
if [ -n "${DOCKERHUB_USERNAME:-}" ] && [ -n "${DOCKERHUB_TOKEN:-}" ]; then
  echo "Logging into Docker Hub as ${DOCKERHUB_USERNAME}..."
  echo "${DOCKERHUB_TOKEN}" | docker login --username "${DOCKERHUB_USERNAME}" --password-stdin
else
  echo "No Docker Hub credentials provided — proceeding as anonymous (may hit rate limits)."
fi

# Pull from Docker Hub
echo "Pulling ${DOCKERHUB_IMAGE}..."
docker pull "${DOCKERHUB_IMAGE}"

# Ensure ECR repo exists (create if missing)
if ! aws ecr describe-repositories --repository-names "${ECR_REPO_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "ECR repository ${ECR_REPO_NAME} not found — creating..."
  aws ecr create-repository --repository-name "${ECR_REPO_NAME}" --region "${AWS_REGION}" >/dev/null
  echo "Created ECR repository ${ECR_REPO_NAME}"
else
  echo "ECR repository ${ECR_REPO_NAME} exists"
fi

# Login to ECR
echo "Logging into ECR ${ECR_REGISTRY}..."
aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

# Determine image tag (default to latest if none)
IMAGE_TAG="${DOCKERHUB_IMAGE##*:}"
if [ "$IMAGE_TAG" = "$DOCKERHUB_IMAGE" ]; then
  IMAGE_TAG="latest"
fi

TARGET="${ECR_REGISTRY}/${ECR_REPO_NAME}:${IMAGE_TAG}"

echo "Tagging ${DOCKERHUB_IMAGE} -> ${TARGET}"
docker tag "${DOCKERHUB_IMAGE}" "${TARGET}"

echo "Pushing ${TARGET} to ECR..."
docker push "${TARGET}"


mkdir -p scripts/runtime
echo
echo "SUCCESS: pushed image to ECR:"
echo "${TARGET}"
echo "${TARGET}" > scripts/runtime/${ENVIRONMENT}-ecr-image-uri
export ECR_PUSHED_IMAGE_URI="${TARGET}"
