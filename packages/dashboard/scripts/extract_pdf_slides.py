import fitz
import os

pdf_dir = "packages/dashboard/public/slides"

pdfs = {
    "CMXS_Infrastructure_Engine.pdf": "cmxs-infrastructure-engine",
    "The_35_Second_Engine.pdf": "the-35-second-engine",
    "Verified_Broadcast_Blueprint.pdf": "verified-broadcast-blueprint",
    "CMXS_Verified_Media_Infrastructure.pdf": "cmxs-verified-media-infrastructure",
}

for pdf_file, out_folder in pdfs.items():
    pdf_path = os.path.join(pdf_dir, pdf_file)
    out_dir = os.path.join(pdf_dir, out_folder)
    os.makedirs(out_dir, exist_ok=True)
    
    if os.path.exists(pdf_path):
        print(f"Extracting {pdf_file} to {out_folder}...")
        doc = fitz.open(pdf_path)
        for i, page in enumerate(doc):
            pix = page.get_pixmap(dpi=150)
            img_path = os.path.join(out_dir, f"p{i+1}.png")
            pix.save(img_path)
        print(f"Done extracting {len(doc)} pages.")
    else:
        print(f"File not found: {pdf_path}")
