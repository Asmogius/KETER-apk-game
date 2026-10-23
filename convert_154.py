#!/usr/bin/env python3
"""Revision 15.4 conversion. Modify becomes the Stats keywords ([[Modify AC +2]]
-> [[AC +2]]); a strengthless status written with a number, which meant turns,
has the number moved into a Duration ([[Rooted 2]] -> [[Rooted]] for
[[turns 2]]) unless its sentence already has one. Safe to run twice."""
import json, re, sys
SL=["Rooted","Stunned","Marked","Pinned","Bleed","Overwhelmed","Compromised"]
STAT={"RANGE":"Range"}
def convert_text(t):
    t=re.sub(r'\[\[Modify\s+([A-Za-z]+)\s*([+-]?\d+)\]\]',
             lambda m:"[["+STAT.get(m.group(1).upper(),m.group(1).upper() if m.group(1).upper()!="RANGE" else "Range")+" "+(m.group(2) if m.group(2)[0] in "+-" else "+"+m.group(2))+"]]", t)
    parts=re.split(r'(?<=[.!?])(\s+)', t)
    out=[]
    for s in parts:
        has_dur=bool(re.search(r'\[\[(turns[^\]]*|persistent|while attached)\]\]', s))
        def fix(m):
            name,n=m.group(1),m.group(2)
            return "[["+name+"]]" if has_dur else "[["+name+"]] for [[turns "+n+"]]"
        s=re.sub(r'\[\[(%s) (\d+)\]\]'%"|".join(SL), fix, s)
        out.append(s)
    return "".join(out)
if __name__=="__main__":
    path=sys.argv[1] if len(sys.argv)>1 else "compendium_full.json"
    comp=json.load(open(path)); n=0
    for c in comp["cards"]:
        for e in c.get("entries") or []:
            t=e.get("text") or ""; nt=convert_text(t)
            if nt!=t: e["text"]=nt; n+=1
    json.dump(comp,open(path,"w"),indent=1)
    print(f"{n} effects converted to Revision 15.4")
