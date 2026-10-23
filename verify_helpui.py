"""One help button per page, in the top bar, and the score badge under the card."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_helpui")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
shutil.copy("compendium_full.json", TMP/"compendium.json")
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9851),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))
comp=json.load(open("compendium_full.json"))

REACH = """(d)=>{ var out={};
  ['hud-panel','hud-undo','hud-redo','hud-help','hud-more'].forEach(function(id){
    var b=d.getElementById(id); if(!b) return;
    var r=b.getBoundingClientRect();
    var hit=d.elementFromPoint(r.left+4, r.top+r.height/2);
    out[id] = hit && (hit===b||b.contains(hit)) ? 'ok' : 'covered';
  }); return out; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9851/"); pg.wait_for_timeout(2200)

    ck("the misleading first-run tip is gone", pg.locator("#nudge").count()==0)

    for tool in ("forge","poi"):
        pg.locator(f"#nav button[data-go='{tool}']").click(); pg.wait_for_timeout(3400)
        D=f"document.querySelector('#v-{tool} iframe').contentDocument"
        F=pg.frame_locator(f'#v-{tool} iframe')
        ids=pg.evaluate(f"()=>[].slice.call({D}.querySelectorAll('#keter-hud button')).map(function(x){{return x.id;}})")
        # the Sandbox also carries undo and redo up here, so check the ? is in
        # the bar and sits just before More, rather than an exact sequence
        ck(f"{tool}: ? sits in the top bar, just before More",
           "hud-help" in ids and ids.index("hud-help")==ids.index("hud-more")-1,
           str(ids))
        ck(f"{tool}: the floating corner button is gone",
           pg.evaluate(f"()=>!{D}.getElementById('keter-helpdock')"))
        ck(f"{tool}: there is exactly one ? on screen",
           pg.evaluate(f"""()=>[].slice.call({D}.querySelectorAll('button'))
             .filter(function(e){{return e.textContent.trim()==='?' &&
                     e.getBoundingClientRect().width>0;}}).length""")==1)

        # the panel is open on arrival; every top-bar control must still be tappable
        r=pg.evaluate(f"(fn)=>{{var d={D}; var a=d.querySelector('aside'); if(a) a.classList.remove('collapsed'); return eval('('+fn+')')(d);}}", REACH)
        ck(f"{tool}: with the panel open, every top-bar button is reachable",
           all(v=="ok" for v in r.values()), str(r))

        F.locator("#hud-help").click(); pg.wait_for_timeout(1000)
        n=F.locator(".help-box").count()
        ck(f"{tool}: help labels the controls", n>10, str(n))
        ck(f"{tool}: the ? lights up while help is on", F.locator("#hud-help.on").count()==1)
        lab=F.locator("#helpExit").inner_text()
        ck(f"{tool}: the way out says Done, not Esc", lab.strip()=="Done", lab)
        txt=F.locator("#helpBanner span").first.inner_text()
        ck(f"{tool}: it says tap, not click", "tap" in txt.lower() and "click" not in txt.lower(), txt)
        clash=pg.evaluate(f"""()=>{{
          var d={D}, bn=d.getElementById('helpBanner').getBoundingClientRect();
          return ['hud-panel','hud-help','hud-more','dockPings','dockCheck'].filter(function(id){{
            var e=d.getElementById(id); if(!e) return false;
            var r=e.getBoundingClientRect();
            return !(r.right<bn.left||r.left>bn.right||r.bottom<bn.top||r.top>bn.bottom);
          }});
        }}""")
        ck(f"{tool}: the banner covers neither the top bar nor the docks", clash==[], str(clash))
        F.locator("#helpExit").click(timeout=6000); pg.wait_for_timeout(500)
        ck(f"{tool}: Done leaves help mode", F.locator(".help-box").count()==0)

    # ---- the score badge ----
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(1500)
    F=pg.frame_locator('#v-forge iframe')
    D="document.querySelector('#v-forge iframe').contentDocument"
    pg.evaluate(f"()=>{{var a={D}.querySelector('aside'); if(a) a.classList.add('collapsed');}}")
    pg.wait_for_timeout(500)
    r=pg.evaluate(f"""()=>{{
      var d={D}, c=d.getElementById('card').getBoundingClientRect(),
          s=d.getElementById('scoreBar').getBoundingClientRect();
      return {{below: s.top >= c.bottom-2,
               centred: Math.abs((s.left+s.right)/2 - (c.left+c.right)/2) < 12,
               narrow: s.width < c.width, cardLeft: Math.round(c.left)}};
    }}""")
    ck("the score sits below the card, not beside it", r["below"] is True, str(r))
    ck("centred under it", r["centred"] is True, str(r))
    ck("as a badge narrower than the card", r["narrow"] is True, str(r))
    ck("and the card is no longer pushed off the left edge", r["cardLeft"] >= 0, str(r))
    ck("it starts collapsed", F.locator("#scoreBar.open").count()==0)
    ck("showing the points and the verdict",
       "pts" in F.locator("#scoreBar").inner_text(), F.locator("#scoreBar").inner_text()[:40])
    F.locator("#scoreBar").click(); pg.wait_for_timeout(400)
    ck("tapping it opens the detail", F.locator("#scoreBar.open").count()==1)
    ck("which says where the budget came from",
       "Budget" in F.locator("#scoreBar").inner_text() and "from" in F.locator("#scoreBar").inner_text(),
       F.locator("#scoreBar").inner_text()[:90])
    F.locator("#scoreBar").click(); pg.wait_for_timeout(300)
    ck("and tapping again closes it", F.locator("#scoreBar.open").count()==0)

    # ---- the shell's pages ----
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":comp["cards"]})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    pg.reload(); pg.wait_for_timeout(2300)
    for page in ("battle","combat","deck"):
        pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
        pg.locator(f'.lt[data-page="{page}"]').click(); pg.wait_for_timeout(800)
        btn=pg.locator(f"#v-{page} .pghelp")
        ck(f"{page}: has a ? in its own header", btn.count()==1 and btn.is_visible())
        top=pg.evaluate(f"()=>Math.round(document.querySelector('#v-{page} .pghelp').getBoundingClientRect().top)")
        ck(f"{page}: it sits at the top of the page", top < 80, str(top))
        btn.click(); pg.wait_for_timeout(700)
        ck(f"{page}: help turns on", pg.locator(".help-box").count()>=2, pg.locator(".help-box").count())
        pg.locator("#helpExit").click(timeout=6000); pg.wait_for_timeout(400)
        ck(f"{page}: and off", pg.locator(".help-box").count()==0)

    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(400)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(700)
    body=pg.locator("#simpadbody").inner_text()
    ck("the empty Simulator names the real button",
       "Set up a combat" in body and "Choose units" not in body, body[:90])
    ck("and does not say there is no combat twice",
       body.lower().count("no combat")==1, body[:90])

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"HELP UI PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
