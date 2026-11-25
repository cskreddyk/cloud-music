#!/usr/bin/env bash

set -euo pipefail

# Move to project root
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "Initializing CloudMusic project..."

# Microservices
services=(
    api-gateway
    auth-service
    user-service
    catalog-service
    streaming-service
    playlist-service
    search-service
    recommendation-service
    favourites-service
    history-service
    notification-service
    admin-service
)

# Create microservice directories
for service in "${services[@]}"; do
    mkdir -p "services/$service/src"
    echo "Created: $service"
done

# Create DevOps directories
mkdir -p frontend/src
mkdir -p packages/shared

mkdir -p infrastructure/terraform/modules
mkdir -p infrastructure/terraform/environments/{dev,qa,uat,prod}

mkdir -p deploy/{argocd,gitops,secrets}
mkdir -p deploy/helm/cloudmusic

mkdir -p ci/jenkins
mkdir -p monitoring/{prometheus,grafana,alerts}
mkdir -p tests/{integration,load}
mkdir -p scripts docs media

# Initialize Git
if [[ ! -d .git ]]; then
    git init -b main
fi

# Create Git ignore configuration
if [[ ! -f .gitignore ]]; then

cat > .gitignore <<'EOF'
# Node.js
node_modules/
dist/
build/
coverage/

# Secrets
.env
.env.*
!.env.example
*.pem
*.key
*.pfx

# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
*.tfvars
!*.tfvars.example
crash.log

# Logs
*.log

# Music files
media/*
!media/.gitkeep

# Editor
.vscode/
.DS_Store
EOF

fi

echo "--------------------------------"
echo "CloudMusic setup successful"
echo "Total microservices: ${#services[@]}"
echo "Project directory: $(pwd)"
echo "--------------------------------"
