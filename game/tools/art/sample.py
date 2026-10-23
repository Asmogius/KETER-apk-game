"""The style sample: six Units of different kinds, the board's props and a few icons."""
import math
import numpy as np
from kart import *

material("navy", ["14121d", "1b2447", "494182", "4572e3", "8aa1f6"], hi="c9d4fd", gloss=0.3)
material("sand", ["2a1e23", "4f342f", "8c5b3e", "b29476", "e1bf89"])
material("concrete", ["171516", "373334", "595757", "807b7a", "a69e9a", "cbc6c1"])
material("silver", ["322f35", "564f5b", "a69e9a", "cbc6c1", "ecebe7"], hi="ffffff", gloss=0.3)
material("ink", ["050403", "0e0c0c", "171516", "2d1b1e", "373334"])
material("warning", ["271f1b", "724b2c", "d6a851", "f8c53a", "fff089"], pattern=("diag", "ink", 2))
material("sack", ["2a1e23", "724b2c", "b29476", "e1bf89", "f6d896"])


def ryska():
    """Volt-Warden Ryska: a cyborg warden in a long coat, a lit spine, an arc lance."""
    S = []
    for sx in (-1, 1):
        S.append(capsule((sx * 2.4, 15.0, 0), (sx * 2.7, 8.6, 0.8), 1.7, "navy"))
        S.append(capsule((sx * 2.7, 8.6, 0.8), (sx * 2.5, 2.6, 0), 1.5, "navy"))
        S.append(box((sx * 2.6, 1.6, 0.9), (1.9, 1.6, 2.8), "leather", r=0.8))
    coat = cone((0, 17.0, -0.4), (0, 4.5, -1.6), 4.8, 7.2, "navy")
    S.append(cut(coat, (0, 0, 1), 0.6))
    S.append(box((0, 21.0, 0), (4.3, 4.8, 2.7), "navy", r=1.5))                 # coat body
    S.append(box((0, 21.4, 1.8), (2.8, 3.4, 1.2), "vantage", r=0.9))            # vest plate
    S.append(box((0, 16.6, 0.3), (4.3, 0.9, 2.8), "leather", r=0.5))            # belt
    S.append(sphere((0, 16.6, 3.0), 0.8, "brass"))                              # buckle
    S.append(sphere((4.9, 24.8, 0.2), 2.6, "vantage"))                          # pauldron, lance side
    S.append(sphere((-4.8, 24.4, 0), 1.9, "navy"))
    # the spine on contract, and a lit cable over the shoulder to the lance
    for y in (18.5, 21.0, 23.5):
        S.append(sphere((0, y, -3.1), 1.3, "brass"))
    S.append(capsule((0, 25.0, -3.0), (3.0, 27.0, -1.6), 0.6, "glow_amber"))
    S.append(capsule((3.0, 27.0, -1.6), (5.6, 26.6, 1.2), 0.6, "glow_amber"))
    # arms: right hand on the lance in front, left fist at the side
    S.append(capsule((5.0, 23.6, 0.6), (5.8, 19.2, 2.6), 1.3, "navy"))
    S.append(capsule((5.8, 19.2, 2.6), (3.8, 19.0, 6.0), 1.2, "navy"))
    S.append(sphere((3.6, 19.0, 6.2), 1.25, "steel"))
    S.append(capsule((-4.9, 23.6, 0.3), (-5.8, 19.0, -0.2), 1.25, "navy"))
    S.append(capsule((-5.8, 19.0, -0.2), (-5.4, 15.4, 1.2), 1.15, "navy"))
    S.append(sphere((-5.3, 15.0, 1.4), 1.2, "steel"))
    # arc lance: a long rod, a fork of brass, a lit head
    S.append(capsule((3.6, 4.0, 6.2), (3.6, 34.0, 6.6), 0.8, "steel"))
    S.append(cone((3.6, 32.0, 6.6), (3.6, 35.5, 6.6), 1.6, 0.5, "brass"))
    for dz in (-1.3, 1.3):
        S.append(capsule((3.6, 35.0, 6.6 + dz), (3.6, 38.5, 6.6 + dz * 1.4), 0.55, "brass"))
    S.append(sphere((3.6, 37.6, 6.6), 1.2, "glow_violet"))
    S.append(sphere((3.6, 37.7, 7.4), 0.55, "glow_white"))
    # head: bigger than life, silver hair cut short on one side, one lit eye
    S.append(capsule((0, 26.0, 0.2), (0, 27.6, 0.4), 1.3, "flesh"))
    S.append(ellipsoid((0, 30.6, 0.6), (2.9, 3.3, 2.9), "flesh"))
    hair = ellipsoid((-0.3, 31.6, -0.4), (3.3, 3.4, 3.3), "silver")
    S.append(cut(hair, (0.35, -0.55, 1), 0.55))
    S.append(sphere((1.3, 30.6, 3.25), 0.6, "glow_amber"))                       # the eye on contract
    S.append(sphere((-1.2, 30.6, 3.15), 0.45, "dark"))
    return S


