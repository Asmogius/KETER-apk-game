/* ===========================================================================
   KETER progress (v12.7) — the video game's: what the player owns, what they
   have discovered, and where everything can be found.

   Blueprints unlock keywords. Target words, damage, heal and turns are free
   from the start; every other keyword is a blueprint. One with a number has
   three levels, each raising the highest number allowed (Burst: 2, 3, 4);
   the rest have one. Level 1 is only ever found as loot; levels 2 and 3 are
   found or researched with shards, in order.

   Chassis are unlocked the same way, found as loot. One General chassis is
   the starter.

   Pools: each District has a hand-set list of the blueprint levels and chassis
   that can drop there at random; an Enemy card can add its own, and name set
   drops with their own chance. A random drop only ever gives the next level
   you are missing, or a chassis you do not have.

   The Codex fills in as things are met: an Enemy when it appears in a fight,
   a District when you fight in it, an item when it is looted. Dev Mode sees
   everything.
   =========================================================================== */
(function(){
  "use strict";
  var K=function(){ return window.KETER_KW; };
  var L=function(){ return window.KETER_LOOT; };
  var PROG_KEY="keter-app-progress", POOL_KEY="keter-app-pools";
  var STARTER="ch_test_general";
  var FREE={"damage":1, "heal":1, "turns":1};
  var DISTRICT_NAMES={"1":"Threshold Dynamics","2":"Halcyon Cognition","3":"Vantage Robotics","4":"Lazarus Computing","5":"Verdant Biogenics","6":"Meridian Entropics"};
  var TYPE_LABEL={enemy:"Enemy", elite:"Elite", miniboss:"Mini-Boss", boss:"Boss"};

  function rnd(){ return L() && L().rnd ? L().rnd() : Math.random(); }
  function read(key, d){ try{ var v=JSON.parse(localStorage.getItem(key)||"null"); return v==null?d:v; }catch(e){ return d; } }
  function write(key, v){ try{ localStorage.setItem(key, JSON.stringify(v)); return true; }catch(e){ return false; } }

  /* ---- the blueprints ---- */
  /* Revision 16.3: a whole side, and Troop or Hero, are Targets worth researching, unlike the rest */
  var PAID_TARGETS={"all allies":1, "all enemies":1, "Troop":1, "Hero":1};
  function isFree(k){ return !!k && ((k.cat==="target" && !PAID_TARGETS[k.name]) || !!FREE[k.name]); }
  function levelsOf(k){ return (k && (k.num==="amount"||k.num==="signed") && k.cat!=="condition" && k.cat!=="duration") ? 3 : 1; }
  function defaultCaps(k){ if(levelsOf(k)===1) return null; if(k.name==="Burst"||k.name==="Line") return [2,3,4]; if(k.cat==="stats") return [2,4,6]; return [1,2,3]; }
  /* your changes to the caps, research prices and part requirements live with the Workshop's tables */
  function wsTables(){ return window.KETER_WORKSHOP ? window.KETER_WORKSHOP.tables() : {caps:{}, research:{}, researchDefault:[0,60,120]}; }
  function capsOf(name){
    var k=K()&&K().byName(name); if(!k) return null;
    var d=defaultCaps(k); if(!d) return null;
    var mine=(wsTables().caps||{})[name];
    return Array.isArray(mine)&&mine.length===3 ? mine.map(function(v,i){ var x=parseInt(v,10); return x>0?x:d[i]; }) : d;
  }
  function catalog(){
    if(!K()) return [];
    return K().allKeywords().filter(function(k){ return !isFree(k) && !(K().isRetired&&K().isRetired(k.name)); })
      .map(function(k){ return {name:k.name, cat:k.cat, levels:levelsOf(k), caps:capsOf(k.name)}; });
  }
  function isBlueprint(name){ var k=K()&&K().byName(name); return !!k && !isFree(k); }
  function blueprintOf(name){ var k=K()&&K().byName(name); if(!k||isFree(k)) return null; return {name:k.name, cat:k.cat, levels:levelsOf(k), caps:capsOf(k.name)}; }
  /* the level a keyword needs to be used with this number: 0 if free, 4 if over the most any level allows */
  function levelFor(name, n){
    var b=blueprintOf(name); if(!b) return 0;
    if(b.levels===1 || !b.caps) return 1;
    var v=Math.abs(parseInt(String(n==null?"":n).replace(/[^0-9-]/g,""),10));
    if(isNaN(v)) return 1;
    for(var i=0;i<3;i++) if(v<=b.caps[i]) return i+1;
    return 4;
  }
  function researchPrice(name, level){
    var t=wsTables(), mine=(t.research||{})[name], d=t.researchDefault||[0,60,120];
    var v=Array.isArray(mine)&&mine[level-1]!=null&&mine[level-1]!=="" ? parseInt(mine[level-1],10) : d[level-1];
    return isNaN(v)?0:v;
  }

  /* ---- the player's progress ---- */
  function blank(){ return {bp:{}, ch:{}, seen:{enemy:{}, district:{}, comp:{}}, named:{}, all:false}; }
  function state(){
    var s=read(PROG_KEY, null)||blank();
    s.bp=s.bp||{}; s.ch=s.ch||{}; s.seen=s.seen||{}; s.named=s.named||{}; ["enemy","district","comp"].forEach(function(k){ s.seen[k]=s.seen[k]||{}; });
    return s;
  }
  function save(s){ return write(PROG_KEY, s); }
  /* Dev Mode, asked of the app; the Forge and the Sandbox ask their parent page */
  function dev(){
    var f=null;
    try{ f=window.KETER_ISDEV; }catch(e){}
    try{ if(!f && window.parent && window.parent!==window) f=window.parent.KETER_ISDEV; }catch(e){}
    try{ return !!(f && f()); }catch(e){ return false; }
  }
  function unlockAll(){ return !!state().all; }
  function setUnlockAll(on){ var s=state(); s.all=!!on; save(s); }
  function reset(){ try{ localStorage.removeItem(PROG_KEY); }catch(e){} }
  /* the highest level owned: free keywords count as everything */
  function owned(name, s){
    var b=blueprintOf(name); if(!b) return 99;
    s=s||state(); if(s.all) return b.levels;
    return Math.min(b.levels, parseInt(s.bp[name],10)||0);
  }
  function hasChassis(id, s){ s=s||state(); return !!(s.all || s.ch[id] || id===STARTER); }
  /* the keywords a set of abilities uses, each at the highest level any use needs */
  function needs(abilities){
    var out={};
    (abilities||[]).forEach(function(a){
      if(!K()) return;
      K().parse(a.text||"").forEach(function(p){
        if(p.type!=="kw" || !p.kw || p.kw.archetype) return;
        var lv=levelFor(p.kw.name, p.n); if(!lv) return;
        if(!out[p.kw.name] || out[p.kw.name]<lv) out[p.kw.name]=lv;
      });
    });
    return Object.keys(out).map(function(k){ return {name:k, level:out[k]}; });
  }
  /* what a design uses that the player does not own yet */
  function missing(abilities, s){
    s=s||state();
    return needs(abilities).filter(function(n){ return owned(n.name,s)<n.level; }).map(function(n){ var b=blueprintOf(n.name);
      return {name:n.name, level:n.level, have:owned(n.name,s), over:n.level>b.levels, max:b.caps?b.caps[b.levels-1]:null}; });
  }
  /* items: "bp:Burst:2" or "ch:<chassis id>" */
  function parseItem(it){
    var m=/^bp:(.+):(\d)$/.exec(String(it||"")); if(m) return {kind:"bp", name:m[1], level:+m[2]};
    var c=/^ch:(.+)$/.exec(String(it||"")); if(c) return {kind:"ch", id:c[1]};
    /* v14.9: a card found, a Consumable or a Prototype, kept at the dock */
    var d=/^cd:(.+)$/.exec(String(it||"")); if(d) return {kind:"cd", name:d[1]};
    return null;
  }
  function itemId(o){ return o.kind==="bp" ? "bp:"+o.name+":"+o.level : o.kind==="cd" ? "cd:"+o.name : "ch:"+o.id; }
  /* can this item drop for the player now? The next level missing, in order;
     a chassis not yet owned. `pending` is what this fight has already found. */
  function eligible(it, pending, s){
    var o=parseItem(it); if(!o) return false; s=s||state();
    if(o.kind==="cd") return true;     /* a card can be found again and again */
    var pend=(pending||[]).map(parseItem).filter(Boolean);
    if(o.kind==="ch"){ if(!chassisGet(o.id)) return false; return !hasChassis(o.id,s) && !pend.some(function(p){ return p.kind==="ch"&&p.id===o.id; }); }
    var b=blueprintOf(o.name); if(!b || o.level<1 || o.level>b.levels) return false;
    var have=owned(o.name,s); pend.forEach(function(p){ if(p.kind==="bp"&&p.name===o.name&&p.level>have) have=p.level; });
    return o.level===have+1;
  }
  /* won: the item is the player's (and discovered) */
  function grant(it){
    var o=parseItem(it); if(!o) return false;
    if(o.kind==="cd"){ if(!window.KETER_DOCK) return false; window.KETER_DOCK.addCard(o.name, 1); return true; }
    var s=state();
    if(o.kind==="ch"){ if(hasChassis(o.id,s)&&!s.all) return false; s.ch[o.id]=true; save(s); return true; }
    var have=parseInt(s.bp[o.name],10)||0; if(o.level!==have+1) return false;
    s.bp[o.name]=o.level; save(s); return true;
  }
  /* research the next level with shards from the stockpile: levels 2 and 3 only */
  function research(name){
    var b=blueprintOf(name), s=state(); if(!b) return {ok:false, why:"Not a blueprint"};
    /* v12.9: research happens at the dock, which is closed while a Strike Team is out */
    if(window.KETER_DEPLOY && window.KETER_DEPLOY.active()) return {ok:false, why:"The dock is closed while a Strike Team is out"};
    var have=parseInt(s.bp[name],10)||0, next=have+1;
    if(have<1) return {ok:false, why:"Its first level has to be found"};
    if(next>b.levels) return {ok:false, why:"Already at its highest level"};
    var price=researchPrice(name,next), st=L().stock();
    if(st.shards<price) return {ok:false, why:"Needs "+price+" shards; you have "+st.shards, price:price};
    st.shards-=price; L().setStock(st);
    s.bp[name]=next; save(s);
    try{ var h=JSON.parse(localStorage.getItem("keter-app-stockpile-log")||"[]"); h.unshift({t:new Date().toISOString(), why:"Researched "+name+" level "+next, bag:{shards:-price, parts:{}}}); localStorage.setItem("keter-app-stockpile-log",JSON.stringify(h.slice(0,30))); }catch(e){}
    return {ok:true, level:next, price:price};
  }

  /* ---- discovery ---- */
  function see(kind, key){ if(key==null||key==="") return; var s=state(); if(!s.seen[kind]) s.seen[kind]={}; if(s.seen[kind][key]) return; s.seen[kind][key]=1; save(s); }
  function seen(kind, key){ if(dev()) return true; var s=state(); return !!(s.seen[kind]&&s.seen[kind][key]); }
  /* a blueprint is known once its first level is owned; a chassis once owned.
     v12.8: or once a won fight on a deployment turned one up, even if the
     deployment never made it home */
  function knownBp(name){ return dev() || owned(name)>=1 || !!state().named["bp:"+name]; }
  function knownCh(id){ return dev() || hasChassis(id) || !!state().named["ch:"+id]; }
  function name(it){ var o=parseItem(it); if(!o || o.kind==="cd") return; var s=state(), k=o.kind==="bp"?"bp:"+o.name:"ch:"+o.id; if(s.named[k]) return; s.named[k]=1; save(s); }

  /* ---- pools ---- */
  function chassisGet(id){ return window.KETER_CHASSIS ? window.KETER_CHASSIS.get(id) : (read("keter-app-chassis",{})||{})[id]||null; }
  function chassisList(){ return window.KETER_CHASSIS ? window.KETER_CHASSIS.list() : Object.keys(read("keter-app-chassis",{})||{}).map(function(k){ return read("keter-app-chassis",{})[k]; }); }
  /* District 3 (where the test floors are) starts with a test pool */
  /* v14.9: and content batch 1's movement keywords */
  var DEFAULT_POOLS={"3":{items:["bp:Burst:1","bp:Burst:2","bp:Pierce:1","bp:Marked:1","bp:Weakened:1","bp:Weakened:2","bp:Slowed:1",
    "bp:AoE:1","bp:when:1","bp:is attacked:1","ch:ch_test_threshold","ch:ch_test_verdant",
    "bp:Lunge:1","bp:Charge:1","bp:Dash:1","bp:Leap:1"], test:true}};
  function pools(){ var p=read(POOL_KEY,null); return p&&typeof p==="object" ? p : JSON.parse(JSON.stringify(DEFAULT_POOLS)); }
  function poolItems(d){ var p=pools()[String(d||"")]; return p&&Array.isArray(p.items)?p.items.slice():[]; }
  function setPoolItem(d, it, on){
    var p=pools(), k=String(d||""); p[k]=p[k]||{items:[]}; var a=p[k].items, i=a.indexOf(it);
    if(on && i<0) a.push(it); if(!on && i>=0) a.splice(i,1);
    write(POOL_KEY,p);
  }
  function resetPools(){ try{ localStorage.removeItem(POOL_KEY); }catch(e){} }

  /* ---- rolling blueprint and chassis drops ----
     o: {chance (per cent), district, card (the Enemy's, with lootPool and setDrops);
     v14.9: cardChance (per cent) and skull, for a card as well} */
  function rollItems(o, pending){
    o=o||{}; var out=[], pend=(pending||[]).slice(), card=o.card||{};
    (card.setDrops||[]).forEach(function(d){
      if(!d||!d.item) return; var ch=Math.max(0,Math.min(100,+d.chance||0));
      if(rnd()*100<ch && eligible(d.item,pend.concat(out))) out.push(d.item);
    });
    if(rnd()*100 < (+o.chance||0)){
      var cands={};
      poolItems(o.district).concat(card.lootPool||[]).forEach(function(it){ if(eligible(it,pend.concat(out))) cands[it]=1; });
      var list=Object.keys(cands); if(list.length) out.push(list[Math.floor(rnd()*list.length)]);
    }
    /* v14.9: and, from an Elite, a Mini-Boss, a Boss, a Cache or a POI's reward, a card */
    if(+o.cardChance>0 && rnd()*100 < +o.cardChance){ var cd=cardDrop(o.district, o.skull); if(cd) out.push(cd); }
    return out;
  }
  /* ---- v14.9: cards as loot ----
     The Consumables and Prototypes of a District (or of none), the rarer ones
     only at higher Skull Levels: common from Skull 1, uncommon from 2, rare
     from 3, epic from 4, legendary from 5. One of them, evenly. */
  var CARD_SRC=null;
  function useCards(fn){ CARD_SRC=fn; }
  var RARITY_ORDER=["common","uncommon","rare","epic","legendary"];
  function cardDistrict(c){ var a=(c&&c.affinities||[])[0]; var d=a&&a.district!=null?String(a.district):String((c&&c.district)||""); return d==="any"?"":d; }
  function cardPool(district, skull){
    var cards=CARD_SRC ? (CARD_SRC()||[]) : [], d=String(district||""), sk=Math.max(1,Math.min(6,parseInt(skull,10)||1)), seen={}, out=[];
    cards.forEach(function(c){
      var t=String(c&&(c.cardType||c.type)||"").toLowerCase(); if(t!=="consumable" && t!=="prototype") return;
      if(c.testCard) return;          /* the test cards are for checking the rules, never loot */
      var cdd=cardDistrict(c); if(cdd && cdd!==d) return;
      var r=RARITY_ORDER.indexOf(String(c.rarity||"common").toLowerCase()); if(r<0) r=0;
      if(r>sk-1 || !c.name || seen[c.name]) return;
      seen[c.name]=1; out.push(String(c.name));
    });
    return out.sort(function(a,b){ return a<b?-1:(a>b?1:0); });
  }
  function cardDrop(district, skull){ var l=cardPool(district, skull); return l.length ? "cd:"+l[Math.floor(rnd()*l.length)] : null; }
  /* a floor reward's item lines: {kind:"item", item, chance} */
  function rollRewardItems(rw, pending){
    var out=[];
    ((rw&&rw.lines)||[]).forEach(function(l){
      if(l.kind!=="item"||!l.item) return; var ch=Math.max(0,Math.min(100,+l.chance||0));
      if(rnd()*100<ch && eligible(l.item,(pending||[]).concat(out))) out.push(l.item);
    });
    return out;
  }
  function itemName(it, reveal){
    var o=parseItem(it); if(!o) return String(it||"");
    if(o.kind==="cd") return o.name;
    if(o.kind==="ch"){ var c=chassisGet(o.id); var nm=c?c.name:o.id; return (reveal||knownCh(o.id))?nm:"an unknown chassis"; }
    var b=blueprintOf(o.name), lv=b&&b.levels>1?" L"+o.level:"";
    return (reveal||knownBp(o.name)) ? o.name+lv+(b&&b.caps?" (up to "+b.caps[o.level-1]+")":"") : "an unknown blueprint";
  }
  /* every item that could be chosen: blueprint levels and chassis */
  function allItems(){
    var out=[];
    catalog().forEach(function(b){ for(var l=1;l<=b.levels;l++) out.push("bp:"+b.name+":"+l); });
    chassisList().forEach(function(c){ if(c&&c.id) out.push("ch:"+c.id); });
    return out;
  }

  /* ---- where to find it ----
     cards: every card the app knows (Enemies carry lootPool, setDrops, salvage);
     floors: the saved floors. Returns a list of sources, each saying what it is. */
  function enemyDistrict(c){ var a=(c.affinities||[])[0]; return a&&a.district?String(a.district):""; }
  function isFoe(c){ return /^(enemy|elite|miniboss|boss)$/.test(String(c&&c.cardType||"")); }
  function savedFloors(){ var all=read("keter-hexmap-levels",{})||{}; return Object.keys(all).map(function(k){ var f=all[k]; return f?{key:k, name:f.name||k, district:String(f.district||""), loot:f.loot||null, lv:f}:null; }).filter(Boolean); }
  function sourcesOf(it, cards){
    var out=[], o=parseItem(it); if(!o) return out;
    var p=pools(); Object.keys(p).forEach(function(d){ if((p[d].items||[]).indexOf(it)>=0) out.push({kind:"district", district:d, name:DISTRICT_NAMES[d]||("District "+d)}); });
    (cards||[]).filter(isFoe).forEach(function(c){
      var set=(c.setDrops||[]).filter(function(d){ return d&&d.item===it; })[0];
      if(set) out.push({kind:"enemy", card:c.name, cardType:c.cardType, district:enemyDistrict(c), chance:+set.chance||0, set:true});
      else if((c.lootPool||[]).indexOf(it)>=0) out.push({kind:"enemy", card:c.name, cardType:c.cardType, district:enemyDistrict(c), set:false});
    });
    savedFloors().forEach(function(f){ ((f.loot&&f.loot.lines)||[]).forEach(function(l){ if(l.kind==="item"&&l.item===it) out.push({kind:"floor", floor:f.name, district:f.district, chance:+l.chance||0}); }); });
    /* v12.8: a Unique POI's own set drops */
    if(window.KETER_WORLD) window.KETER_WORLD.uniques().forEach(function(u){ ((u.reward&&u.reward.items)||[]).forEach(function(x){ if(x.item===it) out.push({kind:"unique", name:u.name||"Unique POI", district:u.tile?window.KETER_WORLD.districtOf(u.tile):"", chance:+x.chance||0}); }); });
    if(o.kind==="bp" && o.level>=2) out.push({kind:"research", price:researchPrice(o.name,o.level)});
    return out;
  }
  /* a source in words, with an Enemy named only once met */
  function sourceText(s, reveal){
    if(s.kind==="district") return "District "+s.district+" · "+s.name+" — a rare drop from anything there";
    if(s.kind==="floor") return "Floor: "+s.floor+(s.district?" (District "+s.district+")":"")+" — its reward, "+s.chance+"%";
    if(s.kind==="research") return "Research at the dock — "+s.price+" shards";
    if(s.kind==="unique") return s.name+(s.district?" (District "+s.district+")":"")+" — its reward, "+s.chance+"%";
    var who=(reveal||seen("enemy",s.card)) ? s.card+" ("+(TYPE_LABEL[s.cardType]||"Enemy")+")" : "a"+(/^[aeiou]/i.test(TYPE_LABEL[s.cardType]||"Enemy")?"n ":" ")+(TYPE_LABEL[s.cardType]||"Enemy")+" in District "+(s.district||"?");
    return who+(s.set?" — "+s.chance+"%":" — a rare drop");
  }

  window.KETER_PROG={STARTER:STARTER, FREE:FREE, PAID_TARGETS:PAID_TARGETS, DISTRICT_NAMES:DISTRICT_NAMES, TYPE_LABEL:TYPE_LABEL, PROG_KEY:PROG_KEY, POOL_KEY:POOL_KEY,
    isFree:isFree, catalog:catalog, isBlueprint:isBlueprint, blueprintOf:blueprintOf, levelFor:levelFor, capsOf:capsOf, researchPrice:researchPrice,
    state:state, save:save, reset:reset, unlockAll:unlockAll, setUnlockAll:setUnlockAll, owned:owned, hasChassis:hasChassis, needs:needs, missing:missing,
    parseItem:parseItem, itemId:itemId, eligible:eligible, grant:grant, research:research, see:see, seen:seen, knownBp:knownBp, knownCh:knownCh, name:name, dev:dev,
    pools:pools, poolItems:poolItems, setPoolItem:setPoolItem, resetPools:resetPools, rollItems:rollItems, rollRewardItems:rollRewardItems,
    itemName:itemName, allItems:allItems, chassisGet:chassisGet, chassisList:chassisList, sourcesOf:sourcesOf, sourceText:sourceText,
    enemyDistrict:enemyDistrict, isFoe:isFoe, savedFloors:savedFloors,
    useCards:useCards, cardPool:cardPool, cardDrop:cardDrop, RARITY_ORDER:RARITY_ORDER};
})();
