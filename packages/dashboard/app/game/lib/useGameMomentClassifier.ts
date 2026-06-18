'use client';
import { useState, useCallback } from 'react';
import type { GameEvent } from './gameData';

// ── Game Moment Taxonomy (Module 3) ──────────────────────────────────────────

export type GameMomentCode =
  | 'GMS_SCORE' | 'GMS_HALFTIME' | 'GMS_CLUTCH' | 'GMS_TIMEOUT'
  | 'GMS_INJURY' | 'GMS_STANDARD' | 'GMS_PREDICTION_WIN' | 'GMS_SPONSOR_QUIZ';

export interface MomentMeta {
  code: GameMomentCode;
  label: string;
  multiplier: number;
  color: string;
  description: string;
  expiresAfterSec: number;
}

export const MOMENT_DEFINITIONS: Record<GameMomentCode, Omit<MomentMeta, 'code'>> = {
  GMS_SCORE:          { label:'Score Event',      multiplier:4.2, color:'#ff6b35', description:'Goal/TD in last 60s',           expiresAfterSec:60 },
  GMS_HALFTIME:       { label:'Halftime',          multiplier:2.8, color:'#ffc107', description:'Halftime break',                 expiresAfterSec:120 },
  GMS_CLUTCH:         { label:'Clutch Time',       multiplier:3.5, color:'#ef4444', description:'Last 5 min, within 3 pts',      expiresAfterSec:300 },
  GMS_TIMEOUT:        { label:'Timeout',           multiplier:1.8, color:'#00c9b1', description:'Commercial timeout',             expiresAfterSec:30 },
  GMS_INJURY:         { label:'Injury Stoppage',   multiplier:1.2, color:'#8892b0', description:'Player injury stoppage',         expiresAfterSec:60 },
  GMS_STANDARD:       { label:'Standard Play',     multiplier:1.0, color:'#4a5568', description:'Standard play',                  expiresAfterSec:Infinity },
  GMS_PREDICTION_WIN: { label:'Prediction Win',    multiplier:2.1, color:'#22c55e', description:'Fan just won a prediction',      expiresAfterSec:15 },
  GMS_SPONSOR_QUIZ:   { label:'Sponsor Quiz',      multiplier:3.0, color:'#7c3aed', description:'Sponsor quiz active',            expiresAfterSec:60 },
};

// ── Event Type → Moment Code ──────────────────────────────────────────────────

function classifyEvent(type: GameEvent['type']): GameMomentCode {
  switch (type) {
    case 'touchdown':    return 'GMS_SCORE';
    case 'fieldgoal':    return 'GMS_SCORE';
    case 'interception': return 'GMS_SCORE';
    case 'sack':         return 'GMS_CLUTCH';
    case 'penalty':      return 'GMS_STANDARD';
    case 'firstdown':    return 'GMS_STANDARD';
    case 'timeout':      return 'GMS_TIMEOUT';
    default:             return 'GMS_STANDARD';
  }
}

// ── Pre-scripted LLM Commentary ───────────────────────────────────────────────
// Generated commentary strings keyed to game event types (Module 8 simulation)

