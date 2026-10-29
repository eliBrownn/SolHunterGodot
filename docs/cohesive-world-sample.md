# Cohesive world sample

October 28, 2026. Bounded T4a composition study under the
[terrain roadmap](terrain-roadmap.md), originally measured on generation 6.
The owner authorized applying the bounded composition to normal play on October
28. This is not worldwide biome rollout or final performance/art acceptance.

Open `scenes/cohesive_world_sample.tscn` in Godot 4.7.2 and press F6.
The usual movement, camera, Observe/Engage, companion, combat, save and load
controls remain connected. Seed **2601026** uses these samples; other seeds and
areas outside their rectangles retain current scenery. Normal **F5** now includes
the same three bounded treatments; F6 on the review scene remains available.
Restart an already-running game to load the changed scene settings. Current
generation-7 seed-2601026 saves use the current geography. The subsequent
[route/pond pass](route-pond-diversity.md) requires a new expedition and rejects
generation-6 development saves. Original counts/costs below are historical
generation-6 evidence; they do not certify the changed geography.

## Connected places

| Treatment | Absolute bounds (end exclusive) | Review approach | Existing terrain evidence |
| --- | --- | --- | --- |
| Woodland | `(20,4)`–`(44,28)` | `(32,16)` | 270 forest cells, 259 marsh, 47 meadow. Woodland dressing is admitted only on the existing forest/meadow part. |
| Dryland | `(92,12)`–`(116,36)` | `(104,24)` | 450 heath cells, 126 meadow. Sparse dressing is restricted to heath. |
| Wetland | `(24,28)`–`(64,68)` | Dry pond approach `(32,32)` | Existing pond: 618 water and 157 bank/sand cells, plus surrounding forest/meadow/heath. This is shoreline treatment, not a claim that the pond generated a new marsh habitat. |

A bounded search of the existing seed selected these sites; it did not edit
moisture, terrain, water classification or generation settings to obtain them.
Walk east from the refuge and take the optional southern excursion through the
woodland to the pond. A reused sign originally at `(28,7)` supplies a small cue
(generation 7 moves it to `(28,16)`);
right-click identifies it as the pond side path. Rejoin existing travel, pass
the eastern waystone and visit dry ground near the next north–south route.
Return through the waystone/refuge network. No new route topology, collision,
bridge, encounter rule or authored story location was introduced.

The real-input review controller records the connected paths to woodland,
pond approach, dryland, waystone and refuge in its report. Fixed-camera art
captures explicitly reposition the player and are identified separately from
that walk. Existing wildlife supplies observation and tactical encounters;
the review never registers substitute individuals or changes affinity/ecology
to dress an area.

## Placement contract

Edit **3D View → Nature Settings → Composition** in the sample scene, or
`resources/nature_cohesive_sample.tres`. These are cosmetic Resources; restart
or rebuild applies edits, including on a loaded expedition. The expedition still
loads its own generation/relief/climate and identity state. Palette edits are not
saved as geography changes, and no save/generation version changes were required.

`NatureComposition` contains at most three nonoverlapping, seed-specific patches.
Each `NaturePatch` records absolute bounds, admitted existing habitat IDs, a small
palette, a density percentage and fixed observation/encounter clearings. Placement
uses separately salted absolute cells and three-cell clusters; it never consults
current actor positions or render order. That keeps it reconstructible after
unloading, save/load and cache eviction.

Each `NatureAssetEntry` specifies:

- A static scene, **Ground**, **Bank** or **Water** surface, and authored uniform
  scale. Flat pads and long logs are not normalized by height.
- Maximum transformed horizontal width and height, maximum terrain grade,
  mesh parts, material surfaces and submitted triangles. The supplied entries
  admit at most 16 parts, 16 surfaces and 2,048 triangles apiece; actual assets
  are substantially smaller.
- Ground/bank anchoring on the final terrain; floating anchoring at the existing
  horizontal pond level plus 0.012 cell. Floating plants leave water nonwalkable.
  Bank plants require an actual water neighbor.

Admission checks finite nonempty bounds, static MeshInstance3D descendants,
materials stored on meshes, and supported triangle geometry. Hidden nodes,
animation/skeletons, top-level transforms, skins and node/surface material
overrides are rejected rather than silently flattened into different art.
There is no animation adapter in this slice.

Admitted parts sharing a material are baked with SurfaceTool into one static
surface per material, with authored vertex attributes and materials retained.
The small palette is compiled before initial chunk publication. This optimization
was added after measurement exposed excess draws from separate fronds/stems.
Legacy blocking assets continue through their existing path. Admission bounds
remain conservative; checks compare the baked geometry with transformed source
vertices and verify equal triangle counts and retained material references.

