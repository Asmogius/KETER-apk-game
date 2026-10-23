#!/usr/bin/env python3
"""The battlefield chunks (Companion 14.7, game 0.20; four more in 14.9 / 0.22, content batch 1): hexagons of tiles, radius 3
(37 tiles), drawn as Sandbox floors and marked as chunks. A POI's battlefield is
grown from them: a Start chunk first, then fillers, Enemy chunks further on, Loot
behind the Enemies, an Exit at the far end of a large one. Each chunk says its
District, the Skull Levels it suits, its role, and which of its six sides are open
(an open side joins only an open side; a walled one gets a wall where it meets
another chunk).

Writes keter_chunks.js (window.KETER_CHUNKS): the app adds any that are missing to the
floor library, as it does the test floors, and never overwrites one you edited.

Each chunk is drawn below as rows of its hexagon, top to bottom (r = -3 to 3),
each row's tiles left to right:
  .  deck            #  no tile (a pit, a gap)
  P  your spawn      E  their spawn
  h  Half Cover      F  Full Cover
  L  Loot Tile       C  Locked Chest     X  Emergency Exit    +  Healing Station
  a  acid (Poisoned) s  live cables (Stunned)  m  molten slag  w  razor wire (Bleed)
Walls: (q, r, side) pairs, side being the tile's neighbour it walls off
(0 east, 1 south-east, 2 south-west, 3 west, 4 north-west, 5 north-east)."""
import json

R = 3
ROWS = [(r, max(-R, -R - r), min(R, R - r)) for r in range(-R, R + 1)]
DIRS = [(1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)]
SIDES = ["N", "NE", "SE", "S", "SW", "NW"]
LABELS = {0: "Enemy Spawn Tile", 1: "Half Cover Barricade", 2: "Loot Tile", 3: "Player Spawn Tile",
          4: "Healing Station", 5: "Full Cover Barricade"}
COLOUR = {"E": 0, "h": 1, "L": 2, "P": 3, "+": 4, "F": 5}
# the symbols a chunk may carry, by its letter: [text, description, hazard]
SYMS = {
    "a": ["AC", "Acid — 2 damage and Poisoned, on entering and at the end of a turn", {"keyword": "Poisoned", "damage": 2, "when": "both"}],
    "s": ["LV", "Live cables — 1 damage and Stunned, on entering and at the end of a turn", {"keyword": "Stunned", "damage": 1, "when": "both"}],
    "m": ["SL", "Molten slag — 3 damage, on entering and at the end of a turn", {"keyword": "", "damage": 3, "when": "both"}],
    "w": ["RW", "Razor wire — 1 damage and Bleed, on entering and at the end of a turn", {"keyword": "Bleed", "damage": 1, "when": "both"}],
    "C": ["LC", "Locked Chest — always rewards loot", None],
    "X": ["EX", "Emergency Exit — the only way out of a POI early", None],
}


def K(q, r):
    return f"{q},{r}"


def wk(a, b):
    return a + "|" + b if a < b else b + "|" + a


def chunk(name, role, rows, sides, skull=(1, 6), walls=(), notes=""):
    """A chunk as a Sandbox floor. rows: seven strings (spaces ignored); sides: the open ones, as names."""
    rows = [x.replace(" ", "") for x in rows]
    assert len(rows) == 7, name
    hexes, marks, used = [], [], []
    for (r, q0, q1), line in zip(ROWS, rows):
        assert len(line) == q1 - q0 + 1, (name, r, line)
        for i, ch in enumerate(line):
            q = q0 + i
            if ch == "#":
                continue
            t = {}
            if ch in COLOUR:
                t["c"] = COLOUR[ch]
            hexes.append([K(q, r), t])
            if ch in SYMS:
                if ch not in used:
                    used.append(ch)
                marks.append([K(q, r), used.index(ch) + 1])
    defs = []
    for i, ch in enumerate(used):
        text, desc, hz = SYMS[ch]
        d = {"id": i + 1, "text": text, "desc": desc}
        if hz:
            d["hazard"] = dict(hz)
        defs.append(d)
    have = {h[0] for h in hexes}
    ws = []
    for q, r, d in walls:
        a, b = K(q, r), K(q + DIRS[d][0], r + DIRS[d][1])
        assert a in have, (name, a)
        ws.append([wk(a, b), -1])
    assert all(s in SIDES for s in sides), name
    return {"v": 6, "name": "Chunk · D3 · " + name, "district": "3", "poiType": "Chunk", "level": "", "floorSize": "",
            "battlefieldSize": "", "notes": notes, "rewards": "", "sizeKey": "one", "radius": R, "labels": True, "ink": False,
            "hexes": hexes, "marks": marks, "walls": ws, "symDefs": defs, "nextDef": len(defs) + 1,
            "colorLabels": {str(k): v for k, v in LABELS.items()}, "wallLabels": {"-1": "Solid wall"}, "stamps": {},
            "createdBy": "KETER", "lastEditedBy": "KETER", "saved": "2026-10-21T00:00:00Z",
            "chunk": {"role": role, "sides": [s in sides for s in SIDES], "skullMin": skull[0], "skullMax": skull[1]},
            "builtinChunk": True}


