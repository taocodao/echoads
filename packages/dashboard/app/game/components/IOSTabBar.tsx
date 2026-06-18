'use client';

const T = {
  bg: '#0d0f14', border: 'rgba(255,255,255,0.08)',
  orange: '#ff6b35', muted: '#64748b', red: '#ef4444',
};

// 9 tabs — original 6 + 3 new (Marketplace, Wallet, Leaderboard)
export type TabKey =
  | 'predict' | 'bingo' | 'scratch' | 'moreless'
  | 'market' | 'wallet' | 'board'
  | 'me' | 'ads';

const TABS: { key: TabKey; icon: string; label: string }[] = [
  { key: 'predict',  icon: '🎯', label: 'Predict'  },
  { key: 'bingo',    icon: '🎲', label: 'Bingo'    },
  { key: 'scratch',  icon: '🎟', label: 'Scratch'  },
  { key: 'moreless', icon: '📊', label: 'M/L'      },
  { key: 'market',   icon: '📍', label: 'Local'    },
  { key: 'wallet',   icon: '💳', label: 'Wallet'   },
  { key: 'board',    icon: '🏆', label: 'Leaders'  },
  { key: 'me',       icon: '👤', label: 'Me'       },
  { key: 'ads',      icon: '📺', label: 'Ads'      },
];

export function IOSTabBar({
  active,
  onChange,
  walletBadge = 0,
}: {
  active: TabKey;
  onChange: (k: TabKey) => void;
  walletBadge?: number;
}) {
  return (
    <div style={{
      display:'flex', justifyContent:'space-around', padding:'6px 0 2px',
      background:'rgba(13,15,20,.96)', backdropFilter:'blur(12px)',
      borderTop:`1px solid ${T.border}`, flexShrink:0,
      overflowX: 'auto', scrollbarWidth: 'none',
    }}>
      {TABS.map(t => (
        <button key={t.key} onClick={() => onChange(t.key)} style={{
          flex:'0 0 auto', display:'flex', flexDirection:'column', alignItems:'center', gap:1,
          background:'none', border:'none', cursor:'pointer', padding:'4px 6px',
          color: active === t.key ? T.orange : T.muted,
          transition:'color .15s', fontFamily:'Inter,system-ui,sans-serif',
          minWidth: 44, position: 'relative',
        }}>
          <span style={{ fontSize:18, lineHeight:1 }}>{t.icon}</span>
          <span style={{ fontSize:8, fontWeight:600, whiteSpace:'nowrap' }}>{t.label}</span>
          {/* Notification badge on Wallet tab */}
          {t.key === 'wallet' && walletBadge > 0 && (
            <span style={{
              position: 'absolute', top: 0, right: 4,
              background: T.red, color: '#fff',
              borderRadius: '50%', width: 14, height: 14,
              fontSize: 8, fontWeight: 900, lineHeight: '14px', textAlign: 'center',
            }}>
              {walletBadge > 9 ? '9+' : walletBadge}
            </span>
          )}
        </button>
      ))}
    </div>
  );
}

