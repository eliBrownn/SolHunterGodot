"""Build the same local plant-review document; retain original images and stable IDs."""
import argparse
import hashlib
import json
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / 'docs/reference/plant_review_registry.json'

def crop_view(path):
    image = Image.open(path).convert('RGB')
    background = Image.new('RGB', image.size, image.getpixel((0, 0)))
    mask = ImageChops.difference(image, background).convert('L').point(lambda value: 255 if value > 24 else 0)
    box = mask.getbbox()
    if not box:
        raise ValueError(f'Blank plant capture: {path}')
    x0, y0, x1, y1 = box
    margin = max(18, int(max(x1-x0, y1-y0)*0.07))
    return image.crop((max(0, x0-margin), max(0, y0-margin), min(image.width, x1+margin), min(image.height, y1+margin)))

def build(output):
    config = json.loads(REGISTRY.read_text(encoding='utf-8'))
    revision = config['revision']
    capture_path = output / revision / 'manifest.json'
    capture = json.loads(capture_path.read_text(encoding='utf-8'))
    capture_registry = ROOT / config['capture_registry_path'] if config.get('capture_registry_path') else REGISTRY
    if capture['registry_sha256'] != hashlib.sha256(capture_registry.read_bytes()).hexdigest():
        raise ValueError('Review settings changed after capture; recapture before presenting.')
    revised = {row['code']: row for row in capture['plants']}
    previous_path = output / 'round-01' / 'manifest.json'
    previous = {row['code']: row for row in json.loads(previous_path.read_text())['plants']} if revision != 'round-01' and previous_path.exists() else {}
    font_path = Path('C:/Windows/Fonts/segoeui.ttf')
    if not font_path.exists():
        font_path = Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
    title_font = ImageFont.truetype(str(font_path), 37)
    font = ImageFont.truetype(str(font_path), 25)
    records = []
    for original in config['roster']:
        row = dict(original)
        code = row['code']
        row['requested'] = code in config['selected_codes']
        row['approved'] = code in config.get('accepted_codes', [])
        row['approval_revision'] = config.get('accepted_inputs', {}).get(code, {}).get('approval_revision', 'round-01')
        if code in previous:
            old = previous[code]
            row['previous'] = dict(old, pair=f'round-01/{code}-pair.jpg', views=[f'round-01/{v}' for v in old['views']])
            row['revision'] = dict(row['previous'])
        row['note'] = config['overrides'].get(code, {}).get('note', '')
        if code in revised:
            update = revised[code]
            canvas = Image.new('RGB', (2000, 1100), 'white')
            draw = ImageDraw.Draw(canvas)
            draw.text((35, 20), f"{code} / {row['biome']} / {row['name']}", font=title_font, fill='#16322a')
            draw.text((35, 78), f'{revision} / approved generation baseline' if row['approved'] else f'{revision} / proposed revision - awaiting review', font=font, fill='#52665d')
            for index, view in enumerate(update['views']):
                image = crop_view(output / revision / view)
                image.thumbnail((960, 895), Image.Resampling.LANCZOS)
                canvas.paste(image, (index*1000+(1000-image.width)//2, 145+(895-image.height)//2))
                draw.text((index*1000+35, 1050), 'Three-quarter close-up' if index == 0 else 'Higher-angle close-up', font=font, fill='#52665d')
            filename = f'{code}-pair.jpg'
            canvas.save(output / revision / filename, quality=94)
            row['revision'] = dict(update, pair=f'{revision}/{filename}', views=[f'{revision}/{view}' for view in update['views']])
        # Source pictures stay relative and work from both file:// and localhost.
        for view in row['views'] + [row['pair']]:
            if not (output / view).is_file():
                raise ValueError(f'Missing original picture: {view}')
        records.append(row)
    payload = {'revision': revision, 'reference': config['reference_code'], 'selected_codes': config['selected_codes'], 'plants': records, 'preferences': config.get('preferences', []), 'history': config.get('history', []), 'status': config.get('status', '')}
    data = json.dumps(payload, ensure_ascii=False).replace('</', '<\\/')
    template = (ROOT / 'tools/plant_review_gallery.html').read_text(encoding='utf-8')
    (output / 'index.html').write_text(template.replace('__REVIEW_DATA__', data), encoding='utf-8')
    (output / 'review-manifest.json').write_text(json.dumps(payload, indent=2), encoding='utf-8')
    print(f"PLANT REVIEW: {len(records)} stable IDs, {len(revised)} revised close-up pairs, {len(config['selected_codes'])} requested redos")
    if (ROOT / 'docs/reference/sol_review_registry.json').exists():
        from build_review_hub import build as build_hub
        build_hub()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'artifacts/plant-closeup-review')
    build(parser.parse_args().output.resolve())
