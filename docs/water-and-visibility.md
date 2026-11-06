# Pixel-art water, banks, and player visibility

October 26, 2026. Continues the selected pixel-art-in-3D direction without changing
terrain generation, water collision, building footprints or the save format.

## Water and shore

`pixel_water.gdshader` uses a restrained blue-green palette, whole-pixel ripple
lines, and a three-step-per-second visual animation. It uses absolute world
coordinates: the scene supplies its camera-relative origin so the pattern does
not restart on each tile/chunk or slide when the world is rebased around the
player. This is cosmetic shader time, not a new simulation clock or Vastra rule.

Water remains recessed to Y=-0.22. The prepared water mask drives narrow bank
faces and pixel rims wherever water meets land. Inside a chunk the renderer uses
its existing prepared cells; at a border it queries the same canonical terrain
sample without constructing a neighboring render chunk. This avoids false seams
and keeps geometry bounded by the existing chunk lifecycle.

Bank bands distinguish the wet lower edge, soil and grassy lip. They do not add
new walkable shallows, change collision or invent water-depth gameplay. Shorelines
still follow the generated tile grid; rounded geometry is not claimed.

## Finding the player behind foreground art

`player_visibility.gd` follows the existing upright character's current atlas,
flip, foot pivot, camera orientation and bob. It adds no second actor state.

A muted gold silhouette is drawn only on character pixels hidden by foreground
depth. Clear pixels, transparent tree gaps and an unobstructed character retain
their original appearance. The helper does not fade the whole forest, move the
camera, change collision or reveal other creatures. It casts no shadow and writes
no depth, so it cannot itself hide the scenery or change picking.

The depth shader reconstructs view distance using the inverse projection matrix,
including the Compatibility renderer's OpenGL depth convention. Implementation
reference: [Godot's depth reconstruction guide](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html).

## Validation

`tests/presentation.gd` checks water/bank batching, no mutation of source terrain,
real chunk-border shoreline agreement (including negative coordinates), the
visibility aid's canonical source and directional flip, and world-origin updates.

Run GPU validation explicitly to exercise the depth buffer:

```powershell
godot --path . --resolution 1280x800 --script tests/presentation.gd
```

The rendered run passed 23 checks. Pixel comparison found zero changed pixels
for the unobstructed character and 1,194 changed pixels behind the opaque test
occluder. The actual sprite-tree material also triggered the silhouette, with no
false tint through its transparent gaps. The aid disappeared after removal of
the occluder. Evidence PNGs are generated under ignored `artifacts/presentation/`.

Headless validation runs 18 contract checks and explicitly skips the five
depth-buffer image comparisons. The full shared validator passed 5,807 headless
checks across both scene journeys, generation/migration, solid geometry, building
collision and presentation. GPU-only checks are not represented as headless passes.

## Current rendered profile

The complete real-time journey/return, negative-coordinate excursion, pause,
new seed and isolated save/load profile completed with zero failures. On Windows,
Godot 4.7.2/OpenGL compatibility, RTX 3070, 1280×800 at a 60 FPS cap, outbound and
return p99 intervals were 16.70/16.69 ms. Live chunks peaked at 49. Scene creation
took 205.79 ms, new-seed rebuilding 119.26 ms and load rebuilding 109.92 ms; warmup
included a 44.44 ms outlier. Engine static memory peaked at about 68.12 MB, which
does not include total process/GPU memory. This is a local paced run, not an
uncapped or portable-device acceptance result. The raw report and captures are
under ignored `artifacts/solid3d/profile/`.

## Remaining exploration acceptance

The building-collision, water/bank and player-readability work packages are now
implemented and tested. Manual full-journey/input acceptance and a target-device
frame/memory budget remain open. The existing profile command can measure the
current view; a paced desktop run does not certify an uncapped or handheld target.
After that gate, D1 introduces territory/individual identity and save contracts,
using SolHunterSource for non-generation mechanics rather than inventing rules.
