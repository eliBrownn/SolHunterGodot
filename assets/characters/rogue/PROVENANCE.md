# Owner-supplied rogue and animation rigs

Supplied October 27, 2026: `Rogue_Hooded.glb`, `Rig_Medium_General.glb`,
and `Rig_Medium_MovementBasic.glb`. Used locally under the owner's explicit
instruction. GLB was selected over the duplicate FBX files. The rogue GLB embeds
the palette texture; Godot extracts it on import. No external animation download
shortcut was opened or executed.

The supplied files contain no verified redistribution license. Keep these assets
local until source redistribution rights are established, as required by the
project standard. Do not push these binaries or the extracted texture merely
because local use is authorized. The original attachments remain untouched.

`scripts/player_model.gd` transfers the rigs' matching Skeleton3D animation paths
to the rogue model. Idle_A and Running_A are connected to actual movement state;
the other supplied clips remain available in its AnimationPlayer for authoring.
