/* Battlefield chunks (v14.7, game 0.20): a POI's battlefield grown from
   premade hexagons of tiles. The game does exactly the same (chunk_gen.gd);
   the tests hold the two to the same answer for every case.

   A chunk is a Sandbox floor of radius 3 (37 tiles) with chunk:{role, sides,
   skullMin, skullMax}: role is start, enemy, loot, exit or filler; sides says
   which of its six sides are open, in the order N, NE, SE, S, SW, NW (N being
   its top row, NE its column q = 3, SE the tiles with q + r = 3, S its bottom
   row, SW the column q = -3, NW the tiles with q + r = -3).

   Chunks sit on a lattice of hexagons: the six neighbours of the chunk at the
   middle are at SIDE_VEC. Each is placed turned by sixths, and maybe mirrored,
   so one chunk gives twelve layouts. An open side joins only an open side;
   where two chunks meet otherwise, a wall runs along the whole join. */
(function(){
  var R=3;
  var SIDE_VEC=[[4,-7],[7,-3],[3,4],[-4,7],[-7,3],[-3,-4]];
  var DIRS=[[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]];
  var MIRROR_SIDE=[4,3,2,1,0,5];
  var COUNT={small:3, medium:5, large:7};
  var PLAN={3:["start","filler","enemy"], 5:["start","filler","enemy","filler","loot"], 7:["start","filler","filler","enemy","enemy","loot","exit"]};
  var LABELS={0:"Enemy Spawn Tile",1:"Half Cover Barricade",2:"Loot Tile",3:"Player Spawn Tile",4:"Healing Station",5:"Full Cover Barricade"};
  var TRIES=8;

  /* the shared random numbers (as the World Map's own) */
  function mulberry(a){ a=a>>>0; return function(){ a=(a+0x6D2B79F5)>>>0; var t=a; t=Math.imul(t^(t>>>15),t|1); t^=t+Math.imul(t^(t>>>7),t|61); return ((t^(t>>>14))>>>0)/4294967296; }; }
  function hashStr(s){ var h=2166136261; s=String(s); for(var i=0;i<s.length;i++){ h^=s.charCodeAt(i); h=Math.imul(h,16777619); } return h>>>0; }
  function key(q,r){ return q+","+r; }
  function parse(k){ var p=String(k).split(","); return [parseInt(p[0],10)||0, parseInt(p[1],10)||0]; }
  function wk(a,b){ return a<b ? a+"|"+b : b+"|"+a; }

  /* a tile of a chunk, placed: mirrored (q,r -> r,q), then turned clockwise by sixths, then moved */
  function place(q,r,rot,mir,at){
    if(mir){ var t=q; q=r; r=t; }
    for(var i=0;i<rot;i++){ var nq=-r, nr=q+r; q=nq; r=nr; }
    return [q+at[0], r+at[1]];
  }
  /* a chunk's own tiles: its hexagon of radius 3 (any drawn outside it are left out) */
  function inside(a){ return Math.max(Math.abs(a[0]), Math.abs(a[1]), Math.abs(a[0]+a[1]))<=R; }
  function worldSide(i,rot,mir){ return ((mir?MIRROR_SIDE[i]:i)+rot)%6; }

  function isChunk(lv){ return !!(lv && lv.chunk && typeof lv.chunk==="object" && (lv.hexes||[]).length); }
  function districtOf(v){ var m=/^\s*(\d)/.exec(String(v||"")); return m?m[1]:""; }
  function fits(lv, district, skull){
    var c=lv.chunk, d=districtOf(lv.district);
    var lo=parseInt(c.skullMin,10)||1, hi=parseInt(c.skullMax,10)||6;
    return (d===String(district||"") || d==="") && skull>=lo && skull<=hi;
  }
  /* the chunks that can make a battlefield here, by role (each list sorted by name, so the order is the same everywhere) */
  function pools(chunks, district, skull){
    var out={start:[], enemy:[], loot:[], exit:[], filler:[]};
    (chunks||[]).filter(isChunk).filter(function(lv){ return fits(lv, district, skull); })
      .sort(function(a,b){ return a.name<b.name?-1:(a.name>b.name?1:0); })
      .forEach(function(lv){ var r=String(lv.chunk.role||"filler"); if(out[r]) out[r].push(lv); });
    return out;
  }
  /* whether there is enough to grow one: a Start and an Enemy chunk */
  function can(chunks, district, skull){ var p=pools(chunks, district, skull); return p.start.length>0 && p.enemy.length>0; }

  function sidesOf(lv){ var s=lv.chunk.sides||[]; var out=[]; for(var i=0;i<6;i++) out.push(s[i]!==false && s[i]!==0); return out; }

  /* one try at growing it; null if it couldn't */
  function grow(P, n, rng){
    var plan=PLAN[n], placed=[], used={};
    var free=function(p){ var out=[]; for(var k=0;k<6;k++){ var v=SIDE_VEC[k], s=key(p.at[0]+v[0], p.at[1]+v[1]); if(p.open[k] && !used[s]) out.push(k); } return out; };
    var pick=function(list){ return list[Math.floor(rng()*list.length)]; };
    var put=function(lv, at, rot, mir, hops, role){
      var s=sidesOf(lv), open=[0,0,0,0,0,0].map(function(){ return false; });
      for(var i=0;i<6;i++) open[worldSide(i,rot,mir)]=s[i];
      var p={lv:lv, at:at, rot:rot, mir:mir, open:open, hops:hops, role:role};
      placed.push(p); used[key(at[0],at[1])]=p; return p;
    };
    var start=pick(P.start);
    put(start, [0,0], Math.floor(rng()*6), rng()<0.5, 0, "start");
    for(var step=1; step<plan.length; step++){
      var role=plan[step], pool=P[role].length?P[role]:(P.filler.length?P.filler:P.enemy);
      var open=placed.filter(function(p){ return free(p).length>0; });
      if(!open.length) return null;
      var parent;
      if(role==="enemy"){
        parent=open[0]; open.forEach(function(p){ if(p.hops>parent.hops) parent=p; });
      } else if(role==="loot" || role==="exit"){
        var foes=open.filter(function(p){ return p.role==="enemy"; });
        parent=foes.length?foes[foes.length-1]:open[0];
        if(!foes.length) open.forEach(function(p){ if(p.hops>parent.hops) parent=p; });
      } else {
        parent=rng()<0.65?open[open.length-1]:pick(open);
      }
      var k=pick(free(parent)), v=SIDE_VEC[k], at=[parent.at[0]+v[0], parent.at[1]+v[1]], back=(k+3)%6;
      /* a chunk whose side facing back can be open: the pool from a random place, then each of its twelve layouts from a random one */
      var c0=Math.floor(rng()*pool.length), t0=Math.floor(rng()*12), done=false;
      for(var ci=0; ci<pool.length && !done; ci++){
        var lv=pool[(c0+ci)%pool.length], s=sidesOf(lv);
        for(var ti=0; ti<12 && !done; ti++){
          var t=(t0+ti)%12, rot=t%6, mir=t>=6;
          for(var i=0;i<6;i++) if(s[i] && worldSide(i,rot,mir)===back){ put(lv, at, rot, mir, parent.hops+1, role); done=true; break; }
        }
      }
      if(!done) return null;
    }
    return placed;
  }

  /* the placed chunks as one Sandbox floor */
  function assemble(placed, district, skull, size, name){
    var hexes=[], tiles={}, walls={}, marks=[], defs=[], defOf={};
    placed.forEach(function(p){
      var lv=p.lv, labels=lv.colorLabels||{}, ids={};
      (lv.symDefs||[]).forEach(function(d){
        var k=String(d.text||"")+"\u0001"+String(d.desc||"")+"\u0001"+JSON.stringify(d.hazard||null);
        if(!defOf[k]){ var nd={id:defs.length+1, text:d.text, desc:d.desc}; if(d.hazard) nd.hazard=JSON.parse(JSON.stringify(d.hazard)); defs.push(nd); defOf[k]=nd.id; }
        ids[d.id]=defOf[k];
      });
      var colourOf=function(c){
        if(c==null) return null; var lab=String(labels[c]||"").toLowerCase();
        for(var j=0;j<6;j++) if(LABELS[j].toLowerCase()===lab) return j;
        return null;
      };
      (lv.hexes||[]).forEach(function(pair){
        var a=parse(pair[0]); if(!inside(a)) return;
        var w=place(a[0],a[1],p.rot,p.mir,p.at), k=key(w[0],w[1]), src=pair[1]||{}, t={};
        var c=colourOf(src.c); if(c!==null) t.c=c;
        if(c===0) t.lvl=skull;
        if(!tiles[k]){ tiles[k]=t; hexes.push([k,t]); }
      });
      (lv.marks||[]).forEach(function(m){
        var a=parse(m[0]); if(!inside(a)) return;
        var w=place(a[0],a[1],p.rot,p.mir,p.at);
        if(ids[m[1]]) marks.push([key(w[0],w[1]), ids[m[1]]]);
      });
      (lv.walls||[]).forEach(function(wp){
        var e=String(wp[0]).split("|"); if(e.length!==2) return;
        var a=parse(e[0]), b=parse(e[1]); if(!inside(a) && !inside(b)) return;
        var wa=place(a[0],a[1],p.rot,p.mir,p.at), wb=place(b[0],b[1],p.rot,p.mir,p.at);
        walls[wk(key(wa[0],wa[1]), key(wb[0],wb[1]))]=-1;
      });
    });
    /* where two chunks meet and the sides aren't both open: a wall all along the join */
    var at={}; placed.forEach(function(p){ at[key(p.at[0],p.at[1])]=p; });
    placed.forEach(function(p){
      for(var k=0;k<3;k++){
        var v=SIDE_VEC[k], q=at[key(p.at[0]+v[0], p.at[1]+v[1])];
        if(!q || (p.open[k] && q.open[(k+3)%6])) continue;
        Object.keys(tiles).forEach(function(tk){
          var a=parse(tk);
          if(Math.max(Math.abs(a[0]-p.at[0]), Math.abs(a[1]-p.at[1]), Math.abs(a[0]-p.at[0]+a[1]-p.at[1]))>R) return;
          DIRS.forEach(function(d){
            var bq=a[0]+d[0], br=a[1]+d[1], bk=key(bq,br);
            if(!tiles[bk]) return;
            if(Math.max(Math.abs(bq-q.at[0]), Math.abs(br-q.at[1]), Math.abs(bq-q.at[0]+br-q.at[1]))>R) return;
            walls[wk(tk,bk)]=-1;
          });
        });
      }
    });
    var wl=Object.keys(walls).sort().map(function(k){ return [k,-1]; });
    var labs={}; Object.keys(LABELS).forEach(function(c){ labs[c]=LABELS[c]; });
    return {v:6, name:name, district:String(district||""), poiType:"Generated", level:String(skull), floorSize:"", battlefieldSize:size,
      notes:"Grown from chunks: "+placed.map(function(p){ return p.lv.name; }).join(", ")+".", rewards:"", sizeKey:"one", radius:R,
      labels:true, ink:false, hexes:hexes, marks:marks, walls:wl, symDefs:defs, nextDef:defs.length+1, colorLabels:labs,
      wallLabels:{"-1":"Solid wall"}, stamps:{}, generated:{chunks:placed.map(function(p){ return [p.lv.name, p.at[0], p.at[1], p.rot, p.mir?1:0, p.role]; })}};
  }

  /* whether every enemy pad, Loot Tile and symbol can be walked to from your pads */
  function connected(lv){
    var tiles={}, walls={}, start=[], need=[];
    lv.hexes.forEach(function(p){ tiles[p[0]]=p[1]; if(p[1].c===3) start.push(p[0]); if(p[1].c===0 || p[1].c===2) need.push(p[0]); });
    lv.marks.forEach(function(m){ need.push(m[0]); });
    lv.walls.forEach(function(w){ walls[w[0]]=1; });
    if(!start.length || !lv.hexes.some(function(p){ return p[1].c===0; })) return false;
    var seen={}, todo=start.slice(); start.forEach(function(k){ seen[k]=1; });
    while(todo.length){
      var k=todo.pop(), a=parse(k);
      DIRS.forEach(function(d){ var b=key(a[0]+d[0], a[1]+d[1]); if(tiles[b] && !seen[b] && !walls[wk(k,b)]){ seen[b]=1; todo.push(b); } });
    }
    return need.every(function(k){ return !!seen[k]; });
  }

  /* A battlefield for a District and Skull Level, of a size (small, medium or
     large), from a seed: the same seed gives the same battlefield. null when
     there aren't chunks enough. */
  function generate(chunks, district, skull, size, seed, name){
    size=COUNT[size]?size:"medium";
    var P=pools(chunks, district, skull);
    if(!P.start.length || !P.enemy.length) return null;
    var rng=mulberry(seed>>>0);
    for(var t=0;t<TRIES;t++){
      var placed=grow(P, COUNT[size], rng);
      if(!placed) continue;
      var lv=assemble(placed, district, skull, size, name||("Generated · D"+(district||"-")+" · Skull "+skull));
      if(connected(lv)) return lv;
    }
    return null;
  }

  /* a generated floor's key: everything it is made from, so it can be made again anywhere */
  function genKey(district, skull, size, seed){ return "gen|"+String(district||"")+"|"+skull+"|"+size+"|"+(seed>>>0); }
  function isGenKey(k){ return /^gen\|/.test(String(k||"")); }
  function fromKey(chunks, k){
    var p=String(k).split("|"); if(p.length!==5 || p[0]!=="gen") return null;
    return generate(chunks, p[1], parseInt(p[2],10)||1, p[3], parseInt(p[4],10)>>>0, "Generated · D"+(p[1]||"-")+" · Skull "+(parseInt(p[2],10)||1));
  }

  window.KETER_CHUNKGEN={R:R, SIDE_VEC:SIDE_VEC, COUNT:COUNT, PLAN:PLAN, isChunk:isChunk, pools:pools, can:can, generate:generate,
    genKey:genKey, isGenKey:isGenKey, fromKey:fromKey, place:place, worldSide:worldSide, connected:connected, hashStr:hashStr};
})();
