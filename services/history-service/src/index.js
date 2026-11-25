import express from "express";
import helmet from "helmet";
import pinoHttp from "pino-http";

const app = express();

const PORT = Number(process.env.PORT || 4009);
const SERVICE = "history-service";

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
