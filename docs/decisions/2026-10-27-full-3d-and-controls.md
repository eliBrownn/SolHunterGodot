# Full 3D presentation and mouse controls

Date: October 27, 2026. Status: explicit owner direction.

The owner selected full 3D presentation and supplied a hooded rogue, compatible
animation rigs, and the Stylized Nature MegaKit Standard archive. This supersedes
the sprite-character/foliage portion of the October 26 visual decision. Preserve
the old terrain textures on 3D tiles. The flat comparison scene remains a terrain
reference; the default scene renders imported scenery, a skinned animated player,
volumetric affinity spheres, and geometric authored props.

WASD controls exploration movement relative to the current camera heading. A
north indicator preserves directional context. Combat Sol deployment, movement and targeting
use left clicks. Move buttons/1–4/Space arm an action; a target click executes it.
Walking snaps the camera-relative input to the nearest existing eight-direction
grid heading; this presentation/input migration does not replace locomotion with
continuous physics or change traversal legality.
Right-click opens Choose Option for the pointed world subject, with Engage and Observe for wild Sols. Nearby wild observations
retain existing range, settled-player and first-seen journal rules; combat and
distant inspection are read-only. Escape cancels aiming before retreat.

Middle-drag orbits/tilts, wheel zooms, and Home restores authored angles and zoom.
Angles remain editable in Godot. Runtime camera adjustments are not saved. The
default game view uses perspective and configurable dolly limits. Camera yaw,
tilt, zoom, FOV and viewport resize feed a conservative frustum streamer that
accounts for tall imported assets. Keep near camera/player neighborhoods ready,
prefetch a margin, and build a bounded number of queued chunks per frame. Small
decoration and shadows have separate draw distances. A matching fog horizon
covers the far clip at a steady distance. Temporary low-detail ground covers
queued chunks during rapid turns until detailed terrain/scenery replaces it.

The supplied SourceCode archive contains a procedural sky shader and seven
noise-texture cloud presets. The owner's subsequent lighting request adds a
[saved-clock day/night and basic weather presentation](../atmosphere.md), with
editable colors, sun/moon light, clouds, rain and wind. The solid view
uses a minimum-size hidden simulation viewport and avoids duplicate 2D scenery.
HUD panels retain their viewport-relative edges when aspect ratio changes.

