"""Iteration 2: Cyber Role, Security, CPU glyph, Compromised."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_i2")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9035),
        functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:9035/index.html"); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    B = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"
    D = "document.querySelector('#v-forge iframe').contentDocument"

    # ---------- Cyber as a Combat Role ----------
    roles = pg.evaluate(f"""()=>[...{D}.querySelectorAll('#roleWrap input')]
      .map(i=>i.id||i.name||i.value)""")
    ck("Cyber appears among the Combat Roles",
       pg.evaluate(f"()=>{D}.getElementById('roleWrap').innerText.toLowerCase().indexOf('cyber')>=0"),
       pg.evaluate(f"()=>{D}.getElementById('roleWrap').innerText"))

    # ---------- Cyber as an Action role ----------
    pg.evaluate(f"()=>{D}.getElementById('addAbility').click()")
    pg.wait_for_timeout(1200)
    pg.wait_for_function(
        "()=>!!document.querySelector('#v-forge iframe').contentDocument.querySelector('.a-role')",
        timeout=8000)
    opts = pg.evaluate(f"""()=>[...{D}.querySelector('.a-role').options].map(o=>o.value)""")
    ck("Cyber is an Action role", "cyber" in opts, str(opts))
    ck("the other roles survive",
       all(r in opts for r in ["melee", "ranged", "support", "aether"]), str(opts))

    # Cyber Actions get Armor Penetration, since Security is beaten like Armor
    pg.evaluate(f"""()=>{{var r={D}.querySelector('.a-role');
      r.value='cyber'; r.dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(800)
    ck("a Cyber Action can carry Armor Penetration",
       pg.evaluate(f"()=>!!{D}.querySelector('.a-pen')"))

    # ---------- Integrity replaced Will and Security (Revision 15.5) ----------
    stats = pg.evaluate(f"""()=>{{
      var w=document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE;
      var human=w.fromSchema({{cardType:'troop',name:'H',combatRoles:['melee']}});
      var mech =w.fromSchema({{cardType:'troop',name:'M',combatRoles:['melee'],
        archetypes:['Mechanical']}});
      return [w.statsOf(human).map(s=>s.abbr), w.statsOf(mech).map(s=>s.abbr), mech.origin];
    }}""")
    ck("every Troop carries Integrity", "INT" in stats[0] and "INT" in stats[1], str(stats[:2]))
    ck("and neither Will nor Security", not any(x in stats[0]+stats[1] for x in ("WIL","SEC")), str(stats[:2]))
    ck("an old Mechanical tag changes no stat", stats[0]==stats[1], str(stats[:2]))
    ck("it is kept as lore instead", stats[2]=="Mechanical", str(stats[2]))

    # ---------- pings ----------
    warn = pg.evaluate(f"""()=>{{
      var w=document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE;
      var c=w.fromSchema({{cardType:'troop',name:'C',combatRoles:['melee'],
        entries:[{{name:'Hack',kind:'Active',role:'cyber',text:'x'}}]}});
      return w.computePings(c).map(p=>p[0]+':'+p[1]);
    }}""")
    ck("a Cyber Action on a Unit without the Cyber subtype is flagged",
       any("only have Actions of its own subtypes" in x for x in warn), str(warn)[:200])
    ck("Cyber's use of Integrity is stated",
       any("Integrity" in x for x in warn), str(warn)[:200])

    okrole = pg.evaluate(f"""()=>{{
      var w=document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE;
      var c=w.fromSchema({{cardType:'troop',name:'C',combatRoles:['cyber'],
        entries:[{{name:'Hack',kind:'Active',role:'cyber',text:'x'}}]}});
      return w.computePings(c).filter(p=>p[0]==='bad').length;
    }}""")
    ck("with the Cyber subtype there is no error", okrole == 0, str(okrole))

    mechping = pg.evaluate(f"""()=>{{
      var w=document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE;
      var c=w.fromSchema({{cardType:'troop',name:'M',combatRoles:['melee'],
        archetypes:['Mechanical']}});
      return w.computePings(c).map(p=>p[1]).join(' | ');
    }}""")
    ck("no flag mentions Overwhelmed or Security any more",
       "Overwhelm" not in mechping and "Security" not in mechping, mechping[:160])

    # ---------- Handbook ----------
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(1200)
    body = pg.locator("#mbody").inner_text()
    ck("Handbook lists the four subtypes", "Melee, Ranged, Support or Cyber" in body)
    ck("Handbook defines Integrity", "Integrity (INT)" in body)
    ck("Handbook says Integrity replaced Will and Security", "replaced Will and Security" in body)
    ck("Cyber must Penetrate Integrity", "Penetrate Integrity rather than Armor Class" in body)
    ck("Compromised and Overwhelmed are no longer defined",
       "Compromised:" not in body and "Overwhelmed:" not in body)

    # glossary
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator('.lt[data-page="gloss"]').click(); pg.wait_for_timeout(800)
    for term in ["Integrity", "Cyber", "Subtype"]:
        pg.locator("#glq").fill(term); pg.wait_for_timeout(500)
        ck(f"Glossary defines {term}", pg.locator(".glrow").count() >= 1,
           pg.locator("#glcount").inner_text())
    pg.locator("#glq").fill("Compromised"); pg.wait_for_timeout(500)
    ck("Glossary no longer lists Compromised", pg.locator(".glrow").count() == 0, pg.locator("#glcount").inner_text())

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"ITERATION 2 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
