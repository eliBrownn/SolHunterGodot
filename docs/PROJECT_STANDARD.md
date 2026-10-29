# SolHunter Godot project standard

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

## Repository layout

Owner direction, October 27, 2026 supersedes the October 26 sprite presentation:
use a full 3D player and world
scenery, with the supplied rogue/animation rigs and Stylized Nature MegaKit.
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
in-game menu, using Pokémon's familiar guide/party/bag/trainer/save/options
organization as a reference. Use original SolHunter styling and retain existing
gameplay authorities. Menu layout preferences are local presentation settings,
separate from expedition saves. Owner follow-up: R toggles the live field menu;
opening it does not pause time or movement. Escape opens a separate true pause
screen after dismissing higher interaction layers. The menu uses a 0.7 size
multiplier (30% smaller), while preserving local adjustments. The game window is
resizable and starts maximized to the available screen, with no fixed physical
startup-size override. The view expands to the display aspect ratio. Player heading
changes use smooth shortest-arc visual turning.
Owner phase-4 direction: use Pokémon as a reference for companion navigation,
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
| `shaders/` | Godot shader resources for the pixel-art 3D presentation |
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
