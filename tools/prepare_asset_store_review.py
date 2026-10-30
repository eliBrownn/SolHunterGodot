"""Prepare a local-only art comparison; never add proprietary pack files to Git."""
import argparse
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "artifacts/asset_store_review"
PACKS = [
    ("EmacEArtStylizedGrass_Godot_2026-09-01_v1.3.0.zip", "grass"),
    ("Environment_Assets_-_Foliage_Sample_Pack-2.zip", "foliage"),
    ("Environment_Assets_-_Rocks_Sample_Pack.zip", "rocks"),
]


def prepare(downloads):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    evidence = []
    for filename, group in PACKS:
        archive = downloads / filename
        evidence.append({"archive": filename, "sha256": hashlib.sha256(archive.read_bytes()).hexdigest()})
        with zipfile.ZipFile(archive) as pack:
            for entry in pack.infolist():
                relative = PurePosixPath(entry.filename)
                if group == "grass":
                    relative = PurePosixPath(*relative.parts[1:])
                if not relative.parts or entry.is_dir():
                    continue
                # Vendor demo code and FBX sources are unnecessary: sample scenes
                # contain their own meshes. Preserve licenses and runtime art.
                if relative.parts[0] not in ("Materials", "Textures", "Scenes", "Shaders", "Meshes") and relative.name != "LICENSE.txt":
                    continue
                if relative.suffix not in (".tres", ".tscn", ".gdshader", ".mesh", ".png", ".tga", ".txt"):
                    continue
                if group == "grass" and relative.parts[0] == "Scenes":
                    continue
                target = OUTPUT / "vendor" / group / str(relative)
                if OUTPUT.resolve() not in target.resolve().parents:
                    raise ValueError("Unsafe archive path")
                target.parent.mkdir(parents=True, exist_ok=True)
                data = pack.read(entry)
                if relative.suffix in (".tres", ".tscn", ".gdshader"):
                    content = data.decode("utf-8-sig")
                    old = {"grass": "res://", "foliage": "res://Foliage Sample Pack/", "rocks": "res://Rocks Sample Pack/"}[group]
                    content = content.replace(old, "res://vendor/" + group + "/")
                    # Fresh project owns resource identity; avoid stale vendor UIDs.
                    content = re.sub(r' uid="uid://[^\"]+"', "", content)
                    data = content.encode("utf-8")
                target.write_bytes(data)
    for name in ("CommonTree_1", "Bush_Common", "Grass_Common_Short", "Rock_Medium_1"):
        source = ROOT / "assets/nature" / (name + ".gltf")
        content = json.loads(source.read_text())
        destination = OUTPUT / "baseline"
        destination.mkdir(exist_ok=True)
        shutil.copy2(source, destination / source.name)
        for section in ("buffers", "images"):
            for item in content.get(section, []):
                if "uri" in item:
                    shutil.copy2(source.parent / item["uri"], destination / item["uri"])
    shutil.copy2(ROOT / "tools/asset_store_review.gd", OUTPUT / "review.gd")
    (OUTPUT / "project.godot").write_text('''config_version=5
[application]
config/name="SolHunter Asset Comparison"
run/main_scene="res://review.tscn"
[display]
window/size/viewport_width=1280
window/size/viewport_height=800
[rendering]
renderer/rendering_method="forward_plus"
''')
    (OUTPUT / "review.tscn").write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://review.gd" id="1"]
[node name="AssetComparison" type="Node3D"]
script = ExtResource("1")
''')
    (OUTPUT / "provenance.json").write_text(json.dumps(evidence, indent=2))
    local_user = OUTPUT / "local_user"
    local_user.mkdir(exist_ok=True)
    (local_user / ".gdignore").touch()
    print(OUTPUT / "project.godot")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("downloads", type=Path)
    prepare(parser.parse_args().downloads)
