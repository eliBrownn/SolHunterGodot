# Runtime concurrency roadmap

## Development decision — November 1, 2026

The owner selected one worker for development and stopped further broad testing
and comparisons. Existing repeated-travel results are sufficient: both worker
counts cleared the backlog, nearby readiness was similar, and one worker used
about 69 MiB less engine memory. The active development checkout now includes
the integrated worker path, defaults to one preparation job, and retains serial
fallback. The installation receipt and pre-integration backups are under
`artifacts/concurrency/development-worker-install.json` and
`artifacts/concurrency/active-integration-before/`.

Focus now moves to gameplay hitches using the existing
[stall findings](runtime-optimization.md#repeatable-baseline-and-stall-attribution--november-1-2026).
Faster scenery readiness does not prove smaller rendering stalls. The expanded
validator was stopped at the owner's request; the planned final comparison
matrix did not start. Historical partial/diagnostic gates are not full passes,
and native-exit issues remain recorded in the qualification artifacts. Steps 1–5
below are retained as historical scope, not an active testing queue or a claim
of release acceptance.

## Historical qualification plan — owner-requested steps 1–5

Execution is in the isolated `codex/chunk-qualification` worktree at
`artifacts/concurrency/qualification/`, based on `712a50c`. The active development
checkout and its newer edits remain preserved. This block is an in-progress
receipt, not enablement or owner acceptance.

1. Fresh-process comparisons in reversed order: profiler/launcher prepared;
   combined-build trials pending final validation.
2. Unseen negative travel and abrupt orbit/zoom/reversal: expanded fixture ready;
   rendered qualification pending.
3. First-use stall attribution: resource/instantiate/tree-ready timing,
   per-frame CPU phases and renderer pipeline counters implemented; results pending.
4. Deliberate integration: newer movement/simulation, plant retirement/reserve
   presentation and terrain-query work reconciled, matching 153-definition bakes
   regenerated, and 77 checks passed against the current serial builder. The first
   full gate exposed a frame-count-based field-action fixture; its corrected
   readiness-based form passes 15 checks. Later fixture corrections and focused
   checks are recorded in the qualification worktree. Broad validation stopped;
   no complete configured-validator pass is claimed.
5. Play review: a one-worker launcher with disposable saves is prepared at
   `tools/open_chunk_review.ps1` in the qualification worktree. Hands-on review
   follows automated measurements; owner acceptance remains separate.

November 1 implementation receipt: the selected chunk-population path is now an
isolated candidate on `codex/chunk-population`. See the [implementation and measured
results](../artifacts/concurrency/worktree/docs/runtime-optimization.md#background-chunk-population--november-1-2026).
Three fresh-process runs per mode completed 47/47 requested chunks in roughly
27 seconds with background preparation, versus 11/47 within the serial 30-second
window. Fill-window frame p95 increased with the additional populated content;
full figures, memory limits and acceptance scope are in that receipt. Current
movement/simulation/rejected-art edits in this checkout remain separate. The
broader MT0–MT8 roadmap below is not a completion claim for every domain.

Resume receipt, November 1: the isolated candidate is checkpointed at `bf72a63`.
A matched serial/one/two-worker screening reached the same 48 visible chunks:
47 queued chunks filled in 112.992 / 29.695 / 26.347 seconds, with zero journey
failures and unchanged study inputs. See [readiness and equal-population memory
screening](../artifacts/concurrency/worktree/docs/runtime-optimization.md#readiness-and-equal-population-memory-screening--november-1-2026)
for memory, frame times and measurement limits. Step 1 below is complete;
steps 2–3 have screening evidence. Longer unseen travel, repeated memory plateau
studies/budgets, input latency, hitch attribution and combined-build qualification
remain open. No worker default or live-build integration is accepted by this run.

Extended travel receipt: serial, one-worker and two-worker modes pass three
96-cell sprint/return cycles with real cache eviction/regeneration. Both worker
modes end each cycle without a backlog and show stable observed memory; first-cycle
nearby missing-request ages peak around 13.1 seconds versus 46.4 seconds serially.
One worker retains about 69 MiB less engine memory than two at the final equal
56-visible/16-cached population, making it the preferred next qualification
candidate. See [the extended receipt and prospective qualification targets](../artifacts/concurrency/worktree/docs/runtime-optimization.md#unseen-scenery-return-travel-and-memory-stability--november-1-2026).
Fresh-process repetitions, negative/camera coverage, residual-stall attribution,
combined-build validation and owner review remain open. No live default changed.


October 31, 2026. Status: original engineering proposal retained below.
The November 1 chunk candidate is implemented separately; integration and
performance acceptance remain open.

## First-pass revision and next steps — November 1, 2026

The first pass supports continuing background chunk preparation. The next
delivery milestone is qualified chunk population, with other systems in MT6
deferred unless profiling identifies a material problem. Retain the existing
exclusive-context ownership, cancellation, epoch checks, shared serial
calculation and main-thread publication design. This section sets the current
execution order; MT0–MT8 below retain their detailed contracts and wider scope.

Implemented candidate work spans the selected chunk portions of MT1–MT4 and
some MT5 transition/teardown safeguards. It does not close those phases in full.
Focused correctness and rendered checks pass; the full validator, combined-build
acceptance and owner play review remain open. See the implementation receipt
above for exact inputs, results and limitations.

1. **Preserve a reviewable checkpoint.** Commit the tested isolated candidate
   with its docs, tests and matching bakes before further runtime changes.
   Keep the newer movement/simulation/rejected-art work separate until deliberate
   integration; a checkpoint is not approval to merge or enable the live build.
2. **Measure player-area readiness and choose concurrency.** Make elapsed time
   to nearby ground and scenery readiness during normal travel the primary
   outcome, alongside total completion, queue age, frame distributions and input
   latency. Compare serial, one-worker and two-worker modes with matched route,
   seed, settings, camera and content. Two workers are the candidate default,
   not yet the accepted default. Four-worker expansion is outside this chunk
   milestone unless the one/two comparison supplies a reason to pursue it.
3. **Close the memory evidence gap.** Compare modes at the same populated chunk
   count and record preparation peaks separately from settled residency. Include
   snapshots, private caches, queued results and retirement, plus process/GPU
   memory where measurable. Repeat travel and eviction until memory/backlogs
   demonstrate a bounded plateau. Existing 11-versus-47-chunk memory figures
   cannot establish worker overhead; result-size limits are not a total memory
   budget. Record explicit acceptance budgets before claiming enablement.
4. **Attribute the remaining first-use stalls.** Both measured modes still
   reached roughly 3.4-second maximum frames. Separate resource acquisition,
   canonical CPU preparation, publication/uploads and pipeline compilation using
   phase measurements and renderer monitors. Change the demonstrated cause and
   repeat the affected study; faster population alone does not close hitch work.
5. **Integrate deliberately and qualify the combined build.** Reconcile newer
   movement/simulation and content changes without copying the dirty checkout
   wholesale. Run relevant checks for changed dependencies and the configured
   full validator unchanged at the integration gate. Exercise long unseen-area
   travel, fast camera orbit/zoom/reversal, return travel and cache eviction,
   populated saves, repeated new/load/quit, pause and settings/content changes
   while work is active. Recheck affected performance evidence on the combined
   inputs. Track baseline failures separately; do not call a partial pass complete.
6. **Review play feel and accept rollout.** Owner review must confirm that nearby
   scenery keeps up with play. Select the worker default from the measured
   readiness, frame-time and memory balance, retain the serial fallback, and
   publish remaining stalls and hardware limits. Lower-core/device qualification
   remains open until tested; other systems need their own evidence before offload.

Reuse valid first-pass checks and receipts. Repeat a study when its relevant
inputs change or a gap above requires new evidence, rather than restarting the
entire MT sequence. Full startup staging and asynchronous save writing remain
separate, unfinished MT5 work; chunk transition tests do not establish their delivery.

## Chunk population research and selected direction — November 1, 2026

Owner play observation: the game feels responsive while chunks struggle to
populate. The selected direction is background chunk preparation, with faster
nearby scenery readiness as the primary outcome. Keep simulation, density and
draw distance intact. Research does not enable workers in the active checkout.
The wider MT sequence below remains the lifecycle/correctness framework; this
section narrows the first delivery to chunk population rather than threading
every system. Measurements guide implementation and rollout settings, rather
than reopening whether to pursue this owner-selected approach.

### Findings from the current pipeline

- `scripts/application/world.gd` advances `pending[0]` and stops when it is not
  ready. `world_solid.gd` holds one `stream_job`. One slow chunk therefore delays
  later requested detail; the current serial path cannot prepare several chunks
  independently. Finishing admitted work first also deliberately avoids churn.
- `View3DSettings` defaults to 3 ms shared preparation per frame, one completed
  detail chunk and two detail batch uploads per frame. Flora and coarse coverage
  share preparation time. At 60 FPS, 3 ms/frame is nominally 180 ms of preparation
  per second before those other consumers; this arithmetic is not a measured
  throughput limit because atomic operations can overrun. Smooth frames and slow
  population are compatible with this scheduling design.
- `view_streaming.gd` selects near/frustum chunks, applies a fixed prefetch margin
  and active-radius cap, and sorts by distance. It does not predict movement or
  size lookahead from observed end-to-end chunk readiness time.
- Current cell cursors still retain terrain, settings and chunk references.
  Terrain caches and plant/model caches mutate during preparation. Submitting the
  existing `advance()` to a worker would not establish safe ownership.
- The existing isolated experiment on `codex/chunk-worker-pipeline` already
  implements bounded instance-buffer packing and asset prefetch. Its report is
  `artifacts/concurrency/worker-report.md`; that worktree and worker-only patch
  must be reviewed before reuse. It leaves canonical generation, placement and
  picking on the main thread. Screening found no consistent frame-time benefit;
  it did not establish whether heavy offload improves time-to-detail.
- The later serial cell split preserves output but its warmed paired fixture
  used 19% more total CPU work while shortening uninterrupted operations. Smaller
  slices alone are therefore not evidence of faster population. See the latest
  [optimization evidence](runtime-optimization.md#resumable-cell-preparation--november-1-2026).

### Implementation shape

1. Reuse the audited coordinator/lifecycle concepts from the isolated experiment;
   reconcile its frozen dependencies with the newer cell/bake work deliberately.
   Keep the separate implementation branch/worktree requirement below.
2. Extract a data-only chunk recipe/result: canonical samples and dependency halo,
   resolved model descriptors, placements, geometry arrays, instance buffers,
   picking records and source/organ anchors. Keep immutable model data or exclusive
   contexts alive for each job. Resolve cache writes and callback captures before
   moving a stage; avoid reconstructing a whole terrain/resource graph per chunk.
3. Begin with one heavy preparation task in flight, then trial two. Use a bounded
   ready-result queue so a blocked request does not prevent independently ready
   nearby chunks from publication. Required access/flora dependencies and stable
   canonical admission remain ordered by their existing owners.
4. Request only the upcoming chunks' required baked resources through the engine
   background loader, deduplicated by path. Retrieve completed requests only.
   Preserve fingerprint checks and authored priority; audit any fallback model
   generation separately instead of moving shared builders blindly to workers.
5. Prioritize missing nearby/visible detail, then predicted travel. Size bounded
   lookahead from movement speed and measured p95 request-to-publication latency,
   with a margin for turns. Replan when heading meaningfully changes; retain useful
   work and cap speculative bytes. Existing radius/resident caps remain binding;
   any expansion needs explicit memory/coverage evidence and adjustable tuning.
6. Keep node/resource mutation and GPU upload/publication with the main owner.
   Retain coarse coverage until full replacement is ready. Poll jobs without
   waiting on unfinished work; validate epoch/content revisions before commit and
   reap all completed/discarded task handles. Keep the equivalent serial path.

### Acceptance for this slice

Record request-to-visible-detail p50/p95/max, nearby missing-detail count and age,
queue-drain time, completed chunks/second and time waiting for assets/publication.
Use stationary fill, normal outbound/return travel, abrupt turns and negative
coordinates on matching inputs. Compare against the current serial build, with
frame tails/input responsiveness and peak memory alongside population latency.
Passing requires faster useful population without changed generation/geometry,
stale commits, missing canonical sources or impaired play responsiveness. Check
pause, cancellation, new/load and shutdown; preserve known unrelated failures.
No numeric improvement is claimed by this research update.

### Primary-source research

Official Godot documentation accessed November 1, 2026; stable pages are moving
references, so verify implementation against the pinned Godot 4.7.2 binary.

- [WorkerThreadPool](https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html)
  supplies persistent workers and completion polling; tasks require eventual
  collection, and small jobs can cost more than inline execution.
- [Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html)
  documents active-tree/shared-resource constraints and GPU synchronization costs.
  Detached records are the conservative project boundary, not a claim that every
  off-tree engine operation is forbidden.
- [Background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html)
  supports asynchronous resource requests; retrieving an unfinished request blocks.
- [MultiMesh optimization](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)
  describes preparing linear buffers across threads and submitting a complete
  buffer. The page labels itself not fully updated for 4.7; validate exact layouts
  with current API/fixture results and preserve spatial chunk batching.
- [Pipeline compilation](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
  explains why background mesh loading can help some first-use costs while scene
  instantiation/render features can still trigger additional compilation. Track
  those costs separately from worker compute and asset retrieval.

October 31 serial optimization follow-up: the owner-requested chunk hitch-control
pass now supplies a rendered journey and isolated geometry/geography comparisons
under `artifacts/chunk-limits/`, indexed in
[runtime optimization](runtime-optimization.md#chunk-hitch-controls-and-local-vastra-effects--october-31-2026).
The rendered journey still recorded 46.465 ms for one scenery-cell preparation,
51.730 ms for simulation and 96.551 ms for movement/admission. This supports a
focused MT0 dependency audit and the first isolated worker experiment; it does
not prove all that time is worker-safe CPU work. Current serial defaults are
3 ms preparation plus a separate 0.5 ms retirement allowance, with explicit
operation/upload/resident caps. Shared terrain caches still have one writer.
Threading, asynchronous resource acquisition and the MT0–MT8 gates remain pending;
retain the isolated-branch requirement below when starting this roadmap.

## Multithreading preparation checklist — November 1, 2026

Owner-requested preparation update. This checklist makes the existing MT0–MT3
entry gates actionable; worker implementation and performance acceptance remain
pending. Complete preparation in order and attach evidence to the existing gates.
The master roadmap retains cross-feature priority.

### 1. Establish the implementation candidate

- [ ] Inventory dirty/untracked files and identify which runtime changes belong in
  the candidate. The inspected checkout is `codex/cell-preparation`, with extensive
  ongoing work; a commit hash alone cannot describe these inputs.
- [ ] Verify the integration base and create the isolated `codex/` branch/worktree
  required below before implementation. Bring required unmerged dependencies in
  deliberately; do not copy the entire dirty checkout or stage unrelated work.
- [ ] Record candidate revision, source/configuration hashes, Godot 4.7.2, renderer,
  hardware, asset/bake availability and known failures in `artifacts/concurrency/`.
  Link existing receipts rather than treating historical results as current passes.

### 2. Measure the serial workload (MT0)

- [ ] Use `tools/profile_current_expedition.ps1` for repeated capped/uncapped
  rendered expedition measurements; inspect its exercised windows before claiming
  workload coverage. Keep `tools/profile_loading.gd` loading/smoke results separate.
- [ ] Cover startup to usable ground and nearby detail, outward/return travel,
  camera changes, populated-save admission, true pause and expedition/lab suspension.
  Use disposable profiling saves; preserve owner saves and review artifacts.
- [ ] Record capture, compute, admission, upload and retirement separately, with
  frame distributions, coverage latency, retained bytes and unfinished work.
  Mark missing instrumentation as missing evidence, not zero cost.
- [ ] Set numeric acceptance targets from reproducible runs, then select the
  largest remaining bottleneck. Record whether its cause is CPU, I/O, GPU or
  main-thread publication before choosing a worker candidate.

### 3. Audit and extract one boundary (MT0–MT1)

The following are inspected starting points, not approved worker entry points:

| Boundary | Current coupling to resolve | Preparation receipt |
| --- | --- | --- |
| `scripts/presentation/stream_chunk_job.gd` | Retains live terrain, tuning and scene references; advances main-thread generation and chunk work | Dependency inventory and detached input/output schema; same serial output |
| `scripts/presentation/coarse_ground_job.gd` | Reads live terrain/tuning, caches vertex data and includes an upload stage | Separate CPU records from publication; retain continuous ground coverage |
| `scripts/world/terrain.gd`, `terrain_heightfield.gd`, `plant_community.gd` | Query paths populate mutable caches; community sampling accepts a Callable | Transitive read/write audit, exclusive evaluation context and explicit dependency halo |
| `scripts/persistence/expedition_state.gd`, `save_store.gd` | Live transactions, callbacks and admission retain authoritative state ownership | Coherent snapshot boundary and main-owned commit; no live terrain hint in worker validation |

- [ ] For the chosen boundary, enumerate nested objects/resources, static caches,
  callback captures, RNG and scene/server access. Assign every dependency to the
  main owner, an exclusive task context or proven immutable storage.
- [ ] Define input/result versions, epoch, relevant revisions, canonical IDs,
  cancellation checkpoints, byte estimates and the current owner's commit checks.
- [ ] Run the extracted calculation serially first. Compare canonical records,
  access, flora/source IDs, placement/geometry and relevant save behavior using
  existing focused fixtures. Include boundaries, negative coordinates and eviction.
- [ ] Bound snapshot, publication and retirement work before introducing parallel
  completion bursts. Preserve matching bakes and current gameplay/visual settings.

### 4. Decide whether to start workers (MT2–MT3)

- [ ] MT0 baseline/targets and MT1 equivalence evidence are complete for the slice.
- [ ] A measured CPU bottleneck remains large enough to justify task overhead.
- [ ] The coordinator's bounded queues, stale-result rejection, cancellation,
  exact-once collection and shutdown lifecycle pass controlled tests in MT2.
- [ ] Serial fallback uses the same calculation and commit path. Trial one job
  before comparing two/four; retain main-thread state/scene publication.

If any gate lacks evidence, keep the slice serial and record the next missing
receipt. Completion of this Markdown checklist's preparation text is not MT0
completion, a worker rollout or a gameplay validation result.

## Recommendation and limits

Establish concurrency contracts now, then move measured workloads to workers in
bounded slices. Do not convert every game system to a thread. The existing domain
owners, deterministic generation, baked art and transactional persistence are
valuable foundations; retain them rather than rebuilding the architecture.

I agree that this is a useful time to establish fundamentals. I disagree that
having most systems present makes a game-wide threading conversion safe or
necessary. The current alpha register still identifies combat, ecology and weather
integration gates. Also, many current read queries mutate caches. Readiness for
parallel execution must be proved per dependency, not inferred from feature count.
No plan can guarantee the absence of concurrency bugs or hardware-specific stalls.
This plan makes failure detectable, bounded and recoverable, and requires evidence
before each rollout.

[PROJECT_STANDARD.md](PROJECT_STANDARD.md) remains the workflow authority, the
[world roadmap](world-exploration-roadmap.md) owns alpha sequencing, and
[runtime optimization](runtime-optimization.md) retains existing optimization
evidence. This document owns only the proposed concurrency implementation sequence.
It does not change mechanics, simulation rates, art density, draw distance, save
compatibility policy, the engine pin, or delivery status. For an actual mechanics
ambiguity outside generation, follow [mechanics reference](mechanics-reference.md)
before implementation. Preserve the Bible and current approved contracts.

## Verified starting point

- `stream_chunk_job.gd` explicitly performs resumable main-thread work. Its deadline
  is checked between geography, generation, cell construction and finalization
  operations; none can be interrupted by that check.
- `WorldTerrain`, `TerrainHeightfield`, geography and plant communities populate
  mutable caches during queries. A shared reference is not a read-only snapshot.
- `SolidChunk` combines data preparation with mesh/material/node work. Extracting
  data builders is required before dispatching its expensive work to workers.
- `ExpeditionState` owns persistent mutations and emits synchronous signals from
  clock and transaction methods. Moving those methods wholesale would also move
  their callbacks onto an unsafe execution path.
- The current readiness contract reserves combat tiles and merges outcomes into
  current state. A worker must never replace live state with a battle-start copy.
- Save admission can reuse a matching live terrain object and its derived caches.
  That optimization does not make the object safe for concurrent validation.
- Startup still constructs the player chunk, authored places and initial coarse
  coverage synchronously. Streaming improvements alone cannot remove that boundary.
- The inspected plant bake fingerprint matched its source inputs. Recorded paired
  CPU evidence reduced eight chunks from 19,802.833 to 1,192.055 ms, but the baked
  run still reached a 23.042 ms preparation slice. These are historical workload
  observations, not a current whole-game benchmark or a physically cold-cache run.
- The October 31 reassessment also inspected `artifacts/loading/profile.json`:
  resource loading was 4,638.699 ms and scene initialization 4,634.855 ms, about
  9.27 seconds combined. This is an existing rendered loading sample with retained
  OS/driver caches, not a newly executed benchmark or time-to-playable guarantee.
  It records no streaming sample; zero stream counters do not demonstrate smooth
  travel. The profiler enables smoke mode after initialization, excluding normal
  movement and ecology from subsequent sampling, and its save has no flora ledger.
  Obtain separate active-gameplay and populated-save evidence in MT0.

Starting code: [world](../scripts/application/world.gd),
[solid-world host](../scripts/application/world_solid.gd),
[chunk job](../scripts/presentation/stream_chunk_job.gd),
[chunk publication](../scripts/presentation/solid_chunk.gd),
[terrain](../scripts/world/terrain.gd),
[community](../scripts/world/plant_community.gd),
[state](../scripts/persistence/expedition_state.gd), and
[save admission](../scripts/persistence/save_store.gd).

## Ownership and execution contract

One main-thread coordinator owns application job admission, dependency readiness,
publication and retirement. Domain owners retain their existing authority. Workers
calculate detached results; they cannot call live state transactions or manipulate
active scenes. Use Godot's existing worker pool for finite CPU jobs and its threaded
resource loader for asset I/O. Application concurrency is an in-flight cap, not an
assumption that the engine's entire pool belongs to this game subsystem.

Proposed flow:

```text
Owner captures a versioned, bounded input
  -> coordinator resolves dependencies and reserves memory
  -> finite worker task computes detached data
  -> synchronized result handoff
  -> main-thread owner validates identity, revisions and current legality
  -> bounded commit/publication
  -> main-thread signals and presentation
```

The following rules are requirements for implementation:

1. **One writer per fact.** `WorldTerrain` remains generation authority;
   `ExpeditionState` remains the live saved-state writer; battle owners retain
   plans/events and once-only outcomes. Workers hold derived data, not new owners.
2. **Inputs cannot alias mutable live objects.** Copy plain bounded records and
   packed arrays; use explicitly transferred or immutable storage. `duplicate(true)`
   alone is not proof: referenced Resources, Objects, Callables and nested values
   require an audit. Do not capture scene nodes, live terrain or state through a
   worker closure. Noise generators and scratch caches are exclusively task-owned.
3. **Task contexts have explicit ownership.** Pool tasks have no assumed worker
   affinity. Reusable contexts require exclusive leases and complete reset/version
   checks; a context cannot be used by two tasks. Start simple before pooling.
4. **Results carry identity and freshness.** Include job ID, expedition epoch,
   generation/settings fingerprint, coordinates or entity IDs, relevant state and
   content revisions, result schema, and requested logical tick where applicable.
   Camera origin is a presentation input, not generated identity.
5. **Stale work cannot commit.** Load/new expedition invalidates the old epoch;
   changes to relevant content, terrain, entities or combat reservations invalidate
   dependent results. Validate again immediately before commit. Use scoped
   revisions where appropriate so unrelated movement cannot starve every job.
6. **Scheduling cannot change rules.** Derive random streams from existing stable
   identities/seeds and explicit domains, never worker ID, wall time or completion
   order. Preserve existing iteration/tie-breaking and floating-point order where
   it affects results. Do not silently accept changed generation under the same
   version. Define equivalence scope across engine/platform versions explicitly.
7. **Only short handoff locks.** Protect task status, cancellation and mailbox
   transfer. Never hold a lock while generating terrain, performing file I/O,
   waiting for tasks, invoking callbacks, or accessing rendering. No global lock
   around the existing world generator.
8. **No unbounded submission.** Cap queued jobs, running jobs, completed results,
   publication backlog, resident contexts, retained assets and total estimated
   bytes. Reserve input plus worst-case output/scratch capacity before dispatch.
   Bound caches across contexts, not merely within each copied cache.
9. **No worker waits on another worker.** Resolve dependencies before dispatch;
   the coordinator advances the dependency graph. Do not saturate the pool with
   tasks waiting for work that needs the same pool. Reject dependency cycles.
10. **No normal-frame wait for unfinished jobs.** Poll completion, collect/reap
    completed tasks exactly once, and publish within budget. All pool task IDs,
    including canceled/discarded work, must eventually be waited/reaped to release
    task resources. Shutdown is a deliberate bounded drain, not routine gameplay.
11. **Cancellation is cooperative.** Use synchronized cancellation state and
    bounded checkpoints. Canceling a consumer does not invalidate another
    consumer's shared dependency. Keep inputs alive until execution has ended.
    A timeout does not prove a task stopped; never free its inputs or force-kill it.
12. **Single-thread execution remains available.** Run the same extracted jobs and
    commit path inline/cooperatively with workers disabled. Do not maintain two
    independent generators. This supports comparison, constrained machines and
    diagnosis without forking gameplay behavior.

GDScript does not enforce recursive immutability for arbitrary job records. Use
constrained schemas, boundary validation and debug assertions, with explicit
ownership transfer. Locks are not a substitute for those boundaries.

## System coverage

Every system adopts the ownership/lifecycle contract. Only measured expensive
work receives a background executor.

| Domain | Candidate worker work | Work retained with the current main-thread owner | Required admission rule |
| --- | --- | --- | --- |
| Geographic generation | Heights, drainage, road candidates/admission, community candidates, canonical cell records | Installing generated results and handling immediate traversal queries | Complete dependency halo, same captured generation inputs and canonical access |
| Scenery and grass | Placement records, mesh arrays, MultiMesh buffers, CPU picking structures | Resource/material mutation, GPU submissions, nodes, animation buffers and picking installation | Same terrain/content/placement revision; renderer consumes admitted plants |
| Resource loading | Engine threaded loading of selected baked assets/scenes | Catalog admission, shared resource changes and scene instantiation/publication | Central path deduplication, retained references and content revision |
| Flora/Vastra/Vessels | First: neighbor/spatial queries and visual path preparation; later: measured pure proposals | Registration, reserves, conserved packets, repair payment, clock and ecology transactions | Exact canonical IDs, current reservations, revisions and conservation |
| Wild and owned Sols | Bounded navigation/behavior proposals on copied occupancy and traversal data | Current movement/occupancy admission, identity, ownership, player interactions and model transforms | Recheck target, footprint, occupancy, encounter/selection and command serial |
| Combat | Optional expensive AI evaluation or preview calculations | Readiness gates, event ordering, aim, AP/uses, impacts, tile reservations and outcomes | Current battle/plan serial; stable tie order and exactly-once receipts |
| Persistence | Encoding, isolated parsing/validation, ordered disk writes | Capturing coherent state and atomically installing a fully admitted candidate | Snapshot sequence, destination ownership and load-request freshness |
| Weather/day/night | Only measured expensive geography/exposure field preparation | Saved-clock decisions, transitions, light/sky parameters and audio controls | Correct clock/settings; no worker-created gameplay weather rules |
| UI/input/camera/audio | Optional expensive detached list/search preparation | Input, UI nodes, camera, audio playback/routing and direct feedback | Current selection/view request; coalesce obsolete derived results |
| Labs/authoring | Expensive mesh-data/bake previews on detached recipes | Sliders, scene/resource editing, library admission and expedition suspension | Separate lab scope/revision; no expedition writes or clock advance |
| Physics/rendering internals | Evaluate existing engine facilities only if measured necessary | Keep current engine settings during initial migration | Separate evidence for changing physics/rendering thread modes |

`SolLocalNavigation` is a custom bounded BFS, not a NavigationServer query. Preserve
its traversal/tie-breaking contract; switching navigation engines is not a required
part of concurrency. Likewise, GPU particles and engine audio/rendering work do
not become faster merely by adding game-side threads.

## Queueing, budgets and gameplay under load

Use separate logical priority lanes in one coordinator: required current-area data,
nearby canonical flora, visible coverage, visible detail, predicted travel, then
optional previews/background work. Reserve service for canonical simulation
dependencies so rapid camera movement cannot starve registration. Age eligible
work to prevent starvation; prioritize dependencies that unblock higher lanes.

Deduplicate by domain, coordinates/identity and input fingerprint. Track consumers
so a camera turn does not throw away work still needed by traversal or flora.
Coalesce replaceable previews, limit speculative distance, and stop dispatch when
the completed-result/publication queue approaches its byte cap. Bound publication
and retirement as well as computation; fast workers must not create a main-thread
completion storm. No task per grass blade, no thread per creature.

Traversal may read a prepared canonical neighborhood. If required data is absent,
use a bounded exact query through the same generation authority where proven safe;
otherwise retain the last valid position while required work is prioritized. Do
not guess walkability, authorize movement from coarse visual ground, or allow
worker lateness to invalidate capture/combat rules. This exceptional wait must be
instrumented and avoided in normal travel by measured lookahead. Do not discard
movement delta or simulation time as a hidden optimization.

Proposed initial tuning for the first experiment: one application CPU job in
flight, then compare two and four; keep a serial mode. Do not set worker count from
logical-core count alone or consume all cores. Include engine loading/render work,
input latency, memory and low-core behavior in that choice.

MT0 must record explicit performance and memory targets before enablement. A
60 FPS desktop study has a 16.67 ms total frame interval; the current 3 ms stream
slice and separate retirement allowance are only part of it. Treat a shared 4 ms optional main-thread preparation/
publication/retirement allowance as a starting experiment, not a hard guarantee or
approved platform budget. Snapshot capture, state commits and unavoidable GPU
calls must be measured separately and included in total frame accounting. Report
p50/p95/p99, worst frame, counts above 33.3/50 ms, oldest job and time-to-detail.

## Delivery sequence and gates

Owner requirement, October 31, 2026: when implementation begins, create a new
isolated Git branch with the `codex/` prefix, such as
`codex/runtime-concurrency`. Do not implement this roadmap on the existing active
feature branch. Follow the project standard to verify the integration base; use a
separate worktree when the current checkout contains unrelated or concurrent work.
Preserve all existing changes and bring dependencies into the isolated branch
deliberately. Recording this plan does not itself start implementation or create
that branch.

Each phase is a bounded reviewable change on `codex/` work, following the existing
standard. Preserve the dirty checkout and coordinate shared-file ownership before
implementation. Do not merge unrelated active combat, plant, terrain or art edits
into a concurrency change. Use one evidence index under ignored
`artifacts/concurrency/`, with exact revisions, settings and commands.

### Reassessed order — October 31, 2026

Cold loading, travel hitches and delayed detail are separate acceptance workloads.
Address them within this roadmap rather than building a temporary second generator.
The execution order is: isolate and pin the baseline; measure each workload; fix
its largest confirmed stall; extract equivalent serial calculations and bound
publication; then trial workers only for a remaining measured CPU bottleneck.
Startup staging and publication/cleanup limits begin in MT1, before real generation
is dispatched in MT3. MT4 and MT5 complete and integrate those foundations rather
than postponing their first implementation until after threading.

The matching bake is not evidence that it needs rebuilding. Validate it against
the frozen inputs and preserve it unless those inputs require a new bake. Prefetch
only dependencies justified by the measured player-area workload; loading the
whole palette upfront can worsen startup and memory. A faster first frame is not
acceptance if canonical access, visible coverage or nearby detail remains delayed.

### MT0 — Freeze a useful baseline and classify stalls

- Pin the actual integrated runtime, settings, species/catalog inputs, baked
  palette and local asset availability. Classify existing failures; do not call a
  known-failing baseline a pass or quietly weaken checks.
- Audit the transitive read/write sets of every candidate: caches, static resource
  stores, signals, callbacks, RNG, allocations, file access and scene/GPU calls.
  Mark each operation main-owned, exclusively task-owned or explicitly immutable.
- Extend existing profiling rather than inventing a second benchmark suite. Add
  queue wait, snapshot cost/bytes, CPU compute, handoff, validation/commit,
  publication/upload, retirement and pipeline-compilation observations.
- Capture at least three comparable fresh-process serial runs, capped and uncapped,
  plus warm return travel. Retain raw frame sequences, source hashes, engine,
  renderer, driver, resolution, hardware and cache policy. Physically cold driver/
  disk caches are a separate labeled experiment, not implied by a fresh process.
- Measure startup through first usable player area and nearby-detail readiness,
  then active travel with normal simulation, movement and flora admission enabled.
  Include a populated flora save. Keep smoke-mode loading samples separate from
  gameplay evidence; capture resource misses, coarse coverage, publication and
  retirement as well as CPU preparation. Do not interpret unexercised zero counters
  as a pass. Confirm which historical bottlenecks still exist on the pinned build.
- Freeze numeric frame, startup, coverage-latency, memory and queue-age targets from
  these workloads before judging later phases. Choose thresholds outside measured
  run-to-run noise; retain both absolute targets and paired relative results.

**Exit:** baseline is reproducible; expensive CPU work is distinguished from disk,
GPU, publication and simulation stalls; targets and dependency audit are recorded.
If GPU cost dominates a workload, pursue its measured rendering bottleneck rather
than claiming threading will fix it.

### MT1 — Address confirmed stalls and extract serial data boundaries

- Prioritize the largest measured stall, whether resource loading, startup,
  oversized CPU work, publication or cleanup. Remove demonstrated repeated work
  and first-use preparation before deciding that a worker is necessary.
- Begin staged startup now: separate bootstrap/progress UI, resource acquisition,
  terrain/access validation, player-area readiness, initial ground and optional
  detail. Yield between bounded stages while retaining canonical access checks.
  Avoid a bootstrap dependency graph that synchronously loads the entire game.
  MT4/MT5 add asynchronous acquisition and transition integration where justified.
- Establish bounded main-thread publication and retirement in the serial path.
  Include coarse-ground CPU preparation, state admission and cleanup measurements;
  reduce oversized units where possible and record indivisible GPU operations.
  Prove that coverage survives staged replacement before worker completion bursts
  can reach this path. Do not merely lower an outer deadline around oversized work.
- Split generation evaluation from cache installation and scene publication. Use
  captured terrain parameters, canonical coordinate keys and data-only results.
- Separate expensive `WorldTerrain` initialization/site planning from reusable
  evaluation contexts. Do not construct a whole new world and load its resource
  graph for every chunk. Preserve existing bootstrap order and route/site
  dependencies; identify cycles before parallelizing them.
- Extract chunk preparation from `SolidChunk` without changing output: vertices,
  normals, blends, transforms/colors, model keys, picking data and organ/source
  records. Keep material/node creation with presentation.
- Define shared immutable geographic blocks and exact halos from actual road,
  drainage, community spacing and plant-footprint queries. Avoid one unexplained
  fixed margin copied into terrain, flora and scenery separately.
- Retain current baked models and authored-library priority. Workers use immutable
  model descriptors; they do not race static plant/material/picking caches.

**Exit:** the extracted serial path matches canonical cells, access, site layout,
living-source IDs, organ anchors, cosmetic placements, geometry and save behavior.
No generation-version bump is used to conceal an accidental behavior change.
Startup stages and publication/retirement limits are exercised in rendered serial
play, with residual overruns and time-to-detail recorded. These improvements stand
on their own even if measurement does not justify enabling workers.

### MT2 — Prove the task coordinator independently

- Implement finite jobs, a synchronized bounded mailbox, input/result validation,
  epoch and scoped revision checks, cooperative cancellation and exact-once task
  collection. Register all in-flight handles centrally, including abandoned jobs.
- Introduce serial and worker executors using the same computation and commits.
  Give each domain an independent rollout switch. Snapshot capture is bounded;
  copying the entire expedition every frame is prohibited.
- Test dependencies, queue capacity, byte reservations, priorities, fairness,
  duplicate requests and context lifetime with controlled tasks before real terrain.
- Exercise randomized/reversed completion order, cancellation before/during/after
  compute, stale results, duplicate delivery, invalid output and teardown. Inject
  controlled failures, not thread-unsafe accesses or deliberately hung engine code.

**Exit:** no stale/duplicate commit, leaked task ID, queue overrun, dependency
deadlock or use-after-free in the lifecycle matrix. Serial fallback is demonstrable.
Controlled completion bursts also exercise MT1's bounded publication path before
real generation jobs are admitted.

### MT3 — Ship the first world-generation vertical slice

- Enter the worker experiment only if the post-MT1 baseline still identifies a
  material CPU preparation bottleneck. If I/O, GPU or publication dominates, address
  that measured cause first and record worker enablement as deferred. The data
  contracts remain useful; running threads is not itself an acceptance criterion.
- Begin with one high-cost data-only geographic stage identified in MT0, then
  include its road/drainage/community and cell-record dependencies. Dispatch only
  independent blocks; publish complete blocks through the generation authority.
- Share ready canonical records among traversal, flora and renderer. Preserve
  independent lifetime/priority: camera visibility cannot decide flora membership.
- Test coordinates around zero, negative coordinates, district/chunk boundaries,
  wetland edges and maximum supported settings/footprints. Evict and regenerate
  blocks in different orders to prove stable reconstruction.
- Compare serial, one-, two- and four-job execution. Count repeated halo work and
  context/cache memory; more tasks must not multiply total work enough to erase
  latency gains. Increase concurrency only after measured improvement.
  Compare total workload time, memory, input latency and time-to-detail as well as
  main-thread stalls; moving work off-thread can otherwise disguise a net slowdown.

**Exit:** matched generation/access results across scheduling orders, bounded
memory, no required-data starvation, and reduced measured main-thread stalls with
no meaningful end-to-end regression. Keep workers off by default until this gate.

### MT4 — Complete scenery preparation and controlled publication

- Extend the serial publication/coverage safeguards proven in MT1 and the burst
  tests from MT2. This phase does not introduce those safeguards for the first time.
- Move the extracted heavy grass/placement/mesh-buffer/picking calculations to
  tasks. Resolve required baked asset keys ahead of publication through a central
  asset request owner; deduplicate requests and retain the completed resources.
- Use threaded loading status checks; retrieve only completed resources during
  normal frames. Resource loading completion is not scene/GPU readiness.
- Publish meshes, MultiMeshes, materials, organ/picking data and nodes on the main
  thread in bounded pieces. Keep canonical source records and animation/reserve
  consumers consistent when the chunk becomes visible.
- Retain coarse ground until replacement is complete. Split CPU preparation of
  coarse coverage too; otherwise fallback coverage remains a source of hitches.
- Measure atomic uploads and render pipeline compilation. Prepare representative
  production features/material combinations during loading; do not warm every
  asset in the project. Separate pipeline stalls from CPU generation in reports.
- Cap per-frame retirement and bytes, not just retired chunk count. Avoid
  repeated full-instance-buffer writes and worker overwrites of animated buffers.

**Exit:** rendered geometry, colors, picking, flora endpoints, grass and animation
match; no gaps at replacement; completed-result bursts stay within memory and
publication budgets. Residual atomic GPU overruns are measured and addressed
through batch size/loading strategy rather than hidden by CPU-only timings.

### MT5 — Make startup, save/load and world transitions safe

- Complete the startup staging begun in MT1 with bootstrap UI, threaded resources,
  isolated terrain admission,
  player-area canonical readiness, ground publication and optional surrounding
  detail. Do not preload the full game through the bootstrap scene's dependencies.
  Display actual stages/progress and keep essential access validation intact.
- Capture a coherent versioned save snapshot on the state owner at a transaction
  boundary. Never encode a live mutable dictionary in the background. If copying
  becomes expensive, use versioned immutable blocks or staged validated capture;
  copying while gameplay mutates the source is not a coherent save.
- Serialize and write detached snapshots through one ordered writer per path.
  Assign snapshot sequence numbers so older saves cannot overwrite newer ones.
  Preserve size/schema/admission checks, temporary write, backup and replacement.
  Report success only after final replacement succeeds; preserve existing saves on
  failure and test actual Windows file replacement behavior.
- Worker validation uses an isolated admitted terrain/context, never the live
  `terrain_hint`. Keep exact candidate reuse within that exclusive context. Move
  restore operations only after their Resource/static-cache/signal audit; otherwise
  stage their main-owned portion. Validate all flora, roaming and player data.
- Keep the current expedition until a candidate is fully admitted and ready to
  install. Load/new expedition establishes a transition barrier for authoritative
  commits, then changes the epoch; failed admission keeps the old world usable.
  Check the latest load-request ID before installation. Settle outstanding save
  writes explicitly before a conflicting load; do not race two file owners.
- Suspend authoritative expedition publication during F8/F9 labs and true pause.
  Detached generation may finish into capped queues; it cannot advance time or
  mutate a suspended expedition. Lab previews use separate scope/revision IDs.
- On shutdown stop admission, signal cancellation, settle/reap finite tasks and
  release resources in ownership order. A watchdog reports a stuck task and
  disables further work; it cannot safely terminate an arbitrary running thread.

**Exit:** responsive staged startup; save errors do not corrupt the last complete
save; old jobs cannot affect a new/loaded world or lab; every handle is cleaned up.
Explicit pause, lab suspension and save guards preserve their current contracts.

### MT6 — Extend to measured game-system workloads

This is selective enablement, not a requirement to thread every system.

1. **Visual consumers:** detach expensive Vastra route/spatial calculations. Use
   immutable transfer IDs, organ graphs and clocks. Publish only current results;
   visual lateness cannot mint reserves or alter packet arrivals. Keep existing
   filament/GPU particle consumers and resource ownership intact.
2. **Navigation and behavior:** compute proposals over immutable local traversal,
   occupancy and policy data. Recheck legal steps, footprint, target and ownership
   immediately before movement. Apply conflicting proposals in stable domain order,
   not completion order. Do not use a live-world `can_step` Callable in workers.
3. **Ecology:** parallelize expensive pure preparation only after measuring the
   previous items. Keep reserve debits/credits, packet IDs, repair payment and
   tile writes in existing transactions. Cross-region transfers use a deterministic
   merge with conservation checks, not independent region writes.
4. **Combat previews/AI:** only if measured expensive, and after readiness integration
   is stable. Worker suggestions cannot commit plans, spend uses/AP, move targets,
   emit impacts, alter attempt-indexed RNG, or bypass combat tile reservations.
5. **Weather/audio/UI:** keep cheap coordination on the main thread. Thread only
   isolated expensive preparation if MT0 or later evidence identifies it. Future
   planned weather or relic features inherit this contract when implemented.

Authoritative computation must preserve existing logical tick/event order. A result
cannot simply be applied whenever it finishes. Capture the tick and dependencies;
commit in domain order at a defined boundary, revalidate/recompute stale proposals,
and retain an equivalent bounded serial path. If readiness of a result changes
gameplay, do not enable it until a scheduling-independent protocol is proven.
Do not drop ticks, invent a simulation rate or accumulate forbidden combat-recovery
debt to meet a frame target. Broad global revisions that invalidate every result
on every tick must be replaced by relevant read-set revisions or smaller jobs.

**Exit per subsystem:** equal gameplay event/state traces for the same inputs and
logical time under altered scheduling; correct current-state reconciliation; a
measured benefit exceeding dispatch/snapshot/commit overhead. Otherwise keep the
contract and leave the workload serial. A dedicated simulation thread is a later
architecture decision only if these measures leave a demonstrated bottleneck.

### MT7 — Integrated qualification and default enablement

Run correctness gates and matched rendered performance studies on the same pinned
inputs. Keep frame caps, route, graphics, density and camera behavior identical.
Test fresh processes and warmed travel separately; headless timing does not prove
rendered performance. Include a capped-worker/low-core study, and obtain real
lower-core hardware evidence before claiming that hardware is supported. Thor
acceptance remains a separate later project gate.

Required matrix:

| Scenario | What must be demonstrated |
| --- | --- |
| Cold startup and populated save | Responsive staging, valid player area, exact admission, bounded memory |
| Sprint into unseen districts/biomes | Canonical lookahead, no guessed collision, bounded queue age |
| Fast camera orbit/zoom/reversal | Coarse coverage, retained-cache reuse, no speculative backlog explosion |
| Return travel and forced cache eviction | Stable reconstruction, identical negative-coordinate behavior |
| Pause/unpause and F8/F9 round trips | No suspended-world mutations, no time catch-up introduced |
| Combat planning/execution/replacement/outcome | Local reservation protection, surrounding world continuity, once-only effects |
| Capture/transfer/despawn while AI work runs | Stale identity/command results rejected; current occupancy rechecked |
| Plant circulation/repair across region boundaries | Canonical membership, exact endpoints and conserved reserves/packets |
| Rapid new/load/save requests and quit during work | Ordered disk writes, latest admitted transition only, no leaked handles |
| Plant-library/settings revision during work | Dependent invalidation, no old art/placement installed afterward |
| Resource failure, malformed result, full queues | Safe refusal/fallback, retained valid world, useful diagnostics |
| Long repeated travel/lab/load cycles | Memory reaches a bounded plateau; no growing result/context/task backlog |

Reuse `world_generation`, `terrain_heightfield`, `terrain_geography`,
`plant_community_integration`, `wetland_query_cache`, `bottleneck_regressions`,
`loading_regressions`, `stutter_regressions`, `save_terrain_reuse`,
`persistent_foundation`, `readiness_expedition`, `combat_world_continuity`,
`sol_wandering` and `development_world_toggle` where their contracts apply. Add
focused concurrency fault/order/lifetime tests where existing suites lack coverage.
Use controlled barriers for ordering tests; wall-clock sleeps are not correctness
proof. Retain Godot thread-safety checks and assert execution ownership in debug.

Each code slice runs relevant checks and import/parse validation. Shared-contract
and final integration changes run the configured validator unchanged. A known
baseline failure is tracked with its owner and reproducer; a new relevant failure
blocks enablement. Final acceptance requires the shared integration gate, a
rendered journey and owner review, not just isolated worker tests.

**Enablement rule:** correctness/lifecycle gates pass, frozen performance/memory
targets are met, benefits are larger than observed noise, and startup, input
latency, warm travel and lower-concurrency modes have no unexplained regressions.
Publish the remaining stalls and limitations. Roll out by subsystem switch;
disable only the offending worker path using the same serial computation if it
regresses. Do not silently retry forever, disguise missing results as empty terrain,
or describe a partially passing build as complete.

### MT8 — Establish the ongoing contribution contract

After the vertical slice proves the design, record adopted rules once in the
existing project standard and update its script-ownership map and Inspector map as
needed. Until adoption, this roadmap remains a proposal, not a competing workflow.
Every new expensive system must identify:

- its authoritative owner and execution context;
- its input/output schemas, bounded read set and invalidation dependencies;
- its determinism, RNG, tick/event and commit rules;
- its queue, scratch/result/cache memory and main-thread publication budgets;
- its cancellation, failure, pause, world-switch, save and shutdown behavior;
- its serial path and evidence that a worker is worth the overhead;
- its relevant tests, representative workload and remaining platform limitations.

Add shared core infrastructure only when demonstrated by multiple consumers. Keep
domain generation, combat, ecology and persistence decisions in their existing
modules. Do not introduce an ECS rewrite, new job framework dependency, native-code
migration, physics redesign or navigation replacement without separate evidence.

**Exit:** world-generation groundwork is enabled and reviewable; all domains have
an explicit threading decision; future features inherit tested boundaries. Systems
that remain serial are documented decisions, not unfinished mandatory migrations.

## Evidence and engine references

Existing evidence entry points: `tools/profile_loading.gd`,
`tools/profile_bottlenecks.gd`, `tools/profile_current_expedition.ps1`,
`tools/profile_current_expedition.gd`, `tools/profile_wetland_cache.gd` and
`docs/runtime-optimization.md`. The new index should record per-phase status,
commands, source/configuration hashes, correctness results, frame distributions,
queue/memory behavior and residual risks. Calendar estimates follow MT3's measured
delivery effort; this plan does not invent an end date.

Official references checked for this plan:

- [Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html):
  active-tree access and shared resource mutation require care. The conservative
  data-only worker boundary above is a project proposal built around those limits.
- [WorkerThreadPool](https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html):
  finite tasks and completion handling; small tasks may lose performance to overhead.
- [Background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html):
  poll threaded-load status before retrieving; retrieving an unfinished load blocks.
- [Pipeline compilation](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html):
  use compilation monitors and representative loading-time rendering features to
  distinguish pipeline stalls from CPU computation.

These documentation URLs track stable Godot. Confirm the APIs and behavior against
the repository's pinned 4.7.2 binary during MT0/MT2. Do not change engine settings or
disable thread-safety checks merely to make an initial worker experiment run.
