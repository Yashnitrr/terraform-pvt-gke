output "gke_cluster_endpoint" {
  description = "GKE Master endpoint"
  value       = "${module.gke_cluster.cluster_endpoint}"
}
