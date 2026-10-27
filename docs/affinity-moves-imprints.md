# Affinities, moves, and lasting battle imprints

The [Bible](reference/SolHunter_Worldbuilding_Bible.md#owner-approved-affinity-move-and-battle-imprint-rules--october-27-2026)
records the owner's October 27 decisions. It supersedes the old provisional
ten-affinity roster and neutral-basic assumptions. Working names remain Fire,
Water, Earth, Air, Lightning, Void, Spectral, and Quantum until distinctive names
are selected. Ordinary affinities and special rarity tiers are confirmed; exact
spawn rates are not. No production wildlife generator is introduced here.

## Playing

C chooses a starter; after selection, C opens Companion Moves. Each species has
an explicit move pool, with four initial remembered/equipped moves. Learn another
eligible move through the panel and equip up to four distinct remembered moves.
Learning never checks the individual's affinity; swapping does not forget moves.
This is direct prototype learning access, not finalized progression or XP gates.
The saved individual retains its move definitions, eligibility pool, and loadout.
Close the panel and press F5 to save these changes to the expedition slot.

In battle, buttons or 1–4 select moves. Damage moves target the opponent; healing
and footing/phasing target self. Field moves highlight legal target tiles for a
click, or arrows/WASD and Enter. Escape cancels an active aim; otherwise it
retreats. Space uses slot one; Enter outside aiming ends the turn. A Quantum move
offers explicit position, stabilization, or entanglement choices. All actions use
the existing one-action-per-turn contract; no new unapproved mana economy is added.

## Connected prototype behaviors

| Affinity | Implementation and tradeoffs |
| --- | --- |
| Fire | Shared heat zones spread through legal cells until their original expiry; smoke blocks shots passing through them, and later-round heat damages occupants. |
| Water | Wet currents lower movement cost with the current and raise it against the current; connected wet cells conduct warned Lightning discharges. |
| Earth | Raised Ground creates a barrier on an unoccupied target with rough surrounding ground. Stable Footing prevents wind displacement for its duration. |
| Air | Directional winds help/hinder travel, push exposed units onto legal vacant cells, and replace/disperse heat/smoke in their affected area. |
| Lightning | A visible charge waits until a later round, then discharges through connected wet terrain, damaging and disrupting movement. A unit is hit at most once by connected discharge in a round. |
| Void | Shared warp zones make vertical entry cheaper and horizontal entry dearer for either side. This axis choice is provisional balance, not final lore. |
| Spectral | A move permits the next movement to cross thin obstacles with legal open landing. Protected building geometry cannot be phased through. |
| Quantum | Chosen-position superposition spends the move; stabilization clears an existing field with certainty; entanglement links two legal locations so subsequent field placement mirrors across the pair. Choices are explicit and deterministic, not hidden random rolls. |

These are representative tunable moves, not complete production learnsets or
final implementations of every proposed ability. Enemy AI currently prioritizes
an equipped damage move and may heal while outside attack range; it does not
optimize all field/Quantum combinations. There is no type-effectiveness chart,
automatic same-affinity immunity, or new concentration damage curve. Rare
individual affinities are not intrinsically stronger. Prototype learning access
to special-affinity moves does not specify their eventual acquisition rarity.

The subsequent [battle feedback slice](battle-feedback.md) adds actual HP-change
cues, move tooltips, and a dismissible recap explaining committed results and
imprints. It does not alter activity or tile-affinity rules.

## Activity, persistence, and recovery

Only a move producing an intended effect contributes one activity event, using
the move's affinity. Target/effect tiles join a battle-wide union; self tiles only
join when affected. Zero-effect healing and invalid actions count nothing.
Movement, deployment, waiting, and automatic condition ticks earn no activity.
The highest count wins; the most recent successful move among tied leaders breaks
a tie. Every resolved outcome applies that winner to the entire affected union.
No successful moves means no imprint. The UI shows the current imprint leader.

Battle completion atomically installs health/result receipts and sparse tile
changes. Duplicate receipts cannot repaint tiles or restart recovery. New tile
affinity is permanent until another explicit change; unrelated terrain conditions
recover through three saved stages over active exploration ticks. Recovery debt
and intervals survive reload; loading neither heals fields nor repeats results.
Battle fields are bounded to the arena. Admission reserves room for a full arena
so sparse-state capacity cannot strand a running battle at completion.

Outside battle, affinity is visible through a local ground tint and E inspection.
Recoverable barriers block traversal; rough ground, currents, winds and warp zones
change movement timing. Barriers eventually recover, and no generation defaults
are rewritten. Heat and charge do not create unnatural Vastra overload.

Outer save format remains 2; domain 7 adds `movebooks` and `affinity_tiles`.
Domains 1–6 retain their histories. Owner-approved aliases map Grove → Earth,
Ember → Fire, Tide → Water, Gale → Air, including saved companion profiles;
individual IDs, classes, health and receipts remain unchanged. Other legacy IDs
are preserved rather than silently reassigned. Known prototype species receive
their initial authored movebooks on explicit state admission, never render rebuild.
Unknown species need an authored pool before they can enter this battle slice.
The later [wild recovery slice](wild-population-recovery.md) adds domain 8 for
saved local home replacement while retaining movebooks, imprints and old IDs.

## Authoring and evidence

The root's Move Library points to `resources/move_library.tres`. Edit typed
`SolMove` subresources, species pools, starting moves, recovery interval, field
damage, and movement costs in Godot. Existing admitted books retain their saved
definitions; changing the resource affects future admissions/learning. Current
battles snapshot moves and tactical parameters. Saved condition recovery retains
its interval. See [Inspector tuning](inspector-tuning.md).

Read-only source evidence: SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`,
`src/systems/tactics/sol_combat.py` (four equipped, remembered moves, targeting and
action contracts) and `species_moves.py` (explicit pools, starting/progression
moves). New owner decisions override its neutral defaults and older affinity
names. New move names, pools and numbers here are Godot-native prototype content;
private source files were not copied into this repository.

`tests/affinity_moves.gd` covers success/activity semantics, ties, affected union,
all terminal outcomes, atomic replay rejection, off-affinity learning, four-slot
rules, migration, malformed data, field legality, Quantum choices, and gradual
recovery. `--capture-affinities` writes ignored loadout, battle and imprint PNGs
under `artifacts/affinities/`. Scripted rendering is not physical-device,
accessibility, production balance, export, or complete D4/D5 acceptance.

Godot 4.7.2 import and the shared validator passed all 6,427 headless checks,
including 80 affinity/move checks and both scene journeys, without script/engine
errors. The rendered affinity suite passed all 80 checks; loadout, battle, and
imprint captures were inspected. A disposable zero-exit error fixture separately
confirmed that the strengthened validator rejects script-error output.
