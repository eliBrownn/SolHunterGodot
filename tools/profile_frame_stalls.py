"""Freeze the current runtime, run rendered baselines, and attribute frame stalls.

Only diagnostic copies receive timing wrappers. Production sources/settings and
the plant-palette fingerprint inputs are never modified. Windows, Python 3.8+.
"""
import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
GIT = r"C:\Program Files\Git\cmd\git.exe"
FOLDERS = ("scripts", "scenes", "resources", "shaders", "tools", "tests", "addons")
SCOPES = {
    "application/world.gd": ["_process", "advance_movement", "advance_environment", "prepare_flora", "plan_chunks", "publish_chunk", "inspect_mouse", "describe_cell"],
    "application/world_solid.gd": ["_process", "update_camera_pose", "sync_ground", "prepare_stream_chunk", "prepare_stream_ground", "publish_solid", "trim_detail_cache"],
    "persistence/expedition_state.gd": ["advance_time", "advance_environment", "advance_flora", "advance_flora_refill", "advance_vessels", "advance_ambient"],
    "sols/presentation/authored_sightings.gd": ["_process", "admit_nearby", "initialize_individuals", "rebuild", "sync_views", "advance_roaming", "build_local_entries"],
    "presentation/stream_chunk_job.gd": ["advance"],
    "presentation/solid_chunk.gd": ["build_cell_step", "finish_step"],
    "presentation/streaming_ground.gd": ["sync"],
    "presentation/vastra_currents.gd": ["_process", "refresh", "collect_living_anchors", "build_transfer_network", "sync_wisps", "update_optics"],
    "presentation/vastra_filament_renderer.gd": ["sync"],
    "presentation/atmosphere_controller.gd": ["update"],
    "presentation/player_visibility.gd": ["_process", "sync_source"],
    "presentation/plant_animation.gd": ["update"],
    "presentation/plant_reserve_view.gd": ["update"],
    "presentation/ground_reserve_view.gd": ["update"],
    "combat/battle_controller.gd": ["_process", "begin_battle", "ensure_movebooks", "update_view", "advance_resolution"],
}


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def hashes(base):
    paths = [base / "project.godot"]
    for folder in FOLDERS:
        paths.extend(p for p in (base / folder).rglob("*") if p.is_file() and p.suffix != ".pyc")
    return {p.relative_to(base).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}


def asset_inventory():
    # Assets/imports are shared read-only. Stat inventory detects edits during runs;
    # this is deliberately not presented as a full asset-content cryptographic hash.
    result = {}
    for folder in (ROOT / "assets", ROOT / ".godot/imported"):
        for p in folder.rglob("*"):
            if p.is_file():
                stat = p.stat()
                result[p.relative_to(ROOT).as_posix()] = [stat.st_size, stat.st_mtime_ns]
    return result


def junction(link, target):
    # Fixed absolute destinations under the new snapshot; no deletion/moving.
    command = "New-Item -ItemType Junction -Path '{}' -Target '{}' | Out-Null".format(
        str(link).replace("'", "''"), str(target).replace("'", "''"))
    subprocess.run(["powershell", "-NoProfile", "-Command", command], check=True, capture_output=True)


