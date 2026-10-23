#!/usr/bin/env python3
"""Mark up the effect text of existing cards for Handbook 15.1.

Conservative by design. It marks keywords the library knows, merges a trailing
number into its keyword, and rewords only the plainest damage and heal lines
into the grammar's order. Anything with a condition, a scaling value, a dice
roll or a retired keyword is left exactly as written and reported instead, so
no card quietly changes meaning.
"""
import json, re, sys

LIB = json.loads(open("keyword_names.json").read()) if False else None

KNOWN = ["Rooted","Stunned","Slowed","Marked","Pinned","Poisoned","Bleed","Weakened",
         "Sundered","Drained","Pierce","Chain","AoE","Deploy","Sacrifice","Flying",
         "Push","Suppressive Fire"]
RETIRED = ["SPOOL","Splash"]
HARD = re.compile(r'\b(if|when|whenever|for each|per |roll a|instead|may |choose|up to)\b', re.I)

def markup(text):
    """Return (new_text, notes). notes is why it was left alone, if it was."""
    notes = []
    out = text

    # [[Keyword]]N and [[Keyword]] N become one piece: [[Keyword N]]
    out = re.sub(r'\[\[([^\]]+)\]\]\s*(\d+)', lambda m: "[["+m.group(1).strip()+" "+m.group(2)+"]]", out)

    # bare capitalised keywords, with or without a number
    for kw in KNOWN:
        out = re.sub(r'(?<!\[)\b'+kw.upper()+r'(\d+)?\b',
                     lambda m: "[["+kw+(" "+m.group(1) if m.group(1) else "")+"]]", out)
        out = re.sub(r'(?<!\[)\b'+kw+r'(\d+)\b',
                     lambda m: "[["+kw+" "+m.group(1)+"]]", out)

    for r in RETIRED:
        if re.search(r'\b'+r+r'\b', out, re.I):
            notes.append("uses "+r+", which is withdrawn")

    if HARD.search(re.sub(r'\[\[[^\]]+\]\]','',out)):
        notes.append("has a condition or a scaling value; needs marking up by hand")
        return out, notes

    # the plainest damage and heal lines, put into Target, Effect order
    body = out.strip().rstrip('.')
    m = re.match(r'^Deals?\s+(\d+)\s*(?:DMG|damage)$', body, re.I)
    if m:
        return "[[target enemy]] takes [[damage "+m.group(1)+"]].", notes
    m = re.match(r'^Deals?\s+(\d+)\s*(?:DMG|damage)\s+to\s+(?:one\s+|the\s+)?'
                 r'target(?:ed)?(?:\s+(?:unit|enemy))?$', body, re.I)
    if m:
        return "[[target enemy]] takes [[damage "+m.group(1)+"]].", notes
    m = re.match(r'^Deals?\s+(\d+)\s*(?:DMG|damage)\s+to\s+all\s+enem(?:y|ies)'
                 r'(?:\s+units?)?\s+within\s+(?:a\s+)?(\d+)\s*tiles?'
                 r'(?:\s+radius)?$', body, re.I)
    if m:
        return ("[[all enemies within "+m.group(2)+"]] take [[damage "+m.group(1)+"]].", notes)
    m = re.match(r'^Heals?\s+(\d+)$', body, re.I)
    if m:
        return "[[target ally]] gains [[heal "+m.group(1)+"]].", notes
    m = re.match(r'^Heals?\s+(?:the\s+)?target(?:\s+ally|\s+unit)?\s+(?:for\s+)?(\d+)$', body, re.I)
    if m:
        return "[[target ally]] gains [[heal "+m.group(1)+"]].", notes

    if "[[" not in out:
        notes.append("nothing the library knows; plain text for now")
    return out, notes

def main():
    path = sys.argv[1] if len(sys.argv)>1 else "compendium_full.json"
    comp = json.load(open(path))
    changed = flagged = 0
    report = []
    for c in comp["cards"]:
        for e in (c.get("abilities") or c.get("entries") or []):
            t = (e.get("text") or "")
            if not t.strip(): continue
            new, notes = markup(t)
            if new != t:
                e["text"] = new; changed += 1
                report.append(("changed", c["name"], t, new))
            if notes:
                flagged += 1
                e["needsReview"] = "; ".join(notes)
                report.append(("flagged", c["name"], t, "; ".join(notes)))
    json.dump(comp, open(path,"w"), indent=1)
    print(f"marked up {changed} effects, flagged {flagged}")
    return report

if __name__ == "__main__":
    rep = main()
    for kind,name,before,after in rep[:14]:
        print(f"  [{kind:7}] {name[:22]:22} {before[:52]}")
        print(f"            -> {after[:74]}")
