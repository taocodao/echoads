'use client';
/**
 * scanner/page.tsx — Arenza Business Scanner (Web Demo)
 * iOS equivalent: native AVFoundation camera + CoreNFC scanner app
 */

import { useState, useRef, useEffect, useCallback } from 'react';
import { validateToken, generateToken, getOrCreateUserId } from '../game/lib/qrToken';
import {
  getMember, getOrCreateMembership, addStamp, redeemCoupon,
  recordPurchase, BUSINESS_CATALOG, type BusinessMembership,
} from '../game/lib/memberStore';

const T = {
  bg: '#0a0c10', surface: '#141720', surface2: '#1a1e2a',
  border: 'rgba(255,255,255,0.08)',
  text: '#f0f2ff', muted: '#8892b0', faint: '#4a5568',
  orange: '#ff6b35', teal: '#00c9b1', gold: '#ffc107',
  green: '#22c55e', red: '#ef4444', purple: '#7c3aed',
};

type ScanState = 'idle' | 'scanning' | 'success' | 'error';

interface ScanResult {
  userId: string;
  businessId: string;
  membership: BusinessMembership;
  memberName: string;
}

const TIER_COLOR: Record<string, string> = {
  'Guest': T.muted, 'Regular': T.teal, 'VIP': T.gold, 'Founding Member': T.orange,
};

