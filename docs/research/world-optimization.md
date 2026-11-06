# World optimization evidence

The workload and architecture described here predate the
[map-first build](../world-map-proposal.md#playable-handoff). Use the current
chunk worker, horizon rings, and vegetation patches when comparing evidence.

Owner-requested optimization of streaming, Vastra rebuilds, vegetation rendering
and flora bookkeeping. This changes derived preparation/presentation only; Godot
generation, source-reconciled ecology, saved energy and membership stay authoritative.

## Implementation

- Geography caches deterministic district hubs. Streaming and flora preparation
  yield between road candidates and route-admission segments, publishing only
  complete districts. Chunk prewarming includes neighboring plant-footprint
  dependencies. Synchronous generation uses the same candidate/admission helpers.
- Scene loading prepares the shared grass texture/mipmaps and biome tint variants,
  moving first-use asset work out of individual streamed cells.
- Vastra retains at most 256 transfer curves keyed by actual endpoints, seed,
  crown mode and geometry tuning. Terrain/rebuild invalidation and returned
  copies prevent stale terrain and caller mutation. Packet timing and energy
  continue to come from the expedition.
- Grass can use independently culled 4/8/16-cell sections (8 by default). Stable
  per-clump distance thinning keeps nearby cover intact, reducing distant raster
  work without a transparent fade pass. Original clump transforms, colors and
  canonical flora links remain unchanged. Inspector controls are documented in
  [Inspector tuning](../inspector-tuning.md).
- Compacted static nature meshes generate native screen-error LOD index levels
  once per shared asset at palette preparation. Close geometry and picking stay
  full resolution; imported sources are unchanged. View settings expose LOD bias.
- Flora neighbors use kind indices and at most 512 successful cached queries.
  Admission/eviction invalidates them; incomplete neighborhoods still return null.
  Active membership is cached, and an unchanged active set avoids rebuilding the
  expedition's regional index.

## Reproduction and scope

Run Godot 4.7.2 with `--headless --path . --script
tools/profile_world_optimization.gd -- --tag=<label>` for CPU evidence. It records
three prepared chunks, repeated flora queries, repeated transfer curves and
output checksums. Current runs separately report scene-style asset prewarming;
this work is shifted to loading, not eliminated. The original cold baseline
included first-use asset preparation in streaming. OS caches and desktop load
are not controlled; these measurements are not whole-game FPS or device acceptance.

Run `tools/profile_grass_batches.gd` using Direct3D 12 with `-- --batch=16` for
the previous unthinned batch treatment and `-- --batch=8` for the optimized
treatment. Both use the production scene at 1280×800 and four camera angles,
with 30 warmup and 90 measured frames per view. Generated clumps and draw distance
match; simulation is frozen for measured windows. JSON and paired screenshots
are written under `artifacts/world-optimization/`.

CPU baseline: flora queries 117.310 ms; repeated curves 12.931 ms; largest
streaming slice 73.609 ms. An intermediate optimized run recorded 5.070 ms,
1.603 ms and 27.801 ms respectively. Its maximum road-preparation step was
1.531 ms. Terrain checksum `647274382`, curve checksum `4164499142` and neighbor
count `3240` match the baseline. First-use cell work remains a separate hitch
risk; smaller preparation steps are cooperative, not a hard real-time guarantee.

Final validation and renderer comparison are recorded after the connected checks.

An initial isolated grass comparison (before static nature LODs) measured
0.697–0.752 ms per view for whole, unthinned batches and 0.623–0.652 ms for
8-cell batches with distant thinning. Whole-scene timing was variable; this is
evidence for reduced grass raster cost, not an equivalent whole-game FPS gain.

## Distance rendering follow-up — October 30, 2026

The shared detailed/streaming terrain shader now samples only material families
with nonzero blend contributions. Geographic colors, trails, supplied texture maps
and blend weights retain their owners. Explicit geographic texture gradients are
computed before material branches so mip selection remains stable at boundaries.
Relief sampling fades between 60% and 100% of `terrain_relief_distance` (56 cells
by default). Normal-map sampling similarly fades to the mesh normal by
`terrain_normal_distance` (88 cells). Zero disables either distance reduction.
These are `NatureSettings` controls, applied on rebuild, with finite 0–128 bounds.

The shared single-blade builder keeps its original seven close triangles and adds
native three-triangle and one-triangle index LODs. Both retain exact root/tip
anchors, winding, UVs and the existing material/wind treatment. Native projected
error selects geometry for each grass batch; selection is not a fixed distance
switch. Shader density thinning remains complementary. This uses Godot's
[native MultiMesh LOD support](https://docs.godotengine.org/en/4.3/tutorials/3d/mesh_lod.html).
`View3DSettings.detail_distance` now defaults to 48 cells instead of unlimited:
small plants fade out separately from full-horizon trees. Setting zero restores
the previous decoration horizon. Flora membership, reserves and simulation remain
independent of drawing. Temporary coverage also sets unchanged material uniforms
only when its terrain/settings owner changes, rather than on every camera update.

`tools/profile_distance_rendering.gd` compares an archived prior shader include
at `artifacts/distance-optimization/terrain_palette_before.gdshaderinc` against
the live include. Preserve that prior file before editing to reproduce a pair.
Run with Godot 4.7.2, Direct3D 12 and `--script tools/profile_distance_rendering.gd`.
The fixed-coverage 1280×800 fixture warms each shader for 45 frames and measures
120 uncapped frames, recording viewport GPU time separately from frame intervals.
Screenshots and `render.json` live beside the archived include. On the local RTX
3070, one clean rendered pair recorded approximately:

| Isolated workload | Prior GPU ms | Updated GPU ms |
| --- | ---: | ---: |
| Near grass terrain | 1.639 | 0.401 |
| Near blended terrain | 1.578 | 1.548 |
| Far grass terrain | 1.558 | 0.213 |
| Far rock terrain | 1.554 | 0.195 |
| 6,400 grass blades, full geometry versus native LOD | 0.118 | 0.079 |

These are small synthetic GPU workloads, not whole-game FPS improvements. The
fixed coverage intentionally isolates shader complexity from perspective size.
Godot's primitive monitor reported one primitive for the instanced far LOD,
apparently omitting the instance multiplier; it is retained only as a raw
diagnostic. Uploaded index buffers independently prove seven/three/one triangles
per blade. Production-scene four-angle rendering uses the existing
`tools/profile_grass_batches.gd -- --batch=8`; screenshots were inspected.
The consecutive full-horizon/small-plant-limit runs reduced scene draw calls
from 4,541–5,446 to 3,698–4,207 across matched angles (about 19–24%). GPU windows
were approximately 6.11–7.43 ms and 4.95–5.83 ms respectively. Desktop load and
CPU frame intervals varied; this is an observation, not an FPS guarantee. Copies
of the first run are `world-before-detail-limit.json/png` under the distance
artifact folder; the final run is `artifacts/world-optimization/grass-8.json/png`.

Focused checks passed: terrain materials 4,823; uploaded blade LOD indices and
winding 198; world optimization 4,328; runtime optimization 62; grass surface
placement 26,745; view/streaming 15,109; wilderness presentation 128.
Script/UID ownership and final engine
import passed. Existing
Canvas/ObjectDB cleanup warnings remain. The older grass-lab review hits a stale
`blades_per_square_metre` field; the cohesive review hits a stale `NaturePatch.clearings`
field. Those review tools are not reported as passes. No full-suite or handheld
acceptance is claimed.
The wilderness presentation check was updated to respect the already separate
grass distance instead of expecting every `nature_detail_` batch to use the
small-plant distance; its former five failures were grass batches.

Further distance work should target the production scene's remaining draw-call
cost: shared distant plant materials and baked tree impostors, then larger
terrain-only horizon rings. Measure movement/turn transitions before adoption;
native mesh LOD reduces geometry but does not merge material draw calls. Keep
Vastra visual range and transparency bounded independently of saved ecology.
