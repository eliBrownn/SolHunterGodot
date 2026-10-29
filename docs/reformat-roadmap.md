# Project reformat roadmap

Prepared October 28, 2026. Owner-directed project-wide restructuring around the
approved hierarchical ownership and composition principle. This is an architecture,
content-organization and migration plan. Runtime execution and evidence are
recorded below; implementation does not close owner or target-device acceptance.

## Authority and intended result

[PROJECT_STANDARD.md](PROJECT_STANDARD.md) remains the sole organization/Git
standard. The [Bible](reference/SolHunter_Worldbuilding_Bible.md) governs design;
[mechanics-reference.md](mechanics-reference.md) governs non-generation evidence.
Godot retains world-generation authority. Preserve the owner's Bible edits,
untracked assets and other active work; leave third-party source assets in place.

Reformat the existing project into understandable domains with clear ownership,
reusable authored definitions and controlled local variation. Maintain one usable
connected expedition while migrating. Shared rules flow down relevant hierarchies;
independent systems connect through explicit references and owner interfaces.
Individual identity/affinity, ecology, rendering and UI retain distinct concerns.

This roadmap owns the structural migration sequence and its evidence index. The
[development plan](development-plan.md) owns broader delivery priorities. The
[terrain](terrain-roadmap.md), [Sol behavior](sol-behavior-roadmap.md),
[combat](combat-roadmap.md) and [UI/UX](ui-ux-roadmap.md) roadmaps retain feature
requirements and acceptance. Link their evidence instead of copying their tasks
or declaring their unfinished features complete during restructuring.

## Target framework

Use three kinds of data with distinct lifetimes:

| Kind | Contents and ownership |
| --- | --- |
| Authored definitions | Typed editable resources for palettes, asset contracts, templates and relevant system tuning. Stable keys, compatible elements, mandatory constraints, preferences, exceptions, required/optional children and budgets. Existing resources are the starting point. |
| Generated results | Stable ID, parent ID, definition/version reference, captured generation settings, resolved bounds/transforms, reservations and asset references. Rendering, collision and interaction consume the same admitted layout. Chunks deliver results without owning permanent locations. |
| Persistent changes | Mutable outcomes stored by the expedition/save authority against stable identities. Reconstruct unchanged generated defaults; keep cosmetic settings distinct from layout/identity-affecting settings. |

Keep hierarchy shallow where possible. A level exists to own a decision, rule or
budget. Children inherit relevant constraints and may narrow them; siblings share
the parent's available space and budget. Requirements such as access and valid
foundations must pass. Preferences such as symmetry or decoration density may
yield. Named exceptions override defaults at their owner without bypassing hard
invariants. Independent properties use references rather than extra ancestry.

