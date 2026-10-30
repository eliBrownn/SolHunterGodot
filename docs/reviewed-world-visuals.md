# Reviewed world visuals and pixel testing

## Required plant registration — October 29, 2026

Art replacement must preserve every living plant's canonical Vastra cell link. Dense grass shares one reserve per cell; authored plant entries declare living membership explicitly, with rocks/logs/dead wood excluded. Model filenames and local art installation cannot determine saved energy. Review vegetation/Vessel and circulation links alongside visual admission.
See the [authoritative registration contract](vastra-integration.md#generated-vegetation-registration-and-system-hierarchy) for owners, limits and checks.

Owner approval, October 29, 2026: apply the reviewed nature visuals, retain a
stylized painterly treatment, make grass expansive, and keep an in-game pixel
adjustor for testing. The earlier standalone asset study remains a comparison
fixture; normal F5 now uses the reviewed main-game palette.

## What is connected

Grass uses independently culled 8-cell sections inside each streamed chunk.
`NatureSettings.meadow_batch_cells` can select 4/8/16 cells at rebuild; this
changes draw-call granularity without changing generated clumps or flora IDs.
`MeadowAppearance` keeps full nearby cover, then gradually thins cosmetic clumps
between 24 and 44 horizontal camera cells to 40% distant density. Stable absolute
root positions select clumps; they shrink into their roots without a transparent
fade pass. Set Distant Density to 1 to disable thinning. Existing grass draw
distance, wind and canonical plant membership remain independently owned.
The shared grass texture and biome tint variants are prepared at scene load to
avoid first-use asset preparation during traversal. See the
[optimization evidence](research/world-optimization.md) for measurements and limits.
Compacted static nature meshes also retain native screen-error LOD index levels
for distant trees and plants. Full-resolution geometry remains available for
close views and picking; source imports are untouched. `Scenery LOD Bias` in
the view settings controls selection, with higher values retaining more detail.

Canonical ground plants retain a ground-level Vastra presentation endpoint even
when cosmetic dressing is absent, including sparse heath and marsh palettes.
Authored model anchors take priority. These endpoints reference existing flora
cells; they add no reserves, plants or transfers. This prevents cosmetic density
from hiding otherwise valid conserved circulation.

The existing saved-clock lighting/mood/sky controller stays authoritative.
October 30 follow-up replaces live imported trees and vegetation with the plant
library/shared procedural builders and reviewed blade grass. Imported tree
palettes, including reviewed junipers, are now empty compatibility fields; source
assets remain historical references. Reviewed rocks still use existing generated
obstacle anchors. Separate meadow and woodland
palettes preserve the other habitats and their identities. MIT sources, licenses
and adaptation details are indexed in [asset provenance](../assets/nature_samples/PROVENANCE.md).

Continuous grass is batched per streamed chunk on free meadow/woodland terrain.
It samples canonical terrain at each clump, excludes existing routes, reserved
sites, landmarks, camps, obstacles, water and steep slopes, and has no collision,
interaction or population identity. The existing chunk pipeline/cache bounds its
work; grass now uses a separate 48-cell camera draw distance with an 8-cell
fade band to reduce distant foliage rendering (owner performance follow-up).
Plants now also follow the horizon by default; an optional positive Detail
Distance still limits smaller decorations. Nearby published scenery stays
resident across camera turns within the existing chunk capacity and retention
budget. Reused plants appear immediately with their normal cutout materials,
without a repeated whole-instance transparency fade.
Specialist Warden/Mender/Regulator bodies are also ordinary seeded chunk scenery.
Their models no longer come from the ecology display's nearest-plant radius;
that display supplies local activity pulses while the bodies remain world-anchored.
It receives tree shadows without casting thousands of blade shadows. The shared
atmosphere supplies its direction and rain-adjusted wind strength using existing
conditions. It creates no independent weather clock or simulation.

Grass uses habitat-matched root colors, matte blades and no normal-map relief; stone
normal strength is reduced. Local EmacEArt art is optional and remains ignored by
Git because its license restricts source redistribution. A fresh checkout uses
the original procedural tuft/shader fallback. Other imported nature uses the
existing biome tint/composition and material/picking pipeline.

Owner follow-up, October 29: reduce foliage clutter and blend the ground into it.
Main-game grass now uses 2 rather than 3 clumps per cell edge (56% fewer), at
0.22 rather than 0.32 cells high. Meadow/woodland cosmetic plant chances are
14%/18% rather than 24%/28%; blocking tree anchors remain generation-owned.

Detailed and temporary streamed turf use the same configurable base color and
restrained texture luminance detail. Trails and shore-bank blending retain their
existing materials/behavior. Grass uses the same base color and habitat tint,
with a restrained root-to-tip gradient and upward shading normals. The local
mesh/alpha silhouette remains optional; both it and the procedural fallback use
the shared meadow shader. Local asset vertex color masks are removed from the
runtime mesh copy so they cannot contaminate the habitat color.

Cutout foliage uses Godot alpha-to-coverage with existing view MSAA, anisotropic
filtering and generated mipmaps on cached runtime texture copies. Grass uses the
same filtering/coverage treatment without emission or normal-map relief. Licensed
sources remain untouched; shared materials and chunk MultiMeshes remain batched.
Pixel modes disable MSAA as described below; judge edge smoothing with Pixel Off.

The rendered `tests/reviewed_visuals.gd -- --capture-visuals` journey covers the
main view and a closer gameplay zoom. Current logs/captures are under
`artifacts/visual_install/foliage_render.log`, `foliage_biome.log` and `game/`.
These supersede the earlier grass-only cleanup capture.
Verified with Godot 4.7.2: 40 rendered visual checks, 404 biome scenery checks and
22,605 shoreline checks passed. Wide and close Off captures were visually
inspected. The full validator was not rerun for this presentation-only pass.

## In-game control

Press **R**, select **Options**, and use **Pixel effect - testing** at the top.
The selector offers Off, Very light (1.25x), Light (1.5x), Medium (1.75x), Strong
(2x), and Deep (3x). Off is the Inspector and main-game default following the
owner's October 29 request to remove pixelation. Changes apply immediately
for the current session, including loaded expeditions; no save schema or world
state changes. Restart restores the configured default.

The main-game effect samples the rendered world on a coarser pixel grid with
nearest filtering before the HUD is drawn. Menus, labels, mouse targeting and
camera projection keep their native coordinates. This avoids moving the live
simulation/actors between viewports. Unlike the standalone preview's lower
resolution viewport, this pass does **not** reduce the 3D rendering workload.
Pixels disable MSAA and FXAA; Off restores the view's configured MSAA with FXAA
still off, preserving the owner's request to remove the blur.

Inspector defaults live on `View3DSettings.pixel_effect_level` and
`NatureSettings.meadow_enabled`, `meadow_divisions`, `meadow_height`. Density and
height apply when scenery rebuilds/restarts, including loaded worlds. Their
validation bounds are 2-4 clumps per cell edge and 0.15-0.65 world-cell height.
Pixel strength can be reapplied live without rebuilding scenery.
`NatureSettings.ground_base_color` and `ground_texture_strength` tune both terrain
render paths; the base color also feeds grass. Rebuild/restart applies these
presentation edits to new and loaded expeditions without changing saved terrain.

## Validation

`tests/reviewed_visuals.gd` covers static asset admission, live Options changes,
canonical grass rooting, unchanged terrain samples and unchanged picking rays.
Its rendered mode (`-- --capture-visuals`) captures Off/Medium and the Options UI
in the actual game. Evidence is under ignored `artifacts/visual_install`.
This is local PC acceptance, not target-device performance acceptance. The full
configured CI suite remains unchanged.

A two-line explicit `Vector2i` annotation fix in `vastra_currents.gd` resolves a
compile error found during the integration checks; it changes no Vastra behavior.

Verified locally on Godot 4.7.2 stable: final editor import reported no errors;
reviewed visuals passed 35 headless and 38 Forward+/Direct3D 12 rendered checks.
Actual Off/Medium game images and the Options selector were inspected. Affected
headless suites passed: biome scenery 499, atmosphere 41 (expected invalid-settings
warning fixture), live menu/window 29, presentation 19 (five depth-render checks
skipped in headless mode), player traversal 13, and Vastra currents 137. Script
ownership passed with 153 scripts/UIDs. Logs with `_verified`/`_final` suffixes,
plus `biome_scenery.log` and `atmosphere.log`, supersede intermediate failed runs.
The full validator was not rerun; no configured CI checks were changed.

## Grass and pale plant shading rework — October 29, 2026

Owner follow-up identified both flat ground grass and pale mint ecology plants.
The shared meadow shader now retains blade form with an adjustable upward normal
bias instead of forcing every face to shade as flat ground. Anchored roots, darker
bases, warm tips, restrained texture luminance and broad color variation provide
separation without emission or specular highlights. Filtered cutout coverage
remains batched. The original fallback now has tapered segmented blades with UVs
and authored normals, rather than five flat triangles.

`resources/meadow_appearance.tres` owns the new root/tip, texture-detail, patch,
normal, transmission, alpha and wind controls. `NatureSettings.meadow_appearance`
connects it to admitted meadow chunks. Restart/rebuild applies. Existing density,
height, traversal exclusions and scenery ownership are unchanged.

The optional tropical plant palette now uses a dedicated matte leaf shader.
Green swatches receive the configurable leaf pigment; flower/stem swatches keep
their supplied colors. Backface normals are corrected, roots remain anchored and
light-dependent transmission stays restrained. Material instances are cached by
model so their fitted base/height data does not leak across different plants.
`resources/vegetation_appearance.tres` owns pigment, normal bias, transmission
and wind displacement. Original source pack files remain untouched/local-only.

Both shaders use the active expedition clock and existing airflow direction;
pause freezes the wind. Absolute terrain origin compensates for camera rebasing,
so moving the view does not change the wind or broad color phase. No independent
weather or gameplay simulation is introduced.

Godot 4.7.2 / Direct3D 12 rendered a normal-world close-up and a controlled
old/new plant comparison with no script or shader errors. Captures:
`artifacts/grass-rework/close-world.png` and `plant-comparison.png`. This was focused
visual verification, not a full test-suite or performance acceptance run.

## Single-blade grass rollout — October 30, 2026

Owner-approved lab starting point is now the live game's grass. This supersedes
the old optional licensed clumps and the five-blade fallback. Both the lab and
`MeadowArt` use `scripts/scenery/grass_blade_mesh.gd`: one tapered curved blade,
seven triangles, fixed root. Four biome variants inherit the approved width,
height, curve, coverage and color differences. The active palette starts at
49 blades per eligible meadow cell (7 per edge), with lower biome coverage;
render sections and distance thinning retain their existing ownership.

Godot terrain still owns the habitat, ground, slope, route and reserved-space
admission. Grass can share canonical plant cells with specialist bodies. A small central
clearance keeps the authored plant readable; its functional role remains the
cell owner. Ground cover does not turn a receiver into an emanator. Every visible blade references its
cell's single existing reserve through the chunk's stable, density-independent
Vastra endpoint. Shared atmosphere/active time supplies wind; grass does not
seed energy, assign affinity or invent transfer paths. No generation/save schema
changes or lab test reserves enter the game. Existing expeditions receive the art
on restart/chunk rebuild.

Old authored grass entries are removed from land palettes and fallback
undergrowth. Explicit superseded-asset guards prevent bounded/authored legacy
clumps from reaching live render or picking batches. Keep their source files and
licenses for provenance and isolated old art fixtures; the fixed bounded pond
placement definition is unchanged so water/bank admission cannot reroll.

October 30 follow-up: lower cover to 0.18 cells high, reduce the marsh height
multiplier to 1.2, and use narrower, less curved blades with softer root/tip
contrast, less backlighting and slower, smaller wind movement. Apply on restart
or chunk rebuild. Final rendered `tests/reviewed_visuals.gd` passed 42 checks;
close gameplay capture inspected. Existing Canvas/ObjectDB shutdown warnings
remain. `tests/grass_ecosystem.gd` has one receiving-animation assertion failure,
also reproduced at the previous 0.3-cell height; its other 14 checks pass.

Inspector tuning lives in `resources/nature_biomes.tres` (enabled, blades per
edge, height, batch edge) and `resources/meadow_appearance.tres` (blade width,
curve, biome multipliers/colors, shading, wind response and distant thinning).
Settings apply on restart/rebuild and do not rewrite expedition identity.

Validation: pinned Godot import passed. `tests/biome_scenery.gd` passed 9,086
checks, including all four live blade variants and absence of old clumps;
`tests/world_optimization.gd` passed 8,152 checks, including density-independent
Vastra anchors and batch equivalence. `tests/grass_blade_preview.gd` passed.
The normal-scene reviewed-visuals journey passed 45 checks and produced inspected
world/close-foliage captures under `artifacts/visual_install/game/`. That journey
and the optimization suite report one Canvas/ObjectDB shutdown leak warning;
no script/engine errors or failed assertions were reported. These are focused
checks, not a full-suite run or target-device performance acceptance.

## Shared plant tiles and default terrain blending — October 30, 2026

Owner follow-up permits plants and grass in the same tile, asks for grass to blend
into trails and requires default blending across all terrain tiles. Grass now
surrounds specialist plant bodies within the existing canonical plant cells.
Ground-cover endpoints have lower presentation priority, so the functional plant
retains the cell's visual recipient anchor. Many blades and a plant still share
one reserve; no new canonical membership, ecological roles or transactions arise.

Default material blending is shared by detailed tiles and temporary streaming
coverage. Independent path and habitat-soil weights are sampled at absolute
vertices and carried through a custom mesh channel; neighboring tiles/chunks use
the same values. Grass/soil, trail and slope-rock transitions use shared smooth,
world-anchored edge breakup. Existing water depth, shore-bank fade and actual
terrain admission remain authoritative. Biome tint blending defaults to full
neighbor blending. The existing Ground019 color, authored OpenGL normal and
relief maps now explicitly texture the trail, distinct from biome soil.

Protected walking cells remain clear. The surface trail fades through its existing
road shoulders into turf; admitted grass beside that corridor gets progressively
sparser and shorter. This blends the verge without inventing unregistered living
plants on the protected route or changing its collision/access rules. The
`MeadowAppearance` verge width/density/height and `NatureSettings` material
softness, edge breakup and trail texture share are editable for restart/rebuild.

Validation for this follow-up: terrain materials passed 4,807 checks, biome
scenery passed 9,092 checks (including shared specialist/grass endpoints),
world optimization passed 8,488 checks and shorelines passed 22,605 checks.
The rendered main-scene journey passed 42 checks, and its close trail/grass
capture was visually inspected. Final pinned-engine import and ownership/UID
checks passed. The rendered journey/optimization suites retain the previously
recorded single Canvas/ObjectDB shutdown warning; no failed assertions or
script/engine errors remained. No full-suite or device-performance claim.

## Terrain texture resolution — October 30, 2026

Owner-approved sharpness comparison: terrain color, supplied normal and supplied
displacement arrays now bake at 1024px instead of 512px from the 2K sources.
All 13 layers retain mipmaps, anisotropic filtering and the existing four-cell
repeat size. No terrain geometry, blend rules or gameplay data changes.
The baker and existing terrain resolution assertion match the new arrays.

Godot 4.7.2: terrain materials passed 4,823 checks; the rendered reviewed-visuals
journey passed 42 checks and the close gameplay capture was inspected. Editor
import completed but reported editor settings/safe-save permission errors; it
is not a clean import pass. Rendered validation also reported an unavailable
shader-cache folder and existing exit leaks. Logs are in ignored artifacts
(terrain_1024_*); captures are under artifacts/visual_install/game.
No before/after frame-time or GPU-memory benchmark was performed. The three
serialized arrays increased from approximately 31 MB to 126 MB combined;
this is disk size, not measured resident GPU memory.
