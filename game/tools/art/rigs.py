"""Reusable bodies for KETER's Units: people, bots, beasts and walkers, each a
list of shapes a recipe can add to. Models face +z with their feet at y = 0;
1 unit is 1 pixel before the token's scale."""
import math
import numpy as np
from kart import *

# ------------------------------------------------------------ extra materials
material("navy", ["14121d", "1b2447", "494182", "4572e3", "8aa1f6"], hi="c9d4fd", gloss=0.3)
material("sand", ["2a1e23", "4f342f", "8c5b3e", "b29476", "e1bf89"])
material("concrete", ["171516", "373334", "595757", "807b7a", "a69e9a", "cbc6c1"])
material("silver", ["322f35", "564f5b", "a69e9a", "cbc6c1", "ecebe7"], hi="ffffff", gloss=0.3)
material("ink", ["050403", "0e0c0c", "171516", "2d1b1e", "373334"])
material("warning", ["271f1b", "724b2c", "d6a851", "f8c53a", "fff089"], pattern=("diag", "ink", 2))
material("sack", ["2a1e23", "724b2c", "b29476", "e1bf89", "f6d896"])
material("sanitation", ["322f35", "5e718e", "88a3bc", "b8ccd8", "dceaee"], hi="f1f2ff", gloss=0.4)   # cleaner-bot white
material("teal", ["14121d", "2c3b39", "486859", "5d9b79", "86c69a"], hi="b5e7cb", gloss=0.3)
material("crimson", ["2a1e23", "64364b", "9f2d35", "b25266", "e27285"], hi="f6a2a8", gloss=0.2)
material("plum", ["14121d", "322f35", "564f5b", "87738f", "bfa5c9"], hi="e3cddf", gloss=0.3)
material("khaki", ["181c19", "4e5e48", "65735a", "7f8a6e", "9eb280"])
material("ochre", ["271f1b", "635017", "806517", "b47538", "d6a851"], hi="efdd91", gloss=0.3)
material("medic", ["322f35", "a69e9a", "cbc6c1", "ecebe7", "ffffff"])
material("charcoal", ["0e0c0c", "171516", "2d1b1e", "373334", "595757"], hi="807b7a", gloss=0.2)
material("slag", ["271f1b", "4c3d2e", "724b2c", "855f39", "b28b78"])
material("pale", ["4f342f", "886e6a", "b29476", "d4b8b8", "eae0dd"])
material("jade", ["122616", "27412d", "3d6f43", "42a459", "59cf93"], hi="97edca", gloss=0.5)
material("gold", ["271f1b", "724b2c", "b47538", "d6a851", "f8e398"], hi="fcf7be", gloss=0.8)
material("lilac", ["14121d", "494182", "7864c6", "9c8bdb", "ceaaed"], hi="fad6ff", gloss=0.6)
material("rose", ["2a1e23", "64364b", "b25266", "e27285", "f6a2a8"])


