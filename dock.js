/* ===========================================================================
   KETER dock (v12.9) — home base between deployments.

   The Exchange sells components (Commons always; a few limited lots of rarer
   ones, never rarer than your reach, the highest Skull Level a haul has come
   home from), blueprints and chassis from the pools of Districts you have
   fought in (only what you could get next), the Consumables and Prototypes you
   pick in Dev Mode, and pre-built Troops you design in Dev Mode: finished
   designs you can't make yet, bought by the copy for the next deployment
   only. It restocks after a deployment that revealed new ground, and buys
   components, Consumables and Prototypes back at half price.

   Reclaiming turns three of a rarity into one of the next (never past your
   reach) and two of one part type into one of another.

   The Bounty Board names two Enemies and one Elite, Mini-Boss or Boss you have
   met; beat one in a won fight on a deployment and it pays shards and
   components when you get home.

   Upgrades, paid in shards and parts: more Exchange stock, more free starter
   copies, insurance on a wiped haul, and a longer-range scanner.

   Recruiting (v14.14): a few Heroes on offer, from the Districts you have
   fought in (or none), changing when the Exchange restocks; more of them with
   each level of Exchange stock. A Hero is priced by its rarity and is yours
   until a Strike Team it went out with is wiped out. The free Heroes (Dev
   Mode lists them) are always yours and never lost, so a team can always
   leave; a Hero whose name starts "Test " is never on offer.

   The dock is closed while a Strike Team is out.
   =========================================================================== */
