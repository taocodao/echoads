import { TokenLifecycle } from "../components/TokenLifecycle";
import { NetworkStatus } from "../components/NetworkStatus";
import { AuctionFeed } from "../components/AuctionFeed";
import { PoDFeed } from "../components/PoDFeed";
import { BurnMintFeed } from "../components/BurnMintFeed";

export default function TokenPage() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem" }}>
      <div>
        <div style={{
          fontSize: 11,
          fontWeight: 700,
          color: "#8B5CF6",
          textTransform: "uppercase",
          letterSpacing: "2px",
          marginBottom: 4,
        }}>
          CMXS Token
        </div>
        <h1 style={{
          fontSize: 26,
          fontWeight: 900,
          color: "#f1f5f9",
          margin: 0,
          letterSpacing: "-0.03em",
        }}>
          Token Dashboard
        </h1>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "2rem" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: "2rem" }}>
          <TokenLifecycle />
          <BurnMintFeed />
          <NetworkStatus />
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: "2rem" }}>
          <AuctionFeed />
          <PoDFeed />
        </div>
      </div>
    </div>
  );
}
