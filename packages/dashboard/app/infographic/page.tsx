"use client";

import { useState } from "react";

const INFOGRAPHS = [
  "Future_of_Gamified_Sports_Advertising.jpg",
  "Future_of_Interactive_Sports_Advertising.jpg",
  "Gamified_Live_Sports_Advertising_Evolution.jpg",
  "Gamified_Sports_Advertising_Platform_Infographic.jpg",
  "Interactive_Sports_Advertising_Infographic.jpg",
  "Interactive_Sports_Advertising_Solutions.jpg",
  "Interactive_Sports_Advertising_Strategy.jpg",
  "Live_Engagement_Market_Trends_Infographic.jpg",
  "QR-Powered_Restaurant_Engagement_Infographic.jpg",
  "Restaurant_Engagement_Gamified_QR_Hubs.jpg",
  "Revolutionizing_Sports_Advertising_Blueprint.jpg",
  "Sports_Advertising_Architecture_Solution.jpg",
  "Sports_Platform_Advertising_Infographic.jpg",
  "Sports_Streaming_and_Gamified_Commerce.jpg",
  "The_Live_Commerce_Revolution.jpg",
];

const T = {
  bg: "#0b0e14",
  surface: "rgba(20,26,40,0.85)",
  border: "rgba(255,255,255,0.08)",
  text: "#e2e8f0",
  muted: "#8892b0",
};

export default function InfographicPage() {
  const [idx, setIdx] = useState(0);

  const prev = () => setIdx(i => (i === 0 ? INFOGRAPHS.length - 1 : i - 1));
  const next = () => setIdx(i => (i === INFOGRAPHS.length - 1 ? 0 : i + 1));
  const title = INFOGRAPHS[idx].replace(/_/g, " ").replace(".jpg", "");

  return (
    <div style={{ maxWidth: 1300, margin: "0 auto", padding: "1rem 0 4rem" }}>

      {/* Header */}
      <div style={{ textAlign: "center", marginBottom: "1.75rem" }}>
        <h1 style={{ margin: 0, fontSize: "1.6rem", fontWeight: 800, color: "#00c9b1", letterSpacing: "-0.4px" }}>
          🖼️ Platform Blueprint & Strategy
        </h1>
        <p style={{ color: T.muted, fontSize: "0.88rem", margin: "0.4rem 0 0" }}>
          Explore the architecture and market strategy behind the Arenza platform.
        </p>
      </div>

      {/* Main Viewer */}
      <div style={{ position: "relative", width: "100%", background: "#000", borderRadius: 18, overflow: "hidden", aspectRatio: "16/9", display: "flex", alignItems: "center", justifyContent: "center", border: `1px solid ${T.border}`, boxShadow: "0 8px 40px rgba(0,0,0,0.5)" }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          key={idx}
          src={`/InfoGraphs/${INFOGRAPHS[idx]}`}
          alt={title}
          style={{ width: "100%", height: "100%", objectFit: "contain" }}
        />

        {/* Left Arrow */}
        <button onClick={prev} style={{ position: "absolute", left: 20, top: "50%", transform: "translateY(-50%)", width: 52, height: 52, borderRadius: "50%", background: "rgba(0,0,0,0.75)", border: "1px solid #444", color: "#fff", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", backdropFilter: "blur(8px)", transition: "all 0.2s" }}
          onMouseOver={e => { e.currentTarget.style.background = "#00c9b1"; e.currentTarget.style.borderColor = "#00c9b1"; e.currentTarget.style.color = "#000"; }}
          onMouseOut={e => { e.currentTarget.style.background = "rgba(0,0,0,0.75)"; e.currentTarget.style.borderColor = "#444"; e.currentTarget.style.color = "#fff"; }}>
          <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="m15 18-6-6 6-6"/></svg>
        </button>

        {/* Right Arrow */}
        <button onClick={next} style={{ position: "absolute", right: 20, top: "50%", transform: "translateY(-50%)", width: 52, height: 52, borderRadius: "50%", background: "rgba(0,0,0,0.75)", border: "1px solid #444", color: "#fff", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", backdropFilter: "blur(8px)", transition: "all 0.2s" }}
          onMouseOver={e => { e.currentTarget.style.background = "#00c9b1"; e.currentTarget.style.borderColor = "#00c9b1"; e.currentTarget.style.color = "#000"; }}
          onMouseOut={e => { e.currentTarget.style.background = "rgba(0,0,0,0.75)"; e.currentTarget.style.borderColor = "#444"; e.currentTarget.style.color = "#fff"; }}>
          <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="m9 18 6-6-6-6"/></svg>
        </button>

        {/* Counter */}
        <div style={{ position: "absolute", bottom: 16, right: 20, background: "rgba(0,0,0,0.75)", border: "1px solid #444", padding: "5px 16px", borderRadius: 24, fontSize: 13, fontWeight: 600, color: "#fff", backdropFilter: "blur(6px)", letterSpacing: "0.5px" }}>
          {idx + 1} <span style={{ color: "#555", margin: "0 2px" }}>/</span> {INFOGRAPHS.length}
        </div>
      </div>

      {/* Slide Title */}
      <div style={{ textAlign: "center", marginTop: "1.1rem", fontSize: "1.05rem", fontWeight: 600, color: T.text }}>
        {title}
      </div>

      {/* Thumbnail Strip */}
      <div style={{ display: "flex", gap: 10, overflowX: "auto", padding: "1.25rem 0 0.5rem", marginTop: "0.5rem", scrollbarWidth: "thin", scrollbarColor: "#333 transparent" }}>
        {INFOGRAPHS.map((g, i) => (
          <button
            key={i}
            onClick={() => setIdx(i)}
            style={{ flexShrink: 0, width: 136, height: 77, padding: 0, background: "#000", border: idx === i ? "2px solid #00c9b1" : "2px solid rgba(255,255,255,0.07)", borderRadius: 10, overflow: "hidden", cursor: "pointer", opacity: idx === i ? 1 : 0.35, transition: "all 0.22s", boxShadow: idx === i ? "0 2px 14px rgba(0,201,177,0.35)" : "none" }}
            onMouseOver={e => { if (idx !== i) e.currentTarget.style.opacity = "0.75"; }}
            onMouseOut={e => { if (idx !== i) e.currentTarget.style.opacity = "0.35"; }}
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={`/InfoGraphs/${g}`} alt={`Slide ${i + 1}`} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
          </button>
        ))}
      </div>

      <style>{`button:hover { filter: brightness(1.05); }`}</style>
    </div>
  );
}
