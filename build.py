#!/usr/bin/env python3
"""Bundle the KETER tools + guides into one offline HTML file."""
import base64, re, html, json, os

SRC = "/mnt/project"
OUT = "./pwa/index.html"

# ---------------------------------------------------------------- tool patch
MOBILE_PATCH = """
<script>var TOOLNAME=document.title.indexOf("Sandbox")>=0?"sandbox":"forge";</script>
<style id="keter-mobile-patch">
#keter-more{display:none;}
#keter-sheet{display:none;}
/* The HUD replaces a header that has room for everything on desktop, so above
   the breakpoint it steps aside and the ordinary controls come back. */
#keter-hud{display:none;}
/* Injected by KETER Companion bundler — phone support patch */
html,body{overscroll-behavior:none;}
html,body{height:100%;}
body{height:-webkit-fill-available;}
@supports (height:100dvh){ html,body{height:100dvh;} }
/* This was for the iOS zoom fix, but it also flattened every checkbox to zero
   width \u2014 they had not been rendering at all in the Forge. */
input:not([type=checkbox]):not([type=radio]),textarea,select{
  -webkit-appearance:none;appearance:none;}
input[type=checkbox],input[type=radio]{
  -webkit-appearance:checkbox;appearance:checkbox;
  width:15px;height:15px;accent-color:var(--cyan);flex:0 0 auto;}
input[type=radio]{-webkit-appearance:radio;appearance:radio;}
/* Four role chips at full size need more width than the panel has. */
#roleWrap{white-space:normal;}
#roleWrap .check{display:inline-flex;margin:0 4px 5px 0;
  padding:6px 7px;font-size:10.5px;gap:5px;}
#roleWrap .check input{width:13px !important;height:13px !important;}
button,.rail,summary,label,.tool{touch-action:manipulation;}

/* iOS zooms into any focused text field under 16px and never zooms back.
   Selects open a native picker instead, so they keep their compact size. */
@media (pointer:coarse){
  input:not([type=checkbox]):not([type=radio]):not([type=color]):not([type=range]),
  textarea{font-size:16px !important;}
  button,.btn,.tool,.rail{min-height:34px;}
  aside{-webkit-overflow-scrolling:touch;}
}

@media (max-width:900px){
  /* panel becomes an overlay drawer instead of eating half the screen */
  /* #13: the panel slides in and out the way the Ping and Task docks do,
     instead of appearing instantly. Width stays fixed so the contents do not
     reflow mid-animation; the transform is what moves. */
  aside{position:absolute !important;z-index:60;top:0;left:0;
        width:min(86vw,320px) !important;flex:0 0 auto !important;
        height:100% !important;box-shadow:14px 0 44px rgba(0,0,0,.72);
        transition:transform .22s ease, opacity .18s ease;
        transform:translateX(0);}
  aside.collapsed{width:min(86vw,320px) !important;
        transform:translateX(-102%);opacity:0;pointer-events:none;}

  /* The rail is the only way into every control in the tool, but at 26px with a
     hover-only tooltip it reads as a border. Make it a handle. */
  .rail{width:46px !important;flex:0 0 46px !important;
        color:var(--cyan) !important;font-size:11px !important;
        background:linear-gradient(90deg,rgba(87,216,227,.13),var(--panel-2)) !important;
        border-right:1px solid var(--line-hot) !important;
        gap:10px !important;}
  .rail::before{content:"›";writing-mode:horizontal-tb;font-size:21px;
        line-height:1;font-family:var(--mono);color:var(--cyan);}
  .rail:active{background:rgba(87,216,227,.24) !important;}

  /* Tapping the canvas outside an open panel should close it. The tools' own
     close control is a small guillemet inside the first section header, which
     scrolls out of view once the panel is scrolled. */
  #keter-scrim{position:fixed;inset:0;z-index:55;background:rgba(4,7,10,.5);
        display:none;}
  #keter-scrim.on{display:block;}

  /* Header keeps only identity and a pinned overflow control, so nothing the
     tool can do is ever parked off the right edge of the screen. */
  header .spacer{display:none !important;}
  header .brand h1{max-width:42vw;overflow:hidden;text-overflow:ellipsis;
        white-space:nowrap;font-size:15px !important;}
  #keter-more{display:none !important;margin-left:auto !important;flex:0 0 auto !important;
        min-width:46px;height:38px;border-radius:4px;cursor:pointer;
        background:var(--panel-2);border:1px solid var(--line-hot);
        color:var(--cyan);font-size:19px;line-height:1;font-family:var(--mono);}
  #keter-more:active{background:rgba(87,216,227,.2);}
}

/* the sheet itself is not width-gated: it is created only on phones */
#keter-sheet{position:fixed;inset:0;z-index:120;display:none;}
#keter-sheet.on{display:block;}
#keter-sheet .ks-scrim{position:absolute;inset:0;background:rgba(4,7,10,.62);}
#keter-sheet .ks-panel{position:absolute;left:0;right:0;bottom:0;
  max-height:78vh;display:flex;flex-direction:column;
  background:var(--panel);border-top:1px solid var(--line-hot);
  border-radius:10px 10px 0 0;box-shadow:0 -18px 48px rgba(0,0,0,.7);}
#keter-sheet .ks-head{display:flex;align-items:center;justify-content:space-between;
  padding:12px 14px;border-bottom:1px solid var(--line);
  font-family:var(--disp);font-size:12px;letter-spacing:1.6px;
  text-transform:uppercase;color:var(--cyan);}
#keter-sheet .ks-close{background:var(--panel-2);border:1px solid var(--line);
  border-radius:3px;color:var(--dim);font-size:11px;padding:8px 12px;cursor:pointer;
  font-family:var(--mono);}
#keter-sheet .ks-body{overflow-y:auto;-webkit-overflow-scrolling:touch;
  padding:12px 14px calc(16px + env(safe-area-inset-bottom));
  display:flex;flex-direction:column;gap:12px;}
#keter-sheet .ks-body .ctrl{display:block;}
#keter-sheet .ks-body .btn{width:100%;justify-content:center;}

#keter-tip{position:fixed;left:12px;right:12px;
  bottom:calc(14px + env(safe-area-inset-bottom));z-index:140;
  background:var(--panel);border:1px solid var(--line-hot);border-radius:6px;
  box-shadow:0 14px 40px rgba(0,0,0,.7);padding:13px 14px;display:none;}
#keter-tip.on{display:block;}
#keter-tip b{display:block;font-family:var(--disp);color:var(--cyan);font-size:13px;
  letter-spacing:.8px;margin-bottom:5px;}
#keter-tip span{font-size:12.5px;color:var(--dim);line-height:1.6;}
@media (max-width:900px){

  /* Header is a single fixed line. Nothing scrolls sideways any more, because
     everything that used to sit off the right edge now lives in the sheet. */
  /* #9 + #14: the tool's own name and subtitle go, since the highlighted tab
     at the bottom already says which tool you are in. The freed row becomes
     the HUD: the tappable title on the left, controls on the right. */
  header{padding:5px 8px !important;gap:7px !important;
         flex-wrap:nowrap !important;overflow:hidden !important;}
  header>*{flex:0 1 auto;min-width:0;}
  header .sub,header .brand h1{display:none !important;}
  header .brand{flex:0 0 auto;min-width:0;}
  header .brand .mark{font-size:15px;}
  #keter-hud{display:flex !important;align-items:center;gap:3px;margin-left:auto;
    flex:0 0 auto;}
  /* Eight buttons plus a title has to fit an iPhone SE at 375px, so the title
     yields first and the mark goes entirely. */
  header #nameTag{max-width:34vw;}
  @media (max-width:430px){
    header .brand{display:none !important;}
    #keter-hud{gap:2px;}
    header #nameTag{max-width:30vw;font-size:11px !important;}
  }
  @media (max-width:390px){
    .hudb{min-width:33px !important;padding:0 3px !important;font-size:14px !important;}
  }
  .hudb{min-width:37px;height:36px;border-radius:4px;cursor:pointer;
    background:var(--panel-2);border:1px solid var(--line);color:var(--dim);
    font-size:15px;line-height:1;font-family:var(--mono);padding:0 6px;
    display:flex;align-items:center;justify-content:center;position:relative;}
  .hudb:active{background:rgba(87,216,227,.2);color:var(--cyan);}
  .hudb.on{color:var(--cyan);border-color:var(--line-hot);}
  .hudb[disabled]{opacity:.35;}
  .hudb .cnt{position:absolute;top:-5px;right:-4px;min-width:15px;height:15px;
    border-radius:8px;background:var(--cyan);color:#04262b;font-size:9px;
    display:flex;align-items:center;justify-content:center;padding:0 3px;}
  .hudb .cnt.warn{background:#e0b34d;}
  /* the help button is lit while help mode is on, so it reads as a toggle */
/* The panel is absolutely positioned from the top of the screen at z-index 60,
     and the top bar had no stacking order of its own, so wherever the two met
     the panel won. With three buttons up here instead of two, the leftmost one
     \u2014 the one that closes the panel \u2014 ended up underneath it. The bar's
     controls have to be above everything they control. */
  #keter-hud{position:relative;z-index:70;}
  #hud-help{font-family:var(--mono);font-size:17px;font-weight:700;}
  #hud-help.on{background:rgba(87,216,227,.22);color:var(--cyan);
    border-color:var(--cyan);}
  header #nameTag,header #status{overflow:hidden;text-overflow:ellipsis;
         white-space:nowrap;min-width:0;}

  /* The docks are built to sit half off the right edge of a wide desktop canvas
     and slide in when opened. On a phone that peek lands outside the screen, so
     pin the stack to the viewport and leave a narrow tab showing. Their open and
     closed heights are the tools' own — do not override them. */
  #docks{position:fixed !important;right:0 !important;left:auto !important;
         top:auto !important;bottom:calc(8px + env(safe-area-inset-bottom)) !important;
         width:auto !important;align-items:flex-end !important;z-index:70;}
  .dock{width:min(74vw,262px) !important;
        transform:translateX(calc(100% - 104px)) !important;}
  .dock.open{transform:translateX(0) !important;}

  /* status strip wraps to several lines on a narrow screen; let it breathe
     rather than clipping mid-sentence */
  footer{font-size:10.5px !important;line-height:1.55 !important;
         gap:4px 14px !important;
         padding:6px 118px calc(6px + env(safe-area-inset-bottom)) 12px !important;}
  #pingBar{white-space:normal !important;overflow:visible !important;
           padding-right:118px !important;}
}
</style>
<script>
(function(){
  var PHONE = window.innerWidth <= 900;

  function panelEl(){ return document.getElementById('panelL')||document.getElementById('panel'); }
  function railEl(){ return document.getElementById('railL')||document.getElementById('rail'); }
  function toolId(){ return document.getElementById('panelL') ? 'poi' : 'forge'; }

  function collapsePanel(){
    var a=panelEl(), r=railEl();
    if(a) a.classList.add('collapsed');
    if(r) r.style.display='flex';
  }
  function openPanel(){
    var a=panelEl(), r=railEl();
    if(a) a.classList.remove('collapsed');
    if(r) r.style.display='none';
  }
  function closePanel(){
    try{ if(typeof window.togglePanel==='function' && !panelEl().classList.contains('collapsed')){
      window.togglePanel(); return;
    } }catch(e){}
    collapsePanel();
    try{ window.dispatchEvent(new Event('resize')); }catch(e){}
  }

  /* First launch of each tool: leave the panel open so the controls are the
     first thing seen, rather than a bare canvas with no visible tools. */
  var SEEN_KEY='keter-mobile-seen-panel-';
  function firstVisit(){
    try{
      var k=SEEN_KEY+toolId();
      if(localStorage.getItem(k)) return false;
      localStorage.setItem(k,'1');
      return true;
    }catch(e){ return false; }
  }

  function scrim(){
    var sc=document.getElementById('keter-scrim');
    if(!sc){
      sc=document.createElement('div');
      sc.id='keter-scrim';
      sc.addEventListener('click',function(ev){ ev.preventDefault(); closePanel(); });
      document.body.appendChild(sc);
    }
    return sc;
  }
  function syncScrim(){
    var a=panelEl();
    if(!a) return;
    var open = !a.classList.contains('collapsed');
    scrim().classList.toggle('on', open && window.innerWidth<=900);
  }
  function watchPanel(){
    var a=panelEl();
    if(!a||!window.MutationObserver) return;
    new MutationObserver(syncScrim).observe(a,{attributes:true,attributeFilter:['class']});
    var r=railEl();
    if(r) r.addEventListener('click',function(){ setTimeout(syncScrim,0); });
    syncScrim();
  }

  function pinDocks(){
    var d=document.getElementById('docks');
    if(d && d.parentNode!==document.body) document.body.appendChild(d);
  }

  /* Zoom to fit. Each tool has its own control, so drive theirs rather than
     imposing a CSS transform that would break hit-testing on the canvas. */
  function fitToScreen(){
    var qf=document.getElementById('qFit');          /* POI Sandbox */
    if(qf){ try{ qf.click(); }catch(e){} return; }

    var z=document.getElementById('oZoom'),          /* Card Forge */
        c=document.getElementById('card'),
        w=document.getElementById('viewport')||document.getElementById('wrap');
    if(!z||!c||!w) return;
    var cw=c.getBoundingClientRect().width;
    if(!cw) return;
    var avail=w.clientWidth-46;
    if(avail<=0) return;
    var cur=parseInt(z.value,10)||150;
    var target=Math.floor(cur*avail/cw/10)*10;
    target=Math.max(parseInt(z.min,10)||60,Math.min(parseInt(z.max,10)||320,target));
    if(target<cur){
      z.value=target;
      z.dispatchEvent(new Event('input',{bubbles:true}));
    }
  }

  /* ---------- overflow sheet ---------- */
  var origOrder=null;
  function sheetEl(){ return document.getElementById('keter-sheet'); }

  /* #6: one always-visible row of the controls that matter, so nothing
     essential is behind a scroll or a panel. Each button drives the tool's own
     control rather than reimplementing it. */
  /* Errors inside a tool are invisible to the shell, so they are posted out to
     it and land in the same action log. */
  (function(){
    function post(kind,text,extra){
      try{ parent.postMessage({__keterLog:1, kind:kind, text:String(text),
                               extra:extra===undefined?null:String(extra)}, "*"); }catch(e){}
    }
    window.addEventListener("error",function(e){
      post("ERROR","["+TOOLNAME+"] "+(e.message||"error"),(e.filename||"")+":"+(e.lineno||""));
    });
    var ce=console.error;
    console.error=function(){
      try{ post("ERROR","["+TOOLNAME+"] "+[].slice.call(arguments).join(" ")); }catch(x){}
      return ce.apply(console,arguments);
    };
    document.addEventListener("click",function(e){
      var el=e.target.closest?e.target.closest("button,[data-tool],[data-shape],.tool"):null;
      if(!el) return;
      var d=[];
      ["tool","shape"].forEach(function(k){ if(el.dataset&&el.dataset[k]) d.push(k+"="+el.dataset[k]); });
      post("tap","["+TOOLNAME+"] "+(el.id?("#"+el.id):"")+(d.length?" ["+d.join(" ")+"]":"")+
           ' "'+(el.textContent||"").trim().replace(/\s+/g," ").slice(0,30)+'"');
    },true);
  })();

  function buildHUD(){
    var h=document.querySelector('header');
    if(!h || document.getElementById('keter-hud')) return;
    var hud=document.createElement('div');
    hud.id='keter-hud';

    function btn(id,glyph,label,fn){
      var b=document.createElement('button');
      b.type='button'; b.className='hudb'; b.id='hud-'+id;
      b.innerHTML=glyph;
      b.setAttribute('data-help',label);
      b.setAttribute('aria-label',label.split('|')[0]);
      b.addEventListener('click',function(e){ e.preventDefault(); fn(b); });
      hud.appendChild(b);
      return b;
    }
    function tap(id){
      var el=document.getElementById(id);
      if(el) el.click();
    }

    /* #5: the panel toggle lives here, in one fixed place, instead of only at
       the top of a panel you have to scroll back up to. */
    btn('panel','\u2630','Panel|Show or hide the tool panel. It is the same button whether the panel is open or closed, so you never have to scroll to find it.',function(){
      var a=panelEl();
      if(!a) return;
      if(a.classList.contains('collapsed')){
        a.classList.remove('collapsed');
        var r=railEl(); if(r) r.style.display='none';
      }else{
        closePanel();
      }
      syncHUD();
    });

    if(document.getElementById('qPan'))
      /* Pan is already a tool in the Sandbox's own row. */

    if(document.getElementById('qUndo'))
      btn('undo','\u21B6','Undo|Step back one change.',function(){ tap('qUndo'); });
    else if(typeof undo==='function')
      btn('undo','\u21B6','Undo|Step back one change.',function(){ try{ undo(); }catch(e){} });

    if(document.getElementById('qRedo'))
      btn('redo','\u21B7','Redo|Step forward again.',function(){ tap('qRedo'); });
    else if(typeof redo==='function')
      btn('redo','\u21B7','Redo|Step forward again.',function(){ try{ redo(); }catch(e){} });

    /* Pings and Tasks have their own docks, which carry live counts and stay
       reachable with the panel open. A HUD copy of each was a second button
       for the same job. */
    /* Help sits in the top bar with the other controls. It used to float in the
       bottom corner because the open panel once covered the header \u2014 it no
       longer does (the panel ends well short of these buttons), and the corner
       was already crowded with the Ping and Tasks docks. */
    btn('help','?','Help|Labels every control on screen. Tap a highlighted control to read what it does, and Done to finish.',function(){
      toggleToolHelp();
    });
    btn('more','\u22EF','More|Everything else: exports, print settings and everything else this tool can do.',function(){
      var sheet=sheetEl();
      if(sheet) sheet.classList.add('on');
    });

    h.appendChild(hud);

    syncHUD();
    if(window.MutationObserver){
      var mo=new MutationObserver(function(){ syncHUD(); });
      ['dockPings','dockCheck'].forEach(function(id){
        var d=document.getElementById(id);
        if(d) mo.observe(d,{attributes:true,attributeFilter:['class']});
      });
      var a=panelEl();
      if(a) mo.observe(a,{attributes:true,attributeFilter:['class']});
    }
  }

  /* Turning help on opens the panel and its sections first: help can only label
     what is on screen, and both start shut, which once left the Sandbox
     labelling a handful of controls and looking broken. */
  function toggleToolHelp(){
    var layer=document.getElementById('helpLayer');
    var turningOn = !layer || getComputedStyle(layer).display==='none';
    if(turningOn){
      var a=panelEl();
      if(a){
        a.classList.remove('collapsed');
        var r=railEl(); if(r) r.style.display='none';
        [].forEach.call(a.querySelectorAll('details'),function(x){ x.open=true; });
        /* the scrim answered the hit test for the panel's own controls */
        var sc=document.getElementById('keter-scrim');
        if(sc) sc.classList.remove('on');
      }
      setTimeout(function(){
        if(typeof window.enterHelp==='function') window.enterHelp();
        else { var hb=document.getElementById('helpBtn'); if(hb) hb.click(); }
        syncHUD();
      },300);
      return;
    }
    if(typeof window.exitHelp==='function') window.exitHelp();
    else { var hb2=document.getElementById('helpBtn'); if(hb2) hb2.click(); }
    setTimeout(syncHUD,60);
  }

  /* Badges mirror the docks, so the counts are visible without opening them. */
  function syncHUD(){
    var hl0=document.getElementById('helpLayer');
    var hh=document.getElementById('hud-help');
    if(hh&&hl0) hh.classList.toggle('on',getComputedStyle(hl0).display!=='none');
    var a=panelEl(), pb=document.getElementById('hud-panel');
    if(pb&&a) pb.classList.toggle('on',!a.classList.contains('collapsed'));

    [['pings','dockPings','tabPings'],['tasks','dockCheck','tabCheck']].forEach(function(m){
      var b=document.getElementById('hud-'+m[0]);
      var dock=document.getElementById(m[1]);
      if(!b||!dock) return;
      b.classList.toggle('on',dock.classList.contains('open'));
      var badge=dock.querySelector('.badge');
      var old=b.querySelector('.cnt');
      if(old) old.remove();
      var n=badge?parseInt(badge.textContent,10):0;
      if(n>0){
        var c=document.createElement('span');
        c.className='cnt'+(badge.className.indexOf('bad')>=0||badge.className.indexOf('warn')>=0?' warn':'');
        c.textContent=n>99?'99':n;
        b.appendChild(c);
      }
    });

    var hb=document.getElementById('hud-help'), hl=document.getElementById('helpLayer');
    if(hb&&hl) hb.classList.toggle('on',getComputedStyle(hl).display!=='none');

    var pan=document.getElementById('hud-pan'), q=document.getElementById('qPan');
    if(pan&&q) pan.classList.toggle('on',q.classList.contains('on'));
  }

  function buildSheet(){
    var h=document.querySelector('header');
    if(!h || document.getElementById('keter-more')) return;

    origOrder=Array.prototype.slice.call(h.children);

    var more=document.createElement('button');
    more.id='keter-more'; more.type='button';
    more.setAttribute('aria-label','More controls and export');
    more.textContent='\u22EF';
    h.appendChild(more);

    var sheet=document.createElement('div');
    sheet.id='keter-sheet';
    sheet.innerHTML='<div class="ks-scrim"></div><div class="ks-panel">'+
      '<div class="ks-head"><span>Controls &amp; Export</span>'+
      '<button type="button" class="ks-close">Close</button></div>'+
      '<div class="ks-body"></div></div>';
    document.body.appendChild(sheet);

    function close(){ sheet.classList.remove('on'); }
    more.addEventListener('click',function(){ sheet.classList.add('on'); });
    sheet.querySelector('.ks-scrim').addEventListener('click',close);
    sheet.querySelector('.ks-close').addEventListener('click',close);
    sheet.querySelector('.ks-body').addEventListener('click',function(e){
      if(e.target.closest('button')) setTimeout(close,180);
    });
  }

  function keepInHeader(el){
    if(el.id==='keter-more') return true;
    if(el.classList && el.classList.contains('brand')) return true;
    if(el.id==='nameTag'||el.id==='status') return true;
    return false;
  }

  function moveToSheet(){
    var h=document.querySelector('header');
    var body=document.querySelector('#keter-sheet .ks-body');
    if(!h||!body) return;
    Array.prototype.slice.call(h.children).forEach(function(el){
      if(!keepInHeader(el)) body.appendChild(el);
    });
  }

  function restoreHeader(){
    var h=document.querySelector('header');
    if(!h||!origOrder) return;
    origOrder.forEach(function(el){ h.appendChild(el); });
    var more=document.getElementById('keter-more');
    if(more) h.appendChild(more);
  }

  var inSheet=false;
  function syncOverflow(){
    var narrow=window.innerWidth<=900;
    if(narrow && !inSheet){
      buildSheet(); moveToSheet(); buildHUD(); inSheet=true;
      collapsePanel(); pinDocks();
    }
    else if(!narrow && inSheet){ restoreHeader(); inSheet=false; }
    if(!narrow){
      /* Undo the inline styles the phone layout set, or a resized desktop
         window keeps a hidden panel and a stranded rail. */
      var r=railEl(), a=panelEl(), d=document.getElementById('docks');
      if(r) r.style.display='';
      if(a) a.classList.remove('collapsed');
      var sc=document.getElementById('keter-scrim');
      if(sc) sc.classList.remove('on');
      if(d && d.parentNode===document.body && document.querySelector('main'))
        document.querySelector('main').appendChild(d);
    }
  }

  /* ---------- long-press help ---------- */
  var lpTimer=null, lpFired=false;
  function tipEl(){
    var t=document.getElementById('keter-tip');
    if(!t){
      t=document.createElement('div');
      t.id='keter-tip';
      t.addEventListener('click',function(){ t.classList.remove('on'); });
      document.body.appendChild(t);
    }
    return t;
  }
  function showTip(raw){
    var bits=String(raw).split('|');
    var t=tipEl();
    t.innerHTML='<b></b><span></span>';
    t.querySelector('b').textContent=bits[0]||'Help';
    t.querySelector('span').textContent=(bits[1]||'').trim()||'No description available.';
    t.classList.add('on');
    clearTimeout(t._h);
    t._h=setTimeout(function(){ t.classList.remove('on'); },7000);
  }
  function lpStart(e){
    if(!PHONE) return;
    var tg=e.target;
    if(!tg||tg.tagName==='CANVAS') return;
    if(tg.closest('input,textarea,select')) return;   /* leave text selection alone */
    var host=tg.closest('[data-help]');
    if(!host) return;
    lpFired=false;
    clearTimeout(lpTimer);
    lpTimer=setTimeout(function(){
      lpFired=true;
      showTip(host.getAttribute('data-help'));
    },520);
  }
  function lpCancel(){ clearTimeout(lpTimer); }
  function bindLongPress(){
    document.addEventListener('touchstart',lpStart,{passive:true});
    document.addEventListener('touchmove',lpCancel,{passive:true});
    document.addEventListener('touchend',function(e){
      lpCancel();
      if(lpFired){ e.preventDefault(); lpFired=false; }
    },{passive:false});
    document.addEventListener('contextmenu',function(e){
      var tg=e.target;
      if(tg && tg.closest && tg.closest('[data-help]') &&
         !tg.closest('input,textarea,select') && tg.tagName!=='CANVAS'){
        e.preventDefault();
      }
    });
  }

  function boot(){
    if(!PHONE) return;
    syncOverflow();
    bindLongPress();
    if(firstVisit()) openPanel(); else collapsePanel();
    watchPanel();
    pinDocks();
    setTimeout(fitToScreen,350);
    setTimeout(fitToScreen,1100);
  }

  /* The shell calls this when the tool becomes visible. An iframe mounted while
     hidden reports zero width, so the boot-time fit is measured against nothing;
     waiting for a resize event to fire on unhide is not reliable everywhere. */
  window.keterFit=function(){
    PHONE = window.innerWidth <= 900;
    if(!PHONE) return;
    collapsePanelIfUnseen();
    pinDocks();
    syncOverflow();
    fitToScreen();
    setTimeout(fitToScreen,260);
  };
  function collapsePanelIfUnseen(){
    var a=panelEl();
    if(a && a.classList.contains('collapsed')) return;
  }

  if(document.readyState==='loading')
    document.addEventListener('DOMContentLoaded',boot);
  else boot();

  var t=null;
  window.addEventListener('resize',function(){
    syncOverflow();
    if(window.innerWidth>900) return;
    clearTimeout(t); t=setTimeout(fitToScreen,300);
  });
  window.addEventListener('orientationchange',function(){
    setTimeout(fitToScreen,500);
  });
})();
</script>
"""



