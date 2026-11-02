# Painterly forest study

Owner direction, October 29, 2026: stylized, painterly fantasy. Use authored
nature models with procedural placement and restrained variation; keep rich biome
palettes, readable silhouettes, warm light, colored shadows and selective magic.

## First slice

Basic lighting promoted October 29: the main game's existing atmosphere controller
now uses Filmic tone mapping, 0.65 sky ambient contribution and the welcoming
lighting palette at 0.715 strength, with 0.55/0.22 day/night ambient and 1.2 base
exposure. Tune `resources/atmosphere_settings.tres` under **Painterly Lighting**;
restart/reapply affects new and loaded expeditions. This transfers light/sky/fog
color treatment and a depth-fog onset multiplier. The custom foliage material and automatic mood transitions
remain separate study work. View distance owns the fixed far horizon; weather and mood scale fog onset,
with clear-day onset at 95% of the horizon by default; the palette's study-only exponential fog density is not transferred.

Fog follow-up, October 29: clear onset moved from 80% to 95% of the fixed
horizon (64.6 of 68 cells at the default view). Cloudy/rain multipliers are
0.85/0.75; neutral/welcoming mood preserves visibility, wondrous/mysterious
scales onset by 0.85/0.65 before mood-strength blending. Inspector controls
apply at restart/reapply, including loaded expeditions. Focused headless checks:
atmosphere 41 and fog horizon 132, zero failures; engine import passed. Rendered
fog capture was inspected, but reported an unrelated existing compile error
in `vastra_currents.gd:226`, so it is not clean rendered validation.

Validation: Godot 4.7.2 import passed; headless atmosphere passed 36 checks;
Forward+ / Direct3D 12 rendered day/sunset/night/rain and passed 40 checks.
Projected camp-ground luminance was 0.91082 day versus 0.28826 night. These are
local visual checks, not target-device acceptance. Captures are under ignored
`artifacts/atmosphere/`. No pixelation or new mechanics were enabled.

Open `scenes/forest_style_preview.tscn` and press F6. This standalone visual
fixture uses the existing CommonTree_1, Bush_Common, grass and rock assets,
with a fixed scatter seed and open clearing. It does not read/write expeditions
or replace the terrain/scenery generator. The leaf shader remains a study;
basic atmosphere settings have now been promoted into the main game.

- B compares imported leaves/linear tone mapping with painterly leaves/Filmic.
- 1/2/3 select noon, sunset and night; both comparison modes use the same sky,
  camera, geometry and sun/moon-direction fixture for each condition.
- Drag with the left mouse button to orbit; wheel to zoom; R resets the camera.
- F freezes wind at a repeatable moment; press again to animate.

`resources/painterly_foliage.tres` owns provisional shader tuning.
The shader adds height-weighted wind measured in world meters, broad per-model
color variation, a subtle lower-to-upper color gradient and light-dependent
backlighting. Imported leaf textures, UV transforms, base colors, optional vertex
colors and alpha-cutout thresholds are retained. Double-sided leaves receive
corrected backface normals. Bark retains its original material. Material overrides
are local to preview instances; imported resources are not modified.

The proposed lighting uses sky ambient fill, Filmic highlight handling and gentle
fog. No screen-space indirect lighting, SDFGI or volumetric fog is required.
The comparison is a direction study rather than a pixel-identical reproduction
of the expedition: its ground, sky and arrangement are deliberately simplified.

## Nearest-neighbor comparison

Pixelation is parked while color/emotion is developed. The saved pixel preview
remains available, off by default; the mood study uses native resolution.

Owner follow-up: compare pixel effects before committing. No commit is authorized
by this comparison itself. Run `scenes/forest_pixel_preview.tscn` with F6. Its
buttons and keys 4â€“9 select the five matched presentations requested initially
plus one deeper 3Ã— comparison:

