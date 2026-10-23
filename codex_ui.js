/* ===========================================================================
   The Codex (v12.7): a bestiary of Enemies, blueprints, chassis and
   components. Mostly redacted to begin with, it fills in as things are met or
   found, and every entry says where to find it — places always, an Enemy by
   name only once it has been met. Dev Mode sees everything.
   =========================================================================== */
(function(){
  "use strict";
  var P=function(){ return window.KETER_PROG; }, L=function(){ return window.KETER_LOOT; }, CH=function(){ return window.KETER_CHASSIS; };
  var HOST=null, TAB="enemies";
  function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
  function $(id){ return document.getElementById(id); }
  function cards(){ try{ return window.KETER_ALLCARDS ? window.KETER_ALLCARDS() : []; }catch(e){ return []; } }
  function foes(){ var seen={}; return cards().filter(function(c){ if(!P().isFoe(c)||seen[c.name]) return false; seen[c.name]=1; return true; }); }
  var DCOL={"1":"#a98ef0","2":"#ef7fbe","3":"#f0a457","4":"#ef8175","5":"#6fd189","6":"#56c6da","":"#d6e3e8"};
  function dName(d){ return d ? "District "+d+" · "+(P().DISTRICT_NAMES[d]||"") : "No District"; }
  var RED="██████";

  function render(host){ HOST=host||HOST||$("v-codex"); if(!HOST) return; draw(); }
  function draw(){
    var tab=function(k,l){ return '<button class="'+(TAB===k?"on":"")+'" data-cxtab="'+k+'">'+l+'</button>'; };
    HOST.innerHTML='<div class="lts cxs">'+
      '<h2 class="pxh">Codex</h2>'+
      '<p class="pxnote">What you have met and found, and where to look for the rest. It fills in as you play.'+(P().dev()?' <b class="cxdev">Dev Mode: everything shown.</b>':'')+'</p>'+
      '<div class="seg pxseg">'+tab("enemies","Enemies")+tab("blueprints","Blueprints")+tab("chassis","Chassis")+tab("components","Components")+'</div>'+
      '<div id="cxBody">'+(TAB==="enemies"?enemiesHTML():TAB==="blueprints"?bpHTML():TAB==="chassis"?chHTML():compHTML())+'</div></div>';
  }
  /* unknowns that share a place are one line: "3 blueprints — found in District 3" */
  function grouped(hints, noun){
    var n={}, order=[]; hints.forEach(function(h){ if(!n[h]){ n[h]=0; order.push(h); } n[h]++; });
    return order.map(function(h){ return '<div class="cxitem cxred"><b>'+RED+'</b><i>'+(n[h]>1?n[h]+" "+noun+(noun==="chassis"?"":"s"):"A "+noun)+' — '+esc(h)+'</i></div>'; }).join("");
  }
  function where(list){ return list.length?'<ul class="cxwhere">'+list.map(function(t){ return '<li>'+t+'</li>'; }).join("")+'</ul>':'<p class="cxnone">Nowhere yet.</p>'; }

  /* ---- Enemies ---- */
  function reachRarity(c){
    var X=L(), t=X.tables(), src=t.sources[X.sourceFor(c.cardType)]||t.sources.enemy, sk=parseInt(c.skullLevel,10)||1;
    return X.topRarity(Math.min(6, sk+(src.bonus||0)), t);
  }
  function enemiesHTML(){
    var fs=foes(), met=fs.filter(function(c){ return P().seen("enemy",c.name); });
    var byD={}; fs.forEach(function(c){ var d=P().enemyDistrict(c); (byD[d]=byD[d]||[]).push(c); });
    return '<p class="cxcount">'+met.length+' met</p>'+Object.keys(byD).sort(function(a,b){ return (a||"9").localeCompare(b||"9"); }).map(function(d){
      /* met ones in full; the rest as one redacted line, counted by kind */
      var unmet={}, order=[];
      byD[d].forEach(function(c){ if(P().seen("enemy",c.name)) return; var t=P().TYPE_LABEL[c.cardType]||"Enemy"; if(!unmet[t]){ unmet[t]=0; order.push(t); } unmet[t]++; });
      var PL={"Enemy":"Enemies","Elite":"Elites","Mini-Boss":"Mini-Bosses","Boss":"Bosses"};
      var plural=function(t,n){ return n+" "+(n===1?t:(PL[t]||t+"s")); };
      var redLine=order.length?'<div class="cxitem cxred"><b>'+RED+'</b><i>'+esc(order.map(function(t){ return plural(t,unmet[t]); }).join(", "))+' · not met yet</i></div>':'';
      return '<p class="pxsub" style="color:'+(DCOL[d]||"#ccc")+'">'+esc(dName(d))+'</p>'+byD[d].filter(function(c){ return P().seen("enemy",c.name); }).map(function(c){
        var type=P().TYPE_LABEL[c.cardType]||"Enemy";
        var st=c.stats||{}, R=L().RARITIES, top=reachRarity(c), sal=String(c.salvage||"mixed");
        var items=(c.setDrops||[]).map(function(x){ return P().itemName(x.item)+" — "+(+x.chance||0)+"%"; })
          .concat((c.lootPool||[]).map(function(it){ return P().itemName(it)+" — a rare drop"; }));
        return '<div class="cxitem"><b>'+esc(c.name)+'</b><i>'+esc(type)+' · Skull '+esc(c.skullLevel||"?")+(c.combatRoles&&c.combatRoles.length?' · '+esc(c.combatRoles.join(" + ")):'')+'</i>'+
          '<i>HP '+esc(st.hp||"?")+' · AC '+esc(st.ac||"?")+' · MS '+esc(st.move||"?")+' · INT '+esc(st.int||"?")+'</i>'+
          '<p class="cxdrops">Drops shards and '+(sal==="mixed"?"any parts":esc(sal)+" parts")+', up to <span style="color:'+R[top].lite+'">'+R[top].label+'</span>'+
          (items.length?'; also '+esc(items.join("; ")):'')+(d?'; and anything from '+esc("District "+d)+'’s pool':'')+'.</p></div>';
      }).join("")+redLine;
    }).join("");
  }

  /* ---- where a blueprint level or chassis can be found ---- */
  function sourcesText(it){ var all=cards(); return P().sourcesOf(it, all).map(function(s){ return esc(P().sourceText(s)); }); }
  function hint(it){
    var s=P().sourcesOf(it, cards()).filter(function(x){ return x.kind!=="research"; })[0]; if(!s) return null;
    return s.kind==="district" ? "found in District "+s.district : s.kind==="floor" ? "found on the floor "+s.floor : P().sourceText(s).replace(/ — .*$/,"");
  }

  /* ---- Blueprints ---- */
  function bpHTML(){
    var X=P(), cat=X.catalog(), K=window.KETER_KW;
    var known=cat.filter(function(b){ return X.knownBp(b.name); }), unknown=cat.filter(function(b){ return !X.knownBp(b.name); });
    var knownHtml=known.map(function(b){
      var have=X.owned(b.name), lv=[];
      for(var l=1;l<=b.levels;l++) lv.push(l);
      return '<div class="cxitem"><b>'+esc(b.name)+'</b><i>'+(b.levels>1?'level '+have+' of '+b.levels+' · up to '+b.caps.join(" · "):(have?'owned':'not owned'))+'</i>'+
        lv.map(function(l){ var it="bp:"+b.name+":"+l, own=have>=l;
          return '<p class="cxlv">'+(b.levels>1?'<b>Level '+l+'</b> ':'')+(own?'<span class="wsok">owned</span>':'')+'</p>'+(own?'':where(sourcesText(it))); }).join("")+'</div>';
    }).join("");
    var hints=[]; unknown.forEach(function(b){ var h=hint("bp:"+b.name+":1"); if(h) hints.push(h); });
    return '<p class="cxcount">'+known.length+' found</p>'+(known.length?knownHtml:'<p class="pxnote">None found yet.</p>')+
      (hints.length?'<p class="pxsub">Still to find</p>'+grouped(hints,"blueprint"):'')+
      '<p class="pxnote">… and more, yet to be found.</p>';
  }

  /* ---- Chassis ---- */
  function chHTML(){
    var X=P(), all=X.chassisList().filter(Boolean);
    var known=all.filter(function(c){ return X.knownCh(c.id); }), unknown=all.filter(function(c){ return !X.knownCh(c.id); });
    return '<p class="cxcount">'+known.length+' found</p>'+known.map(function(c){
        var st=c.stats||{}, dd=CH()?CH().districtOf(c):{name:""}, own=X.hasChassis(c.id);
        return '<div class="cxitem"><b>'+esc(c.name)+'</b><i>'+esc(dd.name)+' · '+esc((c.subtypes||[]).join(" + "))+' · '+esc(c.bodyPlan||"")+(own?' · <span class="wsok">'+(c.id===X.STARTER?"starter":"unlocked")+'</span>':'')+'</i>'+
          '<i>HP '+st.hp+' · AC '+st.ac+' · MS '+st.move+' · NRG '+st.nrg+' · INT '+st.int+' · DMG '+st.dmg+' · power '+c.powerCap+'</i>'+
          (own?'':where(sourcesText("ch:"+c.id)))+'</div>';
      }).join("")+
      (function(){ var hs=[]; unknown.forEach(function(c){ var h=hint("ch:"+c.id); if(h) hs.push(h); }); return hs.length?'<p class="pxsub">Still to find</p>'+grouped(hs,"chassis"):''; })()+
      '<p class="pxnote">… and more, yet to be found.</p>';
  }

  /* ---- Components ---- */
  function compSources(type, r){
    var X=L(), t=X.tables(), out=[], unmet={};
    foes().forEach(function(c){
      var sal=String(c.salvage||"mixed"); if(sal!=="mixed" && sal!==type) return;
      if(reachRarity(c)<r) return;
      if(P().seen("enemy",c.name)) out.push(esc(c.name)+' ('+esc(P().TYPE_LABEL[c.cardType]||"Enemy")+', Skull '+esc(c.skullLevel||"?")+')');
      else { var d=P().enemyDistrict(c); unmet[d]=(unmet[d]||0)+1; }
    });
    Object.keys(unmet).forEach(function(d){ out.push(unmet[d]+' Enem'+(unmet[d]===1?"y":"ies")+' you have not met'+(d?' in District '+d:'')); });
    var minSk=0; for(var s=1;s<=6;s++){ if((t.weights[s-1][r]||0)>0){ minSk=s; break; } }
    if(minSk) out.push('Loot Tiles and Locked Chests at Skull Level '+minSk+(minSk<6?" or higher":""));
    P().savedFloors().forEach(function(f){
      var sk=X.poiSkull(f.lv), lines=(f.loot&&f.loot.lines)||[];
      lines.forEach(function(l){
        if(l.kind==="exact" && l.type===type && +l.rarity===r) out.push('Floor: '+esc(f.name)+' — '+(+l.n)+' in its reward');
        if(l.kind==="roll" && (l.type==="any"||l.type===type) && X.topRarity(Math.min(6,sk+(+l.bonus||0)),t)>=r) out.push('Floor: '+esc(f.name)+' — rolled in its reward');
      });
    });
    return out;
  }
  function compHTML(){
    var X=L(), t=X.tables(), st=X.stock(), R=X.RARITIES;
    return X.TYPES.map(function(ty){
      return '<p class="pxsub">'+esc(ty.label)+'</p>'+R.map(function(rr,r){
        var have=st.parts[ty.id][r], known=P().dev()||have>0||P().seen("comp",ty.id+":"+r);
        return '<div class="cxitem'+(known?"":" cxred")+'"><b>'+(known?esc(X.nameOf(ty.id,r,t)):RED)+'</b><i><span style="color:'+rr.lite+'">'+rr.label+'</span> '+esc(ty.short)+' part'+(known?' · you have '+have:'')+'</i>'+
          where(compSources(ty.id,r))+'</div>';
      }).join("");
    }).join("");
  }

  document.addEventListener("click",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var t=e.target.closest?e.target.closest("button"):null; if(!t) return;
    var a=t.getAttribute("data-cxtab"); if(a){ TAB=a; draw(); }
  });
  window.KETER_CODEX_UI={render:render, _tab:function(k){ TAB=k; draw(); }, state:function(){ return {tab:TAB}; }};
})();
