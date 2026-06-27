import { PdfSlideshow } from "./components/PdfSlideshow";

/* ── Slide data (timing comes from cues.json, not hardcoded) ── */

const FRICTIONLESS_SPORTS_SLIDES  = Array.from({ length: 14 }, (_, i) => ({ src: `/slides/frictionless-sports-engagement/p${i + 1}.png` }));
const SPORTS_V1_SLIDES    = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/sports-v1/p${i + 1}.png` }));
const SPORTS_SLIDES       = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/sports/p${i + 1}.png` }));
const LOYALTY_SLIDES      = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/loyalty/p${i + 1}.png` }));
const FAST_SLIDES         = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/fast-blueprint/p${i + 1}.png` }));
const STRATEGIC_SLIDES    = Array.from({ length: 20 }, (_, i) => ({ src: `/slides/strategic-playbook/p${i + 1}.png` }));
const TACTICAL_SLIDES     = Array.from({ length: 13 }, (_, i) => ({ src: `/slides/tactical-blueprint/p${i + 1}.png` }));
const ARCHITECTURE_SLIDES = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/architecture/p${i + 1}.png` }));
const CMXS_INFRASTRUCTURE_SLIDES = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/cmxs-infrastructure-engine/p${i + 1}.png` }));
const THE_35_SECOND_ENGINE_SLIDES = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/the-35-second-engine/p${i + 1}.png` }));
const VERIFIED_BROADCAST_SLIDES = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/verified-broadcast-blueprint/p${i + 1}.png` }));
const CMXS_VERIFIED_MEDIA_SLIDES = Array.from({ length: 15 }, (_, i) => ({ src: `/slides/cmxs-verified-media-infrastructure/p${i + 1}.png` }));

/* ── Page ──────────────────────────────────────────────────── */

export default function DashboardHome() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "2.5rem" }}>

      {/* Deck 12: ArenzaTV Frictionless Sports Engagement (NEW) */}
      <PdfSlideshow
        title="ArenzaTV: Frictionless Sports Engagement"
        subtitle="Deck 12 — FAST Streaming · Local Loyalty · Fan Gamification · DePIN Infrastructure"
        accent="#22d3ee"
        slides={FRICTIONLESS_SPORTS_SLIDES}
        audioSrc="/audio/frictionless-sports-engagement.mp3"
        cuesSrc="/audio/frictionless-sports-engagement-cues.json"
      />

      {/* Deck 1: Interactive Canvas (Sports V1) */}
      <PdfSlideshow
        title="ArenzaTV: The Interactive Canvas"
        subtitle="Deck 1 — Sports FAST · AI Ad Monetization · Gamification"
        accent="#3B82F6"
        slides={SPORTS_V1_SLIDES}
        audioSrc="/audio/arenza-sports-v1.mp3"
        cuesSrc="/audio/arenza-sports-v1-cues.json"
      />

      {/* Deck 2: Arenza Interactive Sports Engagement */}
      <PdfSlideshow
        title="Arenza Interactive Sports Engagement"
        subtitle="Deck 2 — Live Sports FAST · Gamified Ad Formats · Fan Commerce"
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

      {/* Deck 8: CMXS Infrastructure Engine */}
      <PdfSlideshow
        title="CMXS Infrastructure Engine"
        subtitle="Deck 8 — Media over QUIC · DePIN Edge · Base L2 PoD"
        accent="#f59e0b"
        slides={CMXS_INFRASTRUCTURE_SLIDES}
        audioSrc="/audio/cmxs-infrastructure-engine.mp3"
        cuesSrc="/audio/cmxs-infrastructure-engine-cues.json"
      />

      {/* Deck 9: The 35-Second Engine */}
      <PdfSlideshow
        title="The 35-Second Engine"
        subtitle="Deck 9 — Operational Blueprint · Settlement Mechanism · Verification"
        accent="#3B82F6"
        slides={THE_35_SECOND_ENGINE_SLIDES}
        audioSrc="/audio/the-35-second-engine.mp3"
        cuesSrc="/audio/the-35-second-engine-cues.json"
      />

      {/* Deck 10: Verified Broadcast Blueprint */}
      <PdfSlideshow
        title="Verified Broadcast Blueprint"
        subtitle="Deck 10 — DePIN Nodes · MoQ Protocol · Base L2 Revenue Ceiling"
        accent="#8B5CF6"
        slides={VERIFIED_BROADCAST_SLIDES}
        audioSrc="/audio/verified-broadcast-blueprint.mp3"
        cuesSrc="/audio/verified-broadcast-blueprint-cues.json"
      />

      {/* Deck 11: CMXS Verified Media Infrastructure */}
      <PdfSlideshow
        title="CMXS Verified Media Infrastructure"
        subtitle="Deck 11 — Glass-Box Architecture · Measurement Vacuum · Token Flywheel"
        accent="#ec4899"
        slides={CMXS_VERIFIED_MEDIA_SLIDES}
        audioSrc="/audio/cmxs-verified-media-infrastructure.mp3"
        cuesSrc="/audio/cmxs-verified-media-infrastructure-cues.json"
      />
    </div>
  );
}
