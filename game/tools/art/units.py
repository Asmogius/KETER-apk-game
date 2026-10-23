"""Every master Unit's token: a recipe each, built on rigs.py."""
import math
from kart import *
from rigs import *
import sample

U = {}            # name -> {"fn", "yaw", "pitch", "scale", "big", "kind"}


def unit(name, yaw=45, pitch=18, scale=1.08, big=False, kind="enemy", centre="feet", foot_y=46):
    def deco(fn):
        U[name] = {"fn": fn, "yaw": yaw, "pitch": pitch, "scale": scale, "big": big, "kind": kind, "centre": centre, "foot_y": foot_y}
        return fn
    return deco


WARN = []


def render_unit(name):
    """A token, 48 x 48. Long bodies are centred by their outline, people by their feet.
    One that would run off the edge is pulled back in."""
    u = U[name]
    shapes = u["fn"]()
    fx = 24
    img = make(shapes, size=48, foot=(fx, u["foot_y"]), yaw=u["yaw"], pitch=u["pitch"], scale=u["scale"])
    bb = shapes_bbox(img)
    if bb:
        x0, y0, x1, y1 = bb
        shift = 0
        if u["centre"] == "box":
            shift = round(24 - (x0 + x1 + 1) / 2)
        else:
            if x0 + shift < 0:
                shift = -x0
            if x1 + shift > 47:
                shift = 47 - x1
        if shift:
            img = make(shapes, size=48, foot=(fx + shift, u["foot_y"]), yaw=u["yaw"], pitch=u["pitch"], scale=u["scale"])
        bb = shapes_bbox(img)
        if bb and (bb[0] <= 0 or bb[2] >= 47 or bb[1] <= 0):
            WARN.append((name, "touches the edge", bb))
    return img


# ================================================================ HEROES
@unit("\"Mincer\" Cleaner Bot", yaw=40, scale=1.12, kind="hero")
def mincer():
    S, P = cleaner({"hull": "sanitation", "stripe": "vantage", "eye": "glow_amber"})
    # the mincer: a toothed drum on two arms out front
    S += arm((5.6, 16.0, 3.0), (6.4, 12.0, 7.0), r=1.2, mat="steel")
    S += arm((-5.6, 16.0, 3.0), (-6.4, 12.0, 7.0), r=1.2, mat="steel")
    S.append(cylinder((-7.0, 11.0, 9.6), (7.0, 11.0, 9.6), 3.6, "steel", round_=0.6))
    S.append(cylinder((-7.6, 11.0, 9.6), (-6.6, 11.0, 9.6), 2.4, "vantage", round_=0.3))
    S.append(cylinder((6.6, 11.0, 9.6), (7.6, 11.0, 9.6), 2.4, "vantage", round_=0.3))
    for k in range(-5, 6, 2):
        for a in (0.3, 1.5, 2.7, 3.9, 5.1):
            S.append(cone((k, 11.0 + 3.4 * math.sin(a), 9.6 + 3.4 * math.cos(a)), (k, 11.0 + 5.4 * math.sin(a), 9.6 + 5.4 * math.cos(a)), 0.8, 0.1, "silver"))
    S.append(box((0, 22.0, -4.6), (3.6, 3.0, 1.4), "vantage", r=0.8))   # a contract plate on its back
    return S


@unit("Rictus", yaw=40, scale=1.15, kind="hero")
def rictus():
    S, H = person(pose="fists", build=1.25, mats={"legs": "graphite", "boots": "rubber", "hips": "charcoal", "torso": "pale",
                                                   "chest": "steel", "pads": "steel", "arms": "steel", "hands": "graphite", "neck": "pale"}, hunch=0.18)
    S += head("skull", H["head"], {"skin": "pale", "jaw": "silver", "eye": "glow_orange"}, size=1.1)
    # grinders for hands, spinning up
    for side, dx in (("R", 1.0), ("L", -1.0)):
        x, y, z = H[side]
        S.append(capsule((x, y, z), (x + dx * 0.8, y, z + 2.4), 1.0, "graphite"))
        S.append(cylinder((x + dx * 0.8, y, z + 2.2), (x + dx * 0.8, y, z + 3.2), 4.2, "silver", round_=0.2))
        S.append(cylinder((x + dx * 0.8, y, z + 3.1), (x + dx * 0.8, y, z + 3.5), 1.4, "graphite", round_=0.1))
        for a in range(8):
            t = a * math.pi / 4
            S.append(cone((x + dx * 0.8 + 3.8 * math.cos(t), y + 3.8 * math.sin(t), z + 2.7), (x + dx * 0.8 + 5.2 * math.cos(t + 0.3), y + 5.2 * math.sin(t + 0.3), z + 2.7), 0.6, 0.1, "silver"))
    for k, y in enumerate((19.0, 21.4, 23.8)):
        S.append(capsule((-3.6, y, 2.9), (3.6, y + 0.4, 2.9), 0.35, "crimson"))   # stitched scars
    return S


@unit("Volt-Warden Ryska", yaw=45, kind="hero")
def ryska():
    return sample.ryska()


@unit("Sable-Nine, Ledger Adept", yaw=40, kind="hero")
def sable_nine():
    S, H = person(pose="device", build=0.95, mats={"legs": "charcoal", "boots": "rubber", "hips": "charcoal", "torso": "charcoal",
                                                    "chest": "gold", "arms": "charcoal", "hands": "silver", "coat": "charcoal"}, coat=True)
    S += head("face", H["head"], {"skin": "silver", "hair": "plum", "eye": "glow_violet", "eye2": "glow_violet"}, size=1.08)
    # a monocle and a ledger of light floating between the hands
    S.append(torus((H["head"][0] + 1.3, H["head"][1] - 0.1, H["head"][2] + 3.0), 0.9, 0.3, "gold", R=rot_x(math.radians(90))))
    S.append(box((0.2, H["R"][1] + 3.2, H["R"][2] + 1.6), (3.6, 2.6, 0.3), "glow_violet", r=0.2))
    S.append(box((0.2, H["R"][1] + 3.2, H["R"][2] + 1.9), (2.8, 1.9, 0.25), "lilac", r=0.1))
    for k in range(3):
        S.append(box((0.2, H["R"][1] + 4.3 - k * 1.0, H["R"][2] + 2.2), (2.0, 0.18, 0.15), "glow_white"))
    S.append(box((0, 27.4, -1.0), (5.2, 1.0, 2.6), "gold", r=0.4))               # a gold collar
    return S


@unit("Dross, the Forge-Blind", yaw=32, scale=1.12, big=True, kind="hero")
def dross():
    S, H = person(pose="fists", build=1.6, height=1.05, mats={"legs": "charcoal", "boots": "graphite", "hips": "slag",
                                                              "torso": "charcoal", "chest": None, "pads": "slag", "arms": "slag",
                                                              "hands": "graphite", "belt": "slag", "knees": "slag"})
    cx, cy, cz = H["chest"]
    S.append(box((0, cy + 0.5, 4.6), (3.6, 3.4, 0.9), "slag", r=0.8))            # the furnace door
    S.append(box((0, cy + 0.2, 5.4), (2.6, 2.0, 0.4), "glow_orange", r=0.3))      # its fire
    S.append(box((0, cy + 0.2, 5.7), (1.5, 0.9, 0.3), "glow_yellow", r=0.2))
    hx, hy, hz = H["head"]
    S.append(box((hx, hy, hz), (2.9, 3.0, 2.9), "slag", r=1.2))                    # a blank face: no eyes
    S.append(box((hx, hy - 0.2, hz + 2.6), (2.2, 2.0, 0.5), "charcoal", r=0.5))
    for k in (-1, 0, 1):
        S.append(capsule((hx + k * 1.2, hy + 3.0, hz - 1.0), (hx + k * 1.6, hy + 5.4, hz - 2.0), 0.6, "graphite"))   # chimneys
        S.append(sphere((hx + k * 1.6, hy + 5.6, hz - 2.0), 0.5, "glow_orange"))
    for side in ("R", "L"):                                                          # bellows for fists
        x, y, z = H[side]
        S.append(box((x, y - 0.4, z + 1.0), (2.2, 2.4, 2.4), "leather", r=1.0))
        S.append(box((x, y - 0.4, z + 3.2), (2.4, 2.6, 0.6), "slag", r=0.4))
        S.append(sphere((x, y - 0.4, z + 3.8), 0.7, "glow_orange"))
    return S


@unit("Quillon Vex", yaw=50, kind="hero")
def quillon():
    S, H = person(pose="rifle", build=0.92, mats={"legs": "khaki", "boots": "leather", "hips": "khaki", "torso": "khaki",
                                                  "chest": "leather", "arms": "khaki", "hands": "leather", "coat": "khaki"}, coat=True)
    S += head("hood", H["head"], {"skin": "flesh", "hood": "khaki", "eye": "glow_amber"}, size=1.05)
    S.append(capsule((-3.0, 27.2, 2.0), (3.4, 27.4, 2.4), 1.1, "crimson"))          # scarf
    S.append(capsule((-3.4, 27.0, -1.6), (-4.8, 21.0, -3.4), 0.9, "crimson"))
    S += sniper(H["R"], mat="gold", glow="glow_amber")
    S.append(cone((H["R"][0] - 0.6, H["R"][1] + 0.8, H["R"][2] + 19.0), (H["R"][0] - 0.6, H["R"][1] + 0.8, H["R"][2] + 22.5), 0.5, 0.05, "silver"))   # the quillon blade
    return S


