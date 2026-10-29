# Lighting, day/night and basic weather

Implemented October 27, 2026 under the owner's lighting/skybox and subsequent
day/night/weather direction. This is a presentation feature over the existing
saved exploration clock, not a new combat, ecology or storm rule system.

## Appearance and controls

The scene has moving sunlight and shadows, opposite moonlight at night, readable
ambient fill, blue daytime sky, warm dawn/dusk horizons, stars, a sun/moon disc,
and procedural clouds using the owner's supplied noise presets. Terrain, water,
banks and walls receive the same lighting as imported scenery. A reversed
terrain triangle winding was corrected so the lit ground normals face upward.
Retained textures and generated terrain/collision data are unchanged.

Clear, cloudy and rain states adjust cloud coverage and direct sunlight. Rain
adds nearby depth-tested streaks and earlier horizon fog; particles do not cast
shadows or alter world state. The top-center display shows current time and
weather, including an arrow while transitioning between weather states.

Select the world root's **3D View → Atmosphere Settings**, or open
`resources/atmosphere_settings.tres`. Save edits and restart, or call
`apply_atmosphere_settings()` on the running root. Disable Cycle Enabled and
set Starting Phase to preview a fixed time. Weather can be auto, clear, cloudy,
or rain. View Settings still supplies daytime sky endpoints, cloud textures,
base density/wind and render/shadow distances. All current controls and ranges
are listed in [Inspector tuning](inspector-tuning.md).

## Time, weather and persistence

Defaults: 1,200 active exploration seconds per full day, starting at phase 0.38
(about 09:07). Phase 0 is midnight, 0.25 sunrise, 0.5 noon and 0.75 sunset.
Automatic weather selects a stable state every 300 active seconds using the
expedition seed and interval, with relative weights 0.5/0.3/0.2 and a 20-second
blend. These are editable presentation defaults, not finalized world canon.

The input clock is `activity_tick × 0.75 + remainder_seconds`, both already
saved. No new save fields, migrations, wall-clock catch-up or independent clock
authority are added. Pause and battles freeze the timeline with exploration;
reload reconstructs the same phase and weather transition without rerolling.
Particle positions are cosmetic and are recreated rather than serialized.
Rain animation freezes in the pause menu and may continue during combat.

Changing cycle length, phase offset, weather weights or intervals deliberately
recalculates appearance from existing saved time. It does not rewrite saves.
Fixed-phase mode freezes the lighting preview; automatic weather remains driven
by active time unless a weather state is also forced. Invalid settings fall
back before reaching the renderer. Zero rain particles suppresses streaks while
preserving rainy sky/fog/light. Zero base cloud density clears clouds.

No weather damage, status effects, wet movement cost, lightning, storm eligibility,
temperature, crop growth, population change or new encounter timing is added.
Those need their own mechanics reconciliation and implementation.

## Validation

`tests/atmosphere.gd` verifies connected sun/moon and ambient lighting, warm
sunrise, weather states and particle budget, no domain mutation, smooth sub-tick
time, pause, actual save/reload during a transition, deterministic interval
selection, lit terrain and invalid policy fallback. It is in the shared validator.
The rendered variant additionally checks that daylight ground is substantially
brighter than night ground while the night remains visible.

```powershell
godot --path . --script tests/atmosphere.gd -- --capture-atmosphere
```

Day, sunset, night, rain and sky-only captures under ignored
`artifacts/atmosphere/` were visually inspected on OpenGL/RTX 3070. No export or
portable-device performance acceptance is claimed. Source-asset redistribution
status remains in [sky provenance](../assets/sky/PROVENANCE.md).
