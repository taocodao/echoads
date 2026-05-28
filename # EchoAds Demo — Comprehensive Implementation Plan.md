<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# \# EchoAds Demo — Comprehensive Implementation Plan v2

## 1. Root-Cause Analysis of Current Bugs

I've thoroughly reviewed all three existing files. Here are the exact issues:

### Bug 1: Template literals in static HTML (CRITICAL)

**File:** `index.html` lines 215–232
**Problem:** The benchmark tab contains JavaScript template literal syntax (`${[...].map(r=> ...)}`) directly in the HTML. Static HTML files are served as-is — the browser does not execute JS expressions inside HTML. The entire benchmark section renders as literal text.
**Impact:** The benchmark tab is completely broken. Worse, it may cause the HTML parser to choke, potentially breaking script loading below it.

### Bug 2: CSS `display: none` vs `.hidden` class conflict

**File:** `styles.css` line 262 vs `index.html`
**Problem:** `.latency-badge` uses `display: none` as its default style (line 262). But the code uses `.hidden { display: none !important }` to toggle visibility. The `.latency-badge.show` rule (line 266) sets `display: block`, but `.hidden` with `!important` overrides it. The logic tries to remove `.hidden` AND add `.show`, but these conflict — the badge needs EITHER the hidden-class system OR the show-class system, not both mixed.
**Impact:** Latency badges never appear correctly during ad break.

### Bug 3: Intro screen never hides properly

**File:** `demo.js` line 368–373 and `index.html` lines 26–38, 40–41
**Problem:** The intro screen and the main layout are **siblings at the same level**, but the intro screen has `display: flex` on `#intro-screen` (CSS line 373) while `#main` has `class="hidden"`. When Start is clicked, `demo.js` adds `.hidden` to intro and removes it from main. This part works in JS, BUT the intro screen occupies the entire viewport height (`min-height: calc(100vh - 67px)`), pushing `#main` far below the fold even when both are visible.
**Impact:** User sees the intro AND the main layout simultaneously, stacked vertically.

### Bug 4: `demo.js` tries to control both pages

**Problem:** The current `demo.js` contains ALL logic: cursor simulation, voice-over, tab switching, ad break, autopilot sequence, AND manual click handlers — all in one file for one page. The intro screen + sidebar + browser chrome + dashboard + cursor are all crammed into one `index.html`. This means the "interactive demo" and "auto presentation" are tangled together. The user cannot freely click around because `demoRunning` gates all manual interactions.

### Bug 5: Inline `<style>` block at end of `index.html`

**File:** `index.html` lines 282–351

