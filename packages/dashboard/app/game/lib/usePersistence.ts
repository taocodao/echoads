'use client';
/**
 * usePersistence.ts — Phase 1.4
 * localStorage-backed state that survives page reloads.
 * Drop-in replacement for useState with automatic JSON serialization.
 */

import { useState, useEffect, useCallback, useRef } from 'react';

const PREFIX = 'arenza_';

function load<T>(key: string, fallback: T): T {
  if (typeof window === 'undefined') return fallback;
  try {
    const raw = localStorage.getItem(PREFIX + key);
    return raw !== null ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function save<T>(key: string, value: T): void {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(PREFIX + key, JSON.stringify(value));
  } catch {
    // Storage quota exceeded — ignore
  }
}

/** Drop-in for useState that auto-persists to localStorage */
export function usePersistedState<T>(
  key: string,
  initial: T
): [T, (v: T | ((prev: T) => T)) => void] {
  const [state, setRaw] = useState<T>(() => load(key, initial));

  const set = useCallback(
    (v: T | ((prev: T) => T)) => {
      setRaw(prev => {
        const next = typeof v === 'function' ? (v as (p: T) => T)(prev) : v;
        save(key, next);
        return next;
      });
    },
    [key]
  );

  return [state, set];
}

/** Save a value directly (imperative, outside React) */
export function persistSave<T>(key: string, value: T): void {
  save(key, value);
}

/** Load a value directly (imperative, for init) */
export function persistLoad<T>(key: string, fallback: T): T {
  return load(key, fallback);
}

/** Clear all Arenza persisted state (e.g., on logout or reset) */
export function clearAllPersistedState(): void {
  if (typeof window === 'undefined') return;
  Object.keys(localStorage)
    .filter(k => k.startsWith(PREFIX))
    .forEach(k => localStorage.removeItem(k));
}
