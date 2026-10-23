"""Battlefield chunks (v14.7; four more in v14.9): the 20 built-in District 3 chunks join the floor
library, are kept out of the Simulator's floors and the World Map's ordinary
draws, and grow battlefields; the Sandbox's Chunk mode (role, open sides, Skull
Levels, laying one out) is saved with the floor, and its preview grows and
draws a battlefield at each size."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_chunks")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9871),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9871/"); pg.wait_for_timeout(2000)
    E=pg.evaluate

    # ---- the library ----
    r=E("""()=>{ var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}'), ch=Object.keys(all).filter(function(k){ return all[k].chunk; });
      var roles={}; ch.forEach(function(k){ var c=all[k].chunk; roles[c.role]=(roles[c.role]||0)+1; });
      return {n:ch.length, roles:roles, d3:ch.every(function(k){ return all[k].district==='3' && all[k].hexes.length<=37; }),
        sim:simSavedFloors().filter(function(f){ return all[f.key] && all[f.key].chunk; }).length, simAll:simSavedFloors().length,
        world:KETER_WORLD.chunks().length, floors:KETER_WORLD.floors().filter(function(f){ return /^Chunk/.test(f.key); }).length}; }""")
    ck("the 20 built-in District 3 chunks join the floor library: 4 Start, 6 Enemy, 3 Loot, an Exit, 6 Fillers", r["n"]==20 and r["roles"]=={"start":4,"enemy":6,"loot":3,"exit":1,"filler":6} and r["d3"], r)
    ck("the Battle Simulator never offers one as a floor", r["sim"]==0 and r["simAll"]>=4, r)
    ck("the World Map keeps them apart from its floors", r["world"]==20 and r["floors"]==0, r)
    r=E("""()=>{ localStorage.removeItem('keter-hexmap-levels'); var a=installTestMaps(); var b=installTestMaps();
      var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')); var k='Chunk \\u00b7 D3 \\u00b7 Vault'; all[k].notes='mine'; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all));
      installTestMaps(); return {a:a, b:b, kept:JSON.parse(localStorage.getItem('keter-hexmap-levels'))[k].notes}; }""")
    ck("any missing are added; one you have edited is left as you left it", r["a"]>=20 and r["b"]==0 and r["kept"]=="mine", r)

    # ---- growing, on the World Map ----
    r=E("""()=>{ var W=KETER_WORLD, G=KETER_CHUNKGEN, f=W.drawFloors('3',4,3,{tile:'2,-1'}), g=W.drawFloors('3',4,3,{tile:'2,-1'}), a=W.drawFloors('3',2,1,{ambush:true,tile:'1,0'});
      var lv=W.level(f[0]); return {f:f, same:JSON.stringify(f)===JSON.stringify(g), a:a, gen:f.every(G.isGenKey), hexes:lv?lv.hexes.length:0, name:lv?lv.name:'', whole:W.drawFloors('4',2,2,{tile:'9,9'})}; }""")
    ck("a District 3 POI grows its floors, medium then large from Skull 4; the same tile, the same", r["gen"] and "|medium|" in r["f"][0] and "|large|" in r["f"][2] and r["same"] and r["hexes"]>150, r)
    ck("an ambush grows a small one; a District without chunks draws whole floors", "|small|" in r["a"][0] and not any(k.startswith("gen|") for k in r["whole"]), r)
    r=E("""()=>{ var k=KETER_WORLD.drawFloors('3',3,1,{tile:'3,0'})[0], f=simLoadFloor(k); return {k:k, ok:!!f, n:f?Object.keys(f.hexes||{}).length:0}; }""")
    ck("the Simulator fights on a grown floor from its key", r["ok"] and r["n"]>150, r)

    # ---- the Sandbox's Chunk mode ----
    pg.locator("#nav button[data-go='poi']").click(); pg.wait_for_timeout(3300)
    W="document.querySelector('#v-poi iframe').contentWindow"
    F=pg.frame_locator('#v-poi iframe')
    # (the Floor Info dock may be folded away on a phone: its controls are worked as a tap would)
    def sel(css, v):
        E(f"([c,v])=>{{ var e={W}.document.querySelector(c); e.value=v; e.dispatchEvent(new Event('change',{{bubbles:true}})); }}", [css, v]); pg.wait_for_timeout(150)
    def tick(css, on):
        E(f"([c,v])=>{{ var e={W}.document.querySelector(c); e.checked=v; e.dispatchEvent(new Event('change',{{bubbles:true}})); }}", [css, on]); pg.wait_for_timeout(100)
    def click(css):
        E(f"(c)=>{W}.document.querySelector(c).click()", css); pg.wait_for_timeout(250)
    shown=lambda css: E(f"(c)=>{{ var e={W}.document.querySelector(c); return !!e && e.style.display!=='none' && getComputedStyle(e).display!=='none'; }}", css)
    ck("the Sandbox has the generator", E(f"()=>!!{W}.KETER_CHUNKGEN && typeof {W}.KETER_CHUNKGEN.generate==='function'"))
    types=E(f"()=>[...{W}.document.querySelectorAll('#fType option')].map(function(o){{ return o.value; }})")
    ck("Chunk and Boss are POI Types", all(t in types for t in ["Chunk", "Boss"]), types)
    ck("the Chunk panel stays hidden for any other type", not shown("#chunkField"))
    sel("#fType", "Chunk")
    ck("choosing Chunk opens it: Role, six open sides, Skull Levels, and its two buttons", shown("#chunkField") and F.locator("#chRole").count()==1 and F.locator("[data-chside]").count()==6
       and F.locator("#chLay").count()==1 and F.locator("#chPrev").count()==1)
    click("#chLay")
    r=E(f"()=>{{ var S={W}.KETER_POI_TEST.state(); return {{n:S.hexes.size, far:[...S.hexes.keys()].every(function(k){{ var p=k.split(',').map(Number); return Math.max(Math.abs(p[0]),Math.abs(p[1]),Math.abs(p[0]+p[1]))<=3; }})}}; }}")
    ck("Lay out a chunk fills the radius-3 hexagon: 37 tiles", r["n"]==37 and r["far"], r)
    sel("#chRole", "enemy"); tick("[data-chside='3']", False); sel("#chLo", "2"); sel("#chHi", "5")
    r=E(f"()=>{W}.KETER_POI_TEST.snapshot().chunk")
    ck("its role, sides and Skull Levels are saved with it", r=={"role":"enemy","sides":[True,True,True,False,True,True],"skullMin":2,"skullMax":5}, r)
    sel("#fType", "Lab")
    snap=E(f"()=>{{ var s={W}.KETER_POI_TEST.snapshot(); return {{type:s.poiType, chunk:s.chunk||null}}; }}")
    ck("and a floor of any other type carries none", snap=={"type":"Lab","chunk":None} and not shown("#chunkField"), snap)
    sel("#fType", "Chunk")
    E(f"()=>{{ var d={W}.document.getElementById('fDistrict'); if(d){{ var o=[...d.options].find(function(x){{ return /^\\s*3/.test(x.value||x.text); }}); if(o){{ d.value=o.value; d.dispatchEvent(new Event('change')); d.dispatchEvent(new Event('input')); }} }} }}")
    click("#chPrev")
    info=F.locator("#chpInfo").inner_text()
    ck("Preview grows a battlefield from the saved chunks, and names them", F.locator("#chpCv").count()==1 and info.startswith("medium") and "(start)" in info and "(enemy)" in info, info)
    def lit():
        return E(f"()=>{{ var c={W}.document.getElementById('chpCv'), d=c.getContext('2d').getImageData(0,0,c.width,c.height).data, n=0; for(var i=0;i<d.length;i+=16) if(d[i+3]>0) n++; return n; }}")
    med=lit()
    click("[data-sz='small']"); small=lit(); sinfo=F.locator("#chpInfo").inner_text()
    click("[data-sz='large']"); linfo=F.locator("#chpInfo").inner_text()
    ck("it draws them; Small is 3 chunks, Large 7", med>3000 and small>1000 and sinfo.startswith("small") and sinfo.count("(")==3 and linfo.startswith("large") and linfo.count("(")==7, (med, small, sinfo, linfo))
    click("#chpAgain")
    ck("Grow another grows again", F.locator("#chpInfo").inner_text().startswith("large"))
    click("#chpNo")
    ck("Close closes it", F.locator("#chpCv").count()==0)
    ck("no page errors", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"\nPASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
