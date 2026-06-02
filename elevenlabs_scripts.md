# AntiGravity Auto-Pilot Demo — ElevenLabs Narration Scripts

## ElevenLabs Studio Setup

| Setting | Value |
|---------|-------|
| **Project type** | Narration / Explainer |
| **Model** | Eleven Multilingual v2 |
| **Voice** | Adam (professional, authoritative) or your custom voice |
| **Stability** | 0.55 |
| **Similarity Boost** | 0.78 |
| **Style** | 0.12 |
| **Speaker Boost** | ✅ On |
| **Output format** | MP3 · 44100 Hz · 128 kbps |
| **Export filename** | `ag01.mp3` through `ag18.mp3` |
| **Destination** | `packages/dashboard/public/demo/antigravity/audio/` |

> **Tip:** Record each scene as a separate project so you can re-record individual scenes without re-recording the full set.

---

## Scene ag01 — Opening Overview (~70s)

```
What you're seeing is the AntiGravity prototype — the first working 
implementation of the CMXS Proof-of-Delivery system, running live in 
a browser with no external dependencies.

Every number, every auction, every cryptographic signature is generated 
in real time using the exact same logic deployed to our smart contracts 
on the Base blockchain.

Over the next twelve minutes, I'll walk you through the complete 
lifecycle of a single verified ad delivery — from the moment an 
advertiser places a bid, to the moment a CMXS token is minted and 
burned on-chain, permanently proving that a real viewer saw a real 
ad in real time.

This is the AntiGravity Advertiser Dashboard. This is where ad slots 
are auctioned, delivery is measured, and settlement happens 
automatically — with no human in the loop.
```

---

## Scene ag02 — DSP Bids Arriving (~65s)

```
A live broadcast slot just opened on the UEFA Champions League feed.

Watch the right side of the screen — five Demand-Side Platforms, or 
DSPs, are submitting competing bids for this thirty-second ad impression. 
Each has a different bidding strategy.

SportsPremium DSP bids aggressively on live sports content. BrandSafe 
DSP bids consistently regardless of channel. The Retargeting DSP has 
identified a returning viewer and is bidding at a premium.

All five bids arrive simultaneously, within eighty milliseconds of the 
slot opening. The floor CPM is fifteen dollars. Any bid below the floor 
is automatically rejected.

This is OpenRTB 2.6 format — the industry standard for programmatic 
advertising — operating at sub-100 millisecond speed.
```

---

## Scene ag03 — Second-Price Auction (~60s)

```
I'm running the auction now. Watch the bids sort by price in real time.

SportsPremium DSP won — they bid twenty-eight dollars and fifty cents 
CPM. But the key detail is the clear price: twenty-one dollars and 
forty-two cents.

This is a second-price auction. The winner pays the second-highest bid 
plus one cent — not their own maximum. This prevents overpayment and 
creates the most efficient price discovery mechanism in auction theory, 
proven by Nobel Prize-winning economist William Vickrey in 1961.

The entire process — five bids received, sorted, winner selected, clear 
price calculated — completed in sixty-seven milliseconds. 

That is the auction engine.
```

---

## Scene ag04 — HLS vs MoQ Delivery (~75s)

```
Now watch the delivery. On the left: HLS — the protocol Sling TV uses 
today. On the right: EchoAds, running over MoQ and QUIC.

Both sides received the ad signal at the same millisecond. Watch the 
left panel. It's buffering. The TCP connection tore down, a new segment 
has to load, and the viewer is watching a black screen.

This delay runs one and a half to three seconds on good broadband. 
On satellite — which is EchoStar's strategic expansion market through 
Hughes Network Systems — the same structural delay runs eight to twelve 
seconds, every single ad break.

That is not a software bug. That is a TCP protocol limitation that no 
amount of engineering can eliminate at the protocol level.

On the right, the track switched in two hundred and eighty-seven 
milliseconds. No black screen. No buffer. The five hundred millisecond 
SLA threshold — required by gaming regulators for in-play sports betting 
— is cleared with two hundred milliseconds to spare.
```

---

## Scene ag05 — Viewer Watches Ad (~55s)

