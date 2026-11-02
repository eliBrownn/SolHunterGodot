# Combat presentation and controls

The [shared action budget](combat-action-budget.md) now shows AP/free movement
and per-move costs. Moves retain the current turn; End turn explicitly hands off.
Route previews show free movement and AP separately. This supersedes earlier
one-move/one-response behavior described by the historical delivery below.

Implemented October 27, 2026. This polish builds on the existing one-companion
battle domain, class buffs, individual stats and saved outcome receipts.

The later [sequenced resolution slice](combat-sequencing.md) adds paced
action/consequence/turn presentation. HP, statuses, positions, and terrain now
follow the presented step while commands are gated; this supersedes the earlier
immediate refresh after a whole player/enemy exchange.

## Battle interface

`CombatHud` uses a thin top strip for both names/levels, exact HP and conditions,
plus turn/round/movement. Health bars animate toward actual HP and change color
at half and quarter health. Hover reveals affinity/class, passive potency and
enemy intent. Names can wrap at enlarged text sizes.

The bottom ribbon contains affinity-accented move names, Seal chance and End turn.
Contextual target/path/damage previews appear when relevant. More · Esc opens
secondary actions: Battle log, retreat and camera framing. The log is closed by
default and shows the latest 30 actual recorded events. Routine instruction text
stays in tooltips. Exploration overlays/toasts stay out of active battle.

Unavailable moves are disabled and explain why in their tooltip. In particular,
full-health healing cannot be armed, and an attack needs an effective legal target
in clear range. Selection uses the same admission rule. Move selection
automatically starts at a meaningful legal target; it never executes the move.

The layout follows Godot's scaled viewport and was checked at 1280×800 and a
900×600 window. Short labels and periodic rectangle correction avoid oversized
containers during font/viewport reflow. The action grid uses two columns when the available width is below
900 logical pixels times the text preference. Enlarged action content can scroll. It keeps the existing field-menu palette and typography.

## Targeting and feedback

- Click a legal blue tile to release. Hover previews deployment/movement/aiming;
  left-click confirms. Tactical keyboard shortcuts are retired.
- Click a move card to aim. Escape or Cancel Target clears the pending move.
  Escape outside aiming opens a battle menu with Resume, Frame battlefield and
  Retreat. Retreat requires mouse confirmation. End turn and Seal use buttons.
  Right-click inspection preserves an armed move. Modal layers block the tray,
  world and camera. See [UI/UX roadmap](ui-ux-roadmap.md).
- Hover reachable ground to see its actual route and movement cost. Previewing
  or cycling targets never moves a Sol, spends an action, or changes saved state.
- Legal damaging targets show exact direct damage and projected remaining HP,
  including class/status modifiers. Execution uses the same domain calculation.
- Field targets preview the affected cross or Quantum pair, including an existing
  linked tile when execution mirrors the field. Shared effects are labeled as
  affecting both sides. Blocked, occupied, and unavailable release tiles have
  contextual hints.
- Team rings and short ALLY/WILD labels distinguish nearby orbs without duplicating
  full HUD names. Their body colors still derive only from individual affinity.
  Damage/healing cues add brief cosmetic flashes and squash; none change occupancy,
  damage, initiative, or persistence. Reactions clear at battle/state boundaries.
- Right-click observation and live camera controls remain available under their
  existing rules. No undo, extra action, new damage rule, or capture rule is added.

Result recaps share the field-menu style and show committed XP, training earned
and unspent, any level-up and newly learned moves. Capture recaps identify the
actual saved companion. These are derived from the committed state, not a second
reward calculation.

## Tuning and validation

The root Sol Visual Settings resource exposes Health Bar Seconds (0–1), Target
Previews, Preview Opacity (0.1–0.8), Damage Preview, and Impact Seconds (0–0.6).
Zero-duration animation snaps/disables its respective effect. These settings are
presentation-only and not saved into individual identity; see
[Inspector tuning](inspector-tuning.md).

`tests/combat_polish.gd` tests deployment/aim confirmation, exact damage previews,
path/area overlays, disabled actions, cosmetic reactions, layout at window resize,
log visibility, state immutability during previews, and exploration HUD restoration.
It is included in `tools/validate.ps1`. Rendered evidence is generated with:

```powershell
Godot_console.exe --path . --rendering-method gl_compatibility --resolution 1280x800 --script tests/combat_polish.gd -- --capture-polish
```

Screenshots are written to ignored `artifacts/combat-polish/`.

The source reference's
[combat ownership guide](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/docs/coordination/combat-architecture.md)
keeps lifecycle/persistence, legal positioning, and read-only damage calculation
separate. This change follows that boundary: `TacticalBattle` remains the combat
authority, `ExpeditionState` owns persistent results, and the new HUD is a view.
Godot world generation and the approved individual-stat rules are unchanged.

UI cleanup: move cards show names; hover exposes their existing affinity, category,
range, power/effect and disabled reason. Seal chance remains visible, with testing
supply details on hover. Empty condition rows are hidden and the cards/tray are
shorter. Damage previews, current HP and statuses remain visible when relevant; intent
is available on hover over the turn/round display.

October 28 follow-up: `tests/ui_playtest_blockers.gd` passed 58 rendered checks
for live training refresh and whole-HUD 100–200% text reachability. Normal combat
is checked to stay below 90 logical pixels for the top strip and 125 for the
action ribbon. Captures: ignored `artifacts/playtest-blockers/combat-compact.png`
and `combat-large.png`. `tests/combat_polish.gd` passed its 23 rendered checks
with previews and actual movement into attack range from the outside throw.
