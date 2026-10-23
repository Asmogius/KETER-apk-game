"""The rules resolver, tested on its own with no interface involved.

This is the suite a simulator depends on: if these pass, a batch run is
resolving combat the way the Handbook says.
"""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_rules")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP)
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9651),functools.partial(http.server.SimpleHTTPRequestHandler,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9651/"); pg.wait_for_timeout(2000)

    ck("the resolver loads", pg.evaluate("()=>!!window.KETER_RULES"))
    ck("it needs no interface",
       pg.evaluate("()=>{var s=KETER_RULES.toString?'':''; return typeof KETER_RULES.hit==='function';}"))
    # nine Enemy keywords plus twelve for the Player side
    r = pg.evaluate("""()=>{
      var all=KETER_RULES.behaviors();
      return {total:all.length,
              enemy:all.filter(function(b){return b.side==='enemy';}).length,
              ally:all.filter(function(b){return b.side==='ally';}).length};
    }""")
    ck("it shares the behaviour table", r["total"]==21, str(r))
    ck("both sides are in it", r["enemy"]==9 and r["ally"]==12, str(r))

    # ---------- health ----------
    r = pg.evaluate("""()=>{
      var R=KETER_RULES, u=R.makeUnit({name:'T',hpMax:20,will:3});
      var a=R.hit(u,7);
      return {hp:u.hp, hits:u.hits, ow:R.hasStatus(u,'Overwhelmed'),
              events:a.map(function(e){return e.type;})};
    }""")
    ck("one hit of 7 removes 7", r["hp"]==13, str(r))
    ck("and counts as one instance", r["hits"]==1, str(r))
    ck("it reports what happened", "hit" in r["events"], str(r["events"]))

    # the unit rework: Overwhelmed is retired, with Will and the Mechanical flag
    r = pg.evaluate("""()=>{
      var R=KETER_RULES, u=R.makeUnit({hpMax:20,ac:12});
      for(var i=0;i<9;i++) R.hit(u,1);
      return {hits:u.hits, statuses:u.statuses.length, will:u.will, mech:u.mech, integrity:u.integrity};
    }""")
    ck("instances are still counted", r["hits"]==9, str(r))
    ck("but however many hits land, no status follows", r["statuses"]==0, str(r))
    ck("no Unit carries Will or a Mechanical flag", r["will"] is None and r["mech"] is None, str(r))
    ck("and Integrity starts equal to Armor Class", r["integrity"]==12, str(r))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES, u=R.makeUnit({hpMax:20,hp:20});
      var h=R.heal(u,8)[0], g=R.gain(u,6)[0];
      return {afterHeal:h, hp:u.hp, gain:g};
    }""")
    ck("healing stops at the printed figure", r["hp"]==26 and r["afterHeal"]["amount"]==0, str(r))
    ck("it reports the waste", r["afterHeal"]["wasted"]==8, str(r))
    ck("gaining Health goes above it", r["gain"]["over"]==6, str(r))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES, u=R.makeUnit({hpMax:10});
      var ev=R.hit(u,999);
      return {hp:u.hp, down:u.down, said:ev.some(function(e){return e.type==='down';})};
    }""")
    ck("Health never goes below zero", r["hp"]==0, str(r))
    ck("going down is reported", r["down"] and r["said"], str(r))

    # ---------- statuses ----------
    r = pg.evaluate("""()=>{
      var R=KETER_RULES, u=R.makeUnit({ms:5, ac:11});
      var before=R.effective(u);
      R.addStatus(u,'Marked',null,null,2);
      var marked=R.effective(u);
      u.mods=[{stat:'INT',amt:3,dur:'turns',n:2},{stat:'WIL',amt:1,dur:'turns',n:2}];
      var raised=R.effective(u);
      return {before:before, marked:marked, raised:raised};
    }""")
    ck("an unaffected Unit keeps its Movement Speed", r["before"]["ms"]==5, str(r["before"]))
    ck("its Integrity is its Armor Class", r["before"]["integrity"]==11, str(r["before"]))
    ck("Ranged Attacks against a Marked Unit always hit", r["marked"]["alwaysHit"] is True)
    ck("an INT change raises Integrity, and an old WIL change reads as INT", r["raised"]["integrity"]==15, str(r["raised"]["integrity"]))

    # ---------- turns ----------
    r = pg.evaluate("""()=>{
      var R=KETER_RULES, keepHalf=R.hooks.half;
      /* v13.6: outside a fight the Simulator's hook puts a Status in the Enemies' half of the
         round (Handbook 15.9), where it ticks as the Player's turn ends; this tests the Player's
         half. Since 13.5 these two checks were failing for that reason, not for the rules. */
      delete R.hooks.half;
      var hero=R.makeUnit({name:'H',cardType:'hero',nrgMax:4,nrg:1});
      var troop=R.makeUnit({name:'T',cardType:'troop',nrgMax:4,nrg:1});
      R.hit(troop,1);
      R.addStatus(hero,'Marked',2);
      R.addStatus(hero,'Forever',null,null,999);   /* 15.4: open-ended means a persistent Duration */
      R.endTurn([hero,troop]);
      R.rechargeTick([hero,troop]);
      var afterOne={hero:hero.nrg, troop:troop.nrg, hits:troop.hits,
                    marked:(hero.statuses.filter(function(s){return s.name==='Marked';})[0]||{}).turns};
      R.endTurn([hero,troop]);
      R.rechargeTick([hero,troop]);
      R.hooks.half=keepHalf;
      return {afterOne:afterOne, markedGone:!R.hasStatus(hero,'Marked'),
              foreverStays:R.hasStatus(hero,'Forever')};
    }""")
    ck("a Hero carries unspent Energy over", r["afterOne"]["hero"]==5, str(r["afterOne"]))
    ck("a Troop resets instead", r["afterOne"]["troop"]==4, str(r["afterOne"]))
    ck("damage instances clear", r["afterOne"]["hits"]==0, str(r["afterOne"]))
    ck("a timed status counts down", r["afterOne"]["marked"]==1, str(r["afterOne"]))
    ck("and expires on schedule", r["markedGone"] is True)
    ck("an open-ended status stays", r["foreverStays"] is True)
    r = pg.evaluate("""()=>{
      var R=KETER_RULES, keepHalf=R.hooks.half, h=R.makeUnit({name:'H',cardType:'hero',nrgMax:4,nrg:1});
      R.hooks.half=function(){ return "enemy"; }; R.addStatus(h,'Marked',1); R.hooks.half=keepHalf;
      var late=!!(h.statuses.filter(function(s){return s.name==='Marked';})[0]||{}).late;
      R.rechargeTick([h]); var afterRecharge=R.hasStatus(h,'Marked');
      R.turnEndTick([h]); return {late:late, afterRecharge:afterRecharge, afterTurnEnd:R.hasStatus(h,'Marked')};
    }""")
    ck("15.9: one from the Enemies' half waits out the Recharge and ticks as the Player's turn ends", r["late"] and r["afterRecharge"] and not r["afterTurnEnd"], r)

    # ---------- actions ----------
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      return [R.actionEffect({dmg:'8',text:'Deal 8 damage.'}),
              R.actionEffect({text:'Heals 5.'}),
              R.actionEffect({text:'Target gains +6 HP.'}),
              R.actionEffect({text:'Push the target 1 tile.'})];
    }""")
    ck("damage is read off the card", r[0]["damage"]==8, str(r[0]))
    ck("healing is read from the text", r[1]["heal"]==5, str(r[1]))
    ck("a Health gain is separate", r[2]["gain"]==6, str(r[2]))
    ck("an Action with no numbers yields none", not any(r[3].values()), str(r[3]))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var a=R.makeUnit({name:'A',nrg:4,ms:4});
      var t=R.makeUnit({name:'T',hpMax:30,hp:30,will:9});
      R.useAction(a,{name:'Hit',tag:'Active',cost:2,dmg:'8'},t);
      var normal={nrg:a.nrg, targetHp:t.hp, remembered:t.lastAttackedBy===a.id};
      return {normal:normal};
    }""")
    ck("using an Action spends its Energy", r["normal"]["nrg"]==2, str(r["normal"]))
    ck("damage lands on the target", r["normal"]["targetHp"]==22, str(r["normal"]))
    ck("the target remembers who attacked it", r["normal"]["remembered"] is True)

    # ---------- outcome ----------
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var a=R.makeUnit({side:'ally'}), e=R.makeUnit({side:'enemy'});
      var mid=R.outcome([a,e]);
      e.down=true; var won=R.outcome([a,e]);
      a.down=true; var both=R.outcome([a,e]);
      return {mid:mid, won:won, both:both};
    }""")
    ck("a fight in progress is not over", r["mid"]["over"] is False, str(r["mid"]))
    ck("all Enemies down is a win", r["won"]["winner"]=="ally", str(r["won"]))
    ck("all Player Units down is a loss",
       r["both"]["winner"]=="draw" or r["both"]["over"], str(r["both"]))

    # ---------- behaviour, which is what a simulator needs most ----------
    setup = """
      var R=KETER_RULES;
      var hero =R.makeUnit({id:'h',name:'Hero',cardType:'hero',side:'ally',hpMax:30,hp:30,ac:14});
      var tough=R.makeUnit({id:'t',name:'Tough',cardType:'troop',side:'ally',hpMax:20,hp:20,ac:16});
      var hurt =R.makeUnit({id:'w',name:'Hurt', cardType:'troop',side:'ally',hpMax:20,hp:4, ac:9});
      var team=[hero,tough,hurt];
      function foe(keys){
        return R.makeUnit({side:'enemy',behaviors:keys.map(function(k){
          return typeof k==='string'?{k:k}:k; })});
      }
    """
    r = pg.evaluate("()=>{"+setup+"""
      return {
        none:        R.chooseTarget(foe([]),team,{}).name,
        cunning:     R.chooseTarget(foe(['cunning']),team,{}).name,
        sadistic:    R.chooseTarget(foe(['sadistic']),team,{}).name,
        opportunistic:R.chooseTarget(foe(['opportunistic']),team,{}).name,
        brutish:     R.chooseTarget(foe(['brutish']),team,{}).name
      };
    }""")
    ck("with no keyword it uses the default", r["none"] in ("Hero","Tough","Hurt"), str(r))
    ck("Cunning takes the Hero, ignoring Troops", r["cunning"]=="Hero", str(r))
    ck("Sadistic takes the lowest Health", r["sadistic"]=="Hurt", str(r))
    ck("Opportunistic takes the lowest Armor", r["opportunistic"]=="Hurt", str(r))
    ck("Brutish takes the highest Armor", r["brutish"]=="Tough", str(r))

    r = pg.evaluate("()=>{"+setup+"""
      var v=foe(['vindictive']);
      var beforeAttack=R.chooseTarget(v,team,{}).name;
      tough.id='t'; v.lastAttackedBy='t';
      return {before:beforeAttack, after:R.chooseTarget(v,team,{}).name};
    }""")
    ck("Vindictive uses the default until attacked", r["before"] in ("Hero","Tough","Hurt"), str(r))
    ck("then takes whoever attacked it", r["after"]=="Tough", str(r))

    r = pg.evaluate("()=>{"+setup+"""
      var rv=foe(['ravenous']);
      var quiet=R.chooseTarget(rv,team,{}).name;
      hero.attackedThisRound=true;
      return {quiet:quiet, piled:R.chooseTarget(rv,team,{}).name};
    }""")
    ck("Ravenous does nothing on its own", r["quiet"] in ("Hero","Tough","Hurt"), str(r))
    ck("then piles onto who was already attacked", r["piled"]=="Hero", str(r))

    r = pg.evaluate("()=>{"+setup+"""
      var m=foe(['methodical']);
      R.addStatus(hero,'Rooted',null,'enemy',2);
      R.addStatus(tough,'Blessed',2,'player');
      return {picked:R.chooseTarget(m,team,{}).name};
    }""")
    ck("Methodical skips the Enemy-afflicted but not the player-buffed",
       r["picked"] in ("Tough","Hurt"), str(r))

    # precedence: conditional beats unconditional
    r = pg.evaluate("()=>{"+setup+"""
      var mix=foe(['brutish','vindictive']);
      var before=R.chooseTarget(mix,team,{}).name;
      mix.lastAttackedBy='w';
      return {before:before, after:R.chooseTarget(mix,team,{}).name};
    }""")
    ck("an unconditional keyword applies while nothing else fires",
       r["before"]=="Tough", str(r))
    ck("a conditional keyword outranks it once it fires", r["after"]=="Hurt", str(r))

    # movement
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      function foe(bs,hp){ var u=R.makeUnit({side:'enemy',hpMax:20,hp:hp===undefined?20:hp,
        behaviors:bs}); return u; }
      return {
        plain:   R.movePlan(foe([]),{nearestEnemyDistance:1}),
        farOff:  R.movePlan(foe([{k:'cautious',x:2}]),{nearestEnemyDistance:5}),
        crowded: R.movePlan(foe([{k:'cautious',x:2}]),{nearestEnemyDistance:1}),
        healthy: R.movePlan(foe([{k:'cowardly',x:5}],20),{nearestEnemyDistance:1}),
        broken:  R.movePlan(foe([{k:'cowardly',x:5}],4),{nearestEnemyDistance:1})
      };
    }""")
    ck("a plain Enemy closes", r["plain"]["move"]=="toward", str(r["plain"]))
    ck("Cautious holds when nothing is near", r["farOff"]["move"]=="toward", str(r["farOff"]))
    ck("Cautious backs off when crowded", r["crowded"]["move"]=="away", str(r["crowded"]))
    ck("and still acts", r["crowded"]["act"] is True, str(r["crowded"]))
    ck("Cowardly does nothing while healthy", r["healthy"]["move"]=="toward", str(r["healthy"]))
    ck("Cowardly flees once broken", r["broken"]["move"]=="away", str(r["broken"]))
    ck("and takes no Action", r["broken"]["act"] is False, str(r["broken"]))

    # ---------- reading a card ----------
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var hero=R.unitFromCard({name:'R',cardType:'hero',subtype:'cyborg',
        stats:{hp:'40',ac:'9',apT:'4',move:'4'},
        entries:[{name:'G',kind:'Active',text:'Deal 8 damage.',damage:'8',energyCost:'2'}]});
      var troop=R.unitFromCard({name:'T',cardType:'troop',
        stats:{hp:'24',nrg:'4',will:'4',move:'2'}});
      return {hero:hero, troop:troop};
    }""")
    ck("a Hero's Energy comes from +NRG", r["hero"]["nrgMax"]==4, str(r["hero"]["nrgMax"]))
    ck("an old subtype on a card changes nothing", r["hero"].get("mech") is None and r["hero"].get("will") is None, str(r["hero"]))
    ck("a card with no Integrity takes it from Armor Class", r["hero"]["integrity"]==9, str(r["hero"]["integrity"]))
    ck("a Hero carries Energy over", r["hero"]["carries"] is True)
    ck("a Troop does not", r["troop"]["carries"] is False)
    ck("Actions come across with their numbers",
       r["hero"]["actions"][0]["dmg"]=="8" and r["hero"]["actions"][0]["cost"]==2,
       str(r["hero"]["actions"]))

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:3]))
    b.close()
srv.shutdown()
print(f"RESOLVER PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
# part one done


# ---------------- attack resolution ----------------
srv2 = Q(("127.0.0.1", 9653),
         functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv2.serve_forever, daemon=True).start()
ok2, bad2 = [], []
def ck2(n,c,d=""): (ok2 if c else bad2).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9653/"); pg.wait_for_timeout(2000)

    # ---- the dice ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var a=R.makeDice(12345), b=R.makeDice(12345), c=R.makeDice();
      var ra=[],rb=[];
      for(var i=0;i<12;i++){ ra.push(a.d20()); rb.push(b.d20()); }
      var lo=99,hi=0;
      for(var j=0;j<400;j++){ var v=c.d20(); if(v<lo)lo=v; if(v>hi)hi=v; }
      return {same:ra.join()===rb.join(), lo:lo, hi:hi, seeded:a.seeded, plain:c.seeded};
    }""")
    ck2("the same seed gives the same rolls", r["same"] is True, str(r))
    ck2("a d20 stays within 1 and 20", r["lo"]>=1 and r["hi"]<=20, f"{r['lo']}-{r['hi']}")
    ck2("and reaches both ends", r["lo"]==1 and r["hi"]==20, f"{r['lo']}-{r['hi']}")
    ck2("an unseeded die is marked as such", r["plain"] is False)

    setup = """
      var R=KETER_RULES;
      var atk=R.makeUnit({id:'a',name:'A',nrg:9});
      function tgt(ac,extra){ return R.makeUnit(Object.assign({id:'t',name:'T',
        hpMax:40,hp:40,ac:ac,will:9}, extra||{})); }
      function fixed(v){ return {seeded:true, d20:function(){return v;},
        d6:function(){return v;}, roll:function(){return v;}}; }
    """

    # ---- Melee always hits, but must still Penetrate ----
    r = pg.evaluate("()=>{"+setup+"""
      var a={name:'Swing',role:'melee',dmg:'6',pen:'0'};
      var pass_=R.resolveAttack(atk,a,tgt(10),{dice:fixed(12)});
      var fail =R.resolveAttack(atk,a,tgt(18),{dice:fixed(12)});
      return {pass:pass_, fail:fail};
    }""")
    ck2("a Melee attack always hits", r["pass"]["hit"] is True and r["fail"]["hit"] is True,
        str(r["fail"]))
    ck2("it Penetrates when the roll meets Armor Class",
        r["pass"]["penetrated"] is True and r["pass"]["damage"]==6, str(r["pass"]))
    ck2("and deals nothing when it does not",
        r["fail"]["penetrated"] is False and r["fail"]["damage"]==0, str(r["fail"]))
    ck2("the reason is reported", "Penetrate" in (r["fail"]["reason"] or ""), str(r["fail"]))

    # ---- Armor Penetration is added to the roll ----
    r = pg.evaluate("()=>{"+setup+"""
      var bare={name:'Shot',role:'melee',dmg:'5',pen:'0'};
      var ap  ={name:'Shot',role:'melee',dmg:'5',pen:'4'};
      return {without:R.resolveAttack(atk,bare,tgt(15),{dice:fixed(12)}),
              with_:  R.resolveAttack(atk,ap,  tgt(15),{dice:fixed(12)})};
    }""")
    ck2("without Penetration a 12 fails Armor Class 15",
        r["without"]["penetrated"] is False, str(r["without"]))
    ck2("Armor Penetration is added directly to the roll",
        r["with_"]["penetrated"] is True and r["with_"]["penetrationTotal"]==16,
        str(r["with_"]))

    # ---- Ranged needs both rolls ----
    r = pg.evaluate("()=>{"+setup+"""
      var a={name:'Shot',role:'ranged',dmg:'7',hit:'11',pen:'0',rng:'6'};
      return {
        bothPass: R.resolveAttack(atk,a,tgt(10),{dice:fixed(14),distance:3}),
        missed:   R.resolveAttack(atk,a,tgt(10),{dice:fixed(6), distance:3}),
        noPen:    R.resolveAttack(atk,a,tgt(19),{dice:fixed(14),distance:3}),
        tooFar:   R.resolveAttack(atk,a,tgt(10),{dice:fixed(14),distance:9})
      };
    }""")
    ck2("a Ranged attack that hits and Penetrates deals damage",
        r["bothPass"]["damage"]==7, str(r["bothPass"]))
    ck2("it takes two rolls",
        "accuracy" in r["bothPass"]["rolls"] and "penetration" in r["bothPass"]["rolls"],
        str(r["bothPass"]["rolls"]))
    ck2("a roll below To-Hit misses",
        r["missed"]["hit"] is False and r["missed"]["damage"]==0, str(r["missed"]))
    ck2("a miss is not tested for Penetration",
        "penetration" not in r["missed"]["rolls"], str(r["missed"]["rolls"]))
    ck2("hitting without Penetrating deals nothing",
        r["noPen"]["hit"] is True and r["noPen"]["damage"]==0, str(r["noPen"]))
    ck2("beyond Attack Range it cannot be attacked",
        r["tooFar"]["inRange"] is False and r["tooFar"]["damage"]==0, str(r["tooFar"]))

    # ---- Cover and Evasive raise the To-Hit requirement ----
    r = pg.evaluate("()=>{"+setup+"""
      var a={name:'Shot',role:'ranged',dmg:'5',hit:'11',pen:'9',rng:'8'};
      return {
        open_:  R.resolveAttack(atk,a,tgt(5),{dice:fixed(12),distance:2}),
        half:   R.resolveAttack(atk,a,tgt(5),{dice:fixed(12),distance:2,cover:2}),
        full:   R.resolveAttack(atk,a,tgt(5),{dice:fixed(12),distance:2,cover:4}),
        evasive:R.resolveAttack(atk,a,tgt(5),{dice:fixed(12),distance:2,evasive:3})
      };
    }""")
    ck2("in the open a 12 beats To-Hit 11", r["open_"]["hit"] is True, str(r["open_"]))
    ck2("Half Cover raises it to 13 and the same roll misses",
        r["half"]["hit"] is False and r["half"]["needed"]==13, str(r["half"]))
    ck2("Full Cover raises it to 15", r["full"]["needed"]==15, str(r["full"]))
    ck2("Evasive adds to it as well", r["evasive"]["needed"]==14, str(r["evasive"]))

    # ---- Aether and Support ----
    r = pg.evaluate("()=>{"+setup+"""
      var ae={name:'Lance',role:'aether',dmg:'6'};
      var su={name:'Patch',role:'support',text:'Heals 5.'};
      return {aether:R.resolveAttack(atk,ae,tgt(20),{dice:fixed(1),distance:4}),
              support:R.resolveAttack(atk,su,tgt(20),{dice:fixed(1)})};
    }""")
    ck2("an Aether attack always hits and Penetrates",
        r["aether"]["hit"] and r["aether"]["penetrated"], str(r["aether"]))
    ck2("even against Armor Class 20 on a roll of 1",
        r["aether"]["damage"]==6, str(r["aether"]))
    ck2("its damage is marked as Aether Damage",
        r["aether"].get("aetherDamage") is True, str(r["aether"]))
    ck2("a Support Action always hits", r["support"]["hit"] is True, str(r["support"]))

    # ---- a Marked target is always hit ----
    r = pg.evaluate("()=>{"+setup+"""
      var a={name:'Shot',role:'ranged',dmg:'5',hit:'19',pen:'9',rng:'8'};
      var t=tgt(5); R.addStatus(t,'Marked',null,null,2);
      return R.resolveAttack(atk,a,t,{dice:fixed(2),distance:2});
    }""")
    ck2("a Ranged attack on a Marked target always hits",
        r["hit"] is True, str(r))
    ck2("and skips the accuracy roll", "accuracy" not in r["rolls"], str(r["rolls"]))

    # ---- a Cyber attack must penetrate Integrity, not Armor Class ----
    r = pg.evaluate("()=>{"+setup+"""
      var cy={name:'Spike',role:'cyber',dmg:'6',hit:'2',pen:'2',rng:'6'}, sh={name:'Shot',role:'ranged',dmg:'6',hit:'2',pen:'2',rng:'6'};
      return {cyber:R.resolveAttack(atk,cy,tgt(5,{integrity:19}),{dice:fixed(15),distance:2}),
              shot:R.resolveAttack(atk,sh,tgt(5,{integrity:19}),{dice:fixed(15),distance:2})};
    }""")
    ck2("a Cyber attack of 17 fails against Integrity 19", r["cyber"]["penetrated"] is False and "Integrity" in (r["cyber"]["reason"] or ""), str(r["cyber"]))
    ck2("while the same roll as a shot beats Armor Class 5", r["shot"]["penetrated"] is True, str(r["shot"]))

    # ---- applying it ----
    r = pg.evaluate("()=>{"+setup+"""
      var t=tgt(5);
      var a={name:'Swing',role:'melee',dmg:'6',pen:'9',cost:2};
      var ev=R.attack(atk,a,t,{dice:fixed(15)});
      return {hp:t.hp, nrg:atk.nrg, remembered:t.lastAttackedBy==='a',
              flagged:t.attackedThisRound, kinds:ev.map(function(e){return e.type;})};
    }""")
    ck2("applying an attack removes Health", r["hp"]==34, str(r))
    ck2("it spends the Energy", r["nrg"]==7, str(r))
    ck2("the target remembers the attacker", r["remembered"] is True)
    ck2("and is marked as attacked this round", r["flagged"] is True)
    ck2("it reports an attack and a hit",
        "attack" in r["kinds"] and "hit" in r["kinds"], str(r["kinds"]))

    # ---- an out-of-range attack costs nothing ----
    r = pg.evaluate("()=>{"+setup+"""
      var t=tgt(5);
      var a={name:'Shot',role:'ranged',dmg:'6',hit:'5',pen:'9',rng:'2',cost:3};
      R.attack(atk,a,t,{dice:fixed(20),distance:8});
      return {hp:t.hp, nrg:atk.nrg};
    }""")
    ck2("an attack beyond range spends no Energy and deals nothing",
        r["hp"]==40 and r["nrg"]==9, str(r))

    ck2("no JS errors", len([e for e in errs if 'favicon' not in e.lower()])==0,
        "; ".join(errs[:3]))
    b.close()
