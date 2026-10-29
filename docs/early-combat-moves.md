# Early combat moves and limited uses

Owner direction, October 28, 2026: limit moves according to their strength and
effectiveness, broaden the early pool across classes and affinities, include
healing, tactical hybrids and passives, and retain principles for later study.
This is a low-tier prototype, not a final progression roster or balance approval.

## Encounter supply

Each equipped move has an authored `max_uses`. One accepted active move consumes
one use and its AP cost, including a hybrid with two components. Rejected targets,
previews, cancellation, busy input, and an identical ineffective refresh consume
nothing. Supply is keyed by move identity, independently for both sides. Ending
a turn does not restore it; a new battle restores the allowance.

For this early slice, supply is encounter-local. Rest, inventory, journey attrition
and persistent PP recovery are separate future design decisions. Saved movebooks
retain the authored limit, cost and effects, not a battle's spent counters. Captured
individuals retain their learned moves; their next encounter gets fresh supply.
Existing movebook snapshots use effect-based defaults when fields are omitted.
Start a new expedition to review new authored kits and changed library balance.

Provisional allowances reflect the complete tactical package:

| Role | Initial allowance | Reason |
| --- | --- | --- |
| Reliable basic attack | 14–18, usually 16 | Enough for ordinary exchanges without encouraging terrain/status spam |
| Light repeated attack | 12–18 | Lower damage scaling and/or short range pay for cheaper AP |
| Ranged attack | 10–14 | Reach and safety have value even with modest power |
| Heavy close attack | 6 | Higher power, five AP, and close commitment |
| Broad terrain/control | 3–6 | Coverage, displacement, smoke and routing are valuable even without immediate damage |
| Damage/control hybrid | 4–8 | Two useful components draw from one smaller shared supply |
| Active healing | 2–4 | A bounded recovery reserve prevents endless heal/hit exchanges |
| Reactive passive | 3 successful triggers | Four-slot opportunity cost plus finite useful reactions |

When all equipped damaging moves are exhausted, or none was equipped, **Last
Effort** is exposed as a fallback action. It costs four AP, has one-cell range,
zero move power and 40% direct-damage scaling (minimum one HP). It has no use
limit, affinity imprint or Vastra disturbance and does not occupy a saved slot.
Both sides use it. This keeps exhaustion playable; it is deliberately weaker than
authored attacks. Its use does not refill any other move.

## Power and tactical roles

The connected library now contains **50 moves**, adding **30 low-tier options**
to the existing 20. Every approved affinity is represented. The original first
four equipped moves remain; each species remembers three additional class-suited
options at entry. Four slots remain the loadout limit. Extra original progression
moves retain their existing milestones.

| New option | Affinity | Role and tradeoff |
| --- | --- | --- |
| Quick Fang | Earth | 3 AP close light attack, 70% scaling, many uses |
| Battle Cry | Earth | Short physical-offense preparation |
| Ember Dart | Fire | Modest ranged special pressure |
| Smoulder | Fire | Small hit plus one shared heated tile, five uses |
| Splash Jet | Water | Modest ranged special pressure |
| Soothing Guard | Water | Four HP healing plus 8% temporary protection; five AP and three uses |
| Seed Dart | Earth | 3 AP ranged light attack, 70% scaling |
| Sprout Mend | Earth | Four HP healing and local restoration, three uses |
| Static Tap | Lightning | Small hit plus a short 5% Speed reduction |
| Spark Jab | Lightning | Close light hit, three AP and 70% scaling |
| Chilling Mist | Water | Short 10% Speed penalty; future allowances change, current points stay spent |
| Cold Snap | Water | Close hit plus a short 5% Attack penalty |
| Heavy Swing | Earth | Power nine, five AP, one-cell range, six uses |
| Brace | Earth | One AP brief 15% protection, only three uses |
| Withering Touch | Void | Close small hit plus 8% Attack penalty |
| Pebble Shot | Earth | Modest physical range without Vastra use |
| Air Dart | Air | Light special range, three AP and 70% scaling |
| Tailwind Step | Air | Prepare future movement/initiative; never refill the current turn |
| Thought Pin | Quantum | Modest ranged hit plus 5% Special Attack penalty |
| Pinprick | Earth | Two AP close chip damage at only 40% scaling |
| Crag Chip | Earth | A defensive body's modest special attack option |
| Ghost Touch | Spectral | Modest special pressure under ordinary clear-range rules |
| Drake Spark | Fire | Power five plus a shared heated tile; five AP and four uses |
| Shade Nip | Void | Light close hit plus a brief 5% Defense opening |
| Gentle Mend | Water | Three HP for three AP, four uses |
| Odd Angle | Quantum | Small special hit opens a 5% physical-defense follow-up window |
| Calibrate | Quantum | Modest temporary Defense adjustment |
| Repair Patch | Earth | Physical self-repair, five HP twice; no environmental restoration |
| Grit Guard | Earth | Equipped stationary guard; three useful direct-hit reactions |
| Stillwater | Water | Equipped stationary renewal; three useful two-HP heals |

The source/species learnsets are explicit. Class informs an authored kit's
physical/tactical role, but never sets individual affinity or automatically grants
every move of that affinity. Special affinities do not receive inherently stronger
numbers. These eligibility extensions do not approve new species or evolution.

