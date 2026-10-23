"""The menus' pictures (0.15): QM-7, the Hangar's logistics robot, who keeps
the dock (a bust, 64 x 64, and the same with its optics shut for a blink);
Home's picture, the colony's sign over a lower skyline with the Nexus's
tower (256 x 144, drawn five times over to fill the screen); and the dock's,
the Hangar inside."""
import math, random
import numpy as np
from kart import *
from rigs import *

material("vantage_worn", ["271f1b", "4f342f", "8c5b3e", "b05b2c", "e88a36"], hi="fca570", gloss=0.25)


# ---------------------------------------------------------------- QM-7
def qm7(eyes="glow_amber"):
    """Vantage Robotics Logistics Unit QM-7, Hangar Operations: a squat sensor
    head on a broad chassis, three lenses in its visor, a scanner at its side."""
    S = []
    # the chassis: broad shoulders in Vantage orange, worn
    body = box((0, 12.0, 0), (17.0, 12.0, 9.0), "vantage_worn", r=3.0)
    S.append(cut(body, (0, -1, 0), -2.0))
    S.append(box((0, 19.5, 6.8), (12.0, 2.2, 2.6), "warning", r=0.6))                 # a hazard band across the chest
    S.append(box((0, 9.0, 8.4), (7.0, 5.0, 1.2), "steel", r=0.8))                     # the chest plate (its number goes here)
    for x in (-10.0, 10.0):                                                            # panel seams
        S.append(box((x, 11.0, 8.9), (0.3, 7.0, 0.3), "dark", r=0.1))
    S.append(box((-6.0, 16.6, 8.9), (3.0, 0.3, 0.3), "dark", r=0.1))
    for sx in (-1, 1):
        S.append(sphere((sx * 17.0, 21.0, 0), 5.0, "graphite"))                       # shoulder joints
        S.append(box((sx * 19.5, 12.0, 0.5), (3.4, 8.0, 4.6), "vantage_worn", r=1.4))  # upper arms
    # the neck: pistons
    for sx in (-1, 1):
        S.append(capsule((sx * 3.4, 22.0, 0), (sx * 2.6, 30.0, 0), 1.1, "steel"))
    S.append(cylinder((0, 22.0, 0), (0, 29.0, 0), 2.6, "graphite", round_=0.6))
    # the head: wide and low, a visor across it
    head_ = box((0, 35.5, 0.5), (11.0, 6.4, 7.6), "gunmetal", r=2.4)
    S.append(head_)
    S.append(box((0, 36.0, 7.4), (9.4, 2.6, 1.2), "dark", r=0.8))
    for x, rr in ((-5.2, 1.5), (0.4, 2.0), (5.6, 1.3)):                               # three lenses, the middle one large
        S.append(sphere((x, 36.0, 8.2), rr, eyes))
    S.append(box((0, 42.4, 0), (6.0, 0.8, 5.0), "vantage_worn", r=0.5))               # a stripe over the top
    S.append(capsule((-8.0, 41.0, -2.0), (-10.0, 50.0, -3.0), 0.45, "graphite"))       # an antenna
    S.append(sphere((-10.0, 50.4, -3.0), 1.0, "glow_red"))
    S.append(box((11.6, 35.0, 0), (1.2, 3.0, 3.0), "steel", r=0.4))                    # an ear-plate
    # the scanner in its right hand, raised a little
    S.append(capsule((19.5, 5.0, 3.0), (17.0, 2.0, 9.0), 2.2, "vantage_worn"))
    S.append(box((15.0, 4.0, 12.0), (2.4, 1.6, 3.6), "graphite", r=0.6))
    S.append(box((15.0, 4.0, 15.6), (1.8, 1.0, 0.3), "glow_red", r=0.1))
    # wear: rust and scrapes
    for x, y, z, rr in ((-12.0, 6.0, 7.6, 1.6), (9.0, 15.0, 8.0, 1.2), (-15.0, 18.0, 5.0, 1.4)):
        S.append(sphere((x, y, z), rr, "rust"))
    return S


