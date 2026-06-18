"""
Generate ElevenLabs audio + cues.json for Arenza slideshows.

Usage:
  python scripts/generate_cues.py

Requires:
  pip install requests
  set ELEVENLABS_API_KEY=your_key_here

Outputs (into public/audio/):
  arenza-sports.mp3        + arenza-sports-cues.json
  arenza-loyalty-a.mp3     + arenza-loyalty-a-cues.json  (slides 1-8)
  arenza-loyalty-b.mp3     + arenza-loyalty-b-cues.json  (slides 9-15, raw times)
  arenza-loyalty.mp3       = concat of a + b
  arenza-loyalty-cues.json = merged, b times offset by duration of a
"""

import base64, json, os, sys
import requests

# Force UTF-8 output on Windows
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

API_KEY  = os.environ.get("ELEVENLABS_API_KEY", "")
VOICE_ID = os.environ.get("ELEVENLABS_VOICE_ID", "JBFqnCBsd6RMkjVDRZzb")  # George - Warm, Captivating Storyteller
MODEL_ID = "eleven_multilingual_v2"
OUT_DIR  = os.path.join(os.path.dirname(__file__), "..", "public", "audio")

# ── Slide texts ────────────────────────────────────────────────────────────────
SPORTS_V1_SLIDES = [
    "ArenzaTV: The Interactive Canvas. Merging Sports FAST, AI-Powered Ad Monetization, and Gamification.",
    "Arenza monetizes a 100 billion dollar behavioral convergence across five macro markets: FAST Advertising, Sports Fan Engagement, Second Screen Behavior, Live Commerce, and Zero-Party Data.",
    "Passive viewership has reached its limits. We face structural ad fatigue, a data blindspot from App Tracking Transparency, and a severe retention cliff for traditional companion apps.",
    "Our solution is a Dual-Screen Stage plus Stage Architecture. We transform passive, commodity video inventory into active participation with verifiable attribution.",
    "The Play-to-Earn Activation Curve drives engagement rates nearly triple that of standard video. A broadcast cue triggers a prediction, the user engages, earns points, and redeems them for real-world rewards.",
    "Crucially, this operates within a 50-State Legal Safe Harbor. By using a free-to-play model with non-cash rewards and skill-based scoring, Arenza requires zero gaming licenses.",
    "The Secret Engine is our AI Ad Monetization Stack. It combines low-latency video, an interactive prediction engine, on-device data enrichment, and seamless point-of-sale integration.",
    "Layer one and two of our stack inject contextual microgames directly into the broadcast stream, guided entirely by server-side logic without disrupting the viewing experience.",
    "AI Module 2 is the Zero-Party Profile Engine. By transforming voluntary game inputs into an on-device audience segmentation model, we bypass the ATT ceiling and capture 100% explicit data.",
    "AI Module 3 introduces Predictive Retention and Temporal Hooks. We solve the companion app drop-off by creating temporal habits orchestrated by an AI churn prediction engine, driving pre-game, in-game, and post-game engagement.",
    "This creates a seamless bridge to local commerce. Viewers convert their gameplay success directly into single-use, HMAC-signed reward tokens for local SMBs, closing the loop from screen to store.",
    "The Monetization Output is a massive Revenue Multiplier. The combined Arenza model generates up to 62% higher revenue per channel, elevating pure targeting CPMs with commerce and activation fees.",
    "Looking at our Competitive Positioning Matrix, Arenza is the only platform successfully combining Sports FAST video, interactive games, local SMB targeting, and offline point-of-sale redemption.",
    "Our go-to-market strategy focuses on rapid deployment and proven unit economics, empowering broadcasters to immediately increase the yield of their existing sports rights while eliminating friction.",
    "The Future of Sports FAST is here. Arenza transforms the platform from a commodity utility into a defensible habit, bridging national scale with hyper-local precision."
]