# Both tools wrap their whole script in an IIFE, so nothing is reachable from
# the shell. Export the few functions the Compendium needs by appending an
# assignment inside that scope, immediately after each definition.
FORGE_EXPORTS = ["renderToOffscreen", "fromSchema", "migrate", "blankCard", "typeOf",
                 "chipAether", "statsOf", "computePings", "isMechanical",
                 "textRuns", "plainText", "wrapRuns", "keywordDef", "allKeywords",
                 "customKeywords", "saveCustomKeywords",
                 "hitAt", "openField", "cardScale", "hitList", "flashZones",
                 "currentCard", "toSchema", "tileGlyph", "renderTileFace"]


def add_bridge(src_html: str) -> str:
    added = []
    for fn in FORGE_EXPORTS:
        m = re.search(r"function\s+" + fn + r"\s*\([^)]*\)\s*\{", src_html)
        if not m:
            # arrow consts are declarations too, and several of the useful ones
            # are written that way
            a = re.search(r"const\s+" + fn + r"\s*=", src_html)
            if a:
                # walk to the terminating semicolon at depth zero, so a
                # multi-line arrow body is captured whole
                depth, k = 0, a.end()
                while k < len(src_html):
                    ch = src_html[k]
                    if ch in "([{":
                        depth += 1
                    elif ch in ")]}":
                        depth -= 1
                    elif ch == ";" and depth == 0:
                        break
                    k += 1
                a = type("M", (), {"end": lambda self, k=k: k + 1})()
                shim = ("\ntry{window.KETER_BRIDGE=window.KETER_BRIDGE||{};"
                        "window.KETER_BRIDGE." + fn + "=" + fn + ";}catch(e){}\n")
                pos = a.end() if callable(a.end) else a.end
                src_html = src_html[:pos] + shim + src_html[pos:]
                added.append(fn + " (arrow)")
            continue
        depth, start = 0, src_html.index("{", m.start())
        end = None
        for k in range(start, len(src_html)):
            ch = src_html[k]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = k + 1
                    break
        if end is None:
            continue
        shim = ("\ntry{window.KETER_BRIDGE=window.KETER_BRIDGE||{};"
                "window.KETER_BRIDGE." + fn + "=" + fn + ";}catch(e){}\n")
        src_html = src_html[:end] + shim + src_html[end:]
        added.append(fn)
    print(f"  bridge exports: {', '.join(added) if added else 'none'}")
    return src_html


