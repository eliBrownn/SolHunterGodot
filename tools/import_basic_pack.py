"""Convert the supplied Unity sprite slices to top-left Godot atlas metadata.

Run: python tools/import_basic_pack.py path/to/pack.zip
Requires Pillow and PyYAML only for this offline conversion; Godot needs neither.
No Unity code, project settings, or executable assets are imported.
"""
import io
import json
from pathlib import Path
import sys
import tarfile
import zipfile

from PIL import Image
import yaml

root = Path(__file__).resolve().parents[1] / "assets" / "basic-pack"
root.mkdir(parents=True, exist_ok=True)
manifest = {"source": "Cainos / Pixel Art Top Down - Basic v1.2.3",
            "coordinate_system": "top-left pixels; pivot measured from top-left",
            "sprites": {}}
with zipfile.ZipFile(sys.argv[1]) as archive:
    for name in archive.namelist():
        if name.startswith("Texture/") and name.endswith(".png"):
            dest = root / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(archive.read(name))
    package_name = next(n for n in archive.namelist() if n.endswith(".unitypackage"))
    with tarfile.open(fileobj=io.BytesIO(archive.read(package_name))) as package:
        for member in package.getmembers():
            if not member.name.endswith("/pathname"):
                continue
            path = package.extractfile(member).read().decode()
            if "/Texture/" not in path or not path.endswith(".png"):
                continue
            relative = "Texture/" + path.split("/Texture/", 1)[1]
            raw = package.extractfile(member.name.rsplit("/", 1)[0] + "/asset.meta").read()
            metadata_dir = root / "metadata"
            metadata_dir.mkdir(exist_ok=True)
            (metadata_dir / (Path(path).name + ".meta.txt")).write_bytes(raw)
            importer = yaml.safe_load(raw)["TextureImporter"]
            with Image.open(root / relative) as image:
                width, height = image.size
            for sprite in importer.get("spriteSheet", {}).get("sprites", []):
                rect = sprite["rect"]
                pivot = sprite["pivot"]
                name = sprite["name"]
                # Names occasionally repeat across sheets. Index by sheet/name.
                key = Path(relative).stem + "/" + name
                manifest["sprites"][key] = {
                    "texture": relative,
                    "rect": [rect["x"], height - rect["y"] - rect["height"],
                             rect["width"], rect["height"]],
                    "pivot": [pivot["x"] * rect["width"],
                              (1 - pivot["y"]) * rect["height"]],
                    "unity_id": sprite.get("internalID"),
                    "pixels_per_unit": importer.get("spritePixelsToUnits", 32),
                    "border": sprite.get("border", {})}
(root / "sprites.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print("Imported", len(manifest["sprites"]), "named sprites with original rects and pivots.")
