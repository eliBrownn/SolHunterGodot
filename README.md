# SolHunter

A fresh Godot exploration foundation. The design authority is the
[worldbuilding bible](docs/reference/SolHunter_Worldbuilding_Bible.md), which keeps
confirmed canon, provisional design, and unresolved questions distinct.

Populate species, evolutionary lineages, and the roster in the
[Sol Bible](docs/reference/sol_bible.md), the species authoring companion to that design authority.

The [species data pilot](docs/sol-species-data.md) connects Crown-Ear, Reedback,
and Bellroot through shared resources. Open `scenes/sol_species_pilot.tscn` with F6
to review their [articulated creature blockouts](docs/sol-creature-models.md).
To make another model, follow [the model-authoring guide](docs/creating-sol-models.md)
and open `scenes/sol_model_workshop.tscn` with F6 for independent movement review.
The [flight/swimming pilot](docs/sol-flight-and-swimming.md) adds live wild
traversal; `scenes/sol_traversal_pilot.tscn` starts beside the generated pond bank.

Repository organization and Git workflow follow [the project standard](docs/PROJECT_STANDARD.md).
See the [repository management roadmap](ROADMAP.md) for milestones and completion gates.

Continue creature design with the [design handoff](docs/sol-creature-design-handoff.md).
Gameplay uses creature bodies throughout, including provisional models for legacy species.

Open `project.godot` in Godot 4.7.2 and press **F6** with `scenes/world_3d.tscn` open,
or **F5** to run the project. Command line: `godot --path .`.

Walk east along the old stone trail, reach the waystone, and
return to the refuge. Names and artwork for these places are temporary.

| Control | Action |
| --- | --- |
| WASD / arrows | Walk relative to the camera heading, including diagonals |
| Hold Shift | Run while moving |
| Mouse wheel | Dolly the perspective camera closer/farther |
| Middle-mouse drag / Home | Rotate and tilt the camera / restore starting angles and zoom |
| Right-click | Choose interactions for the pointed target: Engage / Observe on Sols; Observe on scenery; party / guide on your trainer |
| E | Toggle tile examination under the pointer |
| C / 1–3 | Open Sols; choose a starter with 1–3, then manage party, storage and moves |
| H | Recover party health at the refuge |
| Battle controls | Click blue tiles to deploy/move; click a move card then its target; use the End turn / Seal / Retreat buttons. Escape cancels targeting or opens the battle menu; retreat requires confirmation |
| J | Open the Field Guide; Journal holds the session log |
| F5 / F9 | Save / load expedition |
| R / Escape | Open/close the live field menu / pause or resume exploration. Save/load and new expedition are under Save |
| F3 | Frame-time percentiles and streaming diagnostics |

The [field menu](docs/field-menu.md) groups Field Guide, Sols, Bag, Trainer,
Journal, Save and Options in one window. Drag its header to move it or its bottom
right corner to resize it. Options adjusts menu scale/opacity and the live camera
and view. Layout preferences stay on this device, separate from expedition saves.

The normal Godot user-data directory contains `expedition.json`. Saves store the
seed, generation version, settled player cell, and journey progress. The previous
save is copied to `.bak`; malformed or incompatible saves leave the live world
intact. Backups are preserved but are not automatically restored. Starting a new
expedition does not overwrite the saved expedition until you save again. New
expeditions use generation version 6 with gentle Rolling terrain, level ponds,
blended place foundations and a reserved blocking cabin footprint. Save format 3
retains relief/climate parameters, territory observations, activity time, sparse
world changes and stable Sol records. Older development saves require a fresh
expedition; incompatible loads leave the current world intact.

Adjust **Expedition Tuning -> Terrain Settings** on the world root for new
expeditions. Loaded saves keep their settings. See [natural terrain](docs/natural-terrain.md)
for implementation, validation and remaining polish work.

## Climate parameters

Open `resources/climate_settings.tres` in Godot's Inspector to set the Perlin
moisture frequency and the dry and wet thresholds for **new** expeditions. Lower
frequencies produce broader moisture regions. Raising the dry threshold expands
dry heath; lowering the wet threshold expands marsh. Both thresholds range from
0 to 1, and the dry threshold must stay below the wet threshold. Invalid settings
fall back to defaults and produce a warning in Godot's output.

Each save records its climate parameters, so later changes to the resource do
not alter that saved world's generation. The Examine view shows local wetness.
Moisture influences habitat and ground tint; water basins and Vastra use separate
generation inputs.

## Individual stats and class buffs

Combat now uses dedicated health cards and an action tray, exact damage/path/area
previews, a battle log, and brief hit/heal reactions. Mouse controls deployment,
movement and targeting. Escape cancels targeting or opens the battle menu; retreat
requires mouse confirmation. See [combat polish](docs/combat-polish.md) and the
[UI/UX roadmap](docs/ui-ux-roadmap.md).

Sols now retain six independent lifelong 90–110% IV rolls, automatic natural
level growth, and an individually rolled class passive. Physical and special
attacks use separate stats. Battle contributions earn player-assigned training,
with stage-based caps and a maximum 10% bonus in three fully invested stats.

