"""Create an ignored standalone comparison from owner-supplied Vefects ZIPs.

Vendor files stay outside public source. No vendor scripts, plugins or project
settings execute; only the resource dependencies of four selected effects load.
"""
import argparse
import hashlib
import json
import re
import shutil
from pathlib import Path, PurePosixPath
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "artifacts/vastra_resource_review"
EFFECTS = {
    "Wind": ["VFX_Wind_Flows_01", "VFX_Wind_Flows_Trails_01"],
    "Distortion": ["VFX_Distortion_Flat_06", "VFX_Distortion_Flat_11"],
}


def prepare(downloads):
    OUTPUT.mkdir(parents=True, exist_ok=True)
    evidence = []
    for kind, scenes in EFFECTS.items():
        archive = downloads / f"Vefects_{kind}_VFX_Godot_v1.0.3_GodotAssetStore.zip"
        with ZipFile(archive) as pack:
            pending = [f"Vefects/{kind} VFX/VFX/Particles/{scene}.tscn" for scene in scenes]
            pending += [f"Vefects/{kind} VFX/LICENSE.txt", f"Vefects/{kind} VFX/README.txt"]
            visited = set()
            while pending:
                name = pending.pop()
                if name in visited:
                    continue
                visited.add(name)
                relative = PurePosixPath(name)
                target = OUTPUT.joinpath(*relative.parts)
                if OUTPUT.resolve() not in target.resolve().parents:
                    raise ValueError(f"Unsafe archive path: {name}")
                if relative.suffix in (".gd", ".cs", ".dll", ".exe"):
                    raise ValueError(f"Unexpected executable dependency: {name}")
                data = pack.read(name)
                if relative.suffix in (".tscn", ".tres", ".gdshader", ".gdshaderinc"):
                    content = data.decode("utf-8-sig")
                    pending.extend(re.findall(r'res://([^"\n]+)', content))
                    # Discard editor UIDs; this isolated project resolves real paths.
                    content = re.sub(r' uid="uid://[^"]+"', "", content)
                    data = content.encode("utf-8")
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
            evidence.append({"archive": archive.name, "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(), "files": sorted(visited)})
    shutil.copy2(ROOT / "tools/review_vastra_resources.gd", OUTPUT / "review.gd")
    (OUTPUT / "project.godot").write_bytes(b'config_version=5\n[application]\nconfig/name="Vastra resource comparison"\n[display]\nwindow/size/viewport_width=960\nwindow/size/viewport_height=640\n[rendering]\nrenderer/rendering_method="forward_plus"\n')
    (OUTPUT / "provenance.json").write_bytes(json.dumps(evidence, indent=2).encode("utf-8"))
    print(OUTPUT)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("downloads", type=Path)
    prepare(parser.parse_args().downloads)
