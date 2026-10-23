"""Iterations 1 and 2: subtypes, custom archetypes, relevant fields only."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_i6")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9111),
        functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n,c,d=""):
    (ok if c else bad).append(n + ((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915}, is_mobile=True, has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:"+m.text) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9111/"); pg.wait_for_timeout(1900)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    B="document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"
    D="document.querySelector('#v-forge iframe').contentDocument"

    # ---------- subtype control ----------
    ck("subtype control exists", pg.evaluate(f"()=>!!{D}.getElementById('fSubtype')"))
    opts = pg.evaluate(f"()=>[...{D}.getElementById('fSubtype').options].map(o=>o.value)")
    ck("three subtypes plus none", opts==["","human","mechanical","cyborg"], str(opts))
    ck("the old subtype picker is hidden: origin is lore only (15.5)",
       pg.evaluate(f"()=>getComputedStyle({D}.getElementById('subtypeWrap')).display")=="none")

    # not offered on a non-unit card
    pg.evaluate(f"""()=>{{var d={D};
      d.getElementById('fType').value='equipment';
      d.getElementById('fType').dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(800)
    ck("subtype hidden on Equipment",
       pg.evaluate(f"()=>getComputedStyle({D}.getElementById('subtypeWrap')).display")=="none")
    pg.evaluate(f"""()=>{{var d={D};
      d.getElementById('fType').value='troop';
      d.getElementById('fType').dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(800)
    ck("and stays hidden for a Troop",
       pg.evaluate(f"()=>getComputedStyle({D}.getElementById('subtypeWrap')).display")=="none")

    # ---------- Mechanical and Cyborg left the archetype list ----------
    arch = pg.evaluate(f"()=>[...{D}.getElementById('fArch').options].map(o=>o.value)")
    ck("Mechanical is no longer an Archetype", "Mechanical" not in arch)
    ck("Cyborg is no longer an Archetype", "Cyborg" not in arch)
    ck("other archetypes survive",
       all(a in arch for a in ["Sniper","Juggernaut","Drone","Drone"]), str(arch[:6]))

    # ---------- Security follows subtype ----------
    st = pg.evaluate(f"""()=>{{
      var w={B};
      function abbrs(sub){{
        var c=w.fromSchema({{cardType:'troop',name:'T',combatRoles:['melee'],subtype:sub}});
        return w.statsOf(c).map(s=>s.abbr);
      }}
      return {{human:abbrs('human'), mech:abbrs('mechanical'), cy:abbrs('cyborg'), none:abbrs('')}};
    }}""")
    ck("every origin gives the same stat line", st["human"]==st["mech"]==st["cy"]==st["none"], str(st))
    ck("with Integrity", "INT" in st["none"], str(st["none"]))
    ck("and neither Will nor Security", not any(("SEC" in v or "WIL" in v) for v in st.values()), str(st))

    # ---------- schema round trip and migration ----------
    rt = pg.evaluate(f"""()=>{{
      var w={B};
      var c=w.fromSchema({{cardType:'troop',name:'C',combatRoles:['melee'],subtype:'cyborg'}});
      return [c.subtype, c.origin];
    }}""")
    ck("an old subtype becomes lore (origin), not a rule", rt==["","Cyborg"], str(rt))

    mig = pg.evaluate(f"""()=>{{
      var w={B};
      /* a card written before subtypes: Mechanical carried as an Archetype */
      var old=w.fromSchema({{cardType:'troop',name:'Old',combatRoles:['melee'],
        archetypes:['Sniper','Mechanical']}});
      var cy=w.fromSchema({{cardType:'troop',name:'OldCy',combatRoles:['melee'],
        archetypes:['Cyborg']}});
      return [old.origin, old.arches, cy.origin, cy.arches];
    }}""")
    ck("an old Mechanical card keeps it as lore", mig[0]=="Mechanical", str(mig))
    ck("the retired Archetype is stripped from it", mig[1]==["Sniper"], str(mig[1]))
    ck("an old Cyborg card keeps it as lore too", mig[2]=="Cyborg", str(mig))

    # ---------- custom archetypes ----------
    ck("a New button exists", pg.evaluate(f"()=>!!{D}.getElementById('newArch')"))
    made = pg.evaluate(f"""()=>{{
      var d={D};
      d.getElementById('newArch').click();
      var inp=d.querySelector('.overlay input'); if(!inp) return 'no prompt';
      inp.value='Salvager';
      [...d.querySelectorAll('.overlay button')].find(b=>!/cancel/i.test(b.textContent)).click();
      return true;
    }}""")
    pg.wait_for_timeout(500)
    pg.evaluate(f"""()=>{{
      var d={D};
      var inp=d.querySelector('.overlay input, .overlay textarea');
      if(inp){{ inp.value='Strips wrecks for parts.';
        [...d.querySelectorAll('.overlay button')].find(b=>!/cancel/i.test(b.textContent)).click(); }}
    }}""")
    pg.wait_for_timeout(900)
    stored = pg.evaluate("()=>localStorage.getItem('keter-custom-archetypes')")
    ck("the custom archetype is saved", stored and "Salvager" in stored, str(stored))
    arch2 = pg.evaluate(f"()=>[...{D}.getElementById('fArch').options].map(o=>o.value)")
    ck("it joins the dropdown", "Salvager" in arch2, str(arch2[-3:]))
    ck("it is applied to the current card",
       pg.evaluate(f"()=>{D}.querySelectorAll('.archchip').length")>=1)
    ck("a custom Archetype needs only a name",
       pg.evaluate(f"()=>{D}.body.innerText.indexOf('what does')<0"))

    # ---- panel shows only what applies ----
    def secs():
        """Which panel sections are visible for the card currently loaded."""
        return pg.evaluate("""()=>{
          var d=document.querySelector('#v-forge iframe').contentDocument;
          function vis(name){
            var el=d.querySelector('[data-sec="'+name+'"]');
            if(!el) return null;
            return getComputedStyle(el).display!=='none';
          }
          return {identity:true, scaling:vis('scaling'), lore:vis('lore'),
                  stats:vis('stats'), entries:vis('entries')};
        }""")

    hero = secs()
    ck("a Hero shows stats", hero["stats"] is True, str(hero))
    ck("a Hero shows effects", hero["entries"] is True, str(hero))

    pg.evaluate(f"""()=>{{var d={D};
      d.getElementById('fType').value='sphere';
      d.getElementById('fType').dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(900)
    chip = secs()
    ck("an Aether Chip hides the stat bar", chip["stats"] is False, str(chip))
    ck("an Aether Chip hides Lore", chip["lore"] is False, str(chip))
    ck("an Aether Chip still shows Effects", chip["entries"] is True, str(chip))
    ck("Identity is never hidden", chip["identity"] is True, str(chip))

    pg.evaluate(f"""()=>{{var d={D};
      d.getElementById('fType').value='troop';
      d.getElementById('fType').dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(800)
    ck("switching back restores the stat bar", secs()["stats"] is True)

    # the Will slot renames rather than duplicating
    pg.evaluate(f"""()=>{{var d={D};
      d.getElementById('fSubtype').value='mechanical';
      d.getElementById('fSubtype').dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(800)
    lab = pg.evaluate(f"""()=>{{
      var w={D}.getElementById('st_will');
      return w&&w.parentNode?w.parentNode.querySelector('label').textContent:null;
    }}""")
    ck("there is no Will field to relabel", lab is None, str(lab))
    # and back again for a human
    pg.evaluate(f"""()=>{{var d={D};
      d.getElementById('fSubtype').value='human';
      d.getElementById('fSubtype').dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(800)
    lab2 = pg.evaluate(f"""()=>{{
      var w={D}.getElementById('st_will');
      return w&&w.parentNode?w.parentNode.querySelector('label').textContent:null;
    }}""")
    ck("whatever the old picker says", lab2 is None, str(lab2))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"ITERATIONS 1+2 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
