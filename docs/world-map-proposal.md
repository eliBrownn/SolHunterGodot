# Map-first world generator

The owner adopted the map-first build as the main game on November 5, 2026.
`scenes/gameplay_foundation.tscn` launches the current Plan v7 implementation.
Plan v2 established the atlas layout. The standalone proof runs the same Godot
generator before the playable terrain and vegetation are streamed.

1. **Geography.** Seeded continental arrangements, coastal noise, islands and
   mountain belts establish the land mask and broad elevation.
2. **Climate.** Latitude and elevation set temperature. Ocean crossings
   replenish atmospheric moisture, while rising terrain depletes it. A weaker
   return pass softens the prevailing west-to-east rain shadow.
   A warm equatorial belt favors jungle, while subtropical drying and the
   interiors of large landmasses leave room for deserts.
3. **Drainage.** Godot's Priority-Flood solver routes rainfall into connected
   channels and finds the spill elevations of inland basins. The plan stores
   downstream cells, relative river discharge, and lake surfaces.
4. **Biomes.** Coast, ocean, and lakes follow the geography and water plan.
   Elevation, temperature, and rainfall assign meadow, woodland, heath, marsh,
   desert, jungle, savanna, alpine, tundra, and taiga.
5. **Irrigation.** Low-gradient river reaches can supply nearby fields within
   a bounded distance and water budget. Every field records its supplying
   intake. Irrigation raises soil moisture while retaining the natural biome
   and rainfall record. This is a map-scale placement model.
6. **Terrain handoff.** Generate one `WorldMapPlan` per world before creating
   terrain workers. Pass workers the completed read-only plan layers.
   `sample_world_cell(Vector2i)` returns the local biome, natural biome,
   elevation, temperature, rainfall, soil moisture, lake surface, river discharge and receiver, and
   irrigation intake at an absolute cell. Terrain may refine channels and
   fields within the parent plan's constraints. Biomes, water links, and
   intakes stay categorical. Elevation and climate interpolate between samples.

Plan v2 introduced 640×480 map samples, four times the initial sample count.
Each sample represents a square 96 world cells across. The centered map covers
61,440×46,080 world cells and resolves out-of-bounds queries as ocean.
Scale, biome thresholds, rainfall, and irrigation budgets are provisional.
Crossings, settlements, built canals, ecological territories, and authored
progression constraints are outside this stage.

## Playable handoff

