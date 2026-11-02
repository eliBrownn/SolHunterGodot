# Biome encounters and exploration geography

## Vegetation hierarchy requirement — October 29, 2026

Generated vegetation across all habitats must participate in the Vastra hierarchy. Geographic regions and absolute cells own plant definitions; the expedition owns reserves and ecological transactions; biome art references those cells. Missing plant membership would disconnect circulation, repair and vegetation/Vessel activity. This requirement does not derive individual affinity from habitat or alter encounter weights.
See the [current registration contract](vastra-integration.md#generated-vegetation-registration-and-system-hierarchy) for owners, admission and acceptance.

October 29, 2026. Phase 2 of the [world exploration roadmap](world-exploration-roadmap.md).
This is a playable prototype slice; species admission weights and visual tuning
remain provisional. Campaign story and Thor optimization remain deferred.

## Habitat identity

Owner tuning, November 1, 2026: ambient wilderness Sol home slots now use half
the sectors (alternating absolute sector parity), reducing generated spawn
density by approximately 50%. Terrain/habitat eligibility can still omit a slot.
Retained slots keep their original home search, species and identity. Explicit
trail/catalog sightings and companions are unchanged. Restart the game to apply
the change to the loaded area's admission; existing saved individual records are
retained, while excluded sectors no longer supply ambient views or new spawns.

Normal expeditions use four editable habitat encounter pools in
`resources/sol_world_sightings.tres`: meadow has Bellroot and Thimblehart;
woodland has Crown-Ear and Glass-Throat; heath has Ashquill and Rattlehorn;
marsh has Reedback and Bitterfrill. All current weights are equal. These choices
use existing species briefs and behaviors; they do not establish final canon,
rarity, new ecological effects or biome-derived individual affinity.

The existing deterministic sector-home search selects from the actual ground's
pool. Existing explicit sightings remain. Individuals retain species behaviors,
identity, movement policies and saved outcomes independently of view streaming.
An expedition captures its pool once; editing resources affects new expeditions,
not saved residents or the admission policy of an existing world.

Mechanics reconciliation used `eliBrownn/SolHunterSource` at
`115f3e87acc1716c7113523567c01e1666681885`:
[catalog selection](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/systems/world/sol_catalog.py),
[ecology admission](https://github.com/eliBrownn/SolHunterSource/blob/115f3e87acc1716c7113523567c01e1666681885/src/systems/world/ecology.py),
`src/systems/world/ecology_profiles.py`, `tests/test_ecology_profiles.py`,
`tests/test_wild_history_handoff.py` and
`docs/coordination/ecology-profile-authoring.md`.
The supported pattern is habitat-aware candidate selection
with inherited reactions and persistent identity. Legacy source affinities and
species names were not imported. Godot remains the generation authority.

## Hierarchical scenery and landforms

Biome palettes own asset choices and material tints. Tinting clones mesh/material
resources without altering imported assets or their vertices. Regional scale,
grove scale and individual scale combine to produce stands and clearings rather
than uniform scattered copies. Detail patches use absolute geographic regions;
render chunk boundaries do not define production planting boundaries. The old
bounded composition remains an isolated study and a water/shore fallback.
Streaming bounds include the landform height allowance and the complete inherited
canopy scale, so larger geography and trees stay within the view contract.

`resources/terrain_exploration.tres` supplies normal-game relief. Seeded districts
own compact ridge/pass, basin, plateau-shoulder or terrace descriptors. Broad and
detail noise add local variation. Elevation supports smooth simplex or Perlin;
changing the family is an experiment, not a substitute for landform structure.
Both use the same absolute-coordinate sampling and captured settings.

Local finite-grid drainage analysis resolves depressions and contributing area.
It influences pond candidate placement together with raw elevation and authored
exclusions. This is a water-flow factor, not a connected river network. Connected
streams, coordinated outlets across districts and crossings remain subsequent
work. See [research report 02](research/noise-landforms-water.md) and its reproducible
noise/drainage comparison.

## Traversable paths

Generation first reserves candidate roads, then establishes cabin/landmark
foundations, admits roads against final terrain, and places scenery. Final road
admission samples every half cell and checks a three-cell corridor, water,
foundation obstacles, maximum slope and orthogonal clearance at diagonal corners.
Unsafe optional routes are omitted. The mandatory refuge-to-waystone route keeps
its existing three-cell access guarantee. Path paint is suppressed on unwalkable
cells. Scenery cannot reserve required road access.

The normal exploration shelter uses a separate authored search center at x=224;
the stronger relief does not provide a legal foundation in its former search
window. Its bounded search and foundation/access requirements remain unchanged.

## Save and review contract

Generation version is 10, heightfield contract is 3, expedition-state version is
18. Start a new expedition to review these changes. Earlier disposable development
saves are rejected rather than silently reconstructed with different geography.

Focused checks live in `tests/habitat_encounters.gd`,
`tests/exploration_geography.gd`, `tests/biome_scenery.gd`, and the existing terrain,
scenery-site and generation suites. Actual movement checks consume admitted roads
through `can_step(..., 3)`, independently of the route admission predicate.
Rendered biome fixtures and noise maps live under `artifacts/world_exploration/`;
fixture relocation is not evidence of normal-input travel or player enjoyment.
Owner visual/play review remains open. Integration results are recorded separately
from canceled or failed intermediate runs.

Focused desktop evidence on the phase-2 working tree:

| Check | Result |
| --- | --- |
| Habitat encounters | 934 checks, zero failures |
| Exploration geography, both noise families over three seeds | 1,497 checks, zero failures |
| Biome scenery, including tint cloning and streaming | 444 checks, zero failures |
| Scenery sites, including the normal exploration shelter | 226 checks, zero failures |
| Existing terrain geography suite after final-road admission | 8,615 checks, zero failures |
| Script ownership/UID audit | 151 scripts, zero failures |
| Final rendered biome fixtures | Four habitats, zero review-tool failures |

Logs: `artifacts/world_exploration/phase2-final-*.log`,
`phase2-paths-*.log`; final images and resident records:
`artifacts/world_exploration/phase2-current-biomes/`. Rendered review used the pinned
Godot engine with D3D12. It is an art fixture, not a normal-input journey.

Integration uncovered fixture assumptions that changed with habitat populations:
the roster/anatomy fixtures now identify explicit showcase individuals instead
of assuming only one nearby individual per species. The save fixture still
requires every saved row to remain identical; additional traversal rows must
belong to newly admitted nearby individuals. The four-species encounter/capture/
companion/save sequence passes 152 checks; normal rollout passes 243 checks.

The separate flight/swimming pilot explicitly retains its original Rolling
terrain preset, so the capability fixture does not silently inherit a different
pond layout from normal-game authoring. Its 85 checks pass. The normal game keeps
Exploration relief. The exploratory lower starting camera angle was withdrawn
after a real pointer check correctly hit foreground terrain instead of an
occluded enemy. The established 35-degree start passes combat polish (24 checks),
and orbit/tilt remain available. Combat balance was not changed. The polish test
also recalculates its final damage expectation after its own field-state edit.

All 73 configured test scripts have passing results across the initial invocation,
focused fixes and bounded continuations. The final continuation exits zero and
includes terrain integration (3,565), geography (8,615), shoreline (22,605) and the
normal 3D scene journey (2,532), all with zero failures. See
`artifacts/world_exploration/phase2-integration-evidence.json` for the result index
and source hashes. This is not a single frozen full-validator pass: separate
environment-art work changed shared files during testing. The failed intermediate
logs are retained, and configured CI remains unchanged. New streaming bounds were
checked by the subsequent 3D/view/streaming/horizon and final-journey suites.

The headless 3D smoke run recorded one cold chunk publication near 955 ms. This
is not a desktop performance acceptance claim or Thor result; initial publication
latency remains a measurement to review during ordinary play. Owner enjoyment,
visual and physical-input acceptance remain open.

## Slope readability and movement follow-up — October 29

Owner play feedback: slopes beside paths were difficult to distinguish from
cliffs, and movement needed smoothing. Detailed ground now carries the exact
`slope_fits` cell classification into its grass/bank shader: unscalable ground
shows muted exposed stone. Dense meadow cover is omitted on those cells.
Coarse queued ground uses its representative cell and switches to exact per-cell
coverage when detailed geometry publishes; it is not a traversal guide.
UV2.y packs shoreline in the low bit and blocked slope in the next bit; shoreline
consumers decode the independent bank flag. Road admission, heights, generation
versions and player collision remain unchanged.

The visual player body follows terrain height with a bounded 0.06-second response;
feet remain grounded by the existing procedural solver. The camera follows with a
0.12-second response while retaining terrain clearance. Pause holds the filters;
reconstruction, teleports and Home reset their relevant anchors. Controls and
disable options are indexed in [Inspector tuning](inspector-tuning.md).

Mechanics reference: the local SolHunterSource checkout reports
`development/world-redesign-0.2` at `d6f0902d77ed46a2f7d251c354792a4cc9210bc4`.
Read `src/app/controllers/player_movement.py` and
`docs/coordination/warning-movement-continuity.md`: held input advances complete
visual strides while retaining logical step ownership. This pass preserves the
Godot stride duration, diagonal collision and arrival/save rules; it adds only
visual height filtering. Source working-tree cleanliness was not verified.

Focused evidence for the mixed working tree is under
`artifacts/slope_traversal/`. Headless traversal passes 26 checks; rendered D3D12
traversal passes 29, including live leg-solver reach. Shoreline passes 22,605,
biome scenery 404, and fog/horizon 132. Ownership audit passes 153 scripts/UIDs.
An initial shoreline failure exposed the old metadata decoding in its test;
the final test checks the bank bit independently. The broader view test exposed
a stale assertion that treated continuous meadow cover as small decoration;
its expectation now preserves the already implemented terrain-horizon distance.
The corrected final view suite passes all 765 checks. Final D3D12 traversal
passes 29 checks after the stone contrast refinement; measured maximum ankle
target error was 0.0185 cells and settled error rounded to zero.
Final rendered captures are `artifacts/player_traversal/player.png` and
`slopes.png`. The slope capture explicitly relocates the fixture to blocked cell
(-29, -48), seed 71, to inspect its surface; it is not evidence of legal player
travel to that cell. Normal-input owner feel review remains open. No full
validator, multi-seed play acceptance or device acceptance is claimed.