# ================================================================ CLEANER BOTS
@unit("\"Binder\" Cleaner Bot", yaw=40)
def binder():
    S, P = cleaner({"stripe": "crimson", "eye": "glow_magenta"})
    # a foam gun that binds
    S += arm(P["R"], (9.0, 13.0, 5.0), r=1.2)
    S.append(cylinder((8.6, 13.0, 3.0), (8.6, 13.0, 12.0), 2.6, "teal", round_=0.6))
    S.append(cylinder((8.6, 13.0, 11.6), (8.6, 13.0, 13.2), 1.8, "graphite", round_=0.3))
    S.append(sphere((8.6, 13.0, 14.0), 1.6, "white"))
    S.append(sphere((8.6, 13.0, 15.6), 1.1, "white"))
    S += arm(P["L"], (-9.0, 13.0, 3.0), r=1.1)
    S.append(cylinder((-6.0, 20.0, -5.0), (-6.0, 26.0, -5.0), 2.2, "teal", round_=0.6))    # foam tank
    return S


@unit("\"Hunter\" Cleaner Bot", yaw=40)
def hunter():
    S, P = cleaner({"stripe": "ochre", "eye": "glow_orange"})
    S.append(box((0, 22.0, 1.0), (4.0, 1.4, 3.0), "graphite", r=0.6))              # sensor brow
    for k in (-2.0, 0.0, 2.0):
        S.append(sphere((k, 22.2, 4.0), 0.7, "glow_orange"))
    S += arm(P["R"], (9.6, 15.0, 6.0), r=1.2)
    S.append(box((9.4, 15.0, 7.0), (1.4, 1.6, 4.0), "graphite", r=0.4))             # a harpoon gun
    S.append(cylinder((9.4, 15.6, 9.0), (9.4, 15.6, 17.0), 0.6, "steel", round_=0.2))
    S.append(cone((9.4, 15.6, 17.0), (9.4, 15.6, 19.6), 1.5, 0.1, "silver"))
    S.append(capsule((0, 24.0, -1.0), (0, 30.0, -2.0), 0.5, "graphite"))             # a sensor mast
    S.append(sphere((0, 30.4, -2.0), 1.2, "glow_orange"))
    return S


@unit("\"Purifier\" Cleaner Bot", yaw=40)
def purifier():
    S, P = cleaner({"stripe": "crimson", "eye": "glow_orange"})
    S += arm(P["R"], (9.0, 13.0, 5.0), r=1.2)
    S += flamer((8.6, 12.4, 5.0))
    S.append(cone((8.6, 13.0, 15.4), (8.6, 13.6, 19.0), 1.6, 0.6, "glow_orange"))   # a lick of flame
    S.append(cone((8.6, 13.0, 15.2), (8.6, 13.4, 17.4), 0.9, 0.3, "glow_yellow"))
    for dz in (-1.6, 1.6):
        S.append(cylinder((dz * 2.4, 18.0, -6.0), (dz * 2.4, 26.0, -6.0), 2.0, "crimson", round_=0.6))    # fuel tanks
    S.append(sphere((0, 9.6, 7.2), 0.7, "glow_orange"))
    return S


@unit("\"Stitcher\" Cleaner Bot", yaw=40)
def stitcher():
    S, P = cleaner({"stripe": "rose", "eye": "glow_mint"})
    for side, (x, z), yy in (("R", (9.0, 6.0), 0), ("L", (-8.6, 6.4), 0), ("R", (8.0, 3.0), -4), ("L", (-7.6, 3.4), -4)):
        p = P[side]
        S += arm((p[0], p[1] + yy, p[2]), (x + (1.0 if x > 0 else -1.0), 21.0 + yy, 2.0), (x - (1.0 if x > 0 else -1.0), 24.0 + yy, z), r=0.75, mat="steel", joint="rose")
        S.append(capsule((x - (1.0 if x > 0 else -1.0), 24.0 + yy, z), (x - (1.8 if x > 0 else -1.8), 19.0 + yy, z + 3.4), 0.4, "silver"))   # needles
    S.append(cylinder((0, 19.0, -6.0), (0, 23.0, -6.0), 2.6, "white", round_=0.8))     # thread spool
    S.append(torus((0, 21.0, -6.0), 2.6, 0.5, "rose"))
    return S


# ================================================================ HUSKS
@unit("Exo Husk", yaw=42)
def exo_husk():
    S, H = husk({"frame": "hazard", "skin": "sick", "rags": "cloth"}, pose="fists")
    S += head("mask", H["head"], {"helmet": "rubber", "eye": "glow_amber"}, size=1.0)
    S += drill((H["R"][0] + 0.4, H["R"][1], H["R"][2] + 0.4))
    S += claw((H["L"][0] - 0.4, H["L"][1], H["L"][2] + 0.4), size=1.0)
    return S


@unit("Exo Worker Husk", yaw=42)
def exo_worker():
    S, H = husk({"frame": "ochre", "skin": "sick", "rags": "khaki"}, pose="melee")
    S += head("cap", H["head"], {"skin": "sick", "hat": "hazard", "eye": "glow_amber"}, size=1.0)
    S += hammer(H["R"], mat="steel", head="graphite", length=8.0)
    return S


@unit("Laz Welder Husk", yaw=48)
def laz_welder():
    S, H = husk({"frame": "steel", "skin": "sick", "rags": "leather"}, pose="pistol")
    hx, hy, hz = H["head"]
    S.append(box((hx, hy, hz + 0.3), (2.9, 3.2, 2.9), "graphite", r=1.0))         # welding mask
    S.append(box((hx, hy + 0.4, hz + 2.9), (2.2, 0.9, 0.4), "glow_acid", r=0.2))
    x, y, z = H["R"]
    S.append(cylinder((x, y + 0.6, z - 1.0), (x, y + 0.6, z + 6.0), 1.4, "steel", round_=0.4))
    S.append(cone((x, y + 0.6, z + 6.0), (x, y + 0.6, z + 8.0), 1.0, 0.4, "graphite"))
    S.append(sphere((x, y + 0.6, z + 8.4), 0.8, "glow_white"))
    S.append(cylinder((0, 19.0, -5.6), (0, 26.0, -5.6), 2.2, "ochre", round_=0.6))   # gas bottle
    return S


# ================================================================ ENEMIES (the rest)
@unit("Arachnabot", yaw=50, pitch=20, centre="box")
def arachnabot():
    return sample.arachnabot()


@unit("Chrome Fiend", yaw=40)
def chrome_fiend():
    return sample.chrome_fiend()


@unit("Construction Titan", yaw=30, scale=1.0, big=True)
def construction_titan():
    return sample.construction_titan()


@unit("Chrome Junkie", yaw=46)
def chrome_junkie():
    S, H = person(pose="pistol", build=0.85, mats={"legs": "plum", "boots": "rubber", "hips": "plum", "torso": "sick",
                                                   "chest": None, "arms": "silver", "hands": "silver", "neck": "sick"}, hunch=0.15)
    S += head("face", H["head"], {"skin": "sick", "hair": "rose", "eye": "glow_magenta", "eye2": "glow_magenta"}, size=1.05)
    for y in (19.5, 22.0):                                                          # ports where the dose goes in
        S.append(sphere((2.6, y, 2.6), 0.6, "glow_magenta"))
    S.append(sphere((-2.0, 20.8, 2.7), 0.6, "glow_magenta"))
    S += smg(H["R"], mat="silver", glow="glow_magenta")
    S.append(capsule((-4.8, 25.0, -1.0), (-2.0, 22.0, -3.6), 0.4, "glow_pink"))     # a feed tube
    return S


