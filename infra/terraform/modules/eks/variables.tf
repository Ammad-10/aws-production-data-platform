variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS"
  type        = list(string)
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "use_emr_on_eks" {
  description = "Create EMR on EKS node group and virtual cluster"
  type        = bool
  default     = true
}
