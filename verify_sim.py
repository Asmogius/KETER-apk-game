"""The Battle Simulator shell: its panel, settings, and the dice."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_sim")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9681),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9681/"); pg.wait_for_timeout(2000)

    ck("the Simulator is on the launcher", pg.locator('.lt[data-page="battle"]').count()==1)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(900)
    ck("it opens as a page, not a placeholder",
       pg.locator("#v-battle").evaluate("e=>e.classList.contains('on')"))
    ck("it is no longer marked as unbuilt",
       "Not built yet" not in pg.locator("#v-battle").inner_text())

    # ---- the board and the panel share the screen ----
    r = pg.evaluate("""()=>{
      var pad=document.getElementById('simpad').getBoundingClientRect();
      var bd =document.getElementById('simboard').getBoundingClientRect();
      return {pad:Math.round(pad.height), board:Math.round(bd.height),
              total:Math.round(pad.height+bd.height), vh:window.innerHeight};
    }""")
    # the panel is taller now so the hand shows without dragging
    ck("the board takes the larger share", r["board"] > r["pad"], str(r))
    ck("nothing overflows the viewport", r["total"] <= r["vh"], str(r))

    # ---- the panel is draggable and folds ----
    r = pg.evaluate("""()=>{
      var pad=document.getElementById('simpad'), g=document.getElementById('simGrip');
      var start=pad.getBoundingClientRect().height;
      function ev(t,y){ g.dispatchEvent(new MouseEvent(t,{bubbles:true,clientY:y})); }
      ev('mousedown',600);
      window.dispatchEvent(new MouseEvent('mousemove',{bubbles:true,clientY:450}));
      window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true}));
      var grown=pad.getBoundingClientRect().height;
      /* a tap folds it */
      ev('mousedown',600); window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true}));
      var folded=pad.classList.contains('collapsed');
      ev('mousedown',600); window.dispatchEvent(new MouseEvent('mouseup',{bubbles:true}));
      return {start:start, grown:grown, folded:folded,
              unfolded:!pad.classList.contains('collapsed')};
    }""")
    ck("dragging the edge grows it", r["grown"] > r["start"], str(r))
    ck("a tap folds it away", r["folded"] is True, str(r))
    ck("and another brings it back", r["unfolded"] is True, str(r))

    # ---- settings ----
    ck("there is a gear button", pg.locator("#simGear").count()==1)
    pg.locator("#simGear").click(); pg.wait_for_timeout(700)
    ck("it offers Auto and Manual",
       pg.locator("#simDiceAuto").count()==1 and pg.locator("#simDiceManual").count()==1)
    ck("Auto is the default", pg.evaluate("()=>SIM.diceMode")=="auto")
    ck("it explains what Auto does",
       "rolls for you" in pg.locator("#modalBox").inner_text(),
       pg.locator("#modalBox").inner_text()[:100])
    pg.locator("#simDiceManual").click(); pg.wait_for_timeout(600)
    ck("switching to Manual takes", pg.evaluate("()=>SIM.diceMode")=="manual")
    ck("and the wording changes",
       "asks what you rolled" in pg.locator("#modalBox").inner_text(),
       pg.locator("#modalBox").inner_text()[:120])
    pg.locator("#simDiceAuto").click(); pg.wait_for_timeout(500)
    ck("and back again", pg.evaluate("()=>SIM.diceMode")=="auto")
    pg.locator("#mClose").click(); pg.wait_for_timeout(400)
    # the dice mode moved into Settings, where it is set, rather than taking a
    # tile in the panel
    pg.locator("#simGear").click(); pg.wait_for_timeout(500)
    ck("Settings shows which mode is set",
       pg.locator("#simDiceAuto").evaluate("e=>e.classList.contains('on')") or
       pg.locator("#simDiceManual").evaluate("e=>e.classList.contains('on')"))
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)

    # ---- it survives a reload ----
    pg.evaluate("()=>{ SIM.diceMode='manual'; simSave(); }")
    pg.reload(); pg.wait_for_timeout(2000)
    ck("the dice choice is remembered",
       pg.evaluate("()=>{ simLoad(); return SIM.diceMode; }")=="manual")

    # ---- the three dice ----
    r = pg.evaluate("""()=>{
      var d=KETER_RULES.makeDice(1234);
      var out={d20:[],d6:[],coin:[]};
      for(var i=0;i<300;i++){
        out.d20.push(d.roll('d20')); out.d6.push(d.roll('d6'));
        out.coin.push(d.coin().face);
      }
      function range(a){ return [Math.min.apply(null,a),Math.max.apply(null,a)]; }
      return {d20:range(out.d20), d6:range(out.d6),
              faces:out.coin.filter(function(v,i,s){return s.indexOf(v)===i;}).sort()};
    }""")
    ck("a d20 rolls 1 to 20", r["d20"]==[1,20], str(r["d20"]))
    ck("a d6 rolls 1 to 6", r["d6"]==[1,6], str(r["d6"]))
    ck("a coin gives heads and tails", r["faces"]==["heads","tails"], str(r["faces"]))
    ck("a coin reads back as a face",
       pg.evaluate("()=>KETER_RULES.faceOf('coin',1)")=="heads")

    # ---- manual rolls ask, and resume ----
    pg.evaluate("()=>{ SIM.diceMode='manual'; }")
    pg.evaluate("""()=>{ window._got=null;
      simAskRoll({die:'d20',needed:13},function(v){ window._got=v; }); }""")
    pg.wait_for_timeout(600)
    ck("it asks for the roll", pg.locator("#simRollIn").count()==1)
    ck("and says what is needed",
       "13 or better" in pg.locator("#modalBox").inner_text(),
       pg.locator("#modalBox").inner_text()[:110])
    pg.fill("#simRollIn","17"); pg.locator("#simRollOk").click(); pg.wait_for_timeout(500)
    ck("a typed roll comes back", pg.evaluate("()=>window._got")==17)

    pg.evaluate("""()=>{ window._bad=null;
      simAskRoll({die:'d20'},function(v){ window._bad=v; }); }""")
    pg.wait_for_timeout(500)
    pg.fill("#simRollIn","44"); pg.locator("#simRollOk").click(); pg.wait_for_timeout(400)
    ck("an impossible roll is refused", pg.evaluate("()=>window._bad") is None)
    pg.fill("#simRollIn","4"); pg.locator("#simRollOk").click(); pg.wait_for_timeout(400)
    ck("a valid one is then accepted", pg.evaluate("()=>window._bad")==4)

    pg.evaluate("""()=>{ window._coin=null;
      simAskRoll({die:'coin'},function(v){ window._coin=v; }); }""")
    pg.wait_for_timeout(500)
    ck("a coin asks for a face, not a number",
       pg.locator("#simCoinH").count()==1 and pg.locator("#simRollIn").count()==0)
    pg.locator("#simCoinT").click(); pg.wait_for_timeout(400)
    ck("tails comes back as 2", pg.evaluate("()=>window._coin")==2)

    pg.evaluate("""()=>{ window._lazy=null;
      simAskRoll({die:'d6'},function(v){ window._lazy=v; }); }""")
    pg.wait_for_timeout(500)
    # Roll it here tumbles for the dice length before handing the value back
    pg.locator("#simRollAuto").click()
    for _ in range(18):
        pg.wait_for_timeout(200)
        if pg.evaluate("()=>window._lazy"): break
    r = pg.evaluate("()=>window._lazy")
    ck("you can hand a single roll back to the app", 1 <= (r or 0) <= 6, str(r))

    # ---- and the resolver pauses for a manual roll ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var a=R.makeUnit({name:'A'}), t=R.makeUnit({name:'T',ac:12,hpMax:20});
      var act={name:'Shot',role:'ranged',dmg:'6',hit:'11',rng:'6'};
      var first=R.resolveAttack(a,act,t,{manual:true,distance:2});
      var second=R.resolveAttack(a,act,t,{manual:true,distance:2,rolls:{accuracy:15}});
      var done=R.resolveAttack(a,act,t,
        {manual:true,distance:2,rolls:{accuracy:15,penetration:14}});
      return {first:first.pending, firstDie:first.die, firstNeed:first.needed,
              second:second.pending, done:done.damage};
    }""")
    ck("it asks for accuracy first", r["first"]=="accuracy", str(r))
    ck("naming the die and the threshold",
       r["firstDie"]=="d20" and r["firstNeed"]==11, str(r))
    ck("then asks for penetration", r["second"]=="penetration", str(r))
    ck("and resolves once both are in", r["done"]==6, str(r))

    ck("no JS errors", len([e for e in errs if 'favicon' not in e.lower()])==0,
       "; ".join(errs[:3]))
    b.close()
