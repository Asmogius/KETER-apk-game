"""Stand-in pictures: one object per card type for the card face's art window
(64 x 45, transparent: the card fills the window with its District colour),
and four silhouettes for Units that have no token of their own yet."""
import math
import numpy as np
from kart import *
from rigs import *
import units

C = {}


def card(name, yaw=30, pitch=28, scale=1.0, foot=(32, 41)):
    def deco(fn):
        C[name] = {"fn": fn, "yaw": yaw, "pitch": pitch, "scale": scale, "foot": foot}
        return fn
    return deco


def render_card(name):
    c = C[name]
    return make(c["fn"](), size=(64, 45), foot=c["foot"], yaw=c["yaw"], pitch=c["pitch"], scale=c["scale"], inner_step=0.9)


@card("action", yaw=20, pitch=20, foot=(32, 40))
def action():
    """A bolt of light striking down."""
    S = []
    pts = [(-8, 34), (2, 24), (-3, 22), (8, 8), (-1, 16), (4, 18), (-6, 30)]
    for a, b in zip(pts, pts[1:]):
        S.append(capsule((a[0], a[1], 0), (b[0], b[1], 0), 1.8, "glow_amber"))
        S.append(capsule((a[0], a[1], 0.6), (b[0], b[1], 0.6), 0.8, "glow_white"))
    for k in range(6):
        t = k * math.pi / 3
        S.append(capsule((8 + 3 * math.cos(t), 6 + 2 * math.sin(t), 0), (8 + 9 * math.cos(t), 6 + 5 * math.sin(t), 0), 0.6, "glow_orange"))
    S.append(ellipsoid((8, 2.0, 0), (9.0, 1.4, 4.0), "slag"))
    return S


@card("equipment", yaw=35, pitch=24)
def equipment():
    """A powered gauntlet."""
    S = [box((0, 14.0, 0), (6.0, 7.0, 5.0), "steel", r=2.0),
         box((0, 14.0, 4.4), (4.2, 5.0, 1.2), "vantage", r=1.0),
         box((0, 23.0, 0), (5.4, 3.0, 4.6), "graphite", r=1.2)]
    for k, x in enumerate((-3.6, -1.2, 1.2, 3.6)):
        S.append(capsule((x, 22.0, 3.0), (x, 30.0 - abs(k - 1.5), 5.0), 1.2, "steel"))
        S.append(sphere((x, 30.0 - abs(k - 1.5), 5.0), 1.3, "graphite"))
    S.append(capsule((6.0, 18.0, 2.0), (9.0, 24.0, 4.0), 1.2, "steel"))
    S.append(sphere((0, 14.0, 5.8), 1.4, "glow_amber"))
    S.append(box((0, 4.0, 0), (5.6, 3.0, 4.6), "rubber", r=1.0))
    return S


@card("command", yaw=10, pitch=40)
def command():
    """A field tablet showing a target."""
    S = [box((0, 14.0, 0), (14.0, 1.2, 10.0), "graphite", r=1.0),
         box((0, 15.0, 0), (12.6, 0.4, 8.6), "glass", r=0.3)]
    S.append(torus((2.0, 15.6, 0.0), 4.0, 0.45, "glow_orange"))
    S.append(torus((2.0, 15.6, 0.0), 1.8, 0.4, "glow_orange"))
    for (x, z) in ((-8.0, -4.0), (-6.0, 4.0), (8.0, 5.0)):
        S.append(sphere((x, 15.6, z), 0.9, "glow_mint"))
    S.append(capsule((-6.0, 15.6, 4.0), (2.0, 15.6, 0.0), 0.3, "glow_mint"))
    return S


@card("consumable", yaw=30, pitch=26)
def consumable():
    """A stim injector."""
    S = [cylinder((0, 6.0, 0), (0, 26.0, 0), 3.4, "glass", round_=1.0),
         cylinder((0, 8.0, 0), (0, 22.0, 0), 2.7, "glow_acid"),
         cylinder((0, 26.0, 0), (0, 30.0, 0), 3.0, "steel", round_=0.8),
         box((0, 30.6, 0), (5.0, 0.8, 1.6), "graphite", r=0.3),
         cylinder((0, 1.0, 0), (0, 6.0, 0), 2.2, "steel", round_=0.6),
         capsule((0, 1.0, 0), (0, -4.0, 0), 0.4, "silver")]
    S.append(torus((0, 16.0, 0), 3.4, 0.6, "crimson"))
    return S


