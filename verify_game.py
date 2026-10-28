"""The Godot game (v0.23, Revision 16.3's eleven keywords and Actions aimed at
tiles; what 0.22 and before is proved again, and 0.8's to 0.23's own are listed at the end of this
note): a
fresh Export for Godot made
by the built Companion; the game's own tests run in Godot 4.7 without a
screen (hex maths, the export, floors, setting up, moving, aiming, attacking,
what cards say, the Enemies' turns, Strike Teams and what the rules say of
them, the builder, a Strike Team's Battle with its waves, Aether, Chips and
hand, cards played from the hand, Consumables, Chips spent, Recover, Undo,
the round's phases, the end, the screens and their touch handling; and for
0.7 variable costs, Dimensional Instability, loot, Auto and the Behavior
keywords you choose); touches sent through the window as a phone sends them,
from the home screen through the builder and into a Battle where cards are
played by touch, X chosen, Auto switched on and a Unit's Behaviors set;
battles of both kinds played through by a random hand, cards, Auto and loot
and all, to see that nothing breaks; the rules proved equal to the Companion's
rules.js two ways (its suite translated, and thousands of generated cases run
through both); the battle code, the keyword reader, the effect engine, the
waves, the Aether, the cards as they are played, Auto, loot and the Deck
Builder's checks proved equal to the Companion's Battle Simulator, loot.js
and Deck Builder (their own functions, run on the export's floors and cards,
case by case); and the screens rendered on a virtual display, checked for
what should be there.

For 0.8: the test export carries a fixed World Map with a Unique POI, an
Emergency Exit on one floor and Enemies that leave blueprints; when a Status
ticks (Handbook 15.9) is checked in the game's own tests and replayed against
the simulator; blueprints and chassis are rolled as the Companion's
progress.js rolls them, in fights and out; the World Map, its floors, its
Events and whole deployments are proved equal to world.js and deploy.js case
by case; deployments are played through by a random hand, with real fights,
without the screen and through it; and the dock, the map and a deployment's
fight are rendered and checked.

For 0.9: the Workshop's rules (power, the fit check, what a copy costs, a
design as a Troop card, blueprint levels and research, a design's look) and
the keyword builder, tap by tap and screen by screen, are proved equal to the
Companion's workshop.js, chassis.js, scoring.js, skins.js, progress.js and
builder.js case by case; leaving the dock with designs (what the copies cost,
the reasons a team can't go) is proved equal to deploy.js; the Workshop is
used by a random hand through its screens, and deployments take out designs
built by random taps; and the Workshop, a design, the keyword builder and the
dock's Field copy are rendered and checked.

For 0.10: the dock (its tables, the Exchange's stock and prices, buying and
selling, Reclaiming, the Bounty Board, upgrades, and a deployment's end at
the dock) is proved equal to the Companion's dock.js case by case, and the
deployments compared with deploy.js leave with packs and pre-built copies
and end with bounties paid, insurance kept, restocks and reach; deployments
played by a random hand shop at the dock, pack, take pre-built copies out,
claim bounties and lose packs to wipes, with every shard accounted for, and
through the screen a random hand taps whatever the dock offers; and the
dock's tabs, the Pack and a bounty's tag in a fight are rendered and
checked.

For 0.11: every screen is checked again in the new look (its colours are the
Pixel Studio's, though a keyword in a sentence keeps the Companion's), and
the look itself: Home's backdrop, cut corners, text with no smoothed edges,
icons and numbers in results, the side panel and the map, the deck plate
under the board, the bar under the bottom line and the dock's hangar. The
test export carries an icon drawn in its Game look slot, and the game is
seen to use it. The zip carries Jersey 10 and its licence.
For 0.12: the test export's Ranged Actions carry what they fire (the
Companion's Projectile), into the cards, the rules' Units and the designs,
and every comparison includes it; half the fights through the screen are
played with everything moving; and a shot of each kind is caught in the air,
with Options open over Home.
For 0.13 (Handbook 16.0, the playtest's fixes): the locks, Execute, attack
effects that need Penetration, Sacrifice, the area and to-hit prices, a
chassis's best to-hit and Overclock out of the builder are all in the rules,
the keyword reader, the builder and the Workshop on both sides, so every
comparison carries them; the test export's master Enemies aim at 8 to 10 and
its chassis carry a best to-hit; the game's own tests check each; and a
guarded Unit's ring and side panel are rendered.
For 0.14 (the fight, drawn): the test export comes from a Companion that
carries the game's own art: the stand-in skins' tokens are the game's
drawings, 48 square; the master Units' tokens and the slots' pictures stay
out of it, nobody having drawn on them, but for the crate, drawn over in its
slot, which comes and is used; the game's own tests check the art, the grid,
the board's things, tokens, the printed card, the fan, the gems, the zoom
steps and the new bar; and the fight, the hand, a card's sheet, the panel and
the Look board are rendered and checked. The zip carries VT323 and its
licence, the art and the scripts that draw it.
For 0.15 (the World Map and the menus): the test export comes from a
Companion carrying game 0.15's art too: District 3's Half Cover drawn over in
its slot, and one of District 2's four grounds, which brings the whole slot;
the game's own tests check the map's ground, rubble, things, icons and
Hangar, each District's floors and cover, the menus' pictures, QM-7, Home,
Practice, Options, the Exchange's tiles, the result's strip and tiles, the
Workshop's card and pedestal, and Strike Teams and setup to match; and Home,
the map, the dock, a fight in its District and a won fight are rendered and
checked again in the new look.
For 0.16 (the fight's effects, drawn): the test export comes from a Companion
whose Pixel Studio draws in frames, and carries the game's impact drawn over
(a pixel in its third frame, at 10 a second), as its five frames side by
side; the game's own tests check the effects' sheet and frames, yours in
their place, how they play (at their speed, faster at Fast, not at Instant),
where each plays in a fight and from a card, the turn strip and End turn's
icon; and a fight's turn strip and the five effects caught mid-play are
rendered and checked.
For 0.17 (card art): the test export comes from a Companion that gives each
card that is not a Unit the game's picture as its art, and carries Field
Dressing's drawn over (a green line along its top) as that card's art; the
game's own tests check the card art's sheet, how a card finds its picture (by
id, else by name, never across kinds), that every master card that is not a
Unit wears it, yours in its place, and the Look board; and the Team editor's
Consumables and a card's sheet are rendered and checked.
For 0.18 (the fight's atmosphere): the test export carries the Companion's
ash drawn over (a pixel in its second frame), its three frames side by side;
the game's own tests check the motes' sheet, the Atmosphere setting, the
glows, the motes and the flicker at each level and in and out of District 3,
Options' row, yours in the game's place, and the Look board; and a District 3
fight is rendered at Off and at Full, and its glows and embers found.
For 0.19 (transitions, Victory and Defeat, cards dealt): the test export
carries the Companion's card back drawn over (a green line along its top);
the game's own tests check the card back, which cards are dealt, the
transitions and which plays where, the scene's powering on and skipping, and
the hand dealt from its Deck; and a pixel dissolve, Victory, Defeat and a hand
being dealt are rendered mid-play and checked.
For 0.20 (battlefields grown from chunks): the test export carries the 16
District 3 chunks; the game's own tests check the lattice, turning and
mirroring, growing at each size, the joins' walls, keys, the World Map's
grown POIs and ambushes, Boss floors and the chunks kept apart from floors;
the game grows the Companion's battlefields in every one of the generated
cases; and a grown battlefield is rendered whole and checked.
For 0.21 (the movement keywords, Revision 16.1): the test export carries the
Test Skirmisher and the Test Skitter; the game's own tests check the
library, the power, the builder, Lunge, Charge, Dash, Leap and the Skitter's
turn; and the simulator's cases now hold reach with a Leap, where a Lunge
ends, Charge's damage and an Enemy's Dash, with fights where they happen.
For 0.22 (content batch 1, Revision 16.2): the test export carries batch 1's
18 cards, the Skitter Frame and its two pre-built Troops, District 3's
movement blueprints and the four gantry chunks; the game's own tests check
them, a Support Action aimed only at its own Unit, and cards in the haul; the
simulator's cases now hold self-targeted Actions and cards left in fights,
and the World Map's hold cards among the items found.
For 0.23 (Revision 16.3, Companion 14.10 to 14.12): the test export carries the
audited cards, the Bastion Chip and the three new test cards; the game's own
tests check the eleven keywords in the library, the power, the builder and the
blueprints, Troop and Hero, whole sides, Aim and Hardened in the odds and the
rules, Draw and gain Aether, a Barricade (on a copy of the floor, taken back
by Undo), Line and Cone and their preview, Actions aimed at a tile on the
screen, and Hardened's icon; the simulator's cases now hold Actions aimed at
tiles, Barricades put down, cards drawn, Aether gained, Hardened and Line and
Cone in the fights.
("verify_game.py screens" runs only the screens, while working on them.)"""
import subprocess, pathlib, os, sys, zipfile, json, urllib.request, shutil, re

