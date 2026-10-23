/* ===========================================================================
   KETER skins (v13.0) — how things look, chosen rather than drawn.

   A skin is a card art and a board token that go together, in one or more
   colour variants. You draw every skin in Dev Mode (the Pixel Studio's Skins
   tab); players only choose, and every skin is free.

   Who wears them:
   - Troop designs, pre-built Troops included: the skins of the design's
     chassis's body plan (Bipedal, Quadcopter, Quadruped, Hexapod, Octopod).
     Skins tagged with one of the design's roles are offered first; any can be
     picked. A design with no choice wears the first on offer.
   - Heroes: chosen once, on the Hero's card, and worn everywhere. The card's
     own art is the default.
   - Enemies: a random look each time one spawns, from its card's own token and
     any skins drawn for it.

   Every body plan has a stand-in skin (shipped pictures px_skin_<plan>_*), so
   no design goes without a look. Art drawn for a design before v13.0 becomes a
   skin of its body plan, and that design goes on wearing it.
   =========================================================================== */
(function(){
  "use strict";
  var KEY="keter-app-skins", CHOICE_KEY="keter-app-skin-choice";
  var PX=function(){ return window.KETER_PX; }, WS=function(){ return window.KETER_WORKSHOP; }, PR=function(){ return window.KETER_PROG; };
  var BODY_PLANS=["Bipedal","Quadcopter","Quadruped","Hexapod","Octopod"], ROLES=["Melee","Ranged","Support","Cyber"];
  var KIND_LABEL={body:"Body plan", hero:"Hero", enemy:"Enemy"};

  function clone(o){ return JSON.parse(JSON.stringify(o)); }
  /* read often (every design card asks), so each store is parsed once per change */
  var MEMO={};
  function read(k,d){ var raw=null; try{ raw=localStorage.getItem(k); }catch(e){} if(MEMO[k] && MEMO[k].raw===raw) return clone(MEMO[k].val);
    var v=d; try{ v=raw?JSON.parse(raw):d; }catch(e){ v=d; } MEMO[k]={raw:raw, val:v}; return v==null?d:clone(v); }
  function write(k,v){ try{ var s=JSON.stringify(v); localStorage.setItem(k,s); MEMO[k]={raw:s, val:JSON.parse(s)}; return true; }catch(e){ return false; } }
  function newId(p){ return (p||"sk_")+Date.now().toString(36)+Math.random().toString(36).slice(2,6); }

  /* ---- the stand-ins: one per body plan ---- */
  function builtins(){
    return BODY_PLANS.map(function(bp,i){ var k=bp.toLowerCase();
      return {id:"sk_std_"+k, name:bp+" stand-in", owner:{kind:"body", key:bp}, roles:[], builtin:true, order:i,
        variants:[{id:"v1", name:"Standard", art:"px_skin_"+k+"_art", token:"px_skin_"+k+"_token"}]}; });
  }

  /* ---- the store: {v, skins:[], gone:[builtin ids deleted], migrated:{designId:1}} ---- */
  function state(){
    var s=read(KEY,null)||{v:1, skins:[], gone:[], migrated:{}};
    s.skins=Array.isArray(s.skins)?s.skins:[]; s.gone=s.gone||[]; s.migrated=s.migrated||{};
    var have={}; s.skins.forEach(function(k){ have[k.id]=1; });
    builtins().forEach(function(b){ if(!have[b.id] && s.gone.indexOf(b.id)<0) s.skins.push(b); });
    s.skins.forEach(function(k){ k.roles=k.roles||[]; k.variants=(k.variants&&k.variants.length)?k.variants:[{id:"v1", name:"Standard", art:null, token:null}]; });
    return s;
  }
  function save(s){ return write(KEY,s); }
  function all(){ return state().skins; }
  function get(id){ return all().filter(function(k){ return k.id===id; })[0]||null; }
  function forOwner(kind, key){
    return all().filter(function(k){ return k.owner && k.owner.kind===kind && String(k.owner.key)===String(key); })
      .sort(function(a,b){ return (a.order||0)-(b.order||0) || String(a.name).localeCompare(String(b.name)); });
  }
  function update(id, fn){ var s=state(), k=s.skins.filter(function(x){ return x.id===id; })[0]; if(!k) return null; fn(k); save(s); return k; }
  function add(owner, name){
    var s=state(), mine=s.skins.filter(function(k){ return k.owner.kind===owner.kind && String(k.owner.key)===String(owner.key); });
    var k={id:newId(), name:name||"New skin", owner:{kind:owner.kind, key:String(owner.key)}, roles:[], order:mine.length?Math.max.apply(null,mine.map(function(x){ return x.order||0; }))+1:0,
      variants:[{id:"v1", name:"Standard", art:null, token:null}]};
    s.skins.push(k); save(s); return k;
  }
  function remove(id){
    var s=state(), k=s.skins.filter(function(x){ return x.id===id; })[0]; if(!k) return false;
    s.skins=s.skins.filter(function(x){ return x.id!==id; }); if(k.builtin && s.gone.indexOf(id)<0) s.gone.push(id);
    save(s); return true;
  }
  /* the stand-ins you deleted, back again */
  function restoreBuiltins(){ var s=state(); s.gone=[]; save(s); return all().filter(function(k){ return k.builtin; }).length; }
  function variantOf(k, vid){ return k ? (k.variants.filter(function(v){ return v.id===vid; })[0]||null) : null; }
  function setPic(id, vid, kind, picId){ return update(id, function(k){ var v=variantOf(k,vid); if(v) v[kind]=picId||null; }); }
  function removeVariant(id, vid){
    var k=get(id); if(!k || k.variants.length<2) return false;
    update(id, function(x){ x.variants=x.variants.filter(function(v){ return v.id!==vid; }); }); return true;
  }
  /* a colour variant starts as a copy of another: its pictures copied, never shared */
  function addVariant(id, fromVid){
    var k=get(id); if(!k) return null; var src=variantOf(k, fromVid)||k.variants[0], P=PX();
    var n=k.variants.length+1, vid="v"+Date.now().toString(36);
    var v={id:vid, name:"Variant "+n, art:(src&&src.art&&P&&P.get(src.art))?P.copy(src.art):null, token:(src&&src.token&&P&&P.get(src.token))?P.copy(src.token):null};
    [["art",v.art],["token",v.token]].forEach(function(x){ if(!x[1]) return; var p=P.get(x[1]); if(p){ p.name=k.name+" · "+v.name+" "+x[0]; delete p.shipped; P.put(p,x[1]); } });
    update(id, function(x){ x.variants.push(v); }); return v;
  }

  /* ---- recolouring: swap palette colours across a variant's art and token ---- */
  function picsOfVariant(v){ var P=PX(); return ["art","token"].map(function(kd){ return v&&v[kd]&&P?P.get(v[kd]):null; }); }
  function colours(id, vid){
    var k=get(id), v=variantOf(k,vid), P=PX(), used={};
    picsOfVariant(v).forEach(function(pic){ if(!pic) return; var n=pic.w*pic.h;
      (pic.frames||[]).forEach(function(fr){ (fr.layers||[]).forEach(function(L){ var a=P.decode(L.px,n); for(var i=0;i<n;i++) if(a[i]) used[a[i]]=(used[a[i]]||0)+1; }); }); });
    return Object.keys(used).map(Number).sort(function(a,b){ return used[b]-used[a]; }).map(function(c){ return {c:c, n:used[c]}; });
  }
  /* map: {from colour: to colour}; applied to every layer of both pictures at once */
  function recolour(id, vid, map){
    var k=get(id), v=variantOf(k,vid), P=PX(), changed=0; if(!v||!P) return 0;
    var m={}; Object.keys(map||{}).forEach(function(f){ var t=+map[f]; if(+f && t>=0 && t!==+f) m[+f]=t; });
    if(!Object.keys(m).length) return 0;
    ["art","token"].forEach(function(kd){
      var pic=v[kd]&&P.get(v[kd]); if(!pic) return; var n=pic.w*pic.h;
      (pic.frames||[]).forEach(function(fr){ (fr.layers||[]).forEach(function(L){ var a=P.decode(L.px,n), hit=false;
        for(var i=0;i<n;i++){ var t=m[a[i]]; if(t!==undefined){ a[i]=t; hit=true; changed++; } } if(hit) L.px=P.encode(a); }); });
      delete pic.shipped; pic.flat=""; P.put(pic, v[kd]);
    });
    return changed;
  }

  /* ---- designs ---- */
  function bodyPlanOf(d){ var P=PR(), ch=d&&P?P.chassisGet(d.chassis):null; return (ch&&ch.bodyPlan)||"Bipedal"; }
  /* its roles: its Actions' roles, or failing those its chassis's subtypes */
  function rolesOf(d){
    var r=[]; (d&&d.abilities||[]).forEach(function(a){ if(a.kind!=="passive" && a.role && r.indexOf(a.role)<0) r.push(a.role); });
    if(!r.length){ var P=PR(), ch=d&&P?P.chassisGet(d.chassis):null; (ch&&ch.subtypes||[]).forEach(function(x){ if(r.indexOf(x)<0) r.push(x); }); }
    return r;
  }
  function fits(k, roles){ return (k.roles||[]).some(function(x){ return roles.indexOf(x)>=0; }); }
  /* the skins on offer, those that fit its roles first */
  function optionsFor(d){
    var roles=rolesOf(d), list=forOwner("body", bodyPlanOf(d));
    var yes=list.filter(function(k){ return fits(k,roles); }), no=list.filter(function(k){ return !fits(k,roles); });
    return yes.map(function(k){ return {skin:k, fits:true}; }).concat(no.map(function(k){ return {skin:k, fits:false}; }));
  }
  function lookOf(d){
    var opts=optionsFor(d), c=d&&d.skin;
    if(c){ var o=opts.filter(function(x){ return x.skin.id===c.skin; })[0]; if(o){ var v=variantOf(o.skin,c.variant)||o.skin.variants[0]; return {skin:o.skin.id, variant:v.id, chosen:true}; } }
    /* no choice: the first on offer that has been drawn (a skin still blank is never the default) */
    var P=PX(), has=function(id){ return !!(id && P && (P.has?P.has(id):P.get(id))); };
    var drawnV=function(k){ return k.variants.filter(function(v){ return has(v.art)||has(v.token); })[0]||null; };
    for(var i=0;i<opts.length;i++){ var dv=drawnV(opts[i].skin); if(dv) return {skin:opts[i].skin.id, variant:dv.id, chosen:false}; }
    return opts.length ? {skin:opts[0].skin.id, variant:opts[0].skin.variants[0].id, chosen:false} : null;
  }
  function picsOf(look){ if(!look) return null; var v=variantOf(get(look.skin), look.variant); return v?{art:v.art||null, token:v.token||null}:null; }
  function picsOfDesign(d){ return picsOf(lookOf(d)); }
  /* choosing: the design keeps {skin, variant} */
  function chooseForDesign(id, skin, variant){
    var W=WS(); if(!W) return false; var d=W.get(id); if(!d) return false;
    d.skin=skin?{skin:skin, variant:variant||"v1"}:null; return !!W.put(d);
  }

  /* ---- Heroes: chosen once, worn everywhere; the card's own art by default ---- */
  function choices(){ var c=read(CHOICE_KEY,null)||{}; c.hero=c.hero||{}; return c; }
  function heroLook(name){ var c=choices().hero[name]; if(!c) return null; var k=get(c.skin); if(!k || !k.owner || k.owner.kind!=="hero" || k.owner.key!==name) return null;
    var v=variantOf(k,c.variant)||k.variants[0]; return {skin:k.id, variant:v.id}; }
  function setHeroLook(name, look){ var c=choices(); if(look && look.skin) c.hero[name]={skin:look.skin, variant:look.variant||"v1"}; else delete c.hero[name]; return write(CHOICE_KEY,c); }
  function heroPics(card){ return card ? picsOf(heroLook(card.name)) : null; }

  /* ---- Enemies: a random look each spawn ---- */
  function enemyLooks(card){
    var P=PX(), out=[]; if(!card || !P) return out;
    var own=P.pictureFor(card,"token")||(card._raw?P.pictureFor(card._raw,"token"):null); if(own && own.id) out.push(own.id);
    forOwner("enemy", card.name).forEach(function(k){ k.variants.forEach(function(v){ if(v.token && P.get(v.token)) out.push(v.token); }); });
    return out;
  }
  function pickEnemy(card, rnd){ var l=enemyLooks(card); if(l.length<2) return null; return l[Math.floor((rnd||Math.random)()*l.length)]; }

  /* ---- any card: the picture it wears ---- */
  function isHero(c){ return c && /^hero$/i.test(String(c.cardType||"")); }
  function picFor(card, kind){
    var P=PX(); if(!P || !card) return null;
    if(isHero(card)){ var h=heroPics(card); if(h && h[kind]){ var p=P.get(h[kind]); if(p) return p; } }
    return P.pictureFor(card,kind)||(card._raw?P.pictureFor(card._raw,kind):null);
  }

  /* ---- before v13.0 a design's art was drawn for it; now it becomes a skin ---- */
  function migrate(){
    var W=WS(), P=PX(); if(!W || !P) return 0;
    var s=state(), L=P.links(), n=0, list=[];
    try{ list=W.list().concat(W.prebuilts?W.prebuilts():[]); }catch(e){ return 0; }
    list.forEach(function(d){
      if(!d || d.starter || s.migrated[d.id]) return;
      if(d.skin){ s.migrated[d.id]=1; return; }
      var e=L[d.id]||{}, art=d.pixelArt||e.art, tok=d.pixelToken||e.token;
      art=art&&P.get(art)?art:null; tok=tok&&P.get(tok)?tok:null;
      if(!art && !tok){ s.migrated[d.id]=1; return; }
      if(W.locked && W.locked(d.id)) return;          /* out on a deployment: next time */
      var k={id:newId(), name:d.name||"Design", owner:{kind:"body", key:bodyPlanOf(d)}, roles:rolesOf(d), order:100+n,
        variants:[{id:"v1", name:"Original", art:art, token:tok}]};
      s.skins.push(k); s.migrated[d.id]=1; save(s);
      d.skin={skin:k.id, variant:"v1"}; W.put(d); s=state(); n++;
    });
    save(s); return n;
  }

  window.KETER_SKINS={KEY:KEY, CHOICE_KEY:CHOICE_KEY, BODY_PLANS:BODY_PLANS, ROLES:ROLES, KIND_LABEL:KIND_LABEL,
    state:state, all:all, get:get, forOwner:forOwner, update:update, add:add, remove:remove, restoreBuiltins:restoreBuiltins,
    variantOf:variantOf, setPic:setPic, addVariant:addVariant, removeVariant:removeVariant, colours:colours, recolour:recolour,
    bodyPlanOf:bodyPlanOf, rolesOf:rolesOf, fits:fits, optionsFor:optionsFor, lookOf:lookOf, picsOf:picsOf, picsOfDesign:picsOfDesign, chooseForDesign:chooseForDesign,
    heroLook:heroLook, setHeroLook:setHeroLook, heroPics:heroPics, enemyLooks:enemyLooks, pickEnemy:pickEnemy, picFor:picFor, isHero:isHero, migrate:migrate};
})();
