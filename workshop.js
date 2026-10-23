/* ===========================================================================
   KETER Workshop (v12.7) — designing Troops for the video game.

   A design is a chassis plus abilities. The chassis fixes its stats (HP, AC,
   MS, NRG, INT and the DMG of its attacks), its subtypes, its Aether cost, a
   power cap, an ability cap, the keywords it allows, and the most range,
   to-hit and armour penetration an attack may have. The designer names it,
   writes each ability, picks each Action's Energy cost and each attack's
   range, to-hit and AP.

   Power: the keyword score (an attack counts 4; Modifiers multiply), plus
   points for an attack's numbers above the role's baseline, then more for a
   cheap Action (a free one can be used every turn).

   A copy costs  chassis cost + rate x power  Common Troop parts, plus whatever
   rarer parts its keywords require at the level used (a table you fill).
   Copies are paid when deploying (to come); the Workshop says how many your
   stockpile could pay for.

   A design is also a Troop card: it appears as a "Design" in the Compendium,
   the Deck Builder and the Battle Simulator.
   =========================================================================== */
(function(){
  "use strict";
  var STORE="keter-app-designs", WS_KEY="keter-app-workshop";
  var P=function(){ return window.KETER_PROG; };
  var CH=function(){ return window.KETER_CHASSIS; };
  var L=function(){ return window.KETER_LOOT; };
  var DEFAULTS={v:1, rate:0.5, energyBase:2, energyStep:0.25,
    /* hit: "base" is the to-hit an attack is priced at; "per" is no longer used (see hitFactor) */
    numbers:{range:{base:4, per:0.5}, hit:{base:6, per:0}, ap:{base:4, per:0.5}},
    researchDefault:[0,60,120], research:{}, caps:{}, require:{}};
  var ROLES=["Melee","Ranged","Support","Cyber"];

  function clone(o){ return JSON.parse(JSON.stringify(o)); }
  function num(v,d){ var x=parseFloat(v); return isNaN(x)?(d||0):x; }
  function read(k,d){ try{ var v=JSON.parse(localStorage.getItem(k)||"null"); return v==null?d:v; }catch(e){ return d; } }
  function write(k,v){ try{ localStorage.setItem(k,JSON.stringify(v)); return true; }catch(e){ return false; } }

  /* ---- the Workshop's tables: rate, Energy, attack numbers, blueprint caps,
     research prices and each keyword's part requirements ---- */
  function tables(){
    var t=clone(DEFAULTS), m=read(WS_KEY,null);
    if(m && typeof m==="object"){
      if(isFinite(+m.rate)) t.rate=Math.max(0,+m.rate);
      if(isFinite(+m.energyBase)) t.energyBase=Math.max(0,+m.energyBase);
      if(isFinite(+m.energyStep)) t.energyStep=Math.max(0,+m.energyStep);
      if(m.numbers) ["range","hit","ap"].forEach(function(k){ var x=m.numbers[k]; if(x){ if(isFinite(+x.base)) t.numbers[k].base=+x.base; if(isFinite(+x.per)) t.numbers[k].per=+x.per; } });
      ["research","caps","require"].forEach(function(k){ if(m[k] && typeof m[k]==="object") t[k]=m[k]; });
    }
    return t;
  }
  function saveTables(t){ return write(WS_KEY,t); }
  function resetTables(){ try{ localStorage.removeItem(WS_KEY); }catch(e){} }

  /* ---- designs ----
     v12.8: the built-in starter, a plain design on the General chassis. Each
     deployment brings a few copies of it free, so it cannot be changed; copy
     it to make your own. */
  var STARTER={id:"ds_starter", name:"Frame Trooper", chassis:"ch_test_general", starter:true,
    abilities:[{name:"Carbine", kind:"action", role:"Ranged", energy:1, range:4, hit:6, ap:4, text:"[[target enemy]] takes [[damage 1]]."}],
    notes:"The built-in starter: a few free copies every deployment."};
  function all(){ var m=read(STORE,{}); m=(m && typeof m==="object") ? m : {}; if(!m[STARTER.id]) m[STARTER.id]=clone(STARTER); return m; }
  /* a design out on a deployment, or the starter, is not changed here */
  function locked(id){ return id===STARTER.id || !!(window.KETER_DEPLOY && window.KETER_DEPLOY.lockedDesign(id)); }
  function list(){ var m=all(); return Object.keys(m).map(function(k){ return m[k]; }).filter(function(d){ return !d.prebuilt; }).sort(function(a,b){ return String(a.name).localeCompare(String(b.name)); }); }
  /* v12.9: pre-built Troops, made in Dev Mode for the Exchange, in the order made */
  function prebuilts(){ var m=all(); return Object.keys(m).map(function(k){ return m[k]; }).filter(function(d){ return d.prebuilt; }).sort(function(a,b){ return (+a.order||0)-(+b.order||0) || String(a.name).localeCompare(String(b.name)); }); }
  function get(id){ var d=all()[id]; return d?clone(d):null; }
  function put(d){
    if(d.id && locked(d.id)) return null;
    var m=all(); if(!d.id) d.id="ds_"+Date.now().toString(36)+Math.random().toString(36).slice(2,6);
    d.saved=new Date().toISOString(); m[d.id]=clone(d); return write(STORE,m)?d.id:null;
  }
  function remove(id){ if(locked(id)) return false; var m=all(); delete m[id]; return write(STORE,m); }
  function chassisOf(d){ return d && CH() ? CH().get(d.chassis) : null; }
  /* an attack's numbers start at the role's baseline, within the chassis's maximums */
  function blankAbility(ch, kind){
    var sub=((ch&&ch.subtypes)||["Melee"])[0], t=tables().numbers;
    if(kind==="passive") return {name:"", kind:"passive", role:"", text:""};
    return {name:"", kind:"action", role:sub, energy:1, range:Math.min(t.range.base, maxOf(ch,"range")), hit:Math.min(maxOf(ch,"hit"), Math.max(t.hit.base, bestHit(ch))), ap:Math.min(t.ap.base, maxOf(ch,"ap")), text:""};
  }
  function blank(chassisId){
    var ch=CH()&&CH().get(chassisId);
    return {id:null, name:"New design", chassis:chassisId, abilities:[blankAbility(ch,"action")], notes:""};
  }
  /* the most a chassis lets an attack's range or AP be; a to-hit can be as high as 20 */
  function maxOf(ch, k){ if(k==="hit") return 20; var m={range:"maxRange", ap:"maxAP"}[k]; return Math.max(0, num(ch&&ch[m], {range:6,ap:6}[k])); }
  /* Handbook 16.0: a lower to-hit is better, so a chassis sets the best (lowest)
     to-hit its attacks may have, and they choose from it up to 20. A chassis
     from before kept "maxHit", the most an attack could have: it reads as 12
     minus that, so the old ranking holds (8 becomes 4). */
  function bestHit(ch){
    if(ch && ch.bestHit!=null && ch.bestHit!=="") return Math.min(20, Math.max(1, num(ch.bestHit, 4)));
    if(ch && ch.maxHit!=null && ch.maxHit!=="") return Math.min(20, Math.max(1, 12-num(ch.maxHit, 8)));
    return 4;
  }
  function leastOf(ch, k){ return k==="hit" ? bestHit(ch) : 0; }
  /* which of range, to-hit and AP an Action uses */
  function fieldsFor(ab){
    if(!ab || ab.kind==="passive") return [];
    var r=String(ab.role||"").toLowerCase();
    if(r==="melee") return ["ap"];
    if(r==="ranged"||r==="cyber") return ["range","hit","ap"];
    return [];
  }
  function isAttack(ab){ var r=String(ab&&ab.role||"").toLowerCase(); return ab && ab.kind!=="passive" && (r==="melee"||r==="ranged"||r==="cyber"); }

  /* ---- power ---- */
  function abilityPower(ab, ch, t){
    t=t||tables(); var S=window.KETER_SCORE;
    var att=isAttack(ab), d=S&&S.keywordDetail ? S.keywordDetail(ab.text||"", {attack:att}) : null;
    var base=d?d.base:(att?4:(String(ab.text||"").trim()?4:0)), mult=d?d.mult:1;
    var extra=0, hf=1;
    fieldsFor(ab).forEach(function(k){ var n=t.numbers[k];
      if(k==="hit"){ hf=hitFactor(num(ab[k], n.base), n.base); return; }
      extra+=(num(ab[k], n.base)-n.base)*n.per; });
    var ef=ab.kind==="passive" ? 1 : 1+t.energyStep*Math.max(0, t.energyBase-num(ab.energy,t.energyBase));
    return Math.max(0, Math.round(Math.max(0,base+extra)*mult*ef*hf));
  }
  /* To-hit is a d20 threshold (the roll must reach it), so the lower it is the
     more often everything the attack carries lands. An aimed attack's worth
     scales with its chance to hit, P = (21 - hit) / 20, measured against the
     priced-at to-hit: 1.0 at base 6, 1.33 at 1 (always hits), 0 at 21 (never). */
  function hitFactor(hit, base){
    var h=Math.min(21,Math.max(1,hit)), b=Math.min(20,Math.max(1,base));
    return (21-h)/(21-b);
  }
  function power(d, t){ var ch=chassisOf(d); t=t||tables(); return (d.abilities||[]).reduce(function(s,a){ return s+abilityPower(a,ch,t); },0); }

  /* ---- the fit check: the chassis's, the numbers, the blueprints ---- */
  function check(d){
    var ch=chassisOf(d), t=tables(), reasons=[];
    if(!ch) return {ok:false, reasons:["its chassis is missing"], power:0, cap:0};
    var abs=(d.abilities||[]).map(function(a){ return {text:a.text||"", role:a.kind==="passive"?"":String(a.role||"").toLowerCase(), power:abilityPower(a,ch,t)}; });
    var c=CH().check(ch, {abilities:abs});
    reasons=c.reasons.slice();
    var nrg=num(ch.stats&&ch.stats.nrg,0);
    (d.abilities||[]).forEach(function(a,i){
      var label="ability "+(i+1)+(a.name?" ("+a.name+")":"");
      if(!String(a.text||"").trim()) reasons.push(label+" has no text");
      if(a.kind!=="passive" && num(a.energy,0)>nrg) reasons.push(label+" costs "+a.energy+" Energy, more than this chassis's "+nrg);
      fieldsFor(a).forEach(function(k){ var mx=maxOf(ch,k), nm={range:"range",hit:"to-hit",ap:"AP"}[k];
        if(k==="hit"){ var h=num(a.hit, t.numbers.hit.base), lo=bestHit(ch);
          if(h<lo) reasons.push(label+"'s to-hit of "+h+" is better than this chassis's best of "+lo);
          else if(h>mx) reasons.push(label+"'s to-hit of "+h+" is over "+mx+", so it could never hit");
          return; }
        if(num(a[k],0)>mx) reasons.push(label+"'s "+nm+" of "+a[k]+" is over this chassis's "+mx); });
    });
    /* a pre-built Troop is made to show what you can't make yet: only its fit counts */
    var miss=P()?P().missing(d.abilities||[]).filter(function(m){ return !d.prebuilt || m.over; }):[];
    miss.forEach(function(m){
      if(m.over) reasons.push(m.name+" is used higher than any blueprint level allows (the most is "+m.max+")");
      else reasons.push(m.name+" needs blueprint level "+m.level+(m.have?" — you have level "+m.have:" — not found yet"));
    });
    if(P() && !d.prebuilt && !P().hasChassis(ch.id)) reasons.push("this chassis has not been found yet");
    return {ok:!reasons.length, reasons:reasons, power:c.power, cap:c.cap, abilities:c.abilities, abilityCap:c.abilityCap, missing:miss};
  }

  /* ---- what a copy costs, in Troop parts ---- */
  function cost(d, t){
    t=t||tables(); var ch=chassisOf(d), parts=[0,0,0,0,0,0], p=power(d,t);
    parts[0]=Math.ceil(num(ch&&ch.cost&&ch.cost.troop,0)+t.rate*p);
    var lines=[{label:"Chassis "+num(ch&&ch.cost&&ch.cost.troop,0)+" + "+t.rate+" × power "+p, parts:[parts[0],0,0,0,0,0]}];
    (P()?P().needs(d.abilities||[]):[]).forEach(function(n){
      var req=((t.require||{})[n.name]||{})[n.level]; if(!req) return;
      var row=[0,0,0,0,0,0], any=false;
      Object.keys(req).forEach(function(r){ var c=Math.max(0,parseInt(req[r],10)||0); if(c){ row[+r]+=c; parts[+r]+=c; any=true; } });
      if(any) lines.push({label:n.name+(P().blueprintOf(n.name).levels>1?" L"+n.level:""), parts:row});
    });
    return {parts:parts, power:p, lines:lines};
  }
  /* how many copies the stockpile could pay for */
  function affordable(d){
    var c=cost(d), st=L()?L().stock():null, best=Infinity;
    if(!st) return 0;
    c.parts.forEach(function(n,r){ if(n>0) best=Math.min(best, Math.floor(st.parts.troop[r]/n)); });
    return best===Infinity?0:best;
  }

  /* v13.9: what a Ranged (or Cyber) Action fires, in the game; none is a bolt */
  var PROJECTILES=["bolt","shell","beam","spray"];

  /* ---- a design as a Troop card ---- */
  function toCard(d){
    var ch=chassisOf(d)||{}, st=ch.stats||{}, att=function(a){ return isAttack(a); };
    var dist=String(ch.district||"");
    /* v13.0: its look is a skin of its body plan */
    var look=null; try{ look=window.KETER_SKINS?window.KETER_SKINS.picsOfDesign(d):null; }catch(e){}
    return {id:"WS-"+String(d.id||"").slice(3).toUpperCase(), cardType:"troop", name:d.name||"Untitled design",
      affinities:dist?[{district:dist, level:0}]:[], archetypes:[], rarity:null, level:1,
      stats:{hp:String(num(st.hp,12)), ac:String(num(st.ac,10)), int:String(num(st.int,10)), nrg:String(num(st.nrg,3)), move:String(num(st.move,4)), uslot:"1"},
      aetherCost:{generic:num(ch.aether&&ch.aether.generic,1), affinity:num(ch.aether&&ch.aether.affinity,0), affinity2:0},
      combatRoles:(ch.subtypes||[]).map(function(x){ return String(x).toLowerCase(); }),
      entries:(d.abilities||[]).map(function(a){
        var e={name:a.name||(a.kind==="passive"?"Passive":"Action"), kind:a.kind==="passive"?"Passive":"Active", text:a.text||""};
        if(a.kind!=="passive"){ e.role=String(a.role||"").toLowerCase(); e.energyCost=String(num(a.energy,0)); }
        if(att(a)){ e.damage=String(num(st.dmg,2)); e.armorPenetration=String(num(a.ap,0));
          if(e.role!=="melee"){ e.attackRange=String(num(a.range,1)); e.toHit=String(num(a.hit,0));
            /* v13.9: what it fires, for the game to draw */
            if(PROJECTILES.indexOf(a.projectile)>=0) e.projectile=a.projectile; } }
        return e; }),
      design:d.id, chassis:ch.id||d.chassis, chassisName:ch.name||"", pixelArt:(look&&look.art)||d.pixelArt||undefined, pixelToken:(look&&look.token)||d.pixelToken||undefined};
  }
  function cards(){ return list().map(function(d){ var c=toCard(d); c._src="design"; c._design=d.id; if(d.starter) c.starter=true; return c; }); }
  /* pre-built Troops as cards: for deployments and fights only, never the Deck Builder */
  function prebuiltCards(){ return prebuilts().map(function(d){ var c=toCard(d); c._src="prebuilt"; c._design=d.id; c.prebuilt=true; return c; }); }

  window.KETER_WORKSHOP={PROJECTILES:PROJECTILES, STORE:STORE, WS_KEY:WS_KEY, DEFAULTS:DEFAULTS, ROLES:ROLES, tables:tables, saveTables:saveTables, resetTables:resetTables,
    STARTER:STARTER, locked:locked, list:list, prebuilts:prebuilts, prebuiltCards:prebuiltCards, get:get, put:put, remove:remove, blank:blank, blankAbility:blankAbility, chassisOf:chassisOf, maxOf:maxOf, bestHit:bestHit, leastOf:leastOf, fieldsFor:fieldsFor, isAttack:isAttack,
    abilityPower:abilityPower, power:power, check:check, cost:cost, affordable:affordable, toCard:toCard, cards:cards};
})();