ROOT = pathlib.Path(__file__).resolve().parent
GAME = ROOT / "game"
GODOT_VER = "4.7.2"
BIN = pathlib.Path("/home/claude/tools") / f"Godot_v{GODOT_VER}-stable_linux.x86_64"
ok, bad = [], []
def ck(n, c, d=""):
    (ok if c else bad).append(n + ((" — " + str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ") + n + ("" if c else "  — " + str(d)[:260]))

def godot():
    if BIN.exists():
        return str(BIN)
    BIN.parent.mkdir(parents=True, exist_ok=True)
    url = f"https://github.com/godotengine/godot/releases/download/{GODOT_VER}-stable/Godot_v{GODOT_VER}-stable_linux.x86_64.zip"
    zp = BIN.parent / "godot.zip"
    urllib.request.urlretrieve(url, zp)
    with zipfile.ZipFile(zp) as z:
        z.extractall(BIN.parent)
    zp.unlink()
    BIN.chmod(0o755)
    return str(BIN)

sys.path.insert(0, str(ROOT))
import make_game

# 1. a fresh export from the Companion as built
fx = make_game.fixture()
z = zipfile.ZipFile(fx["file"])
man = json.loads(z.read("manifest.json"))
ck("the Companion's Export for Godot carries content and art", man.get("format") == 1 and len(man.get("content", [])) == 7 and fx["graphics"] > 20, man.get("content"))
ck("the zip is named for the game to find", make_game.tag().startswith("v0-"), make_game.tag())
# what the export holds, in a folder of its own, for the Companion's code to be run on
CONTENT = pathlib.Path("/tmp/keter_content")
if CONTENT.exists():
    shutil.rmtree(CONTENT)
CONTENT.mkdir()
for nm in z.namelist():
    if nm.startswith("content/") and nm.endswith(".json"):
        (CONTENT / pathlib.Path(nm).name).write_bytes(z.read(nm))
(CONTENT / "manifest.json").write_bytes(z.read("manifest.json"))      # (0.9: which pictures a skin has)
wm = json.loads((CONTENT / "world_map.json").read_text())
fl = json.loads((CONTENT / "floors.json").read_text())["floors"]
cd = json.loads((CONTENT / "cards.json").read_text())["cards"]
ck("0.8: the test export has a fixed World Map with a Unique POI two steps from the dock", wm["map"]["seed"] == make_game.WORLD_SEED and len(wm["map"]["tiles"]) > 600 and len(wm["uniques"]) == 1 and wm["uniques"][0]["tile"] in wm["map"]["tiles"]
   and len(wm["events"]) >= 8 and wm["tables"]["respawn"] == 3, (wm["map"].get("seed"), len(wm["map"]["tiles"]), wm["uniques"]))
ck("0.8: and a floor with an Emergency Exit and a reward that can leave a blueprint or a chassis", any(any(d.get("text") == "EX" for d in f.get("symDefs", [])) and any(l.get("kind") == "item" for l in (f.get("loot") or {}).get("lines", [])) for f in fl))
ck("0.8: and Enemies that leave some of their own", len([c for c in cd if c.get("setDrops")]) >= 2 and len([c for c in cd if c.get("lootPool")]) >= 2)
aims = [(c["name"], e.get("name"), int(str(e.get("toHit")))) for c in cd if re.search("enemy|elite|boss", str(c.get("cardType", "")).lower()) and not c.get("testCard")
        for e in (c.get("entries") or []) if str(e.get("role", "")).lower() == "ranged" and str(e.get("toHit") or "").strip()]
ck("0.13: the test export's master Enemies aim at 8 to 10", aims and all(8 <= a[2] <= 10 for a in aims), aims)
def _chassis_in(o):
    if isinstance(o, dict):
        if "bodyPlan" in o and "powerCap" in o:
            yield o
        for v in o.values():
            yield from _chassis_in(v)
    elif isinstance(o, list):
        for v in o:
            yield from _chassis_in(v)
chs = [c for f in CONTENT.glob("*.json") for c in _chassis_in(json.loads(f.read_text()))]
ck("0.13: and its chassis carry a best to-hit, and no maximum", chs and all("bestHit" in c and "maxHit" not in c for c in chs), [(c.get("id"), c.get("bestHit"), c.get("maxHit")) for c in chs])
ck("0.12: the test export's Ranged Actions say what they fire", sorted(e.get("projectile") for c in cd for e in (c.get("entries") or []) if e.get("projectile")) == sorted(make_game.TEST_PROJECTILES.values()),
   [(c["name"], e["name"], e.get("projectile")) for c in cd for e in (c.get("entries") or []) if e.get("projectile")])
man_files = man.get("files", [])
# (0.15: and District 3's Half Cover, drawn over, and all four of District 2's ground, one of them drawn over)
games_sent = sorted(f["file"] for f in man_files if str(f.get("picture", "")).startswith("px_keter_"))
ck("0.14: the test export leaves out the game's own art, nobody having drawn on it: no master Unit's token, no slot's picture (only those drawn over, 0.17's Field Dressing art among them)",
   not any(f.get("group") == "cards" and f.get("what") == "token" and not str(f.get("owner", {}).get("card", "")).startswith("Test") for f in man_files)
   and games_sent == sorted(["fight/loot_crate.png", "fight/districts/district_3_half_cover_parts_bin.png", "fight/effects/impact.png", "fight/effects/ash.png", "ui/cards/card_back.png", "cards/consumable/field_dressing_art.png"] + ["map/ground/district_2_ground_%d.png" % i for i in range(1, 5)]), games_sent)
g2 = [f for f in man_files if f.get("owner") == {"slot": "map.ground.2"}]
ck("0.15: District 3's Half Cover, drawn over in District fights; and one of District 2's grounds, which brings all four, as hexagons of hex pixels",
   fx.get("d15", {}).get("cover") and any(f.get("owner") == {"slot": "fight.d3.half_cover"} and f.get("w") == 48 for f in man_files)
   and len(g2) == 4 and all(f.get("grid") == "hex" and f["hex"]["shape"] == "hexagon" and f["hex"]["side"] == 9 and f["hex"]["orient"] == "flat" for f in g2), [(f["file"], f.get("hex")) for f in g2])
ck("0.14: but the crate, drawn over in its slot in The fight, and the stand-in skins' tokens, the game's drawings at 48 by 48",
   fx.get("crate", {}).get("mine") and any(f["file"] == "fight/loot_crate.png" and f.get("owner") == {"slot": "fight.crate"} for f in man_files)
   and sorted((f.get("w"), f.get("h"), f.get("grid")) for f in man_files if str(f.get("picture", "")).startswith("px_skin_") and f.get("what") == "token") == [(48, 48, "square")] * 5,
   [(f["file"], f.get("w"), f.get("grid")) for f in man_files if str(f.get("picture", "")).startswith("px_skin_")])
# (0.16: and the game's impact, drawn over in Effects: its five frames side by side, at 10 a second)
imp16 = [f for f in man_files if f.get("owner") == {"slot": "fight.fx.impact"}]
strip16 = None
if imp16:
    import io
    from PIL import Image as _Im
    strip16 = _Im.open(io.BytesIO(z.read(imp16[0]["file"]))).convert("RGBA")
ck("0.16: the impact, drawn over in Effects, comes as its five frames side by side, saying how many and how fast; the other effects and the Action icons stay out",
   fx.get("d16", {}).get("mine") and len(imp16) == 1 and imp16[0].get("frames") == 5 and imp16[0].get("fps") == 10 and imp16[0].get("w") == 32 and imp16[0].get("h") == 32
   and strip16 is not None and strip16.size == (160, 32) and strip16.getpixel((2 * 32 + 16, 16))[:3] == (109, 255, 58)
   and not any(str(f.get("owner", {}).get("slot", "")).startswith(("fight.fx.flash", "fight.fx.explosion", "fight.fx.heal", "fight.fx.shield", "ui.icon.act_")) for f in man_files),
   [imp16, strip16.size if strip16 else None])
# (0.17: and Field Dressing's art, drawn over in the Pixel Studio: as that card's art, 128 by 90; no other card picture of the game's)
art17 = [f for f in man_files if f.get("file") == "cards/consumable/field_dressing_art.png"]
ck("0.17: Field Dressing's picture, drawn over, comes as that card's art, 128 by 90; the game's other card pictures stay out",
   fx.get("d17", {}).get("mine") and fx.get("d17", {}).get("n") == 93 and len(art17) == 1 and art17[0].get("what") == "art" and art17[0].get("w") == 128 and art17[0].get("h") == 90
   and not any(str(f.get("picture", "")).startswith("px_keter_art_") and f is not art17[0] for f in man_files), [art17, fx.get("d17")])
# (0.18: and the atmosphere's ash, drawn over in Effects: its three frames side by side, at 4 a second)
ash18 = [f for f in man_files if f.get("owner") == {"slot": "fight.fx.ash"}]
ck("0.18: the ash, drawn over in Effects, comes as its three frames side by side, 8 by 8, at 4 a second; the other motes stay out",
   fx.get("d18", {}).get("mine") and len(ash18) == 1 and ash18[0].get("frames") == 3 and ash18[0].get("fps") == 4 and ash18[0].get("w") == 8 and ash18[0].get("h") == 8
   and not any(str(f.get("owner", {}).get("slot", "")) in ("fight.fx.ember", "fight.fx.spark", "fight.fx.dust") for f in man_files), [ash18, fx.get("d18")])
# (0.19: and the card back, drawn over in Game look)
back19 = [f for f in man_files if f.get("owner") == {"slot": "ui.card.back"}]
ck("0.19: the card back, drawn over in Game look, comes as one picture, 75 by 105", fx.get("d19", {}).get("mine") and len(back19) == 1 and back19[0].get("w") == 75 and back19[0].get("h") == 105, [back19, fx.get("d19")])
ck("0.8: the Companion's own test cards are left as they were (no drops; from 0.22 only content batches carry their own)", not any((c.get("setDrops") or c.get("lootPool")) and not c.get("batch") for c in json.loads((ROOT / "compendium_full.json").read_text())["cards"]))

# 2. the game's own tests
G = godot()
imp = subprocess.run([G, "--headless", "--path", str(GAME), "--import"], capture_output=True, text=True, timeout=180)
ck("the project imports in Godot " + GODOT_VER, imp.returncode == 0 and "SCRIPT ERROR" not in imp.stdout + imp.stderr, (imp.stdout + imp.stderr)[-400:])

def suite(script, summary_word, least, timeout=300):
    try:
        run = subprocess.run([G, "--headless", "--path", str(GAME), "--script", "res://tests/" + script], capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as e:
        # a script error inside a test stops it short of quitting: say so, don't hang
        out = ((e.stdout or b"").decode() if isinstance(e.stdout, bytes) else (e.stdout or "")) + ((e.stderr or b"").decode() if isinstance(e.stderr, bytes) else (e.stderr or ""))
        lines = out.splitlines()
        return 1, [], ["TIMED OUT after %ds" % timeout] + [l for l in lines if "SCRIPT ERROR" in l][:3], [l for l in lines if "SCRIPT ERROR" in l], out
    out = run.stdout + run.stderr
    lines = out.splitlines()
    fails = [l for l in lines if l.startswith("FAIL") or l.startswith("  x ") or l.startswith("DIFF")]
    summary = [l for l in lines if l.startswith(summary_word)]
    for l in fails[:12]:
        print("  " + l)
    errs = [l for l in lines if ("SCRIPT ERROR" in l or l.startswith("ERROR")) and "does not exist in zip" not in l]
    return run.returncode, summary, fails, errs, out

# ("screens" after the script's name runs only the screens, below: while working on them)
SCREENS_ONLY = "screens" in sys.argv[1:]
if not SCREENS_ONLY:
    code, summary, fails, errs, out = suite("run_tests.gd", "GAME PASS", 100)
    n = int(summary[0].split()[2]) if summary else 0
    ck("the game's tests: %d pass" % n, code == 0 and summary and not fails and n >= 1080, summary or out[-400:])
    ck("no script errors while testing", not errs, errs[:5])

    code, summary, fails, errs, out = suite("touch_path.gd", "TOUCH PASS", 40)
    ck("touches, sent as the phone sends them, land where they should: " + (summary[0] if summary else "?"), code == 0 and summary and not fails and not errs and int(summary[0].split()[2]) >= 110, (fails or errs or [out[-300:]])[:3])

    code, summary, fails, errs, out = suite("soak.gd", "SOAK PASS", 100)
    ck("battles played through by a random hand, with the export's real cards (half of them a Strike Team's, waves and all), never break: " + (summary[0] if summary else "?"), code == 0 and summary and not fails and not errs and int(summary[0].split()[2]) >= 100, (fails or errs or [out[-300:]])[:3])
    played = [l for l in out.splitlines() if l.startswith("(played from the hand")]
    ck("and in them cards are played, Consumables used, Chips spent and some taken back: no card lost, and a card taken back leaves everything as it was", bool(played) and " 0 Troops" not in played[0] and " 0 taken back" not in played[0], played)
    seven = [l for l in out.splitlines() if l.startswith("(0.7: ")]
    ck("and cards are played for an X, rounds are left to Auto, Enemies drop their loot and Instability sends its own", bool(seven) and not any(w in seven[0] for w in [": 0 cards played for an X", " 0 Auto turns", " 0 Enemies dropped", " 0 Loot Tiles", " 0 fights settled", " 0 Elites"]), seven)
    eight = [l for l in out.splitlines() if l.startswith("(0.8: ")]
    ck("0.8: and blueprints and chassis are left behind in them: each one the export knows, found once, with its line in the log, and settled with the fight", bool(eight) and not eight[0].startswith("(0.8: 0 blueprints"), eight)

    code, summary, fails, errs, out = suite("soak_screen.gd", "SCREEN SOAK PASS", 20, timeout=600)
    ck("the same through the screen, tap by tap: it never breaks and never gets stuck: " + (summary[0] if summary else "?"), code == 0 and summary and not fails and not errs and int(summary[0].split()[3]) >= 20, (fails or errs or [out[-300:]])[:3])
    twelve = [l for l in out.splitlines() if l.startswith("(0.12: ")]
    ck("0.12: and half of them are played with everything moving, shots in the air as the taps come", bool(twelve) and not twelve[0].startswith("(0.12: 0 ") and "; 0 shots" not in twelve[0], twelve)
    played = [l for l in out.splitlines() if l.startswith("(played by touch")]
    ck("and there cards are played by touch: the tray, the sheet's button, then what lights up", bool(played) and not played[0].startswith("(played by touch: 0 cards"), played)
    seven = [l for l in out.splitlines() if l.startswith("(0.7: ")]
    ck("and X is stepped on a card's sheet, Behavior keywords are picked, Auto plays its rounds, and the loot count and every result say what is so", bool(seven) and not any(w in seven[0] for w in [": 0 cards played for an X", " used 0 times", "Auto played 0 rounds", " checked 0 times", " 0 results read"]), seven)

    code, summary, fails, errs, out = suite("soak_world.gd", "WORLD SOAK PASS", 40, timeout=600)
    ck("0.8: deployments played through by a random hand, with real fights, without the screen and through it, never break and the books balance: " + (summary[0] if summary else "?"), code == 0 and summary and not fails and not errs and int(summary[0].split()[3]) >= 40, (fails or errs or [out[-300:]])[:3])
    told = [l for l in out.splitlines() if l.startswith("(")]
    ck("0.8: and in them POIs are cleared, Caches opened, Events chosen, fights tried again, teams wiped out and brought home, and all of it saved and read back", len(told) == 5 and not any(w in " ".join(told) for w in [" 0 POIs", " 0 Caches", " 0 Events", " 0 tried again", " 0 wipes", " 0 Emergency Exits", " 0 came home", "read back 0 times", " 0 cleared tiles came back", ": 0 deployments, ", " 0 walks", ", 0 fights)"]), told)
    nine = [l for l in told if l.startswith("(0.9: ")]
    ck("0.9: and the teams take out designs built with the keyword builder, which fight; copies are paid for as they leave, and a team that can't pay stays", bool(nine) and not any(w in nine[0] for w in ["(0.9: 0 designs", "; 0 of their copies", ", 0 into fights", "; 0 Troop parts", "; 0 teams sent back"]), nine)
    ten = [l for l in told if l.startswith("(0.10: ")]
    ck("0.10: and between them the dock is used: things bought and upgrades paid for, packs taken out and brought back or lost, pre-built copies out, bounties tagged and paid, insurance kept, restocks; and through the screen, buying and a random hand on the dock's tabs",
       bool(ten) and not any(w in ten[0] for w in ["(0.10: 0 Consumables", "and 0 taken out", ", 0 upgrades", "; 0 packed", ", 0 back to the dock", ", 0 lost with a wipe", ", 0 fights with one", ", 0 paid", "kept something 0 times", "; 0 restocks", "; 0 bought through the screen", "and 0 taps at the dock"]), ten)

    code, summary, fails, errs, out = suite("soak_workshop.gd", "WORKSHOP SOAK PASS", 300, timeout=600)
    ck("0.9: the Workshop used by a random hand, through its screens, never breaks, and what is shown is what is kept: " + (summary[0] if summary else "?"), code == 0 and summary and not fails and not errs and int(summary[0].split()[3]) >= 300, (fails or errs or [out[-300:]])[:3])
    told = [l for l in out.splitlines() if l.startswith("(")]
    ck("0.9: and in it designs are made, effects built and changed by thousands of taps, designs renamed, copied, deleted and copied in, blueprints researched, and all of it read back", len(told) == 2 and not any(w in " ".join(told) for w in [" 0 designs made", " 0 effects built", " and 0 changed", " 0 renamed", " 0 names refused", " 0 copies", " 0 deleted", " 0 copied in", " 0 researched", " 0 refused", " flipped 0 times", "read back 0 times"]), told)

    code, summary, fails, errs, out = suite("rules_tests.gd", "RULES TESTS PASS", 150)
    ck("the Companion's rules suite, translated, passes against rules.gd: " + (summary[0] if summary else "?"), code == 0 and summary and not fails and not errs and int(summary[0].split()[3]) >= 150, (fails or errs or [out[-300:]])[:3])

    # the cases come from running the Companion's rules.js, freshly, on this export's cards
    cards = CONTENT / "cards.json"
    gen = subprocess.run(["node", str(ROOT / "make_rule_cases.js"), str(cards)], capture_output=True, text=True, timeout=300)
    ck("rules.js generates its cases", gen.returncode == 0 and (GAME / "tests" / "fixtures" / "rule_cases.json").exists(), (gen.stdout + gen.stderr)[-300:])
    code, summary, fails, errs, out = suite("rules_diff.gd", "RULES MATCH", 5000, timeout=600)
    match = int(summary[0].split()[2]) if summary else 0
    ck("rules.gd gives rules.js's answer in every generated case: " + (summary[0] if summary else "?"), code == 0 and summary and match >= 6000 and summary[0].endswith("DIFFER 0") and not errs, (fails or errs or [out[-300:]])[:4])
    ck("0.8: among them both ticks, in either half of the round", "tickLate" in (GAME / "tests" / "fixtures" / "rule_cases.json").read_text() and '"half"' in (GAME / "tests" / "fixtures" / "rule_cases.json").read_text())

    # the simulator's cases come from running its own functions, out of shell.html, on this export
    # (0.13: about 30,900 of them; 0.12's were 31,100, before Execute ended some fights sooner)
    floors_file = CONTENT / "floors.json"
    gen2 = subprocess.run(["node", str(ROOT / "make_sim_cases.js"), str(cards), str(floors_file)], capture_output=True, text=True, timeout=300)
    ck("the Companion's Battle Simulator generates its cases", gen2.returncode == 0 and (GAME / "tests" / "fixtures" / "sim_cases.json").exists(), (gen2.stdout + gen2.stderr)[-300:])
    code, summary, fails, errs, out = suite("sim_diff.gd", "SIM MATCH", 5000, timeout=600)
    match2 = int(summary[0].split()[2]) if summary else 0
    ck("the game's battle code and effect engine give the simulator's answer in every case: " + (summary[0] if summary else "?"), code == 0 and summary and match2 >= 30500 and summary[0].endswith("DIFFER 0") and not errs, (fails or errs or [out[-300:]])[:4])
    kinds = [l.split(":")[0].split()[1] for l in out.splitlines() if l.startswith("PASS ")]
    ck("every kind of case is there: the keyword reader, starts, moves, attacks, holds, Enemy phases, Strike Team fights, cards played, the Deck Builder's checks; and X, Auto and loot", all(k in kinds for k in ["kwParse", "kwAnalyse", "kwProblems", "startFight", "playerMove", "playerAttack", "holdable", "hurtsOwnSide", "enemyPhase", "handCard", "costLabel", "aetherLabel", "cardNeeds", "textNeeds", "teamFight", "teamPlay", "teamPings", "reachTiles", "lungeSpot", "canReachLunge", "charged", "dashAway",
        "kwX", "cardCost", "costOf", "unitX", "statX", "autoTurn", "lootRoll", "lootReward", "lootText", "lootAdd", "lootSource", "lootPoiSkull"]), kinds)
    try:
        plays = json.loads(gen2.stdout.strip().splitlines()[-1]).get("plays", {})     # the generator's own count of what it played
    except Exception:
        plays = {}
    ck("the fights with cards played cover every way of playing one, and its refusal", all(plays.get(k, 0) >= 20 for k in ["hand:troop", "hand:equipment", "hand:plain", "cons", "chip", "hand:troop refused", "hand:plain refused", "cons refused", "chip refused", "an Action used", "a card aimed at a tile"]) and plays.get("fights with a Recover", 0) >= 10, plays)
    ck("and what 0.7 adds: cards and carried Actions used for an X, turns on Auto, Units that walk, and Instability with something to send and with nothing", plays.get("a card played for X", 0) >= 80 and plays.get("a carried Action used for X", 0) >= 10 and plays.get("auto", 0) >= 50 and plays.get("move", 0) >= 100
       and plays.get("fights where Instability sent an Elite or a Mini-Boss", 0) >= 100 and plays.get("fights where Instability had nothing to send", 0) >= 10 and plays.get("Auto: an attack", 0) >= 300 and plays.get("Auto: a Medic tended someone", 0) >= 20, plays)
    ck("and loot in the fights: Enemies' drops, Loot Tiles and Locked Chests found by walking and on Auto, and a floor's reward", plays.get("loot: an Enemy's drop", 0) >= 500 and plays.get("loot: a Loot Tile found", 0) >= 20 and plays.get("loot: a Locked Chest opened", 0) >= 15 and plays.get("loot: found by a Unit that walked", 0) >= 40
       and plays.get("loot: found by a Unit on Auto", 0) >= 3 and plays.get("loot: a floor's reward paid", 0) >= 3 and plays.get("loot: fights lost with a haul settled", 0) >= 10, plays)
    sct = (GAME / "tests" / "fixtures" / "sim_cases.json").read_text()
    mk = {w: sct.count(w) for w in ["lunges ", "(Charge +", " Dashes ", "may Dash", "can Leap"]}
    import re as _re
    m23 = {"tileUse": "tileUse" in kinds, "barricades": len(_re.findall(r"(Full|Half) Cover Barricade on", sct)), "drew": len(_re.findall(r"drew \d+ card", sct)),
           "gained": len(_re.findall(r": gained [^\"]* Aether", sct)), "hardened": len(_re.findall(r"gains? Hardened", sct)),
           "line": len(_re.findall(r"Line \d+ (also hits|caught nobody)", sct)), "cone": len(_re.findall(r"Cone \d+ (also hits|caught nobody)", sct))}
    ck("0.23: and Actions aimed at tiles, Barricades put down, cards drawn and Aether gained, Hardened given, and Lines and Cones carried on in the fights",
       m23["tileUse"] and m23["barricades"] >= 20 and m23["drew"] >= 50 and m23["gained"] >= 50 and m23["hardened"] >= 20 and m23["line"] >= 5 and m23["cone"] >= 3, m23)
    ck("0.22: and Actions aimed only at their own Unit used at once, and cards left in fights", "selfUse" in kinds and sct.count(" leaves a card") >= 5, {"selfUse": "selfUse" in kinds, "cards": sct.count(" leaves a card")})
    ck("0.21: and in the fights, Units lunge, Charge, Dash (yours and the Enemies') and Leap", mk["lunges "] >= 10 and mk["(Charge +"] >= 2 and mk[" Dashes "] >= 10 and mk["may Dash"] >= 5 and mk["can Leap"] >= 1, mk)
    try:
        seen_sim = json.loads(gen2.stdout.strip().splitlines()[-1]).get("seen", {})
    except Exception:
        seen_sim = {}
    ck("0.8: and when a Status ticks: turns that end with something from the Enemies' half to tick", seen_sim.get("turnEndTicks", 0) >= 150 and seen_sim.get("lateGiven", 0) >= 150, {k: seen_sim.get(k) for k in ("turnEndTicks", "turnEndLines", "lateGiven")})
    ck("0.8: and blueprints and chassis left in fights, some named already, some from a floor's own reward", plays.get("items: a blueprint left behind", 0) >= 60 and plays.get("items: a chassis left behind", 0) >= 20 and plays.get("items: one whose name is known already", 0) >= 1 and plays.get("items: from a floor's own reward", 0) >= 1, {k: v for k, v in plays.items() if k.startswith("items")})
    ck("0.8: and a deployment's fights, won and lost, told to the deployment", plays.get("a deployment's fight", 0) >= 100 and plays.get("a deployment's fight settled: ally", 0) >= 5 and plays.get("a deployment's fight settled: enemy", 0) >= 10 and plays.get("a deployment's fight that found a blueprint or a chassis", 0) >= 3, {k: v for k, v in plays.items() if k.startswith("a deployment")})

    # the World Map's cases come from running world.js, deploy.js and progress.js on this export's map
    gen3 = subprocess.run(["node", str(ROOT / "make_world_cases.js"), str(CONTENT)], capture_output=True, text=True, timeout=300)
    ck("0.8: the Companion's World Map, deployments and progress generate their cases", gen3.returncode == 0 and (GAME / "tests" / "fixtures" / "world_cases.json").exists(), (gen3.stdout + gen3.stderr)[-300:])
    code, summary, fails, errs, out = suite("world_diff.gd", "WORLD MATCH", 3000, timeout=600)
    match3 = int(summary[0].split()[2]) if summary else 0
    ck("0.8: the game's World Map, deployments and drops give the Companion's answer in every case: " + (summary[0] if summary else "?"), code == 0 and summary and match3 >= 3900 and summary[0].endswith("DIFFER 0") and not errs, (fails or errs or [out[-300:]])[:4])
    kinds3 = [l.split(":")[0].split()[1] for l in out.splitlines() if l.startswith("PASS ")]
    ck("0.8: every kind of case is there: tiles, ways across, floors drawn, Events, blueprints, drops rolled, and whole deployments", all(k in kinds3 for k in ["hash", "tile", "mapFacts", "path", "floors", "floorCount", "draw", "event", "blueprint", "eligible", "itemName", "grant", "rollItems", "rollRewardItems", "deployment", "plan"]), kinds3)
    try:
        dp = json.loads(gen3.stdout.strip().splitlines()[-1]).get("deployments", {})
    except Exception:
        dp = {}
    ck("0.8: the deployments cover it: steps, ambushes of both kinds, POIs (a Unique one too) floor by floor to their reward, Caches, Events with checks won and failed, retries, escapes, wipes and coming home",
       dp.get("deployments", 0) >= 250 and dp.get("step", 0) >= 3000 and dp.get("ambush on the way", 0) >= 100 and dp.get("ambush on its tile", 0) >= 40 and dp.get("POI entered", 0) >= 100 and dp.get("POI entered (Unique)", 0) >= 10 and dp.get("fight: floor", 0) >= 40
       and dp.get("fight: map (POI cleared)", 0) >= 60 and dp.get("cache", 0) >= 100 and dp.get("event (check won)", 0) >= 15 and dp.get("event (check failed) into a fight", 0) >= 10 and dp.get("fight: retry", 0) >= 60 and dp.get("fight: map (escaped)", 0) >= 10
       and dp.get("fight: wipe", 0) >= 60 and dp.get("home", 0) >= 30, dp)
    ck("0.25: and recruited Heroes lost with the wipes, and teams with a Hero not recruited refused", dp.get("Heroes lost", 0) >= 20, dp)

    # 0.20: battlefields grown from chunks, from running chunkgen.js on this export's chunks
    gen6 = subprocess.run(["node", str(ROOT / "make_chunk_cases.js"), str(CONTENT)], capture_output=True, text=True, timeout=300)
    ck("0.20: the Companion's chunk generator gives its cases", gen6.returncode == 0 and (GAME / "tests" / "fixtures" / "chunk_cases.json").exists(), (gen6.stdout + gen6.stderr)[-300:])
    code, summary, fails, errs, out = suite("chunk_diff.gd", "CHUNK MATCH", 150, timeout=600)
    match6 = int(summary[0].split()[2]) if summary else 0
    ck("0.20: the game grows every battlefield the Companion does, tile for tile, wall for wall: " + (summary[0] if summary else "?"), code == 0 and summary and match6 >= 200 and summary[0].endswith("DIFFER 0") and not errs, (fails or errs or [out[-300:]])[:4])
    gens = (GAME / "tests" / "fixtures" / "world_cases.json").read_text().count('"gen|')
    ck("0.20: and the World Map's cases draw grown floors, which the game draws the same", gens >= 100, gens)
    cds = (GAME / "tests" / "fixtures" / "world_cases.json").read_text().count('"cd:')
    ck("0.22: and cards are among the items found on the World Map, which the game finds the same", cds >= 30, cds)

    wcr = (GAME / "tests" / "fixtures" / "world_cases.json").read_text().count('"craftShards":') 
    ck("0.34: and the stash in them: plans that craft what the stash lacks, the cards out with a team and back", wcr >= 300, wcr)
    ck("0.9: and leaving with designs: teams that can go and pay, teams short of parts, and teams refused, told why word for word", dp.get("plans that can go", 0) >= 20 and dp.get("plans short of parts", 0) >= 20 and dp.get("plans refused", 0) >= 20, {k: v for k, v in dp.items() if k.startswith("plans")})
    ck("0.10: and the dock in them: teams leaving with packs and pre-built copies, deployments ending with bounties paid, insurance kept, the Exchange restocked and the reach extended",
       dp.get("packed", 0) >= 30 and dp.get("pre-built copies out", 0) >= 100 and dp.get("bounties paid", 0) >= 5 and dp.get("insured", 0) >= 30 and dp.get("restocked", 0) >= 100 and dp.get("reach extended", 0) >= 20,
       {k: dp.get(k) for k in ("packed", "pre-built copies out", "bounties paid", "insured", "restocked", "reach extended")})

    # 0.9: the Workshop's cases come from running workshop.js, chassis.js, scoring.js, skins.js, progress.js and builder.js on this export
    gen4 = subprocess.run(["node", str(ROOT / "make_workshop_cases.js"), str(CONTENT)], capture_output=True, text=True, timeout=600)
    ck("0.9: the Companion's Workshop and keyword builder generate their cases", gen4.returncode == 0 and (GAME / "tests" / "fixtures" / "workshop_cases.json").exists(), (gen4.stdout + gen4.stderr)[-300:])
    code, summary, fails, errs, out = suite("workshop_diff.gd", "WORKSHOP MATCH", 5000, timeout=600)
    match4 = int(summary[0].split()[2]) if summary else 0
    ck("0.9: the game's Workshop and keyword builder give the Companion's answer in every case: " + (summary[0] if summary else "?"), code == 0 and summary and match4 >= 5600 and summary[0].endswith("DIFFER 0") and not errs, (fails or errs or [out[-300:]])[:4])
    kinds4 = [l.split(":")[0].split()[1] for l in out.splitlines() if l.startswith("PASS ")]
    ck("0.9: every kind of case is there: builder walks tap by tap, sentences read back, scores, ability power, blueprints, levels, research, designs, the starter, chassis checks, looks", all(k in kinds4 for k in ["builder", "fromSentence", "score", "abilityPower", "catalog", "levelFor", "needs", "researchPrice", "research", "owned", "design", "tables", "blank", "starter", "chassisCheck", "allowedFor", "districtOf", "keywordsIn", "look"]), kinds4)
    try:
        wsn = json.loads(gen4.stdout.strip().splitlines()[-1]).get("seen", {})
    except Exception:
        wsn = {}
    ck("0.9: the builder's walks: 500 of them, 8,000 taps, sentences inserted, the builder closed and reopened on a sentence; designs that fit and don't; research made and refused",
       wsn.get("walks", 0) >= 500 and wsn.get("taps", 0) >= 8000 and wsn.get("inserted", 0) >= 100 and wsn.get("closed", 0) >= 10 and wsn.get("reopened", 0) >= 50 and wsn.get("designs that fit", 0) >= 100 and wsn.get("designs that don't", 0) >= 100
       and wsn.get("researched", 0) >= 5 and wsn.get("research refused", 0) >= 5, wsn)

    # 0.10: the dock's cases come from running dock.js on this export
    gen5 = subprocess.run(["node", str(ROOT / "make_dock_cases.js"), str(CONTENT)], capture_output=True, text=True, timeout=600)
    ck("0.10: the Companion's dock generates its cases", gen5.returncode == 0 and (GAME / "tests" / "fixtures" / "dock_cases.json").exists(), (gen5.stdout + gen5.stderr)[-300:])
    code, summary, fails, errs, out = suite("dock_diff.gd", "DOCK MATCH", 500, timeout=600)
    match5 = int(summary[0].split()[2]) if summary else 0
    ck("0.10: the game's dock gives the Companion's answer in every case: " + (summary[0] if summary else "?"), code == 0 and summary and match5 >= 600 and summary[0].endswith("DIFFER 0") and not errs, (fails or errs or [out[-300:]])[:4])
    kinds5 = [l.split(":")[0].split()[1] for l in out.splitlines() if l.startswith("PASS ")]
    ck("0.10: both kinds of case are there: the tables as Dev Mode may have saved them, and runs at the dock", all(k in kinds5 for k in ["tables", "dock"]), kinds5)
    try:
        dks = json.loads(gen5.stdout.strip().splitlines()[-1]).get("seen", {})
    except Exception:
        dks = {}
    ck("0.10: the runs cover it: restocks; components, lots, blueprints, chassis, Consumables, Prototypes and pre-built copies bought and sold, and each refused; Reclaiming both ways; upgrades; deployments ending with bounties paid and insurance kept",
       dks.get("restock", 0) >= 200 and dks.get("buyParts", 0) >= 150 and dks.get("sellParts", 0) >= 40 and dks.get("buyItem", 0) >= 25 and dks.get("buyCard", 0) >= 25 and dks.get("sellCard", 0) >= 50 and dks.get("buyPre", 0) >= 40
       and dks.get("combine", 0) >= 15 and dks.get("swap", 0) >= 30 and dks.get("upgrade", 0) >= 10 and dks.get("ended", 0) >= 200 and dks.get("claim", 0) >= 100 and dks.get("bounties paid", 0) >= 60 and dks.get("insured", 0) >= 30
       and all(dks.get("refused: " + k, 0) >= 20 for k in ["buyParts", "sellParts", "buyItem", "buyCard", "sellCard", "buyPre", "combine", "swap", "upgrade"]), dks)
    ck("0.25: and recruiting: Heroes recruited and refused, stocks from before recruiting given their Heroes, and recruited Heroes lost with a wipe",
       dks.get("recruit", 0) >= 40 and dks.get("refused: recruit", 0) >= 40 and dks.get("oldStock", 0) >= 20 and dks.get("Heroes lost", 0) >= 20, dks)
    ck("0.34: and the stash: cards crafted and refused, stashes begun (new runs and old), and rare cards picked and refused",
       dks.get("craft", 0) >= 40 and dks.get("refused: craft", 0) >= 100 and dks.get("beginStash", 0) >= 60 and dks.get("pickRare", 0) >= 10 and dks.get("refused: pickRare", 0) >= 40, dks)

# 3. the screens, drawn
def shot(path, *args):
    if path.exists():
        path.unlink()
    r = subprocess.run(["xvfb-run", "-a", "-s", "-screen 0 1280x720x24", G, "--path", str(GAME), "--rendering-driver", "opengl3", "--audio-driver", "Dummy",
                        "--resolution", "1280x720", "--script", "res://tests/screenshot.gd", "--", str(path)] + list(args),
                       capture_output=True, text=True, timeout=180)
    return path.exists(), r.stdout + r.stderr

if shutil.which("xvfb-run"):
    from PIL import Image
    def colours(path, box):
        im = Image.open(path).convert("RGB")
        px = im.load()
        out = []
        for x in range(box[0], box[2], 4):
            for y in range(box[1], box[3], 4):
                out.append(px[x, y])
        return im, out
    def near(c, want, tol=26):
        return all(abs(c[i] - want[i]) <= tol for i in range(3))
    def count(path, box, want, tol=26):
        px = Image.open(path).convert("RGB").load()
        return len([1 for x in range(box[0], box[2], 2) for y in range(box[1], box[3], 2) if near(px[x, y], want, tol)])
    def colours2(path, box):
        px = Image.open(path).convert("RGB").load()
        return [px[x, y] for x in range(box[0], box[2], 2) for y in range(box[1], box[3], 2)]
    # (0.14) End turn, the bar's one gold button, at its right end; and Undo's icon, left of Auto, when it is offered
    def end_turn(path):
        return count(path, (1118, 12, 1266, 54), (214, 168, 81), 20)
    def undo_icon(path):
        return count(path, (729, 10, 785, 54), (201, 212, 253), 12)
    GOLD, CYAN, COMMAND, AETHER, DIM = (214, 168, 81), (115, 239, 232), (156, 139, 219), (138, 161, 246), (136, 163, 188)
    p1 = pathlib.Path("/tmp/keter_game_setup.png")
    ok1, log1 = shot(p1, "step=troops", "floor=TEST · Waves", "heroes=Test Warden;Test Striker", "troops=Frame Trooper;Test Drone")
    ck("the setup screen renders (Compatibility renderer)", ok1, log1[-300:])
    if ok1:
        im, cs = colours(p1, (0, 120, 1280, 640))
        cyan = [c for c in cs if c[0] < 120 and c[1] > 180 and c[2] > 190]
        ck("chosen Troops are outlined", len(cyan) > 20, len(cyan))
    p2 = pathlib.Path("/tmp/keter_game_battle.png")
    ok2, log2 = shot(p2, "floor=TEST · Corridor", "heroes=Test Warden;Test Striker", "troops=Test Drone", "place=a1:3,0;a2:6,0", "taps=3,0;a:0")
    ck("a battle renders, aiming", ok2, log2[-300:])
    if ok2:
        im, cs = colours(p2, (0, 80, 870, 660))
        ally = [c for c in cs if c[0] < 110 and c[1] > 200 and c[2] > 210]
        enemy = [c for c in cs if c[0] > 200 and c[1] < 90 and c[2] < 100]
        tag = [c for c in cs if c[0] > 200 and 150 < c[1] < 200 and c[2] < 110]
        ck("your Units in cyan, Enemies in red", ally and enemy, (len(ally), len(enemy)))
        ck("the targets wear their odds, in amber here", len(tag) > 6, len(tag))
        px = im.load()
        gold = [c for c in colours(p2, (890, 300, 1270, 716))[1] if 200 < c[0] < 240 and 160 < c[1] < 195 and 60 < c[2] < 100]
        ck("the side panel shows the Unit, and the top bar is there", sum(px[1274, 400]) < 90 and px[640, 20][2] < 40, (px[1274, 400], px[640, 20]))
        # (0.14: End turn is the one gold button, at the bar's right end)
        lit2 = end_turn(p2)
        ck("End turn is there to press, in gold", lit2 > 300, lit2)
        ck("an Action with Suppressive Fire has its gold Hold fire button", len(gold) > 8, len(gold))
    p3 = pathlib.Path("/tmp/keter_game_win.png")
    ok3, log3 = shot(p3, "floor=TEST · Corridor", "heroes=Test Warden;Test Striker", "taps=win")
    ck("the end of a battle renders", ok3, log3[-300:])
    if ok3:
        im, cs = colours(p3, (300, 150, 980, 480))
        green = [c for c in cs if c[1] > 180 and c[0] < 150 and c[2] < 170]
        ck("Victory, in green", len(green) > 10, len(green))
    # what cards say, on screen
    p4 = pathlib.Path("/tmp/keter_game_area.png")
    ok4, log4 = shot(p4, "floor=TEST · Hazards and Cover", "stage=Test Sapper@-4,4;Test Striker@-1,4;Test Warden@-3,1;!Test Grunt@-2,4;!Test Grunt@-2,3;!Test Gunner@2,-2", "sure=1", "taps=-4,4;a:0;-2,4")
    ck("an area Action's preview renders", ok4 and "SCRIPT ERROR" not in log4, log4[-300:])
    if ok4:
        im, cs = colours(p4, (330, 90, 870, 650))
        # (0.14: a hazard is the thing that bites, here pools of acid; the blast a wash with an edge)
        cs2 = colours2(p4, (330, 90, 870, 650))
        acid = [c for c in cs2 if near(c, (89, 207, 147), 10)]
        # (0.15: the floor is District 3's own, Vantage's deck, and the wash lies over it)
        wash = [c for c in cs2 if near(c, (96, 76, 55), 10) or near(c, (122, 76, 49), 10)]
        edge = [c for c in cs2 if c[0] > 215 and 125 < c[1] < 145 and 45 < c[2] < 65]
        yours = [c for c in cs if c[0] > 230 and 40 < c[1] < 90 and 100 < c[2] < 150]
        ck("0.14: hazard tiles are what bites: here pools of acid", len(acid) > 150, len(acid))
        ck("the blast is lit, a wash and its edge in orange, and your own Unit in it is flagged", len(wash) > 300 and len(edge) > 15 and len(yours) > 4, (len(wash), len(edge), len(yours)))
    p5 = pathlib.Path("/tmp/keter_game_halt.png")
    ok5, log5 = shot(p5, "floor=TEST · Hazards and Cover", "stage=Test Striker@-1,4;Test Warden@-3,1;!Test Grunt@-2,4;!Test Gunner@2,-2", "sure=1", "taps=break:a1:Shoulder Check;-1,4;a:0;-2,4;until")
    ck("a card problem's box renders", ok5 and "SCRIPT ERROR" not in log5, log5[-300:])
    if ok5:
        im, cs = colours(p5, (340, 220, 940, 300))
        title = [c for c in cs if c[0] > 200 and 115 < c[1] < 160 and 95 < c[2] < 140]
        ck("it stops the fight to say so, in red", len(title) > 10, len(title))
    p6 = pathlib.Path("/tmp/keter_game_burst.png")
    ok6, log6 = shot(p6, "floor=TEST · Hazards and Cover", "stage=Test Drone@0,4;Test Warden@-3,1;!Test Grunt@2,2;!Test Grunt@3,1", "sure=1", "taps=0,4;a:2;2,2;until;wait:220")
    ck("a Burst waiting on its next target renders", ok6 and "SCRIPT ERROR" not in log6, log6[-300:])
    if ok6:
        im, cs = colours(p6, (330, 90, 870, 650))
        tags = [c for c in cs if 70 < c[0] < 140 and c[1] > 190 and 120 < c[2] < 170]
        px = im.load()
        lit = end_turn(p6)
        ck("both targets lit again with their odds, and End turn waits (greyed)", len(tags) > 6 and lit == 0, (len(tags), lit))
    # home, the builder, and a Strike Team's Battle
    def near(c, want, tol=26):
        return all(abs(c[i] - want[i]) <= tol for i in range(3))
    def count_px(px, box, want):
        return len([1 for x in range(box[0], box[2], 2) for y in range(box[1], box[3], 2) if near(px[x, y], want)])
    # (0.11: the screens' colours are the Pixel Studio's; a keyword in a sentence keeps the Companion's own)
    GOLD, CYAN, COMMAND, AETHER = (214, 168, 81), (115, 239, 232), (156, 139, 219), (138, 161, 246)
    KW_GOLD, KW_CYAN, KW_GREEN = (224, 179, 77), (87, 216, 227), (123, 216, 143)
    p7 = pathlib.Path("/tmp/keter_game_home.png")
    ok7, log7 = shot(p7, "screen=home")
    ck("the home screen renders", ok7 and "SCRIPT ERROR" not in log7, log7[-300:])
    if ok7:
        # (0.15: the colony's sign, KETER in cyan neon with one letter dark, its tagline in amber; Play in gold under it,
        # Practice and Strike Teams beside each other, and the gear in the corner)
        px = Image.open(p7).convert("RGB").load()
        NEON = (34, 240, 255)
        words = [len([1 for x in range(x0, x0 + 212, 2) for y in range(486, 540, 2) if sum(px[x, y]) > 560]) for x0 in (414, 654)]
        ck("0.15: KETER in neon over the colony, RESEARCH COLONY · MARS in amber beneath; Play in gold; Practice and Strike Teams; the gear",
           count(p7, (370, 50, 910, 195), NEON, 12) > 1500 and count(p7, (370, 50, 910, 195), (70, 84, 86), 6) > 200 and count(p7, (380, 225, 900, 260), GOLD, 10) > 600
           and count(p7, (432, 314, 848, 398), GOLD, 10) > 5000 and all(w > 40 for w in words) and count(p7, (1198, 20, 1258, 80), (220, 234, 238), 8) > 20,
           (count(p7, (370, 50, 910, 195), NEON, 12), count(p7, (370, 50, 910, 195), (70, 84, 86), 6), count(p7, (380, 225, 900, 260), GOLD, 10), count(p7, (432, 314, 848, 398), GOLD, 10), words, count(p7, (1198, 20, 1258, 80), (220, 234, 238), 8)))
        ck("0.8: and where the deployments stand, in gold", count(p7, (500, 446, 780, 472), GOLD, 10) > 50, count(p7, (500, 446, 780, 472), GOLD, 10))
    p8 = pathlib.Path("/tmp/keter_game_deck.png")
    ok8, log8 = shot(p8, "screen=editor", "tab=deck", "deckonly=1")
    ck("the Strike Team builder renders", ok8 and "SCRIPT ERROR" not in log8, log8[-300:])
    if ok8:
        im, cs = colours(p8, (20, 240, 1260, 700))
        art = set((c[0] // 24, c[1] // 24, c[2] // 24) for c in colours(p8, (26, 256, 1140, 350))[1])
        ck("the Deck as tiles: each card's art, and a gold badge counting its copies", len([c for c in cs if near(c, GOLD)]) > 150 and len(art) > 25, (len([c for c in cs if near(c, GOLD)]), len(art)))
    p9 = pathlib.Path("/tmp/keter_game_card.png")
    ok9, log9 = shot(p9, "screen=editor", "tab=deck", "card=Test Mortar Strike")
    ck("a card opened to read renders", ok9 and "SCRIPT ERROR" not in log9, log9[-300:])
    if ok9:
        # (0.14: the card itself on the left, large, as the Forge prints it: its District's colour round
        # its edge; beside it its kind in the kind's colour; and its copies to set)
        frame = count(p9, (78, 34, 432, 44), (240, 164, 87)) + count(p9, (78, 34, 86, 534), (240, 164, 87))
        kind = count(p9, (456, 84, 980, 104), COMMAND)
        copies = count(p9, (868, 640, 904, 678), GOLD)
        ck("0.14: the card itself, large, framed in its District's colour; its kind in the kind's colour; its copies to set", frame > 150 and kind > 40 and copies > 4, (frame, kind, copies))
    p10 = pathlib.Path("/tmp/keter_game_hand.png")
    ok10, log10 = shot(p10, "mode=team", "floor=TEST · Corridor", "troops=Test Drone", "taps=hand")
    ck("a Strike Team's Battle renders, the hand open", ok10 and "SCRIPT ERROR" not in log10, log10[-300:])
    if ok10:
        # (0.14: Aether as a gem for each point, in its District's colour; the hand as a fan of whole cards)
        gems = count(p10, (560, 12, 790, 54), (232, 138, 54), 12)
        wave = count(p10, (240, 18, 540, 46), DIM, 16)
        art = set((c[0] // 24, c[1] // 24, c[2] // 24) for c in colours(p10, (160, 490, 1120, 700))[1])
        fronts = count(p10, (160, 490, 1120, 700), (240, 164, 87))
        ck("the bar has the wave and this turn's Aether as gems; the tray shows the cards drawn, each printed whole", gems > 20 and wave > 40 and len(art) > 25 and fronts > 200, (gems, wave, len(art), fronts))
    p11 = pathlib.Path("/tmp/keter_game_phase.png")
    ok11, log11 = shot(p11, "mode=team", "floor=TEST · Corridor", "troops=Test Drone", "taps=go;phase:Draw")
    ck("the round's phases render as they play", ok11 and "SCRIPT ERROR" not in log11, log11[-300:])
    if ok11:
        frame = [c for c in colours(p11, (306, 78, 974, 90))[1] if near(c, GOLD)]
        px = Image.open(p11).convert("RGB").load()
        hand = len([1 for x in range(16, 160, 2) for y in range(662, 706, 2) if sum(px[x, y]) > 560])
        ck("the phase is named across the top in gold, and the Hand button waits below", len(frame) > 40 and hand > 20, (len(frame), hand))
    # playing cards
    def lit(px, x0, x1, y0, y1):
        return len([1 for x in range(x0, x1, 2) for y in range(y0, y1, 2) if sum(px[x, y]) > 560])
    # white lettering only (a button's label), not the blue of the Aether count
    def white(px, x0, x1, y0, y1):
        return len([1 for x in range(x0, x1, 2) for y in range(y0, y1, 2) if min(px[x, y]) > 200])
    p12 = pathlib.Path("/tmp/keter_game_play.png")
    ok12, log12 = shot(p12, "mode=team", "floor=TEST · Corridor", "troops=Test Drone", "taps=aether:9;hand:Test Snare,Test Scout;play:hand:0")
    ck("a card being played renders", ok12 and "SCRIPT ERROR" not in log12, log12[-300:])
    if ok12:
        px = Image.open(p12).convert("RGB").load()
        three = [lit(px, 16, 136, 662, 706), lit(px, 152, 334, 662, 706), lit(px, 350, 460, 662, 706)]
        ring = count(p12, (0, 70, 1280, 620), (239, 221, 145), 12)
        ck("Hand, Consumables and Chips along the bottom", all(n > 20 for n in three), three)
        ck("the Enemies it can go to are ringed, in pale gold, and End turn waits (greyed)", ring > 30 and end_turn(p12) == 0, (ring, end_turn(p12)))
    p13 = pathlib.Path("/tmp/keter_game_plain.png")
    # (0.24: no card is in plain text any more, so Burning Heart is given some for the shot)
    ok13, log13 = shot(p13, "mode=team", "floor=TEST · Corridor", "troops=Test Drone", "taps=aether:9;plain:Burning Heart;hand:Test Rally,Burning Heart,Test Scout;hand")
    ck("the hand with a plain-text card renders", ok13 and "SCRIPT ERROR" not in log13, log13[-300:])
    if ok13:
        # (0.14: three cards in the fan, side by side in the middle; the strip across the art window's corner)
        strip = [count(p13, (408 + 160 * k + 8, 540, 408 + 160 * k + 82, 556), GOLD) for k in (0, 1)]
        ck("a card in plain text wears its gold strip; one written with keywords doesn't", strip[0] == 0 and strip[1] > 30, strip)
    p14 = pathlib.Path("/tmp/keter_game_aim.png")
    ok14, log14 = shot(p14, "mode=team", "floor=TEST · Corridor", "troops=Test Drone", "taps=aether:9;hand:Test Mortar Strike;play:hand:0;6,0")
    ck("a card aimed at a tile renders its area before it is played", ok14 and "SCRIPT ERROR" not in log14, log14[-300:])
    if ok14:
        px = Image.open(p14).convert("RGB").load()
        # (0.14: the area is brought into view as it is lit; nothing to Undo yet, so no Undo)
        wash = count(p14, (0, 70, 1280, 620), (96, 76, 55), 10) + count(p14, (0, 70, 1280, 620), (122, 76, 49), 10)      # (0.15: or over District 3's deck)
        ck("the area is lit where it would land, and nothing is played yet", wash > 300 and end_turn(p14) == 0 and undo_icon(p14) == 0, (wash, end_turn(p14), undo_icon(p14)))
    p15 = pathlib.Path("/tmp/keter_game_played.png")
    ok15, log15 = shot(p15, "mode=team", "floor=TEST · Corridor", "troops=Test Drone", "taps=aether:9;hand:Test Mortar Strike,Test Rally;play:hand:0;6,0;6,0;wait:120")
    ck("a card played renders", ok15 and "SCRIPT ERROR" not in log15, log15[-300:])
    if ok15:
        # (0.14: Undo, an icon, between the Aether's gems and Auto; End turn gold again)
        gems = count(p15, (480, 12, 720, 54), (232, 138, 54), 12)
        ck("with Undo offered for it (the bar makes room), and End turn back", undo_icon(p15) > 15 and gems > 20 and end_turn(p15) > 300, (undo_icon(p15), gems, end_turn(p15)))
    p16 = pathlib.Path("/tmp/keter_game_cons.png")
    ok16, log16 = shot(p16, "screen=editor", "tab=consumables")
    ck("the builder's Consumables tab renders", ok16 and "SCRIPT ERROR" not in log16, log16[-300:])
    if ok16:
        # (0.14: whole printed cards; the strip across each art window's corner)
        strips = count(p16, (26, 280, 1140, 296), GOLD)
        chosen = count(p16, (500, 450, 1136, 458), CYAN)
        # (0.23: since the effect box audit no Consumable is in plain text, so none wears the strip)
        # (the cards' own gold edges along that line come to about 100; each strip added some 70 more)
        ck("no Consumable is in plain text now, so none wears the strip; the team's own outlined and counted", strips < 150 and chosen > 20, (strips, chosen))
    # 0.7: Districts cleared, Auto, the Behavior picker, X, and loot
    LOOT, XBLUE, GREEN = (239, 221, 145), (138, 161, 246), (89, 207, 147)
    def count(path, box, want, tol=26):
        px = Image.open(path).convert("RGB").load()
        return len([1 for x in range(box[0], box[2], 2) for y in range(box[1], box[3], 2) if near(px[x, y], want, tol)])
    p17 = pathlib.Path("/tmp/keter_game_districts.png")
    ok17, log17 = shot(p17, "mode=team", "step=troops", "floor=TEST · Waves", "districts=3")
    ck("setting up a Battle with Districts cleared renders", ok17 and "SCRIPT ERROR" not in log17 and "ERROR: String formatting" not in log17, log17[-300:])
    if ok17:
        ck("Dimensional Instability is spelled out along the bottom, in gold", count(p17, (180, 636, 1050, 704), GOLD) > 60, count(p17, (180, 636, 1050, 704), GOLD))
    p18 = pathlib.Path("/tmp/keter_game_auto.png")
    ok18, log18 = shot(p18, "mode=team", "floor=TEST · Corridor", "place=a1:-2,0", "taps=auto;-2,0")
    ck("a Battle with Auto on renders", ok18 and "SCRIPT ERROR" not in log18, log18[-300:])
    if ok18:
        px = Image.open(p18).convert("RGB").load()
        # (0.14: Auto is an icon, lit in cyan while it is on, beside the speed button)
        ck("the switch is lit, beside the speed button (0.12); End turn is there", count(p18, (775, 5, 834, 66), CYAN) > 40 and end_turn(p18) > 300 and lit(px, 850, 895, 14, 40) > 8, (count(p18, (775, 5, 834, 66), CYAN), end_turn(p18), lit(px, 850, 895, 14, 40)))      # (0.39: the buttons wider, with their words)
    p19 = pathlib.Path("/tmp/keter_game_behaviors.png")
    ok19, log19 = shot(p19, "mode=team", "floor=TEST · Corridor", "place=a1:-2,0", "taps=-2,0;beh;bk:decisive;bk:wary;wait:10")
    ck("the Behavior picker renders", ok19 and "SCRIPT ERROR" not in log19, log19[-300:])
    if ok19:
        ck("a chosen keyword is outlined and numbered, and the choice is summed up in gold", count(p19, (110, 186, 1170, 262), CYAN) > 400 and count(p19, (110, 88, 700, 112), GOLD) > 30, (count(p19, (110, 186, 1170, 262), CYAN), count(p19, (110, 88, 700, 112), GOLD)))
    p20 = pathlib.Path("/tmp/keter_game_x.png")
    ok20, log20 = shot(p20, "mode=team", "floor=TEST · Corridor", "taps=aether:6;hand:Test Swarm,Test Barrage,Test Capacitor,Test Drone Bank;hand;card:0;x:3")
    ck("a card with a variable cost, opened to choose X, renders", ok20 and "SCRIPT ERROR" not in log20, log20[-300:])
    if ok20:
        ck("X is there to step, and the card reads with it in place", count(p20, (686, 638, 724, 678), GOLD) > 8 and count(p20, (454, 234, 572, 260), GOLD) > 12, (count(p20, (686, 638, 724, 678), GOLD), count(p20, (454, 234, 572, 260), GOLD)))
    p21 = pathlib.Path("/tmp/keter_game_xaction.png")
    ok21, log21 = shot(p21, "mode=team", "carry=Test Overcharge", "floor=TEST · Corridor", "heroes=Test Warden;Quillon Vex", "place=a2:0,0;e1:2,0", "taps=aether:6;0,0;a:2;x:2")
    ck("a carried Action card asking for X renders", ok21 and "SCRIPT ERROR" not in log21, log21[-300:])
    if ok21:
        ck("its box names the Action and shows the X chosen", count(p21, (470, 232, 810, 272), XBLUE) > 120 and count(p21, (585, 295, 695, 338), GOLD) > 40, (count(p21, (470, 232, 810, 272), XBLUE), count(p21, (585, 295, 695, 338), GOLD)))
    p22 = pathlib.Path("/tmp/keter_game_loot.png")
    ok22, log22 = shot(p22, "mode=team", "floor=TEST · Loot", "place=a1:-2,5", "taps=-2,5;-2,4;wait:60;kill:e1;log")
    ck("loot found and dropped renders", ok22 and "SCRIPT ERROR" not in log22, log22[-300:])
    if ok22:
        ck("the count under the top bar, and in the Log what has dropped so far and each drop, all in pale yellow", count(p22, (10, 78, 300, 102), LOOT) > 25 and count(p22, (812, 148, 1270, 198), LOOT) > 80 and count(p22, (812, 425, 1270, 480), LOOT) > 120,
           (count(p22, (10, 78, 300, 102), LOOT), count(p22, (812, 148, 1270, 198), LOOT), count(p22, (812, 425, 1270, 480), LOOT)))
    p23 = pathlib.Path("/tmp/keter_game_spoils.png")
    ok23, log23 = shot(p23, "mode=team", "floor=TEST · Loot", "place=a1:-2,5", "taps=-2,5;-2,4;wait:60;kill:e1;win")
    ck("a Battle won on a floor with a reward renders", ok23 and "SCRIPT ERROR" not in log23, log23[-300:])
    if ok23:
        px = Image.open(p23).convert("RGB").load()
        words = len([1 for x in range(250, 1030, 2) for y in range(200, 440, 2) if sum(px[x, y]) > 640])
        # (0.15: Victory in gold neon; under it a strip of how it went; what dropped as tiles)
        NEON_GOLD = (248, 197, 58)
        ck("Victory, with what dropped, the floor's reward and the total under it", count(p23, (500, 60, 780, 128), NEON_GOLD, 12) > 300 and count(p23, (365, 143, 915, 178), CYAN, 12) > 100
           and count(p23, (365, 143, 915, 178), (255, 42, 60), 12) > 90 and words > 1500 and count(p23, (330, 495, 950, 580), GREEN, 12) > 120,
           (count(p23, (500, 60, 780, 128), NEON_GOLD, 12), count(p23, (365, 143, 915, 178), CYAN, 12), count(p23, (365, 143, 915, 178), (255, 42, 60), 12), words, count(p23, (330, 495, 950, 580), GREEN, 12)))
    # 0.8: the dock, the World Map and a deployment
    D3, D1, DOCK, TEAM_RING, SOFT_RED = (240, 164, 87), (169, 142, 240), (223, 232, 236), (115, 239, 232), (221, 136, 119)
    p24 = pathlib.Path("/tmp/keter_game_dock.png")
    ok24, log24 = shot(p24, "screen=dock")
    ck("0.8: the dock renders", ok24 and "SCRIPT ERROR" not in log24, log24[-300:])
    if ok24:
        px = Image.open(p24).convert("RGB").load()
        # (0.15: QM-7 over the tabs, its portrait, its name in orange and its line; the Stockpile under a cyan heading; Deploy in gold)
        portrait = len(set(px[x, y] for x in range(36, 160, 2) for y in range(94, 218, 2)))
        ck("0.8: QM-7 keeps it, the Stockpile's heading in cyan, the shards in pale yellow, and Deploy to press, in gold", portrait > 20 and count(p24, (178, 128, 420, 150), (232, 138, 54), 12) > 120 and lit(px, 180, 790, 162, 182) > 250
           and count(p24, (20, 250, 115, 272), CYAN, 12) > 90 and count(p24, (78, 302, 216, 322), LOOT, 12) > 100 and count(p24, (1040, 640, 1256, 696), GOLD, 10) > 1500 and lit(px, 856, 1022, 646, 690) > 100,
           (portrait, count(p24, (178, 128, 420, 150), (232, 138, 54), 12), lit(px, 180, 790, 162, 182), count(p24, (20, 250, 115, 272), CYAN, 12), count(p24, (78, 302, 216, 322), LOOT, 12), count(p24, (1040, 640, 1256, 696), GOLD, 10)))
    p25 = pathlib.Path("/tmp/keter_game_deploy.png")
    ok25, log25 = shot(p25, "screen=deploy")
    ck("0.8: choosing who goes out renders", ok25 and "SCRIPT ERROR" not in log25, log25[-300:])
    if ok25:
        ck("0.8: the Strike Team chosen is outlined, and said to be ready in gold; Leave the dock in gold", count(p25, (20, 220, 1260, 300), CYAN, 12) > 1300 and count(p25, (180, 650, 760, 690), GOLD, 12) > 350 and count(p25, (1040, 640, 1256, 696), GOLD, 10) > 1500,
           (count(p25, (20, 220, 1260, 300), CYAN, 12), count(p25, (180, 650, 760, 690), GOLD, 12), count(p25, (1040, 640, 1256, 696), GOLD, 10)))
    p26 = pathlib.Path("/tmp/keter_game_map.png")
    ok26, log26 = shot(p26, "screen=map", "map=sel:3,-2")
    ck("0.8: the World Map renders, a tile chosen", ok26 and "SCRIPT ERROR" not in log26, log26[-300:])
    if ok26:
        px = Image.open(p26).convert("RGB").load()
        districts = len(set((c[0] // 40, c[1] // 40, c[2] // 40) for c in colours(p26, (0, 110, 860, 716))[1]))
        ck("0.8: Districts in their colours round the team's marker, the way to the tile in white, and Walk here in the panel, the District's emblem by its name (0.15)", districts >= 8 and count(p26, (392, 356, 470, 434), TEAM_RING) > 30 and count(p26, (460, 230, 610, 400), (255, 255, 255), ) > 120
           and count(p26, (880, 90, 1250, 126), D1) > 40 and count(p26, (890, 330, 1250, 380), CYAN, 12) > 90 and count(p26, (884, 106, 920, 140), D1, 30) > 12,
           (districts, count(p26, (392, 356, 470, 434), TEAM_RING), count(p26, (460, 230, 610, 400), (255, 255, 255)), count(p26, (880, 90, 1250, 126), D1), count(p26, (890, 330, 1250, 380), CYAN, 12), count(p26, (884, 106, 920, 140), D1, 30)))
        # (0.11: who is standing and the haul as icons and numbers; the export's Health icon is a green cross)
        ck("0.8: the bar names the deployment, and under it who is standing and the haul, as icons and numbers", count(p26, (10, 14, 420, 56), CYAN) > 80 and count(p26, (14, 78, 46, 106), (109, 255, 58)) > 20 and count(p26, (180, 78, 250, 106), LOOT) > 3
           and count(p26, (50, 78, 180, 106), (230, 231, 240)) > 40 and lit(px, 1172, 1264, 12, 60) > 20, (count(p26, (10, 14, 420, 56), CYAN), count(p26, (14, 78, 46, 106), (109, 255, 58)), count(p26, (180, 78, 250, 106), LOOT), count(p26, (50, 78, 180, 106), (230, 231, 240))))
    p27 = pathlib.Path("/tmp/keter_game_mapfit.png")
    ok27, log27 = shot(p27, "screen=map", "map=known;fit")
    ck("0.8: the whole map renders, everything on it shown", ok27 and "SCRIPT ERROR" not in log27, log27[-300:])
    if ok27:
        cs27 = colours(p27, (60, 80, 800, 716))[1]
        ground = len([c for c in cs27 if sum(c) > 150])
        dark = len([c for c in cs27 if sum(c) < 60])
        ck("0.8: it fits beside the panel, with the dark beyond its edge", ground > 6000 and dark > 4000 and count(p27, (810, 300, 866, 500), D3) == 0, (ground, dark))
    p28 = pathlib.Path("/tmp/keter_game_event.png")
    ok28, log28 = shot(p28, "screen=map", "map=put:0,3")
    ck("0.8: an Event renders in the panel", ok28 and "SCRIPT ERROR" not in log28, log28[-300:])
    if ok28:
        ck("0.8: its title in gold, its first choice in cyan, and a second under it; District 3's emblem by the tile's name", count(p28, (880, 236, 1250, 258), GOLD, 12) > 190 and count(p28, (890, 362, 1250, 436), CYAN, 12) > 300 and lit(Image.open(p28).convert("RGB").load(), 900, 1240, 456, 500) > 70
           and count(p28, (884, 106, 920, 140), (232, 138, 54), 30) > 30, (count(p28, (880, 236, 1250, 258), GOLD, 12), count(p28, (890, 362, 1250, 436), CYAN, 12), lit(Image.open(p28).convert("RGB").load(), 900, 1240, 456, 500), count(p28, (884, 106, 920, 140), (232, 138, 54), 30)))
    p29 = pathlib.Path("/tmp/keter_game_ambush.png")
    ok29, log29 = shot(p29, "screen=map", "seed=7", "map=walk:-1,2")
    ck("0.8: an ambush on the way renders", ok29 and "SCRIPT ERROR" not in log29, log29[-300:])
    if ok29:
        ck("0.8: Ambush! in red at the head of the panel, and Fight under it", count(p29, (880, 130, 1250, 160), SOFT_RED) > 60 and count(p29, (890, 290, 1250, 336), CYAN) > 20, (count(p29, (880, 130, 1250, 160), SOFT_RED), count(p29, (890, 290, 1250, 336), CYAN)))
    p30 = pathlib.Path("/tmp/keter_game_depsetup.png")
    ok30, log30 = shot(p30, "screen=map", "seed=7", "map=walk:-1,2;do:fight")
    ck("0.8: a deployment fight's setup renders", ok30 and "SCRIPT ERROR" not in log30, log30[-300:])
    if ok30:
        ck("0.8: named for the ambush, the Heroes who enter outlined, one in reserve in gold", count(p30, (20, 14, 290, 58), CYAN) > 100 and count(p30, (20, 128, 1260, 300), CYAN) > 600 and count(p30, (1160, 328, 1250, 356), GOLD) > 20,
           (count(p30, (20, 14, 290, 58), CYAN), count(p30, (20, 128, 1260, 300), CYAN), count(p30, (1160, 328, 1250, 356), GOLD)))
    p31 = pathlib.Path("/tmp/keter_game_depwin.png")
    ok31, log31 = shot(p31, "screen=map", "seed=7", "map=walk:-1,2;do:fight;start;win")
    ck("0.8: a deployment's fight won renders", ok31 and "SCRIPT ERROR" not in log31, log31[-300:])
    if ok31:
        px = Image.open(p31).convert("RGB").load()
        words = len([1 for x in range(340, 940, 2) for y in range(190, 350, 2) if sum(px[x, y]) > 640])
        # (0.23: the box grows with what the haul says, so the title and the buttons are looked for where they may be)
        ck("0.8: Victory, what goes into the haul, and the way back to the map", count(p31, (500, 56, 780, 190), (248, 197, 58), 12) > 300 and words > 800 and lit(px, 440, 840, 540, 680) > 70, (count(p31, (500, 56, 780, 190), (248, 197, 58), 12), words, lit(px, 440, 840, 540, 680)))
    p32 = pathlib.Path("/tmp/keter_game_cameback.png")
    ok32, log32 = shot(p32, "screen=map", "map=put:0,2;do:cache;put:0,0;do:home;ok:0")
    ck("0.8: the dock after a deployment came home renders", ok32 and "SCRIPT ERROR" not in log32, log32[-300:])
    if ok32:
        px = Image.open(p32).convert("RGB").load()
        rows = len([1 for y in range(170, 600, 2) if near(px[640, y], (23, 24, 25), 6)])      # (0.11: a row is a panel of its own)
        ck("0.8: the stockpile lists what it brought, and the deployment is told below", count(p32, (78, 302, 216, 322), LOOT, 12) > 90 and rows > 90 and count(p32, (78, 358, 300, 450), (168, 186, 194), 12) > 150 and count(p32, (20, 566, 300, 612), (136, 163, 188), 12) > 200,   # (0.35: a cache gives four parts, so the rows below are the stash and the blueprints)
           (count(p32, (78, 302, 216, 322), LOOT, 12), rows, count(p32, (78, 358, 300, 450), (168, 186, 194), 12), count(p32, (20, 566, 300, 612), (136, 163, 188), 12)))
    # 0.9: the Workshop, a design, the keyword builder, research, and a Field copy
    MAKE = "tab:blueprints;testing;tab:designs;new;chassis:Test Frame · Lazarus Siege;build:0;kb:none;kb:target enemy;kb:next;kb:damage;step:1;kb:pv:ok;kb:next;kb:Burst;step:1"
    p33 = pathlib.Path("/tmp/keter_game_workshop.png")
    ok33, log33 = shot(p33, "screen=workshop")
    ck("0.9: the Workshop renders", ok33 and "SCRIPT ERROR" not in log33, log33[-300:])
    if ok33:
        px = Image.open(p33).convert("RGB").load()
        ck("0.9: Workshop in cyan, the starter's row with its free copies and its tag in gold, and New design to press", count(p33, (22, 28, 170, 62), CYAN) > 120 and count(p33, (1180, 192, 1250, 214), GOLD) > 20 and count(p33, (36, 234, 520, 252), GOLD) > 100 and lit(px, 1060, 1256, 640, 696) > 60,
           (count(p33, (22, 28, 170, 62), CYAN), count(p33, (1180, 192, 1250, 214), GOLD), count(p33, (36, 234, 520, 252), GOLD), lit(px, 1060, 1256, 640, 696)))
    p34 = pathlib.Path("/tmp/keter_game_chassis.png")
    ok34, log34 = shot(p34, "screen=workshop", "ws=tab:blueprints;testing;tab:designs;new")
    ck("0.9: choosing a chassis renders, everything unlocked", ok34 and "SCRIPT ERROR" not in log34, log34[-300:])
    if ok34:
        px = Image.open(p34).convert("RGB").load()
        bands = set(px[24, y] for y in range(130, 600, 10) if sum(px[24, y]) > 120)
        ck("0.9: five chassis, each banded in its District's colour, Back to go back, and the testing switch's note in gold", len(bands) >= 5 and lit(px, 22, 172, 640, 696) > 30 and count(p34, (186, 656, 690, 680), GOLD) > 120, (len(bands), lit(px, 22, 172, 640, 696), count(p34, (186, 656, 690, 680), GOLD)))
    p35 = pathlib.Path("/tmp/keter_game_design.png")
    ok35, log35 = shot(p35, "screen=workshop", "ws=" + MAKE + ";kb:pv:ok;kb:next;kb:insert")
    ck("0.9: a design renders, an effect built into it", ok35 and "SCRIPT ERROR" not in log35, log35[-300:])
    if ok35:
        # (0.15: the sentence large; on the right the design as its card beside its token, then the power bar)
        card35 = len(set(Image.open(p35).convert("RGB").load()[x, y] for x in range(1050, 1194, 2) for y in range(134, 336, 2)))
        ck("0.9: its sentence in its keywords' colours, its power bar, Fits in green, and what a copy costs in gold; and the design as its card", count(p35, (36, 460, 600, 490), KW_GOLD) > 160 and count(p35, (36, 460, 600, 490), KW_CYAN) > 200 and count(p35, (36, 460, 600, 490), KW_GREEN) > 110
           and count(p35, (874, 348, 1240, 360), CYAN) > 200 and count(p35, (874, 444, 1180, 462), GREEN) > 180 and count(p35, (874, 540, 1110, 556), GOLD) > 160 and card35 > 15,
           [count(p35, (36, 460, 600, 490), KW_GOLD), count(p35, (36, 460, 600, 490), KW_CYAN), count(p35, (36, 460, 600, 490), KW_GREEN), count(p35, (874, 348, 1240, 360), CYAN), count(p35, (874, 444, 1180, 462), GREEN), count(p35, (874, 540, 1110, 556), GOLD), card35])
    p36 = pathlib.Path("/tmp/keter_game_builder.png")
    ok36, log36 = shot(p36, "screen=workshop", "ws=" + MAKE + ";step:1")
    ck("0.9: the keyword builder renders, asking a number", ok36 and "SCRIPT ERROR" not in log36, log36[-300:])
    if ok36:
        ck("0.9: the sentence so far in colour, the number in cyan, and what the blueprint allows in gold", count(p36, (100, 96, 400, 118), KW_CYAN) > 60 and count(p36, (100, 96, 400, 118), KW_GOLD) > 40 and count(p36, (200, 308, 232, 342), CYAN) > 12 and count(p36, (362, 316, 580, 334), GOLD) > 45,
           [count(p36, (100, 96, 400, 118), KW_CYAN), count(p36, (100, 96, 400, 118), KW_GOLD), count(p36, (200, 308, 232, 342), CYAN), count(p36, (362, 316, 580, 334), GOLD)])
    p37 = pathlib.Path("/tmp/keter_game_review.png")
    ok37, log37 = shot(p37, "screen=workshop", "ws=" + MAKE + ";kb:pv:ok;kb:next")
    ck("0.9: the builder's review renders", ok37 and "SCRIPT ERROR" not in log37, log37[-300:])
    if ok37:
        px = Image.open(p37).convert("RGB").load()
        ck("0.9: each part with Change beside it, and Insert", count(p37, (1090, 220, 1180, 450), CYAN) > 60 and count(p37, (1060, 648, 1140, 678), CYAN) > 30 and lit(px, 220, 400, 225, 445) > 120,
           (count(p37, (1090, 220, 1180, 450), CYAN), count(p37, (1060, 648, 1140, 678), CYAN), lit(px, 220, 400, 225, 445)))
    p38 = pathlib.Path("/tmp/keter_game_research.png")
    ok38, log38 = shot(p38, "screen=workshop", "stock=0:90", "ws=grant:Burst:1;grant:Pierce:1;tab:blueprints;research:Burst")
    ck("0.9: research, asked, renders", ok38 and "SCRIPT ERROR" not in log38, log38[-300:])
    if ok38:
        px = Image.open(p38).convert("RGB").load()
        ck("0.9: the box asks in cyan, with Research and Not now", count(p38, (450, 270, 830, 310), CYAN) > 300 and lit(px, 454, 632, 398, 454) > 40 and lit(px, 648, 826, 398, 454) > 40, (count(p38, (450, 270, 830, 310), CYAN), lit(px, 454, 632, 398, 454), lit(px, 648, 826, 398, 454)))
    p39 = pathlib.Path("/tmp/keter_game_fieldcopy.png")
    ok39, log39 = shot(p39, "screen=deploy", "pick=1")
    ck("0.9: a team made before 0.9, chosen at the dock, renders", ok39 and "SCRIPT ERROR" not in log39, log39[-300:])
    if ok39:
        px = Image.open(p39).convert("RGB").load()
        ck("0.9: Field copy needed, said in gold which Troops, Field copy to press and Leave the dock greyed", count(p39, (1105, 336, 1246, 356), CYAN) > 90 and count(p39, (186, 618, 830, 698), GOLD) > 900 and lit(px, 856, 1022, 626, 694) > 80 and lit(px, 1040, 1256, 626, 694) == 0,
           (count(p39, (1105, 336, 1246, 356), CYAN), count(p39, (186, 618, 830, 698), GOLD), lit(px, 856, 1022, 626, 694), lit(px, 1040, 1256, 626, 694)))
    p40 = pathlib.Path("/tmp/keter_game_starter.png")
    ok40, log40 = shot(p40, "screen=workshop", "ws=edit:Frame Trooper")
    ck("0.9: the starter, opened, renders", ok40 and "SCRIPT ERROR" not in log40, log40[-300:])
    if ok40:
        px = Image.open(p40).convert("RGB").load()
        tok = len(set(px[x, y] for x in range(318, 336, 2) for y in range(532, 556, 2)))      # (0.15: its look's chip, under the Action)
        ck("0.9: why it can't be changed, in gold, and its look with its token drawn", count(p40, (22, 88, 980, 108), GOLD) > 300 and tok >= 8, (count(p40, (22, 88, 980, 108), GOLD), tok))
    # 0.10: the dock's tabs, the Pack, a bounty's tag, and a Testing box
    p41 = pathlib.Path("/tmp/keter_game_dock10.png")
    ok41, log41 = shot(p41, "screen=dock", "stock=0:120", "dock=give:Test Stim:2;pre:ds_pre_hornet:2;show")
    ck("0.10: the dock's Stockpile, with what it keeps, renders", ok41 and "SCRIPT ERROR" not in log41, log41[-300:])
    if ok41:
        px = Image.open(p41).convert("RGB").load()
        # (0.25: six tabs, Recruit among them, so the row starts further left)
        ck("0.10: the tabs along the top (0.34: seven, Craft among them), the Stockpile's lit in cyan (0.11); its headings in cyan, the shards in pale yellow, and what it keeps listed", lit(px, 466, 1258, 30, 60) > 300 and count(p41, (375, 16, 495, 72), CYAN) > 80 and count(p41, (507, 16, 633, 72), CYAN) == 0 and count(p41, (20, 250, 170, 455), CYAN) > 220      # (0.37: the Colony Rank's row under the shards)
           and count(p41, (78, 302, 236, 322), LOOT, 12) > 100 and lit(px, 30, 200, 477, 497) > 60 and lit(px, 30, 200, 549, 569) > 80, (lit(px, 466, 1258, 30, 60), count(p41, (375, 16, 495, 72), CYAN), count(p41, (507, 16, 633, 72), CYAN), count(p41, (20, 250, 170, 455), CYAN), count(p41, (78, 302, 236, 322), LOOT, 12), lit(px, 30, 200, 477, 497), lit(px, 30, 200, 549, 569)))
    p42 = pathlib.Path("/tmp/keter_game_exchange.png")
    ok42, log42 = shot(p42, "screen=dock", "stock=0:300", "dock=tab:exchange")
    ck("0.10: the Exchange renders", ok42 and "SCRIPT ERROR" not in log42, log42[-300:])
    if ok42:
        px = Image.open(p42).convert("RGB").load()
        # (0.15: tiles: each its picture, its price on a gold tag, Buy and Buy 5 in cyan; the shards held under the heading)
        ck("0.10: what it sells under cyan headings, as tiles: each its picture, its price in gold, and Buy", count(p42, (20, 250, 320, 505), CYAN) > 450 and count(p42, (146, 374, 310, 418), CYAN) > 60 and count(p42, (32, 374, 96, 422), GOLD, 12) > 80 and count(p42, (32, 318, 80, 364), GREEN, 16) > 70,
           (count(p42, (20, 250, 320, 505), CYAN), count(p42, (146, 374, 310, 418), CYAN), count(p42, (32, 374, 96, 422), GOLD, 12), count(p42, (32, 318, 80, 364), GREEN, 16)))
    # 0.25: the Recruit tab: Heroes on offer as tiles, each its token, its price in gold and Recruit; one recruited says so
    p425 = pathlib.Path("/tmp/keter_game_recruit.png")
    ok425, log425 = shot(p425, "screen=dock", "stock=0:900", "dock=strict;meet;restock;hire:Rictus;tab:recruit")
    ck("0.25: the Recruit tab renders", ok425 and "SCRIPT ERROR" not in log425, log425[-300:])
    if ok425:
        px = Image.open(p425).convert("RGB").load()
        ck("0.25: its tab lit in cyan; what it can't deploy said; Heroes on offer as tiles, each its token, its price in gold, and Recruit in cyan",
           count(p425, (645, 16, 753, 72), CYAN) > 80 and count(p425, (375, 16, 495, 72), CYAN) == 0 and count(p425, (20, 238, 1250, 282), (136, 163, 188)) > 600 and count(p425, (20, 306, 120, 330), CYAN) > 40
           and count(p425, (34, 512, 122, 554), GOLD, 16) > 60 and count(p425, (228, 512, 306, 552), CYAN) > 30 and len(set(px[x, y] for x in range(36, 76, 2) for y in range(390, 460, 2))) >= 6,
           (count(p425, (645, 16, 753, 72), CYAN), count(p425, (375, 16, 495, 72), CYAN), count(p425, (20, 238, 1250, 282), (136, 163, 188)), count(p425, (20, 306, 120, 330), CYAN), count(p425, (34, 512, 122, 554), GOLD, 16), count(p425, (228, 512, 306, 552), CYAN),
            len(set(px[x, y] for x in range(36, 76, 2) for y in range(390, 460, 2)))))
    p43 = pathlib.Path("/tmp/keter_game_bounties.png")
    ok43, log43 = shot(p43, "screen=dock", "dock=meet;restock;tab:bounties")
    ck("0.10: the Bounty Board renders", ok43 and "SCRIPT ERROR" not in log43, log43[-300:])
    if ok43:
        px = Image.open(p43).convert("RGB").load()
        ck("0.10: three bounties posted, each a row of its own, and nothing under them", all(lit(px, 30, 300, y, y + 22) > 60 for y in (248, 320, 392)) and lit(px, 30, 600, 460, 600) == 0, [lit(px, 30, 300, y, y + 22) for y in (248, 320, 392)])
    p44 = pathlib.Path("/tmp/keter_game_upgrades.png")
    ok44, log44 = shot(p44, "screen=dock", "stock=12:300", "dock=up:scanner:1;tab:upgrades")
    ck("0.10: the upgrades render", ok44 and "SCRIPT ERROR" not in log44, log44[-300:])
    if ok44:
        ck("0.10: four of them, each with its next level's price on a cyan chip", count(p44, (840, 140, 1250, 480), CYAN) > 400 and lit(Image.open(p44).convert("RGB").load(), 30, 330, 130, 450) > 400, count(p44, (840, 140, 1250, 480), CYAN))
    p45 = pathlib.Path("/tmp/keter_game_pack.png")
    ok45, log45 = shot(p45, "screen=dock", "dock=give:Test Stim:3;give:Test Aegis Core:1;pre:ds_pre_hornet:2;deploy;pick:0;pack:Test Stim:1")
    ck("0.10: Deploy with its Pack renders", ok45 and "SCRIPT ERROR" not in log45, log45[-300:])
    if ok45:
        ck("0.10: the team chosen outlined, the Pack under a cyan heading, and what it takes said in gold", count(p45, (20, 220, 1260, 300), CYAN) > 1300 and count(p45, (20, 406, 80, 428), CYAN) > 45 and count(p45, (180, 640, 1020, 694), GOLD) > 700,
           (count(p45, (20, 220, 1260, 300), CYAN), count(p45, (20, 406, 80, 428), CYAN), count(p45, (180, 640, 1020, 694), GOLD)))
    p46 = pathlib.Path("/tmp/keter_game_bounty.png")
    ok46, log46 = shot(p46, "screen=map", "seed=7", "dock=wantall", "map=walk:-1,2;do:fight;start;unit:e1")
    p46b = pathlib.Path("/tmp/keter_game_nobounty.png")
    ok46b, log46b = shot(p46b, "screen=map", "seed=7", "map=walk:-1,2;do:fight;start;unit:e1")
    ck("0.10: a deployment's fight with Enemies the Bounty Board wants renders", ok46 and ok46b and "SCRIPT ERROR" not in log46 + log46b, (log46 + log46b)[-300:])
    if ok46 and ok46b:
        # (0.11: gold, closely: an Enemy's own token can come near the palette's gold)
        def gold(path, box):
            px = Image.open(path).convert("RGB").load()
            return len([1 for x in range(box[0], box[2], 2) for y in range(box[1], box[3], 2) if near(px[x, y], GOLD, 12)])
        # (0.14: the diamond by each one's head; Bounty on the panel's second line, which wraps)
        ck("0.10: they wear gold diamonds, and the panel says Bounty in gold; with none wanted, neither", gold(p46, (380, 300, 720, 345)) > 12 and gold(p46b, (380, 300, 720, 345)) == 0 and gold(p46, (1000, 170, 1250, 225)) > 60 and gold(p46b, (1000, 170, 1250, 225)) == 0,
           (gold(p46, (380, 300, 720, 345)), gold(p46b, (380, 300, 720, 345)), gold(p46, (1000, 170, 1250, 225)), gold(p46b, (1000, 170, 1250, 225))))
    p47 = pathlib.Path("/tmp/keter_game_reset.png")
    ok47, log47 = shot(p47, "screen=dock", "dock=testing:reset")
    ck("0.10: Testing's Reset the dock, asked, renders", ok47 and "SCRIPT ERROR" not in log47, log47[-300:])
    if ok47:
        px = Image.open(p47).convert("RGB").load()
        ck("0.10: the box asks in red, says what it forgets, with Yes and Not now", count(p47, (500, 255, 780, 295), SOFT_RED) > 200 and lit(px, 360, 920, 310, 395) > 800 and lit(px, 454, 632, 412, 470) > 20 and lit(px, 648, 826, 412, 470) > 40,
           (count(p47, (500, 255, 780, 295), SOFT_RED), lit(px, 360, 920, 310, 395), lit(px, 454, 632, 412, 470), lit(px, 648, 826, 412, 470)))
    # 0.11: the look
    EDGE_HI, SUN, SUN_RIM, SHARD, SKULL, STRIPE = (64, 105, 119), (220, 175, 52), (214, 89, 29), (151, 237, 202), (232, 220, 196), (70, 56, 31)
    def kinds(path, box):
        px = Image.open(path).convert("RGB").load()
        return len(set(px[x, y] for x in range(box[0], box[2]) for y in range(box[1], box[3])))
    if ok7:
        px = Image.open(p7).convert("RGB").load()
        # (0.15: the night, its towers lit; the Nexus tower's beacon violet)
        ck("0.11: Home stands on the colony at night, its towers' windows lit, the tall tower's beacon on the right", count(p7, (0, 580, 1280, 700), (214, 168, 81), 30) > 30 and count(p7, (990, 150, 1070, 210), (169, 59, 239), 60) > 20,
           (count(p7, (0, 580, 1280, 700), (214, 168, 81), 30), count(p7, (990, 150, 1070, 210), (169, 59, 239), 60)))
        ck("0.11: a button is a pixel plate with its corners cut", not near(px[410, 480], EDGE_HI, 8) and near(px[412, 482], EDGE_HI, 8) and near(px[410, 490], EDGE_HI, 8) and near(px[414, 486], (44, 52, 56), 8), [px[410, 480], px[412, 482], px[410, 490], px[414, 486]])
    if ok3:
        ck("0.11: words with no smoothed edges: a line of text is its colour, its shadow and what is behind it", kinds(p3, (466, 296, 814, 312)) <= 6, kinds(p3, (466, 296, 814, 312)))
        # (0.15: what came in, as tiles: each its picture, large, its count and its name)
        # (0.23: as many tiles as kinds came in, centred, so the row is looked at whole)
        ck("0.11: the result adds up what the fight brought in, as icons and numbers", count(p3, (250, 400, 1030, 530), GREEN, 16) > 120 and count(p3, (250, 400, 1030, 530), LOOT, 16) > 20,
           (count(p3, (250, 400, 1030, 530), GREEN, 16), count(p3, (250, 400, 1030, 530), LOOT, 16)))
    if ok2:
        px = Image.open(p2).convert("RGB").load()
        # (0.16: under the turn strip)
        ck("0.11: the side panel's HP wears its icon: here the export's own, a green cross", count(p2, (890, 230, 930, 266), (109, 255, 58)) > 40, count(p2, (890, 230, 930, 266), (109, 255, 58)))
        ck("0.11: the bottom line sits on its dark bar", near(px[12, 712], (18, 18, 20), 6) and near(px[700, 712], (18, 18, 20), 6), (px[12, 712], px[700, 712]))
    if ok14:
        ck("0.11: the board stands on a deck plate in pixels, its seams and rivets dark and pale", kinds(p14, (5, 205, 60, 240)) >= 3 and count(p14, (5, 205, 60, 240), (22, 27, 32)) > 100 and count(p14, (5, 205, 60, 240), (31, 34, 41)) > 10,
           (kinds(p14, (5, 205, 60, 240)), count(p14, (5, 205, 60, 240), (22, 27, 32))))
    if ok24:
        ck("0.11: the dock stands on its hangar, the hazard stripe along its deck, dimmed", count(p24, (0, 664, 1280, 692), STRIPE) > 600, count(p24, (0, 664, 1280, 692), STRIPE))
    if ok26:
        ck("0.11: the map's panel gives the tile's Skull Level as the skull and its number", count(p26, (1200, 106, 1240, 140), SKULL) > 30, count(p26, (1200, 106, 1240, 140), SKULL))
    if ok31:
        ck("0.11: a deployment's Victory adds up the haul as icons too", count(p31, (330, 400, 950, 560), GREEN, 16) > 90, count(p31, (330, 400, 950, 560), GREEN, 16))
    # 0.12: shots of each kind caught in the air, and Options
    p48 = pathlib.Path("/tmp/keter_game_options.png")
    ok48, log48 = shot(p48, "screen=home", "options=1")
    ck("0.12: Options, over Home, renders", ok48 and "SCRIPT ERROR" not in log48, log48[-300:])
    if ok48:
        px = Image.open(p48).convert("RGB").load()
        # (0.15: and, from Home, the version and the export, with Look again)
        # (0.36: in two columns, the buttons higher)
        ck("0.12: Speed, Screen shake and Sound, each with its choice lit in cyan, and Close; from Home, the version and the export, and Look again", count(p48, (290, 120, 990, 600), CYAN) > 300 and lit(px, 758, 930, 575, 625) > 50
           and count(p48, (480, 510, 800, 563), DIM, 12) > 300 and lit(px, 350, 542, 575, 625) > 50, (count(p48, (290, 120, 990, 600), CYAN), lit(px, 758, 930, 575, 625), count(p48, (480, 510, 800, 563), DIM, 12), lit(px, 350, 542, 575, 625)))      # (0.39: a row more, Music)
        # (0.18: and Atmosphere, Subtle lit, under Speed)
        ck("0.18: Options has Atmosphere beside Speed (0.36), Subtle lit", count(p48, (932, 150, 1028, 196), CYAN) > 40 and count(p48, (818, 150, 914, 196), CYAN) < 10, (count(p48, (932, 150, 1028, 196), CYAN), count(p48, (818, 150, 914, 196), CYAN)))
    # each against the same moment before it fires: what is in the air is the difference
    def near_count(path, w, tol=20, box=(300, 70, 870, 690)):
        px = Image.open(path).convert("RGB").load()
        return len([1 for x in range(box[0], box[2], 2) for y in range(box[1], box[3], 2) if near(px[x, y], w, tol)])
    AIR = {"spray": ("Test Warden", "a:0", (115, 239, 232), 20), "bolt": ("Test Drone", "a:1", (241, 242, 255), 20), "beam": ("Test Overcharge", "a:0", (115, 239, 232), 50)}
    for kind, (who, act, col, least) in AIR.items():
        pk = pathlib.Path("/tmp/keter_game_air_%s.png" % kind)
        pa = pathlib.Path("/tmp/keter_game_aim_%s.png" % kind)
        okk, logk = shot(pk, "floor=TEST · Hazards and Cover", "stage=%s@0,4;!Test Grunt@3,1" % who, "sure=1", "motion=normal", "taps=0,4;%s;midair:0.5;3,1" % act, "after=12")
        oka, loga = shot(pa, "floor=TEST · Hazards and Cover", "stage=%s@0,4;!Test Grunt@3,1" % who, "sure=1", "motion=normal", "taps=0,4;%s" % act, "after=12")
        ck("0.12: a %s, caught in the air, renders" % kind, okk and oka and "SCRIPT ERROR" not in logk + loga, (logk + loga)[-300:])
        if okk and oka:
            ck("0.12: and is there between the shooter and the target, as its kind is drawn", near_count(pk, col) - near_count(pa, col) > least, (near_count(pk, col), near_count(pa, col)))
    p49 = pathlib.Path("/tmp/keter_game_air_shell.png")
    p49a = pathlib.Path("/tmp/keter_game_aim_shell.png")
    ok49, log49 = shot(p49, "floor=TEST · Hazards and Cover", "stage=Test Sapper@-1,4;!Test Grunt@1,2;!Test Grunt@2,2", "sure=1", "motion=normal", "taps=-1,4;a:0;1,2;midair:0.5;1,2", "after=12")
    ok49a, log49a = shot(p49a, "floor=TEST · Hazards and Cover", "stage=Test Sapper@-1,4;!Test Grunt@1,2;!Test Grunt@2,2", "sure=1", "motion=normal", "taps=-1,4;a:0;1,2", "after=12")
    if ok49 and ok49a:
        # (0.14: the deck plates use the shell's grey too: its pale top is the shell's alone)
        def every(path, w, box=(300, 70, 870, 690), tol=6):
            px = Image.open(path).convert("RGB").load()
            return len([1 for x in range(box[0], box[2]) for y in range(box[1], box[3]) if near(px[x, y], w, tol)])
        ck("0.12: a shell, in the air over the board: a grey ball where none was", every(p49, (179, 173, 162)) >= 8 and every(p49a, (179, 173, 162)) == 0, (every(p49, (179, 173, 162)), every(p49a, (179, 173, 162))))
    ck("0.12: a shell, caught in the air, renders", ok49 and "SCRIPT ERROR" not in log49, log49[-300:])
    # 0.13: a Unit guarded against a lock: a ring on the board, and Guarded in the side panel
    p50 = pathlib.Path("/tmp/keter_game_guard.png")
    p50a = pathlib.Path("/tmp/keter_game_unguarded.png")
    ok50, log50 = shot(p50, "floor=TEST · Hazards and Cover", "stage=Test Warden@0,4;!Test Grunt@3,1", "taps=3,1;guard:e1:stunned")
    ok50a, log50a = shot(p50a, "floor=TEST · Hazards and Cover", "stage=Test Warden@0,4;!Test Grunt@3,1", "taps=3,1")
    ck("0.13: a guarded Unit renders", ok50 and ok50a and "SCRIPT ERROR" not in log50 + log50a, (log50 + log50a)[-300:])
    if ok50 and ok50a:
        # (0.14: the guard is the lock's mark by the Unit's head, faded; in the panel, the guard's shield)
        def faded(path):
            px = Image.open(path).convert("RGB").load()
            return len([1 for x in range(775, 812) for y in range(362, 396) if px[x, y][0] > 100 and px[x, y][1] > 80 and px[x, y][0] - px[x, y][2] > 40 and abs(px[x, y][0] - px[x, y][1]) < 40])
        ck("0.13: its guard shows by its head, the Stun's mark faded, where there was none", faded(p50) >= 6 and faded(p50a) == 0, (faded(p50), faded(p50a)))
        ck("0.13: and the side panel says so, with the guard's shield", count(p50, (860, 60, 1280, 720), (69, 114, 227), 12) > 20 and count(p50a, (860, 60, 1280, 720), (69, 114, 227), 12) == 0, (count(p50, (860, 60, 1280, 720), (69, 114, 227), 12), count(p50a, (860, 60, 1280, 720), (69, 114, 227), 12)))
    # 0.14: the fight, drawn: master Units on a floor with cover and hazards, as a fight opens; and the Look board
    p51 = pathlib.Path("/tmp/keter_game_drawn.png")
    ok51, log51 = shot(p51, "floor=TEST · Hazards and Cover", "stage=ONYX Brute@-1,4;Arc Technician@-3,4;Quillon Vex@-2,3;!Arachnabot@1,2;!Exo Husk@2,1;!Chrome Junkie@0,1", "view=start", "taps=-1,4")
    ck("0.14: a fight of master Units renders, as a fight opens: the usual zoom, on your Units", ok51 and "SCRIPT ERROR" not in log51, log51[-300:])
    if ok51:
        board = colours2(p51, (0, 70, 880, 690))
        kinds51 = len(set((c[0] // 16, c[1] // 16, c[2] // 16) for c in board))
        ck("0.14: Units standing on the board as the game's drawings of them, among cover and hazards: many colours, the acid's among them",
           kinds51 > 70 and len([c for c in board if near(c, (89, 207, 147), 10)]) > 150, (kinds51, len([c for c in board if near(c, (89, 207, 147), 10)])))
        ck("0.14: each on a ring in its side's colour, cyan yours, red the Enemies', and the tiles the chosen one can reach lit in cyan",
           count(p51, (0, 70, 880, 690), (115, 239, 232), 10) > 60 and count(p51, (0, 70, 880, 690), (255, 42, 60), 10) > 30, (count(p51, (0, 70, 880, 690), (115, 239, 232), 10), count(p51, (0, 70, 880, 690), (255, 42, 60), 10)))
        portrait = len(set(c for c in colours2(p51, (906, 96, 996, 200))))
        ck("0.14: the side panel's portrait is the Unit's token, large", portrait > 12, portrait)
        # (0.15: a floor in District 3 stands on Vantage's own deck, brown plates and hazard stripes, not the grey one)
        ck("0.15: the fight stands on its District's floor: Vantage's brown deck plates, striped in black and yellow",
           len([c for c in board if near(c, (79, 52, 47), 8)]) > 1500 and len([c for c in board if near(c, (242, 194, 47), 30)]) > 20, (len([c for c in board if near(c, (79, 52, 47), 8)]), len([c for c in board if near(c, (242, 194, 47), 30)])))
    p52 = pathlib.Path("/tmp/keter_game_look.png")
    ok52, log52 = shot(p52, "screen=look")
    ck("0.14: the Look board renders", ok52 and "SCRIPT ERROR" not in log52, log52[-300:])
    if ok52:
        icons52 = len(set((c[0] // 16, c[1] // 16, c[2] // 16) for c in colours2(p52, (14, 480, 1260, 560))))
        ck("0.14: on it the type, the UI kit (the gold main button first) and every icon", count(p52, (18, 266, 164, 312), GOLD) > 300 and icons52 > 40 and count(p52, (14, 120, 300, 165), GOLD) > 100 and lit(Image.open(p52).convert("RGB").load(), 316, 760, 128, 160) > 50,
           (count(p52, (18, 266, 164, 312), GOLD), icons52, count(p52, (14, 120, 300, 165), GOLD)))
    # 0.16: the turn strip and End turn's hourglass; and the five effects, caught mid-play, against the same fight without them
    p60 = pathlib.Path("/tmp/keter_game_strip.png")
    ok60, log60 = shot(p60, "floor=TEST · Hazards and Cover", "stage=Test Warden@-2,3;Test Striker@0,2;!Test Grunt@-2,0", "view=start", "taps=-2,3")
    ck("0.16: a Unit of yours chosen renders, its turn strip in the panel", ok60 and "SCRIPT ERROR" not in log60, log60[-300:])
    if ok60:
        strip = (890, 180, 1270, 238)
        move60, aim60, eye60 = count(p60, strip, (138, 161, 246), 8), count(p60, strip, (241, 100, 31), 8), count(p60, strip, (241, 235, 219), 8)
        ck("0.16: under its name: Move's blue arrow, Attack's orange sight, Hold fire's eye", move60 > 8 and aim60 > 8 and eye60 > 8, (move60, aim60, eye60))
        glass60 = count(p60, (1118, 12, 1266, 54), (184, 204, 216), 8)
        ck("0.16: End turn, still gold, wears its hourglass", end_turn(p60) > 250 and glass60 > 4, (end_turn(p60), glass60))
    STAGE16 = "stage=Test Warden@0,0;Test Striker@1,0;!Test Grunt@3,0;!Test Grunt@5,0;!Test Grunt@-2,0"
    p61a = pathlib.Path("/tmp/keter_game_fx_none.png")
    p61 = pathlib.Path("/tmp/keter_game_fx.png")
    ok61a, log61a = shot(p61a, "floor=TEST · Corridor", STAGE16, "view=start", "motion=normal")
    ok61, log61 = shot(p61, "floor=TEST · Corridor", STAGE16, "view=start", "motion=normal", "after=6",
                       "taps=midair:0.4;area:5,0:1;fx:shield:3,0:body;fx:heal:1,0:feet;fx:impact:-2,0:body;fx:flash:0,0:body")
    ck("0.16: the fight's effects render, caught mid-play", ok61a and ok61 and "SCRIPT ERROR" not in log61 + log61a, (log61 + log61a)[-300:])
    if ok61 and ok61a:
        board16 = (0, 70, 1280, 690)
        def more(c, tol=10):
            return count(p61, board16, c, tol) - count(p61a, board16, c, tol)
        smoke, core = more((89, 87, 87)), more((241, 100, 31))
        shield, heal, gold = more((201, 212, 253)) + more((138, 161, 246)), more((151, 237, 202)) + more((89, 207, 147)), more((248, 197, 58)) + more((255, 240, 137))
        ck("0.16: an explosion on every tile of the blast, smoke round its fire", smoke > 150 and core > 20, (smoke, core))
        ck("0.16: a shield's blue hex, a heal's green, and the gold of an impact and a muzzle flash", shield > 40 and heal > 15 and gold > 30, (shield, heal, gold))
    # 0.17: card art, in the Team editor's Consumables (each at its pixels) and on a card's sheet (at twice them)
    p70 = pathlib.Path("/tmp/keter_game_cardart.png")
    p71 = pathlib.Path("/tmp/keter_game_cardsheet.png")
    ok70, log70 = shot(p70, "screen=editor", "tab=consumables")
    ok71, log71 = shot(p71, "screen=editor", "tab=consumables", "card=Field Dressing")
    ck("0.17: the Team editor's Consumables and a card's sheet render", ok70 and ok71 and "SCRIPT ERROR" not in log70 + log71, (log70 + log71)[-300:])
    if ok70 and ok71:
        deck = lambda box: (count(p70, box, (214, 168, 81), 8), count(p70, box, (69, 42, 27), 8))
        # (0.22: Test Stim two places on, after the Grav-Boot Charge and the Adrenal Overdrive)
        kit, sup, stim = deck((192, 300, 322, 370)), deck((352, 300, 482, 370)), deck((832, 520, 962, 590))
        ck("0.17: Repair Kit and Medical Supplies each show their picture, on Vantage's factory floor (its hazard band, its warm wall); Test Stim, the export's own art",
           kit[0] > 12 and kit[1] > 250 and sup[0] > 12 and sup[1] > 250 and stim == (0, 0), (kit, sup, stim))
        line, below = count(p71, (126, 150, 382, 162), (109, 255, 58), 10), count(p71, (126, 170, 382, 330), (109, 255, 58), 10)
        ck("0.17: on its sheet, Field Dressing wears the picture drawn over in the Companion, at twice its pixels (the green line two pixels deep)", line > 80 and below == 0, (line, below))
    # 0.18: a District 3 fight at Off and at Full: the acid glowing, embers in the air
    ST18 = "stage=Test Warden@-2,3;Test Striker@0,2;!Test Grunt@-2,0;!Test Grunt@1,-1"
    p80, p81 = pathlib.Path("/tmp/keter_game_atmos_off.png"), pathlib.Path("/tmp/keter_game_atmos_full.png")
    ok80, log80 = shot(p80, "floor=TEST · Hazards and Cover", ST18, "view=start", "atmos=off")
    ok81, log81 = shot(p81, "floor=TEST · Hazards and Cover", ST18, "view=start", "atmos=full")
    ck("0.18: a District 3 fight renders at Off and at Full", ok80 and ok81 and "SCRIPT ERROR" not in log80 + log81, (log80 + log81)[-300:])
    if ok80 and ok81:
        board18 = (0, 70, 1280, 690)
        embers = sum(count(p81, board18, c, 12) - count(p80, board18, c, 12) for c in [(255, 240, 137), (248, 197, 58), (255, 255, 255)])
        a80, a81 = Image.open(p80).convert("RGB"), Image.open(p81).convert("RGB")
        brighter = 0
        for x in range(0, 1280, 4):
            for y in range(70, 690, 4):
                q0, q1 = a80.getpixel((x, y)), a81.getpixel((x, y))
                if q1[1] > q0[1] + 12 and q1[0] >= q0[0] and q1[2] >= q0[2]:
                    brighter += 1
        ck("0.18: at Full, embers in the air and the hazards and pads glowing, where at Off there are none", embers > 60 and brighter > 600, (embers, brighter))
    # 0.19: leaving a fight in a pixel dissolve; Victory and Defeat powering on; a hand dealt from the Deck
    p90, p91, p92, p93 = (pathlib.Path("/tmp/keter_game_%s.png" % n) for n in ("dissolve", "victory", "defeat", "deal"))
    ok90, log90 = shot(p90, "floor=TEST · Hazards and Cover", ST18, "view=start", "motion=normal", "turns=1", "taps=home", "after=0", "freeze=0.18")
    ok91, log91 = shot(p91, "floor=TEST · Hazards and Cover", ST18, "view=start", "motion=normal", "taps=neon:win", "after=0", "freeze=1.6")
    ok92, log92 = shot(p92, "floor=TEST · Hazards and Cover", ST18, "view=start", "motion=normal", "taps=neon:lose", "after=0", "freeze=1.7")
    ok93, log93 = shot(p93, "mode=team", "floor=TEST · Hazards and Cover", "view=start", "motion=normal", "taps=hand", "after=0", "freeze=0.5")
    ck("0.19: a pixel dissolve, Victory, Defeat and a hand being dealt render mid-play", ok90 and ok91 and ok92 and ok93 and "SCRIPT ERROR" not in log90 + log91 + log92 + log93, (log90 + log91 + log92 + log93)[-300:])
    if ok90 and ok91 and ok92 and ok93:
        im90 = Image.open(p90).convert("RGB")
        # half the screen still the fight's deck, half Home already: brown blocks among Home's dark
        deck = count(p90, (0, 70, 1280, 690), (79, 52, 47), 10)
        ck("0.19: leaving a fight, it breaks up in blocks, Home showing through", 200 < deck < 60000, deck)
        sign = (300, 120, 980, 300)
        gold, red = count(p91, sign, (248, 197, 58), 30), count(p92, sign, (255, 42, 60), 40)
        ck("0.19: Victory lit in gold over the dimmed board; Defeat in red", gold > 400 and red > 150, (gold, red))
        left, right = count(p92, (300, 120, 640, 300), (255, 42, 60), 40), count(p92, (640, 120, 980, 300), (255, 42, 60), 40)
        ck("0.19: Defeat's right half dim", left > right * 2, (left, right))
        backs = count(p93, (0, 520, 1280, 720), (115, 239, 232), 12)
        ck("0.19: the hand dealt from its Deck: card backs, their cyan frames, among the cards", backs > 150, backs)
    # 0.20: a medium battlefield grown from the export's chunks, the whole board in view
    p100 = pathlib.Path("/tmp/keter_game_grown.png")
    ok100, log100 = shot(p100, "gen=medium:12345:2", "whole=1", "after=0")
    ck("0.20: a battlefield grown from chunks renders", ok100 and "SCRIPT ERROR" not in log100, log100[-300:])
    if ok100:
        px = Image.open(p100).convert("RGB").load()
        xs = [x for x in range(0, 1280, 4) for y in range(70, 690, 4) if near(px[x, y], (79, 52, 47), 10)]
        ck("0.20: its deck spread wide across the screen, five chunks of it", len(xs) > 2500 and max(xs) - min(xs) > 500, (len(xs), (min(xs), max(xs)) if xs else None))
else:
    print("(no virtual display here: the screens aren't rendered)")

# 4. the zip that goes to the phone
packed = make_game.make_zip("/tmp/keter_game_zip")
gz = zipfile.ZipFile(packed["file"])
names = gz.namelist()
size = pathlib.Path(packed["file"]).stat().st_size
ck("the game packs into one folder, KETER, named for its version", pathlib.Path(packed["file"]).name == make_game.tag() + "_KETER_game.zip" and names and all(n.startswith("KETER/") for n in names), names[:3])
ck("with the project, its scene, the README and every script", all(("KETER/" + n) in names for n in ["project.godot", "scenes/main.tscn", "README.md", "icon.png"])
   and all(("KETER/scripts/" + p.name) in names for p in (GAME / "scripts").glob("*.gd")), [n for n in names if "scripts" not in n][:12])
ck("0.8: the new scripts among them", all(("KETER/scripts/" + n) in names for n in ["world.gd", "deployment.gd", "progress.gd", "campaign.gd", "map_view.gd", "map_screen.gd", "dock_screen.gd"]))
ck("0.9: and the Workshop's", all(("KETER/scripts/" + n) in names for n in ["workshop.gd", "scoring.gd", "builder.gd", "skins.gd", "workshop_screen.gd", "design_editor.gd", "builder_sheet.gd"]) and all(("KETER/tests/" + n) in names for n in ["workshop_diff.gd", "soak_workshop.gd"]))
ck("0.10: and the dock's", "KETER/scripts/dock.gd" in names and "KETER/scripts/dock_screen.gd" in names and "KETER/tests/dock_diff.gd" in names)
ck("0.12: and the motion's", all(("KETER/scripts/" + n) in names for n in ["motion.gd", "sound.gd", "options_box.gd"]))
ck("0.11: and the look's: its scripts, and Jersey 10 with its licence", all(("KETER/scripts/" + n) in names for n in ["look.gd", "pixel_box.gd", "art.gd", "backdrop.gd", "info_back.gd"]) and "KETER/fonts/Jersey10-Regular.ttf" in names and "KETER/fonts/OFL.txt" in names
   and gz.getinfo("KETER/fonts/Jersey10-Regular.ttf").file_size > 50000, [n for n in names if "fonts" in n])
ck("the tests and the export they read, and none of the generated cases (90 MB of them)", "KETER/tests/fixtures/export.zip" in names and "KETER/tests/run_tests.gd" in names and "KETER/tests/world_diff.gd" in names
   and not any(n.endswith("_cases.json") for n in names) and not any("/.godot/" in n for n in names) and size < 3_000_000, (size, [n for n in names if n.endswith(".json")]))
ck("0.14: and the fight's: the printed card, the fan, the gems and the Look board; VT323 with its licence; the art's four sheets and art.json; and the scripts that draw them, which Godot ignores",
   all(("KETER/scripts/" + n) in names for n in ["card_face.gd", "card_fan.gd", "aether_gems.gd", "look_board.gd"]) and "KETER/fonts/VT323-Regular.ttf" in names and "KETER/fonts/OFL-VT323.txt" in names
   and all(("KETER/art/" + n) in names for n in ["tokens.png", "board.png", "icons.png", "cards.png", "art.json"]) and "KETER/tools/.gdignore" in names
   and all(("KETER/tools/art/" + n) in names for n in ["README.md", "build_art.py", "kart.py", "rigs.py", "units.py", "props.py", "tiles.py", "icons.py", "cards.py", "sample.py"])
   and not any("__pycache__" in n for n in names), [n for n in names if "/art/" in n or "tools" in n][:20])
ck("0.15: and the map's and the menus': QM-7's lines; the art's four new sheets; and the scripts that draw them",
   "KETER/scripts/qm7.gd" in names and all(("KETER/art/" + n) in names for n in ["ground.png", "map.png", "district.png", "menu.png"])
   and all(("KETER/tools/art/" + n) in names for n in ["hexpix.py", "mapart.py", "mapprops.py", "mapicons.py", "districts.py", "menus.py", "uiicons.py"]), [n for n in names if "/art/" in n][:30])
ck("0.16: and the effects': fx.png, and the script that draws them", "KETER/art/fx.png" in names and "KETER/tools/art/effects.py" in names, [n for n in names if "/art/" in n][:30])
ck("0.19: and the transitions, the scene and the card back: transition.gd, neon_scene.gd, cardback.png and cardback.py", all(n in names for n in ["KETER/scripts/transition.gd", "KETER/scripts/neon_scene.gd", "KETER/art/cardback.png", "KETER/tools/art/cardback.py"]), [n for n in names if "back" in n or "transition" in n or "neon" in n])
ck("0.20: and the chunks': chunk_gen.gd and chunk_diff.gd", "KETER/scripts/chunk_gen.gd" in names and "KETER/tests/chunk_diff.gd" in names, [n for n in names if "chunk" in n])
ck("0.18: and the atmosphere: atmos.gd", "KETER/scripts/atmos.gd" in names, [n for n in names if "/scripts/a" in n])
ck("0.17: and card art: cardart.png, and the script that draws it", "KETER/art/cardart.png" in names and "KETER/tools/art/cardart.py" in names, [n for n in names if "/art/" in n][:30])
readme = gz.read("KETER/README.md").decode()
ck("the README is this version's, and names the Companion it reads", ("**v%s keeps Dimensional\nInstability off" % make_game.game_version()) in readme and "Companion 13.5" in readme and "Companion 13.9" in readme and "Companion 14.0" in readme and "Companion 14.1" in readme and "Companion 14.2" in readme and "Companion\n14.3" in readme and "Companion 14.4" in readme and "Companion 14.5" in readme and "Companion 14.6" in readme and "Companion 14.7" in readme and "Companion 14.8" in readme and "Companion 14.9" in readme and "Companion 14.10" in readme and "Companion 14.11" in readme and "Companion 14.12" in readme and "Companion 14.13" in readme and "Companion 14.14" in readme and "Companion 14.15" in readme and "Companion 14.16" in readme and "Companion 14.17" in readme and "Companion 14.18" in readme and "Companion 14.19" in readme and "Companion 14.20" in readme and "Companion 14.21" in readme and "Companion 14.22" in readme and "Companion 14.23" in readme and "Companion 14.24" in readme and "Companion 14.25" in readme and "Companion 14.26" in readme
   and ("v0-%s_KETER_game.zip" % make_game.game_version().split(".")[1]) in readme, readme[:200])

print(f"\nGAME PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