@unit("Centibot", yaw=58, pitch=22, scale=1.05, centre="box")
def centibot():
    S = []
    n = 8
    pts = []
    for k in range(n):
        t = k / (n - 1)
        x = math.sin(t * math.pi * 1.2) * 5.0
        z = 6.0 - t * 21.0
        rise = max(0.0, 3 - k)                                      # the front three segments rear up
        y = 4.6 + rise * 6.4
        z += rise * 2.6
        pts.append((x, y, z))
    for k, (x, y, z) in enumerate(pts):
        mat = "ochre" if k % 2 == 0 else "graphite"
        S.append(ellipsoid((x, y, z), (4.6 - k * 0.2, 3.4 - k * 0.1, 3.0), mat))
        for sx in (-1, 1):
            if y < 6.0:
                S.append(capsule((x + sx * 2.6, y, z), (x + sx * 5.6, y + 2.0, z + 0.4), 0.5, "steel"))
                S.append(capsule((x + sx * 5.6, y + 2.0, z + 0.4), (x + sx * 6.8, 0.5, z + 0.8), 0.45, "steel", r2=0.3))
            else:
                S.append(capsule((x + sx * 2.6, y, z), (x + sx * 4.6, y - 1.6, z + 2.0), 0.45, "steel", r2=0.3))
    hx, hy, hz = pts[0]
    S.append(ellipsoid((hx, hy + 1.0, hz + 2.6), (4.2, 3.2, 3.0), "graphite"))
    for sx in (-1, 1):
        S.append(sphere((hx + sx * 1.3, hy + 1.8, hz + 4.4), 0.65, "glow_acid"))
        S.append(cone((hx + sx * 1.6, hy - 0.2, hz + 4.0), (hx + sx * 0.6, hy - 1.4, hz + 6.6), 0.8, 0.15, "silver"))
    S.append(capsule((hx, hy + 3.0, hz + 1.0), (hx - 1.0, hy + 7.0, hz - 1.0), 0.4, "graphite"))   # the disabler's antenna
    S.append(sphere((hx - 1.0, hy + 7.2, hz - 1.0), 0.9, "glow_violet"))
    return S


@unit("Vaccinator", yaw=40)
def vaccinator():
    S, H = person(pose="melee", build=1.0, mats={"legs": "steel", "boots": "graphite", "hips": "medic", "torso": "medic",
                                                  "chest": "medic", "pads": "medic", "arms": "steel", "hands": "graphite"})
    S += head("dome", H["head"], {"helmet": "medic", "eye": "glow_acid"}, size=1.0)
    S.append(box((0, 22.0, 3.0), (1.8, 0.5, 0.3), "crimson", r=0.1))               # a red cross
    S.append(box((0, 22.0, 3.0), (0.5, 1.8, 0.3), "crimson", r=0.1))
    S += syringe(H["R"], length=9.0, liquid="glow_acid", forward=False)
    S += syringe(H["L"], length=8.0, liquid="glow_acid", forward=True)
    return S


@unit("Long Range Vaccinator", yaw=50)
def long_vaccinator():
    S, H = person(pose="rifle", build=0.95, height=1.08, mats={"legs": "steel", "boots": "graphite", "hips": "medic", "torso": "medic",
                                                               "chest": "medic", "arms": "steel", "hands": "graphite"})
    S += head("dome", H["head"], {"helmet": "medic", "eye": "glow_acid"}, size=0.95)
    S.append(box((0, 22.4, 3.0), (1.6, 0.45, 0.3), "crimson", r=0.1))
    S.append(box((0, 22.4, 3.0), (0.45, 1.6, 0.3), "crimson", r=0.1))
    S += sniper(H["R"], mat="medic")
    x, y, z = H["R"]
    S.append(cylinder((x - 0.6, y + 3.0, z + 1.0), (x - 0.6, y + 3.0, z + 7.0), 1.0, "glass", round_=0.3))   # a dart magazine
    S.append(cylinder((x - 0.6, y + 3.0, z + 1.6), (x - 0.6, y + 3.0, z + 6.4), 0.65, "glow_acid"))
    return S


@unit("Decimation Titan", yaw=28, scale=1.0, big=True)
def decimation_titan():
    S, P = titan({"thighs": "crimson", "hull": "crimson", "window": "glass", "shins": "steel"})
    S.append(box((0, 33.0, 6.6), (6.0, 1.6, 1.2), "glow_orange", r=0.4))            # a visor slit
    for side, sx in (("shoulder_R", 1), ("shoulder_L", -1)):
        x, y, z = P[side]
        S.append(sphere((x, y, z), 3.9, "graphite"))
        S.append(capsule((x, y, z), (x + sx * 2.6, y - 8.0, z + 3.6), 3.0, "crimson"))
        gx, gy, gz = x + sx * 2.8, y - 10.0, z + 4.0
        S.append(cylinder((gx, gy, gz - 2.0), (gx, gy, gz + 6.0), 3.4, "graphite", round_=0.6))      # gatling
        for a in range(6):
            t = a * math.pi / 3
            S.append(capsule((gx + 1.8 * math.cos(t), gy + 1.8 * math.sin(t), gz + 5.0), (gx + 1.8 * math.cos(t), gy + 1.8 * math.sin(t), gz + 13.0), 0.65, "steel"))
    S.append(box((0, 41.0, -2.0), (7.4, 3.0, 4.0), "graphite", r=1.0))              # missile racks
    for k in range(-3, 4, 2):
        S.append(sphere((k * 1.6, 41.6, 2.2), 0.8, "glow_orange"))
    return S


@unit("Earthshaker Titan", yaw=30, scale=1.0, big=True)
def earthshaker_titan():
    S, P = titan({"thighs": "mars", "hull": "mars", "shins": "slag", "feet": "charcoal"}, w=1.05)
    S.append(box((0, 32.0, 6.8), (5.0, 2.4, 1.0), "glass", r=0.8))
    for side, sx in (("shoulder_R", 1), ("shoulder_L", -1)):
        x, y, z = P[side]
        S.append(sphere((x, y, z), 4.2, "slag"))
        S.append(capsule((x, y, z), (x + sx * 2.4, y - 9.0, z + 3.0), 3.2, "mars"))
        S.append(box((x + sx * 2.6, y - 14.0, z + 3.4), (5.0, 5.0, 5.0), "charcoal", r=1.6))   # hammer fists
        S.append(box((x + sx * 2.6, y - 14.0, z + 8.4), (3.6, 3.6, 0.6), "slag", r=0.6))
    for k in (-6, 0, 6):                                                              # cracked ground at its feet
        S.append(box((k, 0.3, 8.0), (2.0, 0.3, 1.2), "slag", r=0.2))
    return S


@unit("Starkiller Titan", yaw=30, scale=1.0, big=True)
def starkiller_titan():
    S, P = titan({"thighs": "plum", "hull": "plum", "shins": "steel", "beacon": "glow_violet"})
    S.append(box((0, 32.0, 6.8), (4.4, 1.6, 1.0), "glow_violet", r=0.5))
    x, y, z = P["top"]
    S.append(box((2.0, y + 2.0, -1.0), (2.4, 2.4, 6.0), "graphite", r=0.8))          # the rail cannon
    S.append(box((2.0, y + 2.0, 9.0), (1.6, 1.6, 6.0), "steel", r=0.5))
    S.append(sphere((2.0, y + 2.0, 15.4), 1.4, "glow_violet"))
    S.append(sphere((2.0, y + 2.0, 16.4), 0.7, "glow_white"))
    for k in range(3):
        S.append(torus((2.0, y + 2.0, 4.0 + k * 3.0), 2.2, 0.5, "lilac", R=rot_x(math.radians(90))))
    S.append(sphere((0, 30.0, -7.6), 3.0, "glow_violet"))                             # its core
    for side, sx in (("shoulder_R", 1), ("shoulder_L", -1)):
        px, py, pz = P[side]
        S.append(sphere((px, py, pz), 3.6, "graphite"))
        S.append(capsule((px, py, pz), (px + sx * 2.0, py - 10.0, pz + 2.0), 2.6, "plum"))
        S.append(sphere((px + sx * 2.0, py - 11.0, pz + 2.0), 2.4, "steel"))
    return S


@unit("Titan Command Center", yaw=30, scale=1.0, big=True)
def command_center():
    S = []
    for sx in (-1, 1):                                                               # tracks
        S.append(box((sx * 8.0, 3.6, 0), (3.6, 3.6, 10.0), "graphite", r=3.0))
        for z in (-6, -2, 2, 6):
            S.append(cylinder((sx * 10.0, 3.6, z), (sx * 11.8, 3.6, z), 1.8, "steel", round_=0.4))
    S.append(box((0, 11.0, 0), (9.0, 4.0, 9.0), "khaki", r=1.6))                     # the base
    S.append(box((0, 19.0, -1.0), (6.4, 5.0, 6.4), "khaki", r=1.4))                   # the tower
    S.append(box((0, 20.0, 5.2), (4.8, 1.6, 0.6), "glass", r=0.4))
    S.append(capsule((0, 24.0, -1.0), (0, 30.0, -1.0), 0.8, "graphite"))
    dish = cut(sphere((0, 33.0, 2.0), 6.0, "steel"), (0, 0, -1), -1.2)
    S.append(hollow(dish, sphere((0, 33.0, 3.8), 6.0, "steel")))
    S.append(capsule((0, 33.0, 0.0), (0, 33.0, 5.6), 0.4, "graphite"))
    S.append(sphere((0, 33.0, 5.8), 0.8, "glow_amber"))
    for sx in (-1, 1):
        S.append(capsule((sx * 5.0, 23.0, -5.0), (sx * 6.0, 36.0, -6.0), 0.4, "graphite"))   # antennae
        S.append(sphere((sx * 6.0, 36.4, -6.0), 0.7, "glow_amber"))
    for k in (-6.0, -2.0, 2.0, 6.0):
        S.append(sphere((k, 12.0, 9.0), 0.7, "glow_amber"))
    S.append(box((0, 16.0, -9.6), (5.6, 4.0, 1.0), "warning", r=0.4))                 # a bay that lets things out
    return S


