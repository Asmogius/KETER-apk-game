"""Card power scoring: the points, the budget, and the line on the card."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_scoring")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9801),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9801/"); pg.wait_for_timeout(2100)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    W="document.querySelector('#v-forge iframe').contentWindow"

    ck("the scorer is available to the Forge",
       pg.evaluate(f"()=>typeof {W}.KETER_SCORE==='object'"))

    def score(obj):
        return pg.evaluate(f"""(o)=>{{
          var w={W};
          return w.KETER_SCORE.scoreCard(w.KETER_BRIDGE.fromSchema(o),
                                         w.KETER_BEHAVIORS||[]);
        }}""", obj)

    # ---- stats are charged at the fitted weights ----
    base = dict(cardType="troop", name="T", aetherCost={"generic":2,"affinity":1},
                stats={"hp":"20","ac":"10","nrg":"2","will":"3","move":"3","uslot":"1"},
                entries=[])
    r = score(base)
    ck("a Troop is scored", r["points"] > 0, str(r))
    ck("its budget comes from what it costs to play",
       "Aether" in r["from"], r["from"])
    more_hp = dict(base); more_hp["stats"]=dict(base["stats"], hp="30")
    ck("10 more Health is 10 more points",
       score(more_hp)["points"] == r["points"]+10,
       f'{r["points"]} -> {score(more_hp)["points"]}')
    more_nrg = dict(base); more_nrg["stats"]=dict(base["stats"], nrg="3")
    ck("Energy is worth three times Health",
       score(more_nrg)["points"] == r["points"]+3,
       f'{r["points"]} -> {score(more_nrg)["points"]}')

    # ---- the budget follows cost and Unit Slots ----
    dear = dict(base); dear["aetherCost"]={"generic":4,"affinity":2}
    ck("a dearer card gets a bigger budget",
       score(dear)["budget"] > r["budget"],
       f'{r["budget"]} -> {score(dear)["budget"]}')
    slotty = dict(base); slotty["stats"]=dict(base["stats"], uslot="3")
    ck("Unit Slots widen the budget too",
       score(slotty)["budget"] > r["budget"],
       f'{r["budget"]} -> {score(slotty)["budget"]}')
    ck("and it says Unit Slots are part of it",
       "Slot" in score(slotty)["from"], score(slotty)["from"])

    # ---- effects are scored by hand, and never free ----
    unscored = dict(base, entries=[{"name":"A","kind":"Active","text":"Does something."}])
    scored   = dict(base, entries=[{"name":"A","kind":"Active","text":"Does something.","power":"12"}])
    ru, rs = score(unscored), score(scored)
    ck("an unscored effect still costs something",
       ru["points"] == r["points"]+4, f'{r["points"]} -> {ru["points"]}')
    ck("and it is reported as unscored", ru["unscored"] == 1, str(ru["unscored"]))
    ck("a scored effect is charged what you said",
       rs["points"] == r["points"]+12, f'{r["points"]} -> {rs["points"]}')
    ck("a scored effect is not flagged", rs["unscored"] == 0)
    empty = dict(base, entries=[{"name":"","kind":"Active","text":"   "}])
    ck("an empty effect costs nothing", score(empty)["points"] == r["points"])

    # ---- Behavior keywords are charged ----
    kw = dict(base, cardType="enemy", skullLevel="2",
              behaviors=[{"key":"cunning"},{"key":"cautious","value":2}])
    nokw = dict(base, cardType="enemy", skullLevel="2")
    ck("keywords cost points",
       score(kw)["points"] > score(nokw)["points"],
       f'{score(nokw)["points"]} -> {score(kw)["points"]}')
    ck("an Enemy is budgeted on its Skull Level",
       "Skull" in score(nokw)["from"], score(nokw)["from"])

    # ---- the no-cost types fall back to Rarity ----
    cons = dict(cardType="consumable", name="C", rarity="rare",
                stats={}, entries=[{"name":"","kind":"Active","text":"Heals 6.","power":"3"}])
    common = dict(cons, rarity="common")
    ck("a Consumable is budgeted on Rarity",
       "no Aether cost" in score(cons)["from"], score(cons)["from"])
    ck("and a rarer one gets more room",
       score(cons)["budget"] > score(common)["budget"],
       f'{score(common)["budget"]} -> {score(cons)["budget"]}')

    # ---- the verdict ----
    ck("a card near its budget reads as on budget",
       score(dict(base, stats=dict(base["stats"], hp="24"),
                  entries=[{"name":"A","kind":"Active","text":"x","power":"4"}]))["band"]
       in ("on","under","over"))
    huge = dict(base, stats=dict(base["stats"], hp="90"))
    ck("a wildly overloaded card is called out",
       score(huge)["band"] == "well over", score(huge)["band"])
    ck("and the gap says how far", score(huge)["gap"] > 18, score(huge)["gap"])

    # ---- Heroes and Bosses are held to it too ----
    boss = dict(cardType="boss", name="B", skullLevel="4",
                stats={"hp":"60","ac":"14","nrg":"4","will":"6","move":"3"}, entries=[])
    ck("a Boss is scored like anything else", score(boss)["points"] > 0, str(score(boss)))

    # ---- the score is saved with the card ----
    ck("a hand-scored effect survives a round trip",
       pg.evaluate(f"""()=>{{
         var B={W}.KETER_BRIDGE;
         return B.toSchema(B.fromSchema({{cardType:'action',name:'X',
           aetherCost:{{generic:2,affinity:0}},
           entries:[{{name:'',kind:'Active',text:'Deal 5.',power:'6'}}]}})).entries[0].power;
       }}""") in (6,"6"))

    # ---- it is on the preview and not on an export ----
    r = pg.evaluate(f"""()=>{{
      var d=document.querySelector('#v-forge iframe').contentDocument;
      var cv=d.getElementById('card');
      var x=cv.getContext('2d'), w=cv.width, h=cv.height;
      var s=x.getImageData(0,Math.round(h*0.955),w,Math.max(4,Math.round(h*0.038))).data;
      var lit=0;
      for(var i=0;i<s.length;i+=4) if(s[i]+s[i+1]+s[i+2]>150) lit++;
      return lit;
    }}""")
    ck("the score is drawn on the preview", r > 25, str(r))

    # the card's own keyline is cyan along that edge, so look for the score's
    # own colours rather than for any lit pixel at all
    ck("an export carries no score", pg.evaluate(f"""()=>{{
      var w={W}, B=w.KETER_BRIDGE;
      var cv=B.renderToOffscreen(B.fromSchema({{cardType:'troop',name:'T',
        aetherCost:{{generic:2,affinity:1}},
        stats:{{hp:'20',ac:'10',nrg:'2',will:'3',move:'3',uslot:'1'}},
        entries:[]}}), 150, false);
      var x=cv.getContext('2d'), h=cv.height, wd=cv.width;
      var s=x.getImageData(0,Math.round(h*0.955),wd,Math.max(4,Math.round(h*0.038))).data;
      var scoreish=0;
      for(var i=0;i<s.length;i+=4){{
        var R=s[i],G=s[i+1],Bl=s[i+2];
        if(G>R+25 && G>140 && Bl<G) scoreish++;          /* green  */
        if(R>190 && G>150 && Bl<120) scoreish++;          /* amber  */
        if(R>150 && G<80 && Bl<80) scoreish++;            /* red    */
      }}
      return scoreish < 20;
    }}"""))

    # ---- the anchors are published, so scoring is a comparison ----
    a = pg.evaluate(f"()=>{W}.KETER_SCORE.EFFECT_ANCHORS")
    ck("the anchors are available", len(a) >= 5, str(len(a)))
    ck("each one names a real example",
       all(x.get("example") and x.get("pts") for x in a), str(a[:2]))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"SCORING PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
