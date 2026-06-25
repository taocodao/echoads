import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

def composite_og_image():
    base_dir = r"d:\Projects\echoads\packages\dashboard"
    assets_dir = os.path.join(base_dir, "public", "assets")
    os.makedirs(assets_dir, exist_ok=True)
    out_path = os.path.join(assets_dir, "og-preview.jpg")
    logo_path = os.path.join(base_dir, "public", "arenza-logo.png")
    
    W, H = 1200, 627

    # ── 1. Build a clean dark background ──
    bg = Image.new("RGB", (W, H), (8, 8, 15))

    # Subtle dark radial glow in centre
    for radius, alpha in [(350, 18), (250, 25), (150, 32)]:
        overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        cx, cy = W // 2, H // 2
        od.ellipse((cx - radius, cy - radius, cx + radius, cy + radius),
                   fill=(20, 30, 70, alpha))
        bg = Image.alpha_composite(bg.convert("RGBA"), overlay).convert("RGB")

    # ── 2. Paste the real ArenzaTV logo (make white bg transparent) ──
    logo = Image.open(logo_path).convert("RGBA")
    arr = np.array(logo)
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    white = (r > 230) & (g > 230) & (b > 230)
    arr[:,:,3] = np.where(white, 0, a)
    logo = Image.fromarray(arr)

    lw, lh = logo.size
    # Scale logo: 300px tall, max 950px wide
    target_h = 300
    target_w = int(lw * (target_h / lh))
    if target_w > 950:
        target_w = 950
        target_h = int(lh * (target_w / lw))
    logo = logo.resize((target_w, target_h), Image.Resampling.LANCZOS)

    logo_x = (W - target_w) // 2
    logo_y = 50
    bg.paste(logo, (logo_x, logo_y), logo)

    # ── 3. Draw the tagline — find largest size that fits in one line ──
    draw = ImageDraw.Draw(bg)
    text = "Gamified Sports FAST Ads for Local Commerce"
    font_path = r"C:\Windows\Fonts\ariblk.ttf"
    best_font = None
    best_size = 12

    for size in range(72, 20, -1):
        try:
            f = ImageFont.truetype(font_path, size)
            bbox = draw.textbbox((0, 0), text, font=f)
            tw = bbox[2] - bbox[0]
            if tw <= 1140:
                best_font = f
                best_size = size
                print(f"Font size {size}px  width={tw}px")
                break
        except:
            pass

    if best_font is None:
        best_font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=best_font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]

    tx = (W - tw) // 2
    text_zone_top = logo_y + target_h + 15
    ty = text_zone_top + ((H - text_zone_top - th) // 2)

    draw.text((tx, ty), text, fill=(255, 255, 255), font=best_font)

    # ── 4. Save ──
    bg.save(out_path, format="JPEG", quality=95, optimize=True)
    print(f"Saved {out_path}  ({os.path.getsize(out_path) // 1024} KB)")

if __name__ == "__main__":
    composite_og_image()
