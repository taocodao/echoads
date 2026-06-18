// gameMomentClassifier.js — MatchSim (Phase 2: AI Game Moment Taxonomy)
// Maps timeline events to the 8-code GMS taxonomy with CPM multipliers.
// Broadcast alongside every event via WebSocket.

'use strict';

const MOMENT_DEFINITIONS = {
  GMS_SCORE:          { label: 'Score Event',     multiplier: 4.2, expiresAfterSec: 60  },
  GMS_HALFTIME:       { label: 'Halftime',         multiplier: 2.8, expiresAfterSec: 120 },
  GMS_CLUTCH:         { label: 'Clutch Time',      multiplier: 3.5, expiresAfterSec: 300 },
  GMS_TIMEOUT:        { label: 'Timeout',          multiplier: 1.8, expiresAfterSec: 30  },
  GMS_INJURY:         { label: 'Injury Stoppage',  multiplier: 1.2, expiresAfterSec: 60  },
  GMS_STANDARD:       { label: 'Standard Play',    multiplier: 1.0, expiresAfterSec: Infinity },
  GMS_PREDICTION_WIN: { label: 'Prediction Win',   multiplier: 2.1, expiresAfterSec: 15  },
  GMS_SPONSOR_QUIZ:   { label: 'Sponsor Quiz',     multiplier: 3.0, expiresAfterSec: 60  },
};

function classifyEvent(eventType, eventData) {
  switch (eventType) {
    case 'score':          return 'GMS_SCORE';
    case 'sponsor_quiz':   return 'GMS_SPONSOR_QUIZ';
    case 'quarter_change': return eventData?.newQuarter > 2 ? 'GMS_HALFTIME' : 'GMS_CLUTCH';
    case 'timeout':        return 'GMS_TIMEOUT';
    case 'prediction':     return 'GMS_STANDARD';
    case 'trivia':         return 'GMS_STANDARD';
    case 'ad_break':       return 'GMS_TIMEOUT';
    case 'play': {
      const desc = (eventData?.description || '').toLowerCase();
      if (desc.includes('sack') || desc.includes('interception')) return 'GMS_CLUTCH';
      return 'GMS_STANDARD';
    }
    default: return 'GMS_STANDARD';
  }
}

function classifyMoment(event) {
  const code = classifyEvent(event.type, event.data);
  const meta = MOMENT_DEFINITIONS[code];
  return {
    code,
    label: meta.label,
    multiplier: meta.multiplier,
    expiresAfterSec: meta.expiresAfterSec,
  };
}

module.exports = { classifyMoment, MOMENT_DEFINITIONS };