# ================================================================ TROOPS: CERBERUS
@unit("CERBERUS Blitz Bot", yaw=62, kind="troop", centre="box")
def cerberus_blitz():
    return sample.cerberus_blitz()


@unit("CERBERUS Barriage Bot", yaw=60, kind="troop", centre="box")
def cerberus_barriage():
    S, P = quadruped({"body": "gunmetal", "plates": "khaki", "head": "steel"}, headkind="block")
    x, y, z = P["back"]
    S.append(box((0, y + 1.6, -1.0), (3.6, 1.0, 4.0), "graphite", r=0.4))          # the launcher's base
    rack = box((0, y + 4.6, 1.0), (3.4, 2.6, 5.0), "khaki", r=0.8)
    S.append(moved(rack, R=rot_x(-0.45), about=(0, y + 2.0, -1.0)))
    for dx in (-1.6, 0.0, 1.6):
        for dy in (-0.9, 0.9):
            S.append(sphere((dx, y + 4.6 + dy + 3.0, 6.6), 0.75, "glow_orange"))
    for sx in (-1, 1):                                                                # the bipod, folded
        S.append(capsule((sx * 2.2, 13.0, 12.0), (sx * 2.8, 9.0, 16.0), 0.4, "steel"))
    return S


@unit("CERBERUS Breacher Bot", yaw=62, kind="troop", centre="box")
def cerberus_breacher():
    S, P = quadruped({"body": "gunmetal", "plates": "ochre", "head": "steel", "eye": "glow_amber"}, headkind="wolf")
    hx, hy, hz = P["head"]
    S.append(box((0, hy + 0.2, hz + 4.6), (3.4, 2.8, 0.9), "ochre", r=0.5))          # a ram plate on the snout
    for sx in (-1, 1):
        S.append(cylinder((sx * 3.2, 15.0, 4.0), (sx * 3.2, 15.0, 13.0), 1.0, "graphite", round_=0.3))   # slag spray barrels
        S.append(sphere((sx * 3.2, 15.0, 13.4), 0.7, "glow_orange"))
    return S


@unit("CERBERUS Overlord Bot", yaw=55, kind="troop", centre="box")
def cerberus_overlord():
    S, P = quadruped({"body": "gunmetal", "plates": "gold", "head": "steel", "eye": "glow_violet"}, headkind=None)
    for k, (x, a) in enumerate(((-3.2, -0.35), (0.0, 0.0), (3.2, 0.35))):           # three heads, as the name says
        hp = (x, 18.0 + (1.0 if k == 1 else 0.0), 12.4)
        head_ = [box(hp, (1.8, 2.0, 3.0), "steel", r=0.8), box((hp[0], hp[1] - 1.6, hp[2] + 1.2), (1.5, 0.8, 2.6), "graphite", r=0.4),
                 sphere((hp[0] + 0.9, hp[1] + 0.6, hp[2] + 2.8), 0.55, "glow_violet"), sphere((hp[0] - 0.9, hp[1] + 0.6, hp[2] + 2.8), 0.55, "glow_violet"),
                 cone((hp[0], hp[1] + 1.8, hp[2] - 1.0), (hp[0], hp[1] + 4.6, hp[2] - 1.8), 0.9, 0.2, "gold")]
        S += [moved(h, R=rot_y(a), about=(x, 16.0, 9.0)) for h in head_]
        S.append(capsule((x * 0.6, 15.6, 8.6), hp, 1.4, "gunmetal"))
    S.append(capsule((0, 18.0, -2.0), (0, 25.0, -3.0), 0.5, "graphite"))           # the command mast
    S.append(sphere((0, 25.4, -3.0), 1.0, "glow_violet"))
    return S


# ================================================================ TROOPS: ONYX (black armour, one colour each)
def onyx(pose, eye, accent, build=1.0, extra=None, headkind="visor"):
    S, H = person(pose=pose, build=build, mats={"legs": "onyx", "boots": "onyx", "hips": "graphite", "torso": "onyx",
                                                "chest": "onyx", "pads": "onyx", "arms": "graphite", "hands": "onyx", "belt": accent,
                                                "knees": "onyx"})
    S += head(headkind, H["head"], {"helmet": "onyx", "eye": eye}, size=1.05)
    x, y, z = H["chest"]
    S.append(box((0, y + 2.6, 2.9 * build), (2.2 * build, 0.5, 0.3), eye, r=0.1))   # a lit seam across the chest
    return S, H


material("onyx", ["050403", "171819", "2c3438", "465456", "64878c", "8ac4c3"], hi="afe9df", gloss=0.8, line="050403")


@unit("ONYX Assassin", yaw=48, kind="troop")
def onyx_assassin():
    S, H = onyx("dual", "glow_plasma", "plum", build=0.9)
    S += blade(H["R"], mat="lilac", length=8.0, glow="glow_plasma")
    S += blade(H["L"], mat="lilac", length=6.0)
    S.append(cut(cone((0, 27.0, -1.6), (0, 6.0, -3.6), 3.8, 6.4, "plum"), (0, 0, 1), -1.0))   # a cape
    return S


@unit("ONYX Blademaster", yaw=45, kind="troop")
def onyx_blademaster():
    S, H = onyx("melee", "glow_orange", "vantage")
    S += blade(H["R"], mat="silver", length=9.5, up=True, glow="glow_orange")
    S += blade(H["L"], mat="silver", length=8.0)
    return S


@unit("ONYX Breacher", yaw=48, kind="troop")
def onyx_breacher():
    S, H = onyx("rifle", "glow_amber", "ochre", build=1.1)
    x, y, z = H["R"]
    S += [box((x - 0.6, y + 0.6, z + 4.0), (1.3, 1.5, 5.6), "graphite", r=0.5),       # a short heavy shotgun
          cylinder((x - 0.6, y + 1.0, z + 9.0), (x - 0.6, y + 1.0, z + 11.6), 1.1, "steel", round_=0.3),
          box((x - 0.6, y - 1.2, z + 0.6), (0.7, 1.6, 0.8), "graphite", r=0.3)]
    S.append(box((-3.6, 18.0, 3.2), (1.6, 1.2, 0.8), "ochre", r=0.3))              # a breaching charge on the belt
    S.append(sphere((-3.6, 18.6, 4.0), 0.5, "glow_amber"))
    return S


@unit("ONYX Brute", yaw=40, scale=1.12, kind="troop")
def onyx_brute():
    S, H = onyx("fists", "glow_orange", "crimson", build=1.4, headkind="bucket")
    for side in ("R", "L"):
        x, y, z = H[side]
        S.append(box((x, y, z + 0.8), (2.2, 2.2, 2.4), "onyx", r=0.9))             # power fists
        S.append(box((x, y + 0.2, z + 3.2), (1.8, 1.4, 0.4), "crimson", r=0.3))
    return S


@unit("ONYX Guardian", yaw=42, kind="troop")
def onyx_guardian():
    S, H = onyx("shield", "glow_blue", "navy", build=1.15)
    S += shield(H["L"], mat="onyx", w=5.0, h=7.0, trim="navy", glow="glow_blue")
    S += baton(H["R"], mat="graphite", glow="glow_blue")
    return S


@unit("ONYX Sharpshooter", yaw=50, kind="troop")
def onyx_sharpshooter():
    S, H = onyx("rifle", "glow_acid", "jade", build=0.95)
    S += sniper(H["R"], mat="graphite", glow="glow_acid")
    S.append(cut(cone((0, 27.0, -1.4), (0, 9.0, -3.0), 3.4, 5.6, "jade"), (0, 0, 1), -1.0))   # a ghillie cloak
    return S


@unit("ONYX Stitcher", yaw=42, kind="troop")
def onyx_stitcher():
    S, H = onyx("device", "glow_mint", "teal")
    S.append(box((0, 22.0, -4.6), (3.2, 3.6, 1.6), "teal", r=0.8))                 # med pack
    S.append(box((0, 22.4, -6.2), (1.6, 0.5, 0.3), "medic", r=0.1))
    S.append(box((0, 22.4, -6.2), (0.5, 1.6, 0.3), "medic", r=0.1))
    S += arm((3.0, 25.0, -4.0), (6.0, 29.0, -1.0), (5.0, 26.0, 4.0), r=0.6, mat="steel", joint="teal")   # a stitching arm over the shoulder
    S.append(capsule((5.0, 26.0, 4.0), (4.6, 23.0, 6.6), 0.35, "silver"))
    x, y, z = H["R"]
    S.append(box((0.4, y + 0.6, z + 0.4), (2.4, 1.6, 1.0), "glow_mint", r=0.4))      # a dermal patch, glowing
    return S


@unit("ONYX Wraith", yaw=45, kind="troop")
def onyx_wraith():
    S, H = onyx("low", "glow_white", "lilac", build=0.9, headkind="hood")
    S += pistol(H["R"], mat="onyx", glow="glow_white")
    S.append(cut(cone((0, 27.0, -1.2), (0, 3.0, -2.6), 4.0, 7.4, "lilac"), (0, 0, 1), 0.2))    # a long shimmering cloak
    return S


