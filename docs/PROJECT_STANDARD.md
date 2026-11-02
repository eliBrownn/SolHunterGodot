# SolHunter Godot project standard

Owner direction, October 31, 2026: the [master delivery roadmap](master-roadmap.md)
is the entry point for execution order across all roadmaps. It sequences existing
feature steps and distinguishes implementation from acceptance. The world roadmap
retains N0-N7 acceptance and intake evidence; feature roadmaps retain detailed
contracts and receipts. This standard remains the sole workflow authority.

## Current delivery scope — October 31, 2026

Owner approved a nature-only expedition gate before NPCs, requests, shops and
campaign onboarding. The [world roadmap](world-exploration-roadmap.md#nature-delivery-sequence)
owns N0-N7 sequencing; the Bible owns design. This supersedes earlier current-phase
generated-request priority and exclusions of natural leads, not story canon or
the downloaded-landmark hold. Do not create a competing workflow standard.
Readiness combat pauses local participants/hazards during planning while the
surrounding world continues; local tile ownership and outcome reconciliation
must follow the new combat contract rather than silently reusing conflicting
background writers. Scope approval is not runtime completion. Preserve unrelated
work, targeted validation and separate owner review/merge.

October 31 alpha execution: the owner authorized adjustable provisional timing,
exposure and withdrawal defaults. Runtime contracts/evidence live in
[the alpha contract](readiness-alpha-contract.md), with the existing world roadmap
retaining gate ownership. The normal main scene explicitly selects readiness;
older labs and historical turn fixtures retain their selectable turn contract.
The shared validator adds focused alpha suites without removing historical checks.

October 31 biome audit follow-up: the owner approved adjustable 1:1 conversion
from transferred Vastra units to tile concentration points for ambient overflow.
ExpeditionState owns both the conserved delivery backlog and concentration commits;
ordinary overflow caps concentration at 100 and never creates ecological overload.
The [Vastra integration contract](vastra-integration.md#ambient-overflow--october-31-2026)
records routing, technical bounds and save compatibility. This does not authorize
restoring retired aquatic plant artwork or changing geographic membership.

Owner direction, October 31: remove labs from the main game while retaining their
code and standalone scenes. Normal startup must not install the development-world
switch, lab footer buttons or F8/F9 lab handlers. This supersedes earlier temporary
in-game lab access below; standalone authoring and explicit isolated test adapters
remain available. Keep normal save/load shortcuts under their existing owner.

Status: authoritative organization and contribution policy.
Established: 2026-10-26. Owner: project owner; steward: daily Git maintenance in this chat.

## Authority and scope

This is the single source of truth for repository organization, Git practices, and maintenance. README and agent instructions link here instead of duplicating policy. Explicit owner decisions take precedence; record durable changes here with their reason and date. Resolve conflicting instructions before acting on the affected work.

`docs/reference/SolHunter_Worldbuilding_Bible.md` governs game design. Preserve confirmed, provisional, and deferred distinctions. Repository housekeeping must not revise canon or turn unresolved designs into requirements. Other SolHunter repositories are outside this maintenance scope.

Owner direction, November 1, 2026: provide a complete HTML Bible for reviewing
game vision, story, known facts and roadmap status, with diagrams, examples and
notes. `tools/build_bible_review.py` (Python with `markdown-it-py`) builds
`docs/reference/SolHunter_Worldbuilding_Bible.html` using `tools/bible_review.html`.
It includes the full Bible and the complete Markdown reference library under
`docs/`, recording source hashes. Markdown retains its existing authority;
supporting proposals/history remain labeled by their owning sources. Browser
notes and imported/exported review JSON are feedback, not canon changes. Rebuild
the review edition after an intentional source refresh; it is a dated snapshot,
not a live status service or a second workflow standard. Illustrations reference
existing repository images relative to the HTML location.

The ecosystem collection reuses existing Plants review IDs/images and adds
isolated front/rear three-quarter captures through `tools/photograph_ecosystem.py`
and `tools/capture_ecosystem.gd`. Pass `--godot` with the pinned 4.7.2 executable.
The incremental capture manifest under ignored `artifacts/ecosystem-review/`
records source fingerprints and distinguishes current content, retained studies
and text-only concepts without art. Preserve original Plants/Sols review storage,
approvals and captures; this photography neither publishes assets nor admits new
runtime content. Rebuild the Bible HTML after capture. Referenced pictures remain
local artifacts, so retain the repository/artifact layout for this local edition.

Owner direction, October 28, 2026: maintain the [Sol Bible](reference/sol_bible.md)
as the species/lineage authoring reference and roster index to populate. It develops
species details under the worldbuilding Bible's design authority; proposed entries
and existing prototypes do not become approved final-roster designs by inclusion.
Keep repository workflow in this standard and runtime content in Godot resources.

Owner direction, October 26, 2026: use [SolHunterSource](https://github.com/eliBrownn/SolHunterSource) to resolve game-mechanics questions outside the world-generation engine. Read its relevant implementation, tests, and decision evidence before proposing replacement rules or escalating an apparent gap. See [mechanics reference](mechanics-reference.md) for verified source locations and reconciliation procedure. This permits read-only reference use; it does not authorize maintenance of that repository or replacement of Godot world generation. Preserve explicit Bible canon and flag unresolved source conflicts rather than silently overriding it with legacy behavior.

## Hierarchical ownership and composition

Owner direction, November 1, 2026: normal F5 startup opens
`scenes/start_menu.tscn` with New Game, Load Game and Quit. A loading barrier
prepares a fixed 8x8 area (64 detailed terrain chunks) around the new/saved player
position. Grass/ground plant registration precedes trees, then local network
activation; the active clock and gameplay remain disabled until admission is
complete. Loading may take longer to reduce contention during play. After entry,
one chunk job proceeds at a time with a 1 ms main-thread generation allowance
and a 0.5 ms outer-chunk allowance. These are cooperative budgets, not hard hitch
guarantees. `scenes/world_3d.tscn` remains the direct standalone gameplay/test scene;
F6 bypasses the startup menu. Runtime evidence stays in `runtime-optimization.md`.

Owner-approved performance follow-up: after canonical startup admission, the
loading overlay also covers brief real draws of representative combat feedback
and the measured first-use creature variants in the active world/viewport. Dispose
of those graphics samples before enabling gameplay; they must not advance the
saved clock, receive gameplay events or create tactical actors. Existing startup
chunk/flora requirements and deliberate generation policy remain unchanged. See
`runtime-optimization.md` for scope, renderer evidence and remaining limits.

Owner direction, November 1, 2026: remove procedural Sol body animation across
wildlife, companions, combat and authoring previews. Bodies retain neutral authored
poses while existing movement replay, travel heading, terrain/traversal placement,
authored visual cores and combat flashes remain. No procedural foot solver,
breathing, appendage or action posing runs in these paths. This supersedes the
older procedural-animation implementation/control descriptions; see
[the current presentation receipt](sol-procedural-ground.md#static-sol-presentation--november-1-2026).

Owner follow-up, November 1, 2026: remove decorative Sol affinity motes, auras
and affinity-color cycling. Preserve individual affinity mechanics and UI colors,
ground shadows, combat feedback and the Bible's authored visual cores, whose tint
is independent of affinity. Wildlife admission may stage model/move-book preparation
after immediate canonical membership; ecology optimization preserves exact
transactions. Default Vastra filament path preparation may span frames while
retaining the previous complete visual network. Evidence and limits remain in
`runtime-optimization.md`; this does not reopen the broad profiling campaign.

Owner direction, November 1, 2026: use one background chunk-preparation worker
for development. Existing travel/readiness evidence is sufficient for that choice;
stop the expanded comparison/validation campaign. Focus performance work on
gameplay hitches using the measured findings in `runtime-optimization.md`.
This development decision does not establish a clean full release gate or a
measured reduction in rendering stalls. Brief scoped startup checks remain
appropriate; repeated studies need a concrete unresolved decision and permission.

### Generation experience baseline — November 1, 2026

Owner-approved standing rule: preserve the improved startup and initial-generation
experience as the development baseline. The owner reports a greatly improved
player experience with the current approach; the dated feedback and implementation
receipts live in [runtime optimization](runtime-optimization.md#owner-play-experience-feedback--november-1-2026).

- Prepare the surrounding world before handing control to the player, then
  continue generation deliberately during play. A longer initial load is an
  acceptable tradeoff for entering a populated, ready world and reducing work
  competing with gameplay. Preserve the existing startup admission requirements.
- Judge generation changes by player experience alongside measurements: world
  readiness, responsiveness, interruptions and generation order matter as well
  as throughput and average FPS. Owner play feedback is acceptance evidence for
  the experience observed; it does not establish a numerical performance gain
  or identify which individual change caused the improvement.
- Treat existing rendering-stall and wildlife-admission findings as targeted
  follow-ups when a concrete play problem or relevant regression warrants work.
  Preserve the findings and reuse applicable evidence rather than restarting
  completed investigations merely because performance work remains possible.
- Keep the current approach as the baseline for future changes. Reopening broad
  generation investigation requires a concrete unresolved problem or decision,
  an explanation of why existing evidence is insufficient, and explicit owner
  authorization for the expanded investigation/testing scope. Brief checks for
  bounded authorized changes remain appropriate under the guideline below.

This adopts the development direction; existing correctness, CI, release and
target-device requirements retain their separate acceptance criteria.

### Development guideline: use research, make bounded changes, stop at sufficient evidence

Owner direction, November 1, 2026: development must use the whole project's
accumulated research and measured results, not just the current chat. Start with
the [project research index](research/project-research-index.md), then read the
relevant owning documents and their latest dated evidence. The index locates
knowledge; it does not supersede this standard, the Bible or feature contracts.

Follow this order for each development task:

1. Identify the requested player-visible outcome, authorized scope and owning
   roadmap step. Preserve implementation/review/deferred distinctions; do not
   restart completed work or silently advance to the next roadmap step.
2. Consult applicable Bible/design decisions, feature contracts, research,
   implementation and existing receipts. For mechanics outside generation use
   the source-selection procedure in `mechanics-reference.md`. Resolve concrete
   conflicts using authority and dates, rather than treating the newest prose
   anywhere as universal authority.
3. Reuse applicable evidence. Check its source/settings/asset fingerprints,
   scenario, engine, hardware, cache conditions and dependencies. A changed input
   invalidates affected conclusions, not every unrelated project result. If
   applicability is uncertain, record that uncertainty before commissioning more
   research or measurement.
4. Select the smallest useful change with a clear expected benefit. Reuse
   established owners, hierarchies, resources and caches. Cosmetic cleanup is
   maintenance, not an assumed performance improvement. Avoid speculative
   rewrites, duplicate systems and broad reformatting.
5. Preserve authoritative state and gameplay while optimizing derived work.
   Presentation/streaming cannot invent geography, alter canonical vegetation
   membership or create/delete conserved energy. Preserve identity, affinity,
   terrain access, save admission and local combat ownership. Keep tuning under
   existing adjustable owners. Verify prepared-asset fingerprints before blaming
   procedural fallback; do not rebake all assets without an affected input.
6. Make one coherent, reviewable change, preserving the owner's dirty files and
   design Bible. Follow this standard's branch, diff and explicit-path rules.
   Separate unrelated work and distinguish an isolated candidate from integration.
7. Choose proportionate verification from the change and available evidence.
   Brief scoped checks may accompany authorized work. Before repeated rendered
   journeys, prolonged profiling or broad validation, request permission unless
   that testing scope is already explicit. Explain the decision it would resolve,
   why existing results are insufficient, and the expected extent. Do not turn
   every small edit into a complete performance study or full-suite campaign.
8. Stop when the authorized outcome has sufficient evidence. Record the result,
   material limits, rejected attempts and unresolved questions in the existing
   owning document. Distinguish observed data, inference, proposal and accepted
   behavior. Report unrun checks honestly and let the owner decide whether more
   testing or the next implementation step is worthwhile.

For performance work, use the measured findings in `runtime-optimization.md`.
Address frame-time consistency and responsiveness as well as average FPS.
Prioritize small changes that remove measured recurring work; separately address
large stalls. Compare equivalent visible populations and settings when assessing
rendering cost. Faster population is not automatically smoother play, and lower
memory can increase regeneration work. Never add nested timings as independent
costs or present diagnostic overhead, fixture gains, one-run samples or desktop
results as whole-game/device acceptance. Preserve failed pilots and identify
instrumentation failures separately from production failures.

Keep one evidence index per owning feature. Add new findings there and link them
from the research index when needed; do not scatter competing status documents.
Reference local-only artifacts without publishing proprietary assets, saves or
private source. Refresh the research catalog after a deliberate documentation
refresh, not as an excuse to rerun experiments.

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

Owner direction, October 27, 2026 supersedes the October 26 sprite presentation:
use a full 3D player and world
scenery, with the supplied rogue/animation rigs and Stylized Nature MegaKit.
Owner follow-up, October 29, 2026: replace the default player with the supplied
female undead grave knight. Preserve player controls and height; retain the
optional mannequin traversal fixture. Asset attribution lives beside the model.
Owner follow-up, October 31, 2026: replace the grave knight as the default player
with an original low-poly, smoothly shaded adult base, without intimate anatomy.
Match the existing player's height and ground anchor; preserve movement controls.
The rigged base is the first asset for later customization, not approval of a
complete customization interface. Owner follow-up the same day rejects the
procedural prototype and supplies `Human LowPoly1.fbx` as the replacement base.
Preserve its authored topology/proportions, add the movement rig and retain the
same player scale. Source/provenance lives in `assets/characters/human_low_poly/`.
Owner follow-up: use the supplied rogue's idle/walk/run animations on this base.
Retarget its differing bind pose and bone names; authored clips own limb motion
instead of the procedural terrain gait, while actor movement retains travel.
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
stylized grass to the main game, with a live Options pixel adjustor for testing.
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
action labels without repeating that name. Owner follow-up, October 31: one
Examine action combines appearance and expanded readings, with centered text
and smoothly animated reading bars/numbers.


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
the [master delivery roadmap](master-roadmap.md) organizes the forward
cross-feature delivery sequence, with the world roadmap retaining nature gates.
Feature roadmaps retain detailed acceptance
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

Owner direction, November 2, 2026: keep the supplied human model, rogue model and
animation packs, sky source/presets and derived daylight shader local. The public
player defaults to the original `assets/characters/customizable_base/` asset and
shared player locomotion owner; the adapter exposes an opt-in local source setting.
The public sky uses original `shaders/project_sky.gdshader` and authored noise
resources under `resources/sky/`, through the existing view/atmosphere owners.
Preserve the withheld files on disk; provenance documents remain publishable.
An integration branch must not inherit unpublished commits containing these sources.
Start its reviewed snapshot from verified `origin/main`, preserving existing topic
history and the owner's pending Bible/story edits locally. This is a publication
boundary, not permission to rewrite or merge existing branches.

For public repositories, confirm source redistribution rights before pushing third-party assets or source bundles. A local license to use assets in a game does not establish permission to publish the original source pack. Preserve supplied assets locally while that evidence is unresolved.

Review binary asset size before adding it. Adopt Git LFS intentionally for selected large binary types before tracking them; record patterns and installation requirements in the same change. Do not migrate existing history as maintenance. Record third-party asset/plugin licenses and provenance. Keep credentials out of export configuration and review presets before committing.

For documentation, check links, paths, consistency, and whitespace. For game changes, run relevant automated checks and import/parse validation using the pinned engine, then exercise the affected scene or feature. For exports, smoke-test the actual export. Record commands, results, and checks unavailable locally. Do not add meaningless tests for prose or claim a playable build exists from documentation checks alone.

The shared local/CI entry point is `tools/validate.ps1`, requiring Godot 4.7.2 stable. The GitHub Actions job is `Godot 4.7.2 import and tests` in `.github/workflows/validate.yml`. Its first remote run passed, and a failing assertion in a disposable clone confirmed that the shared validator exits nonzero. The workflow remains subject to PR review; required-check enforcement is a separate repository-settings change. Revalidate the official archive digest whenever deliberately changing the engine pin.

November 1 performance measurement: `tools/profile_frame_stalls.py` freezes the
current runtime into ignored `artifacts/frame-stalls/<label>/` copies and runs
the rendered workload with pinned Godot. Timing wrappers belong only to the
diagnostic copy; production scripts, settings and palette admission stay intact.
Keep per-run source hashes, shared-asset edit checks, native exits and complete
workload reports. Failed/interrupted pilots are evidence, not accepted baselines.
`tools/report_frame_stalls.py` separates baseline frame metrics from inclusive
diagnostic timings. Record deliberate driver revisions and matching workload
identity before reusing prior samples. These desktop studies do not replace the
shared validator, functional acceptance or target-device qualification. Evidence
and repeat commands belong in [runtime optimization](runtime-optimization.md).

Owner direction, November 1, 2026: request permission before extensive testing,
including repeated rendered journeys, prolonged profiling and broad test-suite
runs, unless the owner has already explicitly authorized that scope. Present
available results and numbers so the owner can decide whether more testing is
worthwhile. Brief checks appropriate to an authorized change remain scoped;
do not extend a completed investigation into additional testing automatically.
This does not change configured CI checks or turn unrun checks into passes.

October 31 alpha validation expands the bounded CI job timeout to 90 minutes.
The measured 81-suite diagnostic continuation alone took 1,828 seconds, before
the preceding import/alpha suites; the former 10-minute job limit cannot cover
the current complete validator. Keep the existing checks and strict exit/error
handling. This timeout change permits completion on a fresh runner and does not
make an interrupted or failed run successful.

Owner direction, October 31: keep the current alpha on Godot 4.7.2 stable.
Stop preview-engine evaluation for the existing shutdown issue. Future beta
testing needs a specific, material reason, explained before running it; it is
not part of routine alpha validation. Preserve the failed native-exit evidence
and report a known engine issue separately from completed alpha implementation.

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

Owner direction, October 31, 2026: convert the development-lab restructure into
a project-local Godot editor plugin plan under `addons/solhunter_lab/`, with a
SolHunter Lab main-screen workspace and one intuitive menu. This is the target
architecture, now implemented through L5 engineering closure using a versioned
local runtime bridge for the 29 workstation fixtures and separate Sol authoring.
It is enabled in `project.godot`; owner usability acceptance remains pending.
Retain the standalone labs and the lab-free normal game. Use top-down modular
ownership matching the game. Stations own
their bindings/capabilities; the host owns common navigation and lifecycle.
Discover registered stations automatically, consume authoritative game resources
and detect dependency drift through the existing validation workflow. Keep
synthetic test state and local drafts separate from production authority. The
[Godot lab plugin plan](development-workstation.md#godot-development-lab-plugin-plan--october-31-2026)
owns measured performance work, interface simplification and staged migration.
Editor-only code stays in the addon; shared runtime owners remain outside it.
Each station declares editor-safe preview or separate runtime execution; do not
blanket-enable tool execution in production systems. The plugin must not mutate
the edited scene, shared production resources or expedition saves during preview.
This extends shared navigation to Sol Lab while retaining its standalone scene,
authoring owner, draft storage and existing launch/return paths. It supersedes
separate hosted control panels as the target interface, not the isolation rules
or Sol Lab authoring exception below. The shared catalogue is owned by
`tools/lab_station_catalogue.gd`; JSON station definitions live in the addon, while
`tools/lab_bridge_runner.gd` owns isolated execution. Editor preferences stay local
under `.godot/editor/`; bridge sessions use a separate local workstation store.
Disabling the plugin saves/closes its helper, and source reload starts a fresh
helper. The enabled editor export hook excludes lab/editor/test/tool files before
GDScript bytecode generation, retaining the bake source used by PlantLibrary’s
signature contract. Full release export/device qualification remains separate.
Automatic upkeep does not authorize autonomous code edits or publishing tuning.

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

Owner follow-up, October 31, 2026: grass uses thinned procedural leaves across
meadow, woodland, heath and marsh; foliage remains a separate body population.
This supersedes the earlier same-day foliage-as-grass replacement. Retain the blade builder
for existing studies and preserve source/provenance assets. Canonical cells,
reserves, functional bodies, weather ownership and terrain/access admission stay
authoritative. Leaf grass fills admitted emanator cells. The October 31 playtest
follow-up also permits cosmetic grass around larger plants in their cells,
excluding solid bases and exposed roots. The primary plant retains its existing
role, reserve and intake; extra visible clumps never create emanator supply.
This supersedes the October 30 live single-blade rollout.
Lab-seeded energy and authored test receivers remain isolated from expeditions.
See the current rollout in `docs/reviewed-world-visuals.md`.

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


Owner direction, October 31, 2026: retain the close-up plant gallery at
`artifacts/plant-closeup-review/index.html` as the continuing plant review document.
Keep stable review IDs, original pictures, revision comparisons and exported owner
notes. The tracked roster/draft instructions live in
`docs/reference/plant_review_registry.json`; regeneration tools are indexed in
`docs/procedural-plants.md`. Marked candidates request revisions; a proposed
revision becomes a new generation baseline only after the owner's visual selection.
Bushier foliage takes M35 as its reference; selected candidates receive varied
leaves, with S07 retaining its leaf design while its supporting body is rebuilt.
Publishing requires an explicit owner visual selection. On October 31 the owner
accepted M20, H10, S04, S07, S33 and S34 without further notes; their reviewed
bodies are the active generation baselines. Accepted entries with written notes
still require those changes. The owner subsequently approved all nine round-02
revisions (M12, M15, M19, H11, H12, H33, S10, S18 and S19), completing approval
of all 15 selected plants. Preserve ecological identities and admission rules.


Owner direction, October 31, 2026: expand the ongoing web review document to
Sols and make both sections intuitive. Plants and Sols share a searchable catalog,
one-item preview, angle/version selectors, decisions, notes and per-domain
preferences. Keep existing review IDs, browser storage namespaces and approvals;
web review choices do not publish models automatically. The shared template is
`tools/review_hub.html`, built by `tools/build_review_hub.py` into the existing
local review URLs. Sol catalog captures remain appearance review only.
