"""Handbook 15.1's keyword system: the library, the picker, coloured cards,
scoring from keywords, and the flags on effects that could not be converted."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_keywords")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9929),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

# ---- the library, as data ----
lib=open("keywords.js",encoding="utf-8").read()
for gone in ["SPOOL","Splash"]:
    ck(f"{gone} is listed as withdrawn", f'"{gone}"' in lib)
ck("Amount is not a category", '"amount", label:"Amount"' not in lib and 'k:"amount"' not in lib)
comp=json.load(open("compendium_full.json"))
marked=[e for c in comp["cards"] for e in (c.get("abilities") or c.get("entries") or [])
        if "[[" in (e.get("text") or "")]
flagged=[e for c in comp["cards"] for e in (c.get("abilities") or c.get("entries") or [])
         if e.get("needsReview")]
ck("effects were marked up by the conversion", len(marked)>=40, len(marked))
ck("the audits left no box flagged (14.13: the last four cards were deleted)", len(flagged)==0, len(flagged))
# A number only belongs to a keyword that takes one. "[[Sacrifice]] 1 Troop"
# is correct as written: the 1 counts Troops, and Sacrifice takes no number.
import re as _re
TAKES_NUMBER=["Rooted","Stunned","Slowed","Marked","Pinned","Poisoned","Bleed",
              "Weakened","Sundered","Drained","damage","heal","Push","Chain","AoE","Deploy"]
loose=[(c["name"], e.get("text")) for c in comp["cards"]
       for e in (c.get("abilities") or c.get("entries") or [])
       for m in [_re.search(r'\[\[([^\]]+)\]\]\s*\d', e.get("text") or "")] if m
       and m.group(1).strip() in TAKES_NUMBER]
ck("no keyword that takes a number was left with it loose", not loose, str(loose[:2]))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9929/"); pg.wait_for_timeout(2000)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    F=pg.frame_locator('#v-forge iframe'); W="document.querySelector('#v-forge iframe').contentWindow"

    # ---- the library reaches every surface ----
    for where,expr in (("the Forge", f"typeof {W}.KETER_KW"), ("the app", "typeof window.KETER_KW")):
        ck(f"the keyword library is available to {where}", pg.evaluate("()=>"+expr)=="object")
    cats=pg.evaluate(f"()=>{W}.KETER_KW.CATEGORIES.map(function(c){{return c.k;}})")
    ck("seven categories, as Revision 15.4 says",
       cats==["condition","target","effect","status","duration","modifier","stats"], str(cats))
    ck("every keyword names its category and its number's meaning",
       pg.evaluate(f"""()=>{W}.KETER_KW.KEYWORDS.every(function(k){{
         return k.cat && k.desc && (k.num===null || k.numLabel); }})"""))

    # ---- parsing ----
    r=pg.evaluate(f"""()=>{{
      var K={W}.KETER_KW;
      var t='[[if damaged]], [[target enemy]] takes [[damage 5]] and [[Rooted 3]]. Flavour.';
      return {{parts:K.parse(t).filter(function(p){{return p.type==='kw';}})
                 .map(function(p){{ return p.name+'/'+(p.kw?p.kw.cat:'?')+'/'+p.n; }}),
               rendered:K.render(t),
               retired:K.parse('Gains [[SPOOL]]1').filter(function(p){{return p.retired;}}).length}};
    }}""")
    # Revision 15.6: the old one-piece Condition is read as grammar
    ck("a keyword resolves to its category",
       r["parts"]==["if/condition/null","the target/target/null","takes damage/condition/null",
                    "target enemy/target/null","damage/effect/5","Rooted/status/3"], str(r["parts"]))
    ck("the printed line drops the brackets", "[[" not in r["rendered"], r["rendered"])
    ck("and reads as written",
       r["rendered"].startswith("If the target takes damage, target enemy takes damage 5 and Rooted 3"), r["rendered"])
    ck("a withdrawn keyword is recognised as withdrawn", r["retired"]==1)

    # ---- the picker ----
    F.locator("#fType").select_option("action"); pg.wait_for_timeout(600)
    if F.locator(".ability").count()==0:
        F.locator("#addAbility").click(); pg.wait_for_timeout(500)
    groups=F.locator(".a-kw optgroup").evaluate_all("els=>els.map(e=>e.label)")
    ck("the picker groups keywords by category",
       groups==["Condition","Target","Effect","Status","Duration","Modifier","Stats","Target \u00b7 Archetypes"], str(groups))
    # 15.4: a status's number is its strength (Rooted has none)
    F.locator(".a-kw").first.select_option("Poisoned"); pg.wait_for_timeout(450)
    ck("choosing one asks for its number", F.locator(".a-kwnum").is_visible())
    ck("and says what that number means",
       F.locator(".a-kwnum label").inner_text().lower()=="damage each turn",
       F.locator(".a-kwnum label").inner_text())
    ck("with the keyword explained", len(F.locator(".a-kwdesc").inner_text())>20)
    F.locator(".a-kwval").fill("3"); F.locator(".a-kwok").click(); pg.wait_for_timeout(400)
    ck("it inserts as one piece", F.locator(".a-text").input_value().endswith("[[Poisoned 3]]"),
       F.locator(".a-text").input_value()[-30:])
    # 15.4: each stat is its own keyword, asking for an amount up or down
    F.locator(".a-kw").first.select_option("AC"); pg.wait_for_timeout(450)
    ck("a Stats keyword asks for a signed amount", "+" in (F.locator(".a-kwval").get_attribute("placeholder") or ""))
    F.locator(".a-kwval").fill("-2")
    F.locator(".a-kwok").click(); pg.wait_for_timeout(400)
    ck("and writes the stat with its amount, sign kept",
       F.locator(".a-text").input_value().endswith("[[AC -2]]"),
       F.locator(".a-text").input_value()[-24:])
    F.locator(".a-kw").first.select_option("Pierce"); pg.wait_for_timeout(400)
    ck("a keyword with no number goes straight in",
       F.locator(".a-text").input_value().endswith("[[Pierce]]"))

    # ---- the card ----
    r=pg.evaluate(f"""()=>{{
      var w={W}, B=w.KETER_BRIDGE;
      var card=B.fromSchema({{cardType:'action',name:'C',affinities:[{{district:'3',level:1}}],
        useCost:'energy', entries:[{{name:'T',kind:'Active',
        text:'[[if damaged]], [[target enemy]] takes [[damage 5]] and [[Rooted 3]] for [[turns 2]]. Flavour.'}}]}});
      var cv=B.renderToOffscreen(card,150,false);
      var x=cv.getContext('2d'), h=cv.height, wd=cv.width;
      var d=x.getImageData(0,Math.round(h*0.55),wd,Math.round(h*0.40)).data;
      var want={{violet:[176,123,224],cyan:[87,216,227],amber:[224,179,77],
                crimson:[217,79,92],pink:[224,123,200]}}, seen={{}};
      for(var k in want) seen[k]=0;
      for(var i=0;i<d.length;i+=4)
        for(var k in want){{ var cc=want[k];
          if(Math.abs(d[i]-cc[0])<32&&Math.abs(d[i+1]-cc[1])<32&&Math.abs(d[i+2]-cc[2])<32) seen[k]++; }}
      return seen;
    }}""")
    for cat in ["violet","cyan","amber","crimson","pink"]:
        ck(f"the card prints {cat} keywords", r[cat]>20, f"{cat}={r[cat]}")

    # ---- scoring ----
    r=pg.evaluate(f"""()=>{{
      var w={W}, B=w.KETER_BRIDGE, S=w.KETER_SCORE;
      function pts(o){{ return S.scoreCard(B.fromSchema(o),[]); }}
      var base={{cardType:'action',name:'x',aetherCost:{{generic:2,affinity:0}}}};
      return {{
        kw:  pts(Object.assign({{}},base,{{entries:[{{kind:'Active',text:'[[damage 5]]'}}]}})).points,
        more:pts(Object.assign({{}},base,{{entries:[{{kind:'Active',text:'[[damage 5]] and [[Rooted 3]]'}}]}})).points,
        over:pts(Object.assign({{}},base,{{entries:[{{kind:'Active',text:'[[damage 5]]',power:'20'}}]}})).points,
        plain:pts(Object.assign({{}},base,{{entries:[{{kind:'Active',text:'Plain words.'}}]}})).points,
        unscored:pts(Object.assign({{}},base,{{entries:[{{kind:'Active',text:'[[damage 5]]'}}]}})).unscored
      }};
    }}""")
    ck("the score is worked out from the keywords", r["kw"]==5, str(r))
    ck("more keywords score more", r["more"]>r["kw"], str(r))
    ck("a hand-entered Power still overrides it", r["over"]==20, str(r))
    ck("text with no keywords still counts as 4", r["plain"]==4, str(r))
    ck("an effect scored by its keywords is not called unscored", r["unscored"]==0, str(r))

    # ---- the flags ----
    r=pg.evaluate(f"""()=>{{
      var w={W}, B=w.KETER_BRIDGE;
      var card=B.fromSchema({{cardType:'troop',name:'F',aetherCost:{{generic:1,affinity:0}},
        stats:{{hp:'20',ac:'8',nrg:'3',will:'3',move:'3',uslot:'1'}},
        entries:[{{name:'Old',kind:'Active',text:'Gains [[SPOOL 1]] each turn.'}},
                 {{name:'Bare',kind:'Active',text:'Something clever happens.'}},
                 {{name:'Odd',kind:'Active',text:'Applies [[Whatsit 2]].'}}]}});
      return (w.KETER_BRIDGE.pings ? w.KETER_BRIDGE.pings(card)
             : (w.computePings ? w.computePings(card) : [])).map(function(p){{ return p[0]+': '+p[1]; }});
    }}""")
    ck("a withdrawn keyword is flagged", any("withdrawn" in x for x in r), str(r[:2]))
    ck("an unknown keyword is flagged", any("keyword library" in x for x in r), str(r[:3]))
    ck("plain text is flagged as something the Simulator will only log",
       any("no keywords" in x for x in r), str(r[:4]))

    # ---- Revision 15.2 ----
    r=pg.evaluate(f"""()=>{{
      var K={W}.KETER_KW;
      function one(t){{ var p=K.parse(t).filter(function(x){{return x.type==='kw';}})[0];
        return p.name+'|'+(p.kw?p.kw.cat:(p.retired?'retired':'?'))+'|'+p.n; }}
      return {{deploy:one('[[Deploy 2 Aether Battery]]'), remove:one('[[remove Rooted]]'),
               modify:one('[[AC +2]]'), modify2:one('[[+2 AC]]'), dead:one('[[when Incapacitated]]'),
               bound:one('[[while attached]]'), count:K.KEYWORDS.length}};
    }}""")
    ck("Deploy names its count and its card", r["deploy"]=="Deploy|effect|2 Aether Battery", r["deploy"])
    ck("remove names what it takes off", r["remove"]=="remove|effect|Rooted", r["remove"])
    ck("a Stats keyword carries its amount", r["modify"]=="AC|stats|+2", r["modify"])
    ck("written amount first, it reads the same", r["modify2"]=="AC|stats|+2", r["modify2"])
    # Revision 15.6: "when Incapacitated" became when + this Unit + is Incapacitated
    ck("when Incapacitated is a Condition", r["dead"].startswith("when|condition"), r["dead"])
    ck("while attached is a Duration", r["bound"].startswith("while attached|duration"), r["bound"])
    # 53, less the six one-piece Conditions, plus 30 grammar pieces and narrowing words (Revision 15.6),
    # plus Execute (Revision 16.0)
    ck("the library holds all 94 keywords (16.3 adds Hardened, Aim, Line, Cone, Draw, gain Aether, Barricade, all allies, all enemies, Troop, Hero)", r["count"]==94, r["count"])
    r=pg.evaluate(f"""()=>{{
      var B={W}.KETER_BRIDGE;
      function flags(text,type,kind){{ return B.pings(B.fromSchema({{cardType:type||'equipment',name:'x',
        aetherCost:{{generic:1,affinity:0}}, entries:[{{kind:kind||'Passive',text:text}}]}}))
        .map(function(p){{return p[1];}}); }}
      return {{
        /* Revision 15.6: an always-on Passive's Stats last while it is active, so only an Action's need a Duration */
        noDur: flags('[[target ally]] gains [[AC +2]].','equipment','Active').some(function(t){{return /no Duration/.test(t);}}),
        passiveOk: !flags('[[attached Unit]] gains [[AC +2]].').some(function(t){{return /no Duration/.test(t);}}),
        withDur: flags('[[attached Unit]] gains [[AC +2]] [[while attached]].').some(function(t){{return /no Duration/.test(t);}}),
        plainSpool: flags('Gains SPOOL1 at the start of his turn.','hero').some(function(t){{return /withdrawn/.test(t);}})
      }};
    }}""")
    ck("a Stats change with no Duration is flagged", r["noDur"] is True)
    ck("but not in an always-on Passive", r["passiveOk"] is True)
    ck("and one with a Duration is not", r["withDur"] is False)
    ck("a withdrawn word written as plain text is still flagged", r["plainSpool"] is True)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"KEYWORDS PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
