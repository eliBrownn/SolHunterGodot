# World and exploration delivery roadmap

## Active world baseline — November 5, 2026

Normal play starts on the coast in the [map-first generator](world-map-proposal.md).
Plan v7 supplies the geography, climate, drainage, water levels, natural biomes,
and irrigation-adjusted biomes before local terrain streams. Movement, visual
vegetation, and seeded Vastra vortices are connected to this world.

Review the atlas at fixed seeds and use the normal launch for shoreline, channel,
and biome transitions. The [seeded smoke test](../README.md#validate-the-map-first-build)
covers movement, chunk streaming, plant patch reconstruction, and storm persistence.
The October route, refuge, Sol, and combat milestones below refer to the inherited
expedition. Their implementation and acceptance records apply to that fixture.

October 30 generation follow-up: owner selected connected water, added mountain
ranges and approved WorldGen's layout-first principle. Generation 13 now has
optional pond/channel/satellite-pool connections and cross-district ridgelines;
the grass defaults are 40% shorter and 15% narrower. See
[terrain delivery/evidence](natural-terrain.md#connected-water-and-mountain-ranges--october-30-2026).
These level-channel and mountain foundations do not close downhill rivers,
regional watershed connectivity, authored passes or normal-play acceptance.

Relic planning follow-up, October 30: the owner requested a shared relic system,
Vastra reactions and gameplay-focused planning. The [relic delivery plan](relic-roadmap.md)
owns the proposed resonator discovery, later conserved connections and local
operation choices. This is planning only; powered roles and example operations
remain proposals. It does not change current cross-feature priority or lift the
downloaded landmark-asset hold.

Plant-community follow-up, October 30: the owner authorized starting the Deussen
ecosystem-inspired plan. The first isolated Development Lab comparison is
implemented; production integration remains pending. The experiment, limitations
and subsequent sequence are recorded in
[procedural plants](procedural-plants.md#plant-communities-experiment--october-30-2026).
Reuse that evidence before adding real geography/drainage, canonical admission and
saved generation settings. This establishes no new live ecological mechanics.

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
that goal. Landmark asset placement is on hold; optional leads are not the next
delivery priority. Existing combat, collection and persistence remain connected.

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
players choose their own direction through exploration, Sol encounters, generated
quests and local interactions. Give that experience a First Age feeling: discovery,
incomplete knowledge and experiences that could later inform the world's stories.
This is an atmosphere and development direction, not a decision that early saves
become permanent canon or that players share a historical online world.

Authored campaign delivery, including the storm-rescue opening, is deferred.
Generated quests and interactions are in scope now and should support later story
connections. AYN Thor optimization, export and device acceptance are far deferred;
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
The October sequence required a playable expedition after each step and report delivered versus open work.
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
| W5 | Generated quests and interactions arise from real local conditions | Stable place/participant IDs and W4 activity | Proposed; mechanics reconciliation required |
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

### W5 — Generated quests and interactions

Create bounded, authored templates whose participants, place and conditions are
selected from actual saved world facts. Generation should produce a valid local
situation with something to discover or choose; random names and destination
markers alone are insufficient. Do not assume runtime AI text generation.

Start by inspecting the existing story event/director/ledger and save contracts.
Consult SolHunterSource for relevant quest, encounter, reward and persistence
behavior before choosing rules. Extend the existing owner where suitable; avoid
a parallel quest save or a second ecology authority.

Proposed pilot: two small interaction families using supported actions, such as
an observation-led discovery and a request concerning an actual nearby place.
These are examples, not approved rewards, species lore or new gameplay verbs.
Specify eligibility, target validity, choices, completion, interruption, recurrence
and consequences before coding. Declining or leaving should have deliberate,
documented behavior; unresolved penalties must not become accidental defaults.

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
owner files, inspect diffs and stage explicit paths. Use the inherited expedition for these historical integration checks.
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
