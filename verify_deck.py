"""The Deck Builder under Handbook Revision 14.0: one Strike Team of up to three
Heroes, a shared Deck of 10 to 60, Action Cards assigned per Hero, an Aether
Pouch, and the conversion of Loadouts made before any of that existed."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, os
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_deck14")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9875),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
comp=json.load(open("compendium_full.json"))
OLD=[{"name":"Old One","level":2,"teams":[{"hero":"master|Rictus",
       "deck":["master|Field Weld","master|Overpressure","master|Ballast Plate","master|Recall"]}]},
     {"name":"Old Two","level":1,"teams":[
       {"hero":"master|Quillon Vex","deck":["master|Falconer Drone Pack","master|Debt Collector"]},
       {"hero":"master|Dross, the Forge-Blind","deck":["master|Ballast Plate"]}]}]
LS="()=>JSON.parse(localStorage.getItem('keter-app-loadouts')||'[]')"
def close(pg): pg.evaluate("()=>{var m=document.getElementById('modal'); if(m) m.classList.remove('on');}")

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True,accept_downloads=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9875/"); pg.wait_for_timeout(2000)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":comp["cards"]})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    # Handbook 14.0: setup starts from a Strike Team, so the suite needs one
    pg.evaluate("""()=>{
      var raw=JSON.parse(localStorage.getItem('keter-app-master')||'{}');
      var m=(raw&&raw.cards)||(Array.isArray(raw)?raw:[]);
      var hero=m.filter(function(c){ return c.cardType==='hero'; })[0];
      var deck=[];
      m.filter(function(c){ return /^(troop|equipment|command|aether)$/.test(c.cardType||''); })
       .forEach(function(c){ for(var i=0;i<4;i++) deck.push('master|'+c.name); });
      localStorage.setItem('keter-app-loadouts', JSON.stringify([{v:2,name:'Suite Team',
        level:1, heroes:hero?['master|'+hero.name]:[], deck:deck.slice(0,14),
        actions:{}, pouch:{'basic|3':6}}]));
    }"""); pg.wait_for_timeout(150)
    pg.evaluate("(l)=>localStorage.setItem('keter-app-loadouts',JSON.stringify(l))", OLD)
    pg.evaluate("()=>localStorage.removeItem('keter-app-migrate14')")
    pg.reload(); pg.wait_for_timeout(2300)

    # ---- conversion of old Loadouts ----
    pg.locator('.lt[data-page="deck"]').click(); pg.wait_for_timeout(900)
    lo=pg.evaluate(LS)
    ck("each old team becomes its own Loadout", len(lo)==3, str(len(lo)))
    ck("every Loadout is a Strike Team", all(l.get("v")==2 and "teams" not in l for l in lo))
    ck("split Loadouts are named after their Heroes",
       [l["name"] for l in lo][1:]==["Old Two \u2014 Quillon Vex","Old Two \u2014 Dross, the Forge-Blind"],
       str([l["name"] for l in lo]))
    ck("Action Cards come out of the Decks",
       lo[0]["deck"]==["master|Ballast Plate","master|Recall"], str(lo[0]["deck"]))
    ck("a card that is now a Command stays", "master|Recall" in lo[0]["deck"])
    ck("every Hero's Action Slots start empty", all(l["actions"]=={} for l in lo))
    ck("the change is explained once", pg.locator("#migDone").count()==1)
    ck("with how many Action Cards moved", "3 Action Cards" in pg.locator(".dknote").inner_text(),
       pg.locator(".dknote").inner_text()[:120])
    pg.locator("#migDone").click(); pg.wait_for_timeout(400)
    ck("and not again once dismissed", pg.locator("#migDone").count()==0)
    ck("the starter-deck button is gone", pg.locator("#dkStarter").count()==0)

    # ---- a new Strike Team ----
    pg.locator("#dkAdd").click(); pg.wait_for_timeout(600)
    ck("a new Loadout is a Strike Team", pg.evaluate(LS)[-1].get("v")==2)
    for i in range(3):
        pg.locator("#dkAdd").click(); pg.wait_for_timeout(500)
        ck(f"Hero {i+1} can be added", pg.locator("[data-pick]").count()>0)
        if i==1:
            names=pg.locator("[data-pick] b").all_inner_texts()
            first=pg.evaluate("()=>JSON.parse(localStorage.getItem('keter-app-loadouts')).slice(-1)[0].heroes[0]")
            ck("the picker leaves out Heroes already in the team",
               first.split("|",1)[1] not in names, first)
        pg.locator("[data-pick]").first.click(); pg.wait_for_timeout(500)
    last=pg.evaluate(LS)[-1]
    ck("three Heroes join", len(last["heroes"])==3, str(last["heroes"]))
    ck("no Hero twice", len(set(last["heroes"]))==3)
    ck("Add Hero goes away at three", not pg.locator("#dkAdd").is_visible())
    ck("the screen shows Heroes, Deck and Pouch",
       pg.locator("[data-hero]").count()==3 and pg.locator('[data-open="deck"]').count()==1
       and pg.locator('[data-open="pouch"]').count()==1)
    ck("there is one Delete button", pg.locator("#loDelete").count()==1 and pg.locator("#loDel").count()==0)

    # ---- the Deck ----
    pg.locator('[data-open="deck"]').click(); pg.wait_for_timeout(500)
    ck("the Deck asks for 10 to 60", "10\u201360" in pg.locator("#dkbody").inner_text())
    pg.locator("#addCards").click(); pg.wait_for_timeout(500)
    kinds=pg.evaluate("()=>window._pool.map(function(c){return c.cardType;})")
    ck("the Deck picker offers no Action Cards", "action" not in kinds, str(set(kinds)))
    ck("nor Heroes, Enemies or Chips", not ({"hero","enemy","elite","sphere","prototype","consumable"} & set(kinds)),
       str(set(kinds)))
    for i in range(12):
        pg.locator("[data-pick]").nth(i%4).click(); pg.wait_for_timeout(90)
    close(pg); pg.wait_for_timeout(300)
    ck("cards go into the shared Deck", len(pg.evaluate(LS)[-1]["deck"])==12)
    pg.locator("#dkBack").click(); pg.wait_for_timeout(400)

    # ---- Action Cards for a Hero ----
    # Dross has 1 Action Slot now; use whichever Hero has fewest slots but at least 1
    pg.locator("[data-hero]").first.click(); pg.wait_for_timeout(500)
    cap=pg.evaluate("""()=>{ var lo=JSON.parse(localStorage.getItem('keter-app-loadouts')).slice(-1)[0];
      var m=JSON.parse(localStorage.getItem('keter-app-master')).cards;
      var h=m.filter(function(c){return 'master|'+c.name===lo.heroes[0];})[0];
      return parseInt((h.stats||{}).slots,10)||0; }""")
    ck("the Hero's Action Slots are shown", ("of "+str(cap)) in pg.locator("#dkbody").inner_text(),
       pg.locator("#dkbody").inner_text()[:80])
    if cap:
        pg.locator("#assignAct").click(); pg.wait_for_timeout(500)
        kinds=pg.evaluate("()=>window._pool.map(function(c){return c.cardType;})")
        ck("the Action picker offers only Action Cards", set(kinds)=={"action"}, str(set(kinds)))
        for i in range(cap+2):
            if pg.locator("#modal.on [data-pick]").count()==0: break
            pg.locator("[data-pick]").nth(i%3).click(); pg.wait_for_timeout(200)
        close(pg); pg.wait_for_timeout(300)
        got=pg.evaluate(LS)[-1]["actions"]
        k0=pg.evaluate(LS)[-1]["heroes"][0]
        ck("no more are assigned than the Hero has slots", len(got.get(k0,[]))==cap, str(got))
        ck("each assigned card says what a use costs", "Each use costs" in pg.locator("#dkbody").inner_text())
        pg.locator("[data-act]").first.click(); pg.wait_for_timeout(400)
        ck("tapping one removes it", len(pg.evaluate(LS)[-1]["actions"].get(k0,[]))==cap-1)
    pg.locator("#dkBack").click(); pg.wait_for_timeout(400)

    # ---- the Pouch ----
    pg.locator('[data-open="pouch"]').click(); pg.wait_for_timeout(500)
    ck("six Basic Chips are always offered", pg.locator('[data-pq^="basic|"][data-d="1"]').count()==6)
    ck("each is worth 1", pg.locator("#dkbody").inner_text().count("worth 1")>=6)
    need=pg.evaluate("""()=>{ var lo=JSON.parse(localStorage.getItem('keter-app-loadouts')).slice(-1)[0];
      var m=JSON.parse(localStorage.getItem('keter-app-master')).cards;
      return lo.deck.reduce(function(mx,r){ var c=m.filter(function(x){return 'master|'+x.name===r;})[0]||{};
        var a=c.aetherCost||{};
        /* v13.4: a slot holding X counts as the least it can be */
        var s=function(v){ var m=/^X{1,3}$/i.exec(String(v==null?'':v).trim()); return m?m[0].length:(parseInt(v,10)||0); };
        return Math.max(mx,s(a.generic)+s(a.affinity)+s(a.affinity2)); },0); }""")
    ck("the minimum is the priciest card's full cost", ("needs at least "+str(need)) in pg.locator("#dkbody").inner_text(),
       f"need={need}")
    pg.locator("#dkBack").click(); pg.wait_for_timeout(400)
    ck("too few chips is flagged", "Aether Pouch holds 0" in pg.locator("#dkbody").inner_text())
    pg.locator('[data-open="pouch"]').click(); pg.wait_for_timeout(400)
    for _ in range(need):
        pg.locator('[data-pq="basic|1"][data-d="1"]').click(); pg.wait_for_timeout(80)
    ck("chips are counted", pg.evaluate(LS)[-1]["pouch"].get("basic|1")==need)
    pg.locator('[data-pq="basic|1"][data-d="-1"]').click(); pg.wait_for_timeout(200)
    ck("and can be taken out", pg.evaluate(LS)[-1]["pouch"].get("basic|1",0)==need-1)
    pg.locator('[data-pq="basic|1"][data-d="1"]').click(); pg.wait_for_timeout(200)
    pg.locator("#dkBack").click(); pg.wait_for_timeout(400)
    txt=pg.locator("#dkbody").inner_text()
    ck("enough chips clears the flag", "Aether Pouch holds" not in txt, txt[:140])
    ck("District 1 chips do not pay for District 3 cards",
       "District 3 Aether, but the Pouch holds no District 3 chip" in txt, txt[:300])
    ck("pooled Leadership is explained", "Pooled Leadership" in txt)

    # ---- deleting asks first ----
    n0=len(pg.evaluate(LS))
    pg.locator("#loDelete").click(); pg.wait_for_timeout(500)
    ck("deleting asks first", pg.locator("#loDelYes").count()==1)
    pg.locator("#loDelNo").click(); pg.wait_for_timeout(300)
    ck("and keeping it keeps it", len(pg.evaluate(LS))==n0)

    # ---- export, then import from the list ----
    with pg.expect_download() as dl:
        pg.locator("#loExport").click()
    path=dl.value.path()
    exported=json.load(open(path))
    ck("an export carries the Strike Team", "heroes" in (exported.get("loadout") or exported))
    pg.locator("#dkBack").click(); pg.wait_for_timeout(400)
    with pg.expect_file_chooser() as fc:
        pg.locator("#dkImport").click()
    ck("Import is reachable from the list", fc.value is not None)
    fc.value.set_files(path); pg.wait_for_timeout(900)
    ck("a Strike Team imports back", len(pg.evaluate(LS))==n0+1, str(len(pg.evaluate(LS))))
    ck("intact", pg.evaluate(LS)[-1]["heroes"]==exported.get("loadout",exported)["heroes"])

    # ---- the Simulator keeps working until its own iteration ----
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(700)
    pg.locator("#simSetup").click(); pg.wait_for_timeout(600)
    pg.locator("#simMapSel").select_option(index=0); pg.locator("#simMapNext").click(); pg.wait_for_timeout(600)
    ck("the Simulator offers the Strike Team", pg.locator("[data-wizteam]").count()>=1)
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(450)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    ck("with its Heroes ready to enter", len(pg.evaluate("()=>SIM_WIZ.heroes"))>=1)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"DECK PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