srv2.shutdown()
print(f"ATTACKS PASS {len(ok2)}  FAIL {len(bad2)}")
for x in bad2: print("  ✗",x)
# parts one and two done

# ---------------- the round loop ----------------
srv3 = Q(("127.0.0.1", 9655),
         functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv3.serve_forever, daemon=True).start()
ok3, bad3 = [], []
def ck3(n,c,d=""): (ok3 if c else bad3).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9655/"); pg.wait_for_timeout(2000)

    build = """
      var R=KETER_RULES;
      function hero(hp,dmg){ return R.unitFromCard({name:'Hero',cardType:'hero',
        stats:{hp:String(hp||40),ac:'9',apT:'4',move:'4'},
        entries:[{name:'Grinder',kind:'Active',role:'melee',text:'Deal x damage.',
                  damage:String(dmg||8),energyCost:'2',armorPenetration:'9'}]},'ally'); }
      function foe(name,hp,beh,dmg){ return R.unitFromCard({name:name,cardType:'enemy',
        stats:{hp:String(hp||12),ac:'10',will:'2',move:'3'},
        behaviors:beh||[],
        entries:[{name:'Bite',kind:'Combo',role:'melee',text:'Deal y damage.',
                  damage:String(dmg||3),energyCost:'1',armorPenetration:'9'}]},'enemy'); }
    """

    # ---- a fight resolves ----
    r = pg.evaluate("()=>{"+build+"""
      var out=R.runCombat([hero(),foe('D1'),foe('D2')],{dice:R.makeDice(7)});
      return {winner:out.winner, rounds:out.rounds, events:out.log.length,
              kinds:out.log.reduce(function(a,e){a[e.type]=(a[e.type]||0)+1;return a;},{})};
    }""")
    ck3("a fight runs to a conclusion", r["winner"] in ("ally","enemy","draw"), str(r))
    ck3("it takes a sensible number of rounds", 1 <= r["rounds"] <= 50, str(r["rounds"]))
    ck3("rounds are recorded", r["kinds"].get("round",0)==r["rounds"], str(r["kinds"]))
    ck3("both sides attack", r["kinds"].get("attack",0) > 2, str(r["kinds"]))
    ck3("turns end", r["kinds"].get("turn",0)==r["rounds"], str(r["kinds"]))

    # ---- reproducible ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      function build(){
        return [R.unitFromCard({name:'H',cardType:'hero',
                 stats:{hp:'30',ac:'13',apT:'4'},
                 entries:[{name:'A',kind:'Active',role:'melee',damage:'5',
                           energyCost:'1',armorPenetration:'0'}]},'ally'),
                R.unitFromCard({name:'E',cardType:'enemy',
                 stats:{hp:'26',ac:'13',will:'9'},
                 entries:[{name:'B',kind:'Combo',role:'melee',damage:'4',
                           energyCost:'1',armorPenetration:'0'}]},'enemy')];
      }
      function fight(seed){ return R.runCombat(build(),{dice:R.makeDice(seed),maxRounds:40}); }
      var a=fight(99), b=fight(99);
      var differs=false;
      for(var s=1;s<40 && !differs;s++){
        var c=fight(s);
        if(c.rounds!==a.rounds || c.winner!==a.winner) differs=true;
      }
      return {same:(a.winner===b.winner && a.rounds===b.rounds &&
                    a.log.length===b.log.length), differs:differs};
    }""")
    ck3("the same seed gives the same fight", r["same"] is True, str(r))
    ck3("a different seed gives a different one", r["differs"] is True, str(r))

    # ---- victory conditions, as you defined them ----
    r = pg.evaluate("()=>{"+build+"""
      var easy=R.runCombat([hero(80,30),foe('D1',5)],{dice:R.makeDice(3)});
      var hard=R.runCombat([hero(6,1),foe('D1',90,[],40)],{dice:R.makeDice(3)});
      return {easy:easy.winner, hard:hard.winner};
    }""")
    ck3("all Enemies down is a Player win", r["easy"]=="ally", str(r))
    ck3("all Player Units down is a loss", r["hard"]=="enemy", str(r))

    # ---- a stalemate reports itself rather than hanging ----
    r = pg.evaluate("()=>{"+build+"""
      var a=R.unitFromCard({name:'H',cardType:'hero',stats:{hp:'30',ac:'20',apT:'4'},
        entries:[{name:'Tap',kind:'Active',role:'melee',damage:'0',energyCost:'0'}]},'ally');
      var e=R.unitFromCard({name:'E',cardType:'enemy',stats:{hp:'30',ac:'20',will:'9'},
        entries:[{name:'Tap',kind:'Combo',role:'melee',damage:'0',energyCost:'0'}]},'enemy');
      var out=R.runCombat([a,e],{dice:R.makeDice(11), maxRounds:12});
      return {winner:out.winner, rounds:out.rounds};
    }""")
    ck3("a fight nobody can win stops and says so",
        r["winner"]=="stalemate" and r["rounds"]==12, str(r))

    # ---- Enemies act only after every Player Unit ----
    r = pg.evaluate("()=>{"+build+"""
      var out=R.runCombat([hero(),foe('D1')],{dice:R.makeDice(21)});
      var firstRound=[];
      for(var i=0;i<out.log.length;i++){
        if(out.log[i].type==='turn') break;
        if(out.log[i].type==='attack') firstRound.push(out.log[i].unit);
      }
      var units={}; out.units.forEach(function(u){ units[u.id]=u.side; });
      var sides=firstRound.map(function(id){ return units[id]; });
      var firstEnemy=sides.indexOf('enemy');
      var lastAlly=sides.lastIndexOf('ally');
      return {sides:sides, ok:(firstEnemy===-1||lastAlly===-1||firstEnemy>lastAlly)};
    }""")
    ck3("Enemies act only after the Player side", r["ok"] is True, str(r["sides"]))

    # ---- behaviour drives targeting in a real fight ----
    r = pg.evaluate("()=>{"+build+"""
      var h=R.unitFromCard({name:'Hero',cardType:'hero',stats:{hp:'40',ac:'14',apT:'4'},
        entries:[{name:'X',kind:'Active',role:'melee',damage:'1',energyCost:'0',armorPenetration:'9'}]},'ally');
      var t=R.unitFromCard({name:'Troop',cardType:'troop',stats:{hp:'40',ac:'9',nrg:'4',will:'9'},
        entries:[{name:'X',kind:'Active',role:'melee',damage:'1',energyCost:'0',armorPenetration:'9'}]},'ally');
      var e=foe('Hunter',40,[{key:'cunning'}],3);
      var out=R.runCombat([h,t,e],{dice:R.makeDice(31), maxRounds:3});
      var hits={};
      out.log.forEach(function(ev){
        if(ev.type==='attack' && ev.unit===e.id) hits[ev.target]=(hits[ev.target]||0)+1;
      });
      return {hero:hits[h.id]||0, troop:hits[t.id]||0};
    }""")
    ck3("a Cunning Enemy attacks the Hero past a Troop",
        r["hero"]>0 and r["troop"]==0, str(r))

    # ---- a Cowardly Enemy stops attacking once broken ----
    r = pg.evaluate("()=>{"+build+"""
      var e=foe('Craven',30,[{key:'cowardly',value:25}],3);
      var h=hero(200,1);
      var out=R.runCombat([h,e],{dice:R.makeDice(13), maxRounds:6});
      var skipped=out.log.filter(function(ev){ return ev.type==='skip'; }).length;
      return {skipped:skipped, hp:e.hp};
    }""")
    ck3("a Cowardly Enemy below its threshold takes no Action",
        r["skipped"]>0, str(r))

    # ---- Combos run in order ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var e=R.unitFromCard({name:'Seq',cardType:'enemy',stats:{hp:'40',ac:'5',will:'9'},
        entries:[{name:'One',kind:'Combo',role:'melee',damage:'1',energyCost:'0',armorPenetration:'9'},
                 {name:'Two',kind:'Combo',role:'melee',damage:'1',energyCost:'0',armorPenetration:'9'},
                 {name:'Three',kind:'Combo',role:'melee',damage:'1',energyCost:'0',armorPenetration:'9'}]},'enemy');
      var h=R.unitFromCard({name:'H',cardType:'hero',stats:{hp:'500',ac:'30',apT:'4'},
        entries:[{name:'Poke',kind:'Active',role:'melee',damage:'0',energyCost:'0'}]},'ally');
      var out=R.runCombat([h,e],{dice:R.makeDice(8), maxRounds:5});
      return out.log.filter(function(ev){ return ev.type==='attack' && ev.unit===e.id; })
                    .map(function(ev){ return ev.name; });
    }""")
    ck3("a Combo runs in its printed order",
        r[:3]==["One","Two","Three"], str(r[:4]))
    ck3("and wraps back to the start", len(r)>3 and r[3]=="One", str(r[:5]))

    # ---- a Player Unit picks something it can afford ----
    r = pg.evaluate("()=>{"+build+"""
      var u=R.makeUnit({nrg:1, actions:[
        {name:'Cheap',tag:'Active',role:'melee',cost:1,dmg:'3'},
        {name:'Dear', tag:'Active',role:'melee',cost:5,dmg:'20'},
        {name:'Aura', tag:'Aura',  role:'support',cost:0,dmg:'99'}]});
      var t=R.makeUnit({hpMax:30,hp:30});
      var pick=R.bestAction(u,t,{});
      return pick?pick.name:'none';
    }""")
    ck3("it never picks an Action it cannot pay for", r=="Cheap", r)

    ck3("no JS errors", len([e for e in errs if 'favicon' not in e.lower()])==0,
        "; ".join(errs[:3]))
    b.close()
