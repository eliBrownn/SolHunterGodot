# Vastra integration

Owner direction: [October 28 combat/restoration retcon](decisions/2026-10-28-vastra-combat-and-restoration.md).
This connects the current expedition and battle systems; it does not declare the
storm rescue or D2/D6 complete.

## Connected behavior

`SolMove` exports whether an ability is Vastra-powered, whether an otherwise
support/terrain effect is aggressive, and positive overload/restoration points.
Damage, poison and debuff abilities are inherently aggressive when Vastra-powered.
Offensive terrain entries in the shared move library are marked explicitly.
Default move values are two overload points or four restoration points per
actually affected tile, independent of damage/HP healed. Values are provisional.
Non-Vastra abilities produce no Vastra change. Healing at full HP is legal while
it can restore the environment; a fully saturated restorative tile with no HP
healing available remains a no-effect action. Normal action/turn costs still apply.

`TacticalBattle` tracks signed tile values as abilities resolve, clamped per
application to the development envelope -100..100. It does not add the actor's
tile to target effects or double-count repeated cells in an area. Conditions,
affinity imprints and overload remain independent channels. Enemy abilities use
the same path. Illegal actions produce no environmental changes.

Battle outcome persistence atomically commits the signed values with party,
capture/progression and imprints for victory, exhaustion, capture and retreat.
Failed commits retain the existing retry flow; replaying a completed serial cannot
apply changes again. Concentration is preserved, including sparse partial deltas.
World-state schema 16 identifies signed overload; earlier positive-only state
remains readable through the pre-existing loader. Negative values marked as older
schemas are invalid. No new legacy migration is implemented.

Natural recovery uses the saved bounded queue and active exploration clock.
Both signs relax toward zero without crossing it. A combat sign change starts a
new relaxation epoch; repeated effects of the same sign retain elapsed progress.
Pause and offline time do not grant progress. Human harvesting/disturbance also
works on restorative tiles and retains receipt replay protection.

Restorative assistance uses `maximum_bonus * magnitude / (magnitude + half_strength)`.
It accelerates existing lingering terrain-condition recovery and vacant authored
Sol-home recovery, without spawning wildlife from a read or creating carrying
capacity. Terrain condition stage intervals are rounded upward, minimum one tick.
Wildlife assistance services at most 32 saved homes every eight active ticks,
reducing pending deadlines by the rounded-down bonus. Saved same-tick service
prevents duplicate assistance on reload. This is a bounded first expression of
habitat/population recovery, not a new world-wide habitat-health simulation.

Outgoing direct damage receives a provisional linear concentration bonus only
when ground affinity matches the individual Sol's affinity. It never changes
permanent stats, and move affinity does not substitute for individual affinity.
The current tactical system uses one occupied tile per unit. Broader footprint
combat remains future work. Existing class bonuses remain separate.

## Presentation

Normal 3D play includes at most 24 local cosmetic current ribbons by default,
using subtle refraction and occasional luminous strands. Explicit signed changes
take priority over the sparse ambient sample. Neutral currents are white;
affinity color comes from actual imprinted tile affinity. Richness strengthens
visibility, positive overload adds tangled motion and surges, and negative
conditions retain smooth flow. Rendering never creates or modifies Vastra state.
Inspection shows signed overload and describes restorative conditions.
Matching combat affinity produces a short rising current and percentage cue.

## Tuning and acceptance

`resources/vastra_settings.tres` connects natural recovery, restorative assistance,
environmental damage scaling and local current settings. `resources/move_library.tres`
connects per-ability effects. Restart to change current enable/count; the live
simulation reads settings on active ticks. Saved movebooks retain their authored
move snapshots; omitted new fields use documented defaults. Start a fresh
expedition to review newly authored move flags in the library.

`tests/vastra_integration.gd` covers signed persistence, natural relaxation,
human receipt replay, healing at full HP, legal/illegal affected areas, independent
concentration, atomic battle results, diminishing recovery and signed inspection.
It is registered in `tools/validate.ps1`; results are recorded after execution.

### October 28 validation checkpoint

Godot 4.7.2 stable import completed. Eight focused headless suites passed with
459 checks and zero failures: Vastra integration (38), natural Vastra (93), human
activity (80), affinity moves (70), wild population recovery (53), combat
sequencing (39), combat consequences (64), and inspection cards (22).

