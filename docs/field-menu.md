# Field menu

The exploration interface uses one forest/gold window with seven sections,
inspired by Pokémon's familiar menu organization and using original styling.

| Section | Connected behavior |
| --- | --- |
| Field Guide | Existing recorded sightings and first-seen notes |
| Sols | One-time starter choice, party/storage, active companion, moves and refuge recovery |
| Bag | Current unlimited testing Seal supply and capture guidance |
| Trainer | Expedition location, companion count and existing battle statistics |
| Journal | Current journey objective and session message history |
| Save | Existing guarded save, load and confirmed new expedition actions |
| Options | Menu scale/opacity/reset, camera speed/reset, and perspective FOV/view distance |

R or the Menu button opens the window. C opens Sols and J opens the Field
Guide; pressing the same shortcut again closes that section. R/Close closes this
live menu. Escape closes it and opens the separate pause screen. Native buttons
and sliders support keyboard focus and mouse input. Starter buttons retain the 1–3 shortcuts. F5/F9 remain save/load.
An active encounter retains its mouse battle input and prevents opening this menu.
Escape cancels aiming or toggles the battle menu; it never directly retreats.
See [UI/UX roadmap](ui-ux-roadmap.md).

Opening keeps exploration, wildlife, atmosphere time, player movement and animation
running, and closes pointer observation. Menu input cannot rotate or zoom the world
camera. Closing never changes pause state; encounters close the menu before taking
their own pause lock. Escape opens a separate pause screen and freezes exploration;
Escape/Resume returns to play. Replacing expedition state closes both screens.
Party and move controls call the existing collection/loadout implementation,
preserving acquisition, storage and loadout rules.

Drag the header to move the window. Drag its bottom right grip to resize it.
Position stays within the viewport; compact windows scroll their sidebar and
page content. The default 0.7 size multiplier reduces both menu dimensions by 30%.
Options requests 75–125% relative UI scale and 70–100% background opacity; existing
local preferences remain valid and receive the same compact multiplier.
Very small viewports can reduce the effective scale further to keep the minimum
layout visible. Text stays opaque. Reset Menu Layout restores authored defaults.

Layout, requested scale and opacity are remembered in
`user://menu_preferences.cfg`, independently of `expedition.json`. Malformed
preferences reject atomically; off-screen layouts are clamped after loading or
viewport resize. Defaults and persistence can be edited through the root's
Interface → Menu Settings resource; see [Inspector tuning](inspector-tuning.md).
Camera/graphics adjustments in Options apply to the current session only.

Validation: `tests/field_menu.gd` checks native GUI drag/resize, page navigation,
pause and camera isolation, starter acquisition, real save/load, encounter
guards, viewport fitting and preference validation. A rendered run with
`-- --capture-menu` saves review images to ignored `artifacts/menu/`.

The live-menu/window follow-up passed the full shared validator (11,127 checks,
34 reported suites). tests/live_menu_window.gd adds 24 checks for resizing, R menu,
Escape pause/resume, continued movement/time, encounter pause ownership and
shortest-arc frame-rate-independent turning. Rendered menu/window and pause
screens were inspected; captures are under ignored artifacts/live-menu/.

The game now starts maximized to the player's available screen. Fixed physical
window-size overrides are removed; canvas scaling expands with the actual aspect
ratio. The menu clamps to the current viewport after resizing. R and Escape retain
their live-menu/pause behavior. Restart the game to apply startup display changes.

Phase 4 adds Party/Storage lists, Summary/Moves/Training tabs, separate inspected
and active companions, and a fitted live Sol model window. Options → Text size
supports 100–200% for personal screens and is remembered separately from saves.
See [Sol menu](sol-menu.md) for the reference, behavior and remaining phase-4 work.

UI cleanup removes repeated section headings, numbered navigation and permanent
instruction text. Drag/resize and keyboard guidance move to hover tooltips;
confirmation messages appear only when relevant. The Sols page keeps the model,
health and compact actions prominent. Counts and secondary details are available
on hover. Existing R/Escape behavior, text sizing and responsive layout are retained.

## World inspection

World inspection opens as a single-line strip: subject, passability and Close.
Right-click a target and choose Details to reveal wetness, Vastra concentration
and ecological overload as exact readings with thin meters.
Details presents the environmental graphs without a Less control or fact block;
Close dismisses it. Observe and
E examination use separate presentations: Observe shows the target name, a brief
appearance description and Close; E examination uses the compact strip. Hover
keeps full target names available. Left-click performs the first enabled context
action. Right-click titles each target group with its name in smaller text and
uses short action labels, such as Engage, Observe and Details.

Passability also includes lingering barrier conditions: the strip shows Blocked
with a barrier explanation until the condition fully recovers, matching existing
exploration traversal. Inspecting the condition does not advance its recovery.

Inspection is read-only and does not pause exploration. It respects the text-size
preference and fits the current viewport. `tests/inspection_card.gd` covers the
compact layout, explicit Details selection, real readings, mouse collapse/close,
large text, resize fitting and unchanged expedition state. Rendered review images
are saved to ignored `artifacts/inspection/` with `-- --capture-inspection`.

October 28 small-detail follow-up: Godot 4.7.2 import passed; the inspection suite
passed 22 checks headless and rendered with Forward+/Direct3D 12, including a
saved barrier fixture, all recovery stages and unchanged inspection state. World
interactions passed 15 checks. The new checks reproduced three failures before
the label fix. Logs: `artifacts/small-world-details/`; reviewed barrier capture:
`artifacts/inspection/barrier.png`. This focused pass does not certify the full
concurrently changing checkout or target-device usability.

Final inspection verification passed 16 rendered checks on Godot 4.7.2. Import
and all project suites passed across the initial and follow-up runs after the
mouse-controls fixture was updated to wait for battle deployment presentation.
Logs: `artifacts/inspection-validation-final.log`,
`artifacts/inspection-mouse-controls.log`,
`artifacts/inspection-ui-remainder-validation.log` and
`artifacts/inspection-strip-render.log`.

The October 28 blocker pass extends Text size beyond personal pages to the
whole screen-space HUD. Enlarged personal navigation retains enough width,
scroll containers follow focused controls, and settings numbers remain on one
line. Sol training/reset refreshes the surrounding profile and roster without
a tab switch. See [UI/UX roadmap](ui-ux-roadmap.md) for the current evidence and
[combat presentation](combat-polish.md) for the compact action ribbon.


Observe fades out after three real seconds unless pinned. Pin keeps the current
target and description until closed or replaced; opening a menu temporarily hides
it. Unpin starts a fresh three-second lifetime. Journal opens that individual's
Field Guide entry directly, including recorded facts when available. Objects with
no saved entry open an observation page without inventing a saved discovery.
All entries returns to the complete recorded list. Button states use consistent
padding so hovering navigation and inspection controls does not shift the layout.


Observations stack downward below the compact location label. Each has an icon
pin at the left of its heading and Close at the right. New observations retain
older cards' remaining lifetimes and pin state. When the screen fills, the oldest
unpinned card makes room; if every existing card is pinned, the new card is not
retained. Resizing also keeps the stack within the screen. Context menus omit
Cancel; clicking away or Back/Escape closes them. Location padding follows the
text with 10 horizontal and 5 vertical pixels of space.
