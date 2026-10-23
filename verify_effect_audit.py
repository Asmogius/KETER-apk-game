"""The effect box audit (Companion 14.10, and its second round in 14.11 with
Revision 16.3's keywords): every effect box on every master card reads in
keywords the rules know, or is flagged with the reason it can't yet;
the blank Units are filled in; the field fixes are made; and in the app the
converted text is coloured, the Card Forge reads it clean, and the Battle
Simulator carries out converted and drafted abilities."""
import http.server, socketserver, threading, functools, pathlib, shutil, json, subprocess
from playwright.sync_api import sync_playwright
ok, bad = [], []
def ck(n, c, d=""):
    (ok if c else bad).append(n + ((" — " + str(d)[:260]) if not c else ""))
    print(("PASS " if c else "FAIL ") + n + ("" if c else "  — " + str(d)[:260]))

# ---- the Compendium itself, read with the app's own keyword reader ----
NODE = r"""
global.window={};global.localStorage={getItem:()=>null,setItem:()=>{}};
require("./keywords.js"); const K=window.KETER_KW;
const comp=require("./compendium_full.json").cards; const names=new Set(comp.map(c=>c.name));
comp.forEach(c=>{ if(c.archetypes&&c.archetypes.length) K.registerArchetypes(c.archetypes); });
const FILL=new Set("takes take gains gain with for of and is spent as a faces an troop's card from the discard pile on".split(" "));
const out={boxes:0,keyword:0,attacks:0,flagged:0,partial:0,bad:[],flagNoNote:[],blankUnits:[],noAction:[]};
for(const c of comp){ if(c.testCard) continue;
  const unit=/^(enemy|elite|miniboss|boss|hero|troop)$/.test(c.cardType);
  if(unit){ const s=c.stats||{}; if(!s.hp||!s.ac||s.move===undefined||s.move==="") out.blankUnits.push(c.name);
    if(!(c.entries||[]).some(e=>e.kind!=="Passive"&&e.kind!=="Aura")) out.noAction.push(c.name); }
  for(const e of c.entries||[]){ out.boxes++; const t=(e.text||"").trim();
    if(!t){ out.attacks++; continue; }
    const flag=/^Left out of the keywords/.test(e.needsReview||"") ? "partial" : (e.needsReview ? "flag" : null);
    if(flag==="flag"){ out.flagged++; continue; }
    if(flag==="partial") out.partial++;
    const probs=[];
    for(const p of K.parse(t)) if(p.type==="kw"){ if(!p.kw) probs.push("unknown or retired: "+(p.n||"")); else if(p.kw.name==="Deploy"){ const m=String(p.n||"").match(/^(\d+|X)\s+(.+)$/); if(!m||!names.has(m[2])) probs.push("Deploy of no card"); } }
    const kind=(e.kind==="Passive"||e.kind==="Aura")?"passive":"action";
    K.sentences(t).flatMap(s_=>K.problems(K.analyse(s_),{kind:kind})).forEach(x=>probs.push(x));
    const left=t.replace(/\[\[[^\]]*\]\]/g," ").toLowerCase().replace(/[.,:"]/g," ").split(/\s+/).filter(w=>w&&!FILL.has(w));
    if(left.length && flag!=="partial") probs.push("plain words: "+left.join(" "));
    if(!/\[\[/.test(t)) probs.push("no keywords at all");
    if(probs.length) out.bad.push([c.name,e.name||"",probs.join("; ")]); else out.keyword++;
  }}
console.log(JSON.stringify(out));
"""
r = json.loads(subprocess.run(["node", "-e", NODE], capture_output=True, text=True, cwd=".").stdout)
ck("every effect box on a master card is read: 249 of them (the audit's 223, less the 21 blank Units, plus their 45 drafted abilities, less the four cards deleted in 14.13, plus the free Heroes' six in 14.14)", r["boxes"] == 249, r["boxes"])
ck("each reads in keywords the library knows, with no plain rules words, no retired keyword and nothing the Card Forge flags", not r["bad"] and r["keyword"] >= 120, r["bad"][:5])
ck("none is left flagged or partly written: the four 14.11 couldn't write (Split Chip, Reforge, Hold Fast, Quartermaster's Seal) were deleted in 14.13, and are gone", r["flagged"] == 0 and r["partial"] == 0 and not any(c["name"] in ["Split Chip", "Reforge", "Hold Fast", "Quartermaster's Seal"] for c in json.loads(pathlib.Path("compendium_full.json").read_text(encoding="utf-8"))["cards"]), (r["flagged"], r["partial"]))
ck("no Unit is left blank: every one has Health, Armor Class and Movement", not r["blankUnits"], r["blankUnits"])
ck("and every one has an Action, but for three Troops that never had one (Ledger Runner, Slag Hauler, Chaff Swarm)", sorted(r["noAction"]) == ["Chaff Swarm", "Ledger Runner", "Slag Hauler"], r["noAction"])

