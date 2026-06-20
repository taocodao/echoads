"""
Regenerate audio + cues for the three legacy decks using updated narration scripts.
Decks: arenza-loyalty, arenza-sports, arenza-sports-v1
"""

import os, sys, json, requests, time, pathlib

sys.stdout.reconfigure(encoding="utf-8")
sys.stderr.reconfigure(encoding="utf-8")

# ── Config ─────────────────────────────────────────────────────────────────────
API_KEY  = os.environ.get("ELEVENLABS_API_KEY", "")
VOICE_ID = "cgSgspJ2msm6clMCkdW9"   # same voice as other decks
MODEL    = "eleven_multilingual_v2"
BASE_URL = "https://api.elevenlabs.io/v1"

ROOT      = pathlib.Path(__file__).parent.parent
AUDIO_DIR = ROOT / "public" / "audio"
AUDIO_DIR.mkdir(parents=True, exist_ok=True)

# ── Import scripts ─────────────────────────────────────────────────────────────
sys.path.insert(0, str(pathlib.Path(__file__).parent))
from slide_texts_v2 import LOYALTY, SPORTS, SPORTS_V1

DECKS = [
    {"key": "arenza-loyalty",   "slides": LOYALTY,    "count": 15},
    {"key": "arenza-sports",    "slides": SPORTS,     "count": 15},
    {"key": "arenza-sports-v1", "slides": SPORTS_V1,  "count": 15},
]

# ── Helpers ────────────────────────────────────────────────────────────────────
def tts(text: str) -> bytes:
    """Call ElevenLabs TTS and return raw MP3 bytes."""
    url = f"{BASE_URL}/text-to-speech/{VOICE_ID}"
    headers = {"xi-api-key": API_KEY, "Content-Type": "application/json"}
    payload = {
        "text": text,
        "model_id": MODEL,
        "voice_settings": {"stability": 0.45, "similarity_boost": 0.82, "style": 0.2},
    }
    resp = requests.post(url, headers=headers, json=payload, timeout=120)
    resp.raise_for_status()
    return resp.content


def mp3_duration(data: bytes) -> float:
    """Estimate MP3 duration from bitrate header (128 kbps fallback)."""
    # Try to read the bitrate from ID3/frame header
    bitrate_kbps = 128
    for i in range(min(len(data) - 4, 10000)):
        b0, b1 = data[i], data[i + 1]
        if b0 == 0xFF and (b1 & 0xE0) == 0xE0:
            bitrate_index = (data[i + 2] >> 4) & 0x0F
            rates = [0,32,40,48,56,64,80,96,112,128,160,192,224,256,320]
            if 1 <= bitrate_index <= 14:
                bitrate_kbps = rates[bitrate_index]
            break
    return len(data) * 8 / (bitrate_kbps * 1000)


def generate_deck(deck: dict):
    key    = deck["key"]
    slides = deck["slides"]
    n      = deck["count"]

    assert len(slides) == n, f"{key}: expected {n} slides, got {len(slides)}"

    print(f"\n{'='*60}")
    print(f"  Generating: {key}  ({n} slides)")
    print(f"{'='*60}")

    chunks     = []   # list of (mp3_bytes, duration_sec)
    slide_cues = []   # list of start times (seconds)

    for i, text in enumerate(slides, 1):
        print(f"  Slide {i:02d}/{n} ... ", end="", flush=True)
        for attempt in range(3):
            try:
                mp3 = tts(text)
                dur = mp3_duration(mp3)
                chunks.append((mp3, dur))
                print(f"OK  ({dur:.1f}s)")
                break
            except Exception as e:
                print(f"  retry {attempt+1}: {e}")
                time.sleep(3)
        else:
            print(f"  FAILED — aborting")
            sys.exit(1)

        time.sleep(0.5)  # rate-limit courtesy

    # Concatenate MP3 frames
    combined = b"".join(mp3 for mp3, _ in chunks)

    # Build cue list (cumulative start times)
    t = 0.0
    for _, dur in chunks:
        slide_cues.append(round(t, 3))
        t += dur

    total = round(t, 2)
    print(f"\n  Total duration: {total}s")

    # Write MP3
    mp3_path = AUDIO_DIR / f"{key}.mp3"
    mp3_path.write_bytes(combined)
    print(f"  Wrote: {mp3_path.name}  ({len(combined)//1024} KB)")

    # Write cues.json
    cues = {"totalDuration": total, "cues": slide_cues}
    cues_path = AUDIO_DIR / f"{key}-cues.json"
    cues_path.write_text(json.dumps(cues, indent=2))
    print(f"  Wrote: {cues_path.name}")

    return total


if __name__ == "__main__":
    if not API_KEY:
        print("ERROR: ELEVENLABS_API_KEY not set.")
        sys.exit(1)

    print(f"ElevenLabs key: {API_KEY[:8]}...")

    totals = {}
    for deck in DECKS:
        dur = generate_deck(deck)
        totals[deck["key"]] = dur

    print("\n" + "="*60)
    print("  ALL DONE")
    for k, v in totals.items():
        m, s = divmod(int(v), 60)
        print(f"  {k:30s}  {m}:{s:02d}")
    print("="*60)
