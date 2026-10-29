# Class buffs and individual variation

Design baseline and runtime implementation: October 27, 2026. The owner requested
applying the agreed class and individual-stat rules to the game. Numerical ranges
remain editable initial balance tuning.

The owner accepted the proposed signature passives with two revisions:
Beast receives a 5–10% bonus for the affinity of its occupied tile, and
Cinderkin's Kindling grows by 1–5% per attacking turn. Buff strength varies
between individual Sols. All other proposed triggers, caps, and protections
remain the baseline. The roster names remain working names.

The Beast bonus is interpreted as increased direct damage from a move whose
assigned affinity matches the tile occupied by the attacker at execution.
It does not require the individual's own affinity to match. This interpretation
does not change the Sol's affinity, move affinity, or tile affinity. It adds no
bonus on a tile without an assigned affinity. This interpretation is a working
implementation recommendation, not an additional explicit owner decision.

## Buff roster

Beast's 5–10% and Kindling's 1–5% ranges are owner-specified. Other ranges below
are initial balance recommendations applying the owner's individual-variation
direction; they are not separately ratified numerical limits. Percentage rolls
use inclusive whole percentage points. Trigger thresholds and per-battle caps
remain fixed unless explicitly listed as a rolled value.

| Class | Passive | Individual roll and effect |
| --- | --- | --- |
| Beast | Terrain Resonance | **5–10%** more direct damage with moves matching the affinity of its occupied tile. Replaces Survival Instinct entirely. |
| Cinderkin | Kindling | Roll **1–5%** once as the individual's growth rate. Consecutive turns using damaging moves build that much bonus damage per turn, capped at **15%**. A turn without attacking resets the accumulated bonus. |
| Tideborn | Undertow | A damaging hit makes that enemy deal **5–10%** less direct damage to this Tideborn until the end of that enemy's next turn. Reapplication refreshes; it does not stack. |
| Verdant | Rooted Renewal | Ending its turn without moving restores **1–3%** maximum HP, capped at **15%** maximum HP restored by this passive per battle. |
| Stormforged | Momentum | Moving at least **2 tiles** before attacking grants **5–10%** more direct damage that turn. |
| Frostbound | Cold Resolve | At or below **50% HP**, take **5–10%** less direct damage. |
| Warborn | Challenge | Deal **5–10%** more direct damage to adjacent enemies with physical or special moves. |
| Blightborn | Exploit Affliction | Deal **5–10%** more direct damage to enemies with a harmful status or stat reduction. Multiple conditions do not increase the bonus. |
| Earthbound | Surefooted | Difficult ground costs normal movement. Impassable terrain remains impassable. This binary utility has no numerical potency to roll. |
| Skyborne | Swift Arrival | Gain **1–2 extra movement tiles** on its first turn in a battle. Switching does not refresh it. |
| Mindweaver | Forethought | Take **10–15%** less damage from the first damaging action that hits it each battle. |
| Swarmkin | Collective Pressure | Deal **5–10%** more direct damage to an enemy adjacent to another allied Sol. |
| Stonebound | Set Like Stone | After ending a turn without moving, take **5–10%** less direct damage until it next moves. |
| Wraithborn | Unworldly Form | Take **5–10%** less damage from ranged attacks originating at least **3 tiles** away. |
| Wyrmkin | Ancient Might | Deal **5–10%** more direct damage to targets currently above **75% HP**. |
| Umbral | Isolate Prey | Deal **5–10%** more direct damage to enemies with no allies of their own within **2 tiles**. |
| Construct | Stable Frame | Incoming reductions to Attack, Defense, Special Attack, Special Defense, and Speed are **10–20%** weaker. |
| Feyborn | Otherworldly Grace | Helpful stat buffs it applies last **1–2 additional recipient turns**. Reapplication refreshes without accumulating extra turns. |

Kindling's roll is a stable individual trait, not a new random roll each turn.
For example, a 2% individual builds 2%, 4%, 6%, and so on to 15%; a 5%
individual builds 5%, 10%, then 15%. Recommended timing: the first damaging
action receives the first increment; invalid actions do not build stacks.

## Individual identity and persistence contract

- Generate each numeric potency once when admitting the individual. Use a
  versioned deterministic random stream based on world seed, stable individual
  ID, and a class-buff namespace, independent of affinity and other trait rolls.
- Initially use a uniform distribution over the inclusive range. Rarity
  weighting and correlated trait rolls are not established by this decision.
- Save the resolved potency, class-buff ID, and definition version before use.
  Loading, sealing, releasing, transferring, or ordinary evolution must preserve
  them. Do not recalculate existing individuals from changed tuning resources.
- Existing saves need an explicit, deterministic one-time admission migration.
  Save and validate its result; do not roll in rendering or combat preparation.
- Expose connected range endpoints in a typed Godot Resource with tooltips and
  validation. Range changes apply to newly admitted individuals. Runtime
  implementation must update the Inspector tuning map.
- Keep per-battle counters separate from identity traits. Switching preserves
  first-action consumption, first-turn consumption, healing spent, and other
  battle limits. Starting a new battle resets battle counters, not potency.

## Shared rules and implementation boundaries

Class, individual affinity, species abilities, and equipped moves remain
separate. These passives occupy no equipped move slot. A class grants no blanket
immunity and does not lock every species into a combat role. Initially only the
primary class passive activates; secondary-class stacking needs a later rule.

Bonus damage applies to direct move damage, not terrain ticks, damage over time,
healing, or battle-imprint activity counts. One successful move still contributes
one activity event. Percentage calculations should retain fractional precision
until final HP resolution; exact rounding and modifier order need implementation
tests and balance review.

The Godot battle domain implements these passives with saved individual potency,
physical/special damage, stat buffs/debuffs, poison, protection, and finite
recipient-turn durations. Execution and enemy previews share damage calculations.
Battle counters do not alter move activity counts.

The live battlefield remains one allied Sol versus one enemy. Swarmkin checks
explicit additional active allies, so it does not trigger in current encounters;
reserve party/storage members do not qualify. Both conditions are tested with
tactical contexts. Other classes are available to authored profiles; this change
does not invent species for all eighteen classes. See [individual stats](sol-stats.md)
for persistence, training controls, migration, and evolution-content boundaries.

## Reference evidence

October 28 class-coverage continuation: the eighteen current classes now have
playable first-form representatives. Eldritch uses its own runtime key with an
explicitly unassigned, zero-potency passive. It does not inherit legacy
Stonebound's effect. The legacy definition remains available for saved/prototype
content, so runtime settings contain nineteen supported identities while the
current design roster still has eighteen classes. Existing passive rules remain
unchanged. See [class coverage](sol-class-coverage.md) and the Sol Bible.

- Owner discussion, October 27, 2026: accepted the recommended class passives,
  replaced Beast, revised Kindling, and requested per-individual buff ranges.
- [SolHunterSource class specification](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/SOL_CLASS_AFFINITY_SPEC.md):
  working roster and separation of fixed lineage class, individual affinity,
  abilities, and moves. Its older alternative roster and affinity recommendations
  do not override subsequent owner decisions.
- [Source combat domain](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/systems/tactics/sol_combat.py):
  distinct class/affinity/innate ability fields, physical and special damage,
  finite status durations, and refresh rather than unlimited status stacking.
  This file does not establish the newly proposed class buffs as implemented.
- [Godot affinity and imprint rules](affinity-moves-imprints.md) and the
  [Bible's owner-approved affinity rules](reference/SolHunter_Worldbuilding_Bible.md#owner-approved-affinity-move-and-battle-imprint-rules--october-27-2026)
  remain authoritative for move affinity and persistent tile affinity.
