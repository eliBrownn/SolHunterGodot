# Sol Lab

Sol appearance authoring runs standalone in the map-first project. In the
inherited expedition, open **Sol Lab [F9]** beside
**Development Lab [F8]**. F9 returns to the same suspended expedition; F8 switches
to Development Lab. Each workspace retains its in-memory edits between visits.
Standalone use remains available through `scenes/sol_lab.tscn` (F6) or
`tools/open_sol_lab.ps1`.

## Authoring workflow

Use the section selector above the left sidebar:

| Section | Working tools |
| --- | --- |
| Bodies | All 18 current classes, with at least three structural presets per class: 54 editable anatomy studies. Choose a class and shape, then Start from selected body shape. Dirty work is saved before switching. |
| Shape | Select visible anatomy or a part in the list. Sliders show current proportions; Shift + left-drag adjusts the selected part's primary dimension. Reset affects that part and respects inherited limits. Feature locks preserve exact values during generation. |
| Explore | Repeatable seed and variation-range slider. Generate six candidates; compare them to the original batch parent, inspect changed values in button tooltips, adopt one, or restore the parent. Next seed explores another batch. |
| Species | Species/individual editing, six support plans, structural forms, optional ears/tail/wings/horns/fins, independent visual-core anchoring, affinity preview and per-feature allowed minimum/maximum. Individuals inherit their species' structural anatomy and bounds. |
| Surface | Body color in Shape; core tint, accent color, plain/striped/spotted/banded markings, roughness, symmetry/asymmetry and silhouette review. Affinity does not select skin or core tint. |
| Motion | Idle, walk/run, turns, slope, flight/swim and signature/attack/hit poses; pause and pose scrubbing; playback/movement speed; saved stride, foot lift, idle, wingbeat and swim tuning; joint markers, contact readings and one-metre reference. |
| Review | Per-part annotations, general notes, copied reference images, baseline image overlay and recipe restoration, appearance favorites, design stage, scene/recipe export, and explicit reviewed appearance application to an existing species. |

Right-drag orbits; the wheel zooms. Front/Side provide quick views, F/Perspective
fits the current model, and Turntable rotates the camera. The comparison gallery
uses independent worlds with matching cameras. Edits are undoable; a shape-slider
gesture and a candidate adoption each use one undo step. Ctrl+S/Z/Y work outside
text editing, which retains its own keyboard behavior.

## Class body coverage

The library covers Beast, CinderKin, Abyssal, Bloom, Stormforged, Frostbound,
Warborn, Blight, Earthbound, Zephyr, Mindweaver, Chitin, Eldritch, Wraith, Wyrmkin,
Umbral, Construct and Feyborn. Each has three different combinations of support
plan, proportions and structural anatomy, not just color swaps. Plant/fungal
forms, shell/plate forms, folded/ring/thread structures and assembled forms give
classes different starting silhouettes. These are editable proposals rather than
newly approved roster species. Internal class identifiers retain the current
catalog mapping; legacy Stonebound is not repurposed as Eldritch.

`tools/sol_lab_shapes.gd` owns preset recipes under the Sol Bible's design
boundaries. `artifacts/sol-lab/class_shapes.png` is the rendered 54-shape review
board. No preset chooses an individual affinity or grants traversal capabilities.

## Canonical wispy visual cores

Owner canon and clarification, October 30, 2026: the wispy particle ball is the
Sol's **visual core**, not a required anatomical head. The Worldbuilding Bible
and Sol Bible record this clarified decision. Physical heads remain optional
anatomy; the core can be attached to the head, chest, back, root or tail, or given
a free anchor with independent three-axis offsets. Core location establishes no
brain, energy reserve, affinity restriction or other gameplay rule.

`sol_visual_core.gd` reuses the existing Vessel particle/wake component and shaders
with a spherical grouping mode. Shape / **Core** exposes core size, three offsets,
particle density, wisp length/speed, spread, softness, opacity and glow. Species
selects the attachment anchor; Surface owns core tint. Shape / **Head** retains
separate anatomical proportions, while Species can toggle anatomical head and
muzzle modules. The 54 body studies and catalog/legacy views share the visual-core
component. Existing catalog anatomy is preserved, with a separate core attached.

The old `sol_wisp_head.gd` path and early `wisp_head` properties are compatibility
aliases. Earlier head-tint values remain readable as core-tint input. Core motion
consumes the caller's visual clock; it does not spend ecological energy or create
transactions. Actual particle review uses the game's Direct3D 12 renderer.

## Species, individuals and repeatability

Species mode owns structure and allowed numeric ranges. Individual mode snapshots
that species recipe and inherits its body plan, structures, modules, class and
bounds. Switching back to Species makes the current appearance a species draft;
Undo can recover the previous individual. Individual affinity is a separate
preview choice and never supplies body structure or movement permission.

