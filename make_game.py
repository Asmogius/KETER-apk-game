#!/usr/bin/env python3
"""The Godot game: its test export, and its release zip.

  python3 make_game.py fixture   # a real Export for Godot from the built Companion
                                 # (pwa/), saved as game/tests/fixtures/export.zip
  python3 make_game.py zip       # game/ as v<game version>_KETER_game.zip in the
                                 # outputs folder, without Godot's .godot cache
                                 # or the generated rule cases
  python3 make_game.py android   # (0.19) the game as an Android app, v<version>_KETER.apk,
                                 # with the Companion's export built in (see
                                 # game/tools/android/README.md for what it needs)

The game keeps its own version (config/version in game/project.godot), apart
from the Companion's.
"""
import sys, os, re, shutil, zipfile, pathlib, base64, functools, threading, http.server, socketserver

ROOT = pathlib.Path(__file__).resolve().parent
GAME = ROOT / "game"
OUTDIR = pathlib.Path("/mnt/user-data/outputs")


def game_version():
    m = re.search(r'config/version="([\d.]+)"', (GAME / "project.godot").read_text(encoding="utf-8"))
    return m.group(1) if m else "0.0"


def tag():
    return "v" + game_version().replace(".", "-")


def loot_floor():
    """A floor for the game's tests alone: Loot Tiles, two Locked Chests (one
    that says how much it holds) and a reward of its own. It is saved into the
    Companion's floor library before the test export is made, the way a floor
    of yours would be; the Companion itself does not ship it."""
    import make_test_maps as tm
    cells = tm.base()
    for q, r in ((-2, 4), (1, 3), (2, -2)):
        cells[tm.K(q, r)] = {"c": 2}
    sym = [{"id": 1, "text": "LC", "desc": "Locked Chest \u2014 always rewards loot"},
           {"id": 2, "text": "LC3", "desc": "Locked Chest holding 3 components"},
           {"id": 3, "text": "EX", "desc": "Emergency Exit \u2014 the only way out of a POI early"}]
    marks = [(tm.K(-3, 5), 1), (tm.K(3, 1), 2), (tm.K(-1, 5), 3)]
    f = tm.floor("TEST \u00b7 Loot", cells, [],
                 "Loot Tiles (yellow) at -2,4, 1,3 and 2,-2, and two Locked Chests: LC at -3,5 and LC3 (three components) at 3,1. "
                 "The first of your Units to end a move on one finds what it holds. Winning the floor pays its own reward as well. "
                 "EX at -1,5 is an Emergency Exit: on a deployment, inside a POI, a Hero who reaches it takes the Strike Team out.",
                 symdefs=sym, marks=marks)
    f["level"] = "2"
    f["loot"] = {"shards": 12, "lines": [{"kind": "exact", "n": 1, "type": "equipment", "rarity": 2},
                                         {"kind": "roll", "n": 2, "type": "any", "bonus": 1},
                                         {"kind": "item", "item": "bp:Burst:1", "chance": 50},
                                         {"kind": "item", "item": "ch:ch_test_verdant", "chance": 30},
                                         {"kind": "item", "item": "bp:Test Drone", "chance": 50}]}
    return f


# For the game's tests alone: what three of the test Enemies can leave behind.
# The Companion's own test cards carry none, so that its checklist reads as it did.
TEST_DROPS = {
    "Test Gunner": {"setDrops": [{"item": "bp:Marked:1", "chance": 25}]},
    "Test Hacker": {"lootPool": ["bp:Drained:1", "bp:Drained:2", "bp:Rooted:1"]},
    "Test Juggernaut": {"setDrops": [{"item": "ch:ch_test_threshold", "chance": 40}, {"item": "bp:Sundered:1", "chance": 60}], "lootPool": ["bp:Evasive:1"]},
}
# 0.12: what the test cards' Ranged Actions fire (the rest fire a bolt, the default)
TEST_PROJECTILES = {("Test Warden", "Pinning Volley"): "spray", ("Test Drone", "Rapid Fire"): "bolt", ("Test Sapper", "Satchel Charge"): "shell",
                    ("Test Gunner", "Long Shot"): "beam", ("Test Gunner", "Point Blank"): "spray", ("Test Overseer", "Arc Lash"): "beam",
                    ("Test Juggernaut", "Venom Spit"): "shell", ("Test Overcharge", "Overcharge"): "beam"}
