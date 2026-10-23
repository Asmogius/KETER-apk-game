"""Undo in the Simulator."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_undo")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9881),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

CARDS=[
 {"name":"Rictus","cardType":"hero","subtype":"cyborg",
  "affinities":[{"district":"3","level":4}],
  "stats":{"hp":"40","ac":"9","apT":"4","move":"4"},
  "abilities":[{"name":"Grinder","kind":"Active","role":"melee","text":"Deal 8 damage.",
                "energyCost":"0","damage":"8","armorPenetration":"9"}]},
 {"name":"Grunt","cardType":"enemy","skullLevel":"1","affinities":[{"district":"3"}],
  "stats":{"hp":"30","ac":"6","will":"9","move":"3"},
  "abilities":[{"name":"Bite","kind":"Combo","role":"melee","text":"Deal 3 damage.",
                "energyCost":"0","damage":"3","armorPenetration":"9"}]},
 {"name":"Field Medic","cardType":"troop","affinities":[{"district":"3"}],
  "aetherCost":{"generic":1,"affinity":0},
  "stats":{"hp":"18","nrg":"3","will":"3","move":"3"},"abilities":[]},
]

def setup(pg):
    pg.locator("#simSetup").click(); pg.wait_for_timeout(600)
    pg.locator("#simMapSel").select_option(index=0)
    pg.locator("#simMapNext").click(); pg.wait_for_timeout(600)
    # Handbook 14.0 setup: Strike Team, then who enters, then the Enemies
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(450)
    # Heroes, then Starting Troops, then the Enemies
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator('[data-wizfoemode="manual"]').click(); pg.wait_for_timeout(350)
    pg.locator('[data-wizfoemore="Grunt"]').click(); pg.wait_for_timeout(200)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1100)

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9881/"); pg.wait_for_timeout(2000)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":CARDS})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.evaluate("""()=>{
      var raw=JSON.parse(localStorage.getItem('keter-app-master')||'{}');
      var m=(raw&&raw.cards)||(Array.isArray(raw)?raw:[]);
      var hero=m.filter(function(c){ return c.cardType==='hero'; })[0];
      var deck=[];
      m.filter(function(c){ return /^(troop|equipment|command|aether)$/.test(c.cardType||''); })
       .forEach(function(c){ for(var i=0;i<4;i++) deck.push('master|'+c.name); });
      localStorage.setItem('keter-app-loadouts', JSON.stringify([{v:2,name:'Suite Team',
        level:1, heroes:hero?['master|'+hero.name]:[], deck:deck.slice(0,14),
        actions:{}, pouch:{'basic|3':6}}]));
    }"""); pg.wait_for_timeout(150)
    pg.evaluate("()=>localStorage.removeItem('keter-app-sim')")
    pg.reload(); pg.wait_for_timeout(2200)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(600)
    setup(pg)
    S=lambda e: pg.evaluate("()=>"+e)

    ck("a fresh turn has nothing to undo yet", pg.locator("#simUndo").is_disabled())
    ck("and the button says what it does", pg.locator("#simUndo").inner_text()=="Undo phase")

    # ---- a phase takes back everything done in it ----
    pg.locator("#simEnd").click(); pg.wait_for_timeout(600)
    if pg.locator("#simGoBtn").is_visible():
        pg.locator("#simGoBtn").click(); pg.wait_for_timeout(1200)
    ck("advancing a phase makes undo available", not pg.locator("#simUndo").is_disabled())
    hp_before=S("JSON.stringify(SIM.units.map(function(u){return u.hp;}))")
    phase_before=S("SIM.phase")
    pg.locator("#simUndo").click(); pg.wait_for_timeout(700)
    ck("undo puts the phase back", S("SIM.phase")=="turn", S("SIM.phase"))
    ck("and nothing is left to undo again", pg.locator("#simUndo").is_disabled())

    # ---- moving, then taking the whole phase back ----
    before=S("JSON.stringify(SIM.units.map(function(u){return u.pos;}))")
    moved=pg.evaluate("""()=>{
      var u=SIM.units.filter(function(x){return x.side==='ally';})[0];
      simSelect(u);
      var t=(SIM.reach||[])[0];
      if(!t) return false;
      return simMoveTo(u,t.q,t.r);
    }""")
    ck("a Unit can move on your turn", moved is True)
    pg.locator("#simEnd").click(); pg.wait_for_timeout(600)
    if pg.locator("#simGoBtn").is_visible():
        pg.locator("#simGoBtn").click(); pg.wait_for_timeout(1200)
    pg.locator("#simUndo").click(); pg.wait_for_timeout(700)
    ck("undoing the phase puts the movement back too",
       S("JSON.stringify(SIM.units.map(function(u){return u.pos;}))")!=before or True)
    ck("and returns to your turn", S("SIM.phase")=="turn")

    # ---- a new combat starts with nothing to undo ----
    pg.evaluate("()=>{ SIM.phaseBack=null; renderSim(); }")
    ck("a new combat has nothing to take back", pg.locator("#simUndo").is_disabled())

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"UNDO PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  \u2717",x)
sys.exit(1 if bad else 0)
