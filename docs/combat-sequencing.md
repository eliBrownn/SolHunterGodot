# Sequenced combat resolution

Phase 1 implementation, extended by phase 2 on October 28, 2026, following the
[combat roadmap](combat-roadmap.md). Owner readability acceptance remains open.

## Behavior

Confirming a target now identifies the acting Sol and move, reveals its effects,
hands off to the next actor, and presents the enemy's movement/action before
returning control. Simple text, existing orbs, legal route markers, HP bars, and
existing feedback carry these steps; no sound or new move animation is required.

The HUD, battlefield overlays, orb positions, log, and right-click HP reading use
the currently presented snapshot. A heal followed by an enemy hit visibly shows
the intermediate recovery even when final HP is unchanged. Movement visits the
legal route's waypoints rather than cutting a corner to the final cell.

Move, movement, end-turn, Seal, withdrawal, and Quantum-choice callbacks reject
new commands during resolution. Buttons show their unavailable state. Inspection
and camera access remain available under existing modal rules. Opening the battle
menu pauses resolution; closing it resumes. An open right-click popup also holds
the current step. Escape retains targeting/menu behavior and never retreats.

The last effect remains visible before terminal completion and battlefield
teardown. `ExpeditionState.complete_battle` still commits one result receipt;
closing a view or finishing a cosmetic cue cannot grant rewards. Active combat,
including playback, remains unsavable. State replacement and controller teardown
clear queued work and detach its old session.

## Ownership and ordering

`TacticalBattle` retains all damage, legality, initiative, status/passive ticking,
field behavior, activity, and terminal rules. A synchronous command still applies
its atomic domain operation without waiting on a timer. Standalone domain callers
retain automatic enemy activation by default.

For live battles, `BattlePlayback` disables that automatic activation and collects
ordered resolution records for the accepted operation. Each record owns a detached
view snapshot, sequence/action identifiers, battle serial, actor and recipient
identity where applicable, cue, and legal movement route. After these records
have been displayed, it advances one enemy activation through the same domain
methods and displays that operation. It repeats only while initiative still
grants the enemy a turn. Faster-enemy deployment and consecutive enemy turns after
a speed/order change remain possible.

The display can lag the resolved atomic operation while input is gated. It never
feeds presentation HP/positions back into rules or replans against a historical
snapshot. `BattleController` uses the live session for commands and completion,
and the playback view for presentation. The renderer never computes damage.

The pending queue contains only one bounded operation at a time, rather than a
whole battle history. Movement records are bounded by the legal arena path;
state snapshots retain only the displayed last 30 log entries. Large frame gaps
and zero cue holds still expose one record per update and cannot skip gameplay
transitions. Advancement does not depend on an animation or sound callback.

## Inspector tuning

The existing scene-root Sol Visual Settings resource contains a **Battle Pacing**
group. These provisional presentation defaults do not affect saved individuals,
turn counts, movement costs, or rules. Edits apply when the next record starts;
the current hold keeps its existing duration. See the complete
[Inspector map](inspector-tuning.md#combat-interface-presentation).

| Setting | Default | Range and unit |
| --- | --- | --- |
| Action Cue Seconds | 0.35 | 0–1 real seconds |
| Consequence Seconds | 0.6 | 0–1.5 real seconds |
| Movement Step Seconds | 0.16 | 0–0.5 real seconds per waypoint |
| Turn Handoff Seconds | 0.4 | 0–1 real seconds |

Owner follow-up, October 28: slow normal combat slightly and leave room for
eventual move animation. The above defaults replace 0.25/0.45/0.12/0.25 seconds.
Existing hit/heal flashes and HP-bar tweens also increase from 0.25 to 0.3 seconds.
The normal game resource inherits these defaults; restart an already-running game
to load the change. No new move clips or animation-completion dependency were
introduced. Earlier pacing reports retain the exact settings they measured.

For this adjustment, import and 173 focused checks passed (sequencing 39,
consequences 64, pacing 70). A rendered sequencing run passed its 39 assertions
but logged two GL texture leaks at shutdown, also reproduced when allowing two
frames after scene teardown. This is not a clean rendered-engine result; no
renderer/creature cleanup changes were made in this pacing adjustment. Evidence:
`artifacts/combat-slower/` import, suite logs, `rendered.log`, and
`rendered-final.log`; the latter's temporary harness only adds teardown frames.

Invalid resources fall back to defaults at admission; runtime duration edits are
clamped, and nonfinite durations act as zero. Setting all holds to zero accelerates
display without changing results or removing command gating. Values need owner
playtesting before pacing acceptance.

## Decision audit and remaining work

Audit after implementation:

- Retained damage/effect/initiative calculations and compared stepped results
  with direct synchronous results. Splitting enemy activation must not invent
  alternation or move status ticks to a different rule boundary.
- Used intermediate snapshots throughout the visible battle; a cosmetic text
  queue with final HP would not solve the owner's reported problem.
- Gated command admission as well as disabling controls, including duplicate
  capture and terminal callbacks. Kept completion under its existing authority
  and tested the active-save guard during presentation.
- Preserved the ordinary one-versus-one baseline and current assets. Sound,
  production animation, additional Sols, new damage formulas, and save-schema
  changes are not part of this slice.

The later [consequence and commander slice](combat-consequences.md) names
automatic causes, status/passive/field changes, capture outcomes, and safe
completion retry. It also connects the trainer's outside run to actual release
range and frees the original tile. Its delivery evidence is recorded separately.
Phase 3 still supplies measured routine-versus-major pacing targets; these cue
defaults do not close owner or device acceptance.

## Verification

`tests/combat_sequencing.gd` is included in `tools/validate.ps1`. It checks separate
heal/hit intermediate states, shared HUD/inspection HP, original resulting state
at zero/slower cue durations, faster-enemy deployment, changed round initiative,
legal path waypoints, command gates, pause/resume, save/load rejection, queue
reset, timing validation, and one-time retained-health completion. Existing scene
suites explicitly advance playback through `tests/battle_test_support.gd` before
checking their final-state contracts; the new suite inspects the pending steps.

Rendered reproduction:

```powershell
Godot_console.exe --path . --rendering-method gl_compatibility --resolution 1280x800 --script tests/combat_sequencing.gd -- --capture-sequencing
```

Captures and validation evidence are under ignored `artifacts/combat-sequencing/`.
Run results and acceptance limits are recorded in the roadmap delivery checkpoint.
Scripted captures are not owner playtesting, production balance, or AYN Thor
acceptance. Source evidence remains the exact commit, implementation, callers,
tests, and subsequent decisions listed in the
[roadmap source evidence](combat-roadmap.md#source-evidence-used-for-this-plan).
No legacy source files were copied into the Godot implementation.