def chrome_fiend():
    """Chrome Fiend: a hunched chrome cyborg, an arm cannon and a missile pod."""
    S = []
    for sx in (-1, 1):
        S.append(capsule((sx * 3.4, 14.0, 0), (sx * 3.9, 8.0, 1.6), 2.4, "graphite"))
        S.append(capsule((sx * 3.9, 8.0, 1.6), (sx * 3.6, 2.8, 0.0), 2.1, "steel"))
        S.append(box((sx * 3.6, 1.6, 1.0), (2.4, 1.6, 3.2), "graphite", r=0.9))
    S.append(box((0, 15.2, 0), (5.0, 2.0, 3.0), "graphite", r=1.0))
    torso = box((0, 21.5, 0.4), (6.8, 5.6, 4.2), "steel", r=2.4)
    S.append(moved(torso, R=rot_x(math.radians(14)), about=(0, 18, 0)))
    S.append(box((0, 20.6, 3.8), (3.4, 2.6, 1.1), "graphite", r=0.8))          # gut plating
    for dy in (-1.0, 1.0):
        S.append(capsule((-2.4, 20.6 + dy, 4.9), (2.4, 20.6 + dy, 4.9), 0.45, "flesh"))   # where plates part
    for sx in (-1, 1):
        S.append(sphere((sx * 7.4, 25.0, 0.4), 3.5, "steel"))                  # shoulders
        S.append(torus((sx * 7.4, 25.0, 0.4), 3.0, 0.7, "vantage", R=rot_z(math.radians(90))))
    # right arm: a cannon, pointing at the target
    S.append(capsule((7.6, 24.0, 0.8), (8.4, 19.5, 3.4), 2.0, "graphite"))
    S.append(cylinder((8.2, 19.5, 2.6), (8.2, 19.5, 13.5), 2.4, "steel", round_=0.8))
    S.append(cylinder((8.2, 19.5, 8.0), (8.2, 19.5, 9.4), 2.7, "graphite", round_=0.3))
    S.append(cylinder((8.2, 19.5, 13.0), (8.2, 19.5, 14.2), 1.3, "dark"))
    # left arm: a hand like a vice
    S.append(capsule((-7.6, 24.0, 0.8), (-8.6, 18.0, 2.0), 2.0, "graphite"))
    S.append(capsule((-8.6, 18.0, 2.0), (-7.6, 13.5, 4.2), 1.9, "steel"))
    S.append(box((-7.4, 12.2, 4.8), (1.8, 1.4, 1.6), "graphite", r=0.6))
    # missile pod on the left shoulder
    S.append(box((-6.0, 30.2, -1.2), (3.8, 2.8, 3.2), "vantage", r=0.7))
    for dx in (-1.7, 1.7):
        for dy in (-1.1, 1.2):
            S.append(sphere((-6.0 + dx, 30.2 + dy, 2.0), 0.8, "glow_orange"))
    # head: small, sunk between the shoulders, a lit slit
    S.append(ellipsoid((0.8, 28.2, 2.4), (2.8, 2.7, 2.8), "steel"))
    S.append(box((1.3, 28.4, 4.7), (2.2, 0.6, 0.8), "glow_magenta", r=0.2))
    return S


