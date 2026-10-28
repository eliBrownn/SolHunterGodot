# Complete expedition integration review

October 28, 2026. Owner: Fine Detail, through the owner-authorized Bible RoadMap
handoff. Status: read-only audit complete; combined rendered acceptance pending
the active implementation checkpoint. This is an evidence/checklist map under
[PROJECT_STANDARD](PROJECT_STANDARD.md), not a competing roadmap or design source.
The [development plan](development-plan.md) retains milestone authority and the
Bible retains design authority. No D0–D5 completion or owner/device acceptance is
declared here.

## Initial state and sequencing

The shared checkout is `codex/cohesive-world-sample` at
`96f384ffbd12c227b964b5f433a76901e8c3879f`, with substantial tracked and untracked
implementation work. A commit ID alone does not identify this playable tree.
Preserve dirty work, the Bible and the current branch. No feature code was changed
by this initial audit. Do not run a full validator or profile concurrently with
another workstream's measurement. Capture source hashes before and after each
later combined run; changed gameplay/rendering inputs invalidate a stable-tree
acceptance claim even if every assertion passes.

| Workstream | Current dependency | Integration handoff gate |
| --- | --- | --- |
| Plan Sol species roster | Crown-Ear flight and Reedback swimming are being connected to navigation, saved movement and animation; dedicated traversal pilot is in progress | Report its actual test/render evidence and intended normal-versus-pilot rollout; do not convert flight/swimming back into ground movement to satisfy an old fixture |
| Optimize | Another six-path optimization pass is implemented and under verification/measurement | Wait for measurement/validation to finish; retain current caching and resumable chunk publication; verify source hashes afterward |
| Sol Behavior | Selected owned companion ground-following and personality interactions are starting | Verify selected identity, legal spacing, encounter transitions, culling/rebuild and save/load through its delivered interfaces; do not implement a second follower |
| Combat | Measured pacing fixtures are being revised for terrain payoff, heal/hit decisions and the major probe | Exercise the revised fixtures and current production playback separately; fixture labels and shorter waits are not owner-approved battle targets |
| World Generation | Bounded winding-route/pond-diversity slice is starting | Rebuild routes from the delivered generator, verify return and pond access, preserve its generation/version decisions; do not restore old terrain to make travel tests pass |

Use compact thread snapshots to confirm these gates; “active” alone does not say
which files are stable. The current audit intentionally runs no engine workload.

## Existing evidence and its limits

| Evidence | Verified initial audit finding | Limit for this review |
| --- | --- | --- |
| `artifacts/sol_procedural_ground/validate.log` | Shared Godot 4.7.2 validator ended with the success marker; 53 suite reports total 16,815 assertions, zero failed assertions and zero `ERROR:` / `SCRIPT ERROR:` lines | Newer than the failed optimization snapshots; it precedes current flight/swim, companionship, pacing, terrain and optimization changes. Headless success does not cover GPU-only silhouette assertions |
| `tools/profile_current_expedition.gd`, `artifacts/optimization/latest-journey/` | Existing runner uses real-time movement actions, normal AI/clock/automatic contact, outbound/return and negative coordinates, pause and full current-format save/new/load comparison | Existing journey explicitly excludes combat acceptance and long-turnover/max-camera workloads; no controller or complete battle/collection journey is proved |
| `tests/controller_expedition.gd`, `docs/controller-input.md` | Covers actual injected joypad events, native popups, menus, details, remapping, save/load, deployment/actions/Seal/retreat and takeover | The fixture disables wilderness and Sol movement and uses smoke mode outside selected movement/time checks; rendered attempt was interrupted by desktop input. It is not normal live-AI controller acceptance or physical hardware evidence |
| `tests/sol_species_catalog.gd`, `tests/sol_procedural_ground.gd` | Three catalog species have model/identity/affinity/ownership contracts and procedural ground checks; ground documentation records 222 headless/rendered checks | Catalog journey uses the explicit pilot scene, teleport/setup fixtures, direct result setup and deterministic capture probes. Do not describe these as an unassisted normal expedition |
| `tests/combat_consequences.gd`, `tests/first_playable_battle.gd`, `tests/ai_seals_progression.gd` | Terminal capture, withdrawal, victory/exhaustion, receipt replay rejection, HP and imprints have targeted coverage | Some outcomes set fixture HP/status/fields or supply an explicit capture roll. Retain those tests, but label them separately from the later normal journey |
| `tests/presentation.gd`, older optimization rendered reports | Canopy/foreground silhouette checks exist; the older optimization study reproduced two failing GPU assertions even with captured pre-optimization scripts | Latest headless validation cannot settle these pixel checks. Reproduce on current rendering before changing presentation or claiming the old failure remains |
| `tests/fog_horizon.gd`, `tests/view_3d.gd` | Current shared run passes 131 fog and 664 view checks, including steady fog and temporary coverage while chunk preparation is incomplete | Repeat rendered camera turns/zoom and inspect boundaries after new terrain/caching work. Earlier 130-check fog evidence predates resumable publication |
| `tests/ui_playtest_blockers.gd`, inspection/Sol/field-menu suites | Shared baseline reports 59 / 22 / 41 / 30 checks respectively | Need current rendered readability, actual model fitting and input transitions with normal movement and the delivered companion |

