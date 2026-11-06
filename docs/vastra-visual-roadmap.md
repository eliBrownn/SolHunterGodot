# Vastra visual implementation roadmap

The map-first build uses the particle lab's visual vortex at seeded sites. The other runtime visual records below refer to inherited expedition systems. See the [map-first game](../README.md#play-the-map-first-build).

## Plant membership is a presentation prerequisite — October 29, 2026

All generated living plants must reference canonical Vastra cells. Explicit living metadata and endpoint flora_id links survive arbitrary model names; particle count, visibility, render chunk lifetime and clump density cannot own reserves. Missing links disconnect visible plants from real circulation and repair. The bounded pond's existing living water/bank placements are included.
See the [authoritative registration contract](vastra-integration.md#generated-vegetation-registration-and-system-hierarchy) for owners, limits and checks.

October 29, 2026. Owner requested this roadmap and implementation of step 1.
The [Bible's approved visual direction](reference/SolHunter_Worldbuilding_Bible.md#owner-approved-vastra-visual-direction--october-29-2026)
owns design; this document owns delivery and evidence. Develop the look first,
then build supporting code around it. Numerical defaults remain art tuning.

## Current world foundation — October 29, 2026

The owner-requested world-focused replacement is implemented. The
[resource evaluation](research/vastra-resource-evaluation.md#world-foundation-delivery)
owns the revised gates, reference findings and current evidence. The rejected
ribbon/surface prototype and its counts below remain historical engineering notes.
They do not establish acceptance of the replacement's art.

Geographic ownership uses 12-cell regions independent of 16-cell render chunks.
Complete vegetation records determine group membership; the explorer never supplies
positive density or a manifestation radius. Camera streaming selects a bounded
working set while retained region positions, density and phase stay fixed.
Vegetation shares broad, open refractive layers with narrow connections between groups.
Sols dissipate the presentation without consuming saved concentration.

Refraction and intermittent directional wisps use independent geometry/materials.
The carrier stays still; detail and brief packets travel through seeded paths.
Actual tile affinity controls complementary optics, concentration supplies local
inward potential, and existing sun/active-time owners drive highlights, restrained
night emission and motion. Soft geometry intersections and camera clipping replace
radial manifestation. Heatmaps separately expose raw concentration and nature/Sol
visual revelation. Combat's existing short cue keeps its own shader mode.

Owner-approved follow-up implementation: regional tributaries form an open tree
instead of nearest-neighbor cycles enclosing vegetation. Three upstream branches
vary in height and feed each grove; metric path length supplies continuous inward
phase. Two tapered open density layers replace ellipsoid shells. Short leading
edges and longer fading tails clarify motion while the carrier remains stationary.
The stronger visibility preset remains in use for shape review. The staged arch
and moving-Sol study are reproducible with `tools/review_vastra_exploration.gd`;
the arch/invitation are presentation fixtures, not registered discoveries.

Latest owner correction: make the field read as a web connecting the landscape.
The default now selects six groups within the same 24-node global budget.
Bounded alternate inter-grove links join facing outer branches and retain
visibility across gaps. Three unequal translucent veils and broad spatial bends
soften the constructed appearance; sparse bright strands emerge from the haze.
Local tributaries remain open; alternate routes exist between whole groves.
This supersedes the earlier strictly acyclic regional-backbone art constraint.

The revised implementation gates are delivered and focused checks pass. Final
owner art acceptance remains open. Discovery convergence at roots, rock openings
and larger phenomena remains a separate content study; this work does not invent
quest destinations, ecological propagation, storm exposure or campaign rules.

## Planned character interaction: mist flow — October 29, 2026

Status: the owner requested implementation to start after clarifying that character
interaction should feel like mist. Phase 1 now has an isolated CPU reference study
(see evidence below); normal exploration does not enable interaction. Later phases
remain proposals and visual acceptance remains with the owner. This section owns
this slice rather than a separate roadmap.

### Intended result and boundaries

Walking parts the luminous mist around a character, bends its fine filaments and
leaves a soft curling wake. Running produces a longer, stronger disturbance.
Motion persists after contact and gradually blends back into the surrounding
flow. There is no elastic snap, stretched rope or visibly solid collision wall.
Grass/tree sources remain geographically stable while the manifestation between
them can disperse. Height matters: walking under a canopy flow should not disturb
it as though it touched the character.

Start with player-driven presentation. Characters push the mist without movement
resistance, damage, harvesting, charging or changes to concentration/overload.
Existing affinity, ecological readings, source identities and generation remain
authoritative. Disturbance is transient and is not saved with expeditions. This
scope introduces no new game mechanic requiring source-rule reconciliation; any
later ecological or movement effect must follow `mechanics-reference.md`.

The simulated window is a processing limit, never the source of visible Vastra.
Do not restore the rejected player-centered manifestation radius. Preserve the
existing geography-owned undisturbed field outside the interaction window.

### Proposed ownership and simulation

- Keep `vastra_currents.gd` responsible for source selection, existing field
  readings and presentation coordination. Add one focused presentation flow
  component for transient interaction state rather than expanding ecological
  simulation or adding physics bodies to every strand/mote.
- First prototype a bounded coarse 3D velocity/displacement grid around the
  player. A real stateful solver advances at a fixed timestep: movement injects
  velocity, neighboring samples exchange motion, flow transports the disturbance,
  and damping dissipates it. A height-resolved field avoids ground/canopy coupling.
  This is an approximate mist-flow simulation, not a claim of full fluid dynamics.
- Use a swept body capsule between successive actual rendered character
  positions. Feed displacement and speed rather than keyboard input, so turning,
  analog motion and different movement sources produce consistent responses.
  Clamp extreme impulses; teleport, state replacement and reconstruction reset
  the sweep instead of creating a map-length wake.
- Derive the gentle base drift from existing presentation/weather owners where
  available, with explicit conversion of coordinates and units. Do not introduce
  a second weather simulation. Existing concentration-directed optical flow stays
  owned by its current consumer.
- Feed one shared disturbance representation to haze, visible filaments and
  motes. Distort/advection-sample the existing source-supported field so density
  remains attached to the landscape while local wisps move. Replace rigid carrier
  edges where they would clip the bending effect; merely shifting a fragment's
  brightness inside the original thin ribbon is insufficient.
- Preserve overlap when the simulation window moves, initialize newly entered
  cells at undisturbed flow and fade interaction strength at its boundary.
  Store/shift state using stable terrain coordinates; camera-origin rebasing must
  not act like character motion. Expand render bounds for maximum displacement.
- Keep the current implementation as a selectable comparison/fallback during
  development. Choose grid resolution, extent, solver rate and CPU/GPU placement
  from the prototype's measured cost. Begin with a small CPU reference solver;
  move the bounded field update to the GPU only if measured integration cost
  warrants the added complexity. Cap memory, upload size and per-frame work.

### Delivery sequence

| Phase | Concrete work | Exit evidence |
| --- | --- | --- |
| 1. Bounded visual study | Extend the existing Vastra exploration review fixture with repeatable idle, walk-through, run-through, stop, turn and return passes through ground and torso-height mist. Capture the current baseline. Prototype one interactive mist patch with diagnostic velocity/density views. | A moving comparison shows mist parting, curling and settling; interaction remains localized by height; the landscape stays readable. Record frame times and simulation dimensions. |
| 2. Stateful interaction | Implement fixed-step flow, swept capsule forcing, damping, bounded displacement and window-overlap retention. Integrate active-time pause and safe resets for teleport/load/terrain replacement. | Walking and running produce distinct wakes; motion continues after exit and decays; standing still injects no repeated impulse; no wake appears from camera motion. |
| 3. Unified Vastra rendering | Drive haze, filaments and motes from the same field. Adjust carrier geometry/sampling, ground clearance, displacement bounds and current crossfades. Retain stable grass/tree sources and existing affinity/daylight behavior. | No motes riding an old straight path through displaced mist, hard ribbon edges, ground penetration, boundary seams or culling pops during the fixture journey. |
| 4. Connected expedition | Enable player interaction in exploration behind the development switch. Reconcile existing Sol presentation clearing explicitly: retain dissipation and add body-driven flow only where it does not contradict that behavior. Admit additional moving characters through a capped interactor list with stable selection. | Normal exploration, camera orbit/zoom, region transitions, pause/resume and load work; static sources persist; character interactions neither mutate ecology nor block movement. Multi-character work follows the player proof. |
| 5. Tune and adopt | Review daylight/night and meadow/woodland moving captures, compare enabled/disabled performance, expose connected controls and document them in Inspector tuning. Adopt the reviewed default and retain a zero-cost disabled path. | Owner accepts the mist feel; measured CPU/GPU frame times and bounded memory fit the agreed desktop budget; relevant focused checks pass. No target-device acceptance is implied. |

Do not implement full strand ropes, rigid-body chains, strand self-collision,
worldwide fluid simulation, terrain-scale airflow routing or persistent wakes in
this slice. A full pressure solver or obstacle-aware flow is a later option only
if the study demonstrates a visible need. Initial ground constraints must prevent
the presentation from visibly moving through slopes without requiring that work.

### Controls to connect during implementation

Expose interaction enable, body influence radius/height, movement impulse gain,
wake persistence/damping, swirl strength, maximum displacement and recovery blend.
Keep quality controls separate: simulation extent/resolution, fixed update rate
and maximum interactors. Document units, valid ranges, live versus rebuild behavior
and whether pause/zero-flow freezes each control. Defaults remain provisional
until the visual study. No unused settings should be added merely for this plan.

### Proportionate validation and review

- Add focused checks for a stationary character, swept fast crossings, fixed-step
  behavior at different render rates, height separation, bounded state/finite
  values, disturbance decay and preserving overlap during window shifts.
- Check pause/resume and existing zero-flow behavior explicitly; reset on actual
  teleports/load while preserving motion across camera rebases. Verify the
  expedition/ecological snapshot is unchanged by a presentation-only journey.
- Reuse existing Vastra and 3D exploration fixtures; import/parse with the pinned
  engine, inspect moving renders, and log errors. A still image cannot establish
  the wake's feel. Broaden tests only for changed shared contracts or failures.
- Measure warmed enabled/disabled passes along the same route with the same seed,
  camera and settings. Report simulation/update/upload time, CPU/GPU frame-time
  distributions and memory; choose an explicit budget before normal rollout.
  Dense mist transparency may cost more than the solver, so profile both.
- Main risks: mist reading as smoke or ropes, transparent overdraw, incoherent
  motes, terrain clipping and sliding/reset wakes during streaming. Address them
  in the study before increasing visual density or interactor counts.

### Phase 1 reference study — October 29, 2026

Implemented a disposable `--mist` branch in the existing exploration review:

```powershell
godot --path . --rendering-driver d3d12 --script tools/review_vastra_exploration.gd -- --mist --animate
godot --headless --path . --script tests/vastra_mist_flow.gd
```

`tools/vastra_mist_study.gd` stages the same fourteen-second idle/walk/stop/run/
turn/return/settle route in seed 17 with an undisturbed patch and an interactive
patch. It also captures the existing field before replacing it in this fixture.
The 1,400 soft billboards include ground, torso and high control layers. A shared
field displaces their actual positions and clears local opacity, rather than
moving brightness inside an unchanged ribbon. A cached quarter-cell terrain grid
conservatively clamps displaced centers above nearby terrain. Arbitrary scenery
collisions, steep-slope acceptance and production ribbons remain separate gates.
This patch is explicitly authored study geometry; it creates no plants, transfer
events, discoveries or ecological concentration.

`scripts/presentation/vastra_mist_flow.gd` owns only transient velocity,
displacement and density. Its 17×7×17 half-cell grid advances at 30 Hz, transports
motion with bounded upwind exchange, advects displacement/density, injects a swept
body impulse and dissipates the wake without spring forces. Body positions are
terrain coordinates. Whole-cell window shifts preserve overlapping state, the
outer two grid cells soften the disturbance and samples outside the grid return
undisturbed presentation. Four steps per call cap catch-up work; teleports beyond
three cells reset it. Neither camera coordinates nor saved state enter this owner.

Focused flow validation passed 2,039 checks, including 15/30/60 Hz equivalence,
stationary bodies, swept fast crossings, stronger running wakes, height separation,
lingering motion/decay, retained overlap, pause, teleport, invalid input and finite
bounded state. Existing Vastra currents passed 295 checks. The new focused suite
is included in the shared validator; the full validator was not run for this slice.

Final single-instance Direct3D 12 capture completed with no engine/script errors and an
unchanged expedition snapshot. `artifacts/vastra-mist/` contains 420 frames per
mode at 30 samples/second, current-baseline and route snapshots, combined velocity/
density diagnostic maps and `performance.json`. Diagnostic red/blue encode signed
horizontal velocity; green encodes remaining density at grid layer two. The
paired animation is `comparison.webp`; `comparison-sheet.png` samples the route.
Normal exploration retains the existing renderer and has no interaction cost.

Godot 4.7.2 import/parse and the 156-script/UID ownership check passed. Initial
editor imports reported a local safe-save error. A byte-identical engine copy
under ignored `artifacts/vastra-portable/`, with self-contained `_sc_` mode and
its own `editor_data/app_userdata/SolHunter` directory, completed the final import
with empty stderr. Logs are `vastra-mist-import-portable{,-errors}.log` under
`artifacts/`. No machine-wide setting or source engine file was changed. Scoped
diff/whitespace checks passed; pre-existing unrelated whitespace findings were
left intact. No existing user changes were staged or committed.

Measured warm p95 work was 4.99 ms unforced versus 24.14 ms interactive on this
development desktop at 960×600. Interactive solver p95 was 14.00 ms and sampling/
instance-update p95 7.79 ms; these are separate distributions, not additive
percentiles. Timings exclude PNG readback/encoding and initialization. The pure
flow buffers occupy 113,288 bytes; the terrain cache 4,756 bytes, with 89,600 bytes
of transform/color payload updated per rendered frame. These exclude scene,
driver, billboard and capture allocations. The GPU query returned only zero and
is recorded as unavailable. Foliage shader timing is not locked between passes;
the existing headless current regression overlapped part of the final capture.
These practical study measurements establish neither isolated GPU cost nor an
accepted production frame budget.

Phase 1 now has a reviewable prototype, not owner art acceptance. The puff-like
study must still be judged in motion for the requested mist/curling feel. CPU cost
is too high for default rollout: optimize sampling/updates or evaluate the bounded
GPU approach before adoption. Later phases still own shared haze/filament/mote
integration, actual player/active-clock/weather bindings, load/rebuild resets,
multi-character policy, connected Inspector tuning and full biome/night review.
The standalone pause test is not evidence that all live pause/zero-flow paths
are integrated. No new mechanics or design-Bible edits were needed.

## Varied live trajectories and reserve readings — October 29, 2026

Owner follow-up requested intermediate heights, varied point-to-point directions
and distances, and wider irregular wiggles farther along the flow. The live
transfer renderer now samples each tree attachment independently between lower
trunk and crown, with seeded sideways bends and unequal arcs between the actual
recipients. Existing eligible distances, recipient selection and saved arrival
times are unchanged. Each packet retains its path across camera motion/rebuilds.
Interior points follow terrain clearance; exact source/destination centers remain
attached to the assets. This extends the existing nine-point curves rather than
introducing a physics system.

Finite stream carriers widen with traveled arc length, with softer opacity and
larger sideways wiggles. Smooth advected noise supplies irregular wandering;
distance increases amplitude, not a jitter rate. Bounds include the widened
geometry. `Current Path Variation` and `Current Flow Spread` are connected in the
[Inspector map](inspector-tuning.md#vastra-glow-and-local-light--october-29).
Orbs, emission, bloom and scenery lights remain disabled.

Object Details now reads the admitted plant/tree's current stored reserve through
a small read-only `ExpeditionState.flora_reading` projection. Its bar and numeric
value refresh through the existing inspection update as absorption, transfers,
arrivals and repair change energy. Other cells retain the ambient concentration
meter. This uses the existing conserved ledger and changes no simulation rule.

Focused checks cover deterministic curves, intermediate attachments, ground
clearance, preserved endpoints, sideways bends and live reserve rises/drops/arrival.
The plant suite passed 298 checks, the current suite 295, and inspection 22.
The Direct3D 12 study captured actual packet and circulation views plus the reserve
card under `artifacts/plant-vastra/`. One later rendered run encountered graphics
pipeline out-of-memory errors despite passing assertions; it is not a clean render
pass. The final shader reuses existing advected noise without an extra texture
sample; the final rendered retry passed all 298 plant checks and its captures were
inspected. That run retained only the existing local shader-cache directory error,
with no pipeline/LLVM or script errors. Its log is
`artifacts/vastra-varied-paths-render-final.log`. See the other
`artifacts/vastra-varied-paths-*.log` and `vastra-details-tests.log` for
this slice's evidence. Full-suite and device-performance acceptance are not claimed.

## Glow and local scenery lighting — October 29, 2026

Owner follow-up: remove the orb-like Vastra motes. Both the production preset and
resource fallback now use a zero particle budget, hiding the round traveling
particles while preserving the currents. Optional mote transport remains covered
by explicitly enabled test fixtures; production does not enable it.

Latest owner follow-up: turn the added effect off for now. Production defaults
now use zero emission and zero local lights; post-processing glow remains disabled.
Keep the implementation available for an explicit later request to restore it.

Owner follow-up requested glow and emitted light before mist interaction, with
nighttime verification. Implemented HDR emission tuning for strands/motes and
enabled bloom in the main 3D environment. Up to six spatially separated visible
motes drive a fixed eight-slot pool of shadowless affinity-colored OmniLights.
Their positions follow the existing transfer/mote paths; opacity, source fades
and Sol clearing modulate energy. Hidden/disabled currents and heatmaps hide the
lights. This changes presentation only and does not implement mist interaction.
The [Inspector map](inspector-tuning.md#vastra-glow-and-local-light--october-29)
records connected controls and the shadowless-light limitation.

Godot 4.7.2 focused `tests/vastra_currents.gd` passed 295 checks headlessly and
with Direct3D 12 rendering. The `--capture-glow` option avoids the main scene's
independent `--capture` journey and records a fixed midnight comparison, inspected
at `artifacts/vastra-glow/night-lit.png` and `night-emission-only.png`. The lit view
shows a local colored pool on nearby grass. The headless log is
`artifacts/vastra-glow-tests.log`; rendered log is `artifacts/vastra-glow-render.log`.
Rendered startup reported inability to create the local user shader-cache folder;
rendering and assertions completed, so this is not an error-free render-log claim.
The older exploration-review script also failed to resolve its existing superclass
in this session; the focused suite supplied the actual nighttime captures instead.
Scoped whitespace checks passed. Full-suite and target-device acceptance are not
claimed; final brightness remains owner art tuning.

## Historical prototype delivery sequence

The following table predates the world-focused replacement; radius-related entries
are superseded by the current section and resource evaluation.

| Step | Result | Acceptance | Status |
| --- | --- | --- | --- |
| 1. Connected web | Replace isolated rotated ribbons with seeded curved paths sharing stable junctions. Branch and merge, follow terrain, and retain world positions while walking. | One bounded connected component; shared endpoints; stable overlapping paths during travel; unchanged saved state; import, focused tests and rendered inspection. | Implemented and verified; owner visual review open |
| 2. Transparent surfaces | Develop evolving broad-to-fine surfaces, refraction, local-affinity primary/complementary secondary fringes and light glints. Direct optical travel toward higher existing concentration. | Landscape dominates; effect remains perceptible across a starter 5–8 tile radius; no single worm-like strand; rendered moving and disabled comparisons. | Implemented and focused checks passed; owner visual review open |
| 3. Layered movement | Broad drift, traveling ripples, eddies and gentle intermittent surges share the network rhythm. | Branches feel related; no detached creature motion or obvious synchronized flashing. | Basic inward flow and pulse delivered in step 2; refinement pending |
| 4. Proximity and lighting | Refine player-radius fade, daylight edge glints and faint nighttime affinity glow. Step 2 introduces the owner-requested starter fade from 5 to 8 tiles. | Walk across the boundary without visible popping; compare noon, twilight and midnight. | Starter radius in step 2; full lighting review pending |
| 5. Discovery convergence | Stage roots, a rock opening and a larger phenomenon in a bounded visual study. Then connect accepted patterns to real discovery owners. | Convergence invites investigation; affinity/intensity are readable without revealing safety. Mark fixtures separately from real destination integration. | Pending |
| 6. Tuning and integration | Consolidate exposed art controls, refine the playable study and integrate the accepted look into exploration. | Moving before/after review, frame-time comparison, focused integration checks and owner visual acceptance. | Pending |

Add useful Inspector controls with the step that actually connects them. Keep
simulation balance separate from presentation. Existing concentration, overload,
affinity and active-time owners supply readings; rendering creates no ecology,
rewards, danger or discovery-placement rules. Godot generation remains authoritative.

## Step 1 implementation

`scripts/presentation/vastra_currents.gd` owns a bounded local selection of seeded
world-space junctions. Cardinal links curve between shared endpoints; junction
warping breaks the rigid grid, and sampled heights follow ground relief. Local
selection grows one connected component, so clipping the junction budget cannot
leave disconnected fragments. Moving the local selection does not reroll paths.

One local `ArrayMesh` replaces independently rotated plane instances. Vertices
carry environmental color/opacity and overload readings. The shared current
shader has a network mode with continuous world-position phase and no per-link
end taper; existing short combat cues retain their separate presentation mode.
The material remains provisional until steps 2–4. Terrain following does not yet
provide collision-aware routing around tree trunks or rock meshes; assess that
in the visual study before choosing additional obstacle data.

`resources/vastra_settings.tres` exposes the existing enabled flag, junction
budget, radius, opacity and distortion through `VastraSettings`, plus connected
spacing and width controls. Geometry settings apply within 0.5 seconds, except
enable/budget changes which require restart. No saved generation settings change.

## Validation evidence

Godot 4.7.2 stable import/parse completed without engine/script errors. The focused
current suite passed 91 checks headless, followed by 94 checks in a Direct3D 12
Forward+ rendered run after adding branching, rejoining and ground-height checks.
The existing Vastra integration suite passed 38 checks headless. The ownership
checker passed for 151 mapped scripts/UIDs, and scoped whitespace checks passed.
The full game validator was not run for this presentation-only slice.

The inspected capture is `artifacts/vastra-optimization/rendered.png`; run
`tests/vastra_currents.gd` with `-- --capture` to reproduce it. It shows faint
connected ground-following paths across the refuge clearing rather than detached
short ribbons. The current appearance is still geometric: soft irregular surfaces,
distance fading and day/night art treatment remain the next deliveries, and
obstacle-aware routing remains unimplemented. The first rendered launch fell back
from unavailable Vulkan to Direct3D 12; the final explicit Direct3D 12 run passed
without engine/script errors. Logs are under `artifacts/vastra-web-*.log`.

Owner acceptance of the final Vastra appearance remains open. These results
verify geometry and existing Vastra integration, not final art or frame-time
acceptance.

## Step 2 implementation and owner refinements

The owner rejected repeated wave/loop patterns, floor-flat geometry and separate
ribbons. The web now occupies space above terrain, with irregular seeded junctions,
cubic links and tilted membranes. A finer physical branch leaves and rejoins each larger link. The owner then
rejected squiggly noise contours as well: the current material uses stretched
low-frequency variation aligned to the flow, with broad refractive folds and
internal finer streaks. Curves use smooth prevailing-wind tangents.

Three background samples provide paired chromatic refraction. The primary comes
from the actual local tile affinity palette at each sampled vertex; the secondary
is the opposite hue in sRGB, converted back to linear light. Neutral tiles remain
neutral. The existing sun provides direction, color and energy for light catches.
Full night/twilight treatment remains step 4.

### Living centers and directional flow

The player defines the viewing window, not the energy center. Existing visible
wild/deployed companion Sols and living vegetation provide world-space visual
anchors. Vegetation is read from existing streamed picking metadata: live tree
categories and recognizable plant asset names, excluding dead assets. This is a
bounded provisional presentation adapter, not a new biological classification
system. NPC humans and other future life providers are not yet connected.

Choose the strongest concentration-weighted living anchor as the visible pull
center, and connect the nearby web root to it. All main links share a graph-distance
potential toward that root, so branch phases feed a coherent overall inward flow.
A lightweight three-dimensional wind-plus-attraction field guides the optical
direction and coherent X/Y/Z carrier displacement. This is an airflow-style
kinematic presentation, not a fluid-pressure or full aerodynamic simulation. A gentle traveling pulse
modulates the field by 20% on a six-active-second cycle. Existing concentration
overrides influence source selection without receiving any rendering writes.

The web is stronger near living anchors and retains only 3% residual visibility
where life is absent. This is **visual concentration/density**, not a change to
Examine values, environmental combat bonuses or natural-recovery balance. Integrating
life-dependent concentration into those systems is a separate mechanics delivery.

### Current review preset

After the early render was effectively invisible, the owner explicitly requested
an extreme preset to dial back interactively. The connected resource now stores
opacity 0.8, refraction 0.02, aberration/glints 1.0, fine detail 0.9, surface width
2.4 cells and optical speed 0.5. This deliberately exaggerates the effect and is
not final subtle art acceptance. Junction spacing is 3.5 cells, typical hover
height 1.4 cells, living influence radius 3 cells. The viewing radius remains eight
tiles, fading smoothly from five to eight around the explorer. Inspector controls
are indexed in [Inspector tuning](inspector-tuning.md).

### Mechanics reconciliation

Read-only source inspection used the local SolHunterSource checkout whose
`development/world-redesign-0.2` ref resolves to
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`. Inspected
`src/systems/world/vastra.py`, `vastra_simulation.py`, the activity caller in
`src/core/game.py`, `tests/test_vastra_foundation.py`, `tests/test_vastra_regions.py`
and `docs/coordination/vastra-regional-equilibrium.md`. Existing source behavior
uses regional equilibrium and bounded explicit updates, with concentration and
overload independent; it does not establish automatic life-centered concentration.
The natural-recovery audit also distinguishes visible actors from ecological
population authority. Therefore the owner's current life-centered direction is
implemented as a cosmetic projection for this visual-first slice. No legacy
world generator, persistent concentration rule or source-repository file changed.
Git could not enter the source checkout in this tool environment; files and the
local ref were readable directly. The source working-tree cleanliness was not
verified, so the ref is checkout context rather than a claim of pristine content.

### Review and validation

Run `tools/review_vastra_surfaces.gd` with Direct3D 12 for a disposable water/fire
and concentration-peak fixture, actual living source anchors, time-separated
captures and disabled optical comparisons. `-- --animate` also records six seconds
of frames. It reads/writes no player expedition save. Captures are under
`artifacts/vastra-surfaces/`. `-- --slope` also records a generated slope view.
Geometry and opacity diagnostic captures make binding
failures distinguishable from overly weak material blending; neither diagnostic
mode is enabled in normal play.

### Airflow research and performance corrections

The owner observed poor performance, slope distortion and a flat/squiggly pattern.
Only junctions now sample terrain height: interiors remain free cubic curves in
3D, with no per-vertex floor fitting. One lower-detail physical branch replaces
two dense branches, and the mesh uses three banks and nine main longitudinal
samples. Bounded junction/path caches preserve immutable geometry; living strength
is evaluated once per sampled tile rather than per vertex. A precomputed 32-cubed
noise volume replaces per-fragment procedural hashes. The shader rejects regions
outside the viewing radius early, and carrier motion affects X/Y/Z.

Primary research:

- [Godot particle turbulence](https://docs.godotengine.org/en/stable/tutorials/3d/particles/turbulence.html): movement must exist before turbulence modifies it. Adopt a coherent wind/attraction field first, with restrained variation; do not use noise contours as motion.
- [Godot 3D attractors](https://docs.godotengine.org/en/latest/tutorials/3d/particles/attractors.html): shared vector fields and attractors provide a suitable pattern for directional flow. Current connected surfaces use a kinematic field; native particle attractors are a future option, not an implemented particle solver here.
- [Godot GPU optimization](https://docs.godotengine.org/en/latest/tutorials/performance/gpu_optimization.html): overlapping transparent coverage and shader work need explicit budgets. Bound the radius, reduce carrier geometry/overlap and avoid expensive per-pixel noise construction.
- [ImageTexture3D](https://docs.godotengine.org/en/latest/classes/class_imagetexture3d.html): the shared volume supplies cheap GPU interpolation for optical variation.
- [Screen-reading shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html): screen refraction can sample nearer scenery and does not capture other transparent materials. Depth checks reject nearer samples, and glints now use the actual spatial membrane normal. Transparent-overlap limitations remain a presentation refinement; this is not volumetric ray-traced refraction.

Final focused current tests passed 113 checks, including live shader bindings,
shared endpoints, bounded caches, source-driven convergence, faint empty areas,
local affinity colors, freeze/invalid-setting behavior and immutable state.
The existing Vastra integration suite passed another 38 checks. Final Godot
4.7.2 import/parse and the 151-script ownership check passed. Rendered Direct3D 12
checks completed without engine/script errors, including the shared shader's
unbatched combat mode and a generated 72.16-degree terrain sample at (32, 16). The inspected
current frame is `artifacts/vastra-surfaces/default-t0.png`; the six-second preview
is `artifacts/vastra-surfaces/airflow-preview.webp`.

A local paused 1280x800 comparison on the RTX 3070 measured average mesh rebuild
54.74 ms before versus 12.08 ms after (three rebuilds per mode); vertex count fell
from 7,035 to 1,803. This compares the local pre-optimization snapshot to the
current renderer, not identical geometry. Stationary frame windows measured
1.58 ms with the effect hidden and 1.84 ms visible. The shader-only baseline
window measured 1.91 ms and is not evidence of a GPU speedup; these short wall-time
windows are not isolated GPU timings. Full active-game performance and larger
viewport acceptance remain open. Details are in
`artifacts/vastra-surfaces/performance.json`; `-- --profile` uses optional local
pre-optimization snapshots under the same artifact folder.

The full validator and final art/device acceptance are not claimed. The current
exaggerated material remains a review prototype; night lighting, further surface
refinement and actual discovery integration retain their later roadmap gates.


### Direction and motion cleanup — October 29, 2026

Owner feedback: improved style still read as floating and convoluted, with unclear
travel direction, clipping and jumping frames. This follow-up changes presentation
only; the mechanics reconciliation above remains applicable.

- Reduce default hover height to 0.7 cells, narrow the strands, lower refraction,
  haze and glints, and use two broad veils with much fainter secondary strands.
  Traveling heads now have long fading tails with little stationary thread coverage.
- Parameterize each curved ribbon by sampled arc length. Local tributaries retain
  inward phases; inter-grove links use a wind-oriented metric phase rather than
  nearly identical grove scores that made an entire bridge brighten at once.
- Replace cell-selected sparkles with continuously sampled, advected detail.
  Pulse modulation follows the same optical transport, including speed-zero freeze.
- Use the active expedition clock once during combat. Adding the accumulated
  battle visual clock previously jumped phase on entry and could freeze it on exit.
- Apply cached ground clearance at every ribbon bank when building geometry.
  This supersedes the endpoint-only clearance approach above. Interiors still use
  open cubic paths above that minimum; no terrain queries occur during shader
  animation. The cache is bounded and invalidated on world rebuild.
- Record the six-second review animation at 60 samples/second, replacing the
  earlier eight-sample/second capture which itself appeared choppy.

Focused validation: `tests/vastra_currents.gd` passed 122 checks, including combat
entry/exit continuity, bridge phase distance and carrier vertex clearance. Godot
4.7.2 import completed cleanly with temporary editor data redirected under ignored
`artifacts/vastra-runtime/`. The initial default editor-data attempt could not write
to the machine's roaming data directory; no approval or machine setting change was
needed. Full-suite and device acceptance are not claimed. Vertex clearance and
soft depth intersections reduce terrain clipping; this is still transparent ribbon
geometry, so arbitrary scenery intersections and final art acceptance need visual
review rather than a claim of volumetric behavior.

The shared combat-feedback suite passed 22 checks; ownership validation passed
153 scripts/UIDs. The final Direct3D 12 surface review completed with zero reported
failures, including day/night, shared combat shader mode and a generated 72.16-degree
slope. Inspected `artifacts/vastra-foundation/default-t0.png` and
`generated-slope.png`. The 360-frame motion capture also completed; it preceded the
last bridge-phase correction, so final bridge motion is supported by the metric
phase regression and final rendered snapshots, not that earlier animation capture.


### Sparse peaks, asset destinations and streaming — October 29, 2026

Owner follow-up approved the cleanup and requested brighter traveling peaks,
longer tails, fewer and less random currents, and correction of foliage/Vastra
pop-in and performance. Each local connection must lead to a specific surrounding
nature asset. The later request about settings and a minus binding was withdrawn;
no new Options entry or binding belongs to this slice.

The default preset now uses 18 junctions and one extra nearest-group link, retaining
six geographic owners. Peaks are spaced 12 phase units apart, with a bright pale
head and a tail decaying over roughly five units. Local tributaries use fixed lane
spacing; each root terminates at the actual selected living asset's published
anchor rather than the grove's average center. Source positions are registered once
per instance by `SolidChunk` during its budgeted preparation. Vastra consumes only
published chunks, excluding hidden retained chunks; it does not create life or
change saved concentration. Specific destination placement remains cosmetic.

Owners persist through nearest-distance rank changes. A bounded previous density/
wisp pair crossfades over 0.45 seconds while the new mesh appears. Moving the
floating origin translates existing paths rather than rebuilding at every chunk
boundary. Optical sampling calls the generator's existing affinity and concentration
channels directly, avoiding unrelated route/obstacle/scenery compilation. The full
sample still consumes exactly the same generated concentration function.

Small foliage now has a 48-cell camera-relative endpoint with a 12-cell fade band.
Meadow follows the existing terrain horizon. New asynchronous scenery fades in over
0.6 seconds; terrain remains immediately covered. Replanning promotes an admitted
in-progress chunk to the queue front while it remains wanted, preserving its work.
The configured 4 ms preparation budget and publication limits remain unchanged.
This softens loading transitions; it does not promise infinite render distance.

Repeatable CPU probe: run `tools/review_vastra_surfaces.gd` headlessly with
`-- --streaming-profile`. It performs 300 deterministic updates including a
30-cell walk. The disposable prior-state run is recorded in
`artifacts/streaming-motion/before.json`, and the current run in `after.json`.
The initial measurement fell from p99 34.417 ms to 6.753 ms, with refreshes falling
from 12 to 3. Maximum work remained 54.545 ms (previously 63.641 ms), so rare cold
work/rebuild hitches remain open. These are CPU work measurements, not displayed
frame rate or device acceptance. Resident/queued chunk counts can differ because
preparation uses wall-time deadlines; this is a practical comparison, not a locked
microbenchmark. Live GPU windows are recorded separately by `-- --profile`.


Final validation for this follow-up: currents passed 123 checks, 3D view/streaming
passed 1,263 checks, and world generation passed 143 checks across 11 seeds.
Godot 4.7.2 import/parse and the 153-script/UID ownership check passed. The final
Direct3D 12 render completed without engine/script errors, including the actual
flower destination close-up (`artifacts/vastra-foundation/asset-destination-peak.png`),
day/night, shared combat shader and the 72.16-degree generated slope. An earlier
concurrent rendering attempt failed with pipeline allocation/out-of-memory errors;
the isolated retry and final isolated render completed cleanly. The short warmed
GPU windows are not evidence of a GPU speedup or broad hardware acceptance.
The scoped diff and whitespace checks passed; no unrelated work was staged or
committed. Full-suite validation and final in-game art/performance acceptance
remain outside this focused result.


### Height-tier strands, motes and deferred charge sources — October 29, 2026

Owner follow-up requested stronger strand shaking, a particle layer and a range of
sizes: common small grass-to-grass flows with almost no arc, increasingly rare and
longer flows higher up, and the largest arcs going treetop to treetop. Height should
allow about five times the ground-level reach. The owner also requested slower
travel and less visible carrier between streams. The object at the animated arrival
end is reserved as a future Vastra charge generator; its numerical mechanics remain
open. These supersede the previous uniform-width tributaries and globally connected
web requirement. Separate short local flows are valid.

The preset keeps at most 30 selected junctions and two canopy links. Small endpoints
come from actual rendered grass clumps; one representative clump per cell is
registered during its existing budgeted build. Low strands follow authoritative
terrain at 0.06-cell clearance with only 0.02 cells of additional lift. Tree crown
anchors use 96 percent of the actual authored tree height. Their rare large curves
rise above the endpoint line and join actual crowns. Nearby-asset selection gives
variable lengths; reach rises from three cells at ground level to approximately
15 cells at three cells above local terrain. Both endpoint span and sampled curved
length must fit the height-based budget. Terrain elevation alone grants no extra
reach. Curves retain exact shared endpoints rather than float-rounded lerp copies.

Each tier has its own ribbon width, pulse spacing, tail length, ripple gain and mote
scale, packed per vertex in a shared material batch. The new transverse ripple stays
inside existing carrier geometry, preserving the endpoints and clearance/culling
bounds. The optical speed falls from 0.75 to 0.42. Between passes, strand coverage
is reduced to a very small trace and broad density is gated by the traveling pulse.

`light_01.png` from the already approved CC0 Kenney pack supplies the separate mote
layer. One preallocated 128-instance billboard batch renders at most the configured
64 visible motes. Analytic positions follow the same optical phase and sampled
curves, with smaller motes on common ground flows. This adds no emitter nodes,
physics bodies, particle history or per-frame terrain sampling. Pause/speed-zero,
source/setting changes, Sol clearing, scene depth and visibility blending are shared
with the current field. The review fixture isolates particle cost and captures peak
and quiet intervals for all three tiers.

#### Mechanical setup and evidence

Every edge carries actual source/destination asset references, with destination
selected from the increasing animation phase. `charge_destinations()` returns
unique stable presentation asset references and the `future_generator_destination`
role. No charge amount, rate, capacity, arrival event, save schema or simulated
charge generation has been invented. A later simulation owner must admit persistent
nature identities and define charging independently of camera visibility, render
budget and particle count. Current presentation IDs are reconstructible asset/cell/
placement references, not a new authoritative persistent ecological identity.

Read-only mechanics reference inspection used the local SolHunterSource
`development/world-redesign-0.2` ref at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`: `src/systems/world/vastra.py`,
`vastra_simulation.py`, its activity caller in `src/core/game.py`,
`tests/test_vastra_foundation.py` and
`docs/coordination/vastra-regional-equilibrium.md`. Those establish independent
concentration/overload storage, read-only ambient queries and bounded activity-clock
updates; they do not establish this new asset-destination charge mechanism. The
owner direction therefore reserves the new role while leaving its actual mechanic
for reconciliation and implementation later. Source working-tree cleanliness was
not verified; this is local ref context, not a claim of pristine source content.
Godot terrain remains the generation authority. No source-repository file or Bible
content was changed.

The source index caches per-region asset selection and compares neighbors within
their geographic owner, preventing the expanded grass source set from becoming a
per-frame/full-world scan. Caches and the particle pool remain bounded. Inspector
controls are recorded in [Inspector tuning](inspector-tuning.md).


Final focused validation passed 288 current checks, including real grass endpoints,
rare actual tree crowns, physical curved-length budgets, the five-times reach cap,
future destination-role direction, bounded motes, frozen-clock behavior and
persistent-state immutability. The 3D view/streaming suite passed 1,263 checks;
shared combat feedback passed 22. Godot 4.7.2 import and the 153-script/UID ownership
check passed. Final isolated Direct3D 12 captures completed without engine/script
errors: three tier peak/quiet comparisons, actual arrival assets, day/night, Sol
clearing, shared combat shader mode and a generated 72.16-degree slope. The viewed
canopy span was 12.563 cells; the viewed small span was 0.872 cells. Captures are in
`artifacts/vastra-foundation/tier-{small,medium,large}-{peak,quiet}.png`.

The repeatable 300-update/30-cell CPU probe with the new hierarchy and motes is
recorded in `artifacts/vastra-particles/walk.json`: p95 4.904 ms, p99 6.691 ms,
maximum 68.931 ms, 3 current refreshes. This is CPU work, not displayed FPS; rare
cold-work hitches remain. The earlier short GPU windows are noisy (the disabled
window was slower than combined) and establish no GPU speedup or target-device
acceptance. The scoped diff and whitespace checks passed; no unrelated work was
staged or committed. Full-suite and final in-game art/device acceptance are not
claimed.


### Mechanical activation — October 29, 2026

The owner approved the basic look and supplied actual plant-at-100/tree-relay
mechanics, clarifying natural balance/repair rather than growth levels. Live play
now draws finite conserved simulation transfers. Grass-level transfers meet a tree
base; tree relays use the same crown arcs, ripple, peak/tail, palette/refraction and
mote treatment. A small share of the existing visual budget is reserved for actual
rare canopy packets so busy low-level traffic cannot hide every long arc. No art
budget changes the simulation's recipient or energy.

The earlier autonomous prototype remains explicitly available through `study_mode`
for art fixtures and the existing style acceptance tests. It does not run as a
source of real energy. The authoritative mechanical specification, saved policy,
source reconciliation and validation are in
[Vastra integration](vastra-integration.md#plant-energy-circulation-and-natural-repair--october-29-2026).

## Separate particle animation lab — October 29, 2026

Owner requested a test environment, with selectable states, to explore Vastra
using the Vessel study's GPU particle/wake approach before any game adoption.
[The particle lab](vastra-particle-lab.md) owns its controls, synthetic state
samples and focused visual evidence. Run `scenes/vastra_particle_lab.tscn`
directly. This is a separate art fixture; normal Vastra and Vessel presentation,
saved concentration, overload and gameplay remain unchanged.

Owner follow-up added actual plant/tree art, labeled reserves and five scripted
node-transfer interactions to the separate lab. Manual endpoints, finite travel,
arrival readings, tree overflow and root return can be reviewed with independent
particle/path controls. The clipboard parameter snapshot supports sharing an
exact test setup in chat. The [lab guide](vastra-particle-lab.md) owns the controls
and focused 295-check result; production mechanics and presentation are unchanged.

Owner clarification, October 29: the current in-game Vastra look is nearly the
intended appearance. The particle lab is a technical experiment to preserve that
look while evaluating player-driven physical presentation response. Glowing
orb/wake particles are not approved replacement art. The lab guide records this
reference and distinguishes its present analytic displacement from the still
unproven persistent particle interaction. Keep the existing mist-flow acceptance
scope and do not adopt a production rendering change on this basis alone.

The owner-requested particle appearance study now defaults to elongated optical
filaments rather than orb heads, based on the current material's seeded noise,
soft refractive folds and complementary fringe approach. Plant-connected paths,
zero default emission, lower density, isolated-view comparison and live filament
length/refraction controls are documented in the lab guide. This is a rendered
approximation for owner review, not production adoption or persistent physical
interaction acceptance.
