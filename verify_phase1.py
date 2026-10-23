"""Phase 1 verification: Identity tab rebuild in the forked Card Forge."""
import http.server, socketserver, threading, functools, pathlib, shutil, json, sys
from playwright.sync_api import sync_playwright

TMP = pathlib.Path("/tmp/serve_p1")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
H = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP))
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 8981), H); threading.Thread(target=srv.serve_forever, daemon=True).start()

ok, bad = [], []
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

# an old-format card carrying everything Phase 1 removes
LEGACY = """()=>localStorage.setItem('keter-cardforge-heroes', JSON.stringify({
 "Rictus":{v:6,type:"hero",name:"Rictus",title:"Augmented Butcher",
   aff:"3",arch:"Berserker",arch2:"Cyborg",mech:true,level:"3",
   roles:{melee:true},stats:{hp:"44",ac:"11",ldr:"1"},abilities:[]}
}))"""

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:8981/index.html"); pg.wait_for_timeout(1600)
    pg.evaluate(LEGACY)
    pg.reload(); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    fr = pg.frame_locator("#v-forge iframe")

    # --- #16 Title gone ---
    ck("#16 Title input removed from the form", fr.locator("#fTitle").count() == 0)

    # --- #15 Mechanical is no longer a tag ---
    ck("#15 Mechanical checkbox removed", fr.locator("#fMech").count() == 0)
    # Iteration 1 moved Mechanical from Archetype to Subtype, so the option is
    # gone by design and the subtype control replaces it
    ck("#15 Mechanical is no longer an Archetype option",
       fr.locator("#fArch option[value='Mechanical']").count() == 0)
    ck("#15 Mechanical is a Subtype option",
       fr.locator("#fSubtype option[value='mechanical']").count() == 1)

    # --- #17 one control, chips ---
    ck("#17 second Archetype select removed", fr.locator("#fArch2").count() == 0)
    ck("#17 chip container present", fr.locator("#archChips").count() == 1)

    # --- migration of the legacy card ---
    loaded = pg.evaluate("""()=>{
      var w=document.querySelector('#v-forge iframe').contentWindow;
      var all=JSON.parse(localStorage.getItem('keter-cardforge-heroes'));
      var c=w.KETER_BRIDGE.migrate(all['Rictus']);
      return {arches:c.arches, arch:c.arch, arch2:c.arch2, mech:c.mech, title:c.title};
    }""")
    ck("#17 legacy arch/arch2 merged into a list",
       loaded["arches"] == ["Berserker", "Cyborg", "Mechanical"], str(loaded["arches"]))
    ck("#15 legacy Mechanical tag became an Archetype",
       "Mechanical" in (loaded["arches"] or []))
    ck("#16 legacy Title dropped", loaded.get("title") in (None, ""), str(loaded.get("title")))
    ck("old fields cleared", not loaded.get("arch") and not loaded.get("mech"),
       str(loaded))

    # --- schema round trip ---
    rt = pg.evaluate("""()=>{
      var w=document.querySelector('#v-forge iframe').contentWindow;
      var B=w.KETER_BRIDGE;
      var c=B.fromSchema({cardType:'hero',name:'Test',title:'Old Title',
        archetypes:['Sniper','Tinkerer','Healer','Extra'],
        mechanical:true, combatRoles:['ranged'], level:2});
      return {arches:c.arches, title:c.title};
    }""")
    ck("#17 import caps Archetypes at three",
       len(rt["arches"]) == 3, str(rt["arches"]))
    ck("#16 import drops Title", rt.get("title") in (None, ""), str(rt.get("title")))

    # --- the control itself ---
    pg.wait_for_timeout(400)
    sel = fr.locator("#fArch")
    ck("#17 prompt text updated",
       "add an Archetype" in fr.locator("#fArch option").first.inner_text(),
       fr.locator("#fArch option").first.inner_text())
    sel.select_option("Sniper"); pg.wait_for_timeout(500)
    ck("#17 choosing adds a chip", fr.locator(".archchip").count() >= 1,
       fr.locator(".archchip").count())
    sel.select_option("Healer"); pg.wait_for_timeout(400)
    sel.select_option("Tinkerer"); pg.wait_for_timeout(400)
    n = fr.locator(".archchip").count()
    ck("#17 three chips accepted", n == 3, f"n={n}")
    ck("#17 select disabled at three",
       fr.locator("#fArch").evaluate("e=>e.disabled") is True)
    ck("#17 cap is explained",
       fr.locator("#archHint").evaluate("e=>getComputedStyle(e).display") != "none")
    fr.locator(".archchip").first.click(); pg.wait_for_timeout(500)
    ck("#17 tapping a chip removes it", fr.locator(".archchip").count() == 2)
    ck("#17 select re-enabled after removal",
       fr.locator("#fArch").evaluate("e=>e.disabled") is False)

    # --- #25 labels ---
    labels = fr.locator("#aetherWrap label").all_inner_texts()
    up = [l.upper() for l in labels]
    ck("#25a Generic renamed to Any Affinity", "ANY AFFINITY" in up, str(labels))
    ck("#25a Affinity 1 renamed to Dedicated Affinity",
       "DEDICATED AFFINITY" in up, str(labels))
    ck("#25b cost is explained in the form",
       "Aether cost" in fr.locator("#aetherWrap .hint").inner_text(),
       fr.locator("#aetherWrap .hint").inner_text()[:60])

    # --- rendering ---
    shot = pg.evaluate("""()=>{
      var w=document.querySelector('#v-forge iframe').contentWindow;
      var B=w.KETER_BRIDGE;
      var c=B.fromSchema({cardType:'hero',name:'Render Test',
        archetypes:['Sniper','Tinkerer','Mechanical'],combatRoles:['ranged'],level:1});
      var cv=B.renderToOffscreen(c,72,false);
      return [cv.width>100, cv.height>100];
    }""")
    ck("card with three Archetypes still renders", all(shot), str(shot))

    # --- exported schema shape ---
    out = pg.evaluate("""()=>{
      var w=document.querySelector('#v-forge iframe').contentWindow;
      var B=w.KETER_BRIDGE;
      var c=B.fromSchema({cardType:'hero',name:'Round',archetypes:['Mechanical'],
        combatRoles:['melee'],level:1});
      return JSON.stringify(c.arches);
    }""")
    # an old card carrying Mechanical as an Archetype now migrates to the subtype
    mech = pg.evaluate(f"""()=>{{
      var w=document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE;
      var c=w.fromSchema({{cardType:'troop',name:'M',archetypes:['Mechanical'],
        combatRoles:['melee'],level:1}});
      return [c.origin, c.arches];
    }}""")
    # Revision 15.5: what a Unit is made of is lore, kept as its origin
    ck("#15 an old Mechanical card keeps Mechanical as lore (its origin)",
       mech[0]=="Mechanical" and "Mechanical" not in mech[1], str(mech))

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"PHASE 1 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
# part one done; part two follows


