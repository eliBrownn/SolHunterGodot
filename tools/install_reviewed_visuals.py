"""Install owner-approved art from the three supplied ZIPs; grass remains local."""
import hashlib
import json
import re
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path.home() / "Downloads"
PACKS = [
    ("Environment_Assets_-_Foliage_Sample_Pack-2.zip", "foliage"),
    ("Environment_Assets_-_Rocks_Sample_Pack.zip", "rocks"),
    ("EmacEArtStylizedGrass_Godot_2026-09-01_v1.3.0.zip", "grass"),
]
records = []
for filename, group in PACKS:
    source = DOWNLOADS / filename
    records.append({"archive": filename, "sha256": hashlib.sha256(source.read_bytes()).hexdigest()})
    prefix = "assets/local/emace_grass" if group == "grass" else "assets/nature_samples/" + group
    with zipfile.ZipFile(source) as archive:
        for entry in archive.infolist():
            path = PurePosixPath(entry.filename)
            if group == "grass":
                path = PurePosixPath(*path.parts[1:])
            if not path.parts or entry.is_dir() or ".." in path.parts or path.is_absolute():
                continue
            if path.name != "LICENSE.txt" and path.parts[0] not in ("Textures", "Materials", "Scenes", "Meshes", "Shaders"):
                continue
            if path.suffix not in (".txt", ".png", ".tga", ".tres", ".tscn", ".mesh", ".gdshader"):
                continue
            if path.parts[0] == "Scenes" and (group == "grass" or path.name == "Asset DEMO.tscn"):
                continue
            data = archive.read(entry)
            if path.suffix in (".tres", ".tscn", ".gdshader"):
                old = {"foliage": "res://Foliage Sample Pack/", "rocks": "res://Rocks Sample Pack/", "grass": "res://"}[group]
                content = data.decode("utf-8-sig").replace(old, "res://" + prefix + "/")
                data = re.sub(r' uid="uid://[^\"]+"', "", content).encode("utf-8")
            target = ROOT / prefix / str(path)
            if path.parts[0] == "Scenes":
                target = ROOT / "artifacts/visual_install" / group / path.name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
destination = ROOT / "assets/nature_samples/provenance.json"
destination.write_text(json.dumps(records, indent=2))
print("Installed MIT textures/materials and local-only grass; run tools/bake_reviewed_nature.gd next.")
