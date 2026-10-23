"""The World Map's ground (0.15): each District's in hex pixels, four tiles of
it, as the lore has the District: Threshold Dynamics' lab plating under
hexagonal frost, Halcyon Cognition's dim tiled atriums, Vantage Robotics'
hazard-striped factory decks, Lazarus Computing's server floors and ritual
circles, Verdant Biogenics' grating gone to jungle, Meridian Entropics'
plating crumbling to ash; plain colony decking for tiles in no District; and
rubble for collapsed ones. Each is a hexpix tile (a hexagon of flat-top hex
pixels, 9 to a side), drawn darker than what stands on it."""
import math, random
import numpy as np
from kart import idx
from hexpix import CELLS, blank, SQ3

D_NAMES = {"1": "Threshold Dynamics", "2": "Halcyon Cognition", "3": "Vantage Robotics", "4": "Lazarus Computing",
           "5": "Verdant Biogenics", "6": "Meridian Entropics", "": "No District"}


def rng_for(*key):
    return random.Random("|".join(str(k) for k in key))


def noise(seed, c):
    """A steady 0..1 for a cell."""
    return rng_for(seed, c.col, c.row).random()


def paint(a, c, colour):
    a[c.row, c.col] = idx(colour)


def fill(seed, shades, weights=None):
    """Every cell one of a few shades, scattered (the mosaic's grain)."""
    a = blank()
    r = rng_for(seed)
    for c in CELLS:
        paint(a, c, r.choices(shades, weights=weights)[0])
    return a


def line_dist(c, p, angle):
    """How far a cell's middle is from a line through p at an angle (cell units)."""
    nx, ny = -math.sin(angle), math.cos(angle)
    return (c.x - p[0]) * nx + (c.y - p[1]) * ny


def seams(a, lines, dark, lite=None, width=0.75):
    """Seams between plates: cells on each line darkened; the cells just past
    it, on the lit side (the top left), lightened."""
    for p, ang in lines:
        for c in CELLS:
            d = line_dist(c, p, ang)
            if abs(d) < width:
                paint(a, c, dark)
            elif lite and width <= d < width + 0.95:
                paint(a, c, lite)


def dots(a, seed, n, colour, where=None, avoid_edge=2):
    r = rng_for(seed, "dots")
    pool = [c for c in CELLS if c.d <= 8 - avoid_edge and (where is None or where(c))]
    for c in r.sample(pool, min(n, len(pool))):
        paint(a, c, colour)


def hex_rings(a, centre, radii, colours):
    """Rings of cells at hex distances from a cell (the frost's hexagons)."""
    q0, r0 = centre
    for c in CELLS:
        dq, dr = c.q - q0, c.r - r0
        d = (abs(dq) + abs(dr) + abs(dq + dr)) // 2
        for k, rad in enumerate(radii):
            if d == rad:
                paint(a, c, colours[k % len(colours)])


# ---------------------------------------------------------------- 1 · Threshold Dynamics
# Each District has four tiles: three quiet ones and one with something on it,
# so that most of the map is ground and the rare thing stands out.
def frost(a, seed, o, size):
    """A patch of hexagonal frost: pale at its heart, crystals scattered round it."""
    r = rng_for(seed, "frost", o.col, o.row)
    for c in CELLS:
        d = math.hypot(c.x - o.x, c.y - o.y)
        n = r.random()
        if d < size * 0.45:
            paint(a, c, "f1f2ff" if n < 0.3 else "c9d4fd")
        elif d < size * 0.8 and n < 0.65:
            paint(a, c, "c9d4fd" if n < 0.25 else "8aa1f6")
        elif d < size and n < 0.28:
            paint(a, c, "9c8bdb" if n < 0.18 else "c9d4fd")


