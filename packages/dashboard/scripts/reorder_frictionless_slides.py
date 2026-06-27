"""
Reorder frictionless-sports-engagement slide PNGs so that display slot N
matches narration index N (i.e., the already-generated audio).

New display order vs. current PDF page numbers:
  Display 1  <- PDF p1   (Title)
  Display 2  <- PDF p3   (Five Colliding Market Forces)
  Display 3  <- PDF p2   (Collapse of RSNs)
  Display 4  <- PDF p4   (Local Businesses Locked Out)
  Display 5  <- PDF p8   (Eliminating the Hardware Barrier: QR Hub)
  Display 6  <- PDF p6   (Second-Screen Gamification)
  Display 7  <- PDF p5   (B2B2C Ecosystem)
  Display 8  <- PDF p9   (Generational Infrastructure Moat: DePIN)
  Display 9  <- PDF p7   (Frictionless Attribution Loop)
  Display 10 <- PDF p11  (Stacked Revenue Streams)
  Display 11 <- PDF p12  (Fragmented FAST Landscape)
  Display 12 <- PDF p13  (Proactive Mitigations)
  Display 13 <- PDF p10  (Multi-Billion Dollar Disruption)
  Display 14 <- PDF p14  (Closing)

Run from repo root:
    python packages/dashboard/scripts/reorder_frictionless_slides.py
"""

import pathlib, shutil

SLIDES_DIR = (
    pathlib.Path(__file__).resolve().parent.parent
    / "public" / "slides" / "frictionless-sports-engagement"
)

# display slot (1-indexed) -> current PDF page number
NEW_ORDER = [1, 3, 2, 4, 8, 6, 5, 9, 7, 11, 12, 13, 10, 14]

def reorder():
    # Step 1: copy all existing files to tmp_<n>.png
    print("Step 1: copying to temp files …")
    for n in range(1, 15):
        src = SLIDES_DIR / f"p{n}.png"
        dst = SLIDES_DIR / f"tmp_{n}.png"
        shutil.copy2(src, dst)
        print(f"  p{n}.png -> tmp_{n}.png")

    # Step 2: copy tmp_<pdf_page>.png -> p<display_slot>.png
    print("\nStep 2: writing display-order files …")
    for display_slot, pdf_page in enumerate(NEW_ORDER, start=1):
        src = SLIDES_DIR / f"tmp_{pdf_page}.png"
        dst = SLIDES_DIR / f"p{display_slot}.png"
        shutil.copy2(src, dst)
        print(f"  tmp_{pdf_page}.png -> p{display_slot}.png")

    # Step 3: remove temp files
    print("\nStep 3: cleaning up temp files …")
    for n in range(1, 15):
        (SLIDES_DIR / f"tmp_{n}.png").unlink()
        print(f"  removed tmp_{n}.png")

    print("\nDone! Slides reordered to match narration audio.")

if __name__ == "__main__":
    reorder()
