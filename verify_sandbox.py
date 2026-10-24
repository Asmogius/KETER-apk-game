"""The game's Sandbox, back in the Companion (v14.15): a file the game's
Sandbox exports carries its chassis beside its cards, and importing it puts
them in the Chassis library, replacing one of the same id, without what the
game adds to them; a file with no chassis changes nothing there. (v14.16) Its
floors join the POI Sandbox's saved levels by name. (v14.17) Its pictures join
the Pixel Studio's library."""
import http.server, socketserver, threading, functools, pathlib, shutil, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_sandbox")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9977),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915}).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)))
    pg.goto("http://127.0.0.1:9977/"); pg.wait_for_timeout(1800)
    E=pg.evaluate
    ck("the Companion is 14.19", E("()=>document.documentElement.innerHTML.indexOf('14.19')>=0"))
    nz=E("""()=>{ var R=window.KETER_RULES||window.KETER_SIM_RULES||null; if(!R||!R.aetherFromHero) return null;
      return {neu:R.aetherFromHero({affinities:[{district:'neu',level:2}]}), d3:R.aetherFromHero({affinities:[{district:'3',level:2}]})}; }""")
    ck("(14.18) a Neutral Hero generates Neutral Aether; a District's, its District's", nz is not None and nz["neu"]=={"generic":2} and nz["d3"]=={"d3":2}, nz)
    fh=E("()=>{ var c=(typeof simAllCards==='function'?simAllCards():[]).filter(function(x){ return x.name==='Dock Hand'; })[0]; return c?c.affinities:null; }")
    ck("(14.18) the free Heroes are Neutral, at Affinity Level 2", bool(fh) and (fh[0]["district"]=="neu" and fh[0]["level"]==2), fh)
    r=E("""()=>{ var C=KETER_CHASSIS, n0=C.list().length, sk=JSON.parse(JSON.stringify(C.get('ch_skitter_frame')||{id:'ch_skitter_frame',name:'Skitter Frame'}));
      sk.powerCap=22; sk._sandbox='edited';
      var file={schema:'keter.compendium/1', cards:[], chassis:[sk, {id:'ch_sb1_1', name:'Sandbox Strider', district:'', bodyPlan:'Quadruped', subtypes:['Melee','Ranged'], powerCap:20, abilityCap:2,
        cost:{troop:4}, maxRange:6, bestHit:4, maxAP:6, aether:{generic:1,affinity:0}, stats:{hp:12,ac:10,move:4,dmg:3,nrg:3,int:10}, allowed:['target enemy','damage'], notes:'', _sandbox:'made'}]};
      var got=sandboxExtras(file), st=C.get('ch_sb1_1'), sk2=C.get('ch_skitter_frame');
      var none=sandboxExtras({schema:'keter.compendium/1', cards:[]});
      return {got:got, n0:n0, n:C.list().length, name:st&&st.name, subs:st&&st.subtypes, cap:sk2&&sk2.powerCap, clean:!('_sandbox' in st) && !('_sandbox' in sk2), none:none}; }""")
    ck("a Sandbox file's chassis join the Chassis library", r["got"]==2 and r["name"]=="Sandbox Strider" and r["subs"]==["Melee","Ranged"] and r["n"]==r["n0"]+1, r)
    ck("one of the same id is replaced by the game's", r["cap"]==22, r)
    ck("without what the game adds to them", r["clean"], r)
    ck("a file with no chassis changes nothing there", r["none"]==0, r)
    f=E("""()=>{ localStorage.setItem('keter-hexmap-levels', JSON.stringify({'Old Hall':{v:6,name:'Old Hall',hexes:[['0,0',{}]]}}));
      var file={schema:'keter.compendium/1', cards:[], floors:[{v:6,name:'Sandbox Hall',radius:8,hexes:[['0,0',{c:3}],['1,0',{}]],marks:[],walls:[['0,0|1,0',-1]],symDefs:[],colorLabels:{'3':'Player Spawn Tile'},_key:'fl_sb1_1',_sandbox:'made'},
        {v:6,name:'Old Hall',hexes:[['0,0',{}],['0,1',{}]]}, {name:'no tiles'}]};
      var got=sandboxExtras(file), all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}');
      return {got:got, names:Object.keys(all).sort(), tiles:(all['Sandbox Hall']||{}).hexes, walls:(all['Sandbox Hall']||{}).walls, old:(all['Old Hall']||{}).hexes.length,
        clean:!('_key' in (all['Sandbox Hall']||{})) && !('_sandbox' in (all['Sandbox Hall']||{}))}; }""")
    ck("a Sandbox file's floors join the POI Sandbox's levels, as they were drawn", f["got"]==2 and f["names"]==["Old Hall","Sandbox Hall"] and f["tiles"]==[["0,0",{"c":3}],["1,0",{}]] and f["walls"]==[["0,0|1,0",-1]], f)
    ck("one of the same name is replaced, and what the game adds is left behind", f["old"]==2 and f["clean"], f)
    sims=E("()=>typeof simSavedFloors==='function' ? simSavedFloors().map(function(x){ return x.name; }) : null")
    ck("and the Battle Simulator offers it as a floor to fight on", sims is not None and "Sandbox Hall" in sims, sims)
    pz=E("""()=>{ var pic={v:1,w:2,h:1,name:'From the game',frames:[{layers:[{name:'Layer 1',visible:true,locked:false,opacity:100,mode:'view',px:btoa(String.fromCharCode(2,9))}]}],flat:btoa(String.fromCharCode(2,9))};
      var got=sandboxExtras({schema:'keter.compendium/1', cards:[], pictures:{'px_sb1_9':pic, 'bad':{w:0}}});
      var p=KETER_PX.get('px_sb1_9'), flat=p?Array.from(KETER_PX.decode(p.flat,2)):null;
      return {got:got, name:p&&p.name, flat:flat, bad:KETER_PX.has('bad')}; }""")
    ck("a Sandbox file's pictures join the Pixel Studio's library, pixels and all", pz["got"]==1 and pz["name"]=="From the game" and pz["flat"]==[9,9] and not pz["bad"], pz)
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nSANDBOX PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
