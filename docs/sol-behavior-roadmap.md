# Sol world behavior roadmap

Status: prototype phases 1–4, natural movement, and the activity correction are implemented;
owner movement-feel, connected encounter/combat, and device acceptance remain open.
Last audited: October 28, 2026.
Owner direction: October 27, 2026. This chat focuses on Sol AI in the world.

October 28 normal-game rollout: the F5 scene now explicitly selects the live
world sighting preset containing Crown-Ear, bank-placed Reedback and Bellroot,
with normal wilderness and species behavior still enabled. Owned following,
flight/swimming and idle moments are enabled in that same scene. Existing
individuals and starter choices remain intact. See
[rollout and current-save admission](sol-species-data.md#normal-game-rollout).

October 28 owner follow-up: behavior must be hierarchical, with shared mechanics
and species/class/affinity-specific children pulled from an editable list.
Implemented the [inherited behavior library](sol-ecology.md#inherited-behavior-library--october-28-2026):
shared idle/patrol/flee/approach/guard roots, species child definitions, independent
identity filters, inherited response tuning, deterministic overlap resolution and
live cache refresh. Existing species balance and domain 14 are preserved. New
class/affinity actions are authored only when their actual mechanics are defined.
Guard provides territorial defense; pursuit/chase remains unimplemented and must
be added as its own shared primitive rather than relabeling guard. Hierarchy
checks include loaded-world edits and safety/identity preservation. This does not
close owner behavior-feel, group/social, companionship or device acceptance.
Validation: 394 focused checks, a rendered hierarchy run, and 16,305 complete
project checks passed, including import and both exploration scene journeys.

## Purpose and authority

Owner-approved October 28 focus: develop readable Sol behavior and companionship
alongside exploration feel and tactical combat in the same representative
expedition. Review whether Sols belong visually and behaviorally in that world;
passing isolated behavior tests does not close experience acceptance. Keep nearby
AI and navigation costs bounded and measure relevant regressions throughout work
toward AYN Thor release. See the
[approved development focus](development-plan.md#approved-focus--october-28-2026).

Make wild Sols visibly live their own lives while the player watches, starting
with autonomous movement. This is a feature roadmap, not a replacement for the
[project standard](PROJECT_STANDARD.md), [development plan](development-plan.md),
or [design Bible](reference/SolHunter_Worldbuilding_Bible.md).

The owner requires organized code and adjustable behavior parameters, and welcomes
questions when needed. Consult the mechanics references first; ask the owner when
a consequential design ambiguity or conflict remains. Do not invent canon to fill
a gap. Later phases below are proposals, not approval of new mechanics or balance.

## Approved companionship and creature direction — October 28, 2026

Approved follow-up: the three rescuers mysteriously leave their NPC owner to
help the player. After escape, their owner permits keeping one; interactions
suggest a bond before explicit player confirmation. Preserve the same rescuer
through transfer and companionship without inventing trust or transfer formulas.
The first journal discovery pairs observed behavior with a habitat clue. Strong
stylized shapes and clear species silhouettes are the visual priority; a changed
but enduring starter relationship is the first refusal consequence to explore.
Rescuer distinctions and the first curiosity moment remain open. See the
[follow-up specification](decisions/2026-10-28-opening-companionship-and-consequences.md#approved-follow-up--tutorial-and-visual-identity).

The [creative decision](decisions/2026-10-28-opening-companionship-and-consequences.md)
adds an opening where three Sols guide the player out of a Vastra storm and one
of those same individuals becomes the starter. Plan readable guidance and stable
identity through rescue, starter selection and later travel. The companion shows
curiosity and personality while accompanying the player. This is approved design
intent; owned exploration presence and rescue behavior are not implemented by
the existing wild patrol/group systems.

Patient, nondestructive, respectful interaction should support earning trust.
Reconcile the existing source interaction/history paths before specifying live
trust changes; no automatic affection on capture, repetitive upkeep, trust formula
or random command refusal is approved here. Refusing the later legendary request
has lasting relationship/story consequences as well as a harder victory path and
permanent ascension lockout; author the actual consequences separately.

Orbs are temporary placeholders. Production species need their own models,
behaviors and animations while saved individual identity/affinity remain intact.
Review guidance, curiosity and species readability in the connected expedition,
with bounded AI/animation costs and eventual controller/device acceptance.
Exact rescue species, companion interactions and storm failure rules remain open.

## Original baseline and source evidence

Before phase 1, inspection found limited flee, approach, guard, and return decisions in
`scripts/authored_sightings.gd`, but no autonomous idle patrol. The owner's observed
problem is that Sols sit still. Existing reactions do not establish that normal
exploration feels active; verify their live behavior during implementation.
See [local Sol reactions](local-sol-reactions.md) for existing contracts and tests.

Follow [mechanics reference](mechanics-reference.md) for source selection. The
verified source snapshot is SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`:

- `src/systems/ai/roaming.py`: patrol goals, deliberate rests, blocked-goal expiry,
  local position persistence, and social following hooks.
- `src/systems/ai/behavior.py`: decisions, territory limits, occupancy, and bounded
  obstacle detours.
- `src/systems/world/ecology_profiles.py` and `tests/test_ecology_profiles.py`:
  authored behavior sets, temperament, and stable individual variation.

The pinned roaming policy was read through the GitHub connector. Later lookups
identified local reference HEAD `d6f0902d77ed46a2f7d251c354792a4cc9210bc4`;
that checkout supplied additional callers, tests, and audit context. Its clean
working-tree status was not verified. The delivery sections record which reference
was used. Before implementing each mechanic, verify the exact source revision,
callers, tests, and later decision evidence. Source values are
provisional unless separately confirmed. Do not copy private reference files into
this repository. Godot remains authoritative for terrain and traversal.

## Current audit — October 28, 2026

| Phase | Verified implementation | Acceptance still open |
| --- | --- | --- |
| 1. Wander/rest | Local autonomous patrols, rests, goal expiry, saved continuation; subsequent natural pass adds varied destinations/rest draws and full-interval travel. | Owner review of natural timing and readable activity during a representative expedition. |
| 2. Movement | Cardinal legal steps, bounded BFS, reservations, home return and queued display replay for the current footprint-1 prototypes. | Owner visual review; support larger footprints before authoring them. |
| 3. Reactions | Flee/watch/approach, bounded attention, safe routines, moving territorial confrontation, settling and warned later-step entry. | Broader connected combat and owner experience review with normal profiles enabled. |
| 4. Species/individuals | Two species defaults, explicit guard override, stable ID-derived samples, live Inspector tuning. | Owner acceptance of provisional species rhythms, spacing and presentation together. |
| 5–7 | Not implemented as AI roadmap deliveries. Existing identity, journal and Vastra foundations do not complete social behavior, ecological routines or memory-driven reactions. | Source reconciliation and the corresponding implementation/acceptance below. |

Fresh audit checks: 255 assertions passed across `tests/local_sol_reactions.gd`
(51), `tests/sol_wandering.gd` (71), `tests/sol_player_reactions.gd` (44), and
`tests/sol_ecology.gd` (89), using Godot 4.7.2 headless. Historical full-suite and
rendered totals below remain evidence from their deliveries, not fresh device or
whole-project acceptance. This audit changes documentation, not gameplay code.

Audit findings and follow-up status before expanding into phase 5:

1. **Movement display — regression resolved by the natural pass:** the original
   display interpolated toward the latest saved cell. The audit
   committed two legal turns `(8,5) -> (8,6) -> (7,6)` before one visual update;
   at 0.1 seconds the visual cell was `(7.6464,5.3536)`, about 0.354 cells off
   either legal segment. The subsequent owner-authorized
   [natural movement pass](sol-natural-movement.md) retains committed steps in
   `SolMotionTrack`; regression tests now verify both segments, the corner, and
   pause/resume. The audit reproduced a skipped turn, not a particular terrain
   collision. Broader owner visual acceptance remains open.
2. **Readability and performance:** the 2–4 nearby-Sol guideline is not an
   implemented visibility cap. With seed 17 and default settings, player cells
   `(0,0)`, `(16,0)`, `(48,0)`, `(16,16)` had 8–12 visible Sols, 6–10 in the active
   Manhattan range, and 28 local members before catalog rollout. The normal-game
   rollout now permits up to 31 local members: three original trail entries,
   three catalog placements and one candidate in each of 25 sectors. Define and
   assess "nearby" in the actual camera/habitat context; do not silently convert
   the guideline into a hard population rule. Measure AI/navigation cost, frame
   p95/p99, memory and stalls with this workload before adding group agents.
   The natural pass now records a capped/uncapped rendered expedition baseline;
   this does not settle density/readability or Thor budgets.
3. **Connected acceptance:** `tests/smoke.gd` disables live AI through smoke mode;
   earlier movement/reaction suites disable species profiles to isolate their
   contracts. The ecology suite covers profile-enabled movement and save/load,
   but disables automatic encounters in its scene. These tests do not establish
   a normal profile-enabled refuge-to-wilderness, encounter/combat-and-return
   journey. Subsequent natural-pass profiler runs now verify normal live-AI
   travel and save/load at capped/uncapped rates. They recorded zero automatic
   contacts and did not exercise combat, so that combined acceptance and owner
   review remain open.
4. **Companionship scope:** wild social groups in phase 5 are not an owned Sol
   following/presence system. Party selection, combat and model previews exist;
   the October 28 creative direction now approves curiosity/personality while
   accompanying the player. The first [owned ground companion](owned-companion.md)
   slice provides selected-identity presence, legal follow/rest/catch-up and
   inherited species idle moments. Its subsequent flight/water integration now
   reuses the delivered species traversal contract for owned follow routes.
   Opening/rescue guidance, broader interactions and experience acceptance remain open.

AYN Thor acceptance remains open. Follow the approved development focus for
hardware/settings evidence and ongoing performance comparisons; exact device
configuration, resolution, frame-rate and memory budgets are not yet approved.
The recommendations above identify unclosed acceptance work, not approval of
new mechanics, balance values, population caps, or a larger roadmap scope.

Current persistence: expedition format **3**, world domain **14**, generation **6**
(`save_store.gd`, `expedition_state.gd`, `terrain.gd`). Older outer-format or
generation saves are rejected. Per the project standard, current development
work validates current saves and clear incompatible-save rejection instead of
adding legacy migrations. Version 11/format 2 statements in delivery history
describe earlier implementations.

## Delivery sequence

### 1. Wander and rest

- Choose nearby destinations inside home territory without player interaction.
- Travel, rest, then choose another destination; vary timing by stable individual
  identity so all Sols do not move together.
- Keep alert reactions able to interrupt patrol and return to ordinary activity.

Acceptance: a stationary player can watch nearby Sols independently complete
repeated wander/rest cycles with readable pauses.

### 2. Reliable movement

- Respect Godot terrain, footprints, occupied cells, and player destinations.
  Current roaming uses footprint 1; larger Sols require footprint-aware traversal
  and occupancy before their movement can be claimed supported.
- Add bounded obstacle detours and expiry/reselection for unreachable goals.
- Return toward home safely; never teleport to solve a blocked route.
- Preserve essential player travel through the current nonblocking Sol policy.

Acceptance: exercise blocked paths, narrow spaces, competing destinations, and
territory edges without illegal movement, persistent overlap, or endless retries.
Displayed movement must also retain legal segments when multiple decisions occur
before a rendered frame. The natural pass closes the skipped-turn regression;
owner visual review and larger-footprint support remain open.

First implementation delivery combines phases 1 and 2: a complete, safe
wander -> rest -> wander loop with saved continuity.

### 3. Readable player reactions

- Avoidant: retreat and cautiously observe from a safe distance.
- Neutral: watch or approach to a comfortable distance according to authored policy.
- Assertive: defend territory with readable warning before existing encounter entry.
- Use separate entry/release thresholds and recovery timing to avoid rapid switching.
- Resume normal routines after the player leaves. Keep encounter ownership in the
  existing encounter system; AI must not create competing battle rules.

Acceptance: temperament is recognizable before opening an encounter, and approach,
withdrawal, cooldown, and encounter transitions remain consistent.

### 4. Species and individual differences

- Author two or three recognizable behaviors per species.
- Add stable, bounded individual variation in caution, spacing, and activity.
- Keep ecology profiles independent of affinity presentation and combat identity.

Acceptance: species differ observably, while the same individual retains its traits
through save/load and view reconstruction.

### 5. Social behavior

- Support authored solitary, paired, and small-group preferences.
- Let members travel and rest near one another with spacing and bounded following.
- Reconcile source group identity, leadership, separation, and recovery rules first.

Acceptance: groups remain recognizable through movement and streaming without
clumping, duplicated members, or unbounded pursuit.

### 6. Ecological routines

- Add source-backed habitat activity and environmental maintenance through existing
  Vastra authorities; avoid applying ecological effects twice.
- Consider daily schedules only after reconciling mechanics and the active clock.
- Weather-dependent behavior needs a separate design decision; current weather is
  presentation and does not authorize ecological or encounter modifiers.

Acceptance: observable routines connect Sols to habitat and verified ecology rules.
Ordinary noncombat Sol activity does not originate overload. Under the October 28 owner retcon, aggressive Vastra-powered abilities can; healing abilities neutralize it or create restorative negative overload. Combat disturbance does not imply ecological evil.

### 7. Memory and continuity

- Extend notable individuals' responses using verified encounter and relationship
  history; retained identity alone does not prove live relationship behavior.
- Keep distant populations lightweight rather than simulating every individual.
- Reconcile ownership, capture, release, exhaustion, and recovery transitions before
  adding memory effects to them.

Acceptance: revisiting notable Sols preserves understandable consequences without
duplicating identities or growing simulation work without bounds.

## Code organization and adjustable parameters

Use focused components for decisions, movement, species profiles, persistent state,
and presentation. Keep the existing scene/controller as orchestration rather than
growing one script to own every responsibility. Extract incrementally as each
delivery needs it; do not create unused frameworks or empty scaffolding.

- Decisions select an action and goal without moving meshes or editing terrain.
- Movement resolves legal steps through Godot traversal and shared reservations.
- Persistent domain state owns identity, current position, and durable AI state.
- Presentation reads state and interpolates; visibility/rebuilds do not run AI.
- Species resources supply authored policy; individual variation is stable and saved
  or deterministically derived under a versioned identity contract.

Expose all implemented behavior tuning through typed Godot Resources under
`resources/` or grouped scene exports: movement speed/cadence, patrol radius,
rest ranges, goal timeout, reaction/comfort/release distances, return thresholds,
cooldowns, variation, and later group/routine settings as those features arrive.
Do not expose controls for mechanics that do not exist yet.

Every setting needs a useful label, tooltip, units, valid range, runtime validation,
and a connected effect. Document whether changes apply immediately, on restart,
to loaded saves, or only to new expeditions. Persist identity-affecting inputs before
use. Schema versions, corruption limits, and engineering safety ceilings remain
constraints rather than balance sliders. Update [Inspector tuning](inspector-tuning.md)
with each implementation delivery. All initial balance values remain provisional.

## Shared acceptance and working notes

- Advance simulation from active exploration time; pause freezes behavior. Explicitly
  define encounter-time behavior without allowing presentation to drive decisions.
- Preserve identity, affinity, ownership, journal history, and saved positions.
- Verify current-format save/load, clear incompatible-save rejection, streaming,
  culling, and rebuilds. Do not add legacy migration work during the disposable-save
  development phase; follow the project standard if compatibility policy changes.
- Keep approximately 2–4 nearby Sols readable, adjusted for habitat and context;
  distinguish the visible population from the bounded active simulation budget.
- Profile active-agent and path-search work. Distant/offline simulation is deferred
  until a separately verified policy requires it.
- Run relevant gameplay tests and the shared validator for implementation changes,
  then visually exercise the affected scene. Headless checks alone do not establish
  that movement feels natural.
- Use focused `codex/` work, inspect diffs, preserve concurrent edits, and follow
  repository review rules. Do not restore the currently deleted root `ROADMAP.md`
  or modify another contributor's files merely to publish this feature plan.

## First delivery — October 27, 2026

Phases 1–2 now implement autonomous cardinal patrols, stable individual rest phases,
arrival rests, blocked-goal expiry, bounded BFS detours, occupancy reservations,
home return, and interrupting player reactions. `scripts/sol_roaming_policy.gd`
owns decisions; `scripts/sol_local_navigation.gd` owns path steps. The existing
sighting controller orchestrates them. Domain version 11 stores optional patrol
goal, leg, rest deadline, and expiry without resetting older saved individuals.

Evidence: pinned source `115f3e87acc1716c7113523567c01e1666681885`,
`src/systems/ai/roaming.py`, `src/systems/ai/behavior.py`, and
`tests/test_water_display_wildlife.py` (goal retention, arrival rests, occupancy).
The Godot implementation deliberately keeps cardinal movement and persists patrol
memory rather than relying on the source's runtime-only goal cache. Initial rest
variation and all balance defaults are provisional presentation/gameplay tuning.

`tests/sol_wandering.gd` adds 71 checks, including actual save/load, continuation,
legacy migration, malformed memory rejection, obstacle detours, and repeated
autonomous movement. A rendered OpenGL run also passed all 71 checks and produced
`artifacts/roaming/wandering.png`, which was visually inspected. This scripted
scene verification does not substitute for the owner's feel/readability review.
Final shared Godot 4.7.2 validation passed import, all suites, and both scene
journeys with the expanded activity radius. The legacy reaction suite explicitly
retains its original seven-cell activity range to isolate its existing fixture.
GPU-only checks skipped by headless suites remain outside that result; the new
wandering suite was also run with OpenGL rendering. See
[Inspector tuning](inspector-tuning.md#autonomous-sol-wandering)
for connected controls and loaded-save behavior. At that delivery, phases 3–7 remained open.

## Phase 3 — readable player reactions, October 27, 2026

Implemented alert/release hysteresis, safe-distance watching, neutral comfort and
reposition cooldown, stable territory defense, settling after disengagement, and
return to the patrol/rest routine. Captions describe actual saved response state.
Warning Delay Seconds adds a minimum uncovered display period to the existing
displayed-warning/later-player-step contract. Timer expiry and AI movement cannot
start encounters. All new behavior values are connected Inspector controls.

`scripts/sol_reaction_policy.gd` owns response decisions; domain version 12 persists
optional response state. See [Sol player reactions](sol-player-reactions.md) for
behavior, settings, source evidence, save ownership, and tests. New durations remain
provisional tuning. At that delivery, phases 4–7 remained open.

Final phase-3 validation: shared Godot 4.7.2 import, all suites, and both scene
journeys passed 13,584 assertions. The new response suite passed 44 checks both
headless and with OpenGL rendering. The territorial caption and warning were
visually inspected in `artifacts/reactions/guard.png`. GPU-only checks skipped by
other headless suites and owner playtesting remain outside this acceptance.
Changes remain local alongside the preserved concurrent work.

## Phase 4 — species and individual differences, October 27, 2026

Added typed ecology profiles for Seedmote and Bramblepup and an explicit individual
override retaining the existing trail guard. Profiles author up to three actual
behaviors plus bounded caution/spacing/activity variation and distinct patrol/rest
scales. Samples derive from the saved ID through fixed SHA streams; affinity,
class, ownership, combat identity, and global RNG are unaffected. Current domain
version stays 12. Live Inspector edits invalidate the controller's resolved cache.

See [Sol ecology](sol-ecology.md) for source evidence, implementation ownership,
controls, saved-world behavior, and test coverage. The supplied species defaults
remain provisional authoring. Phases 5–7 remain open.

Final phase-4 validation: shared Godot 4.7.2 import, all suites, and both scene
journeys passed 13,673 assertions. The new ecology suite passed 89 checks both
headless and with OpenGL rendering. Inspected `artifacts/ecology/species.png`.
GPU-only checks skipped by other headless suites and owner playtesting remain
outside that result. Changes remain local alongside the preserved concurrent work.

## Natural movement pass — October 28, 2026

Owner requested a direct response to rigid behavior. Travel now fills the decision
interval by default, a bounded display-only queue preserves committed turns, and
patrol goals/rests use deterministic non-compass choices. Movement Travel Fraction
and Patrol Goal Min Fraction are connected Inspector controls. Domain 13 persists
the expanded leg counter; terrain, identity, combat and ecology trait authorities
remain unchanged. See [natural movement](sol-natural-movement.md) for tuning,
source evidence, lifecycle behavior, preview and limitations.

Validation: shared Godot 4.7.2 import, all suites, and both scene journeys passed
13,855 assertions. The new suite passed 120 checks both headless and rendered.
Captured normal live-AI movement in `artifacts/natural_movement/preview.gif`.
Capped-60 and uncapped D3D12 connected expedition runs passed travel/save/load
with unchanged source manifests and zero errors, but zero automatic contacts;
encounter/combat and owner experience acceptance are not closed by those runs.
No Thor/device qualification is claimed. Phases 5–7 and remaining audit acceptance
work remain open. Changes remain local alongside preserved concurrent work.

## Phase 2 blocker verification — October 28, 2026

The current natural-movement implementation already retains committed cardinal
steps in `SolMotionTrack`. This pass verifies it rather than replacing AI policy.
Two additional regressions cover the original `(8,5) → (8,6) → (7,6)` inside-corner
clearance at the current orb radius and grounding at the interpolated displayed
position. The movement suite now passes 122 rendered checks, including queued
turns, pause/resume, encounter freeze, culling and stale-state isolation. Evidence:
`artifacts/playtest-blockers-rendered-regressions.log` (movement and terrain
passed; its initial combat fixture failure was corrected and rerun separately).
Larger footprints, species timing/spacing, normal connected encounter acceptance
and owner/device review retain their existing open gates. No new population cap,
movement rule or save format is introduced by this verification.

## Activity correction — October 28, 2026

Owner playtesting found that Sols still mostly stood still and behavior had little
effect. Owner selected how to approach/avoid Sols as the priority. Reproduction
confirmed the problem: at three cells from the player, Wary and Guarding Sols made
zero moves in a simulated minute; Watching moved twice and then parked. The
earlier natural pass smoothed the travel that occurred but did not resolve
indefinite attention or blocked approach renewal.

Bounded attention now allows safe local routines while the player remains nearby.
Close approach still interrupts cautious movement immediately. Neutral Sols can
explore instead of staring or endlessly attempting an unreachable approach.
Guards visibly approach to a standoff and patrol; warned later-player-step entry
and retreat remain authoritative. Patrols do not rest after every leg and quickly
replace blocked goals. Current state domain 14 persists attention/routine deadlines
and blocked-route state. All new controls are connected Inspector tuning.

In the same seed-17, 80-tick near-player workload, actual movement increased from
0/2/0 to **49/54/53** ticks for Wary/Watching/Guarding. The normal starting seed
2601026 produced **45/43/55** moving ticks in the same cases. These are finite
default-setting acceptance cases, not a requirement that every Sol always walks.

`tests/sol_activity.gd` adds 42 headless/rendered checks covering sustained activity,
legal spacing, urgent interruption, real moving-guard contact/retreat, save/load,
corrupt deadlines and blocked-route recovery. See [Sol activity](sol-activity.md)
for source evidence, controls, measurements and the rendered confrontation.
Broader combat, social/companion behavior, density, owner feel and Thor acceptance
remain open. This correction does not advance phase 5.

Shared Godot 4.7.2 validation passed 16,046 assertions, including import and both
scene journeys; the activity suite passed 42 checks both headless and rendered.
The corrected live guard-approach study recorded one automatic encounter and
passed explicit observation/withdrawal, current save/load and return travel.
The profiler now handles an automatic encounter on its final waypoint instead
of leaving it uncounted for the caller's manual Engage. The study reported no
failures or engine errors, with a source-drift flag limited to concurrent
`ui_text.gd` edits; it is not a clean performance comparison or device qualification.
See the [activity evidence](sol-activity.md#acceptance-measurements) for timing,
source manifests, workload limits and remaining owner acceptance.
