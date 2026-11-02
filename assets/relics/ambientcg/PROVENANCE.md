# Relic stone materials

Latest owner selection, October 30: use
[Rock051](https://ambientcg.com/view?id=Rock051) for the relic stone. All current
relic material variants now use its existing 2K color, OpenGL normal, roughness,
ambient occlusion and metalness maps under `assets/terrain/ambientcg/rock051/`.
Black/Abyssal/Ash-black variants tint that same surface following the owner's later
black-stone direction. The original package/license
evidence and hashes remain in the terrain manifest. The earlier selections below
are retained source assets, not the active relic material palette.

Owner request, October 30, 2026: obtain 3D texture maps from the project's existing
texture website for procedural relics. Provider: ambientCG / Lennart Demes.
[Official license](https://docs.ambientcg.com/license/): CC0 1.0 Universal, including
asset redistribution. The fetched license page is preserved in `license_source.html`.

- Rough stone reuses [Rock020](https://ambientcg.com/view?id=Rock020), already
  downloaded under `assets/terrain/ambientcg/rock020/`.
- Dark stone reuses [Rock035](https://ambientcg.com/view?id=Rock035), already
  downloaded under `assets/terrain/ambientcg/rock035/`.
- Carved masonry uses newly downloaded [Bricks060](https://ambientcg.com/view?id=Bricks060),
  the 1K-JPG package. The four retained source maps are color, authored OpenGL
  normal, roughness and ambient occlusion. No normals are synthesized from color.

`manifest.json` records the archive URL, size, SHA-256, and each retained map's
size/hash. The archive CRC was verified; ZIP copies and unused package files are
not retained. Reproduce with `python tools/download_relic_materials.py`.
The earlier terrain manifest owns provenance for the reused rock sets.

`scripts/scenery/relic_materials.gd` connects all four maps with triplanar mapping
on generated geometry. Material style and tiling are independent of relic shape,
housing style and purpose. The new maps are about 4.0 MiB total; exact sizes are
in the manifest. No source asset or archive was published remotely by this work.

The four owner-supplied ruin images guide original procedural silhouettes only:
split ring with rear monoliths, tapered spire circle, classical courtyard and
compact sanctum. No model or texture was extracted from those images, and their
inclusion in chat supplies no license claim for their underlying asset packs.
