// The istio_vpc module creates a vpc network with two subnets
module "istio_vpc" {
  source = "./modules/vpc_network"

  region        = "${var.region}"
  resource_name = "${var.resource_name}"
  subnet_cidr_1 = "${var.subnet_cidr_1}"
  subnet_cidr_2 = "${var.subnet_cidr_2}"
}

// The gke_cluster module creates a gke cluster over the above network and subnet

module "gke_cluster" {
  source = "./modules/gke_cluster"

  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.zone}"

  vpc_network_link = "${module.istio_vpc.vpc_network_link}"
  vpc_subnet_link  = "${module.istio_vpc.vpc_subnet1_link}"

  gke_cluster_name     = "${var.gke_cluster_name}"
  gke_initial_node     = "${var.gke_initial_node}"
  cluster_machine_type = "${var.cluster_machine_type}"
}