# ------------------------------------------------------------ people
def head(kind, at, mats, size=1.0, facing=0.0):
    """kind: helmet, face, hood, mask, bucket, dome, cap, visor, skull."""
    x, y, z = at
    S = []
    s = size
    m = mats
    if kind == "helmet":
        S.append(ellipsoid((x, y, z), (3.2 * s, 3.4 * s, 3.4 * s), m.get("helmet", "graphite")))
        S.append(box((x, y + 0.2 * s, z + 2.6 * s), (2.6 * s, 0.85 * s, 0.9 * s), m.get("eye", "glow_orange"), r=0.35))
    elif kind == "visor":                                       # a full visor across the front
        S.append(ellipsoid((x, y, z), (3.1 * s, 3.4 * s, 3.3 * s), m.get("helmet", "graphite")))
        v = ellipsoid((x, y + 0.3 * s, z + 0.6 * s), (2.9 * s, 1.5 * s, 3.0 * s), m.get("eye", "glass"))
        S.append(cut(v, (0, 0, -1), -z - 0.4 * s))
    elif kind == "face":
        S.append(ellipsoid((x, y, z + 0.3), (2.7 * s, 3.1 * s, 2.7 * s), m.get("skin", "flesh")))
        hair = ellipsoid((x - 0.2, y + 1.0 * s, z - 0.6), (3.0 * s, 3.0 * s, 3.0 * s), m.get("hair", "charcoal"))
        S.append(cut(hair, (0.25, -0.55, 1), y * -0.55 + z + 0.9 * s + x * 0.25))
        S.append(sphere((x + 1.2 * s, y - 0.1 * s, z + 2.7 * s), 0.5 * s, m.get("eye", "dark")))
        S.append(sphere((x - 1.1 * s, y - 0.1 * s, z + 2.6 * s), 0.45 * s, m.get("eye2", m.get("eye", "dark"))))
    elif kind == "hood":
        S.append(ellipsoid((x, y - 0.2, z + 0.6), (2.5 * s, 2.8 * s, 2.5 * s), m.get("skin", "flesh")))
        hood = ellipsoid((x, y + 0.6 * s, z - 0.3), (3.4 * s, 3.6 * s, 3.5 * s), m.get("hood", "cloth"))
        S.append(hollow(hood, ellipsoid((x, y - 0.4 * s, z + 2.8 * s), (2.2 * s, 2.6 * s, 2.0 * s), "cloth")))
        S.append(sphere((x + 1.0 * s, y - 0.2 * s, z + 2.8 * s), 0.5 * s, m.get("eye", "glow_amber")))
    elif kind == "mask":                                        # a gas mask
        S.append(ellipsoid((x, y, z), (3.0 * s, 3.3 * s, 3.1 * s), m.get("helmet", "rubber")))
        S.append(sphere((x + 1.2 * s, y + 0.6 * s, z + 2.6 * s), 0.9 * s, m.get("eye", "glow_amber")))
        S.append(sphere((x - 1.2 * s, y + 0.6 * s, z + 2.6 * s), 0.9 * s, m.get("eye", "glow_amber")))
        S.append(cylinder((x, y - 1.4 * s, z + 2.2 * s), (x, y - 1.9 * s, z + 4.0 * s), 1.1 * s, m.get("filter", "graphite"), round_=0.3))
    elif kind == "bucket":                                      # a blocky robot head
        S.append(box((x, y, z), (2.8 * s, 2.6 * s, 2.8 * s), m.get("helmet", "steel"), r=0.8))
        S.append(box((x, y + 0.3 * s, z + 2.6 * s), (2.2 * s, 0.7 * s, 0.6 * s), m.get("eye", "glow_orange"), r=0.2))
    elif kind == "dome":                                        # a round robot head with one eye
        S.append(sphere((x, y, z), 3.1 * s, m.get("helmet", "sanitation")))
        S.append(sphere((x, y + 0.3 * s, z + 2.6 * s), 1.2 * s, m.get("eye", "glow_magenta")))
    elif kind == "cap":                                         # a face under a hard hat
        S.append(ellipsoid((x, y - 0.3, z + 0.3), (2.6 * s, 2.9 * s, 2.6 * s), m.get("skin", "flesh")))
        S.append(cut(ellipsoid((x, y + 1.2 * s, z), (3.3 * s, 2.6 * s, 3.4 * s), m.get("hat", "hazard")), (0, -1, 0), -(y + 0.6 * s)))
        S.append(cylinder((x, y + 0.7 * s, z + 0.4), (x, y + 0.9 * s, z + 0.4), 3.8 * s, m.get("hat", "hazard")))
        S.append(box((x, y + 0.1 * s, z + 2.5 * s), (2.1 * s, 0.6 * s, 0.6 * s), m.get("eye", "glass"), r=0.2))
    elif kind == "skull":                                       # a grinning metal jaw
        S.append(ellipsoid((x, y + 0.6, z), (2.7 * s, 2.8 * s, 2.7 * s), m.get("skin", "pale")))
        S.append(box((x, y - 1.4 * s, z + 1.0 * s), (2.4 * s, 1.3 * s, 2.2 * s), m.get("jaw", "steel"), r=0.6))
        for k in range(-2, 3):
            S.append(box((x + k * 0.9 * s, y - 1.0 * s, z + 3.1 * s), (0.25, 0.7 * s, 0.2), "white"))
        S.append(sphere((x + 1.2 * s, y + 0.9 * s, z + 2.4 * s), 0.6 * s, m.get("eye", "glow_orange")))
        S.append(sphere((x - 1.1 * s, y + 0.9 * s, z + 2.3 * s), 0.5 * s, m.get("eye2", "dark")))
    return S


def lean(shapes, pts, angle, about):
    """Tip shapes (and named points) forward by angle about a point."""
    if not angle:
        return shapes, pts
    R = rot_x(angle)
    a = np.array(about, float)
    out = [moved(s, R=R, about=about) for s in shapes]
    Rm = np.array([[1, 0, 0], [0, math.cos(angle), -math.sin(angle)], [0, math.sin(angle), math.cos(angle)]])
    newp = {}
    for k, v in pts.items():
        if isinstance(v, tuple) and len(v) == 3:
            q = Rm @ (np.array(v, float) - a) + a
            newp[k] = tuple(float(c) for c in q)
        else:
            newp[k] = v
    return out, newp


