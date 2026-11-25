
#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../frontend"

# Configure API Gateway proxy
cat > vite.config.ts <<'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '127.0.0.1',
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:4000',
        changeOrigin: true
      }
    }
  }
})
EOF

# Generate React application
cat > src/App.tsx <<'EOF'
import { useEffect, useRef, useState } from 'react'
import {
  Music, Home, Search, Library,
  Play, Pause, SkipBack, SkipForward,
  Volume2, AudioLines
} from 'lucide-react'
import './App.css'

interface Song {
  id: string
  title: string
  artist: string
  audioUrl: string
}

function App() {
  const [songs, setSongs] = useState<Song[]>([])
  const [current, setCurrent] = useState<Song | null>(null)
  const [playing, setPlaying] = useState(false)
  const [search, setSearch] = useState('')
  const [volume, setVolume] = useState(0.5)
  const [progress, setProgress] = useState(0)
  const [duration, setDuration] = useState(0)
  const [error, setError] = useState('')

  const audio = useRef<HTMLAudioElement>(null)
  const searchInput = useRef<HTMLInputElement>(null)

  useEffect(() => {
    fetch('/api/catalog/songs')
      .then(res => {
        if (!res.ok) throw new Error('Catalog unavailable')
        return res.json()
      })
      .then((data: Song[]) => setSongs(data))
      .catch(() => setError('Unable to load music catalog'))
  }, [])

  useEffect(() => {
    if (audio.current) audio.current.volume = volume
  }, [volume])

  async function playSong(song: Song) {
    const player = audio.current
    if (!player) return

    setError('')

    if (current?.id !== song.id) {
      player.src = song.audioUrl
      setCurrent(song)
      setProgress(0)
      setDuration(0)
    }

    try {
      await player.play()
    } catch {
      setError('Unable to play audio')
    }
  }

  function togglePlay() {
    if (!current) {
      if (songs.length) void playSong(songs[0])
      return
    }

    if (playing) audio.current?.pause()
    else void playSong(current)
  }

  function changeTrack(direction: number) {
    if (!songs.length) return

    const index = songs.findIndex(s => s.id === current?.id)

    const next = index < 0
      ? 0
      : (index + direction + songs.length) % songs.length

    void playSong(songs[next])
  }

  function formatTime(seconds: number) {
    if (!Number.isFinite(seconds)) return '0:00'

    const minutes = Math.floor(seconds / 60)
    const remaining = Math.floor(seconds % 60)

    return `${minutes}:${String(remaining).padStart(2, '0')}`
  }

  const filtered = songs.filter(song =>
    `${song.title} ${song.artist}`
      .toLowerCase()
      .includes(search.toLowerCase())
  )

  return (
    <div className="layout">
      <aside className="sidebar">
        <h2 className="brand">
          <AudioLines /> CloudMusic
        </h2>

        <button onClick={() => setSearch('')}>
          <Home /> Home
        </button>

        <button onClick={() => searchInput.current?.focus()}>
          <Search /> Search
        </button>

        <button onClick={() => setSearch('')}>
          <Library /> Music Library
        </button>

        <p className="muted">CloudMusic Platform</p>
      </aside>

      <main>
        <div className="search">
          <Search />
          <input
            ref={searchInput}
            placeholder="Search songs and artists"
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>

        <section className="hero">
          <p>YOUR MUSIC PLATFORM</p>
          <h1>Welcome to CloudMusic</h1>
          <p>Discover and stream your favourite music.</p>
        </section>

        {error && <p className="error">{error}</p>}

        <h2>Recently added</h2>

        <div className="songs">
          {filtered.map(song => (
            <article className="song" key={song.id}>
              <div className="cover">
                <Music size={65} />
              </div>

              <h3>{song.title}</h3>
              <p>{song.artist}</p>

              <button
                className="play"
                aria-label={`Play ${song.title}`}
                onClick={() => void playSong(song)}
              >
                <Play size={20} />
              </button>
            </article>
          ))}
        </div>

        {!filtered.length && !error && <p>No songs found.</p>}
      </main>

      <footer className="player">
        <div className="track">
          <Music size={30} />
          <div>
            <strong>{current?.title || 'Select a song'}</strong>
            <p>{current?.artist || 'CloudMusic'}</p>
          </div>
        </div>

        <div className="controls">
          <div className="buttons">
            <button aria-label="Previous" onClick={() => changeTrack(-1)}>
              <SkipBack />
            </button>

            <button className="play" aria-label="Play or pause" onClick={togglePlay}>
              {playing ? <Pause /> : <Play />}
            </button>

            <button aria-label="Next" onClick={() => changeTrack(1)}>
              <SkipForward />
            </button>
          </div>

          <div className="timeline">
            <span>{formatTime(progress)}</span>

            <input
              aria-label="Playback position"
              type="range"
              min="0"
              max={duration || 0}
              step="0.1"
              value={progress}
              onChange={e => {
                const time = Number(e.target.value)
                if (audio.current) audio.current.currentTime = time
                setProgress(time)
              }}
            />

            <span>{formatTime(duration)}</span>
          </div>
        </div>

        <div className="volume">
          <Volume2 />
          <input
            aria-label="Volume"
            type="range"
            min="0"
            max="1"
            step="0.01"
            value={volume}
            onChange={e => setVolume(Number(e.target.value))}
          />
        </div>

        <audio
          ref={audio}
          preload="metadata"
          onPlay={() => setPlaying(true)}
          onPause={() => setPlaying(false)}
          onTimeUpdate={e => setProgress(e.currentTarget.currentTime)}
          onLoadedMetadata={e => setDuration(e.currentTarget.duration)}
          onEnded={() => changeTrack(1)}
          onError={() => setError('Audio streaming failed')}
        />
      </footer>
    </div>
  )
}

