/* ===========================================================================
   The Dock page (v12.9): the Exchange, Reclaiming, the Bounty Board, the
   dock's upgrades, and the stockpile; and (v14.14) Recruit, the Heroes on
   offer, the free ones and the ones you have. Dev Mode adds the dock's tables, the
   Consumables and Prototypes the Exchange carries, and a restock button.
   (v14.19) Craft: the stash (the cards a deployment takes, held at the dock)
   and crafting for it; a new run's pick of a rare card, the first time the
   dock is opened.
   =========================================================================== */
(function(){
  "use strict";
  var K=function(){ return window.KETER_DOCK; }, L=function(){ return window.KETER_LOOT; };
  var P=function(){ return window.KETER_PROG; }, WS=function(){ return window.KETER_WORKSHOP; }, D=function(){ return window.KETER_DEPLOY; };
  var HOST=null, TAB="exchange", MSG="", QTY={};
  function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
  function $(id){ return document.getElementById(id); }
  function dev(){ return !!(P() && P().dev()); }
  function fmt(n){ return String(n).replace(/\B(?=(\d{3})+(?!\d))/g,","); }
  function rar(r){ var R=L().RARITIES[r]; return '<span style="color:'+R.lite+'">'+R.label+'</span>'; }
  function tyShort(id){ return (L().TYPES.filter(function(t){ return t.id===id; })[0]||{}).short||id; }
  function pname(ty,r){ return L().nameOf(ty,r); }
  function plain(t){ return String(t||"").replace(/\[\[\s*([^\]]+?)\s*\]\]/g,"$1"); }
  function cardText(c){ var raw=(c&&c._raw)||{}; return plain((raw.abilities||c&&c.entries||c&&c.abilities||[]).map(function(a){ return a.text; }).filter(Boolean).join(" ")); }

  function render(host){ HOST=host||HOST||$("v-dock"); if(!HOST) return; draw(); }
  /* (v14.19) a run's stash begins the first time the dock is opened: a new run with the starter
     stash and a rare card to pick; a run with deployments behind it with what its Strike Teams need */
  function beginStash(){
    var X=K(); if(!X.beginStash || X.state().stash) return;
    var old=!!(D() && (D().history().length || D().active())), all=window.KETER_ALLCARDS?window.KETER_ALLCARDS():[];
    X.beginStash(old, old&&D()?D().loadouts().map(function(l){ return D().needOf(l, all); }):[]);
  }
  function rareHTML(){
    var X=K(), s=X.state(), off=(s.stash&&!s.stash.picked&&s.stash.offer)||[]; if(!off.length) return '';
    return '<div class="wldbox"><p><b>Pick a rare card</b></p><p class="pxnote">A new run: the stash holds a starter set of cards, and one rare card of your choice besides.</p><div class="dklist">'+off.map(function(nm){
      var c=X.cardOf(nm)||{};
      return '<div class="dkrow"><span><b>'+esc(nm)+'</b><i>'+esc(c.cardType||"")+' · '+esc(cardText(c).slice(0,140))+'</i></span>'+btn('data-dkrare="'+esc(nm)+'"',"Pick",false,true)+'</div>';
    }).join("")+'</div></div>';
  }
  var CRAFT_KINDS=[["equipment","Equipment"],["command","Command"],["aether","Aether"],["action","Action"],["sphere","Chips"]];
  function craftHTML(){
    var X=K(), t=X.tables(), st=L().stock(), closed=X.closed(), v=X.inv().cards, all=window.KETER_ALLCARDS?window.KETER_ALLCARDS():[];
    var held=Object.keys(v).filter(function(n){ return v[n]>0 && X.isLimited(X.cardOf(n)); }).sort();
    var h='<p class="pxsub">The stash</p><p class="pxnote">The Uncommon and rarer Equipment, Command and Aether cards, Action cards and Chips a deployment takes come from here, or are crafted as it leaves; Common cards are free. They go out with the team and come home with it; a wipe loses them.</p>'+
      (held.length?'<p>'+held.map(function(n){ return esc(n)+' ×'+v[n]; }).join(" · ")+'</p>':'<p class="pxnote">The stash is empty.</p>')+
      '<p class="pxsub">Craft</p><p class="pxnote">From shards and parts of the card’s rarity: Equipment from Equipment parts, Aether cards and Chips from Aether parts; Command and Action cards, which have no part type, cost '+t.craft.noParts+'× the shards.</p>';
    CRAFT_KINDS.forEach(function(k){
      var seen={}, cs=all.filter(function(c){ if(c.cardType!==k[0] || !X.isLimited(c) || c._src==="design" || c._src==="prebuilt" || seen[c.name] || (/^Test /.test(c.name) && !(v[c.name]>0))) return false; seen[c.name]=1; return true; })
        .sort(function(a,b){ return X.heroRarity(a)-X.heroRarity(b) || (a.name<b.name?-1:a.name>b.name?1:0); });
      if(!cs.length) return;
      h+='<p class="pxsub">'+k[1]+'</p><div class="dklist">'+cs.map(function(c){
        var cc=X.craftCost(c.name), can=!closed && st.shards>=cc.shards && (!cc.type || st.parts[cc.type][cc.rarity]>=cc.n);
        return '<div class="dkrow"><span><b>'+esc(c.name)+'</b><i>'+rar(cc.rarity)+' · held '+(v[c.name]||0)+' · '+esc(X.craftText(cc.shards, cc.type, cc.rarity, cc.n))+'</i></span>'+btn('data-dkcraft="'+esc(c.name)+'"',"Craft",!can)+'</div>';
      }).join("")+'</div>';
    });
    return h;
  }
  function draw(){
    var tab=function(k,l){ return '<button class="'+(TAB===k?"on":"")+'" data-dktab="'+k+'">'+l+'</button>'; };
    beginStash();
    var X=K(), s=X.state(), st=L().stock(), closed=X.closed(), reachR=X.reachRarity(s);
    HOST.innerHTML='<div class="lts dks">'+
      '<h2 class="pxh">Dock</h2>'+
      '<p class="pxnote">Home base between deployments: trade at the Exchange, reclaim parts, take bounties and improve the dock.</p>'+
      (closed?'<p class="wslockbar">The dock is closed while a Strike Team is out. You can look, but trading, reclaiming, upgrades and research wait until it’s home.</p>':'')+
      '<div class="dkstat"><b>'+fmt(st.shards)+'</b> shards · '+fmt(L().count(st))+' components · reach: '+(s.reach?'Skull '+s.reach+' ('+rar(reachR)+' at most)':'none yet — Commons only')+'</div>'+
      '<div class="pxrow"><button class="ghost" data-page="world">World Map</button><button class="ghost" data-page="workshop">Workshop</button><button class="ghost" data-page="loot">Stockpile</button></div>'+
      (MSG?'<p class="wsmsg">'+MSG+'</p>':'')+rareHTML()+
      '<div class="seg pxseg">'+tab("exchange","Exchange")+tab("recruit","Recruit")+tab("craft","Craft")+tab("reclaim","Reclaim")+tab("bounties","Bounties")+tab("upgrades","Upgrades")+'</div>'+
      '<div id="dkBody">'+(TAB==="exchange"?exchangeHTML():TAB==="recruit"?recruitHTML():TAB==="craft"?craftHTML():TAB==="reclaim"?reclaimHTML():TAB==="bounties"?bountyHTML():upgradesHTML())+'</div>'+
      (dev()?devHTML():'')+'</div>';
  }
  function btn(attr, label, disabled, primary){ return '<button class="ghost'+(primary&&!disabled?" primary":"")+'" '+attr+(disabled?" disabled":"")+'>'+label+'</button>'; }
  function qty(key){ return '<input type="number" class="ltin dkq" min="1" value="'+(QTY[key]||1)+'" data-dkq="'+esc(key)+'" aria-label="How many">'; }

  /* ---- the Exchange ---- */
  function exchangeHTML(){
    var X=K(), t=X.tables(), stk=X.stock(), st=L().stock(), closed=X.closed(), h='';
    X.seeStock();
    h+='<p class="pxnote">It restocks after a deployment that reveals new ground.'+(dev()?' <i>(Stock '+stk.n+'.)</i>':'')+'</p>';
    /* components */
    h+='<p class="pxsub">Components</p><div class="dklist">'+L().TYPES.map(function(ty){
      return '<div class="dkrow"><span><b>'+esc(pname(ty.id,0))+'</b><i>'+rar(0)+' '+esc(ty.short)+' · '+t.price[0]+' shards each · any amount</i></span>'+qty("c:"+ty.id)+btn('data-dkbuyc="'+ty.id+'"',"Buy",closed,true)+'</div>';
    }).join("")+stk.lots.map(function(lot,i){
      var left=lot.n-lot.bought;
      return '<div class="dkrow"><span><b>'+esc(pname(lot.type,lot.rarity))+'</b><i>'+rar(lot.rarity)+' '+esc(tyShort(lot.type))+' · '+t.price[lot.rarity]+' shards each · '+(left?left+' left':'sold out')+'</i></span>'+
        btn('data-dkbuylot="'+i+'"',"Buy 1",closed||!left,true)+'</div>';
    }).join("")+'</div>';
    if(!stk.lots.length) h+='<p class="pxnote">Rarer components come in once a haul has come home from Skull Level 2 or further.</p>';
    /* blueprints and chassis */
    var its=stk.bps.concat(stk.chs);
    h+='<p class="pxsub">Blueprints and chassis</p>'+(its.length?'<div class="dklist">'+its.map(function(it){
      var sold=stk.sold[it], ok=P().eligible(it), price=X.bpPrice(it);
      return '<div class="dkrow"><span><b>'+esc(P().itemName(it,true))+'</b><i>'+(/^ch:/.test(it)?"Chassis":"Blueprint")+' · '+price+' shards'+(sold?' · sold':(!ok?' · no use to you now':''))+'</i></span>'+
        btn('data-dkbuyit="'+esc(it)+'"',sold?"Sold":"Buy",closed||sold||!ok,true)+'</div>';
    }).join("")+'</div>':'<p class="pxnote">None on offer. They come from the pools of Districts you have fought in.</p>');
    /* Consumables and Prototypes */
    h+='<p class="pxsub">Consumables and Prototypes</p>'+(stk.items.length?'<div class="dklist">'+stk.items.map(function(nm){
      var c=X.cardOf(nm), kind=c&&c.cardType==="prototype"?"Prototype":"Consumable";
      return '<div class="dkrow"><span><b>'+esc(nm)+'</b><i>'+kind+' · '+X.itemPrice(nm)+' shards · you have '+X.owned(nm)+'</i>'+(cardText(c)?'<i class="dktext">'+esc(cardText(c))+'</i>':'')+'</span>'+qty("i:"+nm)+btn('data-dkbuycard="'+esc(nm)+'"',"Buy",closed,true)+'</div>';
    }).join("")+'</div>':'<p class="pxnote">None on offer'+(t.items.length?'.':': the Exchange carries only what Dev Mode gives it.')+'</p>');
    /* pre-built Troops */
    h+='<p class="pxsub">Pre-built Troops</p><p class="pxnote">Finished designs you can’t make yet. Copies go on your next deployment only, on top of its Deck, and are gone when it ends.</p>'+
      (stk.pre.length?'<div class="dklist">'+stk.pre.map(function(id){
        var d=WS().get(id); if(!d) return ''; var ch=WS().chassisOf(d)||{}, c=WS().toCard(d), wait=X.waiting()[id]||0;
        return '<div class="dkrow dkpre"><span><b>'+esc(d.name)+'</b><i>'+esc(ch.name||"")+' · power '+WS().power(d)+' · '+X.preCost(d)+' shards a copy'+(wait?' · '+wait+' waiting':'')+'</i>'+
          (c.entries||[]).map(function(e){ return '<i class="dktext"><b>'+esc(e.name)+'</b> '+esc(plain(e.text))+'</i>'; }).join("")+'</span>'+qty("p:"+id)+btn('data-dkbuypre="'+esc(id)+'"',"Buy copies",closed,true)+'</div>';
      }).join("")+'</div>':'<p class="pxnote">None on offer yet.</p>');
    /* selling */
    var mine=[]; L().TYPES.forEach(function(ty){ st.parts[ty.id].forEach(function(n,r){ if(n>0) mine.push({ty:ty.id, r:r, n:n}); }); });
    var cardsOwned=Object.keys(X.inv().cards).filter(function(n){ var k=X.itemKind(n); return X.inv().cards[n]>0 && (k==="consumable" || k==="prototype"); });
    h+='<p class="pxsub">Sell</p><p class="pxnote">The Exchange pays half its price. Blueprints and chassis aren’t bought back.</p>'+
      (mine.length||cardsOwned.length?'<div class="dklist">'+mine.map(function(m){
        return '<div class="dkrow"><span><b>'+esc(pname(m.ty,m.r))+' ×'+m.n+'</b><i>'+rar(m.r)+' '+esc(tyShort(m.ty))+' · '+Math.floor(t.price[m.r]*t.sell)+' shards each</i></span>'+qty("s:"+m.ty+":"+m.r)+btn('data-dksell="'+m.ty+':'+m.r+'"',"Sell",closed)+'</div>';
      }).join("")+cardsOwned.map(function(nm){
        return '<div class="dkrow"><span><b>'+esc(nm)+' ×'+X.owned(nm)+'</b><i>'+Math.floor((X.itemPrice(nm)||10)*t.sell)+' shards each</i></span>'+qty("sc:"+nm)+btn('data-dksellcard="'+esc(nm)+'"',"Sell",closed)+'</div>';
      }).join("")+'</div>':'<p class="pxnote">Nothing to sell.</p>');
    return h;
  }

  /* ---- Recruit (v14.14) ---- */
  function heroStats(c){ var st=c.stats||{}, out=[];
    [["hp","HP"],["ac","AC"],["move","Move"],["slots","Action Slots"],["ldr","Leadership"]].forEach(function(k){ if(st[k[0]]!=null && st[k[0]]!=="") out.push(k[1]+" "+st[k[0]]); }); return out.join(" · "); }
  function heroRow(c, right, extra){
    var X=K(), d=X.heroDistrict(c), R=L().RARITIES[X.heroRarity(c)];
    return '<div class="dkrow dkpre"><span><b>'+esc(c.name)+'</b><i><span style="color:'+R.lite+'">'+R.label+'</span>'+(d?' · District '+esc(d):' · any District')+((c.combatRoles||[]).length?' · '+esc((c.combatRoles||[]).join(", ")):'')+'</i>'+
      '<i>'+esc(heroStats(c))+'</i>'+(c.entries||[]).map(function(e){ return '<i class="dktext"><b>'+esc(e.name||e.kind)+'</b> '+esc(plain(e.text))+'</i>'; }).join("")+(extra||'')+'</span>'+right+'</div>';
  }
  function recruitHTML(){
    var X=K(), t=X.tables(), stk=X.stock(), closed=X.closed(), h='', mine=X.ownedHeroes();
    h+='<p class="pxnote">Heroes to lead your Strike Teams. A recruited Hero is yours until a team it goes out with is wiped out. The free Heroes are always yours. The roster changes when the Exchange restocks.</p>';
    h+='<p class="pxsub">On offer</p>'+(stk.heroes.length?'<div class="dklist">'+stk.heroes.map(function(nm){
      var c=X.cardOf(nm); if(!c) return ''; var hired=stk.hired&&stk.hired[nm], have=X.owns(nm);
      return heroRow(c, btn('data-dkhire="'+esc(nm)+'"', hired||have?"Recruited":"Recruit · "+X.heroPrice(nm)+" shards", closed||hired||have, true));
    }).join("")+'</div>':'<p class="pxnote">Nobody on offer. Heroes come from the Districts your teams have fought in.</p>');
    var free=X.heroCards().filter(function(c){ return X.isFree(c.name,t); });
    h+='<p class="pxsub">Free Heroes</p>'+(free.length?'<div class="dklist">'+free.map(function(c){ return heroRow(c,'<i class="wldok">Always yours</i>'); }).join("")+'</div>':'<p class="pxnote">None: Dev Mode lists them.</p>');
    h+='<p class="pxsub">Recruited</p>'+(mine.length?'<div class="dklist">'+mine.map(function(nm){ var c=X.cardOf(nm); return c?heroRow(c,'<i class="wldok">Yours</i>'):''; }).join("")+'</div>':'<p class="pxnote">None yet.</p>');
    return h;
  }

  /* ---- Reclaiming ---- */
  function reclaimHTML(){
    var X=K(), t=X.tables(), st=L().stock(), closed=X.closed(), top=X.reachRarity(), h='';
    h+='<p class="pxnote">'+t.reclaimUp+' of a rarity make 1 of the next, same type, never rarer than your reach ('+(X.state().reach?rar(top):'none yet')+'). '+t.reclaimSwap+' of one type make 1 of another, same rarity.</p>';
    var rows=[]; L().TYPES.forEach(function(ty){ for(var r=0;r<5;r++){ var n=st.parts[ty.id][r]; if(n>=t.reclaimUp && r+1<=top) rows.push({ty:ty.id, r:r, n:n}); } });
    h+='<p class="pxsub">Combine</p>'+(rows.length?'<div class="dklist">'+rows.map(function(x){
      return '<div class="dkrow"><span><b>'+t.reclaimUp+' × '+esc(pname(x.ty,x.r))+' → 1 × '+esc(pname(x.ty,x.r+1))+'</b><i>you have '+x.n+' · '+rar(x.r)+' to '+rar(x.r+1)+'</i></span>'+qty("u:"+x.ty+":"+x.r)+btn('data-dkup="'+x.ty+':'+x.r+'"',"Combine",closed,true)+'</div>';
    }).join("")+'</div>':'<p class="pxnote">Nothing to combine: you need '+t.reclaimUp+' of one kind, below your reach.</p>');
    var opt=function(sel){ return L().TYPES.map(function(ty){ return '<option value="'+ty.id+'"'+(ty.id===sel?" selected":"")+'>'+esc(ty.label)+'</option>'; }).join(""); };
    h+='<p class="pxsub">Swap types</p><div class="dkswap"><select id="dkFrom" class="ltsel">'+opt("troop")+'</select><span>→</span><select id="dkTo" class="ltsel">'+opt("equipment")+'</select>'+
      '<select id="dkRar" class="ltsel">'+L().RARITIES.map(function(r,i){ return '<option value="'+i+'">'+r.label+'</option>'; }).join("")+'</select>'+qty("w")+btn('id="dkSwap"',"Swap "+t.reclaimSwap+" for 1",closed,true)+'</div>';
    return h;
  }

  /* ---- the Bounty Board ---- */
  function bountyHTML(){
    var X=K(), t=X.tables(), bs=X.bounties();
    var h='<p class="pxnote">Beat a posted Enemy in a won fight on a deployment. When the Strike Team gets home it pays shards and components by its kind and the Skull Level it fell at; a wipe loses the claim. The board changes when the Exchange restocks.</p>';
    if(!bs.length) return h+'<p class="pxnote">Nothing posted. Bounties name Enemies you have met, in Districts you have fought in.</p>';
    return h+'<div class="dklist">'+bs.map(function(b){
      return '<div class="dkrow dkbounty'+(b.claimed?' dkdone':'')+'"><span><b>'+esc(b.name)+'</b><i>'+esc(X.KIND_LABEL[b.kind]||"Enemy")+(b.district?' · District '+esc(b.district):'')+'</i>'+
        '<i>Pays '+t.bounty.shards[b.kind]+' shards per Skull Level it fell at, and '+t.bounty.n[b.kind]+' component'+(t.bounty.n[b.kind]===1?'':'s')+' rolled at that level</i>'+
        (b.claimed?'<i class="wldok">Claimed: '+esc(L().text(b.paid||L().bag()))+'</i>':'')+'</span></div>';
    }).join("")+'</div>';
  }

  /* ---- upgrades ---- */
  function effectText(id, v){ return id==="starter"?v+" design"+(v===1?"":"s")+" go"+(v===1?"es":"")+" out free":id==="insurance"?v+"% of a wiped haul kept":id==="scanner"?"see "+v+" steps away":"+"+v+" lot"+(v===1?"":"s")+" of rarer parts and +"+v+" pre-built"+(v===1?"":"s")+" and +"+v+" Hero"+(v===1?"":"es")+" on offer"; }
  function upgradesHTML(){
    var X=K(), closed=X.closed();
    return '<div class="dklist">'+X.UPGRADES.map(function(u){
      var lv=X.level(u.id), t=X.tables(), c=X.nextCost(u.id);
      return '<div class="dkrow dkup"><span><b>'+esc(u.name)+' · level '+lv+' of 3</b><i>'+esc(u.what)+'</i>'+
        '<i>Now: '+(lv?effectText(u.id,t.effect[u.id][lv-1]):(u.id==="starter"?"only the starter goes out free":u.id==="scanner"?"see 1 step away":u.id==="insurance"?"nothing kept after a wipe":"the basic stock"))+
        (c?' · next: '+effectText(u.id,t.effect[u.id][lv])+'</i><i>Costs '+c.shards+' shards and '+c.n+' '+L().RARITIES[c.rarity].label+' '+esc(tyShort(c.type))+' parts':'')+'</i></span>'+
        (c?btn('data-dkupg="'+u.id+'"',"Upgrade",closed,true):'<i class="wldok">Done</i>')+'</div>';
    }).join("")+'</div>';
  }

  /* ---- Dev Mode: the dock's tables and what it carries ---- */
  function devHTML(){
    var X=K(), t=X.tables(), n=function(path,val,step){ return '<input type="number" class="ltin" data-dkt="'+path+'" value="'+esc(val)+'" step="'+(step||"1")+'" min="0">'; };
    var all=[]; try{ all=window.KETER_ALLCARDS().filter(function(c){ return c.cardType==="consumable"||c.cardType==="prototype"; }); }catch(e){}
    var seen={}; all=all.filter(function(c){ if(seen[c.name]) return false; seen[c.name]=1; return true; });
    var carried={}; t.items.forEach(function(x){ carried[x.name]=x.price; });
    var heroes=X.heroCards();
    return '<div class="wsdev wlddev"><p class="pxsub">Dev Mode · the dock</p>'+
      '<div class="pxrow"><button class="ghost" id="dkRestock">Restock now</button><button class="ghost" id="dkReach">Reach +1</button><button class="ghost" id="dkReset">Reset the dock</button></div>'+
      '<details class="wldsec"><summary>What the Exchange carries</summary><p class="wldnote">Tick the Consumables and Prototypes it sells, and set each price. It shows a few at a time, in this order.</p>'+
        (all.length?all.map(function(c){ var on=c.name in carried; return '<div class="wldrow wldmini"><label class="wldchk"><input type="checkbox" data-dkitem="'+esc(c.name)+'"'+(on?" checked":"")+'> '+esc(c.name)+' <i>'+esc(c.cardType)+'</i></label>'+(on?'<input type="number" class="ltin" data-dkiprice="'+esc(c.name)+'" value="'+carried[c.name]+'" min="0">':'')+'</div>'; }).join(""):'<p class="wldnote">No Consumable or Prototype cards yet: make some in the Forge.</p>')+
      '</details>'+
      '<details class="wldsec"><summary>Prices and stock</summary><div class="chgrid">'+
        L().RARITIES.map(function(r,i){ return '<label class="chf"><span>'+r.label+' part</span>'+n("price."+i,t.price[i])+'</label>'; }).join("")+
        '<label class="chf"><span>Sell rate</span>'+n("sell",t.sell,"0.05")+'</label><label class="chf"><span>Unfound blueprint</span>'+n("bpFirst",t.bpFirst)+'</label>'+
        '<label class="chf"><span>Later level × research</span>'+n("bpLater",t.bpLater,"0.05")+'</label><label class="chf"><span>Chassis</span>'+n("chassis",t.chassis)+'</label>'+
        '<label class="chf"><span>Pre-built × its parts</span>'+n("preMult",t.preMult,"0.1")+'</label><label class="chf"><span>Rare lots</span>'+n("lots",t.lots)+'</label>'+
        '<label class="chf"><span>Most in a lot</span>'+n("lotMax",t.lotMax)+'</label><label class="chf"><span>Blueprints on offer</span>'+n("bpOffers",t.bpOffers)+'</label>'+
        '<label class="chf"><span>Chassis on offer</span>'+n("chOffers",t.chOffers)+'</label><label class="chf"><span>Consumables etc. on offer</span>'+n("itemsOnOffer",t.itemsOnOffer)+'</label>'+
        '<label class="chf"><span>Pre-builts on offer</span>'+n("preOnOffer",t.preOnOffer)+'</label><label class="chf"><span>Combine: how many</span>'+n("reclaimUp",t.reclaimUp)+'</label>'+
        '<label class="chf"><span>Swap: how many</span>'+n("reclaimSwap",t.reclaimSwap)+'</label></div></details>'+
      '<details class="wldsec"><summary>Recruiting</summary><p class="wldnote">Tick the free Heroes: always yours, never lost. The others are recruited at a price by their rarity.</p>'+
        (heroes.length?heroes.map(function(c){ return '<div class="wldrow wldmini"><label class="wldchk"><input type="checkbox" data-dkfree="'+esc(c.name)+'"'+(X.isFree(c.name,t)?" checked":"")+'> '+esc(c.name)+' <i>'+esc(c.rarity||"common")+'</i></label></div>'; }).join(""):'<p class="wldnote">No Hero cards yet.</p>')+
        '<div class="chgrid">'+L().RARITIES.map(function(r,i){ return '<label class="chf"><span>'+r.label+' Hero</span>'+n("heroPrice."+i,t.heroPrice[i])+'</label>'; }).join("")+
        '<label class="chf"><span>Heroes on offer</span>'+n("heroOnOffer",t.heroOnOffer)+'</label></div>'+
        '<div class="pxrow"><button class="ghost" id="dkHeroesAll">Recruit every Hero</button><button class="ghost" id="dkHeroesNone">Lose every recruited Hero</button></div></details>'+
      '<details class="wldsec"><summary>Crafting and the stash</summary><p class="wldnote">What crafting a card costs, by its rarity: shards, and parts of its kind (Equipment for Equipment cards, Aether for Aether cards and Chips). A Command or Action card costs the shards times the multiplier instead. A new run is offered this many rare cards to pick one from.</p><div class="chgrid">'+
        L().RARITIES.map(function(r,i){ return '<label class="chf"><span>'+r.label+': shards</span>'+n("craft.shards."+i,t.craft.shards[i])+'</label><label class="chf"><span>'+r.label+': parts</span>'+n("craft.parts."+i,t.craft.parts[i])+'</label>'; }).join("")+
        '<label class="chf"><span>No part type: shards ×</span>'+n("craft.noParts",t.craft.noParts,"0.5")+'</label><label class="chf"><span>Rare cards offered</span>'+n("rareOffer",t.rareOffer)+'</label></div></details>'+
      '<details class="wldsec"><summary>Bounties</summary><div class="chgrid">'+Object.keys(X.KIND_LABEL).map(function(k){
        return '<label class="chf"><span>'+X.KIND_LABEL[k]+': shards per Skull</span>'+n("bounty.shards."+k,t.bounty.shards[k])+'</label><label class="chf"><span>'+X.KIND_LABEL[k]+': components</span>'+n("bounty.n."+k,t.bounty.n[k])+'</label>'; }).join("")+'</div></details>'+
      '<details class="wldsec"><summary>Upgrades</summary>'+X.UPGRADES.map(function(u){
        return '<p class="pxsub">'+esc(u.name)+'</p><div class="chgrid">'+[0,1,2].map(function(i){
          var c=t.cost[u.id][i]; return '<label class="chf"><span>Level '+(i+1)+' effect</span>'+n("effect."+u.id+"."+i,t.effect[u.id][i])+'</label>'+
            '<label class="chf"><span>shards</span>'+n("cost."+u.id+"."+i+".0",c[0])+'</label><label class="chf"><span>parts</span>'+n("cost."+u.id+"."+i+".3",c[3])+'</label>'+
            '<label class="chf"><span>rarity (0 Common)</span>'+n("cost."+u.id+"."+i+".2",c[2])+'</label>'; }).join("")+'</div>'; }).join("")+'</details>'+
      '<div class="pxrow"><button class="ghost" id="dkTabReset">Reset the dock’s tables</button></div></div>';
  }

  /* ---- taps ---- */
  function said(r, okText){ MSG=r&&r.ok?okText(r):('<span class="wldbad">'+esc((r&&r.why)||"Couldn’t do that")+'</span>'); draw(); }
  function q(key){ return Math.max(1,parseInt(QTY[key]||1,10)||1); }
  document.addEventListener("click",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var t=e.target.closest?e.target.closest("button"):null; if(!t) return;
    var id=t.id, a, X=K();
    if((a=t.getAttribute("data-dktab"))){ TAB=a; MSG=""; draw(); return; }
    if((a=t.getAttribute("data-dkbuyc"))){ var n=q("c:"+a); said(X.buyParts(a,0,n), function(r){ return "Bought "+n+" × "+esc(pname(a,0))+" for "+r.price+" shards."; }); return; }
    if((a=t.getAttribute("data-dkbuylot"))!==null){ var lot=X.stock().lots[+a]; said(X.buyParts(lot.type,lot.rarity,1,+a), function(r){ return "Bought "+esc(pname(lot.type,lot.rarity))+" for "+r.price+" shards."; }); return; }
    if((a=t.getAttribute("data-dkbuyit"))){ said(X.buyItem(a), function(r){ return "Bought "+esc(P().itemName(a,true))+" for "+r.price+" shards. It’s yours in the Workshop."; }); return; }
    if((a=t.getAttribute("data-dkbuycard"))){ var n2=q("i:"+a); said(X.buyCard(a,n2), function(r){ return "Bought "+n2+" × "+esc(a)+" for "+r.price+" shards."; }); return; }
    if((a=t.getAttribute("data-dkbuypre"))){ var n3=q("p:"+a), d=WS().get(a); said(X.buyPre(a,n3), function(r){ return "Bought "+n3+" "+(n3===1?"copy":"copies")+" of "+esc(d?d.name:"it")+" for "+r.price+" shards. They go on your next deployment."; }); return; }
    if((a=t.getAttribute("data-dksell"))){ var p=a.split(":"), n4=q("s:"+a); said(X.sellParts(p[0],+p[1],n4), function(r){ return "Sold for "+r.gain+" shards."; }); return; }
    if((a=t.getAttribute("data-dksellcard"))){ var n5=q("sc:"+a); said(X.sellCard(a,n5), function(r){ return "Sold for "+r.gain+" shards."; }); return; }
    if((a=t.getAttribute("data-dkup"))){ var p2=a.split(":"), n6=q("u:"+a); said(X.combine(p2[0],+p2[1],n6), function(r){ return "Made "+r.made+" × "+esc(pname(p2[0],+p2[1]+1))+"."; }); return; }
    if(id==="dkSwap"){ var f=$("dkFrom").value, to=$("dkTo").value, rr=+$("dkRar").value, n7=q("w"); said(X.swap(f,to,rr,n7), function(r){ return "Made "+r.made+" × "+esc(pname(to,rr))+"."; }); return; }
    if((a=t.getAttribute("data-dkcraft"))){ said(X.craft(a,1), function(r){ return "Crafted "+esc(a)+" for "+r.shards+" shards"+(r.parts?" and "+r.parts+" parts":"")+": it’s in the stash."; }); return; }
    if((a=t.getAttribute("data-dkrare"))){ said(X.pickRare(a), function(){ return esc(a)+" is in the stash."; }); return; }
    if((a=t.getAttribute("data-dkhire"))){ said(X.recruit(a), function(r){ return esc(a)+" recruited for "+r.price+" shards."; }); return; }
    if(id==="dkHeroesAll"){ var s2=X.state(); X.heroCards().forEach(function(c){ if(!X.isFree(c.name)) s2.heroes[c.name]=1; }); X._save(s2); MSG="Every Hero is yours."; draw(); return; }
    if(id==="dkHeroesNone"){ var s3=X.state(); s3.heroes={}; X._save(s3); MSG="No recruited Heroes."; draw(); return; }
    if((a=t.getAttribute("data-dkupg"))){ said(X.upgrade(a), function(r){ return "Upgraded to level "+r.level+"."; }); return; }
    if(id==="dkRestock"){ X.restock(); MSG="Restocked."; draw(); return; }
    if(id==="dkReach"){ var s=X.state(); s.reach=Math.min(6,(s.reach||0)+1); X._save(s); MSG="Reach set to Skull "+s.reach+"."; draw(); return; }
    if(id==="dkReset"){ if(confirm("Reset the dock? Stock, bounties, upgrades, reach, recruited Heroes and everything kept here (Consumables, Prototypes, pre-built copies) are cleared.")){ X.reset(); MSG="The dock is reset."; draw(); } return; }
    if(id==="dkTabReset"){ if(confirm("Put the dock’s tables back to their starting values? The Exchange’s list of Consumables and Prototypes, and which Heroes are free, stay.")){ X.resetTables(); draw(); } return; }
  });
  document.addEventListener("input",function(e){ if(!HOST||!HOST.contains(e.target)) return; var a=e.target.getAttribute("data-dkq"); if(a) QTY[a]=e.target.value; });
  document.addEventListener("change",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var el=e.target, a, X=K();
    if((a=el.getAttribute("data-dkitem"))){ var t=X.tables(); if(el.checked){ if(!t.items.some(function(x){ return x.name===a; })) t.items.push({name:a, price:20}); } else t.items=t.items.filter(function(x){ return x.name!==a; }); X.saveTables(t); draw(); return; }
    if((a=el.getAttribute("data-dkfree"))){ var tf=X.tables(); tf.free=tf.free.filter(function(x){ return x!==a; }); if(el.checked) tf.free.push(a); X.saveTables(tf); draw(); return; }
    if((a=el.getAttribute("data-dkiprice"))){ var t2=X.tables(); t2.items.forEach(function(x){ if(x.name===a) x.price=Math.max(0,parseFloat(el.value)||0); }); X.saveTables(t2); return; }
    if((a=el.getAttribute("data-dkt"))){
      var t3=X.tables(), p=a.split("."), v=Math.max(0,parseFloat(el.value)||0);
      if(p[0]==="price") t3.price[+p[1]]=v;
      else if(p[0]==="heroPrice") t3.heroPrice[+p[1]]=v;
      else if(p[0]==="bounty") t3.bounty[p[1]][p[2]]=v;
      else if(p[0]==="effect") t3.effect[p[1]][+p[2]]=v;
      else if(p[0]==="cost") t3.cost[p[1]][+p[2]][+p[3]]=(+p[3]===2?Math.min(5,Math.round(v)):v);
      else if(p[0]==="craft"){ if(p[1]==="noParts") t3.craft.noParts=Math.max(1,v); else t3.craft[p[1]][+p[2]]=(p[1]==="parts"?Math.floor(v):v); }
      else t3[p[0]]=v;
      X.saveTables(t3); return;
    }
  });
  window.KETER_DOCK_UI={render:render, _tab:function(k){ TAB=k; MSG=""; draw(); }, state:function(){ return {tab:TAB, msg:MSG}; }};
})();