def patch_tool(src_html: str) -> str:
    """Inject the shared symbol table and the mobile patch.

    The symbols go in the <head> because both tools read them at define time;
    the mobile patch goes at the end because it needs the DOM.
    """
    head = src_html.find("</head>")
    if head != -1:
        src_html = src_html[:head] + SHARED_GLYPHS + SHARED_BEHAVIORS + SHARED_TOOLKIT + SHARED_KEYWORDS + _read_keywords() + _read_pixelart() + _read_scoring() + _read_js('builder.js','loot.js','workshop.js','progress.js','chunkgen.js') + src_html[head:]
    idx = src_html.rfind("</body>")
    if idx == -1:
        return src_html + MOBILE_PATCH
    return src_html[:idx] + MOBILE_PATCH + src_html[idx:]


def b64(text: str) -> str:
    return base64.b64encode(text.encode("utf-8")).decode("ascii")


def as_text_payload(text: str) -> str:
    """The tools were the only thing still paying base64's flat 33%, which cost
    about 145 KB across the two of them. A JSON string needs no such
    protection: escaping `<` makes `</script>` impossible, and JSON.parse
    reads \\u003c natively and faster than atob plus a UTF-8 decode."""
    return json.dumps(text, separators=(",", ":")).replace("<", "\\u003c")


