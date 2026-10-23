#!/bin/bash
# run_batch.sh FROM COUNT — runs that slice of every verify_*.py, appending results
cd /home/claude/build
ls verify_*.py | sed -n "$1,$(( $1 + $2 - 1 ))p" | while read t; do
  # the game's suite runs Godot and both case generators: it gets longer
  lim=70; [ "$t" = "verify_game.py" ] && lim=2400
  full=$(timeout $lim python3 "$t" 2>&1)
  r=$(echo "$full" | grep -E "PASS [0-9]+  FAIL [0-9]+|✗|^FAIL |Error:|waiting for" | head -6 | tr '\n' ' ')
  [ -z "$r" ] && r="NO RESULT (timed out at ${lim}s)"
  # (a suite can print several summaries: any that failed is flagged, however far down it is)
  echo "$full" | grep -qE "PASS [0-9]+ +FAIL [1-9]|^FAIL |✗" && r="!! FAILED: $r"
  printf "%-22s %s\n" "$t" "$r" | tee -a /tmp/regression.txt
done
