"""
Generate audio + cues for the ArenzaTV Frictionless Sports Engagement deck.
Uses the /stream/with-timestamps endpoint for character-level cue alignment.

Usage (from repo root):
    $env:ELEVENLABS_API_KEY = "sk_..."
    python packages/dashboard/scripts/generate_frictionless_audio.py
"""

import base64, json, os, sys, pathlib, time
import requests

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

ROOT      = pathlib.Path(__file__).resolve().parent.parent.parent.parent
AUDIO_DIR = ROOT / "packages" / "dashboard" / "public" / "audio"
AUDIO_DIR.mkdir(parents=True, exist_ok=True)

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from slide_texts_frictionless import FRICTIONLESS_SPORTS_ENGAGEMENT

API_KEY  = os.environ.get("ELEVENLABS_API_KEY", "")
VOICE_ID = os.environ.get("ELEVENLABS_VOICE_ID", "JBFqnCBsd6RMkjVDRZzb")   # George (same as v3 decks)
MODEL_ID = "eleven_multilingual_v2"
DECK_KEY = "frictionless-sports-engagement"


# ── Helpers ────────────────────────────────────────────────────────────────────

def mp3_duration_seconds(mp3_bytes: bytes) -> float:
    RATES = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0]
    i, duration = 0, 0.0
    while i < len(mp3_bytes) - 4:
        b = mp3_bytes[i : i + 4]
        if b[0] == 0xFF and (b[1] & 0xE0) == 0xE0:
            br_idx = (b[2] >> 4) & 0xF
            sr_idx = (b[2] >> 2) & 0x3
            sr = [44100, 48000, 32000, 0][sr_idx]
            br = RATES[br_idx] * 1000
            if br > 0 and sr > 0:
                padding = (b[2] >> 1) & 1
                frame_size = 144 * br // sr + padding
                duration += 1152 / sr
                i += frame_size
                continue
        i += 1
    return duration


def call_elevenlabs(text: str) -> tuple[bytes, list[str], list[float]]:
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}/stream/with-timestamps"
    headers = {"xi-api-key": API_KEY, "Content-Type": "application/json"}
    payload = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": {"stability": 0.50, "similarity_boost": 0.75},
    }
    resp = requests.post(url, headers=headers, json=payload, stream=True, timeout=300)
    resp.raise_for_status()

    audio_bytes: bytes = b""
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


def build_cues(
    slide_texts: list[str],
    chars: list[str],
    starts: list[float],
    slide_offset: int = 0,
    time_offset: float = 0.0,
) -> list[dict]:
    sep = "\n\n"
    cues: list[dict] = []
    char_pos = 0
    for i, text in enumerate(slide_texts):
        while char_pos < len(chars) and chars[char_pos].strip() == "":
            char_pos += 1
        if char_pos < len(starts):
            cues.append({
                "slide": i + slide_offset,
                "startSec": round(starts[char_pos] + time_offset, 3),
            })
        char_pos += len(text) + len(sep)
    return cues


def generate_split(name: str, texts: list[str]):
    """Split a 14-slide deck into two halves and merge the audio."""
    mid = len(texts) // 2  # 7 / 7

    print(f"\n{'='*60}")
    print(f"  Generating Part A: slides 1-{mid}")
    print(f"{'='*60}")
    text_a = "\n\n".join(texts[:mid])
    audio_a, chars_a, starts_a = call_elevenlabs(text_a)
    cues_a = build_cues(texts[:mid], chars_a, starts_a, slide_offset=0)
    dur_a = mp3_duration_seconds(audio_a)
    print(f"  Part A done: {dur_a:.1f}s  {len(audio_a)//1024} KB")

    # Save Part A fragments for debugging
    (AUDIO_DIR / f"{name}-a.mp3").write_bytes(audio_a)
    (AUDIO_DIR / f"{name}-a-cues.json").write_text(json.dumps(cues_a, indent=2))

    time.sleep(1)  # courtesy pause between API calls

    print(f"\n{'='*60}")
    print(f"  Generating Part B: slides {mid+1}-{len(texts)}")
    print(f"{'='*60}")
    text_b = "\n\n".join(texts[mid:])
    audio_b, chars_b, starts_b = call_elevenlabs(text_b)
    cues_b_raw = build_cues(texts[mid:], chars_b, starts_b, slide_offset=0)
    dur_b = mp3_duration_seconds(audio_b)
    print(f"  Part B done: {dur_b:.1f}s  {len(audio_b)//1024} KB")

    (AUDIO_DIR / f"{name}-b.mp3").write_bytes(audio_b)
    (AUDIO_DIR / f"{name}-b-cues.json").write_text(json.dumps(cues_b_raw, indent=2))

    # Merge
    merged_audio = audio_a + audio_b
    merged_cues  = cues_a + [
        {"slide": c["slide"] + mid, "startSec": round(c["startSec"] + dur_a, 3)}
        for c in cues_b_raw
    ]

    mp3_path  = AUDIO_DIR / f"{name}.mp3"
    cues_path = AUDIO_DIR / f"{name}-cues.json"
    mp3_path.write_bytes(merged_audio)
    cues_path.write_text(json.dumps(merged_cues, indent=2))

    total = dur_a + dur_b
    print(f"\n  Merged -> {mp3_path.name}  ({len(merged_audio)//1024} KB, ~{total:.1f}s)")
    print(f"  Cues   -> {cues_path.name}")
    for c in merged_cues:
        m, s = divmod(int(c["startSec"]), 60)
        print(f"    Slide {c['slide']+1:2d}  ->  {m}:{s:02d}.{int((c['startSec']%1)*1000):03d}")


if __name__ == "__main__":
    if not API_KEY:
        sys.exit("ERROR: set ELEVENLABS_API_KEY environment variable first.")

    print(f"ElevenLabs key: {API_KEY[:8]}...")
    print(f"Voice ID: {VOICE_ID}")
    print(f"Deck: {DECK_KEY}  ({len(FRICTIONLESS_SPORTS_ENGAGEMENT)} slides)")

    generate_split(DECK_KEY, FRICTIONLESS_SPORTS_ENGAGEMENT)

    print("\n\nDone! Audio and cues written to public/audio/")
    print(f"  {DECK_KEY}.mp3")
    print(f"  {DECK_KEY}-cues.json")
