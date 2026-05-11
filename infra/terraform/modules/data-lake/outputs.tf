output "bucket_name" {
  description = "Data lake S3 bucket name"
  value       = aws_s3_bucket.data_lake.id
}

output "bucket_arn" {
  description = "Data lake S3 bucket ARN"
  value       = aws_s3_bucket.data_lake.arn
}

output "glue_database_name" {
  description = "Glue database name"
  value       = aws_glue_catalog_database.main.name
}
