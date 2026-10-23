#!/usr/bin/env python3
"""The game's own drawn art, for the Companion (v14.1; v14.2; v14.3).

Reads the art the game draws with (game/art: tokens.png, board.png, icons.png,
cards.png, from game 0.15 ground.png, map.png, district.png and menu.png, and
from game 0.16 fx.png, the fight's effects frame by frame, with art.json, which
game/tools/art/build_art.py makes) and writes
keter_art.js: every piece as a Pixel Studio picture, which master Unit each
token belongs to, and which slot of Export for Godot each other piece fills.
The World Map's ground and rubble go in as hex pictures (a hexagon of flat-top
hex pixels, nine to a side), as the Studio draws them; a slot of several
pictures (ground, rubble, a District's things) is given all of the game's.
Each of the fight's effects goes in as one picture of several frames, with
how many a second it plays at.

The app adds the pictures to the picture library (refreshing any nobody has
drawn on, keeping any you have), links a token to each master Unit that has
none, and puts a picture in each of the game's slots while it is still empty.
Export for Godot leaves out the ones nobody has drawn on: the game has its own
copy of each. One you have drawn on goes, and the game uses yours.

   python3 make_art_pack.py            (writes keter_art.js next to it)
"""
import base64, json, os, re, sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "game", "art")
OUT = os.path.join(HERE, "keter_art.js")


def palette():
    """The Pixel Studio's palette, in its own order: [None, '#050403', ...]."""
    src = open(os.path.join(HERE, "pixelart.js"), encoding="utf-8").read()
    splendor = re.search(r'var SPLENDOR=\("([0-9a-f ]+)"\)', src).group(1).split()
    neon = re.findall(r'\["([0-9a-f]{6})","[^"]+"\]', re.search(r"var NEON=\[(.*?)\];", src, re.S).group(1))
    ext = re.findall(r'\["([0-9a-f]{6})","[^"]+"\]', re.search(r"var EXT=\[(.*?)\];", src, re.S).group(1))
    assert len(splendor) == 128 and len(neon) == 11 and len(ext) == 56, (len(splendor), len(neon), len(ext))
    return [None] + ["#" + h for h in splendor + neon + ext]


PAL = palette()
INDEX = {h: i for i, h in enumerate(PAL) if h}


def encode(values):
    """Runs of (count, colour), as base64: the Pixel Studio's own storage."""
    out = bytearray()
    i, n = 0, len(values)
    while i < n:
        v, run = values[i], 1
        while i + run < n and values[i + run] == v and run < 255:
            run += 1
        out += bytes((run, v))
        i += run
    return base64.b64encode(bytes(out)).decode("ascii")


def hex_picture(cells, name, slot):
    """A Pixel Studio hex picture: a hexagon of flat-top hex pixels, nine to a
    side (18 by 17 cells), from art.json's cells (the Studio's own storage)."""
    return {"v": 1, "w": 18, "h": 17, "name": name, "grid": "hex", "shape": "hexagon", "side": 9, "orient": "flat",
            "frames": [{"layers": [{"name": "Layer 1", "visible": True, "locked": False, "opacity": 100, "mode": "view", "px": cells}]}],
            "flat": "", "kind": "blank", "slot": slot}


def picture(img, name, kind, slot=None):
    """A Pixel Studio picture of an RGBA image whose every pixel is on the palette."""
    w, h = img.size
    px = img.load()
    vals = []
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                vals.append(0)
                continue
            hx = "#%02x%02x%02x" % (r, g, b)
            if a != 255 or hx not in INDEX:
                raise SystemExit("%s: pixel %d,%d is %s, not a colour of the palette" % (name, x, y, hx))
            vals.append(INDEX[hx])
    enc = encode(vals)
    # (flat, the picture flattened, is left empty: the library works it out as the picture goes in)
    p = {"v": 1, "w": w, "h": h, "name": name,
         "frames": [{"layers": [{"name": "Layer 1", "visible": True, "locked": False, "opacity": 100, "mode": "view", "px": enc}]}],
         "flat": "", "kind": kind, "grid": "square"}
    if slot:
        p["slot"] = slot
    return p


UNIT_KINDS = ("hero", "troop", "enemy", "elite", "miniboss", "boss")
NOT_STATUS = ("bar_", "role_", "district_", "act_")
# drawn, and not shown anywhere yet: no slot until they are ((0.16) the Action icons are now)
NOT_YET = ()
# (0.16) the fight's effects: the names their slots go by
FX_NAME = {"flash": "Muzzle flash", "impact": "Impact", "explosion": "Explosion", "heal": "Heal", "shield": "Shield",
           "ember": "Ember", "spark": "Spark", "ash": "Ash", "dust": "Dust"}