def person(pose="rifle", build=1.0, height=1.0, mats=None, headkind="helmet", coat=False, skirt=False, pads=True,
           backpack=None, belt=True, hunch=0.0):
    """A standing person or android. Returns (shapes, hands): hands = {"R": (x,y,z), "L": ...}."""
    m = {"legs": "graphite", "boots": "rubber", "hips": "graphite", "torso": "steel", "chest": None, "pads": None,
         "arms": "graphite", "hands": "graphite", "belt": "leather"}
    m.update(mats or {})
    b, h = build, height
    S = []
    hip_y, knee_y, ank_y = 15.0 * h, 8.8 * h, 2.6 * h
    lw = 1.65 * b
    for sx in (-1, 1):
        S.append(capsule((sx * 2.4 * b, hip_y, 0), (sx * 2.7 * b, knee_y, 0.8), lw, m["legs"]))
        S.append(capsule((sx * 2.7 * b, knee_y, 0.8), (sx * 2.5 * b, ank_y, 0), lw * 0.9, m["legs"]))
        S.append(box((sx * 2.6 * b, 1.6, 0.9), (1.8 * b, 1.6, 2.7 * b), m["boots"], r=0.8))
        if m.get("knees"):
            S.append(box((sx * 2.8 * b, knee_y + 0.6, 1.8 * b), (1.5 * b, 2.0, 0.9), m["knees"], r=0.6))
    if coat:
        c = cone((0, hip_y + 1.6, -0.4), (0, 4.5 * h, -1.6), 4.6 * b, 7.0 * b, m.get("coat", m["torso"]))
        S.append(cut(c, (0, 0, 1), 0.6))
    if skirt:
        S.append(cone((0, hip_y + 1.2, 0), (0, hip_y - 4.0, 0), 4.3 * b, 5.2 * b, m.get("skirt", m["hips"])))
    S.append(box((0, hip_y + 1.2, 0), (3.9 * b, 1.7, 2.4 * b), m["hips"], r=0.9))
    if belt:
        S.append(box((0, hip_y + 1.6, 0.25), (4.2 * b, 0.8, 2.7 * b), m["belt"], r=0.4))
    low = S
    S = []
    cy = hip_y + 6.0 * h
    S.append(box((0, cy, 0), (4.4 * b, 4.6 * h, 2.7 * b), m["torso"], r=1.5))
    if m.get("chest"):
        S.append(box((0, cy + 0.4, 1.9 * b), (3.0 * b, 3.2 * h, 1.2), m["chest"], r=0.9))
    sy = cy + 3.6 * h
    sw = 4.9 * b
    if pads and m.get("pads"):
        for sx in (-1, 1):
            S.append(sphere((sx * sw, sy, 0), 2.3 * b, m["pads"]))
    if backpack:
        S.append(box((0, cy + 0.5, -3.6 * b), (3.2 * b, 3.6 * h, 1.6), backpack, r=0.9))
    aw = 1.2 * b
    hands = {}
    # arms by pose (R = the model's right, +x)
    if pose == "rifle":
        R, L = (2.4 * b, cy - 1.8, 5.8), (0.2, cy - 1.0, 9.6)
        S += [capsule((sw, sy - 0.4, 0.2), (sw + 0.9, cy - 1.5, 1.8), aw, m["arms"]), capsule((sw + 0.9, cy - 1.5, 1.8), R, aw * 0.95, m["arms"]),
              capsule((-sw, sy - 0.4, 0.2), (-sw + 0.4, cy - 1.4, 4.2), aw, m["arms"]), capsule((-sw + 0.4, cy - 1.4, 4.2), L, aw * 0.95, m["arms"])]
    elif pose == "pistol":
        R, L = (sw - 0.2, cy + 0.2, 8.6), (-sw - 0.6, cy - 4.4, 0.8)
        S += [capsule((sw, sy - 0.4, 0.2), (sw + 0.6, cy + 0.4, 4.0), aw, m["arms"]), capsule((sw + 0.6, cy + 0.4, 4.0), R, aw * 0.95, m["arms"]),
              capsule((-sw, sy - 0.4, 0), (-sw - 0.9, cy - 0.6, -0.4), aw, m["arms"]), capsule((-sw - 0.9, cy - 0.6, -0.4), L, aw * 0.95, m["arms"])]
    elif pose == "melee":                                       # weapon raised in the right hand
        R, L = (sw + 0.6, sy + 4.0, 1.8), (-sw + 0.8, cy - 0.5, 5.0)
        S += [capsule((sw, sy - 0.2, 0), (sw + 1.6, sy + 1.0, -1.2), aw, m["arms"]), capsule((sw + 1.6, sy + 1.0, -1.2), R, aw * 0.95, m["arms"]),
              capsule((-sw, sy - 0.4, 0.2), (-sw - 0.4, cy - 1.0, 2.6), aw, m["arms"]), capsule((-sw - 0.4, cy - 1.0, 2.6), L, aw * 0.95, m["arms"])]
    elif pose == "low":                                         # a weapon held low and forward in the right hand
        R, L = (sw + 0.2, cy - 3.2, 5.6), (-sw - 0.6, cy - 4.4, 0.8)
        S += [capsule((sw, sy - 0.4, 0.2), (sw + 0.8, cy - 1.0, 1.8), aw, m["arms"]), capsule((sw + 0.8, cy - 1.0, 1.8), R, aw * 0.95, m["arms"]),
              capsule((-sw, sy - 0.4, 0), (-sw - 0.9, cy - 0.6, -0.4), aw, m["arms"]), capsule((-sw - 0.9, cy - 0.6, -0.4), L, aw * 0.95, m["arms"])]
    elif pose == "shield":                                      # shield forward on the left, right hand raised
        R, L = (sw + 0.4, sy + 2.2, 2.4), (-1.8 * b, cy - 1.0, 6.4)
        S += [capsule((sw, sy - 0.2, 0), (sw + 1.4, sy - 1.0, -0.6), aw, m["arms"]), capsule((sw + 1.4, sy - 1.0, -0.6), R, aw * 0.95, m["arms"]),
              capsule((-sw, sy - 0.4, 0.2), (-sw + 0.2, cy - 1.0, 3.4), aw, m["arms"]), capsule((-sw + 0.2, cy - 1.0, 3.4), L, aw * 0.95, m["arms"])]
    elif pose == "dual":                                        # a blade in each hand, out to the sides
        R, L = (sw + 2.0, cy - 1.5, 5.4), (-sw - 1.6, cy - 1.0, 5.2)
        S += [capsule((sw, sy - 0.4, 0.2), (sw + 1.6, cy, 2.0), aw, m["arms"]), capsule((sw + 1.6, cy, 2.0), R, aw * 0.95, m["arms"]),
              capsule((-sw, sy - 0.4, 0.2), (-sw - 1.4, cy, 2.0), aw, m["arms"]), capsule((-sw - 1.4, cy, 2.0), L, aw * 0.95, m["arms"])]
    elif pose == "fists":
        R, L = (sw + 1.0, cy - 1.0, 5.6), (-sw - 0.2, cy - 2.6, 3.6)
        S += [capsule((sw, sy - 0.4, 0.2), (sw + 1.6, cy, 1.6), aw * 1.2, m["arms"]), capsule((sw + 1.6, cy, 1.6), R, aw * 1.15, m["arms"]),
              capsule((-sw, sy - 0.4, 0.2), (-sw - 1.4, cy - 0.8, 1.0), aw * 1.2, m["arms"]), capsule((-sw - 1.4, cy - 0.8, 1.0), L, aw * 1.15, m["arms"])]
    elif pose == "device":                                      # holding something up in front
        R, L = (1.8 * b, cy + 0.6, 6.4), (-1.4 * b, cy + 0.2, 6.2)
        S += [capsule((sw, sy - 0.4, 0.2), (sw + 0.6, cy - 1.2, 2.6), aw, m["arms"]), capsule((sw + 0.6, cy - 1.2, 2.6), R, aw * 0.95, m["arms"]),
              capsule((-sw, sy - 0.4, 0.2), (-sw - 0.4, cy - 1.2, 2.6), aw, m["arms"]), capsule((-sw - 0.4, cy - 1.2, 2.6), L, aw * 0.95, m["arms"])]
    else:                                                       # idle: arms down
        R, L = (sw + 0.6, cy - 4.4, 1.0), (-sw - 0.6, cy - 4.4, 1.0)
        S += [capsule((sw, sy - 0.4, 0), (sw + 0.9, cy - 0.6, 0.3), aw, m["arms"]), capsule((sw + 0.9, cy - 0.6, 0.3), R, aw * 0.95, m["arms"]),
              capsule((-sw, sy - 0.4, 0), (-sw - 0.9, cy - 0.6, 0.3), aw, m["arms"]), capsule((-sw - 0.9, cy - 0.6, 0.3), L, aw * 0.95, m["arms"])]
    for k in (R, L):
        S.append(sphere(k, 1.15 * b, m["hands"]))
    hands = {"R": R, "L": L, "chest": (0, cy, 0), "shoulder_R": (sw, sy, 0), "shoulder_L": (-sw, sy, 0),
             "back": (0, cy, -3.0 * b), "head": (0, sy + 5.0 * h, 0.3), "hip_y": hip_y, "sw": sw}
    S.append(capsule((0, sy + 0.4, 0.2), (0, sy + 1.8, 0.3), 1.3 * b, m.get("neck", m["torso"])))
    S, hands = lean(S, hands, hunch, (0, hip_y, 0))
    return low + S, hands


