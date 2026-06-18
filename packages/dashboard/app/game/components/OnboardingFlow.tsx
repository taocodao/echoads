'use client';
/**
 * OnboardingFlow.tsx — Phase 1.5
 * 3-step micro-survey shown on first launch.
 * Preferences feed into profileEngine via the saved onboarding profile.
 */

import { useState } from 'react';

const T = {
  bg: '#0d0f14', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)',
  text: '#f0f2ff', muted: '#8892b0', faint: '#4a5568',
  orange: '#ff6b35', teal: '#00c9b1', gold: '#ffc107',
  green: '#22c55e',
};

export interface OnboardingProfile {
  interests: string[];   // e.g., ['restaurant', 'bar', 'pizza']
  sports: string[];      // e.g., ['NFL', 'NBA']
  teams: string[];       // e.g., ['Eagles', 'Giants']
  completedAt: number;
}

interface Props {
  onComplete: (profile: OnboardingProfile) => void;
}

const INTERESTS = [
  { id: 'restaurant', emoji: '🍽️', label: 'Restaurant' },
  { id: 'bar',        emoji: '🍺', label: 'Bar'        },
  { id: 'pizza',      emoji: '🍕', label: 'Pizza'      },
  { id: 'cafe',       emoji: '☕', label: 'Cafe'       },
  { id: 'gym',        emoji: '💪', label: 'Gym'        },
  { id: 'diner',      emoji: '🥞', label: 'Diner'      },
];

const SPORTS = [
  { id: 'NFL', emoji: '🏈', label: 'NFL'     },
  { id: 'NBA', emoji: '🏀', label: 'NBA'     },
  { id: 'MLB', emoji: '⚾', label: 'MLB'     },
  { id: 'NHL', emoji: '🏒', label: 'NHL'     },
  { id: 'MLS', emoji: '⚽', label: 'Soccer'  },
  { id: 'UFC', emoji: '🥊', label: 'UFC/MMA' },
];

const TEAMS: Record<string, { id: string; emoji: string; label: string }[]> = {
  NFL: [
    { id: 'Eagles',   emoji: '🦅', label: 'Eagles'   },
    { id: 'Giants',   emoji: '🗽', label: 'Giants'   },
    { id: 'Cowboys',  emoji: '⭐', label: 'Cowboys'  },
    { id: 'Bears',    emoji: '🐻', label: 'Bears'    },
    { id: 'Chiefs',   emoji: '🔴', label: 'Chiefs'   },
    { id: '49ers',    emoji: '🏆', label: '49ers'    },
  ],
  NBA: [
    { id: 'Knicks',   emoji: '🗽', label: 'Knicks'   },
    { id: 'Nets',     emoji: '🎯', label: 'Nets'     },
    { id: 'Lakers',   emoji: '💛', label: 'Lakers'   },
    { id: 'Bulls',    emoji: '🐂', label: 'Bulls'    },
    { id: 'Celtics',  emoji: '☘️', label: 'Celtics'  },
    { id: 'Heat',     emoji: '🌡️', label: 'Heat'     },
  ],
};

type Step = 1 | 2 | 3;

