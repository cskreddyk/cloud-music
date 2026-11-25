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
