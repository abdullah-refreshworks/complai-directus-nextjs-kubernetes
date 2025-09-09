#!/bin/bash

# Build and Deploy Script for Complai Directus + Next.js + PostgreSQL
# This script builds Docker images and deploys to Azure Kubernetes Service

set -e

# Configuration
RESOURCE_GROUP="complai-rg"
AKS_CLUSTER="complai-aks"
ACR_NAME="complaiacr"
NAMESPACE="complai"
FRONTEND_IMAGE="frontend"
DIRECTUS_IMAGE="directus"

echo "🚀 Building and deploying Complai application to Azure Kubernetes Service..."

# Check if required tools are installed
command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }

# Login to Azure (if not already logged in)
echo "🔐 Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure..."
    az login
fi

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer --output tsv)
echo "📦 Using ACR: $ACR_LOGIN_SERVER"

# Login to ACR
echo "🐳 Logging into Azure Container Registry..."
az acr login --name $ACR_NAME

# Get AKS credentials
echo "🔑 Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing

# Build and push Frontend image
echo "🏗️  Building Frontend Docker image..."
cd frontend
docker build -t $ACR_LOGIN_SERVER/$FRONTEND_IMAGE:latest .
docker push $ACR_LOGIN_SERVER/$FRONTEND_IMAGE:latest
cd ..

# Build and push Directus image
echo "🏗️  Building Directus Docker image..."
cd directus
docker build -t $ACR_LOGIN_SERVER/$DIRECTUS_IMAGE:latest .
docker push $ACR_LOGIN_SERVER/$DIRECTUS_IMAGE:latest
cd ..

# Update image references in deployment files
echo "📝 Updating deployment manifests..."
sed -i.bak "s|complaiacr.azurecr.io/frontend:latest|$ACR_LOGIN_SERVER/$FRONTEND_IMAGE:latest|g" k8s/manifests/frontend-deployment.yaml
sed -i.bak "s|directus/directus:latest|$ACR_LOGIN_SERVER/$DIRECTUS_IMAGE:latest|g" k8s/manifests/directus-deployment.yaml

# Apply Kubernetes manifests
echo "☸️  Deploying to Kubernetes..."

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply configurations
kubectl apply -f k8s/manifests/configmap.yaml
kubectl apply -f k8s/manifests/secret.yaml

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f k8s/manifests/postgres-deployment.yaml

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres-deployment -n $NAMESPACE

# Deploy Directus
echo "📊 Deploying Directus..."
kubectl apply -f k8s/manifests/directus-deployment.yaml

# Wait for Directus to be ready
echo "⏳ Waiting for Directus to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/directus-deployment -n $NAMESPACE

# Deploy Frontend
echo "🌐 Deploying Frontend..."
kubectl apply -f k8s/manifests/frontend-deployment.yaml

# Wait for Frontend to be ready
echo "⏳ Waiting for Frontend to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/frontend-deployment -n $NAMESPACE

# Deploy Ingress
echo "🌍 Deploying Ingress..."
kubectl apply -f k8s/manifests/ingress.yaml

# Get deployment status
echo "✅ Deployment completed!"
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""
kubectl get ingress -n $NAMESPACE

# Get external IP
echo ""
echo "🔗 Getting external IP addresses..."
INGRESS_IP=$(kubectl get ingress complai-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -n "$INGRESS_IP" ]; then
    echo "External IP: $INGRESS_IP"
    echo ""
    echo "🌐 Application URLs (update your DNS to point to $INGRESS_IP):"
    echo "   Directus CMS: http://directus.complai.com"
    echo "   Next.js App: http://app.complai.com"
else
    echo "⏳ External IP is still being assigned. Check with:"
    echo "   kubectl get ingress complai-ingress -n $NAMESPACE"
fi

echo ""
echo "🔧 Useful commands:"
echo "   View pods: kubectl get pods -n $NAMESPACE"
echo "   View logs: kubectl logs -f deployment/directus-deployment -n $NAMESPACE"
echo "   View logs: kubectl logs -f deployment/frontend-deployment -n $NAMESPACE"
echo "   Port forward: kubectl port-forward service/directus-service 8055:8055 -n $NAMESPACE"
