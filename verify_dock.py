"""The Dock (v12.9): reach; the Exchange (Commons always, rarer lots up to
reach, blueprints and chassis from Districts fought in and named on the shelf,
Consumables and Prototypes from the Dev list, pre-built Troops cycled three at
a time, selling at half price); restocking only after new ground; Reclaiming
(3 up capped at reach, 2 for 1 swaps); the Bounty Board (met Enemies, claims
paid at home, lost on a wipe); upgrades (starter bay, insurance, scanner,
Exchange stock); the dock closed while a team is out; pre-built copies and
packed Consumables and Prototypes on a deployment; the Dock page, the Deploy
screen's packing, the Workshop's Pre-built tab and the Stockpile's list."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_dock")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9973),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

TEAM="""()=>{ var deck=['design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','test|Test Mortar Strike','test|Test Snare','test|Test Rally','test|Test Plating','test|Test Surge','test|Test Strip'];
  localStorage.setItem('keter-app-loadouts',JSON.stringify([{v:2,name:'Deploy Team',level:1,created:111,heroes:['test|Test Warden','test|Test Striker'],deck:deck,actions:{},pouch:{'basic|3':6}}])); return true; }"""
LIB=r"""()=>{
window.T={
  K:KETER_DOCK, D:KETER_DEPLOY, W:KETER_WORLD, L:KETER_LOOT, P:KETER_PROG, WS:KETER_WORKSHOP,
  cash:function(sh, parts){ var st=KETER_LOOT.stock(); st.shards=sh; if(parts) Object.keys(parts).forEach(function(t){ st.parts[t]=parts[t].slice(); }); KETER_LOOT.setStock(st); return st; },
  go:function(k){ var s=KETER_DEPLOY.cur(); s.pos=k; KETER_DEPLOY._save(s); KETER_WORLD.stand(k); return k; },
  home:function(){ var s=KETER_DEPLOY.cur(); s.pos=KETER_WORLD.map().dock; s.activity=null; KETER_DEPLOY._save(s); return KETER_DEPLOY.home(); },
  fight:function(spec){ simDeployFight(spec||KETER_DEPLOY.spec()); simWizFinish(); document.getElementById('modal').classList.remove('on'); return SIM.units.length; },
  win:function(){ SIM.units.forEach(function(u){ if(u.side==='enemy') u.hp=0; }); simCheckDowns(); SIM.wave=6; SIM.enemyPile=[]; simFinish({winner:'ally'}); return document.getElementById('modal').innerText; },
  lose:function(){ SIM.units.forEach(function(u){ if(u.side==='ally' && /hero/i.test(u.cardType)) u.hp=0; }); simCheckDowns(); simFinish({winner:'enemy'}); return document.getElementById('modal').innerText; },
  close:function(){ document.getElementById('modal').classList.remove('on'); },
  pre:function(name, order){ var W=KETER_WORKSHOP, d=W.blank('ch_test_general'); d.name=name; d.prebuilt=true; d.order=order; d.abilities[0].name='Shot'; d.abilities[0].text='[[target enemy]] takes [[damage 2]].'; return W.put(d); }
}; return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9973/"); pg.wait_for_timeout(1500)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-dev'); localStorage.removeItem('keter-app-sim'); }")
    pg.evaluate(TEAM)
    pg.reload(); pg.wait_for_timeout(1900)
    E=pg.evaluate
    E(LIB)
    E("()=>{ KETER_WORLD.newMap(4242); KETER_LOOT.seed(5); }")

    # ================= the starting dock =================
    r=E("""()=>{ var s=T.K.state(), st=T.K.stock(), t=T.K.tables(); return {reach:s.reach, rr:T.K.reachRarity(), lots:st.lots.length, bps:st.bps.length, items:st.items.length, pre:st.pre.length, b:s.bounties.length,
      price:t.price, up:T.K.UPGRADES.map(function(u){ return u.id; }), lv:T.K.level('starter'), free:T.K.starterFree(), scan:T.K.scanRange(), ins:T.K.insurance(), closed:T.K.closed()}; }""")
    ck("a new dock: no reach, Commons only", r["reach"]==0 and r["rr"]==0 and r["lots"]==0, r)
    ck("nothing else on offer until you've fought somewhere but the shipped pre-built Troops (v14.9: the Skitter Runner and Harrier), and no bounties", r["bps"]==0 and r["items"]==0 and r["pre"]==2 and r["b"]==0, r)
    ck("drafted prices: 6, 15, 40, 100, 250, 600 shards", r["price"]==[6,15,40,100,250,600], r["price"])
    ck("four upgrades, none bought: 4 free starters, sight 1, no insurance", r["up"]==["exchange","starter","insurance","scanner"] and r["lv"]==0 and r["free"]==4 and r["scan"]==1 and r["ins"]==0, r)
    ck("open while nobody is out", r["closed"] is False)

    # ================= Commons, selling =================
    r=E("""()=>{ T.cash(100); var a=T.K.buyParts('troop',0,5), st=T.L.stock(); var no=T.K.buyParts('troop',0,50);
      var sold=T.K.sellParts('troop',0,4), st2=T.L.stock(); var none=T.K.sellParts('aether',0,1); var noLot=T.K.buyParts('troop',1,1,0);
      return {a:a, sh:st.shards, n:st.parts.troop[0], no:no, sold:sold, sh2:st2.shards, n2:st2.parts.troop[0], none:none.ok, noLot:noLot.ok, log:T.L.history()[0].why}; }""")
    ck("Commons in any amount: 5 for 30 shards", r["a"]["ok"] and r["a"]["price"]==30 and r["sh"]==70 and r["n"]==5, r)
    ck("not without the shards", r["no"]["ok"] is False and "Needs 300 shards" in r["no"]["why"], r["no"])
    ck("sold at half price, rounded down: 4 Commons for 12", r["sold"]["gain"]==12 and r["sh2"]==82 and r["n2"]==1 and r["log"]=="Sold at the Exchange", r)
    ck("nothing sold that you don't have, and no rarer parts without a lot", r["none"] is False and r["noLot"] is False, r)

    # ================= reach and rarer lots =================
    r=E("""()=>{ var o=T.K.deploymentEnded({result:'wipe', maxSkull:5}); var a=T.K.state().reach;
      var h=T.K.deploymentEnded({result:'home', maxSkull:3}); var s=T.K.state(); T.L.seed(3); var st=T.K.restock();
      var rs=st.lots.map(function(l){ return l.rarity; }), ns=st.lots.map(function(l){ return l.n; });
      var lower=T.K.deploymentEnded({result:'home', maxSkull:1});
      return {wipe:a, reach:s.reach, out:h.reach, rr:T.K.reachRarity(), lots:st.lots.length, rs:rs, ns:ns, lower:T.K.state().reach, lowOut:lower.reach||null}; }""")
    ck("a wipe doesn't extend reach", r["wipe"]==0, r)
    ck("coming home from Skull 3 does: Rare at most", r["reach"]==3 and r["out"]==3 and r["rr"]==2, r)
    ck("three lots of rarer parts, Uncommon or Rare, 1 to 3 in each", r["lots"]==3 and all(1<=x<=2 for x in r["rs"]) and all(1<=n<=3 for n in r["ns"]), r)
    ck("a shallower trip leaves reach where it was", r["lower"]==3 and r["lowOut"] is None, r)
    r=E("""()=>{ var st=T.K.stock(), lot=st.lots[0]; lot.n=2; var s=T.K.state(); s.stock.lots[0].n=2; T.K._save(s); T.cash(1000);
      var a=T.K.buyParts(lot.type,lot.rarity,1,0), b=T.K.buyParts(lot.type,lot.rarity,2,0), c=T.K.buyParts(lot.type,lot.rarity,1,0), d=T.K.buyParts(lot.type,lot.rarity,1,0);
      var wrong=T.K.buyParts(lot.type==='troop'?'aether':'troop',lot.rarity,1,0);
      return {a:a.ok, pa:a.price, b:b.why, c:c.ok, d:d.why, bought:T.K.stock().lots[0].bought, have:T.L.stock().parts[lot.type][lot.rarity], wrong:wrong.why, r:lot.rarity}; }""")
    ck("a lot sells what it holds, at its rarity's price", r["a"] and r["pa"]==[6,15,40][r["r"]] and r["c"] and r["bought"]==2 and r["have"]>=2, r)
    ck("and no more", r["b"]=="Only 1 left in that lot" and r["d"]=="Only 0 left in that lot", r)
    ck("only what the lot is", r["wrong"]=="Not in stock", r)

    # ================= Reclaiming =================
    r=E("""()=>{ T.cash(0,{troop:[7,3,0,0,0,0], equipment:[0,0,0,0,0,0], aether:[0,5,0,0,0,0]}); var a=T.K.combine('troop',0,2), st=T.L.stock();
      var b=T.K.combine('troop',1,1), st2=T.L.stock(); var c=T.K.combine('troop',2,1); var few=T.K.combine('troop',0,1);
      var w=T.K.swap('aether','equipment',1,2), st3=T.L.stock(); var same=T.K.swap('aether','aether',1,1), wmany=T.K.swap('aether','troop',1,1);
      return {a:a, t:st.parts.troop.slice(0,3), b:b, t2:st2.parts.troop.slice(0,3), c:c.why, few:few.why, w:w, e:st3.parts.equipment[1], ae:st3.parts.aether[1], same:same.why, wmany:wmany.why}; }""")
    ck("combine: 3 Commons make 1 Uncommon, twice over", r["a"]=={"ok":True,"made":2} and r["t"][0]==1 and r["t"][1]==5, r)
    ck("up to your reach: Uncommon to Rare at Skull 3", r["b"]["ok"] and r["t2"][1]==2 and r["t2"][2]==1, r)
    ck("but never past it", "Nothing rarer than your reach" in r["c"], r["c"])
    ck("and only with enough", r["few"]=="Needs 3 of them", r)
    ck("swap: 2 of one type make 1 of another, same rarity", r["w"]["made"]==2 and r["e"]==2 and r["ae"]==1, r)
    ck("to another type, with enough", r["same"]=="Pick another type" and r["wmany"]=="Needs 2 of them", r)
    r=E("""()=>{ var s=T.K.state(); s.reach=0; T.K._save(s); T.cash(0,{troop:[9,0,0,0,0,0]}); return T.K.combine('troop',0,1).why; }""")
    ck("with no reach, nothing combines", "Nothing rarer than your reach" in r, r)
    E("()=>{ var s=T.K.state(); s.reach=3; T.K._save(s); }")

    # ================= blueprints and chassis =================
    r=E("""()=>{ T.P.reset(); T.P.see('district','3'); T.L.seed(7); var st=T.K.restock(); var pool=T.P.poolItems('3');
      var all=st.bps.concat(st.chs), inPool=all.every(function(it){ return pool.indexOf(it)>=0; }), elig=all.every(function(it){ return T.P.eligible(it); });
      var namedBefore=Object.keys(T.P.state().named).length; T.K.seeStock(); var named=T.P.state().named;
      return {bps:st.bps, chs:st.chs, inPool:inPool, elig:elig, nb:namedBefore, named:Object.keys(named), pool:pool.length}; }""")
    ck("blueprints and a chassis from the pools of Districts fought in", len(r["bps"])==2 and len(r["chs"])<=1 and r["inPool"], r)
    ck("only what could come next", r["elig"] and all(x.endswith(":1") for x in r["bps"]), r["bps"])
    ck("seeing one on the shelf names it", r["nb"]==0 and len(r["named"])==len(r["bps"])+len(r["chs"]), r)
    r=E("""()=>{ var st=T.K.stock(), it=st.bps[0], nm=T.P.parseItem(it).name; T.cash(100); var no=T.K.buyItem(it); T.cash(500);
      var a=T.K.buyItem(it), again=T.K.buyItem(it), sh=T.L.stock().shards;
      var p2=T.K.bpPrice('bp:'+nm+':2'), p3=T.K.bpPrice('bp:'+nm+':3'), rp=T.P.researchPrice(nm,2), ch=T.K.bpPrice('ch:x'), not=T.K.buyItem('bp:Nothing:1');
      return {no:no.why, a:a, own:T.P.owned(nm), sold:T.K.stock().sold[it], again:again.why, sh:sh, p2:p2, p3:p3, rp:rp, ch:ch, not:not.why, log:T.L.history()[0].why}; }""")
    ck("an unfound blueprint costs 150 shards", "Needs 150 shards" in r["no"] and r["a"]=={"ok":True,"price":150} and r["sh"]==350, r)
    ck("bought, it's yours at once, and sold from the shelf", r["own"]==1 and r["sold"]==1 and "Bought" in r["log"], r)
    ck("a shelf item sells once", r["again"]=="You can't use that one yet", r)
    ck("later levels: research × 1.25 (75 and 150); a chassis 300", r["rp"]==60 and r["p2"]==75 and r["p3"]==150 and r["ch"]==300, r)
    ck("only what's on the shelf", r["not"]=="Not in stock", r)
    r=E("""()=>{ var s=T.K.state(); var ch=T.P.chassisList().filter(function(c){ return c.id!=='ch_test_general'; })[0]; if(!ch) return {none:true};
      s.stock.chs=['ch:'+ch.id]; T.K._save(s); T.cash(400); var a=T.K.buyItem('ch:'+ch.id); return {a:a, has:T.P.hasChassis(ch.id), sh:T.L.stock().shards}; }""")
    ck("a chassis bought is yours", r.get("none") or (r["a"]["ok"] and r["has"] and r["sh"]==100), r)

    # ================= Consumables and Prototypes =================
    r=E("""()=>{ var t=T.K.tables(); t.items=[{name:'Test Stim',price:20},{name:'Test Aegis Core',price:80},{name:'Field Dressing',price:12},{name:'Ledger Core',price:90}]; T.K.saveTables(t);
      var st=T.K.restock(), a=st.items.slice(); var st2=T.K.restock(), b=st2.items.slice();
      return {a:a, b:b, saved:JSON.parse(localStorage.getItem(T.K.TAB_KEY)).items.length}; }""")
    ck("the Exchange carries the Dev list, three at a time", r["a"]==["Test Stim","Test Aegis Core","Field Dressing"] and r["saved"]==4, r)
    ck("and cycles on to the next three at a restock", r["b"]==["Ledger Core","Test Stim","Test Aegis Core"], r["b"])
    r=E("""()=>{ T.cash(200); var a=T.K.buyCard('Test Stim',3), b=T.K.buyCard('Test Aegis Core',1), no=T.K.buyCard('Field Dressing',1);
      var sold=T.K.sellCard('Test Stim',1), sh=T.L.stock().shards, many=T.K.sellCard('Test Stim',9);
      return {a:a, b:b, no:no.why, stim:T.K.owned('Test Stim'), aegis:T.K.owned('Test Aegis Core'), kind:[T.K.itemKind('Test Stim'),T.K.itemKind('Test Aegis Core')], sold:sold.gain, sh:sh, many:many.why}; }""")
    ck("bought by the copy and owned: 3 Stims for 60, an Aegis Core for 80", r["a"]["price"]==60 and r["b"]["price"]==80 and r["stim"]==2 and r["aegis"]==1, r)
    ck("only what's on offer now", r["no"]=="Not in stock", r)
    ck("sold back at half price", r["sold"]==10 and r["sh"]==70 and r["many"]=="You don't have that many", r)
    ck("a Consumable and a Prototype", r["kind"]==["consumable","prototype"], r["kind"])

    # ================= pre-built Troops =================
    r=E("""()=>{ var ids=[T.pre('Pre Alpha',1),T.pre('Pre Beta',2),T.pre('Pre Gamma',3),T.pre('Pre Delta',4)];
      var list=T.WS.list().map(function(d){ return d.name; }), pb=T.WS.prebuilts().map(function(d){ return d.name; }), cards=T.WS.prebuiltCards().map(function(c){ return c._src; });
      var comp=T.WS.cards().filter(function(c){ return /^Pre /.test(c.name); }).length;
      var st=T.K.restock(), a=st.pre.map(function(id){ return T.WS.get(id).name; }); var b=T.K.restock().pre.map(function(id){ return T.WS.get(id).name; });
      var d=T.WS.get(ids[0]), parts=T.WS.cost(d).parts, sum=0; parts.forEach(function(n,r){ sum+=n*[6,15,40,100,250,600][r]; });
      return {ids:ids, list:list.filter(function(n){ return /^Pre /.test(n); }), pb:pb, cards:cards, comp:comp, a:a, b:b, cost:T.K.preCost(d), want:Math.round(sum*1.5), chk:T.WS.check(d).ok}; }""")
    ck("pre-builts aren't your designs, and aren't in the Compendium's", r["list"]==[] and r["comp"]==0 and r["pb"]==["Pre Alpha","Pre Beta","Pre Gamma","Pre Delta","Skitter Runner Mk I","Skitter Harrier Mk I"] and set(r["cards"])=={"prebuilt"}, r)
    # (v14.9: the two shipped ones were on offer first, so the turn has moved on two)
    ck("three on offer, in order, then the next three", r["a"]==["Pre Gamma","Pre Delta","Skitter Runner Mk I"] and r["b"]==["Skitter Harrier Mk I","Pre Alpha","Pre Beta"], r)
    ck("a copy costs 1.5 × its parts at the Exchange's prices", r["cost"]==r["want"] and r["cost"]>0, r)
    PRE=r["ids"]
    r=E("""(ids)=>{ var s=T.K.state(); s.stock.pre=[ids[0],ids[1],ids[2]]; T.K._save(s); var c=T.K.preCost(T.WS.get(ids[0]));
      T.cash(c*5); var a=T.K.buyPre(ids[0],3), b=T.K.buyPre(ids[0],2), no=T.K.buyPre(ids[0],1), gone=T.K.buyPre(ids[3],1);
      return {a:a.ok, b:b.ok, no:no.ok, gone:gone.why, wait:T.K.waiting()[ids[0]], sh:T.L.stock().shards}; }""", PRE)
    ck("as many copies as you can afford: the shelf never runs out", r["a"] and r["b"] and r["no"] is False and r["wait"]==5 and r["sh"]==0, r)
    ck("only those on offer", r["gone"]=="Not in stock", r)
    r=E("""()=>{ var p=T.P.state(); delete p.ch.ch_test_lazarus; T.P.save(p); var W=T.WS, d=W.blank('ch_test_lazarus'); d.name='Pre Lazarus'; d.prebuilt=true; d.order=99; d.abilities[0].text='[[target enemy]] takes [[damage 2]] [[Burst 4]].';
      var mine=W.blank('ch_test_lazarus'); mine.abilities[0].text=d.abilities[0].text; var c=W.check(d), m=W.check(mine);
      d.abilities[0].text='[[target enemy]] takes [[damage 2]] [[Burst 9]].'; var over=W.check(d);
      return {ok:c.ok, why:c.reasons, mine:m.ok, over:over.ok, has:T.P.hasChassis('ch_test_lazarus'), burst:T.P.owned('Burst')}; }""")
    ck("a pre-built can use a chassis and keywords you haven't found", r["ok"] is True and r["mine"] is False and r["has"] is False and r["burst"]<3, r)
    ck("but not past a keyword's top level", r["over"] is False, r)

    # ================= deploying with pre-built copies and a pack =================
    r=E("""()=>{ T.cash(0,{troop:[40,0,0,0,0,0]}); var a=T.D.plan(0,{'Test Stim':5}), b=T.D.plan(0,{'Test Stim':1,'Test Aegis Core':1});
      return {a:a.reasons, aok:a.ok, pre:b.pre, packed:b.packed, ok:b.ok}; }""")
    ck("packing only what you own", r["aok"] is False and r["a"]==["only 2 Test Stim to pack"], r)
    ck("the plan shows the pre-built copies going and what's packed", r["pre"]==[{"id":PRE[0],"name":"Pre Alpha","copies":5}] and sorted(x["name"] for x in r["packed"])==["Test Aegis Core","Test Stim"] and r["ok"], r)
    r=E("""()=>{ T.W.resetState(); var k0=T.W.knownCount(); var s=T.D.start(0,{'Test Stim':1,'Test Aegis Core':1}); var cur=T.D.cur(), deck=T.D.deckRefs();
      return {ok:s.ok, pre:cur.pre, pack:cur.pack, inv:T.K.inv(), deck:deck.filter(function(r){ return /^prebuilt\|/.test(r); }).length, len:deck.length, team:T.D.team().pack, left:T.D.copiesLeft(Object.keys(cur.pre)[0]), k0:cur.known0}; }""")
    ck("deploying takes the pre-built copies from the dock", r["ok"] and list(r["pre"].values())==[5] and r["inv"]["pre"]=={} , r)
    ck("and the packed items: one Stim left at the dock, the Aegis Core gone with the team", r["inv"]["cards"]=={"Test Stim":1} and r["pack"]=={"cons":{"Test Stim":1},"protos":{"Test Aegis Core":1}}, r)
    ck("the copies ride on top of the Deck", r["deck"]==5 and r["len"]==15 and r["left"]==5, r)
    ck("the fight's team carries the pack", r["team"]==r["pack"], r)

    # ================= closed while out =================
    r=E("""()=>{ T.cash(999,{troop:[40,10,0,0,0,0]}); var out={buy:T.K.buyParts('troop',0,1).why, sell:T.K.sellParts('troop',0,1).why, card:T.K.buyCard('Test Stim',1).why, pre:T.K.buyPre('x',1).why,
      up:T.K.upgrade('starter').why, comb:T.K.combine('troop',0,1).why, swap:T.K.swap('troop','aether',0,1).why, item:T.K.buyItem('bp:x:1').why};
      var p=T.P.state(); p.bp.Burst=1; T.P.save(p); out.research=T.P.research('Burst'); return out; }""")
    ck("the dock is closed while the team is out", all(v=="The dock is closed while a Strike Team is out" for k,v in r.items() if k!="research"), r)
    ck("and so is research", r["research"]["ok"] is False, r["research"])
    E("()=>KETER_GO('dock')"); pg.wait_for_timeout(300)
    tx=E("()=>document.getElementById('v-dock').innerText")
    ck("the Dock page says so", "closed while a Strike Team is out" in tx and E("()=>document.querySelectorAll('#v-dock [data-dkbuyc][disabled]').length")==3, tx[:300])

    # ================= a fight: the pack, pre-builts and kills =================
    E("()=>KETER_GO('world')"); pg.wait_for_timeout(300)
    r=E("""()=>{ var W=T.W, m=W.map(), k=W.neighbours(m.dock).filter(W.isOpen)[0]; T.go(k); var sp=T.D.ambush(k,{}); var s=T.D.cur(); s.activity.floors=['TEST · Waves']; T.D._save(s);
      simDeployFight(T.D.spec()); var wz=simWiz(); return {protos:wz.protos.slice(), cons:JSON.parse(JSON.stringify(wz.cons))}; }""")
    pg.wait_for_timeout(300)
    ck("a deployment fight brings every packed Prototype and the packed Consumables", r["protos"]==["Test Aegis Core"] and r["cons"]=={"Test Stim":1}, r)
    r=E("""()=>{ simWiz().step='summary'; simWizRender(); var b=document.querySelector('#modalBox [data-wizsub="cons"]'); if(!b) return 'no button: '+document.getElementById('modalBox').innerText; b.click(); return document.getElementById('modalBox').innerText; }""")
    ck("the setup offers only what's packed", "Test Stim" in r and "Test Smoke" not in r and "Test Sandbags" not in r, r[:400])
    r=E("""()=>{ simWizFinish(); T.close(); var pre=SIM.units.filter(function(u){ return u.side==='ally'; }).length; var names=SIM.units.filter(function(u){ return u.side==='enemy'; }).map(function(u){ return u.src||u.name; });
      var cons=(SIM.hand||[]).concat(SIM.consumables||[]); T.win(); var s=T.D.cur(); return {kills:s.kills, names:names, pack:s.pack}; }""")
    ck("a won fight records who fell, and the Skull Level each fell at", len(r["kills"])==len(r["names"]) and all(k["skull"]>=1 for k in r["kills"]) and sorted(k["name"] for k in r["kills"])==sorted(r["names"]), r)
    E("()=>T.close()")
    r=E("""()=>{ var s=T.D.cur(); s.activity={kind:'ambush', name:'Ambush', floors:['TEST · Waves'], index:0, skull:2, district:'3'}; T.D._save(s);
      var o=T.D.fightOver({winner:'ally', haul:T.L.bag(), heroesDown:[], troopsLost:['Pre Alpha','Pre Alpha'], consUsed:['Test Stim'], kills:[{name:'Boss X', skull:2}]}); var c=T.D.cur();
      return {lost:c.lost, left:T.D.copiesLeft(Object.keys(c.pre)[0]), pack:c.pack, deck:T.D.deckRefs().filter(function(r){ return /^prebuilt/.test(r); }).length, kills:c.kills.length}; }""")
    ck("pre-built copies lost are gone for the deployment", r["left"]==3 and r["deck"]==3, r)
    ck("a Consumable used is used up", r["pack"]=={"cons":{},"protos":{"Test Aegis Core":1}}, r["pack"])

    # ================= bounties, home =================
    r=E("""()=>{ var s=T.K.state(); var k=T.D.cur().kills.slice().sort(function(a,b){ return a.skull-b.skull; }); s.bounties=[{name:k[0].name, kind:'enemy', district:'3', claimed:false},{name:'Boss X', kind:'boss', district:'3', claimed:false},{name:'Nobody', kind:'elite', district:'3', claimed:false}]; T.K._save(s);
      T.cash(0,{troop:[0,0,0,0,0,0],equipment:[0,0,0,0,0,0],aether:[0,0,0,0,0,0]}); var h=T.home(); var st=T.L.stock(), bs=T.K.bounties();
      return {ok:h.ok, dock:h.dock, bs:bs, sh:st.shards, k0:k[0].name, k0s:k[0].skull, parts:T.L.count(st), inv:T.K.inv(), haul:h.haul.shards, pre:T.D.last().pre}; }""")
    pd=r["dock"]["bounties"]
    ck("coming home pays the bounties matched", r["ok"] and [x["name"] for x in pd]==[r["k0"],"Boss X"], r["dock"])
    ck("by kind and Skull Level: an Enemy at its Skull Level, a Boss at 2 pays 240, each with components", pd[0]["bag"]["shards"]==15*r["k0s"] and pd[1]["bag"]["shards"]==240 and r["sh"]==15*r["k0s"]+240+r["haul"] and r["parts"]>=6, r)
    ck("the unused pack goes back to the dock: the Prototype and the other Stim", r["inv"]["cards"]=={"Test Stim":1,"Test Aegis Core":1}, r["inv"])
    ck("pre-built copies don't come back", r["inv"]["pre"]=={}, r["inv"])
    ck("new ground revealed: the Exchange restocks", r["dock"].get("restocked") is True, r["dock"])
    r=E("()=>{ var p=T.D.plan(0); return {pre:p.pre}; }")
    ck("the next deployment has no pre-built copies", r["pre"]==[], r)

    # ================= restock only after new ground =================
    r=E("""()=>{ var n0=T.K.stock().n; T.D.start(0); var h=T.home(); var n1=T.K.stock().n;
      T.D.start(0); var W=T.W, far=Object.keys(W.map().tiles).filter(function(k){ return W.dist(k,W.map().dock)===4 && W.isOpen(k) && !W.known(k); })[0]; T.go(far); var h2=T.home();
      return {n0:n0, n1:n1, r1:!!h.dock.restocked, n2:T.K.stock().n, r2:!!h2.dock.restocked}; }""")
    ck("a deployment that saw nothing new doesn't restock", r["n1"]==r["n0"] and not r["r1"], r)
    ck("one that did, does", r["n2"]==r["n0"]+1 and r["r2"], r)
    r=E("""()=>{ var n0=T.K.stock().n; T.D.start(0); var W=T.W, far=Object.keys(W.map().tiles).filter(function(k){ return W.dist(k,W.map().dock)===7 && W.isOpen(k) && !W.known(k); })[0]; T.go(far);
      var w=T.D.wipe(); return {n0:n0, n:T.K.stock().n, r:!!w.dock.restocked}; }""")
    ck("a wipe that explored restocks too", r["n"]==r["n0"]+1 and r["r"], r)

    # ================= the Bounty Board posts met Enemies =================
    r=E("""()=>{ var foes=KETER_ALLCARDS().filter(function(c){ return T.P.isFoe(c) && T.P.enemyDistrict(c)==='3'; }), p=T.P.state();
      var small=foes.filter(function(c){ return c.cardType==='enemy'; }).slice(0,3), big=foes.filter(function(c){ return c.cardType!=='enemy'; }).slice(0,1);
      var other=KETER_ALLCARDS().filter(function(c){ return T.P.isFoe(c) && T.P.enemyDistrict(c) && T.P.enemyDistrict(c)!=='3' && c.cardType==='enemy'; })[0];
      small.concat(big).concat(other?[other]:[]).forEach(function(c){ p.seen.enemy[c.name]=1; }); T.P.save(p);
      var bs=T.K.postBounties(); return {bs:bs, big:big.map(function(c){ return c.cardType; }), other:other&&other.name, kinds:bs.map(function(b){ return b.kind; })}; }""")
    ck("two Enemies and one Elite, Mini-Boss or Boss", len(r["bs"])==3 and r["kinds"][:2]==["enemy","enemy"] and r["kinds"][2] in ("elite","miniboss","boss"), r)
    ck("only ones you've met, from Districts fought in (or of no District)", all(b["district"] in ("3","") for b in r["bs"]) and r["other"] not in [b["name"] for b in r["bs"]], r)
    r=E("""()=>{ var s=T.K.state(); s.bounties=[{name:'Wiped Foe', kind:'enemy', district:'3', claimed:false}]; T.K._save(s); T.D.start(0);
      var c=T.D.cur(); c.kills=[{name:'Wiped Foe', skull:2}]; T.D._save(c); T.D.wipe(); return T.K.bounties()[0].claimed; }""")
    ck("a wipe loses the claim", r is False, r)

    # ================= upgrades =================
    r=E("""()=>{ T.cash(140,{troop:[20,0,0,0,0,0], equipment:[20,6,3,0,0,0], aether:[20,0,0,0,0,0]}); var no=T.K.upgrade('starter'); T.cash(2000);
      var a=T.K.upgrade('starter'), st=T.L.stock(), free=T.K.starterFree(); var pl=T.D.plan(0);
      var sc=[T.K.upgrade('scanner'),T.K.upgrade('scanner'),T.K.upgrade('scanner'),T.K.upgrade('scanner')];
      return {no:no.why, a:a, sh:st.shards, tc:st.parts.troop[0], free:free, pfree:pl.lines[0].free, sc:sc.map(function(x){ return x.ok; }), max:sc[3].why, scan:T.K.scanRange(), eq:T.L.stock().parts.equipment.slice(0,3)}; }""")
    ck("an upgrade needs its shards and parts", r["no"]=="Needs 150 shards and 10 Common troop parts", r)
    ck("Starter bay 1: 6 free starter copies", r["a"]=={"ok":True,"level":1} and r["sh"]==1850 and r["tc"]==10 and r["free"]==6, r)
    ck("a Strike Team with 4 starters still gets all 4 free", r["pfree"]==4, r)
    ck("three levels each: the scanner to 4 steps, paid in Equipment parts", r["sc"]==[True,True,True,False] and r["max"]=="Already at its highest level" and r["scan"]==4 and r["eq"]==[10,0,0], r)
    r=E("""()=>{ var W=T.W; W.resetState(); var m=W.map(), k=Object.keys(m.tiles).filter(function(x){ return W.dist(x,m.dock)===9 && W.isOpen(x); })[0]; W.stand(k);
      var ring=function(d){ return Object.keys(m.tiles).filter(function(x){ return W.dist(x,k)===d; }); };
      var r4=ring(4), r5=ring(5); var out={k4:r4.filter(W.known).length, n4:r4.length, k5:r5.filter(W.known).length};
      var s=T.K.state(); s.upgrades.scanner=0; T.K._save(s); W.resetState(); W.stand(k); out.k2=ring(2).filter(W.known).length; out.k1=ring(1).filter(W.known).length; out.n1=ring(1).length;
      s.upgrades.scanner=3; T.K._save(s); W.resetState(); return out; }""")
    ck("the scanner at level 3 sees what open tiles hold 4 steps away", r["k4"]==r["n4"] and r["k5"]==0, r)
    ck("without it, one step", r["k2"]==0 and r["k1"]==r["n1"], r)
    r=E("""()=>{ T.cash(2000,{troop:[20,0,0,0,0,0], equipment:[20,6,3,0,0,0], aether:[20,6,3,0,0,0]}); T.K.upgrade('insurance'); T.K.upgrade('insurance');
      var stim=T.K.owned('Test Stim'), burst=T.P.owned('Burst'); T.D.start(0,{'Test Stim':1}); var c=T.D.cur(); var b=T.L.bag(); b.shards=100; b.parts.troop[0]=10; b.parts.aether[2]=4; c.haul=b; c.items=['bp:Burst:1']; T.D._save(c);
      var W=T.W, k=W.neighbours(W.map().dock).filter(W.isOpen)[0]; T.go(k); T.D.ambush(k,{}); c=T.D.cur(); c.activity.floors=['TEST \u00b7 Waves']; T.D._save(c);
      T.cash(0,{troop:[0,0,0,0,0,0], equipment:[0,0,0,0,0,0], aether:[0,0,0,0,0,0]}); T.fight(); var h=T.lose(); var st=T.L.stock(); T.close();
      return {ins:T.K.insurance(), active:T.D.active(), h:h, sh:st.shards, t:st.parts.troop[0], a:st.parts.aether[2], burst:T.P.owned('Burst'), burst0:burst, stim0:stim, stim:T.K.owned('Test Stim')}; }""")
    ck("a wipe with Salvage insurance 2 keeps 20% of the haul's shards and parts", r["ins"]==20 and not r["active"] and r["sh"]==20 and r["t"]==2 and r["a"]==0, r)
    ck("but not its blueprints, nor anything packed", r["burst"]==r["burst0"] and r["stim"]==r["stim0"]-1, r)
    ck("the wipe's report says what was packed and what insurance kept", "Test Stim" in r["h"] and "Salvage insurance" in r["h"], r["h"][:400])
    r=E("""()=>{ var before=T.K.stock().lots.length; T.cash(2000,{equipment:[20,6,3,0,0,0]}); var s=T.K.state(); s.upgrades.exchange=0; T.K._save(s); T.K.upgrade('exchange');
      var st=T.K.restock(); return {lots:st.lots.length, pre:st.pre.length}; }""")
    ck("Exchange stock 1: one more lot and one more pre-built on offer", r["lots"]==4 and r["pre"]==4, r)

    # ================= the Dock page =================
    E("()=>{ var s=T.K.state(); s.upgrades={exchange:0,starter:0,insurance:0,scanner:0}; T.K._save(s); T.cash(300,{troop:[6,0,0,0,0,0],equipment:[0,0,0,0,0,0],aether:[0,0,0,0,0,0]}); KETER_GO('home'); }")
    pg.wait_for_timeout(300)
    ck("Dock is on Home", pg.locator('.lt[data-page="dock"]').count()==1)
    pg.locator('.lt[data-page="dock"]').click(); pg.wait_for_timeout(400)
    tx=E("()=>document.getElementById('v-dock').innerText")
    ck("the Dock page: shards, components and reach", "300 shards" in tx and "reach: Skull 3" in tx, tx[:300])
    ck("the Exchange tab: Commons, lots, blueprints, Consumables, pre-builts, selling", all(x in tx.upper() for x in ["COMPONENTS","BLUEPRINTS AND CHASSIS","CONSUMABLES AND PROTOTYPES","PRE-BUILT TROOPS","SELL"]) and "any amount" in tx, tx[:600])
    pg.locator('[data-dkq="c:troop"]').fill("4"); pg.locator('[data-dkq="c:troop"]').dispatch_event("input")
    pg.locator('[data-dkbuyc="troop"]').click(); pg.wait_for_timeout(200)
    r=E("()=>({msg:KETER_DOCK_UI.state().msg, sh:KETER_LOOT.stock().shards, n:KETER_LOOT.stock().parts.troop[0]})")
    ck("buying from the page, by the amount typed", "Bought 4" in r["msg"] and r["sh"]==276 and r["n"]==10, r)
    n_pre=E("()=>document.querySelectorAll('#v-dock [data-dkbuypre]').length")
    ck("pre-builts on the shelf with their abilities", n_pre>=3 and "Shot" in E("()=>document.getElementById('v-dock').innerText"), n_pre)
    pg.locator('[data-dktab="reclaim"]').click(); pg.wait_for_timeout(200)
    ck("the Reclaim tab offers what can combine", pg.locator('[data-dkup="troop:0"]').count()==1)
    pg.locator('[data-dkup="troop:0"]').click(); pg.wait_for_timeout(200)
    ck("and combines it", E("()=>KETER_LOOT.stock().parts.troop[1]")==1 and "Made 1" in E("()=>KETER_DOCK_UI.state().msg"))
    pg.locator('[data-dktab="bounties"]').click(); pg.wait_for_timeout(200)
    tx=E("()=>document.getElementById('dkBody').innerText")
    ck("the Bounties tab: each posted, and what it pays", "per Skull Level it fell at" in tx, tx[:300])
    pg.locator('[data-dktab="upgrades"]').click(); pg.wait_for_timeout(200)
    tx=E("()=>document.getElementById('dkBody').innerText")
    ck("the Upgrades tab: level, now and next, and the cost", "Starter bay · level 0 of 3" in tx and "Now: 4 free starter copies" in tx and "Costs 150 shards and 10 Common Troop parts" in tx, tx[:400])
    ck("no Dev tools for a player", pg.locator("#dkRestock").count()==0)

    # ================= Dev Mode =================
    E("()=>{ localStorage.setItem('keter-app-dev','1'); KETER_DOCK_UI.render(); }"); pg.wait_for_timeout(200)
    ck("Dev Mode: restock, reach and reset", pg.locator("#dkRestock").count()==1 and pg.locator("#dkReach").count()==1)
    ck("the Exchange's list: every Consumable and Prototype, ticked if carried", E("()=>document.querySelectorAll('[data-dkitem]').length")>=20 and E("()=>document.querySelector('[data-dkitem=\"Test Stim\"]').checked"))
    pg.locator('[data-dkitem="Repair Kit"]').dispatch_event("click"); pg.wait_for_timeout(200)
    pg.evaluate("()=>{ var el=document.querySelector('[data-dkitem=\"Repair Kit\"]'); if(!el.checked){ el.checked=true; } el.dispatchEvent(new Event('change',{bubbles:true})); }"); pg.wait_for_timeout(200)
    r=E("()=>KETER_DOCK.tables().items.map(function(x){ return x.name+':'+x.price; })")
    ck("ticking one adds it at a starting price", "Repair Kit:20" in r, r)
    E("()=>{ var el=document.querySelector('[data-dkiprice=\"Repair Kit\"]'); el.value='33'; el.dispatchEvent(new Event('change',{bubbles:true})); }")
    E("()=>{ var el=document.querySelector('[data-dkt=\"price.2\"]'); el.value='45'; el.dispatchEvent(new Event('change',{bubbles:true})); }")
    E("()=>{ var el=document.querySelector('[data-dkt=\"cost.starter.0.0\"]'); el.value='120'; el.dispatchEvent(new Event('change',{bubbles:true})); }")
    r=E("()=>({p:KETER_DOCK.itemPrice('Repair Kit'), r:KETER_DOCK.tables().price[2], c:KETER_DOCK.nextCost('starter').shards, saved:JSON.parse(localStorage.getItem(KETER_DOCK.TAB_KEY))})")
    ck("prices and costs are editable, and only changes are kept", r["p"]==33 and r["r"]==45 and r["c"]==120 and set(r["saved"].keys())=={"price","cost","items"}, r)
    E("()=>{ KETER_DOCK.resetTables(); }")
    r=E("()=>({t:KETER_DOCK.tables().price[2], items:KETER_DOCK.tables().items.length})")
    ck("resetting the tables keeps the Exchange's list", r["t"]==40 and r["items"]==5, r)
    pg.locator("#dkReach").click(); pg.wait_for_timeout(200)
    ck("Reach +1", E("()=>KETER_DOCK.state().reach")==4)

    # ================= the Workshop's Pre-built tab =================
    E("()=>KETER_GO('workshop')"); pg.wait_for_timeout(300)
    ck("Dev Mode: the Workshop has a Pre-built tab", E("()=>!!document.querySelector('#v-workshop [data-wstab=\"prebuilt\"]')"))
    E("()=>document.querySelector('#v-workshop [data-wstab=\"prebuilt\"]').click()"); pg.wait_for_timeout(200)
    tx=E("()=>document.getElementById('v-workshop').innerText")
    ck("listing the pre-builts in order", tx.find("Pre Alpha")<tx.find("Pre Beta")<tx.find("Pre Gamma") and tx.find("Pre Alpha")>=0, tx[:400])
    E("()=>document.querySelector('[data-wspreup=\"'+KETER_WORKSHOP.prebuilts()[1].id+'\"]').click()"); pg.wait_for_timeout(200)
    ck("↑ moves one earlier", E("()=>KETER_WORKSHOP.prebuilts().map(function(d){ return d.name; }).slice(0,2)")==["Pre Beta","Pre Alpha"])
    n0=E("()=>KETER_WORKSHOP.prebuilts().length")
    E("()=>document.getElementById('wsNewPre').click()"); pg.wait_for_timeout(200)
    ck("a new pre-built can take any chassis", E("()=>document.querySelectorAll('[data-wspickpre]').length")>=1)
    E("()=>document.querySelector('[data-wspickpre]').click()"); pg.wait_for_timeout(200)
    r=E("()=>({n:KETER_WORKSHOP.prebuilts().length, last:KETER_WORKSHOP.prebuilts().slice(-1)[0].name, designs:KETER_WORKSHOP.list().length})")
    ck("and joins the end of the list, not your designs", r["n"]==n0+1 and r["last"]=="New pre-built", r)

    # ================= the Stockpile and the Deploy screen =================
    E("()=>{ localStorage.removeItem('keter-app-dev'); KETER_DOCK.addCard('Test Stim',1); var v=KETER_DOCK.inv(); v.pre={}; v.pre[KETER_WORKSHOP.prebuilts()[0].id]=2; KETER_DOCK._saveInv(v); KETER_GO('loot'); }"); pg.wait_for_timeout(300)
    tx=E("()=>document.getElementById('v-loot').innerText")
    ck("the Stockpile lists what the dock keeps", "ALSO KEPT HERE" in tx.upper() and "Test Stim" in tx and "Test Aegis Core" in tx and "Pre Beta" in tx, tx[-400:])
    E("()=>{ KETER_GO('world'); }"); pg.wait_for_timeout(300)
    tx=E("()=>document.getElementById('wldStatus').innerText")
    ck("the World Map at the dock: copies waiting, and a way to the Dock", "2 pre-built copies waiting" in tx and pg.locator('#wldStatus [data-page="dock"]').count()==1, tx)
    pg.locator("#wlDeploy").click(); pg.wait_for_timeout(200)
    pg.locator('[data-wlpick="0"]').click(); pg.wait_for_timeout(200)
    tx=E("()=>document.getElementById('wldDeploy').innerText")
    ck("the Deploy screen: the pre-built copies going, and Pack", "Pre-built copies" in tx.replace("PRE-BUILT COPIES","Pre-built copies") and "Pre Beta ×2" in tx and "0 of 1 packed" in tx, tx[-600:])
    pg.locator('[data-wlpack="Test Stim"][data-d="1"]').click(); pg.wait_for_timeout(150)
    ck("+ packs one, up to what you own", "1 of 1 packed" in E("()=>document.getElementById('wldDeploy').innerText") and pg.locator('[data-wlpack="Test Stim"][data-d="1"]').is_disabled())
    pg.locator("#wlGo").click(); pg.wait_for_timeout(300)
    r=E("()=>({pack:KETER_DEPLOY.cur().pack, inv:KETER_DOCK.inv().cards, st:document.getElementById('wldStatus').innerText})")
    ck("Pay and deploy takes the pack", r["pack"]["cons"]=={"Test Stim":1} and "Test Stim" not in r["inv"] and "Packed: Test Stim ×1" in r["st"], r)
    ck("the status counts pre-built copies left", "Pre Beta 2/2" in r["st"], r["st"])
    E("()=>{ var s=KETER_DEPLOY.cur(); s.pos=KETER_WORLD.neighbours(s.pos).filter(KETER_WORLD.isOpen)[0]; s.kills=[{name:'Pay Me', skull:3}]; s.maxSkull=5; KETER_DEPLOY._save(s); var d=KETER_DOCK.state(); d.bounties=[{name:'Pay Me', kind:'elite', district:'3', claimed:false}]; KETER_DOCK._save(d); s.pos=KETER_WORLD.map().dock; KETER_DEPLOY._save(s); KETER_WORLD_UI._sel(s.pos); }")
    pg.wait_for_timeout(200)
    pg.locator("#wlHome").click(); pg.wait_for_timeout(300)
    tx=E("()=>KETER_WORLD_UI.state().note")
    ck("home: the bounty paid and the reach extended, with a way to the Dock", "Bounty on Pay Me paid" in tx and "Reach extended to Skull Level 5" in tx and "Open the Dock" in tx, tx)

    # ================= the guide =================
    E("()=>KETER_GO('manual')"); pg.wait_for_timeout(200)
    r=E("()=>JSON.parse(document.getElementById('p-docs').textContent).filter(function(d){ return d.id==='dk'; }).map(function(d){ return d.title+' '+d.ver; })")
    ck("the Dock Guide is among the guides", r==["Dock Guide v1.0"], r)
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nDOCK PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
