# Current playable expedition baseline

Measured October 28, 2026 for [D0–D1](development-plan.md) and
[terrain T5 preparation](terrain-roadmap.md). Status: a fresh rendered baseline
has been recorded; owner acceptance and performance budgets remain open.

## Tested experience and provenance

The actual `scenes/world_3d.tscn` was walked through real-time movement input actions,
with `smoke_mode` **false**, normal activity-clock updates, roaming/reactions,
ecology and automatic encounters enabled. The waypoint controller follows a
78-step refuge-to-waystone route, returns, walks 20 cells west into negative
coordinates, and returns again. It does not teleport the player during travel,
disable wildlife or substitute a flat generator. Route planning is timed
separately from travel. This is an agent-controlled rendered walkthrough with
inspected captures, not an owner manual acceptance session.

Three separate 60 FPS processes and three separate uncapped processes completed
with **zero journey-check failures**. Each includes initial warmup and a separate
post-load window. OS and driver caches were retained; these are fresh-process
runs, not proven cold disk/shader-cache measurements. Validation was not run
concurrently with the timed studies. Other desktop applications and the Godot
editor remained open; the machine was not an isolated benchmark environment.

Base commit: `96f384ffbd12c227b964b5f433a76901e8c3879f`.
The tested tree had substantial existing tracked edits and untracked work.
The study used `codex/current-expedition-baseline`, preserving those files,
the Bible and the player's normal expedition save. No game tuning or mechanics
were changed by this task.

During the six-run series, concurrent edits changed `battle_playback.gd`,
`tactical_battle.gd`, `combat_hud.gd`, `inspection_card.gd`, `menu_settings.gd`,
related tests and documentation. The before/after source manifest records the
exact hashes and reports drift. Consequently the six timings describe the
evolving combined checkout; they are **not a frozen-revision regression gate**.
No performance difference between these runs is attributed to a particular edit.
The subsequent focused contact study recorded identical before/after source hashes.
The runner now captures source hashes separately before and after every run.

## Functional observations

| Area | Fresh result | Coverage limit |
| --- | --- | --- |
| Traversal | All six outbound/return and negative-coordinate journeys completed; route junctions remained usable; waystone and return objectives fired. Resident chunks remained bounded at 71. | One seed, normal walking and default view. No exhaustive footprints, running or maximum-distance camera sequence. |
| Normal wildlife | Guard warnings were observed; the first complete journey observed 25 individual Sols change position. No AI or encounter settings were disabled. | Ambient population and reactions are those of the current provisional content. |
| Encounters | A separate walk to the existing guard exercised explicit Engage, Observe and Withdraw. The actual identity was discovered; withdrawal resumed exploration and the player returned home. | Zero automatic contacts occurred in the six journeys or focused approach. This does not certify automatic-contact presentation or combat. |
| Pause | The activity tick remained fixed through 60 paused frames. | Menu usability and owner camera comfort are separate acceptance items. |
| Persistence | Each full journey saved, started seed 7, and loaded the saved expedition. Full persistent snapshots compared exactly, covering territories, identities, affinity, roaming, discoveries, clock and stored outcomes. Position/objectives returned correctly. Incompatible loads preserved the live state. | These are current-format saves. No legacy migration work or long-term progression acceptance. |
| Encounter persistence | Saving while face-to-face was blocked. Observe/Withdraw followed by save/load preserved the complete snapshot and guard discovery. | No mid-battle save or resolved battle outcome was exercised in the rendered study. |

Captures inspected: refuge, waystone, negative-coordinate route, restored refuge
and face-to-face guard. The sampled route stayed visually open and readable.
At the negative-coordinate view, foreground branches cross the trainer's lower
body; canopy/actor readability merits a camera-angle review before denser scenery.
These few views do not prove absence of floating props or occlusion everywhere.

## Desktop measurements

Godot **4.7.2 stable**, Forward+, Direct3D 12, RTX 3070; actual viewport
**2560 × 1369**. The hardware manifest records Ryzen 7 5800XT, approximately 32 GB
RAM, Windows and GPU driver details. These historical captures used the then-current
default view and scenery Resources, including 72-cell render distance, 48-cell shadows,
one chunk published per frame, SSAO and 4× MSAA. Exact relief, climate, palettes,
density, view, atmosphere, encounter and sighting settings are in every profile.
The later stutter fix defaults to 2× MSAA and a 36-cell decoration distance;
see [Inspector tuning](inspector-tuning.md) for the active controls.

Frame times below are wall-clock intervals, including ordinary CPU simulation
and scheduling. Uncapped runs disable v-sync and the frame cap; they are not
isolated GPU-only throughput measurements.

| Run | Outbound p95 / p99 / worst ms | Return p95 / p99 / worst ms |
| --- | --- | --- |
| 60 FPS 1 | 16.68 / 18.49 / 36.64 | 16.68 / 16.70 / 40.77 |
| 60 FPS 2 | 16.73 / 17.31 / 35.73 | 16.73 / 16.82 / 38.90 |
| 60 FPS 3 | 16.72 / 21.57 / 40.16 | 16.69 / 20.72 / 43.56 |
| Uncapped 1 | 6.90 / 15.66 / 42.58 | 7.09 / 14.83 / 44.96 |
| Uncapped 2 | 6.32 / 15.37 / 53.44 | 6.33 / 14.05 / 45.25 |
| Uncapped 3 | 7.78 / 16.50 / 48.86 | 6.63 / 14.86 / 43.87 |

