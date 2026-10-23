"""Hazard tiles: defined in the Sandbox, understood by the Simulator."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_hazard")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9811),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

CARDS=[
 {"name":"Rictus","cardType":"hero","affinities":[{"district":"3","level":4}],
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

# a small floor: a row of tiles, one of them on fire
hexes=[]; 
for q in range(-3,4):
    for r in range(-3,4):
        if abs(q+r)<=3: hexes.append([f"{q},{r}", {"c":None}])
FLOOR={"v":6,"name":"Hazard Test","radius":4,
       "hexes":hexes,"walls":[],
       "marks":[["1,0",7]],
       "symDefs":[{"id":7,"text":"FI","desc":"Fire",
                   "hazard":{"keyword":"Overwhelmed","damage":4,"when":"both"}}],
       "colorLabels":{}}

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9811/"); pg.wait_for_timeout(2100)

    # ---- the Sandbox can define one ----
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3300)
    W="document.querySelector('#v-poi iframe').contentWindow"
    ck("the keyword library reached the Sandbox",
       pg.evaluate(f"()=>({W}.KETER_KEYWORDS||[]).length")>=7,
       pg.evaluate(f"()=>({W}.KETER_KEYWORDS||[]).length"))
    ck("the same keywords the cards use",
       "Overwhelmed" in pg.evaluate(f"()=>({W}.KETER_KEYWORDS||[]).map(function(k){{return k.name;}})"))

    # ---- the Sandbox's hazard editor ----
    F=pg.frame_locator('#v-poi iframe')
    ck("there is a way in", F.locator("#hazBtn").count()==1)
    F.locator("#hazBtn").click(); pg.wait_for_timeout(500)
    ck("it asks you to arm a symbol first",
       "Arm a symbol" in F.locator("#status").inner_text(),
       F.locator("#status").inner_text()[:60])
    F.locator(".symbtn").first.click(); pg.wait_for_timeout(400)
    F.locator("#hazBtn").click(); pg.wait_for_timeout(600)
    ck("the editor opens", F.locator("#hazKw").count()==1)
    ck("it offers a damage value", F.locator("#hazDmg").count()==1)
    opts = F.locator("#hazKw option").all_inner_texts()
    ck("the effects are the card keywords", len(opts)>=8, str(len(opts)))
    ck("including Overwhelmed", "Overwhelmed" in opts, str(opts[:4]))
    F.locator("#hazDmg").fill("5")
    F.locator("#hazKw").select_option("Overwhelmed"); pg.wait_for_timeout(300)
    ck("and it explains what the effect does",
       len(F.locator("#hazDesc").inner_text())>30,
       F.locator("#hazDesc").inner_text()[:50])
    F.locator("#hazOk").click(); pg.wait_for_timeout(500)
    ck("saving reports what was set",
       "5 damage" in F.locator("#status").inner_text(),
       F.locator("#status").inner_text()[:60])
    ck("and the symbol is marked as a hazard",
       F.locator(".symbtn.hazard").count()==1)

    # ---- the Simulator reads a floor with hazards on it ----
    pg.evaluate("""(f)=>localStorage.setItem('keter-hexmap-levels',
                    JSON.stringify({hazardtest:f}))""", FLOOR)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":CARDS})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.evaluate("""()=>localStorage.setItem('keter-app-loadouts',JSON.stringify([
      {name:'L',level:1,teams:[{hero:'master|Rictus',deck:['master|Field Medic']}]}]))""")
    pg.evaluate("()=>localStorage.removeItem('keter-app-sim')")
    pg.reload(); pg.wait_for_timeout(2300)
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)

    r = pg.evaluate("""()=>{
      var m=simLoadFloor('hazardtest');
      return m ? {name:m.name, hazards:Object.keys(m.hazards||{}),
                  one:(m.hazards||{})['1,0']} : null;
    }""")
    ck("the floor loads", r is not None)
    ck("its hazard is found", r and r["hazards"]==["1,0"], str(r))
    ck("with its damage", r and r["one"]["damage"]==4, str(r and r["one"]))
    ck("and its effect", r and r["one"]["keyword"]=="Overwhelmed", str(r and r["one"]))

    # ---- it fires on entering and on remaining ----
    pg.evaluate("""()=>{
      SIM.map=simLoadFloor('hazardtest');
      SIM.units=[KETER_RULES.makeUnit({id:'h',name:'Rictus',cardType:'hero',
        side:'ally',hpMax:40,hp:40,ac:9,ms:4,will:9}),
        KETER_RULES.makeUnit({id:'e',name:'Grunt',cardType:'enemy',
        side:'enemy',hpMax:30,hp:30,ac:6,ms:3,will:9})];
      SIM.units[0].pos={q:0,r:0};
      SIM.units[1].pos={q:3,r:0};
      SIM.round=1; SIM.phase='turn'; SIM.log=[]; SIM.over=false;
      SIM.hand=[]; SIM.deck=[]; SIM.discard=[]; SIM.aether={}; SIM.chips=[];
      renderSim();
    }""")
    hp0=pg.evaluate("()=>SIM.units[0].hp")
    pg.evaluate("""()=>{
      var h=SIM.units[0];
      simSelect(h);          /* selecting works out what it can reach */
      simMoveTo(h,1,0);
    }""")
    pg.wait_for_timeout(500)
    r=pg.evaluate("""()=>({hp:SIM.units[0].hp, pos:SIM.units[0].pos,
      statuses:(SIM.units[0].statuses||[]).map(function(st){return st.name;}),
      log:SIM.log.map(function(l){return l.text;})})""")
    ck("moving onto a hazard costs Health", r["hp"]==hp0-4, f'{hp0} -> {r["hp"]}')
    ck("and applies its effect", "Overwhelmed" in r["statuses"], str(r["statuses"]))
    ck("and says so", any("moves onto" in t for t in r["log"]), str(r["log"][-2:]))

    hp1=pg.evaluate("()=>SIM.units[0].hp")
    pg.evaluate("()=>simHazardEndOfTurn()")
    pg.wait_for_timeout(300)
    ck("standing on it at end of turn costs again",
       pg.evaluate("()=>SIM.units[0].hp")==hp1-4,
       f'{hp1} -> {pg.evaluate("()=>SIM.units[0].hp")}')
    ck("a Unit that is not on one is untouched",
       pg.evaluate("()=>SIM.units[1].hp")==30)

    # ---- it is terrain: both sides, and Armor does not stop it ----
    pg.evaluate("""()=>{
      SIM.units[1].pos={q:1,r:0};
      SIM.units[0].pos={q:0,r:0};
    }""")
    ehp=pg.evaluate("()=>SIM.units[1].hp")
    pg.evaluate("()=>simHazardEndOfTurn()")
    pg.wait_for_timeout(300)
    ck("an Enemy standing on it takes it too",
       pg.evaluate("()=>SIM.units[1].hp")==ehp-4,
       f'{ehp} -> {pg.evaluate("()=>SIM.units[1].hp")}')
    ck("Armor Class does not reduce it",
       pg.evaluate("()=>SIM.units[1].hp")==ehp-4)

    # ---- movement avoids it when it can ----
    r=pg.evaluate("""()=>{
      SIM.units[0].pos={q:-2,r:0};
      SIM.units[1].pos={q:3,r:0};
      var before=JSON.stringify(SIM.units[0].pos);
      simStepToward(SIM.units[0], SIM.units[1]);
      return {before:before, after:JSON.stringify(SIM.units[0].pos),
              landedOnHazard: !!simHazardAt(SIM.units[0].pos.q,SIM.units[0].pos.r)};
    }""")
    ck("a Unit moving toward a target steps around the hazard",
       r["landedOnHazard"] is False, str(r))
    ck("but it still makes progress", r["before"]!=r["after"], str(r))

    # ---- a floor with no hazards behaves as before ----
    ck("an ordinary floor has none",
       pg.evaluate("""()=>{
         var m=simArena(SIM_ARENAS[0]);
         return Object.keys(m.hazards||{}).length===0;
       }"""))
    ck("and asking about a tile is safe there",
       pg.evaluate("""()=>{
         SIM.map=simArena(SIM_ARENAS[0]);
         return simHazardAt(0,0)===null;
       }"""))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"HAZARD PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
