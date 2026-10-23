"""Each District's fights (0.15): its own floor, five plates of it (42 x 48,
as tiles.py's), and its own Half and Full Cover (48 x 48, as props.py's).
Hazards, spawn pads, crates, chests, exits and Healing Stations stay the
same in every District, and a floor with no District keeps the grey deck.

  District 1 · Threshold Dynamics  frosted lab plating; toppled consoles; containment pylons
  District 2 · Halcyon Cognition   dim white tile; barricades of desks; amplifier pylons
  District 3 · Vantage Robotics    hazard-striped factory deck; parts bins; assembly frames
  District 4 · Lazarus Computing   server floor with cable trenches; cooling units; server racks
  District 5 · Verdant Biogenics   grating overgrown with roots; thick roots; cracked vats
  District 6 · Meridian Entropics  plates crumbling to ash; rubble heaps; broken machine hulks"""
import math, random
import numpy as np
from kart import *
from rigs import *
import tiles
from tiles import W, H, MASK, UL, LR, px, hline, disc
material("frosted", ["3a2f3e", "654370", "9c8bdb", "c9d4fd", "f1f2ff"], hi="ffffff", gloss=0.4)

FLOOR = {}        # (district, n) -> fn
COVER = {}        # (district, "half"|"full") -> {fn, foot, pitch, scale, yaw}


def floor(d, n):
    def deco(fn):
        FLOOR[(d, n)] = fn
        return fn
    return deco


def cover(d, kind, foot=(24, 38), pitch=45, scale=1.0, yaw=0, inner=0.8):
    def deco(fn):
        COVER[(d, kind)] = {"fn": fn, "foot": foot, "pitch": pitch, "scale": scale, "yaw": yaw, "inner": inner}
        return fn
    return deco


def render_cover(d, kind):
    p = COVER[(d, kind)]
    return make(p["fn"](), size=48, foot=p["foot"], yaw=p["yaw"], pitch=p["pitch"], scale=p["scale"], inner_step=p["inner"])


def plate(fill, lite, dark):
    a = np.zeros((H, W), np.int32)
    a[MASK] = idx(fill)
    a[UL] = idx(lite)
    a[LR] = idx(dark)
    return a


def speckle(a, seed, colours, share):
    r = random.Random(seed)
    for y in range(H):
        for x in range(W):
            if MASK[y, x] and not UL[y, x] and not LR[y, x] and r.random() < share:
                a[y, x] = idx(r.choice(colours))


def blob(a, seed, cx, cy, rx, ry, colours, rough=0.25):
    """A soft patch: its heart in the first colour, ragged at its edge."""
    r = random.Random(seed)
    for y in range(H):
        for x in range(W):
            if not MASK[y, x]:
                continue
            d = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
            d += (r.random() - 0.5) * rough
            if d < 0.45:
                a[y, x] = idx(colours[0])
            elif d < 1.0:
                a[y, x] = idx(colours[min(1, len(colours) - 1)])


def wander(a, seed, start, steps, colours, width=1, drift=0.5, step=1.0):
    """A line that wanders across (a root, a crack): dark under, lit on top."""
    r = random.Random(seed)
    x, y = start
    ang = r.uniform(-0.3, 0.3)
    for _ in range(steps):
        for w in range(-width, width + 1):
            px(a, int(x), int(y + w), colours[0] if w < 0 or width == 0 else colours[min(len(colours) - 1, 1 + (w > 0))])
        ang += r.uniform(-drift, drift)
        ang = max(-0.9, min(0.9, ang))
        x += step * math.cos(ang)
        y += step * math.sin(ang)


# ================================================================ 5 · Verdant Biogenics
G5 = ("2c3b39", "486859", "14121d")          # the grating's plate: fill, lit rim, dark rim


def grating(a, top=12, bottom=36, gap=3):
    for y in range(top, bottom, gap):
        hline(a, 6, 35, y, "171819")


def sprouts(a, seed, n):
    r = random.Random(seed)
    for k in range(n):
        x, y = r.randint(9, 32), r.randint(14, 34)
        px(a, x, y, "42a459"); px(a, x, y - 1, "61a53f"); px(a, x - 1, y - 1, "3d6f43")


@floor("5", 0)
def v_grating():
    a = plate(*G5)
    grating(a)
    return a


