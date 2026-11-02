# World and exploration delivery roadmap

For the order of work across all feature plans, start with the
[master delivery roadmap](master-roadmap.md). This roadmap retains the N0-N7
acceptance gates, world-specific sequences and alpha intake evidence. Newer dated
implementation receipts take precedence over older status summaries; the master
does not turn an implemented prototype into accepted gameplay.

## Playtest resolution sequence — October 31, 2026

Owner supplied a staged proposal; require a focused playtest between stages.
Existing generation, persistence, Bible and mechanics-reference owners remain
authoritative. The sequence and acceptance gates are:

1. Inspect requests/repeats/preparation, then bound active streaming, residence and
   frame work. Queue drains at rest; travel is bounded; returns preserve contents.
   Separate terrain/tree/grass visibility and coordinate fog with transitions.
2. Shorter grass visibility with simpler distant ground coverage blended into
   terrain; grass coexists with plants outside actual trunk/solid-root footprints.
   Configurable short/medium/tall ranges vary smoothly between patches. No obvious
   disappearing ring; camera/blade count never changes canonical grass supply.
3. Stored Vastra drives leaf saturation and downward droop, preserving species
   colors and adding wind over posture. Known low/medium/full reserves visibly
   differ; depletion does not automatically imply permanent damage.
4. Connect grass emanation → shared currents → reservoirs/plant recipients → root
   circulation, repair and Sol feeding. Splits divide and merges combine energy;
   tree recipient selection stays unbiased. Stagger emissions and traveling
   fluctuations across connected paths. Preserve stream appearance with soft
   intersections and tapered ends; real transfers visibly reach destinations.
   The proposal recommends rings as principal visible tree intake, roots for soil
   and anatomical endpoints elsewhere. Organ reserves remain a later extension.
5. Gently tune stored-Vastra decay plus additional local ecological-overload loss,
   with explicit energy accounting. Full storage safely redirects overflow. The
   proposed first pass removes degraded energy from usable reserves without
   crediting a recipient; recycling remains separate. Normal grass supply sustains
   healthy forests; overload predictably increases losses.
6. Persist distant-tree identity, shape, growth and meaningful foliage condition.
   Keep reusable multi-angle billboard images in a separate identity/appearance
   cache; refresh after meaningful changes, not wind/tiny reserve fluctuations.
   Recognizable silhouettes/condition survive approach, departure and save/load.

Stage 1 in this working change adds a hard request radius, resident detail ceiling,
departure buffer and F3 preparation/job diagnostics. The ceiling counts active,
cached, retiring and preparing detailed chunks. Temporary ground retains its
separate bounded cache. Streaming never owns/evicts saved plant reserves.
Owner's live playtest reports notably better performance with these streaming
bounds; retain those defaults. The visibility follow-up separates tree, grass
and detail categories supplied by admitted render records, updates active and
cached meshes on reapply, and completes fog before the shorter tree/terrain
horizon. Grass retains a separate local fade; simpler distant coverage belongs
to stage 2. The visibility changes and stages 2–6 retain their focused gates.

Pre-limit production-scene stationary evidence: 96 queued chunks drained through
96 started/completed jobs, zero cancellations and 5,640 preparation frames in
25,534 ms (headless workstation CPU run). This identifies unfinished preparation
for that fixture; it does not establish real rendering performance or explain
every playtest pose. Focused regression: `tests/streaming_bounds.gd`.

Post-change headless checks: streaming bounds 6,286 checks, 3D view 6,790,
fog horizon 271 and terrain/save reuse 26; all passed. Streaming checks include
idle cessation, rapid positive/negative travel, exact home-cell reconstruction,
persistent-state invariance and lowering the resident cap during an expedition.
Check counts vary with preparation slices. Visibility follow-up playtest:
use F3 to observe queue drain at rest, travel across chunk boundaries, then return
and inspect contents/coverage. These CPU checks do not establish visual acceptance.

Visibility follow-up validation: `tests/view_3d.gd` passed 21,140 checks,
`tests/fog_horizon.gd` passed 271 and `tests/plant_live_integration.gd` passed
814. Tests exercise independent ranges, cached reapplication, a shorter tree
fog horizon, real render categories and unchanged stored state. The rendered
view journey also passed; inspected `artifacts/view3d/wide.png`. Its low-angle
capture is obscured by nearby foliage and does not prove low-angle transition
acceptance. A normal Direct3D 12 game launch exited cleanly without logged errors.
Normal editor import exposed a missing explicit boolean type in
`tools/lab_review_tools.gd`; that parse error is fixed. Import still exits 1
without further logged script/engine errors, so full editor-import acceptance
remained open at that checkpoint. Owner subsequently requested stage 2 below;
visual transition tuning remains subject to focused playtesting.

## Alpha integration register — October 31, 2026

