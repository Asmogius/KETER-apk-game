#!/usr/bin/env python3
"""The balance lab (not a test): a stand-in player plays many real fights on
the content the game ships with, and this gathers how they went.

  python3 balance_lab.py run  [--n 60] [--jobs 4] [--out DIR]   play the grid
  python3 balance_lab.py sum  [--out DIR]                       gather it into summary.json
  python3 balance_lab.py run --grid focus --tune notest,mix --out DIR   a what-if, on the cells it matters to
  python3 balance_lab.py run-camp [--runs 8] [--bots careful,casual] [--most 150] --out DIR   whole campaigns (lab_campaign.gd)
  python3 balance_lab.py sum-camp --out DIR                     gather them into camp_summary.json

The grid: Skull Level 1-6, each an ambush, a POI (its floors in a row) and a
District Core (three floors), for the careful player and the casual one
(game/tests/lab_fights.gd says how each plays). Each cell is played in parts
with seeds of their own, so that the parts can run side by side. The export is
the one the game ships with (make_game.built_in_export), made once."""
import argparse
import concurrent.futures as cf
import json
import os
import pathlib
import statistics
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent
GAME = ROOT / "game"
GODOT = os.environ.get("GODOT", "/home/claude/tools/Godot_v4.7.2-stable_linux.x86_64")
SKULLS = [1, 2, 3, 4, 5, 6]
KINDS = ["ambush", "poi", "core"]
BOTS = ["careful", "casual"]
# What we aim for (agreed before the lab was built): the careful player's
# chance to clear a fight, by Skull Level; a Core; a fight's length in rounds.
TARGETS = {"careful": {1: 0.90, 2: 0.90, 3: 0.75, 4: 0.75, 5: 0.60, 6: 0.60}, "core": 0.45, "rounds": [5, 9]}
PART = 10           # runs in one Godot process


def export_path(out):
    p = out / "builtin.zip"
    if not p.exists():
        sys.path.insert(0, str(ROOT))
        import make_game
        make_game.built_in_export(str(p))
    return p


def cells(extra=True, grid="full"):
    # every District Core sits at Skull 6 (the farthest tile from the dock): a Core is played at 5 and 6
    cell = lambda s, k, b, inst=0, stage="", d="3": {"skull": s, "kind": k, "bot": b, "inst": inst, "stage": stage, "district": d}
    out = [cell(s, k, b) for s in SKULLS for k in KINDS for b in BOTS if k != "core" or s >= 5]
    if grid == "focus":
        # where the curve breaks: the careful player from Skull 3 up
        return [c for c in out if c["bot"] == "careful" and c["skull"] >= 3]
    if grid == "tuned":
        # the main grid, and District 1 (its floors drawn from the whole floors)
        return out + [cell(s, "poi", "careful", 0, "", "1") for s in SKULLS] + [cell(6, "core", "careful", 0, "", "1")]
    if extra:
        # Instability at its most (five Districts cleared), where it bites
        out += [cell(s, k, "careful", 15) for s in (4, 5, 6) for k in ("poi", "core") if k != "core" or s >= 5]
        # a team a step behind (or ahead) of where the Skull Level expects it
        out += [cell(s, "poi", "careful", 0, st) for s, st in ((3, "starter"), (4, "starter"), (5, "mid"), (6, "mid"), (3, "late"), (4, "late"), (5, "late2"), (6, "late2"))]
        # District 1 (as 2, 4, 5 and 6): no chunks of its own, so its fights are drawn from the whole floors
        out += [cell(s, k, "careful", 0, "", "1") for s in SKULLS for k in ("ambush", "poi")] + [cell(6, "core", "careful", 0, "", "1")]
    return out


def cell_name(c):
    return "d%s_s%d_%s_%s_i%d_%s" % (c["district"], c["skull"], c["kind"], c["bot"], c["inst"], c["stage"] or "auto")


def play(job):
    c, part, n, exp, out, tune = job
    f = out / "runs" / ("%s_p%02d.jsonl" % (cell_name(c), part))
    if f.exists() and f.stat().st_size > 0:
        return str(f), 0
    f.parent.mkdir(parents=True, exist_ok=True)
    seed = 1000 * part + 7 * c["skull"] + KINDS.index(c["kind"]) * 31 + BOTS.index(c["bot"]) * 101 + c["inst"] + 503 * int(c["district"])
    args = [GODOT, "--headless", "--path", str(GAME), "--script", "res://tests/lab_fights.gd", "--",
            "export=%s" % exp, "skull=%d" % c["skull"], "kind=%s" % c["kind"], "bot=%s" % c["bot"],
            "n=%d" % n, "seed=%d" % seed, "inst=%d" % c["inst"], "district=%s" % c["district"], "out=%s" % f]
    if c["stage"]:
        args.append("stage=%s" % c["stage"])
    if tune:
        args.append("tune=%s" % tune)
    r = subprocess.run(args, capture_output=True, text=True, timeout=3600)
    if r.returncode != 0 or not f.exists():
        sys.stderr.write("%s part %d failed:\n%s\n" % (cell_name(c), part, (r.stdout + r.stderr)[-2000:]))
        return str(f), 1
    return str(f), 0


