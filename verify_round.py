"""Enemy turns, the round loop, and the end of a combat."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_round")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9801),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

CARDS=[
 {"name":"Rictus","cardType":"hero","subtype":"cyborg",
  "affinities":[{"district":"3","level":4}],
  "stats":{"hp":"40","ac":"9","apT":"4","move":"4"},
  "abilities":[{"name":"Grinder","kind":"Active","role":"melee",
                "text":"Deal 8 damage.","energyCost":"2","damage":"8",
                "armorPenetration":"9"}]},
 {"name":"Stalker","cardType":"enemy","skullLevel":"1",
  "affinities":[{"district":"3"}],
  "behaviors":[{"key":"cunning","value":None}],
  "stats":{"hp":"14","ac":"6","will":"2","move":"3"},
  "abilities":[{"name":"Bite","kind":"Combo","role":"melee","text":"Deal 3 damage.",
                "energyCost":"0","damage":"3","armorPenetration":"9"},
               {"name":"Rend","kind":"Combo","role":"melee","text":"Deal 4 damage.",
                "energyCost":"0","damage":"4","armorPenetration":"9"}]},
 {"name":"Craven","cardType":"enemy","skullLevel":"1",
  "affinities":[{"district":"3"}],
  "behaviors":[{"key":"cowardly","value":20}],
  "stats":{"hp":"14","ac":"6","will":"2","move":"3"},
  "abilities":[{"name":"Nip","kind":"Combo","role":"melee","text":"Deal 2 damage.",
                "energyCost":"0","damage":"2","armorPenetration":"9"}]},
 {"name":"Field Medic","cardType":"troop","affinities":[{"district":"3"}],
  "aetherCost":{"generic":1,"affinity":0},
  "stats":{"hp":"18","nrg":"3","will":"3","move":"3"},"abilities":[]},
]


def advance_round(pg):
    """Walk from Your turn through the Enemy phase and the upkeep, back to your
    next turn. A tap is one phase now, not a whole round."""
    for _ in range(16):
        if not pg.locator("#simEnd").is_visible(): return
        pg.locator("#simEnd").click(); pg.wait_for_timeout(900)
        if pg.locator("#simGoBtn").is_visible():
            pg.locator("#simGoBtn").click(); pg.wait_for_timeout(900)
        if pg.evaluate("()=>SIM.phase")=="turn": return

def setup(pg, foe="Stalker", count=1):
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
    for _ in range(count):
        pg.locator(f'[data-wizfoemore="{foe}"]').click(); pg.wait_for_timeout(200)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1100)

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9801/"); pg.wait_for_timeout(1900)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":CARDS})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    # Handbook 14.0: setup starts from a Strike Team, so the suite needs one
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
    pg.evaluate("(l)=>localStorage.setItem('keter-app-loadouts',JSON.stringify([l]))",
                {"name":"L","level":1,
                 "teams":[{"hero":"master|Rictus","deck":["master|Field Medic"]*6}]})
    pg.evaluate("()=>localStorage.removeItem('keter-app-sim')")
    pg.reload(); pg.wait_for_timeout(2100)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)
    setup(pg)

    # ---- Units are built whichever shape the card came in ----
    r = pg.evaluate("""()=>{
      var h=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      return {heroActs:(h.actions||[]).map(function(a){return a.name;}),
              foeActs:(e.actions||[]).map(function(a){return a.name;}),
              foeBeh:(e.behaviors||[]).map(function(b){return b.k;}),
              heroAff:h.affinities};
    }""")
    ck("a Hero from the Master keeps its Actions", r["heroActs"]==["Grinder"], str(r))
    ck("an Enemy from the Master keeps its Actions",
       r["foeActs"]==["Bite","Rend"], str(r))
    ck("and its Behavior keywords", r["foeBeh"]==["cunning"], str(r))
    ck("and the Hero keeps its Affinity", bool(r["heroAff"]), str(r))

    # ---- the End turn control ----
    ck("there is an End turn button", pg.locator("#simEnd").is_visible())
    ck("the round starts at 1", pg.evaluate("()=>SIM.round")==1)
    ck("and on your phase", pg.evaluate("()=>SIM.phase")=="turn")

    # ---- an Enemy acts, and says why ----
    pg.evaluate("""()=>{
      var h=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      e.pos={q:h.pos.q+1, r:h.pos.r};
    }""")
    hp0=pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='ally';})[0].hp")
    advance_round(pg)
    r = pg.evaluate("""()=>({
      round:SIM.round, phase:SIM.phase, busy:!!SIM.busy,
      hp:SIM.units.filter(function(u){return u.side==='ally';})[0].hp,
      log:SIM.log.map(function(l){return l.text;})})""")
    ck("the Enemy attacked", any("Stalker used" in t for t in r["log"]), str(r["log"][-4:]))
    ck("it named the keyword that chose the target",
       any("Cunning" in t for t in r["log"]), str(r["log"][-4:]))
    ck("the round advanced", r["round"]==2, str(r))
    ck("and it is your phase again", r["phase"]=="turn", str(r))
    ck("the Enemy phase finished", r["busy"] is False)
    ck("income ran for the new round",
       any("generated" in t for t in r["log"]), str(r["log"][-4:]))

    # ---- Combos run in order across turns ----
    used=[t for t in r["log"] if "Stalker used" in t]
    pg.evaluate("""()=>{
      var h=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      e.pos={q:h.pos.q+1, r:h.pos.r}; h.hp=h.hpMax;
    }""")
    advance_round(pg)
    used2=[t for t in pg.evaluate("()=>SIM.log.map(function(l){return l.text;})")
           if "Stalker used" in t]
    ck("its Combo advances to the next Action",
       len(used2)>len(used) and ("Rend" in used2[-1] or "Bite" in used2[-1]),
       str(used2[-2:]))

    # ---- a Cowardly Enemy below its threshold does not act ----
    pg.evaluate("()=>{ SIM.over=false; SIM.map=null; SIM.units=[]; SIM.round=0; renderSim(); }")
    setup(pg, foe="Craven")
    pg.evaluate("""()=>{
      var h=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      e.pos={q:h.pos.q+1, r:h.pos.r};
      e.hp=5;                       /* below its Cowardly 20 threshold */
      SIM.log=[];
    }""")
    advance_round(pg)
    log=pg.evaluate("()=>SIM.log.map(function(l){return l.text;})")
    ck("a broken Cowardly Enemy takes no Action",
       any("does not act" in t for t in log), str(log[:4]))
    ck("and the reason is given", any("Cowardly" in t for t in log), str(log[:4]))

    # ---- victory ----
    pg.evaluate("()=>{ SIM.over=false; SIM.map=null; SIM.units=[]; SIM.round=0; renderSim(); }")
    setup(pg, foe="Craven")
    pg.evaluate("""()=>{
      SIM.units.filter(function(u){return u.side==='enemy';})
        .forEach(function(e){ KETER_RULES.hit(e,999); });
    }""")
    pg.locator("#simEnd").click(); pg.wait_for_timeout(2200)
    ck("all Enemies down ends the combat", pg.evaluate("()=>!!SIM.over") is True)
    ck("and it reads as a Victory", pg.evaluate("()=>SIM.result")=="Victory",
       pg.evaluate("()=>SIM.phase"))
    txt=pg.locator("#modalBox").inner_text()
    ck("the result says how long it took", "round" in txt.lower(), txt[:90])
    ck("and who is still standing", "Rictus" in txt, txt[:120])
    ck("it offers another combat", pg.locator("#simAgain").count()==1)
    ck("End turn is put away", pg.evaluate(
       "()=>document.getElementById('simEnd').style.display")=="none")

    # ---- defeat ----
    pg.locator("#simAgain").click(); pg.wait_for_timeout(500)
    pg.evaluate("()=>{var m=document.getElementById('modal'); if(m) m.classList.remove('on');}")
    pg.evaluate("()=>{ SIM.over=false; SIM.map=null; SIM.units=[]; SIM.round=0; renderSim(); }")
    setup(pg, foe="Craven")
    pg.evaluate("""()=>{
      SIM.units.filter(function(u){return u.side==='ally';})
        .forEach(function(u){ KETER_RULES.hit(u,999); });
    }""")
    pg.locator("#simEnd").click(); pg.wait_for_timeout(2200)
    ck("losing every Unit ends it too", pg.evaluate("()=>SIM.result")=="Defeat",
       pg.evaluate("()=>SIM.phase"))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"ROUND PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
