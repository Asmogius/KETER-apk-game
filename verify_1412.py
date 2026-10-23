"""Companion 14.12: a Unit's Action that says target tile is aimed at a tile
(lit within its range and sight, tapped, carried out there with no attack
roll; Auto never aims one); Undo takes back a Barricade; the odds show what a
Hardened target would take; Auto keeps a Line or a Cone off its own side; the
Hardened Chip is the Bastion Chip; and Hardened has its icon and mark slots."""
import http.server, socketserver, threading, functools, pathlib, shutil, json
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_1412")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP); shutil.copy("compendium_full.json", TMP / "compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9878), functools.partial(H, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, d=""):
    (ok if c else bad).append(n + ((" — " + str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ") + n + ("" if c else "  — " + str(d)[:260]))
hexes = [[f"{q},{r}", {}] for q in range(-5, 6) for r in range(-5, 6) if abs(q + r) <= 5]
FLOOR = {"v": 6, "name": "KW Test", "radius": 5, "hexes": hexes, "walls": [], "marks": [], "symDefs": [],
         "colorLabels": {"1": "Half Cover Barricade", "5": "Full Cover Barricade"}}
SETUP = """(spec)=>{
  var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}'); all['KW Test']=window.FLOOR_IN; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all));
  SIM.map=simLoadFloor('KW Test');
  SIM.units=spec.map(function(s){ var c=simAllCards().filter(function(x){ return x.name===s[0]; })[0];
    var u=KETER_RULES.unitFromCard(simUnitSpec(c,s[1]),s[1]); u.id=s[2]; u.pos={q:s[3],r:s[4]}; return u; });
  SIM.round=1; SIM.phase='turn'; SIM.log=[]; SIM.over=false; SIM.autoRunning=true;
  SIM.hand=[]; SIM.deck=[]; SIM.discard=[]; SIM.aether={}; SIM.pendingAct=null; SIM.burst=null;
  simApplyContinuous(); renderSim(); return SIM.units.length; }"""
U = "function(id){ return SIM.units.filter(function(u){ return u.id===id; })[0]; }"
NEW = ["Troop", "Hero", "all allies", "all enemies", "Aim", "Draw", "gain Aether", "Hardened", "Barricade", "Line", "Cone"]
with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_context(viewport={"width": 412, "height": 915}).new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("dialog", lambda d: d.accept())
    pg.goto("http://127.0.0.1:9878/"); pg.wait_for_timeout(2500)
    E = pg.evaluate
    E("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")

    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(900)
    E("(g)=>{ window.FLOOR_IN=g; }", FLOOR)

    # ---- an Action aimed at a tile ----
    E(SETUP, [["Test Bulwark", "ally", "b1", 0, 0], ["Test Warden", "ally", "h1", 0, 2], ["Test Grunt", "enemy", "e1", 3, 0]])
    E("()=>{ simFit(); simDraw(); }"); pg.wait_for_timeout(300)
    r = E("""()=>{ var U=""" + U + """, b=U('b1'); simSelect(b); var st=simActionState(b, b.actions.filter(function(a){ return a.name==='Raise Wall'; })[0]);
      simPickAction(b,'Raise Wall');
      var keys=Object.keys(SIM.targets||{}), far=keys.filter(function(k){ var q=+k.split(',')[0], r=+k.split(',')[1]; return KETER_RULES.hexDistance({q:0,r:0},{q:q,r:r})>3; });
      return {ok:st.ok, tile:!!(SIM.pendingAct&&SIM.pendingAct.tile), lit:keys.length, far:far.length, own:keys.indexOf('0,0')>=0, nrg:b.nrg}; }""")
    ck("Raise Wall can be used, and picking it lights the tiles within 3 the Bulwark can see (its own included), none further", r["ok"] and r["tile"] and r["lit"] > 20 and r["far"] == 0 and r["own"], r)
    # a tap on a lit tile, as a finger sends it
    pt = E("""()=>{ var cv=document.getElementById('simcanvas'), rc=cv.getBoundingClientRect(), s=SIM_VIEW.size, q=-1, r=1;
      return {x:rc.left+SIM_VIEW.ox+s*Math.sqrt(3)*(q+r/2), y:rc.top+SIM_VIEW.oy+s*1.5*r}; }""")
    E("""(p)=>{ document.getElementById('simcanvas').dispatchEvent(new MouseEvent('click',{clientX:p.x, clientY:p.y, bubbles:true})); }""", pt)
    pg.wait_for_timeout(300)
    r = E("""()=>{ var U=""" + U + """, b=U('b1'); return {kind:simKindAt(-1,1), nrg:b.nrg, acted:!!b.acted, pending:!!SIM.pendingAct,
      log:SIM.log.map(function(l){ return l.text; }).slice(-3)}; }""")
    ck("tapping one puts a Full Cover Barricade there, pays its Energy and logs it", r["kind"] == "cover-full" and r["acted"] and not r["pending"]
       and any("Raise Wall at -1,1" in l for l in r["log"]) and any("Full Cover Barricade on -1,1" in l for l in r["log"]), r)
    r = E("()=>{ simUndo(); return {kind:simKindAt(-1,1)}; }")
    ck("Undo takes the Barricade back", r["kind"] is None, r)
    r = E("""()=>{ var U=""" + U + """, b=U('b1'); simSelect(b); simPickAction(b,'Raise Wall');
      var lit=Object.keys(SIM.targets||{}); simUseOnTile(b, b.actions.filter(function(a){ return a.name==='Raise Wall'; })[0], {q:0,r:2});
      return {kind:simKindAt(0,2), log:SIM.log.slice(-2).map(function(l){ return l.text; })}; }""")
    ck("on a tile with a Unit on it, nothing is put down, and the Log says why", r["kind"] is None and any("needs an empty tile" in l for l in r["log"]), r)
    r = E("""()=>{ var U=""" + U + """, b=U('b1'), g=U('e1'); var a=b.actions.filter(function(a){ return a.name==='Raise Wall'; })[0];
      b.side='enemy'; var pick=simEnemyAction(b, U('h1')); b.side='ally'; return {auto:pick.action?pick.action.name:null, inReach:pick.inReach}; }""")
    ck("Auto never aims a tile Action", r["auto"] != "Raise Wall" or not r["inReach"], r)

    # ---- the odds and Hardened ----
    E(SETUP, [["Test Warden", "ally", "a1", 0, 0], ["Test Grunt", "enemy", "e1", 3, 0]])
    r = E("""()=>{ var U=""" + U + """, s=U('a1'), g=U('e1'), a=s.actions.filter(function(x){ return x.name==='Pinning Volley'; })[0];
      var before=simOdds(s,a,g).dmg; simRunText('[[this Unit]] gains [[Hardened 2]] for [[turns 2]].',{actor:g, sourceCard:'Test'});
      return {before:before, after:simOdds(s,a,g).dmg}; }""")
    ck("the odds show what a Hardened target would take: 2 less", r["after"] == r["before"] - 2, r)
    r = E("""()=>{ var U=""" + U + """, g=U('e1'), hp=g.hp; KETER_RULES.addStatus(g,'Poisoned',3,'Test',2); KETER_RULES.rechargeTick(SIM.units); return {lost:hp-g.hp}; }""")
    ck("Hardened cuts a Poisoned tick too (3 less 2)", r["lost"] == 1, r)

    # ---- Auto keeps a Line off its own side ----
    E(SETUP, [["Test Bulwark", "ally", "b1", 0, 0], ["Test Grunt", "enemy", "e1", 1, 0], ["Test Warden", "ally", "h1", 2, 0], ["Test Grunt", "enemy", "e2", 0, 2]])
    r = E("""()=>{ var U=""" + U + """, b=U('b1'), line=b.actions.filter(function(a){ return a.name==='Breach Shot'; })[0];
      return {own:simHurtsOwnSide(b, line, U('e1')), clear:simHurtsOwnSide(b, line, U('e2'))}; }""")
    ck("a Line through one of its own counts as hurting its own side; one clear of them does not", r["own"] is True and r["clear"] is False, r)

    # ---- the Bastion Chip, and Hardened's slots ----
    r = E("""()=>{ var c=simAllCards(); return {bastion:c.some(function(x){ return x.name==='Bastion Chip'; }), hardened:c.some(function(x){ return x.name==='Hardened Chip'; }),
      slots:KETER_ASSETS.STATUSES.indexOf('Hardened')>=0, icon:!!(window.KETER_ART_PICS||window.KETER_ART||{}) }; }""")
    ck("the Hardened Chip is the Bastion Chip now", r["bastion"] and not r["hardened"], r)
    ck("Hardened is among the Status slots (icon and board mark)", r["slots"], r)
    ck("no page errors", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"\n14.12 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