export const COMMENTARY_BY_TYPE: Record<GameEvent['type'], string[]> = {
  touchdown:    [
    `🏈 Absolute surgical precision — that's a 6-point statement by the Eagles offense.`,
    `🔥 TOUCHDOWN! The crowd goes electric. Hurts finding his receivers in rhythm tonight.`,
    `💥 That's as clean a red zone execution as you'll see. Eagles on the board again.`,
  ],
  fieldgoal:    [
    `🥅 Cairo Santos splits the uprights from 47 yards — Bears keeping themselves in this game.`,
    `📐 Ice in the veins. That kick never wavered. Bears within striking distance.`,
    `🎯 No drama, just three more points. The Bears kicking game has been reliable all night.`,
  ],
  interception: [
    `😤 Fields telegraphed that throw 200 miles away. Eagles defense was reading every route.`,
    `🙌 Turnover! The Eagles defense makes the pivotal play. This changes the momentum completely.`,
    `⚡ Pick-six territory. That interception could be the dagger the Bears needed to avoid.`,
  ],
  sack:         [
    `💪 The Eagles pass rush is absolutely dominant right now. The Bears O-line has no answers.`,
    `🔒 Sweat off the edge again — that's a loss of 9 yards and a massive third down ahead.`,
    `🏟️ The stadium erupts. Eagles defense is dictating the pace of this entire game.`,
  ],
  penalty:      [
    `🚩 Holding call on the Bears — exactly what you can't afford in field goal range.`,
    `⚠️ Officials have been active tonight. That flag backs Chicago up 10 yards.`,
    `🔍 Replay shows a clear hold. Tough break for the Bears with momentum building.`,
  ],
  firstdown:    [
    `📍 Eagles convert on third down — the chains are moving and the clock is burning.`,
    `✅ First down Eagles. Hurts is managing this game masterfully in the second half.`,
    `🎯 Crisp route, perfect timing. Philadelphia just refuses to let the Bears breathe.`,
  ],
  timeout:      [
    `⏸️ Bears burning a timeout — Coach Eberflus trying to slow the Eagles momentum.`,
    `🧊 Strategic timeout with 2 remaining. Every second counts in the final quarter.`,
    `📋 Coaching staff getting their heads together. Adjustment time — who reads it better?`,
  ],
};

// ── Active Moment State ───────────────────────────────────────────────────────

export interface ActiveMoment {
  code: GameMomentCode;
  meta: MomentMeta;
  setAt: number; // elapsed seconds when this moment was set
  commentary: string | null;
}

// ── Hook ──────────────────────────────────────────────────────────────────────

export function useGameMomentClassifier(elapsed: number) {
  const [moment, setMoment] = useState<ActiveMoment>({
    code: 'GMS_STANDARD',
    meta: { code: 'GMS_STANDARD', ...MOMENT_DEFINITIONS.GMS_STANDARD },
    setAt: 0,
    commentary: null,
  });

  const classifyGameEvent = useCallback((event: GameEvent) => {
    const code = classifyEvent(event.type);
    const meta: MomentMeta = { code, ...MOMENT_DEFINITIONS[code] };
    const lines = COMMENTARY_BY_TYPE[event.type] ?? [];
    const commentary = lines.length > 0 ? lines[Math.floor(Math.random() * lines.length)] : null;
    setMoment({ code, meta, setAt: elapsed, commentary });
  }, [elapsed]);

  const triggerPredictionWin = useCallback(() => {
    const code: GameMomentCode = 'GMS_PREDICTION_WIN';
    setMoment({ code, meta: { code, ...MOMENT_DEFINITIONS[code] }, setAt: elapsed, commentary: null });
  }, [elapsed]);

  const triggerSponsorQuiz = useCallback(() => {
    const code: GameMomentCode = 'GMS_SPONSOR_QUIZ';
    setMoment({ code, meta: { code, ...MOMENT_DEFINITIONS[code] }, setAt: elapsed, commentary: null });
  }, [elapsed]);

  // Auto-expire moment back to standard
  const secondsSinceMoment = elapsed - moment.setAt;
  const effectiveMoment = secondsSinceMoment > moment.meta.expiresAfterSec
    ? { code: 'GMS_STANDARD' as GameMomentCode, meta: { code: 'GMS_STANDARD' as GameMomentCode, ...MOMENT_DEFINITIONS.GMS_STANDARD }, setAt: moment.setAt, commentary: null }
    : moment;

  const commentaryVisible = !!moment.commentary && secondsSinceMoment < 7;

  return { moment: effectiveMoment, commentaryVisible, classifyGameEvent, triggerPredictionWin, triggerSponsorQuiz };
}
