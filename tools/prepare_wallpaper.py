"""Turn your own wallpaper image into resources/drawables/wallpaper.png (416x416, epix Gen 2).

Usage: python3 tools/prepare_wallpaper.py your_image.jpg [focus_x focus_y] [dim]

- The image is cropped to a square around the focus point (fractions 0-1 of
  width/height, default 0.5 0.5), resized to 416x416 and darkened by `dim`
  (0 = untouched, default 0.35) so the time, logo and gauges stay readable.
Requires Pillow (pip install pillow).
"""
import sys
from PIL import Image, ImageEnhance

src = Image.open(sys.argv[1]).convert("RGB")
fx = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
fy = float(sys.argv[3]) if len(sys.argv) > 3 else 0.5
dim = float(sys.argv[4]) if len(sys.argv) > 4 else 0.35

side = min(src.size)
left = min(max(int(fx * src.width - side / 2), 0), src.width - side)
top = min(max(int(fy * src.height - side / 2), 0), src.height - side)
src = src.crop((left, top, left + side, top + side)).resize((416, 416), Image.LANCZOS)
src = ImageEnhance.Brightness(src).enhance(1 - dim)
src.save("resources/drawables/wallpaper.png")
print("wrote resources/drawables/wallpaper.png")
