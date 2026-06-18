'use client';
import { useEffect, useState } from 'react';
import type { ActiveMoment } from '../lib/useGameMomentClassifier';

interface Props {
  moment: ActiveMoment;
  visible: boolean;
}

export function CommentaryOverlay({ moment, visible }: Props) {
  const [show, setShow] = useState(false);

  useEffect(() => {
    if (visible && moment.commentary) {
      setShow(true);
      const t = setTimeout(() => setShow(false), 6500);
      return () => clearTimeout(t);
    } else {
      setShow(false);
    }
  }, [moment.commentary, moment.setAt, visible]);

  if (!show || !moment.commentary) return null;

  return (
    <div style={{
      position: 'absolute', bottom: 14, left: 10, right: 10, zIndex: 40,
      animation: 'commentaryIn 0.4s ease',
      pointerEvents: 'none',
    }}>
      {/* Moment badge */}
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 5,
        background: moment.meta.color + '22',
        border: `1px solid ${moment.meta.color}66`,
        borderRadius: 99, padding: '2px 10px', marginBottom: 5,
      }}>
        <div style={{ width: 6, height: 6, borderRadius: '50%', background: moment.meta.color, boxShadow: `0 0 6px ${moment.meta.color}` }} />
        <span style={{ fontSize: 9, fontWeight: 700, color: moment.meta.color, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
          {moment.meta.label} · {moment.meta.multiplier}× CPM
        </span>
      </div>
      {/* Commentary text */}
      <div style={{
        background: 'rgba(0,0,0,0.82)',
        backdropFilter: 'blur(10px)',
        border: `1px solid rgba(255,255,255,0.1)`,
        borderLeft: `3px solid ${moment.meta.color}`,
        borderRadius: 8, padding: '8px 12px',
      }}>
        <div style={{ fontSize: 10, color: '#8892b0', fontWeight: 600, marginBottom: 3, letterSpacing: '0.05em' }}>
          🤖 AI Commentary
        </div>
        <div style={{ fontSize: 12, color: '#f0f2ff', lineHeight: 1.5, fontWeight: 500 }}>
          {moment.commentary}
        </div>
      </div>
      <style>{`
        @keyframes commentaryIn {
          from { opacity:0; transform:translateY(8px); }
          to   { opacity:1; transform:translateY(0); }
        }
      `}</style>
    </div>
  );
}