The default F5 scene currently uses the bounded nature composition. Its sighting
resource enables normal species behavior and wilderness, but has no catalog
placements; authored trail sightings still use Seedmote/Bramblepup. Crown-Ear,
Reedback and Bellroot are explicitly placed in the species/traversal pilot scenes.
Their resource availability alone does not put those three models in the normal
F5 population. Preserve this content distinction until the owning workstream
reports its rollout; do not silently expand the roster during acceptance.

## Combined rendered checklist

Record each row as **pass**, **fail with reproduction**, **blocked by a named
dependency**, or **unsupported/deferred**. A missing feature must not receive a
pass because a fixture bypasses it. Keep normal-play and controlled scenario
results in separate report sections with the exact scene/settings and method.

| ID | Exercise on the stable combined tree | Required evidence |
| --- | --- | --- |
| I0 | Verify pinned engine, branch/base, hardware/renderer/viewport and actual resources; take complete source fingerprints | Before/after manifests, process commands/exit status and logs with no unclassified engine errors; another agent's validator/profile is not running |
| I1 | Start a fresh normal expedition with `smoke_mode == false`, default species profiles, roaming, warning/contact and ecology enabled | Resource snapshots, initial refuge capture, admitted individual IDs; no movement/AI disabling, population replacement or new gameplay tuning to make the route easier |
| I2 | Choose the companion through the real chooser; open party/details and inspect the selected individual's actual presentation | Selected ID/class/affinity/IVs/moves/HP recorded; model or explicitly documented legacy orb fallback; preview fits at ordinary and enlarged text |
| I3 | Walk to wilderness/waystone and return through actual movement input; visit negative coordinates and a changed route/pond junction | Route computed from current traversal, path completion/objective evidence, captures and bounded chunk/job/derived-cache counts; no travel teleporting |
| I4 | Orbit/tilt/zoom/reset while walking and stopped, including low-angle wide zoom and a rapid reversal | Stable fog distances, coverage of visible pending/partially prepared terrain, no empty boundary/lingering temporary mesh, readable actor under real canopy and no persistent-state mutation from camera work |
| I5 | Observe a moving named Sol through pointed/context or controller targeting; inspect terrain and Sol details without hover | Selected/current identity and cell, discovery and UI captures; stale target revalidation, GUI shielding and correct passability/condition data; observation causes no combat or state rerolls |
| I6 | Run controller/menu/inspection through live AI, not only the isolated fixture; switch back to desktop | Injected events documented separately from physical devices; no menu-input movement/actions, consistent confirm/back, scrollable details, live-menu time versus true pause; settings saved only to test-local paths |
| I7 | Begin a real encounter, inspect/observe, and withdraw before battle; then deploy and act in a supported battle | Same target ID, explicit decisions, presented action/HP/status consequences in order, no action while playback/modal gates are active, clean return to exploration |
| I8 | Exercise movement, a direct move and an available field/terrain interaction using the current legal action authorities | Actual command/receipt trace and before/after HP, positions, fields and budget. If the normal loadout lacks a field move, use a separately labelled authored scenario rather than silently editing that loadout |
| I9 | Exercise supported Seal success/failure, confirmed battle retreat and exhaustion/recovery | Prefer an unchanged-rule normal scenario; retain controlled deterministic outcome cases as separately labelled supplemental evidence. Record actual capture seed/attempts instead of replacing probability, enemy HP or saves to force a result. Verify one completion receipt, the same acquired ID, no duplicate rewards/XP and correct return/recovery location |
| I10 | Review new ground following, flight/swimming and revised pacing through their delivered scenarios | Following on the normal selected companion; species pilot clearly distinguished from F5 roster. Ground legality and water/air transitions remain the owning navigation authority; record any unsupported combat traversal. Pacing measurements and player feedback remain different evidence |
| I11 | At refuge save, create another expedition and load; compare the complete persistent state while time is held by the existing pause layer | Position/objectives plus clock, territories, individual IDs/affinities/traits/moves, ownership, outcomes, imprints and observations compare exactly; incompatible input leaves the current world intact; test saves do not touch the normal player's expedition |
| I12 | Repeat current GPU/picking/layout regressions and run the shared validator after workstreams settle | Current rendered presentation/fog/view/terrain/model/menu/controller evidence, useful screenshots, one fresh shared-validator log and source drift classification. Do not replace failing silhouette/identity checks with weaker assertions |
| I13 | Review performance separately on the same unchanged workload and settings | Travel/menu/encounter frame p95/p99 and worst frames, memory, startup/rebuild and preparation costs; identify route planning, capture waits and screenshot stalls. No acceptance budget, historical speedup or physical Thor claim without the corresponding evidence |