```
The ad is now playing on the MoQ side. The viewer is watching a 
thirty-second creative from SportsPremium DSP.

At the twenty-second mark, an interactive engagement prompt appeared. 
This is the x402 commerce layer — the viewer can click through to a 
product page, with the interaction recorded on-chain in real time.

Completion rate, view duration, and engagement events are all being 
logged to the delivery record. This viewer completed the full thirty 
seconds.

That completion event triggers the most important step in the entire 
CMXS lifecycle — the Proof-of-Delivery signing process.
```

---

## Scene ag06 — PoD ECDSA Signing (~70s)

```
This is the moment that makes CMXS unique.

The viewer's browser just generated a cryptographic signature proving 
they watched this specific ad. The message contains four elements: 
the impression ID — a unique identifier for this ad slot; the node 
address — identifying which relay delivered the content; the CPM paid 
— twenty-one dollars and forty-two cents; and the timestamp.

This message was signed using the viewer's private key, with the ECDSA 
algorithm — the same cryptographic standard that secures every 
Ethereum transaction.

That signature is mathematically impossible to forge. The node cannot 
generate it. The platform cannot generate it. Nobody who doesn't control 
that viewer's wallet can generate it.

This is what transforms self-reported delivery metrics into 
cryptographic fact.
```

---

## Scene ag07 — Oracle Verification + CMXS Mint (~65s)

```
The signature just arrived at the DeliveryOracle smart contract.

Watch the verification steps. First: ECDSA signature verified — the 
signature matches the claimed viewer address. Second: replay protection 
checked — this impression ID has never been submitted before, so it's 
accepted. Third: latency confirmed — two hundred and eighty-seven 
milliseconds is under the five hundred millisecond SLA threshold.

All three checks passed.

The oracle called CMXS dot mintReward — and point-zero-zero-one CMXS 
just appeared in the node operator's wallet.

No invoice. No approval. No thirty-day payment cycle. Automatic, 
instant, and immutable on the Base blockchain.
```

---

## Scene ag08 — CMXS Burn + BME Equilibrium (~60s)

```
The final step: the CMXS burn.

The advertiser paid point-zero-zero-two-one USDC for this impression. 
The AdBurn contract received that payment, routed eighty-five percent 
to the node operator as revenue, and burned point-zero-two-one CMXS 
proportionally from the advertiser's balance.

That's the Burn-and-Mint Equilibrium in action. Every dollar of 
advertising demand burns CMXS, reducing supply. Every verified delivery 
mints CMXS, rewarding nodes.

The gauge you see — currently fifty-eight percent burn to forty-two 
percent mint — is what makes this system deflationary under growing 
demand.

That completes the full lifecycle. One verified ad delivery. Bid to 
burn. Under ten seconds.
```

---

## Scene ag09 — Transition to Slides (~40s)

```
Everything you just watched corresponds to a real function call in our 
deployed Solidity contracts, verifiable right now on Basescan.

Now let me walk through why this matters at the scale of a platform 
like EchoStar's Sling Freestream — and what the financial opportunity 
looks like across four specific, measurable problems.
```

---

## Scene ag10 — Problem: $84B Ad Fraud (~70s)

```
The core problem facing every digital advertising platform is the same: 
there is no independent proof that any ad was actually watched. 
Platforms report their own delivery numbers. Advertisers have no 
choice but to trust them.

The financial consequence is enormous. The Association of National 
Advertisers estimates global digital ad fraud at eighty-four billion 
dollars across the last three years, with connected TV carrying the 
highest fraud rate of any digital channel.

Morgan Stanley estimates thirty percent of all CTV inventory sold is 
never seen by a real viewer. DoubleVerify documented a one hundred and 
forty percent increase in CTV ad fraud in 2025.

For EchoStar specifically: Sling Freestream's programmatic inventory 
runs through open exchanges where verification is optional and rarely 
enforced. For every dollar an advertiser pays, an estimated twenty-five 
to thirty-five cents corresponds to an impression that was never watched.

When major advertisers confirm this — and they are confirming it right 
now — platforms without verifiable delivery face systematic CPM 
deflation. Procter and Gamble, Unilever, and General Motors all publicly 
announced in 2025 they are concentrating CTV budgets on verified-only 
inventory.
```

---

## Scene ag11 — Solution: Verified CPM Premium (~55s)