# ================================================================ TROOPS: guard bots and sentinels
@unit("SecurMax Civilian Guard Bot", yaw=42, kind="troop")
def securmax():
    S, H = person(pose="shield", build=1.1, mats={"legs": "navy", "boots": "graphite", "hips": "navy", "torso": "white",
                                                   "chest": "navy", "pads": "white", "arms": "navy", "hands": "graphite"})
    S += head("visor", H["head"], {"helmet": "white", "eye": "glass"}, size=1.05)
    S.append(sphere((0, H["head"][1] + 3.2, H["head"][2]), 0.8, "glow_blue"))      # a light on the cap
    S += shield(H["L"], mat="glass", w=4.4, h=6.0, trim="white")
    S += baton(H["R"], mat="graphite", glow="glow_blue")
    return S


@unit("BRICK Security Bot", yaw=38, scale=1.1, kind="troop")
def brick():
    S, H = person(pose="shield", build=1.5, height=0.95, mats={"legs": "concrete", "boots": "graphite", "hips": "graphite", "torso": "concrete",
                                                               "chest": "concrete", "pads": "concrete", "arms": "concrete", "hands": "graphite"})
    S += head("bucket", H["head"], {"helmet": "concrete", "eye": "glow_orange"}, size=1.0)
    x, y, z = H["L"]
    S.append(box((x + 0.6, y - 1.0, z + 1.6), (5.6, 7.6, 1.0), "concrete", r=0.6))  # a wall of a shield
    for k in (-2.4, 2.4):
        S.append(box((x + 0.6, y - 1.0 + k, z + 2.7), (5.0, 0.35, 0.2), "graphite"))
    S.append(box((x + 0.6, y + 5.2, z + 2.7), (4.0, 0.6, 0.3), "warning", r=0.2))
    return S


@unit("Foundry Sentinel", yaw=42, kind="troop")
def foundry_sentinel():
    S, H = person(pose="melee", build=1.25, mats={"legs": "charcoal", "boots": "graphite", "hips": "slag", "torso": "slag",
                                                   "chest": "charcoal", "pads": "slag", "arms": "charcoal", "hands": "graphite", "knees": "slag"})
    S += head("bucket", H["head"], {"helmet": "slag", "eye": "glow_orange"}, size=1.0)
    for k in (-1.8, 0, 1.8):
        S.append(box((k, 21.0, 4.0), (0.4, 2.4, 0.4), "glow_orange", r=0.1))          # heat vents
    x, y, z = H["R"]
    S.append(capsule((x, y - 2.0, z), (x, y + 8.0, z + 1.0), 0.7, "steel"))            # the rivet hammer
    S.append(cylinder((x - 2.4, y + 8.2, z + 1.0), (x + 2.4, y + 8.2, z + 1.0), 1.9, "charcoal", round_=0.5))
    S.append(sphere((x + 2.6, y + 8.2, z + 1.0), 0.8, "glow_orange"))
    return S


# ================================================================ TROOPS: the rest
@unit("Aether Battery", yaw=40, kind="troop")
def aether_battery():
    S = []
    for sx in (-1, 1):
        for sz in (-1, 1):
            S.append(capsule((sx * 3.0, 8.0, sz * 3.0), (sx * 5.0, 0.8, sz * 5.0), 0.8, "steel"))
    S.append(cylinder((0, 6.0, 0), (0, 22.0, 0), 5.2, "graphite", round_=1.2))       # the cell
    S.append(cylinder((0, 10.0, 0), (0, 18.0, 0), 5.5, "glow_mint"))
    for a in range(4):
        t = a * math.pi / 2 + 0.4
        S.append(box((math.cos(t) * 5.4, 14.0, math.sin(t) * 5.4), (0.7, 4.2, 0.7), "graphite", r=0.2))
    for y in (8.4, 19.6):
        S.append(torus((0, y, 0), 5.4, 0.7, "vantage"))
    for k in range(3):
        a = k * 2.1
        S.append(cone((math.cos(a) * 2.0, 22.0, math.sin(a) * 2.0), (math.cos(a) * 2.6, 27.0 + k, math.sin(a) * 2.6), 1.2, 0.2, "crystal"))
    return S


@unit("Aetherium Golem", yaw=36, scale=1.0, big=True, kind="troop")
def aetherium_golem():
    S, H = person(pose="fists", build=1.7, height=1.15, mats={"legs": "graphite", "boots": "charcoal", "hips": "graphite", "torso": "steel",
                                                              "chest": "graphite", "pads": "steel", "arms": "steel", "hands": "graphite", "knees": "steel"})
    hx, hy, hz = H["head"]
    S.append(box((hx, hy - 0.6, hz + 0.4), (2.6, 2.4, 2.6), "steel", r=0.9))
    S.append(box((hx, hy - 0.4, hz + 2.8), (1.8, 0.6, 0.4), "glow_mint", r=0.2))
    for (x, y, z, h_, a) in ((-6.0, 31.0, -1.0, 6.0, 0.3), (6.4, 30.0, -0.5, 5.0, -0.3), (-2.0, 30.5, -3.0, 7.0, 0.1), (2.6, 24.0, 4.6, 3.6, -0.6),
                             (-8.6, 18.0, 3.0, 4.0, 0.5)):
        c = cone((x, y, z), (x, y + h_, z), 1.8, 0.2, "crystal")
        S.append(moved(c, R=rot_z(a), about=(x, y, z)))
    for side in ("R", "L"):
        x, y, z = H[side]
        S.append(box((x, y, z + 0.8), (2.6, 2.6, 2.6), "graphite", r=1.0))
        S.append(sphere((x, y + 0.4, z + 3.0), 1.0, "glow_mint"))
    return S


@unit("Augmented Weapons Specialist", yaw=50, kind="troop")
def aws():
    S, H = person(pose="rifle", build=1.05, mats={"legs": "khaki", "boots": "rubber", "hips": "graphite", "torso": "vantage",
                                                  "chest": "graphite", "pads": "vantage", "arms": "graphite", "hands": "graphite", "knees": "vantage"})
    S += head("face", H["head"], {"skin": "flesh", "hair": "charcoal", "eye": "glow_amber", "eye2": "dark"}, size=1.0)
    S.append(box((H["head"][0] + 1.3, H["head"][1] + 0.1, H["head"][2] + 2.8), (0.9, 0.7, 0.4), "glow_amber", r=0.2))   # the targeting eye
    S += rifle(H["R"], mat="graphite", length=16.0, scope=True, glow="glow_amber", thick=1.2)
    return S


@unit("Cyber Savant", yaw=42, kind="troop")
def cyber_savant():
    S, H = person(pose="device", build=0.95, mats={"legs": "plum", "boots": "rubber", "hips": "plum", "torso": "violet",
                                                   "chest": "graphite", "arms": "plum", "hands": "silver"})
    S += head("visor", H["head"], {"helmet": "plum", "eye": "glow_magenta"}, size=1.05)
    hx, hy, hz = H["head"]
    for k in range(4):                                                              # cables for hair
        a = -0.6 + k * 0.4
        S.append(capsule((hx + math.sin(a) * 2.4, hy + 1.6, hz - 1.6), (hx + math.sin(a) * 3.6, hy - 4.0, hz - 3.4), 0.45, "glow_magenta"))
    x, y, z = H["R"]
    S.append(box((0.2, y + 0.4, z + 1.4), (4.0, 0.25, 2.2), "glow_magenta", r=0.1))    # a keyboard of light
    S.append(box((0.2, y + 3.8, z + 2.8), (3.2, 2.2, 0.2), "glow_violet", r=0.1))     # and a screen
    return S


@unit("Defensive Platform Specialist", yaw=44, kind="troop")
def dps():
    S, H = person(pose="pistol", build=1.05, mats={"legs": "khaki", "boots": "leather", "hips": "khaki", "torso": "ochre",
                                                   "chest": "khaki", "pads": None, "arms": "khaki", "hands": "leather"}, backpack="graphite")
    S += head("cap", H["head"], {"skin": "flesh", "hat": "hazard", "eye": "glass"}, size=1.0)
    S += pistol(H["R"], mat="graphite")
    bx, by, bz = H["back"]
    S.append(cylinder((0, by + 4.0, bz - 1.0), (0, by + 6.0, bz - 1.0), 2.2, "steel", round_=0.5))   # a folded turret on the pack
    S.append(cylinder((0, by + 5.0, bz - 1.0), (0, by + 5.0, bz + 4.0), 0.6, "graphite", round_=0.2))
    S.append(sphere((0, by + 6.4, bz - 1.0), 0.6, "glow_amber"))
    return S


