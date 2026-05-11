# Phase 2.7: Wire modules (vpc → eks → data-lake → iam)
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  env      = var.env
}

module "eks" {
  source          = "./modules/eks"
  cluster_name   = var.cluster_name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  env            = var.env
  use_emr_on_eks = var.use_emr_on_eks
}

module "data_lake" {
  source = "./modules/data-lake"
  env    = var.env
}

module "iam" {
  source                   = "./modules/iam"
  cluster_oidc_issuer_url  = module.eks.cluster_oidc_issuer_url
  oidc_provider_arn        = module.eks.oidc_provider_arn
  data_lake_bucket_arn     = module.data_lake.bucket_arn
  glue_database_name       = module.data_lake.glue_database_name
  env                      = var.env
}