def arachnabot():
    """Arachnabot: a brass spider of a machine with an injector tail."""
    S = []
    S.append(ellipsoid((0, 11.0, 1.0), (6.2, 4.3, 6.6), "brass"))               # body
    S.append(box((0, 14.6, 1.0), (3.0, 0.8, 4.6), "graphite", r=0.6))          # spine plate
    S.append(ellipsoid((0, 13.0, -8.6), (5.8, 5.4, 6.8), "mars"))               # abdomen
    for dz in (-10.5, -8.0, -5.5):
        S.append(capsule((-5.0, 14.0, dz), (5.0, 14.0, dz), 0.5, "graphite"))   # abdomen bands
    S.append(capsule((0, 17.0, -13.0), (0, 22.0, -9.6), 1.1, "graphite"))       # injector tail
    S.append(cone((0, 21.6, -9.9), (0, 23.4, -6.2), 1.3, 0.25, "steel"))
    S.append(sphere((0, 23.0, -6.8), 0.9, "glow_acid"))
    S.append(ellipsoid((0, 10.6, 7.6), (3.8, 3.1, 3.1), "graphite"))            # head
    for ex, ey in ((-1.4, 11.6), (1.4, 11.6), (0, 12.8)):
        S.append(sphere((ex, ey, 10.3), 0.75, "glow_acid"))
    for sx in (-1, 1):
        S.append(cone((sx * 1.5, 8.8, 9.6), (sx * 0.8, 5.0, 11.4), 1.0, 0.2, "steel"))   # fangs
    for sx in (-1, 1):
        for k, z in enumerate((5.0, 1.6, -1.8, -5.0)):
            spread = (1.25 - abs(k - 1.5) * 0.15)
            hip = (sx * 5.0, 11.0, z)
            knee = (sx * (10.0 * spread), 16.5 - abs(k - 1.5) * 0.6, z * 1.5 + (2.0 if k < 2 else -2.0))
            foot = (sx * (13.5 * spread), 0.8, z * 1.9 + (3.0 if k < 2 else -3.0))
            S.append(capsule(hip, knee, 1.2, "graphite"))
            S.append(sphere(knee, 1.35, "brass"))
            S.append(capsule(knee, foot, 1.0, "steel", r2=0.5))
    return S


def construction_titan():
    """Construction Titan: a walking crane of a machine in warning paint."""
    S = []
    for sx in (-1, 1):
        S.append(box((sx * 6.6, 3.0, 0.8), (3.9, 3.0, 5.6), "graphite", r=1.2))       # feet
        S.append(box((sx * 6.6, 10.0, 0), (3.0, 5.0, 3.0), "steel", r=1.0))           # shins
        S.append(cylinder((sx * 6.6, 13.2, -0.6), (sx * 6.6, 13.2, 2.0), 2.8, "graphite", round_=0.5))
        S.append(box((sx * 6.0, 17.4, 0), (3.3, 3.8, 3.3), "hazard", r=1.0))           # thighs
    S.append(box((0, 21.6, 0), (8.6, 2.4, 4.8), "graphite", r=1.0))                    # hips
    S.append(box((0, 30.6, 0), (11.4, 8.0, 7.4), "hazard", r=2.6))                     # hull
    S.append(box((0, 24.6, 6.4), (10.2, 1.6, 1.4), "warning", r=0.4))                 # warning band
    S.append(box((-1.0, 33.0, 6.6), (4.6, 3.0, 1.4), "glass", r=0.9))                  # cab window
    S.append(box((0, 39.6, -1.0), (6.6, 1.6, 4.8), "graphite", r=0.8))                 # roof
    S.append(sphere((-4.6, 41.8, 1.0), 1.1, "glow_amber"))                              # beacons
    S.append(sphere((4.6, 41.8, 1.0), 1.1, "glow_amber"))
    S.append(capsule((5.4, 39.0, -3.6), (8.0, 45.0, -5.0), 0.6, "graphite"))           # antenna
    # right arm: a crusher claw
    S.append(sphere((12.6, 34.0, 0), 3.9, "graphite"))
    S.append(capsule((12.6, 34.0, 0), (15.6, 24.0, 4.2), 3.0, "hazard"))
    S.append(box((15.8, 20.0, 5.0), (3.4, 3.6, 3.6), "steel", r=1.0))
    for dz, tilt in ((-2.0, -0.35), (2.0, 0.35)):
        jaw = box((15.8, 13.6, 5.0 + dz), (1.3, 4.0, 1.0), "graphite", r=0.5)
        S.append(moved(jaw, R=rot_x(tilt), about=(15.8, 17.0, 5.0 + dz)))
    # left arm: a pile driver
    S.append(sphere((-12.6, 34.0, 0), 3.9, "graphite"))
    S.append(capsule((-12.6, 34.0, 0), (-15.0, 25.0, 3.0), 3.0, "hazard"))
    S.append(cylinder((-15.0, 27.0, 3.0), (-15.0, 11.0, 3.0), 2.5, "steel", round_=0.6))
    S.append(cylinder((-15.0, 22.0, 3.0), (-15.0, 19.0, 3.0), 2.9, "warning", round_=0.4))
    S.append(cylinder((-15.0, 12.0, 3.0), (-15.0, 7.5, 3.0), 1.3, "graphite"))
    return S


