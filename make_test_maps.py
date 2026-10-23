#!/usr/bin/env python3
"""The test floors: four Sandbox floors built to provoke the situations the
Battle Simulator most needs checking. Saved in the Sandbox's own format so they
can be opened and edited there, and marked testMap. The app adds any that are
missing to the floor library; it never overwrites one you have edited."""
import json
ENEMY, HALF, PLAYER, FULL = 0, 1, 3, 5
LABELS={0:"Enemy Spawn Tile",1:"Half Cover Barricade",2:"Loot Tile",3:"Player Spawn Tile",
        4:"Healing Station",5:"Full Cover Barricade"}
DIRS=[(1,0),(0,1),(-1,1),(-1,0),(0,-1),(1,-1)]
K=lambda q,r: f"{q},{r}"
def wk(a,b): return a+"|"+b if a<b else b+"|"+a
def disc(R): return [(q,r) for q in range(-R,R+1) for r in range(-R,R+1) if abs(q+r)<=R]

def floor(name, cells, walls, notes, symdefs=(), marks=(), radius=6, size="medium"):
    return {"v":6,"name":name,"district":"3","poiType":"Test","level":"","floorSize":"",
      "battlefieldSize":size,"notes":notes,"rewards":"","sizeKey":"one","radius":radius,
      "labels":True,"ink":False,
      "hexes":[[k,v] for k,v in cells.items()],
      "marks":[list(m) for m in marks],
      "walls":[[w,-1] for w in walls],
      "symDefs":list(symdefs),"nextDef":len(symdefs)+1,
      "colorLabels":{str(k):v for k,v in LABELS.items()},"wallLabels":{"-1":"Solid wall"},
      "stamps":{},"createdBy":"KETER tests","lastEditedBy":"KETER tests",
      "saved":"2026-09-25T00:00:00Z","testMap":True}

def base(R=6, enemy=((0,-6),(3,-6),(6,-6)), player=((-3,6),(-2,6),(-1,6),(0,6),(-4,6))):
    cells={K(q,r):{} for q,r in disc(R)}
    for q,r in enemy:  cells[K(q,r)]={"c":ENEMY,"lvl":1}
    for q,r in player: cells[K(q,r)]={"c":PLAYER}
    return cells

# ---- 1. Sight lines ----
cells=base()
walls=[]
walls.append(wk(K(-4,1),K(-4,0)))                          # a lone segment, west
for q in range(-1,2):                                       # a run across the middle
    walls.append(wk(K(q,0),K(q,-1))); walls.append(wk(K(q,0),K(q+1,-1)))
walls+= [wk(K(3,0),K(4,-1)), wk(K(3,0),K(4,0)), wk(K(3,-1),K(4,-1))]   # a sealed corner, east
M1=floor("TEST \u00b7 Sight Lines", cells, walls,
 "WEST (around -4,0): one lone wall segment. Under the line-of-sight rule a single "
 "segment does not block the tile directly behind it \u2014 a line slips past its end.\n"
 "MIDDLE (row 0): a run of six segments. Tiles behind it should shade when a Unit south "
 "of it is selected, and a ranged shot through it should be refused with 'a wall blocks'.\n"
 "EAST (around 3,0 / 4,-1): two walls meeting at a corner. It should seal: no sight across it.\n"
 "Walls also stop movement for everything except a Flying Unit (Test Drone).")

# ---- 2. Corridor ----
cells={}
for r in (-1,0,1):
    for col in range(-7,8):
        q=col-(r-(r&1))//2; cells[K(q,r)]={}
def cq(col,r): return col-(r-(r&1))//2
for r,col in ((-1,-7),(0,-7),(1,-7),(0,-6)): cells[K(cq(col,r),r)]={"c":PLAYER}
for r,col in ((-1,7),(0,7),(1,7)): cells[K(cq(col,r),r)]={"c":ENEMY,"lvl":1}
walls=[]
for r in (-1,1):   # a barrier across the corridor at column 3|4, open in the middle row
    a=(cq(3,r),r); b=(cq(4,r),r); walls.append(wk(K(*a),K(*b)))
M2=floor("TEST \u00b7 Corridor", cells, walls,
 "A corridor three tiles wide. Line Enemies up in a row to check Pierce (the Unit "
 "directly behind also takes the damage) and Chain (the damage jumps to the nearest "
 "other Enemy within range).\n"
 "Push an Enemy into another Unit: both should take 1 damage per tile the push could not "
 "complete. Push one toward the barrier at column 3|4 (walls on the outer rows, gap in the "
 "middle): it should stop at the wall and take the same. Push one off the end of the "
 "corridor: the edge of the floor stops it too.", radius=8)

# ---- 3. Hazards and cover ----
cells=base()
for q,r in ((-2,0),(-1,0)):  cells[K(q,r)]={"c":HALF}
for q,r in ((2,-1),(3,-1)):  cells[K(q,r)]={"c":FULL}
sym=[{"id":1,"text":"AC","desc":"Acid \u2014 2 damage and Poisoned, on entering and at the end of a turn",
      "hazard":{"keyword":"Poisoned","damage":2,"when":"both"}}]
marks=[(K(-2,1),1),(K(-1,1),1),(K(2,0),1),(K(3,0),1),(K(0,2),1)]
M3=floor("TEST \u00b7 Hazards and Cover", cells, [], 
 "Half Cover barricades (orange) at -2,0 and -1,0; Full Cover barricades (violet) at 2,-1 "
 "and 3,-1. A Unit next to one is harder to hit by a ranged attack from the far side: "
 "+2 for Half, +4 for Full. The odds shown over a target should drop accordingly.\n"
 "Acid hazard tiles (AC) sit right beside the cover, and one alone at 0,2. Stepping onto "
 "one, or ending a turn on one, should deal 2 and apply Poisoned. Movement should route "
 "around acid when another way exists.", symdefs=sym, marks=marks)

# ---- 4. Waves ----
cells=base(enemy=())
for (q,r),lvl in (((-3,-3),1),((0,-6),2),((3,-6),3),((6,-6),4)):
    cells[K(q,r)]={"c":ENEMY,"lvl":lvl}
M4=floor("TEST \u00b7 Waves", cells, [],
 "Four Enemy Spawn Tiles at Skull Levels 1, 2, 3 and 4. Each wave fills every tile, and "
 "each tile draws an Enemy of its own Level: Test Grunt or Test Gunner on Level 1, Test "
 "Hacker on Level 2. Level 3 and 4 tiles stay empty unless Dimensional Instability puts an "
 "Elite (Test Juggernaut) or Mini-Boss (Test Overseer) there.\n"
 "Set Districts cleared in setup to raise instability, up to 15%; the log names each "
 "instability spawn. Six waves, then victory once the board is clear.")

MAPS=[M1,M2,M3,M4]
if __name__=="__main__":
    js=("/* Generated by make_test_maps.py \u2014 the test floors, in the Sandbox's own "
        "format. */\nwindow.KETER_TEST_MAPS="+json.dumps(MAPS, ensure_ascii=False)+";\n")
    open("test_maps.js","w",encoding="utf-8").write(js)
    for m in MAPS:
        n=len(m["hexes"]); w=len(m["walls"])
        sp=sum(1 for k,v in m["hexes"] if v.get("c")==ENEMY); pl=sum(1 for k,v in m["hexes"] if v.get("c")==PLAYER)
        print(f"  {m['name']:28} {n:3} tiles, {w} walls, {sp} enemy spawns, {pl} player spawns, {len(m['marks'])} hazards")
