"""Download the owner-selected ambientCG terrain library (2K JPG originals)."""
import concurrent.futures
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import urllib.error
import zipfile

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'terrain' / 'ambientcg'
IDS = ('Grass001', 'Grass004', 'Grass005', 'Ground019', 'Ground037',
       'Ground048', 'Ground054', 'Rock020', 'Rock028', 'Rock029',
       'Rock030', 'Rock035', 'Rock051')


def fetch(url):
    try:
        with urllib.request.urlopen(url, timeout=180) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        if error.code != 403 or not error.url.startswith('https://acg-download.struffelproductions.com/file/ambientCG-Web/'):
            raise
        alternate = error.url.replace('https://acg-download.struffelproductions.com/',
                                      'https://f003.backblazeb2.com/', 1)
        with urllib.request.urlopen(alternate, timeout=180) as response:
            return response.read()


def download(asset_id):
    metadata = json.loads(fetch(
        'https://ambientcg.com/api/v2/full_json?id=' + asset_id + '&include=downloadData'))
    asset = next(a for a in metadata['foundAssets'] if a['assetId'] == asset_id)
    choices = asset['downloadFolders']['default']['downloadFiletypeCategories']['zip']['downloads']
    selected = next(d for d in choices if d['attribute'] == '2K-JPG')
    payload = fetch(selected['downloadLink'])
    if len(payload) != selected['size']:
        raise ValueError('Unexpected archive size: ' + asset_id)
    dest = ROOT / asset_id.lower()
    dest.mkdir(parents=True, exist_ok=True)
    records = []
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        if archive.testzip() is not None:
            raise ValueError('Corrupt archive: ' + asset_id)
        for info in archive.infolist():
            if info.is_dir():
                continue
            relative = Path(info.filename)
            if relative.is_absolute() or '..' in relative.parts:
                raise ValueError('Unsafe archive path')
            target = dest / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            content = archive.read(info)
            target.write_bytes(content)
            records.append({'path': target.relative_to(ROOT).as_posix(),
                            'bytes': len(content), 'sha256': hashlib.sha256(content).hexdigest()})
    print(asset_id + ': downloaded and archive verified', flush=True)
    return {'id': asset_id, 'source': asset['shortLink'],
            'download': selected['downloadLink'], 'archive_bytes': len(payload),
            'archive_sha256': hashlib.sha256(payload).hexdigest(), 'files': records}


if __name__ == '__main__':
    ROOT.mkdir(parents=True, exist_ok=True)
    license_url = 'https://docs.ambientcg.com/license/'
    license_page = fetch(license_url)
    if b'CC0' not in license_page:
        raise ValueError('Could not verify ambientCG CC0 license statement')
    (ROOT / 'license_source.html').write_bytes(license_page)
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        assets = list(pool.map(download, IDS))
    (ROOT / 'manifest.json').write_text(json.dumps({
        'provider': 'ambientCG / Lennart Demes', 'license': 'CC0-1.0',
        'license_source': license_url, 'resolution': '2K-JPG', 'assets': assets
    }, indent=2) + '\n', encoding='utf-8')
    print('Complete: ' + str(len(assets)) + ' materials', flush=True)
