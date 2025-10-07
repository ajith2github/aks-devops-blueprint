# Azure AKS Microservices Environment

## Overview
- Terraform-provisioned Azure AKS cluster
- Dockerized microservices sample (React+Flask)
- build, scan, infra, and deploy 
- Monitoring with Prometheus & Grafana
- Security validation using terrascan

---

## Quickstart

### Infrastructure Deploy
```sh
cd terraform
terraform init
terraform apply

### Build images
docker build -t ajaksacr5ab8510ec6.azurecr.io/backend:latest app/backend/
docker build -t ajaksacr5ab8510ec6.azurecr.io/frontend:latest app/frontend/
docker push ajaksacr5ab8510ec6.azurecr.io/backend:latest
docker push ajaksacr5ab8510ec6.azurecr.io/frontend:latest

### get kubeconfig and deploy services
az aks get-credentials --resource-group ajaks-rg --name ajaks-prod
az aks update -n ajaks-prod -g ajaks-rg --attach-acr ajaksacr5ab8510ec6
kubectl apply -f k8s/
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm install prometheus prometheus-community/prometheus --namespace monitoring --create-namespace
helm install grafana grafana/grafana --namespace monitoring --set adminPassword='StrongPassword123'
kubectl get svc --namespace monitoring