def threshold(v):
    s = "d1-%d" % v
    a = fill(s, ["494182", "4e4054", "3a2f3e"], [14, 5, 1])
    seams(a, [((0, -4.5 + 2 * (v % 2)), 0.0), ((3.0 - 2 * v, 0), math.radians(60))], "3a2f3e", "654370")
    r = rng_for(s, "frost")
    edge = [c for c in CELLS if 5 <= c.d <= 8]
    if v in (0, 2):
        for k in range(1 + v // 2):
            frost(a, s + str(k), r.choice(edge), r.uniform(2.6, 3.4))
    if v == 3:
        # a rift scar: a short crack of violet light across the plating
        r2 = rng_for(s, "rift")
        x, y = -5.0, r2.uniform(-3, 3)
        while x < 5:
            for c in CELLS:
                if abs(c.x - x) < 0.8 and abs(c.y - y) < 1.0:
                    paint(a, c, "c23bff" if abs(c.y - y) < 0.5 else "8a3dff")
            x += 1.5
            y += r2.choice((-SQ3 / 2, 0, SQ3 / 2))
        frost(a, s + "f", r.choice(edge), 2.8)
    return a


# ---------------------------------------------------------------- 2 · Halcyon Cognition
def halcyon(v):
    s = "d2-%d" % v
    a = blank()
    r = rng_for(s)
    for c in CELLS:
        # tiles four cells across in two dim shades, grout between
        t1, t2 = (c.q + 80) // 4, (c.r + 80) // 4
        light = (t1 + t2) % 2 == 0
        col = "c090a9" if light else "966888"
        if c.q % 4 == 0 or c.r % 4 == 0:
            col = "654956"
        if r.random() < 0.05:
            col = "87738f"
        paint(a, c, col)
    if v == 1:
        # a few tiles cracked and dark
        for c in CELLS:
            t1, t2 = (c.q + 80) // 4, (c.r + 80) // 4
            if rng_for(s, t1, t2).random() < 0.18 and not (c.q % 4 == 0 or c.r % 4 == 0):
                paint(a, c, "87738f" if noise(s, c) < 0.7 else "654956")
    if v == 3:
        # a psionic stain, pink, where something fed; sums scrawled beside it
        o = r.choice([c for c in CELLS if c.d <= 3])
        for c in CELLS:
            d = math.hypot(c.x - o.x, c.y - o.y)
            if d < 1.6:
                paint(a, c, "ff3d7f" if d < 0.9 else "d480bb")
            elif d < 3.4 and noise(s, c) < 0.5:
                paint(a, c, "c090a9")
        for row_y in (-6.0, 6.0):
            x = -6.0 + r.uniform(0, 2)
            while x < 5:
                n = r.randint(1, 2)
                for c in CELLS:
                    if abs(c.y - row_y) < 0.5 and x <= c.x < x + 1.5 * n:
                        paint(a, c, "e3cddf")
                x += 1.5 * n + 3.0
    return a


# ---------------------------------------------------------------- 3 · Vantage Robotics
def vantage(v):
    s = "d3-%d" % v
    a = fill(s, ["673931", "4f342f", "8c5b3e"], [14, 5, 1])
    seams(a, [((0, -5.5 + v), 0.0), ((-1.5 + 1.5 * v, 0), math.radians(90))], "271f1b", "8c5b3e")
    for c in CELLS:                                      # rivets
        if noise(s + "r", c) < 0.035 and c.d <= 7:
            paint(a, c, "b28b78")
    if v == 1:
        # an oil stain
        o = rng_for(s).choice([c for c in CELLS if c.d <= 5])
        for c in CELLS:
            d = math.hypot(c.x - o.x, (c.y - o.y) * 1.3)
            if d < 3.0 and noise(s + "o", c) < 0.85:
                paint(a, c, "271f1b" if d < 2.0 else "4f342f")
    if v == 3:
        # a hazard band: yellow and black stripes across the deck
        for c in CELLS:
            if abs(c.y - 1.5) < 1.8:
                stripe = int(math.floor((c.x + c.y * 0.58 + 40) / 2.6)) % 2
                paint(a, c, "f8c53a" if stripe == 0 else "271f1b")
            elif 1.8 <= abs(c.y - 1.5) < 2.7:
                paint(a, c, "b05b2c")
    return a


# ---------------------------------------------------------------- 4 · Lazarus Computing
def lazarus(v):
    s = "d4-%d" % v
    a = fill(s, ["7e0e0e", "37060b", "801c35"], [10, 5, 3])
    # the raised floor's grid
    for c in CELLS:
        if c.q % 4 == 0 or (c.r + c.q // 2) % 4 == 0:
            paint(a, c, "37060b")
    if v == 1:
        dots(a, s, 4, "ff2a3c")
    if v == 2:
        # a cable trench, its lights blinking red
        for c in CELLS:
            if abs(c.x - 1.5) < 1.6:
                paint(a, c, "171516")
                if noise(s + "led", c) < 0.16:
                    paint(a, c, "ff2a3c")
    if v == 3:
        # a ritual circle etched in the deck
        o = (0.0, 0.0)
        for c in CELLS:
            d = math.hypot(c.x - o[0], c.y - o[1])
            if 4.4 <= d < 5.6:
                paint(a, c, "ecebe7")
            elif d < 1.0:
                paint(a, c, "ecebe7")
            elif 4.0 <= d < 4.4 and noise(s, c) < 0.5:
                paint(a, c, "cbc6c1")
        for k in range(5):
            ang = math.radians(-90 + 72 * k)
            for t in np.arange(1.0, 4.4, 0.6):
                for c in CELLS:
                    if math.hypot(c.x - (o[0] + t * math.cos(ang)), c.y - (o[1] + t * math.sin(ang))) < 0.6:
                        paint(a, c, "ecebe7")
    return a


# ---------------------------------------------------------------- 5 · Verdant Biogenics
def verdant(v):
    s = "d5-%d" % v
    a = fill(s, ["27412d", "2c3b39"], [3, 2])
    for c in CELLS:                                      # the grating's bars
        if c.q % 3 == 0:
            paint(a, c, "171819")
    r = rng_for(s)
    # the green comes up through it: moss in drifts
    blobs = [(r.uniform(-8, 8), r.uniform(-8, 8), r.uniform(2.5, 5.0)) for _ in range(2 + v % 3)]
    for c in CELLS:
        m = max((1.0 - math.hypot(c.x - bx, c.y - by) / br) for bx, by, br in blobs)
        n = noise(s + "m", c)
        if m > 0.45 + 0.3 * n:
            paint(a, c, "61a53f" if n < 0.35 else "42a459" if n < 0.85 else "8fd032")
        elif m > 0.15 + 0.3 * n:
            paint(a, c, "3d6f43")
    if v == 2:
        # a root across the deck
        x, y = -10.0, r.uniform(-5, 5)
        while x < 10:
            for c in CELLS:
                d = math.hypot(c.x - x, c.y - y)
                if d < 1.1:
                    paint(a, c, "724b2c" if d < 0.6 else "452a1b")
            x += 0.9
            y += r.uniform(-0.9, 0.9)
    if v == 3:
        # a spill from a cracked vat
        for c in CELLS:
            d = math.hypot(c.x + 2.0, (c.y - 2.0) * 1.2)
            if d < 3.4 and noise(s + "p", c) < 0.92:
                paint(a, c, "97edca" if d < 1.2 else "59cf93" if d < 2.3 else "42a459")
    # flowers, turned to the light
    for c in r.sample(CELLS, 5 + 2 * v):
        if a[c.row, c.col] in (idx("61a53f"), idx("42a459"), idx("3d6f43"), idx("8fd032")):
            paint(a, c, r.choice(["f6a2a8", "fff089", "e27285", "ceaaed"]))
    return a


# ---------------------------------------------------------------- 6 · Meridian Entropics
def meridian(v):
    s = "d6-%d" % v
    a = fill(s, ["406977", "2c3b39", "465456"], [12, 4, 4])
    seams(a, [((0, -2.0 + v), math.radians(30)), ((0, 3.0), math.radians(-30))], "14121d", "64878c")
    r = rng_for(s)
    # cracks running out from a broken point
    o = (r.uniform(-4, 4), r.uniform(-4, 4))
    for k in range(2 + v):
        ang = r.uniform(0, math.tau)
        x, y = o
        for step in range(5 + v):
            for c in CELLS:
                if math.hypot(c.x - x, c.y - y) < 0.65:
                    paint(a, c, "171516")
            ang += r.uniform(-0.6, 0.6)
            x += 1.2 * math.cos(ang)
            y += 1.2 * math.sin(ang)
    # ash, drifting into the low places
    for c in CELLS:
        n = noise(s + "ash", c)
        if n < (0.06 + 0.05 * v):
            paint(a, c, "807b7a" if n < 0.03 else "595757")
    if v == 3:
        # a hole where the deck has crumbled through
        for c in CELLS:
            d = math.hypot(c.x - o[0], c.y - o[1])
            if d < 2.4:
                paint(a, c, "0e0c0c")
            elif d < 3.4 and noise(s + "h", c) < 0.7:
                paint(a, c, "2c3438")
    return a


# ---------------------------------------------------------------- no District
def plain(v):
    s = "d0-%d" % v
    a = fill(s, ["485262", "3e4246", "5e718e"], [12, 5, 1])
    seams(a, [((0, -3.0 + 2 * v), 0.0), ((-2.0 + 3 * v, 0), math.radians(60))], "282c3c", "5e718e")
    return a


# ---------------------------------------------------------------- rubble
def rubble(v):
    s = "rb-%d" % v
    a = fill(s, ["171516", "0e0c0c"], [3, 2])
    r = rng_for(s)
    # slabs, tipped and broken, lit from the top left
    for k in range(5 + v):
        cx, cy = r.uniform(-8, 8), r.uniform(-8, 8)
        w, h, ang = r.uniform(2.5, 5.0), r.uniform(1.6, 3.2), r.uniform(0, math.pi)
        tone = r.choice([("373334", "595757", "171516"), ("322f35", "564f5b", "171516"), ("2d1b1e", "4f342f", "171516")])
        for c in CELLS:
            dx, dy = c.x - cx, c.y - cy
            u = dx * math.cos(ang) + dy * math.sin(ang)
            w2 = -dx * math.sin(ang) + dy * math.cos(ang)
            if abs(u) < w and abs(w2) < h:
                edge = abs(u) > w - 1.2 or abs(w2) > h - 1.1
                lit = (dx + dy) < 0
                paint(a, c, tone[1] if (edge and lit) else tone[2] if edge else tone[0])
    return a


GROUND = {"1": threshold, "2": halcyon, "3": vantage, "4": lazarus, "5": verdant, "6": meridian, "": plain}
VARIANTS = 4


def ground(d, v):
    return GROUND[d](v)


if __name__ == "__main__":
    from PIL import Image
    from hexpix import render
    from kart import preview_path
    tiles = [[render(ground(d, v), s=6)[0] for v in range(VARIANTS)] for d in ["1", "2", "3", "4", "5", "6", ""]]
    tiles.append([render(rubble(v), s=6)[0] for v in range(3)])
    W, H = tiles[0][0].size
    sheet = Image.new("RGBA", ((W + 8) * VARIANTS + 8, (H + 8) * len(tiles) + 8), (20, 18, 29, 255))
    for j, row in enumerate(tiles):
        for i, im in enumerate(row):
            sheet.alpha_composite(im, (8 + i * (W + 8), 8 + j * (H + 8)))
    sheet.save(preview_path("map_ground.png"))
    print(sheet.size)
