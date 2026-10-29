# Natural movement pass

October 28, 2026. Owner request: address rigid Sol behavior in the next pass.
This extends phases 1–4 of the [behavior roadmap](sol-behavior-roadmap.md).
Subsequent owner playtesting found that indefinite attention could still park
Sols despite smooth movement. See the [activity correction](sol-activity.md):
current domain 14, shorter rests, optional rest arrivals, bounded attention,
safe ambient routines, and guards that move to standoff.

## Behavior and controls

Travel now fills the decision interval by default. Previously, a cell movement
finished in 0.2 seconds and waited for the next 0.75-second decision, creating
an unintended pause at each travel step. Intentional patrol rests, cautious
observation, neutral reposition cooldown, and territory defense remain distinct.

Patrol goals now vary across the local home diamond instead of cycling through
four compass endpoints. Distances vary, the previous goal is excluded, and each
new goal is at least the configured minimum distance from the current cell.
Unreachable goals still use the existing bounded path search and expiry policy.
Rest durations use a separate deterministic stream rather than an incrementing
cycle through the rest range. This changes current prototype routine tuning;
it does not add species, social behavior, ecological effects or relationship rules.

Under **Expedition Tuning > Sighting Settings**:

| Setting | Default / range | Effect |
| --- | --- | --- |
| Local Movement > Movement Travel Fraction | 1 / 0.25–1 | Fraction of the decision interval spent moving each cell. One gives continuous consecutive travel; smaller values intentionally finish early. |
| Wandering > Patrol Goal Min Fraction | 0.5 / 0.2–1 | Minimum Manhattan distance to a new goal, as a fraction of the effective patrol radius, rounded up to at least one cell. |

Movement Travel Fraction replaces Movement Blend Seconds; the supplied resource
uses the new property. Queued segments retain their committed durations, and new
segments use current settings. Patrol Goal Min Fraction affects the next goal.
Existing saved goals and rest deadlines finish first. Existing cadence, home
radius, species radius/rest scaling, and individual variation remain adjustable
and connected. Invalid tuning suspends simulation under the existing validation.

## Display route and persistence ownership

`scripts/sols/sol_motion_track.gd` replays each committed cardinal step in order.
The sighting controller subscribes to individual changes on the active state,
with an ID lookup and a bound-state guard. Thus two simulation ticks before one
view update retain their turn instead of interpolating diagonally to the latest
cell. The queue never writes domain state or chooses AI actions. Pause and
encounter entry freeze it; culling/rebuild/load reset it to saved position without
offscreen animation debt. Old-state subscriptions detach on state replacement.

The fixed eight-segment safety ceiling exceeds normal two-tick clock catch-up.
An unobserved relocation or overflow snaps the display to the authoritative cell
instead of inventing a route. This is display recovery, not simulated movement.
Normal replay remains piecewise linear over legal steps. Terrain navigation is
still cardinal and footprint 1; this pass does not establish larger-footprint or
free-steering support.

`SolRoamingPolicy` selects new goals and rests through fixed `sol-patrol-v1` SHA
streams of identity, saved leg counter, and purpose. Domain version **13** retains
the current goal/deadlines and expands the saved leg from a four-state compass
phase to a bounded counter. Save format stays **3**, generation **6**. No new
legacy generator or save migration is added. Current save/load continues the
same next decision; affinity, combat stats, ownership, and ecology trait samples
are unchanged.

Source evidence: SolHunterSource snapshot
`115f3e87acc1716c7113523567c01e1666681885`,
`tests/test_water_display_wildlife.py::test_overworld_stride_fills_decision_interval_without_midstride_pause`,
read through the GitHub connector. Local reference
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` supplied
`src/systems/world/entity_motion.py` and callers for queued route replay and
per-entity duration. Non-compass goal selection is the owner's requested Godot
routine improvement, not a claim that the older source had already authored it.

## Verification

- Shared Godot 4.7.2 import, all suites and both scene journeys passed **13,855**
  assertions. The new `tests/sol_natural_movement.gd` passed **120** checks both
  headless and with OpenGL rendering: 30/60/144 FPS progress, continuous steps,
  two-turn replay, pause/encounter freeze, culling/rebuild, stale-state isolation,
  varied bounded goals, deterministic replay and invalid tuning.
  Re-running the original audit path `(8,5) -> (8,6) -> (7,6)` now reports zero
  deviation from its legal segments at 0.1 seconds (previously about 0.354 cells).
- Recorded a live, stationary-player view with normal AI enabled in
  `artifacts/natural_movement/frames/`; preview `preview.gif` and `scene.png` in
  the parent directory. Recording performs image readback/writes and is not a
  frame-time benchmark. The overlapping-Sol interaction fixture now supplies its
  own motion track and ID registration.
- Ran `tools/profile_current_expedition.ps1 -Repeats 1 -RunLabel natural-movement-20261028`
  with the pinned engine. Both capped-60 and uncapped D3D12/Forward+ journeys had
  zero failures/errors and unchanged source manifests during each run. Hardware:
  Ryzen 7 5800XT, RTX 3070, approximately 32 GB RAM, viewport 2560×1369, seed
  2601026, 78 outbound and 78 return steps. Evidence lives under
  `artifacts/current_expedition/natural-movement-20261028/`.

| Run | Outbound p95 / p99 | Return p95 / p99 | Sampled peak process working set |
| --- | --- | --- | --- |
| 60 FPS cap | 16.689 / 18.504 ms | 16.684 / 16.874 ms | 659,804,160 bytes |
| Uncapped | 5.944 / 14.809 ms | 5.291 / 13.110 ms | 673,402,880 bytes |

Compared with the three stored `baseline-20261028-b` runs using the same renderer,
viewport, seed and route: capped travel remained around 16.7 ms p95; uncapped
outbound p95 was previously 6.322–7.779 ms and return 6.328–7.090 ms. This single
after-run is a development regression observation, not an isolated causal speedup
claim or approved performance budget. Warmup maxima still exceeded 400 ms.

The rendered journeys verified normal AI travel and current save/load, but both
recorded **zero automatic contacts** and did not exercise combat. Focused reaction
tests cover warning/contact rules; connected encounter/combat acceptance remains
open. Device/export qualification, owner feel review, and the roadmap's density,
larger-footprint and companionship questions remain open.
