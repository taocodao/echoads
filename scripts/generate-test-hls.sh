#!/usr/bin/env bash
# scripts/generate-test-hls.sh
# ─────────────────────────────────────────────────────────────────────────────
# Generates HLS content and ad creative segments using FFmpeg, then uploads
# everything to S3.
#
# Prerequisites:
#   - FFmpeg installed (brew install ffmpeg  OR  sudo apt install ffmpeg)
#   - AWS CLI configured
#   - S3 bucket created (run setup-s3-media.sh first)
#
# Usage:
#   export S3_MEDIA_BUCKET=cmxs-media-prototype
#   bash scripts/generate-test-hls.sh
#
# Optional: Place a real MP4 sports clip named "sports_input.mp4" in the
# current directory. Otherwise, a synthetic test pattern is generated.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

BUCKET="${S3_MEDIA_BUCKET:-cmxs-media-prototype}"
TMP_DIR="./tmp_hls_gen"
mkdir -p "$TMP_DIR"

echo "═══════════════════════════════════════════════"
echo "  CMXS HLS Content Generator"
echo "  Output bucket: $BUCKET"
echo "═══════════════════════════════════════════════"

# Check FFmpeg
if ! command -v ffmpeg &> /dev/null; then
  echo "❌ FFmpeg not found. Install with: brew install ffmpeg"
  exit 1
fi

# ── Helper: transcode to HLS ──────────────────────────────────────────────────
transcode_hls() {
  local INPUT="$1"
  local OUTDIR="$2"
  local RESOLUTION="$3"    # e.g., 1920x1080
  local BITRATE="$4"       # e.g., 8M
  local FPS="$5"           # e.g., 60
  local LABEL="$6"         # e.g., sports_1080p

  mkdir -p "$TMP_DIR/$LABEL"
  echo "  Transcoding → $LABEL (${RESOLUTION} @ ${BITRATE}, ${FPS}fps)..."

  ffmpeg -i "$INPUT" \
    -c:v libx264 -b:v "$BITRATE" -r "$FPS" -s "$RESOLUTION" \
    -c:a aac -b:a 128k \
    -f hls \
    -hls_time 6 \
    -hls_list_size 0 \
    -hls_segment_filename "$TMP_DIR/$LABEL/seg_%03d.ts" \
    -hls_flags independent_segments \
    "$TMP_DIR/$LABEL/stream.m3u8" -y 2>/dev/null

  echo "    ✅ Generated $(ls $TMP_DIR/$LABEL/*.ts | wc -l) segments"
}

# ── Helper: generate ad creative (color bar + text) ─────────────────────────
generate_ad() {
  local OUTDIR="$1"
  local DURATION="$2"     # seconds (15 or 30)
  local LABEL="$3"        # display text
  local COLOR="$4"        # background color hex (e.g., 0x1a73e8)

  mkdir -p "$TMP_DIR/$OUTDIR"
  echo "  Generating ad → $OUTDIR (${DURATION}s)..."

  ffmpeg \
    -f lavfi -i "color=c=${COLOR}:s=1920x1080:r=60:d=${DURATION}" \
    -f lavfi -i "sine=frequency=440:sample_rate=44100" \
    -vf "drawtext=text='${LABEL}':fontsize=80:fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:fontfile=/System/Library/Fonts/Helvetica.ttc,
         drawtext=text='CMXS Sports Channel':fontsize=36:fontcolor=rgba(255\\,255\\,255\\,0.7):x=(w-text_w)/2:y=h-100:fontfile=/System/Library/Fonts/Helvetica.ttc" \
    -c:v libx264 -b:v 8M -r 60 \
    -c:a aac -b:a 128k -shortest \
    -f hls \
    -hls_time 6 \
    -hls_list_size 0 \
    -hls_segment_filename "$TMP_DIR/$OUTDIR/ad_seg_%03d.ts" \
    "$TMP_DIR/$OUTDIR/ad.m3u8" -y 2>/dev/null

  echo "    ✅ Generated $(ls $TMP_DIR/$OUTDIR/*.ts | wc -l) segments"
}

# ── 1. Content: Generate or use existing input ────────────────────────────────
echo ""
echo "▶ Step 1: Preparing source content..."

if [ -f "sports_input.mp4" ]; then
  echo "  Using sports_input.mp4 (real sports clip)"
  CONTENT_INPUT="sports_input.mp4"
else
  echo "  No sports_input.mp4 found — generating synthetic sports-style content..."
  # Create a dynamic test pattern simulating a sports broadcast
  ffmpeg \
    -f lavfi -i "testsrc2=s=1920x1080:r=60:d=300" \
    -f lavfi -i "sine=frequency=1000:sample_rate=44100:d=300" \
    -vf "drawtext=text='CMXS SPORTS LIVE - LIV GOLF Round 2':fontsize=48:fontcolor=white:x=40:y=40,
         drawtext=text='%{pts\\:hms}':fontsize=36:fontcolor=yellow:x=w-200:y=40" \
    -c:v libx264 -b:v 8M -r 60 -t 300 \
    -c:a aac -b:a 128k \
    "sports_input.mp4" -y 2>/dev/null
  CONTENT_INPUT="sports_input.mp4"
  echo "  ✅ Generated 5-min synthetic sports content"
fi

# ── 2. Content: Transcode to 3 ABR profiles ──────────────────────────────────
echo ""
echo "▶ Step 2: Transcoding content to ABR ladder..."

