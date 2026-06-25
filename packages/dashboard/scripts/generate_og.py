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
    bg_color = (10, 10, 12) # very dark
    
    # Create background
    img = Image.new('RGB', (width, height), color=bg_color)
    draw = ImageDraw.Draw(img)
    
    # Subtle background element
    draw.ellipse((-200, -200, 400, 400), outline=(25, 25, 30), width=10)
    draw.ellipse((800, 300, 1500, 1000), outline=(20, 20, 25), width=15)
    
    # Load and resize logo
    try:
        logo = Image.open(logo_path).convert("RGBA")
        logo_w, logo_h = logo.size
        aspect = logo_w / logo_h
        
        # Increase logo size a bit
        new_logo_h = 240
        new_logo_w = int(new_logo_h * aspect)
        logo = logo.resize((new_logo_w, new_logo_h), Image.Resampling.LANCZOS)
        
        # Center logo vertically shifted up more
        logo_x = (width - new_logo_w) // 2
        logo_y = (height - new_logo_h) // 2 - 60
        
        # Paste logo using alpha channel as mask
        img.paste(logo, (logo_x, logo_y), logo)
    except Exception as e:
        print(f"Error loading logo: {e}")
        logo_y = height // 2 - 120
        new_logo_h = 240

    # Add text
    text = "Gamified Sports FAST Ads for Local Commerce"
    
    # Try absolute paths for Windows fonts to ensure they load
    font_paths = [
        r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
        r"C:\Windows\Fonts\trebucbd.ttf",
        r"C:\Windows\Fonts\tahoma.ttf",
        "arialbd.ttf"
    ]
    
    font = None
    # Use a large size for maximum clarity
    font_size = 64
    for path in font_paths:
        try:
            font = ImageFont.truetype(path, font_size)
            print(f"Successfully loaded font: {path}")
            break
        except:
            continue
            
    if font is None:
        print("Warning: Could not load any TrueType font. Falling back to default.")
        font = ImageFont.load_default()
        
    try:
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
    except AttributeError:
        # For older Pillow versions
        text_w, text_h = draw.textsize(text, font=font)
    
    text_x = (width - text_w) // 2
    # Ensure there is enough padding below logo
    text_y = logo_y + new_logo_h + 50
        
    # Draw text in crisp white
    draw.text((text_x, text_y), text, fill=(255, 255, 255), font=font)
    
    # Save optimized JPG with highest quality
    img.save(out_path, format="JPEG", quality=100, optimize=True)
    
    print(f"Saved {out_path} ({os.path.getsize(out_path)} bytes)")

if __name__ == "__main__":
    generate_og_image()
