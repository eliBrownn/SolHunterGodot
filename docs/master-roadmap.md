# Master delivery roadmap

Owner-requested consolidation: October 31, 2026.
Status: ordered execution plan; completion remains evidence-based.

This is the entry point for the order of work across the project's roadmaps.
It sequences existing steps rather than approving new mechanics. The
[project standard](PROJECT_STANDARD.md) owns workflow and the Bible owns design.
The [world roadmap](world-exploration-roadmap.md) retains N0-N7 nature-loop
acceptance and cross-feature intake evidence. Feature roadmaps retain their
detailed contracts, phase definitions and validation receipts. Read their latest
dated evidence before acting: older status tables can lag implementation.

## How to use this order

Work through the numbered stages below. Within a stage, follow the row order
unless the dependency column permits overlap. An implemented step needs its
remaining review or verification, not another implementation. Complete a focused
playtest between the world roadmap's six playtest-resolution stages.

The default queue is not a requirement to finish every domain before touching
the next one. Fix a blocker where it appears. UI and relevant performance checks
travel with each feature. Optional relics, full weather, environmental storms,
mist interaction, hydrology, roster expansion and threading are not prerequisites
for N6. N7 requires owner nature-loop acceptance. Campaign and Thor acceptance
remain deferred under the current direction.

Status vocabulary: **Implemented** means recorded engineering evidence exists;
**Review** means acceptance remains; **Open** means unfinished delivery;
**Conditional** means proceed only when its stated trigger is met;
**Deferred** means later scope. This document does not certify the current build.

## 0. Preserve completed foundations and establish the candidate

