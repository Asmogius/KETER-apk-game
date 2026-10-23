"""Loot (v12.6): the video game's components — three types in six rarities —
Aether shards, the loot generator (Skull Level sets the rarity ceiling; tougher
sources roll higher), a floor's own reward, the Salvage field on Enemy cards,
loot in the Battle Simulator (drops, Loot Tiles, chests, won or lost), the
stockpile, and the Loot page with its rolls and tables."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_loot")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9986),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

LIB=r"""()=>{
window.T = {
  R: window.KETER_RULES,
  clear: function(){ SIM.burst=null; SIM.pendingAct=null; SIM.units=[]; SIM.selected=null; SIM.pick=null; SIM.aim=null; SIM.halted=null; SIM.phase='turn'; SIM.over=false;
    SIM.aether={generic:50,d3:50}; SIM_FORCE.length=0; SIM.log=[]; SIM.loot=null; SIM.looted={}; SIM.lootResult=null; },
  put: function(name, side, q, r){
    SIM_DBG.place={card:name, side:side}; simDebugTap({q:q,r:r});
    var u=SIM.units[SIM.units.length-1]; if(!u||u.pos.q!==q||u.pos.r!==r) throw new Error('could not place '+name+' at '+q+','+r);
    return u; },
  free: function(){ var ks=Object.keys(SIM.map.hexes); for(var i=0;i<ks.length;i++){ var a=T.R.hexParse(ks[i]); if(!simUnitAt(a.q,a.r)) return a; } return null; },
  down: function(u){ u.hp=0; simCheckDowns(); },
  L: window.KETER_LOOT
}; return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9986/"); pg.wait_for_timeout(1800)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2000)
    E=pg.evaluate

    # ================= the engine =================
    r=E("""()=>{ var L=KETER_LOOT, t=L.tables(), names=[]; L.TYPES.forEach(function(ty){ names=names.concat(t.names[ty.id]); });
      return {types:L.TYPES.length, rar:L.RARITIES.map(function(x){ return x.label; }), n:names.length, distinct:new Set(names).size}; }""")
    ck("eighteen components: three part types in six rarities", r["types"]==3 and r["n"]==18 and r["distinct"]==18, r)
    ck("the Handbook's rarities, Common to Mythic", r["rar"]==["Common","Uncommon","Rare","Epic","Legendary","Mythic"], r)
    r=E("""()=>{ var L=KETER_LOOT; L.seed(11); var out={};
      for(var s=1;s<=6;s++){ var st=L.simulate({source:'enemy',skull:s},4000), hi=-1; st.byRarity.forEach(function(v,i){ if(v) hi=i; });
        out[s]={hi:hi, pct:st.byRarity.map(function(v){ return 100*v/st.parts; })}; }
      return out; }""")
    ck("Skull 1 drops only Commons", r["1"]["hi"]==0, r["1"])
    ck("Skull N never above the Nth rarity", all(r[str(s)]["hi"]<=s-1 for s in range(1,7)), {k:v["hi"] for k,v in r.items()})
    ck("and at Skull 6 Mythics are scarce (about 3%)", 1.5<r["6"]["pct"][5]<4.5 and r["6"]["hi"]==5, r["6"]["pct"])
    ck("weighted low: Commons are the commonest at every Skull Level", all(r[str(s)]["pct"][0]>=max(r[str(s)]["pct"]) for s in range(1,7)))
    r=E("""()=>{ var L=KETER_LOOT; L.seed(12); var e=L.simulate({source:'elite',skull:1},3000), m=L.simulate({source:'miniboss',skull:2},3000);
      var hi=function(st){ var h=-1; st.byRarity.forEach(function(v,i){ if(v) h=i; }); return h; };
      return {eliteHi:hi(e), eliteParts:e.avgParts, miniHi:hi(m), miniParts:m.avgParts}; }""")
    ck("an Elite rolls one Skull Level higher (Uncommons at Skull 1, never Rare)", r["eliteHi"]==1 and r["eliteParts"]==2, r)
    ck("a Mini-Boss drops three, one Skull Level higher", r["miniParts"]==3 and r["miniHi"]==2, r)
    r=E("""()=>{ var L=KETER_LOOT; L.seed(13); var all=true, n=0;
      for(var i=0;i<200;i++){ var b=L.roll({source:'boss', poiSkull:6, skull:2}); n+=L.count(b); if(!(b.parts.troop[5]+b.parts.equipment[5]+b.parts.aether[5])) all=false; }
      return {every:all, avg:n/200}; }""")
    ck("a Boss drops five by the POI's Skull Level, one always at the rarest it can reach", r["every"] and r["avg"]==5, r)
    r=E("""()=>{ var L=KETER_LOOT; L.seed(14); var st=L.simulate({source:'enemy',skull:3},3000), t=L.simulate({source:'enemy',skull:3,salvage:'troop'},500), m=L.simulate({source:'enemy',skull:3,salvage:'mixed'},3000);
      return {min:st.minShards, max:st.maxShards, avg:st.avgShards, troopOnly:t.byType.troop===t.parts, mix:[m.byType.troop,m.byType.equipment,m.byType.aether].map(function(v){ return v/m.parts; })}; }""")
    ck("shards: 2 per Skull Level, give or take half (Skull 3: 3 to 9)", r["min"]>=3 and r["max"]<=9 and 5.6<r["avg"]<6.4, r)
    ck("an Enemy's Salvage decides the part type", r["troopOnly"], r)
    ck("Mixed gives all three about equally", all(0.29<x<0.38 for x in r["mix"]), r["mix"])
    r=E("""()=>{ var L=KETER_LOOT; L.seed(15); var t=L.simulate({source:'lootTile',poiSkull:2},2000), c=L.roll({source:'chest',poiSkull:2,x:4}), c0=L.roll({source:'chest',poiSkull:2});
      return {tile:[t.avgParts], tileTypes:t.byType, chest:L.count(c), chest0:L.count(c0)}; }""")
    ck("a Loot Tile gives one or two components of any type", 1.3<r["tile"][0]<1.7 and all(v>0 for v in r["tileTypes"].values()), r)
    ck("a Locked Chest the number on its tile (two when it has none)", r["chest"]==4 and r["chest0"]==2, r)
    r=E("""()=>{ var L=KETER_LOOT; L.seed(16); var rw={shards:40, lines:[{kind:'exact',n:2,type:'troop',rarity:2},{kind:'roll',n:3,type:'aether',bonus:1}]};
      var b=L.rollReward(rw,1), st=L.simulate({reward:{lines:[{kind:'roll',n:1,type:'any',bonus:1}]}, poiSkull:1},2000);
      return {shards:b.shards, rareTroop:b.parts.troop[2], aether:b.parts.aether.reduce(function(a,x){return a+x;},0), total:L.count(b), text:L.rewardText(rw), unc:st.byRarity[1]>0, hi:st.byRarity[2]}; }""")
    ck("a floor reward: exact items exactly, rolled ones rolled", r["shards"]==40 and r["rareTroop"]==2 and r["aether"]==3 and r["total"]==5, r)
    ck("rolled ones can be made rarer", r["unc"] and r["hi"]==0, r)
    ck("and it reads plainly", r["text"]=="40 shards, 2 × Myomer bundles, 3 rolled Aether parts (+1 rarity)", r["text"])
    r=E("""()=>{ var L=KETER_LOOT; return [L.poiSkull({level:'4'}), L.poiSkull({hexes:[['0,0',{c:0,lvl:3}],['1,0',{c:0,lvl:5}],['2,0',{c:2}]],colorLabels:{0:'Enemy Spawn Tile',2:'Loot Tile'}}), L.poiSkull({hexes:{}})]; }""")
    ck("a POI's Skull Level: the one set on it, else its highest Enemy Spawn Tile", r==[4,5,1], r)
    r=E("""()=>{ var L=KETER_LOOT; var t=L.tables(); t.names.troop[0]='Bolts'; t.weights[0]=[80,20,0,0,0,0]; t.sources.enemy.shards=3; L.saveTables(t);
      var saved=JSON.parse(localStorage.getItem(L.TABLE_KEY)), again=L.tables(); L.resetTables(); var back=L.tables();
      return {saved:saved, name:again.names.troop[0], other:again.names.troop[1], w:again.weights[0], sh:again.sources.enemy.shards, back:[back.names.troop[0], back.weights[0][0], back.sources.enemy.shards]}; }""")
    ck("changed tables keep only what differs, so later defaults still arrive", set(r["saved"]["sources"].keys())=={"enemy"} and r["saved"]["names"]["troop"][1]=="" , r["saved"])
    ck("and read back with the change", r["name"]=="Bolts" and r["other"]=="Actuator packs" and r["w"]==[80,20,0,0,0,0] and r["sh"]==3, r)
    ck("reset puts every table back", r["back"]==["Scrap servos",100,2], r)
    r=E("""()=>{ var L=KETER_LOOT; L.resetStock(); var b=L.bag(); b.shards=10; b.parts.aether[3]=2; L.addToStock(b,'one'); L.addToStock(b,'two');
      var s=L.stock(), h=L.history(); var none=L.addToStock(L.bag(),'empty'); return {sh:s.shards, ae:s.parts.aether[3], hist:h.map(function(x){ return x.why; }), none:none, after:L.history().length}; }""")
    ck("the stockpile adds up, and remembers where each came from", r["sh"]==20 and r["ae"]==4 and r["hist"]==["two","one"], r)
    ck("an empty bag adds nothing", r["none"] is False and r["after"]==2, r)
    E("()=>{ KETER_LOOT.resetStock(); KETER_LOOT.seed(null); }")

    # ================= the Forge: Salvage =================
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    F=pg.frame_locator('#v-forge iframe'); fr=pg.locator('#v-forge iframe').element_handle().content_frame()
    F.locator("#fType").select_option("enemy"); pg.wait_for_timeout(300)
    ck("an Enemy card has a Salvage field", F.locator("#salvageWrap").is_visible())
    opts=F.locator("#fSalvage option").all_inner_texts()
    ck("Mixed (the default), Troop, Equipment or Aether parts", opts==["Mixed","Troop parts","Equipment parts","Aether parts"], opts)
    r=fr.evaluate("()=>KETER_BRIDGE.toSchema(KETER_BRIDGE.currentCard()).salvage")
    ck("left alone, it is Mixed", r=="mixed", r)
    F.locator("#fSalvage").select_option("equipment"); pg.wait_for_timeout(200)
    r=fr.evaluate("()=>{ var s=KETER_BRIDGE.toSchema(KETER_BRIDGE.currentCard()); var back=KETER_BRIDGE.fromSchema(s); return {s:s.salvage, back:back.salvage}; }")
    ck("set, it travels with the card", r=={"s":"equipment","back":"equipment"}, r)
    F.locator("#fType").select_option("boss"); pg.wait_for_timeout(200)
    ck("Bosses have it too", F.locator("#salvageWrap").is_visible())
    F.locator("#fType").select_option("troop"); pg.wait_for_timeout(200)
    ck("other cards do not, and carry no Salvage", (not F.locator("#salvageWrap").is_visible()) and fr.evaluate("()=>KETER_BRIDGE.toSchema(KETER_BRIDGE.currentCard()).salvage===undefined"))
    r=E("()=>simAllCards().filter(function(c){ return /^Test (Grunt|Gunner|Hacker|Juggernaut)$/.test(c.name); }).map(function(c){ return c.name+':'+c.salvage; }).sort()")
    ck("the test Enemies each salvage into their own type", r==["Test Grunt:troop","Test Gunner:equipment","Test Hacker:aether","Test Juggernaut:troop"], r)

    # ================= the Sandbox: a floor's reward =================
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3300)
    P=pg.frame_locator('#v-poi iframe'); pf=pg.locator('#v-poi iframe').element_handle().content_frame()
    ck("the Sandbox has a floor reward editor", P.locator("#lootEd").count()==1)
    pf.evaluate("()=>{ document.querySelectorAll('details.sec').forEach(function(d){ d.open=true; }); }")
    ck("empty, it says the floor gives only what its Enemies drop", "only what its Enemies drop" in P.locator("#lootEd .lsum").inner_text())
    P.locator('#lootEd input[data-lootf="shards"]').fill("40"); P.locator('#lootEd input[data-lootf="shards"]').dispatch_event("change")
    P.locator('[data-lootadd="exact"]').click(); P.locator('[data-lootadd="roll"]').click(); pg.wait_for_timeout(100)
    P.locator('#lootEd select[data-lootf="rarity"]').select_option("2")
    P.locator('#lootEd input[data-lootf="n"]').first.fill("2"); P.locator('#lootEd input[data-lootf="n"]').first.dispatch_event("change")
    P.locator('#lootEd input[data-lootf="n"]').nth(1).fill("3"); P.locator('#lootEd input[data-lootf="n"]').nth(1).dispatch_event("change")
    P.locator('#lootEd select[data-lootf="type"]').nth(1).select_option("aether")
    P.locator('#lootEd input[data-lootf="bonus"]').fill("1"); P.locator('#lootEd input[data-lootf="bonus"]').dispatch_event("change"); pg.wait_for_timeout(100)
    r=pf.evaluate("()=>({loot:KETER_POI_LOOT.get(), snap:KETER_POI_LOOT.snapshot().loot})")
    ck("exact and rolled lines, with shards", r["loot"]=={"shards":40,"lines":[{"kind":"exact","n":2,"type":"troop","rarity":2},{"kind":"roll","n":3,"type":"aether","bonus":1}]}, r)
    ck("kept with the floor when it is saved", r["snap"]==r["loot"], r)
    ck("and summed up in words", "40 shards, 2 × Myomer bundles, 3 rolled Aether parts (+1 rarity)" in P.locator("#lootEd .lsum").inner_text(), P.locator("#lootEd .lsum").inner_text())
    P.locator('[data-lootdel="0"]').click(); pg.wait_for_timeout(80)
    ck("a line can be taken out", pf.evaluate("()=>KETER_POI_LOOT.get().lines.length")==1)
    r=pf.evaluate("()=>{ var X=KETER_POI_LOOT; X.restoreQuiet(Object.assign(X.snapshot(),{loot:undefined})); var a=X.get(); X.restoreQuiet(Object.assign(X.snapshot(),{loot:{shards:5,lines:[]}})); return [a, X.get()]; }")
    ck("a floor without one loads as none", r[0] is None and r[1]=={"shards":5,"lines":[]}, r)

    # ================= the Battle Simulator =================
    E("()=>KETER_GO('battle')"); pg.wait_for_timeout(600)
    E(LIB)
    E("()=>{ SIM.map=null; SIM.units=[]; simDebugStart('TEST · Waves'); }"); pg.wait_for_timeout(1400)
    E(LIB)
    r=E("""()=>{ T.clear(); KETER_LOOT.seed(21); var a=T.free(); var g=T.put('Test Grunt','enemy',a.q,a.r);
      var info={skull:g.skull, salvage:g.salvage, type:g.cardType}; T.down(g);
      var L=KETER_LOOT, b=L.norm(SIM.loot); return {info:info, shards:b.shards, troop:b.parts.troop, other:L.count(b)-b.parts.troop.reduce(function(x,y){return x+y;},0),
        log:SIM.log.filter(function(l){ return l.loot; }).map(function(l){ return l.text; })}; }""")
    ck("an Enemy on the board knows its Skull Level and Salvage", r["info"]=={"skull":1,"salvage":"troop","type":"enemy"}, r["info"])
    ck("defeated, it drops shards and one Troop part (Common at Skull 1)", 1<=r["shards"]<=3 and r["troop"]==[1,0,0,0,0,0] and r["other"]==0, r)
    ck("the log says what dropped", len(r["log"])==1 and r["log"][0].startswith("Test Grunt drops:"), r["log"])
    r=E("""()=>{ var a=T.free(); var j=T.put('Test Juggernaut','enemy',a.q,a.r); var before=KETER_LOOT.count(SIM.loot); T.down(j); T.down(j);
      var b=KETER_LOOT.norm(SIM.loot); return {added:KETER_LOOT.count(b)-before, troop:b.parts.troop}; }""")
    ck("an Elite drops two, once however often it is checked", r["added"]==2, r)
    renderSim=E("()=>{ renderSim(); var h=document.getElementById('simHaul'); return h?h.textContent:''; }")
    ck("the fight's haul shows by the round", renderSim.startswith("◈ ") and "3 parts" in renderSim, renderSim)
    r=E("""()=>{ var a=T.free(), k=T.R.hexKey(a.q,a.r); SIM.map.hexes[k].c=2; var w=T.put('Test Warden','ally',a.q,a.r);
      var before=KETER_LOOT.count(SIM.loot); simFindLoot(w); var one=KETER_LOOT.count(SIM.loot)-before; simFindLoot(w); var two=KETER_LOOT.count(SIM.loot)-before;
      var c=T.free(), ck=T.R.hexKey(c.q,c.r); SIM.map.chests=SIM.map.chests||{}; SIM.map.chests[ck]=3; w.pos={q:c.q,r:c.r}; var b2=KETER_LOOT.count(SIM.loot); simFindLoot(w);
      return {tile:one, again:two-one, chest:KETER_LOOT.count(SIM.loot)-b2, looted:Object.keys(SIM.looted).length}; }""")
    ck("a friendly Unit on a Loot Tile finds one or two components", 1<=r["tile"]<=2, r)
    ck("once only", r["again"]==0, r)
    ck("a Locked Chest (LC3) gives three", r["chest"]==3 and r["looted"]==2, r)
    # v12.8: a free fight keeps its loot only in Dev Mode (deployments from the World Map are the real thing)
    E("()=>localStorage.setItem('keter-app-dev','1')")
    r=E("""()=>{ var L=KETER_LOOT; L.resetStock(); SIM.map.loot={shards:40, lines:[{kind:'exact',n:2,type:'troop',rarity:2}]};
      var haul=L.norm(SIM.loot); simFinish({winner:'ally'}); var s1=L.stock(); simFinish({winner:'ally'}); var s2=L.stock();
      var html=document.getElementById('modal').innerText;
      return {haulSh:haul.shards, haulN:L.count(haul), sh:s1.shards, n:L.count(s1), rare:s1.parts.troop[2], same:JSON.stringify(s1)===JSON.stringify(s2), html:html, hist:L.history()[0].why}; }""")
    ck("won (in Dev Mode): the haul and the floor's reward go into the stockpile", r["sh"]==r["haulSh"]+40 and r["n"]==r["haulN"]+2 and r["rare"]>=2, r)
    ck("once, however often the result is shown", r["same"], r)
    ck("the result lists the floor reward and the fight's loot", "Floor reward" in r["html"] and "added to your stockpile" in r["html"], r["html"][:300])
    ck("and the stockpile remembers the fight", r["hist"]=="Battle Simulator · TEST · Waves · won", r["hist"])
    ck("with a way to the stockpile", pg.locator('#modal [data-page="loot"]').count()==1)
    E("()=>{ document.getElementById('modal').classList.remove('on'); }")
    r=E("""()=>{ var L=KETER_LOOT; var before=JSON.stringify(L.stock()); T.clear(); SIM.over=false; var a=T.free(); var g=T.put('Test Hacker','enemy',a.q,a.r); T.down(g);
      var haul=L.norm(SIM.loot); simFinish({winner:'enemy'}); return {aether:L.count(haul)===haul.parts.aether.reduce(function(x,y){return x+y;},0) && L.count(haul)===1,
        same:JSON.stringify(L.stock())===before, html:document.getElementById('modal').innerText}; }""")
    ck("the Hacker salvages into Aether parts", r["aether"], r)
    ck("lost: the stockpile is untouched", r["same"], r)
    ck("and the result says the loot was lost, as a wipe loses it", "Loot lost" in r["html"], r["html"][:200])
    E("()=>{ document.getElementById('modal').classList.remove('on'); }")

    E("()=>localStorage.removeItem('keter-app-dev')")
    # ================= the Loot page =================
    E("()=>KETER_GO('home')"); pg.wait_for_timeout(300)
    t=pg.locator('#launcher [data-page="loot"]')
    ck("Home's Loot tile is built, no longer a placeholder", t.count()==1 and "wip" not in (t.get_attribute("class") or ""))
    t.click(); pg.wait_for_timeout(400)
    s=E("()=>KETER_LOOT.stock()")
    ck("the Loot page opens on the stockpile", pg.locator("#v-loot.on").count()==1 and pg.locator("#ltShards").inner_text().replace(",","")==str(s["shards"]))
    cells=pg.locator(".ltgrid tbody tr").count()
    ck("six rarities by three types", cells==6 and pg.locator(".ltgrid thead th").count()==4)
    ck("each count named", pg.locator(".ltgrid td i").first.inner_text()=="Scrap servos")
    pg.locator("#ltAdj").click(); pg.wait_for_timeout(100)
    pg.locator('[data-ltadj="equipment:4"]').fill("7"); pg.locator('[data-ltadj="equipment:4"]').dispatch_event("change")
    pg.locator('[data-ltadj="shards"]').fill("1234"); pg.locator('[data-ltadj="shards"]').dispatch_event("change")
    pg.locator("#ltAdj").click(); pg.wait_for_timeout(100)
    r=E("()=>KETER_LOOT.stock()")
    ck("Adjust changes counts by hand", r["parts"]["equipment"][4]==7 and r["shards"]==1234, r)
    ck("shown with thousands marked", pg.locator("#ltShards").inner_text()=="1,234")
    ck("recent additions are listed", pg.locator(".lthist > div").count()>=1)
    pg.locator('[data-lttab="roll"]').click(); pg.wait_for_timeout(100)
    pg.locator('[data-ltsrc="boss"]').click(); pg.locator('[data-ltskull="6"]').click(); pg.wait_for_timeout(80)
    ck("each source says what it gives", "16 shards per Skull Level" in pg.locator("#ltBody .pxnote").last.inner_text())
    pg.locator("#ltOnce").click(); pg.wait_for_timeout(80)
    ck("Roll once shows what came", pg.locator(".ltres li").count()>=2 and "Mythic" in pg.locator(".ltres").inner_text())
    before=E("()=>KETER_LOOT.count(KETER_LOOT.stock())")
    pg.locator("#ltKeep").click(); pg.wait_for_timeout(80)
    ck("and can be added to the stockpile", E("()=>KETER_LOOT.count(KETER_LOOT.stock())")==before+5 and "Rolled on the Loot page" in E("()=>KETER_LOOT.history()[0].why"))
    pg.locator('[data-ltsrc="enemy"]').click(); pg.locator('[data-ltskull="1"]').click(); pg.locator("#ltMany").click(); pg.wait_for_timeout(150)
    r=pg.locator(".ltbar b").all_inner_texts()
    ck("Roll 1,000 shows the spread (Skull 1: all Common)", r[0]=="100.0%" and all(x=="0.0%" for x in r[1:]), r)
    ck("with the shards' range", "on average" in pg.locator(".ltstats").inner_text())
    ck("a floor's reward can be rolled once a saved floor has one", pg.locator('[data-ltsrc="floor"]').is_disabled())
    E("""()=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}'); var k=Object.keys(all)[0]; all[k].loot={shards:9,lines:[{kind:'roll',n:2,type:'any',bonus:0}]};
      localStorage.setItem('keter-hexmap-levels',JSON.stringify(all)); KETER_LOOT_UI._tab('roll'); }""")
    pg.locator('[data-ltsrc="floor"]').click(); pg.wait_for_timeout(80); pg.locator("#ltOnce").click(); pg.wait_for_timeout(80)
    ck("and then it can", "9" in pg.locator(".ltres").inner_text() and pg.locator("#ltFloor").count()==1, pg.locator("#ltOut").inner_text()[:120])
    pg.locator('[data-lttab="tables"]').click(); pg.wait_for_timeout(100)
    ck("the tables: rarity by Skull Level, each source (with its blueprint chance, and from v14.9 its card chance), and the names", pg.locator("[data-ltw]").count()==36 and pg.locator("[data-lts]").count()==40 and pg.locator("[data-ltname]").count()==18)
    pg.locator('[data-ltw="0:0"]').fill("50"); pg.locator('[data-ltw="0:1"]').fill("50"); pg.locator('[data-ltw="0:1"]').dispatch_event("change")
    pg.locator('[data-ltname="troop:0"]').fill("Rusted servos"); pg.locator('[data-ltname="troop:0"]').dispatch_event("change")
    r=E("()=>{ KETER_LOOT.seed(3); var st=KETER_LOOT.simulate({source:'enemy',skull:1},2000); return {unc:st.byRarity[1]/st.parts, name:KETER_LOOT.tables().names.troop[0]}; }")
    ck("a changed weight changes what drops", 0.44<r["unc"]<0.56, r)
    ck("a renamed component is renamed everywhere", r["name"]=="Rusted servos", r)
    pg.locator("#ltTabReset").click(); pg.wait_for_timeout(100)
    ck("reset brings the starting values back", E("()=>KETER_LOOT.tables().weights[0][0]")==100 and pg.locator('[data-ltname="troop:0"]').input_value()=="Scrap servos")
    pg.locator('[data-lttab="stock"]').click(); pg.wait_for_timeout(80)
    pg.locator("#ltReset").click(); pg.wait_for_timeout(100)
    ck("the stockpile can be emptied", E("()=>KETER_LOOT.isEmpty(KETER_LOOT.stock())") and pg.locator("#ltShards").inner_text()=="0")
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nLOOT PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
