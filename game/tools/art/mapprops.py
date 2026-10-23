"""What stands on the World Map (0.15), in square pixels over the hex-pixel
ground: a few things on each District's empty tiles, and the dock itself,
the Hangar (Docking Bay 2), as a lit landmark. Seen from higher up than a
fight's props, as the map is."""
import math
from kart import *
from rigs import *
import sample

MP = {}


def mprop(name, d, size=32, foot=(16, 26), yaw=25, pitch=45, scale=1.0, inner=0.7):
    def deco(fn):
        MP[name] = {"fn": fn, "d": d, "size": size, "foot": foot, "yaw": yaw, "pitch": pitch, "scale": scale, "inner": inner}
        return fn
    return deco


def render_mprop(name):
    p = MP[name]
    return make(p["fn"](), size=p["size"], foot=p["foot"], yaw=p["yaw"], pitch=p["pitch"], scale=p["scale"], inner_step=p["inner"])


material("frosted", ["3a2f3e", "654370", "9c8bdb", "c9d4fd", "f1f2ff"], hi="ffffff", gloss=0.4)
material("rack", ["050403", "0e0c0c", "171516", "2d1b1e", "373334"], hi="595757", gloss=0.3)
material("vatglass", ["14121d", "2c3b39", "5d9b79", "97edca", "d0ffea"], hi="f1f2ff", gloss=1.0)
material("ash", ["171516", "323232", "595757", "807b7a", "a69e9a"])


# ---------------------------------------------------------------- 1 · Threshold Dynamics
@mprop("d1_ring", "1", size=32, foot=(16, 28), yaw=20, pitch=40, scale=0.95)
def containment_ring():
    S = [box((0, 1.2, 0), (7.0, 1.2, 3.6), "steel", r=0.6),
         box((0, 3.0, 0), (5.0, 0.8, 2.6), "graphite", r=0.4)]
    ring = torus((0, 0, 0), 7.2, 1.5, "frosted", R=rot_x(math.pi / 2))
    S.append(moved(ring, by=(0, 12.0, 0)))
    S.append(sphere((0, 12.0, 0), 2.6, "glow_violet"))
    S.append(sphere((0, 12.0, 0.6), 1.2, "glow_white"))
    for a in (0.6, 2.4, 4.0):
        S.append(sphere((7.2 * math.cos(a), 12.0 + 7.2 * math.sin(a), 0.9), 1.0, "frosted"))
    return S


# ---------------------------------------------------------------- 2 · Halcyon Cognition
@mprop("d2_pylon", "2", size=32, foot=(16, 29), yaw=0, pitch=35, scale=0.9)
def amplifier_pylon():
    S = [cylinder((0, 0, 0), (0, 2.4, 0), 5.0, "white", round_=0.6),
         cone((0, 2.4, 0), (0, 22.0, 0), 2.2, 1.0, "white"),
         capsule((0, 21.0, 0), (0, 27.0, 0), 0.5, "steel")]
    for y, rr in ((8.0, 4.4), (14.0, 3.6), (19.5, 2.8)):
        S.append(torus((0, y, 0), rr, 0.55, "glow_pink"))
    S.append(sphere((0, 27.6, 0), 1.6, "glow_magenta"))
    return S


# ---------------------------------------------------------------- 3 · Vantage Robotics
@mprop("d3_arm", "3", size=32, foot=(16, 28), yaw=30, pitch=38, scale=0.9)
def assembly_arm():
    """An assembly arm, still, over a half-built frame."""
    S = [cylinder((0, 0, 0), (0, 2.2, 0), 6.0, "graphite", round_=0.6),
         cylinder((0, 2.2, 0), (0, 5.0, 0), 4.0, "vantage", round_=0.6),
         sphere((0, 5.6, 0), 2.6, "graphite")]
    S += arm((0, 5.6, 0), (-4.0, 16.0, -1.0), (5.0, 19.0, 2.0), r=1.6, mat="vantage", joint="graphite")
    S.append(capsule((5.0, 19.0, 2.0), (7.0, 14.0, 3.0), 0.8, "steel"))
    S.append(box((7.0, 13.0, 3.0), (1.6, 0.8, 1.0), "graphite", r=0.3))
    S.append(sphere((7.0, 12.0, 3.0), 0.6, "glow_amber"))
    S.append(box((0, 5.2, 0), (5.2, 0.5, 5.2), "warning", r=0.2))
    return S


