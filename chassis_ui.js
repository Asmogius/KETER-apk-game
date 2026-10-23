/* ===========================================================================
   The Chassis editor (video game crafting). Hand-design each Troop chassis: its
   District, body plan, role, stats, power cap, ability cap, part cost and which
   keywords it allows. "Try a design" checks abilities against it as you type,
   with the power broken down so a Modifier's multiplying is visible.
   Uses the Forge's shared pieces: the keyword library and its category colours,
   the District colours, and the scoring engine.
   =========================================================================== */
(function(){
  "use strict";
  var C=function(){ return window.KETER_CHASSIS; };
  var HOST=null, CUR=null, TRY=[{role:"Ranged", text:"[[target enemy]] takes [[damage 3]]."}], saveT=null;
  var BODIES=["Bipedal","Quadruped","Quadcopter","Hexapod","Octopod","Other"];
  function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
  function $(id){ return document.getElementById(id); }

  function renderList(){
    var all=C().list(), D=C().DISTRICTS;
    var groups=D.map(function(d){ return {d:d, items:all.filter(function(c){ return String(c.district||"")===d.id; })}; }).filter(function(g){ return g.items.length; });
    HOST.innerHTML='<div class="chs">'+
      '<h2 class="pxh">Chassis</h2>'+
      '<p class="pxnote">Hand-designed frames for crafted Troops. Each sets the stats, a power cap, how many abilities a design may carry, and which keywords it may use.</p>'+
      '<div class="pxrow"><button class="ghost primary" id="chNew">New chassis</button></div>'+
      (groups.length?groups.map(function(g){
        return '<p class="pxsub" style="color:'+g.d.lite+'">'+esc(g.d.name)+'</p><div class="chlist">'+g.items.map(function(c){
          return '<div class="chitem" style="border-left-color:'+g.d.color+'">'+
            '<b>'+esc(c.name)+'</b><i>'+esc(c.bodyPlan||"")+((c.subtypes||[]).length?" \u00b7 "+esc(c.subtypes.join(" + ")):"")+' \u00b7 power '+c.powerCap+' \u00b7 '+c.abilityCap+' abilit'+(c.abilityCap==1?"y":"ies")+' \u00b7 '+(c.allowed||[]).length+' keywords</i>'+
            '<div class="pxrow"><button class="ghost" data-chopen="'+esc(c.id)+'">Edit</button>'+
            '<button class="ghost" data-chcopy="'+esc(c.id)+'">Copy</button>'+
            '<button class="ghost" data-chdel="'+esc(c.id)+'">Delete</button></div></div>';
        }).join("")+'</div>';
      }).join(""):'<p class="pxnote">No chassis yet.</p>')+'</div>';
  }

  function renderEditor(){
    var c=CUR, D=C().DISTRICTS, K=window.KETER_KW, allowed={};
    (c.allowed||[]).forEach(function(k){ allowed[k]=1; });
    var d=C().districtOf(c);
    var sel=function(id,opts,val,lab){ return '<select id="'+id+'">'+opts.map(function(o){ var v=Array.isArray(o)?o[0]:o, t=Array.isArray(o)?o[1]:(o||"\u2014"); return '<option value="'+esc(v)+'"'+(String(v)===String(val)?" selected":"")+'>'+esc(t)+'</option>'; }).join("")+'</select>'; };
    var numIn=function(id,val,lab){ return '<label class="chf"><span>'+lab+'</span><input id="'+id+'" type="number" inputmode="numeric" value="'+esc(val)+'"></label>'; };
    HOST.innerHTML='<div class="chs">'+
      '<div class="pxtop"><button class="ghost" id="chBack" aria-label="Back">\u2190</button>'+
      '<input id="chName" value="'+esc(c.name)+'" aria-label="Chassis name"><span id="chSaved" class="chsaved"></span></div>'+
      '<div class="chband" style="background:'+d.color+'"></div>'+
      '<div class="chgrid">'+
        '<label class="chf"><span>District</span>'+sel("chDistrict",D.map(function(x){ return [x.id,x.name]; }),c.district)+'</label>'+
        '<label class="chf"><span>Body plan</span>'+sel("chBody",BODIES,c.bodyPlan)+'</label>'+
      '</div>'+
      '<p class="pxsub">Subtypes \u00b7 one or two</p><div class="chchips">'+C().SUBTYPES.map(function(r){
        var on=(c.subtypes||[]).indexOf(r)>=0;
        return '<button class="chchip'+(on?" on":"")+'" data-chsub="'+r+'" style="'+(on?"border-color:var(--cyan);color:var(--cyan)":"")+'">'+r+'</button>';
      }).join("")+'</div><p class="pxnote" id="chSubNote" style="display:none;"></p>'+
      '<p class="pxsub">Limits and cost</p><div class="chgrid">'+
        numIn("chPower",c.powerCap,"Power cap")+numIn("chAbil",c.abilityCap,"Abilities")+numIn("chCost",(c.cost||{}).troop,"Troop parts")+
      '</div>'+
      '<p class="pxsub">Stats</p><div class="chgrid">'+
        C().STATS.map(function(s){ return numIn("chSt_"+s[0],(c.stats||{})[s[0]],s[1]); }).join("")+
      '</div>'+
      /* v12.7: what a design's attacks may reach, and its Aether cost to deploy */
      '<p class="pxsub">Attacks · the most range and AP, and the best (lowest) To-Hit</p><div class="chgrid">'+
        numIn("chMaxRange",c.maxRange,"Range")+numIn("chBestHit",c.bestHit,"Best To-Hit")+numIn("chMaxAP",c.maxAP,"AP")+
      '</div>'+
      '<p class="pxsub">Aether cost to deploy a design on it</p><div class="chgrid">'+
        numIn("chAeGen",(c.aether||{}).generic,"Any Affinity")+numIn("chAeAff",(c.aether||{}).affinity,"Its District")+
      '</div>'+
      '<p class="pxsub">Allowed keywords \u00b7 '+(c.allowed||[]).length+' of '+C().chipList().length+'</p>'+
      '<p class="pxnote">A Condition is built from pieces \u2014 a connector (when, if, while), who it is about, and an event or state \u2014 and each piece is allowed on its own. \u201cArchetype\u201d allows every Archetype as a narrowing word.</p>'+
      K.CATEGORIES.map(function(cat){
        var ks=C().chipList().filter(function(k){ return k.cat===cat.k; });
        return '<div class="chcat"><div class="chcathead" style="color:'+cat.colour+'"><b>'+esc(cat.label)+'</b>'+
          '<button class="ghost" data-chall="'+cat.k+'">All</button><button class="ghost" data-chnone="'+cat.k+'">None</button></div>'+
          '<div class="chchips">'+ks.map(function(k){
            var on=!!allowed[k.name];
            return '<button class="chchip'+(on?" on":"")+'" data-chkw="'+esc(k.name)+'" style="'+(on?"border-color:"+cat.colour+";color:"+cat.colour:"")+'">'+esc(k.name)+'</button>';
          }).join("")+'</div></div>';
      }).join("")+
      '<p class="pxsub">Notes</p><textarea id="chNotes" rows="2" class="chnotes">'+esc(c.notes||"")+'</textarea>'+
      '<p class="pxsub">Try a design</p>'+
      '<p class="pxnote">Build each ability\u2019s effects with Build \u2014 it offers only the keywords this chassis allows \u2014 or write them with keywords in [[double brackets]], as in the Forge. The check updates as you go.</p>'+
      '<div id="chTry"></div>'+
      '<div class="pxrow"><button class="ghost" id="chTryAdd">Add an ability</button></div>'+
      '<div id="chResult" class="chresult"></div></div>';
    renderTry(); renderResult();
  }
  function renderTry(){
    var h=$("chTry"); if(!h) return;
    h.innerHTML=TRY.map(function(a,i){
      return '<div class="chtryrow"><select data-chtryrole="'+i+'">'+["Melee","Ranged","Support","Cyber","Passive"].map(function(r){ return '<option'+(a.role===r?" selected":"")+'>'+r+'</option>'; }).join("")+'</select>'+
        '<textarea data-chtry="'+i+'" rows="2">'+esc(a.text)+'</textarea>'+
        '<button class="ghost" data-chtrybuild="'+i+'" title="Build an effect with only what this chassis allows">Build</button>'+
        '<button class="ghost" data-chtrydel="'+i+'" aria-label="Remove">\u2715</button></div>';
    }).join("");
  }
  function renderResult(){
    var h=$("chResult"); if(!h) return;
    var S=window.KETER_SCORE, design={abilities:TRY.map(function(a){ return {text:a.text, role:a.role==="Passive"?"":a.role}; })};
    var r=C().check(CUR, design), pct=Math.min(100, r.cap?Math.round(r.power/r.cap*100):100);
    var rows=design.abilities.map(function(a,i){
      var d=S.keywordDetail(a.text,{attack:a.role==="Melee"||a.role==="Ranged"||a.role==="Cyber"}), p=C().abilityPower(a);
      var why=d?("base "+d.base+(d.mods.length?" \u00d7 "+d.mods.map(function(m){ return m.name+" "+(+m.x.toFixed(2)); }).join(" \u00d7 "):"")):"no keywords, counted as 4";
      return '<div class="chrow"><span>Ability '+(i+1)+'</span><b>'+p+'</b><i>'+esc(why)+'</i></div>';
    }).join("");
    h.innerHTML='<div class="chbar"><div style="width:'+pct+'%;background:'+(r.power>r.cap?"var(--danger,#ff4a52)":"var(--cyan)")+'"></div></div>'+
      '<div class="chrow"><span>Power</span><b>'+r.power+' / '+r.cap+'</b></div>'+
      '<div class="chrow"><span>Abilities</span><b>'+r.abilities+' / '+r.abilityCap+'</b></div>'+rows+
      (r.ok?'<p class="chok">\u2713 This design fits the chassis.</p>':'<p class="chbad">\u2717 '+esc(r.reasons.join("; "))+'.</p>');
  }
  function scheduleSave(){
    clearTimeout(saveT); if($("chSaved")) $("chSaved").textContent="Saving\u2026";
    saveT=setTimeout(function(){ var id=C().put(CUR); if(id) CUR.id=id; if($("chSaved")) $("chSaved").textContent=id?"Saved":"Could not save"; }, 400);
  }
  function readFields(){
    var v=function(id){ var e=$(id); return e?e.value:""; }, n=function(id){ var x=parseFloat(v(id)); return isNaN(x)?0:x; };
    CUR.name=v("chName")||"Untitled chassis"; CUR.district=v("chDistrict"); CUR.bodyPlan=v("chBody");
    CUR.powerCap=n("chPower"); CUR.abilityCap=n("chAbil"); CUR.cost={troop:n("chCost")}; CUR.notes=v("chNotes");
    CUR.stats={}; C().STATS.forEach(function(s){ CUR.stats[s[0]]=n("chSt_"+s[0]); });
    if($("chMaxRange")){ CUR.maxRange=n("chMaxRange"); CUR.bestHit=Math.min(20, Math.max(1, n("chBestHit")||1)); delete CUR.maxHit; CUR.maxAP=n("chMaxAP"); CUR.aether={generic:n("chAeGen"), affinity:n("chAeAff")}; }
  }

  document.addEventListener("click",function(e){
    if(!HOST || !HOST.contains(e.target)) return;
    var t=e.target.closest?e.target.closest("button"):null; if(!t) return;
    var id=t.id, K=window.KETER_KW;
    if(!CUR){
      if(id==="chNew"){ CUR=C().blank(); C().put(CUR); renderEditor(); return; }
      var o=t.getAttribute("data-chopen"); if(o){ CUR=JSON.parse(JSON.stringify(C().get(o))); renderEditor(); return; }
      var cp=t.getAttribute("data-chcopy"); if(cp){ var c=JSON.parse(JSON.stringify(C().get(cp))); c.id=null; c.test=false; c.name=c.name+" copy"; C().put(c); renderList(); return; }
      var dl=t.getAttribute("data-chdel"); if(dl){ if(confirm("Delete this chassis?")){ C().remove(dl); renderList(); } return; }
      return;
    }
    if(id==="chBack"){ readFields(); C().put(CUR); CUR=null; renderList(); return; }
    var sb=t.getAttribute("data-chsub");
    if(sb){
      var subs=CUR.subtypes=CUR.subtypes||[], at=subs.indexOf(sb);
      if(at>=0){ if(subs.length>1) subs.splice(at,1); }
      else if(subs.length>=2){ var n=$("chSubNote"); if(n){ n.textContent="A chassis has at most two subtypes. Untick one first."; n.style.display=""; } return; }
      else subs.push(sb);
      readFields(); renderEditor(); scheduleSave(); return;
    }
    var kw=t.getAttribute("data-chkw");
    if(kw){ var i=CUR.allowed.indexOf(kw); if(i>=0) CUR.allowed.splice(i,1); else CUR.allowed.push(kw); readFields(); renderEditor(); scheduleSave(); return; }
    var ca=t.getAttribute("data-chall"), cn=t.getAttribute("data-chnone");
    if(ca||cn){ var ks=C().chipList().filter(function(k){ return k.cat===(ca||cn); }).map(function(k){ return k.name; });
      CUR.allowed=CUR.allowed.filter(function(k){ return ks.indexOf(k)<0; }); if(ca) CUR.allowed=CUR.allowed.concat(ks);
      readFields(); renderEditor(); scheduleSave(); return; }
    if(id==="chTryAdd"){ TRY.push({role:"Ranged", text:""}); renderTry(); renderResult(); return; }
    var td=t.getAttribute("data-chtrydel"); if(td!==null){ TRY.splice(+td,1); renderTry(); renderResult(); return; }
    /* Revision 15.6: the keyword builder, limited to what this chassis allows */
    var tb=t.getAttribute("data-chtrybuild");
    if(tb!==null && window.KETER_BUILDER){
      var row=TRY[+tb], role=row.role==="Passive"?"":String(row.role).toLowerCase();
      window.KETER_BUILDER.open({kind:row.role==="Passive"?"passive":"action", cardType:"troop", role:role,
        allowed:(CUR.allowed||[]).slice(), others:row.text||"",
        onDone:function(text){ row.text=((row.text||"").trim()+" "+text).trim(); renderTry(); renderResult(); }});
      return;
    }
  });
  document.addEventListener("input",function(e){
    if(!HOST || !CUR || !HOST.contains(e.target)) return;
    var tt=e.target.getAttribute("data-chtry");
    if(tt!==null){ TRY[+tt].text=e.target.value; renderResult(); return; }
    readFields(); renderResult(); scheduleSave();
  });
  document.addEventListener("change",function(e){
    if(!HOST || !CUR || !HOST.contains(e.target)) return;
    var tr=e.target.getAttribute("data-chtryrole");
    if(tr!==null){ TRY[+tr].role=e.target.value; renderResult(); return; }
    readFields(); if(e.target.id==="chDistrict") renderEditor(); else renderResult(); scheduleSave();
  });
  function render(host){ HOST=host||HOST||$("v-chassis"); if(!HOST) return; if(CUR) renderEditor(); else renderList(); }
  window.KETER_CHASSIS_UI={render:render, state:function(){ return CUR; }, tryDesign:function(t){ if(t) TRY=t; renderTry(); renderResult(); return TRY; }};
})();
