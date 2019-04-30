// The gke_cluster module creates a GKE cluster over the above network, and subnet

module "gke_cluster" {
  source = "./modules/gke_cluster"

  project = "${var.project}"
  region  = "${var.region}"

  vpc_network_name = "${var.vpc_network_name}"
  vpc_subnet_name  = "${var.vpc_subnet_name}"

  master_cidr_range     = "${var.master_cidr_range}"
  authorized_cidr_range = "${var.authorized_cidr_range}"

  gke_cluster_name     = "${var.gke_cluster_name}"
  min_master_version   = "${var.min_master_version}"
  node_pool_name       = "${var.node_pool_name}"
  gke_initial_node     = "${var.gke_initial_node}"
  cluster_machine_type = "${var.cluster_machine_type}"
  min_node_count       = "${var.min_node_count}"
  max_node_count       = "${var.max_node_count}"
istio_version = "${var.istio_version}"
}
