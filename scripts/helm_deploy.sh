#!/usr/bin/env bash
# Phase 5.2: Deploy Airflow via Helm (optional: warn if kubectl context is not EKS)
set -e
ENVIRONMENT="${1:-dev}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALUES_FILE="$REPO_ROOT/helm/airflow/values-${ENVIRONMENT}.yaml"

if [ ! -f "$VALUES_FILE" ]; then
  echo "Values file not found: $VALUES_FILE"
  exit 1
fi

# Optional: warn if context does not look like EKS
CURRENT_CTX=$(kubectl config current-context 2>/dev/null || true)
if [ -n "$CURRENT_CTX" ] && [[ "$CURRENT_CTX" != *"eks"* ]]; then
  echo "Warning: current context '$CURRENT_CTX' does not look like EKS. Proceed? (y/N)"
  read -r r
  [ "$r" = "y" ] || [ "$r" = "Y" ] || exit 0
fi

helm repo add apache-airflow https://airflow.apache.org 2>/dev/null || true
helm repo update

# Inject Airflow IRSA role from Terraform output when available
TERRAFORM_DIR="$REPO_ROOT/infra/terraform"
AIRFLOW_IRSA_ARN=$(cd "$TERRAFORM_DIR" 2>/dev/null && terraform output -raw airflow_irsa_role_arn 2>/dev/null) || true
SET_IRSA=""
if [ -n "${AIRFLOW_IRSA_ARN:-}" ]; then
  SET_IRSA="--set serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=${AIRFLOW_IRSA_ARN}"
fi

helm upgrade --install airflow apache-airflow/airflow \
  --namespace airflow --create-namespace \
  -f "$VALUES_FILE" \
  $SET_IRSA