Read-only mechanics evidence: local SolHunterSource commit
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`,
`src/systems/tactics/live_encounter.py` (`arm_move`, `select_tile`),
`commands.py`, `tests/test_combat_pointer_consistency.py`, and
`docs/coordination/combat-architecture.md`. Source already separates arming from
target clicks and centralizes command execution. Owner direction supersedes its
keyboard movement fallback. The Godot tactical domain keeps turn/budget/effect
authority; this change adds no combat rules.

Imported scenery is selected deterministically from existing biome/obstacle data.
Undergrowth is nonblocking decoration. Terrain generation, collision, identities
and save schemas retain their existing authorities. Asset provenance is recorded
beside each imported pack; no publishing or redistribution of the rogue is implied.

Validation: Godot 4.7.2 import and the full shared validator pass, including
both scene journeys. Mouse and full-3D checks cover actual input routing,
bone-pose deformation, pause/idle/movement state, model normalization and palette
selection. The view suite checks orbit/tilt coverage, actual camera-relative
WASD, connected clipping/sky/fog/asset distances, budgeted queues, eviction and
invalid policy fallback. GPU presentation and view captures are verified on
OpenGL/RTX 3070 under ignored `artifacts/`. Static scenery picking uses triangles
and alpha-tested texture gaps; character picking uses visual bounds. No export,
performance-budget certification or physical-device acceptance is claimed.

## Right-click world interaction, October 27 follow-up

Owner direction: right-click represents the player's hands in the world and is
the primary way to discover available world interactions. RuneScape's
[Choose Option](https://runescape.wiki/w/Choose_Option) and
[OSRS controls](https://oldschool.runescape.wiki/w/Game_controls) informed the
pattern: named target actions, specific interactions before observation, and a
Cancel entry. This adopts the interaction pattern with SolHunter styling.

Right-click a wild Sol to see Engage and Observe. Engage uses the existing
face-to-face preview, where the player can deploy their companion, observe or
withdraw. Observe inspects that specific Sol and records it when in range.
Shared-cell Sols receive separate named actions. Selection retains individual
identity and resolves its current location at activation, never the nearest Sol.
Engage displays a reason when disabled, then checks range, availability and
player state again when selected. Opening/canceling the menu changes no gameplay.
A world replacement, rebuild or battle transition invalidates old actions.

Scenery and terrain currently offer Observe. The trainer offers Your Sols,
Field Guide and existing refuge recovery while at camp. These call implemented
systems; harvesting, doors, NPC trade and click-to-walk are not added by this slice.
During combat, right-click observation preserves the armed move and cannot start
another encounter. Escape dismisses an open context menu before other Escape
actions; outside-click dismissal uses Godot's popup behavior.

The popup follows the cursor, clamps to the main HUD viewport and uses the
validated Menu Settings font size, background, surface, accent and text colors.
These appearance edits apply at restart, independently of expedition saves.
Encounter interaction distance and sighting observation distance retain their
existing Inspector settings. WASD/Shift and battle left-click controls remain.

Mechanics continuity reference: read-only SolHunterSource revision
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`,
`src/systems/ai/encounters.py`, `tests/test_deliberate_encounters.py`, and the
previously inspected `docs/coordination/encounter-persistence.md`. Their stable
identity, deliberate-contact and warning/aftermath contracts remain unchanged;
Godot's generated terrain remains authoritative.

Validation: full `tools/validate.ps1` passed. After correcting visible-viewport
placement, `tests/world_interactions.gd` passed 15 checks in a rendered Direct3D 12
run; its capture is `artifacts/interactions/sol-menu.png` (ignored output).

## Fog stability and distance — October 28 follow-up

Owner report: fog glitches when changing camera angle and sits too close. The
previous queue-dependent horizon reproduced an opaque boundary as close as four
cells from the camera during low-angle zoom/orbit. Fog now stays four cells inside
the configured far clip regardless of loading. Clear-weather Fog Start Fraction
defaults to 0.8 instead of 0.65: at the default 72-cell view, onset moves from
44.2 to 54.4 cells, with the opaque boundary fixed at 68. Rain keeps its existing
earlier-onset multiplier; the saved clock still owns lighting and weather.

Visible queued chunks receive temporary textured ground sampled from the active
Godot generator, with skirts over coarse mesh seams. It has no collision, scenery,
or saved state. Detailed chunk publication keeps its existing per-frame budget;
publication, view eviction and world replacement retire temporary geometry.
View Settings → Stream Ground Step defaults to four cells (choices 1/2/4/8).
Restart or reapply view settings to change sampling; coarser values reduce turn
work. This changes presentation, not generated terrain or traversal.

Godot 4.7.2 import passed. Focused headless checks passed: fog 130, view 664,
atmosphere 33, mouse controls 36, full 3D 44 and terrain integration 1,823
(2,730 total). The fog suite also passed 130 checks rendered with Forward+/D3D12;
orbit/low-angle/wide-zoom/top-down captures were reviewed. The reproduction had
nine failures before the fix. Save/load suites were rerun with their required
temporary user-data write access. Source manifests show only an unrelated Sol
behavior test changed during the final verification window.

In the rendered focused run, temporary ground preparation peaked at 10.83 ms;
the 36-step camera/stream CPU update peaked at 22.90 ms. These are narrow desktop
diagnostics, not frame-time/device acceptance or a whole-project performance
baseline. Logs, source manifests and an isolated change patch are under ignored
`artifacts/fog-horizon/`. The broader 3D/view baseline remains uncommitted in the
shared checkout; this follow-up preserves the other chats' changes and does not
claim a clean full-validator run or Thor/export acceptance.