export default App
EOF

# Generate global styles
cat > src/index.css <<'EOF'
* {
  box-sizing: border-box;
}

body {
  margin: 0;
  background: #121212;
  color: white;
  font-family: Arial, sans-serif;
}

button, input {
  font: inherit;
}

button {
  cursor: pointer;
}

input[type="range"] {
  accent-color: #1ed760;
}
EOF

# Generate dashboard styles
cat > src/App.css <<'EOF'
.layout {
  display: grid;
  grid-template-columns: 240px 1fr;
  min-height: 100vh;
  padding-bottom: 125px;
}

.sidebar {
  background: #080808;
  padding: 25px;
}

.brand {
  color: #1ed760;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 23px;
  margin-bottom: 40px;
}

.sidebar button {
  display: flex;
  align-items: center;
  gap: 15px;
  background: transparent;
  border: 0;
  color: #ddd;
  padding: 15px 0;
}

.muted {
  color: #888;
  margin-top: 40px;
  font-size: 13px;
}

main {
  padding: 30px;
  min-width: 0;
}

.search {
  display: flex;
  align-items: center;
  gap: 12px;
  background: #242424;
  border-radius: 30px;
  padding: 15px 20px;
  max-width: 450px;
}

.search input {
  border: none;
  outline: none;
  background: transparent;
  color: white;
  width: 100%;
}

.hero {
  background: linear-gradient(120deg, #126b40, #142c24);
  padding: 40px;
  border-radius: 15px;
  margin: 25px 0 35px;
}

.hero h1 {
  font-size: clamp(25px, 4vw, 42px);
  margin: 15px 0;
}

.songs {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(170px, 230px));
  gap: 20px;
}

.song {
  background: #242424;
  padding: 15px;
  border-radius: 12px;
  position: relative;
}

.song:hover {
  background: #303030;
}

.cover {
  aspect-ratio: 1;
  background: linear-gradient(135deg, #176d54, #24374c);
  display: grid;
  place-items: center;
  border-radius: 8px;
}

.song:nth-child(2n) .cover {
  background: linear-gradient(135deg, #634b91, #27243b);
}

.song:nth-child(3n) .cover {
  background: linear-gradient(135deg, #97643a, #49352a);
}

.song p, .track p {
  color: #aaa;
  font-size: 14px;
}

.play {
  background: #1ed760 !important;
  color: black !important;
  border: none;
  border-radius: 50%;
  width: 46px;
  height: 46px;
  display: inline-grid;
  place-items: center;
}

.player {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: #080808;
  border-top: 1px solid #333;
  padding: 15px 25px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
}

.track, .volume, .buttons, .timeline {
  display: flex;
  align-items: center;
  gap: 15px;
}

.controls {
  width: 40%;
}

.buttons {
  justify-content: center;
  margin-bottom: 10px;
}

.buttons button {
  background: transparent;
  color: white;
  border: none;
}

.timeline {
  font-size: 12px;
  color: #aaa;
}

.timeline input {
  width: 100%;
  min-width: 0;
}

.volume input {
  width: 90px;
}

.error {
  color: #ff8080;
}

@media (max-width: 700px) {
  .layout {
    grid-template-columns: 1fr;
    padding-bottom: 180px;
  }

  .sidebar {
    padding: 15px;
  }

  .sidebar button {
    display: inline-flex;
    margin-right: 15px;
  }

  .brand {
    margin-bottom: 10px;
  }

  .muted {
    display: none;
  }

  main {
    padding: 15px;
  }

  .player {
    flex-wrap: wrap;
    gap: 10px;
  }

  .controls {
    width: 100%;
    order: 3;
  }
}
EOF

echo "CloudMusic frontend generated successfully"
