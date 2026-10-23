"""KETER art kit: the Pixel Studio palette, a tiny shape renderer and the
finishing passes (outlines, clean-up) that turn a lit model into pixel art.

Models are built from rounded 3D shapes in pixel units (1 unit = 1 pixel),
rendered orthographically from the front and a little above, lit from the
top left, and each surface's light is cut into its material's few colours.
Every pixel that leaves here is a Pixel Studio palette index.
"""
import base64, json, math, os, tempfile, zlib
import numpy as np
from PIL import Image

# ---------------------------------------------------------------- palette
SPLENDOR = ("050403 0e0c0c 2d1b1e 612721 b9451d f1641f fca570 ffe0b7 ffffff fff089 f8c53a e88a36 b05b2c 673931 271f1b 4c3d2e 855f39 d39741 f8f644 d5dc1d adb834 7f8e44 586335 333c24 181c19 293f21 477238 61a53f 8fd032 c4f129 d0ffea 97edca 59cf93 42a459 3d6f43 27412d 14121d 1b2447 2b4e95 2789cd 42bfe8 73efe8 f1f2ff c9d4fd 8aa1f6 4572e3 494182 7864c6 9c8bdb ceaaed fad6ff eeb59c d480bb 9052bc 171516 373334 695b59 b28b78 e2b27e f6d896 fcf7be ecebe7 cbc6c1 a69e9a 807b7a 595757 323232 4f342f 8c5b3e c68556 d6a851 b47538 724b2c 452a1b 61683a 939446 c6b858 efdd91 b5e7cb 86c69a 5d9b79 486859 2c3b39 171819 2c3438 465456 64878c 8ac4c3 afe9df dceaee b8ccd8 88a3bc 5e718e 485262 282c3c 464762 696682 9a97b9 c5c7dd e6e7f0 eee6ea e3cddf bfa5c9 87738f 564f5b 322f35 36282b 654956 966888 c090a9 d4b8b8 eae0dd f1ebdb ddcebf bda499 886e6a 594d4d 33272a b29476 e1bf89 f8e398 ffe9e3 fdc9c9 f6a2a8 e27285 b25266 64364b 2a1e23").split()
NEON = "8a3dff ff2bd6 ff7a1a ff2a3c 6dff3a 22f0ff 3dffc8 2f7bff ff3d7f c23bff f0ff2a".split()
EXT = ("3e4246 6e6a64 6a7178 7e858c b3ada2 122616 3c4a3a 4e5e48 65735a 7f8a6e 6e9f60 9eb280 3a2f3e 4e4054 654370 66566c 89609f a180b2 "
       "406977 5a6da6 5a8ca6 733a28 7a4a36 8e4a30 a65d3c ad7a5e bf7652 c98d68 caa184 d8b89a 43360c 635017 983a1b 804d17 806517 "
       "8a5a48 9c5e44 c8624d dd8877 f0cbae bfae8c d4c6a8 d0cb95 e8dcc4 37060b 7e0e0e 801c35 9f2d35 b81418 b81439 40740b 6b6f11 "
       "6f8707 6aa208 a2c113 8ce50c").split()
PALETTE = [None] + SPLENDOR + NEON + EXT          # index 0 is transparent
INDEX = {h: i for i, h in enumerate(PALETTE) if h}
assert len(PALETTE) == 1 + 128 + 11 + 56


def idx(h):
    h = h.lstrip("#").lower()
    if h not in INDEX:
        raise KeyError("not on the Pixel Studio palette: " + h)
    return INDEX[h]


def rgb(i):
    h = PALETTE[i]
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


# ---------------------------------------------------------------- materials
# ramp: dark -> light (palette hex); hi: a highlight above the ramp's top;
# line: the outline beside this material; emit: drawn flat, unlit.
MAT = {}


def material(name, ramp, hi=None, line=None, emit=False, gloss=0.0, cuts=None, pattern=None):
    """pattern: (kind, other material, width) - e.g. ("diag", "ink", 2) paints
    diagonal stripes of the other material's shades across this one."""
    MAT[name] = {"ramp": [idx(h) for h in ramp], "hi": idx(hi) if hi else None,
                 "line": idx(line) if line else idx(ramp[0]), "emit": emit, "gloss": gloss, "cuts": cuts,
                 "pattern": pattern}
    return name


