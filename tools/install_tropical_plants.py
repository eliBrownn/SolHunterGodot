"""Install owner-supplied CraftPix placeholders locally; never publish the raw pack."""
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def install(archive: Path) -> None:
    destination = (ROOT / "assets/local/tropical_plants").resolve()
    if ROOT not in destination.parents:
        raise ValueError("Destination must remain in this project")
    names = [f"Fbx/Tropical_plant_{index:03}.fbx" for index in range(1, 21)]
    names += ["Textures/T_Tropical_plants.png", "License.txt"]
    records = {}
    with zipfile.ZipFile(archive) as source:
        # Exact names only: no archive paths, scripts or document instructions execute.
        for name in names:
            data = source.read(name)
            target = destination / name
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() and target.read_bytes() != data:
                raise ValueError(f"Preserve modified local asset: {target}")
            target.write_bytes(data)
            records[name] = hashlib.sha256(data).hexdigest()
    manifest = {"archive": archive.name, "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
                "license_url": "https://craftpix.net/file-licenses/", "files": records}
    (destination / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Installed {len(names)} local files. Raw assets remain excluded from Git.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", nargs="?", type=Path,
                        default=Path.home() / "Downloads/tropical-plant-3d-low-poly-models.zip")
    install(parser.parse_args().archive)
