# Solid 3D exploration prototype

October 26, 2026. The owner selected this 3D direction with a clarification to preserve the 2D pixel-art look. This is not a replacement of world-generation or gameplay rules. See [the visual direction decision](decisions/2026-10-26-pixel-art-3d.md).

## Try and compare

Open `project.godot` with Godot 4.7.2 and press **F5**. The default entry is now `scenes/world_3d.tscn`. Use the existing movement, zoom, Examine, journal, pause, and save/load controls.

For the previous presentation, open `scenes/world.tscn` and press **F6**. Switching the project entry back to that scene restores the earlier sprite-ground view. Both scenes use the same generated world and expedition save format; start a separate expedition if you want to compare the same seed rather than loading an existing save.

## What is genuinely 3D

- Land has solid box geometry with its walkable top at Y=0.
- Water is recessed to Y=-0.22, exposing the sides of neighboring land as banks.
- Land and trails reuse the original nearest-filtered grass/paving atlas on 3D surface quads, preserving biome tint and pixel detail.
- Trees and rocks use upright pixel-art cutouts placed in 3D. Tree pieces retain their source pivots and vertical join instead of using smooth primitive canopies.
- The refuge building remains a simple solid mockup with pixel-textured walls/roof. Existing bench, crate, lantern, signs, and waystone props reuse their original sprite artwork and source anchors.
- Ground/foliage artwork preserves its baked palette rather than being lit twice. Directional lighting remains on geometric building/bank surfaces; occlusion and the character ground shadow retain spatial cues.
- The character remains an upright camera-facing sprite, anchored to the same ground coordinates, with a separate ground shadow.
- The camera remains at 35 degrees above the plane with zero sideways rotation, following the owner's correction.

These combine native Godot geometry with the supplied pixel-art pack. No new external art dependency or asset download is required. They are placeholders for judging depth, scale, and visibility, not final production assets or new world canon.

## Connection to the existing world

`world_solid.gd` extends the existing scene host. The original 2D simulation remains active for movement, generation, route/obstacle legality, objectives, saving, and HUD. Its baked terrain image is hidden in solid mode.

The simulation publishes chunk lifecycle signals. Each prepared chunk supplies its existing 256 tile records to `solid_chunk.gd`, which batches meshes with MultiMesh. Tree/rock placement and trail masks come from those records; rendering does not invent a competing generator. Removed simulation chunks immediately free the corresponding 3D chunk. Load/new seed rebuild decorative anchors. Geometry uses the same camera-relative origin as the character.

Publication timing includes subscribed 3D chunk construction. The logical near-player chunk budget remains 49. Geometry is batched by mesh type rather than adding a scene node for every tile or paving stone.

## Deliberate limits

- The cabin, bench, and other authored props are decorative mockups. Like the previous decorative props, they do not add blocking footprints; walking through the cabin is possible. Building placement and traversal require a later authored collision contract before production use.
- Trees, rocks, and water retain their existing logical tile blocking. Locomotion is still the tested grid/footprint traversal system, not a new CharacterBody3D/physics controller.
- The water recess demonstrates height, but there are no traversable hills, slopes, stairs, or vertical gameplay. Examine uses the existing logical ground-plane projection.
- Water and banks still need a consistent pixel-art treatment; characters use the placeholder directional sprite set.
- The hybrid 3D/pixel-art direction is approved, but final asset quality, manual journey acceptance, and portable-device performance targets remain open. The alternate view remains a reference.

## Verification

The shared `tools/validate.ps1` now checks:

1. Godot import, the original scene's expedition smoke tests, and generation/migration tests.
2. Solid geometry fixtures and lifecycle checks, including chunk eviction, negative coordinates, and new-seed cleanup.
3. The same expedition smoke journey against `world_3d.tscn`, exercising movement, streaming, objectives, save/load, migrations, picking, and camera coverage.

Headless Godot's dummy renderer does not retain GPU MultiMesh transforms. The two height/readback checks therefore run separately with a real renderer:

```powershell
godot --path . --script tests/solid_geometry.gd
```

For a rendered, real-time expedition profile:

```powershell
godot --path . --resolution 1280x800 --script tests/exploration_profile.gd -- --scene=res://scenes/world_3d.tscn
```

That command uses isolated temporary saves and writes ignored JSON/screenshots to `artifacts/solid3d/profile/`. The normal `--capture` option writes refuge, shore, landmark, and pause screenshots to `artifacts/solid3d/`, keeping the original view's captures separate.

Initial verification: both scenes completed 2,389 smoke checks each; generation completed 209 checks; headless geometry completed 15 checks (two GPU readbacks explicitly skipped). A rendered geometry run completed all 17 checks with zero failures. These are evidence for the prototype's contracts, not final player acceptance.

Before the pixel-art follow-up, the rendered solid-scene expedition completed with zero failures at 1280×800,
60 FPS cap, Godot 4.7.2/OpenGL compatibility, RTX 3070. Observed outbound/return
p99 frame intervals were 16.69/16.69 ms; live chunks peaked at 49. Scene construction
took 165.99 ms, new seed 99.88 ms, and load 91.45 ms. Warmup included a 195.33 ms
outlier. These are one local run with frame pacing included, not cold-start or
portable-device acceptance. The detailed report includes environment and camera
settings; do not compare it directly with earlier lower-resolution ground views
as if rendering workload were identical. These figures describe the earlier
primitive/flat-color renderer, not a fresh measurement of the pixel-art update.