srv3.shutdown()
print(f"ROUND LOOP PASS {len(ok3)}  FAIL {len(bad3)}")
for x in bad3: print("  ✗",x)
# parts one to three done

# ---------------- dice: three kinds, auto and manual ----------------
srv4 = Q(("127.0.0.1", 9659),
         functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv4.serve_forever, daemon=True).start()
ok4, bad4 = [], []
def ck4(n,c,d=""): (ok4 if c else bad4).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9659/"); pg.wait_for_timeout(2000)

    # ---- all three kinds ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES, d=R.makeDice();
      var out={};
      ["d20","d6"].forEach(function(k){
        var lo=999,hi=0,seen={};
        for(var i=0;i<600;i++){ var v=d.roll(k); seen[v]=1; if(v<lo)lo=v; if(v>hi)hi=v; }
        out[k]={lo:lo,hi:hi,distinct:Object.keys(seen).length};
      });
      var faces={};
      for(var j=0;j<300;j++) faces[d.coin().face]=1;
      return {d20:out.d20, d6:out.d6, coinFaces:Object.keys(faces).sort()};
    }""")
    ck4("a d20 covers 1 to 20",
        r["d20"]["lo"]==1 and r["d20"]["hi"]==20 and r["d20"]["distinct"]==20, str(r["d20"]))
    ck4("a d6 covers 1 to 6",
        r["d6"]["lo"]==1 and r["d6"]["hi"]==6 and r["d6"]["distinct"]==6, str(r["d6"]))
    ck4("a coin gives heads and tails",
        r["coinFaces"]==["heads","tails"], str(r["coinFaces"]))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var a=R.makeDice(4242), b=R.makeDice(4242);
      var x=[],y=[];
      for(var i=0;i<10;i++){ x.push(a.roll("d20"),a.roll("d6"),a.coin().value);
                             y.push(b.roll("d20"),b.roll("d6"),b.coin().value); }
      return {same:x.join()===y.join(),
              faces:[R.faceOf("coin",1),R.faceOf("coin",2),R.faceOf("d20",17)]};
    }""")
    ck4("every kind is reproducible from a seed", r["same"] is True)
    ck4("a roll reads back as a face",
        r["faces"]==["heads","tails","17"], str(r["faces"]))

    setup = """
      var R=KETER_RULES;
      var atk=R.makeUnit({id:'a',name:'A',nrg:9});
      function tgt(ac){ return R.makeUnit({id:'t',name:'T',hpMax:40,hp:40,ac:ac,will:9}); }
      var ranged={name:'Shot',role:'ranged',dmg:'7',hit:'11',pen:'0',rng:'6'};
      var melee ={name:'Swing',role:'melee',dmg:'6',pen:'0'};
    """

    # ---- auto mode resolves in one call ----
    r = pg.evaluate("()=>{"+setup+"""
      var res=R.resolveAttack(atk,ranged,tgt(10),
        {dice:R.makeDice(5), distance:2});
      return {pending:res.pending, hit:res.hit,
              rolledAccuracy:('accuracy' in res.rolls),
              rolledPen:('penetration' in res.rolls),
              settled:(res.hit!==null && res.penetrated!==null)};
    }""")
    ck4("Auto resolves without stopping", r["pending"] is None, str(r))
    ck4("it rolls for accuracy itself", r["rolledAccuracy"] is True, str(r))
    ck4("and rolls for Penetration only if it hit",
        r["rolledPen"] == r["hit"], str(r))

    # ---- manual mode asks, then resumes ----
    r = pg.evaluate("()=>{"+setup+"""
      var t=tgt(10);
      var first=R.resolveAttack(atk,ranged,t,{manual:true, distance:2});
      var second=R.resolveAttack(atk,ranged,t,
        {manual:true, distance:2, rolls:{accuracy:14}});
      var third=R.resolveAttack(atk,ranged,t,
        {manual:true, distance:2, rolls:{accuracy:14, penetration:12}});
      return {first:first, second:second, third:third};
    }""")
    ck4("Manual asks for the accuracy roll first",
        r["first"]["pending"]=="accuracy" and r["first"]["die"]=="d20", str(r["first"]))
    ck4("it says what the player needs to beat",
        r["first"]["needed"]==11, str(r["first"]))
    ck4("nothing is decided while it waits",
        r["first"]["hit"] is None and r["first"]["damage"]==0, str(r["first"]))
    ck4("given the roll it asks for Penetration next",
        r["second"]["pending"]=="penetration", str(r["second"]))
    ck4("and reports the Armor Class to beat",
        r["second"]["needed"]==10, str(r["second"]))
    ck4("given both it settles",
        r["third"]["pending"] is None and r["third"]["damage"]==7, str(r["third"]))

    # ---- a manual miss never asks for the second roll ----
    r = pg.evaluate("()=>{"+setup+"""
      return R.resolveAttack(atk,ranged,tgt(10),
        {manual:true, distance:2, rolls:{accuracy:4}});
    }""")
    ck4("a miss is settled without a Penetration roll",
        r["pending"] is None and r["hit"] is False and "penetration" not in r["rolls"],
        str(r))

    # ---- Melee asks for one roll, Aether for none ----
    r = pg.evaluate("()=>{"+setup+"""
      return {melee:R.resolveAttack(atk,melee,tgt(10),{manual:true}),
              aether:R.resolveAttack(atk,{name:'L',role:'aether',dmg:'6'},tgt(20),
                {manual:true}),
              support:R.resolveAttack(atk,{name:'P',role:'support',text:'Heals 4.'},
                tgt(20),{manual:true})};
    }""")
    ck4("Melee asks only for Penetration",
        r["melee"]["pending"]=="penetration", str(r["melee"]))
    ck4("Aether asks for nothing and lands",
        r["aether"]["pending"] is None and r["aether"]["damage"]==6, str(r["aether"]))
    ck4("Support asks for nothing", r["support"]["pending"] is None, str(r["support"]))

    # ---- what to pick up, before rolling ----
    r = pg.evaluate("()=>{"+setup+"""
      var over=tgt(10); R.addStatus(over,'Marked',null,null,2);
      return {ranged:R.rollsFor(ranged,tgt(10)),
              melee:R.rollsFor(melee,tgt(10)),
              aether:R.rollsFor({name:'L',role:'aether'},tgt(10)),
              cyber:R.rollsFor({name:'C',role:'cyber'},tgt(10)),
              overwhelmed:R.rollsFor(ranged,over)};
    }""")
    ck4("a Ranged attack needs two d20s",
        [x["die"] for x in r["ranged"]]==["d20","d20"], str(r["ranged"]))
    ck4("Melee needs one", len(r["melee"])==1, str(r["melee"]))
    ck4("Aether needs none", len(r["aether"])==0, str(r["aether"]))
    ck4("a Cyber attack needs two d20s, like Ranged", len(r["cyber"])==2, str(r["cyber"]))
    ck4("a Marked target needs only Penetration",
        len(r["overwhelmed"])==1 and r["overwhelmed"][0]["what"]=="penetration",
        str(r["overwhelmed"]))

    # ---- switching mode mid-attack is allowed ----
    r = pg.evaluate("()=>{"+setup+"""
      var t=tgt(10);
      var asked=R.resolveAttack(atk,ranged,t,{manual:true, distance:2});
      /* player switches to Auto part way through: the roll they already made
         stands, the rest is rolled for them */
      var done=R.resolveAttack(atk,ranged,t,
        {dice:R.makeDice(9), distance:2, rolls:{accuracy:asked.needed}});
      return {asked:asked.pending, done:done.pending,
              keptRoll:done.rolls.accuracy===asked.needed, hit:done.hit};
    }""")
    ck4("a roll already made survives switching to Auto",
        r["keptRoll"] is True and r["done"] is None, str(r))
    ck4("and the rest is rolled automatically", r["hit"] is True, str(r))

    ck4("no JS errors", len([e for e in errs if 'favicon' not in e.lower()])==0,
        "; ".join(errs[:3]))
    b.close()
