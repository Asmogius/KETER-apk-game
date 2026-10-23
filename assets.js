/* ===========================================================================
   KETER assets (v13.0; v14.3) — every graphic the game needs, in one place, and the
   export that carries them to Godot.

   Slots hold pictures from the picture library:
   - The World Map's: ground for each District (several, scattered at random),
     the dock, POI, Unique POI, Ambush, Cache and Event icons, and collapsed
     tiles (several). All hex pixels, filling a pointy-top tile.
   - v13.8, the game's look: its title (Home's picture), the backdrops behind
     the dock and the other screens, the floor under a fight, and an icon for
     each amount it shows (shards, the part types, HP, AC, MS, NRG, Aether,
     Skull). Square pixels, each at the size the game draws its own; one
     drawn here is used in place of the game's.
   - v14.1, the fight as game 0.14 draws it: each tile's deck plate, the spawn
     pads, the hazards, cover, crates, chests, the Emergency Exit and the
     Healing Station, and the stand-ins for a Unit with no token; with the
     Status icons and marks, the Aether gems, the bar's and the roles' icons and
     a picture for each kind of card with no art. The game ships its own
     (keter_art.js puts a copy in each slot, and a token on every master Unit);
     the export carries only those you have drawn on.
   - v14.2, game 0.15's World Map and menus: the map's ground and rubble as the
     game draws them, a few things of each District's standing on its empty
     tiles, each icon for what a tile holds (square now, on a plate in its
     colour), the Hangar on the dock's tile; each District's fights, five
     floor plates and its own Half and Full Cover; QM-7, the dock's keeper,
     and its blink; Victory and Defeat; the gear and each District's emblem.
     The game ships its own of these too: the export carries those you draw on.
   - v14.3, game 0.16's fight effects, each drawn frame by frame at its speed:
     the muzzle flash, the impact where damage lands, the explosion on each
     tile a blast catches, the heal rising from whoever is mended and the
     shield as an attack glances off armour; and the icons of the side panel's
     turn strip (Move, Attack; Hold fire is the Holding fire icon) and of End
     turn. The game ships its own of these too.
   - Your own: a named slot of square or hex pixels at a size you choose, for
     what the app doesn't use yet (a loading screen, a logo, UI icons).
   Skins and card art are listed with them, from where they already live.

   Export for Godot: one zip with a PNG of every drawn graphic at its true
   size (hex pictures at 4 pixels to a hex's half-width; v14.3, a picture of
   several frames with its frames side by side, saying how many and how fast),
   in folders by kind, and manifest.json saying what each file is.
   =========================================================================== */