(function(){
  "use strict";
  var KEY="keter-app-dock", INV_KEY="keter-app-inventory", TAB_KEY="keter-app-dock-tables";
  var L=function(){ return window.KETER_LOOT; }, P=function(){ return window.KETER_PROG; };
  var W=function(){ return window.KETER_WORLD; }, D=function(){ return window.KETER_DEPLOY; }, WS=function(){ return window.KETER_WORKSHOP; };
  var UPGRADES=[
    {id:"exchange", name:"Exchange stock", what:"More lots of rarer components, and more pre-built Troops and Heroes on offer at once."},
    {id:"starter", name:"Starter bay", what:"More free starter copies every deployment."},
    {id:"insurance", name:"Salvage insurance", what:"Keep a share of the haul's shards and parts after a wipe."},
    {id:"scanner", name:"Long-range scanner", what:"See what tiles hold further from where the Strike Team stands."}];
  var KIND_LABEL={enemy:"Enemy", elite:"Elite", miniboss:"Mini-Boss", boss:"Boss"};
  var DEFAULTS={v:1,
    price:[6,15,40,100,250,600], sell:0.5,
    bpFirst:150, bpLater:1.25, chassis:300, preMult:1.5,
    lots:3, lotMax:3, bpOffers:2, chOffers:1, itemsOnOffer:3, preOnOffer:3,
    reclaimUp:3, reclaimSwap:2,
    bounty:{shards:{enemy:15, elite:30, miniboss:60, boss:120}, n:{enemy:1, elite:2, miniboss:3, boss:5}},
    items:[],   /* Consumables and Prototypes the Exchange carries: {name, price} */
    heroPrice:[40,80,150,300,600,1200], heroOnOffer:3,
    free:["Dock Hand","Hangar Rifleman","Field Medic"],   /* (v14.14) Heroes always yours */
    effect:{exchange:[1,2,3], starter:[6,8,10], insurance:[10,20,30], scanner:[2,3,4]},
    cost:{exchange:[[150,"equipment",0,10],[400,"equipment",1,6],[900,"equipment",2,3]],
          starter:[[150,"troop",0,10],[400,"troop",1,6],[900,"troop",2,3]],
          insurance:[[150,"aether",0,10],[400,"aether",1,6],[900,"aether",2,3]],
          scanner:[[150,"equipment",0,10],[400,"equipment",1,6],[900,"equipment",2,3]]}};

  function clone(o){ return JSON.parse(JSON.stringify(o)); }
  function read(k,d){ try{ var v=JSON.parse(localStorage.getItem(k)||"null"); return v==null?d:v; }catch(e){ return d; } }
  function write(k,v){ try{ localStorage.setItem(k,JSON.stringify(v)); return true; }catch(e){ return false; } }
  function rnd(){ var x=L(); return x&&x.rnd?x.rnd():Math.random(); }
  function cards(){ try{ return window.KETER_ALLCARDS ? window.KETER_ALLCARDS() : []; }catch(e){ return []; } }
  function num(v,d){ var x=parseFloat(v); return isNaN(x)?d:x; }

  /* ---- the dock's tables: your changes only ---- */
  function tables(){
    var t=clone(DEFAULTS), m=read(TAB_KEY,null);
    if(m && typeof m==="object"){
      if(Array.isArray(m.price)&&m.price.length===6) t.price=m.price.map(function(v,i){ return Math.max(0,num(v,DEFAULTS.price[i])); });
      if(Array.isArray(m.heroPrice)&&m.heroPrice.length===6) t.heroPrice=m.heroPrice.map(function(v,i){ return Math.max(0,num(v,DEFAULTS.heroPrice[i])); });
      if(Array.isArray(m.free)) t.free=m.free.filter(function(x){ return typeof x==="string" && x; });
      ["sell","bpFirst","bpLater","chassis","preMult","lots","lotMax","bpOffers","chOffers","itemsOnOffer","preOnOffer","reclaimUp","reclaimSwap","heroOnOffer"].forEach(function(k){ if(m[k]!=null&&isFinite(+m[k])) t[k]=Math.max(0,+m[k]); });
      if(m.bounty) ["shards","n"].forEach(function(s){ if(m.bounty[s]) Object.keys(KIND_LABEL).forEach(function(k){ if(isFinite(+m.bounty[s][k])) t.bounty[s][k]=Math.max(0,+m.bounty[s][k]); }); });
      if(Array.isArray(m.items)) t.items=m.items.filter(function(x){ return x&&x.name; }).map(function(x){ return {name:String(x.name), price:Math.max(0,num(x.price,20))}; });
      if(m.effect) UPGRADES.forEach(function(u){ if(Array.isArray(m.effect[u.id])&&m.effect[u.id].length===3) t.effect[u.id]=m.effect[u.id].map(function(v,i){ return num(v,DEFAULTS.effect[u.id][i]); }); });
      if(m.cost) UPGRADES.forEach(function(u){ if(Array.isArray(m.cost[u.id])&&m.cost[u.id].length===3) t.cost[u.id]=m.cost[u.id].map(function(c,i){ var d=DEFAULTS.cost[u.id][i]; c=Array.isArray(c)?c:d;
        return [Math.max(0,num(c[0],d[0])), ["troop","equipment","aether"].indexOf(c[1])>=0?c[1]:d[1], Math.max(0,Math.min(5,parseInt(c[2],10)||0)), Math.max(0,parseInt(c[3],10)||0)]; }); });
    }
    t.reclaimUp=Math.max(2,Math.round(t.reclaimUp)); t.reclaimSwap=Math.max(1,Math.round(t.reclaimSwap));
    return t;
  }
  function saveTables(t){
    var d={}, D0=DEFAULTS;
    if(JSON.stringify(t.price.map(Number))!==JSON.stringify(D0.price)) d.price=t.price.map(Number);
    if(JSON.stringify(t.heroPrice.map(Number))!==JSON.stringify(D0.heroPrice)) d.heroPrice=t.heroPrice.map(Number);
    if(JSON.stringify(t.free)!==JSON.stringify(D0.free)) d.free=t.free.slice();
    ["sell","bpFirst","bpLater","chassis","preMult","lots","lotMax","bpOffers","chOffers","itemsOnOffer","preOnOffer","reclaimUp","reclaimSwap","heroOnOffer"].forEach(function(k){ if(+t[k]!==D0[k]) d[k]=+t[k]; });
    ["shards","n"].forEach(function(s){ Object.keys(KIND_LABEL).forEach(function(k){ if(+t.bounty[s][k]!==D0.bounty[s][k]){ d.bounty=d.bounty||{}; d.bounty[s]=d.bounty[s]||{}; d.bounty[s][k]=+t.bounty[s][k]; } }); });
    if(t.items.length) d.items=t.items;
    UPGRADES.forEach(function(u){
      if(JSON.stringify(t.effect[u.id])!==JSON.stringify(D0.effect[u.id])){ d.effect=d.effect||{}; d.effect[u.id]=t.effect[u.id]; }
      if(JSON.stringify(t.cost[u.id])!==JSON.stringify(D0.cost[u.id])){ d.cost=d.cost||{}; d.cost[u.id]=t.cost[u.id]; }
    });
    return write(TAB_KEY,d);
  }
  function resetTables(){ var t=tables(), keep=t.items, d={}; try{ localStorage.removeItem(TAB_KEY); }catch(e){}
    if(keep.length) d.items=keep; if(JSON.stringify(t.free)!==JSON.stringify(DEFAULTS.free)) d.free=t.free; if(Object.keys(d).length) write(TAB_KEY,d); }

  /* ---- the dock's own state ---- */
  function blank(){ return {v:1, reach:0, upgrades:{exchange:0, starter:0, insurance:0, scanner:0}, stock:null, bounties:[], rot:{pre:0, items:0}, restocks:0, log:[], heroes:{}}; }
  function state(){ var s=read(KEY,null)||blank(); s.upgrades=s.upgrades||{}; UPGRADES.forEach(function(u){ s.upgrades[u.id]=parseInt(s.upgrades[u.id],10)||0; }); s.rot=s.rot||{pre:0,items:0}; s.bounties=s.bounties||[]; s.log=s.log||[]; s.reach=+s.reach||0;
    if(!s.heroes || typeof s.heroes!=="object" || Array.isArray(s.heroes)) s.heroes={}; return s; }
  function save(s){ return write(KEY,s); }
  function reset(){ try{ localStorage.removeItem(KEY); localStorage.removeItem(INV_KEY); }catch(e){} }
  function note(s,text){ s.log.unshift({t:new Date().toISOString(), text:text}); s.log=s.log.slice(0,40); }
  function closed(){ return !!(D() && D().active()); }
  var CLOSED="The dock is closed while a Strike Team is out";
  /* the rarest component within reach: Skull N reaches the Nth rarity */
  function reachRarity(s){ s=s||state(); return Math.max(0, Math.min(5, (s.reach||1)-1)); }

  /* ---- what the dock holds for you: Consumables, Prototypes, pre-built copies ---- */
  function inv(){ var v=read(INV_KEY,null)||{}; v.cards=v.cards||{}; v.pre=v.pre||{}; return v; }
  function saveInv(v){ return write(INV_KEY,v); }
  function owned(name){ return inv().cards[name]||0; }
  function addCard(name, n){ var v=inv(); v.cards[name]=Math.max(0,(v.cards[name]||0)+n); if(!v.cards[name]) delete v.cards[name]; saveInv(v); return v.cards[name]||0; }
  function waiting(){ return inv().pre; }
  function cardOf(name){ return cards().filter(function(c){ return c.name===name; })[0]||null; }
  function itemKind(name){ var c=cardOf(name); return c?c.cardType:""; }

  /* ---- pre-built Troops: yours to make in Dev Mode, cycled in order ---- */
  function prebuilts(){ return WS()&&WS().prebuilts ? WS().prebuilts() : []; }
  function preCost(d, t){
    t=t||tables(); var parts=WS().cost(d).parts, sh=0;
    parts.forEach(function(n,r){ sh+=n*t.price[r]; });
    return Math.max(1, Math.round(sh*t.preMult));
  }
  function bpPrice(it, t){
    t=t||tables(); var o=P().parseItem(it); if(!o) return 0;
    if(o.kind==="ch") return t.chassis;
    return o.level<=1 ? t.bpFirst : Math.round(P().researchPrice(o.name,o.level)*t.bpLater);
  }

  /* ---- restocking ---- */
  function cycle(list, from, n){ var out=[]; if(!list.length) return out; for(var i=0;i<Math.min(n,list.length);i++) out.push(list[(from+i)%list.length]); return out; }
  function districtsFought(){ var s=P().state(); return Object.keys(s.seen.district||{}).filter(function(d){ return d; }); }
  function restock(opts){
    opts=opts||{}; var s=state(), t=tables(), up=s.upgrades.exchange, extra=up?t.effect.exchange[up-1]:0;
    var top=reachRarity(s), lots=[];
    /* each lot a different part type or rarity, while there are enough to go round */
    var kinds=[]; for(var r0=1;r0<=top;r0++) L().TYPES.forEach(function(ty){ kinds.push({type:ty.id, rarity:r0}); });
    for(var i=0;i<t.lots+extra && kinds.length;i++){
      var k=kinds.splice(Math.floor(rnd()*kinds.length),1)[0];
      lots.push({type:k.type, rarity:k.rarity, n:1+Math.floor(rnd()*Math.max(1,t.lotMax)), bought:0});
    }
    lots.sort(function(a,b){ return a.rarity-b.rarity || L().TYPES.map(function(x){ return x.id; }).indexOf(a.type)-L().TYPES.map(function(x){ return x.id; }).indexOf(b.type); });
    /* blueprints and chassis: the pools of Districts fought in, only what could come next */
    var pool=[], seen={};
    districtsFought().forEach(function(d){ P().poolItems(d).forEach(function(it){ if(!seen[it]){ seen[it]=1; pool.push(it); } }); });
    var bp=pool.filter(function(it){ return /^bp:/.test(it) && P().eligible(it); }), ch=pool.filter(function(it){ return /^ch:/.test(it) && P().eligible(it); });
    var pick=function(list,n){ list=list.slice(); var out=[]; while(out.length<n && list.length) out.push(list.splice(Math.floor(rnd()*list.length),1)[0]); return out; };
    var pre=prebuilts(), items=t.items;
    if(s.stock && !opts.first){ s.rot.pre=pre.length?(s.rot.pre+(s.stock.pre||[]).length)%pre.length:0; s.rot.items=items.length?(s.rot.items+(s.stock.items||[]).length)%items.length:0; }
    s.stock={n:s.restocks+1, made:new Date().toISOString(), lots:lots, bps:pick(bp,t.bpOffers), chs:pick(ch,t.chOffers),
      items:cycle(items.map(function(x){ return x.name; }), s.rot.items, t.itemsOnOffer),
      pre:cycle(pre.map(function(d){ return d.id; }), s.rot.pre, t.preOnOffer+extra), sold:{}};
    s.restocks++;
    s.bounties=postBounties();
    s.stock.heroes=pickHeroes(s, t.heroOnOffer+extra); s.stock.hired={};
    note(s, "The Exchange restocked; the Bounty Board changed.");
    save(s); return s.stock;
  }
  /* a stock from before recruiting gets its Heroes the first time it is looked at */
  function stock(){ var s=state(); if(!s.stock){ restock({first:true}); s=state(); }
    if(!Array.isArray(s.stock.heroes)){ var t=tables(), up=s.upgrades.exchange; s.stock.heroes=pickHeroes(s, t.heroOnOffer+(up?t.effect.exchange[up-1]:0)); s.stock.hired={}; save(s); }
    return s.stock; }
  /* seeing a blueprint or chassis on the shelf names it */
  function seeStock(){ var st=stock(); st.bps.concat(st.chs).forEach(function(it){ P().name(it); }); }

  /* ---- buying and selling ---- */
  function pay(shards){ var st=L().stock(); if(st.shards<shards) return false; st.shards-=shards; L().setStock(st); return true; }
  function logStock(why, b){ try{ var h=JSON.parse(localStorage.getItem("keter-app-stockpile-log")||"[]"); h.unshift({t:new Date().toISOString(), why:why, bag:b}); localStorage.setItem("keter-app-stockpile-log",JSON.stringify(h.slice(0,30))); }catch(e){} }
  function spent(price){ var b=L().bag(); b.shards=-price; return b; }
  function short(price){ return {ok:false, why:"Needs "+price+" shards; you have "+L().stock().shards}; }
  /* components: Commons any amount; a lot's rarer ones up to what it holds */
  function buyParts(type, rarity, n, lotIndex){
    if(closed()) return {ok:false, why:CLOSED};
    var t=tables(), s=state(), st=stock(); n=Math.max(1,parseInt(n,10)||1); rarity=+rarity||0;
    if(rarity>0){
      var lot=st.lots[lotIndex]; if(!lot || lot.type!==type || lot.rarity!==rarity) return {ok:false, why:"Not in stock"};
      if(lot.bought+n>lot.n) return {ok:false, why:"Only "+(lot.n-lot.bought)+" left in that lot"};
    }
    var price=t.price[rarity]*n; if(!pay(price)) return short(price);
    var st2=L().stock(); st2.parts[type][rarity]+=n; L().setStock(st2);
    var b=L().bag(); b.shards=-price; b.parts[type][rarity]=n; logStock("Bought at the Exchange", b);
    if(rarity>0){ s=state(); s.stock.lots[lotIndex].bought+=n; save(s); }
    return {ok:true, price:price};
  }
  function sellParts(type, rarity, n){
    if(closed()) return {ok:false, why:CLOSED};
    var t=tables(), st=L().stock(); n=Math.max(1,parseInt(n,10)||1);
    if((st.parts[type]||[])[rarity]<n) return {ok:false, why:"You don't have that many"};
    var gain=Math.floor(t.price[rarity]*t.sell)*n;
    st.parts[type][rarity]-=n; st.shards+=gain; L().setStock(st);
    var b=L().bag(); b.shards=gain; b.parts[type][rarity]=-n; logStock("Sold at the Exchange", b);
    return {ok:true, gain:gain};
  }
  function buyItem(it){
    if(closed()) return {ok:false, why:CLOSED};
    var st=stock(); if(st.bps.indexOf(it)<0 && st.chs.indexOf(it)<0) return {ok:false, why:"Not in stock"};
    if(!P().eligible(it)) return {ok:false, why:"You can't use that one yet"};
    var price=bpPrice(it); if(!pay(price)) return short(price);
    P().grant(it); P().name(it);
    var s=state(); s.stock.sold[it]=1; save(s);
    logStock("Bought "+P().itemName(it,true), (function(){ var b=L().bag(); b.shards=-price; return b; })());
    return {ok:true, price:price};
  }
  function itemPrice(name){ var x=tables().items.filter(function(i){ return i.name===name; })[0]; return x?x.price:0; }
  function buyCard(name, n){
    if(closed()) return {ok:false, why:CLOSED};
    n=Math.max(1,parseInt(n,10)||1); if(stock().items.indexOf(name)<0) return {ok:false, why:"Not in stock"};
    var price=itemPrice(name)*n; if(!pay(price)) return short(price);
    addCard(name,n); logStock("Bought "+n+" × "+name, spent(price)); return {ok:true, price:price};
  }
  function sellCard(name, n){
    if(closed()) return {ok:false, why:CLOSED};
    n=Math.max(1,parseInt(n,10)||1); if(owned(name)<n) return {ok:false, why:"You don't have that many"};
    var gain=Math.floor((itemPrice(name)||num((cardOf(name)||{}).price,10))*tables().sell)*n;
    addCard(name,-n); var st=L().stock(); st.shards+=gain; L().setStock(st);
    logStock("Sold "+n+" × "+name, spent(-gain)); return {ok:true, gain:gain};
  }
  function buyPre(id, n){
    if(closed()) return {ok:false, why:CLOSED};
    n=Math.max(1,parseInt(n,10)||1); if(stock().pre.indexOf(id)<0) return {ok:false, why:"Not in stock"};
    var d=WS().get(id); if(!d) return {ok:false, why:"That design is gone"};
    var price=preCost(d)*n; if(!pay(price)) return short(price);
    var v=inv(); v.pre[id]=(v.pre[id]||0)+n; saveInv(v);
    logStock("Bought "+n+" pre-built "+d.name, spent(price)); return {ok:true, price:price};
  }

  /* ---- recruiting Heroes (v14.14) ---- */
  /* every Hero card, once by name (the Workshop's designs and pre-builts are Troops) */
  function heroCards(){ var seen={}; return cards().filter(function(c){ if(!c || c.cardType!=="hero" || c._src==="design" || c._src==="prebuilt" || seen[c.name]) return false; seen[c.name]=1; return true; }); }
  function isFree(name, t){ return (t||tables()).free.indexOf(name)>=0; }
  function isTestHero(c){ return /^Test /.test(String(c&&c.name||"")); }
  /* a Hero's District: none, or one fought in, puts it on offer */
  function heroDistrict(c){ var d=P().enemyDistrict(c); return (d==="any"||d==="neu")?"":d; }
  function owns(name){ return isFree(name) || !!state().heroes[name]; }
  function ownedHeroes(){ return Object.keys(state().heroes); }
  function heroRarity(c){ var r=String(c&&c.rarity||"").toLowerCase(), i=L().RARITIES.map(function(x){ return x.id; }).indexOf(r); return i<0?0:i; }
  function heroPrice(name, t){ t=t||tables(); var c=cardOf(name); return c?t.heroPrice[heroRarity(c)]:0; }
  function recruitable(s){
    s=s||state(); var t=tables(), fought=districtsFought();
    return heroCards().filter(function(c){ var d=heroDistrict(c); return !isFree(c.name,t) && !isTestHero(c) && !s.heroes[c.name] && (!d || fought.indexOf(d)>=0); });
  }
  function pickHeroes(s, n){ var list=recruitable(s).map(function(c){ return c.name; }), out=[]; while(out.length<n && list.length) out.push(list.splice(Math.floor(rnd()*list.length),1)[0]); return out; }
  function recruit(name){
    if(closed()) return {ok:false, why:CLOSED};
    var st=stock(); if(st.heroes.indexOf(name)<0) return {ok:false, why:"Not on offer"};
    if(owns(name)) return {ok:false, why:"Already yours"};
    if(!cardOf(name)) return {ok:false, why:"That Hero is gone"};
    var price=heroPrice(name); if(!pay(price)) return short(price);
    var s=state(); s.heroes[name]=1; s.stock.hired[name]=1; note(s, name+" recruited."); save(s);
    logStock("Recruited "+name, spent(price)); return {ok:true, price:price};
  }
  /* the team's Heroes that aren't yours: it can't leave with them */
  function unowned(names){ return (names||[]).filter(function(n){ return !owns(n); }); }

  /* ---- Reclaiming ---- */
  function combine(type, rarity, times){
    if(closed()) return {ok:false, why:CLOSED};
    var t=tables(), st=L().stock(), top=reachRarity(); rarity=+rarity; times=Math.max(1,parseInt(times,10)||1);
    if(rarity+1>top) return {ok:false, why:"Nothing rarer than your reach: bring a haul home from further out first"};
    var need=t.reclaimUp*times; if((st.parts[type]||[])[rarity]<need) return {ok:false, why:"Needs "+need+" of them"};
    st.parts[type][rarity]-=need; st.parts[type][rarity+1]+=times; L().setStock(st);
    var b=L().bag(); b.parts[type][rarity]=-need; b.parts[type][rarity+1]=times; logStock("Reclaimed", b);
    return {ok:true, made:times};
  }
  function swap(from, to, rarity, times){
    if(closed()) return {ok:false, why:CLOSED};
    var t=tables(), st=L().stock(); rarity=+rarity; times=Math.max(1,parseInt(times,10)||1);
    if(from===to) return {ok:false, why:"Pick another type"};
    var need=t.reclaimSwap*times; if((st.parts[from]||[])[rarity]<need) return {ok:false, why:"Needs "+need+" of them"};
    st.parts[from][rarity]-=need; st.parts[to][rarity]+=times; L().setStock(st);
    var b=L().bag(); b.parts[from][rarity]=-need; b.parts[to][rarity]=times; logStock("Reclaimed", b);
    return {ok:true, made:times};
  }

  /* ---- the Bounty Board ---- */
  function foes(){ var s={}; return cards().filter(function(c){ if(!P().isFoe(c)||s[c.name]) return false; s[c.name]=1; return true; }); }
  function postBounties(){
    var fought=districtsFought(), met=foes().filter(function(c){ var d=P().enemyDistrict(c); return P().state().seen.enemy[c.name] && (!d || fought.indexOf(d)>=0); });
    var pick=function(list,n){ list=list.slice(); var out=[]; while(out.length<n && list.length) out.push(list.splice(Math.floor(rnd()*list.length),1)[0]); return out; };
    var small=pick(met.filter(function(c){ return c.cardType==="enemy"; }),2), big=pick(met.filter(function(c){ return c.cardType!=="enemy"; }),1);
    return small.concat(big).map(function(c){ return {name:c.name, kind:c.cardType, district:P().enemyDistrict(c), claimed:false}; });
  }
  function bounties(){ return state().bounties; }
  function bountyPay(kind, skull, t){
    t=t||tables(); skull=Math.max(1,Math.min(6,+skull||1));
    return {shards:(t.bounty.shards[kind]||0)*skull, lines:[{kind:"roll", n:t.bounty.n[kind]||0, type:"any", bonus:0}]};
  }
  /* a deployment home: its kills claim what they match */
  function claim(kills){
    var s=state(), paid=[], X=L();
    s.bounties.forEach(function(b){
      if(b.claimed) return; var k=(kills||[]).filter(function(x){ return x.name===b.name; }).sort(function(a,c){ return c.skull-a.skull; })[0];
      if(!k) return;
      var bag=X.rollReward(bountyPay(b.kind,k.skull), k.skull);
      X.addToStock(bag, "Bounty: "+b.name); b.claimed=true; b.paid=bag; b.skull=k.skull; paid.push({name:b.name, bag:bag});
    });
    if(paid.length){ note(s, paid.length+" bount"+(paid.length===1?"y":"ies")+" paid."); save(s); }
    return paid;
  }

  /* ---- upgrades ---- */
  function level(id){ return state().upgrades[id]||0; }
  function effect(id){ var l=level(id); return l?tables().effect[id][l-1]:0; }
  function nextCost(id){ var l=level(id); if(l>=3) return null; var c=tables().cost[id][l]; return {shards:c[0], type:c[1], rarity:c[2], n:c[3]}; }
  function upgrade(id){
    if(closed()) return {ok:false, why:CLOSED};
    var c=nextCost(id); if(!c) return {ok:false, why:"Already at its highest level"};
    var st=L().stock();
    if(st.shards<c.shards || (st.parts[c.type]||[])[c.rarity]<c.n) return {ok:false, why:"Needs "+c.shards+" shards and "+c.n+" "+L().RARITIES[c.rarity].label+" "+c.type+" parts"};
    st.shards-=c.shards; st.parts[c.type][c.rarity]-=c.n; L().setStock(st);
    var b=L().bag(); b.shards=-c.shards; b.parts[c.type][c.rarity]=-c.n;
    var s=state(); s.upgrades[id]++; note(s, UPGRADES.filter(function(u){ return u.id===id; })[0].name+" raised to level "+s.upgrades[id]+"."); save(s);
    logStock("Dock upgrade", b);
    return {ok:true, level:s.upgrades[id]};
  }
  /* the effects the rest of the game asks for */
  function starterFree(){ var base=W()?W().tables().starterFree:4; var e=effect("starter"); return e?Math.max(base,e):base; }
  function scanRange(){ return Math.max(1, effect("scanner")||1); }
  function insurance(){ return effect("insurance"); }

  /* ---- a deployment ends: reach, restock, bounties, insurance ---- */
  function deploymentEnded(o){
    o=o||{}; var s=state(), out={};
    if(o.result==="home" && +o.maxSkull>s.reach){ s.reach=Math.min(6,+o.maxSkull); out.reach=s.reach; note(s, "Reach extended to Skull Level "+s.reach+"."); }
    /* (v14.14) a wipe loses the recruited Heroes who went out with it; the free ones come back */
    if(o.result==="wipe" && Array.isArray(o.heroes)){
      var lost=o.heroes.filter(function(n){ return s.heroes[n]; });
      lost.forEach(function(n){ delete s.heroes[n]; });
      if(lost.length){ out.lostHeroes=lost; note(s, "Lost with the wipe: "+lost.join(", ")+"."); }
    }
    save(s);
    if(o.result==="home") out.bounties=claim(o.kills||[]);
    if(o.result==="wipe" && insurance() && o.haul){
      var pc=insurance()/100, X=L(), h=X.norm(o.haul), kept=X.bag();
      kept.shards=Math.floor(h.shards*pc); X.TYPES.forEach(function(ty){ h.parts[ty.id].forEach(function(n,r){ kept.parts[ty.id][r]=Math.floor(n*pc); }); });
      if(!X.isEmpty(kept)){ X.addToStock(kept, "Salvage insurance"); out.insured=kept; }
    }
    if(o.explored) { restock(); out.restocked=true; }
    return out;
  }

  window.KETER_DOCK={KEY:KEY, INV_KEY:INV_KEY, TAB_KEY:TAB_KEY, DEFAULTS:DEFAULTS, UPGRADES:UPGRADES, KIND_LABEL:KIND_LABEL, CLOSED:CLOSED,
    tables:tables, saveTables:saveTables, resetTables:resetTables, state:state, reset:reset, closed:closed, reachRarity:reachRarity,
    inv:inv, owned:owned, addCard:addCard, waiting:waiting, cardOf:cardOf, itemKind:itemKind, prebuilts:prebuilts, preCost:preCost, bpPrice:bpPrice, itemPrice:itemPrice,
    restock:restock, stock:stock, seeStock:seeStock, buyParts:buyParts, sellParts:sellParts, buyItem:buyItem, buyCard:buyCard, sellCard:sellCard, buyPre:buyPre,
    combine:combine, swap:swap, bounties:bounties, bountyPay:bountyPay, claim:claim, postBounties:postBounties,
    level:level, effect:effect, nextCost:nextCost, upgrade:upgrade, starterFree:starterFree, scanRange:scanRange, insurance:insurance,
    deploymentEnded:deploymentEnded, _save:save, _saveInv:saveInv,
    heroCards:heroCards, isFree:isFree, owns:owns, ownedHeroes:ownedHeroes, heroRarity:heroRarity, heroPrice:heroPrice, recruitable:recruitable, recruit:recruit, unowned:unowned, heroDistrict:heroDistrict};
})();