@unit("Entry Denial Bot", yaw=40, kind="troop")
def entry_denial():
    S, H = person(pose="idle", build=1.2, mats={"legs": "steel", "boots": "graphite", "hips": "graphite", "torso": "khaki",
                                                "chest": None, "pads": "khaki", "arms": "steel", "hands": "graphite"})
    S += head("bucket", H["head"], {"helmet": "khaki", "eye": "glow_amber"}, size=0.9)
    dish = cut(sphere((0, 21.0, 0.0), 5.6, "steel"), (0, 0, -1), -3.0)                # a sonic dish on the chest
    S.append(hollow(dish, sphere((0, 21.0, 1.6), 5.4, "steel")))
    for r_ in (1.4, 2.8):
        S.append(torus((0, 21.0, 4.6), r_, 0.35, "glow_yellow", R=rot_x(math.radians(90))))
    S.append(sphere((0, 21.0, 4.4), 0.8, "glow_white"))
    return S


@unit("FALCON Drone", yaw=40, pitch=24, scale=1.45, kind="troop", centre="box", foot_y=50)
def falcon():
    S = [ellipsoid((0, 18.0, 1.0), (3.0, 2.4, 6.0), "white"),
         ellipsoid((0, 18.8, 6.0), (2.0, 1.8, 2.6), "white"),
         box((0, 18.4, 8.4), (1.4, 0.8, 1.2), "vantage", r=0.4),
         sphere((0, 17.8, 8.8), 0.9, "glow_mint"),
         cone((0, 18.6, -4.0), (0, 19.6, -9.0), 2.0, 0.5, "white")]
    for sx in (-1, 1):                                                              # wings, swept
        w = box((sx * 7.0, 19.0, 0.0), (6.0, 0.5, 2.6), "white", r=0.4)
        S.append(moved(w, R=rot_y(sx * 0.35), about=(sx * 2.0, 19.0, 0.0)))
        S.append(box((sx * 11.6, 19.2, -1.6), (1.2, 0.6, 1.4), "vantage", r=0.3))
        S.append(cylinder((sx * 8.0, 19.6, 0.4), (sx * 8.0, 20.2, 0.4), 3.0, "glass"))
    S.append(capsule((0, 16.0, 1.0), (0, 13.0, 1.0), 0.4, "graphite"))
    return S


@unit("FALCON Drone Token", yaw=40, pitch=24, scale=1.45, kind="troop", centre="box", foot_y=50)
def falcon_token():
    return falcon()


@unit("Unmanned Arial Gun Platform", yaw=38, pitch=24, kind="troop")
def uagp():
    S, P = drone({"shell": "khaki", "under": "graphite", "rotor": "ochre", "eye": "glow_amber"})
    x, y, z = P["under"]
    S.append(box((0, y - 0.6, 1.0), (1.6, 1.4, 4.0), "graphite", r=0.5))             # the gun pod
    for dx in (-0.7, 0.7):
        S.append(capsule((dx, y - 0.6, 4.0), (dx, y - 0.6, 9.0), 0.45, "steel"))
    return S


@unit("Scrap Caddy", yaw=50, scale=1.3, kind="troop", centre="box")
def scrap_caddy():
    S = [box((0, 7.0, 0), (5.0, 3.0, 7.0), "rust", r=1.0)]
    for sx in (-1, 1):
        for sz in (-1, 1):
            S.append(cylinder((sx * 5.0, 3.4, sz * 4.6), (sx * 6.6, 3.4, sz * 4.6), 3.0, "rubber", round_=0.6))
            S.append(cylinder((sx * 6.0, 3.4, sz * 4.6), (sx * 6.9, 3.4, sz * 4.6), 1.2, "steel", round_=0.2))
    for (x, y, z, w, h, d, m) in ((-1.6, 11.6, -2.0, 2.6, 1.6, 2.0, "steel"), (2.0, 11.4, 1.0, 2.0, 1.4, 2.4, "teal"),
                                  (-0.6, 13.6, 0.0, 1.6, 1.2, 1.6, "ochre"), (2.6, 13.0, -3.6, 1.2, 1.8, 1.2, "crimson")):
        S.append(box((x, y, z), (w, h, d), m, r=0.5))                             # the load
    S += arm((0, 10.0, 6.0), (0, 16.0, 8.0), (0, 13.0, 12.0), r=0.8, mat="steel", joint="vantage")
    S += claw((0, 13.0, 12.0), size=0.8)
    S.append(sphere((3.6, 9.0, 7.0), 0.8, "glow_amber"))
    return S


@unit("Scrap rat", yaw=48, scale=1.0, kind="troop")
def scrap_rat():
    S, H = person(pose="rifle", build=0.85, height=0.88, mats={"legs": "leather", "boots": "rubber", "hips": "cloth", "torso": "khaki",
                                                               "chest": None, "arms": "leather", "hands": "flesh"}, hunch=0.3)
    S += head("mask", H["head"], {"helmet": "leather", "eye": "glow_amber", "filter": "rust"}, size=1.0)
    x, y, z = H["R"]
    S += [capsule((x - 0.6, y + 0.6, z - 1.0), (x - 0.6, y + 0.8, z + 12.0), 0.9, "rust"),     # a pipe gun, taped
          box((x - 0.6, y + 0.7, z + 4.0), (1.1, 1.1, 0.8), "khaki", r=0.3), box((x - 0.6, y - 0.8, z + 0.6), (0.6, 1.4, 0.7), "leather", r=0.3)]
    S.append(box((0, 20.0, -4.0), (3.0, 3.4, 1.8), "cloth", r=1.2))               # a sack of shinies
    S.append(sphere((1.4, 22.6, -4.0), 0.7, "glow_yellow"))
    return S


@unit("Scrapheap Brawler", yaw=40, scale=1.1, kind="troop")
def scrapheap_brawler():
    S, H = person(pose="melee", build=1.35, mats={"legs": "rust", "boots": "graphite", "hips": "rust", "torso": "steel",
                                                   "chest": "rust", "pads": "ochre", "arms": "rust", "hands": "graphite", "knees": "steel"})
    S += head("bucket", H["head"], {"helmet": "rust", "eye": "glow_amber"}, size=1.0)
    x, y, z = H["R"]
    S.append(capsule((x, y - 2.0, z), (x, y + 8.0, z + 0.6), 0.7, "steel"))          # a pipe with a valve on it: Bonk!
    S.append(box((x, y + 8.6, z + 0.6), (2.2, 1.6, 1.6), "ochre", r=0.5))
    S.append(torus((x, y + 8.6, z + 0.6), 1.8, 0.4, "crimson"))
    return S


@unit("Scuttlebot", yaw=50, scale=0.75, kind="troop", centre="box", foot_y=44)
def scuttlebot():
    S, P = spider({"body": "steel", "abdomen": "graphite", "joints": "vantage", "eye": "glow_amber"}, legs=6, abdomen=False)
    hx, hy, hz = P["head"]
    for sx in (-1, 1):
        S.append(cone((hx + sx * 1.6, hy, hz + 2.0), (hx + sx * 3.0, hy - 2.0, hz + 9.0), 1.0, 0.1, "silver"))   # six-inch blades
    return S


@unit("Scuttle Swarm", yaw=50, scale=0.42, kind="troop", centre="box", foot_y=44)
def scuttle_swarm():
    S = []
    for (dx, dz) in ((-14, -8), (12, -10), (0, 6), (-16, 14), (16, 12)):
        part, P = spider({"body": "steel", "abdomen": "graphite", "joints": "vantage", "eye": "glow_amber"}, legs=6, abdomen=False)
        S += [moved(p, by=(dx, 0, dz)) for p in part]
    return S


@unit("Scuttle Overseer", yaw=48, kind="troop", centre="box")
def scuttle_overseer():
    S, P = spider({"body": "vantage", "abdomen": "graphite", "legs": "steel", "joints": "vantage", "eye": "glow_amber"}, legs=6, size=0.9)
    x, y, z = P["back"]
    for k in (-1, 0, 1):                                                              # an antenna crown
        S.append(capsule((k * 2.0, y, z), (k * 2.8, y + 6.0, z - 1.0), 0.4, "graphite"))
        S.append(sphere((k * 2.8, y + 6.2, z - 1.0), 0.7, "glow_blue"))
    S.append(capsule((4.0, 12.0, 6.0), (9.0, 16.0, 11.0), 0.4, "glow_blue"))         # the static lash
    S.append(capsule((9.0, 16.0, 11.0), (12.0, 11.0, 13.0), 0.35, "glow_blue"))
    return S


@unit("Scuttle brood mother", yaw=48, scale=0.9, big=True, kind="troop", centre="box")
def brood_mother():
    S, P = spider({"body": "vantage", "abdomen": "plum", "legs": "steel", "joints": "vantage", "eye": "glow_amber"}, legs=8, size=1.25)
    x, y, z = P["tail"]
    for (dx, dy, dz) in ((-2.4, 2.0, 0.0), (2.4, 2.4, -0.6), (0.0, 4.4, -1.6), (-1.0, 0.0, -3.6), (2.2, 0.4, -3.0)):
        S.append(sphere((x + dx, y + dy, z + dz), 1.5, "glow_mint"))                  # the clutch, glowing
    hx, hy, hz = P["head"]
    for sx in (-1, 1):
        S.append(cone((hx + sx * 2.0, hy, hz + 3.0), (hx + sx * 3.6, hy - 2.6, hz + 9.0), 1.3, 0.1, "silver"))
    return S