Step 2 follow-up: shorter leaf-grass visibility (28 cells, 12-cell per-clump
fade), terrain-colored distant coverage, shared-cell grass around larger bodies
and configurable short/medium/tall height ranges are implemented for playtest.
Primary plant anatomy/endpoints remain authoritative; visible clumps never
change canonical membership or supply. Shared fade materials avoid per-instance
shader-buffer allocations, and grass casts no individual shadows. Focused
evidence: plant integration 922, foliage rollout 9,850, bounded streaming 10,124
and 3D view 23,588 checks, all zero assertion failures. Counts vary with streaming
slices. The Direct3D 12 close/medium/wide rendered journey passed with bounded
residence and no logged engine/shader errors after replacing the initial
per-instance material approach. Captures/logs: `artifacts/grass-step2/`.
See [the visual contract](reviewed-world-visuals.md#step-2-grass-distance-stature-and-coexistence--october-31-2026)
and [tuning controls](inspector-tuning.md). Owner subsequently requested stage 3;
interactive transition/coexistence acceptance remains open. CPU validation does not establish
an FPS improvement or handheld acceptance.

Stage 3 is implemented for playtest: stored reserves now produce stronger
reversible saturation and downward leaf-tip posture, with full reserves keeping
authored appearance. Shared-clock traveling gusts vary the wind response across
the forest. Owner also requested render-wide Vastra visibility: source coverage
follows rendered terrain, visual budgets distribute among visible regions, and
filament culling follows actual paths. Ecological activation and conserved supply
remain independent of camera. Focused rendered comparisons, 46 nature contracts,
182 current checks, 922 plant integration checks, 153-definition bake and normal
editor import passed. [The Vastra contract](vastra-integration.md#render-wide-visibility-and-reserve-posture--october-31-2026)
records the scope and evidence. Owner subsequently requested stage 4 below.

Stage 4's first circulation refinement is implemented for focused playtest;
the owner reports that the forest still does not feel sufficiently alive.
This is not completion of the full shared-circulation design. Actual packets converge onto seeded
shared corridors and branch toward their existing recipients; derived junction
totals count each packet once. Tree intake prefers the integrated reservoir ring;
soil/root exchanges keep root endpoints and authored internal circulation.
New expeditions use four geographic emission slots (0.75 seconds each); charged
plants retain their energy while waiting, and bounded service cannot starve a
source by repeatedly missing its slot. Existing saved policies retain their timing.
Filaments gain rounded confluences, path-length-correct strips, endpoint taper,
soft depth intersections and source-phased traveling fluctuations. Storage,
unbiased tree selection, root allocation, repair and Sol feeding retain their
conserved owners. Organ reserves and decay remain later stages. Evidence and
apply scope: [circulation refinement](vastra-integration.md#connected-circulation-refinement--october-31-2026).

Owner-approved follow-up: plants communicate conditions/needs/warnings through
small paid pulses before a full reserve; trees retain working reserves and send
smaller releases under a base tree capacity of 500 Vastra increasing with tree
size (owner correction superseding the fixed 100 tree cap); known distant forests continue
through slower regional updates during active play. Pause/offline rules remain.
These are design decisions awaiting implementation, not behavior already added
by stage 4. Fix invisible transfer admission and geographic visual starvation,
then deliver retained reserves, the packet vocabulary/paid transport, and shared
near/distant service with exact accounting and save/load. Acceptance requires
observing healthy exchange, disturbance, response, settling and an evolved patch
after departure/return. The [assessment](living-world-concept-report.md#15-plant-packet-language-assessment--october-31-2026)
owns the proposed details; the Bible records the approved behavior.

Fruit follow-up: owner selected feeding Sols and supporting local regeneration
for the first fruit slice. Growth, flowering, death and replacement remain to be
authored and implemented; hunter collection is outside this slice. The concept
report retains the proposed minimal lifecycle and accounting questions. This
does not close circulation, plant-language or distant-service acceptance.

Owner clarification: trees produce fruit; Vessel activity causes flowers to grow
on other plants. Vessels consume Vastra from plant resources. Preserve existing
transfer accounting while adding Vessel-induced flowering and lifecycle support;
do not require flower feeding ports or introduce nectar/pollen or blossom
consumption as the selected diet. Each fruit produced costs Vastra, and
each Vessel's feeding draws its own accounted amount; costs accumulate with
actual crop production and consumption. Fruit remains for Sols and regeneration.
Owner subsequently specified that Vessels pollinate fruiting sections on trees;
a real visit to a ready section suffices, without cross-tree pollen tracking.
Plant mortality includes old age and sustained damage, with long tree lifespans.
The concept report proposes the bounded crop, survival and replacement lifecycle.
Flowering, pollination, fruit costs and plant aging/death await implementation;
exact lifecycle balance and regeneration rules still need authoring/playtest.

Owner prioritized a narrow pacing/animation slice before further lifecycle work:
reduce tile-fed grass output to one quarter, release and receive energy gradually
at actual outlet/intake, retain a visible final approach, and use cubic vector
stream paths. Production now selects 1 unit/second refill and 8 units/second
release; current expeditions adopt pacing on load/reapply, with existing flights
retaining saved durations. Partial credit, source-held stock and mid-stream save
validation remain conserved. The [paced-flow contract](vastra-integration.md#slower-source-output-and-paced-intakeoutlet--october-31-2026)
owns implementation scope/evidence. This does not close the larger lifecycle,
capacity-growth or distant-activity work above.

The nature-only N0-N6 sequence is the internal desktop alpha target. It builds
on the current game and ongoing work; it is not a restart or a claim that alpha
is ready. N7/NPC content, campaign and handheld/export release acceptance remain
later gates. This register owns cross-feature intake; feature documents retain
implementation evidence. Status is a dated snapshot, not an instruction to stop
or reassign another active chat.

| Workstream | Existing/ongoing work to retain | Alpha integration and remaining gate |
| --- | --- | --- |
| Game structure and persistence | Completed reformat evidence at runtime 2f13c5a, stable identities, central transactions and saved generation settings | Reuse owners/UIDs and validated contracts; later working changes need their own evidence, not another architecture rewrite |
| Terrain, navigation and habitats | Height-aware walking, camera/picking, geographic parents, water/ridge foundations and production community settings | Select N0 from actual reachable geography; keep essential paths, large-Sol clearance and meaningful return; no full watershed prerequisite |
| Plant Maker and live flora | Approved 45 visual baselines; local rollout reports 41 ecologically eligible official designs and 109 baked definitions; four unassigned Receiver studies excluded | Preserve canonical admission, role/reserve ownership, species envelopes and selected library priority; N1 adds reserve saturation/posture without republishing all designs |
| Plant anatomy and Vastra routes | Accepted leaf surfaces, destination-facing roots, underground soil fitting and terrain-following external transfers | Reuse live transformed organ graphs in N1/N4; verify real endpoints and conservation instead of replacing them with tile-center cosmetic strands |
| Vastra ecology and visuals | Existing saved reserves, packets, repair, root surplus, Sol feeding and Vessel pilot | Extend via V1-V5 for finite-speed ambient overflow and persistent-alarm settling; baseline circulation is not the new signal-overload implementation |
| Runtime and loading | Local bake/material compaction, wetland caching, bounded chunk work, terrain reuse and player/occlusion fixes | Carry relevant fixes into the alpha snapshot; fingerprint bake inputs; recheck changed consumers and exact admission equivalence; CPU samples are not whole-game FPS guarantees |
| Sol authoring and active art work | Sol Lab authoring, inherited bodies, independent affinity and core placement; active core/body and low-poly lineage study | Treat designs as drafts until approved/admitted; select existing suitable species for two field interactions; do not make a new roster or three-stage evolution implementation an alpha dependency |
| Wild/owned behavior | Shared behavior hierarchy, grounded following, flight/swimming where admitted, observation and notable identity | N3/N4 add actual field outcomes and peaceful choices through existing owners; idle animation alone does not satisfy cooperation |
| Combat and progression | Playable AP turns, damage/moves, finite uses, capture, training, imprints and once-only outcomes; isolated real-time trial | Preserve the working loop until C0-C5 pass; reuse trial movement/windup lessons, not its synthetic damage/cooldown rules; no reset of learned individuals or growth |
| UI, controls and journal | Context actions, clickable personal menus, field notes, party/loadout UI and controller foundation | Extend existing surfaces for plans, findings, rest and exposure; retain cancel/inspection guards; durable findings cannot be evicted by recent-sighting limits |
| Weather, audio and day/night | Saved atmosphere/clock and audio routing; WX0-WX5 roadmap remains planned in inspected evidence | Reuse available atmosphere/audio now; connect shared wind incrementally; authored revisits cannot assume an undelivered weather simulation or Sol schedule |
| Relics | Shared procedural black-stone lab, crevice routes and finite synthetic intake/output examples | Optional R0-R3 discovery parallel to nature work; R4/R5 need real source budgets and persistence; no requirement to finish powered machinery for N6 |
| Rest, risk and recovery | Existing refuge recovery plus approved NPC-independent shelter, exposure, reserve buffer and emergency recall direction | Extend actual state transactions; safe rest and remote defeat handling must be usable without NPC services; costs/thresholds need authoring |

Evidence entry points: [reformat](reformat-roadmap.md),
[terrain](terrain-roadmap.md), [plants](procedural-plants.md),
[Vastra](vastra-integration.md), [runtime](runtime-optimization.md),
[Sol Lab](sol-lab.md), [Sol Bible](reference/sol_bible.md),
[behavior](sol-behavior-roadmap.md), [combat](combat-roadmap.md),
[UI](ui-ux-roadmap.md), [journal](sol-observation-journal.md),
[weather](weather-roadmap.md), [audio](audio-framework.md), and
[relics](relic-roadmap.md). Some October 30-31 implementation reports and resources
are still uncommitted locally; their presence is not proof of remote availability
or a clean combined build. Integrate their reviewed commits/resources before
using them as an alpha dependency; do not copy unrelated dirty files into this
roadmap commit.

### Intake order and evidence reuse

1. Inventory current files/branches and actual active work. Preserve user changes;
   reconcile independent patches through their owners. Pin one combined runtime
   revision and matching settings, schemas, catalogs, bake manifest and asset set.
2. Carry existing runtime, flora/organ-route and traversal fixes forward. Run their
   relevant checks when inputs changed; reuse earlier evidence only for unchanged
   contracts. Do not rerun the entire historic suite after every prose/art edit.
3. Advance N0-N4 on that baseline while C0-C3 and WX work can progress independently.
   Art authoring and relic studies remain parallel; no implied admission of drafts.
4. Integrate C4-C5 and supported recovery, then perform N5/N6 on the combined game.
   Shared clock, flora/packet, save, journal and outcome changes require cross-system
   validation before calling the alpha gate passed.
5. Record remaining defects, owner play feedback and provenance. Carry unfinished
   optional studies forward without hiding them or making them silent blockers.

### Known unresolved combined-build evidence

October 31 implementation closeout: the five authorized alpha steps are ready for
owner playtest on Godot 4.7.2 stable. The current normal-input outing completes
findings, readiness capture, return and save/load. The canonical remainder's two
fixture failures have clean focused rechecks; current import and palette bake pass.
The strict combined gate remains red because recovery intermittently exits with a
native access violation after all 54 assertions pass. The owner accepts separating
this observed shutdown issue from implementation completion; it remains an open
defect, without suppressing exit/error checks. Preview-engine evaluation is stopped.
See [the alpha closeout](readiness-alpha-contract.md#alpha-implementation-closeout--october-31-2026)
for current receipts. Owner experience acceptance, remaining visual studies and
public-release readiness remain separate. The paragraphs below retain earlier
audit history rather than certifying the current candidate.

Current biome follow-up implements conserved ambient overflow with the owner's
adjustable 1:1 conversion. All six representative generation-16 areas now emit and
receive transfers with valid saved accounting; pond/shore body replacement remains
deferred. State version is 22. The current normal-input D3D12 route records three
findings, real readiness capture and return/save/load with zero failures. Detailed
scope and logs are in [the alpha contract](readiness-alpha-contract.md#biome-follow-up-and-current-validation).
This supersedes zero water/shore simulation flow, not the open V2-V5 signal/storm
work or the combined validation gate. The frozen pre-overflow broad audit finished
with failed/interrupted checks; stale copied bake inputs and native cleanup issues
prevent a green combined-build claim. Focused rechecks are separately attributed.

The earlier continuation-remaining-3.log recorded 11 failures in 26 encounter
assertions. October 31 diagnosis found both obsolete tile-boundary/tween fixture
assumptions and a real continuous-movement contact guard bug. The fixture now uses
physical fractional travel with float32 tolerance; already validated automatic
contact can stop movement while manual approach still requires stopping. All 26
assertions were retained and two guard checks added: the focused run passes 28/28
in artifacts/nature_alpha/encounter-entry.log. This does not replace the combined
validator. The plant report also retains an earlier biome run with 13 failures.
The October 31 recheck reproduced them: twelve looked for retired `grass_*` meshes
instead of the production `ground` mesh, and one omitted production foliage
coverage when reconstructing an admitted body. Binding those same assertions to
the current owners/settings passes 7,098 checks (`biome-contract-recheck.log`);
the positive shared-vertex and endpoint-priority requirements remain intact.
This focused result is not full integration acceptance. Existing shutdown warnings remain
visible in evidence. The older clean reformat run does not certify these inputs.

Alpha acceptance requires the configured validation appropriate to the combined
runtime, import/ownership checks, and normal-input nature journeys with save/load,
withdrawal, defeat/recovery and revisit evidence. Preserve configured CI. Owner
play review must confirm useful choices and a next goal, not just automated wins.
For an internal local alpha, record required local assets; before distributing a
build/clean-clone package, resolve availability and redistribution rights. Do not
silently upload withheld assets. Thor acceptance and public-release readiness
remain separate from this desktop nature gate.

### Ongoing-chat reconciliation snapshot

Repository evidence was paired with a read-only chat inventory. **Clarify Sol
design vision** was active on a wooden three-stage core/body study at inspection;
this is ongoing art exploration, not an approved new playable lineage. **Discuss
wind system implementation** reported roadmap delivery only, not runtime wind.
Other plant, Vastra, optimization and relic chats were identified, but their
status/title alone is not proof of current implementation or acceptance; use the
linked feature evidence and refreshed snapshots when those changes are integrated.
No other chat was instructed, interrupted or reassigned by this audit. Do not treat
work from other repository directories as already integrated in this Godot tree.

## Current delivery gate: nature-only expedition — October 31, 2026

Owner approved the detailed nature-only loop and requested roadmap reconciliation.
This section supersedes earlier delivery priorities below. NPCs, requests, shops,
dialogue, campaign onboarding and NPC-dependent services move to the next phase,
after nature sustains enjoyable play. Their existing story canon is preserved.
Existing NPC content need not be deleted; acceptance cannot depend on it.
The October 29 road/atmosphere work remains useful foundation and dated evidence,
not the current stopping point. Natural leads and interactions are now in scope;
the hold on broad downloaded landmark-asset placement remains.

The loop is: notice -> investigate -> understand -> choose an approach -> gain
knowledge or develop a companion -> recover/prepare -> pursue a new opportunity.
World clues and retained journal leads drive it. Some opportunities combine
knowledge, gear protection and companion capabilities with alternate approaches.
No quest-giver, reporting requirement or loot award is needed to secure knowledge.
Design authority: [Bible](reference/SolHunter_Worldbuilding_Bible.md), especially
its October 31 nature-only expedition specification. This roadmap owns sequencing;
feature documents below own mechanics, implementation evidence and acceptance.

### Evidence classification

- Existing baseline: connected traversal, observation, owned following, encounters,
  AP turns, capture/progression, refuge recovery and saved outcomes. Historical
  checks validate their recorded revisions, not the new experience.
- Approved but not delivered by this edit: durable learned findings, field
  cooperation, natural situations, safe rest, readiness plans, battle storms,
  exposure/recovery, revised foliage/flow presentation and powered relic discovery.
- Deferred: NPC phase, full campaign, broad roster expansion, bosses as mandatory
  loop closure, optional powered relic rollout and detonation implementation until
  its prevention/consequence specification is complete. Possible 2v2 is a later
  combat extension, not a prerequisite for 1v1 nature acceptance.

### Nature delivery sequence

All gates below are planned; documentation approval does not mark them complete.

| Gate | Deliverable | Dependency | Acceptance |
| --- | --- | --- | --- |
| N0 | Select one compact existing natural area and author its situations | Current normal-game baseline | Rest place, circulation grove, sheltered habitat and disturbed crossing fit accessible geography; record baseline and real source/participant IDs |
| N1 | Readable reserves, circulation and disturbance evidence | N0 and Vastra ownership | Healthy rich, depleted and alarmed states are distinguishable; flows reflect real accounting; camera/render density cannot create energy |
| N2 | Durable journal findings and natural leads | N0, existing Field Notes | Observation-led findings survive defeat, repeat visits and save/load; recent sightings cannot evict learned knowledge; no reporting gate |
| N3 | Safe recovery and two bounded companion interactions | N0, existing party/follower/state contracts | Ordinary HP/exhaustion recovery, legal party/loadout changes and return preparation work without an NPC; two relevant cooperative actions preserve identity and offer readable outcomes |
| N4 | Three worthwhile natural discoveries and peaceful choices | N1-N3, behavior hierarchy | Circulation grove, sheltered habitat and disturbed crossing offer different choices/payoffs; at least one productive outing requires no battle |
| N5 | Readiness combat and battle-storm expedition integration | N1-N3 and combat gates C0-C5 | Shared-AP plans, committed aim, exposure, withdrawal, reserve buffer, capture dispersal and supported recovery work in the same expedition |
| N6 | Replay the complete nature loop and select the weakest part | N4-N5 | Observation, companionship, combat and preparation outings each produce a finding, consequence or changed plan and an identifiable next goal |
| N7 | Introduce NPC direction/services only after review | Owner nature-only acceptance | Optional requests enrich an already useful loop; reporting never becomes necessary to retain discovery |

N1-N4 can advance while the combat scheduler is prototyped; no requirement to finish
all world simulation before trying a natural interaction. Relic discovery may be
reviewed in parallel under its roadmap, but powered relics are not a blocker for
N6. Keep the current game playable until replacement systems pass their gates.

### N0/N4 situation sheets and concrete first area

N0 implementation intake started October 31: the [first-area sheet](nature-alpha-area.md)
records reproducible generation-15 grove/bank candidates, footprint-specific return
paths and explicit unverified situation fields. This starts N0; it does not close it.

Author four reusable situation families: living routines, circulation patterns,
local disturbances and unusual opportunities. For each record actual causes,
visible evidence, stable place/participant references, optional approaches,
interruption/leaving behavior, recurrence, payoff, persistence and return reason.
Separate observed fact from interpretation; no generic investigation meter.
Low plant reserve alone never proves damage, starvation or ecological overload.

The circulation grove teaches normal saturation/posture, conserved transfers and
safe overflow; it need not contain a repair quest. The sheltered habitat supports
watching, respectful approach, companion approach, backing off and leaving. The
disturbed crossing tests warning recognition, preparation, terrain, battle or
withdrawal. A safe resting place connects them through an accessible return.
Existing terrain and actual local state determine fit; omit unsupported situations
rather than fabricate creatures, broken connections or obligatory rewards.

Each situation must answer: what can the player now decide or attempt more
confidently? Payoffs can be practical knowledge, existing companion progression,
a cooperative encounter or access through a known approach. Not every discovery
must grant all of them. A journal paragraph alone is insufficient when it changes
no decision. Victory need not unlock a route or automatically award a discovery.

### Return, revisits and acceptance evidence

Recognizable shelter supports ordinary recovery, legal preparation and saving.
Severe exposure, exceptional injuries and blackout require separately specified
rules; rest is not an assumed cure-all. NPC rescue near settlements belongs to
the later phase; the nature-only sample needs a supported prepared extraction or
authored remote recovery, including emergency companion recall, before defeat is
accepted. Exact costs/penalties remain open rather than invented.

Revisit reasons include time/weather-supported activity, recovery, a different
companion, learned signs and persistent battle imprints. Author only supported
responses; ordinary weather does not generate overload or automatically alter
encounter admission. Avoid empty waits for a narrow event window and reward resets.
Some places may be complete in one satisfying visit.

Record one familiar-seed journey first, then representative different/awkward
geography when admission expands. Cover no-battle observation, peaceful contact,
combat, deliberate withdrawal, defeat/recovery, save/load, a meaningful revisit
and a preparation-led second outing. Track what attracted attention, what was
understood, chosen approach, payoff and next goal; retain normal-camera evidence
and actual owner feedback. An automated journey or test count alone proves no fun.

### Cross-feature ownership and open gates

| Responsibility | Owning document |
| --- | --- |
| Terrain fit, navigation and stable places | [Terrain roadmap](terrain-roadmap.md) |
| Living routines, peaceful contact and cooperation | [Sol behavior](sol-behavior-roadmap.md), [owned companion](owned-companion.md) |
| Learned evidence and durable leads | [Observation/journal](sol-observation-journal.md) |
| Conservation, alarms and recovery | [Vastra integration](vastra-integration.md) |
| Saturation, posture, core/strand instability | [Vastra visuals](vastra-visual-roadmap.md), [procedural plants](procedural-plants.md) |
| Timeline, AP plans, storm lifecycle and defeat | [Combat roadmap](combat-roadmap.md) |
| Natural-weather presentation | [Weather roadmap](weather-roadmap.md) |
| Plans, inspection, warnings and journal access | [UI/UX roadmap](ui-ux-roadmap.md) |
| Optional relic discovery and real powered connections | [Relic roadmap](relic-roadmap.md) |

Resolve only when blocking: safe-rest duration/limits; specific species field
assignments and costs; situation rewards/recurrence; archival discovery schema;
AP timing and invalid-plan behavior; exposure thresholds; remote recovery details;
finite-speed overflow routing/backlog; and powered relic source budgets. Consult
source evidence before requesting new rules. Do not reopen already approved roles,
storm origin, recall direction or journal retention on defeat as unanswered.

October 30 generation follow-up: owner selected connected water, added mountain
ranges and approved WorldGen's layout-first principle. Generation 13 now has
optional pond/channel/satellite-pool connections and cross-district ridgelines;
the grass defaults are 40% shorter and 15% narrower. See
[terrain delivery/evidence](natural-terrain.md#connected-water-and-mountain-ranges--october-30-2026).
These level-channel and mountain foundations do not close downhill rivers,
regional watershed connectivity, authored passes or normal-play acceptance.

Relic planning follow-up, October 30: the owner requested a shared relic system,
Vastra reactions and gameplay-focused planning. The [relic delivery
plan](relic-roadmap.md) owns the proposed resonator discovery, later conserved
connections and local operation choices. Broad purpose/source families are now
approved in the October 31 Bible; specific operations, costs and runtime
integration remain open. It does not change current cross-feature priority or
lift the downloaded landmark-asset hold.

Plant-community follow-up, October 30: the owner authorized starting the Deussen
ecosystem-inspired plan. The first isolated Development Lab comparison is
implemented; generation 15 now connects its tree layout to production geography,
protected access and local drainage, with captured community settings in save
format 5. Production generic foliage consumes the same environmental context.
The experiment, limitations
and subsequent sequence are recorded in
[procedural plants](procedural-plants.md#plant-communities-experiment--october-30-2026).
Production integration evidence is recorded in the same document. Rendered
meadow/woodland review and normal-play acceptance remain separate from layout
and save admission checks. This establishes no new live ecological mechanics.

## Required vegetation integration — October 29, 2026

Every generated living plant must be linked to the Vastra hierarchy. Treat missing membership as an integration defect: circulation, root recipients, repair and vegetation/Vessel behavior depend on it. Acceptance includes all biome palettes, arbitrary asset names, existing water/bank plants, camera-independent catalogue admission and save/load. Visual clump count cannot multiply reserves.
See the [authoritative registration contract](vastra-integration.md#generated-vegetation-registration-and-system-hierarchy) for owners, limits and checks.

October 29, 2026. Current forward delivery sequence following the completed desktop
reformat. Owner-directed priorities; phase scope and review workloads below are
engineering proposals. Creating this roadmap implements no gameplay feature.

Latest design: [vegetation and Vessel response follow-up](#vegetation-and-vessel-response-follow-up)
supersedes earlier cue-only Vessel scope; runtime delivery remains open.

## Direction and authority

### Owner focus: living environments — October 29, 2026

Following the vision review, the owner prioritizes Vastra, world generation and
biome-specific systems for today's work. Roads and wilderness should feel active
even when no Sol is present. More creatures or static props alone do not meet
that goal. Downloaded landmark asset placement remains held. Natural leads now
advance through N2/N4, superseding their earlier deferral. Existing combat,
collection and persistence remain connected.

Proposed first review slice: one ordinary road crossing two existing habitats,
with recognizable geography, habitat-specific environmental activity and coherent
Vastra presentation. Reuse shared weather, audio and scenery owners. Review both
walking and standing still, including a view without nearby Sols. Judge whether
the surroundings visibly change or act, whether the habitats feel different, and
whether a natural detail invites attention without a quest marker. Avoid filling
every stretch with effects; quiet areas are part of the composition.

Delivery order within this focus is an engineering proposal: review the current
Vastra look; strengthen geographic/biome character; connect a bounded environmental
activity treatment through existing weather/audio owners; then review the combined
road. Feature roadmaps retain implementation details and evidence. New ecological
effects, ambient events or human activity require their own reconciled specification;
this focus does not approve a full simulation, NPC schedule system or new rewards.

Make the world worth playing before introducing the authored campaign. Early
players choose their direction through exploration, Sol encounters and natural
interactions. Generated NPC requests follow nature-only acceptance. Give that
experience a First Age feeling: discovery, incomplete knowledge and experiences
that could later inform the world's stories. This is an atmosphere and
development direction, not a decision that early saves become permanent canon or
that players share a historical online world.

Authored campaign delivery, including the storm-rescue opening, is deferred.
Natural interactions are in scope now. Generated NPC requests follow N6
acceptance and can support later story connections. AYN Thor optimization, export and device acceptance are far deferred;
ordinary desktop playability still matters. Preserve existing combat, collection,
companions and approved story designs while prioritizing world work.

This document owns the forward cross-feature sequence. The
[development plan](development-plan.md) retains broader design context;
[terrain](terrain-roadmap.md), [Sol behavior](sol-behavior-roadmap.md),
[combat](combat-roadmap.md) and [UI/UX](ui-ux-roadmap.md) retain their detailed
requirements and evidence. Do not duplicate their checklists here.
The [weather and wind roadmap](weather-roadmap.md) owns the approved shared-weather
structure and its phased presentation work, supporting W1/W3 exploration feel.
Its implementation remains planned; it introduces no weather-driven Sol rules.
[PROJECT_STANDARD.md](PROJECT_STANDARD.md) remains the workflow authority;
the [Bible](reference/SolHunter_Worldbuilding_Bible.md) governs canon. Godot remains
the generation authority. Before defining non-generation mechanics, inspect
SolHunterSource under [mechanics-reference.md](mechanics-reference.md), record
the relevant commit/evidence, and resolve remaining conflicts deliberately.
Cobblemon research supplies comparisons, not replacement mechanics authority.

## Living-world execution plan — October 29, 2026

Owner requested a concrete plan following the living-environment pivot. This
section owns cross-feature sequencing; feature roadmaps retain technical detail.
Runtime steps below are planned, not implemented or accepted by this document.
Step 0's conceptual authoring deliverable is recorded below; owner acceptance is open.
Owner-authorized update after the conceptual questionnaires: the owner is away,
so current work is conceptual. Runtime work and owner play review are subsequent
gates. The approved direction is recorded in the
[Bible](reference/SolHunter_Worldbuilding_Bible.md#owner-approved-living-environments-vessels-and-landmarks--october-29-2026);
the [concept report](living-world-concept-report.md) retains examples and open
questions. Do not treat every example as an implementation requirement.

### 0. Specify healthy nature and landmark concepts

Author meadow and woodland experience sheets: geographic character, natural
activity, sound, weather response, quiet/focal pacing and revisits. Define the
Vessel cue/lifecycle boundaries before mechanics implementation. Specify one
candidate natural landmark per biome with terrain fit, safe approaches, ambient
state, lore evidence and possible event conditions. Keep facts separate from
interpretations. No people or human disruption in the first slice.

Deliverable: reviewable conceptual sheets and an explicit list of source-backed
rules versus remaining decisions. Existing canon for the secluded healing
gathering is preserved; the new wounded-ally and wormhole ideas are provisional.

October 29 delivery: [healthy-nature experience sheets](living-world-concept-report.md#13-first-delivery-healthy-nature-experience-sheets)
now specify meadow/woodland character, motion, sound, pacing and revisits;
two candidate natural landmarks; Vessel cue/lifecycle boundaries; and an evidence
classification. Concept authoring is complete, with owner acceptance and mechanics
decisions open. No runtime feature or source reconciliation is claimed.

### 1. Establish the road and its baseline

Select an accessible normal-game road segment crossing meadow and woodland;
use another existing adjacent habitat if that transition is unsuitable. Record
seed, captured settings and source fingerprints, then walk outbound and back.
Include a short stationary observation with no nearby Sols in frame, without
disabling normal wildlife. Identify three concrete failures: static surroundings,
interchangeable habitat composition, or unclear Vastra are initial candidates,
not assumed findings. Reuse current review tools and preserve normal player saves.

Deliverable: baseline captures/motion evidence and three before/after criteria.
Keep all later comparisons on this segment before expanding to other seeds.

#### October 29 road baseline: recorded, owner acceptance open

Added `tools/review_living_road.gd`, extending the existing normal-input journey
controller. Seed `2601026`, generation 10, normal `world_3d.tscn`, 1280×800,
Godot 4.7.2 stable, D3D12 on RTX 3070. The essential stone road reaches woodland
at `(53, -2)` and meadow at `(55, -3)`. Walked from the refuge to both stops,
back to the woodland stop, then home. Zero traversal assertions failed, zero
automatic contacts occurred; automatic contact, wildlife and the saved active
clock remained enabled. No player save was read or written by the review tool.

Evidence is local and ignored under `artifacts/world_exploration/`:

- `living-road-baseline/`: initial wide-view run, meadow `(6, 4)` to woodland
  `(53, -2)`, return; zero traversal failures. Launch reported user-data/cache
  access errors. Retain as diagnostic evidence, not a clean engine pass.
- `living-road-clean/`: revised camera-framing run, `review.json`, captured
  settings, 27 stationary PNGs and `inputs-before.json` with 851 SHA-256 hashes.
  Despite the directory name, launch reported failure to open the requested log
  because the directory did not yet exist. The rendered journey completed with
  zero assertion failures; it is not an error-free launch claim. The manifest was
  captured after renderer launch and compared after completion: no recorded
  input drift. HEAD/status are included; this is a dirty-working-tree sample.
  Subsequent pinned-engine editor import/parse passed; `import.log` records it.

Reproduction, after creating the output directory:

```powershell
New-Item -ItemType Directory -Force artifacts/world_exploration/living-road-repeat | Out-Null
godot --path . --rendering-driver d3d12 --script tools/review_living_road.gd --log-file artifacts/world_exploration/living-road-repeat/engine.log -- --output=res://artifacts/world_exploration/living-road-repeat --seed=2601026
```

The controller takes nine screenshots per stop, each separated by 60 rendered
frames. This is a frame sequence, not a fixed-duration video. It tries eight
camera azimuths at the configured minimum distance; neither stop yielded an empty
Sol frustum. The inspected views visibly contain Sols and labels. Wildlife was
not disabled to manufacture solitude. The Sol-free stationary observation was
still open in these first runs; the completion follow-up below supplies it.
Normal-input human review and owner visual acceptance remain open.
The view is the normal game camera, not a player-eye camera fixture.

Three bounded findings and before/after criteria:

| Finding in this sample | Next comparison on the same road |
| --- | --- |
| Woodland occupies only road x=53–54 between marsh and meadow; inspected close meadow/woodland views share open ground and sparse edge detail, without a strong enclosure change | Recognize the woodland entry and meadow opening from structure and sightlines with habitat labels disregarded; retain all essential road access |
| Production tree foliage adapts ordinary materials in `nature_art.gd`; grass uses its own live-`TIME` sway in `meadow.gdshader`. There is no shared saved-clock crown/grass gust response | Observe one coherent breeze across grass, shrubs and crowns, with distinct exposed/sheltered responses; verify calm, pause and reload under WX0–WX4 |
| Inspected frames show thin, long Vastra strands crossing open road/ground views; their connection to the local terrain is difficult to read | Repeat moving/stationary/return views in day and darkness; judge local anchoring, scale and landscape readability before tuning or changing geometry |

These are engineering visual/code findings, not owner rejection or proof of
enjoyment. This narrow woodland pocket establishes a reproducible weakness; it
does not satisfy the proposed exposed-meadow/sheltered-woodland composition.
The initial stationary sequences remained preliminary without a Sol-free frame
and complete engine log. First outbound frame times were
p50 16.68 ms / p95 30.95 ms; refuge return p50 17.85 ms / p95 33.91 ms. These are
paced controller samples, not GPU or target-device acceptance.

##### Completion follow-up: quiet meadow spur

`living-road-complete/` retains a failed road-only search: the added assertion
correctly rejected a run without Sol-free captures. It is not a passing baseline.
The current prototype catalog places authored creatures at x=50, 56, 60, 64,
68, 72 and 76; repeatedly testing crowded road views did not provide solitude.
The review now permits one ordinary walk into adjacent meadow/woodland within
12 cells of the road stop, selected by current wildlife clearance. It changes
no admissions, AI, time, weather, terrain or player save. Off-road access uses
the existing walkability pathfinder and normal input controller.

The successful follow-up is `artifacts/world_exploration/living-road-spur/`:

- Same seed, engine, renderer, scene and road stops. Walked from `(55, -3)` to
  meadow `(65, 3)` in ten normal-input steps, returned to woodland and then refuge.
  No teleports, disabled wildlife or gameplay tuning changes; zero automatic
  contacts and zero assertion failures. `review.json` records the journeys.
- `quiet_spur_00.png` through `quiet_spur_08.png`: nine stationary captures over
  approximately 10.31 wall seconds, camera distance 8 cells, elevation 80 degrees,
  azimuth 0. The active clock advances from tick 63 to 76. All nine captures were
  visually inspected: player, rock, flowers, tree edge, shadows and Vastra remain
  visible without a recognizable Sol body or Sol label. All nine sampled origin
  frustum queries were empty. Those queries alone are not silhouette/occlusion
  proof; this is sampled frame evidence, not continuous video.
- The Vastra web visibly changes between frames; tree/flower structure appears
  static at this scale. This supports the shared-weather motion priority without
  claiming environmental motion is already coherent or the art is accepted.
- `engine.log` includes renderer startup and the zero-failure completion line;
  no `ERROR:` or `SCRIPT ERROR:` occurred. `parse.log` records a successful pinned
  engine script check. `incomplete-launch.log` retains an earlier launch that
  ended without a report; no result is inferred from it.
- Before/after manifests cover 925 source inputs at HEAD
  `86182cdd52cb2de73951adebf397fd959991f6fd` plus the recorded dirty status.
  Seven nature-sample texture `.import` sidecars changed after the first manifest
  capture; their modification times precede the successful retry. Paths, hashes
  and times are in `input-drift.json`, with final hashes in `inputs-after.json`.
  Do not call this an unchanged-tree visual benchmark or silently reuse the
  earlier manifest as the successful retry's exact starting state. No generation,
  simulation, resource or shader source hash changed in that comparison.

The review tool's subsequent note-only wording correction clarifies the origin
query limitation; the recorded run predates that text change. It does not change
selection, movement or captures. Keep the original run artifacts intact.

Step 1's missing capture/log evidence is now supplied, with the fingerprint gap
above retained explicitly. Owner experience acceptance remains open. Next use
step 2 for daylight/darkness Vastra review on this same sample and WX0 for the
shared-weather contract. Use a fresh prelaunch manifest for the next comparison;
do not expand seeds or treat this as a full validator/device pass.

### 2. Review and stabilize the current Vastra presentation

Use the existing world-anchored web rather than restart its implementation.
Review it on the chosen road in daylight and darkness, while moving, stationary
and after returning. Tune visibility, scale and movement against the approved
look: the landscape remains readable and the field belongs to it. Record which
problems are art tuning and which require supporting geometry/code changes.
See [Vastra visual roadmap](vastra-visual-roadmap.md) for ownership and evidence.

Deliverable: one coherent, reviewable Vastra treatment in the actual world.
Do not make a decorative current imply a saved discovery or new energy transfer.

### 3. Connect environmental motion through shared weather

Advance [WX0–WX2](weather-roadmap.md#delivery-sequence): establish one saved-clock
weather/wind contract and connect grass, shrubs and tree crowns in streamed
scenery. Then connect existing cloud/rain/audio consumers through WX3 as the
slice permits. Keep missing audio slots silent. Prefer a few agreeing responses
to many independent effects. Verify calm, breeze, gust, pause and reload.

Deliverable: a visibly passing breeze that the surroundings respond to together.
Vastra retains its own approved flow behavior; wind does not automatically drive
Vastra, alter concentration, or produce ecological overload.

### 4. Give the two habitats different environmental character

Use current geographic parents and biome palettes. Improve one exposed meadow
and one sheltered woodland treatment through groundcover distribution, grove
edges, clearing/road relationships, sightlines and existing terrain/water context.
Connect bounded geographic shelter through WX4 after the shared breeze works.
Give the habitats different vegetation responses and supported ambient sound
where suitable licensed cues exist. Any sparse leaf/dust accents must fit actual
cover/weather and reuse the existing effects budget; they are optional polish.

Deliverable: a transition recognizable through composition and activity, not
only tint or species selection. Road access and interaction visibility remain
hard constraints. Connected rivers are a separate terrain slice, not a
prerequisite; do not paint flowing water onto unconnected drainage data.

### 5. Add a bounded environmental moment if the foundation holds

First use a supported weather transition: a gust travels through the roadside
vegetation, clouds/light change, and the existing audio responds where assigned.
Choose spacing and intensity through review, leaving quiet intervals. This
demonstrates change over time without a new random-event or quest framework.

Deliverable: one perceptible moment during ordinary travel or stationary watching.
Human routines are deferred. Vessel activity is now approved conceptual scope,
with **Vessels** as its placeholder name; it is not an implemented population
system. Define a bounded biome-specific presentation/cue pilot after shared
weather and scenery contracts are ready. Lifespan, persistence and actual energy
transfer remain unresolved. Resource cycles, hazards, ecological changes and
Vastra storms require separate source/design reconciliation.

### 6. Develop landmark activity and one event specification

Use authored identities with generated variation and stable saved site references.
Require recognizable terrain, environmental lore and ambient activity even between
events. Conditions reference weather, time, local Vastra and Vessel activity.
Define eligibility, signs, participation, absence, resolution, aftermath and
recurrence for one selected situation before coding. Different participation
outcomes need explicit rules and persistence scope; do not infer punishment for
leaving. Select between sanctuary/territory/den concepts only after conceptual
review. A literal wormhole is not approved. Natural site composition may proceed
in the eventual slice; downloaded landmark-model rollout remains on hold.

Deliverable: one coherent event specification and site placement contract.
Implementation follows only after mechanics reconciliation and unresolved design
decisions. Sol events complement the world-without-Sols acceptance criterion.

### 7. Review the connected result and choose the next weakness

Repeat the same outbound/return route and stationary observation under normal
input. Ask: does something happen without Sols, can the two habitats be recognized,
does Vastra feel integrated, and is there a detail worth approaching? Record owner
answers separately from automated correctness. If the slice succeeds, sample two
additional seeds for repetition and access problems before broader rollout.

Run focused checks for changed Vastra, atmosphere, scenery, geography and audio
contracts, plus engine import/parse and rendered motion review. Exercise streaming,
pause, live menu, save/load and battle return where the shared timeline changes.
Measure relevant desktop frame cost with matched inputs; no Thor gate is added.
Record exact dirty inputs and do not claim stable-tree evidence if they drift.

### Work boundaries and stopping point

Step 0's conceptual sheets are authored; owner acceptance remains open. During subsequent implementation, execute steps
1–4 with small feature-owned changes, then the bounded activity/Vessel slice in
step 5. Step 6 prepares a later event; it does not require building an event engine
to review the environment. Step 7 closes whatever actually shipped.
After each step, retain a playable F5 world and report delivered versus open work.
If visual review rejects the current Vastra treatment, keep weather/biome work
moving using the existing effect toggle rather than blocking all work on art.

Downloaded landmark placement, people/human disruption, optional leads, campaign
content, roster expansion, shops and deep simulation remain outside this slice.
Landmark concepts are in scope. A successful first runtime slice is two
distinct habitats with coherent environmental activity and integrated Vastra,
not a claim that the entire ecosystem or game loop is complete.

## Starting point

The [reformat evidence](reformat-roadmap.md#r8-final-configured-result) records
the completed desktop gate at runtime revision `2f13c5a`: 52,274 checks and a
separate connected rendered run. Owner playable review remains open. This is
recorded evidence for that revision, not certification of later working changes.

Reuse existing geography, routes/ponds, streaming, procedural site contracts,
saved identities, Sol behavior, observation, combat, collection and persistence.
The [cohesive world sample](cohesive-world-sample.md) is bounded and seed-specific;
it does not establish varied scenery throughout all generated worlds. Existing
story events/director/ledger are foundations to inspect for reuse, not proof that
a generated quest system already exists. No phase below starts by rebuilding them.

## Delivery sequence

| Phase | Player-facing result | Dependency | Current status |
| --- | --- | --- | --- |
| W0 | Research explains how a creature-filled sandbox creates its own goals | Existing project evidence | Research and automated three-seed review recorded; human play observation open |
| W1 | Moving through the current world is comfortable and inviting | W0 priorities | Habitat labels connected; broader comfort review open |
| W2 | Geography offers recognizable places and meaningful route choices | W1 route/comfort findings | District landforms, mountain ranges and pond-fed level connections implemented; downhill rivers and connected play review open |
| W3 | Generated places feel composed and different from one another | W2 geography contracts | Four biome palettes connected; nature-first meadow/woodland landmark concepts now prioritized; visual review open |
| W4 | Natural activity, Vessels and Sols give places character and reasons to revisit | Suitable W2/W3 places | Four-habitat encounter pilot connected; environmental activity/Vessels/event framework conceptual; runtime and player review open |
| W5 | Natural situations arise from real local conditions; NPC requests follow later | Stable place/participant IDs and W4 activity | N4 now; NPC request pilot deferred to N7 |
| W6 | Loose early play sustains curiosity and preserves meaningful outcomes | Connected W1–W5 slice | Proposed; owner/early-player review pending |

These are delivery gates, not a requirement to finish every terrain feature before
trying an interaction. Prove one small connected example, then expand the weakest
part. Do not assign calendar estimates before the first reviewed slice.

### W0 — Research and choose the first world slice

First report: [Cobblemon and the exploration loop](research/cobblemon-world-exploration.md).
Use its distinction between Minecraft's underlying sandbox and Cobblemon's creature
layer to identify what SolHunter must provide itself. Research alone does not
prove enjoyment or justify importing crafting, building or survival systems.

Next, walk the current refuge/woodland/pond/dryland loop with normal gameplay.
Record where curiosity starts, where travel becomes empty or repetitive, whether
Sols invite observation, and whether the return feels worthwhile. Proposed review
sample: one familiar seed and two different seeds, including an awkward start;
keep seed/settings/revision and useful player-height captures with the findings.
An initial 15–20 minute session is a review workload, not a production duration goal.

Exit: identify the three largest experience problems, select one compact world
slice, and define observable before/after criteria. No new full validation run is
needed just to repeat a walkthrough of unchanged inputs.

### W1 — Traversal and orientation

Fix demonstrated movement, grounding, camera, visibility, picking and interaction
problems on that slice. Essential travel stays accessible; optional detours should
be readable from terrain, vegetation, water and landmarks. Let players notice a
destination and choose an approach rather than depend on an unexplained marker.

Exit: a normal-input outbound/detour/return journey without traversal blockers,
repeated camera obstruction or confusing interaction selection in the covered
sample. Record owner comfort feedback separately from automated correctness.
Check large Sol footprints where the affected access contract requires them.

### W2 — Geography that creates exploration

Develop relief, habitat transitions, water edges and route topology using the
existing deterministic generator. Judge them by the journeys they create: changing
views, recognizable regions, alternative approaches, occasional reveals and a
legible way home. Vary structure and spacing before simply adding more objects.
Keep important authored anchors and required access intact.

First compare the current route/pond slice across the W0 seeds. Advance connected
streams or broader regional landforms from the terrain roadmap only when those
findings justify them; full drainage simulation is not a prerequisite for fun.

Exit: visibly and navigationally distinct journeys across the review seeds, with
deterministic reconstruction, continuous boundaries and valid essential routes.
Geography changes require explicit generation/save versions and current-format
behavior; do not silently reroll loaded expeditions or rebuild legacy generators.

### W3 — Places with purpose

Extend the scenery hierarchy from regional character through site layout to
structures, vegetation and detail. Preserve sibling space budgets, approaches,
clearings and stable parent identities. Develop habitat-compatible palettes beyond
the existing fixed sample. A place should be recognizable through its composition
and possible interactions, not only a shuffled arrangement of the same props.

Proposed first scope: three reusable place treatments in the selected landscape,
using current approved content. Compare silhouettes, approaches, usable space and
local activity. New settlement identities, lore and interaction rules remain
authored proposals until resolved through the governing references.

Exit: useful differences across seeds, safe admission or explicit omission at
unsuitable sites, no overlapping/buried entrances, and no unrelated layout reroll
when a small decoration changes. Review actual player-height views.

### W4 — A world inhabited by Sols

Use existing species records, habitat/traversal policies and inherited behaviors
to make creatures belong to places. Prioritize visible behavior and individual
continuity over roster expansion. Observation should reveal something useful;
companions should remain present during ordinary travel, not only in battle.

Owner clarification, October 29: the prototype roster is limited. Reuse suitable
species across habitats and existing behavior differences; keep encounter pools
and weights provisional. Precise rarity, encounter-frequency and roster balance
are not prerequisites for the exploration prototype.

Select one behavior/habitat relationship already supported by approved content
and prove it through normal play, return and save/load. Any new ecological effects,
time/weather availability, cooperation or relationship rules need source evidence
and an explicit specification before implementation. Presentation weather alone
does not authorize ecological modifiers.

Exit: players can describe a local Sol's behavior and why the place suits it;
the same retained individual and recorded discoveries survive revisits/reloads.
Reconcile this with existing population recovery rather than promising that every
wild creature persists forever. Keep activity independent of rendering lifetime.

### W5 — Natural interactions now; generated NPC requests later

Create bounded, authored templates whose participants, place and conditions are
selected from actual saved world facts. Generation should produce a valid local
situation with something to discover or choose; random names and destination
markers alone are insufficient. Do not assume runtime AI text generation.

Start by inspecting the existing story event/director/ledger and save contracts.
Consult SolHunterSource for relevant quest, encounter, reward and persistence
behavior before choosing rules. Extend the existing owner where suitable; avoid
a parallel quest save or a second ecology authority.

Proposed pilot: two small interaction families using supported actions, such as
an observation-led discovery and a peaceful habitat encounter. The request pilot
is deferred to N7. These are examples, not approved rewards, species lore or new
gameplay verbs. Specify eligibility, target validity, choices, completion,
interruption, recurrence and consequences before coding. Declining or leaving
should have deliberate, documented behavior; unresolved penalties must not
become accidental defaults.

Require stable event/place/participant IDs, saved choices/outcomes, replay-safe
completion and explicit invalid-target handling. Do not generate a request for an
absent participant, inaccessible destination or unsupported action. Revalidate
world conditions at resolution; admit no event if a coherent situation cannot fit.
Use bounded selection, variation and repetition controls with Inspector tuning.

Exit: two different situations across the selected seeds; accepting, declining,
leaving, reloading and returning behave as specified; resolution cannot duplicate
its reward or consequence. Any reward rules must first be reconciled and authored.
Retained facts can inform later story without assigning a campaign chapter now.

### W6 — Early play and First Age atmosphere

Offer loose play with optional local leads, meaningful discoveries and persistent
personal outcomes. Separate witnessed facts, testimony and local interpretation
in presentation. Use approved worldbuilding and original SolHunter identity;
First Age atmosphere does not require an invented historical chronology.

Review whether players choose their next destination, remember places and Sols,
and can recount a memorable event without a campaign quest. Track dead travel,
repeated situations, confusing clues and why players stopped. Fix the weakest
link before expanding geographic area, species count or template volume.

Exit: owner review plus recorded early-player feedback when available; working
current-format save/load; one connected correctness/rendered gate appropriate to
the combined changes. This does not claim public distribution readiness: asset
redistribution rights and eventual external-save policy remain separate gates.
Revisit a small authored story slice once these foundations support it; finishing
the entire world is not required. Decide separately whether any early events
become canon; no automatic save-to-lore or multiplayer history system is approved.

## Validation and execution

Deliver bounded changes under the project standard on `codex/` branches, preserve
owner files, inspect diffs and stage explicit paths. Keep normal F5 play connected.
Expose connected authoring/tuning in Godot; distinguish presentation changes from
saved generation and identity changes.

Reuse existing focused suites for terrain, scenery, behavior, world journeys and
save/load; add checks only for new contracts and real failure modes. Record seed,
settings, revision/dirty inputs, result and limitations. Reuse unchanged evidence.
Run broader integration at shared-contract changes and final combined acceptance;
configured CI remains unchanged. Desktop stalls or runaway resource use that harm
play warrant fixes. Do not turn deferred Thor work into a prerequisite for a world
slice, or claim desktop checks establish target-device acceptance.

## Progress and first action

| Item | Result | Next action |
| --- | --- | --- |
| W0 research report 01 | Desk research complete; primary sources and limitations recorded | Review its proposed exploration experiment in the game |
| W0 playable audit | Automated three-seed review and three priorities recorded in [biome scenery](biome-scenery.md); free-choice player review remains open | Review the four rendered biome treatments and normal gameplay |
| Living-world road baseline | Same-seed normal-input outbound/return, Sol-free meadow spur captures and complete error-free rendered log recorded above; texture-import fingerprint gap disclosed | Day/night Vastra review and WX0 contract; owner experience review remains open |
| W1/W3 first slice | Habitat labels, biome palettes and hierarchical scale/color variation implemented | Owner visual review |
| W2/W4 pilot | District landforms, local drainage, safe-path admission and four captured encounter pools implemented | Normal-play review; develop connected water under shared access contracts |
| W5–W6 | Remaining work open | Generated local interactions after the inhabited-world review |

Immediate work follows the living-world execution plan above: select and record
the step 1 road baseline through meadow and woodland, then review Vastra and
advance shared weather and habitat character. Connected water remains a separate
terrain slice. Review [biome encounters and geography](biome-encounters-geography.md)
in normal play while establishing that baseline. The owner
selected the existing four biomes, related but noticeable visual differences, new
art where needed, and Sol encounters/behavior as the first mechanical distinction.
Keep this table current; store detailed feature evidence in its existing owner.

October 29 phase 2 follow-up: [biome encounters and geography](biome-encounters-geography.md)
implements the initial W4 habitat-pool pilot and extends W2/W3 with district
landforms, grove/individual variation, cloned material tints and local drainage
influence on pond placement. [Research report 02](research/noise-landforms-water.md)
explains Perlin's role and the remaining connected-stream work. Paths must remain
within player-scalable terrain; final road admission checks actual grade and
clearance after foundations. Owner play review and broader W4–W6 remain open.


## Vegetation and Vessel response follow-up

October 29, 2026. Owner-authorized refinement includes plant classes, data-carrying
Vastra, usually swarm-like immune-response Vessels, natural overload and player
communication. The [Bible](reference/SolHunter_Worldbuilding_Bible.md#vegetation-and-vessel-response--october-29-2026)
owns direction; [concept section 14](living-world-concept-report.md#14-vegetation-signals-and-vessel-response)
owns functions, source evidence and communication. Earlier cue-only scope is
superseded; runtime delivery remains open. Reuse the recorded road baseline.

| Stage | Deliverable | Acceptance |
| --- | --- | --- |
| 1 | Grass/tree/class contracts | Cap 100, root overflow, conserved energy, Sol feeding, unbiased recipients, access and baseline recovery retained |
| 2 | One expiring disturbance signal | Original expiry, deduplication, finite relay; no free energy or remote knowledge |
| 3 | One swarm: ordinary/investigate/respond/recover | Stable group state; test disturbance; visuals and Observe agree; healthy without mandatory Regulators |
| 4 | One Warden, Mender and Regulator species | Distinct paid effects; idle plants never described as acting |
| 5 | Escalation plus a specified natural detector | Finite recruitment, reassessment, termination; no overload from ordinary feeding/weather |
| 6 | Storm admission then lifecycle | Existing 3x3, conditions/chance, protected access; no guaranteed cleansing |
| 7 | Same-road day/night walk, watch and revisit | Group picking usable; legible without color/sound alone; danger warning; quiet intervals |

Weather and habitat work continue alongside stages 1-4. Keep natural storms behind
a tested detector and termination model without blocking ordinary environmental
improvements. Runtime checks cover energy, paid actions, signal expiry/replay,
pause/combat clock, save/load, bounded work, streaming and state-to-menu agreement.
Inspect motion and text in a real scene. Numerical balance, Vessel biology,
splitting/merging and player intervention remain open. This plan claims no runtime
change or new gameplay validation pass.


### Connected runtime pilot — October 29, 2026

The owner authorized implementation of the vegetation/Vessel design and supplied
placeholder plants. [Vastra integration](vastra-integration.md#vegetation-and-vessel-runtime-pilot--october-29-2026)
records the actual contracts and limits: classified grass/receivers, bounded class
functions, expiring packet-carried signals, resident swarms, paid response and
recovery, provisional stranded-root detection, and live Observe/Details/group
picking. Supplied class models are connected with a portable fallback. These are
first functions, not completion of every conceptual class capability.

Formation checks exist, but production storms default off pending the separate
storm-behavior design. Traveling swarms, Vessel biology, regional source budgeting,
full storm lifecycle/exposure and player intervention remain open. Continue shared
weather and habitat work; keep the recorded normal-road baseline. The injected
render fixture is a mechanics/communication study, not a normal-input road or
owner play-acceptance claim. Source evidence remains in concept section 14.


### Pilot validation and remaining delivery

Godot 4.7.2 focused checks: Vessel ecology 68 (real Direct3D 12 scene), plant
Vastra 330, persistent foundation 76, Vastra integration 38, inspection card 22,
combat world continuity 23 and Sol observation 38: **595 checks, zero failures**.
The targeted root/inspection regressions were corrected and rerun; unaffected
focused evidence is reused under the project standard. Results and exact input
hashes are in `artifacts/vessel-response/validation-results.json`,
`validation-final-inputs.json` and `ecology-final-inputs.json`. The recorded
end-of-run input drift reports are empty. Scope is not a full validator pass.

The twenty-model and selected three-class Direct3D 12 reviews completed without
engine/script errors. The canonical-terrain fixture injects a declared disturbance,
then verifies saved swarms, class models, group picking, Observe/Details and
camera-independent state; inspected images are `connected.png` and
`class-placeholders.png`. It is not a normal-input road/owner experience review.
Plant action pulses are presentation of paid current activity and preserve the
resolved tile affinity; idle plants have no such activity cue.

The 1,296-node/nine-swarm, 100-tick probe recorded p95 10.931 ms, p99 11.330 ms,
maximum 11.614 ms in the rendered test process. This is simulation-tick CPU cost,
not whole-game frame time or device acceptance. Region-index/trait reuse reduced
the initial roughly 19 ms p95; additional balancing/performance work remains.

Final editor-import recheck was interrupted by a full C: drive after the focused
checks completed. Only this task's generated temporary user caches were removed
(about 8 MiB); code, models, logs and review images were retained. Earlier import
and final real-scene compilation/rendering passed, but no post-cleanup final
editor-import pass is claimed. Free additional disk space before further imports.

Next delivery remains normal-input meadow/woodland review and balance tuning,
then region-wide supply allocation and fuller class/species authoring. Production
storm activation stays off pending its separate behavior/exposure design. Traveling
swarms, biology, player intervention and full storm lifecycle remain open.
