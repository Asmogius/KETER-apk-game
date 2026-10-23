"""Iteration 3: combat keywords in card effects."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_i7")
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
    b = p.chromium.launch()
    c = b.new_context(viewport={"width":412,"height":915}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs=[]
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:"+m.text) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9111/"); pg.wait_for_timeout(2000)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    D = "document.querySelector('#v-forge iframe').contentDocument"
    B = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"
    W = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"

    # an effect to work in
    pg.evaluate(f"()=>{D}.getElementById('addAbility').click()")
    pg.wait_for_timeout(1200)
    pg.wait_for_function(f"()=>!!{D}.querySelector('.a-text')", timeout=8000)

    # ---- the control ----
    ck("keyword dropdown present", pg.evaluate(f"()=>!!{D}.querySelector('.a-kw')"))
    ck("add-keyword button present", pg.evaluate(f"()=>!!{D}.querySelector('.a-kwnew')"))
    opts = pg.evaluate(f"()=>[...{D}.querySelector('.a-kw').options].map(o=>o.value).filter(Boolean)")
    ck("built-in keywords offered", len(opts) >= 6, str(opts))
    ck("Handbook status effects are in the list", "Rooted" in opts and "Marked" in opts, str(opts))
    ck("and the retired ones are not (15.5)", "Overwhelmed" not in opts and "Compromised" not in opts, str(opts))

    # ---- insertion at the cursor ----
    pg.evaluate(f"""()=>{{
      var a={D}.querySelector('.a-text');
      a.value='Deal 3 damage and apply  to the target.';
      a.dispatchEvent(new Event('input',{{bubbles:true}}));
      a.selectionStart=a.selectionEnd=23;   /* between "apply" and "to" */
    }}""")
    pg.wait_for_timeout(400)
    # Handbook 15.1: a keyword that takes a number asks for it before inserting
    pg.evaluate(f"""()=>{{
      var s={D}.querySelector('.a-kw');
      s.value='Weakened';   /* 15.4: Compromised has no number; Weakened keeps its strength */ s.dispatchEvent(new Event('change',{{bubbles:true}}));
    }}""")
    pg.wait_for_timeout(500)
    pg.evaluate(f"""()=>{{
      var v={D}.querySelector('.a-kwval');
      if(v){{ v.value='2'; }}
      var ok={D}.querySelector('.a-kwok');
      if(ok) ok.click();
    }}""")
    pg.wait_for_timeout(600)
    txt = pg.evaluate(f"()=>{D}.querySelector('.a-text').value")
    ck("keyword inserted at the cursor, not appended",
       txt.startswith("Deal 3 damage and apply[[Weakened 2]]") and
       txt.endswith("to the target."), txt)
    ck("the marker is used for storage", "[[Weakened 2]]" in txt, txt)
    ck("the dropdown resets after inserting",
       pg.evaluate(f"()=>{D}.querySelector('.a-kw').value")=="")

    # ---- rendering ----
    runs = pg.evaluate(f"""()=>{{
      var w={W};
      return w.textRuns('Apply [[Compromised]] to it.').map(r=>[r.t,r.kw]);
    }}""")
    ck("text splits into runs", runs==[["Apply ",False],["Compromised",True],[" to it.",False]],
       str(runs))
    ck("plain text drops the brackets",
       pg.evaluate(f"()=>{W}.plainText('Apply [[Compromised]] now.')")=="Apply Compromised now.")

    ink = pg.evaluate(f"""()=>{{
      function px(o){{var c={B}.fromSchema(o);var cv={B}.renderToOffscreen(c,140,false);
        var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=4) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;}}
      var plain={{cardType:'troop',name:'K',combatRoles:['melee'],
        entries:[{{name:'Hit',kind:'Active',role:'melee',text:'Apply Compromised to it.'}}]}};
      var kw=JSON.parse(JSON.stringify(plain));
      kw.entries[0].text='Apply [[Compromised]] to it.';
      return [px(plain),px(kw)];
    }}""")
    ck("a keyword renders differently from plain text", ink[0] != ink[1])

    ck("brackets never reach the card",
       pg.evaluate(f"""()=>{{
         var w={W};
         var lines=w.wrapRuns(document.createElement('canvas').getContext('2d'),
           'Apply [[Rooted]] now.',9999,'12px sans-serif','italic 12px sans-serif');
         var words=[].concat.apply([],lines).map(function(w){{return w.t;}});
         return words.join('').indexOf('[')<0 && words.indexOf('Rooted')>=0;
       }}"""))

    # ---- definition lookup ----
    ck("definitions resolve",
       "Cannot move" in (pg.evaluate(f"()=>{W}.keywordDef('Rooted')") or ""),
       (pg.evaluate(f"()=>{W}.keywordDef('Rooted')") or "")[:50])
    ck("unknown keywords return nothing",
       pg.evaluate(f"()=>{W}.keywordDef('Nonsense')")=="")

    # ---- custom keyword ----
    made = pg.evaluate(f"""()=>{{
      var w={W};
      var list=w.customKeywords(); list.push({{name:'Scry',desc:'Look at the top card.'}});
      w.saveCustomKeywords(list);
      return w.allKeywords().some(k=>k.name==='Scry');
    }}""")
    ck("a custom keyword joins the list", made)
    ck("it is stored on the device",
       "Scry" in (pg.evaluate("()=>localStorage.getItem('keter-app-keywords')") or ""))
    ck("its definition resolves",
       pg.evaluate(f"()=>{W}.keywordDef('Scry')")=="Look at the top card.")
    ck("the list stays sorted and unique",
       pg.evaluate(f"""()=>{{
         var n={W}.allKeywords().map(k=>k.name);
         return JSON.stringify(n)===JSON.stringify(n.slice().sort()) &&
                new Set(n).size===n.length;
       }}"""))

    # ---- schema round trip ----
    rt = pg.evaluate(f"""()=>{{
      var c={B}.fromSchema({{cardType:'troop',name:'S',combatRoles:['melee'],
        entries:[{{name:'A',kind:'Active',role:'melee',text:'Apply [[Scry]] now.'}}]}});
      return c.abilities[0].text;
    }}""")
    ck("markers survive the schema", rt=="Apply [[Scry]] now.", rt)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"ITERATION 3 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
