"""
Extract slides from ArenzaTV_Frictionless_Sports_Engagement.pdf.
The source PDF has already had the NotebookLM logo removed — we render
each page directly without any modifications.

Run from the repo root:
    python packages/dashboard/scripts/extract_frictionless_slides.py
"""

import pathlib
import fitz  # PyMuPDF

REPO_ROOT  = pathlib.Path(__file__).resolve().parent.parent.parent.parent
SLIDES_DIR = REPO_ROOT / "packages" / "dashboard" / "public" / "slides"
PDF_PATH   = SLIDES_DIR / "ArenzaTV_Frictionless_Sports_Engagement.pdf"
OUT_DIR    = SLIDES_DIR / "frictionless-sports-engagement"

DPI = 150


def extract_slides():
    if not PDF_PATH.exists():
        raise FileNotFoundError(f"PDF not found: {PDF_PATH}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(str(PDF_PATH))
    print(f"PDF has {len(doc)} pages. Extracting to {OUT_DIR} ...")

    mat = fitz.Matrix(DPI / 72, DPI / 72)

    for page_num, page in enumerate(doc):
        pix = page.get_pixmap(matrix=mat, alpha=False)
        out_path = OUT_DIR / f"p{page_num + 1}.png"
        pix.save(str(out_path))
        print(f"  Saved slide {page_num + 1}: {out_path.name}")

    print(f"\nDone! {len(doc)} slides written to {OUT_DIR}")
    return len(doc)


if __name__ == "__main__":
    n = extract_slides()
    print(f"\nExtracted {n} clean slides.")
