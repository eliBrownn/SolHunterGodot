# Sol activity and approach consequences

October 28, 2026. Owner feedback: Sols still mostly stand still and behavior does
not meaningfully change exploration. Owner selected approach/avoidance as the
priority. This is a correction to phases 1–4, not the social-behavior phase.

## Reproduced causes

Noticing the player replaced normal routines with alert behavior indefinitely.
Safe Wary/Watching individuals had no way to resume patrol while the player
remained nearby. Guard actions were excluded from navigation, so an assertive
Sol could only display a warning while holding its original cell. A blocked
approach renewed attention even when no movement occurred. Every arrived goal
also caused a rest, and unreachable patrols could wait through the full timeout.
The previous natural pass improved interpolation and destination choice but did
not resolve these decision-policy problems.

## Current behavior

- **Wary:** urgent close approach still triggers flight. Once safe, watch briefly
  and resume local movement with a player-distance buffer. Both goals and detours
  respect that buffer; a new close approach interrupts activity immediately.
- **Watching:** approach according to comfort/resumption distances, watch briefly,
  then explore nearby instead of staring indefinitely. An uninterrupted routine
  window prevents rapid approach/patrol oscillation. A home-leash or terrain-blocked
  approach no longer renews attention forever.
- **Guarding:** visibly close toward an intruder until the configured standoff,
  then alternate watching and territorial patrol. Do not continue pursuit beyond
  detection range or home bounds. Existing displayed-warning/time/later-player-step
  rules alone authorize automatic encounter entry. AI movement and elapsed idle
  time cannot force combat; backing away remains possible.

Existing profiles still whitelist actual patterns. Idle-only profiles stay idle.
No legal route still means waiting, not teleporting. Nearby-player routines can
produce **Roaming cautiously**, **Exploring nearby**, or **Patrolling territory**
captions. Intentional rests remain, but only a configured fraction of arrivals
pause. New goals reject illegal/barrier cells; blocked routes retry quickly.
The named trail-guard profile now uses radius/rest scales of 1 rather than the
smaller, longer-resting Seedmote routine. Affinity, combat stats, trust and
ecological consequences are unchanged.

## Inspector controls

Under **Expedition Tuning > Sighting Settings**:

| Group / setting | Default / range | Connected effect |
| --- | --- | --- |
| Player Reactions / Attention Ticks | 2 / 0–16 | Brief attention after noticing/repositioning before safe activity resumes. |
| Player Reactions / Routine Ticks | 6 / 1–16 | Safe routine window between attention pauses; danger interrupts. |
| Player Reactions / Guard Standoff Distance | 2 / 1–3 Manhattan cells | Territorial approach stopping distance. Does not change Contact Distance. |
| Wandering / Patrol Rest Chance | 0.35 / 0–1 | Chance that a completed/expired goal starts a rest. Deterministic per saved leg. |
| Wandering / Blocked Goal Retry Ticks | 2 / 1–8 | Abandon a stationary patrol goal after this many blocked active ticks. |
| Wandering / Rest Min / Max Ticks | 1 / 3; each 1–64 | Shorter global rest range, still scaled by profile and individual activity. |

One tick is 0.75 active seconds; decisions are quantized by Movement Interval Ticks.
Edits apply to the next relevant decision/goal. Existing deadlines finish first.
Old alert rows without attention fields receive bounded attention on their next
decision, so loaded parked individuals can recover without a new expedition.
Invalid tuning freezes local AI under existing validation. All defaults remain
provisional, including the activity acceptance workload below.

## Ownership, saves and evidence

`SolReactionPolicy` owns bounded attention/routine windows and interrupting
responses. `SolRoamingPolicy` composes safe ambient patrol with those responses.
`SolLocalNavigation` enforces per-step clearance and guard standoff.
The sighting controller supplies Godot goal legality, handles blocked-attempt
feedback, and commits through the existing persistent authority. This does not
make views or encounter panels an AI authority.

Domain **14** adds optional `attention_until`/`routine_until` response deadlines
and `blocked_since` patrol state. Save format remains **3**, generation **6**.
Restore normalizes integral JSON values and validates exact fields, bounded future
deadlines and nonfuture blocked ticks before applying state. Acquisition retires
these wild rows with the existing ownership transfer. No new legacy migration
work is introduced.

Source consulted: SolHunterSource `115f3e87acc1716c7113523567c01e1666681885`,
`src/systems/ai/behavior.py`, through the GitHub connector. Its guard policy uses
bounded home territory and permits guard navigation toward a goal; this port had
previously made that action stationary. The local reference at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` also supplied `roaming.py`'s stopping,
observation, and home-limited behavior. Bounded attention, ambient safe movement,
rest probability and retry durations implement the owner's explicit feedback,
not newly claimed canonical source formulas.

## Acceptance measurements

Same seed 17, current profiles, player stationary three cells west of each home,
80 active ticks (one minute), one step counted only when the actual saved cell
changes:

| Posture | Before: moves / 80 ticks | After: moves / 80 ticks | After: distinct cells |
| --- | --- | --- | --- |
| Wary | 0 | 49 | 9 |
| Watching | 2 | 54 | 21 |
| Guarding | 0 | 53 | 20 |

The normal starting seed 2601026 also moved on 45, 43 and 55 of 80 ticks in the
same nearby-player cases. Resting/blocked individuals are not required to walk
constantly. These measurements demonstrate recovery from the parked-state bug,
not universal activity guarantees across arbitrary terrain or tuning.

`tests/sol_activity.gd` passes 42 checks, including all three postures at near/far
player positions across both seeds, bounded stationary runs and legal positions,
interrupted safe patrol, movement-buffer detours, guard standoff, a later-step
automatic encounter, retreat, save/load, corrupt deadlines and blocked-route
replanning. The rendered suite also passes 42 checks; inspected capture:
`artifacts/activity/confrontation.png`. Probe reports and acceptance measurements
live under `artifacts/sol_activity_*`. The original reaction suite now permits
safe patrol after watching instead of requiring perpetual idle.

Shared Godot 4.7.2 import, all suites and both scene journeys passed **16,046**
assertions in `artifacts/sol_activity_validation.log`.

The existing D3D12 contact study now also records **one real automatic encounter**,
zero failures/errors, explicit Engage/Observe/Withdraw, save/load, and return
travel. Fixed its route logger to handle encounters on the final waypoint: the
earlier zero-contact report had missed that case and treated the already-active
encounter as the later manual action. A direct live trace confirmed the actual
automatic transition before correcting the logger. Evidence:
`artifacts/current_expedition/sol-activity-contact-fixed-20261028/`.

That run measured approach p95/p99 16.689/22.312 ms, return 16.897/20.699 ms,
and sampled peak process working set 636,010,496 bytes on the Ryzen 7 5800XT /
RTX 3070 at the profiler's 60-FPS cap. Its source-drift flag is true because a
concurrent edit changed only `scripts/ui/ui_text.gd`; AI files were unchanged during
the run. Treat this as functional evidence and diagnostic timing, not a clean
performance comparison or device budget. Other rendered project review work was
also active during this task.

Owner feel acceptance, broader combat/companion behavior, density and AYN Thor
qualification remain open. The rendered study is automated; it does not replace
the owner's playtest.
