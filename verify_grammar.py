"""Revision 15.6: Conditions as grammar ([when] / [if] / [while] + who + event or
state), always-on Passives, narrowing words (subtypes, Archetypes, Districts),
the printed forms (tiles, "for 2 turns", capitals), and the keyword builder in
the Forge and the Chassis editor."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_grammar")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9941),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:300]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:300]))

LIB = r"""
window.T = {
  R: window.KETER_RULES, K: window.KETER_KW,
  clear: function(){ SIM.burst=null; SIM.pendingAct=null; SIM.units=[]; SIM.selected=null; SIM.pick=null; SIM.aim=null; SIM.halted=null; SIM.haltShown=false; SIM.phase='turn'; SIM.over=false;
    SIM.aether={generic:50,d3:50}; SIM_FORCE.length=0; SIM.log=[]; SIM.protos=[]; SIM.haltedPassives={}; SIM_EV.queue=[]; },
  put: function(name, side, q, r){
    SIM_DBG.place={card:name, side:side}; simDebugTap({q:q,r:r});
    var u=SIM.units[SIM.units.length-1]; if(!u||u.pos.q!==q||u.pos.r!==r) throw new Error('could not place '+name+' at '+q+','+r);
    u.nrg=Math.max(u.nrg,6); return u; },
  act: function(u, actName, t, rolls){
    var a=(u.actions||[]).filter(function(x){ return x.name===actName; })[0];
    if(!a) throw new Error(u.name+' has no Action '+actName);
    (rolls||[20,20]).forEach(function(v){ SIM_FORCE.push(v); });
    simConfirmAttack(u,t,a); SIM_FORCE.length=0; return a; },
  card: function(name, target){
    var c=simAllCards().filter(function(x){ return x.name===name; })[0];
    SIM.hand.push(simHandCardOf(c)); var i=SIM.hand.length-1;
    simPlayCard(i);
    if(SIM.pick){ var pk=SIM.pick; SIM.pick=null; pk.done(target); }
    return c; },
  st: function(u,n){ return T.R.statusN(u,n); },
  eff: function(u){ return T.R.effective(u); },
  mod: function(u,stat){ return (u.mods||[]).filter(function(m){ return m.stat===stat; }).reduce(function(t,m){ return t+m.amt; },0); },
  hurt: function(u, n, by){ var p=SIM_EV.dealer; SIM_EV.dealer=by||null; T.R.hit(u,n); SIM_EV.dealer=p; simCheckDowns(); renderSim(); },
  logs: function(){ return SIM.log.map(function(l){ return l.text; }); }
};
"""

with sync_playwright() as p:
    b=p.chromium.launch()
    ctx=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=ctx.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:300]))
    pg.goto("http://127.0.0.1:9941/"); pg.wait_for_timeout(2000)
    E=lambda js: pg.evaluate(js)

    # ================= the library =================
    r=E(r"""()=>{ var K=window.KETER_KW;
      var t='[[when]] [[an ally]] [[Sniper]] [[within 3]] [[takes damage]], [[that Unit]] gains [[heal 2]].';
      return {
        r1:K.render(t),
        r2:K.render('[[all allies within 2]] [[District 3]] gain [[AC +1]] for [[turns 2]].'),
        r3:K.render('[[target ally]] [[Sniper]] or [[Gunfighter]] gains [[Evasive 2]] [[turns 1]].'),
        r4:K.render('[[target enemy]] [[Melee]] [[Fighter]] takes [[Push 2]]. [[an enemy]] [[Assassin]]'),
        r5:K.render('[[Aura 1]]: [[all units within 1]] take [[damage 1]]. [[is within 1]]'),
        mig:[K.migrateText('[[if damaged]]'), K.migrateText('[[when deployed]]'), K.migrateText('[[when Incapacitated]]'),
             K.migrateText('[[if this Unit kills an Enemy]]'), K.migrateText('[[further than 3]]'), K.migrateText('[[closer than 2]]'),
             K.migrateText('[[further than]] 4')],
        cats:['when','if','while','takes damage','is below half HP','the target','an ally','that Unit','Melee','District','within','Sniper'].map(function(n){ var k=K.byName(n); return n+':'+(k?k.cat+'/'+(k.role||k.narrow||''):'none'); }),
        retiredArch:!!K.byName('Mechanical'),
        weights:K.KEYWORDS.filter(function(k){ return k.cat==='condition'; }).every(function(k){ return k.weight===0; })
      }; }""")
    ck("narrowing prints inside its Target, with an article and tiles", r["r1"]=="When a Sniper ally within 3 tiles takes damage, that Unit gains heal 2.", r["r1"])
    ck("the user's example reads as asked", r["r2"]=="All District 3 allies within 2 tiles gain +1 AC for 2 turns.", r["r2"])
    ck("two of a kind read as either", r["r3"]=="Target Sniper or Gunfighter ally gains Evasive 2 for 1 turn.", r["r3"])
    ck("different kinds read together, and 'an' becomes 'a' before a consonant", r["r4"]=="Target Melee Fighter enemy takes Push 2 tiles. An Assassin enemy", r["r4"])
    ck("every distance says tiles, singular for one", r["r5"]=="Aura 1 tile: all units within 1 tile take damage 1. Is within 1 tile", r["r5"])
    ck("old one-piece Conditions are rewritten as grammar", r["mig"]==[
        "[[if]] [[the target]] [[takes damage]]","[[when]] [[this Unit]] [[is deployed]]","[[when]] [[this Unit]] [[is Incapacitated]]",
        "[[if]] [[this Unit]] [[kills an enemy]]","[[if]] [[the target]] [[is further than 3]]","[[if]] [[the target]] [[is within 1]]",
        "[[if]] [[the target]] [[is further than 4]]"], r["mig"])
    ck("each piece has its category and part", r["cats"]==['when:condition/connector','if:condition/connector','while:condition/connector',
        'takes damage:condition/event','is below half HP:condition/state','the target:target/subject','an ally:target/subject',
        'that Unit:target/both','Melee:target/subtype','District:target/district','within:target/distance','Sniper:target/archetype'], r["cats"])
    ck("the retired origins are not Archetype keywords", r["retiredArch"] is False)
    ck("Conditions are not scored yet", r["weights"])

    r=E(r"""()=>{ var K=window.KETER_KW;
      function pr(t,kind){ return K.problems(K.analyse(t),{kind:kind}); }
      return {
        actWhen:pr('[[when]] [[this Unit]] [[takes damage]], [[this Unit]] gains [[heal 1]].','action'),
        actWhile:pr('[[while]] [[this Unit]] [[is below half HP]], [[this Unit]] gains [[heal 1]].','action'),
        actIf:pr('[[if]] [[the target]] [[takes damage]], [[target enemy]] gains [[Slowed 1]].','action'),
        pasIfAlone:pr('[[if]] [[this Unit]] [[is below half HP]], [[this Unit]] gains [[DMG +1]].','passive'),
        pasWhenIf:pr('[[when]] [[this Unit]] [[takes damage]], [[if]] [[this Unit]] [[is below half HP]], [[this Unit]] gains [[AC +2]] for [[turns 2]].','passive'),
        whenState:pr('[[when]] [[this Unit]] [[is below half HP]], [[this Unit]] gains [[heal 1]].','passive'),
        whileEvent:pr('[[while]] [[this Unit]] [[takes damage]], [[this Unit]] gains [[heal 1]].','passive'),
        roundSubj:pr('[[when]] [[this Unit]] [[the round begins]], [[this Unit]] gains [[heal 1]].','passive'),
        noSubj:pr('[[when]] [[takes damage]], [[this Unit]] gains [[heal 1]].','passive'),
        noSelf:pr('[[while]] [[this Unit]] [[is within 2]], [[this Unit]] gains [[AC +1]].','passive'),
        targetInPassive:pr('[[when]] [[the target]] [[takes damage]], [[this Unit]] gains [[heal 1]].','passive'),
        thatNoWhen:pr('[[that Unit]] gains [[heal 1]].','passive'),
        stray:pr('[[takes damage]], [[this Unit]] gains [[heal 1]].','passive'),
        subjAsTarget:pr('[[an enemy]] gains [[Slowed 1]].','action'),
        hasNeedsStatus:pr('[[while]] [[this Unit]] [[has]], [[this Unit]] gains [[AC +1]].','passive')
      }; }""")
    ck("an Action cannot use when", len(r["actWhen"])>0 and "Action" in r["actWhen"][0], r["actWhen"])
    ck("an Action cannot use while", any("while" in x for x in r["actWhile"]), r["actWhile"])
    ck("an Action's if may ask what it did", r["actIf"]==[], r["actIf"])
    ck("in a Passive, if follows a when", any("follows" in x for x in r["pasIfAlone"]), r["pasIfAlone"])
    ck("a trigger plus one check is fine", r["pasWhenIf"]==[], r["pasWhenIf"])
    ck("when needs an event, while needs a state", r["whenState"] and r["whileEvent"], [r["whenState"], r["whileEvent"]])
    ck("the round begins takes no one before it", any("no one" in x for x in r["roundSubj"]), r["roundSubj"])
    ck("an event needs to say who", any("who" in x for x in r["noSubj"]), r["noSubj"])
    ck("a distance from this Unit needs someone else", any("measured" in x for x in r["noSelf"]), r["noSelf"])
    ck("the target is for Actions", any("Actions" in x for x in r["targetInPassive"]), r["targetInPassive"])
    ck("that Unit needs a Condition that names someone", len(r["thatNoWhen"])>0, r["thatNoWhen"])
    ck("an event with no connector is flagged", any("connector" in x for x in r["stray"]), r["stray"])
    ck("an ally/enemy word is a Condition word, not a Target", len(r["subjAsTarget"])>0, r["subjAsTarget"])
    ck("gains/has must name a Status", any("Status" in x for x in r["hasNeedsStatus"]), r["hasNeedsStatus"])

    E("()=>{ localStorage.setItem('keter-custom-archetypes', JSON.stringify([{name:'Wrecker'}])); }")
    r=E("()=>{ var K=window.KETER_KW; K.registerArchetypes(['Monsterous']); return {custom:!!K.byName('Wrecker'), card:!!K.byName('Monsterous'), cat:(K.byName('Wrecker')||{}).narrow, list:K.archetypes().length}; }")
    ck("a custom Archetype is a narrowing word automatically", r["custom"] and r["cat"]=="archetype", r)
    ck("so is any Archetype a card carries", r["card"], r)

    # ================= the Simulator =================
    E("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2000)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    E("()=>simDebugStart('TEST · Hazards and Cover')"); pg.wait_for_timeout(1500)
    E(LIB)
    n0=len(errs)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2); renderSim(); renderSim(); renderSim();
      var on=T.eff(w).integrity-w.integrity, mods=(w.mods||[]).filter(function(m){ return m.dur==='passive'; }).length;
      var g=T.put('Test Grunt','enemy',0,-3); T.hurt(w, w.hp); var off=T.eff(w).integrity-w.integrity;
      return {on:on, mods:mods, off:off}; }""")
    ck("an always-on Passive is on once, however often the board redraws", r["on"]==1 and r["mods"]==1, r)
    ck("and off once its Unit is down", r["off"]==0, r)

    r=E(r"""()=>{ T.clear(); var s=T.put('Test Striker','ally',0,2); renderSim(); var full=T.eff(s).dmgFlat;
      s.hp=10; renderSim(); var low=T.eff(s).dmgFlat; s.hp=30; renderSim(); var healed=T.eff(s).dmgFlat;
      return {full:full, low:low, healed:healed}; }""")
    ck("while holds an effect on exactly while its state holds", r["full"]==0 and r["low"]==2 and r["healed"]==0, r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,3), j=T.put('Test Juggernaut','enemy',0,0);
      var ev=T.st(j,'Evasive'); T.hurt(j,5,w); var above=T.mod(j,'AC'); j.hp=20; T.hurt(j,1,w); var below=T.mod(j,'AC');
      var turns=(j.mods||[]).filter(function(m){ return m.stat==='AC'; }).map(function(m){ return m.dur+m.n; });
      return {ev:ev, above:above, below:below, turns:turns}; }""")
    ck("an always-on Status holds (Juggernaut Evasive 2)", r["ev"]==2, r)
    ck("when + if: a hit gives +2 AC only once below half Health", r["above"]==0 and r["below"]==2 and r["turns"]==["turns2"], r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,-1);
      T.act(w,'Pinning Volley',g,[1,1]); var miss=T.mod(g,'AC'); T.act(w,'Pinning Volley',g,[20,20]); var hit=T.mod(g,'AC');
      return {miss:miss, hit:hit}; }""")
    ck("when is attacked fires on a miss and on a hit alike", r["miss"]==1 and r["hit"]==2, r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,4), h=T.put('Test Hacker','enemy',0,-1);
      w.pos={q:0,r:3}; simEmit('moves',w); simCheckDowns(); var far=T.st(w,'Drained');
      w.pos={q:0,r:1}; simEmit('moves',w); simCheckDowns(); var near=T.st(w,'Drained');
      var h0=w.hp; w.pos={q:0,r:0}; w.hp=h0; var st0=T.st(w,'Drained');
      simPush(w,{q:0,r:-1},1); simCheckDowns(); var pushed=T.st(w,'Drained')-st0;
      return {far:far, near:near, pushed:pushed}; }""")
    ck("ends its move within: only a move that ends within 2", r["far"]==0 and r["near"]==1, r)
    ck("and being pushed is not a move", r["pushed"]==0, r)

    r=E(r"""()=>{ T.clear(); var s=T.put('Test Sapper','ally',0,2); s.hp=s.hpMax-5; var h0=s.hp;
      renderSim(); renderSim(); var still=s.hp; SIM.phase='draw'; simNextPhase(true); var after=s.hp;
      return {still:still-h0, after:after-h0, phase:SIM.phase}; }""")
    ck("when the round begins fires at Recharge, once", r["still"]==0 and r["after"]==1 and r["phase"]=="recharge", r)
    E("()=>{ SIM.phase='turn'; renderSim(); }")

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,1);
      T.card('Test Plating', w); var ac=T.mod(w,'AC');
      T.R.addStatus(w,'Slowed',2,'t'); simCheckDowns(); renderSim();
      return {ac:ac, slowed:T.st(w,'Slowed'), log:T.logs().filter(function(l){ return /Slowed/.test(l); }).slice(-2)}; }""")
    ck("Equipment's always-on Passive is on while attached", r["ac"]==2, r)
    ck("when attached Unit gains Slowed: it is shaken off at once", r["slowed"]==0, r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,4), o=T.put('Test Overseer','enemy',0,-1),
        gu=T.put('Test Gunner','enemy',2,-2), gr=T.put('Test Grunt','enemy',1,-1);
      var far=Object.keys(SIM.map.hexes).map(function(k){ var p=T.R.hexParse?T.R.hexParse(k):null; if(!p){ var a=k.split(',').map(Number); p={q:a[0],r:a[1]}; } return p; })
        .filter(function(t){ return T.R.hexDistance(t,{q:0,r:-1})>=5 && !simUnitAt(t.q,t.r); })[0];
      var gf=T.put('Test Grunt','enemy',far.q,far.r);
      T.hurt(gu,gu.hp); var afterRanged=T.mod(o,'DMG');
      T.hurt(gf,gf.hp); var afterFar=T.mod(o,'DMG');
      T.hurt(gr,gr.hp); var afterMelee=T.mod(o,'DMG');
      return {ranged:afterRanged, far:afterFar, melee:afterMelee, roles:gr.roles, arch:gr.archetypes}; }""")
    ck("narrowed subject: a Ranged ally going down does not count", r["ranged"]==0, r)
    ck("nor a Melee one out of range", r["far"]==0, r)
    ck("a Melee ally within 3 does", r["melee"]==1, r)
    ck("Units carry their subtypes and Archetypes", r["roles"]==["melee"] and r["arch"]==["Light Infantry"], r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,1);
      var h=w.hp; T.act(g,'Jab',w); var plain=h-w.hp; w.hp=w.hpMax; T.R.addStatus(w,'Slowed',1,'t'); w.statuses=w.statuses.filter(function(s){ return s.name!=='Weakened'; });
      var h2=w.hp; T.act(g,'Jab',w); var slowed=h2-w.hp; return {plain:plain, slowed:slowed}; }""")
    ck("if the target has Slowed: 1 more damage only then", r["slowed"]-r["plain"]==1, r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,1);
      w.actions.push({name:'Echo', tag:'Passive', text:'[[when]] [[this Unit]] [[deals damage]], [[target enemy]] takes [[damage 1]].'});
      g.actions.push({name:'Spite', tag:'Passive', text:'[[when]] [[this Unit]] [[takes damage]], [[target enemy]] takes [[damage 1]].'});
      var hw=w.hp, hg=g.hp; T.hurt(g,3,w);
      return {g:hg-g.hp, w:hw-w.hp, stopped:T.logs().some(function(l){ return /stopped after/.test(l); })}; }""")
    # Spite answers the first hit and Echo's extra point, but neither answers its own effect
    ck("a Passive never sets itself off, and a chain ends", r["g"]==3+1 and r["w"]==2 and not r["stopped"], r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), s=T.put('Test Striker','ally',1,2), d=T.put('Test Drone','ally',-1,2), g=T.put('Test Grunt','enemy',0,-3);
      SIM.leader=w.id; T.card('Test Rally'); return {w:T.mod(w,'AC'), s:T.mod(s,'AC'), d:T.mod(d,'AC')}; }""")
    ck("all Ranged allies within 3: the Ranged ones only", r["d"]==1 and r["s"]==0, r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), s=T.put('Test Striker','ally',1,2);
      var card={name:'X', effects:[{text:'[[target ally]] [[Fighter]] gains [[heal 2]].'}]};
      simCardNeeds(card);
      var K=window.KETER_KW;
      return {striker:simNarrowOK(s, card._aimNarrow, {actor:w}), warden:simNarrowOK(w, card._aimNarrow, {actor:w}),
              d3:simNarrowOK(w, K.analyse('[[target ally]] [[District 3]].').targets[0].narrow, {actor:w}),
              d1:simNarrowOK(w, K.analyse('[[target ally]] [[District 1]].').targets[0].narrow, {actor:w}),
              both:simNarrowOK(s, K.analyse('[[target ally]] [[Melee]] [[Sniper]].').targets[0].narrow, {actor:w}),
              either:simNarrowOK(s, K.analyse('[[target ally]] [[Sniper]] or [[Fighter]].').targets[0].narrow, {actor:w})}; }""")
    ck("an Archetype narrows who a card can target", r["striker"] and not r["warden"], r)
    ck("a District narrows by the Unit's Districts", r["d3"] and not r["d1"], r)
    ck("different kinds must both match; the same kind, either", (not r["both"]) and r["either"], r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), s=T.put('Test Striker','ally',1,2);
      SIM.leader=w.id;
      SIM.protos=[{name:'Test Aegis Core', fx:[{kind:'Passive', text:'[[all allies within 1]] gain [[AC +1]].'}]}];
      renderSim(); var next=T.mod(s,'AC'); s.pos={q:3,r:2}; renderSim(); var away=T.mod(s,'AC');
      return {next:next, away:away}; }""")
    ck("a Prototype's always-on Passive follows where everyone stands", r["next"]==1 and r["away"]==0, r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,1);
      w.actions.push({name:'Spikes', tag:'Passive', text:'[[all enemies within 1]] take [[damage 1]].'});
      var h=g.hp; renderSim(); renderSim(); var still=h-g.hp; SIM.phase='draw'; simNextPhase(true); var round=h-g.hp;
      SIM.phase='turn'; return {still:still, round:round}; }""")
    ck("an always-on Passive's damage happens once a round, at Recharge", r["still"]==0 and r["round"]==1, r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2); var m0=w.hpMax, h0=w.hp;
      w.actions.push({name:'Bulk', tag:'Passive', text:'[[this Unit]] gains [[HP +5]].'});
      renderSim(); renderSim(); renderSim(); var on=[w.hpMax-m0, w.hp-h0];
      w.actions.pop(); renderSim(); var off=[w.hpMax-m0, w.hp-h0];
      return {on:on, off:off}; }""")
    ck("an always-on +HP raises maximum and current Health once", r["on"]==[5,5], r)
    ck("and takes them back when it stops", r["off"]==[0,0], r)

    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,1);
      w.actions.push({name:'Bad', tag:'Passive', text:'[[if]] [[this Unit]] [[takes damage]], [[this Unit]] gains [[heal 1]].'});
      SIM.phase='draw'; simNextPhase(true); var first=SIM.halted; SIM.halted=null; SIM.haltShown=false;
      SIM.phase='draw'; simNextPhase(true); var second=SIM.halted; SIM.phase='turn';
      return {first:first, second:second}; }""")
    ck("a Passive that cannot run halts the fight once, not every round", bool(r["first"]) and not r["second"], r)
    E("()=>{ SIM.halted=null; SIM.haltShown=false; document.getElementById('modal').classList.remove('on'); }")

    # ---- the test cards added for 15.6 ----
    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,2), g=T.put('Test Grunt','enemy',0,-3); w.hp=w.hpMax-5; var h=w.hp;
      var b=T.put('Test Battery','ally',1,2); return {healed:w.hp-h}; }""")
    ck("Battery Jump Start: allies within 2 heal 2 as it is deployed", r["healed"]==2, r)
    r=E(r"""()=>{ T.clear(); var w=T.put('Test Warden','ally',0,3), g=T.put('Test Grunt','enemy',0,-1);
      T.card('Test Targeting Suite', w); var rng=T.mod(w,'RANGE'), ap=T.mod(w,'AP');
      T.act(w,'Pinning Volley',g,[1,1]); return {rng:rng, ap:ap, ev:T.st(w,'Evasive')}; }""")
    ck("Targeting Suite: +1 Range and +2 AP while attached", r["rng"]==1 and r["ap"]==2, r)
    ck("and when the wearer attacks, even missing, it is Evasive 1", r["ev"]==1, r)
    r=E(r"""()=>{ T.clear(); var s=T.put('Test Scout','ally',0,3), h=T.put('Test Hacker','enemy',2,-2), g=T.put('Test Grunt','enemy',-2,-1);
      h.pos={q:2,r:-1}; simEmit('moves',h); g.pos={q:-2,r:0}; simEmit('moves',g); simCheckDowns(); renderSim();
      var full=T.mod(s,'AP');
      SIM.units.forEach(function(u){ u.hp=u.hpMax-1; }); renderSim(); var none=T.mod(s,'AP');
      return {hacker:T.st(h,'Marked'), grunt:T.st(g,'Marked'), full:full, none:none}; }""")
    ck("Scout Spotter: a Cyber enemy that moves is Marked, a Melee one is not", r["hacker"]==1 and r["grunt"]==0, r)
    ck("Scout Steady Hands: +1 AP only while some District 3 Unit is at full Health", r["full"]==1 and r["none"]==0, r)
    r=E(r"""()=>{ T.clear(); var s=T.put('Test Scout','ally',0,3), g=T.put('Test Grunt','enemy',0,0);
      T.act(s,'Quick Shot',g,[1,1]); var miss=T.mod(s,'MS'); T.act(s,'Quick Shot',g,[20,20]); return {miss:miss, hit:T.mod(s,'MS')}; }""")
    ck("Scout Quick Shot: +1 Movement only when it deals damage", r["miss"]==0 and r["hit"]==1, r)
    E("()=>{ SIM.halted=null; SIM.haltShown=false; document.getElementById('modal').classList.remove('on'); }")
    ck("the Simulator raised no errors", len(errs)==n0, errs[n0:])

    # ================= the Forge =================
    pg.locator("#nav button[data-go='forge']").click(); pg.wait_for_timeout(3400)
    F=pg.frame_locator('#v-forge iframe'); W="document.querySelector('#v-forge iframe').contentWindow"
    r=E(f"""()=>{{ var B={W}.KETER_BRIDGE, c={W}.blankCard?{W}.blankCard('troop'):null; var fw={W};
      function card(abs, roles){{ var x=Object.assign(B.migrate({{type:'troop'}}), {{abilities:abs, roles:roles||{{melee:true}} }}); return x; }}
      var p1=B.computePings(card([{{tag:'Passive', role:'ranged', name:'P', text:'[[this Unit]] gains [[AC +1]].'}}]));
      var p2=B.computePings(card([{{tag:'Active', role:'ranged', name:'A', text:'[[target enemy]] takes [[damage 1]].'}}]));
      var p3=B.computePings(card([{{tag:'Passive', name:'W', text:'[[when]] [[this Unit]] [[takes damage]], [[this Unit]] gains [[AC +1]].'}}]));
      var p4=B.computePings(card([{{tag:'Active', role:'melee', name:'X', text:'[[when]] [[this Unit]] [[takes damage]], [[target enemy]] takes [[damage 1]].'}}]));
      var p5=B.computePings(card([{{tag:'Passive', name:'R', text:'[[all enemies within 1]] take [[damage 1]].'}}]));
      var runs=B.textRuns('[[if]] [[the target]] [[takes damage]], [[target enemy]] gains [[Slowed 2]] for [[turns 2]].').map(function(r){{ return r.t; }}).join('');
      var mig=B.migrate({{type:'troop', abilities:[{{text:'[[if damaged]], [[target enemy]] gains [[Slowed 1]].'}}]}}).abilities[0].text;
      function has(ps, rx){{ return ps.some(function(p){{ return rx.test(p[1]); }}); }}
      return {{passiveExempt:!has(p1,/subtypes/), activeFlagged:has(p2,/subtypes/), alwaysNoDur:!has(p1,/no Duration/),
               whenNeedsDur:has(p3,/no Duration/), actionWhen:has(p4,/cannot use/), roundInfo:has(p5,/once each round/),
               runs:runs, mig:mig}}; }}""")
    ck("Passives are exempt from the subtype rule", r["passiveExempt"], r)
    ck("an Active of the wrong subtype is still flagged", r["activeFlagged"], r)
    ck("an always-on Passive's Stats need no Duration", r["alwaysNoDur"], r)
    ck("a when-Passive's Stats still do", r["whenNeedsDur"], r)
    ck("the Forge flags an Action using when", r["actionWhen"], r)
    ck("and says an always-on Passive's damage comes once a round", r["roundInfo"], r)
    ck("the card prints the grammar as a sentence", r["runs"]=="If the target takes damage, target enemy gains Slowed 2 for 2 turns.", r["runs"])
    ck("an old card's Conditions are rewritten as it loads", r["mig"]=="[[if]] [[the target]] [[takes damage]], [[target enemy]] gains [[Slowed 1]].", r["mig"])

    # ---- the builder, walked through as a player would ----
    F.locator("#fType").select_option("troop"); pg.wait_for_timeout(600)
    if F.locator(".ability").count()==0:
        F.locator("#addAbility").click(); pg.wait_for_timeout(500)
    ab=F.locator(".ability").first
    ab.locator(".a-tag").select_option("Passive"); pg.wait_for_timeout(300)
    ab=F.locator(".ability").first
    ab.locator(".a-text").fill(""); ab.locator(".a-text").dispatch_event("input"); pg.wait_for_timeout(200)
    ck("each effect has a Build button", ab.locator(".a-build").count()==1)
    ab.locator(".a-build").click(); pg.wait_for_timeout(300)
    O=F.locator(".kb-ov")
    ck("the builder opens as a sheet", O.count()==1)
    labels=O.locator(".kb-o b").all_inner_texts()
    ck("a Passive is offered always on, when, or while", labels==["Always on","When something happens…","While something is true…"], labels)
    import re as _re
    def tap(text):
        O.locator(".kb-o").filter(has_text=_re.compile("^"+_re.escape(text))).first.click(); pg.wait_for_timeout(180)
    def chip(text):
        O.locator(".kb-chip").filter(has_text=_re.compile("^"+_re.escape(text)+"$")).first.click(); pg.wait_for_timeout(180)
    def btn(k):
        O.locator(f'[data-kb="{k}"]').first.click(); pg.wait_for_timeout(180)
    tap("When something happens")
    subj=O.locator(".kb-o b").all_inner_texts()
    ck("who it is about: legal subjects only", subj==["this Unit","an ally","an enemy","any Unit","the round"], subj)
    tap("this Unit")
    evs=O.locator(".kb-o b").all_inner_texts()
    ck("after when, events only, and none measured from this Unit itself", "takes damage" in evs and "is below half HP" not in evs and "ends its move within" not in evs, evs)
    tap("takes damage")
    sent=O.locator("#kbSent").inner_text()
    ck("the sentence builds as you go", sent.startswith("When this Unit takes damage"), sent)
    tap("No")
    tg=O.locator(".kb-o b").all_inner_texts()
    ck("a Passive's Targets are its own, never a tile", "target tile" not in tg and "this Unit" in tg, tg)
    tap("this Unit")
    chip("AC")
    O.locator('[data-kbstep="1"]').click(); pg.wait_for_timeout(100)
    btn("pv:ok")
    pow_=O.locator("#kbPow").inner_text()
    ck("the power score shows live", "Ability power" in pow_ and "This effect" in pow_, pow_)
    btn("next")
    if O.locator(".kb-t").inner_text().startswith("Any Modifiers"): btn("skip")
    ck("a Stats change in a when-Passive asks how long", O.locator(".kb-t").inner_text()=="How long does it last?", O.locator(".kb-t").inner_text())
    tap("for N turns"); btn("pv:ok")
    ck("it ends on the review", O.locator(".kb-t").inner_text()=="Review the effect", O.locator(".kb-t").inner_text())
    rows=O.locator(".kb-rv > span").all_inner_texts()
    ck("the review lists every part", rows[:4]==["Condition","Check","Target","Does"], rows)
    btn("insert"); pg.wait_for_timeout(300)
    txt=F.locator(".ability").first.locator(".a-text").input_value()
    ck("Insert writes the effect", txt=="[[when]] [[this Unit]] [[takes damage]], [[this Unit]] gains [[AC +2]] for [[turns 2]].", txt)
    ck("and lists it under the effect", F.locator(".ability").first.locator(".a-sent").count()==1)
    F.locator(".ability").first.locator(".a-sent").first.click(); pg.wait_for_timeout(300)
    ck("tapping an effect reopens it at the review", O.locator(".kb-t").inner_text()=="Review the effect")
    O.locator('[data-kbedit="target"]').click(); pg.wait_for_timeout(200)
    tap("all allies within")
    O.locator('[data-kbstep="1"]').click(); btn("pv:ok")
    ck("changing one part returns to the review", O.locator(".kb-t").inner_text()=="Review the effect", O.locator(".kb-t").inner_text())
    btn("insert"); pg.wait_for_timeout(300)
    txt=F.locator(".ability").first.locator(".a-text").input_value()
    ck("Replace rewrites that effect", txt=="[[when]] [[this Unit]] [[takes damage]], [[all allies within 2]] gain [[AC +2]] for [[turns 2]].", txt)
    # an Action is offered if, never when
    F.locator(".ability").first.locator(".a-tag").select_option("Active"); pg.wait_for_timeout(300)
    F.locator(".ability").first.locator(".a-build").click(); pg.wait_for_timeout(300)
    labels=O.locator(".kb-o b").all_inner_texts()
    ck("an Action is offered every time, or only if", labels==["Every time it is used","Only if…"], labels)
    tap("Only if")
    subj=O.locator(".kb-o b").all_inner_texts()
    ck("an Action's check may be about the target", subj[:2]==["the target","this Unit"], subj)
    tap("the target")
    evs=O.locator(".kb-o b").all_inner_texts()
    ck("and ask what the Action did to it", "takes damage" in evs and "moves" not in evs, evs)
    btn("x"); pg.wait_for_timeout(200)
    ck("closing leaves nothing behind", O.count()==0)
    ck("the Forge raised no errors", len(errs)==n0, errs[n0:])

    # ================= the Chassis editor =================
    E("()=>{ KETER_GO('chassis'); }"); pg.wait_for_timeout(700)
    pg.locator('[data-chopen="ch_test_general"]').click(); pg.wait_for_timeout(400)
    pg.locator('[data-chtrybuild="0"]').click(); pg.wait_for_timeout(300)
    O2=pg.locator(".kb-ov")
    labels=O2.locator(".kb-o b").all_inner_texts()
    ck("on a chassis, only what it allows: no if on the General frame", labels==["Every time it is used"], labels)
    O2.locator(".kb-o").first.click(); pg.wait_for_timeout(200)
    tg=O2.locator(".kb-o b").all_inner_texts()
    ck("its Targets only", tg==["target enemy","target ally","this Unit"], tg)
    O2.locator(".kb-o").filter(has_text=_re.compile("^target enemy")).first.click(); pg.wait_for_timeout(200)
    if O2.locator(".kb-t").inner_text().startswith("Narrow"): O2.locator('[data-kb="skip"]').click(); pg.wait_for_timeout(200)
    eff=O2.locator(".kb-chip").all_inner_texts()
    ck("and its effects only", sorted(eff)==["damage","heal"], eff)
    r=E("""()=>{ var C=window.KETER_CHASSIS, K=window.KETER_KW;
      var up=C.upgrade({name:'old', allowed:['if damaged','when deployed','WIL','damage'], stats:{}, role:'Ranged'});
      return {up:up.allowed, arch:C.keywordsIn('[[target ally]] [[Sniper]] gains [[heal 1]].'),
              chips:C.chipList().filter(function(k){ return k.name==='Archetype'; }).length,
              lazarus:C.get('ch_test_lazarus').allowed.length}; }""")
    ck("an older chassis's Conditions become their pieces", r["up"]==["if","the target","takes damage","when","this Unit","is deployed","INT","damage"], r["up"])
    ck("every Archetype is allowed as one chip", "Archetype" in r["arch"] and r["chips"]==1, r)
    ck("the shipped test chassis are refreshed when untouched", r["lazarus"]>=70, r)
    ck("no errors anywhere", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
sys.exit(1 if bad else 0)
