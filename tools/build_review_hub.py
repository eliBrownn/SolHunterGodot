"""Build consistent Plants/Sols review pages without changing authoring resources."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def build():
 out=ROOT/'artifacts/plant-closeup-review'
 plant=json.loads((out/'review-manifest.json').read_text(encoding='utf-8'))
 sol=json.loads((ROOT/'docs/reference/sol_review_registry.json').read_text(encoding='utf-8'))
 template=(ROOT/'tools/review_hub.html').read_text(encoding='utf-8')
 for domain,target in [('plants',out/'index.html'),('sols',out/'sols/index.html')]:
  payload={'domain':domain,'plants':plant,'sols':sol}
  target.write_text(template.replace('__DATA__',json.dumps(payload,ensure_ascii=False).replace('</','<\\/')),encoding='utf-8')
 print('REVIEW HUB: Plants and Sols pages built; existing review storage keys retained')
if __name__=='__main__':build()