ALL = ["N", "NE", "SE", "S", "SW", "NW"]
CHUNKS = [
    # ---------------------------------------------------------------- Start (your spawn)
    chunk("Loading Bay", "start", [
        "   . . h .",
        "  . . . . .",
        " h . . . . h",
        ". . . . . . .",
        " . . P P . .",
        "  h P P P .",
        "   . . . h"], ["N", "NE", "SE", "SW", "NW"],
        notes="Start: your pads at the back of a loading bay, crates for cover at its mouth."),
    chunk("Freight Lift", "start", [
        "   . . . .",
        "  . F . F .",
        " . . . . . .",
        "h . P P P . h",
        " . . P P . .",
        "  . . . . .",
        "   # . . #"], ["N", "NE", "NW", "S"],
        walls=[(-1, 0, 3), (-1, 0, 2), (2, -1, 0), (2, -1, 5)],
        notes="Start: a freight lift's platform, railed at its sides, two pillars ahead."),
    chunk("Maintenance Tunnel", "start", [
        "   . . . .",
        "  # . . . #",
        " # . h . . #",
        ". . . . . . .",
        " # P P P P #",
        "  # . P . #",
        "   . . . ."], ["N", "S", "NE", "SW"],
        notes="Start: a narrow tunnel with your pads in it; it opens north and south."),
    # v14.9 (content batch 1, gaps and gantries): where a Unit with Leap goes the short way
    chunk("Gantry Landing", "start", [
        "   . . . .",
        "  . h # h .",
        " . . # # . .",
        ". . . . . . .",
        " . P P P P .",
        "  . P P . .",
        "   . . . ."], ["N", "NE", "SE", "SW", "NW"],
        notes="Start: a landing on the gantries, your pads behind a walkway, a gap ahead that a Unit with Leap jumps."),
    # ---------------------------------------------------------------- Enemy (their spawn)
    chunk("Assembly Line", "enemy", [
        "   . E . E",
        "  . . . . .",
        " F s s s s F",
        ". . . . . . .",
        " h . . . . h",
        "  . . . . .",
        "   . E . ."], ALL,
        notes="Enemy: a dead assembly line across the middle, its live cables still sparking; Full Cover at either end."),
    chunk("Robot Pen", "enemy", [
        "   E . . E",
        "  . . E . .",
        " . F . . F .",
        ". . . h . . .",
        " . . . . . .",
        "  h . . . h",
        "   . . . ."], ["N", "NE", "SE", "S", "SW", "NW"],
        walls=[(-1, -1, 3), (3, -2, 0)],
        notes="Enemy: the pen they wake in, three pads at the back, pillars and a barricade between."),
    chunk("Smelter Floor", "enemy", [
        "   . . . .",
        "  . E . E .",
        " . . m m . .",
        "h . m m m . h",
        " . . m m . .",
        "  . . E . .",
        "   . . . ."], ["NE", "SE", "SW", "NW", "N"], skull=(2, 6),
        notes="Enemy: a smelter's pool of slag in the middle; they come round it from three sides."),
    chunk("Security Checkpoint", "enemy", [
        "   . E E .",
        "  . . . . .",
        " F F . . F F",
        ". . . . . . .",
        " . w . . w .",
        "  . . . . .",
        "   . . . ."], ["N", "S", "NE", "NW", "SE", "SW"], skull=(1, 6),
        notes="Enemy: a checkpoint, Full Cover booths with a gap between, razor wire on your side of it."),
    # v14.9 (content batch 1, gaps and gantries)
    chunk("Skitter Nest", "enemy", [
        "   E . . E",
        "  . # . # .",
        " . . E . . .",
        "# . w . w . #",
        " . . # # . .",
        "  h . . . h",
        "   . . . ."], ALL, skull=(1, 6),
        notes="Enemy: a skitter-bots' nest in the gantry's ribs, holes all through it, razor wire strung across the way in."),
    chunk("Gantry Crossing", "enemy", [
        "   . E E .",
        "  h . . . h",
        " . # # # # .",
        ". . . . . . .",
        " . # # # # .",
        "  h . . . h",
        "   . . . ."], ["N", "S", "NE", "SW", "SE", "NW"], skull=(2, 6),
        notes="Enemy: a single gantry across a drop, gaps either side of it; they hold the far end, and a Unit with Leap comes at them across the gaps."),
    # ---------------------------------------------------------------- Loot
    chunk("Parts Store", "loot", [
        "   L . . L",
        "  . F . F .",
        " . . C . . .",
        ". h . . . h .",
        " . . . . . .",
        "  . . . . .",
        "   . . . ."], ["S", "SE", "SW", "NE", "NW"],
        walls=[(-1, -1, 3), (2, -2, 0)],
        notes="Loot: a parts store, shelving for Full Cover, a Locked Chest and two Loot Tiles at the back."),
    chunk("Scrap Heap", "loot", [
        "   . L . .",
        "  . h . h .",
        " . . . L . .",
        ". h . . . h L",
        " . . a . . .",
        "  . . . . .",
        "   . . . ."], ALL,
        notes="Loot: a scrap heap, salvage scattered among half-buried cover, an acid leak where it drains."),
    chunk("Vault", "loot", [
        "   # C L #",
        "  # . . . #",
        " . F . . F .",
        ". . . . . . .",
        " . h . . h .",
        "  . . . . .",
        "   . . . ."], ["S", "SE", "SW"], skull=(2, 6),
        walls=[(0, -2, 3), (2, -2, 0), (-1, -1, 3), (3, -1, 5)],
        notes="Loot: a vault at the end of the line, walled at the back, its chest behind two pillars."),
    # ---------------------------------------------------------------- Exit
    chunk("Service Hatch", "exit", [
        "   . . . .",
        "  . h . . .",
        " . . . X . .",
        ". . . . . . .",
        " . . . . h .",
        "  . . . . .",
        "   . . . ."], ALL,
        notes="Exit: an Emergency Exit hatch in the floor; a Hero who reaches it takes the Strike Team out."),
    # ---------------------------------------------------------------- Filler
    chunk("Conveyor Run", "filler", [
        "   . . . .",
        "  h . . . .",
        " . s s s s .",
        ". . . . . . .",
        " . s s s s .",
        "  . . . . h",
        "   . . . ."], ALL,
        notes="Filler: two conveyor lines, still live, with a walkway between."),
    chunk("Coolant Spill", "filler", [
        "   . . . .",
        "  . . a . .",
        " . h a a . .",
        ". . a + a . .",
        " . . a a h .",
        "  . . a . .",
        "   . . . ."], ALL,
        notes="Filler: a burst coolant main; a Healing Station stands in the middle of the spill."),
    chunk("Pillar Hall", "filler", [
        "   . . . .",
        "  . F . F .",
        " . . . . . .",
        ". F . . . F .",
        " . . . . . .",
        "  . F . F .",
        "   . . . ."], ALL,
        notes="Filler: a hall of pillars: Full Cover, evenly spaced, long sight lines between."),
    chunk("Broken Gantry", "filler", [
        "   . . # #",
        "  . . . # #",
        " h . . . . #",
        ". . . . . . .",
        " # . . . . h",
        "  # # . . .",
        "   # # . ."], ["N", "S", "NW", "SE", "SW", "NE"],
        walls=[(0, -1, 4), (1, 1, 1)],
        notes="Filler: a gantry with its ends fallen in; the way across bends round the gaps."),
    chunk("Catwalk Run", "filler", [
        "   . . # .",
        "  . # . # .",
        " . # . . # .",
        ". # . h . # .",
        " . # . . # .",
        "  . # . # .",
        "   . # . ."], ALL,
        notes="Filler: three catwalks side by side with drops between; the long way round for most, a hop across for a Unit with Leap."),
    chunk("Barricade Line", "filler", [
        "   . . . .",
        "  . . . . .",
        " . . . . . .",
        "h h . w . h h",
        " . . . . . .",
        "  . . . . .",
        "   . . . ."], ALL, skull=(1, 6),
        notes="Filler: a line of barricades with a wired gap; whoever holds it has cover facing either way."),
]

if __name__ == "__main__":
    out = "window.KETER_CHUNKS=" + json.dumps(CHUNKS, ensure_ascii=False, separators=(",", ":")) + ";\n"
    open("keter_chunks.js", "w", encoding="utf-8").write(
        "/* Generated by make_chunks.py: the built-in battlefield chunks (District 3). The app adds any that\n"
        "   are missing to the floor library; one you have edited is left as you left it. */\n" + out)
    roles = {}
    for c in CHUNKS:
        roles[c["chunk"]["role"]] = roles.get(c["chunk"]["role"], 0) + 1
    print("keter_chunks.js:", len(CHUNKS), "chunks", roles)