material("steel", ["14121d", "282c3c", "485262", "5e718e", "88a3bc", "b8ccd8"], hi="dceaee", gloss=0.5)
material("gunmetal", ["171516", "2c3438", "465456", "64878c", "8ac4c3"], hi="afe9df", gloss=0.4)
material("graphite", ["0e0c0c", "171516", "323232", "595757", "807b7a", "a69e9a"], hi="cbc6c1", gloss=0.3)
material("grime", ["171516", "323232", "3e4246", "6a7178", "7e858c", "b3ada2"])
material("onyx", ["050403", "0e0c0c", "171819", "2c3438", "465456"], hi="64878c", gloss=0.8, line="050403")
material("rust", ["271f1b", "4f342f", "8c5b3e", "c68556", "e2b27e"])
material("mars", ["2a1e23", "733a28", "8e4a30", "a65d3c", "bf7652", "d8b89a"])
material("brass", ["271f1b", "452a1b", "724b2c", "b47538", "d6a851", "efdd91"], hi="fcf7be", gloss=0.6)
material("vantage", ["271f1b", "673931", "b05b2c", "e88a36", "fca570"], hi="ffe0b7", gloss=0.3)
material("hazard", ["271f1b", "724b2c", "d6a851", "f8c53a", "fff089"])
material("olive", ["181c19", "333c24", "586335", "7f8e44", "adb834"])
material("drab", ["122616", "3c4a3a", "4e5e48", "65735a", "7f8a6e", "9eb280"])
material("bone", ["33272a", "594d4d", "886e6a", "bda499", "ddcebf", "f1ebdb"])
material("white", ["373334", "695b59", "a69e9a", "cbc6c1", "ecebe7"], hi="ffffff", gloss=0.4)
material("flesh", ["4f342f", "8a5a48", "9c5e44", "c8624d", "dd8877", "f0cbae"])
material("sick", ["33272a", "594d4d", "886e6a", "b29476", "d4b8b8"])
material("blood", ["37060b", "7e0e0e", "9f2d35", "b81418", "c8624d"])
material("toxic", ["122616", "40740b", "6f8707", "8ce50c", "c4f129"])
material("violet", ["14121d", "3a2f3e", "4e4054", "654370", "89609f", "a180b2"])
material("blue", ["14121d", "1b2447", "2b4e95", "2789cd", "42bfe8"], hi="c9d4fd", gloss=0.5)
material("rubber", ["050403", "171516", "2d1b1e", "373334", "4c3d2e"])
material("cloth", ["14121d", "322f35", "564f5b", "87738f", "9a97b9"])
material("leather", ["171516", "2d1b1e", "4f342f", "8c5b3e", "b28b78"])
material("glass", ["14121d", "1b2447", "2b4e95", "8aa1f6", "c9d4fd"], hi="f1f2ff", gloss=1.0)
material("crystal", ["1b2447", "494182", "7864c6", "9c8bdb", "ceaaed"], hi="fad6ff", gloss=1.0)
material("acid", ["122616", "27412d", "42a459", "59cf93", "97edca"], hi="d0ffea", gloss=1.0)
# lights: flat colour
for nm, h in [("glow_orange", "ff7a1a"), ("glow_yellow", "f0ff2a"), ("glow_magenta", "ff2bd6"), ("glow_violet", "8a3dff"),
              ("glow_mint", "3dffc8"), ("glow_acid", "6dff3a"), ("glow_blue", "2f7bff"), ("glow_pink", "ff3d7f"),
              ("glow_plasma", "c23bff"), ("glow_white", "f1f2ff"), ("glow_amber", "f8c53a"), ("glow_red", "ff2a3c"),
              ("glow_cyan", "22f0ff")]:
    MAT[nm] = {"ramp": [idx(h)], "hi": None, "line": idx(h), "emit": True, "gloss": 0, "cuts": None, "pattern": None}
MAT["dark"] = {"ramp": [idx("050403")], "hi": None, "line": idx("050403"), "emit": True, "gloss": 0, "cuts": None, "pattern": None}


# ---------------------------------------------------------------- shapes (signed distance)
def _v(*a):
    return np.array(a, dtype=float)


class Shape:
    """A rounded 3D shape. f(p) -> distance for points p (N,3)."""
    def __init__(self, f, mat, emit_glow=False):
        self.f, self.mat = f, mat