The transformed visual rectangle, including a small margin, must fit the owning
chunk and patch. Every covered cell is checked against protected routes and their
approaches, authored foundations, water/land classification, generated blockers
and fixed five-cell-wide review clearings. Ground pieces also check final heights
and normals across their bounds; steep/poorly supported candidates are omitted.
This prevents logs, crowns or pads from extending through protected space merely
because their anchor was legal. Boundary rejection is deterministic.

All generated blocking trees and rocks keep the **same models, transforms and
pick records** as the existing renderer. Clustering affects nonblocking dressing
only. No hiding/removing a blocking tree to create an apparent clearing.

## Composition and limits

Woodland mixes low ferns, mushrooms, small bushes, pale flowers and short logs.
Dryland uses sparse olive grass, little stone groups and small bare snags.
Wetland uses low shore ferns, reeds/rushes on actual banks and floating lily pads.
These are existing inexpensive placeholders matched to the current kit; no new
model production, textures or simulation systems were needed.

At the shipped settings: **60 woodland**, **40 dryland**, **70 wetland** placements.
Wetland includes **33 floating pads**, **eight bank plants** and 29 ground pieces.
The focused suite checks a provisional per-chunk sample envelope of 48 instances,
256 mesh parts and 12,000 cosmetic triangles. This is a complexity check on the
bounded sample, not an approved desktop frame/memory budget or target-device limit.

## Review and validation

The focused `tests/nature_composition.gd` suite checks static admission, malformed
scale/flat-size rejection, actual published transforms and picks, unchanged
blocker models/transforms, exact cosmetic reconstruction after asset/terrain cache
clearing and reversed chunk publication, reconstruction from saved generation
settings, negative-coordinate borders, floating water level and water legality,
and per-chunk complexity. The suite is included in `tools/validate.ps1`.

The rendered review uses normal AI and checks that an art rebuild leaves the
complete live persistent snapshot unchanged. It walks connected sample approaches,
observes existing identities, enters/deploys/retreats from their tactical battles,
and checks save/load of the resulting state. It captures exploration, observation
and combat in clear daylight, clear night and rain, plus the existing guard's
warning and a woodland boundary/chunk seam.

Judgment so far: the three treatments differ through canopy context, open heath
and visible water/bank plants. Low dressing leaves routes and orb labels legible.
Night reduces ground-detail contrast as expected; rain needs the same terrain
and overlay checks rather than an assumed pass. Existing canopy can obscure the
trainer or an allied Sol at particular camera angles. Review includes an orbit
view without hiding the blocker. That remains a presentation limitation, not a
reason to silently remove collision art. Affinity orbs remain temporary Sol art.

Initial review fixtures exposed stale recap coverage and warning suppression by
prior battle grace. The final harness dismisses the recap through Continue
exploring and uses fresh guard scenarios; it does not change those gameplay rules.
The first shared-validator attempt stopped in the concurrently edited
`local_sol_reactions.gd` suite, with behavior assertions and empty-array accesses.
It is not recorded as a full pass. Logs retain this failure independently of the
focused scenery checks and rendered sample results.

## Reproduce and measure

```powershell
godot --path . --rendering-driver d3d12 res://scenes/cohesive_world_sample.tscn
godot --path . --rendering-driver d3d12 --script tools/review_cohesive_sample.gd -- --walk --output=res://artifacts/cohesive_sample/review
./tools/profile_cohesive_sample.ps1 -Godot <pinned-Godot-path> -Repeats 3
```

The matched cost runner alternates existing dressing and composed dressing in
fresh processes. Each sample/condition has 180 paced frames and a separate
180-frame uncapped/v-sync-off sample after warmup. It records draw calls,
primitives, chunk count, fixture construction, picking and actual process memory.
Reports include active view/nature settings, viewport, engine/driver, commands,
hardware and per-run before/after source/resource SHA-256 fingerprints. OS/driver
caches are retained. Changes to loaded game/settings/review code invalidate a
strict matched-cost claim; unrelated document/test changes are reported separately.
No player save is overwritten; review saves live under ignored artifacts.

Evidence is under ignored `artifacts/cohesive_sample/`, with focused checks in
`artifacts/cohesive_contract_checks.log`, shared validation in
`artifacts/cohesive_shared_validation.log` and per-review logs beside them.
Final evidence:

- Promotion check, October 28: `artifacts/cohesive_promotion_checks.log` passed
  **2,069 checks**, including the normal F5 entry, one pond sign, unchanged live
  state on rebuild and the existing placement/reconstruction checks. Promotion
  changes presentation only; winding routes and varied water geography are the
  next implementation slice in the terrain roadmap, not part of this art change.

