/* The test cards' pixel art, drawn from simple shapes so one description serves
   square pixels and hex pixels alike. Runs in the app, where the palette and the
   Forge's layout are to hand. Returns {id: picture}. */
(function(){
  var P=window.KETER_PX;
  function idx(h){ return P.nearest(parseInt(h.slice(1,3),16),parseInt(h.slice(3,5),16),parseInt(h.slice(5,7),16)); }
  var OUT=idx("#14121d");
  /* shapes in a unit square: circle, rect, ring, line (thick), diamond */
  function inside(s,x,y,grow){
    var g=grow||0;
    if(s.t==="c") return Math.hypot(x-s.x,y-s.y)<=s.r+g;
    if(s.t==="r") return x>=s.x0-g && x<=s.x1+g && y>=s.y0-g && y<=s.y1+g;
    if(s.t==="ring"){ var d=Math.hypot(x-s.x,y-s.y); return d<=s.r+g && d>=s.r-s.w-g; }
    if(s.t==="d") return Math.abs(x-s.x)/(s.rx+g)+Math.abs(y-s.y)/(s.ry+g)<=1;
    if(s.t==="l"){ var vx=s.x1-s.x0, vy=s.y1-s.y0, L=vx*vx+vy*vy, t=Math.max(0,Math.min(1,((x-s.x0)*vx+(y-s.y0)*vy)/L));
      return Math.hypot(x-(s.x0+t*vx), y-(s.y0+t*vy))<=s.w+g; }
    return false;
  }
  /* the colour at a point of a figure: outlines first, then fills, in order */
  function figureAt(shapes,x,y){
    var v=0;
    for(var i=0;i<shapes.length;i++){ var s=shapes[i];
      if(s.noOutline) continue;
      if(inside(s,x,y,0.035) && !inside(s,x,y,0)) v=v||OUT; }
    for(var j=0;j<shapes.length;j++){ var s2=shapes[j];
      if(inside(s2,x,y,0)){ v=s2.dith ? (((Math.floor(x*40)+Math.floor(y*40))&1)?idx(s2.c):idx(s2.dith)) : idx(s2.c); } }
    return v;
  }
  /* ---- figures ---- */
  function humanoid(o){
    var s=[];
    s.push({t:"r",x0:0.36,y0:0.66,x1:0.46,y1:0.92,c:o.legs},{t:"r",x0:0.54,y0:0.66,x1:0.64,y1:0.92,c:o.legs});
    s.push({t:"r",x0:0.20,y0:0.38,x1:0.30,y1:0.64,c:o.arm},{t:"r",x0:0.70,y0:0.38,x1:0.80,y1:0.64,c:o.arm2||o.arm});
    s.push({t:"r",x0:0.30,y0:0.36,x1:0.70,y1:0.68,c:o.body});
    s.push({t:"r",x0:0.30,y0:0.56,x1:0.70,y1:0.68,c:o.shade,noOutline:true});
    if(o.core) s.push({t:"c",x:0.5,y:0.47,r:0.045,c:o.core,noOutline:true});
    if(o.box) s.push({t:"r",x0:0.36,y0:0.08,x1:0.64,y1:0.34,c:o.head});
    else s.push({t:"c",x:0.5,y:0.22,r:0.14,c:o.head});
    s.push({t:"r",x0:0.39,y0:0.18,x1:0.61,y1:0.25,c:o.visor,noOutline:true});
    (o.extra||[]).forEach(function(e){ s.push(e); });
    return s;
  }
  var FIG={
    "Test Warden":humanoid({legs:"#485262",arm:"#5e718e",body:"#88a3bc",shade:"#5e718e",head:"#c9d4fd",visor:"#22f0ff",core:"#ff7a1a",
      extra:[{t:"l",x0:0.62,y0:0.5,x1:0.98,y1:0.42,w:0.035,c:"#322f35"}]}),
    "Test Striker":humanoid({legs:"#654956",arm:"#b25266",arm2:"#ff2a3c",body:"#e27285",shade:"#b25266",head:"#8aa1f6",visor:"#ff7a1a",core:"#22f0ff",
      extra:[{t:"c",x:0.8,y:0.66,r:0.07,c:"#ff2a3c"}]}),
    "Test Sapper":humanoid({legs:"#3d6f43",arm:"#477238",body:"#61a53f",shade:"#3d6f43",head:"#eeb59c",visor:"#171516",
      extra:[{t:"r",x0:0.64,y0:0.40,x1:0.82,y1:0.60,c:"#e88a36"}]}),
    "Test Grunt":humanoid({legs:"#4f342f",arm:"#612721",body:"#b9451d",shade:"#612721",head:"#d39741",visor:"#ff2a3c",
      extra:[{t:"l",x0:0.78,y0:0.62,x1:0.92,y1:0.28,w:0.04,c:"#855f39"}]}),
    "Test Gunner":humanoid({box:true,legs:"#323232",arm:"#595757",body:"#807b7a",shade:"#595757",head:"#a69e9a",visor:"#ff2a3c",
      extra:[{t:"r",x0:0.72,y0:0.44,x1:1.0,y1:0.52,c:"#171516"}]}),
    "Test Hacker":humanoid({legs:"#322f35",arm:"#494182",body:"#7864c6",shade:"#494182",head:"#322f35",visor:"#c23bff",
      extra:[{t:"r",x0:0.06,y0:0.44,x1:0.24,y1:0.58,c:"#8a3dff"}]}),
    "Test Juggernaut":humanoid({box:true,legs:"#36282b",arm:"#886e6a",body:"#b29476",shade:"#886e6a",head:"#bda499",visor:"#6dff3a",core:"#6dff3a",
      extra:[{t:"r",x0:0.14,y0:0.30,x1:0.34,y1:0.44,c:"#594d4d"},{t:"r",x0:0.66,y0:0.30,x1:0.86,y1:0.44,c:"#594d4d"}]}),
    "Test Scout":humanoid({legs:"#3a4a3f",arm:"#566b4a",body:"#7f9c5b",shade:"#566b4a",head:"#c6b858",visor:"#3dffc8",
      extra:[{t:"l",x0:0.66,y0:0.46,x1:0.94,y1:0.36,w:0.03,c:"#322f35"},{t:"ring",x:0.5,y:0.22,r:0.2,w:0.03,c:"#3dffc8",noOutline:true}]}),
    "Test Overseer":humanoid({legs:"#322f35",arm:"#64364b",body:"#b25266",shade:"#64364b",head:"#e3cddf",visor:"#ff2bd6",core:"#ff2bd6",
      extra:[{t:"ring",x:0.5,y:0.14,r:0.2,w:0.035,c:"#ff2bd6",noOutline:true}]}),
    /* Revision 16.1 */
    "Test Skirmisher":humanoid({legs:"#3a4a3f",arm:"#5e718e",body:"#3dffc8",shade:"#2b8a7a",head:"#c9d4fd",visor:"#ff7a1a",
      extra:[{t:"l",x0:0.72,y0:0.6,x1:0.96,y1:0.34,w:0.035,c:"#e8e8f0"},{t:"l",x0:0.36,y0:0.92,x1:0.24,y1:0.98,w:0.03,c:"#22f0ff"},{t:"l",x0:0.64,y0:0.92,x1:0.76,y1:0.98,w:0.03,c:"#22f0ff"}]}),
    "Test Skitter":[{t:"c",x:0.5,y:0.46,r:0.2,c:"#807b7a"},{t:"c",x:0.5,y:0.42,r:0.08,c:"#171516",noOutline:true},{t:"c",x:0.46,y:0.4,r:0.03,c:"#ff2a3c",noOutline:true},{t:"c",x:0.56,y:0.4,r:0.03,c:"#ff2a3c",noOutline:true},
      {t:"l",x0:0.34,y0:0.5,x1:0.12,y1:0.3,w:0.03,c:"#595757"},{t:"l",x0:0.12,y0:0.3,x1:0.06,y1:0.62,w:0.025,c:"#595757"},
      {t:"l",x0:0.66,y0:0.5,x1:0.88,y1:0.3,w:0.03,c:"#595757"},{t:"l",x0:0.88,y0:0.3,x1:0.94,y1:0.62,w:0.025,c:"#595757"},
      {t:"l",x0:0.38,y0:0.6,x1:0.22,y1:0.86,w:0.03,c:"#595757"},{t:"l",x0:0.62,y0:0.6,x1:0.78,y1:0.86,w:0.03,c:"#595757"},
      {t:"l",x0:0.44,y0:0.64,x1:0.4,y1:0.9,w:0.025,c:"#e88a36"},{t:"l",x0:0.56,y0:0.64,x1:0.6,y1:0.9,w:0.025,c:"#e88a36"}],
    /* Revision 16.3 */
    "Test Bulwark":humanoid({box:true,legs:"#465456",arm:"#5e718e",body:"#c6b858",shade:"#939446",head:"#a69e9a",visor:"#f0ff2a",
      extra:[{t:"r",x0:0.04,y0:0.34,x1:0.26,y1:0.74,c:"#88a3bc"},{t:"r",x0:0.08,y0:0.40,x1:0.22,y1:0.46,c:"#f0ff2a",noOutline:true},{t:"l",x0:0.72,y0:0.5,x1:0.98,y1:0.44,w:0.035,c:"#322f35"}]}),
    "Test Swarm":[{t:"c",x:0.3,y:0.62,r:0.13,c:"#7f9c5b"},{t:"c",x:0.52,y:0.48,r:0.15,c:"#939446"},{t:"c",x:0.72,y:0.64,r:0.12,c:"#566b4a"},
      {t:"c",x:0.27,y:0.6,r:0.03,c:"#ff2a3c",noOutline:true},{t:"c",x:0.49,y:0.45,r:0.035,c:"#ff2a3c",noOutline:true},{t:"c",x:0.57,y:0.45,r:0.035,c:"#ff2a3c",noOutline:true},{t:"c",x:0.7,y:0.62,r:0.03,c:"#ff2a3c",noOutline:true},
      {t:"l",x0:0.2,y0:0.74,x1:0.12,y1:0.86,w:0.02,c:"#3a4a3f"},{t:"l",x0:0.4,y0:0.72,x1:0.36,y1:0.86,w:0.02,c:"#3a4a3f"},{t:"l",x0:0.62,y0:0.62,x1:0.6,y1:0.84,w:0.02,c:"#3a4a3f"},{t:"l",x0:0.82,y0:0.74,x1:0.9,y1:0.86,w:0.02,c:"#3a4a3f"}],
    "Test Drone":[{t:"l",x0:0.12,y0:0.3,x1:0.88,y1:0.3,w:0.03,c:"#595757"},{t:"r",x0:0.06,y0:0.24,x1:0.3,y1:0.28,c:"#a69e9a"},{t:"r",x0:0.7,y0:0.24,x1:0.94,y1:0.28,c:"#a69e9a"},
      {t:"c",x:0.5,y:0.5,r:0.24,c:"#88a3bc"},{t:"c",x:0.5,y:0.5,r:0.1,c:"#171516",noOutline:true},{t:"c",x:0.5,y:0.5,r:0.05,c:"#22f0ff",noOutline:true},
      {t:"l",x0:0.36,y0:0.7,x1:0.28,y1:0.86,w:0.025,c:"#595757"},{t:"l",x0:0.64,y0:0.7,x1:0.72,y1:0.86,w:0.025,c:"#595757"}],
    "Test Battery":[{t:"r",x0:0.32,y0:0.2,x1:0.68,y1:0.86,c:"#465456"},{t:"r",x0:0.42,y0:0.12,x1:0.58,y1:0.2,c:"#807b7a"},
      {t:"r",x0:0.38,y0:0.5,x1:0.62,y1:0.8,c:"#3dffc8",noOutline:true},{t:"r",x0:0.38,y0:0.3,x1:0.62,y1:0.46,c:"#171516",noOutline:true}]
  };
  /* v13.0: the stand-in skins, one for each body plan */
  var STAND={
    "Bipedal":humanoid({box:true,legs:"#465456",arm:"#64878c",body:"#8ac4c3",shade:"#64878c",head:"#afe9df",visor:"#22f0ff",core:"#22f0ff",
      extra:[{t:"l",x0:0.66,y0:0.52,x1:0.98,y1:0.46,w:0.035,c:"#2c3438"},{t:"r",x0:0.66,y0:0.46,x1:0.8,y1:0.56,c:"#2c3438"}]}),
    "Quadcopter":[{t:"l",x0:0.5,y0:0.46,x1:0.18,y1:0.22,w:0.03,c:"#465456"},{t:"l",x0:0.5,y0:0.46,x1:0.82,y1:0.22,w:0.03,c:"#465456"},
      {t:"l",x0:0.5,y0:0.46,x1:0.18,y1:0.66,w:0.03,c:"#465456"},{t:"l",x0:0.5,y0:0.46,x1:0.82,y1:0.66,w:0.03,c:"#465456"},
      {t:"d",x:0.18,y:0.2,rx:0.15,ry:0.05,c:"#afe9df"},{t:"d",x:0.82,y:0.2,rx:0.15,ry:0.05,c:"#afe9df"},
      {t:"d",x:0.18,y:0.64,rx:0.15,ry:0.05,c:"#afe9df"},{t:"d",x:0.82,y:0.64,rx:0.15,ry:0.05,c:"#afe9df"},
      {t:"c",x:0.5,y:0.46,r:0.16,c:"#8ac4c3"},{t:"r",x0:0.38,y0:0.5,x1:0.62,y1:0.6,c:"#64878c",noOutline:true},
      {t:"c",x:0.5,y:0.44,r:0.06,c:"#171516",noOutline:true},{t:"c",x:0.5,y:0.44,r:0.03,c:"#22f0ff",noOutline:true},
      {t:"l",x0:0.44,y0:0.62,x1:0.4,y1:0.8,w:0.02,c:"#465456"},{t:"l",x0:0.56,y0:0.62,x1:0.6,y1:0.8,w:0.02,c:"#465456"}],
    "Quadruped":[{t:"l",x0:0.28,y0:0.56,x1:0.2,y1:0.9,w:0.04,c:"#465456"},{t:"l",x0:0.4,y0:0.56,x1:0.42,y1:0.9,w:0.04,c:"#465456"},
      {t:"l",x0:0.62,y0:0.56,x1:0.58,y1:0.9,w:0.04,c:"#465456"},{t:"l",x0:0.74,y0:0.56,x1:0.82,y1:0.9,w:0.04,c:"#465456"},
      {t:"r",x0:0.18,y0:0.38,x1:0.8,y1:0.58,c:"#8ac4c3"},{t:"r",x0:0.18,y0:0.5,x1:0.8,y1:0.58,c:"#64878c",noOutline:true},
      {t:"l",x0:0.18,y0:0.42,x1:0.06,y1:0.3,w:0.02,c:"#465456"},
      {t:"r",x0:0.76,y0:0.24,x1:0.96,y1:0.42,c:"#afe9df"},{t:"r",x0:0.86,y0:0.29,x1:0.94,y1:0.34,c:"#22f0ff",noOutline:true},
      {t:"r",x0:0.36,y0:0.3,x1:0.56,y1:0.38,c:"#2c3438"}],
    "Hexapod":[{t:"l",x0:0.5,y0:0.38,x1:0.24,y1:0.28,w:0.03,c:"#465456"},{t:"l",x0:0.24,y0:0.28,x1:0.12,y1:0.4,w:0.03,c:"#465456"},
      {t:"l",x0:0.5,y0:0.52,x1:0.2,y1:0.5,w:0.03,c:"#465456"},{t:"l",x0:0.2,y0:0.5,x1:0.1,y1:0.64,w:0.03,c:"#465456"},
      {t:"l",x0:0.5,y0:0.66,x1:0.24,y1:0.74,w:0.03,c:"#465456"},{t:"l",x0:0.24,y0:0.74,x1:0.14,y1:0.9,w:0.03,c:"#465456"},
      {t:"l",x0:0.5,y0:0.38,x1:0.76,y1:0.28,w:0.03,c:"#465456"},{t:"l",x0:0.76,y0:0.28,x1:0.88,y1:0.4,w:0.03,c:"#465456"},
      {t:"l",x0:0.5,y0:0.52,x1:0.8,y1:0.5,w:0.03,c:"#465456"},{t:"l",x0:0.8,y0:0.5,x1:0.9,y1:0.64,w:0.03,c:"#465456"},
      {t:"l",x0:0.5,y0:0.66,x1:0.76,y1:0.74,w:0.03,c:"#465456"},{t:"l",x0:0.76,y0:0.74,x1:0.86,y1:0.9,w:0.03,c:"#465456"},
      {t:"d",x:0.5,y:0.58,rx:0.13,ry:0.24,c:"#8ac4c3"},{t:"d",x:0.5,y:0.64,rx:0.07,ry:0.13,c:"#64878c",noOutline:true},
      {t:"c",x:0.5,y:0.26,r:0.09,c:"#afe9df"},{t:"c",x:0.46,y:0.25,r:0.025,c:"#22f0ff",noOutline:true},{t:"c",x:0.54,y:0.25,r:0.025,c:"#22f0ff",noOutline:true}],
    "Octopod":(function(){ var s=[], k, a, b;
      for(k=0;k<8;k++){ a=Math.PI/4*k+Math.PI/8; b=a+0.35;
        s.push({t:"l",x0:0.5,y0:0.5,x1:0.5+0.3*Math.cos(a),y1:0.5+0.3*Math.sin(a),w:0.028,c:"#465456"});
        s.push({t:"l",x0:0.5+0.3*Math.cos(a),y0:0.5+0.3*Math.sin(a),x1:0.5+0.44*Math.cos(b),y1:0.5+0.44*Math.sin(b),w:0.024,c:"#465456"}); }
      s.push({t:"c",x:0.5,y:0.5,r:0.18,c:"#8ac4c3"},{t:"c",x:0.5,y:0.55,r:0.1,c:"#64878c",noOutline:true},
        {t:"c",x:0.44,y:0.45,r:0.03,c:"#22f0ff",noOutline:true},{t:"c",x:0.56,y:0.45,r:0.03,c:"#22f0ff",noOutline:true},{t:"c",x:0.5,y:0.4,r:0.025,c:"#22f0ff",noOutline:true});
      return s; })()
  };
  Object.keys(STAND).forEach(function(k){ FIG["Stand-in \u00b7 "+k]=STAND[k]; });
  /* ---- emblems for everything that isn't a Unit ---- */
  var EMB={
    "Test Piercing Rounds":[{t:"l",x0:0.1,y0:0.7,x1:0.9,y1:0.3,w:0.03,c:"#f0ff2a",noOutline:true},{t:"d",x:0.62,y:0.44,rx:0.12,ry:0.07,c:"#d6a851"},{t:"d",x:0.38,y:0.56,rx:0.12,ry:0.07,c:"#d6a851"}],
    "Test Overclock Routine":[{t:"ring",x:0.5,y:0.5,r:0.3,w:0.1,c:"#807b7a"},{t:"l",x0:0.55,y0:0.18,x1:0.42,y1:0.52,w:0.04,c:"#f0ff2a",noOutline:true},{t:"l",x0:0.42,y0:0.52,x1:0.58,y1:0.5,w:0.04,c:"#f0ff2a",noOutline:true},{t:"l",x0:0.58,y0:0.5,x1:0.45,y1:0.84,w:0.04,c:"#f0ff2a",noOutline:true}],
    "Test Plating":[{t:"d",x:0.5,y:0.5,rx:0.3,ry:0.4,c:"#88a3bc"},{t:"d",x:0.5,y:0.5,rx:0.18,ry:0.26,c:"#5e718e",noOutline:true},{t:"c",x:0.5,y:0.5,r:0.05,c:"#22f0ff",noOutline:true}],
    "Test Targeting Suite":[{t:"ring",x:0.5,y:0.5,r:0.32,w:0.05,c:"#ff2a3c",noOutline:true},{t:"l",x0:0.5,y0:0.1,x1:0.5,y1:0.9,w:0.02,c:"#ff2a3c",noOutline:true},{t:"l",x0:0.1,y0:0.5,x1:0.9,y1:0.5,w:0.02,c:"#ff2a3c",noOutline:true},{t:"c",x:0.5,y:0.5,r:0.05,c:"#f0ff2a",noOutline:true}],
    "Test Mortar Strike":[{t:"c",x:0.5,y:0.58,r:0.34,c:"#e88a36",dith:"#b9451d"},{t:"c",x:0.5,y:0.6,r:0.2,c:"#f8c53a"},{t:"c",x:0.5,y:0.62,r:0.09,c:"#fff089",noOutline:true}],
    "Test Snare":[{t:"l",x0:0.15,y0:0.2,x1:0.85,y1:0.8,w:0.03,c:"#a69e9a"},{t:"l",x0:0.85,y0:0.2,x1:0.15,y1:0.8,w:0.03,c:"#a69e9a"},{t:"ring",x:0.5,y:0.5,r:0.2,w:0.05,c:"#cbc6c1"}],
    "Test Strip":[{t:"l",x0:0.25,y0:0.78,x1:0.66,y1:0.36,w:0.06,c:"#a69e9a"},{t:"ring",x:0.72,y:0.3,r:0.14,w:0.06,c:"#a69e9a"}],
    "Test Rally":[{t:"l",x0:0.3,y0:0.14,x1:0.3,y1:0.88,w:0.025,c:"#807b7a"},{t:"r",x0:0.32,y0:0.16,x1:0.78,y1:0.46,c:"#22f0ff",dith:"#2f7bff"},{t:"d",x:0.55,y:0.31,rx:0.07,ry:0.07,c:"#f0ff2a",noOutline:true}],
    "Test Surge":[{t:"c",x:0.5,y:0.5,r:0.3,c:"#3dffc8",dith:"#22f0ff"},{t:"c",x:0.5,y:0.5,r:0.14,c:"#d0ffea",noOutline:true}],
    "Test Overcharge":[{t:"ring",x:0.5,y:0.5,r:0.3,w:0.06,c:"#2f7bff",noOutline:true},{t:"l",x0:0.56,y0:0.16,x1:0.4,y1:0.52,w:0.05,c:"#22f0ff",noOutline:true},{t:"l",x0:0.4,y0:0.52,x1:0.6,y1:0.5,w:0.05,c:"#22f0ff",noOutline:true},{t:"l",x0:0.6,y0:0.5,x1:0.44,y1:0.86,w:0.05,c:"#22f0ff",noOutline:true}],
    "Test Capacitor":[{t:"r",x0:0.34,y0:0.24,x1:0.66,y1:0.8,c:"#4f6f8f"},{t:"r",x0:0.42,y0:0.14,x1:0.58,y1:0.24,c:"#a69e9a"},{t:"r",x0:0.4,y0:0.5,x1:0.6,y1:0.74,c:"#3dffc8",noOutline:true},{t:"l",x0:0.4,y0:0.4,x1:0.6,y1:0.4,w:0.02,c:"#22f0ff",noOutline:true}],
    "Test Barrage":[{t:"c",x:0.3,y:0.66,r:0.16,c:"#e88a36",dith:"#b9451d"},{t:"c",x:0.56,y:0.42,r:0.2,c:"#e88a36",dith:"#b9451d"},{t:"c",x:0.74,y:0.7,r:0.13,c:"#e88a36",dith:"#b9451d"},{t:"c",x:0.56,y:0.42,r:0.09,c:"#fff089",noOutline:true},{t:"c",x:0.3,y:0.66,r:0.06,c:"#f8c53a",noOutline:true},{t:"c",x:0.74,y:0.7,r:0.05,c:"#f8c53a",noOutline:true}],
    "Test Drone Bank":[{t:"r",x0:0.14,y0:0.3,x1:0.86,y1:0.78,c:"#465456"},{t:"c",x:0.3,y:0.54,r:0.1,c:"#8ac4c3"},{t:"c",x:0.5,y:0.54,r:0.1,c:"#8ac4c3"},{t:"c",x:0.7,y:0.54,r:0.1,c:"#8ac4c3"},{t:"c",x:0.3,y:0.54,r:0.035,c:"#22f0ff",noOutline:true},{t:"c",x:0.5,y:0.54,r:0.035,c:"#22f0ff",noOutline:true},{t:"c",x:0.7,y:0.54,r:0.035,c:"#22f0ff",noOutline:true}],
    "Test Muster":[{t:"l",x0:0.3,y0:0.12,x1:0.3,y1:0.9,w:0.025,c:"#807b7a"},{t:"r",x0:0.32,y0:0.14,x1:0.8,y1:0.44,c:"#c6b858",dith:"#939446"},{t:"ring",x:0.56,y:0.29,r:0.09,w:0.03,c:"#f0ff2a",noOutline:true},{t:"c",x:0.56,y:0.29,r:0.025,c:"#f0ff2a",noOutline:true}],
    "Test Shockwave":[{t:"ring",x:0.5,y:0.5,r:0.42,w:0.04,c:"#22f0ff",noOutline:true},{t:"ring",x:0.5,y:0.5,r:0.28,w:0.05,c:"#2f7bff",noOutline:true},{t:"c",x:0.5,y:0.5,r:0.12,c:"#d0ffea",dith:"#22f0ff"}],
    "Test Stim":[{t:"l",x0:0.3,y0:0.75,x1:0.66,y1:0.3,w:0.07,c:"#dceaee"},{t:"l",x0:0.36,y0:0.66,x1:0.58,y1:0.39,w:0.04,c:"#6dff3a",noOutline:true},{t:"l",x0:0.7,y0:0.25,x1:0.82,y1:0.12,w:0.015,c:"#a69e9a"}],
    "Test Smoke":[{t:"c",x:0.38,y:0.55,r:0.2,c:"#cbc6c1",dith:"#a69e9a"},{t:"c",x:0.6,y:0.45,r:0.22,c:"#cbc6c1",dith:"#807b7a"},{t:"c",x:0.55,y:0.66,r:0.16,c:"#ecebe7"}],
    "Test Sandbags":[{t:"r",x0:0.14,y0:0.6,x1:0.5,y1:0.8,c:"#c6b858"},{t:"r",x0:0.5,y0:0.6,x1:0.86,y1:0.8,c:"#c6b858"},{t:"r",x0:0.32,y0:0.4,x1:0.68,y1:0.6,c:"#939446"}],
    "Test Repair Kit":[{t:"r",x0:0.22,y0:0.4,x1:0.78,y1:0.8,c:"#4f6f8f"},{t:"r",x0:0.4,y0:0.27,x1:0.6,y1:0.4,c:"#a69e9a"},{t:"l",x0:0.5,y0:0.47,x1:0.5,y1:0.73,w:0.05,c:"#ecebe7",noOutline:true},{t:"l",x0:0.37,y0:0.6,x1:0.63,y1:0.6,w:0.05,c:"#ecebe7",noOutline:true}],
    "Test Aegis Core":[{t:"d",x:0.5,y:0.5,rx:0.26,ry:0.36,c:"#8aa1f6"},{t:"d",x:0.5,y:0.5,rx:0.13,ry:0.18,c:"#f1f2ff",noOutline:true},{t:"ring",x:0.5,y:0.5,r:0.42,w:0.03,c:"#2f7bff",noOutline:true}],
    "Test Spark Chip":[{t:"d",x:0.5,y:0.5,rx:0.34,ry:0.34,c:"#465456"},{t:"d",x:0.5,y:0.5,rx:0.2,ry:0.2,c:"#2c3438",noOutline:true},{t:"l",x0:0.52,y0:0.3,x1:0.44,y1:0.52,w:0.035,c:"#f0ff2a",noOutline:true},{t:"l",x0:0.44,y0:0.52,x1:0.56,y1:0.5,w:0.035,c:"#f0ff2a",noOutline:true},{t:"l",x0:0.56,y0:0.5,x1:0.48,y1:0.7,w:0.035,c:"#f0ff2a",noOutline:true}]
  };
  /* ---- backgrounds for card art ---- */
  function bgAt(kind,x,y){  /* x in [0,aspect], y in [0,1] */
    var dither=((Math.floor(x*48)+Math.floor(y*48))&1);
    if(kind==="mars") return y<0.52 ? (y<0.26?idx("#612721"):(Math.abs(y-0.26)<0.03&&dither?idx("#612721"):idx("#b9451d"))) : (y<0.56&&dither?idx("#8c5b3e"):idx("#4f342f"));
    if(kind==="lab") return (Math.floor(x*12)%2===0 && Math.floor(y*8)%2===0) ? idx("#1b2447") : idx("#14121d");
    if(kind==="aether") return y<0.5 ? idx("#27412d") : (dither?idx("#2c3b39"):idx("#171819"));
    return idx("#171516");
  }
  /* one picture from a description, on square pixels or hex pixels */
  function paint(pic, fn){
    var buf=new Uint8Array(pic.w*pic.h);
    if(P.isHex(pic)){
      var L=P.hexLayout(pic), B=L.bounds;
      for(var i=0;i<buf.length;i++){ if(!L.valid[i]) continue; buf[i]=fn((L.cx[i]-B.minx)/B.w, (L.cy[i]-B.miny)/B.h, B.w/B.h); }
    } else {
      for(var y=0;y<pic.h;y++) for(var x=0;x<pic.w;x++) buf[y*pic.w+x]=fn((x+0.5)/pic.w,(y+0.5)/pic.h,pic.w/pic.h);
    }
    pic.frames[0].layers[0].px=P.encode(buf); P.refreshFlat(pic); return pic;
  }
  /* a token: the figure fills the canvas */
  function tokenFn(shapes){ return function(u,v){ return figureAt(shapes,u,v); }; }
  /* card art: background across the box, the figure in a square filling its height */
  function artFn(shapes,kind){ return function(u,v,aspect){
    var X=u*aspect, off=(aspect-1)/2, fx=X-off, f=(fx>=0&&fx<=1)?figureAt(shapes,fx,v):0;
    return f||bgAt(kind,X,v); }; }
  window.KETER_MAKE_TEST_ART=function(card, artHin, plan){
    var shapes=FIG[card.name]||EMB[card.name]; if(!shapes) return null;
    var slug=card.name.toLowerCase().replace(/[^a-z0-9]+/g,"_"), pre=plan.id||("px_test_"+slug);
    var out={};
    var bgKind=FIG[card.name]?(/enemy|elite|miniboss/.test(card.cardType)?"mars":"lab"):(/aether|sphere/.test(card.cardType)?"aether":"lab");
    var art = plan.art==="hex" ? P.blankHexArt(plan.across||40, artHin, plan.orient||"pointy", card.name+" art")
                               : (function(){ var sz=P.artSizeFor(artHin,2.270,plan.w||64); return P.blank(sz.w,sz.h,card.name+" art"); })();
    art.kind="art"; out[pre+"_art"]=paint(art, artFn(shapes,bgKind));
    if(plan.token){
      var tok = plan.token==="hex" ? P.blankHexagon(plan.side||9, plan.orient||"flat", card.name+" token")
                                   : P.blank(plan.size||32, plan.size||32, card.name+" token");
      tok.kind="token"; out[pre+"_token"]=paint(tok, tokenFn(shapes));
    }
    return out;
  };
})();