# A fixed World Map, so the tests walk the same ground every time, and one
# Unique POI on it with floors and a reward of its own.
WORLD_SEED = 880088
UNIQUE = {"id": "uq_test_vault", "name": "Test Vault", "type": "Vault", "tile": None,
          "floors": ["TEST \u00b7 Loot", "TEST \u00b7 Corridor", "No such floor"],
          "reward": {"shards": 30, "n": 2, "type": "equipment", "bonus": 1, "bp": 50, "items": [{"item": "bp:Pierce:1", "chance": 100}, {"item": "bp:AoE:1", "chance": 35}]}}


# The test export's pre-built Troops (0.10): finished designs the dock's Exchange sells by the copy.
PREBUILTS = [
    {"id": "ds_pre_hornet", "name": "Hornet Mk I", "chassis": "ch_test_threshold",
     "abilities": [{"name": "Sting", "kind": "action", "role": "Ranged", "energy": 1, "range": 5, "hit": 7, "ap": 4, "text": "[[target enemy]] takes [[damage 2]] with [[Burst 3]]."}]},
    {"id": "ds_pre_bastion", "name": "Bastion Mk I", "chassis": "ch_test_verdant",
     "abilities": [{"name": "Mend", "kind": "action", "role": "Support", "energy": 1, "text": "[[target ally]] gains [[heal 3]]."},
                   {"name": "", "kind": "passive", "role": "", "text": "[[this Unit]] gains [[+1 AC]] for [[turns 2]]."}]},
]


