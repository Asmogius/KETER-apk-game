"""Skins and assets (v13.0): the five body-plan stand-ins; designs choosing a
skin of their body plan (those suiting their roles first, a drawn one by
default); variants and the recolour tool; deleting and restoring; art drawn
for a design before v13.0 becoming a skin; Heroes' skins chosen once and worn
in fights and on the map; Enemies' random looks; the World Map's drawn ground,
icons and rubble; slots of your own; Export for Godot (a real zip of PNGs and
a manifest); the Pixel Studio's Skins and Assets tabs, read-only for players;
the Workshop's Look picker; a Hero's Look on its card; the picture library's
cache."""
import http.server, socketserver, threading, functools, pathlib, shutil, sys, json, io, zipfile, struct
from playwright.sync_api import sync_playwright
TMP=pathlib.Path("/tmp/serve_skins")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa",TMP); shutil.copy("compendium_full.json", TMP/"compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self,*a): pass
class Q(socketserver.TCPServer): allow_reuse_address=True
srv=Q(("127.0.0.1",9963),functools.partial(H,directory=str(TMP)))
threading.Thread(target=srv.serve_forever,daemon=True).start()
ok,bad=[],[]
def ck(n,c,d=""):
    (ok if c else bad).append(n+((" — "+str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ")+n+("" if c else "  — "+str(d)[:260]))

# a 20x20 PNG: left half red, right half blue
def png(w=20,h=20):
    import zlib
    raw=b"".join(b"\x00"+b"".join((b"\xff\x20\x20\xff" if x<w//2 else b"\x20\x40\xff\xff") for x in range(w)) for y in range(h))
    chunk=lambda t,d: struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
    return b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",w,h,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(raw))+chunk(b"IEND",b"")
IMG=pathlib.Path("/tmp/serve_skins_img.png"); IMG.write_bytes(png())

TEAM="""()=>{ var deck=['design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','design|Frame Trooper','test|Test Mortar Strike','test|Test Snare'];
  localStorage.setItem('keter-app-loadouts',JSON.stringify([{v:2,name:'Deploy Team',level:1,created:111,heroes:['test|Test Warden','test|Test Striker'],deck:deck,actions:{},pouch:{'basic|3':6}}])); return true; }"""
LIB=r"""()=>{
window.T={ S:KETER_SKINS, A:KETER_ASSETS, P:KETER_PX, WS:KETER_WORKSHOP, D:KETER_DEPLOY, W:KETER_WORLD,
  design:function(name, chassis, role){ var d=KETER_WORKSHOP.blank(chassis||'ch_test_general'); d.name=name; if(role){ d.abilities[0].role=role; } return KETER_WORKSHOP.put(d); },
  fill:function(id, colour){ var P=KETER_PX, p=P.get(id), n=p.w*p.h, a=new Uint8Array(n); var L=p.grid==='hex'?P.hexLayout(p):null; for(var i=0;i<n;i++) if(!L||L.valid[i]) a[i]=colour; p.frames[0].layers[0].px=P.encode(a); p.flat=''; P.put(p,id); return id; },
  close:function(){ document.getElementById('modal').classList.remove('on'); }
}; return true; }"""

with sync_playwright() as p:
    b=p.chromium.launch()
    ctx=b.new_context(viewport={"width":412,"height":915},device_scale_factor=2, accept_downloads=True)
    pg=ctx.new_page(); errs=[]
    pg.on("pageerror",lambda e:errs.append(str(e)[:200]))
    pg.on("dialog",lambda d:d.accept())
    pg.goto("http://127.0.0.1:9963/"); pg.wait_for_timeout(1500)
    pg.evaluate("()=>{ localStorage.setItem('keter-app-dice',JSON.stringify({dur:0})); localStorage.removeItem('keter-app-dev'); localStorage.removeItem('keter-app-sim'); }")
    pg.evaluate(TEAM)
    # a design drawn for before v13.0: art linked to it, no skin yet
    pg.evaluate("""()=>{ var P=KETER_PX, W=KETER_WORKSHOP, d=W.blank('ch_test_threshold'); d.name='Old Drone'; var id=W.put(d);
      var art=P.blank(64,40,'Old Drone art'); art.kind='art'; var aid=P.put(art); var tok=P.blank(32,32,'Old Drone token'); tok.kind='token'; var tid=P.put(tok);
      P.link({id:id, name:'Old Drone'},'art',aid); P.link({id:id, name:'Old Drone'},'token',tid); localStorage.setItem('keter-test-old',JSON.stringify({id:id, art:aid, tok:tid})); }""")
    pg.reload(); pg.wait_for_timeout(1900)
    E=pg.evaluate
    E(LIB)
    E("()=>{ KETER_WORLD.newMap(4242); KETER_LOOT.seed(5); }")

    # ================= the stand-ins =================
    r=E("""()=>{ var S=T.S; return {skins:S.all().map(function(k){ return k.id+'|'+k.owner.kind+'|'+k.owner.key; }),
      pics:S.BODY_PLANS.map(function(b){ var k=b.toLowerCase(); return T.P.has('px_skin_'+k+'_art') && T.P.has('px_skin_'+k+'_token'); }),
      art:T.P.get('px_skin_bipedal_art'), tok:T.P.get('px_skin_quadcopter_token')}; }""")
    stands=[x for x in r["skins"] if x.startswith("sk_std_")]
    ck("a stand-in skin for each of the five body plans", stands==["sk_std_bipedal|body|Bipedal","sk_std_quadcopter|body|Quadcopter","sk_std_quadruped|body|Quadruped","sk_std_hexapod|body|Hexapod","sk_std_octopod|body|Octopod"], r["skins"])
    ck("with their pictures installed", all(r["pics"]), r["pics"])
    # (v14.1: the token is the game's own drawing of the body plan, 48 by 48, from keter_art.js)
    ck("the art 128 across, sized as a Troop's; the token the game's drawing of the body plan, 48 square", r["art"]["w"]==128 and r["art"]["h"]==85 and r["tok"]["grid"]=="square" and r["tok"]["w"]==48 and r["tok"]["h"]==48 and bool(r["tok"].get("shipped")), [r["art"]["w"],r["art"]["h"],r["tok"].get("grid"),r["tok"].get("w")])

    # ================= the old drawing became a skin =================
    r=E("""()=>{ var o=JSON.parse(localStorage.getItem('keter-test-old')), d=T.WS.get(o.id), k=d.skin&&T.S.get(d.skin.skin), c=T.WS.toCard(d);
      var n=T.S.all().length; T.S.migrate(); return {o:o, skin:d.skin, owner:k&&k.owner, name:k&&k.name, v:k&&k.variants[0], card:[c.pixelArt,c.pixelToken], again:T.S.all().length===n}; }""")
    ck("art drawn for a design before skins becomes a skin of its body plan", r["owner"]=={"kind":"body","key":"Quadcopter"} and r["name"]=="Old Drone" and r["v"]["art"]==r["o"]["art"] and r["v"]["token"]==r["o"]["tok"], r)
    ck("and the design goes on wearing it", r["skin"]["variant"]=="v1" and r["card"]==[r["o"]["art"],r["o"]["tok"]], r)
    ck("only once", r["again"], r)

    # ================= designs: options, defaults, choosing =================
    r=E("""()=>{ var S=T.S, d=T.WS.get('ds_starter'), c=T.WS.toCard(d);
      var q=T.design('Hover', 'ch_test_threshold'), dq=T.WS.get(q);
      return {bp:S.bodyPlanOf(d), look:S.lookOf(d), art:c.pixelArt, tok:c.pixelToken, qbp:S.bodyPlanOf(dq), qopts:S.optionsFor(dq).map(function(o){ return o.skin.id; }), qlook:S.lookOf(dq)}; }""")
    ck("the starter wears the Bipedal stand-in", r["bp"]=="Bipedal" and r["look"]["skin"]=="sk_std_bipedal" and r["art"]=="px_skin_bipedal_art" and r["tok"]=="px_skin_bipedal_token", r)
    ck("a design on a Quadcopter chassis is offered Quadcopter skins", r["qbp"]=="Quadcopter" and "sk_std_quadcopter" in r["qopts"] and all(not x.startswith("sk_std_bi") for x in r["qopts"]), r)
    r=E("""()=>{ var S=T.S, k=S.add({kind:'body', key:'Bipedal'},'Sniper frame'); S.update(k.id,function(x){ x.roles=['Ranged']; });
      var mel=T.design('Brawler','ch_test_general','Melee'), rng=T.design('Marksman','ch_test_general','Ranged');
      var dm=T.WS.get(mel), dr=T.WS.get(rng);
      var a=S.optionsFor(dr).map(function(o){ return o.skin.id+':'+o.fits; }), b=S.optionsFor(dm).map(function(o){ return o.skin.id+':'+o.fits; });
      var emptyDefault=S.lookOf(dr).skin;
      var pid=T.P.put(T.P.blank(128,85,'x')); S.setPic(k.id,'v1','art',pid); var drawnDefault=S.lookOf(dr).skin;
      return {k:k.id, a:a, b:b, emptyDefault:emptyDefault, drawnDefault:drawnDefault, roles:S.rolesOf(dr), mel:mel, rng:rng}; }""")
    SNIPER=r["k"]; MARK=r["rng"]
    ck("skins suiting a design's roles come first, and are marked", r["a"]==[SNIPER+":true","sk_std_bipedal:false"] and r["roles"]==["Ranged"], r)
    ck("the rest can still be chosen", r["b"]==["sk_std_bipedal:false",SNIPER+":false"], r["b"])
    ck("an undrawn skin is never the default; a drawn one that suits it is", r["emptyDefault"]=="sk_std_bipedal" and r["drawnDefault"]==SNIPER, r)
    r=E("""(a)=>{ var S=T.S; S.chooseForDesign(a[1],'sk_std_bipedal','v1'); var d=T.WS.get(a[1]); var l=S.lookOf(d), c=T.WS.toCard(d);
      S.chooseForDesign(a[1],'nope','v1'); var l2=S.lookOf(T.WS.get(a[1]));
      S.chooseForDesign(a[1],'sk_std_quadcopter','v1'); var l3=S.lookOf(T.WS.get(a[1]));
      return {skin:d.skin, l:l, art:c.pixelArt, l2:l2, l3:l3}; }""", [SNIPER, MARK])
    ck("choosing a skin: the design keeps it and its card wears it", r["skin"]=={"skin":"sk_std_bipedal","variant":"v1"} and r["l"]["chosen"] and r["art"]=="px_skin_bipedal_art", r)
    ck("a skin that's gone, or of another body plan, falls back to the default", not r["l2"]["chosen"] and r["l2"]["skin"]==SNIPER and not r["l3"]["chosen"], r)

    # ================= variants and recolouring =================
    r=E("""()=>{ var S=T.S, k=S.add({kind:'body', key:'Hexapod'},'Crawler'); var a=T.P.put(Object.assign(T.P.blank(16,12,'a'),{kind:'art'})), t=T.P.put(Object.assign(T.P.blank(8,8,'t'),{kind:'token'}));
      T.fill(a,4); T.fill(t,4); S.setPic(k.id,'v1','art',a); S.setPic(k.id,'v1','token',t);
      var v=S.addVariant(k.id,'v1'); var k2=S.get(k.id), cols=S.colours(k.id,v.id);
      var n=S.recolour(k.id, v.id, {4:40}); var va=T.P.get(v.art), orig=T.P.get(a), after=S.colours(k.id,v.id);
      var flat=T.P.decode(va.flat, va.w*va.h), flatO=T.P.decode(orig.flat, orig.w*orig.h);
      return {k:k.id, vars:k2.variants.length, own:v.art!==a && v.token!==t, cols:cols, n:n, after:after, px:flat[0], orig:flatO[0], name:va.name}; }""")
    CRAWL=r["k"]
    ck("a variant starts as a copy of its skin's pictures, never the same ones", r["vars"]==2 and r["own"] and r["name"]=="Crawler · Variant 2 art", r)
    ck("the recolour tool lists the colours it uses", r["cols"]==[{"c":4,"n":256}], r["cols"])
    ck("and swaps them across its art and token together", r["n"]==256 and r["after"]==[{"c":40,"n":256}] and r["px"]==40 and r["orig"]==4, r)
    r=E("""(k)=>{ var S=T.S, v=S.get(k).variants[1]; var one=S.removeVariant(k,v.id), last=S.removeVariant(k,'v1'); return {one:one, last:last, n:S.get(k).variants.length}; }""", CRAWL)
    ck("a variant can be deleted, but not a skin's last", r=={"one":True,"last":False,"n":1}, r)
    r=E("""(k)=>{ var S=T.S; S.remove(k); var gone=!S.get(k); S.remove('sk_std_octopod'); var st=S.get('sk_std_octopod'), g=S.state().gone.slice();
      var n=S.restoreBuiltins(); return {gone:gone, st:st, g:g, back:!!S.get('sk_std_octopod'), n:n}; }""", SNIPER)
    ck("deleting a skin: what wore it goes back to the default", r["gone"], r)
    ck("a deleted stand-in stays gone until brought back", r["st"] is None and r["g"]==["sk_std_octopod"] and r["back"] and r["n"]==5, r)
    r=E("(id)=>T.S.lookOf(T.WS.get(id)).skin", MARK)
    ck("a design wearing a deleted skin wears the default", r=="sk_std_bipedal", r)

    # ================= Heroes =================
    r=E("""()=>{ var S=T.S, c=KETER_ALLCARDS().filter(function(x){ return x.name==='Test Warden'; })[0];
      var own=S.picFor(c,'token'), k=S.add({kind:'hero', key:'Test Warden'},'Warden in white'); var t=T.P.put(Object.assign(T.P.blank(16,16,'wt'),{kind:'token'})); S.setPic(k.id,'v1','token',t);
      var before=S.heroLook('Test Warden'); S.setHeroLook('Test Warden',{skin:k.id, variant:'v1'}); var worn=S.picFor(c,'token'), pics=S.heroPics(c);
      var other=S.add({kind:'hero', key:'Test Striker'},'x'); S.setHeroLook('Test Warden',{skin:other.id, variant:'v1'}); var wrong=S.heroLook('Test Warden');
      S.setHeroLook('Test Warden',{skin:k.id, variant:'v1'});
      return {own:own&&own.id, before:before, worn:worn&&worn.id, t:t, pics:pics, wrong:wrong, k:k.id}; }""")
    WSKIN=r["k"]; WTOK=r["t"]
    ck("a Hero wears its card's own art until a skin is chosen", r["before"] is None and r["own"]=="px_test_test_warden_token", r)
    ck("chosen once, its skin is what it wears", r["worn"]==r["t"] and r["pics"]["token"]==r["t"], r)
    ck("only its own skins can be chosen for it", r["wrong"] is None, r)

    # ================= a fight: Heroes and Enemies =================
    r=E("""()=>{ var S=T.S, g=KETER_ALLCARDS().filter(function(x){ return x.name==='Test Grunt'; })[0];
      var k=S.add({kind:'enemy', key:'Test Grunt'},'Grunt, rusted'); var t=T.P.put(Object.assign(T.P.blank(16,16,'gt'),{kind:'token'})); S.setPic(k.id,'v1','token',t);
      var v=S.addVariant(k.id,'v1'); var looks=S.enemyLooks(g); var seen={}; for(var i=0;i<60;i++) seen[S.pickEnemy(g)]=1;
      return {looks:looks, seen:Object.keys(seen).sort(), none:S.pickEnemy(KETER_ALLCARDS().filter(function(x){ return x.name==='Test Hacker'; })[0])}; }""")
    LOOKS=r["looks"]
    ck("an Enemy's looks: its card's own token and each of its skins' variants", len(LOOKS)==3 and LOOKS[0]=="px_test_test_grunt_token", LOOKS)
    ck("a spawn picks among them at random", r["seen"]==sorted(LOOKS), r["seen"])
    ck("an Enemy with only its own look keeps it", r["none"] is None, r)
    E("()=>KETER_GO('world')"); pg.wait_for_timeout(300)
    r=E("""()=>{ T.D.start(0); var W=T.W, m=W.map(), k=W.neighbours(m.dock).filter(W.isOpen)[0]; var s=T.D.cur(); s.pos=k; T.D._save(s); W.stand(k);
      T.D.ambush(k,{}); s=T.D.cur(); s.activity.floors=['TEST \\u00b7 Waves']; s.activity.skull=1; T.D._save(s);
      simDeployFight(T.D.spec()); simWizFinish(); T.close();
      var hero=SIM.units.filter(function(u){ return u.side==='ally' && /Warden/.test(u.name); })[0], ht=simTokenFor(hero);
      var grunts=SIM.units.filter(function(u){ return u.side==='enemy' && /Test Grunt/.test(u.src||u.name); });
      return {ht:ht&&ht.id, grunts:grunts.map(function(u){ return [u.look, (simTokenFor(u)||{}).id]; }), others:SIM.units.filter(function(u){ return u.side==='enemy' && !/Test Grunt/.test(u.src||u.name); }).map(function(u){ return u.look||null; })}; }""")
    ck("in a fight, a Hero wears its skin's token", r["ht"]==WTOK, r)
    ck("each Enemy that spawns wears one of its looks", (not r["grunts"]) or all(g[0] in LOOKS and g[1]==g[0] for g in r["grunts"]), r["grunts"])
    ck("an Enemy with one look spawns without a choice", all(x is None for x in r["others"]), r["others"])
    r=E("()=>{ var t=KETER_WORLD_UI._teamToken(); return t&&t.id; }")
    ck("on the World Map, the team is its first standing Hero, in its skin", r==WTOK, r)
    E("()=>{ T.D.abandon(); }")

    # ================= World Map art =================
    r=E("""()=>{ var A=T.A, sl=A.slots(); var g3=A.newPicture('map.ground.3'), g3b=A.newPicture('map.ground.3'), ic=A.newPicture('map.icon.poi'), ic2=A.newPicture('map.icon.poi');
      var pic=T.P.get(g3); return {n:sl.length, ids:sl.map(function(s){ return s.id; }).slice(0,8), g:A.ids('map.ground.3').length, icon:A.ids('map.icon.poi'), ic2:ic2, grid:pic.grid, shape:pic.shape, side:pic.side, orient:pic.orient, g3:g3, g3b:g3b}; }""")
    ck("World Map slots: ground for six Districts and none, six icons, collapsed tiles (and, from v13.8, the game's look; from v14.1, the fight's; from v14.2, the map's things, District fights and the menus'; from v14.3, the effects and the turn strip's icons; from v14.5, the atmosphere's motes; from v14.6, the card back; v14.12, Hardened's icon and mark)", r["n"]==179 and r["ids"][:7]==["map.ground.1","map.ground.2","map.ground.3","map.ground.4","map.ground.5","map.ground.6","map.ground.none"], r)
    ck("ground drawn in hex pixels, a hexagon filling a pointy-top tile", r["grid"]=="hex" and r["shape"]=="hexagon" and r["side"]==9 and r["orient"]=="flat", r)
    ck("ground takes several pictures (the game's four, and two more); an icon keeps its newest", r["g"]==6 and r["icon"]==[r["ic2"]], r)
    MAG=E("()=>KETER_PX.indexOfHex('#ff2bd6')")
    # (v14.2: the game's own ground and things are in their slots: out of District 3's, so only the two drawn here show)
    E("""(a)=>{ var A=T.A; A.ids('map.ground.3').forEach(function(id){ if(id!==a[0] && id!==a[1]) A.detach('map.ground.3', id, false); });
      A.ids('map.prop.3').forEach(function(id){ A.detach('map.prop.3', id, false); }); T.fill(a[0],a[2]); T.fill(a[1],a[2]); }""", [r["g3"], r["g3b"], MAG])
    r=E("""()=>{ var W=T.W, m=W.map(), k=Object.keys(m.tiles).filter(function(x){ return m.tiles[x].d==='3' && W.skullOf(x)===1 && !W.contentAt(x) && x!==m.dock; })[0];
      KETER_WORLD_UI._sel(null); KETER_WORLD_UI.render(); var V=KETER_WORLD_UI.state().view; var a=W.parse(k);
      V.size=20; V.cx=V.w/2-Math.sqrt(3)*20*(a.q+a.r/2); V.cy=V.h/2-1.5*20*a.r; KETER_WORLD_UI._paint();
      var cv=document.getElementById('wldCv'), g=cv.getContext('2d'), d=V.dpr||1, px=g.getImageData(Math.round(V.w/2*d), Math.round(V.h/2*d),1,1).data;
      V.size=4; KETER_WORLD_UI._paint(); var px2=g.getImageData(Math.round(V.w/2*d), Math.round(V.h/2*d),1,1).data;
      return {k:k, px:[px[0],px[1],px[2]], small:[px2[0],px2[1],px2[2]]}; }""")
    ck("a District's drawn ground shows on its tiles", r["px"][0]>200 and r["px"][1]<90 and r["px"][2]>170, r)
    ck("zoomed right out, the map keeps its colours", not (r["small"][0]>200 and r["small"][1]<90 and r["small"][2]>170), r)

    # ================= v13.8: the game's look =================
    r=E("""()=>{ var A=T.A, ui=A.slots().filter(function(s){ return s.group==='ui'; }); var t=A.newPicture('ui.title'), f=A.newPicture('ui.floor'), i=A.newPicture('ui.icon.hp'), i2=A.newPicture('ui.icon.hp');
      var pt=T.P.get(t), pf=T.P.get(f), pi=T.P.get(i2);
      return {ids:ui.map(function(s){ return s.id; }), names:ui.map(function(s){ return s.name; }), t:[pt.w,pt.h,pt.grid], f:[pf.w,pf.h,pf.grid], i:[pi.w,pi.h], kept:A.ids('ui.icon.hp'), i2:i2, ti:t, fi:f}; }""")
    ck("v14.1: and the fight's icons with them: 16 Status icons and 16 marks (v14.12: Hardened's), 7 Aether gems, 5 bar icons, 4 role icons and 7 card pictures (v14.2: and QM-7, its blink, Victory, Defeat, the gear and six District emblems; v14.3: and Move, Attack and End turn; v14.6: and the card back)", len(r["ids"])==84
       and r["ids"][62:65]==["ui.icon.act_move","ui.icon.act_attack","ui.icon.act_end"] and "ui.status.hardened" in r["ids"] and "ui.mark.hardened" in r["ids"]
       and r["ids"][72:78]==["ui.qm7","ui.qm7_blink","ui.title.victory","ui.title.defeat","ui.icon.gear","ui.card.back"] and r["ids"][78:]==["ui.icon.district_%d" % i for i in range(1,7)]
       and "ui.status.stunned" in r["ids"] and "ui.mark.gem_any" in r["ids"] and "ui.icon.bar_auto" in r["ids"] and "ui.icon.role_cyber" in r["ids"] and "ui.card.sphere" in r["ids"], len(r["ids"]))
    ck("v13.8: the game's look has slots of its own: its title, two backdrops, the fight floor, and ten icons",
       r["ids"][:14]==["ui.title","ui.backdrop.dock","ui.backdrop.menu","ui.floor","ui.icon.shards","ui.icon.part_troop","ui.icon.part_equipment","ui.icon.part_aether","ui.icon.hp","ui.icon.ac","ui.icon.ms","ui.icon.nrg","ui.icon.aether","ui.icon.skull"]
       and r["names"][:4]==["Title","Dock backdrop","Menu backdrop","Fight floor"] and r["names"][8]=="Health (HP) icon", r)
    ck("v13.8: each a square picture at the size the game draws its own (a backdrop fills the screen at five times its size), and one picture to a slot", r["t"]==[256,144,"square"] and r["f"]==[64,64,"square"] and r["i"]==[16,16] and r["kept"]==[r["i2"]], {k: r[k] for k in ("t","f","i","kept","i2")})
    E("(a)=>{ T.fill(a[0],a[3]); T.fill(a[1],a[3]); T.fill(a[2],a[3]); }", [r["ti"], r["fi"], r["i2"], MAG])

    # ================= your own slots =================
    r=E("""()=>{ var A=T.A, c=A.addCustom({name:'Loading screen 1', kind:'square', w:300, h:256}), h=A.addCustom({name:'Emblem', kind:'hex', side:12});
      var id=A.newPicture(c.id), pic=T.P.get(id), hid=A.newPicture(h.id), hp=T.P.get(hid);
      var cs=A.slots().filter(function(s){ return s.group==='custom'; }).map(function(s){ return s.name; });
      A.removeCustom(h.id); return {c:c, w:pic.w, h:pic.h, hp:[hp.grid,hp.side], cs:cs, after:A.slots().filter(function(s){ return s.group==='custom'; }).length}; }""")
    ck("a slot of your own, capped at 256 across", r["c"]["w"]==256 and r["w"]==256 and r["h"]==256, r)
    ck("square or hex pixels", r["hp"]==["hex",12] and r["cs"]==["Loading screen 1","Emblem"], r)
    ck("and deleted", r["after"]==1, r)

    # ================= Export for Godot =================
    r=E("""()=>{ var z=T.A.build(); var s=''; for(var i=0;i<z.bytes.length;i++) s+=String.fromCharCode(z.bytes[i]); return {b64:btoa(s), count:z.count, man:z.manifest}; }""")
    import base64
    zf=zipfile.ZipFile(io.BytesIO(base64.b64decode(r["b64"])))
    names=zf.namelist(); man=json.loads(zf.read("manifest.json"))
    ck("a real zip: every drawn graphic, the content and manifest.json", zf.testzip() is None and len(names)==r["count"]+8 and "manifest.json" in names, len(names))
    kinds=[c["kind"] for c in man["content"]]
    ck("the content the game reads, one file per kind, each with its format", kinds==["cards","floors","world_map","chassis","pools","tables","skins"] and all(json.loads(zf.read("content/"+k+".json"))["format"]==1 for k in kinds), man["content"])
    cards=json.loads(zf.read("content/cards.json"))["cards"]; floors=json.loads(zf.read("content/floors.json"))["floors"]
    ck("cards (designs and pre-builts too) and every saved floor", any(c.get("_src")=="design" for c in cards) and any(c["name"]=="Test Warden" for c in cards) and len(floors)>=4 and all("hexes" in f for f in floors), (len(cards), len(floors)))
    ck("and says which Companion made it", man["format"]==1 and man.get("companion"), man.get("companion"))
    ck("in folders by kind", any(n.startswith("skins/body/bipedal/bipedal_stand_in/standard_art") for n in names) and any(n.startswith("cards/hero/test_warden_art") for n in names) and any(n.startswith("map/ground/district_3_ground_") for n in names) and any(n.startswith("map/icons/poi_icon") for n in names) and any(n.startswith("custom/loading_screen_1") for n in names), [n for n in names][:12])
    ck("v13.8: the game's look in a folder of its own, its icons in one inside it", "ui/title.png" in names and "ui/fight_floor.png" in names and "ui/icons/health_hp_icon.png" in names, [n for n in names if n.startswith("ui/")])
    uent=[f for f in man["files"] if f["file"]=="ui/icons/health_hp_icon.png"]
    ck("v13.8: the manifest says which slot each is, and its size", bool(uent) and uent[0]["group"]=="ui" and uent[0]["owner"]=={"slot":"ui.icon.hp"} and uent[0]["w"]==16 and uent[0]["h"]==16 and uent[0]["grid"]=="square", uent)
    art=zf.read([n for n in names if n.startswith("skins/body/bipedal/bipedal_stand_in/standard_art")][0])
    w,h=struct.unpack(">II",art[16:24])
    ck("PNGs at their true size", art[:8]==b"\x89PNG\r\n\x1a\n" and (w,h)==(128,85), (w,h))
    ent=[f for f in man["files"] if f["file"].startswith("skins/body/bipedal/bipedal_stand_in/standard_token")][0]
    # (v14.1: the stand-ins' tokens are square now, the game's drawings; a test card's token is still hex)
    hx=[f for f in man["files"] if f.get("what")=="token" and f.get("owner",{}).get("card")=="Test Warden"][0]
    tok=zf.read(hx["file"]); tw,th=struct.unpack(">II",tok[16:24])
    ck("hex pictures drawn at a set scale, which the manifest records", hx["grid"]=="hex" and hx["hex"]["scale"]==4 and hx["hex"]["side"]==9 and tw>40 and th>40, (hx, tw, th))
    ck("v14.1: and a stand-in skin's token, the game's drawing, at its true size", ent["grid"]=="square" and ent["w"]==48 and ent["h"]==48 and struct.unpack(">II",zf.read(ent["file"])[16:24])==(48,48), ent)
    ck("the manifest says what each file is", all(k in ent for k in ("file","group","what","name","picture","owner")) and ent["owner"]["kind"]=="body" and ent["owner"]["key"]=="Bipedal", ent)
    ck("undrawn slots are left out", not any(n.startswith("map/ground/district_1") for n in names))

    # ================= the Pixel Studio's tabs, for a player =================
    E("()=>{ KETER_STUDIO.tab('library'); KETER_GO('studio'); }"); pg.wait_for_timeout(300)
    ck("the Studio has Library, Skins and Assets tabs", pg.locator('[data-pxstab]').count()==3 and pg.locator('#pxNewArt').count()==1)
    pg.locator('[data-pxstab="skins"]').click(); pg.wait_for_timeout(300)
    tx=E("()=>document.getElementById('v-studio').innerText")
    ck("Skins, for a player: every skin, read-only", "Bipedal stand-in" in tx and "Only Dev Mode can draw them" in tx and pg.locator('[data-skedit]').count()==0 and pg.locator('[data-sknew]').count()==0, tx[:300])
    ck("drawn as thumbnails", pg.locator('#v-studio canvas[data-pxt]').count()>=10)
    pg.locator('[data-sko="hero"]').click(); pg.wait_for_timeout(300)
    tx=E("()=>document.getElementById('v-studio').innerText")
    ck("Heroes: the card's own look and its skins", "TEST WARDEN · 1 SKIN" in tx.upper() and "The card’s own" in tx and "Warden in white" in tx, tx[:400])
    pg.locator('[data-sko="enemy"]').click(); pg.wait_for_timeout(300)
    tx=E("()=>document.getElementById('v-studio').innerText")
    ck("Enemies: those with skins, and a random look each spawn", "TEST GRUNT" in tx.upper() and "random look" in tx, tx[-300:])
    pg.locator('[data-pxstab="assets"]').click(); pg.wait_for_timeout(300)
    tx=E("()=>document.getElementById('v-studio').innerText")
    ck("Assets, for a player: counts, and Export for Godot, but no drawing", "drawn." in tx and pg.locator('#asExport').count()==1 and pg.locator('[data-skdraw]').count()==0, tx[:300])
    with pg.expect_download() as dl:
        pg.locator('#asExport').click()
    d=dl.value
    ck("Export for Godot downloads the zip", d.suggested_filename.startswith("KETER_export_") and d.suggested_filename.endswith(".zip"), d.suggested_filename)
    # (v14.2: the game's own are in every map slot from the start: two cleared, to be missing)
    E("()=>{ var A=T.A; A.ids('map.ground.1').forEach(function(id){ A.detach('map.ground.1', id, false); }); A.ids('map.icon.unique').forEach(function(id){ A.detach('map.icon.unique', id, false); }); }")
    pg.locator('[data-asf="map"]').click(); pg.wait_for_timeout(200)
    pg.locator('#asMiss').check(); pg.wait_for_timeout(200)
    tx=E("()=>document.getElementById('v-studio').innerText")
    ck("Missing only hides what's drawn", "District 1 ground" in tx and "District 3 ground" not in tx and "\nPOI icon" not in tx and "Unique POI icon" in tx, [l for l in tx.splitlines() if "3 ground" in l or "POI" in l])
    pg.locator('#asMiss').uncheck(); pg.wait_for_timeout(200)

    # ================= Dev Mode: drawing skins =================
    E("()=>{ localStorage.setItem('keter-app-dev','1'); KETER_STUDIO.tab('skins'); }"); pg.wait_for_timeout(300)
    pg.locator('[data-sko="body"]').click(); pg.wait_for_timeout(200)
    pg.locator('[data-sknew="body|Quadruped"]').click(); pg.wait_for_timeout(300)
    r=E("()=>{ var l=KETER_SKINS.forOwner('body','Quadruped'); return {n:l.length, edit:KETER_STUDIO_TABS.state().edit===l[l.length-1].id, id:l[l.length-1].id}; }")
    QS=r["id"]
    ck("Dev Mode: a new skin for a body plan, open to edit", r["n"]==2 and r["edit"], r)
    pg.locator(f'[data-skrole="{QS}|Melee"]').click(); pg.wait_for_timeout(200)
    ck("tagged with the roles it suits", E("(k)=>KETER_SKINS.get(k).roles",QS)==["Melee"])
    E("(k)=>{ var el=document.querySelector('[data-skname=\"'+k+'\"]'); el.value='Hound'; el.dispatchEvent(new Event('change',{bubbles:true})); }", QS); pg.wait_for_timeout(200)
    ck("and renamed", E("(k)=>KETER_SKINS.get(k).name",QS)=="Hound")
    pg.locator(f'[data-skdraw="{QS}|v1|art"]').click(); pg.wait_for_timeout(400)
    r=E("()=>{ var s=KETER_STUDIO.state(); return s&&s.pic?{w:s.pic.w, h:s.pic.h, kind:s.kind, id:s.id}:null; }")
    ck("Draw art opens a blank art, sized as a Troop's", r and r["w"]==128 and r["h"]==85 and r["kind"]=="art", r)
    ck("attached to the skin", E("(k)=>KETER_SKINS.get(k).variants[0].art",QS)==(r or {}).get("id"), r)
    pg.locator('#pxBack').click(); pg.wait_for_timeout(300)
    ck("back to the Skins tab", pg.locator('[data-sko]').count()==3)
    with pg.expect_file_chooser() as fc:
        pg.locator(f'[data-skimg="{QS}|v1|token"]').click()
    fc.value.set_files(str(IMG)); pg.wait_for_timeout(700)
    # (v14.1: a new skin's token is 48 by 48 square by default, the size the game draws a Unit at)
    ck("Token from an image: a blank token, 48 square, then the converter onto it", pg.locator('#pxConv').count()==1 and E("()=>{ var p=KETER_STUDIO.state().pic; return p.grid+' '+p.w+'x'+p.h; }")=="square 48x48")
    pg.locator('#pxConvGo').click(); pg.wait_for_timeout(500)
    r=E("(k)=>{ var t=KETER_SKINS.get(k).variants[0].token, p=KETER_PX.get(t); return {layers:p.frames[0].layers.map(function(l){ return l.name; }), cols:KETER_SKINS.colours(k,'v1').length}; }", QS)
    ck("the image lands on the skin's token", "Converted" in r["layers"] and r["cols"]>=2, r)
    pg.locator('#pxBack').click(); pg.wait_for_timeout(300)
    pg.locator(f'[data-skvar="{QS}|v1"]').click(); pg.wait_for_timeout(300)
    ck("Make a variant opens the recolour tool", pg.locator('.skrc').count()==1 and pg.locator('[data-skfrom]').count()>=2)
    src=E("()=>+document.querySelector('[data-skfrom]').getAttribute('data-skfrom')")
    pg.locator('[data-skfrom]').first.click(); pg.wait_for_timeout(200)
    pg.locator('[data-skto="5"]').click(); pg.wait_for_timeout(200)
    ck("tap a colour, then its replacement: the preview changes", E("()=>KETER_STUDIO_TABS.state().rc.map")=={str(src):5})
    pg.locator('#skRcGo').click(); pg.wait_for_timeout(300)
    r=E("(k)=>{ var v=KETER_SKINS.get(k).variants; return {n:v.length, cols:KETER_SKINS.colours(k,v[1].id).map(function(c){ return c.c; }), orig:KETER_SKINS.colours(k,'v1').map(function(c){ return c.c; })}; }", QS)
    ck("Apply recolours the variant only", r["n"]==2 and 5 in r["cols"] and src not in r["cols"] and src in r["orig"], r)

    # ================= the Assets tab, Dev Mode =================
    E("()=>{ KETER_STUDIO.tab('assets'); }"); pg.wait_for_timeout(300)
    pg.locator('[data-asf="map"]').click(); pg.wait_for_timeout(200)
    pg.locator('[data-asnew="map.collapsed"]').click(); pg.wait_for_timeout(400)
    r=E("()=>{ var s=KETER_STUDIO.state(); return {grid:s.pic.grid, slot:s.pic.slot, ids:KETER_ASSETS.ids('map.collapsed').length}; }")
    ck("Dev Mode: Draw on a map slot opens a new hex picture in it (beside the game's three of rubble)", r=={"grid":"hex","slot":"map.collapsed","ids":4}, r)
    pg.locator('#pxBack').click(); pg.wait_for_timeout(300)
    pg.locator('[data-asf="custom"]').click(); pg.wait_for_timeout(200)
    pg.locator('#asCName').fill("Logo"); pg.locator('#asCKind').select_option("square"); pg.locator('#asCW').fill("64"); pg.locator('#asCH').fill("32")
    pg.locator('#asCAdd').click(); pg.wait_for_timeout(200)
    ck("Add a slot, from the page", E("()=>KETER_ASSETS.slots().filter(function(s){ return s.name==='Logo'; }).map(function(s){ return [s.w,s.h]; })")==[[64,32]])
    pg.locator('[data-asf="cards"]').click(); pg.wait_for_timeout(200)
    pg.locator('#asQC').fill("Test Surge"); pg.wait_for_timeout(300)
    ck("Cards: find one, and draw its art", pg.locator('[data-ascard="Test Surge|test|art"]').count()==1 and pg.locator('[data-ascard="Test Surge|test|token"]').count()==0)

    # ================= the Workshop's Look =================
    E("()=>{ localStorage.removeItem('keter-app-dev'); KETER_GO('workshop'); }"); pg.wait_for_timeout(300)
    E("(id)=>document.querySelector('[data-wsopen=\"'+id+'\"]').click()", MARK); pg.wait_for_timeout(400)
    tx=E("()=>document.getElementById('wsLook').innerText")
    ck("the Workshop: a design's Look, from its body plan's skins", "LOOK · BIPEDAL" in tx.upper() and pg.locator('[data-wslook]').count()>=1, tx)
    pg.locator('[data-wslook="sk_std_bipedal|v1"]').click(); pg.wait_for_timeout(300)
    ck("tap one to wear it", E("(id)=>KETER_WORKSHOP.get(id).skin",MARK)=={"skin":"sk_std_bipedal","variant":"v1"} and pg.locator('[data-wslook="sk_std_bipedal|v1"].on').count()==1)
    E("()=>document.getElementById('wsBack').click()"); pg.wait_for_timeout(300)
    E("()=>document.querySelector('[data-wsopen=\"ds_starter\"]').click()"); pg.wait_for_timeout(400)
    ck("the starter's Look is shown but can't be changed", pg.locator('[data-wslook]').count()>=1 and pg.locator('[data-wslook]').first.is_disabled())
    E("()=>document.getElementById('wsBack').click()"); pg.wait_for_timeout(200)

    # ================= a Hero's Look on its card =================
    E("()=>KETER_GO('comp')"); pg.wait_for_timeout(500)
    pg.locator("#cq").fill("Test Warden"); pg.wait_for_timeout(500)
    pg.locator(".crow, .gcard").first.click(); pg.wait_for_timeout(1200)
    tx=E("()=>document.getElementById('modal').innerText")
    ck("a Hero's card: its Look, the card's own or a skin", "LOOK" in tx.upper() and pg.locator('#modal [data-herolook]').count()==2 and pg.locator(f'#modal [data-herolook="{WSKIN}|v1"].on').count()==1, tx[-300:])
    pg.locator('#modal [data-herolook="own"]').click(); pg.wait_for_timeout(800)
    ck("choosing the card's own clears the skin", E("()=>KETER_SKINS.heroLook('Test Warden')") is None and pg.locator('#modal [data-herolook="own"].on').count()==1)
    E("()=>document.getElementById('modal').classList.remove('on')")

    # ================= the picture library's cache =================
    r=E("""()=>{ var P=KETER_PX, a=P.get('px_skin_bipedal_art'); a.name='changed in memory'; var b=P.get('px_skin_bipedal_art');
      var id=P.put(P.blank(4,4,'fresh')); var raw=JSON.parse(localStorage.getItem(P.LIB_KEY))[id]; P.remove(id);
      return {same:b.name, saved:!!raw, gone:!P.has(id)}; }""")
    ck("the library is read once per change, and hands out copies", r["same"]!="changed in memory" and r["saved"] and r["gone"], r)
    ck("no page errors", not errs, errs)
    b.close()
print(f"\nSKINS PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗",x)
srv.shutdown()
