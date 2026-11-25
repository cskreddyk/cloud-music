#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

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

port=4000

for service in "${services[@]}"; do

    echo "Generating $service on port $port"

    dir="services/$service"

    mkdir -p "$dir/src"

    # Generate package.json
    if [[ ! -f "$dir/package.json" ]]; then
        cat > "$dir/package.json" <<EOF
{
  "name": "$service",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "node --watch src/index.js"
  },
  "dependencies": {
    "express": "^5.1.0",
    "helmet": "^8.1.0",
    "pino-http": "^10.4.0"
  }
}
EOF
    fi

    # Generate application entry point
    if [[ ! -f "$dir/src/index.js" ]]; then
        cat > "$dir/src/index.js" <<EOF
import express from "express";
import helmet from "helmet";
import pinoHttp from "pino-http";

const app = express();

const PORT = Number(process.env.PORT || $port);
const SERVICE = "$service";

app.disable("x-powered-by");

app.use(helmet());
app.use(express.json({ limit: "1mb" }));
app.use(pinoHttp());

app.get("/", (req, res) => {
    res.json({
        service: SERVICE,
        version: "1.0.0",
        status: "running"
    });
});

app.get("/health", (req, res) => {
    res.status(200).json({
        service: SERVICE,
        status: "UP"
    });
});

app.get("/ready", (req, res) => {
    res.status(200).json({
        service: SERVICE,
        status: "READY"
    });
});

app.use((req, res) => {
    res.status(404).json({
        error: "Route not found"
    });
});

const server = app.listen(PORT, "0.0.0.0", () => {
    console.log(SERVICE + " running on port " + PORT);
});

function shutdown() {
    server.close(() => process.exit(0));

    setTimeout(() => process.exit(1), 10000).unref();
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
EOF
    fi

    # Generate Dockerfile
    if [[ ! -f "$dir/Dockerfile" ]]; then
        cat > "$dir/Dockerfile" <<EOF
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
    fi

    # Generate Docker ignore file
    if [[ ! -f "$dir/.dockerignore" ]]; then
        cat > "$dir/.dockerignore" <<'EOF'
node_modules
.git
.env
.env.*
*.log
coverage
*.pem
*.key
EOF
    fi

    port=$((port + 1))

done

echo "=================================="
echo "All 12 service foundations created"
echo "=================================="
