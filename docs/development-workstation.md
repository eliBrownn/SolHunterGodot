# Development workstation


## Review workspace rollout — October 30, 2026

### Creative additions — October 30, 2026

Use **Creative additions** in the lab's top bar to browse proposed new content.
The same entries appear under **Browse** and in the station picker. This section
reuses Settings, View, Compare and Review; saved drafts stay local to the lab.

The first entry, **Creative additions / relics**, shows seven original procedural
families. Choose the original trio or focus a marker, arch, foundation, split ring,
spire circle, courtyard or sanctum. Adjust the concentration, signed condition and response
strength sliders; toggle purpose labels. High concentration and disruption can
coexist. Compare the healthy, disrupted and restorative treatments and save feedback.

Procedural follow-up: **New design** advances the seed while retaining other
settings. **Design seed**, **Structure scale**, **Missing stonework** and **Rubble
pieces** control reproducible variations. A shared visual builder generates tapered,
chamfered stones, segmented arches and foundation courses. Separate structure,
breakage, surface and rubble streams keep dressing changes from rerolling the
parent layout. Changing Vastra conditions does not alter that layout. Seeds and
tuning save in the existing local station draft. World spawning remains planned.
The procedural journey verifies reproducibility, seed variation, independent
dressing/conditions, finite bounded geometry, outward normals and New design.
Godot 4.7.2 import, the rendered journey and the 185-script ownership audit passed.
Current procedural logs are `artifacts/relic-procedural-import.log` and
`artifacts/relic-procedural-render.log`; two seeded designs were visually reviewed.

**Send Vastra in** sends a finite packet from each visible relic's external test
supply through its mapped crevice veins to the shared node core. **Run purpose /
output** spends reserve on the selected purpose; automatic output is adjustable.
Markers default to clue reveal, arches to a relay receiver, and foundations to
layout reveal. Purpose can be selected independently of silhouette. Arrival, not
departure, completes each effect. **Reset test supply** explicitly restarts the
lab circuit. Rebuilding/switching a fixture also resets its test energy.

**Stone material** selects Black stone, Abyssal stone or Ash-black stone using the owner's
selected ambientCG Rock051 surface, with authored color/normal/roughness/AO/metalness
maps. **Ancient node carving** selects Square seal, Diamond seal or Narrow seal.
These preserve the logical Core/InputPort/OutputPort contract, while cutting the
visible node into its owning stone. Etch-outs have perpendicular 90-degree sidewalls
and flat bottoms cut into the stone, not attached tubes or strips. A masked light
pass on that same mesh confines the Vastra response to the recesses. Physical frames,
port collars, the central orb and in-world IN/OUT/readout labels have been removed.
Channels follow seeded fracture routes projected onto stone surfaces; this is not an
automatic mesh-crevice mapper. Readings include source, reserve, travelling energy,
receiver output and spent energy. Housing/material changes cannot reroll geometry.

This is a bounded lab simulation, with no expedition harvesting, ecological writes,
save migration, repair or production rewards. The
[relic plan](relic-roadmap.md) retains the production integration sequence.
Review status does not approve test costs or adopt these examples into the game.
The expanded node journey covers seven families, three material/carving styles,
fixed ports, mapped route endpoints, finite supply, no early credit, purpose sinks,
exactly-once arrival, reset, and the real intake button. Node/material source maps
and the scene/script ownership map are checked separately. Current node logs are
`artifacts/relic-nodes-import.log` and `artifacts/relic-nodes-render.log`; screenshots
include `relic-node-style-*.png`, `relic-node-output-*.png` and
`relic-reference-family-*.png` under `artifacts/`.

Ancient-stone revision: `scripts/scenery/relic_carving.gd` projects the routes onto
admitted stone surfaces and cuts bounded, square-bottomed grooves and seal recesses into those
meshes. Rubble remains independent. Prepared meshes have a bounded 12-layout cache;
condition/energy changes update presentation without recarving. Authored normal maps
still provide fine stone relief. `tests/relic_concept_preview.gd` verifies actual
inward vertex displacement and absence of attached channel/housing geometry alongside
the prior energy checks. Final logs: `artifacts/relic-carving-render.log` and
`artifacts/relic-carving-import.log`; the native viewport close-up is
`artifacts/relic-ancient-stone.png`. This is focused lab validation.

