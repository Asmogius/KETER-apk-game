"""Content batch 1 (Revision 16.2, Companion 14.9): District 3's fast melee.
Its 18 cards in the Compendium, the Skitter Frame in the chassis library with
its two pre-built Troops in the Workshop, the movement blueprints in District
3's pool, cards in the haul (the tables' Card %, the pool by Skull Level, a
card found kept at the dock), a Support Action aimed only at this Unit used at
once in the Battle Simulator, the four gantry chunks, and each new Unit's
token and card's picture."""
import http.server, socketserver, threading, functools, pathlib, shutil, json
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_batch1")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP); shutil.copy("compendium_full.json", TMP / "compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9874), functools.partial(H, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, d=""):
    (ok if c else bad).append(n + ((" — " + str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ") + n + ("" if c else "  — " + str(d)[:260]))

BATCH = ["Skitterling", "Skitter Stalker", "Brood Matriarch", "Ilsa Varn, Jump-Frame Pilot", "Kinetic Surge", "Gravity Well",
         "Leaper Greaves", "Momentum Plating", "Flank Them", "Pin the Runner", "Spring Chip", "Gyro Chip", "Grav-Boot Charge",
         "Adrenal Overdrive", "Vault Strike", "Skitter Step", "Kinetic Recycler", "Gantry Mapper"]
comp = json.loads(pathlib.Path("compendium_full.json").read_text(encoding="utf-8"))["cards"]
mine = [c for c in comp if c.get("batch") == 1]
ck("the Compendium holds batch 1's 18 cards, each marked batch 1", sorted(c["name"] for c in mine) == sorted(BATCH) and all(str(c.get("id", "")).startswith("D3-") for c in mine),
   sorted(c["name"] for c in mine))
hb = pathlib.Path("handbook_v14-0.md").read_text(encoding="utf-8")
ck("the Handbook is past Version 16.2 (16.3 since 14.11), with Revision 16.2's self-targeted Support Actions and cards in the haul", "**Version 16.3" in hb and "Revision 16.2" in hb and "Cards in the haul" in hb)

with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_context(viewport={"width": 412, "height": 915}).new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("dialog", lambda d: d.accept())
    pg.goto("http://127.0.0.1:9874/"); pg.wait_for_timeout(2500)
    E = pg.evaluate
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")

    # ---- the frame and its Troops ----
    r = E("""()=>{ var C=KETER_CHASSIS, WS=KETER_WORKSHOP, ch=C.get('ch_skitter_frame');
      var pre=WS.prebuilts().filter(function(d){ return d.chassis==='ch_skitter_frame'; });
      return {ch:ch?{d:ch.district, plan:ch.bodyPlan, sub:ch.subtypes, cap:ch.powerCap, ab:ch.abilityCap, st:ch.stats, al:ch.allowed}:null,
        pre:pre.map(function(d){ return [d.name, WS.check(d).ok]; }),
        cards:WS.prebuiltCards().filter(function(c){ return /^Skitter /.test(c.name); }).map(function(c){ return c.name; })}; }""")
    ck("the Skitter Frame is in the chassis library: District 3, a Hexapod for Melee, power 14, two abilities",
       r["ch"] and r["ch"]["d"] == "3" and r["ch"]["plan"] == "Hexapod" and r["ch"]["sub"] == ["Melee"] and r["ch"]["cap"] == 14 and r["ch"]["ab"] == 2
       and r["ch"]["st"] == {"hp": 12, "ac": 11, "move": 5, "dmg": 3, "nrg": 3, "int": 10} and all(k in r["ch"]["al"] for k in ("Lunge", "Charge", "Dash", "Leap")), r)
    ck("its two pre-built Troops are in the Workshop, each fitting the frame, and go in the export",
       r["pre"] == [["Skitter Runner Mk I", True], ["Skitter Harrier Mk I", True]] and r["cards"] == ["Skitter Runner Mk I", "Skitter Harrier Mk I"], r)
    r = E("""()=>{ var WS=KETER_WORKSHOP, d=WS.get('ds_pre_skitter_runner'); d.name='Mine'; WS.put(d); location.reload(); return 1; }""")
    pg.wait_for_timeout(2500)
    ck("a pre-built one changed in Dev Mode is left as it is", E("()=>KETER_WORKSHOP.get('ds_pre_skitter_runner').name") == "Mine")
    ck("District 3's pool starts with the Lunge, Charge, Dash and Leap blueprints",
       E("()=>{ var it=KETER_PROG.pools()['3'].items; return ['bp:Lunge:1','bp:Charge:1','bp:Dash:1','bp:Leap:1'].every(function(i){ return it.indexOf(i)>=0; }); }"))

    # ---- cards in the haul ----
    r = E("""()=>{ var L=KETER_LOOT.tables().sources, W=KETER_WORLD.tables(), P=KETER_PROG, D=KETER_DOCK;
      var before=D.owned('Grav-Boot Charge'), granted=P.grant('cd:Grav-Boot Charge');
      return {loot:['enemy','elite','miniboss','boss','lootTile','chest'].map(function(k){ return L[k].card; }), cache:W.cache.card, poi:W.poi.card,
        s1:P.cardPool('3',1), s3:P.cardPool('3',3), granted:granted, n:D.owned('Grav-Boot Charge')-before, name:P.itemName ? P.itemName('cd:Grav-Boot Charge') : null}; }""")
    ck("the tables' Card %: an Elite 25, a Mini-Boss 50, a Boss 100, a Locked Chest 10; a Cache 20 and a POI's reward 30",
       r["loot"] == [0, 25, 50, 100, 0, 10] and r["cache"] == 20 and r["poi"] == 30, r)
    ck("a Skull 1 haul's cards are common ones only; Skull 3 adds the rare ones",
       "Grav-Boot Charge" in r["s1"] and "Adrenal Overdrive" not in r["s1"] and "Kinetic Recycler" in r["s3"] and not any(n.startswith("Test ") for n in r["s3"]), r)
    ck("a card found is kept at the dock", r["granted"] is True and r["n"] == 1, r)
    html = pg.content()
    ck("the Loot and World Map table editors have a Card % column", "Card %" in html and ':card"' in html and 'cache.card' in html and 'poi.card' in html)

    # ---- the four chunks ----
    r = E("""()=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}'), ch=Object.keys(all).filter(function(k){ return all[k].chunk; });
      return {n:ch.length, mine:ch.filter(function(k){ return /Gantry Landing|Skitter Nest|Gantry Crossing|Catwalk Run/.test(k); }).map(function(k){ return [k, all[k].chunk.role]; })}; }""")
    ck("the four gantry chunks join the floor library: 20 in all", r["n"] == 20 and sorted(x[1] for x in r["mine"]) == ["enemy", "enemy", "filler", "start"], r)

    # ---- art ----
    r = E("""(names)=>{ var P=KETER_PX, list=KETER_ASSETS.cardList();
      function card(n){ return list.filter(function(c){ return c.name===n && c._src==='master'; })[0] || {name:n}; }
      return names.map(function(n){ var c=card(n), unit=/troop|enemy|hero|elite|miniboss/.test(String(c.cardType||'')) || /Mk I$/.test(n);
        var q=P.pictureFor(c, unit?'token':'art'); return [n, unit?'token':'art', q?q.id:null]; }); }""", BATCH + ["Skitter Runner Mk I", "Skitter Harrier Mk I"])
    missing = [x for x in r if not x[2]]
    ck("each of batch 1's Units and the two pre-built Troops wears its token, and each of its cards its picture", not missing, missing)

    # ---- a Support Action aimed only at this Unit ----
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(900)
    hexes = [[f"{q},{r}", {}] for q in range(-4, 5) for r in range(-4, 5) if abs(q + r) <= 4]
    E("""(g)=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}'); all['Batch Test']=g; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); }""",
      {"v": 6, "name": "Batch Test", "radius": 4, "hexes": hexes, "walls": [], "marks": [], "symDefs": [], "colorLabels": {}})
    r = E("""()=>{ SIM.map=simLoadFloor('Batch Test');
      function mk(n,side,id,q,r){ var c=simAllCards().filter(function(x){ return x.name===n; })[0]; var u=KETER_RULES.unitFromCard(simUnitSpec(c,side),side); u.id=id; u.pos={q:q,r:r}; return u; }
      SIM.units=[mk('Ilsa Varn, Jump-Frame Pilot','ally','a1',-2,1), mk('Test Grunt','enemy','e1',2,-2)];
      SIM.round=1; SIM.phase='turn'; SIM.log=[]; SIM.over=false; SIM.autoRunning=true; SIM.hand=[]; SIM.deck=[]; SIM.discard=[]; SIM.aether={}; SIM.pendingAct=null; SIM.burst=null;
      simApplyContinuous(); renderSim();
      var il=SIM.units[0], n0=il.nrg, jj=il.actions.filter(function(a){ return a.name==='Jump Jets'; })[0];
      simSelect(il); simPickAction(il,'Jump Jets');
      return {self:true, log:SIM.log.map(function(l){ return l.text||l; }), nrg:n0-il.nrg, cost:+jj.cost||0, acted:!!il.acted,
        leap:(il.mods||[]).some(function(m){ return m.stat==='LEAP' && +m.amt===4; }), pending:!!SIM.pendingAct, targets:Object.keys(SIM.targets||{}).length}; }""")
    ck("in the Battle Simulator, Jump Jets (aimed only at this Unit) is used the moment it is picked: paid for, logged, Leap 4",
       r["self"] and any("used Jump Jets" in str(l) for l in r["log"]) and r["nrg"] == r["cost"] and r["acted"] and r["leap"] and not r["pending"] and r["targets"] == 0, r)

    ck("no page errors", not errs, errs)
    b.close()
srv.shutdown()
print("\nBATCH1 PASS %d  FAIL %d" % (len(ok), len(bad)))
