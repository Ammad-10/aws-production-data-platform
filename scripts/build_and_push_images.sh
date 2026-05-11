#!/usr/bin/env bash
# Phase 5.1: Build Airflow (and optional Spark) image, tag for ECR, push
set -e
ENVIRONMENT="${1:-dev}"
TAG="${2:-latest}"
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Building and pushing images for environment: $ENVIRONMENT"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"

# Build the image yourself first, e.g.:
#   docker build -t $ECR_URI/<your-ecr-namespace>/airflow:$TAG -f airflow-docker/Dockerfile airflow-docker
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_URI="$ECR_URI/<your-ecr-namespace>/airflow:$TAG"

# Push (image must already be built and tagged as $IMAGE_URI)
docker push "$IMAGE_URI"