def fixture(out=GAME / "tests" / "fixtures" / "export.zip", port=9959):
    """Serves the built Companion, asks it for its Export for Godot, and saves the zip."""
    from playwright.sync_api import sync_playwright
    tmp = pathlib.Path("/tmp/serve_gamefix")
    if tmp.exists():
        shutil.rmtree(tmp)
    shutil.copytree(ROOT / "pwa", tmp)
    import json
    comp = json.loads((ROOT / "compendium_full.json").read_text(encoding="utf-8"))
    for c in comp["cards"]:
        if c.get("name") in TEST_DROPS:
            c.update(TEST_DROPS[c["name"]])
        for e in c.get("entries") or []:
            if (c.get("name"), e.get("name")) in TEST_PROJECTILES:
                e["projectile"] = TEST_PROJECTILES[(c.get("name"), e.get("name"))]
    (tmp / "compendium.json").write_text(json.dumps(comp), encoding="utf-8")

    class H(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *a): pass

    class Q(socketserver.TCPServer):
        allow_reuse_address = True

    srv = Q(("127.0.0.1", port), functools.partial(H, directory=str(tmp)))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    try:
        with sync_playwright() as p:
            b = p.chromium.launch()
            pg = b.new_page()
            pg.goto(f"http://127.0.0.1:{port}/")
            pg.wait_for_timeout(2000)
            # one more floor, for the game's tests: saved as the Sandbox saves a floor
            pg.evaluate("""(m)=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}')||{}; all[m.name]=m;
              localStorage.setItem('keter-hexmap-levels', JSON.stringify(all)); }""", loot_floor())
            # the same World Map every time, and a Unique POI two steps from the dock
            placed = pg.evaluate("""(a)=>{ var W=KETER_WORLD, m=W.newMap(a.seed); m.made='2026-10-01T00:00:00.000Z'; W.setMap(m, false);
              var spot=Object.keys(m.tiles).filter(function(k){ return W.dist(k,m.dock)===2 && !m.tiles[k].c; }).sort()[0];
              a.unique.tile=spot; W.saveUniques([a.unique]); return spot; }""", {"seed": WORLD_SEED, "unique": UNIQUE})
            if not placed:
                raise SystemExit("the fixture's World Map has nowhere two steps from the dock for its Unique POI")
            # 0.10: two pre-built Troops, as Dev Mode makes them, for the dock's Exchange
            pg.evaluate("""(list)=>{ var WS=KETER_WORKSHOP; list.forEach(function(p,i){ p.prebuilt=true; p.order=i; p.notes=''; WS.put(p); }); }""", PREBUILTS)
            # 0.11: one of the game's icons drawn in its Game look slot (a green cross for Health),
            # so the tests see the game use yours in place of its own
            drawn = pg.evaluate("""()=>{ var A=KETER_ASSETS, PX=KETER_PX, id=A.newPicture('ui.icon.hp'); if(!id) return null;
              var p=PX.get(id), d=new Uint8Array(p.w*p.h);
              for(var y=1;y<15;y++) for(var x=1;x<15;x++){ var arm=(x>=5&&x<=10&&y>=2&&y<=13)||(y>=5&&y<=10&&x>=2&&x<=13),
                near=(x>=4&&x<=11&&y>=1&&y<=14)||(y>=4&&y<=11&&x>=1&&x<=14); d[y*p.w+x]=arm?133:(near?128:0); }
              p.frames[0].layers[0].px=PX.encode(d); PX.put(p,id); return {id:id, colour:PX.PALETTE[133]}; }""")
            if not drawn:
                raise SystemExit("the fixture couldn't draw its Health icon")
            # 0.14: the game's own crate, from its slot in The fight, drawn over (a green line
            # across its top), so the tests see the game use yours in place of its own; the
            # rest of the game's art, nobody having drawn on it, stays out of the export
            crate = pg.evaluate("""()=>{ var A=KETER_ASSETS, PX=KETER_PX, id=A.ids('fight.crate')[0]; if(!id) return null;
              var p=PX.get(id), d=PX.decode(p.frames[0].layers[0].px, p.w*p.h);
              for(var x=4;x<28;x++) d[2*p.w+x]=133;
              p.frames[0].layers[0].px=PX.encode(d); delete p.shipped; PX.put(p,id);
              return {id:id, mine:!A.gamesOwn(PX.get(id)), linked:!!PX.pictureFor({id:'D3-T21', name:'Aether Battery'},'token')}; }""")
            if not crate or not crate["mine"] or not crate["linked"]:
                raise SystemExit("the fixture's Companion didn't have the game's art in place: %s" % crate)
            # 0.15: District 3's Half Cover, from its slot in District fights, drawn over (a green line
            # across its top); and one of District 2's four tiles of ground, a green hex pixel at its
            # middle: the export carries the cover, and all four of District 2's ground (a slot of
            # several goes whole), for the tests to see the game use them
            d15 = pg.evaluate("""()=>{ var A=KETER_ASSETS, PX=KETER_PX, out={};
              var id=A.ids('fight.d3.half_cover')[0];
              if(id){ var p=PX.get(id), d=PX.decode(p.frames[0].layers[0].px, p.w*p.h);
                for(var x=8;x<40;x++) d[3*p.w+x]=133;
                p.frames[0].layers[0].px=PX.encode(d); delete p.shipped; PX.put(p,id); out.cover=!A.gamesOwn(PX.get(id)); }
              var gs=A.ids('map.ground.2');
              if(gs.length===4){ var q=PX.get(gs[0]), e=PX.decode(q.frames[0].layers[0].px, q.w*q.h);
                e[8*q.w+8]=133; q.frames[0].layers[0].px=PX.encode(e); delete q.shipped; PX.put(q,gs[0]); out.ground=gs.length; out.mine=!A.gamesOwn(PX.get(gs[0])); }
              return out; }""")
            if not d15.get("cover") or d15.get("ground") != 4 or not d15.get("mine"):
                raise SystemExit("the fixture's Companion didn't have the game's 0.15 art in place: %s" % d15)
            # 0.16: the game's impact, from its slot in Effects, drawn over: a green pixel in the
            # middle of its third frame, played at 10 a second; the export carries its five frames
            # side by side, saying how many and how fast, for the tests to see the game play yours
            d16 = pg.evaluate("""()=>{ var A=KETER_ASSETS, PX=KETER_PX, out={};
              var id=A.ids('fight.fx.impact')[0];
              if(id){ var p=PX.get(id), d=PX.decode(p.frames[2].layers[0].px, p.w*p.h);
                d[16*p.w+16]=133; p.frames[2].layers[0].px=PX.encode(d); p.fps=10; delete p.shipped; PX.put(p,id);
                out.frames=PX.frameCount(PX.get(id)); out.mine=!A.gamesOwn(PX.get(id)); }
              out.act=['act_move','act_attack','act_end'].every(function(k){ return A.ids('ui.icon.'+k).length===1; });
              return out; }""")
            if d16.get("frames") != 5 or not d16.get("mine") or not d16.get("act"):
                raise SystemExit("the fixture's Companion didn't have the game's 0.16 art in place: %s" % d16)
            # 0.17: the game's art for Field Dressing (a card of no id), linked to the card, drawn over
            # (a green line across its top); the export carries it as that card's art. The Aether
            # battery card (D3-AE08) has the game's own art; the Aether Battery Unit (D3-T21) has none
            d17 = pg.evaluate("""()=>{ var A=KETER_ASSETS, PX=KETER_PX, out={};
              var p=PX.pictureFor({name:'Field Dressing'},'art');
              if(p){ var d=PX.decode(p.frames[0].layers[0].px, p.w*p.h);
                for(var x=10;x<118;x++) d[2*p.w+x]=133;
                p.frames[0].layers[0].px=PX.encode(d); var id=p.id; delete p.shipped; PX.put(p,id); out.size=[p.w,p.h]; out.mine=!A.gamesOwn(PX.get(id)); }
              var ab=PX.pictureFor({id:'D3-AE08', name:'Aether battery'},'art');
              out.battery=!!(ab && A.gamesOwn(ab)); out.unit=!PX.pictureFor({id:'D3-T21', name:'Aether Battery'},'art');
              out.n=(KETER_ART.arts||[]).filter(function(t){ return !!PX.pictureFor({id:t[0]||null, name:t[1]},'art'); }).length;
              return out; }""")
            if not d17.get("mine") or d17.get("size") != [128, 90] or not d17.get("battery") or not d17.get("unit") or d17.get("n") != 93:   # (0.24: 97, less the four cards withdrawn)
                raise SystemExit("the fixture's Companion didn't have the game's 0.17 card art in place: %s" % d17)
            # 0.18: the atmosphere's ash, from its slot in Effects, drawn over (a green pixel in its
            # second frame); the export carries its three frames side by side, for the game to drift
            d18 = pg.evaluate("""()=>{ var A=KETER_ASSETS, PX=KETER_PX, out={};
              var id=A.ids('fight.fx.ash')[0];
              if(id){ var p=PX.get(id), d=PX.decode(p.frames[1].layers[0].px, p.w*p.h);
                d[4*p.w+4]=133; p.frames[1].layers[0].px=PX.encode(d); delete p.shipped; PX.put(p,id);
                out.frames=PX.frameCount(PX.get(id)); out.mine=!A.gamesOwn(PX.get(id)); }
              out.motes=['ember','spark','ash','dust'].every(function(k){ return A.ids('fight.fx.'+k).length===1; });
              return out; }""")
            if d18.get("frames") != 3 or not d18.get("mine") or not d18.get("motes"):
                raise SystemExit("the fixture's Companion didn't have the game's 0.18 motes in place: %s" % d18)
            # 0.19: the card back, from its slot in Game look, drawn over (a green line across its top)
            d19 = pg.evaluate("""()=>{ var A=KETER_ASSETS, PX=KETER_PX, out={};
              var id=A.ids('ui.card.back')[0];
              if(id){ var p=PX.get(id), d=PX.decode(p.frames[0].layers[0].px, p.w*p.h);
                for(var x=10;x<65;x++) d[3*p.w+x]=133;
                p.frames[0].layers[0].px=PX.encode(d); delete p.shipped; PX.put(p,id); out.size=[p.w,p.h]; out.mine=!A.gamesOwn(PX.get(id)); }
              return out; }""")
            if d19.get("size") != [75, 105] or not d19.get("mine"):
                raise SystemExit("the fixture's Companion didn't have the game's 0.19 card back in place: %s" % d19)
            r = pg.evaluate("""()=>{ var z=KETER_ASSETS.build(); var s='';
              for(var i=0;i<z.bytes.length;i+=8192) s+=String.fromCharCode.apply(null, z.bytes.subarray(i,i+8192));
              return {b64:btoa(s), n:z.count, c:z.content}; }""")
            b.close()
    finally:
        srv.shutdown()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(base64.b64decode(r["b64"]))
    return {"file": str(out), "graphics": r["n"], "content": r["c"], "icon": drawn, "crate": crate, "d15": d15, "d16": d16, "d17": d17, "d18": d18, "d19": d19}


