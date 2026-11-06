# Encounter pacing measurements

Phase 3 development slice, revised fixture set v2, October 28, 2026.
**Owner acceptance is open.**

The later [shared action budget](combat-action-budget.md) changes move handoff,
Speed movement and enemy activations. All numerical tables below are historical
measurements under the earlier rules; rerunning a retained fixture uses the new
economy. Current pacing requires new measurements and owner review.

Owner follow-up, October 28: normal combat now uses slightly slower presentation
defaults to leave space for eventual move animations: action/consequence/movement/
handoff **0.35/0.6/0.16/0.4 seconds**, HP bars and hit/heal flashes **0.3 seconds**.
Historical comparison tables below retain their measured settings; they do not
describe these new defaults. The explicit concise development preset is separate.
The [combat roadmap](combat-roadmap.md) requires a quick ordinary encounter and
a longer, meaningful major fixture accepted by the owner. This slice provides
repeatable measurements, playable probes, a comparison timing preset, and a
verified detour correction. The second iteration below improves the representative
matchups and development policies without changing production balance. It does not establish duration/action-count targets,
approve a production major encounter, or close that exit gate.

## Repeatable fixtures

`resources/combat_pacing/` contains Inspector-editable development recipes:

| Current recipe v2 | Existing profiles and choices | Geometry/conditions |
| --- | --- | --- |
| ordinary | Starter Bramblepup vs wild Bramblepup; Strike/Mend vs Strike | Open 9×9 arena |
| terrain | Starter Bramblepup vs Seedmote; Strike/Thin Passage/Mend vs Vine Whip | Seven-cell thin wall with open routes around both ends |
| major_probe | Starter Bramblepup vs starter-profile Bramblepup; Arc Bolt/Thin Passage/Focus/Mend vs Strike/Heat/Mend | Same thin wall; enemy can create shared heat |

These use actual Godot movement, damage, initiative, status/terrain and AI rules,
fixed class potency 1 for both participants, and the shared battle/library tuning.
The major probe uses an existing starter profile as a synthetic opponent; it is
not an authored boss or approved production encounter. No HP scaling, new ability, enemy reward,
species approval, or world-generation rule follows from these recipes.

Geometry is deliberately synthetic and drawn over the normal expedition scene.
Its walkable cells/route are probe authority; scenery behind the overlay does
not describe that geometry. This is a battle-pacing diagnostic, not connected
expedition traversal acceptance. Capture is disabled by the development battle
subclass, because synthetic opponents are not persistent capture identities.
Normal battles retain capture. Each process uses a fresh isolated user-data
directory; no personal expedition is loaded or changed.

The three original v1 recipes remain under `resources/combat_pacing/baseline/`.
They retain their version and original loadouts/geometry; `-Reference -LegacyPolicy`
replays the first diagnostic policies. Reports name both fixture and policy version
so a matchup change cannot masquerade as a pure algorithmic improvement.

## Running a baseline or owner playtest

From the repository root in PowerShell, supply the Godot 4.7.2 console executable
to `-Godot` if it is not on PATH:

```powershell
# All three recipes, two bounded scripted policies, existing presentation timing.
./tools/combat_pacing.ps1 -Godot 'path/to/Godot_console.exe'
# Same workload with the comparison feedback preset.
./tools/combat_pacing.ps1 -Godot 'path/to/Godot_console.exe' -Timing concise
# Play one fixture using normal mouse/controller battle controls.
./tools/combat_pacing.ps1 -Godot 'path/to/Godot_console.exe' -Play -Fixture ordinary -Timing concise
./tools/combat_pacing.ps1 -Godot 'path/to/Godot_console.exe' -Play -Fixture major_probe -Timing concise
# Compact four-run owner session, with optional in-game notes after each result.
./tools/combat_pacing.ps1 -Godot 'path/to/Godot_console.exe' -Session
# Retained original fixtures and original policies, for historical comparison.
./tools/combat_pacing.ps1 -Godot 'path/to/Godot_console.exe' -Reference -LegacyPolicy
```

F8 or closing the window writes an unfinished run and exits. A terminal battle
writes automatically and opens an optional pacing/clarity/notes questionnaire.
Save notes and exit, or skip them. The questionnaire uses the existing native-window
controller routing and keyboard focus. Skipped answers stay null; it never records
fixture acceptance on the owner's behalf. Manual
runs have a 20-minute recording limit; automatic rendered probes have two minutes.
Reports distinguish resolved terminal outcomes from unfinished/limited runs.