@floor("5", 1)
def v_sprouts():
    a = plate(*G5)
    grating(a)
    sprouts(a, "v1", 5)
    return a


@floor("5", 2)
def v_moss():
    a = plate(*G5)
    grating(a)
    blob(a, "v2", 13, 31, 9, 6, ["3d6f43", "27412d"], rough=1.1)
    sprouts(a, "v2s", 2)
    px(a, 14, 29, "f6a2a8")
    return a


@floor("5", 4)
def v_root():
    a = plate(*G5)
    grating(a)
    wander(a, "v1", (2, 21), 40, ["452a1b", "724b2c", "8c5b3e"], width=1, drift=0.35)
    wander(a, "v1", (2, 22), 40, ["452a1b", "724b2c", "8c5b3e"], width=1, drift=0.35)
    sprouts(a, "v3s", 2)
    return a


@floor("5", 3)
def v_overgrown():
    a = plate(*G5)
    grating(a)
    blob(a, "v4", 21, 24, 15, 14, ["27412d", "2c3b39"], rough=1.2)
    blob(a, "v4b", 18, 22, 8, 7, ["3d6f43", "27412d"], rough=1.2)
    sprouts(a, "v4s", 3)
    for x, y, c in ((12, 18, "f6a2a8"), (25, 14, "fff089")):
        px(a, x, y, c)
    return a


@cover("5", "half", foot=(24, 38), pitch=45, scale=1.25)
def thick_roots():
    """Roots as thick as a body, arched up out of the grating."""
    S = []
    for k, (x0, x1, h, rr) in enumerate(((-14.0, 2.0, 7.0, 2.2), (-4.0, 13.0, 8.5, 2.6), (6.0, 15.0, 5.0, 1.8))):
        pts = [(x0 + (x1 - x0) * t, math.sin(t * math.pi) * h, (k - 1) * 2.4 + math.sin(t * 5.0) * 0.8) for t in np.linspace(0, 1, 7)]
        for i in range(len(pts) - 1):
            S.append(capsule(pts[i], pts[i + 1], rr * (1.0 - 0.15 * abs(0.5 - i / 6.0)), "leather"))
    S.append(ellipsoid((-3.0, 8.8, 0.0), (3.4, 1.2, 2.6), "jade"))
    S.append(ellipsoid((8.0, 9.8, -1.0), (2.6, 1.0, 2.2), "jade"))
    S.append(sphere((-5.0, 10.0, 1.5), 0.9, "rose"))
    return S


@cover("5", "full", foot=(24, 44), pitch=38, scale=1.0)
def cracked_vats():
    """A pair of growth vats, one cracked and leaking, the jungle up their sides."""
    material("vatglass", ["14121d", "2c3b39", "5d9b79", "97edca", "d0ffea"], hi="f1f2ff", gloss=1.0)
    S = []
    for k, (x, z, full) in enumerate(((-6.5, -1.0, 13.0), (6.5, 1.0, 7.0))):
        S.append(cylinder((x, 0, z), (x, 3.0, z), 6.6, "gunmetal", round_=0.6))
        S.append(cylinder((x, 3.0, z), (x, 3.0 + full, z), 5.4, "acid", round_=0.3))
        S.append(cylinder((x, 3.0 + full, z), (x, 24.0, z), 5.4, "vatglass", round_=0.3))
        S.append(cylinder((x, 24.0, z), (x, 26.4, z), 6.2, "gunmetal", round_=0.6))
        for a in (0.4, 2.5, 4.6):
            S.append(capsule((x + 5.9 * math.cos(a), 3.0, z + 5.9 * math.sin(a)), (x + 5.9 * math.cos(a), 24.0, z + 5.9 * math.sin(a)), 0.5, "gunmetal"))
    S.append(box((8.8, 17.0, 6.2), (0.35, 4.0, 0.4), "dark", R=rot_z(0.45)))
    S.append(ellipsoid((9.0, 0.6, 8.0), (5.0, 0.6, 3.0), "acid"))
    for k in range(7):
        a = k * 1.1
        S.append(ellipsoid((-6.5 + 5.6 * math.cos(a), 2.0 + k * 3.0, -1.0 + 5.6 * math.sin(a)), (2.0, 1.1, 2.0), "jade"))
    return S


