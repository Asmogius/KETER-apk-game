"""The fight's effects (0.16), drawn frame by frame on the Pixel Studio's
palette, each in its own colours (the side's colour stays on the shot):

  flash      a muzzle flash at the shooter            24 x 24, 4 frames
  impact     where damage lands                       32 x 32, 5 frames
  explosion  on every tile a blast catches            48 x 48, 8 frames
  heal       rising from whoever is mended            32 x 48, 6 frames
  shield     flaring when an attack glances off       48 x 48, 6 frames

Each is a list of frames, each frame an (h, w) array of palette indices (0 is
clear). FPS says how fast each plays at Normal speed; ANCHOR where it sits
(its pixel over the point it is drawn at: the shooter's muzzle, the point
struck, a tile's middle, a Unit's feet, a Unit's middle)."""
import math, random
import numpy as np
from kart import idx

SIZE = {"flash": (24, 24), "impact": (32, 32), "explosion": (48, 48), "heal": (32, 48), "shield": (48, 48)}
FPS = {"flash": 20, "impact": 16, "explosion": 14, "heal": 12, "shield": 14}
ANCHOR = {"flash": (12, 12), "impact": (16, 16), "explosion": (24, 28), "heal": (16, 44), "shield": (24, 26)}
NAMES = ["flash", "impact", "explosion", "heal", "shield"]
# (0.18) the fight's atmosphere: small motes that drift over the board, each looping its frames
SIZE.update({"ember": (8, 8), "spark": (12, 12), "dust": (6, 6), "ash": (8, 8)})
FPS.update({"ember": 8, "spark": 16, "dust": 3, "ash": 4})
ANCHOR.update({"ember": (4, 4), "spark": (6, 6), "dust": (3, 3), "ash": (4, 4)})
ATMOS = ["ember", "spark", "ash", "dust"]


# ---------------------------------------------------------------- drawing on a frame
def blank(name):
    w, h = SIZE[name]
    return np.zeros((h, w), dtype=np.int32)


def put(a, x, y, c):
    x, y = int(round(x)), int(round(y))
    if 0 <= y < a.shape[0] and 0 <= x < a.shape[1]:
        a[y, x] = idx(c) if isinstance(c, str) else c


def disc(a, cx, cy, r, c, squash=1.0):
    """Every pixel whose middle is within r of (cx, cy) (squash < 1: an ellipse, flatter)."""
    v = idx(c) if isinstance(c, str) else c
    H, W = a.shape
    ys, xs = np.mgrid[0:H, 0:W]
    m = ((xs + 0.5 - cx) ** 2 + ((ys + 0.5 - cy) / squash) ** 2) <= r * r
    a[m] = v


def blob(a, cx, cy, r, c, rng, rough=0.22, squash=1.0):
    """A disc with a ragged edge: fire and smoke."""
    v = idx(c) if isinstance(c, str) else c
    H, W = a.shape
    k = [rng.uniform(-rough, rough) for _ in range(7)]
    ph = [rng.uniform(0, math.tau) for _ in range(7)]
    for y in range(H):
        for x in range(W):
            dx, dy = x + 0.5 - cx, (y + 0.5 - cy) / squash
            d = math.hypot(dx, dy)
            if d > r * (1 + rough) + 1:
                continue
            t = math.atan2(dy, dx)
            rr = r * (1 + sum(k[i] * math.sin((i + 2) * t + ph[i]) for i in range(len(k))) / 2.2)
            if d <= rr:
                a[y, x] = v


def ring(a, cx, cy, r, c, width=1.0, squash=1.0, gaps=0, rng=None, phase=0.0):
    """A circle's edge, `width` pixels thick; with gaps, broken into that many pieces."""
    v = idx(c) if isinstance(c, str) else c
    H, W = a.shape
    for y in range(H):
        for x in range(W):
            dx, dy = x + 0.5 - cx, (y + 0.5 - cy) / squash
            d = math.hypot(dx, dy)
            if r - width / 2 <= d <= r + width / 2:
                if gaps:
                    t = (math.atan2(dy, dx) + phase) % math.tau
                    if (t / math.tau * gaps * 2) % 2 > 1.25:
                        continue
                a[y, x] = v


