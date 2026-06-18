import requests, os, json

key = os.environ["ELEVENLABS_API_KEY"]

u = requests.get("https://api.elevenlabs.io/v1/user/subscription", headers={"xi-api-key": key})
sub = u.json()
print("Plan:", sub.get("tier"))
used  = sub.get("character_count", 0)
limit = sub.get("character_limit", 0)
print(f"Characters: {used:,} used / {limit:,} limit  ({limit-used:,} remaining)")

v = requests.get("https://api.elevenlabs.io/v1/voices", headers={"xi-api-key": key})
voices = v.json().get("voices", [])
print(f"Voices: {len(voices)} available")
for voice in voices[:8]:
    print(f"  {voice['voice_id']}  {voice['name']}")
