"""The Workshop and the Codex (v12.7): blueprints (free words, levels, found or
researched), chassis found like blueprints, District pools and Enemy drops,
floor reward items, designs (power, the fit check, the cost of a copy) as real
Troop cards, the Codex's redacted entries, and Dev Mode's editors."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_workshop")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9987),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

LIB=open("verify_loot.py").read().split('LIB=r"""')[1].split('"""')[0]
DESIGN="""(o)=>{ var W=KETER_WORKSHOP, d=W.blank(o.ch); d.name=o.name; d.abilities[0].text=o.text; if(o.energy!=null) d.abilities[0].energy=o.energy;
  ['range','hit','ap'].forEach(function(k){ if(o[k]!=null) d.abilities[0][k]=o[k]; }); return d; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9987/"); pg.wait_for_timeout(1800)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); localStorage.removeItem('keter-app-dev'); }")
    pg.reload(); pg.wait_for_timeout(2000)
    E=pg.evaluate
    D=lambda o: E("(o)=>{ var f="+DESIGN+"; window._D=f(o); return true; }", o)

    # ================= blueprints =================
    r=E("""()=>{ var P=KETER_PROG, c=P.catalog(), n=function(x){ return c.filter(function(b){ return b.name===x; })[0]||null; };
      return {n:c.length, damage:n('damage'), heal:n('heal'), turns:n('turns'), target:n('target enemy'), burst:n('Burst'), ac:n('AC'), when:n('when'), pierce:n('Pierce'),
        free:[P.isBlueprint('damage'),P.isBlueprint('target enemy'),P.isBlueprint('Burst')]}; }""")
    ck("target words, damage, heal and turns are free: not blueprints", r["damage"] is None and r["heal"] is None and r["turns"] is None and r["target"] is None and r["free"]==[False,False,True], r["free"])
    ck("every other keyword is a blueprint", r["n"]>=40, r["n"])
    ck("one with a number has three levels: Burst up to 2, 3, 4", r["burst"]["levels"]==3 and r["burst"]["caps"]==[2,3,4], r["burst"])
    ck("a stat up to 2, 4, 6", r["ac"]["levels"]==3 and r["ac"]["caps"]==[2,4,6], r["ac"])
    ck("the rest (a condition, a word without a number) have one", r["when"]["levels"]==1 and r["when"]["caps"] is None, r["when"])
    r=E("()=>{ var P=KETER_PROG; return [P.levelFor('Burst',2),P.levelFor('Burst',3),P.levelFor('Burst',4),P.levelFor('Burst',5),P.levelFor('damage',9),P.levelFor('when')]; }")
    ck("the level a number needs (Burst 2 → 1, 3 → 2, 4 → 3, 5 → more than any)", r==[1,2,3,4,0,1], r)
    r=E("()=>{ var P=KETER_PROG; P.reset(); return {starter:P.STARTER, g:P.hasChassis('ch_test_general'), t:P.hasChassis('ch_test_threshold'), burst:P.owned('Burst'), dmg:P.owned('damage')}; }")
    ck("a new player has the General starter chassis, and no other", r["g"] and not r["t"] and r["starter"]=="ch_test_general", r)
    ck("and no blueprints (free words count as owned)", r["burst"]==0 and r["dmg"]==99, r)
    r=E("""()=>{ var P=KETER_PROG; P.reset(); return {l2:P.eligible('bp:Burst:2'), l1:P.eligible('bp:Burst:1'), pend:P.eligible('bp:Burst:2',['bp:Burst:1']), pend3:P.eligible('bp:Burst:3',['bp:Burst:1']),
      ch:P.eligible('ch:ch_test_threshold'), starter:P.eligible('ch:ch_test_general'), twice:P.eligible('ch:ch_test_threshold',['ch:ch_test_threshold']), nosuch:P.eligible('ch:nope'), lv4:P.eligible('bp:Burst:4')}; }""")
    ck("only the next level missing can drop: L1 before L2", r["l1"] and not r["l2"], r)
    ck("in the same fight, L1 found makes L2 possible (and not L3)", r["pend"] and not r["pend3"], r)
    ck("a chassis you do not have can drop; the starter, or one found this fight, cannot", r["ch"] and not r["starter"] and not r["twice"] and not r["nosuch"] and not r["lv4"], r)
    r=E("""()=>{ var P=KETER_PROG; P.reset(); var a=P.grant('bp:Burst:2'), b=P.grant('bp:Burst:1'), c=P.grant('bp:Burst:2'), d=P.grant('bp:Burst:2'), e=P.grant('ch:ch_test_threshold');
      return [a,b,c,d,e,P.owned('Burst'),P.hasChassis('ch_test_threshold')]; }""")
    ck("granted in order: L2 not before L1, and not twice", r==[False,True,True,False,True,2,True], r)
    r=E("""()=>{ var P=KETER_PROG, L=KETER_LOOT; P.reset(); L.resetStock(); var a=P.research('Weakened');
      P.grant('bp:Weakened:1'); var b=P.research('Weakened'); var st=L.stock(); st.shards=200; L.setStock(st);
      var c=P.research('Weakened'), d=P.research('Weakened'), e=P.research('Weakened'), w=P.grant('bp:when:1'), f=P.research('when');
      return {a:a.why, b:b.why, c:c, d:d, e:e.why, left:L.stock().shards, lv:P.owned('Weakened'), f:f.why, hist:L.history()[0].why}; }""")
    ck("level 1 is only ever found, never researched", r["a"]=="Its first level has to be found", r)
    ck("level 2 costs 60 shards, level 3 120 (not enough: it says so)", r["b"]=="Needs 60 shards; you have 0" and r["c"]=={"ok":True,"level":2,"price":60} and r["d"]=={"ok":True,"level":3,"price":120}, r)
    ck("and the shards come out of the stockpile, with a note", r["left"]==20 and r["lv"]==3 and r["hist"]=="Researched Weakened level 3", r)
    ck("nothing past the last level, and a one-level blueprint has no research", r["e"]=="Already at its highest level" and r["f"]=="Already at its highest level", r)
    E("()=>{ KETER_LOOT.resetStock(); KETER_PROG.reset(); }")

    # ================= pools and drops =================
    r=E("""()=>{ var P=KETER_PROG; P.resetPools(); var d3=P.poolItems('3'), d1=P.poolItems('1'); P.setPoolItem('1','bp:Chain:1',true); P.setPoolItem('3','bp:Burst:1',false);
      var after=[P.poolItems('1'), P.poolItems('3').indexOf('bp:Burst:1')]; P.resetPools(); return {d3:d3, d1:d1, after:after, back:P.poolItems('3').length}; }""")
    ck("District 3 starts with a test pool of blueprint levels and chassis (16, with v14.9's movement blueprints); others empty", len(r["d3"])==16 and "bp:Leap:1" in r["d3"] and "bp:Burst:2" in r["d3"] and "ch:ch_test_threshold" in r["d3"] and r["d1"]==[], r)
    ck("every blueprint level and chassis can be toggled on or off a pool, and reset", r["after"]==[["bp:Chain:1"],-1] and r["back"]==16, r)
    r=E("""()=>{ var P=KETER_PROG, L=KETER_LOOT; P.reset(); L.seed(31); var none=0, got={}, bad=0;
      for(var i=0;i<400;i++){ var o=P.rollItems({chance:0, district:'3'}); none+=o.length; }
      for(var j=0;j<400;j++){ var g=P.rollItems({chance:100, district:'3'}); if(g.length!==1) bad++; else got[g[0]]=1; }
      var other=P.rollItems({chance:100, district:'1'});
      return {none:none, bad:bad, got:Object.keys(got).sort(), other:other}; }""")
    ck("at 0% nothing drops", r["none"]==0, r)
    ck("at 100% one item from the District's pool — only first levels and chassis for a new player", r["bad"]==0 and all(x.endswith(":1") or x.startswith("ch:") for x in r["got"]) and "bp:Burst:2" not in r["got"], r["got"])
    ck("and nothing where the pool is empty", r["other"]==[], r)
    r=E("""()=>{ var P=KETER_PROG, L=KETER_LOOT; P.reset(); L.seed(32);
      var c={lootPool:['bp:Chain:1'], setDrops:[{item:'bp:Weakened:1',chance:100},{item:'bp:Weakened:2',chance:100},{item:'bp:Burst:2',chance:100}]};
      var a=P.rollItems({chance:0, district:'', card:c}), seen={};
      for(var i=0;i<200;i++){ var g=P.rollItems({chance:100, district:'', card:{lootPool:['bp:Chain:1']}}); g.forEach(function(x){ seen[x]=1; }); }
      var fl=P.rollRewardItems({lines:[{kind:'item',item:'ch:ch_test_verdant',chance:100},{kind:'item',item:'ch:ch_test_verdant',chance:100},{kind:'item',item:'bp:AoE:1',chance:0},{kind:'exact',n:1,type:'troop',rarity:0}]});
      return {a:a, pool:Object.keys(seen), fl:fl}; }""")
    ck("an Enemy's set drops by their own chance: L1 then L2 in the same fight, never a level out of order", r["a"]==["bp:Weakened:1","bp:Weakened:2"], r["a"])
    ck("an Enemy's own pool adds to the District's", r["pool"]==["bp:Chain:1"], r["pool"])
    ck("a floor's item lines, by their chance, never twice", r["fl"]==["ch:ch_test_verdant"], r["fl"])
    r=E("""()=>{ var L=KETER_LOOT, t=L.tables(); return [t.sources.enemy.bp, t.sources.elite.bp, t.sources.miniboss.bp, t.sources.boss.bp, t.sources.lootTile.bp, t.sources.chest.bp]; }""")
    ck("a rarer drop wherever components drop: Enemy 2%, Elite 6%, Mini-Boss 15%, Boss 35%, Loot Tile 8%, chest 15%", r==[2,6,15,35,8,15], r)

    # ================= names and where to find things =================
    r=E("""()=>{ var P=KETER_PROG; P.reset(); var a=P.itemName('bp:Burst:2'), b=P.itemName('bp:Burst:2',true), c=P.itemName('ch:ch_test_threshold'); P.grant('bp:Burst:1'); var d=P.itemName('bp:Burst:3'); P.reset(); return [a,b,c,d]; }""")
    ck("a blueprint's name stays hidden until its first level is found", r[0]=="an unknown blueprint" and r[2]=="an unknown chassis", r)
    ck("and then every level is named, with its cap", r[1]=="Burst L2 (up to 3)" and r[3]=="Burst L3 (up to 4)", r)
    r=E("""()=>{ var P=KETER_PROG; P.reset(); var cards=[{name:'Test Grunt', cardType:'enemy', affinities:[{district:'3'}], setDrops:[{item:'bp:Weakened:2',chance:40}]}, {name:'Test Juggernaut', cardType:'elite', affinities:[{district:'3'}], lootPool:['bp:Weakened:2']}];
      var s=P.sourcesOf('bp:Weakened:2', cards), before=s.map(function(x){ return P.sourceText(x); }); P.see('enemy','Test Grunt'); var after=s.map(function(x){ return P.sourceText(x); });
      return {kinds:s.map(function(x){ return x.kind; }), before:before, after:after}; }""")
    ck("where to find it: the District's pool, Enemy set drops, Enemy pools and research", r["kinds"]==["district","enemy","enemy","research"], r["kinds"])
    ck("an Enemy not met yet is not named", r["before"][1:3]==["an Enemy in District 3 — 40%","an Elite in District 3 — a rare drop"], r["before"])
    ck("once met, it is", r["after"][1]=="Test Grunt (Enemy) — 40%" and r["after"][3]=="Research at the dock — 60 shards", r["after"])
    r=E("()=>{ var P=KETER_PROG; return P.sourcesOf('bp:Burst:1',[]).map(function(x){ return P.sourceText(x); }); }")
    ck("a District's pool is a place, always shown", r==["District 3 · Vantage Robotics — a rare drop from anything there"], r)

    # ================= designs =================
    E("()=>{ localStorage.removeItem('keter-app-designs'); KETER_WORKSHOP.resetTables(); KETER_PROG.reset(); }")
    r=E("""()=>{ var W=KETER_WORKSHOP, ch=KETER_CHASSIS.get('ch_test_general'), a=function(o){ var x=W.blankAbility(ch,'action'); x.text='[[target enemy]] takes [[damage 2]].'; for(var k in o) x[k]=o[k]; return W.abilityPower(x,ch); };
      return {e2:a({energy:2}), e1:a({energy:1}), e0:a({energy:0}), range:a({energy:2,range:6}), hit:a({energy:2,hit:8}), hitUp:a({energy:2,hit:3}), ap:a({energy:2,ap:6}), low:a({energy:2,range:2}),
        blank:W.blankAbility(ch,'action'), melee:W.fieldsFor({kind:'action',role:'Melee'}), sup:W.fieldsFor({kind:'action',role:'Support'}), pas:W.fieldsFor({kind:'passive'})}; }""")
    ck("an attack counts 4, plus its keywords (damage 2): power 6 at 2 Energy", r["e2"]==6, r)
    ck("a cheaper Action counts for more: × 1.25 at 1 Energy, × 1.5 at 0", r["e1"]==8 and r["e0"]==9, r)
    ck("better numbers add power: range +0.5 and AP +0.5 a point above 4", r["range"]==7 and r["ap"]==7 and r["low"]==5, r)
    # 14.0 (the playtest's fix): a to-hit multiplies by its chance to hit, against 6's: a surer shot costs more
    ck("a to-hit multiplies by its chance to hit: 3 is worth more than 6, 8 less", r["hitUp"]==7 and r["hit"]==5, r)
    ck("a new Action starts at the baselines within the chassis's maximums, 1 Energy", r["blank"]["energy"]==1 and [r["blank"]["range"],r["blank"]["hit"],r["blank"]["ap"]]==[4,6,4], r["blank"])
    ck("Melee sets AP; Ranged and Cyber range, to-hit and AP; Support and Passives none", r["melee"]==["ap"] and r["sup"]==[] and r["pas"]==[], r)
    D({"ch":"ch_test_general","name":"Rifleman","text":"[[target enemy]] takes [[damage 2]]."})
    r=E("()=>{ var W=KETER_WORKSHOP; return {c:W.check(_D), cost:W.cost(_D), n:W.affordable(_D)}; }")
    ck("a plain design fits", r["c"]["ok"] and r["c"]["power"]==8 and r["c"]["cap"]==12, r["c"])
    ck("a copy costs the chassis cost + 0.5 × power in Common Troop parts (3 + 4)", r["cost"]["parts"]==[7,0,0,0,0,0], r["cost"])
    ck("and the stockpile says how many it could pay for", r["n"]==0, r["n"])
    r=E("""()=>{ var W=KETER_WORKSHOP, L=KETER_LOOT; L.resetStock(); var st=L.stock(); st.parts.troop[0]=22; L.setStock(st); var n=W.affordable(_D); L.resetStock(); return n; }""")
    ck("22 Commons pay for 3 copies", r==3, r)
    D({"ch":"ch_test_general","name":"Burster","text":"[[target enemy]] takes [[damage 2]] [[Burst 2]].","energy":4,"range":9})
    r=E("()=>KETER_WORKSHOP.check(_D).reasons")
    ck("the fit check: over the power cap", any("over this chassis's cap of 12" in x for x in r), r)
    ck("a keyword the chassis does not allow", any("cannot use Burst" in x for x in r), r)
    ck("a blueprint not found yet", any(x=="Burst needs blueprint level 1 — not found yet" for x in r), r)
    ck("more Energy than the chassis's NRG, and a range over its maximum", any("costs 4 Energy, more than this chassis's 3" in x for x in r) and any("range of 9 is over this chassis's 5" in x for x in r), r)
    D({"ch":"ch_test_threshold","name":"Burster","text":"[[target enemy]] takes [[damage 2]] [[Burst 3]]."})
    r=E("""()=>{ var W=KETER_WORKSHOP, P=KETER_PROG; P.reset(); var a=W.check(_D).reasons; P.grant('bp:Burst:1'); P.grant('ch:ch_test_threshold'); var b=W.check(_D).reasons; P.grant('bp:Burst:2'); var c=W.check(_D); return {a:a, b:b, c:c.ok}; }""")
    ck("a chassis not found yet cannot be built on", any("has not been found yet" in x for x in r["a"]), r["a"])
    ck("Burst 3 needs level 2 — having level 1 says so", r["b"]==["Burst needs blueprint level 2 — you have level 1"], r["b"])
    ck("with level 2 it fits", r["c"], r)
    r=E("""()=>{ var W=KETER_WORKSHOP, t=W.tables(); t.require={Burst:{"2":{"1":2,"3":1}}}; t.rate=1; W.saveTables(t); var c=W.cost(_D); W.resetTables(); return c; }""")
    ck("rarer parts per keyword level, from the table you fill (Burst L2: 2 Uncommon, 1 Epic)", r["parts"][1:]==[2,0,1,0,0] and r["lines"][1]["label"]=="Burst L2", r)
    ck("the rate is yours to set too", r["parts"][0]==6+r["power"], r)
    r=E("""()=>{ var W=KETER_WORKSHOP, d=_D; d.id=null; var id=W.put(d), c=W.toCard(W.get(id)); return {c:c, id:id}; }""")
    c=r["c"]
    ck("a design is a Troop card with its chassis's stats", c["cardType"]=="troop" and c["stats"]=={"hp":"10","ac":"12","int":"11","nrg":"4","move":"6","uslot":"1"}, c["stats"])
    ck("its Aether cost set by the chassis (1 any + 1 District 1)", c["aetherCost"]=={"generic":1,"affinity":1,"affinity2":0} and c["affinities"]==[{"district":"1","level":0}], c)
    ck("its attacks deal the chassis's DMG, at the range, to-hit, AP and Energy set", c["entries"][0]=={"name":"Action","kind":"Active","text":"[[target enemy]] takes [[damage 2]] [[Burst 3]].","role":"ranged","energyCost":"1","damage":"2","armorPenetration":"4","attackRange":"4","toHit":"6"}, c["entries"][0])
    ck("a steady card id from the design", c["id"]=="WS-"+r["id"][3:].upper(), c["id"])
    r=E("""()=>{ var a=KETER_ALLCARDS().filter(function(c){ return c._src==='design'; }).map(function(c){ return c.name; }), s=simAllCards().filter(function(c){ return c._src==='design'; }).map(function(c){ return c.name; });
      return {a:a, s:s}; }""")
    ck("designs are in the Compendium and Deck Builder's cards, the starter too", r["a"]==["Burster","Frame Trooper"], r)
    ck("and the Battle Simulator's", r["s"]==["Burster","Frame Trooper"], r)
    E("()=>KETER_GO('comp')"); pg.wait_for_timeout(1200)
    r=E("()=>({txt:document.getElementById('v-comp').innerText.indexOf('Burster')>=0, src:document.getElementById('v-comp').innerHTML.indexOf('Designs')>=0})")
    ck("the Compendium shows it, with Designs as a source to filter by", r=={"txt":True,"src":True}, r)
    r=E("""()=>{ var W=KETER_WORKSHOP, t=W.tables(); t.numbers.range.per=2; t.energyStep=0; W.saveTables(t); var saved=JSON.parse(localStorage.getItem(W.WS_KEY)); var p=W.power(_D); W.resetTables(); return {p:p, back:W.power(_D), saved:saved.numbers.range.per}; }""")
    ck("the Workshop's tables are yours: changed, they change power; reset, they go back", r["saved"]==2 and r["p"]!=r["back"], r)

    # ================= the Workshop page =================
    E("()=>{ localStorage.removeItem('keter-app-designs'); KETER_PROG.reset(); KETER_GO('home'); }"); pg.wait_for_timeout(300)
    ck("Home has the Workshop and the Codex", pg.locator('#launcher [data-page="workshop"]').count()==1 and pg.locator('#launcher [data-page="codex"]').count()==1)
    pg.locator('#launcher [data-page="workshop"]').click(); pg.wait_for_timeout(300)
    ck("the Workshop opens on Designs, with the built-in starter", pg.locator("#v-workshop.on").count()==1 and "Frame Trooper" in pg.locator("#v-workshop").inner_text() and "free copies every deployment" in pg.locator("#v-workshop").inner_text())
    pg.locator("#wsNew").click(); pg.wait_for_timeout(100)
    ck("a new design starts on a chassis you have found", pg.locator("[data-wspick]").count()==1 and pg.locator('[data-wspick="ch_test_general"]').count()==1)
    ck("the rest are still to be found", "5 more chassis are still to be found" in pg.locator("#v-workshop").inner_text(), pg.locator("#v-workshop").inner_text()[-200:])
    pg.locator('[data-wspick="ch_test_general"]').click(); pg.wait_for_timeout(200)
    ck("the editor shows the chassis and its limits", "Attacks up to range 5 and AP 5, to-hit 5 at best · deploys for 1 Aether" in pg.locator(".wschs").inner_text(), pg.locator(".wschs").inner_text())
    pg.locator('[data-wstext="0"]').fill("[[target enemy]] takes [[damage 2]]."); pg.locator('#wsName').fill("Rifleman Mk I"); pg.wait_for_timeout(600)
    ck("power and the fit update as you write", pg.locator(".wspow b").inner_text()=="8" and "This design fits" in pg.locator("#wsResult").inner_text())
    ck("with the cost of a copy", "7 Common" in pg.locator(".wstot").inner_text(), pg.locator(".wstot").inner_text())
    ck("saved as you go", E("()=>KETER_WORKSHOP.list().map(function(d){ return d.name; })")==["Frame Trooper","Rifleman Mk I"])
    pg.locator('[data-wsnum="0:energy"]').fill("0"); pg.locator('[data-wsnum="0:energy"]').dispatch_event("input"); pg.wait_for_timeout(100)
    ck("a free Action counts for more", pg.locator(".wspow b").inner_text()=="9", pg.locator(".wspow b").inner_text())
    pg.locator('[data-wsnum="0:range"]').fill("7"); pg.locator('[data-wsnum="0:range"]').dispatch_event("input"); pg.wait_for_timeout(100)
    ck("a range past the chassis's maximum does not fit", "range of 7 is over this chassis's 5" in pg.locator("#wsResult").inner_text())
    pg.locator('[data-wsnum="0:range"]').fill("5"); pg.locator('[data-wsnum="0:range"]').dispatch_event("input")
    got=E("""()=>{ window._bopts=null; var o=KETER_BUILDER.open; KETER_BUILDER.open=function(x){ window._bopts=x; }; return true; }""")
    pg.locator('[data-wsbuild="0"]').click(); pg.wait_for_timeout(100)
    r=E("()=>{ var x=window._bopts; return x?{allowed:x.allowed, role:x.role, type:x.cardType}:null; }")
    ck("Build offers only the chassis's keywords that you own", r and sorted(r["allowed"])==sorted(["target enemy","target ally","this Unit","damage","heal","turns"]) and r["role"]=="ranged" and r["type"]=="troop", r)
    E("()=>{ KETER_PROG.grant('ch:ch_test_threshold'); }")
    pg.locator("#wsBack").click(); pg.wait_for_timeout(100)
    pg.locator("#wsNew").click(); pg.locator('[data-wspick="ch_test_threshold"]').click(); pg.wait_for_timeout(200)
    pg.locator('[data-wsbuild="0"]').click(); pg.wait_for_timeout(100)
    r=E("()=>window._bopts.allowed")
    ck("Burst, Pierce and Marked stay out until found", sorted(r)==sorted(["target enemy","damage","turns"]), r)
    E("()=>{ KETER_PROG.grant('bp:Pierce:1'); KETER_PROG.grant('bp:Weakened:1'); }")
    pg.locator('[data-wsbuild="0"]').click(); pg.wait_for_timeout(100)
    ck("and come in once found", "Pierce" in E("()=>window._bopts.allowed"))
    pg.reload(); pg.wait_for_timeout(1800)
    E("()=>KETER_GO('workshop')"); pg.wait_for_timeout(300)
    ck("the list shows each design with its power, fit and cost", pg.locator(".wsitem").count()==3 and "power 10 / 12" in pg.locator("#v-workshop").inner_text(), pg.locator("#v-workshop").inner_text()[:400])
    pg.locator('[data-wstab="blueprints"]').click(); pg.wait_for_timeout(100)
    ck("Blueprints lists what you own", "Weakened" in pg.locator("#wsBody").inner_text() and "level 1 of 3" in pg.locator("#wsBody").inner_text())
    ck("research needs shards", pg.locator('[data-wsres="Weakened"]').is_disabled())
    E("()=>{ var st=KETER_LOOT.stock(); st.shards=100; KETER_LOOT.setStock(st); }")
    pg.locator('[data-wstab="designs"]').click(); pg.locator('[data-wstab="blueprints"]').click(); pg.wait_for_timeout(100)
    pg.locator('[data-wsres="Weakened"]').click(); pg.wait_for_timeout(100)
    ck("and researches the next level", "Researched Weakened level 2 for 60 shards" in pg.locator("#wsBody").inner_text() and E("()=>KETER_PROG.owned('Weakened')")==2)
    ck("the testing switch is Dev Mode's", pg.locator("#wsAll").count()==0)
    pg.locator('[data-wstab="costs"]').click(); pg.wait_for_timeout(100)
    ck("Costs: the rate, Energy and attack numbers", pg.locator("[data-wst]").count()==3 and pg.locator("[data-wsn]").count()==6)
    ck("each blueprint's levels, prices and parts only in Dev Mode", pg.locator("#wsCostKw").count()==0 and "edited in Dev Mode" in pg.locator("#wsBody").inner_text())

    # ================= the Codex (a player) =================
    E("()=>{ KETER_PROG.reset(); KETER_GO('codex'); }"); pg.wait_for_timeout(300)
    t=pg.locator("#v-codex").inner_text()
    ck("the Codex: nothing met, every Enemy redacted", "0 met" in t and "Test Grunt" not in t and "not met yet" in t, t[:300])
    ck("counted by kind in one line per District", pg.locator("#v-codex .cxred").count()==E("()=>{ var d={}; KETER_ALLCARDS().forEach(function(c){ if(KETER_PROG.isFoe(c)) d[KETER_PROG.enemyDistrict(c)]=1; }); return Object.keys(d).length; }") and "Enemies" in t, t[:300])
    E("()=>{ KETER_PROG.see('enemy','Test Grunt'); KETER_CODEX_UI._tab('enemies'); }"); pg.wait_for_timeout(100)
    t=pg.locator("#v-codex").inner_text()
    ck("an Enemy met is filled in, with what it drops", "1 met" in t and "Test Grunt" in t and "Drops shards and troop parts" in t, t[:500])
    E("()=>KETER_CODEX_UI._tab('blueprints')"); pg.wait_for_timeout(100)
    t=pg.locator("#v-codex").inner_text()
    ck("blueprints: none named, and no full list — just where to look", "0 found" in t and "Burst" not in t and "blueprints — found in District 3" in t and "and more, yet to be found" in t, t[:400])
    E("()=>{ KETER_PROG.grant('bp:Burst:1'); KETER_CODEX_UI._tab('blueprints'); }"); pg.wait_for_timeout(100)
    t=pg.locator("#v-codex").inner_text()
    ck("a blueprint found is named, level by level, with where to find the rest", "1 found" in t and "Burst" in t and "level 1 of 3" in t and "District 3 · Vantage Robotics" in t, t[:500])
    E("()=>KETER_CODEX_UI._tab('chassis')"); pg.wait_for_timeout(100)
    t=pg.locator("#v-codex").inner_text()
    ck("chassis: the starter, and the rest by where they are found", "Test Frame · General" in t and "starter" in t and "Threshold" not in t and "2 chassis — found in District 3" in t, t[:400])
    E("()=>KETER_CODEX_UI._tab('components')"); pg.wait_for_timeout(100)
    t=pg.locator("#v-codex").inner_text()
    ck("components: unnamed until found, each with its sources", "Scrap servos" not in t and "Loot Tiles and Locked Chests at Skull Level 1" in t and "Test Grunt (Enemy, Skull 1)" in t, t[:400])

    # ================= the Battle Simulator =================
    E("()=>{ KETER_PROG.reset(); KETER_LOOT.resetStock(); KETER_GO('battle'); }"); pg.wait_for_timeout(600)
    E(LIB); E("()=>{ SIM.map=null; SIM.units=[]; simDebugStart('TEST · Waves'); }"); pg.wait_for_timeout(1400); E(LIB)
    r=E("()=>({d:SIM.map.district, seen:KETER_PROG.state().seen.district})")
    ck("fighting in a District discovers it", r["d"]=="3" and r["seen"]=={"3":1}, r)
    ck("an Enemy that appears in a fight is met", E("()=>KETER_PROG.state().seen.enemy['Test Grunt']===1 || Object.keys(KETER_PROG.state().seen.enemy).length>0"))
    r=E("""()=>{ T.clear(); KETER_LOOT.seed(41); var a=T.free(), g=T.put('Test Grunt','enemy',a.q,a.r); g.setDrops=[{item:'bp:Burst:1',chance:100},{item:'bp:Burst:2',chance:100},{item:'bp:Burst:3',chance:0}]; T.down(g);
      return {found:SIM.found, log:SIM.log.filter(function(l){ return /blueprint/.test(l.text); }).map(function(l){ return l.text; })}; }""")
    ck("an Enemy's set drops fall in the fight", r["found"]==["bp:Burst:1","bp:Burst:2"], r)
    ck("the log keeps an unknown blueprint's name hidden until won", len(r["log"])==2 and "not found before" in r["log"][0] and "Burst" not in r["log"][0], r["log"])
    E("()=>localStorage.setItem('keter-app-dev','1')")
    r=E("""()=>{ SIM.map.loot={shards:0, lines:[{kind:'item', item:'ch:ch_test_threshold', chance:100}]}; simFinish({winner:'ally'}); var P=KETER_PROG;
      return {burst:P.owned('Burst'), ch:P.hasChassis('ch_test_threshold'), html:document.getElementById('modal').innerText, comp:Object.keys(P.state().seen.comp)}; }""")
    E("()=>localStorage.removeItem('keter-app-dev')")
    ck("won (a free fight keeps them in Dev Mode): blueprints are kept, in order", r["burst"]==2, r)
    ck("with the floor's own blueprint or chassis", r["ch"], r)
    ck("the result names them", "Found:" in r["html"] and "Blueprint Burst L1 (up to 2)" in r["html"] and "Chassis Test Frame · Threshold Burst" in r["html"], r["html"][:400])
    ck("and components won are discovered", "troop:0" in r["comp"], r["comp"])
    E("()=>document.getElementById('modal').classList.remove('on')")
    r=E("""()=>{ T.clear(); SIM.over=false; SIM.found=[]; KETER_LOOT.seed(42); var a=T.free(), g=T.put('Test Grunt','enemy',a.q,a.r); g.setDrops=[{item:'bp:Weakened:1',chance:100}]; T.down(g);
      simFinish({winner:'enemy'}); return {owned:KETER_PROG.owned('Weakened'), html:document.getElementById('modal').innerText}; }""")
    ck("lost: the blueprint is lost with the rest, unnamed", r["owned"]==0 and "Lost with it:" in r["html"] and "Blueprint an unknown blueprint" in r["html"] and "Weakened" not in r["html"], r["html"][:400])
    E("()=>document.getElementById('modal').classList.remove('on')")
    r=E("""()=>{ var W=KETER_WORKSHOP, d=W.blank('ch_test_general'); d.name='Rifleman'; d.abilities[0].text='[[target enemy]] takes [[damage 2]].'; W.put(d);
      T.clear(); var a=T.free(), u=T.put('Rifleman','ally',a.q,a.r); return {hp:u.hp, name:u.name, act:(u.actions||[])[0]}; }""")
    ck("a design deploys in the Battle Simulator with its chassis's numbers", r["hp"]==14 and r["act"] and r["act"]["dmg"]=="3" and r["act"]["rng"]=="4" and r["act"]["hit"]=="6", r)

    # ================= Dev Mode =================
    E("()=>{ localStorage.setItem('keter-app-dev','1'); KETER_PROG.reset(); }")
    pg.reload(); pg.wait_for_timeout(2000)
    E("()=>KETER_GO('codex')"); pg.wait_for_timeout(300)
    t=pg.locator("#v-codex").inner_text()
    ck("Dev Mode: the Codex shows everything", "Dev Mode: everything shown" in t and "Test Grunt" in t and "not met yet" not in t)
    E("()=>KETER_CODEX_UI._tab('blueprints')"); pg.wait_for_timeout(100)
    ck("every blueprint, named", "Burst" in pg.locator("#v-codex").inner_text() and "Still to find" not in pg.locator("#v-codex").inner_text())
    E("()=>KETER_GO('workshop')"); pg.wait_for_timeout(300)
    pg.locator('[data-wstab="blueprints"]').click(); pg.wait_for_timeout(100)
    ck("the testing switch: every blueprint and chassis unlocked", pg.locator("#wsAll").count()==1)
    pg.locator("#wsAll").click(); pg.wait_for_timeout(100)
    r=E("()=>({b:KETER_PROG.owned('Burst'), c:KETER_PROG.hasChassis('ch_test_lazarus')})")
    ck("switched on, everything is owned", r=={"b":3,"c":True}, r)
    pg.locator("#wsAll").click()
    pg.locator('[data-wstab="costs"]').click(); pg.wait_for_timeout(100)
    ck("Costs: each blueprint's caps, research prices and rarer parts", pg.locator("#wsCostKw").count()==1)
    pg.locator("#wsCostKw").select_option("Burst"); pg.wait_for_timeout(100)
    ck("Burst: three levels of caps, prices for 2 and 3, five rarer parts each", pg.locator("[data-wscap]").count()==3 and pg.locator("[data-wsres-price]").count()==2 and pg.locator("[data-wsreq]").count()==15)
    pg.locator('[data-wscap="1"]').fill("3"); pg.locator('[data-wsres-price="2"]').fill("45"); pg.locator('[data-wsreq="1:2"]').fill("1"); pg.locator('[data-wsreq="1:2"]').dispatch_event("change"); pg.wait_for_timeout(100)
    r=E("()=>({caps:KETER_PROG.capsOf('Burst'), price:KETER_PROG.researchPrice('Burst',2), req:KETER_WORKSHOP.tables().require.Burst})")
    ck("changed, they apply", r["caps"]==[3,3,4] and r["price"]==45 and r["req"]=={"1":{"2":1}}, r)
    E("()=>KETER_WORKSHOP.resetTables()")
    E("()=>KETER_GO('loot')"); pg.wait_for_timeout(200)
    E("()=>KETER_LOOT_UI._pool('3')"); pg.wait_for_timeout(200)
    ck("Loot · Pools: a District's pool, every blueprint level and chassis", pg.locator("[data-ltpool]").count()==E("()=>KETER_PROG.allItems().length") and pg.locator("[data-ltpool].on").count()==16)
    pg.locator('[data-ltpool="bp:Chain:1"]').click(); pg.wait_for_timeout(100)
    ck("toggled on", "bp:Chain:1" in E("()=>KETER_PROG.poolItems('3')") and pg.locator("[data-ltpool].on").count()==17)
    E("()=>KETER_PROG.resetPools()")
    # the Forge
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    F=pg.frame_locator('#v-forge iframe'); fr=pg.locator('#v-forge iframe').element_handle().content_frame()
    F.locator("#fType").select_option("enemy"); pg.wait_for_timeout(300)
    ck("the Forge: an Enemy's blueprints and chassis (Dev Mode)", F.locator("#bpDropWrap").is_visible())
    F.locator("#bpPoolAdd").select_option("bp:Chain:1"); F.locator("#bpPoolAddBtn").dispatch_event("click"); pg.wait_for_timeout(100)
    F.locator("#bpSetAdd").select_option("ch:ch_test_verdant"); F.locator("#bpSetAddBtn").dispatch_event("click"); pg.wait_for_timeout(100)
    F.locator('[data-bpchance="0"]').fill("60"); F.locator('[data-bpchance="0"]').dispatch_event("change"); pg.wait_for_timeout(100)
    r=fr.evaluate("()=>{ var s=KETER_BRIDGE.toSchema(KETER_BRIDGE.currentCard()), back=KETER_BRIDGE.fromSchema(s); return {pool:s.lootPool, set:s.setDrops, back:[back.lootPool, back.setDrops]}; }")
    ck("can drop and set drops travel with the card", r["pool"]==["bp:Chain:1"] and r["set"]==[{"item":"ch:ch_test_verdant","chance":60}] and r["back"]==[r["pool"],r["set"]], r)
    F.locator("#fType").select_option("troop"); pg.wait_for_timeout(200)
    ck("not on other cards", (not F.locator("#bpDropWrap").is_visible()) and fr.evaluate("()=>{ var s=KETER_BRIDGE.toSchema(KETER_BRIDGE.currentCard()); return s.lootPool===undefined && s.setDrops===undefined; }"))
    # the Sandbox
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3300)
    P=pg.frame_locator('#v-poi iframe'); pf=pg.locator('#v-poi iframe').element_handle().content_frame()
    pf.evaluate("()=>{ document.querySelectorAll('details.sec').forEach(function(d){ d.open=true; }); }")
    pf.evaluate("()=>{ var X=KETER_POI_LOOT; X.restoreQuiet(Object.assign(X.snapshot(),{loot:{shards:0,lines:[]}})); }"); pg.wait_for_timeout(100)
    ck("the Sandbox: a floor reward can hold a blueprint or chassis (Dev Mode)", P.locator('[data-lootadd="item"]').count()==1)
    P.locator('[data-lootadd="item"]').click(); pg.wait_for_timeout(100)
    P.locator('#lootEd select[data-lootf="item"]').select_option("bp:AoE:1")
    P.locator('#lootEd input[data-lootf="chance"]').fill("30"); P.locator('#lootEd input[data-lootf="chance"]').dispatch_event("change"); pg.wait_for_timeout(100)
    r=pf.evaluate("()=>KETER_POI_LOOT.get()")
    ck("with its chance", r=={"shards":0,"lines":[{"kind":"item","item":"bp:AoE:1","chance":30}]}, r)
    ck("no page errors (Dev Mode)", not errs, errs)
    # a player sees neither editor
    E("()=>{ localStorage.removeItem('keter-app-dev'); }")
    pg.reload(); pg.wait_for_timeout(2000)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    F=pg.frame_locator('#v-forge iframe')
    F.locator("#fType").select_option("enemy"); pg.wait_for_timeout(300)
    ck("a player's Forge has no blueprint list", not F.locator("#bpDropWrap").is_visible())
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3300)
    P=pg.frame_locator('#v-poi iframe'); pf=pg.locator('#v-poi iframe').element_handle().content_frame()
    pf.evaluate("()=>{ document.querySelectorAll('details.sec').forEach(function(d){ d.open=true; }); var X=KETER_POI_LOOT; X.restoreQuiet(Object.assign(X.snapshot(),{loot:{shards:0,lines:[{kind:'item',item:'bp:AoE:1',chance:30}]}})); X.render(); }"); pg.wait_for_timeout(100)
    ck("nor its Sandbox: a blueprint line is shown, not chosen", P.locator('[data-lootadd="item"]').count()==0 and P.locator('#lootEd select[data-lootf="item"]').count()==0 and "A blueprint or chassis, 30% — set in Dev Mode" in P.locator("#lootEd").inner_text())
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nWORKSHOP PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