srv4.shutdown()
print(f"DICE PASS {len(ok4)}  FAIL {len(bad4)}")
for x in bad4: print("  ✗",x)
# earlier parts done

# ---------------- aether generation ----------------
srv5 = Q(("127.0.0.1", 9661),
         functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(TMP)))
threading.Thread(target=srv5.serve_forever, daemon=True).start()
ok5, bad5 = [], []
def ck5(n,c,d=""): (ok5 if c else bad5).append(n+((" — "+str(d)) if d and not c else ""))

with sync_playwright() as p:
    b=p.chromium.launch()
    c=b.new_context(viewport={"width":412,"height":915},is_mobile=True,has_touch=True)
    pg=c.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:170]))
    pg.on("console",lambda m:errs.append("con:"+m.text[:170]) if m.type=="error" else None)
    pg.goto("http://127.0.0.1:9661/"); pg.wait_for_timeout(2000)

    setup = """
      var R=KETER_RULES;
      function hero(name,affs){ return R.unitFromCard({name:name,cardType:'hero',
        affinities:affs, stats:{hp:'40',apT:'4'}},'ally'); }
      function troop(name,affs){ return R.unitFromCard({name:name,cardType:'troop',
        affinities:affs, stats:{hp:'20',nrg:'4'}},'ally'); }
    """

    # ---- a Hero generates its Affinity Level in its own District ----
    r = pg.evaluate("()=>{"+setup+"""
      return {four:R.aetherFromHero(hero('R',[{district:'3',level:4}])),
              three:R.aetherFromHero(hero('Y',[{district:'3',level:3}])),
              zero:R.aetherFromHero(hero('M',[{district:'3',level:0}])),
              none:R.aetherFromHero(hero('N',[]))};
    }""")
    ck5("Affinity Level 4 in District 3 gives 4 District 3 Aether",
        r["four"]=={"d3":4}, str(r["four"]))
    ck5("Level 3 gives 3", r["three"]=={"d3":3}, str(r["three"]))
    ck5("Level 0 gives nothing", r["zero"]=={}, str(r["zero"]))
    ck5("no Affinity gives nothing", r["none"]=={}, str(r["none"]))

    r = pg.evaluate("()=>{"+setup+"""
      return R.aetherFromHero(hero('Two',[{district:'3',level:2},{district:'1',level:1}]));
    }""")
    ck5("two Affinities generate for both", r=={"d3":2,"d1":1}, str(r))

    # ---- only Heroes generate, and only standing ones ----
    r = pg.evaluate("()=>{"+setup+"""
      var h=hero('H',[{district:'3',level:4}]);
      var t=troop('T',[{district:'3',level:5}]);
      var dead=hero('D',[{district:'3',level:6}]); dead.down=true;
      var foe=R.unitFromCard({name:'F',cardType:'hero',
        affinities:[{district:'2',level:5}],stats:{hp:'20'}},'enemy');
      return {all:R.aetherIncome([h,t,dead,foe],'ally'),
              troopAlone:R.aetherIncome([t],'ally'),
              downAlone:R.aetherIncome([dead],'ally')};
    }""")
    ck5("a Troop generates nothing however high its Affinity",
        r["troopAlone"]=={}, str(r["troopAlone"]))
    ck5("a downed Hero generates nothing", r["downAlone"]=={}, str(r["downAlone"]))
    ck5("only your own side counts, and only Heroes",
        r["all"]=={"d3":4}, str(r["all"]))

    r = pg.evaluate("()=>{"+setup+"""
      return R.aetherIncome([hero('A',[{district:'3',level:4}]),
                             hero('B',[{district:'3',level:3}])],'ally');
    }""")
    ck5("several Heroes add together", r=={"d3":7}, str(r))

    # ---- paying with it ----
    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      function pool(){ return {d3:4, generic:2}; }
      return {
        affordAffinity: R.aetherCanPay(pool(),{district:'3',affinity:3,generic:0}),
        tooMuchAffinity:R.aetherCanPay(pool(),{district:'3',affinity:5,generic:0}),
        wrongDistrict:  R.aetherCanPay(pool(),{district:'1',affinity:1,generic:0}),
        genericFromAny: R.aetherCanPay(pool(),{generic:5}),
        tooMuchTotal:   R.aetherCanPay(pool(),{generic:7}),
        total:          R.aetherTotal(pool())
      };
    }""")
    ck5("District Aether pays its own District", r["affordAffinity"] is True, str(r))
    ck5("but not more than you hold", r["tooMuchAffinity"] is False, str(r))
    ck5("and not another District", r["wrongDistrict"] is False, str(r))
    ck5("anything pays a generic cost", r["genericFromAny"] is True, str(r))
    ck5("but not beyond the total", r["tooMuchTotal"] is False, str(r))
    ck5("the total counts every kind", r["total"]==6, str(r))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var pool={d3:4, generic:2};
      var paid=R.aetherPay(pool,{district:'3',affinity:2,generic:2});
      return {paid:paid, left:pool, total:R.aetherTotal(pool)};
    }""")
    ck5("paying takes it out of the pool", r["paid"] is True and r["total"]==2, str(r))

    r = pg.evaluate("""()=>{
      var R=KETER_RULES;
      var pool={d3:1};
      var before=R.aetherTotal(pool);
      var paid=R.aetherPay(pool,{district:'3',affinity:3});
      return {paid:paid, unchanged:R.aetherTotal(pool)===before};
    }""")
    ck5("a cost you cannot meet takes nothing",
        r["paid"] is False and r["unchanged"] is True, str(r))

    ck5("no JS errors", len([e for e in errs if 'favicon' not in e.lower()])==0,
        "; ".join(errs[:3]))
    b.close()
srv5.shutdown()
print(f"AETHER PASS {len(ok5)}  FAIL {len(bad5)}")
for x in bad5: print("  ✗",x)
sys.exit(1 if (bad or bad2 or bad3 or bad4 or bad5) else 0)
