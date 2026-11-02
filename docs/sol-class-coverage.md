# One playable first form per class

Owner direction, October 28, 2026: fill each class with one playable first-form
creature. The [Sol Bible](reference/sol_bible.md#class-coverage) remains the roster
index and approval authority. Six concepts keep their explicit approvals; twelve
existing proposed candidates are selected for this provisional implementation.
This does not finalize their concepts, names, families or release art.

![Eighteen playable first-form blockouts](../artifacts/sol_class_coverage/class_board.png)

This engine-rendered board uses the actual catalog scenes and one fixed review
camera per cell. Affinity motes are hidden only for this body comparison; live
gameplay keeps each individual's effects. The first three pilots retain their
existing sizes; the fifteen subsequent models use provisional art scale 0.65.
The board is ignored local review output, not a required runtime asset.

## Delivered content

Twelve additions fill the previously missing classes: Browguard, Bitterfrill,
Knucklemole, Sailcrest, Glass-Throat, Claspback, Foldling, Mournveil, Pebblewyrm,
Shadepelt, Kilnling and Thimblehart. The Bible links each canonical production
sheet and its runtime record. Their unique species/lineage keys are 0007–0018.
Each has a distinct builder and scene, provisional level-three six-stat profile,
seven existing eligible moves/four initial moves, ecology, normal trail sighting
and species-specific companion gesture/caption.

Anatomy varies across padded biped, creeping sole, digging quadruped, kite
membranes, three-point chamber support, six walking legs, folded ribbon body,
living veil, draconic quadruped, matte-fur mantle, ceramiclike living seams and
cup-tipped antler buds. Geometry/support helpers are shared; bodies are not
recolored copies. Materials are species-specific and independent of affinity.
Juvenile proportions and reduced ornaments preserve the small/cute first-form
direction, rather than the earlier mature-looking board.

Bitterfrill has four solved contact zones on its continuous creeping sole,
not four invented external legs. Foldling has three supported band-end zones.
Glass-Throat has three real legs, Claspback six. Actual joint chains retain
presentation-only ground contacts. Rest, alert, walking, turn, signature, attack,
hit and recovery use the shared driver plus distinct appendage controls.

All twelve additions are ground-only in this first slice. Sailcrest's anatomy
does not yet admit flight; veils do not grant obstacle crossing; digging gestures
do not mutate terrain. Existing Crown-Ear low flight and Reedback surface swimming
remain available. Habitat directions remain design references; explicit trail
homes are playtest placements, not complete ecological distributions.

Run the normal `scenes/world_3d.tscn` game. New/current-format-load admission adds
the explicit individuals once, preserving saved identities and starters. Capture
through existing rules, then use **Sols > Party > Set active** for that actual
owned individual. The same catalog scene serves wild encounters, battle,
following and menu previews. The model workshop can load any new scene directly.

All entries have ordinary form 1 and footprint 1. The existing provisional
three-slot training-capacity parameter remains playtest tuning; no later forms,
final family counts or evolution triggers are created. Finished art, final
balance and target-device acceptance remain open.

## Eldritch boundary

Eldritch has a separate runtime identity with a zero-potency, explicitly unassigned
passive. Nonzero potency bounds reject until an effect is authored; these are not
unused balance sliders. Legacy `stonebound` retains its original
identity/behavior for saved and prototype content and is not a nineteenth current
class. The settings now validate eighteen current definitions plus that legacy
definition. An actual Eldritch passive needs separate design authoring.

Read-only reference evidence remains SolHunterSource local HEAD/ref
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` and the previously recorded catalog,
identity, capture and following evidence. The additional read of
`SOL_CLASS_AFFINITY_SPEC.md` describes legacy Stonebound; it supplies no Eldritch
passive. Later Godot Bible direction takes precedence. No private source content
or generator was copied, and no existing passive rule was changed.

## Focused verification

Following the [project standard](PROJECT_STANDARD.md#routine-creature-integration-and-proportionate-checks),
this batch uses the affected checks and a single rendered board, rather than
repeating unrelated terrain/weather/full-project suites.

- Godot 4.7.2 import/parse: passes.
- Class coverage: **203 headless / 203 rendered checks**, including eighteen
  unique current classes, real support counts, no-orb bodies, independent affinity,
  bounded geometry, two walking speeds, planted error below 2.5 cm on a moderate
  slope, and signature/attack/hit/recovery envelopes. The board was visually reviewed.
- Main-scene rollout: **243 checks** on the default seed and seed 17.
- Class/stat checks: **3686**, including the neutral Eldritch definition.
- Existing AI/capture checks: **78**.
- Representative main-game journey: **151 checks** using Bitterfrill, Glass-Throat,
  Claspback and Foldling. It covers Observe/Engage, combat, capture, selected
  following/gesture, menu preview and real save/new/load across the new support
  categories. This is not a claim of twelve separate manual battle playtests.

That journey exposed an enemy route lookup failure. Execution now uses the exact
route admitted by its plan instead of recomputing a path map after selection.
The fresh-enemy-turn AI fixture resets its own movement/AP, and the Feyborn
duration fixture finishes the casting turn before counting recipient turns.
These corrections do not change AP, move, duration or class-passive rules.

```powershell
& $godot --headless --path . --script tests/sol_class_coverage.gd
& $godot --path . --rendering-driver d3d12 --script tests/sol_class_coverage.gd -- --class-board
& $godot --headless --path . --script tests/sol_anatomy_integration.gd -- --species=sol_species_0008,sol_species_0011,sol_species_0012,sol_species_0013
```

The reusable integration test still defaults to the prior three additions when
no species argument is supplied. CI's validator selects this representative new
batch and includes the coverage suite. Logs/board are under
`artifacts/sol_class_coverage/`, with separate workspace-local engine-data folders.
Historical full-validator/atmosphere failures are not promoted to a clean full
result by these focused passes. All-frame gait polish and AYN Thor acceptance
remain separate from this playable content slice.