def as_json_payload(obj) -> str:
    """Base64 costs a flat 33% and exists only so arbitrary HTML can sit inside
    a <script> tag. JSON needs no such protection: escaping `<` is enough to
    make `</script>` impossible, and JSON.parse reads \u003c natively."""
    return json.dumps(obj, separators=(",", ":")).replace("<", "\\u003c")


# ---------------------------------------------------------------- manual prep
SLUG_RE = re.compile(r"[^a-z0-9]+")


def slugify(s, seen):
    s = SLUG_RE.sub("-", s.lower()).strip("-")[:60] or "sec"
    n, out = 1, s
    while out in seen:
        n += 1
        out = f"{s}-{n}"
    seen.add(out)
    return out


TAG_RE = re.compile(r"<[^>]+>")


def plain(html_fragment):
    txt = TAG_RE.sub(" ", html_fragment)
    txt = html.unescape(txt)
    return re.sub(r"\s+", " ", txt).strip()


def md_sections(md_path):
    """Slice the Markdown source by heading so the editor can show real source."""
    if not md_path or not os.path.exists(md_path):
        return {}
    md = open(md_path, encoding="utf-8").read()
    marks = list(re.finditer(r"^(#{1,3})\s+(.+?)\s*$", md, re.M))
    out = {}
    for n, m in enumerate(marks):
        end = marks[n + 1].start() if n + 1 < len(marks) else len(md)
        out[m.group(2).strip()] = md[m.start():end].rstrip()
    return out


def prep_doc(path, doc_id, md_path=None):
    """Add stable ids to h1/h2/h3 and return (html, toc, sections)."""
    raw = open(path, encoding="utf-8").read()
    seen, toc, parts, pos = set(), [], [], 0
    for m in re.finditer(r"<h([1-3])([^>]*)>(.*?)</h\1>", raw, re.S):
        lvl = int(m.group(1))
        text = re.sub(r"<[^>]+>", "", m.group(3))
        text = html.unescape(text).strip()
        if not text:
            continue
        sid = f"{doc_id}-{slugify(text, seen)}"
        parts.append(raw[pos:m.start()])
        parts.append(f'<h{lvl} id="{sid}">{m.group(3)}</h{lvl}>')
        pos = m.end()
        toc.append({"id": sid, "lvl": lvl, "text": text})
    parts.append(raw[pos:])
    out = "".join(parts)
    src = md_sections(md_path)

    # sections: heading plus the body text up to the next heading, so search can
    # scan every document without having to render it first
    sections, marks = [], list(re.finditer(r'<h([1-3]) id="([^"]+)">(.*?)</h\1>', out, re.S))
    for n, m in enumerate(marks):
        end = marks[n + 1].start() if n + 1 < len(marks) else len(out)
        body = plain(out[m.end():end])
        head = plain(m.group(3))
        sections.append({
            "id": m.group(2),
            "lvl": int(m.group(1)),
            "head": head,
            # `text` used to be stored here as well. It is the same prose as
            # `html` with the tags taken out, so it is derived once at runtime
            # and memoised instead of shipped a second time.
            "md": src.get(head, ""),
        })
    return out, toc, sections


# ---------------------------------------------------------------- gather
# v3.0 fork: the Card Forge now lives here, not in the project folder. See
# fork_forge.py for exactly what was changed and why.

# ---------------------------------------------------------------- freshness
def check_fresh():
    """Every guide is authored in Markdown and converted by pandoc. If a .md is
    newer than its .html, the build would quietly ship the old text — which has
    happened once. Fail loudly instead."""
    pairs = [("handbook_v14-0.md", "handbook.html"), ("forge_guide.md", "forge_guide.html"),
             ("poi_guide.md", "poi_guide.html"),
             ("datapad_guide.md", "datapad_guide.html"),
             ("simulator_guide.md", "simulator_guide.html"),
             ("deck_guide.md", "deck_guide.html"),
             ("studio_guide.md", "studio_guide.html"),
             ("loot_guide.md", "loot_guide.html"),
             ("workshop_guide.md", "workshop_guide.html"),
             ("world_guide.md", "world_guide.html"),
             ("dock_guide.md", "dock_guide.html"),
             ("changelog.md", "changelog.html"), ("whatsnew.md", "whatsnew.html")]
    stale = [h for m, h in pairs
             if os.path.exists(m) and os.path.exists(h)
             and os.path.getmtime(m) > os.path.getmtime(h)]
    if stale:
        raise SystemExit("STALE: re-run pandoc for " + ", ".join(stale))


check_fresh()

forge_src = open("forge_v3.html", encoding="utf-8").read()
# v19 fork: the Sandbox now lives here too, for Phase 2's naming and author
# changes. See fork_phase2.py.
POI_EXPORTS = ["shapeCells", "commitShape", "applyCell", "pushUndo", "hexDist",
               "glyphOf", "glyphName", "openSymPicker", "renderSyms",
               "mirrorCell", "mirrorActive", "mirrorIsSame", "applyAt", "syncMirrorBtn",
               "setZoom", "center", "cubeRound", "mirrorAngle",
               "mirrorImages", "mirrorPlanes", "imageToStencil", "autoThreshold",
               "stencilSVG", "stencils", "saveStencils", "glyphOf", "drawSymGlyph",
               "pdfSymGlyph", "openStencilDialog", "openSymPicker", "loadLevel", "renderSlots"]



# ---------------------------------------------------------------- symbols
# One symbol table for both tools. It used to live only in the Sandbox, which
# meant the Forge could not draw the same pictograms; that is the sort of
APP_VERSION = "14.18"

# ---------------------------------------------------------------- behaviour
# The enemy AI vocabulary, shared by the Card Forge (which edits it) and the
SHARED_KEYWORDS = """<script>window.KETER_KEYWORDS=""" + r'''[
  {name:'Overwhelmed', desc:'Applied once a Troop or Enemy takes more instances of damage in a turn than its Will allows. Deals half Damage, half Movement Speed, and Ranged Attacks against it always hit.'},
  {name:'Compromised', desc:'Mechanical Units only. Security drops to 0, Passives and Auras stop functioning, and Repair Kits cannot be used while it lasts.'},
  {name:'Evasive', desc:'Adds its value to the To-Hit threshold of Ranged Attacks against this Unit.'},
  {name:'Overclock', desc:'A Vantage Robotics mechanic: spend now for a stronger effect, at a cost paid afterwards.'},
  {name:'Aura', desc:'A Passive that affects only Units within its printed Radius.'},
  {name:'Half Cover', desc:'A Unit adjacent to a Half Cover Barricade gains +2 To-Hit against Ranged Attacks from the opposite side.'},
  {name:'Full Cover', desc:'A Unit adjacent to a Full Cover Barricade gains +4 To-Hit against Ranged Attacks from the opposite side.'}
]''' + """;</script>"""

