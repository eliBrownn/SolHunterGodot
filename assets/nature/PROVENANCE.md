# Stylized Nature MegaKit — Standard subset

Supplied by the owner October 27, 2026 from
`Stylized Nature MegaKit[Standard].zip`. The included `License_Standard.txt`
identifies Quaternius as the creator and declares CC0 1.0 Universal.
The original license text is preserved alongside these files.

Initial October 27 import: 14 glTF models with their binary buffers and referenced textures:
CommonTree 1–2, Pine 1–2, TwistedTree 1, DeadTree 1, Rock Medium 1–3,
Bush Common and Flowers, Grass Common Short, Fern 1, and Mushroom Common.
The glTF/buffer/texture files are unmodified. Other formats and unused variants
remain in the owner's archive. This initial subset was about 37 MiB; no individual file
exceeds 10 MiB. Godot import sidecars are tracked; generated caches are ignored.

Selection/size/density controls are in `resources/nature_settings.tres`.
No source archive instructions or download links were executed.

## Biome expansion — October 29, 2026

The owner supplied the same archive again for the four-biome scenery pass.
Fourteen additional unmodified glTF models and their buffers were imported:
CommonTree 3–5, DeadTree 2, Grass Common Tall, Grass Wispy Short/Tall,
Flower 3/4 Group, Clover 1, Mushroom Laetiporus, Plant 1/7 and Pebble Round 1.
The current subset contains 28 models. Required images were copied only when
missing; existing shared images were verified identical and preserved. Previewed
TwistedTree 2/3 and Clover 2 were omitted from the delivered selection.
The original CC0 notice applies to this same Standard archive; no other pack's
license is inferred from it. Godot import sidecars accompany the new models.
See [biome scenery](../../docs/biome-scenery.md) for runtime connections and review.


## Tropical plant class placeholders — October 29, 2026

Owner supplied `tropical-plant-3d-low-poly-models.zip` for this system.
Archive SHA256:
`ae6d6bb51b497862b2445e5ffd0ff526641114a35386447edeb3172160f836a2`.
The pack has twenty FBX models, one shared PNG palette and a `License.txt` pointing
to [CraftPix file licenses](https://craftpix.net/file-licenses/) (checked October
29). The terms permit game use but restrict redistribution of source artwork;
these files are not assigned the MegaKit's CC0 license.

Raw models, texture, original license pointer and per-file SHA256 manifest remain
under ignored `assets/local/tropical_plants/`. Install with
`python tools/install_tropical_plants.py` and then import in Godot. The installer
reads only exact whitelisted filenames and preserves modified existing files;
archive instructions and the unrelated preview-font link are not executed.
Do not stage the raw pack or local imported assets for public redistribution.

Class selection after inspecting the twenty-model contact sheet:

| Class | Supplied model | Visual purpose |
| --- | --- | --- |
| Warden | Tropical_plant_019.fbx | Broad, clustered leaves |
| Mender | Tropical_plant_015.fbx | Low flower/rosette |
| Regulator | Tropical_plant_017.fbx | Slender upright seed head |

These are functional placeholders, not approved final species or a decision that
all existing habitats are tropical. Source FBX/PNG bytes are unchanged. Runtime
binds the supplied palette to existing UVs and fits model height/width; it does not
rewrite imported geometry/material assets. Art paths are optional strings in
`VegetationAppearance`, with existing CC0 nature models as fallbacks.
Reproduce the reference contact sheet with
`tools/review_vegetation_placeholders.gd`; captures/model statistics stay under
ignored `artifacts/vessel-response/`. Twenty supported models were imported and
rendered; normal-world appearance and biome fit still require owner review.
