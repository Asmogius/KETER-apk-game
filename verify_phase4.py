"""Phase 4: chip cards, footer removal, thumbnail sharpness."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_p4")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9007),
        functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width": 412, "height": 915}, device_scale_factor=3,
                      is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:9007/index.html"); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    B = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"

    # ---------- #18 chips are cards ----------
    dims = pg.evaluate(f"""()=>{{
      var chip={B}.fromSchema({{cardType:'sphere',name:'Chip',level:3,rarity:'rare',
        affinities:[{{district:'3'}}]}});
      var cv={B}.renderToOffscreen(chip,150,false);
      return [cv.width,cv.height,(cv.width/cv.height).toFixed(2)];
    }}""")
    ck("#18 chip renders at card proportions, not a disc",
       dims[2] == "0.71", f"{dims[0]}x{dims[1]} ratio {dims[2]}")

    # the circular face is actually drawn inside
    diff = pg.evaluate(f"""()=>{{
      function px(o){{var c={B}.fromSchema(o);var cv={B}.renderToOffscreen(c,120,false);
        var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=4) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;}}
      var base={{cardType:'sphere',name:'Chip',level:1,rarity:'common',affinities:[{{district:'3'}}]}};
      var lvl=JSON.parse(JSON.stringify(base)); lvl.level=5;
      var rar=JSON.parse(JSON.stringify(base)); rar.rarity='mythic';
      var aff=JSON.parse(JSON.stringify(base)); aff.affinities=[{{district:'1'}}];
      return [px(base),px(lvl),px(rar),px(aff)];
    }}""")
    ck("#18 chip face redraws when Level changes", diff[0] != diff[1])
    ck("#18 chip face redraws when Rarity changes", diff[0] != diff[2])
    ck("#18 chip face redraws when Affinity changes", diff[0] != diff[3])

    # ---------- #18b generation ----------
    vals = pg.evaluate(f"""()=>{{
      var B={B};
      var out={{}};
      [['common',1],['common',6],['rare',3],['mythic',6],['epic',2],['uncommon',4]]
        .forEach(function(t){{
          out[t[0]+t[1]]=B.chipAether ? B.chipAether({{level:t[1],rarity:t[0]}}) : null;
        }});
      return out;
    }}""")
    ck("#18b Level 1 Common generates 1", vals.get("common1") == 1, str(vals))
    ck("#18b Level 6 Common generates 6", vals.get("common6") == 6, str(vals))
    ck("#18b Level 3 Rare generates 4", vals.get("rare3") == 4, str(vals))
    ck("#18b Level 6 Mythic caps at 8", vals.get("mythic6") == 8, str(vals))
    ck("#18b Level 2 Epic generates 3", vals.get("epic2") == 3, str(vals))
    ck("#18b Uncommon adds nothing", vals.get("uncommon4") == 4, str(vals))

    # ---------- #18 effects tab and level box ----------
    pg.evaluate("""()=>{var d=document.querySelector('#v-forge iframe').contentDocument;
      d.getElementById('fType').value='sphere';
      d.getElementById('fType').dispatchEvent(new Event('change',{bubbles:true}));}""")
    pg.wait_for_timeout(800)
    fr = pg.frame_locator("#v-forge iframe")
    ck("#18 Level box shown for chips",
       pg.evaluate("()=>getComputedStyle(document.querySelector('#v-forge iframe').contentDocument.getElementById('lvlWrap')).display") != "none")
    ck("#18 chips can take effects", fr.locator("#addAbility").count() == 1)
    pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.getElementById('addAbility').click()")
    pg.wait_for_timeout(700)
    ck("#18 an effect can be added to a chip", fr.locator(".a-text").count() >= 1)

    # ---------- #19 footer ----------
    foot = pg.evaluate(f"""()=>{{
      function band(o){{
        var c={B}.fromSchema(o);
        var cv={B}.renderToOffscreen(c,150,false);
        var d=cv.getContext('2d').getImageData(0,Math.round(cv.height*0.93),
              cv.width,Math.round(cv.height*0.06)).data;
        var h=0; for(var i=0;i<d.length;i+=4) h=(h*31+d[i]+d[i+1]*3+d[i+2]*7)|0;
        return h;
      }}
      var plain={{cardType:'hero',name:'Foot',combatRoles:['melee'],
        affinities:[{{district:'3'}}]}};
      var full={{cardType:'hero',name:'Foot',combatRoles:['melee'],
        affinities:[{{district:'3'}}],id:'D3-H01'}};
      return [band(plain),band(full)];
    }}""")
    ck("#19 the card number no longer prints in the footer strip",
       foot[0] == foot[1], str(foot))

    numvis = pg.evaluate(f"""()=>{{
      function px(o){{var c={B}.fromSchema(o);var cv={B}.renderToOffscreen(c,150,false);
        var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=4) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;}}
      var no={{cardType:'hero',name:'N',combatRoles:['melee']}};
      var yes=JSON.parse(JSON.stringify(no)); yes.id='D3-H01';
      return [px(no),px(yes)];
    }}""")
    ck("#19 the card number still prints", numvis[0] != numvis[1], str(numvis))

    # ---------- #4 thumbnails ----------
    pg.evaluate("""()=>localStorage.setItem('keter-cardforge-heroes',JSON.stringify({
      "Sharp":{v:6,type:"hero",name:"Sharp",arches:[],roles:{melee:true},stats:{hp:"30"},abilities:[]}}))""")
    pg.reload(); pg.wait_for_timeout(2000)
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(800)
    pg.locator("#cView").click(); pg.wait_for_timeout(5000)
    img = pg.locator(".gcard img").first
    ck("#4 a thumbnail rendered", img.count() == 1)
    sharp = img.evaluate("""e=>{var r=e.getBoundingClientRect();
      return [e.naturalWidth, Math.round(r.width), Math.round(window.devicePixelRatio*r.width)];}""")
    ck("#4 thumbnail is not upscaled", sharp[0] >= sharp[2] * 0.9,
       f"natural={sharp[0]} css={sharp[1]} needed={sharp[2]}")
    ck("#4 old blurry cache is bypassed",
       pg.evaluate("""async ()=>{
         return await new Promise(r=>{var q=indexedDB.open('keter-durable',1);
           q.onsuccess=()=>{var d=q.result;
             var g=d.transaction('kv','readonly').objectStore('kv').getAllKeys();
             g.onsuccess=()=>r(g.result.filter(k=>String(k).indexOf('thumb2:')===0).length);
             g.onerror=()=>r(0);};
           q.onerror=()=>r(0);});
       }""") >= 1)

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"PHASE 4 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
