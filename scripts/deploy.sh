#!/usr/bin/env bash
# Phase 5.3: One-click deploy - build/push, Terraform apply, kubeconfig, Helm deploy
set -e
ENVIRONMENT="${1:-dev}"
REGION="${AWS_REGION:-us-east-1}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Deploying environment: $ENVIRONMENT"
"$SCRIPT_DIR/build_and_push_images.sh" "$ENVIRONMENT"
cd "$REPO_ROOT/infra/terraform"
terraform init
terraform apply -var-file="env/${ENVIRONMENT}.tfvars" -auto-approve
cd "$REPO_ROOT"
aws eks update-kubeconfig --region "$REGION" --name "$(cd infra/terraform && terraform output -raw eks_cluster_name)"
"$SCRIPT_DIR/helm_deploy.sh" "$ENVIRONMENT"
