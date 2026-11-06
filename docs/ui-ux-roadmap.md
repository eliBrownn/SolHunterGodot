# SolHunter UI/UX roadmap

Desktop direction: October 27, 2026. Mouse acts on the world, combat and NPCs;
keyboard controls the player and personal systems. Personal menus remain clickable.
This is a feature plan; [PROJECT_STANDARD.md](PROJECT_STANDARD.md) remains the
workflow authority and the Bible remains the design authority.

## Approved opening and relationship UX — October 28, 2026

Approved follow-up: teach movement and sprinting during storm escape. Afterward,
the rescuers' NPC owner permits keeping one: interactions suggest a bond and the
player confirms the choice. Present the first protective mask, basic instruction,
teaching battle and onward objective to find the first refuge camp. The first
journal discovery connects observed Sol behavior to a habitat clue. See the
[follow-up specification](decisions/2026-10-28-opening-companionship-and-consequences.md#approved-follow-up--tutorial-and-visual-identity);
exact prompts, protection feedback and failure/retry rules need authoring.

The [creative decision](decisions/2026-10-28-opening-companionship-and-consequences.md)
adds campaign onboarding through waking in a Vastra storm, attempting escape,
following three Sols to safety and continuing with one as the starter. Plan
readable guidance and starter comparison/selection that retain the actual rescued
individual's identity. Storm danger, failure/checkpoint behavior and exact prompts
remain open; neither the current starter chooser nor the refuge journey completes
this prologue. Keep the desktop/controller contract and accessibility work central.

Show curiosity and personality during companionship and make respectful wild
approaches understandable. Distinguish observed behavior, recorded history and
known trust from unknown evidence; capture never implies affection. Journal/lore
discoveries should support the adventure/combat loop, with actual triggers authored
separately rather than invented by UI work.

Production previews must show each species' eventual model/animation and the
selected individual's affinity; current orbs are placeholders. Later legendary
choice UX must explain permanent ascension loss and the authored lasting
relationship/story consequences before commitment. Exact warnings, consequences
and external save-rollback restrictions remain unresolved. Do not implement a
new online/account requirement or claim the ending is already present.

## Audit checkpoint — October 28, 2026

Original audit snapshot, before the blocker implementation below:
seven existing UI suites were rerun: **203 checks passed**. Earlier full-suite
counts below are historical run snapshots, not cumulative completion or Thor acceptance.

- Phases 1–3 have a verified desktop implementation; user/device acceptance remains open.
- Phase 4 follow-up resolves the reproduced stale training display and extends
  the existing text preference across the screen-space HUD. Focus and scroll
  continuity, actual controls and viewport reachability are covered below.
  Physical-device and complete controller accessibility acceptance remain open.
- Phase 6 is partly implemented: local menu preferences persist; camera/graphics
  settings are session-only. Controller remapping now persists locally; reduced effects and onboarding remain open.
- Thor input mapping, access to hover details without a mouse, actual device/export
  usability, and menu/preview performance measurements are not yet accepted.

The original refresh/scaling gaps are addressed in the blocker pass below.
Keep handheld design choices provisional until owner decisions settle.
Probe evidence: `artifacts/roadmap-audit-ui_roadmap_audit_probe.log`;
suite evidence: `artifacts/roadmap-audit-*.log`. This audit did not rerun the full
project validator or perform a new rendered/device acceptance run.

## Controller support and game UI/UX — approved fallback

Owner clarification, October 28, 2026: the fallback priority is **controller input
handling and the game UI/UX around it**, after active owner-directed UI work or
when that work is waiting on another decision. This corrects the earlier wording
that made physical handheld acceptance itself the fallback task. AYN Thor remains
the release target; device/export performance acceptance is a separate requirement.

Controller support must cover exploration, camera, world/Sol/NPC interaction,
combat placement/targeting/actions, personal menus, readable Sol information,
confirmations, save/load and settings. Desktop mouse/keyboard behavior remains
supported. Preserve the live-menu versus true-pause distinction.

Implementation/acceptance checklist:

- Action-based mappings, analog deadzones, camera sensitivity and remapping;
  handle connection changes without stuck input or accidental commands.
- Separate gameplay input from UI focus navigation. Menu focus must not also move
  the player or spend a combat action; confirm/back must have consistent scope.
- Explicit focus paths and focus restoration after tabs, modals or rebuilt rows;
  visible selection and predictable list/detail scrolling.
- Controller-readable prompts that follow the active input device and bindings;
  accessible inspect/details actions for information currently exposed by hover.
- Complete controller-only expedition/UI journeys on a desktop controller first,
  then validate the target export and physical Thor. Do not treat desktop success
  as device acceptance or assume unapproved button layouts/performance budgets.

Current implementation: a dedicated controller router provides exploration, target
selection, inspection, combat, menus, confirmations, save/load and settings. Focus
and remapping are separate from desktop controls. Injected joypad journeys cover
the current expedition; physical-controller and Thor acceptance remain open.
See [controller input](controller-input.md) for controls and validation scope.

Research references: [Godot controller input](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html),
[Godot focus/navigation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html),
and [Xbox UI navigation guidance](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112).
These inform the routing and focus implementation; physical device acceptance remains separate.

## Input contract

Owner-approved October 28 focus: assess menus, world interactions and combat as
one coherent expedition experience with a distinct visual identity. Feel and
readability are acceptance criteria throughout development. AYN Thor is the release
target; include device input/layout acceptance and ongoing relevant performance
checks in this roadmap. Existing mouse/keyboard controls remain the current
desktop contract; a handheld input mapping still needs specification and device
validation. See the [approved development focus](development-plan.md#approved-focus--october-28-2026).

- WASD/arrows walk, Shift runs. C opens Sols; J opens the Field Guide;
  Escape navigates interaction layers and opens the separate true pause screen. Existing save/load and refuge recovery
  remain personal commands. R now toggles the live field menu; F no longer chooses a nearby world target.
- Hover identifies the pointed cell/subject. Left-click performs the first enabled
  context action in exploration. Right-click offers actions for the pointed target, including
  separate named actions for overlapping Sols. Stale actions revalidate identity,
  range, expedition and encounter state. Existing automatic warned encounters remain.
- In combat, click a blue release/movement tile or click a move card and its target.
  Hover previews; invalid targeting retains the armed move. Right-click inspection
  never spends an action. End turn, Seal and Retreat are explicit clickable actions.
- Escape closes a context menu, cancels targeting, or toggles the battle menu.
  It never retreats. Retreat requires mouse confirmation bound to the same session.
- GUI receives pointer events before the world. Context menus and battle dialogs
  block world/camera commands. Double-click suppression is verified for world tile
  commands; blanket protection for every GUI action has not been established.
- Camera orbit/zoom/reset are view controls. Frame battlefield is an explicit
  battle-menu action; it does not move either unit or change saved state.

## Implementation sequence

| Phase | Scope | Exit evidence | Status |
| --- | --- | --- | --- |
| 0 | Audit existing inputs and preserve current work | Input contract above; existing context identity guards retained | Complete |
| 1 | Shared interaction foundation: target locking, GUI isolation, layered Escape, modal lifecycle, shared theme | Regression checks for cancellation, stale dialogs, click-through and camera isolation | Implemented; automated/rendered checks passed |
| 2 | Exploration: pointed-target prompt/ring, right-click actions, retire nearby-target shortcuts | Hover is read-only; actions retain selected identity; keyboard cannot engage/observe | Implemented; automated/rendered checks passed |
| 3 | Mouse-first combat: deployment/movement/cards/targeting, explicit buttons, safe retreat and optional framing | Full pointer journey; preview/commit parity; compact layout and rendered checks | Implemented; automated/rendered checks passed |
| 4 | Personal systems: companion list/detail, shared text sizing and responsive layouts | Party/storage/move tasks at enlarged text settings | Desktop refresh/scaling blockers implemented and checked; fitted model, whole-HUD text and live stat refresh present; controller/device acceptance remains open |
| 5 | NPC/dialogue integration when implemented | Same target/action model; no dialogue click-through | Planned |
| 6 | Persistent settings, remapping, reduced effects and onboarding | Preferences survive restart; prompts follow bindings; uncoached introduction | Partial: local menu preferences persist; camera/graphics persistence, remapping, reduced effects and onboarding remain open |
| 7 | Complete exported-build usability acceptance | Representative players/devices; dense/moving targets, long names, night/rain | Planned |

Each phase uses focused regression checks, the pinned Godot import/shared validator,
and rendered evidence where layout changes. Passing scripts does not establish
physical-device or new-player acceptance. Companion list/detail redesign, shared HUD text scaling and live stat refresh
are implemented. Complete device accessibility acceptance remains open; NPC mechanics and future
menu options are not fabricated here.

## Mechanics evidence

Read-only local SolHunterSource branch development/world-redesign-0.2 at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` was consulted:
`src/systems/tactics/live_encounter.py` (select_tile, arm/action behavior),
`tests/test_combat_pointer_consistency.py`, and
`docs/coordination/combat-architecture.md`. They support read-only pointer previews,
click-based placement/movement and domain-owned execution. Escape/menu/confirmation
changes are the owner's presentation direction; they introduce no combat rule.
Godot TacticalBattle and ExpeditionState retain action and persistence authority.

## Review and validation record

Godot 4.7.2 import and tools/validate.ps1 passed: 11,102 checks across 33
reported suites, including both scene journeys. tests/mouse_first_ui.gd passed
28 checks in headless and rendered runs; tests/combat_polish.gd passed 23 checks
in both modes. The new suite covers actual GUI move-card clicks, modal shielding,
retired tactical keys, layered Escape, keyboard rejection in retreat confirmation,
read-only hover/framing, right-click inspection and committed/stale retreat receipts.
Existing world_interactions checks retain identity/range/stale-target coverage.

Rendered exploration, deployment, battle menu, retreat confirmation and combat
screens were inspected, including the 900×600 compact capture. Evidence is under
ignored artifacts/mouse-first-ui/ and artifacts/combat-polish/; full output is
artifacts/ui-validation-final.log. Initial restricted runs could not write Godot's
user logs/settings; validation was rerun successfully with the required access.
The older presentation test now selects a visible pickable release tile instead
of an obscured tile; scenery picking remains authoritative.

Human/device acceptance, large-text layouts and optional alternative tactical
inputs remain follow-up work. Native text at compact window sizes still needs the
phase 4 scaling pass. No exported-build or new-player acceptance is claimed.

Existing dirty files were preserved on codex/mouse-first-ui. Changes are left
uncommitted because this checkout includes substantial earlier uncommitted work;
no unrelated paths are staged, and the Bible is untouched by this task.

## Owner follow-up: window, live menu and heading

R toggles the field menu without pausing exploration or interrupting movement.
Escape closes an open field menu and opens the separate true pause screen;
Escape resumes. Context/target cancellation remains the first layer. The compact
menu multiplies existing local scale by 0.7. Window resizing and smooth shortest-arc
player heading are covered by tests/live_menu_window.gd. Existing encounter pause
ownership remains in place.

Follow-up validation passed Godot 4.7.2 import and all 11,127 checks across 34
reported suites, including both scene journeys. tests/live_menu_window.gd passed
24 checks headless and rendered; tests/field_menu.gd passed 30 in both modes.
Rendered pause, compact-menu and resized-window screenshots were inspected.
Evidence: artifacts/live-menu-validation-final.log, artifacts/live-menu/ and
artifacts/menu/. This establishes scripted/window-layout acceptance; no exported
build or new-player acceptance is claimed.

## Automatic screen fit

Fixed physical startup-window overrides were removed. The game starts maximized
on the available display and expands the view to the current aspect ratio, while
remaining resizable. Existing UI anchoring, menu clamping and pointer projection
are retained. Display changes apply at the next launch.

Validation: Godot 4.7.2 import and all 11,132 checks across 34 reported suites
passed. Rendered live-menu/window checks passed 29 assertions, including wide and
tall layouts; rendered combat polish passed 23. A standalone startup probe measured
maximized mode with an actual 2560×1369 client area on a 2560×1392 usable desktop.
The startup screenshot was inspected. Logs: artifacts/screen-fit-validation.log,
artifacts/screen-fit-screen_fit_probe.log and artifacts/screen-fit-*.log.

## Phase 4 companion-screen slice

Implemented party/storage lists, separate inspection and active selection,
Summary/Moves/Training tabs, remembered inspection/scroll state, starter comparison,
and a camera-fitted model window using the actual individual-affinity model.
Pokémon is referenced for navigation clarity; original SolHunter styling remains.
Personal-screen text sizing supports 100–200% with responsive growth/stacking.
See [Sol menu](sol-menu.md) for behavior, sources, controls and validation.
The blocker pass below adds whole-HUD text scaling. Complete device accessibility
acceptance remains open.

Phase-4 first-slice evidence: import/full validation passed 11,158 checks across
35 reported suites; 25 companion-menu checks also passed rendered. Native starter
selection, model fitting/affinity, transfers, move explanations and enlarged personal
text were checked. See artifacts/phase4-validation-final.log and artifacts/sol-menu/.

## Thin UI and hover details

Owner follow-up: reduce visible text and visual weight. Navigation is narrower
and flat, controls and margins are shorter, duplicate headings/help are removed,
and secondary counts/class/XP/stats/move information moves to hover tooltips.
Health, capture chance, action availability and tactical previews remain visible.
Hover text follows the personal text-size preference. Training remains explicit.
The full shared validator passed 11,159 checks across 35 reported suites; rendered
companion and combat checks passed. Final hover/text-size checks passed separately.
Evidence: artifacts/ui-thin-validation.log, artifacts/ui-thin-focused-final.log and
artifacts/sol-menu/hover.png. No world streaming or gameplay rules were changed.

Extensive Sol information is available through Sols → Details, keeping Summary
compact. This dossier reads saved identity, stats, class ability, training,
progression, moves and recorded sightings/relationship evidence. Starter Details
separates authored baseline data from not-yet-assigned individual potential.
See [Sol menu](sol-menu.md) for exact scope and validation evidence.

The next Sol-information pass makes Details → Overview the initial view, adds
Overview/Combat/Growth/Moves/History categories and a visible quick combat summary.
It explains loadout reach/support coverage, current class-passive thresholds,
individual potential comparisons, next-level stat projections and explicit gaps
in recorded history. It uses saved state and existing calculators only. Final
rendered companion verification passed 41 checks; the shared validator passed.
See [Sol menu](sol-menu.md) for the evidence and scope.

World inspection now defaults to a single-line subject/passability strip. Full
environment readings and secondary facts require right-click → Details; Less
returns to the strip. The redundant EXAMINE heading and permanent reading list
are removed. Rendered inspection checks pass for actual values, explicit detail
selection, collapse/close, large text, viewport fitting and unchanged save state.
See [field menu](field-menu.md#world-inspection) for behavior and tuning.

## Phase 4 blocker pass — October 28, 2026

Training allocation and confirmed retraining refresh the surrounding selected
profile, health meter, roster and dossier through the existing state-change
signal. The update is deferred and coalesced to avoid rebuilding a pressed
button mid-command. Selection and scroll are retained; focus returns to the
same available training action, or to its tab when that action becomes disabled.

Options → Text size (100–200%) now applies to personal screens, exploration
labels, clock/compass, context menus, encounters, pause, confirmations, combat
and result recaps. Modal content scrolls within bounded panels. Navigation grows
with text, and slider numbers keep one line rather than collapsing into a tall
column. Original font sizes are retained so reducing text does not compound size.

Combat uses a compact health strip and action ribbon. Primary moves, Seal chance
and End turn stay visible. More · Esc exposes Battle log, retreat and camera
framing. Routine instructions, affinity/class and enemy intent move to hover;
committed resolution captions, action gates, conditions and contextual damage/
path previews remain available. The log is closed by default. Exploration toasts
stay out of an active battle. Layout stays bounded at enlarged text sizes.

`tests/ui_playtest_blockers.gd` passed 58 rendered checks, including actual mouse
training/reset, coherent HP refresh, focus, 1280×800 / 640×400 / 800×1000 layouts,
large-text navigation, encounter, pause, combat actions and result dismissal.
`tests/combat_polish.gd` passed 23 rendered checks. Captures:
`artifacts/playtest-blockers/`; logs use `artifacts/playtest-blockers-*`.
This is desktop scripted/rendered coverage, not export, Thor or new-player acceptance.

Final verification: Godot 4.7.2 import succeeded. All registered project suites
and both scene journeys have passing results across the shared and targeted
runs. The shared run stopped at the obsolete full-width action-tray assertion;
that check now verifies the intended compact, centered ribbon and passed with
the remaining suites. This is split verification, not a single shared-validator
pass. Concurrent controller/test edits were preserved and the affected combat,
mouse, wilderness and UI suites were rechecked against unchanged input hashes.

Evidence: `artifacts/playtest-blockers-validated.log`,
`artifacts/playtest-blockers-remainder-validation.log`,
`artifacts/playtest-blockers-final-focus.log`,
`artifacts/playtest-blockers-ui-rendered-final.log`, and
`artifacts/playtest-blockers-validation-summary.json`. Final affected-suite input
hashes are in `artifacts/playtest-blockers-final-focus-inputs.json`. The last
rendered UI run passed 58 checks. No exported-build, owner-playtest or Thor
acceptance is claimed.

Subsequent concurrent combat/test edits occurred after the recorded validation
snapshots. A later consequences-suite recheck passed 63 assertions
(`artifacts/playtest-blockers-concurrent-test-recheck.log`), but ongoing tactical
changes mean these records do not certify every later combined working tree.
The requested UI implementation and its rendered checks are complete; a clean
full-project run after concurrent combat work settles remains an acceptance gate.
