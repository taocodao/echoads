import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { NavBar } from "./components/NavBar";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "ArenzaTV — Gamified Sports FAST Ads for Local Commerce",
  description: "ArenzaTV connects Sports FAST viewers to local merchants at the moment of peak fan engagement. Gamified fan games. Apple Wallet rewards. Verified in-store redemption. No POS integration required.",
  openGraph: {
    title: "ArenzaTV — Gamified Sports FAST Ads for Local Commerce",
    description: "Fan plays. Wins a reward. Walks into your business. No app download. No POS needed. Live MVP at arenza.tv.",
    url: "https://arenza.tv",
    siteName: "ArenzaTV",
    images: [
      {
        url: "https://arenza.tv/assets/og-preview-v3.jpg",
        width: 1200,
        height: 627,
        type: "image/jpeg",
      },
    ],
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "ArenzaTV — Gamified Sports FAST Ads for Local Commerce",
    description: "Fan plays. Wins a reward. Walks into your business. No app download. No POS needed.",
    images: ["https://arenza.tv/assets/og-preview-v3.jpg"],
    site: "@arenzatv",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <NavBar />
        <main style={{ padding: "0.5rem 1.5rem 2rem", maxWidth: "1400px", margin: "0 auto" }}>
          {children}
        </main>
      </body>
    </html>
  );
}
