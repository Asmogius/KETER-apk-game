"""The game's Sandbox, back in the Companion (v14.15): a file the game's
Sandbox exports carries its chassis beside its cards, and importing it puts
them in the Chassis library, replacing one of the same id, without what the
game adds to them; a file with no chassis changes nothing there."""
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
    ck("the Companion is 14.15", E("()=>document.documentElement.innerHTML.indexOf('14.15')>=0"))
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
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nSANDBOX PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
