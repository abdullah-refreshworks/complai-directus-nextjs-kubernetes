# Deployment Guide - Complai Directus + Next.js + PostgreSQL on Azure Kubernetes Service

This guide will walk you through deploying the Complai application stack (Directus CMS + Next.js Frontend + PostgreSQL Database) to Azure Kubernetes Service (AKS).

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Next.js App   │    │  Directus CMS   │    │   PostgreSQL    │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│   (Database)    │
│   Port: 3000    │    │   Port: 8055    │    │   Port: 5432    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  NGINX Ingress  │
                    │   (Load Balancer)│
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Azure AKS     │
                    │   (Kubernetes)  │
                    └─────────────────┘
```

## 📋 Prerequisites

### Required Tools
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (v2.0+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Docker](https://docs.docker.com/get-docker/)
- [Git](https://git-scm.com/downloads)

### Azure Requirements
- Azure subscription with sufficient permissions
- Resource group creation permissions
- AKS cluster creation permissions

## 🚀 Quick Start Deployment

### Step 1: Clone and Setup
```bash
git clone https://github.com/abdullah-refreshworks/complai-directus-nextjs-kubernetes.git
cd complai-directus-nextjs-kubernetes
```

### Step 2: Run Azure Setup Script
```bash
chmod +x scripts/azure-setup.sh
./scripts/azure-setup.sh
```

This script will:
- Create Azure Resource Group (`complai-rg`)
- Create Azure Container Registry (`complaiacr`)
- Create AKS cluster (`complai-aks`)
- Install NGINX Ingress Controller
- Create Kubernetes namespace (`complai`)

### Step 3: Configure GitHub Secrets
After running the setup script, you'll need to add these secrets to your GitHub repository:

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Add the following secrets:

```bash
# Get Azure credentials (run this command from the setup script output)
az ad sp create-for-rbac --name complai-sp --role contributor --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/complai-rg --sdk-auth

# Add these secrets to GitHub:
AZURE_CREDENTIALS: <output from above command>
ACR_USERNAME: <ACR username from Azure portal>
ACR_PASSWORD: <ACR password from Azure portal>
```

### Step 4: Update Configuration
Update the following files with your actual values:

1. **k8s/manifests/secret.yaml** - Update with your actual secrets
2. **k8s/manifests/configmap.yaml** - Update URLs and admin credentials
3. **k8s/manifests/ingress.yaml** - Update domain names

### Step 5: Deploy via GitHub Actions
Simply push your changes to the `main` branch:
```bash
git add .
git commit -m "Configure deployment"
git push origin main
```

The GitHub Actions workflow will automatically:
- Build Docker images
- Push to Azure Container Registry
- Deploy to AKS
- Configure ingress

## 🔧 Manual Deployment

If you prefer to deploy manually:

### Step 1: Build and Push Images
```bash
chmod +x scripts/build-and-deploy.sh
./scripts/build-and-deploy.sh
```

### Step 2: Apply Kubernetes Manifests
```bash
# Apply in order
kubectl apply -f k8s/manifests/namespace.yaml
kubectl apply -f k8s/manifests/configmap.yaml
kubectl apply -f k8s/manifests/secret.yaml
kubectl apply -f k8s/manifests/postgres-deployment.yaml
kubectl apply -f k8s/manifests/directus-deployment.yaml
kubectl apply -f k8s/manifests/frontend-deployment.yaml
kubectl apply -f k8s/manifests/ingress.yaml
```

## 🌐 Accessing Your Applications

### Get External IP
```bash
kubectl get ingress complai-ingress -n complai
```

### Update DNS
Point your domains to the external IP:
- `directus.complai.com` → External IP
- `app.complai.com` → External IP

### Access URLs
- **Directus CMS**: `https://directus.complai.com`
- **Next.js App**: `https://app.complai.com`

## 🔍 Monitoring and Troubleshooting

### Check Deployment Status
```bash
# View all resources
kubectl get all -n complai

# View pods
kubectl get pods -n complai

# View services
kubectl get services -n complai

# View ingress
kubectl get ingress -n complai
```

### View Logs
```bash
# Directus logs
kubectl logs -f deployment/directus-deployment -n complai

# Frontend logs
kubectl logs -f deployment/frontend-deployment -n complai

# PostgreSQL logs
kubectl logs -f deployment/postgres-deployment -n complai
```

### Port Forwarding (for local testing)
```bash
# Directus
kubectl port-forward service/directus-service 8055:8055 -n complai

# Frontend
kubectl port-forward service/frontend-service 3000:3000 -n complai

# PostgreSQL
kubectl port-forward service/postgres-service 5432:5432 -n complai
```

## 🔐 Security Considerations

### Secrets Management
- All sensitive data is stored in Kubernetes secrets
- Secrets are base64 encoded (not encrypted)
- Consider using Azure Key Vault for production

### Network Security
- Services use ClusterIP (internal only)
- External access via NGINX Ingress
- SSL/TLS termination at ingress level

### Access Control
- AKS uses managed identity
- RBAC enabled by default
- Network policies can be added for additional security

## 📊 Scaling

### Horizontal Pod Autoscaling
```bash
# Enable HPA for Directus
kubectl autoscale deployment directus-deployment --cpu-percent=70 --min=2 --max=10 -n complai

# Enable HPA for Frontend
kubectl autoscale deployment frontend-deployment --cpu-percent=70 --min=2 --max=10 -n complai
```

### Vertical Scaling
Update resource limits in deployment files:
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

## 🗑️ Cleanup

### Delete Kubernetes Resources
```bash
kubectl delete namespace complai
```

### Delete Azure Resources
```bash
az group delete --name complai-rg --yes --no-wait
```

## 📚 Additional Resources

- [Azure Kubernetes Service Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Directus Documentation](https://docs.directus.io/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting guide: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review application logs
3. Check Azure resource health
4. Verify network connectivity
