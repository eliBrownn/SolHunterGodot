"""Install selected owner-supplied Vefects dependencies, never vendor demo code.

Usage: python tools/install_local_effects.py C:/Users/elija/Downloads
Licensed vendor sources stay ignored; clones work without this optional art.
"""
import argparse
import hashlib
import json
import re
from pathlib import Path, PurePosixPath
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / 'assets/local/vefects'
SELECTION = {
    'Wind': 'VFX_Wind_Debris_Tree_Leaves_01_Colored_Closer',
    'Distortion': 'VFX_Distortion_Flat_01',
}


def install(downloads):
    evidence = []
    for kind, effect in SELECTION.items():
        archive = downloads / f'Vefects_{kind}_VFX_Godot_v1.0.3_GodotAssetStore.zip'
        with ZipFile(archive) as pack:
            pending = [f'Vefects/{kind} VFX/VFX/Particles/{effect}.tscn',
                       f'Vefects/{kind} VFX/LICENSE.txt', f'Vefects/{kind} VFX/README.txt']
            visited = set()
            while pending:
                name = pending.pop()
                if name in visited:
                    continue
                relative = PurePosixPath(name)
                target = DESTINATION.joinpath(*relative.parts)
                if DESTINATION.resolve() not in target.resolve().parents:
                    raise ValueError(f'Unsafe archive path: {name}')
                if relative.suffix not in {'.tscn', '.tres', '.gdshader', '.gdshaderinc', '.png', '.tga', '.txt'}:
                    raise ValueError(f'Unexpected dependency: {name}')
                data = pack.read(name)
                if relative.suffix in {'.tscn', '.tres', '.gdshader', '.gdshaderinc'}:
                    content = data.decode('utf-8-sig')
                    pending.extend(re.findall(r'res://([^"\n]+)', content))
                    content = content.replace('res://Vefects/', 'res://assets/local/vefects/Vefects/')
                    content = re.sub(r' uid="uid://[^"]+"', '', content)
                    data = content.encode('utf-8')
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
                visited.add(name)
        evidence.append({'archive': archive.name, 'sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'files': sorted(visited)})
    (DESTINATION / 'provenance.json').write_text(json.dumps(evidence, indent=2), encoding='utf-8')
    print(f'Installed {sum(len(item["files"]) for item in evidence)} selected dependencies to {DESTINATION}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('downloads', type=Path)
    install(parser.parse_args().downloads)