The complete validator did not pass: it stopped at three movement/action-budget
assertions in `first_playable_battle.gd` while another active chat changed the
combat action-point system. A separate `battle_feedback.gd` run reported three
failures in expected heal/enemy-damage cue counts, expected post-field enemy
damage, and the tied-affinity recap. These fixtures depend on the changing turn
flow; their failures are recorded rather than changing that other work here.
Source hashes in `artifacts/vastra-validation-start.json` and
`artifacts/vastra-validation-drift.json` identify concurrent code/test drift.
Results describe the evolving shared checkout, not a frozen-revision full pass.

A rendered Direct3D 12 / Forward+ check on the development RTX 3070 completed
without engine/script errors; the inspected capture is
`artifacts/vastra-world-review.png`. It uses explicit runtime fixture areas at
positive and negative overload, ordinary render settings, and no player-save
writes. Smooth/surging currents and negative inspection readings were visible.
This is visual verification, not owner art acceptance, a frame-time comparison
or AYN Thor acceptance. The authored opening remains unimplemented below.

The storm opening, mask/exposure/failure rules, the chosen rescue trio, companion
discovery sequence, refuge barrier visuals, procedural storms and spatial
propagation remain subsequent connected content/systems work. Their approved
direction is retained in the decision record. No exposure rules were invented.

## Current-rendering optimization — October 28

The default 24 ribbons now share one MultiMesh and material, retaining independent
terrain anchors, phases, affinity colors, strength and disturbance. A single
shader-clock update animates the batch; the same shader keeps the unbatched combat
cue path. Explicit batch bounds include the maximum animated displacement. Instance transforms
remain local to the current sample center so distant world coordinates do not
reduce GPU animation precision or inflate culling bounds.

Generated concentration, height and placement are cached in a bounded 256-entry
FIFO. New terrain and rebuilds invalidate that derived cache. Live signed values
remain uncached: local environment changes, battle outcomes, pending combat actions,
state replacement and movement invalidate readings. Distant changes do not.
Idle frames update only animation, while in-place radius, opacity, refraction and
palette edits are detected within 0.5 seconds. Restart to change enable/count.
Sparse local queries inspect saved changes instead of probing empty coordinates;
dense queries retain the spatial bound and both paths retain the same row order.

`godot --headless --path . --script tools/profile_vastra.gd -- --tag=current`
measures 600 current-processing calls
after 120 warmup calls for each synthetic workload, at seed 17 and default settings.
Active time advances outside the timed section. Travel changes the sample center
every six calls; it is not a navigated journey. A paired run on the development
PC, Godot 4.7.2 stable, measured:

| Current processing | Before mean | After mean | Before p95 | After p95 |
| --- | ---: | ---: | ---: | ---: |
| Stationary | 50.81 µs | 1.48 µs | 17 µs | 2 µs |
| Synthetic travel | 193.25 µs | 29.64 µs | 1082 µs | 160 µs |
| Stationary disturbed area | 52.82 µs | 1.49 µs | 18 µs | 2 µs |

This is approximately 97% less current-processing CPU time when stationary and
85% less during this travel workload. Reports are in
`artifacts/vastra-optimization/before.json` and `after.json`. These are single paired
microbenchmarks on a non-isolated development desktop, not whole-frame FPS,
GPU-time or AYN Thor claims. World generation, saves, combat balance and recovery
rates are unchanged by the optimization.

`tests/vastra_currents.gd` covers sparse/dense equivalence, cache bounds and
invalidation, read-only behavior, state replacement and pending combat effects.
Rendered checks also read instance phase/placement and verify animation bounds.
It is registered in the shared validator. The existing integration, natural
recovery and persistent-foundation checks remain the relevant gameplay regressions.
Godot import passed; the focused runs passed 15 headless current checks, 18
rendered current checks, 38 Vastra integration checks, 93 natural recovery checks
and 76 persistent-foundation checks. The new rendered capture is
`artifacts/vastra-optimization/rendered.png`. The earlier full-suite limitations
remain recorded above; this optimization did not rerun unrelated combat suites.
