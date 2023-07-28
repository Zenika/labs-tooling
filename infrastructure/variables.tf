# GCP authentication file
variable "gcp_auth_file" {
  type        = string
  description = "GCP authentication file"
}

variable "gcp_region" {
  type        = string
  description = "GCP region"
  default     = "europe-west1"
}

variable "gcp_zone" {
  type        = string
  description = "GCP zone"
  default     = "europe-west1-b"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP project name"
}