# ------------------------------------------------------------ weapons and things to hold
def rifle(R, L=None, mat="graphite", length=15.0, scope=True, glow=None, thick=1.0):
    x, y, z = R
    S = [box((x - 0.6, y + 0.6, z + length / 2 - 2.0), (0.9 * thick, 1.3 * thick, length / 2), mat, r=0.4),
         box((x - 0.6, y - 1.1, z + 0.4), (0.7, 1.6, 0.8), mat, r=0.3),             # grip
         box((x - 0.6, y - 1.0, z + 3.6), (0.7, 1.5, 0.9), mat, r=0.3)]              # magazine
    S.append(box((x - 0.6, y + 0.3, z - 2.8), (0.8, 1.2, 1.8), mat, r=0.5))          # stock
    if scope:
        S.append(box((x - 0.6, y + 2.3, z + 2.6), (0.6, 0.6, 2.0), "steel", r=0.3))
    if glow:
        S.append(sphere((x - 0.6, y + 0.6, z + length - 2.0), 0.7, glow))
    return S


def sniper(R, L=None, mat="graphite", glow=None):
    x, y, z = R
    S = [box((x - 0.6, y + 0.6, z + 6.0), (0.8, 1.0, 8.5), mat, r=0.4),
         capsule((x - 0.6, y + 0.8, z + 13.0), (x - 0.6, y + 0.8, z + 19.0), 0.5, "steel"),
         box((x - 0.6, y + 2.4, z + 3.2), (0.7, 0.7, 2.8), "steel", r=0.3),
         box((x - 0.6, y - 0.6, z + 0.6), (0.6, 1.3, 0.7), mat, r=0.3),
         box((x - 0.6, y + 0.2, z - 3.0), (0.8, 1.5, 2.0), mat, r=0.5)]
    if glow:
        S.append(sphere((x - 0.6, y + 2.4, z + 6.0), 0.55, glow))
    return S