(function(){
  "use strict";
  var KEY="keter-app-assets";
  var PX=function(){ return window.KETER_PX; }, SK=function(){ return window.KETER_SKINS; }, WD=function(){ return window.KETER_WORLD; };
  /* flat-top hex pixels build a pointy-top hexagon: the map tile's own shape */
  var TILE={kind:"hex", side:9, orient:"flat"}, HEX_SCALE=4;
  var ICONS=[["dock","The dock"],["poi","POI"],["unique","Unique POI"],["ambush","Ambush"],["cache","Cache"],["event","Event"]];
  /* v14.2 (game 0.15): what a tile holds is a 16 by 16 icon on a plate in its
     colour; the dock is the Hangar, 64 by 64, standing on its tile. (A hex
     picture drawn here before still works: the game lays it over the tile.) */
  var PLATE={poi:"#d6a851", unique:"#f8e398", ambush:"#ff2a3c", cache:"#59cf93", event:"#42bfe8"};
  var ICON_WHAT={poi:"A POI, once it is known", unique:"A Unique POI, once it is known", ambush:"An Ambush, once it is known", cache:"A Cache, once it is known", event:"An Event, once it is known"};
  /* each District's floor plates, quietest first, as the game names them */
  var D_FLOORS={"1":["plain","crystals","vent","frost","rift"],"2":["tiles","cracked","drain","stain","sums"],"3":["plate","grate","oil","keep clear","hazard band"],
    "4":["perforated","solid","scorch","trench","sigil"],"5":["grating","sprouts","moss","overgrown","root"],"6":["cracked","rust","ash","crumble","hole"]};
  var D_COVER={"1":["toppled console","containment pylon"],"2":["desk barricade","amplifier pylon"],"3":["parts bin","assembly frame"],
    "4":["cooling unit","server rack"],"5":["thick roots","cracked vat"],"6":["rubble heap","machine hulk"]};
  /* the menus' (game 0.15): [id, name, w, h, what it is] */
  var MENU_SLOTS=[["ui.qm7","QM-7",64,64,"The dock's keeper, Hangar Operations: its portrait beside what it says, at twice its size"],
    ["ui.qm7_blink","QM-7, blinking",64,64,"Shown for a moment now and then, its optics shut"],
    ["ui.title.victory","Victory",139,32,"Over a won fight's result, at twice its size"],
    ["ui.title.defeat","Defeat",129,32,"Over a lost fight's result, at twice its size"],
    ["ui.icon.gear","Options icon (the gear)",16,16,"Home's Options button, at twice its size"],
    /* v14.6 (game 0.19): the back of a card, as the hand is dealt */
    ["ui.card.back","Card back",75,105,"The back of every card, at twice its size: on the Deck beside your hand, and on each card as it is dealt, before it turns face up"]];
  /* v13.8: the game's look. [id, name, w, h, what it is] */
  var UI_SLOTS=[["ui.title","Title",256,144,"Home's picture: shown behind its buttons, in place of the game's own title and backdrop"],
    ["ui.backdrop.dock","Dock backdrop",256,144,"Behind the dock's tabs, dimmed"],
    ["ui.backdrop.menu","Menu backdrop",256,144,"Behind the Strike Teams, the Workshop and a fight's setup, dimmed"],
    ["ui.floor","Fight floor",64,64,"Repeats under a fight's board, darkened"]];
  var UI_ICONS=[["shards","Aether shards"],["part_troop","Troop parts"],["part_equipment","Equipment parts"],["part_aether","Aether parts"],
    ["hp","Health (HP)"],["ac","Armour (AC)"],["ms","Movement (MS)"],["nrg","Energy (NRG)"],["aether","Aether"],["skull","Skull Level"]];
  /* v14.1 (game 0.14): a fight as the game draws it, and its icons. The game
     has its own picture for each (keter_art.js puts a copy in each slot); one
     you draw over is used in its place. [key, name, w, h, what it is] */
  var PLATE="One tile of a fight's floor, at twice its size; every tile wears one of the five plates", HAZ="A hazard tile, at twice its size, ";
  var FIGHT_SLOTS=[["floor_bolts","Deck plate: bolts",42,48,PLATE],["floor_seam","Deck plate: seam",42,48,PLATE],["floor_grate","Deck plate: grate",42,48,PLATE],
    ["floor_vent","Deck plate: vent",42,48,PLATE],["floor_trench","Deck plate: trench",42,48,PLATE],
    ["pad_yours","Your spawn pad",42,48,"Over a tile where your Units arrive"],["pad_theirs","Enemy spawn pad",42,48,"Over a tile where Enemies arrive"],
    ["hazard_acid","Hazard: acid",42,48,HAZ+"one that Poisons"],["hazard_sparks","Hazard: sparks",42,48,HAZ+"one that Stuns or Drains"],
    ["hazard_razor","Hazard: razor wire",42,48,HAZ+"one that Bleeds or Sunders"],["hazard_sludge","Hazard: sludge",42,48,HAZ+"one that Slows, Roots or Pins"],
    ["hazard_fire","Hazard: fire",42,48,HAZ+"any other"],
    ["half_cover_a","Half Cover, first",48,48,"Stands at the front of a Half Cover tile, so a Unit on it is seen behind it"],["half_cover_b","Half Cover, second",48,48,"The other Half Cover, for every other tile"],
    ["full_cover_a","Full Cover, first",48,48,"Stands at the front of a Full Cover tile, so a Unit on it is seen behind it"],["full_cover_b","Full Cover, second",48,48,"The other Full Cover, for every other tile"],
    ["crate","Loot crate",32,32,"On a Loot Tile; dimmed once it has been searched"],["locked_chest","Locked Chest",32,32,"On a Locked Chest's tile; dimmed once it is open"],
    ["emergency_exit","Emergency Exit",48,48,"A hatch in the floor: a Unit stands over it"],["healing_station","Healing Station",48,48,"On a healing tile"]];
  var STANDINS=[["melee","Melee stand-in"],["ranged","Ranged stand-in"],["drone","Drone stand-in"],["beast","Beast stand-in"]];
  /* v14.3 (game 0.16): the fight's effects, each a picture of several frames
     played at its speed. [key, name, w, h, frames, fps, what it is] */
  var FX_SLOTS=[["flash","Muzzle flash",24,24,4,20,"At the shooter as a shot leaves, its middle over the muzzle"],
    ["impact","Impact",32,32,5,16,"Where damage lands on a Unit, its middle over the Unit's"],
    ["explosion","Explosion",48,48,8,14,"On every tile a blast catches, and where a shell comes down; it sits a little low on the tile, the fire rising"],
    ["heal","Heal",32,48,6,12,"Rising from whoever is mended or helped, its foot at the Unit's feet"],
    ["shield","Shield",48,48,6,14,"Flares round a Unit when an attack glances off its armour"],
    /* v14.5 (game 0.18): the fight's atmosphere, motes that drift over the board, each looping its frames */
    ["ember","Ember",8,8,4,8,"The atmosphere, in District 3: rising off the hot metal, looping its frames as it drifts up"],
    ["spark","Spark",12,12,3,16,"The atmosphere, in District 3: spat from a hazard in a burst, falling; its frames play once, head at the bottom right (flipped when it flies left)"],
    ["ash","Ash",8,8,3,4,"The atmosphere, in District 3: falling and tumbling, looping its frames"],
    ["dust","Dust",6,6,2,3,"The atmosphere, anywhere: drifting slowly across the board"]];
  /* v14.3: the side panel's turn strip and End turn */
  var ACT_ICONS=[["act_move","Move icon","In the side panel's turn strip: Move, and how far it can still go, at twice its size"],
    ["act_attack","Attack icon","In the side panel's turn strip: Attack, lit while it can still use an Action, at twice its size"],
    ["act_end","End turn icon","On End turn, beside the words, at twice its size"]];
  var STATUSES=["Bleed","Drained","Evasive","Full Cover","Guarded","Half Cover","Hardened","Marked","Overwatch","Pinned","Poisoned","Rooted","Slowed","Stunned","Sundered","Weakened"];
  var BAR_ICONS=[["bar_undo","Undo"],["bar_auto","Auto"],["bar_log","Log"],["bar_fit","Fit"],["bar_leave","Leave"]];
  var ROLES=["Melee","Ranged","Support","Cyber"];
  var CARD_PICS=[["action","Action"],["command","Command"],["equipment","Equipment"],["consumable","Consumable"],["prototype","Prototype"],["aether","Aether"],["sphere","Chip"]];
  function key_(s){ return String(s).toLowerCase().replace(/ /g,"_"); }
  var DN={"1":"Threshold Dynamics","2":"Halcyon Cognition","3":"Vantage Robotics","4":"Lazarus Computing","5":"Verdant Biogenics","6":"Meridian Entropics"};

  function clone(o){ return JSON.parse(JSON.stringify(o)); }
  function read(){ try{ var s=JSON.parse(localStorage.getItem(KEY)||"null"); if(s&&typeof s==="object"){ s.pics=s.pics||{}; s.custom=s.custom||[]; return s; } }catch(e){} return {v:1, pics:{}, custom:[]}; }
  function write(s){ try{ localStorage.setItem(KEY,JSON.stringify(s)); return true; }catch(e){ return false; } }

  /* ---- slots ---- */
  function builtinSlots(){
    var out=[];
    ["1","2","3","4","5","6",""].forEach(function(d){
      out.push(Object.assign({id:"map.ground."+(d||"none"), name:d?"District "+d+" ground":"No District ground", group:"map", multi:true,
        what:d?DN[d]:"Tiles in no District"}, TILE)); });
    ICONS.forEach(function(x){
      if(x[0]==="dock") out.push({id:"map.icon.dock", name:"The Hangar (the dock)", group:"map", multi:false, kind:"square", w:64, h:64,
        what:"Stands on the dock's tile, its foot near the bottom, at twice its size"});
      else out.push({id:"map.icon."+x[0], name:x[1]+" icon", group:"map", multi:false, kind:"square", w:16, h:16,
        what:ICON_WHAT[x[0]]+": on a plate in its colour, at twice its size", plate:PLATE[x[0]]}); });
    out.push(Object.assign({id:"map.collapsed", name:"Collapsed tile", group:"map", multi:true, what:"Rubble for blocked tiles"}, TILE));
    /* v14.2: what stands on a District's empty tiles */
    ["1","2","3","4","5","6"].forEach(function(d){ out.push({id:"map.prop."+d, name:"District "+d+" things", group:"map", multi:true, kind:"square", w:32, h:32,
      what:DN[d]+": one stands on one empty tile in five, its foot near the bottom, at twice its size"}); });
    UI_SLOTS.forEach(function(x){ out.push({id:x[0], name:x[1], group:"ui", multi:false, kind:"square", w:x[2], h:x[3], what:x[4]}); });
    UI_ICONS.forEach(function(x){ out.push({id:"ui.icon."+x[0], name:x[1]+" icon", group:"ui", multi:false, kind:"square", w:16, h:16, what:"An icon, shown at twice its size; leave its edge clear"}); });
    /* v14.1: game 0.14's icons and marks, and its pictures for a card with no art */
    STATUSES.forEach(function(s){ out.push({id:"ui.status."+key_(s), name:(s==="Overwatch"?"Holding fire":s)+" icon", group:"ui", multi:false, kind:"square", w:16, h:16,
      what:s==="Overwatch"?"Beside Holding fire in a Unit's side panel, and on Hold fire in its turn strip, at twice its size":"Beside the Status in a Unit's side panel, at twice its size"}); });
    STATUSES.forEach(function(s){ out.push({id:"ui.mark."+key_(s), name:(s==="Overwatch"?"Holding fire":s)+" mark", group:"ui", multi:false, kind:"square", w:8, h:8,
      what:"On the board by a Unit's head, at twice its size"}); });
    ["1","2","3","4","5","6"].forEach(function(d){ out.push({id:"ui.mark.gem_"+d, name:"Aether gem, District "+d, group:"ui", multi:false, kind:"square", w:8, h:8,
      what:"A point of "+DN[d]+" Aether: on a fight's Aether button and in a card's cost"}); });
    out.push({id:"ui.mark.gem_any", name:"Aether gem, any", group:"ui", multi:false, kind:"square", w:8, h:8, what:"A point of Aether of any kind: on the Aether button and in a card's cost"});
    BAR_ICONS.forEach(function(x){ out.push({id:"ui.icon."+x[0], name:x[1]+" button icon", group:"ui", multi:false, kind:"square", w:16, h:16, what:"A button on a fight's top bar, at twice its size"}); });
    ROLES.forEach(function(r){ out.push({id:"ui.icon.role_"+r.toLowerCase(), name:r+" role icon", group:"ui", multi:false, kind:"square", w:16, h:16, what:"Before each "+r+" Action in a Unit's side panel, at twice its size"}); });
    ACT_ICONS.forEach(function(x){ out.push({id:"ui.icon."+x[0], name:x[1], group:"ui", multi:false, kind:"square", w:16, h:16, what:x[2]}); });
    CARD_PICS.forEach(function(x){ out.push({id:"ui.card."+x[0], name:x[1]+" card picture", group:"ui", multi:false, kind:"square", w:64, h:45,
      what:"In the art window of a"+(/^[AEIOU]/.test(x[1])?"n ":" ")+x[1]+" card with no art of its own"}); });
    /* v14.2: the menus' (QM-7, Victory, Defeat, the gear) and each District's emblem */
    MENU_SLOTS.forEach(function(x){ out.push({id:x[0], name:x[1], group:"ui", multi:false, kind:"square", w:x[2], h:x[3], what:x[4]}); });
    ["1","2","3","4","5","6"].forEach(function(d){ out.push({id:"ui.icon.district_"+d, name:"District "+d+" emblem", group:"ui", multi:false, kind:"square", w:16, h:16,
      what:DN[d]+": by a tile's name on the World Map and by a floor in a fight's setup"}); });
    FIGHT_SLOTS.forEach(function(x){ out.push({id:"fight."+x[0], name:x[1], group:"fight", multi:false, kind:"square", w:x[2], h:x[3], what:x[4]}); });
    STANDINS.forEach(function(x){ out.push({id:"fight.standin."+x[0], name:x[1], group:"fight", multi:false, kind:"square", w:48, h:48,
      what:"A Unit with no token of its own stands in as this, by what it is"}); });
    /* v14.3: the fight's effects, frame by frame */
    FX_SLOTS.forEach(function(x){ out.push({id:"fight.fx."+x[0], name:x[1], group:"effects", multi:false, kind:"square", w:x[2], h:x[3], frames:x[4], fps:x[5], what:x[6]}); });
    /* v14.2: each District's fights: five floor plates, its Half and Full Cover */
    ["1","2","3","4","5","6"].forEach(function(d){
      D_FLOORS[d].forEach(function(nm,n){ out.push({id:"fight.d"+d+".floor_"+n, name:"District "+d+" plate: "+nm, group:"district", multi:false, kind:"square", w:42, h:48,
        what:n===0?DN[d]+"'s floor, the plate it shows most":n===4?DN[d]+"'s floor, the plate it shows least":DN[d]+"'s floor"}); });
      out.push({id:"fight.d"+d+".half_cover", name:"District "+d+" Half Cover: "+D_COVER[d][0], group:"district", multi:false, kind:"square", w:48, h:48,
        what:"Stands at the front of a Half Cover tile in "+DN[d]+"'s fights"});
      out.push({id:"fight.d"+d+".full_cover", name:"District "+d+" Full Cover: "+D_COVER[d][1], group:"district", multi:false, kind:"square", w:48, h:48,
        what:"Stands at the front of a Full Cover tile in "+DN[d]+"'s fights"});
    });
    return out;
  }
  /* v14.1: one of the game's own pictures (from keter_art.js) that nobody has
     drawn on. The game has its own copy, so Export for Godot leaves it out. */
  function gamesOwn(pic){ var P=PX(); return !!(pic && /^px_keter_/.test(pic.id||"") && pic.shipped && P && P.mark && P.mark(pic)===pic.shipped); }
  function slots(){ return builtinSlots().concat(read().custom.map(function(c){ return Object.assign({group:"custom", multi:false}, c); })); }
  function slot(id){ return slots().filter(function(s){ return s.id===id; })[0]||null; }
  function ids(id){ var P=PX(); return (read().pics[id]||[]).filter(function(p){ return P && (P.has?P.has(p):P.get(p)); }); }
  function pics(id){ var P=PX(); return ids(id).map(function(p){ return P.get(p); }); }
  function attach(id, picId){ var s=read(); s.pics[id]=(s.pics[id]||[]).filter(function(p){ return p!==picId; }).concat([picId]); return write(s); }
  function detach(id, picId, alsoDelete){
    var s=read(); s.pics[id]=(s.pics[id]||[]).filter(function(p){ return p!==picId; }); write(s);
    if(alsoDelete && PX()) PX().remove(picId); return true;
  }
  /* a blank picture sized for the slot */
  function blankFor(sl){
    var P=PX(), pic;
    if(sl.kind==="hex") pic=P.blankHexagon(Math.max(2,Math.min(32,sl.side||9)), sl.orient||"flat", sl.name);
    else if(sl.frames>1 && P.blankFrames){ pic=P.blankFrames(Math.max(1,Math.min(P.BLANK_MAX||256,sl.w||32)), Math.max(1,Math.min(P.BLANK_MAX||256,sl.h||32)), sl.frames, sl.name, sl.fps||12); pic.grid="square"; }
    else { pic=P.blank(Math.max(1,Math.min(P.BLANK_MAX||256,sl.w||32)), Math.max(1,Math.min(P.BLANK_MAX||256,sl.h||32)), sl.name); pic.grid="square"; }
    pic.kind="blank"; pic.slot=sl.id; return pic;
  }
  /* a new picture in the slot; a single-picture slot keeps only the newest */
  function newPicture(id){
    var sl=slot(id), P=PX(); if(!sl || !P) return null;
    var n=ids(id).length, pic=blankFor(sl); if(sl.multi) pic.name=sl.name+" "+(n+1);
    var pid=P.put(pic); if(!pid) return null;
    if(!sl.multi) ids(id).forEach(function(old){ detach(id, old, false); });
    attach(id, pid); return pid;
  }
  function addCustom(o){
    var s=read(), hex=o.kind==="hex", c={id:"cu_"+Date.now().toString(36)+Math.random().toString(36).slice(2,5), name:String(o.name||"").trim()||"Untitled graphic", kind:hex?"hex":"square"};
    if(hex){ c.side=Math.max(2,Math.min(32,parseInt(o.side,10)||9)); c.orient=o.orient==="pointy"?"pointy":"flat"; }
    else { c.w=Math.max(1,Math.min(256,parseInt(o.w,10)||32)); c.h=Math.max(1,Math.min(256,parseInt(o.h,10)||32)); }
    s.custom.push(c); write(s); return c;
  }
  function removeCustom(id){ var s=read(); s.custom=s.custom.filter(function(c){ return c.id!==id; }); delete s.pics[id]; return write(s); }

  /* ---- drawing a hex picture into a map tile: rendered once per size, then reused ---- */
  var SPR={}, SPR_ORDER=[];
  function tileSprite(pic, h){
    var key=pic.id+":"+(pic.saved||"")+":"+h; if(SPR[key]) return SPR[key];
    var P=PX(), w=Math.round(h*Math.sqrt(3)/2), c=document.createElement("canvas"); c.width=w; c.height=h;
    P.draw(c.getContext("2d"), pic, 0, 0, w, h, 1, {});
    SPR_ORDER.push(key); if(SPR_ORDER.length>160) delete SPR[SPR_ORDER.shift()];
    return (SPR[key]=c);
  }
  /* a stable pick for one tile, from a slot's pictures (or a list already fetched) */
  function pickFrom(list, tileKey){
    if(!list || !list.length) return null; var h=0, s=String(tileKey);
    for(var i=0;i<s.length;i++) h=(h*31+s.charCodeAt(i))>>>0;
    return list[h%list.length];
  }
  function pickFor(id, tileKey){ return pickFrom(pics(id), tileKey); }

  /* ---- the whole list: skins, card art, the map, your own ---- */
  function slug(s){ return String(s||"").toLowerCase().replace(/[^a-z0-9]+/g,"_").replace(/^_|_$/g,"")||"untitled"; }
  function cardList(){
    var all=[]; try{ all=window.KETER_ALLCARDS?window.KETER_ALLCARDS():[]; }catch(e){}
    var seen={}; return all.filter(function(c){ if(!c||c._src==="design"||c._src==="prebuilt") return false; var k=(c._src||"")+"|"+c.name; if(seen[k]) return false; seen[k]=1; return true; });
  }
  function isUnit(c){ return /^(hero|troop|enemy|elite|miniboss|boss)$/i.test(String(c&&c.cardType||"")); }
  /* every entry: {group, name, owner, kind:"art"|"token"|"slot", pic or null, path} */
  function entries(){
    var P=PX(), S=SK(), out=[];
    if(S) S.all().forEach(function(k){
      k.variants.forEach(function(v){ ["art","token"].forEach(function(kd){
        var pic=v[kd]&&P.get(v[kd]);
        out.push({group:"skins", name:k.name+(k.variants.length>1?" · "+v.name:"")+" "+kd, owner:{kind:k.owner.kind, key:k.owner.key, skin:k.id, variant:v.id}, kind:kd, pic:pic||null,
          path:"skins/"+slug(k.owner.kind)+"/"+slug(k.owner.key)+"/"+slug(k.name)+"/"+slug(v.name)+"_"+kd+".png"}); }); }); });
    cardList().forEach(function(c){
      var kinds=isUnit(c)?["art","token"]:["art"];
      kinds.forEach(function(kd){ var pic=P.pictureFor(c,kd)||(c._raw?P.pictureFor(c._raw,kd):null);
        out.push({group:"cards", name:c.name+" "+kd, owner:{card:c.name, cardType:c.cardType, src:c._src||""}, kind:kd, pic:pic||null,
          path:"cards/"+slug(c.cardType)+"/"+slug(c.name)+"_"+kd+".png"}); });
    });
    slots().forEach(function(sl){
      var list=pics(sl.id);
      if(!list.length) out.push({group:sl.group, name:sl.name, owner:{slot:sl.id}, kind:"slot", pic:null, path:""});
      list.forEach(function(pic,i){ out.push({group:sl.group, name:sl.name+(sl.multi?" "+(i+1):""), owner:{slot:sl.id}, kind:"slot", pic:pic,
        path:(sl.group==="map"?"map/"+(/^map\.ground/.test(sl.id)?"ground/":/^map\.icon/.test(sl.id)?"icons/":/^map\.prop/.test(sl.id)?"things/":"collapsed/")
          :sl.group==="ui"?"ui/"+(/^ui\.icon/.test(sl.id)?"icons/":/^ui\.status/.test(sl.id)?"status/":/^ui\.mark/.test(sl.id)?"marks/":/^ui\.card/.test(sl.id)?"cards/":"")
          :sl.group==="fight"?"fight/"+(/^fight\.standin/.test(sl.id)?"standins/":"")
          :sl.group==="district"?"fight/districts/":sl.group==="effects"?"fight/effects/":"custom/")+slug(sl.name)+(sl.multi?"_"+(i+1):"")+".png", multi:!!sl.multi}); });
    });
    return out;
  }

  /* ---- PNGs ---- */
  function pngCanvas(pic){
    var P=PX();
    if(P.isHex(pic)){ var B=P.hexLayout(pic).bounds, w=Math.max(1,Math.ceil(B.w*HEX_SCALE)), h=Math.max(1,Math.ceil(B.h*HEX_SCALE));
      var c=document.createElement("canvas"); c.width=w; c.height=h; P.draw(c.getContext("2d"), pic, 0, 0, w, h, 1, {}); return c; }
    /* v14.3: a picture of several frames: its frames side by side */
    if(P.frameCount && P.frameCount(pic)>1) return P.stripCanvas(pic,1);
    var s=P.sprite(pic), c2=document.createElement("canvas"); c2.width=pic.w; c2.height=pic.h; c2.getContext("2d").drawImage(s,0,0); return c2;
  }
  function pngBytes(pic){
    var url=pngCanvas(pic).toDataURL("image/png"), b=atob(url.split(",")[1]), out=new Uint8Array(b.length);
    for(var i=0;i<b.length;i++) out[i]=b.charCodeAt(i); return out;
  }

  /* ---- a zip, stored without compression (PNGs are compressed already) ---- */
  var CRC=null;
  function crc32(u){ if(!CRC){ CRC=new Uint32Array(256); for(var n=0;n<256;n++){ var c=n; for(var k=0;k<8;k++) c=c&1?0xEDB88320^(c>>>1):c>>>1; CRC[n]=c>>>0; } }
    var x=0xFFFFFFFF; for(var i=0;i<u.length;i++) x=CRC[(x^u[i])&255]^(x>>>8); return (x^0xFFFFFFFF)>>>0; }
  function utf8(s){ return new TextEncoder().encode(s); }
  function zip(files){
    var parts=[], central=[], off=0, now=new Date();
    var dtime=(now.getHours()<<11)|(now.getMinutes()<<5)|(now.getSeconds()>>1), ddate=((now.getFullYear()-1980)<<9)|((now.getMonth()+1)<<5)|now.getDate();
    files.forEach(function(f){
      var name=utf8(f.name), data=f.data, crc=crc32(data), h=new DataView(new ArrayBuffer(30));
      h.setUint32(0,0x04034b50,true); h.setUint16(4,20,true); h.setUint16(6,0x0800,true); h.setUint16(8,0,true); h.setUint16(10,dtime,true); h.setUint16(12,ddate,true);
      h.setUint32(14,crc,true); h.setUint32(18,data.length,true); h.setUint32(22,data.length,true); h.setUint16(26,name.length,true); h.setUint16(28,0,true);
      parts.push(new Uint8Array(h.buffer), name, data);
      var c=new DataView(new ArrayBuffer(46));
      c.setUint32(0,0x02014b50,true); c.setUint16(4,20,true); c.setUint16(6,20,true); c.setUint16(8,0x0800,true); c.setUint16(10,0,true); c.setUint16(12,dtime,true); c.setUint16(14,ddate,true);
      c.setUint32(16,crc,true); c.setUint32(20,data.length,true); c.setUint32(24,data.length,true); c.setUint16(28,name.length,true);
      c.setUint32(42,off,true); central.push(new Uint8Array(c.buffer), name);
      off+=30+name.length+data.length;
    });
    var csize=central.reduce(function(a,p){ return a+p.length; },0), e=new DataView(new ArrayBuffer(22));
    e.setUint32(0,0x06054b50,true); e.setUint16(8,files.length,true); e.setUint16(10,files.length,true); e.setUint32(12,csize,true); e.setUint32(16,off,true);
    var all=parts.concat(central,[new Uint8Array(e.buffer)]), total=all.reduce(function(a,p){ return a+p.length; },0), out=new Uint8Array(total), o=0;
    all.forEach(function(p){ out.set(p,o); o+=p.length; }); return out;
  }
  /* ---- v13.1: the content the game reads, each kind its own file with its format ---- */
  var FORMAT=1;
  function safe(f, d){ try{ var v=f(); return v==null?d:v; }catch(e){ return d; } }
  function plain(o){ return JSON.parse(JSON.stringify(o==null?null:o)); }
  function content(){
    var W=window.KETER_WORLD, WS=window.KETER_WORKSHOP, PR=window.KETER_PROG, L=window.KETER_LOOT, D=window.KETER_DOCK, CH=window.KETER_CHASSIS, S=SK();
    var cards=safe(function(){ var all=window.KETER_ALLCARDS?window.KETER_ALLCARDS():[]; return all.concat(WS&&WS.prebuiltCards?WS.prebuiltCards():[]); },[]).map(plain);
    var levels=safe(function(){ return JSON.parse(localStorage.getItem("keter-hexmap-levels")||"{}"); },{});
    var floors=Object.keys(levels).map(function(k){ var f=plain(levels[k]); f.name=f.name||k; return f; });
    var out=[
      {kind:"cards", data:{cards:cards}, count:cards.length},
      {kind:"floors", data:{floors:floors}, count:floors.length},
      {kind:"world_map", data:{map:safe(function(){ return W.map(); },null), tables:safe(function(){ return W.tables(); },null), events:safe(function(){ return W.events(); },[]), uniques:safe(function(){ return W.uniques(); },[])}, count:1},
      {kind:"chassis", data:{chassis:safe(function(){ return CH.list(); },[])}},
      {kind:"pools", data:{pools:safe(function(){ return PR.pools(); },{})}},
      {kind:"tables", data:{loot:safe(function(){ return L.tables(); },null), workshop:safe(function(){ return WS.tables(); },null), world:safe(function(){ return W.tables(); },null), dock:safe(function(){ return D.tables(); },null)}, count:4},
      {kind:"skins", data:{skins:safe(function(){ return S.all(); },[])}}
    ];
    out.forEach(function(c){ c.file="content/"+c.kind+".json"; c.data=Object.assign({format:FORMAT, kind:c.kind}, plain(c.data));
      if(c.count==null){ var v=c.data[c.kind]||c.data.chassis||c.data.skins; c.count=Array.isArray(v)?v.length:(v&&typeof v==="object"?Object.keys(v).length:1); } });
    return out;
  }
  /* everything drawn, and the content, as {bytes, manifest} */
  function build(){
    var P=PX(), files=[], man=[], used={}, all=entries();
    /* v14.2: a slot of several pictures (ground, rubble, a District's things)
       goes whole once any of its pictures is yours: the game then uses that
       slot's pictures alone, so the game's own in it go too */
    var whole={};
    all.forEach(function(e){ if(e.multi && e.pic && !gamesOwn(e.pic) && e.owner && e.owner.slot) whole[e.owner.slot]=1; });
    all.forEach(function(e){
      /* v14.1: the game's own pictures go only once you have drawn on them */
      if(!e.pic || (gamesOwn(e.pic) && !(e.multi && e.owner && whole[e.owner.slot]))) return; var path=e.path, n=2; while(used[path]){ path=e.path.replace(/\.png$/,"_"+(n++)+".png"); } used[path]=1;
      var bytes=pngBytes(e.pic), hex=P.isHex(e.pic);
      files.push({name:path, data:bytes});
      var m={file:path, group:e.group, what:e.kind, name:e.name, grid:hex?"hex":"square", picture:e.pic.id, owner:e.owner};
      if(hex){ m.hex={cols:e.pic.w, rows:e.pic.h, shape:e.pic.shape||"rect", side:e.pic.side||null, orient:e.pic.orient||"pointy", scale:HEX_SCALE}; }
      else { m.w=e.pic.w; m.h=e.pic.h; }
      /* v14.3: its frames, side by side in the PNG: how many, and how many a second */
      var nf=P.frameCount?P.frameCount(e.pic):1;
      if(!hex && (nf>1 || /^fight\.fx\./.test(e.owner&&e.owner.slot||""))){ m.frames=nf; m.fps=e.pic.fps||12; }
      man.push(m);
    });
    var cs=content();
    cs.forEach(function(c){ files.push({name:c.file, data:utf8(JSON.stringify(c.data))}); });
    var manifest={game:"KETER", format:FORMAT, companion:String(window.KETER_APP_VER||""), exported:new Date().toISOString(),
      note:"Square pictures are at their true pixel size; hex pictures are drawn "+HEX_SCALE+" pixels to a hex's half-width. Content is in content/, one file per kind.",
      content:cs.map(function(c){ return {file:c.file, kind:c.kind, format:FORMAT, count:c.count}; }), files:man};
    files.push({name:"manifest.json", data:utf8(JSON.stringify(manifest,null,1))});
    return {bytes:zip(files), manifest:manifest, count:man.length, content:cs.length};
  }
  function fileName(){ return "KETER_export_"+new Date().toISOString().slice(0,10)+".zip"; }
  function download(){
    var r=build(), blob=new Blob([r.bytes],{type:"application/zip"}), a=document.createElement("a");
    a.href=URL.createObjectURL(blob); a.download=fileName();
    document.body.appendChild(a); a.click(); setTimeout(function(){ URL.revokeObjectURL(a.href); a.remove(); },1500);
    return r;
  }

  window.KETER_ASSETS={KEY:KEY, TILE:TILE, ICONS:ICONS, PLATE:PLATE, D_FLOORS:D_FLOORS, MENU_SLOTS:MENU_SLOTS, UI_SLOTS:UI_SLOTS, UI_ICONS:UI_ICONS, FIGHT_SLOTS:FIGHT_SLOTS, STANDINS:STANDINS, STATUSES:STATUSES, gamesOwn:gamesOwn,
    FX_SLOTS:FX_SLOTS, ACT_ICONS:ACT_ICONS,
    HEX_SCALE:HEX_SCALE, slots:slots, slot:slot, builtinSlots:builtinSlots, ids:ids, pics:pics, attach:attach, detach:detach,
    blankFor:blankFor, newPicture:newPicture, addCustom:addCustom, removeCustom:removeCustom, tileSprite:tileSprite, pickFor:pickFor, pickFrom:pickFrom,
    entries:entries, cardList:cardList, isUnit:isUnit, pngCanvas:pngCanvas, pngBytes:pngBytes, crc32:crc32, zip:zip, build:build, download:download, content:content, fileName:fileName, FORMAT:FORMAT};
})();
