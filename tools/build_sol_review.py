import json,sys
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
sys.path.insert(0,str(Path('tools').resolve()))
from build_plant_review import crop_view
root=Path('artifacts/plant-closeup-review');p=root/'sols';rows=json.loads((p/'manifest.json').read_text())
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',30)
for r in rows:
 pair=Image.new('RGB',(2000,1050),'white');d=ImageDraw.Draw(pair);d.text((30,15),r['code']+' / '+r['name'],font=font,fill='#16322a')
 for i,v in enumerate(r['views']):
  im=crop_view(p/v);im.thumbnail((950,900));pair.paste(im,(i*1000+(1000-im.width)//2,80+(900-im.height)//2))
 pair.save(p/(r['code']+'-pair.jpg'),quality=94)
 r.update(pair=r['code']+'-pair.jpg',biome=r['class_id'],group='Catalog Sol model',plant_id=r['species_id'],status='Current catalog presentation / visual review only',requested=True,approved=False,note='Review appearance, anatomy, silhouette and colors. Decisions do not change mechanics or publish models automatically.')
config={'revision':'sol-round-01','status':'pending_owner_visual_review','reference':'','selected_codes':[r['code'] for r in rows],'plants':rows,'preferences':['Preserve species identity and independent individual affinity.','Review silhouette, anatomy, colors, face and visual-core placement.','Use close-ups and retain earlier pictures when requesting revisions.'],'history':[]}
registry=Path('docs/reference/sol_review_registry.json')
if registry.exists():
 previous=json.loads(registry.read_text(encoding='utf-8'))
 config['preferences']=previous.get('preferences',config['preferences'])
 config['history']=previous.get('history',[])
Path('docs/reference/sol_review_registry.json').write_text(json.dumps(config,indent=2),encoding='utf-8')
from build_review_hub import build
build()
