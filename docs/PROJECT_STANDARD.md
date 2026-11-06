# SolHunter Godot project standard

## Main gameplay foundation

The owner selected the current map-first gameplay build as the main game on
November 5, 2026. Its publication target is the `main` branch of
`eliBrownn/SolHunterGodot`.
Its default entry is `scenes/gameplay_foundation.tscn`. It uses a
map-driven terrain and free movement that settles at tile centers. The default
player is the Quaternius mannequin from the supplied Universal Animation Library
Standard archive. The Godot model and CC0 dedication are in
`assets/characters/universal_mannequin/`. The map-first scene plays the authored
in-place idle, walk, and sprint loops using the current movement state.
Seeded, persistent Vastra vortices are a field test independent of
the inherited ecology and storm admission rules.
Open `scenes/world_3d.tscn` with F6 for the inherited expedition. Its
routes, encounter/combat loop, saved ecology, and save formats are fixture
contracts. The map-first game currently exposes exploration, visual vegetation,
and seeded visual storms. The dated rollout and design records below retain
their original scope. The main game uses the `SolHunter-Gameplay` user-data directory. GitHub validation
imports the project and runs the seeded gameplay foundation test. The
full validator also runs the inherited fixture suites.

### World-generation baseline — November 5, 2026

The owner approved [World Map Plan v2](world-map-proposal.md) on November 5,
2026 as the map-first baseline. The playable scene uses Plan v7, with smoother
lowlands, increasingly jagged upper ridges and curved river channels rasterized
at eight-world-cell spacing. Tundra remains reserved for cold, higher terrain.
Every normal launch selects a new seed before
generating the atlas. The plan owns mountains, biome placement, drainage and
irrigation. Terrain samples add local relief, fit banks to the planned ocean
and lake levels, and cut shallow channels along mapped rivers.
The ocean uses a single datum at world height 0. A shared elevation curve
keeps foothills low and gives the upper ranges more vertical relief. Lake spill
heights use the same curve as the terrain. The atlas records both the natural
and irrigation-adjusted biome. The ground material and biome HUD use the
adjusted value. The main scene streams visual plant communities from these
biomes and the canonical terrain surface. The canopy uses the inherited
expedition's twelve procedural tree forms and five named designs. Each tree
form is a species resource with its own allowed biomes and spawn weight.
The defaults allow all seventeen in every land biome. Local density, slope,
and water clearance guide seeded placement. Biome hue shifts tint foliage at
all seven tree detail levels. Plant scale defaults to 1.5×. See
[the canopy hierarchy and tiers](world-map-proposal.md#tree-species-and-vector-lods).

The optional local EmacEArt Cool Water material reads the opaque terrain beds
on Forward+ and Mobile. The full effect fades from 150 to 260 cells from the
camera. Distant patches use the atlas water material. Water levels and
walkability remain owned by the plan. See [local water setup](water-appearance.md#cool-water-in-the-map-first-build).

Spawn favors a dry ocean beach near the outer edge of the map with higher
terrain in the opening inland view. Movement and
terrain rendering share height samples. The nearby 64-cell chunks join eight
coarser horizon rings. A dedicated worker prepares distant terrain and travel
updates from read-only atlas data. The main thread uploads geometry in batches
and replaces the horizon after the new coverage is ready. Distant rings use
fixed world-space sample grids. An eight-cell margin absorbs small reversals
at chunk boundaries, and a finished build is discarded if it would take
coverage away from the latest request.

### Biome standard for the map-first world

**World plan → geographic region → local terrain → streamed chunks.** The
completed `WorldMapPlan` owns biome placement before terrain workers start.
Geography, elevation, temperature, natural moisture and drainage determine
where each biome belongs. Aim for interiors large enough to explore, with
smaller patches where the geography supports them. Keep biome IDs stable
across the world plan, proof maps and terrain. Normal launches generate a new
seed. The same seed, generator version and settings reproduce the same map.

| Layer | Responsibility |
| --- | --- |
| World atlas | Assign the natural biome to each map sample. Keep ocean, lakes and rivers tied to their planned levels and drainage. The existing Ocean, Lake and Coast IDs identify water and shore categories in the shared atlas. |
| Local terrain | Refine ridges, slopes, channels and banks within the atlas constraints. Use elevation, slope and proximity to water to vary the ground within a biome. Irrigation changes soil moisture and can shift the local biome toward Meadow or Marsh. The atlas retains the natural biome and its intake record. |
| Presentation | Use an editable Godot surface profile keyed by biome ID for map color, ground materials, texture scale and blend settings. Sample in world coordinates so neighbors meet across chunk seams. Fade from close texture detail to the atlas palette at distance. |
| Ecology | The Bible's ecological territories own persistent habitat and population state. Future habitat rules can reference biome, water and landform together. A biome ID describes environmental context and carries no automatic Sol affinity. Streaming chunks serve loading and rendering. |

Give each land biome a recognizable combination of silhouette, ground
materials and water context. A surface profile may combine shared ground
materials such as sand, rock and soil. Use matching authored normals when
supplied. Blend transitions using world-space masks such as shore wetness,
slope and neighboring biome weights. World queries expose both categorical biome
IDs and identify the one in use. Use the atlas palette as the fallback for missing optional textures.
An art-only change must preserve atlas geography and biome placement, terrain
height, water levels and spawn for a fixed seed and settings.

**Authoring checklist.** Record each biome's stable ID and name, its placement
conditions, typical landforms and water context, neighboring transitions, and
surface profile with asset provenance. Describe how it reads on the world map
and on foot. Record future habitat ideas separately from active mechanics. The
gameplay foundation uses terrain, water, and streamed visual plants to
establish biome identity. Plant ecology is a separate milestone.

**Biome features.** The gameplay foundation uses
[Lynocs ground materials](../assets/terrain/lynocs/README.md) for Coast, Meadow,
Heath, Desert and Jungle. The other habitats use their atlas colors.

| Biome | Landform in the gameplay foundation |
| --- | --- |
| Meadow | Open, nearly level fields with long shallow folds. |
| Woodland | Raised shoulders, elongated hollows and occasional gullies. |
| Heath | Sandy ridges with wind-cut notches and open dry saddles. |
| Marsh | Shallow basins, broken banks and raised hummocks. |
| Ocean | Shallow shelves easing into deeper offshore hollows. |
| Coast | Low beach shelves with low sandy bars above the tideline. |
| Desert | Broad hills with rolling, wind-shaped dunes and troughs. |
| Jungle | Closely spaced hills and knolls above deeper river hollows. |
| Savanna | Open swales punctuated by flat-topped rises. |
| Alpine | High crags and ribs separated by saddles. |
| Tundra | Cold high benches with low ridges and shallow depressions. |
| Taiga | Long rounded ridges and cool troughs. |
| Lake | Shallow banks easing into an uneven deeper bed below the planned surface. |

The terrain projection bakes regional land shapes from the seed and blends
them across atlas cells. Nearby biome samples also control local relief, giving
meadows gentler grades and desert dunes a continuous shape across chunks.
Lowland relief tapers near the mountain belt, where Alpine
relief takes over. Ocean and lakebed features appear through the optional
close water material. The plan supplies water levels, channels and irrigation.
The Meadow label retains the existing Plains biome ID.

**Review for future implementation.** Use the existing
[world-map proofs](world-map-proposal.md#reproduce-the-proof) for several
fixed seeds. Review connected biome interiors, climate fit, river and lake
continuity, and irrigated ground retaining its underlying biome. Review a
representative crossing at ground level and from a high camera, including a
chunk seam and the transition to distant terrain. Check frame pacing during
fast traversal with the existing terrain worker and horizon rings. Ecology
follows the [Worldbuilding Bible](reference/SolHunter_Worldbuilding_Bible.md).

Status: authoritative organization and contribution policy.
Established: 2026-10-26. Owner: project owner; steward: daily Git maintenance in this chat.

## Authority and scope

This is the single source of truth for repository organization, Git practices, and maintenance. README and agent instructions link here instead of duplicating policy. Explicit owner decisions take precedence; record durable changes here with their reason and date. Resolve conflicting instructions before acting on the affected work.

`docs/reference/SolHunter_Worldbuilding_Bible.md` governs game design. Preserve confirmed, provisional, and deferred distinctions. Repository housekeeping must not revise canon or turn unresolved designs into requirements. Other SolHunter repositories are outside this maintenance scope.

Owner direction, October 28, 2026: maintain the [Sol Bible](reference/sol_bible.md)
as the species/lineage authoring reference and roster index to populate. It develops
species details under the worldbuilding Bible's design authority; proposed entries
and existing prototypes do not become approved final-roster designs by inclusion.
Keep repository workflow in this standard and runtime content in Godot resources.

Owner direction, October 26, 2026: use [SolHunterSource](https://github.com/eliBrownn/SolHunterSource) to resolve game-mechanics questions outside the world-generation engine. Read its relevant implementation, tests, and decision evidence before proposing replacement rules or escalating an apparent gap. See [mechanics reference](mechanics-reference.md) for verified source locations and reconciliation procedure. This permits read-only reference use; it does not authorize maintenance of that repository or replacement of Godot world generation. Preserve explicit Bible canon and flag unresolved source conflicts rather than silently overriding it with legacy behavior.

## Hierarchical ownership and composition

Owner-approved principle, October 28, 2026: use hierarchy across the game to own
standards and constrain local variation. Maintain separate domain hierarchies;
connect independent properties and systems through explicit references rather
than forcing them into one inheritance tree. Preserve individual affinity as
independent of species and rendering ownership as independent of ecological state.

Each fact has one authoritative owner. Children inherit relevant constraints and
may narrow them; siblings share parent space and budgets. Distinguish mandatory
requirements from preferences. Named authored exceptions may override defaults
at the owning level, but cannot bypass required access, data integrity or other
hard invariants. Small detail changes must not reroll unrelated parent layouts.
Create a hierarchy level only when it owns a useful decision, rule or budget.

Owner direction, October 29, 2026: world variation should use geographic parents,
local landforms, water-flow context and biome/grove variation. Render chunks do
not own geographic layout. Paths must remain on terrain the player can scale;
local scenery preferences cannot override that access constraint. See the
[biome/geography slice](biome-encounters-geography.md) for implementation evidence.

Owner requirement, October 29, 2026: every generated living plant must be
registered in the Vastra hierarchy through its canonical geographic cell.
Generation owns membership; geographic regions catalogue definitions;
ExpeditionState owns saved reserves and transactions; scenery/particles reference
those owners. This includes all biome vegetation and the existing authored pond's
living water/bank plants. Registration is required infrastructure for circulation,
repair and vegetation/Vessel ecology. Visual clumps cannot multiply reserves, and
camera/asset names cannot determine membership. Keep new vegetation and relevant
system/hierarchy documentation aligned with the authoritative
[vegetation registration contract](vastra-integration.md#generated-vegetation-registration-and-system-hierarchy).

Owner direction, October 29, 2026: audio follows that hierarchy. The root game
mix owns routing and the shared voice budget; category mixes own volume and
inherited zoom behavior; individual cues own assigned streams and local playback
within those constraints. Attach the spatial listener to the camera. Wide zoom
emphasizes atmosphere, close zoom emphasizes footsteps and foliage detail,
with a smooth adjustable blend. Audio consumes existing gameplay and weather
owners and does not create mechanics. Owner follow-up, October 29, 2026: add
licensed audio assets to the existing sound system and apply the approved Kenney
particle artwork. Preserve source/license records; choose conservative cue trims
and retain empty slots where suitable content has not been selected.
Implementation controls are indexed in [Inspector tuning](inspector-tuning.md).

Owner direction, October 29, 2026: wind belongs inside a shared weather system.
Weather owns coordinated cloud cover, precipitation, wind and transitions; a wind
component owns airflow/gusts, geography modifies local exposure, and presentation
consumes those conditions. Day/night remains alongside weather. Extend the existing
saved-clock weather foundation; first deliver environmental presentation, with
gameplay/ecological effects requiring separate mechanics reconciliation. The
[weather roadmap](weather-roadmap.md) owns the detailed delivery and acceptance
plan; the world/exploration roadmap retains cross-feature sequencing.

Owner follow-up, October 28: reformat the existing project around this principle
through the [project reformat roadmap](reformat-roadmap.md). Prove the first
scenery slice, then migrate the remaining domains in bounded, reviewable changes.
The roadmap owns the structural delivery sequence; feature roadmaps retain their
design and acceptance criteria. The Bible and mechanics-reference authorities
above remain binding; structural approval establishes no new mechanics.

Keep one owner per responsibility and one evidence index for the reformat. Reuse
verified contracts, mechanics evidence and matching validation results. Select
checks from the actual change and its dependencies; invalidate evidence when
relevant inputs, contracts or execution conditions change. Do not rerun unrelated
systems at every phase or duplicate an existing implementation/test. Run broader
integration checks at shared-contract changes and final integration as warranted,
and keep configured CI checks unchanged. See the roadmap's
[validation reuse rules](reformat-roadmap.md#validation-and-evidence-reuse).

Owner direction, October 29, 2026: use supplied material maps whenever available,
including terrain normal maps; do not synthesize relief from color textures when
the asset provides authored surface data.

## Repository layout

The inherited expedition moved from the October 26 sprite presentation to
full 3D on October 27, 2026. That build used the supplied rogue and animation
rigs and Stylized Nature MegaKit scenery.
Owner follow-up, October 29, 2026: replace the default player with the supplied
female undead grave knight. Preserve player controls and height; retain the
optional mannequin traversal fixture. Asset attribution lives beside the model.
Existing terrain textures may remain on real tile geometry. Allow live camera
orbit/tilt/zoom and reset, camera-relative walking, perspective game view,
view-dependent terrain streaming and configurable asset/render distances.
Use the supplied procedural sky resources with a matching horizon.
Owner direction, October 27, 2026 also adds day/night and basic weather. Derive
their visual timeline from the saved active exploration clock; expose lighting,
cycle and clear/cloudy/rain tuning in Godot. This presentation slice does not
add weather damage, encounter rules or ecological modifiers.
Preserve generation and gameplay authorities.
See [the current visual direction](decisions/2026-10-27-full-3d-and-controls.md).
Owner direction, October 29, 2026: develop a stylized, painterly fantasy look
with authored nature assets, procedural placement/variation, soft colored shadows
and restrained magical accents. Establish foliage wind/backlighting and lighting
in a standalone forest study before broad rollout. The study is an art fixture;
Godot world generation remains authoritative. See [forest style](forest-style.md).
Owner approval, October 29, 2026: apply the reviewed nature samples and expansive
stylized grass to the inherited expedition. Its Options menu included a live
pixel adjustor for testing.
The owner's later October 29 direction removes pixelation from the default view.
Keep UI/picking at native coordinates and proprietary grass
source local-only; use the original grass fallback when it is absent. See
[reviewed world visuals](reviewed-world-visuals.md) for the implementation contract.

Owner direction, October 27, 2026: mouse controls world, combat and NPC
interactions; keyboard controls player movement and personal systems. Escape
cancels/closes interaction layers and must not directly retreat. Personal menus
remain clickable. See [UI/UX roadmap](ui-ux-roadmap.md) for the implementation
sequence and validation status.
Owner clarification, October 28, 2026: that input split describes desktop play.
Controller support, including full-game input handling and game UI/UX, is the
approved fallback priority after active UI work. Preserve desktop controls and
provide equivalent controller interactions; handheld device acceptance remains
separate. See the same UI/UX roadmap for scope.
Owner direction, October 27, 2026: right-click is the primary world interaction
menu, informed by RuneScape's Choose Option pattern. Offer actions for the pointed
target, including Engage/Observe on Sols, preserving existing gameplay authority.
Owner follow-up, October 28, 2026: exploration left-click performs the first
enabled context action. Context menus use a smaller target-name heading and short
action labels without repeating that name. Observe shows a simplified appearance
description; Details retains the expanded readings.


Owner direction, October 27, 2026: provide a cohesive, movable and adjustable
in-game menu, using PokÃƒÂ©mon's familiar guide/party/bag/trainer/save/options
organization as a reference. Use original SolHunter styling and retain existing
gameplay authorities. Menu layout preferences are local presentation settings,
separate from expedition saves. Owner follow-up: R toggles the live field menu;
opening it does not pause time or movement. Escape opens a separate true pause
screen after dismissing higher interaction layers. The menu uses a 0.7 size
multiplier (30% smaller), while preserving local adjustments. The game window is
resizable and starts maximized to the available screen, with no fixed physical
startup-size override. The view expands to the display aspect ratio. Player heading
changes use smooth shortest-arc visual turning.
Owner phase-4 direction: use PokÃƒÂ©mon as a reference for companion navigation,
without copying its presentation. Sol menus show the selected Sol's actual model
fitted inside a dedicated preview window. See [Sol menu](sol-menu.md) and
[field menu](field-menu.md).

Owner clarification, October 28, 2026: affinity orbs are temporary Sol placeholders.
Production Sols have species-specific models, behaviors and animations, while
individual identity and affinity remain independent. Owner follow-up, October 28:
remove orb bodies from gameplay, including legacy and unknown species. Catalog
species use authored models; other identities use provisional articulated creature
bodies. Anatomy must vary and reflect its class. Individual-affinity effects remain
separate from the body. The editable affinity palette follows the approved Bible
colors; exact RGB values remain art tuning. Affinity colors never derive from
species/class. See [affinity orb presentation](affinity-orbs.md) and the
[opening/companionship decision](decisions/2026-10-28-opening-companionship-and-consequences.md).

Keep the root small: project entry/configuration, README, agent instructions, and repository tooling. Use the following destinations as content arrives; do not create empty scaffolding or relocate existing assets solely for cosmetic consistency.

| Path | Purpose |
| --- | --- |
| `project.godot` | Godot project entry |
| `ROADMAP.md` | Repository management milestones and completion evidence |
| `scenes/` | Reusable and game-specific scenes |
| `scripts/` | Game code, grouped by feature |
| `shaders/` | Godot shaders for 3D materials, atmosphere and visibility |
| `assets/` | Runtime art, audio, fonts, and source asset metadata |
| `resources/` | Authored Godot resources and game data |
| `addons/` | Deliberately adopted editor/runtime plugins with licenses |
| `tests/` | Meaningful automated checks and fixtures |
| `tools/` | Repeatable development and validation scripts |
| `docs/reference/` | Canonical reference material |
| `docs/decisions/` | Dated decisions with context and consequences |
| `docs/maintenance-status.md` | Latest maintenance findings and unresolved actions |
| `builds/` | Ignored generated exports |

Use descriptive snake_case names for new game files/folders and follow established class naming in code. Avoid case-only renames on Windows. Keep related resources together and update references through Godot when moving scenes/assets. Validate moved paths and resource identifiers before committing. Do not keep duplicate authoritative documents or daily copies of the same status.

Reformat execution, October 28, 2026: scripts now live under `application`,
`world`, `scenery`, `persistence`, `sols` (with separate presentation consumers),
`combat`, `presentation`, `ui`, `story`, `development` and the demonstrated shared
`core` helpers. The exact ownership/move map and validation evidence live in
[the reformat roadmap](reformat-roadmap.md#execution-ownership-and-migration-map).
Keep authored resource groups and third-party asset paths intact. Reference-aware
script moves preserve `.gd.uid` sidecars, update all consumers together, verify
reference-only logic equivalence and finish with engine import/entry validation.
`tools/check_script_ownership.py` checks the map, literal script paths and unique
UIDs locally; the configured Godot CI entry point remains `tools/validate.ps1`.

## Branches and synchronization

- `main` is the intended integration branch and must remain usable once the project exists. Confirm the remote default branch before establishing upstreams; do not rename branches speculatively.
- Use short-lived branches for one coherent change: `feature/<topic>`, `fix/<topic>`, or `docs/<topic>` for human work; `codex/<topic>` for agent work. Use separate worktrees when concurrent changes need isolation.
- Before work, inspect status, current branch/upstream, and active work. Preserve dirty and untracked files. Never stash, reset, clean, overwrite, or commit another contributor's work as housekeeping.
- Fetch before synchronizing. On a clean integration checkout, use `git pull --ff-only`; if it cannot fast-forward, inspect divergence and resolve deliberately. Do not use an automatic merge pull.
- Start topic branches from the verified current integration tip. Update a shared topic branch by merging the integration branch when necessary. Rebase only private, unpublished work; never rewrite published history.
- A repository with no commits requires an explicit bootstrap change before normal branching/PR flow is possible. Account for pre-existing untracked content and inspect remote history before the initial commit or push.

## Commits, pushes, and pull requests

Review `git diff` and `git diff --cached`; stage named paths or selected hunks. Use focused commits with clear imperative subjects, for example `docs: define repository workflow`. Separate unrelated refactors, generated artifacts, and gameplay changes. Never commit credentials, machine-specific secrets, or player saves.

Push topic branches without force only after checking their contents, destination, and validation. Open a PR to `main` describing the problem, resulting behavior, validation evidence, and material limitations. Link the relevant issue/decision when one exists. Scene or UI changes should include useful screenshots or a short reproduction path.

For an owner-authorized sequence that depends on unmerged work, a topic branch may start from its reviewed predecessor and target that predecessor in a stacked PR. Identify the dependency and integration order in the PR; retarget to `main` after the prerequisite merges. Each change still requires validation and owner review. This records the development workflow used on October 26, 2026.

Before merge, resolve review feedback and conflicts and pass the checks appropriate to the change. A reviewer other than the author should approve when available; in a solo project the owner explicitly reviews and merges. Prefer squash merge for a coherent topic and keep the PR description meaningful. Maintenance agents do not automatically merge PRs.

The desired remote rules are: require PRs, block force pushes and default-branch deletion, and require relevant configured checks. Require independent approval when collaborators make that practical. These are policy targets, not proof of GitHub configuration. Record actual enforcement separately; do not invent check names or claim protection is enabled without verification.

After merge, branch deletion is a deliberate cleanup action: verify the PR is merged, no unique commits or active work remain, and the owner authorizes deletion. Age alone never justifies deletion. Recover mistakes with revert commits rather than rewriting shared history. Tag approved releases with version and validation evidence; do not retag published releases.

## Godot and validation

Owner direction, October 29, 2026: tactical combat must not pause the surrounding
game world. Keep the shared active clock, atmosphere, Vastra and unrelated local
wildlife/recovery running while combat owns player input and its participants.
Retain explicit pause-screen behavior and existing encounter-preview/persistence
guards. The current implementation and source reconciliation are recorded in
[battle world continuity](first-playable-battle.md#continuing-world-during-combat--october-29-2026).

Owner focus clarification, October 29, 2026: prioritize Vastra, world generation
and biome-specific environmental activity so roads and wilderness feel alive
without relying on nearby Sols. Hold landmark placement and advance this work
before optional leads. The [world/exploration roadmap](world-exploration-roadmap.md#owner-focus-living-environments--october-29-2026)
owns the proposed connected slice; existing feature and mechanics authorities
remain in force. This direction does not establish new ecological rules.

Owner priority update, October 29, 2026: prioritize world generation, worldbuilding
and exploration that are enjoyable without an authored campaign. Generated quests
and local interactions are in scope, with saved outcomes that can support later
story connections. Early play should have a First Age feeling; this does not
automatically make early saves canon. Defer campaign implementation, including
the opening, and place AYN Thor optimization, export and device
acceptance on the far back burner. Thor remains the intended release platform;
it is not the current development gate. This supersedes earlier immediate
story-delivery and target-device optimization priorities below. Preserve existing
story canon, gameplay and validation requirements. The current delivery focus is
recorded in [the development plan](development-plan.md#current-focus--october-29-2026);
the [world/exploration roadmap](world-exploration-roadmap.md) owns the forward
cross-feature delivery sequence. Feature roadmaps retain detailed acceptance
and evidence; the reformat roadmap retains the completed migration evidence.

Owner-approved workflow, October 28, 2026: keep the connected expedition loop
central and assess exploration feel, Sol behavior/companionship, combat and visual
cohesion together in each slice. AYN Thor is the intended release platform and
audience; optimization and relevant performance regression checks happen throughout
development. The above-average development PC is a baseline, not device acceptance.
See [approved development focus](development-plan.md#approved-focus--october-28-2026)
for hardware evidence, measurement scope and remaining target-budget decisions.
The separate daily 06:00 Pacific vision audit presents a status questionnaire,
processes feedback into proposed decisions, and updates roadmaps only after explicit
owner approval. Owner direction, October 28: present questions through an
interactive questionnaire rather than prose-only question lists. The approved
[creative direction](decisions/2026-10-28-opening-companionship-and-consequences.md)
records the storm rescue, companionship, production Sol presentation and lasting
choice consequences; its roadmap changes were explicitly authorized by the owner.
Owner scheduling update, October 28: the existing vision audit now runs at 06:00
America/Los_Angeles daily, including weekends, with a creative review, ten primary
questions in an interactive questionnaire, and a report of other active project
chats/agents. Repository maintenance retains its separate 07:00 schedule and scope.

Owner direction, October 27, 2026: during the current solo development/testing
phase, old test saves are disposable. Keep explicit save, world-state and
generation versions, saved generation settings, current-format validation and
reliable save/load behavior. Incompatible development saves may be rejected with
a clear new-expedition message. Do not spend feature work on legacy generators,
migrations or old-save preservation; obsolete compatibility checks may be replaced
with current-format and incompatible-version rejection checks in the affected
feature change. Revisit compatibility before external testing or release.

Owner direction, October 27, 2026: keep implemented gameplay, simulation, and presentation tuning adjustable in Godot. Use typed exported Resource properties under `resources/` or grouped scene-root exports, with Inspector tooltips, meaningful units, valid ranges, and runtime validation. Expose the actually connected setting rather than an unused placeholder. Document whether changes apply immediately, at restart/new expedition, or to loaded saves; persist generation/identity-affecting values before using them. Keep provisional defaults labeled and avoid adding controls for unimplemented mechanics. Schema versions, identity contracts, and corruption/admission safety ceilings remain engineering constraints rather than balance sliders. See [Inspector tuning](inspector-tuning.md) for the current control map. New features should update that map in their implementation PR.

Pin the actual Godot version and any required tooling in README when the runnable project arrives. Track authored scenes, resources, project configuration, import sidecars, and UID sidecars required by that pinned version. Ignore generated `.godot/` caches and builds. Do not blanket-ignore resource metadata or rewrite resource IDs during cleanup.

For public repositories, confirm source redistribution rights before pushing third-party assets or source bundles. A local license to use assets in a game does not establish permission to publish the original source pack. Preserve supplied assets locally while that evidence is unresolved.

Review binary asset size before adding it. Adopt Git LFS intentionally for selected large binary types before tracking them; record patterns and installation requirements in the same change. Do not migrate existing history as maintenance. Record third-party asset/plugin licenses and provenance. Keep credentials out of export configuration and review presets before committing.

For documentation, check links, paths, consistency, and whitespace. For game changes, run relevant automated checks and import/parse validation using the pinned engine, then exercise the affected scene or feature. For exports, smoke-test the actual export. Record commands, results, and checks unavailable locally. Do not add meaningless tests for prose or claim a playable build exists from documentation checks alone.

The shared local/CI entry point is `tools/validate.ps1`, requiring Godot 4.7.2 stable. The GitHub Actions job is `Godot 4.7.2 import and tests` in `.github/workflows/validate.yml`. Its first remote run passed, and a failing assertion in a disposable clone confirmed that the shared validator exits nonzero. The workflow remains subject to PR review; required-check enforcement is a separate repository-settings change. Revalidate the official archive digest whenever deliberately changing the engine pin.

The validator also rejects `SCRIPT ERROR:` and `ERROR:` output even when Godot
returns zero. Expected warning fixtures remain permitted. This closes the
zero-exit script-error gap observed during October 27 affinity implementation.

### Routine creature integration and proportionate checks

Owner direction, October 28, 2026: learn and reuse the creature-authoring process
instead of repeating extensive testing for every addition. This is the local
workflow for ordinary content changes; configured CI checks remain unchanged.

1. Read the selected species sheet and owner decisions. Preserve its class,
   first-form/size direction, independent individual affinity and approval scope.
   Reuse already-recorded mechanics evidence when rules are unchanged; consult
   SolHunterSource again for an actual mechanics change, conflict or unanswered rule.
2. Reuse the existing species-resource pattern and shared presentation factory.
   Check/reserve unique species and lineage keys; connect the scene, provisional
   reference stats, existing moves, ecology and explicit traversal policy. Register
   the record in the shared catalog and the normal sighting preset. Add an owned
   idle branch/caption when a signature gesture exists. Keep later forms and final
   balance open until authored; do not replace unrelated identities or starters.
3. Validate the changed content through an existing focused catalog or integration
   smoke test. Prefer one journey covering admission, encounter/capture, party,
   preview/following and save/load to separate repeated tests of each layer. New
   anatomy or changed support/animation code warrants its targeted model/movement
   checks; a routine record, placement or art-tuning edit does not warrant every
   terrain, weather, combat and world suite. Do not duplicate authored stat/shape
   values into tests or invent tests for prose.
4. Import/parse new scripts/resources when needed, then inspect one useful actual
   game/menu render for visual changes. Reuse the workshop and existing fixtures;
   do not regenerate a full pose gallery or retest unchanged systems each time.
5. Update the canonical species sheet/index and connected Inspector map. Review
   the scoped diff and report the focused result and real limitations. Broaden
   validation only for shared-system/schema/generation changes, a new failure or
   unresolved risk relevant to this change. A known unrelated full-suite failure
   is recorded once, not repeatedly rediscovered on each content edit.

This supersedes blanket per-creature instructions to rerun `tools/validate.ps1`
locally for every ordinary content addition. Use the full validator when the
change or integration checkpoint actually calls for broad regression evidence;
do not claim a focused pass is a full pass or weaken configured CI requirements.
The existing `tests/sol_species_catalog.gd`, `tests/sol_game_rollout.gd` and
`tests/sol_anatomy_integration.gd` demonstrate the reusable admission/journey path;
`tests/sol_anatomy_batch.gd` is for the new body plans, not a mandatory rerun for
every future creature data edit.

## Daily maintenance at 7:00 AM Pacific

The scheduled chat maintenance runs daily at 07:00 America/Los_Angeles, including weekends. Inspect before changing anything:

1. Read this standard, `ROADMAP.md`, and current status; advance the next unfinished organization milestone when safe. Check for concurrent work and preserve its files.
2. Inspect local status, remotes/upstreams, branches, and recent history. Fetch when accessible; inspect PRs and checks through available access. Record access failures accurately.
3. Identify organization drift, stale documentation, conflicting standards, and branch/PR issues. Make small reversible corrections within scope; avoid churn when nothing changed.
4. Validate changes, review the diff, and commit only maintenance-owned files on an appropriate branch when safe. Leave blocked work intact with a concrete next action.
5. Replace the maintenance status snapshot when findings change. Report meaningful changes, failures, and required decisions; stay quiet on unchanged, non-actionable runs.

Routine maintenance never includes destructive cleanup, forced updates, automatic merges, remote permission changes, game implementation, or edits to the Bible. Surface those as specific owner decisions when needed.

## Policy changes

Update this document in the same change as an adopted layout/workflow change. Distinguish policy from observed enforcement, and remove superseded guidance rather than appending contradictory exceptions. Record substantial governance decisions under `docs/decisions/`; keep this file the operative standard.

Owner direction, October 29, 2026: consolidate labs and previews through
`scenes/development_workstation.tscn` as the shared visual/debug review surface.
Reuse fixture scenes; isolate their 3D world, block expedition save/load when
hosted, and pair screenshots with notes and measurements. The main game entry
remains separate. Owner follow-up, October 29, 2026: temporarily allow F8 or the
Development lab button to toggle to that standalone lab as a separate world.
Keep the expedition in memory, suspended and restored on return; retain lab
controls/notes between visits and the hosted-fixture save/load guard. This does
not adopt experimental lab mechanics or visuals into normal play. See
`docs/development-workstation.md` for usage and limits.

Owner direction, October 30, 2026: every new development lab must provide usable
sliders and/or knobs for numeric tuning, with visible values and useful ranges.
Use switches for booleans and selectors for discrete presets. Do not rely on
Inspector-only controls or typed numeric fields as the primary review interface.
The shared workstation supplies sliders for ranged scalar exports; expensive
fixture rebuilds apply on release, so dragging remains usable.

Owner approval and rollout, October 30, 2026: use the reviewed procedural
single-blade grass in normal gameplay across meadow, woodland, heath and marsh.
Retire the earlier grass clumps from live rendering. This supersedes the former
licensed-grass/original-clump rendering fallback; source assets remain local with
provenance intact. Keep registered cell reserves, functional specialist bodies,
weather ownership and terrain/access admission authoritative. The lab and live
world share the blade mesh builder; lab-seeded energy and authored test receivers
never enter the expedition. See the current rollout in `docs/reviewed-world-visuals.md`.

Owner follow-up, October 30, 2026: plants may share tiles with grass. Preserve the
canonical cell reserve and the functional plant's recipient anchor when adding
ground cover. All terrain tiles should blend by default, including biome,
soil/grass, trail and shore transitions. Trails need a visible surface texture
and a softened grass verge while retaining mandatory walking clearance. Use the
supplied matching surface maps and keep terrain/canonical flora admission intact.

Owner direction, October 30, 2026: develop the Sol Creator in its own standalone
Sol Lab (`scenes/sol_lab.tscn`), rather than inside the shared Development Lab.
This is an explicit exception to the shared-lab consolidation above. Prioritize
usable in-game authoring controls and saved appearance drafts as the foundation
for species/individual design and procedural variation. Keep draft appearance
experiments separate from approved species and expedition saves. The existing
Development Lab and main game retain their entry points. See [Sol Lab](sol-lab.md)
for current capabilities, limits and the delivery sequence.

Owner follow-up, October 30, 2026: launch Sol Lab from normal gameplay beside
the Development Lab control. The shared world-switch owner provides F9/Sol Lab
and return controls, suspends/restores the same expedition, and retains the Sol
workspace between visits. F8 and F9 can switch between the separate labs without
allowing either to advance the expedition. Standalone F6 use remains supported.

Owner follow-ups, October 30, 2026: complete the Sol Lab authoring workflow and
provide at least three editable body-shape starting points per current class
(54 across 18 classes). These are anatomy studies, not roster admission. Sol
visual cores are confirmed canon as parameterized wispy particle balls, using the
existing particle approach. Owner clarification: “head” meant visual core, which
need not be an anatomical head. Keep core placement separate from optional head
anatomy in the lab, catalog creatures and legacy/fallback bodies. Preserve distinct
species bodies, individual affinity independence and existing mechanics. The
Worldbuilding Bible and Sol Bible record the clarified canon.

Owner direction, October 30, 2026: extend the approved plant maker variety into
live plant presentation. Shared procedural builders live under `scripts/scenery/`;
plant labs consume them. Canonical biome/role/class slots select a bounded seeded
palette for trees and specialist plants, with enabled authored library designs
preferred. Preserve the reviewed procedural grass, geography/access admission,
canonical reserves and saved ecological rules. Underwater generation remains deferred.

Owner follow-up, October 30, 2026: retire all old plant bodies from live expedition
rendering, including legacy tree/specialist fallbacks and pond/biome vegetation.
Use the plant library/shared procedural palette and reviewed blade grass only.
Rejected placement stays empty; preserve canonical membership and reserves.
Aquatic replacement remains deferred. Keep source/provenance assets on disk.
