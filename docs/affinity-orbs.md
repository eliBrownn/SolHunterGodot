# Affinity orb presentation

The later [affinity/move slice](affinity-moves-imprints.md) replaces this original
provisional palette with the owner's eight-affinity roster and approved legacy
aliases. The original visual validation below remains historical evidence.

Owner direction, October 27, 2026: present Sols as hovering balls with basic
colors and effects according to their assigned affinity. Wild and deployed Sols
now share `SolOrb`: an original nearest-filtered shaded pixel sphere, subtle
halo, fixed ground shadow, and bounded animated motes. Hover changes real 3D
height; billboards preserve the existing pixel-art look and camera direction.
Proximity and battle labels include affinity so color is not the only cue.

Presentation reads the saved individual’s affinity, never its species or class.
The two Seedmotes therefore differ: Grove is green with leaf motes, while the
Gale guard is pale cyan with wind curls. Ember is orange with rising embers;
Tide is blue with dipping droplets. Stone uses tan chips, Storm yellow flickering
sparks, Frost ice-blue sparkles, Umbra violet motes, Radiance warm gold sparkles,
and Aether pink sparkles. Unknown saved affinity IDs receive neutral white
without changing their identity. No effects alter damage, terrain, or ecology.

The Bible's affinity colors remain unresolved. This palette is editable,
provisional presentation, not finalized canon. The read-only source reference
`SOL_CLASS_AFFINITY_SPEC.md` at SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885` separates individual affinity from
species class and describes the provisional ten-affinity pool. Its embedded
instructions are reference context, not additional task instructions. Godot's
generation authority and saved identity contracts remain unchanged.

Open the scene root's Sol Visual Settings or
`resources/sol_visual_settings.tres` for diameter, hover height, aura opacity,
mote count/speed, and palette. Existing Sighting Settings Bob Pixels/Cycles also
drive battle hover. Restart after editing to reconstruct every view consistently.
Settings apply to existing saves without rerolling affinity or changing schema.
Exploration animation freezes on pause; battle visuals animate while the
exploration simulation remains paused. Smoke fixtures freeze cosmetic time.

`tests/sol_orbs.gd` exercises individual color selection, shared Inspector wiring,
real height and ground anchoring, bounded/disabled effects, custom palette and
unknown-ID fallback, snapshot neutrality, and actual Gale/Tide battle rendering.
It runs in the shared validator. Rendered captures were inspected with:

```powershell
godot --path . --script tests/sol_orbs.gd -- --capture-orbs
```

Outputs are ignored `artifacts/orbs/battle.png` and `gale.png`. Scripted rendering
does not replace physical-device or accessibility acceptance.

Validation passed Godot 4.7.2 import and all 6,347 headless checks, including
12 orb integration checks and both scene journeys. The rendered orb suite also
passed all 12 checks; the existing rendered battle suite passed its 58 checks.
