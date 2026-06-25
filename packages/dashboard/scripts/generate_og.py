import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

def generate():
    base_dir = r"d:\Projects\echoads\packages\dashboard"
    assets_dir = os.path.join(base_dir, "public", "assets")
    os.makedirs(assets_dir, exist_ok=True)
    out_path = os.path.join(assets_dir, "og-preview-v2.jpg")
    logo_path = os.path.join(base_dir, "public", "arenza-logo-real.png")

    W, H = 1200, 627

    # ── Dark background ──
    bg = Image.new("RGB", (W, H), (8, 8, 15))

    # ── Paste logo-real (white bg → transparent) ──
    logo = Image.open(logo_path).convert("RGBA")
    arr = np.array(logo)
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    white = (r > 230) & (g > 230) & (b > 230)
    arr[:,:,3] = np.where(white, 0, a)
    logo = Image.fromarray(arr)

    # Scale: 300px tall, max 950px wide
    lw, lh = logo.size
    target_h = 300
    target_w = int(lw * (target_h / lh))
    if target_w > 950:
        target_w = 950
        target_h = int(lh * (target_w / lw))
    logo = logo.resize((target_w, target_h), Image.Resampling.LANCZOS)

    logo_x = (W - target_w) // 2
    logo_y = 60
    bg.paste(logo, (logo_x, logo_y), logo)

    # ── Tagline text: find largest Arial Black size that fits 1 line ──
    draw = ImageDraw.Draw(bg)
    text = "Gamified Sports FAST Ads for Local Commerce"
    font_path = r"C:\Windows\Fonts\ariblk.ttf"

    best_font = None
    for size in range(72, 20, -1):
        f = ImageFont.truetype(font_path, size)
        bbox = draw.textbbox((0, 0), text, font=f)
        tw = bbox[2] - bbox[0]
        if tw <= 1140:
            best_font = f
            print(f"Text: {size}px  width={tw}px")
            break

    bbox = draw.textbbox((0, 0), text, font=best_font)
    tw, th = bbox[2]-bbox[0], bbox[3]-bbox[1]
    tx = (W - tw) // 2
    zone_top = logo_y + target_h + 10
    ty = zone_top + ((H - zone_top - th) // 2)

    draw.text((tx, ty), text, fill=(255, 255, 255), font=best_font)

    bg.save(out_path, format="JPEG", quality=95, optimize=True)
    print(f"Saved: {out_path}  ({os.path.getsize(out_path)//1024} KB)")

if __name__ == "__main__":
    generate()
