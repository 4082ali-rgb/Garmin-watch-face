"""Turn your own copy of a logo into resources/drawables/logo.png for the watch face.

Usage: python3 tools/prepare_logo.py path/to/your_logo_or_screenshot.png [x0 y0 x1 y1]

- Optional crop box (pixels) if the image contains more than the logo.
- Near-black pixels become transparent (the face background is black anyway).
- Output is scaled to 183 px wide (44% of a 416 px screen, the epix Gen 2).
Requires Pillow (pip install pillow).
"""
import sys
from PIL import Image

src = Image.open(sys.argv[1]).convert("RGB")
if len(sys.argv) == 6:
    src = src.crop(tuple(int(v) for v in sys.argv[2:6]))

# Trim to the non-black bounding box.
bbox = src.point(lambda v: 255 if v > 60 else 0).convert("L").getbbox()
if bbox:
    src = src.crop(bbox)

w = 183
h = round(src.height * w / src.width)
src = src.resize((w, h), Image.LANCZOS)

out = Image.new("RGBA", src.size)
px, o = src.load(), out.load()
for y in range(h):
    for x in range(w):
        r, g, b = px[x, y]
        a = max(r, g, b)
        o[x, y] = (r, g, b, 0 if a < 40 else 255)
out.save("resources/drawables/logo.png")
print("wrote resources/drawables/logo.png", out.size, "(keep height <= ~65 px)")
