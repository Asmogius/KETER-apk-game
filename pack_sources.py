#!/usr/bin/env python3
"""Bundle the sources and tests into a handful of files for Project Knowledge.

One file was too large to open on an older phone, and thirty was too many to
delete one at a time. Five is the compromise: each part is small enough to
render and few enough to replace quickly.
"""
import glob, os, json, re

OUTDIR = "/mnt/user-data/outputs"

def app_version():
    with open("build.py", encoding="utf-8") as fh:
        m = re.search(r'APP_VERSION\s*=\s*"([\d.]+)"', fh.read())
    return ("v" + m.group(1).replace(".", "-")) if m else "v0-0"

VER = app_version()
TAG = "@@" + "@@@ KETER-FILE"          # split so the example below cannot self-match
MARK = "\n\n" + TAG + ": %s " + TAG + "\n\n"

PARTS = [
    ("1_shell",     "App shell",       ["shell.html"]),
    ("2_forge",     "Card Forge",      ["forge_v3.html"]),
    ("3_sandbox",   "POI Sandbox",     ["poi_v19.html"]),
    ("4_rules_docs","Rules and docs",  ["rules.js", "scoring.js", "keywords.js", "pixelart.js", "studio.js", "test_chassis.js", "chassis_ui.js", "chassis.js", "builder.js", "loot.js", "loot_ui.js", "progress.js", "workshop.js", "workshop_ui.js", "codex_ui.js", "world.js", "deploy.js", "world_ui.js", "dock.js", "dock_ui.js", "skins.js", "assets.js", "studio_tabs.js", "convert_effects.py", "convert_154.py", "convert_rework.py", "convert_158.py", "make_test_cards.py", "make_batch1.py", "make_test_maps.py", "make_chunks.py", "keter_chunks.js", "make_frames.py", "keter_frames.js", "audit_effects/apply_audit.py", "audit_effects/conv.py", "audit_effects/drafts.py", "audit_effects/apply_audit2.py", "audit_effects/conv2.py", "audit_effects/new_keywords.js", "audit_effects/keyword_decisions.md", "chunkgen.js", "make_chunk_cases.js", "compendium_version.json", "test_maps.js", "test_pictures.js", "test_pictures_old_marks.json", "make_test_art.js", "make_test_art.py", "make_art_pack.py", "playtest/playtest.py", "playtest/checklist.py", "playtest/run.sh", "run_batch.sh", "build.py", "pack_sources.py", "add_entry.py", "make_game.py", "make_rule_cases.js", "make_sim_cases.js", "make_world_cases.js", "make_workshop_cases.js", "make_dock_cases.js", "guides.sh",
                                        "handbook_v14-0.md", "forge_guide.md",
                                        "poi_guide.md", "datapad_guide.md",
                                        "simulator_guide.md", "deck_guide.md", "studio_guide.md", "loot_guide.md", "workshop_guide.md", "world_guide.md", "dock_guide.md",
                                        "compendium_full.json",
                                        "whatsnew.md", "changelog.md"]),
    ("5_tests",     "Verification suites", sorted(glob.glob("verify_*.py"))),
    # the Godot game: its text files (the icon and the test export are rebuilt by make_game.py;
    # its typefaces in fonts/ and its art's sheets in art/ are binary and come from the game zip),
    # with art/art.json and the scripts that draw the art (tools/art, which Godot ignores)
    ("6_game",      "The Godot game",  sorted(str(p) for p in __import__("pathlib").Path("game").rglob("*")
                                              if p.is_file() and ".godot" not in p.parts and "__pycache__" not in p.parts and "out" not in p.parts
                                              and p.parts[:2] != ("game", "tests")
                                              and (p.suffix in (".gd", ".tscn", ".godot", ".md", ".cfg", ".uid", ".import", ".txt")
                                                   or str(p) in ("game/art/art.json", "game/tools/.gdignore")
                                                   or (p.suffix in (".py", ".b64") and p.parts[:2] == ("game", "tools"))))),
    # (0.16) the game's tests, a part of their own: like the Companion's suites (part 5), they
    # stay out of Project Knowledge (their export and generated cases are rebuilt, as before)
    ("7_game_tests", "The Godot game's tests", sorted(str(p) for p in __import__("pathlib").Path("game/tests").glob("*")
                                              if p.is_file() and p.suffix in (".gd", ".uid"))),
]
def game_version():
    m = re.search(r'config/version="([\d.]+)"', open("game/project.godot", encoding="utf-8").read())
    return ("v" + m.group(1).replace(".", "-")) if m else "v0-0"
