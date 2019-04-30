// Creates a custom VPC network

resource "google_compute_network" "custom_istio_network" {
  name = "${var.resource_name}-vpc"

  auto_create_subnetworks = "false"
}

//Creates subnet with 'private google access' enabled

resource "google_compute_subnetwork" "custom_istio_subnet_1" {
  name   = "${var.resource_name}-subnet1"
  region = "${var.region}"

  ip_cidr_range = "${var.subnet_cidr_1}"
  network       = "${google_compute_network.custom_istio_network.name}"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "custom_istio_subnet_2" {
  name   = "${var.resource_name}-subnet2"
  region = "${var.region}"

  ip_cidr_range = "${var.subnet_cidr_2}"
  network       = "${google_compute_network.custom_istio_network.name}"
  private_ip_google_access = true
}