Black-stone and range follow-up: the current generation version is 5. **Missing
stonework: intact → skeletal** spans 0–2; **Stone courses / layers** spans 2–12;
**Uneven break variation** spans 0–1. Seeded breaks remove upper courses before
lower support, with independent heights across walls, monoliths and spires. Arch
spring stones follow their surviving supports. Rubble remains independent and the
shared geometry ceiling is 160 pieces. **Square-cut etch depth (m)** spans 0.04–0.12.
Bottom faces of thin slabs are protected from a second excavation. Try the intact,
uneven-courses and skeletal presets alongside the four environmental presets.
Black-tinted Rock051, cooler fixture lighting and reduced neutral Vastra brightness
establish the ominous presentation without new gameplay effects. The focused
geometry/energy journey verifies perpendicular wall normals and constant-depth
floors; rendered range/close-up evidence and logs are under `artifacts/relic-square-*`.
Run `tests/relic_concept_preview.gd` for the section/filter, fixture, tuning,
independent-condition and draft-retention journey; a rendered run also writes
normal/compact-window captures under `artifacts/relic-*.png`.

Validation: Godot 4.7.2 import completed without engine/script errors; the existing
workstation journey and the Direct3D 12 relic journey both reported zero failures.
Normal 1600×1000 and compact 1100×720 captures were inspected. Logs are
`artifacts/relic-import.log`, `artifacts/relic-workstation.log` and
`artifacts/relic-render.log`. This is focused lab validation, not a full game pass.

The lab is a shared place to try a change, compare it, and save the result.
It keeps test data separate from the expedition and does not write production tuning.

### Start here

1. Choose a test using **Browse**. Favorites and recent tests appear first.
2. Open **Try a test** in Settings and choose a starting scenario.
3. Use **View** to pick an object and **Move closer**, or click it in the scene.
4. In **Compare**, take a **before picture**, change a setting, and drag the
   comparison slider or the picture divider. Before is on the left; now is on the right.
5. In **Review**, name the experiment, record what happened and the next change,
   choose **Needs changes**, **Ready to check** or **Accepted**, then **Save review**.

### What each tab does

| Tab | Use it for |
| --- | --- |
| Settings | Guided tests, grouped sliders, exact number entry, single-value/group resets, undo, and saved settings with rename/delete |
| View | Object selection, size/readings, turn/pan/zoom, front/side/above views, whole-scene or selected-object framing, names/tips, metre ruler, mesh edges, surface direction, and energy endpoints where present |
| Compare | Before pictures, changed settings, matching camera, optional known-time replay, and a draggable before/now divider |
| Review | Named experiments, status, next action, saved pictures, clean captures, full-window captures and concrete change notes |
| Speed | A two-second warm-up plus at least five seconds of frame samples; average, slow-frame estimate and sample count |

Right-drag turns the camera, middle-drag moves it, and the wheel zooms. These
shared controls work while paused. Turn off **Click objects to select them** to
use a gameplay-backed preview's original click interactions. **Show on-screen tips**
also reveals those previews' runtime game interface; game menus retain their
original behavior and are not dismantled into lab controls.

Static art panels and station tuning controls are docked beside the preview,
including rendering benches, plants, forests, terrain, Vessels and Sol workshops.
Extra captions move to **View → Test info**. The underlying standalone scenes keep
their original interfaces. Custom Vastra docking remains supported.

### Repeatable tests and honest comparisons

Grass offers strong-wind, night and four-habitat tests. Vastra offers a known
single-transfer test and quiet/busy background energy. Rendering benches include
low sun, fog, calm/stronger water, clear/blocked targets and light/heavy particle
loads. Plant and animation stations have focused starting tests. Other previews
restart their existing defaults with a review prompt.

