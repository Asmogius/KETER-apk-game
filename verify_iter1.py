"""Iteration 1: Energy/NRG, Armor Penetration/AP, button visibility."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_i1")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9031),
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
    pg.goto("http://127.0.0.1:9031/index.html"); pg.wait_for_timeout(1800)

    # ---------- buttons ----------
    st = pg.locator("#updBtn").evaluate("""e=>{var s=getComputedStyle(e);
      return [s.backgroundColor, s.borderTopColor, s.color];}""")
    def lum(rgb):
        n = [int(x) for x in rgb.replace("rgb(", "").replace(")", "").split(",")[:3]]
        return 0.2126*n[0] + 0.7152*n[1] + 0.0722*n[2]
    page_bg = lum("rgb(8,11,16)")
    ck("buttons sit above the page background", lum(st[0]) > page_bg + 12,
       f"btn={round(lum(st[0]),1)} page={round(page_bg,1)}")
    ck("button border is visible against its own fill",
       lum(st[1]) > lum(st[0]) + 12, f"border={round(lum(st[1]),1)} fill={round(lum(st[0]),1)}")
    ck("button text is full strength, not dim",
       lum(st[2]) > 160, f"text={round(lum(st[2]),1)}")

    # ---------- Energy in the Forge ----------
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    B = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"
    fr = pg.frame_locator("#v-forge iframe")

    # the Action fields only exist once an Action does
    pg.evaluate("""()=>{
      var d=document.querySelector('#v-forge iframe').contentDocument;
      d.getElementById('addAbility').click();
    }""")
    pg.wait_for_timeout(700)
    pg.evaluate("""()=>{
      var d=document.querySelector('#v-forge iframe').contentDocument;
      var r=d.querySelector('.a-role');
      if(r){ r.value='ranged'; r.dispatchEvent(new Event('change',{bubbles:true})); }
    }""")
    pg.wait_for_timeout(800)
    labels = pg.evaluate("""()=>[...document.querySelector('#v-forge iframe')
      .contentDocument.querySelectorAll('label')].map(l=>l.textContent.trim())""")
    ck("editor says Energy cost, not AP cost",
       any("Energy cost" in l for l in labels) and not any(l == "AP cost" for l in labels),
       str([l for l in labels if "cost" in l.lower()]))
    ck("editor says Armor Penetration",
       any("Armor Penetration" in l for l in labels),
       str([l for l in labels if "enetration" in l]))

    stat = pg.evaluate(f"""()=>{{
      var c={B}.fromSchema({{cardType:'hero',name:'E',combatRoles:['melee']}});
      var T={B}.typeOf(c);
      return T.stats.map(s=>s.abbr);
    }}""")
    ck("Hero stat bar shows +NRG", "+NRG" in stat, str(stat))
    ck("Hero stat bar no longer shows +AP", "+AP" not in stat, str(stat))

    # ---------- schema round trip ----------
    out = pg.evaluate(f"""()=>{{
      var c={B}.fromSchema({{cardType:'hero',name:'E',combatRoles:['ranged'],
        entries:[{{name:'Shot',kind:'Active',role:'ranged',
          energyCost:'2',armorPenetration:'3'}}]}});
      var s={B}.toSchema ? null : null;
      return [c.abilities[0].cost, c.abilities[0].pen];
    }}""")
    ck("new keys read correctly", out == ["2", "3"], str(out))

    old = pg.evaluate(f"""()=>{{
      var c={B}.fromSchema({{cardType:'hero',name:'O',combatRoles:['ranged'],
        entries:[{{name:'Old',kind:'Active',role:'ranged',
          apCost:'2',penetration:'3'}}]}});
      return [c.abilities[0].cost, c.abilities[0].pen];
    }}""")
    ck("old files still import correctly", old == ["2", "3"], str(old))

    mixed = pg.evaluate(f"""()=>{{
      /* a file written mid-transition: the new key must win, and an old apCost
         must never be read as Armor Penetration */
      var c={B}.fromSchema({{cardType:'hero',name:'M',combatRoles:['ranged'],
        entries:[{{name:'Mix',kind:'Active',role:'ranged',
          apCost:'5',energyCost:'2',armorPenetration:'1'}}]}});
      return [c.abilities[0].cost, c.abilities[0].pen];
    }}""")
    ck("new keys take precedence over old ones", mixed == ["2", "1"], str(mixed))

    # ---------- rendering ----------
    ink = pg.evaluate(f"""()=>{{
      function px(o){{var c={B}.fromSchema(o);var cv={B}.renderToOffscreen(c,140,false);
        var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=4) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;}}
      var none={{cardType:'hero',name:'R',combatRoles:['ranged'],
        entries:[{{name:'A',kind:'Active',role:'ranged',text:'x'}}]}};
      var nrg=JSON.parse(JSON.stringify(none));
      nrg.entries[0].energyCost='2';
      var ap=JSON.parse(JSON.stringify(none));
      ap.entries[0].armorPenetration='3';
      return [px(none),px(nrg),px(ap)];
    }}""")
    ck("an Energy cost prints on the card", ink[0] != ink[1])
    ck("an Armor Penetration value prints on the card", ink[0] != ink[2])

    # ---------- Handbook ----------
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(1200)
    pg.locator("#q").fill("Energy"); pg.wait_for_timeout(700)
    ck("Handbook covers Energy", pg.locator("#toc .res").count() > 0)
    pg.locator("#q").fill("Armor Penetration"); pg.wait_for_timeout(700)
    ck("Handbook covers Armor Penetration", pg.locator("#toc .res").count() > 0)
    pg.locator("#q").fill(""); pg.wait_for_timeout(500)

    body = pg.locator("#mbody").inner_text()
    # the term should survive only where the change itself is explained
    hits = body.count("Action Points")
    ck("Action Points survives only as an explanation of the rename", hits <= 2,
       f"{hits} mentions")
    ck("the rename is explained for anyone holding an old card",
       "AP now means Armor Penetration" in body)

    # glossary carries the retired meaning
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator('.lt[data-page="gloss"]').click(); pg.wait_for_timeout(800)
    pg.locator("#glq").fill("Armor Penetration"); pg.wait_for_timeout(600)
    gl = pg.locator("#gllist").inner_text()
    ck("Glossary defines Armor Penetration", "Armor Penetration" in gl, gl[:80])
    ck("Glossary explains what AP used to mean",
       "Action Points" in gl or "Energy" in gl, gl[:200])

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"ITERATION 1 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
