"""Card art (0.17): a picture for every card that isn't a Unit, 128 by 90
pixels (the game's art window, 64 by 45, at twice the detail). Each shows the
thing itself, modelled and lit as the tokens are, over a dim backdrop of the
District the card belongs to (Vantage Robotics' factory floor for District 3;
the colony at night for a card of no District or of any)."""
import math, random
import numpy as np
from kart import *
from rigs import *

W, H = 128, 90


# ---------------------------------------------------------------- backdrops
SEAM = 4.0  # how sharply one band gives way to the next: the dither is kept to the seam between them


def _dither(x, y, share):
    """Ordered dither: whether pixel (x, y) takes the second colour at this share (0 to 1).
    The share is steepened, so a band is solid and only its seam is dithered (which also keeps
    the picture small to store: long runs of one colour)."""
    share = min(1.0, max(0.0, (share - 0.5) * SEAM + 0.5))
    B = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
    return share * 16 > B[(y & 3) * 4 + (x & 3)] + 0.5


def _ramp_fill(a, x0, y0, x1, y1, cols, horiz=False):
    """A gradient band of palette colours, dithered between steps."""
    n = len(cols) - 1
    for y in range(max(0, y0), min(H, y1)):
        for x in range(max(0, x0), min(W, x1)):
            t = ((x - x0) / max(1, x1 - x0 - 1)) if horiz else ((y - y0) / max(1, y1 - y0 - 1))
            f = t * n
            i = min(n - 1, int(f))
            a[y, x] = idx(cols[i + 1]) if _dither(x, y, f - i) else idx(cols[i])


def _glow(a, cx, cy, rx, ry, cols, strength=1.0):
    """A soft dithered glow: rings of the given colours, brightest in the middle,
    laid only over the darker colours already there."""
    n = len(cols)
    for y in range(H):
        for x in range(W):
            d = math.hypot((x - cx) / rx, (y - cy) / ry)
            if d >= 1:
                continue
            f = (1 - d) * n * strength
            i = min(n - 1, int(f))
            if i < 0:
                continue
            c = cols[i] if not _dither(x, y, f - i) or i + 1 >= n else cols[i + 1]
            a[y, x] = idx(c)


