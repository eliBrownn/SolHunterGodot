# D0 exploration foundation: implementation and evidence

October 26, 2026. Status: implementation validated; final player acceptance and device budgets remain open.

## Changes

The owner selected upright billboard characters. `scripts/sols/presentation/actor_billboard.gd` displays the explorer as a camera-facing Sprite3D, using the existing directional atlas, nearest filtering, source foot pivot, horizontal flip, and walking bob. The ground texture retains the existing flat shadow and hides the duplicate 2D body. Movement, terrain coordinates, saving, and ground-plane picking retain their existing authority. Trees and decorative props remain flat; no general 3D collision or elevation system is introduced.

`World.rebuild_world` now builds chunks intersecting the visible SubViewport plus a 128-pixel prop margin. The margin covers the current tree canopy's 120-pixel overhang. Remaining offscreen chunks use the existing one-per-frame queue. The live chunk budget remains 49. New seed and load no longer synchronously build the entire render radius.

## Repeatable benchmark

With Godot 4.7.2 stable on PATH, run:

```powershell
godot --path . --resolution 1280x800 --script tests/exploration_profile.gd
```

Use the installed console executable's absolute path if `godot` is not on PATH. Run without `--headless` for rendered measurements. The profile limits itself to 180 seconds and returns nonzero on a failed check.

The script performs a real-time waypoint-controlled expedition to the waystone and back, a negative-coordinate excursion and return, pause/resume, isolated save, a new seed, and restoration. It uses normal interpolated movement with waypoint clamping; it does not teleport during travel. Route planning is separately reported. A unique test save is cleaned up without touching the player's expedition.

The generated `artifacts/d0/profile.json` records engine, renderer, GPU, viewport, cap, seed, phase-specific wall-clock frame intervals, synchronous rebuild times, engine static memory, and chunk peak. Refuge, landmark, negative-coordinate, and pause PNGs are written alongside it. These generated files are ignored. This benchmark stays outside the normal CI suite because hardware timings are not portable acceptance thresholds.

## Observed results

Follow-up camera direction: the owner clarified that depth should come from
lowering the camera, without rotating the world sideways. The
scene now uses a 35-degree elevation and zero azimuth above the real XZ
plane, with a 64×48-unit surface and 2048×1536 texture. Both angles are exported
on the root node for adjustment in Godot. The upright character stays
camera-facing. Ground-plane picking and full viewport coverage at zooms 16, 22,
and 23 passed regression checks, alongside 2,389 smoke and 209 generation checks.
Refuge/landmark captures were regenerated for the lower, axis-aligned view.
The timing table below records the preceding camera/texture configuration and
must not be presented as measurements of this larger angled surface. New profile
reports include camera and ground-surface settings to make comparisons explicit.

Environment: Windows, Godot 4.7.2 stable, OpenGL compatibility renderer, NVIDIA RTX 3070, 1280×800, 60 FPS cap, seed 2601026, generation version 4. These are individual local runs, not statistically established speedups or portable-device certification.

| Measurement | Original full rebuild | Visible-first rebuild with upright character |
| --- | ---: | ---: |
| Initial scene construction | 219.55 ms | 110.07 ms |
| New-seed construction | 146.72 ms | 58.66 ms |
| Load/reconstruction | 146.83 ms | 48.41 ms |
| Save | 1.92 ms | 1.91 ms |
| Outbound frame p95 / p99 | 17.03 / 17.21 ms | 16.68 / 16.69 ms |
| Return frame p95 / p99 | 16.72 / 16.83 ms | 16.68 / 16.69 ms |
| Live render chunks, peak | 49 | 49 |

The first run contained an outbound maximum of 182.93 ms, and an intermediate run contained 114.41 ms. The final upright run's outbound maximum was 16.77 ms. That variation may include warm-cache/shader/OS effects; it is not evidence that all travel stalls have been eliminated. Separate synchronous rebuild measurements show less blocking work, but cold starts and target devices need further measurement. The frame cap includes pacing time and cannot establish uncapped GPU throughput.

Final rendered traversal completed with zero failures. Engine static memory peaked around 59.35 MB; this is not total process or graphics memory. Maximum observed travel chunk generation/publication costs were 3.29/0.41 ms.

## Verification and remaining acceptance

- Existing generation and migration tests passed alongside new regressions for immediate viewport/canopy coverage at startup, new seed, load, and negative coordinates; offscreen deferral; billboard direction/scale; duplicate-body removal; and ground anchoring.
- Final validation after the canopy-margin refinement completed 2,374 smoke checks and 209 generation checks with zero failures.
- Rendered captures were visually inspected at the refuge and landmark: the explorer stands upright with its feet on the ground, and terrain remained covered.
- The waypoint-controlled journey, objective state, pause state, test save/load, new seed, and bounded streaming passed. These are automated checks, not a substitute for a player walking the whole journey.
- Computer Use opened the scene in the editor and a standalone session for visual inspection. Synthetic keyboard presses did not establish live pause/movement acceptance; do not count that attempt as a successful manual control test.
- Still required: player judgment of the upright presentation/camera/scale, uninterrupted keyboard/controller journey acceptance, a target hardware/frame/memory budget, and repeated cold/warm measurements. No AYN Thor readiness claim is made.

Next implementation work after D0 acceptance: reconcile SolHunterSource's non-generation territory/identity/persistence contracts and prepare D1's bounded Godot data/save model. No combat, capture, or ecological tuning is invented by this D0 change.
