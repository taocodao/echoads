"""
Extract slides from ArenzaTV_Frictionless_Sports_Engagement.pdf.
Removes the NotebookLM logo watermark from the bottom-right corner by
sampling the actual background color at that location and painting over it.
Works correctly on both dark and white slide backgrounds.

Run from the repo root:
    python packages/dashboard/scripts/extract_frictionless_slides.py
"""

import io
import pathlib

import fitz       # PyMuPDF
from PIL import Image

REPO_ROOT  = pathlib.Path(__file__).resolve().parent.parent.parent.parent
SLIDES_DIR = REPO_ROOT / "packages" / "dashboard" / "public" / "slides"
PDF_PATH   = SLIDES_DIR / "ArenzaTV_Frictionless_Sports_Engagement.pdf"
OUT_DIR    = SLIDES_DIR / "frictionless-sports-engagement"

DPI = 150  # render resolution

# The NotebookLM logo occupies roughly the bottom-right corner.
# These fractions define the logo bounding box in page-coordinate space.
LOGO_X_FRAC = 0.88   # logo starts at 88% of page width
LOGO_Y_FRAC = 0.935  # logo starts at 93.5% of page height

# How many pixels ABOVE the logo region to sample the background color from.
# We look at a 4×4 pixel patch just above the logo and use its median color.
SAMPLE_OFFSET_PX = 6


def median_color(img: Image.Image, x: int, y: int, size: int = 4) -> tuple[int, int, int]:
    """Sample a small patch and return the median RGB as the background color."""
    patch = img.crop((x, y, x + size, y + size))
    pixels = list(patch.getdata())
    r = sorted(p[0] for p in pixels)[len(pixels) // 2]
    g = sorted(p[1] for p in pixels)[len(pixels) // 2]
    b = sorted(p[2] for p in pixels)[len(pixels) // 2]
    return (r, g, b)


def extract_slides():
    if not PDF_PATH.exists():
        raise FileNotFoundError(f"PDF not found: {PDF_PATH}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(str(PDF_PATH))
    print(f"PDF has {len(doc)} pages. Extracting to {OUT_DIR} ...")

    mat = fitz.Matrix(DPI / 72, DPI / 72)

    for page_num, page in enumerate(doc):
        # Render the full page to a PIL image first
        pix = page.get_pixmap(matrix=mat, alpha=False)
        img = Image.open(io.BytesIO(pix.tobytes("png")))
        img = img.convert("RGB")

        w, h = img.size

        # Logo bounding box in pixel coordinates
        logo_x0 = int(w * LOGO_X_FRAC)
        logo_y0 = int(h * LOGO_Y_FRAC)

        # Sample background color from a small patch just ABOVE the logo
        sample_y = max(0, logo_y0 - SAMPLE_OFFSET_PX)
        sample_x = max(0, logo_x0)
        bg_color = median_color(img, sample_x, sample_y)

        # Paint a filled rectangle over the logo using the sampled bg color
        from PIL import ImageDraw
        draw = ImageDraw.Draw(img)
        draw.rectangle([logo_x0, logo_y0, w, h], fill=bg_color)

        out_path = OUT_DIR / f"p{page_num + 1}.png"
        img.save(str(out_path), "PNG", optimize=True)
        print(f"  Slide {page_num + 1}: logo erased with sampled color {bg_color}  -> {out_path.name}")

    print(f"\nDone! {len(doc)} slides written to {OUT_DIR}")
    return len(doc)


if __name__ == "__main__":
    n = extract_slides()
    print(f"\nExtracted {n} slides. All NotebookLM logos removed.")