# rules resolver (which executes it). One table, so the two cannot disagree
SHARED_TOOLKIT = """<script>
/* ---------------------------------------------------------------------------
   Shared tool code.

   The Card Forge and the POI Sandbox had their own copy of each of these, and
   the copies had drifted \u2014 which is why a fix to the help overlay had to be
   made twice, and why one tool's hit-test bug outlived the other's. One copy
   now, injected into both by build.py.

   Only functions that do the same job are here. computePings, computeChecklist,
   renderSlots, renderDocks and snapshot share a name between the tools but are
   2% to 41% alike: they are different functions, not drifted ones, and merging
   them would be wrong.

   Where the tools genuinely differ, they say so through KETER_TOOL rather than
   by keeping a second copy. It is read at call time because each tool sets it
   after this script has run.
   --------------------------------------------------------------------------- */
window.KETER_TOOL = window.KETER_TOOL || {};
function toolCfg(k, fallback){
  var v = window.KETER_TOOL && window.KETER_TOOL[k];
  return (v===undefined || v===null) ? fallback : v;
}

function download(blob,name){
  const url=URL.createObjectURL(blob), a=document.createElement('a');
  a.href=url; a.download=name; document.body.appendChild(a); a.click();
  setTimeout(()=>{a.remove();URL.revokeObjectURL(url);},400);
}

function keterUser(){
  try{ return (localStorage.getItem('keter-app-user')||'').trim(); }catch(e){ return ''; }
}

function stampAuthor(obj){
  const who=keterUser();
  if(!who) return obj;
  if(!obj.createdBy) obj.createdBy=who;
  obj.lastEditedBy=who;
  return obj;
}

function confirmBox(msg,yes,no){
  const ov=document.createElement('div'); ov.className='overlay';
  ov.innerHTML='<div class="modal"><p>'+msg+'</p><div class="acts">'+
    '<button class="btn primary" data-a="yes">Confirm</button>'+
      '<button class="btn" data-a="no">Cancel</button></div></div>';
  document.body.appendChild(ov);
  ov.addEventListener('click',e=>{
    const a=e.target.dataset?e.target.dataset.a:null;
    if(a==='yes'){ov.remove();yes&&yes();} else if(a==='no'||e.target===ov){ov.remove();no&&no();}
  });
}

function promptBox(msg,def,cb){
  const ov=document.createElement('div'); ov.className='overlay';
  ov.innerHTML='<div class="modal"><p>'+msg+'</p><input type="text" id="pIn" maxlength="60">'+
    '<div class="acts"><button class="btn" data-a="no">Cancel</button>'+
    '<button class="btn primary" data-a="yes">OK</button></div></div>';
  document.body.appendChild(ov);
  const inp=ov.querySelector('#pIn'); inp.value=def||'';
  setTimeout(()=>{inp.focus();inp.select();},30);
  const done=ok=>{const v=inp.value.trim();ov.remove();if(ok&&v)cb(v);};
  inp.addEventListener('keydown',e=>{if(e.key==='Enter')done(true);if(e.key==='Escape')done(false);});
  ov.addEventListener('click',e=>{
    const a=e.target.dataset?e.target.dataset.a:null;
    if(a==='yes')done(true); else if(a==='no'||e.target===ov)done(false);
  });
}

function safeFile(n){
  return (n || toolCfg("defaultFile","KETER_file"))
    .replace(/[^\w\-. ]+/g,"_").replace(/\s+/g,"_");
}
function setStatus(m){
  var el=document.getElementById("status");
  if(!el) return;
  el.textContent=m; el.classList.add("show");
  clearTimeout(window._statusT);
  window._statusT=setTimeout(function(){ el.classList.remove("show"); },2600);
}
function flash(sev,msg){
  flashPing=[sev,msg];
  var redraw=toolCfg("onFlash",function(){});
  redraw();
  clearTimeout(flashT);
  flashT=setTimeout(function(){ flashPing=null; redraw(); },7000);
}

function buildHelpBoxes(){
  [...helpLayer.querySelectorAll('.help-box')].forEach(n=>n.remove());
  /* #20: a group and its own controls were both boxed, which produced a
     lattice of overlapping rectangles. Box the innermost only, inset rather
     than inflated, with duplicates dropped. */
  const annotated=[...document.querySelectorAll('[data-help]')];
  const innermost=annotated.filter(el=>!el.querySelector('[data-help]'));
  const seen=[];
  /* The overlay sits above everything, so hit-testing has to ignore it or it
     answers "the overlay" for every single control. */
  const layerPE=helpLayer.style.pointerEvents;
  helpLayer.style.pointerEvents='none';
  innermost.forEach(el=>{
    const r=el.getBoundingClientRect();
    if(r.width<6||r.height<6||r.bottom<0||r.top>window.innerHeight) return;
    const sig=Math.round(r.left)+':'+Math.round(r.top)+':'+
              Math.round(r.width)+':'+Math.round(r.height);
    if(seen.indexOf(sig)>=0) return;
    /* A control sitting under a dock or an open panel cannot be tapped, so
       boxing it only draws a rectangle across whatever is covering it. */
    const cx=Math.min(window.innerWidth-2,Math.max(2,r.left+r.width/2));
    const cy=Math.min(window.innerHeight-2,Math.max(2,r.top+r.height/2));
    const hit=document.elementFromPoint(cx,cy);
    /* Boxes already drawn in this same pass sit on top of later controls and
       answered the hit test, so each box silently suppressed the next one
       behind it. Setting pointer-events on the layer is not enough because the
       boxes set their own back on to be clickable. */
    /* Ignore the overlay's own boxes and the scrim. Boxes drawn earlier in
       this pass sat on top of later controls, and the scrim \u2014 which dims the
       map behind the open panel \u2014 answered for 23 of the panel's own
       controls, so Help could not see what opening the panel had revealed. */
    const ignorable = hit && (helpLayer.contains(hit) || hit.id==='keter-scrim');
    if(hit && hit!==el && !el.contains(hit) && !hit.contains(el) && !ignorable) return;
    seen.push(sig);
    const box=document.createElement('div');
    box.className='help-box';
    box.style.left=(r.left+1)+'px'; box.style.top=(r.top+1)+'px';
    box.style.width=Math.max(4,r.width-2)+'px';
    box.style.height=Math.max(4,r.height-2)+'px';
    box.addEventListener('click',ev=>{
      ev.stopPropagation();
      const [t,d]=el.dataset.help.split('|');
      helpPop.querySelector('h4').textContent=t;
      helpPop.querySelector('p').textContent=d;
      /* clicking the open control closes it; any other control replaces it */
      if(helpOpenEl===el){ helpPop.style.display='none'; helpOpenEl=null; return; }
      helpOpenEl=el;
      helpPop.style.display='block';
      const pw=helpPop.offsetWidth, phh=helpPop.offsetHeight;
      let x=r.left+r.width/2-pw/2, y=r.bottom+14;
      if(y+phh>window.innerHeight-10){
        const above=r.top-phh-14;
        // prefer above; if that also overflows, sit beside the control instead
        if(above>=10) y=above;
        else { y=Math.max(10,Math.min(window.innerHeight-phh-10,r.top));
               x=(r.left>window.innerWidth/2)? r.left-pw-14 : r.right+14; }
      }
      helpPop.style.left=Math.max(10,Math.min(window.innerWidth-pw-10,x))+'px';
      helpPop.style.top=y+'px';
    });
    helpLayer.appendChild(box);
  });
  helpLayer.style.pointerEvents=layerPE;
}

</script>"""

