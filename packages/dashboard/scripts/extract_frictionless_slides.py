"""
Extract slides from ArenzaTV_Frictionless_Sports_Engagement.pdf.
Crops the bottom-right corner to remove the NotebookLM logo watermark.
Run from the repo root:
    python packages/dashboard/scripts/extract_frictionless_slides.py
"""

import os
import pathlib
import fitz  # PyMuPDF

REPO_ROOT  = pathlib.Path(__file__).resolve().parent.parent.parent.parent
SLIDES_DIR = REPO_ROOT / "packages" / "dashboard" / "public" / "slides"
PDF_PATH   = SLIDES_DIR / "ArenzaTV_Frictionless_Sports_Engagement.pdf"
OUT_DIR    = SLIDES_DIR / "frictionless-sports-engagement"

DPI = 150  # render resolution

# NotebookLM logo sits roughly in the bottom-right corner.
# We cover it by painting a solid black rectangle over that region
# BEFORE rendering, so the final PNG is clean.
# The logo occupies roughly the bottom ~6% of height and right ~12% of width.
LOGO_CROP_FRAC_X = 0.88   # start cropping at this fraction of page width
LOGO_CROP_FRAC_Y = 0.935  # start cropping at this fraction of page height


def extract_slides():
    if not PDF_PATH.exists():
        raise FileNotFoundError(f"PDF not found: {PDF_PATH}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(str(PDF_PATH))
    print(f"PDF has {len(doc)} pages. Extracting to {OUT_DIR} ...")

    for page_num, page in enumerate(doc):
        pw = page.rect.width
        ph = page.rect.height

        # Build a rectangle covering the NotebookLM logo region
        logo_rect = fitz.Rect(
            pw * LOGO_CROP_FRAC_X,   # x0
            ph * LOGO_CROP_FRAC_Y,   # y0
            pw,                        # x1 (full width)
            ph,                        # y1 (full height)
        )

        # Draw a filled rectangle in the page's background color (black/dark)
        # using an annotation shape so it renders on top of the logo
        shape = page.new_shape()
        shape.draw_rect(logo_rect)
        # Use the dominant dark background color of these slides
        shape.finish(fill=(0.04, 0.04, 0.08), color=None, width=0)
        shape.commit()

        mat = fitz.Matrix(DPI / 72, DPI / 72)
        pix = page.get_pixmap(matrix=mat, alpha=False)
        out_path = OUT_DIR / f"p{page_num + 1}.png"
        pix.save(str(out_path))
        print(f"  Saved slide {page_num + 1}: {out_path.name}")

    print(f"\nDone! {len(doc)} slides written to {OUT_DIR}")
    return len(doc)


if __name__ == "__main__":
    n = extract_slides()
    print(f"\nExtracted {n} slides. Update page.tsx to use Array.from({{ length: {n} }}, ...).")
