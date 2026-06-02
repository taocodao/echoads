'use client';

/**
 * AdOverlay.tsx
 * ─────────────────────────────────────────────────────────────────────────────
 * x302 shoppable commerce overlay that slides up during an ad at T+20s.
 * Shows product card with Buy Now / Learn More CTAs.
 * Dismisses automatically when the ad ends or user closes it.
 */

import { useState, useEffect, useCallback } from 'react';

interface AdOverlayProps {
  /** Whether the overlay should be visible */
  visible: boolean;
  /** Ad details from SSAI manifest EXT-X-SESSION-DATA */
  adInfo: {
    advertiser: string;
    product: string;
    price: string;
    impressionId: string;
  } | null;
  /** Called when user clicks Buy Now */
  onBuyNow: (impressionId: string) => void;
  /** Called when user closes overlay */
  onDismiss: () => void;
}

export function AdOverlay({ visible, adInfo, onBuyNow, onDismiss }: AdOverlayProps) {
  const [checkoutOpen, setCheckoutOpen] = useState(false);

  // Reset checkout state when overlay hides
  useEffect(() => {
    if (!visible) setCheckoutOpen(false);
  }, [visible]);

  const handleBuyNow = useCallback(() => {
    if (!adInfo) return;
    setCheckoutOpen(true);
    onBuyNow(adInfo.impressionId);
  }, [adInfo, onBuyNow]);

  if (!adInfo) return null;

  return (
    <>
      {/* Overlay slide-up panel */}
      <div style={{
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        transform: visible ? 'translateY(0)' : 'translateY(100%)',
        transition: 'transform 0.4s cubic-bezier(0.16, 1, 0.3, 1)',
        background: 'linear-gradient(to top, rgba(0,0,0,0.95) 0%, rgba(0,0,0,0.85) 100%)',
        backdropFilter: 'blur(16px)',
        borderTop: '1px solid rgba(255,255,255,0.12)',
        padding: '1.25rem 1.5rem',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: '1rem',
        zIndex: 20,
      }}>
        {/* Product info */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flex: 1 }}>
          {/* Icon */}
          <div style={{
            width: 48, height: 48, borderRadius: 10,
            background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: '1.5rem', flexShrink: 0,
          }}>
            ⛳
          </div>
          {/* Text */}
          <div>
            <div style={{ fontSize: '0.7rem', color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
              {adInfo.advertiser}
            </div>
            <div style={{ fontSize: '1rem', fontWeight: 600, color: '#f8fafc', lineHeight: 1.3 }}>
              {adInfo.product}
            </div>
            <div style={{ fontSize: '1rem', fontWeight: 700, color: '#3B82F6', marginTop: 2 }}>
              {adInfo.price}
            </div>
          </div>
        </div>

        {/* CTA buttons */}
        <div style={{ display: 'flex', gap: '0.75rem', flexShrink: 0 }}>
          <button
            onClick={onDismiss}
            style={{
              padding: '0.5rem 1rem',
              background: 'rgba(255,255,255,0.08)',
              border: '1px solid rgba(255,255,255,0.15)',
              borderRadius: 8,
              color: '#94a3b8',
              fontSize: '0.85rem',
              cursor: 'pointer',
              transition: 'background 0.2s',
            }}
          >
            ✕ Close
          </button>
          <button
            onClick={handleBuyNow}
            style={{
              padding: '0.5rem 1.25rem',
              background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)',
              border: 'none',
              borderRadius: 8,
              color: '#fff',
              fontSize: '0.85rem',
              fontWeight: 600,
              cursor: 'pointer',
              boxShadow: '0 0 20px rgba(59,130,246,0.4)',
              transition: 'opacity 0.2s',
            }}
          >
            🛒 Buy Now
          </button>
        </div>
      </div>

      {/* Simulated checkout modal */}
      {checkoutOpen && (
        <div style={{
          position: 'fixed', inset: 0, zIndex: 100,
          background: 'rgba(0,0,0,0.8)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <div style={{
            background: 'linear-gradient(135deg, #1e293b, #0f172a)',
            border: '1px solid rgba(255,255,255,0.12)',
            borderRadius: 16, padding: '2rem', width: 400, maxWidth: '90vw',
            boxShadow: '0 25px 50px rgba(0,0,0,0.5)',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <h3 style={{ margin: 0, fontSize: '1.1rem', color: '#f8fafc' }}>Complete Purchase</h3>
              <button
                onClick={() => setCheckoutOpen(false)}
                style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer', fontSize: '1.25rem' }}
              >✕</button>
            </div>

            <div style={{
              background: 'rgba(59,130,246,0.08)', border: '1px solid rgba(59,130,246,0.2)',
              borderRadius: 10, padding: '1rem', marginBottom: '1.5rem',
            }}>
              <div style={{ fontSize: '0.8rem', color: '#94a3b8' }}>{adInfo.advertiser}</div>
              <div style={{ fontSize: '1rem', color: '#f8fafc', fontWeight: 600, margin: '0.25rem 0' }}>
                {adInfo.product}
              </div>
              <div style={{ fontSize: '1.25rem', color: '#3B82F6', fontWeight: 700 }}>{adInfo.price}</div>
            </div>

            <div style={{ display: 'flex', gap: '0.75rem', marginBottom: '1rem' }}>
              <input
                placeholder="Card number"
                style={{
                  flex: 1, padding: '0.65rem 0.85rem',
                  background: 'rgba(255,255,255,0.05)',
                  border: '1px solid rgba(255,255,255,0.1)',
                  borderRadius: 8, color: '#f8fafc', fontSize: '0.85rem',
                }}
              />
            </div>

            <button
              onClick={() => { setCheckoutOpen(false); onDismiss(); }}
              style={{
                width: '100%', padding: '0.85rem',
                background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)',
                border: 'none', borderRadius: 10,
                color: '#fff', fontWeight: 700, fontSize: '1rem',
                cursor: 'pointer',
                boxShadow: '0 0 30px rgba(59,130,246,0.35)',
              }}
            >
              Pay {adInfo.price} — Apple Pay / Card
            </button>

            <p style={{ textAlign: 'center', fontSize: '0.7rem', color: '#475569', margin: '0.75rem 0 0' }}>
              Powered by CMXS x302 Commerce Protocol
            </p>
          </div>
        </div>
      )}
    </>
  );
}
