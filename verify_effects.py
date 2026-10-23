"""Handbook 15.3 in the Simulator: the effect engine, statuses that stack and
tick, line of sight, walls that stop movement, reactions, tile aiming, the
pause on a failed effect, and the friendly-fire guard."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_effects")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9947),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
comp=json.load(open("compendium_full.json"))
CARDS=comp["cards"]+[
 {"cardType":"troop","name":"Sentry","affinities":[{"district":"3"}],
  "stats":{"hp":"20","ac":"8","nrg":"3","will":"3","move":"3","uslot":"1"},
  "abilities":[{"name":"Overwatch","kind":"Active","role":"ranged","text":"[[Suppressive Fire]].",
                "damage":"4","attackRange":"5","toHit":"1","armorPenetration":"20","energyCost":"1"}]},
 {"cardType":"command","name":"Mortar","affinities":[{"district":"3"}],"aetherCost":{"generic":1,"affinity":0},
  "abilities":[{"name":"","kind":"Active","text":"[[all units within 1]] of [[target tile]] take [[damage 3]]."}]},
 {"cardType":"equipment","name":"Plating","affinities":[{"district":"3"}],"aetherCost":{"generic":1,"affinity":0},
  "abilities":[{"name":"","kind":"Passive","text":"[[attached Unit]] gains [[AC +2]] [[while attached]]."}]}]
TEAM=[{"v":2,"name":"T","level":2,"heroes":["master|Quillon Vex"],
  "deck":["master|Sentry"]*4+["master|Mortar"]*3+["master|Plating"]*3,"actions":{},"pouch":{"basic|3":6}}]

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9947/"); pg.wait_for_timeout(2000)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",{"version":"99999","cards":CARDS})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.evaluate("(l)=>localStorage.setItem('keter-app-loadouts',JSON.stringify(l))",TEAM)
    pg.evaluate("()=>localStorage.removeItem('keter-app-sim')")
    pg.reload(); pg.wait_for_timeout(2300)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(600)
    pg.locator("#simSetup").click(); pg.wait_for_timeout(500)
    pg.locator("#simMapSel").select_option(index=0); pg.locator("#simMapNext").click(); pg.wait_for_timeout(700)
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450); pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("[data-wiztroopmore]:not([disabled])").first.click(); pg.wait_for_timeout(300)
    for _ in range(2): pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1500)
    S=lambda e: pg.evaluate("()=>"+e)

    # ---- the engine ----
    r=pg.evaluate("""()=>{
      var Rr=window.KETER_RULES, out={};
      var hero=SIM.units.filter(function(u){return u.side==='ally'&&/hero/i.test(u.cardType||'');})[0];
      var foes=SIM.units.filter(function(u){return u.side==='enemy';});
      hero.pos={q:0,r:0}; foes[0].pos={q:1,r:0}; foes[1].pos={q:2,r:0}; foes[2].pos={q:-3,r:3};
      function last(){ return SIM.log[SIM.log.length-1].text; }
      simRunText('[[if damaged]], [[target enemy]] gains [[Rooted 2]].',{actor:hero,target:foes[0],damaged:true,sourceCard:'T'});
      out.rooted=Rr.statusTurns(foes[0],'Rooted');   /* 15.4: Rooted has no strength, only turns */
      simRunText('[[if damaged]], [[target enemy]] gains [[Rooted 2]].',{actor:hero,target:foes[0],damaged:false,sourceCard:'T'});
      out.notMet=/not met/.test(last());
      simRunText('[[target enemy]] gains [[Poisoned 3]]. [[target enemy]] gains [[Poisoned 2]].',{actor:hero,target:foes[0],sourceCard:'T'});
      out.stack=Rr.statusN(foes[0],'Poisoned');
      var a=foes[0].hp, b=foes[1].hp;
      simRunText('[[target enemy]] takes [[Push 2]].',{actor:hero,target:foes[0],sourceCard:'T'});
      out.pushBoth=(a-foes[0].hp===2)&&(b-foes[1].hp===2);
      simRunText('[[target enemy]] takes [[Chain 3]].',{actor:hero,target:foes[0],damage:4,sourceCard:'T'});
      out.chain=/Chain jumps to/.test(last());
      simRunText('[[target enemy]] takes [[Chain 1]].',{actor:hero,target:foes[2],damage:4,sourceCard:'T'});
      out.chainNone=/no second Enemy/.test(last());
      SIM.halted=null; simRunText('[[this Unit]] gains [[AC +2]].',{actor:hero,sourceCard:'T'});
      out.haltNoDur=!!SIM.halted; SIM.halted=null; SIM.haltShown=false;
      simRunText('[[this Unit]] gains [[AC +2]] for [[turns 2]].',{actor:hero,sourceCard:'T'});
      out.acUp=Rr.effective(hero).ac-(parseInt(hero.ac,10)||10);
      simRunText('Only flavour here.',{actor:hero,sourceCard:'F'});
      out.plainLogged=/Only flavour/.test(last()); out.plainNoHalt=!SIM.halted;
      simRunText('[[target enemy]] gains [[SPOOL 1]].',{actor:hero,target:foes[0],sourceCard:'Old'});
      out.retiredHalts=!!SIM.halted; SIM.halted=null; SIM.haltShown=false;
      simRunText('[[target ally]] gains [[heal 5]].',{actor:hero,target:hero,sourceCard:'T'});
      out.selfNotAlly=/found no target/.test(last());
      simRunText('[[target enemy]] gains [[remove Rooted]].',{actor:hero,target:foes[0],sourceCard:'T'});
      out.removed=!Rr.hasStatus(foes[0],'Rooted');
      return out;
    }""")
    ck("a conditional effect applies when its condition holds", r["rooted"]==2, r["rooted"])
    ck("and says so when it does not", r["notMet"])
    ck("a repeated status adds its number", r["stack"]==5, r["stack"])
    ck("a Push into a Unit hurts both", r["pushBoth"])
    ck("Chain jumps to the nearest other Enemy", r["chain"])
    ck("and names it when there is none", r["chainNone"])
    ck("a Stats change with no Duration halts the fight", r["haltNoDur"])
    ck("a Stats change with a Duration changes the stat", r["acUp"]==2, r["acUp"])
    ck("plain text is logged", r["plainLogged"])
    ck("and does not pause", r["plainNoHalt"])
    ck("a withdrawn keyword pauses", r["retiredHalts"])
    ck("target ally never means the Unit itself", r["selfNotAlly"])
    ck("remove clears a Status", r["removed"])

    # ---- the round ticks statuses in Recharge ----
    r=pg.evaluate("""()=>{
      var Rr=window.KETER_RULES;
      var f=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      var hp0=f.hp, p0=Rr.statusN(f,'Poisoned'), t0=Rr.statusTurns(f,'Poisoned');
      SIM.phase='draw'; simNextPhase(true);
      return {phase:SIM.phase, took:hp0-f.hp, now:Rr.statusN(f,'Poisoned'), was:p0, turnsWere:t0, turnsNow:Rr.statusTurns(f,'Poisoned')};
    }""")
    ck("Recharge is the phase that ticks statuses", r["phase"]=="recharge", r["phase"])
    # 15.4: full strength every turn; a turn comes off, and it ends when none are left
    ck("Poisoned deals its full strength and loses a turn", r["took"]==r["was"] and r["turnsNow"]==max(0,r["turnsWere"]-1), str(r))
    pg.evaluate("()=>{ SIM.phase='turn'; renderSim(); }")

    # ---- walls: sight and movement ----
    r=pg.evaluate("""()=>{
      var Rr=window.KETER_RULES, walls={};
      for(var q=-3;q<=3;q++){ var a=q+',0', b=q+',-1'; walls[a<b?a+'|'+b:b+'|'+a]=1;
                              var c=q+',0', d=(q+1)+',-1'; walls[c<d?c+'|'+d:d+'|'+c]=1; }
      SIM.map.walls=walls; SIM._wallSegs=null; SIM._blindFor=null;
      var hero=SIM.units.filter(function(u){return u.side==='ally'&&/hero/i.test(u.cardType||'');})[0];
      hero.pos={q:0,r:1}; hero.moved=0;
      var foe=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      foe.pos={q:0,r:-2};
      simSelect(hero);
      var crossed=(SIM.reach||[]).some(function(t){ return t.r<=-1 && t.q>=-3 && t.q<=3; });
      return {sees:simSees(hero.pos,foe.pos), shaded:Object.keys(SIM._blind||{}).length,
              crossed:crossed, reach:(SIM.reach||[]).length};
    }""")
    ck("a wall blocks line of sight", r["sees"] is False)
    ck("and the board shades what cannot be seen", r["shaded"]>0, r["shaded"])
    ck("movement does not pass through a wall", r["crossed"] is False, str(r))
    ck("but the Unit can still move elsewhere", r["reach"]>0)
    r=pg.evaluate("""()=>{
      var hero=SIM.units.filter(function(u){return u.side==='ally'&&/hero/i.test(u.cardType||'');})[0];
      var foe=SIM.units.filter(function(u){return u.side==='enemy';})[0];
      var n=SIM.log.length; simAttack(hero,foe);
      return SIM.log.length>n ? SIM.log[SIM.log.length-1].text : '';
    }""")
    ck("a blocked shot says a wall is in the way", "wall" in r or "out of reach" in r, r)
    pg.evaluate("()=>{ SIM.map.walls={}; SIM._wallSegs=null; SIM._blindFor=null; }")

    # ---- reactions ----
    r=pg.evaluate("""()=>{
      var Rr=window.KETER_RULES, out={};
      var s=SIM.units.filter(function(u){return u.name==='Sentry';})[0];
      s.moved=0; s.nrg=3; s.pos={q:0,r:3};
      out.roleKept=s.actions[0].role==='ranged';
      out.holdable=simHoldable(s).length===1;
      s.moved=1; out.notAfterMoving=simHoldable(s).length===0; s.moved=0;
      simHoldFire(s,'Overwatch'); out.paid=s.nrg===2;
      var foe=SIM.units.filter(function(u){return u.side==='enemy';})[1];
      var hp=foe.hp; foe.pos={q:0,r:0}; simReactTo(foe);
      out.fired=hp-foe.hp>0; out.spent=!s.holding;
      s.nrg=3; simHoldFire(s,'Overwatch'); simLapseHolds();
      out.lapsed=!s.holding && /lapses/.test(SIM.log[SIM.log.length-1].text);
      return out;
    }""")
    ck("an Action's role reaches the Unit", r["roleKept"])
    ck("a card that grants Suppressive Fire can hold", r["holdable"])
    ck("but not after moving", r["notAfterMoving"])
    ck("holding pays the Energy", r["paid"])
    ck("the shot fires as an Enemy moves into range", r["fired"])
    ck("and the hold is spent by it", r["spent"])
    ck("an unused hold lapses with the Enemy turn", r["lapsed"])

    # ---- cards from the hand ----
    r=pg.evaluate("""()=>{
      var Rr=window.KETER_RULES, out={};
      SIM.aether={generic:9,d3:9}; SIM.phase='turn';
      var hero=SIM.units.filter(function(u){return u.side==='ally'&&/hero/i.test(u.cardType||'');})[0];
      var mi=SIM.hand.findIndex(function(c){return c.name==='Mortar';});
      out.needs=simCardNeeds(SIM.hand[mi]);
      simPlayCard(mi); out.aiming=!!SIM.aim;
      var foe=SIM.units.filter(function(u){return u.side==='enemy';})[2]; foe.pos={q:3,r:-3};
      SIM.aim.at={q:3,r:-3}; renderSim();
      out.preview=/would catch/.test(document.getElementById('simphases').innerText);
      var hp=foe.hp; simConfirmAim(); out.hit=hp-foe.hp===3; out.aimCleared=!SIM.aim;
      var pi=SIM.hand.findIndex(function(c){return c.name==='Plating';});
      var ac0=Rr.effective(hero).ac;
      simAttachEquipment(pi,hero);
      out.plating=Rr.effective(hero).ac-ac0===2;
      simRunText('[[this Unit]] gains [[remove Equipment]].',{actor:hero,sourceCard:'T'});
      out.stripped=Rr.effective(hero).ac===ac0 && (hero.equipment||[]).length===0;
      return out;
    }""")
    ck("a card aimed at ground enters aiming", r["needs"]=="tile" and r["aiming"], str(r))
    ck("aiming previews what it would catch", r["preview"])
    ck("confirming resolves it on the tile", r["hit"])
    ck("and aiming ends", r["aimCleared"])
    ck("Equipment applies its Stats change while attached", r["plating"])
    ck("remove Equipment takes the bonus with it", r["stripped"])

    # ---- the automated side spares its own ----
    r=pg.evaluate("""()=>{
      var foes=SIM.units.filter(function(u){return u.side==='enemy';});
      var e=foes[0], friend=foes[1], hero=SIM.units.filter(function(u){return u.side==='ally';})[0];
      foes.forEach(function(f,i){ f.pos={q:-6,r:i}; });
      e.pos={q:-1,r:5}; hero.pos={q:1,r:5}; friend.pos={q:2,r:5}; e.nrg=5;
      var a={name:'Blast',tag:'Active',role:'ranged',rng:'4',hit:'1',cost:0,dmg:'3',pen:'20',text:'[[AoE 1]].'};
      return {own:simHurtsOwnSide(e,a,hero), alone:(friend.pos={q:5,r:5}, simHurtsOwnSide(e,a,hero))};
    }""")
    ck("an area effect that would catch its own side is refused", r["own"] is True)
    ck("and allowed once nobody friendly is near", r["alone"] is False)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"EFFECTS PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
