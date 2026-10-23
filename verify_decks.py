"""Handbook Revision 14.0 in the Card Forge and POI Sandbox: the Elite type, the
Mini-Boss label, Action use costs, chip values, spawn-tile Skull Levels, and the
automatic battlefield size. (This file used to test the starter decks, which
were removed at Cameron's request until there are more cards to build them.)"""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, re
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_tools14")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9877),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

# ---- the compendium ----
comp={c["name"]:c for c in json.load(open("compendium_full.json"))["cards"]}
ck("Dross has the Handbook's minimum of 1 Action Slot",
   comp["Dross, the Forge-Blind"]["stats"].get("slots")=="1")
ck("Ledger Call is a Command", comp["Ledger Call"]["cardType"]=="command")
ck("Recall is a Command", comp["Recall"]["cardType"]=="command")

# ---- no affinity restriction left in how cards print ----
forge=open("forge_v3.html",encoding="utf-8").read()
ck("the type line no longer prints a District restriction",
   "D.name.replace(/^\\d+ · /,'')+' '+plural+' only'" not in forge)
ck("the Starter-deck feature is gone from the app",
   "STARTER_DECKS" not in open("shell.html",encoding="utf-8").read())

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9877/"); pg.wait_for_timeout(2000)

    # ---- the Forge ----
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    F=pg.frame_locator('#v-forge iframe'); W="document.querySelector('#v-forge iframe').contentWindow"
    opts=F.locator("#fType option").all_inner_texts()
    ck("Elite is a card type", "Elite" in opts, str(opts))
    ck("it sits between Enemy and Mini-Boss",
       opts.index("Enemy") < opts.index("Elite") < opts.index("Mini-boss"), str(opts))
    ck("Boss appears once", opts.count("Boss")==1, str(opts))
    r=pg.evaluate(f"""()=>{{
      var B={W}.KETER_BRIDGE;
      function trip(o){{ return B.toSchema(B.fromSchema(o)); }}
      var e=trip({{cardType:'elite',name:'E',stats:{{hp:'40',ac:'10',move:'4',will:'4',int:'3'}}}});
      return {{type:e.cardType, rarity:e.rarity, hp:e.stats.hp}};
    }}""")
    ck("an Elite round-trips as an Elite", r["type"]=="elite", str(r))
    ck("an Elite has no Rarity, like any encounter", not r["rarity"], str(r))

    r=pg.evaluate(f"""()=>{{
      var B={W}.KETER_BRIDGE;
      function trip(o){{ return B.toSchema(B.fromSchema(o)).useCost; }}
      return {{
        both: trip({{cardType:'action',name:'A',aetherCost:{{generic:2,affinity:0}},
                     entries:[{{kind:'Active',text:'x',energyCost:'2'}}]}}),
        aether: trip({{cardType:'action',name:'B',aetherCost:{{generic:2,affinity:0}},
                     entries:[{{kind:'Active',text:'x'}}]}}),
        energy: trip({{cardType:'action',name:'C',entries:[{{kind:'Active',text:'x',energyCost:'1'}}]}}),
        chosen: trip({{cardType:'action',name:'D',useCost:'aether',aetherCost:{{generic:1,affinity:0}},
                     entries:[{{kind:'Active',text:'x',energyCost:'1'}}]}}),
        notAction: trip({{cardType:'troop',name:'T'}}),
        xCost: trip({{cardType:'action',name:'X',aetherCost:{{generic:'X',affinity:0}},
                     entries:[{{kind:'Active',text:'x'}}]}})
      }};
    }}""")
    ck("an old Action with both costs reads as both", r["both"]=="both", str(r))
    ck("one with only Aether reads as Aether", r["aether"]=="aether", str(r))
    ck("one with only Energy reads as Energy", r["energy"]=="energy", str(r))
    ck("a chosen use cost is kept", r["chosen"]=="aether", str(r))
    ck("only Actions carry a use cost", r["notAction"] is None, str(r))
    ck("an X cost counts as an Aether cost", r["xCost"]=="aether", str(r))

    F.locator("#fType").select_option("action"); pg.wait_for_timeout(500)
    ck("Actions show the use-cost control", F.locator("#useCostWrap").is_visible())
    F.locator("#fUseCost").select_option("energy"); pg.wait_for_timeout(300)
    ck("Energy-only hides the Aether fields", not F.locator("#aetherWrap").is_visible())
    F.locator("#fUseCost").select_option("both"); pg.wait_for_timeout(300)
    ck("Both shows them", F.locator("#aetherWrap").is_visible())
    F.locator("#fType").select_option("troop"); pg.wait_for_timeout(400)
    ck("other types do not", not F.locator("#useCostWrap").is_visible())

    # ---- chip values, and the Forge and the rules agreeing on them ----
    F.locator("#fType").select_option("sphere"); pg.wait_for_timeout(400)
    ck("chips show a value field", F.locator("#chipValWrap").is_visible())
    ck("with the guideline in it", "Guideline" in (F.locator("#fChipVal").get_attribute("placeholder") or ""))
    F.locator("#fType").select_option("troop"); pg.wait_for_timeout(300)
    mism=pg.evaluate(f"""()=>{{
      var B={W}.KETER_BRIDGE, R=window.KETER_RULES, out=[];
      ['common','uncommon','rare','epic','legendary','mythic'].forEach(function(rar){{
        for(var lv=1;lv<=6;lv++){{
          var card=B.fromSchema({{cardType:'sphere',name:'x',level:lv,rarity:rar}});
          var sch=B.toSchema(card);
          var a=B.chipAether(card), b=R.chipValue(sch);
          if(a!==b) out.push(rar+' L'+lv+': forge '+a+' rules '+b);
        }}
      }});
      [0,4,9,10,40].forEach(function(v){{
        var card=B.fromSchema({{cardType:'sphere',name:'x',level:3,rarity:'rare',aetherValue:v}});
        var sch=B.toSchema(card);
        if(B.chipAether(card)!==R.chipValue(sch)) out.push('value '+v+': forge '+B.chipAether(card)+' rules '+R.chipValue(sch));
      }});
      return out;
    }}""")
    ck("the Forge and the rules agree on every chip's value", mism==[], str(mism[:4]))
    r=pg.evaluate("()=>({g:KETER_RULES.chipValue({level:6,rarity:'mythic'}), z:KETER_RULES.chipValue({aetherValue:0}), cap:KETER_RULES.chipValue({aetherValue:40})})")
    ck("the guideline tops out at 8", r["g"]==8, str(r))
    ck("a printed 0 is allowed", r["z"]==0, str(r))
    ck("nothing exceeds 10", r["cap"]==10, str(r))

    # ---- the Sandbox ----
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3400)
    W="document.querySelector('#v-poi iframe').contentWindow"
    G=pg.frame_locator('#v-poi iframe')
    ck("there is a Spawn Level tool", G.locator('.tool[data-tool="spawnlvl"]').count()==1)
    pg.evaluate(f"""()=>{{
      var T={W}.KETER_POI_TEST, S=T.state(); S.hexes.clear();
      for(var q=-3;q<=3;q++) for(var r=-3;r<=3;r++) if(Math.abs(q+r)<=3) S.hexes.set(T.K(q,r),{{c:null}});
      S.hexes.set(T.K(0,0),{{c:0}}); S.hexes.set(T.K(-1,1),{{c:3}});
      T.redraw();
    }}""")
    G.locator('.tool[data-tool="spawnlvl"]').click(); pg.wait_for_timeout(300)
    pg.evaluate("()=>{var a=document.querySelector('#v-poi iframe').contentDocument.querySelector('aside'); if(a) a.classList.add('collapsed');}")
    pg.wait_for_timeout(400)
    def tap(q,r):
        pg.evaluate(f"()=>{W}.KETER_POI_TEST.reveal({q},{r})"); pg.wait_for_timeout(120)
        pt=pg.evaluate(f"()=>{W}.KETER_POI_TEST.cellClient({q},{r})")
        box=pg.locator('#v-poi iframe').bounding_box()
        pg.mouse.click(box['x']+pt['x'], box['y']+pt['y']); pg.wait_for_timeout(160)
    lvl=lambda q,r: pg.evaluate(f"()=>{{var T={W}.KETER_POI_TEST; return T.spawnLevelOf(T.state().hexes.get(T.K({q},{r})));}}")
    ck("a spawn tile starts at Skull Level 1", lvl(0,0)==1)
    tap(0,0)
    ck("a tap raises it", lvl(0,0)==2, lvl(0,0))
    for _ in range(4): tap(0,0)
    ck("up to 6", lvl(0,0)==6, lvl(0,0))
    tap(0,0)
    ck("and past 6 back to 1", lvl(0,0)==1, lvl(0,0))
    tap(-1,1)
    ck("other tiles are left alone",
       pg.evaluate(f"()=>{{var T={W}.KETER_POI_TEST; return T.state().hexes.get(T.K(-1,1)).lvl===undefined;}}"))
    ck("with the reason given", "Only Enemy Spawn" in (G.locator("#status").text_content() or ""))
    tap(0,0); tap(0,0)
    snap=pg.evaluate(f"()=>{W}.KETER_POI_TEST.snapshot()")
    saved={h[0]:h[1] for h in snap["hexes"]}
    ck("the level is saved with the floor", saved.get("0,0",{}).get("lvl")==3, str(saved.get("0,0")))
    ck("the battlefield size is saved too", snap.get("battlefieldSize")=="Small", str(snap.get("battlefieldSize")))
    for n,want in ((37,"Small"),(150,"Medium"),(300,"Large")):
        pg.evaluate(f"""()=>{{var T={W}.KETER_POI_TEST, S=T.state(); S.hexes.clear();
          for(var i=0;i<{n};i++) S.hexes.set(T.K(i%40,Math.floor(i/40)),{{c:null}}); T.redraw();}}""")
        ck(f"{n} tiles read as {want}", pg.evaluate(f"()=>{W}.KETER_POI_TEST.effectiveFloorSize()")==want)
    ck("the Auto option says what it chose",
       "Large (300 tiles)" in (G.locator("#fSizeCat option").first.text_content() or ""))
    poi=open("poi_v19.html",encoding="utf-8").read()
    ck("the invented unit cap is gone", "caps at '+cap+' Friendly Units" not in poi)
    ck("a Hero-capacity check replaces it", "Every Hero needs one to start on" in poi)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"TOOLS 14.0 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
