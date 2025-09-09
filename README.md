# Complai - Directus + Next.js + PostgreSQL on Azure Kubernetes

A modern, production-ready CMS application built with Directus, Next.js, and PostgreSQL, deployed on Azure Kubernetes Service (AKS).

## 🏗️ Architecture

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

## 🚀 Quick Start

### Prerequisites
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Docker](https://docs.docker.com/get-docker/)
- [Git](https://git-scm.com/downloads)

### 1. Clone the Repository
```bash
git clone https://github.com/abdullah-refreshworks/complai-directus-nextjs-kubernetes.git
cd complai-directus-nextjs-kubernetes
```

### 2. Deploy to Azure Kubernetes Service

#### Option A: Automated Deployment (Recommended)
```bash
# Run the Azure setup script
chmod +x scripts/azure-setup.sh
./scripts/azure-setup.sh

# Follow the instructions to configure GitHub secrets
# Then push to main branch to trigger automated deployment
git push origin main
```

#### Option B: Manual Deployment
```bash
# Run the build and deploy script
chmod +x scripts/build-and-deploy.sh
./scripts/build-and-deploy.sh
```

### 3. Access Your Applications
After deployment, your applications will be available at:
- **Next.js Frontend**: `https://app.complai.com`
- **Directus CMS**: `https://directus.complai.com`

## 🛠️ Local Development

### Start Local Development Environment
```bash
chmod +x scripts/local-dev.sh
./scripts/local-dev.sh
```

This will start:
- PostgreSQL database on port 5432
- Directus CMS on port 8055
- Next.js frontend on port 3000

### Access Local Applications
- **Frontend**: http://localhost:3000
- **Directus Admin**: http://localhost:8055
- **Admin Credentials**: admin@complai.com / admin123

### Development Commands
```bash
# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View status
docker-compose ps
```

## 📁 Project Structure

```
├── .github/workflows/          # GitHub Actions CI/CD
├── database/                   # PostgreSQL configuration
│   ├── config/                # Database config files
│   ├── init/                  # Database initialization scripts
│   └── Dockerfile             # Database container
├── directus/                   # Directus CMS
│   ├── uploads/               # File uploads
│   ├── Dockerfile             # Directus container
│   └── package.json           # Directus dependencies
├── frontend/                   # Next.js application
│   ├── src/app/               # App router pages
│   ├── src/lib/               # Utility functions
│   ├── Dockerfile             # Frontend container
│   └── package.json           # Frontend dependencies
├── k8s/manifests/             # Kubernetes configurations
├── scripts/                   # Deployment scripts
└── docs/                      # Documentation
```

## 🔧 Configuration

### Environment Variables

#### Frontend (.env.local)
```env
NEXT_PUBLIC_DIRECTUS_URL=http://localhost:8055
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

#### Directus (.env)
```env
# Database
DB_CLIENT=pg
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=directus
DB_USER=directus
DB_PASSWORD=directus123

# Admin
ADMIN_EMAIL=admin@complai.com
ADMIN_PASSWORD=admin123

# Security
KEY=directus123
SECRET=directus-secret-123
JWT_SECRET=jwt-secret-123
```

### Kubernetes Secrets
Update `k8s/manifests/secret.yaml` with your actual secrets:
```yaml
data:
  postgres-password: <base64-encoded-password>
  directus-key: <base64-encoded-key>
  directus-secret: <base64-encoded-secret>
  jwt-secret: <base64-encoded-jwt-secret>
```

## 🔄 CI/CD Pipeline

The GitHub Actions workflow automatically:
1. Builds Docker images for frontend and Directus
2. Pushes images to Azure Container Registry
3. Deploys to Azure Kubernetes Service
4. Configures ingress and services
5. Runs health checks

### Triggering Deployment
Simply push to the `main` branch:
```bash
git add .
git commit -m "Your changes"
git push origin main
```

## 📊 Monitoring

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

### Health Checks
- **Frontend Health**: `https://app.complai.com/api/health`
- **Directus Health**: `https://directus.complai.com/server/ping`

## 🔐 Security

- All sensitive data stored in Kubernetes secrets
- SSL/TLS termination at ingress level
- Network policies for service isolation
- Non-root containers for security
- Health checks for reliability

## 📈 Scaling

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
az group delete --name complai-directus-nextjs-kubernetes --yes --no-wait
```

## 🆘 Troubleshooting

### Common Issues

1. **Pods not starting**: Check resource limits and node capacity
2. **Database connection issues**: Verify secrets and network policies
3. **Ingress not working**: Check NGINX controller and DNS configuration
4. **Build failures**: Verify Dockerfile and dependencies

### Debug Commands
```bash
# Describe pod for detailed information
kubectl describe pod <pod-name> -n complai

# Check events
kubectl get events -n complai --sort-by='.lastTimestamp'

# Port forward for local testing
kubectl port-forward service/directus-service 8055:8055 -n complai
```

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT.md) - Detailed deployment instructions
- [Development Guide](docs/DEVELOPMENT.md) - Local development setup
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally with `./scripts/local-dev.sh`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting guide
2. Review application logs
3. Check Azure resource health
4. Verify network connectivity

---

**Built with ❤️ using Directus, Next.js, PostgreSQL, and Azure Kubernetes Service**
