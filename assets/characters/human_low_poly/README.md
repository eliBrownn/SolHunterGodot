# Supplied low-poly human

Current player base, supplied by the owner on October 31, 2026 as
`Human LowPoly1.fbx`. Original author/license information was not supplied;
preserve the source locally and verify redistribution rights before publishing it.

- `human_low_poly.fbx`: unchanged owner-supplied source.
- `human_low_poly.blend`: prepared editable source with a 20-bone movement rig.
- `human_low_poly.glb`: Godot asset, 650 source vertices / 1,296 triangles, UVs,
  smooth shading. Original topology/proportions are preserved; no subdivision,
  decimation or voxel remeshing is applied.

Source SHA-256: `180df3d5bd59f338c611599dab43c93f66790b8b33c8d039f1185018b4138108`.

The supplied FBX has no rig or animations. Preparation normalizes its height to
1.8 m, anchors the soles at zero, clears faceted custom normals and adds automatic
skin weights. The existing `scenes/customizable_base.tscn` adapter scales this to
the existing 0.85-unit player height. `rogue_animation_retarget.gd` maps Idle_A
from `Rig_Medium_General.glb` and Walking_A/Running_A from
`Rig_Medium_MovementBasic.glb` onto this rig, preserving their duration and sampled
motion. Bind-pose correction handles the rogue's T-pose versus the human's lowered
arms. Bone lengths remain human proportions; root travel is stripped and scaled
hip bob is retained. The procedural terrain gait is disabled for this adapter so
it cannot replace the authored leg motion. The existing actor owns travel and
ground height; per-foot terrain IK is not applied to these clips.
The blank adult mannequin has
no intimate anatomy; clothing, facial detail and a customization menu remain open.
Skin Color applies when the adapter is prepared. No appearance blend shapes are
provided by this asset.

Rebuild with Blender 2.82:
`blender --background --python tools/import_human_low_poly.py`.
This overwrites the prepared Blender/GLB files; preserve hand edits separately.
Focused validation: `Godot --path . --script tests/customizable_base.gd`.
Use the real renderer for the full player binding/animation lifecycle. Godot's
headless dummy renderer reports a null-material error on skinned-mesh disposal;
the rendered check passes without engine errors.