def run(a):
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    exp = export_path(out)
    parts = max(1, a.n // PART)
    jobs = [(c, p, PART, exp, out, a.tune) for c in cells(not a.core_grid, a.grid) for p in range(parts)]
    # the slowest first, so that the last to finish isn't a long one alone
    jobs.sort(key=lambda j: -(j[0]["skull"] * (3 if j[0]["kind"] == "core" else (2 if j[0]["kind"] == "poi" else 1))))
    bad = 0
    done = 0
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        for _, err in ex.map(play, jobs):
            bad += err
            done += 1
            if done % 20 == 0 or done == len(jobs):
                print("%d/%d parts" % (done, len(jobs)), flush=True)
    print("failed parts:", bad)
    return 1 if bad else 0


def pct(xs, q):
    xs = sorted(xs)
    if not xs:
        return None
    return xs[min(len(xs) - 1, int(q * len(xs)))]


def sum_cell(rows):
    fights = [f for r in rows for f in r["fight"]]
    won_f = [f for f in fights if f["won"]]
    first = [r["fight"][0] for r in rows if r["fight"]]
    rounds_won = [f["rounds"] for f in won_f]
    return {
        "runs": len(rows),
        "fights_n": len(fights),
        "clear": sum(r["won"] for r in rows) / max(1, len(rows)),
        "first_try": sum(1 for r in rows if r["won"] and r["retries"] == 0) / max(1, len(rows)),
        "fight_win": len(won_f) / max(1, len(fights)),
        "first_fight_win": sum(f["won"] for f in first) / max(1, len(first)),
        "stall": sum(1 for f in fights if not f["over"]) / max(1, len(fights)),
        "rounds_med": statistics.median(rounds_won) if rounds_won else None,
        "rounds_p25": pct(rounds_won, 0.25), "rounds_p75": pct(rounds_won, 0.75),
        "in_target": sum(1 for x in rounds_won if TARGETS["rounds"][0] <= x <= TARGETS["rounds"][1]) / max(1, len(rounds_won)),
        "retries": statistics.mean(r["retries"] for r in rows) if rows else 0,
        "heroes_down": statistics.mean(r["heroes_down"] for r in rows) if rows else 0,
        "hp_won": statistics.mean(f["hp"] for f in won_f) if won_f else None,
        "foes": statistics.mean(f["foes"] for f in fights) if fights else 0,
        "elite": statistics.mean(f["elite"] for f in fights) if fights else 0,
        "played": statistics.mean(f["played"] for f in fights) if fights else 0,
        "deck_dry": sum(1 for f in fights if f["deck_left"] == 0 and f["hand_left"] == 0) / max(1, len(fights)),
        "floors": statistics.mean(r["floors"] for r in rows) if rows else 0,
        "errors": sum(1 for r in rows if r.get("error")),
    }


def summarise(a):
    out = pathlib.Path(a.out)
    res = []
    for c in cells(True, a.grid):
        rows = []
        for f in sorted((out / "runs").glob(cell_name(c) + "_p*.jsonl")):
            rows += [json.loads(l) for l in f.read_text().splitlines() if l.strip()]
        if not rows:
            continue
        res.append(dict(c, **sum_cell(rows)))
    (out / "summary.json").write_text(json.dumps({"targets": TARGETS, "cells": res}, indent=1))
    for r in res:
        print("%-38s runs %4d  clear %3.0f%%  1st fight %3.0f%%  fight %3.0f%%  stall %3.0f%%  rounds %s (%s-%s)  down %.1f" % (
            cell_name(r), r["runs"], 100 * r["clear"], 100 * r["first_fight_win"], 100 * r["fight_win"], 100 * r["stall"],
            r["rounds_med"], r["rounds_p25"], r["rounds_p75"], r["heroes_down"]))
    return 0


# ---------------------------------------------------------------- campaigns
# What we aim for (agreed before the lab was built): the careful player clears
# its first District in 15-25 deployments, and all six in 60-100.
CAMP_TARGETS = {"first": [15, 25], "all": [60, 100]}


def play_camp(job):
    bot, seed, most, exp, out, extra = job
    f = out / "camps" / ("%s_s%03d.jsonl" % (bot, seed))
    if f.exists() and any(json.loads(l).get("summary") for l in f.read_text().splitlines() if l.strip()):
        return str(f), 0
    f.parent.mkdir(parents=True, exist_ok=True)
    args = [GODOT, "--headless", "--path", str(GAME), "--script", "res://tests/lab_campaign.gd", "--",
            "export=%s" % exp, "bot=%s" % bot, "seed=%d" % seed, "most=%d" % most, "out=%s" % f] + [x for x in extra.split(",") if x]
    r = subprocess.run(args, capture_output=True, text=True, timeout=6 * 3600)
    if r.returncode != 0:
        sys.stderr.write("%s seed %d failed:\n%s\n" % (bot, seed, (r.stdout + r.stderr)[-2000:]))
        return str(f), 1
    return str(f), 0


def run_camp(a):
    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    exp = export_path(out)
    jobs = [(b, s, a.most, exp, out, a.camp) for b in a.bots.split(",") for s in range(1, a.runs + 1)]
    bad = 0
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        for i, (_, err) in enumerate(ex.map(play_camp, jobs)):
            bad += err
            print("%d/%d campaigns" % (i + 1, len(jobs)), flush=True)
    print("failed campaigns:", bad)
    return 1 if bad else 0


def sum_camp(a):
    out = pathlib.Path(a.out)
    runs, deps = [], []
    for f in sorted((out / "camps").glob("*.jsonl")):
        rows = [json.loads(l) for l in f.read_text().splitlines() if l.strip()]
        summ = [r for r in rows if r.get("summary")]
        if not summ:
            continue
        runs.append(summ[0])
        deps += [dict(r, bot=summ[0]["bot"], seed=summ[0]["seed"]) for r in rows if not r.get("summary")]
    by_bot = {}
    for b in sorted({r["bot"] for r in runs}):
        rs = [r for r in runs if r["bot"] == b]
        ds = [d for d in deps if d["bot"] == b and not d.get("error")]
        firsts = [r["first_district"] for r in rs if r["first_district"]]
        alls = [r["all_districts"] for r in rs if r["all_districts"]]
        most = max(r["deployments"] for r in rs)
        by_bot[b] = {
            "runs": len(rs), "most": most,
            "first_med": statistics.median(firsts) if firsts else None, "first_n": len(firsts),
            "all_med": statistics.median(alls) if alls else None, "all_n": len(alls),
            "wipe_rate": sum(1 for d in ds if d["result"] == "wipe") / max(1, len(ds)),
            "rank_at": {k: statistics.median([r["rank_at"][k] for r in rs if k in r["rank_at"]]) for k in ["2", "3", "4", "5", "6"] if any(k in r["rank_at"] for r in rs)},
            "comfort_at": {k: statistics.median([r["comfort_at"][k] for r in rs if k in r["comfort_at"]]) for k in ["1", "2", "3", "4", "5", "6"] if any(k in r["comfort_at"] for r in rs)},
            "districts_final": [r["final"]["districts"] for r in rs],
            "errors": [r["error"] for r in rs if r.get("error")],
        }
    (out / "camp_summary.json").write_text(json.dumps({"targets": CAMP_TARGETS, "by_bot": by_bot, "runs": runs}, indent=1))
    (out / "camp_deployments.json").write_text(json.dumps(deps))
    for b, v in by_bot.items():
        print(b, json.dumps(v))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("what", choices=["run", "sum", "run-camp", "sum-camp"])
    ap.add_argument("--n", type=int, default=60, help="runs a cell")
    ap.add_argument("--jobs", type=int, default=os.cpu_count() or 2)
    ap.add_argument("--out", default=str(ROOT / "lab_out"))
    ap.add_argument("--core-grid", action="store_true", help="only the main grid, without the extra cells")
    ap.add_argument("--grid", default="full", choices=["full", "focus", "tuned"], help="which cells: all, the careful player from Skull 3, or the main grid and District 1")
    ap.add_argument("--tune", default="", help="what-if switches for lab_fights.gd's tune= (the game is untouched)")
    ap.add_argument("--runs", type=int, default=8, help="campaigns a player")
    ap.add_argument("--bots", default="careful,casual", help="which players play campaigns")
    ap.add_argument("--most", type=int, default=150, help="deployments a campaign at most")
    ap.add_argument("--camp", default="", help="what-if switches for lab_campaign.gd, key=value,key=value (d3floors=1)")
    a = ap.parse_args()
    sys.exit({"run": run, "sum": summarise, "run-camp": run_camp, "sum-camp": sum_camp}[a.what](a))


if __name__ == "__main__":
    main()
