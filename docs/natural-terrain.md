# Natural terrain in the live game

This guide describes the inherited expedition generator. Open `scenes/world_3d.tscn` with F6 to review its relief settings, routes, and ponds. See the [map-first game](../README.md#play-the-map-first-build).

Implemented October 27, 2026 after the owner requested continuation from the
[terrain study](terrain-preview.md). The expedition fixture uses Exploration
relief (`resources/terrain_exploration.tres`), including district landforms and
flow-informed ponds. Rolling remains the conservative fallback/comparison preset.
This is the initial live slice of the [terrain roadmap](terrain-roadmap.md),
not completion of its regional geography or release milestones.

## Behavior and controls

### Continuous player movement — October 30, 2026

Exploration movement now follows the exact input direction at continuous positions,
including inside each tile. Release stops immediately and turning/reversing does
not wait for a tile centre. Short swept increments prevent tunnelling; blocked
diagonals retain their legal component along the obstacle. Cliffs, water, solid
obstacles and live barriers retain the existing terrain/condition admission rules.
The occupied tile is the floor of the player position in terrain cells. Each
crossing emits the existing arrival/step signals for encounters and discovery.
Running, condition speed modifiers, pause and combat guards remain connected.
Saves continue to store the occupied tile and restore at its centre.

Source consulted read-only: local SolHunterSource at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`, `src/core/game.py::_move_player`
and `docs/coordination/warning-movement-continuity.md`. These preserve successful
tile-step notifications and held-input continuity under warnings. Continuous
sub-tile steering follows the owner's newer explicit direction; Godot terrain
remains the collision/generation authority.

Focused checks: player traversal 32 headless / 35 rendered and running 10,
zero failures; pinned-engine editor import passed. Existing Canvas/ObjectDB
exit warnings remain. The broader smoke check did not pass: it reports an
outdated rogue-body assertion and save-access failures in the restricted run;
its downstream climate assertions cannot complete after the save failure.

### Connected water and mountain ranges — October 30, 2026

Generation 13 adds optional pond-fed channels to the Exploration preset. A region
can admit one channel ending in a smaller pool. Twenty-four bounded candidate
directions are checked against raw relief, sibling ponds, region margins and the
protected refuge/waystone approach, including shorter alternatives. A shared
level is fitted below the sampled corridor with bounded lowering/excavation;
connections needing raised water ribbons or deep cuts are omitted. Pond,
channel and terminal pool share one descriptor and horizontal water level. The
existing bed, clipped shoreline, picking and ordinary-walking exclusion consume
that footprint. Narrow banks blend into the pond bank instead of inheriting its
full vertical rise. These are slow level connections, not downhill rivers or an
inter-region watershed. Optional routes are admitted around water; no bridges or
new underwater plants are generated.

Mountain ranges use larger seeded geographic parents with overlapping finite
ridgelines, varied crests and lower saddles. Neighbor parents are sampled on both
sides of boundaries; render chunks never own ranges. A broad lowland band
protects the essential east/west approach. Render height bounds and temporary
ground skirts include added elevation. Authored mountain passes remain open.

Saved `TerrainReliefSettings` controls are `stream_length` (0 disables),
`stream_width` (half-width), `mountain_height` (0 disables) and `mountain_spacing`
(parent cells). Exploration defaults are 28, 1.7, 18 and 384 respectively. New
expeditions capture these controls; loaded expeditions retain theirs. Generation
12 and older development saves require a new expedition through the existing
version guard. Heightfield snapshots now use contract 4.

Grass is cosmetic: the live biome resource/shared defaults use height 0.3 instead
of 0.5 and blade width 0.03825 instead of 0.045. Restart/rebuild applies the
40%/15% reductions to existing worlds without changing plant reserves.

Focused Godot 4.7.2 checks passed: exploration geography 12,633; heightfield 298;
terrain integration/save-load 3,945; world generation 147 across 11 seeds;
shoreline geometry/depth 27,053 including connected-channel chunks; grass preview
zero failures. Existing Canvas/ObjectDB exit warnings remain in integration.
Import/class registration completed with the previously observed Windows
safe-save error; no error-free import or full-validator pass is claimed.

`tools/review_generation_layout.gd` writes three-seed maps and reports under
`artifacts/world_generation_next/survey/`. It found 5, 6 and 7 channels across
nine sampled regions for seeds 2601026, 7 and 19. The production render fixture
`tools/review_water_mountains.gd` repositions the player/camera and reports queued
detail publication. These are fixtures, not normal-input travel, owner acceptance
or performance qualification. Earlier rendering attempts and save checks hit
user-data access errors; subsequent checks redirect process-local `APPDATA` to
`artifacts/world_generation_next/userdata`, preserving the player's normal data.
Final corrected-channel D3D12 review completed without engine/script errors;
existing Canvas/ObjectDB shutdown warnings remain. It still had 69/47 detailed
chunks queued at the two water captures (15/23 published), so distant-detail
publication and normal-input play review remain open. The separate mountain
fixture was rendered and inspected before the water-only bank correction; its
range heightfield and renderer bounds were unchanged by that correction.

### Existing terrain contracts

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

October 30 correction: pond-bank influence now fades back to unmodified relief
before its outer cutoff. Previously, raised banks could end in a sudden cliff
where the surrounding land was lower. Generation 12 captures this change;
generation-11 development saves require a new expedition rather than silently
reconstructing different terrain. Terrain detail also advances before temporary
coverage, and shared material samples are cached without changing their output.

Select the world root's **Expedition Tuning -> Terrain Settings**, or edit
`resources/terrain_exploration.tres`. Scales/amplitudes, warp and walkable slope are
connected controls. Restart/new expedition applies edits; loaded expeditions keep
their saved values. The preview shares preset Resources; edit the preset actually
selected by the live scene when tuning later expeditions. Movement speed,
ecology and individual affinity remain separate authorities.

## Save framework

Generation version is 12; outer save format is 4. Saves contain validated relief
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

## Cliff tile rendering repair — October 30, 2026

The owner-reported view at seed 2601026, cell (-3, -52), 27-degree tilt,
104-degree orbit and nine-cell zoom reproduced the stretching/speckled patches.
The shoreline shader packed shore/cliff flags into UV2.y. Interpolation could
produce 1.999999 for a cliff-only value of 2; applying mod directly decoded a
shore weight near 2 instead of zero, extrapolating the bank color. Round the
packed flags before decoding. The rendered regression deliberately perturbs
both cliff-only and cliff-plus-shore values; it fails with the old decoder and
passes with the corrected shader.

Terrain now publishes one opaque material skin on each canonical tile, including
pond beds, rather than near-coincident base and turf surfaces. Heights, triangle
splits and picking remain canonical. Exposed rock uses the existing supplied
ambientCG rock color/normal/displacement layers and triplanar mapping. Shared
vertex slopes blend turf and stone continuously across cells and chunks; the
new slope controls are indexed in Inspector tuning. Movement slope flags remain
independent of material blending.

A separate invisible-tree defect admitted obstacle-1 trees on sand even though
that habitat has no supported living-tree body or canonical tree membership.
Generation version 14 omits those invalid sand-tree blockers, leaving other
terrain, landforms, rivers and roads intact. The normal current-version save
policy rejects older development expeditions with the existing new-expedition
message; saved files were not rewritten or deleted. See procedural plants for
the visible-body repair of supported terrestrial tree cells.

Local rendered evidence: `artifacts/cliff-fix/location-before.png` reproduces the
reported view, and `location-after.png` shows the corrected decoder and smooth
rock blend at the same location/camera. These are disposable test expeditions,
not the owner's save. The baseline uses pre-edit terrain geometry with the new
rock shader, so it isolates the remaining packed-flag failure rather than claiming
to be an untouched historical build. Additional isolation captures confirmed the
pattern survived removal of water, grass, shadows and temporary ground. Final
validation is recorded below after checks complete.

Validation: Godot 4.7.2 import/parse passed. Focused suites passed: terrain
materials 4,988; terrain integration 3,654; water shoreline 41,109 (111 partly
wet cells); loading regressions 74; plant diversity 1,976; tree visibility 461;
world generation 149 across 11 seeds; rendered terrain flag shading 6. Total:
52,417 checks, zero failures. The flag test produced one expected failure when
run against a disposable copy with the original unrounded decoder, proving it
catches this defect. The new single-surface shoreline fixture checks exact
canonical heights instead of the removed 0.002-unit overlay. Existing
Canvas/ObjectDB exit warnings remain in integration/loading/render fixtures.
The full validator and an exported build were not run. Changes are reviewed but
remain uncommitted alongside existing owner work on the current codex branch.
