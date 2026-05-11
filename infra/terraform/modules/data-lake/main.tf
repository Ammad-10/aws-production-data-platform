# Phase 2.5: S3 data lake (bronze/silver/gold) + Glue database
locals {
  bucket_name = "data-platform-datalake-${var.env}"
}

resource "aws_s3_bucket" "data_lake" {
  bucket = local.bucket_name
  tags = {
    Name = local.bucket_name
    Env  = var.env
  }
}

resource "aws_s3_bucket_versioning" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Optional: block public access
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Phase 2.5: Bronze / silver / gold layout (folder markers; data written by Spark/DAGs)
resource "aws_s3_object" "bronze" {
  bucket  = aws_s3_bucket.data_lake.id
  key     = "bronze/"
  content = ""
}
resource "aws_s3_object" "silver" {
  bucket  = aws_s3_bucket.data_lake.id
  key     = "silver/"
  content = ""
}
resource "aws_s3_object" "gold" {
  bucket  = aws_s3_bucket.data_lake.id
  key     = "gold/"
  content = ""
}

# Glue database for catalog
resource "aws_glue_catalog_database" "main" {
  name        = "data_lake_${var.env}"
  description = "Data lake Glue database for ${var.env}"
  tags = {
    Env = var.env
  }
}
