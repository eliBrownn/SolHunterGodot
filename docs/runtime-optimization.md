# Runtime optimization

## Owner play feedback — November 2, 2026

The owner reports the changes are good and gameplay feels smoother. Full judgment
and additional notes are deferred until these improvements are combined with the
other development work. Preserve the measured receipts below; this feedback does
not establish a causal gain from any individual change or combined-build acceptance.

## Public combined gameplay candidate — November 2, 2026

The owner requested combining the gameplay and optimization work before fuller
play judgment, then explicitly prioritized gameplay features and optimization.
An isolated `codex/combined-development` snapshot starts from verified `origin/main`
`ac656ce`; existing local branches and pending owner Bible/story edits remain intact.
It combines the existing connected gameplay, readiness combat, world/ecology and
optimization implementation for review. No merge or new roadmap acceptance is implied.

The supplied human, rogue animations and sky source remain local by explicit owner
direction. The public/default player uses the original 3,104-triangle base and
existing shared terrain gait; an optional local-source export retains the workstation
adapter. An original sky shader and authored FastNoiseLite resources reuse the
existing atmosphere interface. No supplied sky code/presets enter this candidate.

Fresh candidate validation, with the withheld bundles and other ignored local packs
absent, passed Godot 4.7.2 import; the rendered character scale/skin/animation bridge
check; **50 atmosphere**, **17 readiness expedition**, and **11 startup gate** checks.
All finished with native exit 0 and no engine/script errors. The startup fixture
completed 64 chunks for new and loaded expeditions and checked save/load/clock gates.
The first atmosphere run exposed an old >90% fog assertion; corrected it to the
approved active view's 85% policy without changing runtime behavior. Its intentional
invalid-settings probe still emits its expected warning. D3D12 was selected explicitly
for rendered checks; an initial automatic-driver character pilot logged a Vulkan
availability error before successfully falling back, and is not the clean receipt.
Initial unisolated editor validation also could not write profile data; the clean
import/tests use isolated writable preferences and saves.

Structure audit: **223 mapped scripts, 223 unique UIDs, zero failures**. Verified the
existing literal-reference matcher rejects a temporary missing-script probe. The normal validator now runs the ownership check before engine suites.
Reviewed explicit candidate paths omit withheld sources, Python caches, local review
artifacts and pending Bible/story changes. No candidate file exceeds 50 MiB; retained
vendor notices/generated source whitespace is not reformatted during integration.
Local evidence is under `artifacts/publication-review/`.

The earlier 9,391-check/journey receipt below covers its recorded source/assets.
Core optimization evidence remains useful, but replacing player/sky and omitting
local grass/VFX/plant packs changes rendered content: the earlier frame numbers
are **not** a benchmark of this public candidate. The complete configured validator,
remote CI, owner combined-build play review and device acceptance remain separate.

## Combined improvements: startup, correctness and rendered journey

Owner explicitly requested testing the accumulated improvements. Six relevant
headless suites plus the complete startup new/save/load fixture passed **9,391
checks**, with zero engine/script errors and native exit 0. This is focused
combined-build validation, not the entire configured validator.

| Suite | Passing checks |
| --- | ---: |
| Terrain materials: 512px, no normal/parallax maps | 4,900 |
| Wildlife admission/revisit preparation | 28 |
| Shared vegetation visual queue | 3,127 |
| Plant Vastra conservation and presentation | 1,013 |
| Vastra currents, staging and smoothing reuse | 295 |
| Production readiness expedition | 17 |
| Full startup new/save/load gate | 11 |

The startup fixture completed 64 chunks for both new and loaded expeditions,
registration ordering, saved-clock freezing/restoration and gameplay release.
Headless execution skips GPU warm-up; the separate rendered journey below includes
actual visible loading preparation.

**One integrated rendered journey passed**, native exit 0, empty engine/script
error log, and unchanged runtime/source hashes before/after. Godot
4.7.2.stable.official.ed1daf0bf, D3D12 Forward+, RTX 3070, 2560×1369, seed 2601026,
60 FPS cap with VSync. Fresh isolated preferences/saves; OS/driver caches retained.
It used the existing input-action travel/inspection/menu/encounter/readiness driver,
with only its test entry adapted to await the real startup menu's 64-chunk and
render preparation barrier. Production scripts were not instrumented or modified.
The normal live world was retained: no smoke mode, teleports, artificial HP/RNG,
simulation-speed changes or population reductions. The authored opponent was
`2601026:6:4:sol_species_0018`.

Initial menu-to-admitted-world loading was **67.090 seconds**. The gameplay record
contains **7,429 accepted frames** (7,627 raw collector rows): **59.37 FPS** average
throughput, **16.665 ms median**, **20.327 ms p95**, **34.916 ms p99**, **56.653 ms
worst**. There were **3 frames >50 ms**, **95 >33.4 ms**, and **0 >100 ms** in those
accepted windows. Existing reporting excludes warm-up, route-planning,
screenshot/checkpoint writes, finish and phase-boundary frames. Capture-boundary
intervals reached 976.744 ms because synchronous image/checkpoint I/O is part of
the test driver; those are retained in raw data, not silently treated as gameplay
or used to attribute a production hitch.

| Gameplay phase | p95 ms | Worst ms | Frames >50 ms |
| --- | ---: | ---: | ---: |
| Outbound travel | 20.612 | 46.470 | 0 |
| Return travel | 20.428 | 52.322 | 2 |
| Negative-coordinate sprint | 20.236 | 39.357 | 0 |
| Negative return | 20.968 | 38.931 | 0 |
| Camera orbit | 17.802 | 36.304 | 0 |
| Inspection | 16.691 | 44.625 | 0 |
| Live Sol menu | 16.688 | 38.211 | 0 |
| Combat approach | 16.713 | 39.336 | 0 |
| Readiness planning | 16.702 | 33.004 | 0 |
| Combat execution | 23.403 | 56.653 | 1 |
| After execution | 16.683 | 28.180 | 0 |

Pipeline coverage remains incomplete. Draw compilations rose from **35 to 46**
after loading: 1 during warm-up, 2 outbound, 2 during an orbit boundary, 3 in the
live menu and 3 at combat entry. Mesh/surface counters stayed **51/62** across the
collector window; specializations rose **49 to 60**. The counter-change intervals
were not the three worst accepted frames, and delayed monitor reporting prevents
attributing exact costs. The earlier targeted feedback/creature zero-increment
check remains valid for its samples; it does not imply zero new pipelines for a
full journey. There was no reproduced one-second first-hit pause in accepted
combat windows. First-use menu/entry variants remain a concrete follow-up.

This is one current-build observation, **not a matched before/after speedup**.
Earlier baselines bypassed the real 64-chunk menu and used different camera,
terrain and presentation inputs. Do not compare their initial loading time or
subtract their frame metrics to claim an improvement from an individual change.
Screenshots of populated entry and combat were inspected for visibility/readability;
this is not owner visual acceptance of every plant or terrain transition.

Evidence lives in `artifacts/combined-improvements-test/`: `suites.json`, per-suite
logs, `startup.log`, `journey.log`, `journey/profile.json`, `summary.json`,
`pipeline-events.json`, source guards and captures. The first isolated-copy setup
was rejected by Windows when it could not create the asset junction; that unused
partial copy remains a rejected setup, not a game failure. The successful journey
used guarded active sources instead; hashes matched before/after. The process
memory sampler returned figures inconsistent with the engine's own static-memory
monitor, so its `process.json` values are unqualified instrumentation evidence,
not a claimed memory reduction or actual game working-set measurement. No extra
run was commissioned merely to repair that optional metric.

No gameplay/runtime changes were made by this testing pass. No broad validator,
export, repeated timing campaign, physically cold driver-cache or target-device
qualification was run. Existing editor safe-save import limitations retain their
prior status; the passing suites and journey do not certify a clean editor import.

## Vastra smoothing reuse and visible loading preparation — follow-up 4–5

Owner confirmed continuing the earlier Vastra-rebuild and first-use-rendering
items. This extends the already integrated shared visual queue, source-revision
cache, staged packet paths and hit-flash material fix; it does not restart those
investigations or change the nature-loop delivery sequence.

**Vastra:** cubic smoothing still rebuilt and terrain-sampled unchanged paths on
each replacement. A 256-entry FIFO derived cache now retains the exact smoothed
samples. Keys include every input point, root-flow mode, requested sample limit,
ground clearance and height-sampling host identity. Terrain identity changes and
world rebuilds discard the cache. Returned arrays isolate callers; storage remains
bounded during churn. Shared junction accounting still runs for every actual
packet and was not bypassed by this geometry cache. Existing publication budgets,
conserved transfers, clock, plant state and optical endpoints are unchanged.
Snapshot/filter selection, legacy ribbon construction and GPU publication still
have synchronous portions; this is targeted reuse, not a hard bound on every
Vastra rendering operation.

**Rendering:** after the existing 64-chunk and canonical registration stages, the
startup menu now performs real draws behind its opaque overlay before gameplay
is enabled. A disposable process-disabled sample tree uses the active world,
camera and viewport. The existing feedback builder supplies numeric/outlined
text, pulse sprites, Vastra ribbons and the installed emitting distortion effect;
the same species factory supplies only the measured Sailcrest and Glass-Throat
variants. Feedback samples draw for 12 frames and each creature for 8 frames.
Samples are placed in front of the current camera to avoid frustum rejection.
No gameplay cue is received, no tactical session/identity is created, and the
existing saved-clock/loading barrier remains in charge. Sample trees are freed
before entry; headless mode skips the GPU stage. Direct F6 fixtures still bypass
the startup menu. This spends additional loading frames and transient graphics
resources to move first-use work out of gameplay; it is not a portable driver
cache or exhaustive warm-up of every future effect/graphics configuration.

Focused Godot 4.7.2 results: final isolated Vastra staging/reuse **50** checks;
full Vastra currents **294** checks before the final added reuse assertion;
headless loading lifecycle **12** checks. Curve tests compare the unchanged
original calculation, root/non-root paths and sample limits; cover caller mutation,
clearance/terrain invalidation and FIFO turnover; and verify no new smoothing
builds for an unchanged replacement while retaining identical junction totals.

One D3D12 Forward+/RTX 3070 loading check passed **15** assertions with native exit
0 and no engine/script errors. Mesh/surface/draw/specialization counters were
**51/56/32/45** after visible loading, remained **51/56/32/45** after both creature
variants were recreated, and remained **51/56/32/45** after live feedback samples.
No additional pipeline compilations were observed in those windows. The complete
expedition snapshot stayed identical and no battle started. Inspected captures
show the opaque overlay covering preparation and normal feedback after that
fixture overlay is dismissed. This uses a direct gameplay fixture injected into
the real menu preparation method: it verifies that stage and its resource cleanup,
not a rerun of the complete 64-chunk new/save startup journey. Driver/OS caches
were retained; counter delays and the narrow sample prevent a no-hitch/FPS or
whole-game coverage claim. A pilot had an untyped fixture variable; the corrected
runs supersede it.

Final script ownership passed **223 scripts / 223 UIDs**, and scoped whitespace
checks passed. Editor import completed without script/parse errors but retained
the existing editor safe-save permission error; this is not a clean import under
the shared validator's strict error rule.

Pre-edit sources, logs, captures and scoped diffs are under
`artifacts/vastra-loading-followup/`. The prior full startup receipts remain
applicable to unchanged canonical admission; the startup fixture now also requires
render preparation to finish before entry. No repeated journey, broad validator,
export or target-device run was performed. Work remains uncommitted on the
existing codex branch, preserving earlier changes and the design Bible.

## Distant vegetation draw-call audit — step 3

Owner selected the third follow-up: inspect shared materials and distant tree
impostors after first-use rendering attribution. Read-only runtime audit; no
vegetation resources, material builders, visibility ranges, ecology or runtime
code were changed. Existing source and generation evidence were reused.