Each generated feature has a separate deterministic random stream. Locking a head
feature does not reroll a tail. Saved revisions include the seed, range, locks and
original batch parent, so reopening reconstructs the gallery. Manual shape/color
changes and changed generation settings dismiss stale candidates; Undo restores
the prior batch. Favorites retain proportions, structural choices and surfaces.

## Revisions and review handoff

Save revision always writes a new document. New/Open saves dirty work first;
a failed save cancels the switch. Closing likewise saves dirty work or keeps the
application open on failure. Existing version-1 drafts are readable; newly added
appearance fields receive defaults. Unsupported versions and invalid data are
rejected without replacing the current draft.

All local data lives under `user://sol_lab/`, separate from expedition saves:

- Draft JSON revisions retain the appearance recipe, species constraints,
  individual settings, notes, references, favorites and generation setup.
- Reference images are copied to a bounded local library and displayed in Review;
  removing a reference from one draft preserves files used by earlier revisions.
- Capture + notes writes a preview PNG and JSON with recipe, camera, motion and
  diagnostics. Status messages show the absolute destination.
- Comparison baselines retain a screenshot, recipe and camera for this session.
  They are visual comparisons, not a deterministic replay of past simulation.
- Export writes an editable `appearance.tscn`, `recipe.json`, review metadata,
  copied references and a preview when rendering is available.

**Apply reviewed appearance to target** requires Species mode, an existing catalog
species, a matching class when assigned, and a deliberately selected Reviewed
stage. It installs a reversible local appearance override through the existing
`SolSpeciesView` factory. Existing actors use their previous view until the next
normal rebuild; newly created wild, combat, companion and menu views use the
reviewed appearance. Restore target's original appearance removes the override.
Neither operation changes species stats, identity, moves, ecology, captures,
traversal rules or expedition save schema. Exporting a new-species candidate
produces presentation assets; new gameplay admission still requires authored
species data and owner review through the established catalog workflow.

## Ownership and validation

Shared runtime owners are under `scripts/sols/presentation/`: recipe, modular
body, visual core, game-view adapter and local appearance library. Tools under
`tools/` own workflow panels and class presets; compatibility entries preserve
existing lab references. Runtime views extend the existing SolCreature contract
and use the existing SolGroundMotion support solver. Lab exercises do not create
movement capabilities or introduce game mechanics.

Use Godot 4.7.2 and disposable APPDATA folders for tests that exercise the library:

- `tests/sol_lab.gd`: editing, selection, undo/redo, generation and saved-gallery
  reconstruction (36 checks headless; additional rendered capture checks).
- `tests/sol_lab_authoring.gd`: class coverage, all 54 shapes, inheritance,
  references, materials, favorites, motion, reviewed export/factory admission,
  restoration, and catalog/legacy visual-core coverage. Direct3D 12 with
  `-- --render` also captures every workflow section and the 54-shape board.
- `tests/development_world_toggle.gd`: game/lab isolation, return controls,
  retained drafts/variations and direct cross-lab switching.

The configured CI validator remains unchanged; a focused pass is not a full-game
regression pass. Current tools provide modular
procedural blockouts and pose review, not arbitrary mesh sculpting, finished
species art, a complete retargeting system or newly invented gameplay rules.

### October 30 validation evidence

| Check | Observed result |
| --- | --- |
| Current authoring and visual-core journey | 385 checks passed using Direct3D 12, including all 54 class shapes, independent core anchors, optional physical heads, and catalog/legacy coverage. `artifacts/sol-lab/core-render.log` |
| Current edit/save/generation journey | 36 checks passed headless. `artifacts/sol-lab/foundation-final.log` |
| Current authored creature models | 93 checks passed. `artifacts/sol-lab/core-models-final.log` |
| Current procedural ground movement | 222 assertions passed after the stale encounter-continuity assertion was repaired; the fixture retains two Canvas/ObjectDB shutdown warnings. `artifacts/sol-lab/core-ground-final.log` |
| Current main-game/lab round trip | 31 checks passed using Direct3D 12. `artifacts/sol-lab/core-game-entry.log` |
| Script ownership / UID check | 181 mapped scripts and UIDs, zero failures. |
| Broader integration checks during delivery | Catalog 243, game rollout 243, companion 40 and menu 41 assertions passed. Those older suites also reported small Canvas/ObjectDB shutdown warnings; they are not described as warning-free runs. |
| Editor import | Registered the scripts and completed the scan/layout phase, but logs a Windows safe-save error at startup. Import is not claimed clean; the full configured validator was not claimed passing. `artifacts/sol-lab/import-final.log` |

The movement suite initially failed an obsolete encounter-freeze assertion.
`authored_sightings.gd` already advances unrelated wildlife during encounters under
the October 29 combat-continuity rule. Its focused test now checks continued route
and gait motion while preserving the separate true-pause assertion; no gameplay
movement behavior was changed for this repair.
