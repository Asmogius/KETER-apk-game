"""Enemy Behavior keywords."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_beh")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9631),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9631/"); pg.wait_for_timeout(1900)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3300)
    D="document.querySelector('#v-forge iframe').contentDocument"
    B="document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"

    # ---- the section belongs to Enemies only ----
    def settype(t):
        pg.evaluate(f"""(t)=>{{var d={D};
          d.getElementById('fType').value=t;
          d.getElementById('fType').dispatchEvent(new Event('change',{{bubbles:true}}));}}""", t)
        pg.wait_for_timeout(700)
    settype('enemy')
    ck("Behavior appears on Enemy cards",
       pg.evaluate(f"()=>getComputedStyle({D}.getElementById('behWrap')).display")!="none")
    for t in ('hero','troop','equipment'):
        settype(t)
        ck(f"it is hidden on {t} cards",
           pg.evaluate(f"()=>getComputedStyle({D}.getElementById('behWrap')).display")=="none")
    settype('miniboss')
    ck("it appears on Mini-Bosses too",
       pg.evaluate(f"()=>getComputedStyle({D}.getElementById('behWrap')).display")!="none")
    settype('enemy')

    # ---- the nine keywords ----
    keys = pg.evaluate(f"()=>[...{D}.getElementById('behAdd').options].map(o=>o.value).filter(Boolean)")
    for k in ['cunning','sadistic','opportunistic','brutish','vindictive',
              'ravenous','methodical','cautious','cowardly']:
        ck(f"{k} is offered", k in keys, str(keys))

    # ---- adding, editing, removing ----
    def add(k):
        pg.evaluate(f"""(k)=>{{var d={D};
          d.getElementById('behAdd').value=k;
          d.getElementById('behAddBtn').click();}}""", k)
        pg.wait_for_timeout(500)
    add('cunning'); add('cautious')
    ck("two behaviours added", pg.locator("#v-forge").count()==1 and
       pg.evaluate(f"()=>{D}.querySelectorAll('.behrow').length")==2,
       pg.evaluate(f"()=>{D}.querySelectorAll('.behrow').length"))
    ck("a keyword already taken is not offered again",
       "cunning" not in pg.evaluate(f"()=>[...{D}.getElementById('behAdd').options].map(o=>o.value)"))
    ck("the one with a number shows a field",
       pg.evaluate(f"()=>{D}.querySelectorAll('.beh-x').length")==1)
    ck("the rule is spelled out",
       "nearest Hero" in pg.evaluate(f"()=>{D}.querySelector('.behrow .bt').textContent"),
       pg.evaluate(f"()=>{D}.querySelector('.behrow .bt').textContent"))

    pg.evaluate(f"""()=>{{var d={D};
      var i=d.querySelector('.beh-x');
      i.value='4'; i.dispatchEvent(new Event('input',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(500)
    ck("the number reaches the card",
       pg.evaluate(f"()=>{B}.currentCard().behaviors[1].x")==4,
       pg.evaluate(f"()=>JSON.stringify({B}.currentCard().behaviors)"))

    pg.evaluate(f"""()=>{{var d={D};
      d.querySelector('[data-behdel]').click();}}""")
    pg.wait_for_timeout(500)
    ck("removing one works",
       pg.evaluate(f"()=>{D}.querySelectorAll('.behrow').length")==1)

    # ---- schema ----
    rt = pg.evaluate(f"""()=>{{
      var w={B};
      var c=w.fromSchema({{cardType:'enemy',name:'E',
        behaviors:[{{key:'cunning',value:null}},{{key:'cautious',value:3}}]}});
      var back=w.toSchema(c).behaviors;
      return {{parsed:c.behaviors, exported:back}};
    }}""")
    ck("behaviours survive import", len(rt["parsed"])==2, str(rt["parsed"]))
    ck("the number survives", rt["parsed"][1]["x"]==3, str(rt["parsed"]))
    ck("and they export again",
       rt["exported"][0]["key"]=="cunning" and rt["exported"][1]["value"]==3,
       str(rt["exported"]))
    ck("an unknown keyword is dropped rather than kept",
       pg.evaluate(f"""()=>{B}.fromSchema({{cardType:'enemy',name:'E',
         behaviors:[{{key:'nonsense',value:null}}]}}).behaviors.length""")==0)

    # ---- printed on the card ----
    ink = pg.evaluate(f"""()=>{{
      var w={B};
      function px(bh){{
        var c=w.fromSchema({{cardType:'enemy',name:'E',combatRoles:['melee'],
          stats:{{hp:'18',ac:'11'}}, behaviors:bh,
          entries:[{{name:'A',kind:'Combo',role:'melee',text:'Deal 3 damage.'}}]}});
        var cv=w.renderToOffscreen(c,140,false);
        var d=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<d.length;i+=4) h=(h*31+d[i]+d[i+1]*3+d[i+2]*7)|0; return h;
      }}
      return {{none:px([]), one:px([{{key:'cunning',value:null}}]),
               two:px([{{key:'cunning',value:null}},{{key:'cautious',value:2}}])}};
    }}""")
    ck("a behaviour changes the printed card", ink["none"]!=ink["one"], str(ink))
    ck("a second one changes it again", ink["one"]!=ink["two"], str(ink))

    # ---- the pings ----
    def pings(bh):
        return pg.evaluate(f"""(bh)=>{{
          var w={B};
          var c=w.fromSchema({{cardType:'enemy',name:'E',combatRoles:['melee'],
            stats:{{hp:'18',ac:'11'}}, behaviors:bh,
            entries:[{{name:'A',kind:'Combo',role:'melee',text:'Deal 3.'}}]}});
          return w.computePings(c).map(function(p){{ return p[0]+': '+p[1]; }});
        }}""", bh)
    pl = pings([{"key":"cunning","value":None},{"key":"brutish","value":None}])
    ck("two unconditional targeting keywords are flagged",
       any("never apply" in t for t in pl), str(pl))
    pl2 = pings([{"key":"cautious","value":2},{"key":"cowardly","value":5}])
    ck("Cautious with Cowardly is not flagged — both are conditional",
       not any("never apply" in t for t in pl2), str(pl2))
    pl3 = pings([{"key":"cautious","value":0}])
    ck("a zero on a numbered keyword is flagged",
       any("above zero" in t for t in pl3), str(pl3))
    pl4 = pings([{"key":"ravenous","value":None}])
    ck("Ravenous warns it needs company", any("lone Enemy" in t for t in pl4), str(pl4))
    pl5 = pings([{"key":"vindictive","value":None}])
    ck("Vindictive warns about the memory it asks for",
       any("remember" in t for t in pl5), str(pl5))
    pl6 = pings([])
    ck("no behaviour at all explains the default",
       any("closest Unit" in t for t in pl6), str(pl6))

    # ---- the Boss label bug found on the way in ----
    ck("Boss is labelled Boss, not Mini-Boss",
       pg.evaluate(f"""()=>{B}.typeOf({B}.fromSchema({{cardType:'boss',name:'B'}})).label""")=="BOSS")

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"BEHAVIOR PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
