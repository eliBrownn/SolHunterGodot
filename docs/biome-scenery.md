# Biome scenery and exploration review

October 29, 2026. First world-facing slice of the
[world/exploration roadmap](world-exploration-roadmap.md). Normal F5 play now uses
generated-habitat scenery across seeds, with the existing bounded sample retained
as an authored local override. Owner visual acceptance remains open.

## Owner direction

Develop the existing meadow, woodland, heath and marsh first. They belong to a
related landscape: differences should be subtle but noticeable, with meaningful
mechanical differences too. Create new art where needed. Prioritize Sol encounters
and behavior for mechanical differentiation. Authored campaign delivery and Thor
work remain deferred. These instructions do not authorize arbitrary terrain
penalties, new capture rules or affinity derived from a biome's visual palette.

## Required Vastra membership

Every generated living plant must resolve to a canonical Vastra cell, including
numbered/custom assets and water/bank plants in the existing bounded pond.
`NatureAssetEntry.living` is explicit; mark rocks, dead wood and fallen logs false.
`NatureSettings.nonliving_trees` owns dead tree artwork. Model names are not
membership rules. Ground dressing consumes `WorldTerrain.flora_kind`; each chunk
endpoint references `flora_id`, while `ExpeditionState` owns its single reserve.
Many clumps share that cell. Render eviction and density changes cannot remove
saved membership or add energy. Missing registration would disconnect circulation,
repair and vegetation/Vessel ecology. See the
[required hierarchy and content acceptance](vastra-integration.md#generated-vegetation-registration-and-system-hierarchy).

## Connected presentation

| Habitat | Current scenery treatment |
| --- | --- |
| Meadow | Smaller light broadleaf variants, wildflower groups, clover and wispy grass |
| Woodland | Taller mixed broadleaf/conifer canopy, ferns, taller grass and mushrooms |
| Heath | Shorter sparse dry/dead trees, low plants, wispy grass and pebbles |
| Marsh | Wet woodland silhouettes, occasional bare trees, reeds, rushes and low damp-ground plants |

The location display reports the actual generated habitat, including while on a
trail. Named places display both place and habitat, such as `Refuge · Meadow`.
Water and shore retain their existing categories; this work does not add new biomes.

Vastra flora admission uses the same terrestrial policy in Meadow, Woodland,
Heath and Marsh. The previous Meadow/Forest-only filter incorrectly excluded
the latter two despite their rendered vegetation. Routes, reserved ground,
obstacles and slope checks still govern admission. Bare water/sand is excluded;
the existing authored pond's actual lilies/bank plants are registered explicitly. Meadow grass artwork remains limited to Meadow/Woodland, while
Heath/Marsh retain their own plants, including living rush endpoints. The
existing local simulation area and conserved packet rules remain unchanged.

`resources/nature_biomes.tres` owns the normal world's scenery selection. Its four
child resources in `resources/scenery/biomes/` own trees, relative tree height,
ground tint, cosmetic plant entries and density. `NatureBiomePalette` interprets
the existing generated ground ID; it does not generate ecology or terrain.
Colors blend at neighboring habitat boundaries and use absolute vertex samples.
Detailed and temporary streamed ground share those tint rules and matching skirt
endpoint colors, avoiding separate color schemes as terrain streams in.

Generated blocker anchors/counts, terrain heights, habitat IDs and traversal rules
are unchanged. Different tree geometry changes visible silhouettes and picking;
recheck clearance when authoring new proportions. Decorative plants reuse
`NatureComposition.placement_for` and `NatureAssetEntry`: uniform scale, transformed
bounds, slope, surface, route/site reservations and required clearings are admitted
before publication. Cosmetic clusters use the existing independent salts. Render
chunks contain dressing; they do not own ecological state or generated locations.

The old bounded composition now lives in one shared
`resources/scenery/bounded_composition.tres`. Both the original study settings and
the new normal-world settings reference it. Seed-specific sample overrides and
the existing pond sign remain intact. Outside those overrides, biome palettes
apply across seeds rather than only inside the original three rectangles.

Restart/rebuild applies art changes, including to loaded expeditions. No generation
or save version changes are needed for this visual slice. Existing saved geography,
individuals and outcomes remain authoritative.

## Supplied art

The owner supplied three archives in Downloads. Fourteen additional unmodified
MegaKit glTF models, buffers and required shared textures were selected, bringing
the imported MegaKit subset to 28 models. Its included CC0 notice remains in
`assets/nature/License_Standard.txt`; see [provenance](../assets/nature/PROVENANCE.md).
Native willow, dry-tree, reed and rush placeholders remain provisional art.
No raster image generation or new asset purchase was required for this pass.

`Rocks.zip` contains one FBX scene, a Blender file and a texture, with no included
license notice. The shrub/flower/mushroom archive contains 20 FBX models and a
license link to [CraftPix's terms](https://craftpix.net/file-licenses/). The archives
were inventoried without executing their contents or treating readme text as
instructions. Neither pack was copied into the repository or published in this
slice; the selected MegaKit art provides the initial coherent set.

## W0 findings and evidence

An automated normal-input controller visited the refuge, woodland/pond review
coordinates, waystone, dryland coordinates and return. Destinations are fixed
review samples, not guarantees that a coordinate has the same habitat on every
seed. Live clock, AI and automatic contact remained enabled; contacts were observed
and withdrawn. This is traversal evidence and visual analysis, not free-choice
human play, a 20-minute player study or proof of enjoyment.

Seeds 2601026 and 7 completed the original route without traversal failures.
Concurrent audio edits changed inputs during seed 7; its captured run is not a
frozen combined-build result. Seed 19 initially failed to reach the pond using the
older profiler's narrow search rectangle. Widening only the review controller's
search area allowed the full normal-input route to complete with zero failures.
No generation repair was needed for that observed failure.

Three priorities from the covered views/code inspection:

1. Generic `The wilds` hid actual habitat transitions. Habitat labels are now connected.
2. Meadow/woodland shared trees, heath/marsh shared another palette, and small
   plants mostly used one global mix. This slice connects distinct habitat palettes.
3. Ambient procedural wildlife still selects the same two prototype species
   regardless of habitat, while catalog species use explicit trail placements.
   Habitat-specific encounters/behavior are the next mechanical slice.

Focused verification after corrections:

- `tests/biome_scenery.gd`: 435 checks, zero failures. Covers actual model admission,
  generated dressing across three seeds, blocker counts, unchanged sampled ground,
  deterministic reconstruction, reservations, shared tile colors and agreement
  between temporary/detailed ground at shared vertices.
- `tests/nature_composition.gd`: 1,640 checks, zero failures; original bounded
  placements and two-part pond sign remain connected.
- `tests/terrain_integration.gd`: 3,565 checks, zero failures for covered terrain,
  grounding/picking and persistence contracts.
- `tools/review_biome_scenery.gd`: four actual generated habitats rendered at
  1280×800 with controlled clear-noon lighting, zero fixture failures. Art fixtures
  explicitly reposition the player; they are not walking/behavior acceptance.

Logs and screenshots: `artifacts/world_exploration/`. Failed launch, scale and
boundary experiments remain separately labeled in that directory. Early launches
failed on local-data access and automatic Vulkan fallback; successful rendered
runs use the installed pinned engine with explicit D3D12. No error was suppressed.
This is focused verification, not a new full configured-validator or device pass.

## Next mechanical slice

Source comparison used SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`, `src/systems/world/sol_catalog.py` and
`src/systems/world/ecology_profiles.py`. The former demonstrates authored biome
eligibility/weighted selection; the latter separates temperament, behavior and
stable individual traits. Old biome names, affinity vocabulary, probabilities and
unimplemented chase/social behavior must not be imported as current canon.
Relevant callers/tests and later decision evidence still need reconciliation
before defining a new runtime admission rule.

Reuse species briefs and the existing Godot behavior library to specify a small
habitat-aware population pilot. Record authored eligibility separately from visual
palettes and independent affinity. Preserve admitted individuals and explicit
trail sightings; define when new habitat-aware admissions apply, how unsuitable
homes are omitted, and how vacant homes recover without rerolling saved identity.
Start with existing supported patrol/idle/approach/flee/guard actions. Exact pools,
weights and newly requested behaviors remain authoring/specification work; this
scenery slice does not claim mechanical biome differentiation is complete.

Phase 2 extends this initial slice: see [biome encounters and geography](biome-encounters-geography.md).
Normal land scenery now gives biome palettes precedence over the bounded study,
with geographic regions owning placement and regional/grove/individual scales.
The historical first-pass evidence above remains unchanged; current development
uses generation 10 and expedition state 18.
