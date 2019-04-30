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
EOF
  }
}

/* docker_build_express and docker_build_graphql builds the docker
image out of Dockerfile present in ./Docker/node-express ./Docker/node-graphql
directory and pushes it to the GCR.
*/

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
depends_on=["null_resource.docker_build_express"]
}

/* Creates a GKE cluster with Istio enabled as an add-on
with required storage access to pull the images build for
graphql and node express from GCR.
Once it is created, terraform runs a series of shell
commands which connects and deploys the resources like
deployments, services, policies, RBAC in GKE cluster
A secret is created for istio-system namespace for TLS
communication on Istio's ingress gateway
*/

resource "google_container_cluster" "istio_cluster" {
  provider = "google-beta"

  name       = "${var.gke_cluster_name}"
  project    = "${var.project}"
 location     = "${var.region}"
  network    = "${var.vpc_network_link}"
  subnetwork = "${var.vpc_subnet_link}"

  initial_node_count = "${var.gke_initial_node}"

  addons_config {
    istio_config {
      disabled = false
      auth     = "AUTH_MUTUAL_TLS"
    }
  }

  node_config {
    machine_type = "${var.cluster_machine_type}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
  }

  provisioner "local-exec" {
    command = <<EOF
sleep 60s
gcloud container clusters get-credentials ${google_container_cluster.istio_cluster.name} --region ${google_container_cluster.istio_cluster.region} --project ${var.project}
kubectl create ns palo-alto-demo
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin  --user=$(gcloud config get-value core/account) \
&& kubectl label namespace palo-alto-demo istio-injection=enabled 
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes -out ${path.module}/tls.crt -keyout ${path.module}/tls.key -subj '/C=US/ST=California/L=San Francisco/O=Global Security/OU=IT Department/CN=csumeet@google.com'
kubectl create -n istio-system secret tls istio-ingressgateway-certs --key ${path.module}/tls.key --cert ${path.module}/tls.crt
sleep 5s
kubectl create -f ${path.module}/deployment.yaml
echo https://$(kubectl get svc istio-ingressgateway -n istio-system | awk 'FNR == 2{print $4}')/graphql
EOF
  }

  depends_on = ["null_resource.docker_build_graphql"]
}
