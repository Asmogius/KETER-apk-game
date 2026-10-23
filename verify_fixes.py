"""v14.0: the playtest's fixes (Handbook Revision 16.0). The locks (Stunned,
Rooted, Pinned and Marked: 2 turns at most, no second dose, a guard once over,
never from an always-on Passive); what an attack carries needs it to
Penetrate; Execute; Sacrifice never touches an Enemy; an area's price; a
chassis's best (lowest) to-hit; Overclock out of the keyword builder and
warned of in the Forge; and the master Enemies' to-hits. Each is checked in
rules.js, the Simulator, the keyword reader, the builder, scoring.js, the
Workshop and the Chassis editor, as the player meets it."""
import http.server, socketserver, threading, functools, pathlib, shutil, json, re
from playwright.sync_api import sync_playwright
TMP = pathlib.Path("/tmp/serve_fixes")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP); shutil.copy("compendium_full.json", TMP / "compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9973), functools.partial(H, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
ok, bad = [], []
def ck(n, c, d=""):
    (ok if c else bad).append(n + ((" — " + str(d)[:300]) if not c else ""))
    print(("PASS " if c else "FAIL ") + n + ("" if c else "  — " + str(d)[:300]))

# the checklist's tester: Units put on the board and Actions used with forced dice
LIB = r"""
window.T = {
  R: window.KETER_RULES,
  clear: function(){ SIM.burst=null; SIM.pendingAct=null; SIM.units=[]; SIM.selected=null; SIM.pick=null; SIM.aim=null; SIM.halted=null; SIM.phase='turn'; SIM.over=false;
    SIM.aether={generic:50,d3:50}; SIM_FORCE.length=0; SIM.log=[]; },
  put: function(name, side, q, r){
    SIM_DBG.place={card:name, side:side}; simDebugTap({q:q,r:r});
    var u=SIM.units[SIM.units.length-1]; if(!u||u.pos.q!==q||u.pos.r!==r) throw new Error('could not place '+name+' at '+q+','+r);
    u.nrg=Math.max(u.nrg,6); return u; },
  act: function(u, actName, t, rolls){
    var a=(u.actions||[]).filter(function(x){ return x.name===actName; })[0];
    if(!a) throw new Error(u.name+' has no Action '+actName);
    (rolls||[20,20]).forEach(function(v){ SIM_FORCE.push(v); });
    simConfirmAttack(u,t,a); SIM_FORCE.length=0; return a; },
  logs: function(){ return SIM.log.map(function(l){ return l.text; }); }
};
"""

with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_context(viewport={"width": 412, "height": 915}, is_mobile=True, has_touch=True).new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("dialog", lambda d: d.accept())
    pg.goto("http://127.0.0.1:9973/index.html"); pg.wait_for_timeout(1800)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2000)
    E = pg.evaluate

    # ---------- rules.js: the locks ----------
    r = E("""()=>{ var R=KETER_RULES, out={};
      ['Stunned','Rooted','Pinned','Marked'].forEach(function(nm){
        var u={id:'l', name:'L', side:'enemy', hp:10, hpMax:10, statuses:[]}, o={};
        R.addStatus(u, nm, null, null, 5); o.capped=R.statusTurns(u,nm);
        /* (it ticks in the half of the round it arrived in: whichever the page is in now) */
        var late=!!R.statusOf(u,nm).late, tick=function(l){ return l?R.turnEndTick([u]):R.rechargeTick([u]); };
        var again=R.addStatus(u, nm, null, null, 2); o.again=[R.statusTurns(u,nm), !!(again[0]&&again[0].resisted), R.lockBlock(u,nm)];
        tick(late); tick(late);
        o.ended=[R.hasStatus(u,nm), !!(u.guards&&(nm.toLowerCase() in u.guards)), R.lockBlock(u,nm)];
        R.addStatus(u, nm); o.guarded=R.hasStatus(u,nm);
        tick(!late); o.otherHalf=!!(u.guards&&(nm.toLowerCase() in u.guards));
        tick(late); R.addStatus(u, nm); o.after=[('guards' in u), R.hasStatus(u,nm)];
        out[nm]=o; });
      var pz={id:'p', name:'P', side:'enemy', hp:10, hpMax:10, statuses:[]};
      R.addStatus(pz,'Poisoned',2,null,2); R.addStatus(pz,'Poisoned',1,null,3);
      out.poison=[R.statusN(pz,'Poisoned'), R.statusTurns(pz,'Poisoned'), R.isLock('Poisoned')];
      out.consts=[R.LOCKS, R.LOCK_MAX_TURNS];
      return out; }""")
    for nm in ["Stunned", "Rooted", "Pinned", "Marked"]:
        o = r[nm]
        ck("rules.js: %s lasts 2 turns at most, however long it is given for" % nm, o["capped"] == 2, o)
        ck("rules.js: a second dose of %s does nothing while it lasts" % nm, o["again"] == [2, True, "already"], o)
        ck("rules.js: when %s ends, the Unit is guarded against it" % nm, o["ended"] == [False, True, "guard"] and o["guarded"] is False, o)
        ck("rules.js: the guard outlasts the other half of the round, and is gone a round on (%s)" % nm, o["otherHalf"] and o["after"] == [False, True], o)
    ck("rules.js: any other Status still adds both doses", r["poison"] == [3, 5, False], r["poison"])
    ck("rules.js: the locks are the four, at 2 turns", r["consts"] == [["stunned", "rooted", "pinned", "marked"], 2], r["consts"])

    # ---------- the Simulator ----------
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    E("()=>simDebugStart('TEST · Hazards and Cover')"); pg.wait_for_timeout(1500)
    E(LIB)
    r = E("""()=>{ T.clear();
      var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,-1); g.ac=99; var hp=g.hp;
      T.act(w,'Pinning Volley',g,[20,1]); var miss={pinned:T.R.hasStatus(g,'Pinned'), lost:hp-g.hp};
      g.ac=0; T.act(w,'Pinning Volley',g,[20,20]); return {miss:miss, through:{pinned:T.R.statusTurns(g,'Pinned'), lost:hp-g.hp}}; }""")
    ck("Simulator: a Ranged shot that hits but doesn't Penetrate gives no Status and no extra damage", r["miss"] == {"pinned": False, "lost": 0}, r)
    ck("Simulator: once it Penetrates, it carries them (Pinned 2, and 2 more damage)", r["through"]["pinned"] == 2 and r["through"]["lost"] == 6, r)
    r = E("""()=>{ T.clear();
      var s=T.put('Test Striker','ally',0,2), g=T.put('Test Grunt','enemy',0,1); g.ac=99;
      T.act(s,'Shoulder Check',g,[1]); var at=[g.pos.q,g.pos.r];
      var w=T.put('Test Warden','ally',1,2); w.ac=99; s.hp=5;
      T.act(w,'Field Medicine',s,[1,1]);
      return {pushed:at[0]!==0||at[1]!==1, healed:s.hp}; }""")
    ck("Simulator: a Melee blow that doesn't Penetrate pushes nobody", r["pushed"] is False, r)
    ck("Simulator: a Support Action always lands what it carries", r["healed"] == 10, r)
    r = E("""()=>{ T.clear();
      var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,-1);
      g.guards={stunned:false}; var n=SIM.log.length;
      simRunText('[[target enemy]] gains [[Stunned]].', {actor:w, target:g, sourceCard:'Test Stun'});
      var shrug=[T.R.hasStatus(g,'Stunned'), T.logs().slice(n)];
      var det=simUnitDetail(g);
      delete g.guards;
      simRunText('[[target enemy]] gains [[Rooted]].', {actor:w, target:g, sourceCard:'Test Root'}); n=SIM.log.length;
      simRunText('[[target enemy]] gains [[Rooted]].', {actor:w, target:g, sourceCard:'Test Root'});
      return {shrug:shrug, det:det.replace(/<[^>]+>/g,' '), already:[T.R.statusTurns(g,'Rooted'), T.logs().slice(n)]}; }""")
    ck("Simulator: a guarded Unit shrugs a Stun off, and the Log says why", r["shrug"][0] is False and any("just came out of a Stun and shrugs it off" in t for t in r["shrug"][1]), r["shrug"])
    ck("Simulator: a Unit's details say what it is guarded against", "Guarded: Stunned" in r["det"] and "until the same point of the next round" in r["det"], r["det"][-300:])
    ck("Simulator: a second Root does nothing, and says it is already Rooted", r["already"][0] == 1 and any("already Rooted" in t for t in r["already"][1]), r["already"])
    r = E("""()=>{ T.clear();
      var ex=T.put('Test Warden','ally',0,2), e1=T.put('Test Grunt','enemy',0,-1), e2=T.put('Test Grunt','enemy',1,-1), jg=T.put('Test Juggernaut','enemy',-1,0), ov=T.put('Test Overseer','enemy',2,-2);
      e1.hp=Math.floor(e1.hpMax/2)-1; e2.hp=Math.ceil(e2.hpMax/2); jg.hp=1; ov.hp=1; var n=SIM.log.length;
      simRunText('[[all enemies within 9]] face an [[Execute]].', {actor:ex, target:e1, sourceCard:'Test Execution'});
      var lg=T.logs().slice(n); n=SIM.log.length; ex.hp=1;
      simRunText('[[this Unit]] faces an [[Execute]].', {actor:ex, sourceCard:'Test Misfire'});
      return {e1:[e1.down, e1.hp], e2:!!e2.down, jg:!!jg.down, ov:!!ov.down, log:lg, mis:[!!ex.down, SIM.halted||'', T.logs().slice(n)]}; }""")
    ck("Simulator: Execute removes an Enemy below half its Health", r["e1"] == [True, 0] and "Test Grunt is Executed" in r["log"], r)
    ck("Simulator: one at half its Health or more is untouched, and the Log says so", r["e2"] is False and "Test Grunt is not weak enough to be Executed" in r["log"], r["log"])
    ck("Simulator: an Elite and a Mini-Boss never are", not r["jg"] and not r["ov"] and "Test Juggernaut is too strong to be Executed" in r["log"] and "Test Overseer is too strong to be Executed" in r["log"], r["log"])
    ck("Simulator: aimed at its own side, Execute is refused before anything happens", r["mis"][0] is False and "Execute removes an Enemy" in (r["mis"][1] + " ".join(r["mis"][2])), r["mis"])
    E("()=>{ SIM.halted=null; }")
    r = E("""()=>{ T.clear();
      var s=T.put('Test Striker','ally',0,2), g=T.put('Test Grunt','enemy',0,1), g2=T.put('Test Grunt','enemy',1,1); s.hp=s.hpMax-10; g.hp=12; var h0=s.hp;
      T.act(s,'Finisher',g,[20]); var low={down:!!g.down, healed:s.hp-h0};
      var h1=s.hp; T.act(s,'Finisher',g2,[20]);
      return {low:low, full:{down:!!g2.down, hp:g2.hp, healed:s.hp-h1}}; }""")
    ck("test card: the Striker's Finisher Executes an Enemy its blow leaves below half, and doesn't count it as its blow's kill", r["low"] == {"down": True, "healed": 0}, r)
    ck("test card: one it leaves at half or more is only hurt", r["full"]["down"] is False and r["full"]["hp"] == 13 and r["full"]["healed"] == 0, r)
    r = E("""()=>{ T.clear();
      var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,1);
      simApplyKeyword({kw:KETER_KW.byName('Sacrifice'), n:null}, [g], {actor:w}, null);
      return [!!g.down, T.logs().slice(-1)[0]]; }""")
    ck("Simulator: Sacrifice never removes an Enemy, and says so", r[0] is False and "is not a friendly Unit, so it cannot be Sacrificed" in r[1], r)

    # ---------- the keyword reader ----------
    r = E("""()=>{ var K=KETER_KW, P=function(t,k){ return K.problems(K.analyse(t),{kind:k||'action'}); }, out={};
      ['Stunned','Rooted','Pinned','Marked'].forEach(function(nm){
        out[nm]={always:P('[[all enemies within 2]] gain [[%]].'.replace('%',nm),'passive'),
                 when:P('[[when]] [[the round begins]], [[all enemies within 2]] gain [[%]].'.replace('%',nm),'passive'),
                 long:['[[turns 3]]','[[persistent]]','[[while attached]]'].map(function(d){ return P('[[target enemy]] gains [[%]] '.replace('%',nm)+d+'.'); }),
                 two:P('[[target enemy]] gains [[%]] for [[turns 2]].'.replace('%',nm))}; });
      out.exAlly=P('[[target ally]] faces an [[Execute]].'); out.exEnemy=P('[[target enemy]] faces an [[Execute]].').concat(P('[[all enemies within 2]] face an [[Execute]].'));
      out.over=P('[[Overclock]]: [[this Unit]] gains [[DMG +2]] for [[turns 2]].');
      out.kw=[K.byName('Execute').cat, K.byName('Execute').weight, K.byName('Stunned').weight, K.byName('Sacrifice').weight, K.KEYWORDS.length];
      return out; }""")
    for nm in ["Stunned", "Rooted", "Pinned", "Marked"]:
        o = r[nm]
        ck("checks: an always-on Passive cannot give %s; a triggered one can" % nm, any("always-on Passive" in x for x in o["always"]) and not any("always-on Passive" in x for x in o["when"]), o)
        ck("checks: %s for 3 turns, persistent or while attached is too long; for 2 it is fine" % nm, all((nm + " lasts 2 turns at most: use turns 1 or 2") in l for l in o["long"]) and o["two"] == [], o)
    ck("checks: Execute aimed at an ally is flagged, at an Enemy it is fine", r["exAlly"] == ["Execute removes an Enemy: use target enemy or all enemies within"] and r["exEnemy"] == [], r)
    ck("checks: Overclock stops nothing: the rest of its sentence still works", r["over"] == [], r["over"])
    ck("the library: Execute is an Effect worth 6; Stunned is worth 2 and Sacrifice nothing; 94 keywords (16.1: and Lunge, Charge, Dash and Leap; 16.3: eleven more)", r["kw"] == ["effect", 6, 2, 0, 94], r["kw"])

    # ---------- prices ----------
    r = E("""()=>{ var S=KETER_SCORE, d=function(t){ return S.keywordDetail(t); };
      return {areas:[1,2,3].map(function(n){ return d('[[all enemies within '+n+']] take [[damage 2]].'); }),
              one:d('[[target enemy]] takes [[damage 2]].'),
              both:[d('[[all allies within 2]] gain [[heal 2]]. [[this Unit]] gains [[heal 2]].').base, d('[[all allies within 2]] gain [[heal 2]].').base, d('[[this Unit]] gains [[heal 2]].').base,
                    d('[[all allies within 2]] gain [[heal 2]]. [[this Unit]] gains [[heal 2]].').mult, d('[[all allies within 2]] gain [[heal 2]]. [[this Unit]] gains [[heal 2]].').points],
              over:d('[[Overclock]]: [[this Unit]] gains [[DMG +2]] for [[turns 2]].').mult, f:[S.areaFactor(0), S.areaFactor(2)]}; }""")
    ck("prices: an area Target makes its sentence cost 1.5, 2 and 2.5 times as much at 1, 2 and 3 tiles", [a["base"] for a in r["areas"]] == [3, 4, 5] and r["areas"][1]["mods"] == [{"name": "area", "x": 2}], r["areas"])
    ck("prices: only the sentence with the area Target", r["both"][0] == r["both"][1] + r["both"][2] and r["both"][1] == 4 and r["both"][3] == 1 and r["both"][4] == r["both"][0], r["both"])
    ck("prices: Overclock multiplies by 1, and an area of 0 tiles by 1", r["over"] == 1 and r["f"] == [1, 2], r)

    # ---------- the keyword builder ----------
    O = pg.locator(".kb-ov")
    def tap(text):
        O.locator(".kb-o").filter(has_text=re.compile("^" + re.escape(text))).first.click(); pg.wait_for_timeout(150)
    def btn(k):
        O.locator(f'[data-kb="{k}"]').first.click(); pg.wait_for_timeout(150)
    def chips():
        return O.locator(".kb-chip").all_inner_texts()
    E("()=>KETER_BUILDER.open({kind:'passive', onDone:function(){}, onCancel:function(){}})"); pg.wait_for_timeout(300)
    tap("Always on")
    tap("all enemies within"); O.locator('[data-kbstep="1"]').click(); btn("pv:ok")
    if O.locator(".kb-t").inner_text().startswith("Narrow"): btn("skip")
    eff = chips()
    ck("builder: an always-on Passive is offered no lock", not any(k in eff for k in ["Stunned", "Rooted", "Pinned", "Marked"]) and "Slowed" in eff, eff)
    btn("x")
    E("()=>KETER_BUILDER.open({kind:'action', onDone:function(){}, onCancel:function(){}})"); pg.wait_for_timeout(300)
    tap("Every time it is used")
    tap("target ally")
    if O.locator(".kb-t").inner_text().startswith("Narrow"): btn("skip")
    eff = chips()
    ck("builder: Execute is not offered for an ally", "Execute" not in eff and "Stunned" in eff, eff)
    btn("back")
    if O.locator(".kb-t").inner_text().startswith("Narrow"): btn("back")
    tap("target enemy")
    if O.locator(".kb-t").inner_text().startswith("Narrow"): btn("skip")
    eff = chips()
    ck("builder: it is offered for an Enemy", "Execute" in eff, eff)
    O.locator(".kb-chip").filter(has_text=re.compile("^damage$")).first.click(); pg.wait_for_timeout(150)
    O.locator('[data-kbstep="1"]').click(); btn("pv:ok")
    O.locator(".kb-chip").filter(has_text=re.compile("^Execute$")).first.click(); pg.wait_for_timeout(150)
    btn("next")
    mods = chips() if O.locator(".kb-t").inner_text().startswith("Any Modifiers") else []
    ck("builder: Overclock is no longer offered among the Modifiers", "Overclock" not in mods and "Burst" in mods, mods)
    if O.locator(".kb-t").inner_text().startswith("Any Modifiers"): btn("skip")
    sent = O.locator("#kbSent").inner_text()
    ck("builder: it phrases Execute, after what else the sentence does", "target enemy takes damage 2 and faces an execute" in sent.lower(), sent)
    btn("x")
    r = E("""()=>{ var B=KETER_BUILDER; var st=B.fromSentence('[[all enemies within 2]] take [[damage 2]] and face an [[Execute]].');
      return [B.build(st), st.ownWords]; }""")
    ck("builder: and reads it back as it was", r == ["[[all enemies within 2]] take [[damage 2]] and face an [[Execute]].", False], r)
    E("()=>KETER_BUILDER.open({kind:'action', onDone:function(){}, onCancel:function(){}})"); pg.wait_for_timeout(300)
    tap("Every time it is used"); tap("target enemy")
    if O.locator(".kb-t").inner_text().startswith("Narrow"): btn("skip")
    O.locator(".kb-chip").filter(has_text=re.compile("^Stunned$")).first.click(); pg.wait_for_timeout(150)
    btn("next")
    if O.locator(".kb-t").inner_text().startswith("Any Modifiers"): btn("skip")
    durs = O.locator(".kb-o b").all_inner_texts()
    ck("builder: a lock's Duration is the default or a number of turns, never persistent", "for N turns" in durs and "persistent" not in durs, durs)
    tap("for N turns")
    for i in range(4): O.locator('[data-kbstep="1"]').click()
    v = O.locator("#kbNum").input_value()
    ck("builder: its turns step no higher than 2", v == "2", v)
    O.locator("#kbNum").fill("7"); btn("pv:ok")
    sent = O.locator("#kbSent").inner_text()
    ck("builder: and a number typed in is held to 2", sent.endswith("for 2 turns."), sent)
    btn("x")

    # ---------- the Forge: Overclock is warned of ----------
    pg.goto("http://127.0.0.1:9973/index.html"); pg.wait_for_timeout(1800)
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3000)
    W = "document.querySelector('#v-forge iframe').contentWindow"
    r = E(f"""()=>{{ var B={W}.KETER_BRIDGE; var c=B.fromSchema({{cardType:'action', name:'Test O', aetherCost:{{generic:1}}, entries:[{{name:'Routine', kind:'Active', role:'support', text:'[[Overclock]]: [[this Unit]] gains [[DMG +2]] for [[turns 2]].'}}]}});
      return B.pings(c).map(function(p){{ return [p[0], p[1]]; }}); }}""")
    ck("Forge: a card with Overclock is warned that it does nothing in a fight, and nothing else is flagged", any(p[0] == "warn" and "Overclock" in p[1] and "does nothing in a fight" in p[1] for p in r) and not any(p[0] == "bad" for p in r), r)
    r = E(f"""()=>{{ var B={W}.KETER_BRIDGE; var c=B.fromSchema({{cardType:'action', name:'Test S', aetherCost:{{generic:1}}, entries:[{{name:'Hold', kind:'Active', role:'support', text:'[[target enemy]] gains [[Stunned]] [[persistent]].'}}]}});
      return B.pings(c).map(function(p){{ return [p[0], p[1]]; }}); }}""")
    ck("Forge: a persistent Stun is flagged", any(p[0] == "bad" and "Stunned lasts 2 turns at most" in p[1] for p in r), r)

    # ---------- the Workshop and the Chassis editor: a best (lowest) to-hit ----------
    pg.goto("http://127.0.0.1:9973/index.html"); pg.wait_for_timeout(1800)
    r = E("""()=>{ var W=KETER_WORKSHOP, C=KETER_CHASSIS;
      return {best:[W.bestHit({bestHit:5}), W.bestHit({bestHit:0}), W.bestHit({bestHit:30}), W.bestHit({maxHit:8}), W.bestHit({maxHit:9}), W.bestHit({})],
              most:[W.maxOf({maxRange:5},'hit'), W.maxOf({maxRange:5},'range'), W.leastOf({bestHit:5},'hit'), W.leastOf({bestHit:5},'ap')],
              up:C.upgrade({name:'old', maxHit:8, stats:{}, subtypes:['Ranged'], allowed:[]}),
              blank:C.blank().bestHit, shipped:['ch_test_general','ch_test_threshold','ch_test_verdant','ch_test_meridian','ch_test_lazarus'].map(function(id){ var c=C.get(id); return [c.bestHit, 'maxHit' in c]; })}; }""")
    ck("Workshop: the best to-hit is read as given, held between 1 and 20", r["best"][:3] == [5, 1, 20], r["best"])
    ck("Workshop: a chassis from before reads its old maximum as 12 minus it, and none says 4", r["best"][3:] == [4, 3, 4], r["best"])
    ck("Workshop: a to-hit may go as high as 20; range and AP keep their maximums", r["most"] == [20, 5, 5, 0], r["most"])
    ck("Chassis: an older one is upgraded to a best to-hit, its maximum gone", r["up"].get("bestHit") == 4 and "maxHit" not in r["up"], r["up"])
    ck("Chassis: a new one's best is 4, and the shipped five carry theirs (5, 3, 6, 4, 4)", r["blank"] == 4 and r["shipped"] == [[5, False], [3, False], [6, False], [4, False], [4, False]], r)
    r = E("""()=>{ var W=KETER_WORKSHOP; KETER_PROG.setUnlockAll && KETER_PROG.setUnlockAll(true);
      var d=W.blank('ch_test_general'); d.abilities[0].text='[[target enemy]] takes [[damage 1]].';
      var out={start:d.abilities[0].hit, nine:W.blankAbility({bestHit:9, subtypes:['Ranged']},'action').hit};
      d.abilities[0].hit=3; out.better=W.check(d).reasons;
      d.abilities[0].hit=21; out.over=W.check(d).reasons;
      d.abilities[0].hit=5; out.fits=W.check(d).reasons.filter(function(x){ return /to-hit/.test(x); });
      out.pw=[5,6,12].map(function(h){ d.abilities[0].hit=h; return W.abilityPower(d.abilities[0], KETER_CHASSIS.get('ch_test_general')); });
      KETER_PROG.setUnlockAll && KETER_PROG.setUnlockAll(false);
      return out; }""")
    ck("Workshop: a new design's to-hit starts at the priced-at 6, or the chassis's best where that is worse", r["start"] == 6 and r["nine"] == 9, r)
    ck("Workshop: a to-hit better than the chassis's best doesn't fit", "ability 1's to-hit of 3 is better than this chassis's best of 5" in r["better"], r["better"])
    ck("Workshop: nor one over 20", "ability 1's to-hit of 21 is over 20, so it could never hit" in r["over"], r["over"])
    ck("Workshop: at the best, nothing is said of its to-hit", r["fits"] == [], r["fits"])
    ck("Workshop: a surer shot costs more", r["pw"][0] >= r["pw"][1] > r["pw"][2], r["pw"])
    E("()=>{ KETER_GO('workshop'); }"); pg.wait_for_timeout(400)
    pg.locator("#wsNew").click(); pg.locator('[data-wspick="ch_test_general"]').click(); pg.wait_for_timeout(400)
    head = E("()=>document.querySelector('.wschs').innerText")
    ck("Workshop: the design names its chassis's best to-hit", "to-hit 5 at best" in head and "range 5 and AP 5" in head, head)
    lab = E("""()=>{ var i=document.querySelector('[data-wsnum="0:hit"]'); return i?[i.closest('label').innerText, i.min, i.max]:null; }""")
    ck("Workshop: its To-Hit box says its best, and runs from it to 20", lab and "best 5" in lab[0] and lab[1] == "5" and lab[2] == "20", lab)
    E("()=>{ KETER_GO('chassis'); }"); pg.wait_for_timeout(600)
    pg.locator('[data-chopen="ch_test_threshold"]').click(); pg.wait_for_timeout(400)
    ed = E("""()=>{ var i=document.getElementById('chBestHit'); return i?[i.value, i.closest('label').innerText, !!document.getElementById('chMaxHit')]:null; }""")
    ck("Chassis editor: a Best To-Hit field in place of the most a to-hit could be", ed and ed[0] == "3" and "Best To-Hit" in ed[1] and ed[2] is False, ed)

    # ---------- the master Enemies ----------
    comp = json.loads(pathlib.Path("compendium_full.json").read_text())
    aims = [(c["name"], e.get("name"), int(e["toHit"])) for c in comp["cards"] if re.search("enemy|elite|boss", str(c.get("cardType", "")).lower()) and not c.get("testCard")
            for e in (c.get("entries") or []) if str(e.get("role", "")).lower() == "ranged" and str(e.get("toHit") or "").strip()]
    ck("the master Enemies aim at 8 to 10", aims and all(8 <= a[2] <= 10 for a in aims), aims)
    ck("no page errors", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"FIXES 14.0 PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