def rot_y(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def rot_x(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def rot_z(a):
    c, s = math.cos(a), math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def _local(p, at, R):
    q = p - at
    return q @ R if R is not None else q          # R's columns are the local axes


def sphere(at, r, mat):
    at = _v(*at)
    return Shape(lambda p: np.linalg.norm(p - at, axis=1) - r, mat)


def ellipsoid(at, radii, mat, R=None):
    at, rr = _v(*at), _v(*radii)
    def f(p):
        q = _local(p, at, R)
        k0 = np.linalg.norm(q / rr, axis=1)
        k1 = np.linalg.norm(q / (rr * rr), axis=1)
        return k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)
    return Shape(f, mat)


def box(at, half, mat, r=0.0, R=None):
    at, h = _v(*at), _v(*half)
    def f(p):
        q = np.abs(_local(p, at, R)) - (h - r)
        out = np.linalg.norm(np.maximum(q, 0.0), axis=1)
        inside = np.minimum(np.max(q, axis=1), 0.0)
        return out + inside - r
    return Shape(f, mat)


def capsule(a, b, r, mat, r2=None):
    """A rod from a to b, radius r (tapering to r2 at b)."""
    a, b = _v(*a), _v(*b)
    r2 = r if r2 is None else r2
    ba = b - a
    L2 = float(ba @ ba)
    def f(p):
        pa = p - a
        h = np.clip((pa @ ba) / L2, 0.0, 1.0)
        return np.linalg.norm(pa - np.outer(h, ba), axis=1) - (r + (r2 - r) * h)
    return Shape(f, mat)


def cylinder(a, b, r, mat, round_=0.0):
    """A can from a to b, radius r, edges rounded by round_."""
    a, b = _v(*a), _v(*b)
    ba = b - a
    L = float(np.linalg.norm(ba))
    ax = ba / L
    def f(p):
        pa = p - a
        y = pa @ ax - L / 2.0
        x = np.linalg.norm(pa - np.outer(pa @ ax, ax), axis=1)
        dx = x - (r - round_)
        dy = np.abs(y) - (L / 2.0 - round_)
        out = np.linalg.norm(np.stack([np.maximum(dx, 0), np.maximum(dy, 0)], 1), axis=1)
        return out + np.minimum(np.maximum(dx, dy), 0.0) - round_
    return Shape(f, mat)


def cone(a, b, ra, rb, mat):
    """A frustum from a (radius ra) to b (radius rb)."""
    a, b = _v(*a), _v(*b)
    ba = b - a
    L = float(np.linalg.norm(ba))
    ax = ba / L
    def f(p):
        pa = p - a
        y = pa @ ax
        x = np.linalg.norm(pa - np.outer(y, ax), axis=1)
        # 2D sdf of a trapezoid in (x, y): y in [0,L], radius from ra to rb
        k = (rb - ra) / L
        rr = ra + k * np.clip(y, 0, L)
        side = (x - rr) / math.sqrt(1 + k * k)
        cap = np.maximum(-y, y - L)
        return np.maximum(side, cap)
    return Shape(f, mat)


def torus(at, R_, r, mat, R=None):
    at = _v(*at)
    def f(p):
        q = _local(p, at, R)
        qx = np.linalg.norm(q[:, [0, 2]], axis=1) - R_
        return np.sqrt(qx * qx + q[:, 1] ** 2) - r
    return Shape(f, mat)


def cut(shape, normal, offset):
    """Keep the part of a shape behind a plane (n.p <= offset)."""
    n = _v(*normal)
    n = n / np.linalg.norm(n)
    g = shape.f
    return Shape(lambda p: np.maximum(g(p), p @ n - offset), shape.mat)


def hollow(shape, inner):
    g, h = shape.f, inner.f
    return Shape(lambda p: np.maximum(g(p), -h(p)), shape.mat)


def blend(a, b, k=2.0):
    """Two shapes melted together (the first one's material)."""
    fa, fb = a.f, b.f
    def f(p):
        da, db = fa(p), fb(p)
        h = np.clip(0.5 + 0.5 * (db - da) / k, 0, 1)
        return db * (1 - h) + da * h - k * h * (1 - h)
    return Shape(f, a.mat)


def moved(shape, by=(0, 0, 0), R=None, about=(0, 0, 0)):
    """The same shape turned by R about a point, then moved."""
    by, about = _v(*by), _v(*about)
    g = shape.f
    def f(p):
        q = p - by - about
        if R is not None:
            q = q @ R
        return g(q + about)
    return Shape(f, shape.mat)


def mirror_x(shapes):
    """Each shape and its mirror across x = 0 (the model's own left/right)."""
    out = []
    for s in shapes:
        g = s.f
        out.append(s)
        out.append(Shape(lambda p, g=g: g(p * np.array([-1.0, 1, 1])), s.mat))
    return out


# ---------------------------------------------------------------- render
# how light the pictures come out (0.14 sample 2: "brighter, more colour")
LOOK = {"ambient": 0.34, "occ_min": 0.55, "skip_dark": True, "lo": 0.30, "top": 0.84}

LIGHT = _v(-0.62, 0.70, 0.55)
LIGHT = LIGHT / np.linalg.norm(LIGHT)


def render(shapes, size=48, foot=(24, 45), pitch=18.0, yaw=35.0, scale=1.0, light=None, steps=140, ao=True):
    """Ray-march the shapes. Returns (index image, depth) as arrays size x size.
    The model's ground point (0,0,0) lands on pixel `foot`; it faces +z and
    is turned by `yaw` degrees toward the right."""
    W = H = size if isinstance(size, int) else None
    if W is None:
        W, H = size
    th = math.radians(pitch)
    fwd = _v(0, -math.sin(th), -math.cos(th))
    up = _v(0, math.cos(th), -math.sin(th))
    right = _v(1, 0, 0)
    Ry = rot_y(math.radians(-yaw))           # rays into the model's frame
    jj, ii = np.mgrid[0:H, 0:W]
    sx = (ii + 0.5 - foot[0]) / scale
    sy = (foot[1] - (jj + 0.5)) / scale
    o = np.outer(sx.ravel(), right) + np.outer(sy.ravel(), up) - 200.0 * fwd
    d = np.tile(fwd, (o.shape[0], 1))
    o = o @ Ry.T
    d = d @ Ry.T
    lt = (light if light is not None else LIGHT) @ Ry.T
    n_rays = o.shape[0]
    t = np.zeros(n_rays)
    hit = np.zeros(n_rays, bool)
    alive = np.ones(n_rays, bool)
    fs = [s.f for s in shapes]

    def scene(p):
        ds = np.stack([f(p) for f in fs], 1)
        return ds.min(1), ds.argmin(1)

    for _ in range(steps):
        a = np.where(alive)[0]
        if a.size == 0:
            break
        p = o[a] + d[a] * t[a, None]
        dist, _m = scene(p)
        h = dist < 0.02
        hit[a[h]] = True
        alive[a[h]] = False
        t[a[~h]] += np.maximum(dist[~h], 0.01) * 0.9
        far = t > 420
        alive &= ~far
    hi = np.where(hit)[0]
    out = np.zeros(n_rays, np.int32)
    depth = np.full(n_rays, np.inf)
    matid = np.full(n_rays, -1)
    level = np.zeros(n_rays, np.int32)
    if hi.size:
        p = o[hi] + d[hi] * t[hi, None]
        _, m = scene(p)
        e = 0.06
        n = np.zeros_like(p)
        for k in range(3):
            dv = np.zeros(3); dv[k] = e
            n[:, k] = scene(p + dv)[0] - scene(p - dv)[0]
        n /= np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-9)
        diff = np.clip(n @ lt, 0, 1)
        occ = np.ones(hi.size)
        if ao:
            for k, step in enumerate((0.8, 1.6, 2.6, 3.8)):
                dd = scene(p + n * step)[0]
                occ -= np.clip((step - dd) / step, 0, 1) * (0.5 ** k) * 0.32
            occ = np.clip(occ, LOOK["occ_min"], 1)
        view = -d[hi]
        refl = 2 * (n @ lt)[:, None] * n - lt
        spec = np.clip(np.sum(refl * view, 1), 0, 1) ** 24
        for j, s in enumerate(shapes):
            sel = m == j
            if not sel.any():
                continue
            M = MAT[s.mat]
            full = M["ramp"]
            if M["emit"]:
                out[hi[sel]] = full[-1]
            else:
                skip = 1 if (LOOK["skip_dark"] and len(full) >= 4) else 0
                ramp = full[skip:]
                v = (LOOK["ambient"] + (1 - LOOK["ambient"]) * diff[sel]) * occ[sel]
                cuts = M["cuts"] or list(np.linspace(LOOK["lo"], LOOK["top"], len(ramp) - 1))
                lv = np.clip(np.searchsorted(np.array(cuts), v), 0, len(ramp) - 1) + skip
                level[hi[sel]] = lv
                col = np.array(full)[lv]
                if M["hi"] is not None and M["gloss"] > 0:
                    col = np.where(spec[sel] > 1.0 - 0.55 * M["gloss"], M["hi"], col)
                out[hi[sel]] = col
            matid[hi[sel]] = j
        depth[hi] = t[hi]
    render.level = level.reshape(H, W)
    return out.reshape(H, W), depth.reshape(H, W), matid.reshape(H, W), [s.mat for s in shapes]


