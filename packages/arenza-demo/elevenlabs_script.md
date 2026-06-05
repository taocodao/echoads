# Arenza Demo — ElevenLabs Narration Scripts

## ElevenLabs Studio Setup

| Setting | Value |
|---------|-------|
| **Project type** | Narration / Explainer |
| **Model** | Eleven Multilingual v2 |
| **Voice** | Adam (professional, authoritative) |
| **Stability** | 0.55 |
| **Similarity Boost** | 0.78 |
| **Style** | 0.12 |
| **Speaker Boost** | ✅ On |
| **Output format** | MP3 · 44100 Hz · 128 kbps |
| **Export filenames** | `ar01.mp3` through `ar08.mp3` |
| **Destination** | `packages/arenza-demo/public/audio/` |

> **Tip:** Record each slide as a separate project so you can re-record individual slides without redoing the full set.

---

## Slide ar01 — Hero Overview (~22s)

```
Welcome to Arenza.

We deliver cryptographically verified ad impressions on live sports
streams — moving local TV stations from a ten-to-twenty-five-dollar
unverified CPM tier, to a forty-five-to-sixty-five-dollar verified tier.

Zero upfront cost. Eighty-five percent revenue share.
On-chain proof, every thirty-five seconds.
```

---

## Slide ar02 — The Problem (~26s)

```
The problem is clear.

Ad fraud costs eighty-four billion dollars annually. Nielsen abandoned
one hundred and thirty-seven US markets in twenty-twenty-six. Standard
FAST channels earn ten-to-twenty-five dollars CPM — because advertisers
cannot verify delivery. Roku taxes stations thirty percent.

Arenza eliminates all three pain points simultaneously.
```

---

## Slide ar03 — The Solution (~32s)

```
Our solution is five integrated layers.

First: MoQ video delivery over Caton's network — five thousand eight
hundred EchoStar edge nodes, under three hundred milliseconds
glass-to-glass latency.

Second: OpenRTB two-point-six real-time auction, closing in under
six hundred milliseconds.

Third: blockchain Proof-of-Delivery on Base L2.

Fourth: server-guided interactive commerce overlay.

Fifth: the CMXS token burn-mint equilibrium.

No competitor — Fubo, Magnite, DoubleVerify, StreamLayer — provides
all five layers under a single contract.
```

---

## Slide ar04 — Live MoQ Pipeline Demo (~36s)

```
Watch the live thirty-five-second cycle.

A SCTE-thirty-five cue triggers an OpenRTB auction. Five DSPs bid
simultaneously. The Trade Desk wins at forty-seven-fifty CPM. The
creative is server-stitched into the stream — seamless, no ad blocker
exposure.

When the ad completes, the viewer's device signs an ECDSA receipt.
DeliveryOracle dot sol mints an immutable record on Base L2.

The entire cycle: thirty-five seconds.

Click Run Demo Cycle to see it live.
```

---

## Slide ar05 — Unit Economics (~28s)

```
Unit economics for a single channel with five hundred thousand
monthly viewers.

Four million impressions at forty-five dollars verified CPM generates
one hundred and eighty thousand dollars in gross monthly revenue.

The station partner keeps eighty-five percent — that's one hundred
and fifty-three thousand dollars per month, or one-point-eight million
annually — from a channel requiring zero additional staff and zero
capital expenditure.
```

---

## Slide ar06 — Tokenomics / BME (~32s)

```
The CMXS token is not speculative.

Every dollar of advertiser spend triggers AdBurn dot sol to
non-discretionarily burn tokens. Supply deflates. Price appreciates.
Higher token value attracts more EchoStar node operators. More nodes
attract more broadcasters, increasing ad spend — restarting the cycle.

Every burn transaction is publicly verifiable on Basescan.
This is structural demand from ongoing corporate advertising spend
— not speculation.

Helium Network proved this model at a five-hundred-million-dollar
fully-diluted valuation on just twenty-four million in annual revenue.
```

---

## Slide ar07 — Go-To-Market (~30s)

```
Our go-to-market targets local TV stations — the highest-leverage
first market.

Three structural forces converge in twenty-twenty-six: Nielsen's exit
from one hundred and thirty-seven markets creates a credibility vacuum
that blockchain-verified receipts fill directly. Sports FAST channels
more than doubled year-over-year in twenty-twenty-five. And local
programmatic CPM averages two-to-five dollars — compared to
thirty-five-to-forty-five on Arenza's verified inventory.

A ninety-day cold start needs just three to five EchoStar nodes
in the pilot DMA, a Roku FAST channel, and two local direct advertisers.
```

---

## Slide ar08 — The Ask / Close (~36s)

```
The ask is simple: a ninety-day pilot.

Zero technology cost to the station. You bring your content feed and
your existing local ad relationships. We bring the full stack —
delivery, auction, verification, and settlement.

At ninety days, you'll have a verified CPM report, an auditable
on-chain impression record, and a revenue check.

If we don't beat your current FAST CPM, we part ways.
If we do — and we're confident we will — we extend to a twelve-month
Channel-as-a-Service agreement.

Year three: fifty station partners, nine-point-seven million dollars
in protocol revenue, and a Basescan record of every single verified
impression that got us there.

The window is open now. Let's build.
```

---

## Export Checklist

| File | Slide | Est. Duration | Status |
|------|-------|--------------|--------|
| `ar01.mp3` | Hero Overview | ~22s | ⬜ |
| `ar02.mp3` | The Problem | ~26s | ⬜ |
| `ar03.mp3` | The Solution | ~32s | ⬜ |
| `ar04.mp3` | Live MoQ Pipeline | ~36s | ⬜ |
| `ar05.mp3` | Unit Economics | ~28s | ⬜ |
| `ar06.mp3` | Tokenomics / BME | ~32s | ⬜ |
| `ar07.mp3` | Go-To-Market | ~30s | ⬜ |
| `ar08.mp3` | The Ask / Close | ~36s | ⬜ |
| **Total** | | **~4 min** | |

Place all files in: `packages/arenza-demo/public/audio/`