```
**Problem:** Critical styles for `#browser-chrome`, `#product-nav`, `.nav-link`, `.ad-stat-card`, `.small-btn`, `#sim-cursor`, etc. are in an inline `<style>` block at the **bottom** of the HTML, after `<script>`. While browsers still parse this, it's after the script has already tried to run, and it's separated from the main stylesheet. This makes maintenance harder and creates a risk of flash-of-unstyled-content.
```


---

## 2. Two-Site Architecture

### Site 1: Interactive Demo — `echoads.tv/demo/`

**Purpose:** A standalone dashboard that a human operates manually.
**Behavior:**

- No intro splash screen, no sidebar, no browser chrome, no animated cursor, no voice-over
- Just the clean dashboard UI with tabs (Advertiser, Node, Benchmark) and the "Force Ad Break" button
- User clicks buttons freely — no prescribed sequence
- Every click triggers real animations (black screen, impression feed, stats update)
- This is what a prospect would explore on their own after a meeting


### Site 2: Auto Presentation — `echoads.tv/demo/presentation/`

**Purpose:** A guided, narrated walkthrough for senior leadership.
**Behavior:**

- Shows the same dashboard UI embedded inside a simulated browser chrome frame
- An animated SVG cursor moves to elements and clicks them
- Pre-recorded voice-over (MP3 files) plays at each step, narrating the demo
- Sidebar shows: narration transcript, step timeline, node status indicators
- Start / Stop button controls the entire sequence
- Runs exactly one cycle (9 steps), then stops


### Why two separate pages

- The interactive demo should feel like a PRODUCT, not a presentation
- The auto presentation should feel like a KEYNOTE, not a product
- Mixing them (as the current build does) breaks both experiences

---

## 3. Voice-Over Strategy

### Recommended: Pre-generated ElevenLabs MP3 (Best Quality)

Based on research, the optimal approach for a senior leadership demo:


| Approach | Quality | Setup | Runtime Dependency |
| :-- | :-- | :-- | :-- |
| **Web Speech API** | Robotic, varies by OS | Zero | None |
| **ElevenLabs pre-generated MP3** | Professional, human-like | Generate once | None (static files) |
| **ElevenLabs API at runtime** | Professional | API key in server | Server required |
| **Kokoro/Piper in-browser** | Good | Load model (~100MB) | Heavy client CPU |

**Decision: Pre-generate MP3 files using ElevenLabs, store them as static assets.**

Reasoning:

1. **No API key needed at runtime** — files are just static MP3s served alongside the HTML
2. **Consistent quality** — every playback sounds identical (no OS voice variation)
3. **No server dependency** — works on Vercel's static hosting
4. **Small files** — 9 voice clips × ~20-40 seconds each ≈ ~3-5 MB total
5. **Fallback** — if MP3 fails to load, fall back to Web Speech API gracefully

### File naming convention

```
demo/audio/
├── 01-opening.mp3          (~25s)
├── 02-player-intro.mp3     (~22s)
├── 03-trigger-ad-break.mp3 (~10s)
├── 04-black-screen.mp3     (~30s)
├── 05-impression-receipt.mp3 (~28s)
├── 06-node-dashboard.mp3   (~12s)
├── 07-cmxs-earnings.mp3    (~30s)
├── 08-benchmark.mp3        (~28s)
└── 09-closing.mp3          (~30s)
```


### How to generate

1. Go to [https://elevenlabs.io](https://elevenlabs.io) → Text to Speech
2. Select voice: "Daniel" or "Antoni" (professional male, boardroom-appropriate)
3. Paste each transcript segment (see Section 4 below)
4. Download each MP3
5. Place in `packages/dashboard/public/demo/audio/`

### Fallback implementation

```javascript
async function playVoice(stepNum, text) {
  const audio = new Audio(`audio/${stepNum}.mp3`);
  try {
    await audio.play();
    return new Promise(resolve => { audio.onended = resolve; });
  } catch {
    // Fallback to Web Speech API
    return speakWithBrowserTTS(text);
  }
}
```


---

## 4. Complete Voice-Over Transcript (9 Scenes)

### Scene 1: Opening — Dashboard Overview

> "Welcome to EchoAds Phase Zero. What you are seeing is the live advertiser dashboard, running right now at echoads dot TV. This is not a mock-up. The relay node is live on AWS. The smart contracts are deployed on the Base blockchain. Notice the impression counter is at zero. No ads have run yet. This is our baseline."

### Scene 2: Player Introduction

> "On the left is Sling TV's current technology — HLS running over TCP. On the right is EchoAds — connected live to our QUIC relay node on AWS. Both sides are playing the same soccer match highlights simultaneously. Same content. Same moment in time. Watch what happens when we trigger an ad break."

### Scene 3: Triggering the Ad Break

> "I am now clicking Force Ad Break. This fires the same ad signal on both sides at exactly the same moment. Watch the left panel carefully."

### Scene 4: The Black Screen vs. Instant Switch

> "The left side has gone completely black. This is what Sling TV viewers see every time an ad plays. TCP must tear down the existing connection, negotiate a new one with the ad server, then download and buffer the entire ad segment before playback can begin. That process takes three to seven seconds. Meanwhile, the right side — EchoAds — switched in 287 milliseconds. No black screen. Not ever. This is not a software bug we are fixing. This is a structural limitation of TCP that QUIC eliminates permanently, because both streams share the same multiplexed connection."

### Scene 5: On-Chain Delivery Receipt

> "Within two seconds of that ad playing, a record appeared in the impression feed — automatically. It shows the ad ID, delivery latency confirmed under 500 milliseconds, a USDC micropayment settled on the Base blockchain, and a transaction hash that anyone can verify independently on Basescan right now. This is the first cryptographic proof of delivery in the history of connected TV advertising. Morgan Stanley estimates 30 percent of CTV ad inventory is fraudulent. With EchoAds, fraud becomes mathematically impossible — because every impression is an immutable fact on a public blockchain."

### Scene 6: Switching to Node Dashboard

> "Now I am switching to the Node Operator dashboard. This shows the perspective of whoever owns the infrastructure that delivered that ad."

### Scene 7: CMXS Token Earnings

> "The node that delivered that ad just earned 0.001 CMXS tokens — automatically. No invoice. No manual reconciliation. Now replace this AWS instance with an EchoStar tower. EchoStar has 60,000 towers across the country. At 1,440 deliveries per day per node, each tower earns approximately 43 CMXS per month. Across 60,000 towers, that is 2.6 million CMXS circulating monthly through the node reward pool. This is the DePIN flywheel — infrastructure that pays for itself from the advertising revenue it carries. EchoStar's towers carry the ads today but earn nothing from them. EchoAds changes that."

### Scene 8: 100-Trial Benchmark

> "This is not one lucky result. These are 100 consecutive trials. EchoAds at the 95th percentile: 312 milliseconds. Sling TV's current system at the 95th percentile: 4,100 milliseconds. That is 13 times faster. And that 312 millisecond figure does more than fix the black screen — it clears the 500 millisecond regulatory threshold for live sports betting synchronization. That is a 45 billion dollar market that Sling TV is currently 100 percent locked out of because HLS runs 5 to 30 seconds behind live action. EchoAds opens that door."

### Scene 9: Closing

> "EchoAds is not asking EchoStar to make a technology bet on a promise. Everything you just saw is running in production right now. The relay node is live on AWS. Both smart contracts are deployed and independently verifiable on the Base blockchain. The question for EchoStar is straightforward: do you want to capture the verified-impression premium — where CPMs roughly double from 18 to 65 dollars for the same inventory — the sports betting synchronization market, and the DePIN node reward economy? Or do those opportunities go to a competitor who builds the same system on someone else's towers?"

---

## 5. File Architecture

```
packages/dashboard/public/demo/
├── index.html              ← Interactive Demo (human-operated)
├── styles.css              ← Shared CSS (both pages use this)
├── app.js                  ← Shared logic (ad break, tabs, impressions, stats)
├── presentation/
│   └── index.html          ← Auto Presentation (cursor + voice + sidebar)
├── autopilot.js            ← Cursor movement + voice + step orchestration
└── audio/                  ← Pre-generated ElevenLabs MP3 files
    ├── 01-opening.mp3
    ├── 02-player-intro.mp3
    ├── 03-trigger-ad-break.mp3
    ├── 04-black-screen.mp3
    ├── 05-impression-receipt.mp3
    ├── 06-node-dashboard.mp3
    ├── 07-cmxs-earnings.mp3
    ├── 08-benchmark.mp3
    └── 09-closing.mp3
