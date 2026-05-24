import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Project Clarity — SlingDePIN Dashboard",
  description: "Real-time ad delivery verification and CMXS node rewards — powered by MOQ + x402 + Base",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