def patterns(img, matid, mats, level):
    """Paint each pattern material's stripes (in the other material's matching shade)."""
    out = img.copy()
    H, W = img.shape
    for y in range(H):
        for x in range(W):
            j = matid[y, x]
            if j < 0:
                continue
            M = MAT[mats[j]]
            pat = M.get("pattern")
            if not pat or img[y, x] == M.get("hi"):
                continue
            kind, other, width = pat
            on = ((x + y) // width) % 2 == 0 if kind == "diag" else ((x - y) // width) % 2 == 0 if kind == "diag2" else (y // width) % 2 == 0
            if on:
                R2 = MAT[other]["ramp"]
                lv = int(level[y, x])
                out[y, x] = R2[min(len(R2) - 1, round(lv * (len(R2) - 1) / max(1, len(M["ramp"]) - 1)))]
    return out


def finish(img, depth, matid, mats, outline=True, inner=True, inner_step=2.2, clean=True, line=None):
    """Outlines: the edge of the figure gets a line in the darkest shade of the
    material beside it; where a near part covers a far one, the far side gets
    a darker line. Lone pixels are tidied away."""
    H, W = img.shape
    out = img.copy()
    solid = img > 0
    if clean:
        for y in range(H):
            for x in range(W):
                if solid[y, x]:
                    nb = sum(1 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))
                             if 0 <= x + dx < W and 0 <= y + dy < H and solid[y + dy, x + dx])
                    if nb == 0:
                        out[y, x] = 0
        solid = out > 0
    if inner:
        dark = out.copy()
        for y in range(H):
            for x in range(W):
                if not solid[y, x]:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    X, Y = x + dx, y + dy
                    if 0 <= X < W and 0 <= Y < H and solid[Y, X] and depth[Y, X] - depth[y, x] > inner_step:
                        m = mats[matid[Y, X]] if matid[Y, X] >= 0 else None
                        if m and not MAT[m]["emit"]:
                            ramp = MAT[m]["ramp"]
                            cur = list(ramp).index(out[Y, X]) if out[Y, X] in ramp else len(ramp) - 1
                            dark[Y, X] = ramp[max(0, min(cur - 2, 1))] if len(ramp) > 2 else ramp[0]
        out = dark
    if outline:
        ring = np.zeros_like(out)
        for y in range(H):
            for x in range(W):
                if solid[y, x]:
                    continue
                best = None
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    X, Y = x + dx, y + dy
                    if 0 <= X < W and 0 <= Y < H and solid[Y, X]:
                        m = mats[matid[Y, X]] if matid[Y, X] >= 0 else None
                        best = line if line else (MAT[m]["line"] if m else idx("0e0c0c"))
                        if m and MAT[m]["emit"]:
                            best = idx("0e0c0c") if not line else line
                        break
                if best:
                    ring[y, x] = best
        out = np.where(ring > 0, ring, out)
    return out


