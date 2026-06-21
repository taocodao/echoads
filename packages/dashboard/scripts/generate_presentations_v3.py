import base64, json, os, sys
import requests

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

from slide_texts_v3 import INFRASTRUCTURE_ENGINE, THE_35_SECOND_ENGINE, VERIFIED_BROADCAST_BLUEPRINT, CMXS_VERIFIED_MEDIA_INFRASTRUCTURE

API_KEY  = os.environ.get("ELEVENLABS_API_KEY", "")
VOICE_ID = os.environ.get("ELEVENLABS_VOICE_ID", "JBFqnCBsd6RMkjVDRZzb")  # George
MODEL_ID = "eleven_multilingual_v2"
OUT_DIR  = os.path.join(os.path.dirname(__file__), "..", "public", "audio")

def mp3_duration_seconds(mp3_bytes: bytes) -> float:
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
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE_ID}/stream/with-timestamps"
    headers = {"xi-api-key": API_KEY, "Content-Type": "application/json"}
    payload = {
        "text": text,
        "model_id": MODEL_ID,
        "voice_settings": {"stability": 0.50, "similarity_boost": 0.75},
    }
    resp = requests.post(url, headers=headers, json=payload, stream=True, timeout=180)
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

def build_cues(slide_texts, chars, starts, slide_offset=0, time_offset=0.0):
    sep = "\n\n"
    cues = []
    char_pos = 0
    for i, text in enumerate(slide_texts):
        while char_pos < len(chars) and chars[char_pos].strip() == "":
            char_pos += 1
        if char_pos < len(starts):
            cues.append({"slide": i + slide_offset, "startSec": round(starts[char_pos] + time_offset, 3)})
        char_pos += len(text) + len(sep)
    return cues

def generate_deck(name, slide_texts, slide_offset=0, time_offset=0.0, force=False):
    mp3_path  = os.path.join(OUT_DIR, f"{name}.mp3")
    cues_path = os.path.join(OUT_DIR, f"{name}-cues.json")

    if not force and os.path.exists(mp3_path) and os.path.exists(cues_path):
        print(f"  SKIP  {name} (already exists)")
        with open(mp3_path, "rb") as f: audio = f.read()
        with open(cues_path, "r") as f: cues = json.load(f)
        return audio, cues, mp3_duration_seconds(audio)

    print(f"\n>> Generating {name} ({len(slide_texts)} slides)...")
    full_text = "\n\n".join(slide_texts)
    audio, chars, starts = call_elevenlabs(full_text)
    cues = build_cues(slide_texts, chars, starts, slide_offset, time_offset)

    with open(mp3_path,  "wb") as f: f.write(audio)
    with open(cues_path, "w")  as f: json.dump(cues, f, indent=2)

    dur = mp3_duration_seconds(audio)
    print(f"  OK  {mp3_path}  ({len(audio)//1024} KB, ~{dur:.1f}s)")
    for c in cues:
        print(f"    slide {c['slide']+1:2d}  ->  {c['startSec']:.3f}s")
    return audio, cues, dur

def merge_decks(name, audio_a, cues_a, dur_a, audio_b, cues_b_raw):
    merged_audio = audio_a + audio_b
    merged_cues  = cues_a + [
        {"slide": c["slide"], "startSec": round(c["startSec"] + dur_a, 3)}
        for c in cues_b_raw
    ]
    mp3_path  = os.path.join(OUT_DIR, f"{name}.mp3")
    cues_path = os.path.join(OUT_DIR, f"{name}-cues.json")
    with open(mp3_path,  "wb") as f: f.write(merged_audio)
    with open(cues_path, "w")  as f: json.dump(merged_cues, f, indent=2)
    print(f"\nOK Merged {name} -> {mp3_path}")

def generate_split(name, texts):
    audio_a, cues_a, dur_a = generate_deck(f"{name}-a", texts[:8], slide_offset=0)
    audio_b, cues_b_raw, _ = generate_deck(f"{name}-b", texts[8:], slide_offset=8)
    merge_decks(name, audio_a, cues_a, dur_a, audio_b, cues_b_raw)

if __name__ == "__main__":
    if not API_KEY:
        sys.exit("ERROR: set ELEVENLABS_API_KEY environment variable first.")
    os.makedirs(OUT_DIR, exist_ok=True)

    generate_split("cmxs-infrastructure-engine", INFRASTRUCTURE_ENGINE)
    generate_split("the-35-second-engine", THE_35_SECOND_ENGINE)
    generate_split("verified-broadcast-blueprint", VERIFIED_BROADCAST_BLUEPRINT)
    generate_split("cmxs-verified-media-infrastructure", CMXS_VERIFIED_MEDIA_INFRASTRUCTURE)

    print("\nDone! All MP3s and cue files written to public/audio/")