def stencil(img, text, x0, y0, colour):
    """Small capitals, 3 x 5, painted on (QM-7's number on its chest plate)."""
    font = {"Q": ["111", "101", "101", "111", "001"], "M": ["101", "111", "111", "101", "101"],
            "-": ["000", "000", "111", "000", "000"], "7": ["111", "001", "010", "010", "010"]}
    x = x0
    for ch in text:
        g = font[ch]
        for j, row in enumerate(g):
            for i, b in enumerate(row):
                if b == "1":
                    put(img, x + i, y0 + j, colour)
        x += 4


def render_qm7(blink=False):
    img = make(qm7("dark" if blink else "glow_amber"), size=64, foot=(32, 68), pitch=8, yaw=-22, scale=1.0, inner_step=1.4)
    stencil(img, "QM-7", 26, 56, "171516")
    return img


if __name__ == "__main__":
    a, b = render_qm7(), render_qm7(True)
    sheet([a, b], preview_path("qm7.png"), scale=4, labels=["QM-7", "blink"], cols=2)
    print("ok")


# ---------------------------------------------------------------- Home: the colony's sign
HW, HH = 256, 144


def _rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[k:k + 2], 16) for k in (0, 2, 4))


def _bayer(x, y, share):
    B = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
    return share * 16.0 > B[(y % 4) * 4 + (x % 4)] + 0.5


# each letter of the sign as its neon tube's path, in a box 16 wide and 24 high
LETTERS = {
    "K": [[(1, 0), (1, 23)], [(14, 0), (3, 12), (14, 23)]],
    "E": [[(14, 0), (1, 0), (1, 23), (14, 23)], [(1, 11), (11, 11)]],
    "T": [[(0, 0), (15, 0)], [(7, 0), (7, 23)]],
    "R": [[(1, 23), (1, 0), (10, 0), (13, 2), (14, 5), (14, 7), (13, 10), (10, 12), (1, 12)], [(7, 12), (14, 23)]],
    "V": [[(1, 0), (7, 23), (8, 23), (14, 0)]],
    "I": [[(2, 0), (2, 23)]],
    "C": [[(14, 2), (11, 0), (4, 0), (1, 3), (1, 20), (4, 23), (11, 23), (14, 21)]],
    "O": [[(4, 0), (11, 0), (14, 3), (14, 20), (11, 23), (4, 23), (1, 20), (1, 3), (4, 0)]],
    "Y": [[(1, 0), (7, 11), (14, 0)], [(7, 11), (7, 23)]],
    "D": [[(1, 0), (1, 23), (9, 23), (13, 20), (14, 16), (14, 7), (13, 3), (9, 0), (1, 0)]],
    "F": [[(14, 0), (1, 0), (1, 23)], [(1, 11), (11, 11)]],
    "A": [[(1, 23), (1, 6), (5, 0), (10, 0), (14, 6), (14, 23)], [(1, 13), (14, 13)]],
}
WIDTH = {"I": 5}
TINY = {  # small capitals for the line under the sign, 4 wide (M 5)
    "R": ["1110", "1001", "1110", "1010", "1001"], "E": ["1111", "1000", "1110", "1000", "1111"],
    "S": ["0111", "1000", "0110", "0001", "1110"], "A": ["0110", "1001", "1111", "1001", "1001"],
    "C": ["0111", "1000", "1000", "1000", "0111"], "H": ["1001", "1001", "1111", "1001", "1001"],
    "O": ["0110", "1001", "1001", "1001", "0110"], "L": ["1000", "1000", "1000", "1000", "1111"],
    "N": ["1001", "1101", "1011", "1001", "1001"], "Y": ["1001", "1001", "0110", "0100", "0100"],
    "M": ["10001", "11011", "10101", "10001", "10001"], " ": ["00", "00", "00", "00", "00"],
    "·": ["00", "00", "11", "11", "00"]}


