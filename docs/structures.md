# Structures: modular authoring and scaling

October 31, 2026. This document owns the structure asset pipeline and scaling
process. [Project standard](PROJECT_STANDARD.md) retains repository/workflow
ownership; the [Bible](reference/SolHunter_Worldbuilding_Bible.md) retains design
authority. [World exploration](world-exploration-roadmap.md) owns integration
priority and [relic delivery](relic-roadmap.md) owns powered relic operations.

## Goal and approved direction

Use a small reusable library of basic assets to procedurally assemble diverse
obstacle shapes. Reuse the existing relic stone building blocks, not complete
relic models. Structures should eventually give ordinary wilderness combat useful
positioning choices as well as exploration interest. Visual arrangements alone
do not establish collision, cover bonuses, traversal abilities or powered behavior.

## Ownership and pipeline

1. Base geometry/material: `scripts/scenery/procedural_relic.gd` owns stone meshes;
   `scripts/scenery/relic_materials.gd` owns existing Rock051 surface maps.
2. Recipe: `scripts/scenery/stone_obstacle_definition.gd` owns bounded authoring
   inputs, expressed in metres and scale multipliers.
3. Assembly: `scripts/scenery/procedural_stone_obstacle.gd` owns module selection,
   supported stacks, local positions, stable part IDs, seeded variation and bounds.
4. Rendering: `build()` consumes the layout and shares compatible meshes/material
   within an assembly. It does not choose world placement or own persistent state.
5. Preview: `scenes/stone_obstacle_preview.tscn` displays isolated assemblies.
   `tools/stone_obstacle_preview.gd` owns the contact-sheet camera and lighting.

The current module adapter selects actual individual part records from existing
relic layouts at source seed 73. Source layouts are used only to obtain base
parts; whole relics, carved nodes and circuits are not instantiated. This is an
initial adapter, not an independent replacement geometry library. If extraction
becomes expensive, cache detached catalog records or extract a shared stone-module
owner used by both systems, preserving relic appearance and recorded contracts.

## Current base pieces and assemblies

| Module | Existing source part | Use |
| --- | --- | --- |
| Block | Foundation `wall_0_0` | Stack bodies |
| Slab | Foundation `slab_0_0` | Low steps and caps |
| Pier | Arch `pier_-1_0` | Uprights and corners |
| Taper | Spire circle `tapered_spire_0_3` | Narrowing crowns |
| Arch segment | Arch `arch_0` | Chamfered upper remnants |
| Rubble | Marker `rubble_0` | Independent ground detail |

The original six assembly recipes are: barrier, corner, horseshoe, pillars,
stepped outcrop and broken enclosure. An arch segment used as a cap does not
imply a complete arch or a walkable opening. The module envelope limits width
and depth to avoid overlapping neighbouring columns. Stacks are contiguous;
brokenness removes upper courses rather than leaving floating stones.

The earlier generic tree/log/earth blockouts remain an isolated study. The
relic-derived module pipeline is the current stone-obstacle direction.

## Scaling process

1. Reuse a module first. Add a base asset only when an existing piece cannot
   express the required silhouette or connection. Give it a stable module key,
   metre dimensions, ground/support anchor and clear orientation.
2. Add an arrangement grammar separately from the base mesh. Define footprint,
   supported stacking and intended gaps explicitly. Avoid an entire bespoke
   model for each combination of length, height, breakage and material.
3. Validate and bound recipe inputs before generation. Expose connected settings
   through typed Resources with units, ranges and rebuild semantics.
4. Generate detached layout records with stable IDs. Current assembly version is
   3; records also identify the relic geometry version. Change versions when
   reconstruction changes. This prototype has no expedition-save admission yet.
5. Keep structural streams independent of detail streams. Current structural
   height randomness is keyed by family, seed and column. Rubble uses a separate
   stream: changing rubble count must not reroll the structure.
6. Render and review silhouettes at actual game-camera distances. Check support,
   openings, repetition and recognizability across several seeds and dimensions.
7. Run focused invariant checks before expanding the catalog. Broaden validation
   when integration changes shared terrain, combat or save contracts.

Current rebuild-only controls: family (ten choices), seed (0–99999), length
(2–6 cells), courses (1–4), brokenness (0–1), rubble count (0–12) and scale
(0.5–2). The preview root exposes the shared seed. There is no live Options UI
or saved world tuning for these assets.

## Future environment integration

Godot world generation remains the placement authority. Geographic parents should
select eligible recipes using biome, landform, slope, drainage and reserved access.
Admit one canonical layout before rendering; reject unsuitable sites rather than
blocking required routes. Do not use render chunks or camera visibility as identity.

Movement footprints, height/clearance, sight obstruction and attack obstruction
must be separate consumers of that admitted layout. Water, low slabs and tall walls
must not inherit identical behavior merely because movement is blocked. Combat
preview, AI and impact resolution must query the same authoritative representation.
Preserve creature footprint clearance and existing readiness/local tile ownership.
No such integration is claimed by this object-authoring slice.