Existing work already addresses the obvious material-sharing proposals:

- `nature_art.compact_parts` groups static geometry by shared material and creates
  native LODs. The runtime plant bake additionally merges neutral tissue surfaces
  using vertex colors while retaining picking data and generating native LODs.
- Chunk publication uses MultiMeshes by asset/piece/tint/visibility group, rather
  than creating a separate scene node per living plant. Material/geometry owners
  are reused; reserve/custom-data links remain per canonical cell.
- Middle/far chunks already reduce native LOD bias and disable detailed shadows.
  Small vegetation stops at 32 cells while trees retain the 72-cell horizon.
  Neither another generic material cache nor another LOD toggle establishes a
  new draw-call reduction. Different geometry still needs separate batches.

A single bounded D3D12 Forward+/RTX 3070 sample used the direct gameplay scene,
180 preparation frames, then disabled processing to retain exactly the same
population while toggling presentation categories. It had only **one detailed
chunk**, with **47 chunks pending**, at **2560×1369**. This is explicitly a
starting-area screening fixture, not a fully prepared forest or a far-tier study.

| Admitted category | Instances | MultiMesh batches | Surfaces |
| --- | ---: | ---: | ---: |
| Detail | 18 | 18 | 18 |
| Grass/ground cover | 2,226 | 10 | 10 |
| Trees | 8 | 8 | 8 |

Those batches referenced 36 distinct meshes and 36 material identities. Different
material identities alone do not prove duplicate settings or safe mergeability.
Each tree in this sample occupied a separate single-instance batch. This points
toward representation/batch diversity as a candidate, not a missing cache.

Render counters averaged **583 calls** for the complete frozen sample, **548**
with detail hidden, **559** with trees hidden and **573** with grass hidden.
Restoring all categories returned to **583**. Windows used 12 settling and 12
sampled frames each; the complete persistent snapshot stayed unchanged, native
exit was 0 and the log had no engine/script errors. These marginal differences
include relevant rendering passes; they are not independent CPU/GPU timings,
whole-game savings, or a recommendation to remove vegetation. The prepared
palette's native LOD path is established by its owning code/earlier receipts;
absence of an optional LOD-count metadata field does not establish missing LODs.

The concrete next candidate is a **shared multi-angle tree atlas and shared quad
mesh**, batched per existing chunk for the far tier. One independent billboard
mesh/material per tree design would mostly reduce triangles while retaining the
batch split. Begin with a small representative authored-tree set before changing
the 153-entry prepared palette. A runtime pilot must retain original close/middle
models and switching continuity across camera orbit/height/return travel, actual
plant identity, reserve-condition data, terrain picking and clearance. Keep the
atlas selector separate from the existing four reserve-transition custom-data
channels. Silhouette, wind and lighting fidelity need visual review; no candidate
art or runtime impostor implementation was produced/accepted by this audit.

