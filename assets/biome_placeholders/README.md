# Biome scenery placeholders

Created October 27, 2026 at the owner's request for inexpensive biome preparation.
Expanded October 28, 2026 with 16 additional placeholders for later human-authored
replacement. The kit now contains 24 original Godot primitive assemblies,
approximately 25 KB of scene text in total. No new textures, binary model files,
downloads, animation rigs or plugins.

The supplied Quaternius nature kit is the visual reference: CommonTree_1 for
bunched green canopy and warm bark, Pine_1 for stacked conifer silhouette, and
Rock_Medium_1 for compact low-poly stone proportions. Its imported models and
leaf palette were inspected; original source assets remain unmodified. See
[nature provenance](../nature/PROVENANCE.md).

| Scene | Intended art use |
| --- | --- |
| `broadleaf_tree.tscn` | Green woodland canopy |
| `conifer.tscn` | Temperate/conifer woodland |
| `dry_tree.tscn` | Sparse olive canopy for dry ground; active hardy-tree variant |
| `snow_conifer.tscn` | Snowy-region silhouette study |
| `palm.tscn` | Tropical/coastal silhouette study |
| `cactus.tscn` | Dry-region silhouette study |
| `reeds.tscn` | Wetland/pond-edge dressing |
| `rock_cluster.tscn` | Shared rocky-region dressing |
| `birch_tree.tscn` | Light-barked woodland tree |
| `willow_tree.tscn` | Drooping wet woodland canopy |
| `dead_snag.tscn` | Bare branching tree silhouette |
| `stump.tscn` | Cut stump with a pale top |
| `fallen_log.tscn` | Horizontal woodland log |
| `bush.tscn` | Small clustered green shrub |
| `grass_tuft.tscn` | Simple upright ground cover |
| `flower_patch.tscn` | Small pale-yellow flowering patch |
| `mangrove_tree.tscn` | Raised-root wetland silhouette |
| `fern.tscn` | Low radial foliage |
| `mushroom_cluster.tscn` | Grouped small mushrooms |
| `lily_pad.tscn` | Flat pond plant and small bloom |
| `boulder.tscn` | Single large low-poly stone |
| `stone_spire.tscn` | Upright rock formation |
| `ice_cluster.tscn` | Matte pale-blue ice shapes |
| `rush_cluster.tscn` | Simple wetland stems |

Scene roots are at ground level, with visible meshes in MeshInstance3D children
so the existing NatureArt/MultiMesh pipeline can reuse them. Materials and shapes
remain editable directly in Godot. These are art studies, not new biome canon,
generation, collision or ecology rules. Only the dry tree is wired into live
scenery; the rest are prepared for future palettes.

For replacement, keep each scene path and its Node3D root at the ground origin;
replace the visual children with your authored model. Imported models can be
nested under that root. The current NatureArt adapter reads mesh references and
transforms from MeshInstance3D descendants. Store materials on the meshes:
node-level material_override and surface override materials are not retained by
the batching path. Animation and node visibility are also not baked. Use static
visual parts with finite, nonempty bounds and keep hidden helper geometry out of
the scene. T4a in the [terrain roadmap](../../docs/terrain-roadmap.md) plans explicit
size, surface and complexity admission for mixed replacement assets.
World collision continues to use the existing generated tile rules. Each asset
can be replaced independently, without changing the gallery or future palette
references. The additional assets do not change the current live-world palette.

The active red TwistedTree variant was replaced in `NatureSettings.hardy_trees`
with the olive dry-tree placeholder; the dead-tree variant remains. Placement,
tree density, blocking cells and saved world state are unchanged. Restart/rebuild
the world to see the replacement, including on a loaded expedition.

Open `scenes/biome_asset_preview.tscn` and press F6 for a contact sheet with supplied
kit references. Buttons select Core silhouettes, Woodland details, and Wetland &
stone. A non-focusing offscreen capture is available with:

```powershell
godot --path . --rendering-driver d3d12 res://scenes/biome_asset_preview.tscn -- --capture-biomes
```

Output: ignored `artifacts/biome_placeholders/preview.png`, `woodland_details.png`
and `wetland_stone.png`. Godot 4.7.2 import and all three Forward+/Direct3D 12
pages passed and were visually inspected after expansion. Existing full-3D checks
also passed when the live hardy-tree replacement was introduced.
