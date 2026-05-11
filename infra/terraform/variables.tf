# Root variables (Phase 2.2)
variable "env" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "use_emr_on_eks" {
  description = "Enable EMR on EKS"
  type        = bool
  default     = true
}