SPORTS_SLIDES = [
    "Arenza Interactive Sports Engagement — reimagining how fans connect with live sports content and how brands capture that attention.",
    "The CTV sports ad market is growing rapidly but facing a fundamental crisis: viewers are disengaging from traditional ad formats. Arenza solves this with interactive, gamified ad experiences that viewers actually want to participate in.",
    "Today's CTV models are failing across three dimensions. Ad fatigue has driven completion rates from 82 down to 57 percent. Companion apps see 70 to 80 percent drop-off within 30 days. And QR-to-mobile scan rates sit at a dismal 0.004 percent. Arenza fixes each one: opt-in gamified panels, temporal in-stream mechanics, and frictionless point-of-sale QR codes inside the app wallet.",
    "The Arenza platform is built on four layers. Layer one: low-latency video infrastructure with sub-500 millisecond delivery and server-side ad insertion. Layer two: an interactive prediction engine driven by SCTE-35 triggers. Layer three: on-device CoreML for zero-party data enrichment — no personal data ever leaves the device. Layer four: local commerce integration with POS systems like Toast, Square, and Clover.",
    "The user experience is a split-screen format. Live sports on top, interactive engagement panel on the bottom. Nine tabs cover every engagement format: predictions, bingo, scratch cards, more-or-less games, local offers, wallet, leaderboards, profile, and sponsored ad games.",
    "The prediction mechanic is the core engagement loop. During a live match, viewers receive context-aware microgames tied to what is happening on screen. Will the next goal be scored from inside the box? Will there be a card before halftime? Each correct prediction earns points, building an addictive loop that keeps viewers engaged through commercial breaks.",
    "What makes this work for advertisers is contextual ad insertion. When the game reaches specific SCTE-35 markers, Arenza surfaces sponsor-branded interactive games. A restaurant might sponsor a halftime trivia round, with rewards redeemable at their location. The viewer earns points. The advertiser gets verified, engaged impressions. The broadcaster monetizes inventory that was previously dead air.",
    "The revenue model serves all three parties. Broadcasters get higher CPMs through verified interactive impressions. Advertisers get measurable engagement — not just viewability, but active participation with provable redemption. Local businesses get foot traffic directly attributable to their sponsored game, with a 40 to 1 return on a dollar redemption fee.",
    "Engagement happens across three temporal windows. Pre-game: lineup predictions and prop bets build anticipation. In-game: live play predictions and sponsor trivia keep attention locked during the match. Post-game: reward redemption and leaderboard competition extend the session beyond final whistle. This creates appointment-based viewing habits — exactly what FAST channels need.",
    "The data architecture is privacy-first by design. All user profiling runs on-device via CoreML. Watch-time patterns, team preferences, and interaction signals are processed locally. No PII is transmitted. This makes Arenza GDPR compliant, Apple ATT compliant, and CCPA compliant from day one.",
    "The points economy is carefully structured outside gambling regulation. Points are non-transferable and non-redeemable for cash — operating legally in all 50 US states without requiring gaming licenses.",
    "Arenza leverages proven gamification psychology. Variable reward schedules, competitive leaderboards, and streak mechanics create the same engagement loops that drive mobile gaming — applied to live sports broadcasting.",
    "The competitive landscape includes standalone prediction apps and broadcaster companion apps, but none combine live-stream integration, gamified advertising, and local commerce in a single frictionless experience.",
    "What has been built: a working iOS prototype with a split-screen player, prediction engine, QR wallet, leaderboard, and merchant scanner. The technical implementation plan is documented and development partner engaged.",
    "The ask is 25,000 dollars initial investment with follow-on up to 250,000 dollars as milestones are met. Milestone at 90 days: 10 live merchant accounts, 500 or more active wallet pass holders, and measurable redemption data for investor reporting. ArenzaTV — Queens, New York.",
]