Each run writes `report.json`, `engine.log`, tracked `working-tree.patch` and a
SHA-256 code/resource `manifest.json` under ignored `artifacts/combat-pacing/<run>/`.
Reports include fixture version/hash, revision with dirty marker, profiles,
loadouts, initial conditions, passive units, engine and actual timing/rule settings.
Keep the source tree corresponding to the manifest for replay; a dirty marker
alone is not a reproducible revision and hashes are not a source archive.

Revised policy A approaches along a complete legal route, prioritizes a lethal
hit, and considers healing below one-third HP only when a detached execution of
the actual heal/automatic response improves retained HP or advances ongoing enemy
damage. Revised policy B also prepares Focus once during an approach turn without
a planned direct enemy hit, and uses Thin Passage when its legal route saves more
than one movement turn. These are diagnostic heuristics, not optimal play or new
player assistance. The forecast copies initiative, terrain/status and class state;
it does not use the display snapshot as a complete execution model.

Both policies retain 120-command and bounded presentation safety limits. Their
reasons and skipped nonprogressing-heal count are recorded. These bounds do not
limit live battle rounds. The human runner never supplies choices for the player.
See the [compact owner session](combat-playtest-session.md).

## What the report counts

- **Turn decisions:** accepted move uses, end-turn choices, and Seal attempts.
  Accepted movement choices and deployment/retreat are counted separately. Aiming,
  hovering and cancelled selections do not spend a command and are not counted.
- **Round reached:** the domain's round number, not a count of completed rounds.
  Enemy action announcements include repositioning as well as move/wait actions.
- **Configured holds:** sum of holds for displayed records. **Presentation time:**
  sampled time with input gated by playback; includes frame scheduling overhead.
  The fixed-step script samples 1/60 second before each presentation advance.
  Live runs sample actual frame delta. Neither is CPU execution time.
- **Choice time:** time with commands available, including deployment aiming.
  This is a proxy for voluntary thinking, including idle/distraction time; it is
  not a claim to measure cognition. Scripted reports set voluntary choice to null.
  Trainer travel, paused menus/inspection, and pending-result gates have distinct
  buckets. Total sampled encounter time is their sum, ending at terminal playback
  settlement; the result recap/return animation is excluded.
- **Repeated commands:** consecutive identical command/slot/target choices.
  These may still be useful. **Unchanged operations:** no net change in the
  compared tactical state after the response. **Repeated state visits:** repeated
  post-turn state with relative field/footing lifetimes and passive counters.
  These are stall indicators, not automatic diagnoses or anti-stall rules.
- **Damage-free turns/streak:** accepted turn decisions whose entire response
  caused no damage. Per-side actual healing/damage remain separate even when net
  HP is unchanged. The ordered trace retains each individual HP/status result and
  grouped terrain record's affected cells. Trace storage is capped at 4,096 rows;
  truncation is explicit while aggregates continue.

Measurements are opt-in development observers. Production battles allocate no
measurement or trace. Existing simultaneous field expiry, spread and connected
discharge stay grouped; no pauses are added per tile or particle. Individual
unit damage remains ordered separately so both HP results are readable.

## First scripted measurements — retained v1 baseline

Godot 4.7.2 on the development PC; seed label 17, recipe v1, fixed potency 1,
current working tree based on `96f384ffbd12c227b964b5f433a76901e8c3879f`.
These are scripted workload measurements, **not human encounter durations**.
Final recipe semantics include disabled synthetic capture; that change does not
affect either scripted policy. Timing values are action/consequence/movement/turn:
default **0.25/0.45/0.12/0.25 s**, concise **0.15/0.25/0.08/0.15 s**.

| Fixture / policy | Outcome | Turn choices + movement choices | Round reached | Default holds / sampled presentation | Concise holds / sampled presentation |
| --- | --- | --- | --- | --- | --- |
| ordinary / A or B | Victory | 14 + 1 | 14 | 28.64 / 30.62 s | 16.56 / 18.52 s |
| terrain / A | Victory | 21 + 2 | 21 | 45.74 / 48.87 s | 26.46 / 29.52 s |
| terrain / B | Victory | 27 + 1 | 27 | 58.16 / 62.12 s | 33.64 / 37.52 s |
| major probe / A | Exhaustion | 6 + 1 | 7 | 25.11 / 26.58 s | 14.39 / 15.78 s |
| major probe / B | Exhaustion | 6 + 1 | 7 | 24.62 / 26.05 s | 14.08 / 15.45 s |

