"""The card back (0.19), 75 by 105 pixels (a card in the hand, at 2 to a
pixel): a dark plate in a cyan hex frame, and the KETER emblem in its middle.

The emblem is an upside-down crown, modelled and lit as the tokens are: a slab
of the colony's surface, seen a little from above, its towers lit along the
top and a cyan rim; and under it the spires of uneven length that go down to
points, the underground labs, their windows lit red.

    python3 cardback.py [out.png]      # the back at 4x, the emblem, and the back at its size
"""
import math
import numpy as np
from PIL import Image, ImageDraw
from kart import idx, rgb, make, cylinder, cone, sphere, box, rot_y
import rigs  # noqa: F401  (its materials: concrete)

W, H = 75, 105

OUT = "0e0c0c"
PLATE, PLATE2 = "14121d", "171819"
CY, CY2 = "73efe8", "406977"

# the emblem: drawn this size, the slab's middle at (30, 10)
TW, TH = 60, 66
# each spire: (angle round the slab in degrees, distance from its middle, length below it), uneven as the labs go down
DOWN = [(200, 15, 30), (235, 14, 44), (270, 13, 24), (305, 14, 50), (340, 15, 28), (20, 14, 36), (60, 13, 20), (110, 13, 32),
        (150, 14, 22), (0, 0, 40)]
# the surface's towers: (x, z, height)
TOWERS = [(-6, -4, 7), (2, -6, 10), (7, 2, 5), (-2, 4, 4), (-10, 3, 3), (10, -5, 6)]


def emblem():
    """The upside-down crown: the colony's surface over its labs."""
    S = []
    for k in range(6):                                           # a hexagonal slab
        S.append(box((0, 0, 0), (9.6, 2.0, 16.6), "steel", r=0.6, R=rot_y(k * math.pi / 3)))
    S.append(cylinder((0, 1.9, 0), (0, 2.5, 0), 19.4, "glow_cyan", 0.3))
    S.append(cylinder((0, 2.0, 0), (0, 2.8, 0), 18.2, "steel", 0.3))
    for ang, dist, ln in DOWN:
        x, z = dist * math.cos(math.radians(ang)), -dist * math.sin(math.radians(ang))
        S.append(cone((x, -1.5, z), (x, -1.5 - ln, z), 4.2 if ln > 35 else 3.5, 0.15, "onyx"))
        S.append(cone((x, -1.5 - ln * 0.86, z), (x, -1.5 - ln, z), 0.8, 0.1, "glow_red"))
        for k in range(1, int(ln / 14) + 1):
            S.append(sphere((x + 0.8, -1.5 - k * 12, z + 3.4 * (1 - k * 12 / ln)), 0.8, "glow_red"))
    for (x, z, h) in TOWERS:
        S.append(box((x, 2.4 + h / 2, z), (1.6, h / 2, 1.6), "concrete", r=0.3))
        S.append(sphere((x + 1.7, 2.4 + h * 0.7, z), 0.5, "glow_cyan"))
    return make(S, size=(TW, TH), foot=(30, 10), pitch=18, yaw=25, scale=1.0, inner_step=1.4)


class Canvas:
    """A grid of palette indices, drawn on with PIL's pixel-exact shapes."""
    def __init__(self, w, h):
        self.a = np.zeros((h, w), np.int32)
        self.w, self.h = w, h

    def _mask(self, fn):
        m = Image.new("1", (self.w, self.h), 0)
        fn(ImageDraw.Draw(m))
        return np.array(m, bool)

    def poly(self, pts, c):
        self.a[self._mask(lambda d: d.polygon([tuple(p) for p in pts], fill=1))] = idx(c)

    def line(self, pts, c, w=1):
        self.a[self._mask(lambda d: d.line([tuple(p) for p in pts], fill=1, width=w))] = idx(c)

    def rect(self, x0, y0, x1, y1, c):
        self.a[y0:y1 + 1, x0:x1 + 1] = idx(c)

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.a[y, x] = idx(c)


def hexagon(cx, cy, r):
    return [(cx + r * math.cos(math.radians(60 * i - 30)), cy + r * math.sin(math.radians(60 * i - 30))) for i in range(6)]


def back():
    """The card back: a dark plate in a cyan frame, a hex in its middle, the emblem over it."""
    c = Canvas(W, H)
    c.rect(0, 0, W - 1, H - 1, PLATE)
    # a faint hex lattice on the plate
    for row in range(-1, 9):
        for col in range(-1, 7):
            pts = hexagon(6 + col * 13 + (6 if row % 2 else 0), 6 + row * 12, 6)
            c.line(pts + [pts[0]], PLATE2, 1)
    # the edge: dark, then a cyan line
    c.rect(0, 0, W - 1, 1, OUT); c.rect(0, H - 2, W - 1, H - 1, OUT)
    c.rect(0, 0, 1, H - 1, OUT); c.rect(W - 2, 0, W - 1, H - 1, OUT)
    c.rect(2, 2, W - 3, 2, CY2); c.rect(2, H - 3, W - 3, H - 3, CY2)
    c.rect(2, 2, 2, H - 3, CY2); c.rect(W - 3, 2, W - 3, H - 3, CY2)
    # the hex frame round the middle
    big = hexagon(W // 2, H // 2, 35)
    c.poly(big, CY2)
    c.poly(hexagon(W // 2, H // 2, 33), OUT)
    c.poly(hexagon(W // 2, H // 2, 32), PLATE2)
    c.line(big + [big[0]], CY, 1)
    # the emblem, centred on what it covers
    em = emblem()
    ys, xs = np.nonzero(em)
    em = em[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    eh, ew = em.shape
    x0, y0 = (W - ew) // 2, (H - eh) // 2
    on = em > 0
    c.a[y0:y0 + eh, x0:x0 + ew][on] = em[on]
    for (x, y) in ((6, 6), (W - 7, 6), (6, H - 7), (W - 7, H - 7)):
        c.px(x, y, CY)
    return c.a


def rgba(a):
    im = Image.new("RGBA", (a.shape[1], a.shape[0]), (0, 0, 0, 0))
    p = im.load()
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            if a[y, x]:
                p[x, y] = rgb(int(a[y, x])) + (255,)
    return im


if __name__ == "__main__":
    import sys
    out = sys.argv[1] if len(sys.argv) > 1 else "out/card_back.png"
    k, gap = 4, 16
    b, e = rgba(back()), rgba(emblem())
    sheet = Image.new("RGBA", (W * k + TW * 3 + W + gap * 4, H * k + gap * 2), (44, 52, 56, 255))
    sheet.alpha_composite(b.resize((W * k, H * k), Image.NEAREST), (gap, gap))
    sheet.alpha_composite(e.resize((TW * 3, TH * 3), Image.NEAREST), (W * k + gap * 2, gap))
    sheet.alpha_composite(b, (W * k + TW * 3 + gap * 3, gap))
    sheet.save(out)
    print(out, sheet.size)
