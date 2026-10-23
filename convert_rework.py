#!/usr/bin/env python3
"""The unit rework, applied to the card list. Every Troop is mechanical and the
Human/Cyborg/Mechanical subtype becomes lore only (kept as "origin"); subtypes
are now Combat Roles, at most two. Will, Security and Intelligence give way to
Integrity (INT), which starts equal to Armor Class. Overwhelmed and Compromised
are gone: four cards built on them are deleted, five effects reworded as decided.
Safe to run twice."""
import json, sys
DELETE={"Flywheel Coupling","Static Wash","Redundant Servos","Static Field"}
REWORD={
 ("Salvage Aether Core",""): ("Sacrifice 1 [[Mechanical]] Troop. Draw 1 Aether Chip.","Sacrifice 1 Troop. Draw 1 Aether Chip."),
 ("Salvage Hard Drive",""): ("Sacrifice 1 [[Mechanical]] Troop. Draw 1 Aether Chip.","Sacrifice 1 Troop. Draw 1 Aether Chip."),
 ("Volt-Warden Ryska","Arc Lance"): ("Deal 7 damage. Mechanical targets gain [[Compromised]].","Deal 7 damage."),
 ("Sable-Nine, Ledger Adept","Foreclose"): ("Deal 5 damage. A Mechanical target gains [[Compromised]].","Deal 5 damage."),
 ("Repair Kit",""): ("Heals 8 to a Mechanical or Cyborg Unit. Cannot be used on a [[Compromised]] Unit.","Heals 8 to a Troop."),
}
ROLES={"Cyber Savant":["cyber","ranged"]}
UNIT_TYPES=("hero","troop","enemy","elite","miniboss","boss")
def convert(comp):
    log={"deleted":0,"reworded":0,"origins":0,"integrity":0,"roles":0}
    before=len(comp["cards"])
    comp["cards"]=[c for c in comp["cards"] if c.get("name") not in DELETE]
    log["deleted"]=before-len(comp["cards"])
    for c in comp["cards"]:
        for e in c.get("entries") or []:
            k=(c.get("name"),(e.get("name") or "").strip())
            if k in REWORD and e.get("text")==REWORD[k][0]:
                e["text"]=REWORD[k][1]; log["reworded"]+=1
        sub=str(c.get("subtype") or "").strip()
        if sub:
            c["origin"]=sub.capitalize()   # lore and flavour only
            log["origins"]+=1
        c.pop("subtype",None)
        st=c.get("stats")
        if isinstance(st,dict) and str(c.get("cardType","")).lower() in UNIT_TYPES:
            for k in ("will","sec"): st.pop(k,None)
            if "intRework" not in c:
                st["int"]=st.get("ac") if str(st.get("ac","")).strip() else "10"
                c["intRework"]=True; log["integrity"]+=1
        if c.get("name") in ROLES and c.get("combatRoles")!=ROLES[c["name"]]:
            c["combatRoles"]=ROLES[c["name"]]; log["roles"]+=1
        if isinstance(c.get("combatRoles"),list) and len(c["combatRoles"])>2:
            raise SystemExit("more than two Combat Roles left on "+c["name"])
    return log
if __name__=="__main__":
    path=sys.argv[1] if len(sys.argv)>1 else "compendium_full.json"
    comp=json.load(open(path)); log=convert(comp)
    json.dump(comp,open(path,"w"),indent=1); print(log)