GAME_VER = game_version()
def ver_of(slug): return GAME_VER if slug in ("6_game", "7_game_tests") else VER

SPLITTER = """**To split any part back into files**, save it and run:

```python
import re, pathlib
tag = "@@" + "@@@ KETER-FILE"
pat = re.escape(tag) + r": (.+?) " + re.escape(tag) + r"\\n(.*?)(?=\\n" + re.escape(tag) + r": |\\Z)"
text = pathlib.Path("THIS_FILE.md").read_text(encoding="utf-8")
for name, body in re.findall(pat, text, re.S):
    pathlib.Path(name).write_text(body.strip("\\n") + "\\n", encoding="utf-8")
    print("wrote", name)
```

Split every part into the same folder, then `python3 build.py` rebuilds
`pwa/index.html`. The guides need `pandoc` first: `./guides.sh` converts whichever have changed.
"""

# Every source the build reads, or that regenerates something the build reads,
# must be bundled. Additions to the lists above were once made by matching text
# that had since changed, so they silently failed and three files went missing
# from two releases. Now a missing one stops the packing.
_bundled = set(f for _, _, fs in PARTS for f in fs)
_needed = [f for f in glob.glob("*.js") + glob.glob("*.py") + glob.glob("*.md") + glob.glob("*.html") + glob.glob("*.json")
           if not f.startswith(("verify_",)) and f not in ("handbook.html",) and not f.endswith("_guide.html")
           and f not in ("changelog.html","whatsnew.html","compendium.json")
           # v14.1: made from the game's art (game/art, from the game zip) by make_art_pack.py, which build.py runs
           and f != "keter_art.js"]
_missing = sorted(f for f in _needed if f not in _bundled)
if _missing:
    raise SystemExit("NOT BUNDLED: " + ", ".join(_missing) + " \u2014 add them to PARTS in pack_sources.py")

written = []
for slug, title, files in PARTS:
    files = [f for f in files if os.path.exists(f)]
    if not files:
        continue
    listing = "\n".join(f"- `{f}` — {os.path.getsize(f)/1024:.0f} KB" for f in files)
    others = "\n".join(
        f"- **{ver_of(s)}_KETER_{s}.md** — {t}" for s, t, _ in PARTS if s != slug)
    head = (f"# KETER sources {ver_of(slug)} — part {slug.split('_')[0]} of {len(PARTS)}: {title}\n\n"
            f"{listing}\n\n"
            f"**The other parts**\n\n{others}\n\n"
            f"Parts 1 to 5 rebuild the Companion; part 6 is the Godot game and part 7 its tests (put their files under game/ and game/tests/, with its `fonts/` and `art/` folders from the game zip, which hold its typefaces and its art's sheets; then `python3 make_game.py fixture`, and `python3 verify_game.py` to regenerate the rule, simulator, World Map, Workshop, dock and chunk cases and test it; `make_game.py zip` packs it). With game/art in place, `build.py` also makes the Companion's copy of the game's art (keter_art.js). This one is only {title.lower()}.\n\n"
            f"{SPLITTER}\n")
    body = "".join(MARK % f + open(f, encoding="utf-8").read() for f in files)
    path = os.path.join(OUTDIR, f"{ver_of(slug)}_KETER_{slug}.md")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(head + body)
    written.append((path, os.path.getsize(path) / 1024, len(files)))

for path, kb, n in written:
    print(f"  {os.path.basename(path):24} {kb:6.0f} KB  {n} file(s)")
print(f"  total {sum(k for _, k, _ in written):.0f} KB across {len(written)} parts")
