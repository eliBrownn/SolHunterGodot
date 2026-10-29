# Shared building footprint and safe migration

October 26, 2026. The refuge cabin now blocks movement instead of being decorative.

## One footprint authority

`authored_structures.gd` selects a deterministic 3×3 cabin footprint near the refuge.
The previous fixed model overlapped the westbound trail, so it cannot simply be
made blocking in place. A bounded site search reserves dry land and a one-tile
clear approach, avoiding protected route buffers and spawn. If no valid site is
available, the building is omitted rather than blocking an essential route.

`WorldTerrain.cabin_footprint` owns this placement. Sampling, walking, diagonal
corner checks, large footprints, chunk data and save validation all use the same
obstacle result. The 3D foundation center and XZ bounds derive directly from the
rectangle; the roof can overhang it. The original reference view draws the same
occupied area so there is no invisible building blocker in that scene. Examine
identifies an occupied tile as `Building · blocked`.

Only the cabin is made blocking here. Benches, crates, lanterns and other small
authored props remain decorative pending their own authored footprints. The door
is a visual placeholder: no interior or interaction/entry rules are introduced.
Movement remains logical tile/footprint traversal, not a competing physics system.

## Generation and saves

The world generation version advances from 4 to 5 because traversal has changed.
Noise, water and route calculations remain intact; the cabin reservation and
cleared approach are the new generated content.

Versions 1–4 migrate forward using the existing deterministic legal-position
search. A former player position inside the new footprint moves to nearby legal
ground. Seed, journey flags and valid recorded climate settings are preserved.
Version 4's climate fields remain mandatory and validated; migration must not
silently reset custom settings. Earlier formats without climate use defaults.

Loading never writes the source save. The first successful save after migration
backs up the original before replacement. Current-version saves that put the
player inside the cabin are rejected before writing.

## Reference and evidence

The SolHunterSource movement-controller reference at commit
`115f3e87acc1716c7113523567c01e1666681885`,
`docs/coordination/player-movement-controller.md`, retains logical collision and
saved tiles while separating visual interpolation. Its world-building standards
also call for shared structure footprints, clear approaches and protected access.
These contracts informed the boundary; the Godot generator and site-search code
remain this project's own implementation.

`tests/building_collision.gd` covers ten seeds, reservation/approach checks, wall
entry from all sides, diagonal corner clipping, 3×3 actor overlap, negative chunk
coordinates, valid detours, real movement stopping before the wall, recovery into
a legal direction, and version-4 migration from an occupied site with custom
climate. It verifies original-file preservation, backup creation and malformed
climate/current blocked-save rejection. Rendered runs additionally read back the
foundation transform to check exact footprint/model agreement.

The shared validator runs these checks alongside both scene journeys, generation
connectivity/migration, and solid geometry. GPU foundation checks are explicitly
skipped by the headless dummy renderer and must also run with rendering enabled:

```powershell
godot --path . --script tests/building_collision.gd
```

Final local validation passed 5,789 headless checks: both scene journeys (2,389
each), generation/migration (212), solid geometry (17), and building collision
(782). A rendered building run passed all 784 checks, including the two foundation
readbacks omitted by the headless renderer. No player save was used or overwritten.