@unit("Sentry Turret", yaw=40, scale=1.3, kind="troop")
def sentry_turret():
    S = []
    for a in (0.5, 2.6, 4.7):                                                         # a tripod
        S.append(capsule((0, 10.0, 0), (math.cos(a) * 7.0, 0.6, math.sin(a) * 7.0), 0.8, "graphite"))
    S.append(cylinder((0, 9.0, 0), (0, 12.0, 0), 3.0, "steel", round_=0.6))
    S.append(box((0, 15.0, 0.6), (4.0, 3.0, 4.6), "ochre", r=1.0))
    S.append(box((0, 15.6, 5.0), (2.6, 1.6, 0.6), "graphite", r=0.3))
    S.append(sphere((0, 17.6, 3.6), 0.8, "glow_amber"))
    S.append(cylinder((0, 14.6, 4.0), (0, 14.6, 8.0), 2.0, "graphite", round_=0.4))  # the gatling
    for k in range(6):
        t = k * math.pi / 3
        S.append(capsule((math.cos(t) * 1.0, 14.6 + math.sin(t) * 1.0, 7.0), (math.cos(t) * 1.0, 14.6 + math.sin(t) * 1.0, 14.0), 0.4, "steel"))
    S.append(box((-4.6, 14.0, 0.0), (1.0, 2.6, 2.4), "graphite", r=0.4))            # the belt box
    return S


@unit("Ledger Runner", yaw=48, kind="troop")
def ledger_runner():
    S, H = person(pose="pistol", build=0.92, mats={"legs": "charcoal", "boots": "leather", "hips": "charcoal", "torso": "plum",
                                                   "chest": "gold", "arms": "charcoal", "hands": "leather"})
    S += head("face", H["head"], {"skin": "flesh", "hair": "gold", "eye": "glow_violet", "eye2": "dark"}, size=1.0)
    S += pistol(H["R"], mat="gold", glow="glow_violet")
    S.append(box((-4.6, 17.0, 0.4), (1.4, 2.4, 2.4), "leather", r=0.6))            # a satchel of ledgers
    S.append(capsule((-4.0, 19.0, 2.6), (3.6, 25.6, 2.6), 0.35, "leather"))
    return S


@unit("Slag Hauler", yaw=40, scale=1.1, kind="troop")
def slag_hauler():
    S, H = person(pose="shield", build=1.35, mats={"legs": "charcoal", "boots": "graphite", "hips": "slag", "torso": "slag",
                                                   "chest": "charcoal", "pads": "slag", "arms": "charcoal", "hands": "graphite"})
    S += head("bucket", H["head"], {"helmet": "charcoal", "eye": "glow_orange"}, size=0.95)
    x, y, z = H["L"]
    bucket = cut(cylinder((x + 0.8, y - 1.0, z + 1.0), (x + 0.8, y - 1.0, z + 3.6), 6.0, "slag", round_=0.8), (0, 1, 0), y + 3.2)
    S.append(bucket)                                                                 # a slag bucket for a shield
    S.append(box((x + 0.8, y + 2.6, z + 2.4), (5.0, 0.6, 0.9), "glow_orange", r=0.3))
    return S


@unit("Arc Technician", yaw=45, kind="troop")
def arc_technician():
    S, H = person(pose="pistol", build=1.0, mats={"legs": "navy", "boots": "leather", "hips": "leather", "torso": "navy",
                                                  "chest": "vantage", "arms": "navy", "hands": "leather"}, backpack="steel")
    S += head("cap", H["head"], {"skin": "flesh", "hat": "vantage", "eye": "glow_blue"}, size=1.0)
    x, y, z = H["R"]
    S.append(capsule((x, y + 0.4, z - 0.6), (x, y + 0.6, z + 5.0), 0.8, "steel"))   # an arc tool
    S.append(capsule((x - 0.8, y + 0.6, z + 5.0), (x - 0.8, y + 0.6, z + 7.0), 0.3, "brass"))
    S.append(capsule((x + 0.8, y + 0.6, z + 5.0), (x + 0.8, y + 0.6, z + 7.0), 0.3, "brass"))
    S.append(sphere((x, y + 0.6, z + 7.4), 0.9, "glow_blue"))
    bx, by, bz = H["back"]
    S.append(capsule((2.0, by + 4.0, bz - 1.0), (x, y + 0.6, z - 0.6), 0.35, "glow_amber"))   # a lit cable from the pack
    return S


@unit("Debt Collector", yaw=42, scale=1.1, kind="troop")
def debt_collector():
    S, H = person(pose="melee", build=1.25, mats={"legs": "charcoal", "boots": "rubber", "hips": "charcoal", "torso": "charcoal",
                                                   "chest": "gold", "pads": "gold", "arms": "charcoal", "hands": "leather", "coat": "charcoal"}, coat=True)
    S += head("helmet", H["head"], {"helmet": "charcoal", "eye": "glow_amber"}, size=1.05)
    S += baton(H["R"], mat="gold", glow="glow_amber")
    x, y, z = H["L"]
    S.append(box((x, y + 0.6, z + 1.6), (1.6, 2.2, 0.4), "lilac", r=0.2))            # the bill, held out
    S.append(box((x, y + 0.6, z + 1.9), (1.2, 1.6, 0.2), "glow_violet", r=0.1))
    return S


@unit("Chaff Swarm", yaw=40, pitch=24, scale=0.5, kind="troop", centre="box", foot_y=40)
def chaff_swarm():
    S = []
    for (dx, dy, dz) in ((-16, 10, -8), (14, 18, -12), (0, 4, 8), (-14, 22, 14), (18, 4, 12), (2, 26, -4)):
        part, P = drone({"shell": "silver", "under": "graphite", "rotor": "graphite", "eye": "glow_amber"}, span=8.0)
        S += [moved(p, by=(dx, dy - 16.0, dz)) for p in part]
    return S


# ================================================================ CONTENT BATCH 1 (0.22): District 3, fast melee
@unit("Skitterling", yaw=50, scale=0.62, centre="box", foot_y=42)
def skitterling():
    S, P = spider({"body": "teal", "joints": "vantage", "legs": "graphite", "feet": "steel", "head": "graphite", "eye": "glow_cyan"},
                  legs=6, abdomen=False, reach=1.15, lift=1.15)
    hx, hy, hz = P["head"]
    S.append(cone((hx, hy - 1.0, hz + 2.0), (hx, hy - 3.0, hz + 7.0), 0.9, 0.1, "silver"))          # a single stabbing tine
    return S


@unit("Skitter Stalker", yaw=48, pitch=20, scale=0.92, centre="box")
def skitter_stalker():
    S, P = spider({"body": "teal", "abdomen": "graphite", "joints": "vantage", "legs": "gunmetal", "feet": "steel", "head": "graphite", "eye": "glow_cyan"},
                  legs=6, abdomen=True, reach=1.2, lift=1.3)
    hx, hy, hz = P["head"]
    for sx in (-1, 1):                                                                          # two scythe arms, raised
        S.append(capsule((hx + sx * 2.4, hy + 1.0, hz), (hx + sx * 4.4, hy + 7.0, hz + 3.0), 0.8, "gunmetal"))
        S.append(cone((hx + sx * 4.4, hy + 7.0, hz + 3.0), (hx + sx * 3.0, hy - 1.0, hz + 10.0), 1.0, 0.1, "silver"))
    S.append(box((0, 15.4, 1.0), (2.6, 0.6, 3.6), "hazard", r=0.3))
    return S


@unit("Brood Matriarch", yaw=48, scale=0.88, big=True, centre="box")
def brood_matriarch():
    S, P = spider({"body": "teal", "abdomen": "gunmetal", "legs": "graphite", "joints": "vantage", "head": "graphite", "eye": "glow_cyan"},
                  legs=8, size=1.3)
    x, y, z = P["tail"]
    for (dx, dy, dz) in ((-2.6, 2.0, 0.0), (2.6, 2.4, -0.6), (0.0, 4.6, -1.8), (-1.2, 0.2, -3.8), (2.4, 0.6, -3.2), (0.0, -1.0, -1.0)):
        S.append(sphere((x + dx, y + dy, z + dz), 1.4, "glow_cyan"))                            # the brood, racked on her back
    S.append(box((x, y + 1.6, z - 1.0), (4.4, 0.5, 4.0), "vantage", r=0.4))
    hx, hy, hz = P["head"]
    for sx in (-1, 1):
        S.append(cone((hx + sx * 2.2, hy, hz + 3.0), (hx + sx * 3.8, hy - 2.6, hz + 9.0), 1.3, 0.1, "silver"))
    return S


