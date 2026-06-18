'use client';

import { useState, useRef, useEffect } from 'react';

/* ── Video catalog ────────────────────────────────────────────────────────── */
const VIDEOS = [
  {
    id: 'anti-ad',
    title: 'Architecting the Anti-Ad',
    subtitle: 'How to build ads people actually want to watch',
    duration: '5:42',
    tag: 'Strategy',
    color: '#3b82f6',
    url: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/video/Architecting_the_Anti-Ad.mp4',
  },
  {
    id: 'launch-tutorial',
    title: 'Arenza Advertiser Launch Tutorial',
    subtitle: 'Step-by-step guide to launching your first campaign',
    duration: '7:15',
    tag: 'Tutorial',
    color: '#8b5cf6',
    url: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/video/Arenza_Advertiser_Launch_Tutorial.mp4',
  },
  {
    id: 'interactive-campaign',
    title: 'Building Your Interactive Campaign',
    subtitle: 'Arenza Sports FAST platform deep-dive',
    duration: '6:30',
    tag: 'Product',
    color: '#f59e0b',
    url: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/video/Arenza_Sports_FAST_Platform__Building_Your_Interactive_Campaign.mp4',
  },
  {
    id: 'restaurant-ads',
    title: 'Gamified Restaurant Ads & QR Hubs',
    subtitle: 'Designing identity-driven local ad experiences',
    duration: '8:03',
    tag: 'Local Ads',
    color: '#10b981',
    url: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/video/Designing_Gamified_Restaurant_Ads___QR_Identity_Hubs.mp4',
  },
  {
    id: 'screen-to-sale',
    title: 'The Screen-to-Sale Pipeline',
    subtitle: 'From impression to conversion in one flow',
    duration: '4:58',
    tag: 'Revenue',
    color: '#ef4444',
    url: 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/video/The_Screen-to-Sale_Pipeline.mp4',
  },
];

/* ── Styles ────────────────────────────────────────────────────────────────── */
const T = {
  bg: '#0b0e14',
  surface: 'rgba(20,26,40,0.85)',
  surface2: 'rgba(30,38,58,0.7)',
  border: 'rgba(255,255,255,0.08)',
  text: '#e2e8f0',
  muted: '#8892b0',
  faint: '#4a5568',
};

