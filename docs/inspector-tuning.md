# Adjusting the game in Godot

November 1 terrain-quality direction: the shared `NatureSettings` terrain color
palette is **512×512** per layer. **Terrain Depth Strength** (normal/bump mapping)
and **Terrain Relief Depth** (visual parallax) default to **0**, with **Terrain
Normals** and **Terrain Heights** unassigned. Rebuild/restart applies to detailed
and streaming terrain, including loaded expeditions; physical relief and collision
are unaffected. To deliberately restore either effect, assign its matching
13-layer array and raise that effect's strength. The original high-resolution
source artwork remains under `assets/terrain/ambientcg/`. The existing bake tool
now regenerates 512px color layers by default; `--with-relief` includes the optional
map arrays.

November 1 gameplay hitch follow-up (live presentation controls, not expedition
save fields): `SightingSettings` → Admission Presentation owns **Admission Items
Per Frame** (1; 1–8) and **Admission Work Ms** (1; 0.25–3 ms). Models and new move
books share that travel allowance; initial startup/rebuild remains complete and
battle participants still prepare their required books on demand. Membership and
roaming do not wait for models. `VastraSettings` → Visible Currents owns **Current
Paths Per Frame** (4; 1–32) and **Current Work Ms** (1; 0.25–3 ms). The default
filament view stages packet paths and publishes a complete replacement; legacy
ribbon/study/light modes retain immediate preparation. Individual operations can
exceed either cooperative time allowance. Decorative Sol aura/mote/speed controls
are now storage-only compatibility data; the affinity palette still serves UI and
combat. Authored neutral visual-core controls remain active.