| Mode | 3D rendering at a 1280Ã—800 window | Sampling |
| --- | --- | --- |
| Smooth | 1280Ã—800, 4Ã— MSAA | Linear textures with mipmaps |
| Very light 1.25x | 1024Ã—640, no MSAA | Smooth textures, nearest enlargement |
| Light 1.5x | 853Ã—533, no MSAA | Smooth textures, nearest enlargement |
| Medium 1.75x | 731Ã—457, no MSAA | Smooth textures, nearest enlargement |
| Pixel 2x | 640Ã—400, no MSAA | Smooth textures, nearest 2Ã— enlargement |
| Deep 3x | 427Ã—267, no MSAA | Smooth textures, nearest enlargement |

The pixel modes deliberately retain smooth texture sampling to isolate the
whole-image pixel treatment. A separate nearest-textures checkbox duplicates the
preview's imported materials and selects the leaf shader's nearest sampler.
Mipmaps remain enabled to limit distant shimmer. Fractional enlargement produces
slightly uneven pixel widths; 2Ã— is the integer-scale comparison. The ground is a flat-color fixture, so this
comparison does not establish a terrain texture treatment. The HUD stays at native
resolution in all modes. Scene controls and wind freeze work in this preview too.

`tools/review_forest_pixels.gd` captures all six modes at noon and sunset into
`artifacts/forest_style/pixels/<renderer>/`. They share geometry, camera, wind
phase and lighting. Static images establish appearance; walking/orbiting tests in
the actual game will be needed to judge shimmer before broad adoption.

Saved on/off controls live on the preview scene root under **Saved Filter
Defaults** in Godot's Inspector. Save the scene after changing pixel enablement,
strength, nearest texture sampling or initial painterly-style enablement. Turning
pixels off retains the chosen preset; enabling them restores it. Defaults use
native resolution, retain the light 1.5Ã— preset, keep nearest textures off and
enable the painterly style. Runtime preview controls are temporary; no player
preferences or expedition data are written. See [Inspector tuning](inspector-tuning.md).

Verified locally with Godot 4.7.2 on October 29: editor import passed, the initial
six condition/style views rendered on Compatibility and Forward+ (Direct3D 12),
and the five-level pixel comparison rendered ten views on Forward+ with
no reported engine/script errors. The first automatic Forward+ launch could not
initialize Vulkan and fell back to Direct3D 12; the final run selected Direct3D
12 explicitly. The static fixture was approximately display-limited at 6.94 ms
per frame on the RTX 3070; this is not an isolated shader-cost measurement.
The subsequent saved-settings review rendered twelve views including 3Ã— and
verified that off/on restores native/selected resolution without losing strength.

## Review and next gate

### Situation-driven color

#### Lighting rules for the test

1. **Time owns the base light.** The main world's saved exploration clock drives
   sun/moon direction, daylight and night brightness. Pause freezes that clock;
   the live field menu does not pause it. The study's 1/2/3 keys are explicit
   visual fixtures, never changes to expedition time.
2. **Weather modifies that base.** Existing clear/cloudy/rain states own cloud
   cover, reduced direct light, sky/horizon color and rain fog. Mood does not
   select weather or cause rain; ordinary weather does not create Vastra overload.
3. **Biome owns surface identity.** Authored scenery/terrain palettes retain
   their habitat identity. Mood is a bounded overlay, not a biome reroll.
4. **Situations request mood explicitly.** Neutral is the reset. Welcoming uses
   warm light and richer greens; wondrous uses blue-green foliage and cooler fill;
   mysterious reduces saturation and direct light with blue-violet accents.
   These communicate atmosphere, not an automatic safe/danger classification.
   Until existing situation owners are connected, Z/X/C/V are manual test inputs.
5. **One blend owns the result.** Apply mood once over the current base, with a
   2.5-second default transition. Interrupted transitions continue from the visible
   result. Invalid palette requests are ignored. Off/zero strength restores base.