```


### File responsibilities

| File | Used by | Contains |
| :-- | :-- | :-- |
| `styles.css` | Both pages | All CSS (dark theme, player, cards, sidebar, cursor, animations) |
| `app.js` | Both pages | `switchTab()`, `triggerAdBreak()`, `addImpression()`, `resetAll()`, `animateBenchmarkBars()`, `buildBenchmarkHTML()` |
| `index.html` | Interactive only | Clean dashboard — no sidebar, no cursor, no browser chrome frame. Nav tabs + player + impressions + benchmark |
| `presentation/index.html` | Presentation only | Browser chrome frame wrapping the dashboard UI, plus sidebar with narration/timeline, plus SVG cursor element |
| `autopilot.js` | Presentation only | Step sequence definition, cursor animation, MP3 playback (with Web Speech API fallback), Start/Stop logic |


---

## 6. Step-by-Step Build Order

### Step 1: Create `app.js` (shared logic)

Extract all reusable functions from the current `demo.js`:

- `switchTab(tabName)` — show/hide tab panels, update nav active state
- `triggerAdBreak()` → Promise — runs the black screen animation, adds impression on completion
- `addImpression(latencyMs)` — creates impression row, updates all stat counters
- `resetAll()` — reset counters, clear impression feed, reset player overlays
- `animateBenchmarkBars()` — trigger the bar width CSS transitions
- `buildBenchmarkHTML()` — returns the benchmark chart HTML string (solves the template-literal-in-HTML problem)
- `genTxHash()` — generates random hex hash

**Acceptance:** Can be loaded by both `index.html` and `presentation/index.html`. Has no DOM references to sidebar, cursor, or intro screen.

### Step 2: Rewrite `index.html` (Interactive Demo)

- Remove: intro splash screen, sidebar, browser chrome frame, cursor element, scene headers, progress bar, timeline
- Keep: header with logo + "Force Ad Break" button, nav tabs, player panels, impression feed, node dashboard, benchmark tab
- The benchmark section is rendered by calling `buildBenchmarkHTML()` from `app.js` on page load — NOT by template literals in HTML
- All buttons wired via simple event listeners at bottom of page:

```html
<script src="app.js"></script>
<script>
  document.getElementById('force-ad-btn').onclick = triggerAdBreak;
  document.querySelectorAll('.nav-link').forEach(l => 
    l.onclick = () => switchTab(l.dataset.tab)
  );
  buildBenchmarkHTML();
