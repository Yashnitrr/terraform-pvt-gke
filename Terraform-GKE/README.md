# Terraform template- Private GKE cluster

The Terraform template creates a new private GKE cluster


Instructions:

Note: The machine used to execute terraform must be in the same network as of gke cluster for network connections. Refer [private gke cluster](https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters)

1. Clone the repository
```
git clone <repo_link>
cd (..)Terraform-GKE/
```

2. [Create a service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#creating_a_service_account) and grant the following roles to the service account by following these [instructions](https://cloud.google.com/iam/docs/granting-roles-to-service-accounts#granting_access_to_a_service_account_for_a_resource)
    1. roles/storage.admin
    2. roles/container.admin
    3. roles/iam.serviceAccountUser
    4. roles/compute.admin

3. [Install Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts)

4. Install kubectl, terraform, helm, docker.

5. unzip terraform as well as  untar (tar -zxvf) helm and add them to /usr/bin.

6. [Activate the service account on gcloud sdk](https://cloud.google.com/sdk/gcloud/reference/auth/activate-service-account) and set the default project.
```
gcloud auth activate-service-account --key-file=SA_FILE.json
gcloud init
```
7. Create Clount NAT for your VPC

8. Set the variables in [variables.tf](variables.tf) and corresponding service account filename in [provider_config.tf](provider_config.tf)

Terraform commands to setup the environment:
```
terraform init
terraform plan

terraform apply
```

Terraform commands to destroy the setup:
```
terraform destroy
```

## Test GKE connectivity with master

1. Run
```
kubectl cluster-info
```


## Troubleshooting

### Network failed to delete during terraform destroy

This occurs sometimes when Gogoles Kubernetes Engine cluster is destroyed however, GKE does not wait for the ingress controller to clean up resources. This results in orphaned firewall rules still attached with the network. If it occurs `delete the listed firewall rules manually and then run terraform destroy`