def freeze(destination):
    if destination.exists():
        raise RuntimeError("Snapshot already exists; use a fresh label")
    destination.mkdir(parents=True)
    (destination / ".gdignore").write_text("\n")
    shutil.copy2(ROOT / "project.godot", destination / "project.godot")
    for folder in FOLDERS:
        shutil.copytree(ROOT / folder, destination / folder, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    junction(destination / "assets", ROOT / "assets")
    cache = destination / ".godot"
    cache.mkdir()
    for name in ("global_script_class_cache.cfg", "uid_cache.bin"):
        shutil.copy2(ROOT / ".godot" / name, cache / name)
    junction(cache / "imported", ROOT / ".godot/imported")


def parameters(text):
    depth, quote, start, parts = 0, "", 0, []
    for i, c in enumerate(text):
        if quote:
            if c == quote and (i == 0 or text[i - 1] != "\\"): quote = ""
        elif c in "\"'": quote = c
        elif c in "([{": depth += 1
        elif c in ")]}": depth -= 1
        elif c == "," and depth == 0:
            parts.append(text[start:i]); start = i + 1
    parts.append(text[start:])
    return [re.match(r"\s*(\w+)", p).group(1) for p in parts if p.strip()]


def instrument(base):
    receipt = []
    scopes = {key: list(value) for key, value in SCOPES.items()}
    for path in (base / "scripts").rglob("*.gd"):
        source = path.read_text(encoding="utf-8-sig")
        relative = path.relative_to(base / "scripts").as_posix()
        for name in ("_process", "_physics_process"):
            if re.search(r"^func " + name + r"\(", source, re.M) and name not in scopes.get(relative, []):
                scopes.setdefault(relative, []).append(name)
    for relative, names in scopes.items():
        path = base / "scripts" / relative
        source = path.read_text(encoding="utf-8-sig")
        found = []
        for name in names:
            if re.search(r"func __stall_original_(?:[0-9a-f]{8}_)?" + re.escape(name) + r"\(", source):
                continue
            pattern = re.compile(r"^(static )?func " + re.escape(name) + r"\((.*)\)([ \t]*->[ \t]*[^:\n]+)?:[ \t]*$", re.M)
            matches = list(pattern.finditer(source))
            if not matches:
                receipt.append({"path": relative, "function": name, "status": "absent"})
                continue
            if len(matches) != 1: raise RuntimeError("Ambiguous function " + name)
            match = matches[0]
            static, params, returns = match.group(1) or "", match.group(2), match.group(3) or ""
            args = ", ".join(parameters(params))
            # Unique names preserve virtual dispatch when child and parent
            # callbacks are both wrapped (for example the audio hierarchy).
            original = "__stall_original_" + hashlib.sha1(relative.encode()).hexdigest()[:8] + "_" + name
            call = original + "(" + args + ")"
            void = returns.strip() == "-> void"
            key = relative.replace(".gd", "") + "." + name
            trace = "STALL_TRACE_" + hashlib.sha1(relative.encode()).hexdigest()[:8]
            wrapper = static + "func " + name + "(" + params + ")" + returns + ":\n"
            wrapper += "\tif not " + trace + ".enabled:\n\t\t" + (call + "\n\t\treturn" if void else "return " + call) + "\n"
            wrapper += "\tvar __stall_started := " + trace + ".enter()\n"
            wrapper += "\t" + (call if void else "var __stall_result = " + call) + "\n"
            wrapper += '\t' + trace + '.leave("' + key + '", __stall_started)\n'
            if not void: wrapper += "\treturn __stall_result\n"
            wrapper += "\n" + static + "func " + original + "(" + params + ")" + returns + ":\n"
            source = source[:match.start()] + wrapper + source[match.end():]
            found.append(name)
            receipt.append({"path": relative, "function": name, "original_function": original, "status": "wrapped", "inclusive": True})
        if found:
            source = re.sub(r"^(extends .+)$", r'\1\nconst '+trace+' = preload("res://tools/stall_probe.gd")', source, count=1, flags=re.M)
            path.write_text(source, encoding="utf-8")
    return receipt


class MemoryCounters(ctypes.Structure):
    _fields_ = [("cb", ctypes.c_ulong), ("PageFaultCount", ctypes.c_ulong)] + [
        (name, ctypes.c_size_t) for name in ("PeakWorkingSetSize", "WorkingSetSize", "QuotaPeakPagedPoolUsage",
        "QuotaPagedPoolUsage", "QuotaPeakNonPagedPoolUsage", "QuotaNonPagedPoolUsage", "PagefileUsage", "PeakPagefileUsage", "PrivateUsage")]


def memory(process):
    counters = MemoryCounters()
    counters.cb = ctypes.sizeof(counters)
    success = ctypes.windll.psapi.GetProcessMemoryInfo(ctypes.c_void_p(int(process._handle)), ctypes.byref(counters), counters.cb)
    return {"working_set": counters.WorkingSetSize, "private_bytes": counters.PrivateUsage} if success else {}


def metrics(rows):
    values = sorted(row["wall_ms"] for row in rows)
    if not values: return {"frames": 0}
    return dict(frames=len(values), p50_ms=values[int((len(values)-1)*.5)],
                p95_ms=values[int((len(values)-1)*.95)], p99_ms=values[int((len(values)-1)*.99)],
                max_ms=values[-1], over_33_4=sum(v > 33.4 for v in values), over_50=sum(v > 50 for v in values),
                over_100=sum(v > 100 for v in values))


def summarize(destination):
    summaries = []
    for profile in sorted(destination.glob("*-run*/profile.json")):
        report = json.loads(profile.read_text(encoding="utf-8-sig"))
        frames = [r for r in report["frames"] if not r["boundary"]]
        phases = sorted(set(r["phase"] for r in frames))
        excluded = {"setup", "route_planning", "capture", "finish", "warmup"}
        workload = [r for r in frames if r["phase"] not in excluded]
        slow = sorted(workload, key=lambda r: r["wall_ms"], reverse=True)[:30]
        summaries.append({"run": profile.parent.name, "startup_ms": report["startup_ms"],
                          "failures": report["failures"], "viewport": report["viewport"],
                          "phases": {p: metrics([r for r in frames if r["phase"] == p]) for p in phases},
                          "workload": metrics(workload), "slowest_workload_frames": slow,
                          "scope_calls": report["scope_calls"], "combat_clock": report.get("combat_clock")})
    write(destination / "summary.json", summaries)
    return summaries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--label", required=True)
    parser.add_argument("--mode", choices=["prepare", "baseline", "diagnostic", "all", "summarize"], default="all")
    parser.add_argument("--runs", type=int, default=3)
    parser.add_argument("--first-run", type=int, default=1)
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.label) or not 1 <= args.runs <= 5: parser.error("Invalid label/runs")
    destination = ROOT / "artifacts/frame-stalls" / args.label
    if args.mode == "summarize":
        summarize(destination); return
    console = Path(args.godot).resolve()
    version = subprocess.check_output([str(console), "--version"], text=True).strip()
    if not version.startswith("4.7.2.stable."): raise RuntimeError("Expected pinned Godot 4.7.2: " + version)
    engine = Path(str(console).replace("_console.exe", ".exe"))
    manifest_path = destination / "manifest.json"
    if not manifest_path.exists():
        destination.mkdir(parents=True, exist_ok=False)
        before = hashes(ROOT)
        assets = asset_inventory()
        freeze(destination / "baseline-runtime")
        freeze(destination / "diagnostic-runtime")
        receipt = instrument(destination / "diagnostic-runtime")
        manifest = {"engine": version, "branch": subprocess.check_output([GIT, "branch", "--show-current"], cwd=ROOT, text=True).strip(),
                    "source_before": before, "assets_before": assets, "instrumentation": receipt, "runs": [],
                    "policy": "Sequential fresh processes; retained OS/driver caches; fixed default viewport, cap60/vsync. Assets/imports shared with edit detection; runtime copied. Diagnostic timings inclusive, never summed across nesting."}
        manifest["baseline_hashes"] = hashes(destination / "baseline-runtime")
        manifest["diagnostic_hashes"] = hashes(destination / "diagnostic-runtime")
        write(manifest_path, manifest)
        print("Prepared snapshots: " + str(destination), flush=True)
    else: manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if args.mode == "prepare": return
    modes = ["baseline", "diagnostic"] if args.mode == "all" else [args.mode]
    for mode in modes:
        for iteration in range(args.first_run, args.first_run + args.runs):
            name = "{}-run{}".format(mode, iteration)
            output = destination / name
            if output.exists(): raise RuntimeError("Refusing to overwrite " + str(output))
            output.mkdir()
            base = destination / (mode + "-runtime")
            before = hashes(base)
            if before != manifest[mode + "_hashes"]: raise RuntimeError("Frozen runtime drift before " + name)
            write(output / "source_before.json", before)
            env = os.environ.copy()
            env["APPDATA"] = str(output / "appdata")
            env["LOCALAPPDATA"] = str(output / "localdata")
            for key in ("APPDATA", "LOCALAPPDATA"): Path(env[key]).mkdir()
            command = [str(engine), "--path", str(base), "--rendering-driver", "d3d12", "--script", "tools/profile_frame_stalls.gd", "--", "--output=" + output.as_posix()]
            if mode == "diagnostic": command.append("--diagnostic")
            startup = subprocess.STARTUPINFO()
            startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startup.wShowWindow = 0
            samples, started = [], time.monotonic()
            print("Starting " + name, flush=True)
            with (output / "stdout.log").open("w") as out, (output / "stderr.log").open("w") as err:
                process = subprocess.Popen(command, cwd=base, env=env, stdout=out, stderr=err, startupinfo=startup)
                write(output / "launch.json", {"launcher_pid": os.getpid(), "engine_pid": process.pid, "command": command})
                while process.poll() is None:
                    samples.append(dict(seconds=time.monotonic()-started, **memory(process)))
                    if time.monotonic()-started > 480:
                        process.kill(); process.wait(); raise RuntimeError("Timeout " + name)
                    time.sleep(.2)
            entry = {"name": name, "command": command, "exit": process.returncode, "seconds": time.monotonic()-started,
                     "source_changed": before != hashes(base), "peak_working_set": max((s.get("working_set", 0) for s in samples), default=0),
                     "peak_private_bytes": max((s.get("private_bytes", 0) for s in samples), default=0)}
            write(output / "source_after.json", hashes(base))
            entry["profile_completed"] = (output / "profile.json").is_file()
            errors = re.findall(r"^(?:SCRIPT ERROR|ERROR):.*$", (output / "stderr.log").read_text(encoding="utf-8", errors="replace"), re.M)
            entry["engine_error_count"] = len(errors)
            entry["engine_errors"] = list(dict.fromkeys(errors))[:20]
            write(output / "process.json", dict(entry, samples=samples))
            manifest["runs"].append(entry)
            write(manifest_path, manifest)
            print(json.dumps(entry), flush=True)
            if process.returncode != 0 or entry["source_changed"] or not entry["profile_completed"] or entry["engine_errors"]:
                raise RuntimeError("Run failed or incomplete; inspect " + str(output))
    manifest["active_source_changed"] = manifest["source_before"] != hashes(ROOT)
    manifest["shared_assets_changed"] = manifest["assets_before"] != asset_inventory()
    write(manifest_path, manifest)
    summarize(destination)


if __name__ == "__main__":
    main()
