locals {
  repositories = ["ethis-website"]
}

module "vpc" {
  source = "./modules/terraform-gcp-vpc"

  gcp_project_id = var.gcp_project_id
  gcp_region     = var.gcp_region
}


module "gke" {
  source     = "./modules/terraform-gcp-gke"
  depends_on = [module.vpc]

  gcp_zone       = var.gcp_zone
  gcp_region     = var.gcp_region
  gcp_project_id = var.gcp_project_id
  subnetwork     = module.vpc.subnetwork
  network        = module.vpc.network
}
