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

app.listen(process.env.PORT || 4000, "0.0.0.0", () => {
    console.log("API Gateway running on port 4000");
});
