/* The del_image resource deletes the image pushed into GCR
as a part of cleanup and it also removes the .crt and .key used
for creating the secrets for istio.
*/

resource "null_resource" "del_image" {
  provisioner "local-exec" {
    when = "destroy"

    command = <<EOF
gcloud container images delete gcr.io/${var.project}/graphql:v1
gcloud container images delete gcr.io/${var.project}/express:v1
gcloud container images delete gcr.io/${var.project}/sfdc:v1
rm -rf ${path.module}/*.pem
rm -rf ${path.module}/mod_deployment.yaml
EOF
  }
}

/*docker_build_sfdc, docker_build_express, and docker_build_graphql
builds the docker image out of Dockerfile present in ./Docker
directory and pushes it to the GCR.
*/

resource "null_resource" "docker_build_sfdc" {
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/Docker/node-sfdc/ \
&& docker build -t sfdc:v1 . \
&& docker tag sfdc:v1 gcr.io/${var.project}/sfdc:v1 \
&& echo y | gcloud auth configure-docker \
&& docker push gcr.io/${var.project}/sfdc:v1
EOF
  }
}

resource "null_resource" "docker_build_express" {
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/Docker/node-express/ \
&& docker build -t express:v1 . \
&& docker tag express:v1 gcr.io/${var.project}/express:v1 \
&& echo y | gcloud auth configure-docker \
&& docker push gcr.io/${var.project}/express:v1
EOF
  }

  depends_on = ["null_resource.docker_build_sfdc"]
}

resource "null_resource" "docker_build_graphql" {
  provisioner "local-exec" {
    command = <<EOF
cd ${path.module}/Docker/node-graphql/ \
&& docker build -t graphql:v1 . \
&& docker tag graphql:v1 gcr.io/${var.project}/graphql:v1 \
&& echo y | gcloud auth configure-docker \
&& docker push gcr.io/${var.project}/graphql:v1
EOF
  }

  depends_on = ["null_resource.docker_build_express"]
}

/*
Modifies the deployment files based on the current deployment
*/

data "template_file" "deployment_file" {
  template = "${file("${path.module}/deployment.yaml")}"

  vars {
    project_id    = "${var.project}"
    SFDC_USERNAME = "${var.sfdc_username}"
    SFDC_PASSWORD = "${var.sfdc_password}"
  }
}

/*
Creates the modified deployment file
It is then used to deploy the microservices
*/

resource "local_file" "mod_deployment" {
  content  = "${data.template_file.deployment_file.rendered}"
  filename = "${path.module}/mod_deployment.yaml"
}

/*
Create a separate node pool for the gke cluster
https://www.terraform.io/docs/providers/google/r/container_node_pool.html
*/

resource "google_container_node_pool" "istio_pool" {
  name     = "${var.node_pool_name}"
  cluster  = "${google_container_cluster.istio_cluster.name}"
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

/* Creates a private GKE cluster and deployes Istio with helm,
provides required storage access to pull the images build for
graphql, sfdc and node express from GCR.

Once it is created, terraform runs a series of shell
commands which connects and deploys the resources like
deployments, services, policies, RBAC in GKE cluster
A secret is created for istio-system namespace for TLS
communication on Istio's ingress gateway

https://www.terraform.io/docs/providers/google/d/google_container_cluster.html
*/

resource "google_container_cluster" "istio_cluster" {
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
Deploy Istio with HELM and microservices with kubectl
*/

resource "null_resource" "deployment" {
  triggers {
    id = "${google_container_cluster.istio_cluster.id}"
  }

  provisioner "local-exec" {
    command = <<EOF
sleep 60s
gcloud container clusters get-credentials ${google_container_cluster.istio_cluster.name} --region ${google_container_cluster.istio_cluster.region} --project ${var.project} \
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
sleep 30s
kubectl label namespace palo-alto-demo istio-injection=enabled
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout ${path.module}/privkey.pem -out ${path.module}/cert.pem -subj "/CN=panw.demo.com"
kubectl -n istio-system create secret tls istio-ilbgateway-certs --key ${path.module}/privkey.pem --cert ${path.module}/cert.pem \
  --dry-run -o yaml | kubectl apply -f -
sleep 60s
kubectl apply -f ${path.module}/mod_deployment.yaml 
sleep 15s
echo https://$(kubectl get svc istio-ilbgateway -n istio-system | awk 'FNR == 2{print $4}')/graphql
EOF
  }

  depends_on = ["null_resource.docker_build_graphql", "local_file.mod_deployment", "google_container_node_pool.istio_pool"]
}
