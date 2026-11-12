# Terraform Infrastructure Provisioning (Phase 4)

This directory contains the Terraform configuration for provisioning managed nodes `node-02` through `node-10` on the local Docker Desktop engine using the `kreuzwerker/docker` provider.

## Ownership Boundaries

- **Terraform-managed:** `node-02` through `node-10` (`10.240.0.102`–`10.240.0.110`)
- **Docker Compose-managed (read-only data sources in Terraform):**
  - Network: `devops-infra-net` (`10.240.0.0/16`, gateway `10.240.0.1`)
  - `puppet-server` (`10.240.0.10`)
  - `nagios-server` (`10.240.0.20`)
  - `node-01` (`10.240.0.101`)
- **Local Image:** `custom-ubuntu24-managed-node:monitoring-v2.1` (referenced via `data.docker_image` so no remote registry pull is performed)

## Directory Structure

```text
terraform/
├── README.md
├── versions.tf
├── providers.tf
├── data.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
└── modules/
    └── managed_nodes/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Validation Commands

```bash
terraform fmt -recursive
terraform init
terraform validate
terraform providers
terraform plan
```
