"""The World Map and deployments (v12.8): the generated colony (six District
wedges round a central dock, Skull Level by ring, blocked tiles with every open
tile reachable, contents), what the player knows, clearing and coming back,
paths and ambush risk, the Sandbox round trip, floors for fights, Events,
deploying (Troops must be designs, copies paid, the starter's free copies,
locks), walking, POIs floor by floor with their final reward, ambushes, caches,
Events, Heroes sitting out, copies lost, retries and wipes, the Emergency Exit,
coming home, free fights paying only in Dev Mode, Take over from Auto, and the
World Map page with its Dev Mode tools."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_world")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9988),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

TEAM="""()=>{ var deck=['design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','test|Test Mortar Strike','test|Test Snare','test|Test Rally','test|Test Plating','test|Test Surge','test|Test Strip'];
  localStorage.setItem('keter-app-loadouts',JSON.stringify([{v:2,name:'Deploy Team',level:1,created:111,heroes:['test|Test Warden','test|Test Striker'],deck:deck,actions:{},pouch:{'basic|3':6}}]));
  /* (v14.14) the test Heroes lead the team out: Dev Mode makes them free, as the three free Heroes are */
  localStorage.setItem('keter-app-dock-tables',JSON.stringify({free:['Dock Hand','Hangar Rifleman','Field Medic','Test Warden','Test Striker']}));
  /* (v14.19) and every card it takes counts as held: the stash has checks of its own (verify_stash.py) */
  localStorage.setItem('keter-test-every-card','1'); localStorage.setItem('keter-test-paid-commons','1'); return true; }"""
LIB=r"""()=>{
window.T={
  W:KETER_WORLD, D:KETER_DEPLOY, L:KETER_LOOT, P:KETER_PROG,
  go:function(k){ var s=KETER_DEPLOY.cur(); s.pos=k; KETER_DEPLOY._save(s); KETER_WORLD.stand(k); return k; },
  find:function(kind, skull){ var W=KETER_WORLD, m=W.map(); return Object.keys(m.tiles).filter(function(k){ var c=W.contentAt(k); return c && c.kind===kind && !c.unique && (!skull || W.skullOf(k)===skull) && W.available(k); })[0]||null; },
  fight:function(spec){ simDeployFight(spec||KETER_DEPLOY.spec()); simWizFinish(); document.getElementById('modal').classList.remove('on'); return SIM.units.length; },
  win:function(){ SIM.units.forEach(function(u){ if(u.side==='enemy') u.hp=0; }); simCheckDowns(); SIM.wave=6; SIM.enemyPile=[]; simFinish({winner:'ally'}); return document.getElementById('modal').innerText; },
  lose:function(){ SIM.units.forEach(function(u){ if(u.side==='ally' && /hero/i.test(u.cardType)) u.hp=0; }); simCheckDowns(); simFinish({winner:'enemy'}); return document.getElementById('modal').innerText; },
  close:function(){ document.getElementById('modal').classList.remove('on'); }
}; return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9988/"); pg.wait_for_timeout(1500)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-dev'); localStorage.removeItem('keter-app-sim'); }")
    pg.evaluate(TEAM)
    pg.reload(); pg.wait_for_timeout(1900)
    E=pg.evaluate
    E(LIB)

    # ================= the generated map =================
    r=E("""()=>{ var W=KETER_WORLD, m=W.generate(4242), keys=Object.keys(m.tiles), all=W.allKeys(18);
      var reach=W.reach(m.tiles,m.dock), c={}, d={}, near=0;
      keys.forEach(function(k){ var t=m.tiles[k]; c[t.c]=(c[t.c]||0)+1; d[t.d]=(d[t.d]||0)+1; if(t.c && t.c!=='dock' && W.dist(k,m.dock)<2) near++; });
      var again=W.generate(4242);
      return {all:all.length, open:keys.length, reach:Object.keys(reach).length, dock:m.dock, dockC:m.tiles[m.dock].c, c:c, d:d, near:near, same:JSON.stringify(again.tiles)===JSON.stringify(m.tiles), radius:m.radius}; }""")
    ck("18 rings: 1,027 tiles", r["all"]==1027 and r["radius"]==18, r)
    ck("about one tile in seven blocked", 0.8<r["open"]/r["all"]<0.9, r["open"])
    ck("every open tile reachable from the dock", r["reach"]==r["open"], r)
    ck("the dock at the centre", r["dock"]=="0,0" and r["dockC"]=="dock", r)
    ck("six District wedges, each a fair share", sorted(k for k in r["d"] if k)==list("123456") and all(100<r["d"][k]<220 for k in "123456"), r["d"])
    ck("POIs, Ambushes, Caches and Events in their proportions", 35<=r["c"]["poi"]<=50 and 25<=r["c"]["ambush"]<=40 and 35<=r["c"]["cache"]<=50 and 25<=r["c"]["event"]<=40, r["c"])
    ck("nothing but the dock right beside it", r["near"]==0, r["near"])
    ck("a seed makes the same map again", r["same"])
    E("()=>{ KETER_WORLD.newMap(4242); }")
    r=E("""()=>{ var W=KETER_WORLD, m=W.map(), at=function(d){ return Object.keys(m.tiles).filter(function(k){ return W.dist(k,m.dock)===d; })[0]; };
      var out={}; [1,3,4,6,16,18].forEach(function(d){ out[d]=W.skullOf(at(d)); });
      var k=at(10); var t=m.tiles[k]; t.s=2; W.setMap(m,true); out.set=W.skullOf(k); t.s=0; W.setMap(m,true);
      out.dockAmb=W.ambushChance(m.dock); out.amb=W.ambushChance(at(7)); return out; }""")
    ck("Skull Level by ring: 1 for rings 1–3, 2 for 4–6, 6 for 16–18", r["1"]==1 and r["3"]==1 and r["4"]==2 and r["6"]==2 and r["16"]==6 and r["18"]==6, r)
    ck("a tile can have its own Skull Level", r["set"]==2, r)
    ck("an ambush: none at the dock, 5% per Skull Level each step", r["dockAmb"]==0 and r["amb"]==15, r)
    r=E("""()=>{ var W=KETER_WORLD, m=W.map(), far=Object.keys(m.tiles).filter(function(k){ return W.dist(k,m.dock)===18; })[0], p=W.path(m.dock,far);
      var ok=p.every(function(k,i){ return W.isOpen(k) && (!i || W.dist(k,p[i-1])===1); });
      var blocked=W.allKeys(18).filter(function(k){ return !W.isOpen(k); })[0];
      return {len:p.length, ok:ok, risk:W.pathRisk(p), none:W.path(m.dock,blocked)}; }""")
    ck("the way there: open tiles, one step at a time", r["ok"] and r["len"]>=19, r)
    ck("and the chance of at least one ambush on it", 90<r["risk"]<=100, r["risk"])
    ck("no way onto a blocked tile", r["none"] is None)
    r=E("""()=>{ var W=KETER_WORLD; W.resetState(); var m=W.map(), k=Object.keys(m.tiles).filter(function(x){ return W.dist(x,m.dock)===5; })[0];
      var before=W.known(k); W.stand(k); var nb=W.neighbours(k).filter(W.isOpen).every(function(n){ return W.known(n); });
      var far=Object.keys(m.tiles).filter(function(x){ return W.dist(x,k)===2; })[0]; return {before:before, self:W.known(k), nb:nb, far:W.known(far)}; }""")
    ck("what a tile holds is unknown at first", r["before"] is False)
    ck("standing on a tile shows it and its neighbours, for good", r["self"] and r["nb"] and r["far"] is False, r)
    r=E("""()=>{ var W=KETER_WORLD; W.resetState(); var k=T.find('cache'), s=W.state();
      W.clear(k,1); var a=W.isCleared(k), b0=W.backIn(k); W.endDeployment(); W.endDeployment(); W.endDeployment(); var b=W.isCleared(k); W.endDeployment(); var c=W.isCleared(k);
      W.resetState(); return {a:a, back:b0, b:b, c:c}; }""")
    ck("cleared in deployment 1, back once it and three more have ended", r["a"] and r["back"]==4 and r["b"] and r["c"] is False, r)
    r=E("""()=>{ var W=KETER_WORLD, k=T.find('poi'), c=W.contentAt(k); return {type:c.type, types:W.POI_TYPES}; }""")
    ck("a POI's type is a label: Lab, Security Armory, Bunker or Overrun Hideout", r["type"] in r["types"], r)

    # ================= the Sandbox round trip =================
    r=E("""()=>{ var W=KETER_WORLD, m=W.map(), lv=W.toLevel(m,'World Test');
      var back=W.fromLevel(lv), same=Object.keys(m.tiles).every(function(k){ var a=m.tiles[k], b=back.tiles[k]; return b && a.d===b.d && a.c===b.c && (a.s||0)===(b.s||0); });
      var syms=lv.symDefs.map(function(d){ return d.text; });
      /* edits: erase a tile, move the dock, give one a Skull Level, recolour one */
      var k1=lv.hexes[10][0]; lv.hexes=lv.hexes.filter(function(h){ return h[0]!==k1; });
      var k2=lv.hexes[20][0]; lv.hexes[20][1].lvl=5;
      var k3=lv.hexes[30][0]; lv.hexes[30][1].c=5;
      var dk=lv.marks.filter(function(x){ return x[1]===1; })[0]; var k4=lv.hexes[40][0]; dk[0]=k4;
      var ed=W.fromLevel(lv);
      return {type:lv.poiType, same:same, syms:syms, labels:lv.colorLabels, gone:!ed.tiles[k1], lvl:ed.tiles[k2].s, d3:ed.tiles[k3].d, dock:ed.dock===k4}; }""")
    ck("the map as a Sandbox World Map level", r["type"]=="World Map" and r["syms"]==["DK","PO","AM","CA","EV"], r)
    ck("its colours labelled by District", r["labels"]["5"]=="District 1 · Threshold Dynamics" and r["labels"]["1"]=="District 3 · Vantage Robotics", r["labels"])
    ck("and read back exactly", r["same"])
    ck("an erased tile is blocked; a tile's level is its Skull; a colour its District; DK the dock", r["gone"] and r["lvl"]==5 and r["d3"]=="1" and r["dock"], r)
    r=E("""()=>{ var W=KETER_WORLD; var n=W.saveToSandbox('World Test'); var lv=JSON.parse(localStorage.getItem('keter-hexmap-levels'))[n];
      var fl=W.floors().map(function(f){ return f.key; }), sb=W.sandboxMaps().map(function(x){ return x.key; });
      var sim=simAllCards?true:true; return {n:n, hexes:lv.hexes.length, inFloors:fl.indexOf(n)>=0, inMaps:sb.indexOf(n)>=0, src:W.map().source}; }""")
    ck("saved into the Sandbox's levels", r["n"]=="World Test" and r["hexes"]>800 and r["src"]=="sandbox:World Test", r)
    ck("a world map is not a floor to fight on", r["inMaps"] and not r["inFloors"], r)
    r=E("""()=>{ var W=KETER_WORLD; W.resetState(); var k=Object.keys(W.map().tiles)[5]; W.stand(k);
      var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')); var lv=all['World Test']; lv.hexes=lv.hexes.slice(0,lv.hexes.length-3); lv.saved=new Date(Date.now()+5000).toISOString(); localStorage.setItem('keter-hexmap-levels',JSON.stringify(all));
      var newer=W.sandboxNewer(); W.useSandbox('World Test'); return {newer:newer, kept:W.known(k), open:Object.keys(W.map().tiles).length, after:W.sandboxNewer()}; }""")
    ck("an edited copy in the Sandbox is noticed, and used without forgetting the explored map", r["newer"] and r["kept"] and not r["after"], r)
    E("()=>{ KETER_WORLD.newMap(4242); var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')); delete all['World Test']; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); }")

    # ================= floors for fights, and Events =================
    r=E("""()=>{ var W=KETER_WORLD, fl=W.floors(); KETER_LOOT.seed(3);
      var d3=W.drawFloors('3',1,3), amb=W.drawFloors('5',4,1,{ambush:true});
      return {n:fl.length, test:fl.every(function(f){ return f.test; }), d3:d3, amb:amb, c:[W.floorCount(1),W.floorCount(2),W.floorCount(3),W.floorCount(4),W.floorCount(5),W.floorCount(6)],
        waves:fl.filter(function(f){ return f.key==='TEST · Waves'; })[0]}; }""")
    ck("the test floors fill in until you have your own", r["n"]>=4 and r["test"] and len(r["d3"])==3 and len(r["amb"])==1, r)
    ck("a POI has 1 floor at Skull 1–2, 2 at 3–4, 3 at 5–6", r["c"]==[1,1,2,2,3,3], r["c"])
    ck("a floor's own Skull Level is its lowest spawn mark when none is set", r["waves"]["skull"]==1 and r["waves"]["district"]=="3", r["waves"])
    E("""()=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')); var w=JSON.parse(JSON.stringify(all['TEST · Corridor']));
      w.name='Mine D5 S4'; w.district='5 · Verdant Biogenics'; w.level='4'; w.testMap=false; all['Mine D5 S4']=w;
      var a=JSON.parse(JSON.stringify(all['TEST · Corridor'])); a.name='Mine Ambush'; a.poiType='Ambush'; a.district='5 · Verdant Biogenics'; a.level='4'; a.testMap=false; all['Mine Ambush']=a;
      localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); }""")
    r=E("""()=>{ var W=KETER_WORLD; KETER_LOOT.seed(4); return {poi:W.drawFloors('5',4,2), amb:W.drawFloors('5',4,1,{ambush:true}), other:W.drawFloors('2',1,1)}; }""")
    ck("your own floors first, by District and Skull Level", r["poi"][0]=="Mine D5 S4", r)
    ck("an ambush prefers an Ambush floor", r["amb"]==["Mine Ambush"], r)
    E("""()=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')); delete all['Mine D5 S4']; delete all['Mine Ambush']; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); }""")
    r=E("""()=>{ var W=KETER_WORLD, ev=W.events(), k=T.find('event'); var a=W.eventFor(k), b=W.eventFor(k);
      var mine=W.events(); mine[0].title='Changed'; W.saveEvents(mine); var ch=W.events()[0].title; W.resetEvents();
      return {n:ev.length, checks:ev.every(function(e){ return e.choices.length>=2 && e.choices.some(function(c){ return +c.check>0; }); }), same:a.id===b.id, ch:ch, back:W.events()[0].title}; }""")
    ck("eight drafted Events, each a choice, most with a d20 check", r["n"]==8 and r["checks"], r)
    ck("the same Event on a tile until it comes back", r["same"])
    ck("yours to rewrite, and reset", r["ch"]=="Changed" and r["back"]=="Sealed maintenance hatch", r)
    r=E("""()=>{ var W=KETER_WORLD, t=W.tables(); t.ambushStep=7; t.floorsBySkull[0]=2; W.saveTables(t); var saved=JSON.parse(localStorage.getItem(W.TAB_KEY)); var a=W.tables(); W.resetTables(); return {saved:saved, a:[a.ambushStep,a.floorsBySkull[0]], b:W.tables().ambushStep}; }""")
    ck("the world's tables keep only what differs", r["saved"]=={"ambushStep":7,"floorsBySkull":[2,1,2,2,3,3]} and r["a"]==[7,2] and r["b"]==5, r)

    # ================= deploying =================
    r=E("""()=>{ var l=JSON.parse(localStorage.getItem('keter-app-loadouts')); l[0].deck.push('master|Foundry Sentinel'); localStorage.setItem('keter-app-loadouts',JSON.stringify(l));
      var p=KETER_DEPLOY.plan(0); l[0].deck.pop(); localStorage.setItem('keter-app-loadouts',JSON.stringify(l)); return {ok:p.ok, why:p.reasons}; }""")
    ck("Troops must be designs: a Forge Troop stops it", r["ok"] is False and r["why"]==["Foundry Sentinel is a Forge Troop: Troops come only from the Workshop, unless Common"], r)
    r=E("""()=>{ var p=KETER_DEPLOY.plan(0); return {ok:p.ok, lines:p.lines, parts:p.parts, other:p.other, heroes:p.heroes}; }""")
    ck("the starter design: four copies free", r["ok"] and r["lines"][0]["free"]==4 and r["parts"]==[0]*6 and r["other"]==6, r)
    # (v14.21: 4 copies of a card at most, so the copies paid for are another design's)
    r=E("""()=>{ var W=KETER_WORKSHOP, d=W.blank('ch_test_general'); d.name='Plinker'; d.abilities[0].text='[[target enemy]] takes [[damage 2]].'; var id=W.put(d), each=W.cost(W.get(id)).parts[0];
      var l=JSON.parse(localStorage.getItem('keter-app-loadouts')); l[0].deck.push('design|Plinker','design|Plinker'); localStorage.setItem('keter-app-loadouts',JSON.stringify(l));
      KETER_LOOT.resetStock(); var a=KETER_DEPLOY.plan(0); var st=KETER_LOOT.stock(); st.parts.troop[0]=20; KETER_LOOT.setStock(st); var b=KETER_DEPLOY.plan(0);
      return {each:each, a:{ok:a.ok, afford:a.afford, parts:a.parts}, b:{ok:b.ok, parts:b.parts}}; }""")
    each=r["each"]
    ck("more copies cost Commons: two of another design", each>0 and r["a"]["parts"][0]==2*each and r["a"]["afford"] is False and r["a"]["ok"] is False, r)
    ck("affordable with the parts in the stockpile", r["b"]["ok"], r)
    r=E("""()=>{ var W=KETER_WORKSHOP, d=W.blank('ch_test_general'); d.name='Broken'; d.abilities[0].text='[[target enemy]] takes [[damage 2]] [[Burst 4]].'; var id=W.put(d);
      var l=JSON.parse(localStorage.getItem('keter-app-loadouts')); l[0].deck.push('design|Broken'); localStorage.setItem('keter-app-loadouts',JSON.stringify(l));
      var p=KETER_DEPLOY.plan(0); l[0].deck.pop(); localStorage.setItem('keter-app-loadouts',JSON.stringify(l)); W.remove(id); return p.reasons; }""")
    ck("a design that does not fit its chassis cannot go", len(r)==1 and r[0].startswith("Broken does not fit its chassis"), r)
    r=E("""()=>{ KETER_WORLD.resetState(); var s=KETER_DEPLOY.start(0); var st=KETER_LOOT.stock(), h=KETER_LOOT.history()[0];
      return {ok:s.ok, n:s.state.n, pos:s.state.pos, left:st.parts.troop[0], why:h.why, again:KETER_DEPLOY.plan(0).ok, lockD:KETER_DEPLOY.lockedDesign('ds_starter'),
        lockL:KETER_DEPLOY.lockedLoadout(JSON.parse(localStorage.getItem('keter-app-loadouts'))[0]), known:KETER_WORLD.known('1,0')}; }""")
    ck("deploying pays for the copies, with a note", r["ok"] and r["left"]==20-2*each and r["why"]=="Deployment 1 · copies paid", r)
    ck("and leaves from the dock, seeing what is around it", r["pos"]=="0,0" and r["n"]==1 and r["known"], r)
    ck("one deployment at a time", r["again"] is False)
    ck("its designs and Strike Team are locked until it comes home", r["lockD"] and r["lockL"], r)
    r=E("""()=>{ var W=KETER_WORKSHOP, d=W.get('ds_starter'); d.name='Changed'; return {put:W.put(d), del:W.remove('ds_starter'), name:W.get('ds_starter').name}; }""")
    ck("a locked design is not changed", r=={"put":None,"del":False,"name":"Frame Trooper"}, r)

    # ================= walking =================
    r=E("""()=>{ var D=KETER_DEPLOY, W=KETER_WORLD, t=W.tables(); t.ambushStep=0; W.saveTables(t);
      var far=D.stepTo('5,-2'), n=W.neighbours('0,0').filter(W.isOpen)[0], a=D.stepTo(n), back=D.stepTo('0,0');
      t.ambushStep=100; W.saveTables(t); KETER_LOOT.seed(9); var b=D.stepTo(n); var act=D.cur().activity; W.resetTables();
      return {far:far.moved, a:a.moved, amb0:a.ambush, home:back.home, b:b.ambush, act:act&&act.kind, steps:D.cur().steps}; }""")
    ck("only a step to an open neighbour", r["far"] is False and r["a"], r)
    ck("the dock is home", r["home"], r)
    ck("each step can spring an ambush", r["amb0"] is False and r["b"] is True and r["steps"]==3, r)
    r=E("""()=>{ var D=KETER_DEPLOY; var sp=D.ambush(D.cur().pos,{}); return {sp:sp, blocked:D.stepTo('0,0')}; }""")
    ck("an ambush is a fight on one floor at the tile's District and Skull Level", r["sp"]["kind"]=="ambush" and r["sp"]["count"]==1 and r["sp"]["skull"]==1, r["sp"])
    ck("no walking away from a fight", r["blocked"]["moved"] is False, r["blocked"])

    # ================= fights: the Battle Simulator =================
    E("()=>KETER_GO('world')"); pg.wait_for_timeout(300)
    E("()=>{ var s=KETER_DEPLOY.cur(); s.activity.floors=['TEST \u00b7 Waves']; s.activity.skull=3; KETER_DEPLOY._save(s); simDeployFight(KETER_DEPLOY.spec()); }"); pg.wait_for_timeout(500)
    r=E("()=>({view:document.getElementById('v-battle').classList.contains('on'), title:document.querySelector('#modalBox h3').textContent, head:(document.querySelector('.simdephead')||{}).textContent, team:simWiz().heroes})")
    ck("a deployment fight opens the Battle Simulator on who fights and who leads", r["view"] and r["title"]=="Who fights, and who leads" and "Ambush" in (r["head"] or ""), r)
    ck("with the deployment's Strike Team, set up already", r["team"]==["test|Test Warden","test|Test Striker"], r)
    crumbs=E("()=>document.querySelector('#modalBox p[style*=\"letter-spacing\"]').textContent")
    ck("three steps: no choosing a team or Enemies", crumbs.replace(" ","")=="1–2–3", crumbs)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(200); pg.locator("#wizNext").click(); pg.wait_for_timeout(200); pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    r=E("""()=>({dep:SIM.deploy&&SIM.deploy.kind, allies:SIM.units.filter(function(u){ return u.side==='ally'; }).map(function(u){ return u.src; }),
      foes:SIM.units.filter(function(u){ return u.side==='enemy'; }).map(function(u){ return u.skull; }), tiles:simEnemySpawnTiles().map(function(t){ return t.level; }).sort()})""")
    ck("the fight starts with the Heroes, and knows it is a deployment's", r["dep"]=="ambush" and sorted(r["allies"])==["Test Striker","Test Warden"], r)
    ck("Enemies at the tile's Skull Level, a higher spawn mark staying higher", r["tiles"]==[3,4,5,6] and sorted(r["foes"])==[3,4,5,6], r)
    r=E("""()=>{ var a=simFoePool(2,'3').map(function(c){ return (c.affinities&&c.affinities[0]||{}).district+':'+(c.skullLevel||c.level); });
      var b=simFoePool(5,'3').map(function(c){ return String(c.skullLevel||c.level); }); return {a:a, b:b}; }""")
    ck("Enemies from the tile's District at the level wanted", len(r["a"])>0 and all(x.split(":")==["3","2"] for x in r["a"]), r["a"])
    ck("or, with none there, from any District", len(r["b"])>0 and all(x=="5" for x in r["b"]), r["b"])
    html=E("()=>T.win()")
    r=E("()=>{ var s=KETER_DEPLOY.cur(); return {act:s.activity, haul:KETER_LOOT.count(s.haul)+s.haul.shards, fights:s.fights}; }")
    ck("won: the fight's loot goes into the haul, not the stockpile", "Into the haul" in html and r["haul"]>0 and r["act"] is None and r["fights"]==1, html[:200])
    ck("and back to the map", pg.locator("#simDepMap").count()==1)
    pg.locator("#simDepMap").click(); pg.wait_for_timeout(400)
    ck("Back to the map opens the World Map", E("()=>document.getElementById('v-world').classList.contains('on')"))
    ck("the stockpile is untouched while out", E("()=>KETER_LOOT.stock().shards")==0 and E("()=>KETER_LOOT.stock().parts.troop[0]")==20-2*each)

    # ================= a POI =================
    r=E("""()=>{ var k=T.find('poi',3); T.go(k); var sp=KETER_DEPLOY.enterPOI(k); return {k:k, sp:sp}; }""")
    ck("entering a POI at Skull 3: two floors", r["sp"]["kind"]=="poi" and r["sp"]["count"]==2 and r["sp"]["index"]==0 and r["sp"]["skull"]==3, r["sp"])
    poi=r["k"]
    E("()=>T.fight()")
    html=E("()=>T.win()")
    ck("floor 1 cleared: onward, with no way back to the map", "Floor 1 of 2 cleared" in html and pg.locator("#simDepNext").count()==1 and pg.locator("#simDepMap").count()==0, html[-200:])
    pg.locator("#simDepNext").click(); pg.wait_for_timeout(500)
    ck("Next floor sets up the second", E("()=>simWiz().step")=="heroes" and "floor 2 of 2" in (E("()=>(document.querySelector('.simdephead')||{}).textContent") or ""))
    E("()=>{ simWizFinish(); T.close(); }")
    before=E("()=>KETER_DEPLOY.cur().haul.shards")
    html=E("()=>T.win()")
    r=E("(k)=>{ var s=KETER_DEPLOY.cur(); return {act:s.activity, shards:s.haul.shards, cleared:KETER_WORLD.isCleared(k)}; }", poi)
    ck("the last floor: the POI is cleared with its reward", "cleared — its reward" in html and r["act"] is None and r["cleared"] and r["shards"]>=before+30*0.9, r)
    E("()=>T.close()")
    # v13.5: the final reward counts what the last floor has just given. (Everything is put back afterwards.)
    r=E("""()=>{ var W=KETER_WORLD, D=KETER_DEPLOY, P=KETER_PROG, L=KETER_LOOT, m=W.map(), keep={}, out={};
      for(var i=0;i<localStorage.length;i++){ var key=localStorage.key(i); keep[key]=localStorage.getItem(key); }
      var was=JSON.stringify(D.cur());
      function put(){ Object.keys(localStorage).forEach(function(k){ if(!(k in keep)) localStorage.removeItem(k); }); Object.keys(keep).forEach(function(k){ localStorage.setItem(k, keep[k]); }); }
      function run(floorGives){
        put();
        var s=D.cur(), it=['bp:Pierce:1','bp:AoE:1','bp:Burst:1','bp:Marked:1','bp:Sundered:1'].filter(function(x){ return P.eligible(x, s.items); })[0];
        var spot=Object.keys(m.tiles).filter(function(k){ return W.dist(k,m.dock)>=2 && !W.contentAt(k); })[0];
        W.saveUniques([{id:'uq_check', name:'Check Vault', type:'Vault', tile:spot, floors:[], reward:{shards:1, n:0, type:'any', bonus:0, bp:0, items:[{item:it, chance:100}]}}]);
        T.go(spot); var sp=D.enterPOI(spot), res=null, guard=0;
        while(D.cur().activity && guard++<9){ var last=D.cur().activity.index+1>=D.cur().activity.floors.length;
          res=D.fightOver({winner:'ally', haul:L.bag(), reward:L.bag(), items:(last&&floorGives)?[it]:[], heroesDown:[], troopsLost:[], kills:[], consUsed:[]}); }
        var have=D.cur().items.filter(function(x){ return x===it; }).length;
        return {it:it, spot:spot, floors:sp&&sp.count, done:!!(res&&res.poiDone), floorGave:(res&&res.items||[]).indexOf(it)>=0, finalGave:((res&&res.final||{}).items||[]).indexOf(it)>=0, have:have}; }
      out.plain=run(false); out.given=run(true); put();
      out.back=JSON.stringify(D.cur())===was && W.uniques().length===JSON.parse(keep['keter-app-world-unique']||'[]').length;
      return out; }""")
    ck("a Unique POI's own blueprint comes with its final reward", r["plain"]["done"] and r["plain"]["it"] and r["plain"]["spot"] and not r["plain"]["floorGave"] and r["plain"]["finalGave"] and r["plain"]["have"]==1, r["plain"])
    ck("v13.5: and not a second time when its last floor has just left that very blueprint", r["given"]["done"] and r["given"]["spot"] and r["given"]["floorGave"] and not r["given"]["finalGave"] and r["given"]["have"]==1, r["given"])
    ck("(the deployment is as it was before that)", r["back"], r)

    # ================= losing, retrying, the fallen, and a wipe =================
    r=E("""()=>{ var k=T.find('poi',1); T.go(k); KETER_DEPLOY.enterPOI(k); simDeployFight(KETER_DEPLOY.spec());
      var w=simWiz(); w.heroes=['test|Test Warden']; w.leader='test|Test Warden'; simWizFinish(); T.close();
      var h=T.lose(); var s=KETER_DEPLOY.cur(); return {h:h, act:s&&s.activity&&s.activity.kind, out:s&&s.heroesOut, k:k}; }""")
    ck("a Hero who goes down sits out the rest of the deployment", r["out"]==["test|Test Warden"] and "sits out the rest" in r["h"], r)
    ck("a lost fight with a Hero in reserve can be retried", "Retry with reserves" in r["h"] and r["act"]=="poi", r["h"][-160:])
    lostpoi=r["k"]
    pg.locator("#simDepRetry").click(); pg.wait_for_timeout(400)
    ck("Retry sets the same floor up again, with the reserves", E("()=>simWiz().step")=="heroes" and E("()=>simWiz().heroes")==["test|Test Striker"], E("()=>simWiz().heroes"))
    r=E("""()=>{ simWizFinish(); T.close();
      var u=KETER_RULES.unitFromCard({name:'Frame Trooper 2', src:'Frame Trooper', cardType:'troop', stats:{hp:14}},'ally'); u.pos={q:99,r:99}; u.hp=0; u.down=true; SIM.units.push(u);
      var html=T.win(); var s=KETER_DEPLOY.cur(); return {html:html, lost:s.lost, left:KETER_DEPLOY.copiesLeft('ds_starter'), deck:KETER_DEPLOY.deckRefs().length, team:KETER_DEPLOY.team().heroes, act:s.activity}; }""")
    ck("a Troop copy that goes down is gone for the rest of it", r["lost"]=={"ds_starter":1} and r["left"]==3 and r["deck"]==11 and "Copies lost" in r["html"], r)
    ck("won on the retry: the one-floor POI is cleared", r["act"] is None and E("(k)=>KETER_WORLD.isCleared(k)", lostpoi), r)
    ck("and the team fights on with who is left", r["team"]==["test|Test Striker"], r)
    E("()=>T.close()")
    r=E("""()=>{ var s=KETER_DEPLOY.cur();
      s.activity={kind:'ambush', name:'Test', floors:['x'], index:0, district:'3', skull:1, tile:'0,1'}; s.log=[];
      localStorage.setItem(KETER_DEPLOY.KEY, JSON.stringify(s));
      var W=KETER_WORKSHOP, d=W.blank('ch_test_general'); d.name='Spare'; d.abilities[0].text='[[target enemy]] takes [[damage 1]].'; var spare=W.put(d);
      var lost=['Frame Trooper','Frame Trooper','Frame Trooper','Frame Trooper','Frame Trooper','Frame Trooper','Frame Trooper','Test Drone','Spare'];
      KETER_DEPLOY.fightOver({winner:'ally', haul:KETER_LOOT.bag(), reward:KETER_LOOT.bag(), items:[], heroesDown:[], troopsLost:lost, kills:[], consUsed:[]});
      var t=KETER_DEPLOY.cur(), said=t.log.filter(function(l){ return /A copy of/.test(l.text||String(l)); }).length;
      W.remove(spare);
      return {lost:t.lost, left:KETER_DEPLOY.copiesLeft('ds_starter'), said:said, act:t.activity}; }""")
    ck("v13.6: the last copy can be lost, and no more; a Troop of a design the team didn't take costs nothing", r["lost"]=={"ds_starter":4} and r["left"]==0 and r["said"]==3 and r["act"] is None, r)
    r=E("""()=>{ var k=T.find('poi',1); T.go(k); KETER_DEPLOY.enterPOI(k); T.fight(); var haul=KETER_LOOT.norm(KETER_DEPLOY.cur().haul); var h=T.lose();
      return {h:h, haul:haul.shards, active:KETER_DEPLOY.active(), completed:KETER_WORLD.state().completed, stock:KETER_LOOT.stock().shards, last:KETER_DEPLOY.last().result, lock:KETER_DEPLOY.lockedDesign('ds_starter')}; }""")
    ck("with no Hero left, it is a wipe: the haul is lost", "Deployment lost" in r["h"] and r["haul"]>0 and r["stock"]==0 and not r["active"] and r["last"]=="wipe", r)
    ck("the deployment is over, and the locks lift", r["completed"]==1 and not r["lock"], r)
    E("()=>T.close()")

    # ================= caches, Events, the Emergency Exit, coming home =================
    E("""()=>{ KETER_LOOT.resetStock(); KETER_PROG.reset(); var l=JSON.parse(localStorage.getItem('keter-app-loadouts')); l[0].deck=l[0].deck.slice(0,10); localStorage.setItem('keter-app-loadouts',JSON.stringify(l)); KETER_DEPLOY.start(0); }""")
    r=E("""()=>{ var k=T.find('cache',2); T.go(k); KETER_LOOT.seed(5); var c=KETER_DEPLOY.openCache(k); var again=KETER_DEPLOY.openCache(k); var s=KETER_DEPLOY.cur();
      return {shards:c.bag.shards, parts:KETER_LOOT.count(c.bag), again:again, haul:s.haul.shards, cleared:KETER_WORLD.isCleared(k)}; }""")
    ck("a cache: shards and four components into the haul, once (v14.20)", r["parts"]==4 and 6<=r["shards"]<=18 and r["haul"]==r["shards"] and r["again"] is None and r["cleared"], r)
    r=E("""()=>{ var k=T.find('event'); T.go(k); var ev=KETER_DEPLOY.eventAt(k); var i=ev.choices.findIndex(function(c){ return !+c.check; });
      var o=KETER_DEPLOY.choose(k,i); return {title:ev.title, check:o.check, won:o.won, cleared:KETER_WORLD.isCleared(k), again:KETER_DEPLOY.eventAt(k)}; }""")
    ck("an Event: a choice with no check always goes as written, and the tile is done", r["check"]==0 and r["won"] and r["cleared"] and r["again"] is None, r)
    r=E("""()=>{ var W=KETER_WORLD, ev=W.events(); ev[0]={id:'ev_t', title:'Test', text:'x', choices:[{label:'Risk it', check:21, win:{text:'no'}, fail:{text:'Lost some', lose:50, fight:true}}]}; W.saveEvents(ev.slice(0,1));
      var k=T.find('event'); T.go(k); var s0=KETER_DEPLOY.cur().haul.shards; var o=KETER_DEPLOY.choose(k,0); var s=KETER_DEPLOY.cur(); W.resetEvents();
      return {won:o.won, roll:o.roll, lost:o.lost.shards, before:s0, after:s.haul.shards, fight:o.fight, act:s.activity&&s.activity.kind}; }""")
    ck("a failed check: its cost, and its fight", r["won"] is False and 1<=r["roll"]<=20 and r["lost"]==r["before"]//2 and r["after"]==r["before"]-r["lost"] and r["fight"] and r["act"]=="ambush", r)
    E("()=>{ T.fight(); T.win(); T.close(); }")
    # the Emergency Exit
    E("""()=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')); var f=JSON.parse(JSON.stringify(all['TEST · Corridor'])); f.name='Exit Floor'; f.testMap=false; f.district='';
      var id=(f.symDefs||[]).reduce(function(a,d){ return Math.max(a,d.id); },0)+1; f.symDefs=(f.symDefs||[]).concat([{id:id,text:'EX',desc:'Emergency Exit'}]); f.marks=(f.marks||[]).concat([[f.hexes[3][0],id]]);
      all['Exit Floor']=f; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); }""")
    r=E("""()=>{ var k=T.find('poi',5); T.go(k); var sp=KETER_DEPLOY.enterPOI(k); var s=KETER_DEPLOY.cur(); s.activity.floors=['Exit Floor','Exit Floor','Exit Floor']; KETER_DEPLOY._save(s);
      T.fight(); var ex=Object.keys(SIM.map.exits)[0], a=KETER_RULES.hexParse(ex), h=SIM.units.filter(function(u){ return u.side==='ally'; })[0];
      SIM.phase='turn'; SIM.reach=[{q:a.q,r:a.r,cost:1}]; h.moved=0; var before=KETER_DEPLOY.cur().haul.shards; SIM.loot={shards:7, parts:{troop:[1,0,0,0,0,0],equipment:[0,0,0,0,0,0],aether:[0,0,0,0,0,0]}};
      simMoveTo(h,a.q,a.r); var s2=KETER_DEPLOY.cur();
      return {k:k, exits:Object.keys(SIM.map.exits).length, over:SIM.over, result:SIM.result, act:s2.activity, gain:s2.haul.shards-before, cleared:KETER_WORLD.isCleared(k), html:document.getElementById('modal').innerText}; }""")
    ck("a floor's EX symbol is an Emergency Exit", r["exits"]==1, r)
    ck("a Hero reaching it takes the team out, with what the fight had found", r["over"] and r["result"]=="Escaped" and r["act"] is None and r["gain"]==7 and r["cleared"], {k:r[k] for k in r if k!="html"})
    ck("and the POI's final reward is given up", "given up" in r["html"] and "cleared — its reward" not in r["html"], r["html"][:200])
    E("()=>{ T.close(); var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')); delete all['Exit Floor']; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); }")
    # blueprints named when won, kept when home
    r=E("""()=>{ var s=KETER_DEPLOY.cur(); var k=T.find('ambush'); T.go(k); KETER_DEPLOY.ambush(k,{tileAmbush:true}); T.fight();
      var out=KETER_DEPLOY.cur(); /* a blueprint found in the fight */ SIM.found=['bp:Burst:1']; var h=T.win();
      return {named:KETER_PROG.itemName('bp:Burst:1'), owned:KETER_PROG.owned('Burst'), items:KETER_DEPLOY.cur().items, h:h, cleared:KETER_WORLD.isCleared(k)}; }""")
    ck("a blueprint won in a fight is named at once", r["named"]=="Burst L1 (up to 2)" and "Blueprint Burst L1" in r["h"], r)
    ck("but only rides in the haul until home", r["owned"]==0 and r["items"]==["bp:Burst:1"], r)
    ck("an ambush tile beaten is cleared", r["cleared"])
    E("()=>T.close()")
    r=E("""()=>{ var d=KETER_DOCK.state(); d.bounties=[]; KETER_DOCK._save(d); /* verify_dock covers bounties */ var s=KETER_DEPLOY.cur(), haul=KETER_LOOT.norm(s.haul); var no=KETER_DEPLOY.home(); T.go('0,0'); var h=KETER_DEPLOY.home(); var st=KETER_LOOT.stock();
      return {no:no.why, ok:h.ok, shards:st.shards, want:haul.shards, parts:KETER_LOOT.count(st), wantParts:KETER_LOOT.count(haul), burst:KETER_PROG.owned('Burst'), why:KETER_LOOT.history()[0].why,
        active:KETER_DEPLOY.active(), completed:KETER_WORLD.state().completed, comp:Object.keys(KETER_PROG.state().seen.comp).length, hist:KETER_DEPLOY.history()[0].result}; }""")
    ck("coming home only from the dock", r["no"]=="The team has to reach the dock", r)
    ck("home: the haul goes into the stockpile", r["ok"] and r["shards"]==r["want"] and r["parts"]==r["wantParts"] and r["why"]=="Deployment 2 · home", r)
    ck("and blueprints into the Workshop", r["burst"]==1, r)
    ck("the deployment ends, and is remembered", not r["active"] and r["completed"]==2 and r["hist"]=="home" and r["comp"]>0, r)

    # ================= free fights and Auto =================
    r=E("""()=>{ localStorage.setItem('keter-app-simdebug','1'); KETER_GO('battle'); KETER_LOOT.resetStock(); SIM.map=null; SIM.units=[]; simDebugStart('TEST · Waves'); return true; }""")
    pg.wait_for_timeout(1200)
    r=E("""()=>{ SIM.over=false; SIM.loot={shards:9, parts:{troop:[2,0,0,0,0,0],equipment:[0,0,0,0,0,0],aether:[0,0,0,0,0,0]}}; SIM.found=['bp:Chain:1']; SIM.lootResult=null; simFinish({winner:'ally'});
      return {html:document.getElementById('modal').innerText, stock:KETER_LOOT.stock().shards, chain:KETER_PROG.owned('Chain'), dep:!!SIM.deploy}; }""")
    ck("a free fight keeps nothing outside Dev Mode", "Practice fight" in r["html"] and r["stock"]==0 and r["chain"]==0 and not r["dep"], r["html"][:160])
    ck("and does not name what it would have found", "Chain" not in r["html"], r["html"][:200])
    E("()=>{ T.close(); localStorage.setItem('keter-app-dev','1'); SIM.lootResult=null; SIM.over=false; simFinish({winner:'ally'}); }")
    r=E("()=>({stock:KETER_LOOT.stock().shards, chain:KETER_PROG.owned('Chain')})")
    ck("in Dev Mode it keeps its loot, for testing", r["stock"]==9 and r["chain"]==1, r)
    E("()=>{ T.close(); localStorage.removeItem('keter-app-dev'); KETER_LOOT.resetStock(); KETER_PROG.reset(); }")
    E("()=>{ KETER_GO('battle'); SIM.map=null; SIM.units=[]; simDebugStart('TEST · Waves'); }"); pg.wait_for_timeout(1200)
    txt=E("()=>{ T.close(); simRunAuto(); var b=document.getElementById('simAuto'), t=b.textContent; b.click(); return [t, b.textContent]; }")
    ck("while Auto plays, its button says Take over", txt[0]=="Take over" and txt[1].startswith("Taking over"), txt)
    for _ in range(40):
        pg.wait_for_timeout(250)
        if not E("()=>!!SIM.autoRunning"): break
    r=E("()=>({auto:!!SIM.autoRunning, busy:!!SIM.busy, over:!!SIM.over, log:SIM.log.filter(function(l){ return /take over/.test(l.text); }).length})")
    ck("Take over hands the fight back at the start of a round", (not r["auto"]) and (not r["busy"]) and (r["log"]==1 or r["over"]), r)
    ck("and the button is Auto again", pg.locator("#simAuto").inner_text()=="Auto" or r["over"])

    # ================= the World Map page =================
    E("()=>{ localStorage.removeItem('keter-app-simdebug'); KETER_WORLD.newMap(4242); KETER_GO('home'); }"); pg.wait_for_timeout(300)
    t=pg.locator('#launcher [data-page="world"]')
    ck("Home has the World Map", t.count()==1)
    t.click(); pg.wait_for_timeout(500)
    ck("it shows the colony on a canvas", pg.locator("#v-world.on #wldCv").count()==1 and E("()=>document.getElementById('wldCv').width")>300)
    ck("at the dock, with Deploy", "At the dock" in pg.locator("#wldStatus").inner_text() and pg.locator("#wlDeploy").count()==1)
    ck("no Dev Mode tools for a player", pg.locator("#wldDev").inner_text()=="")
    E("()=>KETER_WORLD_UI._tap('0,0')"); pg.wait_for_timeout(100)
    ck("tapping a tile says what it is", "The dock" in pg.locator("#wldPanel").inner_text())
    far=E("()=>{ var W=KETER_WORLD, m=W.map(); return Object.keys(m.tiles).filter(function(k){ return W.dist(k,m.dock)===9 && W.contentAt(k); })[0]; }")
    E("(k)=>KETER_WORLD_UI._tap(k)", far); pg.wait_for_timeout(100)
    tx=pg.locator("#wldPanel").inner_text()
    ck("an unexplored tile: District, Skull Level and ambush chance, but not what it holds", "Skull 3" in tx and "Unknown" in tx and "15% chance of an ambush" in tx, tx)
    pg.locator("#wlDeploy").click(); pg.wait_for_timeout(100)
    pg.locator('[data-wlpick="0"]').click(); pg.wait_for_timeout(100)
    ck("Deploy: the Strike Team's Heroes and copies, and what they cost", "Frame Trooper ×4" in pg.locator("#wldDeploy").inner_text() and "4 free" in pg.locator("#wldDeploy").inner_text())
    pg.locator("#wlGo").click(); pg.wait_for_timeout(300)
    ck("Pay and deploy sets out (a new map starts the count again)", "Deployment 1 " in pg.locator("#wldStatus").inner_text() and E("()=>KETER_DEPLOY.active()"), pg.locator("#wldStatus").inner_text()[:200]+" | "+pg.locator("#wldDeploy").inner_text()[:300])
    E("(k)=>KETER_WORLD_UI._tap(k)", far); pg.wait_for_timeout(100)
    tx=pg.locator("#wldPanel").inner_text()
    ck("a tile further off: how far, and the risk on the way", "steps away" in tx and "chance of at least one ambush on the way" in tx and pg.locator("#wlWalk").count()==1, tx)
    E("()=>{ var t=KETER_WORLD.tables(); t.ambushStep=0; KETER_WORLD.saveTables(t); }")
    pg.locator("#wlWalk").click(); pg.wait_for_timeout(4200)
    r=E("(k)=>({pos:KETER_DEPLOY.cur().pos, walking:KETER_WORLD_UI.state().walking})", far)
    ck("Walk here walks the team there, stopping at anything it holds", r["pos"]==far or (not r["walking"] and E("(k)=>!!KETER_WORLD.contentAt(KETER_DEPLOY.cur().pos)", far)), r)
    E("()=>KETER_WORLD.resetTables()")
    E("()=>{ var s=KETER_DEPLOY.cur(); var k=T.find('cache'); T.go(k); KETER_WORLD_UI._sel(k); }"); pg.wait_for_timeout(100)
    ck("on a cache: Open it", pg.locator("#wlCache").count()==1)
    pg.locator("#wlCache").click(); pg.wait_for_timeout(100)
    ck("and what it held goes into the haul", "Into the haul" in pg.locator("#wldPanel").inner_text() and "The cache holds" in pg.locator("#wldPanel").inner_text())
    E("()=>{ var k=T.find('event'); T.go(k); KETER_WORLD_UI._sel(k); }"); pg.wait_for_timeout(100)
    ck("on an Event: what the team finds, and the choices", pg.locator("[data-wlev]").count()>=2)
    pg.locator("[data-wlev]").last.click(); pg.wait_for_timeout(100)
    ck("a choice made says how it went", len(pg.locator("#wldPanel").inner_text())>40)
    E("()=>{ var k=T.find('poi',3); T.go(k); KETER_WORLD_UI._sel(k); }"); pg.wait_for_timeout(100)
    ck("on a POI: Enter", pg.locator("#wlEnter").count()==1 and "floors, fought in order" in pg.locator("#wldPanel").inner_text())
    pg.locator("#wlEnter").click(); pg.wait_for_timeout(600)
    ck("Enter starts its first fight", E("()=>document.getElementById('v-battle').classList.contains('on')") and E("()=>simWiz().step")=="heroes")
    E("()=>{ T.close(); KETER_GO('world'); }"); pg.wait_for_timeout(300)
    ck("a fight waiting shows on the map", pg.locator("#wlFight").count()==1 and "floor 1 of 2" in pg.locator("#wldPanel").inner_text())
    E("()=>{ KETER_DEPLOY.cur(); var s=KETER_DEPLOY.cur(); s.activity=null; KETER_DEPLOY._save(s); T.go('0,0'); KETER_WORLD_UI._sel('0,0'); }"); pg.wait_for_timeout(100)
    pg.locator("#wlHome").click(); pg.wait_for_timeout(200)
    ck("Come home banks the haul and says so", "Home." in pg.locator("#wldPanel").inner_text() and not E("()=>KETER_DEPLOY.active()"))
    # the Deck Builder and the Workshop while deployed
    E("()=>{ KETER_DEPLOY.start(0); KETER_GO('deck'); }"); pg.wait_for_timeout(300)
    ck("the Deck Builder marks a Strike Team out on a deployment", "Out on a deployment" in pg.locator("#dkbody").inner_text())
    pg.locator('#dkbody [data-lo="0"]').click(); pg.wait_for_timeout(200)
    ck("and shows it locked", "locked until it comes home" in pg.locator("#dkbody").inner_text() and pg.locator("#loName").count()==0)
    E("()=>KETER_GO('workshop')"); pg.wait_for_timeout(300)
    ck("the Workshop marks its designs as out", "Out on a deployment" in pg.locator("#v-workshop").inner_text())
    pg.locator('[data-wsopen="ds_starter"]').click(); pg.wait_for_timeout(200)
    ck("and shows them without letting them change", pg.locator(".wslockbar").count()==1 and pg.locator("#wsName").is_disabled() and pg.locator("#wsCopyThis").count()==1)
    E("()=>{ KETER_DEPLOY.abandon(); }")

    # ================= Dev Mode =================
    E("()=>{ localStorage.setItem('keter-app-dev','1'); KETER_GO('world'); }"); pg.wait_for_timeout(400)
    ck("Dev Mode: the world's tools", pg.locator("#wldDev .wldsec").count()==4)
    pg.locator("#wldDev details").first.evaluate("d=>d.open=true")
    pg.locator("#wlSeed").fill("99"); pg.locator("#wlNew").click(); pg.wait_for_timeout(300)
    ck("a new map from a seed", E("()=>KETER_WORLD.map().seed")==99 and E("()=>KETER_WORLD.state().completed")==0)
    E("()=>{ document.querySelectorAll('#wldDev details').forEach(function(d){ d.open=true; }); }")
    pg.locator("#uqNew").click(); pg.wait_for_timeout(200)
    E("()=>{ document.querySelectorAll('#wldDev details').forEach(function(d){ d.open=true; }); }")
    pg.locator('[data-uq="name"]').fill("The Foundry"); pg.locator('[data-uq="name"]').dispatch_event("change")
    pg.locator("#uqFloor").select_option("TEST · Corridor"); pg.locator("#uqAddFloor").click(); pg.wait_for_timeout(100)
    E("()=>{ document.querySelectorAll('#wldDev details').forEach(function(d){ d.open=true; }); }")
    pg.locator("#uqFloor").select_option("TEST · Waves"); pg.locator("#uqAddFloor").click(); pg.wait_for_timeout(100)
    E("()=>{ document.querySelectorAll('#wldDev details').forEach(function(d){ d.open=true; }); }")
    uid=E("()=>KETER_WORLD.uniques()[0].id")
    pg.locator('[data-uqplace="%s"]'%uid).click(); pg.wait_for_timeout(100)
    ck("placing a Unique POI waits for a tap", "Tap a tile to place" in pg.locator("#wldPanel").inner_text())
    spot=E("()=>{ var W=KETER_WORLD, m=W.map(); return Object.keys(m.tiles).filter(function(k){ return W.dist(k,m.dock)===6; })[0]; }")
    E("(k)=>KETER_WORLD_UI._tap(k)", spot); pg.wait_for_timeout(100)
    r=E("(k)=>{ var c=KETER_WORLD.contentAt(k); return {kind:c.kind, name:c.name, floors:c.unique.floors}; }", spot)
    ck("a Unique POI: its name and floor list, on the tile tapped", r=={"kind":"poi","name":"The Foundry","floors":["TEST · Corridor","TEST · Waves"]}, r)
    r=E("""(k)=>{ KETER_LOOT.resetStock(); var st=KETER_LOOT.stock(); KETER_DEPLOY.start(0); T.go(k); var sp=KETER_DEPLOY.enterPOI(k); var s=KETER_DEPLOY.cur(); var fl=s.activity.floors.slice(); s.activity=null; KETER_DEPLOY._save(s); KETER_DEPLOY.abandon(); return {fl:fl, n:sp.count}; }""", spot)
    ck("entered, it fights its own floors in order", r["fl"]==["TEST · Corridor","TEST · Waves"] and r["n"]==2, r)
    E("()=>{ document.querySelectorAll('#wldDev details').forEach(function(d){ d.open=true; }); }")
    pg.locator('[data-evedit="0"]').click(); pg.wait_for_timeout(100)
    E("()=>{ document.querySelectorAll('#wldDev details').forEach(function(d){ d.open=true; }); }")
    pg.locator('[data-ev="title"]').fill("A new title"); pg.locator('[data-ev="title"]').dispatch_event("change")
    pg.locator('[data-evo="0:win:shards"]').fill("6"); pg.locator('[data-evo="0:win:shards"]').dispatch_event("change")
    r=E("()=>{ var e=KETER_WORLD.events()[0]; return {t:e.title, s:e.choices[0].win.shards}; }")
    ck("an Event rewritten in Dev Mode", r=={"t":"A new title","s":6}, r)
    E("()=>{ document.querySelectorAll('#wldDev details').forEach(function(d){ d.open=true; }); }")
    pg.locator('[data-wt="ambushStep"]').fill("3"); pg.locator('[data-wt="ambushStep"]').dispatch_event("change")
    pg.locator('[data-wt="floorsBySkull.5"]').fill("4"); pg.locator('[data-wt="floorsBySkull.5"]').dispatch_event("change")
    r=E("()=>({a:KETER_WORLD.tables().ambushStep, f:KETER_WORLD.tables().floorsBySkull[5]})")
    ck("and the world's tables", r=={"a":3,"f":4}, r)
    E("()=>{ KETER_WORLD.resetTables(); KETER_WORLD.resetEvents(); }")
    # the Sandbox
    E("()=>{ document.querySelectorAll('#wldDev details').forEach(function(d){ d.open=true; }); }")
    pg.locator("#wlEdit").click(); pg.wait_for_timeout(4500)
    pf=pg.locator('#v-poi iframe').element_handle().content_frame()
    r=pf.evaluate("()=>({name:KETER_POI.S.name, type:KETER_POI.S.poiType, hexes:KETER_POI.S.hexes.size, r:KETER_POI.S.radius})")
    ck("Edit in the Sandbox opens the map there as a World Map level", r["name"]=="World Map" and r["type"]=="World Map" and r["hexes"]>800 and r["r"]==18, r)
    G=pg.frame_locator('#v-poi iframe'); WIN="document.querySelector('#v-poi iframe').contentWindow"
    G.locator('.tool[data-tool="spawnlvl"]').click(); pg.wait_for_timeout(300)
    pg.evaluate("()=>{var a=document.querySelector('#v-poi iframe').contentDocument.querySelector('aside'); if(a) a.classList.add('collapsed');}")
    pg.wait_for_timeout(400)
    def tap(q,r):
        pg.evaluate(f"()=>{WIN}.KETER_POI_TEST.reveal({q},{r})"); pg.wait_for_timeout(150)
        pt=pg.evaluate(f"()=>{WIN}.KETER_POI_TEST.cellClient({q},{r})")
        box=pg.locator('#v-poi iframe').bounding_box()
        pg.mouse.click(box['x']+pt['x'], box['y']+pt['y']); pg.wait_for_timeout(160)
    ok_k=E("()=>{ var W=KETER_WORLD, m=W.map(); return Object.keys(m.tiles).filter(function(k){ return W.dist(k,m.dock)===4 && !m.tiles[k].s; })[0]; }")
    QQ,RR=[int(x) for x in ok_k.split(",")]
    lv=lambda: pg.evaluate(f"()=>{{var T={WIN}.KETER_POI_TEST, h=T.state().hexes.get(T.K({QQ},{RR})); return h?(h.lvl||0):-1;}}")
    start=lv(); tap(QQ,RR); one=lv(); tap(QQ,RR); two=lv()
    for _ in range(5): tap(QQ,RR)
    ck("any World Map tile can take a Skull Level there, a seventh tap clearing it", start==0 and one==1 and two==2 and lv()==0, [start,one,two,lv()])
    tap(QQ,RR); tap(QQ,RR); tap(QQ,RR)
    pf.evaluate("()=>{ var T=KETER_POI_TEST; var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')); all['World Map']=T.snapshot(); localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); }")
    r=E("(k)=>{ KETER_WORLD.useSandbox('World Map'); return {s:KETER_WORLD.skullOf(k), t:KETER_WORLD.tile(k).s}; }", ok_k)
    ck("and the map uses it", r=={"s":3,"t":3}, r)
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nWORLD PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