November 1 staged-loading experiment (`resources/view_3d_settings.tres`, reapply
or restart): **Spiral Chunk Loading** defaults on. It completes one detailed
chunk through publication before preparing another, in player-centered square
rings starting toward travel. **Nearby Chunk Fraction** (0.5; 0.25–1.0) gives the
nearest half of the complete desired list the normal chunk work budget.
**Distant Chunk Work Ms** (0.75; 0.25–3.0 ms/frame) spreads outer scenery completion
over more frames, within the shared deadline. Existing coarse ground remains
available. These settings affect presentation, not saves or generation; individual
uploads and finite worker tasks can exceed the cooperative allowance. Disable
Spiral Chunk Loading to restore the prior pipeline/priority. See the
[experiment receipt](runtime-optimization.md#staged-spiral-loading-experiment--november-1-2026).

## Development Lab editor workflow — October 31, 2026

Use the **SolHunter Lab** editor tab → station → **Open in Lab** for the existing
sliders/switches/selectors and authoring controls. Plant Maker applies compatible
parameters in place; geometry recipes rebuild samples, while wind/event/review
presentation retains meshes. Existing parameter ranges and apply scope still come
from station exports/hooks. Source changes show a stale notice; **Reload source**
saves drafts and starts a fresh helper. Interactive/Exact picture quality and
10/20 fps/on-demand refresh are editor-view preferences, separate from simulation
speed and production tuning. The layout preferences live under ignored
`.godot/editor/`; bridge workspace data is separate from standalone workspace data.
See [the lab workflow](development-workstation.md#current-workflow-and-l5-evidence--october-31-2026)
for ownership, limits and validation.

October 31 visibility follow-up (`View3DSettings`, reapply/restart, loaded worlds
included): `render_distance` remains terrain extent (72 cells); `tree_distance`
independently controls whole tree bodies (72, range 48–128 cells),
`grass_distance` controls individual ground-cover clumps (28, range 8–64), and
`detail_distance` controls other small plants/decorations (48, range 0–128).
Zero detail distance follows the tree/terrain horizon. All plant ranges are
clamped to the shorter terrain/tree horizon. Trees/details fade over 12 cells;
`grass_fade_cells` controls the per-clump grass transition (12, range 4–24,
strictly less than Grass Distance). Live admitted records supply explicit tree/grass/detail
categories; asset filenames never select live visibility policy. Both active
and hidden cached meshes update on reapply. Fog completes four cells before
the shorter terrain/tree horizon, with the existing weather-scaled onset;
grass retains its earlier local fade. The tree horizon must exceed maximum
camera distance by more than four cells. No generation identities, reserves or
circulation supply change.

Step 2 leaf-grass controls are in `NatureSettings`, applied on restart/scenery
rebuild to loaded expeditions too. Short, medium and tall height ranges default
to 0.08–0.16, 0.16–0.30 and 0.30–0.48 cells above ground. They blend smoothly
through a seeded geographic field; `grass_patch_cells` (16, range 4–48 cells)
sets patch width. `grass_base_clearance` (0.10, range 0.02–0.30 cells) sets the
minimum stem/exposed-root clearance, enlarged for scaled stems. Canopies do not
clear entire ground cells. Shared-cell grass retains the main plant's endpoint,
organ graph and role; adding clumps never adds an emanator reserve.
`grass_ground_strength` (0.35, range 0–1) controls inexpensive terrain-colored
fiber/patch detail as leaves fade, shared by detailed and temporary ground.
Grass fades in its foliage shader with world-anchored stippling; whole-batch CPU
culling happens 16 cells beyond the visible grass endpoint to avoid chunk rings.
Blade-study materials retain their existing native fade path.

October 31 streaming bounds (`View3DSettings`, reapply/restart; presentation only):
`active_chunk_radius` (3, range 3–16) caps requests in a player-centered square,
measured in 16-cell chunks. Once this nearby queue drains, ordinary chunk
generation stops; moving toward missing chunks brings them into range and resumes
work. Camera changes can request missing coverage only inside that same radius.
`chunk_unload_buffer` (1, range 0–2) retains departure
rings without generating them. `max_resident_chunks` (128, range 64–512) bounds
active + hidden + retiring + preparing detailed chunk nodes. The live queue
reserves the configured hidden-cache allowance and one preparation slot; nearest
player coverage takes priority when the cap truncates the frustum request set.
Keep enough capacity/radius for the chosen view distance; aggressive settings can
truncate visible coverage and need playtesting. Temporary ground retains its
separate bounded cache. Existing `chunks_per_frame`/`chunk_work_ms` still bound
publications/cooperative preparation; a single indivisible operation may overrun
the deadline. F3 now shows resident totals, started/completed/cancelled jobs, work
frames and current road/cell/geometry progress. No saved contents are evicted.

October 31 ground-flow appearance: live Vastra surface ports are seeded inside
their owning tiles and external paths use densely sampled curves. Current Path
Variation controls the bend; zero straightens it. Particle Filaments Visibility
now defaults to 0.30 and the legacy Current Opacity preset to 0.25 for more
transparent strands. These are presentation settings; runtime resource edits
retain their existing immediate refresh behavior.

The default player uses `scenes/customizable_base.tscn`. Its **Skin Color** applies
when the adapter is prepared; `prepare(height)` retains the player's existing
height and ground anchor. It now loads the owner-supplied low-poly human from
`assets/characters/human_low_poly/`; this mesh has no appearance blend shapes.
A customization menu and saved appearance are not connected.
The supplied rogue clips now own idle/walk/run body motion on this model. The
procedural movement/stride/foot-IK controls apply to older procedural adapters;
they do not override this model's authored animation. Actor travel stays unchanged.

## Nature alpha execution — October 31, 2026

**Vastra Settings → Ambient Overflow (Provisional)** exposes enabled routing,
concentration points per transferred unit (default 1.0) and per-tick work budget
(default 64 arrivals and 64 relays). Transfer speed uses the existing plant packet
speed. These values are captured for a new expedition; domain saves now use version
22. See [overflow accounting](vastra-integration.md#ambient-overflow--october-31-2026).

The main scene's **Expedition Tuning → Readiness Settings** references
`resources/readiness_settings.tres`: enabled mode, movement/preparation/recovery
seconds, blackout threshold, warning/severe fractions, equipped alpha-kit
protection and reserve-buffer seconds. The main scene explicitly enables the
provisional readiness mode; older labs retain their turn fixture. Timings and
protection are captured at battle entry, so editing them cannot change an
already committed action. Existing damage/AP/move-use tuning remains under its
original owners. These are internal playtest values, not final gear progression.

**Nature Field Settings** references `resources/nature_field_settings.tres`:
observation distance (default three cells), listening distance (default six cells),
cooperation duration in seconds and authored
listening/inspection species lists. Affinity does not grant these capabilities.
The first-area seed/grove/bank hints are authoring data, admitted against current
geography; they do not reroll terrain or move saved evidence. Subsequent actions
read the current valid settings; a pending action keeps its captured duration.

The solid-world root exposes **Plant Reserve Cells Per Frame** (1–256, default 64).
It bounds read-only canonical reserve projection onto leaf-instance appearance;
changing it affects update latency, never reserves, plant membership or energy.
Low-reserve leaf saturation/posture is additive to existing wind/event animation.
The [runtime contract](readiness-alpha-contract.md) owns detailed implementation
and validation scope.

## Existing lab and runtime controls

Bellroot concept preview (October 31): Sol Lab's **Bellroot concept test** opens
isolated first-form geometry with live sliders for core diameter (0.25–0.55),
particle-envelope clearance (0.08–0.25), leaf droop (-0.25–0.45 radians) and view
angle (-PI–PI). Diameter/clearance are model metres. Walk and pause use switches;
Tend / inspect cues the gesture. Values affect only this preview and reset on
closing it. They do not change catalog species, saves or modular drafts. See
[Sol Lab](sol-lab.md) for the dedicated scene and focused validation.

Real-time combat experiment (October 31):
`scenes/realtime_combat_trial.tscn` / `scripts/development/realtime_combat_trial.gd`
exposes movement speed (m/s), enemy warning and global attack cooldown (seconds),
and simulation speed. Matching live sliders are available in Development Lab →
Combat / real-time experiment and the standalone scene. Existing committed timers
retain their durations; restart resets encounter state while retaining tuning.
These provisional controls affect only the isolated trial, never expedition saves.
See [trial controls and scope](realtime-combat-trial.md).

## Connected water, mountains and grass — October 30, 2026

`resources/terrain_exploration.tres` / `TerrainReliefSettings` expose channel
length (0 disables), channel half-width, mountain height (0 disables) and mountain
parent spacing, in world cells. These apply to new expeditions and are saved.
Generation 13 requires a new expedition for older development saves. Unsuitable
channels are omitted. See [live terrain](natural-terrain.md#connected-water-and-mountain-ranges--october-30-2026).

Live `resources/nature_biomes.tres` grass height is 0.3 and shared
`MeadowAppearance.blade_width` is 0.03825: 40% shorter and 15% narrower.
Restart/rebuild applies cosmetic grass changes to loaded worlds; canonical
membership and reserves remain unchanged.

## Live foliage patches — October 30, 2026

`resources/nature_biomes.tres` uses **NatureSettings → Foliage coverage** (0–1,
default 0.65). Rebuild/restart applies to current and loaded expeditions. Zero
removes generic foliage bodies while retaining canonical flora and reviewed grass.
Patch centers, local palettes and individual sizes reconstruct from the existing
world seed; these settings change presentation rather than saved membership.

In the plant maker, **Growth category → Generic foliage** and **Generic
circulation → Emanator · live ground cover** author a role-appropriate live body.
The separate **Receiver · anatomy draft** selection remains draft-only. Neither
assigns specialist abilities. Focus one biome and named form to save/enable an
emanator design; comparison views cannot publish ambiguous selections.

## Creative additions: relic concept review — October 30, 2026

Node/vein follow-up: **Structure to view** now includes the original trio and four
reference-inspired families: Split ring, Spire circle, Courtyard ruin and Sanctum
ruin. **Stone material** selects three tints of the owner-selected ambientCG Rock051
surface (Black stone by default, Abyssal stone, Ash-black stone); **Material
tiling** is 0.25–3. **Ancient node carving** selects Square seal, Diamond seal or
Narrow seal. This changes the recessed socket outline, preserving structural
layout and logical port anchors. Raised channel/housing objects have been removed.
The stone mesh owns the perpendicular sidewalls and flat-bottomed etch-outs;
**Square-cut etch depth (m)** controls depth from 0.04–0.12. Restrained Vastra light uses their
vertex mask on the same mesh. Fine normal-map relief still comes from the supplied
surface maps. Recarving applies on rebuild, while energy/condition presentation is
read from the existing lab owners.

**Vastra flow** exposes purpose (family defaults or an explicit override), intake
amount (1–50 units), packet travel time (0.2–3 seconds) and automatic output.
**Send Vastra in**, **Run purpose / output**, and **Reset test supply** operate a
finite, conserved lab circuit. Each node's initial external test supply is 100;
reserve capacity is 100. The clue/relay/layout resource costs are provisionally
12/20/16. Mapped crevice polylines carry actual packet heads/tails; node inspection,
materials and camera do not create energy. Rebuilding resets test energy; local
drafts save tuning only. No production ecology or expedition format changes.

Definitions: `resources/scenery/relic_clue.tres`, `relic_relay.tres` and
`relic_layout.tres`; shared node: `scenes/relic_vastra_node.tscn`; visual mapping:
`scripts/scenery/procedural_relic.gd`; authored textures:
[relic material provenance](../assets/relics/ambientcg/PROVENANCE.md).

Open **Development Lab → Creative additions → Creative additions / relics**.
The shared Settings panel provides **Structure to view**, **Show gameplay purposes**,
**Test concentration / 100**, **Test condition: restorative − / disrupted +**, and
**Visual response strength**. Numeric controls have sliders and visible values.

Procedural geometry controls are **Design seed** (0–99999), **Structure scale**
(0.6–1.3), **Missing stonework: intact → skeletal** (0–2), **Stone courses / layers**
(2–12), **Uneven break variation** (0–1) and **Rubble pieces** (0–16). **New design**
advances the seed without resetting other settings. The shared builder is
`scripts/scenery/procedural_relic.gd`; its bounded seeded layouts are visual data,
not geography admission or energy state. The same seed and inputs reproduce the
same layout. Rubble and environmental response do not reroll structural proportions.

Changes rebuild the isolated preview on release and persist as local lab drafts.
**Try a test** includes healthy/rich, disturbed, restorative and quiet starting
conditions. Compare and Review use the existing local workstation storage.
These controls affect synthetic concept presentation only; no expedition reserve,
generation setting or ecological policy changes. The current fixture is
`tools/relic_concept_preview.gd`; usage and limitations are in the
[workstation guide](development-workstation.md#creative-additions--october-30-2026).

## Tree leaf shader and dense offshoots — October 30, 2026

In **Plants / maker & library** or the anatomy station, **Tree structure → Tree
leaf cards** selects painted shader cutouts for the small canopy leaves. Turn it
off for the mesh-leaf comparison. Releasing a structure/fullness slider rebuilds
the specimen; recipes retain the leaf mode. The runtime procedural tree palette
uses cards, connected three-way first forks and paired smaller offshoots.
**Foliage fullness**, **Branching depth**, **Tree fork depth**, branch count and
leaf size tune actual generated foliage. Weather owns wind time, strength and
direction. Cutaway removes leaf cards with outer growth; silhouettes retain their
cutout outlines. Saved baked assets are not rewritten by these defaults.

## Generic foliage authoring — October 30, 2026

In **Plants / maker & library**, **Growth category → Generic foliage** selects
the shared builder. **Review all 20 foliage designs** opens a grid at common
world scale. The biome selector narrows it to five designs; the foliage selector
offers **All five foliage variations** and each habitat's named forms. Select one
named form to edit/save it, or compare that variation across all biomes. The existing size, branch
count, fullness, leaf size/shape and wind controls apply to the draft. Changes
rebuild the preview; saved recipes retain category and variation. Baseline library
designs use restrained habitat colors and seeded individual differences.

**Generic circulation** selects live emanator anatomy or an unclassed receiving
draft, with no specialist class. The main role picker is locked in this mode and
specialist controls are hidden. Save/load is available for one biome and form.
Publishing is enabled only for the emanator role; receiving studies remain drafts.
Live bodies share canonical ground-cover cells as described above. Switching to
**Role forms** restores normal role authoring.

## Procedural plant lab — October 30, 2026

`scenes/plant_biome_role_lab.tscn` is the **Plants / biomes & Vastra anatomy**
fixture. It provides grouped numeric controls in the workstation sidebar.
Hover labels for help; tree/woodland/heath-only controls carry an applicability
suffix. Release a slider to rebuild while retaining the selected sample.

| Group | Controls and ranges |
| --- | --- |
| Plant structure | Height ratio 0.05–12; spread ratio 0.05–12; tree branch rise -0.3–0.8 world units; stem thickness 0.6–2; radial symmetry 0–1. |
| Leaf shape | Width 0.4–1.8; tip taper exponent 0.3–2.3; edge lobes 0–5; lobe depth 0–0.7; droop 0–1.2; woodland frond pairs 3–12; heath thorn length 0–2. |
| Vastra anatomy | Conductor thickness 0.6–2; organ height 0.5–1.5; storage size 0.5–1.6; port radius 0.5–1.8; root reach 0.5–1.5. |
| Seed, size and motion | The seven inherited controls listed below. |

Unspecified units are multipliers or shape coefficients. Physical organ size and
root reach do not change saved capacities, exchange rates or recipient ranges.
Dense woodland fronds use bounded stem/crown counts to keep extreme tuning within
the lab's geometry ceiling. **Reset shape controls** restores numeric shape defaults
while retaining seed, selected biome/role and review choices. **Silhouette view**
uses black plant geometry against a pale background for comparison; it changes
no materials outside this fixture. Cutaway and organ-label switches remain.
Its local biome and
role/class selectors preserve their selection across sidebar rebuilds. Cutaway
also toggles immediately in the fixture. All changes are isolated art settings;
anatomical graphs and their exposed anchors do not create ecological transactions.

`scenes/procedural_plant_lab.tscn` exposes the controls also shown as sliders in
the development workstation's **Plants / procedural forms** fixture. Seed
(1–1000), branch count (3–14), plant size (0.02–20), leaf size (0.02–12), foliage
density (0.4–1.8), curl (0–1) and wind strength (0–2) apply on release through a
fixture rebuild. Labels use a switch; growth forms use the fixture selector.
Sizes/density are unitless multipliers. Seed affects only this isolated art study.
Pause freezes wind. No expedition or saved ecological values are changed.
See [procedural plants](procedural-plants.md) for implementation and limits.

The maker's **World use** group has height 0.02–20 and spread 0.02–12 world units.
These sliders use logarithmic spacing for useful control at small sizes. Keep
**Preserve proportions** enabled for natural uniform fitting; disable it to
set height and spread independently. The old 1.5-unit ground-plant height cap
is removed. Tiny/groundcover/low/shrub/tree presets provide ordinary scales;
20-unit plants are exceptional rather than the normal randomized result.
Randomized ground plants request 0.04–1.8 units; randomized reservoir trees
request 1.8–7.5. Actual size can be smaller when preserving natural proportions.
Tiny previews have a smaller platform and close camera; size edits reframe the
maker. Saved definitions and live placement use the same scaling function.

## Geographic terrain materials â€” October 29, 2026

The active NatureSettings resource (including `resources/nature_cohesive_sample.tres`)
owns the **Terrain materials** group: enable, shared color-layer array, repeat size
in world cells, color strength, detail contrast and texture depth strength. Rebuild/restart applies to
existing expeditions too; these are presentation settings, not saved generation
parameters. The default uses all thirteen licensed ambientCG sets through compact
1024px mipmapped color layers in `resources/terrain_palette.res`.

Both full terrain and streaming coverage share absolute geographic coordinates,
the existing 128-cell geographic scale and expedition seed. Biome and trail samples
produce shared vertex soil weights; slopes use interpolated world normals. Paths
blend into the ground instead of adding square paving overlays when enabled.
Rock uses triplanar mapping. Texture coordinates never restart at tile/chunk edges.
`terrain_cliff_start_degrees` (32) and `terrain_cliff_full_degrees` (52)
control the smooth grass/soil-to-rock transition using shared vertex slopes.
Start must be nonnegative, full must exceed start and remain at most 89 degrees;
rebuild/restart applies to detailed and streaming terrain. The existing rock
color, normal and displacement layers remain paired.
Existing water/shore ownership, terrain geometry, collision and traversal remain
authoritative. Texture depth strength (default 0.5, zero disables) blends the
supplied ambientCG OpenGL normal maps from `resources/terrain_normals.res`.
Normals share color's geographic selection, soil blend and triplanar coordinates
on both render distances. Terrain relief depth (default 0.0225 of a texture repeat, range 0–0.1) adds
12-step interpolated parallax from the supplied Displacement maps in
`resources/terrain_heights.res`; zero disables it. Color and normals share the
offset. This adds view-dependent surface relief, with extra texture sampling cost.
  No height is inferred from color; geometry and collision are unchanged.
  `terrain_relief_distance` (56 cells) and `terrain_normal_distance` (88 cells)
  fade depth/normal detail over the last 40% of their ranges; 0 keeps full detail.
  Both accept 0–128 cells and apply on rebuild to detailed and streaming terrain.
Rebuild all three arrays with `tools/bake_terrain_palette.gd` using a graphics-enabled
Godot run, not the headless dummy renderer. Sources/license/hashes are recorded in
`assets/terrain/ambientcg/PROVENANCE.md` and its manifest.

Development labs are standalone: open their scenes with F6. October 31 owner
direction removes lab buttons and lab shortcuts from the main game while retaining
all authoring code. The old switch remains available only to explicit isolated
tests. See [workstation controls and isolation](development-workstation.md#standalone-access-and-retained-switch-tests).

## Vegetation registration ownership â€” October 29, 2026

Every generated living plant must reference a canonical Vastra cell; membership
supports circulation, repair and vegetation/Vessel ecology. See the
[system hierarchy contract](vastra-integration.md#generated-vegetation-registration-and-system-hierarchy).

| Control | Application and ownership |
| --- | --- |
| NatureAssetEntry â†’ Living | True for living vegetation; false for rocks, logs and dead wood. Restart/rebuild applies to visual admission. Asset filenames do not classify plants. The fixed bounded pond's coverage is also generation evidence: changes require admission review. |
| NatureSettings â†’ Nonliving Trees | Explicit dead-tree art list. Restart/rebuild applies to visual endpoints; it cannot erase the canonical tree-slot reserve. |
| Meadow density / art palettes / plant model paths | Presentation only. Clumps share their cell's flora_id and saved reserve. These controls cannot create energy or unregister canonical flora. |
| Existing saved flora policy / active radius / work budget | Continues to bound service and admission. Registration does not enable offline refill or unlimited whole-world simulation. |


## Main-game lighting â€” October 29

`WorldSolid.vegetation_appearance` selects specialist plant models, height/width
limits and material tuning for streamed scenery. Restart/rebuild applies art
changes. Specialist seed/cell identity determines each body throughout visible
chunks, independent of player distance, ecology enablement and the nearby
activity-cue budget. Chunk eviction reconstructs the same placement. Simulation
radius and activity pulse limits continue to govern effects and work only.

The temporary HUD **Show night / Show day** button overrides the displayed phase
for lighting review. **Resume cycle** restores the configured saved-clock cycle.
This session-only preview does not modify the Atmosphere Settings resource or saves.

The main `world_3d` scene already uses `resources/atmosphere_settings.tres`.
Its **Painterly Lighting** group now controls Filmic tone mapping, sky ambient
enablement/contribution, mood enablement, `lighting_mood` and `mood_strength`.
Default: Filmic on, sky fill 0.65, welcoming palette at 0.715; day/night ambient
energies 0.55/0.22 and base exposure 1.2. Color/light factors apply once after
the saved-clock/weather calculation. Night factors cannot increase moonlight,
fill or exposure beyond the configured base. These controls are presentation only.

Save the resource and restart the main game to apply, including to loaded worlds.
During a running editor session, reapply with `apply_atmosphere_settings()` when
needed. Disabling mood removes its multipliers; disabling sky ambient and Filmic
restores their respective color-only/linear modes. Weather and mood multiply depth-fog onset while keeping the far horizon fixed; the mood's exponential fog-density field is specific to the study.
Mood palettes expose `fog_start_scale` (0.4â€“1): neutral/welcoming 1, wondrous 0.85, mysterious 0.65, blended by mood strength. Clear weather keeps the default first 64.6 cells free of depth fog; overcast and rain blend toward closer haze using the saved weather transition.
Pixelation remains off. The custom leaf shader and automatic situation transitions
remain in the study; the main game currently uses a static selected light palette.

## Painterly forest study â€” October 29

Pixelation is currently parked. For color work, run `scenes/forest_style_preview.tscn`.
Under **Situation and mood**, set `mood_enabled`, `initial_mood`, `mood_strength`
(0â€“1) and `mood_transition_seconds` (0â€“10 seconds). The `mood_palettes` list points
to editable `resources/moods/` resources. The pre-test strength is **0.715**,
10% above the preferred 0.65. Night mood energy/exposure cannot exceed its base.
Each palette owns leaf tints/saturation,
sun/ambient/fog color multipliers, light/fill/exposure scales and fog density.
These are validated presentation values, not gameplay rules. Save and restart
after Inspector edits. Z/X/C/V smoothly select neutral/welcoming/wondrous/mysterious
at runtime; an interrupted transition starts from the visible blend. Disabling
mood or using strength zero restores the underlying time-of-day treatment.
The main expedition has no automatic situation-to-mood wiring yet.

Run `scenes/forest_style_preview.tscn` with F6. Its `foliage_material` references
`resources/painterly_foliage.tres`; expand Shader Parameters to tune world-meter
wind strength (0â€“0.3), wind speed (0â€“3), direction, backlighting (0â€“1), lower/upper
leaf tints, gradient strength (0â€“1), color variation (0â€“0.3) and roughness (0â€“1).
Restart the preview after resource edits. The adapter supplies imported leaf
textures/colors, UV transforms, cutout threshold and local mesh height bounds.
Leave `preview_time` negative for animation; a nonnegative value freezes the wind.
Scene controls select the visual scatter seed, initial noon/sunset/night condition
and baseline comparison. These affect only the standalone art study, with no
expedition/save effect. See [forest study](forest-style.md) for controls and scope.
Select the root of `scenes/forest_pixel_preview.tscn` in the Inspector and expand
**Saved Filter Defaults**. `pixel_filter_enabled` turns pixel enlargement on/off;
`effect_mode` selects smooth, 1.25Ã—, 1.5Ã—, 1.75Ã—, 2Ã— or the deeper 3Ã— option.
Disabling pixel enlargement retains its selected strength. `nearest_textures`
independently switches texture sampling; `painterly_style_enabled` selects the
initial foliage/lighting treatment. Save the scene (Ctrl+S) and restart to apply
these defaults. The saved default is smooth, with the light 1.5Ã— preset retained
for enabling later; nearest textures are off and the painterly treatment is on.
Preview buttons, checkboxes and keys 4â€“9 work immediately during a run but do not
overwrite saved defaults. These settings currently affect only the art preview;
they are not expedition/game Options controls. The HUD stays at native resolution.

## Audio hierarchy â€” October 29

The world scene's `audio_settings` references `resources/audio/game_audio.tres`.
Root controls own the 1â€“64 shared one-shot budget, 0â€“5 second bed crossfade,
close/wide camera distances (ordered, in cells), inherited atmosphere/detail zoom
gains (0â€“1), and default Master/category volume percentages. Cue resources own
stream assignments, category references, local trim (-60â€“0 dB), looping,
positional playback, audible radius (1â€“200 cells) and cooldown (0â€“5 seconds).
Approved menu, combat, ambience and rain streams are assigned. Footsteps are
disabled at the owner's request until revisited; music and foliage also remain
unassigned and silent. Restart applies resource
edits, including to loaded expeditions. Options volume changes apply immediately
and persist separately in local audio preferences. The listener follows the
camera: wide zoom favors atmosphere and close zoom favors footsteps/foliage.
See [audio framework](audio-framework.md) for ownership, event slots and limits.

## Reformat scenery â€” October 28

The world scene's `scenery_settings` references
`resources/scenery/woodland_shelter.tres`. Its stable key, absolute preferred X
cell, bounded candidate count and shared module budget apply to new expeditions
and are captured in save format 4 / generation 9. Required clearings come from
`resources/scenery/required_spaces.tres`, shared with nature dressing, and are captured with their seed and
absolute bounds. Loaded expeditions retain those layout settings, including
required spaces. `shelter_roof_trim` on the solid world scene is cosmetic;
rebuild/restart applies it to both new and loaded worlds without changing
reservations or identity. The default site is an open woodland shelter with no
interaction/reward rules.

## Early moves, supply and hybrids â€” October 28

The 50-move library and explicit species kits follow
[early combat move principles](early-combat-moves.md). Select each `SolMove` in
`resources/move_library.tres`:

| Control | Allowed range / connected effect |
| --- | --- |
| Max Uses | 1â€“40 successful uses per encounter; independent per side and move identity |
| Action Points | 1â€“12 for active moves; exactly zero for automatic equipped passives |
| Damage Percent | 25â€“125% of shared direct damage; light early attacks use 40â€“70% |
| Secondary Effect / Power | None, one shared terrain tile, or a 1â€“20% buff/debuff/protection after the primary hit/heal |
| Passive Kind | Guard or renewal for a passive move; Power is HP blocked/healed per useful trigger |
| Description | Authored tactical purpose shown in battle/loadout tooltips |

Battle Settings also exposes Exhausted Move Fallback: Action Points (default 4,
1â€“12 and no higher than the turn budget), Damage Percent (40%, range 25â€“75%) and
Reach (1, range 1â€“3 clear cells). These apply at the next battle and are included
in displayed snapshots and development fixtures. Its zero power and absence of
imprint/Vastra activity are the fallback contract rather than separate sliders.

Costs, supply and effect metadata are snapshotted into remembered moves. Existing
individuals retain their definitions; use a new expedition to test edited library
values and the three new remembered alternatives per species. Spent uses reset
at battle entry, not each turn, and are not expedition-save attrition. Original
four-slot equipment and individual affinity remain unchanged. Reaction limits and
hybrid effects are connected domain rules, not presentation-only sliders.

## Eighteen-class first-form content

The shared `resources/sol_species/catalog.tres` now has one first-form record per
current class. Records 0007â€“0018 link twelve distinct `scenes/sols/` models,
provisional reference stats, seven-move pools, ecology and ground traversal.
See the [Sol Bible index](reference/sol_bible.md#authored-species-index) for canonical
sheets. Existing typed stat, pool, temperament and clearance controls apply;
admitted individuals retain saved stats/moves/affinity. Models use inherited
scale (0.65), idle/action/step/turn controls and apply after view rebuild/restart.
Resize or reshape a body only with a corresponding clearance/envelope review.

The normal-world preset authors each additional trail home and that individual's
affinity. The companion behavior resource selects `<species>_moment` idle branches;
existing global rest/moment timing controls remain connected. All twelve new
traversal policies are ground-only. Habitat text or gliding anatomy is not an
unused flight, digging or ecological slider.

Class settings include a separate Eldritch definition at fixed zero potency.
Nonzero bounds reject while its passive remains unauthored; this is an admission
constraint, not a promised balance control. Legacy Stonebound keeps its existing
definition. An eventual Eldritch passive requires authored mechanics and an
intentional change to that constraint.

## Combat action budget â€” October 28

| Control | Default / range | Connected effect |
| --- | --- | --- |
| Battle Settings / Action Points | 6 / 1â€“12 points | Shared turn budget, refilled only when an actor starts its turn |
| Battle Settings / Speed Per Movement Point | 10 / 1â€“100 Speed | Effective Speed per free movement point, rounded down at turn start |
| Battle Settings / Movement Points | 3 / 1â€“8 points | Cap on Speed-derived free movement, before class/disruption adjustments; extra movement spends AP |
| Battle Settings / Seal Action Points | 4 / 1â€“12 points | Seal affordability/cost; failure still ends the turn |
| Move Library / each SolMove / Action Points | attacks/healing 4, setup 2 / 1â€“12 points | Cost of each accepted move; positive costs bound repeated actions |

Battle settings apply at the next battle, including after loading an expedition.
Move costs are snapshotted in admitted/learned movebooks; start a new expedition
to review library authoring changes. Missing snapshot costs use effect defaults.
The AP HUD, route preview, enemy planning and domain execution share these values.
Speed changes do not refill movement mid-turn. See [turn rules](combat-action-budget.md).

## Vastra glow and local light â€” October 29

Current Path Variation (1, range 0â€“1) varies real transfer attachments from lower
trunk to crown, with independent heights at either tree and seeded sideways bends
and unequal arches. Grass-to-tree strands can rise through the middle heights.
Zero returns the ground/crown attachment pattern. Applies within 0.5 seconds,
including loaded expeditions; recipient choice, allowed distances and arrival
ticks stay with the saved circulation policy. Paths remain stable across camera
movement and rebuilds. No orbs, bloom or scenery lighting are re-enabled.

Current Flow Spread (0.6, range 0â€“2) widens real streams and increases their
sideways wiggle amplitude with distance traveled from the source. Smooth moving
noise produces irregular bends rather than a steady rhythm. Spread saturates after four ground-reach distances;
opacity softens with width. Live edits rebuild within 0.5 seconds. Plant/tree
Details now shows its live stored Vastra reserve, including fractional refill,
transfer/repair drops and incoming energy; other cells retain concentration.
Numbers can exceed capacity when relay energy queues; the bar fills to capacity.

`VastraSettings` â†’ Current Motion and Particles exposes Current Emission Energy
(0, 0â€“8 HDR multiplier), Current Light Limit (0, 0â€“8 pooled lights), Current
Light Energy (2, 0â€“8) and Current Light Range (2.5, 0.25â€“6 terrain cells).
These apply every frame, including loaded expeditions. The main 3D environment
disables bloom at the owner's request. Strands and motes share emission strength; real shadowless colored
lights follow a spatially separated selection of visible motes, inheriting their
opacity, Sol clearing and source-transition fade. Zero light limit or energy
disables scenery illumination independently of emission. Hiding currents, removing
the mote budget or entering a heatmap hides their lights. Short shadowless ranges
limit cost but cannot occlude light behind walls. No ecological state is changed.

## Vastra combat and restorative conditions â€” October 28

`resources/vastra_settings.tres` now connects signed relaxation (both signs toward
zero), restorative maximum bonus and half-strength, environmental concentration
damage scaling, and local current enable/count/radius/opacity/refraction. Numeric
defaults remain provisional. Simulation settings apply to active ticks, including
loaded worlds; restart to change current enable/count. Radius, opacity, refraction
and palette edits apply within 0.5 seconds. Currents sample only a
bounded local view and never write ecological state.

`SolMove` resources in `resources/move_library.tres` expose Vastra Powered,
Aggressive (for terrain/support abilities), Overload Points and Restoration Points.
Aggressive damage, poison and debuff effects are inferred from their effect type.
Amounts apply per actually affected tile; healing works independently of HP healed.
Saved movebook snapshots retain authored values; omitted fields use the new
provisional defaults. Start a new expedition to review changed library authoring.
The signed storage envelope is currently -100..100, not finalized balance.
See [Vastra integration](vastra-integration.md) for ownership and acceptance limits.

Current rendering separates broad refractive density from sparse traveling wisps.
Both consume existing concentration, signed overload and tile affinity without
changing saved state. Geographic ownership uses 12-cell regions independently of
render chunks; there is no explorer-centered manifestation radius.

`resources/vastra_settings.tres` exposes Current Region Limit (6, range 1â€“8) and
Current Limit (18, range 0â€“64 junctions). Region selection is ordinary camera
streaming; retained regions do not reroll. Each geographic owner admits at most
16 stable vegetation samples after complete scenery coverage becomes available.
The global node budget is divided independently of the visible group count.
Current Web Links (2, range 1â€“3) links each group to nearby groups in addition
to the connected backbone. Connections use facing outer branches rather than
one central hub. Local tributaries stay open; alternate routes weave between
whole groves. Current Connection Visibility (0.35, range 0â€“1) keeps those links
perceptible between living regions, without raising unrelated empty terrain.
The revealed-field heatmap includes the same corridor support. Current Haze
Strength (0.4, range 0â€“1) adds affinity-tinted cloud layers around the threads.
These controls apply within 0.5 seconds and create no ecological energy.

Current Spacing is 3.5 cells (2â€“8), Current Width 2.4 (0.1â€“4), Hover Height 1.4
(0.2â€“4), and Life Radius 3 (1â€“6). Geometry settings refresh within 0.5 seconds.
Width controls tapered open layers and finer tributaries; three unequal veils
overlap through each shared region, with wider haze along inter-grove links.
Shared regions use no closed ellipsoid shells. Hover Height also spreads
tributaries vertically. Fixed broad asymmetric curves provide spatial depth.
Vegetation creates visual support; living wild/companion Sols clear it through
Sol Dissipation Radius (1.6, range 0.5â€“4), without ecological consumption.
Empty Visibility is 0.03 (0â€“0.2) for residual optics where vegetation is absent.

The authored optical preset uses Opacity 0.5, Distortion 0.006, Fine Detail 0.9,
Flow Speed 0.75, Aberration 0.6, Glints 0.4, Pulse Strength 0.1 and Pulse Seconds 6.
The owner found the earlier preset too faint. Wisps now retain a continuous
low-level trace between broader traveling packets, with higher transparency
ceilings (0.55 for wisps, 0.22 for refraction) and stronger colored emission.
Opacity zero hides both layers; distortion zero removes refraction; aberration
zero removes chromatic separation. Sun direction/color/energy come from the
existing atmosphere. Nighttime wisps retain restrained affinity emission.
Fine Detail also reveals layered astral mist and irregular threads; Glints
controls sparse star-like pinpoints as well as sunlight highlights, following
the owner's Milky Way reference. Both use the existing bounded noise texture.

Wind Velocity (0.7, 0.12, 0.25), maximum magnitude 4, supplies path tangents and
optical transport speed. Attraction (0.8, range 0â€“2) modulates optical transport;
local concentration potential sets inward direction independently of the camera.
Flow Speed zero freezes transport; the independent pulse uses saved active time.
These are presentation controls, not gameplay forces or a fluid simulation.

Current Debug View selects Normal, Concentration Heatmap, or Revealed Field
Heatmap. The former shows actual concentration; the latter projects vegetation
support and Sol clearing separately. Neither writes simulation state. Invalid
live tuning suspends all layers. Enable/count changes require a restart when the
renderer was initially disabled. Reproduction and measured limits live in the
[resource evaluation](research/vastra-resource-evaluation.md#world-foundation-delivery).

## New first-form workshop models

Ashquill, Rattlehorn and Rimefold have isolated review scenes under `scenes/`:
`ashquill_workshop.tscn`, `rattlehorn_workshop.tscn`, `rimefold_workshop.tscn`.
Open one with F6. Their Model Scene fields point to distinct direction-B builders
under `scenes/sols/`; select that model scene's root to edit inherited typed
controls. Their models are now also connected to normal gameplay through the
shared catalog, retaining their small first-stage scene settings.

| Control | Units / allowed range | Connected effect |
| --- | --- | --- |
| Model Scale | uniform multiplier, 0.5â€“1.5; authored default 0.65 | Small first-form visual scale; not final height, footprint or evolution logic |

The workshop validates inherited model tuning before building. Restart/rebuild
after editing scene files. The workshop's Walk Speed (0.1â€“2 m/s), Exercise and
Affinity fields affect only review. G/J/H cue signature/attack/hit. No flight or
swimming capability is implied by anatomy or by an isolated workshop exercise.
See [anatomy review](sol-creature-anatomy-review.md) for selection and evidence.

### Applied species records and sightings

Edit `resources/sol_species/ashquill.tres`, `rattlehorn.tres`, or `rimefold.tres`
for reference-level stats, existing-move pools, ecology and ground traversal
clearance. These are the existing typed Inspector controls and runtime validation;
no second balance table or species-affinity setting was introduced. Provisional
reference stats/moves apply to new admissions, while saved individual traits and
movebooks remain intact. The existing training-capacity value is provisional,
not an approved family count. Scene scale changes apply after view rebuild/restart.

`resources/sol_world_sightings.tres` now includes the three explicit homes at
trail x=22/40/56 and their individual affinities. Placement edits do not relocate
saved identities; new species are admitted through normal new/load initialization.
`resources/owned_companion_behaviors.tres` selects preening, testing footing and
fin investigation for the new species. Global rest/moment timing remains in
the existing companion settings. All three are ground-only in this slice.

## Existing game controls

Normal F5 play now explicitly uses `resources/sol_world_sightings.tres` for
**Expedition Tuning > Sighting Settings**, plus the enabled companion settings.
This adds Crown-Ear, legal-bank Reedback and Bellroot while retaining wilderness
and the existing behavior defaults. Tune the new world preset for the normal
game; `resources/sighting_settings.tres` remains the legacy comparison preset.
See [normal-game rollout](sol-species-data.md#normal-game-rollout) for placements,
save admission and ownership continuity.

Owned companion controls are now under **Expedition Tuning > Companion Settings**:
selected owned following with species flight/swimming, preferred admission side,
stop/resume distances, step duration, bounded search/culling, idle timing and
inherited species moments.
See [owned companion](owned-companion.md) for ranges, save/load reconstruction,
application timing and traversal scope. Species resources tune altitude, draft and
body clearance on selection/load; Step Seconds tunes owned transitions. Ownership
and combat remain unchanged.


Combat phase 3 adds development-only recipes under `resources/combat_pacing/`.
Open an ordinary/terrain/major recipe in the Inspector to edit existing profiles,
up to four move IDs per side, fixed individual class potency (1â€“10), arena offsets,
blocked/wet/heat cells and initial field lifetime (1â€“20 tactical rounds). Recipes
validate before building and apply to the next probe only; production encounters
and saves do not consume them. The optional `concise.tres` uses the existing
Sol Visual Settings pacing properties (0.15/0.25/0.08/0.15 real seconds for
action/consequence/movement/turn). Select it through the fixture runner's
`-Timing concise`; production defaults are unchanged. See
[encounter pacing measurements](combat-pacing.md) for launch commands, complete
measurement definitions, provisional results and the open owner acceptance gate.

Wild Sol behavior now has an inherited library at **Sighting Settings > Species
Behavior > Behavior Library** (`resources/sol_ecology/behavior_library.tres`).
Species profiles select branch IDs; children inherit a root's movement primitive
and can specialize its response tuning using species/class/affinity filters.
Each response override uses -1 for inheritance. Priority resolves overlap, with
stable specificity/depth/ID tie breaks. Nested live edits refresh on the next
decision; existing deadlines finish first. See [Sol ecology](sol-ecology.md#inherited-behavior-library--october-28-2026)
for exact units, ranges, validation, and the distinction between territorial
defense and future pursuit. No save-version change or new affinity ability.

The [activity correction](sol-activity.md) fixes indefinite near-player watching
and static guards. **Player Reactions** adds Attention Ticks (2, 0â€“16), Routine
Ticks (6, 1â€“16), and Guard Standoff Distance (2, 1â€“3 cells). **Wandering** adds
Patrol Rest Chance (0.35, 0â€“1) and Blocked Goal Retry Ticks (2, 1â€“8); global Rest
Min/Max Ticks now default to 1/3. Existing deadlines finish before edited durations
apply; new decisions/goals use live tuning. Current state domain is 14, save format
3, generation 6. See the linked document for exact behavior and acceptance evidence.

The [natural movement pass](sol-natural-movement.md) replaces Movement Blend
Seconds with **Movement Travel Fraction** (default 1, range 0.25â€“1 of the decision
interval), adds **Patrol Goal Min Fraction** (0.5, range 0.2â€“1 of patrol radius),
and uses domain 13 for the saved patrol counter. Queued steps keep their duration;
new goals/steps use live tuning. World save format remains 3, generation 6.

Wild Sol phase 4 adds **Sighting Settings > Species Behavior** and editable
`resources/sol_ecology/` profiles for behavior sets, caution/spacing/activity
variation, patrol radius scaling, and rest scaling. See
[Sol ecology](sol-ecology.md) for defaults, ranges, live edits, and identity rules.

Wild Sol phase 3 adds **Sighting Settings > Player Reactions** (release distance,
approach resumption, reposition cooldown, settling ticks) and **Encounter Settings
> Warning Delay Seconds**. See [Sol player reactions](sol-player-reactions.md) for
defaults, ranges, validation relationships, and loaded-save behavior. Current AI
response state was introduced in domain version 12; the domain-11 notes below describe the
earlier autonomous-wandering delivery.

Open `scenes/world_3d.tscn`, select the **SolHunter3D** root, and expand
**Expedition Tuning** in the Inspector for simulation resources. **Camera**
contains orbit/tilt/sensitivity, **Player** contains model height, and **3D View**
contains View Settings, Nature Settings and Atmosphere Settings. Expand a resource to edit its values.
**Interface** contains Menu Settings for the field menu's authored defaults.
The comparison scene `scenes/world.tscn` retains an orthographic terrain reference;
the default game view is perspective.

You can also select the `.tres` files below in Godot's FileSystem dock. Save edits,
stop the game, and run again to apply them reliably. Editor changes are not
automatically synchronized into an already running game. Default resources are
shared: editing one affects scenes using that resource. To try a separate preset,
duplicate a `.tres` in Godot and assign it to the root's matching resource field,
or use Make Unique and save the result. Defaults preserve the current behavior.

| Resource / field | Default and range | Effect and save behavior |
| --- | --- | --- |
| Terrain study root / Presets | `scenes/terrain_preview.tscn`; Very gentle / Rolling / Upper relief | F6 shape study only; does not change F5 terrain or expedition saves. See [terrain preview](terrain-preview.md). |
| Terrain study / Study Seed | 2601026; 0â€“2147483646 | Restart the preview to apply. Same seed across all comparison presets. |
| Root Terrain Settings | `resources/terrain_rolling.tres` | New expeditions use copied relief parameters; current saves restore theirs. See [natural terrain](natural-terrain.md). |
| Terrain relief / Broad Scale, Broad Amplitude | 144 cells (64â€“256); Rolling 3.2 cells (0â€“8) | Broad independently seeded landforms; amplitude is not measured peak-to-trough relief. New expedition applies edits; preview rebuild applies them to the study. |
| Terrain relief / Detail Scale, Detail Amplitude | 48 cells (16â€“96); Rolling 0.55 cells (0â€“2) | Secondary landform channel, copied into the expedition's saved relief parameters and the preview snapshot. |
| Terrain relief / Micro Amplitude, Warp Amplitude | Rolling 0.06 cells (0â€“0.15); 8 cells (0â€“16) | Eight-cell micro sampling scale; broad-channel displacement. Zero warp disables it. New expeditions only; saved parameters are retained on load. |
| Terrain relief / Walkable Slope Degrees | 25 degrees; 15â€“35 | Both triangles of each standing cell must pass; shared traversal and spawn/battle admission use it. Saved per expedition. Unsafe essential-route settings fall back to Rolling. |
| Root Menu Settings | `resources/menu_settings.tres` | Restart after editing. Validated defaults for the unified field menu; local remembered preferences override size, position, scale and opacity. Reset Menu Layout restores authored defaults. No gameplay save changes. |
| Window Size / Minimum Size | (940,620) / (660,440) unscaled viewport pixels | Finite bounds: width 620â€“1600, height 380â€“1000; minimum must fit within window size. Drag the corner to resize live. Narrow viewports reduce effective scale and clamp position, with scrollable navigation/content. |
| UI Scale / Background Opacity | 1.0 / 0.97; 0.75â€“1.25 / 0.7â€“1.0 | Options applies these live and remembers them in `user://menu_preferences.cfg`. Opacity affects the panel background; text stays opaque. |
| Remember Layout / Font Size / Colors | true / 16 (14â€“20) / forest, gold, light text | Startup theme settings. Colors must be finite opaque RGB 0â€“1. Disabling Remember Layout suppresses preference reads/writes. |
| `resources/expedition_settings.tres`: Initial Seed | 2601026; 0â€“2147483646 | Startup expedition seed. New Seed continues advancing from the current world's seed; loading uses the saved seed. |
| Move Seconds | 0.28; 0.04â€“1.0 seconds | Time per cardinal tile; lower is faster. Walking and running are about 30% slower again following owner feedback on October 29. Diagonal duration is multiplied by sqrt(2). Applies to loaded journeys too; does not change saved cells or terrain. |
| Territory Size | 16; 1â€“256 cells | Width/height of population home territories for new expeditions. Independent of rendering chunks. Existing saves retain their own territory size and IDs. |
| Population Cache Territories | 256; 1â€“1024 | Runtime summary capacity, applied when starting/replacing/loading state. Lower limits evict cached knowledge sooner, without deleting individuals or progress. Not ecological carrying capacity. |
| `resources/climate_settings.tres`: Moisture Frequency | 0.012; 0.001â€“0.1 | New expeditions only. Lower gives broader moisture/habitat regions; loaded saves retain climate. |
| Dry Threshold / Wet Threshold | 0.42 / 0.58; 0â€“1 | New expeditions only. Dry must be below wet; higher dry expands heath, lower wet expands marsh. Invalid combinations fall back with a warning. |
| `resources/vastra_settings.tres`: Recovery Interval Ticks | 120; 1â€“1000000 | Active ticks per healing interval. At the fixed 0.75-second activity tick, 120 is 90 active seconds. Applies to loaded worlds and their retained interval debt. |
| Recovery Points | 1; 0â€“100 | Signed overload magnitude returned toward zero per interval. Zero disables relaxation; re-enabling can catch up retained known debt. Does not change concentration. |
| Tiles Per Tick | 32; 1â€“1024 | Maximum changed cells serviced per tick. Larger values reduce queue delay but cost more CPU. Applies to loaded worlds. |
| Root Camera Elevation | Script default 35; 10â€“80 degrees | Starting tilt; scene overrides remain authoritative. Middle-drag adjusts live; Home restores the authored value. Runtime adjustment is not saved. |
| Root Camera Azimuth | 0; -180â€“180 degrees | Starting orbit; zero aligns world axes. Middle-drag adjusts live; Home restores it. Runtime adjustment is not saved. |
| Root Camera Drag Sensitivity | 0.25; 0.05â€“1 degrees per mouse pixel | Middle-drag orbit/tilt speed. Read live; invalid values fall back to 0.25. Wheel dolly works during combat; Home restores View Settings' Starting Distance. |
| Root Player Height | 0.85; 0.4â€“2.4 world cells | Scales the supplied grave knight model and contact shadow at startup; half the previous height. Presentation only; no saved identity or collision change. |
| Root Player Model Scene | Empty: supplied grave knight | Restart applies. The grave knight uses its supplied relaxed idle and provisional generated walk/run gaits. Set `scenes/basic_man.tscn` only for the optional procedural-foot traversal fixture. |
| Root Player Procedural Movement | true | Optional mannequin only: live toggle for terrain-aware alternating foot placement and body lean. The grave knight uses its own rig gait. |
| Root Player Step Seconds | 0.32; 0.18â€“0.8 seconds | Live duration of each alternating procedural footstep; running uses 80% of this duration. Slow cadence is independent of travel speed and model size. Short legs release stance locks at their reach limit; swing targets follow the body. Authored locomotion playback is reduced to 25% of its former rate, capped at 0.75x. |
| Root Player Stride Length / Step Height | 0.2 / 0.09; 0.08â€“0.4 / 0.02â€“0.2 of player height | Live procedural foot travel and swing clearance. Stance anchors use absolute terrain coordinates within leg reach, independent of camera rebasing. |
| Root Player Lean Degrees | 8; 0â€“15 degrees | Live maximum smoothed slope and turn lean. Zero disables body lean while retaining stepping. |
| Root Nature Settings | `resources/nature_settings.tres` | Common/hardy trees, rocks and undergrowth PackedScene palettes. Applies to rebuilt chunks after restart; deterministic visual selection from existing terrain data. Invalid settings use defaults. No save changes. |
| Tree / Rock / Undergrowth Height | 3.5 / 0.65 / 0.35; 2â€“7 / 0.3â€“1.2 / 0.1â€“0.8 world cells | Normalizes imported models before deterministic per-cell size variation. Rebuild/restart to apply. |
| Hardy Trees palette | Olive dry-tree placeholder and supplied dead tree | Red twisted-tree foliage removed from the active palette. Cosmetic only; restart/rebuild applies it to current or loaded worlds. See [placeholder assets](../assets/biome_placeholders/README.md). |
| Undergrowth Percent | 12; 0â€“40 percent | Nonblocking visual decoration on free ground outside routes/refuge/landmark. Zero removes decoration on rebuild; obstacle placement and path legality stay authoritative. |
| Root View Settings | `resources/view_3d_settings.tres` | Restart after editing, or call `apply_view_settings()` on the running root to reconfigure. Pure presentation; no save/identity/generation changes. Invalid policy falls back to defaults. |
| Field of View | 50; 35â€“75 vertical degrees | Perspective camera FOV. Replans the visible terrain and tall-asset coverage. |
| Starting / Minimum / Maximum Distance | 22 / 8 / 40; 8â€“40 / 5â€“20 / 20â€“48 world cells | Camera orbit/dolly distance. Minimum â‰¤ Starting â‰¤ Maximum; maximum must be at least 4 cells inside Render Distance. Home restores Starting Distance. Runtime zoom is not saved. |
| Render Distance | 72; 48â€“128 world cells | Camera far clipping depth, frustum streaming extent, and distant fog. Larger values increase terrain/asset work. Turn, tilt, zoom and viewport resize all replan coverage. |
| Stream Margin / Chunks Per Frame | 8 / 1; 4â€“16 cells / 1â€“4 chunks | Prefetch margin and runtime detailed terrain/scenery publication budget. Visible startup/rebuild coverage is prepared synchronously. Near player and camera neighborhoods stay resident; distant chunks are evicted. Temporary ground covers visible queued chunks during turns. |
| Stream Ground Step | 4; 1 / 2 / 4 / 8 cells | Sample spacing for temporary, noncolliding ground while detailed chunks are queued. Coarser samples reduce camera-turn work; skirts conceal seams. Samples use the active world's generated heights/water. Restart/reapply view settings; not saved. |
| Detail Distance / Shadow Distance | 0 / 48; 0â€“128 / 16â€“80 cells | Zero keeps decoration with trees to the horizon; positive values enable whole-chunk decoration culling. Directional shadows are clamped to the far clip. |
| Fog Start Fraction | 0.8; 0.4â€“0.85 | Clear-weather fog begins at this fraction of the fixed horizon, fully opaque 4 cells before the far clip. At the default 72-cell view, begin/end are 64.6/68 cells from the camera. Turns and loading queues do not pull fog closer. Cloudy/rain weather and mood have separate earlier-onset multipliers. Restart/reapply view settings; not saved. |
| Sky Shader / Cloud Primary / Cloud Secondary | `shaders/daylight_sky.gdshader` / clouds 01 / clouds 07 | Day/night shader uses the supplied procedural cloud presets. Seven presets remain available. Atmosphere Settings drives sun/moon, current sky colors and weather. |
| Horizon Color / Sky Color | `#b7d4ed` / `#4387c8`; opaque RGB 0â€“1 | Daytime horizon/fog and upper-sky endpoints; blended with night/sunset/weather colors. Sky remains visible above the fog. |
| Cloud Density / Cloud Wind | 0.65 / (0.1, 0.035); 0â€“1 / -2â€“2 each component | Connected sky shader uniforms. Density zero clears clouds; wind zero freezes their translation. Cosmetic, not saved. |
| Root Atmosphere Settings | `resources/atmosphere_settings.tres` | Restart after editing, or call `apply_atmosphere_settings()` on the running root. Validated copy drives the actual lights, sky, rain and status display. No schema change; visual phase derives from saved active time. |
| Cycle Enabled / Day Seconds / Starting Phase | true / 1200 / 0.38; 120â€“7200 seconds / 0â€“1 phase | Full cycle duration in active exploration seconds. Phase 0 midnight, 0.25 sunrise, 0.5 noon, 0.75 sunset. Disable cycle for fixed-time authoring. Policy edits recalculate appearance without rewriting saved time. |
| Sun Elevation / Azimuth / Energy / Color | 55Â° / -30Â° / 1.25 / `#fff1d9`; 25â€“80Â° / -180â€“180Â° / 0â€“3 | Maximum altitude, world arc heading, relative daylight strength and daytime color. Visible sun and cast shadows share the same direction. |
| Moon Energy / Color | 0.32 / `#a7c9f0`; 0â€“0.8 | Moon opposite the sun; below-horizon light disables. No lunar phase calendar is implied. |
| Day / Night Ambient | 0.6 / 0.28; 0â€“2 / 0â€“0.6 | Relative fill-light energy, with editable day/night colors. Smoothly blends through twilight. |
| Exposure / Shadow Opacity / Shadow Blur | 1.05 / 0.8 / 1.5; 0.5â€“1.5 / 0â€“1 / 0.5â€“3 | Scene exposure and light shadow controls. HUD text remains independent. Sun/moon share View Settings' shadow distance. |
| Night Sky / Night Horizon / Sunset Horizon | `#07162e` / `#263c59` / `#efaa7e` | Opaque 0â€“1 colors. Horizon fog follows the current blended sky, including rain. |
| Horizon Curve / Cloud Scale / Cloud Softness | 0.4 / 0.16 / 0.12; 0.2â€“1.2 / 0.05â€“0.5 / 0.04â€“0.3 | Sky gradient height, projected cloud size and cloud edge softness. Cloud projection fades before its horizon clamp. |
| Weather / Weather Seconds / Transition Seconds | auto / 300 / 20; auto, clear, cloudy, rain / 60â€“1800 / 1â€“60 seconds | Automatic choice is stable for seed and saved time interval. Transition must fit within the interval. Forced modes apply immediately for authoring. |
| Clear / Cloudy / Rain Weight | 0.5 / 0.3 / 0.2; each 0â€“1 | Relative automatic-weather weights; at least one must be positive. No simulation RNG or world mutation occurs. |
| Cloudy Fog Fraction / Rain Fog Fraction / Rain Particles | 0.75 / 500; 0.4â€“1 / 0â€“1200 | Earlier fog onset in rain / bounded nearby CPU streaks. Zero particles disables streaks while preserving rainy sky and lighting. Particle animation is cosmetic and not serialized. |
| `resources/sighting_settings.tres`: Enabled / Wilderness Enabled | true / true | Show/admit trail sightings and local prototype wilderness Sols. Disabling does not delete saved individuals. |
| Visible Radius / Reaction Distance | 28 / 3; 4â€“32 / 1â€“6 cells | Euclidean distance culling / base Manhattan detection band. Species profiles can adjust detection within valid bounds. |
| Bob Pixels / Bob Cycles | 1 / 0.8; 0â€“3 pixels / 0.1â€“3 cycles per second | Idle animation amplitude/frequency. Zero pixels disables it; pause freezes it. No simulation or identity change. |
| Observation Distance | 3; 1â€“6 Manhattan cells | Right-click Observe selects the pointed sighting. Recording requires a settled player within range and visibility radius. Distant and combat inspection show details without recording. Retained first-seen records do not change. |
| Local Movement: Enabled / Interval Ticks | true / 1; 1â€“8 ticks | Run local responses once per interval of the 0.75-second active clock. Disable without resetting saved cells. |
| Home Radius / Movement Radius | 5 / 28; 1â€“5 / 4â€“32 Manhattan cells | Limit distance from fixed home and player-local simulation range. Smaller home range returns gradually; no ID change. |
| Comfort Distance / Flee Release Distance | 2 / 5; 1â€“3 / 2â€“8 cells | Neutral stopping distance and flight hysteresis. Release must be at least Reaction Distance. |
| Movement Travel Fraction | 1; 0.25â€“1 of decision interval | Each queued legal step fills this fraction of cadence Ã— 0.75 active seconds. New steps use edits; authoritative movement cadence is unchanged. |
| `resources/encounter_settings.tres`: Enabled / Automatic Contact | true / true | Right-click Engage and warned later-contact entry for the authored guard. Loaded worlds use current settings; no identity change. R opens the field menu. |
| Warning / Contact / Interaction Distance | 3 / 1 / 3; 1â€“6 / 0â€“1 / 1â€“6 cells | Manhattan warning band, later-step automatic contact, and selected-Sol Engage range. Warning must cover contact. |
| Withdrawal Safe Steps | 3; 1â€“8 successful steps | Prototype automatic re-entry protection. Runtime-only; manual approach remains available. |
| `resources/battle_settings.tres`: Enabled | true | Enable companion choice and Battle button. Applies at scene startup; disabling preserves saved companions. |
| Starters / Opponents | Three unique starters / 1â€“16 unique opponent profiles | Species reference profiles. Starters snapshot on choice; wild profiles on explicit individual profile admission. Saved individuals retain their reference stats, IVs and growth. |
| Arena Radius | 4; 3â€“6 cells | Half-width/height around trainer; default 9Ã—9 arena. Applies to new battles, using existing terrain. |
| Movement Points / Release Range | 3 / 3; 1â€“8 / 1â€“4 cells | Shared cardinal movement per turn / Manhattan deployment distance. Snapshotted at battle entry. |
| `BattleProfile`: identity and display fields | Species, lineage, class, affinity, name, move name | Must be compatible with existing individual metadata. Changing resources does not rewrite saved individuals. |
| Level / Max HP | 3 starters, 1 wild / 36â€“50 species HP; 1â€“55 / 1â€“1000 | Reference level and species health before individual IVs/training. Natural level growth is automatic. Reference profile, resolved stats and current HP persist. |
| Attack / Defense / Special Attack / Special Defense / Speed | Per-profile defaults; 0â€“1000 | Species offense/protection and initiative before IVs/training. Special fields permit -1 to inherit authored physical values. Explicit special values remain independent of affinity. |
| Evolution Forms | 3; 1â€“3 | Number of ordinary forms; final available form unlocks full training capacity. Saved at profile admission, including single-form lines. Does not invent evolution content. |
| Move Power / Move Range | 6 / 2; 1â€“100 / 1â€“6 cells | Neutral physical basic damage and Manhattan targeting, subject to terrain line blocking. |
| Root Sol Visual Settings | `resources/sol_visual_settings.tres` | Shared Sol scale/shadows and combat/UI presentation. Decorative sphere/halo/mote effects are retired; affinity identity and authored neutral cores remain. Reconstruct views after size changes; no save migration. |
| Diameter / Hover Height | 0.75 / 0.7; 0.3â€“1.2 / 0.35â€“1.5 world cells | Pixel sphere size and real 3D center height above ground. Existing sighting Bob Pixels/Cycles settings animate both wild and battle orbs. |
| Aura Opacity / Effect Count / Effect Speed | 0.22 / 5 / 0.6; 0â€“0.6 / 0â€“12 / 0â€“3 cycles per second | Halo strength and bounded decorative motes; zero opacity/count disables the corresponding effect, zero speed freezes effects. |
| Palette | Ten provisional affinity ID â†’ color entries | Uses the saved individual's affinity, with neutral white for unknown IDs. Custom opaque colors are supported. Species/class never select the color. |

The subsequent [affinity and moves implementation](affinity-moves-imprints.md)
replaces the ten-color default palette with the eight approved color directions
(exact RGB remains art tuning), including animated pink/cyan Quantum orbs.

| Move Library control | Range / application |
| --- | --- |
| Root Move Library | `resources/move_library.tres`; restart after authoring changes. Invalid libraries fall back to the default prototype library. |
| Moves: ID / name / affinity / effect | Explicit authored identity and effect kind. Affinity is independent of the learner. Saved remembered definitions do not reroll. |
| Move power / reach / duration | 0â€“100 HP power or healing / 1â€“6 Manhattan cells / 1â€“1000 tactical rounds. Field actions currently affect a target and its legal cardinal neighbors. |
| Species Pools / Starting Moves | Up to 32 move IDs per species; starting moves must be in the pool. First four start equipped. Newly admitted books snapshot eligibility and initial definitions. |
| Recovery Interval | 1â€“1000 active 0.75-second ticks per recovery stage; default 8. Captured in each saved condition, so later edits do not rewrite existing recovery debt. |
| Field Damage | 0â€“10 HP per tactical round; default 2. Shared Fire/Lightning effects; applies to new battles. |
| Rough Cost | 1â€“4 movement points per cardinal tile; default 2. Applies to new battles. |
| Assisted / Resisted Cost | 0â€“1 / 1â€“4 movement points; defaults 0 / 2. Currents, winds and warp zones affect both sides. Applies to new battles. |

Move Library also exports World Condition Timing multipliers, each 0.25â€“4Ã—:
rough 1.5Ã—; favorable flow 0.75Ã—, opposed flow 1.5Ã—; vertical warp 0.5Ã—,
horizontal warp 2Ã—. The base Move Seconds remains adjustable. These are prototype
defaults, not finalized balance or a change to generated terrain legality.
Sol Visual Settings also exports Imprint Opacity (0â€“0.5, default 0: hidden after combat); zero
hides the local ground tint without deleting saved affinity.

The [battle feedback slice](battle-feedback.md) adds Sol Visual Settings controls:

| Control | Default / range | Application |
| --- | --- | --- |
| Feedback Enabled | true | Suppress new floating cues when false; existing cues finish fading. |
| Feedback Seconds | 0.9; 0.25â€“2.5 seconds | Real-time cue lifetime, including while exploration is paused for battle. |
| Feedback Rise | 0.6; 0.1â€“2 world cells | Floating text travel; applies to active cues. |
| Feedback Limit | 16; 1â€“32 cues | Retire oldest cues on admission; bounds visual node growth. |
| Result Panel Enabled | true | Show the next runtime outcome recap. Does not affect commits, saves, or exploration pause. |

The [wild recovery slice](wild-population-recovery.md) adds the root's Wild
Recovery Settings resource (`resources/wild_recovery_settings.tres`):

| Control | Default / range | Application |
| --- | --- | --- |
| Interval Ticks | 2400; 0â€“1000000 active ticks | 30 minutes at 0.75 seconds/tick. New victory/acquisition and historical-revisit waits capture an absolute deadline. Zero disables new waits, preserving old commitments. |
| Local Radius | 14; 4â€“32 cells | Due authored homes activate only within this distance, on free legal ground. Does not change IDs or deadlines. |

Restart after editing for consistent policy setup; live changes refresh on the
next active tick. Saved deadlines retain their original timing. Invalid initial
resources fall back with a warning; invalid live settings suspend admission.

Battle settings are read for each new battle; restart after editing live resources
to refresh chooser labels and the Enabled switch. Current battle settings and
profiles are frozen for that battle. Refuge H recovery uses the chosen saved HP
ceiling. The same Withdrawal Safe Steps tuning controls saved post-battle
protection, while preview withdrawal protection remains runtime-only. See
[first playable battle](first-playable-battle.md) for provisional stat scope,
controls, persistence, and validation evidence.

Hover properties for their Inspector tooltips. Recovery defaults are provisional
development tuning, not finalized ecological balance. Climate, movement, seed,
territory, cache, and recovery inputs are validated at runtime, including resources
assigned through code. Invalid expedition/recovery resources use defaults and warn
once per simulation instance; missing climate resources use the existing fallback.

`SolSpeciesDefinition` also appears as a creatable typed Resource with species,
lineage, class, ordinary form, and footprint fields. These are authored content
contracts, not an approved roster. Do not create a fourth ordinary form for a
legendary manifestation. Production regional capacities, harvesting budgets,
population recovery curves, and wildlife generators are not yet implemented as
connected authoring controls; this change adds no speculative sliders for them.

Schema/generation versions, identity formats, render chunk geometry, the activity
clock contract, and corruption/admission safety ceilings remain engineering
constraints. Changing those requires an explicit implementation/compatibility
change rather than treating them as balance values.

## Standard for future work

The [AI, Seal and progression slice](ai-seals-progression.md) adds:

| Control | Default / range | Application |
| --- | --- | --- |
| Battle Settings: Seal Power | 10; 1â€“100 | Frozen per new battle; same probability in preview and execution. Supply remains unlimited testing supply. |
| Battle Settings: Commander Run Speed | 6; 1â€“10 world cells per real second | Applies to the next battle's validated outside route. Deployment waits for arrival; no exploration ticks or Sol movement costs. |
| AI Hazard Weight | 2; 0â€“10 | Penalty per expected shared field damage; lethal risk is tripled. Frozen per new battle. |
| AI Heal Weight | 0.25; 0â€“2 | Source aggressive heal benefit relative to damage; frozen per new battle. |
| AI Field Weight | 2; 0â€“10 | Provisional useful shared terrain benefit; damaging fields multiply this by 1.5. Frozen per new battle. |
| Root Progression Settings (`resources/progression_settings.tres`): Threshold Factor | 10; 1â€“100 | Cumulative XP threshold = factor Ã— current levelÂ². Restart/load refreshes policy, retaining saved XP and stats. |
| Victory Base / XP Per Enemy Level / Minimum XP | 4 / 3 / 5; each 0â€“100 | Participating victory reward = max(minimum, base + enemy level Ã— per level). Restart/load refreshes policy. |
| Level Cap | 55; 1â€“55 | Future growth ceiling; existing higher-level profiles are never downgraded. Restart/load refreshes policy. |
| HP Growth / Stat Growth | 2 / 1; each 0â€“10 | Species-level increments before IVs/training, including special stats. Snapshotted for new individuals; loaded individuals retain saved growth. HP gained through actual leveling preserves existing damage. |
| Unlock Levels | [4, 8, 14]; three strictly increasing levels 1â€“55 | Provisional first/second/rest additional species moves. Captured on first individual schedule admission, including capture. Existing saved schedules and remembered moves are preserved. |

Unlock scheduling follows explicit species pool order. Species pools and starting
move definitions remain in Move Library. Individual potential/training and explicit
authored evolution preservation are now implemented as described below; opening
quests, production evolution content and finite Seal economy remain separate.

## Combat interface presentation

The existing root Sol Visual Settings resource also drives the polished
[combat HUD](combat-polish.md). These presentation values apply to the live view,
not to saved individuals, combat rules, or generation.

| Control | Default / application |
| --- | --- |
| Health Bar Seconds | 0.3; 0â€“1 real seconds. Animation toward the currently presented resolution step's HP; zero snaps. Numeric HP is exact for that same step. |
| Target Previews / Preview Opacity | true / 0.5; opacity 0.1â€“0.8. Read-only movement routes and move-area overlays. Refresh targeting after changing preview settings. |
| Damage Preview | true. Exact direct damage and remaining HP for legal aimed attacks, using the execution calculation. |
| Impact Seconds | 0.3; 0â€“0.6 real seconds. Cosmetic damage/heal flash and squash; zero disables. Feedback Enabled also disables these reactions. |
| Action Cue Seconds | 0.35; 0â€“1 real seconds. Hold the acting Sol/move cue before revealing consequences. |
| Consequence Seconds | 0.6; 0â€“1.5 real seconds. Hold damage/healing/field or outcome feedback. |
| Movement Step Seconds | 0.16; 0â€“0.5 real seconds per displayed legal waypoint. Does not alter movement cost. |
| Turn Handoff Seconds | 0.4; 0â€“1 real seconds. Identify the next actor without changing initiative. |

The Battle Pacing group drives [sequenced resolution](combat-sequencing.md).
Its four durations apply when the next record starts; active holds keep their
existing duration. Values are provisional presentation tuning, never saved into
individuals. Zero holds still process records in order with command admission
gated. Invalid resources fall back at playback admission; runtime duration edits
are clamped to their ranges and nonfinite values act as zero. The battle menu
pauses the sequence. These settings do not alter status/field turn lifetimes.

## Individual stats and class buffs

`BattleSettings.sol_stats` links `resources/sol_stat_settings.tres`;
`BattleSettings.class_buffs` links `resources/class_buff_settings.tres`. Both are
typed, validated Resources. See [individual stats](sol-stats.md) and
[class buffs](class-buffs.md) for rules and migration behavior.

| Control | Default / application |
| --- | --- |
| IV Min / Max / Samples | 90 / 110 / 3 averaged samples, inclusive integer percent. Independent streams per stat; more samples concentrate rolls near the center. New individuals only; resolved IVs persist. |
| Points Per Stat / Trained Stats / Training Percent | 100 / 3 / 10%; defines full per-stat and total training budgets. Saved per individual; no separate growth-point pool. |
| First / Second Form Percent | 50 / 75; final available form always 100. Applies to earned total and per-stat caps. Saved per individual. |
| Weak Level Gap / Training Reward | 10 / 5; no training at or below the negative gap; otherwise max(1, reward + level difference). Saved per individual; requires an effective contribution to victory. |
| Retraining Items | 3; 0â€“99. Supplied once for a new expedition; consumed/reset count persists on load. Bag and companion controls show actual supply. |
| Class Definitions | Eighteen typed `ClassBuffDefinition` subresources: ID, name, description, inclusive min/max potency. Percentage points except Skyborne tiles and Feyborn extra turns. Resolved potency persists; edits affect new individuals. Earthbound is binary utility (0â€“0). |
| Kindling Cap / Verdant Healing Cap | 15 / 15 percent. Snapshot at battle preparation; accumulation/healing counters reset only for a new battle. |
| Momentum Tiles / Low Health Percent / Wyrm Health Percent | 2 cells / 50 / 75 percent. Snapshot at battle preparation. |
| Wraith Distance / Isolation Distance | 3 / 2 Manhattan cells. Snapshot at battle preparation. |
| SolMove Category / Stat / Effect | Physical or special damage category; target stat for buff/debuff; damage/heal/field/phase/quantum/anchor/buff/debuff/poison/protect. Saved movebooks retain definitions. New prototype unlocks use the same authoring path. |

Stats resolve from the saved reference profile, saved level-growth increments,
locked IVs, and training allocation. No setting rerolls an existing individual.
Allocation/reset cannot heal, run during battle, or exceed earned/stage budgets.

The [project standard](PROJECT_STANDARD.md) now requires future implemented tuning
to be exposed through typed resources or grouped scene-root properties, with
tooltips, units, ranges, validation, and documented application/save semantics.
Every feature PR should update this control map when adding or changing settings.

`tests/inspector_tuning.gd` validates actual root-resource wiring, changed movement,
world creation, recovery, cache eviction, saved identity/climate preservation,
invalid/missing resource fallback, and `.tres` serialization/reload. It runs in
`tools/validate.ps1`. This changes configuration access, not default game balance.

Validation passed Godot 4.7.2 import and all 6,126 headless assertions, including
14 tuning integration checks and both scene journeys. The tuning suite also
passed after moving its temporary resource fixture into unique user storage so
it does not depend on an ignored local artifacts folder. Existing GPU-only
checks remain outside this count; default presentation is unchanged.

## Wilderness and image quality (October 27, 2026)

`SightingSettings.wilderness_enabled` enables persistent prototype wildlife beyond
three trail encounters. Default visibility is 28 cells. Admission happens on
expedition initialization/load and exploration steps, never camera or render
rebuilds. As of November 1, wilderness home slots use alternating absolute
16-cell sectors, halving ambient spawn density; legal terrain is still required.
Restart to refresh loaded-area admission. Explicit sightings are unchanged;
existing individuals, captures, depletion and recovery retain their saved IDs.
The current Bramblepup/Seedmote roster and four affinities are provisional content,
not a completed biome ecology system. Disabling wilderness hides its local views
without deleting saved individuals. The existing 2,048-individual admission ceiling
still applies.

`View3DSettings` exposes Ambient Occlusion (on), Occlusion Radius (1.2 cells),
Occlusion Intensity (1.4), and Multisample Antialiasing (2x). Restart or call
`apply_view_settings()` to apply. Desktop rendering uses Forward+; image quality
and performance should be assessed on the target GPU. Detail Distance defaults
to zero, following trees to the streamed terrain horizon. Positive values opt
into distance culling, with picking using the same cutoff. These are
presentation settings and do not change terrain or species identities.

`View3DSettings.chunk_work_ms` defaults to 3 ms (1â€“8 ms) for later streamed
chunk preparation. Reapply view settings to change it. Generation and geometry
are prepared incrementally after warming cold road dependencies one region
at a time. November 1 cell preparation separates ground, plant placement, body
submission, individual grass candidates and dressing. Each consumes an operation;
completed cells alone advance the chunk cursor. Synchronous callers drain the
same preparation path. Instance filling and picking-index preparation
yield in groups of 32; surface uploads remain atomic and can finish after the
deadline. Temporary-ground builds share this deadline and resume on later frames,
including when the camera stops. `chunks_per_frame` still caps
completed publications. Initial visible coverage and explicit rebuilds remain
synchronous. These are local presentation settings, not expedition save data.
See [runtime optimization](runtime-optimization.md) for validation and limits.

October 31 hitch-control follow-up: `chunk_operations_per_frame` defaults to 128
(16–256); `chunk_upload_steps_per_frame` defaults to 2 material-batch uploads
(1–8). CPU instance-buffer assembly and picking preparation spend operations/time,
not the upload allowance. `ground_operations_per_frame` defaults to 32 (8–128)
and `ground_uploads_per_frame` to 1 (1–2). Temporary coverage now yields between
tiles and skirt edges, sharing vertex attributes within its chunk; its single mesh
upload remains atomic. `retirement_steps_per_frame` defaults to 8 (1–32), and
`retirement_work_ms` to 0.5 ms (0.1–2). Each cleanup step releases at most 32 owned
records or one child/root node. Pending retirement blocks new detail admission at
the resident cap rather than forcing a mass free. Reapply/restart applies these
settings; explicit startup, load/rebuild and settings reapplication remain
synchronous boundaries. F3 separates runtime coverage/cleanup peaks from startup.
A placement query, cold model/resource preparation, ground setup or engine upload
can still overrun a cooperative deadline; these are explicit work limits, not a hard frame-time promise.

`View3DSettings.stream_ground_cache_chunks` retains up to 64 recently hidden
temporary-ground chunks by default (0-256). Zero disables retention. Reapplying
view settings applies a new limit on the next synchronization; changing terrain
source or temporary sample spacing clears retained geometry. This trades bounded
local presentation memory for less camera-reversal mesh construction and is not
saved in the expedition. Visible pending terrain receives coverage over budgeted
slices, rather than forcing every newly visible chunk into one frame.

`View3DSettings.stream_detail_cache_chunks` retains up to 16 hidden detailed
chunks by default (0â€“128); zero disables retention. Reapply to change capacity.
The same limit also bounds nearby published chunks kept visible outside the
current frustum, within the existing total stream capacity. This prevents a
camera turn alone from immediately removing all scenery behind the player.
Camera reversals restore their existing geometry and prepared cells. Retained
chunks never participate in picking or traversal clearance until republished.
World rebuilds clear the cache; routine evictions spread disposal over frames.
Shared static nature meshes are merged by material for rendering while original
per-part picking and traversal bounds remain unchanged.

Hover events are coalesced to one exact scenery pick per frame; clicks still
resolve their target immediately. Shared mesh-space triangle bins skip unrelated
triangles, and nature textures are decoded before play rather than on first hover.
Companion validation reuses the existing nested-edit-aware admission cache;
ecology configuration snapshots are rebuilt only when admission revisions change.
Local-home layouts also reuse a terrain/sector/configuration cache. Crossing a
sector retains unchanged Sol models and motion tracks; combat admission processes
only newly registered identities. Explicit world rebuilds still reconstruct views.
Wild-home recovery skips already occupied homes and memoizes move-library admission;
its saved deadlines and activation rules are unchanged.

Battle Settings' Commander Run Speed now drives the player model's sideline
speed. [Combat consequences and command positions](combat-consequences.md)
supersede the earlier cosmetic nearest-exit walk: the trainer runs to the farthest
usable side, deployment waits for arrival, release range uses that actual command
position, and the old tile is free. No valid outside route/release space rejects
entry. Ordinary return retains the route when walkable; a blocked return remains
outside without deleting the imprint. Defeat retains refuge relocation.

Mechanics reference inspected at SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`: `src/systems/world/sol_catalog.py`
(first-stage pools and deterministic individual affinity) and
`src/systems/ai/encounters.py` (saved identity, warning and contact policy).
Godot terrain remains the home-placement authority. Sector density and the small
available roster are explicitly provisional; existing encounter rules are retained.

Additional read-only source evidence: local SolHunterSource revision
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`,
`tests/test_entity_spawn_density.py`, `tests/test_encounter_aftermath.py`, and
`docs/coordination/encounter-persistence.md`: stable home membership, preserving
owned records, saved aftermath protection and avoiding duplicate acquisition.
These are continuity constraints, not approval of legacy generation or density.

Validation: `tools/validate.ps1` passed with Godot 4.7.2, including the new 18-check
wilderness/presentation suite and both exploration journeys. A rendered Forward+
run of `tests/full_3d.gd -- --capture-3d` passed 43 checks; camp and observation
captures are in ignored `artifacts/full3d/`. Desktop selected Direct3D 12 after
Vulkan initialization was unavailable on this machine.

## Running

October 29 traversal update: blocked diagonal input falls back to a legal cardinal
component, preferring the stronger input axis. This slides along banks, slopes and
walls without bypassing terrain or live-condition collision checks. The camera
follows the continuous explorer position without pixel rounding. Procedural legs
use alternating ground-sampled targets with Godot's TwoBoneIK3D; stance anchors
use absolute coordinates, swing clearance scales with the smaller model, and
body lean responds to terrain and turning. Animation cadence follows measured
travel speed. Pause freezes the procedural pose; teleport/reconstruction resets
anchors. Disabling the live toggle restores authored animation. These are visual
and input changes; no generation policy or saved simulation rule changes.

Reference checked read-only at SolHunterSource commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`: `src/app/controllers/player_movement.py`,
`src/core/game.py::_move_player` and `src/core/state/game_state.py::move_player`
retain tile-step authority and legal-step checks separately from player visuals.
The owner's procedural movement request layers cosmetic rig adaptation over
Godot's existing authoritative traversal rather than importing legacy generation.

Validation on Godot 4.7.2: player traversal passed 11 headless checks and 14 rendered
checks, including live leg-solver reach and settled foot placement. Running (10),
building collision (776), terrain integration (3565), full 3D (62) and Inspector
tuning (14) checks passed. Rendered evidence and logs are in ignored
`artifacts/player_traversal/`. This is focused validation, not a full-suite run.
The owner's slower-leg follow-up passed 16 rendered traversal checks, including
the reduced step count, slower animation playback, leg reach and final settling;
see `artifacts/player_traversal/slower-render.log`.

Hold Shift with WASD/arrows to run; releasing Shift restores walking even during
a step. `ExpeditionSettings.run_multiplier` is provisional 1.75x (range 1â€“3),
applied immediately to loaded and new expeditions. Cardinal/diagonal duration,
terrain penalties, collision and per-step encounter checks use the same movement
path. Walking uses `Walking_A`; running uses `Running_A`. Menus and combat block
running. No stamina system or save-format change is introduced.

Read-only reference search at SolHunterSource revision
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` found no existing sprint/Shift/run-speed
implementation under `src/`. The modifier and provisional multiplier implement
the owner's explicit running request without adding resource costs.

## Right-click interaction menu

The context menu shares `MenuSettings` font size, background, surface, accent and
text colors (startup/restart). It uses `EncounterSettings.interaction_distance`
for selected-Sol Engage and `SightingSettings.observation_distance` for recording
selected-Sol observations. These remain Manhattan cell distances; out-of-range
Engage is visibly disabled and revalidated when invoked. No new balance sliders
or saved interaction rules are introduced. See the
[right-click behavior and research](decisions/2026-10-27-full-3d-and-controls.md#right-click-world-interaction-october-27-follow-up).

## Autonomous Sol wandering

Under **Expedition Tuning > Sighting Settings > Wandering**:

| Setting | Provisional default / range | Connected behavior |
| --- | --- | --- |
| Wander Enabled | true | Enable autonomous patrol/rest, including safe local routines after bounded near-player attention. |
| Wander Radius | 3 / 1â€“5 cells | Next goal's Manhattan distance from home, capped by Home Radius. |
| Patrol Goal Min Fraction | 0.5 / 0.2â€“1 | Minimum distance from current cell to the next goal as a fraction of effective patrol radius, rounded up. |
| Rest Min / Max Ticks | 1 / 3; each 1â€“64 | Duration when an arrival/expiry elects to rest; profile-scaled. Max must be at least min. Each tick is 0.75 active seconds. |
| Patrol Rest Chance | 0.35 / 0â€“1 | Deterministic chance to rest between goals; otherwise continue moving. |
| Blocked Goal Retry Ticks | 2 / 1â€“8 | Abandon a stationary patrol goal promptly. Decisions remain quantized by movement cadence. |
| Goal Timeout Ticks | 12 / 1â€“64 | Abandon an unreachable goal after this many active ticks. |
| Path Search Cells | 64 / 4â€“128 | Maximum visited cells per cardinal obstacle search. |

Existing Local Movement controls still govern decision cadence, home bounds,
reaction distances, and interpolation. Movement Radius now defaults to 28 cells
(range 4â€“32) so visible trail/wilderness Sols can be active before close approach.
The activity radius is Manhattan distance; visibility uses Euclidean distance.

Changes apply to loaded worlds without rerolling identity. New radii/rest durations
and timeouts apply to the next goal/rest; existing deadlines finish first. Lowering
Home Radius retires an out-of-range goal and returns the individual legally.
Disabling wandering preserves position and clears the interrupted goal on the next
decision; existing proximity reactions and return-home behavior continue. Disabling
Movement Enabled freezes all local decisions, including timers stored in their rows;
on resumption, deadlines are compared with the current exploration tick. There is
no movement catch-up. Invalid runtime settings suspend local AI. No new species,
social, weather, or relationship mechanics are introduced.

Implementation ownership: `sol_roaming_policy.gd` chooses actions/goals,
`sol_local_navigation.gd` resolves legal steps, `ExpeditionState` stores patrol
memory, and `authored_sightings.gd` orchestrates updates and presents saved state.
The original wandering delivery used domain version 11 and outer format 2.
Current AI state uses domain 14 (patrol, attention/routine and blocked-route state), expedition format 3,
and generation 6. Older outer formats/generations are rejected under the current
development policy. The five-cell saved home envelope and deadline corruption
ceiling remain engineering constraints. See the [roadmap audit](sol-behavior-roadmap.md#current-audit--october-28-2026)
for acceptance status. The [natural pass](sol-natural-movement.md) closes the
skipped-turn regression with queued legal-step replay; readability/device review
and owner movement-feel acceptance remain open.

## Mouse-first pointer presentation

Interface â†’ Menu Settings â†’ Pointer Highlight toggles the exploration ground
ring immediately. It is presentation-only and does not affect expedition saves.
The ring uses Menu Settings Accent at startup. Combat uses the same configured
Menu Settings theme. Input policy is documented in [UI/UX roadmap](ui-ux-roadmap.md);
full cross-screen text scaling remains phase 4.

## Live compact menu and smooth player turning

Interface â†’ Menu Settings â†’ Size Multiplier defaults to 0.7 (30% smaller in each
dimension), range 0.5â€“1.0. It multiplies the saved local menu scale rather than
rewriting preferences. Restart after editing this resource default. Options still
adjusts the relative menu scale immediately. R toggles this non-pausing menu;
Escape opens a separate pause screen. Encounter pause ownership is unchanged.

Player â†’ Player Turn Speed Degrees defaults to 540 degrees/second, range 90â€“1440.
Changes apply immediately to the actual model, including its sideline walk.
Rotation follows the shortest arc and is independent of frame rate. It changes
presentation only; tile traversal, collision and saved positions remain authoritative.
The standalone window starts maximized to the available screen and remains
resizable, with a 640Ã—400 minimum size. Physical startup-size overrides are removed;
canvas scaling expands to the screen aspect ratio. Startup display changes apply
on the next launch.

## Companion preview and interface text

Interface â†’ Menu Settings adds Text Scale (1â€“2, default 1), Preview Height
(140â€“320 logical pixels, default 140), and Preview Framing (2â€“4 model diameters,
default 2.5). Options â†’ Text size overrides Text Scale live and remembers it in
local preferences; it affects the screen-space HUD as well as personal screens. Reopen Sols
after changing preview defaults. Preview models use the existing Sol Visual Settings
palette, diameter and effects. No identity or expedition-save tuning is added.
See [Sol menu](sol-menu.md).

## Compact world inspection

Interface â†’ Menu Settings â†’ Inspection Width sets the collapsed strip width
(default 190, range 160â€“360 logical pixels at 100% text). Inspection Meter Height
sets the expanded reading bars (default 4, range 3â€“10 logical pixels). Both apply
immediately. The default strip shows only the subject and passability; right-click
â†’ Details opens readings and secondary facts. The detail card grows for larger
text, clamps within the viewport and scrolls its secondary facts. These settings
only affect presentation and do not alter expedition saves.

## Compact combat layout

Interface â†’ Menu Settings â†’ Combat Width sets the action-ribbon width at 100%
text (default 900, range 600â€“1200 logical pixels). Combat Health Width sets the
combined health-strip width (default 860, same range). Restart after editing these
resource defaults. Both layouts grow for the text preference, clamp to the current
viewport, and derive height from visible content; enlarged action content can
scroll. Secondary combat actions are under More Â· Esc. These are presentation
settings and do not alter tactical rules or expedition saves.

## Generated biome scenery â€” October 29

Normal `scenes/world_3d.tscn` uses `resources/nature_biomes.tres`. Its Biomes list
references meadow, woodland, heath and marsh children in `resources/scenery/biomes/`.
Each child owns its generated ground ID, tree scenes, tree-height multiplier
(0.5â€“1.3 of shared tree height), ground tint, cosmetic density (0â€“40%) and plant
entries. Entries retain shared uniform-scale/size/slope/static-geometry admission.
Biome Edge Blend (0â€“1, default 0.5) blends neighboring colors at shared vertices;
temporary and detailed ground use the same values. Ground IDs reference existing
geography, not new ecological definitions. Restart/rebuild applies to current and
loaded expeditions without changing generation or saved identities. Appearance,
picking and clearance should be reviewed together after tree changes. The HUD
shows actual habitat names automatically. See [biome scenery](biome-scenery.md).

## Bounded cohesive scenery sample

Open `scenes/cohesive_world_sample.tscn` â†’ 3D View â†’ Nature Settings â†’ Composition,
or `resources/nature_cohesive_sample.tres`. The optional composition selects a
seed and up to three absolute patch rectangles. Each patch exposes admitted
existing habitat IDs, density (0â€“40%) and scene entries. Shared review clearings live in `resources/scenery/required_spaces.tres`.
Entries expose Ground/Bank/Water, authored uniform scale, maximum horizontal
width/height in cells, terrain slope in degrees and static part/surface/triangle
admission limits. No height normalization is applied to these entries.
Composition â†’ Orientation Marker reuses a sign on existing legal ground.
Restart/rebuild applies these cosmetic changes, including on loaded expeditions;
generation, collisions and saved identity/ecology remain unchanged. The normal
world now uses `resources/nature_biomes.tres`: the three bounded treatments remain
for seed 2601026, with generated biome palettes elsewhere and on other seeds. See [sample contract and review](cohesive-world-sample.md).


## Smaller interface text and controller defaults

Interface â†’ Menu Settings â†’ Base Text Multiplier defaults to **0.715**: the previous 0.65 compact
baseline increased by 10% (28.5% below authored sizes). Restart after editing this resource.
The existing 100â€“200% Text Size preference multiplies this smaller baseline,
including menus, inspection, combat, prompts and tooltips; repeated application
does not compound the reduction.

Interface â†’ Controller Settings exposes deadzone, camera speed, repeat delay,
repeat interval and camera inversion. Options adjusts deadzone, camera speed,
inversion and button bindings immediately. These local preferences live in
`user://controller_preferences.cfg`, independently of expedition saves.
See [controller input](controller-input.md).

## Species catalog pilot â€” step two

See [species data integration](sol-species-data.md) and the
[Sol Bible](reference/sol_bible.md#pilot-production-sheets).
The connected catalog is `resources/sol_species/catalog.tres`; its three records
are shared by the battle settings and move library. Sighting settings select the
same file through Species Catalog Path, keeping the registry out of duplicated
movement tuning. All names and initial numerical values remain provisional.

| Inspector location / field | Connected effect | Application timing |
| --- | --- | --- |
| Battle Settings / Move Library > Species Catalog > Entries | Shared species taxonomy, six-stat reference profiles, lineage capacity, move pools, ecology and presentation lookup | Validate before admission; use matching catalog references |
| Catalog record > Display Name / species ID / lineage ID / class ID / ordinary form / footprint | Labels and authored identity of new individuals; class names displayed through approved metadata | Do not rename saved IDs. Test taxonomy edits in a new expedition |
| Catalog record > Reference Level / six stats / Evolution Forms | Existing individual-stat admission and training capacity | New admissions snapshot values; existing saved traits do not reroll |
| Catalog record > Learnable Moves / Starting Moves | Explicit eligible/remembered pool; first four start equipped | New movebook admissions; existing saved books retain their pool and definitions |
| Catalog record > Ecology | Existing profile/behavior hierarchy and bounded individual variation | Live decision/view configuration invalidation; existing committed legs/rests finish under current policy |
| Catalog record > Presentation Scene | Same species presentation choice in exploration, battle and preview | View reconstruction; pilots use articulated creature scenes. This does not enable unimplemented locomotion |
| Sighting Settings > Species Catalog Path | Resolves the shared resource without retaining a registry inside each movement-tuning copy | Validation at runtime; keep aligned with battle/move settings |
| Sighting Settings > Catalog Sightings | Explicit species ID, trail X and individual affinity for test/story placements | New expedition recommended; existing saved identities/affinities never relocate or reroll |

`resources/sol_pilot_sightings.tres` and `scenes/sol_species_pilot.tscn` provide the
review scenario. The ordinary expedition retains its original placements. Missing,
wrong-type, conflicting or incompatible resources reject; there are no unused
flight/swimming/procedural-animation controls in this data-only step.

## Pilot creature models - step three

See [creature models](sol-creature-models.md). Select a root under `scenes/sols/`.
Body Plan selects the species mesh builder. Model Scale controls uniform art size.
Sol bodies now remain in their neutral authored pose. Legacy idle, action, step,
turn-response, wingbeat and stroke values are stored for existing scenes but
hidden from Inspector and do not animate bodies. Affinity motes and visual cores
remain under shared Sol Visual Settings. See the current
[static-presentation contract](sol-procedural-ground.md#static-sol-presentation--november-1-2026).

## Routes and ponds â€” generation 7

Water and bank art tuning lives in `resources/water_appearance.tres`: Deep/Shallow
Color, Wet/Dry Bank Color, Bank Blend Height (metres), Depth Color Range (metres),
Foam Depth (metres), Ripple Strength (normal-only) and Ripple Speed (clock multiplier).
These affect the actual terrain/water materials on rebuild/restart and are cosmetic,
separate from saved generation controls. See [water appearance](water-appearance.md).

World root â†’ Expedition Tuning â†’ Terrain Settings exposes Route Bend (0.5â€“1.5),
Pond Scale (0.6â€“1.2) and Pond Candidates (1â€“3). They change selected district road
bends, pond radii and maximum candidates. Conflicts can omit candidates; the
essential approach retains its admission check. These saved generation settings
apply on a new expedition. Loaded current-generation saves retain their values.
See [route and pond diversity](route-pond-diversity.md).

## Sol body presentation

Procedural body animation was removed at the owner's request on November 1.
Movement replay still positions and faces rigid models; feet, breathing, gestures
and appendages stay neutral. Workshop exercise routes can move the model but no
longer animate its joints. See [the current contract](sol-procedural-ground.md#static-sol-presentation--november-1-2026).

## Sol flight and swimming

See [flight/swimming](sol-flight-and-swimming.md). In a species record, Traversal
selects ground, flight or swim and exposes root altitude, maximum draft, radius,
height and maximum bank step in metres. New wild admissions snapshot this policy;
saved wild individuals retain it. Test policy edits in a fresh expedition.

Flight/swim root placement remains connected to admitted traversal. Wingbeat and
stroke poses are removed; workshop Flight/Swimming modes retain neutral joints.

Catalog sightings can select a deterministic bank placement near their Trail X
anchor, with a bounded Bank Radius. This affects explicit home admission; no
terrain is rewritten. The separate pond pilot uses this setting and a review-only
fresh start near Reedback. Ordinary expedition spawn and pilot homes stay intact.


Provisional creature art: scripts/sols/presentation/sol_prototype_creature.gd exposes Prototype Kind
(Unassigned/Seedmote/Bramblepup/Ashkit/Rillfin) alongside the inherited model settings. The shared view factory selects the kind for existing
species IDs; it does not change class, stats or movement capability. Rebuild views
after editing defaults. Gameplay no longer uses orb bodies or hovering; affinity
palette and motes still apply. See [the design handoff](sol-creature-design-handoff.md).


Menu Settings â†’ Observe Seconds defaults to 3 real seconds (1â€“10); changes apply
to the next observation or unpin. The final 0.35 seconds fade out. Pin suspends
expiry. This affects presentation only and does not modify expedition saves.

View 3D Settings â†’ Ground Clearance keeps the camera endpoint at least 0.6 cells
above terrain (0.1â€“3.0). Reapply view settings after editing. It does not remove
intervening hills or scenery. Owned Companion Settings â†’ Caption Clearance adds
0.25 cells above species bounds (0.05â€“1.0); Routine Captions restores repeated
Following/Resting subtitles if desired. Both companion controls apply live.

The [story workshop](story-tools.md) exposes Preview Events on its root. StoryEvent
and StoryChoice resources expose IDs, prose, prerequisites and assigned facts;
edits apply on the next opening. Saved decisions retain their stable IDs. The
normal game has no automatically enabled campaign events.

## Phase 2 biome and geography controls

See [biome encounters and geography](biome-encounters-geography.md). Normal F5 uses
`terrain_exploration.tres`. Elevation Noise chooses smooth simplex or Perlin;
Landform Strength controls district landforms; Drainage Influence controls local
catchment influence on pond candidates. These are captured generation inputs;
review changes in a new expedition. Road access remains a hard constraint.

Each biome palette exposes Tree Tint and Detail Tint, individual Scale Variation,
Regional Scale Variation, Cluster Cells and Cluster Fill. Regions and groves own
shared variation before individual placement. Original imported assets remain
unchanged. Sighting Settings exposes Habitat Encounters with a ground and weighted
species map per pool. Policies are captured once per expedition; use a fresh
expedition to review pool edits. These provisional weights do not tune combat.

## Local asset-store meadow preview

The separate generated asset review project's root exposes Meadow Spacing (meters),
Meadow Size (width/depth in meters), Meadow Height (meters), and wind/gust strengths.
These apply at preview restart and do not affect expeditions. The reproducible
fixture is `tools/asset_store_review.gd`; see the [asset comparison](research/asset-store-review.md)
for preparation, license handling, limits and the stylized presentation treatment.

## Reviewed main-game visual controls

`View3DSettings.pixel_effect_level` selects Off through Deep pixelation; Off
is the default following the owner's October 29 removal request. R > Options exposes the same live current-session selector
at the top. The effect samples only the world, leaving UI and picking native.
`NatureSettings.meadow_enabled`, `meadow_divisions` and `meadow_height` control
continuous grass at scenery rebuild/restart, including loaded expeditions.
Grass is the built-in emanator under `AuthoredPlantLibrary.add_cell`; enabled
matching authored emanators replace its default blade body. Its density settings
never multiply reserves. The plant library now routes shared atmosphere weather
to grass and other plant shaders; existing rain response remains connected.
`NatureSettings.meadow_batch_cells` selects 4, 8 or 16-cell grass batches
(default 8). Smaller batches improve frustum/distance culling while increasing
draw calls; clump positions, density, wind and canonical flora remain unchanged.
Restart/rebuild applies; `View3DSettings.grass_distance` still owns draw distance.
`MeadowAppearance.density_start`, `density_end` and `distant_density` control
gradual distance thinning (24/44 camera cells and 0.4 by default). The distance
is horizontal; nearby cover stays full density. Set distant density to 1 to
disable it. These apply at rebuild/restart and do not alter canonical flora.
`View3DSettings.scenery_lod_bias` tunes native static scenery LOD selection
(0.25–4, default 1). Higher values retain more distant detail. Restart/reapply
view settings to change it. Imported source meshes and full-resolution picking
remain intact; render LODs are built once during shared palette preparation.
  Single-blade grass additionally carries seven/three/one-triangle native LODs.
  `View3DSettings.detail_distance` defaults to 48 cells for small plants, with
  the existing 12-cell fade band; 0 follows trees to the horizon. Grass retains
  its separate draw distance and density controls.
Main F5 enables it in `resources/nature_biomes.tres`.
`NatureSettings.ground_base_color` and `ground_texture_strength` tune turf color
and retained texture contrast on detailed and temporary streamed ground. Grass
inherits the same base color and habitat tint. Rebuild/restart applies to loaded
expeditions too. Main defaults use 2 clumps per edge at 0.22-cell height;
meadow/woodland `NatureBiomePalette.density_percent` is 14/18 for small plants.
See the [reviewed visual contract](reviewed-world-visuals.md) for bounds, provenance,
weather ownership and validation. These presentation settings do not alter saves.

## Slope readability and vertical movement

`WorldPlane.player_height_smoothing` follows terrain-height changes over 0.06 seconds
by default (0â€“0.2; live). Zero restores exact body following. The cosmetic height
lag is bounded to 6% of player height; procedural feet still sample actual terrain.
`View3DSettings.height_smoothing_seconds` defaults to 0.12 seconds (0â€“0.4; live
on the active settings). Zero disables it. Home, rebuild/load and teleports reset
height immediately; pause holds it. Camera ground clearance remains enforced.

Blocked slope cells use exposed stone and omit dense meadow cover. Their marker
comes from `WorldTerrain.slope_fits`, including both terrain triangles, rather
than interpolated lighting normals. This reads saved walkability settings and
does not change terrain, access rules or saved generation. Temporary coarse
ground uses its representative sample until detailed terrain publishes.

## Optional supplied effects

`AtmosphereSettings.wind_leaf_particles` controls the locally installed Vefects
leaf emitter (0â€“96; default 32). Apply atmosphere settings to rebuild it; zero
removes it. Direction follows the existing view `cloud_wind`, with rain-strength
drift and pause matching the rain owner. `SolVisualSettings.impact_distortion_enabled`
controls the optional burst on subsequent positive damage cues; the existing
feedback limit and lifetime own cleanup. Missing local assets retain existing
visuals. See [supplied effects](local-effects.md) for installation and licensing.


October 29 streaming/peak follow-up: the reviewed current preset uses 18 junctions
across at most six geographic owners and one extra nearest-group link. Pulses are
12 phase units apart with a bright head and a longer fading tail. Roots terminate
at a published living asset, rather than a grove centroid. Owner retention and a
0.45-second old/new mesh transition soften source admission; at most one previous
geometry pair is retained. This changes presentation, not concentration rules.

`View3DSettings.detail_distance` defaults to zero: plants follow the camera
horizon. A positive opt-in distance retains its 12-cell visibility fade band.
`View3DSettings.grass_distance` independently limits live leaf grass to
28 camera cells by default (8–64 adjustable), with a 12-cell per-clump fade.
The current controls and legacy blade-study distinction are described above.
Restart/reapply view settings to change them. Imported
plants keep zero instance transparency, preserving their cutout/depth pass;
cached scenery returns without restarting an arrival fade. Live Vastra
particle transfers blend admission/removal over 0.45 active seconds and retain
their absolute path while retiring across an origin shift. The existing chunk work/publication budget
remains in force, and replanning preserves an admitted in-progress chunk while it
is still wanted. No new key binding or Options entry was added.


October 29 height-tier and particle follow-up supersedes the prior 18-junction
preset: `resources/vastra_settings.tres` now uses a 30-junction ceiling for common
small ground strands and at most two rare canopy links. It does not require every
visible grove to connect to one global graph. The table describes the art-study
controls; normal play uses the mechanical overrides below. Graphical changes are
live on loaded worlds; mechanical reach is captured for each expedition.

| VastraSettings field | Default | Connected behavior |
| --- | --- | --- |
| `current_ground_reach` | 3 cells | Nearby grass-to-grass endpoint selection and base maximum reach. |
| `current_ground_clearance` | 0.06 cells | Small currents follow actual terrain with only a 0.02-cell additional arc. |
| `current_canopy_links` | 2 | Global maximum rare treetop-to-treetop connections; zero disables them. |
| `current_canopy_arc` | 0.18 | Crown-to-crown arch height as a fraction of span, capped at six cells. |
| `current_height_range_multiplier` | 5 | Maximum reach relative to grass-level strands; default approximately 15 cells at canopy height. |
| `current_range_height` | 3 cells | Height above local terrain at which full reach is available. |
| `current_strand_shake` | 0.18 | Smooth transverse ripple within the existing ribbon; zero retains quiet base detail. |
| `current_flow_speed` | 0.42 | Cosmetic detail clock, down from 0.75. Zero freezes art-study transport/detail; real packet heads retain saved departure/arrival timing. |
| `current_particle_limit` | 0 | Orb-like motes removed from the production view at the owner's request. Zero hides the optional particle layer. |
| `current_particle_size` | 0.09 cells | Mote diameter before tier and tail variation. Smaller motes accompany the more common low flows. |

Grass roots and canopy endpoints reference actual published assets. In normal play,
`charge_destinations()` identifies actual energy recipients; the earlier deferred
generator hook is superseded by the saved circulation below. Particle and ribbon
brightness fades between streams; the inactive carrier retains only a trace of
its prior visibility. These controls add no Options page or key binding.


October 29 mechanical circulation: normal currents now consume actual saved plant
transfer events. The old optical speed remains a study/ripple control; mechanical
head and mote arrival follow the captured packet speed. Ground endpoints lead to
tree bases; tree relays use crowns. `current_range_height` remains an art-study
reach control. `VastraSettings` adds the following
provisional new-expedition policy, separate from live graphical tuning:

| Field | Default | Effect |
| --- | --- | --- |
| `plant_threshold` | 100 | Stored energy that emits one conserved packet. |
| `plant_refill_rate` | 4 units/s at concentration 100 | Ambient-scaled refill, capped at the emission threshold for new ambient absorption. |
| `plant_repair_cost` | 10 units | Paid reduction of one local positive overload point. |
| `plant_repair_points` | 1 per serviced tick | Local repair work; zero disables assistance. |
| `plant_transfer_speed` | 0.35 cells/s | Saved head travel/arrival timing; finite ribbons and motes follow it. |
| `plant_work_limit` | 64 | Maximum source visits and arrival credits per activity tick. |
| `plant_active_radius` | 1 geographic region | Active simulation ring around the player, independent of camera/graphics. |
| `plant_root_rate` | 8 units/active second | Bounded distribution of expelled root stock to nearby admitted plants; fractional finite packets reserve destination capacity. |
| `sol_feeding_rate` | 4 units/active second per Sol | Consumption of nearby root excess as food; one per-Sol budget across all trees, no automatic healing/XP. |
| `sol_feeding_radius` | 3 cells | Distance from a Sol's authoritative field anchor to available tree-root stock. |

Plant and tree reach are captured from the existing ground reach and height-range
multiplier (3 and 15 cells by default). Their product must remain at most 32 cells
within the bounded catalogue policy. Rendering budget zero hides the field without
turning off its simulation. Art-only study fixtures opt into `study_mode` explicitly.
See [Vastra integration](vastra-integration.md#plant-energy-circulation-and-natural-repair--october-29-2026)
for repair scope, conservation and saved policy. The owner-approved overflow/food
change uses development-save version 20 / plant ledger 2 and requires a new
expedition for older snapshots. Root stock is separate from the capped object
reserve; hover its Details bar/value to read expelled energy around the roots.
Current Distance Taper (1.5, 0â€“4) narrows finite filaments with distance traveled,
independently of the wider wiggle envelope; zero disables distance taper. This
presentation control applies within 0.5 seconds. Feeding/root rate and radius are
saved new-expedition controls. Orbs, bloom and scenery lights remain off.

### Mist interaction study â€” October 29

The [mist roadmap](vastra-visual-roadmap.md#planned-character-interaction-mist-flow--october-29-2026)
now has a disposable `--mist` exploration review, separate from normal currents.
No unused Inspector fields or Options entries are added. `VastraMistFlow` is a
reference component (script `vastra_mist_flow.gd`, no global class): coordinates
are terrain cells and world Y, time is active seconds. Its study-only body radius
is 0.38 cells and height 0.85 cells. A 17Ã—7Ã—17 grid uses 0.5-cell spacing, a 30 Hz
fixed step, at most four steps per call and 0.7-cell maximum displacement.
The study supplies a constant gentle art drift, rather than simulating weather.
These defaults are development parameters, not accepted production controls.

Recreate the study to change dimensions or body settings. Its pause argument
freezes transient state and resets the body sweep; large teleports reset the
field. Runtime pause/zero-flow, weather conversion, load/rebuild, shared haze/
filament/mote rendering and Inspector controls remain later integration gates.

### Vessel visual study â€” October 29

The standalone [Vessel preview](vessel-visual-study.md) uses
`scenes/vessel_preview.tscn` and `scripts/presentation/vessel_particle_swarm.gd`.
Latest owner direction replaces the insect art test with particle orbs and fading
wakes. One GPU emitter owns all heads and wake samples. Member count (1â€“4,096),
orb scale, spread, affinity tint, flight radius (0.02â€“0.3 metres), motion speed
(0.1â€“2 curve segments/second), trail samples (4â€“16) and trail seconds (0.1â€“1)
apply on restart/recreation. Close inspection uses a 6 cm flight radius; field
views use 10 cm. Trail seconds describe a visual wake, not Vessel lifespan.

Anger (0â€“1) applies immediately; A cycles it in 25% steps. Maximum additional
aberration pixels also update immediately; refraction pixels apply at recreation.
Glow is emissive
with preview bloom; no per-orb point lights or surface illumination are added.
All controls are presentation-only and do not save or create ecological effects.
The live ecology now uses the same particle emitter via
`scenes/vessel_particle_swarm.tscn`. Edit that scene's exported visual controls
and restart for structural changes. Runtime caps its head count at 24 per group,
overrides tint from the existing affinity palette and enforces the saved active
clock. State-derived anger blends at one unit per active second, so explicit
pause freezes that blend as well as flight and trails. No gameplay/save rule is changed.

Aberration-meter follow-up: maximum aberration now also applies immediately.
The preview has Anger (0â€“1) and Maximum color separation (0â€“24 screen pixels)
sliders plus a live meter of maximum Ã— angerÂ², matching the per-channel shader
offset. These values survive preview density switches, without being saved.
Refraction tuning still applies at recreation.

Direct-mask follow-up: maximum separation now ranges 0â€“24 px (default 12), with
preview anger starting at 0.5. Refraction ranges 0â€“32 px (default 14), scaled by
0.005 + 1.995 Ã— angerÂ² and radial falloff. With the default, warp is 0.07 px calm,
7.05 px at half anger and 28 px at full anger. A 12 cm soft radial head mask samples
the background before the orb/wake glow pass; the single emitter adds two draw
calls. Refraction remains a restart/recreate setting. Controls are at the top
right so the close-up effect is visible. This remains a bounded art test.


### Connected vegetation and Vessel pilot â€” October 29

The main world's inherited `vessel_settings` points to
`resources/vessel_settings.tres` (`VesselSettings`). Enabled state, group limit,
signal lifetime, feeding/response costs, response/recovery duration, stranded-flow
threshold/duration and storm policy capture once per expedition. Editing the
resource does not silently replace a loaded expedition's captured policy.
`storm_chance_percent` is zero by default while storm behavior is designed.
Specialist class costs are provisional code constants in this first pilot.

The 3D world's `vegetation_appearance` points to
`resources/vegetation_appearance.tres`. Its optional Warden/Mender/Regulator model
paths, fitted heights and maximum width affect presentation only; restart to
rebuild existing plant instances. Default local models are tropical 019/015/017.
Absent local art falls back to the bundled CC0 models. The shared Vessel body and
shader remain owned by the separate visual study; the live consumer supplies
active-time animation and state-derived agitation without saving art settings.

## Standalone Vastra particle lab

`scenes/vastra_particle_lab.tscn` is an optional art fixture; run that scene with
F6. Root exports `max_members`, `trail_samples` and `field_radius` apply on scene
restart. Its on-screen sliders and state/pattern/affinity selectors apply live
and are not saved. See [particle lab controls](vastra-particle-lab.md). These
controls have no effect on the main game or expedition state.

The lab also exposes synthetic plant reserves through five labeled real nature
assets. Its interaction menu selects emission, relay, convergence, overflow and
root-return samples. Transfer energy and travel speed apply on the next send;
arc height and path width apply live. Copy all test parameters copies field and
interaction settings to the clipboard for review in chat. This is lab-only art
tuning, not a new production reserve/recipient-selection policy.

The lab's filament approximation defaults to 128 GPU heads with zero emission.
Its appearance selector retains the earlier trail comparison. Filament length
(cells) and refraction (screen UV offset) apply live to both ambient and transfer
particles; the neutral field-optics option does not assign a gameplay affinity.
The copied snapshot includes appearance and the root rendering budget.

## Development workstation

Open `scenes/development_workstation.tscn` with F6. The sidebar edits scalar
exported fixture properties and rebuilds to apply them; resource properties stay
in each fixture's Inspector. These overrides affect only the current test fixture.
Boolean exports use switches; ranged numbers use sliders and enums use selectors.
Other scalar fields accept Enter or Apply. The lab
shell shares the field menu theme and `resources/menu_settings.tres` palette.
The shared workspace now uses Settings, View, Compare, Review and Speed tabs.
Ranged shared controls pair sliders with exact number entry and per-value/group
resets. Existing art-station panels dock in the sidebar; runtime game menus retain
their original interactions. Guided Grass/Vastra tests can stop at a known test
time; other stations expose repeatable starting settings without claiming exact
replay. Named local reviews preserve notes, status, before/current pictures, camera
and settings across restarts. The View tools temporarily override presentation;
they never edit source resources. See the
[workspace rollout](development-workstation.md#review-workspace-rollout--october-30-2026)
for application timing, review storage and comparison limits.

See [workstation usage](development-workstation.md) for capture and measurement limits.

Lab filaments now curve using a 24-segment particle strip and a shared path
sampler. Arc height/path width reshape the actual strip vertices live; filament
length sets the sampled span. This remains confined to the lab.

Visual benches: `tools/visual_test_station.gd` owns the station selector export;
its per-station sliders apply immediately and remain fixture-local. Animation
benches inherit model/exercise/speed/affinity exports from the existing model
workshop; clickable action/route controls apply immediately. See
[additional visual stations](development-workstation.md#additional-visual-stations).

The lab loads the owner-captured `resources/vastra_particle_lab_baseline.json` at
startup; Restore your baseline reapplies it. Opacity and independent ambient/
transfer visibility sliders reach zero. Send pulse strength/duration apply live
to the finite transfer packet; no ecological or reserve policy changes. Export
shows selectable JSON and saves `artifacts/vastra-particle-lab/latest-settings.json`
even if Windows clipboard access fails.

## Grass and leaf appearance

`resources/meadow_appearance.tres`, connected through
`NatureSettings.meadow_appearance`, owns root shade, tip brightness, texture
detail, broad patch variation, normal-up bias, backlight, cutout threshold and
wind displacement/speed. These apply at restart/rebuild. Density/height remain
with the existing continuous-meadow controls; geography/collision is unchanged.
`resources/vegetation_appearance.tres` adds leaf-only pigment, normal-up bias,
backlight and tip-wind displacement for optional ecology plant art. Flowers and
stems retain their supplied palette colors. Wind consumes existing airflow and
active seconds, with no movement on pause and no phase shift from camera rebasing.
See [grass/plant review](reviewed-world-visuals.md#grass-and-pale-plant-shading-rework--october-29-2026).

### Lab: single-blade grass

`scenes/grass_blade_preview.tscn` exposes density (blades/m²), blade height (m),
width (m), curve (fraction of normalized blade height), wind strength and direction
(degrees). The Development lab's **Grass / single blades** sidebar applies scalar
changes by rebuilding this fixture. Four biome multipliers remain provisional art
constants. Changes affect only the lab session; gameplay settings and saves are
unchanged. See [development workstation](development-workstation.md#single-blade-grass-prototype).

The grass lab also exposes **Vastra visible** and **Night view** switches plus
sliders for Vastra visibility, path arc height (m), thickness (m), whole-fixture simulation
speed and optical filament count. The isolated production plant ledger owns all
transfers; these settings do not create recipients, duplicate reserves or assign
affinity. Arc height leaves the source/destination anchors fixed. Simulation speed
advances the shared test clock, preserving transaction/particle timing.

### Live procedural single-blade grass — October 30, 2026

`resources/nature_biomes.tres` enables the approved grass with `meadow_divisions`
(2–16 individual blades per cell edge, default 7) and `meadow_height` (0.15–1.2
world cells, default 0.18). `resources/meadow_appearance.tres` owns blade width,
curve and meadow/woodland/heath/marsh height, width, curve, coverage and color
multipliers. Existing wind response and thinning controls remain connected.
Restart/rebuild applies to existing expeditions. Shape/density changes preserve
canonical cell reserves and endpoints. Old grass clumps are no longer live art.

### Default terrain/trail blending and shared plant tiles

`NatureSettings.terrain_blend_softness` defaults to 1, with
`terrain_blend_detail` controlling stable geographic edge breakup and
`trail_texture_strength` controlling the supplied Ground019 color/detail share.
Matching authored normals/relief follow the same trail blend. These settings feed
both detailed and streaming terrain; biome tint edge blending defaults to 1.
`MeadowAppearance.trail_verge_cells`, `trail_verge_density` and
`trail_verge_height` taper admitted blades toward the protected road corridor.
Restart/chunk rebuild applies. Specialist tiles admit surrounding grass with a
small central clearance; plant anchors outrank ground-cover anchors, retaining
one canonical cell reserve and the existing ecological role.

### Shared plant growth diversity — October 30, 2026

Plant maker and biome/anatomy labs expose **Growth diversity**: Leaf architecture
is a discrete choice (habitat default, broad fans, divided fronds, succulent scales,
long ribbons); Branch irregularity and Leaf asymmetry are 0–1 sliders. Zero/default
preserves the approved forms. The maker randomizer includes all three, and saved
recipes restore them. Shared scenery builders also supply the bounded live tree
and specialist palette; these settings never change Vastra roles or reserves.

**Organic softness** (0–1, default 0.7) controls curved stem interpolation and
rounded leaf cups in both shared plant labs. The randomizer uses 0.6–1.0.
Anatomical endpoints remain fixed. Saved plant meshes need a new saved revision
to adopt changed generator geometry; the existing project plant has been rebaked
as a new revision with its original retained.

Plant **Growth diversity** also includes Foliage fullness (0–2), Branching depth
(0–3), Branching spread (0.2–1.3 radians), and Branching reduction (0.4–0.75).
Their defaults are 1, 2, 0.75, and 0.62 respectively. Increasing depth repeats
smaller forks; spread opens them out; reduction sets each child's relative length.
Zero depth keeps direct leaf clusters. Saved recipes retain all four settings.

### Plant event animations

The Plant maker's **Event animation preview** provides a discrete event selector
(Idle, Receiving, Releasing, Repairing, Protecting, Regulating), a strength slider
(0–2, default 1) and duration slider (0.5–3 seconds, default 1.6). Preview events
loop locally. `world_solid.gd` exposes matching live strength/duration controls;
zero strength restores rest poses. Live reactions use committed transfers and
existing specialist activity, with the saved active clock controlling playback.

### Sol Lab and canonical visual cores

Open `scenes/sol_lab.tscn` directly with F6. Its section selector provides Bodies,
Shape, Explore, Species, Surface, Motion and Review.
Bodies has three structural presets for each of the eighteen current classes.

The owner's October 30 clarification establishes the wispy ball as a **visual
core**, not necessarily an anatomical head. Species selects a head/chest/back/root/
tail/free anchor independently of optional physical head anatomy. Shape / Core
exposes size, three-axis offset, density, wisp length/speed, spread, softness,
opacity and glow; Surface owns its independent tint. Shape / Head controls the
separate anatomical proportions. Existing species retain their authored heads.

`sol_visual_core.gd` owns shared particle ranges/defaults and reuses the existing
Vessel wake renderer. `sol_creature.gd` accepts per-scene `visual_core_tuning`
overrides; early `head_wisp_tuning` entries remain readable for compatibility.
The Sol Lab recipe and exported view use the same component. Particle paths
follow the visual owner's clock. `sol_design_recipe.gd` owns the other appearance
ranges and inherited species limits. See [Sol Lab](sol-lab.md) for revision/export
paths and explicit reviewed-appearance application.

Physical plant size classes (October 30): Small, Medium and Large are independent
of circulation roles and Receiver specialties. Plant Maker class selection applies
a size; randomization stays within it. Tree height ranges are 3–5, 5–8 and 8–12
units; other plants use 0.04–0.3, 0.3–0.8 and 0.8–1.8. Height/spread remain
adjustable. Saved assets retain the class; older assets default to Medium without
changing dimensions. Reservoirs now have trunks and ascending scaffold tiers
in every biome, retaining their distinctive foliage and roots.

Plant lab `role_expression` controls the strength of role-specific blossoms, cups,
shield leaves, tendrils and vanes. `organic_softness` also smooths multi-joint
stems; both rebuild the visual recipe and persist with saved plants.

Plant Maker **Color assignments**: separate `bark_palette`, `foliage_palette`,
`flower_palette` selectors, `color_gradient` strength and `leaf_tip_gradient`
canopy-to-tip blend apply to every role and persist in the recipe. Trees limit
hue offsets to earthly colors; smaller plants keep the full range. **Plant
structure** adds `branch_reach` and `branch_arch` for the Reservoir canopy.
These controls rebuild visual geometry; existing baked library revisions change
only when loaded and resaved. Randomization includes these connected controls.

Plant suite cleanup (October 30): **Plants / maker & library** starts with
**All biomes · side by side** and **All plant forms**, showing 24 editable previews.
The **All biomes · all plants** button returns to this overview from a saved/focused
selection. Shared sliders affect the visible designs; select one biome and form
before saving an individual asset. Save buttons disable in overview, and the store
rejects ambiguous multi-specimen saves before writing. Prior saved selections are
preserved when revisiting a session. The anatomy comparison station also defaults
to all biomes. Earlier procedural forms remain a reference station.

Size class, biome/role locks and cutaway have one visible control each; their
redundant generic Inspector-derived controls are hidden in the shared dock.
Randomize, size presets and library load rebuild the specimen in place, preserving
the editor controls rather than destroying their fixture during a button callback.
The full maker flow now passes 34 checks, including default overview, focused
saving, recipe restoration, seeded randomization and unlock behavior.

Comparative scale: the plant editor shows a world-unit height ruler and a neutral
1.8-unit standing figure by default. All visible samples use the same unit scale;
the all-forms overview uses each form's Small/Medium/Large game-height preset,
so a tree is not normalized to the same height as a ground plant. Focusing a form
restores its custom dimensions (or class defaults on first selection). Select a
single biome/form for a closer framed view. `show_scale_reference` can hide the
ruler/figure for extreme closeups; `reference_height` changes the reference figure.
Both belong to **Scale comparison**. Scale markers are viewer-owned and excluded
from saved plant meshes, gameplay geometry, flora membership and reserves.

Biome scene viewer and visual balance (October 30): **Biome scenes** is the default
layout, with each biome's tree and five ground-plant forms sharing a ground patch
at comparative scale. **Plant grid** restores individual specimen plots. Viewer
arrangement is an art comparison, not a replacement for generated-cell placement.
With the reference visible, the maker uses an orthographic camera so foreground
plants are not enlarged by perspective. The reference ruler aligns with tree
root depth and remains outside saved plant assets.

Trees now have connected secondary structural forks, with adjustable
`tree_fork_depth`, `tree_fork_spread` and `trunk_lean`. Forks taper toward smaller
children; foliage remains attached to their tips. Meadow crowns spread, Woodland
forks rise, Heath keeps its jointed form and Marsh keeps lower stilt roots with
shorter drooping curtains. Crown fullness and sparse woodland/heath Emanator
foliage were increased moderately. Anatomical plant materials reduce palette gain
from 1.4 to 1.1 to retain softer leaf/flower color and stem contrast. Existing
fullness, density, color and branch controls still apply. These are visual changes;
no reserves, circulation rules or generation membership change.

Plant maker quick actions: Randomize and Lock as official are at the top of the
plant editor. Each roll starts a new candidate identity; official saved plants
remain in the library. Tree rolls span Small/Medium/Large. Color assignments,
Color diversity and Hue shift tune tree crown variation; rebuild on release.

## Plant community experiment — October 30, 2026

Production follow-up, October 31: `resources/plant_community_settings.tres` owns
new-expedition patch size (3–24 cells), coverage (0–1), spacing (0.5–4 cells),
canopy influence (0–1) and drainage influence (0–1). The world plane exposes
`community_settings`; the world controller captures validated parameters before
generation. Loads retain the saved parameters rather than applying later edits.
Coverage zero removes community trees and generic understory, while canonical
grass and specialist admission retain their existing owners. These are layout
preferences constrained by access, terrain and canonical reserve registration.

Development Lab → **Plants / communities** → **Coverage** exposes habitat,
generation seed, patch size, coverage, spacing, canopy influence and geographic
offsets. Typed ranged exports live in `tools/plant_community_lab.gd`; the shared
workstation supplies sliders with visible values and rebuilds on release.
These controls affect this synthetic fixture only and never expedition saves.
See [procedural plants](procedural-plants.md#plant-communities-experiment--october-30-2026)
for ownership, limitations and evidence.

Live procedural plant colors: `BIOME_LEAF_PALETTES` in
`scripts/scenery/plant_vastra_anatomy_mesh.gd` owns five curated leaf swatches
per habitat. The shared library selects `biome_palette_variant` deterministically
for tree/specialist size variants and undergrowth forms. Rebuild streamed scenery
(or restart exploration) to apply edits. Authored library recipes retain their
selected colors; grass keeps its reviewed palette. This changes presentation only.

New-expedition plant rarity: `ExpeditionSettings.flora_specialist_percent` defaults
to provisional 5% and is captured in the state; loaded saves retain their value
(old snapshots use 25%). Geographic potential permits no-specialist areas, without
minimum class counts or population repair. Viewer **Natural biome mix** uses
`common_foliage_samples` and `preview_specialist_percent` only for its example
scene. **All plant designs** restores the full editable collection.


Official plant species (October 30): `resources/plants/official_catalog.json` owns
45 read-only baseline recipes and their `variation_limits.numeric_ranges` and
`fixed` identity settings. The Maker exposes bounded sliders for an active species
and saves `catalog_design_id`, `species_id` and `specimen_seed_override` on each
copy. Detach with **Customize freely as new design** for unrestricted controls.
Imported `common_trees`, `hardy_trees`, `nonliving_trees` and biome `trees` palettes
are retired empty compatibility fields; use the procedural plant library.


Vegetation and close-camera update (October 31): NatureSettings
`plant_instance_variation` defaults to 0.22; foliage patches use the same blade
ground-cover owner. View3DSettings `minimum_distance` defaults to 2.5 cells;
`close_elevation` (12 degrees) and `close_focus_height` (0.75 player heights)
blend toward close third-person framing below the starting distance, read live.
Close elevation sets the neutral 35-degree orbit pose; vertical orbit still
responds across the input range and can reach 80 degrees at every zoom distance.
TerrainReliefSettings `walkable_slope_degrees` defaults to 35 degrees for new
expeditions; ClimateSettings `moisture_frequency` defaults to 0.007. Saved
terrain/climate retain their captured tuning. Woodland shading blends supplied
Ground037 moss/litter color, normal and depth maps at shared terrain vertices.

Plant root collars: PlantDefinition `root_burial` defaults to 0.06 world cells,
range 0–0.2; rebuild scenery after editing. Plant event poses now apply half
the former amplitude for all activities; receiving uses rigid sway with unit
scale. Existing animation strength/duration controls still apply. These are
presentation changes; no Vastra transfer or growth mechanics changed.

October 31 vegetation revision: live grass uses narrow procedural leaves;
foliage stays separate. `meadow_enabled` toggles leaf-grass cover; `foliage_coverage`
controls seeded density. Existing blade height/division/appearance controls are
retained for blade studies. Live cover uses its own `grass_distance`, independent
of detail distance and bounded by the terrain/tree horizon. Nature Settings'
short/medium/tall height ranges own live clump stature; `root_burial` is capped at
10% of above-ground height. Rebuild/restart applies to geometry and placement.
Every admitted empty emanator tile receives leaf grass when coverage is positive.
`foliage_coverage` scales clump count within each tile instead of randomly removing
whole tiles. A seeded world-space noise field gently varies count (24–36 before
coverage) and height across neighboring cells; leaf models, yaw and position
remain varied. Roots stay within their canonical tile and reject unscalable
surface points. Paths, reserved terrain and separate plant bodies retain admission.

Tree recipes now carry `crown_habit` (rounded/narrow/spreading),
`branch_rise_degrees`, `branch_curve`, `trunk_curve`, `trunk_phase`, and `trunk_lean`; the shared
builder constrains biome ranges and fits tree instances uniformly. All three
size classes exist for each habit. Main stems precede leaf-bearing supports in
the spacing pass; optional growth is fitted or omitted while functional anatomy
stays connected. Branch collars are part of the shared indexed bark surface.

The leaf shaders retain `leaf_saturation_min/max` (0.65/1.65) for the authored
spatial palette. Nature Settings owns `reserve_saturation_floor` (0.35,
range 0–1), `reserve_droop` (0.30 model units, range 0–0.6) and
`reserve_transition_seconds` (1.2 seconds, range 0.1–3). Reapply/restart updates
both CPU retargeting and the shared leaf shader. Stored energy divided by
capacity supplies the canonical cell's fraction; full reserves keep authored
posture and pigment, while depletion lowers free tips and reduces saturation
toward equal-luminance gray. No white tint, damage flag, reserve or anatomy is
written. Bark, exchange organs, flower pigments and leaf attachments stay fixed.
Wind remains layered over the reversible posture.

Atmosphere Settings owns live `foliage_gust_strength` (0.7, range 0–1),
`foliage_gust_seconds` (8, range 2–30 seconds) and `foliage_gust_cells` (24,
range 4–64 cells). Zero strength restores steady wind. Traveling gusts and local
flutter share the saved weather clock and direction; pause freezes them and
floating-origin shifts do not reroll the field. Source and shared grass fade
materials receive the same weather controls.

Live Vastra rendering intersects published render bounds and the camera frustum
with `View3DSettings.vastra_distance` (24 cells, range 8–48) around the player.
`vastra_fade_cells` (6 cells, range 2–12, less than the radius) fades the outer band.
These two settings are read live, apply to loaded worlds, and never enter saves.
Zooming out does not expand the effects radius. `current_region_limit` governs
the isolated web study only; live budgets remain `current_limit` and particle
`transfer_limit`, distributed across eligible source regions. Active plus fading
filament layers are capped at twice `transfer_limit`, including nodes queued for
deletion when admitting replacements. Filament culling follows the real path
inside the effect range. This changes visibility only:
saved geographic simulation activation, energy supply, recipient selection and
arrival times remain independent of camera/zoom. Eligible visuals require real
exchanges with published endpoints; no distant transfers are invented.

Step 4 circulation controls: `VastraSettings.plant_emission_phases` is saved in
the new expedition's plant policy (1–8 slots, 0.75 active seconds each). The
production resource selects 4; the Resource class and older policies default to
1. Full sources wait with their reserves intact. A slot crossed between bounded
service visits remains eligible, preventing phase/work-queue alias starvation.
Loaded saves retain their own timing; restarting alone does not replace it.
`current_junction_cells` (3 cells, range 2–6) rebuilds optical shared routes live
within 0.5 seconds. It never reselects recipients or changes ledger travel time.
Shared air junction height follows 30% of `current_hover_height` over ground
clearance; soil junctions retain ground clearance.

`VastraParticleSettings` adds live `intersection_softness` (0.12 cells,
range 0.01–0.5), `breathing_strength` (0.18, range 0–0.5) and
`breathing_seconds` (6 active seconds, range 2–20). Zero breathing strength keeps
steady packet optics. Saved activity time, source phase and path distance drive
traveling brightness; no global synchronous forest pulse or second clock is
introduced. Actual packet amount scales visibility relative to saved capacity;
head count remains optical only. Curved strips use full path length, not the
straight endpoint distance. Taper/depth softness do not change arrival/credit.

October 31 paced-transfer follow-up: production sets `plant_refill_rate = 1.0`
(formerly 4.0 units/active second at concentration 100) and
`plant_transfer_rate = 8.0` units/active second. The class retains the explicit
legacy fixture mode (`plant_transfer_rate = 0`); positive rates must be at least
0.01 and at most 100. Load/reapply applies these two pacing settings through
`configure_flora_pacing`, without changing capacity, identity or durations of
already-started flights. Restart/reapply is required for Inspector changes;
no new expedition is needed.

A 100-unit release at eight units/second lasts 17 activity ticks (12.75 seconds),
separate from travel at `plant_transfer_speed`. Committed stock remains physically
at its outlet until departure and cannot pay another action. The recipient takes
portions only after the travel delay, reaching the total as the last portion
arrives. Details/posture include the physically held source stock; `reserved`
exposes its committed share. Partial credits occur on 0.75-second activity ticks,
not through invented UI interpolation.

Stream heads distribute across the saved release window, with strips trailing
their heads instead of protruding ahead of the actual arrival. Paced paths run
from external outlet to intake; tree rings use their authored surface radius and
plane instead of an occluded trunk-center point. External spans use cubic vector
curves with fixed ports and a 64-point GPU budget including internal anatomy.
At intake, each crossed particle/strip fragment is removed at the surface;
the remaining tail keeps moving without an arrival or age fade. Strip lifetime
includes the time for its trailing end to enter. Existing distance visibility
and admission controls remain independent. Invisible completed paths no longer
occupy visible slots; delayed final credits cannot replay a partly received train.
Every accepted tree leaf has its own derived outlet and connected petiole, even
when several leaves share a branch socket. An onward non-root transfer selects
the nearest leaf to its destination; ring intake and soil/root exchanges retain
their roles. Rebuild the runtime plant palette after anatomy code changes, then
restart/reload to use the refreshed cached outlets. No new balance slider or
per-leaf reserve is introduced.

November 1 ground-condition follow-up: the terrain palette conditions living
grass/moss before blending roads and rock over it, including woodland ground.
Missing plant cells no longer count as full reserves when interpolating ground
pigment. A bounded search at one, two and four cells continues known neighboring
pigment over nonliving footprints; wholly unknown areas keep authored color.
This is cosmetic sampling and never admits vegetation or changes energy.
`NatureSettings.biome_blend_cells` defaults to 4 (range 1–8 cells), widening the
weighted nine-sample biome tint kernel. `biome_edge_blend` retains its 0–1
strength control. Rebuild/restart applies to existing expeditions; generation,
habitat boundaries, road access and species identity remain unchanged.


Plant Maker exposes `fern_growth` as **Fern fronds** in its Foliage controls.
This boolean opts generic foliage into connected pinnate fronds and is saved
with its recipe. It defaults off. Rebuild the maker preview to see the change;
H33 remains a review draft until approved. Accepted models live under
`resources/plants/reviewed_baselines/`; editing a recipe alone does not rebuild
its baked mesh in the Godot editor.

## Examine and tree storage

Examine follow-up (October 31): `VastraSettings.tree_capacity` defaults to 1,000
stored units, independently of the plant/packet threshold. It is captured for new
expeditions; saved policies without this field use 1,000. Existing energy is retained.
`MenuSettings.inspection_animation_seconds` (0.1–2 seconds, default 0.65) controls
live examine bar/number interpolation. New targets show their current readings
immediately; changes on the same target animate from the displayed amount.
Examine combines appearance, facts and meters with centered text.

## Plant leaf and grass reserve appearance

November 1 flow/size follow-up: generation uses six 0.125-second credits per
existing ecology interval, retaining `VastraSettings.plant_refill_rate` and its
units/second. `NatureSettings.foliage_size_multiplier` (0.5–3, default 2) scales
foliage before the existing access/footprint fitting; restricted sites may use a
smaller fit. Rebuild/restart applies this visual control to loaded worlds. Grass
blade height remains under the grass controls. Culling bounds include the supported
foliage scale ceiling; saved identity, membership and reserves retain their owners.

November 1 reserve follow-up: the existing Nature Settings **Plant reserve
appearance** controls also reach optional meadow blades and grass ground.
`reserve_droop` controls free-tip lowering at empty reserve (full charge restores
the authored height); `reserve_saturation_floor` controls depleted pigment on
leaves and turf. `reserve_transition_seconds` controls temporal interpolation
for both. Ground colors blend between canonical cell centers, including render
chunk boundaries. Reapply/restart to use appearance changes. Saved energy and
capacity remain authoritative, including the independent 1,000-unit tree cap.

## Wind presentation

Wind presentation (October 31): `AtmosphereSettings.wind_strength` is a live
0–8 multiplier (provisional default 5) on the view's prevailing `cloud_wind`.
`wind_variation` (0–1, default 0.75) smoothly builds/eases that airflow over
`wind_cycle_seconds` (4–120 active seconds, default 24). Plants, meadow grass,
airborne leaves and rain lean consume the same sampled airflow; local foliage
gusts remain layered over it. Zero strength is calm; zero variation is steady.
The saved activity clock freezes/reconstructs the cycle across pause/load.
Cloud translation retains its existing sky control. This is presentation only.

## Procedural structure objects

See [Structures](structures.md) for the rebuild-only stone obstacle Resource controls, module catalog, preview scene and integration boundaries. These settings currently affect isolated objects, not expedition generation.

Stone obstacle recipes now expose ten families, Surface Style (five authored PBR sets), and overall Scale up to 4. All apply on rebuild. See [Structures](structures.md#expanded-relic-obstacle-kit--october-31-2026) for family-specific input applicability.

## Combat board markings

October 31 presentation follow-up: floating titles over battle units, wild Sols
and the owned companion are hidden. Screen-space health cards, Examine and
transient damage/healing feedback retain their information. Legacy companion
caption-clearance/routine-caption fields no longer affect visible overhead text.
Shared mouse confirmation dialogs keep action labels on one line during text
scaling; explanatory paragraphs still wrap. The real readiness Run confirmation
was rendered at normal text/1280×800 and enlarged text/900×600.
`tests/run_menu_layout.gd` passed 64 checks; `tests/owned_companion.gd` passed 41.
Godot 4.7.2 import and scoped whitespace checks passed. Local screenshots and
receipts live in `artifacts/run-menu/` and `artifacts/run_menu_*.log`.

`SolVisualSettings` → Battle Interface owns the combat board presentation.
`board_ring_width` thickens unit/target/path rings; `board_boundary_width`
controls the arena ribbon. `board_ember_rise`, `board_ember_size` and
`board_ember_opacity` tune sparse Vastra embers rising from those patterns.
Zero rise or opacity disables the embers. `board_grid_width` and
`board_grid_opacity` control thin internal grid lines, sampled against actual
terrain height. The grid has no emission effect. Changes apply on the next
battle visual refresh; none changes movement, arena limits or saved state.

## Startup loading and generation pace — November 1, 2026

The main entry is `scenes/start_menu.tscn`. Its `Play Generation Ms` field sets the
post-entry main-thread chunk allowance (default 1 ms, range 1–3 ms). The startup
area is a fixed 64-chunk 8x8 footprint around the player; both new and saved games
wait for it. A single preparation job and one publication per frame remain the
policy after entry, with outer work capped at 0.5 ms. Runtime view settings are
duplicated before these overrides. Canonical local flora is registered in batches
of 64 definitions, ground plants first, then trees; simulation starts only after
active membership/network indexing is complete. No existing reserve is reset on load.

## Shared vegetation instance-write budget — November 1, 2026

WorldSolid's `Vegetation Writes Per Frame` defaults to 512 (32–4096). Reserve
custom-data and reaction-pose writes share this cap, rotating in groups of at most
32 writes. Dense vegetation may catch up over several frames. This controls optical
updates only; ecological timing and conserved values are unaffected. Ground reserve
textures retain their separate bounded sampling/upload path.

## Distance tiers and zoom — November 1, 2026

View3DSettings defaults: Starting Distance 18, Maximum Distance 26, Grass Distance
26, Detail Distance 32, Tree/Render Distance 72, Shadow Distance 32, Vastra Distance
38. Options → Camera Zoom enables/disables dolly immediately and remembers it
locally; disabling holds the current view distance. Home still resets the camera.
The exported Zoom Enabled default applies when no saved preference exists.
Near/middle/far chunk groups use native LOD bias multipliers 1/0.5/0.25 at nearest
chunk distances 24/48 cells. Middle/far groups omit detailed shadows. Full-resolution
picking and canonical simulation retain their existing owners.

### Public player fallback — November 2, 2026

`scenes/customizable_base.tscn` uses the original project body by default. Its
`use_local_source` export is an optional workstation presentation setting, applied
when prepared; it selects the supplied human and retargeted rogue locomotion only
if all three withheld files exist. It is not saved identity or gameplay tuning.
Default public builds reuse the existing terrain gait and skin-color control.
