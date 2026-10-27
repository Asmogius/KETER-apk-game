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
    ck("v14.21: waves by Skull Level, 3 3 4 4 5 6, one fewer in an ambush; Skull 1 and 2 are the gentle ones", r=={"poi":[3,3,4,4,5,6],"amb":[2,2,3,3,4,5],"soft":[True,True,False]}, r)
    r=E("""()=>{ var K=KETER_DOCK, s=K.state(); var a=K.freeDesigns(), f=K.starterFree(); s.upgrades.starter=2; K._save(s); return {a:a, f:f, b:K.freeDesigns(), f2:K.starterFree(), eff:K.tables().effect.starter}; }""")
    ck("v14.21: the Starter bay frees designs (1, 2, 3), and the starter keeps its 4", r=={"a":0,"f":4,"b":2,"f2":4,"eff":[1,2,3]}, r)
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nBALANCE PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