transcode_hls "$CONTENT_INPUT" "$TMP_DIR/content/sports_1080p" "1920x1080" "8M" "60" "sports_1080p"
transcode_hls "$CONTENT_INPUT" "$TMP_DIR/content/sports_720p"  "1280x720"  "4M" "60" "sports_720p"
transcode_hls "$CONTENT_INPUT" "$TMP_DIR/content/sports_360p"  "640x360"   "1M" "30" "sports_360p"

# ── 3. Generate HLS Master Playlist with SCTE-35 cue markers ─────────────────
echo ""
echo "▶ Step 3: Building master manifest with SCTE-35 cue markers..."

# For the prototype we inject cue markers manually at segment 5 (30s into content)
MASTER_MANIFEST="$TMP_DIR/sports_1080p/master_scte35.m3u8"
STREAM_M3U8="$TMP_DIR/sports_1080p/stream.m3u8"

# Patch the stream manifest: inject SCTE-35 cue-out after segment 4, cue-in after seg 9
python3 - <<'PYEOF'
import sys

with open("tmp_hls_gen/sports_1080p/stream.m3u8", "r") as f:
    lines = f.readlines()

output = []
seg_count = 0
cue_out_done = False
cue_in_done = False

for line in lines:
    output.append(line)
    if line.startswith("#EXTINF"):
        seg_count += 1
        if seg_count == 4 and not cue_out_done:
            # After segment 4, inject ad break cue
            output.append("\n")
            output.append("## ── AD BREAK 1: 30 seconds (Halftime) ──\n")
            output.append("#EXT-X-DISCONTINUITY\n")
            output.append("#EXT-X-CUE-OUT:DURATION=30\n")
            output.append("## SSAI_PLACEHOLDER_START campaignId=__CAMPAIGN_ID__ duration=30\n")
            output.append("## SSAI_PLACEHOLDER_END\n")
            output.append("#EXT-X-CUE-IN\n")
            output.append("#EXT-X-DISCONTINUITY\n")
            output.append("\n")
            cue_out_done = True

with open("tmp_hls_gen/sports_1080p/master_scte35.m3u8", "w") as f:
    f.writelines(output)

print("  ✅ SCTE-35 cue markers injected into manifest")
PYEOF

# ── 4. Generate ad creatives ──────────────────────────────────────────────────
echo ""
echo "▶ Step 4: Generating ad creatives..."

generate_ad "callaway_30s_1080p" 30 "⛳ CALLAWAY PARADYM DRIVER" "0x1a5c2a"
generate_ad "bmw_30s_1080p"      30 "🚗 BMW M4 COMPETITION"       "0x1c3a5a"
generate_ad "nike_15s_1080p"     15 "👟 NIKE AIR MAX"             "0x2d1a3a"
generate_ad "taylormade_15s_1080p" 15 "⛳ TAYLORMADE STEALTH 2"  "0x3a1a1a"
generate_ad "rolex_30s_1080p"    30 "⌚ ROLEX OYSTER PERPETUAL"   "0x3a2a0a"

# ── 5. Upload to S3 ───────────────────────────────────────────────────────────
echo ""
echo "▶ Step 5: Uploading to S3..."

# Content segments (long TTL — immutable)
for profile in sports_1080p sports_720p sports_360p; do
  echo "  Uploading content/$profile..."
  aws s3 sync "$TMP_DIR/$profile/" "s3://$BUCKET/content/$profile/" \
    --cache-control "public, max-age=31536000, immutable" \
    --content-type "video/MP2T" \
    --exclude "*.m3u8" \
    --quiet
  # Manifests — no cache
  aws s3 sync "$TMP_DIR/$profile/" "s3://$BUCKET/content/$profile/" \
    --cache-control "no-cache, no-store" \
    --content-type "application/vnd.apple.mpegurl" \
    --exclude "*.ts" \
    --quiet
done

# Ad creatives
for ad in callaway_30s_1080p bmw_30s_1080p nike_15s_1080p taylormade_15s_1080p rolex_30s_1080p; do
  echo "  Uploading ads/$ad..."
  aws s3 sync "$TMP_DIR/$ad/" "s3://$BUCKET/ads/$ad/" \
    --cache-control "public, max-age=31536000, immutable" \
    --content-type "video/MP2T" \
    --exclude "*.m3u8" \
    --quiet
  aws s3 sync "$TMP_DIR/$ad/" "s3://$BUCKET/ads/$ad/" \
    --cache-control "no-cache" \
    --content-type "application/vnd.apple.mpegurl" \
    --exclude "*.ts" \
    --quiet
done

# ── 6. Cleanup temp files ─────────────────────────────────────────────────────
echo ""
echo "▶ Step 6: Cleaning up temporary files..."
rm -rf "$TMP_DIR"

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ HLS Generation Complete"
echo "═══════════════════════════════════════════════"
echo ""
echo "  Content streams:"
echo "    s3://${BUCKET}/content/sports_1080p/master_scte35.m3u8"
echo "    s3://${BUCKET}/content/sports_720p/stream.m3u8"
echo "    s3://${BUCKET}/content/sports_360p/stream.m3u8"
echo ""
echo "  Ad creatives:"
echo "    s3://${BUCKET}/ads/callaway_30s_1080p/ad.m3u8  (30s)"
echo "    s3://${BUCKET}/ads/bmw_30s_1080p/ad.m3u8       (30s)"
echo "    s3://${BUCKET}/ads/nike_15s_1080p/ad.m3u8      (15s)"
echo "    s3://${BUCKET}/ads/taylormade_15s_1080p/ad.m3u8 (15s)"
echo "    s3://${BUCKET}/ads/rolex_30s_1080p/ad.m3u8     (30s)"
echo ""
echo "  Next: start the API and test GET /api/ssai/manifest/test-001"
echo ""
