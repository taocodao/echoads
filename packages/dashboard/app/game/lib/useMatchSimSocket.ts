'use client';
/**
 * useMatchSimSocket.ts — Phase 2.5
 * WebSocket client for MatchSim backend (ws://localhost:3001/ws/match/{matchId})
 * Falls back silently to client-side mode if the server is unavailable.
 *
 * Message types received:
 *   timeline_info  — sent once on connect (match metadata)
 *   clock          — every 5s (elapsed, remaining)
 *   play           — game event (description, emoji, bingoLabel)
 *   score          — scoring event (homeScoreDelta, awayScoreDelta)
 *   prediction     — prediction question to display
 *   quarter_change — new quarter
 *   ad_break       — commercial break trigger
 *   sponsor_quiz   — sponsor quiz trigger
 *   trivia         — trivia pack trigger
 */

import { useEffect, useRef, useState, useCallback } from 'react';

export type MatchSimEvent = {
  type:
    | 'timeline_info'
    | 'clock'
    | 'play'
    | 'score'
    | 'prediction'
    | 'quarter_change'
    | 'ad_break'
    | 'sponsor_quiz'
    | 'trivia';
  at?: number;
  elapsed?: number;
  remaining?: number;
  data?: Record<string, any>;
  // timeline_info fields
  matchId?: string;
  sport?: string;
  homeTeam?: Record<string, any>;
  awayTeam?: Record<string, any>;
  durationSeconds?: number;
  totalEvents?: number;
};

export type SocketStatus = 'connecting' | 'live' | 'offline';

const MATCHSIM_URL =
  process.env.NEXT_PUBLIC_MATCHSIM_URL ?? 'ws://localhost:3001';

export function useMatchSimSocket(
  matchId: string,
  onEvent: (evt: MatchSimEvent) => void
) {
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const mountedRef = useRef(true);
  const [status, setStatus] = useState<SocketStatus>('connecting');

  const connect = useCallback(() => {
    if (!mountedRef.current) return;

    try {
      const ws = new WebSocket(`${MATCHSIM_URL}/ws/match/${matchId}`);
      wsRef.current = ws;

      ws.onopen = () => {
        if (!mountedRef.current) return;
        setStatus('live');
        console.info('[MatchSim] ✅ Connected to', matchId);
      };

      ws.onmessage = (evt) => {
        if (!mountedRef.current) return;
        try {
          const msg: MatchSimEvent = JSON.parse(evt.data);
          onEvent(msg);
        } catch {
          // malformed message — ignore
        }
      };

      ws.onerror = () => {
        // Error handling via onclose
      };

      ws.onclose = () => {
        if (!mountedRef.current) return;
        setStatus('offline');
        console.warn('[MatchSim] Connection lost — falling back to client-side mode. Will retry in 10s.');
        // Retry every 10 seconds — server may not be running
        reconnectRef.current = setTimeout(connect, 10_000);
      };
    } catch {
      // WebSocket constructor can throw (e.g. SSR)
      setStatus('offline');
    }
  }, [matchId, onEvent]);

  useEffect(() => {
    mountedRef.current = true;
    connect();

    return () => {
      mountedRef.current = false;
      if (reconnectRef.current) clearTimeout(reconnectRef.current);
      wsRef.current?.close();
    };
  }, [connect]);

  const disconnect = useCallback(() => {
    if (reconnectRef.current) clearTimeout(reconnectRef.current);
    wsRef.current?.close();
    setStatus('offline');
  }, []);

  return { status, disconnect };
}
