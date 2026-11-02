# Water appearance and shoreline continuity

October 28, 2026. The owner's close-up exposed pale triangular wedges along pond
edges. The clipped water plane was meeting the actual terrain, but the water-center
cell path rendered bare sand while adjacent land-center cells rendered grass.
That cell-level material distinction remained visible as a false shoreline mask.

Both sides now use the same ground-following bank/grass layer. Pond level is carried
in mesh attributes and the bank blends continuously by height above that level.
Partly wet cells retain their dry bank layer; wholly submerged cells omit the extra
grass layer. Water still clips against the same canonical triangles. No terrain
height, water classification, movement, encounter or save rule changes in this fix.
Generation remains **7**. Restart the game to rebuild cached materials/meshes;
current-generation saves retain their geography and can be loaded normally.

The opaque water shader uses actual triangle depth for shallow/deep color, a narrow
soft foam fringe and irregular ripple normals from a small seamless noise texture.
The 256×256 Godot-generated texture is shared, with four samples per water fragment;
it avoids the obvious crossing sine-wave grid seen in the first visual iteration.
Its geometry stays horizontal;
normal animation does not move targeting or swimming heights. Existing sky/lighting
and weather continue to light the water. This adds no screen-space refraction,
reflection render pass or physical fluid simulation. Existing shader paths remain
stable; the old `pixel_water` filename now hosts the updated 3D treatment.

Open `resources/water_appearance.tres` in Godot. Deep/Shallow Color, Wet/Dry Bank
Color, Bank Blend Height, Depth Color Range, Foam Depth, Ripple Strength and Ripple
Speed and Ripple Noise are connected to the actual grass/water materials. Height/depth controls are
in metres; ripple strength changes normals only and speed is a clock multiplier.
Defaults remain art tuning. Rebuild/restart after edits. Invalid settings use the
validated default appearance; appearance values are separate from expedition saves.

`tests/water_shoreline.gd` covers production bank coverage on both cell categories,
the actual configured materials, unchanged generated samples and interpolated depth
against the canonical ground. It includes positive/negative partial shore chunks.
Float32 pond-level attributes use a measured 0.000001-world-unit comparison;
depth interpolation uses 0.0001. `tests/terrain_geography.gd` retains exact
generation/reconstruction fingerprints and the production border checks.

Reproduce the real-view review with pinned Godot 4.7.2:

```powershell
godot --path . --rendering-driver d3d12 --script tools/review_water.gd
```

It uses normal AI and an isolated in-memory expedition, captures daylight/night/rain
plus a dry-bank close-up, and writes `artifacts/water/final/`. Its paced frame sample
is a single review workload, not a matched GPU-cost comparison or owner/Thor acceptance.
The earlier rendered silhouette failures remain a separate presentation issue.

Final evidence: `artifacts/water-shoreline-final.log` passes 22,605 assertions over
94 partially wet cells; `artifacts/water-geography.log` passes the existing 8,853
generation/reconstruction checks. Rendered terrain integration passes 3,565 checks
in `artifacts/water-integration-rendered.log`. The final irregular-noise treatment
has zero review failures in `artifacts/water/current/`, with daylight, night, rain
and close-up images. Its single 60 FPS-paced sample has p95 intervals of
16.678–16.683 ms, without establishing a shader-only cost regression or a device
budget. Earlier `first`, `refined` and `final` capture folders record visual
iterations; `current` is the final appearance in this change.
