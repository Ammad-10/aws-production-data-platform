# Phase 2.6: Airflow IRSA role + EMR on EKS job execution role
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  oidc_host  = replace(var.cluster_oidc_issuer_url, "https://", "")
}

# Airflow IRSA: S3 (data lake), Glue, EMR job submission (uses OIDC provider from EKS module)
resource "aws_iam_role" "airflow" {
  name = "airflow-irsa-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:sub" = "system:serviceaccount:airflow:airflow"
          "${local.oidc_host}:aud"  = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "airflow" {
  name = "airflow-irsa-policy"
  role = aws_iam_role.airflow.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"
        ]
        Resource = [
          var.data_lake_bucket_arn,
          "${var.data_lake_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase", "glue:GetTable", "glue:GetPartition", "glue:CreateTable",
          "glue:UpdateTable", "glue:BatchCreatePartition"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "emr-containers:StartJobRun", "emr-containers:DescribeJobRun", "emr-containers:ListJobRuns"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# EMR on EKS job execution role: S3 + Glue for Spark
resource "aws_iam_role" "emr_job" {
  name = "emr-job-execution-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "emr_job" {
  name = "emr-job-s3-glue"
  role = aws_iam_role.emr_job.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"
        ]
        Resource = [
          var.data_lake_bucket_arn,
          "${var.data_lake_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase", "glue:GetTable", "glue:GetPartition", "glue:CreateTable",
          "glue:UpdateTable", "glue:BatchCreatePartition"
        ]
        Resource = ["*"]
      }
    ]
  })
}
