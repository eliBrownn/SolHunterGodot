# Repository management roadmap

Scope: Git health, organization, contribution workflow, and repeatable validation for SolHunter Godot. This is the execution plan for [the project standard](docs/PROJECT_STANDARD.md), which remains the workflow authority. Gameplay priorities and design decisions belong to the Bible and development planning.

Work in milestone order. Check an item only when its completion evidence exists; record remaining blockers in [maintenance status](docs/maintenance-status.md). Dates are intentionally dependency-based rather than promises about unavailable remote access or owner decisions.

## M0 — Establish the organization baseline

- [x] Create the authoritative project standard and link it from README and AGENTS.md.
- [x] Add a pull request template and generated-file ignore rules.
- [x] Schedule maintenance daily at 07:00 America/Los_Angeles.
- [x] Create this ordered roadmap.
- [x] Reconcile current ignore rules with the standard: inspect secret/export credential handling without masking intended source files.

Completion evidence: policy and entry points agree, the daily schedule is active, and `git check-ignore` confirms caches, captures, builds, environment secrets, and export credentials are ignored while script/UID/import sidecars and `.env.example` remain eligible for tracking.

## M1 — Preserve the current work and establish Git history

Priority: current. Local branch: `codex/exploration-plane`; maintenance baseline commit: `bb7f316`.

- [x] Coordinate with any active implementation work before staging or switching branches.
- [x] Restore remote inspection and confirm origin's history, default branch, and access rights. A missing tracking ref is not proof of an empty remote.
- [x] Review the intended source inventory, Bible, asset provenance/licensing, large binaries, and potential secrets. Keep generated caches, captures, builds, and saves out of history.
- [x] If origin has history, reconcile in an isolated checkout without overwriting local work. If origin is empty, prepare an intentional bootstrap commit with an explicit reviewed file list.
- [ ] Commit only agreed, reviewed content; establish the integration branch and upstream consistent with the verified remote state.
- [ ] Push through the appropriate bootstrap or topic-branch path, then verify the remote commit matches the intended local commit.

Completion evidence: a recorded branch and commit, verified remote reachability and push status, and all remaining local changes accounted for. Never sweep up untracked work merely to make status clean.

Current evidence: app inventory showed the other chat in this checkout idle. Unsandboxed `git ls-remote --symref origin` succeeded with no refs; the GitHub connector independently returned no branches, default branch `main`, public visibility, and push/admin permission. Maintenance baseline `bb7f316` contains seven named maintenance files. The owner subsequently confirmed public source redistribution rights for the supplied art pack; its provenance records that confirmation. The explicit prototype bootstrap inventory comprises README, assets, development notes, the Bible, project configuration, resources, scenes, scripts with UID sidecars, tests/fixtures, and the asset importer. Generated cache, captures, and builds remain excluded.

## M2 — Make contribution review enforceable

Depends on M1.

- [ ] Confirm branch naming, integration target, merge strategy, and who reviews in the current solo/collaborator setup.
- [ ] Exercise the PR template with a focused maintenance change and verify its diff contains only intended files.
- [ ] Inspect GitHub rules and document actual enforcement separately from policy targets.
- [ ] Have the owner adopt the applicable PR, review, force-push, and deletion protections through an explicit repository-settings change.
- [ ] Verify the resulting rules and document unavailable capabilities or exceptions.

Completion evidence: a reviewed example PR and a verified protection summary. A written standard alone does not complete this milestone. Required check names are added only after M3 supplies working checks.

## M3 — Make validation reproducible

Depends on M1; can proceed alongside M2.

- [x] Verify the README's Godot 4.7.2 environment and record a reproducible installation/version check.
- [ ] Run the documented headless import, smoke, and world-generation checks on a clean checkout; record results and prerequisites.
- [x] Define one repeatable validation entry point using those existing checks, with meaningful failure exit codes.
- [ ] Add CI using the verified engine version and required asset/import setup; do not expose credentials or upload proprietary source assets as public artifacts.
- [ ] Verify a passing run and that an actual validation failure blocks the check, then select the working check names for branch rules.
- [ ] Keep manual playtesting, presentation acceptance, and target-hardware performance measurements explicit where automation cannot establish them.

Completion evidence: a fresh checkout can reproduce checks and CI reports the same checks accurately.

Preparation evidence: `tools/validate.ps1` verifies Godot 4.7.2 stable, imports the project, and runs both suites. On the current working tree it passed 2,331 smoke checks and 209 generation checks across ten seeds. A missing-engine probe returned exit code 1. These are working-tree results, not clean-checkout or CI evidence; the full milestone remains open.

## M4 — Keep project growth organized

Depends on M1; apply incrementally as content arrives.

- [ ] Audit source/resource locations against the standard without cosmetic bulk moves.
- [ ] Verify resource paths and UID/import sidecars after any necessary relocation.
- [ ] Record third-party asset and plugin provenance, licenses, and regeneration prerequisites.
- [ ] Decide whether measured binary sizes justify LFS; adopt selected patterns before adding affected new assets if needed.
- [ ] Record major organization decisions and update the standard in the same change.

Completion evidence: new contributions have clear destinations, references resolve, and no competing authoritative documents or accidental generated artifacts are tracked.

## M5 — Establish release and recovery practice

Depends on M2 and M3, and an owner-approved build worth releasing.

- [ ] Document the export target, tooling, output location, and clean-checkout build procedure.
- [ ] Smoke-test an actual export and record its source commit and known limitations.
- [ ] Use owner-approved version tags and release notes linked to the tested commit.
- [ ] Document recovery using revert commits and a fresh checkout; preserve player saves and source assets.
- [ ] Review merged branches for cleanup eligibility without automatic deletion.

Completion evidence: one reproducible, traceable release and a documented recovery path. Housekeeping does not authorize publishing releases or deleting branches.

## Ongoing — Daily maintenance

At 07:00 Pacific, follow the project standard, review the next unfinished milestone, and advance safe organization work within this chat's authorized scope. Check Git/PR health, documentation drift, and available validation evidence. Update the current maintenance snapshot when facts change; report meaningful outcomes or blockers and stay quiet when nothing actionable changed.

Do not mark a milestone complete because time passed, documentation exists, or a command was attempted. Attach the evidence needed to support completion. Preserve existing work whenever access, concurrency, or ownership is unresolved.
