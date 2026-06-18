import { PdfSlideshow } from "./components/PdfSlideshow";

/* ── Slide data (timing comes from cues.json, not hardcoded) ── */

const SPORTS_V1_SLIDES = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/sports-v1/p${i + 1}.png` }));
const SPORTS_SLIDES    = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/sports/p${i + 1}.png` }));
const LOYALTY_SLIDES   = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/loyalty/p${i + 1}.png` }));

/* ── Page ──────────────────────────────────────────────────── */

export default function DashboardHome() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "2.5rem" }}>



      {/* Deck 1: Interactive Canvas (Sports V1) */}
      <PdfSlideshow
        title="ArenzaTV: The Interactive Canvas"
        subtitle="Deck 1 — Sports FAST · AI Ad Monetization · Gamification"
        accent="#3B82F6"
        slides={SPORTS_V1_SLIDES}
        audioSrc="/audio/arenza-sports-v1.mp3"
        cuesSrc="/audio/arenza-sports-v1-cues.json"
      />

      {/* Deck 2: LvlUp E-commerce (Sports) */}
      <PdfSlideshow
        title="LvlUp E-commerce"
        subtitle="Deck 2 — Sports Retail · Fan Commerce · Live Shopping"
        accent="#8B5CF6"
        slides={SPORTS_SLIDES}
        audioSrc="/audio/arenza-sports.mp3"
        cuesSrc="/audio/arenza-sports-cues.json"
      />

      {/* Deck 3: Frictionless Restaurant Loyalty */}
      <PdfSlideshow
        title="Frictionless Restaurant Loyalty"
        subtitle="Deck 3 — QR Wallet · Apple Wallet · POS Integration"
        accent="#f59e0b"
        slides={LOYALTY_SLIDES}
        audioSrc="/audio/arenza-loyalty.mp3"
        cuesSrc="/audio/arenza-loyalty-cues.json"
      />
    </div>
  );
}
