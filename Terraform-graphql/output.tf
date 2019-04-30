output "istio_network" {
  description = "Link of the Network"
  value       = "${module.istio_vpc.vpc_network_link}"
}

output "vpc_subnet1" {
  description = "Link of the Subnet 1"
  value       = "${module.istio_vpc.vpc_subnet1_link}"
}

output "vpc_subnet2" {
  description = "Link of the Subnet 2"
  value       = "${module.istio_vpc.vpc_subnet2_link}"
}

output "gke_cluster_endpoint" {
  description = "GKE Master endpoint"
  value       = "${module.gke_cluster.cluster_endpoint}"
}

/* Uncomment for Certificates of GKE Cluster
output "gke_client_certificate" {
  value = "${module.gke_cluster.client_certificate}"
}

output "gke_client_key" {
  value = "${module.gke_cluster.client_key}"
}

output "gke_client_ca_certificate" {
  value = "${module.gke_cluster.cluster_ca_certificate}"
}
*/

