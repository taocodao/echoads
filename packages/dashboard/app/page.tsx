import { TokenLifecycle } from "./components/TokenLifecycle";
import { NetworkStatus } from "./components/NetworkStatus";
import { AuctionFeed } from "./components/AuctionFeed";
import { PoDFeed } from "./components/PoDFeed";
import { BurnMintFeed } from "./components/BurnMintFeed";

export default function DashboardHome() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '2rem' }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
        <TokenLifecycle />
        <BurnMintFeed />
        <NetworkStatus />
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
        <AuctionFeed />
        <PoDFeed />
      </div>
    </div>
  );
}
