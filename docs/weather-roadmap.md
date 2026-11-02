# Weather and wind roadmap

October 31 presentation follow-up: atmosphere now derives a smooth repeating
build/easing envelope from saved active time. Adjustable strength, variation and
cycle duration feed plants, grass, airborne leaves and rain lean together.
Plant sway follows world airflow despite instance rotation; small plants have
a more visible height response. Existing local gusts remain layered on top.
This bounded presentation change does not complete the coordinated weather,
geographic exposure or cloud-transport phases below. Controls are recorded in
[Inspector tuning](inspector-tuning.md).

## Nature-only loop integration — October 31, 2026

Weather/time can support authored revisit reasons in the nature loop, but visual
weather alone still grants no unimplemented ecological effect or encounter rule.
Record actual conditions and author each behavior dependency. Do not make a useful
discovery depend on waiting idly for an unexplained narrow window. Existing
weather ownership and saved active-time contracts remain. Foliage reserve posture
and saturation are separate consumers, blended with wind rather than replacing it.
Battle storms are a separate combat/Vastra lifecycle; turbulence exposure does not
turn ordinary rain into an overload source. The surrounding atmosphere continues
through tactical planning; only explicit pause stops the normal world clock.

October 29, 2026. Owner-approved direction: wind belongs within a shared weather
system. This roadmap records that direction; phases, component boundaries and
review samples below are engineering proposals. No runtime implementation is
claimed by this document.

## Ownership and scope

Extend the existing weather implementation rather than create a second weather
timeline. Weather owns coordinated cloud cover, precipitation, wind and their
transitions. A wind component owns prevailing airflow and gusts within those
conditions. Geography supplies local exposure modifiers. Lighting, foliage,
clouds, rain, fog and audio consume the resulting conditions.

Day/night remains alongside weather: saved exploration time establishes base
lighting, then weather modifies it. Mood remains a separate bounded presentation
overlay. Render chunks do not own weather or geography; streaming must not select
new conditions. Godot remains the terrain/climate-generation authority.

Represent weather with coordinated properties rather than mutually exclusive
labels alone. Named authored presets select compatible targets, allowing clear
and windy, overcast and calm, or rainy and gusty conditions. Keep the current
clear/cloudy/rain controls functional while their consumers migrate. Exact
strengths, probabilities and durations remain provisional Inspector tuning.

The first delivery covers environmental presentation. Movement penalties,
projectile deflection, combat conditions, encounter availability, ecological
effects and Vastra coupling require separate mechanics specifications and source
reconciliation. Ordinary weather does not create ecological overload. Temperature,
snow accumulation and fluid/atmospheric simulation are deferred. Approved audio
asset selection is recorded in [audio framework](audio-framework.md).
Preserve the authored storm-rescue design and its deferred campaign status.

## Current foundation and reference evidence

- [Atmosphere](atmosphere.md): `scripts/presentation/atmosphere_controller.gd`
  already derives clear/cloudy/rain transitions from expedition seed and saved
  active time. `AtmosphereSettings` owns the connected presentation tuning.
- `scripts/presentation/view_3d_settings.gd` supplies a separate cloud wind vector;
  the atmosphere controller also uses it for rain direction. These must migrate
  to shared wind consumption rather than remain competing airflow owners.
- [Forest study](forest-style.md): `shaders/painterly_foliage.gdshader` demonstrates
  height-weighted sway, but remains preview-only. Its live `TIME` animation and
  render-space phase are not yet the saved-time, streaming-safe wind contract.
- [Audio framework](audio-framework.md): `expedition_audio.gd` consumes rain
  strength through the existing mix/bed framework. Extend that consumer for wind;
  retain shared voice budgets and camera-listener ownership.
- Read-only source observation: local SolHunterSource branch
  `development/world-redesign-0.2`, recorded HEAD
  `d6f0902d77ed46a2f7d251c354792a4cc9210bc4`,
  `src/systems/world/weather.py`. It derives ordinary weather from seed and saved
  activity time, blends epochs and includes a wind weather label. This supports
  deterministic read-only conditions; it does not establish a wind-vector field,
  gust model or gameplay effects. These are working-copy observations, not a
  verified clean-source claim. Follow [mechanics reference](mechanics-reference.md)
  before introducing effects outside the approved presentation scope.

## Delivery sequence

| Phase | Result | Dependency | Status |
| --- | --- | --- | --- |
| WX0 | One explicit weather contract and Inspector ownership map | Existing atmosphere and clock | Planned |
| WX1 | Reconstructible prevailing wind, smooth direction changes and gusts | WX0 | Planned; first implementation slice |
| WX2 | Grass, shrubs and tree crowns respond coherently in the actual world | WX1 and scenery material adapter | Planned |
| WX3 | Clouds, rain and audio consume shared conditions | WX1; WX2 for connected visual review | Planned |
| WX4 | Geography produces smoothly varying exposure | Stable Godot geography inputs and WX1 | Planned after shared breeze works |
| WX5 | Connected multi-seed exploration and owner acceptance | WX2–WX4 | Planned |

### WX0 — Establish the shared contract

Audit the atmosphere update path, saved clock, settings application, scenery
batching and audio consumers. Define a read-only conditions snapshot and a local
wind query. Document world axes, units, update cadence, parameter ownership and
fallback behavior. Keep physical wind speed separate from each material's sway
distance; clouds can have a slower authored response to the same airflow.

Weather target selection, temporal interpolation and local sampling must have
single owners. Preserve existing lighting, fog horizon and weather override
behavior. Resolve how legacy cloud-wind controls map into the shared settings;
do not leave two active controls for the same fact. Update
[Inspector tuning](inspector-tuning.md) when controls are actually connected.