For scenery, use the [approved composition hierarchy](terrain-roadmap.md#required-generation-hierarchy):
world, region, location/patch, zone, assembly, element, detail. Buildings and
vegetation are sibling branches. Plan/reserve broad spaces before details and
validate children/siblings before admitting a complete site. Bound searches and
retries; omit optional details or reject an optional site when requirements fail.
Shared planning resolves sites that cross boundaries. Independent chunks cannot
each approve overlapping placements. Required authored approaches remain safe.

Derive variation from saved seed, stable parent/child keys and purpose; unrelated
elements must not share a sequence whose order changes their results. Adding
detail must preserve parent layouts. Capture relevant settings and deliberately
version changed identity/footprint/route contracts. Current-format reliability and
clear incompatible-development-save rejection remain required; legacy migration
is outside this solo-development reformat.

## Ownership and organization map

These existing files are verified starting points, not claims that their current
responsibility boundaries already satisfy the target. R0/R1 resolve each actual
writer, reader and dependency once and maintain that record as changes occur.

| Domain | Existing starting points | Target responsibility |
| --- | --- | --- |
| World/geography | `scripts/world/terrain.gd`, `scripts/world/terrain_geography.gd` | Canonical ground, routes, geographic defaults and traversal queries |
| Scenery/structures | `scripts/scenery/nature_composition.gd`, `scripts/scenery/nature_patch.gd`, `scripts/scenery/nature_asset_entry.gd`, `scripts/scenery/structure_view.gd` | Definitions and admitted placement shared by visual, collision and interaction consumers |
| Expedition/persistence | `scripts/persistence/expedition_state.gd`, `scripts/persistence/save_store.gd` | Persistent outcomes, identity references, validation and save admission |
| Sols/ecology/progression | `scripts/sols/sol_species_catalog.gd`, `scripts/sols/sol_species_record.gd`, `scripts/sols/sol_ecology.gd`, `scripts/sols/sol_stats.gd` | Species content and focused policies; persistent records remain with expedition authority |
| Encounters/combat | `scripts/combat/encounter_controller.gd`, `scripts/combat/battle_controller.gd`, `scripts/combat/tactical_battle.gd` | Encounter orchestration and combat rules with explicit presentation/outcome boundaries |
| Presentation/streaming | `scripts/application/world_solid.gd`, `scripts/presentation/solid_chunk.gd`, `scripts/presentation/view_streaming.gd` | Consume admitted state/layout, publish/evict visual nodes and bound rendering work |
| UI/input | `scripts/ui/field_menu.gd`, `scripts/ui/menu_theme.gd`, `scripts/ui/controller_input.gd`, `scripts/ui/sol_menu.gd` | Shared visual/input patterns and owner-issued actions; no duplicate simulation state |
| Story | `scripts/story/story_director.gd`, `scripts/story/story_ledger.gd` | Authored sequence orchestration and facts through existing persistence contracts |
| Application assembly | `scripts/application/world.gd`, `scripts/application/world_plane.gd`, `scenes/world_3d.tscn` | Wire owners and views; delegate focused responsibilities instead of accumulating unrelated rules |

Retain the standard's top-level folders. Group owned code/content by feature when
it makes responsibility clearer. Candidate script groups are world, scenery,
persistence, sols, combat, presentation, ui and story; R1 records actual destination
paths before moving files. Existing useful groups such as species resources stay
intact. Shared helpers require demonstrated shared use and an explicit owner.
Do not create empty groups or move assets merely to make the tree symmetrical.

Move a domain once after stabilizing its boundary, updating script/resource/scene
references, UID sidecars, validator paths and documentation in the same change.
Use Godot-aware moves per the standard. Separate mechanical relocation from rule
changes in reviewable changes; do not leave both paths as independent active
implementations. A temporary forwarding adapter needs one owner and a removal
phase. Keep public resource IDs stable where possible; save admission rules apply
when persistent contracts change.

## Phases and dependencies

R0 → R1 → R2 → R3 → R4 → R5 → R6 → R7 → R8 is the default order. Finish the
scenery proof before widening adoption. Later domain work may reuse a completed
contract; it must not reopen completed phases without an identified dependency
change. No calendar estimates until the first implementation slice is measured.

| Phase | Deliverable | Exit evidence | Status |
| --- | --- | --- | --- |
| R0 | Current baseline and one ownership/dependency/evidence inventory | Known state, missing evidence and affected seams recorded | Desktop baseline recorded; E0 |
| R1 | Minimal contracts and migration map | Owners, data lifetimes, paths and check selection agreed in the implementation change | Implemented map/contracts; E1 |
| R2 | Working hierarchical scenery proof | One woodland approach/site satisfies placement, reconstruction and cost checks | Corrected placement and matched desktop cost recorded; E2R / final desktop evidence |
| R3 | World and presentation separation | Normal expedition consumes admitted layout consistently | Implemented and checked; E3 |
| R4 | Sol, ecology and progression organization | Identity/state continuity and focused domain journey preserved | Implemented and checked; E4 |
| R5 | Encounter/combat organization | Existing encounter-to-outcome flow preserved with one outcome writer | Implemented and checked; E5 |
| R6 | UI/input/story organization | Existing controls, previews, pause and authored facts remain coherent | Implemented and checked; E6 |
| R7 | Dependency and documentation closure | Superseded paths/adapters removed; ownership index matches actual code | Implemented and checked; E7 |
| R8 | Integrated acceptance | Combined checks and representative desktop/device evidence recorded | Desktop checks recorded; baseline native crash and owner/device acceptance open |

### R0 — Establish the baseline once

Inspect current branch/status, active changes, owner files and dependency seams.
Reuse the map above and existing feature evidence; record gaps rather than doing
a second full audit. Capture revision plus dirty-tree fingerprint, engine,
generation/save versions and relevant settings. Historical logs such as the
[playable baseline](current-playable-baseline.md) need matching inputs before reuse.

Establish missing baseline evidence once: the connected travel/observation/
encounter/combat/save-load journey and representative desktop cost. Use existing
fixtures/profilers. Record known failures and their scopes separately; do not
rediscover them at every phase. Missing device budgets remain explicit. A baseline
failure in a contract being migrated must be addressed or isolated with evidence
before that contract's phase can pass.

### R1 — Define contracts and the move map

For each affected fact, record owner, permitted writer, readers, lifetime and
dependency inputs. Keep this in the map/evidence index here, extending rows only
as needed. Identify duplicate responsibility and select the existing implementation
to retain. Define only the resource/result/state contracts needed for R2; extend
existing classes before inventing a universal hierarchy class or registry.

Specify parent-rule resolution, mandatory/preferred constraints, stable identities,
shared reservations/budgets, rejection behavior and named exceptions. Plan exact
source/destination paths and incoming references for the first domain. Identify
the existing checks covering each contract and genuinely missing coverage. Add a
small development-only report for ownership, reservations and rejection reasons
when implementing the proof; keep implementation diagnostics out of player flows.

### R2 — Prove scenery and secondary-location composition

Build one connected woodland approach and one small secondary-site template with
existing assets and only necessary layout placeholders. Choose the site's purpose
and architectural style during authoring without inventing new mechanics/canon.
Keep authored settlements, important routes and story landmarks intentionally
composed. Extend the current bounded nature contracts into a complete admitted
site consumed by rendering, collision and interaction; include save behavior for
any supported persistent changes. Keep incomplete candidate results unpublished.

Demonstrate several distinct seeds, unsuitable-site rejection, sibling budgets/
overlap handling, grounded structures, usable entrances, readable Sol/encounter
space and safe travel. Exercise a streaming-boundary site, changed loading order,
eviction/rebuild and save/load. A decoration-only change must preserve building
and parent layouts. Measure relevant streaming/rendering cost against R0's matched
workload. Do not expand the library or global rollout before this proof passes.

### R3 — Migrate world composition and presentation

Route normal expedition composition through the proven ownership boundaries.
Separate location planning, terrain queries, geometry publication and application
wiring. Persistent locations span chunks; streaming consumes and evicts derived
results without changing saved identity or layout. Preserve height, slope, water,
foundation, picking and traversal authorities. Consolidate duplicated placement
calculations only after identifying their canonical owner. Verify the changed
world/presentation seams with existing terrain/building/journey coverage, reusing
R2 results where the exercised code and inputs remain unchanged.

### R4 — Migrate Sols, ecology and progression

Organize species definitions, individual records, behavior policies, movement,
owned companions and progression around their existing owners. Keep species,
individual affinity and persistent identity independent. Views reference the same
individual in world, party, storage and previews; they do not create new copies of
its authoritative state. Ecology reads geography without inheriting rendering
chunk lifetimes. Remove duplicate configuration/state only where verified; reuse
existing catalog, behavior and integrated ownership/save checks. Reuse recorded
mechanics evidence for unchanged rules; consult the source for actual unresolved
behavior questions before altering rules.

### R5 — Migrate encounters and combat

Keep encounter orchestration, deterministic battle decisions, presentation and
persistent resolution as focused responsibilities. Establish one authoritative
resolution path so a repeated view event cannot apply an outcome twice. Reuse
current settings and mechanics contracts; extract duplicated rules into their
existing owner. Exercise the affected encounter/deployment/action/resolution/save
seams with current fixtures. Structural changes do not retune balance or reopen
settled mechanics.

### R6 — Migrate UI, input and story wiring

Consolidate genuinely shared menu/theme/preview/input patterns; retain screen-
specific behavior where it belongs. UI sends actions to owners and displays their
state. Story orchestration records facts through the existing ledger/save owner;
it does not duplicate progression. Preserve desktop controls, controller support,
live-menu versus pause behavior and preview identity. Use the existing connected
input/menu/story fixtures for changed seams; implement no new prologue content as
a side effect of moving its wiring.

### R7 — Close paths, adapters and documentation

This closes work done with each domain; it is not another full relocation pass.
Remove temporary adapters after their consumers switch, stale active paths,
duplicate tuning, orphan references and obsolete test entry points. Update the
ownership/move map, Inspector map and affected guides. Keep historical evidence
labeled and canon intact. Verify imports, UIDs, paths and dependency direction.
Retain justified comparison scenes only with a clear purpose and owner; remove
superseded tracked code only through reviewed changes, preserving unrelated work.

### R8 — Accept the integrated project

Run the current configured shared validator and one representative connected
expedition covering travel, Sol observation/companionship, encounter, combat,
menus and persistence. Include new-expedition admission, pause and incompatible
load handling. Reuse earlier valid focused evidence; rerun affected boundaries
changed since those results. Compare matched desktop travel, streaming, startup,
combat and menu costs, with memory/instrumentation limits stated. Target-device
acceptance requires an actual AYN Thor export and usability/performance evidence;
desktop completion may be recorded separately while device acceptance stays open.

Exit requires coherent ownership, no competing active writers/implementations,
valid references, connected behavior retained and owner review of the playable
result. Do not close feature or device gates merely because folders are organized.

## Validation and evidence reuse

Maintain one evidence index below. Store large logs/captures in ignored artifacts;
link the exact evidence rather than producing a new report per phase. A completed
phase references the contracts and evidence it relies on. One check can satisfy
multiple phases. Use existing fixtures; add coverage only for a new invariant,
uncovered seam or actual regression, without copying implementation values into tests.

| Change | Appropriate verification |
| --- | --- |
| Documentation only | Changed links/anchors/paths, consistency, whitespace and scoped diff |
| Relocation with unchanged logic | Reference/UID/path checks, engine import and the affected entry-point smoke check |
| Local definition or presentation edit | Existing focused admission check and one useful render when visible |
| Ownership/interface or layout/state contract | Owner checks plus changed consumers; reconstruction/save/travel checks when affected |
| Rendering/streaming cost change | Matched rendered workload; preserve hardware, renderer, viewport and settings in evidence |
| Shared contract change or final integration | Broaden to affected domains and the shared validator as warranted; final R8 runs the configured validator |

Evidence reuse depends on relevant code/resource hashes, transitive dependencies,
fixture/tool version and inputs. Record revision/dirty fingerprint for traceability;
an unrelated commit alone need not invalidate a focused result. Engine changes
invalidate engine-sensitive results; rendering/performance evidence also depends
on hardware, driver, renderer, viewport, settings and workload. If a dependency is
unknown, resolve it once or rerun the relevant check; do not assume validity.

After failure, retain the result and rerun the affected checks after a relevant
fix. After a pass, repeat only for changed dependencies, a new failure or an
unresolved concern. Configured CI remains mandatory; local evidence reuse must not
disable, weaken or claim to replace those checks. No repeated whole-project suite
at every small content edit, and no repeated source lookup for an unchanged rule
already settled by recorded evidence.

## Execution ownership and migration map

Execution started October 28, 2026 on `codex/restructure` at `7d3731a`.
The initial dirty tree, patch and per-file hashes are preserved in
`artifacts/reformat/initial-status.txt`, `initial.patch` and `baseline-source.json`.
The existing Bible, story, documentation changes and withheld player/sky assets
remain owner work. No third-party source redistribution permission is inferred.

| Fact / lifetime | Sole writer / owner | Readers and dependency inputs |
| --- | --- | --- |
| Terrain, routes, height and site admission / generated | `WorldTerrain`, geography and authored structure/site planners | Streaming, traversal, ecology and picking read the same seed, generation version, climate, relief and captured scenery parameters. A render chunk cannot approve a site. |
| Required observation spaces / authored and captured | `SceneryRequiredSpaces`, `resources/scenery/required_spaces.tres` | One data-only owner supplies anchors/radius to nature dressing and absolute captured reservations to new site planning. Visual resources and species rules are not planner dependencies. |
| Woodland site / generated | `ScenerySiteTemplate.plan`, called once during terrain construction | One region owns the absolute location; building plot, approach and clearing reserve space before vegetation. Required supports/roof share the location budget; optional trim yields first. No named exceptions currently apply. Ground, water and essential access are mandatory. |
| Site publication / derived | `SolidChunk.add_site`, wired by the solid world view | Consumes admitted absolute transforms and stable site/module IDs. Rendering and picking use those exact transforms. Terrain consumes the admitted support cells for collision; the open central space and approach remain traversable. Full rebuild cannot reroll the site. |
| Persistent individuals, ownership, progression, outcomes and story facts / saved | `ExpeditionState` owner methods | Catalog/ecology/policies supply definitions; views, menus and controllers read copies or request actions. Species, affinity and identity remain independent. No external writes to private individual/battle storage were found. |
| Battle session / transient | `TacticalBattle`; orchestration by encounter/battle controllers | Playback/HUD consume session events. `ExpeditionState.complete_battle` remains the single transactional outcome writer, guarded by active serial; existing replay/retry tests cover duplicate events. |
| Save envelope / saved | `ExpeditionSave` admission and atomic file replacement | Captures generation inputs; world assembly restores admitted terrain before publishing. Generation 9 / save format 4 capture scenery parameters and required clearing bounds. World state remains version 17. Incompatible development envelopes are rejected without overwriting them. |
| Local input, menu layout and camera / presentation | Existing controller/menu preference owners | UI issues owner actions. Live R menu, true pause, preview identity and desktop/controller bindings retain their existing contracts. Story director records through the ledger/state owner. |
| Shared resource-field/cache helpers / derived | Existing core helpers | Multiple resource, scenery, ecology and streaming readers demonstrate shared use. They own no gameplay facts. |

The following exact move map groups existing scripts after their boundary is
verified. Every listed stem moves from `scripts/<stem>.gd` to the listed directory
with its existing `.gd.uid`. Incoming references include scripts, scenes, resources,
tests, tools and current guides. Authored resource groups and third-party assets
stay in place. Relocation preserves logic and UIDs; it is a separate change from
the scenery contract. There are no forwarding adapters.

<!-- reformat-move-map:start -->
| Destination under `scripts/` | Script stems |
| --- | --- |
| application | world, world_plane, world_solid |
| world | terrain, terrain_geography, terrain_heightfield, terrain_relief_settings, climate_settings, expedition_settings, explorer |
| scenery | authored_structures, scenery_site_template, scenery_required_spaces, nature_art, nature_asset_entry, nature_composition, nature_patch, nature_settings, structure_view |
| persistence | expedition_contract, expedition_state, save_store |
| sols | sol_species, sol_species_record, sol_species_catalog, sol_catalog_sighting, sol_identity, sol_ecology, sol_ecology_profile, sol_behavior_definition, sol_behavior_library, sol_reaction_policy, sol_roaming_policy, sol_traversal_policy, sol_traversal_profile, sol_local_navigation, sol_ground_motion, sol_motion_track, sol_stats, sol_stat_settings, class_buff_definition, class_buff_settings, collection_progress, progression_settings, owned_companion_policy, owned_companion_traversal, owned_companion_settings, wild_population, wild_recovery_settings, vastra_settings, human_vastra_activity, vastra_natural, sighting_settings |
| sols/presentation | actor_billboard, authored_sightings, owned_companion, wild_recovery_controller, sol_creature, sol_orb, sol_model_parts, sol_prototype_creature, sol_species_view, sol_visual_settings, sol_ashquill, sol_bitterfrill, sol_browguard, sol_claspback, sol_foldling, sol_glass_throat, sol_kilnling, sol_knucklemole, sol_mournveil, sol_pebblewyrm, sol_rattlehorn, sol_rimefold, sol_sailcrest, sol_shadepelt, sol_thimblehart |
| combat | encounter_controller, encounter_settings, battle_controller, tactical_battle, battle_class_passives, battle_commander, battle_feedback, battle_pacing_measurement, battle_playback, battle_profile, battle_progress, battle_settings, combat_pacing_fixture, move_library, move_loadout, sol_move, affinity_imprint, vastra_combat |
| presentation | solid_chunk, stream_chunk_job, streaming_ground, view_streaming, view_3d_settings, terrain_chunk, terrain_ray, mesh_picking, pack_art, player_model, player_visibility, affinity_ground, vastra_currents, atmosphere_controller, atmosphere_settings, water_appearance_settings |
| ui | expedition_hud, field_menu, menu_theme, menu_settings, hud_accessibility, inspection_card, mouse_confirmation, ui_text, controller_focus, controller_input, controller_settings, controller_window_input, combat_hud, sol_menu, sol_details, sol_model_preview |
| story | story_director, story_ledger, story_event, story_choice |
| development | cohesive_world_sample, terrain_preview, terrain_study_mesh, sol_model_workshop, sol_traversal_review, story_workshop |
| core | record_shape, derived_cache_window, resource_storage_fields, runtime_validation_cache |
<!-- reformat-move-map:end -->

Retain the existing 2D/plane comparison scenes as regression consumers of the
same expedition owner. Development/workshop scripts remain explicit authoring
tools, with no automatic campaign activation. No shared UI framework or new
mechanics registry is introduced merely for directory symmetry.

## Execution and evidence index

Planning delivery: roadmap created and linked from the standard, development plan,
terrain roadmap and README. Runtime completion is tracked in the phase table.

| Evidence | Phase / scope and inputs | Result and invalidation |
| --- | --- | --- |
| E0 | R0, baseline `7d3731a` plus original dirty fingerprint in `artifacts/reformat/baseline-source.json`; pinned Godot `4.7.2.stable.official.ed1daf0bf`. R0 capped-render manifest/hardware/settings and exact hashes: `artifacts/current_expedition/reformat-r0/manifest.json`, `cap60-run1/source_before.json`, `cap60-run1/profile.json`. | Capped normal-input journey passed, including save/new/load and incompatible admission. Smoke 2,389, generation 127/11 seeds, building 776 and persistence 76 passed in `artifacts/reformat/baseline-validation-local.log`. Full baseline stopped at one stale v1-migration assertion in human Vastra; isolate/update that obsolete fixture in persistence scope. Initial restricted settings-write failure is retained in `baseline-validation.log`; normal-access import passed. Do not reuse these baseline results as final-tree evidence. R0 uncapped sample is excluded: unrelated new proof files and brief headless probing overlapped that run. |
| E1 | R1, owner/lifetime/reader table and exact move map above; existing mechanics evidence is unchanged. | No duplicate individual/battle writer found outside expedition state. Existing terminal-serial/retry checks in first-playable battle, AI/Seals and combat consequences already cover outcome replay; reuse them rather than add another outcome writer/test. World state stays version 17; initial captured layout used generation 8/save 4; E2R advances generation to 9 to preserve required clearings. Invalidated by owner/interface or definition schema changes. |
| E2 | R2, open timber woodland shelter, existing primitive scenery assets, stable site/module IDs, shared required/optional budget and absolute access reservations. `artifacts/reformat/site-rendered-final.log`, `site-buildings.log`, `site-journey.log`, `generation8/woodland-site.png`. Matched capped cost: `artifacts/current_expedition/reformat-r2/cap60-run1/profile.json` and source/hardware manifest. | 220 site checks, 776 existing building checks and 2,506 existing 3D journey checks passed. Eight seeds exercised: three admitted woodland sites, five safely omitted unsuitable sites; includes a cross-chunk result, reverse chunk visitation, visual rebuild, exact save reconstruction, malformed/incompatible admission and detail-independent required modules. Render inspected. New-expedition 1,359.918 → 1,353.153 ms; load 1,453.315 → 1,438.907 ms; outbound p95 20.206 → 16.848 ms; peak draw calls 2,396 → 2,393. Historical generation-8 placement/cost evidence: final review found the site overlapped the existing woodland clearing. E2R corrects this missed invariant; generation-9 placement and cost require fresh evidence. No statistical speedup or device acceptance is implied. |
| E3 | R3, scenery proof `4b5fcf9`, resolved cabin owner `b39da63`, reference-only domain move `db79d69`. Exact 37-script pre/post logic and UID equivalence: `artifacts/reformat/moves-application-core-presentation-scenery-world.json`. | Cabin renderer now consumes terrain's resolved modules, retaining all previous transforms/footprints. Rendered building 778, site 220 and terrain integration 3,565 checks passed (`r3-buildings.log`, `r3-sites.log`, `r3-terrain.log`). Post-move import, bounded nature 1,680 and 3D journey 2,506 checks passed (`r3-relocation-*.log`). No adapters or parallel implementations. Persistent/consumer changes require their affected checks again at final integration. |
| E4 | R4, current-only state restoration `9afb181`, Sol/persistence move `35a2c46`. Exact 58-script logic/UID equivalence: `artifacts/reformat/moves-persistence-sols-sols_presentation.json`. Existing species, ecology, progression, owned-traversal and individual-affinity owners retained. | Fourteen focused suites passed in `artifacts/reformat/r4-*.log`: human Vastra 80, natural 93, observation 38, wandering 71, stats/classes 3,686, recovery 54, first battle 60, AI/Seals 78, Sol journey 243, outcome/retry 64, story/connected 32, local reactions 51, persistence 76 and affinity 100. Replaced obsolete upgrade fixtures with current reconstruction and incompatible-state rejection. Removed unreachable old-state migrations; current version-17 normalization/rules remain unchanged. Post-move import and Sol journey 243 passed. Current-format persistence and affected consumers are dependencies for final integration. |
| E5 | R5, combat move `1050b1d`; exact 18-script logic/UID equivalence in `artifacts/reformat/moves-combat.json`. | Import and 60-check encounter/deployment/outcome journey passed (`r5-import.log`, `r5-journey.log`). Reuse E4's serial/replay/retry tests: no combat rule or balance change, new outcome path or duplicate writer. Final shared validation covers cross-domain integration. |
| E6 | R6, HUD extraction `3a2b747`, UI/story/authoring move `2ac4415`; exact 26-script logic/UID equivalence in `artifacts/reformat/moves-development-story-ui.json`. | Shared label/panel/HUD construction belongs to `ExpeditionHud`; world assembly delegates its construction and retains pause/new-expedition actions. Story still records through `ExpeditionState`/`StoryLedger`. Import, 32 connected/story checks, 58 controller and 29 live-menu/window checks passed (`r6-*.log`). Final integration covers actual rendered menus and previews. |
| E7 | R7, all 142 script paths and original UID sidecars match the map. `tools/check_script_ownership.py` verifies map coverage, unique UIDs and literal consumer paths. | No root script duplicates or temporary path adapters remain. Removed the unused hidden journal panel; encounter coverage and journal captures now use the actual Guide menu. Encounter 26 and observation 38 checks passed (`r7-encounter.log`, `r7-observation.log`). Region identity reads geography's region size rather than repeating that authority. Current Inspector map and organization standard updated; original feature-slice records explicitly label their old controls/schema/migration evidence as historical. Final import and shared validation are recorded under R8. |
| E2R | R2 reopened for a verified missing dependency: existing authored observation/encounter clearings. `SceneryRequiredSpaces` owns their anchors/radius; new-expedition site settings capture the source seed and absolute required bounds. Generation 9 deliberately rejects the previous placement contract. | Corrected admission skips every overlapping building/reservation candidate. Eight seeds still exercise three admitted sites and unsuitable omission; the default site's search now reaches candidate 13 outside the required woodland clearing. 226 site checks, 1,640 nature checks and 3,565 terrain checks passed (`clearing-proof.log`, `clearing-rendered.log`, `clearing-nature.log`, `clearing-terrain.log`); entrance and normal-view captures inspected. Added coverage for blocked required spaces, save capture and reconstruction independent of current authoring defaults. Earlier generation-8 placement/cost claims are superseded. The first R8 validator was intentionally interrupted when this uncovered invariant was identified (`r8-interruption.txt`); its partial passes are not a full result. Final combined validation and generation-9 cost follow under R8. |
| E8R | Final-validation repairs; failed and diagnostic results remain in `artifacts/reformat/preflight-results.json`, `fixed-results.json` and the earlier R8 log directories. | Fixed an unbound-world catalog fixture by exercising its existing authoring builder; updated obsolete orb/material assertions without changing game presentation. Native shutdown failures prompted dependency isolation: the planner consumes the terrain-query interface and loads its definition after script registration. Required spaces now live in one data-only shared resource, so site planning does not load nature art or species validation resources. Three consecutive class runs (203 checks each), anatomy 423, site 226 and nature 1,640 checks exited cleanly after this correction; failed lifetime experiments were reverted. This is observed evidence, not a proven native stack diagnosis. Model fixtures use presentation interfaces/runtime resources and release their sky cleanly. Verified clean exits and zero engine/script errors: catalog 243, class coverage 203, companion 40, interaction 32, atmosphere 33 and site 226 (`verified-*.log`). Rendered lighting passed 37 checks with projected samples of the same camp ground, replacing obsolete fixed pixels; day luminance 0.50261 versus night 0.17147 (`final-atmosphere-rendered.log`). The evidence wrapper now reads plain .NET log strings, preventing PowerShell provider metadata from expanding JSON serialization; the reproduced summary is bounded at 1,379 characters. These repairs require the final configured validator; partial runs are not relabeled as passing. |

Owner response during execution: complete desktop work and leave actual AYN Thor
acceptance open. Numeric device budgets, physical-controller usability, export
and owner playable review are not established by automated desktop checks.

The optional `Cost` phase of `tools/review_expedition_integration.ps1` reuses the
existing connected journey and adds 90-frame live Sol-menu and active-battle
windows. `tools/review_reformat_cost.gd` is the same measurement fixture in the
preserved baseline checkout (`artifacts/reformat/baseline_checkout`, detached at
`7d3731a`) and final project. That ignored comparison checkout contains local
copies of the same withheld assets for measurement, not a second active game
implementation or redistributable build. It is retained as reproducibility
evidence. The standard validator/CI checks are not replaced by the cost study.

For each completed change, add one row with phase/contract, owner and dependency
scope, revision/dirty fingerprint, input/environment manifest, reused or new check,
result/log and invalidation triggers. Reference the same row from dependent phases.
Use this table as the single execution evidence index; artifact logs are ignored.

Follow the standard's `codex/` branches, explicit-path staging, scoped review and
owner-controlled integration. Plan one coherent ownership change per review;
preserve unrelated files and avoid combining relocation, new features and balance
changes. Update phase status and this index in the implementing change. If a phase
regresses its boundary, fix it or revert that focused change through normal Git
history while preserving other work. Do not merge, force-push or delete branches
as part of executing this roadmap.

### R8 native shutdown blocker

The configured validator at `artifacts/integration_readiness/reformat-r8-spaces/Validate/manifest.json` exited 1 after class coverage printed 203 checks / zero failures. Its source fingerprint did not change and no script/engine error text was suppressed. This is a failed run, not full acceptance. Windows records native access violation `0xc0000005` at engine offset `0x547f2c`.

Isolation used detached baseline `7d3731a`, the same local assets, the same pinned engine and the original canonical `tests/sol_class_coverage.gd`: four of five baseline processes crashed after assertions; two of five restructured processes crashed with that identical fixture (`artifacts/reformat/baseline-original-*.log`, `current-original-*.log`). The fixture is restored exactly to baseline; speculative lifetime changes are not retained. This establishes an existing baseline blocker, not a native root-cause diagnosis. Do not retry until green, ignore nonzero exits, or upgrade the pinned engine as part of this structural change. R8 remains open until this native failure and owner playable acceptance are resolved. Remaining configured cases and rendered cost evidence are recorded separately below. Thor acceptance is explicitly deferred by the owner.

### Final desktop evidence

After the configured validator stopped at the native class-test failure, all 41 remaining configured commands were executed sequentially with their original arguments: 46,740 assertions, zero assertion failures, zero engine/script error messages and every process exit zero (`artifacts/reformat/final-tail/results.json`). This includes `full_3d`, `view_3d`, scenery/nature, terrain, menus/controllers, combat outcomes and the solid-3D save/load smoke journey. It is diagnostic continuation, not a replacement for the failed configured-validator gate. The unchanged original class fixture was separately checked in the baseline/current matrix above.

The first baseline connected-cost attempt exposed a review-driver AP assumption (`reformat-baseline-cost`): movement and a direct move may leave too few action points for Current or a Seal. The shared review driver now uses the actual End turn button when that budget is exhausted; it does not edit AP, HP, loadouts, terrain or capture rolls. The identical corrected driver is used in baseline/final comparison; the failed first attempt is retained and excluded.

The intermediate generation-9 rendered connected-cost runs (before final dependency closure) both exited zero with no engine/script errors or source changes: baseline `artifacts/reformat/baseline_checkout/artifacts/integration_readiness/reformat-baseline-cost-ap/Cost/manifest.json` and final `artifacts/integration_readiness/reformat-final-cost/Cost/manifest.json`. Each passed all 34 connected checks plus the inherited travel/save/load checks. Both used Godot 4.7.2, D3D12 Forward+, 2560 x 1369, VSync and a 60 FPS cap, the same local assets, seed, settings, original opponents and normal game actions. The retained source/environment manifests include the background editor and exact instrumentation. Final battle-action and restored-world captures were inspected; no visible layout/UI regression was found in these views.

| Single desktop sample | Baseline | Restructured |
| --- | ---: | ---: |
| Initial scene build (ms) | 3071.041 | 3303.401 |
| New expedition (ms) | 1381.806 | 1442.501 |
| Load (ms) | 1499.946 | 1539.176 |
| Outbound frame p95 (ms) | 19.351 | 20.453 |
| Sol menu open CPU (ms) | 12.285 | 12.156 |
| Live menu frame p95 (ms) | 16.764 | 16.708 |
| Peak draw calls | 2537 | 2533 |
| Engine static memory peak (MiB) | 316.993 | 317.18 |
| Sampled process working-set peak (MiB) | 1019.918 | 1019.738 |

Active battle frame p95 for the three matched 90-frame windows: 16.725, 16.692, 16.803 ms baseline; 16.689, 16.752, 16.716 ms final. Outbound routes were 78 steps in both runs. Startup/new/load and outbound p95 were higher in this sample; menu and battle frame windows stayed near the 60 FPS cap. These are one-run observations, not statistical regression bounds or a speedup claim. Approach/deployment wall times include real travel/playback and are retained in profiles rather than presented as pure combat CPU costs. Engine static/process working-set measurements are not GPU memory. Numeric budgets, owner feel review, an export and Thor qualification remain open.

### R8 project dependency correction

Owner follow-up asked to investigate the class fixture first. A predetermined seven-variant matrix showed that removing timeout, board, frame wait or using deferred exit did not eliminate the crash. A five-line catalog-only reproduction still failed, while a bare SceneTree exited cleanly. Dependency isolation then reproduced the failure by preloading `SolSpeciesRecord` alone; its creature scene, move library, behavior library and class settings each exited cleanly in five runs (`artifacts/reformat/class-isolation/results.json`, `dependency-results.json`; the view-script variant had a parse error and supplies no native evidence).

The species/affinity validation path referenced `ExpeditionState.keys_match`, pulling persistence and its dependent domain scripts back into otherwise local resource admission. `RecordShape` now solely owns the exact same dictionary-key check. Persistence and eleven other consumers call it directly. `extraction-audit.json` verifies the helper body is unchanged and all consumer edits only change that helper owner; no gameplay/schema/data rules changed. The original canonical class fixture is retained. The planned post-change matrix exited zero in all 25 runs: species preload 5, catalog preload 5, full class fixture 10 (203 checks each), anatomy 5 (423 each), with no script/engine errors (`key-owner-results.json`). This identifies a project dependency trigger; it is not a symbolized diagnosis of the native engine fault. A fresh configured run and refreshed final cost sample follow; earlier failed runs remain preserved.

### R8 remaining dependency closure

The post-RecordShape configured run (`reformat-r8-record-owner/Validate`) stopped on a native exit after all 54 wild-recovery assertions, with no source changes or script errors. Reduced persistence loads passed five runs each; the unchanged wild fixture failed two of five. Cleanup variants were not reliable: clearing sky and queued deletion separately each passed five, but their combination still crashed once (`remaining-dependency-results.json`, `wild-cleanup-results.json`). No speculative wild-test cleanup changes are retained.

The lexical script-reference audit identified four remaining strongly connected groups (persistence 6 scripts, story 3, structures/terrain 2, battle/passives 2). Six shared bounds/clock constants now have one pure `ExpeditionContract` owner; existing consumers refer to those unchanged values directly. Story ledger admission consumes a Resource event interface; battle passives preserve their WeakRef and consume the battle interface; cabin admission reads the supplied terrain enum. These break the back-references without duplicating mutable state or changing gameplay/schema values. `script-dependency-cycles.json` and `closed-script-dependency-cycles.json` record the groups before/after; the latter reports none across 142 scripts. This is a lexical audit, not a claim to resolve every dynamic resource dependency.

The first cycle-closure diagnostic matrix completed five class runs, then exceeded its per-process limit on the first wild case and aborted; it is not a successful result. Original line endings were restored during that diagnostic attempt. Subsequent checks use frozen source and record every exit, timeout and error (`frozen-cycle-results.json`). A final configured gate and refreshed rendered cost sample are still required.
