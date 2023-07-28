output "network" {
  value       = google_compute_network.main.self_link
  description = "The self-link of the Google Cloud Compute Engine network created."
}

output "subnetwork" {
  value       = google_compute_subnetwork.private.self_link
  description = "The self-link of the Google Cloud Compute Engine subnetwork created."
}