6. **Night remains night.** In the study, mood cannot raise direct-light energy,
   ambient energy or exposure above that night's base. Leaves use backlighting,
   not emission; a mood adds no glow. The cap applies to moods, not future authored
   lamps or light-producing abilities, which need their own explicit owners.
7. **Color carries no hidden mechanics.** This slice changes no detection,
   stealth, encounters, combat stats, affinity identity or ecological simulation.
   Warm light is not proof of safety; blue light is not proof of danger. Gameplay
   information must still come from its existing cues and authoritative state.
8. **Pixelation stays off.** Color tests use native resolution and retain the
   existing affinity colors and readable UI. Actual-creature readability remains
   a main-world validation gate, not something this empty clearing proves.

Owner's pre-test adjustment: the mood/color strength is saved at **0.715**,
10% above the preferred 0.65 (`0.65 Ã— 1.10`), with palettes unchanged. This raises
the palette blend rather than globally increasing saturation or brightness.
Inspector strength remains adjustable; no commit has been made.

Mechanics reference inspected read-only: local `SolHunterSource` branch
`development/world-redesign-0.2`, HEAD `d6f0902d77ed46a2f7d251c354792a4cc9210bc4`.
`src/systems/world/day_cycle.py` defines cosmetic saved-time daylight;
`weather.py` derives read-only ordinary weather; `storms.py` distinguishes it
from overload admission. `tests/test_world_session_systems.py` covers clock
persistence, read-only daylight and bounded night rendering. This supports
presentation/simulation separation; it does not import the earlier generator,
phase timings or menu semantics over the Godot owner's explicit decisions.
Local source files were inspected; Git status/history access in that sibling
checkout was unavailable, so these are working-copy observations at its recorded
HEAD rather than a claim that the files were clean. No source files were copied.

`resources/moods/` contains provisional neutral, welcoming, wondrous and
mysterious palettes, owned by `scripts/presentation/world_mood_palette.gd`.
The forest study's **Situation and mood** exports select enablement, initial key,
strength (0â€“1) and transition duration (0â€“10 seconds). Save scene/resource edits
and restart to apply. Z/X/C/V request those four moods during preview.

The presentation API `set_mood(key, seconds)` requests a palette; unknown or invalid
palettes are rejected. Colors interpolate in linear light with a smooth time
curve. A new request blends from the currently displayed values, so interrupted
transitions remain continuous. Neutral/disabled/zero-strength states restore the
base treatment. Changing noon/night during a blend recomposes from that condition's
base light, avoiding accumulated multiplication and preserving night brightness.

The leaf shader exposes mood tint, lower/upper tint and saturation independently
of wind and texture sampling. Sun, ambient fill, fog and exposure follow the same
blend. The material changes apply only to scenery leaves; no species or affinity
palette is rewritten, and no glow/emission is added. The presets express art
direction rather than universal emotional meanings.

Existing gameplay owners should eventually request presentation moods for
situations; this study invents no danger/quest/weather rules or automatic mood
selection. The main expedition is not wired to the study API yet. A single target
request currently wins; future situation priority belongs to the consuming owner.

`tools/review_forest_moods.gd` passed its transition, halfway, interruption,
completion, unknown-key and disable checks, and rendered eight mood/day-night
views on Godot 4.7.2 Forward+ / Direct3D 12. Images are in
`artifacts/forest_style/moods/`; no pixel filter was used.

`tools/review_forest_style.gd` renders six matched condition/style views and writes
renderer-specific frame statistics under ignored `artifacts/forest_style/`.
Frame samples cover the small static fixture, with wind frozen for comparison;
they do not certify streaming performance, animated-wind performance or AYN Thor.

Review canopy color, shadow readability, leaf cutouts and night brightness before
integrating a material adapter into streamed scenery. That integration must retain
shared materials/MultiMesh batching, terrain picking and existing biome tints;
wind needs consistent root anchors across compacted meshes and floating-origin
rebasing. The prototype adapter currently targets the supplied `Leaves_` material
names on one tree and one shrub. It is not a universal material converter.