| Measurement | Six-run observed range / maximum |
| --- | --- |
| Synchronous initial scene construction | 1,362–1,487 ms; excludes engine launch and time before script execution |
| New-expedition rebuild | 703–759 ms |
| Load/rebuild | 679–734 ms |
| Save | 17–22 ms |
| Initial warmup p95 / p99 | 17.69–27.66 / 26.99–37.20 ms |
| Negative-coordinate travel worst frame | 75.03 ms across outbound/return samples |
| Individual chunk generation / publication maximum | 10.39 / 12.40 ms |
| Render draw calls / primitives peak | 1,315 / 944,669; whole-scene frame monitors, not unique asset triangles |
| Engine static allocation peak | 140–195 MiB across runs; not total process or graphics memory |
| Actual game-process working-set peak | 613 MiB in the separate contact study; not the six travel runs' peak |

The first version of the memory sampler followed the console launcher and
reported about 8 MB. Those six process readings are **invalid for game memory**
and must be excluded. The corrected runner samples the real Godot executable;
the focused contact run measured 642,969,600 bytes. GPU memory is unmeasured.

Observed performance work: synchronous construction/new/load costs visibly exceed
a frame interval; isolated travel spikes reach 75 ms even though most paced travel
frames stay near 16.7 ms. These are candidates for investigation, not approved
budget failures or proof that one subsystem caused each spike. Numeric desktop
startup/frame/memory and scenery-regression limits remain unapproved.

## Validation and issues

The initial fresh shared-validator run stopped at `tests/battle_feedback.gd`:
21 checks, **two failures** (exhaustion recap/recovery and clearing feedback on
state replacement). Preserve the log as evidence of the combined checkout at
that point. Concurrent battle work subsequently changed the fixture and runtime;
do not assume those failures remain reproducible on the later tree.

The later shared-validator run passed the 21 battle-feedback checks, the
76 D1-foundation checks, ten-seed generation and all preceding suites, then
stopped at `tests/world_interactions.gd`. Its overlapping-target fixture creates
an extra member without `motion`; `authored_sightings.gd:253/259` accesses that
required member field. Three script errors were emitted even though the suite
printed "15 checks, 0 failures." The shared validator correctly failed the run.
This is verified fixture drift; normal constructed Sols in the rendered journeys
did not exhibit that error. It remains a current validation blocker, not evidence
that the overlapping-target runtime path has been accepted.

All 12 remaining unique suites were then run separately with zero engine/script
errors and zero failures: mouse-first UI, mouse controls, running, full 3D,
wilderness presentation, view, atmosphere, live menu window, Sol menu, field menu,
terrain heightfield and terrain integration. The terrain integration suite passed
1,823 checks. An additional solid-3D smoke journey passed 2,506 checks.
`artifacts/current_baseline_remaining_checks.json` records each exit status and
error list; per-suite logs use the `artifacts/current_baseline_` prefix.
These separate passes do not convert the failed shared-validator run into a pass.
Headless passes cannot certify rendered depth/foundation readbacks or the
whole player experience. The captured journeys do not replace those pixel checks.

## Evidence and reproduction

Local generated evidence is ignored by Git:

- `artifacts/current_expedition/baseline-20261028-b/manifest.json`: commit,
  dirty/untracked source and resource SHA-256 fingerprints, hardware, commands,
  run timestamps and source-drift flag.
- Each `cap60-run1..3` and `cap0-run1..3` directory: `profile.json`, logs,
  screenshots and isolated current-format expedition save.
- `artifacts/current_expedition/contact-20261028/`: stable-source contact-study
  manifest, per-run hashes, measured process memory, capture and isolated saves.
- `artifacts/current_baseline_validation.log` and
  `artifacts/current_baseline_validation_after.log`: fresh shared-validator logs.
- `artifacts/current_baseline_remaining_checks.json`: separate completion of
  suites after the validator's stop, with per-suite logs beside it.

Use the pinned Godot executable on this Windows host:

```powershell
./tools/profile_current_expedition.ps1 -Godot <path-to-Godot-4.7.2> -Repeats 3
./tools/profile_current_expedition.ps1 -Godot <path-to-Godot-4.7.2> -Repeats 1 -ContactStudy
./tools/validate.ps1 -Godot <path-to-Godot-4.7.2>
```

The profiler uses Direct3D 12, stores saves under its unique artifact run directory,
and leaves `user://expedition.json` untouched. Specify a new `-RunLabel` for an
explicitly named rerun. The runner stops on failures or engine errors; incomplete
runs must not be counted as passes. The original
`tests/exploration_profile.gd` still enables smoke mode and remains a separate,
historical workload; it is not the normal-AI baseline.

Next: resolve any current validation failures, review the observed synchronous
stalls and occlusion, then repeat matched runs on an unchanged tree with agreed
limits before claiming a regression gate or global scenery acceptance. Owner
journey acceptance, automatic-contact/combat walkthrough, sustained cache turnover,
maximum-view/orbit/running workloads, an actual export and AYN Thor qualification
remain open. D0/D1/T5 are not declared fully accepted by this report.