# The generated cases (rules, simulator and World Map) are for testing here,
# not for the phone: 90 MB between them.
GENERATED = ("rule_cases.json", "sim_cases.json", "world_cases.json", "workshop_cases.json", "dock_cases.json", "chunk_cases.json")


def make_zip(outdir=None):
    outdir = pathlib.Path(outdir) if outdir else OUTDIR
    shutil.copy(ROOT / "pwa" / "icon-192.png", GAME / "icon.png")
    outdir.mkdir(parents=True, exist_ok=True)
    out = outdir / f"{tag()}_KETER_game.zip"
    n = 0
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for p in sorted(GAME.rglob("*")):
            rel = p.relative_to(GAME)
            if p.is_dir() or rel.parts[0] == ".godot" or p.name in GENERATED or "__pycache__" in rel.parts or rel.parts[:3] == ("tools", "art", "out"):
                continue
            z.write(p, "KETER/" + str(rel))
            n += 1
    return {"file": str(out), "files": n}


# ---------------------------------------------------------------- (0.19) the Android app
GODOT = os.environ.get("GODOT", "/home/claude/tools/Godot_v4.7.2-stable_linux.x86_64")
KEY_PASS = "keterketer"          # the app's own signing key: the same every build, so a new one installs over the old


def built_in_export(out, port=9961):
    """A plain Export for Godot from the built Companion, as it ships (its test floors, the
    master cards, the World Map; nobody's drawings): the export the app plays until it may
    read yours."""
    from playwright.sync_api import sync_playwright
    tmp = pathlib.Path("/tmp/serve_builtin")
    if tmp.exists():
        shutil.rmtree(tmp)
    shutil.copytree(ROOT / "pwa", tmp)
    shutil.copy(ROOT / "compendium_full.json", tmp / "compendium.json")

    class H(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *a): pass

    class Q(socketserver.TCPServer):
        allow_reuse_address = True

    srv = Q(("127.0.0.1", port), functools.partial(H, directory=str(tmp)))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    try:
        with sync_playwright() as p:
            b = p.chromium.launch()
            pg = b.new_page()
            pg.goto(f"http://127.0.0.1:{port}/")
            pg.wait_for_timeout(2000)
            r = pg.evaluate("""()=>{ var z=KETER_ASSETS.build(); var s='';
              for(var i=0;i<z.bytes.length;i+=8192) s+=String.fromCharCode.apply(null, z.bytes.subarray(i,i+8192));
              return {b64:btoa(s), n:z.count}; }""")
            b.close()
    finally:
        srv.shutdown()
    pathlib.Path(out).write_bytes(base64.b64decode(r["b64"]))
    return r["n"]