**Start this test** deliberately resets the current test settings and prepares the
scenario. The panel then folds away so tuning remains easy to reach. Grass and
Vastra can restart the same setup and advance their existing root simulation in
fixed 1/60-second steps to a chosen 0–10 second test time. A guided transfer repeats
its existing send action. No independent particle speed or invented ecological rule
is introduced. Other stations explain that they can restart but cannot reproduce
an exact simulation time. GPU rendering and shader TIME are not deterministic replay.

Before/now comparisons flag changes in camera, viewport size and settings. A
recorded picture can show a different animation time. The saved camera includes
projection, field of view and size as well as position/orientation. Object framing
uses visual bounds; it is an inspection aid, not gameplay picking or terrain admission.

Speed results include the whole host window rather than isolated GPU time. Changing
the camera, controls, viewport, pause state or station interrupts a measurement.
These results do not qualify target-device performance.

### Local storage and implementation handoff

Workspace preferences and per-station drafts save every two seconds to
`user://workstation/workspace.cfg`. Saved settings save immediately. Switching
stations retains each station's setup, notes, supported camera and draft review.

**Save review** writes `user://workstation/reviews.cfg` and review pictures under
`user://workstation/reviews/`. A review contains its question/observation notes,
settings, camera, before picture, current picture, review state and next change.
**Open review** restores those settings and pictures; the live simulation starts
again. The stored current picture remains available even when exact simulation
replay is unsupported. Saving a copy creates a separate record. A session-only
before picture becomes durable when its review is saved.

**Take picture** saves a preview PNG and JSON report under `user://workstation/`;
**Take full-screen picture** includes the lab interface. **Hide names and tips in
pictures** temporarily hides scene labels and view helpers and restores them after
capture. Reports record that choice. Baseline and saved-review captures support it.

**Write change note** writes a concrete local Markdown handoff with proposed setting
changes, live controls, observations and known source references. It uses the last
saved review, so save after editing its notes or settings. **Accepted** is a local
review state; it does not approve canon, update resource files, or apply values to
the game. Lab-only test reserves and optical settings must never be copied as
production mechanics. Changes to actual game settings remain separate reviewable
repository work.

### Ownership and integration

`tools/development_workstation.gd` owns layout, playback, parameters, comparison
reports and workspace preferences. `tools/lab_station_tools.gd` owns the hosted
panel adapter, common camera, visual bounds selection and reversible view helpers.
`tools/lab_review_tools.gd` owns guided tasks, known-time test stepping, the divider,
review records and change notes. Fixtures retain their simulation/presentation owners.

Custom stations may expose `workstation_parameter_info(key)`,
`workstation_dock_controls(host)` and `workstation_readings()`. Other stations use
the shared adapter without modifying their standalone scenes. Live control records
use stable names derived from control purpose/options, frozen on first use, plus
a station-script revision guard. The workspace revision is now `workspace-3`;
older live-control snapshots are skipped rather than applied to a changed layout.
Exported settings remain checked against the current fixture's supported properties.

Mesh-edge and surface-direction modes use temporary per-instance material overrides;
they do not edit source materials. They show base geometry and can omit the original
shader's vertex deformation. Selection bounds and endpoint markers are lab helpers,
not gameplay targets. Common camera control does not replace gameplay movement.

### Validation and reproduction

Run the pinned Godot 4.7.2 engine with:

- `--headless --path . --script tests/development_workstation.gd`
- `--headless --path . --script tests/lab_review_journey.gd`
- `--headless --path . --script tests/grass_blade_preview.gd`
- `--headless --path . --script tests/development_world_toggle.gd`

`tools/review_lab_upgrade.gd` renders desktop/1100×720 views, selection, mesh-edge and
surface-direction modes, the divider and named review UI. It verifies paired preview
capture and actual before-image/library reopening. It uses a separate artifact
workspace, not personal saved lab settings. Images/logs are under
`artifacts/development-workstation/upgraded-*` and `review-*.log`.

