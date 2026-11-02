# Downloaded asset comparison

October 29, 2026: owner supplied three ZIPs following the Asset Store search.
These are evaluation candidates, not adopted production art or new design canon.

## Licenses and provenance

| Download | Publisher | Included terms | Source |
| --- | --- | --- | --- |
| `EmacEArtStylizedGrass_Godot_2026-09-01_v1.3.0.zip` | EmacEArt (Maciej) | Personal/commercial project use; no redistribution of original or modified asset files, packs, collections or templates | [Store](https://store.godotengine.org/asset/emace-art/godot-stylized-vegetation-wind-shader/) |
| `Environment_Assets_-_Foliage_Sample_Pack-2.zip` | Renard Noir | MIT, copyright 2026; retain supplied copyright/license | [Store](https://store.godotengine.org/asset/renard-noir/forest-vegetation-sample-pack/) |
| `Environment_Assets_-_Rocks_Sample_Pack.zip` | Renard Noir | MIT, copyright 2026; retain supplied copyright/license | [Store](https://store.godotengine.org/asset/renard-noir/rocks-and-stones-sample-pack/) |

Terms above were read from the supplied archives, not inferred from download
price. All extracted assets remain under Git-ignored `artifacts/asset_store_review`.
Do not force-add the proprietary grass sources to a public repository.
The generated `provenance.json` records the supplied ZIP names and SHA-256 hashes;
each pack's original license is preserved next to its local evaluation files.

## Reproduce

Run `python tools/prepare_asset_store_review.py C:/Users/elija/Downloads` from the
repository root, substituting the directory containing all three named archives.
Python 3.8 or newer suffices. This creates an independent Godot project at
`artifacts/asset_store_review/project.godot`. Import it into Godot 4.7.2 and run F5.
The preparation script copies only art dependencies and licenses, rewrites
resource paths and removes stale vendor UIDs in text resources. It does not run
vendor demo scripts. Embedded sample-scene meshes avoid importing the much larger
FBX sources. Original ZIPs remain intact.

- 1: existing Quaternius trees, shrubs, grass and rocks with imported materials.
- 2: Renard Noir junipers, JelloBush, grass and round boulders.
- 3: same samples with a continuous, stylized EmacEArt wind meadow.
- N changes noon/sunset/night; drag orbits, wheel zooms, R restores framing.

The tree/shrub/rock variants use the same scatter seed, positions, target heights,
camera, ground and lighting. View 3 now replaces sparse clumps with an expansive
meadow. Shapes and material treatment differ intentionally. This preview
does not reproduce the main game's complete
painterly material, mood, weather or streaming treatment. Vendor grass uses its
own animated shader time. Review wind motion live; static captures alone cannot
establish animation quality. Wind/gust strengths are exported on the review root
and apply at restart; defaults are provisional light breeze values (0.14/0.25).
Any production use must consume the existing weather owner.

For automated captures, launch that project with `--rendering-method forward_plus
--rendering-driver d3d12 -- --capture-review` on this Windows machine. It writes
nine images and draw-call/primitive observations under `captures/forward_plus`.
The independent project defaults to Forward+; Compatibility can be selected
explicitly for a separate comparison. For restricted execution, set process-local
`APPDATA` and `LOCALAPPDATA` to the generated `local_user` directory.

## Verified result

Godot 4.7.2 stable final headless import completed without logged errors/warnings.
Forward+ / Direct3D 12 captured all nine matched views on the RTX 3070 without
logged script/engine errors. Noon current, sample and wind variants were visually
inspected, along with sunset/night views during preparation. The generated logs
are `import_final.log` and `render_final.log`. Earlier Compatibility and import
attempts are not the final validation evidence.

The junipers provide broader, irregular branching; EmacEArt grass gives noticeably
fuller clumps at the same target height. They warrant owner visual comparison.
No production substitution has been made. In this fixture, noon draw calls were
53 current, 106 samples, 69 samples with wind grass before the meadow revision.
Those measurements describe the initial sparse fixture, not the updated meadow.
These observations are not frame-time or target-device acceptance.
World generation, gameplay, the Bible and existing dirty work were not edited.

## Owner follow-up: smooth, expansive and stylized

The owner found the initial presentation grainy and requested expansive grass,
then reaffirmed that everything must stay stylized. View 3 starts selected and
uses a 40 by 44 meter meadow with 0.3 meter jittered spacing, a narrow meandering
trail and irregular shoulders (18,539 batched clumps at the default seed).
One MultiMesh batches the grass; short grass receives tree shadows without
casting individual blade shadows. This remains a bounded art fixture.

Four-sample MSAA, FXAA, mipmapped anisotropic filtering and alpha-to-coverage
soften small leaf/blade edges. Scene-local material copies replace transparent
leaf prepasses with cutouts; opaque stones use weaker normals. Grass removes
normal-map relief and uses matte blades, vertex-level tinting and restrained broad
green color variation. The pack files remain untouched. This preserves the
existing painterly design direction rather than introducing realistic surface
detail. Reference: [Godot material alpha antialiasing](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html).

Meadow size, spacing and height are exported on the review root, alongside wind
strengths, and apply on restart. Runtime bounds limit size to 10–50 meters per
axis, spacing to 0.2–0.8 meters and height to 0.15–0.65 meters. Keep production
streaming, geography and weather ownership separate from these preview controls.

Updated validation: all nine noon/sunset/night captures completed on Godot 4.7.2
Forward+ / Direct3D 12 without logged errors (`meadow_render.log`). The revised
noon and sunset meadow images were visually inspected; dense grass still has
fine blade texture at distance, so complete removal of motion shimmer is not
claimed. The noon meadow used 61 draw calls and about 740,000 visible primitives
in this fixture. These counts are not a frame-time benchmark or device acceptance.
