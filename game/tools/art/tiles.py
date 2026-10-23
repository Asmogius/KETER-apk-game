"""The fight's floor, drawn flat: hex tiles 42 x 48 (one art pixel = 2 world
units; the board's columns are 42 pixels apart, rows 36), spawn pads and
hazards. A pixel belongs to a tile when its centre is inside the hexagon, so
tiles laid side by side meet without gaps or overlaps."""
import math, random
import numpy as np
from kart import idx, to_png, sheet, preview_path

W, H = 42, 48
CORNERS = [(21, -12), (21, 12), (0, 24), (-21, 12), (-21, -12), (0, -24)]


def inside(px, py, k=1.0):
    """Is the point (relative to the centre) inside the hexagon scaled by k?"""
    # pointy-top hex with half width 21k, top 24k, side 12k
    ax, ay = abs(px), abs(py)
    if ax > 21 * k:
        return False
    return ay <= 24 * k - ax * (12.0 / 21.0)


def mask(k=1.0):
    m = np.zeros((H, W), bool)
    for j in range(H):
        for i in range(W):
            m[j, i] = inside(i + 0.5 - 21, j + 0.5 - 24, k)
    return m


MASK = mask()


def edge_of(m):
    """Pixels of the mask that touch the outside, split into upper-left and the rest."""
    ul = np.zeros_like(m)
    rest = np.zeros_like(m)
    for j in range(H):
        for i in range(W):
            if not m[j, i]:
                continue
            out = [(dx, dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                   if not (0 <= i + dx < W and 0 <= j + dy < H and m[j + dy, i + dx])]
            if out:
                if any(d in ((-1, 0), (0, -1)) for d in out):
                    ul[j, i] = True
                else:
                    rest[j, i] = True
    return ul, rest


UL, LR = edge_of(MASK)


def base(fill="2c3438", lite="465456", dark="14121d"):
    a = np.zeros((H, W), np.int32)
    a[MASK] = idx(fill)
    a[UL] = idx(lite)
    a[LR] = idx(dark)
    return a


def px(a, x, y, c):
    if 0 <= x < W and 0 <= y < H and MASK[y, x]:
        a[y, x] = idx(c)


def hline(a, x0, x1, y, c):
    for x in range(x0, x1 + 1):
        px(a, x, y, c)


def disc(a, cx, cy, rx, ry, c, ring=False):
    for j in range(H):
        for i in range(W):
            d = ((i + 0.5 - cx) / rx) ** 2 + ((j + 0.5 - cy) / ry) ** 2
            if (d <= 1.0 and not ring) or (ring and 0.62 <= d <= 1.0):
                px(a, i, j, c)


# ---------------------------------------------------------------- floor plates
def plate_bolts():
    a = base()
    for x, y in ((9, 16), (32, 16), (9, 31), (32, 31)):
        px(a, x, y, "6a7178"); px(a, x + 1, y + 1, "14121d"); px(a, x + 1, y, "3e4246")
    hline(a, 6, 35, 24, "171819")
    hline(a, 6, 35, 25, "3e4246")
    return a


def plate_grate():
    a = base(fill="282c3c", lite="465456")
    for y in range(14, 35, 3):
        hline(a, 10, 31, y, "14121d")
        hline(a, 10, 31, y + 1, "3e4246")
    return a


def plate_seam():
    a = base(fill="2c3438")
    for k in range(-12, 13):
        px(a, 21 + k, 24 + k // 2, "171819")
        px(a, 21 + k, 25 + k // 2, "465456")
    for x, y in ((14, 14), (28, 34)):
        px(a, x, y, "6a7178"); px(a, x + 1, y + 1, "14121d")
    return a


def plate_vent():
    a = base(fill="2c3438")
    disc(a, 21, 24, 9, 8, "171819")
    disc(a, 21, 24, 9, 8, "465456", ring=True)
    for k in (-4, 0, 4):
        hline(a, 15, 27, 24 + k, "14121d")
    return a


def plate_trench():
    a = base(fill="282c3c")
    for y in range(20, 29):
        hline(a, 2, 39, y, "171516" if 21 <= y <= 27 else "3e4246")
    for x in range(2, 40):
        px(a, x, 24 + (1 if (x // 5) % 2 else 0), "d1751c" if False else "b47538")
    return a


FLOORS = {"floor_bolts": plate_bolts, "floor_grate": plate_grate, "floor_seam": plate_seam, "floor_vent": plate_vent, "floor_trench": plate_trench}


# ---------------------------------------------------------------- spawn pads (team colours)
def pad(lit, dim):
    a = np.zeros((H, W), np.int32)
    m1, m2, m3 = mask(0.78), mask(0.64), mask(0.56)
    a[m1] = idx("14121d")
    ring = m2 & ~m3
    a[ring] = idx(lit)
    a[m1 & ~mask(0.72)] = idx(dim)
    for k in (-1, 1):                                            # chevrons pointing in
        for t in range(-4, 5):
            px(a, 21 + t, 24 + k * (4 - abs(t) // 2) - (0 if k > 0 else 1), dim)
    px(a, 21, 24, lit); px(a, 20, 24, lit); px(a, 21, 23, lit); px(a, 20, 23, lit)
    return a


PADS = {"pad_yours": lambda: pad("73efe8", "2b4e95"), "pad_theirs": lambda: pad("ff2a3c", "7e0e0e")}


# ---------------------------------------------------------------- hazards (decals over a floor plate)
def acid():
    a = np.zeros((H, W), np.int32)
    disc(a, 21, 25, 15, 11, "27412d")
    disc(a, 20, 24, 14, 10, "42a459")
    disc(a, 19, 23, 10, 7, "59cf93")
    for cx, cy in ((14, 21), (26, 27), (28, 19)):
        disc(a, cx, cy, 2.2, 2.0, "97edca", ring=True)
    px(a, 12, 19, "d0ffea"); px(a, 13, 19, "d0ffea")
    return a


def sparks():
    a = np.zeros((H, W), np.int32)
    rnd = random.Random(7)
    # two cables across the tile, cut, sparking
    for y0, col, lit in ((19, "1b2447", "2b4e95"), (29, "36282b", "64364b")):
        for x in range(3, 39):
            y = y0 + int(2 * math.sin(x / 5.0))
            px(a, x, y, col); px(a, x, y - 1, lit)
    for cx, cy in ((21, 20), (17, 29)):
        for k in range(8):
            t = k * math.pi / 4 + rnd.random() * 0.4
            for r in range(1, 4 + k % 3):
                px(a, int(cx + math.cos(t) * r), int(cy + math.sin(t) * r * 0.8), "f0ff2a" if r < 3 else "2f7bff")
        px(a, cx, cy, "f1f2ff")
    return a


def razor():
    a = np.zeros((H, W), np.int32)
    for k in range(5):                                            # coils of wire
        cx = 7 + k * 7
        for t in range(0, 360, 15):
            r = math.radians(t)
            px(a, int(cx + 4 * math.cos(r)), int(24 + 6 * math.sin(r)), "cbc6c1" if t < 180 else "807b7a")
    for x, y in ((9, 20), (16, 27), (23, 19), (30, 28)):
        px(a, x, y, "f1f2ff")
    for x, y in ((12, 30), (26, 31), (19, 18)):                   # a little blood on the barbs
        px(a, x, y, "b81418"); px(a, x + 1, y, "7e0e0e")
    return a


def sludge():
    a = np.zeros((H, W), np.int32)
    disc(a, 21, 25, 16, 11, "14121d")
    disc(a, 20, 24, 14, 9, "322f35")
    for cx, cy, rx in ((17, 22, 5), (25, 27, 4)):
        disc(a, cx, cy, rx, 2.2, "564f5b", ring=True)
    for x in range(14, 20):
        px(a, x, 21, "8a3dff" if x % 2 else "c23bff")             # an oily sheen
    px(a, 26, 26, "6dff3a"); px(a, 27, 26, "8a3dff")
    return a


def fire():
    a = np.zeros((H, W), np.int32)
    for y in range(16, 33, 4):                                    # a grate
        hline(a, 8, 33, y, "171516")
    rnd = random.Random(3)
    for cx in (12, 20, 28):
        hgt = 9 + rnd.randint(0, 4)
        for j in range(hgt):
            w = max(1, int((hgt - j) / 2.2))
            col = "ff7a1a" if j < hgt * 0.5 else "f8c53a" if j < hgt * 0.8 else "fff089"
            if j < 2:
                col = "b9451d"
            for i in range(-w, w + 1):
                px(a, cx + i + (1 if j > hgt * 0.6 else 0), 31 - j, col)
    return a


HAZARDS = {"hazard_acid": acid, "hazard_sparks": sparks, "hazard_razor": razor, "hazard_sludge": sludge, "hazard_fire": fire}

ALL = {}
ALL.update(FLOORS)
ALL.update(PADS)
ALL.update(HAZARDS)

if __name__ == "__main__":
    names = list(ALL)
    imgs = []
    for n in names:
        a = ALL[n]()
        if n.startswith("hazard") or n.startswith("pad"):
            b = plate_bolts()
            b[a > 0] = a[a > 0]
            a = b
        imgs.append(a)
    sheet(imgs, preview_path("tiles.png"), scale=4, labels=names, cols=6, show1x=False)
