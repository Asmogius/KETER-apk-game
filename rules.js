/* ===========================================================================
   KETER rules resolver

   The rules of combat, with nothing else attached. No DOM, no storage, no
   rendering, no logging. Functions take plain objects and return plain
   objects, so the same code can drive the Combat Datapad, a batch simulator
   running a thousand fights, or anything later.

   Two conventions hold throughout:

   * Nothing here talks to the outside world. A function that changes a Unit
     returns a list of events describing what happened; the caller decides
     whether to log them, draw them, or ignore them.

   * Where the Handbook is specific, the citation is in the comment. This file
     is the one place a rule is written in code, so it is the one place to
     check when the Handbook changes.
   =========================================================================== */
(function(root){
"use strict";

var BEH = (typeof KETER_BEHAVIORS !== "undefined") ? KETER_BEHAVIORS : [];
function behOf(k){ for(var i=0;i<BEH.length;i++) if(BEH[i].k===k) return BEH[i]; return null; }

/* ---------------------------------------------------------------- aether --- */

/* Handbook, Aether Generation: a Hero produces Aether of its own Affinity
   equal to its Affinity Level, every turn, for as long as it is standing. A
   Hero with two Affinities generates for both. Chips drawn from the Pouch are
   separate income and are counted by the caller. (v14.18) A Neutral Affinity
   ("neu", as the Forge writes it) generates Neutral Aether, which pays any cost. */
function aetherFromHero(unit){
  var out = {};
  (unit.affinities||[]).forEach(function(a){
    var lvl = parseInt(a.level,10)||0;
    if(lvl<=0) return;
    var key = (a.district && a.district!=="neu") ? ("d"+a.district) : "generic";
    out[key] = (out[key]||0) + lvl;
  });
  return out;
}
/* What every standing Hero on a side produces together. */
function aetherIncome(units, side){
  var total = {};
  units.forEach(function(u){
    if(u.side!==side || u.down) return;
    if(!/hero/i.test(u.cardType||"")) return;
    var got = aetherFromHero(u);
    for(var k in got) total[k]=(total[k]||0)+got[k];
  });
  return total;
}
function aetherAdd(pool, gain){
  for(var k in gain) pool[k]=(pool[k]||0)+gain[k];
  return pool;
}
/* Can a cost be paid, and with what. District Aether pays its own district;
   generic Aether pays anything. */
function aetherCanPay(pool, cost){
  cost = cost || {};
  var need = parseInt(cost.affinity,10)||0;
  var gen  = parseInt(cost.generic,10)||0;
  var key  = cost.district ? ("d"+cost.district) : null;
  var have = key ? (pool[key]||0) : 0;
  if(need > have) return false;
  /* anything left over, plus generic, has to cover the generic part */
  var spare = 0;
  for(var k in pool) spare += pool[k];
  return (spare - need) >= gen;
}
function aetherPay(pool, cost){
  if(!aetherCanPay(pool,cost)) return false;
  cost = cost || {};
  var need = parseInt(cost.affinity,10)||0;
  var gen  = parseInt(cost.generic,10)||0;
  var key  = cost.district ? ("d"+cost.district) : null;
  /* v13.3: a Bank with none of that District's Aether has 0 of it, not
     nothing. Taking the District part (even a part of 0) from a missing entry
     left Not-a-Number there, and a Bank holding Not-a-Number could pay for
     nothing more that turn, a free card included. */
  if(key){ pool[key] = (pool[key]||0) - need; }
  /* spend generic first, then whatever district Aether is spare */
  var left = gen;
  ["generic"].concat(Object.keys(pool)).forEach(function(k){
    if(left<=0 || !pool[k]) return;
    var take = Math.min(left, pool[k]);
    pool[k] -= take; left -= take;
  });
  return left<=0;
}
function aetherTotal(pool){
  var n=0; for(var k in pool) n+=pool[k]; return n;
}

/* ------------------------------------------------------------------ hex --- */

/* Axial coordinates on a pointy-top lattice, matching the POI Sandbox, so a
   floor built there means the same thing here. Distance is a rule \u2014 Attack
   Range and Movement Speed are both counted in tiles \u2014 which is why the
   geometry lives with the rules rather than with whatever draws them. */
var HEX_DIRS = [[1,0],[1,-1],[0,-1],[-1,0],[-1,1],[0,1]];

function hexKey(q,r){ return q+","+r; }
function hexParse(k){ var a=String(k).split(","); return {q:+a[0], r:+a[1]}; }
function hexDistance(a,b){
  var dq=a.q-b.q, dr=a.r-b.r;
  return (Math.abs(dq) + Math.abs(dq+dr) + Math.abs(dr)) / 2;
}
function hexNeighbours(q,r){
  return HEX_DIRS.map(function(d){ return {q:q+d[0], r:r+d[1]}; });
}

/* Tiles a Unit can reach with the Movement Speed it has, walking round walls
   and other Units rather than through them. Breadth-first, so the cost it
   returns is the real number of tiles walked. */
function reachable(from, steps, opts){
  opts = opts || {};
  var passable = opts.passable || function(){ return true; };
  var blocked  = opts.blocked  || function(){ return false; };
  var wall     = opts.wall     || function(){ return false; };
  var seen = {}, out = [];
  seen[hexKey(from.q,from.r)] = 0;
  var edge = [{q:from.q, r:from.r}];
  for(var step=1; step<=steps; step++){
    var next = [];
    edge.forEach(function(cur){
      hexNeighbours(cur.q,cur.r).forEach(function(n){
        var k = hexKey(n.q,n.r);
        if(seen[k]!==undefined) return;
        if(!passable(n)) return;
        if(wall(cur,n)) return;      /* a wall sits between two tiles */
        if(blocked(n)) return;       /* someone is standing there */
        seen[k] = step;
        out.push({q:n.q, r:n.r, cost:step});
        next.push(n);
      });
    });
    edge = next;
    if(!edge.length) break;
  }
  return out;
}

/* A straight line between two tiles, for working out what an attack passes
   through. Walks the cube line and rounds at each step. */
function hexLine(a,b){
  var n = hexDistance(a,b);
  if(!n) return [{q:a.q, r:a.r}];
  var out = [];
  for(var i=0;i<=n;i++){
    var t = i/n;
    var q = a.q + (b.q-a.q)*t;
    var r = a.r + (b.r-a.r)*t;
    out.push(hexRound(q,r));
  }
  return out;
}
function hexRound(q,r){
  var x=q, z=r, y=-x-z;
  var rx=Math.round(x), ry=Math.round(y), rz=Math.round(z);
  var dx=Math.abs(rx-x), dy=Math.abs(ry-y), dz=Math.abs(rz-z);
  if(dx>dy && dx>dz) rx=-ry-rz;
  else if(dy>dz) ry=-rx-rz;
  else rz=-rx-ry;
  return {q:rx, r:rz};
}

/* ---------------------------------------------------------------- units --- */

function makeUnit(spec){
  spec = spec || {};
  return {
    id:    spec.id || ("u"+Math.random().toString(36).slice(2,9)),
    name:  spec.name || "Unit",
    side:  spec.side || "ally",
    hp:    num(spec.hp, num(spec.hpMax, 20)),
    hpMax: num(spec.hpMax, 20),
    nrg:   num(spec.nrg, num(spec.nrgMax, 4)),
    nrgMax:num(spec.nrgMax, 4),
    ac:    num(spec.ac, 10),
    /* Integrity (the unit rework): every Unit's armour against Cyber, 1 to 20 */
    integrity: num(spec.integrity, num(spec.ac, 10)),
    ms:    num(spec.ms, 3),
    subtype: spec.subtype || "",
    cardType: spec.cardType || "",
    affinities: (spec.affinities||[]).slice(),
    /* subtypes (Combat Roles) and Archetypes: what narrowing words match */
    roles: (spec.roles||[]).map(function(x){ return String(x).toLowerCase(); }).slice(0,2),
    archetypes: (spec.archetypes||[]).slice(),
    /* v12.6: what it drops when defeated — its Skull Level and Salvage */
    skull: num(spec.skull, 0), salvage: spec.salvage || "",
    /* v12.8: the card it came from, whatever it is called on the board */
    src: spec.src || spec.name || "",
    /* v12.7: the blueprints and chassis it can add to a drop, and its set drops */
    lootPool: (spec.lootPool||[]).slice(), setDrops: (spec.setDrops||[]).slice(),
    /* Handbook stat table: Troops reset Energy each turn, Heroes generate it
       and carry over what they do not spend. */
    carries: spec.carries !== undefined ? !!spec.carries : /hero/i.test(spec.cardType||""),
    hits: 0,              /* instances of damage this turn, which is what Will counts */
    statuses: [],
    behaviors: (spec.behaviors||[]).slice(),
    actions: (spec.actions||[]).slice(),
    down: false,
    lastAttackedBy: null, /* for Vindictive */
    attackedThisRound: false
  };
}
function num(v,d){ var n=parseInt(v,10); return isNaN(n)?d:n; }

/* Reads a card in the app's schema form. Kept here so the Datapad and the
   simulator cannot disagree about what a card means. */
function unitFromCard(card, side){
  var st = card.stats || {};
  /* Handbook 15.8: on a card with a variable cost a stat may be written N(X),
     N for each X. X is what was chosen as the card was played, and 1 when
     nobody chose (a Starting Troop, a Unit put down by a Deploy). */
  var x = Math.max(1, parseInt(card.x,10)||1);
  var sx = function(v,d){
    var m = /^\s*(\d+)\s*\(\s*X\s*\)\s*$/i.exec(String(v==null?"":v));
    return m ? parseInt(m[1],10)*x : num(v,d);
  };
  var made = makeUnit({
    name: card.name,
    side: side || (/enemy|boss/i.test(card.cardType||"") ? "enemy" : "ally"),
    hpMax: sx(st.hp,20),
    /* a Hero's Energy is its per-turn generation; a Troop's is its pool */
    nrgMax: sx(st.nrg, num(st.apT,4)),
    ac: sx(st.ac,10),
    /* Integrity replaced Will and Security; a card without one uses its AC */
    integrity: sx(st.int, sx(st.ac,10)),
    ms: sx(st.move,3),
    subtype: "", roles: (card.combatRoles||[]).slice(0,2), cardType: card.cardType,
    affinities: card.affinities||[],
    /* Revision 15.6: Archetypes narrow Targets, so a Unit keeps its own */
    archetypes: (card.archetypes||[]).slice(),
    skull: card.skull, salvage: card.salvage, lootPool: card.lootPool, setDrops: card.setDrops, src: card.src || card.name,
    behaviors: (card.behaviors||[]).map(function(b){
      return {k:b.key||b.k, x:(b.value===undefined?b.x:b.value)};
    }),
    actions: (card.entries||card.abilities||[]).filter(function(a){
      return (a.text||"").trim() || (a.name||"").trim();
    }).map(function(a){
      return {
        name:(a.name||"").trim()||"(unnamed)",
        tag: a.kind || a.tag || "Active",
        cost: num(a.energyCost!==undefined?a.energyCost:a.cost, 0),
        dmg:  a.damage!==undefined?a.damage:a.dmg,
        rng:  a.attackRange!==undefined?a.attackRange:a.rng,
        hit:  a.toHit!==undefined?a.toHit:a.hit,
        pen:  a.armorPenetration!==undefined?a.armorPenetration:a.pen,
        /* melee, ranged or support. This was never copied over, so every
           Action from a card resolved as melee: adjacent only, no roll to hit. */
        role: a.role || "",
        /* v13.9: what a Ranged Action fires, for the game to draw (none is a Bolt) */
        proj: a.projectile || a.proj || "",
        text:(a.text||"").trim()
      };
    })
  });
  /* a Unit from a variable-cost card remembers its X, for what its text says */
  if(card.x !== undefined && card.x !== null) made.x = x;
  return made;
}

/* ------------------------------------------------------------- statuses --- */

function hasStatus(u,name){
  name = String(name||"").toLowerCase();
  if(!u || !u.statuses) return false;
  for(var i=0;i<u.statuses.length;i++)
    if(String(u.statuses[i].name).toLowerCase()===name) return true;
  return false;
}
/* Handbook 15.2. A Status carries a number, and a repeat adds to it. What the
   number means is the keyword's business: turns for Rooted, damage that decays
   for Poisoned, Movement lost for Slowed. `turns` is kept in step with `n` so
   anything still reading the older field sees the same value. */
/* Revision 15.4: every status lasts its Duration at full strength, then ends.
   The number is its strength; strengthless statuses carry none. Each Recharge
   applies its per-turn effect and takes a turn off. A second dose adds its
   strength and its turns. */
var STATUS_RULES={
  rooted:{}, stunned:{}, marked:{}, pinned:{},
  bleed:{dmg:"pct10"}, "half cover":{}, "full cover":{},
  slowed:{strength:true}, drained:{strength:true}, evasive:{strength:true},
  poisoned:{strength:true, dmg:"n"}, weakened:{strength:true}, sundered:{strength:true},
  /* Revision 16.3 */
  hardened:{strength:true}
};
function strengthless(name){ var r=STATUS_RULES[String(name).toLowerCase()]; return !r || !r.strength; }
function statusOf(u,name){
  name=String(name||"").toLowerCase();
  for(var i=0;i<(u.statuses||[]).length;i++)
    if(String(u.statuses[i].name).toLowerCase()===name) return u.statuses[i];
  return null;
}
/* a status's strength; 1 for a strengthless status that is present */
function statusN(u,name){
  var st=statusOf(u,name);
  if(!st) return 0;
  if(st.n===null||st.n===undefined) return 1;
  return num(st.n,0);
}
function statusTurns(u,name){ var st=statusOf(u,name); return st?num(st.turns,0):0; }

/* Revision 15.6: whatever is listening for "gains [Status]" is told here. The
   simulator sets these; nothing else needs to. */
var HOOKS={};
/* The locks (Handbook 16.0): Stunned, Rooted, Pinned and Marked last 2 turns
   at most and never stack or refresh: a Unit that has one ignores another
   dose, and one just out of it cannot be given it again until the same point
   of the next round (its guard, in u.guards, cleared by tickStatuses). So a
   lock can take at most turns/(turns+1) of a Unit's turns. */
var LOCKS=["stunned","rooted","pinned","marked"];
var LOCK_MAX_TURNS=2, STUN_MAX_TURNS=LOCK_MAX_TURNS;
function isLock(name){ return LOCKS.indexOf(String(name).toLowerCase())>=0; }
/* "" if name can land on u; "guard" (just out of it) or "already" (has it now) if not */
function lockBlock(u,name){
  if(!isLock(name) || !u) return "";
  if(u.guards && Object.prototype.hasOwnProperty.call(u.guards, String(name).toLowerCase())) return "guard";
  if(hasStatus(u,name)) return "already";
  return "";
}
function addStatus(u,name,n,source,turns){
  u.statuses=u.statuses||[];
  if(lockBlock(u,name)) return [{type:"status", unit:u.id, name:name, gained:false, resisted:true}];
  if(HOOKS.status) HOOKS.status(u,name);
  var raw=(n===undefined||n===null||n==="")?null:num(n,0);
  var t=(turns===undefined||turns===null||turns==="")?null:num(turns,0);
  var str, trn;
  if(strengthless(name)){ str=null; trn=(t!==null)?t:(raw!==null?raw:1); }
  else { str=(raw!==null)?raw:1; trn=(t!==null)?t:1; }
  trn=Math.max(1,trn);
  if(isLock(name)) trn=Math.min(trn,LOCK_MAX_TURNS);
  var had=statusOf(u,name);
  if(had){
    if(str!==null) had.n=num(had.n,0)+str;
    had.turns=num(had.turns,0)+trn;
    return [{type:"status", unit:u.id, name:had.name, gained:true, stacked:true, n:had.n, turns:had.turns}];
  }
  var st={name:name, n:str, turns:trn, source:source||null};
  /* Handbook 15.9: one that arrives in the Enemies' half of the round is
     marked, and ticks when the Player's next turn ends (see tickStatuses) */
  if(HOOKS.half && HOOKS.half()==="enemy") st.late=true;
  u.statuses.push(st);
  return [{type:"status", unit:u.id, name:name, gained:true, n:str, turns:trn}];
}

function dropStatus(u,name){
  var before=u.statuses.length;
  u.statuses=u.statuses.filter(function(s){ return s.name!==name; });
  return before===u.statuses.length ? [] : [{type:"status",unit:u.id,name:name,gained:false}];
}

/* What the statuses on a Unit change about it. (Overwhelmed and Compromised
   were removed in the unit rework, with Will and Security.) */
function effective(u){
  var e = {ms:u.ms, msBase:u.ms, ac:num(u.ac,10), integrity:num(u.integrity,num(u.ac,10)),
           dmgMult:1, dmgFlat:0, passivesOff:false, alwaysHit:false,
           cannotMove:false, cannotAct:false, evasion:0, aim:0, hardened:0, flying:!!(u.flying||u.pFlying),
           reactionAlwaysHit:false, notes:[]};
  if(hasStatus(u,"Slowed")){
    var sl=statusN(u,"Slowed");
    e.ms=Math.max(0,e.ms-sl);
    e.notes.push("Slowed: Movement Speed down "+sl);
  }
  if(hasStatus(u,"Rooted")){ e.ms=0; e.cannotMove=true; e.notes.push("Rooted: cannot move"); }
  if(hasStatus(u,"Stunned")){
    e.ms=0; e.cannotMove=true; e.cannotAct=true;
    e.notes.push("Stunned: cannot act or move");
  }
  if(hasStatus(u,"Sundered")){
    var su=statusN(u,"Sundered");
    e.ac=Math.max(0,e.ac-su);
    e.notes.push("Sundered: Armor Class down "+su);
  }
  if(hasStatus(u,"Weakened")){
    e.dmgFlat=-statusN(u,"Weakened");
    e.notes.push("Weakened: deals "+(-e.dmgFlat)+" less damage");
  }
  if(hasStatus(u,"Marked")){ e.alwaysHit=true; e.notes.push("Marked: Ranged attacks against it always hit"); }
  if(hasStatus(u,"Pinned")){ e.reactionAlwaysHit=true; e.notes.push("Pinned: reaction shots against it always hit"); }
  if(hasStatus(u,"Evasive")){
    e.evasion=statusN(u,"Evasive");
    e.notes.push("Evasive: +"+e.evasion+" to be hit by Ranged attacks");
  }
  /* Revision 16.3: each hit on it is that much less, never below 1 */
  if(hasStatus(u,"Hardened")){
    e.hardened=statusN(u,"Hardened");
    e.notes.push("Hardened: each hit on it is "+e.hardened+" less, never below 1");
  }
  /* Modify, from cards: each carries its stat, amount and how long it lasts */
  (u.mods||[]).forEach(function(m){
    var a=num(m.amt,0);
    if(m.stat==="AC") e.ac=Math.max(0,e.ac+a);
    else if(m.stat==="MS"){ if(!e.cannotMove) e.ms=Math.max(0,e.ms+a); }
    else if(m.stat==="DMG") e.dmgFlat+=a;
    else if(m.stat==="INT"||m.stat==="WIL") e.integrity=Math.max(0,e.integrity+a);   /* WIL, the old name, reads as INT */
    else if(m.stat==="RANGE"||m.stat==="Range") e.range=(e.range||0)+a;
    else if(m.stat==="AP") e.ap=(e.ap||0)+a;
    else if(m.stat==="Aim") e.aim+=a;   /* Revision 16.3: its ranged attacks need that much less */
    e.notes.push((a>=0?"+":"")+a+" "+m.stat+" ("+(m.dur==="passive"?"Passive, while it holds":m.dur+(m.n?" "+m.n:""))+")");
  });
  return e;
}

/* Handbook 15.9: every Status ticks once a round, at the end of the turn after
   the one it arrived in. One that arrived in the Player's half of the round
   (from the Recharge to the end of the Player's turn) ticks in the Recharge
   Phase, as every Status did before 15.9. One that arrived in the Enemies'
   half (their turn, its end, the next wave, up to the Recharge) is marked
   late, and ticks when the Player's next turn ends. So a Status for 1 turn
   always lasts through the next turn, whoever put it there. Timed stat
   changes follow the same rule. The decaying ones do their damage first. */
function tickStatuses(units, late){
  var ev=[], mine=function(x){ return !!x.late===!!late; };
  (units||[]).forEach(function(u){
    if(u.down) return;
    if(u.guards){
      Object.keys(u.guards).forEach(function(g){ if(!!u.guards[g]===!!late) delete u.guards[g]; });   /* a round has gone by since it ended */
      if(!Object.keys(u.guards).length) delete u.guards;
    }
    (u.statuses||[]).forEach(function(st){
      if(/^(aura|passive):/.test(String(st.source||""))) return;   /* an Aura or a Passive lasts while it holds */
      if(!mine(st)) return;
      var rule=STATUS_RULES[String(st.name).toLowerCase()]||{};
      if(rule.dmg==="n" && num(st.n,0)>0){
        ev=ev.concat(hit(u,num(st.n,0))); ev.push({type:"tick", unit:u.id, name:st.name, damage:num(st.n,0)});
      }
      if(rule.dmg==="pct10"){
        var d=Math.max(1, Math.round(num(u.hp,0)*0.10));
        ev=ev.concat(hit(u,d)); ev.push({type:"tick", unit:u.id, name:st.name, damage:d});
      }
      st.turns=num(st.turns,0)-1;
    });
    u.mods=(u.mods||[]).filter(function(m){
      if(m.dur!=="turns") return true; /* persistent, while attached and a Passive's stay */
      if(!mine(m)) return true;
      m.n=num(m.n,0)-1;
      if(m.n>0) return true;
      if(m.stat==="HP"){ u.hpMax=Math.max(1,num(u.hpMax,1)-num(m.amt,0)); u.hp=Math.min(num(u.hp,0),u.hpMax); }
      if(m.stat==="NRG"){ u.nrgMax=Math.max(0,num(u.nrgMax,0)-num(m.amt,0)); u.nrg=Math.min(num(u.nrg,0),u.nrgMax); }
      ev.push({type:"mod", unit:u.id, stat:m.stat, expired:true});
      return false;
    });
    u.statuses=(u.statuses||[]).filter(function(st){
      if(/^(aura|passive):/.test(String(st.source||""))) return true;
      if(num(st.turns,0)>0) return true;
      if(isLock(st.name)){ u.guards=u.guards||{}; u.guards[String(st.name).toLowerCase()]=!!late; }
      ev.push({type:"status", unit:u.id, name:st.name, gained:false, expired:true});
      return false;
    });
  });
  return ev;
}
/* the Recharge Phase: what arrived in the Player's half of the round */
function rechargeTick(units){ return tickStatuses(units, false); }
/* the end of the Player's turn: what arrived in the Enemies' half */
function turnEndTick(units){ return tickStatuses(units, true); }

/* ---------------------------------------------------------------- health --- */

/* Each hit is one instance, whatever its size: a Unit hit once for seven has
   taken one instance. */
/* Revision 16.3: Hardened takes its number off each hit, never below 1 */
function hardenedCut(u, amount){
  amount = Math.max(0, num(amount,0));
  var hard = hasStatus(u,"Hardened") ? statusN(u,"Hardened") : 0;
  return (hard > 0 && amount > 0) ? Math.max(1, amount - hard) : amount;
}
function hit(u, amount, cut){
  amount = cut ? Math.max(0, num(amount,0)) : hardenedCut(u, amount);
  var ev = [];
  var before = u.hp;
  u.hp = Math.max(0, u.hp - amount);
  u.hits++;
  ev.push({type:"hit", unit:u.id, amount:amount, instance:u.hits});
  if(u.hp===0 && !u.down){ u.down = true; ev.push({type:"down", unit:u.id}); }
  /* Revision 15.6: a simulator listening for "takes damage" hears it here */
  if(HOOKS.hit && before-u.hp>0) HOOKS.hit(u, before-u.hp);
  return ev;
}
/* Healing restores what was lost and stops at the printed figure. */
function heal(u, amount){
  amount = Math.max(0, num(amount,0));
  var before = u.hp;
  u.hp = Math.min(u.hpMax, u.hp + amount);
  if(u.hp>0) u.down=false;
  return [{type:"heal", unit:u.id, amount:u.hp-before, wasted:amount-(u.hp-before)}];
}
/* Gaining Health is a different thing and may go above the printed figure. */
function gain(u, amount){
  amount = Math.max(0, num(amount,0));
  u.hp += amount;
  if(u.hp>0) u.down=false;
  return [{type:"gain", unit:u.id, amount:amount, over:Math.max(0,u.hp-u.hpMax)}];
}

/* --------------------------------------------------------------- actions --- */

/* What an Action does to whoever it lands on. The damage strip is
   authoritative; otherwise the rules text is read for the usual phrasing. */
function actionEffect(a){
  var out = {damage:0, heal:0, gain:0};
  var d = parseInt(a.dmg,10);
  if(!isNaN(d) && d>0) out.damage = d;
  var t = String(a.text||"");
  if(!out.damage){
    var m = t.match(/deal\s+(\d+)\s+damage/i) || t.match(/(\d+)\s+damage/i);
    if(m) out.damage = parseInt(m[1],10)||0;
  }
  var h = t.match(/heals?\s+(?:for\s+)?(\d+)/i) || t.match(/restores?\s+(\d+)/i);
  if(h) out.heal = parseInt(h[1],10)||0;
  var g = t.match(/gains?\s+\+?(\d+)\s*(?:HP|Health)/i);
  if(g) out.gain = parseInt(g[1],10)||0;
  return out;
}
function canAfford(u,a){
  return !((a.tag==="Active"||a.tag==="Combo") && num(a.cost,0) > u.nrg);
}
/* Resolve an Action from one Unit onto another. Legality is the caller's
   business; this works out what happens if it lands. */
function useAction(actor, action, target){
  var ev = [{type:"action", unit:actor.id, name:action.name, cost:num(action.cost,0)}];
  actor.nrg = Math.max(0, actor.nrg - num(action.cost,0));
  var eff = actionEffect(action);
  var mine = effective(actor);
  if(target){
    target.lastAttackedBy = actor.id;
    target.attackedThisRound = true;
    if(eff.damage){
      var dealt = Math.floor(eff.damage * mine.dmgMult);
      if(dealt !== eff.damage)
        ev.push({type:"modified", unit:actor.id, from:eff.damage, to:dealt,
                 why:"a status"});
      ev = ev.concat(hit(target, dealt));
    }
    if(eff.heal) ev = ev.concat(heal(target, eff.heal));
    if(eff.gain) ev = ev.concat(gain(target, eff.gain));
  }
  return ev;
}

/* ------------------------------------------------------------- the dice --- */

/* A seeded generator, so a simulator can run the same fight twice and get the
   same answer. Passing no seed gives ordinary randomness.

   Three kinds are rolled in KETER: a d20 for To-Hit and Penetration, and a d6
   or a coin where a card calls for one. */
var DIE = {d20:20, d6:6, coin:2};
function makeDice(seed){
  var plain = (seed===undefined || seed===null);
  var s0 = plain ? 0 : ((seed|0) || 1);
  function raw(sides){
    if(plain) return 1 + Math.floor(Math.random()*sides);
    /* xorshift32: small, fast, and repeatable */
    s0 ^= s0 << 13; s0 ^= s0 >>> 17; s0 ^= s0 << 5; s0 |= 0;
    return 1 + (Math.abs(s0) % sides);
  }
  var d = {
    seeded: !plain,
    d20:  function(){ return raw(20); },
    d6:   function(){ return raw(6);  },
    /* a coin reports as heads or tails, and as 1 or 2 for anything counting */
    coin: function(){ var v=raw(2); return {value:v, face:(v===1?"heads":"tails")}; },
    roll: function(kind){
      if(kind==="coin") return d.coin().value;
      return raw(DIE[kind]||20);
    }
  };
  return d;
}
/* The face a player would read off the table, for reporting back. */
function faceOf(kind, value){
  if(kind==="coin") return value===1 ? "heads" : "tails";
  return String(value);
}

/* -------------------------------------------------------------- attacks --- */

/* Handbook, Attack Types and Armor Class & Penetration:

   Ranged   must both hit and Penetrate. Accuracy is a d20 against the To-Hit
            printed on the Action; Cover and Evasive add to that value and
            nothing else modifies it. Penetration is a d20 plus Armor
            Penetration against the target's Armor Class. Beyond the Action's
            Attack Range the target cannot be attacked at all.
   Melee    always hits, but must still Penetrate to deal damage.
   Aether   always hits and always Penetrates; its damage ignores Armor Class.
   Support  always hits, since it targets friendly Units.

   Cyber    reaches and aims like Ranged, then must Penetrate Integrity
            rather than Armor Class.

   A target that is Marked is always hit by Ranged Attacks, so the accuracy
   roll is skipped. */
/* Resolution is resumable, which is what makes a manual roll possible at all.

   Called without the roll it needs, it returns what it is waiting for:
     {pending:"accuracy", die:"d20", needed:13}
   Fill that in and call again and it either finishes or asks for the next one.

   A caller in Auto mode supplies a die and never sees a pending state \u2014 the
   rolls are filled as they come up. A caller in Manual mode hands the pending
   request to the player and calls again with what they rolled. The rules do
   not care which happened, which is the point of resolving it this way. */
function resolveAttack(attacker, action, target, ctx){
  ctx = ctx || {};
  var rolls = ctx.rolls || {};
  var dice = ctx.dice;
  var manual = !!ctx.manual;
  var kind = String(action.role || action.kind || "melee").toLowerCase();
  var out = {
    kind: kind, inRange: true, hit: null, penetrated: null,
    damage: 0, rolls: {}, reason: null, pending: null
  };

  function need(what, die, needed){
    if(rolls[what] !== undefined && rolls[what] !== null) return num(rolls[what],0);
    if(!manual && dice) return dice.roll(die);
    out.pending = what; out.die = die; out.needed = needed;
    return null;
  }

  if(kind === "support" || kind === "aether"){
    out.hit = true;
    out.penetrated = true;
    if(kind === "aether") out.aetherDamage = true;
  } else {
    /* a Cyber Action reaches and aims like a ranged attack */
    var aimed = (kind === "ranged" || kind === "cyber");
    if(aimed && action.rng !== undefined && action.rng !== "" && ctx.distance !== undefined){
      var reach = num(action.rng, 0) + num(effective(attacker).range, 0);
      if(ctx.distance > reach){
        out.inRange = false;
        out.reason = "beyond Attack Range " + reach;
        return out;
      }
    }
    /* accuracy */
    if(aimed){
      var tEff = effective(target);
      if(tEff.alwaysHit || (ctx.reaction && tEff.reactionAlwaysHit)){
        out.hit = true;
        out.reason = hasStatus(target,"Marked") ? "target Marked, always hit"
                   : ctx.reaction ? "target Pinned, the reaction always hits"
                   : "target always hit";
      } else {
        var threshold = num(action.hit, 0) + num(ctx.cover, 0) + num(ctx.evasive, 0) +
                        num(tEff.evasion, 0) - num(effective(attacker).aim, 0);
        var acc = need("accuracy", "d20", threshold);
        if(acc === null) return out;
        out.rolls.accuracy = acc;
        out.needed = threshold;
        out.hit = acc >= threshold;
        if(!out.hit) out.reason = "missed: " + acc + " against " + threshold;
      }
    } else {
      /* Flying: cannot be hit by melee attacks */
      if(effective(target).flying){
        out.hit=false; out.penetrated=false; out.reason="target is Flying: melee cannot reach it";
        return out;
      }
      out.hit = true;   /* melee always hits */
    }
    /* penetration, asked for only once it has hit */
    if(out.hit){
      /* a Cyber Action must penetrate Integrity, as an attack must Armor */
      var cyber = (kind === "cyber");
      var ac = cyber ? effective(target).integrity : effective(target).ac;   /* Sundered lowers AC */
      var pen = need("penetration", "d20", ac);
      if(pen === null) return out;
      out.rolls.penetration = pen;
      var withAp = pen + num(action.pen, 0) + num(effective(attacker).ap, 0);
      out.needed_ac = ac; out.against = cyber ? "Integrity" : "Armor Class";
      out.penetrated = withAp >= ac;
      out.penetrationTotal = withAp;
      if(!out.penetrated)
        out.reason = "did not Penetrate: " + withAp + " against " + (cyber?"Integrity ":"Armor Class ") + ac;
    } else {
      out.penetrated = false;
    }
  }

  if(out.hit && out.penetrated){
    var eff = actionEffect(action);
    var mine = effective(attacker);
    out.damage = hardenedCut(target, Math.max(0, Math.floor(eff.damage * mine.dmgMult) + num(mine.dmgFlat,0)));
    if(out.damage !== eff.damage) out.halved = mine.dmgMult<1;
    if(mine.dmgFlat) out.weakened = -mine.dmgFlat;
  }
  return out;
}

/* What an attack will ask for before it is resolved, so an interface can warn
   the player which dice to pick up. Accuracy only, where penetration depends
   on whether it hits. */
function rollsFor(action, target){
  var kind = String(action.role || action.kind || "melee").toLowerCase();
  if(kind === "support" || kind === "aether") return [];
  /* Cyber aims like Ranged, then penetrates Integrity: two dice as well */
  if((kind === "ranged" || kind === "cyber") && !effective(target).alwaysHit)
    return [{what:"accuracy", die:"d20"}, {what:"penetration", die:"d20"}];
  return [{what:"penetration", die:"d20"}];
}

/* Resolve and apply, returning the same event list the rest of the resolver
   uses. This is what a simulator calls once per attack. */
function attack(attacker, action, target, ctx){
  var res = resolveAttack(attacker, action, target, ctx);
  var ev = [{type:"attack", unit:attacker.id, target:target.id,
             name:action.name, result:res}];
  if(!res.inRange) return ev;
  attacker.nrg = Math.max(0, attacker.nrg - num(action.cost,0));
  target.lastAttackedBy = attacker.id;
  target.attackedThisRound = true;
  if(res.damage) ev = ev.concat(hit(target, res.damage, true));
  return ev;
}

/* ----------------------------------------------------------------- turns --- */

/* The three things a table forgets, in one place. */
function endTurn(units){
  var ev = [];
  units.forEach(function(u){
    u.hits = 0; u.attackedThisRound = false;
    u.nrg = u.carries ? (u.nrg + u.nrgMax) : u.nrgMax;
    /* Drained takes its strength from every refill while it lasts (15.4); it
       ends at Recharge like any other status */
    var dr=hasStatus(u,"Drained")?statusN(u,"Drained"):0;
    if(dr){
      u.nrg=Math.max(0,u.nrg-dr);
      ev.push({type:"status", unit:u.id, name:"Drained", energyLost:dr});
    }
    /* Statuses no longer count down here: they tick in the Recharge Phase. */
  });
  ev.push({type:"turn"});
  return ev;
}

/* Combat ends when every Enemy is down, or every Player Unit is. */
function outcome(units){
  var live = function(side){
    return units.filter(function(u){ return u.side===side && !u.down; }).length;
  };
  var allies = live("ally"), foes = live("enemy");
  if(foes===0 && allies===0) return {over:true, winner:"draw"};
  if(foes===0)   return {over:true, winner:"ally"};
  if(allies===0) return {over:true, winner:"enemy"};
  return {over:false, winner:null};
}

/* ------------------------------------------------------------- behaviour --- */

/* Tie-breaks are fixed and not editable, so an Enemy's target is never a
   matter of opinion: closest, then lowest current Health, then lowest Armor
   Class, then lowest card number. */
function tieBreak(list, ctx){
  return list.slice().sort(function(a,b){
    var da=dist(ctx,a), db=dist(ctx,b);
    if(da!==db) return da-db;
    if(a.hp!==b.hp) return a.hp-b.hp;
    if(a.ac!==b.ac) return a.ac-b.ac;
    return String(a.id).localeCompare(String(b.id));
  })[0] || null;
}
function dist(ctx,u){
  if(!ctx || !ctx.distance) return 0;
  return ctx.distance(u);
}

/* Picks who an Enemy attacks. A keyword with a condition outranks one
   without, which is how an Enemy can be Cautious normally and Cowardly once
   hurt; where two conditions are both met, the one printed first wins. */
function chooseTarget(enemy, candidates, ctx){
  ctx = ctx || {};
  var live = candidates.filter(function(u){ return !u.down; });
  if(!live.length) return null;

  var defs = (enemy.behaviors||[]).map(function(b){
    var d = behOf(b.k); return d ? {def:d, x:(b.x===undefined?d.pdef:b.x)} : null;
  }).filter(function(x){ return x && x.def.cat==="target"; });

  /* conditional first, in printed order, then unconditional */
  var ordered = defs.filter(function(d){ return d.def.cond; })
            .concat(defs.filter(function(d){ return !d.def.cond; }));

  for(var i=0;i<ordered.length;i++){
    var pick = applyTargeting(ordered[i].def.k, enemy, live, ctx);
    if(pick) return pick;
  }
  return tieBreak(live, ctx);
}

function applyTargeting(key, enemy, live, ctx){
  var pool;
  switch(key){
    /* The Player keywords mirror an Enemy one each, so they share its logic
       rather than repeating it \u2014 the only difference is what counts as a
       priority target: a Hero for Cunning, a Boss for Valiant. */
    case "decisive":     return applyTargeting("sadistic", enemy, live, ctx);
    case "precise":      return applyTargeting("opportunistic", enemy, live, ctx);
    case "dauntless":    return applyTargeting("brutish", enemy, live, ctx);
    case "defiant":      return applyTargeting("vindictive", enemy, live, ctx);
    case "coordinated":  return applyTargeting("ravenous", enemy, live, ctx);
    case "thorough":     return applyTargeting("methodical", enemy, live, ctx);
    case "valiant":
      pool = live.filter(function(u){ return /boss/i.test(u.cardType||""); });
      return pool.length ? tieBreak(pool, ctx) : null;
    case "cunning":
      pool = live.filter(function(u){ return /hero/i.test(u.cardType||""); });
      return pool.length ? tieBreak(pool, ctx) : null;
    case "sadistic":
      return best(live, function(u){ return -u.hp; }, ctx);
    case "opportunistic":
      return best(live, function(u){ return -u.ac; }, ctx);
    case "brutish":
      return best(live, function(u){ return u.ac; }, ctx);
    case "vindictive":
      pool = live.filter(function(u){ return u.id===enemy.lastAttackedBy; });
      return pool.length ? pool[0] : null;
    case "ravenous":
      pool = live.filter(function(u){ return u.attackedThisRound; });
      return pool.length ? best(pool, function(u){ return -u.hp; }, ctx) : null;
    case "methodical":
      /* only statuses an Enemy applied count, so a Unit the player buffed is
         still a valid target */
      pool = live.filter(function(u){
        return !u.statuses.some(function(s){ return s.source==="enemy"||s.source==="rule"; });
      });
      return pool.length ? tieBreak(pool, ctx) : null;
    default:
      return null;
  }
}
function best(list, score, ctx){
  var top = -Infinity, pool = [];
  list.forEach(function(u){
    var v = score(u);
    if(v>top){ top=v; pool=[u]; }
    else if(v===top) pool.push(u);
  });
  return tieBreak(pool, ctx);
}

/* What a Unit's movement keywords tell it to do this turn. */
function movePlan(enemy, ctx){
  ctx = ctx || {};
  var nearest = ctx.nearestEnemyDistance;
  var out = {move:"toward", act:true, why:null};
  var defs = (enemy.behaviors||[]).map(function(b){
    var d = behOf(b.k); return d ? {def:d, x:(b.x===undefined?d.pdef:b.x)} : null;
    /* Guardian is filed under support because it is about the Unit's job, but
       what it actually changes is where it stands \u2014 so movement has to see it. */
  }).filter(function(x){ return x && (x.def.cat==="move" || x.def.k==="guardian"); });

  for(var i=0;i<defs.length;i++){
    var k = defs[i].def.k, x = defs[i].x, nm = defs[i].def.name;
    /* Prudent and Wary are the Player's Cowardly and Cautious */
    if((k==="cowardly"||k==="prudent") && enemy.hp<=x)
      return {move:"away", act:false, why:nm+" "+x};
    if((k==="cautious"||k==="wary") && nearest!==undefined && nearest<=x)
      out = {move:"away", act:true, why:nm+" "+x};
    if(k==="steadfast" && out.move!=="away")
      out = {move:"hold", act:true, why:"Steadfast"};
    if(k==="guardian" && out.move==="toward")
      out = {move:"escort", act:true, why:"Guardian"};
  }
  return out;
}

/* ------------------------------------------------------------ the round --- */

/* Handbook round sequence: Draw, Recharge Aether, then the Player acts \u2014 cards,
   movement, attacks, cards again \u2014 and only once every Player Unit is finished
   do the Enemies move and use their Actions.

   Two things are deliberately not modelled yet, and both are hooks rather than
   omissions: the Draw and Recharge phases need a deck and an Aether pool, and
   distance needs a map. Where no map is supplied every Unit is treated as
   adjacent, so Attack Range never blocks. That is the honest simplification \u2014
   it answers "is this fight winnable" without pretending to answer "where
   should I stand".  */

function distanceBetween(ctx, a, b){
  if(ctx && typeof ctx.distance === "function") return ctx.distance(a,b);
  return 1;   /* no map supplied: treat everything as adjacent */
}

/* The Action a Unit would choose against a given target: the most damaging it
   can afford. A Player can of course choose otherwise; this is the simulator's
   stand-in for that judgement. */
function bestAction(unit, target, ctx){
  var usable = (unit.actions||[]).filter(function(a){
    if(a.tag === "Passive" || a.tag === "Aura") return false;
    if(!canAfford(unit, a)) return false;
    var reach = num(a.rng, 0);
    if(String(a.role||"").toLowerCase() === "ranged" && reach)
      return distanceBetween(ctx, unit, target) <= reach;
    return true;
  });
  if(!usable.length) return null;
  return usable.slice().sort(function(x,y){
    return actionEffect(y).damage - actionEffect(x).damage;
  })[0];
}

/* An Enemy running a Combo takes them in order, restarting if it is ever
   unable to act. A Special Ability overrides the next one without advancing
   the sequence. */
function comboActions(u){
  return (u.actions||[]).filter(function(a){ return a.tag === "Combo"; });
}
function nextComboAction(u){
  var combo = comboActions(u);
  if(!combo.length) return null;
  if(u.overrideNext){
    var sp = (u.actions||[]).filter(function(a){
      return a.tag === "Special" && a.name === u.overrideNext; })[0];
    if(sp) return {action: sp, override: true};
  }
  var i = ((u.comboAt||0) % combo.length + combo.length) % combo.length;
  return {action: combo[i], index: i, override: false};
}

function enemyTurn(enemy, state, ctx){
  var ev = [];
  if(enemy.down) return ev;
  var foes = state.units.filter(function(u){ return u.side === "ally" && !u.down; });
  if(!foes.length) return ev;

  /* movement keywords decide whether it closes, backs off, or breaks entirely */
  var nearest = Math.min.apply(null, foes.map(function(f){
    return distanceBetween(ctx, enemy, f); }));
  var plan = movePlan(enemy, {nearestEnemyDistance: nearest});
  if(plan.move === "away") ev.push({type:"move", unit:enemy.id, away:true, why:plan.why});
  if(!plan.act){
    /* Cowardly takes no Action, so its Combo loses its place */
    if(comboActions(enemy).length) enemy.comboAt = 0;
    ev.push({type:"skip", unit:enemy.id, why:plan.why});
    return ev;
  }

  var target = chooseTarget(enemy, foes, {
    distance: function(u){ return distanceBetween(ctx, enemy, u); }
  });
  if(!target) return ev;

  var pick = nextComboAction(enemy);
  var action = pick ? pick.action : bestAction(enemy, target, ctx);
  if(!action) action = bestAction(enemy, target, ctx);
  if(!action){
    if(comboActions(enemy).length) enemy.comboAt = 0;
    ev.push({type:"skip", unit:enemy.id, why:"nothing it can use"});
    return ev;
  }

  ev = ev.concat(attack(enemy, action, target, {
    dice: ctx.dice,
    distance: distanceBetween(ctx, enemy, target),
    cover: ctx.coverFor ? ctx.coverFor(target, enemy) : 0,
    evasive: target.evasive || 0
  }));

  if(pick && !pick.override && comboActions(enemy).length)
    enemy.comboAt = ((enemy.comboAt||0) + 1) % comboActions(enemy).length;
  if(pick && pick.override) enemy.overrideNext = null;
  return ev;
}

/* The Player's side. Order is the Player's to choose, so the caller may supply
   one; otherwise they act in the order given. */
function playerTurn(state, ctx){
  var ev = [];
  var mine = state.units.filter(function(u){ return u.side === "ally" && !u.down; });
  if(ctx.playerOrder) mine = ctx.playerOrder(mine.slice(), state);
  mine.forEach(function(u){
    if(u.down) return;
    var foes = state.units.filter(function(f){ return f.side === "enemy" && !f.down; });
    if(!foes.length) return;
    var choice = ctx.playerPolicy
      ? ctx.playerPolicy(u, state, ctx)
      : defaultPlayerPolicy(u, foes, ctx);
    if(!choice || !choice.action || !choice.target) return;
    ev = ev.concat(attack(u, choice.action, choice.target, {
      dice: ctx.dice,
      distance: distanceBetween(ctx, u, choice.target),
      cover: ctx.coverFor ? ctx.coverFor(choice.target, u) : 0,
      evasive: choice.target.evasive || 0
    }));
  });
  return ev;
}

/* Finish something if you can, otherwise hit the most dangerous thing you can
   reach. A crude stand-in for a Player, and openly so. */
function defaultPlayerPolicy(unit, foes, ctx){
  var best = null;
  foes.forEach(function(f){
    var a = bestAction(unit, f, ctx);
    if(!a) return;
    var dmg = actionEffect(a).damage;
    var kills = dmg >= f.hp;
    var score = (kills ? 1000 : 0) + dmg - f.hp * 0.01;
    if(!best || score > best.score) best = {action:a, target:f, score:score};
  });
  return best;
}

function runRound(state, ctx){
  ctx = ctx || {};
  state.round = (state.round||0) + 1;
  var ev = [{type:"round", round:state.round}];
  /* Draw and Recharge belong here once decks and Aether are modelled */
  if(ctx.onDraw) ev = ev.concat(ctx.onDraw(state) || []);

  ev = ev.concat(playerTurn(state, ctx));
  var done = outcome(state.units);
  if(!done.over){
    state.units.filter(function(u){ return u.side === "enemy"; })
      .forEach(function(e){ ev = ev.concat(enemyTurn(e, state, ctx)); });
  }
  ev = ev.concat(endTurn(state.units));
  return ev;
}

/* Run a whole fight. The cap exists so a stalemate reports itself rather than
   hanging: two Units that cannot hurt each other would otherwise loop forever. */
function runCombat(units, ctx){
  ctx = ctx || {};
  var state = {units: units, round: 0, log: []};
  var cap = ctx.maxRounds || 50;
  var res;
  while(true){
    state.log = state.log.concat(runRound(state, ctx));
    res = outcome(state.units);
    if(res.over) break;
    if(state.round >= cap){ res = {over:false, winner:"stalemate"}; break; }
  }
  return {
    winner: res.winner,
    rounds: state.round,
    units: state.units,
    log: state.log,
    survivors: state.units.filter(function(u){ return !u.down; }).map(function(u){
      return {name:u.name, side:u.side, hp:u.hp, hpMax:u.hpMax};
    })
  };
}

/* Some Player keywords are about what a Unit does rather than who it hits.
   Medic looks for a wounded ally first; Guardian keeps station on the Hero.
   Both are reported so an auto-battle can say why it did what it did. */
function supportPlan(unit, allies){
  var keys = (unit.behaviors||[]).map(function(b){ return b.k; });
  if(keys.indexOf("medic")<0) return null;
  var heals = (unit.actions||[]).filter(function(a){
    if(a.tag==="Passive"||a.tag==="Aura") return false;
    if(!canAfford(unit,a)) return false;
    var eff = actionEffect(a);
    return eff.heal>0 || eff.gain>0 ||
           String(a.role||"").toLowerCase()==="support";
  });
  if(!heals.length) return null;
  var hurt = allies.filter(function(u){
    return !u.down && u.id!==unit.id && u.hp < u.hpMax;
  }).sort(function(a,b){
    return (a.hp/a.hpMax) - (b.hp/b.hpMax);
  })[0];
  if(!hurt) return null;
  return {action:heals[0], target:hurt, why:"Medic"};
}
function escortTarget(unit, allies){
  return allies.filter(function(u){
    return !u.down && /hero/i.test(u.cardType||"") && u.id!==unit.id;
  })[0] || null;
}

/* Handbook 14.0: every Aether Chip prints its own value, 0 to 10. Level and
   Rarity are only the guideline for choosing it. The Card Forge's chipAether
   applies the same guideline, and the test suite checks the two agree. */
var CHIP_RARITY_BONUS={common:0,uncommon:0,rare:1,epic:1,legendary:2,mythic:2};
function chipValue(card){
  if(!card) return 0;
  /* Revision 16.3: a Chip whose Passive gains Aether (the Ledger Chip) gives that much more */
  var more=0;
  ((card._raw||{}).abilities||card.entries||[]).forEach(function(e){
    if(String(e.kind||"").toLowerCase()!=="passive") return;
    var m=String(e.text||"").match(/\[\[gain Aether (\d+)\]\]/i); if(m) more+=parseInt(m[1],10)||0;
  });
  return Math.max(0,Math.min(10,chipBase(card)+more));
}
function chipBase(card){
  var v=card.aetherValue;
  if(v!==undefined && v!==null && String(v).trim()!==""){
    var n=parseInt(v,10);
    if(!isNaN(n)) return Math.max(0,Math.min(10,n));
  }
  var lvl=Math.max(1,Math.min(6,parseInt(card.level,10)||1));
  return lvl+(CHIP_RARITY_BONUS[String(card.rarity||"").toLowerCase()]||0);
}

/* ---- line of sight ----------------------------------------------------
   Handbook 15.3. A Unit sees a target if any point in its tile can be joined to
   any point in the target's tile by a straight line touching no wall. Walls sit
   on the shared edge between two neighbouring hexes, so each is one hex edge.

   Geometry is pointy-top on unit hexes, matching the board: a hex's centre is
   (sqrt3*(q+r/2), 1.5*r) and its corners sit at 60k-30 degrees. The edge a hex
   shares with its neighbour in direction i runs from corner i to corner i+1. */
var LOS_DIRS=[[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]];
function hexCentre(q,r){ return {x:Math.sqrt(3)*(q+r/2), y:1.5*r}; }
function hexCorner(q,r,k){
  var c=hexCentre(q,r), a=Math.PI/180*(60*k-30);
  return {x:c.x+Math.cos(a), y:c.y+Math.sin(a)};
}
function wallSegments(walls){
  var out=[];
  Object.keys(walls||{}).forEach(function(key){
    var ends=key.split("|"); if(ends.length!==2) return;
    var a=hexParse(ends[0]), b=hexParse(ends[1]);
    for(var i=0;i<6;i++){
      if(a.q+LOS_DIRS[i][0]===b.q && a.r+LOS_DIRS[i][1]===b.r){
        out.push([hexCorner(a.q,a.r,i), hexCorner(a.q,a.r,(i+1)%6)]);
        return;
      }
    }
  });
  return out;
}
/* Closed segments: touching counts, including at an end. */
function segTouch(p1,p2,p3,p4){
  function cross(o,a,b){ return (a.x-o.x)*(b.y-o.y)-(a.y-o.y)*(b.x-o.x); }
  function on(o,a,b){ return Math.min(o.x,a.x)-1e-9<=b.x && b.x<=Math.max(o.x,a.x)+1e-9 &&
                             Math.min(o.y,a.y)-1e-9<=b.y && b.y<=Math.max(o.y,a.y)+1e-9; }
  var d1=cross(p3,p4,p1), d2=cross(p3,p4,p2), d3=cross(p1,p2,p3), d4=cross(p1,p2,p4);
  var E=1e-9;
  if(((d1>E&&d2<-E)||(d1<-E&&d2>E)) && ((d3>E&&d4<-E)||(d3<-E&&d4>E))) return true;
  if(Math.abs(d1)<=E && on(p3,p4,p1)) return true;
  if(Math.abs(d2)<=E && on(p3,p4,p2)) return true;
  if(Math.abs(d3)<=E && on(p1,p2,p3)) return true;
  if(Math.abs(d4)<=E && on(p1,p2,p4)) return true;
  return false;
}
/* Points standing in for "any point in the tile": the centre, and the corners
   and edge midpoints pulled a little inward, so a line cannot run along an edge
   the tile shares with a walled neighbour and slip through. */
function tilePoints(q,r){
  var c=hexCentre(q,r), pts=[c], IN=0.86;
  for(var k=0;k<6;k++){
    var a=hexCorner(q,r,k), b=hexCorner(q,r,(k+1)%6);
    pts.push({x:c.x+(a.x-c.x)*IN, y:c.y+(a.y-c.y)*IN});
    pts.push({x:c.x+((a.x+b.x)/2-c.x)*IN, y:c.y+((a.y+b.y)/2-c.y)*IN});
  }
  return pts;
}
function lineOfSight(from, to, walls, segs){
  if(!from||!to) return false;
  if(from.q===to.q && from.r===to.r) return true;
  segs=segs||wallSegments(walls);
  if(!segs.length) return true;
  var A=tilePoints(from.q,from.r), B=tilePoints(to.q,to.r);
  /* the centre line first: it is the usual answer and the cheapest */
  var order=[];
  for(var i=0;i<A.length;i++) for(var j=0;j<B.length;j++) order.push([i,j]);
  for(var n=0;n<order.length;n++){
    var p=A[order[n][0]], q=B[order[n][1]];
    var minx=Math.min(p.x,q.x)-1, maxx=Math.max(p.x,q.x)+1,
        miny=Math.min(p.y,q.y)-1, maxy=Math.max(p.y,q.y)+1;
    var blocked=false;
    for(var w=0;w<segs.length;w++){
      var s1=segs[w][0], s2=segs[w][1];
      if(Math.max(s1.x,s2.x)<minx||Math.min(s1.x,s2.x)>maxx||
         Math.max(s1.y,s2.y)<miny||Math.min(s1.y,s2.y)>maxy) continue;
      if(segTouch(p,q,s1,s2)){ blocked=true; break; }
    }
    if(!blocked) return true;
  }
  return false;
}

root.KETER_RULES = {
  version: "1.0",
  makeUnit: makeUnit, unitFromCard: unitFromCard,
  hasStatus: hasStatus, addStatus: addStatus, dropStatus: dropStatus, stunBlock: lockBlock, lockBlock: lockBlock, isLock: isLock, LOCKS: LOCKS, LOCK_MAX_TURNS: LOCK_MAX_TURNS, STUN_MAX_TURNS: STUN_MAX_TURNS,
  effective: effective,
  hit: hit, hardenedCut: hardenedCut, heal: heal, gain: gain,
  actionEffect: actionEffect, canAfford: canAfford, useAction: useAction,
  endTurn: endTurn, outcome: outcome,
  makeDice: makeDice, resolveAttack: resolveAttack, attack: attack,
  rollsFor: rollsFor, faceOf: faceOf, DIE: DIE,
  bestAction: bestAction, nextComboAction: nextComboAction,
  enemyTurn: enemyTurn, playerTurn: playerTurn, runRound: runRound,
  runCombat: runCombat,
  chooseTarget: chooseTarget, movePlan: movePlan,
  supportPlan: supportPlan, escortTarget: escortTarget,
  chipValue: chipValue,
  lineOfSight: lineOfSight, wallSegments: wallSegments,
  statusN: statusN, statusTurns:statusTurns, strengthless:strengthless, statusOf: statusOf, rechargeTick: rechargeTick, turnEndTick: turnEndTick,
  aetherFromHero: aetherFromHero, aetherIncome: aetherIncome,
  aetherAdd: aetherAdd, aetherCanPay: aetherCanPay, aetherPay: aetherPay,
  aetherTotal: aetherTotal,
  hexKey: hexKey, hexParse: hexParse, hexDistance: hexDistance,
  hexNeighbours: hexNeighbours, hexLine: hexLine, reachable: reachable,
  behaviors: function(){ return BEH; },
  hooks: HOOKS
};
})(typeof window!=="undefined" ? window : this);