- `artifacts/cohesive_contract_checks.log`: **2,066 checks, zero failures**.
- `artifacts/cohesive_sample/functional-final/`: **zero failures**, 31 captures,
  connected real-input walk, pointer-routed companion deployment, observation,
  safe retreat, and guard warnings visible in daylight, night and rain.
  `sample_outcomes.json` preserves three retreat receipts and the actual discovered
  individuals. Full persistent snapshots compared exactly across save/load.
- `artifacts/cohesive_functional_final.log`: complete functional-run log.
- Rendered regression logs `artifacts/cohesive_regression_full_3d.log`,
  `cohesive_regression_solid_geometry.log` and
  `cohesive_regression_terrain_integration.log`: 44, 19 and 1,823 checks passed.
  These ran before the material compaction; final compaction has the focused
  vertex/material/reconstruction checks and the final rendered gameplay review.
- `artifacts/cohesive_sample/matched-20261028/`: initial cost study. It revealed
  about 90–270 additional draws and woodland publication around 32 ms, motivating
  static material batching rather than immediate rollout.
- `artifacts/cohesive_sample/compact-matched-20261028/` and
  `compact-retry-20261028/`: final cost studies. Use completed pairs 1 and 2 from
  the former and the completed pair from the latter. The former's `composed3`
  exited without a report and is **incomplete**, despite exit code zero; its
  runner correctly failed. Do not include that run as a pass.
- `artifacts/cohesive_sample/compact_summary.json`: medians from the three
  complete pairs, with the source-drift limitations below.

## Measured cost and rollout decision

Forward+/Direct3D 12 on the RTX 3070 development machine, actual viewport
2560×1369, 60 FPS paced samples plus separate uncapped samples. Default view,
shadow/detail distances and quality settings are captured in each report.
The following daylight medians summarize the three complete pairs; they are
observations, not performance acceptance:

| Sample | Draw calls, existing → composed | Fixture rebuild ms | Maximum chunk publication ms | Picking average ms |
| --- | --- | --- | --- | --- |
| Woodland | 1,306 → 1,322 | 513 → 546 | 11.0 → 16.7 | 2.87 → 2.77 |
| Dryland | 1,157 → 1,158 | 464 → 484 | 8.2 → 11.5 | 2.32 → 2.41 |
| Wetland | 1,113 → 1,120 | 447 → 519 | 8.3 → 11.9 | 1.70 → 2.13 |

Composed daylight paced p95 was approximately 16.69 ms in these medians.
Uncapped p95 medians were 5.40 / 4.48 / 4.70 ms for woodland/dryland/wetland,
versus existing 5.55 / 4.80 / 6.60 ms. Do not infer an overall speedup: the
background workload, warm caches and concurrent source changes prevent that
causal conclusion. Full night/rain/p99/worst-frame data remain in the reports.
Composed initial synchronous scene construction ranged 1,411–1,432 ms; existing
was 1,337–1,482 ms. Composed process working-set peaks were approximately
637–690 MiB, versus existing 638–705 MiB. GPU memory was not measured.

The first compact pair had identical before/after source hashes across both
runs. Later repetitions overlapped edits to UI and wildlife code, including
`field_menu.gd`, `hud_accessibility.gd`, `inspection_card.gd`, `menu_settings.gd`,
`menu_theme.gd`, `ui_text.gd` and `authored_sightings.gd`. Their manifests identify
exact changes. Thus there is one strict source-matched pair and three complete
but not uniformly frozen pairs; the medians are provisional evidence, not a
three-repeat frozen-revision regression gate.

Material compaction substantially reduced the observed draw overhead without
changing placement. Publication, rebuilding and pond picking still cost more in
these samples. The next performance work is a source-frozen comparison against
agreed limits, particularly the synchronous publication/rebuild costs. The owner
subsequently authorized applying these bounded samples in normal play; these
observations do not authorize worldwide palette expansion.

Visual judgment: the final pond view exposes level pads and clear dry approaches;
the dryland view retains open ground; woodland has a distinct low understory.
Sols, their labels and combat tile/health information remain readable in the
sampled night/rain views. Existing canopy occlusion is still visible from some
angles, and the retained orbit captures show an available clear combat view.
Combat coverage is entry, actual pointer deployment, UI/overlay readability and
safe retreat; this is not full action-balance, damage-effect or battle-pacing
acceptance. Owner judgment of cohesion remains open.

Expansion beyond the three promoted areas remains closed until correctness, matched measured cost,
approved limits and owner visual review are satisfied. Export/AYN Thor qualification
and full T5 acceptance remain separate. Existing target budgets are still open;
this sample does not ratify a new performance target or complete Region One.
