# Natural terrain in the live game

Implemented October 27, 2026 after the owner requested continuation from the
[terrain study](terrain-preview.md). The default F5 scene now uses Rolling
elevation. This is the initial live slice of the [terrain roadmap](terrain-roadmap.md),
not completion of its regional geography or release milestones.

## Behavior and controls

Ground is a continuous triangulated surface with broad low hills and restrained
detail. Original grass and trail textures follow the surface. Imported trees,
rocks, small vegetation, authored props, trainer, roaming/deployed Sols, shadows,
selection markers, battle tiles and affinity overlays use the shared height data.
The camera follows ground elevation; frustum and fog planning include vertical
terrain bounds. Terrain picking intersects the same triangles, including negative
coordinates and level pond surfaces, rather than projecting onto Y=0.

Refuge, cabin and waystone foundations blend into the surrounding landscape.
Existing routes follow its gentle contours. New-expedition admission checks the
essential journey for 3x3 traversal; unsafe experimental settings retry default
Rolling once, then retain the current expedition if the route is still blocked.
Every standing cell checks both terrain triangle slopes. Existing footprint and
diagonal-corner rules then cover the swept travel corridor. Battle cell admission
uses those same standing rules; existing special movement mechanics are retained.
No height damage bonus, movement-cost change, climbing or fall-damage rule is added.

Generation 7 replaces the repeated road lattice with seeded district hubs,
winding dry links, asymmetric junctions and optional spurs. Refuge and waystone
anchors remain fixed. Candidate paths are scored against raw relief and omitted
when they cannot clear the independently selected ponds. The required approach
retains its separately checked dry 3x3 travel corridor.

Ponds vary in count, radii, rotation and lobed shoreline. Each has a deterministic
horizontal water level, recessed bed and rising bank. Water geometry clips that
plane against the final ground triangles, including partial shoreline cells;
picking uses the same plane/triangle intersection. Ground/water cell admission
samples the cell center; partial shore cells retain dry and wet portions visually.
Water cells still exclude ordinary walking. Full river drainage remains later work.
See [route and pond diversity](route-pond-diversity.md) for bounds and current evidence.

Select the world root's **Expedition Tuning -> Terrain Settings**, or edit
`resources/terrain_rolling.tres`. Scales/amplitudes, warp and walkable slope are
connected controls. Restart/new expedition applies edits; loaded expeditions keep
their saved values. The preview scene shares these Resources, so editing its
Rolling preset also changes defaults for later live expeditions. Movement speed,
ecology and individual affinity remain separate authorities.

## Save framework

Generation version is 7; outer save format is 3. Saves contain validated relief
parameters alongside seed, climate, player progress and persistent world state.
The generator snapshots settings before use. Reload reconstructs the same
surface even after Inspector defaults change. Old outer formats/generations are
rejected with a new-expedition message, leaving the running expedition intact.
No legacy terrain generator or conversion chain is maintained during solo testing.
Current writes retain temporary-file replacement and the previous-save backup.

## Verification and limits

The terrain integration suite checks actual curved mesh vertices, vertical and
oblique ray hits, negative/large coordinates, level ponds and closed bank edges,
world-space scenery targets, trainer grounding, live camera picking, current
save/settings reconstruction and incompatible-load rejection. The generation
suite covers essential travel, broader route junctions and 3x3 footprints over
ten seeds. The shared validator includes both terrain suites and both existing
scene journeys. The recorded log under ignored
`artifacts/terrain_study/final_integration_validation.log` is the October 27
terrain integration run, not certification of the current changing checkout.
That then-current shared validation passed: 298 heightfield checks, 1,823 terrain integration
checks, the ten-seed generation suite and both expedition journeys, alongside
the existing gameplay/presentation suites. A sighting presentation assertion was
updated to compare its saved reaction caption after concurrent behavior work;
no Sol reaction rules were changed by terrain integration.

Audit update, October 28: the validator subsequently gained ecology coverage not
present in that historical log. The current source must be revalidated for its
own revision/dirty-tree fingerprint before a new full-suite claim. The existing
profile also lacks a complete active-settings/source manifest. T5 preparation in
the roadmap schedules that instrumentation and a current Forward+ baseline;
historical timing below is not a gate for expanded biome art.

Rendered refuge, trail, pond, waystone and battle captures are reproducible with:

```powershell
godot --path . --script tools/capture_elevated_terrain.gd
```

They are written to ignored `artifacts/elevated_terrain/`. A compatibility-renderer
capture also ran. Forward+ captures were verified through Direct3D 12; this host's
Vulkan startup lacked a required surface extension, so use `--rendering-driver d3d12`
for a direct repeat without the automatic fallback. Rendering checks use an
isolated in-memory expedition and do not overwrite the player's expedition.
Owner manual acceptance is still required.

The real-time expedition profile completed with zero failures on Godot 4.7.2,
OpenGL compatibility / RTX 3070, actual viewport 2560x1369 and a 60 FPS cap:

| Measurement | Earlier flat baseline | Elevated, one chunk/frame |
| --- | ---: | ---: |
| Outbound frame p95 / p99 | 16.68 / 16.70 ms | 16.68 / 17.69 ms |
| Return frame p95 / p99 | 16.68 / 16.74 ms | 16.68 / 16.70 ms |
| Outbound / return worst frame | 39.29 / 25.80 ms | 26.02 / 32.85 ms |
| Initial scene construction | 1165.57 ms | 1541.07 ms |
| New expedition / load | 201.41 / 221.02 ms | 635.32 / 628.42 ms |
| Peak resident chunks | 59 | 71 |
| Engine static memory peak | 100.61 MB | 107.51 MB |

These are individual runs with pacing time, not portable performance guarantees
or total process/graphics-memory measurements. The earlier two-chunk/frame
elevated run had outbound/return p99 of 28.32/26.52 ms; that observation motivated
the lower default budget and bounded normal cache. Recorded reports are
`artifacts/terrain_study/flat_profile.json`, `elevated_profile_before_budget.json`
and `elevated_profile.json`. The timing run preceded the final essential-route
admission guard; its synchronous new-expedition cost therefore needs another
measurement when startup tuning is revisited. Steady travel geometry is unchanged.

Height/normal caches are bounded at 65,536 entries each, slope at 32,768 and pond
descriptors at 256. Cache clearing never changes generated values. Long-duration
cache-turnover timing, repeated cold starts, default-renderer performance budgets,
portable hardware and exported-build acceptance remain open. No export preset is
currently configured. Dedicated road grading, smoother shoreline transitions,
broader biome clustering and T6 rivers/erosion remain follow-up work.
