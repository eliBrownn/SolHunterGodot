# SolHunter Godot project standard

Status: authoritative organization and contribution policy.
Established: 2026-10-26. Owner: project owner; steward: daily Git maintenance in this chat.

## Authority and scope

This is the single source of truth for repository organization, Git practices, and maintenance. README and agent instructions link here instead of duplicating policy. Explicit owner decisions take precedence; record durable changes here with their reason and date. Resolve conflicting instructions before acting on the affected work.

`docs/reference/SolHunter_Worldbuilding_Bible.md` governs game design. Preserve confirmed, provisional, and deferred distinctions. Repository housekeeping must not revise canon or turn unresolved designs into requirements. Other SolHunter repositories are outside this maintenance scope.

Owner direction, October 26, 2026: use [SolHunterSource](https://github.com/eliBrownn/SolHunterSource) to resolve game-mechanics questions outside the world-generation engine. Read its relevant implementation, tests, and decision evidence before proposing replacement rules or escalating an apparent gap. See [mechanics reference](mechanics-reference.md) for verified source locations and reconciliation procedure. This permits read-only reference use; it does not authorize maintenance of that repository or replacement of Godot world generation. Preserve explicit Bible canon and flag unresolved source conflicts rather than silently overriding it with legacy behavior.

## Repository layout

Owner visual direction, October 26, 2026: retain a 3D world with the low,
axis-aligned camera while preserving the 2D pixel-art look. Favor original
nearest-filtered terrain/prop textures and upright sprite foliage/characters;
do not replace the established artwork with a smooth low-poly aesthetic by
default. See [the visual direction decision](decisions/2026-10-26-pixel-art-3d.md).

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

Owner direction, October 27, 2026: keep implemented gameplay, simulation, and presentation tuning adjustable in Godot. Use typed exported Resource properties under `resources/` or grouped scene-root exports, with Inspector tooltips, meaningful units, valid ranges, and runtime validation. Expose the actually connected setting rather than an unused placeholder. Document whether changes apply immediately, at restart/new expedition, or to loaded saves; persist generation/identity-affecting values before using them. Keep provisional defaults labeled and avoid adding controls for unimplemented mechanics. Schema versions, identity contracts, and corruption/admission safety ceilings remain engineering constraints rather than balance sliders. See [Inspector tuning](inspector-tuning.md) for the current control map. New features should update that map in their implementation PR.

Pin the actual Godot version and any required tooling in README when the runnable project arrives. Track authored scenes, resources, project configuration, import sidecars, and UID sidecars required by that pinned version. Ignore generated `.godot/` caches and builds. Do not blanket-ignore resource metadata or rewrite resource IDs during cleanup.

For public repositories, confirm source redistribution rights before pushing third-party assets or source bundles. A local license to use assets in a game does not establish permission to publish the original source pack. Preserve supplied assets locally while that evidence is unresolved.

Review binary asset size before adding it. Adopt Git LFS intentionally for selected large binary types before tracking them; record patterns and installation requirements in the same change. Do not migrate existing history as maintenance. Record third-party asset/plugin licenses and provenance. Keep credentials out of export configuration and review presets before committing.

For documentation, check links, paths, consistency, and whitespace. For game changes, run relevant automated checks and import/parse validation using the pinned engine, then exercise the affected scene or feature. For exports, smoke-test the actual export. Record commands, results, and checks unavailable locally. Do not add meaningless tests for prose or claim a playable build exists from documentation checks alone.

The shared local/CI entry point is `tools/validate.ps1`, requiring Godot 4.7.2 stable. The GitHub Actions job is `Godot 4.7.2 import and tests` in `.github/workflows/validate.yml`. Its first remote run passed, and a failing assertion in a disposable clone confirmed that the shared validator exits nonzero. The workflow remains subject to PR review; required-check enforcement is a separate repository-settings change. Revalidate the official archive digest whenever deliberately changing the engine pin.

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
