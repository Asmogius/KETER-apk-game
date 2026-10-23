"""The setup wizard (Hero -> Deck -> Prototypes -> Consumables -> Enemies),
filters throughout, and card play (Troop/Equipment/Action/Command)."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_cardplay")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9751),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

CARDS = [
 {"name":"Rictus","cardType":"hero","subtype":"cyborg",
  "affinities":[{"district":"3","level":4}],
  "stats":{"hp":"40","ac":"9","apT":"4","move":"4"},
  "abilities":[{"name":"Grinder","kind":"Active","role":"melee","text":"Deal 8 damage.",
                "energyCost":"2","damage":"8"}]},
 {"name":"\"Test\" Bot","cardType":"enemy","subtype":"mechanical","skullLevel":"1",
  "affinities":[{"district":"3"}],
  "stats":{"hp":"12","ac":"10","will":"2","move":"3"},
  "abilities":[{"name":"Bite","kind":"Combo","role":"melee","text":"Deal 3 damage.",
                "energyCost":"1","damage":"3"}]},
 {"name":"Field Medic","cardType":"troop","affinities":[{"district":"3"}],
  "aetherCost":{"generic":1,"affinity":0},
  "stats":{"hp":"18","nrg":"3","will":"3","move":"3"},
  "abilities":[]},
 {"name":"Servo Plating","cardType":"equipment","affinities":[{"district":"3"}],
  "aetherCost":{"generic":2,"affinity":0},
  "abilities":[{"name":"","kind":"Passive","text":"[[attached Unit]] gains [[HP +6]] [[while attached]]. [[attached Unit]] gains [[AC +1]] [[while attached]]."}]},
 {"name":"Overcharge","cardType":"action","affinities":[{"district":"3"}],
  "aetherCost":{"generic":1,"affinity":0},
  "abilities":[{"name":"","kind":"Active","text":"Deal 5 damage."}]},
 {"name":"Rally Cry","cardType":"command","affinities":[{"district":"3"}],
  "aetherCost":{"generic":2,"affinity":0},
  "abilities":[{"name":"","kind":"Active","text":"All allies gain +1 MS this round."}]},
]

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:200]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9751/"); pg.wait_for_timeout(2000)
    pg.evaluate("(m)=>localStorage.setItem('keter-app-master',JSON.stringify(m))",
                {"version":"99999","cards":CARDS})
    pg.evaluate("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    # Handbook 14.0: setup starts from a Strike Team, so the suite needs one
    pg.evaluate("""()=>{
      var raw=JSON.parse(localStorage.getItem('keter-app-master')||'{}');
      var m=(raw&&raw.cards)||(Array.isArray(raw)?raw:[]);
      var hero=m.filter(function(c){ return c.cardType==='hero'; })[0];
      var deck=[];
      m.filter(function(c){ return /^(troop|equipment|command|aether)$/.test(c.cardType||''); })
       .forEach(function(c){ for(var i=0;i<4;i++) deck.push('master|'+c.name); });
      localStorage.setItem('keter-app-loadouts', JSON.stringify([{v:2,name:'Suite Team',
        level:1, heroes:hero?['master|'+hero.name]:[], deck:deck.slice(0,14),
        actions:{}, pouch:{'basic|3':6}}]));
    }"""); pg.wait_for_timeout(150)
    deck_refs=["master|Field Medic","master|Servo Plating","master|Overcharge","master|Rally Cry"]
    loadout={"name":"Field Loadout","level":1,
             "teams":[{"hero":"master|Rictus","deck":deck_refs*2}]}
    pg.evaluate("(l)=>localStorage.setItem('keter-app-loadouts',JSON.stringify([l]))", loadout)
    pg.reload(); pg.wait_for_timeout(2200)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(800)

    # ---- esc() escapes quotes, which the wizard depends on ----
    ck("esc() escapes double quotes",
       pg.evaluate('()=>esc(\'"x"\')')=="&quot;x&quot;",
       pg.evaluate('()=>esc(\'"x"\')'))
    ck("esc() still escapes the basics",
       pg.evaluate("()=>esc('<a>&')")=="&lt;a&gt;&amp;")

    # ---- the map step comes first ----
    pg.locator("#simSetup").click(); pg.wait_for_timeout(700)
    ck("the map is chosen before anything else",
       pg.locator("#simMapSel").count()==1)
    pg.locator("#simMapSel").select_option(index=0)
    pg.locator("#simMapNext").click(); pg.wait_for_timeout(700)
    # ---- step 1: the Strike Team ----
    ck("the wizard starts on the Strike Team", pg.evaluate("()=>SIM_WIZ.step")=="team")
    ck("Strike Teams are offered", pg.locator("[data-wizteam]").count()>=1)
    ck("Next does nothing with no Team picked",
       pg.evaluate("()=>{var s=SIM_WIZ.step; document.getElementById('wizNext').click(); return SIM_WIZ.step===s;}"))
    pg.locator("[data-wizteam] b").first.click(); pg.wait_for_timeout(350)
    ck("picking one marks it", pg.evaluate("()=>SIM_WIZ.loadout")==0)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)

    # ---- step 2: who enters, and who leads ----
    ck("advances to the Heroes", pg.evaluate("()=>SIM_WIZ.step")=="heroes")
    ck("a Hero is entering", len(pg.evaluate("()=>SIM_WIZ.heroes"))>=1)
    ck("and one of them leads", bool(pg.evaluate("()=>SIM_WIZ.leader")))
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)

    # ---- step 3: Starting Troops, then the Enemies ----
    ck("Starting Troops comes next", pg.evaluate("()=>SIM_WIZ.step")=="troops")
    pg.locator("#wizNext").click(); pg.wait_for_timeout(450)
    ck("advances to the Enemies", pg.evaluate("()=>SIM_WIZ.step")=="enemies")
    ck("the Floor's Spawn tiles are described",
       "Enemy Spawn tile" in pg.locator("#modalBox").inner_text())
    ck("Auto and Manual are both offered", pg.locator("[data-wizfoemode]").count()==2)
    pg.locator('[data-wizfoemode="manual"]').click(); pg.wait_for_timeout(400)
    ck("Manual lists the Enemies", pg.locator("[data-wizfoemore]").count()>=1)
    ck("Skull Level is offered as a filter", pg.locator(".simf-facet").count()==1)
    pg.locator('[data-wizfoemore]').first.click(); pg.wait_for_timeout(250)
    ck("picking an Enemy counts it", pg.evaluate('()=>SIM_WIZ.foes["\\"Test\\" Bot"]')==1)

    # ---- finishing sets up the combat ----
    pg.locator("#wizNext").click(); pg.wait_for_timeout(500)
    pg.locator("#wizNext").click(); pg.wait_for_timeout(1200)
    ck("the Hero is on the board",
       pg.evaluate("()=>SIM.units.some(function(u){return u.name==='Rictus'&&u.side==='ally';})"))
    ck("the Enemy is on the board, quoted name intact",
       pg.evaluate('()=>SIM.units.some(function(u){return u.name==="\\"Test\\" Bot"&&u.side==="enemy";})'))
    ck("the Hero generates its Affinity in Aether",
       pg.evaluate("()=>SIM.aether.d3")==4, pg.evaluate("()=>SIM.aether"))
    ck("the assigned Deck is what got shuffled in",
       pg.evaluate("()=>SIM.deck.length + SIM.hand.length")==8,
       pg.evaluate("()=>[SIM.deck.length, SIM.hand.length]"))
    ck("card selection needed no separate Player-card step",
       pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='ally';}).length")==1)

    # ---- playing cards ------------------------------------------------
    # The opening hand is shuffled, so which types it holds varies. These
    # checks seed the hand from the real Deck, one of each type, so each play
    # path is exercised every run rather than by luck.
    pg.evaluate("""()=>{
      SIM.aether={generic:99,d3:99};
      var all=SIM.deck.concat(SIM.hand);
      function pick(t){ return all.filter(function(c){return c.type===t;})[0]; }
      SIM.hand=[pick('troop'),pick('equipment'),pick('action'),pick('command')]
        .filter(Boolean);
      SIM.discard=[]; renderSim();
    }""")
    pg.wait_for_timeout(300)
    ck("a card of each type is in hand", pg.evaluate("()=>SIM.hand.length")==4,
       pg.evaluate("()=>SIM.hand.map(function(c){return c.type;})"))

    # effects survive whichever shape the card was stored in
    fx = pg.evaluate("""()=>SIM.hand.map(function(c){
      return {t:c.type, n:(c.effects||[]).length}; })""")
    ck("every card carries its effects", all(f["n"]>0 for f in fx if f["t"]!="troop"),
       str(fx))

    # ---- Troop ----
    r = pg.evaluate("""()=>{
      var before=SIM.units.length;
      var i=SIM.hand.findIndex(function(c){return c.type==='troop';});
      simPlayCard(i);
      var u=SIM.units[SIM.units.length-1];
      return {added:SIM.units.length===before+1, hp:u.hpMax,
              spawn:simKindAt(u.pos.q,u.pos.r), discard:SIM.discard.length, card:(u.card||{}).name};
    }""")
    ck("playing a Troop puts it on the board", r["added"] is True, str(r))
    ck("it deploys on a Player Spawn tile", r["spawn"]=="spawn-ally", str(r))
    ck("it arrives with its own Health", r["hp"]==18, str(r))
    # v13.3 (Handbook, Sections 3 and 6): its card stays with it until it goes down
    ck("its card stays with the Troop, not yet in the discard", r["discard"]==0 and r["card"]=="Field Medic", str(r))

    # ---- Equipment ----
    eIdx=pg.evaluate("()=>SIM.hand.findIndex(function(c){return c.type==='equipment';})")
    pg.evaluate(f"()=>simPlayCard({eIdx})"); pg.wait_for_timeout(600)
    # the Unit is chosen on the board now: the ones that can carry it are lit
    ck("Equipment asks which Unit when several can carry it",
       len(pg.evaluate("()=>Object.keys(SIM.pick?SIM.pick.valid:{})"))==2,
       pg.evaluate("()=>SIM.pick?Object.keys(SIM.pick.valid).length:0"))
    pg.evaluate("""()=>{ var u=SIM.units.filter(function(x){return x.name==='Rictus';})[0];
      var pk=SIM.pick; SIM.pick=null; if(pk) pk.done(u); }"""); pg.wait_for_timeout(500)
    r = pg.evaluate("""()=>{
      var u=SIM.units.filter(function(x){return x.name==='Rictus';})[0];
      return {equipped:(u.equipment||[]).indexOf('Servo Plating')>=0,
              hp:u.hpMax, ac:window.KETER_RULES.effective(u).ac};
    }""")
    ck("it attaches to the Unit you chose", r["equipped"] is True, str(r))
    # Rictus is 40/9 from his card; before the Unit-build fix he was getting
    # the fallback 20/10, which is what these numbers used to assert
    ck("its +6 HP is applied", r["hp"]==46, str(r))
    ck("its +1 AC is applied", r["ac"]==10, str(r))
    pg.evaluate("()=>{var m=document.getElementById('modal'); if(m) m.classList.remove('on');}")
    pg.wait_for_timeout(200)

    # ---- Action ----
    aIdx=pg.evaluate("()=>SIM.hand.findIndex(function(c){return c.type==='action';})")
    hp0=pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='enemy';})[0].hp")
    pg.evaluate(f"()=>simPlayCard({aIdx})"); pg.wait_for_timeout(600)
    ck("a damaging Action asks for a target",
       pg.locator("[data-simacttarget]").count()>=1,
       pg.locator("[data-simacttarget]").count())
    pg.locator("[data-simacttarget]").first.click(); pg.wait_for_timeout(500)
    hp1=pg.evaluate("()=>SIM.units.filter(function(u){return u.side==='enemy';})[0].hp")
    ck("resolving it deals its damage", hp1==hp0-5, f"{hp0} -> {hp1}")

    # ---- Command ----
    cIdx=pg.evaluate("()=>SIM.hand.findIndex(function(c){return c.type==='command';})")
    if cIdx>=0:
        pg.evaluate(f"()=>simPlayCard({cIdx})"); pg.wait_for_timeout(400)
        ck("a Command is played and its text logged",
           pg.evaluate("""()=>SIM.log.some(function(l){
             return /Rally Cry/.test(l.text) && /MS/.test(l.text);})"""),
           pg.evaluate("()=>SIM.log.slice(-2).map(function(l){return l.text;})"))

    # ---- affordability ----
    pg.evaluate("""()=>{
      SIM.aether={};
      var all=SIM.deck.concat(SIM.discard);
      var c=all.filter(function(x){return x.cost && x.cost.generic>0;})[0];
      if(c) SIM.hand=[c];
      renderSim();
    }""")
    pg.wait_for_timeout(300)
    ck("a card you cannot pay for is shown as unaffordable",
       pg.locator(".fcard.off").count()>0)
    before=pg.evaluate("()=>SIM.hand.length")
    pg.evaluate("()=>simPlayCard(0)"); pg.wait_for_timeout(500)
    # the heading is upper-cased by the stylesheet, so compare case-insensitively
    ck("playing it explains the shortfall",
       "not enough aether" in pg.locator("#modalBox").inner_text().lower(),
       pg.locator("#modalBox").inner_text()[:90])
    ck("and nothing leaves the hand", pg.evaluate("()=>SIM.hand.length")==before)
    pg.evaluate("()=>{var m=document.getElementById('modal'); if(m) m.classList.remove('on');}")


    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:4]))
    b.close()
srv.shutdown()
print(f"CARD PLAY PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
