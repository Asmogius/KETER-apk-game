"""v13.4 (Handbook 15.8): Usability Restrictions removed from the Handbook and
the Forge; variable costs (X chosen as a card is played, at least 1; X as any
keyword's number; a stat written N(X); X = 1 when nobody paid; a carried
Action card asking each time; the cost saved with its X); Dimensional
Instability sending only what the current District has; and the Pouch check
counting X as 1."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_variable")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9981),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)[:340]) if d not in ("",None) and not c else ""))
LIB=r"""()=>{ window.T={ R:window.KETER_RULES,
  unit:function(n){ return SIM.units.filter(function(u){ return u.name===n; })[0]; },
  lib:function(n){ return simAllCards().filter(function(c){ return c.name===n; })[0]; },
  card:function(n){ return simHandCardOf(simAllCards().filter(function(c){ return c.name===n; })[0]); },
  act:function(u,name){ return (u.actions||[]).filter(function(a){return a.name===name;})[0]; },
  names:function(list){ return (list||[]).map(function(c){ return (c&&c.name)||String(c); }); },
  texts:function(from){ return SIM.log.slice(from||0).map(function(l){ return l.text; }); },
  pick:function(u){ var pk=SIM.pick; SIM.pick=null; if(pk) pk.done(u); },
  x:function(n){ var w=window._simX; window._simX=null; document.getElementById('modal').classList.remove('on'); if(w) w.then(n); return !!w; },
  shut:function(){ var m=document.getElementById('modal'); if(m) m.classList.remove('on'); window._simX=null; SIM.pick=null; SIM.halted=null; SIM.haltShown=false; },
  total:function(){ return window.KETER_RULES.aetherTotal(SIM.aether); }
}; return true; }"""
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9981/"); pg.wait_for_timeout(2000)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2200)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    E=pg.evaluate

    # ---- the Handbook ----
    hb=" ".join(pathlib.Path("handbook.html").read_text(encoding="utf-8").split())
    md=pathlib.Path("handbook_v14-0.md").read_text(encoding="utf-8")
    ck("the Handbook has been through Revision 15.8", "Revision 15.8" in hb)
    ck("Usability Restrictions is no longer a section of it", "## Usability Restrictions" not in md and 'id="usability-restrictions"' not in hb)
    ck("Who May Use a Card says nothing restricts it", "Nothing restricts who may use a card" in hb and "any Troop may perform any Command" in hb)
    ck("no card is said to name who may use it", "may use them" not in md and "Most specify which Archetype" not in md)
    ck("Variable Costs says how X works: at least 1, in any keyword's number, in a stat as N(X), 1 when unpaid",
       all(t in hb for t in ["X is at least 1","X stands wherever a keyword takes a number","A stat may be written N(X)","Unpaid, X is 1"]))
    ck("and the glossary has Variable Cost", "<strong>Variable Cost</strong>" in hb)
    ck("Dimensional Instability says what happens with none in the District", "the Enemy that was drawn arrives after all" in hb)
    cl=" ".join(pathlib.Path("changelog.html").read_text(encoding="utf-8").split())
    ck("the Change Log has Revision 15.8", "Revision 15.8" in cl and "Usability Restrictions are removed" in cl)

    # ---- the keyword library ----
    r=E("""()=>{ var K=window.KETER_KW;
      var t=["[[target enemy]] takes [[damage X]].","[[Deploy X Aether Battery]].","[[Deploy 2 Model X]].","[[this Unit]] gains [[HP +X]] for [[turns X]].","[[AoE X]].","X marks the spot."];
      var an=K.analyse(t[0]);
      return {uses:t.map(function(x){ return K.usesX(x); }), filled:t.map(function(x){ return K.fillX(x,3); }), shown:t.map(function(x){ return K.render(x); }),
        flagged:K.problems(an,{kind:'action',variable:false}), fine:K.problems(an,{kind:'action',variable:true}), unsaid:K.problems(an,{kind:'action'}),
        least:K.fillX("[[damage X]]",0), numFirst:K.parse("[[+X HP]]")[0].n}; }""")
    ck("X is a keyword's number, and only that: a card called Model X is left alone", r["uses"]==[True,True,False,True,True,False], r["uses"])
    ck("filled in, the text reads with the number chosen", r["filled"][0]=="[[target enemy]] takes [[damage 3]]." and r["filled"][1]=="[[Deploy 3 Aether Battery]]." and
       r["filled"][2]=="[[Deploy 2 Model X]]." and r["filled"][3]=="[[this Unit]] gains [[HP +3]] for [[turns 3]]." and r["filled"][4]=="[[AoE 3]].", r["filled"])
    ck("on the card it reads as X: +X HP, for X turns, AoE X tiles", r["shown"][3]=="This Unit gains +X HP for X turns." and r["shown"][4]=="AoE X tiles." and r["shown"][0]=="Target enemy takes damage X.", r["shown"])
    ck("X on a card with no variable cost is a problem; on one with, it is not", len(r["flagged"])==1 and "variable cost" in r["flagged"][0] and r["fine"]==[] and r["unsaid"]==[], r)
    ck("X is never less than 1, and a Stat may be written number first", r["least"]=="[[damage 1]]" and r["numFirst"]=="+X", r)

    # ---- a card's cost, as it is saved and read ----
    E("()=>simDebugStart('TEST \\u00b7 Corridor')"); pg.wait_for_timeout(1200)
    E("""()=>{ var w=simWiz(); w.startTroops=['Test Swarm','Test Drone']; w.protos=[]; w.cons={}; w.instability=0;
      var vex=simAllCards().filter(function(c){ return c.name==='Quillon Vex'; })[0];
      simWizFinish(); }"""); pg.wait_for_timeout(1200)
    E(LIB)
    r=E("""()=>{ var b=T.card('Test Barrage'), s=T.card('Test Swarm'), d=T.card('Test Drone Bank'), c=T.card('Test Capacitor'), plain=T.card('Test Rally');
      var old=simHandCardOf({name:'Old X', cardType:'command', hasVariableCost:true, aetherCost:{generic:0,affinity:1,affinity2:0}, affinities:[{district:'3'}], entries:[]});
      var old2=simHandCardOf({name:'Old X2', cardType:'command', hasVariableCost:true, aetherCost:{generic:2,affinity:0,affinity2:0}, affinities:[{district:'3'}], entries:[]});
      var mine=simHandCardOf({name:'Mine', cardType:'command', aetherCost:{generic:0,affinity:1}, _raw:{aeGen:'xx', aeAff:'1'}, affinities:[{district:'2'}], entries:[]});
      return {b:b.cost, s:s.cost, d:d.cost, c:c.cost, plain:plain.cost, vars:[b,s,d,c,plain].map(simCardVar),
        labels:[b,s,d,c,plain].map(function(x){ return simCostLabel(x); }), at3:[b,s,d,c].map(function(x){ return simCardCost(x,3); }),
        least:simCardCost(d,0), old:old.cost, old2:old2.cost, mine:mine.cost, spec:simUnitSpec(T.lib('Test Swarm')).x, specPlain:simUnitSpec(T.lib('Test Drone')).x}; }""")
    ck("a variable cost keeps its X in the slot it was written in", r["b"]["generic"]=="X" and r["s"]["affinity"]=="X" and r["d"]["generic"]=="XX" and r["c"]=={"generic":"X","affinity":1}, r)
    ck("the card knows it is variable; an ordinary card is not", r["vars"]==[True,True,True,True,False], r["vars"])
    ck("its cost reads with X until X is chosen", r["labels"][0]=="X\u25c7" and r["labels"][1]=="X D3" and r["labels"][2]=="XX\u25c7" and r["labels"][3]=="1 D3 + X\u25c7" and r["labels"][4]=="1\u25c7", r["labels"])
    ck("at X = 3: X costs 3, XX costs 6, beside whatever else the card costs", r["at3"][0]["generic"]==3 and r["at3"][1]["affinity"]==3 and r["at3"][2]["generic"]==6 and r["at3"][3]=={"generic":3,"affinity":1,"district":"3"}, r["at3"])
    ck("X is never taken as less than 1", r["least"]["generic"]==2, r["least"])
    ck("a card saved before 13.4, with only the flag, gets its X in the first empty slot", r["old"]=={"generic":"X","affinity":1} and r["old2"]=={"generic":2,"affinity":"X"}, [r["old"],r["old2"]])
    ck("a card of your own keeps the X the Forge has for it", r["mine"]=={"generic":"XX","affinity":1}, r["mine"])
    ck("a Unit from a variable-cost card has X = 1 until it is paid for", r["spec"]==1 and r["specPlain"] is None, r)

    # ---- Starting Troops: nobody chose X ----
    r=E("""()=>{ var s=T.unit('Test Swarm'); return {hp:s&&s.hpMax, x:s&&s.x, text:s&&T.act(s,'Swarm Bite').text, drone:T.unit('Test Drone').x===undefined}; }""")
    ck("a Starting Troop with a variable cost arrives at X = 1: 4 Health, and its text reads 1", r["hp"]==4 and r["x"]==1 and r["text"]=="[[target enemy]] takes [[damage 1]]." and r["drone"], r)

    # ---- playing a card for X ----
    r=E("""()=>{ SIM.phase='turn'; SIM.discard=[]; SIM.hand=[T.card('Test Barrage')]; SIM.aether={};
      var cant=simCanPlay(SIM.hand[0]); SIM.aether={generic:5}; var can=simCanPlay(SIM.hand[0]), max=simMaxX(SIM.hand[0]);
      simPlayCard(0); var w=window._simX, box=document.getElementById('modal').innerText;
      return {cant:cant, can:can, max:max, asked:!!w, wmax:w&&w.max, n:w&&w.n, box:box, paid:T.total(), hand:SIM.hand.length}; }""")
    ck("with an empty Bank it can't be played; with 5 Aether X can be up to 5", r["cant"] is False and r["can"] is True and r["max"]==5, r)
    ck("playing it asks for X first, starting at 1, and nothing is paid yet", r["asked"] and r["n"]==1 and r["wmax"]==5 and r["paid"]==5 and r["hand"]==1 and "choose x" in r["box"].lower() and "X = 1" in r["box"], r)
    pg.locator("#simXMore").click(); pg.wait_for_timeout(150); pg.locator("#simXMore").click(); pg.wait_for_timeout(150)
    r=E("()=>{ return {n:window._simX.n, box:document.getElementById('modal').innerText, less:document.getElementById('simXLess').disabled}; }")
    ck("the stepper raises X and says what it costs", r["n"]==3 and "X = 3" in r["box"] and "Costs 3\u25c7" in r["box"] and r["less"] is False, r)
    pg.locator("#simXGo").click(); pg.wait_for_timeout(250)
    r=E("""()=>{ var g=SIM.units.filter(function(u){ return u.side==='enemy' && !u.down && u.pos; })[0]; g.hp=g.hpMax=40; var from=SIM.log.length;
      var asked=!!SIM.pick, before=T.total(); T.pick(g);
      var st=(g.statuses||[]).filter(function(s){ return s.name==='Weakened'; })[0];
      return {asked:asked, before:before, after:T.total(), hp:g.hp, weak:st&&st.n, turns:st&&st.turns, log:T.texts(from), discard:T.names(SIM.discard), hand:SIM.hand.length}; }""")
    ck("then it asks who, and is paid for as it lands: 3 Aether for X = 3", r["asked"] and r["before"]==5 and r["after"]==2 and r["hand"]==0 and r["discard"]==["Test Barrage"], r)
    ck("its text is carried out with X in place: 3 damage, Weakened 3 for 2 turns", r["hp"]==37 and r["weak"]==3 and r["turns"]==2, r)
    ck("the Log says what X was", any(l.startswith("Played Test Barrage (X = 3) on ") for l in r["log"]), r["log"])
    r=E("()=>{ simUndo(); return {total:T.total(), hand:T.names(SIM.hand), cost:SIM.hand[0]&&SIM.hand[0].cost.generic}; }")
    ck("Undo takes it back: the Aether returns, and the card still costs X", r=={"total":5,"hand":["Test Barrage"],"cost":"X"}, r)
    r=E("""()=>{ simPlayCard(0); var a=!!window._simX; document.getElementById('simXNo').click(); return {asked:a, gone:!window._simX, total:T.total(), hand:SIM.hand.length}; }""")
    ck("Not yet puts it back with nothing spent", r=={"asked":True,"gone":True,"total":5,"hand":1}, r)

    # ---- XX ----
    r=E("""()=>{ SIM.hand=[T.card('Test Drone Bank')]; SIM.aether={generic:5};
      SIM.units.filter(function(u){ return u.side==='ally'; }).forEach(function(u,i){ u.pos={q:-3-i, r:2}; });      // off the spawn tiles
      var max=simMaxX(SIM.hand[0]), n=SIM.units.length, from=SIM.log.length; simPlayCard(0); T.x(2);
      var made=SIM.units.slice(n).map(function(u){ return u.name.replace(/ \\d+$/,''); });
      return {max:max, total:T.total(), made:made, log:T.texts(from)}; }""")
    ck("XX is X paid twice: 5 Aether allows X = 2, and it costs 4", r["max"]==2 and r["total"]==1, r)
    ck("Deploy X puts down X of them", r["made"]==["Test Drone","Test Drone"] and any("(X = 2)" in l for l in r["log"]), r)

    # ---- a Troop for X ----
    r=E("""()=>{ SIM.units=SIM.units.filter(function(u){ return !(u.side==='ally' && /Drone/.test(u.name) && !u.card); });
      SIM.hand=[T.card('Test Swarm')]; SIM.aether={d3:4, generic:9}; var max=simMaxX(SIM.hand[0]), n=SIM.units.length, from=SIM.log.length;
      simPlayCard(0); T.x(3); var u=SIM.units[SIM.units.length-1];
      return {max:max, added:SIM.units.length===n+1, name:u.name.replace(/ \\d+$/,''), hp:u.hp, hpMax:u.hpMax, x:u.x, text:T.act(u,'Swarm Bite').text, d3:SIM.aether.d3, gen:SIM.aether.generic,
        card:u.card&&u.card.name, log:T.texts(from), id:u.id}; }""")
    ck("an X in the Affinity slot is paid in that District's Aether: 4 D3 allows X = 4", r["max"]==4 and r["d3"]==1 and r["gen"]==9, r)
    ck("the Troop arrives with N for each X: 12 Health at X = 3", r["added"] and r["name"]=="Test Swarm" and r["hp"]==12 and r["hpMax"]==12 and r["x"]==3, r)
    ck("its own text reads with its X from then on", r["text"]=="[[target enemy]] takes [[damage 3]]." and any(l=="Test Swarm deployed (X = 3)" for l in r["log"]), r)
    r=E("""()=>{ var u=SIM.units[SIM.units.length-1], g=SIM.units.filter(function(x){ return x.side==='enemy' && !x.down && x.pos; })[0];
      g.hp=g.hpMax=40; g.ac=0; g.pos={q:u.pos.q+1, r:u.pos.r}; u.nrg=3; SIM_FORCE.push(20); SIM_FORCE.push(20);
      simConfirmAttack(u,g,T.act(u,'Swarm Bite')); return {hp:g.hp}; }""")
    pg.wait_for_timeout(700)
    ck("and its Action does it: 1 damage and 3 more", r["hp"]==36, r)
    r=E("""()=>{ var u=SIM.units[SIM.units.length-1]; u.hp=0; simCheckDowns(); var c=SIM.discard[SIM.discard.length-1];
      return {name:c&&c.name, cost:c&&c.cost.affinity, vars:c&&simCardVar(c)}; }""")
    ck("gone down, its card is in the Discard Pile, still costing X, to be chosen again", r=={"name":"Test Swarm","cost":"X","vars":True}, r)
    r=E("""()=>{ var w=T.unit('Test Warden'), n=SIM.units.length; T.shut();
      SIM.units.filter(function(u){ return u.side==='ally' && !u.down; }).forEach(function(u,i){ u.pos={q:-3-i, r:2}; });
      simRunText('[[Deploy 1 Test Swarm]].',{actor:w, sourceCard:'T'}); var u=SIM.units[SIM.units.length-1];
      return {added:SIM.units.length===n+1, hp:u.hpMax, x:u.x, text:T.act(u,'Swarm Bite').text}; }""")
    ck("put down by a Deploy, nobody paid: X is 1", r=={"added":True,"hp":4,"x":1,"text":"[[target enemy]] takes [[damage 1]]."}, r)

    # ---- Equipment for X ----
    r=E("""()=>{ T.shut(); var w=T.unit('Test Warden'), hp=w.hpMax; SIM.hand=[T.card('Test Capacitor')]; SIM.aether={d3:1, generic:4}; var from=SIM.log.length;
      simPlayCard(0); T.x(4); T.pick(w);
      return {was:hp, now:w.hpMax, fx:w.equipFx[w.equipFx.length-1].fx[0].text, total:T.total(), log:T.texts(from)}; }""")
    ck("Equipment played for X reads with it while it is worn: +4 Health at X = 4", r["now"]==r["was"]+4 and r["fx"]=="[[attached Unit]] gains [[HP +4]]." and r["total"]==0, r)
    ck("and the Log says so", any(l=="Test Capacitor equipped on Test Warden (X = 4)" for l in r["log"]), r["log"])

    # ---- X with no value ----
    r=E("""()=>{ T.shut(); var w=T.unit('Test Warden'), g=SIM.units.filter(function(x){ return x.side==='enemy' && !x.down && x.pos; })[0]; var hp=g.hp;
      simRunText('[[target enemy]] takes [[damage X]].',{actor:w, target:g, sourceCard:'No Cost'}); var halted=SIM.halted;
      T.shut(); simRunText('[[target enemy]] takes [[damage X]].',{actor:w, target:g, sourceCard:'Paid', x:2});
      return {halted:halted, dealt:hp-g.hp, after:SIM.halted}; }""")
    ck("X on a card with no variable cost stops as a card problem, and nothing happens", r["halted"]=="No Cost: X has no value here, because the card has no variable cost. It was not carried out.", r)
    ck("given an X, the same words are carried out", r["dealt"]==2 and r["after"] is None, r)

    # ---- a carried Action card with a variable cost ----
    E("()=>simDebugStart('TEST \\u00b7 Corridor')"); pg.wait_for_timeout(1200)
    E("""()=>{ var w=simWiz(); var hero=w.heroes[0]; w.actions[hero]=(w.actions[hero]||[]).concat(['master|Test Overcharge']); w.startTroops=[]; w.protos=[]; w.cons={}; w.instability=0; simWizFinish(); }""")
    pg.wait_for_timeout(1200); E(LIB)
    r=E("""()=>{ var u=SIM.units.filter(function(x){ return x.side==='ally' && (x.actions||[]).some(function(a){ return a.name==='Overcharge'; }); })[0];
      if(!u) return {none:T.names(SIM.units), acts:SIM.units.map(function(x){ return T.names(x.actions); })};
      var a=T.act(u,'Overcharge'), g=SIM.units.filter(function(x){ return x.side==='enemy' && !x.down && x.pos; })[0];
      g.pos={q:u.pos.q+2, r:u.pos.r}; g.hp=g.hpMax=60; g.ac=0; u.nrg=6; SIM.phase='turn';
      SIM.aether={}; var none=simActionState(u,a);
      SIM.aether={d3:3}; var can=simActionState(u,a).ok; SIM.selected=u.id; var bar=simActionBarHTML(u).replace(/<[^>]+>/g,' ');
      simPickAction(u,'Overcharge'); var w=window._simX;
      window._ov={u:u.id, g:g.id};
      return {aether:a.aether, raw:a.aetherX, text:a.text, tmpl:a.textX, none:none, can:can, bar:bar, asked:!!w, max:w&&w.max, pending:!!SIM.pendingAct}; }""")
    ck("a carried Action card with a variable cost stands at X = 1 until it is used", r.get("aether")=={"generic":0,"affinity":1,"district":"3"} and r.get("raw")=={"generic":0,"affinity":"X"} and r.get("text")=="[[target enemy]] takes [[damage 1]]." and r.get("tmpl")=="[[target enemy]] takes [[damage X]].", r)
    ck("it needs its least to be used, and its button shows X", r.get("none")=={"ok":False,"why":"Needs 1 D3 Aether"} and r.get("can") is True and "1 NRG + X D3" in r.get("bar",""), r)
    ck("choosing it asks for X, up to what the Bank holds, before it is aimed", r.get("asked") and r.get("max")==3 and r.get("pending") is False, r)
    r=E("""()=>{ var u=SIM.units.filter(function(x){ return x.id===window._ov.u; })[0], g=SIM.units.filter(function(x){ return x.id===window._ov.g; })[0], a=T.act(u,'Overcharge');
      T.x(2); var pending=!!SIM.pendingAct, text=a.text; SIM_FORCE.push(20); SIM_FORCE.push(20); simConfirmAttack(u,g,a);
      return {pending:pending, text:text, d3:SIM.aether.d3, hp:g.hp, nrg:u.nrg}; }""")
    pg.wait_for_timeout(700)
    ck("used for X = 2: aimed, 2 District 3 Aether and its Energy paid, 3 damage and 2 more", r=={"pending":True,"text":"[[target enemy]] takes [[damage 2]].","d3":1,"hp":55,"nrg":5}, r)

    # ---- Dimensional Instability ----
    r=E("""()=>{ T.shut(); SIM.instability=100; var was=SIM.map.district, out={};
      SIM_FORCE.push(1); SIM_FORCE.push(1); SIM_FORCE.push(1); var e=simInstabilityPick(); out.elite=e&&e.cardType; out.eliteD=e&&String((e.affinities[0]||{}).district);
      SIM_FORCE.push(1); SIM_FORCE.push(6); SIM_FORCE.push(1); var m=simInstabilityPick(); out.mini=m&&m.cardType;
      SIM.map.district='5'; var from=SIM.log.length;
      SIM_FORCE.push(1); SIM_FORCE.push(1); var none=simInstabilityPick(); out.none=none; out.said=T.texts(from);
      SIM_FORCE.push(1); SIM_FORCE.push(6); var none2=simInstabilityPick(); out.none2=none2; out.said2=T.texts(from).slice(1);
      SIM.map.district=was; SIM.instability=0; out.off=simInstabilityPick(); out.district=String(was); return out; }""")
    ck("Instability sends an Elite or a Mini-Boss of the floor's own District", r["elite"]=="elite" and r["mini"]=="miniboss" and r["eliteD"]==r["district"], r)
    ck("with none of that kind in the District, nothing unusual comes, and the Log says so", r["none"] is None and r["said"]==["Dimensional instability stirs, but District 5 has no Elite to send: an ordinary Enemy arrives"] and
       r["none2"] is None and r["said2"]==["Dimensional instability stirs, but District 5 has no Mini-Boss to send: an ordinary Enemy arrives"], r)
    ck("at 0% it never stirs", r["off"] is None, r)

    # ---- the Pouch check ----
    r=E("""()=>{ var c=function(n){ return simAllCards().filter(function(x){ return x.name===n; })[0]; };
      return {x:aetherCostLeast(c('Test Barrage')), xx:aetherCostLeast(c('Test Drone Bank')), cap:aetherCostLeast(c('Test Capacitor')), plain:aetherCostLeast(c('Test Mortar Strike')),
        old:aetherCostLeast({hasVariableCost:true, aetherCost:{generic:0,affinity:1,affinity2:0}})}; }""")
    ck("for the Pouch's minimum, X counts 1 and XX counts 2", r=={"x":1,"xx":2,"cap":2,"plain":2,"old":2}, r)

    # ---- Auto finds loot (13.4): left standing on a Loot Tile, a Unit of yours finds what is there ----
    r=E("""()=>new Promise(function(done){ T.shut();
      var u=SIM.units.filter(function(x){ return x.side==='ally' && !x.down && x.pos; })[0];
      var k=u.pos.q+','+u.pos.r, labs=SIM.map.colorLabels||{};
      var lootC=Object.keys(labs).filter(function(c){ return /loot/i.test(labs[c]); })[0];
      SIM.map.hexes[k]=Object.assign({}, SIM.map.hexes[k], {c:+lootC}); SIM.looted={}; SIM.loot=null;
      SIM.units.forEach(function(x){ if(x.side==='ally') x.behaviors=[{k:'steadfast'}]; });
      var from=SIM.log.length;
      simAutoAllies(function(){ done({label:String(labs[lootC]||''), looted:!!(SIM.looted||{})[k], finds:T.texts(from).filter(function(t){ return / finds: /.test(t); }).length,
        haul:!KETER_LOOT.isEmpty(SIM.loot), stayed:(u.pos.q+','+u.pos.r)===k, name:u.name}); });
    })""")
    pg.wait_for_timeout(300)
    ck("Auto leaves a Unit on a Loot Tile: it finds what is there, once, as one moved by hand does", r["looted"] and r["finds"]==1 and r["haul"] and r["stayed"], r)

    # ---- Stunned (13.4): "cannot act or move at all" holds on an Enemy's own turn, on Auto, and for a held shot ----
    r=E("""()=>new Promise(function(done){ T.shut();
      var R=T.R, foe=SIM.units.filter(function(x){ return x.side==='enemy' && !x.down && x.pos; })[0], me=SIM.units.filter(function(x){ return x.side==='ally' && !x.down && x.pos; })[0];
      if(!foe || !me) return done({missing:true});
      var was={fp:foe.pos, mp:me.pos, fc:foe.comboAt};
      foe.pos={q:me.pos.q, r:me.pos.r-1};
      if(!SIM.map.hexes[foe.pos.q+','+foe.pos.r] ) foe.pos={q:me.pos.q+1, r:me.pos.r};
      foe.comboAt=1; R.addStatus(foe,'Stunned',null,'ally',2);
      var hp=me.hp, from=SIM.log.length, at=foe.pos.q+','+foe.pos.r;
      simOneEnemy(foe, function(){
        var out={hp:me.hp===hp, stayed:(foe.pos.q+','+foe.pos.r)===at, said:T.texts(from), combo:foe.comboAt};
        R.addStatus(me,'Stunned',null,'enemy',2); me.behaviors=[]; var fh=foe.hp, from2=SIM.log.length, mat=me.pos.q+','+me.pos.r;
        SIM.units.forEach(function(x){ if(x.side==='ally' && x!==me) x.down=true; });
        simAutoAllies(function(){ out.autoHp=foe.hp===fh; out.autoStayed=(me.pos.q+','+me.pos.r)===mat; out.autoSaid=T.texts(from2); done(out); });
      });
    })""")
    pg.wait_for_timeout(300)
    ck("a Stunned Enemy loses its turn: it doesn't attack from where it stands, its Combo starts again, and the Log says so", r.get("hp") and r.get("stayed") and r.get("combo")==0 and any(t.endswith(" is Stunned and loses its turn") for t in r.get("said",[])) and not any(" used " in t for t in r.get("said",[])), r)
    ck("so does a Stunned Unit of yours on Auto", r.get("autoHp") and r.get("autoStayed") and any(t.endswith(" is Stunned and loses its turn") for t in r.get("autoSaid",[])) and not any(" used " in t for t in r.get("autoSaid",[])), r)

    # ---- your own cards, converted ----
    comp=json.loads(pathlib.Path("compendium_full.json").read_text())
    by={c["name"]:c for c in comp["cards"]}
    ck("no card says who may use it any more", not any("usableBySubtype" in c for c in comp["cards"]) and
       not any(c.get("archetypes") for c in comp["cards"] if c.get("cardType") in ("equipment","action","command")))
    ck("Aether battery and Scuttle Swarm have their X back, in the Any Affinity slot", by["Aether battery"]["aetherCost"]=={"generic":"X","affinity":1,"affinity2":0} and by["Scuttle Swarm"]["aetherCost"]["generic"]=="X", [by["Aether battery"]["aetherCost"], by["Scuttle Swarm"]["aetherCost"]])
    r=E("""()=>{ var s=simAllCards().filter(function(c){ return c.name==='Scuttle Swarm'; })[0];
      var one=T.R.unitFromCard(simUnitSpec(s),'ally'), three=T.R.unitFromCard(Object.assign(simUnitSpec(s),{x:3}),'ally');
      return {one:one.hpMax, three:three.hpMax, x:three.x, ac:three.ac}; }""")
    ck("Scuttle Swarm's Health of 5(X) is 5 at X = 1 and 15 at X = 3", r=={"one":5,"three":15,"x":3,"ac":8}, r)

    # ================= the Forge =================
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    F=pg.frame_locator('#v-forge iframe'); W="document.querySelector('#v-forge iframe').contentWindow"
    src=pathlib.Path("forge_v3.html").read_text(encoding="utf-8")
    ck("the Forge has no Usable by box, and prints no 'only' on a type line", "Usable by" not in src and "fUseSub" not in src and "' only'" not in src and "usableBySubtype:" not in src)
    r=E(f"""()=>{{ var fw={W}.KETER_BRIDGE;
      var a=fw.fromSchema({{cardType:'command', name:'A', aetherCost:{{generic:'XX',affinity:1,affinity2:0}}, hasVariableCost:true, affinities:[{{district:'3'}}], entries:[{{kind:'Active', text:'[[target enemy]] takes [[damage X]].'}}]}});
      var back=fw.toSchema(a);
      var old=fw.fromSchema({{cardType:'command', name:'B', aetherCost:{{generic:0,affinity:1,affinity2:0}}, hasVariableCost:true, affinities:[{{district:'3'}}], entries:[{{kind:'Active', text:'Deal X damage.'}}]}});
      var fixed=fw.fromSchema({{cardType:'command', name:'C', aetherCost:{{generic:2,affinity:0,affinity2:0}}, affinities:[{{district:'3'}}], usableBySubtype:'cyborg', archetypes:['Sniper'], entries:[{{kind:'Active', text:'[[target enemy]] takes [[damage X]].'}}]}});
      var troop=fw.fromSchema({{cardType:'troop', name:'D', aetherCost:{{generic:1,affinity:0,affinity2:0}}, affinities:[{{district:'3'}}], combatRoles:['melee'], stats:{{hp:'5(X)',ac:'9',nrg:'3',move:'4',int:'9',uslot:'1'}}, entries:[]}});
      function has(c, rx){{ return fw.computePings(c).some(function(p){{ return rx.test(p[1]); }}); }}
      return {{slots:[a.aeGen,a.aeAff], saved:back.aetherCost, flag:back.hasVariableCost, usable:('usableBySubtype' in back), fineA:!has(a,/variable cost|plain words|explains what X/),
        oldSlot:old.aeGen, oldWarn:has(old,/only in plain words/), fixedBad:has(fixed,/X needs a variable cost/), useSub:fixed.useSub===undefined||fixed.useSub==='',
        statBad:has(troop,/written with X, but this card has no variable cost/), type:fw.typeOf(fixed).noArch, eq:fw.typeOf({{type:'equipment'}}).noArch, act:fw.typeOf({{type:'action'}}).noArch, hero:!!fw.typeOf({{type:'hero'}}).noArch}}; }}""")
    ck("the Forge reads a variable cost into its slots, and saves it as it reads", r["slots"]==["XX","1"] and r["saved"]=={"generic":"XX","affinity":1,"affinity2":0} and r["flag"] is True, r)
    ck("a card that uses X as a keyword's number raises nothing", r["fineA"], r)
    ck("an older card's X goes to the first empty slot; X only in plain words is warned about", r["oldSlot"]=="X" and r["oldWarn"], r)
    ck("X on a card with no variable cost is flagged, in text and in a stat", r["fixedBad"] and r["statBad"], r)
    ck("a saved card no longer carries who may use it; Equipment, Action and Command cards take no Archetypes", r["usable"] is False and r["useSub"] and r["type"] is True and r["eq"] is True and r["act"] is True and r["hero"] is False, r)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:4]))
    b.close()
srv.shutdown()
print(f"VARIABLE PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