Exit: documented inputs/outputs, consumer migration map and a small initial
clear/breezy/rainy review fixture. No speculative controls for deferred mechanics.

### WX1 — Deterministic wind foundation

Derive prevailing direction, speed and gust envelopes from expedition seed and
saved exploration time. Use a dedicated deterministic key so wind never consumes
simulation RNG or rerolls unrelated weather, terrain or individuals. Use smooth
interpolation, including direction wraparound and deliberate calm/reversal
behavior. Gusts rise and subside rather than change randomly every frame.

Pause and battle hold the wind timeline with the exploration clock; the live
field menu continues it. Loading reconstructs the same state for unchanged
settings. Avoid shader `TIME` as an independent wind clock. Accumulated cloud
offsets must also reconstruct or be derived without jumps during speed changes.

Prefer derived presentation state over new save fields. Document that changing
presentation tuning can recalculate loaded-save appearance. Any subsequently
required persistent inputs need an explicit schema/version decision before use.

Expose enablement, prevailing speed/direction ranges, change duration, gust
strength/duration and deterministic preview overrides with tooltips and validated
ranges. Final parameter names and defaults follow the WX0 audit.

Exit: focused checks for seed/time repeatability, actual save/reload mid-transition,
pause/battle/menu semantics, direction wraparound, calm, invalid settings and zero
strength. Confirm no terrain/ecology/individual/save mutation by the sampler.

### WX2 — Foliage in streamed scenery

Adapt the forest-study wind into shared scenery materials, preserving imported
textures, alpha cutouts, biome colors and MultiMesh batching. Give grass a flexible
bend, shrubs moderate sway and crowns slower movement with restrained leaf
flutter. Material response owns flexibility; wind owns the forcing signal.

Retain root anchors and stable per-instance variation. A passing gust should be
coherent across neighboring plants without making every plant move identically.
Use stable absolute sampling coordinates or a bounded equivalent so origin
rebasing, mesh compaction and chunk rebuilds do not jump the animation. Account
for displacement in culling bounds. Visual sway must preserve terrain picking,
collision and usable routes. Avoid per-plant frame updates or unique materials.

Exit: actual player-height motion review across grass, shrub and tree cases,
including uneven ground, streaming, origin changes, calm and strong gusts. Record
bounded desktop frame-cost comparisons with matching scene/camera conditions.
The standalone preview alone cannot close this gate.

### WX3 — Coordinated atmosphere and sound

Replace independent cloud drift and rain tilt with consumers of shared wind.
Clouds respond more slowly; rain retains gravity and a bounded downwind slant.
Cloud cover, precipitation and fog blend from the same weather transition while
retaining their individual rendering settings. Keep day/night and mood composition
in their existing owners.

Connect wind intensity to the existing audio framework with authored cue slots,
bounded gain changes and smooth fades. Honor category mix, zoom policy and pause.
Missing streams remain silent; this phase does not authorize asset creation.
Inspect the current rain animation's battle behavior before changing it: the new
wind timeline freezes in battle, but that does not automatically require every
cosmetic particle to stop.

Exit: clear/breezy, overcast/calm and rain/gust samples visibly agree on direction;
transitions, pause and reload have no abrupt drift resets or audible restarts.
Existing day/night, fog horizon and audio routing checks remain valid or are
updated only where the contract deliberately changes.

### WX4 — Geographic exposure

Start with cheap, bounded queries of existing geographic parents, terrain and
authored cover: exposed ridges may strengthen airflow; valleys/groves may shelter
it. These are proposed exposure treatments, not an atmospheric fluid simulation.
Blend modifiers across world space and preserve parent constraints. Do not make
render distance, loaded vegetation or chunk boundaries change local weather.

Use a shared low-frequency field or bounded sampling grid where necessary to keep
GPU foliage and CPU rain/audio queries consistent. Keep regional conditions
independent of the camera; the camera/player only selects where effects are
sampled. Do not reroll terrain or introduce new generation/save inputs without
the corresponding version and persistence work.

Exit: a walk from shelter to open ground and across a regional boundary changes
wind smoothly. Revisiting, changing render distance and reloading preserve the
same sample for the same seed, location, time and settings.

### WX5 — Connected acceptance

Review one familiar seed and two different landscapes through normal exploration.
Cover a full weather blend, shelter/open transitions, save/load, pause, the live
menu, battle return and scenery streaming. Judge readable silhouettes, believable
plant flexibility, direction agreement and whether motion distracts from Sols or
interaction cues. Record owner visual acceptance separately from automated checks.

Use focused weather/atmosphere/scenery/audio checks and engine import/parse
validation for the affected contracts. Run broader connected regression when
shared contracts change and at final integration, reusing unchanged evidence under
the project standard. Record revision/dirty inputs, seeds, settings, renderer,
results and remaining limitations. No device acceptance is implied by desktop
results; deferred Thor work is not a gate for this feature.

## First action and reporting

Begin with WX0 and WX1 as one bounded foundation slice, then prove foliage in the
real streamed world before broad rollout. WX3 can reuse that reviewed wind
contract; local shelter follows after the shared breeze works. This sequence
supports W1/W3 exploration feel in the [world roadmap](world-exploration-roadmap.md)
without replacing its cross-feature priorities.

All phases remain planned. Add implementation evidence here only when connected
behavior has been verified; keep [atmosphere](atmosphere.md) as the current-runtime
guide and [forest style](forest-style.md) as the study/evidence owner. Workflow,
branching and review remain governed by [PROJECT_STANDARD.md](PROJECT_STANDARD.md).