[Godot's MultiMesh guidance](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)
explains shared instanced drawing and the all-or-none culling tradeoff. Keeping
chunk ownership is preferable to one global vegetation batch. This is an
implementation direction, not evidence that impostors will improve this game's
far-forest frame time; the current one-chunk screen cannot settle that question.

Receipt: `artifacts/vegetation-draw-audit/results.json`, `run.log`, `probe.gd`,
`view.png` and `sources.json`. The capture preserves what was actually populated;
it is not full-world visual acceptance. No repeated journey, full validator,
asset rebake or target-device study ran. The existing dirty codex checkout and
design Bible are preserved. This investigation intentionally adds no speculative
runtime optimization or claimed FPS gain.

## First-use rendering attribution and impact material reuse

Owner selected step 2 of the remaining rendering investigation after the 512px
terrain change. One bounded D3D12 Forward+/RTX 3070 diagnostic used the direct
world scene, froze its processing after readiness, and retained normal rendering.
It separated hidden admission and first-visible windows of 16 frames each for
feedback components, then the 18 catalog species. A 48-frame initial settle and
quiet control preceded sampling; feedback components also had settled controls.
There were 50 windows, no engine/script errors and no changed expedition snapshot
or started battle. This is presentation attribution, not a normal gameplay journey.

| Isolated first use | Additional draw pipelines | Additional surface pipelines |
| --- | ---: | ---: |
| Floating combat text | 1 | 0 |
| Pulse sprite | 1 | 0 |
| Vastra feedback ribbon | 1 | 0 |
| Optional distortion particles | 1 | 0 |
| Crown-Ear hit flash | 4 | 7 |
| Sailcrest first display | 2 | 0 |
| Glass-Throat first display | 2 | 0 |

The quiet control and feedback settled windows had no counter increments. Hidden
admission windows had no increments in this already-loaded scene. The other 16
catalog species added no first-visible pipelines in this sequence; earlier
species may have warmed shared variants, so this is not independent cold-cache
qualification of every species. Counter reporting delays likewise limit exact
attribution. The old three-draw combined feedback sample and this four-component
sample are different sequences/settings and should not be treated as equal totals.

The hit-flash window contained a **1,014.215 ms** interval while the material
changed `emission_enabled` from false to true. That code changes a StandardMaterial
shader feature on first damage. The bounded fix enables the feature when each
body skin is constructed with black emission, and changes only the emission color
on impact/reset. Neutral body color, impact intensity, authored cores, affinity,
saved state and combat rules remain unchanged. Compilation is admitted with the
body rather than deliberately changing shader features during a hit; no claim is
made that total startup work disappears.

A separate narrow post-change rendered check sampled only Crown-Ear and its hit
flash: **zero** new mesh/surface/draw/specialization pipelines in the flash window,
zero control increments, unchanged saved state, native exit 0 and no errors.
This supports eliminating this runtime material-feature switch, not a numerical
whole-game hitch/FPS guarantee. Driver/OS caches were retained and no paired
repeated timing study was performed. Creature-model verification passed **96**
assertions, including zero neutral/reset emission and stable feature enablement.
The initial reset-color pilot compared alpha as well as RGB; corrected assertions
check emitted RGB because emission alpha does not represent emitted light.

Remaining targeted work is visible loading-time preparation for feedback's text,
sprite, ribbon and actual emitting distortion, and representative Sailcrest/
Glass-Throat drawing variants. Existing hidden startup admission alone did not
cover those first-visible draw cases in this sample. Any preparation should use
the active renderer/environment, preserve the startup barrier, and avoid showing
samples or consuming gameplay events. It should not instantiate every species
merely because the roster may grow. No such loading-time rendering change was
made by this slice.

Evidence: `artifacts/first-use-attribution/` contains the original ordered probe,
raw counters/frame intervals, pre-edit sources, focused final logs and the
post-change flash-only check. Reproduce the ordered diagnostic with the pinned
engine, `--path . --rendering-driver d3d12 --script
artifacts/first-use-attribution/probe.gd`; add `-- --flash-only` for the small
verification. These are local diagnostic fixtures, not a public asset package.
No broad validator, repeated journey, export or target-device qualification ran.
The current dirty codex checkout is preserved; nothing was staged, pushed or merged.

[Godot's official pipeline guidance](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
distinguishes potentially blocking draw/surface compilations from background
specialization and notes the limits of automatic hidden-instance preparation.
Its export shader baker handles intermediate shader code and does not replace
runtime pipeline preparation; export settings were therefore left unchanged.

## Terrain quality: 512px without bump maps — November 1, 2026

Owner selected 512px terrain textures with no bump mapping. The runtime color
array now retains all 13 grass/soil/rock layers at **512×512**, with mipmaps.
Original licensed 2K artwork is preserved. The existing bake tool builds color
only by default at 512px; `--with-relief` explicitly rebuilds optional normal and
displacement arrays too. No plant palette rebake is involved.

`NatureSettings` defaults normal-map strength and parallax relief depth to zero,
with both optional texture arrays unassigned, avoiding their runtime preload.
The shared terrain shader also defaults both strengths to zero; its existing
early-outs skip normal and displacement sampling. Detailed terrain and coarse
streaming ground use the same settings. Physical terrain shape, collision,
geographic materials, texture repeats, biome blends and ecological state retain
their existing owners. Optional maps require 13 layers before their corresponding
strength can be enabled; missing maps also force zero at material binding.

Focused Godot 4.7.2 terrain-material checks passed **4,900 assertions**, including
512px dimensions, absent default maps, safe binding and unchanged terrain/blends.
The palette bake and a short rendered scene check passed with D3D12
Forward+/RTX 3070 and no engine/script errors. The rendered check confirmed both
strengths are zero on detailed and streaming ground; its screenshot was inspected.
Pre-edit sources, verification logs and the capture are recorded under `artifacts/terrain-quality-512/`; this is a bounded material
change, not a measured whole-game FPS gain. No broad validator, repeated journey,
export or target-device qualification was performed.

## Gameplay hitch follow-up — November 1, 2026

Owner authorized removal of decorative Sol affinity effects and the admission,
ecology-preparation and Vastra-presentation follow-ups. Changes preserve the existing
64-chunk startup gate, deliberate generation policy and authored neutral visual
cores (Bible canon, independent of affinity). No new FPS result is established.

- Removed persistent affinity motes, aura geometry and quantum color cycling at
  their shared adapter. Ground shadows, actual affinity/UI palette, authored core
  art and combat impact flashes remain. Retired effect tuning is storage-only.
- Travel admission retains immediate canonical member/roaming records using hidden
  meshless adapters, then prepares at most one model or move book per frame under
  a shared default 1 ms cooperative allowance. Existing models are reused; initial
  startup and explicit full rebuilds retain immediate preparation. Departure prunes
  queued work; revisiting an existing identity requeues a missing book, and
  new/load discards old work. Battle admission prepares only
  its actual participants on demand, using a presence query that does not copy
  existing nested move books. Individual construction and canonical home
  discovery remain atomic; this does not establish a hard maximum admission time.
- Flora preparation combines ordinary/root held accounting in one flight traversal;
  retained incoming reservations accumulate during arrival processing in the same
  flight order. Fine refill and reserve displays share the existing tick/commit
  invalidated memo, now including incoming reservations. No simulation ticks,
  packet order, recipient selection or conservation rules are deferred or changed.
  Environment/Vessel transactions still run synchronously; this is work reuse,
  not completion of a frame-spread ecology scheduler.
- Stable published vegetation membership reuses anchor preparation, with explicit
  source revisions from the existing detached chunk-data owner. Chunk publication,
  source replacement/registration, camera/bounds/range changes and rebuilds invalidate
  it. Default filament paths prepare up to four packets per frame under a default
  1 ms cooperative allowance, retaining the previous complete network until atomic
  replacement. Dirty inputs cancel incomplete replacements; new state/rebuild clears
  prior paths and particle layers. Legacy ribbon, study and optional-light modes
  retain the immediate builder. Snapshot/filter selection and GPU layer admission
  remain synchronous; this does not budget every Vastra rendering operation.

Focused Godot 4.7.2 results: final admission **28**, creature models **93**, static Sol
presentation **238**, plant Vastra **1,013**, Vessel ecology **4,827** and Vastra
currents **278** checks passed before the additional prepared-data-identity guard;
its final focused staging fixture passed **34** checks. Affinity/battle presentation
also passed **14** checks. A separate frozen-original comparison matched
complete flora preparation outputs and untouched inputs across three seeds and
96 ticks each (**576 checks**), including paced/root packets, work limits, feeding
and repair. The rendered D3D12 Forward+/RTX 3070 admission run passed the same
**26** assertions with no engine/script errors; its inspected capture retains
species bodies, neutral cores and legible UI without colored orbiting motes. It
uses the direct gameplay fixture with streaming incomplete, not the startup gate
or a visual acceptance pass for the whole world. Incidental fixture timing output
is not a new performance comparison.

Pre-edit sources, focused logs, original-comparison fixture and capture live under
`artifacts/gameplay-hitch-followup/`. Initial pilots exposed a local signature-name
collision, a chunk-data indentation error, and an unparented fixture-node cleanup
leak; corrected runs supersede those pilots. One plant presentation checkpoint
needed to await the now-staged network; its energy/endpoint assertions remain.
The existing 24-cell Vastra range fixture now explicitly selects 24 rather than
implicitly assuming the newer production default of 38. Script ownership passed
**223 scripts / 223 UIDs**. Final editor import completed without script/parse
errors, but repeated the existing editor safe-save permission error; it is not a
clean import under the shared validator's strict error rule. No repeated rendered
journey, full validator, export,
target-device run or measured hitch/FPS reduction is claimed. Work remains
uncommitted on `codex/chunk-spiral-loading`, preserving the prior dirty checkout.

Owner also requested retaining the texture-quality finding: smaller world textures
can reduce texture memory/bandwidth, and disabling normal/bump maps can reduce
shading work. Existing distance-shader receipts support the shading direction,
not a measured saving from a current whole-game texture reduction. Neither change
addresses synchronous wildlife admission or ecology transactions. Keep this as a
separate visual-quality option; no texture assets or normal-map settings were
changed by this follow-up.

## Distance tiers and optional camera zoom — November 1, 2026

Owner requested applying near/middle/far presentation, adjusting zoom to the new
ranges, adding a zoom toggle and retaining gameplay Vastra visibility at 38 cells.
Default orbit distance is now 18 cells (was 22), with maximum 26 (was 40) and the
existing 2.5-cell close limit. Options exposes Camera Zoom; disabling it holds the
current distance and suppresses the shared wheel/controller dolly API. Orbit/tilt
and Home reset retain their owners. The boolean is remembered in local menu
preferences independently of expedition saves; older preferences lacking the key
retain the configured view setting.

Grass draws to 26 cells; small vegetation/decorations to 32; trees and terrain
retain the 72-cell horizon. Vastra defaults to **38 cells**, with its existing
independent 6-cell edge fade; vegetation culling does not change its simulation.
Shadows use a 32-cell range and clear-weather fog begins earlier (0.85 of its
68-cell fog horizon). Existing smooth grass and decoration fades remain.

Native authored-mesh LOD now receives near/middle/far biases of 1/0.5/0.25 times
configured scenery bias. The owning chunk's nearest bounds select tiers at 24 and
48 camera-relative cells; actual simplification still follows each mesh's available
native LOD indices and projected size. Near groups preserve their original shadow
mode; middle/far groups stop casting detailed shadows. Tier assignments are only
written when their inputs change and are invalidated on settings reapplication.
This preserves authored silhouettes; no new billboard art, merged-material proxies
or synthetic replacement tree shapes are introduced. Mesh LOD alone does not merge
draw calls; shorter small-plant range removes some distant submissions.

Reserve appearance scans skip cells outside the detail radius (plus a conservative
two-cell margin). Camera/range changes restart the bounded scan even while paused;
canonical reserves and ecological membership remain independent. Ground appearance
retains its shared geographic texture and existing sampling budget. The 64-chunk
startup barrier and slow generation policy remain in place.

Focused rendered D3D12/Forward+ testing passed **17 checks** for zoom limits,
Options toggle/persistence, tier bias, restored near shadows and Vastra range.
World/Options captures under `artifacts/distance-tiers/` were inspected. That world
capture still has streaming in progress; it is not full forest/horizon art approval.
The focused suite is included in the shared validator. Headless checks also passed: distance tiers 17, wilderness presentation 61, leaf
reserve links 35, Inspector tuning 14 (**127 checks**). Inspector warnings come
from intentional invalid-setting fixtures. Logs are in the same artifact directory. No measured FPS saving,
full-validator/export or device acceptance is claimed. Native LOD benefits depend
on the existing asset's LOD levels. Pre-edit sources remain in the artifact folder;
changes preserve the existing dirty codex checkout and remain uncommitted.


## Shared vegetation visual queue — November 1, 2026

Owner approved the next bounded step: share the allowance for changed vegetation
visuals. `vegetation_visual_queue.gd` now serves leaf/grass reserve custom-data
writes and plant-reaction transform writes under one default **512 instance writes
per frame**. WorldSolid exposes `Vegetation Writes Per Frame` (32–4096). Each group
gets at most 32 writes per turn, then rotates behind others. Budgets count actual
instance writes rather than assuming equal cost per canonical cell.

Pending groups coalesce to the latest target. A target changed during a partial
sweep receives a follow-up sweep so earlier instances eventually converge too.
Jobs use weak chunk/mesh references and are pruned on chunk departure. Re-admitted
cached chunks invalidate reserve-level metadata and queue neutral-pose restoration
from retained original transforms, preventing partial updates from persisting.
Original rest arrays remain with affected chunk groups until their owning chunk
is freed; memory stays bounded by retained chunk populations, not past events.
Standalone chunk consumers retain their immediate path unless assigned the queue.

This changes derived appearance only: reserves, transfers, simulation ticks,
canonical registration, generation and geography retain their existing owners.
The existing reserve-reading scan is still bounded per frame; ground reserve-map
sampling and its at-most-one texture upload remain under their existing owner.
This slice does not claim to schedule all ecological computation or GPU execution
under the instance-write cap. Visual catch-up can lag under a dense changing load;
it cannot discard or postpone conserved simulation transactions.

Verification: `tests/vegetation_visual_queue.gd` passed **3,127 checks** both
headlessly and with D3D12 rendering. A 1,030-instance fixture compares deferred
reserve/pose data against the immediate reference, changes a target mid-sweep,
ends/restarts reactions, and evicts/re-admits a cached chunk. A 128-write allowance
held throughout its 32 catch-up frames. Rendered readback establishes real instance
buffer equivalence; the initial headless pilot's direct readback fairness assertion
was replaced by queue-service evidence because the dummy renderer does not provide
that GPU readback. Existing leaf-reserve links passed **35 checks**. Ownership
passed **223 scripts / 223 UIDs**. The queue suite is in the shared validator.

A 180-frame live D3D12 scene check completed without engine/script errors: peak
vegetation writes were **512**, matching the configured cap, with **zero pending
jobs** at the end. This confirms integration and queue drainage in that sample,
not whole-game smoothness.

Logs and pre-edit sources are under `artifacts/vegetation-queue/`. No full-validator,
startup requalification, exported build, target-device acceptance or FPS gain is
claimed. Existing 64-chunk startup gating remains in place. Changes remain
uncommitted on the existing codex branch alongside preserved work.


## Owner play experience feedback — November 1, 2026

The owner reports that the generation pipeline changes have greatly improved
the player experience, particularly how the world spawns at startup and how
initial generation is handled. This is positive owner play feedback on the
current startup/generation approach described below: preparing the surrounding
world before gameplay begins, then continuing generation deliberately during play.
Retain this feedback as evidence when evaluating future generation changes.
It does not establish a measured FPS gain, hitch-free play or full release acceptance.
The owner subsequently adopted this direction as the standing
[generation experience baseline](PROJECT_STANDARD.md#generation-experience-baseline--november-1-2026)
in the authoritative project standard.

## Startup gate and plant sharing applied — November 1, 2026

Owner requested a basic menu, initial 64-chunk terrain preparation before simulation,
slow deliberate generation afterward, and application of tested plant reuse. A later
32-chunk suggestion was withdrawn; 64 remains the selected startup footprint.

F5 now opens `scenes/start_menu.tscn`: New Game, Load Game and Quit. The loading UI
is drawn before the game scene is loaded/constructed. The gameplay subtree remains
process-disabled while the controller explicitly advances existing preparation
with zero simulation delta. A separate `startup_loading` flag holds clock/movement
and bypasses gameplay inspection without pausing the preparation workers. Both new
and restored expeditions prepare a fixed 8x8 footprint around the player through
the existing one-job chunk pipeline, requiring all 64 detailed terrain/scenery
chunks to be published. Canonical local flora and its neighbor halo finish discovery.
Registration then proceeds in batches of 64: grass/ground plants (`plant`), trees
(`tree`), and active regional indexing. Existing saved reserves are retained.
Wildlife is established through the existing scene/state admission. No ecological
transfer or Vessel tick is run merely to initialize the loading screen.

After entry, the duplicated runtime view settings use one job, one chunk publication
per frame, a 1 ms main-thread allowance, and a 0.5 ms outer-chunk allowance. The menu
exports the play allowance (1–3 ms). Budgets remain cooperative; one resource upload
or atomic operation can exceed them. Initial resource loading/scene construction
still includes synchronous work behind the already drawn loading screen. This is
not a claim that every loading frame animates or all gameplay hitches are gone.
F6 on world_3d remains the direct fixture; three gameplay tests explicitly select
that fixture after the project's main-entry change.

Plant changes: ecology queries use the already-owned regional index before exact
radius/filter/order selection. Environmental readings are reused only within a
pure preparation phase, with independent copies for consumers. The memo is cleared
before Vessel preparation because ambient delivery and repairs may have changed
conditions. No reserves, rates, reservations or transfer clocks are pooled between
individual plants. Earlier isolated measurements support the regional-query change;
the synthetic environmental-read percentage is not a production FPS saving.

Final verification after application: startup new/save/invalid-save/clock/registration
order **11** checks; fine generation flow **195**; plant Vastra **950**; runtime work
reuse **3,388**; independent original-versus-current plant/ecology ledger comparison
**180**; Vessel ecology **4,827** (**9,551 checks**, zero failures). The paired ledger
fixture uses varied concentrations, tree/plant recipients and ecology enabled.
The original query reference also matched all **196** ordered local-query comparisons
against the applied implementation. Its post-application timing run overlapped other
validation and is retained as screening, not a clean performance comparison.
Ownership passed **222 scripts / 222 UIDs**. New startup and sharing suites are wired
into the existing validator. The complete validator/export/device run was not repeated.

A D3D12 Forward+ / RTX 3070 rendered startup completed 64 chunks and all registration
stages, with a clean log. Menu, loading progress and populated entry captures were
inspected under `artifacts/startup-gate/`. Final headless logs are `gate-staged.log`,
`flow.log`, `plants.log`, `reuse.log`, `equivalence-ecology.log`, `vessels.log` and
`sharing-final.log`; `render.log` records the rendered gate. The rejected first gate
pilot exposed a deferred UI call after queueing a failed-load scene for deletion;
the failure path now frees that detached game immediately, and final tests are clean.
No new whole-game FPS or no-hitch acceptance is claimed. Changes remain uncommitted
on the existing codex branch with pre-existing work preserved.


## Static Sol presentation — November 1, 2026

Owner requested removal of procedural animation from Sols and a result report.
The shared creature and appearance adapters now retain neutral authored body/joint
poses. They no longer advance procedural ground supports or apply foot solving,
breathing, gestures, wing/fin cycles, or attack/hit posing. Direct appearance
previews also remain neutral. Neutral wing membranes are assembled once. Movement
replay, rigid travel heading, caller ground/traversal height, affinity motes/cores
and impact flashes remain. Legacy animation values use storage-only exports to
keep existing authored scenes/validation while removing inactive Inspector knobs.
Unused construction/support helpers and species gesture methods remain in source;
the runtime update does not invoke them. Player animation is unaffected.

### Bounded comparison

Evidence: `artifacts/sol-static-presentation/`. Before sources, source hashes,
headless/rendered logs, raw windows/frames, screenshots and `summary.json` are
retained. `tools/profile_sol_static.gd` measures actual `sync_views` calls with a
frozen startup population: **34 tracked, 12 visible** in both versions. Persistent
snapshots remained identical in both CPU and rendered windows. The isolated CPU
sample warms 240 calls then measures five windows of 240 calls. Initial headless
means were **1.730 → 1.116 ms/call**, about **35% less**.

A separate short rendered pair used Godot 4.7.2, D3D12 Forward+ / RTX 3070,
**2560 × 1369**, cap off and VSync disabled, with 120 warmup and 300 measured frames.
Normal startup maximization overrode the requested 1280 × 800; screenshot dimensions
record the actual viewport. Simulation was frozen, wildlife updated manually once
per frame and streaming continued. Before rendering used an isolated copy restored
from the three archived presentation files; runtime comparison confirmed those
were the only differing files across scripts/scenes/resources/shaders.

| Metric | Before | After |
| --- | ---: | ---: |
| Wildlife sync CPU, mean per rendered frame | 2.829 ms | 1.980 ms |
| Whole-frame mean | 12.868 ms | 12.328 ms |
| Average throughput, 1000 / mean frame time | 77.7 FPS | 81.1 FPS |
| Frame p95 | 20.795 ms | 21.451 ms |
| Worst frame | 263.659 ms | 254.453 ms |

Wildlife presentation saved approximately **0.85 ms/frame (30%)** in this rendered
sample. Average throughput was about **4.4% higher**, while p95 was slightly worse.
This is one sequential frozen-scene observation per version, with OS/driver/import
caches retained and live streaming variability, not a matched repeated gameplay
qualification or proof of stable 60 FPS. Large hitches remain. These are not the
older 4.1 ms diagnostic workload and must not be subtracted from that figure.
No broad profiling campaign or full validator was run.

### Verification

Focused Godot suites passed: static presentation **238**, creature models **93**,
anatomy batch **411**, companion traversal **30**, combat world continuity **26**
(**798 checks**). Updated animation assertions now require neutral body poses rather
than retired procedural behavior. The static suite checks all catalog entries plus
an unknown-species fallback and direct appearance previews, with no support-solver
activation or locomotion terrain queries; movement heading and ground/flight/swim
height remain checked. Script ownership passed **221 scripts / 221 UIDs**.
Editor import completed without script/parse errors but emitted the existing safe-save
permission error; this is not a clean import pass. Scoped CRLF-aware diff checks
were used. Changes remain uncommitted on the existing `codex/` branch.
Rendered before/after profiles exited cleanly with no engine/script errors. The
after screenshot was inspected for world/UI/model visibility; it is a wide view,
not detailed art acceptance for each species. An initial static-test pilot wrongly
included permitted root heading in its neutral-joint comparison; corrected checks
exclude that root. The failed snapshot-launch pilot lacked asset junctions/import
cache and is retained separately from completed measurement logs.


## Staged spiral loading experiment — November 1, 2026

Owner requested fully completing one chunk at a time in a spiral, then clarified
that nearby chunks should load first while outer scenery fills slowly, favoring
the travel direction. The active development experiment defaults
`View3DSettings.spiral_chunk_loading` to true. The existing desired visibility,
player radius, cache, canonical geography and temporary-ground coverage remain
under their existing owners. This changes detailed scenery scheduling only.

Requests follow player-centered square rings, starting each ring toward the
dominant travel axis when moving. The nearest `nearby_chunk_fraction` (default
0.5, rounded up) of the complete desired list receives the normal detail budget;
outer requests use `distant_chunk_work_ms` (default 0.75 ms), capped by the existing
frame deadline. Classification uses the desired list including already loaded
chunks, so draining the near queue does not promote every remaining outer chunk.
An admitted chunk finishes before another starts, including dependency loading,
background geometry and main-thread mesh upload/publication. Movement preserves
admitted work while it remains wanted; out-of-range work still cancels normally.
The serial fallback retains the same spiral and reduced outer budget.

These are cooperative main-thread time allowances, not hard limits on individual
uploads or worker execution. The worker still runs a finite task; lower outer
budget spreads its main-thread completion over more frames. This does not change
the rendering distance or prove a reduction in the recorded rendering hitches.
Disable Spiral Chunk Loading and restart/reapply to restore the prior priority
and pipeline overlap. The nearby fraction and outer budget are adjustable under
the existing view resource. This experiment does not close release gates.

Focused verification: `tests/spiral_chunk_loading.gd` passes 1,118 checks covering
spiral uniqueness/rings, travel orientation, admitted-work retention, publication
selection, near/outer budgets, disabling the experiment and invalid tuning.
Receipts are under ignored `artifacts/spiral-loading/`. A scoped D3D12 Forward+
startup check exited 0 without engine/script errors: three chunks published in
queue order `(1,0), (1,1), (0,1)`, with no overlap between background preparation
and another chunk's publication. The desired list assigned 24 chunks to the near
tier; the three post-startup publications took 10,549 ms under this checking
fixture. This is functional evidence, not a performance comparison. The first
launch used automatic renderer selection, logged Vulkan initialization errors
and then fell back to D3D12; the clean receipt explicitly selects D3D12. An initial
unit-test pilot omitted its mock world and failed two checks; the corrected probe
and writable absolute log destination pass cleanly. No broad validator or
performance comparison was commissioned. Work is uncommitted on
`codex/chunk-spiral-loading`, layered over the existing dirty development checkout;
unrelated edits are preserved.

## Vegetation update scheduling audit — November 1, 2026

Owner requested read-only investigation without further hard testing, suspecting
plant numbers update together despite local-update plans. No vegetation runtime
change or additional performance test was made by this audit.

Code inspection supports a narrower concern than whole-world updates each frame:

- `world.gd:advance_environment` synchronously chains environment recovery,
  affinity recovery and flora circulation on the shared 0.75-second activity tick.
  Flora circulation then calls ambient delivery, Vessel ecology and ambient export
  before returning. `advance_time` can emit multiple catch-up ticks in one frame.
  Work limits within services do not spread that chain over separate frames.
- Fine refill already rotates through at most 256 active nodes per frame and
  credits elapsed generation in 0.125-second quanta. Leaf display rotates through
  64 cells per frame by default; ground display through 256. Both restart their
  pending sweep counts on the same finer clock while preserving their cursors.
  These protections exist; claiming every plant is recomputed every frame is wrong.
- Budgets count cells/records, not wall time or instances. `apply_plant_reserve`
  skips unchanged 5-percent reserve levels, but a changed level writes custom data
  for every associated instance in the serviced cell. `apply_plant_animations`
  similarly writes all instances belonging to event cells. Dense cells therefore
  have unequal costs despite equal cell counts. Ground-map changes upload the
  whole 128x128 texture, although CPU sampling is bounded.
- `ecology_plants(focus,64)` scans the complete active flora list, filters to the
  local radius, sorts candidates, then limits returned records. Plant animation
  invokes it on each activity tick. The output limit is not a scan-work limit.
- Packet accounting contains several passes over all pending flora flights:
  held-reserve calculation, incoming reservations, arrivals and visual transfer
  projection. Some results are already memoized per tick; fine refill also builds
  held/incoming maps on frames with due generation. These passes cover admitted
  pending packets, not every generated plant in the infinite world.
- Vastra presentation coalesces dirty signals into one refresh per frame, and
  caches chunk vegetation. It still performs a source scan every 0.5 seconds;
  a dirty refresh synchronously rebuilds the selected transfer presentation.
  Coalescing avoids duplicate refreshes, but does not budget one refresh's work.

The existing concurrency roadmap already separates visual work from canonical
transactions and plans regional query/preparation ownership. The best bounded
follow-ups are to reuse that regional index for truly local reads, count/cap
presentation work by actual instance writes, and queue changed visual cells under
a shared allowance. Preserve elapsed generation, transfer order, conservation and
combat ownership; do not simply defer/drop simulation ticks or equate offscreen
plants with inactive ecology. These are code-derived candidates, not measured
causes or promised FPS gains. Prior gameplay evidence still records simulation
batch spikes around 37–43 ms; the static Sol comparison froze simulation and
cannot rule this vegetation path in or out.

## Development hitch changes — November 1, 2026

Owner selected one background chunk-preparation worker and ended the broad
comparison/testing campaign. The active checkout includes the integrated candidate
with a one-job default and serial fallback; see the
[concurrency decision](runtime-concurrency-roadmap.md#development-decision--november-1-2026).

Two bounded rendering changes target the measured first-use stalls below:
`world_solid.gd` now establishes MSAA, SSAO, the environment and directional light
before base-scene mesh admission; `battle_controller.gd` retains hidden marker
and ember instances created through the same builders used by combat. Preparation
runs during startup and owns no actors or tactical state. Godot's
[pipeline guidance](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
supports enabling rendering features early and adding representative hidden
instances before first use. These changes target pipeline preparation; they do
not prewarm every creature, effect or mesh variant. No post-change frame-time
improvement is claimed without measurement. The previous baseline remains the
evidence for prioritization; sustained wildlife synchronization and atomic
simulation/scenery work remain further targets if hitches persist.

Brief verification: normal D3D12/Forward+ startup exited 0 with
`worker_enabled=true jobs=1 slots=1 prepared_board=true`; no engine/script errors
were reported. Receipt: `artifacts/concurrency/development-startup.log` (disposable
preferences/save directory). Script ownership passed for 221 scripts and UIDs.
These checks establish startup/integration, not a frame-time improvement. No
further broad suite or rendered journey was run for these changes.

## Repeatable baseline and stall attribution — November 1, 2026

Owner requested optimization-plan steps 1–2 only: establish a repeatable heavy
workload and locate stalls. No production script, gameplay rule, visual setting,
simulation rate or prepared plant asset was changed by this work. New tools live
under `tools/`; timing wrappers are generated only in an ignored diagnostic copy.

Evidence: `artifacts/frame-stalls/baseline-20261101-v4/`. The manifest preserves
frozen runtime hashes, driver/instrumentation revisions, native exits, shared
asset/import size/mtime inventories and per-run sources. `hardware.json`,
`analysis.json` and `report.md` provide the machine receipt, detailed results and
human-readable summary. Per-run `profile.json` contains frame intervals, phase
boundaries, queue/population state and diagnostic spans; `process.json` contains
sampled working set/private bytes. `progress.json` is incomplete checkpoint
evidence and never substitutes for a completed profile.

### Workload and accepted baseline

Godot `4.7.2.stable.official.ed1daf0bf`, D3D12 Forward+, RTX 3070, Ryzen 7 5800XT,
2560 × 1369, seed 2601026, normal settings, cap 60 and VSync enabled. Fresh
processes use separate preferences/save locations. OS/driver caches are retained;
snapshot shader caches may warm across repeats. This is desktop debug evidence,
not physically cold-cache qualification, GPU-memory measurement or Thor acceptance.

The driver uses normal input-action travel with live simulation: initial idle,
outbound/return, negative-coordinate sprint/return, four camera headings,
inspection, live Sol menu, actual encounter/deployment, readiness planning and
one committed combat plan. Route preparation, screenshot/checkpoint writes,
warmup and phase-boundary frames are excluded from workload statistics. Initial
idle still has queued scenery and is not labeled settled performance. The
controller chooses the actual starter through the menu owner; it never changes
HP, RNG, simulation speed, AI or terrain to admit combat.

Accepted uninstrumented runs are `baseline-run1`, `baseline-run2` and
`baseline-run4`: all workload checks passed, native exit 0, zero engine errors,
unchanged frozen sources, same selected authored opponent
`2601026:6:4:sol_species_0018`. Startup ranged 11.478–13.413 seconds; sampled peak
process working set ranged 1,851–2,163 MiB, including measurement bookkeeping.
These are observed peaks, not approved memory budgets or leak/plateau evidence.

| Baseline phase | Per-run p95 range ms | Worst accepted frame ms |
| --- | ---: | ---: |
| Outbound travel | 31.87–43.41 | 236.06 |
| Return travel | 35.57–38.38 | 277.40 |
| Negative-coordinate sprint | 34.57–47.85 | 89.16 |
| Camera orbit | 27.30–31.64 | 58.39 |
| Inspection | 27.65–31.65 | 60.02 |
| Readiness planning | 27.98–34.01 | 61.70 |
| Combat execution | 47.69–60.10 | 208.06 |

Execution is one short action-plan window, not a sustained-combat FPS estimate.
Three samples establish an initial observed range, not statistical regression
bounds. Scenario timing and moving wildlife vary naturally with frame intervals.

### Diagnostic findings

The expanded diagnostic wraps 74 original function bodies, including all script
process/physics callbacks, selected nested operations and render-signal markers.
`wrapper-body-verification-expanded.json` verifies the original bodies against
the uninstrumented copy. Renamed implementations have per-file unique names to
preserve inherited dispatch. Timings are inclusive wall durations, not hardware
CPU/GPU timers; parent and child costs must not be added together. The union of
recorded spans counts overlaps once. Residual wall time includes unwrapped work,
sub-millisecond spans, scheduling and waits; it is not automatically GPU time.

Clean expanded runs `diagnostic-run3`, `diagnostic-run4` and `diagnostic-run5` passed all workload
checks, native exits and source/error checks. Their largest travel render
intervals were 246.773 ms within a 273.467 ms frame and 347.034 ms within a
376.051 ms frame. Combat render intervals reached 128.017 ms within 166.242 ms
and 1,169.431 ms within 1,336.074 ms. These are diagnostic observations, not
uninstrumented baseline maxima or measured optimization gains. Render boundaries
isolate the subsystem but alone cannot distinguish GPU execution, driver waits,
pipeline compilation and native rendering work. One 102.966 ms return frame still
had 81.912 ms outside recorded spans; not every outlier is fully attributed.

The final counter run narrowed the render finding: its 242.945 ms outbound frame
spent 218.117 ms in the render interval while the surface-pipeline compilation
counter increased by five. A 148.764 ms combat frame spent 115.745 ms there while
draw and surface compilation counters each increased by four. Raw adjacent-frame
counts are retained in `diagnostic-run5/profile.json`; `pipeline-events.json`
extracts counter changes. This is evidence of pipeline-compilation activity
coinciding with the stalls, not proof that every render millisecond is compilation.
Godot documents surface/draw compilations as potential first-use stutter sources
and notes that some monitors can update with a delay; see the official
[Performance monitor reference](https://docs.godotengine.org/en/stable/classes/class_performance.html).
Pipeline preparation/reuse is therefore a stronger early candidate than camera
arithmetic, subject to a separately authorized implementation and comparison.

| Scope, first two clean diagnostic runs | Observed cost | Implication |
| --- | --- | --- |
| Wildlife `sync_views` | 4.08–4.12 ms mean per present frame | A sustained cost deserving priority over camera arithmetic; includes terrain/traversal, animation, validation and label work. Individual causes need narrower measurement. |
| Wildlife admission | 45.20–49.99 ms maximum call | Chunk crossings still batch initialization/view rebuilding/move-book preparation synchronously. |
| Plant-reserve display | 1.52–1.57 ms mean per frame | Candidate for small work-reuse/binding/update improvements; preserve actual reserve readings and transitions. |
| Inspection description | 1.57–1.60 ms mean when called | Candidate for reusing unchanged inputs; card rendering already has a reading cache. |
| Camera pose | 0.10–0.11 ms total mean per frame, four calls | Repetition is real, but measured payoff is smaller than the above. |
| Simulation clock/update batch | 37.07–42.77 ms maximum call | Includes signal-driven environment and wildlife work; not just clock arithmetic. |
| Scenery cell step | 34.65–37.05 ms maximum call | The nominal 3 ms streaming deadline cannot preempt one atomic operation. |
| Battle view update | 41.31–53.38 ms maximum call | Worth narrowing alongside render-first-use work; it is event-driven rather than a 15 ms cost on every game frame. |

The prepared plant palette was current in every accepted workload. Earlier
four-second fallback generation is not the demonstrated cause of these stalls.
Small-change priority should now favor wildlife presentation reuse, reserve
projection and inspection inputs; the largest hitches need rendering/pipeline
attribution before choosing a rendering fix. No implementation change or speedup
is claimed by this measurement slice.

### Driver revisions, rejected pilots and reuse

The third baseline selected a nearer habitat individual without an admissible
battle position and is excluded. The driver was then pinned to the authored
opponent used by both earlier successful runs; their production runtime hashes
and actual opponent identity justify reuse. The final driver can withdraw and
reposition through normal input when a moving opponent invalidates a command
position; admission rejections are retained in the report. This does not bypass
combat's spatial checks.

`diagnostic-run1` completed exploration but failed combat admission and is not an
accepted full workload. `diagnostic-run2` exposed an inherited-method collision
in the expanded wrappers, was deliberately stopped and is rejected. Its error
logs are instrumentation failure evidence, not a production-game regression.
Earlier `baseline-20261101-v2`/`v3` directories retain intake/interrupted pilots;
none are silently pooled into the accepted baseline.

Repeat from the repository root with a fresh label:

```powershell
python tools/profile_frame_stalls.py --godot '<pinned Godot console executable>' --label '<fresh-label>' --mode all --runs 3
python tools/report_frame_stalls.py '<fresh-label>'
```

The launcher preserves existing output, checks snapshot hashes before/after each
run and rejects missing final profiles, nonzero exits and engine errors. Asset
links keep local-only art in place; shared-asset edit detection is metadata-based,
not a content hash of every imported binary. Retain all per-run settings and
sources when comparing a later change. Changing the seed, roster identity or
scenario is a new workload version. Configured CI and prior functional/save
acceptance requirements remain unchanged; this slice does not run or pass the
full validator or close the historical save/new/load comparison failure.

The completed study has three accepted uninstrumented baselines and three clean
expanded diagnostics, zero shared-asset metadata drift, and no production
optimization changes. Extensive follow-up testing now requires the owner's
prior permission under `PROJECT_STANDARD.md`; do not automatically launch more
journeys from these findings.

## Isolated background chunk candidate — November 1, 2026

The owner-selected population work is implemented on `codex/chunk-population` in
`artifacts/concurrency/worktree/`. Its [scope, controls and receipts](../artifacts/concurrency/worktree/docs/runtime-optimization.md#background-chunk-population--november-1-2026)
record three clean rendered comparisons per mode and headless/rendered lifecycle
checks. This is separate from the newer movement/simulation/rejected-art work
below; those changes were preserved in this active checkout. Owner play review
and deliberate integration remain open.

## Movement, simulation and rejected-art work reuse — November 1, 2026

Follow-up to resumable cell preparation. A diagnostic journey separated the
remaining inclusive movement/simulation/cell costs. `artifacts/runtime-hotpaths/`
retains pre-edit sources, the diagnostic wrappers and timings. Wrappers were
removed before implementation and verification; they are not runtime features.
The aggregate diagnostic also includes explicit new/load rebuilds, so its large
nested maxima must not be mislabeled as travel-only costs.

Verified repeated work and changes:

- Wildlife-home windows overlap by 20 of their 25 geographic blocks at a cardinal
  sector crossing. A 128-entry FIFO now retains each block's exact original
  candidate-search result, including empty results. Same-state admission no
  longer invalidates immutable home geography. Terrain, tuning revision or state
  replacement invalidates the derived cache; returned records are copied.
- The live wildlife owner retains its current species catalog. Previously a
  standalone owner could release/reload the catalog between settings checks,
  changing resource IDs and defeating validation and geography reuse. The
  validation memo still retains only values/IDs; duplicated movement settings
  still use their existing weak catalog override. Replacement/null settings
  release the owner's reference.
- Wildlife admission now retains behavior resolutions only alongside unchanged
  retained models/entries under the same state and validated settings. Departed
  members are pruned; state replacement, changed entries and direct tuning edits
  invalidate them. Previously each sector crossing cleared all resolutions.
- Move-book admission accepts an optional value-only validation memo; the default
  API still validates normally. The battle owner retains nonempty species
  templates, bounded by the validated library roster, and checks the current
  library graph once per admission batch before serving them. Nested edits clear
  templates, and ExpeditionState still deep-copies each individual book. Wild
  recovery reuses its existing validation memo as well.
- Bounded roaming BFS rejected candidates at a full frontier only after calling
  collision. The capacity check now precedes that discarded query. Queue order,
  target choice, occupancy and player-spacing rules are unchanged.
- Per-frame flora refill first identifies due sampled plants, preserving the
  round-robin cursor and original visit/credit order. Already-credited rows skip
  role classification. Empty due sets skip reservation/flight-index construction.
  Rates, fractional-clock boundaries, held/incoming stock and conservation stay
  unchanged; no simulation tick is deferred or dropped.
- Live scenery dressing used to prepare legacy living artwork and then discard
  the returned record. An explicit `allow_living=false` query now rejects those
  entries before model preparation. Existing composition/pond callers retain
  their default admission; canonical flora still belongs to its existing owner.
- ArrayMesh triangle counts use surface index/vertex lengths, avoiding full
  array retrieval solely to count triangles. Non-ArrayMesh handling is unchanged.
  The fingerprinted art change requires the regenerated 153-definition bake.

`tests/runtime_work_reuse.gd` is in the shared validator. Its optional `--paired`
uses archived pre-edit home, navigation and refill algorithms. The paired fixture
passed 854 checks: identical ordered homes/species/affinity, navigation targets,
energy ledgers and refill cursor progression across multiple limits, fractional
steps, classified roles and held/incoming transfers. It also covers bounded
empty-result eviction, resource retention, edit/source invalidation, rejected-art
admission and indexed mesh counts. One paired CPU observation reduced collision
queries from 6,875 to 5,765 (16%) and refill CPU from 178.953 to 84.286 ms (53%).
These are fixture costs, not whole-game frame-time gains.

A second direct-admission diagnostic (initial construction/new/load excluded)
identified move-book preparation at up to 22.848 ms and view rebuild at 30.857 ms.
The first serial pass had not improved the movement peak, so the final pass adds
the species-template and retained-behavior reuse above. Its 41-check admission
fixture verifies exact books, rejected invalid nested edits, independent committed
state, bounded templates, retained models/tuning, and in-place invalidation and
restoration. Twenty book constructions measured 59.169 ms with full validation
versus 35.321 ms with memoization in one focused observation; this does not include
the additional controller-template reuse and is not a frame-time claim.

Final screening used one frozen pre-edit runtime and a final fresh process with
normal input-action travel and live simulation: seed 2601026, Direct3D 12 / RTX
3070, 2560 x 1369, cap 60. Both packaged palettes were current for their own
sources. OS/driver caches were retained; the reference was not repeated after
the later admission-cache refinement. Full script/resource/scene/shader hashes
were unchanged during the final journey. This is exploratory screening, not
repeated matched qualification or a numerical acceptance gate.

| Peak operation | Frozen baseline ms | Final ms |
| --- | ---: | ---: |
| Movement/admission | 44.477 | 38.865 |
| Simulation including refill | 37.943 | 35.010 |
| Cell suboperation | 218.866 | 26.675 |
| Detail preparation slice | 219.620 | 27.868 |

The intermediate serial pass recorded movement 44.450 ms, so it did not address
that peak; the later move-book/behavior reuse reduced it in the final sample.
Cell numbers refer to uninterrupted suboperations in both these runs. They do
not describe the total CPU work accumulated across all steps of one cell.
Remaining atomic model/resource, view construction and simulation work still
exceed the 16.7 ms interval for 60 FPS. Startup was 11,608.382 / 9,335.599 ms;
retained caches and a single sequential comparison prevent attributing that
difference to these changes.

| Route | Baseline p95 / p99 ms | Final p95 / p99 ms |
| --- | ---: | ---: |
| Outbound | 25.804 / 41.709 | 24.879 / 39.641 |
| Return | 29.082 / 46.472 | 28.391 / 46.598 |
| Negative | 23.538 / 39.869 | 25.920 / 42.739 |
| Negative return | 23.075 / 39.317 | 25.514 / 40.554 |

The negative-coordinate sections were slower in this observation, despite the
smaller targeted operation peaks. Overall FPS improvement is **not established**.
Worst travel frames still reached 211.041 ms in the final outbound leg, without
an isolated cause; the return worst frame fell from 236.162 to 69.137 ms.

**Both journeys failed the same complete persistent-snapshot save/new/load
comparison.** Neither is a functional acceptance pass. The final focused
inventory has 20 passing suites / 57,780 checks, with import/parse and
ownership/UID checks passing (212 mapped scripts / 212 UIDs). The two existing
label-visibility assertions in `authored_sightings` and `sol_player_reactions`
reproduced on the frozen baseline. `runtime_hot_paths` passed all 186 assertions
but exited with a native shutdown crash in current runs. An initial archived
baseline also crashed; a later guarded baseline with a verified current bake
passed. The intermittent shutdown symptom remains unresolved and is not counted
as a suite pass or conclusively attributed to a change. A trial sky-release
cleanup did not resolve it and was reverted; assertions/checker strictness were
not weakened. The full configured validator was not run.

Evidence lives under ignored `artifacts/runtime-hotpaths/`: `final-comparison.json`,
`validation-summary.json`, `final-source-before.json`, `final-source-after.json`,
`baseline-runtime/artifacts/journey/`, `final-journey/`, archived source/palette,
paired/admission checks, diagnostic breakdowns and per-suite logs. Temporary
profiling wrappers are absent from production code. Startup and remaining atomic
operations retain their existing limitations.

## Resumable cell preparation — November 1, 2026

The existing worker screening left canonical cell/model preparation on the main
thread and did not establish a consistent frame-time benefit. This follow-up
keeps those experimental switches unchanged and divides the serial cell path:
ground, plant placement, body submission, individual grass candidates, endpoint
commit and remaining dressing now yield separately. Streaming counts each step
against the existing operation/time bounds and advances the cell index only on
completion. Synchronous construction drains the same cursor. Grass retains its
original random draw order, rejection rules, body clearance and organ attachment
order; retirement releases unfinished cursor references. Partial chunks remain
unpublished. No generation, simulation, saved-state or density defaults change.

The active checkout's palette fingerprint was stale on intake. A focused
five-chunk diagnostic recorded fallback procedural/official model generation
inside cells, including a 4,103.796 ms plant call. This diagnostic used the
plain nature settings with grass disabled; it is not a main-game frame timing.
The 153 derived palette definitions were regenerated with the existing bake tool;
stale-bake rejection remains intact. Any later change to fingerprinted inputs
requires regeneration again. The original palette and three edited runtime
sources are archived under ignored `artifacts/cell-preparation/`.

`tests/cell_preparation.gd` covers yielding within a cell, expired deadlines,
one-candidate grass steps, cancellation and exact finished geometry, picking,
cosmetics and living-endpoint anatomy. Its optional `--reference=` accepts an
archived original chunk implementation. The paired archive also retains the
original plant library, so this compares against the pre-edit algorithm rather
than another caller of the new cursor. The shared validator includes this suite.

The warmed three-chunk paired fixture passed 23,361 checks against the original
algorithms. Full-cell CPU work totaled 508.657 ms before versus 605.482 ms after
(19% more); the largest uninterrupted operation fell from 5.522 to 2.724 ms.
Accumulated work for a sliced cell still reached 6.073 ms. These measurements
show a scheduling tradeoff, not a reduction of total CPU work. The earlier
3.096 ms sliced-operation sample preceded the expanded cancellation/timing fixture.

One rendered fresh-process pair used the same seed (2601026), regenerated bake,
normal live input-action travel, Direct3D 12 / RTX 3070, 2560 x 1369 and 60 FPS
cap. OS/driver caches were retained. Selected runtime/resource fingerprints were
unchanged across the pair. This is exploratory screening, not repeated matched
qualification. The original world/chunk/plant scripts are archived for the
reference process, preserving the active checkout and its user changes.

| Route | Original p95 / p99 ms | Sliced p95 / p99 ms |
| --- | ---: | ---: |
| Outbound | 46.256 / 79.568 | 29.816 / 43.343 |
| Return | 29.570 / 47.920 | 30.828 / 48.644 |
| Negative | 24.723 / 39.565 | 25.791 / 41.693 |
| Negative return | 25.630 / 43.249 | 24.041 / 39.017 |

The cell-operation peak fell from 222.242 to 31.236 ms. The updated cell metric
measures a resumable suboperation; it must not be described as the total cost of
all work for one cell. Preparation slices peaked at the values in
`artifacts/cell-preparation/comparison.json`. Movement/admission peaks were
47.933 / 49.376 ms and simulation 33.483 / 34.199 ms: neither subsystem was fixed
by this change. Startup was 10,417.335 / 8,171.737 ms, but one sequential pair
with retained caches cannot attribute that difference to this refactor.

**Both journeys failed the same final full-persistent-snapshot save/new/load
comparison.** Travel, route discovery, pause and the other journey assertions
completed, but neither run is a functional acceptance pass. The original-builder
failure establishes that this failure predates the cell split in this comparison.
No save/load behavior or assertion was changed or suppressed. Screenshots from
both waystone arrivals were inspected; they are live captures at different clock
instants, not pixel-equivalence evidence. Exact geometry equivalence comes from
the paired fixtures.

Final focused validation passed nine suites / 50,174 checks with no script or
engine errors: cell preparation, runtime optimization, chunk limits, stutter,
streaming bounds, live plant integration, community integration, baked-art
regressions and terrain integration. Engine import/parse passed; ownership/UID
validation passed (212 mapped scripts / 212 UIDs). The stationary streaming
fixture drained all 47 requests without cancellation and obeyed preparation,
upload and residency bounds. The full configured validator was not run; the
rendered snapshot failures above remain open and were not reclassified.

Evidence: ignored `artifacts/cell-preparation/comparison.json`, `journey-manifest.json`,
`reference/`, `sliced/`, `check-results.json`, individual logs and the archived
pre-edit implementations. Cold resource loads, fallback procedural model
generation, placement queries, ground setup and GPU uploads remain atomic.
This does not claim a hard 3 ms deadline, worker-safe generation, hitch-free
travel or target-device acceptance.

## Chunk hitch controls and local Vastra effects — October 31, 2026

The owner requested a chunk-rendering audit, a shorter Vastra effects range,
more efficient chunk construction and explicit work limits. This serial change
retains canonical generation, ecology, saves, plant geometry and existing
MultiMesh batching. It does not enable the proposed concurrency architecture.

Confirmed issues and fixes:

- Temporary ground previously built its entire mesh in one uninterrupted call
  after geography preparation. `coarse_ground_job.gd` now yields between tiles,
  skirt edges and its final upload. Chunk-local vertex tint/soil/blend reuse avoids
  repeated shared-corner and skirt queries. Detailed ground shares those attributes
  too; construction caches are released before residency.
- A cold route step could synchronously construct neighboring drainage, ponds
  and channels. The same canonical basin builder now supports cooperative raw
  drainage samples, pond candidates and individual channel attempts. Route
  preparation warms its surrounding basin dependencies before path queries.
  Completed warmup cursors are removed so cache turnover rechecks dependencies.
- Finalization used only elapsed time, allowing multiple uploads in one slice.
  Detail now caps actual material-batch uploads separately from CPU instance-buffer
  and picking preparation. Incomplete chunks remain unpublished.
- Cancellation and resident-pressure eviction could destroy whole chunks at once.
  Cancelled visuals now join bounded retirement; owned records and child/root nodes
  are released incrementally. New detail waits at the resident cap. Explicit
  startup, load/rebuild and view-settings reapplication remain synchronous.
- Vastra optics followed the entire terrain horizon (at least 128 cells in the
  previous query calculation). Live play now uses a 24-cell player-centered radius,
  fading over the outer 6 cells. Distant source regions and transfers are rejected
  before optical work; one frustum is shared by the packet filter. Active/fading
  filament admission is capped at twice the transfer limit, including queued
  deletions. Simulation activation, amounts, recipients and clocks are unchanged.

Provisional, Inspector-adjustable defaults in `View3DSettings`:

| Work | Default bound |
| --- | --- |
| Combined flora/detail/temporary-ground preparation | 3 ms per active frame |
| Detail preparation | 128 operations and 2 material-batch uploads per frame |
| Temporary ground | 32 geography/tile/skirt/upload operations and 1 mesh upload per frame |
| Detailed chunk publication | 1 completed chunk per frame |
| Retirement | 0.5 ms and 8 steps per frame; at most 32 owned records or one node per step |
| Resident detail, including preparation/cache/retirement | 128 chunk roots |
| Hidden detailed cache / hidden temporary-ground cache | 16 / 64 chunks |
| Vastra optics | 24-cell radius, fading from 18 cells; default 12 active and up to 12 fading layers |

These cooperative deadlines can overrun on one canonical cell, resource release
or engine upload. They do not impose a hard CPU/GPU frame-time guarantee. F3 shows
actual operations/uploads, retirement backlog and separate runtime coverage peaks.

Evidence under `artifacts/chunk-limits/` includes pre-edit source copies and logs.
The warmed paired fixture matched all mesh arrays across nine coarse chunks/sample
spacings and all detailed mesh arrays, instance buffers, cosmetics and living-source
records across three chunks. Coarse CPU work was 42.215 to 24.598 ms (42% less);
detailed CPU work was 78.305 to 68.909 ms (12% less). Both paths were warmed;
the previous path ran first. These are local CPU samples, not whole-game FPS.
Exact geography comparisons cover three seeds, three districts and both default
and production relief: 72 checks passed. One cold basin call was 16.412 ms before;
the maximum cooperative step was 0.925 ms. Initial stress observations of geography
78.554 ms and cleanup 28.402 ms fell to 1.495 ms and 1.284 ms in the subsequent
stress run. Those runs used changing inputs during this pass and establish local
diagnostic evidence, not an isolated whole-game comparison.

The rendered Direct3D 12 journey completed outbound/return/negative travel,
pause and disposable save/new/load with zero functional failures. It used live
simulation and reached 37 detailed chunks, 2,684 peak draw calls and approximately
3.99 million peak primitives. Travel p95 remained 25.551–37.406 ms; p99 remained
45.867–59.684 ms. Worst recorded travel frame was 747.894 ms, without an isolated
cause. Detailed cell preparation reached 46.465 ms, upload 3.342 ms, simulation
51.730 ms, movement/admission 96.551 ms and publication 1.369 ms. Initial scene
construction took 8,229.060 ms; temporary coverage's startup-inclusive peak was
491.899 ms. The journey loaded the implementation before the final telemetry and
nearby-source/layer-cap refinements; retain this limitation with its results.
No 60 FPS, hitch-free, exported-build or target-device acceptance is claimed.
The next justified optimization is isolated worker preparation/resource acquisition,
with a dependency audit of mutable terrain caches and main-thread publication;
moving the existing builder wholesale to a worker is unsafe.

Final focused validation passed on Godot 4.7.2: world generation 153 checks across
11 seeds, terrain geography 8,856, terrain integration 3,554, runtime optimization
63, stutter regressions 353, chunk limits 367, geography preparation 72, rendered
Vastra currents 231, and streaming bounds 31,235 (44,884 checks total). Import/parse
and ownership/UID checks passed. The runtime fixture now checks the intentional
expired-deadline rejection and the already-authored flat combat marker proportions;
no combat behavior was changed. The full configured validator was not run.

The final stress run completed all 96 queued chunks without cancellation and
obeyed count limits. Runtime temporary coverage peaked at 2.196 ms, independently
of its 410.367 ms startup/rebuild peak. Detail slices still reached 14.744 ms
(individual cell 13.205 ms; generation 5.514 ms; geography 1.499 ms; upload 1.666 ms).
Cleanup reached 6.166 ms, showing that an individual release can still exceed
the 0.5 ms cooperative allowance. Retain these final shortfalls alongside the
earlier samples; operation caps are passing, hard time targets are not.

## Terrain pointer picking — October 31, 2026

Terrain rays skip ground-face construction/testing for tiles entirely below a
level or rising ray's origin. Water picking remains independent. The two ground
faces are tested directly, preserving their diagonal, nearest hit and tie order.
Downward rays retain both exact face tests. No generation, reach or visual setting
changes. The shared validator includes `tests/terrain_ray_optimization.gd`:
2,018 fixture rays, 200 independent exhaustive comparisons and 42 explicit
vertical-hit/horizontal-miss checks. Optional `-- --paired` compares a local
pre-edit copy at `artifacts/picking-optimization/terrain_ray_before.gd`.

One paired Godot 4.7.2 headless synthetic CPU sample over 2,000 calls per path
measured sky-facing rays at 491.143 to 383.070 ms (22% less) and oblique downward
rays at 210.424 to 203.921 ms (3% less). All 2,018 paired results matched, including
scaled directions, water, below-surface origins and cell boundaries. These are
local fixture timings, not whole-game FPS or device acceptance. Logs and the
baseline are under `artifacts/picking-optimization/`. Production terrain integration
passed 3,554 checks and engine import/parse passed; the full validator was not run.

## Proposed concurrency foundation — October 31, 2026

The [runtime concurrency roadmap](runtime-concurrency-roadmap.md) defines the
owner-requested plan for bounded worker jobs, canonical generation preparation,
main-thread publication, lifecycle safety and selective game-system rollout.
It is a proposal, not an implemented optimization or performance acceptance.
Preserve the existing fixes and evidence below; establish a matching baseline
before enabling workers. The project standard remains the workflow authority.

## Integration into the nature-only alpha — October 31, 2026

This work is a retained alpha foundation, not replaced by the nature roadmap.
The [alpha register](world-exploration-roadmap.md#alpha-integration-register--october-31-2026)
tracks combined-build intake. Preserve bake fingerprints, compressed materials,
organ/picking data, bounded wetland/chunk caches, terrain admission/reuse and
player/occlusion fixes as their reviewed changes land. Do not disable canonical
flora or rebuild every plant dynamically to add reserve posture/color consumers.
New consumer inputs must participate in the appropriate bake/cache invalidation.

Existing focused CPU/rendered results apply only to their captured inputs. The
latest local broad run is not clean; classify encounter-initiation failures and
unresolved seam/endpoint results before alpha acceptance. New scheduler, journal,
clock and flora changes need their relevant integration checks. No numeric FPS
budget, handheld acceptance or asset redistribution permission is invented here.

## Live plant palette and Vastra consumers — October 30, 2026

The live procedural and official palette now loads 109 compressed, prebuilt art
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
October 31 follow-up: the current official catalog is included in both the bake
and its equivalence checks. Wetland membership queries now retain their existing
bounded-composition resource for the terrain's lifetime. Empty results are cached
too, with single-entry FIFO eviction at 4,096 cells. Previously an empty patch
returned before caching, repeatedly releasing/reloading the composition's entire
asset graph while building water cells. The first required resource load now
occurs during expedition preparation, outside streamed cell work. Admission,
plants and saved generation parameters are unchanged. One bounded composition
asset graph remains resident per live terrain rather than being repeatedly
released; the cell cache itself is bounded and never enters saved state.

Paired Godot 4.7.2 headless CPU observations on the current catalog:

| Workload | Original query/builder | Updated query/baked art |
| --- | ---: | ---: |
| 128 wetland cell queries, identical results | 7,336.502 ms | 59.454 ms |
| Eight chunks, retained wetland query in both runs | 19,802.833 ms | 1,192.055 ms |
| Largest preparation slice in that eight-chunk run | 2,998.324 ms | 23.042 ms |
| Material batches across the same chunks | 354 | 232 |

The eight-chunk comparison preserved exact generated cells, cosmetic placements
and living-source records, used 45 baked models and recorded no input-source
drift. Its archived prior chunk script also covers the old upload path. These are
CPU workload observations, with retained OS caches and warmed shared resources;
they do not establish whole-game FPS or handheld acceptance. The maximum includes
cold first-chunk material setup and loading. Atomic resource/GPU operations can
still exceed the cooperative 4 ms preparation budget.

`tests/wetland_query_cache.gd` covers exact legacy admission equivalence, cached
empty cells, bounded rollover/reconstruction and unchanged generation parameters.
`tools/profile_wetland_cache.gd` reproduces the paired query measurement. The smoke
journey now verifies that the player bridge includes every supplied model mesh,
replacing its obsolete assertion of eight rogue pieces after the approved grave
knight replacement. That stronger check exposed that the runtime-attached imported
mesh had been omitted by ownership-filtered searches. The bridge now includes
unowned runtime descendants. Occlusion's existing self-depth allowance follows
normalized player height instead of the adapter's different import-unit scale.
The presentation and full-3D fixtures follow the current body and animated calf
bone while retaining their material, movement, pause and pixel assertions.

Same-world saves and loads can now reuse a production terrain only when seed,
generator version, specialist percentage and every captured climate, relief,
scenery and community parameter match. Subclass hints are rejected. Complete
saved-state, flora, roaming and player admission still runs on every candidate;
only derived generation work is reused. The focused journey passes 26 checks,
including independent state replacement and preserving the live expedition after
invalid input. The production-community follow-up changes generation separately;
the paired CPU measurements above describe the preceding generation, not a
performance guarantee for the new layout.

October 31 continuation evidence is in `artifacts/bottleneck-fixes/continuation-*`.
Rendered D3D12 checks pass: solid geometry 19, player/animation 62, presentation 24
(including depth-buffer occlusion), and baked-art equivalence 1,338. Conserved
plant transfers pass 821 checks and Vastra currents pass 149, including bounded
terrain-following external root paths and distinct cached aerial attachments.
The older tile-center collision assertion now checks continuous movement up to
the wall and repeated-input rejection; building collision passes 777 checks and
player traversal passes 32. Existing Canvas/ObjectDB shutdown warnings remain.
The broad validator is not clean. After the corrected collision, plant-route
and Inspector fixtures passed, `tests/encounter_initiation.gd` reported 11 failures
in 26 assertions (warning/contact entry, preview guards and withdrawal/deliberate
approach). Its log is `continuation-remaining-3.log`. Several assertions still
describe tile-step movement or older keyboard/withdrawal behavior; this pass does
not establish whether all failures are stale fixtures or runtime defects. No
encounter rules were changed. Subsequent broad suites were not run; focused
generation/optimization checks are recorded separately. This is not a full
validator pass, export test or handheld acceptance.

Final focused continuation: wetland cache 467, loading regressions 74, runtime
optimization 62, runtime hot paths 186, stutter regressions 353, world optimization
4,263, terrain integration 3,617 and terrain geography 8,754 checks all pass
(17,776 total). The solid-world movement/save/new/load journey passes 2,571
checks. Inspector tuning passes 14. Engine import and script ownership pass
(191 mapped scripts/UIDs); scoped whitespace checks pass with Windows CR line
endings accounted for. A 758-file runtime source snapshot showed no drift across
the final checks. No staging, commit, push or merge was performed; the existing
owner changes remain in the checkout.

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

### Relief query support rejection — November 1, 2026

Raw terrain evaluation now rejects positions outside the finite support of a
local landform or mountain ridge before rotation and further shape calculations.
The local ellipse fits inside a 46-cell circle; rejection uses 47 cells for
numerical margin. Mountain support fits inside a circle smaller than 0.671 times
parent spacing, including crest displacement; rejection uses 0.68 times spacing.
Contributing shapes retain their original arithmetic. Descriptor creation/cache
order, generation versions, saved parameters and authored settings are unchanged.
The production scene uses the exploration relief resource exercised here.

Godot 4.7.2 paired CPU measurements, alternating execution order across four
runs of 7,012 raw queries each, measured 55.187–56.506 ms for the original
calculations and 45.527–46.534 ms with support rejection (approximately 18% less
CPU time). These are local raw-query observations with retained OS caches,
not rendered frame-rate or whole-world startup measurements. Cache hits bypass
this work already, so the benefit applies to uncached relief preparation.

`tests/relief_query_optimization.gd` retains the original shape calculations as
an independent reference and passes 182,345 checks with profiling enabled.
It covers four seeds, minimum/default/maximum mountain spacing, contributing
ridges, rotated support edges, negative/large coordinates and cache turnover.
The shared validator includes its non-profiling regression path. Reproduce with
the pinned engine using `--headless --path . --script tests/relief_query_optimization.gd -- --profile`;
paired timings, source hashes, parameters and engine version are written to
`artifacts/relief-query-optimization/profile.json`. Import/parse validation and
script ownership (212 mapped scripts/UIDs) passed. Related suites passed:
terrain heightfield 298, exploration geography 12,649, geography preparation 72,
and launch optimization 742 (196,106 checks including the paired regression).
Logs live alongside the profile. No full-validator, rendered FPS or target-device
acceptance is claimed. Work remains uncommitted on
`codex/relief-query-optimization`, preserving the pre-existing dirty checkout.

## Unchanged-data reuse audit and implementation — November 1, 2026

Owner requested a search for unchanged data, then implementation of the safe
findings, emphasizing low-cost checks instead of repeated recursive work.
Inspected the current dirty `codex/performance-baseline-stalls` checkout
(HEAD `2812938a8135d94a311ee4b0b7512a1277b36566`); HEAD alone does not reproduce
these sources. Pre-edit copies and focused logs are retained locally under
`artifacts/unchanged-data-reuse/`. Existing baseline timings above prioritize
investigation; none is a promised saving from this change.

### Implemented reuse

| Data/work | Change | What remains live / invalidates reuse |
| --- | --- | --- |
| Field-menu typography tree | `field_menu.apply_text_size` skips its recursive descendant walk on stable frames. | Font size, text scale, base multiplier, theme replacement and newly attached descendants trigger formatting. Geometry still follows dragging/resizing; the Sol screen retains its resize handler. |
| Local wildlife home layout | Sightings builds a cell-to-first-entry index alongside its existing local-entry cache. Inspection copies one matching entry instead of the entire nested list. | Existing sector, terrain, state/habitat and nested tuning invalidation remain authoritative. The index follows the original first-match ordering and isolates callers. |
| Home recovery record | `wild_home_view` copies one record; non-home inspection never copies the full population. | Active occupant and recovery countdown are read freshly. No recovery clock is cached. |
| Wildlife floating text | Stop constructing reaction, traversal and input-hint strings for labels that production presentation always hides. | Observations and menus still request their captions from existing owners. This preserves the newer hidden-title contract; the older reaction-title fixture is not its authority. |
| Hidden wildlife locomotion | Reset on becoming hidden or receiving a different committed target, rather than every hidden frame. | Visible interpolation, animation and committed motion continue normally. |
| Leaf and ground reserve inputs | Both projections use `flora_reserve_fraction`, avoiding full reading dictionaries, trait copies, root lookup and trace derivation when only energy/capacity is needed. | Ratio uses current energy and the existing held-reserve memo, preserving its tick invalidation and same-tick refill behavior. Missing plants remain distinct from empty reserves. Existing transition/upload guards remain. |
| Inspection terrain/plant reads | Subject naming accepts the readings already fetched by `describe_cell`. | Raw generated terrain stays separate from mutable environment overlays. Other naming callers still fetch fresh data. |
| Inspection appearance layout | Repeated identical appearance text and control state no longer force font measurements and card fitting. | Reading changes, appearance/control changes, viewport resize and existing expand/minimum-size handlers still update layout. |
| Vastra actor exclusion uploads | Reuse identical actor arrays for the same destination materials. | Positions, visibility, ordering, rebasing, radius and replacement materials change the result. Actor collection still runs; this does not cache moving actors. |
| Vastra distance uniforms | Write effect range/fade only when their per-material inputs change. | New materials, study mode and live distance tuning are checked; clocks, sunlight and transitions continue. |
| Audio emitter/volume work | Zero camera shift skips emitter traversal; settled incoming beds skip repeated gain-to-decibel conversion and volume writes. | Changed gain/trim and new beds update immediately; outgoing fades, playback and suspension remain live. |

### Other stable inputs found

These are audit findings, not additional implemented savings or a claim that all
runtime work is now cached:

- **Already reused:** terrain height/normal/slope/pond/geography data; prepared
  plant meshes and palette; scenery picking bounds/inverse transforms/mesh data;
  wildlife behavior resolutions and retained species views; move-book templates;
  battle tiles/markers/views and settled HUD layout; inspection reading content;
  ground/leaf reserve uploads; plant event routing; Vastra anchors/edges/transfer
  curves; audio bed identity, suspension and zoom blend. Extend their owners
  rather than adding competing caches.
- **Plant weather material membership:** model pieces/surfaces share materials;
  unique material registration could replace repeated surface traversal and
  duplicate writes. A trial per-call deduplication was removed before delivery:
  `plant_library.gd` participates in baked-palette source fingerprints. It is
  byte-identical to its pre-task version. A deliberate prepared-asset compatibility
  update belongs with this optimization; silently causing procedural fallback
  would undermine the purpose.
- **Camera/ground presentation:** repeated camera projection/orbit inputs,
  root-origin material bindings, compass sectors, selection terrain alignment and
  stationary player shadow samples are stable under unchanged inputs. Terrain
  sampling already has bounded caches. Any pose cache must preserve smoothing,
  camera clearance, rebasing, new materials and calls after simulation moves.
  Prior measured camera cost is small, so no blanket frame guard was added.
- **Wildlife/companion support:** stationary surface samples, grounded traversal
  fields, model capability checks, selected identity/profile reads and caption
  prefixes are potential reuse points. Gait settling, body support, idle poses,
  flight/swim transitions and animated bounds cannot be frozen just because the
  committed grid cell is unchanged.
- **UI beyond typography:** HUD geometry, combat card names/metadata, move
  descriptions/style boxes and log prefixes often remain unchanged. Their
  content/layout has several independent owners, including playback snapshots,
  readiness plans, minimum-size settling and dynamically created controls.
  No broad UI refresh was disabled.
- **Atmosphere/swarm presentation:** current/previous weather selection is stable
  within a weather slot; shadow/sky settings are stable until tuning changes;
  swarm seeds, radii/state flags, affinity tint and warning layout often remain
  unchanged between simulation ticks. Daylight, wind, rain, particle time,
  transitions, camera rebasing and active ecology remain dynamic.
- **Validation/source scans:** validation results already have consumer memos,
  but matching nested mutable Resource graphs still traverses their inputs.
  Direct in-place Inspector/script edits are an existing supported contract;
  identity-only checks or reliance solely on `Resource.changed` would miss them.
  Removing that traversal needs a complete mutation/revision contract, not an
  assumption that a resource stayed unchanged. Vastra's periodic living-source
  scans likewise need reliable membership/tuning invalidation before removal.

### Focused verification and limits

Godot 4.7.2 completed import with no script/parse errors after APPDATA was
redirected into the ignored local artifact profile. It still emitted an editor
safe-save error, so this is not a clean import pass under the shared validator's
strict error rule. The initial default-profile attempt also reported inaccessible
editor/user-data directories; both environment attempts are retained.

Five focused headless suites passed: runtime work reuse **3,388**, leaf reserve
links **35**, inspection card **27**, live menu window **31**, audio framework
**47** (**3,528 checks**). Added coverage compares lightweight reserve reads
against full live readings across trees/plants, held transfers, partial refills
and ecology settings; exercises home-index ordering, mutation isolation and
terrain/sector invalidation; and checks late menu controls and direct text edits.
The existing shared validator already includes both extended suites.

One rendered inspection run passed its **27** assertions; its examined capture
under `artifacts/inspection/` has legible controls and facts. Vulkan initialization
reported missing surface support and automatically fell back to D3D12 Forward+
on the RTX 3070, so this is not a clean Vulkan validation result. No repeated
journey study, full validator, export or target-device run was performed. No
new whole-game frame-time/FPS saving is established. Changes remain uncommitted
alongside the preserved pre-existing work; no staging or push occurred.

### Repeated text, material and visual updates — follow-up November 1

Owner requested implementation of this next opportunity. Bounded follow-up:

- Combat cards retain formatted names/metadata until those identity fields
  change. Health fills and move-button styles retain their resources until the
  health color band or affinity tint changes, rather than allocating replacements
  on every HUD refresh. Health values, tweens, statuses and legality remain live.
- Terrain selection retains its terrain-derived position and bar alignment for
  the same target, terrain identity and selection membership. Camera rebasing
  still moves the parent. The signature holds instance IDs rather than retaining
  an obsolete terrain after a new expedition/load.
- Shared ground materials skip identical world-origin writes. The guard checks
  the actual uniform, so a different consumer's intervening write is corrected;
  it does not assume exclusive material ownership.
- Compass and day/night button text skip identical assignments. Clock/weather
  text is formatted only when the displayed minute/weather/transition state or
  destination label changes. Shadow configuration and sky-shape uniforms update
  when their inputs or destination light/material change. Saved-clock daylight,
  wind, rain, cloud motion and other live lighting work still run.

Godot 4.7.2 focused checks: **50 atmosphere** and **192 runtime hot-path** checks
passed (**242 total**) with no engine/script errors. The atmosphere suite retains
its expected invalid-settings warning fixture. Added checks cover shared-material
origin restoration, hover changes, direct sky/shadow edits, retained style
identity and live low-health styling. Both suites already belong to the shared
validator. An initial hot-path pilot logged missing-metadata errors despite
passing assertions; the guard now tests `has_meta`, and the final run is clean.

One rendered hot-path check, explicitly selecting D3D12 Forward+ on the RTX 3070,
passed **192 assertions** with an empty error log. The inspected combat capture
under `artifacts/optimization_pass2/combat-layout.png` retains readable cards and
the deliberately long test text within its tray. Prior capture, pre-edit sources,
pilot and final logs are preserved under `artifacts/repeated-presentation/`.
Scoped diffs and CRLF-aware whitespace checks passed. No broad validator,
additional profiling or FPS-gain claim; work remains uncommitted on the existing
`codex/performance-baseline-stalls` branch, preserving earlier changes.

### Expanded startup pipeline preparation — November 1, 2026

Owner requested preparing rendering pipelines earlier. Reused the baseline's
surface/draw compilation evidence and the existing early MSAA/SSAO/environment
setup and hidden ring/ember examples, rather than restarting the profiling study.
[Godot's pipeline guidance](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
supports adding hidden representative instances to the tree before first use
for Forward+/Mobile. This is preparation, not a portable compiled-driver cache
or proof that every first draw is covered.

`battle_controller.prepare_board_rendering` now also retains a field-shader
marker, opaque unit ring, emissive arena boundary and non-emissive grid sample.
The boundary/grid samples use position-only ImmediateMesh triangle surfaces to
match the real vertex formats. Shared field, ring and line builders serve both
startup and actual combat, preserving the live material/mesh settings. Preparation
is idempotent, hidden and process-disabled, with no actors or TacticalBattle.

`battle_feedback` uses one cue builder for live feedback and two hidden startup
examples. They expose billboard text, pulse sprites, Vastra ribbons and the
optional installed distortion impact's drawing resources. Prepared particle
emission is disabled before tree attachment; examples never enter the live cue
queue. Existing feedback/impact switches and missing-asset fallback are retained.
The fixed 24x24 pulse texture is generated once and shared with live cues.
Reset/load clears actual cues while retaining the small preparation tree.
This does not preload every species, enable unused rendering features, change
export presets, or invalidate/rebake prepared plant assets.

Focused Godot 4.7.2 checks passed: **30 battle feedback** and **32 readiness arena
UI** assertions, including preparation identity, no emission, hidden/disabled
examples, unchanged saved state and no started battle. The existing validator
already runs these suites. A short optional rendered path is available through
`tests/battle_feedback.gd -- --pipeline-smoke`; use the pinned engine with
`--rendering-driver d3d12` on this workstation. It passed **11 assertions**,
native exit 0 and an empty error log on D3D12 Forward+/RTX 3070. The capture
`artifacts/pipeline-preparation/feedback-smoke.png` was visually inspected.

That single rendered sample reported mesh/surface/draw compilation counters
**51/57/27** after startup and **51/57/30** after two live feedback samples.
Thus no additional mesh/surface compilations were observed in that window, but
three draw compilations remained; their individual source was not isolated.
Counter updates may be delayed. Retained OS/driver caches, one run and no paired
baseline prevent a measured hitch-reduction or startup-cost claim. Startup does
more preparation and retains additional examples; its time/memory tradeoff has
not been quantified. Disabled emission also does not establish that every
particle simulation pipeline was exercised.

The preceding rendered full-feedback pilot failed mouse-confirmation/feedback
assertions and a recap child-type assumption (`ScrollContainer` versus
`VBoxContainer`), then exited 1. Its partial pipeline counts and logs remain in
`artifacts/pipeline-preparation/render*`; it is not an accepted full rendered
journey, and the small smoke does not clear those fixture failures. The two
focused headless suites passed independently. No repeated journey campaign,
full validator, export or target-device check was run.

Pre-edit sources and all receipts are under `artifacts/pipeline-preparation/`.
Scoped diffs and CRLF-aware whitespace checks passed. The checkout was on
`codex/chunk-spiral-loading` when this slice began editing; existing and concurrent
work was preserved. These changes remain uncommitted; no staging, push or merge.

## Plant sharing experiment — November 1, 2026

Owner authorized testing while preserving vegetation as the core game system.
`tools/profile_plant_sharing.gd` uses a disposable headless main scene with 740
canonically admitted active plant nodes. Four alternating-order CPU rounds compare
the existing nearby ecology query against the existing regional index. All 196
ordered-result comparisons across 49 focuses and four limits matched. Each timing
round runs 196 queries: mean 110.428 ms original versus 76.401 ms regional
(30.8% less). This is query cost, not whole-frame improvement.

A second unchanged-snapshot fixture requests each cell's environmental reading
three times. A per-cell memo reduces mean cost from 7.066 to 2.955 ms
(58.2% less), with identical concentration checksums. This deliberately
creates repeated reads: it does not establish production reuse frequency, complete
reading equivalence under mutation, or safe cross-tick caching. Shared timing alone
does not justify shared reserves or environmental values across different cells.
Keep each entity's capacity, reservations, elapsed credit and conserved transfers.

Results/log: `artifacts/plant-sharing/results.json` and `run.log`. No production
plant-system changes or FPS claims. The fixture also records 120 explicit clock
and refill calls as diagnostic observations, not a representative gameplay study.

Owner proposed establishing terrain/entities before simulation and noted the
missing loading screen. Current main scene directly loads world_3d; clock advance
precedes incremental flora preparation in world._process. A future startup gate
should draw a loading scene before expensive world construction, permit canonical
flora/entity preparation while holding simulation/input, then release at a bounded
starting-area readiness condition. It must not wait for every distant chunk or
block preparation with the same pause flag used to suspend gameplay. This is a
proposal, not implemented by the sharing experiment.
