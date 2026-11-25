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
