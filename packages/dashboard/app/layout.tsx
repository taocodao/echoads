import type { Metadata } from "next";
import { Inter } from "next/font/google";
import Link from "next/link";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "CMXS AntiGravity — Sports FAST Dashboard",
  description: "Real-time ad delivery, PoD verification, DePIN node rewards, and CMXS token lifecycle",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <header style={{
          padding: '0.9rem 2rem',
          borderBottom: '1px solid rgba(255,255,255,0.08)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          background: 'rgba(15,23,42,0.9)', backdropFilter: 'blur(12px)',
          position: 'sticky', top: 0, zIndex: 50,
        }}>
          <Link href="/" style={{ textDecoration: 'none' }}>
            <span style={{
              fontSize: '1.25rem', fontWeight: 800, letterSpacing: '-0.04em',
              background: 'linear-gradient(135deg, #3B82F6, #8B5CF6)',
              WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent',
            }}>
              CMXS AntiGravity
            </span>
          </Link>

          <nav style={{ display: 'flex', gap: '0.25rem' }}>
            {[
              { href: '/',         label: '📊 Overview'   },
              { href: '/player',   label: '📺 Live Player' },
              { href: '/auction',  label: '⚡ Auction'     },
              { href: '/nodes',    label: '🏗️ Nodes'       },
              { href: '/treasury', label: '💰 Treasury'    },
              { href: '/chain',    label: '🔗 On-Chain'    },
            ].map(({ href, label }) => (
              <Link key={href} href={href} style={{
                padding: '0.4rem 0.85rem',
                fontSize: '0.82rem', color: '#94a3b8',
                textDecoration: 'none', borderRadius: 6,
                transition: 'background 0.15s, color 0.15s',
              }}>
                {label}
              </Link>
            ))}
          </nav>
        </header>

        <main style={{ padding: '2rem', maxWidth: '1400px', margin: '0 auto' }}>
          {children}
        </main>
      </body>
    </html>
  );
}