# ================================================================ shared touches
def vline(a, x, y0, y1, c):
    for y in range(y0, y1 + 1):
        px(a, x, y, c)


def seam_cross(a, dark, lite, y=24, x=21):
    hline(a, 3, 38, y, dark); hline(a, 3, 38, y + 1, lite)
    vline(a, x, 6, 42, dark); vline(a, x + 1, 6, 42, lite)


def rivets(a, pts, lit="6a7178", shade="14121d"):
    for x, y in pts:
        px(a, x, y, lit); px(a, x + 1, y + 1, shade)


# ================================================================ 1 · Threshold Dynamics: frosted lab plating
G1 = ("3a2f3e", "654370", "14121d")


def frost_patch(a, seed, cx, cy, size):
    r = random.Random(seed)
    for y in range(H):
        for x in range(W):
            if not MASK[y, x] or UL[y, x] or LR[y, x]:
                continue
            d = math.hypot(x + 0.5 - cx, (y + 0.5 - cy) * 1.1) + (r.random() - 0.5) * 2.0
            if d < size * 0.4:
                a[y, x] = idx("c9d4fd" if r.random() < 0.6 else "f1f2ff")
            elif d < size * 0.75 and r.random() < 0.55:
                a[y, x] = idx("9c8bdb" if r.random() < 0.6 else "c9d4fd")
            elif d < size and r.random() < 0.18:
                a[y, x] = idx("7864c6")


@floor("1", 0)
def t_plain():
    a = plate(*G1)
    seam_cross(a, "14121d", "4e4054")
    rivets(a, ((8, 14), (33, 14), (8, 33), (33, 33)), "654370")
    return a


@floor("1", 3)
def t_frost():
    a = plate(*G1)
    seam_cross(a, "14121d", "4e4054")
    frost_patch(a, "t1", 11, 33, 11)
    return a


@floor("1", 1)
def t_crystals():
    a = plate(*G1)
    hline(a, 3, 38, 18, "14121d"); hline(a, 3, 38, 19, "4e4054")
    r = random.Random("t2")
    for k in range(9):                                   # little hexagons of frost, scattered
        x, y = r.randint(9, 32), r.randint(12, 36)
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            px(a, x + dx, y + dy, "9c8bdb")
        px(a, x, y, "f1f2ff")
    return a


@floor("1", 2)
def t_vent():
    a = plate(*G1)
    disc(a, 21, 24, 9, 8, "14121d")
    disc(a, 21, 24, 9, 8, "654370", ring=True)
    for k in (-4, 0, 4):
        hline(a, 15, 27, 24 + k, "8a3dff")
    px(a, 21, 24, "c23bff")
    return a


@floor("1", 4)
def t_rift():
    a = plate(*G1)
    seam_cross(a, "14121d", "4e4054")
    wander(a, "t4", (8, 30), 26, ["8a3dff", "c23bff", "8a3dff"], width=0, drift=0.6)
    frost_patch(a, "t4f", 31, 16, 7)
    return a


@cover("1", "half", foot=(24, 38), pitch=45, scale=1.2)
def toppled_consoles():
    """Lab consoles, toppled, their screens still lit."""
    S = [moved(box((0, 0, 0), (7.0, 3.0, 4.4), "steel", r=0.8), by=(-6.0, 3.0, 0), R=rot_z(0.15)),
         moved(box((0, 0, 0), (5.0, 2.2, 0.3), "glow_violet", r=0.2), by=(-6.0, 4.0, 4.4), R=rot_z(0.15)),
         moved(box((0, 0, 0), (5.0, 4.0, 3.6), "steel", r=0.8), by=(7.0, 3.6, -1.0), R=rot_y(0.5)),
         moved(box((0, 0, 0), (3.6, 2.4, 0.3), "glass", r=0.2), by=(8.6, 4.4, 2.0), R=rot_y(0.5)),
         sphere((-2.0, 6.0, 2.0), 1.4, "frosted"), sphere((4.0, 7.6, 1.0), 1.1, "frosted")]
    return S


