# Reviewed Renard Noir nature samples

Supplied by the owner and approved for main-game visual use October 29, 2026.
Original archive names and SHA-256 hashes are recorded in `provenance.json`.

- [Forest Vegetation sample](https://store.godotengine.org/asset/renard-noir/forest-vegetation-sample-pack/): seven supplied static scenes, textures and materials.
- [Rocks and Stones sample](https://store.godotengine.org/asset/renard-noir/rocks-and-stones-sample-pack/): five supplied static scenes, textures and materials.

Both archives include the MIT license, copyright 2026 Renard Noir. The original
notices are retained in each pack directory. PNG textures are unchanged. Resource
paths are adapted to this repository and stale archive UIDs are removed. Supplied
surface overrides and transforms are baked into static meshes by
`tools/bake_reviewed_nature.gd`; this preserves the existing NatureArt admission,
batching, picking and clearance contracts. Materials use mipmapped sampling,
leaf cutouts, matte stones and weaker rock normals for the reviewed style.
Original FBX sources and vendor demo scenes/scripts are not included.

The main palette uses the regular juniper among the existing meadow/woodland
trees, JelloBush among woodland dressing, and round boulders, stones and columns
for existing rock anchors. Other supplied variants remain available for authoring.
Generation, route admission, species and individual affinities remain unchanged.

Total size was reviewed before adoption: the largest file is the approximately
3.3 MB stone normal texture; no new individual asset exceeds 10 MB. No LFS policy
change is needed for this subset.

EmacEArt grass is separate: its asset license allows game use but restricts source
redistribution. `assets/local/emace_grass/` is ignored by Git. The original license
is preserved there by `tools/install_reviewed_visuals.py`. MeadowArt loads that
local pack when present and falls back to an original procedural grass tuft and
shader when absent. Do not force-add the local pack. This fallback keeps a fresh
checkout runnable without redistributing proprietary sources.
