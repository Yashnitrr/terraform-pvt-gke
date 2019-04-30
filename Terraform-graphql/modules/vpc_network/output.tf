output "vpc_network_link" {
  value = "${google_compute_network.custom_istio_network.self_link}"
}

output "vpc_subnet1_link" {
  value = "${google_compute_subnetwork.custom_istio_subnet_1.self_link}"
}

output "vpc_subnet2_link" {
  value = "${google_compute_subnetwork.custom_istio_subnet_2.self_link}"
}
