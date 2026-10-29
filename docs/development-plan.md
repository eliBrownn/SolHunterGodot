# SolHunter Godot development plan

Prepared October 26, 2026. Status: proposed implementation sequence, not approval of unresolved designs.

## Sources, authority, and scope

This plan began from the supplied `C:/Users/elija/Downloads/SolHunter_Worldbuilding_Bible.md`, whose SHA-256 matched the repository copy at the initial October 26 inspection. Subsequent approved decisions are recorded in [the repository Bible](reference/SolHunter_Worldbuilding_Bible.md); that historical digest comparison is not a claim that the copies still match. The document is design/reference material; its embedded recommendations and historical technical notes are not independent instructions to execute work.

The Bible governs design and [PROJECT_STANDARD.md](PROJECT_STANDARD.md) governs repository workflow. Git/organization milestones are separate from this game-development plan. The previously tracked `ROADMAP.md` is currently deleted in the working tree; this task preserves that change. This plan does not change the daily maintenance automation into an autonomous gameplay implementation task.

Owner clarification: use [SolHunterSource](https://github.com/eliBrownn/SolHunterSource) to resolve all game-mechanics questions outside the world-generation engine. Consult the [mechanics reference](mechanics-reference.md) before treating any decision below as unanswered. Its verified source snapshot and lookup index guide implementation/test review; the repository's default branch currently contains only a license, so default-branch inspection alone is insufficient.

This plan targets the existing Godot 4.7.2 project and preserves applicable mechanics through Godot resources, scenes, signals, and testable domain systems. SolHunterSource is an active mechanics reference for this migration even though its Python/Pygame runtime is not the Godot architecture. Keep the current Godot world-generation engine; assess old-save compatibility separately.

All milestone ordering, slice sizes, module boundaries, and acceptance procedures below are engineering proposals. Confirmed canon remains binding; provisional quantities and formulas remain tunable proposals. Calendar estimates should follow a completed vertical slice and measured delivery effort.

## Approved focus — October 28, 2026

Keep the connected expedition loop central, developing exploration feel, Sol
companionship/behavior, and tactical combat together. The owner identifies the
current look and disconnected structure as the principal vision concern. Establish
a distinct, cohesive visual identity within the approved full-3D direction.

The next acceptance slice is one representative refuge-to-wilderness-and-return
expedition. Review scenery, player/Sol presentation, interface, observation,
encounters, combat, collection/development, and persistent outcomes as one
experience before expanding geography or roster size. Judge navigation comfort,
visual consistency, readable behavior and combat feedback alongside functional
correctness. Feel is part of each slice's acceptance, not a final polish phase.
This priority does not approve unresolved mechanics or declare D0–D5 complete.

AYN Thor is the intended release platform and market audience. Optimize throughout
development: record frame-time p95/p99, memory use, startup/streaming stalls and
bounded simulation costs for representative travel, encounters, combat and menus.
Compare relevant feature changes against the same workload and settings; address
observed regressions in the affected slice and keep rendering/simulation settings
scalable. Device acceptance requires a tested export on the target hardware,
including input and interface usability. Exact Thor configuration, resolution,
frame-rate and memory budgets remain to be established; no numeric targets are
approved by this decision.

The above-average development PC was inspected October 28: AMD Ryzen 7 5800XT,
NVIDIA GeForce RTX 3070, approximately 32 GB RAM (31.9 GB reported), Windows 11 Pro.
Use it for development baselines; smooth desktop performance does not demonstrate
Thor readiness. Record hardware, renderer, resolution/settings, tested revision
and workload with measurements. Headless test timings are not rendered frame-time
or device-performance acceptance.

The daily vision audit runs at 06:00 America/Los_Angeles, including weekends,
separately from repository maintenance. Read the Bible and current evidence,
report condition and vision drift, and present a focused questionnaire. Return
owner feedback as concrete proposed decisions/roadmap edits for explicit approval
before applying them. This section records approval of the initial audit's
revised proposal; later proposals require their own approval. Owner scheduling
update, October 28: the existing audit moved from 07:00 to 06:00 and includes the
creative report, ten primary questions in an interactive questionnaire, and the
current status/work of other active project chats/agents. The separate repository
maintenance remains at 07:00. Do not reopen settled questions or treat unanswered
questionnaire items as decisions.

## Approved hierarchical framework — October 28, 2026

Owner approval: apply hierarchical ownership, relevant inherited standards,
controlled variation, explicit exceptions and contained changes across the existing
project. The operative principle remains in
[PROJECT_STANDARD.md](PROJECT_STANDARD.md#hierarchical-ownership-and-composition).

Owner follow-up: reformat the project around that plan, efficiently, without
duplicate systems or repeated checks of unchanged work. The
[project reformat roadmap](reformat-roadmap.md) is the single execution sequence
for this structural work, including ownership/data contracts, migration phases,
dependencies, validation reuse and completion evidence. It replaces the earlier
construction outline here. Feature roadmaps continue to own their gameplay and
visual acceptance requirements.

The reformat proceeds through bounded, reviewable changes with a usable connected
expedition. Existing design/mechanics authorities remain binding. This records the
approved direction. Current runtime phase status and validation evidence are
recorded in the reformat roadmap; documentation alone closes no feature/device gate.

## Approved creative direction — October 28, 2026

The owner authorized recording the questionnaire answers and subsequent correction;
see the [decision record](decisions/2026-10-28-opening-companionship-and-consequences.md)
and the Bible's corresponding owner-approved section. Lead with unease and mystery:
the player wakes in a Vastra storm, tries to escape, and three Sols guide them to
safety. One of those same individuals becomes the starter. Curiosity and personality
during shared travel establish attachment. Patient, nondestructive and respectful
approaches support earned trust; holding a Seal does not establish affection.

Civilization's dependence on Vastra grounds the human/habitat conflict. Combat
should connect strategy, leveling, training, journal discoveries and lore. Orbs
are prototype placeholders; production Sol species need their own models,
behaviors and animations, with independently retained individual affinity.
The named references are Monster Hunter, Pokemon, Pokemon Legends: Arceus and
The Legend of Zelda: Tears of the Kingdom; the proposed role of each remains
subject to review rather than becoming imported mechanics or final art direction.

The refusal route permits victory without ascension through a harder path,
permanently forfeits that starter's legendary manifestation, and carries lasting
relationship/story consequences. The owner withdrew the intervening answer
limiting consequences to difficulty and access. Exact scenes, penalties, warnings
and external save-rollback restrictions remain open; preserve starter survival
and do not create later in-game legendary-access loopholes.

Select the Thor configuration with the largest verified unit sales when reliable
evidence exists. No such ranking was verified; model, resolution, frame-rate and
memory budgets remain unapproved. Storm failure/checkpoint rules, exposure effects,
trust formulas and battle durations also remain open. Questions use an interactive
questionnaire. This documentation approval does not implement the opening or close
any acceptance gate; retain current correctness/playtest work and the connected
expedition as the development baseline.

## Approved opening delivery sequence — October 28, 2026

Author storm escape as the movement/sprinting tutorial; three Sols guide the
player out. After escape, their NPC owner explains that they left mysteriously,
permits keeping one after interaction-led bonding and explicit confirmation,
provides the first protective mask and basic instruction, and gives a teaching
battle before the journey to the first refuge camp. Preserve the chosen rescuer's
identity. Implement protection and any exposure together only after source
reconciliation and an authored specification; do not invent immunity, stamina,
upkeep, transfer bonuses, storm damage or failure rules. See the
[approved follow-up](decisions/2026-10-28-opening-companionship-and-consequences.md#approved-follow-up--tutorial-and-visual-identity).

Use strong stylized shapes and clear species silhouettes across the playable
refuge/habitat/encounter sample. Protective infrastructure establishes Vastra
dependence; human order versus living wilderness organizes the route. The first
journal discovery pairs observed Sol behavior with a useful habitat clue. Review
routine victories for opponent/terrain understanding and explore a changed but
enduring starter relationship on refusal, preserving the legendary lockout.
The existing refuge-return sample and current active work remain the development
baseline; this campaign sequence is an authored target, not delivered content.

## Historical starting point — October 26, 2026

The initial inspection and [development notes](development.md) established the
following historical baseline. It is not current completion status; subsequent
implementation evidence below and the feature roadmaps record later work.

| Area | Existing foundation | Missing capability |
| --- | --- | --- |
| Exploration | Seeded terrain, wetness/habitats, dry routes, eight-way movement, orthographic 3D plane | Accepted final presentation, richer authored places and encounters |
| Streaming | Bounded nearby chunks and deterministic reconstruction | Territory simulation independent of rendering lifetime |
| Vastra | Noise-derived concentration, an Examine display, overload fixed at zero | Mutable concentration/overload, replenishment, harvesting, restoration, storms |
| Persistence | Versioned expedition saves, validation, previous-save backup, generation migration | Sol identity, party/contracts, mutable world deltas, simulation clock and story state |
| Verification | Import, smoke/generation suites, diagnostics, CI maintenance PR | Gameplay contracts, manual acceptance and representative hardware measurements |
| Core gameplay | A refuge-to-landmark return journey | Sols, battles, capture, relationships, progression and narrative |

Prior recorded validation passed 2,331 smoke checks and 209 generation checks on a clean remote clone. This planning task inspected code and documents; it did not rerun those checks. Existing test counts do not establish compliance with the whole Bible.

## First playable target

Campaign opening target: wake in a Vastra storm, escape with three Sols' guidance,
reach safety, and continue with one of those same individuals as the starter.
Author this prologue under the approved creative direction above; its danger,
failure/checkpoint and exposure rules still need specification.

The existing development acceptance slice remains a short expedition in which the
player leaves a refuge with a starter, observes a wild Sol, reads environmental
conditions, resolves a tactical encounter, forms or declines a Seal contract, and
returns with persistent consequences. Save/load must preserve the same Sols and
outcomes. Integrate the approved opening with that loop without claiming the
current refuge/waystone route already implements the rescue.

For this slice, propose one starter and two encounter species using temporary assets, one compact authored route with adjacent wilderness, and one controlled human-disturbance/restoration example. This is a production scope proposal, not a reduction of Region One's approximately 151-Sol target or approval of species/class names. Use approved content where available and clearly labeled fixtures for unresolved authoring.

Keep all three pillars represented before expanding geography or the roster. Do not finish an enormous terrain simulator before testing whether collection and combat are enjoyable together.

## Milestone sequence

October 28 Vastra integration: the owner approved developing the authored storm
opening alongside the connected expedition and retconned combat/restoration
overload to a signed measure. See the [decision](decisions/2026-10-28-vastra-combat-and-restoration.md)
and [runtime integration](vastra-integration.md). Signed battle outcomes, natural
relaxation, bounded restorative assistance and current presentation advance D2/D4;
opening content and D6 storm/propagation acceptance remain outstanding.

### D0 — Accept and stabilize the exploration foundation

Depends on: current prototype. First implementation milestone.

- Manually walk the outbound/return journey, test pause/save/load/new-seed behavior, and inspect negative coordinates and route junctions.
- Current owner-selected presentation: full 3D player/scenery, retained terrain textures, perspective orbit/tilt/zoom, camera-relative walking and view-based streaming. This supersedes the earlier sprite direction; see [the October 27 decision](decisions/2026-10-27-full-3d-and-controls.md). Lighting, a saved-clock day/night cycle and basic clear/cloudy/rain weather are documented in [atmosphere](atmosphere.md). Refine readability and scale within that direction.
- Measure startup/rebuild stalls and continuous-travel frame p95/p99 on available hardware. Agree a target device, workload, memory budget, and acceptable frame budget before claiming portable-device readiness.
- Confirm the existing tests reproduce from the pinned engine environment. Keep CI merge/protection work on the repository roadmap.

Exit: a manually accepted exploration loop, recorded performance baseline/limitations, and a documented presentation decision. The visual-direction decision is now recorded; full manual journey and target-budget acceptance remain open. Fix observed blockers; do not rewrite functioning terrain solely to match an architectural preference.

### D1 — Establish persistent world and Sol contracts

Depends on: D0. Bible references: §§6, 20–29, 32, 62–63, 72–75.

- Define stable territory identifiers independently of streaming chunks. Territories own population/ecological state; render chunks remain disposable views.
- Separate generated terrain defaults from mutable saved deltas. Keep bounded near-player updates and explicit aggregate distant state.
- Add a simulation clock and explicit pause/load/catch-up policy. Proposed initial scope: bounded in-session catch-up; no wall-clock offline simulation until designed.
- Define species resources, ordinary evolution-lineage references, fixed lineage class, independently stored individual affinity, and individual IDs. The unratified 18-class roster must not be fabricated.
- Give starters, contracted creatures, and notable wild Sols stable individual identity. Use lightweight population records for ordinary distant wildlife rather than retaining every transient creature forever.
- Introduce typed domain events/signals for human activity, ecological changes, encounter outcomes, and relationship changes. Preserve clear ownership so one event cannot mutate several competing copies of state.
- Extend saves with explicit schema migrations for territory deltas, simulation time, and Sol records before those systems can affect player progress.

Exit: unload/reload and save/load preserve territory identity and a fixture Sol's ID, affinity, relationships, and location/contract state. Old expedition fixtures still load or fail safely according to documented compatibility. No duplicated creature or double-applied event appears after reconstruction.

### D2 — Implement foundational Vastra behavior

Depends on: D1. Bible references: §§7–18, 43–46, 74.

- Store independent tile concentration (0–100) and signed ecological overload (positive disturbed, negative restorative; bounds provisional), with region-configured replenishment/equalization parameters.
- Implement bounded replenishment, redistribution, sustainable harvesting, excessive harvesting, and recovery. Model human disturbance explicitly; ordinary natural/noncombat Sol activity does not originate overload; aggressive Vastra-powered abilities do, and healing abilities counteract it under the October 28 retcon.
- Make harvesting budgets account for multiple devices/users over simulation time. Repeated small requests must not bypass a regional limit.
- Persist changed state and timestamps. Unloading an area must not reset damage or grant duplicate recovery.
- Keep detailed numbers in Examine, with readable warnings where danger matters. Distinguish concentration effects from overload effects without inventing exposure symptoms or thresholds.
- Start with controlled fixtures and configurable experimental values. Record candidate rates for owner review rather than declaring numerical canon.

Exit: a healthy high-concentration region remains healthy; sustainable harvesting does not create overload; over-budget human activity does; recovery and save/load work consistently across chunk borders. Redistribution does not accidentally create energy or overload outside the designed source/sink rules. Storm generation is not required for this milestone.

### D3 — Add readable wild Sol encounters

Depends on: D1 and D2. Bible references: §§20–30, 59–64.

- Build the proposed small species set with authored habitat, footprint, temperament, and two or three readable behavior states.
- Represent avoidant, neutral, and assertive behaviors. Territorial aggression must not imply moral evil or spontaneous ecological damage.
- Add observation, approach/retreat, encounter initiation, and persistent notable sightings. Present approximately 2–4 nearby Sols as a provisional readability target, adjusted to context.
- Keep distant populations aggregate and bounded. Record migration/complex nesting as deferred, rather than implementing them to support the first encounter.

Exit: the player can recognize and re-encounter a notable individual; loading/unloading does not duplicate it; behaviors are visibly distinct; terrain and large footprints cannot trap encounters or block required travel permanently.

### D4 — Prove tactical combat

Depends on: D3 and approval of the minimum combat specification. Bible references: §§18, 30, 38–42.

The [combat roadmap](combat-roadmap.md) records the owner's October 28 priorities
and the proposed delivery sequence: readable action resolution first, then
complete consequence/outcome handling, measured routine/major pacing, player
expression, and broader combat systems. It does not close D4 acceptance or
approve unresolved mechanics.

- Agree the initial arena/grid, turn order, action economy, movement costs, ranges, collision, escape, and exhaustion/recovery contract before building the battle loop.
- Start with the ordinary one-allied-Sol versus one-opponent baseline, a small authored move set, clear enemy intent, movement, statuses, and understandable feedback.
- Reuse terrain footprint/traversal contracts where valid; keep battle state separate from world rendering and deterministic enough to reproduce failures.
- Apply environmental affinity matching to outgoing damage only. For multi-tile Sols select the strongest matching tile; mismatched tiles contribute no affinity bonus. Never mutate permanent stats through this effect.
- Keep the concentration-to-damage curve and proposed +99% ceiling behind an explicit tuning decision. The Bible's canon table does not turn its unresolved formula or proposed ceiling into a finalized rule.
- Treat ordinary defeat as exhaustion. Preserve the starter's no-death invariant; do not introduce permanent-loss mechanics.

Exit: a battle can start, resolve, or end through an agreed escape path and return safely to exploration. Player and AI share legality rules; footprint bonus selection is correct; exhaustion cannot silently kill or duplicate a Sol. Decide and test whether saving mid-battle is supported or safely unavailable.

### D5 — Connect Seals, relationships, and progression

Depends on: D4 and approval of capture/relationship rules. Bible references: §§24–25, 31–40, 43.

- Implement combat capture and deliberate peaceful interaction as separate routes. The standard peaceful route excludes aggressive Sols under the current design.
- Preserve the same individual through wild encounter, sealing, party membership, release, and subsequent encounter. A Seal holds the actual Sol rather than producing a copy.
- Track contractual authority separately from trust and command response; expose understandable feedback without mandatory relationship micromanagement.
- Add a small progression loop, recovery, and one ordinary evolution transition once its content/rules are approved. Preserve lineage class and individual affinity through ordinary evolution.
- Use approved capture/progression values or labeled experimental fixtures. Do not finalize doubled capture factors, transfer bonuses, IV/EV formulas, inheritance weights, or universal evolution levels by implication.
- Add the eight-slot equipment data contract and an initial mask/protection interaction only when its gameplay is defined. No consumable oxygen/filter maintenance loop.

Exit: the entire expedition target is playable and saveable, with a visible choice between battle and eligible peaceful interaction. Capture does not guarantee affection or obedience; ordinary defeat is recoverable; old saves migrate; reload cannot duplicate or reroll an already resolved individual/outcome.

### D6 — Expand ecological consequences and storms

Depends on: the accepted D5 slice and approved ecological tuning. Bible references: §§15–17, 25–30, 44–45, 59–65.

- Add population-sensitive restoration with diminishing returns and carrying-capacity controls. Depletion must remain recoverable without compulsory player intervention.
- Add adjacent overload propagation and explicit human disturbance events. Define event ordering/time steps so camera movement or update order cannot change outcomes arbitrarily.
- Implement procedural storm eligibility over nine contiguous tiles in a 3×3 footprint, including across streaming boundaries. Eligibility permits a probability evaluation; it never guarantees a storm.
- Track thresholds, probabilities, duration, cooldowns, exposure, warnings, and protection as reviewed configuration. Allow authored narrative exceptions through a separate explicit path.
- Large Sols may redistribute existing overload. Aggressive Vastra-powered abilities originate overload on affected tiles; healing abilities can reduce it below zero. Ordinary noncombat Sol activity remains separate.
- Preserve essential story access and a recovery route. Keep complex food webs, migration, and nesting outside this milestone unless separately justified.

Exit: causal disturbance → overload → possible storm → recovery can be observed and explained. Tests cover high concentration without overload, eight-versus-nine eligible tiles, cross-boundary footprints, scripted exceptions, retreat access, and aggregate/near simulation transitions without double-counting.

### D7 — Deliver Region One content and narrative

Depends on: accepted core loop and ecology; narrative decisions before affected story work. Bible references: §§3–5, 23–24, 38–40, 48–58.

Class passives and individual stat/training rules are implemented for the current
species slice; see [class buffs](class-buffs.md) and [individual stats](sol-stats.md).
Production balance and authored evolution content remain pending.

- Build content incrementally around authored settlements, connected routes, dangerous wilderness, NPC sightings, and journal discoveries. Validate one content batch before multiplying the roster.
- Ratify classes/species/affinities and expand toward the approximately 151-Sol Region One roster and level-55 cap. Track authored, implemented, balanced, and validated counts separately.
- Support three ordinary forms where authored. Legendary manifestation is a distinct primordial individual and a unique event, not an ordinary fourth level-up stage.
- Resolve the antagonist's identity/plan and author the approved refusal branch before implementing irreversible starter choice state: victory remains possible through a harder path, permanent starter-legendary lockout and lasting relationship/story consequences. Exact consequences and scenes remain open. The refusal lockout cannot be silently undone by a later collection system.
- Preserve starter survival, original/vessel/legendary identity, one legendary individual per lineage reality, and distinct separation versus destructive-extraction processes.
- Deliver a complete Region One ending with variations in which humanity survives. Preserve intentional mysteries rather than inventing explanations to fill content gaps.

Exit: a start-to-ending playthrough completes through every approved major branch, including refusal; saves retain irreversible choices correctly; required ultimate abilities are available within the cap; no content gate requires an unresolved formula or deferred online feature.

### D8 — Prepare and verify a single-player release

Depends on: D7 and agreed release scope. Bible references: §§42–47, 75.

- Complete onboarding, control readability, journal and settings/accessibility requirements identified through playtesting.
- Profile long journeys, dense encounters, saves, and ecological events on the agreed target hardware. Measure worst cases as well as averages.
- Verify export/build reproducibility, input/device behavior, migration, malformed-save handling, recovery, and long-running simulation stability.
- Review asset provenance, release content, known limitations, and release notes against the tested commit. Follow repository release/tag rules.

Exit: the actual exported build passes a documented acceptance checklist and matches its recorded commit. A successful editor run alone is insufficient.

## Decisions to resolve at the point they block work

For every non-generation entry below, first reconcile SolHunterSource implementation, tests, and decision evidence with confirmed Bible canon. These are lookup/reconciliation gates, not automatic requests to redesign or ask the owner again. Only remaining gaps or conflicts require a new decision. The table has not yet been fully audited against that source.

| Decision | Needed before | Safe work while unresolved |
| --- | --- | --- |
| Presentation direction and target performance budgets | D0 acceptance | Current prototype measurement and usability review |
| Simulation clock, catch-up scope, territory ownership | D1 completion | Save-schema and domain-contract proposals |
| Vastra budgets, equilibrium/propagation/recovery rates | D2 production behavior; D6 ecology | Invariant tests and explicitly experimental fixtures |
| Minimum grid/action economy and damage model | D4 implementation | Encounter identity, movement and data ownership |
| Affinity colors and concentration damage curve/ceiling | Final effects/combat tuning | Matching/footprint semantics and placeholder labels |
| Capture, obedience, growth and ordinary evolution rules | D5 production loop | Persistent individual/contract data and UI prototypes |
| Storm, protection, human exposure and carrying-capacity rules | D6 production behavior | Eligibility geometry, configuration and event plumbing |
| Final classes, species roster, moves and progression | Each D7 content batch | Small approved species slice and content validation |
| Refusal ending, legendary memory/bond rules, collection conflict | D7 climax and late-game acquisition | Earlier narrative and explicit unresolved branch contracts |

Do not present temporary tuning as settled canon. Where a feature has no approved rule, prepare a concrete proposal or fixture and identify the decision required to ship it.

## Deferred scope

Keep multiverse reveals, online competition/leaderboards, anti-cheat, Hardcore rules, the superboss, advanced form-shifting, advanced Seal escape/resistance, and complex migration/nesting out of the first slice. Legendary separation and late-game collection require later authored decisions. Do not add permadeath, unrestricted hybrids, mandatory filter/oxygen management, or a copied external type-effectiveness chart.

Use stable IDs and clear domain boundaries to leave room for future systems; do not build networking or speculative infrastructure solely because future expansion is mentioned.

## How to execute the plan

Deliver one coherent behavior change per topic branch/PR with its acceptance evidence, relevant save migrations, and updated documentation. Add tests for meaningful gameplay contracts and cross-system failures, alongside manual experience acceptance. Keep implementation claims tied to code and observed behavior rather than checked boxes alone.

D0 development has started. The owner selected upright billboards; the explorer now uses one, rebuilds prepare the visible area first, and the rendered journey benchmark records phase-specific performance. The owner subsequently requested a [solid 3D prototype](solid-3d-prototype.md) to judge genuine environmental depth; it is the current F5 entry while the original view remains available for comparison. See [D0 implementation and evidence](d0-exploration.md). Player acceptance and target-device budgets remain open before declaring D0 complete. D1's territory/individual/save foundation has begun under the owner's subsequent direction; this does not close those acceptance gates.

Subsequent exploration work delivered [shared building collision and safe migration](building-collision.md), followed by [pixel-art water/banks and player occlusion readability](water-and-visibility.md). These are implemented work packages, not a substitute for the remaining manual/device acceptance gates.

D1 now has an initial [persistent domain and save foundation](d1-persistent-foundation.md): independent territory observations, stable individual IDs, explicit relationship evidence, a bounded activity clock, and save-format migration. Live Sol content, population simulation, and the remaining D1 acceptance work are still outstanding.

D2 has begun with [atomic human Vastra activity](vastra-human-activity.md): shared per-region/tick harvest usage, explicit authored overload effects, saved producer receipts, and replay-safe loading. This reusable interface does not yet add a player harvesting action or production budgets. Natural replenishment/recovery and the rest of D2 remain outstanding; starting this slice does not declare D0 or D1 fully accepted.

D2 subsequently adds [bounded natural replenishment and recovery](vastra-natural-recovery.md): live clock-driven baseline overload healing, explicit-profile concentration balancing, and saved scheduling/interval progress. Production regional profiles, spatial redistribution, population assistance, and authored human interactions remain outstanding. No whole milestone is declared complete.

The next slice adds [runtime population summaries](population-summaries.md) over explicitly published complete home definitions and authoritative individual ownership. Unknown populations remain unknown, carrying capacity stays separately authored, and cache state never affects baseline recovery or save output. Wildlife generation, observation aging, and production assisted-recovery tuning remain future work.

D3 begins with [three authored Sol sightings](authored-sol-sightings.md): upright pixel placeholders, provisional source-derived species metadata, stable saved individuals, and configurable proximity reactions along the existing trail. This is visible presentation groundwork, not completed encounters, roaming, combat, or capture. Remaining earlier-milestone gates stay open.

D3 now adds [deliberate observation and saved Field Notes](sol-observation-journal.md): F records a nearby individual once while retained, J opens the saved Sightings tab, and first-seen metadata survives reload. Observation distance is Inspector tuning; source-bounded recent-journal retention does not delete individuals or grant trust/capture rewards. Roaming and actual encounter resolution remain outstanding.

D3 subsequently adds [bounded local reactions](local-sol-reactions.md): real avoidant flight, neutral approach, guard/return behavior, saved current positions, and Inspector movement tuning. Terrain legality, fixed home identity, pause, reload, and observation-at-current-position are covered. This is a limited authored controller, not full source AI, production wildlife generation, or battle initiation.

D3 now has [encounter initiation and withdrawal](encounter-initiation.md): deliberate R approach and owner-confirmed warned contact with the guarding Seedmote. A runtime face-to-face panel supports recording a sighting and withdrawal, with world activity/persistence guards.

D4 now has a [first playable battle](first-playable-battle.md): all four requested steps are implemented—explicit starter selection, saved companion/deployment, tactical movement/basic attacks/enemy turns, and persistent victory/exhaustion/retreat. Source-derived mechanics and provisional Inspector profiles are documented with 6,335 passing headless checks and 58 rendered battle checks. Capture, growth, wild replacement, broader combat systems, and manual milestone acceptance remain outstanding.

The owner's subsequent [affinity orb direction](affinity-orbs.md) replaces Sol
silhouettes with hovering pixel spheres and basic affinity colors/effects in
exploration and battle. Shared Inspector settings control presentation; saved
individual affinity remains authoritative and no combat bonuses are added.

The [affinity/move/imprint slice](affinity-moves-imprints.md) records the owner's
eight-affinity decisions in the Bible and connects four-slot remembered movebooks,
explicit species eligibility, shared field prototypes, lasting battle-wide tile
imprints, and independent condition recovery. This advances D4/D5 with migration
and save contracts; production progression, wildlife rarity rates, broader ability
content and manual milestone acceptance remain open.

The next [battle feedback slice](battle-feedback.md) adds capped damage/healing
numbers, affinity pulses, result/imprint recaps, move tooltips, and keyboard field
target confirmation/cancellation. It improves D4 readability while preserving
the existing action, outcome, persistence and balance rules.

[Repeatable authored wildlife homes](wild-population-recovery.md) now recover
after saved active-time delays through distinct successor identities. Local
vacant admission, retained old/owned records, fresh guard warnings, population
projections, legacy full waits, movebooks and persistent imprints are covered.
This is a bounded source-derived three-home loop, not production wildlife
generation, affinity inheritance, reproduction, or a finalized rarity system.

[Field-aware enemies, testing Seals and progression](ai-seals-progression.md)
implement the next requested steps 2–4: shared legal enemy move planning, visible
capture odds and persistent captured companions, party/storage selection, and
participating victory XP with remembered level unlocks. Owner choices are unlimited
testing Seals and editable provisional milestones 4/8/14. Story gates, genetics,
evolution, battle switching, economy, production learnsets and manual acceptance
remain outstanding.