@cover("1", "full", foot=(24, 44), pitch=38, scale=1.0)
def containment_pylons():
    """Two containment pylons, a field of violet light hung between them."""
    S = []
    for x in (-9.0, 9.0):
        S.append(cylinder((x, 0, 0), (x, 2.0, 0), 4.0, "graphite", round_=0.4))
        S.append(cone((x, 2.0, 0), (x, 24.0, 0), 2.8, 1.6, "steel"))
        S.append(sphere((x, 25.0, 0), 2.2, "frosted"))
        for y in (8.0, 15.0, 21.0):
            S.append(torus((x, y, 0), 2.7, 0.5, "glow_violet"))
    for y in (6.0, 10.0, 14.0, 18.0, 22.0):                                  # the field, in bands of light
        S.append(box((0, y, 0), (6.6, 0.45, 0.25), "glow_violet" if y != 14.0 else "glow_plasma", r=0.1))
    return S


# ================================================================ 2 · Halcyon Cognition: dim white tile
G2 = ("464762", "9a97b9", "14121d")


def tiles_grid(a, light="696682", grout="464762", size=8, ox=1, oy=2):
    for y in range(H):
        for x in range(W):
            if not MASK[y, x] or UL[y, x] or LR[y, x]:
                continue
            if (x + ox) % size == 0 or (y + oy) % size == 0:
                a[y, x] = idx(grout)
            else:
                a[y, x] = idx(light)


@floor("2", 0)
def h_tiles():
    a = plate(*G2)
    tiles_grid(a)
    return a


@floor("2", 1)
def h_cracked():
    a = plate(*G2)
    tiles_grid(a)
    wander(a, "h1", (10, 14), 20, ["36282b"], width=0, drift=0.8)
    wander(a, "h1b", (22, 30), 14, ["36282b"], width=0, drift=0.8)
    return a


@floor("2", 3)
def h_stain():
    a = plate(*G2)
    tiles_grid(a)
    blob(a, "h2", 25, 28, 8, 6, ["d480bb", "c090a9"], rough=1.0)
    px(a, 25, 28, "ff3d7f"); px(a, 26, 28, "ff3d7f")
    return a


