# Project research and development reference

Consolidated November 1, 2026 at the owner's request. This indexes the whole
repository's available research, design references, engineering investigations,
experiments and validation receipts. It does not certify the current build or
recover knowledge that was never saved from an older chat.

The [project standard](../PROJECT_STANDARD.md#development-guideline-use-research-make-bounded-changes-stop-at-sufficient-evidence)
contains the development guideline. It remains the workflow authority; the
[Bible](../reference/SolHunter_Worldbuilding_Bible.md) owns design and the
[master roadmap](../master-roadmap.md) owns execution order. Follow each feature's
own contracts and dated receipts for implementation and acceptance status.

## Where to look before doing more work

| Area | Research and owning records | What to preserve or learn from |
| --- | --- | --- |
| Game vision, story and species | [Bible](../reference/SolHunter_Worldbuilding_Bible.md), [Sol Bible](../reference/sol_bible.md), [story](../story.md), [decisions](../decisions/2026-10-28-opening-companionship-and-consequences.md) | Canon, provisional ideas and deferred campaign work are different. A model study does not approve a roster entry. |
| Mechanics source evidence | [Mechanics reference](../mechanics-reference.md), [class buffs](../class-buffs.md), [stats](../sol-stats.md), [affinity moves](../affinity-moves-imprints.md) | Use verified source revisions for non-generation rules; Godot retains generation authority. |
| Exploration motivation | [Cobblemon study](cobblemon-world-exploration.md), [living-world concepts](../living-world-concept-report.md), [nature area](../nature-alpha-area.md), [world roadmap](../world-exploration-roadmap.md) | Desk-research inferences are not playtest evidence. Nature-loop acceptance and campaign delivery are separate. |
| Terrain and geography | [Noise/landforms/water research](noise-landforms-water.md), [geography slice](../biome-encounters-geography.md), [terrain roadmap](../terrain-roadmap.md), [natural terrain](../natural-terrain.md) | Noise is input; parents own geography and water context. Render chunks must not invent independent landscapes. Preserve traversable routes and captured generation settings. |
| Scenery, structures and relics | [Biome scenery](../biome-scenery.md), [building collision](../building-collision.md), [structures](../structures.md), [blockouts](../structure-blockouts.md), [relic roadmap](../relic-roadmap.md) | Required spaces, footprints, access reservations and authored exceptions constrain decoration. Read placement receipts before reusing old timings. |
| Plants and ecosystem authoring | [Procedural plants](../procedural-plants.md), [ecosystem](../reference/ecosystem.md), [reviewed visuals](../reviewed-world-visuals.md), [forest study](../forest-style.md) | Preserve reviewed designs, original review IDs and approval records; appearance changes cannot multiply canonical plants or reserves. |
| Vastra and ecological accounting | [Integration](../vastra-integration.md), [natural recovery](../vastra-natural-recovery.md), [human activity](../vastra-human-activity.md), [resource evaluation](vastra-resource-evaluation.md), [visual roadmap](../vastra-visual-roadmap.md) | Geographic membership, conserved transactions and saved ownership precede optical presentation. Finite-speed transfers and their visible effects are different evidence. |
| Wildlife and companions | [Behavior roadmap](../sol-behavior-roadmap.md), [ecology](../sol-ecology.md), [movement](../sol-natural-movement.md), [flight/swimming](../sol-flight-and-swimming.md), [owned companion](../owned-companion.md), [population recovery](../wild-population-recovery.md) | Species behavior, individual identity/affinity and render ownership remain independent. Reuse established navigation and admission evidence. |
| Creature artwork and reviews | [Design handoff](../sol-creature-design-handoff.md), [model authoring](../creating-sol-models.md), [anatomy review](../sol-creature-anatomy-review.md), [creature models](../sol-creature-models.md), [species data](../sol-species-data.md) | Keep model/rig evidence, provisional bodies and approved designs distinct. Species pages and JSON review registries retain item-level records. |
| Combat | [Readiness contract](../readiness-alpha-contract.md), [combat roadmap](../combat-roadmap.md), [action budget](../combat-action-budget.md), [first playable battle](../first-playable-battle.md), [consequences](../combat-consequences.md), [pacing](../combat-pacing.md) | The production readiness contract supersedes conflicting historical turn fixtures. Planning, surrounding-world continuity, committed actions and outcome reconciliation have separate owners. |
| Persistence and connected play | [Persistent foundation](../d1-persistent-foundation.md), [expedition integration](../expedition-integration.md), [playable baseline](../current-playable-baseline.md), [alpha contract](../readiness-alpha-contract.md) | A dated passing build is not a claim about later dirty sources. Preserve identity and current-format admission; report unresolved snapshot failures separately. |
| UI and input | [UI roadmap](../ui-ux-roadmap.md), [field menu](../field-menu.md), [Sol menu](../sol-menu.md), [controller input](../controller-input.md), [encounter initiation](../encounter-initiation.md) | Preserve desktop/controller behavior and actual live/pause ownership. Inspect existing reading/layout caches before adding another. |
| Weather, water and audio | [Weather roadmap](../weather-roadmap.md), [atmosphere](../atmosphere.md), [water appearance](../water-appearance.md), [audio framework](../audio-framework.md) | Shared weather/mix owners constrain local presentation. Existing environmental presentation does not authorize new ecological mechanics. |
| Asset evaluation and rights | [Asset-store review](asset-store-review.md), [reviewed visuals](../reviewed-world-visuals.md), [stone assets](../stone-obstacle-assets.md) and asset-folder provenance/license records | Price/download availability is not redistribution permission. Keep proprietary local sources and supplied licenses intact. |
| Architecture and organization | [Reformat roadmap](../reformat-roadmap.md), [restructure checkpoint](../restructure-checkpoint.md), [project standard](../PROJECT_STANDARD.md) | Reuse verified ownership/migration evidence, stable UIDs and one authoritative owner; do not restart the architecture for cosmetic consistency. |
| Runtime performance | [Runtime optimization](../runtime-optimization.md), [world optimization research](world-optimization.md), [Inspector controls](../inspector-tuning.md) | Source-matched frame data outranks guesses based on code length. Fixture improvements, startup shifts, frame smoothness and device acceptance are different claims. |
| Background preparation | [Concurrency roadmap](../runtime-concurrency-roadmap.md), [chunk-candidate receipt](../runtime-optimization.md#isolated-background-chunk-candidate--november-1-2026) | Faster population can render more content and worsen measured frames. Retain serial fallback, memory/cancellation evidence and integration/acceptance distinctions. |
| Development tools | [Workstation](../development-workstation.md), [Sol Lab](../sol-lab.md), [story tools](../story-tools.md), [plant authoring](../procedural-plants.md) | Standalone labs remain available; main-game lab access was removed. Authoring, visual approval, runtime admission and publishing are different actions. |

## Performance findings to reuse

The complete current study is in
[runtime optimization](../runtime-optimization.md#repeatable-baseline-and-stall-attribution--november-1-2026),
with original evidence under `artifacts/frame-stalls/baseline-20261101-v4/`.
It includes three accepted baselines, three accepted expanded diagnostics, source
fingerprints, pipeline counter changes, rejected pilots and measurement limits.

- Sustained work: wildlife view synchronization averaged about 4.1 ms/frame;
  plant-reserve display about 1.5 ms/frame; descriptions about 1.6 ms when
  inspection was open. Repeated camera calculations totaled about 0.1 ms/frame.
- Hitches: accepted baseline return travel reached 277 ms. Large diagnostic
  render intervals coincided with new surface/draw pipeline compilations.
  This supports investigating pipeline preparation/reuse; it does not establish
  that every render delay is compilation or GPU execution.
- Other measured spikes include chunk-crossing wildlife admission, simulation
  batches, atomic scenery steps and battle view updates. A cooperative 3 ms
  streaming deadline cannot preempt a larger individual operation.
- Earlier research already added caches, validation reuse, prepared plant
  assets, resumable cell construction, rendering batches and work budgets.
  Consult those receipts before proposing another implementation.
- The old restructuring sample showed little change in exploration frame time.
  The worker candidate improves scenery readiness under its recorded conditions;
  it is not proof of smoother FPS or current integration acceptance.

Latest combined-build verification is recorded in
[the runtime evidence](../runtime-optimization.md#combined-improvements-startup-correctness-and-rendered-journey).
It includes the real startup barrier and one current-build journey; its changed
entry/settings distinguish it from older direct-gameplay baselines.

## Evidence reuse and unresolved limits

Read the source's method and latest relevant dated receipt before acting. Keep
measured observations, implementation receipts, owner approvals, proposals and
historical notes separate. Check matching runtime/settings/assets, engine,
hardware, visible population, cache policy and scenario before comparing numbers.
Do not add nested timings or reuse a stale placement/asset contract as current.

The catalog below is a documentation snapshot, not a new acceptance ledger.
Some older documents contain superseded versions or refer to absent files (for
example `ROADMAP.md` is referenced by older maintenance notes but is absent in
this checkout). Those references are retained as historical leads, not current
instructions. Isolated worktree receipts and ignored artifacts may be available
only on this machine. The index does not publish them or grant asset rights.

Existing failed/interrupted runs, save-snapshot issues, native shutdown symptoms,
owner review and target-device gates keep their original qualifications. The
master and feature roadmaps retain their unresolved work; inclusion here closes
none of those gates. Ask before extensive new testing unless already authorized.

## Complete source catalog

The companion [machine-readable catalog](project-research-catalog.json) records
every available Markdown document under `docs/`, its headings and SHA-256,
referenced artifact locations, provenance-file locations, tool/test inventories
and local top-level artifact directories. It indexes existing material without
running tests, importing the game or recursively duplicating snapshot projects.

<!-- SOURCE_CATALOG -->

Snapshot: **123 source documents**, **35 provenance locations**, **133 tool files**, **156 test scripts**, and **222 local artifact directories**. Counts describe reference coverage, not passing checks.

### Research reports

- [Downloaded asset comparison](asset-store-review.md)
- [Research report 01: Cobblemon and the exploration loop](cobblemon-world-exploration.md)
- [Research report 02: noise, landforms and water in a modular world](noise-landforms-water.md)
- [Vastra: supplied resource evaluation](vastra-resource-evaluation.md)
- [World optimization evidence](world-optimization.md)

### Design decisions

- [Visual direction: pixel art in a 3D world](../decisions/2026-10-26-pixel-art-3d.md)
- [Encounter initiation for the first prototype](../decisions/2026-10-27-encounter-initiation.md)
- [Full 3D presentation and mouse controls](../decisions/2026-10-27-full-3d-and-controls.md)
- [Opening, companionship, and lasting consequences](../decisions/2026-10-28-opening-companionship-and-consequences.md)
- [Vastra combat and restorative conditions](../decisions/2026-10-28-vastra-combat-and-restoration.md)

### Bible, species and visual references

- [Ecosystem — life, circulation and response](../reference/ecosystem.md)
- [Sol Bible](../reference/sol_bible.md)
- [SolHunter — Complete Worldbuilding Bible & Research Compendium](../reference/SolHunter_Worldbuilding_Bible.md)
- [Ashquill first-form blockout](../reference/sols/ashquill.md)
- [Bellroot production sheet](../reference/sols/bellroot.md)
- [Bitterfrill first-form production sheet](../reference/sols/bitterfrill.md)
- [Browguard first-form production sheet](../reference/sols/browguard.md)
- [Claspback first-form production sheet](../reference/sols/claspback.md)
- [Crown-Ear production sheet](../reference/sols/crown_ear.md)
- [Foldling first-form production sheet](../reference/sols/foldling.md)
- [Glass-Throat first-form production sheet](../reference/sols/glass_throat.md)
- [Kilnling first-form production sheet](../reference/sols/kilnling.md)
- [Knucklemole first-form production sheet](../reference/sols/knucklemole.md)
- [Mournveil first-form production sheet](../reference/sols/mournveil.md)
- [Pebblewyrm first-form production sheet](../reference/sols/pebblewyrm.md)
- [Rattlehorn first-form blockout](../reference/sols/rattlehorn.md)
- [Reedback production sheet](../reference/sols/reedback.md)
- [Rimefold first-form blockout](../reference/sols/rimefold.md)
- [Sailcrest first-form production sheet](../reference/sols/sailcrest.md)
- [Shadepelt first-form production sheet](../reference/sols/shadepelt.md)
- [Thimblehart first-form production sheet](../reference/sols/thimblehart.md)
- [Vastra cosmic-web structure reference](../reference/visuals/vastra_cosmic_web_structure.md)

### Feature contracts, roadmaps and engineering receipts

- [Affinities, moves, and lasting battle imprints](../affinity-moves-imprints.md)
- [Affinity orb presentation](../affinity-orbs.md)
- [Field-aware enemies, testing Seals and progression](../ai-seals-progression.md)
- [Lighting, day/night and basic weather](../atmosphere.md)
- [Game audio framework](../audio-framework.md)
- [First authored Sol sightings](../authored-sol-sightings.md)
- [Battle feedback and result recap](../battle-feedback.md)
- [Biome encounters and exploration geography](../biome-encounters-geography.md)
- [Biome scenery and exploration review](../biome-scenery.md)
- [Shared building footprint and safe migration](../building-collision.md)
- [Class buffs and individual variation](../class-buffs.md)
- [Cohesive world sample](../cohesive-world-sample.md)
- [Shared combat action budget](../combat-action-budget.md)
- [Combat consequences and outside command positions](../combat-consequences.md)
- [Encounter pacing measurements](../combat-pacing.md)
- [Combat phase 3 owner session](../combat-playtest-session.md)
- [Combat presentation and controls](../combat-polish.md)
- [Combat roadmap](../combat-roadmap.md)
- [Sequenced combat resolution](../combat-sequencing.md)
- [Current expedition controller input](../controller-input.md)
- [Creating another Sol model](../creating-sol-models.md)
- [Current playable expedition baseline](../current-playable-baseline.md)
- [D0 exploration foundation: implementation and evidence](../d0-exploration.md)
- [D1 persistent foundation](../d1-persistent-foundation.md)
- [SolHunter Godot development plan](../development-plan.md)
- [Development workstation](../development-workstation.md)
- [Exploration foundation — October 26, 2026](../development.md)
- [Early combat moves and limited uses](../early-combat-moves.md)
- [Encounter initiation and withdrawal prototype](../encounter-initiation.md)
- [Complete expedition integration review](../expedition-integration.md)
- [Field menu](../field-menu.md)
- [First playable battle](../first-playable-battle.md)
- [Painterly forest study](../forest-style.md)
- [Adjusting the game in Godot](../inspector-tuning.md)
- [SolHunter living-world concept report](../living-world-concept-report.md)
- [Supplied effect integration](../local-effects.md)
- [Local Sol movement and reactions](../local-sol-reactions.md)
- [Repository maintenance status](../maintenance-status.md)
- [Master delivery roadmap](../master-roadmap.md)
- [Mechanics reference: SolHunterSource](../mechanics-reference.md)
- [Natural terrain in the live game](../natural-terrain.md)
- [Nature alpha: first area intake](../nature-alpha-area.md)
- [Owned exploration companion](../owned-companion.md)
- [Runtime territory population summaries](../population-summaries.md)
- [Procedural plant proof of concept](../procedural-plants.md)
- [SolHunter Godot project standard](../PROJECT_STANDARD.md)
- [Nature alpha runtime contract](../readiness-alpha-contract.md)
- [Real-time combat trial](../realtime-combat-trial.md)
- [Project reformat roadmap](../reformat-roadmap.md)
- [Relic structures: gameplay and delivery plan](../relic-roadmap.md)
- [Checkpoint before restructuring](../restructure-checkpoint.md)
- [Reviewed world visuals and pixel testing](../reviewed-world-visuals.md)
- [Route and pond diversity](../route-pond-diversity.md)
- [Runtime concurrency roadmap](../runtime-concurrency-roadmap.md)
- [Runtime optimization](../runtime-optimization.md)
- [Sol activity and approach consequences](../sol-activity.md)
- [Sol world behavior roadmap](../sol-behavior-roadmap.md)
- [One playable first form per class](../sol-class-coverage.md)
- [Sol anatomy review — Ashquill, Rattlehorn and Rimefold](../sol-creature-anatomy-review.md)
- [Handoff: design and build more Sol creatures](../sol-creature-design-handoff.md)
- [Pilot creature models and articulation](../sol-creature-models.md)
- [Species behavior and individual variation](../sol-ecology.md)
- [Sol flight and swimming](../sol-flight-and-swimming.md)
- [Sol Lab](../sol-lab.md)
- [Sol companion menu: phase 4 first slice](../sol-menu.md)
- [Natural movement pass](../sol-natural-movement.md)
- [Deliberate Sol observation and saved Field Notes](../sol-observation-journal.md)
- [Readable wild Sol reactions](../sol-player-reactions.md)
- [Procedural ground locomotion](../sol-procedural-ground.md)
- [Sol species data integration](../sol-species-data.md)
- [Individual Sol stats and training](../sol-stats.md)
- [Solid 3D exploration prototype](../solid-3d-prototype.md)
- [Stone obstacle assets](../stone-obstacle-assets.md)
- [Story event tools](../story-tools.md)
- [SolHunter story development](../story.md)
- [Procedural structure blockout objects](../structure-blockouts.md)
- [Structures: modular authoring and scaling](../structures.md)
- [T0 natural-terrain preview](../terrain-preview.md)
- [Natural terrain roadmap](../terrain-roadmap.md)
- [SolHunter UI/UX roadmap](../ui-ux-roadmap.md)
- [Human Vastra activity foundation](../vastra-human-activity.md)
- [Vastra integration](../vastra-integration.md)
- [Natural Vastra replenishment and recovery](../vastra-natural-recovery.md)
- [Vastra particle lab](../vastra-particle-lab.md)
- [Vastra visual implementation roadmap](../vastra-visual-roadmap.md)
- [Woodland Vessel visual study](../vessel-visual-study.md)
- [Pixel-art water, banks, and player visibility](../water-and-visibility.md)
- [Water appearance and shoreline continuity](../water-appearance.md)
- [Weather and wind roadmap](../weather-roadmap.md)
- [Repeatable authored wildlife homes](../wild-population-recovery.md)
- [World and exploration delivery roadmap](../world-exploration-roadmap.md)