# ---------------------------------------------------------------- 4 · Lazarus Computing
@mprop("d4_racks", "4", size=32, foot=(16, 28), yaw=35, pitch=40, scale=0.9)
def server_racks():
    S = []
    for k, x in enumerate((-5.6, 5.6)):
        S.append(box((x, 10.0, 0), (4.6, 10.0, 4.0), "rack", r=0.5))
        for j in range(6):
            y = 4.0 + j * 2.8
            S.append(box((x - 1.6, y, 4.0), (1.6, 0.35, 0.25), "glow_red" if (j + k) % 3 else "glow_white", r=0.1))
            S.append(box((x + 2.0, y, 4.0), (0.4, 0.35, 0.25), "glow_red" if (j + k) % 2 else "glow_amber", r=0.1))
    S.append(capsule((-5.6, 20.4, 0), (5.6, 20.4, -1.0), 0.6, "charcoal"))
    return S


# ---------------------------------------------------------------- 5 · Verdant Biogenics
@mprop("d5_vat", "5", size=32, foot=(16, 29), yaw=15, pitch=35, scale=0.92)
def cracked_vat():
    S = [cylinder((0, 0, 0), (0, 3.0, 0), 6.4, "gunmetal", round_=0.6),
         cylinder((0, 3.0, 0), (0, 15.0, 0), 5.0, "acid", round_=0.3),      # what is left in it
         cylinder((0, 15.0, 0), (0, 21.0, 0), 5.0, "vatglass", round_=0.3),  # the glass above, emptied
         cylinder((0, 21.0, 0), (0, 23.4, 0), 6.0, "gunmetal", round_=0.6),
         capsule((0, 23.4, 0), (-3.0, 27.0, -2.0), 0.7, "graphite")]
    for a in (0.3, 2.4, 4.5):                                          # the frame's bars
        S.append(capsule((5.6 * math.cos(a), 3.0, 5.6 * math.sin(a)), (5.6 * math.cos(a), 21.0, 5.6 * math.sin(a)), 0.5, "gunmetal"))
    S.append(box((2.6, 18.0, 4.4), (0.35, 3.2, 0.4), "dark", R=rot_z(0.5)))
    for k in range(5):                                                 # the jungle, climbing it
        a = k * 1.3 + 0.4
        S.append(ellipsoid((5.4 * math.cos(a), 3.0 + k * 3.6, 5.4 * math.sin(a)), (1.8, 1.0, 1.8), "jade"))
    S.append(ellipsoid((5.0, 0.6, 5.0), (4.0, 0.6, 2.4), "acid"))      # the spill
    return S


# ---------------------------------------------------------------- 6 · Meridian Entropics
@mprop("d6_hulk", "6", size=32, foot=(16, 26), yaw=35, pitch=42, scale=0.9)
def machine_hulk():
    body = box((0, 7.0, 0), (8.0, 6.0, 5.0), "steel", r=0.8)
    body = cut(body, (0.6, 0.8, 0.2), 8.0)                       # a corner gone to ash
    S = [moved(body, R=rot_z(0.18)),
         box((-1.0, 13.0, 0), (4.0, 2.4, 3.6), "rust", r=0.6),
         ellipsoid((7.0, 1.0, 3.0), (5.0, 1.6, 3.6), "ash"),
         ellipsoid((-8.0, 0.8, -2.0), (3.6, 1.2, 3.0), "ash"),
         box((9.0, 2.0, -4.0), (1.8, 1.2, 1.4), "steel", r=0.3, R=rot_y(0.7)),
         box((10.5, 5.0, 2.0), (1.0, 0.8, 0.9), "steel", r=0.2, R=rot_z(0.5)),
         sphere((-3.0, 9.0, 5.2), 0.8, "glow_cyan")]
    return S