comp = {c["name"]: c for c in json.loads(pathlib.Path("compendium_full.json").read_text(encoding="utf-8"))["cards"]}
def ent(card, name=""):
    return [e for e in comp[card]["entries"] if (e.get("name") or "").strip() == name][0]
ck("examples: Field Dressing heals an ally within 1 tile; Rivet Slam pushes; Arc Lance's text was only its own damage, and is cleared",
   ent("Field Dressing")["text"] == "[[target ally]] [[within 1]] gains [[heal 6]]." and ent("Foundry Sentinel", "Rivet Slam")["text"] == "[[target enemy]] takes [[Push 1]]." and ent("Volt-Warden Ryska", "Arc Lance")["text"] == "")
ck("Splash is gone: the Aetherium Golem's eruption is AoE 1", ent("Aetherium Golem", "Aether eruption")["text"].startswith("[[AoE 1]]."))
ck("the fixes: six Chips played on a Unit are Actives, Dragonskin lining is a Passive, and four Energy costs moved into the Energy field",
   all(ent(n)["kind"] == "Active" for n in ["Barbed Chip", "Bolstering Chip", "Bastion Chip", "Invigorating Chip", "Surge Chip", "Ballast Chip"]) and ent("Dragonskin lining")["kind"] == "Passive"
   and ent("Courrier exorunners", "Leap")["energyCost"] == "1" and ent("HALO targeting System", "Identify Molecular Flaw")["energyCost"] == "1"
   and ent("MONTU Battle Suit", "Doom.exe")["energyCost"] == "3" and ent("Personal mounted cluster ordinance", "Lay waste")["energyCost"] == "3")
ck("SPOOL is gone (14.11): Rictus spins up with DMG and MS doses that last 3 rounds, and Field Triage heals all allies", "SPOOL" not in json.dumps([e for c in comp.values() for e in c.get("entries") or [] if not e.get("needsReview")])
   and ent("Rictus", "Spin-Up")["text"].startswith("[[when]] [[the round begins]], [[this Unit]] gains [[DMG +2]] for [[turns 3]].") and ent("Field Triage")["text"] == "[[all allies]] gain [[heal 1]].")
dr = comp["Earthshaker Titan"]
ck("the drafts are in: the Earthshaker Titan is a Skull 6 Juggernaut of 160 Health with Hammer Fists; the Mincer a rare Berserker Hero; ONYX uses library Archetypes",
   dr["skullLevel"] == 6 and dr["stats"]["hp"] == "160" and dr["archetypes"] == ["Juggernaut"] and dr["entries"][0]["name"] == "Hammer Fists"
   and comp['"Mincer" Cleaner Bot']["rarity"] == "rare" and comp['"Mincer" Cleaner Bot']["archetypes"] == ["Berserker"]
   and all("Cyborg" not in comp[n]["archetypes"] for n in comp if n.startswith("ONYX ")))

