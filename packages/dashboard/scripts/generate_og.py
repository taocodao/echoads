import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

def generate():
    base_dir = r"d:\Projects\echoads\packages\dashboard"
    assets_dir = os.path.join(base_dir, "public", "assets")
    os.makedirs(assets_dir, exist_ok=True)
    out_path = os.path.join(assets_dir, "og-preview-v3.jpg")
    logo_path = os.path.join(base_dir, "public", "arenza-logo-real.png")

    W, H = 1200, 627
    BG = (8, 8, 16)

    # ── Dark background ──
    bg = Image.new("RGBA", (W, H), (*BG, 255))

    # ── Load logo — it already has proper RGBA transparency! ──
    logo = Image.open(logo_path).convert("RGBA")  # preserves existing alpha
    lw, lh = logo.size
    print(f"Logo original: {lw}x{lh} RGBA")

    # Scale: 1100px wide (50px padding each side)
    target_w = 1100
    target_h = int(lh * (target_w / lw))
    logo = logo.resize((target_w, target_h), Image.Resampling.LANCZOS)

    logo_x = (W - target_w) // 2
    logo_y = 35

    # Composite using the existing alpha channel
    bg.paste(logo, (logo_x, logo_y), logo)

    # Convert to RGB for final output
    bg = bg.convert("RGB")

    # ── Tagline text ──
    draw = ImageDraw.Draw(bg)
    text = "Gamified Sports FAST Ads for Local Commerce"
    font_path = r"C:\Windows\Fonts\ariblk.ttf"

    best_font = None
    for size in range(72, 20, -1):
        f = ImageFont.truetype(font_path, size)
        b = draw.textbbox((0, 0), text, font=f)
        if b[2] - b[0] <= 1120:
            best_font = f
            print(f"Text: {size}px  width={b[2]-b[0]}px")
            break

    b = draw.textbbox((0, 0), text, font=best_font)
    tw, th = b[2]-b[0], b[3]-b[1]
    tx = (W - tw) // 2
    zone_top = logo_y + target_h + 10
    ty = zone_top + ((H - zone_top - th) // 2)
    draw.text((tx, ty), text, fill=(255, 255, 255), font=best_font)

    bg.save(out_path, format="JPEG", quality=95, optimize=True)
    print(f"Saved: {out_path}  ({os.path.getsize(out_path)//1024} KB)")

if __name__ == "__main__":
    generate()