All six runs finish with zero repeated-state visits and no damage-free turn
streak. Ordinary recovers 24 allied HP during the fight; terrain A/B recover
54/78 HP respectively. Terrain policy B takes more turns and healing despite
using interactions. That is evidence to investigate opportunity cost and useful
counterplay, not proof that an extra field action is meaningful. The major probe
currently defeats this scripted policy sooner than the ordinary encounter ends.
It therefore did not demonstrate the intended longer major pacing and motivated
the v2 iteration below.

An additional peer-profile variant (starter Bramblepup against starter Bramblepup,
same major arena, Strike/Mend/Spore Sting/Ward enemy loadout) hit the 120-command
bound: the cautious script repeatedly restored six HP while receiving six damage.
It caused damage on every exchange yet made no net progress; the cycle counters
exposed what a damage-free-turn check alone would miss. This variant was not
adopted as the major fixture or hidden by changing healing rules. Its diagnostic
recipe/log remain in `artifacts/combat-pacing/alternative_probe.gd` and
`alternative.log`; gameplay healing costs/caps and better counters remain design
questions for the measured owner session.

The concise preset cuts configured ordinary waiting by 12.08 seconds while
preserving every ordered result. It is available only to the fixture runner;
production defaults remain unchanged pending readability feedback. The preset
keeps consequence time at the existing 0.25-second HP-bar tween duration.

## Stall correction and decision audit

The first major diagnostic hit 120 commands with no HP damage: greedy approach
stopped at a short wall and protective actions repeated. Earlier evidence is
retained in the first report directory, rather than replaced by passing numbers.

After inspecting that trace, both the scripted approach and production enemy
fallback now find a bounded complete route to a legal offensive range before
choosing this turn's reachable destination. A short detour may initially increase
Manhattan distance. When no route exists, the enemy holds instead of oscillating
toward an unreachable anchor. The existing best immediate move/position scoring
still runs first; healing/damage/status weights and numerical rules are unchanged.
This is an explicit tactical behavior correction, not a damage or HP rebalance.

A domain-only detour diagnostic on Ryzen 7 5800XT/RTX 3070, 30 plans after five
warm-ups, measured median **0.859 ms**, p95 **0.923 ms**, maximum **1.190 ms**.
It uses the major wall layout with fields cleared, one-point enemy movement and
a Strike-only enemy facing the allied Sol across the wall. The exact temporary
workload and output are `artifacts/combat-pacing/detour_cost.gd` / `.log`.
This small current-build sample is not a historical speedup, frame-rate budget,
or target-device acceptance measurement.

## Revised fixture measurements — v2

These are fixed-step rule/presentation workload comparisons, not CPU profiles or
human duration targets. No timed profiling was performed alongside the active
optimization/validation work. The four report directories from this iteration
contain the current working-tree patch/manifests:
`20261028-142608-523-ordinary-default`, `20261028-142611-852-ordinary-concise`,
`20261028-142615-193-ordinary-default`, `20261028-142618-612-ordinary-concise`,
under `artifacts/combat-pacing/`. The first two are v2/new policies; the last two
are reference v1/original policies. Revision base remains
`96f384ffbd12c227b964b5f433a76901e8c3879f` plus the dirty manifest, not a new commit.

| v2 fixture / policy | Outcome | Turn + movement choices | Round | Retained HP | Default holds / sampled presentation | Concise holds / sampled presentation |
| --- | --- | --- | --- | --- | --- | --- |
| ordinary / A or B | Victory | 4 + 1 | 4 | 38 | 7.84 / 8.42 s | 4.56 / 5.12 s |
| terrain / A | Victory | 16 + 2 | 16 | 12 | 32.80 / 35.17 s | 19.10 / 21.37 s |
| terrain / B | Victory | 14 + 4 | 14 | 12 | 29.17 / 31.33 s | 17.03 / 19.08 s |
| major probe / A | Victory | 9 + 2 | 9 | 2 | 18.15 / 19.53 s | 10.65 / 11.93 s |
| major probe / B | Victory | 8 + 3 | 8 | 8 | 25.82 / 27.52 s | 14.98 / 16.52 s |

All six v2 runs finish with no repeated-state visits, and both timing presets
retain identical choices and individual consequences. The ordinary profile
change is deliberate: an existing wild Bramblepup matchup (36 HP, defense 15)
replaces the original Seedmote (36 HP, defense 21 plus finite Rooted Renewal).
It is a different representative matchup, not a claimed production damage boost.

Terrain B performs one actual Thin Passage and legal two-cell crossing. It
reduces allied damage from 56 to 44 and healing from 24 to 12 HP, with the same
retained 12 HP. It needs two more movement confirmations but two fewer turn
choices; that tradeoff remains for the owner to assess. Unlike the v1 water/charge
script, its benefit is measured rather than inferred from move variety.