# ---------------------------------------------------------------- the rest of each District's things
@mprop("d1_clock", "1", size=32, foot=(16, 28), yaw=25, pitch=35, scale=0.95)
def stopped_clock():
    """A station clock on its post, stopped, frost on its face."""
    S = [cylinder((0, 0, 0), (0, 1.6, 0), 3.4, "graphite", round_=0.5),
         capsule((0, 1.6, 0), (0, 15.0, 0), 0.9, "steel"),
         cylinder((0, 20.0, -1.0), (0, 20.0, 1.0), 6.0, "steel", round_=0.6),
         cylinder((0, 20.0, 0.9), (0, 20.0, 1.3), 5.0, "white", round_=0.3)]
    S[2] = moved(cylinder((0, 0, -1.0), (0, 0, 1.0), 6.4, "steel", round_=0.6), by=(0, 20.0, 0))
    S[3] = moved(cylinder((0, 0, 1.0), (0, 0, 1.5), 5.2, "glow_white"), by=(0, 20.0, 0))
    S.append(box((0, 21.8, 1.7), (0.45, 2.0, 0.2), "dark"))                  # the hands, stopped at ten to twelve
    S.append(moved(box((0, 1.5, 0), (0.4, 1.5, 0.2), "dark"), by=(0, 20.0, 1.7), R=rot_z(1.0)))
    for a in (0.3, 1.9, 3.6, 5.0):                                            # frost round its rim
        S.append(sphere((6.0 * math.cos(a), 20.0 + 6.0 * math.sin(a), 0.8), 1.1, "frosted"))
    return S


@mprop("d1_crystal", "1", size=32, foot=(16, 27), yaw=20, pitch=40, scale=0.95)
def frost_crystals():
    """A growth of hexagonal frost, crystals as tall as a man's arm."""
    S = [ellipsoid((0, 0.6, 0), (8.0, 1.2, 5.0), "frosted")]
    for x, z, h, r, tilt in ((0.0, 0.0, 15.0, 2.2, 0.0), (-4.5, 1.0, 9.0, 1.6, -0.35), (4.0, -1.0, 11.0, 1.8, 0.3), (2.0, 2.5, 6.0, 1.3, 0.5), (-2.5, -2.0, 7.0, 1.4, -0.2)):
        c = cone((0, 0, 0), (0, h, 0), r, 0.2, "frosted")
        S.append(moved(c, by=(x, 0.5, z), R=rot_z(tilt)))
    S.append(sphere((0, 6.0, 1.6), 1.0, "glow_violet"))
    return S


@mprop("d2_barricade", "2", size=32, foot=(16, 27), yaw=20, pitch=40, scale=0.95)
def hideout_barricade():
    """A hideout's door, barricaded with desks and boards."""
    S = [box((0, 9.0, -2.0), (9.0, 9.0, 1.2), "white", r=0.6),                  # the wall and its door
         box((0, 7.0, -0.7), (4.2, 7.0, 0.3), "charcoal", r=0.2)]
    S.append(moved(box((0, 0, 0), (6.0, 1.0, 2.6), "leather", r=0.3), by=(-1.0, 3.4, 1.4), R=rot_z(0.25)))
    S.append(moved(box((0, 0, 0), (5.0, 0.8, 2.2), "leather", r=0.3), by=(2.0, 6.8, 1.0), R=rot_z(-0.35)))
    for x, a in ((-3.0, 0.6), (2.6, -0.5), (0.0, 0.1)):                       # boards nailed across
        S.append(moved(box((0, 0, 0), (0.7, 6.0, 0.3), "sack", r=0.1), by=(x, 9.0, 0.2), R=rot_z(a)))
    S.append(box((5.0, 13.0, -0.6), (2.0, 1.0, 0.2), "glow_pink", r=0.1))      # sums, scrawled in light
    return S


