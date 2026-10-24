/* ===========================================================================
   KETER deployments (v12.8) — leaving the dock, and coming home or not.

   A deployment brings one Strike Team from the Deck Builder. Its Troops must
   be designs from the Workshop that fit their chassis; every copy in the Deck
   costs Troop parts, paid before leaving and spent whatever happens. The
   built-in starter design comes with a few free copies each time. Everything
   else in the Deck comes along free, for now.

   Out on the map the team walks tile by tile. Each step may spring an ambush,
   likelier the higher the tile's Skull Level. POIs are a run of floors fought
   in order, with a final reward; the only way out early is a Hero reaching an
   Emergency Exit. A Hero who goes down sits out the rest of the deployment;
   a Troop copy that goes down is gone for the rest of it. A lost fight can be
   retried with the Heroes still standing; with none left, it is a wipe.

   Loot rides in the haul. It reaches the stockpile and the Workshop only when
   the team walks back onto the dock. A wipe loses it.
   =========================================================================== */
(function(){
  "use strict";
  var KEY="keter-app-deploy", HIST_KEY="keter-app-deploy-log", LOAD_KEY="keter-app-loadouts";
  var W=function(){ return window.KETER_WORLD; }, L=function(){ return window.KETER_LOOT; };
  var P=function(){ return window.KETER_PROG; }, WS=function(){ return window.KETER_WORKSHOP; };
  function clone(o){ return JSON.parse(JSON.stringify(o)); }
  function read(k,d){ try{ var v=JSON.parse(localStorage.getItem(k)||"null"); return v==null?d:v; }catch(e){ return d; } }
  function write(k,v){ try{ localStorage.setItem(k,JSON.stringify(v)); return true; }catch(e){ return false; } }
  function rnd(){ var x=L(); return x&&x.rnd?x.rnd():Math.random(); }
  /* every card, and the dock's pre-built Troops (v12.9), which never reach the Deck Builder */
  function cards(){ var out=[]; try{ out=window.KETER_ALLCARDS ? window.KETER_ALLCARDS() : []; }catch(e){}
    try{ if(WS()&&WS().prebuiltCards) out=out.concat(WS().prebuiltCards()); }catch(e){} return out; }
  var K=function(){ return window.KETER_DOCK; };

  /* ---- Strike Teams, as the Deck Builder keeps them ---- */
  function loadouts(){
    var lo=read(LOAD_KEY,[])||[], out=[];
    lo.forEach(function(l,i){
      if(!l) return;
      if(Array.isArray(l.heroes)) out.push({index:i, name:l.name||"Untitled", level:l.level||1, created:l.created||null,
        heroes:(l.heroes||[]).slice(), deck:(l.deck||[]).slice(), actions:clone(l.actions||{}), pouch:clone(l.pouch||{})});
    });
    return out;
  }
  function resolve(ref, all){
    all=all||cards(); var s=String(ref||""), src=s.split("|")[0], name=s.split("|").slice(1).join("|")||s;
    return all.filter(function(c){ return c.name===name && (c._src||"master")===src; })[0] || all.filter(function(c){ return c.name===name; })[0] || null;
  }

  /* (v14.19) the cards a team takes that must be held or crafted: {name: copies} */
  function needOf(lo, all){
    /* (a test's switch: every card counts as held, as the game's tests have it) */
    try{ if(localStorage.getItem("keter-test-every-card")==="1") return {}; }catch(e){}
    var need={}, add=function(r, n){ var c=resolve(r,all); if(!c || !K() || !K().isLimited || !K().isLimited(c) || !(n>0)) return; need[c.name]=(need[c.name]||0)+n; };
    (lo.deck||[]).forEach(function(r){ add(r,1); });
    Object.keys(lo.actions||{}).forEach(function(h){ (lo.actions[h]||[]).forEach(function(r){ add(r,1); }); });
    Object.keys(lo.pouch||{}).forEach(function(k){ if(String(k).indexOf("basic|")===0) return; add(k, parseInt(lo.pouch[k],10)||0); });
    return need;
  }

  /* ---- what leaving costs ---- */
  function plan(index, pack){
    var lo=loadouts().filter(function(l){ return l.index===+index; })[0];
    if(!lo) return {ok:false, fits:false, afford:false, reasons:["That Strike Team is gone"], lines:[], parts:[0,0,0,0,0,0]};
    var all=cards(), T=W().tables(), reasons=[], heroes=[], per={}, forge={}, other=0;
    lo.heroes.forEach(function(r){ var c=resolve(r,all); if(c) heroes.push(c.name); else reasons.push("a Hero in it is missing ("+String(r).split("|").slice(1).join("|")+")"); });
    if(!lo.heroes.length) reasons.push("it has no Hero");
    /* (v14.14) only Heroes recruited at the dock, or the free ones, can leave with it */
    if(K() && K().unowned) K().unowned(heroes).forEach(function(n){ reasons.push(n+" isn't recruited: recruit them at the dock, or swap in a free Hero"); });
    lo.deck.forEach(function(r){
      var c=resolve(r,all);
      if(!c){ reasons.push("a card in its Deck is missing ("+String(r).split("|").slice(1).join("|")+")"); return; }
      if(c.cardType==="troop"){
        if(c._src!=="design"){ forge[c.name]=(forge[c.name]||0)+1; return; }
        per[c._design]=per[c._design]||{id:c._design, name:c.name, copies:0}; per[c._design].copies++;
      } else other++;
    });
    Object.keys(forge).forEach(function(n){ reasons.push(n+" is a Forge Troop"+(forge[n]>1?" (×"+forge[n]+")":"")+": Troops come only from the Workshop"); });
    var parts=[0,0,0,0,0,0], lines=[];
    Object.keys(per).forEach(function(id){
      var ln=per[id], d=WS().get(id);
      if(!d){ reasons.push(ln.name+" is no longer in the Workshop"); return; }
      var chk=WS().check(d); if(!chk.ok) reasons.push(ln.name+" does not fit its chassis ("+chk.reasons.join("; ")+")");
      var each=WS().cost(d).parts, free=d.starter?Math.min(ln.copies, K()?K().starterFree():T.starterFree):0, paid=ln.copies-free;
      var cost=each.map(function(n){ return n*paid; });
      cost.forEach(function(n,r){ parts[r]+=n; });
      lines.push({id:id, name:ln.name, copies:ln.copies, free:free, each:each, cost:cost, starter:!!d.starter});
    });
    var st=L().stock(), afford=parts.every(function(n,r){ return st.parts.troop[r]>=n; });
    /* (v14.19) the cards it takes must be held, or are crafted as it leaves */
    var need=needOf(lo,all), craft=[], craftShards=0, craftParts={equipment:[0,0,0,0,0,0], aether:[0,0,0,0,0,0]};
    Object.keys(need).sort().forEach(function(nm){
      var have=K()?K().owned(nm):0, short=Math.max(0,need[nm]-have); if(!short) return;
      var cc=K().craftCost(nm); if(!cc){ reasons.push(nm+" can't be crafted"); return; }
      craft.push({name:nm, n:short, have:have, shards:cc.shards*short, type:cc.type, rarity:cc.rarity, parts:cc.n*short});
      craftShards+=cc.shards*short; if(cc.type) craftParts[cc.type][cc.rarity]+=cc.n*short;
    });
    if(st.shards<craftShards) afford=false;
    ["equipment","aether"].forEach(function(ty){ craftParts[ty].forEach(function(n,r){ if(st.parts[ty][r]<n) afford=false; }); });
    /* v12.9: pre-built copies bought at the dock go too; packed Consumables and Prototypes must be owned */
    var pre=[], wait=K()?K().waiting():{};
    Object.keys(wait).forEach(function(id){ var d=WS().get(id); if(d && wait[id]>0) pre.push({id:id, name:d.name, copies:wait[id]}); });
    pack=pack||{}; var packed=[];
    Object.keys(pack).forEach(function(nm){ var n=parseInt(pack[nm],10)||0; if(!n) return;
      var have=K()?K().owned(nm):0; if(n>have) reasons.push("only "+have+" "+nm+" to pack"); else packed.push({name:nm, n:n, kind:K()?K().itemKind(nm):""}); });
    return {ok:!reasons.length && afford && !active(), fits:!reasons.length, afford:afford, reasons:reasons, heroes:heroes, lines:lines,
      parts:parts, other:other, loadout:lo, busy:active(), pre:pre, packed:packed, need:need, craft:craft, craftShards:craftShards, craftParts:craftParts};
  }

  /* ---- the deployment in progress ---- */
  function cur(){ var s=read(KEY,null); return s&&s.active?s:null; }
  function active(){ return !!cur(); }
  function save(s){ return write(KEY,s); }
  function note(s, text){ s.log=s.log||[]; s.log.unshift({t:new Date().toISOString(), text:text}); s.log=s.log.slice(0,60); }
  function history(){ return read(HIST_KEY,[])||[]; }
  function pushHistory(entry){ var h=history(); h.unshift(entry); write(HIST_KEY,h.slice(0,30)); }

  function start(index, pack){
    var p=plan(index, pack); if(!p.ok) return p;
    var st=L().stock(); p.parts.forEach(function(n,r){ st.parts.troop[r]-=n; });
    /* (v14.19) and what it lacks is crafted */
    st.shards-=p.craftShards; ["equipment","aether"].forEach(function(ty){ p.craftParts[ty].forEach(function(n,r){ st.parts[ty][r]-=n; }); });
    L().setStock(st);
    var n=W().state().completed+1, lo=p.loadout;
    if(p.parts.some(function(x){ return x; })){
      try{ var h=JSON.parse(localStorage.getItem("keter-app-stockpile-log")||"[]"); var b=L().bag(); p.parts.forEach(function(x,r){ b.parts.troop[r]=-x; });
        h.unshift({t:new Date().toISOString(), why:"Deployment "+n+" · copies paid", bag:b}); localStorage.setItem("keter-app-stockpile-log",JSON.stringify(h.slice(0,30))); }catch(e){}
    }
    var copies={}; p.lines.forEach(function(l){ copies[l.id]=l.copies; });
    /* pre-built copies leave the dock with the team; packed items ride with it */
    var pre={}; p.pre.forEach(function(x){ pre[x.id]=x.copies; });
    if(K()){ var v=K().inv(); v.pre={}; p.packed.forEach(function(x){ v.cards[x.name]=(v.cards[x.name]||0)-x.n; if(v.cards[x.name]<=0) delete v.cards[x.name]; });
      /* (v14.19) the cards it takes go with it: what was held, and what was crafted for it */
      Object.keys(p.need).forEach(function(nm){ v.cards[nm]=Math.max(0,(v.cards[nm]||0)-p.need[nm]); if(!v.cards[nm]) delete v.cards[nm]; });
      K()._saveInv(v); }
    var packC={}, packP={}; p.packed.forEach(function(x){ if(x.kind==="prototype") packP[x.name]=x.n; else packC[x.name]=x.n; });
    var s={active:true, n:n, started:new Date().toISOString(), lo:lo, heroesOut:[], lost:{}, copies:copies, pre:pre, pack:{cons:packC, protos:packP},
      pos:W().map().dock, haul:L().bag(), items:[], activity:null, log:[], steps:0, fights:0, paid:p.parts, lines:p.lines,
      preLines:p.pre, known0:W().knownCount?W().knownCount():0, maxSkull:0, kills:[], cards:clone(p.need), crafted:p.craft.map(function(c){ return {name:c.name, n:c.n}; })};
    note(s, "Left the dock with "+lo.name+".");
    if(p.craft.length) note(s, "Crafted for it: "+p.craft.map(function(c){ return (c.n>1?c.n+" × ":"")+c.name; }).join(", ")+".");
    save(s); W().stand(s.pos);
    return {ok:true, state:s};
  }

  /* designs and Strike Teams out on a deployment wait at the dock until it comes home */
  function lockedDesign(id){ var s=cur(); return !!(s && s.copies && s.copies[id]); }
  function lockedLoadout(lo){
    var s=cur(); if(!s||!lo) return false;
    if(s.lo.created && lo.created) return s.lo.created===lo.created;
    return s.lo.name===lo.name;
  }

  /* the Heroes and cards still with the team */
  function heroRefs(s){ s=s||cur(); if(!s) return []; return s.lo.heroes.filter(function(r){ return s.heroesOut.indexOf(r)<0; }); }
  function deckRefs(s){
    s=s||cur(); if(!s) return [];
    var gone=clone(s.lost||{}), all=cards();
    var deck=s.lo.deck.filter(function(r){
      var c=resolve(r,all); if(c && c._src==="design" && gone[c._design]>0){ gone[c._design]--; return false; } return true;
    });
    /* pre-built copies ride on top of the Deck, less those lost */
    Object.keys(s.pre||{}).forEach(function(id){ var d=WS().get(id); if(!d) return; var n=Math.max(0,s.pre[id]-(gone[id]||0)); for(var i=0;i<n;i++) deck.push("prebuilt|"+d.name); });
    return deck;
  }
  function team(){
    var s=cur(); if(!s) return null; var hs=heroRefs(s), acts={};
    hs.forEach(function(r){ if(s.lo.actions[r]) acts[r]=s.lo.actions[r]; });
    return {name:s.lo.name+" · deployed", level:s.lo.level, heroes:hs, deck:deckRefs(s), actions:acts, pouch:clone(s.lo.pouch||{}), deployed:true, pack:clone(s.pack||{cons:{},protos:{}})};
  }
  function copiesLeft(id, live){ var s=live||cur(); if(!s) return 0; return Math.max(0,((s.copies||{})[id]||0)+((s.pre||{})[id]||0)-(s.lost[id]||0)); }

  /* ---- walking ---- */
  function stepTo(k){
    var s=cur(); if(!s) return {moved:false, why:"No deployment"};
    if(s.activity) return {moved:false, why:"Finish what you started here first"};
    if(W().neighbours(s.pos).indexOf(k)<0 || !W().isOpen(k)) return {moved:false, why:"Not a step away"};
    s.pos=k; s.steps++; s.maxSkull=Math.max(s.maxSkull||0, W().skullOf(k)); save(s); W().stand(k);
    var home=k===W().map().dock, c=W().available(k)?W().contentAt(k):null;
    var out={moved:true, pos:k, home:home, content:c, ambush:false};
    if(c && c.kind==="ambush"){ out.ambush=true; out.tileAmbush=true; return out; }
    if(!home && rnd()*100 < W().ambushChance(k)){ out.ambush=true; out.content=null; }
    return out;
  }

  /* ---- fights ---- */
  function begin(kind, k, opts){
    var s=cur(); if(!s) return null; opts=opts||{};
    var d=W().districtOf(k), sk=W().skullOf(k), c=W().contentAt(k), fl;
    if(kind==="poi"){
      if(c && c.unique){ fl=(c.unique.floors||[]).filter(function(f){ return W().floors().some(function(x){ return x.key===f; }); }); if(!fl.length) fl=W().drawFloors(d, sk, W().floorCount(sk), {tile:k}); }
      else fl=W().drawFloors(d, sk, W().floorCount(sk), {tile:k});
    } else fl=W().drawFloors(d, sk, 1, {ambush:true, tile:k});
    if(!fl.length) return null;
    s.activity={kind:kind, tile:k, district:d, skull:sk, floors:fl, index:0, name:kind==="poi"?(c&&c.name||"POI"):"Ambush",
      type:kind==="poi"?(c&&c.type||""):"", unique:c&&c.unique?c.unique.id:null, tileAmbush:!!opts.tileAmbush, fromEvent:!!opts.fromEvent};
    note(s, kind==="poi" ? "Entered "+s.activity.name+" ("+fl.length+" floor"+(fl.length===1?"":"s")+")." : "Ambushed"+(opts.fromEvent?" after an event":"")+".");
    save(s); return spec();
  }
  function enterPOI(k){ return begin("poi", k); }
  function ambush(k, opts){ return begin("ambush", k, opts); }
  function spec(){
    var s=cur(); if(!s||!s.activity) return null; var a=s.activity;
    return {floor:a.floors[a.index], district:a.district, skull:a.skull, kind:a.kind, index:a.index, count:a.floors.length,
      name:a.name, type:a.type, tile:a.tile, n:s.n, pending:s.items.slice()};
  }
  function heroNames(s, refs){ var all=cards(); return refs.map(function(r){ var c=resolve(r,all); return c?c.name:String(r).split("|").slice(1).join("|"); }); }

  /* res: {winner:"ally"|"enemy"|"escape"|..., haul, reward, items, heroesDown:[names], troopsLost:[card names]} */
  function fightOver(res){
    var s=cur(); if(!s||!s.activity) return {next:"map"};
    var a=s.activity, all=cards(); s.fights++;
    /* the fallen: Heroes sit out, Troop copies are gone */
    var names=heroNames(s, s.lo.heroes);
    (res.heroesDown||[]).forEach(function(nm){ var i=names.indexOf(nm); if(i>=0 && s.heroesOut.indexOf(s.lo.heroes[i])<0){ s.heroesOut.push(s.lo.heroes[i]); note(s, nm+" is down and sits out the rest of the deployment."); } });
    (res.troopsLost||[]).forEach(function(nm){
      /* a copy of a design or of a pre-built Troop brought on this deployment, while one is left.
         v13.6: a Troop of a design the team didn't bring (one a Deploy put down) is nobody's
         copy, and the last copy can be lost but no more than that; this used to count both,
         and say so in the log */
      var c=all.filter(function(x){ return (x._src==="design"||x._src==="prebuilt") && x.name===nm && (((s.copies||{})[x._design])||((s.pre||{})[x._design])); })[0];
      if(c && copiesLeft(c._design, s)>0){ s.lost[c._design]=(s.lost[c._design]||0)+1; note(s, "A copy of "+nm+" is lost."); } });
    /* a Consumable used is used, whoever won */
    (res.consUsed||[]).forEach(function(nm){ var pk=s.pack&&s.pack.cons; if(pk && pk[nm]>0){ pk[nm]--; if(!pk[nm]) delete pk[nm]; } });
    var out={next:"map", kind:a.kind, name:a.name};
    if(res.winner==="ally" || res.winner==="escape"){
      /* the Enemies beaten, for the Bounty Board (claimed at home) */
      (res.kills||[]).forEach(function(x){ if(x && x.name) s.kills.push({name:x.name, skull:+x.skull||a.skull}); });
      var gained=L().add(res.haul, res.winner==="ally"?res.reward:null);
      s.haul=L().add(s.haul, gained);
      var its=[];
      (res.items||[]).forEach(function(it){ if(P().eligible(it, s.items)){ s.items.push(it); its.push(it); P().name(it); } });
      out.gained=gained; out.items=its;
      if(res.winner==="escape"){
        W().clear(a.tile, s.n); s.activity=null; note(s, "Escaped "+a.name+" through the Emergency Exit."); out.escaped=true;
      } else if(a.kind==="poi" && a.index+1<a.floors.length){
        a.index++; out.next="floor"; out.floor=a.index+1; out.count=a.floors.length; note(s, "Floor "+a.index+" of "+a.floors.length+" cleared.");
      } else if(a.kind==="poi"){
        var fin=finalReward(a, s); s.haul=L().add(s.haul, fin.bag);
        fin.items.forEach(function(it){ s.items.push(it); P().name(it); });
        W().clear(a.tile, s.n); s.activity=null; out.poiDone=true; out.final=fin; note(s, a.name+" cleared.");
      } else {
        if(a.tileAmbush) W().clear(a.tile, s.n);
        s.activity=null; note(s, "The ambush is beaten.");
      }
      save(s); return out;
    }
    /* lost: the fight's loot is gone; the haul stays while any Hero stands */
    if(heroRefs(s).length){ out.next="retry"; out.reserves=heroNames(s, heroRefs(s)); note(s, "The fight is lost; "+out.reserves.join(", ")+" can try again."); save(s); return out; }
    save(s); return Object.assign(wipe(), {next:"wipe"});
  }
  /* v13.5: `live` is the deployment as the fight just left it. This used to
     read the saved one, which did not yet hold what the last floor gave, so
     the reward could be a blueprint or chassis that floor had just found. */
  function finalReward(a, live){
    var T=W().tables(), u=a.unique?W().uniques().filter(function(x){ return x.id===a.unique; })[0]:null, rw, items=[];
    if(u && u.reward){ rw={shards:+u.reward.shards||0, lines:[{kind:"roll", n:+u.reward.n||0, type:u.reward.type||"any", bonus:+u.reward.bonus||0}]}; }
    else rw={shards:T.poi.shards*a.skull, lines:[{kind:"roll", n:T.poi.n, type:"any", bonus:T.poi.bonus}]};
    var b=L().rollReward(rw, a.skull), s=live||cur(), pend=(s?s.items:[]).slice();
    if(u && u.reward && Array.isArray(u.reward.items)) items=P().rollRewardItems({lines:u.reward.items.map(function(x){ return {kind:"item", item:x.item, chance:x.chance}; })}, pend);
    items=items.concat(P().rollItems({chance:u&&u.reward&&u.reward.bp!=null?+u.reward.bp:T.poi.bp, district:a.district, card:{}, cardChance:T.poi.card, skull:a.skull}, pend.concat(items)));
    return {bag:b, items:items};
  }
  function retryable(){ var s=cur(); return !!(s && s.activity && heroRefs(s).length); }

  /* ---- a cache: loot, no fight ---- */
  function openCache(k){
    var s=cur(); if(!s) return null; if(!W().available(k) || (W().contentAt(k)||{}).kind!=="cache") return null;
    var T=W().tables(), sk=W().skullOf(k);
    var b=L().rollReward({shards:T.cache.shards*sk, lines:[{kind:"roll", n:T.cache.n, type:"any", bonus:T.cache.bonus}]}, sk);
    var its=P().rollItems({chance:T.cache.bp, district:W().districtOf(k), card:{}, cardChance:T.cache.card, skull:sk}, s.items);
    s.haul=L().add(s.haul,b); its.forEach(function(it){ s.items.push(it); P().name(it); });
    W().clear(k, s.n); note(s, "Opened a cache: "+L().text(b)+(its.length?", and "+its.length+" more":"")+".");
    save(s); return {bag:b, items:its};
  }

  /* ---- an event: a choice, sometimes a d20 check ---- */
  function eventAt(k){ return W().available(k)&&(W().contentAt(k)||{}).kind==="event" ? W().eventFor(k) : null; }
  function choose(k, i){
    var s=cur(), ev=eventAt(k); if(!s||!ev) return null;
    var ch=ev.choices[i]; if(!ch) return null;
    var check=+ch.check||0, roll=check?1+Math.floor(rnd()*20):0, won=!check||roll>=check, o=(won?ch.win:ch.fail)||{};
    var sk=W().skullOf(k), got=L().bag(), items=[], lostBag=null;
    if(+o.shards) got.shards=Math.max(0,Math.round(+o.shards*sk));
    if(+o.n) got=L().add(got, L().rollReward({shards:0, lines:[{kind:"roll", n:+o.n, type:o.type||"any", bonus:+o.bonus||0}]}, sk));
    if(+o.bp) items=P().rollItems({chance:+o.bp, district:W().districtOf(k), card:{}}, s.items);
    if(+o.lose){
      var pc=Math.max(0,Math.min(100,+o.lose))/100, h=L().norm(s.haul); lostBag=L().bag();
      lostBag.shards=Math.floor(h.shards*pc); L().TYPES.forEach(function(ty){ h.parts[ty.id].forEach(function(n,r){ lostBag.parts[ty.id][r]=Math.floor(n*pc); }); });
      h.shards-=lostBag.shards; L().TYPES.forEach(function(ty){ h.parts[ty.id].forEach(function(n,r){ h.parts[ty.id][r]=n-lostBag.parts[ty.id][r]; }); });
      s.haul=h;
    }
    s.haul=L().add(s.haul, got); items.forEach(function(it){ s.items.push(it); P().name(it); });
    W().clear(k, s.n);
    note(s, ev.title+": "+ch.label+(check?" (rolled "+roll+", needed "+check+")":"")+".");
    save(s);
    var out={event:ev, choice:ch, check:check, roll:roll, won:won, text:o.text||"", got:got, items:items, lost:lostBag, fight:!!o.fight};
    if(o.fight) out.spec=ambush(k,{fromEvent:true});
    return out;
  }

  /* ---- coming home, or not ---- */
  function home(){
    var s=cur(); if(!s) return null;
    if(s.pos!==W().map().dock) return {ok:false, why:"The team has to reach the dock"};
    if(s.activity) return {ok:false, why:"Finish what you started first"};
    var X=L(), haul=X.norm(s.haul);
    if(!X.isEmpty(haul)) X.addToStock(haul, "Deployment "+s.n+" · home");
    var granted=[];
    s.items.map(P().parseItem).filter(Boolean).sort(function(a,b){ return (a.level||0)-(b.level||0); })
      .forEach(function(o){ var id=P().itemId(o); if(P().grant(id)) granted.push(id); });
    X.TYPES.forEach(function(ty){ haul.parts[ty.id].forEach(function(n,r){ if(n) P().see("comp", ty.id+":"+r); }); });
    /* what was packed and not used goes back to the dock */
    if(K()){ var v=K().inv(); var back=function(m){ Object.keys(m||{}).forEach(function(nm){ v.cards[nm]=(v.cards[nm]||0)+m[nm]; }); }; back((s.pack||{}).cons); back((s.pack||{}).protos);
      back(s.cards); K()._saveInv(v); }   /* (v14.19) and the cards it took */
    var explored=W().knownCount?W().knownCount()>(s.known0||0):true;
    W().endDeployment();
    pushHistory({n:s.n, result:"home", ended:new Date().toISOString(), team:s.lo.name, steps:s.steps, fights:s.fights, haul:haul, items:granted, lost:s.lost, out:s.heroesOut.length});
    s.active=false; s.ended=new Date().toISOString(); s.result="home"; note(s,"Home."); save(s);
    var dock=K()?K().deploymentEnded({result:"home", maxSkull:s.maxSkull||0, kills:s.kills||[], explored:explored}):{};
    return {ok:true, haul:haul, items:granted, n:s.n, dock:dock};
  }
  function wipe(){
    var s=cur(); if(!s) return null;
    var haul=L().norm(s.haul), items=s.items.slice();
    var explored=W().knownCount?W().knownCount()>(s.known0||0):true;
    W().endDeployment();
    pushHistory({n:s.n, result:"wipe", ended:new Date().toISOString(), team:s.lo.name, steps:s.steps, fights:s.fights, haul:haul, items:items, lost:s.lost, out:s.heroesOut.length});
    s.active=false; s.ended=new Date().toISOString(); s.result="wipe"; s.activity=null; note(s,"Wiped out. The haul is lost."); save(s);
    /* packed Consumables and Prototypes are lost with it; insurance may keep some of the haul */
    var dock=K()?K().deploymentEnded({result:"wipe", haul:haul, explored:explored, heroes:heroNames(s, s.lo.heroes)}):{};
    return {ok:true, lostHaul:haul, lostItems:items, n:s.n, dock:dock, lostPack:s.pack||{}, lostCards:clone(s.cards||{})};
  }
  /* Dev Mode: end it on the spot, nothing banked */
  function abandon(){ var s=cur(); if(!s) return false; s.active=false; s.result="abandoned"; save(s); W().endDeployment(); if(K()) K().deploymentEnded({result:"abandoned", explored:false}); return true; }
  function last(){ var s=read(KEY,null); return s&&!s.active?s:null; }

  window.KETER_DEPLOY={KEY:KEY, HIST_KEY:HIST_KEY, loadouts:loadouts, resolve:resolve, needOf:needOf, plan:plan, start:start, cur:cur, active:active,
    lockedDesign:lockedDesign, lockedLoadout:lockedLoadout, heroRefs:heroRefs, deckRefs:deckRefs, team:team, copiesLeft:copiesLeft,
    stepTo:stepTo, enterPOI:enterPOI, ambush:ambush, spec:spec, fightOver:fightOver, retryable:retryable,
    openCache:openCache, eventAt:eventAt, choose:choose, home:home, wipe:wipe, abandon:abandon, history:history, last:last,
    _save:save};
})();