Open **Sols** or press **C** to inspect exact IVs, allocate training, or reset it
using a limited retraining item. Bag shows remaining items. Saves preserve
potential, class potency, allocations and supply; older saves migrate once.
See [individual stats](docs/sol-stats.md) and [class buffs](docs/class-buffs.md)
for rules, tuning, migration and current content boundaries.

## 3D world

The default `scenes/world_3d.tscn` renders streamed 3D tile geometry, an animated
skinned rogue, imported nature meshes, geometric refuge props, and affinity
spheres. Existing grass/pavement textures remain on tile surfaces. The
perspective camera supports live orbit, tilt, dolly and reset. A north indicator
keeps world directions readable as WASD follows the view. The simulation
still owns terrain, collision and saves; one world cell is one 3D unit.

`scenes/world.tscn` retains the flat terrain comparison view. Both scenes share
the player model and input routing. HUD controls stay in screen space.

`resources/view_3d_settings.tres` controls perspective, orbit distance, terrain
render distance, scenery detail distance, shadows, and the supplied procedural
sky/clouds. Terrain streaming follows the 3D view and viewport aspect ratio;
prefetch and a per-frame chunk budget bound the work. Distant horizon fog hides
the far clip at a steady distance. Temporary ground covers queued chunks during
camera turns while detailed terrain/scenery loads, avoiding a foreground fog flash. The
solid view avoids constructing duplicate hidden sprite scenery.

## Assets

The supplied **Cainos / Pixel Art Top Down - Basic v1.2.3** pack provides retained
terrain textures and reference artwork. `assets/basic-pack/sprites.json`
contains 337 named sprite slices converted from the Unity package, preserving
rectangles, pivots, pixel scale, borders, and IDs. Original texture importer
metadata is retained in `assets/basic-pack/metadata`. The pack's Unity code and
project settings are not used. See [asset provenance](assets/basic-pack/PROVENANCE.md).

The player uses the supplied [rogue and animation rigs](assets/characters/rogue/PROVENANCE.md).
The [Quaternius nature subset](assets/nature/PROVENANCE.md) supplies 14 imported
models and textures for biome scenery. Edit `resources/nature_settings.tres` for
visual palettes, sizes and decoration density. See the [current visual decision](docs/decisions/2026-10-27-full-3d-and-controls.md).
The [supplied cloud presets](assets/sky/PROVENANCE.md) feed a daylight/night sky
with a matching sun, moon, stars, dawn/dusk gradients and moving clouds. A full
day takes 20 minutes of active exploration by default. Clear, cloudy and rainy
weather blend on a deterministic five-minute schedule; pause and reload preserve
the saved-clock appearance. Rain adds nearby streaks, dimmer sun and closer fog.
Terrain, water and props receive the changing lighting and shadows.

Edit `resources/atmosphere_settings.tres` for cycle length, starting time, lighting
and weather. Disable Cycle Enabled and choose a phase to preview a fixed time;
force clear/cloudy/rain for authoring. See [atmosphere controls and behavior](docs/atmosphere.md).

To regenerate the metadata from the original ZIP, install Pillow and PyYAML, then:

```powershell
python tools/import_basic_pack.py 'path/to/Pixel Art Top Down - Basic v1.2.3.zip'
```

## Validation

The `Godot validation` GitHub Actions workflow runs the same entry point
on pull requests to `main` and pushes to `main` or `codex/` branches. It pins the
engine archive checksum and uploads no source assets or build artifacts.

Run the existing import and test suites together (requires Godot 4.7.2 stable):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate.ps1 -Godot 'C:\path\to\Godot_console.exe'
```

This invocation permits the local script in that process without changing the
machine's execution policy. Omit `-Godot` when `godot` is on PATH. The script returns a nonzero exit code
if the engine version, import, or either suite fails. These checks do not replace
manual playtesting or performance acceptance. Individual commands follow:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/world_generation.gd
godot --path . -- --capture
```

The last command writes camp, shore, landmark, and pause PNGs to ignored
`artifacts/`. The smoke test uses its own save filename and removes its test saves.
It validates multiple seeds, large footprints, negative chunk coordinates,
determinism, actual outbound/return movement, bounded streaming, reconstruction,
save replacement and rejection, input routing, and projection round trips. The
world-generation suite additionally checks dry route reservations, water collision,
network junctions, 3×3 routes, and save migration over ten seeds.

See [implementation and validation notes](docs/development.md) for measured
results and current limits. The [first playable battle](docs/first-playable-battle.md)
adds a saved starter, deployment, tactical actions, and safe outcomes.
[Enemy AI, Seals and progression](docs/ai-seals-progression.md) add visible capture
odds, captured companion selection/storage with C, and victory XP/move unlocks.
Quests, caves, economy and production wildlife simulation remain future work.

The game automatically opens maximized to the available screen and adapts its
view/UI to the current aspect ratio. It remains resizable; there is no fixed
physical startup-window size. Restart the game after display-setting updates.
