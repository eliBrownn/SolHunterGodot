"""Fetch the additional ambientCG masonry set used by the relic study."""
import hashlib
import io
import json
from pathlib import Path
import zipfile
from download_ambientcg_terrain import fetch

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'relics' / 'ambientcg'

def main():
    asset_id = 'Bricks060'
    data = json.loads(fetch('https://ambientcg.com/api/v2/full_json?id=' + asset_id + '&include=downloadData'))
    asset = next(a for a in data['foundAssets'] if a['assetId'] == asset_id)
    downloads = asset['downloadFolders']['default']['downloadFiletypeCategories']['zip']['downloads']
    selected = next(d for d in downloads if d['attribute'] == '1K-JPG')
    payload = fetch(selected['downloadLink'])
    if len(payload) != selected['size']:
        raise ValueError('Archive size differs from provider metadata')
    license_url = 'https://docs.ambientcg.com/license/'
    license_page = fetch(license_url)
    if b'CC0' not in license_page:
        raise ValueError('Provider license could not be verified')
    target = ROOT / asset_id.lower()
    target.mkdir(parents=True, exist_ok=True)
    records = []
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        if archive.testzip() is not None:
            raise ValueError('Archive CRC failure')
        for info in archive.infolist():
            relative = Path(info.filename)
            if relative.is_absolute() or '..' in relative.parts:
                raise ValueError('Unsafe archive path')
            if not info.filename.endswith(('_Color.jpg', '_NormalGL.jpg', '_Roughness.jpg', '_AmbientOcclusion.jpg')):
                continue
            content = archive.read(info)
            dest = target / relative
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(content)
            records.append({'path': dest.relative_to(ROOT).as_posix(), 'bytes': len(content), 'sha256': hashlib.sha256(content).hexdigest()})
    if len(records) != 4:
        raise ValueError('Expected four authored material maps')
    (ROOT / 'license_source.html').write_bytes(license_page)
    (ROOT / 'manifest.json').write_text(json.dumps({'provider': 'ambientCG / Lennart Demes', 'license': 'CC0-1.0', 'license_source': license_url, 'id': asset_id, 'source': asset['shortLink'], 'download': selected['downloadLink'], 'resolution': '1K-JPG', 'archive_bytes': len(payload), 'archive_sha256': hashlib.sha256(payload).hexdigest(), 'files': records}, indent=2) + '\n', encoding='utf-8')
    print('Bricks060: verified archive; four authored maps downloaded')

if __name__ == '__main__':
    main()
