# Combat phase 3 owner session

Status: prepared, **not yet played or accepted by the owner**. October 28, 2026.
This uses the [v2 development fixtures](combat-pacing.md), not production boss
content. Keep duration/action-count targets open until this first measured session.

Start from the repository root, using the Godot 4.7.2 console executable:

```powershell
./tools/combat_pacing.ps1 -Godot 'C:/Users/elija/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe' -Session
```

The session opens four separate disposable expeditions in order:

1. Ordinary with unchanged presentation timing.
2. Ordinary with concise presentation timing.
3. Terrain with concise timing.
4. Major development probe with concise timing.

Use the existing mouse/controller combat controls. Choose deployment, movement,
and moves yourself. Inspect tooltips, opponent intent and the battle log as needed.
The later [shared budget](combat-action-budget.md) keeps moves within the same
turn: watch AP/free movement, combine actions, then choose End turn explicitly.
This session now exercises those new rules; earlier timing tables are historical.
No scripted policy runs in this session. Capture is disabled for synthetic probe
identities. These are synthetic battle overlays over normal scenery, not a world
traversal or production encounter-authoring acceptance test.

After each terminal outcome, an optional in-game questionnaire asks about pace,
clarity, and which choice mattered or became repetitive. Save notes and exit to
continue, or skip them. Controller Back/window close skips notes. F8 during battle
records an unfinished attempt and exits; ending an attempt does not pretend it won.
No response is preselected as owner acceptance. Native timing/readability reports
remain separate from the choice to accept the fixture.

Each run writes its report, optional answers, timing/rule settings, fixture/policy
version, source hashes and patch under `artifacts/combat-pacing/<time>-<fixture>-<timing>/`.
The real choice time is recorded separately from presentation holds, trainer
departure and paused inspection/menus. A normal expedition save is never loaded.

Review these observations after playing:

- Could you follow each actor, HP change, terrain effect and return of control?
- Which ordinary timing felt concise while leaving enough time to read?
- Did the terrain route offer a worthwhile choice? After an initial attempt,
  compare walking around the wall with preparing Thin Passage and crossing it.
- Did preparation, range, and enemy Heat make the major battle earn its extra
  decisions? After an initial attempt, compare Focus during a safe approach with
  attacking directly. More feedback time by itself is not a better major battle.
- Did healing, harmless exchanges or unreachable positions stop progress?

Then use the actual reports and feedback to propose numerical duration/action
targets and the next fixture revision. Phase 3 closes only when the owner accepts
a quick ordinary encounter and a longer tactically meaningful major fixture.
Automated scripted results and controller-event tests do not supply that decision
or AYN Thor device acceptance.
