# Field-aware enemies, testing Seals and progression

Implemented October 27, 2026 as steps 2–4 after authored wildlife recovery.
This is a bounded D4/D5 prototype; manual acceptance and production balance remain open.

## Playable behavior

Enemies compare legal equipped move/position pairs using the same targeting,
effects and weighted paths as the player. Useful damage, healing and terrain
actions compete against expected shared field risk. Equal utility prefers less
movement, then stable grid/move order. Full-health healing and redundant fields
do not cause camping; no useful move falls back to safer attack range. The intent
label uses this same read-only planner. This is a deterministic local heuristic,
not lookahead search or a promise of optimal play; wet-ground charge risk is
conservative and future spread is not simulated during planning.

After deployment, press **Q** or the **Seal** button. Its percentage uses the
same probability as execution:

`clamp(0.08 + (1 - HP/maxHP)*0.48 + power/250 + max(0, 0.20 - 0.025*(distance-1)), 0, 0.95)`.

Distance is Manhattan separation from the released Sol. Basic power is 10.
No poison/status bonus is added because that status system is absent. Invalid
attempts spend nothing. Failure spends the action and lets the enemy activate;
success ends the encounter. A world/encounter/individual/attempt seed makes the
roll reproducible; repeated terminal commands cannot duplicate a receipt.
Capture itself adds no affinity activity. Earlier successful moves still imprint
normally, including on capture. Active encounters remain unsavable.

The owner selected **unlimited testing Seals until shops and rewards exist**.
There is no finite opening inventory or purchase/refill UI in this slice.
Captured ID, home, generation, assigned affinity, remaining HP, resolved profile,
learned moves and equipped four survive ownership and reload. Sealing does not
invent trust: the owned relationship starts with unknown trust and no memories.
The original wild home queues the existing successor wait; the captured individual
never becomes that successor.

**C** opens Companions & Moves after starter choice. Select a party companion for
the next encounter, store it, bring it back, and swap its remembered moves outside
battle. Party capacity is six; capture overflow goes to storage. The last party
member cannot be stored, and storage members cannot deploy. Storage currently has
a flat roster rather than authored box pages. There is one deployed companion per
encounter; battle switching and multi-unit combat remain separate work. Refuge
**H** heals party companions. The original starter stays addressable for save
compatibility while the selected party member supplies battle stats and HP.

## Growth and learned moves

Only the selected participating companion earns victory XP. Successful movement,
waiting or moves establish participation; capture attempts alone do not.
Retreat, exhaustion, capture, exploration and inactive companions earn none.
The source-derived default reward is `max(5, 4 + 3*enemy_level)`. XP is cumulative:
level-up requires `10*current_level²`, retains the XP total, and repeats across
multiple earned thresholds. The default future cap is 55. Each level adds 2
maximum/current HP and 1 attack, defense and speed, within existing stat safety
ceilings. IV/EV growth, evolution and opening quest caps are not inferred.
Victory recaps show XP and newly learned move names.

The owner approved **provisional unlock levels 4, 8 and 14**, editable in Godot.
Starting species moves remain remembered at level 1. In each authored pool's
order, the first additional move unlocks at 4, the next at 8, and remaining
additional moves at 14. This is prototype scheduling, not finalized learnset
content. Species eligibility stays independent of the individual's affinity.
Level-up automatically remembers eligible definitions and fills available equipped
slots; a full four-move loadout is preserved. There is no unrestricted Learn
button. Previously remembered moves remain available after migration.

The root's Progression Settings resource controls XP curve/reward, future cap,
base growth and milestone values. Restart/reload after edits to refresh runtime
policy. Existing profiles, HP and XP never reroll; lower caps never downgrade.
Per-individual unlock schedules are saved on first admission (or capture), so
changing milestones affects newly admitted schedules rather than rewriting old
ones. Move definitions are snapshotted when first learned. See the exact control
map in [Inspector tuning](inspector-tuning.md).

## Persistence and evidence

Domain version 9 adds collection/selection, XP and saved unlock schedules, plus
capture counts in the outcome receipt. Completion builds and validates one
candidate before installing HP, ownership, growth, moves, imprint and home wait.
Save admission rejects malformed profiles, missing selected members, stored
selection while a party exists, excessive party size and invalid receipt totals. Versions 1–8 retain
the original starter's existing profile, health and moves with zero inferred XP;
no historical rewards are replayed. Older generic owned records without combat
profiles remain preserved without fabricating deployable stats. A legacy stored
starter stays stored when it is the only profiled companion; C can bring it into
the party before battle.

Read-only mechanics reference: SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885` on
`backup/pre-world-redesign-2026-10-24`. Relevant files inspected:

- `src/systems/tactics/ai.py`: legal move/position comparison, stationary ties,
  aggressive heal weighting and approach fallback. Field scoring is new Godot
  prototype tuning over the owner's shared affinity effects.
- `capture.py`, `live_encounter.py`, `supplies.py`: visible probability, action
  sequencing, identity/health continuity and testing supply. The owner selected
  testing supply over the separate finite opening inventory.
- `party.py`: party capacity and ownership/storage continuity.
- `battle_growth.py`, `move_learnsets.py`, `species_moves.py`,
  `move_management.py`: victory-only participant XP, cumulative thresholds,
  base stat growth, remembered moves and preserving a full loadout.
- `opening_progression.py`, `region_progression.py`, `config/development.py`:
  distinct opening/story gates and regional cap. Godot does not yet have the
  source's opening quest or genetics systems.

No source Python files were bulk copied and Godot world generation is unchanged.
The Bible's design authority is preserved; this change does not amend it.

`tests/ai_seals_progression.gd` exercises actual UI/controller capture and reload,
enemy planning purity/legality/hazards, field execution, invalid and failed Seals,
party/storage limits, malformed saves, legacy migration, exact XP thresholds,
off-affinity unlocks and atomic participating victory growth. The shared validator
runs it. `--capture-progression` with a rendering driver writes ignored screenshots
to `artifacts/progression/`; these are scripted acceptance evidence, not a device
performance or full balance signoff.

Godot 4.7.2 import and the shared validator passed **6,579 headless checks**,
including 78 new acceptance checks and both scene journeys. The rendered suite
also passed all 78 checks; Seal preview/result and companion panel screenshots
were inspected. The camera smoke assertion now verifies the configured Inspector
elevation/azimuth rather than assuming every scene stays below 45 degrees. Local
camera/resource edits remain separate from this gameplay change.
