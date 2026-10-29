# Runtime optimization

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
  temporary ground continues to cover queued chunks. Initial visible terrain
  and explicit rebuilds remain synchronous to preserve immediate coverage.
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