LOYALTY_A_SLIDES = [
    "Frictionless Restaurant Loyalty by ArenzaTV — a complete customer retention and engagement platform purpose-built for local restaurants and bars.",
    "Restaurant loyalty is fundamentally broken. Paper punch cards get lost. Branded apps require downloads that 90 percent of customers refuse. Third-party platforms like Yelp and DoorDash own the customer relationship and take 15 to 30 percent commissions. Arenza eliminates every friction point by putting the loyalty program directly into Apple Wallet — no app download, no account creation, no friction.",
    "The customer journey is three steps. Step one: scan a QR code at the table or counter — the pass installs to Apple Wallet in under 5 seconds. Step two: the pass automatically appears on the lock screen when the customer returns within proximity of the restaurant. Step three: staff scans the pass, points are awarded or redeemed, and the loop closes. No app. No login. No waiting.",
    "Arenza's technical architecture has four layers. The foundation is a rule-based coupon engine that will evolve to CoreML on-device machine learning. On top of that, QR and NFC scanning with HMAC-signed single-use reward tokens. Then Apple Wallet PKPass generation with dynamic updates. And at the top layer, direct webhook integration to POS systems — Toast, Square, and Clover.",
    "The engagement toolkit goes far beyond basic points. Arenza offers four interactive ad formats ranked by engagement depth. Rewarded ads at the top: scratch cards that reveal coupon codes deliver the highest engagement. Playable ads: spin-to-win wheels create a game-like experience. Interactive banners: menu exploration and dish reveals. Even niche creative formats like build-your-own-roll simulators. Brands that move from passive banners to gamified mechanics report thousands of new loyalty enrollments.",
    "The spin-to-win wheel is the hero engagement mechanic. It is visually exciting, takes 3 seconds, and guarantees a reward every time — even if it is just bonus points. The variable reward schedule creates the same dopamine loop that drives slot machines, applied ethically to restaurant loyalty.",
    "Here is how a typical user session works. A customer sits down at a restaurant and scans the table QR code. The Apple Wallet pass installs instantly. During the meal, a push notification offers a spin-to-win for dessert. The customer spins, wins a free coffee, and the coupon appears in their wallet. At checkout, the staff scans the pass — the reward is redeemed, and 50 loyalty points are credited. The customer leaves with a pass that will re-engage them automatically on their next visit.",
    "The merchant dashboard gives restaurant operators real-time visibility into their loyalty program. Active pass holders, redemption rates, popular rewards, peak engagement hours — all presented in a clean interface. The dashboard also supports push notification campaigns: slow Tuesday? Send a flash deal to all pass holders within a 2-mile radius. No email list needed. No SMS costs. Direct to the lock screen.",
]

LOYALTY_B_SLIDES = [
    "The numbers tell the story. Beyond the surface metrics, what matters is the closed-loop attribution. A restaurant runs a spin to win a free appetizer campaign. Arenza can report exactly how many spins occurred, how many were redeemed, what the average ticket was for redeeming customers, and the incremental revenue generated. No other local loyalty platform provides this level of attribution.",
    "For restaurants already using POS systems, Arenza integrates directly. When a customer redeems a reward, the discount is applied automatically in Toast, Square, or Clover. No manual entry. No coupon codes to type. The staff simply scans the wallet pass and the POS handles the rest. This eliminates the number one operational complaint about loyalty programs: staff friction.",
    "The privacy architecture is built for compliance from day one. All user profiling runs on-device. Arenza never collects names, emails, or phone numbers unless the customer explicitly provides them. The system is GDPR compliant, CCPA compliant, and passes Apple App Tracking Transparency requirements. For restaurants concerned about data liability, this is a decisive advantage.",
    "The unit economics work at every scale. A neighborhood restaurant paying 49 dollars per month gets unlimited wallet passes, spin-to-win campaigns, push notifications, and a real-time dashboard. A local merchant spending 40 dollars average ticket, acquired via a 1 dollar redemption fee, delivers a 40 to 1 return on ad spend. This is the attribution story no existing loyalty platform can tell at the local level.",
    "Here is a summary of projected metrics for the pilot program. 40 percent or higher QR scan rate from physical cards. 25 percent or higher wallet pass install rate from initial scans. 35 percent increase in return visit rate for members versus non-members. 20 percent daily engagement among active pass holders. 15 to 25 percent push notification open rate landing directly on the lock screen. And over 30 percent points redemption rate — proving system liquidity.",
    "A complete, zero-friction customer engagement ecosystem. No custom app required. The restaurant brand lives inside Apple Wallet — the one app every iPhone user already has. No download barrier. No account creation. No friction between the first scan and the hundredth visit.",
    "What has been built: a working prototype including a split-screen player, AI coupon engine — currently rule-based and ML-ready, Apple Wallet PKPass generation service, QR and NFC staff scanner app, and a merchant dashboard progressive web app. Restaurant and bar vertical templates are complete. The ask: 25,000 dollar initial investment with follow-on up to 250,000 dollars as milestones are hit. Milestone at 90 days: 10 live merchant accounts, 500 or more active wallet pass holders, and measurable redemption rate data for fund reporting. ArenzaTV — Queens, New York.",
]