def pistol(R, mat="graphite", glow=None, size=1.0):
    x, y, z = R
    S = [box((x, y + 0.7, z + 2.0 * size), (0.7, 0.9, 2.6 * size), mat, r=0.3), box((x, y - 0.4, z + 0.2), (0.6, 1.3, 0.7), mat, r=0.3)]
    if glow:
        S.append(sphere((x, y + 0.7, z + 4.6 * size), 0.6, glow))
    return S


def smg(R, mat="graphite", glow=None):
    x, y, z = R
    return [box((x, y + 0.8, z + 3.0), (0.8, 1.2, 4.0), mat, r=0.4), box((x, y - 1.0, z + 2.0), (0.6, 1.8, 0.7), mat, r=0.3),
            capsule((x, y + 1.0, z + 6.8), (x, y + 1.0, z + 8.6), 0.5, "steel")] + ([sphere((x, y + 0.8, z + 8.8), 0.6, glow)] if glow else [])


def blade(H, mat="silver", length=11.0, up=False, glow=None, tilt=0.0):
    x, y, z = H
    if up:
        S = [box((x, y + length / 2 + 1.0, z), (0.5, length / 2, 0.9), mat, r=0.2), box((x, y + 0.8, z), (0.6, 0.4, 1.8), "graphite", r=0.2)]
    else:
        S = [box((x, y + 0.4, z + length / 2 + 0.8), (0.45, 0.9, length / 2), mat, r=0.2), box((x, y, z + 0.8), (0.6, 1.6, 0.4), "graphite", r=0.2)]
    if glow:
        S.append(capsule((x, y + (length if up else 0.4), z + (0 if up else length)), (x, y + (length * 0.4 if up else 0.4), z + (0 if up else length * 0.4)), 0.35, glow))
    if tilt:
        S = [moved(s, R=rot_x(tilt), about=H) for s in S]
    return S


def hammer(H, mat="steel", head="graphite", length=10.0):
    x, y, z = H
    return [capsule((x, y - 2.0, z), (x, y + length, z), 0.6, mat), box((x, y + length, z + 0.4), (1.6, 1.6, 3.2), head, r=0.5)]


def shield(L, mat="steel", w=4.6, h=6.2, trim=None, glow=None):
    x, y, z = L
    S = [box((x + 0.6, y - 0.8, z + 1.2), (w, h, 0.8), mat, r=1.0)]
    if trim:
        S.append(box((x + 0.6, y - 0.8, z + 1.9), (w - 1.4, 0.7, 0.3), trim, r=0.2))
    if glow:
        S.append(box((x + 0.6, y + h - 2.6, z + 2.0), (w - 2.0, 0.4, 0.3), glow, r=0.1))
    return S


def baton(R, mat="graphite", glow="glow_blue"):
    x, y, z = R
    return [capsule((x, y - 1.0, z), (x - 0.4, y + 7.0, z + 1.2), 0.6, mat), capsule((x - 0.4, y + 5.0, z + 1.0), (x - 0.5, y + 7.2, z + 1.3), 0.7, glow)]


