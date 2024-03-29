terraform {
  required_version = "~> 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.75.0"
    }
  }

  backend "gcs" {
    bucket = "zenika-labs-bucket-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  credentials = file(var.gcp_auth_file)

  region  = var.gcp_region
  project = var.gcp_project_id
}
