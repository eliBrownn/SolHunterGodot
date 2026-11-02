import sys,json
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
from download_ambientcg_terrain import download, fetch
root=Path('assets/structures/ambientcg');root.mkdir(parents=True,exist_ok=True)
import download_ambientcg_terrain as lib
lib.ROOT=root
license_page=fetch('https://docs.ambientcg.com/license/')
assert b'CC0' in license_page
(root/'license_source.html').write_bytes(license_page)
records=[download(x) for x in ['Bricks075A','Rock034']]
(root/'manifest.json').write_text(json.dumps({'provider':'ambientCG / Lennart Demes','license':'CC0-1.0','license_source':'https://docs.ambientcg.com/license/','assets':records},indent=2)+'\n')
