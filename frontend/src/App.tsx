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
