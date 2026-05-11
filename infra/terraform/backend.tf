# Phase 2.1: S3 backend for Terraform state (partial config).
# Provide bucket, region, dynamodb_table via -backend-config=env/backend-dev.hcl
#   terraform init -backend-config=env/backend-dev.hcl
#
# One-time: create state bucket <your-state-bucket> and lock table <your-state-lock-table>:
#   aws s3 mb s3://<your-state-bucket> --region us-east-1
#   aws s3api put-bucket-versioning --bucket <your-state-bucket> --versioning-configuration Status=Enabled
#   aws dynamodb create-table --table-name <your-state-lock-table> --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-east-1
#
# To use local state instead: comment out the "backend \"s3\" { ... }" block in versions.tf.