@mprop("d2_chair", "2", size=32, foot=(16, 26), yaw=35, pitch=40, scale=0.95)
def psi_chair():
    """An empty Psi-Lab chair, its halo of a headset still lit."""
    S = [cylinder((0, 0, 0), (0, 1.2, 0), 4.2, "graphite", round_=0.4),
         capsule((0, 1.2, 0), (0, 6.0, 0), 0.8, "steel"),
         box((0, 7.0, 0.5), (4.4, 1.0, 4.2), "white", r=0.8),
         moved(box((0, 0, 0), (4.4, 6.0, 1.0), "white", r=0.8), by=(0, 12.0, -3.6), R=rot_x(-0.2)),
         torus((0, 19.4, -3.2), 3.0, 0.5, "glow_pink"),
         capsule((0, 17.8, -4.4), (0, 19.0, -4.0), 0.4, "steel")]
    for sx in (-1, 1):
        S.append(box((sx * 4.8, 9.2, 0.8), (0.8, 0.6, 3.6), "graphite", r=0.3))
    return S


@mprop("d3_conveyor", "3", size=32, foot=(16, 26), yaw=30, pitch=42, scale=0.9)
def conveyor():
    """A run of conveyor, parts still on it."""
    S = [box((0, 3.2, 0), (13.0, 1.2, 3.6), "graphite", r=0.4),
         box((0, 4.5, 0), (12.6, 0.2, 3.0), "rubber", r=0.1)]
    for x in (-11.0, -3.6, 3.6, 11.0):
        S.append(box((x, 1.2, 0), (0.8, 1.6, 3.2), "vantage", r=0.2))
    S.append(box((-6.0, 6.4, 0), (2.6, 1.8, 2.2), "olive", r=0.4))
    S.append(box((2.0, 6.0, 0), (2.0, 1.4, 1.8), "brass", r=0.4))
    S.append(sphere((8.0, 6.0, 0), 1.8, "steel"))
    S.append(box((0, 4.8, 3.3), (12.6, 0.2, 0.3), "warning", r=0.1))
    return S


@mprop("d3_scrapbot", "3", size=32, foot=(16, 27), yaw=-25, pitch=38, scale=0.95)
def scrapped_bot():
    """A worker bot, scrapped where it stood, slumped on its frame."""
    S = [ellipsoid((0, 6.5, 0), (6.0, 5.0, 4.6), "vantage"),
         moved(box((0, 0, 0), (3.6, 2.6, 3.0), "steel", r=0.8), by=(1.0, 12.0, 2.0), R=rot_z(0.5)),
         box((1.6, 12.4, 4.8), (1.6, 0.6, 0.3), "dark", r=0.1),
         capsule((-5.0, 6.0, 0), (-9.0, 1.0, 3.0), 1.0, "steel"),
         capsule((5.0, 7.0, 1.0), (8.0, 2.0, 5.0), 1.0, "steel"),
         capsule((-3.0, 2.0, 0), (-5.0, 0.4, -3.0), 1.2, "graphite"),
         capsule((3.0, 2.0, 0), (5.0, 0.4, -3.0), 1.2, "graphite"),
         sphere((-1.0, 9.0, 4.4), 1.0, "rust"), sphere((3.0, 4.0, 4.0), 1.2, "rust")]
    return S


@mprop("d4_circle", "4", size=32, foot=(16, 24), yaw=0, pitch=55, scale=1.0)
def black_circle():
    """A ritual circle of the Black kind, candles round it, still burning."""
    S = [cylinder((0, 0, 0), (0, 0.3, 0), 11.0, "rack"),
         cut(torus((0, 0.3, 0), 8.6, 0.6, "blood"), (0, -1, 0), -0.25),
         sphere((0, 0.6, 0), 1.6, "blood")]
    for k in range(5):
        a = math.radians(-90 + 72 * k)
        x, z = 10.0 * math.cos(a), 10.0 * math.sin(a)
        S.append(cylinder((x, 0, z), (x, 2.6, z), 0.8, "bone", round_=0.2))
        S.append(sphere((x, 3.3, z), 0.6, "glow_amber"))
    return S