Verified with Godot 4.7.2: editor import passed with no engine/script errors;
the all-25-station journey passed 83 checks. A later focused journey passed 72
checks, including refreshed selection after changing biome pages. Workstation and
grass suites passed, the expedition round trip passed all 18 checks, and the
rendered review verified its saved images and reopened library. The short-window
render shows all five tabs without scrolling the tab strip. Logs are the
`review-*` files in the above artifact directory.

The full gameplay suite was not rerun for this development-UI change.

## Procedural plants

Choose **Plants / biomes & Vastra anatomy** for one proposed sample per
biome/role/class combination: 24 total across Meadow, Woodland, Heath and Marsh.
Use the biome and role selectors to compare a habitat, a role across habitats,
the full grid or one specimen. **See inside the plant** reveals connected
conducting tissue, storage and exchange surfaces; organ annotations appear for
individual samples. Sliders reshape anatomy and outer growth. Launch with
`-- --plant-anatomy`. These are static anatomy proposals, without live energy
transactions or newly approved species/abilities.

The revised samples have distinct habitat growth structures: meadow fans,
woodland divided fronds, thorned heath cushions and marsh pitchers/stilts/ribbons.
The sidebar now groups 24 numeric controls, with help on parameter labels.
**Reset shape controls** restores the shape defaults. **Silhouette view** compares
plant outlines on a pale backdrop; selecting a role across all biomes places
its four samples side by side. Biome-specific controls identify their scope.

Choose **Plants / procedural forms** for the October 30 morphology proof: eight
growth forms with three seeded variants each, generated using existing painted
leaf/flower/bark textures and authored bark/ground normal maps. Select a form for
close review; right-drag to orbit and scroll to zoom. Sidebar sliders adjust seed,
branch count, plant/leaf size, foliage, curl and wind. **New seed variations**
rebuilds the specimens. Launch with `-- --plant-prototype` to select this fixture.
See [procedural plants](procedural-plants.md) for scope, checklist and validation.
This is an isolated art study; species and production rollout remain open.

## Temporary lab world from the game

The main-game footer also provides **Sol Lab [F9]**, a separate Sol-authoring
workspace. F9 opens/returns from Sol Lab; F8 opens/returns from this Development
Lab. Pressing the other lab's key switches directly while keeping the expedition
suspended. Both workspaces retain their in-memory edits between visits. See
[Sol Lab](sol-lab.md) for its appearance-authoring workflow.

Press **F8** or click **Development lab [F8]** in the lower-right corner of
normal play. The existing standalone development workstation opens as a separate
world. Press F8 or **Return to expedition [F8]** to return to the same expedition.
The main scene remains `scenes/world_3d.tscn`; F6 on the standalone workstation
still works. This is a temporary development convenience, not a gameplay location.

The expedition stays in memory with its clock, movement, input, GPU particles,
audio and HUD suspended while the lab is open. Returning restores its previous
processing/visibility/audio state, including an already-open pause screen. No
expedition save/load or regeneration is used to switch worlds. The lab instance,
selected fixture, parameter changes, notes and lab pause choice survive visits
until the game closes. The lab has its own World3D, and gameplay-backed fixtures
retain their existing save/load block. Hosted fixtures do not create nested world
switches. This does not adopt experimental lab effects into production Vastra.

`tools/development_world_toggle.gd` owns the temporary switch. The workstation's
mixed indentation errors are corrected so it loads under the pinned Godot version.
Run `tests/development_world_toggle.gd` for isolation/round-trip checks; add
`-- --capture-lab-world` with Direct3D 12 for an actual toggle-world screenshot.


Open `scenes/development_workstation.tscn` and press F6. This is the single
development entry point; the game keeps its normal main scene. Existing lab,
preview and workshop scenes are reusable fixtures inside its isolated viewport.
Use the selector to switch between particles, vessels, forest looks, biome assets,
landforms, cohesive world, creature exercises and gameplay pilots. Only one fixture
runs at a time. Grass uses grouped shared controls; Vastra docks its live controls
outside the preview. Other art stations use the shared panel adapter; runtime game menus retain their original interactions.

