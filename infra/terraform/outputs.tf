# Root outputs (Phase 2.2) - wired after modules
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster CA data"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL for IRSA"
  value       = module.eks.cluster_oidc_issuer_url
}

output "data_lake_bucket_name" {
  description = "Data lake S3 bucket name"
  value       = module.data_lake.bucket_name
}

output "glue_database_name" {
  description = "Glue database name"
  value       = module.data_lake.glue_database_name
}

output "airflow_irsa_role_arn" {
  description = "Airflow IRSA role ARN"
  value       = module.iam.airflow_irsa_role_arn
}

output "emr_job_execution_role_arn" {
  description = "EMR on EKS job execution role ARN"
  value       = module.iam.emr_job_execution_role_arn
}

output "emr_virtual_cluster_id" {
  description = "EMR on EKS virtual cluster ID (for EmrContainerOperator)"
  value       = module.eks.emr_virtual_cluster_id
}
