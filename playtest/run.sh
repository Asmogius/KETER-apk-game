#!/bin/bash
# run.sh FLOOR SEED — one combat, reported
cd /home/claude/build
timeout 290 python3 playtest/playtest.py "$1" "$2" ${3:-6} ${4:-2} > /tmp/pt.txt 2>&1
python3 - <<'PY'
import json
t=open('/tmp/pt.txt').read(); i=t.find('{\n "floor"')
if i<0:
    import re; print("NO REPORT:", re.findall(r'line \d+, in <module>', t)[:1], re.findall(r'waiting for locator\([^)]*\)', t)[:1], t[-200:]); raise SystemExit
d=json.loads(t[i:]); s=d['summary']
print(d['floor'],'seed',d['seed'],'|',d['actions'],'actions | round',s['round'],'|',s['outcome'],'| allies',s['allies'],'foes',s['foes'],'wave',s['wave'])
for x in d['issues']: print(' ISSUE',x['kind'],'r'+str(x['round']),'|',x['detail'][:300],'| after',x['after'][-2:])
if not d['issues']: print(' no issues')
print(' odd moves:', ', '.join(w.replace('WEIRD: ','') for w in d.get('weird',[])))
PY