The lab uses the normal field menu's shared theme and `resources/menu_settings.tres`
palette. The fixture toolbar wraps, and the review sidebar scrolls on shorter
windows. Boolean parameters use switches; ranged numeric parameters use labeled sliders
that apply on release. Other scalar parameters accept Enter or Apply to rebuild. Restart retains applied settings, camera, notes and baseline. The visual review script `tools/review_workstation.gd` writes a preview
to `artifacts/development-workstation/preview.png`.

UI polish validation: Godot 4.7.2 import passed; the workstation suite passed
with zero failures and the expedition/lab round trip passed all 18 checks.
The shared-theme layout and paired capture were inspected using the OpenGL
compatibility renderer. The full game suite was not rerun for this UI change.

Pause stops the fixture subtree and GPU particle speed; Step advances one host
frame and pauses again. This is a visual frame step, not a deterministic physics
replay. Shader TIME effects can keep animating while node processing is paused.
Restart reconstructs the current fixture, retaining its setup.
Switching stations preserves each station's setup, notes and session baseline. Scalar exported parameters are editable
in the sidebar and applied by rebuilding; range hints clamp numeric input.
Resource parameters remain available in the fixture's Godot Inspector.

Record expected behavior, observed behavior and the next change in Test Notes.
Take before picture records the image and numerical/context report. Copy test details includes
notes, fixture variables, live slider/preset/toggle values, camera transform,
elapsed test time and viewport dimensions. The baseline appears in subsequent
reports. Host frame mean is wall frame time, including editor/render overhead,
not an isolated GPU benchmark. Draw calls and object counts are viewport readings.

Take picture saves a paired PNG and JSON report under `user://workstation/`.
The sidebar shows the absolute path. Share that pair for visual discussion; the
JSON records context rather than promising a complete replay of arbitrary fixtures.
Reports and captures are local development artifacts, not gameplay saves.
Gameplay-backed pilots block expedition save/load while hosted here; normal game
save/load stays unchanged. Story preview still creates its own artifact directory.

Validation: run Godot headless with `--path . --script tests/development_workstation.gd`.
For visual review, run the workstation, adjust a particle preset, pause, annotate,
capture, switch to a creature exercise, then reset and resume.

Temporary-world validation: Godot 4.7.2 editor import passed; the standalone
workstation suite passed; the real Direct3D 12 toggle journey passed **18 checks**,
including frozen expedition state, particle/audio restoration, retained lab tuning
and notes, hosted save blocking and no nested switches. The actual lab view was
inspected at `artifacts/development-world/lab.png`. Full-suite validation was not
run for this temporary world entry.

## Additional visual stations

Eight more selector entries support focused review:

| Station | Useful comparisons and controls |
| --- | --- |
| Lighting / shadows | Sun angle, energy, ambient fill, fog, shadow opacity, warm/neutral tint; shared cube, sphere, tree and rock references |
| Materials / response grid | Fifteen identical spheres across roughness and metallic values; rotate the light under identical conditions |
| Water / depth and foam | Actual game water shader on a known 0–1 m depth ramp; tune ripple speed/strength, foam width and color depth |
| Readability / scale and occlusion | Same 1.8 m silhouette at three depths; adjust foreground blocker position/height, target brightness, FOV and viewing distance |
| Particles / density and overdraw | Fixed-seed 128–8192 transparent particles; tune size/opacity and compare host frame metrics with a baseline |
| Animation / slope and actions | Rattlehorn on the existing slope route; clickable signature/attack/hit and movement-speed controls |
| Animation / flight | Sailcrest takeoff/flight/landing through the existing workshop traversal contract |
| Animation / swimming | Rimefold in the existing workshop swimming fixture |

New benches support right-drag orbit and wheel zoom. Their controls change only
the current fixture, and reset restores defaults. Reports include station-specific
readings via `workstation_readings()`, including live values and animation identity.
Lighting presets are an art rig, not a replacement weather simulation. Particle
counts are a synthetic visual load, not a target-device performance qualification.
The readability targets are calibration silhouettes, not gameplay targeting logic.
Water depth values are an authored test mask rather than generated river geometry.

