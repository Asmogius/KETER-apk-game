"""v13.3 (Handbook 15.7): the Recover keyword; when a card reaches the Discard
Pile (a Troop's with its Troop, Equipment with its Unit); Consumables doing
what they say; a carried Action card's Aether cost; Chips and Consumables on
your turn only; and the Bank left sound after a District card is paid for with
Generic Aether."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_recover")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9979),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""): (ok if c else bad).append(n+((" — "+str(d)[:300]) if d not in ("",None) and not c else ""))
LIB=r"""()=>{ window.T={ R:window.KETER_RULES,
  unit:function(n){ return SIM.units.filter(function(u){ return u.name===n; })[0]; },
  card:function(n){ return simHandCardOf(simAllCards().filter(function(c){ return c.name===n; })[0]); },
  act:function(u,name){ return (u.actions||[]).filter(function(a){return a.name===name;})[0]; },
  names:function(list){ return (list||[]).map(function(c){ return (c&&c.name)||String(c); }); },
  texts:function(from){ return SIM.log.slice(from||0).map(function(l){ return l.text; }); },
  pick:function(u){ var pk=SIM.pick; SIM.pick=null; if(pk) pk.done(u); },
  shut:function(){ var m=document.getElementById('modal'); if(m) m.classList.remove('on'); window._simRecover=null; window._simCons=null; },
  cons:function(n){ for(var i=0;i<SIM.cons.length;i++) if(SIM.cons[i].name===n && !SIM.cons[i].used) return i; return -1; }
}; return true; }"""
with sync_playwright() as p:
    b=p.chromium.launch()
    pg=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2).new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.goto("http://127.0.0.1:9979/"); pg.wait_for_timeout(2000)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-simdebug','1'); localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-sim'); }")
    pg.reload(); pg.wait_for_timeout(2200)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(500)
    E=pg.evaluate

    # ---- the keyword ----
    r=E("""()=>{ var K=window.KETER_KW, k=K.byName('Recover'), p=K.parse("[[Recover]] a Troop's card from the Discard Pile.");
      var an=K.analyse("[[Recover]] a Troop's card from the Discard Pile.");
      return {cat:k&&k.cat, num:k&&k.num, desc:k&&k.desc, kw:p.filter(function(x){return x.type==='kw';}).map(function(x){return x.kw&&x.kw.name;}),
        effects:an.effects.length, problems:K.problems(an,{kind:'action'}), shown:K.render("[[Recover]] a Troop's card from the Discard Pile.")}; }""")
    ck("Recover is an Effect in the keyword library, with no number", r["cat"]=="effect" and r["num"] is None, r)
    ck("it says what it does", "Discard Pile" in (r["desc"] or "") and "hand" in (r["desc"] or ""), r["desc"])
    ck("a card's text is read with it, and nothing is wrong with the sentence", r["kw"]==["Recover"] and r["effects"]==1 and r["problems"]==[], r)
    hb=(pathlib.Path("handbook.html").read_text(encoding="utf-8"))
    ck("the Handbook lists it among the Effects and in the glossary, as Revision 15.7", hb.count("<strong>Recover</strong>")>=3 and "Revision 15.7" in hb, hb.count("<strong>Recover</strong>"))

    # ---- a Strike Team's fight, with Starting Troops ----
    E("()=>simDebugStart('TEST \\u00b7 Corridor')"); pg.wait_for_timeout(1200)
    E("""()=>{ var w=simWiz(); w.startTroops=['Test Drone','Test Sapper']; w.protos=[]; w.cons={'Test Stim':1,'Test Repair Kit':3,'Signal Flare':1};
      w.instability=0; simWizFinish(); }"""); pg.wait_for_timeout(1200)
    E(LIB)
    r=E("""()=>{ var d=T.unit('Test Drone'), s=T.unit('Test Sapper'), w=T.unit('Test Warden');
      return {drone:d&&d.card&&d.card.name, sapper:s&&s.card&&s.card.type, hero:!!(w&&w.card), discard:SIM.discard.length,
        inDeck:SIM.deck.concat(SIM.hand).filter(function(c){ return c.name==='Test Drone'; }).length, phase:SIM.phase}; }""")
    ck("a Starting Troop goes in with its card, out of the Deck", r["drone"]=="Test Drone" and r["sapper"]=="troop" and r["discard"]==0, r)
    ck("a Hero has no card to discard", r["hero"] is False, r)

    # ---- a carried Action card's Aether ----
    r=E("""()=>{ var w=T.unit('Test Warden'), pr=T.act(w,'Piercing Rounds'), pv=T.act(w,'Pinning Volley');
      var g=SIM.units.filter(function(u){ return u.side==='enemy'; })[0]; g.pos={q:w.pos.q+2, r:w.pos.r}; g.hp=g.hpMax=60;
      w.nrg=6; SIM.aether={}; var none=simActionState(w,pr), printed=simActionState(w,pv);
      SIM.aether={d1:5}; var wrong=simActionState(w,pr);
      SIM.aether={d3:3}; var can=simActionState(w,pr);
      SIM.selected=w.id; var bar=simActionBarHTML(w);
      SIM_FORCE.push(20); SIM_FORCE.push(20); simConfirmAttack(w,g,pr);
      return {aether:pr.aether, printed:pv.aether||null, none:none, okPrinted:printed.ok, wrong:wrong, can:can.ok, bar:bar.replace(/<[^>]+>/g,' '),
        after:SIM.aether.d3, nrg:w.nrg, gid:g.id}; }""")
    ck("a carried Action card carries its Aether cost; a printed Action has none", r["aether"]=={"generic":0,"affinity":1,"district":"3"} and r["printed"] is None, r)
    ck("with no Aether in the Bank it can't be used, and says what it needs", r["none"]=={"ok":False,"why":"Needs 1 D3 Aether"}, r["none"])
    ck("another District's Aether won't pay for it", r["wrong"].get("ok") is False, r["wrong"])
    ck("a printed Action is untouched by the Bank", r["okPrinted"] is True, r)
    ck("its button shows Energy and Aether", "2 NRG + 1 D3" in r["bar"], r["bar"][:400])
    ck("using it pays the Aether as well as the Energy", r["can"] is True and r["after"]==2 and r["nrg"]==4, r)
    pg.wait_for_timeout(900)
    r2=E("()=>{ simUndo(); var w=T.unit('Test Warden'); return {aether:SIM.aether.d3, nrg:w.nrg}; }")
    ck("Undo gives both back", r2=={"aether":3,"nrg":6}, r2)
    r=E("""()=>{ var w=T.unit('Test Warden'), ow=T.act(w,'Overwatch'); w.moved=0; w.nrg=6;
      ow.aether={generic:0,affinity:2,district:'3'}; SIM.aether={d3:1}; var cant=simHoldable(w).length;
      SIM.aether={d3:5}; var can=simHoldable(w).length; simHoldFire(w,'Overwatch');
      var out={cant:cant, can:can, after:SIM.aether.d3, holding:!!w.holding}; w.holding=null; delete ow.aether; return out; }""")
    ck("holding fire with one pays its Aether too, and needs it", r=={"cant":0,"can":1,"after":3,"holding":True}, r)

    # ---- a Troop played from the hand ----
    r=E("""()=>{ SIM.phase='turn'; SIM.aether={generic:20,d3:20}; SIM.discard=[]; SIM.hand=[T.card('Test Scout'), T.card('Test Plating'), T.card('Test Plating'), T.card('Test Rally')];
      T.unit('Test Sapper').pos={q:-2,r:0}; T.unit('Test Drone').pos={q:-1,r:0};      // off their spawn tiles, so there is room
      var n=SIM.units.length; simPlayCard(0); var u=SIM.units[SIM.units.length-1];
      window._scout=u.id;
      return {added:SIM.units.length===n+1, name:u.name, card:u.card&&u.card.name, discard:SIM.discard.length, hand:T.names(SIM.hand)}; }""")
    ck("a Troop played from the hand keeps its card with it: nothing is discarded yet", r["added"] and r["card"]=="Test Scout" and r["discard"]==0 and len(r["hand"])==3, r)
    # ---- Equipment ----
    E("()=>{ simPlayCard(0); T.pick(T.unit('Test Scout')); }"); pg.wait_for_timeout(200)
    r=E("""()=>{ var u=T.unit('Test Scout'); return {eq:u.equipment, cards:T.names(u.equipCards), discard:SIM.discard.length, ac:T.R.effective(u).ac}; }""")
    ck("Equipment stays with the Unit wearing it, undiscarded", r["eq"]==["Test Plating"] and r["cards"]==["Test Plating"] and r["discard"]==0, r)
    r=E("""()=>{ var u=T.unit('Test Scout'), w=T.unit('Test Warden');
      simRunText('[[target ally]] gains [[remove Equipment]].',{actor:w,target:u,sourceCard:'T'});
      return {eq:u.equipment, cards:(u.equipCards||[]).length, discard:SIM.discard.map(function(c){ return typeof c==='string' ? 'STRING '+c : c.name+':'+c.type; })}; }""")
    ck("taken off, the Equipment card itself goes to the Discard Pile", r["eq"]==[] and r["cards"]==0 and r["discard"]==["Test Plating:equipment"], r)
    E("()=>{ simPlayCard(0); T.pick(T.unit('Test Scout')); }"); pg.wait_for_timeout(200)
    r=E("""()=>{ var u=T.unit('Test Scout'); var before=SIM.discard.length; u.hp=0; simCheckDowns();
      return {before:before, discard:T.names(SIM.discard), card:u.card, down:u.down}; }""")
    ck("when the Troop goes down, its card and what it wore go to the Discard Pile", r["before"]==1 and sorted(r["discard"])==["Test Plating","Test Plating","Test Scout"] and r["card"] is None and r["down"], r)
    r=E("()=>{ simCheckDowns(); simCheckDowns(); return SIM.discard.length; }")
    ck("once, however often it is looked at", r==3, r)
    r=E("""()=>{ var d=T.unit('Test Drone'); d.hp=0; simCheckDowns(); var g=SIM.units.filter(function(u){ return u.side==='enemy' && !u.down; })[0]; var n=SIM.discard.length; g.hp=0; simCheckDowns();
      return {discard:T.names(SIM.discard), same:SIM.discard.length===n}; }""")
    ck("a Starting Troop's card goes there too; an Enemy's never does", r["discard"].count("Test Drone")==1 and r["same"], r)
    # a Command is discarded as it's played
    r=E("""()=>{ var n=SIM.discard.length; var i=SIM.hand.findIndex(function(c){ return c.name==='Test Rally'; }); simPlayCard(i);
      if(SIM.pick) T.pick(T.unit('Test Warden'));
      return {more:SIM.discard.length-n, last:SIM.discard[SIM.discard.length-1].name}; }""")
    ck("a Command is discarded as it is played, as before", r=={"more":1,"last":"Test Rally"}, r)

    # ---- Recover ----
    r=E("""()=>{ SIM.discard=SIM.discard.filter(function(c){ return c.type!=='troop'; }); SIM.hand=[]; var i=T.cons('Test Repair Kit'), from=SIM.log.length;
      simUseConsumable(i); return {used:SIM.cons[i].used, hand:SIM.hand.length, log:T.texts(from), said:(document.getElementById('simticker')||{}).textContent||''}; }""")
    ck("with no Troop's card in the Discard Pile, a card that Recovers can't be used", r["used"] is False and r["hand"]==0 and "there is none there" in r["said"] and not any(l.startswith("Used") for l in r["log"]), r)
    r=E("""()=>{ SIM.discard.push(T.card('Test Sapper')); var i=T.cons('Test Repair Kit'), from=SIM.log.length; simUseConsumable(i);
      return {used:SIM.cons[i].used, hand:T.names(SIM.hand), left:SIM.discard.filter(function(c){ return c.type==='troop'; }).length, log:T.texts(from), modal:document.getElementById('modal').classList.contains('on')}; }""")
    ck("with one there, it comes back to the hand without asking", r["used"] is True and r["hand"]==["Test Sapper"] and r["left"]==0 and not r["modal"], r)
    ck("and the log says so", "Used Test Repair Kit" in r["log"] and "Test Sapper returns to your hand from the Discard Pile" in r["log"], r["log"])
    r=E("""()=>{ SIM.hand=[]; SIM.discard.push(T.card('Test Drone')); SIM.discard.push(T.card('Test Battery')); var i=T.cons('Test Repair Kit'); window._rk=i; simUseConsumable(i);
      var rows=[].map.call(document.querySelectorAll('[data-simrecover]'), function(e){ return e.querySelector('b').textContent; });
      return {used:SIM.cons[i].used, rows:rows, title:document.getElementById('modalBox').textContent.slice(0,40)}; }""")
    ck("with several, it asks which, and nothing is used until one is chosen", r["used"] is False and r["rows"]==["Test Drone","Test Battery"], r)
    pg.locator("[data-simrecover]").nth(1).click(); pg.wait_for_timeout(250)
    r=E("()=>({used:SIM.cons[window._rk].used, hand:T.names(SIM.hand), left:T.names(SIM.discard.filter(function(c){ return c.type==='troop'; }))})")
    ck("the one chosen returns; the other stays", r=={"used":True,"hand":["Test Battery"],"left":["Test Drone"]}, r)
    r=E("""()=>{ simUndo(); var i=window._rk; return {used:SIM.cons[i].used, hand:SIM.hand.length, left:SIM.discard.filter(function(c){ return c.type==='troop'; }).length}; }""")
    ck("Undo puts it back in the Discard Pile, the Repair Kit unused", r=={"used":False,"hand":0,"left":2}, r)
    # the recovered Troop is played again at its cost, and its card goes with it
    r=E("""()=>{ var i=window._rk; simUseConsumable(i); return true; }"""); pg.locator("[data-simrecover]").nth(0).click(); pg.wait_for_timeout(250)
    r=E("""()=>{ SIM.aether={generic:0,d3:0}; var cant=simCanPlay(SIM.hand[0]); SIM.aether={generic:9,d3:9}; var before=T.R.aetherTotal(SIM.aether), n=SIM.units.length;
      var name=SIM.hand[0].name; simPlayCard(0); var u=SIM.units[SIM.units.length-1];
      return {name:name, cant:cant, paid:before-T.R.aetherTotal(SIM.aether), back:SIM.units.length===n+1, unit:u.name.replace(/ \\d+$/,''), card:u.card&&u.card.name, hpFull:u.hp===u.hpMax}; }""")
    ck("a Recovered Troop is played again at its normal cost, at full Health", r["name"]=="Test Drone" and r["cant"] is False and r["paid"]==1 and r["back"] and r["unit"]=="Test Drone" and r["card"]=="Test Drone" and r["hpFull"], r)
    # a card in the hand that Recovers
    r=E("""()=>{ SIM.discard=SIM.discard.filter(function(c){ return c.type!=='troop'; });
      var card={name:'Field Recall', type:'command', cost:{generic:1,affinity:0}, district:null, effects:[{name:'',kind:'Active',text:'[[Recover]] a Troop.'}]};
      SIM.hand=[card]; SIM.aether={generic:3}; simPlayCard(0); var kept=SIM.hand.length===1 && SIM.aether.generic===3;
      SIM.discard.push(T.card('Test Scout')); simPlayCard(0);
      return {kept:kept, hand:T.names(SIM.hand), aether:SIM.aether.generic, discarded:SIM.discard[SIM.discard.length-1].name}; }""")
    ck("a card that Recovers isn't paid for while there is nothing to Recover", r["kept"] is True, r)
    ck("with a Troop's card there it is paid, discarded, and the Troop's card is in the hand", r["hand"]==["Test Scout"] and r["aether"]==2 and r["discarded"]=="Field Recall", r)
    r=E("""()=>{ var w=T.unit('Test Warden'), from=SIM.log.length; SIM.discard=SIM.discard.filter(function(c){ return c.type!=='troop'; });
      simRunText('[[Recover]] a Troop.',{actor:w,sourceCard:'T'}); var none=T.texts(from);
      SIM.discard.push(T.card('Test Drone')); SIM.discard.push(T.card('Test Sapper')); SIM.hand=[];
      simRunText('[[Recover]] a Troop.',{actor:w,sourceCard:'T'});
      return {none:none, hand:T.names(SIM.hand)}; }""")
    r2=E("""()=>{ var w=T.unit('Test Warden'); SIM.halted=null;
      var card={name:'Nameless Drop', type:'command', cost:{generic:1,affinity:0}, district:null, effects:[{name:'',kind:'Active',text:'[[Deploy 1]] Sentry Token.'}]};
      SIM.hand=[card]; SIM.aether={generic:3}; simPlayCard(0); var hand=SIM.halted; SIM.halted=null;
      simRunText('[[Deploy 1]] Sentry Token.',{actor:w,sourceCard:'Call Sentry'}); var own=SIM.halted; SIM.halted=null;
      var m=document.getElementById('modalRoot'); if(m) m.innerHTML='';
      return {hand:hand, own:own}; }""")
    ck("a card from the hand whose Deploy names nothing is named in the problem, not the leader who played it",
       r2["hand"]=="Deploy on Nameless Drop does not name what to deploy." and r2["own"]=="Deploy on Test Warden does not name what to deploy.", r2)
    ck("carried out with nothing chosen, it says there is none, or takes the one discarded last", r["none"]==["There is no Troop card in the Discard Pile to Recover"] and r["hand"]==["Test Sapper"], r)

    # ---- Consumables do what they say ----
    r=E("""()=>{ T.shut(); var s=T.unit('Test Striker'); s.hp=s.hpMax-10; var i=T.cons('Test Stim'); window._stim=i; window._hp=s.hp; window._nrg=s.nrg;
      document.querySelector('[data-simcons="'+i+'"]').click();
      return {used:SIM.cons[i].used, box:document.getElementById('modalBox').textContent, on:document.getElementById('modal').classList.contains('on')}; }""")
    ck("tapping a Consumable shows it first: its text, and Use it", r["on"] and r["used"] is False and "Use it" in r["box"] and "Not yet" in r["box"] and "6" in r["box"], r)
    pg.locator("#simConsGo").click(); pg.wait_for_timeout(250)
    r=E("()=>({used:SIM.cons[window._stim].used, picking:!!SIM.pick, lit:SIM.pick?Object.keys(SIM.pick.valid).length:0, allies:SIM.units.filter(function(u){ return u.side==='ally' && !u.down && u.pos; }).length})")
    ck("Use it lights the Units it can go to; it isn't used until one is tapped", r["used"] is False and r["picking"] and r["lit"]==r["allies"], r)
    r=E("""()=>{ var s=T.unit('Test Striker'), from=SIM.log.length; T.pick(s);
      return {used:SIM.cons[window._stim].used, healed:s.hp-window._hp, nrg:s.nrg-window._nrg, log:T.texts(from)}; }""")
    ck("its keywords are carried out: 6 healed and +1 NRG", r["used"] is True and r["healed"]==6 and r["nrg"]==1 and "Used Test Stim on Test Striker" in r["log"], r)
    r=E("()=>{ simUndo(); var s=T.unit('Test Striker'); return {used:SIM.cons[window._stim].used, hp:s.hp===window._hp}; }")
    ck("Undo takes it back, unused", r=={"used":False,"hp":True}, r)
    r=E("""()=>{ var i=T.cons('Signal Flare'), from=SIM.log.length; simUseConsumable(i); return {used:SIM.cons[i].used, log:T.texts(from)}; }""")
    ck("14.11: Signal Flare is in keywords now (all allies gain Aim +1), and is carried out", r["used"] is True and any("+1 Aim" in l for l in r["log"]) and not any(l.startswith("Not carried out") for l in r["log"]), r)
    r=E("""()=>{ simUndo(); var i=T.cons('Signal Flare'), from=SIM.log.length; SIM.cons[i].text='Every Unit you control gains +1 to hit until the end of the turn.';
      simUseConsumable(i); return {used:SIM.cons[i].used, log:T.texts(from)}; }""")
    ck("a Consumable in plain text (no card has one since 14.11, so the Flare's old wording stands in) is used, and logged as not carried out", r["used"] is True and any(l.startswith("Not carried out") and "Signal Flare" in l for l in r["log"]), r)
    r=E("""()=>{ var i=T.cons('Test Stim'); SIM.phase='draw'; simUseConsumable(i); var a=SIM.cons[i].used;
      SIM.bank=[{name:'Test Spark Chip', value:1, district:'3', text:'[[target enemy]] takes [[damage 3]].', spent:false}]; simSpendChip(0); var c=SIM.bank[0].spent, picking=!!SIM.pick;
      SIM.phase='turn'; return {cons:a, chip:c, picking:picking}; }""")
    ck("Consumables and Chips are used on your turn only", r=={"cons":False,"chip":False,"picking":False}, r)
    r=E("""()=>{ simSpendChip(0); var asked=!!SIM.pick, early=SIM.bank[0].spent; var g=SIM.units.filter(function(u){ return u.side==='enemy' && !u.down && u.pos; })[0];
      if(!g){ g=T.unit('Test Warden'); }
      var hp=g.hp, from=SIM.log.length; T.pick(g);
      return {asked:asked, early:early, spent:SIM.bank[0].spent, dealt:hp-g.hp, log:T.texts(from)}; }""")
    ck("a Chip is spent when its effect happens, not when it's tapped", r["asked"] is True and r["early"] is False and r["spent"] is True and r["dealt"]==3 and any(l.startswith("Spent Test Spark Chip on ") for l in r["log"]), r)
    r=E("()=>{ simSpendChip(0); return {again:!!SIM.pick}; }")
    ck("and not twice in a round", r["again"] is False, r)

    # ---- the Bank after a District card is paid for with Generic ----
    r=E("""()=>{ var R=T.R, pool={generic:5}; var paid=R.aetherPay(pool,{generic:2,affinity:0,district:'1'});
      return {paid:paid, pool:pool, free:R.aetherCanPay(pool,{generic:0,affinity:0}), three:R.aetherCanPay(pool,{generic:3,affinity:0}), four:R.aetherCanPay(pool,{generic:4,affinity:0}), total:R.aetherTotal(pool)}; }""")
    ck("a District card paid for with Generic leaves the Bank able to pay for more", r["paid"] is True and r["pool"]=={"generic":3,"d1":0} and r["free"] is True and r["three"] is True and r["four"] is False and r["total"]==3, r)

    real=[e for e in errs if 'favicon' not in e.lower()]
    ck("no JS errors", len(real)==0, "; ".join(real[:4]))
    b.close()
srv.shutdown()
print(f"RECOVER PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
sys.exit(1 if bad else 0)
