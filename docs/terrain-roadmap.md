# Natural terrain roadmap

Prepared October 27, 2026. Status: Rolling integrated into the default 3D game
after the owner's instruction to continue. See [implementation evidence](natural-terrain.md).
Owner playtesting and target-device acceptance remain open.
Plan audited against the working tree, validation artifacts and Bible vision
October 28, 2026. This audit changes planning/documentation only; it does not
establish a new passing game build or owner acceptance.
Owner clarification October 27, 2026: current development saves are disposable;
retain the save framework without implementing backward compatibility.

Execution evidence, October 28: the [current playable baseline](current-playable-baseline.md)
records six fresh rendered journeys with normal AI, a focused guard encounter,
current save/load checks, performance measurements and validation blockers.
Concurrent source changes limit matched-run comparisons; this does not close
owner acceptance, performance budgets or the broader T5 workload.

## Intended result

Owner-approved October 28 focus: contribute to one cohesive refuge-to-wilderness
expedition, with comfortable traversal, readable destinations and scenery that
shares the game's visual identity. Review terrain with Sol encounters, interface
and combat before expanding geography. Measure relevant travel/streaming and
rendering regressions throughout implementation toward AYN Thor release; desktop
results alone do not close device acceptance. See the
[approved development focus](development-plan.md#approved-focus--october-28-2026).

Replace the flat landscape with gentle rolling ground: broad low hills, shallow
valleys, comfortable paths, occasional low rises, and believable pond banks.
The landscape should feel natural at walking height without extreme mountains,
constant climbing, or terrain that hides every destination. Preserve the Bible's
authored places, procedural wilderness, seamless exploration, and safe essential
travel. This is a feature roadmap under [the project standard](PROJECT_STANDARD.md),
not a replacement design or organization standard.

Initial slice: one refuge-to-waystone journey with a meadow
rise, a shallow wooded valley, and a pond depression. Review it at player scale
before expanding geography. Larger river systems are a later milestone.

## Approved procedural scenery direction — October 28, 2026

Owner clarification and approval: procedural generation should extend to trees,
buildings and secondary locations, using authored assets, reusable templates and
explicit composition standards. The goal is varied places that look deliberately
composed. This approves the direction; the implementation sequence below is a
proposal, not evidence of a completed system or approval of new gameplay rules.

Preserve the Bible's authored settlements, landmarks, important routes and story
locations. Their identity, required layout and narrative composition remain
authored; procedural surroundings and compatible detail can provide variation.
Secondary wilderness sites may use authored templates with generated layouts.
This develops the existing Godot generation engine and T4a placement contracts.

| Layer | Authored standards | Generated variation |
| --- | --- | --- |
| Trees and vegetation | Habitat-compatible palettes, size/spacing ranges, ground and slope suitability, clearings and visual bounds | Groves, woodland edges, understory and individual transforms |
| Buildings | Architectural families, compatible modules, dimensions, ground pivots, foundations, entrances and access clearance | Compatible assemblies, orientation and restrained decoration |
| Secondary locations | Site purpose, required/optional elements, spatial relationships, usable spaces, approaches and exclusions | Bounded layout, scale, surroundings and secondary details |
| Regional scenery | Shared materials, silhouettes, palette and density character | Composition adapted to existing habitat, relief and water |

### Required generation hierarchy

This specializes the approved [game-wide ownership principle](PROJECT_STANDARD.md#hierarchical-ownership-and-composition).
See the [project reformat roadmap](reformat-roadmap.md) for owner boundaries,
authored/generated/saved data contracts, delivery sequence and validation reuse.

Owner follow-up: maintain a hierarchy throughout procedural scenery authoring,
generation and validation. Compose from broad context to individual detail;
buildings and vegetation are sibling branches within that hierarchy.

| Level | Owns and constrains |
| --- | --- |
| World | Shared generation contracts, authored anchors and essential connectivity |
| Region | Scenery character, compatible palettes/materials, broad composition and density limits |
| Location or landscape patch | Site/template identity, footprint, approaches, required spaces and exclusions; a wilderness patch need not contain a building |
| Zone | Functional subdivisions such as an approach, building plot, grove, clearing or bank, with their reserved space |
| Assembly | A compatible building assembly, tree group, rock formation or other composed group |
| Element | Building modules, individual trees, rocks and other placed assets with explicit bounds and support requirements |
| Detail | Admitted decoration and small variation within the space and limits left by the parent |

Each child inherits its parent's allowed palette, footprint, access reservations,
density and performance limits, and may narrow them. Siblings share their parent's
available space and budget; each cannot independently consume the full allowance.
Local variation must not relax an ancestor's hard constraints. Represent deliberate
authored exceptions explicitly at the owning level and revalidate affected parents.
Required levels are ownership concepts; an empty level needs no generated objects.

Plan and reserve space from parent to child, then validate completed children
against their parent and siblings. Retry or omit an optional child within bounded
limits when it cannot fit; reject an optional site if a required child fails.
Required authored places retain their guaranteed access. Keep stable parent/child
identities and independently derived variation so adding decoration cannot reroll
the site's buildings or neighboring sites. Render chunks only stream the results;
they do not own location layouts. This composition hierarchy reads existing
geography and habitat data without creating a second ecology/territory authority.

Select a suitable site, reserve its required spaces and access, fit structures and
paths, then place vegetation and decoration around them. Use final terrain and
transformed bounds to prevent floating foundations, overlapping buildings,
buried entrances and tree crowns
blocking required views. Keep encounter/observation space and player/Sol movement
readable. Decoration must agree with actual collision and picking.

Templates should have bounded candidate searches and explicit rejection when
required elements cannot fit. Optional sites may be omitted; authored essential
access must remain guaranteed. Generate stable site identities and results from
saved seed/settings and absolute geography, independent of chunk loading order.
Store any layout-affecting settings and version changes that alter routes,
building footprints, blockers or persistent site identity. Cosmetic dressing
continues to follow T4a's separate reconstruction contract.

Proposed first proof: one connected woodland approach and one small secondary
site, using existing assets where suitable and minimal layout placeholders where
necessary. Review several seeds at walking height, including an unsuitable site
that is rejected, chunk eviction/rebuild and save/load. Inspect parent/child
ownership, inherited constraints and shared budgets; changing optional detail
must preserve parent layouts and reserved access. Check clear entrances,
foundations, travel, observation, picking and an existing encounter, plus relevant
streaming/rendering cost. Choose the site's specific purpose and architectural
style during authoring; no new settlement, reward, encounter or ecological rule
is established here. Keep bulk asset production paused until this proof identifies
specific missing pieces. This direction does not close current playtest or T5
acceptance, or automatically expand the existing bounded T4a treatments worldwide.

## Approved opening and visual context — October 28, 2026

Approved follow-up: storm escape teaches movement/sprinting before meeting the
rescuers' owner, receiving a starter and first mask, and undertaking a teaching
battle before finding the first refuge camp. Compose readable tutorial traversal
and the subsequent wilderness route within existing generation authority. Use
strong stylized shapes, clear creature silhouettes and human-order/living-wilderness
contrast; protective refuge infrastructure demonstrates Vastra dependence. The
playable refuge/habitat/encounter sample remains the visual review deliverable.
See the [follow-up specification](decisions/2026-10-28-opening-companionship-and-consequences.md#approved-follow-up--tutorial-and-visual-identity).

The [creative decision](decisions/2026-10-28-opening-companionship-and-consequences.md)
sets an uneasy, mysterious campaign opening: wake in a Vastra storm and follow
three Sols to safety, then continue with one as the starter. Author a readable
escape route, shelter and space for the guiding Sols alongside existing traversal
and picking contracts. The current refuge/waystone route remains a development
acceptance baseline; it is not already the implemented prologue.

Keep route cues, silhouettes and interactions readable in storm presentation.
Ordinary rain remains separate from an authored Vastra storm. This plan does not
approve exposure/damage, failure/checkpoint rules, a storm origin, or changes to
procedural storm admission. Human dependence on Vastra is the ecological conflict's
thematic basis; scenery must not invent damage or make healthy concentration
appear equivalent to overload.

Monster Hunter, Pokemon, Pokemon Legends: Arceus and The Legend of Zelda: Tears of
the Kingdom are owner-selected references. Their exact stylistic roles remain
provisional as recorded in the decision. Orbs are temporary Sol art; production
species models/animation must fit the landscape and remain legible. These goals
do not reopen bulk asset creation, change generation authority, or close T5.

## Bible vision and scope

The [Bible](reference/SolHunter_Worldbuilding_Bible.md) governs design. Its section
numbers below refer to the design vision, not a claim that the corresponding
systems are implemented. The later owner-approved
[full-3D direction](decisions/2026-10-27-full-3d-and-controls.md) supersedes the
earlier sprite/pixel presentation pipeline; retain readability and dark-fantasy
intent without reverting the approved 3D work or changing the Bible.

| Bible evidence | Requirement for this roadmap |
| --- | --- |
| Sections 1–2: three equal pillars and meaningful consequences | Terrain supports discovery, Sol observation/collection and tactical readability. Visual realism and asset production must not consume the whole development scope. |
| Sections 4–5: authored civilization/landmarks plus seamless radial wilderness | Connect sample areas to the refuge/route network and authored orientation cues. Three art samples are not three isolated progression maps, nor completion of Region One geography. |
| Sections 5, 44–46: curiosity, readable danger, safe travel, minimal interface | Include an optional discoverable side excursion and a reliable return. Keep existing warnings and Examine information legible; avoid new survival-maintenance systems. |
| Sections 6, 62–63: territories own ecological state; nearby detail and distant aggregates | Cosmetic clusters and render chunks must not create a second territory, population or persistence authority. |
| Sections 10–11, 15–17: concentration differs from overload; natural processes do not originate unnatural overload | Dry, snowy, dead-tree or lush scenery does not imply ecological damage. Ordinary rain is not a Vastra storm. Disturbance/recovery visuals must read actual domain state before they communicate such meaning. |
| Sections 47, 59–65: readable world, recognizable behavior, understandable cause/effect | Preserve Sol visibility, observation and encounter space; keep camouflage, palette and clutter from obscuring existing gameplay. Placeholder geometry is not final visual-direction acceptance. |
| Sections 61, 64, 75: deferred complex migration/nesting, incremental ecology, bounded work | Keep this pass small and measurable. No food-web, migration, nesting, storm or encounter-rule expansion is required to dress terrain. Portable-device readiness requires its own evidence. |

This is a terrain/presentation subplan under the [development plan](development-plan.md).
Authored settlements/story locations, hazard ratings, population/ecology depth
and a full regional adventure remain broader work. For non-generation mechanics,
follow [mechanics-reference.md](mechanics-reference.md) before specifying behavior.

## Audit outcome and immediate work

Direction retained: use the existing kit, finish three connected visual samples,
and defer new assets and rivers until a demonstrated need. The audit identified
three rollout blockers: stale baseline/evidence claims, collision-versus-art
placement ambiguity, and missing placement/size rules for mixed scenery.

Next work, in order:

1. Resolve owner playtest blockers and establish the current baseline described
   in T5 preparation. Historical passing logs are not current-tree certification.
2. Define T4a palette, placement and static-asset admission contracts. No invisible
   blockers, water plants grounded on pond beds, or unbounded horizontal scaling.
3. Compose bounded woodland/dryland/wetland samples and review gameplay readability.
4. Verify reconstruction and compare measured costs against agreed desktop limits
   before global palette rollout. Release/export/device gates remain separate.

No further bulk asset creation or new simulation subsystem is needed for these steps.

## Research and selected approach

These are primary author/engine sources, consulted October 27, 2026. Their
techniques inform the proposal; their example values are not SolHunter rules.
The application column contains project-specific recommendations inferred from
those techniques, not claims made by the source authors about this project.

| Source | Relevant finding | Application proposed here |
| --- | --- | --- |
| [Red Blob Games: terrain from noise](https://www.redblobgames.com/maps/terrain-from-noise/) | Combining frequencies produces features at different scales; reshaping elevation controls landform character. Noise alone does not enforce global geography. | Broad landforms plus restrained detail, followed by explicit place, route, and water constraints. |
| [Auburn: FastNoiseLite documentation](https://github.com/Auburn/FastNoiseLite/wiki/Documentation) | Fractal controls combine scales; domain warping changes sampling positions. | Use the existing noise dependency, separate salts, and modest optional warp to reduce obvious repeated shapes. |
| [Red Blob Games: Mapgen4](https://www.redblobgames.com/maps/mapgen4/) | Authored terrain edits can guide subsequent procedural biomes and rivers. | Keep authored sites and corridors as inputs to terrain shaping, with smooth transitions into wilderness. |
| [Nick McDonald: particle hydraulic erosion](https://nickmcd.me/2020/04/10/simple-particle-based-hydraulic-erosion/) | Moving droplets erode and deposit material on a height grid. | Consider a deterministic regional preprocessing experiment later; do not erode individual render chunks independently. |
| [Godot: ArrayMesh](https://docs.godotengine.org/en/stable/classes/class_arraymesh.html) | Mesh surfaces can be built from vertex arrays. | Build continuous, batched chunk ground meshes while retaining tile-based gameplay and existing terrain textures. |
| [Godot: HeightMapShape3D](https://docs.godotengine.org/en/stable/classes/class_heightmapshape3d.html) | A heightmap collision shape represents a single surface height at each grid position. | Possible collision/picking representation if needed; adopting a physics movement controller is a separate decision. |

Recommendation: use a heightfield, meaning one ground height per horizontal
position. This fits low hills and valleys. Caves, overhangs, and stacked walkable
floors would require another representation and are outside this proposal.
The cited stable engine documentation is architectural evidence; verify the
specific APIs and behavior against this project's pinned Godot 4.7.2 during work.

### Alternatives considered

| Approach | Fit for this project |
| --- | --- |
| Independently raise the current tile boxes | Useful as a diagnostic, but produces steps and does not meet the smooth natural-terrain goal. |
| Continuous heightfield with logical cells | Recommended: modest scope, smooth ground, deterministic streaming, existing gameplay ownership. |
| Full hydraulic erosion at runtime | Potentially richer drainage, but adds regional dependencies, generation cost, and reproducibility work before the first playable hill. Defer. |
| Voxel terrain or a new terrain plugin | Broader capability than currently needed; would require a separate dependency, compatibility, licensing, and performance evaluation. No adoption proposed. |

## Current integration baseline

Inspected October 28; this is source inspection rather than a fresh test result.

| Area | Implemented baseline | Open acceptance/dependency |
| --- | --- | --- |
| Generation/save | `scripts/world/terrain.gd` generation 7; `scripts/persistence/save_store.gd` format 3, saved relief/geography tuning and rejection of incompatible outer formats/generations | Keep current-contract reconstruction; no legacy generators or migration project. The older variable named `height` still serves habitat classification independently. |
| Final terrain | `TerrainHeightfield` supplies raw noise; `WorldTerrain` applies pond/foundation shaping; `solid_chunk.gd` publishes curved textured meshes | Verify independently built production borders and overlap cases; raw preview checks alone are insufficient. |
| Grounding/picking | Shared final height queries, `terrain_ray.gd`, vertical streaming bounds and grounded actor/overlay adapters | Camera damping, all-prop slope fit and worst-angle readability remain specific review items; do not mark the whole T2 wish list accepted. |
| Traversal | `fits`/`can_step`, per-triangle standing slopes, essential 3x3 route admission and default-relief fallback | Broader grading and junction/cross-slope evidence; graph changes only if new edge-specific rules are introduced. |
| Scenery | Existing blocker palettes plus three bounded T4a treatments, clustered nonblocking entries, ground/bank/water modes and transformed-bounds admission | Wider palette rollout, visibility and performance acceptance remain open; generation-6 art measurements are historical. |
| Asset flattening | `nature_art.gd` collects static meshes/transforms and compacts admitted dressing by material | Unsupported node/surface overrides, hidden nodes and animation reject through the asset contract; general animated scenery remains outside scope. |
| Evidence | The dated terrain integration log passed its then-current suites; older timing is OpenGL compatibility on RTX 3070 | The validator has since gained ecology coverage. Refresh evidence for the tested tree and default Forward+ renderer before rollout claims. |

## Proposed visual envelope

Numbers below are starting experiments in world cells, not approved balance or
real-world meters. The current player model is approximately 1.7 cells tall.

| Control | Initial experiment | Review criterion |
| --- | --- | --- |
| Broad landform feature scale | Noise sampling scale of 96–192 cells | Hills read as landforms rather than repeated bumps. |
| Hill/valley detail feature scale | Noise sampling scale of 24–64 cells | Local variety without noisy footing. |
| Typical local relief | 2–4 cells across a 64-cell area | Clearly visible while walking, with useful long views. |
| Initial elevation envelope | Approximately -3 to +5 cells | Low terrain; use smooth shaping rather than abrupt clipping. |
| Fine surface detail | At most about 0.15 cell initially | Texture and vegetation carry most small detail. |
| Essential trail grade | Aim below 10 degrees | Comfortable-looking routes; validate actual grade after all shaping. |
| General walkable slope | Compare 20 and 25 degrees | Select after visual and footprint testing; not a new movement-cost rule. |

Amplitude alone cannot guarantee slope. Record actual triangle gradients, route
grades, and elevation distributions across seeds. Broad flattening should retain
gentle variation; avoid perfectly flat circular pads and conspicuous road trenches.
Noise has no single repeating wavelength; these feature scales mean starting
sampling frequencies around the reciprocal of the listed distances. They do not
promise a hill every fixed number of cells. Typical relief is a measured
peak-to-trough target, and the envelope includes final place/water shaping.

### Shared generation pipeline

Target dependency order for shaping changes: saved generation policy -> raw
landform fields -> stable authored sites/route descriptors -> bounded foundation
and route shaping -> eligible pond descriptors and basin shaping -> final height,
water mask, slope and traversal queries -> disposable render meshes.

Descriptor selection must use earlier-stage fields rather than call final
terrain sampling recursively. If pond placement would invalidate a protected
route or foundation, reject that pond candidate instead of repeatedly reshaping
the route and pond against each other. All overlapping modifiers need explicit
priority, stable tie-breaking, finite influence radii and bounded search/repair
work. A query near a chunk edge must include every descriptor that can affect it,
even when the descriptor's center is in an unloaded neighboring area.

Required-route failure uses a deterministic bounded fallback profile shared by
all chunks touching the affected corridor; it cannot depend on which chunk was
built first. Reject the new expedition safely if the fallback still fails.
Keep the existing expedition intact. Geographic planning regions are generation
units, distinct from both streaming chunks and ecological territory ownership.

## Milestone roadmap

Current implementation: T0 comparisons delivered; T1 current save/generation
contract and the core T2 terrain/grounding/picking path are implemented. T3 has shared slope
legality, blended authored foundations and essential-route admission checks;
dedicated road grading and wider regional route redesign remain future work.
T4 has per-pond level water, closed tile banks and terrain-grounded scenery;
smoother shoreline geometry and richer biome clustering remain polish work.
T5 has automated and rendered evidence, with owner/device/export acceptance open.
T6 rivers, drainage and erosion remain deferred. This status does not mark every
proposed item below complete.
T0–T4 retain the original milestone scope for traceability; unfinished exit items
remain work even where an implementation baseline exists. T4a has a bounded
[review-scene implementation](cohesive-world-sample.md); its full visual/cost
acceptance and global rollout remain open.

### T0 — Establish the comparison and terrain contract

1. Capture the current journey, camera extremes, shoreline, and chunk boundaries.
2. Produce same-seed previews for three presets: very gentle, rolling, and upper
   acceptable relief. Include a walking-height view, overhead height/slope maps,
   and player/tree scale references.
3. Specify elevation samples at shared world-space vertices, a fixed triangle
   diagonal, continuous interpolation matching those triangles, slope queries,
   water surface level, and authored shaping precedence.
   Define integer cell corners, half-cell actor centers, camera-relative render
   origins and vertical offsets explicitly. Capture the current flat scene for
   comparison; elevated worlds use the 3D entry. Maintaining a playable old
   generator or alternate flat scene is not an acceptance requirement.
4. Define settings stored with an expedition: generation version, noise seeds,
   landform scales/amplitudes, shaping rules and their version, and traversal
   limits. Cosmetic rendering settings remain separate.
   Surface sample spacing and triangulation are part of this saved contract if
   changing them changes grounding or legality; they are not free quality sliders.

Exit: reviewable comparisons and a selected visual envelope. Rolling is the
current implementation baseline following the owner's continuation instruction;
its camera comfort and final art acceptance still require playtesting.

### T1 — Add deterministic elevation and the current save contract

1. Introduce an independently salted elevation field using broad smooth noise,
   restrained secondary detail, and optional low-strength domain warp.
2. Sample absolute coordinates, never per-chunk normalization. Adjacent chunks
   independently calculate identical shared vertices and normals using a halo.
3. Add a typed terrain settings Resource with units, tooltips, validation, and
   saved parameter snapshots. Apply generation changes to new expeditions.
4. Introduce elevated terrain as a new generation version. Keep explicit outer
   save, world-state and generation versions; validate the supported combination
   before constructing a world. Unsupported versions return a distinct reason
   explaining that this development save requires a new expedition. Do not build
   a version-5 generator path, converters, or migration chains for this feature.
5. Validate current saves and reconstruct from their saved generation settings.
   Preserve identities, mutable territory/Sol records and legal player/wild
   positions within the current contract. Keep reliable file replacement and
   corruption handling. A rejected load leaves the running expedition intact;
   starting a fresh expedition is an explicit action, not a silent load fallback.

Exit: identical seed/settings produce identical heights regardless of chunk
order; current saves reconstruct after resource edits and preserve the active
expedition's state; incompatible saves are clearly rejected. Testing can start
fresh after a breaking generation/schema change. No legacy preservation work.

### T2 — Render seamless terrain and ground everything on it

1. Replace flat land tops with chunk meshes; start with one-cell vertex spacing
   and compare half-cell spacing only if visible faceting warrants the cost.
   Select canonical spacing for the current generation contract. Visual subdivision
   must interpolate its triangles; resampling different heights is a generation
   change and may invalidate development saves.
2. Use common world-space samples for mesh borders and normal calculation.
   Retain terrain textures, conform trails to the surface, and avoid z-fighting.
3. Provide one shared continuous surface-height query matching mesh triangles.
   Ground the interpolated player, roaming/deployed Sols, props, shadows,
   markers, battle overlays, and the trainer's cosmetic sideline walk through it.
4. Keep trees upright with buried roots; permit small props/rocks to align to
   slope within an art limit. Give structures supported, blended foundations.
5. Follow player elevation with damped camera motion. Update camera orbit target,
   streaming vertical bounds, fog, occlusion, and rain placement as needed.
6. Replace flat-plane picking with terrain intersection from the same surface
   data. Use matching physics shapes only if they simplify this without adding
   a competing source of height/traversal truth.
   Test triangle diagonal, grid centering and sample spacing against the pinned
   physics backend before selecting HeightMapShape3D. Identical vertex heights
   alone do not prove that ray hits between vertices match the rendered mesh.

Exit: no seams, floating models, buried feet, incorrect ground clicks, missing
hilltops, or sinking overlays during walking, orbiting, battle, load, and rebuild.

### T3 — Make terrain traversable and preserve authored travel

1. Extend shared traversal queries to evaluate grades, diagonal edges, and the
   complete 1x1–3x3 footprint, including within-cell slopes. Cell-center height
   differences alone must not allow crossing a steep internal triangle.
   Make `sample().walkable`, `is_walkable`, `fits`, movement and spawn admission
   consistent. Check the swept footprint between endpoints. Keep existing travel
   timing unless a separate mechanics decision changes it.
2. Blend authored refuge/landmark foundations and trail profiles into natural
   terrain with smooth shoulders. Start with existing routes; defer changing
   route topology until elevation is stable.
3. Validate longitudinal grades and cross-slopes after shaping, especially at
   junctions. Use deterministic local repairs or a defined safe fallback when
   required routes fail; never silently publish an inaccessible destination.
4. Keep current combat rules. Audit battle entry, deployment, movement overlays,
   pointer targeting, and retreat for terrain compatibility; do not introduce
   high-ground bonuses, fall damage, climbing, or slope costs by implication.
   Preview and execution must use the same legality rules. If introducing a
   step-height or other edge-specific restriction, path planners and battle
   snapshots must represent it as well as cell passability. Do not add redundant
   edge data solely to replace the current continuous-surface standing checks.
   Preserve any existing
   special movement exceptions. Audit field-created/removed obstacles against
   immutable terrain slope so clearing an obstacle cannot accidentally clear a
   steep-slope restriction. Reconcile any affected exceptions with the source.
5. Before specifying any changed non-generation mechanic, consult the pinned
   SolHunterSource reference and decision evidence under
   [mechanics-reference.md](mechanics-reference.md).

Exit: the outbound/return route and route junctions remain reachable for supported
footprints across the seed set; player, wildlife, and battle visuals agree with
their existing legality contracts. Any mechanics conflict is recorded separately.

### T4 — Integrate ponds, banks, and habitat polish

1. Give each initial pond a deterministic horizontal water level and a shaped
   bed/bank connected to surrounding elevations. Water must not follow hills.
   Require a closed shoreline above that level, or reject the candidate. Match
   the water classification used by traversal, sampling, and visible shoreline;
   do not retain an unrelated old water mask after reshaping the bank. A pond can
   have its own level; negative terrain height does not imply a global ocean.
2. Resolve water/route/place conflicts explicitly. Preserve required dry travel;
   initially relocate or omit conflicting ponds with a deterministic rule.
3. Blend shore materials and low vegetation using water proximity and slope.
   Keep existing moisture and Vastra channels independent; elevation must not
   silently reroll affinity, individuals, or ecological state.
4. Expand vegetation placement with slope-aware exclusions, small clusters, and
   clear views near routes. Keep decorative density separate from collision.

Exit: no uphill water sheets, exposed holes, flooded refuge, disconnected trail,
or shoreline seams. The sample journey reads as meadow rise, wooded valley,
and pond depression under daylight, dusk, night, and rain.

### T5 preparation — Establish a current measurement baseline

Before comparing expanded art with the live game, extend the profile manifest
to record timestamp, command, engine, renderer/driver, actual viewport, frame cap,
seed, generation/relief/climate settings, view/shadow/detail distances, quality
settings, nature palettes/density, and tested source/resource fingerprints.
Record the commit plus dirty-file hashes when working outside a clean revision.
The existing profile does not yet capture all of these inputs.

Use the current default Forward+ renderer on the development desktop (Direct3D 12
on the inspected host), with separate Compatibility results if useful. Repeat
fresh-process and warm runs at least three times; label cache conditions honestly.
The old flat/elevated timing table remains historical evidence, not the current
comparison baseline. Keep initialization, travel, save/load and rebuild timings separate.

Agree explicit provisional desktop frame/startup/memory and scenery-regression
limits before global rollout. Report both paced frame intervals and a separate
uncapped throughput sample. Missing limits do not prevent bounded composition
prototypes or owner playtesting, but do prevent claiming performance acceptance.
Record limitations where process/GPU memory or instrumentation is unavailable.

### T4a — Make three areas distinct with the existing asset kit

Priority update, October 28, 2026: the supplied nature kit and
[24 lightweight placeholders](../assets/biome_placeholders/README.md) are sufficient
for the next art pass. Pause bulk asset creation and prove composition first.
The [bounded review scene](cohesive-world-sample.md) now implements placement
contracts and three connected treatments. The requirements below still govern
acceptance and rollout; this does not declare new biome generation implemented
or replace the owner's current terrain playtest. Address playtest blockers first.

1. Define the rendering/asset contract before selecting palettes:

   - Palette entries identify scene, placement surface, authored uniform scale or
     target-size policy, and a maximum horizontal extent. Height-only normalization
     is insufficient for flat lily pads or long fallen logs. Validate finite,
     nonempty bounds and set small per-category mesh-part/triangle limits.
   - Ground/bank entries sample final terrain; floating entries sample pond water
     level. Water decoration is a new rendering path: today's `walkable` detail
     filter excludes water and would otherwise anchor models to the pond bed.
     Keep water nonwalkable and avoid creating bank/water gameplay rules here.
   - Reserve routes, authored approaches, interaction/encounter space and chunk
     edges using transformed visual bounds, not only the anchor cell. Account for
     crowns and horizontal logs extending into neighboring chunks.
   - Retain visible tree/rock blockers at their generated positions. First-pass
     clusters and density changes apply to nonblocking dressing; use existing
     open ground for clearings. Hiding or moving blocking art would leave invisible
     collisions. Any blocker-layout change is a separately versioned generation
     task with traversal and fresh-expedition validation.
   - Use static MeshInstance3D descendants with materials stored on the meshes.
     Current flattening does not preserve node/surface material overrides, hidden
     nodes or animation. Bake the supported material state or explicitly extend
     the adapter with focused checks; general animation support is outside scope.

2. Compose one bounded woodland, dryland and wetland sample using existing
   habitat/moisture data and terrain. Record each sample's seed, coordinates,
   palette and bounds. Select existing environments with a bounded search; if
   suitable habitat is absent, record that generation gap rather than relabeling
   the same environment to force an art result. These are visual treatments,
   not new biome canon, encounter or ecological rules.

   | Sample | Existing art to try | Intended visual distinction |
   | --- | --- | --- |
   | Woodland | Broadleaf/birch trees, bushes, ferns, grass, flowers, mushrooms, logs and stumps | Existing tree groups, varied nonblocking ground cover and existing clearings. |
   | Dryland | Olive dry trees, sparse grass, snags, boulders and rock clusters | Existing open views, lower dressing density and warm ground tones. Keep cactus/tropical/snow studies for environments that call for them. |
   | Wetland | Willows, reeds, rushes, lily pads and bank rocks | Low clustered plants around water and readable dry approaches. |

3. Connect small editable palettes and bounded dressing controls to actual
   rendering. Use independently salted absolute-coordinate placement; generation
   and rendering order must not change results. With matched palette/settings,
   verify identical world-space cosmetic transforms after chunk eviction/rebuild
   and save/load, matching by asset path/cell rather than runtime instance IDs.
   Require no changes to
   blocking cells, individual IDs, territory/ecology state or generation settings.
   Distinguish cosmetic palette edits from versioned geography changes.
4. Connect the samples through the existing refuge/routes and an optional side
   excursion with a discoverable orientation cue. Reuse existing authored props,
   Sol observation/journal and encounter fixtures to check the other two gameplay
   pillars. Rendering must not admit new individuals or fabricate ecological
   damage. This does not require new story content, species or encounter rules.
5. Review matched views in daylight, dusk/night and rain, plus travel, observation,
   picking and an existing tactical encounter. Show boundary transitions as well
   as sample centers, including a chunk seam. Confirm that plants preserve route,
   warning, trainer and Sol readability under the approved full-3D direction.
6. Measure bounded samples against T5 preparation's baseline and agreed limits.
   Include draw calls, mesh parts/triangles, instances/shadow casters, publication
   time, picking cost and frame p95/p99. Small scene-file size is not a runtime
   budget. Expand palettes globally only after correctness and cost gates pass.
7. Judge the samples before adding models. Record concrete gaps with a location
   or screenshot; add only the minimum cheap placeholder needed. The following
   are conditional backlog items, not prerequisites for the three samples:

   | Conditional additions | Add when |
   | --- | --- |
   | Ground materials: sand, mud, gravel; snow later | Existing surfaces cannot communicate the intended ground or transition. |
   | Transition pieces: roots, bank rocks, exposed terrain faces | An actual shoreline, slope or prop placement exposes a visible mismatch. |
   | Landmark props: signs, fences, simple ruins | An authored place needs orientation or a distinct silhouette. |
   | Bridges | A designed crossing requires one; coordinate with route/water work instead of adding decorative crossings without traversal support. |

8. Keep stable scene paths and ground pivots so the owner can substitute finished
   models individually. Placeholders remain inexpensive layout tools; detailed
   final-art production is outside this pass.

Exit: owner review can distinguish the three connected areas without location
labels; travel, observation and targeting remain clear; no invisible blockers or
floating/oversized replacements are introduced; deterministic reconstruction and
unchanged domain state are demonstrated; costs meet the agreed desktop limits.
Record evidence for each sample. Further asset requests need a demonstrated use;
asset counts and pretty screenshots alone do not complete the milestone.

### T5 — Validate cost and accept the first natural-terrain slice

1. Add focused checks for shared vertices/normals, interpolation, finite bounds,
   slope/footprint legality, water levels, shaping overlap, negative coordinates,
   repeatability, saved settings, and incompatible-version rejection.
   Include adversarial slope/diagonal/pond-junction fixtures, supported coordinate
   limits near +/-1,000,000 cells, shuffled generation and eviction/reconstruction,
   invalid saved terrain settings, and a complete read -> move -> save -> reload
   cycle for the current generation. Replace obsolete generation migration checks
   in affected suites with explicit rejection checks; verify failure preserves the
   running expedition. Verify shared samples exactly within the pinned runtime;
   state a measured tolerance for rendered/physics interpolation comparisons.
   In particular, compare independent final production meshes across positive
   and negative borders, around pond/foundation/route shaping overlaps, and before
   and after cache turnover. Verify final normals as well as heights. Add pinned
   current-generation fingerprint fixtures; intentional version changes may
   replace them without maintaining old-save compatibility. Test counts from the
   raw study mesh or one production chunk do not establish these cases.
2. Extend the rendered journey profile for elevated terrain. Measure cold/warm
   startup, rebuild/load, continuous running, rapid orbit/zoom, maximum render
   distance, and dense scenery. Record p95/p99/worst frame, generation/mesh cost,
   peak resident chunks/vertices, process memory, and GPU memory where available.
   Use named repeatable runs: ordinary outbound/return journey; the same journey
   with running held; a fixed orbit/tilt/zoom sequence at maximum render distance;
   each T4a sample at its maximum supported dressing density; and a bounded long
   trip that records at least one turnover of each terrain cache. If a time cap
   ends the trip before turnover, mark that coverage incomplete. Keep these
   rendered/device workloads outside ordinary hardware-independent CI.
3. Run the shared validator and affected rendered suites on pinned Godot 4.7.2;
   manually walk the route, inspect pointer accuracy and camera comfort, and
   smoke-test an actual export before claiming exported-build acceptance.
4. Compare current art against T5 preparation's matched baseline. The flat-world
   T0 report is historical context; no maintained legacy generator is needed.
   Enumerate headless GPU skips and complete their relevant rendered checks.
   Record owner journey acceptance separately from automated traversal. Desktop
   development acceptance can proceed independently of future export/portable
   device qualification; each needs its own stated workload and budget.
5. Update the Inspector map and affected development notes with actual results.
   Make threading or mesh-resolution changes only when measurements justify them.
   Keep regression checks with each implementation milestone; T5 consolidates
   acceptance evidence rather than deferring all testing to the end. If a phase
   changes after its tests pass, rerun the affected checks.

Exit: owner accepts terrain scale, comfort, and appearance; relevant checks pass;
performance evidence and remaining limitations are recorded for the tested state.

### T6 — Later expansion: connected drainage and regional geography

Owner priority update, October 28, 2026: route/water repetition is now the next
terrain update, ahead of broad palette expansion and full regional drainage.
The [bounded geography slice](route-pond-diversity.md) is now implemented in
generation 7: displaced district hubs, winding selected dry links, optional spurs,
varied pond descriptors and triangle-clipped level water replace the 96-cell
lattice and tile-edged ponds. These requirements govern validation and owner
acceptance; full regional drainage remains later work:

1. Keep authored refuge/waystone anchors, but replace the visibly regular road
   lattice in the representative expedition with deterministic winding approaches,
   varied spacing and asymmetric junctions/optional branches. Shape travel around
   terrain and water rather than drawing the same grid over each region.
2. Vary pond count, size, aspect and shoreline shape using stable geographic
   descriptors. Blend banks into final terrain and render smoother shorelines;
   adding reeds or pads alone does not address the owner's concern.
3. Deliver same-seed before/after player-scale views and a connected outbound/return
   journey first. Keep bounded descriptor searches, continuous chunk boundaries,
   final picking/grounding, level water and safe essential travel for 1x1–3x3 footprints.
4. Treat changed routes/water masks as a generation change with a version bump,
   saved settings and clear incompatible-development-save rejection. Do not
   silently reinterpret current expeditions or preserve an obsolete generator.
   Verify encounters/battle admission, deterministic reconstruction, save/load,
   and travel/streaming cost against the changed geography.

Connected river drainage, large regional landforms and erosion retain the later
scope below; this priority does not promise a full river simulation in that update.

After T5 acceptance, evaluate connected streams, river valleys and regional
landform masks beyond the bounded route/pond slice. Plan drainage over deterministic geographic regions,
independent of render chunks, with explicit boundary inflow/outflow contracts.
Specify depression handling, downstream continuity, lake outlets, crossings,
cache limits, reconstruction, and save/version policy before implementation.

If terrain still looks artificial, compare a bounded seeded erosion preprocessing
pass against cheaper shaping. Fixed iteration order and regional boundaries are
required; a finite halo alone does not prove globally correct river drainage.
Preserve safe essential routes through explicit crossings or route planning.
Full water simulation, terrain deformation, caves, and extreme mountains remain
outside the initial roadmap.

## Review points and implementation order

T0 and the initial T1–T4 slice already exist. T4a contracts and three bounded
treatments are implemented and owner-authorized in normal play. The bounded
route/pond-diversity slice is implemented, with owner playtesting and T5 performance
acceptance still open. Wider art rollout and desktop acceptance
remain gated by their recorded correctness/cost and review requirements.
Export/portable-device qualification is a separate acceptance track;
The owner's bounded route/pond-diversity priority above now has generation-7
implementation evidence; full T6 drainage remains a separately reviewed expansion.
Keep the current playable slice usable while addressing outstanding acceptance
items; do not treat every original milestone bullet as unfinished implementation.

The review decisions are the preferred relief preset, smooth versus subtly
faceted shading, and whether streams are a first-slice requirement. Recommended
defaults are rolling low relief, smooth shading, and ponds first. Old-save
preservation is excluded by owner direction during solo development. The versioned
save framework remains; revisit compatibility before external testing or release.
The owner authorized execution and then requested continuation after the
[T0 terrain preview](terrain-preview.md). Rolling is the implementation baseline;
its tuning can still be refined through playtesting. Remaining acceptance and
expansion work is tracked above and in the implementation evidence.

Review correction: later milestones remain a proposed implementation sequence. Noise-based
landforms should be judged against the visual envelope; physical realism and
cross-platform bit-identical output have not been established. Recheck generation
fixtures deliberately when changing engine/noise versions. Raw heightfield checks
and preview captures do not establish gameplay integration, portable-device
performance, or owner acceptance. T1–T6 are not marked complete by the preview.

## T2–T3 blocker verification — October 28, 2026

Fresh rendered checks passed for production terrain grounding/picking (1,823),
solid geometry (19), and building traversal/foundation bounds (778), including
the GPU checks skipped by headless runs. No grounding, picking or route failure
was reproduced in these covered cases. A renderer teardown error in the building
and terrain fixtures was corrected by flushing frames and releasing the sky
before freeing the scene; assertions alone no longer mask that error.

Evidence: `artifacts/playtest-blockers-terrain-rendered.log` (solid geometry),
`artifacts/playtest-blockers-buildings-rendered.log`, and
`artifacts/playtest-blockers-rendered-regressions.log` (terrain and Sol movement;
its initial combat fixture failure was subsequently corrected). Godot terrain
remains the height and traversal authority. This verification does not reroll
generation or close independent-border/overlap coverage, all-prop slope-fit,
camera comfort, owner playtesting or export/device acceptance.

## T4a bounded sample — October 28, 2026

[The cohesive world sample](cohesive-world-sample.md) provides a separate playable
scene with bounded woodland, heath and pond-side palettes, typed surface/size/static
asset contracts and reconstruction checks. Existing blockers and generation remain
authoritative. Its review/cost evidence and unresolved visibility/validation gates
are tracked there. Owner instruction to apply the changes, October 28, promotes
these three bounded treatments and the pond cue into normal F5 play. Other areas
and seeds retain existing dressing; worldwide palette expansion remains gated.
