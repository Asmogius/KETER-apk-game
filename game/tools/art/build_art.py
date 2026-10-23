"""Render every picture the game draws with (0.14, 0.15, 0.16) and write them
into the game: art/tokens.png, board.png, icons.png, cards.png, (0.15) the
World Map's ground.png and map.png, each District's district.png and the
menus' menu.png, and (0.16) the fight's effects, frame by frame, in fx.png;
and art.json (where each picture sits in its sheet, and what it is).

   python3 tools/art/build_art.py [game folder] [compendium_full.json] [--sheet]

The game folder is the one these scripts sit in (tools/art inside it) unless
another is named. The cards (for each master Unit's number and kind) come from
the Companion's compendium_full.json beside the game folder, as the sources lay
them out, or from the test export the game's tests read (tests/fixtures/
export.zip). Needs Python 3 with numpy and Pillow. --sheet also writes a contact
sheet of the tokens to look at, in out/ beside these scripts."""
import io, json, os, re, sys, zipfile
import numpy as np
from PIL import Image
from kart import rgb, to_png, sheet, preview_path
import units, props, tiles, icons, cards, cardart, cardback
import hexpix, mapart, mapprops, mapicons, districts, menus, uiicons, effects
from kart import studio_encode

HERE = os.path.dirname(os.path.abspath(__file__))
ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
GAME = ARGS[0] if ARGS else os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(GAME, "art")
os.makedirs(OUT, exist_ok=True)


def the_cards():
    """The cards: from a compendium named, or the Companion's beside the game, or the game's test export."""
    for path in ([ARGS[1]] if len(ARGS) > 1 else []) + [os.path.join(os.path.dirname(os.path.abspath(GAME)), "compendium_full.json"),
                                                       os.path.join(os.path.dirname(os.path.dirname(HERE)), "..", "compendium_full.json")]:
        if os.path.exists(path):
            return json.load(open(path, encoding="utf-8"))["cards"]
    fx = os.path.join(GAME, "tests", "fixtures", "export.zip")
    if os.path.exists(fx):
        with zipfile.ZipFile(fx) as z:
            return json.loads(z.read("content/cards.json"))["cards"]
    raise SystemExit("No cards to read: name compendium_full.json, or run this from the game with its tests/fixtures/export.zip")


COMP = the_cards()


def slug(s):
    s = re.sub(r"[^a-z0-9]+", "_", str(s).lower()).strip("_")
    return s or "untitled"


def rgba(a):
    H, W = a.shape
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    for y in range(H):
        for x in range(W):
            v = int(a[y, x])
            if v:
                px[x, y] = rgb(v) + (255,)
    return im


