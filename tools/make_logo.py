"""Draws the BlueShift logo for the CurseForge project page: a blue Battle.net notification that
has just been shifted (a fading trail of copies behind it) and a lock pinning it in place.
Drawn at four times the size and written as a 512x512 PNG. With a second path, the same logo
is also written as the in-game icon: 64x64 TGA (type 2, 32 bpp, bottom-left origin), the layout
the client's own addon icons use.

    python3 make_logo.py <PNG file> [<TGA file>]
"""
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 512
SS = 4
N = S * SS
OUT = sys.argv[1]
ICON = sys.argv[2] if len(sys.argv) > 2 else None

BLUE = (130, 197, 255)  # the light blue of the toast's top line
GREY = (124, 132, 137)
TOAST_FILL = (14, 22, 36)
GOLD = (240, 196, 72)
GOLD_DARK = (120, 84, 20)


def px(v):
    return v * SS


def rounded(draw, box, radius, **kwargs):
    draw.rounded_rectangle([px(c) for c in box], radius=px(radius), **kwargs)


# Background: deep navy with a blue glow behind the toast
yy, xx = np.mgrid[0:N, 0:N].astype(np.float32) / N
d = np.clip(np.sqrt((xx - 0.6) ** 2 + (yy - 0.47) ** 2) / 0.75, 0, 1)
inner = np.array([22, 52, 92], np.float32)
outer = np.array([4, 8, 16], np.float32)
bg = inner * (1 - d[..., None]) ** 1.8 + outer * (1 - (1 - d[..., None]) ** 1.8)
img = Image.fromarray(np.dstack([bg, np.full((N, N), 255, np.float32)]).astype(np.uint8), "RGBA")


def toast(layer_alpha, dx, dy, detail=True):
    """One notification card on its own layer, moved by dx, dy (logo pixels)."""
    layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    box = (140 + dx, 196 + dy, 452 + dx, 316 + dy)
    rounded(draw, box, 18, fill=TOAST_FILL + (255,), outline=BLUE + (255,), width=px(6))
    if detail:
        # Friend icon: a blue disc with a head and shoulders
        cx, cy = 196 + dx, 256 + dy
        draw.ellipse([px(cx - 34), px(cy - 34), px(cx + 34), px(cy + 34)], fill=(40, 96, 160, 255))
        draw.ellipse([px(cx - 12), px(cy - 24), px(cx + 12), px(cy)], fill=BLUE + (255,))
        draw.pieslice([px(cx - 26), px(cy + 2), px(cx + 26), px(cy + 50)], 180, 360, fill=BLUE + (255,))
        # Two lines of text
        rounded(draw, (250 + dx, 232 + dy, 420 + dx, 252 + dy), 10, fill=BLUE + (255,))
        rounded(draw, (250 + dx, 266 + dy, 370 + dx, 284 + dy), 9, fill=GREY + (255,))
    if layer_alpha < 1:
        a = layer.getchannel("A").point(lambda v: int(v * layer_alpha))
        layer.putalpha(a)
    return layer


# The trail: fading copies where the card came from (lower left)
for alpha, offset in ((0.14, -84), (0.3, -52), (0.5, -24)):
    img.alpha_composite(toast(alpha, offset, -offset * 0.55, detail=False))

# Soft glow under the card, then the card itself
glow = Image.new("RGBA", (N, N), (0, 0, 0, 0))
rounded(ImageDraw.Draw(glow), (134, 190, 458, 322), 22, fill=BLUE + (150,))
img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(px(14))))
img.alpha_composite(toast(1, 0, 0))

# Lock badge on the top right corner of the card
lock = Image.new("RGBA", (N, N), (0, 0, 0, 0))
draw = ImageDraw.Draw(lock)
cx, cy = 438, 190
draw.ellipse([px(cx - 50), px(cy - 50), px(cx + 50), px(cy + 50)], fill=(10, 16, 28, 255), outline=GOLD + (255,), width=px(6))
draw.arc([px(cx - 18), px(cy - 34), px(cx + 18), px(cy + 4)], 180, 360, fill=GOLD + (255,), width=px(8))
draw.line([px(cx - 18), px(cy - 15), px(cx - 18), px(cy - 2)], fill=GOLD + (255,), width=px(8))
draw.line([px(cx + 18), px(cy - 15), px(cx + 18), px(cy - 2)], fill=GOLD + (255,), width=px(8))
rounded(draw, (cx - 27, cy - 4, cx + 27, cy + 30), 6, fill=GOLD + (255,))
draw.ellipse([px(cx - 6), px(cy + 4), px(cx + 6), px(cy + 16)], fill=GOLD_DARK + (255,))
draw.rectangle([px(cx - 3), px(cy + 12), px(cx + 3), px(cy + 22)], fill=GOLD_DARK + (255,))
img.alpha_composite(lock)

logo = img.resize((S, S), Image.LANCZOS)
logo.convert("RGB").save(OUT)

if ICON:
    icon = img.resize((64, 64), Image.LANCZOS)
    rgba = np.asarray(icon.convert("RGBA"))
    header = struct.pack("<BBBHHBHHHHBB", 0, 0, 2, 0, 0, 0, 0, 0, 64, 64, 32, 8)
    rows = [rgba[y][:, [2, 1, 0, 3]].tobytes() for y in range(63, -1, -1)]
    with open(ICON, "wb") as f:
        f.write(header + b"".join(rows))
