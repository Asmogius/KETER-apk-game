#!/usr/bin/env python3
"""Revision 15.8 conversion. Usability Restrictions left the rules: a card's
usableBySubtype goes, and Equipment, Action and Command cards (which only ever
carried Archetypes to say who could use them) carry none. A variable cost,
which used to be saved as a flag and a 0 where the X stood, gets its X back:
in the first empty slot, Generic before Affinity. Safe to run twice."""
import json, re, sys
X=re.compile(r'^X{1,3}$', re.I)
def convert(c):
    said=[]
    if c.get("usableBySubtype"):
        said.append("no longer for %s only" % c["usableBySubtype"])
    if "usableBySubtype" in c: del c["usableBySubtype"]
    if c.get("cardType") in ("equipment","action","command") and c.get("archetypes"):
        said.append("no longer for %s only" % " / ".join(c["archetypes"]))
        c["archetypes"]=[]
    a=c.get("aetherCost")
    if c.get("hasVariableCost") and isinstance(a,dict) and not any(X.match(str(a.get(k,""))) for k in ("generic","affinity","affinity2")):
        k="generic" if not int(a.get("generic") or 0) else ("affinity" if not int(a.get("affinity") or 0) else None)
        if k:
            a[k]="X"; said.append("its X is put in the %s slot" % ("Any Affinity" if k=="generic" else "Affinity"))
    return said
if __name__=="__main__":
    path=sys.argv[1] if len(sys.argv)>1 else "compendium_full.json"
    comp=json.load(open(path)); n=0
    for c in comp["cards"]:
        said=convert(c)
        if said: n+=1; print("  %s: %s" % (c.get("name"), "; ".join(said)))
    json.dump(comp,open(path,"w"),indent=1)
    print(f"{n} cards converted to Revision 15.8")