# about what a keyword means.
SHARED_BEHAVIORS = """<script>window.KETER_BEHAVIORS=""" + r'''[
  {k:'cunning', name:'Cunning', side:'enemy', cat:'target', cond:false,
   text:'Attacks the nearest Hero.'},
  {k:'sadistic', name:'Sadistic', side:'enemy', cat:'target', cond:false,
   text:'Attacks the Unit with the lowest current Health.'},
  {k:'opportunistic', name:'Opportunistic', side:'enemy', cat:'target', cond:false,
   text:'Attacks the Unit with the lowest Armor Class.'},
  {k:'brutish', name:'Brutish', side:'enemy', cat:'target', cond:false,
   text:'Attacks the Unit with the highest Armor Class.'},
  {k:'vindictive', name:'Vindictive', side:'enemy', cat:'target', cond:true,
   text:'Attacks the last Unit that attacked it.'},
  {k:'ravenous', name:'Ravenous', side:'enemy', cat:'target', cond:true,
   text:'Attacks a Unit another Enemy has already attacked this round.'},
  {k:'methodical', name:'Methodical', side:'enemy', cat:'target', cond:true,
   text:'Attacks a Unit with no Enemy-applied status on it.'},
  {k:'cautious', name:'Cautious', side:'enemy', cat:'move', cond:true,
   param:'tiles', pdef:2,
   text:'Moves away from any Player Unit within X tiles, then acts normally.'},
  {k:'cowardly', name:'Cowardly', side:'enemy', cat:'move', cond:true,
   param:'Health', pdef:5,
   text:'At X Health or below, moves away from the closest Player Unit and takes no Action.'},

  {k:'valiant', name:'Valiant', side:'ally', cat:'target', cond:false,
   text:'Attacks the nearest Boss or Mini-Boss, ignoring lesser Enemies.'},
  {k:'decisive', name:'Decisive', side:'ally', cat:'target', cond:false,
   text:'Attacks the Enemy with the lowest current Health.'},
  {k:'precise', name:'Precise', side:'ally', cat:'target', cond:false,
   text:'Attacks the Enemy with the lowest Armor Class.'},
  {k:'dauntless', name:'Dauntless', side:'ally', cat:'target', cond:false,
   text:'Attacks the Enemy with the highest Armor Class.'},
  {k:'defiant', name:'Defiant', side:'ally', cat:'target', cond:true,
   text:'Attacks the last Enemy that attacked it.'},
  {k:'coordinated', name:'Coordinated', side:'ally', cat:'target', cond:true,
   text:'Attacks an Enemy an ally has already attacked this round.'},
  {k:'thorough', name:'Thorough', side:'ally', cat:'target', cond:true,
   text:'Attacks an Enemy carrying no status yet.'},
  {k:'wary', name:'Wary', side:'ally', cat:'move', cond:true,
   param:'tiles', pdef:2,
   text:'Moves away from any Enemy within X tiles, then acts normally.'},
  {k:'prudent', name:'Prudent', side:'ally', cat:'move', cond:true,
   param:'Health', pdef:5,
   text:'At X Health or below, withdraws and takes no Action.'},
  {k:'steadfast', name:'Steadfast', side:'ally', cat:'move', cond:false,
   text:'Holds its tile and does not move.'},
  {k:'medic', name:'Medic', side:'ally', cat:'support', cond:true,
   text:'Uses a Support Action on the most wounded ally before attacking.'},
  {k:'guardian', name:'Guardian', side:'ally', cat:'support', cond:false,
   text:'Stays within 1 tile of your Hero rather than chasing targets.'}
]''' + """;</script>"""

# ---------------------------------------------------------------- resolver
# The rules of combat with nothing else attached. Injected into the shell so
# the Combat Datapad uses it rather than owning its own copy, and available to
# anything else that needs to resolve a fight.
def _read_keywords():
    with open("keywords.js", encoding="utf-8") as f:
        return "<script>\n" + f.read() + "\n</script>"


def _read_pixelart():
    with open("pixelart.js", encoding="utf-8") as f:
        return "<script>\n" + f.read() + "\n</script>"


def _read_js(*names):
    out=""
    for nm in names:
        if os.path.exists(nm):
            with open(nm, encoding="utf-8") as f: out += "<script>\n" + f.read() + "\n</script>"
    return out


def _read_studio():
    with open("studio.js", encoding="utf-8") as f:
        return "<script>\n" + f.read() + "\n</script>"


def _read_test_pictures():
    if not os.path.exists("test_pictures.js"): return ""
    with open("test_pictures.js", encoding="utf-8") as f:
        return "<script>\n" + f.read() + "\n</script>"


def _read_game_art():
    """v14.1: the game's own drawn art, as Pixel Studio pictures (keter_art.js).
    Made from game/art by make_art_pack.py whenever the game's art is here: the
    sources don't carry it, being the game's own pictures (from the game zip)."""
    if os.path.exists(os.path.join("game", "art", "art.json")):
        try:
            import make_art_pack
            make_art_pack.main()
        except ImportError as e:
            print("  (couldn't remake keter_art.js: %s)" % e)
    if not os.path.exists("keter_art.js"):
        print("  (no game/art here: the app is built without the game's own art)")
        return ""
    with open("keter_art.js", encoding="utf-8") as f:
        return "<script>\n" + f.read() + "\n</script>"


def _read_test_maps():
    # (v14.7) and the built-in battlefield chunks, with the generator that grows them
    out = ""
    for fn in ("test_maps.js", "keter_chunks.js", "chunkgen.js"):
        with open(fn, encoding="utf-8") as f:
            out += "<script>\n" + f.read() + "\n</script>"
    return out


def _read_scoring():
    with open("scoring.js", encoding="utf-8") as f:
        return "<script>\n" + f.read() + "\n</script>"


def _read_rules():
    with open("rules.js", encoding="utf-8") as f:
        return "<script>\n" + f.read() + "\n</script>"