Run `tests/visual_stations.gd` for the new stations' focused validation.

## Single-blade grass prototype

Choose **Grass / single blades** in the lab selector. Four side-by-side patches
compare meadow, woodland, heath and marsh. Each instance is one tapered,
seven-triangle blade. Right-drag orbits; the wheel zooms. Sidebar sliders
control blades per square metre, blade height/width/curve, wind strength and wind
direction; releasing a slider rebuilds while retaining other applied values. Density and
size inherit provisional biome multipliers. Pause freezes the wind clock.

This isolated art fixture consumes the existing meadow shader through private
materials. It does not change production grass, weather, generation or Vastra.
Production rollout must use existing terrain admission and canonical cell flora
endpoints; visual blade counts must never multiply cell reserves. Lab samples
have no expedition or ecological ledger.

Launch directly selected with `scenes/development_workstation.tscn -- --grass-prototype`.
`tools/review_grass_blades.gd` captures the lab and a paired settings report under
`artifacts/grass-prototype/`; `-- --keep-open` leaves that review window open.
Focused validation: `tests/grass_blade_preview.gd`.

Owner review, October 30, 2026: approved the four-biome single-blade grass
prototype as an acceptable starting point. Preserve the individual-blade approach
and usable slider controls as the basis for further refinement. This approval
covers the lab prototype; production rollout, final biome styling and tuning
remain unfinished. The prototype remains isolated from expedition ecology.

### Grass with Vastra comparison — October 30, 2026

**Grass / single blades** now uses an isolated `ExpeditionState` and the existing
`PlantVastra` transactions. This supersedes the earlier arbitrary patch-local
paths. Four illustrated grass cells and four visible tree receivers have explicit
cell IDs and root/crown anchors. All blades in a patch share its one reserve.
Every visible packet comes from `flora_transfers()`, with matching source/target
IDs, authoritative send/arrival ticks and an endpoint belonging to its actual
receiver. Tree-root returns land at the grass roots; plant emissions land at the
receiving tree. No transfer means no transfer particle. Live labels show reserves
and root stock; the HUD reports stored/in-transit energy and conservation error.

Fixture cells, display spacing and initial test reserves are authored lab data.
They demonstrate the existing generic plant cycle without an expedition,
generated-world catalogue, classified specialist ecology or Sol-feeding subjects.
They do not prove those other recipients have visual coverage. Production
admission, ecology and save rules are unchanged. Optical settings never choose
recipients or amounts. The simulation-speed slider advances the whole isolated
clock (including wind and transactions); it cannot independently speed up a
particle's arrival. The height slider controls the optical path arc, keeping the
source and receiver endpoints fixed. Night/visibility switches remain cosmetic.

Sliders expose visibility, path arc height, thickness, filament count and shared
simulation speed alongside the approved grass controls. Pause freezes both
transaction time and GPU particles. The shared Vastra lab noise helper is static
so this fixture can reuse it without creating unused UI. Focused tests prove
source/target identity, root/crown endpoint selection, real root-return packets,
visibility independence and conserved state through arrivals and repeated sends.

Live rollout, October 30, 2026: the approved blade mesh and four-biome styling now
ship in the normal game through `MeadowArt`. Production and lab share
`grass_blade_mesh.gd`; lab controls and seeded reserves remain isolated. This
supersedes the earlier note that production rollout was unfinished. Old grass
clumps are retired from live palettes/rendering. See
[the rollout record](reviewed-world-visuals.md#single-blade-grass-rollout--october-30-2026).

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


Official plant editing (October 30): open **Plants → Maker & library**, choose an
entry under **Official species presets**, then **Load official baseline**. The
45 presets load as independent copies with bounded visible sliders and a saved
individual seed. Randomize stays in that species; **Customize freely as new
design** opens the full range. Save uses the existing library workflow. Four
unassigned Receiver forms remain draft-only. See [procedural plants](procedural-plants.md)
for the identity and export contracts.
