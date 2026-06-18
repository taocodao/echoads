'use client';
/**
 * PostGameRecap.tsx — Phase 1.7
 * Post-game summary: prediction accuracy, points earned, offers redeemed, post-game offer.
 */

const T = {
  bg: '#0d0f14', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)',
  text: '#f0f2ff', muted: '#8892b0', faint: '#4a5568',
  orange: '#ff6b35', teal: '#00c9b1', gold: '#ffc107',
  green: '#22c55e', red: '#ef4444', purple: '#7c3aed',
};

interface Props {
  points: number;
  correctPredictions: number;
  totalPredictions: number;
  adsWatched: number;
  couponsClaimedCount: number;
  homeScore: number;
  awayScore: number;
  onClose: () => void;
}

function grade(correct: number, total: number): { letter: string; color: string } {
  if (total === 0) return { letter: 'N/A', color: T.muted };
  const pct = correct / total;
  if (pct >= 0.85) return { letter: 'A+', color: T.green };
  if (pct >= 0.7)  return { letter: 'A',  color: T.green };
  if (pct >= 0.55) return { letter: 'B',  color: T.teal  };
  if (pct >= 0.4)  return { letter: 'C',  color: T.gold  };
  return { letter: 'D', color: T.orange };
}

export function PostGameRecap({
  points, correctPredictions, totalPredictions,
  adsWatched, couponsClaimedCount,
  homeScore, awayScore, onClose,
}: Props) {
  const eaglesWon = homeScore > awayScore;
  const g = grade(correctPredictions, totalPredictions);
  const pct = totalPredictions > 0
    ? Math.round((correctPredictions / totalPredictions) * 100)
    : 0;

  const statCard = (emoji: string, value: string | number, label: string, color: string) => (
    <div style={{
      background: T.surface2, borderRadius: 12, padding: '12px 8px',
      textAlign: 'center', flex: 1,
    }}>
      <div style={{ fontSize: 22 }}>{emoji}</div>
      <div style={{
        fontSize: 22, fontWeight: 900, color,
        fontFamily: 'Bebas Neue, sans-serif', lineHeight: 1.1, marginTop: 2,
      }}>{value}</div>
      <div style={{ fontSize: 9, color: T.faint, marginTop: 3 }}>{label}</div>
    </div>
  );

  return (
    <div style={{
      height: '100%', overflowY: 'auto', padding: '12px 14px',
      display: 'flex', flexDirection: 'column', gap: 12,
      fontFamily: 'Inter, system-ui, sans-serif',
    }}>

      {/* Hero result */}
      <div style={{
        background: eaglesWon
          ? `linear-gradient(135deg, ${T.orange}22, ${T.gold}11)`
          : `linear-gradient(135deg, ${T.purple}22, ${T.red}11)`,
        border: `1px solid ${eaglesWon ? T.orange : T.purple}44`,
        borderRadius: 16, padding: '16px 14px', textAlign: 'center',
      }}>
        <div style={{ fontSize: 40, marginBottom: 6 }}>
          {eaglesWon ? '🏆' : '💪'}
        </div>
        <div style={{ fontSize: 22, fontWeight: 900, color: T.text, marginBottom: 4 }}>
          {eaglesWon ? 'Eagles Win!' : 'Better Luck Next Time'}
        </div>
        <div style={{ fontSize: 28, fontWeight: 900, fontFamily: 'Bebas Neue, sans-serif', color: T.gold, marginBottom: 4 }}>
          🦅 {homeScore} — {awayScore} 🐻
        </div>
        <div style={{ fontSize: 11, color: T.muted }}>
          {eaglesWon
            ? 'What a game! Eagles dominate the Bears on Arenza Sports.'
            : 'The Bears showed heart. Eagles will bounce back.'}
        </div>
      </div>

      {/* Your stats */}
      <div style={{ background: T.surface, border: `1px solid ${T.border}`, borderRadius: 14, padding: '12px 14px' }}>
        <div style={{ fontSize: 10, color: T.muted, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>
          Your Game Stats
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          {statCard('🏆', points, 'Points Earned', T.gold)}
          {statCard('🎯', `${pct}%`, 'Pick Accuracy', T.orange)}
          {statCard(g.letter, `${correctPredictions}/${totalPredictions}`, 'Predictions', g.color)}
        </div>
      </div>

      {/* Grade badge */}
      <div style={{
        background: T.surface, border: `1px solid ${T.border}`,
        borderRadius: 14, padding: '12px 14px',
        display: 'flex', alignItems: 'center', gap: 14,
      }}>
        <div style={{
          width: 56, height: 56, borderRadius: 14,
          background: `${g.color}22`, border: `2px solid ${g.color}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 26, fontWeight: 900, color: g.color,
          fontFamily: 'Bebas Neue, sans-serif', flexShrink: 0,
        }}>{g.letter}</div>
        <div>
          <div style={{ fontSize: 13, fontWeight: 800, color: T.text }}>Prediction Grade</div>
          <div style={{ fontSize: 11, color: T.muted, marginTop: 2 }}>
            {totalPredictions === 0
              ? 'Join predictions next game to earn a grade!'
              : pct >= 70
                ? 'Sharp picker — you read the game well!'
                : pct >= 40
                  ? 'Solid effort — keep predicting!'
                  : "Tough game — you'll get 'em next time."}
          </div>
          <div style={{ fontSize: 10, color: T.faint, marginTop: 4 }}>
            📺 {adsWatched} ads watched · 🎟 {couponsClaimedCount} coupons claimed
          </div>
        </div>
      </div>

      {/* Post-game offer */}
      {eaglesWon ? (
        <div style={{
          background: `linear-gradient(135deg, ${T.orange}, ${T.gold})`,
          borderRadius: 14, padding: '14px', textAlign: 'center',
        }}>
          <div style={{ fontSize: 16, fontWeight: 900, color: '#fff', marginBottom: 4 }}>
            🏆 Victory Round — Come Celebrate!
          </div>
          <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.85)', marginBottom: 10 }}>
            Any sponsor bar is ready for you. Mention Arenza for 10% off tonight.
          </div>
          <button style={{
            background: 'rgba(0,0,0,0.3)', border: '1px solid rgba(255,255,255,0.3)',
            borderRadius: 10, padding: '8px 20px', color: '#fff',
            fontWeight: 800, fontSize: 13, cursor: 'pointer',
          }}>
            🎟 Claim Victory Drink
          </button>
        </div>
      ) : (
        <div style={{
          background: `linear-gradient(135deg, ${T.purple}22, ${T.red}11)`,
          border: `1px solid ${T.purple}44`,
          borderRadius: 14, padding: '14px', textAlign: 'center',
        }}>
          <div style={{ fontSize: 16, fontWeight: 900, color: T.text, marginBottom: 4 }}>
            💪 Consolation Pint — 10% Off
          </div>
          <div style={{ fontSize: 11, color: T.muted, marginBottom: 10 }}>
            Come commiserate at any sponsor bar. Show this screen.
          </div>
          <button style={{
            background: T.purple, border: 'none',
            borderRadius: 10, padding: '8px 20px', color: '#fff',
            fontWeight: 800, fontSize: 13, cursor: 'pointer',
          }}>
            🍺 Claim Consolation Drink
          </button>
        </div>
      )}

      {/* Points summary */}
      <div style={{
        background: T.surface, border: `1px solid ${T.border}`, borderRadius: 14, padding: '12px 14px',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div>
          <div style={{ fontSize: 12, fontWeight: 800, color: T.text }}>Total Arenza Points</div>
          <div style={{ fontSize: 10, color: T.muted }}>Redeemable at any sponsor business</div>
        </div>
        <div style={{ fontSize: 28, fontWeight: 900, color: T.gold, fontFamily: 'Bebas Neue, sans-serif' }}>
          {points}
        </div>
      </div>

      {/* Close */}
      <button onClick={onClose} style={{
        width: '100%', padding: '12px 0', borderRadius: 12, border: 'none',
        background: T.surface2, color: T.muted, fontWeight: 700, fontSize: 13,
        cursor: 'pointer', fontFamily: 'Inter, system-ui, sans-serif',
      }}>
        Close Recap
      </button>
    </div>
  );
}
