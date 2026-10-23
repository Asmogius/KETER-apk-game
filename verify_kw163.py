"""Revision 16.3 (Companion 14.11): the eleven keywords decided after the effect
box audit. In the library and the power score; offered by the keyword builder
where they belong; and carried out by the Battle Simulator: Troop and Hero
narrowing, all allies and all enemies, Aim in the odds, Hardened on each hit,
Draw, gain Aether, a Barricade put down, and Line and Cone shapes."""
import http.server, socketserver, threading, functools, pathlib, shutil, json
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_kw163")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP); shutil.copy("compendium_full.json", TMP / "compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9877), functools.partial(H, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, d=""):
    (ok if c else bad).append(n + ((" — " + str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ") + n + ("" if c else "  — " + str(d)[:260]))
hexes = [[f"{q},{r}", {}] for q in range(-5, 6) for r in range(-5, 6) if abs(q + r) <= 5]
FLOOR = {"v": 6, "name": "KW Test", "radius": 5, "hexes": hexes, "walls": [], "marks": [], "symDefs": [],
         "colorLabels": {"1": "Half Cover Barricade", "5": "Full Cover Barricade"}}
SETUP = """(spec)=>{
  var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}'); all['KW Test']=window.FLOOR_IN; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all));
  SIM.map=simLoadFloor('KW Test');
  SIM.units=spec.map(function(s){ var c=simAllCards().filter(function(x){ return x.name===s[0]; })[0];
    var u=KETER_RULES.unitFromCard(simUnitSpec(c,s[1]),s[1]); u.id=s[2]; u.pos={q:s[3],r:s[4]}; return u; });
  SIM.round=1; SIM.phase='turn'; SIM.log=[]; SIM.over=false; SIM.autoRunning=true;
  SIM.hand=[]; SIM.deck=[]; SIM.discard=[]; SIM.aether={}; SIM.pendingAct=null; SIM.burst=null;
  simApplyContinuous(); renderSim(); return SIM.units.length; }"""
U = "function(id){ return SIM.units.filter(function(u){ return u.id===id; })[0]; }"
NEW = ["Troop", "Hero", "all allies", "all enemies", "Aim", "Draw", "gain Aether", "Hardened", "Barricade", "Line", "Cone"]
with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_context(viewport={"width": 412, "height": 915}).new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("dialog", lambda d: d.accept())
    pg.goto("http://127.0.0.1:9877/"); pg.wait_for_timeout(2500)
    E = pg.evaluate
    E("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")

    # ---- the library ----
    r = E("""(names)=>{ var K=KETER_KW, S=KETER_SCORE; return {cats:names.map(function(n){ var k=K.byName(n); return k?k.cat:null; }), n:K.KEYWORDS.length,
      stats:K.STATS.indexOf('Aim')>=0,
      read:['[[Barricade Full]] on [[target tile]].','[[all allies]] [[Troop]] gain [[Aim +1]] for [[turns 1]].','[[target ally]] [[Hero]] gains [[Hardened 2]] for [[turns 1]].','[[gain Aether 1]]. [[Draw 2]].','[[target enemy]] takes [[damage 6]] with [[Line 4]].'].map(function(t){ return K.render(t); }),
      line:K.problems(K.analyse('[[Line 2]].'),{kind:'passive'}), bar:K.problems(K.analyse('[[Barricade Huge]] on [[target tile]].'),{kind:'action'}),
      barTile:K.problems(K.analyse('[[target ally]] gains [[Barricade Full]].'),{kind:'action'}),
      pts:[S.keywordPoints('[[all allies]] gain [[Aim +1]] for [[turns 1]].'), S.keywordPoints('[[all allies within 1]] gain [[Aim +1]] for [[turns 1]].'), S.keywordPoints('[[Line 4]].',{attack:true}), S.keywordPoints('[[Cone 2]].',{attack:true}), S.keywordPoints('[[Draw 2]].')]}; }""", NEW)
    ck("the library has the eleven: Troop, Hero, all allies and all enemies Targets; Aim a Stat; Draw, gain Aether and Barricade Effects; Hardened a Status; Line and Cone Modifiers",
       r["cats"] == ["target", "target", "target", "target", "stats", "effect", "effect", "status", "effect", "modifier", "modifier"] and r["n"] == 94 and r["stats"], r)
    ck("they read as cards print them", r["read"] == ["Full Cover Barricade on target tile.", "All Troop allies gain +1 Aim for 1 turn.", "Target Hero ally gains Hardened 2 for 1 turn.",
                                                      "Gain Aether 1. Draw 2.", "Target enemy takes damage 6 with Line 4 tiles."], r["read"])
    ck("the Card Forge flags a Line in a Passive, a Barricade that isn't Half or Full, and one not on a tile",
       r["line"] == ["Line is a shape an attack makes: put it on an Action"] and r["bar"] == ["Barricade needs Half or Full"] and r["barTile"] == ["Barricade goes on a tile: use target tile"], r)
    ck("power: a whole side counts as an area of 4 (x3, against x1.5 within 1); Line 4 and Cone 2 double an attack; Draw is 2 a card",
       r["pts"] == [9, 5, 8, 8, 4], r["pts"])
    # ---- the Workshop's blueprints ----
    r = E("""(names)=>{ var P=KETER_PROG; return {bp:names.map(function(n){ var b=P.blueprintOf(n); return b?[b.levels, b.caps]:null; }),
      inCat:names.every(function(n){ return P.catalog().some(function(c){ return c.name===n; }); }), melee:P.blueprintOf('Melee'), price:P.researchPrice?P.researchPrice('Aim',1):null}; }""", NEW)
    ck("all eleven are blueprints: the numbered ones in three levels (Aim up to 2/4/6, Line 2/3/4, the rest 1/2/3), the others in one; plain narrowing words stay free",
       r["inCat"] and r["melee"] is None and r["bp"] == [[1, None], [1, None], [1, None], [1, None], [3, [2, 4, 6]], [3, [1, 2, 3]], [3, [1, 2, 3]], [3, [1, 2, 3]], [1, None], [3, [2, 3, 4]], [3, [1, 2, 3]]], r)
    # ---- the builder ----
    r = E("""()=>{ var B=KETER_BUILDER;
      var att=B.offers({kind:'action', role:'ranged'}), sup=B.offers({kind:'action', role:'support'}), pas=B.offers({kind:'passive'});
      var tile=B.offers({kind:'action', role:'support'}, 'target tile'), ally=B.offers({kind:'action', role:'support'}, 'target ally');
      var rt=['[[Barricade Full]] on [[target tile]].','[[Draw 2]].','[[all enemies]] take [[damage 2]].'].map(function(t){ return B.build(B.fromSentence(t,{kind:'action'})); });
      return {attMods:att.mods, supMods:sup.mods, targets:att.targets, pasTargets:pas.targets, narrow:att.narrow, tileFx:tile.effects.indexOf('Barricade')>=0, allyFx:ally.effects.indexOf('Barricade')>=0, rt:rt}; }""")
    ck("the builder offers Line and Cone on an attack, not on a Support Action", "Line" in r["attMods"] and "Cone" in r["attMods"] and "Line" not in r["supMods"], r)
    ck("it offers all allies and all enemies as Targets, on Actions and Passives, and Troop and Hero to narrow them",
       "all allies" in r["targets"] and "all enemies" in r["targets"] and "all allies" in r["pasTargets"] and "Troop" in r["narrow"] and "Hero" in r["narrow"], r)
    ck("a Barricade is offered only on a target tile; and the builder writes these sentences back as they were", r["tileFx"] and not r["allyFx"]
       and r["rt"] == ["[[Barricade Full]] on [[target tile]].", "[[Draw 2]].", "[[all enemies]] take [[damage 2]]."], r)

    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(900)
    E("(g)=>{ window.FLOOR_IN=g; }", FLOOR)
    # ---- Troop and Hero; all allies and all enemies ----
    E(SETUP, [["Test Warden", "ally", "h1", 0, 0], ["Test Drone", "ally", "t1", 4, 0], ["Test Grunt", "enemy", "e1", -4, 4], ["Test Grunt", "enemy", "e2", 4, -4]])
    r = E("""()=>{ var U=""" + U + """, h=U('h1'), t=U('t1'), e1=U('e1'), e2=U('e2'), hp=[e1.hp,e2.hp];
      simRunText('[[all allies]] [[Troop]] gain [[AC +2]] for [[turns 1]].',{actor:h, sourceCard:'Test'});
      simRunText('[[all allies]] [[Hero]] gain [[MS +1]] for [[turns 1]].',{actor:h, sourceCard:'Test'});
      simRunText('[[all enemies]] take [[damage 2]].',{actor:h, sourceCard:'Test'});
      return {tAC:KETER_RULES.effective(t).ac-t.ac, hAC:KETER_RULES.effective(h).ac-h.ac, hMS:KETER_RULES.effective(h).ms-h.ms, tMS:KETER_RULES.effective(t).ms-t.ms, e:[hp[0]-e1.hp, hp[1]-e2.hp]}; }""")
    ck("all Troop allies reach the Troop across the floor and not the Hero; all Hero allies the Hero only", r["tAC"] == 2 and r["hAC"] == 0 and r["hMS"] == 1 and r["tMS"] == 0, r)
    ck("all enemies reach both Enemies, wherever they stand", r["e"] == [2, 2], r)
    # ---- Aim ----
    E(SETUP, [["Test Warden", "ally", "a1", 0, 0], ["Test Grunt", "enemy", "e1", 3, 0]])
    r = E("""()=>{ var U=""" + U + """, s=U('a1'), g=U('e1'), a=s.actions.filter(function(x){ return /ranged/i.test(x.role||''); })[0];
      var before=simOdds(s,a,g).p; simRunText('[[this Unit]] gains [[Aim +4]] for [[turns 2]].',{actor:s, sourceCard:'Test'}); var after=simOdds(s,a,g).p;
      var res=KETER_RULES.resolveAttack(s,a,g,{distance:3, rolls:{accuracy:(parseInt(a.hit,10)||10)-4, penetration:20}});
      return {a:a.name, before:before, after:after, hit:res.hit}; }""")
    ck("Aim +4: the Warden's To-Hit of 8 is worked out as 4, so its chance to hit goes from 13 in 20 to 17 in 20", abs(r["after"] / r["before"] - 17 / 13) < 1e-6, r)
    ck("and the rules agree, roll for roll", r["hit"] is True, r)
    # ---- Hardened ----
    r = E("""()=>{ var U=""" + U + """, g=U('e1'); simRunText('[[this Unit]] gains [[Hardened 2]] for [[turns 2]].',{actor:g, sourceCard:'Test'});
      var h0=g.hp; KETER_RULES.hit(g,5); var a=h0-g.hp; h0=g.hp; KETER_RULES.hit(g,2); var b=h0-g.hp;
      return {a:a, b:b}; }""")
    ck("Hardened 2: a hit of 5 deals 3, and one of 2 still deals 1", r == {"a": 3, "b": 1}, r)
    # ---- Draw and gain Aether ----
    E(SETUP, [["Test Warden", "ally", "h1", 0, 0], ["Test Grunt", "enemy", "e1", 3, 0]])
    r = E("""()=>{ var U=""" + U + """, h=U('h1'), g=U('e1'); var c=simAllCards().filter(function(x){ return x.name==='Test Stim'; })[0];
      SIM.deck=[simHandCardOf(c), simHandCardOf(c), simHandCardOf(c)]; SIM.hand=[];
      simRunText('[[Draw 2]].',{actor:h, sourceCard:'Test Warden'}); var hand=SIM.hand.length, deck=SIM.deck.length;
      simRunText('[[gain Aether 1]].',{actor:h, sourceCard:'Test Warden'});
      simRunText('[[Draw 2]].',{actor:g, sourceCard:'Test Grunt'}); simRunText('[[gain Aether 3]].',{actor:g, sourceCard:'Test Grunt'});
      return {hand:hand, deck:deck, after:SIM.hand.length, aether:JSON.stringify(SIM.aether)}; }""")
    ck("Draw 2 puts two cards from the Deck in your hand; on an Enemy's card it does nothing", r["hand"] == 2 and r["deck"] == 1 and r["after"] == 2, r)
    ck("gain Aether 1 gives 1 Aether of the card's District (3); an Enemy gains none", r["aether"] == '{"d3":1}', r)
    r = E("""()=>KETER_RULES.chipValue({cardType:'sphere', aetherValue:1, entries:[{kind:'Passive', text:'[[gain Aether 1]].'}]})""")
    ck("a Chip whose Passive gains Aether gives that much more (the Ledger Chip: 2)", r == 2, r)
    # ---- Barricade ----
    E(SETUP, [["Test Striker", "ally", "a1", -3, 0], ["Test Grunt", "enemy", "e1", 3, 0]])
    r = E("""()=>{ var U=""" + U + """, s=U('a1'), g=U('e1'); var before=simCoverFor(g,s);
      simRunText('[[Barricade Full]] on [[target tile]].',{actor:s, tile:{q:2,r:0}, sourceCard:'Test'});
      var kind=simKindAt(2,0), after=simCoverFor(g,s);
      SIM.log=[]; simRunText('[[Barricade Half]] on [[target tile]].',{actor:s, tile:{q:3,r:0}, sourceCard:'Test'});
      return {before:before, kind:kind, after:after, taken:SIM.log.map(function(l){ return l.text; }), still:simKindAt(3,0)}; }""")
    ck("a Full Cover Barricade goes on the empty tile, and the Enemy behind it now has Full Cover (4) against the shot", r["before"] == 0 and r["kind"] == "cover-full" and r["after"] == 4, r)
    ck("a tile with a Unit on it takes no Barricade, and the Log says why", r["still"] is None and any("needs an empty tile" in t for t in r["taken"]), r)
    # ---- Line and Cone ----
    E(SETUP, [["Test Striker", "ally", "a1", 0, 0], ["Test Grunt", "enemy", "e1", 1, 0], ["Test Grunt", "enemy", "e2", 2, 0], ["Test Grunt", "enemy", "e3", 3, 0], ["Test Grunt", "enemy", "e4", 2, -2], ["Test Grunt", "enemy", "e5", -1, 0]])
    r = E("""()=>{ var U=""" + U + """, s=U('a1'), ids=['e1','e2','e3','e4','e5'], hp=ids.map(function(i){ return U(i).hp; });
      simRunText('[[target enemy]] takes [[damage 4]] with [[Line 3]].',{actor:s, target:U('e1'), sourceCard:'Test'});
      var line=ids.map(function(i,k){ return hp[k]-U(i).hp; });
      ids.forEach(function(i,k){ U(i).hp=hp[k]; });
      simRunText('[[target enemy]] takes [[damage 4]] with [[Cone 2]].',{actor:s, target:U('e1'), sourceCard:'Test'});
      var cone=ids.map(function(i,k){ return hp[k]-U(i).hp; });
      return {line:line, cone:cone}; }""")
    ck("Line 3 from the Striker through its target hits the two Enemies behind it in the row, and not those off the line or behind the Striker", r["line"] == [4, 4, 4, 0, 0], r)
    ck("Cone 2 hits the wedge 2 tiles deep toward the target, not the Enemy behind the Striker", r["cone"][0] == 4 and r["cone"][1] == 4 and r["cone"][2] == 0 and r["cone"][4] == 0, r)
    # ---- the three test cards 14.11 adds, so the test cards use every keyword ----
    r = E("""()=>{ var K=window.KETER_KW, names=['Test Bulwark','Test Muster','Test Shockwave'], out={};
      names.forEach(function(n){ var c=simAllCards().filter(function(x){ return x.name===n; })[0];
        out[n]=c ? (c.effects||[]).map(function(e){ var kind=/passive|aura/i.test(e.kind||'')?'passive':'action';
          return K.sentences(e.text||'').flatMap(function(t){ return K.problems(K.analyse(t),{kind:kind}); }); }) : null; });
      return out; }""")
    ck("Test Bulwark, Test Muster and Test Shockwave are in the library, every sentence on them reading cleanly", all(v is not None and not any(v) for v in r.values()), r)
    E(SETUP, [["Test Warden", "ally", "h1", 0, 0], ["Test Bulwark", "ally", "b1", -1, 0], ["Test Drone", "ally", "t1", 0, 2], ["Test Grunt", "enemy", "e1", 1, 0], ["Test Grunt", "enemy", "e2", 2, 0], ["Test Grunt", "enemy", "e3", -4, 4]])
    r = E("""()=>{ var U=""" + U + """, all=function(n){ return simAllCards().filter(function(x){ return x.name===n; })[0]; };
      SIM.deck=[simHandCardOf(all('Test Stim')), simHandCardOf(all('Test Stim'))]; SIM.aether={generic:9};
      SIM.hand.push(simHandCardOf(all('Test Muster'))); simPlayCard(SIM.hand.length-1);
      var h=U('h1'), b=U('b1'), t=U('t1'), eff=KETER_RULES.effective;
      var muster={heroAim:eff(h).aim, bulwarkAim:eff(b).aim||0, troopsHard:[b,t].map(function(u){ return (u.statuses||[]).some(function(x){ return /hardened/i.test(x.name||x.k||x.id||''); }); }),
        heroHard:(h.statuses||[]).some(function(x){ return /hardened/i.test(x.name||x.k||x.id||''); }), aether:JSON.stringify(SIM.aether), hand:SIM.hand.length};
      var hp=['e1','e2','e3'].map(function(i){ return U(i).hp; });
      SIM.hand.push(simHandCardOf(all('Test Shockwave'))); simPlayCard(SIM.hand.length-1);
      var shock={dmg:['e1','e2','e3'].map(function(i,k){ return hp[k]-U(i).hp; }), hand:SIM.hand.map(function(c){ return c.name; }), deck:SIM.deck.length};
      return {muster:muster, shock:shock, log:SIM.log.map(function(l){ return l.text; })}; }""")
    m = r["muster"]
    ck("Test Muster: the Hero gains Aim 2, the Troops (not the Hero) Hardened 1, and 1 District 3 Aether goes in the Bank", m["heroAim"] == 2 and m["bulwarkAim"] == 0 and m["troopsHard"] == [True, True] and not m["heroHard"] and '"d3":1' in m["aether"], r)
    ck("Test Shockwave: every Enemy takes 1, however far, and a card is drawn", r["shock"]["dmg"] == [1, 1, 1] and r["shock"]["hand"] == ["Test Stim"] and r["shock"]["deck"] == 1, r)
    r = E("""()=>{ var U=""" + U + """, b=U('b1'), g=U('e1'), act=function(n){ return b.actions.filter(function(a){ return a.name===n; })[0]; };
      var hp=['e1','e2'].map(function(i){ return U(i).hp; }), w=U('h1').hp;
      simRunText(act('Breach Shot').text,{actor:b, target:U('h1'), damage:3, damaged:true, sourceCard:'Breach Shot'});
      var line=['e1','e2'].map(function(i,k){ return hp[k]-U(i).hp; });
      simRunText(act('Raise Wall').text,{actor:b, tile:{q:-2,r:1}, sourceCard:'Raise Wall'});
      return {line:line, warden:w-U('h1').hp, wall:simKindAt(-2,1), roles:[act('Breach Shot').role, act('Scatter Shot').role, act('Raise Wall').role]}; }""")
    ck("Test Bulwark: Breach Shot through the Warden carries its 3 on down the row, friend or foe; Raise Wall puts Full Cover on an empty tile", r["line"] == [3, 3] and r["wall"] == "cover-full", r)
    ck("no page errors", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"\nKW 16.3 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
