"""The fight's props, seen from a little higher than the Units (the board is flat)."""
import math
from kart import *
from rigs import *
import sample

P = {}


def prop(name, size=48, foot=(24, 40), yaw=0, pitch=45, scale=1.0, inner=0.8):
    def deco(fn):
        P[name] = {"fn": fn, "size": size, "foot": foot, "yaw": yaw, "pitch": pitch, "scale": scale, "inner": inner}
        return fn
    return deco


def render_prop(name):
    p = P[name]
    return make(p["fn"](), size=p["size"], foot=p["foot"], yaw=p["yaw"], pitch=p["pitch"], scale=p["scale"], inner_step=p["inner"])


@prop("half_cover_a", foot=(24, 38), pitch=45, scale=1.35)
def half_cover_a():
    return sample.sandbags()


@prop("half_cover_b", foot=(24, 38), pitch=45, scale=1.25)
def half_cover_b():
    """Low concrete blocks with a stripe."""
    S = []
    for k, (x, z, a) in enumerate(((-9.0, 0.0, 0.15), (0.0, 1.0, 0.0), (9.0, 0.0, -0.15))):
        b = box((x, 3.4, z), (4.2, 3.4, 3.0), "concrete", r=0.7)
        S.append(moved(b, R=rot_y(a), about=(x, 0, z)))
        S.append(moved(box((x, 5.6, z + 2.9), (3.6, 0.8, 0.3), "warning", r=0.2), R=rot_y(a), about=(x, 0, z)))
    S.append(capsule((-12.0, 7.0, 0.0), (12.0, 7.0, 1.0), 0.35, "steel"))           # a rail of rebar
    return S


@prop("full_cover_a", foot=(24, 42), pitch=38, scale=1.0)
def full_cover_a():
    return sample.barrier()


@prop("full_cover_b", foot=(24, 44), pitch=38, scale=1.0)
def full_cover_b():
    """Two containers, stacked."""
    S = [box((0, 6.0, 0), (13.0, 6.0, 5.0), "crimson", r=0.6), box((1.0, 17.6, -0.4), (12.0, 5.4, 4.6), "teal", r=0.6)]
    for x in range(-11, 12, 3):
        S.append(box((x, 6.0, 5.0), (0.5, 5.4, 0.3), "blood", r=0.1))
        S.append(box((x + 1.0, 17.6, 4.2), (0.5, 4.8, 0.3), "khaki", r=0.1))
    S.append(box((-6.0, 7.0, 5.3), (2.6, 1.4, 0.2), "white", r=0.1))
    return S


@prop("crate", size=32, foot=(16, 27), yaw=25, pitch=40, scale=1.15, inner=0.6)
def crate():
    return sample.crate()


@prop("locked_chest", size=32, foot=(16, 27), yaw=25, pitch=40, scale=1.15, inner=0.6)
def locked_chest():
    S = [box((0, 4.6, 0), (7.0, 4.6, 4.6), "gunmetal", r=0.8)]
    lid = cut(cylinder((-7.0, 9.0, 0), (7.0, 9.0, 0), 4.6, "gunmetal", round_=0.6), (0, -1, 0), -9.0)
    S.append(lid)
    for x in (-5.0, 5.0):
        S.append(box((x, 7.0, 0), (0.9, 6.8, 4.9), "brass", r=0.3))
    S.append(box((0, 8.0, 4.8), (1.8, 2.0, 0.6), "graphite", r=0.4))
    S.append(sphere((0, 8.0, 5.4), 0.9, "glow_amber"))
    return S


@prop("emergency_exit", size=48, foot=(24, 36), pitch=62, scale=1.0, inner=0.6)
def emergency_exit():
    S = [box((0, 0.8, 0), (13.0, 0.8, 11.0), "graphite", r=0.6),
         box((0, 1.4, 0), (10.6, 0.6, 8.8), "warning", r=0.3),
         box((0, 1.8, 0), (8.6, 0.6, 6.8), "steel", r=0.4)]
    for x in (-4.0, 0.0, 4.0):
        S.append(box((x, 2.4, 0), (1.2, 0.3, 6.0), "graphite", r=0.2))
    S.append(box((0, 2.6, 4.0), (4.0, 0.3, 0.8), "glow_acid", r=0.2))
    S.append(capsule((9.6, 1.0, -7.6), (9.6, 9.0, -7.6), 0.6, "graphite"))          # a lit post
    S.append(box((9.6, 10.0, -7.6), (2.4, 1.6, 0.6), "glow_acid", r=0.2))
    return S


@prop("healing_station", size=48, foot=(24, 40), pitch=40, scale=1.0, inner=0.6)
def healing_station():
    S = [box((0, 1.0, 0), (8.0, 1.0, 6.0), "graphite", r=0.5),
         box((0, 10.0, -1.0), (6.0, 9.0, 4.0), "medic", r=1.2),
         box((0, 13.0, 3.2), (3.6, 3.6, 0.6), "graphite", r=0.6),
         box((0, 13.0, 3.8), (2.6, 0.8, 0.2), "glow_mint", r=0.1),
         box((0, 13.0, 3.8), (0.8, 2.6, 0.2), "glow_mint", r=0.1),
         capsule((-5.0, 4.0, 3.0), (-8.0, 4.0, 6.0), 0.6, "teal"),
         capsule((5.0, 4.0, 3.0), (8.6, 2.0, 5.0), 0.6, "teal")]
    S.append(cylinder((-7.0, 2.0, -4.0), (-7.0, 12.0, -4.0), 1.6, "glass", round_=0.4))
    S.append(cylinder((-7.0, 3.0, -4.0), (-7.0, 9.0, -4.0), 1.2, "glow_mint"))
    return S


NAMES = list(P)

if __name__ == "__main__":
    imgs = [render_prop(n) for n in NAMES]
    sheet(imgs, preview_path("props.png"), scale=3, labels=NAMES, cols=4, show1x=False)