# ---- in the app ----
TMP = pathlib.Path("/tmp/serve_effect_audit")
if TMP.exists(): shutil.rmtree(TMP)
shutil.copytree("pwa", TMP); shutil.copy("compendium_full.json", TMP / "compendium.json")
class H(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
class Q(socketserver.TCPServer): allow_reuse_address = True
srv = Q(("127.0.0.1", 9876), functools.partial(H, directory=str(TMP)))
threading.Thread(target=srv.serve_forever, daemon=True).start()
hexes = [[f"{q},{r}", {}] for q in range(-4, 5) for r in range(-4, 5) if abs(q + r) <= 4]
FLOOR = {"v": 6, "name": "Audit Test", "radius": 4, "hexes": hexes, "walls": [], "marks": [], "symDefs": [], "colorLabels": {}}
SETUP = """(spec)=>{
  var all=JSON.parse(localStorage.getItem('keter-hexmap-levels')||'{}'); all['Audit Test']=window.FLOOR_IN; localStorage.setItem('keter-hexmap-levels',JSON.stringify(all));
  SIM.map=simLoadFloor('Audit Test');
  SIM.units=spec.map(function(s){ var c=simAllCards().filter(function(x){ return x.name===s[0]; })[0];
    var u=KETER_RULES.unitFromCard(simUnitSpec(c,s[1]),s[1]); u.id=s[2]; u.pos={q:s[3],r:s[4]}; return u; });
  SIM.round=1; SIM.phase='turn'; SIM.log=[]; SIM.over=false; SIM.autoRunning=true;
  SIM.hand=[]; SIM.deck=[]; SIM.discard=[]; SIM.aether={}; SIM.pendingAct=null; SIM.burst=null;
  simApplyContinuous(); renderSim(); return SIM.units.length; }"""
U = "function(id){ return SIM.units.filter(function(u){ return u.id===id; })[0]; }"
with sync_playwright() as p:
    b = p.chromium.launch()
    pg = b.new_context(viewport={"width": 412, "height": 915}).new_page(); errs = []
    pg.on("pageerror", lambda e: errs.append(str(e)[:200]))
    pg.on("dialog", lambda d: d.accept())
    pg.goto("http://127.0.0.1:9876/"); pg.wait_for_timeout(2500)
    E = pg.evaluate
    E("()=>localStorage.setItem('keter-app-dice',JSON.stringify({dur:0}))")
    r = E("""()=>{ var K=KETER_KW, c=simAllCards().filter(function(x){ return x.name==='Field Dressing'; })[0];
      var runs=K.displayRuns((c.entries||c.effects)[0].text); return {ver:window.KETER_APP_VER||null, coloured:runs.filter(function(x){ return x.kw; }).map(function(x){ return x.cat; })}; }""")
    ck("the app is 14.16, and Field Dressing's text is coloured keywords (its Target, narrowed to within 1 tile, then its Effect)", r["ver"] == "14.16" and r["coloured"] == ["target", "effect"], r)
    pg.locator("#nav button[data-go='home']").click(); pg.wait_for_timeout(500)
    pg.locator('.lt[data-page="battle"]').click(); pg.wait_for_timeout(900)
    E("(g)=>{ window.FLOOR_IN=g; }", FLOOR)
    # a drafted Troop's attack, carried out: ONYX Brute's Power Fist pushes
    E(SETUP, [["ONYX Brute", "ally", "a1", 0, 0], ["Test Grunt", "enemy", "e1", 1, 0]])
    r = E("""()=>{ var U=""" + U + """, b=U('a1'), g=U('e1'), a=b.actions.filter(function(x){ return x.name==='Power Fist'; })[0], pushed=0, n=0;
      for(var i=0;i<12;i++){ g.pos={q:1,r:0}; g.hp=40; g.statuses=[]; b.nrg=3; SIM.log=[]; simConfirmAttack(b,g,a);
        var l=SIM.log.map(function(x){ return x.text; }).join(' | '); if(/: \\d+ damage/.test(l)){ n++; if(KETER_RULES.hexDistance(b.pos,g.pos)===3) pushed++; } }
      return {acts:b.actions.map(function(x){ return x.name; }), n:n, pushed:pushed}; }""")
    ck("the ONYX Brute, drafted, fights: each Power Fist that lands pushes its target 2 tiles", r["acts"] == ["Power Fist", "Haymaker"] and r["n"] > 0 and r["pushed"] == r["n"], r)
    # a converted Passive held: Vantage Servo Harness's MS and a Unit's Passive
    E(SETUP, [["FALCON Drone", "ally", "a1", 0, 0], ["Test Grunt", "enemy", "e1", 3, 0]])
    r = E("""()=>{ var U=""" + U + """, d=U('a1'), eff=KETER_RULES.effective(d); return {flying:!!eff.flying, ev:(d.statuses||[]).concat(d.mods||[]).map(function(s){ return (s.name||s.stat)+':'+(s.amt||s.n||s.amount||''); })}; }""")
    ck("the FALCON Drone's Passive, converted, holds: it flies", r["flying"], r)
    # a converted Action from the Unit's bar: Chrome Junkie's Emergency Recharge heals itself
    E(SETUP, [["Exo Husk", "ally", "a1", -2, 0], ["Chrome Junkie", "enemy", "e1", 2, 0]])
    r = E("""()=>{ var U=""" + U + """, j=U('e1'); j.hp=10; SIM.log=[]; simRunText(j.actions.filter(function(a){ return a.name==='Emergency Recharge'; })[0].text,{actor:j, sourceCard:'Emergency Recharge'});
      return {hp:j.hp, log:SIM.log.map(function(l){ return l.text; })}; }""")
    ck("Chrome Junkie's Emergency Recharge, converted, heals it 5", r["hp"] == 15, r)
    ck("no page errors", not errs, errs[:3])
    b.close()
srv.shutdown()
print(f"\nEFFECT AUDIT PASS {len(ok)}  FAIL {len(bad)}")
for x in bad: print("  ✗", x)
