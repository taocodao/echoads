"""
Regenerate audio + cues for the three legacy decks using the CORRECT method:
  - ElevenLabs /stream/with-timestamps endpoint for character-level alignment
  - Build cues from actual character start times, not bitrate estimation
  
This mirrors the proven approach in generate_cues.py that produced the working
fast-blueprint, strategic-playbook, tactical-blueprint, and architecture decks.
"""

import base64, json, os, sys, pathlib, time
import requests

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.stderr.reconfigure(encoding="utf-8", errors="replace")

API_KEY  = os.environ.get("ELEVENLABS_API_KEY", "")
VOICE_ID = "cgSgspJ2msm6clMCkdW9"   # Same voice as the 4 blueprint decks
MODEL_ID = "eleven_multilingual_v2"

ROOT      = pathlib.Path(__file__).parent.parent
AUDIO_DIR = ROOT / "public" / "audio"
AUDIO_DIR.mkdir(parents=True, exist_ok=True)

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from slide_texts_v2 import LOYALTY, SPORTS, SPORTS_V1

DECKS = [
    {"key": "arenza-loyalty",   "slides": LOYALTY},
    {"key": "arenza-sports",    "slides": SPORTS},
    {"key": "arenza-sports-v1", "slides": SPORTS_V1},
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


def call_elevenlabs_with_timestamps(text: str) -> tuple[bytes, list[str], list[float]]:
    """
    Call /stream/with-timestamps endpoint.
    Returns (audio_bytes, characters_list, start_times_seconds_list).
    """
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}/stream/with-timestamps"
    headers = {"xi-api-key": API_KEY, "Content-Type": "application/json"}
    payload = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": {"stability": 0.45, "similarity_boost": 0.82, "style": 0.2},
    }
    resp = requests.post(url, headers=headers, json=payload, stream=True, timeout=300)
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


def build_cues(slide_texts: list[str], chars: list[str], starts: list[float]) -> list[dict]:
    """
    Map each slide's first non-whitespace character to a precise startSec
    using the character-level alignment data from ElevenLabs.
    """
    sep = "\n\n"
    cues = []
    char_pos = 0

    for i, text in enumerate(slide_texts):
        # Skip whitespace chars at current position
        while char_pos < len(chars) and chars[char_pos].strip() == "":
            char_pos += 1
        if char_pos < len(starts):
            cues.append({
                "slide": i,
                "startSec": round(starts[char_pos], 3),
            })
        # Advance by text length + separator
        char_pos += len(text) + len(sep)

    return cues


def generate_deck(deck: dict):
    key    = deck["key"]
    slides = deck["slides"]
    n      = len(slides)

    print(f"\n{'='*60}")
    print(f"  Generating: {key}  ({n} slides)")
    print(f"{'='*60}")

    # Check if text is under ~5000 chars (ElevenLabs single-request limit)
    full_text = "\n\n".join(slides)
    char_count = len(full_text)
    print(f"  Total characters: {char_count}")

    if char_count > 4800:
        # Split into two parts and merge (same approach as loyalty in generate_cues.py)
        mid = n // 2
        part_a_slides = slides[:mid]
        part_b_slides = slides[mid:]

        text_a = "\n\n".join(part_a_slides)
        text_b = "\n\n".join(part_b_slides)

        print(f"  Splitting: Part A ({len(part_a_slides)} slides, {len(text_a)} chars)")
        print(f"             Part B ({len(part_b_slides)} slides, {len(text_b)} chars)")

        # Generate Part A
        print(f"  Generating Part A ...", end=" ", flush=True)
        audio_a, chars_a, starts_a = call_elevenlabs_with_timestamps(text_a)
        cues_a = build_cues(part_a_slides, chars_a, starts_a)
        dur_a = mp3_duration_seconds(audio_a)
        print(f"OK ({dur_a:.1f}s, {len(audio_a)//1024} KB)")

        time.sleep(1)  # rate-limit courtesy

        # Generate Part B
        print(f"  Generating Part B ...", end=" ", flush=True)
        audio_b, chars_b, starts_b = call_elevenlabs_with_timestamps(text_b)
        cues_b_raw = build_cues(part_b_slides, chars_b, starts_b)
        dur_b = mp3_duration_seconds(audio_b)
        print(f"OK ({dur_b:.1f}s, {len(audio_b)//1024} KB)")

        # Merge
        combined_audio = audio_a + audio_b
        merged_cues = cues_a + [
            {"slide": c["slide"] + mid, "startSec": round(c["startSec"] + dur_a, 3)}
            for c in cues_b_raw
        ]
        total = dur_a + dur_b
    else:
        # Single request (small enough)
        print(f"  Generating single request ...", end=" ", flush=True)
        combined_audio, chars, starts = call_elevenlabs_with_timestamps(full_text)
        merged_cues = build_cues(slides, chars, starts)
        total = mp3_duration_seconds(combined_audio)
        print(f"OK ({total:.1f}s, {len(combined_audio)//1024} KB)")

    # Write MP3
    mp3_path = AUDIO_DIR / f"{key}.mp3"
    mp3_path.write_bytes(combined_audio)
    print(f"  Wrote: {mp3_path.name}  ({len(combined_audio)//1024} KB)")

    # Write cues.json
    cues_path = AUDIO_DIR / f"{key}-cues.json"
    cues_path.write_text(json.dumps(merged_cues, indent=2))
    print(f"  Wrote: {cues_path.name}")

    # Print cue table
    for c in merged_cues:
        m, s = divmod(int(c["startSec"]), 60)
        print(f"    Slide {c['slide']+1:2d}  ->  {m}:{s:02d}.{int((c['startSec']%1)*1000):03d}")

    return total


if __name__ == "__main__":
    if not API_KEY:
        print("ERROR: ELEVENLABS_API_KEY not set.")
        sys.exit(1)

    print(f"ElevenLabs key: {API_KEY[:8]}...")
    print(f"Voice: {VOICE_ID}")
    print(f"Using /stream/with-timestamps for precise cue alignment")

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
