import { PdfSlideshow } from "./components/PdfSlideshow";

/* ── Slide data (timing comes from cues.json, not hardcoded) ── */

const SPORTS_V1_SLIDES    = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/sports-v1/p${i + 1}.png` }));
const SPORTS_SLIDES       = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/sports/p${i + 1}.png` }));
const LOYALTY_SLIDES      = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/loyalty/p${i + 1}.png` }));
const FAST_SLIDES         = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/fast-blueprint/p${i + 1}.png` }));
const STRATEGIC_SLIDES    = Array.from({ length: 20 }, (_, i) => ({ src: `/slides/strategic-playbook/p${i + 1}.png` }));
const TACTICAL_SLIDES     = Array.from({ length: 13 }, (_, i) => ({ src: `/slides/tactical-blueprint/p${i + 1}.png` }));
const ARCHITECTURE_SLIDES = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/architecture/p${i + 1}.png` }));

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

      {/* Deck 4: Arenza FAST Blueprint */}
      <PdfSlideshow
        title="Arenza FAST Blueprint"
        subtitle="Deck 4 — Free Ad-Supported Streaming · Channel Strategy · Revenue Model"
        accent="#06b6d4"
        slides={FAST_SLIDES}
        audioSrc="/audio/fast-blueprint.mp3"
        cuesSrc="/audio/fast-blueprint-cues.json"
      />

      {/* Deck 5: Arenza Strategic Playbook */}
      <PdfSlideshow
        title="Arenza Strategic Playbook"
        subtitle="Deck 5 — Go-To-Market · Partnership Strategy · Growth Roadmap"
        accent="#a855f7"
        slides={STRATEGIC_SLIDES}
        audioSrc="/audio/strategic-playbook.mp3"
        cuesSrc="/audio/strategic-playbook-cues.json"
      />

      {/* Deck 6: Arenza Tactical Blueprint */}
      <PdfSlideshow
        title="Arenza Tactical Blueprint"
        subtitle="Deck 6 — Campaign Execution · Ad Formats · Measurement"
        accent="#f43f5e"
        slides={TACTICAL_SLIDES}
        audioSrc="/audio/tactical-blueprint.mp3"
        cuesSrc="/audio/tactical-blueprint-cues.json"
      />

      {/* Deck 7: The Arenza Architecture */}
      <PdfSlideshow
        title="The Arenza Architecture"
        subtitle="Deck 7 — Technical Stack · On-Chain PoD · DePIN Infrastructure"
        accent="#10b981"
        slides={ARCHITECTURE_SLIDES}
        audioSrc="/audio/architecture.mp3"
        cuesSrc="/audio/architecture-cues.json"
      />
    </div>
  );
}
