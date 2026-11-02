# Research report 02: noise, landforms and water in a modular world

October 29, 2026. Owner-requested research during
[phase 2](../biome-encounters-geography.md). Primary-source desk research plus an
executable Godot comparison. Engineering recommendations below are interpretations
for SolHunter, not new ecology, survival or story canon.

## Finding

Noise is useful input, but landscape structure needs several owners. Perlin can
vary elevation and moisture; it does not itself specify a watershed, a connected
stream, a lake outlet or a good crossing. A different noise family alone will not
resolve repetitive distribution, equal-looking vegetation or disconnected places.

Godot's FastNoiseLite supports Perlin, smooth simplex and other families, along
with fractal combinations and domain warp. Its documentation distinguishes their
sampling structures. The current project already uses Perlin for moisture and
smooth simplex for elevation; phase 2 exposes the elevation choice separately.
See [Godot's FastNoiseLite reference](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html).

The relevant design lesson from Red Blob's noise experiments is to combine
different scales and reshape fields for valleys, ridges and terraces instead of
expecting a single height field to provide all terrain character. This is a
procedural design technique, not proof of physical geology. See
[Making maps with noise functions](https://www.redblobgames.com/maps/terrain-from-noise/).

For drainage from a height field, Priority-Flood provides a way to resolve enclosed
depressions and derive drainage information. Its boundary/outlet assumptions matter:
an analysis that drains to the edge of a finite sample does not establish a global
river network in an infinite world. See the authors' paper,
[Priority-Flood](https://rbarnes.org/sci/2014_depressions.pdf).

An alternative is to structure terrain around a river network, then combine
procedural terrain and river patches. Génevaux and colleagues demonstrate this
hydrology-led approach. For SolHunter, it suggests that major valleys and water
connections deserve parent-level planning. It does not require copying that full
system or importing its implementation. See
[Terrain Generation Using Procedural Models Based on Hydrology](https://perso.liris.cnrs.fr/eric.galin/Articles/2013-river-networks.pdf).

## Application to our hierarchy

Use the existing ownership structure rather than a separate generator per biome:

1. **World policy** owns the seed, generation version, captured noise/relief/drainage
   parameters and hard access requirements.
2. **Regional geography** owns broad relief, ridge/pass or basin/plateau/terrace
   descriptors and hydrological context. Current geographic districts are 128
   cells; future major watersheds may span multiple districts.
3. **Habitat and place authoring** selects compatible scenery, species pools and
   site templates by references to generated facts. Ecological state and individual
   affinity remain separate authorities.
4. **Groves, clearings and site children** organize coherent local groups and
   inherited size/density budgets. Small individual variation develops that group.
5. **Render chunks** stream the resulting meshes. The existing 16-cell chunks
   must not independently invent rivers, restart a grove pattern or decide where
   a geological feature ends.

Large-scale noise should establish broad variation; smaller bands supply secondary
forms and surface detail. Domain warp can bend patterns without changing their
ownership. Ridge, basin, plateau and terrace shaping give those fields recognizable
structure. Decorative variation should follow region and grove context rather than
making every tree and plant an unrelated random choice.

This is particularly useful for a top-down presentation: readable silhouettes,
shorelines, passes and continuous routes communicate geography even when vertical
depth is compressed by the camera. Actual terrain heights still govern geometry,
picking and traversal; colored tiles must not pretend an impassable cliff is flat.

## Implemented bounded proof

`TerrainHeightfield` now supports both elevation families, seeded regional landforms
and captured settings. The normal exploration preset uses stronger broad/secondary
relief and landform strength 1; smooth simplex remains the default pending playable
comparison. Moisture retains its independent Perlin field.

`TerrainDrainage` builds a finite-grid receiver tree using a Priority-Flood pass
and derives contributing sample counts. Its tests check termination, non-increasing
spill heights, deterministic ties, depression depth and conservation at boundary
outlets. This is a derived analysis; it does not move water volume every frame.

Normal pond candidate selection now reads a bounded 9×9 raw-height catchment grid
per geographic district. It favors lower candidates with contributing area or
depression context, while retaining existing authored-route/foundation exclusions.
The influence is captured with generation settings and can be tuned in Godot.
The grid's edges are local analysis outlets. This improves pond siting; it does
not claim that neighboring districts' receivers connect into rivers.

Generation 10 deliberately versions the new geography contract. Saved expeditions
retain their own settings; previous development formats are rejected through the
existing new-expedition path rather than silently reinterpreted.

## Perlin versus smooth-simplex study

Run `tools/review_noise_drainage.gd` with the pinned Godot engine. It compares seed
2601026 over 129×129 samples at four-cell spacing, beginning at (-128,-128). Both
cases use the same amplitudes, scales, landform rules and finite-grid drainage
analysis. Maps use the same elevation color range. They show raw terrain before
authored routes, pond shaping and rendered scenery.

| Single diagnostic sample | Smooth simplex | Perlin |
| --- | ---: | ---: |
| Minimum relative height, cells | -7.506 | -5.021 |
| Maximum relative height, cells | 6.399 | 8.973 |
| Largest contributing sample count | 6,805 | 5,336 |
| Samples filled by more than 0.25 cell in spill analysis | 3,856 | 2,228 |

Refresh this table when the inputs change. These figures describe one finite
map, not worldwide statistics, river discharge, performance acceptance or a verdict
that one family is more enjoyable.

Output: `artifacts/world_exploration/noise-drainage/`. The elevation maps show
relative height; blue drainage marks show larger contributing areas, and cyan
indicates filled depressions in the analysis. These colors are study annotations,
not a promise of visible water at every marked position in the game.

## Next connected-water contract

Build a bounded parent watershed graph before adding rendered stream segments.
The parent must specify terminal outlets or retained lake basins and a cycle-free
downstream ordering. Neighboring regions should refer to one shared edge contract
for crossing position, direction, elevation and contributing area; they must not
roll those facts independently.

Derive local tributaries and valley carving under that graph. Retain explicit lake
spill/outlet behavior, verify downstream water-surface height, and plan essential
road crossings before committing terrain. Final water masks, grounding, swimming,
interaction picking and dry access must consume the same resulting descriptors.
Vegetation and habitat presentation can then read verified water proximity;
actual ecological effects still need their own mechanics specification.

Check reversed chunk publication, negative coordinates, cache eviction, neighboring
regions and save/load. A local halo or attractive blue noise strip alone cannot
prove cross-region drainage. This connected-stream stage remains open; live fluid
simulation, erosion and river mechanics are not claimed by the current proof.
