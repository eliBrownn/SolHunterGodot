# Combat roadmap

Prepared October 28, 2026 from the owner's combat questionnaire.
Status: phases 1–2 implemented; phase 3 measurement tools, revised v2 fixtures,
timing comparisons and owner playtest session delivered. Owner readability/pacing
acceptance and numeric targets remain open. Phase 4 and later remain proposals.

## Direction and scope

Owner follow-up, October 28: finite move uses and an expanded low-tier library are
implemented in [early combat moves](early-combat-moves.md). The 50-move pool adds
class-suited remembered options, small hybrids, bounded equipped passives and a
weak fallback action. These additions are explicitly authorized; earlier phase-4
cost/ability proposals do not prevent this connected early-game slice. Balance
and human pacing acceptance remain open.

Owner-approved October 28 follow-up: use a six-point shared turn budget, with
initial setup costs of two and attack/healing costs of four. Speed grants free
movement; extra movement spends shared points. Actions may occur in either order
and the player explicitly ends the turn. See [action budget](combat-action-budget.md)
for the connected behavior, source reconciliation and provisional tuning. This
specific decision supersedes the earlier no-new-action-cost scope below;
historical pacing measurements do not validate the new economy.

The first priority is to make existing battles clear, responsive, and satisfying.
The owner reports that confirming moves makes the actions happen together, with
insufficient pacing or visual cues. Establish the sequencing logic now using
simple labels, highlights, paths, and existing HP feedback. Sound production and
new character/move animation are deferred; later presentation can consume the
same resolution events.

Routine encounters should be quick, with longer major battles. Positioning,
terrain, and Sol/move combinations should blend and allow player expression.
Numerical duration targets, a new damage formula and larger teams remain
unapproved. Action costs follow the later approved shared-budget slice above.

This combat workstream covers deployment, movement, turn order, moves, statuses,
class passives, field interactions, enemy tactics, capture actions, withdrawal,
exhaustion, and the handoff to persistent outcomes and combat-earned growth.
Coordinate shared systems through the [development plan](development-plan.md),
[Sol behavior roadmap](sol-behavior-roadmap.md), and
[UI/UX roadmap](ui-ux-roadmap.md). The Bible governs design, the
[project standard](PROJECT_STANDARD.md) governs workflow, and the
[mechanics reference](mechanics-reference.md) governs source reconciliation.
Godot remains the world-generation authority.

## Approved adventure and consequence direction — October 28, 2026