def syringe(H, length=9.0, liquid="glow_acid", forward=True):
    x, y, z = H
    if forward:
        return [cylinder((x, y, z + 0.5), (x, y, z + length), 1.1, "glass", round_=0.3),
                cylinder((x, y, z + 1.4), (x, y, z + length - 1.2), 0.75, liquid),
                capsule((x, y, z + length), (x, y, z + length + 3.0), 0.25, "silver"),
                box((x, y, z), (1.6, 0.4, 0.4), "steel", r=0.1)]
    return [cylinder((x, y + 0.5, z), (x, y + length, z), 1.1, "glass", round_=0.3), cylinder((x, y + 1.4, z), (x, y + length - 1.2, z), 0.75, liquid)]


def drill(H, mat="steel", tip="silver"):
    x, y, z = H
    return [cylinder((x, y, z - 0.5), (x, y, z + 3.0), 2.0, mat, round_=0.5), cone((x, y, z + 3.0), (x, y, z + 9.5), 1.8, 0.2, tip),
            torus((x, y, z + 5.0), 1.5, 0.35, "graphite", R=rot_x(math.radians(90)))]


def saw(H, mat="silver"):
    x, y, z = H
    return [cylinder((x + 0.4, y, z + 3.0), (x - 0.4, y, z + 3.0), 4.0, mat, round_=0.2), sphere((x, y, z + 3.0), 1.2, "graphite"),
            capsule((x, y, z), (x, y, z + 3.0), 0.9, "graphite")]


def claw(H, mat="steel", size=1.0):
    x, y, z = H
    S = [box((x, y, z + 1.0), (1.5 * size, 1.5 * size, 1.6 * size), "graphite", r=0.5)]
    for dx in (-1.0, 1.0):
        S.append(moved(cone((x + dx * size, y, z + 2.0 * size), (x + dx * 1.6 * size, y - 0.5, z + 6.0 * size), 0.8 * size, 0.2, mat), R=None))
    return S


def flamer(R, mat="steel", tank="crimson"):
    x, y, z = R
    return [cylinder((x, y + 0.6, z), (x, y + 0.6, z + 8.0), 0.9, mat, round_=0.3), cone((x, y + 0.6, z + 7.5), (x, y + 0.6, z + 10.0), 1.0, 1.6, "graphite"),
            sphere((x, y + 0.6, z + 10.2), 0.8, "glow_orange")]


# ------------------------------------------------------------ four legs
def quadruped(mats=None, length=1.0, height=1.0, headkind="wolf", plates=True, tail=True):
    m = {"body": "gunmetal", "plates": "vantage", "legs": "steel", "feet": "graphite", "head": "steel", "eye": "glow_orange"}
    m.update(mats or {})
    L, Hh = length, height
    S = [ellipsoid((0, 13.0 * Hh, 0), (4.4, 4.4 * Hh, 9.8 * L), m["body"])]
    if plates:
        S.append(box((0, 16.8 * Hh, 0.5), (3.8, 1.6, 7.4 * L), m["plates"], r=1.2))
    S.append(ellipsoid((0, 15.6 * Hh, 8.8 * L), (3.8, 4.0, 3.8), m["body"]))
    hp = (0, 17.4 * Hh, 12.8 * L)
    if headkind == "wolf":
        S.append(box(hp, (2.8, 2.6, 3.8), m["head"], r=1.0))
        S.append(box((0, hp[1] - 2.0, hp[2] + 1.4), (2.3, 1.0, 3.4), m["feet"], r=0.5))
        S.append(box((0, hp[1] - 3.1, hp[2] + 4.1), (1.6, 0.6, 0.8), m["eye"], r=0.2))
        for sx in (-1, 1):
            S.append(cone((sx * 1.7, hp[1] + 2.2, hp[2] - 1.4), (sx * 2.1, hp[1] + 6.0, hp[2] - 2.4), 1.1, 0.2, m["head"]))
            S.append(sphere((sx * 1.8, hp[1] + 0.8, hp[2] + 3.2), 0.65, m["eye"]))
    elif headkind == "block":
        S.append(box(hp, (2.6, 2.4, 2.8), m["head"], r=0.8))
        S.append(box((0, hp[1] + 0.3, hp[2] + 2.6), (2.0, 0.7, 0.5), m["eye"], r=0.2))
    if tail:
        S.append(capsule((0, 15.0 * Hh, -9.4 * L), (0, 19.0 * Hh, -14.6 * L), 1.1, m["legs"], r2=0.5))
    for sx in (-1, 1):
        S.append(capsule((sx * 2.8, 12.0 * Hh, 7.0 * L), (sx * 3.2, 6.5 * Hh, 8.8 * L), 1.7, m["legs"]))
        S.append(capsule((sx * 3.2, 6.5 * Hh, 8.8 * L), (sx * 3.0, 1.2, 8.2 * L), 1.3, m["feet"]))
        S.append(capsule((sx * 3.0, 12.0 * Hh, -6.6 * L), (sx * 3.4, 7.5 * Hh, -9.8 * L), 2.0, m["legs"]))
        S.append(capsule((sx * 3.4, 7.5 * Hh, -9.8 * L), (sx * 3.2, 1.2, -8.0 * L), 1.3, m["feet"]))
    return S, {"back": (0, 18.0 * Hh, 0), "head": hp, "front": (0, 13.0 * Hh, 12.0 * L)}


