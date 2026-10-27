# Exploration foundation — October 26, 2026

The current F5 entry is an experimental [solid 3D view](solid-3d-prototype.md)
using the same simulation. The earlier sprite-ground presentation remains in
`scenes/world.tscn` for F6 comparison. The description below documents that shared
foundation and its earlier presentation; solid-mode limitations are listed in
the prototype note.

Implemented in a fresh Godot project:

- A 2D world rendered as a texture onto a horizontal 3D plane, with a separate
  screen-space HUD, orthographic zoom, and an upright billboard explorer.
  The camera looks down at 35 degrees with zero azimuth: lower toward the plane,
  with the world axes aligned rather than rotated sideways.
  Its 64-by-48-unit XZ surface uses a 2048-by-1536 texture, preserving 32 pixels
  per world unit. Elevation and azimuth are exposed on the scene root in Godot.
- Metadata-based asset slicing, anchored/y-sorted props, and directional player art.
- Seeded, independently salted terrain and decoration using absolute coordinates;
  new worlds use generation version 5 and save format version 2. Generation 1–4
  saves migrate on load, retaining seed and journey progress; a blocked position
  is relocated to nearby dry ground. Migration does not rewrite the save on load.
- A reserved refuge, eastern landmark, five-cell-wide winding main trail and a
  seven-cell-wide network of connected wilderness routes. Routes are defined from
  absolute coordinates and seeded route offsets, with obstacle-free approaches
  and shared footprint traversal rules. Water is generated independently in
  bounded basins inside each area; routes use dry margins around those basins.
  This deliberately constrained layout guarantees dry corridors and is provisional
  geography, not general-purpose pathfinding around arbitrary bodies of water.
- Continuous interpolated eight-way movement, diagonal corner checks, inspection,
  pause, session notes, and an outbound/return objective.
- Seeded Perlin moisture shapes dry heath, temperate ground and wet marsh.
  Frequency and dry/wet thresholds are configured in `resources/climate_settings.tres`
  for new expeditions and stored in each save. Moisture is independent of both
  the water-basin layout and the Vastra concentration noise.
- At most 49 live chunks; generation/publication of one pending chunk per frame,
  eviction of visual nodes and their data together, and deterministic reconstruction.
- Validated save loading, temporary-file replacement, and previous-save backup.

The world bible remains the design authority. Vastra concentration and overload
are separate measurements. Overload is initially zero, and no ecological behavior
is inferred from a concentration reading. Chunk boundaries have no ecological
meaning. The [D1 persistent foundation](d1-persistent-foundation.md) now supplies stable
individual identities and bounded records independently of rendering. There are
no live creatures or collection gameplay yet.

## Validation so far

Godot 4.7.2, Windows, OpenGL compatibility renderer, RTX 3070.

Generation 4 validation includes Perlin moisture and configurable thresholds,
saved climate reconstruction, 3×3 travel along horizontal and vertical routes,
junctions, natural water collision, dry route reservations, reverse-order chunk
reconstruction and migration of older saves. The integration smoke test exercises
actual outbound and return movement, streaming and saving. F3 reports frame
p95/p99/max for the current session, including startup and rebuild frames.
The D0 rendered benchmark now records separate startup/rebuild and travel phases;
see [D0 evidence](d0-exploration.md). Target hardware budgets and manual
continuous-travel acceptance remain outstanding.

## Current limits

- The explorer is an upright camera-facing billboard with a flat ground shadow.
  Environment props remain flat; there is no elevation traversal, general 3D
  collision, or dynamic 3D lighting.
- Noise classifies habitats; grass tint blends smoothly, but terrain boundaries
  and temporary water are still square cells. Water bodies are constrained to
  bounded basins; there is no drainage model or arbitrary water-aware route planner.
- The route network and places are the intended connected backbone; off-route
  wilderness pockets can be isolated. Tests of large footprints are groundwork
  for future Sols. The regular provisional network needs design and playtesting
  before it is treated as final world geography.
- The cabin now has a shared blocking footprint with a clear approach; other
  camp/landmark props remain decorative. See [building collision](building-collision.md).
- Player movement uses bobbing directional stills, not a completed walk cycle.
- First view and explicit load/new-seed build the visible area plus canopy margin
  synchronously; remaining chunks stream one per frame on the main thread.
  Work is not threaded and the live render budget remains 49 chunks.
- Inspection samples a cell without populating the chunk cache. Frame statistics
  include initialization; the separate D0 harness isolates travel statistics but
  no target-device performance acceptance threshold has been adopted.
- Session messages are temporary; [recorded Sol observations](sol-observation-journal.md) are saved. No fog-of-war, map, NPCs, encounter,
  creature collection, combat, ecological simulation, or Python save import.

Next player acceptance: walk the journey manually and judge the upright character,
3D plane angle, pixel readability, and terrain scale before expanding content.