F5 and `godot --path .` run the default gameplay scene. It chooses a fresh
seed on launch and builds the atlas before streaming terrain. Pass
`-- --world-seed=2601026` to replay a world. Use the
[gameplay validator](../README.md#validate-the-map-first-build) for the
startup scene and this page's proof exporter for atlas-level checks.

Plan v7 retains the continental layout and refines the local height and water samples. Tundra requires a temperature below 0.24 and an atlas
elevation of at least 0.30, about 66 world cells above the ocean at the parent
sample. Alpine retains priority above 0.62. Meadow uses the existing Plains ID
and forms open fields with shallow folds.
The terrain worker samples the plan's broad elevation and adds local relief.
The ground material reads the same world coordinates for biomes, rivers,
water surfaces, and irrigated ground. Land uses plain biome colors, slope
shading, and mesh lighting. Distant biome color boundaries use a narrower
filtered blend. The daylight sky uses two 1024×1024 cloud
textures and a 512-pixel radiance cubemap. Terrain fog fades from 2,600 to
7,800 cells and matches the sky at the horizon. The current exploration controls allow
travel over land and water. Visual vegetation now streams as part of the
main gameplay scene.

### Watershed refinement — November 5, 2026

The owner selected SolHunter-Gameplay as the main game and asked to bring the
watershed study's terrain style into its map-first world. At local scale the
plains carry less high-frequency relief, while narrower rock ribs strengthen
with elevation. The river atlas samples at eight world cells instead of twelve.
Curved segments share their junction points and widen with flow, with fixed
outlet points in lakes and ocean. Raising the river threshold from 125 to 140
reduced admitted river samples by 11–15% across the three proof seeds.
The same river raster drives ground carving, terrain color and the close water
mask. The comparison confirmed the same continental elevations, biome IDs,
lake levels and downstream links. Irrigation re-evaluates land where the
admitted streams change.

The normal gameplay scene passed its movement, terrain and horizon smoke test
with seed 2601026. The atlas proof passed for seeds 2601026, 41971 and 73020.
The D3D12 river-junction camera fixture is
`artifacts/world-map-v5/gameplay-watershed.png`.

### Irrigation and local biomes — November 5, 2026

Plan v6 derives a local biome after the atlas assigns river intakes. Irrigated
desert, savanna, and warm low heath can become Meadow. Already-moist meadow
and woodland can become Marsh in warm, low basins. The result feeds the terrain
palette, the in-game biome label, and the map proof. The plan keeps the natural
biome, rainfall, and supplying intake as separate fields. Irrigation geometry,
landform elevation, and planned water levels still come from their existing
atlas layers.

The three proof seeds produced 141, 150 and 66 local biome changes. The v5-to-v6
comparison matched natural biomes, elevation, climate, rivers, lake levels,
and irrigation intakes exactly. The normal gameplay smoke check for seed
2601026 verified that the live biome label uses the local classification.

### Biome terrain shapes — November 5, 2026

Plan v7 uses local biome weights for height as well as appearance. Meadows have
shallower regional folds and less small-scale height variation. Desert hills
carry wind-shaped dunes with winding crests and intervening troughs. Adjacent
atlas cells blend their weights into the same height query used by the player,
near chunks and the horizon. Dune relief tapers near the mountain belt, and
the existing shoreline and channel passes fit the terrain to water.

At seed 2601026, the sampled 384-cell meadow's RMS grade fell from 3.9% to
1.5%. The same-size desert sample rose from 8.0% to 32.5%. The normal scene
smoke test passed with the new terrain.

### Shared plant and tree palette — November 5, 2026

Every land biome can draw from the same grass, eight ground plant forms, and
seventeen custom expedition tree forms. The canopy includes twelve baked
procedural forms and five named designs. The seeded map still controls local
density, the mix of grass and ground plants, slopes, moisture, and root
clearance. Coast, desert, alpine, and tundra have sparse tree sites. Ocean and
lake beds are excluded from terrestrial planting.

Grass, ground plants, and trees are 1.5× taller and wider by default.
[Plant Scale](inspector-tuning.md#map-first-vegetation) adjusts both dimensions
around the plant's root. Tree site checks account for the larger root footprint.
The seeded gameplay test covers the shared palette, size, and plant patch revisit.

### Tree species and LODs

Each of the seventeen custom tree forms has its own resource under
`resources/plants/map_tree_species/`. The resource references its baked
model settings, sets a maximum canopy width and relative spawn weight, and
lists eligible biomes. The defaults list all eleven land biomes. At a viable
site, the map selects a species from that biome's list and applies the biome's
hue shift to its foliage. The shift travels with each instance through all
detail levels.

Camera distance from the tree patch edge selects one of eight levels. The
full authored mesh stays active out to 512 world cells. Each subsequent
level reduces faces while keeping the original materials. The final two
levels drop additional faces when the mesh simplifier runs out of reductions.
Leaf cards are thinned as complete leaves. Levels begin at 512, 608, 704, 896,
1,152, 1,408, and 1,792 world cells. Neighboring levels share the same planted
transforms and blend over the next 32 cells in either direction.

Individual tree patches cover the detailed terrain window. Beyond it, the
terrain worker samples sparse groves through all eight terrain rings, using
the same seed, species eligibility, and biome hues. Grove footprints widen
as sample spacing increases from 16 to 128 cells. Their roots follow the
triangles of the rendered terrain, including the stitched outer edges.
Nearer horizon rings group their groves into 256-cell patches. The horizon
groves follow the same camera-distance schedule as the detailed trees.
The terrain and forest blend together over 0.4 seconds as the horizon recenters.
New local vegetation patches fade in over 0.25 seconds. The outer
ring extends to 8,192 world cells along its axes, subject to the camera view.
The seven inner ring boundaries retain each terrain sampling density at
least 30% farther, rounded up to the next coarser grid for stitching. The
four-cell geometry extends to 688 cells, up from 528.

### Ground asset LOD and coverage

Grass and ground plants use the eight tree geometry bands scaled by their
fitted height relative to a six-cell tree. Grass first simplifies the
original blade shapes, then drops blades in successive tiers. Other ground plants use the mesh simplifier's available index levels
and retain their authored materials. Levels share the same placement and
blend over the same height-scaled bands. A sparse, fixed subset of ground-cover sites remains in the
detailed terrain window. Additional foreground sites fade from 56 to 96
camera cells. The sparse sites fade after their size-scaled last tier.

Trees and ground plants measure camera distance to a batch edge. Terrain
rings recenter with the published player chunk. The tree-to-horizon handoff
blends from individually placed trees to sparse groves.

### Earlier visual plant rollout — November 5, 2026

Ground cover pairs the shared grass blade with Open fan, Divided frond,
Oxide thorn crown and Ribbon leaves from the
[official plant catalog](../resources/plants/official_catalog.json).
The canopy palette for Meadow, Woodland, Heath and Marsh follows the
Worldbuilding Bible's Ecosystem gallery. Each habitat has three crown
families with small, medium and large forms. The five named catalog trees
also appear in their source habitats. A seeded roll selects a crown family
or named tree, and the grove field biases the size class. Irrigated dry
meadow uses the Heath palette. The 41 baked models under
`resources/plants/ecosystem_trees/` use the SolHunterGodot runtime asset
paths indexed by `artifacts/ecosystem-review/manifest.json` in the source
project. The separate selected library specimen stays a gallery reference.

New map plant drafts extend the visual palette. Jungle uses Rain vault,
savanna uses Copper flatcrown, and taiga uses Rime spire. Coast uses Salt
ribbon, desert uses Dune paddle, alpine uses Scree cushion, and tundra uses
Frost mat. These draft recipes use the shared mesh builder and participate
in the map's visual planting pass. They are available for design review.

Meadow has denser grass, coast has sparse tufts, woodland and jungle favor
groves, and deserts favor sheltered scrub. The other land biomes have their
own density and color profiles. Irrigated grassland in a dry natural biome
gets sparser, drought-colored cover. Woodland and jungle trees concentrate in
groves where the soil is moist. Taiga canopy thins in colder and drier ground,
and heath trees thin toward the treeline. Meadow, savanna and marsh trees favor
damp patches or dry ground along water margins. Irrigated dry meadow retains
sparse, dry-climate trees near those margins. Increasing grade thins canopy
before the slope cutoff. Tree size follows the same continuous grove field
that drives local canopy density. Dense cores favor larger trees, while
open edges and steeper slopes favor smaller trees, with slight seeded
variation at each site. Water masks, root clearance and spawn clearance
keep tree sites on suitable ground.

Absolute, seeded sites own the placements. The map terrain's shared
height query supplies the roots, and visible terrain gates publication.
Ground cover uses nine close patches and canopy uses up to 49 patches.
Preparation examines a bounded set of sites per frame and publishes at most
one patch of MultiMesh batches. Compacted tree assets supply native
distance LODs. The Terrain node's `plant_coverage` control defaults to 0.72
and applies on scene restart. A value of zero gives the terrain-only view.
Living plants and Vastra circulation belong to the next milestone.

For seed 2601026, the earlier `artifacts/map-plants/procedural-trees.png`
captures the preliminary generic woodland palette. The earlier
coast-to-meadow camera pair in the same directory
used imported trees. That planted view had 58 patch records and 1,799 plant
instances. Its settled 90-frame comparison on the development PC measured
p95 frame intervals of 1.38 ms for terrain and 1.54 ms with plants.
The gameplay smoke fixture checks normal input across a chunk seam and
deterministic reconstruction of a retired plant patch.

## Reproduce the proof

From the Godot project folder, run:

```powershell
godot --headless --path . --script res://tools/export_world_map_proof.gd
python tools/render_world_map_proof.py artifacts/world-map-v7
```

The renderer requires Pillow. The default proofs use seeds 2601026, 41971
and 73020. To export different seeds, pass a destination and seed numbers after
`--`, for example `-- res://artifacts/custom-maps 33 209`.
The JSON files contain the geography, climate, water, irrigation, and both biome
layers rendered by the atlas. The default export checks seed repeatability,
distinct maps, an ocean border, all 13 categories, river continuity, lake
levels, intake reach, the tundra elevation floor, and agreement between the exported layers and world-cell
sampling.
