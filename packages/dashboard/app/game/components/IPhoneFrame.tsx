'use client';
import { ReactNode } from 'react';
/* eslint-disable @next/next/no-img-element */

const T = {
  bg: '#0d0f14', surface: '#141720', border: 'rgba(255,255,255,0.08)',
  orange: '#ff6b35', gold: '#ffc107', muted: '#8892b0',
};

export function IPhoneFrame({ children, points }: { children: ReactNode; points: number }) {
  return (
    <div style={{ display:'flex', justifyContent:'center', alignItems:'center', height:'calc(100vh - 70px)', background:'#080a0e', padding:'6px 0' }}>
      <div style={{
        width: 430, maxWidth:'100vw', height:'100%', maxHeight: 932,
        background: T.bg, borderRadius: 54, border:'3px solid #3a3a3a',
        position:'relative', overflow:'hidden', display:'flex', flexDirection:'column',
        boxShadow:'0 0 0 2px #0a0a0a, 0 30px 80px rgba(0,0,0,.7), 0 0 60px rgba(99,102,241,.12)',
      }}>
        {/* No Dynamic Island, no Status Bar — clean full-bleed display */}
        {/* Content */}
        <div style={{ flex:1, display:'flex', flexDirection:'column', overflow:'hidden', position:'relative' }}>
          {children}
        </div>
        {/* Home Indicator */}
        <div style={{ height:22, display:'flex', justifyContent:'center', alignItems:'center', flexShrink:0, background:T.bg }}>
          <div style={{ width:134, height:5, background:'rgba(255,255,255,.2)', borderRadius:3 }} />
        </div>
      </div>
    </div>
  );
}