@card("aether", yaw=25, pitch=24)
def aether():
    """A cluster of Aether crystals."""
    S = [ellipsoid((0, 2.0, 0), (12.0, 3.0, 7.0), "slag")]
    for (x, z, h, a, r) in ((0.0, 0.0, 26.0, 0.0, 4.0), (-7.0, 1.0, 16.0, 0.35, 3.0), (7.0, -1.0, 18.0, -0.3, 3.2),
                            (-3.0, -3.0, 12.0, 0.15, 2.4), (4.0, 3.0, 10.0, -0.5, 2.2)):
        c = cone((x, 1.0, z), (x, h, z), r, 0.3, "crystal")
        S.append(moved(c, R=rot_z(a), about=(x, 1.0, z)))
    S.append(sphere((0, 10.0, 2.6), 1.4, "glow_mint"))
    return S


@card("sphere", yaw=20, pitch=40)
def sphere_chip():
    """An Aether chip."""
    S = [cylinder((0, 10.0, 0), (0, 12.0, 0), 12.0, "graphite", round_=0.8)]
    S.append(cylinder((0, 12.0, 0), (0, 12.6, 0), 9.0, "gold", round_=0.3))
    S.append(cylinder((0, 12.6, 0), (0, 13.4, 0), 5.0, "glow_mint"))
    for a in range(6):
        t = a * math.pi / 3
        S.append(box((math.cos(t) * 10.4, 11.0, math.sin(t) * 10.4), (1.6, 1.2, 1.6), "gold", r=0.4))
    return S


@card("prototype", yaw=30, pitch=24)
def prototype():
    """A device nobody should touch: an orb in a cage."""
    S = [cylinder((0, 1.0, 0), (0, 5.0, 0), 9.0, "graphite", round_=1.0),
         cylinder((0, 30.0, 0), (0, 33.0, 0), 7.0, "graphite", round_=1.0),
         sphere((0, 17.0, 0), 7.0, "glow_violet"),
         sphere((-1.6, 18.4, 3.4), 3.0, "glow_white")]
    for a in range(5):
        t = a * 2 * math.pi / 5 + 0.3
        S.append(capsule((math.cos(t) * 8.0, 4.0, math.sin(t) * 8.0), (math.cos(t) * 8.0, 31.0, math.sin(t) * 8.0), 0.8, "brass"))
    S.append(box((0, 3.0, 8.6), (3.0, 1.0, 0.6), "warning", r=0.2))
    return S


# the four stand-ins for Units without a token: dark shapes, lit at the edge
def silhouette(img):
    out = np.zeros_like(img)
    H, W = img.shape
    for y in range(H):
        for x in range(W):
            if img[y, x]:
                edge = any(not (0 <= x + dx < W and 0 <= y + dy < H) or img[y + dy, x + dx] == 0 for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
                up = (y > 0 and img[y - 1, x] == 0) or (x > 0 and img[y, x - 1] == 0)
                out[y, x] = idx("88a3bc") if (edge and up) else idx("0e0c0c") if edge else idx("2c3438")
    return out


def standin(kind):
    if kind == "ranged":
        return silhouette(units.render_unit("Bipedal"))
    if kind == "drone":
        return silhouette(units.render_unit("Quadcopter"))
    if kind == "beast":
        return silhouette(units.render_unit("Quadruped"))
    S, H = person(pose="melee", build=1.1)
    S += head("helmet", H["head"], {})
    S += blade(H["R"], length=10.0, up=True)
    return silhouette(make(S, size=48, foot=(24, 46), yaw=45, scale=1.08))


STANDINS = ["melee", "ranged", "drone", "beast"]

if __name__ == "__main__":
    imgs = [render_card(n) for n in C]
    sheet(imgs, preview_path("cards.png"), scale=4, labels=list(C), cols=4, show1x=False)
    sheet([standin(k) for k in STANDINS], preview_path("standins.png"), scale=4, labels=STANDINS, cols=4, show1x=False)