def ellipse_edge(a, cx, cy, rx, ry, c, skip=None):
    """An ellipse's edge, one pixel wide (skip(angle) -> True leaves a gap)."""
    seen = set()
    for i in range(720):
        t = math.tau * i / 720
        if skip and skip(t):
            continue
        p = (int(math.floor(cx + math.cos(t) * rx)), int(math.floor(cy + math.sin(t) * ry)))
        if p not in seen:
            seen.add(p)
            put(a, p[0], p[1], c)


def line(a, x0, y0, x1, y1, c):
    n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
    for i in range(n + 1):
        t = i / max(1, n)
        put(a, x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, c)


def ray(a, cx, cy, ang, r0, r1, c, tip=None, width=1):
    """A ray from r0 to r1 out of (cx, cy); its last pixels in `tip`."""
    for i in range(int(r0 * 2), int(r1 * 2) + 1):
        d = i / 2
        x, y = cx + math.cos(ang) * d - 0.5, cy + math.sin(ang) * d - 0.5
        col = tip if (tip and d > r1 - 2) else c
        put(a, x, y, col)
        if width > 1 and d < r1 - 2:
            put(a, x + math.sin(ang) * 0.9, y - math.cos(ang) * 0.9, col)


def plus(a, cx, cy, c, core, edge, size=2):
    """A plus sign, `size` pixels from its middle to each end, with a dark rim."""
    for dx in range(-size - 1, size + 2):
        for dy in range(-1 - 1, 2):
            pass
    pts = [(cx + d, cy) for d in range(-size, size + 1)] + [(cx, cy + d) for d in range(-size, size + 1) if d]
    rim = set()
    for (x, y) in pts:
        for ox, oy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            rim.add((x + ox, y + oy))
    for p in rim - set(pts):
        if 0 <= p[1] < a.shape[0] and 0 <= p[0] < a.shape[1] and a[p[1], p[0]] == 0:
            put(a, p[0], p[1], edge)
    for (x, y) in pts:
        put(a, x, y, c)
    put(a, cx, cy, core)


def hexagon(cx, cy, r):
    """A pointy-top hexagon's corners, as the board's tiles."""
    return [(cx + r * math.cos(math.radians(60 * i - 30)), cy + r * math.sin(math.radians(60 * i - 30))) for i in range(6)]


