# First playable battle

The starter, battle, and save instructions below belong to the inherited expedition. See the [map-first game](../README.md#play-the-map-first-build).

## Continuing world during combat — October 29, 2026

Owner direction: combat must not stop the surrounding world. Beginning tactical
combat now clears the encounter preview's global pause while retaining
`encounter_active` for input and save/load/new-expedition guards. The world owner
advances its one existing active clock; there is no separate combat world clock.
Day/night, weather, natural Vastra repair, plant circulation and unrelated local
wildlife continue during command selection and battle overlays. Tactical turns
still advance through commands. Encounter preview, starter/loadout modals and the
explicit exploration pause screen retain their existing pause behavior.

The persistent owner prevents the active wild opponent from ordinary roaming.
Other local individuals continue saved decisions and visual interpolation within
the existing distance/work bounds. Current/displayed combatant cells and the
trainer route are reserved from ordinary wildlife movement and successor admission.
Unrelated depleted homes can recover when their existing deadlines and clearance
conditions are satisfied. Birth validation uses the last completed battle receipt
as a validation-only projection; it does not change the active battle or permit
in-progress saves. Completion uses the current live snapshot, retaining background
changes and merging the battle's net overload contribution with concurrent repair.
No save format, balance numbers, extra encounter triggers or world generator changed.

Read-only source reconciliation used the local SolHunterSource
`development/world-redesign-0.2` ref at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`. Inspected
`src/core/game.py` (`_exploration_controls_enabled`, `_advance_world_activity`,
`_advance_day_cycle` and the main-loop callers), `src/systems/ai/world_activity.py`,
`tests/test_idle_world_activity.py` and
`docs/coordination/warning-movement-continuity.md`. The source already separates
bounded activity and tile reservations from successful player steps, but deliberately
stops wildlife during combat; day/night admits combat. The new explicit owner
direction supersedes that combat-wide activity stop. Warning acknowledgement,
later-step contact, movement lock and aftermath protection remain intact. The ref
is local checkout context; source working-tree cleanliness was not verified and
no source-repository file was changed.

`tests/combat_world_continuity.gd` exercises actual battle entry/exit, continuing
world time/atmosphere/repair, bystander movement/interpolation, unrelated successor
birth, opponent reservation, unchanged tactical turns, blocked exploration input,
safe battle completion and a real pause. `-- --capture-world` writes disposable
start/advanced rendered views to `artifacts/combat-world/`. The new test is included
in the shared validator. The continuity journey passed 23 checks headlessly and
with Direct3D 12; rendered stderr was empty. The start/advanced battle view was
inspected. Logs are `artifacts/combat-world-tests.log` and
`artifacts/combat-world-render{,-errors}.log`.

Focused regressions passed: persistent foundation (76 checks), first playable
battle (60), wild recovery (54), local Sol reactions (51) and Vastra integration
(38). Godot 4.7.2 import/parse completed with empty stderr using the existing
isolated portable engine; script/UID ownership passed for 156 scripts. Relevant
diffs were reviewed and scoped whitespace checks passed, with existing unrelated
whitespace in the sightings files left intact. The full validator and device
acceptance are not claimed; no user changes were staged or committed.

## Historical prototype

Historical feature-slice record: controls, schema versions and validation below
refer to its original delivery. Current save admission uses format 4, generation
9 and world state 17; incompatible development saves require a new expedition.
See the [reformat evidence](reformat-roadmap.md#execution-and-evidence-index) and
[current controls/tuning](inspector-tuning.md) for the integrated project.

The later [shared action budget](combat-action-budget.md) replaces automatic
move-to-enemy handoffs: moves spend AP, Speed supplies free movement, extra travel
spends AP, and End turn explicitly advances initiative.

The subsequent [affinity/move slice](affinity-moves-imprints.md) adds four equipped
moves, species learnsets, field effects, permanent tile imprints, and domain 7.
It supersedes this original slice's neutral-basic and domain-6 limitations.
The later [wild recovery slice](wild-population-recovery.md) also replaces the
original expedition-long wildlife depletion limit with saved successor waits.

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

Click a blue release tile. After deployment, click blue tiles to move the Sol.
WASD remains the exploration movement control. Select a move button (or 1–4,
or Space for slot 1), then click a highlighted target to use it. Selection only
arms a move. Right-click Observe preserves pending aim and spends no action.
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