def pack(items, cell, cols):
    """items: [(key, array)] -> (sheet image, {key: [x, y, w, h]})."""
    rows = (len(items) + cols - 1) // cols
    W, H = cell[0] * cols, cell[1] * rows
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rects = {}
    for n, (k, a) in enumerate(items):
        x, y = (n % cols) * cell[0], (n // cols) * cell[1]
        im.alpha_composite(rgba(a), (x, y))
        rects[k] = [x, y, int(a.shape[1]), int(a.shape[0])]
    return im, rects


def card_of(name):
    for c in COMP:
        # (0.22: an export's pre-built Troops are designs, not master cards: the same sheets either way)
        if c.get("name") == name and c.get("_src") not in ("prebuilt", "design", "workshop"):
            return c
    return None


def card_of_type(name):
    """The card of that name that is not a Unit (a Unit can share a name: Aether Battery)."""
    for c in COMP:
        if c.get("name") == name and str(c.get("cardType", "")).lower() not in ("troop", "enemy", "hero", "elite", "miniboss", "unit"):
            return c
    return None


def pack_any(items, width=512, pad=1):
    """items: [(key, image)] of any sizes -> (sheet, {key: [x, y, w, h]}), on shelves."""
    order = sorted(items, key=lambda kv: (-kv[1].size[1], kv[0]))
    x = y = shelf = 0
    rects = {}
    for k, im in order:
        w, h = im.size
        if x + w > width:
            x, y, shelf = 0, y + shelf + pad, 0
        rects[k] = [x, y, w, h]
        x += w + pad
        shelf = max(shelf, h)
    sheet_im = Image.new("RGBA", (width, y + shelf), (0, 0, 0, 0))
    for k, im in items:
        r = rects[k]
        sheet_im.alpha_composite(im, (r[0], r[1]))
    return sheet_im, rects


manifest = {"version": "0.24", "note": "Drawn for KETER 0.14 to 0.24. Square pixels on the Pixel Studio palette; the World Map's ground in hex pixels; "
            "each of the fight's effects a row of frames, side by side; each card that is not a Unit its own picture, 128 by 90.",
            "tokens": {}, "board": {}, "icons": {}, "marks": {}, "cards": {}, "ground": {}, "map": {}, "district": {}, "menu": {}, "fx": {}, "cardart": {}, "cardback": {}}

# ---- tokens: every master Unit, the body plans, the stand-ins
tok_items = []
for name, u in units.U.items():
    img = units.render_unit(name)
    key = slug(name)
    c = card_of(name)
    kind = u["kind"]
    tok_items.append((key, img))
    manifest["tokens"][key] = {"name": name, "id": (c or {}).get("id"), "cardType": (c or {}).get("cardType"),
                               "kind": kind, "big": bool(u["big"])}
for k in cards.STANDINS:
    key = "standin_" + k
    tok_items.append((key, cards.standin(k)))
    manifest["tokens"][key] = {"name": k.capitalize() + " stand-in", "id": None, "cardType": None, "kind": "standin", "big": False}
im, rects = pack(tok_items, (48, 48), 10)
im.save(os.path.join(OUT, "tokens.png"))
for k, r in rects.items():
    manifest["tokens"][k]["rect"] = r
if units.WARN:
    print("WARN", units.WARN)

# ---- the board: props and tiles (cells of 48 x 48)
board_items = []
for name in props.NAMES:
    p = props.P[name]
    a = props.render_prop(name)
    board_items.append((name, a))
    manifest["board"][name] = {"kind": "prop", "foot": list(p["foot"])}
for name, fn in tiles.ALL.items():
    a = fn()
    board_items.append((name, a))
    manifest["board"][name] = {"kind": "floor" if name.startswith("floor") else "pad" if name.startswith("pad") else "hazard", "foot": [21, 24]}
im, rects = pack(board_items, (48, 48), 10)
im.save(os.path.join(OUT, "board.png"))
for k, r in rects.items():
    manifest["board"][k]["rect"] = r

# ---- icons (16 x 16) and the board's marks (8 x 8)
icon_items = [(k, v) for k, v in icons.ICONS.items() if k != "act_hold"]
icon_items += [("mark_" + k.replace(" ", "_"), v) for k, v in icons.MARKS.items()]
im, rects = pack(icon_items, (16, 16), 12)
im.save(os.path.join(OUT, "icons.png"))
for k, r in rects.items():
    if k.startswith("mark_"):
        manifest["marks"][k[5:].replace("_", " ")] = {"rect": r}
    else:
        manifest["icons"][k.replace("status_", "")] = {"rect": r}

# ---- the card types' stand-in pictures (64 x 45)
card_items = [(k, cards.render_card(k)) for k in cards.C]
im, rects = pack(card_items, (64, 45), 4)
im.save(os.path.join(OUT, "cards.png"))
for k, r in rects.items():
    manifest["cards"][k] = {"rect": r}

# ---- (0.17) each card that is not a Unit: its own picture (128 x 90), the thing lit on its District's backdrop;
# keyed by the card's name as a slug, with its id (when it has one), name and kind
ca_items = []
for name in cardart.CARDS:
    c = card_of_type(name)
    key = slug(name)
    ca_items.append((key, cardart.render_card(name)))
    manifest["cardart"][key] = {"name": name, "id": str((c or {}).get("id", "")), "type": str((c or {}).get("cardType", "")).lower()}
im, rects = pack(ca_items, (cardart.W, cardart.H), 8)
im.save(os.path.join(OUT, "cardart.png"))
for k, r in rects.items():
    manifest["cardart"][k]["rect"] = r

# ---- (0.19) the card back (75 x 105): the KETER emblem, the colony's surface over its labs, in a cyan frame
rgba(cardback.back()).save(os.path.join(OUT, "cardback.png"))
manifest["cardback"]["back"] = {"rect": [0, 0, cardback.W, cardback.H]}

# ---- (0.15) the World Map's ground: each District's four tiles, no District's, and rubble, in hex pixels,
# drawn at 3 pixels to a hex pixel's corner (the map's usual zoom); with each its hex pixels as the
# Pixel Studio keeps them (the Companion's copy is made from these)
g_items = []
for d in ["1", "2", "3", "4", "5", "6", ""]:
    for v in range(mapart.VARIANTS):
        a = mapart.ground(d, v)
        key = "ground_%s_%d" % (d or "none", v)
        im, mid = hexpix.render(a, 3.0)
        g_items.append((key, im))
        manifest["ground"][key] = {"d": d, "v": v, "kind": "ground", "mid": [round(mid[0], 3), round(mid[1], 3)], "cells": studio_encode(a)}
for v in range(3):
    a = mapart.rubble(v)
    key = "rubble_%d" % v
    im, mid = hexpix.render(a, 3.0)
    g_items.append((key, im))
    manifest["ground"][key] = {"d": None, "v": v, "kind": "rubble", "mid": [round(mid[0], 3), round(mid[1], 3)], "cells": studio_encode(a)}
im, rects = pack_any(g_items, width=560)
im.save(os.path.join(OUT, "ground.png"))
for k, r in rects.items():
    manifest["ground"][k]["rect"] = r
manifest["ground_layout"] = {"side": hexpix.SIDE, "orient": "flat", "cols": hexpix.COLS, "rows": hexpix.ROWS, "s": 3.0, "clip": round(hexpix.CLIP, 4)}

# ---- (0.15) what stands on the map: each District's things, the Hangar, and the icons for what a tile holds
m_items = []
for name in mapprops.NAMES:
    p = mapprops.MP[name]
    m_items.append((name, rgba(mapprops.render_mprop(name))))
    manifest["map"][name] = {"kind": "dock" if name == "hangar" else "prop", "d": p["d"], "foot": list(p["foot"])}
for k, a in mapicons.MAP_ICONS.items():
    m_items.append(("icon_" + k, rgba(a)))
    manifest["map"]["icon_" + k] = {"kind": "icon", "plate": mapicons.PLATE[k]}
im, rects = pack_any(m_items, width=256)
im.save(os.path.join(OUT, "map.png"))
for k, r in rects.items():
    manifest["map"][k]["rect"] = r

# ---- (0.15) each District's fights: its five floor plates, its Half and Full Cover
dp = districts.all_pieces()
d_items = []
for (d, n), a in sorted(dp["floors"].items()):
    key = "d%s_floor_%d" % (d, n)
    d_items.append((key, rgba(a)))
    manifest["district"][key] = {"d": d, "kind": "floor", "n": n, "foot": [21, 24]}
for (d, kind), a in sorted(dp["covers"].items()):
    key = "d%s_%s_cover" % (d, kind)
    d_items.append((key, rgba(a)))
    manifest["district"][key] = {"d": d, "kind": kind + "_cover", "foot": list(districts.COVER[(d, kind)]["foot"])}
im, rects = pack_any(d_items, width=480)
im.save(os.path.join(OUT, "district.png"))
for k, r in rects.items():
    manifest["district"][k]["rect"] = r

# ---- (0.15) the menus: Home's picture with the sign, the dock's and the other menus', QM-7 (and blinking),
# Victory and Defeat, and the menus' icons
u_items = [("home", rgba(menus.home_picture())), ("dock", rgba(menus.dock_picture())), ("menu", rgba(menus.menu_picture())),
           ("qm7", rgba(menus.render_qm7())), ("qm7_blink", rgba(menus.render_qm7(True))),
           ("victory", rgba(menus.victory())), ("defeat", rgba(menus.defeat()))]
u_items += [("icon_" + k, rgba(a)) for k, a in uiicons.UI_ICONS.items()]
im, rects = pack_any(u_items, width=520)
im.save(os.path.join(OUT, "menu.png"))
for k, r in rects.items():
    manifest["menu"][k] = {"rect": r}

# ---- (0.16) the fight's effects: each a row of its frames, side by side, one row under another;
# with how many frames, how fast they play at Normal speed, and the pixel that sits over the point it plays at
fx_rows = []
y = 0
for name in effects.NAMES + effects.ATMOS:
    fr = effects.frames(name)
    h, w = fr[0].shape
    strip = Image.new("RGBA", (w * len(fr), h), (0, 0, 0, 0))
    for i, a in enumerate(fr):
        strip.alpha_composite(rgba(a), (i * w, 0))
    fx_rows.append((name, strip, y))
    manifest["fx"][name] = {"rect": [0, y, w * len(fr), h], "frames": len(fr), "w": w, "h": h, "fps": effects.FPS[name], "anchor": list(effects.ANCHOR[name])}
    if name in effects.ATMOS:
        manifest["fx"][name]["atmos"] = True     # (0.18) a mote of the fight's atmosphere, looping as it drifts
    y += h + 1
fx_sheet = Image.new("RGBA", (max(s.size[0] for _, s, _ in fx_rows), y - 1), (0, 0, 0, 0))
for name, strip, yy in fx_rows:
    fx_sheet.alpha_composite(strip, (0, yy))
fx_sheet.save(os.path.join(OUT, "fx.png"))

with open(os.path.join(OUT, "art.json"), "w") as f:
    json.dump(manifest, f, indent=1, sort_keys=True)
print("tokens", len(manifest["tokens"]), "board", len(manifest["board"]), "icons", len(manifest["icons"]), "marks", len(manifest["marks"]), "cards", len(manifest["cards"]),
      "ground", len(manifest["ground"]), "map", len(manifest["map"]), "district", len(manifest["district"]), "menu", len(manifest["menu"]), "fx", len(manifest["fx"]),
      "cardart", len(manifest["cardart"]), "cardback", len(manifest["cardback"]))

# a contact sheet of the tokens, to look at
if "--sheet" in sys.argv:
    sheet([a for _, a in tok_items], preview_path("all_tokens.png"), scale=2, labels=[k[:16] for k, _ in tok_items], cols=10, show1x=False)