def home_picture(dark_letter=3, seed=11, sign=True):
    from PIL import Image, ImageDraw
    rnd = random.Random(seed)
    im = Image.new("RGB", (HW, HH), _rgb("050403"))
    px_ = im.load()
    # the night beyond the dome: black at the top, the dust's rust at the horizon
    stops = ["050403", "050403", "0e0c0c", "14121d", "2a1e23", "2d1b1e", "4f342f"]
    for y in range(HH):
        t = y / (HH - 1) * (len(stops) - 1)
        i = min(int(t), len(stops) - 2)
        f = t - i
        for x in range(HW):
            px_[x, y] = _rgb(stops[i + 1] if _bayer(x, y, f) else stops[i])
    for k in range(70):                                              # stars
        x, y = rnd.randrange(HW), rnd.randrange(0, 92)
        px_[x, y] = _rgb("c5c7dd" if rnd.random() < 0.25 else "5a6da6")
    g = ImageDraw.Draw(im)
    # the dome's panes: a faint lattice of hexagons over the sky
    size = 22.0
    for r in range(-2, 8):
        for q in range(-4, 12):
            cx = math.sqrt(3) * size * (q + r / 2.0)
            cy = 1.5 * size * r - 6
            pts = [(cx + size * math.cos(math.radians(60 * k - 30)), cy + size * math.sin(math.radians(60 * k - 30))) for k in range(7)]
            g.line(pts, fill=_rgb("171516"), width=1)
    # the distant colony in the haze, then the near skyline, low
    x = -4
    while x < HW:
        w, h = rnd.randint(5, 14), rnd.randint(6, 16)
        g.rectangle((x, 122 - h, x + w, 126), fill=_rgb("2d1b1e"))
        x += w + rnd.randint(0, 3)
    x = -6
    while x < HW:
        w, h = rnd.randint(6, 18), rnd.randint(8, 22)
        if 196 <= x <= 222:
            h = min(h, 10)
        g.rectangle((x, 140 - h, x + w, HH), fill=_rgb("0e0c0c"))
        g.line((x, 140 - h, x, HH), fill=_rgb("171516"))
        for yy in range(140 - h + 3, 138, 3):
            for xx in range(x + 2, x + w - 1, 3):
                if rnd.random() < 0.16:
                    px_[min(HW - 1, max(0, xx)), yy] = _rgb("d6a851" if rnd.random() < 0.7 else "73efe8")
        if rnd.random() < 0.3 and w > 8:
            mx = x + w // 2
            g.line((mx, 140 - h - rnd.randint(4, 9), mx, 140 - h), fill=_rgb("171516"))
        x += w + rnd.randint(0, 4)
    g.rectangle((0, 140, HW, HH), fill=_rgb("050403"))
    # the Nexus: one tall tower, the eye's place to land
    tx = 206
    for y in range(34, 141):
        half = 2 + int((y - 34) / 106.0 * 8)
        for xx in range(tx - half, tx + half + 1):
            edge = xx == tx - half
            band = (y % 6 == 0)
            px_[xx, y] = _rgb("282c3c" if edge else ("171516" if band else "0e0c0c"))
        if y % 6 == 3 and y > 44:
            for xx in range(tx - half + 2, tx + half - 1, 2):
                if rnd.random() < 0.35:
                    px_[xx, y] = _rgb("73efe8" if rnd.random() < 0.4 else "d6a851")
    for y in range(22, 34):                                           # its mast
        px_[tx, y] = _rgb("282c3c")
    px_[tx, 21] = _rgb("ff2a3c")
    for dy in range(-3, 4):                                           # the Aether at its crown
        for dx in range(-3, 4):
            d = math.hypot(dx, dy)
            if d <= 3.2:
                c = "f1f2ff" if d < 1.2 else "c23bff" if d < 2.2 else "8a3dff"
                if d > 2.6 and not _bayer(tx + dx, 36 + dy, 0.6):
                    continue
                px_[tx + dx, 36 + dy] = _rgb(c)
    if not sign:
        return _to_indices(im)
    # the sign: KETER in neon tubes, hung from the dome on two cables
    word, x0, y0, gap = "KETER", 76, 13, 6
    tube = Image.new("L", (HW, HH), 0)
    dead = Image.new("L", (HW, HH), 0)
    tg, dg = ImageDraw.Draw(tube), ImageDraw.Draw(dead)
    for i, ch in enumerate(word):
        lx = x0 + i * (16 + gap)
        for path in LETTERS[ch]:
            pts = [(lx + p[0], y0 + p[1]) for p in path]
            (dg if i == dark_letter else tg).line(pts, fill=255, width=2, joint="curve")
    T = np.array(tube) > 0
    D = np.array(dead) > 0
    # the rail behind the letters, its brackets, and the cables up to the dome
    for xx in (82, 176):
        g.line((xx, 0, xx, 40), fill=_rgb("282c3c"))
    g.rectangle((72, 39, 186, 41), fill=_rgb("282c3c"))
    g.line((72, 39, 186, 39), fill=_rgb("485262"))
    for i in range(5):
        bx = x0 + i * (16 + gap) + 8
        g.rectangle((bx - 1, 36, bx, 39), fill=_rgb("171516"))
    # the glow round the lit tubes: two rings, thinning out
    from scipy.ndimage import binary_dilation as dil
    g1 = dil(T, iterations=1) & ~T
    g2 = dil(T, iterations=3) & ~dil(T, iterations=1)
    arr = np.array(im)
    for y in range(HH):
        for x in range(HW):
            if g2[y, x] and _bayer(x, y, 0.45):
                arr[y, x] = _rgb("1b2447")
            if g1[y, x]:
                arr[y, x] = _rgb("2789cd") if _bayer(x, y, 0.7) else _rgb("1b2447")
            if D[y, x]:
                arr[y, x] = _rgb("465456") if (x + y) % 3 else _rgb("2c3438")
            if T[y, x]:
                # a white-hot core along the tube, cyan at its edge
                core = T[max(0, y - 1), x] and T[min(HH - 1, y + 1), x] and T[y, max(0, x - 1)] and T[y, min(HW - 1, x + 1)]
                arr[y, x] = _rgb("f1f2ff") if core else _rgb("22f0ff")
    im = Image.fromarray(arr)
    g = ImageDraw.Draw(im)
    # the line under it, on its own plate: RESEARCH COLONY · MARS
    text = "RESEARCH COLONY · MARS"
    w = sum(len(TINY[ch][0]) + 1 for ch in text) - 1
    px0 = HW // 2 - w // 2
    g.rectangle((px0 - 4, 44, px0 + w + 3, 52), fill=_rgb("171516"))
    g.line((px0 - 4, 44, px0 + w + 3, 44), fill=_rgb("465456"))
    for xx in (px0 - 2, px0 + w + 1):
        im.putpixel((xx, 48), _rgb("595757"))
    x = px0
    for ch in text:
        for j, row in enumerate(TINY[ch]):
            for i, b in enumerate(row):
                if b == "1":
                    im.putpixel((x + i, 46 + j), _rgb("d6a851"))
        x += len(TINY[ch][0]) + 1
    # back to the palette's indices
    a = np.array(im)
    out = np.zeros((HH, HW), np.int32)
    for y in range(HH):
        for x in range(HW):
            out[y, x] = INDEX["%02x%02x%02x" % tuple(a[y, x])]
    return out


