# Azure AKS Microservices Environment

## Overview
- Terraform-provisioned Azure AKS cluster
- Dockerized microservices sample (React+Flask)
- CI/CD pipeline for build, scan, infra, and deploy (GitHub Actions)
- Monitoring with Prometheus & Grafana
- Security validation using Checkov

---

## Quickstart

### Infrastructure Deploy
```sh
cd terraform
terraform init
terraform apply
