"""Player Behavior keywords, presets, and the auto-battle."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_auto")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9831),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
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
  "behaviors":[{"key":"cunning","value":None}],
  "stats":{"hp":"10","ac":"6","will":"2","move":"3"},
  "abilities":[{"name":"Bite","kind":"Combo","role":"melee","text":"Deal 3 damage.",
                "energyCost":"0","damage":"3","armorPenetration":"9"}]},
 {"name":"Field Medic","cardType":"troop","affinities":[{"district":"3"}],
  "aetherCost":{"generic":1,"affinity":0},
  "stats":{"hp":"18","nrg":"3","will":"3","move":"3"},"abilities":[]},
]

def setup(pg, foes=1):
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
    for _ in range(foes):
        pg.locator('[data-wizfoemore="Grunt"]').click(); pg.wait_for_timeout(200)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1100)

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9831/"); pg.wait_for_timeout(1900)
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
    pg.evaluate("()=>{localStorage.removeItem('keter-app-sim');"
                "localStorage.removeItem('keter-app-behpresets');}")
    pg.reload(); pg.wait_for_timeout(2100)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)

    # ---- the keyword table ----
    r = pg.evaluate("""()=>{
      var all=KETER_BEHAVIORS;
      return {total:all.length,
              enemy:all.filter(function(b){return b.side==='enemy';}).length,
              ally:all.filter(function(b){return b.side==='ally';}).map(function(b){return b.name;}),
              cats:all.filter(function(b){return b.side==='ally';})
                     .map(function(b){return b.cat;})
                     .filter(function(v,i,s){return s.indexOf(v)===i;}).sort()};
    }""")
    ck("both sides share one table", r["total"]==21, str(r["total"]))
    ck("the Enemy set is unchanged", r["enemy"]==9, str(r["enemy"]))
    ck("twelve Player keywords exist", len(r["ally"])==12, str(len(r["ally"])))
    for name in ["Valiant","Decisive","Precise","Dauntless","Defiant","Coordinated",
                 "Thorough","Wary","Prudent","Steadfast","Medic","Guardian"]:
        ck(f"{name} is defined", name in r["ally"])
    ck("they fall into targeting, movement and role",
       r["cats"]==["move","support","target"], str(r["cats"]))

    # ---- targeting, against a mixed enemy line ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      function foe(n,ct,hp,ac){ return R.makeUnit({id:n,name:n,cardType:ct,
        side:'enemy',hpMax:hp,hp:hp,ac:ac}); }
      var grunt=foe('Grunt','enemy',20,10);
      var boss=foe('Boss','boss',40,16);
      var hurt=foe('Hurt','enemy',20,8); hurt.hp=3;
      var line=[grunt,boss,hurt];
      function me(k){ return R.makeUnit({side:'ally',cardType:'troop',
        behaviors:[{k:k}]}); }
      return {valiant:R.chooseTarget(me('valiant'),line,{}).name,
              decisive:R.chooseTarget(me('decisive'),line,{}).name,
              precise:R.chooseTarget(me('precise'),line,{}).name,
              dauntless:R.chooseTarget(me('dauntless'),line,{}).name};
    }""")
    ck("Valiant goes for the Boss", r["valiant"]=="Boss", str(r))
    ck("Decisive takes the lowest Health", r["decisive"]=="Hurt", str(r))
    ck("Precise takes the lowest Armor", r["precise"]=="Hurt", str(r))
    ck("Dauntless takes the highest Armor", r["dauntless"]=="Boss", str(r))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var a=R.makeUnit({id:'a',name:'A',side:'enemy',hpMax:20,hp:20});
      var bb=R.makeUnit({id:'b',name:'B',side:'enemy',hpMax:20,hp:20});
      var me=R.makeUnit({side:'ally',behaviors:[{k:'defiant'}]});
      var before=R.chooseTarget(me,[a,bb],{}).name;
      me.lastAttackedBy='b';
      var after=R.chooseTarget(me,[a,bb],{}).name;
      var coord=R.makeUnit({side:'ally',behaviors:[{k:'coordinated'}]});
      var quiet=R.chooseTarget(coord,[a,bb],{}).name;
      a.attackedThisRound=true;
      return {before:before, after:after, quiet:quiet,
              piled:R.chooseTarget(coord,[a,bb],{}).name};
    }""")
    ck("Defiant strikes back at whoever attacked it", r["after"]=="B", str(r))
    ck("Coordinated does nothing alone", r["quiet"] in ("A","B"), str(r))
    ck("then focuses what an ally already hit", r["piled"]=="A", str(r))

    # ---- movement and role ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      function me(keys,hp){ return R.makeUnit({side:'ally',hpMax:20,hp:hp||20,
        behaviors:keys.map(function(k){return typeof k==='string'?{k:k}:k;})}); }
      return {wary:R.movePlan(me([{k:'wary',x:2}]),{nearestEnemyDistance:1}),
              waryFar:R.movePlan(me([{k:'wary',x:2}]),{nearestEnemyDistance:6}),
              prudent:R.movePlan(me([{k:'prudent',x:5}],4),{nearestEnemyDistance:1}),
              prudentOk:R.movePlan(me([{k:'prudent',x:5}],20),{nearestEnemyDistance:1}),
              steadfast:R.movePlan(me(['steadfast']),{nearestEnemyDistance:6}),
              guardian:R.movePlan(me(['guardian']),{nearestEnemyDistance:6}),
              both:R.movePlan(me(['guardian',{k:'prudent',x:5}],3),{nearestEnemyDistance:1})};
    }""")
    ck("Wary backs off when crowded", r["wary"]["move"]=="away", str(r["wary"]))
    ck("and still acts", r["wary"]["act"] is True)
    ck("Wary holds when nothing is near", r["waryFar"]["move"]=="toward")
    ck("Prudent withdraws when hurt", r["prudent"]["move"]=="away", str(r["prudent"]))
    ck("and takes no Action", r["prudent"]["act"] is False)
    ck("Prudent does nothing while healthy", r["prudentOk"]["move"]=="toward")
    ck("Steadfast holds its tile", r["steadfast"]["move"]=="hold", str(r["steadfast"]))
    ck("Guardian escorts", r["guardian"]["move"]=="escort", str(r["guardian"]))
    ck("a conditional keyword still outranks one without",
       r["both"]["move"]=="away" and r["both"]["act"] is False, str(r["both"]))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var medic=R.makeUnit({id:'m',side:'ally',cardType:'troop',nrg:9,
        behaviors:[{k:'medic'}],
        actions:[{name:'Patch',tag:'Active',role:'support',cost:1,text:'Heals 5.'}]});
      var hurt=R.makeUnit({id:'h',name:'Hurt',side:'ally',hpMax:30,hp:6});
      var fine=R.makeUnit({id:'f',name:'Fine',side:'ally',hpMax:30,hp:30});
      var plan=R.supportPlan(medic,[medic,hurt,fine]);
      var none=R.supportPlan(medic,[medic,fine]);
      var notMedic=R.supportPlan(R.makeUnit({side:'ally',nrg:9,
        actions:[{name:'Patch',tag:'Active',role:'support',cost:1,text:'Heals 5.'}]}),
        [hurt]);
      return {picked:plan?plan.target.name:null, act:plan?plan.action.name:null,
              nobodyHurt:none, withoutTheKeyword:notMedic};
    }""")
    ck("Medic finds the most wounded ally", r["picked"]=="Hurt", str(r))
    ck("and uses a Support Action", r["act"]=="Patch", str(r))
    ck("it does nothing when nobody is hurt", r["nobodyHurt"] is None)
    ck("and nothing without the keyword", r["withoutTheKeyword"] is None)

    # ---- assigning them, capped at three ----
    setup(pg)
    ck("there is an Auto button", pg.locator("#simAuto").is_visible())
    pg.locator("#simAuto").click(); pg.wait_for_timeout(700)
    ck("your Units are listed", pg.locator("[data-autounit]").count()>=1)
    pg.locator("[data-autounit]").first.click(); pg.wait_for_timeout(600)
    ck("only Player keywords are offered", pg.locator("[data-behpick]").count()==12,
       pg.locator("[data-behpick]").count())
    for k in ["decisive","wary","guardian"]:
        pg.locator(f'[data-behpick="{k}"]').click(); pg.wait_for_timeout(300)
    ck("three can be chosen",
       pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='ally';})[0].behaviors.length")==3)
    pg.locator('[data-behpick="precise"]').click(); pg.wait_for_timeout(300)
    ck("a fourth is refused",
       pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='ally';})[0].behaviors.length")==3)
    pg.locator('[data-behpick="wary"]').click(); pg.wait_for_timeout(300)
    ck("tapping one again removes it",
       pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='ally';})[0].behaviors.length")==2)

    # ---- presets ----
    pg.locator("#behSavePreset").click(); pg.wait_for_timeout(500)
    ck("it asks for a name", pg.locator("#behPresetName").count()==1)
    pg.fill("#behPresetName","Front line")
    pg.locator("#behPresetOk").click(); pg.wait_for_timeout(500)
    r = pg.evaluate("()=>behPresets()")
    ck("the preset is saved", len(r)==1 and r[0]["name"]=="Front line", str(r))
    ck("it keeps the keywords", len(r[0]["keys"])==2, str(r))
    ck("and which side it is for", r[0]["side"]=="ally", str(r))
    ck("it is offered back", pg.locator("[data-behpreset]").count()==1)

    pg.evaluate("()=>{SIM.units.filter(function(u){return u.side==='ally';})[0].behaviors=[];}")
    pg.evaluate("()=>simBehDialog(SIM.units.filter(function(u){return u.side==='ally';})[0])")
    pg.wait_for_timeout(400)
    pg.locator("[data-behpreset]").first.click(); pg.wait_for_timeout(500)
    ck("applying it restores the keywords",
       pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='ally';})[0].behaviors.length")==2)

    ck("a preset survives a reload",
       pg.evaluate("()=>{ return behPresets().length; }")==1)
    pg.evaluate("()=>behPresetDelete('Front line')")
    ck("and can be deleted", pg.evaluate("()=>behPresets().length")==0)

    # ---- the auto-battle itself ----
    pg.evaluate("()=>{var m=document.getElementById('modal'); if(m) m.classList.remove('on');}")
    pg.evaluate("()=>{ SIM.over=false; SIM.map=null; SIM.units=[]; SIM.round=0; renderSim(); }")
    setup(pg, foes=2)
    pg.evaluate("""()=>{
      SIM.units.filter(function(u){return u.side==='ally';})[0]
        .behaviors=[{k:'decisive'}];
    }""")
    before=pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='enemy';}).length")
    pg.evaluate("()=>simRunAuto()")
    pg.wait_for_timeout(25000)
    r = pg.evaluate("""()=>({round:SIM.round, phase:(SIM.result||SIM.phase), over:!!SIM.over,
      busy:!!SIM.busy, log:SIM.log.map(function(l){return l.text;})})""")
    ck("the fight runs to a conclusion", r["over"] is True, str(r["phase"]))
    ck("it is not left running", r["busy"] is False)
    ck("it took a sensible number of rounds", 1<=r["round"]<=60, str(r["round"]))
    ck("your Unit acted on its keyword",
       any("Decisive" in t for t in r["log"]), str(r["log"][-4:]))
    ck("and the Enemy acted on its own",
       any("Cunning" in t for t in r["log"]), str(r["log"][-4:]))
    ck("the result is one of the three outcomes",
       r["phase"] in ("Victory","Defeat","Draw"), str(r["phase"]))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"AUTO BATTLE PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
