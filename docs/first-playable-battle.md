# First playable battle

Implemented October 27, 2026: explicit starter choice, persistent companion and
deployment, tactical movement/basic attacks/enemy turns, and durable victory,
exhaustion, and retreat outcomes. This is a two-unit D4 prototype in the existing
pixel-art 3D world, not completion of the full combat or collection milestones.

## Play

Press C and choose Bramblepup, Ashkit, or Rillfin using 1–3 or the buttons.
Selection is explicit, once per expedition; cancel grants nothing. R approaches
a nearby Sol. Choose Battle in its encounter panel; if necessary, this opens the
same companion chooser before continuing to deployment. The owner-approved
guarding Seedmote still requires a displayed warning and a later contact step
for automatic entry. The preview itself does not force a tactical battle.

Click a blue release tile, or move the yellow cursor with arrows/WASD and press
Enter. After deployment, blue tiles show reachable movement; click one or use
arrows/WASD to move. Space performs the named basic attack when in range.
Enter ends the turn. Escape or Retreat guarantees withdrawal, including before
deployment. The sidebar shows both HP totals, movement remaining, attack damage,
enemy intent, and recent actions. Red marks the opponent and green your Sol.

Movement is cardinal and shares one budget across inputs in a turn. Attack
ends the turn; unused movement is discarded. Speed determines initiative each
round, with the ally first on a tie. The enemy automatically moves and attacks
on its turn. The arena uses existing terrain legality and bounded pathfinding;
neither deployment nor attacks pass through blocking terrain or the trainer.

Victory marks that wild individual exhausted and unavailable, retaining its
identity rather than killing, capturing, or duplicating it. Exhaustion returns
the player to the refuge with the same companion at zero HP. Press H at the
refuge to recover fully. Retreat preserves remaining companion HP. Three
successful steps of post-battle automatic-contact protection are saved; manual
approach remains available. Save with F5 after returning to exploration.

## Mechanics evidence and limits

Read-only reference: `eliBrownn/SolHunterSource`, commit
`115f3e87acc1716c7113523567c01e1666681885`, branch
`backup/pre-world-redesign-2026-10-24`. Relevant files under
`src/systems/tactics/`:

| Behavior | Evidence |
| --- | --- |
| Explicit trio, one starter, level 3 | `starter_choice.py` |
| Wild arena 9×9, legal release within 3 cells | `arena_sizes.py`, `encounter_setup.py`, `seal_placement.py` |
| Shared movement budget 3, one action, guaranteed run | `live_encounter.py` |
| Speed initiative and stable ties | `turns.py`, `policies.py` |
| Physical damage `max(1, attack + power - defense)` | `sol_combat.py` |
| Named physical basics, power 6, range 2 | `species_moves.py` |
| Stat construction, recovery, growth boundaries | `generation.py`, `healing.py`, `battle_growth.py` |

`src/app/controllers/combat_controller.py` supplies the centralized completion
and retained-health reference; `src/core/game.py` supplies return-to-spawn after
defeat. `src/systems/world/population_recovery.py` separates depletion from later
replacement. Godot remains the world-generation authority.

Profiles are provisional authored resolved stats using source base/level inputs,
without IV rolls, trait bonuses, or genetic multipliers. The current basics are
neutral physical attacks; affinity/Vastra damage curves are not invented here.
There is no XP, EV gain, evolution, capture, party switching, consumable economy,
or permanent death in this slice. Defeated wild individuals remain unavailable
for this expedition: delayed population recovery/replacement is still future
work. Enemy HP resets for a later encounter after retreat; companion HP persists.
The trio and placeholder sprites are not a finalized production roster.

## Persistence and authoring

Outer save format stays 2; domain version becomes 6. Domains 1–5 migrate with
empty battle progress and no inferred starter. Existing owned collections are
preserved and cannot receive a second starter through this chooser. Chosen
identity, resolved profile, HP, result counters, latest serial receipt, defeated
IDs, and protection steps survive reload. Loading does not heal or replay a
result. Active battle snapshots are rejected by the domain validator as well as
the UI save/load/new-expedition guards. Only the authoritative completion path
commits a terminal result, once per active serial.

The root's Battle Settings resource connects `resources/battle_settings.tres`
and five `BattleProfile` resources. See [Inspector tuning](inspector-tuning.md)
for limits and application timing. Existing chosen profiles remain saved;
editing starter resources does not silently reroll a loaded companion.

## Verification

Godot 4.7.2 import and the shared `tools/validate.ps1` entry point passed all
6,335 headless checks, including 58 battle checks and both scene journeys.
The rendered battle suite separately passed all 58 checks on OpenGL/RTX 3070.
Coverage includes each choice, canceled/pending choice, saved identity and HP,
deployment, split movement budgets, blocked targeting, speed initiative, enemy
turns, every terminal outcome, duplicate-result rejection, active-save rejection,
legacy migration, and malformed-save preservation.

```powershell
godot --path . --script tests/first_playable_battle.gd -- --capture-battle
```

This writes ignored `artifacts/battle/starter.png`, `deployment.png`, and
`battle.png`; all three were visually inspected. These are scripted input and
rendering checks, not physical-device, accessibility, export, or D4 acceptance.
