import os
from PIL import Image, ImageDraw, ImageFont

def generate_og_image():
    # Set paths
    base_dir = r"d:\Projects\echoads\packages\dashboard"
    assets_dir = os.path.join(base_dir, "public", "assets")
    os.makedirs(assets_dir, exist_ok=True)
    out_path = os.path.join(assets_dir, "og-preview.jpg")
    
    logo_path = os.path.join(base_dir, "public", "arenza-logo-real.png")
    if not os.path.exists(logo_path):
        logo_path = os.path.join(base_dir, "public", "arenza-logo.png")
    
    # Image specs
    width = 1200
    height = 627
    bg_color = (13, 13, 13) # #0d0d0d
    
    # Create background
    img = Image.new('RGB', (width, height), color=bg_color)
    draw = ImageDraw.Draw(img)
    
    # Subtle background element
    draw.ellipse((-200, -200, 400, 400), outline=(30, 30, 30), width=10)
    draw.ellipse((800, 300, 1500, 1000), outline=(20, 20, 40), width=15)
    
    # Load and resize logo
    logo_y = height // 2 - 100
    new_logo_h = 200
    try:
        logo = Image.open(logo_path).convert("RGBA")
        logo_w, logo_h = logo.size
        aspect = logo_w / logo_h
        new_logo_h = 200
        new_logo_w = int(new_logo_h * aspect)
        logo = logo.resize((new_logo_w, new_logo_h), Image.Resampling.LANCZOS)
        
        # Center logo
        logo_x = (width - new_logo_w) // 2
        logo_y = (height - new_logo_h) // 2 - 50
        
        # Paste logo using alpha channel as mask
        img.paste(logo, (logo_x, logo_y), logo)
    except Exception as e:
        print(f"Error loading logo: {e}")

    # Add text
    text = "Gamified Sports FAST Ads for Local Commerce"
    try:
        font = ImageFont.truetype("segoeui.ttf", 36)
    except:
        try:
            font = ImageFont.truetype("arialbd.ttf", 36)
        except:
            font = ImageFont.load_default()
        
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
    except AttributeError:
        # For older Pillow versions
        text_w, text_h = draw.textsize(text, font=font)
    
    text_x = (width - text_w) // 2
    text_y = logo_y + new_logo_h + 60
        
    draw.text((text_x, text_y), text, fill=(230, 230, 230), font=font)
    
    # Save optimized JPG
    img.save(out_path, format="JPEG", quality=85, optimize=True)
    
    print(f"Saved {out_path} ({os.path.getsize(out_path)} bytes)")

if __name__ == "__main__":
    generate_og_image()
