/* ===========================================================================
   The Workshop page (v12.7): designs, blueprints and the Workshop's tables.
   Designs are built on chassis you have found, with keywords you own; the
   check, the power and the cost of a copy update as you go.
   =========================================================================== */
(function(){
  "use strict";
  var W=function(){ return window.KETER_WORKSHOP; }, P=function(){ return window.KETER_PROG; };
  var CH=function(){ return window.KETER_CHASSIS; }, L=function(){ return window.KETER_LOOT; };
  var HOST=null, TAB="designs", CUR=null, PICK=false, saveT=null, MSG="", COSTKW="";
  function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
  function $(id){ return document.getElementById(id); }
  function num(v,d){ var x=parseFloat(v); return isNaN(x)?(d||0):x; }
  function dev(){ return P()&&P().dev(); }
  function costText(parts){
    var R=L().RARITIES, bits=[]; parts.forEach(function(n,r){ if(n) bits.push('<span style="color:'+R[r].lite+'">'+n+' '+R[r].label+'</span>'); });
    return bits.join(" · ")||"nothing";
  }

  function render(host){ HOST=host||HOST||$("v-workshop"); if(!HOST) return; draw(); }
  function draw(){
    if(CUR){ drawEditor(); return; }
    var tab=function(k,l){ return '<button class="'+(TAB===k?"on":"")+'" data-wstab="'+k+'">'+l+'</button>'; };
    HOST.innerHTML='<div class="lts wss">'+
      '<h2 class="pxh">Workshop</h2>'+
      '<p class="pxnote">Design Troops on the chassis you have found, with the blueprints you own. A design is a Troop card: it goes into decks and fights in the Battle Simulator.</p>'+
      '<div class="seg pxseg">'+tab("designs","Designs")+tab("blueprints","Blueprints")+tab("costs","Costs")+(dev()?tab("prebuilt","Pre-built"):"")+'</div>'+
      '<div id="wsBody">'+(TAB==="designs"?(PICK?pickHTML():listHTML()):TAB==="blueprints"?bpHTML():TAB==="prebuilt"&&dev()?(PICK?pickHTML(true):preHTML()):costsHTML())+'</div></div>';
  }

  /* ---- the list ---- */
  function stockLine(){
    var st=L().stock(), t=st.parts.troop, R=L().RARITIES, bits=[];
    t.forEach(function(n,r){ if(n) bits.push('<span style="color:'+R[r].lite+'">'+n+' '+R[r].label+'</span>'); });
    return '<p class="wsstock">Troop parts: '+(bits.join(" · ")||"none")+' · '+st.shards+' shards</p>';
  }
  function listHTML(){
    var ds=W().list();
    return stockLine()+'<div class="pxrow"><button class="ghost primary" id="wsNew">New design</button></div>'+
      (ds.length?'<div class="wslist">'+ds.map(function(d){
        var ch=W().chassisOf(d), c=W().check(d), cost=W().cost(d), n=W().affordable(d), dd=CH().districtOf(ch||{});
        var out=window.KETER_DEPLOY&&window.KETER_DEPLOY.lockedDesign(d.id), free=window.KETER_DOCK?window.KETER_DOCK.starterFree():(window.KETER_WORLD?window.KETER_WORLD.tables().starterFree:4);
        return '<div class="wsitem" style="border-left-color:'+dd.color+'"><b>'+esc(d.name)+'</b>'+
          (d.starter?'<i class="wsstarter">Starter · '+free+' free copies every deployment · copy it to make your own</i>':'')+
          (out?'<i class="wslock">Out on a deployment · changes wait until it comes home</i>':'')+
          '<i>'+esc(ch?ch.name:"(missing chassis)")+' · power '+cost.power+' / '+(ch?ch.powerCap:"?")+' · '+(c.ok?'<span class="wsok">fits</span>':'<span class="wsbad">does not fit</span>')+'</i>'+
          /* (v14.22) a design costing only Common parts goes out free; and its Mark */
          (cost.parts.every(function(x,r){ return r===0||!x; }) && localStorage.getItem("keter-test-paid-commons")!=="1"?'<i class="wsok">Free to take out: it costs only Common parts</i>':'<i>One copy: '+costText(cost.parts)+' · you could pay for '+n+'</i>')+
          '<i>'+W().MK_NAME[W().mkOf(d)-1]+(W().mkOf(d)<3?' · Mk '+(W().mkOf(d)===1?'II':'III')+' for '+W().mkText(W().mkCost(d))+' Troop parts':' · the highest Mark')+'</i>'+
          '<div class="pxrow"><button class="ghost" data-wsopen="'+esc(d.id)+'">'+(W().locked(d.id)?'View':'Edit')+'</button><button class="ghost" data-wscopy="'+esc(d.id)+'">Copy</button>'+
          (W().mkOf(d)<3 && !(window.KETER_DEPLOY&&window.KETER_DEPLOY.active())?'<button class="ghost" data-wsmk="'+esc(d.id)+'">Raise to '+W().MK_NAME[W().mkOf(d)]+'</button>':'')+
          (W().locked(d.id)?'':'<button class="ghost" data-wsdel="'+esc(d.id)+'">Delete</button>')+'</div></div>';
      }).join("")+'</div>':'<p class="pxnote">No designs yet. Start one on a chassis you have found.</p>');
  }
  /* v12.9: pre-built Troops, made here in Dev Mode for the Exchange */
  function preHTML(){
    var ps=W().prebuilts(), K=window.KETER_DOCK;
    return '<p class="pxnote">Pre-built Troops are finished designs the Exchange sells by the copy, for the next deployment only: a way for players to try chassis and blueprints they haven\u2019t found. Only their fit is checked, not what the player owns. The Exchange offers them a few at a time, in this order.</p>'+
      '<div class="pxrow"><button class="ghost primary" id="wsNewPre">New pre-built</button></div>'+
      (ps.length?'<div class="wslist">'+ps.map(function(d,i){
        var ch=W().chassisOf(d), c=W().check(d), cost=W().cost(d), dd=CH().districtOf(ch||{});
        return '<div class="wsitem" style="border-left-color:'+dd.color+'"><b>'+(i+1)+'. '+esc(d.name)+'</b>'+
          '<i>'+esc(ch?ch.name:"(missing chassis)")+' \u00b7 power '+cost.power+' / '+(ch?ch.powerCap:"?")+' \u00b7 '+(c.ok?'<span class="wsok">fits</span>':'<span class="wsbad">does not fit</span>')+'</i>'+
          '<i>A copy at the Exchange: '+(K?K.preCost(d):"?")+' shards</i>'+
          '<div class="pxrow"><button class="ghost" data-wsopen="'+esc(d.id)+'">Edit</button><button class="ghost" data-wspreup="'+esc(d.id)+'">\u2191</button><button class="ghost" data-wsdel="'+esc(d.id)+'">Delete</button></div></div>';
      }).join("")+'</div>':'<p class="pxnote">None yet.</p>');
  }
  /* choosing a chassis: those found, and the rest as unknowns (a pre-built may use any) */
  function pickHTML(pre){
    var all=CH().list(), s=P().state();
    var mine=all.filter(function(c){ return pre || P().hasChassis(c.id,s); }), rest=all.filter(function(c){ return !pre && !P().hasChassis(c.id,s); });
    return '<p class="pxsub">Choose a chassis</p><div class="wslist">'+mine.map(function(c){ if(pre) return '<button class="wsch" data-wspickpre="'+esc(c.id)+'"><b>'+esc(c.name)+'</b><i>'+esc(CH().districtOf(c).name)+' \u00b7 '+esc((c.subtypes||[]).join(" + "))+'</i></button>';
        var dd=CH().districtOf(c), st=c.stats||{};
        return '<button class="wsch" data-wspick="'+esc(c.id)+'" style="border-left-color:'+dd.color+'"><b>'+esc(c.name)+'</b>'+
          '<i>'+esc(dd.name)+' · '+esc((c.subtypes||[]).join(" + "))+' · power '+c.powerCap+' · '+c.abilityCap+' abilit'+(c.abilityCap==1?"y":"ies")+'</i>'+
          '<i>HP '+st.hp+' · AC '+st.ac+' · MS '+st.move+' · NRG '+st.nrg+' · INT '+st.int+' · DMG '+st.dmg+'</i></button>';
      }).join("")+'</div>'+
      (rest.length?'<p class="pxnote">'+rest.length+' more chassis are still to be found. The Codex says where.</p>':'')+
      '<div class="pxrow"><button class="ghost" id="wsPickX">Cancel</button></div>';
  }

  /* ---- the editor ---- */
  function allowedFor(ch){
    /* the chassis's keywords that you can use now: free ones, and blueprints you own; a pre-built may use them all */
    if(CUR && CUR.prebuilt) return (ch.allowed||[]).slice();
    return (ch.allowed||[]).filter(function(k){ return !P().isBlueprint(k) || P().owned(k)>=1; });
  }
  function drawEditor(){
    var d=CUR, ch=W().chassisOf(d);
    if(!ch){ HOST.innerHTML='<div class="lts"><p class="pxnote">This design’s chassis is missing.</p><button class="ghost" id="wsBack">Back</button></div>'; return; }
    var dd=CH().districtOf(ch), st=ch.stats||{}, own=allowedFor(ch).length;
    HOST.innerHTML='<div class="lts wss">'+
      '<div class="pxtop"><button class="ghost" id="wsBack" aria-label="Back">←</button>'+
      '<input id="wsName" value="'+esc(d.name)+'" aria-label="Design name"><span id="wsSaved" class="chsaved"></span></div>'+
      '<div class="chband" style="background:'+dd.color+'"></div>'+
      '<div class="wschs"><b>'+esc(ch.name)+'</b><i>'+esc(dd.name)+' · '+esc((ch.subtypes||[]).join(" + "))+' · '+esc(ch.bodyPlan||"")+'</i>'+
        '<i>HP '+st.hp+' · AC '+st.ac+' · MS '+st.move+' · NRG '+st.nrg+' · INT '+st.int+' · DMG '+st.dmg+'</i>'+
        '<i>Attacks up to range '+W().maxOf(ch,"range")+' and AP '+W().maxOf(ch,"ap")+', to-hit '+W().bestHit(ch)+' at best · deploys for '+num(ch.aether&&ch.aether.generic,1)+' Aether'+(num(ch.aether&&ch.aether.affinity,0)?' + '+ch.aether.affinity+' of its District':'')+'</i>'+
        '<i>Power cap '+ch.powerCap+' · '+ch.abilityCap+' abilit'+(ch.abilityCap==1?"y":"ies")+' · you can use '+own+' of its '+(ch.allowed||[]).length+' keywords</i></div>'+
      '<div id="wsAbs"></div>'+
      '<div class="pxrow"><button class="ghost" id="wsAddAct">Add an Action</button><button class="ghost" id="wsAddPas">Add a Passive</button></div>'+
      '<div id="wsResult" class="chresult"></div>'+
      '<div id="wsLook">'+lookHTML(d)+'</div>'+
      (d.prebuilt?'<p class="wslockbar">A pre-built Troop for the Exchange. Only its fit is checked, not what the player owns.</p>':'<p class="pxnote">Designs can be changed only at the dock. A design out on a deployment is locked until it comes home.</p>')+
      '<div class="pxrow"><button class="ghost" id="wsDelete">Delete this design</button></div></div>';
    drawAbs(); drawResult(); paintLooks(); lockView();
  }
  /* v13.0: its look, a skin of its body plan; those that suit its roles first */
  function lookHTML(d){
    var S=window.KETER_SKINS; if(!S) return '';
    var opts=S.optionsFor(d), look=S.lookOf(d), bp=S.bodyPlanOf(d), dv=!!(P()&&P().dev());
    var cv=function(id,w,h){ return id&&window.KETER_PX.get(id)?'<canvas data-wslookpic="'+esc(id)+'" width="'+w+'" height="'+h+'"></canvas>':'<span class="skmiss" style="width:'+w+'px;height:'+h+'px;">none</span>'; };
    var h='<p class="pxsub">Look · '+esc(bp)+'</p>';
    if(!opts.length) return h+'<p class="pxnote">No '+esc(bp)+' skins yet.'+(dv?' Draw one on the Pixel Studio’s Skins tab.':'')+'</p>';
    return h+'<p class="pxnote">Its card art and board token, from the '+esc(bp)+' skins. Those that suit its roles come first; any can be chosen.</p><div class="wslooks">'+opts.map(function(o){
      return '<div class="wslook"><b>'+esc(o.skin.name)+(o.fits?'<i>suits its roles</i>':'')+'</b>'+o.skin.variants.map(function(v){ var on=!!(look&&look.skin===o.skin.id&&look.variant===v.id);
        return '<button class="wslookv'+(on?' on':'')+'" data-wslook="'+esc(o.skin.id+'|'+v.id)+'" aria-pressed="'+on+'"><span>'+cv(v.art,56,38)+cv(v.token,28,28)+'</span><i>'+esc(v.name)+'</i></button>'; }).join('')+'</div>'; }).join('')+'</div>'+
      (dv?'<div class="pxrow"><button class="ghost" id="wsSkins">Skins in the Pixel Studio</button></div>':'');
  }
  function paintLooks(){
    var PXL=window.KETER_PX; if(!PXL||!HOST) return;
    [].slice.call(HOST.querySelectorAll("canvas[data-wslookpic]")).forEach(function(c){ var g=c.getContext("2d"), pic=PXL.get(c.getAttribute("data-wslookpic"));
      g.fillStyle="#0e1418"; g.fillRect(0,0,c.width,c.height); if(pic) PXL.draw(g,pic,1,1,c.width-2,c.height-2,1,{minFill:0.5}); });
  }
  /* the starter, or a design out on a deployment, is shown but not changed */
  function lockView(){
    if(!CUR || !CUR.id || !W().locked(CUR.id)) return;
    var box=HOST.querySelector(".wss"); if(!box) return;
    var why=CUR.starter?"This is the built-in starter, which every deployment brings a few free copies of, so it can't be changed. Copy it to make your own.":"This design is out on a deployment. It can be changed again once the Strike Team is home.";
    var p=document.createElement("p"); p.className="wslockbar"; p.textContent=why;
    var band=box.querySelector(".chband"); if(band) band.parentNode.insertBefore(p, band.nextSibling); else box.insertBefore(p, box.firstChild);
    [].forEach.call(box.querySelectorAll("input,select,textarea"),function(el){ el.disabled=true; });
    [].forEach.call(box.querySelectorAll("button"),function(el){ if(el.classList.contains("wslookv")){ el.disabled=true; return; } if(!/^(wsBack|wsCopyThis)$/.test(el.id)) el.style.display="none"; });
    var row=document.createElement("div"); row.className="pxrow"; row.innerHTML='<button class="ghost" id="wsCopyThis">Copy it to change it</button>';
    p.parentNode.insertBefore(row, p.nextSibling);
  }
  function drawAbs(){
    var h=$("wsAbs"); if(!h) return;
    var ch=W().chassisOf(CUR), nrg=num(ch.stats&&ch.stats.nrg,0), subs=ch.subtypes||[];
    h.innerHTML=(CUR.abilities||[]).map(function(a,i){
      var pas=a.kind==="passive", f=W().fieldsFor(a), pw=W().abilityPower(a,ch);
      /* 14.0: a to-hit goes from the chassis's best (lowest) up to 20 */
      var numIn=function(k,lab){ var lo=W().leastOf(ch,k); return '<label class="chf"><span>'+lab+' <i>'+(k==="hit"?"best "+lo:"max "+W().maxOf(ch,k))+'</i></span><input type="number" min="'+lo+'" max="'+W().maxOf(ch,k)+'" inputmode="numeric" data-wsnum="'+i+':'+k+'" value="'+esc(a[k])+'"></label>'; };
      return '<div class="wsab">'+
        '<div class="pxrow wsabtop"><input class="wsabname" data-wsname="'+i+'" value="'+esc(a.name||"")+'" placeholder="'+(pas?"Passive name":"Action name")+'">'+
          (pas?'<span class="wstag">Passive</span>':'<select data-wsrole="'+i+'">'+subs.map(function(r){ return '<option'+(r===a.role?" selected":"")+'>'+esc(r)+'</option>'; }).join("")+'</select>')+
          '<button class="ghost pxic" data-wsdelab="'+i+'" aria-label="Remove">✕</button></div>'+
        (pas?'':'<div class="chgrid">'+
          '<label class="chf"><span>Energy <i>0–'+nrg+'</i></span><input type="number" min="0" max="'+nrg+'" inputmode="numeric" data-wsnum="'+i+':energy" value="'+esc(a.energy)+'"></label>'+
          (f.indexOf("range")>=0?numIn("range","Range"):"")+(f.indexOf("hit")>=0?numIn("hit","To-Hit"):"")+(f.indexOf("ap")>=0?numIn("ap","AP"):"")+
          /* v13.9: what it fires, in the game */
          (f.indexOf("range")>=0?'<label class="chf"><span>Projectile</span><select data-wsproj="'+i+'">'+W().PROJECTILES.map(function(p){ return '<option value="'+p+'"'+((W().PROJECTILES.indexOf(a.projectile)>=0?a.projectile:"bolt")===p?" selected":"")+'>'+p.charAt(0).toUpperCase()+p.slice(1)+'</option>'; }).join("")+'</select></label>':"")+'</div>')+
        '<textarea rows="2" class="wstext" data-wstext="'+i+'" placeholder="Build it, or write keywords in [[double brackets]]">'+esc(a.text||"")+'</textarea>'+
        '<div class="pxrow" style="align-items:center;"><button class="ghost" data-wsbuild="'+i+'">Build</button><span class="wspow">power <b>'+pw+'</b>'+(W().isAttack(a)?' · '+num(ch.stats&&ch.stats.dmg,0)+' damage':'')+'</span></div></div>';
    }).join("");
  }
  function drawResult(){
    var h=$("wsResult"); if(!h) return;
    var c=W().check(CUR), cost=W().cost(CUR), n=W().affordable(CUR), pct=Math.min(100,Math.round(100*c.power/Math.max(1,c.cap)));
    var R=L().RARITIES;
    h.innerHTML='<div class="chbar"><div style="width:'+pct+'%;background:'+(c.power>c.cap?"var(--danger,#ff4a52)":"var(--cyan)")+'"></div></div>'+
      '<div class="chrow"><span>Power</span><b>'+c.power+' / '+c.cap+'</b></div>'+
      '<div class="chrow"><span>Abilities</span><b>'+c.abilities+' / '+c.abilityCap+'</b></div>'+
      (c.ok?'<p class="chok">✓ This design fits, and you own everything it uses.</p>':'<p class="chbad">✗ '+esc(c.reasons.join("; "))+'.</p>')+
      '<p class="pxsub">One copy costs</p><table class="wscost">'+cost.lines.map(function(l){
        return '<tr><td>'+esc(l.label)+'</td><td>'+costText(l.parts)+'</td></tr>'; }).join("")+
      '<tr class="wstot"><td>In all</td><td>'+costText(cost.parts)+'</td></tr></table>'+
      '<p class="pxnote">Your stockpile could pay for <b>'+n+'</b> cop'+(n===1?"y":"ies")+'. Copies are paid when you deploy.</p>';
  }
  function scheduleSave(){
    clearTimeout(saveT); if($("wsSaved")) $("wsSaved").textContent="Saving…";
    saveT=setTimeout(function(){ var id=W().put(CUR); if(id) CUR.id=id; if($("wsSaved")) $("wsSaved").textContent=id?"Saved":"Could not save"; }, 350);
  }
  function flush(){ clearTimeout(saveT); if(CUR){ var id=W().put(CUR); if(id) CUR.id=id; } }

  /* ---- blueprints ---- */
  function bpHTML(){
    var X=P(), K=window.KETER_KW, s=X.state(), st=L().stock(), out=!!(window.KETER_DEPLOY&&window.KETER_DEPLOY.active());
    var known=X.catalog().filter(function(b){ return X.owned(b.name,s)>=1; });
    var cats=K?K.CATEGORIES:[];
    var rows=cats.map(function(cat){
      var bs=known.filter(function(b){ return b.cat===cat.k; }); if(!bs.length) return "";
      return '<p class="pxsub" style="color:'+cat.colour+'">'+esc(cat.label)+'</p><div class="wsbps">'+bs.map(function(b){
        var have=X.owned(b.name,s), next=have+1, price=next<=b.levels?X.researchPrice(b.name,next):null;
        return '<div class="wsbp"><b>'+esc(b.name)+'</b><i>'+(b.levels>1?'level '+have+' of '+b.levels+' · up to '+b.caps.join(" · "):'owned')+'</i>'+
          (price!=null?'<button class="ghost'+(st.shards>=price&&!out?" primary":"")+'" data-wsres="'+esc(b.name)+'"'+(st.shards>=price&&!out?"":" disabled")+'>Research level '+next+' · '+price+' shards</button>':'')+'</div>';
      }).join("")+'</div>';
    }).join("");
    return '<p class="wsstock">'+st.shards+' Aether shards</p>'+(out?'<p class="wslockbar">Research happens at the dock, which is closed while a Strike Team is out.</p>':'')+
      '<p class="pxnote">Target words, damage, heal and turns are yours from the start. Every other keyword is a blueprint: its first level is found as loot, and levels 2 and 3 are found or researched here.</p>'+
      (MSG?'<p class="wsmsg">'+esc(MSG)+'</p>':'')+
      (known.length?rows:'<p class="pxnote">No blueprints found yet. The Codex says where to look.</p>')+
      (dev()?'<div class="wsdev"><p class="pxsub">Dev Mode</p><div class="pxrow">'+
        '<button class="ghost'+(s.all?" primary":"")+'" id="wsAll">Testing: every blueprint and chassis unlocked · '+(s.all?"on":"off")+'</button>'+
        '<button class="ghost" id="wsReset">Reset progress</button></div></div>':'');
  }

  /* ---- the Workshop's tables ---- */
  function costsHTML(){
    var t=W().tables(), X=P(), R=L().RARITIES;
    var n=function(attr,val,step){ return '<input type="number" class="ltin" '+attr+' value="'+val+'" step="'+(step||"any")+'" min="0" inputmode="decimal">'; };
    var h='<p class="pxsub">A copy</p><div class="chgrid">'+
      '<label class="chf"><span>Rate (parts per power)</span>'+n('data-wst="rate"',t.rate,"0.05")+'</label>'+
      '<label class="chf"><span>Energy baseline</span>'+n('data-wst="energyBase"',t.energyBase,"1")+'</label>'+
      '<label class="chf"><span>+ power per Energy below it</span>'+n('data-wst="energyStep"',t.energyStep,"0.05")+'</label></div>'+
      '<p class="pxnote">A copy costs the chassis cost plus rate × power, in Common Troop parts. An Action cheaper than the baseline counts for more: × (1 + step × each Energy below).</p>'+
      '<p class="pxsub">Attack numbers</p><table class="ltw"><thead><tr><th></th><th>Baseline</th><th>Power per point above</th></tr></thead><tbody>'+
      [["range","Range"],["hit","To-Hit"],["ap","AP"]].map(function(x){ return '<tr><th>'+x[1]+'</th><td>'+n('data-wsn="'+x[0]+':base"',t.numbers[x[0]].base,"1")+'</td><td>'+n('data-wsn="'+x[0]+':per"',t.numbers[x[0]].per,"0.1")+'</td></tr>'; }).join("")+
      '</tbody></table>';
    if(!dev()) return h+'<p class="pxnote">Each blueprint’s levels, research prices and the rarer parts it needs are edited in Dev Mode, which sees every blueprint.</p>'+resetRow();
    var cat=X.catalog(); if(!COSTKW || !X.blueprintOf(COSTKW)) COSTKW=(cat[0]||{}).name||"";
    var b=X.blueprintOf(COSTKW), req=(t.require||{})[COSTKW]||{};
    h+='<p class="pxsub">A blueprint</p><select id="wsCostKw" class="ltsel">'+cat.map(function(x){ return '<option'+(x.name===COSTKW?" selected":"")+'>'+esc(x.name)+'</option>'; }).join("")+'</select>';
    if(b){
      h+='<table class="ltw wsreq"><thead><tr><th>Level</th>'+(b.levels>1?'<th>Up to</th>':'')+'<th>Research</th>'+R.slice(1).map(function(r){ return '<th style="color:'+r.lite+'">'+r.label.slice(0,4)+'</th>'; }).join("")+'</tr></thead><tbody>';
      for(var lv=1;lv<=b.levels;lv++){
        h+='<tr><th>'+lv+'</th>'+(b.levels>1?'<td>'+n('data-wscap="'+lv+'"',b.caps[lv-1],"1")+'</td>':'')+
          '<td>'+(lv===1?'<span class="ltnote">found only</span>':n('data-wsres-price="'+lv+'"',X.researchPrice(COSTKW,lv),"1"))+'</td>'+
          R.slice(1).map(function(r,ri){ return '<td>'+n('data-wsreq="'+lv+':'+(ri+1)+'"',(req[lv]||{})[ri+1]||0,"1")+'</td>'; }).join("")+'</tr>';
      }
      h+='</tbody></table><p class="pxnote">The last columns are the rarer Troop parts a copy needs for using '+esc(COSTKW)+' at that level, on top of the Commons. They start at nothing.</p>';
    }
    return h+resetRow();
  }
  function resetRow(){ return '<div class="pxrow" style="margin-top:10px;"><button class="ghost" id="wsTabReset">Reset the Workshop’s tables</button></div><p class="pxnote" id="wsTSaved"></p>'; }
  function saveCosts(){
    var t=W().tables(), X=P();
    [].forEach.call(HOST.querySelectorAll("[data-wst]"),function(el){ t[el.getAttribute("data-wst")]=Math.max(0,parseFloat(el.value)||0); });
    [].forEach.call(HOST.querySelectorAll("[data-wsn]"),function(el){ var a=el.getAttribute("data-wsn").split(":"); t.numbers[a[0]][a[1]]=parseFloat(el.value)||0; });
    if(COSTKW && X.blueprintOf(COSTKW)){
      var b=X.blueprintOf(COSTKW);
      if(b.levels>1){ var caps=[1,2,3].map(function(l){ var e=HOST.querySelector('[data-wscap="'+l+'"]'); return e?Math.max(1,parseInt(e.value,10)||1):b.caps[l-1]; }); t.caps[COSTKW]=caps; }
      var pr=[0,0,0]; [2,3].forEach(function(l){ var e=HOST.querySelector('[data-wsres-price="'+l+'"]'); if(e) pr[l-1]=Math.max(0,parseInt(e.value,10)||0); }); t.research[COSTKW]=pr;
      var req={}; [].forEach.call(HOST.querySelectorAll("[data-wsreq]"),function(el){ var a=el.getAttribute("data-wsreq").split(":"), v=Math.max(0,parseInt(el.value,10)||0); if(v){ req[a[0]]=req[a[0]]||{}; req[a[0]][a[1]]=v; } });
      if(Object.keys(req).length) t.require[COSTKW]=req; else delete t.require[COSTKW];
    }
    W().saveTables(t); var m=$("wsTSaved"); if(m) m.textContent="Saved on this device.";
  }

  /* ---- events ---- */
  document.addEventListener("click",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var t=e.target.closest?e.target.closest("button"):null; if(!t) return;
    var id=t.id, a;
    if(!CUR){
      if((a=t.getAttribute("data-wstab"))){ TAB=a; PICK=false; MSG=""; draw(); return; }
      if(id==="wsNew"){ PICK=true; draw(); return; }
      if(id==="wsPickX"){ PICK=false; draw(); return; }
      if((a=t.getAttribute("data-wspick"))){ PICK=false; CUR=W().blank(a); W().put(CUR); draw(); return; }
      if(id==="wsNewPre"){ PICK=true; draw(); return; }
      if((a=t.getAttribute("data-wspickpre"))){ PICK=false; CUR=W().blank(a); CUR.prebuilt=true; CUR.order=Date.now(); CUR.name="New pre-built"; W().put(CUR); draw(); return; }
      if((a=t.getAttribute("data-wspreup"))){ var ps=W().prebuilts(), i=ps.map(function(x){ return x.id; }).indexOf(a);
        if(i>0){ var up=ps[i], dn=ps[i-1], o=up.order; up.order=dn.order; dn.order=o; if(up.order===dn.order) up.order=dn.order-1; W().put(up); W().put(dn); } draw(); return; }
      if((a=t.getAttribute("data-wsopen"))){ CUR=W().get(a); draw(); return; }
      if((a=t.getAttribute("data-wscopy"))){ var c=W().get(a); c.id=null; delete c.starter; delete c.mk; c.name=c.name+" copy"; W().put(c); draw(); return; }
      /* (v14.22) raise it a Mark */
      if((a=t.getAttribute("data-wsmk"))){ var dm=W().get(a), mc=W().mkCost(dm); if(!mc) return; var to=W().mkOf(dm)+1, g=W().MK[to-1];
        if(confirm("Raise "+dm.name+" to "+W().MK_NAME[to-1]+"? +"+g.hp+" Health, +"+g.ac+" Armor Class"+(g.move?", +"+g.move+" Movement":"")+" in all, for "+W().mkText(mc)+" Troop parts.")){ var ur=W().upgrade(a); MSG=ur.ok?(dm.name+" raised to "+W().MK_NAME[ur.mk-1]+"."):ur.why; draw(); } return; }
      if((a=t.getAttribute("data-wsdel"))){ if(confirm("Delete this design? Decks that use it lose it.")){ W().remove(a); draw(); } return; }
      if((a=t.getAttribute("data-wsres"))){ var r=P().research(a); MSG=r.ok?("Researched "+a+" level "+r.level+" for "+r.price+" shards."):r.why; draw(); return; }
      if(id==="wsAll"){ P().setUnlockAll(!P().unlockAll()); draw(); return; }
      if(id==="wsReset"){ if(confirm("Reset progress? Every blueprint and chassis found, and everything discovered, is forgotten. Designs and the stockpile stay.")){ P().reset(); draw(); } return; }
      if(id==="wsTabReset"){ if(confirm("Put the Workshop’s tables back to their starting values?")){ W().resetTables(); draw(); } return; }
      return;
    }
    if(id==="wsBack"){ if(!W().locked(CUR.id)) flush(); if(CUR.prebuilt) TAB="prebuilt"; CUR=null; draw(); return; }
    if(id==="wsCopyThis"){ var cp=W().get(CUR.id)||CUR; cp=JSON.parse(JSON.stringify(cp)); cp.id=null; delete cp.starter; cp.name=cp.name+" copy"; var nid=W().put(cp); CUR=nid?W().get(nid):null; draw(); return; }
    if(id==="wsAddAct"||id==="wsAddPas"){ CUR.abilities.push(W().blankAbility(W().chassisOf(CUR), id==="wsAddPas"?"passive":"action")); drawAbs(); drawResult(); scheduleSave(); return; }
    if((a=t.getAttribute("data-wsdelab"))!==null){ CUR.abilities.splice(+a,1); drawAbs(); drawResult(); scheduleSave(); return; }
    if((a=t.getAttribute("data-wsbuild"))!==null && window.KETER_BUILDER){
      var ab=CUR.abilities[+a], ch=W().chassisOf(CUR);
      window.KETER_BUILDER.open({kind:ab.kind==="passive"?"passive":"action", cardType:"troop", role:ab.kind==="passive"?"":String(ab.role||"").toLowerCase(),
        allowed:allowedFor(ch), others:ab.text||"",
        onDone:function(text){ ab.text=((ab.text||"").trim()+" "+text).trim(); drawAbs(); drawResult(); scheduleSave(); }});
      return;
    }
    if((a=t.getAttribute("data-wslook"))){ var lk=a.split("|"); CUR.skin={skin:lk[0], variant:lk[1]}; flush(); var box=$("wsLook"); if(box){ box.innerHTML=lookHTML(CUR); paintLooks(); } return; }
    if(id==="wsSkins"){ flush(); if(window.KETER_STUDIO) window.KETER_STUDIO.tab("skins"); if(window.KETER_GO) window.KETER_GO("studio"); return; }
    if(id==="wsDelete"){ if(confirm("Delete this design?")){ W().remove(CUR.id); CUR=null; draw(); } return; }
  });
  document.addEventListener("input",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var el=e.target, a;
    if(!CUR){ if(el.hasAttribute("data-wst")||el.hasAttribute("data-wsn")||el.hasAttribute("data-wscap")||el.hasAttribute("data-wsres-price")||el.hasAttribute("data-wsreq")){ clearTimeout(saveT); saveT=setTimeout(saveCosts,400); } return; }
    if(el.id==="wsName"){ CUR.name=el.value||"Untitled design"; scheduleSave(); return; }
    if((a=el.getAttribute("data-wsname"))!==null){ CUR.abilities[+a].name=el.value; scheduleSave(); return; }
    if((a=el.getAttribute("data-wstext"))!==null){ CUR.abilities[+a].text=el.value; drawResult(); refreshPow(+a); scheduleSave(); return; }
    if((a=el.getAttribute("data-wsnum"))!==null){ var p=a.split(":"); CUR.abilities[+p[0]][p[1]]=Math.max(0,parseInt(el.value,10)||0); drawResult(); refreshPow(+p[0]); scheduleSave(); return; }
  });
  function refreshPow(i){ var h=$("wsAbs"); if(!h) return; var sp=h.querySelectorAll(".wspow b")[i]; if(sp) sp.textContent=W().abilityPower(CUR.abilities[i],W().chassisOf(CUR)); }
  document.addEventListener("change",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var el=e.target, a;
    if(!CUR){
      if(el.id==="wsCostKw"){ saveCosts(); COSTKW=el.value; draw(); return; }
      if(el.hasAttribute("data-wst")||el.hasAttribute("data-wsn")||el.hasAttribute("data-wscap")||el.hasAttribute("data-wsres-price")||el.hasAttribute("data-wsreq")) saveCosts();
      return;
    }
    if((a=el.getAttribute("data-wsproj"))!==null){ CUR.abilities[+a].projectile=el.value; scheduleSave(); return; }
    if((a=el.getAttribute("data-wsrole"))!==null){ var ab=CUR.abilities[+a]; ab.role=el.value; drawAbs(); drawResult(); scheduleSave(); return; }
  });

  window.KETER_WORKSHOP_UI={render:render, state:function(){ return {tab:TAB, cur:CUR, pick:PICK, msg:MSG}; },
    _open:function(id){ CUR=W().get(id); draw(); }, _tab:function(k){ CUR=null; PICK=false; TAB=k; draw(); }, _flush:flush};
})();