# duplication that let the rules drift apart elsewhere.
SHARED_GLYPHS = """<script>window.KETER_GLYPHS=""" + r'''{
  spawn:   {name:'Player spawn', strokes:[[[0,-.75],[0,.75]],[[-.6,-.15],[0,-.75],[.6,-.15]]]},
  enemy:   {name:'Enemy spawn',  strokes:[[[0,.75],[0,-.75]],[[-.6,.15],[0,.75],[.6,.15]]]},
  boss:    {name:'Boss',         strokes:[[[-.7,.4],[0,-.75],[.7,.4],[-.7,.4]],[[-.35,.4],[-.35,.75]],[[.35,.4],[.35,.75]]]},
  loot:    {name:'Loot',         strokes:[[[-.7,-.25],[.7,-.25],[.7,.6],[-.7,.6],[-.7,-.25]],[[-.7,-.25],[0,-.7],[.7,-.25]],[[0,-.7],[0,.6]]]},
  chest:   {name:'Locked chest', strokes:[[[-.7,-.2],[.7,-.2],[.7,.65],[-.7,.65],[-.7,-.2]],[[-.25,.05],[.25,.05],[.25,.4],[-.25,.4],[-.25,.05]],[[-.15,.05],[-.15,-.1],[.15,-.1],[.15,.05]]]},
  key:     {name:'Keycard',      strokes:[[[-.75,-.4],[.4,-.4],[.4,.4],[-.75,.4],[-.75,-.4]],[[-.45,-.15],[-.15,-.15]],[[-.45,.1],[-.15,.1]],[[.4,0],[.8,0]]]},
  cover:   {name:'Cover',        strokes:[[[-.7,.55],[-.7,-.35],[0,-.7],[.7,-.35],[.7,.55]],[[-.7,.1],[.7,.1]]]},
  heal:    {name:'Healing',      strokes:[[[0,-.7],[0,.7]],[[-.7,0],[.7,0]]]},
  hive:    {name:'Hive',         strokes:[[[-.5,-.6],[.5,-.6],[.8,0],[.5,.6],[-.5,.6],[-.8,0],[-.5,-.6]],[[-.25,-.2],[.25,-.2],[.4,.1],[.15,.45],[-.15,.45],[-.4,.1],[-.25,-.2]]]},
  captive: {name:'Captive',      strokes:[[[0,-.75],[0,-.45]],[[-.4,-.15],[.4,-.15]],[[0,-.45],[0,.25]],[[0,.25],[-.35,.75]],[[0,.25],[.35,.75]]]},
  exit:    {name:'Exit',         strokes:[[[-.75,-.6],[.1,-.6],[.1,.6],[-.75,.6],[-.75,-.6]],[[.35,0],[.85,0]],[[.6,-.25],[.85,0],[.6,.25]]]},
  terminal:{name:'Terminal',     strokes:[[[-.75,-.55],[.75,-.55],[.75,.35],[-.75,.35],[-.75,-.55]],[[-.3,.35],[-.3,.65]],[[.3,.35],[.3,.65]],[[-.55,.65],[.55,.65]],[[-.45,-.3],[-.05,-.3]],[[-.45,-.05],[.2,-.05]]]},
  radiation: {name:"Radiation", strokes:[[[0, 0], [-0.28, -0.55]], [[0, 0], [0.28, -0.55]], [[0, 0], [0, 0.6]], [[-0.62, -0.28], [-0.28, -0.55], [0.28, -0.55], [0.62, -0.28]], [[-0.55, 0.42], [-0.3, 0.05], [0.3, 0.05], [0.55, 0.42]]]},
  biohazard: {name:"Biohazard", strokes:[[[0, -0.15], [-0.5, 0.5]], [[0, -0.15], [0.5, 0.5]], [[0, -0.15], [0, -0.7]], [[-0.5, 0.5], [0.5, 0.5]], [[-0.35, -0.35], [0.35, -0.35]]]},
  fire: {name:"Fire", strokes:[[[0, 0.65], [-0.4, 0.15], [-0.15, -0.1], [-0.25, -0.65], [0.2, -0.25], [0.4, 0.15], [0, 0.65]]]},
  electric: {name:"Electrical", strokes:[[[0.2, -0.7], [-0.3, 0.05], [0.05, 0.05], [-0.2, 0.7]]]},
  toxic: {name:"Toxic", strokes:[[[-0.5, -0.5], [0.5, 0.5]], [[0.5, -0.5], [-0.5, 0.5]], [[-0.6, 0], [0.6, 0]], [[0, -0.6], [0, 0.6]]]},
  explosive: {name: "Explosive", strokes: [[[-0.45, 0.15], [-0.32, -0.2], [0, -0.33], [0.32, -0.2], [0.45, 0.15], [0.32, 0.5], [0, 0.63], [-0.32, 0.5], [-0.45, 0.15]], [[0.12, -0.3], [0.3, -0.55], [0.55, -0.6]], [[0.42, -0.72], [0.55, -0.6], [0.68, -0.7]]]},
  freeze: {name:"Cryogenic", strokes:[[[0, -0.7], [0, 0.7]], [[-0.6, -0.35], [0.6, 0.35]], [[0.6, -0.35], [-0.6, 0.35]], [[-0.2, -0.5], [0, -0.7], [0.2, -0.5]]]},
  acid: {name:"Corrosive", strokes:[[[0, -0.65], [-0.35, 0.1], [0, 0.6], [0.35, 0.1], [0, -0.65]], [[-0.5, 0.5], [-0.35, 0.65]], [[0.5, 0.5], [0.35, 0.65]]]},
  warning: {name:"Hazard", strokes:[[[0, -0.65], [0.7, 0.55], [-0.7, 0.55], [0, -0.65]], [[0, -0.25], [0, 0.2]], [[0, 0.35], [0, 0.42]]]},
  voidrift: {name:"Void rift", strokes:[[[0, -0.7], [-0.25, 0], [0, 0.7], [0.25, 0], [0, -0.7]], [[-0.5, -0.35], [0.5, 0.35]], [[0.5, -0.35], [-0.5, 0.35]]]},
  gear: {name:"Machinery", strokes:[[[-0.25, -0.25], [0.25, -0.25], [0.25, 0.25], [-0.25, 0.25], [-0.25, -0.25]], [[0, -0.25], [0, -0.6]], [[0, 0.25], [0, 0.6]], [[-0.25, 0], [-0.6, 0]], [[0.25, 0], [0.6, 0]]]},
  hammer: {name:"Tools", strokes:[[[-0.55, -0.4], [0.1, -0.4]], [[-0.55, -0.55], [-0.55, -0.25]], [[0.1, -0.55], [0.1, -0.25]], [[-0.2, -0.4], [0.35, 0.6]]]},
  swords: {name:"Combat", strokes:[[[-0.55, -0.55], [0.45, 0.5]], [[0.55, -0.55], [-0.45, 0.5]], [[-0.6, 0.35], [-0.35, 0.6]], [[0.6, 0.35], [0.35, 0.6]]]},
  pick: {name:"Mining", strokes:[[[-0.6, -0.35], [0.6, -0.35]], [[-0.6, -0.35], [-0.35, -0.15]], [[0.6, -0.35], [0.35, -0.15]], [[0, -0.3], [0, 0.65]]]},
  wrench: {name:"Repair", strokes:[[[-0.5, -0.5], [-0.2, -0.2]], [[-0.6, -0.35], [-0.35, -0.6]], [[-0.2, -0.2], [0.55, 0.6]]]},
  door: {name:"Door", strokes:[[[-0.4, -0.65], [0.4, -0.65], [0.4, 0.65], [-0.4, 0.65], [-0.4, -0.65]], [[0.18, 0.05], [0.28, 0.05]]]},
  ladder: {name:"Ladder", strokes:[[[-0.35, -0.7], [-0.35, 0.7]], [[0.35, -0.7], [0.35, 0.7]], [[-0.35, -0.35], [0.35, -0.35]], [[-0.35, 0], [0.35, 0]], [[-0.35, 0.35], [0.35, 0.35]]]},
  crate: {name:"Crate", strokes:[[[-0.55, -0.45], [0.55, -0.45], [0.55, 0.5], [-0.55, 0.5], [-0.55, -0.45]], [[-0.55, -0.45], [0.55, 0.5]], [[0.55, -0.45], [-0.55, 0.5]]]},
  barrel: {name:"Barrel", strokes:[[[-0.4, -0.55], [0.4, -0.55], [0.4, 0.55], [-0.4, 0.55], [-0.4, -0.55]], [[-0.4, -0.2], [0.4, -0.2]], [[-0.4, 0.2], [0.4, 0.2]]]},
  generator: {name:"Generator", strokes:[[[-0.55, -0.35], [0.55, -0.35], [0.55, 0.45], [-0.55, 0.45], [-0.55, -0.35]], [[0.1, -0.2], [-0.15, 0.1], [0.05, 0.1], [-0.1, 0.35]]]},
  pipe: {name:"Pipes", strokes:[[[-0.65, -0.3], [0.2, -0.3], [0.2, 0.6]], [[-0.65, -0.45], [-0.65, -0.15]], [[0.05, 0.6], [0.35, 0.6]]]},
  valve: {name:"Valve", strokes:[[[0, -0.5], [0, 0.5]], [[-0.45, -0.25], [0.45, 0.25]], [[0.45, -0.25], [-0.45, 0.25]], [[-0.15, 0], [0.15, 0]]]},
  turret: {name:"Turret", strokes:[[[-0.45, 0.5], [0.45, 0.5]], [[-0.3, 0.5], [-0.3, 0.05]], [[0.3, 0.5], [0.3, 0.05]], [[-0.3, 0.05], [0.3, 0.05]], [[0, 0.05], [0, -0.6]]]},
  ammo: {name:"Ammunition", strokes:[[[-0.2, 0.6], [-0.2, -0.2], [0, -0.6], [0.2, -0.2], [0.2, 0.6], [-0.2, 0.6]], [[-0.2, 0.25], [0.2, 0.25]]]},
  medkit: {name:"Medical", strokes:[[[-0.55, -0.35], [0.55, -0.35], [0.55, 0.45], [-0.55, 0.45], [-0.55, -0.35]], [[0, -0.15], [0, 0.25]], [[-0.2, 0.05], [0.2, 0.05]]]},
  antenna: {name:"Comms", strokes:[[[0, 0.65], [0, -0.35]], [[-0.35, -0.6], [0, -0.35], [0.35, -0.6]], [[-0.55, -0.75], [0, -0.35], [0.55, -0.75]]]},
  star: {name:"Star", strokes:[[[0, -0.7], [0.2, -0.18], [0.68, -0.18], [0.3, 0.13], [0.44, 0.62], [0, 0.32], [-0.44, 0.62], [-0.3, 0.13], [-0.68, -0.18], [-0.2, -0.18], [0, -0.7]]]},
  flag: {name:"Objective", strokes:[[[-0.35, 0.7], [-0.35, -0.65]], [[-0.35, -0.65], [0.5, -0.4], [-0.35, -0.15]]]},
  cross: {name:"Blocked", strokes:[[[-0.5, -0.5], [0.5, 0.5]], [[0.5, -0.5], [-0.5, 0.5]]]},
  check: {name:"Cleared", strokes:[[[-0.5, 0], [-0.15, 0.42], [0.55, -0.5]]]},
  query: {name:"Unknown", strokes:[[[-0.3, -0.4], [0, -0.65], [0.3, -0.4], [0.15, -0.05], [0, 0.1], [0, 0.3]], [[0, 0.55], [0, 0.62]]]},
  arrowN: {name:"North", strokes:[[[0, 0.6], [0, -0.6]], [[-0.35, -0.2], [0, -0.6], [0.35, -0.2]]]},
  arrowS: {name:"South", strokes:[[[0, -0.6], [0, 0.6]], [[-0.35, 0.2], [0, 0.6], [0.35, 0.2]]]},
  arrowE: {name:"East", strokes:[[[-0.6, 0], [0.6, 0]], [[0.2, -0.35], [0.6, 0], [0.2, 0.35]]]},
  arrowW: {name:"West", strokes:[[[0.6, 0], [-0.6, 0]], [[-0.2, -0.35], [-0.6, 0], [-0.2, 0.35]]]},
  circle: {name:"Marker A", strokes:[[[0.6, 0], [0.42, 0.42], [0, 0.6], [-0.42, 0.42], [-0.6, 0], [-0.42, -0.42], [0, -0.6], [0.42, -0.42], [0.6, 0]]]},
  square: {name:"Marker B", strokes:[[[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, 0.5], [-0.5, -0.5]]]},
  triangle: {name:"Marker C", strokes:[[[0, -0.6], [0.6, 0.5], [-0.6, 0.5], [0, -0.6]]]}
}''' + """;</script>"""

def add_poi_bridge(src_html):
    """The Sandbox wraps everything in an IIFE too, so nothing is reachable for
    testing or for the shell. Expose the few things worth reaching, plus the
    state object itself."""
    added = []
    for fn in POI_EXPORTS:
        m = re.search(r"function\s+" + fn + r"\s*\([^)]*\)\s*\{", src_html)
        if not m:
            continue
        depth, start = 0, src_html.index("{", m.start())
        end = None
        for k in range(start, len(src_html)):
            ch = src_html[k]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    end = k + 1
                    break
        if end is None:
            continue
        shim = ("\ntry{window.KETER_POI=window.KETER_POI||{};"
                "window.KETER_POI." + fn + "=" + fn + ";}catch(e){}\n")
        src_html = src_html[:end] + shim + src_html[end:]
        added.append(fn)
    # the state object, so a test can set the tool and read the result
    src_html = src_html.replace("S.shape='free'; S.shapeFill=true; S.shapeDrag=null;",
        "S.shape='free'; S.shapeFill=true; S.shapeDrag=null;\n"
        "try{window.KETER_POI=window.KETER_POI||{};window.KETER_POI.S=S;}catch(e){}", 1)
    print(f"  poi bridge: {', '.join(added) if added else 'none'}")
    return src_html


