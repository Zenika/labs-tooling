resource "google_project_service" "compute" {
  service                    = "compute.googleapis.com"
  project                    = var.gcp_project_id
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "container" {
  service                    = "container.googleapis.com"
  project                    = var.gcp_project_id
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_compute_network" "main" {
  name                            = "vpc-labs"
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "private" {
  name                     = "private"
  ip_cidr_range            = "10.0.0.0/18"
  region                   = var.gcp_region
  network                  = google_compute_network.main.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.48.0.0/14"
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.52.0.0/20"
  }
}

# It will be used with the NAT gateway to allow VMs without public IP addresses to access the internet
# For example, Kubernetes nodes will be able to pull docker images from the docker hub.
resource "google_compute_router" "router" {
  name    = "router"
  region  = var.gcp_region
  network = google_compute_network.main.id
}

resource "google_compute_router_nat" "nat" {
  name   = "nat"
  router = google_compute_router.router.name
  region = var.gcp_region

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ips = [google_compute_address.nat.self_link]
}

resource "google_compute_address" "nat" {
  name         = "nat"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

  depends_on = [google_project_service.compute]
}
