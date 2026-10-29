# Individual Sol stats and training

Historical feature-slice record: controls, schema versions and validation below
refer to its original delivery. Current save admission uses format 4, generation
9 and world state 17; incompatible development saves require a new expedition.
See the [reformat evidence](reformat-roadmap.md#execution-and-evidence-index) and
[current controls/tuning](inspector-tuning.md) for the integrated project.

Implemented October 27, 2026, following the owner's decisions in this chat.
This supersedes the earlier two-pool proposal and its additional 40% growth
bonus. Only training points are player-assigned; natural level growth is automatic.

## Natural stats

The six stats are HP, Attack, Defense, Special Attack, Special Defense, and Speed.
Physical/special moves use their corresponding offense and protection. Speed
determines initiative independently of movement distance.

Species profiles supply stats at a reference level. Each individual independently
rolls six natural percentages, default **90–110%**, with no total-strength budget.
Three uniform integer samples are averaged and rounded per stat, concentrating
values near 100%. This distribution is initial implementation tuning, not an
additional inheritance or rarity rule.

SHA-256-derived deterministic streams use stable individual ID (including world
seed), with separate namespaces per stat and for class potency. Rolls, reference
profile, growth increments, class potency, and training policy are saved before
combat use. Capture and ordinary evolution preserve lifelong IVs and potency.

Natural growth continues to level 55. Prototype species increments remain +2 HP
and +1 to each other stat per level, before IVs and training; each individual
snapshots these increments. No separate 40% bonus applies. Unspecified special
stats inherit authored physical Attack/Defense; authors can set explicit values.

Resolution: `round((reference stat + levels gained × species growth) × IV / 100 × (1 + training bonus / 100))`.
HP is bounded to 1–1000; other stats to 0–1000. Combat applies class/status and
protection modifiers afterward, retaining fractions until final damage rounding
with a minimum of 1 direct damage.

## Training

Full investment adds **10% per stat**. The total budget can maximize **three**
of six stats, or spread investment more widely. Initial scale: 100 points per
stat, 300 total, with each point contributing 0.1 percentage point.

| Ordinary form | Per-stat point cap | Total earned/allocated cap |
| --- | --- | --- |
| First of three | 50 | 150 |
| Second of three | 75 | 225 |
| Final available form | 100 | 300 |

Shorter lines reach full capacity in their final form, including single-form
species. Evolution unlocks capacity, not free points. Prototype profiles default
to three forms; authors must set the actual lineage length.

Only a contributing Sol earns training from victory. Damaging moves, effective
healing, useful hostile statuses/terrain, and effective protection qualify;
movement, waiting, deployment and reserve party membership alone do not. Current
encounters have one active allied Sol, so only that qualifying participant earns
points. Capture, retreat and exhaustion award none. Existing atomic battle
receipts prevent duplicate rewards for an already defeated individual.

Initial reward: `max(1, 5 + opponent level − participant level)`, but opponents
ten or more levels weaker award nothing. Earnings stop at the current form cap.
This per-individual policy is editable for future admissions in Godot.

Wild Sols have no training investment. Capture retains exact resolved stats,
remaining HP, IVs and class potency. It creates no growth-point allocation.

## Controls, authoring and persistence

Open **Sols** in the field menu or **C** outside battle. The companion panel shows
exact IV percentages, natural/final stats, training bonuses, earned/unspent points,
stage caps and class potency. Allocate +1 or +10 points at a time outside battle.

Resetting requires confirmation and consumes one limited retraining item. It
returns spent points without changing earned total or IVs. Expeditions start
with three items (Godot tuning); Bag shows remaining supply. Empty/invalid resets
consume nothing. Allocation/reset never heal: HP is preserved, clamped if its
maximum falls. This implements the limited-item option, not a paid-shop economy.

`BattleSettings` links `resources/sol_stat_settings.tres` and
`resources/class_buff_settings.tres`. `BattleProfile.evolution_forms` defines
lineage length. [Inspector tuning](inspector-tuning.md) describes application
timing. New move metadata separates physical/special damage and supports stat
buffs/debuffs, poison and protection. Prototype pools add Arc Bolt, Focus, Rattle,
Spore Sting and Ward as later unlocks, retaining existing equipped choices.
Expanded authored pools apply to new movebook admissions; previously saved
movebooks retain their recorded pools and definitions.

Domain **10**, inside outer save format 2, adds `sol_stats` and
`retraining_items`. Versions 1–9 migrate once: identities receive deterministic
IV/class rolls, owned profiles become reference baselines at their saved level,
and IVs apply once. HP is retained and clamped to the new maximum; historical
training is not invented. Earlier wild profiles are admitted from authored
resources when available. Subsequent loads never reroll or apply IVs twice.
Malformed traits, budgets, or inconsistent resolved profiles are rejected.

The explicit authored evolution command preserves ID (recording birth species),
affinity, IVs, potency, training, and remembered/equipped moves. It updates
species/form stats and capacity. No new evolution species or automatic evolution
levels are invented; the current species slice still needs authored evolution
content. [Class buffs](class-buffs.md) records the single-companion battlefield
limitation for Swarmkin.

## Evidence and validation

Reference commit `115f3e87acc1716c7113523567c01e1666681885`:
`src/systems/tactics/sol_combat.py` supplies separate physical/special combat and
finite, nonstacking statuses; `genetic_abilities.py` in the same directory
demonstrates persisted deterministic traits. Owner decisions here supersede older
proposed IV/EV ranges and source ability modifiers. Source innate abilities have
not been silently layered onto class buffs. Godot generation remains unchanged.

`tests/sol_stats_and_classes.gd` covers potential distribution, independent/fixed
rolls, rewards/caps/reset supply, evolution preservation, migrations, JSON round
trips, malformed saves, special damage, and all class passives. It is included
in `tools/validate.ps1`, alongside existing capture, progression and scene suites.
