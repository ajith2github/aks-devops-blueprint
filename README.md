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

---

### docker build images
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

Prometheus:

The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
prometheus-server.monitoring.svc.cluster.local

Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=prometheus,app.
kubernetes.io/instance=prometheus" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9090

Grafana:

1. Get your 'admin' user password by running:

   kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; 
echo


2. The Grafana server can be accessed via port 80 on the following DNS name from within your cluster:

   grafana.monitoring.svc.cluster.local

   Get the Grafana URL to visit by running these commands in the same shell:
     export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.
kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
     kubectl --namespace monitoring port-forward $POD_NAME 3000
