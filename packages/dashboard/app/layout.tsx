import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Project Clarity — AntiGravity Dashboard",
  description: "Real-time ad delivery verification and CMXS node rewards",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <header style={{ padding: '1rem 2rem', borderBottom: '1px solid rgba(255,255,255,0.1)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h1 className="gradient-text" style={{ margin: 0, fontSize: '1.5rem', fontWeight: 'bold' }}>AntiGravity Network</h1>
          <nav style={{ display: 'flex', gap: '1.5rem', fontSize: '0.9rem', color: '#94a3b8' }}>
            <span>Token</span>
            <span>Network</span>
            <span>Auctions</span>
            <span>PoD Feed</span>
          </nav>
        </header>
        <main style={{ padding: '2rem', maxWidth: '1400px', margin: '0 auto' }}>
          {children}
        </main>
      </body>
    </html>
  );
}