# ── Helpers ────────────────────────────────────────────────────────────────────

def mp3_duration_seconds(mp3_bytes: bytes) -> float:
    """Estimate MP3 duration by scanning frame headers."""
    RATES = [0,32,40,48,56,64,80,96,112,128,160,192,224,256,320,0]
    i, duration = 0, 0.0
    while i < len(mp3_bytes) - 4:
        b = mp3_bytes[i:i+4]
        if b[0] == 0xFF and (b[1] & 0xE0) == 0xE0:
            br_idx = (b[2] >> 4) & 0xF
            sr_idx = (b[2] >> 2) & 0x3
            sr = [44100,48000,32000,0][sr_idx]
            br = RATES[br_idx] * 1000
            if br > 0 and sr > 0:
                padding = (b[2] >> 1) & 1
                frame_size = 144 * br // sr + padding
                duration += 1152 / sr
                i += frame_size
                continue
        i += 1
    return duration


def call_elevenlabs(text: str) -> tuple[bytes, list, list]:
    """Call /stream/with-timestamps. Returns (audio_bytes, chars, start_times_sec)."""
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}/stream/with-timestamps"
    headers = {"xi-api-key": API_KEY, "Content-Type": "application/json"}
    payload = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": {"stability": 0.50, "similarity_boost": 0.75},
    }
    resp = requests.post(url, headers=headers, json=payload, stream=True, timeout=120)
    resp.raise_for_status()

    audio_bytes = b""
    all_chars: list[str] = []
    all_starts: list[float] = []

    for raw_line in resp.iter_lines():
        if not raw_line:
            continue
        try:
            chunk = json.loads(raw_line)
        except json.JSONDecodeError:
            continue
        if chunk.get("audio_base64"):
            audio_bytes += base64.b64decode(chunk["audio_base64"])
        aln = chunk.get("normalized_alignment") or chunk.get("alignment")
        if aln:
            all_chars.extend(aln.get("characters", []))
            all_starts.extend(aln.get("character_start_times_seconds", []))

    return audio_bytes, all_chars, all_starts


def build_cues(slide_texts: list[str], chars: list[str], starts: list[float],
               slide_offset: int = 0, time_offset: float = 0.0) -> list[dict]:
    """
    Map each slide's first non-whitespace character to a startSec.
    slide_offset shifts the slide index (for loyalty part B).
    time_offset shifts all times (for loyalty part B after concat).
    """
    sep = "\n\n"
    cues = []
    char_pos = 0  # index into chars/starts

    for i, text in enumerate(slide_texts):
        # Skip whitespace chars at current position
        while char_pos < len(chars) and chars[char_pos].strip() == "":
            char_pos += 1
        if char_pos < len(starts):
            cues.append({
                "slide": i + slide_offset,
                "startSec": round(starts[char_pos] + time_offset, 3),
            })
        # Advance by text length + separator
        char_pos += len(text) + len(sep)

    return cues


