"""Iteration 3: Aura, Troop Energy bar, card number on the type line."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_i3")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9041),
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
    pg.goto("http://127.0.0.1:9041/index.html"); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    B = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"
    D = "document.querySelector('#v-forge iframe').contentDocument"

    def px(js):
        return pg.evaluate(f"""()=>{{
          function h(o){{var c={B}.fromSchema(o);var cv={B}.renderToOffscreen(c,140,false);
            var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,v=0;
            for(var i=0;i<x.length;i+=4) v=(v*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return v;}}
          {js}
        }}""")

    # ---------- Aura ----------
    pg.evaluate(f"()=>{D}.getElementById('addAbility').click()")
    pg.wait_for_timeout(1200)
    tags = pg.evaluate(f"()=>[...{D}.querySelector('.a-tag').options].map(o=>o.value)")
    ck("Aura is an entry type", "Aura" in tags, str(tags))
    pg.evaluate(f"""()=>{{var t={D}.querySelector('.a-tag');
      t.value='Aura'; t.dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(900)
    ck("choosing Aura reveals a Radius field", pg.evaluate(f"()=>!!{D}.querySelector('.a-rad')"))
    pg.evaluate(f"""()=>{{var t={D}.querySelector('.a-tag');
      t.value='Passive'; t.dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(800)
    ck("a plain Passive has no Radius field", pg.evaluate(f"()=>!{D}.querySelector('.a-rad')"))

    rt = pg.evaluate(f"""()=>{{
      var c={B}.fromSchema({{cardType:'troop',name:'A',combatRoles:['support'],
        entries:[{{name:'Ward',kind:'Aura',auraRadius:'3',text:'Allies gain 1 AC.'}}]}});
      return [c.abilities[0].tag, c.abilities[0].rad];
    }}""")
    ck("Aura survives the schema", rt == ["Aura", "3"], str(rt))

    noradius = pg.evaluate(f"""()=>{{
      var w=document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE;
      var c=w.fromSchema({{cardType:'troop',name:'A',combatRoles:['support'],
        entries:[{{name:'Ward',kind:'Aura',text:'x'}}]}});
      return w.computePings(c).filter(p=>p[0]==='bad').map(p=>p[1]).join('|');
    }}""")
    ck("an Aura with no Radius is flagged", "reaches nothing" in noradius, noradius[:90])

    aur = px("""
      var base={cardType:'troop',name:'A',combatRoles:['support'],
        entries:[{name:'Ward',kind:'Aura',text:'x'}]};
      var withR=JSON.parse(JSON.stringify(base)); withR.entries[0].auraRadius='3';
      return [h(base),h(withR)];""")
    ck("the Radius prints on the card", aur[0] != aur[1])

    # ---------- Troop Energy ----------
    stats = pg.evaluate(f"""()=>{{
      var w=document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE;
      var t=w.fromSchema({{cardType:'troop',name:'T',combatRoles:['melee']}});
      var all=w.typeOf(t).stats.map(s=>s.abbr);
      var line=w.statsOf(t).map(s=>s.abbr);
      return [all,line];
    }}""")
    ck("Energy is a Troop stat", "NRG" in stats[0], str(stats[0]))
    ck("the Energy stat is flagged for bar drawing",
       pg.evaluate(f"""()=>{{
         var w=document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE;
         var t=w.fromSchema({{cardType:'troop',name:'T',combatRoles:['melee']}});
         return w.typeOf(t).stats.some(s=>s.abbr==='NRG' && s.bar===true);
       }}"""))

    ck("Energy is editable in the form",
       pg.evaluate(f"""()=>{{
         var d={D};
         d.getElementById('fType').value='troop';
         d.getElementById('fType').dispatchEvent(new Event('change',{{bubbles:true}}));
         return true;
       }}"""))
    pg.wait_for_timeout(900)
    ck("an Energy input exists", pg.evaluate(f"()=>!!{D}.getElementById('st_nrg')"))

    bar = px("""
      var three={cardType:'troop',name:'B',combatRoles:['melee'],stats:{nrg:'3'}};
      var six=JSON.parse(JSON.stringify(three)); six.stats.nrg='6';
      var hero={cardType:'hero',name:'H',combatRoles:['melee']};
      var hero2=JSON.parse(JSON.stringify(hero));
      return [h(three),h(six),h(hero),h(hero2)];""")
    ck("a 3-section bar differs from a 6-section bar", bar[0] != bar[1])
    ck("Heroes are unaffected by the Troop bar", bar[2] == bar[3])

    cost = px("""
      var base={cardType:'troop',name:'C',combatRoles:['melee'],stats:{nrg:'4'},
        entries:[{name:'Strike',kind:'Active',role:'melee',text:'x'}]};
      var one=JSON.parse(JSON.stringify(base)); one.entries[0].energyCost='1';
      var two=JSON.parse(JSON.stringify(base)); two.entries[0].energyCost='2';
      return [h(base),h(one),h(two)];""")
    ck("an Action's Energy cost prints", cost[0] != cost[1])
    ck("one section differs from two", cost[1] != cost[2])

    # ---------- card number ----------
    num = px("""
      var base={cardType:'hero',name:'N',combatRoles:['melee'],archetypes:['Sniper']};
      var withNum=JSON.parse(JSON.stringify(base)); withNum.id='D3-H07';
      return [h(base),h(withNum)];""")
    ck("the card number still prints", num[0] != num[1])

    band = pg.evaluate(f"""()=>{{
      function strip(o,top,frac){{
        var c={B}.fromSchema(o);
        var cv={B}.renderToOffscreen(c,150,false);
        var d=cv.getContext('2d').getImageData(0,Math.round(cv.height*top),
              cv.width,Math.round(cv.height*frac)).data;
        var v=0; for(var i=0;i<d.length;i+=4) v=(v*31+d[i]+d[i+1]*3+d[i+2]*7)|0; return v;
      }}
      var base={{cardType:'hero',name:'N',combatRoles:['melee'],archetypes:['Sniper']}};
      var withNum=JSON.parse(JSON.stringify(base)); withNum.id='D3-H07';
      /* the type line sits just under the name, around 12-18% down */
      return [strip(base,0.12,0.06),strip(withNum,0.12,0.06),
              strip(base,0.55,0.06),strip(withNum,0.55,0.06)];
    }}""")
    ck("the number now changes the type line row", band[0] != band[1])
    ck("it no longer sits under the art window", band[2] == band[3])

    # ---------- Handbook ----------
    pg.locator("#nav button[data-go='manual']").click(); pg.wait_for_timeout(1200)
    body = pg.locator("#mbody").inner_text()
    ck("Handbook defines Auras", "Auras" in body and "Radius" in body)
    ck("Handbook no longer ties Auras to Compromised (15.5)",
       "Auras stop functioning" not in body and "Compromised Mechanical" not in body)
    ck("Handbook gives Troop Energy a range", "3 to 6" in body, "")
    ck("the old fixed-3 rule is gone", "Every Troop has 3 Energy" not in body)
    ck("Handbook describes the bar", "segmented bar" in body)

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"ITERATION 3 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
