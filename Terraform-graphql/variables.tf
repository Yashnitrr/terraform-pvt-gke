//Variables must be changed according to the executing project/environment

variable "project" {
  description = "Project ID in which resources to be deployed"
  default     = "palo-alto-networks-234507"
}

variable "region" {
  description = "Region in which resources to be deployed"
  default     = "us-west1"
}

variable "zone" {
  description = "Zone in which resources to be deployed"
  default     = "us-west1-b"
}

variable "resource_name" {
  description = "Prefix to be used in VPCs, and Subnets"
  default     = "istio"
}

variable "subnet_cidr_1" {
  description = "CIDR range to be used for first Subnet"
  default     = "10.0.0.0/27"
}

variable "subnet_cidr_2" {
  description = "CIDR range to be used for second Subnet"
  default     = "10.0.1.0/27"
}

variable "gke_initial_node" {
  description = "Initial nodes to be deployed in Google Kubernetes Engine, by default it is a Regional deployment"
  default     = "1"
}

variable "gke_cluster_name" {
  description = "Google Kubernetes Engines cluster name"
  default     = "istio-tf"
}

variable "cluster_machine_type" {
  description = "Google Kubernetes Engines cluster node machine type"
  default     = "n1-standard-2"
}

variable "vpc_network_link" {
  description = "This variables is used internally in Terraform to store network link"
  default     = "default"
}

variable "vpc_subnet_link" {
  description = "This variables is used internally in Terraform to store subnet link"
  default     = "default"
}
