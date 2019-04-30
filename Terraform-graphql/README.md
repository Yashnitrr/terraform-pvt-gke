# Terraform template to deploy a Google Kubernetes Engine on a new custom VPC

[Architecture](https://docs.google.com/presentation/d/1HAKWhTezFvcTG6b6OHpa_4DPSHyGTL5a359RIXwhnEI/edit?usp=sharing) and [Documentation](https://docs.google.com/document/d/1X_He7FWbJu88y9pR43YjkFxIGXHRdvTS0Vn0WsclW1s/edit?usp=sharing) of the demo deployment.

1. Clone the repository
```
git clone <repo_link>
cd (..)Terraform-graphql/
```

2. [Create a service account](https://cloud.google.com/iam/docs/creating-managing-service-accounts#creating_a_service_account) and grant the following roles to the service account by following these [instructions](https://cloud.google.com/iam/docs/granting-roles-to-service-accounts#granting_access_to_a_service_account_for_a_resource)
    1. roles/storage.admin
    2. roles/container.admin
    3. roles/compute.networkAdmin
    4. roles/iam.serviceAccountUser

3. [Install Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts)

4. [Activate the service account on gcloud sdk](https://cloud.google.com/sdk/gcloud/reference/auth/activate-service-account) and set the default project.
```
gcloud auth activate-service-account --key-file=SA_FILE.json
gcloud init
```

5. [Docker](https://docs.docker.com/install/) and [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) must be installed and running

6. This Terraform template consumes some of the beta version of google clouds resources, and hence the [provider google-beta](https://github.com/terraform-providers/terraform-provider-google-beta) must be installed

7. Set the variables in [variables.tf](variables.tf) and corresponding service account filename in [provider_config.tf](provider_config.tf)

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



# Troubleshooting

## Network failed to delete during terraform destroy

This occurs sometimes when Gogoles Kubernetes Engine cluster is destroyed however, GKE does not wait for the ingress controller to clean up resources. This results in orphaned firewall rules still attached with the network. If it occurs `delete the listed firewall rules manually and then run terraform destroy`
