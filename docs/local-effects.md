# Supplied effect integration

These supplied effects and tuning instructions describe the inherited expedition and standalone reviews. See the [map-first game](../README.md#play-the-map-first-build).

October 29, 2026: selected art from the owner-supplied Vefects Wind and
Distortion 1.0.3 Godot archives in Downloads. Both included licenses permit
integration into games but prohibit uploading source assets or derivatives to
public repositories. Sources and import sidecars remain under the ignored
`assets/local/vefects/`; no vendor demo scripts, plugins or project settings load.
`tools/install_local_effects.py` installs only the selected scenes' recursive
resource dependencies, preserves licenses/readmes, relocates resource paths and
records archive SHA-256 provenance locally. Run:

```powershell
python tools/install_local_effects.py C:/Users/elija/Downloads
```

The atmosphere controller owns a nearby, bounded leaf emitter from
`VFX_Wind_Debris_Tree_Leaves_01_Colored_Closer`. Its velocity follows the same
cloud-wind direction consumed by foliage and rain, with stronger drift during
rain. Still air suppresses emission. It follows the player in rebased world
coordinates and freezes alongside rain on pause. It adds no weather simulation.
The provisional default is 32 leaves, adjustable to 0–96 in AtmosphereSettings;
zero removes the emitter when settings are applied.

Battle feedback adds `VFX_Distortion_Flat_01` only for positive confirmed damage
events. It remains under the existing feedback cue limit and lifetime, with
local coordinates so rebasing follows the target. Disable through
SolVisualSettings `impact_distortion_enabled`. Existing damage labels and
affinity rings remain visible; distortion conveys impact without introducing
affinity rules, additional damage or persistent state.

Both integrations dynamically check for the optional art. A clone without it
retains the existing presentation and requires no vendor resources to parse.
Use Forward+ for the intended screen-space distortion; transparent scenery
cannot be included in Godot's opaque screen capture.

The pixel FX archive was inventoried but not installed: its numbered sprite
sheets need authored mappings and frame metadata, and its downloaded contents
do not establish redistribution permission. The tiny Fire Zone RAR and action
library are not adopted as dependencies. Existing sky, nature and grass assets
are already connected through their existing owners.

Focused verification: `tests/local_effects.gd` checks installation availability,
particle limits, pause, damage attachment, cleanup and immutable saved state.
Run with `-- --effects-capture` on a rendering device for an actual exploration capture
under `artifacts/local-effects/`. Existing atmosphere and battle-feedback suites
cover the affected presentation owners.

Validation on Godot 4.7.2: optional-art integration passed with installed packs;
atmosphere passed 41 checks and battle feedback passed 22 checks. Import/parse
and script ownership passed (153 scripts). The actual game rendered with
Direct3D 12/Forward+ on the local RTX 3070; this is visual smoke evidence, not a
performance or export acceptance claim. The full validator was not run.
