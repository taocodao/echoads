import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { NavBar } from "./components/NavBar";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "ArenzaTV — Sports FAST Dashboard",
  description: "Real-time ad delivery, PoD verification, DePIN node rewards, and CMXS token lifecycle",
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