export function OnboardingFlow({ onComplete }: Props) {
  const [step, setStep] = useState<Step>(1);
  const [interests, setInterests] = useState<string[]>([]);
  const [sports, setSports] = useState<string[]>([]);
  const [teams, setTeams] = useState<string[]>([]);

  const toggle = (arr: string[], setArr: (v: string[]) => void, id: string) => {
    setArr(arr.includes(id) ? arr.filter(x => x !== id) : [...arr, id]);
  };

  const availableTeams = sports.flatMap(s => TEAMS[s] ?? []);

  const finish = () => {
    onComplete({ interests, sports, teams, completedAt: Date.now() });
  };

  const btnStyle = (active: boolean, color = T.orange): React.CSSProperties => ({
    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
    padding: '10px 6px', borderRadius: 12, cursor: 'pointer',
    background: active ? `${color}22` : T.surface2,
    border: `1.5px solid ${active ? color : T.border}`,
    color: active ? color : T.muted,
    fontFamily: 'Inter, system-ui, sans-serif',
    transition: 'all 0.15s', flex: '0 0 calc(33% - 6px)',
    fontSize: 11, fontWeight: active ? 700 : 400,
  });

  const nextBtn = (label: string, onPress: () => void, disabled = false) => (
    <button
      onClick={onPress}
      disabled={disabled}
      style={{
        width: '100%', padding: '13px 0', borderRadius: 12, border: 'none',
        background: disabled ? T.faint : `linear-gradient(135deg, ${T.orange}, ${T.gold})`,
        color: '#fff', fontWeight: 800, fontSize: 14, cursor: disabled ? 'not-allowed' : 'pointer',
        fontFamily: 'Inter, system-ui, sans-serif',
        boxShadow: disabled ? 'none' : `0 4px 20px ${T.orange}44`,
        transition: 'all 0.2s',
      }}
    >{label}</button>
  );

  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 200,
      background: 'rgba(0,0,0,0.92)', backdropFilter: 'blur(12px)',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      padding: 20, fontFamily: 'Inter, system-ui, sans-serif',
    }}>
      <div style={{
        width: '100%', maxWidth: 380, background: T.surface,
        border: `1px solid ${T.border}`, borderRadius: 20, padding: 24,
        display: 'flex', flexDirection: 'column', gap: 18,
      }}>

        {/* Header */}
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: 36, marginBottom: 8 }}>📺</div>
          <div style={{ fontSize: 20, fontWeight: 900, color: T.text, marginBottom: 4 }}>
            Welcome to ArenzaTV
          </div>
          <div style={{ fontSize: 12, color: T.muted }}>
            Watch live sports. Earn rewards. Discover local deals.
          </div>
        </div>

        {/* Step indicator */}
        <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
          {([1, 2, 3] as Step[]).map(s => (
            <div key={s} style={{
              height: 4, flex: 1, borderRadius: 2,
              background: s <= step ? T.orange : T.border,
              transition: 'background 0.3s',
            }} />
          ))}
        </div>

        {/* Step 1 — Interests */}
        {step === 1 && (
          <>
            <div>
              <div style={{ fontSize: 14, fontWeight: 800, color: T.text, marginBottom: 4 }}>
                What do you like nearby?
              </div>
              <div style={{ fontSize: 11, color: T.muted }}>Select all that apply</div>
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {INTERESTS.map(i => (
                <button key={i.id} onClick={() => toggle(interests, setInterests, i.id)} style={btnStyle(interests.includes(i.id))}>
                  <span style={{ fontSize: 22 }}>{i.emoji}</span>
                  {i.label}
                </button>
              ))}
            </div>
            {nextBtn('Next →', () => setStep(2), interests.length === 0)}
          </>
        )}

        {/* Step 2 — Sports */}
        {step === 2 && (
          <>
            <div>
              <div style={{ fontSize: 14, fontWeight: 800, color: T.text, marginBottom: 4 }}>
                Favorite sports?
              </div>
              <div style={{ fontSize: 11, color: T.muted }}>Select all that apply</div>
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {SPORTS.map(s => (
                <button key={s.id} onClick={() => toggle(sports, setSports, s.id)} style={btnStyle(sports.includes(s.id), T.teal)}>
                  <span style={{ fontSize: 22 }}>{s.emoji}</span>
                  {s.label}
                </button>
              ))}
            </div>
            {nextBtn('Next →', () => setStep(3), sports.length === 0)}
          </>
        )}

        {/* Step 3 — Teams */}
        {step === 3 && (
          <>
            <div>
              <div style={{ fontSize: 14, fontWeight: 800, color: T.text, marginBottom: 4 }}>
                Favorite teams?
              </div>
              <div style={{ fontSize: 11, color: T.muted }}>We'll personalize your experience</div>
            </div>
            {availableTeams.length > 0 ? (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                {availableTeams.map(t => (
                  <button key={t.id} onClick={() => toggle(teams, setTeams, t.id)} style={btnStyle(teams.includes(t.id), T.gold)}>
                    <span style={{ fontSize: 22 }}>{t.emoji}</span>
                    {t.label}
                  </button>
                ))}
              </div>
            ) : (
              <div style={{ color: T.muted, fontSize: 12, textAlign: 'center' }}>
                Teams auto-suggested based on your sports picks above.
              </div>
            )}
            {nextBtn("Let's Go! 🏈", finish)}
          </>
        )}

        {/* Skip */}
        <button onClick={finish} style={{
          background: 'none', border: 'none', color: T.faint,
          fontSize: 11, cursor: 'pointer', textAlign: 'center',
        }}>
          Skip for now
        </button>
      </div>
    </div>
  );
}