The revised major opponent is the existing 44-HP starter peer profile, replacing
the 47-HP Ashkit. It adds no HP or new damage. Safe approach preparation gives
Focus two boosted special hits (8 rather than 6 damage); the complete sequence
wins with six Arc Bolts instead of eight and retains 8 rather than 2 HP. Shared
Heat also damages its caster for 4 HP. The enemy uses Heat twice
and changes route, supplying a readable terrain response. This trace has more
consequences and longer holds despite fewer turn choices; whether that extra
presentation is worthwhile remains an explicit owner question, not an automatic
success claim. Thin Passage remains an alternative in the major loadout; this
scripted major policy wins through preparation rather than using that move.

On this same v2 major fixture, the original heal-first policy still repeats the
six-heal/six-damage response and hits the diagnostic bound. The revised direct
policy skips that forecasted net-zero heal twice and wins. Nothing bans the
player from healing, alters Mend, adds a cost, or forces a timeout/damage tick.
This demonstrates a legal way out for this loadout; it does not prove all possible
healing matchups are free of stalemates. The regression retains the original cycle.

Post-iteration audit: keep v1 replayable; separate fixture changes from policy
changes; retain the weak Current/Charged Path findings instead of raising their
numbers; verify route and forecast purity; retain grouped terrain records and
individual HP results. Production combat, rewards/imprints/capture, creature
motion/rigs and render-cache code were not edited in this iteration.

Post-implementation audit:

1. Keep simulation policies distinct from human pacing. Null human thinking time
   and record actual settings rather than presenting scripts as owner acceptance.
2. Preserve individual damage/heal results and grouped area causes. A faster
   preset changes holds only, with identical ordered consequences checked.
3. Fix the reproduced route failure; do not add round limits, forced damage,
   hidden healing penalties, or inflated HP to make a fixture pass.
4. Keep major content provisional. Its current shorter defeat and terrain's
   healing burden are open design observations, not successful pacing targets.
5. Use isolated user-data and a synthetic capture guard for probe identities.
   Do not write measurement data into expedition saves or production encounters.

## Verification and owner feedback gate

For v2, Godot 4.7.2 import and **332 focused checks** passed: pacing 70,
sequencing 39, consequences 64, AI/Seals/progression 78, combat interface 23,
controller expedition 58. Twenty-four scripted runs cover the retained v1/legacy
and revised v2/policy pairs with unchanged and concise timing. All reported pairs
finish; the separate regression deliberately retains a bounded legacy heal loop.
Rendered 1280×800 OpenGL compatibility probes for all three revised fixtures
reach victory and committed once-only receipts with current creature presentation.
The optional review window was visually inspected and exercised through native
keyboard/controller routing; automation leaves owner answers null.

Evidence: `artifacts/combat-pacing-v2/import.log`, the six named suite logs,
`rendered-major.json`, `rendered-terrain.json`, `rendered-review-final.json` and
matching engine logs, plus `review.png`. Early exploratory output encountered a
transient parse failure while the geography agent edited its new helper; that
output was excluded from final evidence and the subsequent import/focused/rendered
logs are clean. No geography/cache/rig changes or timing profiles were made here.

The shared validator includes `tests/combat_pacing.gd`: reproducibility,
unchanged rules across timing presets, finite representative runs, timing bucket
separation, invalid delta handling, exact heal/hit cycles, rejected busy input,
frozen terminal clocks, wall detours, read-only planning, and unreachable harmless
exchanges. Relevant existing suites continue to cover combat consequences and
persistent outcomes. Validation evidence is recorded in the roadmap checkpoint.

Next owner session: play ordinary, terrain and major probe with default/concise
timing, retaining each report. Record which waits felt excessive, which cues
could not be read, where a choice changed the outcome, healing repetition, and
whether the major fixture earned its time. Then propose actual action/duration
targets and tune a second measured revision. No owner playtest has occurred yet;
feedback and targets remain **pending**, and phase 3 remains open.

## Mechanics evidence

Read-only reference at SolHunterSource
`115f3e87acc1716c7113523567c01e1666681885`:
[pacing/planning decision](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/docs/coordination/combat-reliability-pacing.md)
and [planning/simulation tests](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/tests/test_combat_planning_simulation.py)
establish bounded repeatable probes, read-only move planning, legal detours, and
the distinction between synthetic labels and authored/human acceptance. Python
fixture counts were not imported as Godot targets. No private source was copied.
