"""Incremental isolated ecosystem reference capture; never publishes game assets.

Run with Python and the pinned Godot 4.7.2 stable console executable. Existing
Plants HTML images remain untouched. Fingerprints determine capture reuse.
"""
import argparse
import hashlib
import json
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "artifacts/ecosystem-review"


def hashes(paths):
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(set(paths)) if p.is_file()}


def run(engine):
    OUT.mkdir(parents=True, exist_ok=True)
    version = subprocess.check_output([engine, "--version"], text=True).strip()
    if not version.startswith("4.7.2.stable."):
        raise ValueError("Use the pinned Godot 4.7.2 stable engine.")
    shared = [ROOT / "tools/capture_ecosystem.gd", ROOT / "tools/photograph_ecosystem.py"]
    shared += list((ROOT / "scripts/scenery").glob("*.gd"))
    shared += list((ROOT / "scripts/presentation").glob("*.gd"))
    shared += list((ROOT / "shaders").glob("*gdshader*"))
    common = hashes(shared)
    registry = json.loads((ROOT / "docs/reference/plant_review_registry.json").read_text(encoding="utf-8"))
    archive = {r["plant_id"]: r for r in registry["roster"]}
    jobs = []
    for path in sorted((ROOT / "resources/plants/runtime_palette").glob("*.res")):
        row = archive.get(path.stem)
        if row is None:
            raise ValueError("No reference identity for " + path.stem)
        jobs.append({"code": row["code"], "name": row["name"], "biome": row["biome"],
                     "status": row["status"] + " / current runtime definition", "kind": "plant",
                     "path": "res://" + path.relative_to(ROOT).as_posix(),
                     "source_hashes": {**common, **hashes([path, ROOT / "resources/plants/runtime_palette/manifest.json"])}})
    modeled_ids = {Path(r["path"]).stem for r in jobs}
    library = ROOT / "resources/plants/library.json"
    for location in json.loads(library.read_text(encoding="utf-8"))["plants"]:
        path = ROOT / location[len("res://"):]
        text = path.read_text(encoding="utf-8")
        identity = re.search(r'plant_id = "([^"]+)"', text)[1]
        row = archive.get(identity)
        if identity in modeled_ids or row is None:
            continue
        jobs.append({"code": row["code"], "name": row["name"], "biome": row["biome"],
                     "status": "Currently selected authored plant library definition", "kind": "plant", "path": location,
                     "source_hashes": {**common, **hashes([library] + list(path.parent.rglob("*")))}})
        modeled_ids.add(identity)
    for identity, row in archive.items():
        if identity in modeled_ids:
            continue
        jobs.append({"code": row["code"], "name": row["name"], "biome": row["biome"],
                     "status": "Retained unclassed receiver anatomy study; excluded from live palette",
                     "kind": "plant_study", "design": identity, "path": "res://resources/plants/official_catalog.json",
                     "source_hashes": {**common, **hashes([ROOT / "resources/plants/official_catalog.json"])}})
    # The retained imported reference library is part of the ecology art evidence;
    # three selected shapes are live class appearances, the others remain studies.
    for index in range(1, 21):
        path = ROOT / f"assets/local/tropical_plants/Fbx/Tropical_plant_{index:03d}.fbx"
        if not path.exists():
            continue
        role = {19: "Warden", 15: "Mender", 17: "Regulator"}.get(index)
        dependencies = [path, Path(str(path) + ".import"), ROOT / "resources/vegetation_appearance.tres",
                        ROOT / "assets/local/tropical_plants/Textures/T_Tropical_plants.png"]
        imported = Path(str(path) + ".import")
        if imported.exists():
            dependencies += [ROOT / p[len("res://"):] for p in re.findall(r'res://[^"\n]+', imported.read_text(encoding="utf-8"))]
        jobs.append({"code": f"VEG{index:03d}", "name": (role + " selected class reference") if role else f"Retained vegetation study {index:03d}",
                     "biome": "Specialist references", "status": "Selected class appearance" if role else "Historical/provisional art reference; not new world admission",
                     "kind": "imported", "path": "res://" + path.relative_to(ROOT).as_posix(),
                     "source_hashes": {**common, **hashes(dependencies)}})
    for code, name, members, anger in [("VES01", "Vessel — isolated calm individual", 1, 0),
                                       ("VES02", "Vessel — isolated instability presentation", 1, 1),
                                       ("VES03", "Vessels — isolated 24-member swarm", 24, 0)]:
        jobs.append({"code": code, "name": name, "biome": "Vessels", "status": "Current particle presentation; synthetic pose, not ecological state",
                     "kind": "vessel", "members": members, "anger": anger, "source_hashes": common})
    # Habitat inhabitants: current catalog bodies rather than newly invented fauna.
    sol_catalog = ROOT / "resources/sol_species/catalog.tres"
    sol_paths = re.findall(r'path="res://(resources/sol_species/[^\"]+\.tres)"', sol_catalog.read_text(encoding="utf-8"))
    sol_common = hashes(list((ROOT / "scripts/sols/presentation").glob("*.gd")) + list((ROOT / "scenes/sols").glob("*.tscn")) + list((ROOT / "resources/sol_species").glob("*.tres")) + [ROOT / "resources/sol_visual_settings.tres"])
    for index, path in enumerate(sol_paths):
        text = (ROOT / path).read_text(encoding="utf-8")
        name = re.search(r'display_name = "([^"]+)"', text)
        jobs.append({"code": f"SOL{index + 1:02d}", "name": name[1] if name else Path(path).stem,
                     "biome": "Habitat Sols", "status": "Current catalog body; neutral affinity; provisional species art",
                     "kind": "sol", "path": "res://" + path, "source_hashes": {**common, **sol_common}})
    jobs.append({"code": "CONCEPT01", "name": "Bellroot — isolated first-form concept",
                 "biome": "Habitat Sols", "status": "Separate visual prototype; does not replace the catalog Bellroot",
                 "kind": "concept", "path": "res://scripts/sols/presentation/bellroot_concept.gd",
                 "source_hashes": {**common, **sol_common}})
    old_file = OUT / "manifest.json"
    old = {r["code"]: r for r in json.loads(old_file.read_text(encoding="utf-8"))["items"]} if old_file.exists() else {}
    pending = [r for r in jobs if r["code"] not in old or old[r["code"]]["source_hashes"] != r["source_hashes"]
               or not all((OUT / p).is_file() for p in old[r["code"]]["views"])]
    (OUT / "jobs.json").write_text(json.dumps(pending, indent=2), encoding="utf-8")
    print(f"Inventory: {len(jobs)} modeled references, {len(pending)} missing/unverified or changed; {len(jobs)-len(pending)} fingerprint-matched captures reused.", flush=True)
    if pending:
        environment = os.environ.copy()
        for name, folder in [("APPDATA", "profile"), ("LOCALAPPDATA", "local-profile")]:
            destination = OUT / folder
            destination.mkdir(exist_ok=True)
            environment[name] = str(destination)
        with (OUT / "capture.log").open("w", encoding="utf-8") as log:
            result = subprocess.run([engine, "--path", str(ROOT), "--log-file", str(OUT / "engine.log"), "--rendering-driver", "d3d12", "--script", "res://tools/capture_ecosystem.gd"], cwd=ROOT, env=environment, stdout=log, stderr=subprocess.STDOUT, timeout=1800)
        output = (OUT / "capture.log").read_text(encoding="utf-8", errors="replace")
        if result.returncode or re.search(r"^(SCRIPT ERROR|ERROR):", output, re.M):
            raise RuntimeError(f"Capture failed, exit {result.returncode}. See {OUT / 'capture.log'}")
    # Detect any input drift before presenting photographs as current.
    all_inputs = {p: h for r in jobs for p, h in r["source_hashes"].items()}
    changed = [p for p, h in all_inputs.items() if not (ROOT / p).is_file() or hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != h]
    if changed:
        raise RuntimeError("Capture source drift; rerun after changes settle: " + ", ".join(changed))
    timestamp = datetime.now().astimezone().isoformat(timespec="seconds")
    pending_codes = {r["code"] for r in pending}
    from PIL import Image, ImageChops
    items = []
    for row in jobs:
        views = [row["code"] + "-0.png", row["code"] + "-1.png"]
        for view in views:
            with Image.open(OUT / view) as picture:
                picture.verify()
            with Image.open(OUT / view) as picture:
                picture = picture.convert("RGB")
                background = Image.new("RGB", picture.size, picture.getpixel((0, 0)))
                difference = ImageChops.difference(picture, background)
                if difference.getbbox() is None:
                    raise ValueError("Blank capture " + view)
        items.append({**row, "views": views, "image_hashes": {p: hashlib.sha256((OUT / p).read_bytes()).hexdigest() for p in views},
                      "captured": timestamp if row["code"] in pending_codes else old[row["code"]]["captured"]})
    coverage = {"schema": 1, "engine": version, "captured": timestamp, "camera": "isolated front/rear three-quarter; independently framed, not shared scale",
                "items": items, "reused": len(jobs)-len(pending), "new_or_refreshed": len(pending),
                "archive_only": [r for r in registry["roster"] if r["code"] not in {j["code"] for j in jobs}],
                "excluded_from_live_palette": [r["code"] for r in jobs if r["kind"] == "plant_study"],
                "text_only_unmodeled": ["Fruit/flower lifecycle artwork", "Plant aging/death/replacement variants", "Distant ecology service (behavior, no standalone object)", "Retired aquatic/bank replacement artwork"]}
    old_file.write_text(json.dumps(coverage, indent=2), encoding="utf-8")
    print(f"Verified {len(items)*2} isolated pictures; coverage saved. Original Plants review and runtime resources unchanged.", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    run(args.godot)
