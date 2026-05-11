output "airflow_irsa_role_arn" {
  description = "Airflow IRSA role ARN"
  value       = aws_iam_role.airflow.arn
}

output "emr_job_execution_role_arn" {
  description = "EMR on EKS job execution role ARN"
  value       = aws_iam_role.emr_job.arn
}