# ---------------------------------------------------------------- part 2
import http.server as _h
srv2 = Q(("127.0.0.1", 8987), functools.partial(_h.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv2.serve_forever, daemon=True).start()
ok2, bad2 = [], []
def ck2(n, c, det=""):
    (ok2 if c else bad2).append(n + ((" — " + str(det)) if det and not c else ""))

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:8987/index.html"); pg.wait_for_timeout(1600)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    fr = pg.frame_locator("#v-forge iframe")
    B = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"

    # --- #3 Attack Range off the stat bar ---
    troop_stats = pg.evaluate(f"()=>{{var c={B}.fromSchema({{cardType:'troop',name:'T'}});return Object.keys(c.stats||{{}});}}")
    ck2("#3 Attack Range gone from Troop stats", "rng" not in troop_stats, str(troop_stats))

    # --- #2 Troops price Actions in AP ---
    pg.evaluate("""()=>{var d=document.querySelector('#v-forge iframe').contentDocument;
      d.getElementById('fType').value='troop';
      d.getElementById('fType').dispatchEvent(new Event('change',{bubbles:true}));}""")
    pg.wait_for_timeout(700)
    fr.locator("#addAbility").click() if fr.locator("#addAbility").count() else None
    pg.wait_for_timeout(500)
    ck2("#2 Troop Actions show an AP cost field", fr.locator(".a-cost").count() >= 1,
        fr.locator(".a-cost").count())

    # --- #3 per-Role fields ---
    if fr.locator(".a-role").count():
        fr.locator(".a-role").first.select_option("ranged"); pg.wait_for_timeout(600)
        ck2("#3 Ranged Action gets Range", fr.locator(".a-rng").count() >= 1)
        ck2("#3 Ranged Action gets To-Hit", fr.locator(".a-hit").count() >= 1)
        ck2("#3 Ranged Action gets Penetration", fr.locator(".a-pen").count() >= 1)
        fr.locator(".a-role").first.select_option("support"); pg.wait_for_timeout(600)
        ck2("#3 Support Action has no Range", fr.locator(".a-rng").count() == 0)
        ck2("#3 Support Action has no Penetration", fr.locator(".a-pen").count() == 0)
        fr.locator(".a-role").first.select_option("melee"); pg.wait_for_timeout(600)
        ck2("#3 Melee Action gets Penetration but no Range",
            fr.locator(".a-pen").count() >= 1 and fr.locator(".a-rng").count() == 0)

    # --- #3 schema round trip ---
    rt = pg.evaluate(f"""()=>{{
      var c={B}.fromSchema({{cardType:'troop',name:'Gunner',combatRoles:['ranged'],
        entries:[{{name:'Volley',kind:'Active',role:'ranged',damage:'6',
          apCost:'2',attackRange:'8',toHit:'11',penetration:'3'}}]}});
      var a=c.abilities[0];
      return [a.rng,a.hit,a.pen,a.cost,a.dmg];
    }}""")
    ck2("#3 per-Action stats survive a schema round trip",
        rt == ["8", "11", "3", "2", "6"], str(rt))

    # --- #3 strip renders and grows the card content ---
    dims = pg.evaluate(f"""()=>{{
      var plain={B}.fromSchema({{cardType:'troop',name:'A',combatRoles:['ranged'],
        entries:[{{name:'Shot',kind:'Active',role:'ranged',text:'Fire once.'}}]}});
      var full={B}.fromSchema({{cardType:'troop',name:'A',combatRoles:['ranged'],
        entries:[{{name:'Shot',kind:'Active',role:'ranged',text:'Fire once.',
          damage:'6',attackRange:'8',toHit:'11',penetration:'3'}}]}});
      var c1={B}.renderToOffscreen(plain,72,false);
      var c2={B}.renderToOffscreen(full,72,false);
      function ink(cv){{var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=4) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;}}
      return [c1.width,c2.width,ink(c1),ink(c2)];
    }}""")
    ck2("#3 card with stats renders", dims[1] > 100)
    ck2("#3 the strip actually changes the card", dims[3] != dims[2],
        f"plain={dims[2]} full={dims[3]}")

    # --- #3 Penetration 0 does not print ---
    pen0 = pg.evaluate(f"""()=>{{
      var z={B}.fromSchema({{cardType:'troop',name:'A',combatRoles:['melee'],
        entries:[{{name:'Hit',kind:'Active',role:'melee',text:'x',penetration:'0'}}]}});
      var t={B}.fromSchema({{cardType:'troop',name:'A',combatRoles:['melee'],
        entries:[{{name:'Hit',kind:'Active',role:'melee',text:'x',penetration:'2'}}]}});
      function ink(c){{var cv={B}.renderToOffscreen(c,72,false);
        var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=4) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;}}
      return [ink(z),ink(t)];
    }}""")
    ck2("#3 Penetration 0 prints nothing, 2 does", pen0[1] != pen0[0], str(pen0))

    # --- #11 Token ---
    ck2("#11 Token checkbox present for Troops", fr.locator("#fToken").count() == 1)
    tok = pg.evaluate(f"""()=>{{
      var c={B}.fromSchema({{cardType:'troop',name:'Servo',token:true,combatRoles:['melee'],
        aetherCost:{{generic:3}}}});
      return c.token===true;
    }}""")
    ck2("#11 token survives the schema", tok)
    tokink = pg.evaluate(f"""()=>{{
      function ink(o){{var c={B}.fromSchema(o);var cv={B}.renderToOffscreen(c,72,false);
        var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=4) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;}}
      var base={{cardType:'troop',name:'Servo',combatRoles:['melee'],aetherCost:{{generic:3}}}};
      var t=JSON.parse(JSON.stringify(base)); t.token=true;
      return [ink(base),ink(t)];
    }}""")
    ck2("#11 a Token card renders differently from a costed one",
        tokink[0] != tokink[1], str(tokink))

    # --- #11 tokens excluded from decks ---
    pg.evaluate("""()=>localStorage.setItem('keter-cardforge-heroes',JSON.stringify({
      "Hero":{v:6,type:"hero",name:"Hero",arches:[],roles:{melee:true},stats:{ldr:"4"},abilities:[]},
      "Real":{v:6,type:"troop",name:"Real",arches:[],roles:{melee:true},stats:{},abilities:[]},
      "Tok":{v:6,type:"troop",name:"Tok",token:true,arches:[],roles:{melee:true},stats:{},abilities:[]}
    }))""")
    pg.reload(); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(800)
    ck2("#11 Compendium labels tokens", "token" in pg.locator("#clist").inner_text().lower(),
        pg.locator("#clist").inner_text()[:80])
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(300); pg.locator('.lt[data-page="deck"]').click(); pg.wait_for_timeout(600)
    # New Loadout, then Add Hero — the Strike Team screen replaced the old
    # per-team "Choose a Hero" button
    pg.locator("#dkAdd").click(); pg.wait_for_timeout(500)
    pg.locator("#dkAdd").click(); pg.wait_for_timeout(500)
    pg.locator("[data-pick]").first.click(); pg.wait_for_timeout(600)
    pg.locator('[data-open="deck"]').click(); pg.wait_for_timeout(500)
    pg.locator("#addCards").click(); pg.wait_for_timeout(600)
    names = " ".join(pg.locator("[data-pick] b").all_inner_texts())
    ck2("#11 tokens are not offered for a Deck", "Tok" not in names, names)
    ck2("#11 ordinary Troops still are", "Real" in names, names)

    real = [e for e in errs if "favicon" not in e.lower()]
    ck2("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv2.shutdown()
print(f"PHASE 1B PASS {len(ok2)}  FAIL {len(bad2)}")
for x in bad2: print("  ✗", x)
sys.exit(1 if (bad or bad2) else 0)