@mprop("d4_spools", "4", size=32, foot=(16, 26), yaw=30, pitch=40, scale=0.95)
def cable_spools():
    """Cable on drums, and the cable run from them into the floor."""
    S = []
    for x, z in ((-5.0, 0.0), (4.0, -2.0)):
        for dz in (-2.2, 2.2):
            S.append(moved(cylinder((0, 0, -0.4), (0, 0, 0.4), 5.4, "steel", round_=0.3), by=(x, 5.4, z + dz)))
        S.append(moved(cylinder((0, 0, -1.9), (0, 0, 1.9), 4.4, "crimson", round_=0.6), by=(x, 5.4, z)))
    S.append(capsule((-5.0, 1.0, 3.0), (6.0, 0.6, 6.0), 0.8, "crimson"))
    S.append(capsule((6.0, 0.6, 6.0), (11.0, 0.4, 3.0), 0.8, "crimson"))
    S.append(sphere((8.0, 1.6, 5.0), 0.5, "glow_red"))
    return S


@mprop("d5_bloom", "5", size=32, foot=(16, 28), yaw=15, pitch=35, scale=0.95)
def bloom():
    """A flower the size of a door, turned toward the nearest Aether conduit."""
    S = [capsule((0, 0, 0), (1.0, 10.0, 0.5), 1.0, "jade"),
         capsule((1.0, 10.0, 0.5), (2.0, 16.0, 2.0), 0.9, "jade"),
         ellipsoid((-4.0, 4.0, 1.0), (3.0, 0.8, 1.6), "jade"),
         ellipsoid((4.0, 7.0, 0.0), (3.0, 0.8, 1.6), "jade")]
    for k in range(6):
        a = k * math.pi / 3
        S.append(moved(ellipsoid((0, 0, 0), (3.6, 1.4, 2.0), "rose"), by=(2.0 + 3.4 * math.cos(a), 18.0 + 3.4 * math.sin(a), 2.6), R=rot_z(a)))
    S.append(sphere((2.0, 18.0, 3.4), 1.8, "glow_amber"))
    return S


@mprop("d5_roots", "5", size=32, foot=(16, 26), yaw=20, pitch=42, scale=0.95)
def root_arch():
    """Roots up out of the deck and back into it, moss along them."""
    S = []
    for k, (x0, x1, h, rr) in enumerate(((-12.0, 6.0, 11.0, 1.9), (-6.0, 12.0, 8.0, 1.6), (-10.0, 2.0, 5.0, 1.3))):
        pts = [(x0 + (x1 - x0) * t, math.sin(t * math.pi) * h, (k - 1) * 3.0) for t in np.linspace(0, 1, 8)]
        for i in range(len(pts) - 1):
            S.append(capsule(pts[i], pts[i + 1], rr, "leather"))
    S.append(ellipsoid((-3.0, 11.0, -3.0), (3.0, 1.0, 2.0), "jade"))
    S.append(ellipsoid((3.0, 8.0, 0.0), (2.4, 0.9, 1.8), "jade"))
    S.append(sphere((-1.0, 12.0, -2.0), 0.9, "rose"))
    return S