```
The financial upside of solving this problem is direct and large.

PubMatic and Magnite's 2025 CTV Marketplace reports both confirm: 
verified inventory commands forty-five to sixty-five dollars CPM. 
Unverified inventory — which is what Sling Freestream sells today — 
commands eighteen to thirty dollars.

Same viewers. Same content. Same ad break. The difference is 
cryptographic proof.

At one billion impressions per month, the difference between a 
twenty-five dollar and a fifty-five dollar average CPM is thirty million 
dollars per month — three hundred and sixty million dollars per year — 
from inventory EchoStar already owns and sells today. No new 
subscribers. No new content rights. Just proof.

The IAB Tech Lab explicitly called for cryptographic delivery credentials 
in October 2025. CMXS generates them automatically, for every impression, 
at zero additional cost to the platform.
```

---

## Scene ag12 — Problem: Sports Betting Locked Out (~60s)

```
The second major opportunity is a forty-five billion dollar market that 
EchoStar currently generates zero revenue from.

New Jersey and Pennsylvania gaming commissions — governing two of the 
largest legal sports betting markets in the United States — require 
real-time odds synchronization within five hundred milliseconds of 
live action. This prevents arbitrage between the broadcast signal and 
the betting interface.

Sling TV's HLS stream runs five to thirty seconds behind live. This is 
a structural TCP limitation. No software optimization can fix it.

EchoStar is categorically disqualified from the in-play sports betting 
infrastructure market — not by choice, but by architecture.

EchoStar's current share of this forty-five billion dollar market is 
zero.
```

---

## Scene ag13 — Solution: 312ms Clears the Threshold (~55s)

```
EchoAds changes that equation entirely.

Our MoQ-over-QUIC delivery records a P95 latency of three hundred and 
twelve milliseconds — clearing the five hundred millisecond regulatory 
threshold with one hundred and eighty-eight milliseconds to spare. 
Validated across one hundred consecutive delivery trials on AWS 
infrastructure.

The moment EchoAds deploys at scale, EchoStar becomes technically 
qualified to partner with every major US sports betting operator as a 
verified low-latency delivery infrastructure provider. DraftKings, 
FanDuel, BetMGM — all of them need this infrastructure.

EchoStar's current share of this market is zero. The cost to access 
it is a software layer on infrastructure that already exists.
```

---

## Scene ag14 — BME Token Economics (~65s)

```
The CMXS token is a settlement and incentive layer that creates a 
self-regulating economy through the Burn-and-Mint Equilibrium.

On the burn side: every dollar of advertising demand burns CMXS 
proportionally. More ad spend means more tokens destroyed, reducing 
circulating supply.

On the mint side: every verified delivery mints exactly point-zero-zero-one 
CMXS to the node that delivered it.

The equilibrium is automatic. When burn exceeds mint, supply falls and 
price rises, attracting more nodes. When mint exceeds burn, supply rises 
and marginal nodes exit. No human decides. No vote required. The 
protocol self-corrects.

A daily mint cap of two point eight eight million CMXS is hardcoded 
into the token contract. Even a complete oracle compromise cannot 
produce more than point three percent of total supply in twenty-four 
hours. This is the safety valve that institutional investors require.

This model was pioneered by Helium's HNT token and validated by 
peer-reviewed research in 2025 as the DePIN industry standard.
```

---

## Scene ag15 — PoD vs PoW vs PoS (~60s)

```
Every blockchain needs a consensus mechanism — a way to decide what 
real work deserves reward.

Bitcoin uses Proof-of-Work: computers solve cryptographic puzzles that 
have nothing to do with delivering content. The puzzles consume 
enormous energy and produce no useful output.

Ethereum uses Proof-of-Stake: the richest token holders earn more 
rewards, regardless of infrastructure quality. It rewards capital, 
not work.

CMXS uses Proof-of-Delivery: nodes earn tokens for doing exactly what 
the network needs — delivering verified content to real devices, on 
time, under five hundred milliseconds.

Critically, PoD uses dual-signal verification. Both an independent 
cryptographic receipt from the viewer's wallet, and an independent 
on-chain payment via x402. A node cannot fake a viewer's signature. 
Two independent cryptographic systems must both be defeated 
simultaneously — which is computationally infeasible.
```

---

## Scene ag16 — 5,800 Towers Earn $30M/yr (~60s)

