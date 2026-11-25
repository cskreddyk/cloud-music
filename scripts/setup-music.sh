#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

# Catalog service
cat > services/catalog-service/src/index.js <<'EOF'
import express from "express";
import helmet from "helmet";
import pinoHttp from "pino-http";

const app = express();

app.use(helmet());
app.use(pinoHttp());

const songs = [1, 2, 3].map(id => ({
    id: String(id),
    title: `Song ${id}`,
    artist: "CloudMusic",
    audioUrl: `/api/stream/song${id}.mp3`
}));

app.get("/health", (req, res) => {
    res.json({service: "catalog-service", status: "UP"});
});

app.get("/ready", (req, res) => {
    res.json({status: "READY"});
});

app.get("/songs", (req, res) => {
    res.json(songs);
});

app.get("/songs/:id", (req, res) => {
    const song = songs.find(s => s.id === req.params.id);
    if (!song) {
        return res.status(404).json({error: "Song not found"});
    }
    res.json(song);
});

app.listen(process.env.PORT || 4003, "127.0.0.1", () => {
    console.log("Catalog service running on port 4003");
});
EOF

# Streaming service
cat > services/streaming-service/src/index.js <<'EOF'
import express from "express";
import helmet from "helmet";
import pinoHttp from "pino-http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const app = express();

app.use(helmet());
app.use(pinoHttp());

const mediaPath = process.env.MEDIA_PATH ||
    fileURLToPath(new URL("../../../media/", import.meta.url));

app.get("/health", (req, res) => {
    res.json({service: "streaming-service", status: "UP"});
});

app.get("/ready", (req, res) => {
    res.json({status: "READY"});
});

app.get("/stream/:file", (req, res) => {
    const file = req.params.file;

    if (!/^song[1-3]\.mp3$/.test(file)) {
        return res.status(404).json({error: "Song not found"});
    }

    res.type("audio/mpeg");
    res.sendFile(path.join(mediaPath, file));
});

app.listen(process.env.PORT || 4004, "127.0.0.1", () => {
    console.log("Streaming service running on port 4004");
});
EOF

# API Gateway
cat > services/api-gateway/src/index.js <<'EOF'
import express from "express";
import helmet from "helmet";
import pinoHttp from "pino-http";
import { createProxyMiddleware } from "http-proxy-middleware";

const app = express();

app.use(helmet());
app.use(pinoHttp());

app.get("/health", (req, res) => {
    res.json({service: "api-gateway", status: "UP"});
});

app.get("/ready", (req, res) => {
    res.json({status: "READY"});
});

app.use("/api/catalog", createProxyMiddleware({
    target: process.env.CATALOG_URL || "http://127.0.0.1:4003",
    changeOrigin: true
}));

app.use("/api/stream", createProxyMiddleware({
    target: process.env.STREAMING_URL || "http://127.0.0.1:4004",
    changeOrigin: true,
    pathRewrite: path => "/stream" + path
}));

app.listen(process.env.PORT || 4000, "127.0.0.1", () => {
    console.log("API Gateway running on port 4000");
});
EOF

(
    cd services/api-gateway
    npm install http-proxy-middleware@3
)

echo "===================================="
echo "Music functionality setup successful"
echo "===================================="