When mutations are introduced, ExpeditionState should own saved outcomes through
existing transactions. Powered relics retain their own authored energy contracts;
using relic stone geometry does not make an ordinary obstacle a powered relic.

## Validation and current limits

Run Godot 4.7.2 with `--headless --path . --script tests/stone_obstacle_assets.gd`.
The focused suite checks reconstruction, unique IDs, stack support, build counts
and invalid-input rejection for all ten families across three seeds. It passed
for assembly version 3. The standalone preview was rendered using Godot's
Compatibility renderer. Generated PNGs live under ignored `artifacts/structure-renders/`.

These are object-only procedural assets. World spawning, terrain fitting,
physics collision, navigation/cover queries, persistence, performance budgets and
owner gameplay acceptance remain future work. Current mesh sharing is per build;
large-scale batching and shared catalog caching require measurement when integrated.


## Expanded relic obstacle kit � October 31, 2026

Assembly version 3 adds monolith clusters, broken gateways, split rings and layered
remnants. These are new obstacle arrangements from reusable pieces, not complete
relic-model instances. Column shafts and capitals from the courtyard join the
existing blocks, slabs, tapered spire stones, arch segments and footings. Larger
module proportions express tall markers, cantilevered lintel remnants, curved
segmented arms and broad terrace layers. Stored roll/yaw are now rendered, and
rotated parts contribute transformed bounds. Angular front-face recesses reuse
`relic_carving.gd`; no glow, power circuit, purpose, history or reward is implied.

`structure_stone_materials.gd` owns a separate five-surface obstacle palette:
Rock051, existing Rock035/Rock030, and newly downloaded Bricks075A/Rock034.
Original relic materials are unchanged. All five consume authored color, OpenGL
normal and roughness maps; available AO maps are retained. Dark tints keep the
current relic direction across different surface grains. Surface Style is a
rebuild-only recipe input, independent of geometry randomness.

The four larger grammars use fixed architectural proportions with overall scale
0.5�4. Courses controls the layered remnant; brokenness controls monolith height
and ring reach. Length and rubble count currently affect the original six
recipes only. New families should document which inputs they consume rather than
implying every family uses every control. Large-ring supports are continuous
segmented arms from the plinth; tests validate their data/bounds, not structural
engineering or physical traversal. Detailed stack support checks cover the six
original column-based grammars. Detail-independence checks cover all ten.

New texture provenance and archive/file hashes live in
`assets/structures/ambientcg/manifest.json`; source/license notes are adjacent.
The raw new texture packages occupy approximately 49 MiB locally; publication and
runtime texture budgeting remain separate review steps. No displacement or
height-map geometry is applied. The owner still needs to review visual results.

## Individual masonry expansion — October 31, 2026

The owner narrowed this slice to building blocks while the lab is developed
separately. `scripts/scenery/relic_masonry_blocks.gd` is a lab-independent catalog
of twelve individual profiles: wedge, keystone, L corner, fork, curved arc,
half-round, hexagonal shaft, obelisk, split slab, chamfered lintel, stepped cap
and broken tooth. No additional assembly or lab UI is required to consume them.

Call `definition(key, seed, scale)` then `mesh(record)`. Definitions own a stable
key/version, metre footprint profile, height, taper, crown offset and ground-center
support anchor. Meshes extrude and triangulate the profile, including concave
corners and arc segments. Polygon topology stays authored; seeded height variation
is bounded. Scale 0.25–4 applies uniformly. Rock051 and the existing structure
palette can be assigned by consumers. These new shapes contain no powered parts,
physics, world placement or automatic integration into the older obstacle recipes.
The old relic geometry is unchanged. This additive profile owner handles shapes
that the rectangular stone generator cannot express; do not duplicate it per recipe.

Run `--headless --path . --script tests/relic_masonry_blocks.gd` for topology,
reconstruction, finite geometry/normals, ground anchors and proportional scaling.
The object contact sheet is `artifacts/structure-renders/masonry-blocks.png`.

### Cohesive detail pass

Masonry catalog version 2 keeps twelve distinct profiles while sharing a 4.5 cm
edge bevel, flat support planes, inset crown borders and repeated angular side
carvings. Carving uses the existing right-angle recess implementation. Sparse
seeded crown chips add wear without moving the ground anchor; course heights
are consistent rather than randomly stretched. Detail is generated in module
units and scaled with the whole asset, preserving groove and bevel proportions.
`material()` supplies the shared dark Rock051 treatment, vertex-colored recess
shading and restrained specular response. No luminous strips or power behavior
are added. Consumers should use both `mesh(record)` and this shared material.
The twelve-profile geometry/scaling suite passed after this update and the full
contact sheet was rendered for visual inspection. Assembly and lab code are
unchanged by this individual-block detail pass.