def stripes(img, colour="hazard", band=(2, 3), step=4, ink="171516"):
    """Black warning stripes painted over every pixel of a material's two lightest shades."""
    ramp = MAT[colour]["ramp"]
    paint = set(ramp[band[0]:band[1] + 1])
    H, W = img.shape
    out = img.copy()
    for y in range(H):
        for x in range(W):
            if img[y, x] in paint and ((x + y) // 2) % step == 0:
                out[y, x] = idx(ink)
    return out


def cerberus_blitz():
    """CERBERUS Blitz Bot: a quadruped like a dire wolf, plated for close work."""
    S = []
    S.append(ellipsoid((0, 13.0, 0), (4.4, 4.4, 9.8), "gunmetal"))                # body
    S.append(box((0, 16.8, 0.5), (3.8, 1.6, 7.4), "vantage", r=1.2))               # back plates
    S.append(ellipsoid((0, 15.6, 8.8), (3.8, 4.0, 3.8), "gunmetal"))               # chest/neck
    S.append(box((0, 17.4, 12.8), (2.8, 2.6, 3.8), "steel", r=1.0))                # head
    S.append(box((0, 15.4, 14.2), (2.3, 1.0, 3.4), "graphite", r=0.5))             # jaw
    S.append(box((0, 14.3, 16.9), (1.6, 0.6, 0.8), "glow_orange", r=0.2))          # mouth glow
    for sx in (-1, 1):
        S.append(cone((sx * 1.7, 19.6, 11.4), (sx * 2.1, 23.4, 10.4), 1.1, 0.2, "steel"))   # ears
        S.append(sphere((sx * 1.8, 18.2, 16.0), 0.65, "glow_orange"))
    S.append(capsule((0, 15.0, -9.4), (0, 19.0, -14.6), 1.1, "steel", r2=0.5))    # tail
    for sx in (-1, 1):
        S.append(capsule((sx * 2.8, 12.0, 7.0), (sx * 3.2, 6.5, 8.8), 1.7, "steel"))
        S.append(capsule((sx * 3.2, 6.5, 8.8), (sx * 3.0, 1.2, 8.2), 1.3, "graphite"))
        S.append(capsule((sx * 3.0, 12.0, -6.6), (sx * 3.4, 7.5, -9.8), 2.0, "steel"))
        S.append(capsule((sx * 3.4, 7.5, -9.8), (sx * 3.2, 1.2, -8.0), 1.3, "graphite"))
    return S


def quadcopter():
    """The Quadcopter body plan: four rotors and one eye."""
    S = []
    S.append(ellipsoid((0, 18.0, 0), (4.8, 2.8, 4.8), "white"))
    S.append(box((0, 18.4, 0), (5.2, 0.6, 1.2), "vantage", r=0.3))
    S.append(ellipsoid((0, 16.0, 0), (3.3, 2.1, 3.3), "steel"))
    S.append(sphere((0, 15.8, 3.1), 1.6, "gunmetal"))
    S.append(sphere((0, 15.8, 4.3), 0.95, "glow_mint"))
    for ax, az in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        tip = (ax * 9.6, 18.6, az * 9.6)
        S.append(capsule((ax * 2.5, 18.2, az * 2.5), tip, 0.95, "steel"))
        S.append(cylinder((tip[0], 18.0, tip[2]), (tip[0], 20.0, tip[2]), 1.35, "white", round_=0.4))
        S.append(torus((tip[0], 20.0, tip[2]), 4.6, 0.55, "vantage"))
        S.append(box((tip[0], 20.3, tip[2]), (4.2, 0.18, 0.6), "steel", R=rot_y(0.5 * ax * az)))
    for sx in (-1, 1):
        S.append(capsule((sx * 2.2, 15.5, 0), (sx * 2.8, 11.5, 0), 0.55, "graphite"))
        S.append(capsule((sx * 2.8, 11.5, -1.5), (sx * 2.8, 11.5, 1.5), 0.5, "graphite"))
    return S


# ---------------------------------------------------------------- props (seen from higher up)
def sandbags():
    S = []
    for k in range(5):
        a = (k - 2) * 0.32
        x, z = math.sin(a) * 15, math.cos(a) * 15 - 15
        S.append(moved(ellipsoid((0, 2.6, 0), (3.9, 2.6, 2.7), "sack"), by=(x, 0, z), R=rot_y(a)))
    for k in range(4):
        a = (k - 1.5) * 0.32
        x, z = math.sin(a) * 15, math.cos(a) * 15 - 15
        S.append(moved(ellipsoid((0, 7.0, 0), (3.9, 2.5, 2.6), "sack"), by=(x, 0, z - 0.4), R=rot_y(a)))
    for k in range(3):
        a = (k - 1.0) * 0.32
        x, z = math.sin(a) * 15, math.cos(a) * 15 - 15
        S.append(moved(ellipsoid((0, 11.2, 0), (3.8, 2.4, 2.5), "sack"), by=(x, 0, z - 0.8), R=rot_y(a)))
    return S


def barrier():
    """Full Cover: a tall barrier wall, plated and striped."""
    body = box((0, 11.0, 0), (14.0, 11.0, 5.0), "concrete", r=1.0)
    body = cut(body, (0, 0.45, 1), 9.4)
    body = cut(body, (0, 0.45, -1), 9.4)
    S = [body,
         box((0, 1.4, 0), (14.6, 1.4, 5.6), "graphite", r=0.6),
         box((0, 21.0, 0), (14.2, 1.0, 1.6), "warning", r=0.3)]
    for x in (-9, 0, 9):
        S.append(box((x, 11.0, 3.2), (0.6, 7.5, 0.6), "graphite", r=0.2))
    S.append(box((-4.5, 6.0, 4.4), (2.0, 1.2, 0.6), "vantage", r=0.2))
    return S


def crate():
    S = [box((0, 5.2, 0), (6.4, 5.0, 5.0), "olive", r=0.7)]
    for x in (-6.2, 6.2):
        for z in (-4.8, 4.8):
            S.append(box((x, 5.2, z), (0.9, 5.3, 0.9), "brass", r=0.3))
    S.append(box((0, 10.3, 0), (6.8, 0.5, 5.4), "brass", r=0.2))
    S.append(box((0, 5.2, 5.1), (3.6, 1.6, 0.3), "vantage", r=0.2))
    S.append(box((0, 10.6, 0), (3.6, 0.3, 2.0), "vantage", r=0.1))
    return S


def make_titan():
    return make(construction_titan(), size=48, foot=(24, 46), yaw=30)


UNITS = [("Volt-Warden Ryska", ryska, 45, 18), ("Chrome Fiend", chrome_fiend, 40, 18), ("Arachnabot", arachnabot, 50, 20),
         ("Construction Titan", None, 30, 18), ("CERBERUS Blitz Bot", cerberus_blitz, 62, 18), ("Quadcopter", quadcopter, 35, 26)]


def units():
    out = []
    for name, fn, yaw, pitch in UNITS:
        img = make_titan() if fn is None else make(fn(), size=48, foot=(24, 46), yaw=yaw, pitch=pitch, scale=1.08)
        out.append((name, img))
    return out


def props():
    return [("Half Cover", make(sandbags(), size=48, foot=(24, 38), yaw=0, pitch=45, inner_step=0.8, scale=1.35)),
            ("Full Cover", make(barrier(), size=48, foot=(24, 40), yaw=0, pitch=38, inner_step=0.8)),
            ("Loot crate", make(crate(), size=32, foot=(16, 26), yaw=25, pitch=40, inner_step=0.6))]


if __name__ == "__main__":
    us = units()
    sheet([u[1] for u in us], preview_path("sample_units.png"), scale=4, labels=[u[0] for u in us], cols=3)
    ps = props()
    sheet([p[1] for p in ps], preview_path("sample_props.png"), scale=4, labels=[p[0] for p in ps], cols=3)
