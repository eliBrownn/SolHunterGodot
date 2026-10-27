# Supplied asset pack

Source: user-provided `Pixel Art Top Down - Basic v1.2.3.zip`.
Creator: Cainos. Original [documentation](https://docs.cainos.net/pixel-art-top-down-basic).

PNG textures, the overview image, changelog, and documentation shortcut are
preserved from that archive. The archive did not include a standalone license
file. No license or redistribution terms have been added or changed here.

On October 26, 2026, the project owner confirmed that the pack's license terms
allow its source files in this public GitHub repository. This records the
owner's confirmation; it does not replace or amend the original license terms.

`metadata/*.meta.txt` preserves Unity texture importer records. `sprites.json` is
derived by `tools/import_basic_pack.py`: bottom-left Unity rectangles become
top-left Godot rectangles, and normalized bottom-origin pivots become pixel
offsets measured from the top-left. Runtime uses those named slices directly;
it does not require Unity or the Python conversion dependencies.

The game uses hand-selected pavement variants and continuous biome tinting.
The conversion preserves slicing and border metadata; it does not invent Godot
terrain-connect rules or import Unity scene, collider, shader, or prefab behavior.
Water artwork is temporary native drawing code.
