/* ===========================================================================
   The keyword builder (Revision 15.6). Builds one effect — one sentence — at a
   time, by walking through the grammar: when it happens, who it is about, who
   it affects, what it does, any Modifiers, how long it lasts. Every step offers
   only what is legal for this kind of ability (and, on a chassis, only what the
   chassis allows); optional steps can be skipped. It ends on a review of the
   whole sentence where any part can be changed, then Insert.

   Shared by the Card Forge and the Chassis editor:
     KETER_BUILDER.open({kind, tag, cardType, role, allowed, sentence, others,
                         cards, onDone(text), onCancel()})
   `kind` is "action" or "passive" (or pass the ability's `tag`). `allowed` is a
   chassis's keyword list, or null for everything. `sentence` reopens an
   existing effect. `others` is the rest of the ability's text, for its power.
   =========================================================================== */
(function(){
"use strict";
var K=function(){ return window.KETER_KW; };
var S=function(){ return window.KETER_SCORE; };
var ST=null, OPT=null, HOST=null;

function esc(s){ return String(s==null?"":s).replace(/[&<>"]/g,function(c){ return {"&":"&amp;","<":"&lt;",">":"&gt;","\"":"&quot;"}[c]; }); }
function kw(name){ return K().byName(name); }
function colourOf(name){ var k=kw(name); var c=k?K().category(k.cat):null; return c?c.colour:"#dce8ee"; }
function allowed(name){
  if(!OPT || !OPT.allowed) return true;
  var k=kw(name), nm=(k&&k.archetype)?"Archetype":name;
  return OPT.allowed.some(function(a){ return String(a).toLowerCase()===String(nm).toLowerCase(); });
}
function tok(p){ return p ? "[["+p.name+(p.n!==null&&p.n!==undefined&&p.n!==""?" "+p.n:"")+"]]" : ""; }
/* Handbook 16.0: the statuses that lock a Unit down, 2 turns at most and never
   always-on (rules.js) */
var LOCKS=["Stunned","Rooted","Pinned","Marked"], LOCK_MAX_TURNS=2;
function isLock(name){ return LOCKS.indexOf(name)>=0; }
function hasLock(){ return ST.effects.some(function(e){ return isLock(e.name); }); }
var DISTRICTS=[["1","Threshold Dynamics"],["2","Halcyon Cognition"],["3","Vantage Robotics"],
  ["4","Lazarus Computing"],["5","Verdant Biogenics"],["6","Meridian Entropics"]];

/* ---- the state and the sentence it makes ---- */
function blank(){ return {when:null, check:null, target:null, effects:[], mods:[], dur:null, adjacent:false, visited:{}}; }
var PLURAL={"all enemies within":1,"all allies within":1,"all units within":1,"all enemies":1,"all allies":1};
var TAKES={"damage":1,"Push":1};
function clauseText(c){
  if(!c) return "";
  var parts=["[["+c.conn+"]]"];
  if(c.subject) parts.push(tok(c.subject));
  (c.narrow||[]).forEach(function(q){ parts.push(tok(q)); });
  if(c.event) parts.push(tok(c.event));
  return parts.join(" ");
}
function build(st){
  var head=[];
  if(st.when) head.push(clauseText(st.when));
  if(st.check) head.push(clauseText(st.check));
  var lead=head.length ? head.join(", ")+", " : "";
  var t=st.target, many=t && PLURAL[t.name];
  var who=t ? [tok(t)].concat((t.narrow||[]).map(tok)).join(" ") : "";
  var take=[], gain=[], other=[], cover=null, sac=null, exe=null, deploy=[], bare=[], barricade=null;
  st.effects.forEach(function(e){
    if(e.name==="Sacrifice") sac=e;
    else if(e.name==="Execute") exe=e;
    else if(e.name==="Deploy") deploy.push(e);
    /* Revision 16.3: Draw and gain Aether are what you do, not something a Unit gains; a Barricade goes on a tile */
    else if(e.name==="Draw"||e.name==="gain Aether") bare.push(e);
    else if(e.name==="Barricade") barricade=e;
    else if(e.name==="Half Cover"||e.name==="Full Cover") cover=e;
    else if(TAKES[e.name]) take.push(e);
    else gain.push(e);
  });
  var bits=[];
  if(take.length) bits.push((many?"take ":"takes ")+take.map(tok).join(" and "));
  if(gain.length) bits.push((many?"gain ":"gains ")+gain.map(tok).join(" and "));
  if(cover) bits.push((many?"count":"counts")+" as behind "+tok(cover));
  var main="";
  /* what else it does happens first, then the Unit is spent */
  if(sac) main=(who||"[[this Unit]]")+" "+(bits.length?bits.join(" and ")+" and ":"")+"is spent as a "+tok(sac);
  /* likewise, what else it does happens first, then the Enemy faces the Execute */
  else if(exe) main=(who?who+" ":"")+(bits.length?bits.join(" and ")+" and ":"")+(many?"face an ":"faces an ")+tok(exe);
  else if(bits.length) main=(who?who+" ":"")+bits.join(" and ");
  if(deploy.length) main=(main?main+" and ":"")+deploy.map(tok).join(" and ")+(st.adjacent?" [[adjacent]]":"");
  if(barricade) main=(main?main+" and ":"")+tok(barricade)+" on "+(who||"[[target tile]]");
  if(bare.length) main=(main?main+". ":"")+bare.map(tok).join(". ");
  var mods=st.mods.map(tok).join(" and ");
  /* a Target with only Modifiers is the attack itself: "target enemy is hit with AoE 1" */
  if(mods) main = main ? main+" with "+mods : (who ? who+(many?" are":" is")+" hit with "+mods : mods);
  if(st.dur){
    if(st.dur.name==="turns") main+=" for "+tok(st.dur);
    else main+=" "+tok(st.dur);
  }
  var out=(lead+main).replace(/\s+/g," ").trim();
  if(!main) out=out.replace(/,\s*$/,"");
  return out ? out+"." : "";
}
/* an existing sentence, read back into the steps */
function fromSentence(sent){
  var st=blank(), an=K().analyse(sent);
  var P=function(p){ return p?{name:p.kw?p.kw.name:p.name, n:p.n}:null; };
  function clause(c){ return c?{conn:c.connector, subject:P(c.subject), narrow:(c.narrow||[]).map(P), event:P(c.event)}:null; }
  st.when=clause(an.when); st.check=clause(an.check);
  an.targets.forEach(function(t){
    if(t.part.kw.name==="adjacent"){ st.adjacent=true; return; }
    if(!st.target) st.target={name:t.part.kw.name, n:t.part.n, narrow:t.narrow.map(P)};
  });
  st.effects=an.effects.map(P).concat(an.covers.map(P));
  st.mods=an.mods.map(P);
  st.dur=P(an.durations[0]);
  /* anything written by hand in the sentence is lost if it is rebuilt */
  st.ownWords = K().render(build(st))!==K().render(sent);
  Object.keys(STEP_BY).forEach(function(k){ st.visited[k]=1; });
  return st;
}

/* ---- what is legal ---- */
function isPassive(){ return OPT.kind==="passive"; }
function isEquip(){ return /equipment/i.test(OPT.cardType||""); }
function always(){ return isPassive() && !ST.when; }
function subjectsFor(conn, isCheck){
  var out=[];
  var add=function(name, label, desc){ if(kw(name) && allowed(name)) out.push({name:name, label:label||name, desc:desc||kw(name).desc}); };
  if(!isPassive()){ add("the target","the target","The Unit this Action is used on."); add("this Unit"); }
  else{
    if(isEquip()) add("attached Unit"); else add("this Unit","this Unit","The Unit whose card this is.");
    if(isCheck && ST.when && ST.when.subject) add("that Unit","that Unit","Whoever the “when” is about.");
  }
  add("an ally"); add("an enemy"); add("any Unit");
  if(conn==="when" && allowed("the round begins")) out.push({name:"", special:"round", label:"the round", desc:"Something about the round itself, not a Unit."});
  return out;
}
function eventsFor(c, isCheck){
  var L=K().KEYWORDS, sn=c.subject?c.subject.name:"";
  var self=(sn==="this Unit"||sn==="attached Unit");
  return L.filter(function(k){
    if(k.cat!=="condition" || !(k.role==="event"||k.role==="state")) return false;
    if(!allowed(k.name) || k.noSubject) return false;
    if(self && k.noSelf) return false;
    if(c.conn==="when") return k.role==="event";
    if(c.conn==="while") return k.role==="state";
    /* if: a state; in an Action, also what the Action itself did */
    if(k.role==="state") return true;
    return !isPassive() && !isCheck && k.actionIf && (sn==="this Unit"||sn==="the target");
  }).filter(function(k){
    if(k.role!=="event" || isPassive()) return true;
    /* what an Action can ask about itself */
    if(sn==="the target") return k.name==="takes damage"||k.name==="is Incapacitated";
    return k.name==="deals damage"||k.name==="kills an enemy";
  });
}
function targetsFor(){
  var out=[], add=function(name, label, desc){ if(kw(name) && allowed(name)) out.push({name:name, label:label||name, desc:desc||kw(name).desc}); };
  if(!isPassive()){
    add("target enemy"); add("target ally"); add("target tile"); add("this Unit");
    add("all enemies within"); add("all allies within"); add("all units within");
    /* Revision 16.3: a whole side, wherever it stands */
    add("all enemies"); add("all allies");
  }else{
    if(isEquip()) add("attached Unit"); else add("this Unit","this Unit","The Unit whose card this is.");
    var about=(ST.when&&ST.when.subject)||(ST.check&&ST.check.subject);
    if(about && about.name!=="this Unit" && about.name!=="attached Unit") add("that Unit","that Unit","Whoever the Condition is about.");
    if(ST.when){
      add("target enemy","target enemy","The Enemy involved in the event — the attacker, or the one hit.");
      add("target ally","target ally","The friendly Unit involved in the event.");
    }
    add("all enemies within","all enemies within","Every Enemy within that many tiles of this Unit.");
    add("all allies within","all allies within","Every friendly Unit within that many tiles of this Unit.");
    add("all units within","all units within","Everything within that many tiles of this Unit.");
    add("all enemies"); add("all allies");
  }
  return out;
}
function narrowFor(){
  var out=[];
  ["Melee","Ranged","Support","Cyber"].forEach(function(n){ if(allowed(n)) out.push({name:n, group:"Subtype"}); });
  /* Revision 16.3: Troop or Hero */
  ["Troop","Hero"].forEach(function(n){ if(kw(n) && allowed(n)) out.push({name:n, group:"Troop or Hero"}); });
  if(allowed("District")) out.push({name:"District", group:"District", param:"district"});
  if(allowed("Archetype") || !OPT.allowed) K().archetypes().forEach(function(a){ if(allowed(a)) out.push({name:a, group:"Archetype"}); });
  return out;
}
function effectsFor(){
  var L=K().KEYWORDS, out=[], tn=ST.target?String(ST.target.name):"";
  L.forEach(function(k){
    if(!allowed(k.name)) return;
    /* an always-on Passive cannot Stun, Root, Pin or Mark (keywords.js says why) */
    if(isLock(k.name) && always()) return;
    /* Sacrifice removes a friendly Unit: not offered where the Target is (or may be) an Enemy */
    if(k.name==="Sacrifice" && ["target enemy","all enemies within","all units within","target tile","all enemies"].indexOf(tn)>=0) return;
    /* Revision 16.3: a Barricade goes on a tile, and only there */
    if(k.name==="Barricade" && tn!=="target tile") return;
    /* Execute removes an Enemy: offered only where the Target is one */
    if(k.name==="Execute" && ["target enemy","all enemies within","all enemies"].indexOf(tn)<0) return;
    if(k.cat==="effect"){ out.push({name:k.name, group:"Effect"}); return; }
    if(k.cat==="status"){ out.push({name:k.name, group:"Status"}); return; }
    if(k.cat==="stats"){ out.push({name:k.name, group:"Stats"}); return; }
    if(k.name==="Half Cover"||k.name==="Full Cover") out.push({name:k.name, group:"Cover"});
  });
  return out;
}
function modsFor(){
  return K().KEYWORDS.filter(function(k){
    if(k.cat!=="modifier" || !allowed(k.name)) return false;
    /* Overclock carries no rules yet, so it is not offered (the Forge flags it where it is used) */
    if(k.name==="Overclock") return false;
    /* Revision 16.1: Lunge and Charge are made with a blow, so only a Melee Action has them */
    if((k.name==="Lunge"||k.name==="Charge") && OPT.role && String(OPT.role).toLowerCase()!=="melee") return false;
    /* Revision 16.3: Line and Cone are shapes an attack makes */
    if((k.name==="Line"||k.name==="Cone") && OPT.role && String(OPT.role).toLowerCase()==="support") return false;
    return isPassive() ? k.name==="Aura" : k.name!=="Aura";
  }).map(function(k){ return {name:k.name, group:"Modifier"}; });
}
function needsDuration(){
  return ST.effects.some(function(e){ var k=kw(e.name); return k && (k.cat==="stats"||k.cat==="status"||k.name==="Half Cover"||k.name==="Full Cover"); });
}
function durRequired(){ return !always() && ST.effects.some(function(e){ var k=kw(e.name); return k && k.cat==="stats"; }); }

/* ---- the steps ---- */
var STEPS=[
  {id:"cond", title:"When does it happen?", optional:false},
  {id:"csubj", title:"Who is it about?", when:function(){ return !!condOf("c"); }},
  {id:"cnarrow", title:"Narrow them down?", optional:true, when:function(){ var c=condOf("c"); return c && c.subject && /^(an ally|an enemy|any Unit)$/.test(c.subject.name); }},
  {id:"cevent", title:"What happens, or what must be true?", when:function(){ var c=condOf("c"); return c && !(c.event && kw(c.event.name) && kw(c.event.name).noSubject); }},
  {id:"check", title:"Check something as well?", optional:true, when:function(){ return isPassive() && !!ST.when; }},
  {id:"ksubj", title:"Who is the check about?", when:function(){ return !!(isPassive() && ST.when && ST.check); }},
  {id:"knarrow", title:"Narrow them down?", optional:true, when:function(){ return isPassive() && ST.when && ST.check && ST.check.subject && /^(an ally|an enemy|any Unit)$/.test(ST.check.subject.name); }},
  {id:"kstate", title:"What must be true?", when:function(){ return !!(isPassive() && ST.when && ST.check); }},
  {id:"target", title:"Who does it affect?", optional:true},
  {id:"tnarrow", title:"Narrow them down?", optional:true, when:function(){ return ST.target && /^(target enemy|target ally|all enemies within|all allies within|all units within|all enemies|all allies)$/.test(ST.target.name); }},
  {id:"effect", title:"What does it do?", optional:false},
  {id:"mods", title:"Any Modifiers?", optional:true, when:function(){ return modsFor().length>0; }},
  {id:"dur", title:"How long does it last?", optional:true, when:function(){ return needsDuration() && !always(); }},
  {id:"review", title:"Review the effect"}
];
var STEP_BY={}; STEPS.forEach(function(s,i){ STEP_BY[s.id]=i; });
/* the Condition being built: the [when], or an Action's/[while]'s check */
function condOf(){
  if(ST.when) return ST.when;
  return (ST.check && (!isPassive() || ST.check.conn==="while")) ? ST.check : null;
}
function setCond(c){
  if(!c){ ST.when=null; ST.check=null; return; }
  if(c.conn==="when"){ ST.when=c; if(ST.check && ST.check.conn!=="if") ST.check=null; }
  else { ST.when=null; ST.check=c; }
}
function stepOn(i){ var s=STEPS[i]; return !s.when || s.when(); }
function complete(id){
  var c=condOf();
  switch(id){
    case "cond": return !!ST.visited.cond;
    case "csubj": return !!(c && (c.subject || (c.event && kw(c.event.name) && kw(c.event.name).noSubject)));
    case "cevent": return !!(c && c.event);
    case "ksubj": return !!(ST.check && ST.check.subject);
    case "kstate": return !!(ST.check && ST.check.event);
    case "effect": return ST.effects.length>0 || ST.mods.length>0 || !!ST.visited.effect;
    case "dur": return !durRequired() || !!ST.dur;
    default: return !!ST.visited[id];
  }
}

/* ---- drawing ---- */
var CSS='.kb-ov{position:fixed;inset:0;z-index:9999;background:rgba(3,8,11,.72);display:flex;align-items:flex-end;justify-content:center;font-family:inherit}'+
'.kb{background:#0f1a20;border:1px solid #29434f;border-radius:10px 10px 0 0;width:100%;max-width:560px;max-height:92vh;display:flex;flex-direction:column;color:#dce8ee;box-shadow:0 -8px 30px rgba(0,0,0,.5)}'+
'@media(min-width:700px){.kb-ov{align-items:center}.kb{border-radius:10px}}'+
'.kb-h{display:flex;align-items:center;gap:8px;padding:12px 14px 6px}.kb-h b{flex:1;font-size:15px;letter-spacing:.02em}'+
'.kb-x{background:none;border:0;color:#8aa0aa;font-size:20px;cursor:pointer;padding:2px 6px}'+
'.kb-sent{margin:0 14px 6px;padding:10px 12px;background:#0a1318;border:1px solid #213843;border-radius:6px;font-size:14px;line-height:1.55;min-height:22px}'+
'.kb-sent i{color:#6d838d}.kb-pow{margin:0 14px 8px;font-size:11.5px;color:#8aa0aa;display:flex;gap:12px;flex-wrap:wrap}.kb-pow b{color:#57d8e3}'+
'.kb-step{padding:4px 14px 2px;font-size:12px;color:#8aa0aa;text-transform:uppercase;letter-spacing:.08em}'+
'.kb-t{padding:0 14px 8px;font-size:16px;font-weight:600}'+
'.kb-b{overflow:auto;padding:0 14px 10px;flex:1}'+
'.kb-o{display:block;width:100%;text-align:left;background:#132229;border:1px solid #223a45;border-radius:6px;padding:10px 12px;margin:0 0 6px;color:#dce8ee;cursor:pointer;font:inherit}'+
'.kb-o:hover,.kb-o:focus-visible{border-color:#57d8e3;outline:none}.kb-o.on{border-color:#57d8e3;background:#15313a}'+
'.kb-o b{display:block;font-size:14px}.kb-o i{display:block;font-style:normal;font-size:11.5px;color:#8aa0aa;margin-top:2px;line-height:1.4}'+
'.kb-g{font-size:11px;color:#8aa0aa;text-transform:uppercase;letter-spacing:.08em;margin:10px 0 6px}'+
'.kb-chips{display:flex;flex-wrap:wrap;gap:6px;margin:0 0 8px}.kb-chip{background:#132229;border:1px solid #2c4a57;border-radius:14px;padding:5px 10px;font-size:12.5px;color:#dce8ee;cursor:pointer;font:inherit}'+
'.kb-chip.on{border-color:currentColor}.kb-chip s{text-decoration:none;opacity:.7;margin-left:6px}'+
'.kb-num{display:flex;align-items:center;gap:8px;margin:8px 0}.kb-num button{width:38px;height:38px;border-radius:6px;background:#132229;border:1px solid #2c4a57;color:#dce8ee;font-size:18px;cursor:pointer}'+
'.kb-num input,.kb-sel{background:#0a1318;border:1px solid #2c4a57;color:#dce8ee;border-radius:6px;padding:8px;font-size:16px;width:80px;text-align:center}.kb-sel{width:100%;text-align:left}'+
'.kb-f{display:flex;gap:8px;padding:10px 14px 14px;border-top:1px solid #1d333d}.kb-f .sp{flex:1}'+
'.kb-btn{background:#132229;border:1px solid #2c4a57;color:#dce8ee;border-radius:6px;padding:9px 14px;font-size:14px;cursor:pointer;font:inherit}'+
'.kb-btn.pri{background:#1c4a55;border-color:#57d8e3;color:#eafcff}.kb-btn[disabled]{opacity:.4;cursor:default}'+
'.kb-rv{display:flex;align-items:flex-start;gap:8px;padding:8px 0;border-bottom:1px solid #1a2e37}.kb-rv span{width:92px;flex:none;font-size:11.5px;color:#8aa0aa;padding-top:2px}.kb-rv div{flex:1;font-size:13.5px;line-height:1.45}'+
'.kb-rv button{flex:none}.kb-bad{color:#ff8a8f;font-size:12.5px;line-height:1.5;margin:8px 0}.kb-note{color:#8aa0aa;font-size:12px;line-height:1.5;margin:6px 0}';
function ensureCss(){
  if(document.getElementById("kbCss")) return;
  var st=document.createElement("style"); st.id="kbCss"; st.textContent=CSS; document.head.appendChild(st);
}
function coloured(text){
  if(!text) return '<i>Your effect will appear here as you build it.</i>';
  return K().displayRuns(text).map(function(r){
    return r.kw ? '<span style="color:'+(r.colour||"#dce8ee")+';font-weight:600">'+esc(r.t)+'</span>' : esc(r.t);
  }).join("");
}
function powerLine(text){
  var sc=S(); if(!sc) return "";
  var attack=/^(melee|ranged|cyber)$/i.test(OPT.role||"");
  var d=sc.keywordDetail(text||"",{});
  var mine=d?d.points:0;
  var total=sc.abilityPower({text:((OPT.others||"")+" "+(text||"")).trim(), role:OPT.role||""});
  return '<span>This effect <b>'+mine+'</b>'+(d&&d.mods.length?' ('+d.base+' × '+d.mods.map(function(m){ return m.name+" "+(+m.x.toFixed(2)); }).join(" × ")+')':'')+'</span>'+
         '<span>Ability power <b>'+total+'</b>'+(attack?' (with its attack)':'')+'</span>'+
         '<span>Conditions are not scored yet</span>';
}
function opt(o, on, extra){
  var c=o.name?colourOf(o.name):"#dce8ee";
  return '<button class="kb-o'+(on?" on":"")+'" data-kb="'+esc(o.key||o.name||o.special||"")+'"'+(extra||"")+'><b style="color:'+c+'">'+esc(o.label||o.name)+'</b>'+
    (o.desc?'<i>'+esc(o.desc)+'</i>':'')+'</button>';
}
function chip(p, i){
  return '<button class="kb-chip on" data-kbdrop="'+i+'" style="color:'+colourOf(p.name)+'">'+esc(K().label({type:"kw",name:p.name,n:p.n,kw:kw(p.name)}))+'<s>✕</s></button>';
}
function paramView(){
  var pp=ST.param, k=kw(pp.name)||{}, h='<p class="kb-note">'+esc(k.desc||"")+'</p>';
  if(pp.kind==="amount"||pp.kind==="signed"){
    h+='<div class="kb-g">'+esc(k.numLabel||"Number")+'</div><div class="kb-num"><button data-kbstep="-1">−</button><input id="kbNum" inputmode="numeric" value="'+esc(pp.value)+'"><button data-kbstep="1">+</button></div>';
  }else if(pp.kind==="status"){
    h+='<div class="kb-g">Which Status</div>'+K().KEYWORDS.filter(function(x){ return x.cat==="status"; }).map(function(x){
      return opt({name:x.name, key:"pv:"+x.name, desc:x.desc}); }).join("");
  }else if(pp.kind==="district"){
    h+='<div class="kb-g">Which District</div>'+DISTRICTS.map(function(d){ return opt({name:"District", label:"District "+d[0]+" · "+d[1], key:"pv:"+d[0]}); }).join("");
  }else if(pp.kind==="what"){
    h+='<div class="kb-g">What to take off</div>'+opt({name:"remove", label:"a piece of Equipment", key:"pv:Equipment"})+
      K().KEYWORDS.filter(function(x){ return x.cat==="status"; }).map(function(x){ return opt({name:x.name, key:"pv:"+x.name}); }).join("");
  }else if(pp.kind==="cover"){
    h+='<div class="kb-g">Which Barricade</div>'+opt({name:"Barricade", label:"Half Cover Barricade", key:"pv:Half"})+opt({name:"Barricade", label:"Full Cover Barricade", key:"pv:Full"});
  }else if(pp.kind==="card"){
    var cards=(OPT.cards||[]);
    h+='<div class="kb-g">How many</div><div class="kb-num"><button data-kbstep="-1">−</button><input id="kbNum" inputmode="numeric" value="'+esc(pp.value)+'"><button data-kbstep="1">+</button></div>'+
      '<div class="kb-g">What</div>'+(cards.length?'<select class="kb-sel" id="kbCard">'+cards.map(function(c){ return '<option>'+esc(c)+'</option>'; }).join("")+'</select>':'<p class="kb-note">No Troop cards to deploy yet.</p>')+
      '<label class="kb-note" style="display:flex;gap:8px;align-items:center;margin-top:10px"><input type="checkbox" id="kbAdj"'+(ST.adjacent?" checked":"")+'> beside this Unit (adjacent), not on a Spawn Tile</label>';
  }
  /* Handbook 15.8: on a card with a variable cost, a keyword's number may be X */
  if(pp.kind==="amount"||pp.kind==="signed"||pp.kind==="card") h+='<div style="margin-top:10px;display:flex;gap:8px;flex-wrap:wrap"><button class="kb-btn pri" data-kb="pv:ok">Use this</button>'+
    (OPT.variable?'<button class="kb-btn" data-kb="pv:X">Use X, the card\u2019s variable cost</button>':'')+'</div>';
  return h;
}
function paramKind(name){
  var k=kw(name); if(!k) return null;
  if(k.num==="amount") return "amount";
  if(k.num==="signed") return "signed";
  if(k.num==="status") return "status";
  if(k.num==="district") return "district";
  if(k.num==="what") return "what";
  if(k.num==="cover") return "cover";
  if(k.num==="card") return "card";
  return null;
}
function defaultValue(name, kind){
  if(kind==="signed") return "+1";
  if(name==="turns") return "2";
  return "1";
}
function body(){
  var s=STEPS[ST.at], h="";
  if(ST.param) return paramView();
  var c=condOf();
  if(s.id==="cond"){
    var none=isPassive()?{key:"none", label:"Always on", desc:"On for as long as its card is active. Stats and Statuses simply hold; damage or healing happens once each round, at Recharge."}
                        :{key:"none", label:"Every time it is used", desc:"No Condition."};
    h+=opt(none, ST.visited.cond && !c);
    if(isPassive()){
      if(allowed("when")) h+=opt({name:"when", key:"when", label:"When something happens…", desc:"Reacts: it happens each time the event does."}, ST.when);
      if(allowed("while")) h+=opt({name:"while", key:"while", label:"While something is true…", desc:"On for as long as a state holds, and off the moment it does not."}, ST.check&&ST.check.conn==="while");
    }else if(allowed("if")) h+=opt({name:"if", key:"if", label:"Only if…", desc:"Checks as the Action resolves; if it is not so, this effect does not happen."}, !!ST.check);
    return h;
  }
  if(s.id==="csubj"||s.id==="ksubj"){
    var cc=s.id==="csubj"?c:ST.check;
    return subjectsFor(cc.conn, s.id==="ksubj").map(function(o){
      return opt(Object.assign({key:o.special?"round":o.name},o), o.special ? (cc.event&&cc.event.name==="the round begins") : (cc.subject&&cc.subject.name===o.name)); }).join("");
  }
  if(s.id==="cnarrow"||s.id==="knarrow"||s.id==="tnarrow"){
    var into=s.id==="cnarrow"?c:(s.id==="knarrow"?ST.check:ST.target), list=into.narrow||[];
    h+='<p class="kb-note">Optional. Two of the same kind mean either will do; different kinds mean both must match.</p>';
    if(list.length) h+='<div class="kb-chips">'+list.map(chip).join("")+'</div>';
    var groups={};
    narrowFor().forEach(function(o){ (groups[o.group]=groups[o.group]||[]).push(o); });
    if(s.id!=="tnarrow" && allowed("within")) (groups["Distance"]=[]).push({name:"within", label:"within N tiles", desc:"Only those that many tiles or fewer from this Unit."});
    Object.keys(groups).forEach(function(g){
      h+='<div class="kb-g">'+esc(g)+'</div><div class="kb-chips">'+groups[g].map(function(o){
        return '<button class="kb-chip" data-kb="'+esc(o.name)+'" style="color:'+colourOf(o.name)+'">'+esc(o.label||o.name)+'</button>'; }).join("")+'</div>';
    });
    return h;
  }
  if(s.id==="cevent"||s.id==="kstate"){
    var ce=s.id==="cevent"?c:ST.check;
    var evs=eventsFor(ce, s.id==="kstate");
    if(!evs.length) return '<p class="kb-note">Nothing fits here'+(OPT.allowed?' on this chassis':'')+'. Go back and choose differently.</p>';
    var ev=evs.filter(function(k){ return k.role==="event"; }), stt=evs.filter(function(k){ return k.role==="state"; });
    if(ev.length) h+='<div class="kb-g">'+(ce.conn==="if"?"What this Action did":"Events")+'</div>'+ev.map(function(k){ return opt({name:k.name, desc:k.desc}, ce.event&&ce.event.name===k.name); }).join("");
    if(stt.length) h+='<div class="kb-g">States</div>'+stt.map(function(k){ return opt({name:k.name, desc:k.desc}, ce.event&&ce.event.name===k.name); }).join("");
    return h;
  }
  if(s.id==="check"){
    h+=opt({key:"none", label:"No", desc:"It happens every time the event does."}, ST.visited.check && !ST.check);
    if(allowed("if")) h+=opt({name:"if", key:"if", label:"Only if…", desc:"Checks a state at that moment: “when this Unit takes damage, if it is below half HP”."}, !!ST.check);
    return h;
  }
  if(s.id==="target"){
    h+='<p class="kb-note">'+(isPassive()?"With no Target, it applies to this Unit.":"Optional for a Deploy or Modifiers alone.")+'</p>';
    h+=targetsFor().map(function(o){ return opt(o, ST.target&&ST.target.name===o.name); }).join("");
    if(ST.target) h+=opt({key:"none", label:"No Target", desc:"Clear the Target."});
    return h;
  }
  if(s.id==="effect"||s.id==="mods"){
    var list2=s.id==="effect"?ST.effects:ST.mods, src=s.id==="effect"?effectsFor():modsFor();
    h+='<p class="kb-note">'+(s.id==="effect"?"Choose one, then add more if it does several things.":"Optional. A Modifier changes how the Action works; several multiply together.")+'</p>';
    if(list2.length) h+='<div class="kb-chips">'+list2.map(chip).join("")+'</div>';
    var g2={};
    src.forEach(function(o){ (g2[o.group]=g2[o.group]||[]).push(o); });
    Object.keys(g2).forEach(function(g){
      h+='<div class="kb-g">'+esc(g)+'</div><div class="kb-chips">'+g2[g].map(function(o){
        return '<button class="kb-chip" data-kb="'+esc(o.name)+'" style="color:'+colourOf(o.name)+'">'+esc(o.name)+'</button>'; }).join("")+'</div>';
    });
    return h;
  }
  if(s.id==="dur"){
    if(!durRequired()) h+=opt({key:"none", label:"The default", desc:"A Status lasts 1 turn when no Duration is given."}, ST.visited.dur && !ST.dur);
    else h+='<p class="kb-note">A Stats change needs a Duration, or it would last no time at all.</p>';
    if(hasLock()) h+='<p class="kb-note">Stunned, Rooted, Pinned and Marked last 2 turns at most.</p>';
    ["turns","persistent","while attached"].forEach(function(n){
      if(!kw(n) || !allowed(n)) return;
      if(n==="while attached" && !isEquip()) return;
      /* a lock lasts 2 turns at most, so it is never open-ended */
      if(n!=="turns" && hasLock()) return;
      h+=opt({name:n, label:n==="turns"?"for N turns":n, desc:kw(n).desc}, ST.dur&&ST.dur.name===n);
    });
    return h;
  }
  if(s.id==="review") return review();
  return h;
}
function review(){
  var text=build(ST), an=K().analyse(text), probs=text?K().problems(an,{kind:OPT.kind, variable:(OPT.variable===undefined?undefined:!!OPT.variable)}):["the effect is empty"];
  if(durRequired() && !ST.dur) probs.push("a Stats change needs a Duration");
  if(!ST.effects.length && !ST.mods.length) probs.push("it does nothing yet: choose what it does");
  var row=function(label, html, step){
    return '<div class="kb-rv"><span>'+label+'</span><div>'+html+'</div><button class="kb-btn" data-kbedit="'+step+'">Change</button></div>'; };
  var c=condOf(), h='';
  h+=row("Condition", c ? coloured(clauseText(c)) : '<i style="color:#6d838d">'+(isPassive()?"Always on":"Every time it is used")+'</i>', "cond");
  if(isPassive() && ST.when) h+=row("Check", ST.check ? coloured(clauseText(ST.check)) : '<i style="color:#6d838d">None</i>', "check");
  h+=row("Target", ST.target ? coloured([tok(ST.target)].concat((ST.target.narrow||[]).map(tok)).join(" ")) : '<i style="color:#6d838d">'+(isPassive()?"This Unit":"None")+'</i>', "target");
  h+=row("Does", ST.effects.length ? coloured(ST.effects.map(tok).join(" and ")) : '<i style="color:#6d838d">Nothing yet</i>', "effect");
  if(modsFor().length) h+=row("Modifiers", ST.mods.length ? coloured(ST.mods.map(tok).join(" and ")) : '<i style="color:#6d838d">None</i>', "mods");
  if(needsDuration() && !always()) h+=row("Lasts", ST.dur ? coloured(ST.dur.name==="turns"?"for "+tok(ST.dur):tok(ST.dur)) : '<i style="color:#6d838d">The default</i>', "dur");
  if(ST.ownWords) h+='<p class="kb-note">This effect had words of your own in it. Inserting replaces it with the built sentence; add flavour back in the Rules text afterwards.</p>';
  if(probs.length) h+='<div class="kb-bad">✗ '+probs.map(esc).join('<br>✗ ')+'</div>';
  ST.problems=probs;
  return h;
}
function draw(){
  var s=STEPS[ST.at], text=build(ST);
  /* later steps appear as earlier choices call for them, so only this step's number is shown */
  var shown=STEPS.filter(function(x,i){ return stepOn(i); }), n=shown.indexOf(s)+1;
  var last=s.id==="review";
  HOST.innerHTML='<div class="kb" role="dialog" aria-label="Build an effect">'+
    '<div class="kb-h"><b>'+(OPT.sentence?"Edit an effect":"Build an effect")+'</b><button class="kb-x" data-kb="x" aria-label="Close">✕</button></div>'+
    '<div class="kb-sent" id="kbSent">'+coloured(text)+'</div>'+
    '<div class="kb-pow" id="kbPow">'+powerLine(text)+'</div>'+
    '<div class="kb-step">'+(last?"Review":"Step "+n)+(s.optional&&!last?" · optional":"")+'</div>'+
    '<div class="kb-t">'+esc(ST.param?(ST.param.label||ST.param.name):s.title)+'</div>'+
    '<div class="kb-b" id="kbBody">'+body()+'</div>'+
    '<div class="kb-f">'+
      '<button class="kb-btn" data-kb="back"'+(ST.at===0&&!ST.param?" disabled":"")+'>Back</button>'+
      (s.optional&&!last&&!ST.param?'<button class="kb-btn" data-kb="skip">Skip</button>':'')+
      '<span class="sp"></span>'+
      (last?'<button class="kb-btn pri" data-kb="insert"'+((ST.problems||[]).length?" disabled":"")+'>'+(OPT.sentence?"Replace":"Insert")+'</button>'
           :(ST.param?'':'<button class="kb-btn pri" data-kb="next"'+(canNext()?"":" disabled")+'>Next</button>'))+
    '</div></div>';
  if(last && (ST.problems||[]).length){ var ib=HOST.querySelector('[data-kb="insert"]'); if(ib) ib.disabled=true; }
}
function canNext(){
  var s=STEPS[ST.at];
  if(s.optional) return true;
  if(s.id==="effect") return ST.effects.length>0 || (!isPassive());
  return complete(s.id);
}
function go(i){ ST.param=null; ST.at=i; draw(); }
function next(){
  var s=STEPS[ST.at]; ST.visited[s.id]=1;
  for(var i=ST.at+1;i<STEPS.length;i++){
    if(!stepOn(i)) continue;
    /* changing one part from the review returns there once nothing else is missing */
    if(ST.editing && STEPS[i].id!=="review" && (STEPS[i].optional ? true : complete(STEPS[i].id))) continue;
    return go(i);
  }
  go(STEPS.length-1);
}
function back(){
  if(ST.param){ ST.param=null; draw(); return; }
  for(var i=ST.at-1;i>=0;i--) if(stepOn(i)) return go(i);
}
function beginParam(name, into, label){
  var kind=paramKind(name);
  if(!kind){ into(null); return; }
  ST.param={name:name, kind:kind, value:defaultValue(name,kind), into:into, label:label||name};
  draw();
  var inp=document.getElementById("kbNum"); if(inp) try{ inp.focus(); inp.select(); }catch(e){}
}
function pick(key){
  var s=STEPS[ST.at], c=condOf();
  if(s.id==="cond"){
    ST.visited.cond=1;
    if(key==="none"){ setCond(null); return next(); }
    var had=condOf();
    if(!had || had.conn!==key) setCond({conn:key, subject:null, narrow:[], event:null});
    return next();
  }
  if(s.id==="csubj"||s.id==="ksubj"){
    var cc=s.id==="csubj"?c:ST.check;
    if(key==="round"){ cc.subject=null; cc.narrow=[]; cc.event={name:"the round begins", n:null}; return next(); }
    if(!cc.subject || cc.subject.name!==key){ cc.subject={name:key, n:null}; cc.narrow=[];
      if(cc.event && (kw(cc.event.name)||{}).noSubject) cc.event=null;
      if(cc.event && (key==="this Unit"||key==="attached Unit") && (kw(cc.event.name)||{}).noSelf) cc.event=null; }
    return next();
  }
  if(s.id==="cevent"||s.id==="kstate"){
    var ce=s.id==="cevent"?c:ST.check;
    return beginParam(key, function(v){ ce.event={name:key, n:v}; next(); });
  }
  if(s.id==="check"){
    ST.visited.check=1;
    if(key==="none"){ ST.check=null; return next(); }
    if(!ST.check) ST.check={conn:"if", subject:null, narrow:[], event:null};
    return next();
  }
  if(s.id==="cnarrow"||s.id==="knarrow"||s.id==="tnarrow"){
    var into=s.id==="cnarrow"?c:(s.id==="knarrow"?ST.check:ST.target);
    into.narrow=into.narrow||[];
    return beginParam(key, function(v){
      /* one distance at most; a word already chosen is not added twice */
      if(key==="within") into.narrow=into.narrow.filter(function(q){ return q.name!=="within"; });
      if(!into.narrow.some(function(q){ return q.name===key && String(q.n||"")===String(v||""); })) into.narrow.push({name:key, n:v});
      ST.param=null; draw();
    }, key);
  }
  if(s.id==="target"){
    if(key==="none"){ ST.target=null; return draw(); }
    return beginParam(key, function(v){
      var keep=ST.target&&ST.target.name===key ? ST.target.narrow : [];
      ST.target={name:key, n:v, narrow:keep}; next(); });
  }
  if(s.id==="effect"||s.id==="mods"){
    var list=s.id==="effect"?ST.effects:ST.mods;
    return beginParam(key, function(v){
      list.push({name:key, n:v});
      ST.param=null; draw(); }, key);
  }
  if(s.id==="dur"){
    ST.visited.dur=1;
    if(key==="none"){ ST.dur=null; return next(); }
    return beginParam(key, function(v){ ST.dur={name:key, n:v}; next(); }, key==="turns"?"How many turns":key);
  }
}
function onClick(e){
  var t=e.target.closest?e.target.closest("button,[data-kb]"):null;
  if(e.target===HOST){ close(); return; }
  if(!t) return;
  var k=t.getAttribute("data-kb"), drop=t.getAttribute("data-kbdrop"), edit=t.getAttribute("data-kbedit"), stp=t.getAttribute("data-kbstep");
  if(stp!==null){
    var inp=document.getElementById("kbNum"); if(!inp) return;
    var v=parseInt(String(inp.value).replace(/[^0-9-]/g,""),10); if(isNaN(v)) v=0;
    v+=+stp;
    if(ST.param.kind==="signed"){ if(v===0) v=+stp; inp.value=(v>0?"+":"")+v; }
    else { var lo=ST.param.name==="turns"?2:(ST.param.name==="is within"||ST.param.name==="within"?0:1); inp.value=Math.max(lo, ST.param.name==="turns"?Math.min(hasLock()?LOCK_MAX_TURNS:10,v):v); }
    return;
  }
  if(drop!==null){
    var s=STEPS[ST.at], c=condOf();
    var list=s.id==="effect"?ST.effects:s.id==="mods"?ST.mods:s.id==="cnarrow"?c.narrow:s.id==="knarrow"?ST.check.narrow:ST.target.narrow;
    list.splice(+drop,1); draw(); return;
  }
  if(edit){ ST.editing=true; go(STEP_BY[edit]); return; }
  if(k==="x"){ close(); return; }
  if(k==="back"){ back(); return; }
  if(k==="skip"){ next(); return; }
  if(k==="next"){ next(); return; }
  if(k==="insert"){ var text=build(ST); var cb=OPT.onDone; ST=null; HOST.remove(); HOST=null; if(cb) cb(text); return; }
  if(k && k.indexOf("pv:")===0){
    var pp=ST.param, val=k.slice(3);
    if(val==="ok" || (val==="X" && (pp.kind==="amount"||pp.kind==="signed"||pp.kind==="card"))){
      var inp2=document.getElementById("kbNum"), raw=inp2?String(inp2.value).trim():"";
      /* X, typed into the box or asked for with its button, stands for the number */
      var useX=!!OPT.variable && (val==="X" || /^[+\-−]?x$/i.test(raw));
      if(pp.kind==="signed"){
        if(useX) val=(/^[\-−]/.test(raw)?"-":"+")+"X";
        else { raw=raw.replace(/[^0-9+\-−]/g,"").replace("−","-")||"+1"; if(!/^[+-]/.test(raw)) raw="+"+raw; val=raw; }
      }
      else if(pp.kind==="card"){ var cd=document.getElementById("kbCard"), adj=document.getElementById("kbAdj");
        if(!cd){ return; } ST.adjacent=!!(adj&&adj.checked); val=(useX?"X":(raw.replace(/[^0-9]/g,"")||"1"))+" "+cd.value; }
      else val=useX?"X":(raw.replace(/[^0-9]/g,"")||"1");
      /* a lock lasts 2 turns at most */
      if(pp.name==="turns" && hasLock()) val=String(Math.max(1, Math.min(LOCK_MAX_TURNS, parseInt(val,10)||LOCK_MAX_TURNS)));
    }
    var into=pp.into; ST.param=null; into(val); return;
  }
  if(k!==null && k!==undefined) pick(k);
}
function close(){ var cb=OPT&&OPT.onCancel; ST=null; if(HOST){ HOST.remove(); HOST=null; } if(cb) cb(); }
function open(o){
  if(!K() || !K().analyse) return false;
  OPT=Object.assign({}, o||{});
  if(!OPT.kind) OPT.kind=K().kindOf(OPT.tag);
  ensureCss();
  if(HOST) HOST.remove();
  HOST=document.createElement("div"); HOST.className="kb-ov";
  HOST.addEventListener("click", onClick);
  HOST.addEventListener("keydown", function(e){ if(e.key==="Escape") close(); });
  document.body.appendChild(HOST);
  if(OPT.sentence){ ST=fromSentence(OPT.sentence); ST.at=STEPS.length-1; }
  else { ST=blank(); ST.at=0; }
  draw();
  return true;
}
window.KETER_BUILDER={open:open, close:close, build:build, fromSentence:function(s,o){ OPT=Object.assign({kind:"action"},o||{}); if(!OPT.kind) OPT.kind=K().kindOf(OPT.tag); return fromSentence(s); },
  state:function(){ return ST; }, isOpen:function(){ return !!HOST; },
  /* what the builder would offer, for the checks: an ability's kind and role, and a Target picked */
  offers:function(o, target){ var keepO=OPT, keepS=ST; OPT=Object.assign({kind:"action"},o||{}); ST=blank(); if(target) ST.target={name:target, narrow:[]};
    var r={targets:targetsFor().map(function(x){ return x.name; }), mods:modsFor().map(function(x){ return x.name; }),
      effects:effectsFor().map(function(x){ return x.name; }), narrow:narrowFor().map(function(x){ return x.name; })};
    OPT=keepO; ST=keepS; return r; }};
})();
