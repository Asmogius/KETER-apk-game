/* ===========================================================================
   The Loot page (v12.6): the stockpile won in the Battle Simulator, rolls to
   see what a source gives (once, or a thousand times for the spread), and the
   tables themselves — rarity by Skull Level, what each source drops, and the
   eighteen components' names. Everything here is the video game's, not the
   board game's.
   =========================================================================== */
(function(){
  "use strict";
  var L=function(){ return window.KETER_LOOT; };
  var HOST=null, TAB="stock", ADJ=false, LAST=null, STATS=null, saveT=null;
  var ROLL={source:"enemy", skull:3, salvage:"mixed", x:2, floor:""};
  function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
  function $(id){ return document.getElementById(id); }
  function fmt(n){ n=Math.round(n); return String(n).replace(/\B(?=(\d{3})+(?!\d))/g,","); }
  function pct(a,b){ return b? (100*a/b) : 0; }
  /* a saved time, in this device's own time zone */
  function when(iso){ var d=new Date(iso); if(isNaN(d)) return ""; var p=function(n){ return ("0"+n).slice(-2); };
    return d.getFullYear()+"-"+p(d.getMonth()+1)+"-"+p(d.getDate())+" "+p(d.getHours())+":"+p(d.getMinutes()); }

  function render(host){ HOST=host||HOST||$("v-loot"); if(!HOST) return; draw(); }
  function draw(){
    var tab=function(k,l){ return '<button class="'+(TAB===k?"on":"")+'" data-lttab="'+k+'">'+l+'</button>'; };
    HOST.innerHTML='<div class="lts">'+
      '<h2 class="pxh">Loot</h2>'+
      '<p class="pxnote">The video game’s economy: Aether shards, and components of three types in six rarities. A won fight in the Battle Simulator adds its loot to your stockpile.</p>'+
      '<div class="seg pxseg">'+tab("stock","Stockpile")+tab("roll","Roll")+tab("tables","Tables")+tab("pools","Pools")+'</div>'+
      '<div id="ltBody">'+(TAB==="stock"?stockHTML():TAB==="roll"?rollHTML():TAB==="pools"?poolsHTML():tablesHTML())+'</div></div>';
  }

  /* ---- the stockpile ---- */
  function stockHTML(){
    var X=L(), s=X.stock(), t=X.tables(), hist=X.history();
    var cell=function(ty,r){
      var n=s.parts[ty.id][r], nm=X.nameOf(ty.id,r,t);
      return ADJ ? '<td><input type="number" min="0" inputmode="numeric" class="ltin" data-ltadj="'+ty.id+':'+r+'" value="'+n+'" aria-label="'+esc(nm)+'"></td>'
                 : '<td class="'+(n?"":"lt0")+'" title="'+esc(nm)+'"><b>'+(n?fmt(n):"—")+'</b><i>'+esc(nm)+'</i></td>';
    };
    return '<div class="ltshards"><span>Aether shards</span>'+
        (ADJ?'<input type="number" min="0" inputmode="numeric" class="ltin ltbig" data-ltadj="shards" value="'+s.shards+'" aria-label="Aether shards">':'<b id="ltShards">'+fmt(s.shards)+'</b>')+'</div>'+
      '<table class="ltgrid"><thead><tr><th></th>'+X.TYPES.map(function(ty){ return '<th>'+ty.short+'</th>'; }).join("")+'</tr></thead><tbody>'+
      X.RARITIES.map(function(rr,r){ return '<tr><th style="color:'+rr.lite+'">'+rr.label+'</th>'+X.TYPES.map(function(ty){ return cell(ty,r); }).join("")+'</tr>'; }).join("")+
      '</tbody></table>'+
      '<p class="pxnote">'+fmt(X.count(s))+' component'+(X.count(s)===1?"":"s")+' in all. The Workshop and the dock spend them.</p>'+
      keptHTML()+
      '<div class="pxrow"><button class="ghost'+(ADJ?" primary":"")+'" id="ltAdj">'+(ADJ?"Done":"Adjust")+'</button>'+
      '<button class="ghost" id="ltReset">Reset the stockpile</button></div>'+
      (ADJ?'<p class="pxnote">Change any count by hand, for testing.</p>':'')+
      '<p class="pxsub">Recent</p>'+
      (hist.length?'<div class="lthist">'+hist.slice(0,12).map(function(h){
        return '<div><b>'+esc(h.why||"Added")+'</b><i>'+esc(when(h.t))+'</i><span>'+esc(signed(h.bag,t))+'</span></div>'; }).join("")+'</div>'
        :'<p class="pxnote">Nothing yet. Bring a haul home from the World Map, or roll here and add it.</p>');
  }
  /* a log entry: what came in, and what was spent */
  function signed(b, t){
    var X=window.KETER_LOOT, gain=X.bag(), lost=X.bag(); b=b||{};
    var sh=Math.floor(+b.shards||0); if(sh>0) gain.shards=sh; else lost.shards=-sh;
    X.TYPES.forEach(function(ty){ var r=(b.parts||{})[ty.id]||[]; for(var i=0;i<6;i++){ var n=Math.floor(+r[i]||0); if(n>0) gain.parts[ty.id][i]=n; else if(n<0) lost.parts[ty.id][i]=-n; } });
    var bits=[]; if(!X.isEmpty(gain)) bits.push(X.text(gain,t)); if(!X.isEmpty(lost)) bits.push("spent "+X.text(lost,t));
    return bits.join(" · ")||"nothing";
  }
  /* v12.9: the stockpile also holds Consumables, Prototypes and pre-built copies waiting to go */
  function keptHTML(){
    var K=window.KETER_DOCK; if(!K) return "";
    var v=K.inv(), names=Object.keys(v.cards).filter(function(n){ return v.cards[n]>0; }).sort(), pre=Object.keys(v.pre).filter(function(id){ return v.pre[id]>0; });
    if(!names.length && !pre.length) return "";
    var W=window.KETER_WORKSHOP;
    return '<p class="pxsub">Also kept here</p><div class="lthist">'+
      names.map(function(n){ return '<div><b>'+esc(n)+' ×'+v.cards[n]+'</b><i>'+esc(K.itemKind(n)==="prototype"?"Prototype":"Consumable")+'</i></div>'; }).join("")+
      pre.map(function(id){ var d=W&&W.get(id); return '<div><b>'+esc(d?d.name:id)+' ×'+v.pre[id]+'</b><i>Pre-built copies · go on the next deployment</i></div>'; }).join("")+'</div>';
  }

  /* ---- rolling ---- */
  function floorsWithReward(){
    var out=[];
    try{ var all=JSON.parse(localStorage.getItem("keter-hexmap-levels")||"{}");
      Object.keys(all).forEach(function(k){ var lv=all[k]; if(lv && lv.loot && ((lv.loot.lines||[]).length || +lv.loot.shards)) out.push({key:k, name:lv.name||k, loot:lv.loot, skull:L().poiSkull(lv)}); }); }catch(e){}
    return out;
  }
  function rollOpts(){
    var X=L(), o={source:ROLL.source, skull:ROLL.skull, poiSkull:ROLL.skull, salvage:ROLL.salvage, x:ROLL.x};
    if(ROLL.source==="floor"){ var f=floorsWithReward().filter(function(x){ return x.key===ROLL.floor; })[0]; if(!f) return null; return {reward:f.loot, poiSkull:f.skull}; }
    return o;
  }
  function rollHTML(){
    var X=L(), t=X.tables(), src=t.sources[ROLL.source], floors=floorsWithReward();
    var seg=function(attr,items,cur){ return '<div class="seg pxseg">'+items.map(function(it){ return '<button class="'+(String(cur)===String(it[0])?"on":"")+'" '+attr+'="'+it[0]+'">'+it[1]+'</button>'; }).join("")+'</div>'; };
    var kill=/^(enemy|elite|miniboss|boss)$/.test(ROLL.source), poi=src&&src.skull==="poi";
    return '<p class="pxsub">What drops it</p>'+
      '<div class="ltsrc">'+X.SOURCE_ORDER.map(function(k){ return '<button class="ghost'+(ROLL.source===k?" primary":"")+'" data-ltsrc="'+k+'">'+esc(t.sources[k].label)+'</button>'; }).join("")+
        '<button class="ghost'+(ROLL.source==="floor"?" primary":"")+'" data-ltsrc="floor"'+(floors.length?"":" disabled title=\"No floor has a reward yet\"")+'>A floor’s reward</button></div>'+
      (ROLL.source==="floor"
        ? '<p class="pxsub">Floor</p><select id="ltFloor" class="ltsel">'+floors.map(function(f){ return '<option value="'+esc(f.key)+'"'+(f.key===ROLL.floor?" selected":"")+'>'+esc(f.name)+' · Skull '+f.skull+'</option>'; }).join("")+'</select>'+
          (function(){ var f=floors.filter(function(x){ return x.key===ROLL.floor; })[0]; return f?'<p class="pxnote">'+esc(X.rewardText(f.loot,t))+'</p>':''; })()
        : '<p class="pxsub">'+(poi?"The POI’s Skull Level":"Its Skull Level")+'</p>'+seg("data-ltskull",[[1,1],[2,2],[3,3],[4,4],[5,5],[6,6]],ROLL.skull)+
          (kill?'<p class="pxsub">Its Salvage</p>'+seg("data-ltsalv",X.SALVAGE.map(function(s){ return [s.id,s.label]; }),ROLL.salvage):'')+
          (ROLL.source==="chest"?'<p class="pxsub">Components in the chest (the number on its tile)</p><input type="number" id="ltX" class="ltin" min="0" max="20" value="'+ROLL.x+'">':'')+
          '<p class="pxnote">'+describe(ROLL.source,t)+'</p>')+
      '<div class="pxrow"><button class="ghost primary" id="ltOnce">Roll once</button><button class="ghost" id="ltMany">Roll 1,000</button></div>'+
      '<div id="ltOut">'+outHTML()+'</div>';
  }
  function describe(k,t){
    var s=t.sources[k]; if(!s) return "";
    var n=s.fromTile?"the number on its tile":(s.min===s.max?String(s.min):s.min+" to "+s.max);
    return esc(s.label)+": "+s.shards+" shards per Skull Level (±"+t.spread+"%), "+n+" component"+(s.max===1&&s.min===1?"":"s")+
      (s.bonus?", rolled as if "+s.bonus+" Skull Level"+(s.bonus===1?"":"s")+" higher":"")+
      (s.top?", "+s.top+" of them at the rarest it can reach":"")+
      " — by "+(s.skull==="poi"?"the POI’s":"its own")+" Skull Level.";
  }
  function outHTML(){
    var X=L();
    if(STATS){
      var S=STATS, tot=S.parts||1;
      return '<div class="ltstats"><p class="pxsub">'+fmt(S.n)+' rolls</p>'+
        '<p class="ltline">Shards: <b>'+S.avgShards.toFixed(1)+'</b> on average ('+S.minShards+' to '+S.maxShards+')</p>'+
        '<p class="ltline">Components: <b>'+S.avgParts.toFixed(2)+'</b> a roll'+(S.empty?' · none in '+pct(S.empty,S.n).toFixed(1)+'% of rolls':'')+'</p>'+
        '<div class="ltbars">'+X.RARITIES.map(function(rr,r){ var p=pct(S.byRarity[r],tot);
          return '<div class="ltbar"><span style="color:'+rr.lite+'">'+rr.label+'</span><i><em style="width:'+Math.max(p>0?1:0,p).toFixed(1)+'%;background:'+rr.color+'"></em></i><b>'+p.toFixed(1)+'%</b></div>'; }).join("")+'</div>'+
        '<p class="ltline">'+X.TYPES.map(function(ty){ return ty.short+' '+pct(S.byType[ty.id],tot).toFixed(0)+'%'; }).join(" · ")+'</p></div>';
    }
    if(LAST){
      var ls=X.lines(LAST);
      return '<div class="ltres"><p class="pxsub">Rolled</p><ul>'+
        (LAST.shards?'<li><b>'+fmt(LAST.shards)+'</b> Aether shards</li>':'')+
        ls.map(function(l){ return '<li><b>'+l.n+' ×</b> '+esc(l.name)+' <i style="color:'+l.color+'">'+l.rarityLabel+' '+(X.TYPES.filter(function(t){ return t.id===l.type; })[0].short)+'</i></li>'; }).join("")+
        (!LAST.shards&&!ls.length?'<li>Nothing</li>':'')+'</ul>'+
        '<button class="ghost" id="ltKeep"'+(X.isEmpty(LAST)?" disabled":"")+'>Add to the stockpile</button></div>';
    }
    return "";
  }

  /* ---- the tables ---- */
  function tablesHTML(){
    var X=L(), t=X.tables();
    var num=function(attr,val,min,max,extra){ return '<input type="number" class="ltin" '+attr+' value="'+val+'" min="'+(min||0)+'"'+(max!=null?' max="'+max+'"':'')+' inputmode="numeric"'+(extra||"")+'>'; };
    return '<p class="pxsub">Rarity by Skull Level</p>'+
      '<p class="pxnote">Each row is how the components at that Skull Level divide among the rarities. The numbers are weights: they need not add to 100. A 0 means never.</p>'+
      '<div class="ltscroll"><table class="ltw"><thead><tr><th>Skull</th>'+X.RARITIES.map(function(rr,r){ return '<th style="color:'+rr.lite+'" title="'+rr.label+'">'+["Com","Unc","Rare","Epic","Leg","Myth"][r]+'</th>'; }).join("")+'</tr></thead><tbody>'+
      t.weights.map(function(row,s){ return '<tr><th>'+(s+1)+'</th>'+row.map(function(w,r){ return '<td>'+num('data-ltw="'+s+':'+r+'"',w,0,1000)+'</td>'; }).join("")+'</tr>'; }).join("")+
      '</tbody></table></div>'+
      '<p class="pxsub">What each source drops</p>'+
      '<div class="ltscroll"><table class="ltw lts2"><thead><tr><th></th><th>Shards per Skull</th><th>Fewest</th><th>Most</th><th>Rarer by</th><th>At the top</th><th>Blueprint %</th><th>Card %</th></tr></thead><tbody>'+
      X.SOURCE_ORDER.map(function(k){ var s=t.sources[k];
        return '<tr><th>'+esc(s.label)+'</th><td>'+num('data-lts="'+k+':shards"',s.shards,0,999)+'</td>'+
          (s.fromTile?'<td colspan="2" class="ltnote">its tile</td>':'<td>'+num('data-lts="'+k+':min"',s.min,0,20)+'</td><td>'+num('data-lts="'+k+':max"',s.max,0,20)+'</td>')+
          '<td>'+num('data-lts="'+k+':bonus"',s.bonus,0,5)+'</td><td>'+num('data-lts="'+k+':top"',s.top,0,20)+'</td><td>'+num('data-lts="'+k+':bp"',s.bp||0,0,100)+'</td><td>'+num('data-lts="'+k+':card"',s.card||0,0,100)+'</td></tr>'; }).join("")+
      '</tbody></table></div>'+
      '<p class="pxnote"><b>Rarer by</b> rolls as if that many Skull Levels higher. <b>At the top</b> is how many come at the rarest rarity it can reach. Enemies, Elites and Mini-Bosses use their own Skull Level; Bosses, Loot Tiles and chests the POI’s. <b>Card %</b> (v14.9) is the chance of a Consumable or a Prototype card of the District, no rarer than the Skull Level allows, kept at the dock once home.</p>'+
      '<div class="pxrow pxcustom ltspread"><span>Shards vary by ±</span>'+num('data-ltspread',t.spread,0,100)+'<span>%</span></div>'+
      '<p class="pxsub">Names</p><div class="ltnames">'+
      '<span></span>'+X.TYPES.map(function(ty){ return '<b>'+ty.short+'</b>'; }).join("")+
      X.RARITIES.map(function(rr,r){ return '<span style="color:'+rr.lite+'">'+rr.label+'</span>'+X.TYPES.map(function(ty){ return '<input class="ltname" data-ltname="'+ty.id+':'+r+'" value="'+esc(t.names[ty.id][r])+'" aria-label="'+rr.label+' '+ty.label+'">'; }).join(""); }).join("")+
      '</div>'+
      '<div class="pxrow" style="margin-top:10px;"><button class="ghost" id="ltTabReset">Reset every table to the starting values</button></div>'+
      '<p class="pxnote" id="ltSaved"></p>';
  }
  /* ---- the pools (v12.7): which blueprint levels and chassis each District can drop at random ---- */
  var POOLD="3";
  function poolsHTML(){
    var P=window.KETER_PROG, K=window.KETER_KW;
    if(!P) return '<p class="pxnote">Pools are not available.</p>';
    if(!P.dev()) return '<p class="pxnote">Each District has a pool: the blueprint levels and chassis that can drop there at random, on top of what any Enemy carries. Pools list every blueprint in the game, so they are edited in Dev Mode.</p>';
    var items=P.poolItems(POOLD), on=function(it){ return items.indexOf(it)>=0; };
    var cat=P.catalog(), cats=K?K.CATEGORIES:[];
    var chip=function(it,label){ return '<button class="chchip'+(on(it)?" on":"")+'" data-ltpool="'+esc(it)+'">'+esc(label)+'</button>'; };
    return '<p class="pxnote">What can drop at random anywhere in a District, by each source’s Blueprint % (Tables). A drop only ever gives the next level the player is missing, or a chassis they do not have. An Enemy card can add its own, in the Forge.</p>'+
      '<select id="ltPoolD" class="ltsel">'+["1","2","3","4","5","6"].map(function(d){ return '<option value="'+d+'"'+(d===POOLD?" selected":"")+'>District '+d+' · '+esc(P.DISTRICT_NAMES[d])+'</option>'; }).join("")+'</select>'+
      '<p class="pxnote">'+items.length+' in this pool.</p>'+
      '<p class="pxsub">Chassis</p><div class="chchips">'+P.chassisList().filter(Boolean).map(function(c){ return chip("ch:"+c.id, c.name); }).join("")+'</div>'+
      cats.map(function(ct){
        var bs=cat.filter(function(b){ return b.cat===ct.k; }); if(!bs.length) return "";
        return '<p class="pxsub" style="color:'+ct.colour+'">'+esc(ct.label)+'</p><div class="ltpool">'+bs.map(function(b){
          var chips=""; for(var l=1;l<=b.levels;l++) chips+=chip("bp:"+b.name+":"+l, b.levels>1?"L"+l+" · "+b.caps[l-1]:"L1");
          return '<div class="ltpoolrow"><span>'+esc(b.name)+'</span><div class="chchips">'+chips+'</div></div>'; }).join("")+'</div>';
      }).join("")+
      '<div class="pxrow" style="margin-top:10px;"><button class="ghost" id="ltPoolReset">Reset every pool</button></div>';
  }
  function saveFromInputs(){
    var X=L(), t=X.tables();
    [].forEach.call(HOST.querySelectorAll("[data-ltw]"),function(el){ var a=el.getAttribute("data-ltw").split(":"); t.weights[+a[0]][+a[1]]=Math.max(0,parseFloat(el.value)||0); });
    [].forEach.call(HOST.querySelectorAll("[data-lts]"),function(el){ var a=el.getAttribute("data-lts").split(":"); t.sources[a[0]][a[1]]=Math.max(0,parseInt(el.value,10)||0); });
    Object.keys(t.sources).forEach(function(k){ var s=t.sources[k]; if(s.max<s.min) s.max=s.min; });
    var sp=HOST.querySelector("[data-ltspread]"); if(sp) t.spread=Math.max(0,Math.min(100,parseInt(sp.value,10)||0));
    [].forEach.call(HOST.querySelectorAll("[data-ltname]"),function(el){ var a=el.getAttribute("data-ltname").split(":"); var v=String(el.value||"").trim(); if(v) t.names[a[0]][+a[1]]=v; });
    X.saveTables(t);
    var m=$("ltSaved"); if(m) m.textContent="Saved on this device.";
  }
  function saveStockFromInputs(){
    var X=L(), b=X.bag();
    [].forEach.call(HOST.querySelectorAll("[data-ltadj]"),function(el){ var k=el.getAttribute("data-ltadj"), v=Math.max(0,parseInt(el.value,10)||0);
      if(k==="shards") b.shards=v; else { var a=k.split(":"); b.parts[a[0]][+a[1]]=v; } });
    X.setStock(b);
  }

  document.addEventListener("click",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var t=e.target.closest?e.target.closest("button"):null; if(!t) return;
    var X=L(), id=t.id, a;
    if((a=t.getAttribute("data-lttab"))){ if(ADJ) saveStockFromInputs(); ADJ=false; TAB=a; draw(); return; }
    if(id==="ltAdj"){ if(ADJ) saveStockFromInputs(); ADJ=!ADJ; draw(); return; }
    if(id==="ltReset"){ if(confirm("Empty the stockpile? Every shard and component on this device goes.")){ X.resetStock(); ADJ=false; draw(); } return; }
    if((a=t.getAttribute("data-ltsrc"))){ ROLL.source=a; LAST=null; STATS=null;
      if(a==="floor" && !ROLL.floor){ var f=floorsWithReward()[0]; ROLL.floor=f?f.key:""; }
      draw(); return; }
    if((a=t.getAttribute("data-ltskull"))){ ROLL.skull=+a; LAST=null; STATS=null; draw(); return; }
    if((a=t.getAttribute("data-ltsalv"))){ ROLL.salvage=a; LAST=null; STATS=null; draw(); return; }
    if(id==="ltOnce"||id==="ltMany"){
      var o=rollOpts(); if(!o) return;
      if(id==="ltOnce"){ STATS=null; LAST=o.reward?X.rollReward(o.reward,o.poiSkull):X.roll(o); }
      else { LAST=null; STATS=X.simulate(o,1000); }
      var out=$("ltOut"); if(out) out.innerHTML=outHTML(); return;
    }
    if(id==="ltKeep" && LAST){
      var lab=ROLL.source==="floor"?"a floor’s reward":X.tables().sources[ROLL.source].label;
      X.addToStock(LAST,"Rolled on the Loot page · "+lab+(ROLL.source==="floor"?"":" · Skull "+ROLL.skull));
      LAST=null; var o2=$("ltOut"); if(o2) o2.innerHTML='<p class="pxnote">Added to the stockpile.</p>'; return;
    }
    if((a=t.getAttribute("data-ltpool"))){ var P=window.KETER_PROG; P.setPoolItem(POOLD, a, P.poolItems(POOLD).indexOf(a)<0); draw(); return; }
    if(id==="ltPoolReset"){ if(confirm("Put every District\u2019s pool back as it started?")){ window.KETER_PROG.resetPools(); draw(); } return; }
    if(id==="ltTabReset"){ if(confirm("Put every loot table back to its starting values? Your names go too.")){ X.resetTables(); draw(); } return; }
  });
  document.addEventListener("change",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var el=e.target;
    if(el.id==="ltPoolD"){ POOLD=el.value; draw(); return; }
    if(el.id==="ltFloor"){ ROLL.floor=el.value; LAST=null; STATS=null; draw(); return; }
    if(el.id==="ltX"){ ROLL.x=Math.max(0,Math.min(20,parseInt(el.value,10)||0)); return; }
    if(el.hasAttribute("data-ltadj")){ saveStockFromInputs(); return; }
    if(el.hasAttribute("data-ltw")||el.hasAttribute("data-lts")||el.hasAttribute("data-ltname")||el.hasAttribute("data-ltspread")) saveFromInputs();
  });
  document.addEventListener("input",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var el=e.target;
    if(el.hasAttribute("data-ltw")||el.hasAttribute("data-lts")||el.hasAttribute("data-ltname")||el.hasAttribute("data-ltspread")){
      clearTimeout(saveT); saveT=setTimeout(saveFromInputs,400); }
  });

  window.KETER_LOOT_UI={render:render, _pool:function(d){ POOLD=String(d); TAB="pools"; draw(); }, state:function(){ return {tab:TAB, adj:ADJ, last:LAST, stats:STATS, roll:ROLL}; },
    _tab:function(k){ TAB=k; ADJ=false; draw(); }};
})();
