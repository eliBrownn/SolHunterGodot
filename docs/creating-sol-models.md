# Creating another Sol model

The class-coverage batch adds twelve distinct examples under `scenes/sols/`,
linked by the [Sol Bible](reference/sol_bible.md#class-coverage). Load any in the
shared workshop. `sol_model_parts.gd` supplies geometry/contact helpers without
reusing a species body. Glass-Throat demonstrates tripod legs, Claspback six
legs, Bitterfrill a creeping sole and Foldling band-end support zones.

This is the practical model-authoring guide. Use the [Sol Bible](reference/sol_bible.md)
for creature design and roster decisions, [species data guide](sol-species-data.md)
for runtime records, and [pilot models](sol-creature-models.md) for current examples.
Adding a test model does not approve a species or allocate a final journal number.

## Start with the model workshop

The next batch has direct first-form review scenes:
[Ashquill](../scenes/ashquill_workshop.tscn),
[Rattlehorn](../scenes/rattlehorn_workshop.tscn) and
[Rimefold](../scenes/rimefold_workshop.tscn). These are small, cute direction-B
blockouts, separate from the catalog and normal expeditions. G cues signature,
J attack and H hit; each returns through recovery. The same keys work in the
shared workshop. Use Rest/Walk/Turns/Slope for this batch; flight/swim exercises
are only presentation tools and do not author movement capability.

1. Open [sol_model_workshop.tscn](../scenes/sol_model_workshop.tscn) in Godot.
2. Select its root, **SolModelWorkshop**. Drop your creature scene into **Model Scene**.
   Before you have one, select a scene from `scenes/sols/`.
3. Press **F6**. Use **M** to cycle Rest, Walk, Turns and Slope; **Space** to pause;
   **R** to reset. Adjust **Walk Speed** and **Affinity** in the root Inspector,
   then restart the scene. Test at both 0.3 m/s and about 1.33 m/s.
   M also offers Flight and Swimming; use the winged or amphibian rig for these
   pose exercises. Live navigation is reviewed in the separate
   [flight/swimming pilot](sol-flight-and-swimming.md).
4. Compare different affinities: the same species should retain its body colors
   and silhouette while the individual's effects change.

The workshop is separate from expeditions and creates no saved individuals. It
can review a model before it has a catalog record. Travel in this workshop is
an artificial art-review route, without navigation or encounter permission.

## Choose how to make the geometry

**Adjust an existing body for an early proxy:** duplicate one of the three
`scenes/sols/` scenes. Keep its Body Plan and adjust Model Scale, idle and movement
settings on the root. This reuses the same generated geometry; changing those
settings alone will not make a new silhouette or skin palette.

**Create a distinct body from primitives:** add a new script extending
`res://scripts/sols/presentation/sol_creature.gd`. Override `build_model()`, `animate_features()` and
`preview_bounds()` as shown below. Give a new MeshInstance3D scene root that script.
Do not edit an existing builder to create an unrelated species: its other scenes
would change too. The inherited Body Plan may remain at its default; these three
overrides replace the pilot-specific builder and appendage logic. Do not add a
fourth enum value without extending the runtime validation as well.

**Create geometry in Blender or another modeling tool:** use metres, apply scale,
put the ground origin at the creature's center, and export original geometry as
GLB under `assets/sols/<working_name>/`. Keep its source and license/provenance
record nearby. Instance its imported meshes under the control pivots described
below, or build an adapter for its own rig. Godot imports the GLB; the imported
scene is a child of the scripted presentation wrapper.

The current solver rotates rigid Node3D limb pieces. A skinned `Skeleton3D` mesh
needs an adapter mapping these targets to its bones; the current code does not
automatically discover, retarget or animate an arbitrary skeleton. Retain the
same presentation interface and contact semantics when adding that adapter.

## Coordinate and rig contract

| Item | Requirement |
| --- | --- |
| Root | MeshInstance3D with a script deriving from `SolCreature`; factory calls `configure()`. Orb-only scenes reject catalog admission. |
| Units and facing | One world unit is one metre/cell. The pilot art faces **+Z**, with +Y up |
| Origin | Ground center, with the creature's neutral contact pads near y=0 |
| Rig / Body | Named Node3D pivots; rotate or compress the visual body, never move the saved actor |
| Head | Assign the `head` control in the builder; shared attention animation uses it |
| Support limb | Hip/upper pivot → knee → foot/wrist pivot → `Contact` Marker3D |
| Leg lengths | Nonzero upper and lower lengths. Put pivots at joints, not at mesh centers |
| Support groups | Opposite diagonal feet share group 0; the other diagonal uses group 1 |
| Optional appendages | Separate ear, wing, tail, plate or leaf controls; animate these in `animate_features()` |
| Meshes | Attach rigid pieces below the pivot that should move them; avoid negative/nonuniform rig scale |
| Bounds | Return a model-local AABB covering all poses, tail, ears and appendages; include art scale |

`joint()`, `skin()`, `ellipsoid()`, `taper()`, `face()` and `limb()` are reusable
builder helpers. `limb()` creates its knee, foot and contact marker and registers
the support chain. For an authored or unusual limb, call
`register_support(hip, knee, foot, group)` yourself. Crown-Ear demonstrates wrist
support. All control names must be unique within one creature because the joint
lookup is keyed by name.

## Minimal distinct quadruped builder

Save this as a new script, for example `scripts/my_sol_model.gd`, and attach it to
a MeshInstance3D root in `scenes/sols/my_sol.tscn`. The name is illustrative;
choose a working name from the Bible when making an actual species.

```gdscript
extends "res://scripts/sols/presentation/sol_creature.gd"

func build_model() -> void:
    var hide := skin("8b7f69")
    var eyes := skin("1d2927")
    var pale := skin("dfd0aa")
    ellipsoid(body, "Torso", Vector3(0, 0.2, 0), Vector3(0.3, 0.28, 0.4), hide)
    head = joint(body, "Head", Vector3(0, 0.27, 0.2))
    ellipsoid(head, "Skull", Vector3.ZERO, Vector3(0.2, 0.18, 0.18), hide)
    face(head, 0.05, 0.085, eyes, pale)
    limb(body, "FrontLeft", Vector3(-0.12, 0.15, 0.12), 0.14, 0.06, hide)
    limb(body, "FrontRight", Vector3(0.12, 0.15, 0.12), 0.14, 0.06, hide)
    limb(body, "HindLeft", Vector3(-0.12, 0.15, -0.12), 0.14, 0.06, hide)
    limb(body, "HindRight", Vector3(0.12, 0.15, -0.12), 0.14, 0.06, hide)

func animate_features(_seconds: float, wave: float, _gesture: float) -> void:
    head.rotation.z += wave * 0.025

func preview_bounds() -> AABB:
    return AABB(Vector3(-0.3, -0.08, -0.35) * model_scale,
        Vector3(0.6, 0.65, 0.8) * model_scale)
```

The base class creates `rig` and `body` before calling your builder. It snapshots
joint transforms afterward. Each animation frame restores those transforms,
adds breathing/attention and feature poses, then solves support contacts. In
`animate_features()` change visual appendages, rather than writing the root
position or overwriting the planted feet after the solver.

For imported rigid meshes, replace `ellipsoid()` calls with instances of your
imported pieces attached under the same pivots. Make editable materials unique
to the creature instance when applying flashes. `skin()` does this automatically.

Override `released_support(gesture)` only when a signature intentionally lifts a
registered support. Return its hip control name or an empty string. The solver
continues planting all remaining contacts; a released foot must visibly lift and
return without moving the actor. Rattlehorn's three-foot test demonstrates this.

## Connect a finished test model to a species

1. Reserve a stable species and lineage ID in the Bible; display names can change.
   Check for an existing record first. Each ordinary evolution form gets its own
   species record, while related forms share the lineage ID.
2. Create a `SolSpeciesRecord` under `resources/sol_species/`, or duplicate a
   pilot record and make its editable nested Ecology and Traversal resources unique. Replace
   IDs, display name, class, stage, stats, moves and ecology deliberately.
3. Set **Presentation Scene** to your new scene and add the record to
   `resources/sol_species/catalog.tres`. Keep the catalog shared by services.
   Do not put an affinity property on the species; the individual supplies it.
   For flight or swimming, configure its Traversal profile and check the complete
   animated clearance envelope. Saved wild individuals retain admitted movement
   policy; test policy edits with new admissions. Rig pose controls alone do not
   grant a species permission to fly or swim.
4. Add an explicit test placement in a separate pilot Sighting Settings resource.
   Choose an unused trail X with a legal dry home. Current trail slots include
   8, 12, 18, 26, 34 and 48. Do not overwrite an existing species or saved identity.
5. In a new test expedition, encounter, deploy, capture and inspect the species,
   then save/load. Verify its actual individual affinity, moves and traits remain
   intact. Use the same scene in exploration, battle and the party preview.

Three total forms follow small → medium → large. Two-form size progression can
vary; a non-evolving species has its authored predetermined size. Model Scale is
art tuning, not an automatic evolution system or a change to the saved footprint.

## Review and validation

- Check silhouette and facial readability at the expedition camera distance.
- Check contact planting on flat ground and slopes, turns, stopping, pause and
  reset. At extreme speed or beyond limb reach the solver clamps; do not approve
  a new body from a standing pose alone.
- Check all appendage poses fit the menu preview; change the AABB when geometry
  or scale changes. Check minimum/maximum supported art scale.
- Keep species colors separate from affinity effects. Test several affinities.
- Run `tools/validate.ps1` with Godot 4.7.2. Existing catalog/model checks cover
  the three pilots; extend them deliberately for the new species and body.
  `tests/sol_procedural_ground.gd` exercises contact errors, frame rates, camera
  rebasing, route replay and pause. Merely adding a catalog row does not certify
  an unfamiliar rig.
- Record the art source, model scene, rig controls, bounds, settings and any
  limitations in the species sheet. Keep proposed art distinct from owner approval.

Common problems: a magenta material indicates a missing import/material; a generic
creature means the species lookup used provisional art. Orb bodies are no longer
allowed in gameplay; route all views through `SolSpeciesView`. The
[design handoff](sol-creature-design-handoff.md) covers class variety and next candidates.

For rig troubleshooting, feet floating above the floor usually mean the origin, chain lengths or contact
points are wrong; walking while the camera pans means relative screen positions
were supplied instead of absolute route positions; clipping in menus means the
declared bounds are too small. Restart/rebuild views after editing scene defaults.
