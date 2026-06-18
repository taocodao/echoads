"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

const NAV_ITEMS = [
  { href: "/",             label: "📊 Overview"    },
  { href: "/player",       label: "🎥 Video"       },
  { href: "/infographic",  label: "🖼️ Infographic" },
  { href: "/game",         label: "📱 iPhone Sim"  },
  { href: "/demo",         label: "🎬 Demo"        },
  { href: "/auction",      label: "⚡ Auction"     },
  { href: "/token",        label: "🪙 Token"       },
  { href: "/treasury",     label: "🏦 Treasury"    },
];

export function NavBar() {
  const pathname = usePathname();

  return (
    <header style={{
      padding: "0 0.75rem",
      height: "70px",
      borderBottom: "1px solid rgba(255,255,255,0.08)",
      display: "flex",
      alignItems: "center",
      gap: "0.5rem",
      background: "rgba(15,23,42,0.95)",
      backdropFilter: "blur(16px)",
      position: "sticky",
      top: 0,
      zIndex: 50,
    }}>
      {/* Logo — top-left corner, big */}
      <Link href="/" style={{ textDecoration: "none", display: "flex", alignItems: "center", flexShrink: 0, marginTop: 10 }}>
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img
          src="/arenza-logo-real.png"
          alt="ArenzaTV"
          style={{ height: 52, width: "auto", display: "block" }}
        />
      </Link>

      {/* Nav — tight to logo, single row */}
      <nav style={{
        display: "flex",
        gap: "0.05rem",
        flexWrap: "nowrap",
        alignItems: "center",
        minWidth: 0,
        marginLeft: "auto",
      }}>
        {NAV_ITEMS.map(({ href, label }) => {
          const isActive = href === "/" ? pathname === "/" : pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              style={{
                padding: "0.4rem 0.8rem",
                fontSize: "0.95rem",
                fontWeight: isActive ? 700 : 500,
                color: isActive ? "#ffffff" : "#94a3b8",
                textDecoration: "none",
                borderRadius: 8,
                background: isActive
                  ? "linear-gradient(135deg, rgba(59,130,246,0.25), rgba(139,92,246,0.25))"
                  : "transparent",
                border: isActive ? "1px solid rgba(139,92,246,0.4)" : "1px solid transparent",
                boxShadow: isActive ? "0 0 12px rgba(139,92,246,0.15)" : "none",
                transition: "all 0.2s ease",
                whiteSpace: "nowrap",
                flexShrink: 0,
              }}
            >
              {label}
            </Link>
          );
        })}
      </nav>
    </header>
  );
}