# ------------------------------------------------------------ many legs
def spider(mats=None, legs=8, size=1.0, abdomen=True, reach=1.0, lift=1.0):
    m = {"body": "brass", "abdomen": "mars", "legs": "graphite", "feet": "steel", "joints": "brass", "head": "graphite", "eye": "glow_acid"}
    m.update(mats or {})
    s = size
    S = [ellipsoid((0, 11.0 * s * lift, 1.0 * s), (6.2 * s, 4.3 * s, 6.6 * s), m["body"])]
    if abdomen:
        S.append(ellipsoid((0, 13.0 * s * lift, -8.6 * s), (5.8 * s, 5.4 * s, 6.8 * s), m["abdomen"]))
    S.append(ellipsoid((0, 10.6 * s * lift, 7.6 * s), (3.8 * s, 3.1 * s, 3.1 * s), m["head"]))
    pairs = legs // 2
    zs = [5.0, 1.6, -1.8, -5.0][:pairs] if pairs <= 4 else [5.0, 2.5, 0.0, -2.5, -5.0][:pairs]
    for sx in (-1, 1):
        for k, z in enumerate(zs):
            mid = (len(zs) - 1) / 2
            spread = (1.25 - abs(k - mid) * 0.15) * reach
            hip = (sx * 5.0 * s, 11.0 * s * lift, z * s)
            knee = (sx * 10.0 * spread * s, (16.5 - abs(k - mid) * 0.6) * s * lift, (z * 1.5 + (2.0 if k < mid else -2.0)) * s)
            foot = (sx * 13.5 * spread * s, 0.8, (z * 1.9 + (3.0 if k < mid else -3.0)) * s)
            S.append(capsule(hip, knee, 1.2 * s, m["legs"]))
            S.append(sphere(knee, 1.35 * s, m["joints"]))
            S.append(capsule(knee, foot, 1.0 * s, m["feet"], r2=0.5 * s))
    return S, {"head": (0, 10.6 * s * lift, 7.6 * s), "back": (0, 15.0 * s * lift, 1.0 * s), "tail": (0, 15.0 * s * lift, -12.0 * s)}


# ------------------------------------------------------------ rotors
def drone(mats=None, rotors=4, span=9.6, y=18.0, body=1.0):
    m = {"shell": "white", "under": "steel", "arms": "steel", "rotor": "vantage", "eye": "glow_mint", "blade": "steel"}
    m.update(mats or {})
    S = [ellipsoid((0, y, 0), (4.8 * body, 2.8 * body, 4.8 * body), m["shell"]),
         ellipsoid((0, y - 2.0, 0), (3.3 * body, 2.1 * body, 3.3 * body), m["under"]),
         sphere((0, y - 2.2, 3.1 * body), 1.6 * body, "gunmetal"),
         sphere((0, y - 2.2, 4.3 * body), 0.95 * body, m["eye"])]
    pts = [(1, 1), (1, -1), (-1, 1), (-1, -1)] if rotors == 4 else [(1, 0), (-1, 0)] if rotors == 2 else \
          [(math.cos(a), math.sin(a)) for a in [k * math.pi / 3 for k in range(6)]]
    for ax, az in pts:
        tip = (ax * span, y + 0.6, az * span)
        S.append(capsule((ax * 2.5, y + 0.2, az * 2.5), tip, 0.95, m["arms"]))
        S.append(cylinder((tip[0], y, tip[2]), (tip[0], y + 2.0, tip[2]), 1.35, m["shell"], round_=0.4))
        S.append(torus((tip[0], y + 2.0, tip[2]), 4.6, 0.55, m["rotor"]))
        S.append(box((tip[0], y + 2.3, tip[2]), (4.2, 0.18, 0.6), m["blade"], R=rot_y(0.5 * ax * (az if az else 1))))
    return S, {"under": (0, y - 3.5, 0), "front": (0, y - 2.0, 4.5)}