@unit("Ilsa Varn, Jump-Frame Pilot", yaw=40, scale=1.08, kind="hero")
def ilsa_varn():
    S, H = person(pose="melee", build=1.0, mats={"legs": "gunmetal", "boots": "vantage", "hips": "graphite", "torso": "navy",
                                                 "chest": "vantage", "pads": "vantage", "arms": "navy", "hands": "graphite", "knees": "vantage"},
                  backpack="gunmetal")
    S += head("face", H["head"], {"skin": "flesh", "hair": "ochre", "eye": "glow_cyan", "eye2": "dark"}, size=1.0)
    for sx in (-1, 1):                                                                           # the jump-frame: a spring piston behind each leg
        S.append(cylinder((sx * 2.2, 2.0, -2.6), (sx * 2.2, 12.0, -2.4), 0.7, "steel", 0.3))
        S.append(cylinder((sx * 2.2, 5.0, -2.6), (sx * 2.2, 9.0, -2.5), 1.0, "brass", 0.3))
        S.append(sphere((sx * 2.2, 12.4, -2.4), 0.7, "glow_cyan"))
    S += baton(H["R"], mat="silver", glow="glow_cyan")
    return S


# ---------------------------------------------------------------- the free Heroes (0.25): the Hangar's own
@unit("Dock Hand", yaw=40, scale=1.08, kind="hero")
def dock_hand():
    S, H = person(pose="melee", build=1.05, mats={"legs": "drab", "boots": "rubber", "hips": "drab", "torso": "cloth",
                                                  "chest": "hazard", "arms": "cloth", "hands": "leather", "knees": "rubber"})
    S += head("cap", H["head"], {"skin": "flesh", "hat": "hazard", "eye": "glass"}, size=1.0)
    S += hammer(H["R"], mat="steel", head="gunmetal", length=8.0)                                # a heavy spanner
    return S


@unit("Hangar Rifleman", yaw=45, scale=1.08, kind="hero")
def hangar_rifleman():
    S, H = person(pose="rifle", build=1.0, mats={"legs": "olive", "boots": "rubber", "hips": "olive", "torso": "drab",
                                                 "chest": "olive", "pads": "drab", "arms": "drab", "hands": "graphite", "knees": "olive"},
                  backpack="olive")
    S += head("helmet", H["head"], {"helmet": "olive", "eye": "glass"}, size=1.0)
    S += rifle(H["R"], H["L"], mat="graphite", length=14.0, scope=False)
    return S


@unit("Field Medic", yaw=40, scale=1.08, kind="hero")
def field_medic():
    S, H = person(pose="pistol", build=0.95, mats={"legs": "cloth", "boots": "rubber", "hips": "cloth", "torso": "white",
                                                   "chest": "white", "pads": "white", "arms": "white", "hands": "rubber"},
                  backpack="blood")
    c = H["chest"]
    S.append(box((c[0], c[1] + 0.4, 3.2), (0.6, 1.8, 0.3), "blood", r=0.1))                    # the cross on her chest
    S.append(box((c[0], c[1] + 0.4, 3.2), (1.8, 0.6, 0.3), "blood", r=0.1))
    S += head("face", H["head"], {"skin": "flesh", "hair": "graphite", "eye": "dark", "eye2": "dark"}, size=1.0)
    S += pistol(H["R"], mat="graphite")
    return S


@unit("Skitter Runner Mk I", yaw=50, scale=0.85, kind="troop", centre="box")
def skitter_runner():
    S, P = spider({"body": "concrete", "joints": "vantage", "legs": "steel", "feet": "graphite", "head": "graphite", "eye": "glow_amber"},
                  legs=6, abdomen=False, reach=1.2, lift=1.15)
    S.append(box((0, 15.6, 1.0), (3.6, 1.2, 4.0), "vantage", r=0.6))
    hx, hy, hz = P["head"]
    S.append(capsule((hx, hy, hz + 2.0), (hx, hy + 1.0, hz + 7.0), 1.2, "gunmetal"))            # a ram for the pounce
    S.append(sphere((hx, hy + 1.0, hz + 7.4), 1.5, "hazard"))
    return S


@unit("Skitter Harrier Mk I", yaw=50, scale=0.85, kind="troop", centre="box")
def skitter_harrier():
    S, P = spider({"body": "concrete", "joints": "vantage", "legs": "steel", "feet": "graphite", "head": "graphite", "eye": "glow_amber"},
                  legs=6, abdomen=False, reach=1.25, lift=1.25)
    S.append(box((0, 15.6, 1.0), (3.6, 1.2, 4.0), "hazard", r=0.6))
    hx, hy, hz = P["head"]
    for sx in (-1, 1):                                                                           # raking claws
        for k in (-1, 0, 1):
            S.append(cone((hx + sx * 2.6, hy - 0.4, hz + 2.0), (hx + sx * (3.4 + k * 0.6), hy - 3.0, hz + 7.0), 0.5, 0.05, "silver"))
    return S


# ================================================================ CHASSIS BODY PLANS (the Workshop's stand-in skins)
@unit("Bipedal", yaw=48, kind="body")
def body_bipedal():
    S, H = person(pose="rifle", build=1.05, mats={"legs": "steel", "boots": "graphite", "hips": "graphite", "torso": "concrete",
                                                  "chest": "vantage", "pads": "concrete", "arms": "steel", "hands": "graphite", "knees": "concrete"})
    S += head("bucket", H["head"], {"helmet": "concrete", "eye": "glow_amber"}, size=1.0)
    S += rifle(H["R"], mat="graphite", length=14.0, scope=False)
    return S


@unit("Quadcopter", yaw=35, pitch=26, kind="body", centre="box")
def body_quadcopter():
    return sample.quadcopter()


@unit("Quadruped", yaw=60, kind="body", centre="box")
def body_quadruped():
    S, P = quadruped({"body": "concrete", "plates": "vantage", "legs": "steel", "head": "concrete", "eye": "glow_amber"}, headkind="block")
    return S


@unit("Hexapod", yaw=48, pitch=22, kind="body", centre="box")
def body_hexapod():
    S, P = spider({"body": "concrete", "abdomen": "graphite", "legs": "steel", "joints": "vantage", "head": "graphite", "eye": "glow_amber"},
                  legs=6, abdomen=False, size=1.0)
    S.append(box((0, 15.6, 1.0), (3.6, 1.2, 4.0), "vantage", r=0.6))
    return S


@unit("Octopod", yaw=48, pitch=22, kind="body", centre="box")
def body_octopod():
    S, P = spider({"body": "concrete", "abdomen": "steel", "legs": "steel", "joints": "vantage", "head": "graphite", "eye": "glow_amber"},
                  legs=8, size=0.95)
    return S


BATCH1 = ["\"Mincer\" Cleaner Bot", "Rictus", "Volt-Warden Ryska", "Sable-Nine, Ledger Adept", "Dross, the Forge-Blind", "Quillon Vex",
          "\"Binder\" Cleaner Bot", "\"Hunter\" Cleaner Bot", "\"Purifier\" Cleaner Bot", "\"Stitcher\" Cleaner Bot",
          "Exo Husk", "Exo Worker Husk", "Laz Welder Husk"]
BODIES = ["Bipedal", "Quadcopter", "Quadruped", "Hexapod", "Octopod"]
BATCH4 = ["Aether Battery", "Aetherium Golem", "Augmented Weapons Specialist", "Cyber Savant", "Defensive Platform Specialist",
          "Entry Denial Bot", "FALCON Drone", "Unmanned Arial Gun Platform", "Scrap Caddy", "Scrap rat", "Scrapheap Brawler",
          "Scuttlebot", "Scuttle Swarm", "Scuttle Overseer", "Scuttle brood mother", "Sentry Turret", "Ledger Runner", "Slag Hauler",
          "Arc Technician", "Debt Collector", "Chaff Swarm"]
BATCH3 = ["CERBERUS Blitz Bot", "CERBERUS Barriage Bot", "CERBERUS Breacher Bot", "CERBERUS Overlord Bot", "ONYX Assassin", "ONYX Blademaster",
          "ONYX Breacher", "ONYX Brute", "ONYX Guardian", "ONYX Sharpshooter", "ONYX Stitcher", "ONYX Wraith", "SecurMax Civilian Guard Bot",
          "BRICK Security Bot", "Foundry Sentinel"]
FREE = ["Dock Hand", "Hangar Rifleman", "Field Medic"]
BATCH5 = ["Skitterling", "Skitter Stalker", "Brood Matriarch", "Ilsa Varn, Jump-Frame Pilot", "Skitter Runner Mk I", "Skitter Harrier Mk I"]
BATCH2 = ["Arachnabot", "Chrome Fiend", "Construction Titan", "Chrome Junkie", "Centibot", "Vaccinator", "Long Range Vaccinator",
          "Decimation Titan", "Earthshaker Titan", "Starkiller Titan", "Titan Command Center"]

if __name__ == "__main__":
    import sys
    names = BATCH1 if len(sys.argv) < 2 else globals()[sys.argv[1]] if sys.argv[1] in globals() and isinstance(globals()[sys.argv[1]], list) else [n for n in U if any(a.lower() in n.lower() for a in sys.argv[1:])]
    imgs = [render_unit(n) for n in names]
    sheet(imgs, preview_path("batch.png"), scale=3, labels=[n[:22] for n in names], cols=5, show1x=False)
    for w in WARN:
        print("WARN", w)
