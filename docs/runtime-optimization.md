# Runtime optimization

## Map-first runtime evidence

Use the [map generator record](world-map-proposal.md#playable-handoff) for the
active terrain worker, horizon rings, and visual plant publication. The
[visual plant rollout](world-map-proposal.md#earlier-visual-plant-rollout--november-5-2026)
records its measured seed and workload. The expedition timings below apply to
their recorded routes, scenes, and settings. A map-first performance claim
requires measurements from that build.

## Live plant palette and Vastra consumers — October 30, 2026

The live procedural fallback palette now loads 68 compressed, prebuilt art
definitions under `resources/plants/runtime_palette/`. Recipes, dimensions,
accepted full-resolution geometry, organ anchors and canonical placement stay
unchanged. Bake-time compaction preserves native mesh LODs. The three neutral
tissue materials become one material with the same colors carried in vertices,
removing two material surfaces per design. Exact mesh-space picking bins are
also built offline, rather than reconstructed by a cold streamed cell.

Regenerate with the pinned engine using `--headless --path . --script
tools/bake_runtime_plants.gd` after changing the shared plant builders or picking
index. The manifest fingerprints those inputs, including the bake tool. The tool
rejects changes to its inputs during baking. Development/editor binaries reject
stale manifests; missing/stale entries use the original deterministic builders.
Exports package the versioned bake with the build (compiled script remapping
prevents checking source-file hashes there). Include the manifest JSON in export
filters when preparing an export. Authored plant-library entries retain priority;
the bake does not enable drafts, change ecological admission or enter saves.

Chunk MultiMeshes assemble their row-major transform/color buffers in the
existing bounded preparation slices and submit one completed buffer per batch.
Individual root pivots, linear colors, blade alpha, picking and animation
membership are retained. Publication remains atomic; GPU upload is still an
indivisible operation, not a hard frame-time guarantee.

Live filament rendering no longer constructs the hidden legacy ribbon surfaces,
per-vertex optical readings or connected-region fields. Conserved packet IDs,
paths, organ endpoints and clocks still feed the filament consumer. Explicit
legacy/debug views and optional scenery lights retain their required paths.
Changing between consumers invalidates the projection immediately. State,
periodic source/tuning and camera invalidations coalesce into one refresh per
frame; transfer sorting computes each source distance once.

`tests/bottleneck_regressions.gd` is connected to the existing validator and
checks all baked definitions, anatomy/dimensions, geometry counts/bounds,
material merging, baked-versus-fresh triangle bins, stale/missing bake rejection,
MultiMesh upload/animation membership and consumer switches. Its rendered run
also checks transform and color readback. `tools/profile_bottlenecks.gd` compares
the original builder and baked path over eight identical chunks and checks exact
cell, cosmetic-placement and living-source equivalence. An optional
`-- --reference=res://<archived-solid-chunk.gd>` also compares a captured prior
upload implementation. It is CPU work evidence, not a whole-game FPS assertion.

Evidence for this pass is under `artifacts/bottleneck-fixes/`. Rendered paired
tree samples for meadow and woodland were inspected; their images matched
pixel-for-pixel with native LOD disabled for the full-resolution comparison.
Performance and final validation results are recorded below after measurement.

## Terrain detail scheduling and material reuse — October 30, 2026

Detailed terrain now advances before temporary coverage. When visible coverage
has gaps, half the remaining frame work budget is reserved for it; once coverage
exists, detail can use the full remaining budget. This prevents cold fallback
preparation from repeatedly taking all detail time. Existing flora admission,
chunk publication limits and saved generation settings remain authoritative.

Terrain material samples share a bounded 32,768-vertex cache across neighboring
faces, shoreline skirts and near/far meshes. It combines soil and path sampling,
uses weak expedition ownership, and discards values on terrain replacement.
Eviction affects computation only; returned arrays cannot mutate cached weights.

The Godot 4.7.2 repeated-sample comparison recorded 686.618 ms before and
32.566 ms with reuse for 2,312 matching samples. This is material-sampling CPU
work, not whole-game FPS. Focused material (4,811), loading (64) and stutter
(353) checks passed. Editor scanning/class registration completed without script
parse errors, but editor safe-save failed; no clean import pass is claimed.
Loading/stutter fixtures retain
their Canvas/ObjectDB shutdown warnings. Evidence is under
`artifacts/terrain_audit/`; rendered completion evidence is recorded separately.

The generation-12 Direct3D 12 review drained all 68 initially queued detail
chunks through normal scheduling with accelerated frame calls. The final capture
(`fixed-view.png`) was inspected at the fixed 35-degree/zero-orbit camera and
shows the corrected pond-bank slope. Its 28.182-second accelerated workload is
not real-time travel/FPS evidence. The earlier 1,800 real-frame sample still had
42 queued chunks after 57.313 seconds; distant-detail latency remains measurable
follow-up work rather than a claim of instant full-world loading.

October 28, 2026. Scope: the six opportunities identified in the owner's code
review. Generation rules, collision, identity, clocks, combat resolution and save
formats are retained. This document records implementation and evidence; project
workflow remains in [PROJECT_STANDARD.md](PROJECT_STANDARD.md).

## Changes

- Later streamed chunks prepare eight cells at a time and upload one material
  batch per step. Preparation yields after the configurable 4 ms frame budget.
  One indivisible operation can overrun it; this is not a hard frame-time cap.
  A chunk is published only when its cells and geometry are complete. Camera
  replanning, new expeditions and load/rebuild discard stale work. Existing
  temporary ground continues to cover queued chunks. The October 30 loading follow-up below limits synchronous detail to the player
  chunk and preserves initial coverage with coarse generated terrain.
- Battle layouts reuse tile nodes, terrain overlay meshes, per-side Sol views
  and target-preview markers. Unused markers are hidden, and scale/position/color
  are reset on reuse. Session/state replacement releases the pools. Existing
  layout-change detection and species-specific view creation remain connected.
- Scenery selection first tests a conservative chunk-local bounding box, then
  cached object-local inverse transforms. Exact mesh triangles, alpha cutouts,
  distance cutoff and nearest-hit rules remain the final authority.
- Derived terrain caches evict one oldest entry on insertion at capacity. Their
  previous 65,536 height/normal, 32,768 slope and 256 pond ceilings are retained.
  A bounded key ring replaces whole-cache clearing. Explicit cache clearing
  resets that ring on the next insertion; generated values are unchanged. The
  key rings add bounded bookkeeping memory in exchange for smoother turnover.
- Ecology configuration checks reuse script property names while reading values
  freshly, including nested behavior definitions. Direct Inspector/script edits
  still invalidate the configuration. Inspection-card content/layout changes
  only when its reading or relevant size/text settings change; viewport resize
  and expansion keep their existing layout handlers.
- Frame diagnostics retain the last 3,600 samples in a circular buffer and
  refresh percentiles at most four times per second while visible.

No scenery-density, draw-distance, image-quality or AI-update reductions are
part of this work. Existing MultiMesh scenery batching is retained.

## Verification

`tests/runtime_optimization.gd` adds equivalence checks for sliced and synchronous
generation/geometry (including negative coordinates), bounded cache rollover,
stale-job cancellation, indexed versus exhaustive opaque scenery selection,
inspection invalidation, battle-node reuse, unchanged battle state, preview-pool
reset and diagnostic ring rollover. It is included in `tools/validate.ps1`.

`tools/profile_runtime_optimization.gd` is an optional paired CPU study. It
compares old property-list enumeration with cached names, exhaustive picking
with chunk rejection, and uninterrupted chunk work with preparation slices.
It checks matching outputs and writes `artifacts/optimization/paired_cpu.json`.
It does not establish GPU performance, a hard budget or AYN Thor acceptance.

The existing rendered expedition profiler remains the end-to-end check for
walking, encounters and current-format save/new/load. Source files were already
substantially modified when this task began, and concurrent species/presentation
work was observed. Previous baseline timings must not be treated as a frozen
revision comparison with this checkout. Normal expedition saves are preserved;
profile saves live in the artifact directory.

## Results and limits

Pinned engine: Godot 4.7.2 stable. Focused paired headless CPU study:

| Workload | Exhaustive/original work | Optimized work |
| --- | --- | --- |
| 300 scenery selections | 430.568 ms | 57.812 ms (7.45x faster) |
| 250 ecology configuration checks | 124.742 ms | 18.517 ms (6.74x faster) |
| Four cold-terrain chunks, largest uninterrupted call/slice | 25.701 ms | 4.494 ms |
| Same four chunks, total CPU work | 88.639 ms | 85.634 ms |

The chunk result primarily demonstrates shorter work slices, not a large
throughput gain. Both paths use warmed shared asset resources and independent
terrain instances with equal seeds. Selection and configuration outputs, and
prepared geometry, were checked for equality in the same process. Timing is
not a CI assertion or a claim of equivalent overall FPS improvement.

- The new regression suite passed **59 checks** headlessly and in a rendered
  D3D12 process, with no engine/script errors. Rendered execution also checks
  actual MultiMesh buffer equivalence rather than dummy-renderer placeholders.
- The latest rendered expedition passed all journey checks, including one
  automatic contact, withdrawal, both 78-step journeys, negative-coordinate
  travel, pause and complete persistent-state save/new/load comparison. Its
  source hashes matched before/after. No tests ran concurrently with the timed
  journey. Captures of the refuge and automatic encounter were inspected.
- The latest journey's maximum preparation slice was **4.685 ms**, with
  accumulated geometry work up to 16.649 ms per chunk. Travel p95 values were
  8.121/8.490 ms outbound/return. The roughly 971 ms outbound maximum includes
  the profiler's contact capture and deliberate 0.5-second encounter wait; it
  must not be presented as an isolated engine frame. Initial construction
  remained 2,610.799 ms and load/rebuild 734.533 ms in that process. These are
  observations, not approved budget passes or matched before/after comparisons.
- A separate sweep ran all 49 unique non-digit-named suites in the shared
  validator. The additional `view_3d`/`full_3d` suites and solid-3D smoke journey
  were exercised separately. Following fixture updates, fog horizon passed
  131 assertions, Sol menu 41, view 664, terrain integration 1,823 and the
  solid-3D smoke journey 2,506. Fog tests now wait for completed publication
  while requiring temporary coverage for visible partially prepared chunks.
  Sol-menu class expectations use the current catalog display names.
- **The shared validation gate is not green.** The first run stopped on
  shutdown resource/RID errors after the geometry assertions passed. The last
  editor/import attempt returned nonzero despite completing its displayed
  import steps. Rendered presentation also failed its two player-silhouette
  pixel assertions. Shutdown errors and the silhouette failures were reproduced
  using the captured pre-optimization chunk/solid-view scripts in this current
  checkout. This is evidence of combined-checkout problems beyond these
  optimizations, not certification that the rest of the game is error-free.
  No checks were suppressed or reclassified as passes.

Generated local evidence is under `artifacts/optimization/`: `paired_cpu.json`,
`check-results.json`, `final-check-results.json`, per-suite `checks/` logs,
`validation.log`, `validation-final.log`, rendered `latest-runtime/` and
`latest-journey/`, and captured-source reference reproductions. Early exploratory
logs include failed/replaced attempts; use the latest named logs for final
assertion results. The initial baseline process could not write its default
user log/shader cache, so its timings are not used to claim an end-to-end gain.
Later runs redirect application data into the ignored artifact directory.

Handheld qualification, sustained rendered cache-turnover testing and clean
full-suite acceptance remain outstanding. Initial-load staging is a separate
future change; immediate visible-world coverage has deliberately been retained.

## Second hot-path pass — October 28, 2026

The owner subsequently authorized all six follow-up opportunities from the next
review. This pass adds:

- Consumer-owned validation memos for movement-condition tuning and sightings.
  They compare the actual stored tuning graph before reusing a result. Direct
  nested edits, resource-array edits, packed arrays, resource replacement and
  packed-scene root changes invalidate the memo; public validators and admission
  checks remain intact. Snapshots retain values/IDs rather than Resource graphs.
  Normal movement without rough/warp/wet/wind conditions avoids move-library
  validation entirely, since its multiplier is unconditionally 1 in that case.
- A bounded recently-used temporary-ground cache, defaulting to 64 hidden
  chunks, with a connected Inspector setting. Unchanged camera/queue inputs skip
  repeated temporary visibility passes. Reversed views reuse cached nodes and
  meshes. New terrain sources and sample resolutions invalidate the pool.
  Active coverage remains immediate: the cache does not defer needed ground or
  impose a hard time cap on first-time cold coverage.
- One isolated roaming snapshot per member in a Sol visual update, reused for
  position, stance and reaction captions. The public copied-state boundary and
  the actual decision/commit loop remain intact.
- Incremental affinity overlays: reuse existing nodes, meshes and materials;
  update changed colors; release departed cells. A read-only nearby-color query
  copies no mutable world records and uses bounded spatial lookup for large
  imprint histories. One parent transform rebases all overlays, with immutable
  ground heights sampled only when creating geometry for a terrain source.
- One camera-frustum plane array per streaming-plan or temporary-coverage pass,
  shared by all chunk/AABB tests. Single-test callers retain the old wrapper.
- Combat layout invalidation from viewport, content minimum-size and visibility
  signals, plus cheap live text-scale/width comparisons. A later minimum-size
  signal requests the next-frame wrap correction; settled content no longer
  rewrites Control rectangles every frame.

`tests/runtime_hot_paths.gd` is included in the shared validator. Its initial run
passed 181 checks, covering direct invalid/valid tuning edits, in-place resource
array changes, repacking the same presentation scene, resource-graph release,
visibility equivalence, temporary mesh reuse/reset, one roaming read per member,
overlay reuse/recolor/grounding, nearby-query equivalence and mutation isolation,
idle layout suppression, wrapped content, scaling and viewport resizing.

The optional `tools/profile_runtime_hot_paths.gd` writes paired CPU results to
`artifacts/optimization_pass2/paired_cpu.json`. One successful local study gave:

| Workload | Previous/full work | New work |
| --- | --- | --- |
| 200 move-library validity checks | 57.680 ms | 48.862 ms; one full validation across 201 memo calls |
| 200 sighting validity checks | 84.171 ms | 45.975 ms |
| 1,000 normal-ground movement checks | 358.771 ms | 3.046 ms |
| Camera-reversal temporary coverage | 127.925 ms / 456 mesh builds | 41.718 ms / 150 builds / 306 reuses |
| Visibility tests across 100 13×13 passes | 28.145 ms | 11.052 ms |
| 1,000 settled combat-layout frames | 8.440 ms | 1.224 ms / zero full layout updates |

These are paired CPU workloads with warmed shared resources, not overall FPS,
GPU memory or device-acceptance claims. The temporary-ground comparison uses
identical camera poses and sample spacing; only the retention limit differs.
The cache adds bounded node/mesh memory. Source changes from simultaneous
traversal work were observed during this task, so full-check results must retain
their recorded source provenance rather than being treated as a frozen gate.

Final second-pass verification: `tests/runtime_hot_paths.gd` passed **186 checks**
after adding packed-array, external-dependency and cache-eviction cases. The
resource-lifetime assertion checks after its creation scope returns, excluding
GDScript VM call-argument temporaries. The rendered suite passed its earlier 181
checks without engine/script errors; `artifacts/optimization_pass2/combat-layout.png`
was inspected at an 800-by-600 viewport with wrapped content and enlarged layout.
The final 3D-view and fog suites passed **666** and **131** checks with no engine
or script errors. Queue-drain fixtures now allow multiple preparation frames per
resident chunk, consistent with the configured work budget; they retain their
coverage, publication, completion and bounded-capacity assertions. This is not
a new numeric loading-performance acceptance threshold.

The 18-suite targeted sweep covered the old optimization suite, ecology,
behavior inheritance, natural/procedural movement, player reactions, running,
affinity mechanics, combat presentation/sequencing, controller input, UI layout,
view/fog, Inspector tuning, persistence and full 3D. Its view/fog failures from
the earlier drain assumption were resolved by the final rechecks above. The
shared validator itself stopped during simultaneous version-7 terrain edits on
parse errors in the then-changing `terrain_geography.gd`; that affinity suite
subsequently passed separately. Do not describe this as a completed full-gate
pass or a frozen-revision regression result.

Second-pass evidence: `artifacts/optimization_pass2/validation.log`, its before/
after runtime source manifests, `check-results.json`, `finished-checks.json`,
per-suite `checks/` logs, `rendered-hot-paths/`, the layout capture and
`paired_cpu.json`. No expedition save format or game-mechanics changes were
introduced by this optimization pass. Concurrent feature/generation changes
are separate work and were preserved.

## Stutter fixes — October 28, 2026

The stutter audit exposed work outside the nominal 4 ms chunk budget and
sector-boundary reconstruction of unchanged creatures. The connected fixes are:

- Share one preparation deadline between temporary ground and detailed terrain.
  Warm the 25 cold road-region dependencies one region at a time before cell
  sampling; prepare cells individually, and fill instance/picking data in groups
  of 32. GPU surface uploads remain atomic rather than claiming a hard deadline.
- Retain a bounded cache of 32 hidden detailed chunks for camera reversals;
  republish their prepared cells and existing nodes, and spread evicted-node
  disposal over frames. World replacement clears retained geometry.
- Preserve unchanged Sol models, elapsed animation time and motion tracks when
  the local home window changes. Admit combat data only for new identities;
  explicit expedition rebuilds still reconstruct views. Reuse local home layouts
  until terrain, sector or nested authoring changes. Wild recovery skips occupied
  homes, and roaming callbacks reuse the already-admitted tuning for their batch.
- Coalesce mouse-motion hover work into one pick per frame, retaining immediate
  click targeting. Mesh-space triangle bins preserve exact triangle/texture-alpha
  picking; nature mesh and texture preparation occurs before exploration.
- Merge static nature render geometry by material, keeping original per-part
  picking and traversal boxes. Provisional defaults use 2x MSAA and a 36-cell
  decoration cutoff; terrain distance and ambient occlusion remain adjustable.
- Memoize companion and recovery-library validation with nested-edit detection;
  rebuild ecology configuration snapshots only when admission changes. Skip
  distant scenery bounds before local clearance scans and avoid running a ground
  path search whose result would be discarded by flight/swim traversal.

The focused sweep passed **19 suites / 4,175 checks**, including 352 stutter
regressions, terrain/streaming lifecycle and equivalence, exact alpha picking,
Inspector-style nested edits, movement, companionship, recovery and the connected
Sol journey. Evidence is under `artifacts/stutter_fix/`, including
`check-results.json`, per-suite logs and rendered expedition captures. Updated
fixtures exercise enabled affinity overlays independently of the production
opacity default and wait for the actual frame boundary/shared preparation queue.

The full shared gate was attempted but stopped on the separately changing
`tests/early_combat_moves.gd:187` (`victories` dictionary access); this occurred
before the partial combat-admission optimization was introduced. It is not a
full-gate pass. The initial restricted launch also could not create normal Godot
user/cache directories; subsequent checks used a writable, ignored local APPDATA
directory without modifying player saves or project user-data settings.

The final rendered 60-FPS-cap journey (`artifacts/stutter_fix/verified/profile.json`)
completed with zero journey failures on Godot 4.7.2 / D3D12 / RTX 3070 at
2560 x 1369. Travel p99 intervals were 26.66 / 25.79 / 22.94 / 26.83 ms across
outbound, return, negative and negative-return routes; worst intervals were
62.67 / 43.41 / 61.89 / 32.02 ms. Detailed preparation peaked at 6.38 ms
(a cold geographic-region operation: 6.23 ms; individual cells: 0.37 ms;
surface/instance finalization: 2.77 ms), compared with 20.40 ms in the preceding
clean-cache-directory intermediate run. The cache restored 39 detailed chunks.
The frame cap is therefore usually met, but this is **not hitch-free acceptance**:
movement/admission still peaked at 45.86 ms and a simulation callback batch at
18.05 ms. Startup and explicit save/new/load remain synchronous. Results are
desktop observations, not isolated GPU benchmarks or Thor qualification; the
initial restricted-launch audit is not a controlled before/after baseline.

## Loading and runtime follow-up — October 30, 2026

Plan: measure the current checkout; reduce synchronous startup/rebuild work;
reuse validated save candidates; remove unused optical work and repeated uploads;
route plant animation to its geographic chunks; verify geometry, persistence,
streaming lifecycle and rendered coverage. These steps are implemented below.

- Solid-world rebuilds publish the player's detail chunk immediately. The existing
  coarse-ground renderer covers pending visible terrain before returning; nearby
  detail then uses the existing bounded streaming jobs. Flat-world loading retains
  its visible-tile path. World generation, movement and saved ecology remain the
  authorities while detailed scenery is pending.
- Startup no longer compacts/tints/picks the entire biome palette. Existing shared
  asset caches prepare only assets actually requested by generated chunks.
- Streamed chunks prepare shared terrain material uniforms and biome patches once,
  rather than repeating that setup for each of their 256 one-cell work steps.
- Save reading retains the state and terrain admitted by validation and passes
  those exact objects to the load. Every candidate still checks format, state,
  generation parameters, flora membership, roaming positions and player position.
  No persistent trust cache or unchecked restore flag is introduced. Save-only
  validation does not allocate a restored state unnecessarily.
- Filament mode skips the hidden legacy particle/light update when no optional
  scene lights consume it. Optional lighting, legacy study rendering and debug
  heatmaps retain their existing paths.
- Filament path uploads invalidate on path changes or floating-origin changes;
  other uniforms update by value. Clearing positions are transformed once when
  their input changes, rather than separately for every transfer every frame.
- Plant events route directly to canonical 16-cell chunk owners, including negative
  coordinates. Unchanged paused poses skip transform writes; removed/replaced
  chunks restore their previous animated instances before reuse.

### Measurements and limits

Godot 4.7.2, current dirty development checkout, disposable save, headless CPU
study (`tools/profile_loading.gd`). Baseline and initial corrected coverage run:

| Operation | Before | After |
| --- | ---: | ---: |
| Scene initialization after resource loading | 35,536 ms | 5,234 ms |
| Explicit warm rebuild | 11,483 ms | 1,092 ms |
| Disposable save load | 32,591 ms | 3,477 ms |
| Synchronous detailed chunks | 51 | 1 |

Resource loading was approximately 3.7–3.8 seconds separately. These samples use
in-process rebuilds/loads and retain OS/driver caches; they are observations, not
performance thresholds or a claim about every save size. This profiling save has
no flora ledger; the regression fixture separately exercises a populated ledger.

The final rendered D3D12/RTX 3070 sample at 2560 × 1369 initialized in 5,924 ms
plus 2,689 ms resource loading and loaded its disposable save in 3,203 ms. There
were 52 initial coarse chunks. Removing repeated chunk setup improved the 1,800
frame streaming sample from 8 to 21 newly published detail chunks (46.2 and 37.3
seconds respectively). This is not complete-detail acceptance: 47 chunks remained
queued in the latter sample. One cold cell/asset operation reached 205 ms and
an individual preparation slice reached 209 ms; asset compilation remains
indivisible. The new loading behavior makes the expedition available sooner but
does not eliminate all streaming hitches. No density, draw-distance, simulation
rate or visual-quality tuning was reduced. No Thor/device acceptance is claimed.

Evidence: `artifacts/loading/` contains the disposable save, profiling output,
rendered first/streaming views and validation logs. `tests/loading_regressions.gd`
is included in the existing validator; it verifies initial ground coverage,
populated save admission/rejection, chunk routing/restoration, paused work skips,
and filament invalidation. Existing smoke coverage now accepts generated coarse
ground while detail is queued, and the eviction fixture waits for its second
streamed chunk. Validation results are recorded after the final checks below.

Validation: Godot import/parse passed. Focused suites passed: loading regressions
60, runtime optimization 62, world optimization 8,488, stutter regressions 353,
Vastra currents 129, persistence foundation 76, and rendered plant-event animation
45 checks (9,213 combined). Script ownership passed with 181 mapped scripts/UIDs.
Headless plant-event geometry readback has two failures also reproduced with the
original animation loop; the rendered D3D12 test passes all 45 assertions.

The final solid-world smoke journey completed 2,532 checks with one unrelated
stale assertion expecting eight rogue mesh pieces, while the configured player is
now the grave knight. Coverage, movement and save/new/load assertions passed. This
is not a full-validator pass, and that model-specific assertion remains unchanged.
Earlier restricted runs could not write disposable user-data fixtures; the final
persistence/journey runs used normal Godot access. Existing Canvas/ObjectDB exit
warnings were also present in the initial baseline. No commits, staging, push or
merge were performed; the checkout's pre-existing content changes are preserved.

### Grass surface reuse — October 30, 2026

Dense blade placement now resolves each canonical cell's four terrain vertices
and two triangle slope checks once, rather than once per candidate blade. Blade
height interpolation retains the canonical triangle split and original floating
point offsets. Specialized terrain scripts retain their surface-query overrides.
No density, draw distance, appearance or reserve tuning changed.

A paired 256-cell CPU comparison against the pre-edit script matched complete
batch dictionaries and living-source records at divisions 2, 8 and 16, both with
and without specialist center clearance (six comparisons, zero differences).
At 16 divisions the measured placement work fell from 129.185 to 73.250 ms and
120.989 to 69.096 ms (about 43%); at 8 divisions it fell from 47.832 to 29.171 ms
and 41.446 to 25.882 ms. These are single-run local CPU observations, not FPS or
GPU claims. The copied baseline and comparison harness are disposable local
artifacts under `artifacts/deep-optimization/`.

Godot 4.7.2 import/parse passed with normal editor-directory access. Focused
validation passed: `tests/grass_surface_optimization.gd` (26,745 checks across
13,371 blades, two canonical seeds and a surface-override fixture),
`tests/foliage_rollout.gd` (7,293 checks), and `tests/world_optimization.gd`
(4,328 checks). The latter reported Canvas/ObjectDB exit warnings. This is not
a full-validator pass or rendered gameplay/FPS acceptance. Changes remain
uncommitted on `codex/deep-grass-optimization`, preserving the existing dirty
checkout; the edited grass script was already untracked before this pass.

### Launch preparation — October 30, 2026

The world controller no longer constructs a default WorldTerrain before its
configured new expedition replaces it. Terrain is initialized by the existing
validated new-expedition path before gameplay starts. Raw heightfield integer
vertices now use a bounded 32,768-entry derived FIFO cache, shared by repeated
foundation, road and drainage preparation. Cache eviction reconstructs identical
values and does not affect saved parameters. Terrain material masks use the
canonical visible-trail query without constructing full affinity/ecology cell
records; specialized review sample overrides retain their original behavior.
Optional legacy animation packs and the Development Lab scene load on first use.

The existing `tools/profile_loading.gd` headless study measured resource loading
plus scene readiness at 10.369 seconds before and 8.565 seconds after (about 17%
less). Scene preparation alone fell from 6.625 to 4.804 seconds (about 27%).
Disposable-save loading measured 3.793 versus 2.746 seconds. Both samples retained
one detailed player chunk, 55 coarse ground chunks and 72 queued detail chunks;
coverage and detail settings were not reduced. These are local single-run CPU
observations with OS caches retained, not process-to-playable guarantees. Resource
loading itself was effectively unchanged (3.745 versus 3.761 seconds). Other
rendering work was being edited concurrently and was preserved, so this is not
an isolated whole-renderer benchmark.

The rendered production scene reached a visible first frame; its screenshot is
`artifacts/launch-optimization/first-frame.png`. That run fell back from Vulkan
to Direct3D 12 and measured 17.858 seconds from script entry to captured frame;
it is separate evidence, not comparable to the headless CPU figure. The lab
round-trip retry passed after concurrent shader edits settled. No renderer
configuration changes were made by this launch pass. Raw logs and copied
pre-edit scripts live under `artifacts/launch-optimization/`.

Final focused validation: Godot 4.7.2 import/parse passed; launch optimization
742, loading regressions 74, terrain heightfield 298, terrain geography 8,754,
world generation 147 across 11 seeds, and development-world round trips 31 checks
passed (10,046 total). Loading fixtures retain the previously observed
Canvas/ObjectDB exit warnings. The full configured validator and an exported
build were not run. Reviewed changes remain uncommitted alongside the owner's
existing changes on `codex/deep-grass-optimization`; no staging or push occurred.