poi_src = open("poi_v19.html", encoding="utf-8").read()

hb_html, hb_toc, hb_secs = prep_doc("handbook.html", "hb", "handbook_v14-0.md")
fg_html, fg_toc, fg_secs = prep_doc("forge_guide.html", "fg", "forge_guide.md")
pg_html, pg_toc, pg_secs = prep_doc("poi_guide.html", "pg", "poi_guide.md")
dg_html, dg_toc, dg_secs = prep_doc("datapad_guide.html", "dg", "datapad_guide.md")
sg_html, sg_toc, sg_secs = prep_doc("simulator_guide.html", "sg", "simulator_guide.md")
kg_html, kg_toc, kg_secs = prep_doc("deck_guide.html", "kg", "deck_guide.md")
ps_html, ps_toc, ps_secs = prep_doc("studio_guide.html", "ps", "studio_guide.md")
lg_html, lg_toc, lg_secs = prep_doc("loot_guide.html", "lg", "loot_guide.md")
wg_html, wg_toc, wg_secs = prep_doc("workshop_guide.html", "wg", "workshop_guide.md")
wm_html, wm_toc, wm_secs = prep_doc("world_guide.html", "wm", "world_guide.md")
dk_html, dk_toc, dk_secs = prep_doc("dock_guide.html", "dk", "dock_guide.md")
cl_html, cl_toc, cl_secs = prep_doc("changelog.html", "cl", "changelog.md")
wn_html, wn_toc, wn_secs = prep_doc("whatsnew.html", "wn", "whatsnew.md")

# ---------------------------------------------------------------- glossary
# Handbook 13 is the authoritative term list; extract it so keyword definitions
# stay correct whenever the Handbook is updated.
GLOSS_ALIAS = re.compile(r"^(.*?)\s*\(([^)]+)\)\s*$")


def build_glossary(md_path):
    md = open(md_path, encoding="utf-8").read()
    start = md.find("# 13. Glossary")
    if start < 0:
        return []
    body = md[start:]
    terms = []
    for m in re.finditer(r"^\|\s*\*\*([^*|]+)\*\*\s*\|\s*(.+?)\s*\|\s*$", body, re.M):
        term = m.group(1).strip()
        definition = re.sub(r"\*\*|\*", "", m.group(2)).strip()
        if term.lower() == "term" or not definition:
            continue
        aliases = []
        am = GLOSS_ALIAS.match(term)
        label = term
        if am:
            label = am.group(1).strip()
            short = am.group(2).strip()
            aliases = [label, short]
        else:
            aliases = [term]
        aliases = [a for a in dict.fromkeys(aliases) if len(a) >= 2]
        terms.append({"term": term, "label": label, "def": definition, "alias": aliases})
    return terms


GLOSSARY = build_glossary("handbook_v14-0.md")
print(f"  glossary terms: {len(GLOSSARY)}")

DOCS = [
    {"id": "hb", "title": "Player Handbook", "ver": "v15.9", "html": hb_html,
     "toc": hb_toc, "secs": hb_secs},
    {"id": "fg", "title": "Card Forge Guide", "ver": "v3.6", "html": fg_html,
     "toc": fg_toc, "secs": fg_secs},
    {"id": "pg", "title": "POI Sandbox Guide", "ver": "v1.6", "html": pg_html,
     "toc": pg_toc, "secs": pg_secs},
    {"id": "dg", "title": "Combat Datapad Guide", "ver": "v1.0", "html": dg_html,
     "toc": dg_toc, "secs": dg_secs},
    {"id": "sg", "title": "Battle Simulator Guide", "ver": "v1.4", "html": sg_html,
     "toc": sg_toc, "secs": sg_secs},
    {"id": "kg", "title": "Deck Builder Guide", "ver": "v1.1", "html": kg_html,
     "toc": kg_toc, "secs": kg_secs},
    {"id": "ps", "title": "Pixel Studio Guide", "ver": "v1.2", "html": ps_html,
     "toc": ps_toc, "secs": ps_secs},
    {"id": "lg", "title": "Loot Guide", "ver": "v1.3", "html": lg_html,
     "toc": lg_toc, "secs": lg_secs},
    {"id": "wg", "title": "Workshop and Codex Guide", "ver": "v1.3", "html": wg_html,
     "toc": wg_toc, "secs": wg_secs},
    {"id": "wm", "title": "World Map Guide", "ver": "v1.2", "html": wm_html,
     "toc": wm_toc, "secs": wm_secs},
    {"id": "dk", "title": "Dock Guide", "ver": "v1.0", "html": dk_html,
     "toc": dk_toc, "secs": dk_secs},
    {"id": "wn", "title": "What's New", "ver": "v" + APP_VERSION, "html": wn_html,
     "toc": wn_toc, "secs": wn_secs},
    {"id": "cl", "title": "Change Log", "ver": "v" + APP_VERSION, "html": cl_html,
     "toc": cl_toc, "secs": cl_secs},
]

docs_payload = as_json_payload([
    {k: d[k] for k in ("id", "title", "ver", "html", "toc", "secs")} for d in DOCS
])

gloss_payload = as_json_payload(GLOSSARY)

# The card list's version rises whenever its cards change. A device only takes a
# new card list when its version is higher, and this number was never raised, so
# phones kept an old copy: the test cards and the 48 restored cards never arrived.
def _bump_card_version():
    import hashlib
    p = "compendium_full.json"
    if not os.path.exists(p): return None
    with open(p, encoding="utf-8") as f: comp = json.load(f)
    fp = hashlib.sha256(json.dumps(comp.get("cards", []), sort_keys=True).encode("utf-8")).hexdigest()
    rec = {}
    if os.path.exists("compendium_version.json"):
        with open("compendium_version.json", encoding="utf-8") as f: rec = json.load(f)
    if rec.get("fingerprint") != fp:
        try: v = int(float(comp.get("version") or 0))
        except ValueError: v = 0
        v = max(v, int(rec.get("version", 0))) + 1
        comp["version"] = str(v)
        with open(p, "w", encoding="utf-8") as f: json.dump(comp, f, indent=1)
        with open("compendium_version.json", "w", encoding="utf-8") as f:
            json.dump({"fingerprint": fp, "version": v}, f)
    return comp.get("version")
CARD_LIST_VERSION = _bump_card_version()

# Master compendium ships empty; Dev Mode fills it, and compendium.json overrides
# it at runtime so cards can be published without rebuilding the whole app.
MASTER_DEFAULT = {"schema": "keter.compendium/1", "version": "0", "cards": []}
master_payload = as_json_payload(MASTER_DEFAULT)

forge_payload = as_text_payload(patch_tool(add_bridge(forge_src)))
poi_payload = as_text_payload(patch_tool(add_poi_bridge(poi_src)))


# ---------------------------------------------------------------- assemble
shell = open("shell.html", encoding="utf-8").read()
# the resolver and the behaviour table go in the head, before anything reads them
_head = shell.find("</head>")
if _head != -1:
    _body_end = shell.rfind("</body>")
    shell = shell[:_body_end] + _read_studio() + _read_js('studio_tabs.js','chassis_ui.js','loot_ui.js','workshop_ui.js','codex_ui.js','world_ui.js','dock_ui.js') + shell[_body_end:]
    _head = shell.find("</head>") if shell.find("</head>")>=0 else _head
    shell = shell[:_head] + SHARED_BEHAVIORS + _read_keywords() + _read_pixelart() + _read_test_maps() + _read_test_pictures() + _read_game_art() + _read_scoring() + _read_js('builder.js','chassis.js','test_chassis.js','keter_frames.js','loot.js','workshop.js','progress.js','world.js','deploy.js','dock.js','skins.js','assets.js') + _read_rules() + shell[_head:]
out = (shell
       .replace("__GLOSS__", gloss_payload)
       .replace("__MASTER__", master_payload)
       .replace("__DOCS__", docs_payload)
       .replace("__FORGE__", forge_payload)
       .replace("__POI__", poi_payload)
       .replace("__VER__", "v" + APP_VERSION))

os.makedirs(os.path.dirname(OUT), exist_ok=True)
open(OUT, "w", encoding="utf-8").write(out)
print("wrote", OUT, len(out), "chars", round(len(out.encode())/1048576, 2), "MB")

# sidecar files: both are always fetched no-store so a publish is seen immediately
side = os.path.dirname(OUT)
with open(os.path.join(side, "version.json"), "w") as f:
    json.dump({"version": APP_VERSION, "built": __import__("datetime").datetime.utcnow()
               .strftime("%Y-%m-%dT%H:%M:%SZ")}, f, indent=2)
hp = os.path.join(side, "handbook.json")
if not os.path.exists(hp):
    with open(hp, "w") as f:
        json.dump({"schema": "keter.handbook/1", "version": "0", "edits": {}}, f, indent=2)

mp = os.path.join(side, "compendium.json")
if not os.path.exists(mp):
    with open(mp, "w") as f:
        json.dump(MASTER_DEFAULT, f, indent=2)
print("wrote version.json, compendium.json and handbook.json")
