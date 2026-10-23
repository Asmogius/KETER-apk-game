"""v13.5 (Handbook 15.9): a Status ticks at the end of the turn after the one it
arrived in (the Player's half ticks at the Recharge, the Enemies' half as the
Player's next turn ends); timed Stats changes the same; Auto plays whole
rounds; the round ends once with no Enemy left to act; and two Units of one
name holding fire are two lines in the Log."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_timing")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9983),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)[:420]) if d not in ("",None) and not c else ""))
LIB=r"""()=>{ window.T={ R:window.KETER_RULES,
  foes:function(){ return SIM.units.filter(function(u){ return u.side==='enemy' && !u.down && u.pos; }); },
  mine:function(){ return SIM.units.filter(function(u){ return u.side==='ally' && !u.down && u.pos; }); },
  texts:function(from){ return SIM.log.slice(from||0).map(function(l){ return l.text; }); },
  shut:function(){ var m=document.getElementById('modal'); if(m) m.classList.remove('on'); window._simX=null; SIM.pick=null; SIM.halted=null; SIM.haltShown=false; },
  st:function(u,n){ return (u.statuses||[]).filter(function(s){ return s.name===n; })[0]||null; },
  /* Next, until the phase is the one named (the Enemies act one tap at a time) */
  to:function(k){ return new Promise(function(done){ var n=0, t=setInterval(function(){
      if(SIM.phase===k && !SIM.busy || SIM.over || n++>3000){ clearInterval(t); return done(SIM.phase); }
      if(!SIM.busy){ T.shut(); simNextPhase(true); } }, 3); }); },
  next:function(){ return new Promise(function(done){ T.shut(); simNextPhase(true); var n=0, t=setInterval(function(){ if(!SIM.busy || n++>3000){ clearInterval(t); done(SIM.phase); } }, 3); }); },
  /* stand every Enemy out of anyone's reach, so a turn passes with nothing but the clock */
  calm:function(){ T.foes().forEach(function(e){ e.behaviors=[{k:'steadfast'}]; e.actions=[]; }); }
}; return true; }"""
START="""()=>{ var w=simWiz(); w.startTroops=['Test Drone']; w.protos=[]; w.cons={}; w.instability=0; simWizFinish(); }"""
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9983/"); pg.wait_for_timeout(2000)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2200)
    # every wait in the simulator is cut short, so a whole fight on Auto takes moments
    pg.evaluate("()=>{ var st=window.setTimeout; window.setTimeout=function(f,ms){ return st(f, Math.min(ms||0, 4)); }; }")
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    E=pg.evaluate

    # ---- the Handbook and the guides ----
    hb=" ".join(pathlib.Path("handbook.html").read_text(encoding="utf-8").split())
    md=pathlib.Path("handbook_v14-0.md").read_text(encoding="utf-8")
    ck("the Handbook is Version 15.9 or later (16.3 now), and keeps 15.9's timing", ("Version 15.9" in hb or "Version 16.0" in hb or "Version 16.1" in hb or "Version 16.2" in hb or "Version 16.3" in hb) and "Revision 15.9" in hb)
    ck("it says when a Status ticks: at the end of the turn after the one it arrived in", "A Status ticks at the end of the turn after the one it arrived in" in hb)
    ck("and names the two halves of the round", "the Player’s half</strong> ticks at the next Recharge Phase" in hb and "the Enemies’ half</strong> ticks as the Player’s next turn ends" in hb, hb[hb.find("The round has two halves"):][:500])
    ck("the Turn Sequence has the end of the Player's turn, and its Recharge no longer says every Status ticks", "The Player’s turn ends — the Statuses that arrived in the Enemies’ half" in hb and "every Status ticks" not in hb)
    ck("nothing in it still says a Status ticks at each Recharge", "at each Recharge" not in md and "Statuses tick in the Recharge Phase" not in md and "two Recharges" not in md)
    ck("the glossary has Tick", "<strong>Tick (Status)</strong>" in hb)
    cl=" ".join(pathlib.Path("changelog.html").read_text(encoding="utf-8").split())
    ck("the Change Log has Revision 15.9", "Revision 15.9" in cl and "A Status ticks at the end of the turn after the one it arrived in" in cl)
    wn=" ".join(pathlib.Path("whatsnew.html").read_text(encoding="utf-8").split())
    ck("What's New has v13.5", "v13.5" in wn and "Auto plays whole rounds" in wn and "The round ends once" in wn)
    sg=" ".join(pathlib.Path("simulator_guide.html").read_text(encoding="utf-8").split())
    ck("the Simulator Guide tells the timing and that Auto plays whole rounds", "a Status ticks at the end of the turn after the one it arrived in" in sg and "Auto plays whole rounds" in sg and "Every Status ticks once a round" not in sg)
    ck("the app is 13.5 or later", E("()=>document.documentElement.innerHTML.indexOf('13.5')>=0") and __import__("re").search(r"keter-companion-v(13-([5-9]|\d\d)|1[4-9]-\d+)", pathlib.Path("pwa/sw.js").read_text()))

    # ---- the rules: two ticks, each for its own half ----
    r=E("""()=>{ var R=window.KETER_RULES, half='ally'; var keep=R.hooks.half; R.hooks.half=function(){ return half; };
      var u=R.makeUnit({id:'u', name:'U', side:'ally', hp:20, ac:5, ms:3});
      R.addStatus(u,'Poisoned',3,null,2); half='enemy'; R.addStatus(u,'Bleed',null,null,2); R.addStatus(u,'Poisoned',1,null,1);
      u.mods=[{stat:'AC',amt:2,dur:'turns',n:1,source:'a'},{stat:'MS',amt:1,dur:'turns',n:1,source:'b',late:true},{stat:'DMG',amt:1,dur:'persistent',n:null,source:'c'}];
      var out={stamps:u.statuses.map(function(s){ return [s.name, s.n, s.turns, !!s.late]; })};
      var e1=R.turnEndTick([u]); out.afterLate={hp:u.hp, st:u.statuses.map(function(s){ return [s.name, s.turns]; }), mods:u.mods.map(function(m){ return m.stat; }), ev:e1.map(function(e){ return e.type+(e.name?':'+e.name:'')+(e.stat?':'+e.stat:''); })};
      var e2=R.rechargeTick([u]); out.afterMine={hp:u.hp, st:u.statuses.map(function(s){ return [s.name, s.turns]; }), mods:u.mods.map(function(m){ return m.stat; }), ev:e2.map(function(e){ return e.type+(e.name?':'+e.name:'')+(e.stat?':'+e.stat:''); })};
      var held=R.makeUnit({id:'h', name:'H', side:'ally', hp:9, ac:5, ms:3}); R.addStatus(held,'Rooted',null,'aura:x',1); R.turnEndTick([held]); R.rechargeTick([held]); out.held=held.statuses.length;
      R.hooks.half=keep; return out; }""")
    ck("a Status is stamped by the half it arrives in; a second dose keeps the timing of the first", r["stamps"]==[["Poisoned",4,3,False],["Bleed",None,2,True]], r["stamps"])
    r2=E("""()=>{ var R=window.KETER_RULES, half='enemy'; var keep=R.hooks.half; R.hooks.half=function(){ return half; };
      var u=R.makeUnit({id:'v', name:'V', side:'ally', hp:20, ac:5, ms:3});
      R.addStatus(u,'Weakened',1,null,1); half='ally'; R.addStatus(u,'Weakened',2,null,1);
      var out=u.statuses.map(function(s){ return [s.name, s.n, s.turns, !!s.late]; }); R.hooks.half=keep; return out; }""")
    ck("and the other way round: one that came in the Enemies' half stays late when it is added to in the Player's", r2==[["Weakened",3,2,True]], r2)
    ck("as the Player's turn ends, only what came in the Enemies' half ticks: Bleed bites, the late Stats change ends, Poison waits",
       r["afterLate"]["hp"]==18 and r["afterLate"]["st"]==[["Poisoned",3],["Bleed",1]] and r["afterLate"]["mods"]==["AC","DMG"] and "tick:Bleed" in r["afterLate"]["ev"] and "mod:MS" in r["afterLate"]["ev"] and "tick:Poisoned" not in r["afterLate"]["ev"], r["afterLate"])
    ck("at the Recharge, only what came in the Player's half: Poison bites, the other Stats change ends, Bleed waits; a persistent change stays",
       r["afterMine"]["hp"]==14 and r["afterMine"]["st"]==[["Poisoned",2],["Bleed",1]] and r["afterMine"]["mods"]==["DMG"] and "tick:Poisoned" in r["afterMine"]["ev"] and "tick:Bleed" not in r["afterMine"]["ev"], r["afterMine"])
    ck("a Status an Aura or Passive holds is ticked by neither", r["held"]==1, r)

    # ---- the simulator: which half is which ----
    E("()=>simDebugStart('TEST \\u00b7 Corridor')"); pg.wait_for_timeout(700)
    E(START); pg.wait_for_timeout(700); E(LIB)
    r=E("""()=>{ var was=SIM.phase, out={start:was, startHalf:simHalf()};
      ['waves','gen','chips','draw','recharge','turn','enemy'].forEach(function(k){ SIM.phase=k; out[k]=simHalf(); }); SIM.phase=was; return out; }""")
    ck("the fight opens in the Player's half", r["start"]=="turn" and r["startHalf"]=="ally", r)
    ck("the Player's half is the Recharge and the Player's turn; the Enemies' is their turn, Waves, Aether Generation, Aether Draw and Draw",
       [r[k] for k in ["waves","gen","chips","draw","recharge","turn","enemy"]]==["enemy","enemy","enemy","enemy","ally","ally","enemy"], r)
    r=E("()=>({recharge:SIM_PHASES.filter(function(p){ return p.k==='recharge'; })[0].hint, enemy:SIM_PHASES.filter(function(p){ return p.k==='enemy'; })[0].hint})") if E("()=>typeof SIM_PHASES!=='undefined'") else None
    if r: ck("the phase hints say which Statuses tick where", "from your turn tick" in r["recharge"] and "from the Enemies' turn tick" in r["enemy"], r)

    # ---- a Status given in your turn: the Enemy keeps it through its own turn, and it ticks at the Recharge ----
    r=E("""async ()=>{ T.shut(); T.calm(); var foe=T.foes()[0], R=T.R, out={};
      R.addStatus(foe,'Stunned',null,null,1); R.addStatus(foe,'Poisoned',2,null,2);
      out.late=[!!T.st(foe,'Stunned').late, !!T.st(foe,'Poisoned').late]; var hp=foe.hp, from=SIM.log.length;
      await T.next(); out.phase=SIM.phase; out.afterTurnEnd={stunned:!!T.st(foe,'Stunned'), hp:foe.hp};
      await T.to('draw'); out.beforeRecharge={stunned:!!T.st(foe,'Stunned'), hp:foe.hp, said:T.texts(from)};
      var f2=SIM.log.length; await T.to('recharge'); out.afterRecharge={stunned:!!T.st(foe,'Stunned'), hp:foe.hp, turns:(T.st(foe,'Poisoned')||{}).turns, said:T.texts(f2)};
      out.hp0=hp; out.name=foe.name; await T.to('turn'); return out; }""")
    ck("given in your turn, a Status is not late", r["late"]==[False,False], r)
    ck("ending your turn doesn't tick it: the Enemy is still Stunned and loses its turn", r["phase"]=="enemy" and r["afterTurnEnd"]=={"stunned":True,"hp":r["hp0"]} and r["beforeRecharge"]["stunned"] and any(t==r["name"]+" is Stunned and loses its turn" for t in r["beforeRecharge"]["said"]), r)
    ck("the Recharge ticks it: Stunned ends and Poison bites once", r["afterRecharge"]=={"stunned":False,"hp":r["hp0"]-2,"turns":1,"said":r["afterRecharge"]["said"]} and r["name"]+" takes 2 from Poisoned" in r["afterRecharge"]["said"] and r["name"]+" is no longer Stunned" in r["afterRecharge"]["said"], r)

    # ---- a Status given in the Enemies' turn: it lasts through your next turn and ticks as that turn ends ----
    r=E("""async ()=>{ T.shut(); T.calm(); var me=T.mine().filter(function(u){ return /hero/i.test(u.cardType||''); })[0], R=T.R, out={name:me.name};
      await T.to('enemy'); R.addStatus(me,'Stunned',null,'enemy',1); R.addStatus(me,'Poisoned',3,'enemy',2);
      out.late=[!!T.st(me,'Stunned').late, !!T.st(me,'Poisoned').late]; var hp=me.hp; out.hp0=hp;
      var f=SIM.log.length; await T.to('turn'); out.atTurn={stunned:!!T.st(me,'Stunned'), cannot:!!R.effective(me).cannotAct, hp:me.hp, turns:T.st(me,'Poisoned').turns, said:T.texts(f)};
      var f2=SIM.log.length; await T.next(); out.phase=SIM.phase;
      out.atEnd={stunned:!!T.st(me,'Stunned'), hp:me.hp, turns:(T.st(me,'Poisoned')||{}).turns, said:T.texts(f2)};
      var f3=SIM.log.length; await T.to('turn'); out.round2={hp:me.hp, turns:(T.st(me,'Poisoned')||{}).turns, said:T.texts(f3)};
      var f4=SIM.log.length; await T.next(); out.end2={hp:me.hp, poisoned:!!T.st(me,'Poisoned'), said:T.texts(f4)}; await T.to('turn'); return out; }""")
    ck("given in the Enemies' turn, a Status is late", r["late"]==[True,True], r)
    ck("the Recharge leaves it alone: in your turn the Hero is still Stunned and Poison hasn't bitten", r["atTurn"]["stunned"] and r["atTurn"]["cannot"] and r["atTurn"]["hp"]==r["hp0"] and r["atTurn"]["turns"]==2 and not any(t.startswith(r["name"]+" ") and ("Poisoned" in t or "Stunned" in t) for t in r["atTurn"]["said"]), r["atTurn"])
    ck("ending your turn ticks it, before the Enemies act: Stunned ends, Poison bites, and the Log says so",
       r["phase"]=="enemy" and r["atEnd"]["stunned"] is False and r["atEnd"]["hp"]==r["hp0"]-3 and r["atEnd"]["turns"]==1 and r["atEnd"]["said"][:2]==[r["name"]+" takes 3 from Poisoned", r["name"]+" is no longer Stunned"], r["atEnd"])
    ck("its second turn passes the same way: nothing at the Recharge, its last bite as your next turn ends",
       r["round2"]["hp"]==r["hp0"]-3 and r["round2"]["turns"]==1 and r["end2"]["hp"]==r["hp0"]-6 and r["end2"]["poisoned"] is False and r["name"]+" is no longer Poisoned" in r["end2"]["said"], [r["round2"], r["end2"]])

    # ---- a card's own words, in either half ----
    r=E("""async ()=>{ T.shut(); T.calm(); var me=T.mine()[0], foe=T.foes()[0], out={};
      simRunText('[[this Unit]] gains [[AC +2]] for [[turns 1]]. [[target enemy]] gains [[Weakened 2]] for [[turns 1]].',{actor:me,target:foe,sourceCard:'Mine'});
      out.mine=[(me.mods||[]).filter(function(m){ return m.source==='Mine'; }).map(function(m){ return !!m.late; }), !!T.st(foe,'Weakened').late];
      await T.to('enemy');
      simRunText('[[this Unit]] gains [[AC +3]] for [[turns 1]]. [[target enemy]] gains [[Slowed 1]] for [[turns 1]].',{actor:foe,target:me,sourceCard:'Theirs'});
      out.theirs=[(foe.mods||[]).filter(function(m){ return m.source==='Theirs'; }).map(function(m){ return !!m.late; }), !!T.st(me,'Slowed').late];
      var ac=function(u){ return T.R.effective(u).ac; }; out.base=[ac(me)-2, ac(foe)-3];
      await T.to('turn'); out.atTurn={mine:ac(me), foe:ac(foe), weak:!!T.st(foe,'Weakened'), slowed:!!T.st(me,'Slowed')};
      await T.next(); out.atEnd={foe:ac(foe), slowed:!!T.st(me,'Slowed')}; await T.to('turn'); return out; }""")
    ck("a timed Stats change and a Status from your turn are not late; from the Enemies' turn they are", r["mine"]==[[False],False] and r["theirs"]==[[True],True], r)
    ck("your own boost lasts through the Enemies' turn and is gone by yours; so is what you gave them", r["atTurn"]["mine"]==r["base"][0] and r["atTurn"]["weak"] is False, r)
    ck("an Enemy's boost in its own turn lasts through yours, and what it gave you does too", r["atTurn"]["foe"]==r["base"][1]+3 and r["atTurn"]["slowed"] is True, r)
    ck("both end as your turn does", r["atEnd"]["foe"]==r["base"][1] and r["atEnd"]["slowed"] is False, r)

    # ---- a hazard's keyword follows the half it bites in ----
    r=E("""async ()=>{ T.shut(); T.calm(); var me=T.mine()[0], k=me.pos.q+','+me.pos.r, out={};
      SIM.map.hazards=SIM.map.hazards||{}; SIM.map.hazards[k]={damage:0, keyword:'Rooted', text:'Tar'};
      await T.to('enemy'); await T.to('waves'); out.late=!!(T.st(me,'Rooted')||{}).late; out.has=!!T.st(me,'Rooted');
      delete SIM.map.hazards[k]; await T.to('turn'); out.inTurn=!!T.st(me,'Rooted'); await T.next(); out.after=!!T.st(me,'Rooted'); await T.to('turn'); return out; }""")
    ck("a hazard that bites as the round ends gives a Status that lasts through your next turn", r=={"late":True,"has":True,"inTurn":True,"after":False}, r)

    # ---- the round ends once, even with no Enemy left to act ----
    r=E("""async ()=>{ T.shut(); var n=0, o=KETER_RULES.endTurn; KETER_RULES.endTurn=function(u){ n++; return o(u); };
      var hero=T.mine().filter(function(u){ return /hero/i.test(u.cardType||''); })[0];
      T.foes().forEach(function(e){ e.down=true; e.hp=0; });
      var out={pile:(SIM.enemyPile||[]).length, wave:SIM.wave, nrg0:hero.nrg, max:hero.nrgMax};
      await T.next(); out.phase1=SIM.phase; out.n1=n; await T.next(); out.phase2=SIM.phase; out.n2=n; out.nrg=hero.nrg; out.wave2=SIM.wave;
      KETER_RULES.endTurn=o; await T.to('turn'); return out; }""")
    ck("with a wave cleared and more to come, the Enemy turn has nobody in it", r["pile"]>0 and r["phase1"]=="enemy" and r["n1"]==0, r)
    ck("the round is ended once: a Hero's Energy is refilled once, and the next wave arrives", r["phase2"]=="waves" and r["n2"]==1 and r["nrg"]==r["nrg0"]+r["max"] and r["wave2"]==r["wave"]+1, r)

    # ---- two Units of one name holding fire ----
    r=E("""()=>{ T.shut(); var a=T.mine()[0], held=simHoldable(a)[0]; if(!held) return {none:true};
      var twin=JSON.parse(JSON.stringify(a)); twin.id='twin'; twin.pos=null; SIM.units.push(twin);
      var free=Object.keys(SIM.map.hexes).map(T.R.hexParse).filter(function(h){ return !simUnitAt(h.q,h.r); })[0]; twin.pos=free;
      a.nrg=a.nrgMax; twin.nrg=twin.nrgMax; var from=SIM.log.length;
      simHoldFire(a, held.name); simHoldFire(twin, held.name);
      var out={said:T.texts(from), both:!!a.holding && !!twin.holding};
      SIM.units=SIM.units.filter(function(u){ return u!==twin; }); a.holding=null; return out; }""")
    ck("two Units of one name holding fire one after the other are two lines in the Log", r.get("none") or (r["both"] and len([t for t in r["said"] if " holds fire with " in t])==2), r)

    # ---- Auto plays whole rounds ----
    E("()=>simDebugStart('TEST \\u00b7 Corridor')"); pg.wait_for_timeout(700)
    E(START); pg.wait_for_timeout(700); E(LIB)
    r=E("""()=>new Promise(function(done){ T.shut();
      var hero=T.mine().filter(function(u){ return /hero/i.test(u.cardType||''); })[0];
      T.mine().forEach(function(u){ u.hp=u.hpMax=400; u.behaviors=[{k:'decisive'}]; });
      T.R.addStatus(hero,'Poisoned',2,null,2);
      var foe=T.foes()[0]; T.R.addStatus(foe,'Stunned',null,null,1);
      var out={pile:(SIM.enemyPile||[]).length, wave0:SIM.wave, round0:SIM.round, foe:foe.name}, from=SIM.log.length;
      simRunAuto();
      var n=0, t=setInterval(function(){ if(SIM.over || n++>4000){ clearInterval(t);
        var said=T.texts(from);
        out.over=!!SIM.over; out.result=SIM.result; out.round=SIM.round; out.wave=SIM.wave; out.busy=!!SIM.busy; out.phase=SIM.phase;
        out.waves=said.filter(function(x){ return /^Wave \\d of /.test(x); }).length;
        out.aether=said.filter(function(x){ return /^Heroes generated /.test(x); }).length;
        out.draws=said.filter(function(x){ return /^Drew \\d+ card/.test(x) || x==='The Deck is empty'; }).length;
        out.poison=said.filter(function(x){ return x===hero.name+' takes 2 from Poisoned'; }).length;
        out.unstunned=said.indexOf(out.foe+' is no longer Stunned')>=0;
        out.stunnedTurns=said.filter(function(x){ return x===out.foe+' is Stunned and loses its turn'; }).length;
        out.tail=said.slice(-4); done(out); } }, 20); })""")
    ck("Auto runs a fight with more waves to come to a real end, not sixty empty rounds and a Draw", r["over"] and r["result"] in ("Victory","Defeat") and not r["busy"] and r["round"]<60, {k:r[k] for k in ["over","result","round","wave","busy","tail"]})
    ck("the later waves arrive on Auto", r["waves"]>=1 and r["wave"]>r["wave0"], r)
    ck("Aether is generated and cards are drawn each round", r["aether"]>=1 and r["draws"]>=1 and r["aether"]>=min(r["round"]-r["round0"],2)-1, r)
    ck("Statuses tick on Auto: Poison for two turns bites twice, and an Enemy Stunned for a turn loses one turn, not all of them", r["poison"]==2 and r["unstunned"] and r["stunnedTurns"]<=1, r)

    # ---- the fights the game is checked against ----
    gen=pathlib.Path("make_sim_cases.js").read_text()
    ck("the cases the game replays end the Player's turn the simulator's way", '"simHalf", "simTurnEndTick"' in gen and gen.count("lateTick();")==2)
    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"STATUS TIMING PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
