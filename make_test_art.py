#!/usr/bin/env python3
"""Draws the test cards' pixel art inside the app (make_test_art.js), sized to
each card's art box as the Forge lays it out, and writes test_pictures.js.
v12.4: the Unit cards drawn in square pixels are 128 across; the rest stay 64,
so both sizes are exercised."""
import http.server, socketserver, threading, functools, pathlib, shutil, json
from playwright.sync_api import sync_playwright
PLAN={
 "Test Warden":{"art":"square","w":128,"token":"hex","side":9,"orient":"flat"},
 "Test Striker":{"art":"square","w":128,"token":"hex","side":9,"orient":"flat"},
 "Test Drone":{"art":"square","w":128,"token":"hex","side":9,"orient":"flat"},
 "Test Sapper":{"art":"hex","across":40,"orient":"pointy","token":"hex","side":9},
 "Test Battery":{"art":"square","w":128,"token":"hex","side":6,"orient":"flat"},
 "Test Grunt":{"art":"square","w":128,"token":"square","size":24},
 "Test Scout":{"art":"hex","across":40,"orient":"flat","token":"hex","side":9,"orient":"flat"},
 "Test Gunner":{"art":"hex","across":48,"orient":"pointy","token":"square","size":32},
 "Test Hacker":{"art":"square","w":128,"token":"square","size":16},
 "Test Juggernaut":{"art":"hex","across":40,"orient":"flat","token":"square","size":32},
 "Test Overseer":{"art":"square","w":128,"token":"hex","side":12,"orient":"pointy"},
 "Test Piercing Rounds":{"art":"hex","across":48,"orient":"pointy"},
 "Test Overclock Routine":{"art":"hex","across":40,"orient":"flat"},
 "Test Plating":{"art":"square"}, "Test Targeting Suite":{"art":"square"},
 "Test Mortar Strike":{"art":"hex","across":40,"orient":"pointy"}, "Test Snare":{"art":"square"},
 "Test Strip":{"art":"hex","across":32,"orient":"flat"}, "Test Rally":{"art":"square"}, "Test Surge":{"art":"hex","across":40,"orient":"pointy"},
 "Test Swarm":{"art":"square","w":128,"token":"hex","side":9,"orient":"flat"},
 "Test Skirmisher":{"art":"square","w":128,"token":"hex","side":9,"orient":"flat"},
 "Test Skitter":{"art":"square","w":128,"token":"square","size":24},
 "Test Bulwark":{"art":"square","w":128,"token":"hex","side":9,"orient":"flat"},
 "Test Muster":{"art":"square"}, "Test Shockwave":{"art":"hex","across":40,"orient":"pointy"},
 "Test Overcharge":{"art":"square"}, "Test Capacitor":{"art":"square"}, "Test Barrage":{"art":"hex","across":40,"orient":"pointy"}, "Test Drone Bank":{"art":"square"},
 "Test Stim":{"art":"square"}, "Test Smoke":{"art":"hex","across":40,"orient":"flat"}, "Test Sandbags":{"art":"square"}, "Test Repair Kit":{"art":"square"},
 "Test Aegis Core":{"art":"hex","across":32,"orient":"pointy"}, "Test Spark Chip":{"art":"hex","across":32,"orient":"flat"},
}
TMP=pathlib.Path("/tmp/make_art")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9997),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
cards=[c for c in json.load(open("compendium_full.json"))["cards"] if c.get("testCard")]
with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page()
    pg.goto("http://127.0.0.1:9997/"); pg.wait_for_timeout(2000)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3500)
    fr=[f for f in pg.frames if f!=pg.main_frame and f.evaluate("()=>!!(window.KETER_BRIDGE&&window.KETER_BRIDGE.renderCard)")][0]
    fr.add_script_tag(content=open("make_test_art.js",encoding="utf-8").read())
    pics=fr.evaluate("""(a)=>{ var cards=a[0], plan=a[1], B=window.KETER_BRIDGE, out={}, heights={};
      cards.forEach(function(c){
        var sch=JSON.parse(JSON.stringify(c)); delete sch.pixelArt; delete sch.pixelToken;
        var cv=document.createElement('canvas'); cv.width=250; cv.height=350;
        B.renderCard(cv.getContext('2d'), B.fromSchema(sch), 100, {});
        var h=B.lastLayout().artH; heights[c.name]=h;
        var made=window.KETER_MAKE_TEST_ART(c, h, plan[c.name]||{art:'square'}); if(made) Object.assign(out, made);
      });
      /* v13.0: the five stand-in skins, one per body plan, sized as a Troop's art.
         v14.1: their art only: their tokens are the game's own drawings of the
         body plans, from keter_art.js (make_art_pack.py) */
      var th=heights["Test Drone"]||1.5;
      ["Bipedal","Quadcopter","Quadruped","Hexapod","Octopod"].forEach(function(bp){
        var made=window.KETER_MAKE_TEST_ART({name:"Stand-in \u00b7 "+bp, cardType:"troop"}, th,
          {art:"square", w:128, id:"px_skin_"+bp.toLowerCase()});
        if(made) Object.assign(out, made); });
      return {pics:out, heights:heights}; }""", [cards, PLAN])
    b.close()
srv.shutdown()
# the fingerprints of every earlier release's pictures, so the app can tell a
# picture nobody edited (and refresh it) from one someone drew on (and keep it)
def mark(pic):
    t=json.dumps([pic['w'],pic['h'],pic['frames']],separators=(',',':'),ensure_ascii=False)
    h=5381
    for ch in t: h=(((h*33)&0xFFFFFFFF)^ord(ch))&0xFFFFFFFF
    digits='0123456789abcdefghijklmnopqrstuvwxyz'; s=''
    while True:
        s=digits[h%36]+s; h//=36
        if not h: break
    return s
import os, re as _re
older=set(json.load(open("test_pictures_old_marks.json"))) if os.path.exists("test_pictures_old_marks.json") else set()
if os.path.exists("test_pictures.js"):
    m=_re.search(r'window\.KETER_TEST_PICTURES=(\{.*?\});\n', open("test_pictures.js",encoding="utf-8").read(), _re.S)
    if m: older|={mark(v) for v in json.loads(m.group(1)).values()}
older-={mark(v) for v in pics["pics"].values()}
json.dump(sorted(older), open("test_pictures_old_marks.json","w"))
js="/* Generated by make_test_art.py \u2014 the test cards' pixel art. The app adds any that\n   are missing to the picture library, and refreshes any nobody has edited; one you\n   have edited is never replaced. */\nwindow.KETER_TEST_PICTURES="+json.dumps(pics["pics"])+";\nwindow.KETER_TEST_PICTURE_OLD_MARKS="+json.dumps(sorted(older))+";\n"
open("test_pictures.js","w",encoding="utf-8").write(js)
hexes=sum(1 for v in pics["pics"].values() if v.get("grid")=="hex")
print(f"{len(pics['pics'])} pictures ({hexes} hex, {len(pics['pics'])-hexes} square), {len(js)//1024} KB")
for n,h in list(pics["heights"].items())[:4]: print(f"  {n}: art box {h:.2f} in")