PRESET = """[preset.0]

name="Android"
platform="Android"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="exports/*.zip"
exclude_filter="tests/*, tools/*"
export_path="KETER.apk"
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false

[preset.0.options]

custom_template/debug=""
custom_template/release=""
gradle_build/use_gradle_build=false
gradle_build/export_format=0
architectures/armeabi-v7a=true
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
keystore/debug=""
keystore/debug_user=""
keystore/debug_password=""
keystore/release="{keystore}"
keystore/release_user="keter"
keystore/release_password="{password}"
version/code={code}
version/name="{name}"
package/unique_name="com.keter.game"
package/name="KETER"
package/signed=true
package/app_category=2
package/retain_data_on_uninstall=false
package/exclude_from_recents=false
package/show_in_android_tv=false
package/show_in_app_library=true
package/show_as_launcher_app=false
launcher_icons/main_192x192="res://icon.png"
launcher_icons/adaptive_foreground_432x432=""
launcher_icons/adaptive_background_432x432=""
graphics/opengl_debug=false
xr_features/xr_mode=0
screen/immersive_mode=true
screen/support_small=true
screen/support_normal=true
screen/support_large=true
screen/support_xlarge=true
user_data_backup/allow=false
command_line/extra_args=""
apk_expansion/enable=false
permissions/custom_permissions=PackedStringArray()
permissions/manage_external_storage=true
permissions/read_external_storage=true
permissions/vibrate=true
"""


