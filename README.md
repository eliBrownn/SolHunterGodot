# SolHunter

A fresh Godot exploration foundation. The design authority is the
[worldbuilding bible](docs/reference/SolHunter_Worldbuilding_Bible.md), which keeps
confirmed canon, provisional design, and unresolved questions distinct.

Repository organization and Git workflow follow [the project standard](docs/PROJECT_STANDARD.md).
See the [repository management roadmap](ROADMAP.md) for milestones and completion gates.

Open `project.godot` in Godot 4.7.2 and press **F6** with `scenes/world.tscn` open,
or **F5** to run the project. Command line: `godot --path .`.

Walk east along the old stone trail, reach the waystone, and
return to the refuge. Names and artwork for these places are temporary.

| Control | Action |
| --- | --- |
| WASD / arrows | Walk, including diagonals |
| Mouse wheel | Zoom the orthographic 3D camera |
| E | Toggle tile examination under the pointer |
| F | Observe a nearby Sol |
| R | Approach a nearby Sol; Escape withdraws from the encounter panel |
| C / 1–3 | Open companion selection / explicitly choose a starter |
| H | Recover companion health at the refuge |
| Battle controls | Click blue tiles or use arrows; Enter deploys/ends turn, Space attacks, Escape retreats |
| J | Field Notes: saved sightings and session log |
| F5 / F9 | Save / load expedition |
| Escape | Pause, save/load, or start another seed |
| F3 | Frame-time percentiles and streaming diagnostics |

The normal Godot user-data directory contains `expedition.json`. Saves store the
seed, generation version, settled player cell, and journey progress. The previous
save is copied to `.bak`; malformed or incompatible saves leave the live world
intact. Backups are preserved but are not automatically restored. Starting a new
expedition does not overwrite the saved expedition until you save again. New
expeditions use generation version 5 with a reserved, blocking cabin footprint.
Version 1–4 saves migrate when loaded: seed, journey progress, and recorded climate
settings are preserved. The player moves to nearby legal ground if terrain or the
new cabin blocks their former position. Geography changes. Loading
does not alter the original file; the next save backs it up before replacement.

Save format 2 also retains territory observations, the activity clock, sparse
environment changes, and stable Sol records independently of streamed chunks.
Older format-1 saves receive an empty persistent foundation without invented
creature history. See [D1 implementation](docs/d1-persistent-foundation.md).

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

## 2D world on a 3D plane

`scripts/world_plane.gd` owns the 3D scene: an XZ `PlaneMesh`, a nearest-filtered
`SubViewportTexture`, and an orthographic `Camera3D`. The viewport draws the 2D
terrain, props, and player. The HUD is in the main viewport, outside the plane.
Pointer rays intersect the plane and map back to the same 2D cell coordinates
used for movement and inspection. One 32-pixel cell corresponds to one plane unit.

The plane follows the player by updating its viewport camera. It is a bounded
rendering surface over streamed procedural terrain, rather than a mesh for the
entire generated world. All artwork is currently projected flat onto the surface;
upright billboard actors, physical height, 3D lighting, and camera rotation are
future presentation work.

## Assets

The supplied **Cainos / Pixel Art Top Down - Basic v1.2.3** pack provides grass,
pavement, trees, rocks, props, and the character. `assets/basic-pack/sprites.json`
contains 337 named sprite slices converted from the Unity package, preserving
rectangles, pivots, pixel scale, borders, and IDs. Original texture importer
metadata is retained in `assets/basic-pack/metadata`. The pack's Unity code and
project settings are not used. See [asset provenance](assets/basic-pack/PROVENANCE.md).

To regenerate the metadata from the original ZIP, install Pillow and PyYAML, then:

```powershell
python tools/import_basic_pack.py 'path/to/Pixel Art Top Down - Basic v1.2.3.zip'
```

## Validation

The proposed `Godot validation` GitHub Actions workflow runs the same entry point
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
adds a saved starter, deployment, tactical actions, and safe outcomes. Capture,
growth, quests, caves, and production wildlife simulation remain future work.