srv.shutdown()
print(f"SIMULATOR PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
# part one done


# ---------------- the board ----------------
import json as _json
srv2 = Q(("127.0.0.1", 9683),
         functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv2.serve_forever, daemon=True).start()
ok2, bad2 = [], []
def ck2(n,c,d=""): (ok2 if c else bad2).append(n+((" — "+str(d)) if d and not c else ""))

CARDS = {
 "Rictus":{"v":6,"type":"hero","name":"Rictus","subtype":"cyborg","roles":{"melee":True},
   "stats":{"hp":"40","ac":"9","apT":"4","move":"4"},
   "abilities":[{"name":"Grinder","tag":"Active","role":"melee",
                 "text":"Deal 8 damage.","cost":"2","dmg":"8"}]},
 "Hive Drone":{"v":6,"type":"enemy","name":"Hive Drone","subtype":"human",
   "roles":{"melee":True},"stats":{"hp":"12","ac":"10","will":"2","move":"3"},
   "behaviors":[{"k":"sadistic"}],
   "abilities":[{"name":"Bite","tag":"Combo","role":"melee",
                 "text":"Deal 3 damage.","cost":"1","dmg":"3"}]}}

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9683/"); pg.wait_for_timeout(1900)
    pg.evaluate("(c)=>localStorage.setItem('keter-cardforge-heroes',c)", _json.dumps(CARDS))
    pg.evaluate("()=>localStorage.removeItem('keter-app-sim')")
    pg.reload(); pg.wait_for_timeout(1900)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)

    # ---- hex geometry, which the rules own ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      return {adj:R.hexDistance({q:0,r:0},{q:1,r:0}),
              two:R.hexDistance({q:0,r:0},{q:2,r:-1}),
              far:R.hexDistance({q:0,r:0},{q:0,r:4}),
              self:R.hexDistance({q:3,r:-2},{q:3,r:-2}),
              n:R.hexNeighbours(0,0).length,
              line:R.hexLine({q:0,r:0},{q:3,r:0}).length};
    }""")
    ck2("adjacent tiles are 1 apart", r["adj"]==1, str(r))
    ck2("distance counts tiles, not steps in a straight line",
        r["two"]==2 and r["far"]==4, str(r))
    ck2("a tile is nothing from itself", r["self"]==0, str(r))
    ck2("every tile has six neighbours", r["n"]==6, str(r))
    ck2("a line spans both ends", r["line"]==4, str(r))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var open=R.reachable({q:0,r:0},2,{});
      var walled=R.reachable({q:0,r:0},2,{
        passable:function(n){ return n.q<=0; }});
      var occupied=R.reachable({q:0,r:0},1,{
        blocked:function(n){ return n.q===1 && n.r===0; }});
      return {open:open.length, costs:open.filter(function(t){return t.cost>2;}).length,
              walled:walled.length, occupied:occupied.length};
    }""")
    ck2("two steps reach eighteen tiles", r["open"]==18, str(r["open"]))
    ck2("and never further than asked", r["costs"]==0, str(r))
    ck2("impassable ground is not crossed", r["walled"] < r["open"], str(r))
    ck2("an occupied tile is not entered", r["occupied"]==5, str(r["occupied"]))

    # ---- setting a combat up ----
    # setup is the Hero/Deck/Prototypes/Consumables/Enemies wizard now, with
    # the map chosen first because Enemy counts depend on its Spawn tiles
    # build the loadout from the real cards so the reference prefix matches
    # whichever store they came from
    pg.evaluate("""()=>{
      var all=simAllCards();
      function ref(n){
        var c=all.filter(function(x){return x.name===n;})[0];
        return c ? ((c._src||"master")+"|"+c.name) : null;
      }
      localStorage.setItem('keter-app-loadouts', JSON.stringify([{
        name:"T", level:1,
        teams:[{hero:ref("Rictus"), deck:[ref("Hive Drone")].filter(Boolean)}]
      }]));
    }""")
    pg.locator("#simSetup").click(); pg.wait_for_timeout(800)
    ck2("maps are offered", pg.locator("#simMapSel option").count()>=3,
        pg.locator("#simMapSel option").count())
    pg.locator("#simMapSel").select_option(index=0)
    pg.locator("#simMapNext").click(); pg.wait_for_timeout(700)
    ck2("the wizard opens on the Strike Team", pg.evaluate("()=>SIM_WIZ.step")=="team")
    # Handbook 14.0 setup: Strike Team, then who enters, then the Enemies
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(450)
    # Heroes, then Starting Troops, then the Enemies
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator('[data-wizfoemode="manual"]').click(); pg.wait_for_timeout(350)
    ck2("Enemies are listed", pg.locator("[data-wizfoemore]").count()>=1)
    pg.locator('[data-wizfoemore]').first.click(); pg.wait_for_timeout(200)
    pg.locator('[data-wizfoemore]').first.click(); pg.wait_for_timeout(200)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1100)

    r = pg.evaluate("""()=>{
      return {n:SIM.units.length,
              allies:SIM.units.filter(function(u){return u.side==='ally';}).length,
              foes:SIM.units.filter(function(u){return u.side==='enemy';}).length,
              placed:SIM.units.every(function(u){ return u.pos; }),
              tiles:Object.keys(SIM.map.hexes).length,
              onMap:SIM.units.every(function(u){
                return !!SIM.map.hexes[KETER_RULES.hexKey(u.pos.q,u.pos.r)]; })};
    }""")
    ck2("the count you picked is what you get", r["n"]==3, str(r))
    ck2("enemy cards join the other side", r["foes"]==2 and r["allies"]==1, str(r))
    ck2("every Unit is placed", r["placed"] is True, str(r))
    ck2("and placed on the map", r["onMap"] is True, str(r))
    ck2("the map has tiles", r["tiles"]>20, str(r["tiles"]))

    apart = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var a=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      return R.hexDistance(a.pos,e.pos);
    }""")
    ck2("the sides start apart", apart >= 3, str(apart))

    # ---- selecting and moving ----
    r = pg.evaluate("""()=>{
      var hero=SIM.units.filter(function(u){return u.side==='ally';})[0];
      simSelect(hero);
      return {ms:hero.ms, reach:SIM.reach.length,
              tooFar:SIM.reach.filter(function(t){return t.cost>hero.ms;}).length,
              onSelf:SIM.reach.filter(function(t){
                return t.q===hero.pos.q&&t.r===hero.pos.r;}).length};
    }""")
    ck2("selecting shows where it can go", r["reach"]>0, str(r))
    ck2("never beyond its Movement Speed", r["tooFar"]==0, str(r))
    ck2("and not its own tile", r["onSelf"]==0, str(r))

    r = pg.evaluate("""()=>{
      var hero=SIM.units.filter(function(u){return u.side==='ally';})[0];
      simSelect(hero);
      var step=SIM.reach.filter(function(t){ return t.cost===2; })[0];
      var from=JSON.stringify(hero.pos);
      var moved=simMoveTo(hero,step.q,step.r);
      return {moved:moved, from:from, to:JSON.stringify(hero.pos),
              cost:hero.moved, cleared:SIM.selected===null};
    }""")
    ck2("a legal move is taken", r["moved"] is True and r["from"]!=r["to"], str(r))
    ck2("it costs what it walked", r["cost"]==2, str(r))
    ck2("and the selection clears", r["cleared"] is True)

    ck2("a move off the map is refused", pg.evaluate("""()=>{
      var hero=SIM.units.filter(function(u){return u.side==='ally';})[0];
      simSelect(hero);
      return simMoveTo(hero,99,99);
    }""") is False)
    ck2("a move beyond reach is refused", pg.evaluate("""()=>{
      var R=KETER_RULES;
      var hero=SIM.units.filter(function(u){return u.side==='ally';})[0];
      simSelect(hero);
      var far={q:hero.pos.q, r:hero.pos.r+hero.ms+3};
      return simMoveTo(hero,far.q,far.r);
    }""") is False)
    ck2("an Enemy cannot be moved by you", pg.evaluate("""()=>{
      var foe=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      simSelect(foe);
      return SIM.reach.length;
    }""")==0)

    # ---- the Datapad reflects the board ----
    pg.evaluate("()=>{ simSelect(null); renderSim(); }")
    pg.wait_for_timeout(400)
    ck2("the Datapad lists every Unit",
        pg.locator("#simpadbody .cbu").count()==3,
        pg.locator("#simpadbody .cbu").count())
    ck2("it no longer says nothing is set up",
        "No combat set up" not in pg.locator("#simpadbody").inner_text())
    ck2("the header shows the round",
        "ROUND 1" in pg.locator("#simRound").inner_text().upper(),
        pg.locator("#simRound").inner_text())
    pg.locator("#simpadbody [data-simu]").first.click(); pg.wait_for_timeout(500)
    ck2("tapping a Unit there selects it on the board",
        pg.evaluate("()=>!!SIM.selected") is True)

    # ---- it survives a reload ----
    pg.evaluate("()=>simSave()")
    pg.reload(); pg.wait_for_timeout(2000)
    ck2("the combat survives a reload",
        pg.evaluate("()=>{ simLoad(); return SIM.units.length; }")==3,
        pg.evaluate("()=>{ simLoad(); return SIM.units.length; }"))

    ck2("no JS errors", len([e for e in errs if 'favicon' not in e.lower()])==0,
        "; ".join(errs[:3]))
    b.close()
srv2.shutdown()
print(f"BOARD PASS {len(ok2)}  FAIL {len(bad2)}")
for x in bad2: print("  ✗",x)
# parts one and two done

# ---------------- tiles that mean something, and attacking ----------------
srv3 = Q(("127.0.0.1", 9685),
         functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv3.serve_forever, daemon=True).start()
ok3, bad3 = [], []
def ck3(n,c,d=""): (ok3 if c else bad3).append(n+((" — "+str(d)) if d and not c else ""))

FLOOR = {"v":6,"name":"Test Floor","radius":5,
  "colorLabels":{"0":"Enemy Spawn Tile","1":"Half Cover Barricade",
                 "3":"Player Spawn Tile","5":"Full Cover Barricade"},
  "hexes":[], "walls":[], "marks":[]}
for q in range(-5,6):
    for r in range(-5,6):
        if abs(q+r)>5: continue
        cell={}
        if r<=-4: cell={"c":0}
        elif r>=4: cell={"c":3}
        elif (q,r)==(0,0): cell={"c":1}
        elif (q,r)==(2,0): cell={"c":5}
        FLOOR["hexes"].append([f"{q},{r}", cell])

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9685/"); pg.wait_for_timeout(1900)
    pg.evaluate("(c)=>localStorage.setItem('keter-cardforge-heroes',c)", _json.dumps(CARDS))
    pg.evaluate("(f)=>localStorage.setItem('keter-hexmap-levels',JSON.stringify({t:f}))",
                FLOOR)
    pg.evaluate("()=>localStorage.removeItem('keter-app-sim')")
    pg.reload(); pg.wait_for_timeout(1900)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)

    # ---- a tile means what its colour is called ----
    r = pg.evaluate("""()=>[
      simTileKind('Player Spawn Tile'), simTileKind('Enemy Spawn Tile'),
      simTileKind('Half Cover Barricade'), simTileKind('Full Cover Barricade'),
      simTileKind('Healing Station'), simTileKind('Loot Tile'),
      simTileKind('Something Else'), simTileKind('')]""")
    ck3("a Player Spawn is recognised", r[0]=="spawn-ally", str(r))
    ck3("an Enemy Spawn is recognised", r[1]=="spawn-enemy", str(r))
    ck3("both Cover types are recognised",
        r[2]=="cover-half" and r[3]=="cover-full", str(r))
    ck3("Healing and Loot are recognised", r[4]=="healing" and r[5]=="loot", str(r))
    ck3("anything else is just ground", r[6] is None and r[7] is None, str(r))

    # ---- deployment uses the Spawns ----
    pg.locator("#simSetup").click(); pg.wait_for_timeout(700)
    opts = pg.locator("#simMapSel option").count()
    pg.locator("#simMapSel").select_option(value="ft"); pg.wait_for_timeout(250)
    pg.evaluate("""()=>{
      var all=simAllCards();
      function ref(n){
        var c=all.filter(function(x){return x.name===n;})[0];
        return c ? ((c._src||"master")+"|"+c.name) : null;
      }
      localStorage.setItem('keter-app-loadouts', JSON.stringify([{
        name:"T", level:1,
        teams:[{hero:ref("Rictus"), deck:[ref("Hive Drone")].filter(Boolean)}]
      }]));
    }""")
    pg.locator("#simMapSel").select_option(value="ft")
    pg.locator("#simMapNext").click(); pg.wait_for_timeout(700)
    # Handbook 14.0 setup: Strike Team, then who enters, then the Enemies
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(450)
    # Heroes, then Starting Troops, then the Enemies
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator('[data-wizfoemode="manual"]').click(); pg.wait_for_timeout(350)
    pg.locator('[data-wizfoemore]').first.click(); pg.wait_for_timeout(200)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1100)

    r = pg.evaluate("""()=>{
      return {allySpawns:simSpawnTiles('ally').length,
              foeSpawns:simSpawnTiles('enemy').length,
              placed:SIM.units.map(function(u){
                return {name:u.name, side:u.side, on:simKindAt(u.pos.q,u.pos.r)}; }),
              warning:SIM.spawnWarning};
    }""")
    ck3("the floor's Spawn tiles are found",
        r["allySpawns"]>0 and r["foeSpawns"]>0, str(r))
    ck3("your Unit deploys on a Player Spawn",
        [u for u in r["placed"] if u["side"]=="ally"][0]["on"]=="spawn-ally", str(r))
    ck3("an Enemy deploys on an Enemy Spawn",
        [u for u in r["placed"] if u["side"]=="enemy"][0]["on"]=="spawn-enemy", str(r))
    ck3("and nothing is warned about", r["warning"] is None, str(r))

    # more Units than Spawns says so rather than failing quietly
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var keep=SIM.map.hexes;
      /* leave a single Player Spawn */
      var seen=0;
      Object.keys(keep).forEach(function(k){
        var a=R.hexParse(k);
        if(simKindAt(a.q,a.r)==='spawn-ally'){ seen++; if(seen>1) keep[k]={}; }
      });
      SIM.units.push(R.makeUnit({name:'Extra',side:'ally',cardType:'troop'}));
      SIM.units.push(R.makeUnit({name:'Extra 2',side:'ally',cardType:'troop'}));
      simPlace();
      return {warning:SIM.spawnWarning, allPlaced:SIM.units.every(function(u){return u.pos;})};
    }""")
    ck3("too many Units for the Spawns is reported",
        r["warning"] and "Spawn" in r["warning"], str(r))
    ck3("but everyone still gets a tile", r["allPlaced"] is True, str(r))

    # ---- cover, which only counts from the right side ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var a=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      /* the Half Cover tile is at 0,0 and Full Cover at 2,0 */
      e.pos={q:1,r:0};
      a.pos={q:-3,r:0};
      var through=simCoverFor(e,a);
      a.pos={q:4,r:0};
      var fullSide=simCoverFor(e,a);
      e.pos={q:-4,r:0};
      var none=simCoverFor(e,a);
      return {throughHalf:through, throughFull:fullSide, inTheOpen:none};
    }""")
    ck3("Half Cover adds 2 when it stands between", r["throughHalf"]==2, str(r))
    ck3("Full Cover adds 4", r["throughFull"]==4, str(r))
    ck3("and nothing applies in the open", r["inTheOpen"]==0, str(r))

    # ---- attacking ----
    r = pg.evaluate("""()=>{
      SIM.diceMode='auto';
      var a=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      a.pos={q:0,r:2}; e.pos={q:1,r:2}; a.nrg=4; e.hp=e.hpMax;
      simSelect(a);
      return {marked:SIM.targets?Object.keys(SIM.targets).length:0};
    }""")
    ck3("an Enemy in reach is marked as a target", r["marked"]==1, str(r))

    # both rolls tumble for the dice length before the attack resolves
    before = pg.evaluate("""()=>{
      var a=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      window._atkBefore={hp:e.hp, nrg:a.nrg, logs:SIM.log.length};
      simAttack(a,e); return window._atkBefore; }""")
    for _ in range(30):
        pg.wait_for_timeout(200)
        if pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='ally';})[0].nrg")!=before["nrg"]: break
    pg.wait_for_timeout(300)
    r = pg.evaluate("""()=>{
      var a=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      var lines=SIM.log.slice(window._atkBefore.logs).map(function(l){return l.text;});
      return {before:window._atkBefore, hp:e.hp, nrg:a.nrg,
              logged:lines.filter(function(t){ return / used /.test(t); }).pop()||lines.pop()||""};
    }""")
    ck3("attacking spends the Energy", r["nrg"]==r["before"]["nrg"]-2, str(r))
    ck3("and reports what happened",
        "Grinder" in r["logged"] and "Hive Drone" in r["logged"], r["logged"])
    ck3("the ticker shows the attack's result, not unmarked card text",
        "Hive Drone" in pg.evaluate("()=>document.getElementById('simticker').textContent"),
        pg.evaluate("()=>document.getElementById('simticker').textContent"))
    ck3("the outcome is one the rules allow",
        ("damage" in r["logged"] or "Penetrate" in r["logged"]
         or "missed" in r["logged"]), r["logged"])

    # out of reach is not offered
    r = pg.evaluate("""()=>{
      var a=SIM.units.filter(function(u){return u.side==='ally';})[0];
      var e=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      a.pos={q:0,r:2}; e.pos={q:0,r:-2};
      simSelect(a);
      return SIM.targets?Object.keys(SIM.targets).length:0;
    }""")
    ck3("a distant Enemy is not a target for a melee Unit", r==0, str(r))

    # ---- the board sizes itself to stay tappable ----
    r = pg.evaluate("""()=>({tile:Math.round(SIM_VIEW.size), panned:!!SIM.panned})""")
    ck3("tiles stay big enough to tap", r["tile"] >= 20, str(r))

    ck3("no JS errors", len([e for e in errs if 'favicon' not in e.lower()])==0,
        "; ".join(errs[:3]))
    b.close()
srv3.shutdown()
print(f"TILES AND ATTACKS PASS {len(ok3)}  FAIL {len(bad3)}")
for x in bad3: print("  ✗",x)
sys.exit(1 if (bad or bad2 or bad3) else 0)
