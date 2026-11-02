"""Summarize completed frame-stall runs without mixing pilots or nested timings."""
import argparse
from collections import defaultdict
import json
from pathlib import Path
import statistics

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {"setup", "warmup", "route_planning", "capture", "finish"}


def metrics(rows):
    values = sorted(r["wall_ms"] for r in rows)
    if not values:
        return {"frames": 0}
    return {"frames": len(values), "p50_ms": values[int((len(values)-1)*.5)],
            "p95_ms": values[int((len(values)-1)*.95)], "p99_ms": values[int((len(values)-1)*.99)],
            "max_ms": values[-1], "over_33_4": sum(v > 33.4 for v in values),
            "over_50": sum(v > 50 for v in values), "over_100": sum(v > 100 for v in values)}


def coverage(row):
    # Union the recorded intervals so inclusive parents/children count once.
    # Scope detail below 1 ms is omitted; residual includes that work too.
    intervals = []
    for span in row.get("spans_over_1ms", []):
        start = max(row["interval_start_usec"], span["start_usec"])
        end = min(row["interval_end_usec"], span["start_usec"] + span["ms"] * 1000)
        if end > start:
            intervals.append((start, end))
    merged = []
    for start, end in sorted(intervals):
        if merged and start <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    return sum(end - start for start, end in merged) / 1000


def analyze(destination):
    runs = []
    for path in sorted(destination.glob("*-run*/profile.json")):
        profile = json.loads(path.read_text(encoding="utf-8-sig"))
        process = json.loads((path.parent / "process.json").read_text(encoding="utf-8-sig"))
        valid = process["exit"] == 0 and not process["source_changed"] and not process.get("engine_errors") and not profile["failures"]
        frames = [r for r in profile["frames"] if not r["boundary"] and r["phase"] not in EXCLUDED]
        groups = defaultdict(list)
        scopes = defaultdict(list)
        for row in frames:
            groups[row["phase"]].append(row)
            for key, scope in row.get("scopes", {}).items():
                scopes[key].append(dict(wall_ms=scope["total_ms"], calls=scope["calls"], max_call_ms=scope["max_ms"], frame_wall_ms=row["wall_ms"]))
        slow = []
        for row in sorted(frames, key=lambda r: r["wall_ms"], reverse=True)[:30]:
            known = coverage(row) if profile["diagnostic"] else None
            slow.append({"frame": row["frame"], "phase": row["phase"], "wall_ms": row["wall_ms"], "cell": row["cell"],
                         "pending_detail": row["pending_detail"], "known_span_union_ms": known,
                         "residual_wall_ms": max(0, row["wall_ms"] - known) if known is not None else None,
                         "largest_scopes_inclusive": sorted(row.get("scopes", {}).items(), key=lambda pair: pair[1]["total_ms"], reverse=True)[:10],
                         "spans": row.get("spans_over_1ms", [])})
        scope_summary = {}
        for key, rows in scopes.items():
            scope_summary[key] = dict(metrics(rows), calls=sum(r["calls"] for r in rows),
                                      mean_calls_per_present_frame=statistics.mean(r["calls"] for r in rows),
                                      max_single_call_ms=max(r["max_call_ms"] for r in rows),
                                      mean_present_frame_ms=statistics.mean(r["wall_ms"] for r in rows))
        runs.append({"name": path.parent.name, "valid": valid, "failures": profile["failures"],
                     "startup_ms": profile["startup_ms"], "diagnostic": profile["diagnostic"],
                     "viewport": profile["viewport"], "adapter": profile["adapter"], "generation": profile["generation"],
                     "combat_clock": profile.get("combat_clock"), "combat_identity": profile.get("combat_identity"),
                     "peak_working_set_mib": process["peak_working_set"] / 1048576,
                     "peak_private_bytes_mib": process["peak_private_bytes"] / 1048576,
                     "engine_static_peak_mib": max(r["engine_static_bytes"] for r in frames) / 1048576,
                     "draw_calls_peak": max(r["draw_calls"] for r in frames),
                     "phases": {k: metrics(v) for k, v in sorted(groups.items())},
                     "scope_summary_inclusive": scope_summary, "slowest_frames": slow})
    (destination / "analysis.json").write_text(json.dumps(runs, indent=2), encoding="utf-8")
    lines = ["# Frame-stall baseline and attribution", "", "Only completed, unchanged-source, error-free runs with passing workload checks qualify.",
             "Scope times are inclusive. Residual wall time is unclassified: engine/render waits, OS scheduling, unwrapped work and omitted sub-millisecond spans can all contribute.", ""]
    baseline = [r for r in runs if r["valid"] and not r["diagnostic"]]
    diagnostic = [r for r in runs if r["valid"] and r["diagnostic"]]
    lines += ["Accepted baseline runs: **{}**. Accepted diagnostic runs: **{}**.".format(len(baseline), len(diagnostic)), "",
              "| Baseline phase | p50 range ms | p95 range ms | p99 range ms | Worst ms | Frames >50 ms |",
              "| --- | ---: | ---: | ---: | ---: | ---: |"]
    phases = sorted(set(p for r in baseline for p in r["phases"]))
    for phase in phases:
        rows = [r["phases"][phase] for r in baseline if phase in r["phases"]]
        def interval(key):
            return "{:.2f}–{:.2f}".format(min(r[key] for r in rows), max(r[key] for r in rows))
        lines.append("| {} | {} | {} | {} | {:.2f} | {} |".format(phase, interval("p50_ms"), interval("p95_ms"), interval("p99_ms"), max(r["max_ms"] for r in rows), sum(r["over_50"] for r in rows)))
    lines += ["", "## Diagnostic slowest frames", "", "| Run | Phase | Wall ms | Recorded scope union ms | Unclassified wall ms | Largest inclusive scope |", "| --- | --- | ---: | ---: | ---: | --- |"]
    for run in diagnostic:
        for row in run["slowest_frames"][:8]:
            largest = row["largest_scopes_inclusive"][0] if row["largest_scopes_inclusive"] else ["none", {"total_ms": 0}]
            lines.append("| {} | {} | {:.2f} | {:.2f} | {:.2f} | {} ({:.2f} ms) |".format(run["name"], row["phase"], row["wall_ms"], row["known_span_union_ms"], row["residual_wall_ms"], largest[0], largest[1]["total_ms"]))
    lines += ["", "See analysis.json for per-scope call counts, operation maxima, frame spans, memory and per-run results."]
    (destination / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("Accepted baselines: {}; diagnostics: {}. Report: {}".format(len(baseline), len(diagnostic), destination / "report.md"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("label")
    args = parser.parse_args()
    destination = (ROOT / "artifacts/frame-stalls" / args.label).resolve()
    if destination.parent != (ROOT / "artifacts/frame-stalls").resolve():
        parser.error("Expected a single study label")
    analyze(destination)
