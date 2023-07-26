variable "gcp_project_id" {
  type        = string
  description = "GCP project name"
}

variable "gcp_region" {
  type        = string
  description = "GCP region"
}

variable "gcp_zone" {
  type        = string
  description = "GCP zone"
}

variable "network" {
  description = "Name or self link of the VPC used for the cluster. Use the self link for Shared VPC."
  type        = string
}

variable "subnetwork" {
  description = "VPC subnetwork name or self link."
  type        = string
}

variable "maintenance_start_time" {
  description = "Maintenance start time in RFC3339 format 'HH:MM', where HH is [00-23] and MM is [00-59] GMT."
  type        = string
  default     = "01:00"
}