## Hybrids and equipped passives

Hybrids use the ordinary target, primary calculation and range admission. A small
secondary status applies after the primary effect without additive stacking; a
field hybrid creates one shared tile, not the full cross-shaped terrain move.
New heat still waits for its ordinary round tick. Both components share one use,
one AP cost and one successful-move activity event. Their actually affected cells
are unioned for the existing Vastra/imprint contract. Healing-plus-protection may
be legal at full HP when protection is useful, even if local restoration is capped.

Equipped passives are distinct from the existing rolled class passives. They take
one of four move slots and cannot be armed manually:

- **Grit Guard:** ending a turn without moving prepares a guard. The next direct
  hit loses up to two damage, with a minimum of one. A useful reaction spends one
  charge; preparing it does not. Moving or being displaced breaks readiness.
- **Stillwater:** ending a turn without moving restores up to two missing HP,
  spending one charge only when HP actually rises. At full HP it spends nothing.

Neither passive consumes AP, creates an imprint, changes environmental Vastra,
or farms move activity. Both are limited to three triggers. Class effects retain
their own original counters and limits. A passive trigger is visibly named; Grit
Guard's read-only damage preview matches the hit that consumes its charge.

## Principles to carry forward

1. Price the whole package: damage, reach, coverage, safety, duration, displacement
   and secondary effects. AP and finite uses are different costs.
2. Give light attacks reduced damage scaling. Lower power alone still applies
   full offensive stats repeatedly and can make cheap multi-hits dominant.
3. Keep routine basics reliable. Reserve tight supply for broad control, efficient
   recovery and effects that do several jobs.
4. Give hybrids smaller components or higher costs. They should open combinations,
   not replace both specialist moves at full strength.
5. Make passive conditions observable and reactions bounded. An occupied slot is
   a real opportunity cost; inactivity must not produce unlimited recovery.
6. Preserve counterplay through positioning, range, terrain shared by both sides,
   separate physical/special offense and small temporary penalties.
7. Admit effects before spending resources. Use the same accounting for players,
   AI, previews and playback; one operation must not grant duplicate activity.
8. Study actual choice sequences, useful damage/healing, depleted moves, fallback
   use, and strategy variety. More move names alone do not establish depth.
9. Keep early content modest and all tuning in authored Godot resources. Later
   tiers should expand decisions before multiplying power or bypassing defenses.

## Source reconciliation and validation

Read-only SolHunterSource snapshot `115f3e87acc1716c7113523567c01e1666681885`:
`src/systems/tactics/species_moves.py` separates explicit class/species profiles
and innate traits, with modest initial attacks, restricted healing/status access
and stronger later progression. `src/systems/tactics/sol_combat.py` has no finite
per-move supply; its old one-action contract was already superseded by the
[approved AP budget](combat-action-budget.md). These new use limits, equipped
passives and early hybrid values are owner-authorized Godot design, not claimed
legacy rules. Existing source combat-loop/architecture evidence remains recorded
in the action-budget document. No private reference files are copied here.

`tests/early_combat_moves.gd` covers admission and supply, duplicate identities,
fresh encounters, finite healing, hybrid activity/secondary effects, passive
conditions and useful charge consumption, fallback legality, save/load and actual
HUD controls. Existing suites exercise sequencing, class effects, catalog
admission, capture and connected encounters. Test results and real limitations
are recorded below after verification. Numerical balance, human playtest and
AYN Thor acceptance remain open.

### Verification checkpoint

Godot 4.7.2 import/parse completed without engine or script errors. **4,984 checks
passed across 17 focused suites**: early moves 113; action budget 34; sequencing
39; consequences 64; pacing 70; affinity moves 100; AI/Seals/progression 78;
species catalog 243; stats/classes 3,686; first playable battle 60; battle feedback
22; combat polish 23; controller expedition 58; field menu 37; connected creature
rollout 243; save foundation 76; Vastra integration 38. Process exits and error
output were checked, rather than trusting assertion summaries alone.

The early-move suite also passed **113 rendered checks**, OpenGL compatibility at
1280×800 on the development RTX 3070. Its actual screenshot was visually inspected
for depleted cards, passive supply and the fifth fallback action. The live test
arms that fallback, completes a victory, and verifies one saved outcome with no
invented affinity imprint. The full unrelated world/presentation validator was
not repeated: its previously documented catalog native-exit instability remains
an existing limitation in [the AP checkpoint](combat-action-budget.md#validation).
Configured CI still includes the full validator and the new early-move suite.

An isolated current-build 9×9 major-fixture planner probe, 30 samples after five
warmups, measured median **5.918 ms**, p95 **7.525 ms**, maximum **7.627 ms**, with
the tactical snapshot unchanged. Ordinary move admission now avoids allocating a
fallback array or scanning the full loadout for every candidate. These are small
development-PC diagnostic samples, not device acceptance or a general frame-rate
claim. The observer retains spent-use maps in traces and final reports for later
balance study.

Ignored evidence: `artifacts/early-moves/` contains import, per-suite and rendered
logs, `supply.png`, planning samples and a file-hash manifest. All 50 definitions
are referenced by authored species pools. The specimen sheets and Inspector map
link back here; no final art or species acceptance is inferred.
