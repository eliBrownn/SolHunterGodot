# T0 natural-terrain preview

October 27, 2026. Implementation of the first checkpoint in the
[terrain roadmap](terrain-roadmap.md). This is a shape study, separate from F5's
production expedition. Subsequent owner direction to continue adopted Rolling
for [production integration](natural-terrain.md). This page records the T0 study.

## Inspect the terrain

Open `scenes/terrain_preview.tscn` in Godot 4.7.2 and press F6. The default is
Rolling. Buttons or keys 1–3 select Very gentle, Rolling, and Upper relief using
the same seed, sampling scales, tree positions, scale model, and comparison view.
Tab toggles overview; middle drag orbits; wheel zooms; Home restores the view.
WASD moves the scale model through the bounded preview area to inspect slopes.
This inspection movement has no gameplay collision or encounter behavior.

The player model is 1.7 cells tall; trees are 3.5 cells. Height maps use a shared
-6 to +6 cell legend. Slope maps show the steeper of both triangles in each cell
with a shared 0–25 degree legend. Red means above 25 degrees, not an implemented
gameplay traversal restriction. Comparing presets retains the current camera
and model position; Home restores a repeatable starting comparison.

The ground is deliberately a simple shaded surface to make landforms readable.
Terrain textures, road grading, pond beds/water, authored foundations, gameplay
movement, picking and combat integration remain later milestones. Existing road
locations are tinted onto raw terrain, not presented as finished safe routes.
The study does not load or save an expedition or alter the production generator.

## Connected Inspector settings

Select the TerrainStudy root. Study Seed applies when restarting the scene.
Presets references three Resources under `resources/`: `terrain_very_gentle.tres`,
`terrain_rolling.tres`, and `terrain_upper_relief.tres`. Each exposes broad/detail
sampling scales and amplitudes, small variation, and broad-channel warp strength,
with cell units and validation. Resource edits apply at restart, or on reselecting
a preset when testing through a live script/debugger. Invalid settings fall back
to the default Rolling settings. The same Rolling resource now supplies NEW F5
expeditions; existing loaded worlds retain their saved parameters.

## Shared surface contract

`TerrainHeightfield` captures a private copy of validated parameters and uses
independent seeded noise channels. The origin vertex is anchored at height zero.
Integer XZ coordinates are cell corners; actor centers use a half-cell offset.
Each cell uses the NW–SE diagonal. Height interpolation and triangle normals
match that triangulation. Smoothed shading normals use neighboring absolute
samples, so independent chunks share identical border normals.

The study uses a fixed one-cell lattice and 16x16-cell mesh chunks, with a 17x17
vertex grid per chunk. Render coordinates are local to each chunk; height queries
use absolute coordinates. The study contract snapshot includes its version, seed,
and generation parameters and can be reconstructed after a JSON round trip.
It is not yet an expedition-save field or production generation-version change.

## Reproduce review artifacts

Use the installed console executable if `godot` is not on PATH:

```powershell
godot --path . --rendering-method gl_compatibility --windowed --resolution 1280x800 --script tools/capture_terrain_study.gd
```

This writes ignored `artifacts/terrain_study/` output: three walking/overview
pairs, individual height/slope maps, `comparison.png`, and `report.json`.
The report records settings, measured relief, triangle slopes, and raw trail
centerline grades for seed 2601026. It also captures current flat refuge,
waystone, shore, negative chunk boundary and camera-extreme references.

The study region is X=-64..127, Z=-64..63. Local relief is measured over the
64x64-cell window X=-16..47, Z=-32..31; these measurements describe that seed and
window, not bounds guaranteed for every seed. The raw field has no final
foundation/pond shaping or enforced global height envelope yet.

For a fresh rendered flat-game timing baseline, use the existing journey harness:

```powershell
godot --path . --rendering-method gl_compatibility --windowed --resolution 1280x800 --script tests/exploration_profile.gd -- --scene=res://scenes/world_3d.tscn
```

It writes `artifacts/solid3d/profile/` with real-time travel, rebuild/load timings
and limitations. Compare the same renderer, resolution and device later; the
standalone study is not a production streaming/performance benchmark.

## Validation

Observed October 27, 2026 on Godot 4.7.2 / OpenGL compatibility / RTX 3070:

| Preset | Local 64-cell relief | Triangle slope p95 / maximum | Raw trail maximum centerline grade |
| --- | --- | --- | --- |
| Very gentle | 2.06 cells | 3.30 / 4.33 degrees | 2.90 degrees |
| Rolling | 3.68 cells | 5.96 / 7.89 degrees | 5.18 degrees |
| Upper relief | 5.54 cells | 8.86 / 11.61 degrees | 7.73 degrees |

These are sampled-region results, before route grading or foundation/water
modifiers. Rolling matches the proposed 2–4-cell local relief experiment. The
raw trail measurement is not a cross-slope, large-footprint or connectivity proof.

Shared `tools/validate.ps1` passed import and every suite on the working tree,
including 298 terrain checks and both existing expedition journeys. Expected
headless GPU readback skips remain identified by their existing suites. Walking
and overview renders were inspected: no visible chunk seam or obvious floating
scale references in the captured views; maps and labels remain readable.
Inspection does not establish absence of defects at every coordinate or angle.

The flat-world rendered journey completed with zero failures. Its actual recorded
viewport was 2560x1369 under the current maximized project setup, despite the
requested CLI resolution. At the 60 FPS cap, outbound/return p99 frame intervals
were 16.70/16.74 ms and maxima 39.29/25.80 ms. Initial scene construction was
1165.57 ms; new expedition/load were 201.41/221.02 ms; live chunks peaked at 59.
This single run includes pacing time and is a compatibility-renderer reference,
not an uncapped benchmark or acceptance of the default Forward Plus renderer.
The recorded viewport/device/settings must be matched for a later comparison.
`artifacts/terrain_study/flat_profile.json` preserves that baseline report.

The three terrain walking/overview pairs are 1280x800; their frame times must not
be compared with the differently sized production journey as a speedup claim.
Validation and captures used isolated Godot application-data folders under ignored
`artifacts/terrain_study_runtime/`, leaving normal user preferences and saves alone.

`tests/terrain_heightfield.gd` is included in `tools/validate.ps1`. It checks
triangle interpolation against an adversarial saddle, JSON reconstruction,
negative and supported extreme coordinates, resource snapshot isolation,
invalid contract/parameter rejection, independently built mesh borders,
unchanged production samples, and live preview preset/camera controls.

Rendered captures must also be inspected for grounding, clipping, shading and
legibility. Automated checks establish the study contract; they do not establish
owner preference, manual movement acceptance, target hardware budgets or exports.
