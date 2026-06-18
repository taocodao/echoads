'use client';
import { useState, useEffect, useRef } from 'react';
import type { AdCreative } from '../lib/gameData';

const T = {
  bg: '#0d0f14', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)', text: '#f0f2ff', muted: '#8892b0',
  faint: '#4a5568', orange: '#ff6b35', teal: '#00c9b1', gold: '#ffc107',
  green: '#22c55e',
};

// Fallback videos if no videoUrl on the ad creative
const AD_VIDEOS_FALLBACK: Record<string, string> = {
  'Nike': 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/Coca%20Ad.%20.mp4',
  'Pepsi': 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/FiFA%20Coca%20Ad.%20.mp4',
  'DraftKings': 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/TV%20Take%20Ad..mp4',
  'State Farm': 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/iphone%20ad.%20.mp4',
  'Pinecrest Pizza Co.': 'https://lavcma6duvpplftv.public.blob.vercel-storage.com/Coca%20Ad.%20.mp4',
};

export function AdOverlay({ ad, onClose, onComplete }: {
  ad: AdCreative; onClose: () => void; onComplete: () => void;
}) {
  const [timer, setTimer] = useState(ad.durationSec);
  const [canSkip, setCanSkip] = useState(false);
  const [showPod, setShowPod] = useState(false);
  const [podVerified, setPodVerified] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);
  const txHash = '0x' + Array.from({length:16}, ()=>Math.floor(Math.random()*16).toString(16)).join('');

  const videoUrl = ad.videoUrl || AD_VIDEOS_FALLBACK[ad.brand] || AD_VIDEOS_FALLBACK['Nike'];

  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.muted = false;
      videoRef.current.volume = 1.0;
      videoRef.current.play().catch(() => {
        // Autoplay blocked — play muted then unmute
        if (videoRef.current) {
          videoRef.current.muted = true;
          videoRef.current.play().catch(() => {});
        }
      });
    }
    const id = setInterval(() => {
      setTimer(t => {
        if (t <= 1) {
          clearInterval(id);
          setShowPod(true);
          setTimeout(() => setPodVerified(true), 1200);
          setTimeout(() => { onComplete(); onClose(); }, 3500);
          return 0;
        }
        if (t <= ad.durationSec - 5) setCanSkip(true);
        return t - 1;
      });
    }, 1000);
    return () => clearInterval(id);
  }, [ad.durationSec, onClose, onComplete]);

  const progress = ((ad.durationSec - timer) / ad.durationSec) * 100;

  return (
    <div style={{ position:'absolute', inset:0, zIndex:60, background:T.bg, display:'flex', flexDirection:'column', animation:'fadeIn .3s ease' }}>
      {/* Ad Header */}
      <div style={{ padding:'10px 16px', display:'flex', justifyContent:'space-between', alignItems:'center', borderBottom:`1px solid ${T.border}`, background:T.surface }}>
        <div style={{ fontSize:12, color:'#fff', fontWeight:700, letterSpacing:'.06em', textTransform:'uppercase' }}>
          📺 Sponsored Ad
        </div>
        <div style={{ fontSize:12, color:T.gold, fontWeight:800 }}>+50 AZT for watching</div>
      </div>

      {/* Video Area — full commercial video with sound */}
      <div style={{ flex:'0 0 55%', position:'relative', background:'#000', overflow:'hidden' }}>
        <video
          ref={videoRef}
          src={videoUrl}
          style={{ width:'100%', height:'100%', objectFit:'cover' }}
          playsInline
        />
        {/* Brand badge overlay */}
        <div style={{ position:'absolute', top:12, left:12, display:'flex', alignItems:'center', gap:8, background:'rgba(0,0,0,.75)', backdropFilter:'blur(8px)', padding:'6px 14px', borderRadius:99 }}>
          <span style={{ fontSize:20 }}>{ad.emoji}</span>
          <div>
            <div style={{ fontSize:14, fontWeight:800, color:'#fff' }}>{ad.brand}</div>
            <div style={{ fontSize:10, color:ad.color, fontWeight:600 }}>{ad.tagline}</div>
          </div>
        </div>
      </div>

      {/* Ad Info */}
      <div style={{ flex:1, padding:'12px 16px', display:'flex', flexDirection:'column', gap:10 }}>
        <div style={{ fontSize:16, fontWeight:800, color:T.text, lineHeight:1.3 }}>
          {ad.brand} — "{ad.tagline}"
        </div>
        <div style={{ fontSize:13, color:T.muted, lineHeight:1.5 }}>
          Targeted: {ad.targetSegment}<br/>
          OpenRTB 2.6 Auction Winner · <span style={{ color:T.green, fontWeight:700 }}>${ad.cpm} CPM</span>
        </div>

        {/* Progress Bar */}
        <div>
          <div style={{ height:5, background:T.border, borderRadius:4 }}>
            <div style={{ height:'100%', width:`${progress}%`, background:ad.color, borderRadius:4, transition:'width 1s linear' }} />
          </div>
          <div style={{ display:'flex', justifyContent:'space-between', marginTop:8 }}>
            <span style={{ fontSize:13, color:'#fff', fontWeight:600 }}>{timer}s remaining</span>
            {canSkip && !showPod && (
              <button onClick={onClose} style={{ fontSize:13, fontWeight:800, color:T.orange, background:'none', border:`2px solid ${T.orange}`, borderRadius:8, padding:'5px 16px', cursor:'pointer', transition:'all .15s' }}>
                Skip Ad →
              </button>
            )}
            {!canSkip && !showPod && (
              <span style={{ fontSize:13, color:T.muted, fontWeight:600 }}>Skip in {Math.max(0, 5 - (ad.durationSec - timer))}s</span>
            )}
          </div>
        </div>
      </div>

      {/* PoD Receipt */}
      {showPod && (
        <div style={{ margin:'0 16px 16px', padding:14, background:`${T.green}15`, border:`1px solid ${T.green}44`, borderRadius:12, animation:'slideIn .4s ease' }}>
          <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:8 }}>
            <span style={{ fontSize:18 }}>{podVerified ? '✅' : '⏳'}</span>
            <span style={{ fontSize:15, fontWeight:800, color:podVerified ? T.green : T.gold }}>
              {podVerified ? 'Proof-of-Delivery Verified' : 'Verifying on Base L2...'}
            </span>
          </div>
          {podVerified && (
            <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:6, fontSize:12 }}>
              <div><span style={{color:T.muted}}>CPM:</span> <span style={{color:T.text,fontWeight:700}}>${ad.cpm}</span></div>
              <div><span style={{color:T.muted}}>Brand:</span> <span style={{color:T.text,fontWeight:700}}>{ad.brand}</span></div>
              <div style={{gridColumn:'1/3'}}><span style={{color:T.muted}}>Tx:</span> <span style={{fontFamily:'JetBrains Mono,monospace',color:T.teal,fontSize:10,fontWeight:600}}>{txHash}</span></div>
            </div>
          )}
        </div>
      )}

      <style>{`
        @keyframes fadeIn { from{opacity:0} to{opacity:1} }
        @keyframes slideIn { from{opacity:0;transform:translateY(8px)} to{opacity:1;transform:translateY(0)} }
      `}</style>
    </div>
  );
}