@mprop("d6_heap", "6", size=32, foot=(16, 26), yaw=25, pitch=42, scale=0.95)
def ash_heap():
    """A heap of what the deck has crumbled into, a girder twisted out of it."""
    S = [ellipsoid((0, 1.0, 0), (10.0, 3.6, 7.0), "ash"),
         ellipsoid((4.0, 2.0, 2.0), (4.0, 3.0, 3.0), "ash"),
         moved(box((0, 0, 0), (1.0, 9.0, 1.4), "rust", r=0.3), by=(-3.0, 8.0, 0), R=rot_z(-0.4)),
         moved(box((0, 0, 0), (1.0, 4.0, 1.4), "rust", r=0.3), by=(-7.6, 15.0, 0), R=rot_z(-1.2)),
         box((6.0, 3.0, -3.0), (1.6, 1.0, 1.2), "steel", r=0.3),
         sphere((2.0, 4.6, 4.0), 0.6, "glow_cyan")]
    return S


@mprop("d6_pylon", "6", size=32, foot=(16, 28), yaw=20, pitch=36, scale=0.95)
def leaning_pylon():
    """A power pylon, cracked through, leaning as it comes apart."""
    body = cone((0, 0, 0), (0, 22.0, 0), 3.4, 1.6, "steel")
    S = [cylinder((0, 0, 0), (0, 1.4, 0), 5.0, "graphite", round_=0.4),
         moved(body, by=(0, 1.0, 0), R=rot_z(0.28)),
         moved(box((0, 0, 0), (4.0, 0.6, 0.6), "steel", r=0.2), by=(-3.4, 16.0, 0), R=rot_z(0.28)),
         box((4.0, 1.0, 3.0), (1.4, 1.0, 1.2), "steel", r=0.3),
         ellipsoid((-3.0, 0.6, 3.0), (4.0, 1.0, 2.6), "ash"),
         sphere((-4.8, 20.6, 0), 0.9, "glow_cyan")]
    return S


# ---------------------------------------------------------------- the dock: the Hangar, Docking Bay 2
@mprop("hangar", "", size=64, foot=(32, 52), yaw=-20, pitch=38, scale=1.0, inner=0.8)
def hangar():
    """An arched hangar, its great door open toward you and the bay lit inside."""
    S = [box((0, 0.8, 0), (22.0, 0.8, 22.0), "concrete", r=0.8),              # the apron
         box((0, 1.7, 17.0), (16.0, 0.2, 2.2), "warning", r=0.1)]
    shell = cylinder((0, 0, -16.0), (0, 0, 9.0), 14.0, "steel", round_=1.2)
    S.append(cut(shell, (0, -1, 0), 0.0))                                     # the arch above the deck
    for z in (-12.0, -4.0, 4.0):                                              # the roof's ribs
        S.append(cut(torus((0, 0, z), 14.1, 0.7, "graphite", R=rot_x(math.pi / 2)), (0, -1, 0), 0.0))
    door = cylinder((0, 0, 8.4), (0, 0, 9.4), 10.5, "glow_blue")
    S.append(cut(door, (0, -1, 0), 0.0))
    S.append(box((0, 4.0, 9.5), (6.0, 3.0, 0.2), "dark", r=0.4))               # a ship's nose, docked in the light
    S.append(box((0, 1.2, 9.0), (8.0, 0.4, 0.3), "glow_cyan", r=0.1))
    S.append(cut(torus((0, 0, 9.3), 10.8, 0.45, "glow_white", R=rot_x(math.pi / 2)), (0, -1, 0), 1.0))
    S.append(box((-11.0, 9.0, 9.6), (1.6, 2.4, 0.3), "vantage", r=0.2))       # its number, 2
    S.append(capsule((15.0, 0, 2.0), (15.0, 26.0, 2.0), 0.6, "graphite"))     # the beacon mast
    S.append(sphere((15.0, 26.6, 2.0), 1.4, "glow_cyan"))
    for x in (-18.0, -9.0, 0.0, 9.0, 18.0):                                   # lights round the apron
        S.append(sphere((x, 1.8, 21.5), 0.8, "glow_amber"))
    return S


NAMES = list(MP)

if __name__ == "__main__":
    imgs = [render_mprop(n) for n in NAMES]
    sheet(imgs, preview_path("map_props.png"), scale=4, labels=NAMES, cols=4, show1x=True)
    print("ok")
