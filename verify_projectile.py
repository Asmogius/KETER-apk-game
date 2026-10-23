"""v13.9: what a Ranged Action fires. The Forge's Projectile choice (Bolt,
Shell, Beam or Spray) appears for a Ranged Action only, is saved in the card's
schema and read back, and isn't printed on the card; the Workshop's Ranged and
Cyber Actions have it too, and a design's Troop card carries it; and rules.js
hands it to a Unit's Action for the game to draw."""
import http.server, socketserver, threading, functools, pathlib, shutil
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_proj")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP); shutil.copy("compendium_full.json", TMP / "compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9971), functools.partial(H, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, d=""):
    (ok if c else bad).append(n + ((" — " + str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ") + n + ("" if c else "  — " + str(d)[:260]))

with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True).new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("dialog", lambda d: d.accept())
    pg.goto("http://127.0.0.1:9971/index.html"); pg.wait_for_timeout(1800)
    E = pg.evaluate

    # ---------- the Forge ----------
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    D = "document.querySelector('#v-forge iframe').contentDocument"
    BR = "document.querySelector('#v-forge iframe').contentWindow.KETER_BRIDGE"
    E(f"()=>{D}.getElementById('addAbility').click()"); pg.wait_for_timeout(900)
    pg.wait_for_function("()=>!!document.querySelector('#v-forge iframe').contentDocument.querySelector('.a-role')", timeout=8000)
    def role(r):
        E(f"""()=>{{var el={D}.querySelector('.a-role'); el.value='{r}'; el.dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
        pg.wait_for_timeout(400)
    role("melee")
    ck("a Melee Action has no Projectile", E(f"()=>!{D}.querySelector('.a-proj')"))
    role("ranged")
    opts = E(f"()=>{{var s={D}.querySelector('.a-proj'); return s?[[...s.options].map(o=>o.value), s.value]:null;}}")
    ck("a Ranged Action chooses its Projectile: Bolt, Shell, Beam or Spray, and starts as a Bolt", opts == [["bolt", "shell", "beam", "spray"], "bolt"], opts)
    help_ = E(f"()=>{D}.querySelector('.a-proj').closest('.field').getAttribute('data-help')||''")
    ck("its help says what each looks like, and that it changes nothing in the rules", "arcs over the board" in help_ and "changes nothing in the rules" in help_, help_)
    sch = E(f"()=>{BR}.toSchema({BR}.currentCard()).entries[0].projectile")
    ck("left as it starts, nothing is saved: a Bolt is the default", sch is None, sch)
    E(f"""()=>{{var s={D}.querySelector('.a-proj'); s.value='shell'; s.dispatchEvent(new Event('change',{{bubbles:true}}));}}""")
    pg.wait_for_timeout(300)
    sch = E(f"()=>{BR}.toSchema({BR}.currentCard()).entries[0]")
    ck("chosen, it is saved in the card's schema", sch.get("projectile") == "shell" and sch.get("role") == "ranged", sch)
    back = E(f"""()=>{{var B={BR}; var c=B.fromSchema(B.toSchema(B.currentCard())); return [c.abilities[0].proj, B.toSchema(c).entries[0].projectile];}}""")
    ck("and read back the same", back == ["shell", "shell"], back)
    odd = E(f"""()=>{{var B={BR}; var c=B.fromSchema({{cardType:'troop',name:'P',entries:[{{name:'a',kind:'Active',role:'ranged',projectile:'laser',text:''}},{{name:'b',kind:'Active',role:'ranged',projectile:'beam',text:''}}]}}); return c.abilities.map(a=>a.proj);}}""")
    ck("one it doesn't know is read as none (a Bolt)", odd == ["", "beam"], odd)
    role("support")
    sch = E(f"()=>{BR}.toSchema({BR}.currentCard()).entries[0].projectile")
    ck("an Action that stops being Ranged fires nothing", sch is None and E(f"()=>!{D}.querySelector('.a-proj')"), sch)

    # ---------- rules.js ----------
    r = E("""()=>{ var R=KETER_RULES;
      var u=R.unitFromCard({name:'P', cardType:'troop', stats:{hp:'10'}, entries:[{name:'Gun', kind:'Active', role:'ranged', attackRange:'4', toHit:'6', projectile:'spray', text:'[[target enemy]] takes [[damage 1]].'},
        {name:'Fist', kind:'Active', role:'melee', text:'[[target enemy]] takes [[damage 1]].'}]}, 'ally');
      return u.actions.map(function(a){ return a.proj; }); }""")
    ck("rules.js hands a Unit's Action what it fires, and none where none is set", r == ["spray", ""], r)

    # ---------- the Workshop ----------
    pg.goto("http://127.0.0.1:9971/index.html"); pg.wait_for_timeout(1800)
    E("()=>{ KETER_PROG.grant('ch:ch_test_threshold'); KETER_GO('workshop'); }"); pg.wait_for_timeout(400)
    pg.locator("#wsNew").click(); pg.locator('[data-wspick="ch_test_threshold"]').click(); pg.wait_for_timeout(300)
    sel = pg.locator('[data-wsproj="0"]')
    ck("a design's Ranged Action chooses its Projectile too, starting as a Bolt", sel.count() == 1 and sel.input_value() == "bolt" and E("()=>KETER_WORKSHOP.PROJECTILES") == ["bolt", "shell", "beam", "spray"])
    sel.select_option("beam"); pg.wait_for_timeout(600)
    r = E("""()=>{ var W=KETER_WORKSHOP, d=W.list().filter(function(x){ return !x.starter; })[0]; return d?[d.abilities[0].projectile, W.toCard(d).entries[0].projectile]:null; }""")
    ck("it is saved with the design, and its Troop card carries it", r == ["beam", "beam"], r)
    r = E("""()=>{ var W=KETER_WORKSHOP, d=W.blank(KETER_CHASSIS.get('ch_test_threshold'));
      d.abilities=[{name:'a',kind:'action',role:'Melee',energy:1,ap:2,projectile:'shell',text:''},{name:'b',kind:'action',role:'Ranged',energy:1,range:4,hit:6,ap:2,projectile:'laser',text:''},{name:'c',kind:'action',role:'Cyber',energy:1,range:3,hit:6,ap:2,projectile:'spray',text:''},{name:'d',kind:'passive',role:'',projectile:'beam',text:''}];
      return W.toCard(d).entries.map(function(e){ return e.projectile===undefined?null:e.projectile; }); }""")
    ck("only an attack with a range fires one, and only one the game knows", r == [None, None, "spray", None], r)
    ck("the starter fires a Bolt (it has none set)", E("()=>KETER_WORKSHOP.toCard(KETER_WORKSHOP.STARTER).entries[0].projectile===undefined"))
    ck("no page errors", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"\nPROJECTILE PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
