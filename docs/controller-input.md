# Current expedition controller input

Implemented October 28, 2026. Desktop controls and game rules are preserved.
The router adapts controller input to existing world/menu/battle commands.

| Default Xbox control | Action |
| --- | --- |
| Left stick / stick click | Walk / hold to sprint |
| Right stick / stick click | Camera / reset; scroll while in menus |
| Triggers | Zoom |
| D-pad | World/tactical cursor or menu navigation |
| LB / RB | Previous/next individual target or legal battle target |
| A / B | Confirm / cancel or close the highest interaction layer |
| X | Inspection/details, including move descriptions without hover |
| Y | Cycle world targets / switch combat action selection |
| Menu / View | Live field menu (combat More) / pause |

Prompts follow bindings and detected Xbox, PlayStation or Nintendo naming.
Options offers deadzone, camera sensitivity, inversion, button remapping and
reset. Conflicting bindings swap; preferences persist separately from game saves.
Disconnect and window focus loss clear held input. Menu navigation cannot move
the player or spend a combat action. Consequential confirmation starts on Cancel.

World interaction uses an explicit target cursor and the existing target-action
menu. Individual identity is revalidated before acting. Combat selection, movement,
attacks and Seal use existing legal-action checks. Inspection is scrollable and
available without hover; battle detail windows suspend pending presentation.
The field menu remains live, while the pause screen stops exploration time.

`tests/controller_expedition.gd` injects joypad events through viewport input,
including native popups and confirmation windows. It covers starter selection,
training, move assignment, settings/remapping, save/load, inspection, camera,
deployment, movement, attacks, Seal, retreat, disconnect and desktop takeover.
This is automated input coverage, not physical controller or Thor acceptance.

Implementation follows [Godot controller input](https://docs.godotengine.org/en/4.7/tutorials/inputs/controllers_gamepads_joysticks.html)
and [focus navigation](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html).
Explicit repeat handling is necessary because joypad buttons do not emit keyboard
echo. Window-local input bridges and controller-only removal of native UI mappings
prevent a single press from activating both native GUI and the router.

Mechanics reference: read-only `SolHunterSource`, branch
`development/world-redesign-0.2`, commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`,
`src/systems/tactics/live_encounter.py`. This change introduces no new combat rules.


Validation: pinned Godot 4.7.2 full `tools/validate.ps1` passed after the text
reduction (`artifacts/controller-full-validation.log`), including 58 controller,
59 UI blocker, 22 inspection, 41 Sol menu and 30 field menu checks. A rendered UI
run also passed and produced `artifacts/playtest-blockers/combat-compact.png`.
The rendered controller attempt was interrupted by real desktop input; isolated
headless joypad journeys passed. Physical hardware remains untested.
