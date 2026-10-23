#!/bin/bash
# guides.sh: converts every guide that is newer than its page (build.py refuses a stale one).
cd "$(dirname "$0")"
conv(){ # md html [options]
  if [ ! -f "$2" ] || [ "$1" -nt "$2" ]; then pandoc $3 "$1" -o "$2" && echo "converted $1"; fi
}
conv handbook_v14-0.md handbook.html
conv changelog.md changelog.html --wrap=none
conv datapad_guide.md datapad_guide.html --wrap=none
for g in whatsnew simulator_guide forge_guide poi_guide deck_guide studio_guide loot_guide workshop_guide world_guide dock_guide; do conv $g.md $g.html; done
