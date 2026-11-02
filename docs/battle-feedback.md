# Battle feedback and result recap

The battle loop now reports actual damage and healing as floating numbers, with
short affinity-colored pulses and named cues for terrain/status moves. Damage
from heat and charged ground also produces feedback. Separate events preserve
the meaning of a heal followed immediately by an enemy hit, even when the net
HP change is zero. The displayed amounts are actual capped HP changes.

Presentation events never spend actions, contribute activity, or modify saved
state. Cues animate in real time while the turn-based battle pauses exploration.
They have a bounded count and lifetime and are cleared on state replacement or
the next battle. Pixel rings and text are original code-native visuals.

## Targeting and move information

Field targeting follows the mouse; click a highlighted tile to confirm. Aiming
does not move the Sol or spend its movement budget. Escape cancels an active aim;
otherwise it opens the battle menu. The explicit Retreat button requests mouse
confirmation bound to the current battle. Keyboard never executes tactical actions. Hover move buttons for
affinity, effect, range, and power. Quantum selection refreshes legal targets and
starts at chosen-position mode for each new battle.

## Results

After an authoritative victory, exhaustion, or retreat commit, a dismissible
panel shows retained companion HP, the imprint affinity and affected tile count,
successful-move counts, and the tie explanation when relevant. No successful
moves means no imprint. Exhaustion explains H recovery at the refuge. The F5
save reminder remains visible outside the scrolling details.

Exploration resumes normally; the panel does not pause the world or award
anything. Closing it cannot replay completion. It is a runtime recap, hidden on
load/new expedition, rather than a newly persisted battle history. The existing
receipt, health, imprint, and manual-save contracts remain authoritative.

## Godot tuning and verification

Sol Visual Settings exposes Feedback Enabled, Feedback Seconds (0.25–2.5),
Feedback Rise (0.1–2 cells), Feedback Limit (1–32), and Result Panel Enabled.
Duration/rise affect active cues; the limit applies to incoming cues. Disabling
feedback suppresses new cues, while existing ones finish fading. The panel
switch applies to the next result. None changes saves or combat balance.

`tests/battle_feedback.gd` covers actual input routing, cancel versus retreat,
unchanged state while aiming/animating, separate heal/hit amounts, result
contents, dismissal, exhaustion guidance, cue bounds/expiry/disable, and transient
cleanup. It is part of the shared validator. Rendered captures are produced by:

```powershell
godot --path . --script tests/battle_feedback.gd -- --capture-feedback
```

Ignored PNGs are under `artifacts/feedback/`: aim, combat, and result. Scripted
input/render checks do not establish physical-device, accessibility, export, or
production balance acceptance. No new affinity, damage, recovery, progression,
or save-schema rule is introduced by this presentation slice.

Godot 4.7.2 import and the shared validator passed all 6,448 headless checks,
including 21 feedback checks and both scene journeys. The rendered feedback
suite separately passed all 21 checks; aim, combat, and result captures were
visually inspected.