@floor("2", 4)
def h_sums():
    a = plate(*G2)
    tiles_grid(a)
    r = random.Random("h3")
    for row in (13, 20, 27, 34):                         # sums, scrawled to keep a mind scattered
        x = r.randint(8, 13)
        while x < 32:
            n = r.randint(2, 4)
            hline(a, x, x + n, row, "e3cddf")
            if r.random() < 0.5:
                px(a, x + n // 2, row - 1, "e3cddf"); px(a, x + n // 2, row + 1, "e3cddf")
            x += n + r.randint(2, 4)
    return a


@floor("2", 2)
def h_drain():
    a = plate(*G2)
    tiles_grid(a)
    disc(a, 21, 25, 5, 4, "36282b")
    for k in (-2, 0, 2):
        hline(a, 18, 24, 25 + k, "14121d")
    return a


@cover("2", "half", foot=(24, 38), pitch=45, scale=1.2)
def desk_barricade():
    """Desks on their sides, a chair jammed between: a barricade."""
    S = [moved(box((0, 0, 0), (7.0, 4.0, 0.8), "white", r=0.4), by=(-6.0, 4.0, 0), R=rot_y(0.2)),
         moved(box((0, 0, 0), (6.0, 3.6, 0.8), "white", r=0.4), by=(7.0, 3.6, -1.0), R=rot_y(-0.3)),
         moved(box((0, 0, 0), (2.4, 0.6, 2.4), "graphite", r=0.3), by=(1.0, 7.4, -1.0), R=rot_z(0.6)),
         capsule((0.0, 0.0, -1.0), (1.0, 6.6, -1.0), 0.5, "steel"),
         box((-6.0, 7.6, 0.2), (2.0, 0.6, 0.3), "glow_pink", r=0.1)]
    for x in (-11.0, -1.0, 3.0, 12.0):
        S.append(capsule((x, 0, -2.6), (x, 3.0, -2.0), 0.45, "steel"))
    return S


@cover("2", "full", foot=(24, 44), pitch=36, scale=1.0)
def amplifier_pylon_big():
    """A psionic amplifier: white, ringed in pink light, humming."""
    S = [cylinder((0, 0, 0), (0, 2.6, 0), 7.0, "white", round_=0.8),
         cone((0, 2.6, 0), (0, 27.0, 0), 3.4, 1.4, "white"),
         capsule((0, 26.0, 0), (0, 31.0, 0), 0.6, "steel"),
         sphere((0, 31.6, 0), 1.8, "glow_magenta")]
    for y, rr in ((9.0, 5.2), (16.0, 4.4), (22.5, 3.4)):
        S.append(torus((0, y, 0), rr, 0.7, "glow_pink"))
    return S


# ================================================================ 3 · Vantage Robotics: hazard-striped factory deck
G3 = ("4f342f", "8c5b3e", "14121d")


def hazard_band(a, y0, y1):
    for y in range(y0, y1 + 1):
        for x in range(W):
            if MASK[y, x] and not UL[y, x] and not LR[y, x]:
                a[y, x] = idx("f8c53a" if ((x + y) // 3) % 2 == 0 else "271f1b")


@floor("3", 0)
def v_plate():
    a = plate(*G3)
    seam_cross(a, "271f1b", "673931")
    rivets(a, ((8, 14), (33, 14), (8, 33), (33, 33)), "b28b78", "271f1b")
    return a


@floor("3", 4)
def v_band():
    a = plate(*G3)
    hazard_band(a, 34, 37)
    hline(a, 3, 38, 33, "271f1b")
    rivets(a, ((10, 16), (31, 16)), "b28b78", "271f1b")
    return a


@floor("3", 2)
def v_oil():
    a = plate(*G3)
    seam_cross(a, "271f1b", "673931")
    for y in range(H):
        for x in range(W):
            if not MASK[y, x] or UL[y, x] or LR[y, x]:
                continue
            d = ((x + 0.5 - 16) / 10.0) ** 2 + ((y + 0.5 - 30) / 5.0) ** 2
            if d < 0.55 or (d < 1.0 and (x + y) % 2 == 0):
                a[y, x] = idx("271f1b")
    px(a, 12, 29, "4f342f"); px(a, 13, 29, "5e718e")
    return a


@floor("3", 3)
def v_keepclear():
    a = plate(*G3)
    for x in range(11, 31):                              # a painted "keep clear" box, worn
        if (x // 2) % 2 == 0:
            px(a, x, 15, "d6a851"); px(a, x, 33, "d6a851")
    for y in range(15, 34):
        if (y // 2) % 2 == 0:
            px(a, 11, y, "d6a851"); px(a, 30, y, "d6a851")
    speckle(a, "v3w", ["4f342f"], 0.06)
    return a


@floor("3", 1)
def v_grate():
    a = plate(*G3)
    for y in range(12, 37, 3):
        hline(a, 7, 34, y, "271f1b")
    for x in range(9, 34, 6):
        vline(a, x, 11, 37, "673931")
    return a


@cover("3", "half", foot=(24, 38), pitch=45, scale=1.2)
def parts_bins():
    """Parts bins in Vantage orange, full of what the line was making."""
    S = []
    for x, z, a in ((-7.0, 0.0, 0.1), (5.0, -1.0, -0.15), (13.0, 1.0, 0.25)):
        S.append(moved(hollow(box((0, 3.0, 0), (4.0, 3.0, 3.4), "vantage", r=0.4), box((0, 4.4, 0), (3.4, 3.0, 2.8), "vantage")), by=(x, 0, z), R=rot_y(a)))
        for k in range(3):
            S.append(sphere((x - 1.6 + k * 1.6, 5.4, z + (k - 1) * 0.6), 1.2, ["steel", "brass", "graphite"][k]))
    S.append(box((-7.0, 3.0, 3.6), (2.0, 0.8, 0.2), "warning", r=0.1))
    return S


@cover("3", "full", foot=(24, 44), pitch=38, scale=1.0)
def assembly_frame():
    """An assembly frame, a half-built frame hung in it."""
    S = []
    for x in (-10.0, 10.0):
        S.append(box((x, 12.0, 0), (1.2, 12.0, 1.2), "vantage", r=0.3))
        S.append(box((x, 0.8, 0), (2.4, 0.8, 2.4), "graphite", r=0.3))
    S.append(box((0, 24.0, 0), (11.4, 1.3, 1.6), "vantage", r=0.3))
    S.append(box((0, 25.5, 0), (11.4, 0.3, 1.7), "warning", r=0.1))
    S.append(capsule((0, 23.0, 0), (0, 19.0, 0), 0.4, "graphite"))
    S.append(ellipsoid((0, 14.0, 0), (5.0, 5.0, 3.4), "steel"))                 # the frame being built
    S.append(capsule((-4.0, 13.0, 0), (-6.0, 7.0, 1.0), 1.0, "graphite"))
    S.append(capsule((4.0, 13.0, 0), (6.0, 7.0, 1.0), 1.0, "graphite"))
    S.append(sphere((0, 15.0, 3.2), 0.8, "glow_amber"))
    return S


# ================================================================ 4 · Lazarus Computing: server floor with cable trenches
G4 = ("36282b", "64364b", "14121d")


def perforated(a, colour="37060b", step=3):
    for y in range(10, 39, step):
        for x in range(6, 36, step):
            px(a, x, y, colour)


@floor("4", 0)
def l_perforated():
    a = plate(*G4)
    perforated(a)
    return a


@floor("4", 1)
def l_solid():
    a = plate(*G4)
    seam_cross(a, "14121d", "4f342f")
    rivets(a, ((8, 14), (33, 14), (8, 33), (33, 33)), "64364b")
    return a


@floor("4", 3)
def l_trench():
    a = plate(*G4)
    perforated(a)
    for y in range(20, 29):
        hline(a, 2, 39, y, "171516" if 21 <= y <= 27 else "14121d")
    for x in range(4, 38, 5):
        px(a, x, 24, "ff2a3c")
    hline(a, 2, 39, 22, "64364b")
    return a


@floor("4", 4)
def l_sigil():
    a = plate(*G4)
    perforated(a)
    disc(a, 21, 25, 8, 7, "ecebe7", ring=True)           # a chalk circle, White kind
    for k in range(5):
        ang = math.radians(-90 + 72 * k)
        px(a, int(21 + 4 * math.cos(ang)), int(25 + 3.5 * math.sin(ang)), "ecebe7")
    return a


@floor("4", 2)
def l_scorch():
    a = plate(*G4)
    perforated(a)
    blob(a, "l4", 24, 27, 9, 7, ["14121d", "2d1b1e"], rough=1.2)
    return a


@cover("4", "half", foot=(24, 38), pitch=45, scale=1.2)
def cooling_units():
    """Cooling units: boxes with fans, frost on their pipes."""
    S = []
    for x, z in ((-7.0, 0.0), (6.0, -0.6)):
        S.append(box((x, 3.6, z), (5.0, 3.6, 3.8), "steel", r=0.6))
        S.append(cylinder((x, 7.2, z), (x, 7.6, z), 3.0, "charcoal", round_=0.2))
        S.append(box((x, 7.7, z), (2.6, 0.2, 0.3), "steel"))
        S.append(box((x, 7.7, z), (0.3, 0.2, 2.6), "steel"))
    S.append(capsule((-2.0, 2.0, 3.6), (1.0, 2.0, 3.4), 0.9, "crimson"))
    S.append(sphere((-7.0, 3.0, 3.9), 0.5, "glow_red"))
    return S


@cover("4", "full", foot=(24, 44), pitch=38, scale=1.0)
def server_racks_big():
    """Server racks, floor to ceiling, their lights blinking red."""
    material("rack", ["050403", "0e0c0c", "171516", "2d1b1e", "373334"], hi="595757", gloss=0.3)
    S = []
    for k, x in enumerate((-6.2, 6.2)):
        S.append(box((x, 13.0, 0), (5.6, 13.0, 4.6), "rack", r=0.6))
        for j in range(8):
            y = 4.0 + j * 2.8
            S.append(box((x - 2.0, y, 4.6), (2.0, 0.4, 0.25), "glow_red" if (j + k) % 3 else "glow_white", r=0.1))
            S.append(box((x + 2.6, y, 4.6), (0.5, 0.4, 0.25), "glow_red" if (j + k) % 2 else "glow_amber", r=0.1))
    S.append(capsule((-6.2, 26.6, 0), (6.2, 26.6, -1.0), 0.8, "crimson"))
    return S


# ================================================================ 6 · Meridian Entropics: plates crumbling to ash
G6 = ("2c3438", "406977", "14121d")


@floor("6", 0)
def m_cracked():
    a = plate(*G6)
    seam_cross(a, "14121d", "465456")
    wander(a, "m0", (24, 26), 14, ["14121d"], width=0, drift=0.9)
    return a


@floor("6", 2)
def m_ash():
    a = plate(*G6)
    seam_cross(a, "14121d", "465456")
    blob(a, "m1", 14, 31, 10, 6, ["595757", "465456"], rough=1.2)
    speckle(a, "m1s", ["807b7a"], 0.03)
    return a


@floor("6", 4)
def m_hole():
    a = plate(*G6)
    blob(a, "m2", 26, 20, 6, 5, ["0e0c0c", "171516"], rough=0.9)
    wander(a, "m2c", (20, 22), 12, ["14121d"], width=0, drift=0.9)
    return a


@floor("6", 3)
def m_crumble():
    a = plate(*G6)
    seam_cross(a, "14121d", "465456")
    speckle(a, "m3", ["595757", "14121d", "465456"], 0.07)
    return a


@floor("6", 1)
def m_rust():
    a = plate(*G6)
    seam_cross(a, "14121d", "465456")
    blob(a, "m4", 28, 31, 5, 4, ["4f342f", "2c3438"], rough=1.0)
    rivets(a, ((8, 14), (33, 14), (8, 33)), "64878c")
    return a


@cover("6", "half", foot=(24, 38), pitch=45, scale=1.2)
def rubble_heap():
    """A heap of the deck, broken up, ash drifting off it."""
    material("ash", ["171516", "323232", "595757", "807b7a", "a69e9a"])
    S = [ellipsoid((0, 1.0, 0), (12.0, 3.4, 6.0), "ash"),
         moved(box((0, 0, 0), (4.0, 1.0, 3.0), "steel", r=0.3), by=(-5.0, 4.0, 0.5), R=rot_z(0.4)),
         moved(box((0, 0, 0), (3.4, 0.9, 2.6), "steel", r=0.3), by=(5.0, 3.6, -0.5), R=rot_z(-0.5)),
         moved(box((0, 0, 0), (2.0, 0.8, 2.0), "rust", r=0.3), by=(0.5, 6.4, 0), R=rot_z(0.2)),
         sphere((8.0, 2.0, 3.0), 0.5, "glow_cyan")]
    return S


@cover("6", "full", foot=(24, 44), pitch=38, scale=1.0)
def machine_hulk_big():
    """A machine, coming apart: its corner gone to ash, its parts adrift."""
    material("ash", ["171516", "323232", "595757", "807b7a", "a69e9a"])
    body = cut(box((0, 11.0, 0), (10.0, 11.0, 6.0), "steel", r=1.0), (0.6, 0.7, 0.3), 12.0)
    S = [moved(body, R=rot_z(0.1)),
         box((-2.0, 20.0, 0), (5.0, 2.6, 4.4), "rust", r=0.6),
         sphere((-4.0, 14.0, 6.0), 1.0, "glow_cyan"),
         ellipsoid((9.0, 1.2, 3.0), (5.0, 1.6, 3.0), "ash"),
         box((12.0, 6.0, 0), (1.2, 1.0, 1.0), "steel", r=0.3, R=rot_z(0.6)),
         box((13.0, 12.0, -1.0), (0.8, 0.7, 0.7), "steel", r=0.2, R=rot_z(0.9)),
         box((11.0, 17.0, 1.0), (0.6, 0.5, 0.5), "steel", r=0.2)]
    return S


def all_pieces():
    return {"floors": {k: fn() for k, fn in FLOOR.items()}, "covers": {k: render_cover(*k) for k in COVER}}


if __name__ == "__main__":
    P = all_pieces()
    keys = sorted(P["floors"])
    sheet([P["floors"][k] for k in keys], preview_path("district_floors.png"), scale=4, labels=["%s-%d" % k for k in keys], cols=5, show1x=False)
    ck = sorted(P["covers"])
    sheet([P["covers"][k] for k in ck], preview_path("district_covers.png"), scale=4, labels=["%s-%s" % k for k in ck], cols=4, show1x=False)
    print("ok", len(keys), len(ck))
