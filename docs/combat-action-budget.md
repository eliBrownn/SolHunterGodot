# Shared combat action budget

Owner-approved direction, October 28, 2026. This supersedes the earlier
one-move-ends-the-turn behavior and the roadmap's prohibition on new action costs
for this specific slice. Numerical costs and Speed conversion are initial tuning,
not final balance or owner playtest acceptance.

## Turn rules

The later [early-move slice](early-combat-moves.md) adds finite encounter uses,
per-move AP variation, light-attack scaling, hybrids and equipped passives. The
two/four-point figures below describe the ordinary baseline, not every authored
move. Passives are automatic, take a loadout slot and have finite useful triggers.

- Each Sol starts its turn with **6 shared action points (AP)**.
- Authored attacks and healing cost **4 AP**. Terrain, buffs, debuffs and other
  setup/status moves currently cost **2 AP**. Each move has its own adjustable
  positive cost; there is no reserved attack pool or separate setup quota.
- Setup then attack, attack then setup, and three different setup actions are
  legal. Successful moves keep the same turn open, including at zero AP.
- **End turn** explicitly advances initiative and recipient-turn statuses and
  passives. A terminal result still ends combat immediately. Unspent AP do not
  carry over. No points refill after a move, camera change or inspection.
- Effective Speed supplies movement-only points at turn start: currently
  `floor(Speed / 10)`, capped at 3, then adjusted by existing class movement and
  disruption. Buffing Speed mid-turn does not refill that allowance. Speed keeps
  its existing initiative role.
- Routes spend free movement first, then shared AP for any remaining cost.
  Existing rough/current/wind/warp/phasing costs still apply; terrain effects
  remain shared. Movement can be split around moves. Backtracking refunds nothing.
- Player and enemy share admission, move costs and movement spending. Enemy
  planning reserves enough AP for its selected move after paying for its route;
  the bounded coordinator continues until no useful affordable action remains.
- A Seal attempt costs 4 AP so an already-spent attack cannot grant a free
  capture action. Existing capture odds, unlimited development supply and failure
  handoff remain: failure ends the turn, success resolves capture.

Identical buffs do not stack indefinitely; their existing refresh/recipient
duration rules remain. Identical unchanged terrain is rejected before AP,
activity or presentation mutation. Distinct terrain placements remain legal
within the budget; whether repeated placement is interesting needs playtesting.
This slice adds no cooldown, action-type quota, trust rule or damage formula.

## Authoring and presentation

`BattleSettings.action_points`, `speed_per_movement_point`, `movement_points`
(the Speed-derived free movement cap), and `seal_action_points` apply to new
battles, including expeditions loaded before entry. The current battle snapshots
them. `SolMove.action_points` is stored with newly admitted/learned moves. Saved
movebooks retain their authored cost; snapshots without an explicit cost use
4 for attack/heal and 2 for other effects. Start a new expedition when reviewing
edited library costs. See [Inspector tuning](inspector-tuning.md).

The HUD shows current/max AP and free movement, labels move and Seal costs,
explains insufficient AP, and previews how much of a route spends free movement
versus shared AP. Presentation remains sequenced; input returns to the same
actor after a move. Busy playback blocks all further commands.

Pacing reports now retain AP/free movement in their trace and repeated-state
signature. Previous timing tables describe the older action economy and cannot
establish current pacing or balance. Diagnostic policies explicitly end turns
when finished; healing forecasts include that handoff. Historical fixtures retain
their recipes, but running them now uses the new rules, not a historical engine.

## Reference reconciliation

Read-only SolHunterSource evidence at
`115f3e87acc1716c7113523567c01e1666681885`:

- `src/systems/tactics/sol_combat.py`: `_acted` allows one move; `end_turn`
  owns status ticking and initiative advancement.
- `src/systems/tactics/live_encounter.py`: successful moves previously triggered
  `end_turn` and enemy activation; movement had an independent tile allowance.
- `tests/test_combat_loop.py`: path spending, rejected actions, real-loop outcomes
  and capture identity/persistence regressions.
- `docs/coordination/combat-architecture.md`: legal positioning, shared read-only
  calculations and centralized durable outcome ownership.

The owner's explicit shared-budget and Speed decisions supersede that earlier
one-action contract. Preserve the source's ownership and admission boundaries;
Godot remains generation authority. No private reference files are copied here.

## Validation

`tests/combat_action_budget.gd` covers action order, setup-only turns, rejection
purity, per-move tuning, Speed movement, shared movement costs, no mid-turn refill,
enemy budgets, live HUD/playback and expedition restoration after retreat. The
existing sequencing, consequences and encounter suites now use explicit End turn
where their scenario requires an enemy response. Numeric balance, human pacing
and AYN Thor acceptance remain open.

Focused Godot 4.7.2 checks passed: action budget 34, sequencing 39, consequences
64, pacing 70, affinity moves 70, first playable battle 60, AI/Seals/progression
78, combat polish 23, controller expedition 58 and battle feedback 22: **518 total**.
The action-budget suite also passed all **34 rendered checks** at 1280×800 with
OpenGL compatibility on the development RTX 3070. The actual HUD screenshot was
visually inspected. Ignored evidence is under `artifacts/combat-action-budget/`,
including per-suite logs, `rendered.log`, `budget.png` and source hashes.

Fresh diagnostic observations: the direct major policy now exhausts while the
preparation policy wins. The old thin-wall script now uses more actions and
healing than the detour; its old superiority assertion was replaced with finite
execution/actual-use checks. Neither observation ratifies balance. The exact
heal/hit-cycle regression remains separate from the old major policy, which no
longer loops under these rules. No production damage/healing numbers were raised
to preserve a historical scripted result.

The full shared validator was attempted. It stopped after 24 passing suite reports
when `tests/sol_species_catalog.gd` reported 243 checks/zero failures but the engine
returned nonzero. An isolated retry passed the same 243 checks with exit zero.
Similar unresolved native exit instability is already recorded in
[the anatomy review](sol-creature-anatomy-review.md); this retry does not establish
a clean full-validator pass. Logs: `full-validation.log` and `catalog-recheck.log`.

Additional checks passed for stats/classes (3,686), inspection cards (22), text/UI
reachability (61), mouse controls (36), mouse-first UI (29) and the connected
creature rollout (243). A separate world-interaction check failed its expectation
that Observe describes an `orb`, which conflicts with the already-approved
creature presentation. That appearance assertion is outside this combat change
and was left intact. A concurrent Vastra visual edit briefly caused a compile
error; that run is excluded from passing evidence and was rechecked after the
visual script's type annotation was corrected.

A domain-only current-build probe of the 9×9 major fixture measured enemy planning
at median 5.056 ms, p95 5.350 ms and maximum 5.353 ms, 30 samples after five warmups.
Planning preserved the snapshot. This is one development-PC workload, not a
historical regression comparison, frame-rate guarantee or Thor acceptance. See
`planning-cost.log` and the retained `profile_budget.gd` for the exact workload.
