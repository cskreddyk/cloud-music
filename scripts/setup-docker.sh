
#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "Configuring microservice Dockerfiles..."

for service in services/*; do

    name=$(basename "$service")

    port=$(sed -n 's/^EXPOSE //p' "$service/Dockerfile" | head -1)

    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        echo "Invalid port for $name"
        exit 1
    fi

    cat > "$service/Dockerfile" <<EOF
FROM node:24-bookworm-slim

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=$port

COPY package*.json ./

RUN npm ci --omit=dev

COPY --chown=node:node src ./src

USER node

EXPOSE $port

CMD ["node", "src/index.js"]
EOF

    cat > "$service/.dockerignore" <<'EOF'
node_modules
.git
.env
.env.*
*.log
coverage
dist
*.pem
*.key
EOF

    echo "Configured: $name"

done

# Allow traffic from outside the container
for service in api-gateway catalog-service streaming-service; do
    sed -i 's/"127.0.0.1"/"0.0.0.0"/g' \
        "services/$service/src/index.js"
done

echo "Configuring frontend Dockerfile..."

cat > frontend/Dockerfile <<'EOF'
FROM node:24-bookworm-slim AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

FROM nginxinc/nginx-unprivileged:stable-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
EOF

cat > frontend/nginx.conf <<'EOF'
server {
    listen 8080;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location = /health {
        access_log off;
        return 200 "healthy\n";
    }

    location /api/ {
        proxy_pass http://api-gateway:4000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

cat > frontend/.dockerignore <<'EOF'
node_modules
dist
.git
.env
.env.*
*.log
*.pem
*.key
EOF

echo "All 13 Dockerfiles configured successfully."

