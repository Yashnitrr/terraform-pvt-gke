/*
Create a separate node pool for the gke cluster
https://www.terraform.io/docs/providers/google/r/container_node_pool.html
*/

resource "google_container_node_pool" "gke_cluster_pool" {
  name     = "${var.node_pool_name}"
  cluster  = "${google_container_cluster.gke_cluster.name}"
  location = "${var.region}"

  node_count = "${var.gke_initial_node}"

  lifecycle {
    ignore_changes = ["node_count"]
  }

  node_config {
    machine_type = "${var.cluster_machine_type}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    tags = ["${var.gke_cluster_name}-cluster", "nodes"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = "${var.min_node_count}"
    max_node_count = "${var.max_node_count}"
  }
}

/* Creates a private GKE cluster 

https://www.terraform.io/docs/providers/google/d/google_container_cluster.html
*/

resource "google_container_cluster" "gke_cluster" {
  name               = "${var.gke_cluster_name}"
  project            = "${var.project}"
  location           = "${var.region}"
  initial_node_count = 1

  min_master_version = "${var.min_master_version}"
  node_version       = "${var.min_master_version}"

  remove_default_node_pool = true

  network    = "${var.vpc_network_name}"
  subnetwork = "${var.vpc_subnet_name}"

  lifecycle {
    ignore_changes = ["initial_node_count", "network_policy", "node_config", "node_pool"]
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "${var.master_cidr_range}"
  }

  ip_allocation_policy {}

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  master_authorized_networks_config {
    cidr_blocks = [{
      cidr_block   = "${var.authorized_cidr_range}"
      display_name = "Master Authorized network"
    }]
  }
}


/*
Deploy Istio with HELM
*/

resource "null_resource" "deployment" {
  triggers {
    id = "${google_container_cluster.gke_cluster.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
sleep 60s
gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --region ${google_container_cluster.gke_cluster.region} --project ${var.project} \
&& kubectl create ns palo-alto-demo \
&& kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin  --user=$(gcloud config get-value core/account) \
&& helm init --client-only \
&& helm repo add istio.io "https://storage.googleapis.com/istio-release/releases/${var.istio_version}/charts/" \
&& kubectl apply -f ${path.module}/helm-service-account.yaml
sleep 15s
helm init --service-account tiller
sleep 30s
helm init --upgrade \
&& helm install istio.io/istio-init --name istio-init --namespace istio-system 
sleep 50s
kubectl get crds | grep 'istio.io\|certmanager.k8s.io' | wc -l \
&& helm install istio.io/istio --name istio --namespace istio-system  --set gateways.enabled=true  --set gateways.istio-ilbgateway.enabled=true --set grafana.enabled=true --set global.mtls.enabled=true --set gateways.istio-ingressgateway.type=NodePort
EOF
}
}