| Order | Work and owning steps | Current status / exit |
| --- | --- | --- |
| 0.1 | [Reformat R0-R8](reformat-roadmap.md): retain owners, paths, contracts and existing evidence | Desktop engineering complete at recorded revision `2f13c5a`; 52,274 checks passed there. Owner playable review remains; later changes need their own evidence. No architecture restart. |
| 0.2 | [Lab plugin L0-L5](development-workstation.md#current-workflow-and-l5-evidence--october-31-2026): review existing editor workflow | Engineering complete for 30 registered stations; owner usability review remains. Resolve concrete tooling blockers alongside affected work; tooling acceptance does not block normal-game nature review. |
| 0.3 | [Alpha intake](world-exploration-roadmap.md#alpha-integration-register--october-31-2026): identify the runtime/catalog/bake/settings/assets under review | Preserve active work and record exact inputs. The five authorized alpha implementation steps are closed in the [runtime contract](readiness-alpha-contract.md#alpha-implementation-closeout--october-31-2026); experience acceptance remains open. |

## 1. Playtest the current loop and close reliability defects

| Order | Work and owning steps | Dependency / exit |
| --- | --- | --- |
| 1.1 | Play the existing N0-N6 candidate: observe, cooperate, battle, recover, return and save/load | Start with current implementation. Record confusing choices, pacing, legibility and the next useful goal; choose the weakest part. This is diagnostic playtesting, not premature N6 sign-off. |
| 1.2 | Resolve the [combined-build blocker](world-exploration-roadmap.md#known-unresolved-combined-build-evidence) | Recovery can pass 54 assertions then fail with a native shutdown access violation. Keep failed receipts and strict exit/error handling. Stay on Godot 4.7.2; do not treat assertion success as a clean process exit. |
| 1.3 | Validate the candidate and reconcile stale completion claims | Apply the standard's relevant import, ownership, integration and normal-input checks to pinned inputs. A clean combined gate is required for integration acceptance, but investigation need not stop independent feature work. |

## 2. Stabilize travel, visibility and the performance baseline

| Order | Work and owning steps | Dependency / exit |
| --- | --- | --- |
| 2.1 | [World playtest stage 1](world-exploration-roadmap.md#playtest-resolution-sequence--october-31-2026): bounded preparation/residence, independent visibility and fog | Implemented with focused evidence and reported owner performance improvement. Finish transition/return review, including ordinary and low camera angles. |
| 2.2 | World playtest stage 2: shorter grass range, distant coverage, plant coexistence and height ranges | Implemented for playtest in the alpha register. Review close/medium/wide transitions and coexistence; preserve canonical grass supply. |
| 2.3 | [Concurrency MT0](runtime-concurrency-roadmap.md#delivery-sequence-and-gates): freeze inputs and measure cold loading, travel and populated-save workloads separately | After the relevant streaming changes settle. Establish an active-gameplay baseline; old smoke-mode timings are not acceptance. Concurrency implementation requires its own isolated branch/worktree under that roadmap. |
| 2.4 | MT1: address the largest confirmed stalls, extract equivalent serial boundaries, stage startup and bound publication/cleanup | Conditional on MT0 findings. Do useful serial fixes before choosing workers. Preserve matching bakes; do not rebuild or preload the entire palette without evidence. |

## 3. Make the environment coherent and readable

| Order | Work and owning steps | Dependency / exit |
| --- | --- | --- |
| 3.1 | [Weather WX0 -> WX1](weather-roadmap.md#delivery-sequence): shared contract and reconstructible wind | Reuse existing saved-clock gust work; prove gaps rather than duplicating it. Shared weather remains planned as a complete delivery. |
| 3.2 | WX2: connect grass, shrubs and crowns to shared conditions | After WX1. Review coherent motion in actual streamed scenery, pause and reload. |
| 3.3 | [World playtest stage 3](world-exploration-roadmap.md#alpha-integration-register--october-31-2026), [Vastra V1](vastra-integration.md#approved-ecology-delivery--october-31-2026), current visual acceptance | Reserve saturation/posture and render-wide coverage are implemented for playtest. Review low/mid/full foliage and additive wind; retain species anatomy/hue and camera-independent accounting. |
| 3.4 | World playtest stage 4 and V2 circulation: emanation, currents, real recipients, roots, repair and feeding | Preserve implemented finite-speed ambient overflow. Finish actual endpoint, split/merge, fair allocation and visible-arrival review; do not replace conserved transfers with cosmetic paths. |
| 3.5 | World playtest stage 5: reserve decay and additional overload loss | After stage 4 review. Retain the owning document's proposal distinction; reconcile and author the actual contract/tuning before changing energy accounting. Full storage must redirect overflow safely. |
| 3.6 | World playtest stage 6: persistent distant-tree appearance and separate reusable billboard cache | After the preceding focused playtests. Identity and meaningful condition survive travel/save/load; wind and tiny changes must not invalidate the cache continuously. |
| 3.7 | WX3 -> WX4 -> WX5: shared clouds/rain/audio, geographic exposure, connected acceptance | Extend the proven wind foundation. Can continue alongside later nature work; full weather is not an N6 blocker. |

## 4. Close the nature-only expedition, in N-gate order

These are acceptance and gap-closing passes over existing alpha work. Do not
restart implemented actions because an older feature backlog still says planned.

| Order | Work and owning steps | Dependency / exit |
| --- | --- | --- |
| 4.1 | [N0](world-exploration-roadmap.md#nature-delivery-sequence), terrain T0-T4/T4a and W1-W3 as needed | Confirm the existing compact area, real IDs, reachable rest/grove/habitat/crossing, essential routes and large-Sol clearance. Fix local grading, grounding or shoreline blockers; full T6 hydrology is unnecessary. |
| 4.2 | N1, V1-V2 and Vastra visual review | With N0, confirm distinct healthy/depleted/alarmed evidence and real circulation. Accept the required readability without waiting for experimental mist. |
| 4.3 | N2: durable findings and natural leads | With N0, verify defeat, revisit and save/load retention; recent sightings cannot evict learned knowledge. |
| 4.4 | N3: safe rest, legal preparation and two bounded companion interactions | With N0, verify actual recovery, retained identity, useful outcomes, unsupported actions and return preparation without NPCs. |
| 4.5 | N4: three distinct discoveries and peaceful choices | After N1-N3. Prove a useful battle-free outing and different choices/payoffs at the three situations. Add only the bounded behavior needed for those interactions. |
| 4.6 | [Combat C0 -> C1 -> C2 -> C3 -> C4 -> C5](combat-roadmap.md#migration-gates), N5 and V5 | Implementation exists in the alpha. Verify contract/traces, scheduler, committed-plan legality/AI, authoring UI, storm/exposure/withdrawal, and once-only outcomes/recovery in that order. Recheck changed dependencies; preserve the continuing world and local battle ownership. |
| 4.7 | N6 and the relevant W0/W6 experience review | After N4-N5, replay observation, companionship, combat and preparation outings with revisit/save/load. Obtain owner acceptance of useful choices, consequences and a next goal; record remaining weaknesses. |

## 5. Finish UI and input closure alongside nature acceptance

| Order | Work and owning steps | Dependency / exit |
| --- | --- | --- |
| 5.1 | [UI phases 0-4](ui-ux-roadmap.md#implementation-sequence) and nature/plan UX | Retain implemented desktop interactions; complete focus, scaling, stale-action, risk and plan readability review with stage 4. Verify actual controller journeys. |
| 5.2 | UI phase 6: remaining settings persistence, reduced effects and binding-aware prompts | Can overlap stages 3-4. Remapping already has newer implementation evidence; do not reimplement it from the stale phase table. Onboarding content waits for its authored sequence. |
| 5.3 | UI phase 7 preliminary desktop usability | Review dense targets, long names, night/rain and representative users as features land. Final exported/device acceptance belongs to stage 12. |

## 6. Extend living behavior and ecological consequences

| Order | Work and owning steps | Dependency / exit |
| --- | --- | --- |
| 6.1 | [Sol behavior phases 1-4](sol-behavior-roadmap.md#current-audit--october-28-2026): close movement/reaction/species feel review | Use the accepted expedition and current inherited behavior library. Add larger-footprint support before affected species; pursuit needs its own shared primitive. |
| 6.2 | Behavior phase 5 -> phase 6 -> phase 7 | Follow the feature dependency order: social behavior, ecological routines, memory/continuity. Stage 4 may pull forward only the routines required for N3/N4. Reconcile actual mechanics before extending them. |
| 6.3 | [Vessel follow-up stages 1-4](world-exploration-roadmap.md#vegetation-and-vessel-response-follow-up): plants, signal, swarm and three classes | Retain the existing pilot. Close normal-input review, supply allocation, balance and fuller species/class authoring rather than rebuilding it. |
| 6.4 | V3 -> V4, Vessel stages 5 -> 6 -> 7, development D6 | After conserved circulation: persistent-alarm settling, bounded escalation/detection, environmental storm admission/lifecycle, then connected danger/recovery review. Battle storms remain separate. Full environmental storm delivery is not an N6 dependency. |

## 7. Add optional relic discoveries, then powered operations

| Order | Work and owning steps | Dependency / exit |
| --- | --- | --- |
| 7.1 | [Relic R0 -> R1](relic-roadmap.md#delivery-sequence): author one discovery, finish definitions/review fixture | Existing lab geometry is partial R1. R0's purpose, motif, clue, real reaction and useful outcome precede production admission. Authoring can overlap earlier stages without blocking nature. |
| 7.2 | R2 -> R3: deterministic sparse placement and resonator exploration loop | Requires stable geographic access and N2 durable findings. Verify either approach, leave/return, quiet evidence and save/load. |
| 7.3 | R4 -> R5 -> R6: real conduit/reservoir, authored local operation, review/expansion | Requires real source budgets and conserved transactions. Spend only for an authored operation; review the connected slice before increasing density. Powered relics are optional to nature acceptance. |

## 8. Introduce NPC direction and services

After owner N6 acceptance, advance N7/W5 request content and
[UI phase 5](ui-ux-roadmap.md#implementation-sequence) together. Author NPCs,
dialogue, requests and services through the accepted target/action and persistence
owners. Requests enrich useful exploration; reporting never secures previously
earned knowledge. Campaign onboarding remains a later, separate delivery.

## 9. Expand terrain, combat, progression and content

| Order | Work and owning steps | Dependency / exit |
| --- | --- | --- |
| 9.1 | Terrain remaining T2-T4/T4a -> T5; world W1 -> W2 -> W3 -> W4 -> W5 -> W6 | Close outstanding border/grounding, route grading, shoreline, palette, cost and connected reviews before broad rollout. Reuse completed slices; do not restart historical research W0. Actual device portions of T5 stay at stage 12. |
| 9.2 | Terrain T6: connected drainage and regional geography | After accepted local terrain/access contracts. Extend existing mountain/water foundations into downhill rivers and broader drainage; erosion remains a later experiment under T6. |
| 9.3 | Combat earlier phases 1-2 retained; phase 3 pacing -> phase 4 counterplay -> phase 5 expansion; C6 team expansion | Reapply readable sequencing/consequence lessons to accepted readiness combat. Author unit-ID/team ownership before 2v2 and validate group readability. Do not restore superseded End turn timing. |
| 9.4 | Development D1-D5 remaining contracts, peaceful relationships, learning and authored evolution | Foundations/capture/training already exist. Close actual missing requirements with accepted rules/content; do not invent trust rewards, evolution thresholds or old-save migration requirements. Complete these before affected D7 content. |

## 10. Complete optional visual studies

After the required presentation is accepted, finish
[mist interaction phases 1 -> 2 -> 3 -> 4 -> 5](vastra-visual-roadmap.md#planned-character-interaction-mist-flow--october-29-2026):
review the isolated study, implement stateful interaction, unify consumers,
prove expedition integration, then tune/adopt. Preserve the later direction that
normal gameplay remains lab-free; the historical development-switch instruction
does not authorize restoring it.

Finish discovery convergence against actual discovery owners and review daylight,
night, accessibility and instability/core cues against the approved design.
The visual roadmap's historical prototype steps 1-6 are superseded by its current
world foundation; do not restore the rejected player-radius manifestation or
rejected ribbon/surface design to check off old rows.

## 11. Deliver authored campaign and Region One

When campaign work resumes, follow the
[approved opening sequence](development-plan.md#approved-opening-delivery-sequence--october-28-2026)
and remaining D7 content dependencies: author rescue/failure prompts and the
actual trio, preserve identity through starter transfer, connect companionship,
then develop settlements, roster/evolution content, major story consequences and
the ending. Author irreversible refusal consequences before implementation.
Production species art and expanded roster admission remain bounded content
deliveries, not hidden prerequisites for the current alpha.

## 12. Qualify the exported release and target device

Complete development D8, UI phase 7, deferred reformat/terrain device acceptance
and remaining physical-controller/Thor review against the actual exported build.
Measure sustained travel, dense scenes, saves, combat and ecology; complete
onboarding/accessibility, asset availability/redistribution, reproducibility,
known-defect disposition and release review. Editor and development-PC results
do not substitute for these acceptance gates.

## Conditional concurrency track

After stage 2's MT0 -> MT1, enter MT2 only for a remaining measured workload that
justifies workers. Follow MT2 coordinator -> MT3 generation proof -> MT4 scenery
preparation/publication -> MT5 startup/save/load/transitions -> MT6 selected
game-system workloads -> MT7 integrated qualification/default enablement -> MT8
contribution contract. Startup and publication limits begin in MT1, not MT5.

Run this track before expanding content if measured stalls impede that expansion;
otherwise keep it separate from feature acceptance. Every admitted workload must
retain deterministic results, single-writer transactions, stale-result rejection,
bounded queues and safe cancellation. MT6 is selective, not a mandate to thread
all domains. MT8 workflow changes must update PROJECT_STANDARD.md on adoption;
this proposed track does not itself change contribution policy.

## Roadmap coverage index

| Owning plan | Placement in this master |
| --- | --- |
| [World/exploration](world-exploration-roadmap.md) | Stages 1-4: playtest stages 1-6 and N0-N6; stages 6/8/9: Vessel follow-up, N7 and W0-W6; living-world steps 0-7 feed the same authoring, baseline, Vastra, weather, habitat, event and review work rather than a second implementation queue |
| [Reformat R0-R8](reformat-roadmap.md) | Stage 0 retained completion; owner review in stages 1/4, deferred device acceptance in stage 12 |
| [Terrain T0-T6/T4a](terrain-roadmap.md) | Stages 2/4 for immediate blockers; stage 9 for remaining expansion; stage 12 device acceptance |
| [Sol behavior 1-7](sol-behavior-roadmap.md) | Stage 4 bounded cooperation; stage 6 broader behavior |
| [Combat phases 1-5 and C0-C6](combat-roadmap.md) | Stage 4 readiness C0-C5; stage 9 pacing/counterplay/teams; isolated real-time trial retained as evidence |
| [UI/UX phases 0-7](ui-ux-roadmap.md) | Stage 5 plus each feature's interaction work; stage 8 NPC UI; stages 11-12 onboarding/export |
| [Vastra visuals](vastra-visual-roadmap.md) | Stages 3-4 required readability; stage 6 instability consumers; stage 10 optional studies and art closure |
| [Weather WX0-WX5](weather-roadmap.md) | Stage 3, without imposing full weather on N6 |
| [Relics R0-R6](relic-roadmap.md) | Stage 7, optional early authoring overlap |
| [Concurrency MT0-MT8](runtime-concurrency-roadmap.md) | Stage 2 baseline/serial fixes; conditional track thereafter |
| [Development plan D0-D8](development-plan.md) | D0 review stages 1/4; D1-D5 foundations/gaps stages 0/3/4/9; D6 stage 6; D7 stage 11; D8 stage 12. New N-gates supersede conflicting historical priorities. |
| [Lab plugin L0-L5](development-workstation.md) | Stage 0 engineering retained; owner usability review and affected tooling fixes alongside feature work |
| [Vastra integration V1-V5](vastra-integration.md) | V1/V2 stages 3-4; V3/V4 stage 6; V5 with combat C4/C5 in stage 4 |

The former root `ROADMAP.md` is absent. Do not recreate its historical repository
management milestones as game completion claims. The dated
[maintenance snapshot](maintenance-status.md) remains historical evidence;
repository protections, PR status and releases require current verification
through the project standard when relevant, outside this feature sequence.