Approved follow-up: after storm escape, the rescuers' NPC owner offers a starter,
first protective mask and instruction, including a first teaching battle before
the player journeys through wilderness to the first refuge camp. Author the
opponent, lesson progression and loss/retry behavior separately; no storm combat
modifiers or new reward formulas are approved. Routine victories should emphasize
understanding the opponent and terrain. The first refusal relationship expression
to explore is changed but enduring, preserving the permanent legendary lockout.
See the [follow-up specification](decisions/2026-10-28-opening-companionship-and-consequences.md#approved-follow-up--tutorial-and-visual-identity).

The [creative decision](decisions/2026-10-28-opening-companionship-and-consequences.md)
connects routine strategy, leveling, training, journal discoveries and lore in the
creature-collecting adventure loop. Use authored encounters to assess that combined
payoff alongside readable action sequencing. Journal/lore triggers, reward amounts,
and routine/major encounter durations still need authoring and playtest evidence;
this direction does not grant entries or training merely for starting a battle.

The campaign opens with a storm rescue by three Sols, one becoming the starter.
Do not assume the rescue requires a battle or approve storm combat modifiers.
Production Sols will have species-specific models, behaviors and animations;
orbs remain temporary presentation. Retain the existing resolution-event hooks
for future assets without blocking the current readability work on final art.

For later narrative delivery, refusing the starter's legendary request allows
victory by a harder path and proves its capability without ascension, while
permanently forfeiting its legendary manifestation and producing lasting
relationship/story consequences. Exact consequences are unresolved; do not infer
numerical stat/trust penalties, random disobedience or larger teams. Preserve
starter survival and once-only saved outcomes. This is a D7 dependency, not a
new requirement for accepting phase 1 or a completed ending implementation.

## Phase 1 delivery checkpoint — October 28, 2026

[Sequenced combat resolution](combat-sequencing.md) now separates the accepted
action, its consequences, movement waypoints, turn handoffs, and enemy activation.
HP/status/terrain displays and inspection use the presented state. Commands are
gated during resolution; the battle menu pauses it. Existing completion authority
and active-save guards remain in place. Four Inspector durations are connected.

Godot 4.7.2 import and the shared validator passed **13,735 checks across 41 suite
and journey invocations**, including **39 sequencing checks** and both exploration
journeys. The sequencing suite also passed all 39 checks in a rendered
1280×800 OpenGL compatibility run on RTX 3070. Action, intermediate healing, and
enemy-hit captures were visually inspected. Existing final-state scene fixtures
now explicitly advance presentation rather than assume instantaneous completion.
After the final tooltip/log audit, 91 focused sequencing, combat-interface, and
mouse-UI checks passed again, followed by the 39 rendered sequencing checks.
The tested working tree is based on `96f384ffbd12c227b964b5f433a76901e8c3879f`
and includes existing in-progress work; this checkpoint is not a committed revision.

Diagnostic comparison on the documented Ryzen 7 5800XT/RTX 3070 development PC,
same scene/settings and one end-turn/enemy-hit workload: 180 measured rendered
frame intervals after 120 warm-up frames per mode. Synchronous p95/p99 were
**7.071/13.780 ms**; paced p95/p99 were **7.008/13.624 ms**. Monitored static-memory
peak above the sample's starting value was about **58 KiB / 422 KiB** respectively.
A separate 30-sample domain-only operation probe, excluding deliberate hold time
and rendering, measured synchronous/paced p95 **1.003/1.918 ms**. These compare
coordination modes in the current build, not separate historical revisions.
The rendered probe uses seed 17, the first authored encounter, Bramblepup and
Seedmote, a legal walkable fixture arena, disabled wilderness/movement AI, default
scene rendering with explicit battle framing, and a one-damage enemy strike.
One end-turn command starts at measured frame 60 in each mode. The retained
`performance_probe.gd` beside the logs contains the exact diagnostic workload.

Evidence: ignored `artifacts/combat-sequencing/validation.log`, `rendered.log`,
`performance.log`, and captures. This is a short diagnostic sample, not a broad
performance benchmark or device acceptance; static memory excludes GPU memory.
No numeric Thor budget is inferred. Owner readability/pacing review, a normal
behavior-enabled connected expedition, and target-device acceptance remain open.
That phase-1 checkpoint left cause/chain/lifecycle coverage open; phase 2 below
extends it. Phase 3's encounter-duration tuning is still pending. The original
post-implementation decision audit is in the sequencing delivery doc.

## Phase 2 delivery checkpoint — October 28, 2026

[Consequences and command positions](combat-consequences.md) names automatic
damage, status expiry, field changes, displacement, passive modifiers, and terminal
outcomes. Failed capture is shown before enemy activation. Completion rejection
keeps a frozen terminal packet and a deliberate Retry result action; it cannot
repeat capture rolls, rewards, or imprints.

The owner's follow-up is implemented: the trainer runs outside on the farthest
usable side, the old tile becomes available, and release range comes from the
arrived command position. A bounded terrain-valid search requires legal throw
space before battle admission. Deployment waits for arrival; retreat remains
available. Commander Run Speed is connected through Battle Settings in Godot.
After completion, an obstructed return remains at the safe outside position rather
than erasing a barrier or putting the trainer inside it. Exhaustion retains refuge
recovery.

The audit also reproduced and corrected two existing field-command bugs: an
unchanged wind field could displace a Sol, and rough ground could become a raised
barrier, while execution reported rejection. Intended displacement/barrier changes
now count as the accepted action; a genuinely unchanged field still rejects
without spending movement/action or adding activity. Regression probes failed
before the fix and pass afterward. No new damage, status, capture, or reward
formula was introduced.

Godot 4.7.2 import and the shared validator passed **13,973 checks in 44 suite and
journey invocations**, including **64 consequence checks**, the existing sequencing
suite, and both exploration journeys. After avoiding full arena rebuilds for
HP/text-only updates, **185 focused checks** passed across consequence, sequencing,
combat-interface, mouse-UI, orb, and wilderness-presentation suites. The final
rendered consequence run passed all **64 checks** on RTX 3070/OpenGL compatibility
at 1280×800. Trainer departure/arrival, poison, and pending-result retry captures
were visually inspected.

Evidence: ignored `artifacts/combat-consequences/validation-final.log`,
`*-review.log`, `rendered-final.log`, and captures. The tested working tree is
based on `96f384ffbd12c227b964b5f433a76901e8c3879f`, with existing shared work
preserved; it is not a committed revision. The post-implementation decision audit
and exact source references are in the consequence delivery document.

Short diagnostic on the documented Ryzen 7 5800XT/RTX 3070 development PC,
1280×800 OpenGL compatibility: after 120 warm-up frames, each mode measured at
least three real seconds with one end-turn/enemy-hit command at one second.
Both modes completed the same retained-HP result. Synchronous/paced rendered
frame-interval p95 were **5.023/5.274 ms**, p99 **6.059/6.639 ms** (751/729 samples).
Monitored static-memory peak above the starting value was about **92/446 KiB**;
GPU memory is excluded. Thirty-sample domain-operation p95, excluding deliberate
holds/rendering, were **0.869/2.041 ms**. Commander planning against real Godot
traversal measured p95 **3.199/3.154 ms** in the two runs.

The probe uses seed 17, the first authored encounter, default scene rendering,
disabled wilderness/movement AI, a walkable arena fixture, explicit framing, and
one-damage enemy strike. It compares modes in the same working build, not historic
commits. Evidence and exact workload are `performance.log` and
`performance_probe.gd` beside the phase-2 logs. The initial sample identified full
arena rebuilding for HP-only cues; view reuse now avoids that work. These short
diagnostics are neither a broad benchmark nor device acceptance, and establish
no numeric Thor budget.

Owner playtesting, a behavior-enabled connected journey, ordinary/major duration
targets, and physical Thor acceptance remain open.

## Phase 3 v1 measurement checkpoint — October 28, 2026

[Encounter pacing measurements](combat-pacing.md) provides Inspector-editable
ordinary, terrain and major development recipes, an isolated playable runner,
bounded scripted policies, revision/settings manifests and ordered result traces.
Choice time, presentation time, commander movement and pause time are separate;
scripted thinking time is null. Repeated commands, net-state cycles, damage-free
turns and actual healing/damage expose possible stalls.

The first wall probe reproduced a no-damage approach stall. Production enemy
fallback and scripted approach now use a complete bounded legal route to attack
range, including detours that initially increase distance. Unreachable opponents
do not cause anchor-chasing oscillation. Immediate move scoring and damage,
healing, status, capture and reward numbers are unchanged.

With the v1 profiles and fixed class potency 1, ordinary finishes in 14 turn
choices plus one movement choice. Default configured holds total 28.64 seconds;
the optional concise preset lowers them to 16.56 seconds with identical ordered
results. Scripted 60 Hz presentation totals are 30.62/18.52 seconds. These are
waiting measurements, not owner encounter duration or approved targets.

Terrain takes 21 or 27 turn choices under the two policies, with 54/78 HP of allied
healing. The v1 major probe ends in exhaustion after six turn choices; it
does not yet satisfy the longer meaningful fight goal. An alternate peer-profile
probe also reproduced repeated healing with no net progress. Preserve these
findings for owner playtesting rather than increasing HP or silently limiting
healing to manufacture a passing fixture. Full results/settings and open issues
are in the linked delivery document.

Godot 4.7.2 import/shared validation passed **16,355 checks in 50 suite/journey
invocations**, including both exploration journeys and the first 50 pacing checks.
After final probe/timing refinements, **263 focused checks** passed across pacing
(59), sequencing (39), consequences (64), AI/Seals/progression (78) and combat
interface (23). Twelve final scripted comparisons (three recipes × two policies ×
two timings) finished with no repeated-state visits. Rendered automatic runs
exercised the ordinary, terrain and major probe through normal live controls on
RTX 3070/OpenGL compatibility. The final ordinary/major captures use 1280×800;
the earlier terrain capture uses the maximized development display. This is
development-PC functional evidence, not a performance or AYN Thor acceptance claim.

Evidence is under ignored `artifacts/combat-pacing/`: `validation.log`, final
focused suite logs, the timestamped reports/manifests, `rendered-*-final.json`,
render logs and captures. The working tree is based on
`96f384ffbd12c227b964b5f433a76901e8c3879f` and includes concurrent in-progress work;
it is not a committed revision. No owner playtest/feedback or accepted numeric
targets exist yet. **Phase 3 remains open.**

## Phase 3 v2 fixture checkpoint — October 28, 2026

The [revised fixture set and comparisons](combat-pacing.md#revised-fixture-measurements--v2)
keep the three original recipes replayable under `resources/combat_pacing/baseline/`.
Production combat balance, resolution order, rewards/imprints/capture and creature
motion/rig/cache code were not changed in this iteration.

The revised ordinary matchup uses existing starter/wild Bramblepup profiles and
finishes in four turn choices. The terrain probe's Thin Passage option reduces
turn choices from 16 to 14, incoming damage from 56 to 44 HP, and healing from 24
to 12 HP, while requiring two extra movement confirmations. The major probe uses
an existing 44-HP peer profile rather than the original 47-HP Ashkit. Safe approach
preparation and ranged offense win in eight turn choices with 8 HP retained;
direct play wins in nine with 2 HP. Enemy Heat and route changes remain visible.

Major preparation has more presentation despite fewer turn choices: default
holds 25.82 seconds (concise 14.98), compared with ordinary 7.84 (concise 4.56).
These are workload measurements, not approved duration targets. The original
heal-first policy still loops on the revised major probe; a detached forecast lets
the revised script skip the six-heal/six-damage response twice and win. Healing
remains legal and unchanged; the regression preserves the unresolved general
stall possibility rather than inventing a cost or forced timeout.

Godot 4.7.2 import and **332 focused checks** passed, including 70 pacing checks
and 58 controller expedition checks. Twenty-four retained-v1/revised-v2 scripted
comparisons cover both timings. Rendered probes for all three revised fixtures
reach victory and committed receipts. The optional review window was visually
inspected, keyboard/controller routing was exercised, and owner responses remain
null. See the delivery document for source evidence, exact settings/manifests,
report paths and the post-implementation audit. No timed profiling was run during
other agents' active validation/profiling.

The [compact four-run owner session](combat-playtest-session.md) compares ordinary
default/concise, then terrain and major concise, with optional in-game notes saved
beside measured reports. **Not yet played by the owner. Phase 3 remains open**
until the owner accepts the ordinary/major pacing and actual targets can be
proposed from that feedback. Automated results do not establish readability,
tactical satisfaction or AYN Thor acceptance.

## Inspected baseline

Static inspection of the current working tree found:

| Area | Existing implementation | Gap relevant to this roadmap |
| --- | --- | --- |
| Battle rules | `scripts/tactical_battle.gd`: one allied Sol/one opponent, legal deployment and movement, speed initiative, four moves, fields, statuses, capture, terminal outcomes. | `execute_move`, `wait_turn`, deployment, and failed capture can invoke automatic enemy turns synchronously. One command can cross several meaningful boundaries before returning. |
| Feedback | `scripts/battle_feedback.gd` and `scripts/battle_controller.gd::receive_feedback` immediately display incoming events. | Ordered signal emission does not give the player a readable sequence; multiple cues can start together. Existing events omit a complete action/turn timeline. |
| HUD | `scripts/combat_hud.gd::refresh` reads live HP, statuses, turn, and intent; HP bars have cosmetic tweens. | After synchronous resolution it reads the resulting state, potentially skipping the intermediate heal, hit, movement, or turn change. |
| Completion | `scripts/battle_controller.gd::after_command` commits terminal results through `ExpeditionState`, then tears down battle views. | A final hit can lose its battlefield context immediately. Pacing must preserve the one-time completion contract. |
| Tests | `tests/battle_feedback.gd` expects separate heal and damage events even when their net HP change is zero. Existing battle, affinity, class, capture, and UI suites cover many domain contracts. | Event counts and final-state checks do not establish that a player sees those events separately. |

This baseline includes existing uncommitted work on `codex/mouse-first-ui`.
It is a code/document inspection, not a fresh runtime, full-suite, balance, or
device-acceptance result. Historical validation remains in the feature documents:
[battle prototype](first-playable-battle.md), [affinity moves](affinity-moves-imprints.md),
[AI/Seals/growth](ai-seals-progression.md), [stats](sol-stats.md),
[class buffs](class-buffs.md), and [combat interface](combat-polish.md).

## Phase 1 — Give actions a readable sequence

First implementation slice: one ordinary encounter using the current rules and
placeholder orbs. Trace the existing resolution order before splitting its calls.

- Introduce explicit coordination boundaries between an accepted command, its
  effects, turn-end/round-start consequences, the next actor, and completion.
  The domain determines ordering and results; the controller schedules their
  presentation without running the entire enemy response inside the player's
  command. Domain calculations remain usable without rendering or real-time waits.
- Produce ordered, immutable resolution records with battle/action identity,
  actor/recipient, move or cause, affected cells, actual HP changes, and the state
  needed to show that step. Include movement routes and turn transitions, rather
  than inferring them from the final positions or parsing log text.
- Identify the acting Sol and move, show the actual consequence, then identify
  the next actor before showing its response. HP numbers, bars, statuses, ground
  overlays, and the log must describe the same presented step. Show heal-then-hit
  separately even when final HP equals starting HP.
- Add a resolution input gate at command admission, covering world clicks and
  action buttons. Repeated clicks cannot execute another move, spend movement,
  roll capture again, or submit withdrawal during an unresolved step. Retain
  inspection/camera access where existing modal rules allow it.
- Expose connected, validated Godot tuning for cue holds, movement display, and
  turn handoffs in real seconds. Keep these separate from turn counts, status
  lifetimes, and gameplay costs. Define application timing and update
  [Inspector tuning](inspector-tuning.md) in the implementation change.
- Preserve existing initiative, including faster enemies acting after release
  and consecutive enemy turns across a round boundary. A presentation handoff
  must not impose artificial player/enemy alternation.

An illustrative attack flow is: confirm target, identify ally/move, show its
effect and any rule-ordered consequences, identify enemy turn, show its legal
movement and action, then return control or show the outcome. This is not a new
rule for when statuses or fields tick; the inspected domain order governs.

Exit: a rendered ordinary encounter visibly separates the player's action from
the enemy response using simple cues. Automated traces verify intermediate
states, command rejection during resolution, and equivalent final results across
different presentation timings. The owner can identify who acted, what changed,
and when control returned without opening the log.

## Phase 2 — Complete consequences and safe transitions

Depends on phase 1. Extend the same sequence through every existing action path.

- Cover deployment/first initiative, standalone movement, end turn, healing,
  status application/ticks/expiry, protection and passive triggers, field
  placement/spread/charge/discharge, displacement, phasing, and Quantum choices.
  Name meaningful causes; distinguish a command's effect from later automatic
  consequences. Preserve actual legal paths and endpoints.
- Cover failed Seal attempt followed by enemy activation, successful capture,
  victory, exhaustion, and confirmed retreat. Preserve the same individual,
  retained HP, move activity, lasting imprint, rewards, and one-time receipt.
- Keep battle context until the final meaningful consequence is visible, then
  show the committed result. Specify the completion boundary so visual callbacks
  never award rewards or apply imprints. If persistence rejects completion, keep
  a recoverable encounter and an honest message rather than implying success.
- Keep save/load unavailable for active combat through the resolution phase.
  Old callbacks must not affect a replacement session. Pause/menu handling must
  preserve true pause, targeting cancellation, explicit retreat confirmation,
  and world input shielding. Sound or animation completion must never be needed
  for combat to advance.
- Keep resolution records bounded without dropping required state transitions.
  Decorative cue limits may still retire cosmetic effects. Test large frame
  gaps and zero-duration settings for correct completion and no stuck gates.

Exit: each existing outcome and automatic-effect path has an ordered regression
trace and a rendered reproduction. A final hit remains understandable, queued
work cannot survive into a new encounter, and completion cannot duplicate a
capture, reward, health update, or terrain imprint.

## Phase 3 — Tune routine and major encounter pacing

Depends on phases 1–2. Tune a small representative set before adding content.

- Establish repeatable ordinary, terrain-focused, and major-battle fixtures.
  Major-battle fixtures are development probes until their content is authored
  and approved; their name alone does not establish a production encounter.
- Measure player decision count, rounds, forced presentation time, voluntary
  thinking time, no-effect/repeated turns, and total encounter duration separately.
  Record timing settings and fixture/revision so comparisons are meaningful.
- Keep routine feedback concise. Group genuinely simultaneous area consequences
  where that improves readability, while retaining their individual results in
  the log. Avoid multiplying pauses by tile count or decorative particle count.
- Give major fights more meaningful decisions through existing terrain, move
  interactions, and readable enemy choices. Test whether repeated healing,
  unreachable paths, or harmless exchanges stall progress. Numerical balance
  changes need their own evidence and remain tunable; longer battles must earn
  their time through decisions rather than extra waiting.
- Propose actual duration/action-count targets after the first measured owner
  playtest. Do not import the Python source's fixture counts as Godot targets.

Exit: the owner accepts a quick ordinary encounter and a longer, tactically
meaningful major fixture. Record the settings, measurements, feedback, and
remaining issues. Passing a scripted action-count probe alone does not close
human pacing acceptance.

## Phase 4 — Strengthen expression and enemy counterplay

Depends on an accepted basic rhythm. Use the current small roster to prove depth.

- Build scenarios supporting different combinations of movement, terrain,
  damage, support, status, and class passives. Check that multiple approaches
  are viable and understandable rather than requiring one scripted solution.
- Make shared-field risk and enemy decisions legible at the decision point.
  Preserve read-only previews and identical legality/damage rules for player and
  AI. Improve the bounded planner only where a reproduced scenario shows a gap.
- Audit useful support contribution and combat-earned training, species move
  eligibility, off-affinity moves, natural stat variation, and permanent imprints
  together. Presentation must not count a second activity event or contribution.
- Reconcile any proposed costs, counters, innate/ultimate abilities, or Vastra
  damage curve with source implementation/tests and later owner decisions before
  adding them. The unresolved concentration curve and proposed ceiling remain
  unresolved; special affinities do not gain automatic superior strength.

Exit: representative scenarios demonstrate distinct successful approaches,
readable enemy counterplay, preview/execution agreement, and correct durable
outcomes. Record which combinations work and which need balance/content work.

## Phase 5 — Expand the combat system through connected slices

Depends on the accepted earlier slices and each feature's source reconciliation.
This is an ordered candidate backlog, not approval of new mechanics:

1. In-battle party switching and exhaustion replacement, with explicit action,
   occupancy, initiative, retained-health, and contribution contracts.
2. Larger footprints and authored encounter variants, with whole-footprint
   movement, release space, targeting, and any approved environmental bonus.
3. Multiple active Sols, ally-target support, and group tactics once deployment,
   turn order, information density, and bounded AI costs are proven. The current
   ordinary one-versus-one baseline remains valid; Swarmkin's reserve members
   must not be treated as active adjacent allies to simulate this feature.
4. Authored ability/ultimate and progression content, combat-side trust/command
   behavior, and production Seal supply as their designs and shared-system
   dependencies are resolved. Existing prototype grants and unlimited testing
   Seals do not establish their eventual economy.

Exit for each slice: source-backed behavior, focused regressions, a playable
refuge-to-wilderness encounter and return, persistent outcomes/save-load, and
owner review. Do not expand geography or roster simply to avoid acceptance of
the connected loop.

## Validation throughout delivery

For implementation, use the pinned Godot 4.7.2 and `tools/validate.ps1`, relevant
domain/UI regressions, and rendered acceptance. A prospective sequencing suite
should cover observed step order, intermediate HUD state, input gating, session
replacement, pause/resume, terminal receipts, and timing independence. Include
support and field chains, faster-enemy deployment, and consecutive enemy turns.
Use explicit advancement in tests instead of waiting through production delays.

Coordinate controller focus, confirmation/back, inspection access, and combat
commands with the approved [UI/UX controller work](ui-ux-roadmap.md); do not invent
a competing input layout. Check readability at the existing compact viewport and
enlarged text settings. Exercise a complete expedition with normal Sol behavior.

Measure relevant planning/queue costs, rendered frame-time p95/p99, memory, and
stalls under consistent hardware/settings/workloads as features change. AYN Thor
remains the release target. Desktop headless/rendered checks do not establish
device performance or input acceptance; numeric device budgets remain open in
the development plan. Optimization runs throughout these phases.

## Post-planning decision audit

The sequence above was reviewed after drafting against the owner's complaint,
the current call paths, source evidence, and confirmed canon.

| Decision | Audit finding and resulting safeguard |
| --- | --- |
| Sequence resolution before adding more effects. | Correct priority: existing cues already exist, but the synchronous player/enemy chain collapses their display. Longer floating-text lifetimes alone would preserve the defect. Phase 1 requires intermediate state and explicit next-actor boundaries. |
| Preserve rule-driven ordering. | Risk: splitting calls could shift poison, passive, field, or initiative timing. Capture baseline traces first; compare state and event order across timing settings. Do not correct a suspected rule bug silently during presentation work. |
| Add readable holds. | Risk: excessive waits undermine quick routine battles. Measure forced presentation time separately; use short tunable holds and group simultaneous area results without skipping distinct causes. Final values follow playtesting. |
| Gate commands during resolution. | Risk: an unlocked tray could accept another action while it shows earlier state. Gate every mutation entry point, reject stale commands/callbacks, and retain inspection where safe. |
| Delay teardown until the consequence is visible. | Risk: view timing could duplicate or strand persistence. Keep terminal completion under its existing authority with one receipt; visuals never own rewards, capture, or imprints. Include failure and session-reset cases. |
| Defer larger teams and production animation/sound. | Fits the requested first milestone and the ordinary encounter baseline. Keep actor/recipient identity and presentation hooks extensible, without a speculative general engine or an animation dependency. |

Audit conclusion: the first deliverable is a sequenced version of the existing
battle, followed by full-path reliability and measured pacing. Broader tactics
and team expansion follow demonstrated readability. No new gameplay formula,
content roster, or combat completion claim follows from this roadmap.

## Source evidence used for this plan

Read through the GitHub connector at SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`. This is the verified reference snapshot,
not a claim that it is the newest revision of every system.

- [Combat loop review](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/docs/coordination/combat-loop-review.md)
  identifies synchronous enemy activation and missing visible sequence as an
  earlier problem. Followed its linked
  [repair](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/docs/coordination/combat-loop-repair.md)
  and subsequent
  [seamless correction](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/docs/coordination/seamless-combat-correction.md):
  restored world-space combat and readable history do not establish paced action
  resolution. Retain Godot's existing world-space presentation and owner controls.
- [Live encounter coordination](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/systems/tactics/live_encounter.py),
  its [controller caller](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/app/controllers/combat_controller.py),
  and [combat domain](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/systems/tactics/sol_combat.py)
  establish action/enemy coordination, shared calculations, effect ticking, and
  centralized completion. They do not supply an approved Godot pacing duration.
- [Ownership guide](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/docs/coordination/combat-architecture.md)
  supports keeping occupancy, battle rules, live coordination, and persistence
  under explicit authorities; it cautions against speculative generic systems.
- [Pacing probes](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/docs/coordination/combat-reliability-pacing.md),
  [planning/simulation tests](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/tests/test_combat_planning_simulation.py),
  and [live-loop tests](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/tests/test_combat_loop.py)
  support reproducible bounded encounters, legal planning, and real-loop checks.
  Their decision counts and historical test results are source evidence, not
  player-time targets or newly run Godot validation.

## Original planning validation

At roadmap creation, checked local links, referenced paths, and whitespace and
reviewed the documentation diff; that planning change did not change gameplay or
rerun game tests. The later phase-1 implementation evidence appears above.
The existing dirty files and deleted repository-management `ROADMAP.md` were
preserved; this feature roadmap does not replace that file or the project standard.
