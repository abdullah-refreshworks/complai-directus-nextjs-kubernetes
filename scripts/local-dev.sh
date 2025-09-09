#!/bin/bash

# Local Development Setup Script
# This script sets up the local development environment using Docker Compose

set -e

echo "🚀 Setting up local development environment for Complai..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

# Create .env files if they don't exist
echo "📝 Creating environment files..."

# Frontend .env.local
if [ ! -f "frontend/.env.local" ]; then
    cat > frontend/.env.local << EOF
NEXT_PUBLIC_DIRECTUS_URL=http://localhost:8055
NEXT_PUBLIC_APP_URL=http://localhost:3000
EOF
    echo "✅ Created frontend/.env.local"
fi

# Directus .env
if [ ! -f "directus/.env" ]; then
    cat > directus/.env << EOF
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

# Public
PUBLIC_URL=http://localhost:8055
CORS_ENABLED=true
CORS_ORIGIN=http://localhost:3000

# Logging
LOG_LEVEL=info
LOG_STYLE=pretty
EOF
    echo "✅ Created directus/.env"
fi

# Start the development environment
echo "🐳 Starting development environment..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."

# Wait for PostgreSQL
echo "   Waiting for PostgreSQL..."
until docker-compose exec -T postgres pg_isready -U directus > /dev/null 2>&1; do
    sleep 2
done
echo "   ✅ PostgreSQL is ready"

# Wait for Directus
echo "   Waiting for Directus..."
until curl -f http://localhost:8055/server/ping > /dev/null 2>&1; do
    sleep 2
done
echo "   ✅ Directus is ready"

# Wait for Frontend
echo "   Waiting for Frontend..."
until curl -f http://localhost:3000/api/health > /dev/null 2>&1; do
    sleep 2
done
echo "   ✅ Frontend is ready"

echo ""
echo "🎉 Development environment is ready!"
echo ""
echo "🌐 Application URLs:"
echo "   Frontend: http://localhost:3000"
echo "   Directus Admin: http://localhost:8055"
echo "   Directus API: http://localhost:8055"
echo ""
echo "🔑 Admin Credentials:"
echo "   Email: admin@complai.com"
echo "   Password: admin123"
echo ""
echo "🔧 Useful commands:"
echo "   View logs: docker-compose logs -f"
echo "   Stop services: docker-compose down"
echo "   Restart services: docker-compose restart"
echo "   View status: docker-compose ps"
echo ""
echo "📊 Database:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: directus"
echo "   Username: directus"
echo "   Password: directus123"
