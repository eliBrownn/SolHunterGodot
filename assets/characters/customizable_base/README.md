# Low-poly character base

Owner-approved public fallback, November 2, 2026. The shared
`scenes/customizable_base.tscn` adapter defaults to this project-owned source.
Its opt-in `use_local_source` property uses the supplied human/rogue files only
when all are available locally; those files remain withheld from publication.
This fallback is provisional presentation, not acceptance of final character art.

Original neutral adult humanoid authored for SolHunter, October 31, 2026.
No external assets, clothing, hair, genital anatomy or nipple detail.

- `customizable_base.glb`: game asset; 3,104 triangles total, smooth normals,
  UVs, one continuous body and two replaceable eyes, 20-bone deformation rig.
- `customizable_base.blend`: editable Blender 2.82 source, A-pose.
- `scenes/customizable_base.tscn`: player adapter. Source height is 1.8 m;
  `prepare(height)` uses the existing player height, currently 0.85 world units.
  Soles are at the root origin; forward is Godot +Z.
- Idle/walk/run clips are provisional procedural motion. The existing terrain
  locomotion owner continues to own foot placement.

Skin color is exposed on the adapter and applies when prepared. The body's
ShoulderWidth, HipWidth, BodyBuild and FaceWidth blend shapes are modest authoring
starting points, not a finished customization interface or saved appearance schema.
Clothing fitting, facial expression and detailed finger animation remain future work.

Rebuild with Blender `--background --python tools/create_character_base.py` from
the repository root. This overwrites the generated GLB and Blender source; preserve
hand edits separately before rebuilding. Studio preview and mesh measurements are
written to ignored `artifacts/character_base/`. Focused validation:
`Godot --headless --path . --script tests/customizable_base.gd`.
Omit `--headless` to also exercise the production player bridge and terrain IK
with the real renderer. The focused rendered check passed with Godot 4.7.2.
