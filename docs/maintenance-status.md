# Repository maintenance status

Last inspected: 2026-10-26 (America/Los_Angeles).

## Verified Git and ownership state

- Checkout: `C:\Users\elija\Documents\GitHub\SolHunterGodot`; current maintenance branch: `codex/git-validation`.
- Origin: `https://github.com/eliBrownn/SolHunterGodot.git`; public repository, default branch `main`, authenticated push/admin access reported by the GitHub connector.
- Remote was verified empty before bootstrap. It now has `main` at `ac656ce7eba063a303e0c93c1001f385647181d4`, matching the local integration commit and remote HEAD. Local `main` tracks `origin/main`.
- The app's other chat in this checkout was idle before maintenance. Prototype code, tests, and Bible contents were preserved. A separate maintenance branch was created after the baseline was committed and pushed.
- Maintenance baseline: `bb7f316`. Reviewed prototype baseline: `ac656ce`. Working-tree status was clean after bootstrap, before the current CI/documentation changes.
- Initial `main` was pushed without force. No PR merge, branch deletion, release, or repository-settings change has been performed.

## Completed work and evidence

- M0 organization baseline complete: authority links and daily 07:00 Pacific schedule established; ignore behavior verified for generated files/secrets and retained source/UID/import metadata.
- Candidate inventory reviewed: no secret/save filenames or known private-key/token signatures found by a heuristic scan. This is not a guarantee that all possible secrets are absent.
- Bootstrap preserves the Bible and supplied vendor metadata verbatim, including their existing whitespace. Source baseline checks accept Windows CRLF and existing extra terminal blank lines; new maintenance edits passed strict staged whitespace checks. No gameplay files were reformatted solely for bootstrap.
- Largest supplied asset observed: `assets/basic-pack/Scene Overview.png`, 836,279 bytes. Current asset sizes do not justify adopting LFS as part of this maintenance change.
- Added `tools/validate.ps1`: pinned version check, headless import, smoke suite, generation suite, and failure exit codes. README documents invocation.
- Verified engine: `4.7.2.stable.official.ed1daf0bf` at `C:\Users\elija\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
- Validation passed outside the sandbox: import; 2,331 smoke checks with zero failures; 209 generation checks over ten seeds with zero failures. The missing-engine probe correctly returned exit code 1.
- A separate fresh clone of remote main at `ac656ce` passed the same import and 2,540 checks and remained clean after validation. Temporary checkout: `C:\Users\elija\AppData\Local\Temp\SolHunterGodot-validation-e3e0b016ab0a486d918bb6affa6b55bb`.
- Sandboxed validation could not write normal Godot user data and was stopped after save-related errors; successful runs used normal access. No game-code fixes were needed. Neither run establishes CI, manual playtesting, or performance acceptance.
- Added the proposed Windows CI workflow with a ten-minute timeout, read-only contents permission, pinned checkout action revision, and the official Godot 4.7.2 archive SHA-256 verified from the release API. Workflow YAML parsed successfully. No source/build artifact upload is configured.
- GitHub returned an empty repository ruleset list. The connector's branch-protection read returned 403 (`Resource not accessible by integration`); traditional branch protections remain unverified despite the metadata reporting account admin permission.

## Next actions and blockers

1. M0 and M1 are complete. Review the CI maintenance PR, verify its remote run, and establish real failure behavior before requiring its check.
2. Public source redistribution rights for the Cainos pack were confirmed by the owner in this chat on October 26, 2026, and recorded in its provenance. The supplied archive did not include a standalone license; the confirmation does not amend its original terms.
3. Adopt PR/review/check protection settings through a distinct owner-authorized change with sufficient administration access; do not treat the current policy as enforcement.
4. Manual journey acceptance, representative performance profiling, and release/export work remain separate pending milestones.

Read `ROADMAP.md` for completion gates. Update this snapshot only when findings change; daily maintenance remains scheduled for 07:00 America/Los_Angeles.