```
EchoStar operates over five thousand eight hundred owned broadcast and 
ground station sites. These sites carry the video that contains the ads 
that generate the revenue — and today they earn nothing from advertising. 
They receive a flat infrastructure fee regardless of ad volume.

CMXS builds revenue participation directly into the protocol. Every 
verified ad delivery triggers a point-zero-zero-one CMXS reward to 
the node that relayed it.

At fourteen hundred and forty deliveries per day, each EchoStar site 
earns approximately four hundred and thirty-two CMXS per month — 
roughly four hundred and thirty-two dollars at initial FDV.

Scaled to five thousand eight hundred sites: approximately two point 
five million CMXS flows to infrastructure operators every month, 
automatically, triggered by cryptographic proof, with no human process 
involved. Thirty million dollars per year in new revenue for 
infrastructure that already exists and is already operating.

Helium Network proved this model at scale — nearly one million 
independently operated hotspots at peak, with zero company-owned nodes. 
EchoStar starts with five thousand eight hundred sites already in the 
ground.
```

---

## Scene ag17 — Four-Demand Flywheel (~60s)

```
What makes CMXS structurally different from single-use DePIN tokens 
is four independent demand engines, any one of which is sufficient for 
sustainable utility.

First: PoD node rewards — point-zero-zero-one CMXS per verified 
delivery, aligning token value directly with network performance.

Second: x402 burns — every dollar of ad spend burns CMXS, tying 
token demand directly to platform revenue growth.

Third: SLA staking — nodes stake CMXS to access premium routing slots, 
permanently removing circulating supply.

Fourth: veToken governance — long-term holders lock CMXS for one to 
four years for governance rights and protocol fee income paid in USDC.

These four engines create a compounding flywheel: more service demand 
burns tokens, higher token value attracts more nodes, better coverage 
attracts more service buyers, which burns more tokens. Each cycle 
reinforces the next.
```

---

## Scene ag18 — Summary + Call to Action (~70s)

```
Here is the one-sentence summary.

EchoAds is not asking anyone to make a technology bet on a promise. 
The infrastructure is live. Both smart contracts are deployed on 
Base Sepolia and verifiable by anyone right now.

Four financial problems. One protocol layer.

First: three hundred and sixty million dollars per year in recoverable 
revenue from impressions EchoStar already sells, once advertisers can 
independently verify delivery.

Second: a forty-five billion dollar sports betting market that EchoStar 
is currently a hundred percent absent from, due to a protocol limitation 
this system eliminates.

Third: thirty million dollars per year in new CMXS revenue flowing 
automatically to five thousand eight hundred infrastructure sites that 
currently earn nothing from advertising.

Fourth: a token economy with four independent demand engines, hardcoded 
daily mint caps, and Burn-and-Mint Equilibrium stability properties that 
align every participant's incentives with network growth.

The question is not whether this technology works.

The question is whether EchoStar captures this revenue — or watches 
a competitor build the same system on someone else's towers.
```

---

## Export Checklist

| File | Scene | Est. Duration | Status |
|------|-------|--------------|--------|
| `ag01.mp3` | Opening Overview | ~70s | ⬜ |
| `ag02.mp3` | DSP Bids Arriving | ~65s | ⬜ |
| `ag03.mp3` | Second-Price Auction | ~60s | ⬜ |
| `ag04.mp3` | HLS vs MoQ Delivery | ~75s | ⬜ |
| `ag05.mp3` | Viewer Watches Ad | ~55s | ⬜ |
| `ag06.mp3` | PoD ECDSA Signing | ~70s | ⬜ |
| `ag07.mp3` | Oracle Verify + Mint | ~65s | ⬜ |
| `ag08.mp3` | CMXS Burn + BME | ~60s | ⬜ |
| `ag09.mp3` | Transition to Slides | ~40s | ⬜ |
| `ag10.mp3` | Problem: $84B Fraud | ~70s | ⬜ |
| `ag11.mp3` | Solution: CPM Premium | ~55s | ⬜ |
| `ag12.mp3` | Problem: Sports Locked | ~60s | ⬜ |
| `ag13.mp3` | Solution: 312ms | ~55s | ⬜ |
| `ag14.mp3` | BME Token Economics | ~65s | ⬜ |
| `ag15.mp3` | PoD vs PoW vs PoS | ~60s | ⬜ |
| `ag16.mp3` | 5,800 Towers $30M/yr | ~60s | ⬜ |
| `ag17.mp3` | Four-Demand Flywheel | ~60s | ⬜ |
| `ag18.mp3` | Summary + CTA | ~70s | ⬜ |
| **Total** | | **~18 min** | |

Place all files in: `packages/dashboard/public/demo/antigravity/audio/`
