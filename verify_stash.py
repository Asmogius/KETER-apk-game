"""The stash (v14.19; v14.20 frees the Common cards): a deployment's Uncommon and rarer Equipment, Command and Aether cards,
its Heroes' Action cards and its Pouch's Chips must be held at the dock, or
are crafted as it leaves; they go out with the team, come home with it, and
are lost with a wipe. The Dock's Craft tab crafts ahead of time and shows the
stash; a new run's dock offers the pick of a rare card; Deploy shows what the
team takes from the stash and what is crafted for it; Dev Mode sets the
prices."""
import http.server, socketserver, threading, functools, pathlib, shutil
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_stash")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9978),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

TEAM="""()=>{ var deck=['design|Frame Trooper','design|Frame Trooper','test|Test Snare','test|Test Snare','test|Test Capacitor','test|Test Capacitor','test|Test Plating','test|Test Surge'];
  localStorage.setItem('keter-app-loadouts',JSON.stringify([{v:2,name:'Stash Team',level:1,created:222,heroes:['test|Test Warden'],deck:deck,
    actions:{'test|Test Warden':['test|Test Piercing Rounds']},pouch:{'basic|3':4,'test|Test Spark Chip':2}}]));
  localStorage.setItem('keter-app-dock-tables',JSON.stringify({free:['Dock Hand','Hangar Rifleman','Field Medic','Test Warden']}));
  localStorage.removeItem('keter-test-every-card'); return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915}).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9978/"); pg.wait_for_timeout(1500)
    pg.evaluate("()=>{ localStorage.clear(); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); }")
    pg.evaluate(TEAM)
    pg.reload(); pg.wait_for_timeout(1900)
    E=pg.evaluate
    E("()=>{ KETER_WORLD.newMap(4242); KETER_LOOT.seed(7); }")

    # the rules
    r=E("""()=>{ var D=KETER_DEPLOY, K=KETER_DOCK, all=KETER_ALLCARDS(), lo=D.loadouts()[0];
      return {need:D.needOf(lo, all), cap:K.craftCost('Test Capacitor'), plating:K.craftCost('Test Plating'), hold:K.craftCost('Hold the Line'), stim:K.craftCost('Test Stim')}; }""")
    ck("the cards a team takes that the stash must hold: Uncommon and rarer Deck cards, carried Action cards, Pouch Chips; not Troops, Common cards or basic Chips",
       r["need"]=={"Test Capacitor":2, "Test Surge":1, "Test Piercing Rounds":1, "Test Spark Chip":2}, r["need"])
    ck("a card's price by rarity: Equipment from Equipment parts; a Command card twice the shards; a Common card or a Consumable isn't crafted",
       r["cap"]=={"name":"Test Capacitor","rarity":1,"type":"equipment","n":1,"shards":30} and r["hold"]["shards"]==60 and r["hold"]["type"]=="" and r["plating"] is None and r["stim"] is None, r)

    # a new run's dock: the starter stash, and a rare card to pick
    pg.locator('.lt[data-page="dock"]').click(); pg.wait_for_timeout(500)
    r=E("""()=>{ var s=KETER_DOCK.state(); return {stash:s.stash, recall:KETER_DOCK.owned('Hold the Line'), chip:KETER_DOCK.owned('Surge Chip'), picks:document.querySelectorAll('[data-dkrare]').length,
      text:document.getElementById('v-dock').innerText}; }""")
    ck("a new run's dock begins the stash: the starter set, and three rare cards to pick one from", r["stash"] and len(r["stash"]["offer"])==3 and r["recall"]==2 and r["chip"]==2 and r["picks"]==3 and "Pick a rare card" in r["text"], r)
    first=E("()=>document.querySelector('[data-dkrare]').getAttribute('data-dkrare')")
    pg.locator('[data-dkrare]').first.click(); pg.wait_for_timeout(300)
    r=E("()=>({owned:KETER_DOCK.owned(%r), picks:document.querySelectorAll('[data-dkrare]').length, picked:KETER_DOCK.state().stash.picked})" % first)
    ck("picked, it is in the stash and the offer is gone", r["owned"]>=1 and r["picks"]==0 and r["picked"]==first, r)

    # Craft
    pg.locator('[data-dktab="craft"]').click(); pg.wait_for_timeout(300)
    tx=E("()=>document.getElementById('v-dock').textContent")
    ck("the Craft tab: the stash, then every card it can hold by kind, with what is held and its price", "The stash" in tx and "Hold the Line ×2" in tx and "Equipment" in tx and "Chips" in tx and "30 shards and 1 Uncommon equipment part" in tx and "Ballast Plate" not in tx, tx[:400])
    E("()=>{ var st=KETER_LOOT.stock(); st.shards=200; st.parts.equipment[1]=1; KETER_LOOT.setStock(st); KETER_DOCK_UI._tab('craft'); }")
    pg.locator('[data-dkcraft="Counterweight Fist"]').click(); pg.wait_for_timeout(300)
    r=E("()=>({held:KETER_DOCK.owned('Counterweight Fist'), sh:KETER_LOOT.stock().shards, parts:KETER_LOOT.stock().parts.equipment[1], msg:KETER_DOCK_UI.state().msg})")
    ck("Craft makes one for the stash, paid in shards and parts", r["held"]==2 and r["sh"]==170 and r["parts"]==0 and "in the stash" in r["msg"], r)

    # Deploy
    E("()=>{ var st=KETER_LOOT.stock(); st.shards=1000; st.parts.equipment=[5,5,5,5,5,5]; st.parts.aether=[9,9,9,9,9,9]; st.parts.troop=[20,0,0,0,0,0]; KETER_LOOT.setStock(st); }")
    r=E("""()=>{ var p=KETER_DEPLOY.plan(0); return {ok:p.ok, craft:p.craft.map(function(c){ return [c.name,c.n]; }), shards:p.craftShards}; }""")
    ck("the plan crafts all the stash lacks, and a stockpile that can pay lets it go", r["ok"] and len(r["craft"])==4 and r["shards"]==2*30+30+60+2*30, r)
    pg.locator('#v-dock [data-page="world"]').first.click(); pg.wait_for_timeout(800)
    dep=pg.locator('#wlDeploy')
    if dep.count(): dep.first.click(); pg.wait_for_timeout(400)
    pk=pg.locator('[data-wlpick="0"]')
    if pk.count(): pk.first.click(); pg.wait_for_timeout(400)
    tx=E("()=>(document.getElementById('v-world')||document.body).textContent")
    ck("Deploy shows what the team takes from the stash, and what is crafted for it", "From the stash" in tx and "Test Capacitor ×2" in tx and "crafted" in tx, tx[-600:])
    r=E("()=>{ var r=KETER_DEPLOY.start(0); return {ok:r.ok, cap:KETER_DOCK.owned('Test Capacitor'), shards:KETER_LOOT.stock().shards, cards:r.state&&r.state.cards}; }")
    ck("leaving crafts it and takes the cards out of the stash (the Common ones are free)", r["ok"] and r["cap"]==0 and r["shards"]==1000-210 and r["cards"]["Test Capacitor"]==2 and "Test Snare" not in r["cards"], r)
    r=E("()=>{ var s=KETER_DEPLOY.cur(); s.pos=KETER_WORLD.map().dock; s.activity=null; s.steps=1; KETER_DEPLOY._save(s); var h=KETER_DEPLOY.home(); return {ok:h.ok, cap:KETER_DOCK.owned('Test Capacitor'), chip:KETER_DOCK.owned('Test Spark Chip')}; }")
    ck("home, the cards come back to the stash", r["ok"] and r["cap"]==2 and r["chip"]==2, r)
    r=E("()=>{ KETER_DEPLOY.start(0); var w=KETER_DEPLOY.wipe(); return {lost:w.lostCards, cap:KETER_DOCK.owned('Test Capacitor')}; }")
    ck("a wipe loses them", r["lost"]["Test Capacitor"]==2 and r["cap"]==0, r)

    # Dev Mode
    E("()=>{ localStorage.setItem('keter-app-dev','1'); KETER_DOCK_UI.render(); }"); pg.wait_for_timeout(200)
    r=E("()=>({n:document.querySelectorAll('[data-dkt^=\"craft.\"]').length, rare:document.querySelectorAll('[data-dkt=\"rareOffer\"]').length})")
    ck("Dev Mode sets the crafting prices and how many rare cards are offered", r["n"]==13 and r["rare"]==1, r)
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nSTASH PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