DN = {"1": "Threshold Dynamics", "2": "Halcyon Cognition", "3": "Vantage Robotics", "4": "Lazarus Computing", "5": "Verdant Biogenics", "6": "Meridian Entropics"}
# (0.15) the menus' pictures and the slots they fill
MENU_SLOT = {"home": "ui.title", "dock": "ui.backdrop.dock", "menu": "ui.backdrop.menu", "qm7": "ui.qm7", "qm7_blink": "ui.qm7_blink",
             "victory": "ui.title.victory", "defeat": "ui.title.defeat"}
MENU_NAME = {"home": "Home: the colony's sign", "dock": "The Hangar, inside", "menu": "The colony at night", "qm7": "QM-7", "qm7_blink": "QM-7, blinking",
             "victory": "Victory", "defeat": "Defeat"}


def nice(s):
    return s.replace("_", " ").capitalize()


def main():
    man = json.load(open(os.path.join(ART, "art.json"), encoding="utf-8"))
    sheets = {k: Image.open(os.path.join(ART, k + ".png")).convert("RGBA") for k in ("tokens", "board", "icons", "cards", "map", "district", "menu")
              + tuple(k for k in ("fx", "cardart", "cardback") if os.path.exists(os.path.join(ART, k + ".png")))}
    sheet_of = {"tokens": "tokens", "board": "board", "icons": "icons", "marks": "icons", "cards": "cards", "map": "map", "district": "district", "menu": "menu", "cardart": "cardart", "cardback": "cardback"}

    def cut(kind, key):
        x, y, w, h = man[kind][key]["rect"]
        return sheets[sheet_of[kind]].crop((x, y, x + w, y + h))

    pics, tokens, slots, arts = {}, [], [], []
    for key, e in sorted(man["tokens"].items()):
        kind = e.get("kind")
        if kind == "body":
            pid = "px_skin_%s_token" % key
            pics[pid] = picture(cut("tokens", key), "Stand-in · %s token" % e["name"], "token")
        elif kind == "standin":
            what = key[len("standin_"):]
            pid = "px_keter_standin_" + what
            slot = "fight.standin." + what
            pics[pid] = picture(cut("tokens", key), "%s stand-in token" % what.capitalize(), "blank", slot)
            slots.append([slot, pid])
        else:
            pid = "px_keter_token_" + key
            pics[pid] = picture(cut("tokens", key), "%s token" % e["name"], "token")
            if kind in UNIT_KINDS:
                tokens.append([e.get("id") or "", e["name"], pid])
    for key in sorted(man["board"]):
        pid = "px_keter_board_" + key
        slot = "fight." + key
        pics[pid] = picture(cut("board", key), nice(key), "blank", slot)
        slots.append([slot, pid])
    for key in sorted(man["icons"]):
        if NOT_YET and key.startswith(NOT_YET):
            continue
        k_ = key.replace(" ", "_")
        pid = "px_keter_icon_" + k_
        slot = ("ui.icon." if key.startswith(NOT_STATUS) else "ui.status.") + k_
        pics[pid] = picture(cut("icons", key), nice(k_) + " icon", "blank", slot)
        slots.append([slot, pid])
    for key in sorted(man["marks"]):
        k_ = key.replace(" ", "_")
        pid = "px_keter_mark_" + k_
        slot = "ui.mark." + k_
        pics[pid] = picture(cut("marks", key), nice(k_) + " mark", "blank", slot)
        slots.append([slot, pid])
    for key in sorted(man["cards"]):
        pid = "px_keter_card_" + key
        slot = "ui.card." + key
        pics[pid] = picture(cut("cards", key), nice(key) + " card picture", "blank", slot)
        slots.append([slot, pid])

    # ---- (0.15) the World Map: ground and rubble in hex pixels, each District's things, the icons, the Hangar
    for key, e in sorted(man.get("ground", {}).items()):
        if e.get("kind") == "rubble":
            pid = "px_keter_rubble_%d" % e["v"]
            slot = "map.collapsed"
            name = "Collapsed tile %d" % (e["v"] + 1)
        else:
            d = e.get("d") or ""
            pid = "px_keter_ground_%s_%d" % (d or "none", e["v"])
            slot = "map.ground." + (d or "none")
            name = ("District %s ground %d" % (d, e["v"] + 1)) if d else "No District ground %d" % (e["v"] + 1)
        pics[pid] = hex_picture(e["cells"], name, slot)
        slots.append([slot, pid])
    props_seen = {}
    for key, e in sorted(man.get("map", {}).items()):
        kind = e.get("kind")
        pid = "px_keter_map_" + key
        if kind == "prop":
            d = str(e["d"])
            props_seen[d] = props_seen.get(d, 0) + 1
            slot = "map.prop." + d
            name = "District %s things %d" % (d, props_seen[d])
        elif kind == "dock":
            slot, name = "map.icon.dock", "The Hangar (the dock)"
        else:
            k = key[len("icon_"):]
            slot, name = "map.icon." + k, {"poi": "POI", "unique": "Unique POI", "ambush": "Ambush", "cache": "Cache", "event": "Event"}.get(k, nice(k)) + " icon"
        pics[pid] = picture(cut("map", key), name, "blank", slot)
        slots.append([slot, pid])
    # ---- (0.15) each District's fights: five floor plates, its Half and Full Cover
    for key, e in sorted(man.get("district", {}).items()):
        d = str(e["d"])
        rest = key[len("d%s_" % d):]
        pid = "px_keter_district_" + key
        slot = "fight.d%s.%s" % (d, rest)
        pics[pid] = picture(cut("district", key), "District %s %s" % (d, rest.replace("_", " ")), "blank", slot)
        slots.append([slot, pid])
    # ---- (0.15) the menus: Home, the Hangar inside, the colony; QM-7; Victory and Defeat; their icons
    for key, e in sorted(man.get("menu", {}).items()):
        pid = "px_keter_menu_" + key
        if key.startswith("icon_"):
            k = key[len("icon_"):]
            slot = "ui.icon." + k
            name = nice(k) + " icon"
        else:
            slot = MENU_SLOT.get(key)
            name = MENU_NAME.get(key, nice(key))
        pics[pid] = picture(cut("menu", key), name, "blank", slot)
        if slot:
            slots.append([slot, pid])

    # ---- (0.16) the fight's effects: each one picture of several frames, at its speed
    for key, e in sorted(man.get("fx", {}).items()):
        x, y, w, h = e["rect"]
        n, fw = int(e["frames"]), int(e["w"])
        frames = []
        for i in range(n):
            one = picture(sheets["fx"].crop((x + i * fw, y, x + (i + 1) * fw, y + h)), key, "blank")
            frames.append(one["frames"][0])
        pid = "px_keter_fx_" + key
        slot = "fight.fx." + key
        pic = picture(sheets["fx"].crop((x, y, x + fw, y + h)), FX_NAME.get(key, nice(key)), "blank", slot)
        pic["frames"] = frames
        pic["fps"] = int(e["fps"])
        pics[pid] = pic
        slots.append([slot, pid])

    # ---- (0.19) the card back, in its Game look slot
    if "back" in man.get("cardback", {}):
        pics["px_keter_card_back"] = picture(cut("cardback", "back"), "Card back", "blank", "ui.card.back")
        slots.append(["ui.card.back", "px_keter_card_back"])

    # ---- (0.17) each card that is not a Unit: its own picture, 128 by 90, linked to the card as its art
    for key, e in sorted(man.get("cardart", {}).items()):
        pid = "px_keter_art_" + key
        pics[pid] = picture(cut("cardart", key), "%s art" % e["name"], "art")
        arts.append([e.get("id") or "", e["name"], pid])

    data = {"version": str(man.get("version", "")), "pics": pics, "tokens": tokens, "slots": slots, "arts": arts}
    js = ("/* Generated by make_art_pack.py from the game's own drawn art (game/art, game "
          + data["version"] + "). The app adds these pictures\n"
          "   to the picture library, links each master Unit with no token to its own, each card that is\n"
          "   not a Unit and has no art to its picture, and puts a\n"
          "   picture in each of the game's slots while it is empty (every one of the game's, in a slot of\n"
          "   several). A picture you have drawn on is\n"
          "   never replaced, and Export for Godot carries only those: the game has its own copy of\n"
          "   the rest. */\n"
          "window.KETER_ART=" + json.dumps(data, sort_keys=True, separators=(",", ":"), ensure_ascii=False) + ";\n")
    open(OUT, "w", encoding="utf-8").write(js)
    print("keter_art.js: %d pictures (%d tokens for master Units, %d card art, %d body plans, %d slots), %d KB"
          % (len(pics), len(tokens), len(arts), sum(1 for p in pics if p.startswith("px_skin_")), len(slots), len(js) // 1024))


if __name__ == "__main__":
    main()
