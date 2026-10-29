# Pilot creature models and articulation

October 28, 2026. Step three of the [Sol Bible production plan](reference/sol_bible.md#production-integration-plan).
Status: original primitive 3D blockouts with articulated control hierarchies and
essential cosmetic poses. Shapes, proportions and colors remain art proposals.

For step-by-step creation of another creature, use [Creating another Sol model](creating-sol-models.md).
The [model workshop](../scenes/sol_model_workshop.tscn) provides independent rest,
walking, turning and slope review. The first [procedural ground pass](sol-procedural-ground.md)
now drives the rig from committed movement and terrain contacts.

The shared species records now select three separate scenes:

| Species | Scene | Distinguishing controls |
| --- | --- | --- |
| Crown-Ear | [Bat blockout](../scenes/sols/crown_ear.tscn) | Broad paired ears, wing/elbow/wrist/tip chains, hind feet, short tail |
| Reedback | [Amphibian blockout](../scenes/sols/reedback.tscn) | Four webbed feet, overlapping plates, flexible reeds, two-part paddle tail |
| Bellroot | [Botanical blockout](../scenes/sols/bellroot.tscn) | Four root feet, bulb and low face, six leaf base/tip pairs and canopy |

[SolCreature](../scripts/sol_creature.gd) builds low-resolution original meshes
and named Node3D pivots when the shared presentation factory configures a scene.
These are rigid articulated parts, without a skinned mesh or external skeleton.
Each limb has a knee, foot pivot and `Contact` marker for the next movement step.
The wing membrane now follows the elbow, wrist and tip controls using reusable
triangle meshes; animated deformation does not allocate new meshes each frame.
Ground contacts use the shared support solver.
Geometry is generated from
Godot primitives and a small original triangle membrane. No external model,
texture, animation pack or generated raster artwork is used.

## Connected animation and effects

All three have deterministic breathing, head attention and secondary motion.
Wild idle selects the lower rest pose; existing non-idle roaming actions select
alert. A periodic rest gesture opens Crown-Ear's listening crown, raises a
Reedback forefoot toward its plate, or gathers Bellroot's leaf skirt. These are
presentation gestures without changes to relationships, ecology or saved state.

Battle effect cues trigger an attack accent on the acting creature; damage cues
trigger a hit accent on the recipient. Each returns to its base pose over the
configured action duration. The existing impact flash and squash also reach the
creature. Cosmetic timing does not delay rule execution or add combat bonuses.
There are no authored animation clips: these first essential poses are generated
from joint transforms, blended with the idle motion. Travel, takeoff, landing and
swim transitions are reserved for the actual movement implementation.

Species palettes remain fixed across individual affinities. Existing saved
affinity motes, battle rings and flashes carry individual affinity. The legacy
orb body and halo are hidden for every gameplay model. Uncatalogued prototype
species use provisional creature bodies from `sol_prototype_creature.gd`:
Seedmote/Bloom is a seed walker, Bramblepup/Beast a long hound, Ashkit/CinderKin
an upright feline, and Rillfin/Abyssal a low finned amphibian. Unknown IDs get a
neutral creature without inferred class. These designs remain provisional.
Exploration, combat and menu previews all use
the same species scene. Preview cameras use a conservative creature envelope
instead of assuming a spherical body.

Legacy creature previews fit each anatomy's own envelope while retaining a minimum
margin for the independent affinity motes. This keeps small species readable
without clipping those effects in wide or narrow preview windows.

## Inspector and review

Select the root of a species scene in Godot. **Model Scale** changes art size;
**Idle Strength** and **Idle Rate** control the generated rest motion, and
**Action Seconds** controls attack/hit recovery. **Body Plan** selects the mesh
builder and must match the species scene. Rebuild the view after changing these
scene defaults. They do not change cell occupancy, taxonomy, saved traits or
movement permissions. The shared Sol visual settings still control affinity
effect count, palette and speed; legacy orb diameter/hover/bob do not size or lift
the creature body. Wingbeat Rate and Swim Stroke Rate now drive the connected
[flight and swimming poses](sol-flight-and-swimming.md); capability and clearance
are authored in the species Traversal profile.

Open [the pilot expedition](../scenes/sol_species_pilot.tscn) with F6 to encounter
the three species. Capture and inspect them in the party menu to review the same
models. The [normal-game rollout](sol-species-data.md#normal-game-rollout) now also
places these three species in the ordinary expedition; starter choices are unchanged.
The first ground locomotion slice adds planted contacts, stride and heading along
existing legal routes. Subsequent [flight/swimming](sol-flight-and-swimming.md)
and [owned follow integration](owned-companion.md#owned-flight-and-swimming-integration)
connect these models to validated travel. Art scale remains provisional; model
tests alone do not establish traversal safety or target-device performance.

`tests/sol_creature_models.gd` checks scene routing, contact controls, mesh-count
bounds, geometry envelopes, affinity independence, repeatable idle poses,
rest/alert distinction, essential pose recovery and impact materials. It is
included in `tools/validate.ps1`. Render it with `-- --capture` to save a local
three-species studio image under `artifacts/sol_creature_models/pilot_models.png`.
The separate species catalog journey covers encounters, battle deployment,
capture, ownership, previews and save/new/load. Final results are recorded in the
[Bible](reference/sol_bible.md#step-three-creature-models-and-essential-poses).

The model test uses the presentation interface instead of a concrete
`SolCreature` type: the combination of that type and a preloaded catalog caused
a reproducible Godot 4.7.2 native shutdown crash despite passing assertions.
Removing that circular type/preload dependency restored a clean process exit;
the validator continues to reject nonzero exits and engine/script errors.
