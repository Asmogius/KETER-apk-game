"""The game's own art in the Companion (v14.1). keter_art.js's pictures join the
picture library at start-up: a token for every master Unit, the five body
plans' stand-in tokens (the stand-in skins wear them), and a picture in each of
the game's slots (The fight's board pieces and stand-ins; the Status icons and
marks, the Aether gems, the fight bar's and the roles' icons and the card
pictures under Game look). A master Unit is given its token only if it has
none, and a slot its picture only while it is empty, each once: a token taken
off a card, or a slot cleared, stays that way. A picture nobody has drawn on is
refreshed when a release redraws it; one drawn on is kept. Export for Godot
leaves the game's own pictures out until one is drawn on, and then carries it.
The Pixel Studio's Assets tab has The fight; tokens can be 48 across.

v14.2 (game 0.15): the World Map's ground (four to a District, in hex pixels,
the same cells the game draws) and rubble, each District's things, the map's
icons (square, on plates) and the Hangar; District fights, a new group of 42
slots; Home's picture, the backdrops, QM-7 and its blink, Victory, Defeat, the
gear and the District emblems. A slot of several is given all of the game's,
and once one of them is yours, Export for Godot carries the whole slot. The
Companion's World Map stands the things, icons and Hangar as the game does.

v14.3 (game 0.16): the fight's five effects, each one picture of several
frames at its speed, every frame the game's own pixel for pixel; the turn
strip's Move and Attack icons and End turn's, under Game look; Effects, a new
group of five slots.

v14.6 (game 0.19): the card back, 75 by 105, in Game look, the game's own.

v14.5 (game 0.18): the atmosphere's four motes (ember, spark, ash, dust), in
four more Effects slots, frame for frame the game's own.

v14.4 (game 0.17): a picture for each of the 83 cards (97 from v14.9) that are not Units, 128
by 90, the game's own pixel for pixel, linked to its card as its art while the
card has none, once; drawn over, it goes in the export as that card's art."""
import http.server, socketserver, threading, functools, pathlib, shutil, json, io, zipfile
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_shipped_art")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP); shutil.copy("compendium_full.json", TMP / "compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9353), functools.partial(H, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, d=""):
    (ok if c else bad).append(n + ((" — " + str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ") + n + ("" if c else "  — " + str(d)[:260]))

UNITS = "/^(hero|troop|enemy|elite|miniboss|boss)$/i"

# ---- (v14.2) before the app: the Companion's ground is the game's, cell for cell
import sys, base64 as _b64
sys.path.insert(0, "game/tools/art")
import numpy as np
from PIL import Image as _Image
import hexpix
_src = open("keter_art.js", encoding="utf-8").read()
_art = json.loads(_src[_src.index("=") + 1:_src.rstrip().rindex(";")])
_man = json.load(open("game/art/art.json", encoding="utf-8"))
_sheet = _Image.open("game/art/ground.png").convert("RGBA")
_same, _all = 0, 0
for key, e in _man["ground"].items():
    pid = ("px_keter_rubble_%d" % e["v"]) if e["kind"] == "rubble" else ("px_keter_ground_%s_%d" % (e["d"] or "none", e["v"]))
    pic = _art["pics"].get(pid)
    if not pic:
        continue
    _all += 1
    raw = _b64.b64decode(pic["frames"][0]["layers"][0]["px"])
    vals = []
    for i in range(0, len(raw), 2):
        vals += [raw[i + 1]] * raw[i]
    a = np.array(vals, dtype=np.int32).reshape(pic["h"], pic["w"])
    im, mid = hexpix.render(a, 3.0)
    x, y, w, h = e["rect"]
    A, B = np.array(im), np.array(_sheet.crop((x, y, x + w, y + h)))
    seen = A[:, :, 3] > 0                      # (what is clear may hold any colour)
    if pic["grid"] == "hex" and pic["side"] == 9 and pic["orient"] == "flat" and A.shape == B.shape and np.array_equal(A[:, :, 3], B[:, :, 3]) and np.array_equal(A[seen], B[seen]):
        _same += 1
ck("v14.2: every tile of ground and rubble in the Companion, drawn as the game draws it, is the game's own, pixel for pixel", _all == 31 and _same == 31, (_same, _all))
# ---- (v14.3) and its effects are the game's, frame for frame, at the game's speed
from kart import rgb as _rgb
_fxs = _Image.open("game/art/fx.png").convert("RGBA")
_fx_ok, _fx_info = [], {}
for key, e in _man.get("fx", {}).items():
    pic = _art["pics"].get("px_keter_fx_" + key)
    if not pic:
        continue
    x, y, w, h = e["rect"]
    fw = e["w"]
    frames_same = 0
    for i, fr in enumerate(pic["frames"]):
        raw = _b64.b64decode(fr["layers"][0]["px"])
        vals = []
        for j in range(0, len(raw), 2):
            vals += [raw[j + 1]] * raw[j]
        cut = _fxs.crop((x + i * fw, y, x + (i + 1) * fw, y + h)).load()
        same = len(vals) == fw * h
        for k, v in enumerate(vals[:fw * h]):
            px = cut[k % fw, k // fw]
            if (px[3] > 0) != (v > 0) or (v and px[:3] != _rgb(v)):
                same = False
                break
        frames_same += 1 if same else 0
    _fx_info[key] = [len(pic["frames"]), e["frames"], pic.get("fps"), e["fps"], frames_same, pic.get("slot")]
    if len(pic["frames"]) == e["frames"] and frames_same == e["frames"] and pic.get("fps") == e["fps"] and pic["w"] == fw and pic["h"] == h and pic.get("slot") == "fight.fx." + key:
        _fx_ok.append(key)
ck("v14.3: each of the fight's five effects in the Companion is the game's own, frame for frame, at its speed (v14.5: and the atmosphere's four motes)", sorted(_fx_ok) == ["ash", "dust", "ember", "explosion", "flash", "heal", "impact", "shield", "spark"], _fx_info)
with sync_playwright() as p:
    b = p.chromium.launch()
    ctx = b.new_context(viewport={"width": 412, "height": 915}, device_scale_factor=2)
    pg = ctx.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("dialog", lambda d: d.accept())
    pg.goto("http://127.0.0.1:9353/"); pg.wait_for_timeout(1800)
    E = pg.evaluate

    # ---- what came in at start-up
    r = E("""()=>{ var A=window.KETER_ART, P=KETER_PX, ids=Object.keys(A.pics);
      return {n:ids.length, version:A.version, tokens:A.tokens.length, slots:A.slots.length,
        missing:ids.filter(function(id){ return !P.has(id); }),
        unmarked:ids.filter(function(id){ var q=P.get(id); return !q || q.shipped!==P.mark(q) || q.shipped!==P.mark(A.pics[id]); }),
        flat:ids.filter(function(id){ return !(P.get(id).flat||'').length; }).length}; }""")
    ck("the game's art is built in: its pictures, tokens and slots, from game 0.19 (0.24 now)", r["n"] >= 351 and r["version"] in ("0.19", "0.22", "0.23", "0.24") and r["tokens"] >= 60 and r["slots"] >= 203, r)
    ck("every picture is in the library at start-up, marked as shipped, its flat image worked out", not r["missing"] and not r["unmarked"] and r["flat"] == 0, r)
    t = E("""()=>{ var A=window.KETER_ART, P=KETER_PX;
      var wrong=A.tokens.filter(function(t){ var q=P.pictureFor({id:t[0]||null, name:t[1]},'token'); return !q || q.id!==t[2]; });
      var cards=KETER_ASSETS.cardList().filter(function(c){ return c._src==='master' && """ + UNITS + """.test(String(c.cardType||'')); });
      var without=cards.filter(function(c){ return !P.pictureFor(c,'token'); }).map(function(c){ return c.name; });
      var sizes=A.tokens.map(function(t){ var q=P.get(t[2]); return q.w+'x'+q.h+':'+q.grid+':'+q.kind; });
      return {wrong:wrong.map(function(t){ return t[1]; }), units:cards.length, without:without, sizes:sizes.filter(function(s,i,a){ return a.indexOf(s)===i; })}; }""")
    ck("every master Unit wears its token, 48 by 48 in square pixels", not t["wrong"] and t["units"] >= 60 and not t["without"] and t["sizes"] == ["48x48:square:token"], t)
    # ---- (v14.4) every card that is not a Unit wears its picture as its art
    ca = E("""()=>{ var A=window.KETER_ART, P=KETER_PX;
      var wrong=(A.arts||[]).filter(function(t){ var q=P.pictureFor({id:t[0]||null, name:t[1]},'art'); return !q || q.id!==t[2]; });
      var cards=KETER_ASSETS.cardList().filter(function(c){ return c._src==='master' && !""" + UNITS + """.test(String(c.cardType||'')); });
      var without=cards.filter(function(c){ return !P.pictureFor(c,'art'); }).map(function(c){ return c.name; });
      var sizes=(A.arts||[]).map(function(t){ var q=P.get(t[2]); return q.w+'x'+q.h+':'+q.grid+':'+q.kind+':'+(q.shipped===P.mark(q)); });
      var unit=P.pictureFor({id:'D3-T21', name:'Aether Battery'},'art'), cell=P.pictureFor({id:'D3-AE08', name:'Aether battery'},'art');
      return {n:(A.arts||[]).length, ids:(A.arts||[]).filter(function(t){ return t[0]; }).length, wrong:wrong.map(function(t){ return t[1]; }), cards:cards.length, without:without,
        sizes:sizes.filter(function(s,i,a){ return a.indexOf(s)===i; }), unit:unit?unit.id:null, cell:cell?cell.id:null,
        name:P.get('px_keter_art_aether_lance').name}; }""")
    ck("v14.4: 93 card pictures (14 more in v14.9, 4 fewer in v14.13), 60 of cards with an id, each 128 by 90 in square pixels, kind art, shipped", ca["n"] == 93 and ca["ids"] == 60 and ca["sizes"] == ["128x90:square:art:true"] and ca["name"] == "Aether Lance art", ca)
    ck("v14.4: every master card that is not a Unit wears its own as its art (bar the test cards, which have theirs)", not ca["wrong"] and not [n for n in ca["without"] if not n.startswith("Test ")] and ca["cards"] >= 93, ca)
    ck("v14.4: the Aether battery card wears its picture; the Aether Battery Unit, of the same name, none", ca["cell"] == "px_keter_art_aether_battery" and ca["unit"] is None, ca)
    _ca_same, _ca_all = 0, 0
    _ca_sheet = _Image.open("game/art/cardart.png").convert("RGBA")
    import kart as _kart
    for key, e in _man.get("cardart", {}).items():
        pic = _art["pics"].get("px_keter_art_" + key)
        if not pic:
            continue
        _ca_all += 1
        raw = _b64.b64decode(pic["frames"][0]["layers"][0]["px"])
        vals = []
        for i in range(0, len(raw), 2):
            vals += [raw[i + 1]] * raw[i]
        x0, y0, w0, h0 = e["rect"]
        crop = np.array(_ca_sheet.crop((x0, y0, x0 + w0, y0 + h0)))
        mine = np.array([_kart.rgb(v) for v in vals], dtype=np.uint8).reshape(h0, w0, 3) if len(vals) == w0 * h0 and all(v > 0 for v in vals) else None
        if pic["w"] == w0 and pic["h"] == h0 and mine is not None and (crop[:, :, 3] == 255).all() and np.array_equal(mine, crop[:, :, :3]):
            _ca_same += 1
    ck("v14.4: each the game's own: every pixel there, solid to its edges, its size the game's", _ca_all == 93 and _ca_same == 93, (_ca_all, _ca_same))
    s = E("""()=>{ var A=window.KETER_ART, AS=KETER_ASSETS, P=KETER_PX;
      var off=A.slots.filter(function(x){ var sl=AS.slot(x[0]), q=P.get(x[1]); if(!sl || !q) return true;
        var held=sl.multi ? AS.ids(x[0]).indexOf(x[1])>=0 : AS.ids(x[0]).join()===x[1];
        var sized=sl.kind==='hex' ? (q.grid==='hex' && q.shape==='hexagon' && q.side===sl.side && q.orient===sl.orient) : (q.w===sl.w && q.h===sl.h && q.grid==='square');
        return !held || !sized || (!sl.multi && q.name!==sl.name); });
      var fight=AS.slots().filter(function(x){ return x.group==='fight'; }), dist=AS.slots().filter(function(x){ return x.group==='district'; });
      return {off:off.map(function(x){ return x[0]; }), fight:fight.length, fightDrawn:fight.filter(function(x){ return AS.ids(x.id).length; }).length,
        dist:dist.length, distDrawn:dist.filter(function(x){ return AS.ids(x.id).length===1; }).length,
        groups:A.slots.map(function(x){ return x[0].split('.').slice(0,2).join('.'); }).filter(function(g,i,a){ return a.indexOf(g)===i; })}; }""")
    ck("each of the game's slots holds its picture, at the slot's size (a hexagon of hex pixels for ground and rubble) and under its name", not s["off"] and s["fight"] == 24 and s["fightDrawn"] == 24, s)
    ck("among them the board, the stand-ins, the Status icons and marks, the gems, the bar's and roles' icons and the card pictures",
       all(g in s["groups"] for g in ["fight.standin", "ui.status", "ui.mark", "ui.icon", "ui.card"]) and any(g.startswith("fight.") and g != "fight.standin" for g in s["groups"]), s["groups"])
    ck("v14.2: and the World Map's, each District's fights, and the menus'", all(g in s["groups"] for g in ["map.ground", "map.collapsed", "map.prop", "map.icon", "fight.d1", "fight.d6", "ui.title", "ui.backdrop", "ui.qm7", "ui.qm7_blink"])
       and s["dist"] == 42 and s["distDrawn"] == 42, s)
    m = E("""()=>{ var AS=KETER_ASSETS, P=KETER_PX, n=function(id){ return AS.ids(id).length; }, q=function(id){ var x=P.get(AS.ids(id)[0]); return x?[x.w,x.h,x.grid]:null; };
      return {ground:['1','2','3','4','5','6','none'].map(function(d){ return n('map.ground.'+d); }), rubble:n('map.collapsed'), things:['1','2','3','4','5','6'].map(function(d){ return n('map.prop.'+d); }),
        thing:q('map.prop.5'), icons:['poi','unique','ambush','cache','event'].map(function(k){ return q('map.icon.'+k); }), dock:q('map.icon.dock'), qm7:q('ui.qm7'), blink:q('ui.qm7_blink'), win:q('ui.title.victory'), lose:q('ui.title.defeat'),
        home:q('ui.title'), dockb:q('ui.backdrop.dock'), menu:q('ui.backdrop.menu'), gear:q('ui.icon.gear'), emblems:['1','2','3','4','5','6'].map(function(d){ return q('ui.icon.district_'+d); }),
        shards:q('ui.icon.shards'), hp:n('ui.icon.hp'), floor:n('ui.floor'), names:AS.ids('map.ground.2').map(function(id){ return P.get(id).name; })}; }""")
    ck("v14.2: four pictures of ground for each District and for none, three of rubble, three things for each District", m["ground"] == [4] * 7 and m["rubble"] == 3 and m["things"] == [3] * 6 and m["thing"] == [32, 32, "square"], m)
    ck("v14.2: in a slot of several, each keeps its own name", m["names"] == ["District 2 ground %d" % i for i in range(1, 5)], m["names"])
    ck("v14.2: the map's icons, 16 by 16 in square pixels; the Hangar, 64", all(i == [16, 16, "square"] for i in m["icons"]) and m["dock"] == [64, 64, "square"], m)
    ck("v14.2: QM-7 and its blink, 64; Victory and Defeat, 32 high; Home's picture and the two backdrops, 256 by 144; the gear, the emblems and the shards, 16",
       m["qm7"] == [64, 64, "square"] and m["blink"] == [64, 64, "square"] and m["win"][1] == 32 and m["lose"][1] == 32 and m["home"] == m["dockb"] == m["menu"] == [256, 144, "square"]
       and m["gear"] == [16, 16, "square"] and all(e == [16, 16, "square"] for e in m["emblems"]) and m["shards"] == [16, 16, "square"], m)
    ck("v14.2: Health and the fight floor stay the game's to draw (no picture)", m["hp"] == 0 and m["floor"] == 0, m)
    k = E("""()=>{ var S=KETER_SKINS, P=KETER_PX; return S.all().filter(function(k){ return k.builtin; }).map(function(k){ var q=P.get(k.variants[0].token); return [k.name, q&&q.w, q&&q.h, q&&q.grid, !!(q&&q.shipped)]; }); }""")
    ck("the five stand-in skins wear the game's drawings of their body plans", len(k) == 5 and all(x[1] == 48 and x[2] == 48 and x[3] == "square" and x[4] for x in k), k)
    ck("and the stand-in skins' art is the test art's, as before", E("()=>['bipedal','quadcopter','quadruped','hexapod','octopod'].every(function(b){ var q=KETER_PX.get('px_skin_'+b+'_art'); return q && q.w===128 && q.shipped; })"))

    # ---- Export for Godot: the game's own stay out
    x = E("""()=>{ var r=KETER_ASSETS.build(), m=r.manifest.files;
      return {count:r.count, games:m.filter(function(f){ return /^px_keter_/.test(f.picture||''); }).length,
        skins:m.filter(function(f){ return /^px_skin_.*_token$/.test(f.picture||''); }).map(function(f){ return f.file+':'+f.w+'x'+f.h; })}; }""")
    ck("Export for Godot leaves out the game's own pictures nobody has drawn on", x["games"] == 0 and x["count"] > 20, x)
    ck("but carries the stand-in skins' tokens, which designs wear", len(x["skins"]) == 5 and all(f.endswith(":48x48") for f in x["skins"]), x["skins"])
    # draw over the crate, as the Studio saves a picture
    d = E("""()=>{ var A=KETER_ASSETS, P=KETER_PX, id=A.ids('fight.crate')[0], q=P.get(id), n=q.w*q.h, px=P.decode(q.frames[0].layers[0].px,n);
      for(var i=0;i<q.w;i++) px[i]=133; q.frames[0].layers[0].px=P.encode(px);
      if(q.shipped && P.mark(q)!==q.shipped) delete q.shipped; P.put(q,id);
      var r=A.build(), f=r.manifest.files.filter(function(e){ return e.picture===id; })[0];
      return {id:id, own:A.gamesOwn(P.get(id)), file:f&&f.file, owner:f&&f.owner, w:f&&f.w, count:r.count}; }""")
    ca2 = E("""()=>{ var A=KETER_ASSETS, P=KETER_PX, q=P.pictureFor({id:'D3-EQ14', name:'Counterweight Fist'},'art'), id=q.id, n=q.w*q.h, px=P.decode(q.frames[0].layers[0].px,n);
      for(var i=0;i<q.w;i++) px[q.w*3+i]=133; q.frames[0].layers[0].px=P.encode(px);
      if(q.shipped && P.mark(q)!==q.shipped) delete q.shipped; P.put(q,id);
      var r=A.build(), f=r.manifest.files.filter(function(e){ return e.picture===id; })[0], others=r.manifest.files.filter(function(e){ return /^px_keter_art_/.test(e.picture||'') && e.picture!==id; });
      return {id:id, own:A.gamesOwn(P.get(id)), file:f&&f.file, what:f&&f.what, owner:f&&f.owner, w:f&&f.w, h:f&&f.h, others:others.length}; }""")
    ck("v14.4: a card's picture drawn over goes in the export as that card's art; the others nobody drew on stay out",
       ca2["id"] == "px_keter_art_counterweight_fist" and not ca2["own"] and ca2["file"] == "cards/equipment/counterweight_fist_art.png" and ca2["what"] == "art"
       and ca2["owner"].get("card") == "Counterweight Fist" and [ca2["w"], ca2["h"]] == [128, 90] and ca2["others"] == 0, ca2)
    ck("drawn over, a picture of the game's goes in the export, in its slot's folder, for the game to use", d["id"] == "px_keter_board_crate" and not d["own"] and d["file"] == "fight/loot_crate.png" and d["owner"] == {"slot": "fight.crate"} and d["w"] == 32 and d["count"] == x["count"] + 1, d)
    # (v14.2) one of District 5's grounds drawn over: the whole slot goes, as hex pictures; a District 4 plate, in its folder
    g = E("""()=>{ var A=KETER_ASSETS, P=KETER_PX, id=A.ids('map.ground.5')[1], q=P.get(id), n=q.w*q.h, px=P.decode(q.frames[0].layers[0].px,n);
      for(var i=0;i<n;i++) if(px[i]) { px[i]=133; break; } q.frames[0].layers[0].px=P.encode(px);
      if(q.shipped && P.mark(q)!==q.shipped) delete q.shipped; P.put(q,id);
      var pid=A.ids('fight.d4.floor_2')[0], p2=P.get(pid), px2=P.decode(p2.frames[0].layers[0].px,p2.w*p2.h); px2[p2.w*20+20]=133; p2.frames[0].layers[0].px=P.encode(px2); if(p2.shipped) delete p2.shipped; P.put(p2,pid);
      var r=A.build(), g5=r.manifest.files.filter(function(e){ return e.owner && e.owner.slot==='map.ground.5'; }), g6=r.manifest.files.filter(function(e){ return e.owner && e.owner.slot==='map.ground.6'; });
      var d4=r.manifest.files.filter(function(e){ return e.owner && e.owner.slot==='fight.d4.floor_2'; })[0];
      var bytes=null; if(g5.length){ var z=r.bytes, s=''; for(var i=0;i<z.length;i++) s+=String.fromCharCode(z[i]); bytes=btoa(s); }
      return {g5:g5.map(function(e){ return [e.file, e.grid, e.hex]; }), g6:g6.length, d4:d4?[d4.file, d4.w, d4.h, d4.group]:null, zip:bytes}; }""")
    hexes = [e[2] for e in g["g5"]]
    ck("v14.2: one ground of District 5 drawn over, Export for Godot carries all four of its, as hex pictures; District 6's, nobody's drawn on, stay out",
       len(g["g5"]) == 4 and all(e[1] == "hex" and e[0].startswith("map/ground/district_5_ground_") for e in g["g5"]) and all(h["shape"] == "hexagon" and h["side"] == 9 and h["orient"] == "flat" and h["scale"] == 4 for h in hexes) and g["g6"] == 0, g["g5"])
    ck("v14.2: a District's floor plate drawn over goes in fight/districts/, 42 by 48", g["d4"] is not None and g["d4"][0] == "fight/districts/district_4_plate_scorch.png" and g["d4"][1:3] == [42, 48] and g["d4"][3] == "district", g["d4"])
    if g["zip"]:
        import base64, struct
        zf = zipfile.ZipFile(io.BytesIO(base64.b64decode(g["zip"])))
        png = zf.read(g["g5"][0][0]); pw, ph = struct.unpack(">II", png[16:24])
        ck("v14.2: each 104 by 118: four pixels to a hex pixel's corner, the game's fit for a tile of ground", (pw, ph) == (104, 118), (pw, ph))

    # ---- once, and never over yours
    E("""()=>{ var P=KETER_PX, A=KETER_ASSETS; P.link({id:'D3-T21', name:'Aether Battery'},'token',null); P.link({name:'Ration Pack'},'art',null);
      A.detach('fight.locked_chest', A.ids('fight.locked_chest')[0], false);
      /* a picture as an older release shipped it, nobody having drawn on it */
      var q=P.get('px_keter_board_floor_bolts'), n=q.w*q.h, px=P.decode(q.frames[0].layers[0].px,n); px[0]=1; q.frames[0].layers[0].px=P.encode(px); q.shipped=P.mark(q); P.put(q,'px_keter_board_floor_bolts');
      return true; }""")
    pg.reload(); pg.wait_for_timeout(1800)
    o = E("""()=>{ var P=KETER_PX, A=KETER_ASSETS, crate=P.get('px_keter_board_crate'), n=crate.w*crate.h, px=P.decode(crate.frames[0].layers[0].px,n);
      var bolts=P.get('px_keter_board_floor_bolts');
      return {token:!!P.pictureFor({id:'D3-T21', name:'Aether Battery'},'token'), art:!!P.pictureFor({name:'Ration Pack'},'art'), chest:A.ids('fight.locked_chest').length, chestPic:P.has('px_keter_board_locked_chest'),
        crate:px[0]===133 && !crate.shipped, bolts:bolts.shipped===P.mark(bolts) && P.mark(bolts)===P.mark(window.KETER_ART.pics['px_keter_board_floor_bolts'])}; }""")
    ck("a token taken off a master Unit stays off, (v14.4) art taken off a card stays off, and a slot cleared stays clear (its picture kept in the library)", not o["token"] and not o["art"] and o["chest"] == 0 and o["chestPic"], o)
    ck("a picture you have drawn on is never replaced; one nobody has is brought up to this release", o["crate"] and o["bolts"], o)

    # ---- a token of yours on a master Unit before the game's art arrives
    ctx2 = b.new_context(viewport={"width": 412, "height": 915})
    pg2 = ctx2.new_page()
    pg2.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg2.add_init_script("""(()=>{ if(localStorage.getItem('keter-test-seeded')) return; localStorage.setItem('keter-test-seeded','1');
      var mine={v:1,w:24,h:24,name:'My battery',frames:[{layers:[{name:'Layer 1',visible:true,locked:false,opacity:100,mode:'view',px:btoa(String.fromCharCode(255,9,255,9,66,9))}]}],flat:'',kind:'token',grid:'square',id:'px_mine_battery'};
      localStorage.setItem('keter-app-pixels', JSON.stringify({px_mine_battery:mine}));
      localStorage.setItem('keter-app-pixellinks', JSON.stringify({'D3-T21':{token:'px_mine_battery'}, 'Aether Battery':{token:'px_mine_battery'}, 'Signal Flare':{art:'px_mine_battery'}})); })();""")
    pg2.goto("http://127.0.0.1:9353/"); pg2.wait_for_timeout(1800)
    y = pg2.evaluate("""()=>{ var P=KETER_PX, q=P.pictureFor({id:'D3-T21', name:'Aether Battery'},'token'), g=P.pictureFor({id:'D3-E02', name:'Arachnabot'},'token');
      return {mine:q&&q.id, other:g&&g.id}; }""")
    ck("a master Unit that already has a token of yours keeps it; the others get the game's", y["mine"] == "px_mine_battery" and y["other"] == "px_keter_token_arachnabot", y)
    y2 = pg2.evaluate("""()=>{ var P=KETER_PX, q=P.pictureFor({name:'Signal Flare'},'art'), g=P.pictureFor({name:'Grapple Line'},'art'); return {mine:q&&q.id, other:g&&g.id}; }""")
    ck("v14.4: a card that already has art of yours keeps it; the others get the game's", y2["mine"] == "px_mine_battery" and y2["other"] == "px_keter_art_grapple_line", y2)
    ctx2.close()

    # ---- the Pixel Studio: The fight, and tokens of 48
    ck("tokens can be 48 by 48: the Studio offers 16, 24, 32 and 48", E("()=>KETER_PX.TOKEN_SIZES.join()") == "16,24,32,48")
    E("()=>{ localStorage.setItem('keter-app-dev','1'); return true; }")
    pg.reload(); pg.wait_for_timeout(1600)
    E("()=>{ KETER_STUDIO.tab('library'); KETER_GO('studio'); return true; }"); pg.wait_for_timeout(500)
    pg.locator('[data-pxstab="assets"]').click(); pg.wait_for_timeout(500)
    seg = pg.locator("[data-asf='fight']")
    ck("the Assets tab has The fight: every slot drawn but the one cleared above", seg.count() == 1 and "23/24" in seg.inner_text(), seg.inner_text() if seg.count() else None)
    if seg.count():
        seg.click(); pg.wait_for_timeout(500)
        rows = pg.locator(".asrow.asslot")
        ck("its rows: the deck plates, pads, hazards, cover, crate, chest, Exit, Station and the stand-ins, each with its picture (the chest's slot empty)", rows.count() == 24 and pg.locator(".asrow.asslot canvas[data-pxt]").count() == 23, (rows.count(), pg.locator(".asrow.asslot canvas[data-pxt]").count()))
    ui = pg.locator("[data-asf='ui']")
    want = E("()=>{ var A=KETER_ASSETS, ui=A.slots().filter(function(s){ return s.group==='ui'; }); return ui.filter(function(s){ return A.ids(s.id).length; }).length+'/'+ui.length; }")
    ck("and Game look counts the fight's icons, marks, gems and card pictures, (v14.2) the menus' and (v14.3) the turn strip's and (v14.6) the card back, with its old slots (78 of 84 drawn: v14.12 adds Hardened's two)", ui.count() == 1 and want == "78/84" and want in ui.inner_text(), (want, ui.inner_text() if ui.count() else None))
    fxs = pg.locator("[data-asf='effects']")
    cbk = E("""()=>{ var AS=KETER_ASSETS, P=KETER_PX, q=P.get(AS.ids('ui.card.back')[0]); return q?[q.w,q.h,q.name,AS.gamesOwn(q)]:null; }""")
    ck("v14.6: the card back in its Game look slot, the game's own, 75 by 105", cbk == [75, 105, "Card back", True], cbk)
    ck("v14.3: Effects, its own group: every slot drawn (v14.5: the atmosphere's four with them)", fxs.count() == 1 and "9/9" in fxs.inner_text(), fxs.inner_text() if fxs.count() else None)
    e16 = E("""()=>{ var AS=KETER_ASSETS, P=KETER_PX; return {fx:['flash','impact','explosion','heal','shield'].map(function(k){ var q=P.get(AS.ids('fight.fx.'+k)[0]); return q?[P.frameCount(q), q.fps, q.w, q.h, AS.gamesOwn(q)]:null; }),
      act:['act_move','act_attack','act_end'].map(function(k){ var q=P.get(AS.ids('ui.icon.'+k)[0]); return q?[q.w,q.h,q.name,AS.gamesOwn(q)]:null; }),
      eye:(function(){ var q=P.get(AS.ids('ui.status.overwatch')[0]); return q?[q.w,q.h,q.name]:null; })()}; }""")
    ck("v14.3: each effect's slot holds the game's own, its frames and speed: 4 at 20, 5 at 16, 8 at 14, 6 at 12, 6 at 14", e16["fx"] == [[4, 20, 24, 24, True], [5, 16, 32, 32, True], [8, 14, 48, 48, True], [6, 12, 32, 48, True], [6, 14, 48, 48, True]], e16)
    ck("v14.3: and the turn strip's icons and End turn's, each the game's own, 16 by 16, under its slot's name; Hold fire's eye under Holding fire's",
       e16["act"] == [[16, 16, "Move icon", True], [16, 16, "Attack icon", True], [16, 16, "End turn icon", True]] and e16["eye"] == [16, 16, "Holding fire icon"], e16)
    ds = pg.locator("[data-asf='district']")
    ck("v14.2: District fights, its own group: every slot drawn", ds.count() == 1 and "42/42" in ds.inner_text(), ds.inner_text() if ds.count() else None)
    if ds.count():
        ds.click(); pg.wait_for_timeout(500)
        tx = E("()=>document.getElementById('v-studio').innerText")
        ck("v14.2: its rows: five plates and two covers for each District, each with its picture", pg.locator(".asrow.asslot").count() == 42 and pg.locator(".asrow.asslot canvas[data-pxt]").count() == 42
           and "District 5 plate: overgrown" in tx and "District 3 Full Cover: assembly frame" in tx, pg.locator(".asrow.asslot").count())
    mp = pg.locator("[data-asf='map']")
    if mp.count():
        mp.click(); pg.wait_for_timeout(500)
        tx = E("()=>document.getElementById('v-studio').innerText")
        ck("v14.2: World Map: the ground, the things, the icons and the Hangar, each with the game's pictures", "District 4 things" in tx and "The Hangar (the dock)" in tx and "Cache icon" in tx and "16×16" in tx and "64×64" in tx, tx[:300])
    # ---- (v14.2) the Companion's World Map stands them as the game does
    E("()=>{ KETER_GO('world'); return true; }"); pg.wait_for_timeout(700)
    w = E("""()=>{ var W=KETER_WORLD, AS=KETER_ASSETS, m=W.map(); KETER_WORLD_UI._sel(null); KETER_WORLD_UI.render(); var V=KETER_WORLD_UI.state().view;
      var hash=function(str){ var h=0; for(var i=0;i<str.length;i++) h=(h*31+str.charCodeAt(i))>>>0; return h; };
      var look=function(k){ var a=W.parse(k); V.size=30; V.cx=V.w/2-Math.sqrt(3)*30*(a.q+a.r/2); V.cy=V.h/2-1.5*30*a.r; };
      var sample=function(){ KETER_WORLD_UI._paint(); var cv=document.getElementById('wldCv'), g=cv.getContext('2d'), d=V.dpr||1, out=[];
        for(var y=-56;y<6;y+=2) for(var x=-30;x<30;x+=2){ var px=g.getImageData(Math.round((V.w/2+x)*d), Math.round((V.h/2+y)*d),1,1).data; out.push(px[0]+','+px[1]+','+px[2]); } return out; };
      var without=function(slot){ var ids=AS.ids(slot); ids.forEach(function(id){ AS.detach(slot,id,false); }); var r=sample(); ids.forEach(function(id){ AS.attach(slot,id); }); return r; };
      var differ=function(a,b){ var n=0; for(var i=0;i<a.length;i++) if(a[i]!==b[i]) n++; return n; };
      look(m.dock); var hangar=differ(sample(), without('map.icon.dock'));
      var k=Object.keys(m.tiles).filter(function(x){ return m.tiles[x].d==='3' && x!==m.dock && !W.contentAt(x) && hash(x+'p')%5===0; })[0], thing=-1;
      if(k){ look(k); thing=differ(sample(), without('map.prop.3')); }
      /* (v14.12) and none of its neighbours has one either: a thing stands up from its tile into the one behind it, which read as this tile's, now and then */
      var clear=function(x){ var a=W.parse(x); return [[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]].every(function(d){ var nk=(a.q+d[0])+','+(a.r+d[1]); return !m.tiles[nk] || hash(nk+'p')%5!==0; }); };
      var other=Object.keys(m.tiles).filter(function(x){ return m.tiles[x].d==='3' && x!==m.dock && !W.contentAt(x) && hash(x+'p')%5!==0 && clear(x); })[0], none=-1;
      if(other){ look(other); none=differ(sample(), without('map.prop.3')); }
      return {hangar:hangar, thing:thing, none:none, k:k}; }""")
    ck("v14.2: the Companion's World Map stands the Hangar over the dock, and a District's thing on one empty tile in five (not the others)", w["hangar"] > 150 and w["thing"] > 20 and w["none"] == 0, w)
    ck("no page errors", not errs, errs[:3])
    print("  (the picture library holds %d characters)" % E("()=>KETER_PX.libBytes()"))
    b.close()
srv.shutdown()
print(f"\nSHIPPED ART PASS {len(ok)}  FAIL {len(bad)}")
for z in bad: print("  ✗", z)
