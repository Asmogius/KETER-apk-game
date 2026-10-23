"""Test cards, test floors, toggle filters and the Simulator's debug mode."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, re
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_debug")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9991),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

# ---- the test cards, as data ----
comp=json.load(open("compendium_full.json"))
tests=[c for c in comp["cards"] if c.get("testCard")]
ck("there are test cards", len(tests)>=20, len(tests))
used_types={c["cardType"] for c in tests}
for t in ["hero","troop","enemy","elite","miniboss","action","equipment","command","aether","consumable","prototype","sphere"]:
    ck(f"a test card of type {t}", t in used_types)
ck("no test card is a Boss or a World Tile, which never enter a fight",
   not ({"boss","worldtile"} & used_types))
ids=[c["id"] for c in comp["cards"] if c.get("id")]
ck("every test card has a real number, and no number is used twice", len(ids)==len(set(ids)))
ck("each test card says what it should do", all(c.get("testExpect") for c in tests))

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9991/"); pg.wait_for_timeout(2400)

    # ---- every keyword is used by a test card ----
    r=pg.evaluate("""(cards)=>{ var K=window.KETER_KW, used={}, bad=[];
      cards.forEach(function(c){ (c.entries||c.abilities||[]).forEach(function(a){
        K.parse(a.text).forEach(function(q){ if(q.type!=='kw') return;
          if(q.kw) used[q.kw.name]=1; else bad.push(c.name+': '+q.name); }); }); });
      return {missing:K.KEYWORDS.map(function(k){return k.name;}).filter(function(n){return !used[n];}), bad:bad}; }""", tests)
    ck("the test cards use every keyword in the library", not r["missing"], r["missing"])
    ck("and every coloured word on them is a real keyword", not r["bad"], r["bad"][:3])

    # ---- the test floors ----
    floors=pg.evaluate("()=>Object.keys(JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}')).filter(function(k){return /^TEST/.test(k);})")
    ck("four test floors join the floor library", len(floors)==4, floors)
    pg.evaluate("""()=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels'));
      all['TEST \u00b7 Waves'].notes='EDITED'; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); }""")
    pg.reload(); pg.wait_for_timeout(2200)
    ck("a test floor you have edited is not overwritten",
       pg.evaluate("()=>JSON.parse(localStorage.getItem('keter-hexmap-levels'))['TEST \u00b7 Waves'].notes")=="EDITED")
    r=pg.evaluate("""()=>{ var R=window.KETER_RULES, M=window.KETER_TEST_MAPS[0], w={};
      M.walls.forEach(function(x){ w[x[0]]=1; });
      return {lone:R.lineOfSight({q:-4,r:1},{q:-4,r:0},w), run:R.lineOfSight({q:0,r:2},{q:0,r:-2},w),
              corner:R.lineOfSight({q:3,r:0},{q:4,r:-1},w)}; }""")
    ck("Sight Lines: a lone segment does not block the tile behind it", r["lone"] is True)
    ck("Sight Lines: the wall run blocks", r["run"] is False)
    ck("Sight Lines: the sealed corner seals", r["corner"] is False)

    # ---- toggle filters in the Card Browser ----
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(1400)
    F="()=>compFiltered()"
    n_all=pg.evaluate(F+".length")
    ck("Test Cards is a source", pg.locator('[data-fg="src"][data-fv="test"]').count()==1)
    ck("every filter starts lit", pg.locator(".fchip:not(.on)").count()==0)
    pg.locator("#cFilters").click(); pg.wait_for_timeout(300)
    pg.locator('[data-fg="src"][data-fv="test"]').click(); pg.wait_for_timeout(300)
    ck("switching Test Cards off hides them", pg.evaluate(F+".filter(function(c){return c._src==='test';}).length")==0)
    pg.locator('[data-fg="type"][data-fv="enemy"]').click(); pg.wait_for_timeout(300)
    ck("several filters can be off at once", pg.evaluate(F+".filter(function(c){return c.cardType==='enemy';}).length")==0
       and pg.evaluate(F+".length")<n_all)
    pg.locator("#cReset").click(); pg.wait_for_timeout(300)
    ck("Show everything brings them all back", pg.evaluate(F+".length")==n_all)

    # ---- debug mode ----
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(600)
    ck("Debug combat is hidden while debug mode is off", not pg.locator("#simDebugQuick").is_visible())
    pg.locator("#simGear").click(); pg.wait_for_timeout(300)
    ck("the Settings dice choice shows which is chosen",
       pg.locator("#simDiceAuto").evaluate("e=>e.classList.contains('on')") !=
       pg.locator("#simDiceManual").evaluate("e=>e.classList.contains('on')"))
    ck("buttons styled btn are styled at all",
       pg.evaluate("""()=>{ var b=document.createElement('button'); b.className='btn'; document.body.appendChild(b);
         var c=getComputedStyle(b).borderTopColor; b.remove(); return c; }""")=="rgb(51, 80, 94)")
    pg.locator("#simDebugOnBtn").click(); pg.wait_for_timeout(300)
    ck("debug mode can be switched on", pg.evaluate("()=>simDebugOn()"))
    pg.evaluate("()=>document.getElementById('modal').classList.remove('on')")
    ck("then Debug combat appears", pg.locator("#simDebugQuick").is_visible())
    team=pg.evaluate("()=>simTestTeam()")
    ck("the Test Strike Team is built from the test cards", len(team["heroes"])>=2 and len(team["deck"])>=10)
    ck("and heads the Strike Team list", pg.evaluate("()=>simLoadoutList()[0].isTestTeam===true"))
    pg.locator("#simDebugQuick").click(); pg.wait_for_timeout(400)
    ck("it offers every test floor", pg.locator("[data-dbgfloor]").count()==4)
    pg.locator('[data-dbgfloor="TEST \u00b7 Corridor"]').click(); pg.wait_for_timeout(2600)
    ck("a debug fight starts straight away", pg.evaluate("()=>SIM.round")==1)
    ck("and is marked DEBUG", pg.locator("#simRound .dbgflag").count()==1)
    ck("both test Heroes enter, since the floor is Medium",
       pg.evaluate("()=>SIM.units.filter(function(u){return /hero/i.test(u.cardType||'');}).length")==2)
    ck("each carries its assigned test Action Card", pg.evaluate("""()=>SIM.units.filter(function(u){
       return /hero/i.test(u.cardType||''); }).every(function(u){ return (u.actions||[]).some(function(a){
       return /Piercing|Overclock/.test(a.name); }); })"""))
    ck("only test Enemies are drawn", pg.evaluate("""()=>SIM.enemyPile.concat(SIM.units.filter(function(u){return u.side==='enemy';}))
       .every(function(e){ return /^Test /.test(e.name); })"""))
    ck("test tokens are told apart, not all TES", pg.evaluate("()=>SIM.units.length")>1)
    ck("no tile sits under the hand", pg.evaluate("""()=>{ var cv=document.getElementById('simcanvas').getBoundingClientRect(),
       d=document.getElementById('simdock').getBoundingClientRect();
       return Object.keys(SIM.map.hexes).every(function(k){ var a=window.KETER_RULES.hexParse(k);
         return cv.top+1.5*SIM_VIEW.size*a.r+SIM_VIEW.oy < d.top-SIM_VIEW.size*0.5; }); }"""))

    # ---- a fight survives the app being reopened ----
    before=pg.evaluate("()=>JSON.stringify({r:SIM.round,p:SIM.phase,n:SIM.units.length,h:SIM.hand.length,m:SIM.map&&SIM.map.name,a:SIM.aether})")
    pg.reload(); pg.wait_for_timeout(2400)
    if pg.locator('.lt[data-page="battle"]').is_visible():
        pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)
    after=pg.evaluate("()=>SIM.map?JSON.stringify({r:SIM.round,p:SIM.phase,n:SIM.units.length,h:SIM.hand.length,m:SIM.map&&SIM.map.name,a:SIM.aether}):'no fight'")
    ck("a reload brings back the whole fight: map, Units, hand and Aether", after==before, before+" -> "+after)

    # ---- the tools ----
    pg.locator('[data-simtab="debug"]').click(); pg.wait_for_timeout(300)
    ck("the Debug tab has the tools and the checklist", pg.locator(".dbgh").count()>=4)
    pg.locator("#dbgDie").fill("20"); pg.locator("#dbgForce").click(); pg.wait_for_timeout(150)
    pg.locator("#dbgDie").fill("1"); pg.locator("#dbgForce").click(); pg.wait_for_timeout(150)
    r=pg.evaluate("()=>[simDice().roll('d20'), simDice().roll('d20'), SIM_FORCE.length]")
    ck("forced dice come out in order, then the dice roll normally", r==[20,1,0], r)
    a0=pg.evaluate("()=>SIM.aether.generic||0"); pg.locator('[data-dbgae="generic"]').click(); pg.wait_for_timeout(150)
    ck("Aether can be given", pg.evaluate("()=>SIM.aether.generic||0")==a0+3)
    h0=pg.evaluate("()=>SIM.hand.length"); pg.locator("#dbgCard").select_option("Test Mortar Strike"); pg.locator("#dbgDraw").click(); pg.wait_for_timeout(200)
    ck("any card can be put in hand, keywords and all",
       pg.evaluate("()=>SIM.hand.length")==h0+1 and pg.evaluate("()=>SIM.hand[SIM.hand.length-1].effects.length")>0)
    pg.evaluate("()=>{ simSelect(SIM.units.filter(function(u){return u.side==='enemy';})[0]); SIM.tab='debug'; renderSim(); }"); pg.wait_for_timeout(200)
    pg.locator("#dbgHp").fill("1"); pg.locator("#dbgNrg").fill("0"); pg.locator("#dbgSetStats").click(); pg.wait_for_timeout(150)
    # 15.4: Rooted has no strength, so its 3 goes in the Turns box (16.0: a lock lasts 2 at most)
    pg.locator("#dbgStatus").select_option("Rooted"); pg.locator("#dbgStatusT").fill("3"); pg.locator("#dbgAddStatus").click(); pg.wait_for_timeout(150)
    r=pg.evaluate("()=>{ var e=SIM.units.filter(function(u){return u.side==='enemy';})[0]; return [e.hp, e.nrg, window.KETER_RULES.statusTurns(e,'Rooted')]; }")
    ck("a Unit's Health, Energy and Statuses can be set (a lock held to 2 turns)", r==[1,0,2], r)
    t=pg.evaluate("()=>{ var ks=Object.keys(SIM.map.hexes).filter(function(k){ var a=window.KETER_RULES.hexParse(k); return !simUnitAt(a.q,a.r); }); return window.KETER_RULES.hexParse(ks[3]); }")
    pg.locator("#dbgPlaceCard").select_option("Test Juggernaut"); pg.locator("#dbgPlace").click(); pg.wait_for_timeout(150)
    n0=pg.evaluate("()=>SIM.units.length"); pg.evaluate(f"()=>simDebugTap({{q:{t['q']},r:{t['r']}}})"); pg.wait_for_timeout(150)
    ck("any card can be placed as a Unit", pg.evaluate("()=>SIM.units.length")==n0+1)
    pg.evaluate("()=>{ SIM.tab='debug'; renderSim(); }"); pg.wait_for_timeout(150)
    pg.locator("#dbgMove").click(); pg.wait_for_timeout(150)
    t2=pg.evaluate("()=>{ var ks=Object.keys(SIM.map.hexes).filter(function(k){ var a=window.KETER_RULES.hexParse(k); return !simUnitAt(a.q,a.r); }); return window.KETER_RULES.hexParse(ks[ks.length-1]); }")
    pg.evaluate("()=>simSelect(SIM.units.filter(function(u){return u.name==='Test Warden';})[0])")
    pg.evaluate(f"()=>simDebugTap({{q:{t2['q']},r:{t2['r']}}})"); pg.wait_for_timeout(150)
    ck("a Unit can be moved anywhere", pg.evaluate("()=>JSON.stringify(SIM.units.filter(function(u){return u.name==='Test Warden';})[0].pos)")==json.dumps(t2,separators=(",",":")))
    pg.evaluate("()=>{ SIM_DBG.move=false; SIM.tab='debug'; renderSim(); }"); pg.wait_for_timeout(150)
    total=re.search(r"of (\d+)", pg.locator(".dbgh span").last.inner_text())
    ck("the checklist lists what each test card should do", total and int(total.group(1))>=40, pg.locator(".dbgh span").last.inner_text())
    pg.locator("[data-dbgck]").first.check(); pg.wait_for_timeout(250)
    ck("ticking an item counts it", pg.locator(".dbgh span").last.inner_text().startswith("1 of"))
    pg.reload(); pg.wait_for_timeout(2200)
    ck("and the tick is remembered", len(pg.evaluate("()=>Object.keys(JSON.parse(localStorage.getItem('keter-app-testcheck')||'{}'))"))==1)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"DEBUG PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