Final automated evidence can qualify this combined desktop slice. Owner feel,
onboarding, physical controller, actual export and Thor qualification remain
separate unchecked gates. The intended Thor configuration and numeric budgets
are still open; they do not block functional desktop verification.

## Follow-on D5/D2 backlog, outside this acceptance implementation

Read-only reconciliation uses SolHunterSource commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`, verified through the GitHub connector.
The local reference branch points to the same commit; local Git directory access
failed, so do not infer a clean source worktree from readable local files.
These are proposals for later bounded slices, not authorization to ship three
new systems during this review.

| Gap / classification | Smallest connected follow-on proposal | Evidence and remaining gate |
| --- | --- | --- |
| Peaceful acquisition: existing provisional source behavior, absent from Godot's current live interaction path | One explicitly eligible neutral individual offers an invitation via the existing target/confirmation model. Commit to the existing individual/party-storage authority, with current range/disposition/availability revalidation, no battle XP, stable home identity and retry-safe ownership. Keep aggressive/territorial/cautious cases ineligible under the reconciled prototype policy; cancellation/stale targets consume nothing | [Implementation](https://github.com/eliBrownn/SolHunterSource/blob/d6f0902d77ed46a2f7d251c354792a4cc9210bc4/src/systems/tactics/peaceful_acquisition.py) and [tests](https://github.com/eliBrownn/SolHunterSource/blob/d6f0902d77ed46a2f7d251c354792a4cc9210bc4/tests/test_peaceful_acquisition.py) distinguish deterministic accepted invitations from battle odds and finite/testing Seal stock. Godot currently has no equivalent finite Basic Seal inventory; the exact authored eligibility and supply/content policy need reconciliation before rollout. Do not add a whole inventory system or copy provisional numeric rules during acceptance |
| Live relationship consequences: optional evidence exists; an obedience/affection formula is not established | Coordinate with Sol Behavior's active companion work. A bounded first successful existing refuge recovery could record neutral care evidence for that same owned Sol, without changing trust, affection or commands. Preserve unknown versus zero and existing history; no-op recovery adds nothing; repeated care is idempotent and full history does not block healing | [Care contract](https://github.com/eliBrownn/SolHunterSource/blob/d6f0902d77ed46a2f7d251c354792a4cc9210bc4/docs/coordination/care-memory-events.md), [healing caller](https://github.com/eliBrownn/SolHunterSource/blob/d6f0902d77ed46a2f7d251c354792a4cc9210bc4/src/systems/tactics/healing.py) and [continuity tests](https://github.com/eliBrownn/SolHunterSource/blob/d6f0902d77ed46a2f7d251c354792a4cc9210bc4/tests/test_sol_relationships.py) establish evidence, not obedience. [Follow-on audit](https://github.com/eliBrownn/SolHunterSource/blob/d6f0902d77ed46a2f7d251c354792a4cc9210bc4/docs/coordination/sol-relationship-evidence.md) explicitly keeps growth/decay/behavioral thresholds open. Actual relationship consequences require authored policy; this proposed record alone must not be advertised as delivered consequences |
| Controlled Vastra disturbance/recovery: human-event/recovery APIs implemented, normal-play producer/content absent | One authored human disturbance at a named test site invokes the existing stable actor/sequence receipt once; inspection shows independent concentration/overload, saved active time services existing bounded recovery, and return/save/load retain the same event and recovery progress. Label experimental magnitude/rates and grant no new item, currency or harvesting reward | [Human contract/caller audit](https://github.com/eliBrownn/SolHunterSource/blob/d6f0902d77ed46a2f7d251c354792a4cc9210bc4/docs/coordination/vastra-human-activity.md), Godot [human activity](vastra-human-activity.md), [natural recovery](vastra-natural-recovery.md), `tests/human_vastra_activity.gd` and `tests/vastra_natural.gd`. The source does not supply an already-authored live producer. Owner/content decision remains which activity/site and explicit effect the example represents. Never attach overload to ordinary healing, movement, natural Sol behavior or spawn-safety repairs |

The first two proposals do not implement the storm rescue, narrative bonding,
refusal consequences or advanced Seal resistance. The third does not implement
storms, exposure, carrying capacity or spatial redistribution. These missing
capabilities remain visible backlog; integration acceptance must not conceal them.