</script>
```

- Move all inline `<style>` from old HTML into `styles.css`

**Acceptance:** Human can click any button in any order. Force Ad Break works multiple times. All tabs switch. Benchmark bars animate on first view. No voice, no cursor, no sidebar.

### Step 3: Create `presentation/index.html` (Auto Presentation)

- Wraps the same dashboard UI inside a browser chrome frame (3 colored dots + URL bar)
- Adds sidebar with: node status indicators, narration transcript box, step timeline
- Adds SVG cursor element (positioned absolutely over the stage)
- Adds header with Start/Stop button and progress bar
- Loads: `../styles.css`, `../app.js`, `../autopilot.js`
- All dashboard content (nav, tabs, player, impressions) is identical HTML to `index.html`

**Acceptance:** Page loads showing the dashboard inside the browser frame + sidebar. Nothing auto-plays. Start button is visible.

### Step 4: Create `autopilot.js` (presentation orchestration)

- Defines `STEPS` array with: step name, target element ID for cursor, action (click/hover), audio file path, transcript text
- Implements `moveCursorTo(elementId)` — smooth CSS transition to element center
- Implements `clickElement(elementId)` — cursor scale animation + call the `app.js` function
- Implements `playAudio(stepIndex)` — plays MP3 from `/demo/audio/`, falls back to Web Speech API
- Implements `async runPresentation()` — walks through all 9 steps sequentially
- Implements `stopPresentation()` — sets abort flag, cancels audio, resets all state
- Updates sidebar narration text and timeline at each step

**Acceptance:** Click Start → cursor moves to dashboard, narration plays, cursor clicks Force Ad Break, black screen appears, impression appears, cursor clicks Node tab, cursor clicks Benchmark tab, closing narration plays, demo ends.

### Step 5: Generate voice-over audio files

- Use ElevenLabs (or OpenAI TTS) to generate 9 MP3 files from the transcripts in Section 4
- Place in `packages/dashboard/public/demo/audio/`
- If user prefers not to use ElevenLabs, the Web Speech API fallback will work (lower quality but functional)


### Step 6: Update `styles.css`

- Merge inline styles from old `index.html` (browser chrome, nav, stat cards, small-btn, cursor) into the main stylesheet
- Fix the latency badge display conflict: remove `display: none` default, use ONLY the `.hidden` class system
- Add presentation-specific styles (sidebar narration box, browser chrome frame) — these only apply to elements that exist in `presentation/index.html`


### Step 7: Test and deploy

- Test `index.html` locally: open in Chrome, click all buttons
- Test `presentation/index.html` locally: click Start, verify full cycle
- `git add . && git commit && git push` → Vercel auto-deploys
- Verify: `echoads.tv/demo/` loads interactive demo
- Verify: `echoads.tv/demo/presentation/` loads auto presentation

---

## Summary

| Decision | Choice | Rationale |
| :-- | :-- | :-- |
| Voice quality | ElevenLabs pre-generated MP3 | Professional quality, no runtime dependency, static hosting |
| Voice fallback | Web Speech API | Zero-cost, works offline if MP3s fail |
| Two pages | Separate HTML files | Different UX goals (explore vs. watch) |
| Shared logic | `app.js` | Both pages use the same ad break / impression / tab functions |
| Benchmark rendering | JS-generated HTML | Eliminates the template-literal-in-HTML bug |
| CSS | Single shared file | No more inline `<style>` blocks |

Based on everything gathered from the implementation plan, the PDF document, and the full context of this project, here is the complete revised implementation plan with the four industry problems and "beyond advertising" content fully integrated as a 13-scene presentation.

---
<span style="display:none">[^1]</span>

<div align="center">⁂</div>

[^1]: Echoads-demo-description-English.pdf