def backdrop(d, seed=1):
    """The dim scene behind a card's thing: '3' Vantage Robotics, else the colony."""
    rng = random.Random(seed)
    a = np.zeros((H, W), np.int32)
    if d == "3":
        # the factory: a dark wall of girders and a pipe, a warm glow, a deck with a hazard band
        _ramp_fill(a, 0, 0, W, 66, ["0e0c0c", "171516", "271f1b"])
        _glow(a, 64 + rng.randint(-10, 10), 42, 90, 52, ["271f1b", "452a1b", "4f342f", "673931"], 0.75)
        for gx in range(6 + rng.randint(0, 8), W, 26 + rng.randint(-3, 3)):
            for y in range(0, 66):
                for x in range(gx, gx + 5):
                    if 0 <= x < W:
                        a[y, x] = idx("171516") if x in (gx, gx + 4) else idx("2d1b1e")
            for y in range(4, 66, 9):
                for x in range(gx + 1, gx + 4):
                    if 0 <= x < W:
                        a[y, x] = idx("4c3d2e")
        py = 14 + rng.randint(0, 8)
        for x in range(W):
            for y in range(py, py + 5):
                a[y, x] = idx("4c3d2e") if y == py + 1 else (idx("271f1b") if y in (py, py + 4) else idx("452a1b"))
            if x % 21 == 7:
                for y in range(py - 1, py + 6):
                    a[y, x] = idx("0e0c0c")
        for k in range(3):
            lx, ly = rng.randint(8, W - 8), rng.randint(30, 56)
            a[ly, lx] = idx("e88a36")
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                a[ly + dy, lx + dx] = idx("b05b2c")
        _ramp_fill(a, 0, 66, W, H, ["452a1b", "271f1b", "171516"])
        for x in range(W):
            if ((x // 6) % 2) == 0:
                for y in (66, 67):
                    a[y, x] = idx("d6a851")
            else:
                for y in (66, 67):
                    a[y, x] = idx("171516")
        for y in range(70, H, 7):
            for x in range(W):
                a[y, x] = idx("171516")
    else:
        # the colony at night: a sky with stars, towers with a few windows lit, the ground
        _ramp_fill(a, 0, 0, W, 72, ["0e0c0c", "14121d", "1b2447", "282c3c"])
        for k in range(40):
            x, y = rng.randint(0, W - 1), rng.randint(0, 40)
            a[y, x] = idx("88a3bc") if k % 5 else idx("e6e7f0")
        x = 0
        while x < W:
            w = rng.randint(8, 16)
            top = rng.randint(30, 58)
            for yy in range(top, 74):
                for xx in range(x, min(W, x + w)):
                    a[yy, xx] = idx("171819") if xx in (x, x + w - 1) else idx("282c3c")
            for wy in range(top + 3, 70, 4):
                for wx in range(x + 2, x + w - 2, 3):
                    if rng.random() < 0.18 and wx < W:
                        a[wy, wx] = idx(rng.choice(["f8c53a", "73efe8", "fca570"]))
            x += w + rng.randint(0, 3)
        _ramp_fill(a, 0, 74, W, H, ["2c3438", "171819", "0e0c0c"])
    a[a == 0] = idx("171819")          # no gaps: a card's picture is solid to its edges
    return a


# ---------------------------------------------------------------- the things
CARDS = {}


def card(name, d, yaw=30, pitch=22, scale=2.0, foot=(64, 78)):
    def deco(fn):
        CARDS[name] = {"fn": fn, "d": d, "yaw": yaw, "pitch": pitch, "scale": scale, "foot": foot}
        return fn
    return deco


@card("Aether Lance", "3", yaw=20, pitch=15, scale=1.9, foot=(64, 70))
def aether_lance():
    """A lance-emitter: a steel shaft in a Vantage housing, a violet crystal head crackling."""
    R = rot_z(math.radians(-28))
    S = [moved(capsule((-24, 0, 0), (14, 0, 0), 1.6, "steel"), by=(0, 14, 0), R=R),
         moved(box((-6, 0, 0), (7, 3.2, 3.2), "vantage", r=1.0), by=(0, 14, 0), R=R),
         moved(box((-6, 3.6, 0), (5, 0.6, 2.6), "hazard", r=0.2), by=(0, 14, 0), R=R),
         moved(cylinder((-26, 0, 0), (-21, 0, 0), 2.6, "graphite", 0.6), by=(0, 14, 0), R=R),
         moved(torus((10, 0, 0), 3.2, 0.7, "brass", R=rot_z(math.pi / 2)), by=(0, 14, 0), R=R),
         moved(cone((14, 0, 0), (27, 0, 0), 3.0, 0.2, "crystal"), by=(0, 14, 0), R=R),
         moved(sphere((16, 0, 0), 1.6, "glow_violet"), by=(0, 14, 0), R=R)]
    for k in range(5):
        ang = k * 1.26
        S.append(moved(capsule((22, 0, 0), (27 + 3 * math.cos(ang), 4 * math.sin(ang), 4 * math.cos(ang * 1.7)), 0.35, "glow_plasma"), by=(0, 14, 0), R=R))
    return S


@card("Counterweight Fist", "3", yaw=48, pitch=18, scale=1.9, foot=(60, 80))
def counterweight_fist():
    """A heavy gauntlet seen from its side: a fist of plated fingers on a long
    forearm, a drum of counterweight riding its back."""
    S = [cylinder((0, 14, -22), (0, 14, -4), 5.2, "graphite", 1.2),          # forearm
         cylinder((0, 14, -16), (0, 14, -10), 5.9, "vantage", 0.8),        # cuff
         box((0, 14, 3), (6.5, 7.0, 7.0), "vantage", r=2.4),                 # back of the hand
         box((0, 8.5, 4), (5.6, 1.0, 5.2), "hazard", r=0.3)]
    for i, x in enumerate((-4.2, -1.4, 1.4, 4.2)):
        S.append(capsule((x, 18, 10), (x, 11, 12), 1.55, "steel"))           # curled fingers
        S.append(sphere((x, 18.4, 9.6), 1.7, "steel"))                       # knuckles
    S += [capsule((-6.6, 12, 4), (-5.2, 10, 10), 1.6, "steel"),              # thumb
          cylinder((0, 23.5, -18), (0, 23.5, -6), 3.4, "brass", 0.8),       # the counterweight drum
          torus((0, 23.5, -12), 3.5, 0.7, "steel", R=rot_x(math.pi / 2)),
          box((0, 20.4, -12), (1.4, 2.0, 4.0), "steel", r=0.4),
          capsule((2.5, 10.5, -20), (2.5, 10.5, -6), 0.5, "rubber")]
    return S


@card("Falconer Drone Pack", "3", yaw=30, pitch=20, scale=1.8, foot=(64, 84))
def falconer_pack():
    """A backpack frame, and its FALCON drone lifting off it."""
    S = [box((0, 12, 0), (8, 10, 4.5), "vantage", r=1.8),
         box((0, 6, 4.8), (6, 3.5, 1.2), "graphite", r=0.6),
         capsule((-6, 2, -5), (-6, 22, -5), 0.9, "steel"), capsule((6, 2, -5), (6, 22, -5), 0.9, "steel"),
         box((0, 18, 4.4), (5, 1.0, 0.6), "hazard", r=0.2),
         cylinder((-9.6, 6, 0), (-9.6, 18, 0), 1.6, "rubber", 0.4)]
    # the drone, above
    dz = (0, 33, 2)
    S += [moved(box((0, 0, 0), (4.5, 1.6, 3.0), "steel", r=1.0), by=dz),
          moved(sphere((0, -0.6, 3.0), 1.3, "glow_red"), by=dz)]
    for sx in (-1, 1):
        for sz in (-1, 1):
            S.append(moved(capsule((0, 0, 0), (7.5 * sx, 0.6, 5.0 * sz), 0.6, "graphite"), by=dz))
            S.append(moved(cylinder((7.5 * sx, 1.0, 5.0 * sz), (7.5 * sx, 1.4, 5.0 * sz), 3.6, "glass", 0.2), by=dz))
    return S


@card("Hold the Line", "3", yaw=15, pitch=14, scale=1.75, foot=(64, 86))
def hold_the_line():
    """A standard planted in the deck: a Vantage banner, a rank of shields at its foot."""
    S = [capsule((0, 0, 0), (0, 44, 0), 0.9, "steel"),
         sphere((0, 45, 0), 1.6, "brass"),
         box((7.5, 36, 0), (7.0, 7.5, 0.4), "vantage", r=0.3),
         box((7.5, 30.5, 0.2), (7.0, 1.0, 0.4), "hazard", r=0.2),
         torus((7.5, 37, 0.5), 2.6, 0.7, "ink", R=rot_x(math.pi / 2)),
         box((7.5, 37, 0.5), (0.8, 3.6, 0.3), "ink", r=0.1)]
    for i, x in enumerate((-16, -8, 8, 16)):
        S.append(box((x, 7, 3), (3.6, 7, 0.9), "steel", r=0.8))
        S.append(box((x, 9, 4.0), (2.2, 0.6, 0.3), "hazard", r=0.1))
    return S


@card("Smoke Canister", "3", yaw=20, pitch=22, scale=2.4, foot=(40, 80))
def smoke_canister():
    """A smoke canister on its side, pin out, grey smoke pouring from its cap."""
    R = rot_z(math.radians(-80))
    S = [moved(cylinder((0, -9, 0), (0, 9, 0), 4.4, "khaki", 1.0), by=(0, 4.5, 0), R=R),
         moved(box((0, -2, 0), (4.6, 2.0, 4.6), "hazard", r=0.6), by=(0, 4.5, 0), R=R),
         moved(cylinder((0, 9, 0), (0, 11.5, 0), 2.6, "steel", 0.6), by=(0, 4.5, 0), R=R),
         torus((4, 9.6, 3), 1.8, 0.4, "steel")]
    rng = random.Random(4)
    for k in range(8):
        x = 14 + k * 2.6 + rng.uniform(-1, 1)
        y = 6 + k * 2.2 + rng.uniform(-1.5, 1.5)
        S.append(sphere((x, y, rng.uniform(-3, 3)), 2.0 + k * 0.42, "grime" if k % 3 else "concrete"))
    return S


@card("Harmonic Damper", "3", yaw=30, pitch=20, scale=2.0, foot=(64, 80))
def harmonic_damper():
    """A prototype on a test plinth: twin tuning prongs over a coil humming blue."""
    S = [box((0, 3, 0), (11, 3, 7), "graphite", r=1.0),
         box((0, 6.6, 0), (9, 0.8, 5.6), "vantage", r=0.4),
         cylinder((0, 7, 0), (0, 12, 0), 4.2, "steel", 0.8),
         torus((0, 13.5, 0), 4.6, 1.0, "glow_cyan"),
         torus((0, 16.5, 0), 3.8, 0.8, "glow_blue"),
         capsule((-2.4, 12, 0), (-2.4, 33, 0), 1.0, "silver"), capsule((2.4, 12, 0), (2.4, 33, 0), 1.0, "silver"),
         sphere((0, 11.5, 0), 2.6, "steel"),
         box((-8.5, 6.8, 4), (1.2, 0.4, 1.2), "glow_amber", r=0.2), box((-5.5, 6.8, 4), (1.2, 0.4, 1.2), "glow_red", r=0.2)]
    for k, y in enumerate((20, 26, 31)):
        S.append(torus((0, y, 0), 6.5 + k, 0.25, "glow_cyan"))
    return S


@card("Aether Bolt", "any", yaw=0, pitch=10, scale=1.9, foot=(64, 72))
def aether_bolt():
    """A bolt of Aether: a violet crystal dart, its trail breaking into sparks."""
    R = rot_z(math.radians(-18))
    S = [moved(cone((0, 0, 0), (20, 0, 0), 4.0, 0.2, "crystal"), by=(4, 18, 0), R=R),
         moved(cone((0, 0, 0), (-9, 0, 0), 4.0, 0.6, "crystal"), by=(4, 18, 0), R=R),
         moved(sphere((0, 0, 0), 2.2, "glow_white"), by=(4, 18, 0), R=R)]
    rng = random.Random(7)
    for k in range(10):
        x = -12 - k * 3.4
        S.append(moved(sphere((x, rng.uniform(-3, 3), rng.uniform(-2, 2)), max(0.5, 2.6 - k * 0.22), "glow_violet" if k % 2 else "glow_plasma"), by=(4, 18, 0), R=R))
    return S


# ---------------------------------------------------------------- shared builders
def chip(frame="brass", core="onyx", face="jade", glyph=None, glow="glow_mint", sides=6, studs="steel"):
    """An Aether Chip: a frame of plates round a dark core, a glowing glyph on its face."""
    S = []
    for k in range(sides):
        a = k * 2 * math.pi / sides
        S.append(box((10 * math.cos(a), 6, 10 * math.sin(a)), (5.8 if sides == 6 else 4.6, 1.6, 1.4), frame, r=0.5,
                     R=rot_y(-a + math.pi / 2)))
    S += [cylinder((0, 4.6, 0), (0, 7.4, 0), 9.4, core, 0.6),
          cylinder((0, 7.3, 0), (0, 8.0, 0), 6.0, face, 0.5)]
    for k in range(sides):
        a = k * 2 * math.pi / sides + math.pi / sides
        S.append(box((11.6 * math.cos(a), 5.4, 11.6 * math.sin(a)), (0.7, 0.8, 0.7), studs, r=0.2))
    S += GLYPH[glyph or "plus"](glow)
    return S


def _g(*bits):
    return lambda glow: [box((x, 8.4, -z), (hx, 0.6, hz), glow, r=0.2) for (x, z, hx, hz) in bits]  # +z reads as up the card


GLYPH = {
    "plus": _g((0, 0, 4.2, 1.2), (0, 0, 1.2, 4.2)),
    "minus": _g((0, 0, 4.2, 1.2)),
    "up": _g((0, 3.4, 0.9, 0.7), (0, 2.2, 2.1, 0.7), (0, 1.0, 3.3, 0.7), (0, -2.0, 1.1, 2.4)),
    "bars": _g((-2.6, 0, 0.9, 3.6), (0, 0, 0.9, 3.6), (2.6, 0, 0.9, 3.6)),
    "shield": _g((0, -1.0, 3.6, 1.0), (-2.6, 1.2, 1.0, 2.6), (2.6, 1.2, 1.0, 2.6), (0, 3.2, 1.6, 0.8)),
    "bolt": _g((1.2, -2.2, 0.9, 2.2), (0, 0, 2.6, 0.8), (-1.2, 2.2, 0.9, 2.2)),
    "barb": _g((0, 0, 0.8, 4.2), (-1.8, -2.2, 0.8, 1.2), (1.8, -2.2, 0.8, 1.2), (-1.8, 0.8, 0.8, 1.2), (1.8, 0.8, 0.8, 1.2)),
    "ring": _g((0, -3, 3, 0.8), (0, 3, 3, 0.8), (-3, 0, 0.8, 3), (3, 0, 0.8, 3)),
    "split": _g((-2.2, 0, 1.0, 3.8), (2.2, 0, 1.0, 3.8)),
    "dot": _g((0, 0, 1.6, 1.6)),
    "wave": _g((-3, -1, 1.0, 1.0), (-1, 1, 1.0, 1.0), (1, -1, 1.0, 1.0), (3, 1, 1.0, 1.0)),
    "flask": _g((0, 1.8, 2.8, 1.8), (0, -1.6, 1.0, 2.0)),
    "spark": _g((0, 0, 0.8, 4.0), (0, 0, 4.0, 0.8), (2, 2, 0.8, 0.8), (-2, -2, 0.8, 0.8), (2, -2, 0.8, 0.8), (-2, 2, 0.8, 0.8)),
}
CHIP_KW = dict(yaw=0, pitch=52, scale=2.6, foot=(64, 66))


def crystal_shard(at, length, r, mat="crystal", R=None):
    """A double-ended crystal."""
    return [moved(cone((0, 0, 0), (0, length, 0), r, 0.2, mat), by=at, R=R), moved(cone((0, 0, 0), (0, -length * 0.45, 0), r, 0.3, mat), by=at, R=R)]


def plate(at, half, mat="steel", trim="vantage", R=None):
    """An armour plate with a coloured edge and rivets."""
    x, y, z = at
    S = [moved(box((0, 0, 0), half, mat, r=1.0), by=at, R=R), moved(box((0, half[1] - 0.6, half[2] * 0.3), (half[0] * 0.95, 0.7, half[2] * 0.8), trim, r=0.3), by=at, R=R)]
    for sx in (-1, 1):
        for sy in (-1, 1):
            S.append(moved(sphere((sx * half[0] * 0.75, sy * half[1] * 0.6, half[2] + 0.2), 0.6, "brass"), by=at, R=R))
    return S


def drone(at, body="steel", eye="glow_red", arms="graphite", rotor="glass", k=1.0):
    S = [moved(box((0, 0, 0), (4.5 * k, 1.6 * k, 3.0 * k), body, r=1.0), by=at), moved(sphere((0, -0.6 * k, 3.0 * k), 1.3 * k, eye), by=at)]
    for sx in (-1, 1):
        for sz in (-1, 1):
            S.append(moved(capsule((0, 0, 0), (7.5 * sx * k, 0.6 * k, 5.0 * sz * k), 0.6 * k, arms), by=at))
            S.append(moved(cylinder((7.5 * sx * k, 1.0 * k, 5.0 * sz * k), (7.5 * sx * k, 1.4 * k, 5.0 * sz * k), 3.6 * k, rotor, 0.2), by=at))
    return S


def arcs(a, b, n, mat="glow_plasma", seed=3, jitter=2.5, r=0.35):
    """A crackling arc of Aether from a to b, in n kinks."""
    rng = random.Random(seed)
    pts = [np.array(a, float)]
    for i in range(1, n):
        t = i / n
        q = np.array(a, float) * (1 - t) + np.array(b, float) * t + np.array([rng.uniform(-jitter, jitter) for _ in range(3)])
        pts.append(q)
    pts.append(np.array(b, float))
    return [capsule(tuple(pts[i]), tuple(pts[i + 1]), r, mat) for i in range(len(pts) - 1)]


# ---------------------------------------------------------------- Chips
for _name, _d, _kw in [
    ("Mending Chip", "3", dict(frame="brass", face="jade", glyph="plus", glow="glow_mint")),
    ("Alchemical Chip", "3", dict(frame="brass", face="violet", glyph="flask", glow="glow_violet")),
    ("Barbed Chip", "", dict(frame="steel", face="blood", glyph="barb", glow="glow_red")),
    ("Bolstering Chip", "", dict(frame="silver", face="navy", glyph="shield", glow="glow_blue")),
    ("Dampening Chip", "3", dict(frame="gunmetal", face="teal", glyph="wave", glow="glow_cyan")),
    ("Bastion Chip", "", dict(frame="graphite", face="steel", glyph="bars", glow="glow_white", studs="brass")),
    ("Invigorating Chip", "", dict(frame="silver", face="olive", glyph="bolt", glow="glow_yellow")),
    ("Sparking chip", "3", dict(frame="vantage", face="rust", glyph="spark", glow="glow_orange")),
    ("Ledger Chip", "3", dict(frame="gold", face="ochre", glyph="ring", glow="glow_amber", studs="brass")),
    ("Surge Chip", "3", dict(frame="vantage", face="olive", glyph="up", glow="glow_acid")),
    ("Ballast Chip", "3", dict(frame="graphite", face="concrete", glyph="minus", glow="glow_amber", sides=8)),
    ("Quiet Chip", "3", dict(frame="charcoal", face="plum", glyph="dot", glow="glow_violet", sides=8)),
    # content batch 1 (0.22)
    ("Spring Chip", "3", dict(frame="vantage", face="teal", glyph="up", glow="glow_cyan", studs="brass")),
    ("Gyro Chip", "3", dict(frame="gunmetal", face="navy", glyph="ring", glow="glow_violet", sides=8)),
]:
    CARDS[_name] = {"fn": (lambda kw=_kw: chip(**kw)), "d": _d, **CHIP_KW}


# ---------------------------------------------------------------- Aether
@card("Aether Discharge", "any", yaw=20, pitch=24, scale=1.8, foot=(64, 76))
def aether_discharge():
    """A burst of Aether over a cracked tile: a violet core flinging arcs outward."""
    S = [cylinder((0, 0, 0), (0, 2.0, 0), 16, "concrete", 0.6), sphere((0, 12, 0), 4.5, "glow_violet"), sphere((0, 12, 0), 2.2, "glow_white")]
    for k in range(7):
        a = k * 2 * math.pi / 7
        S += arcs((0, 12, 0), (16 * math.cos(a), 4 + 10 * ((k % 3) / 2), 16 * math.sin(a)), 4, "glow_plasma" if k % 2 else "glow_violet", seed=k)
    for k in range(5):
        a = k * 1.3
        S += crystal_shard((11 * math.cos(a), 2, 11 * math.sin(a)), 4.0, 1.4, R=rot_z(0.4 * math.cos(a)))
    return S


@card("Aether battery", "3", yaw=30, pitch=22, scale=2.0, foot=(64, 80))
def aether_battery():
    """An Aether battery: a glass cell of violet light in a Vantage cradle."""
    S = [box((0, 2.0, 0), (9, 2.0, 7), "graphite", r=0.8), box((0, 4.4, 0), (8, 0.6, 6), "vantage", r=0.3),
         cylinder((0, 5, 0), (0, 26, 0), 5.6, "glass", 1.0), cylinder((0, 7, 0), (0, 23, 0), 3.4, "glow_violet", 1.0),
         cylinder((0, 25, 0), (0, 29, 0), 6.4, "steel", 0.8), cylinder((0, 29, 0), (0, 31, 0), 2.6, "brass", 0.4)]
    for x in (-6.8, 6.8):
        S.append(capsule((x, 4, 0), (x, 27, 0), 0.9, "steel"))
    S += arcs((0, 31, 0), (6, 36, 2), 3, "glow_plasma", seed=5, jitter=1.5)
    return S


@card("Burning Heart", "3", yaw=20, pitch=15, scale=2.0, foot=(64, 76))
def burning_heart():
    """A cyborg heart: a mechanical pump, its chambers glowing hot, cables trailing."""
    S = [ellipsoid((0, 16, 0), (7.5, 9, 6), "crimson"), ellipsoid((3, 20, 1), (4.5, 5, 4), "blood"),
         cylinder((-2, 24, 0), (-4, 31, -1), 2.0, "steel", 0.6), cylinder((3, 24, 0), (6, 30, 1), 1.6, "steel", 0.6),
         torus((0, 16, 0), 7.6, 0.9, "steel", R=rot_x(0.3)), sphere((-2, 14, 5), 2.4, "glow_orange"), sphere((-2, 14, 5.5), 1.1, "glow_yellow")]
    for k in range(3):
        S.append(capsule((-5 + k * 5, 9, -2), (-12 + k * 12, 3, -9), 0.7, "rubber"))
    for k in range(6):
        a = k * 1.05
        S.append(sphere((9 * math.cos(a), 16 + 9 * math.sin(a), 3), 0.9, "glow_orange" if k % 2 else "glow_amber"))
    return S


@card("Datamine", "any", yaw=25, pitch=22, scale=2.0, foot=(64, 78))
def datamine():
    """A data spike jacked into a terminal, light streaming out of it in lines."""
    S = [box((0, 6, 0), (11, 6, 6), "gunmetal", r=1.0), box((0, 9, 6.2), (7, 2.5, 0.3), "glow_cyan", r=0.2),
         box((0, 4, 6.2), (8, 0.6, 0.3), "glow_mint", r=0.1), capsule((0, 12, 0), (6, 26, -2), 1.6, "steel"),
         cone((6, 26, -2), (8, 31, -3), 1.8, 0.2, "brass")]
    for k in range(6):
        S.append(box((-12 + k * 4.5, 16 + (k % 3) * 4, 3), (1.6, 0.5, 0.5), "glow_cyan", r=0.1))
        S.append(box((-10 + k * 4.5, 22 + (k % 2) * 5, 2), (0.8, 0.5, 0.5), "glow_mint", r=0.1))
    return S


@card("Deploy FCB", "any", yaw=25, pitch=24, scale=1.6, foot=(64, 82))
def deploy_fcb():
    """A Full Cover Barricade unfolding on its drop-pad, tall and plated."""
    S = [cylinder((0, 0, 0), (0, 1.5, 0), 15, "graphite", 0.5)]
    for x in (-9, 0, 9):
        S += [box((x, 13, 0), (4.4, 12, 2.0), "steel", r=0.8), box((x, 20, 2.1), (3.6, 1.0, 0.3), "warning", r=0.2)]
    S += [capsule((-13, 3, -3), (13, 3, -3), 0.8, "brass"), sphere((0, 1.8, 7), 1.0, "glow_cyan")]
    return S


@card("Deploy HCB", "any", yaw=25, pitch=28, scale=1.75, foot=(64, 80))
def deploy_hcb():
    """A Half Cover Barricade, low plates braced on its drop-pad."""
    S = [cylinder((0, 0, 0), (0, 1.5, 0), 15, "graphite", 0.5)]
    for x in (-9, 0, 9):
        S += [box((x, 6, 0), (4.4, 5, 2.0), "steel", r=0.8), box((x, 9, 2.1), (3.6, 0.8, 0.3), "warning", r=0.2),
              capsule((x, 2, -2), (x, 8, -6), 0.7, "graphite")]
    S.append(sphere((0, 1.8, 7), 1.0, "glow_cyan"))
    return S


@card("Deploy Sentry", "3", yaw=30, pitch=18, scale=1.9, foot=(64, 82))
def deploy_sentry():
    """A sentry turret on its tripod, twin barrels, its eye lit."""
    S = [capsule((0, 10, 0), (-7, 0, -5), 1.0, "graphite"), capsule((0, 10, 0), (7, 0, -5), 1.0, "graphite"), capsule((0, 10, 0), (0, 0, 8), 1.0, "graphite"),
         cylinder((0, 9, 0), (0, 13, 0), 3.4, "steel", 0.6), box((0, 17, 0), (5.5, 4, 5), "vantage", r=1.4),
         box((0, 19.5, 0), (4.5, 0.8, 4.5), "hazard", r=0.2), sphere((0, 17, 5.2), 1.6, "glow_red")]
    for x in (-2.2, 2.2):
        S.append(cylinder((x, 16, 4), (x, 16, 14), 1.0, "graphite", 0.3))
    return S


@card("Deploy ordinance drone swarm", "3", yaw=20, pitch=22, scale=1.25, foot=(64, 82))
def drone_swarm():
    """A swarm of ordnance drones dropping out of the dark, each slung with a bomb."""
    S = []
    for (x, y, z, k) in [(-22, 30, -4, 0.9), (0, 38, -8, 0.8), (20, 31, 0, 0.9), (-10, 18, 6, 1.1), (12, 16, 8, 1.1)]:
        S += drone((x, y, z), body="vantage", k=k)
        S.append(capsule((x, y - 2.5 * k, z), (x, y - 6 * k, z), 1.3 * k, "graphite"))
        S.append(sphere((x, y - 6.5 * k, z), 0.7 * k, "glow_orange"))
    return S


@card("Emergency Overdrive", "3", yaw=25, pitch=20, scale=2.0, foot=(64, 80))
def emergency_overdrive():
    """A red emergency lever thrown on a power box, sparks flying."""
    S = [box((0, 10, 0), (9, 10, 4), "steel", r=1.0), box((0, 10, 4.2), (7, 8, 0.4), "graphite", r=0.4),
         box((0, 3, 4.6), (7, 1.0, 0.3), "warning", r=0.2), capsule((2, 12, 5), (9, 22, 10), 1.2, "steel"),
         sphere((9, 22, 10), 2.4, "blood"), sphere((-4, 15, 4.8), 1.2, "glow_red"), sphere((-4, 11, 4.8), 1.2, "glow_acid")]
    rng = random.Random(9)
    for k in range(8):
        S.append(capsule((0, 16, 6), (rng.uniform(-14, 14), 16 + rng.uniform(-6, 10), 8), 0.3, "glow_yellow" if k % 2 else "glow_orange"))
    return S


@card("Frenzy Protocol", "3", yaw=20, pitch=15, scale=1.9, foot=(64, 74))
def frenzy_protocol():
    """A robot's head, its optics burning red, a protocol card slotted in its temple."""
    S = [box((0, 18, 0), (8, 7, 7), "vantage", r=2.4), box((0, 18, 7.2), (6.5, 2.4, 0.6), "onyx", r=0.4),
         box((-3, 18, 7.6), (1.8, 1.0, 0.3), "glow_red", r=0.2), box((3, 18, 7.6), (1.8, 1.0, 0.3), "glow_red", r=0.2),
         box((0, 12, 6), (5, 1.4, 1.6), "graphite", r=0.4), cylinder((0, 6, 0), (0, 11, 0), 3.0, "graphite", 0.5),
         box((8.6, 21, 0), (0.6, 4.4, 3.0), "glow_amber", r=0.2), box((8.2, 15, 0), (1.0, 2, 2), "steel", r=0.4)]
    for k in range(5):
        S.append(capsule((-10 - k, 24 - k * 2, 0), (-16 - k * 2, 26 - k * 3, 0), 0.4, "glow_red"))
    return S


@card("Overrun", "3", yaw=30, pitch=18, scale=1.6, foot=(64, 84))
def overrun():
    """A shockwave rolling out from a stamping metal foot, cracked tiles flying."""
    S = [box((0, 6, 0), (6, 3, 8), "vantage", r=1.6), box((0, 2, 0), (7, 2, 9), "graphite", r=1.0), cylinder((0, 9, -2), (0, 22, -3), 3.2, "steel", 0.6)]
    for r_, mat in ((12, "glow_orange"), (16, "glow_amber"), (20, "glow_orange")):
        S.append(torus((0, 1, 0), r_, 0.6, mat))
    rng = random.Random(2)
    for k in range(7):
        a = rng.uniform(0, 2 * math.pi)
        S.append(box((18 * math.cos(a), 3 + rng.uniform(0, 8), 18 * math.sin(a)), (1.8, 0.7, 1.4), "concrete", r=0.3, R=rot_z(rng.uniform(-1, 1))))
    return S


@card("Salvage Aether Core", "3", yaw=25, pitch=22, scale=2.0, foot=(64, 80))
def salvage_aether_core():
    """A core prised from a wrecked bot: a violet sphere in torn brackets, wires hanging."""
    S = [box((0, 5, 0), (10, 5, 7), "slag", r=1.0), box((-6, 10, 0), (3, 2, 6), "rust", r=0.6, R=rot_z(0.3)),
         sphere((0, 15, 0), 5.5, "crystal"), sphere((0, 15, 0), 3.0, "glow_violet")]
    for a in (0.5, 2.6, 4.4):
        S.append(capsule((7 * math.cos(a), 10, 7 * math.sin(a)), (5 * math.cos(a), 20, 5 * math.sin(a)), 0.8, "steel"))
    for k in range(4):
        S.append(capsule((-8 + k * 5, 9, 6), (-10 + k * 6, 2, 9), 0.5, "rubber" if k % 2 else "blood"))
    return S


@card("Salvage Hard Drive", "3", yaw=25, pitch=30, scale=2.0, foot=(64, 80))
def salvage_hard_drive():
    """A hard drive pulled from scrap: its case open, the platter and the arm, a status light."""
    S = [box((0, 3, 0), (11, 2.2, 8), "gunmetal", r=0.8), cylinder((-2, 5, 0), (-2, 5.6, 0), 6.5, "silver", 0.3),
         cylinder((-2, 5.6, 0), (-2, 6.2, 0), 1.6, "steel", 0.3), capsule((7, 6, 5), (0, 6.4, 1), 0.7, "brass"),
         sphere((8.5, 5.4, -6), 0.9, "glow_acid"), box((10, 5.4, 0), (1.2, 0.6, 4), "graphite", r=0.2)]
    for k in range(3):
        S.append(capsule((-11, 3, -5 + k * 3), (-17, 1, -6 + k * 4), 0.5, "rubber"))
    return S


@card("Scavenge Parts", "3", yaw=30, pitch=28, scale=2.5, foot=(64, 78))
def scavenge_parts():
    """A heap of salvaged parts: a gear, a servo, plates, bolts, a cracked optic."""
    S = [ellipsoid((0, 2, 0), (16, 3, 10), "slag"), torus((-6, 6, 2), 4.2, 1.2, "steel", R=rot_x(1.1)),
         box((6, 6, -1), (4, 2.6, 3), "vantage", r=1.0, R=rot_y(0.5)), cylinder((5, 9, 1), (5, 13, 1), 1.6, "brass", 0.4),
         box((-1, 4, 7), (5, 0.8, 3), "steel", r=0.4, R=rot_z(0.2)), sphere((-11, 5, -4), 2.6, "graphite"), sphere((-11, 5, -1.5), 1.2, "glow_red")]
    for k in range(6):
        a = k * 1.1
        S.append(capsule((10 * math.cos(a), 4, 7 * math.sin(a)), (10 * math.cos(a) + 1.5, 5, 7 * math.sin(a)), 0.6, "brass"))
    return S


@card("Static Veil", "3", yaw=20, pitch=18, scale=1.9, foot=(64, 80))
def static_veil():
    """A veil of static drawn round a figure's outline: a hex shell crackling blue."""
    S = [capsule((0, 6, 0), (0, 22, 0), 3.2, "gunmetal"), sphere((0, 26, 0), 3.0, "gunmetal"),
         capsule((-2, 6, 0), (-2, 0, 0), 1.3, "gunmetal"), capsule((2, 6, 0), (2, 0, 0), 1.3, "gunmetal"),
         sphere((1.2, 26.4, 2.6), 0.8, "glow_cyan")]
    for k in range(6):
        a, b = k * math.pi / 3 + 0.35, (k + 1) * math.pi / 3 + 0.35
        for y in (1.5, 32):
            S.append(capsule((12 * math.cos(a), y, 12 * math.sin(a)), (12 * math.cos(b), y, 12 * math.sin(b)), 0.45, "glow_blue"))
        S.append(capsule((12 * math.cos(a), 1.5, 12 * math.sin(a)), (12 * math.cos(a), 32, 12 * math.sin(a)), 0.3, "glow_cyan"))
    for k in range(3):
        S += arcs((-11, 6 + k * 10, 7), (11, 9 + k * 10, 7), 4, "glow_cyan" if k % 2 else "glow_blue", seed=20 + k, jitter=1.8, r=0.3)
    return S


# ---------------------------------------------------------------- Equipment
def torso(mat="vantage", trim="graphite", y=14, k=1.0):
    """A suit's chest and shoulders, standing on a rack post (equipment on display)."""
    return [cylinder((0, 0, 0), (0, 1.4, 0), 9 * k, "graphite", 0.4), capsule((0, 1, -1), (0, y - 6 * k, -1), 1.0 * k, "steel"),
            box((0, y, 0), (6.5 * k, 6.5 * k, 4 * k), mat, r=2.2 * k), box((0, y - 7 * k, 0), (5 * k, 2 * k, 3.4 * k), trim, r=1.0 * k),
            sphere((-8 * k, y + 4 * k, 0), 3.2 * k, mat), sphere((8 * k, y + 4 * k, 0), 3.2 * k, mat),
            cylinder((0, y + 6 * k, 0), (0, y + 8.5 * k, 0), 2.4 * k, trim, 0.5)]


@card("Aetherium Reactive Plating", "3", yaw=25, pitch=18, scale=2.0, foot=(64, 80))
def reactive_plating():
    """Armour plates with veins of Aether glowing between them."""
    S = []
    for i, (x, y) in enumerate([(-6, 8), (6, 8), (-6, 20), (6, 20)]):
        S += plate((x, y, 0), (5.2, 5.2, 1.2), "steel", "glow_violet")
    S += [box((0, 14, -0.2), (0.6, 12, 0.8), "glow_violet", r=0.2), box((0, 14, -0.2), (11, 0.6, 0.8), "glow_violet", r=0.2),
          box((0, 1, 0), (12, 1, 4), "graphite", r=0.4)]
    return S


@card("Courrier exorunners", "3", yaw=55, pitch=16, scale=2.1, foot=(60, 80))
def exorunners():
    """Exoskeleton running legs: braced struts, a spring at the heel, a sprinter's foot blade."""
    S = []
    for z in (-4, 4):
        S += [box((0, 22, z), (3, 3, 1.6), "vantage", r=1.0), capsule((0, 22, z), (3, 12, z), 1.2, "steel"),
              sphere((3, 12, z), 1.8, "brass"), capsule((3, 12, z), (-2, 3, z), 1.1, "steel"),
              capsule((1.8, 13, z), (-1, 4, z), 0.6, "glow_cyan"), box((1, 1.2, z), (5.5, 0.9, 1.4), "graphite", r=0.5),
              capsule((-2, 3, z), (-5, 1.5, z), 0.8, "rubber")]
    for k in range(3):
        S.append(capsule((-8 - k * 3, 6 + k * 4, 0), (-15 - k * 3, 6 + k * 4, 0), 0.35, "glow_white"))
    return S


@card("Dragonskin lining", "3", yaw=20, pitch=20, scale=2.0, foot=(64, 78))
def dragonskin():
    """A vest lining of overlapping scales, folded back to show the weave."""
    S = [box((0, 14, -1), (10, 12, 1.0), "leather", r=0.8)]
    for row in range(5):
        for col in range(5):
            x = -8 + col * 4 + (2 if row % 2 else 0)
            if x > 9:
                continue
            S.append(ellipsoid((x, 23 - row * 4.2, 0.4), (2.2, 2.4, 0.7), "gunmetal" if (row + col) % 3 else "silver"))
    S += [box((0, 1, 0), (12, 1, 4), "graphite", r=0.4), capsule((-10, 26, 0), (10, 26, 0), 0.8, "steel")]
    return S


@card("HALO targeting System", "3", yaw=25, pitch=18, scale=2.4, foot=(64, 76))
def halo():
    """A helmet with a targeting ring hovering over it, a reticle lit across the visor."""
    S = [ellipsoid((0, 12, 0), (6.5, 6.5, 7), "vantage"), box((0, 11, 5.4), (5.0, 1.8, 1.4), "onyx", r=0.6),
         box((-1.8, 11, 6.6), (1.4, 0.6, 0.3), "glow_red", r=0.1), box((1.8, 11, 6.6), (1.4, 0.6, 0.3), "glow_red", r=0.1),
         torus((0, 22, 0), 7.5, 0.6, "glow_cyan"), box((0, 22, 7.5), (0.5, 0.5, 1.4), "glow_cyan", r=0.1),
         box((0, 22, -7.5), (0.5, 0.5, 1.4), "glow_cyan", r=0.1), cylinder((0, 3, 0), (0, 6, 0), 4, "graphite", 0.6)]
    return S


@card("MONTU Battle Suit", "3", yaw=25, pitch=15, scale=1.65, foot=(64, 84))
def montu():
    """A heavy battle suit on its rack: broad plates, a falcon-crest helm, a glowing chest core."""
    S = torso("vantage", "graphite", y=20, k=1.2) + [
        box((0, 31, 0), (3.4, 3, 3.4), "vantage", r=1.0), box((0, 31, 3.4), (2.6, 0.8, 0.4), "glow_amber", r=0.2),
        cone((0, 33, -1), (0, 38, -4), 1.6, 0.3, "gold"), sphere((0, 21, 4.8), 1.6, "glow_amber"),
        box((-10, 13, 0), (2.4, 6, 2.6), "steel", r=0.8), box((10, 13, 0), (2.4, 6, 2.6), "steel", r=0.8),
        box((0, 19, 5.2), (5, 0.6, 0.3), "hazard", r=0.1)]
    return S


@card("Personal mounted cluster ordinance", "3", yaw=35, pitch=18, scale=2.0, foot=(64, 80))
def cluster_pod():
    """A shoulder-mounted pod of small rockets, the tips peeking from their tubes."""
    S = [box((0, 14, 0), (8, 6, 6), "vantage", r=1.6), box((0, 7, 0), (3, 2, 3), "graphite", r=0.6), cylinder((0, 0, 0), (0, 5, 0), 2, "steel", 0.4)]
    for i in range(3):
        for j in range(2):
            x, y = -5 + i * 5, 11 + j * 6
            S += [cylinder((x, y, 5), (x, y, 7), 2.0, "graphite", 0.3), cone((x, y, 6.4), (x, y, 8.6), 1.3, 0.2, "blood")]
    S.append(box((0, 20.4, 0), (7, 0.5, 5), "hazard", r=0.2))
    return S


@card("Redline Governor", "3", yaw=20, pitch=20, scale=2.2, foot=(64, 80))
def redline_governor():
    """A gauge, its needle pushed past the red line, on a governor block with pipes."""
    S = [box((0, 6, 0), (9, 6, 5), "steel", r=1.2), cylinder((0, 16, 0), (0, 16, 3), 7, "brass", 0.6),
         cylinder((0, 16, 2.6), (0, 16, 3.4), 6, "bone", 0.3)]
    for k in range(5):
        a = math.pi * (0.15 + k * 0.17)
        S.append(box((4.6 * math.cos(a), 16 + 4.6 * math.sin(a), 3.5), (0.5, 0.5, 0.2), "ink" if k < 4 else "blood", r=0.1))
    S += [capsule((0, 16, 3.6), (4.8, 18.2, 3.6), 0.45, "blood"), sphere((0, 16, 3.7), 0.9, "graphite"),
          cylinder((-9, 4, 0), (-15, 4, 0), 1.6, "brass", 0.4), cylinder((9, 4, 0), (15, 4, 0), 1.6, "brass", 0.4),
          sphere((6, 10, 5.2), 1.0, "glow_red")]
    return S


@card("Ripper Combat Suit", "3", yaw=25, pitch=15, scale=1.75, foot=(64, 84))
def ripper_suit():
    """A lean combat suit on its rack, blades folded along its forearms."""
    S = torso("crimson", "graphite", y=20, k=1.05) + [
        box((0, 30, 0), (3, 3, 3.2), "graphite", r=1.2), box((0, 30, 3.2), (2.4, 0.6, 0.3), "glow_red", r=0.2)]
    for sx in (-1, 1):
        S += [capsule((sx * 9, 22, 0), (sx * 10, 12, 1), 2.0, "crimson"),
              box((sx * 11.5, 15, 2), (0.5, 7, 1.2), "silver", r=0.2), cone((sx * 11.5, 22, 2), (sx * 11.5, 25, 2), 1.0, 0.1, "silver")]
    return S


@card("Superheated Blades", "3", yaw=15, pitch=18, scale=2.0, foot=(64, 80))
def superheated_blades():
    """Two blades crossed, their edges glowing white-hot, heat shimmering off them."""
    S = []
    for sx in (-1, 1):
        R, by = rot_z(sx * 0.6), (0, 17, sx * 0.6)
        S += [moved(box((0, 2, 0), (1.6, 12, 0.4), "steel", r=0.2), by=by, R=R),
              moved(box((1.4, 2, 0), (0.5, 12, 0.5), "glow_orange", r=0.2), by=by, R=R),
              moved(box((1.6, 6, 0), (0.3, 7, 0.55), "glow_yellow", r=0.1), by=by, R=R),
              moved(box((0, -10.5, 0), (3.5, 1.0, 1.4), "brass", r=0.4), by=by, R=R),
              moved(capsule((0, -11.5, 0), (0, -16, 0), 1.2, "leather"), by=by, R=R)]
    for k in range(5):
        S.append(sphere((-6 + k * 3, 30 + (k % 2) * 3, 0), 0.6, "glow_amber"))
    return S


@card("Vantage Servo Harness", "3", yaw=200, pitch=18, scale=1.8, foot=(64, 82))
def servo_harness():
    """A harness seen from behind: a spine of servos, struts down to the hips, cables."""
    S = [cylinder((0, 0, 0), (0, 1.4, 0), 9, "graphite", 0.4)]
    for k in range(5):
        S += [box((0, 8 + k * 4.4, 0), (2.6, 1.6, 2.0), "vantage", r=0.6), sphere((0, 8 + k * 4.4, 2.4), 0.8, "brass")]
    for sx in (-1, 1):
        S += [capsule((0, 27, 0), (sx * 8, 27, 0), 1.0, "steel"), sphere((sx * 8, 27, 0), 1.8, "brass"),
              capsule((sx * 8, 27, 0), (sx * 6, 6, 0), 0.9, "steel"), box((sx * 6, 5, 0), (2.5, 2, 2), "graphite", r=0.6),
              capsule((sx * 2, 22, 2), (sx * 7, 10, 2.5), 0.4, "rubber")]
    S.append(sphere((0, 18, 2.6), 0.8, "glow_cyan"))
    return S


@card("Ballast Plate", "3", yaw=25, pitch=24, scale=2.2, foot=(64, 80))
def ballast_plate():
    """A thick plate of weight, chained and bolted, heavy enough to dent the deck."""
    S = [box((0, 3.5, 0), (10, 3.5, 7), "gunmetal", r=0.8), box((0, 7.4, 0), (8, 0.6, 5), "warning", r=0.2),
         box((0, 9, 0), (5, 1.4, 3), "steel", r=0.6), torus((0, 12, 0), 2.2, 0.6, "steel", R=rot_x(math.pi / 2))]
    for sx in (-1, 1):
        for sz in (-1, 1):
            S.append(cylinder((sx * 8, 7, sz * 5), (sx * 8, 8, sz * 5), 0.8, "brass", 0.2))
    for k in range(4):
        S.append(torus((0, 15 + k * 3, 0), 1.2, 0.45, "steel", R=rot_y(k * math.pi / 2) @ rot_x(math.pi / 2)))
    return S


@card("Dead Man's Grip", "3", yaw=30, pitch=20, scale=2.7, foot=(64, 76))
def dead_mans_grip():
    """A metal hand clamped shut on a trigger handle, its knuckles locked by a pin."""
    S = [box((0, 10, 0), (5.4, 4.2, 3.4), "steel", r=1.4), box((0, 4, 0), (4.4, 2.2, 3), "graphite", r=0.8)]
    for k in range(4):
        S.append(capsule((-4 + k * 2.6, 14, 2), (-4 + k * 2.6, 11, 5.2), 1.1, "steel"))
    S += [capsule((5, 10, 1), (7, 13, 4), 1.2, "steel"), cylinder((-7, 13, 4), (7, 13, 4), 1.2, "blood", 0.3),
          capsule((0, 2, 0), (0, -2, 0), 1.2, "rubber"), cylinder((6, 7, 0), (6, 7, 5), 0.6, "brass", 0.2),
          sphere((-5, 8, 3.5), 0.8, "glow_red")]
    return S


@card("Spool Governor", "3", yaw=25, pitch=24, scale=2.1, foot=(64, 80))
def spool_governor():
    """A cable spool with a spinning governor on its axle, the flyweights flung out."""
    S = [cylinder((-7, 10, 0), (-5.6, 10, 0), 9, "vantage", 0.5), cylinder((5.6, 10, 0), (7, 10, 0), 9, "vantage", 0.5),
         cylinder((-5.6, 10, 0), (5.6, 10, 0), 5.4, "steel", 0.4)]
    for k in range(8):
        S.append(torus((-4.9 + k * 1.4, 10, 0), 6.0, 0.7, "khaki", R=rot_z(math.pi / 2)))
    S += [cylinder((6, 10, 0), (12, 10, 0), 0.8, "brass", 0.2), capsule((12, 10, 0), (14, 14, 3), 0.4, "steel"),
          capsule((12, 10, 0), (14, 6, -3), 0.4, "steel"), sphere((14, 14, 3), 1.4, "brass"), sphere((14, 6, -3), 1.4, "brass"),
          box((0, 1.5, 0), (8, 1.5, 4), "graphite", r=0.4), capsule((-6, 10, 6), (-12, 2, 8), 0.5, "rubber")]
    return S


@card("Whisper Coil", "3", yaw=25, pitch=22, scale=2.2, foot=(64, 80))
def whisper_coil():
    """A coil of fine copper wire on a silenced barrel, a faint violet hum around it."""
    S = [cylinder((-12, 10, 0), (12, 10, 0), 2.4, "graphite", 0.6), cylinder((12, 10, 0), (16, 10, 0), 3.2, "graphite", 0.8)]
    for k in range(9):
        S.append(torus((-8 + k * 2, 10, 0), 3.0, 0.6, "brass", R=rot_z(math.pi / 2)))
    S += [box((-14, 7, 0), (2, 4, 1.4), "steel", r=0.6), box((0, 1, 0), (10, 1, 3), "graphite", r=0.4),
          capsule((-4, 15, 0), (4, 16, 0), 0.25, "glow_violet"), capsule((-6, 4, 2), (5, 3.5, 3), 0.25, "glow_violet")]
    return S


@card("Debt Ledger", "3", yaw=20, pitch=40, scale=2.2, foot=(64, 76))
def debt_ledger():
    """A data-slate ledger strapped open, columns of red figures, a brass stylus."""
    S = [box((0, 2, 0), (10, 1.0, 7), "gunmetal", r=0.8), box((0, 3.1, 0), (8.6, 0.2, 5.8), "onyx", r=0.1)]
    for row in range(5):
        S.append(box((-3, 3.4, -4.4 + row * 2.2), (4, 0.15, 0.4), "glow_mint", r=0.05))
        S.append(box((5, 3.4, -4.4 + row * 2.2), (1.6, 0.15, 0.4), "glow_red", r=0.05))
    S += [capsule((-12, 3, 6), (-2, 4.4, 9), 0.6, "brass"), box((0, 3.4, 6.8), (10.4, 0.4, 0.6), "leather", r=0.2),
          cylinder((9, 0, -6), (9, 4, -6), 2.0, "gold", 0.3), cylinder((9, 4, -6), (9, 6, -6), 2.0, "gold", 0.3)]
    return S


# ---------------------------------------------------------------- Actions
def targeting_eye(ring="glow_red", body="vantage", lens="glow_red", v2=False):
    """A targeting module: an optic on a swivel, a reticle projected in front of it."""
    S = [cylinder((0, 0, 0), (0, 2, 0), 6, "graphite", 0.4), cylinder((0, 2, 0), (0, 9, 0), 2, "steel", 0.4),
         box((0, 12, 0), (6, 4, 4.5), body, r=1.6), cylinder((0, 12, 4), (0, 12, 7), 3, "graphite", 0.6),
         cylinder((0, 12, 6.8), (0, 12, 7.4), 2.2, lens, 0.3)]
    if v2:
        S += [cylinder((-4.5, 15.5, 2), (-4.5, 15.5, 5.5), 1.2, "graphite", 0.3), sphere((-4.5, 15.5, 5.6), 0.8, lens),
              box((5.6, 14, 0), (0.4, 3.4, 3), "glow_cyan", r=0.1)]
    for r_ in (5.5, 3.0):
        S.append(torus((0, 12, 18), r_, 0.35, ring, R=rot_x(math.pi / 2)))
    S += [box((0, 12, 18), (0.3, 7.5, 0.3), ring, r=0.1), box((0, 12, 18), (7.5, 0.3, 0.3), ring, r=0.1)]
    return S


@card("Integrated Targeting System 2", "3", yaw=50, pitch=14, scale=2.0, foot=(52, 80))
def its_2():
    """The targeting module, single optic, its red reticle thrown ahead."""
    return targeting_eye()


@card("Integrated Targeting System V2", "3", yaw=50, pitch=14, scale=2.0, foot=(52, 80))
def its_v2():
    """The upgraded module: graphite body, a second optic and a rangefinder strip, a cyan reticle."""
    return targeting_eye(ring="glow_cyan", body="graphite", lens="glow_cyan", v2=True)


def subdermal(skin="sand", plate_mat="steel", glow="glow_cyan", v2=False):
    """An arm with the skin cut back on armour plates set beneath it."""
    S = [capsule((-16, 7, 0), (10, 10, 0), 4.6, skin), box((15, 10.5, 0), (3.6, 3.2, 3.4), skin, r=1.4),
         box((10.5, 10, 0), (1.0, 4.4, 4.4), "khaki", r=0.4)]
    for k in range(4):
        S.append(capsule((18, 12.5 - k * 1.7, 2.2), (19.4, 12.5 - k * 1.7, -0.6), 0.85, skin))
    S.append(box((-2, 13.2, 0), (11.5, 0.5, 3.8), "blood", r=0.3))
    for k in range(4):
        x = -9 + k * 5.6
        S += [box((x, 13.6, 0), (2.4, 0.8, 3.4), plate_mat, r=0.6), box((x + 2.6, 13.8, 0), (0.25, 0.5, 3.0), glow, r=0.1)]
    if v2:
        S += [capsule((-12, 13.6, 2.6), (10, 14.2, 2.6), 0.35, glow), box((0, 5, 4.6), (10, 1.0, 0.5), plate_mat, r=0.3)]
    S += [box((0, 1, 0), (16, 1, 6), "graphite", r=0.5)]
    return S


@card("Subdermal Armor Plating 2", "3", yaw=20, pitch=26, scale=2.0, foot=(64, 76))
def sap_2():
    """Plates sitting under a forearm's skin, cyan seams glowing between them."""
    return subdermal()


@card("Subdermal Armor Plating V2", "3", yaw=20, pitch=26, scale=2.0, foot=(64, 76))
def sap_v2():
    """The deeper plating: darker plates, a ridge under the arm, a seam of light along it."""
    return subdermal(skin="pale", plate_mat="gunmetal", glow="glow_violet", v2=True)


@card("Kickstart", "3", yaw=25, pitch=20, scale=2.0, foot=(64, 80))
def kickstart():
    """Defibrillator paddles crossing a jolt of current, the charge meter full."""
    S = [box((0, 4, 0), (8, 4, 5), "medic", r=1.0), box((0, 7, 5.2), (5, 1.4, 0.3), "glow_acid", r=0.2)]
    for sx in (-1, 1):
        S += [box((sx * 9, 18, 2), (3.4, 1.2, 2.6), "steel", r=0.6, R=rot_z(sx * 0.4)), capsule((sx * 9, 18, 2), (sx * 7, 23, 2), 1.0, "rubber"),
              capsule((sx * 4, 8, 0), (sx * 8, 17, 1), 0.5, "rubber")]
    S += arcs((-7, 17, 3), (7, 17, 3), 5, "glow_cyan", seed=11, jitter=1.8, r=0.4)
    S += arcs((-7, 17, 2), (7, 18, 2), 4, "glow_white", seed=12, jitter=1.2, r=0.25)
    return S


@card("Overclock Surge", "3", yaw=25, pitch=24, scale=2.0, foot=(64, 80))
def overclock_surge():
    """A processor board running hot: its core white, heat bars climbing off it."""
    S = [box((0, 2, 0), (12, 1.0, 9), "teal", r=0.4), box((0, 4, 0), (5, 1.4, 5), "graphite", r=0.6), box((0, 5.6, 0), (3.4, 0.3, 3.4), "glow_white", r=0.2)]
    for k in range(6):
        S.append(box((-10 + k * 4, 3.2, 7), (0.6, 0.3, 1.2), "gold", r=0.1))
        S.append(box((-10 + k * 4, 3.2, -7), (0.6, 0.3, 1.2), "gold", r=0.1))
    for k, h in enumerate((8, 13, 18, 14, 9)):
        S.append(box((-8 + k * 4, 6 + h / 2, -2), (1.0, h / 2, 0.5), ["glow_amber", "glow_orange", "glow_red", "glow_orange", "glow_amber"][k], r=0.2))
    return S


@card("Overpressure", "3", yaw=25, pitch=20, scale=1.9, foot=(64, 82))
def overpressure():
    """A pressure tank bursting at a seam, a jet of steam blasting sideways."""
    S = [capsule((0, 6, 0), (0, 20, 0), 7, "steel"), box((0, 13, 0), (7.3, 0.8, 7.3), "warning", r=0.3),
         cylinder((0, 26, 0), (0, 29, 0), 1.8, "brass", 0.4), cylinder((-4, 29, 0), (4, 29, 0), 0.8, "blood", 0.3),
         box((0, 1, 0), (9, 1, 9), "graphite", r=0.4)]
    for k in range(6):
        S.append(sphere((9 + k * 3.6, 17 + k * 0.8, 3), 1.6 + k * 0.6, "white" if k < 2 else "concrete"))
    return S


@card("Field Weld", "3", yaw=30, pitch=24, scale=2.0, foot=(64, 80))
def field_weld():
    """A welding torch closing a crack across a plate, sparks spraying off the bead."""
    S = [box((0, 3, 0), (12, 2, 8), "steel", r=0.6), box((-2, 5.2, 0), (6, 0.4, 0.6), "glow_orange", r=0.2),
         box((-8, 5.2, 0), (3.6, 0.3, 0.4), "onyx", r=0.1), capsule((4, 6, 0), (12, 16, 4), 1.4, "vantage"),
         cylinder((12, 16, 4), (14, 19, 5), 1.0, "brass", 0.3), sphere((4, 6, 0), 1.4, "glow_white"),
         capsule((14, 19, 5), (20, 22, 2), 0.5, "rubber")]
    rng = random.Random(4)
    for k in range(9):
        a = rng.uniform(0.3, 2.8)
        S.append(capsule((4, 6, 0), (4 + 9 * math.cos(a), 6 + 9 * math.sin(a), rng.uniform(-3, 5)), 0.25, "glow_yellow" if k % 2 else "glow_amber"))
    return S


# ---------------------------------------------------------------- Commands
def radio(at=(0, 0, 0), mat="khaki"):
    return [moved(box((0, 6, 0), (4, 6, 2.4), mat, r=1.0), by=at), moved(box((0, 8, 2.5), (2.6, 2, 0.2), "glow_mint", r=0.2), by=at),
            moved(capsule((2.6, 12, 0), (3.4, 21, 0), 0.4, "graphite"), by=at), moved(sphere((3.4, 21.4, 0), 0.7, "glow_red"), by=at)]


@card("Redline overdrive", "3", yaw=20, pitch=18, scale=2.1, foot=(64, 80))
def redline_overdrive():
    """A throttle slammed forward to the stops, the red lamp burning above it."""
    S = [box((0, 4, 0), (10, 4, 6), "graphite", r=1.0), box((0, 8.2, 0), (2, 0.3, 5), "onyx", r=0.1),
         capsule((0, 8, 4), (0, 18, 9), 1.0, "steel"), sphere((0, 18, 9), 2.4, "blood"),
         box((-6, 8.4, -4), (2, 0.4, 0.8), "warning", r=0.1), box((6, 8.4, -4), (2, 0.4, 0.8), "warning", r=0.1),
         cylinder((0, 14, -5), (0, 18, -5), 2.0, "glass", 0.4), sphere((0, 17, -5), 1.6, "glow_red")]
    for k in range(4):
        S.append(capsule((3 + k, 20 + k * 2, 9), (7 + k * 2, 20 + k * 2, 9), 0.35, "glow_red"))
    return S


@card("Reroute Power", "3", yaw=25, pitch=30, scale=1.9, foot=(64, 80))
def reroute_power():
    """A junction box opened up, a glowing cable pulled across to a new socket."""
    S = [box((0, 8, 0), (12, 8, 3), "steel", r=1.0), box((0, 8, 3.2), (11, 7, 0.3), "onyx", r=0.3)]
    for i in range(3):
        for j in range(2):
            S.append(cylinder((-7 + i * 7, 5 + j * 7, 3.2), (-7 + i * 7, 5 + j * 7, 4.4), 1.4, "brass", 0.3))
    pts = [(-7, 5, 4.4), (-4, 2, 8), (4, 14, 9), (7, 12, 4.4)]
    for a, b in zip(pts, pts[1:]):
        S.append(capsule(a, b, 0.7, "glow_amber"))
    S += [capsule((-7, 12, 4.4), (-10, 18, 7), 0.6, "rubber"), sphere((-10, 18, 7), 1.0, "graphite")]
    return S


@card("Recall", "3", yaw=20, pitch=22, scale=1.9, foot=(64, 82))
def recall():
    """A drop-pad lit up for a pull-out: a pillar of light rising, an arrow climbing it."""
    S = [cylinder((0, 0, 0), (0, 2, 0), 12, "graphite", 0.6), torus((0, 2, 0), 10, 0.6, "glow_cyan"),
         cylinder((0, 2, 0), (0, 36, 0), 6.5, "glass", 0.2)]
    S += [box((0, 22, 7), (1.2, 6, 0.4), "glow_white", r=0.2), box((0, 29, 7), (4.2, 0.9, 0.4), "glow_white", r=0.2),
          box((0, 31, 7), (2.4, 0.9, 0.4), "glow_white", r=0.2), box((0, 32.8, 7), (0.9, 0.9, 0.4), "glow_white", r=0.2)]
    for k in range(4):
        a = k * math.pi / 2 + 0.4
        S.append(box((10.5 * math.cos(a), 2.4, 10.5 * math.sin(a)), (1.2, 0.4, 1.2), "hazard", r=0.2))
    return S


@card("Ledger Call", "3", yaw=25, pitch=22, scale=2.1, foot=(64, 80))
def ledger_call():
    """A field radio on a strongbox of the Ledger, its channel lit, a coin on the lid."""
    S = [box((0, 4, 0), (9, 4, 6), "gunmetal", r=0.8), box((0, 4, 6.1), (2, 2, 0.3), "gold", r=0.3),
         cylinder((5, 8, -2), (5, 9, -2), 2.2, "gold", 0.3)] + radio((-3, 8, 0))
    for k in range(3):
        S.append(torus((-0.4, 29, 0), 2 + k * 2.2, 0.3, "glow_mint", R=rot_x(math.pi / 2)))
    return S


@card("Call the Note", "3", yaw=25, pitch=26, scale=2.9, foot=(70, 74))
def call_the_note():
    """A promissory note on a clipboard, stamped and sealed, a brass bell to call it in."""
    S = [box((0, 2, 0), (8, 0.8, 10), "leather", r=0.4), box((0, 3, 0), (6.6, 0.3, 8.6), "bone", r=0.1),
         box((0, 3.4, -9), (3, 1, 1), "steel", r=0.3)]
    for row in range(4):
        S.append(box((-1, 3.4, -5 + row * 2.4), (4.6, 0.12, 0.35), "ink", r=0.05))
    S += [cylinder((3, 3.2, 5), (3, 3.8, 5), 2.2, "blood", 0.3), cylinder((-12, 0, 2), (-12, 1, 2), 3.4, "graphite", 0.3),
          cone((-12, 1, 2), (-12, 8, 2), 3.2, 1.2, "brass"), sphere((-12, 9, 2), 1.0, "brass")]
    return S


@card("Tighten Ranks", "3", yaw=25, pitch=24, scale=1.6, foot=(64, 84))
def tighten_ranks():
    """Three shields locked edge to edge, a line drawn tight across them."""
    S = []
    for i, x in enumerate((-11, 0, 11)):
        S += [box((x, 11, 0), (5.4, 10, 1.4), "vantage" if i == 1 else "steel", r=1.6), box((x, 11, 1.5), (1.0, 7, 0.3), "hazard", r=0.2),
              box((x, 11, 1.5), (3.6, 1.0, 0.3), "hazard", r=0.2)]
    S += [capsule((-17, 18, 2), (17, 18, 2), 0.4, "glow_amber"), box((0, 0.6, 0), (18, 0.6, 3), "graphite", r=0.3)]
    return S


@card("Liquidate", "3", yaw=25, pitch=24, scale=2.0, foot=(64, 80))
def liquidate():
    """A stack of chips and coins melting down into a crucible of gold."""
    S = [cylinder((0, 0, 0), (0, 8, 0), 8, "graphite", 0.8), cylinder((0, 7.6, 0), (0, 8.2, 0), 6.6, "glow_amber", 0.3)]
    for k in range(4):
        S.append(cylinder((-3, 12 + k * 1.4, 0), (-3, 13 + k * 1.4, 0), 2.6, "gold", 0.3))
    S += [ellipsoid((-3, 10, 0), (2.8, 2, 2.8), "glow_amber"), cylinder((5, 9, 2), (5, 10, 2), 2.4, "gold", 0.3, ),
          sphere((5, 11.5, 2), 0.8, "glow_yellow")]
    for k in range(3):
        S.append(capsule((-9 + k * 2, 3, 7), (-9 + k * 2, 0.5, 9), 0.6, "glow_amber"))
    return S


# ---------------------------------------------------------------- Consumables
@card("Field Dressing", "3", yaw=25, pitch=28, scale=3.3, foot=(64, 72))
def field_dressing():
    """A roll of bandage half unwound, a clip and a sealed pad beside it."""
    S = [cylinder((-4, 4, -3), (-4, 4, 3), 4, "white", 0.4), cylinder((-4, 4, -3.1), (-4, 4, 3.1), 1.4, "bone", 0.2),
         box((5, 0.4, 0), (5, 0.4, 2.8), "white", r=0.2), box((-1, 2, 0), (2, 2, 2.8), "white", r=0.6),
         box((5, 1.2, 6), (3.4, 0.5, 3), "sack", r=0.3), box((5, 1.8, 6), (1.2, 0.2, 0.4), "blood", r=0.1),
         box((5, 1.8, 6), (0.4, 0.2, 1.2), "blood", r=0.1), capsule((9, 1, -2), (11, 1.4, -1), 0.4, "steel")]
    return S


@card("Repair Kit", "3", yaw=25, pitch=28, scale=2.0, foot=(64, 80))
def repair_kit():
    """An open repair case: a wrench, a driver, a spool of wire, a patch of plate."""
    S = [box((0, 3, 0), (11, 3, 7), "vantage", r=0.8), box((0, 5.4, 0), (10, 0.4, 6), "graphite", r=0.2),
         box((0, 12, -7.4), (11, 7, 0.6), "vantage", r=0.6, R=rot_x(-0.25)), box((0, 6.4, -6.6), (3, 0.5, 0.6), "steel", r=0.2),
         capsule((-8, 6.5, -3), (2, 6.5, -1), 0.7, "steel"), torus((3, 6.5, -1), 1.6, 0.6, "steel", R=rot_x(math.pi / 2)),
         capsule((-6, 6.5, 2), (4, 6.5, 3), 0.5, "brass"), capsule((4, 6.5, 3), (7, 6.5, 3.6), 0.9, "blood"),
         cylinder((7, 6, -3), (7, 8, -3), 2.0, "khaki", 0.3), box((-6, 6.6, 4), (2.6, 0.4, 1.6), "steel", r=0.2)]
    return S


@card("Medical Supplies", "3", yaw=30, pitch=24, scale=2.0, foot=(64, 80))
def medical_supplies():
    """A medic's crate, the cross on its side, vials and a syringe on top."""
    S = [box((0, 6, 0), (9, 6, 6), "white", r=1.0), box((0, 6, 6.1), (1.4, 4, 0.2), "blood", r=0.1),
         box((0, 6, 6.1), (4, 1.4, 0.2), "blood", r=0.1), box((0, 12.4, 0), (9.4, 0.6, 6.4), "graphite", r=0.3)]
    for k, mat in enumerate(("glow_mint", "glow_cyan", "glow_red")):
        S += [cylinder((-5 + k * 3, 13, -2), (-5 + k * 3, 17, -2), 1.0, "glass", 0.3), cylinder((-5 + k * 3, 13.4, -2), (-5 + k * 3, 15.6, -2), 0.7, mat, 0.2)]
    S += [capsule((2, 13.6, 2), (9, 13.6, 3), 0.8, "glass"), capsule((9, 13.6, 3), (11, 13.6, 3.3), 0.2, "steel")]
    return S


@card("Adrenal Shot", "3", yaw=25, pitch=18, scale=2.2, foot=(64, 76))
def adrenal_shot():
    """An autoinjector, its chamber full of glowing yellow, the needle cap off."""
    S = [capsule((-12, 12, 0), (8, 12, 0), 2.6, "steel"), cylinder((-6, 12, 0), (5, 12, 0), 2.7, "glass", 0.4),
         cylinder((-5, 12, 0), (4, 12, 0), 2.0, "glow_yellow", 0.4), box((-12, 12, 0), (1.2, 3.2, 3.2), "hazard", r=0.4),
         capsule((8, 12, 0), (13, 12, 0), 0.25, "silver"), cylinder((-2, 0, 4), (6, 1, 5), 1.0, "blood", 0.3),
         box((0, 1, 0), (14, 1, 5), "graphite", r=0.4)]
    return S


@card("Breach Charge", "3", yaw=25, pitch=22, scale=2.1, foot=(64, 80))
def breach_charge():
    """A shaped charge stuck on a door, its timer lit, wires taped down."""
    S = [box((0, 14, -2), (13, 14, 1.4), "gunmetal", r=0.6), box((0, 14, 0), (6, 6, 1.4), "olive", r=0.6),
         box((0, 14, 1.6), (3, 1.4, 0.4), "onyx", r=0.2), box((0, 14, 2.0), (2.2, 0.8, 0.2), "glow_red", r=0.1)]
    for sx in (-1, 1):
        S += [capsule((sx * 5, 18, 1.4), (sx * 9, 24, 0), 0.4, "blood" if sx < 0 else "blue")]
    S += [box((-6, 14, 1.4), (0.5, 6.4, 0.2), "khaki", r=0.1), box((6, 14, 1.4), (0.5, 6.4, 0.2), "khaki", r=0.1)]
    return S


@card("Signal Flare", "3", yaw=20, pitch=20, scale=2.2, foot=(60, 86))
def signal_flare():
    """A flare jammed in the deck, burning red, its smoke trail rising."""
    S = [cylinder((0, 0, 0), (0, 14, 0), 1.6, "blood", 0.3), cylinder((0, 0, 0), (0, 2, 0), 1.9, "graphite", 0.3),
         sphere((0, 15.5, 0), 2.6, "glow_red"), sphere((0, 15.5, 0), 1.3, "glow_white")]
    for k in range(6):
        S.append(sphere((math.sin(k) * 2.5 + k, 20 + k * 3.4, 0), 1.6 + k * 0.4, "rose" if k < 2 else "concrete"))
    for k in range(5):
        a = k * 1.3
        S.append(sphere((5 * math.cos(a), 13 + 3 * math.sin(a), 2), 0.5, "glow_orange"))
    return S


@card("Coolant Flush", "3", yaw=25, pitch=22, scale=2.0, foot=(64, 80))
def coolant_flush():
    """A coolant canister venting cold blue vapour from its nozzle."""
    S = [capsule((0, 4, 0), (0, 16, 0), 5, "white"), box((0, 10, 0), (5.2, 2, 5.2), "blue", r=0.6),
         cylinder((0, 20, 0), (0, 23, 0), 1.8, "steel", 0.4), capsule((0, 23, 0), (6, 25, 0), 0.8, "steel")]
    for k in range(7):
        S.append(sphere((8 + k * 3.0, 25 + k * 1.2 + (k % 2) * 1.5, (k % 3 - 1) * 1.5), 1.0 + k * 0.6, "glow_cyan" if k < 2 else "white"))
    S.append(ellipsoid((0, 0.2, 0), (9, 0.4, 7), "crystal"))
    return S


@card("Ration Pack", "3", yaw=25, pitch=28, scale=2.2, foot=(64, 80))
def ration_pack():
    """A torn-open ration pack: a tin, a bar, a canteen, the foil peeled back."""
    S = [box((0, 1.6, 0), (9, 1.6, 6), "olive", r=0.6), box((3, 3.6, -6), (6, 0.3, 2.4), "silver", r=0.1, R=rot_x(-0.5)),
         cylinder((-4, 3, 0), (-4, 7, 0), 2.6, "steel", 0.4), box((3, 3.6, 2), (4, 0.6, 1.6), "ochre", r=0.4),
         capsule((10, 2, -3), (10, 10, -3), 3, "khaki"), cylinder((10, 13, -3), (10, 14.4, -3), 1.2, "graphite", 0.3),
         box((-4, 7.2, 0), (1.2, 0.2, 0.4), "blood", r=0.1)]
    return S


@card("Grapple Line", "3", yaw=30, pitch=18, scale=1.9, foot=(64, 80))
def grapple_line():
    """A grapple gun, its hook flung up and biting a girder, the line pulled tight."""
    S = [box((-10, 8, 0), (5, 2.4, 2), "vantage", r=0.8), box((-12, 4, 0), (1.6, 3, 1.6), "graphite", r=0.5),
         cylinder((-5, 8.6, 0), (-1, 8.6, 0), 1.4, "graphite", 0.3), capsule((-1, 8.6, 0), (12, 30, 0), 0.3, "khaki")]
    for a in (-0.7, 0, 0.7):
        S.append(capsule((12, 30, 0), (12 + 3 * math.sin(a + math.pi / 4), 33 + 2 * math.cos(a), 2 * math.sin(a)), 0.6, "steel"))
    S.append(box((14, 33.6, 0), (12, 1.0, 1.6), "rust", r=0.3))
    return S


# ---------------------------------------------------------------- Prototypes
@card("Ledger Core", "3", yaw=25, pitch=22, scale=2.0, foot=(64, 80))
def ledger_core():
    """A gold-cased core in a cradle, figures scrolling round its band of light."""
    S = [box((0, 2, 0), (8, 2, 6), "graphite", r=0.6), sphere((0, 13, 0), 7, "gold"), torus((0, 13, 0), 7.3, 0.6, "glow_mint"),
         sphere((0, 13, 6.6), 1.4, "glow_amber")]
    for sx in (-1, 1):
        S.append(capsule((sx * 6, 3, 0), (sx * 7, 12, 0), 0.9, "steel"))
    for k in range(5):
        a = k * 2 * math.pi / 5
        S.append(box((10 * math.cos(a), 13 + (k % 2) * 2, 10 * math.sin(a)), (0.9, 0.4, 0.4), "glow_mint", r=0.1))
    return S


@card("Field Triage", "3", yaw=25, pitch=22, scale=1.8, foot=(64, 82))
def field_triage():
    """A prototype medic station on legs: a scanner arm over a cot, a cross lit on its post."""
    S = [box((0, 8, 0), (11, 1.0, 5), "white", r=0.6)]
    for sx in (-1, 1):
        for sz in (-1, 1):
            S.append(capsule((sx * 9, 8, sz * 4), (sx * 9, 0, sz * 4), 0.6, "steel"))
    S += [capsule((-12, 0, -4), (-12, 24, -4), 1.0, "steel"), capsule((-12, 24, -4), (0, 20, 0), 0.8, "steel"),
          cylinder((0, 20, 0), (0, 17, 0), 2.4, "medic", 0.4), cone((0, 17, 0), (0, 9.4, 0), 2.0, 6, "glass"),
          box((-12, 27, -4), (2.2, 0.7, 0.5), "glow_mint", r=0.1), box((-12, 27, -4), (0.7, 2.2, 0.5), "glow_mint", r=0.1)]
    return S


@card("Targeting Mesh", "3", yaw=20, pitch=24, scale=1.8, foot=(64, 84))
def targeting_mesh():
    """A drone projecting a mesh of red lines over the ground, a target at its heart."""
    S = drone((0, 30, 0), body="graphite", eye="glow_red", k=0.9)
    for k in range(-3, 4):
        S.append(capsule((k * 5, 1, -15), (k * 5, 1, 15), 0.2, "glow_red"))
        S.append(capsule((-15, 1, k * 5), (15, 1, k * 5), 0.2, "glow_red"))
    S += [torus((0, 1.2, 0), 4, 0.45, "glow_orange"), capsule((0, 28, 2), (-12, 1, 12), 0.15, "glow_red"), capsule((0, 28, 2), (12, 1, 12), 0.15, "glow_red")]
    return S


@card("Reinforced Frames", "3", yaw=30, pitch=20, scale=1.8, foot=(64, 82))
def reinforced_frames():
    """A bot's frame in a jig, cross-braces bolted on, a welded seam still glowing."""
    S = [box((0, 1, 0), (12, 1, 7), "graphite", r=0.4)]
    for sx in (-1, 1):
        S += [capsule((sx * 8, 2, 0), (sx * 8, 26, 0), 1.2, "steel")]
    for y in (6, 14, 22):
        S.append(capsule((-8, y, 0), (8, y, 0), 1.0, "steel"))
    S += [capsule((-8, 6, 0.8), (8, 22, 0.8), 0.9, "vantage"), capsule((8, 6, 0.8), (-8, 22, 0.8), 0.9, "vantage"),
          sphere((0, 14, 1.4), 1.4, "glow_orange")]
    for (x, y) in ((-8, 6), (8, 6), (-8, 22), (8, 22)):
        S.append(sphere((x, y, 1.2), 1.0, "brass"))
    return S


@card("Scavenger Protocol", "3", yaw=25, pitch=22, scale=1.8, foot=(64, 82))
def scavenger_protocol():
    """A small scavenger bot pincering a part out of a wreck, its bin half full."""
    S = [box((0, 6, 0), (6, 3.5, 4.5), "khaki", r=1.4), box((0, 10.6, -1), (4.6, 1.4, 3.4), "olive", r=0.6),
         sphere((0, 8, 4.6), 1.2, "glow_amber")]
    for sx in (-1, 1):
        S.append(cylinder((sx * 6.2, 3, -2), (sx * 6.2, 3, 2), 2.4, "rubber", 0.4) if False else cylinder((sx * 6, 3, 2.6), (sx * 7.2, 3, 2.6), 2.6, "rubber", 0.4))
        S.append(cylinder((sx * 6, 3, -2.6), (sx * 7.2, 3, -2.6), 2.6, "rubber", 0.4))
    S += [capsule((3, 9, 3), (8, 16, 7), 0.7, "steel"), capsule((8, 16, 7), (12, 10, 9), 0.7, "steel"),
          capsule((12, 10, 9), (13, 7, 8), 0.4, "steel"), capsule((12, 10, 9), (11, 7, 10), 0.4, "steel"),
          ellipsoid((14, 3, 10), (5, 3, 4), "slag"), torus((13, 6, 9), 1.6, 0.5, "brass", R=rot_x(1.2)),
          box((-2, 12.4, -1), (1.4, 0.8, 1.0), "steel", r=0.3), sphere((1.4, 12.6, -2), 0.8, "glow_red")]
    return S


@card("Overdrive Governor", "3", yaw=25, pitch=22, scale=2.0, foot=(64, 80))
def overdrive_governor():
    """A prototype governor: a spinning flyball over a hot block, glowing coils banded round it."""
    S = [box((0, 4, 0), (8, 4, 6), "vantage", r=1.0), box((0, 8.4, 0), (6, 0.6, 4.6), "hazard", r=0.2),
         cylinder((0, 8, 0), (0, 24, 0), 0.8, "steel", 0.2), cylinder((0, 22, 0), (0, 24, 0), 2.0, "brass", 0.3)]
    for sx in (-1, 1):
        S += [capsule((0, 23, 0), (sx * 7, 16, 0), 0.5, "steel"), sphere((sx * 7, 16, 0), 2.0, "brass")]
    for k in range(3):
        S.append(torus((0, 11 + k * 2.2, 0), 2.4, 0.5, "glow_orange"))
    return S


# ---------------------------------------------------------------- content batch 1 (0.22): District 3, fast melee
@card("Kinetic Surge", "3", yaw=25, pitch=22, scale=1.9, foot=(64, 80))
def kinetic_surge():
    """A flywheel spun up past its limit on a Vantage mount, streaks of motion flung off its rim."""
    S = [box((0, 2, 0), (10, 2, 6), "graphite", r=0.6), box((0, 4.4, 0), (8, 0.5, 4.6), "hazard", r=0.2),
         box((-7, 12, 0), (1.6, 8, 2.4), "vantage", r=0.6), box((7, 12, 0), (1.6, 8, 2.4), "vantage", r=0.6),
         cylinder((-6, 16, 0), (6, 16, 0), 1.0, "steel", 0.3),
         cylinder((-2.4, 16, 0), (2.4, 16, 0), 9.0, "gunmetal", 0.8), cylinder((-2.6, 16, 0), (2.6, 16, 0), 3.0, "brass", 0.4),
         torus((0, 16, 0), 9.0, 0.6, "glow_cyan", R=rot_z(math.pi / 2))]
    for k in range(7):
        a = k * 0.9
        S.append(capsule((0, 16 + 10 * math.sin(a), 10 * math.cos(a)), (0, 16 + 13 * math.sin(a + 0.5), 13 * math.cos(a + 0.5)), 0.35,
                         "glow_white" if k % 2 else "glow_cyan"))
    return S


@card("Gravity Well", "3", yaw=25, pitch=26, scale=1.9, foot=(64, 80))
def gravity_well():
    """A black sphere held in three rings, bolts and plate torn loose and falling in towards it."""
    S = [sphere((0, 16, 0), 5.0, "dark"), torus((0, 16, 0), 7.4, 0.5, "glow_violet"),
         torus((0, 16, 0), 9.4, 0.4, "glow_plasma", R=rot_x(1.1)), torus((0, 16, 0), 11.0, 0.35, "violet", R=rot_z(0.9)),
         box((0, 1, 0), (9, 1, 7), "graphite", r=0.4)]
    rng = random.Random(7)
    for k in range(8):
        a, d = k * 0.8, rng.uniform(13, 18)
        at = (d * math.cos(a), 16 + d * 0.5 * math.sin(a * 1.3), d * 0.6 * math.sin(a))
        S.append(box(at, (1.0, 0.6, 0.8), "steel" if k % 2 else "vantage", r=0.3, R=rot_z(a)))
        S.append(capsule(at, (at[0] * 0.75, 16 + (at[1] - 16) * 0.75, at[2] * 0.75), 0.2, "glow_violet"))
    return S


@card("Leaper Greaves", "3", yaw=55, pitch=16, scale=1.9, foot=(64, 84))
def leaper_greaves():
    """A pair of armoured greaves, a spring piston down the back of each, the heels shod for landing."""
    S = []
    for sx in (-1, 1):
        x = sx * 6
        S += [capsule((x, 6, 0), (x, 24, 0), 3.2, "vantage"), box((x, 16, 3.0), (2.6, 6, 0.8), "graphite", r=0.6),
              box((x, 22, 3.2), (2.2, 0.6, 0.5), "hazard", r=0.2), box((x, 2.4, 2.0), (3.4, 2.4, 5.0), "gunmetal", r=1.0),
              cylinder((x, 6, -4.0), (x, 22, -4.0), 1.2, "steel", 0.3), cylinder((x, 10, -4.0), (x, 18, -4.0), 1.6, "brass", 0.3),
              sphere((x, 23, -4.0), 1.3, "glow_cyan"), box((x, 0.6, 2.0), (3.6, 0.6, 5.2), "rubber", r=0.3)]
    return S


@card("Momentum Plating", "3", yaw=25, pitch=20, scale=2.0, foot=(64, 82))
def momentum_plating():
    """A chest plate on a stand, chevrons down its front lit amber, hotter the faster it goes."""
    S = [cylinder((0, 0, 0), (0, 2, 0), 6, "graphite", 0.4), capsule((0, 2, 0), (0, 10, 0), 1.0, "steel"),
         box((0, 18, 0), (8, 8, 3.4), "vantage", r=3.0), box((0, 18, 3.0), (5.6, 6.4, 0.8), "gunmetal", r=1.2)]
    for k, mat in enumerate(("glow_amber", "glow_orange", "glow_red")):
        y = 22 - k * 3.6
        S += [box((-2.0, y, 3.9), (2.6, 0.6, 0.3), mat, r=0.2, R=rot_z(-0.5)), box((2.0, y, 3.9), (2.6, 0.6, 0.3), mat, r=0.2, R=rot_z(0.5))]
    for sx in (-1, 1):
        S.append(ellipsoid((sx * 9.6, 24, 0), (3.0, 2.2, 3.2), "vantage"))
    return S


@card("Flank Them", "3", yaw=20, pitch=40, scale=1.8, foot=(64, 80))
def flank_them():
    """A holo-table: a red block in the middle, two cyan arrows curling round it from either side."""
    S = [box((0, 3, 0), (13, 3, 9), "graphite", r=0.8), box((0, 6.2, 0), (12, 0.3, 8), "navy", r=0.2),
         box((0, 8, -1), (2.6, 1.6, 2.0), "glow_red", r=0.4)]
    for sx in (-1, 1):
        pts = [(sx * 2, 7, 7), (sx * 7, 7, 5), (sx * 9, 7, 0), (sx * 7, 7, -4.6), (sx * 3.6, 7, -5.6)]
        for a, b in zip(pts, pts[1:]):
            S.append(capsule(a, b, 0.55, "glow_cyan"))
        S.append(cone((sx * 3.6, 7, -5.6), (sx * 1.0, 7, -4.0), 1.4, 0.1, "glow_cyan"))
    return S


@card("Pin the Runner", "3", yaw=30, pitch=22, scale=2.7, foot=(64, 80))
def pin_the_runner():
    """A bolas of weighted cable wrapped round a skitter-bot's leg, the leg pinned to the deck."""
    S = [box((0, 1, 0), (12, 1, 7), "steel", r=0.4),
         ellipsoid((-12, 14, -2), (4.0, 2.6, 3.4), "vantage"), sphere((-9, 14, 1.6), 0.9, "glow_amber"),
         capsule((-10, 12, -2), (-2, 14, 0), 1.0, "graphite"), sphere((-2, 14, 0), 1.3, "vantage"), capsule((-2, 14, 0), (4, 2.4, 1), 0.8, "steel"),
         torus((1.6, 7.0, 0.6), 1.6, 0.4, "rubber", R=rot_z(0.6)), torus((2.6, 5.0, 0.8), 1.5, 0.4, "rubber", R=rot_z(0.6))]
    for at in ((7, 3, 4), (9, 2.4, -3), (5, 2.4, -5)):
        S += [capsule((2.2, 6, 0.7), at, 0.3, "rubber"), sphere(at, 1.6, "gunmetal"), sphere((at[0], at[1] + 1.0, at[2]), 0.5, "glow_red")]
    return S


@card("Grav-Boot Charge", "3", yaw=30, pitch=22, scale=2.2, foot=(64, 80))
def grav_boot_charge():
    """A cartridge of compressed lift, violet through its window, clicking into a boot's heel."""
    S = [box((-4, 4, 0), (7, 4, 4), "gunmetal", r=1.6), box((-9, 10, 0), (2.6, 6, 3.6), "vantage", r=1.0), box((-4, 0.6, 0), (7.4, 0.6, 4.4), "rubber", r=0.3),
         cylinder((6, 3, 0), (14, 3, 0), 2.4, "steel", 0.6), cylinder((8, 3, 0), (12, 3, 0), 2.5, "glass", 0.4),
         cylinder((8.4, 3, 0), (11.6, 3, 0), 1.8, "glow_violet", 0.3), box((14.6, 3, 0), (0.6, 1.6, 1.6), "hazard", r=0.2)]
    return S


@card("Adrenal Overdrive", "3", yaw=25, pitch=20, scale=2.1, foot=(64, 80))
def adrenal_overdrive():
    """A double injector, both chambers glowing red, its dial turned past the line."""
    S = [box((0, 1, 0), (14, 1, 6), "graphite", r=0.4)]
    for z in (-2.6, 2.6):
        S += [capsule((-12, 10, z), (8, 10, z), 2.2, "steel"), cylinder((-6, 10, z), (5, 10, z), 2.3, "glass", 0.4),
              cylinder((-5, 10, z), (4, 10, z), 2.4, "glow_red", 0.3), capsule((8, 10, z), (13, 10, z), 0.22, "silver")]
    S += [box((-12, 10, 0), (1.4, 3.0, 5.2), "hazard", r=0.4), cylinder((-12, 14, 0), (-12, 15, 0), 2.0, "onyx", 0.3),
          box((-12, 15.2, 1.2), (0.3, 0.2, 1.2), "glow_amber", r=0.1)]
    return S


@card("Vault Strike", "3", yaw=30, pitch=18, scale=1.9, foot=(64, 84))
def vault_strike():
    """A blade coming down at the end of a jump, the arc of the leap traced behind it."""
    R = rot_z(-0.7)
    S = [moved(capsule((0, 0, 0), (0, 22, 0), 1.0, "silver"), by=(4, 6, 0), R=R), moved(box((0, 0, 0), (3.4, 0.8, 1.6), "brass", r=0.3), by=(4, 6, 0), R=R),
         moved(capsule((0, -1, 0), (0, -6, 0), 0.9, "leather"), by=(4, 6, 0), R=R),
         box((0, 1, 0), (14, 1, 6), "steel", r=0.4)]
    for k in range(9):
        a = math.pi * k / 8
        S.append(sphere((-18 + 18 * (1 - math.cos(a)) * 0.6, 4 + 22 * math.sin(a) * 0.7, 0), 0.5 + 0.1 * k, "glow_cyan" if k % 2 else "glow_white"))
    S += arcs((14, 2, 0), (20, 2, 2), 3, "glow_amber", seed=3, jitter=1.2, r=0.3)
    return S


@card("Skitter Step", "3", yaw=35, pitch=20, scale=1.9, foot=(64, 82))
def skitter_step():
    """Three jointed legs mid-stride, their old places left as streaks on the deck."""
    S = [box((0, 1, 0), (14, 1, 7), "steel", r=0.4)]
    for k, x in enumerate((-8, 0, 8)):
        hip, knee, foot = (x - 2, 20, 0), (x + 2, 15, 1), (x + 4, 2.4, 0)
        S += [capsule(hip, knee, 1.2, "vantage"), sphere(knee, 1.4, "graphite"), capsule(knee, foot, 0.9, "steel", r2=0.5)]
        for j in range(3):
            S.append(capsule((x - 3 - j * 3, 2.4, 0.4 * j), (x + 2 - j * 3, 2.4, 0.4 * j), 0.3, "glow_cyan" if j == 0 else "glow_blue"))
    S.append(capsule((-12, 20, 0), (12, 20, 0), 1.6, "graphite"))
    return S


@card("Kinetic Recycler", "3", yaw=25, pitch=22, scale=1.9, foot=(64, 82))
def kinetic_recycler():
    """A prototype on a test rig: a turbine in a cage of coils, cables trailing from it, half its casing off."""
    S = [box((0, 1.4, 0), (11, 1.4, 7), "graphite", r=0.4), cylinder((0, 3, 0), (0, 20, 0), 5, "gunmetal", 0.8),
         cylinder((0, 6, 0), (0, 17, 0), 5.2, "glass", 0.4), cylinder((0, 8, 0), (0, 15, 0), 3.2, "glow_mint", 0.3)]
    for k in range(4):
        y = 7 + k * 2.6
        S.append(torus((0, y, 0), 6.0, 0.5, "brass", R=rot_x(math.pi / 2)))
    S += [capsule((5, 4, 4), (11, 2, 7), 0.5, "rubber"), capsule((-5, 4, 4), (-12, 2, 3), 0.5, "glow_amber"),
          box((7, 21, 0), (2.6, 0.6, 3.6), "vantage", r=0.3, R=rot_z(-0.6)), box((0, 3, 5.6), (2.4, 1.2, 0.3), "warning", r=0.2)]
    return S


@card("Gantry Mapper", "3", yaw=25, pitch=24, scale=1.9, foot=(64, 82))
def gantry_mapper():
    """A tripod scanner throwing a grid of light across the gantries, a gap in it marked red."""
    S = [box((0, 0.6, 0), (14, 0.6, 8), "steel", r=0.3)]
    for a in (0.0, 2.1, 4.2):
        S.append(capsule((0, 12, 0), (5 * math.cos(a), 1, 5 * math.sin(a)), 0.5, "graphite"))
    S += [box((0, 14, 0), (3.0, 2.0, 2.4), "vantage", r=0.8), sphere((0, 14, 2.6), 1.2, "glow_cyan")]
    for k in range(-2, 3):
        S.append(capsule((k * 4, 1.4, 4), (k * 4, 1.4, -6), 0.2, "glow_cyan"))
        S.append(capsule((-9, 1.4, k * 2.4 - 1), (9, 1.4, k * 2.4 - 1), 0.2, "glow_cyan"))
    S.append(box((6, 1.5, 3), (2.0, 0.1, 1.2), "glow_red", r=0.1))
    return S


def render_card(name, seed=None):
    """A card's picture: its backdrop, then its thing over it (128 by 90, palette indices)."""
    c = CARDS[name]
    bg = backdrop("3" if c["d"] == "3" else "", seed if seed is not None else sum(map(ord, name)))
    img = make(c["fn"](), size=(W, H), foot=c["foot"], pitch=c["pitch"], yaw=c["yaw"], scale=c["scale"], inner_step=1.4)
    return np.where(img > 0, img, bg)


if __name__ == "__main__":
    import sys
    names = sys.argv[1:] or list(CARDS)
    pics = [render_card(n) for n in names]
    sheet(pics, preview_path("card_art.png"), scale=2, labels=names, cols=6, show1x=False)
    print("ok", len(pics))
