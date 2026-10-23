"""Phase 5: multi-select, ping silencing, variable costs, help overlay."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_p5")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP)
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9015),
        functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, det=""):
    (ok if c else bad).append(n + ((" — " + str(det)) if det and not c else ""))

SEED = """()=>localStorage.setItem('keter-cardforge-heroes',JSON.stringify({
 "Alpha":{v:6,type:"hero",name:"Alpha",arches:[],roles:{melee:true},stats:{hp:"30"},abilities:[]},
 "Beta":{v:6,type:"hero",name:"Beta",arches:[],roles:{ranged:true},stats:{hp:"25"},abilities:[]},
 "Gamma":{v:6,type:"troop",name:"Gamma",arches:[],roles:{melee:true},stats:{},abilities:[]}
}))"""

with sync_playwright() as p:
    b = p.chromium.launch()
    c = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True)
    pg = c.new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)))
    pg.on("console", lambda m: errs.append("con:" + m.text) if m.type == "error" else None)
    pg.goto("http://127.0.0.1:9015/index.html"); pg.wait_for_timeout(1600)
    pg.evaluate(SEED); pg.reload(); pg.wait_for_timeout(1900)

    # ---------------- #24 multi-select ----------------
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(800)
    ck("#24 Select button present", pg.locator("#cSelect").count() == 1)
    ck("#24 no checkboxes before selecting", pg.locator(".selbox").count() == 0)
    pg.locator("#cSelect").click(); pg.wait_for_timeout(500)
    ck("#24 selection mode turns on",
       pg.locator("#cSelect").evaluate("e=>e.classList.contains('on')"))
    ck("#24 checkboxes appear (the starter design too)", pg.locator(".selbox").count() == 4)
    ck("#24 action bar appears", pg.locator(".selbar").count() == 1)

    pg.locator(".crow").first.click(); pg.wait_for_timeout(400)
    ck("#24 tapping selects instead of opening",
       pg.locator(".crow.sel").count() == 1 and
       not pg.locator("#modal").evaluate("e=>e.classList.contains('on')"))
    ck("#24 count reported", "1 selected" in pg.locator(".selbar .count").inner_text())
    pg.locator(".crow").nth(1).click(); pg.wait_for_timeout(400)
    ck("#24 a second card adds to the selection", pg.locator(".crow.sel").count() == 2)
    pg.locator(".crow").nth(1).click(); pg.wait_for_timeout(400)
    ck("#24 tapping again deselects", pg.locator(".crow.sel").count() == 1)
    pg.locator("#selAll").click(); pg.wait_for_timeout(400)
    ck("#24 select all works", pg.locator(".crow.sel").count() == 4)

    with pg.expect_download(timeout=8000) as dl:
        pg.locator("#selExport").click()
    ck("#24 selection exports", "KETER_cards_4" in dl.value.suggested_filename,
       dl.value.suggested_filename)

    # deletion of own cards
    pg.locator("#selNone").click(); pg.wait_for_timeout(300)
    pg.locator(".crow").first.click(); pg.wait_for_timeout(300)
    ck("#24 delete names what it will remove",
       "Delete 1" in pg.locator("#selDel").inner_text(),
       pg.locator("#selDel").inner_text())
    pg.locator("#selDel").click(); pg.wait_for_timeout(500)
    ck("#24 deletion asks first", pg.locator("#selDelYes").count() == 1)
    ck("#24 deletion warns it cannot be undone",
       "cannot be undone" in pg.locator("#modalBox").inner_text())
    pg.locator("#selDelYes").click(); pg.wait_for_timeout(900)
    left = pg.evaluate("()=>Object.keys(JSON.parse(localStorage.getItem('keter-cardforge-heroes')||'{}')).length")
    ck("#24 the card is gone", left == 2, f"{left} left")
    ck("#24 selection clears after deleting", pg.locator(".crow.sel").count() == 0)

    # master cards are protected outside Dev Mode
    pg.evaluate("""()=>localStorage.setItem('keter-app-master',JSON.stringify({
      schema:'keter.compendium/1',version:'1',
      cards:[{name:'Canon',cardType:'hero',level:1,
              entries:[{name:'Volley',kind:'Active',role:'ranged',
                        text:'Deal 6 damage.'}]}]}))""")
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.reload(); pg.wait_for_timeout(1900)
    pg.locator("#nav button[data-go='comp']").click(); pg.wait_for_timeout(700)
    pg.locator("#cSelect").click(); pg.wait_for_timeout(400)
    pg.locator("#selAll").click(); pg.wait_for_timeout(400)
    ck("#24 mixed selection says master needs Dev Mode",
       "Dev Mode" in pg.locator(".selbar .count").inner_text(),
       pg.locator(".selbar .count").inner_text())
    pg.locator("#selDel").click(); pg.wait_for_timeout(500)
    ck("#24 master deletion refused without Dev Mode",
       "protected" in pg.locator("#modalBox").inner_text().lower(),
       pg.locator("#modalBox").inner_text()[:70])
    ck("#24 nothing was deleted",
       pg.evaluate("()=>JSON.parse(localStorage.getItem('keter-app-master')).cards.length") == 1)
    pg.locator("#mClose").click(); pg.wait_for_timeout(300)

    # ---------------- #25c variable costs ----------------
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    fr = pg.frame_locator("#v-forge iframe")
    B = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"
    opts = pg.evaluate("""()=>[...document.querySelector('#v-forge iframe').contentDocument
      .getElementById('fAeGen').options].map(o=>o.value)""")
    ck("#25c X options offered", "X" in opts and "XX" in opts and "XXX" in opts, str(opts[-4:]))

    varpix = pg.evaluate(f"""()=>{{
      function px(o){{var c={B}.fromSchema(o);var cv={B}.renderToOffscreen(c,120,false);
        var x=cv.getContext('2d').getImageData(0,0,cv.width,cv.height).data,h=0;
        for(var i=0;i<x.length;i+=4) h=(h*31+x[i]+x[i+1]*3+x[i+2]*7)|0; return h;}}
      var two={{cardType:'action',name:'V',combatRoles:['ranged'],
        affinities:[{{district:'3'}}],aetherCost:{{generic:2}}}};
      var xx=JSON.parse(JSON.stringify(two)); xx.aetherCost={{generic:'XX'}};
      var xaff=JSON.parse(JSON.stringify(two)); xaff.aetherCost={{generic:0,affinity:'X'}};
      return [px(two),px(xx),px(xaff)];
    }}""")
    ck("#25c an X cost renders differently from a number", varpix[0] != varpix[1])
    ck("#25c a Dedicated X renders differently from an Any X", varpix[1] != varpix[2])

    rt = pg.evaluate(f"""()=>{{
      var c={B}.fromSchema({{cardType:'action',name:'V',combatRoles:['ranged'],
        aetherCost:{{generic:'XX',affinity:'X'}}}});
      return [c.aeGen,c.aeAff];
    }}""")
    ck("#25c X survives the schema", rt == ["XX", "X"], str(rt))

    # ---------------- #12 ping silencing ----------------
    counts = pg.evaluate("""()=>{
      var d=document.querySelector('#v-forge iframe').contentDocument;
      return [d.querySelectorAll('#pingBody .ping').length,
              d.querySelectorAll('#pingBody .pingX').length];
    }""")
    ck("#12 every ping has a silence control", counts[0] == counts[1] and counts[0] > 0,
       str(counts))
    before = counts[0]
    pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.querySelector('#pingBody .pingX').click()")
    pg.wait_for_timeout(600)
    after = pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.querySelectorAll('#pingBody .ping').length")
    ck("#12 silencing removes the ping", after == before - 1, f"{before} -> {after}")
    ck("#12 the dock says how many are muted",
       "1 silenced" in pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.querySelector('#pingBody .pingMuted').innerText"))
    ck("#12 badge counts only what is shown",
       pg.evaluate("()=>+document.querySelector('#v-forge iframe').contentDocument.getElementById('pingBadge').textContent") == after)
    pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.querySelector('#pingBody .pingMuted button').click()")
    pg.wait_for_timeout(600)
    ck("#12 show all brings them back",
       pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.querySelectorAll('#pingBody .ping').length") == before)

    # silences belong to the card, not the app
    pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.querySelector('#pingBody .pingX').click()")
    pg.wait_for_timeout(500)
    muted_before = pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.querySelectorAll('#pingBody .pingMuted').length")
    pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.getElementById('newBtn').click()")
    pg.wait_for_timeout(600)
    # a dirty card asks before it is discarded
    pg.evaluate("""()=>{
      var d=document.querySelector('#v-forge iframe').contentDocument;
      var ok=[...d.querySelectorAll('.overlay button')].find(b=>!/cancel/i.test(b.textContent));
      if(ok) ok.click();
    }""")
    pg.wait_for_timeout(900)
    muted_after = pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.querySelectorAll('#pingBody .pingMuted').length")
    scoped = [muted_before, muted_after]
    ck("#12 a new card starts with nothing silenced",
       scoped[0] == 1 and scoped[1] == 0, str(scoped))

    # ---------------- #20 help overlay ----------------
    pg.evaluate("()=>document.querySelector('#v-forge iframe').contentDocument.getElementById('hud-help').click()")
    pg.wait_for_timeout(900)
    overlap = pg.evaluate("""()=>{
      var d=document.querySelector('#v-forge iframe').contentDocument;
      var boxes=[...d.querySelectorAll('.help-box')].map(b=>b.getBoundingClientRect());
      var bad=0;
      for(var i=0;i<boxes.length;i++)
        for(var j=i+1;j<boxes.length;j++){
          var a=boxes[i],c=boxes[j];
          var ox=Math.min(a.right,c.right)-Math.max(a.left,c.left);
          var oy=Math.min(a.bottom,c.bottom)-Math.max(a.top,c.top);
          if(ox>1&&oy>1) bad++;
        }
      return [boxes.length,bad];
    }""")
    ck("#20 help boxes are drawn", overlap[0] > 5, str(overlap))
    ck("#20 no overlapping help boxes", overlap[1] == 0, f"{overlap[1]} overlaps of {overlap[0]} boxes")

    real = [e for e in errs if "favicon" not in e.lower()]
    ck("no JS errors", len(real) == 0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"PHASE 5 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
