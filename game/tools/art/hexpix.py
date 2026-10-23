"""Hex-pixel pictures (0.15): the World Map's ground, as the Pixel Studio's hex
canvas holds it. A map tile is a hexagon of flat-top hex pixels, 9 to a side
(the Companion's map slots): an array 18 wide and 17 high in offset columns,
the cells outside the hexagon void. The cells are laid out as the Companion's
pixelart.js lays them (a cell's circumradius is one unit).

The game draws a tile's picture clipped to the tile's own hexagon (pointy
top), which these cells cover: CLIP units from the middle to a corner."""
import math
import numpy as np
from PIL import Image, ImageDraw
from kart import idx, rgb

SQ3 = math.sqrt(3.0)
SIDE = 9
COLS, ROWS = 2 * SIDE, 2 * SIDE - 1
R = SIDE - 1


def axial(col, row):
    """Offset columns (flat-top cells) to axial, as pixelart.js's axialOf."""
    return col, row - (col - (col & 1)) // 2


CQ, CR = axial(R, R)
X0, Y0 = 1.5 * CQ, SQ3 * (CR + CQ / 2.0)


class Cell:
    __slots__ = ("col", "row", "q", "r", "x", "y", "d", "a")

    def __init__(self, col, row):
        self.col, self.row = col, row
        self.q, self.r = axial(col, row)
        self.x = 1.5 * self.q - X0                       # from the tile's middle, in cell units
        self.y = SQ3 * (self.r + self.q / 2.0) - Y0
        dq, dr = self.q - CQ, self.r - CR
        self.d = (abs(dq) + abs(dr) + abs(dq + dr)) // 2  # rings out from the middle
        self.a = math.atan2(self.y, self.x)              # its angle (y down)


CELLS = [c for c in (Cell(col, row) for row in range(ROWS) for col in range(COLS)) if c.d <= R]
assert len(CELLS) == 3 * R * R + 3 * R + 1
# the tile's hexagon (pointy top): its corners sit just past the corner cells' middles
CLIP = SQ3 * R + 0.5


def blank():
    return np.zeros((ROWS, COLS), np.int32)


def corners(cx, cy, size):
    """A pointy-top hexagon's corners (y down), as the game's Hex.corners."""
    return [(cx + size * math.cos(math.radians(60 * k - 30)), cy + size * math.sin(math.radians(60 * k - 30))) for k in range(6)]


def cell_poly(x, y, s, grow=1.0):
    """A flat-top cell's outline, centred at x, y, s pixels to a corner."""
    return [(x + s * grow * math.cos(math.radians(60 * k)), y + s * grow * math.sin(math.radians(60 * k))) for k in range(6)]


def render(a, s=3.0, clip=True, alpha=255):
    """The tile at s pixels to a cell's corner: an RGBA image of the cells'
    whole extent, and where the tile's middle falls in it. With clip, only
    what lies inside the tile's hexagon is kept."""
    xs = [c.x for c in CELLS]
    ys = [c.y for c in CELLS]
    minx, maxx = min(xs) - 1.0, max(xs) + 1.0
    miny, maxy = min(ys) - SQ3 / 2.0, max(ys) + SQ3 / 2.0
    W, H = int(math.ceil((maxx - minx) * s)), int(math.ceil((maxy - miny) * s))
    mid = (-minx * s, -miny * s)
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    g = ImageDraw.Draw(im)
    for c in CELLS:
        v = int(a[c.row, c.col])
        if v:
            g.polygon(cell_poly(mid[0] + c.x * s, mid[1] + c.y * s, s, 1.04), fill=rgb(v) + (alpha,))
    if clip:
        m = Image.new("L", (W, H), 0)
        ImageDraw.Draw(m).polygon(corners(mid[0], mid[1], CLIP * s), fill=255)
        im.putalpha(Image.fromarray(np.minimum(np.array(im.split()[3]), np.array(m))))
    return im, mid


def studio_picture(a, name):
    """The Pixel Studio's hex canvas: grid hex, a hexagon of side 9, flat cells."""
    from kart import studio_encode
    enc = studio_encode(a)
    return {"v": 1, "w": COLS, "h": ROWS, "name": name, "grid": "hex", "shape": "hexagon", "side": SIDE, "orient": "flat",
            "frames": [{"layers": [{"name": "Layer 1", "visible": True, "locked": False, "opacity": 100, "mode": "view", "px": enc}]}], "flat": enc}


def coverage_check(s=8.0):
    """Every point of the tile's hexagon is under a cell (no gaps at its edge)."""
    a = blank()
    for c in CELLS:
        a[c.row, c.col] = idx("ffffff")
    im, mid = render(a, s, clip=False)
    px = np.array(im)[:, :, 3]
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).polygon(corners(mid[0], mid[1], CLIP * s), fill=255)
    hole = (np.array(m) > 0) & (px == 0)
    return int(hole.sum())


if __name__ == "__main__":
    print("cells", len(CELLS), "clip", round(CLIP, 2), "gaps at s=8:", coverage_check())
