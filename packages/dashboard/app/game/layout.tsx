'use client';
import { ReactNode } from 'react';

// Override the root layout's <main> padding for the game page
export default function GameLayout({ children }: { children: ReactNode }) {
  return (
    <div style={{ margin: '-2rem', overflow: 'hidden', height: 'calc(100vh - 57px)' }}>
      {children}
    </div>
  );
}