def make_android(outdir=None):
    """The game as an Android app: a copy of game/ with the built-in export in exports/, signed
    with the app's key, exported by Godot (no Gradle). Needs Godot's 4.7 export templates and an
    Android SDK with apksigner (ANDROID_SDK, or the editor's setting)."""
    outdir = pathlib.Path(outdir) if outdir else OUTDIR
    outdir.mkdir(parents=True, exist_ok=True)
    work = pathlib.Path("/tmp/keter_android")
    if work.exists():
        shutil.rmtree(work)
    proj = work / "KETER"
    shutil.copy(ROOT / "pwa" / "icon-192.png", GAME / "icon.png")
    shutil.copytree(GAME, proj, ignore=shutil.ignore_patterns(".godot", "__pycache__", "out", *GENERATED))
    # Android wants its textures importable as ETC2/ASTC too (the pixel art itself stays lossless)
    pg = (proj / "project.godot").read_text(encoding="utf-8")
    if "import_etc2_astc" not in pg:
        pg = pg.replace("[rendering]\n", "[rendering]\n\ntextures/vram_compression/import_etc2_astc=true\n", 1)
        (proj / "project.godot").write_text(pg, encoding="utf-8")
    (proj / "exports").mkdir(exist_ok=True)
    n = built_in_export(proj / "exports" / "KETER_export_0000_built_in.zip")
    ks = work / "keter_release.keystore"
    ks.write_bytes(base64.b64decode((GAME / "tools" / "android" / "keter_release.keystore.b64").read_text()))
    v = game_version()
    code = int(v.split(".")[0]) * 1000 + int(v.split(".")[1])
    (proj / "export_presets.cfg").write_text(PRESET.format(keystore=str(ks), password=KEY_PASS, code=code, name=v), encoding="utf-8")
    sdk = os.environ.get("ANDROID_SDK")
    if sdk:
        es = pathlib.Path.home() / ".config" / "godot" / "editor_settings-4.7.tres"
        if es.exists():
            t = es.read_text(encoding="utf-8")
            t = re.sub(r'export/android/android_sdk_path = ".*"', 'export/android/android_sdk_path = "%s"' % sdk, t)
            es.write_text(t, encoding="utf-8")
    import subprocess
    subprocess.run([GODOT, "--headless", "--path", str(proj), "--import"], capture_output=True, text=True, timeout=600)
    apk = outdir / f"{tag()}_KETER.apk"
    r = subprocess.run([GODOT, "--headless", "--path", str(proj), "--export-release", "Android", str(apk)], capture_output=True, text=True, timeout=900)
    if r.returncode != 0 or not apk.exists():
        raise SystemExit("the Android export failed:\n" + (r.stdout + r.stderr)[-3000:])
    sig = pathlib.Path(str(apk) + ".idsig")      # (a v4 signature some signers leave beside it: not needed to install)
    if sig.exists():
        sig.unlink()
    return {"file": str(apk), "bytes": apk.stat().st_size, "export_files": n}


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else ""
    if what == "fixture":
        print(fixture())
    elif what == "zip":
        print(make_zip())
    elif what == "android":
        print(make_android(sys.argv[2] if len(sys.argv) > 2 else None))
    else:
        print(__doc__)