# ---------------------------------------------------------------- the end of a fight: its title, in neon
NEON = {"gold": ("fff089", "f8c53a", "b47538", "724b2c"), "red": ("f6a2a8", "ff2a3c", "b81418", "7e0e0e"),
        "cyan": ("f1f2ff", "22f0ff", "2789cd", "1b2447")}


def neon_word(word, tone="gold", gap=5, pad=4):
    """A word in neon tubes, on nothing: its glow dithered out to the edge."""
    from PIL import Image, ImageDraw
    from scipy.ndimage import binary_dilation as dil
    core, edge, g1c, g2c = NEON[tone]
    widths = [WIDTH.get(ch, 16) for ch in word]
    W = sum(widths) + gap * (len(word) - 1) + pad * 2
    H = 24 + pad * 2
    m = Image.new("L", (W, H), 0)
    g = ImageDraw.Draw(m)
    x = pad
    for ch, w in zip(word, widths):
        for path in LETTERS[ch]:
            g.line([(x + p[0], pad + p[1]) for p in path], fill=255, width=2, joint="curve")
        x += w + gap
    T = np.array(m) > 0
    G1 = dil(T, iterations=1) & ~T
    G2 = dil(T, iterations=3) & ~dil(T, iterations=1)
    out = np.zeros((H, W), np.int32)
    for y in range(H):
        for x in range(W):
            if G2[y, x] and _bayer(x, y, 0.4):
                out[y, x] = idx(g2c)
            if G1[y, x]:
                out[y, x] = idx(g1c) if _bayer(x, y, 0.7) else idx(g2c)
            if T[y, x]:
                inner = all(T[min(H - 1, max(0, y + dy)), min(W - 1, max(0, x + dx))] for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                out[y, x] = idx(core) if inner else idx(edge)
    return out


def victory():
    return neon_word("VICTORY", "gold")


def defeat():
    return neon_word("DEFEAT", "red")


def _to_indices(im):
    a = np.array(im.convert("RGB"))
    out = np.zeros(a.shape[:2], np.int32)
    for y in range(a.shape[0]):
        for x in range(a.shape[1]):
            out[y, x] = INDEX["%02x%02x%02x" % tuple(a[y, x])]
    return out


# ---------------------------------------------------------------- the dock: Docking Bay 2, inside
def dock_picture(seed=23):
    """The Hangar from inside: its ribs overhead, the bay door open on the
    night and a ship's nose in it, lockers down one wall, crates down the
    other, and from the crane the Purifier QM-7 hung up by its treads."""
    from PIL import Image, ImageDraw
    rnd = random.Random(seed)
    im = Image.new("RGB", (HW, HH), _rgb("0e0c0c"))
    g = ImageDraw.Draw(im)
    px_ = im.load()
    # the back wall, and the bay door open on the night
    g.rectangle((0, 0, HW, 104), fill=_rgb("171516"))
    door = (64, 30, 192, 104)
    stops = ["050403", "14121d", "2a1e23", "4f342f"]
    for y in range(door[1], door[3]):
        t = (y - door[1]) / (door[3] - door[1] - 1) * (len(stops) - 1)
        i = min(int(t), len(stops) - 2)
        for x in range(door[0], door[2]):
            px_[x, y] = _rgb(stops[i + 1] if _bayer(x, y, t - i) else stops[i])
    for k in range(18):
        px_[rnd.randrange(door[0], door[2]), rnd.randrange(door[1], 70)] = _rgb("c5c7dd" if rnd.random() < 0.3 else "5a6da6")
    g.rectangle((door[0] - 3, door[1] - 3, door[2] + 2, door[1] - 1), fill=_rgb("485262"))
    for x in (door[0] - 3, door[2]):
        g.rectangle((x, door[1] - 3, x + 2, door[3]), fill=_rgb("282c3c"))
    # the RV Thoth's nose, docked in the light
    g.polygon([(96, 104), (110, 76), (146, 70), (172, 80), (182, 104)], fill=_rgb("2c3438"))
    g.polygon([(110, 76), (146, 70), (160, 74), (118, 80)], fill=_rgb("465456"))
    g.rectangle((132, 84, 150, 88), fill=_rgb("73efe8"))
    for x in (104, 176):
        px_[x, 98] = _rgb("ff2a3c")
    # the roof's ribs, arched overhead
    for k, x0 in enumerate(range(-40, HW + 40, 52)):
        g.arc((x0 - 80, -60, x0 + 80, 90), 200, 340, fill=_rgb("282c3c"), width=3)
        g.arc((x0 - 80, -59, x0 + 80, 91), 210, 330, fill=_rgb("406977"), width=1)
    # the crane's beam, and what hangs from it
    g.rectangle((0, 12, HW, 16), fill=_rgb("0e0c0c"))
    g.line((0, 12, HW, 12), fill=_rgb("595757"))
    for x in range(0, HW, 8):
        g.line((x, 13, x + 4, 16), fill=_rgb("373334"))
    g.line((150, 16, 150, 30), fill=_rgb("373334"))
    # the Purifier, upside down by its treads: a warning that has not worked
    g.rectangle((141, 30, 159, 34), fill=_rgb("171516"))
    g.ellipse((140, 33, 160, 52), fill=_rgb("b8ccd8"))
    g.ellipse((143, 36, 157, 50), fill=_rgb("dceaee"))
    g.rectangle((145, 47, 155, 50), fill=_rgb("171516"))
    px_[150, 48] = _rgb("ff2bd6")
    g.line((140, 41, 136, 46), fill=_rgb("595757"))
    g.line((160, 41, 164, 46), fill=_rgb("595757"))
    # lockers down the left wall, crates down the right
    for i in range(7):
        x = 4 + i * 8
        g.rectangle((x, 46, x + 6, 104), fill=_rgb("282c3c"))
        g.line((x, 46, x, 104), fill=_rgb("485262"))
        g.rectangle((x + 4, 66, x + 5, 70), fill=_rgb("595757"))
        for y in (50, 53):
            g.line((x + 1, y, x + 5, y), fill=_rgb("171516"))
    for x0, y0, w, h, col in ((198, 80, 24, 24, "586335"), (222, 84, 22, 20, "724b2c"), (204, 60, 18, 20, "586335"), (236, 70, 18, 14, "673931")):
        g.rectangle((x0, y0, x0 + w, y0 + h), fill=_rgb(col))
        g.line((x0, y0, x0 + w, y0), fill=_rgb("d6a851"))
        g.line((x0, y0, x0, y0 + h), fill=_rgb("7f8e44" if col == "586335" else "8c5b3e"))
    # the deck: plates running back to the door, a hazard stripe, a scorch
    for y in range(104, HH):
        f = (y - 104) / (HH - 104)
        for x in range(HW):
            c = "282c3c" if _bayer(x, y, 0.35 + 0.4 * f) else "171516"
            px_[x, y] = _rgb(c)
    for k in range(-6, 7):
        x = HW // 2 + k * 10
        g.line((x, 104, HW // 2 + k * 40, HH), fill=_rgb("0e0c0c"))
    for y in range(126, 131):
        for x in range(HW):
            px_[x, y] = _rgb("d6a851" if ((x + y) // 4) % 2 == 0 else "0e0c0c")
    for k in range(60):
        x, y = rnd.randint(80, 170), rnd.randint(108, 124)
        px_[x, y] = _rgb("050403")
    # lights along the back wall, cyan, and the door's amber warning
    for x in range(10, HW, 22):
        px_[x, 22] = _rgb("73efe8"); px_[x + 1, 22] = _rgb("73efe8")
    for x in (60, 196):
        px_[x, 27] = _rgb("f8c53a")
    return _to_indices(im)


def menu_picture():
    """Behind the Strike Teams, the Workshop and a fight's setup: the colony
    at night, as on Home, with no sign in the sky."""
    return home_picture(sign=False, seed=37)
