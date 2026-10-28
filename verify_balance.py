"""Balance and a first team (v14.20): loot about twice as plentiful, rarer parts
sooner, cheaper dock prices; Common cards free on a deployment (Common Troop
cards off the card list go as they are; a design costing only Common parts
costs nothing); and with no Loadout yet the Deck Builder walks a new one
through, step by step. (v14.21) Four copies of a card; the Starter bay frees
designs; fewer waves where it's easy; a gentler start."""
import http.server, socketserver, threading, functools, pathlib, shutil
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_balance")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9979),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:300]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:300]))

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915}).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9979/"); pg.wait_for_timeout(1500)
    pg.evaluate("()=>{ localStorage.clear(); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); }")
    pg.reload(); pg.wait_for_timeout(1900)
    E=pg.evaluate

    # the tables
    r=E("""()=>{ var L=KETER_LOOT.tables(), W=KETER_WORLD.tables(), K=KETER_DOCK.tables();
      return {enemy:L.sources.enemy, boss:L.sources.boss, chest:L.sources.chest, elite:L.sources.elite, w6:L.weights[5], cd:L.chestDefault,
        cache:W.cache, poi:W.poi, price:K.price, hero:K.heroPrice, craft:K.craft, bp:K.bpFirst, ch:K.chassis, bounty:K.bounty}; }""")
    ck("loot: about twice the shards and parts from every source; a Boss's first two at the top rarity; chests hold four",
       r["enemy"]["shards"]==4 and r["enemy"]["max"]==2 and r["boss"]["shards"]==32 and r["boss"]["max"]==10 and r["boss"]["top"]==2 and r["chest"]["shards"]==6 and r["cd"]==4, r)
    ck("Consumables and Prototypes drop more often from Elites and Chests", r["elite"]["card"]==40 and r["chest"]["card"]==25, r)
    ck("rarer parts sooner: Skull 6 is 7% Mythic", r["w6"]==[15,20,23,20,15,7], r["w6"])
    ck("the World Map's Caches and POIs give twice as much", r["cache"]["shards"]==6 and r["cache"]["n"]==4 and r["poi"]["shards"]==20 and r["poi"]["n"]==6, r)
    ck("cheaper at the dock: parts, Heroes, blueprints, chassis, crafting; the Bounty Board pays twice",
       r["price"]==[4,10,25,60,150,360] and r["hero"]==[25,50,90,180,360,720] and r["bp"]==90 and r["ch"]==180 and r["craft"]["shards"]==[12,30,70,170,360,780] and r["bounty"]["shards"]["enemy"]==30, r)
    r=E("""()=>{ KETER_LOOT.seed(5); var n=0, s=0; for(var i=0;i<200;i++){ var b=KETER_LOOT.roll({source:'enemy', skull:3}); s+=b.shards; n+=KETER_LOOT.count(b); } return {n:n, s:s}; }""")
    ck("an Enemy at Skull 3 drops 2 parts and 6 to 18 shards", r["n"]==400 and 6*200<=r["s"]<=18*200, r)

    # Common cards are free on a deployment
    E("""()=>{ localStorage.setItem('keter-app-loadouts',JSON.stringify([{v:2,name:'Commons',level:1,created:333,heroes:['test|Test Warden'],
        deck:['master|Test Drone','master|Test Drone','test|Test Snare','test|Test Snare','test|Test Plating','design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','design|Frame Trooper'],
        actions:{}, pouch:{'basic|1':6}}]));
      localStorage.setItem('keter-app-dock-tables',JSON.stringify({free:['Dock Hand','Hangar Rifleman','Field Medic','Test Warden']})); localStorage.removeItem('keter-test-every-card'); return true; }""")
    pg.reload(); pg.wait_for_timeout(1900)
    r=E("""()=>{ KETER_WORLD.newMap(4242); var all=KETER_ALLCARDS(), d=all.filter(function(c){ return c.name==='Test Drone'; }), lo=KETER_DEPLOY.loadouts()[0], p=KETER_DEPLOY.plan(0);
      return {src:d.map(function(c){ return c._src+':'+c.rarity; }), need:KETER_DEPLOY.needOf(lo, all), reasons:p.reasons, other:p.other, lines:p.lines, parts:p.parts, ok:p.ok}; }""")
    ck("a team of Common cards needs nothing from the stash", r["need"]=={}, r)
    ck("a Common Troop card off the card list deploys as it is", not any("Forge Troop" in x for x in r["reasons"]) and r["other"]>=5, r)
    ck("a design whose copies cost only Common parts costs nothing", r["lines"] and r["lines"][0]["common"] and r["lines"][0]["free"]==r["lines"][0]["copies"] and r["parts"]==[0,0,0,0,0,0], r)
    ck("so the team can leave with an empty stockpile", r["ok"], r["reasons"])
    r=E("()=>{ var s=KETER_DEPLOY.start(0); return {ok:s.ok, deck:s.ok?KETER_DEPLOY.team().deck.filter(function(x){ return /Test Drone/.test(x); }).length:-1}; }")
    ck("and its Common Troops go with it", r["ok"] and r["deck"]==2, r)

    # the walk-through
    E("()=>{ KETER_DEPLOY.abandon(); localStorage.removeItem('keter-app-loadouts'); return true; }")
    pg.reload(); pg.wait_for_timeout(1900)
    pg.locator('.lt[data-page="deck"]').click(); pg.wait_for_timeout(700)
    g=lambda: E("()=>{ var g=document.querySelector('.dkguide'); return g?{text:g.innerText, next:!!(g.querySelector('[data-guide=next]')||{}).disabled}:null; }")
    r=g()
    ck("with no Loadout, the Deck Builder opens a new one at Step 1 of the walk-through", r and "Step 1 of 6" in r["text"] and "Name it" in r["text"] and not r["next"], r)
    pg.locator('[data-guide="next"]').click(); pg.wait_for_timeout(300)
    r=g()
    ck("Step 2 asks for a Hero, and Next waits for one", r and "Step 2 of 6" in r["text"] and "Add at least one Hero" in r["text"] and r["next"], r)
    E("()=>{ var lo=JSON.parse(localStorage.getItem('keter-app-loadouts'))[0]; lo.heroes=['master|Dock Hand']; localStorage.setItem('keter-app-loadouts',JSON.stringify([lo])); return lo.guide; }")
    pg.reload(); pg.wait_for_timeout(1900)
    E("()=>{ document.querySelector('.lt[data-page=\"deck\"]').click(); }"); pg.wait_for_timeout(700)
    pg.locator('[data-lo="0"]').click(); pg.wait_for_timeout(400)
    r=g()
    ck("the step is kept on the Loadout: opened again, it picks up at Step 2, and with a Hero Next goes on", r and "Step 2 of 6" in r["text"] and not r["next"], r)
    pg.locator('[data-guide="next"]').click(); pg.wait_for_timeout(300)
    r=g()
    ck("Step 3 is the Deck, which needs 10 cards", r and "Step 3 of 6" in r["text"] and "at least 10 cards" in r["text"] and r["next"], r)
    pg.locator('[data-guide="suggest"]').click(); pg.wait_for_timeout(300)
    r=E("""()=>{ var lo=JSON.parse(localStorage.getItem('keter-app-loadouts'))[0], all=KETER_ALLCARDS();
      var cs=lo.deck.map(function(k){ return all.filter(function(c){ return (c._src||'master')+'|'+c.name===k; })[0]; });
      return {n:lo.deck.length, common:cs.every(function(c){ return c && KETER_DOCK.heroRarity(c)===0; }), troops:cs.filter(function(c){ return c&&c.cardType==='troop'; }).length}; }""")
    ck("Suggest a Deck fills it to 20 with Common cards, Troops among them", r["n"]==20 and r["common"] and r["troops"]>=2, r)
    pg.locator('[data-guide="next"]').click(); pg.wait_for_timeout(300)
    r=g()
    ck("Step 4, Action Cards, can be skipped", r and "Step 4 of 6" in r["text"] and not r["next"], r)
    pg.locator('[data-guide="next"]').click(); pg.wait_for_timeout(300)
    r=g()
    ck("Step 5 is the Pouch", r and "Step 5 of 6" in r["text"] and r["next"], r)
    pg.locator('[data-guide="suggest"]').click(); pg.wait_for_timeout(300)
    r=E("()=>{ var lo=JSON.parse(localStorage.getItem('keter-app-loadouts'))[0], n=0; Object.keys(lo.pouch).forEach(function(k){ n+=lo.pouch[k]; }); return {n:n, keys:Object.keys(lo.pouch)}; }")
    ck("Suggest a Pouch fills it with Basic Chips", r["n"]>=10 and all(k.startswith("basic|") for k in r["keys"]), r)
    pg.locator('[data-guide="next"]').click(); pg.wait_for_timeout(300)
    r=g()
    ck("Step 6 looks it over, and Finish ends it", r and "Step 6 of 6" in r["text"] and "Finish" in r["text"], r)
    pg.locator('[data-guide="next"]').click(); pg.wait_for_timeout(300)
    ck("finished, the walk-through is gone and the team is kept", g() is None and E("()=>JSON.parse(localStorage.getItem('keter-app-loadouts')).length")==1)
    # ================= v14.21 =================
    E("""()=>{ localStorage.setItem('keter-app-loadouts',JSON.stringify([{v:2,name:'Over',level:1,created:5,heroes:['master|Dock Hand'],
        deck:['test|Test Drone','test|Test Drone','test|Test Drone','test|Test Drone','test|Test Drone','test|Test Drone','test|Test Snare'],actions:{},pouch:{'test|Test Spark Chip':6,'basic|3':12}}])); return true; }""")
    r=E("()=>{ var lo=KETER_DEPLOY.loadouts()[0]; return {drones:lo.deck.filter(function(x){ return /Drone/.test(x); }).length, n:lo.deck.length, chip:lo.pouch['test|Test Spark Chip'], basic:lo.pouch['basic|3']}; }")
    ck("v14.21: a Loadout from before is read with 4 copies of a card at most; Basic Chips aren't limited", r=={"drones":4,"n":5,"chip":4,"basic":12}, r)
    pg.reload(); pg.wait_for_timeout(1900)
    r=E("()=>{ var lo=JSON.parse(localStorage.getItem('keter-app-loadouts'))[0]; return lo.deck.length; }")
    ck("v14.21: and the Deck Builder saves it trimmed", r==5, r)
    r=E("""()=>{ var D=KETER_DEPLOY; return {poi:[1,2,3,4,5,6].map(function(k){ return D.waves(k,'poi'); }), amb:[1,2,3,4,5,6].map(function(k){ return D.waves(k,'ambush'); }), soft:[D.soft(1),D.soft(2),D.soft(3)]}; }""")
    ck("v14.21: waves by Skull Level, one fewer in an ambush (v14.24: 3 3 4 3 4 5); Skull 1 and 2 are the gentle ones", r=={"poi":[3,3,4,3,4,5],"amb":[2,2,3,2,3,4],"soft":[True,True,False]}, r)
    r=E("""()=>{ var K=KETER_DOCK, s=K.state(); var a=K.freeDesigns(), f=K.starterFree(); s.upgrades.starter=2; K._save(s); return {a:a, f:f, b:K.freeDesigns(), f2:K.starterFree(), eff:K.tables().effect.starter}; }""")
    ck("v14.21: the Starter bay frees designs (1, 2, 3), and the starter keeps its 4", r=={"a":0,"f":4,"b":2,"f2":4,"eff":[1,2,3]}, r)
    # ================= v14.22 =================
    r=E("""()=>{ var K=KETER_DOCK; KETER_DEPLOY.abandon&&KETER_DEPLOY.active()&&KETER_DEPLOY.abandon(); var s=K.state(); s.merits=0; K._save(s);
      var a=K.deploymentEnded({result:'home', maxSkull:3}), b=K.deploymentEnded({result:'home', maxSkull:4}), w=K.deploymentEnded({result:'wipe'});
      return {ranks:[0,2,3,7,12,18,25].map(K.rankOf), a:a.merits, b:b.merits, up:b.rank, w:w.merits||0, m:K.merits(), r:K.rank(), next:K.toNext()}; }""")
    ck("v14.22: Colony Rank: merits coming home (1, +1 every second Skull Level), none for a wipe; 3 7 12 18 25 make Ranks 2 to 6", r=={"ranks":[1,1,2,3,4,5,6],"a":2,"b":3,"up":2,"w":0,"m":5,"r":2,"next":2}, r)
    r=E("""()=>{ var W=KETER_WORKSHOP, L=KETER_LOOT; var st=L.stock(); st.parts.troop=[8,10,4,0,0,0]; L.setStock(st);
      var c0=W.toCard(W.get('ds_starter')).stats, a=W.upgrade('ds_starter'), c1=W.toCard(W.get('ds_starter')).stats, b=W.upgrade('ds_starter'), c2=W.toCard(W.get('ds_starter')).stats, no=W.upgrade('ds_starter');
      return {a:a.mk, b:b.mk, no:no.why, hp:[+c0.hp,+c1.hp,+c2.hp], ac:[+c0.ac,+c1.ac,+c2.ac], mv:[+c0.move,+c2.move], left:L.stock().parts.troop.slice(0,3), card:W.toCard(W.get('ds_starter')).mk}; }""")
    ck("v14.22: Mk II and Mk III: +3/+1, then +6/+2/+1 Movement, paid in Troop parts; no higher", r["a"]==2 and r["b"]==3 and r["no"]=="Already Mk III" and r["hp"][1]==r["hp"][0]+3 and r["hp"][2]==r["hp"][0]+6 and r["ac"][2]==r["ac"][0]+2 and r["mv"][1]==r["mv"][0]+1 and r["left"]==[0,0,0] and r["card"]==3, r)
    # ================= v14.23 =================
    r=E("""()=>{ var W=KETER_WORLD; W.resetState(); var c=W.cores(), ks=Object.keys(c), m=W.map(), far=true;
      ks.forEach(function(k){ Object.keys(m.tiles).forEach(function(t){ if(String(m.tiles[t].d)===c[k] && W.skullOf(t)<=W.coreSkullOf(c[k]) && W.dist(t,m.dock)>W.dist(k,m.dock)) far=false; }); });
      var k1=W.coreOf('1'), cn=W.contentAt(k1); var a=W.instability(); W.clearDistrict('1',1); W.clearDistrict('2',1);
      for(var i=0;i<6;i++) W.endDeployment();
      return {ds:ks.map(function(k){ return c[k]; }).sort(), far:far, cn:cn, a:a, b:W.instability(), cleared:W.isCleared(k1), list:W.districtsCleared()}; }""")
    ck("v14.23: a Core for each District at its far edge (v14.25: at or below its Core Skull Level), a POI; clearing it lasts, and brings Instability", r["ds"]==["1","2","3","4","5","6"] and r["far"] and r["cn"]["core"]=="1" and r["cn"]["name"]=="District 1 Core" and r["a"]==0 and r["b"]==6 and r["cleared"] and r["list"]==["1","2"], r)
    r=E("()=>{ var W=KETER_WORLD; W.newMap(77); var l=W.districtsCleared(); W.resetState(); return l; }")
    ck("v14.23: a District cleared stays so on a new map", r==["1","2"], r)
    # ================= v14.24 =================
    r=E("""()=>{ var all=simFoeCards().filter(function(c){ return c.cardType==='enemy'; });
      var t=function(l){ return l.filter(function(c){ return simIsTest(c); }).length; };
      var free=[1,2,3,4,5,6].map(function(lv){ return t(simFoePool(lv,'3')); }), real=[1,2,3,4,5,6].map(function(lv){ return t(simFoePool(lv,'3',true)); });
      return {tests:t(all)>0, free:free.reduce(function(a,b){ return a+b; },0)>0, real:real}; }""")
    ck("v14.24: a deployment's Enemy pool leaves the test set's Enemies out (a free fight still may draw them)", r=={"tests":True,"free":True,"real":[0,0,0,0,0,0]}, r)
    r=E("""()=>{ var keep={deck:SIM.deck, discard:SIM.discard, log:SIM.log};
      SIM.deck=[]; SIM.log=[]; SIM.discard=[{name:'A',type:'command'},{name:'T',type:'troop'},{name:'B',type:'aether'},{name:'C',type:'equipment'}];
      var ok=simRefillDeck(), out={ok:ok, deck:SIM.deck.map(function(c){ return c.name; }).sort(), discard:SIM.discard.map(function(c){ return c.name; }), line:SIM.log.map(function(l){ return l.text; })};
      SIM.deck=[]; SIM.discard=[{name:'T2',type:'troop'}]; out.none=simRefillDeck();
      SIM.deck=keep.deck; SIM.discard=keep.discard; SIM.log=keep.log; return out; }""")
    ck("v14.24: an empty Deck takes back the cards played (not Troops), shuffled; with none, nothing", r=={"ok":True,"deck":["A","B","C"],"discard":["T"],"line":["The Deck is empty: 3 played cards are shuffled back in"],"none":False}, r)
    r=E("""()=>{ var spray={name:'Spray', role:'ranged', text:'[[target enemy]] gains [[Rooted]] for [[turns 1]].'};
      var bite={name:'Bite', role:'melee', dmg:5, text:'[[target enemy]] gains [[Rooted]] for [[turns 1]].'};
      var free={name:'U', statuses:[]}, held={name:'U', statuses:[{name:'Rooted', turns:1}]}, slowed={name:'U', statuses:[{name:'Slowed', n:1, turns:1}]};
      var slow={name:'Slow', role:'ranged', text:'[[target enemy]] gains [[Slowed 1]] for [[turns 1]].'};
      return {free:simPointless(spray, free), held:simPointless(spray, held), bite:simPointless(bite, held), slow:simPointless(slow, slowed)}; }""")
    ck("v14.24: an Action that would only give a status the target already has is pointless (damage, or a status that stacks, is not)", r=={"free":False,"held":True,"bite":False,"slow":False}, r)
    r=E("""()=>{ var by={}; simAllCards().forEach(function(c){ if(c._src==='master') by[c.name]=c; });
      var s=function(n){ var c=by[n]; return [+c.stats.hp, +c.stats.ac].concat((c.entries||[]).filter(function(e){ return e.damage; }).map(function(e){ return +e.damage; })); };
      return {ar:s('Arachnabot'), st:s('Starkiller Titan'), de:s('Decimation Titan'), co:s('Construction Titan')}; }""")
    ck("v14.24: the Skull 4-6 Enemies re-statted (Arachnabot 28 Health; Titans about a third of their Health, a third less damage)", r=={"ar":[28,15,12,8],"st":[39,15,13,5],"de":[42,16,4,8],"co":[44,16,11,7]}, r)
    # ================= v14.25 =================
    r=E("""()=>{ var W=KETER_WORLD, c=W.cores(), lv=W.tables().coreSkulls, ok=true;
      Object.keys(c).forEach(function(k){ if(W.skullOf(k)>W.coreSkullOf(c[k])) ok=false; });
      var sk=Object.keys(c).sort(function(a,b){ return +c[a]-+c[b]; }).map(function(k){ return W.skullOf(k); });
      var t=W.tables(); t.coreSkulls=[6,6,6,6,6,6]; W.saveTables(t); var c6=W.cores(), m=W.map(), far=true;
      Object.keys(c6).forEach(function(k){ Object.keys(m.tiles).forEach(function(x){ if(String(m.tiles[x].d)===c6[k] && W.dist(x,m.dock)>W.dist(k,m.dock)) far=false; }); });
      var saved=JSON.parse(localStorage.getItem('keter-app-world-tables')||'{}').coreSkulls; W.resetTables();
      return {lv:lv, ok:ok, sk:sk, far:far, saved:saved, back:W.tables().coreSkulls}; }""")
    ck("v14.25: Core Skull Levels 4 4 5 5 6 6 by District; each Core at or below its own; at 6 everywhere, the far edge again; saved as a change, reset with the tables", r["lv"]==[4,4,5,5,6,6] and r["ok"] and r["sk"]==[4,4,5,5,6,6] and r["far"] and r["saved"]==[6,6,6,6,6,6] and r["back"]==[4,4,5,5,6,6], r)
    r=E("""()=>{ var h=simDeployResultHTML({out:{next:'retry', reserves:['Field Medic']}, winner:'enemy', heroesDown:[], troopsLost:[]});
      return {withdraw:h.indexOf('id="simDepWithdraw"')>=0, retry:h.indexOf('id="simDepRetry"')>=0, give:h.indexOf('id="simDepGiveUp"')>=0, D:typeof KETER_DEPLOY.withdraw==='function' && KETER_DEPLOY.canWithdraw()===false && KETER_DEPLOY.withdraw().ok===false}; }""")
    ck("v14.25: after a lost fight, Withdraw sits between Retry and Give up; with no fight lost, it can't be done", r=={"withdraw":True,"retry":True,"give":True,"D":True}, r)
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nBALANCE PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