def shapes_bbox(img):
    ys, xs = np.nonzero(img)
    if ys.size == 0:
        return None
    return xs.min(), ys.min(), xs.max(), ys.max()


# ---------------------------------------------------------------- 2D touches
def put(img, x, y, colour):
    H, W = img.shape
    if 0 <= x < W and 0 <= y < H:
        img[y, x] = idx(colour) if isinstance(colour, str) else colour


def stamp(img, rows, x0, y0, key):
    """Paint an ASCII picture: each character maps to a palette hex (or None to skip)."""
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            c = key.get(ch)
            if c:
                put(img, x0 + i, y0 + j, c)


# ---------------------------------------------------------------- output
def to_png(img, path, scale=1):
    H, W = img.shape
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    for y in range(H):
        for x in range(W):
            i = int(img[y, x])
            if i:
                r, g, b = rgb(i)
                px[x, y] = (r, g, b, 255)
    if scale != 1:
        im = im.resize((W * scale, H * scale), Image.NEAREST)
    im.save(path)
    return im


def from_png(path):
    im = Image.open(path).convert("RGBA")
    W, H = im.size
    px = im.load()
    out = np.zeros((H, W), np.int32)
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a >= 128:
                out[y, x] = INDEX["%02x%02x%02x" % (r, g, b)]
    return out


