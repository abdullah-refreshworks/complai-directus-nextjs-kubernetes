#!/bin/bash

# Azure Kubernetes Service Setup Script
# This script sets up Azure resources for deploying Directus + Next.js + PostgreSQL

set -e

# Configuration variables
RESOURCE_GROUP="complai-directus-nextjs-kubernetes"
LOCATION="westeurope"
AKS_CLUSTER="complai-aks"
ACR_NAME="complaiacr"
NAMESPACE="complai"

echo "🚀 Setting up Azure resources for Complai Directus + Next.js deployment..."

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first:"
    echo "   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Login to Azure (if not already logged in)
echo "🔐 Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "Please login to Azure..."
    az login
fi

# Create resource group
echo "📦 Creating resource group: $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Container Registry
echo "🐳 Creating Azure Container Registry: $ACR_NAME"
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true

# Create AKS cluster
echo "☸️  Creating AKS cluster: $AKS_CLUSTER"
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER \
    --node-count 2 \
    --node-vm-size Standard_B2s \
    --attach-acr $ACR_NAME \
    --generate-ssh-keys \
    --enable-managed-identity

# Get AKS credentials
echo "🔑 Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER --overwrite-existing

# Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
echo "⏳ Waiting for NGINX Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# Create namespace
echo "📁 Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query loginServer --output tsv)

echo "✅ Azure setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Update your GitHub repository secrets with the following values:"
echo "   - AZURE_CREDENTIALS: (run 'az ad sp create-for-rbac --name complai-sp --role contributor --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP --sdk-auth')"
echo "   - ACR_NAME: $ACR_NAME"
echo "   - ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "   - RESOURCE_GROUP: $RESOURCE_GROUP"
echo "   - AKS_CLUSTER: $AKS_CLUSTER"
echo ""
echo "2. Update k8s/manifests/secret.yaml with your actual secrets"
echo "3. Push your code to trigger the GitHub Actions deployment"
echo ""
echo "🔗 Useful commands:"
echo "   - View cluster: kubectl get nodes"
echo "   - View pods: kubectl get pods -n $NAMESPACE"
echo "   - View services: kubectl get services -n $NAMESPACE"
echo "   - View ingress: kubectl get ingress -n $NAMESPACE"
