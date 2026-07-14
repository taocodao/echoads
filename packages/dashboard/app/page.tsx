import { PdfSlideshow } from "./components/PdfSlideshow";

/* ── Slide data (timing comes from cues.json, not hardcoded) ── */

const FRICTIONLESS_SPORTS_SLIDES = [
  { src: `/slides/frictionless-sports-engagement/p1.png`, title: "The Future of Frictionless Sports Engagement" },
  { src: `/slides/frictionless-sports-engagement/p2.png`, title: "Five Colliding Market Forces Validate the ArenzaTV Model" },
  { src: `/slides/frictionless-sports-engagement/p3.png`, title: "The Collapse of RSNs is Driving a FAST Sports Supercycle" },
  { src: `/slides/frictionless-sports-engagement/p4.png`, title: "Local Businesses Are Locked Out of Ads and Trapped by POS Loyalty" },
  { src: `/slides/frictionless-sports-engagement/p5.png`, title: "Eliminating the Hardware Barrier: The QR Hub Leap" },
  { src: `/slides/frictionless-sports-engagement/p6.png`, title: "Second-Screen Gamification Turns Distraction into Purchase Intent" },
  { src: `/slides/frictionless-sports-engagement/p7.png`, title: "The B2B2C Ecosystem Resolves the Market Fragmentation" },
  { src: `/slides/frictionless-sports-engagement/p8.png`, title: "The Generational Infrastructure Moat: DePIN Powered by MOQ" },
  { src: `/slides/frictionless-sports-engagement/p9.png`, title: "The Frictionless Attribution Loop in Action" },
  { src: `/slides/frictionless-sports-engagement/p10.png`, title: "Stacked Revenue Streams Replace Traditional SaaS Models" },
  { src: `/slides/frictionless-sports-engagement/p11.png`, title: "A Fragmented FAST Landscape Offers Immediate Partnership Targets" },
  { src: `/slides/frictionless-sports-engagement/p12.png`, title: "Proactive Mitigations for Key Structural Risks" },
  { src: `/slides/frictionless-sports-engagement/p13.png`, title: "A Multi-Billion Dollar Disruption Opportunity" },
  { src: `/slides/frictionless-sports-engagement/p14.png`, title: "Redefining Local Sports Monetization at Scale" },
];
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
      <div style={{ display: "flex", flexDirection: "column", gap: "1rem", position: "relative" }}>
        <PdfSlideshow
          title="ArenzaTV: Frictionless Sports Engagement"
          subtitle="Deck 12 — FAST Streaming · Local Loyalty · Fan Gamification · DePIN Infrastructure"
          accent="#22d3ee"
          slides={FRICTIONLESS_SPORTS_SLIDES}
          audioSrc="/audio/frictionless-sports-engagement.mp3"
          cuesSrc="/audio/frictionless-sports-engagement-cues.json"
        />
        
        <div style={{
          alignSelf: "flex-end",
          display: "flex",
          alignItems: "center",
          gap: "8px",
          animation: "bounce-down-scroll 2s infinite",
          color: "#22d3ee",
          fontSize: "14px",
          fontWeight: 600,
          paddingRight: "10px",
          pointerEvents: "none"
        }}>
          <style>{`
            @keyframes bounce-down-scroll {
              0%, 100% { transform: translateY(0); }
              50% { transform: translateY(8px); }
            }
          `}</style>
          Scroll for more pitch decks <span style={{ fontSize: 18 }}>👇</span>
        </div>
      </div>

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