def generate_deck(name: str, slide_texts: list[str],
                  slide_offset: int = 0, time_offset: float = 0.0):
    print(f"\n>> Generating {name} ({len(slide_texts)} slides)...")
    mp3_path  = os.path.join(OUT_DIR, f"{name}.mp3")
    cues_path = os.path.join(OUT_DIR, f"{name}-cues.json")
    
    if os.path.exists(mp3_path) and os.path.exists(cues_path):
        print(f"  Skipping: {mp3_path} already exists")
        with open(mp3_path, "rb") as f: audio = f.read()
        with open(cues_path, "r") as f: cues = json.load(f)
        return audio, cues, mp3_duration_seconds(audio)

    full_text = "\n\n".join(slide_texts)
    audio, chars, starts = call_elevenlabs(full_text)
    cues = build_cues(slide_texts, chars, starts, slide_offset, time_offset)

    mp3_path  = os.path.join(OUT_DIR, f"{name}.mp3")
    cues_path = os.path.join(OUT_DIR, f"{name}-cues.json")
    with open(mp3_path,  "wb") as f: f.write(audio)
    with open(cues_path, "w")  as f: json.dump(cues, f, indent=2)

    duration = mp3_duration_seconds(audio)
    print(f"  OK  {mp3_path}  ({len(audio)//1024} KB, ~{duration:.1f}s)")
    print(f"  OK  {cues_path}")
    for c in cues:
        print(f"    slide {c['slide']+1:2d}  ->  {c['startSec']:.3f}s")
    return audio, cues, duration


def merge_loyalty(audio_a: bytes, cues_a: list, dur_a: float,
                  audio_b: bytes, cues_b_raw: list):
    """Concat audio, offset part-B cues by dur_a, write merged files."""
    merged_audio = audio_a + audio_b
    merged_cues  = cues_a + [
        {"slide": c["slide"], "startSec": round(c["startSec"] + dur_a, 3)}
        for c in cues_b_raw
    ]
    mp3_path  = os.path.join(OUT_DIR, "arenza-loyalty.mp3")
    cues_path = os.path.join(OUT_DIR, "arenza-loyalty-cues.json")
    with open(mp3_path,  "wb") as f: f.write(merged_audio)
    with open(cues_path, "w")  as f: json.dump(merged_cues, f, indent=2)
    print(f"\nOK Merged loyalty  ->  {mp3_path}")
    print(f"OK Merged cues     ->  {cues_path}")


# ── Main ───────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    if not API_KEY:
        sys.exit("ERROR: set ELEVENLABS_API_KEY environment variable first.")
    os.makedirs(OUT_DIR, exist_ok=True)

    # Sports V1 (Interactive Canvas)
    generate_deck("arenza-sports-v1", SPORTS_V1_SLIDES)

    # Sports (single generation - ~4,900 chars)
    generate_deck("arenza-sports", SPORTS_SLIDES)

    # Loyalty Part A (slides 1-8)
    audio_a, cues_a, dur_a = generate_deck(
        "arenza-loyalty-a", LOYALTY_A_SLIDES,
        slide_offset=0, time_offset=0.0
    )

    # Loyalty Part B (slides 9-15) - raw times start from 0
    audio_b, cues_b_raw, _ = generate_deck(
        "arenza-loyalty-b", LOYALTY_B_SLIDES,
        slide_offset=8, time_offset=0.0
    )

    # Merge into single arenza-loyalty.mp3 + cues
    merge_loyalty(audio_a, cues_a, dur_a, audio_b, cues_b_raw)

    print("\nDone! Drop the MP3s + cues JSONs into public/audio/ and reload the page.")
