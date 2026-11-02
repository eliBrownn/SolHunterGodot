# Readable wild Sol reactions

October 27, 2026 — phase 3 of the [Sol behavior roadmap](sol-behavior-roadmap.md).
This implements the Wary, Watching, and Guarding prototypes. Subsequent
[phase-4 ecology profiles](sol-ecology.md) now select these responses and supply
bounded individual tuning; the global controls below remain their base values.
The [activity correction](sol-activity.md) subsequently replaces indefinite
watching/static guard behavior with bounded attention, safe nearby routines and
guard standoff movement. Its controls and domain-14 fields extend this slice.

## Behavior

Sols notice the player inside Reaction Distance and remain alert until the player
reaches Reaction Release Distance. Separate entry/release bands prevent repeated
alert/patrol switching at the detection boundary.

- Wary Sols flee inside Reaction Distance and continue until Flee Release Distance.
  They then watch cautiously. Small movement back into the outer band does not
  restart flight; a new close approach can restart it immediately. After brief
  attention, cautious patrol can resume while the player is still nearby.
- Watching Sols approach inside the detection band, stop at Comfort Distance, and
  reposition at Approach Resume Distance after their cooldown. They watch rather
  than pursuing a withdrawing player beyond the detection band, and resume
  nearby activity after bounded attention.
- Guarding Sols close to Guard Standoff Distance and alternate watch/patrol,
  labeled **Defending territory** or **Patrolling territory**.
  Hostility remains separately authored; neutral Sols do not gain automatic contact.

After disengagement, the individual waits in **Settling down**, returns home if
displaced, and resumes its patrol/rest routine. Close approach interrupts settling.
Terrain, occupancy, home bounds, pause, active simulation limits, and encounter
ownership still apply. Lowering Home Radius prioritizes legal return. No trust,
combat, relationship memory, or ecological effects are added.

Labels read saved response state and remain visible during settling within render
range. Rendering/rebuilding never advances AI. Observation also handles patrol
actions without an unknown-action lookup failure.

## Adjustable controls

**Expedition Tuning > Sighting Settings > Player Reactions**:

| Setting | Provisional default / range | Effect |
| --- | --- | --- |
| Reaction Release Distance | 6 / 2–12 Manhattan cells | Must exceed Reaction Distance and cover Flee Release Distance. |
| Approach Resume Distance | 3 / 2–6 Manhattan cells | Must exceed Comfort Distance; approach also requires being inside Reaction Distance. |
| Reposition Cooldown Ticks | 2 / 1–16 ticks | Minimum spacing between neutral approach attempts, including blocked attempts. Flight is never delayed. |
| Settle Ticks | 3 / 0–32 ticks | Wait after disengagement; zero skips the wait. |

One tick is 0.75 active exploration seconds, quantized by Movement Interval Ticks.
Existing reaction/comfort/flight distances and movement controls remain connected.
Ranges and cooldowns apply on the next decision; existing settling deadlines finish
before a changed Settle Ticks value is used. No new expedition is required. Invalid
runtime tuning suspends local updates.

**Encounter Settings > Warning Delay Seconds** defaults to 0.75 (range 0–5 seconds).
Automatic contact requires the same warning to have been drawn, enough uncovered
active time, and a later completed player step inside contact range. Idle updates,
AI movement, and timer completion cannot open an encounter or stop held movement.
Hidden HUD, Field Notes, confirmation, pause, field menu, and world context menu
cannot contribute uncovered time. Leaving the band, changing target, loading, or
entering protection resets acknowledgement and elapsed time. The delay is live
tuning. Manual Engage and successful-step withdrawal protection retain their rules.

## Ownership and persistence

`scripts/sols/sol_reaction_policy.gd` owns pure responses and captions. `SolRoamingPolicy`
composes those with home return and patrol. The sighting controller commits one
legal step and response atomically. The encounter controller alone owns warning
presentation and encounter entry.

Domain version 12 adds optional `response` state: mode (`alert` or `settling`),
settling deadline, and reposition deadline. Restore validates exact fields, enums,
integral values, and bounded future deadlines before applying state. Acquisition
retires the wild row and its response memory. Warning acknowledgement and elapsed
display time remain runtime-only and reset on load. At the original reaction
delivery, outer format was 2; the current terrain/save work uses outer format 3,
generation 6. Current domain 14 extends response state with attention/routine
deadlines; its patrol counter was introduced by the
[natural movement pass](sol-natural-movement.md).
No new legacy migration work is introduced.

## Evidence and verification

Consulted SolHunterSource snapshot `115f3e87acc1716c7113523567c01e1666681885`:
`src/systems/ai/roaming.py`, `behavior.py`, `encounters.py`, and
`tests/test_water_display_wildlife.py`. The pinned encounter code was read through
the GitHub connector. Local checkout `d6f0902d77ed46a2f7d251c354792a4cc9210bc4`
supplied callers, tests, and `docs/coordination/warning-movement-continuity.md`.
See [mechanics reference](mechanics-reference.md). These establish stopping
distances, flight hysteresis, and displayed-warning/later-step entry. The new
settling, reposition, and display durations are reversible tuning for the owner's
phase-3 request, not final source balance. Bible temperament distinctions remain
authoritative.

`tests/sol_player_reactions.gd` checks behavior boundaries, cooldowns, interruption,
return to routine, connected movement/labels, actual settling save/load, malformed
state rejection, ownership cleanup, pause, covered warnings, target changes, and
delayed later-step contact. The original encounter suite uses zero display delay
to isolate its acknowledgement/step-order contract. The local reaction fixture
retreats away from the displaced Sol rather than into its new flight position.
Rendered capture: `artifacts/reactions/guard.png`.

Final results are recorded in the roadmap. Scripted visual inspection does not
replace owner playtesting of timing, spacing, or warning readability.