/* ── Page ──────────────────────────────────────────────────────────────────── */
export default function VideoPage() {
  const [activeId, setActiveId] = useState(VIDEOS[0].id);
  const [isPlaying, setIsPlaying] = useState(false);
  const [progress, setProgress] = useState(0);
  const [currentTime, setCurrentTime] = useState('0:00');
  const [totalTime, setTotalTime] = useState('0:00');
  const videoRef = useRef<HTMLVideoElement>(null);

  const active = VIDEOS.find(v => v.id === activeId)!;

  /* ── Video event handlers ──────────────────────────────────────────────── */
  useEffect(() => {
    const v = videoRef.current;
    if (!v) return;

    const onPlay = () => setIsPlaying(true);
    const onPause = () => setIsPlaying(false);
    const onTime = () => {
      if (!v.duration) return;
      setProgress((v.currentTime / v.duration) * 100);
      setCurrentTime(fmtTime(v.currentTime));
      setTotalTime(fmtTime(v.duration));
    };
    const onLoaded = () => {
      setTotalTime(fmtTime(v.duration));
      setProgress(0);
      setCurrentTime('0:00');
    };

    v.addEventListener('play', onPlay);
    v.addEventListener('pause', onPause);
    v.addEventListener('timeupdate', onTime);
    v.addEventListener('loadedmetadata', onLoaded);

    return () => {
      v.removeEventListener('play', onPlay);
      v.removeEventListener('pause', onPause);
      v.removeEventListener('timeupdate', onTime);
      v.removeEventListener('loadedmetadata', onLoaded);
    };
  }, [activeId]);

  const fmtTime = (s: number) => {
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${m}:${sec.toString().padStart(2, '0')}`;
  };

  const togglePlay = () => {
    const v = videoRef.current;
    if (!v) return;
    if (v.paused) v.play().catch(() => {});
    else v.pause();
  };

  const selectVideo = (id: string) => {
    setActiveId(id);
    setIsPlaying(false);
    setProgress(0);
    setTimeout(() => {
      videoRef.current?.play().catch(() => {});
    }, 200);
  };

  const seekTo = (e: React.MouseEvent<HTMLDivElement>) => {
    const v = videoRef.current;
    if (!v || !v.duration) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const pct = (e.clientX - rect.left) / rect.width;
    v.currentTime = pct * v.duration;
  };

  return (
    <div style={{ maxWidth: 1300, margin: '0 auto', padding: '1rem 0' }}>

      {/* ── Main Player Area ──────────────────────────────────────────────── */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 360px', gap: '1.25rem' }}>

        {/* Video Player */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>

          {/* Video container */}
          <div
            onClick={togglePlay}
            style={{
              position: 'relative',
              borderRadius: 16,
              overflow: 'hidden',
              background: '#000',
              aspectRatio: '16/9',
              cursor: 'pointer',
              boxShadow: `0 8px 40px rgba(0,0,0,0.5), 0 0 80px ${active.color}15`,
              border: `1px solid ${T.border}`,
            }}
          >
            <video
              ref={videoRef}
              key={activeId}
              src={active.url}
              style={{ width: '100%', height: '100%', objectFit: 'contain', display: 'block' }}
              playsInline
            />

            {/* Play overlay */}
            {!isPlaying && (
              <div style={{
                position: 'absolute', inset: 0,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                background: 'rgba(0,0,0,0.35)',
                transition: 'opacity 0.3s',
              }}>
                <div style={{
                  width: 72, height: 72, borderRadius: '50%',
                  background: `linear-gradient(135deg, ${active.color}, ${active.color}cc)`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: `0 4px 24px ${active.color}66`,
                  transition: 'transform 0.2s',
                }}>
                  <span style={{ fontSize: 28, marginLeft: 4, color: '#fff' }}>▶</span>
                </div>
              </div>
            )}

            {/* Tag badge */}
            <div style={{
              position: 'absolute', top: 14, left: 14,
              background: `${active.color}dd`, color: '#fff',
              fontSize: 11, fontWeight: 700, padding: '4px 12px',
              borderRadius: 999, letterSpacing: '0.04em',
              backdropFilter: 'blur(8px)',
            }}>
              {active.tag}
            </div>
          </div>

          {/* Progress bar */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
            <span style={{ fontSize: 12, color: T.muted, fontFamily: 'JetBrains Mono, monospace', minWidth: 40 }}>{currentTime}</span>
            <div
              onClick={seekTo}
              style={{
                flex: 1, height: 6, background: 'rgba(255,255,255,0.08)',
                borderRadius: 3, cursor: 'pointer', position: 'relative',
              }}
            >
              <div style={{
                height: '100%', borderRadius: 3,
                background: `linear-gradient(90deg, ${active.color}, ${active.color}bb)`,
                width: `${progress}%`, transition: 'width 0.15s linear',
                boxShadow: `0 0 8px ${active.color}44`,
              }} />
              {/* Scrubber dot */}
              <div style={{
                position: 'absolute', top: '50%', left: `${progress}%`,
                transform: 'translate(-50%, -50%)',
                width: 14, height: 14, borderRadius: '50%',
                background: '#fff', border: `2px solid ${active.color}`,
                boxShadow: `0 0 8px ${active.color}66`,
                transition: 'left 0.15s linear',
              }} />
            </div>
            <span style={{ fontSize: 12, color: T.muted, fontFamily: 'JetBrains Mono, monospace', minWidth: 40, textAlign: 'right' }}>{totalTime}</span>
          </div>

          {/* Title + description */}
          <div>
            <h1 style={{ margin: 0, fontSize: '1.35rem', fontWeight: 700, color: T.text }}>{active.title}</h1>
            <p style={{ margin: '0.3rem 0 0', fontSize: '0.85rem', color: T.muted }}>{active.subtitle}</p>
          </div>
        </div>

        {/* ── Playlist Sidebar ──────────────────────────────────────────────── */}
        <div style={{
          background: T.surface,
          border: `1px solid ${T.border}`,
          borderRadius: 16,
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
        }}>
          {/* Sidebar header */}
          <div style={{
            padding: '1rem 1.25rem 0.75rem',
            borderBottom: `1px solid ${T.border}`,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <h2 style={{ margin: 0, fontSize: '0.95rem', fontWeight: 700, color: T.text }}>
                🎥 Introductory Videos
              </h2>
              <span style={{ fontSize: '0.75rem', color: T.faint }}>{VIDEOS.length} videos</span>
            </div>
          </div>

          {/* Video list */}
          <div style={{ flex: 1, overflowY: 'auto', padding: '0.5rem' }}>
            {VIDEOS.map((v, idx) => {
              const isCurrent = v.id === activeId;
              return (
                <button
                  key={v.id}
                  onClick={() => selectVideo(v.id)}
                  style={{
                    width: '100%',
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '0.75rem',
                    padding: '0.7rem 0.75rem',
                    borderRadius: 12,
                    border: 'none',
                    cursor: 'pointer',
                    background: isCurrent
                      ? `linear-gradient(135deg, ${v.color}18, ${v.color}08)`
                      : 'transparent',
                    textAlign: 'left',
                    transition: 'all 0.2s',
                    marginBottom: 2,
                    outline: isCurrent ? `1px solid ${v.color}44` : '1px solid transparent',
                  }}
                >
                  {/* Index / Now Playing indicator */}
                  <div style={{
                    width: 24, height: 24, borderRadius: 6, flexShrink: 0,
                    background: isCurrent ? `${v.color}33` : T.surface2,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    fontSize: 11, fontWeight: 700, marginTop: 2,
                    color: isCurrent ? v.color : T.muted,
                    border: isCurrent ? `1px solid ${v.color}66` : `1px solid ${T.border}`,
                  }}>
                    {isCurrent && isPlaying ? '▶' : idx + 1}
                  </div>

                  {/* Text */}
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{
                      fontSize: '0.82rem',
                      fontWeight: isCurrent ? 700 : 500,
                      color: isCurrent ? '#fff' : T.text,
                      lineHeight: 1.35,
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      display: '-webkit-box',
                      WebkitLineClamp: 2,
                      WebkitBoxOrient: 'vertical' as const,
                    }}>
                      {v.title}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
                      <span style={{
                        fontSize: 10, fontWeight: 600,
                        color: v.color, background: `${v.color}18`,
                        padding: '1px 7px', borderRadius: 4,
                      }}>
                        {v.tag}
                      </span>
                      <span style={{ fontSize: 11, color: T.faint }}>{v.duration}</span>
                    </div>
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* ── Bottom Feature Cards ──────────────────────────────────────────── */}
      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(5, 1fr)',
        gap: '0.75rem', marginTop: '1.5rem',
      }}>
        {VIDEOS.map(v => {
          const isCurrent = v.id === activeId;
          return (
            <button
              key={v.id}
              onClick={() => selectVideo(v.id)}
              style={{
                background: isCurrent
                  ? `linear-gradient(135deg, ${v.color}22, ${v.color}0a)`
                  : T.surface,
                border: `1px solid ${isCurrent ? `${v.color}55` : T.border}`,
                borderRadius: 14, padding: '1rem 1rem',
                cursor: 'pointer',
                textAlign: 'left',
                transition: 'all 0.25s',
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              {/* Glow */}
              {isCurrent && (
                <div style={{
                  position: 'absolute', top: -20, right: -20,
                  width: 80, height: 80, borderRadius: '50%',
                  background: `${v.color}15`, filter: 'blur(20px)',
                }} />
              )}
              <div style={{
                fontSize: 11, fontWeight: 700, color: v.color,
                marginBottom: 6, letterSpacing: '0.04em',
              }}>
                {v.tag}
              </div>
              <div style={{
                fontSize: '0.82rem', fontWeight: 600, color: T.text,
                lineHeight: 1.4, marginBottom: 4,
                overflow: 'hidden', textOverflow: 'ellipsis',
                display: '-webkit-box',
                WebkitLineClamp: 2,
                WebkitBoxOrient: 'vertical' as const,
              }}>
                {v.title}
              </div>
              <div style={{ fontSize: 11, color: T.faint }}>{v.duration}</div>
            </button>
          );
        })}
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600&display=swap');
        button:hover { filter: brightness(1.08); }
      `}</style>
    </div>
  );
}
