# Combat consequences and outside command positions

Phase 2 implementation, October 28, 2026. Follows the
[combat roadmap](combat-roadmap.md) and [sequenced resolution](combat-sequencing.md).
The owner's follow-up requires the trainer to run to the side farthest from the
enemy, free the old tile, and throw from the actual command position.

## Consequence presentation

Resolution records now name poison damage and duration/expiry, heat damage and
spread, connected Lightning discharge, field expiry, protection, class damage
modifiers and changing passive conditions. Damage-modifier explanations come from
the calculation used by actual damage, not a second UI formula. Read-only previews
do not collect records or change passive state.

Footing/phasing readiness, wind displacement, Quantum repositioning, stabilization,
and entanglement use their actual domain flags/positions. Status cards show those
flags from the presented snapshot. Environmental ticks have a named cause and no
invented acting-Sol identity. They do not count as successful moves or grant a
second activity/training contribution.

Field expiry, heat spread, and connected discharge group affected cells into
bounded records rather than pausing once per tile. Actual per-unit HP changes
remain separate. The existing Consequence Seconds setting controls these holds;
there is no new gameplay timer, status duration, capture modifier, or balance rule.

HP/text-only steps reuse the existing arena view; placement, movement, terrain,
target highlights, palette changes, and view reconstruction still refresh their
geometry. This avoids recreating the full arena for every consequence cue.

Two existing field-command defects were reproduced during the audit: unchanged
wind could displace a Sol, and existing rough ground could become a barrier,
while execution returned rejection. Success now checks the final intended barrier
and displacement effects. A genuinely unchanged field still rejects without
spending an action or recording affinity activity. This is an explicit correctness
fix, not a new balance rule; before/after probes are retained with validation logs.

## Capture, outcomes, and retry

A failed Seal has an explicit failure step before enemy activation. Success,
victory, and exhaustion have named outcome steps after the final meaningful
consequence. Retreat retains its confirmed outcome path, including before release.

Only after playback settles does the existing completion authority receive the
terminal packet. The controller freezes its serial, HP, outcome, imprint, and
capture/reward details before the first attempt. A rejection keeps the battle,
active-save guards, and resolved state, shows **Retry result**, and withholds the
success recap. Ordinary action callbacks cannot implicitly retry.

Retry submits that same packet without repeating a move, capture roll, or enemy
activation. Success clears retry authority and commits once through
`ExpeditionState.complete_battle`. State replacement clears queued work, retry
context, and obsolete trainer routes. No mid-battle save format was introduced.

## Trainer departure and release origin

The former sideline behavior was cosmetic: it reserved the old trainer tile and
kept measuring release distance there. Live battle entry now stages a shared
`BattleCommander` route before creating an active persistent battle.

- Search the arena plus its one-cell outer ring using bounded cardinal paths,
  actual Godot traversal/terrain, persistent barriers, and enemy occupancy.
- Rank the four outside sides by their midpoint's squared distance from the
  enemy. On the farthest reachable side with legal release space, prefer the
  shortest route. Stable search order breaks remaining ties. If that entire
  side is blocked, consider the next farthest usable side.
- Reject entry without moving the trainer, relocating the enemy, changing
  terrain, or spending a battle serial when no command/release position exists.
- Store the validated destination as the combat trainer position. Legal release
  tiles use Manhattan distance from there and must still connect to the enemy's
  legal arena. The former tile is usable for movement, attacks, and fields whenever
  terrain permits; the trainer is outside the tactical occupancy.
- Run the existing model along that exact route. Deployment waits until the
  model reaches the authoritative throw origin. Running advances no exploration
  clock, AI tick, initiative, or Sol action. The battle menu pauses the route;
  explicit retreat remains available before deployment/arrival.

The root Battle Settings resource exposes **Commander Run Speed**, default
6 world cells per real second, range 1–10. New battles apply that value to the
existing player-model route; editing it does not alter saves or Sol movement
budgets. Invalid values are rejected. See [Inspector tuning](inspector-tuning.md).

Ordinary completion retains the return display along the validated route when
it remains walkable after imprints are applied. If a newly created barrier blocks
that route or the freed origin, exploration resumes at the valid outside command
position. It does not erase the barrier/imprint or place the trainer inside it.
Exhaustion retains refuge relocation. The expedition origin and transient command
position remain separate while active combat cannot be saved.

## Verification and audit

`tests/combat_consequences.gd` is included in the shared validator. It covers
ordered poison/expiry/protection, passive activation/reset, field damage/spread/
expiry/discharge, wind, footing, phasing, three Quantum choices, capture failure
and success, victory/exhaustion/retreat receipts, frozen retry under injected
rejection, save/load rejection, and capture imprint/HP/identity preservation.

Commander checks cover read-only planning, farthest-side/shortest-route choice,
blocked-side fallback, enclosed rejection, legal path steps, a freed origin,
actual throw distance, arrival gating, pause, and blocked-return safety. Existing
scene fixtures explicitly finish departure and use legal approach movement where
outside deployment places a close-range move out of reach. The wilderness fixture
now consumes the battle-owned route rather than inventing a cosmetic exit.

Rendered reproduction:

```powershell
Godot_console.exe --path . --rendering-method gl_compatibility --resolution 1280x800 --script tests/combat_consequences.gd -- --capture-consequences
```

Evidence is under ignored `artifacts/combat-consequences/`; final check counts,
render inspection, performance scope, and remaining acceptance are recorded in the
roadmap checkpoint. Temporary test user-data is isolated under that directory.

Post-implementation audit decisions:

1. Preserve rule order and calculations; add named records around those changes.
   Keep optional explanation collectors absent during read-only planning.
2. Freeze completion before retry so later display data cannot change captured HP,
   imprints, or rewards. Never report a successful result before acceptance.
3. Make one route own the visible run and throw origin; do not hide a second
   reserved trainer tile behind a cosmetic walk.
4. Preserve lasting terrain changes. A blocked return stays at a safe command
   position rather than deleting effects or trapping the player at the old origin.
5. Keep all new timing provisional. Phase 3 still needs ordinary/major encounter
   pacing playtests; this slice does not establish owner or AYN Thor acceptance.

## Mechanics evidence

Read at SolHunterSource commit `115f3e87acc1716c7113523567c01e1666681885`:

- [Commander behavior](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/docs/coordination/commander-combat.md),
  [bounded route implementation](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/systems/tactics/commander.py),
  and [commander tests](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/tests/test_commander_combat.py)
  supply outside command positions, legal release, unchanged enemy anchors,
  rejected enclosed arenas, and no combat occupancy for the trainer. The owner's
  new farthest-side preference supersedes that snapshot's nearest-exit selection.
- [Live capture](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/systems/tactics/live_encounter.py)
  and [combat effects](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/systems/tactics/sol_combat.py)
  establish failure activation, status ticking, and finite expiry. Existing Godot
  formulas and subsequent owner decisions remain authoritative for this slice.
- [Game encounter caller](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/core/game.py)
  returns along a reversed route only if walking it succeeds; otherwise the
  commander remains outside. Defeat retains its separate recovery authority.
- [State-boundary tests](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/tests/test_combat_state_boundaries.py)
  and the roadmap's ownership evidence support explicit failure/retry and no
  phantom positioning events. No private source file was copied into Godot.