export default function ScannerPage() {
  const [state, setState] = useState<ScanState>('idle');
  const [result, setResult] = useState<ScanResult | null>(null);
  const [error, setError] = useState('');
  const [actionToast, setActionToast] = useState('');
  const [manualInput, setManualInput] = useState('');
  const [showManual, setShowManual] = useState(false);
  const [selectedBizId, setSelectedBizId] = useState('roccos');
  const videoRef = useRef<HTMLVideoElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const detectorRef = useRef<unknown>(null);
  const animFrameRef = useRef<number>(0);

  const processToken = useCallback((token: string) => {
    const payload = validateToken(token);
    if (!payload.valid) {
      setState('error');
      setError(payload.error ?? 'Invalid QR code');
      return;
    }
    const userId = payload.userId!;
    const bizId = payload.businessId === 'ALL' ? selectedBizId : payload.businessId!;
    const member = getMember(userId);
    const membership = getOrCreateMembership(userId, bizId);
    setResult({ userId, businessId: bizId, membership, memberName: member.displayName });
    setState('success');
  }, [selectedBizId]);

  const startCamera = useCallback(async () => {
    setState('scanning');
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        videoRef.current.play();
      }

      // Use BarcodeDetector if available (Chrome/Android)
      if ('BarcodeDetector' in window) {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const detector = new (window as any).BarcodeDetector({ formats: ['qr_code'] });
        detectorRef.current = detector;

        const scan = async () => {
          if (!videoRef.current || videoRef.current.readyState < 2) {
            animFrameRef.current = requestAnimationFrame(scan);
            return;
          }
          try {
            const barcodes = await detector.detect(videoRef.current);
            if (barcodes.length > 0) {
              stopCamera();
              processToken(barcodes[0].rawValue);
              return;
            }
          } catch { /* continue */ }
          animFrameRef.current = requestAnimationFrame(scan);
        };
        animFrameRef.current = requestAnimationFrame(scan);
      } else {
        // Fallback: show manual input
        setShowManual(true);
      }
    } catch {
      setState('error');
      setError('Camera access denied. Use manual entry below.');
      setShowManual(true);
    }
  }, [processToken]);

  const stopCamera = useCallback(() => {
    cancelAnimationFrame(animFrameRef.current);
    streamRef.current?.getTracks().forEach(t => t.stop());
    streamRef.current = null;
  }, []);

  useEffect(() => () => stopCamera(), [stopCamera]);

  const toast = (msg: string) => {
    setActionToast(msg);
    setTimeout(() => setActionToast(''), 2500);
  };

  const handleStamp = () => {
    if (!result) return;
    const { membership: updated, rewardUnlocked } = addStamp(result.userId, result.businessId);
    setResult(r => r ? { ...r, membership: updated } : r);
    toast(rewardUnlocked ? '🎉 Stamp card complete — free reward unlocked!' : `⭐ Stamp added! ${updated.stamps}/${updated.stampsRequired}`);
  };

  const handleRedeem = (couponId: string) => {
    if (!result) return;
    const res = redeemCoupon(result.userId, result.businessId, couponId);
    if (res.success) {
      const updated = getOrCreateMembership(result.userId, result.businessId);
      setResult(r => r ? { ...r, membership: updated } : r);
      toast(`✅ Redeemed: ${res.coupon?.offer}`);
    } else {
      toast(`❌ ${res.error}`);
    }
  };

  const handlePurchase = () => {
    if (!result) return;
    const updated = recordPurchase(result.userId, result.businessId, 'In-store purchase', 35);
    setResult(r => r ? { ...r, membership: updated } : r);
    toast(`💳 Purchase recorded — +${Math.floor(35 * 10)} pts`);
  };

  const reset = () => {
    setState('idle');
    setResult(null);
    setError('');
    setManualInput('');
  };

  const activeCoupons = result?.membership.activeCoupons.filter(c => !c.redeemed && Date.now() < c.expiresAt) ?? [];

  return (
    <div style={{
      minHeight: '100vh', background: T.bg, color: T.text,
      fontFamily: 'Inter, system-ui, sans-serif', display: 'flex', flexDirection: 'column',
    }}>
      {/* Header */}
      <div style={{
        display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
        background: T.surface, borderBottom: `1px solid ${T.border}`,
      }}>
        <div style={{ fontSize: 24 }}>📷</div>
        <div>
          <div style={{ fontSize: 16, fontWeight: 900 }}>Arenza Business Scanner</div>
          <div style={{ fontSize: 10, color: T.muted }}>
            iOS equivalent: AVFoundation + CoreNFC
          </div>
        </div>
      </div>

      <div style={{ flex: 1, padding: 16, display: 'flex', flexDirection: 'column', gap: 12, maxWidth: 480, margin: '0 auto', width: '100%' }}>

        {/* Business selector */}
        <div style={{ background: T.surface, borderRadius: 14, padding: 14, border: `1px solid ${T.border}` }}>
          <div style={{ fontSize: 10, color: T.muted, marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
            Scanning for
          </div>
          <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
            {Object.entries(BUSINESS_CATALOG).map(([id, biz]) => (
              <button key={id} onClick={() => setSelectedBizId(id)} style={{
                padding: '5px 10px', borderRadius: 8, cursor: 'pointer', fontSize: 10, fontWeight: 700,
                background: selectedBizId === id ? `${T.orange}22` : T.surface2,
                border: `1px solid ${selectedBizId === id ? T.orange : T.border}`,
                color: selectedBizId === id ? T.orange : T.muted,
              }}>{biz.emoji} {biz.name.split(' ')[0]}</button>
            ))}
          </div>
        </div>

        {/* ── IDLE ── */}
        {state === 'idle' && (
          <div style={{
            background: T.surface, borderRadius: 16, padding: 24, textAlign: 'center',
            border: `1px solid ${T.border}`, display: 'flex', flexDirection: 'column', gap: 14,
          }}>
            <div style={{ fontSize: 60 }}>📲</div>
            <div style={{ fontSize: 16, fontWeight: 800 }}>Ready to Scan</div>
            <div style={{ fontSize: 12, color: T.muted }}>
              Point camera at the member's Arenza QR code
            </div>
            <button onClick={startCamera} style={{
              padding: '13px 0', borderRadius: 12, border: 'none', cursor: 'pointer',
              background: `linear-gradient(135deg, ${T.orange}, ${T.gold})`,
              color: '#fff', fontWeight: 900, fontSize: 15,
              boxShadow: `0 6px 24px ${T.orange}44`,
            }}>
              📷 Open Camera
            </button>
            <button onClick={() => setShowManual(true)} style={{
              padding: '10px 0', borderRadius: 10, border: `1px solid ${T.border}`,
              background: T.surface2, color: T.muted, cursor: 'pointer', fontSize: 12, fontWeight: 600,
            }}>
              ⌨️ Enter Token Manually
            </button>

            {/* Demo: generate test token */}
            <div style={{ borderTop: `1px solid ${T.border}`, paddingTop: 12 }}>
              <div style={{ fontSize: 10, color: T.faint, marginBottom: 8 }}>Demo: Simulate scan</div>
              <button onClick={() => {
                processToken(generateToken(getOrCreateUserId(), selectedBizId));
              }} style={{
                padding: '8px 16px', borderRadius: 8, border: `1px solid ${T.teal}44`,
                background: `${T.teal}11`, color: T.teal, cursor: 'pointer', fontSize: 11, fontWeight: 700,
              }}>
                🧪 Simulate Customer Scan
              </button>
            </div>
          </div>
        )}

        {/* ── SCANNING ── */}
        {state === 'scanning' && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div style={{
              background: '#000', borderRadius: 16, overflow: 'hidden',
              border: `2px solid ${T.orange}66`, position: 'relative', aspectRatio: '1',
            }}>
              <video ref={videoRef} playsInline muted style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              {/* Scan corners */}
              {['topleft','topright','bottomleft','bottomright'].map(pos => (
                <div key={pos} style={{
                  position: 'absolute', width: 24, height: 24,
                  borderColor: T.orange, borderStyle: 'solid', borderWidth: 0,
                  ...(pos.includes('top') ? { top: 16, borderTopWidth: 3 } : { bottom: 16, borderBottomWidth: 3 }),
                  ...(pos.includes('left') ? { left: 16, borderLeftWidth: 3 } : { right: 16, borderRightWidth: 3 }),
                }} />
              ))}
              <div style={{
                position: 'absolute', bottom: 16, left: '50%', transform: 'translateX(-50%)',
                background: 'rgba(0,0,0,0.7)', borderRadius: 20, padding: '6px 14px',
                fontSize: 11, color: '#fff',
              }}>Scanning…</div>
            </div>
            <button onClick={() => { stopCamera(); reset(); }} style={{
              padding: '10px', borderRadius: 10, border: `1px solid ${T.border}`,
              background: T.surface2, color: T.muted, cursor: 'pointer', fontSize: 12,
            }}>Cancel</button>
          </div>
        )}

        {/* ── MANUAL INPUT ── */}
        {(state === 'idle' || state === 'scanning') && showManual && (
          <div style={{ background: T.surface, borderRadius: 14, padding: 14, border: `1px solid ${T.border}` }}>
            <div style={{ fontSize: 11, color: T.muted, marginBottom: 8 }}>Paste or type QR token:</div>
            <div style={{ display: 'flex', gap: 8 }}>
              <input
                value={manualInput}
                onChange={e => setManualInput(e.target.value)}
                placeholder="ARZ-U123456-roccos-..."
                style={{
                  flex: 1, background: T.surface2, border: `1px solid ${T.border}`,
                  borderRadius: 8, padding: '8px 10px', color: T.text, fontSize: 11,
                  fontFamily: 'JetBrains Mono, monospace',
                }}
              />
              <button onClick={() => processToken(manualInput)} style={{
                padding: '8px 12px', borderRadius: 8, border: 'none',
                background: T.orange, color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 12,
              }}>→</button>
            </div>
          </div>
        )}

        {/* ── ERROR ── */}
        {state === 'error' && (
          <div style={{
            background: `${T.red}11`, border: `1px solid ${T.red}44`,
            borderRadius: 14, padding: 20, textAlign: 'center',
          }}>
            <div style={{ fontSize: 36, marginBottom: 8 }}>❌</div>
            <div style={{ fontSize: 14, fontWeight: 800, color: T.red, marginBottom: 6 }}>Scan Failed</div>
            <div style={{ fontSize: 12, color: T.muted, marginBottom: 14 }}>{error}</div>
            <button onClick={reset} style={{
              padding: '10px 24px', borderRadius: 10, border: 'none',
              background: T.surface2, color: T.muted, cursor: 'pointer', fontSize: 12,
            }}>Try Again</button>
          </div>
        )}

        {/* ── SUCCESS: Member Profile ── */}
        {state === 'success' && result && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>

            {/* Member header */}
            <div style={{
              background: `linear-gradient(135deg, ${T.green}22, ${T.teal}11)`,
              border: `1px solid ${T.green}44`, borderRadius: 16, padding: '14px 16px',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 48, height: 48, borderRadius: 14,
                  background: `linear-gradient(135deg, ${T.orange}, ${T.gold})`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 22, flexShrink: 0,
                }}>
                  {BUSINESS_CATALOG[result.businessId]?.emoji ?? '👤'}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 16, fontWeight: 900, color: T.text }}>{result.memberName}</div>
                  <div style={{ fontSize: 10, color: T.muted }}>
                    {BUSINESS_CATALOG[result.businessId]?.name} · ID: {result.userId}
                  </div>
                  <div style={{ display: 'flex', gap: 6, marginTop: 4, alignItems: 'center' }}>
                    <span style={{
                      padding: '2px 8px', borderRadius: 6, fontSize: 9, fontWeight: 800,
                      background: `${TIER_COLOR[result.membership.memberTier]}22`,
                      color: TIER_COLOR[result.membership.memberTier],
                      border: `1px solid ${TIER_COLOR[result.membership.memberTier]}44`,
                    }}>{result.membership.memberTier}</span>
                    <span style={{ fontSize: 9, color: T.muted }}>
                      {result.membership.visitCount} visits · joined today
                    </span>
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ fontSize: 22, fontWeight: 900, color: T.gold, fontFamily: 'Bebas Neue, sans-serif' }}>
                    {result.membership.pointsBalance}
                  </div>
                  <div style={{ fontSize: 8, color: T.faint }}>POINTS</div>
                </div>
              </div>
            </div>

            {/* Stamp card */}
            <div style={{ background: T.surface, borderRadius: 14, padding: '12px 14px', border: `1px solid ${T.border}` }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                <div style={{ fontSize: 11, fontWeight: 800, color: T.text }}>⭐ Loyalty Stamps</div>
                <div style={{ fontSize: 10, color: T.muted }}>
                  {result.membership.stamps}/{result.membership.stampsRequired}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 4, marginBottom: 10 }}>
                {Array.from({ length: result.membership.stampsRequired }).map((_, i) => (
                  <div key={i} style={{
                    flex: 1, height: 18, borderRadius: 4,
                    background: i < result.membership.stamps
                      ? `linear-gradient(135deg, ${T.orange}, ${T.gold})` : T.surface2,
                    border: `1px solid ${i < result.membership.stamps ? T.orange : T.border}`,
                  }} />
                ))}
              </div>
              <button onClick={handleStamp} style={{
                width: '100%', padding: '10px', borderRadius: 10, border: 'none', cursor: 'pointer',
                background: `linear-gradient(135deg, ${T.orange}, ${T.gold})`,
                color: '#fff', fontWeight: 800, fontSize: 13,
                boxShadow: `0 4px 16px ${T.orange}44`,
              }}>
                ⭐ Add Stamp
              </button>
            </div>

            {/* Active coupons */}
            {activeCoupons.length > 0 && (
              <div style={{ background: T.surface, borderRadius: 14, padding: '12px 14px', border: `1px solid ${T.border}` }}>
                <div style={{ fontSize: 11, fontWeight: 800, color: T.text, marginBottom: 8 }}>
                  🎟 Active Coupons ({activeCoupons.length})
                </div>
                {activeCoupons.map(c => (
                  <div key={c.id} style={{
                    display: 'flex', alignItems: 'center', gap: 10, padding: '8px 10px',
                    background: `${T.green}11`, border: `1px solid ${T.green}33`,
                    borderRadius: 10, marginBottom: 6,
                  }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: 12, fontWeight: 700, color: T.text }}>{c.offer}</div>
                      <div style={{ fontSize: 9, color: T.muted }}>{c.value}</div>
                    </div>
                    <button onClick={() => handleRedeem(c.id)} style={{
                      padding: '6px 12px', borderRadius: 8, border: 'none', cursor: 'pointer',
                      background: T.green, color: '#fff', fontWeight: 800, fontSize: 11,
                    }}>REDEEM</button>
                  </div>
                ))}
              </div>
            )}

            {/* Record purchase */}
            <div style={{ background: T.surface, borderRadius: 14, padding: '12px 14px', border: `1px solid ${T.border}` }}>
              <div style={{ fontSize: 11, fontWeight: 800, color: T.text, marginBottom: 8 }}>💳 Record Purchase</div>
              <button onClick={handlePurchase} style={{
                width: '100%', padding: '10px', borderRadius: 10, border: `1px solid ${T.border}`,
                background: T.surface2, color: T.muted, cursor: 'pointer', fontSize: 12, fontWeight: 600,
              }}>
                💳 Record $35 Purchase (+350 pts)
              </button>
            </div>

            {/* Recent history */}
            {result.membership.purchaseHistory.length > 0 && (
              <div style={{ background: T.surface, borderRadius: 14, padding: '12px 14px', border: `1px solid ${T.border}` }}>
                <div style={{ fontSize: 11, fontWeight: 800, color: T.text, marginBottom: 8 }}>📋 Visit History</div>
                {result.membership.purchaseHistory.slice(-3).reverse().map(p => (
                  <div key={p.id} style={{
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                    padding: '6px 0', borderBottom: `1px solid ${T.border}`, fontSize: 10,
                  }}>
                    <span style={{ color: T.muted }}>{p.description}</span>
                    <span style={{ color: T.gold, fontWeight: 700 }}>+{p.pointsEarned} pts</span>
                  </div>
                ))}
              </div>
            )}

            {/* Scan again */}
            <button onClick={reset} style={{
              padding: '12px', borderRadius: 12, border: `1px solid ${T.border}`,
              background: T.surface2, color: T.muted, cursor: 'pointer', fontSize: 12, fontWeight: 600,
            }}>
              ← Scan Another Customer
            </button>
          </div>
        )}
      </div>

      {/* Action toast */}
      {actionToast && (
        <div style={{
          position: 'fixed', bottom: 24, left: '50%', transform: 'translateX(-50%)',
          background: T.surface, border: `1px solid ${T.green}44`,
          borderRadius: 12, padding: '10px 18px', zIndex: 100,
          fontSize: 12, fontWeight: 700, color: T.text, whiteSpace: 'nowrap',
          boxShadow: `0 8px 32px rgba(0,0,0,0.4)`,
        }}>{actionToast}</div>
      )}

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Inter:wght@400;600;700;800;900&family=JetBrains+Mono:wght@400;600&display=swap');
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
        * { box-sizing: border-box; }
      `}</style>
    </div>
  );
}