# ------------------------------------------------------------ the walking giants
def titan(mats=None, w=1.0, h=1.0):
    m = {"feet": "graphite", "shins": "steel", "knees": "graphite", "thighs": "hazard", "hips": "graphite", "hull": "hazard",
         "window": "glass", "roof": "graphite", "beacon": "glow_amber"}
    m.update(mats or {})
    S = []
    for sx in (-1, 1):
        S.append(box((sx * 6.6 * w, 3.0, 0.8), (3.9 * w, 3.0, 5.6), m["feet"], r=1.2))
        S.append(box((sx * 6.6 * w, 10.0 * h, 0), (3.0 * w, 5.0 * h, 3.0), m["shins"], r=1.0))
        S.append(cylinder((sx * 6.6 * w, 13.2 * h, -0.6), (sx * 6.6 * w, 13.2 * h, 2.0), 2.8 * w, m["knees"], round_=0.5))
        S.append(box((sx * 6.0 * w, 17.4 * h, 0), (3.3 * w, 3.8 * h, 3.3), m["thighs"], r=1.0))
    S.append(box((0, 21.6 * h, 0), (8.6 * w, 2.4, 4.8), m["hips"], r=1.0))
    S.append(box((0, 30.6 * h, 0), (11.4 * w, 8.0 * h, 7.4), m["hull"], r=2.6))
    return S, {"shoulder_R": (12.6 * w, 34.0 * h, 0), "shoulder_L": (-12.6 * w, 34.0 * h, 0), "top": (0, 38.6 * h, 0),
               "front": (0, 31.0 * h, 7.0), "back": (0, 31.0 * h, -7.0)}


# ------------------------------------------------------------ the cleaner bots
def cleaner(mats=None, wheels=True):
    """Sanitation bots: a domed hull on a skirt of wheels, one eye, tool arms."""
    m = {"hull": "sanitation", "skirt": "graphite", "stripe": "vantage", "eye": "glow_magenta", "arms": "steel"}
    m.update(mats or {})
    S = [ellipsoid((0, 16.0, 0), (7.0, 8.0, 6.6), m["hull"]),
         cylinder((0, 9.0, 0), (0, 10.4, 0), 7.2, m["stripe"], round_=0.5),
         cone((0, 9.2, 0), (0, 3.0, 0), 6.6, 7.4, m["skirt"]),
         box((0, 18.4, 5.8), (3.4, 1.4, 1.2), "graphite", r=0.6),
         box((0, 18.4, 6.6), (2.6, 0.7, 0.6), m["eye"], r=0.2)]
    if wheels:
        for sx in (-1, 1):
            for sz in (-1, 1):
                S.append(cylinder((sx * 5.6, 2.0, sz * 4.2), (sx * 7.2, 2.0, sz * 4.2), 2.0, "rubber", round_=0.4))
    S.append(sphere((0, 24.0, 0), 1.2, m["stripe"]))
    S.append(capsule((0, 24.0, 0), (0, 27.4, -1.0), 0.4, "graphite"))
    S.append(sphere((0, 27.6, -1.0), 0.7, m["eye"]))
    return S, {"R": (7.4, 16.0, 2.0), "L": (-7.4, 16.0, 2.0), "front": (0, 13.0, 6.4), "top": (0, 24.0, 0)}


def arm(a, b, c=None, r=1.1, mat="steel", joint=None):
    """A two-part limb a-b-c with a joint ball."""
    S = [capsule(a, b, r, mat)]
    if c:
        S.append(capsule(b, c, r * 0.9, mat))
        S.append(sphere(b, r * 1.15, joint or mat))
    return S


# ------------------------------------------------------------ husks: the dead in walking frames
def husk(mats=None, pose="fists", hunch=0.28):
    m = {"skin": "sick", "frame": "hazard", "rags": "cloth", "bolts": "graphite", "eye": "glow_amber"}
    m.update(mats or {})
    S, H = person(pose=pose, build=1.05, mats={"legs": m["rags"], "boots": "rubber", "hips": m["rags"], "torso": m["skin"],
                                                 "arms": m["skin"], "hands": m["skin"], "belt": "leather", "neck": m["skin"]},
                  pads=False, hunch=hunch)
    # the frame: rails up the legs, a spine and a cage on the chest
    for sx in (-1, 1):
        S.append(capsule((sx * 3.4, 15.0, -1.4), (sx * 3.6, 2.6, -1.2), 0.55, m["frame"]))
        S.append(box((sx * 3.6, 8.8, 0.4), (0.8, 1.2, 1.8), m["bolts"], r=0.3))
    up = [box((0, 21.0, -3.0), (3.6, 4.4, 0.9), m["frame"], r=0.5), box((0, 25.6, -2.4), (5.4, 1.0, 1.6), m["frame"], r=0.4)]
    for y in (18.6, 21.0, 23.4):
        up.append(capsule((-4.6, y, 2.4), (4.6, y, 2.4), 0.45, m["frame"]))
    up, _ = lean(up, {}, hunch, (0, 15.0, 0))
    return S + up, H
