variable "cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  type        = string
}

variable "oidc_provider_arn" {
  description = "EKS OIDC provider ARN for IRSA"
  type        = string
}

variable "data_lake_bucket_arn" {
  description = "Data lake S3 bucket ARN"
  type        = string
}

variable "glue_database_name" {
  description = "Glue database name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}