def hex_edge(a, cx, cy, r, c, dash=0, phase=0, squash=1.0):
    pts = hexagon(cx, cy, r)
    k = 0
    for i in range(6):
        x0, y0 = pts[i]
        x1, y1 = pts[(i + 1) % 6]
        n = int(max(abs(x1 - x0), abs(y1 - y0) * squash)) + 1
        for j in range(n + 1):
            t = j / n
            k += 1
            if dash and ((k + phase) // dash) % 2:
                continue
            put(a, x0 + (x1 - x0) * t - 0.5, cy + ((y0 + (y1 - y0) * t) - cy) * squash - 0.5, c)


def sparks(a, cx, cy, n, r, colours, rng, size=1, spread=0.3):
    for i in range(n):
        ang = math.tau * i / n + rng.uniform(-spread, spread)
        d = r * rng.uniform(0.8, 1.15)
        x, y = cx + math.cos(ang) * d - 0.5, cy + math.sin(ang) * d - 0.5
        c = colours[i % len(colours)]
        put(a, x, y, c)
        if size > 1:
            put(a, x + 1, y, c)
            put(a, x, y + 1, c)
            put(a, x + 1, y + 1, c)


# ---------------------------------------------------------------- the effects
def flash():
    """A muzzle flash: a white-hot star, then an orange ring, then a puff of smoke."""
    rng = random.Random(7)
    out = []
    cx, cy = 12, 12
    a = blank("flash")
    for k in range(4):
        ray(a, cx, cy, k * math.pi / 2, 1, 5, "fff089")
    disc(a, cx, cy, 2.6, "ffffff")
    out.append(a)
    a = blank("flash")
    for k in range(8):
        ang = k * math.pi / 4
        if k % 2 == 0:
            ray(a, cx, cy, ang, 2, 11, "fff089", tip="f8c53a", width=2)
        else:
            ray(a, cx, cy, ang, 2, 7.5, "f8c53a", tip="e88a36")
    disc(a, cx, cy, 5, "f8c53a")
    disc(a, cx, cy, 4, "fff089")
    disc(a, cx, cy, 2.8, "ffffff")
    out.append(a)
    a = blank("flash")
    blob(a, cx, cy, 5.2, "e88a36", rng, 0.2)
    blob(a, cx - 0.5, cy - 0.5, 3.6, "f8c53a", rng, 0.15)
    disc(a, cx - 0.5, cy - 0.5, 1.8, "fff089")
    for k in range(4):
        ang = k * math.pi / 2 + math.pi / 4
        put(a, cx + math.cos(ang) * 7.5 - 0.5, cy + math.sin(ang) * 7.5 - 0.5, "e88a36")
        put(a, cx + math.cos(ang) * 9 - 0.5, cy + math.sin(ang) * 9 - 0.5, "b9451d")
    out.append(a)
    a = blank("flash")
    blob(a, cx - 2, cy - 1, 3.6, "595757", rng, 0.18)
    blob(a, cx + 2.5, cy - 2.5, 3.0, "595757", rng, 0.18)
    blob(a, cx, cy + 1.5, 2.6, "3e4246", rng, 0.15)
    blob(a, cx - 2.5, cy - 2.5, 1.8, "807b7a", rng, 0.1)
    blob(a, cx + 2, cy - 3.5, 1.4, "807b7a", rng, 0.1)
    put(a, cx + 5, cy + 3, "e88a36")
    put(a, cx - 5, cy + 2, "b9451d")
    out.append(a)
    return out


def impact():
    """Where damage lands: a white flash, a gold star of sparks, sparks flying out, embers."""
    rng = random.Random(11)
    out = []
    cx, cy = 16, 16
    a = blank("impact")
    disc(a, cx, cy, 7, "fff089")
    disc(a, cx, cy, 5, "ffffff")
    out.append(a)
    a = blank("impact")
    for k in range(8):
        ang = k * math.pi / 4 + 0.2
        ray(a, cx, cy, ang, 2, 12.5 if k % 2 == 0 else 9, "fff089", tip="f8c53a", width=2 if k % 2 == 0 else 1)
    disc(a, cx, cy, 4, "f8c53a")
    disc(a, cx, cy, 3, "ffffff")
    sparks(a, cx, cy, 6, 13.5, ["f8c53a", "ffffff"], rng, size=2)
    out.append(a)
    a = blank("impact")
    ring(a, cx, cy, 7.5, "f8c53a", width=1.6, gaps=5, phase=0.4)
    for k in range(10):
        ang = math.tau * k / 10 + rng.uniform(-0.2, 0.2)
        d = rng.uniform(9, 13)
        x0, y0 = cx + math.cos(ang) * d, cy + math.sin(ang) * d
        line(a, x0 - 0.5, y0 - 0.5, x0 + math.cos(ang) * 2 - 0.5, y0 + math.sin(ang) * 2 - 0.5, "f8c53a" if k % 3 else "ffffff")
    disc(a, cx, cy, 2.2, "fff089")
    sparks(a, cx, cy, 5, 14.5, ["e88a36", "b47538"], rng, size=2)
    out.append(a)
    a = blank("impact")
    blob(a, cx, cy, 3.2, "595757", rng, 0.2)
    blob(a, cx - 1, cy - 1, 1.8, "807b7a", rng, 0.1)
    sparks(a, cx, cy, 8, 14, ["e88a36", "b05b2c", "f8c53a"], rng)
    out.append(a)
    a = blank("impact")
    blob(a, cx + 1, cy - 2, 2.4, "3e4246", rng, 0.25)
    sparks(a, cx, cy + 2, 5, 15, ["b9451d", "612721"], rng)
    out.append(a)
    return out


def explosion():
    """A blast on one tile: a white core, a fireball, smoke rising with embers."""
    rng = random.Random(23)
    out = []
    cx, cy = 24, 28
    a = blank("explosion")
    disc(a, cx, cy, 7.5, "fff089")
    disc(a, cx, cy, 5.2, "ffffff")
    for k in range(6):
        ray(a, cx, cy, k * math.tau / 6 + 0.3, 7, 11, "f8c53a", tip="e88a36")
    out.append(a)
    a = blank("explosion")
    blob(a, cx, cy, 12, "f1641f", rng, 0.18)
    blob(a, cx - 0.5, cy - 0.5, 9.5, "e88a36", rng, 0.15)
    blob(a, cx - 1, cy - 1.5, 7, "f8c53a", rng, 0.12)
    disc(a, cx - 1.5, cy - 2, 4.5, "fff089")
    disc(a, cx - 2, cy - 2.5, 2.4, "ffffff")
    sparks(a, cx, cy, 8, 16, ["f8c53a", "fff089"], rng, size=2)
    out.append(a)
    a = blank("explosion")
    blob(a, cx, cy, 16, "b9451d", rng, 0.2)
    blob(a, cx, cy - 0.5, 13.5, "f1641f", rng, 0.2)
    blob(a, cx - 1, cy - 2, 10.5, "e88a36", rng, 0.18)
    blob(a, cx - 2, cy - 3.5, 7, "f8c53a", rng, 0.15)
    disc(a, cx - 3, cy - 4.5, 3.6, "fff089")
    sparks(a, cx, cy, 10, 20.5, ["323232", "4c3d2e", "f8c53a"], rng, size=2)
    out.append(a)
    a = blank("explosion")
    for (ox, oy, r) in ((-7, -4, 8), (6, -6, 8.5), (0, 3, 9), (-3, -11, 7), (8, 4, 6)):
        blob(a, cx + ox, cy + oy, r, "3e4246", rng, 0.2)
    for (ox, oy, r) in ((-7, -5, 6), (6, -7, 6.5), (0, 2, 7), (-3, -12, 5)):
        blob(a, cx + ox, cy + oy, r, "595757", rng, 0.2)
    blob(a, cx, cy - 1, 7, "b9451d", rng, 0.25)
    blob(a, cx - 1, cy - 2, 4.5, "f1641f", rng, 0.25)
    disc(a, cx - 1.5, cy - 2.5, 2.2, "f8c53a")
    sparks(a, cx, cy, 9, 22, ["323232", "f8c53a", "4c3d2e"], rng)
    out.append(a)
    a = blank("explosion")
    for (ox, oy, r) in ((-8, -8, 8), (7, -10, 8.5), (0, -2, 9), (-2, -16, 7), (9, 1, 6)):
        blob(a, cx + ox, cy + oy, r, "3e4246", rng, 0.22)
    for (ox, oy, r) in ((-8, -9, 6), (7, -11, 6.5), (0, -3, 7), (-2, -17, 5)):
        blob(a, cx + ox, cy + oy, r, "595757", rng, 0.22)
    for (ox, oy, r) in ((-9, -11, 3), (5, -13, 3.5), (-2, -5, 3.5), (-3, -19, 2.5)):
        blob(a, cx + ox, cy + oy, r, "807b7a", rng, 0.2)
    blob(a, cx, cy - 1, 3.6, "b9451d", rng, 0.3)
    sparks(a, cx, cy - 4, 6, 18, ["f8c53a", "e88a36"], rng)
    out.append(a)
    a = blank("explosion")
    for (ox, oy, r) in ((-9, -12, 7.5), (8, -14, 8), (0, -6, 8), (-2, -20, 6.5)):
        blob(a, cx + ox, cy + oy, r, "3e4246", rng, 0.25)
    for (ox, oy, r) in ((-9, -13, 5.5), (8, -15, 6), (0, -7, 6), (-2, -21, 4.5)):
        blob(a, cx + ox, cy + oy, r, "595757", rng, 0.25)
    for (ox, oy, r) in ((-10, -15, 2.6), (6, -17, 3), (-2, -9, 3)):
        blob(a, cx + ox, cy + oy, r, "807b7a", rng, 0.2)
    sparks(a, cx, cy - 8, 5, 17, ["e88a36", "b9451d"], rng)
    out.append(a)
    a = blank("explosion")
    for (ox, oy, r) in ((-10, -16, 6), (8, -18, 6.5), (0, -10, 6.5), (-2, -24, 5)):
        blob(a, cx + ox, cy + oy, r, "3e4246", rng, 0.3)
    for (ox, oy, r) in ((-10, -17, 4), (8, -19, 4.5), (0, -11, 4.5)):
        blob(a, cx + ox, cy + oy, r, "595757", rng, 0.3)
    sparks(a, cx, cy - 12, 3, 15, ["b9451d"], rng)
    out.append(a)
    a = blank("explosion")
    for (ox, oy, r) in ((-10, -20, 4.5), (8, -22, 5), (1, -15, 4.5)):
        blob(a, cx + ox, cy + oy, r, "3e4246", rng, 0.35)
    # a few holes torn in what is left, as it thins
    for _ in range(26):
        x, y = rng.randrange(48), rng.randrange(48)
        a[y, x] = 0
    out.append(a)
    return out


def heal():
    """Rising from whoever is mended: a ring of light at the feet, green pluses climbing and fading."""
    rng = random.Random(5)
    out = []
    fx, fy = 16, 44
    steps = [
        {"ring": ("59cf93", "97edca", 9.5), "plus": [(16, 36, "59cf93", "d0ffea")]},
        {"ring": ("97edca", "d0ffea", 11), "plus": [(10, 32, "59cf93", "d0ffea"), (22, 29, "59cf93", "d0ffea")], "col": "42a459"},
        {"ring": ("42a459", "59cf93", 12), "plus": [(10, 26, "97edca", "ffffff"), (22, 22, "59cf93", "d0ffea"), (16, 31, "59cf93", "d0ffea")], "col": "42a459", "glint": 2},
        {"plus": [(10, 20, "97edca", "ffffff"), (22, 15, "97edca", "ffffff"), (16, 25, "59cf93", "d0ffea")], "glint": 3},
        {"plus": [(10, 14, "59cf93", "97edca"), (22, 9, "42a459", "97edca"), (16, 19, "42a459", "59cf93")], "glint": 2},
        {"plus": [(16, 12, "42a459", "59cf93")], "glint": 1},
    ]
    for st in steps:
        a = blank("heal")
        if "col" in st:
            for x in (13, 16, 19):
                for y in range(18, 42, 2):
                    if (x + y) % 4 == 0:
                        put(a, x, y, st["col"])
        if "ring" in st:
            outer, inner, rx = st["ring"]
            ellipse_edge(a, fx, fy - 2, rx, rx * 0.38, outer)
            ellipse_edge(a, fx, fy - 2, rx - 0.6, rx * 0.38 - 0.6, outer)
            ellipse_edge(a, fx, fy - 2, rx - 3, rx * 0.38 - 1.4, inner, skip=lambda t: math.sin(t) < -0.2)
        for (x, y, c, core) in st["plus"]:
            plus(a, x, y, c, core, "27412d")
        for _ in range(st.get("glint", 0)):
            put(a, rng.randrange(6, 26), rng.randrange(8, 36), "ffffff")
        out.append(a)
    return out


def shield():
    """Flaring when an attack glances off: a hexagon of blue light round the Unit, a ripple, fading."""
    out = []
    cx, cy = 24, 26
    a = blank("shield")
    hex_edge(a, cx, cy, 20, "2b4e95", dash=3)
    out.append(a)
    a = blank("shield")
    hex_edge(a, cx, cy, 20.5, "4572e3")
    hex_edge(a, cx, cy, 20, "8aa1f6")
    hex_edge(a, cx, cy, 11, "2b4e95", dash=2)
    out.append(a)
    a = blank("shield")
    hex_edge(a, cx, cy, 21, "8aa1f6")
    hex_edge(a, cx, cy, 20.2, "c9d4fd")
    hex_edge(a, cx, cy, 19.4, "f1f2ff")
    hex_edge(a, cx, cy, 13, "8aa1f6")
    for i in range(6):
        x, y = hexagon(cx, cy, 20.2)[i]
        disc(a, x, y, 1.4, "f1f2ff")
    out.append(a)
    a = blank("shield")
    hex_edge(a, cx, cy, 20.2, "8aa1f6")
    hex_edge(a, cx, cy, 19.4, "c9d4fd")
    hex_edge(a, cx, cy, 16, "4572e3", dash=2, phase=1)
    hex_edge(a, cx, cy, 9, "8aa1f6", dash=3)
    out.append(a)
    a = blank("shield")
    hex_edge(a, cx, cy, 20, "4572e3", dash=4)
    hex_edge(a, cx, cy, 19.2, "8aa1f6", dash=4, phase=2)
    out.append(a)
    a = blank("shield")
    hex_edge(a, cx, cy, 20, "2b4e95", dash=2, phase=1)
    out.append(a)
    return out


# ---------------------------------------------------------------- (0.18) the atmosphere's motes
def ember():
    """An ember rising off hot metal: a bright speck in a halo, brightening and dimming as it turns."""
    out = []
    for core, mid, rim, halo in [("fff089", "f8c53a", "ff7a1a", "e88a36"), ("ffffff", "fff089", "f8c53a", "ff7a1a"),
                                 ("ffffff", "ffffff", "fff089", "f8c53a"), ("ffffff", "fff089", "f8c53a", "ff7a1a")]:
        a = blank("ember")
        for (x, y) in ((3, 1), (4, 1), (1, 3), (1, 4), (6, 3), (6, 4), (3, 6), (4, 6)):
            put(a, x, y, halo)
        for (x, y) in ((2, 2), (5, 2), (2, 5), (5, 5)):
            put(a, x, y, rim)
        for y in range(2, 6):
            for x in range(2, 6):
                if (x, y) not in ((2, 2), (5, 2), (2, 5), (5, 5)):
                    put(a, x, y, mid)
        for (x, y) in ((3, 3), (4, 3), (3, 4)):
            put(a, x, y, core)
        out.append(a)
    return out


def spark():
    """A spark off a machine: a white-hot point with a tail, burning down to orange."""
    out = []
    for head, tail, end in [("ffffff", "fff089", "f8c53a"), ("fff089", "f8c53a", "ff7a1a"), ("f8c53a", "ff7a1a", "b05b2c")]:
        a = blank("spark")
        for (x, y) in ((7, 7), (8, 7), (7, 8), (8, 8)):
            put(a, x, y, head)
        for k in (5, 6):
            put(a, k, k, tail); put(a, k + 1, k, tail)
        for k in (3, 4):
            put(a, k, k, end)
        put(a, 2, 2, end)
        out.append(a)
    return out


def ash():
    """A flake of ash falling from the machines' heat, tumbling as it drifts down."""
    out = []
    shapes = [((2, 3), (3, 3), (4, 3), (5, 3), (3, 4), (4, 4)),          # flat
              ((3, 2), (4, 3), (4, 4), (3, 4), (5, 4), (4, 5)),          # turning
              ((3, 2), (3, 3), (4, 3), (4, 4), (4, 5), (3, 5))]          # on edge
    for sh in shapes:
        a = blank("ash")
        for i, (x, y) in enumerate(sh):
            put(a, x, y, "cbc6c1" if i == 0 else ("a69e9a" if i < 4 else "807b7a"))
        out.append(a)
    return out


def dust():
    """A mote of dust catching the light, turning slowly."""
    out = []
    a = blank("dust")
    put(a, 2, 2, "a69e9a"); put(a, 3, 2, "807b7a"); put(a, 2, 3, "807b7a"); put(a, 3, 3, "6a7178")
    out.append(a)
    a = blank("dust")
    put(a, 2, 2, "cbc6c1"); put(a, 3, 3, "807b7a"); put(a, 3, 2, "6a7178")
    out.append(a)
    return out


DRAW = {"flash": flash, "impact": impact, "explosion": explosion, "heal": heal, "shield": shield,
        "ember": ember, "spark": spark, "ash": ash, "dust": dust}


def frames(name):
    return DRAW[name]()


if __name__ == "__main__":
    from kart import sheet, preview_path
    for n in NAMES + ATMOS:
        fr = frames(n)
        sheet(fr, preview_path("fx_%s.png" % n), scale=6, labels=["%s %d" % (n, i + 1) for i in range(len(fr))], cols=len(fr))
    print("ok")
