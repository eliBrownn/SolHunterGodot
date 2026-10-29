# Owned exploration companion

Latest content: all eighteen current classes now have a playable first form.
The twelve new class representatives use the same selected-owned follower and
their own `<species>_moment` idle branch, signature rig controls and caption.
Existing following, legal routing, pause, save/load and ownership rules remain.
See the [class-coverage review](sol-class-coverage.md) for scope and evidence.

Current status: the initial ground slice below is extended by
[owned flight and swimming](#owned-flight-and-swimming-integration). Current
validation evidence for that integration appears in the same section; the earlier
shared-project failures below describe the original delivery, not a current audit.
The [normal F5 game](sol-species-data.md#normal-game-rollout) now admits Crown-Ear,
Reedback, Bellroot, Ashquill, Rattlehorn and Rimefold. Use the existing capture/party workflow, then **Set active**
to see that individual follow with its species movement and idle behavior.

Owner follow-up: apply the new small/cute first forms. Ashquill, Rattlehorn and
Rimefold now use the same catalog lookup for wild, battle, companion and menu
views. Their ground-only followers select the inherited `ashquill_preens`,
`rattlehorn_footing` and `rimefold_investigate` idle branches. These cue the existing
model signatures with the existing rest/moment timings, and captions describe the
actual gesture. Affinity comes from the owned individual; no trust reward, new
ownership record, flight or swimming capability is introduced.

October 28, 2026. Owner-authorized Job 2: selected owned presence, safe following,
rest and one readable personality moment. Pursuit, wild groups, opening rescue,
trust, upkeep, mounts and additional combat rules remain outside this slice.

## Source and behavioral contract

Read-only SolHunterSource checkout ref
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`:
`src/systems/world/party_follower.py`, `tests/test_party_follower.py`, and its
`src/core/game.py` sync/movement/update callers. These present an existing owned
identity, use bounded legal navigation, reconstruct presentation on load, and hide
it during encounters without auto-deploying. Source follows party slot one;
this assignment explicitly selects the active owned party Sol instead. Live
relocation recovery is not imported. Checkout cleanliness was not independently
verified; no private files were copied.

`ExpeditionState.active_sol_view()` and `individual_view()` remain the
selection/ownership/affinity authority. No second individual, ownership record,
follower position or trust data is saved. Current-format load retains the actual
selected identity and reconstructs a legal adjacent presentation, rather than
promising exact follower-coordinate restoration. This slice does not change any
save/domain/generation version; concurrent work retains version authority.

`owned_companion.gd` is separate from wild movement, rigs and state.
`owned_companion_policy.gd` uses bounded cardinal search, world traversal, saved
barriers and current wild/player-destination reservations. Catalog species also
use their existing body dimensions and published `sol_clearance_bounds`/corridor
contract. Search shrinks to published scenery or waits; unknown geometry is never
assumed clear. This ground adapter grants no flight/swimming permissions.

Choose a starter or **Sols > Set active**. The same owned model/affinity appears
beside the player, follows, and stops nearby. Blocked routes cause waiting, not
teleporting. A player walking onto it prompts a legal step aside. It does not
block the player's movement or reserve authoritative cells against wild AI.
Pause freezes movement/personality time. Encounter entry hides/freezes it and
withdrawal restores it without auto-deployment. Culling and view rebuilds retain
position. Selection/load admits an adjacent view; a never-admitted view retries
when no legal cell exists. Profile/level updates cannot relocate a present Sol.

The existing behavior hierarchy is reused by
`resources/owned_companion_behaviors.tres`: shared `idle`, then
`crown_ear_listen` (species `sol_species_0001`) and `bellroot_tend`
(`sol_species_0003`). They cue existing signature animations from the approved
[Crown-Ear listening](reference/sols/crown_ear.md) and
[Bellroot tending](reference/sols/bellroot.md) intent. Other species rest without
invented gestures. Walking interrupts the moment. This is ambient companionship,
with no trust, affection, ecological or resource award and no new command UI.

## Adjustable controls

Open **Expedition Tuning > Companion Settings**, or edit
`resources/owned_companion_settings.tres`. Changes apply on subsequent updates;
an in-progress display step retains its duration. Editor-file edits require a
restart unless made through Godot's live remote resource. Defaults are provisional.

| Setting | Default / valid range | Connected effect |
| --- | --- | --- |
| Enabled | true | Hide/show without deleting ownership |
| Admission Side | west; west/east/south/north | Preferred adjacent side on selection/load, with legal fallbacks |
| Stop Distance | 1; 1-3 Manhattan cells | Follow comfort distance |
| Resume Distance | 2; 2-6, greater than Stop | Follow hysteresis |
| Step Seconds | 0.2; 0.1-1 seconds | One legal cardinal display step |
| Search Cells | 128; 16-512 cells | Path work budget |
| Search Radius | 12; 4-32 Manhattan cells | Search extent, reduced by known scenery |
| Visible Radius | 24; 4-32 Euclidean cells | Presentation culling |
| Rest After Seconds | 4; 1-30 active seconds | Delay before species idle moment |
| Moment Seconds | 1.5; 0.5-4 active seconds | Caption and signature duration |
| Behavior Library | inherited idle branches | Eligible species/class/affinity specialization |

The component reuses `SolSpeciesView`, `SolOrb`/creature animation, grounded
locomotion and `SolMotionTrack`, with bounded active frame time and no offline
catch-up. Blocked-route and initial-admission retries are limited by Step Seconds,
rather than repeating the path/clearance search every render frame. It does not
duplicate the active flight/water mode or animation work.

## Validation and open work

`tests/owned_companion.gd` is registered in `tools/validate.ps1`. It covers bounded
detours, blockers/reservations, step-aside, actual owned identity/affinity, legal
admission, personality without domain changes, pause, a short refuge-to-wilderness
route, real encounter entry/withdrawal and return, culling/rebuild, current-format
save/load, body clearance and enable/disable. Logs are in
`artifacts/owned_companion_test.log`, `artifacts/owned_companion_rendered.log`, and
`artifacts/owned_companion_validation.log`; capture: `artifacts/owned_companion.png`.

Final ground-slice evidence: 40 checks passed headless and rendered with clean
logs in `artifacts/owned_companion_final_headless.log` and
`artifacts/owned_companion_final_rendered.log`; the latter capture was visually
inspected. The route includes actual encounter entry, withdrawal, walking back
to the refuge and real save/load. It uses completed legal exploration edges in
the test fixture; it is not a real-input or owner-playtest acceptance claim.
The complete validator retry passed the 2,389-check smoke journey, then stopped
at parsing errors in `tests/world_generation.gd:18,29,30,41-44`
(`artifacts/owned_companion_validation_retry.log`). A separate existing-suite run
also reported empty mesh-surface errors in `scripts/presentation/solid_chunk.gd:136-137`.
No full-project clean pass or device/performance acceptance is claimed. An earlier
headless run passed assertions then had a process-exit crash; the focused rerun
and rendered run both exited successfully. Shared world/mesh work was active
during these checks, so this is functional slice evidence, not a controlled
performance comparison.

Flight/water companion integration must consume Job 1's stable interface after
delivery. Opening rescue/guidance, player-issued companion interactions, longer
off-path recovery, owner feel and AYN Thor performance acceptance remain open.
Current species scale, label style and gestures are not final art acceptance.

## Owned flight and swimming integration

October 28, 2026 follow-up: the delivered wild traversal contract now also serves
the selected owned companion. `OwnedCompanionTraversal` adapts its local route to
`SolTraversalPolicy.can_step`, `can_land`, `changed`, `water_mode`, `cell_valid`,
and `presentation`, plus the selected species' existing `SolTraversalProfile`.
The adapter replaces neither wild navigation nor the shared rigs/state schema.
Reference reconciliation remains the source follower implementation/tests/callers
at `d6f0902d77ed46a2f7d251c354792a4cc9210bc4` documented above, together with
the owner's movement direction and the delivered
[flight/swimming contract](sol-flight-and-swimming.md). The reference follower
alone did not implement these Godot traversal modes.

Crown-Ear uses a cleared stationary takeoff, legal air corridors, then a validated
landing when the player stops nearby. Failed or newly occupied landings remain
airborne; a blocked launch waits or uses a legal grounded route. Reedback follows
legal banks into water, distinguishes shallow wading/deep swimming, and exits via
the shared shore transition. Ordinary player/ground permissions are unchanged.
The follower does not grant flight/swimming based on affinity. Water and air cells
remain visible only when the shared capability/mode validates them.

All routes still use the bounded owned search, current wild/player reservations
and published scenery envelopes. The prepared geometry radius also bounds air
and swimming searches; missing scenery is never interpreted as clear space.
Grounded portions of swimming retain the grounded body sweep. Idle personality
moments require ground, so listening/tending cannot interrupt a landing or swim.
An unsupported landing or an idle swimmer without an available land route waits
in its valid mode; no teleport-to-bank recovery is introduced.

The follower mode is transient presentation, consistent with the original slice.
Current saves retain the selected owned individual; load/state replacement starts
a legal ground admission without recovering a stale water/air position. There is
no second wild roaming row or domain/save/generation version change. Pause and
encounters freeze the existing local clock and queued steps, including transitions;
withdrawal resumes that view rather than creating an extra combat deployment.

Capability, altitude, draft, shore step and animated-body envelope remain editable
on the species traversal resource. They are read when a selected presentation is
created/reconstructed. Step Seconds controls both owned step and transition
duration; an already-started transition retains its duration. Shared presentation
phase is adapted from tick units to that duration, while wingbeats/strokes keep
using the follower's active seconds. All existing stop/resume, search, culling and
idle controls remain connected. These defaults are provisional.

`tests/owned_companion_traversal.gd` adds 30 checks: launch/landing timing,
water crossing, blocked/occupied clearance, legal bank transitions, real selected
Reedback and Crown-Ear controllers/models, pause/encounter freezing, independent
affinity, unchanged ownership/domain state and safe state replacement. Controlled
shore terrain isolates transition contracts; the original 40-check owned suite
still exercises generated scenery and actual encounter/return/save-file IO.
Both suites are in the shared validator. This functional evidence does not close
owner movement-feel, long off-path recovery, opening rescue, interactive commands,
or AYN Thor performance/acceptance.

Integration verification: all nine affected suites passed cleanly, totaling 501
checks, with zero engine/script errors and successful exits. This includes wild
flight/swimming (85), owned exploration (40), new owned traversal (30), ecology,
hierarchy, natural movement, activity, encounter initiation and Sol menu selection.
Results and per-suite logs are indexed in
`artifacts/owned_traversal_regressions.json`. The rendered generated-world owned
journey also passed its 40 checks; `artifacts/owned_companion_flight.png` was
visually inspected (`artifacts/owned_traversal_rendered.log`). Import passed.

The full validator stopped after `tests/sol_creature_models.gd` printed 93 passing
checks but the engine exited with `-1073741819`. A direct isolated repeat of that
model suite reproduced the same exit; it does not load the companion component.
Evidence: `artifacts/owned_traversal_validation.log` and
`artifacts/owned_traversal_model_retry.log`. No full-project pass is claimed.