def studio_encode(arr):
    """The Pixel Studio's storage: runs of (count, colour) as base64."""
    flat = [int(v) for v in np.asarray(arr).ravel()]
    b = bytearray()
    i, n = 0, len(flat)
    while i < n:
        v, run = flat[i], 1
        while i + run < n and flat[i + run] == v and run < 255:
            run += 1
        b += bytes((run, v))
        i += run
    return base64.b64encode(bytes(b)).decode("ascii")


def studio_picture(img, name):
    H, W = img.shape
    enc = studio_encode(img)
    return {"v": 1, "w": int(W), "h": int(H), "name": name, "frames": [{"layers": [
        {"name": "Layer 1", "visible": True, "locked": False, "opacity": 100, "mode": "view", "px": enc}]}], "flat": enc}


# ---------------------------------------------------------------- previews
def preview_path(name):
    """Where a contact sheet to look at goes: out/, beside these scripts."""
    d = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")
    os.makedirs(d, exist_ok=True)
    return os.path.join(d, name)


def sheet(images, path, scale=4, bg="2c3438", labels=None, cols=None, pad=6, show1x=True):
    """Lay pictures out on a dark ground: each at 1x (small) and scaled."""
    from PIL import ImageDraw
    cols = cols or len(images)
    rows = (len(images) + cols - 1) // cols
    cw = max(i.shape[1] for i in images) * scale + pad * 2
    ch = max(i.shape[0] for i in images) * scale + pad * 2 + (max(i.shape[0] for i in images) + pad if show1x else 0) + (14 if labels else 0)
    canvas = Image.new("RGBA", (cols * cw, rows * ch), tuple(int(bg[k:k + 2], 16) for k in (0, 2, 4)) + (255,))
    d = ImageDraw.Draw(canvas)
    for n, img in enumerate(images):
        cx, cy = (n % cols) * cw, (n // cols) * ch
        big = to_png(img, os.path.join(tempfile.gettempdir(), "_k.png"), scale=scale)
        canvas.alpha_composite(big, (cx + pad, cy + pad))
        if show1x:
            small = to_png(img, os.path.join(tempfile.gettempdir(), "_k1.png"), scale=1)
            canvas.alpha_composite(small, (cx + pad, cy + pad + img.shape[0] * scale + 4))
            small2 = to_png(img, os.path.join(tempfile.gettempdir(), "_k2.png"), scale=2)
            canvas.alpha_composite(small2, (cx + pad + img.shape[1] + 8, cy + pad + img.shape[0] * scale + 4))
        if labels:
            d.text((cx + pad, cy + ch - 14), labels[n], fill=(200, 210, 220, 255))
    canvas.save(path)
    return canvas


def despeckle(img, keep=()):
    """A pixel whose four neighbours all share one other colour takes that
    colour (keeps the shading bands clean). Colours in `keep` are left alone."""
    H, W = img.shape
    out = img.copy()
    keep = set(idx(k) if isinstance(k, str) else k for k in keep)
    for y in range(1, H - 1):
        for x in range(1, W - 1):
            c = img[y, x]
            if c == 0 or c in keep:
                continue
            n = {img[y - 1, x], img[y + 1, x], img[y, x - 1], img[y, x + 1]}
            if len(n) == 1:
                v = n.pop()
                if v != c and v != 0:
                    out[y, x] = v
    return out


def emissive_ids():
    return [m["ramp"][0] for m in MAT.values() if m["emit"]]


def make(shapes, size=48, foot=None, pitch=18, yaw=40, scale=1.0, line=None, inner_step=2.2, speck=True):
    """Render + finish in one go."""
    foot = foot or (size // 2, size - 3)
    img, depth, mid, mats = render(shapes, size=size, foot=foot, pitch=pitch, yaw=yaw, scale=scale)
    img = patterns(img, mid, mats, render.level)
    if speck:
        img = despeckle(img, keep=emissive_ids())
    return finish(img, depth, mid, mats, line=line, inner_step=inner_step)
