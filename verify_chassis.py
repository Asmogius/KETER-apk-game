"""Chassis (video game crafting): the scorer multiplying Modifiers, the fit check
(power cap, ability cap counting Actions and Passives, allowed keywords), the
test chassis, and the Chassis editor."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_chassis")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9986),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d not in ("",None) and not c else ""))
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200])); pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9986/"); pg.wait_for_timeout(2200)
    E=pg.evaluate

    # ---- the scorer: Modifiers multiply ----
    r=E("""()=>{ var S=KETER_SCORE, p=function(t,o){ return S.keywordPoints(t,o); };
      return {plain:p('[[target enemy]] takes [[damage 3]].'), burst:p('[[Burst 3]]. [[target enemy]] takes [[damage 3]].'),
        both:p('[[Burst 3]]. [[AoE 1]]. [[target enemy]] takes [[damage 3]].'), bare:p('[[Burst 2]].',{attack:true}),
        attack:p('',{attack:true}), none:p('no keywords here')}; }""")
    ck("a plain effect scores its keywords", r["plain"]==3, r)
    ck("Burst 3 triples it", r["burst"]==r["plain"]*3, r)
    ck("several Modifiers multiply together", r["both"]==r["plain"]*6, r)
    ck("a Modifier on a bare attack multiplies the attack's own 4", r["bare"]==8 and r["attack"]==4, r)
    ck("text with no keywords is left for the caller to count as 4", r["none"] is None, r)

    # ---- the test chassis ----
    r=E("()=>KETER_CHASSIS.list().filter(function(c){return c.test;}).map(function(c){return c.id;})")
    ck("the five test chassis are installed", len(r)==5, r)
    # Revision 15.6: "Archetype" is one chip standing for every Archetype
    r=E("()=>{ var C=KETER_CHASSIS, all=C.chipList().map(function(k){return k.name;}); return C.list().every(function(c){ return (c.allowed||[]).every(function(k){ return all.indexOf(k)>=0; }); }); }")
    ck("every keyword they allow exists", r)
    r=E("()=>KETER_CHASSIS.list().filter(function(c){return c.test;}).map(function(c){return c.district;})")
    ck("most belong to a District, one is General", r.count("")==1 and len(set(x for x in r if x))==4, r)
    # v14.9: and content batch 1's Skitter Frame ships alongside them
    r=E("()=>{ var c=KETER_CHASSIS.get('ch_skitter_frame'); return c ? [c.district, !!c.shipped, !!c.test] : null; }")
    ck("v14.9: the Skitter Frame ships in the library too: District 3, shipped, not a test chassis", r==["3", True, False], r)

    # ---- the fit check, rule by rule ----
    def check(cid, abilities):
        return E(f"(a)=>KETER_CHASSIS.check(KETER_CHASSIS.get('{cid}'),{{abilities:a}})", abilities)
    r=check("ch_test_threshold",[{"role":"Ranged","text":"[[Burst 2]]. [[target enemy]] takes [[damage 2]]."}])
    ck("a design within every limit fits", r["ok"] and not r["reasons"], r)
    r=check("ch_test_threshold",[{"role":"Ranged","text":"[[Burst 3]]. [[target enemy]] takes [[damage 2]] and gains [[Marked]] for [[turns 3]]."}])
    ck("over the power cap, it doesn't fit, and says so", not r["ok"] and r["power"]>r["cap"] and "cap" in r["reasons"][0], r)
    r=check("ch_test_meridian",[{"role":"Melee","text":"[[target enemy]] takes [[damage 2]]."},{"role":"","text":"[[target enemy]] takes [[damage 1]]."}])
    ck("the ability cap counts Passives as well as Actions", not r["ok"] and r["abilities"]==2 and r["abilityCap"]==1, r)
    r=check("ch_test_threshold",[{"role":"Ranged","text":"[[AoE 1]]. [[target enemy]] takes [[damage 1]]."}])
    ck("a forbidden keyword is refused by name", not r["ok"] and r["forbidden"]==["AoE"], r)
    r=check("ch_test_general",[{"role":"Ranged","text":"[[Burst 2]]. [[target enemy]] takes [[damage 1]]."},{"role":"Ranged","text":"[[AoE 1]]."},{"role":"","text":"[[this Unit]] gains [[heal 1]]."}])
    ck("every broken rule is reported, not just the first", len(r["reasons"])==3, r["reasons"])
    # Revision 15.5: a chassis's subtypes decide which kinds of Actions a design may have
    r=check("ch_test_threshold",[{"role":"Melee","text":"[[target enemy]] takes [[damage 1]]."}])
    ck("an Action outside the chassis's subtypes is refused", not r["ok"] and r["wrongKind"] and "Melee" in r["wrongKind"][0], r)
    r=check("ch_test_threshold",[{"role":"Cyber","text":"[[target enemy]] takes [[damage 1]]."},{"role":"","text":"[[target enemy]] gains [[Marked]] for [[turns 1]]."}])
    ck("its own subtypes, and Passives, are allowed", not r["wrongKind"], r)
    r=E("()=>{ var c=KETER_CHASSIS.upgrade({name:'Old',role:'Ranged',stats:{sec:7,ac:12},allowed:['WIL','damage','Compromised']}); return {subs:c.subtypes, int:c.stats.int, sec:c.stats.sec, allowed:c.allowed}; }")
    ck("an older chassis upgrades: role to subtypes, Security to Integrity, retired keywords dropped",
       r["subs"]==["Ranged"] and r["int"]==7 and r.get("sec") is None and r["allowed"]==["INT","damage"], r)
    r=check("ch_test_lazarus",[{"role":"Ranged","text":"[[Chain 2]]. [[Pierce]]. [[target enemy]] takes [[damage 2]]."}])
    ck("a chassis allowing everything is limited by power alone", not r["forbidden"], r)

    # ---- the editor ----
    ck("the Chassis editor has a tile on Home", pg.locator('.lt[data-page="chassis"]').count()==1)
    pg.locator('.lt[data-page="chassis"]').click(); pg.wait_for_timeout(500)
    ck("its library groups chassis by District (the five test chassis and the Skitter Frame)", pg.locator(".chitem").count()==6 and "THRESHOLD DYNAMICS" in pg.locator("#v-chassis").inner_text().upper())
    pg.locator("#chNew").click(); pg.wait_for_timeout(300)
    pg.locator("#chName").fill("Suite Frame"); pg.locator("#chDistrict").select_option("3"); pg.locator("#chPower").fill("18")
    pg.locator('[data-chkw="damage"]').click(); pg.wait_for_timeout(100)
    pg.locator('[data-chall="modifier"]').click(); pg.wait_for_timeout(700)
    r=E("()=>{ var c=KETER_CHASSIS.list().filter(function(x){return x.name==='Suite Frame';})[0]; return c&&{d:c.district, cap:c.powerCap, allowed:c.allowed}; }")
    ck("a new chassis saves as you edit it", r and r["d"]=="3" and r["cap"]==18, r)
    ck("keywords are allowed one at a time, or a whole category at once", r and "damage" in r["allowed"] and "Burst" in r["allowed"] and "Aura" in r["allowed"], r)
    pg.locator('[data-chnone="modifier"]').click(); pg.wait_for_timeout(700)
    ck("and a whole category can be forbidden again", "Burst" not in E("()=>KETER_CHASSIS.list().filter(function(x){return x.name==='Suite Frame';})[0].allowed"))
    E("()=>KETER_CHASSIS_UI.tryDesign([{role:'Ranged',text:'[[Burst 2]]. [[target enemy]] takes [[damage 3]].'}])")
    txt=pg.locator("#chResult").inner_text()
    ck("Try a design shows the power, with the Modifier's multiplying", "Burst" in txt and "\u00d7" in txt, txt[:120])
    ck("and says why it doesn't fit", "cannot use Burst" in txt, txt[:200])
    pg.locator("#chBack").click(); pg.wait_for_timeout(300)
    pg.locator('[data-chcopy="ch_test_general"]').click(); pg.wait_for_timeout(300)
    ck("a chassis can be copied", E("()=>KETER_CHASSIS.list().filter(function(x){return x.name==='Test Frame \u00b7 General copy';}).length")==1)
    pg.evaluate("()=>{ var c=KETER_CHASSIS.get('ch_test_general'); c.powerCap=99; KETER_CHASSIS.put(c); }")
    pg.reload(); pg.wait_for_timeout(2000)
    ck("an edited test chassis is never replaced on start-up", E("()=>KETER_CHASSIS.get('ch_test_general').powerCap")==99)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"CHASSIS PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
