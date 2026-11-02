# Procedural plant proof of concept

November 1 size follow-up: world foliage now defaults to twice its prior scale,
controlled by `NatureSettings.foliage_size_multiplier`. Existing path, terrain
and neighbor admission still constrain fitted bodies; source meshes/recipes
remain authored baselines, and leaf-grass retains its separate height controls.
Generation now arrives in finer credits at the unchanged rate; see the
[generation flow contract](vastra-integration.md#fine-generation-flow--november-1-2026).

## Shared leaf lift and blended grass ground — November 1, 2026

Plant leaves, tree leaf cards, live leaf-grass and optional meadow blades share
the reserve-driven tip-drop/lift function. Empty reserves droop free tips;
full reserves restore authored posture. Attachments and roots remain fixed,
with weather motion additive. The alternate meadow renderer now admits per-cell
reserve instance data and consumes the same posture/pigment Inspector controls.

Grass-covered ground reads the same canonical energy/capacity ratio through
`ground_reserve_view.gd`, a bounded read-only 128×128 geographic texture updated
at most 256 cell reads per frame. Each texel retains previous/target reserve and
active-time transition start. Interrupted changes and overlapping window moves
preserve the displayed value; paused time freezes interpolation. Unregistered
or out-of-window cells retain authored color rather than inventing reserves.
Four neighboring cell-center readings blend smoothly across tile/chunk edges.
Detailed and distant terrain share that projection; trail, bare soil, bank and
rock contributions retain their material identity. Ground tint changes color,
not terrain height or plant admission. No presentation consumer writes energy.

Godot 4.7.2 validation: leaf/grass/ground links passed 35 rendered checks; nature reserve
contracts passed 46 rendered checks; terrain materials passed 4,893; the actual
3D world passed 65 checks and rendered. The low/mid/full review lives locally in
`artifacts/leaf-reserve/low-mid-full.png`; receipts use `artifacts/leaf_reserve_*.log`.
The runtime plant palette was rebuilt successfully (153 definitions).

## Reserve readability implementation and review — October 31, 2026

Implemented consumer for [N1](world-exploration-roadmap.md#nature-delivery-sequence):
leaf saturation increases with the canonical plant/tree reserve and decreases to
pastel at low reserve; leaves lift with charge. Preserve authored hue, anatomy,
wind and species variation. Reserve response is posture, not levitation, growth
levels or an automatic damage/health indicator. Visual clumps do not own state.

Shared foliage consumers read actual flora identity and the saved reserve.
Visual acceptance still requires low/mid/full review at normal camera in both
habitats, day/night, calm/wind, streaming and load. Do not mark this delivered from
existing pulse/receive animations alone. Mechanics and outward overflow belong
to [Vastra integration](vastra-integration.md#approved-ecology-delivery--october-31-2026);
plants/tiles gain no distortion aura simply from fullness or ecological overload.

## Generic foliage world rollout — October 30, 2026

Plan steps 4–6 connect all twenty reviewed forms to normal terrestrial play.
`foliage_distribution.gd` proposes visual communities from the saved world seed
and absolute geographic coordinates. Sixteen-cell geographic parents own jittered
patch centers, irregular noise-broken edges and a palette of three related forms.
Overlapping fields give dense centers, sparse edges, isolated specimens and gaps;
none of these parents depend on render chunk admission or camera position.
Wetness, existing bank distance and nearby generated tree anchors influence density.
Terrain slope and the actual transformed footprint remain hard admission checks.

### Circulation decision and ownership

Live generic foliage is an **emanator growth form on existing canonical ground
cover cells**, alongside reviewed grass. It does not admit new flora, introduce an
unclassed receiver population or acquire Warden/Mender/Regulator abilities. The
cell retains its existing `FloraTraits` role, ID, region and single reserve.
`FloraCatalog` and `ExpeditionState` remain the membership and transaction owners.
Grass remains around the foliage body and leaves its center/recipient anchor open.
The body's ground intake and emanating opening provide its physical anchors;
the distinct unclassed receiving anatomy remains an editable draft study.

Read-only source reconciliation reused `vastra_simulation.py` at SolHunterSource
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` and rechecked
`tests/test_vastra_foundation.py` at `115f3e87acc1716c7113523567c01e1666681885`.
They support bounded regional updates, sparse state and independent concentration/
overload; they establish no additional foliage population rule. The existing
[Godot circulation contract](vastra-integration.md) already owns grass/emanator
behavior. Reusing that owner is a presentation decision, not a new energy mechanic.

### Placement and tuning

The shared plant library selects the patch's form, then fits its seeded individual
size. It tries scale factors 1, 0.72 and 0.5 before leaving rejected placement empty.
Neighbor priority is stateless with a complete two-cell halo, so query order,
cache eviction and streaming cannot change spacing. Suppression is conservative:
a higher-priority candidate can suppress a neighbor even if that candidate later
fails terrain admission. Footprints include wind allowance and exclude protected
routes, sites, camps, landmarks, water and neighboring specialist recipient cells.
Trees/specialists also try bounded smaller fits; oversized procedural trees may
use their small palette model. Every alternative retains the full access checks.

`NatureSettings.foliage_coverage` (0–1, default 0.65) applies on rebuild/restart,
including loaded expeditions. Zero removes these visual bodies without removing
grass or canonical reserves. This is scenery tuning; no generated identity,
terrain layout or save schema changes. Shared model caching, MultiMesh batching,
native scenery distance/detail, weather and event animation remain in use.
New underwater population remains deferred.

In the maker, **Generic circulation** independently selects live emanator anatomy
or the unclassed receiving draft. Focus one biome/form to save. Live emanator
designs can be explicitly enabled for matching cells; receiving drafts cannot.
The twenty-design comparison and existing recipe save/load remain available.

### Acceptance evidence

`tests/foliage_rollout.gd` covers three seeds and all four habitats, all five forms,
community palette bounds, reverse query order, cache reconstruction, protected
placement, bounded smaller alternatives, shared grass endpoints, unchanged saved
reserves, save/load and live maker admission. The grass ecosystem journey retains
the actual conserved send, in-flight reload and arrival. Its transform animation
check requires the real renderer; the headless dummy renderer did not reflect
that MultiMesh update. The D3D12 run passed all 15 grass checks.

`tools/review_foliage_rollout.gd` captures four actual generated habitats and a
woodland/meadow boundary pilot, compares disabled/default/dense coverage, and
checks identical placements on revisit. Its `report.json` and captures live in
`artifacts/foliage-rollout/`. Measurements are matched-camera desktop observations,
not owner enjoyment acceptance or a target-device performance guarantee.

Final rollout checks: **7,293** placement/ownership/anatomy/maker assertions passed.
The separate real-geography suite passed **1,906** checks, finding 200 foliage
bodies and 31 tree bodies in sparse samples of seeds 7, 19 and 2601026. All twenty
live forms appeared in actual generated terrain across those seeds. The current
biome integration suite passed **13,376** checks, the diversity suite **1,976**,
the generic-design suite **902**, the maker suite **69**, and the rendered conserved
grass journey **15**. The two new rollout/geography suites are included in the
existing shared validator without changing the configured CI job/check name.

The generated-world review covered all four habitats and the woodland/meadow
edge at `(-8,128)` in seed 2601026. The revisit check retained the same 42 default
foliage bodies and all transforms/IDs. A close-height capture is
`pilot_walking_height.png`. At 1280×800, Direct3D 12 on the local RTX 3070,
six isolated 120-frame windows produced these paced measurements:

| Coverage | Foliage bodies | Frame p95 | Peak draw calls |
| --- | --- | --- | --- |
| Disabled, two windows | 0 | 16.687–16.690 ms | 1,622 |
| Default 0.65, three windows | 42 | 16.683–16.687 ms | 1,879 |
| Dense 1.0, one window | 58 | 16.688 ms | 1,926 |

This holds the 60-FPS cap in the covered desktop pilot; it does not establish
uncapped headroom or handheld acceptance. The earlier maximized 2560×1369 run
showed 37–59 ms p95 and one noisy identical-geometry repeat, so it is not a
60-FPS high-resolution result. The isolated windowed report is
`artifacts/foliage-rollout/windowed-performance/report.json`. The existing two
Canvas/ObjectDB shutdown warnings remain in world review logs; no engine/script
errors occurred in the final rendered journeys. A full configured-validator or
device export pass is not claimed for this focused rollout.

## Reviewed foliage style and shader tree canopies — October 30, 2026

Owner direction: carry the approved generic foliage design into trees and plants,
with plentiful tree offshoots and leaves; investigate a shader leaf approach and
verify plant anatomy. Shared role plants now default to restrained habitat pigments
like the reviewed foliage family. Their existing physical exchange structures and
specialist silhouettes remain. Authored palette overrides remain available.

Tree scaffolds split into three connected offshoots, followed by paired smaller
forks. Layered rising/spreading leaves fill the terminal shoots. The runtime tree
palette uses painted shader leaf cards for small canopy leaves: two triangles per
card, atlas alpha cutout, a subtle visual rib, soft backlighting and weather-driven
tip motion. Cards have fixed spatial orientation, not camera-facing billboards.
Large shaped leaves, trunk, branches and offshoots retain geometry. Meadow/heath/
marsh use the existing painted leaf; woodland cards use the divided-frond region.
The same saved active weather clock drives movement. This changes presentation,
not membership, reserve capacities, circulation, abilities or expedition saves.

**Tree leaf cards** in the maker/anatomy lab's **Tree structure** controls switches
between shader cards and mesh leaves. Recipes retain the switch. Silhouette mode
preserves alpha cutouts; anatomy cutaway excludes cards. Existing baked library
scenes remain authored assets; changing a builder does not overwrite their files.

Anatomy verification covers every organ's rooted parent, exact graph/anchor
agreement between leaf renderers, cutaway separation and canopy-shoot attachment.
New shoots now start on stored conductor midpoints rather than linear positions
beside curved branches, so foliage remains physically attached. Leaf render counts
never create ecological owners or additional reserves.

Focused Godot 4.7.2 evidence: `tests/tree_leaf_cards.gd` passed 587 checks. Four
same-seed biome comparisons each retain 54 structural offshoots; total triangles
fell from 26,488/31,304/25,688/27,648 to 16,408/21,224/15,608/17,568
(approximately 32–39%). This measures geometry, not frame-rate or GPU-overdraw
performance. `tests/plant_diversity.gd` passed 1,976 checks, anatomy passed 2,812,
and maker passed 69, including the final silhouette-helper integration. The focused
card suite additionally checks the corrected shoot attachments and cutout-aware
silhouette restoration. Logs are under `artifacts/`. The comparison capture is
`artifacts/tree-leaf-cards/comparison.png`, produced by
`tools/review_tree_leaf_cards.gd` using real Direct3D 12 rendering.

## Plant communities experiment — October 30, 2026

In the Development Lab (F8), choose **Plants / communities**. The left bed is an
independent-scatter control; the right uses habitat-weighted patches, bounded
neighbor spacing and a canopy influence on understory density. Both use the same
seed, analytic rolling ground and protected curved path. This is a synthetic
experiment, not a comparison against the current production generator.

The shared Coverage controls provide habitat selection and sliders for seed,
patch size (3–24 cells), coverage (0–1), spacing (0.5–4 cells), canopy influence
(0–1) and absolute geographic offsets. Changes rebuild on release. Existing
Compare, Review and Speed tools remain available. Each bed reports plant/tree
counts, shared body count and construction time; the first bed may pay cold
geometry costs, so the two construction times are not a paired speed benchmark.

`scripts/world/plant_community.gd` owns the experimental layout proposal. Its
absolute-cell hash, continuous patch field, stable candidate priority and fixed
six-cell neighbor halo make results independent of query order. A bounded cache
is invalidated on configuration changes; callers must also clear it when site
inputs change. Same-layer footprint rejection is conservative: a higher-priority
candidate can suppress another even if it is itself suppressed. Canopy influence
uses proposed tree candidates, not a physical light simulation or growth model.
The fixture fits shared procedural bodies to the admitted footprint. It does not
write flora membership, reserves, live ecological state or generation settings.

At the October 30 checkpoint, the experiment's tree/population proposal remained
isolated. Production generic ground foliage used the separate visual rollout
above, reusing canonical emanator cells without a generation/save schema change.
The [October 31 production integration](#production-community-layout--october-31-2026)
supersedes that isolation status. New living placements must use the existing
Vastra registration contract. No growth, reproduction or mortality mechanics are added.

Evidence: `tests/plant_community.gd` checks four habitats, reverse query order,
negative coordinates, cache reconstruction, full-footprint access, same-layer
spacing and workstation controls. `tools/review_plant_communities.gd` captures the
actual workstation at `artifacts/plant-communities/lab.png`. Baseline seed 73 in
woodland produced 86 control plants (28 trees), versus 52 community plants (12
trees), sharing two body definitions in each bed. Density differs; no performance
gain or final visual acceptance is inferred.

Validation: Godot 4.7.2 headless community suite passed 7,223 checks, including
actual workstation slider discovery and deferred rebuild. The D3D12 workstation
capture completed without engine/script errors; script ownership passed with
183 mapped scripts/UIDs. Initial import passed; an early fixture run exposed an
unowned inherited selector, now attached and hidden, and a test was corrected to
wait for the existing deferred rebuild. Final focused output is clean. No full
validator pass or production-world baseline is claimed.

## Generic foliage category and designs — October 30, 2026

Plan steps 1–3 add a morphology category independent of biome, circulation role
and specialist class. In **Plants / maker & library**, set **Growth category** to
**Generic foliage**, choose a biome and select variation 1–5. The selected form's
name appears in the notes. **Review all 20 foliage designs** opens a common-scale
grid with one row per biome and five forms per row. Choose a biome to compare
its five forms, then choose a named form in the foliage selector to edit/save one
draft. Select **All five foliage variations** to return to that biome's comparison.
All-biome selection can also compare one variation across the four habitats.
Existing shape/size sliders and draft save/load remain usable;
Unclassed receiver drafts cannot be published; selecting emanator circulation
permits explicit live publication. Role forms remain the default.

| Habitat | Five related forms |
| --- | --- |
| Meadow | Open fan, Low rosette, Cupped leaves, Branching spray, Folded cluster |
| Woodland | Divided frond, Layered leaves, Hanging folds, Arching stems, Broad shade leaves |
| Heath | Compact cushion, Curled thick leaves, Overlapping scales, Twisted low branches, Upright folds |
| Marsh | Upright sails, Ribbon leaves, Hollow sheaths, Overlapping cups, Arching narrow leaves |

`scripts/scenery/generic_foliage_mesh.gd` reuses the shared curved leaf, stem,
material and connected-anatomy builders. Scaffold arrangements and habitat leaf
structures differ physically. Seeded angles, reach and proportions vary individuals;
the palette keeps restrained habitat pigments independent of affinity. Receiving
and releasing surfaces sit inside a connected basal structure. This is proposed
living-body anatomy, not specialist behavior, approved species or a lifecycle.

`AuthoredPlantLibrary.foliage_definition(biome, variation)` supplies twenty cached,
reusable draft definitions, separate from live placement candidates. Saved foliage
retains its category, variation, recipe and empty specialist class. Existing
definitions default to `role_form`; loading an older recipe clears foliage mode.
No plant manifest, canonical admission, reserves, terrain or save schema changes.

Mechanics boundary: source lookup read `src/systems/world/vastra.py` and
`tests/test_vastra_foundation.py` at SolHunterSource
`115f3e87acc1716c7113523567c01e1666681885`, plus
`src/systems/world/vastra_simulation.py` at
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`. These establish sparse state,
concentration/overload separation and bounded regional updates; they do not
establish a generic foliage circulation role. The existing Godot circulation
reconciliation in [Vastra integration](vastra-integration.md) remains authoritative.
The receiver anatomy used here is provisional and draft-only. Live `FloraTraits`
currently admits grass emanators, reservoir trees and specialist receivers; this
change does not replace those identities or silently turn foliage into specialists.
The world rollout above resolves live presentation through existing emanator
cells. The existing maker hosts the comparison; no new lab or expedition
population is created. **Inspect anatomy** hides outer growth;
**Compare silhouettes** uses black plants on a pale background without soil disks.
Selections and rebuilds retain these review modes. The optional world-unit ruler
and standing figure keep sizes comparable. Numeric tuning uses the existing
workstation sliders and applies on release. Multi-design views cannot save drafts.

Godot 4.7.2 focused validation: `tests/generic_foliage.gd` passed 902 checks,
covering seeded reconstruction, distinct forms, individual variation, finite/bounded
geometry, connected anatomy, reusable definitions, draft-only admission and maker
save/load, twenty-form layout, named selectors, fullness editing and review-mode
retention. The existing maker suite passed 64 checks. The actual Direct3D 12
twenty-design render is produced by `tools/review_generic_foliage.gd` at
`artifacts/generic-foliage/palette.png`; actual workstation captures are
`lab-overview.png`, `lab-silhouettes.png` and `lab-anatomy.png` in the same folder.
Visual approval and production
distribution/performance remain open. Tests use an isolated repository-local
APPDATA directory; the initial default-directory import encountered permission
errors and is not a clean validation result.

October 30, 2026. Owner direction: generate all plant life procedurally; underwater
life is deferred. Vastra has its own in-world identity and language. Its fungal
design reference must remain behind the scenes, appearing only through subtle
hints rather than explicit game terminology or origin claims.

## Review in the development lab

### Plant size range

The maker supports 0.02–20 world units of height and 0.02–12 of spread, saved
with the recipe and the game asset. **Preserve proportions** keeps natural
uniform fitting; disabling it permits independent height and width. Ground
plants no longer have an invisible 1.5-unit height cap. Size presets range from
tiny groundcover to trees; exceptional sizes remain opt-in. After owner review
rejected the towering example, normal random plants were reduced to 0.04–1.8
units and trees to 1.8–7.5. The runtime palette uses restrained small/medium/large
variants (ground targets 0.08/0.5/1.5; trees 2/4/7, with modest seeded variation).

Plant/leaf size and height/spread multipliers also have wider authoring ranges.
The maker shrinks its preview platform for tiny plants, supports close zoom,
and reframes after size edits. Rendering bounds account for enabled plant height
and canopy width; actual placement still checks the entire footprint and wind
margin against protected routes and terrain. Large dimensions do not add reserves,
abilities, terrain obstacles or generation slots.

`tests/plant_size_range.gd` verifies extremes, independent/uniform scaling,
save/load, full runtime ground-plant height, visibility bounds, protected-access
rejection and presets. `tools/review_plant_size.gd` reviews a modest 0.8-unit plant
in the actual maker without saving any plant asset.

Size verification: 21 size checks, 28 maker checks, 496 diversity checks and
9,682 live-view checks passed. Pinned-engine import was clean. The live-view
suite retained its two existing Canvas/ObjectDB shutdown warnings; no size or
view assertions failed. The final rendered preview uses natural proportions
and a modest 0.8-unit plant.

### Biome and Vastra anatomy samples

Choose **Plants / biomes & Vastra anatomy** in the shared workstation, or launch
with `-- --plant-anatomy`. The scene is `scenes/plant_biome_role_lab.tscn`.
There are 24 proposed samples: Meadow, Woodland, Heath and Marsh each have an
emanator, reservoir, unclassed receiver, and Warden/Mender/Regulator receivers.
The last three are specialist classes on the receiver role, not additional
circulation roles. The unclassed receiver is an anatomy comparison candidate;
it does not add a new live population rule or approved species.

Biome and role selectors allow a six-sample habitat view, a comparison of the
same role/class across habitats, the complete grid, or an individual specimen.
**Cutaway / expose anatomy** hides outer growth while retaining connected
conductors, storage tissue and exchange structures. Organ labels and leader
lines appear when one specimen is selected. They remain development annotations.
The 24 numeric controls are grouped by structure, leaf shape, Vastra anatomy,
and seed/size/motion. Applicability suffixes and label tooltips explain narrower
controls. **Reset shape controls** returns shape settings to their defaults.
**Silhouette view** compares black plant shapes on a pale background; role
comparisons place the four habitats side by side. Detailed ranges are in
[Inspector tuning](inspector-tuning.md#procedural-plant-lab--october-30-2026).
Sidebar rebuilds preserve the selected biome/role and applied cutaway state.

The generator defines a connected organ graph first, builds conductor tubes
between its exact anchors, then wraps stems, folded leaves, shaped blades and
specialist growth around those structures. Reservoirs include crown receipt/
release and root exchange; emanators connect ground contact to blade-tip outlets;
receivers have receiving cups, local storage and release openings. Broad guarded
growth distinguishes Wardens, basal rosettes/folded blossoms Menders, and staggered
exchange collars Regulators. Woodland grows taller and layered, heath lower and
compact, meadow open/spreading and marsh upright/narrow with hanging tree foliage.

Owner review rejected the first anatomy samples as too similar. The revised
builder changes the underlying growth structures and leaf profiles by habitat,
rather than relying on scale and tint. Meadow uses broad bowls, fans and radial
flowers; woodland uses divided fronds, layered branches and hanging bell forms;
heath uses low succulent scales, thorned cushions and twisted spreading trunks;
marsh uses tall pitchers, upright sails, stilt roots and long weeping ribbons.
Role-specific growth combines with those habitat structures. Exchange openings
have physical lips/membranes instead of a repeated wire basket. Storage tissue
is enclosed by the outer stem/sheath and exposed by cutaway.

These are static physical anatomy proposals. The graph is structural and its
links are not energy-transfer instructions. Tissue colors are neutral study
materials, not affinity or ecological-state coding. This fixture changes no
roles, classes, saved reserve capacity, transfer routes, repairs or abilities.
Existing `FloraTraits` and the reconciled [circulation contract](vastra-integration.md)
provide role evidence; [vegetation design](living-world-concept-report.md#plant-classes)
keeps classes separate. No source-repository mechanics are replaced or invented.

### Original growth-form study

Press **F8** in normal play, then choose **Plants / procedural forms**. Or run
`scenes/development_workstation.tscn` with `-- --plant-prototype` to select it on
startup. The separate `scenes/procedural_plant_lab.tscn` is also runnable with F6.

Eight specimen beds show broadleaf trees, conifers, shrubs, ferns, flowers, grass,
reeds and provisional Vastra forms. Each bed has three seeded variants. Select
a growth form to isolate and frame it, right-drag to orbit, and scroll to zoom.
**New seed variations** changes the seed; the same seed and controls reconstruct
the same geometry. This is a morphology study, not an approved species roster.

The shared sidebar supplies labeled sliders for seed, branch count, plant size,
leaf size, foliage density, curl and wind strength, plus a label switch. Changes
apply on release by rebuilding the fixture. The shared Pause, Step, baseline,
notes and paired capture controls work normally. Changing family resets its view;
rebuilding returns to the overview. Settings are local to this lab session.

## Implementation and existing textures

`scripts/scenery/procedural_plant_mesh.gd` generates tapered branch/stem tubes, curved ridged
leaves, paired fern leaflets, radial petals, grass blades, reeds and Vastra ribbons.
Each specimen batches its geometry into at most four material surfaces. No imported
plant meshes are used. Local random streams use independent per-family/per-variant
seeds, without consuming the world's RNG.

Existing supplied assets are reused without modification:

- `assets/nature/Leaves.png`: painted green leaf atlas region, with explicit UVs.
- `assets/nature/Flowers.png`: painted pink petal interior; mesh owns the outline.
- `assets/nature/Bark_NormalTree.png` and `Bark_NormalTree_Normal.png`: bark with
  the supplied normal map.
- `assets/terrain/ambientcg/ground048/`: color and supplied OpenGL normal map for
  the specimen beds. Existing source/license records remain with the assets.

The foliage shader uses the fixture's elapsed clock for restrained wind. Pause
therefore freezes wind; it does not rely on shader TIME. The fixture restores its
viewport anti-aliasing setting when removed.

This isolated art fixture does not create an expedition, saved reserves, species,
ecological classes or simulation events. Production integration must retain the
[canonical vegetation registration contract](vastra-integration.md#generated-vegetation-registration-and-system-hierarchy)
and separate species, growth form, role and class. The existing geography engine
remains authoritative for placement and access. Existing authored pond content is
unaffected by the deferral of new underwater generation.

## Delivery checklist

Owner follow-up: plant designs require anatomy for Vastra. Each species must
define structures appropriate to its circulation role, and procedural growth
must preserve their connections. The original growth-form proof does not provide
that anatomy; the separate biome/role study above now demonstrates connected
proposed structures. Their species designs and production adoption remain open.

Proposed anatomical expression, pending art review: ground-contact structures,
continuous conducting ribs, storage tissue where appropriate, and distinct
receiving/releasing surfaces. Grass anatomy should express its established
emanation role; trees should express receipt, stockpiling, onward release and
outward root overflow. Other plants retain their existing receiving/specialist
roles. These proposals do not add routes, reserves, capacities or abilities.
Anatomical anchors should eventually replace generic particle attachment points;
visible transfers must still follow actual conserved ledger events. Keep organ
names and forms original to the world, with the underlying Vastra reference subtle.

- [x] Reuse existing painted textures and authored surface maps.
- [x] Generate geometry for eight representative terrestrial/Vastra growth forms.
- [x] Show three deterministic variants per form in the shared lab.
- [x] Provide sliders, form selection, orbit, zoom, pause and capture/report support.
- [x] Check deterministic reconstruction, different seeds, tuning limits and controls.
- [x] Inspect actual rendered overview and representative close views.
- [x] Owner approved the 45 pictured catalog designs as official visual baselines; future revisions retain a review step.
- [x] Generate connected proposed Vastra anatomy before wrapping themed foliage
      and bark; provide cutaway review by biome and circulation role/class.
- [ ] Author recognizable species and habitat-specific variation constraints.
- [ ] Extend remaining forms: willow-like growth, dry/bare trees and groundcover.
- [x] Connect reviewed terrestrial forms to world placement, canonical Vastra
      membership, bounds/picking, path clearance and rendering budgets.
- [ ] Add production instancing/distance detail and validate streaming reconstruction.
- [ ] Address underwater life in a later phase.

## Validation

Godot 4.7.2: `tests/procedural_plant_lab.gd` checks all eight builders, exact seeded
reconstruction including UVs/normals, seed variation, finite geometry at both tuning
limits, per-specimen geometry ceilings, workstation sliders, family isolation,
parameter rebuild, pause and report readings. `tests/development_workstation.gd`
checks the host's existing controls and fixture selection.

`tools/review_procedural_plants.gd` captures the real workstation overview, four
close views and a settings/geometry report into `artifacts/plant-prototype/`.
Run using Direct3D 12 for the local review. This is focused lab validation, not
full game regression evidence or production performance acceptance.

Local result: 57 plant checks passed, workstation regression passed with zero
failures, pinned-engine import completed cleanly, and Direct3D 12 overview/close
captures were inspected. Default review contains 24 specimens and 213,336 mesh
vertices; this is a lab measurement, not a production instance budget.

The anatomical study uses `tests/plant_biome_role_lab.gd` for complete sample
coverage, graph reachability, exact rendered connection endpoints, seeded mesh/
organ reconstruction and variation, geometry at tuning limits, selector behavior,
cutaway, settings persistence and report coverage. Its capture script is
`tools/review_plant_biome_roles.gd`; paired whole/cutaway views, four biome views,
the full grid and settings/organ report are in `artifacts/plant-anatomy/`.

Initial anatomy follow-up result: 1,161 checks passed with zero failures. The original
57 plant checks and shared workstation regression also passed after the builder
refactor. Godot 4.7.2 editor import completed cleanly; actual Direct3D 12 biome,
whole/cutaway and full-grid renders were inspected. No full game suite or
production ecology/performance acceptance is claimed by this art study.

Silhouette/control revision: 1,224 anatomy checks, the original 57 plant checks
and shared workstation regression passed. The anatomy suite now checks all 16
new numeric controls against generated geometry, all control extremes, shape
reset and silhouette material overrides. Pinned-engine import passed. New real
Direct3D 12 captures include four biome views and side-by-side reservoir/Warden
silhouettes. Visual species approval remains open.

## Live plant system integration â€” October 30, 2026

The owner approved the last batch's appearance and requested more maker diversity
and whole-system integration. `plant_library.gd` now prefers enabled saved designs
at matching canonical biome/role/class slots and supplies a bounded procedural
fallback for trees and Warden/Mender/Regulator receivers. Four habitats, four
functional forms and three variants give 48 reusable models. The approved
single-blade grass continues to render emanator cells and ground cover; grass
around a specialist never creates another reserve. Legacy pond plant bodies are retired from live rendering; their canonical
membership remains intact. New underwater generation remains deferred.

The maker and world share the mesh builders and material factories under
`scripts/scenery/`. New Growth diversity controls select habitat foliage, broad
fans, divided fronds, succulent scales or long ribbons, plus seeded branch
irregularity and unequal leaf halves. Defaults retain habitat foliage and regular branching; the later organic refinement
softens the shared surfaces.
Randomize includes these settings; saved recipes retain them. These controls
change physical geometry, not species approval, affinity or ecological rules.

World selection uses independent cell rolls; a fixed palette seed reconstructs
geometry without consuming generation RNG. Runtime models reuse the established
static MultiMesh, picking and native distance LOD pipeline. Placement retains
existing slope, footprint and protected-route checks and falls back to existing
empty presentation where rejected; legacy plant bodies are never used as a fallback. Receiving and crown organs supply live Vastra anchors;
FloraCatalog and ExpeditionState retain membership and all transactions. Weather
updates the same cached foliage materials through the existing atmosphere owner.
No mechanics changed; the reconciled circulation evidence above remains valid.

Focused validation: `tests/plant_diversity.gd` covers all 48 definitions, geometry
budgets, variants, placement across habitats and specialist classes, protected
spaces, canonical identity, crown anchors and weather propagation. The maker,
anatomy and original form suites also exercise authoring. Tests use isolated lab
settings and look up controls in their current workstation dock.
`tools/review_plant_diversity.gd` renders the runtime palette to
`artifacts/plant-diversity-palette.png`. Production population/performance and
owner review of these added variations remain separate from focused validation.

### Organic shape refinement

Owner follow-up: soften the shapes and make them more organic. Shared stems now
use curved interpolation through the authored anchors, continuous transported
cross sections and smooth shading. Closed exchange lips keep a continuous width
at the join. Leaves have four curved strips across their width, subtle lateral
sway and softened lobes instead of a sharp central fold. Indexed geometry reuses
shared vertices; anatomy reports count the actual mesh vertices after indexing.

**Organic softness** is a 0â€“1 slider in Growth diversity (default 0.7); higher
values soften bends and leaf cups while leaving organ endpoints connected. The
randomizer chooses 0.6â€“1.0. An append-only smoothed revision of the existing
project-library plant is enabled under the same identity; its original remains
on disk. Draft/load/save and live placement retain their existing contracts.

Validation after refinement: 310 diversity checks, 28 maker checks, 1,567 anatomy
checks and 57 original growth-form checks passed; earlier integration checks
passed 812 Vastra checks, 11,777 biome-scenery checks and the maker/world refresh
journey. The world journey reports existing Canvas/ObjectDB shutdown warnings.
Rendered runtime-palette and actual maker captures are produced by
`tools/review_plant_diversity.gd`; full-game performance acceptance is still open.

### Fuller foliage and repeated branching

Owner follow-up: add foliage and fractal-like spread to the overall structure.
Foliage shoots now fork recursively at smaller scales, ending in layered leaf
clusters. Each child starts exactly at its parent tip; lengths and stem widths
shrink each generation. Physical conducting tissue follows the new shoots back
to existing branches. These presentation branches do not create ecological slots,
reserves, recipient routes or roles. The reviewed grass remains unchanged.

The maker and live palette share this structure. Growth diversity adds
**Foliage fullness** (0â€“2, default 1), **Branching depth** (0â€“3, default 2),
**Branching spread** (0.2â€“1.3 radians, default 0.75) and **Branching reduction**
(0.4â€“0.75, default 0.62). Zero branching depth retains direct leaf clusters.
Small secondary leaves and leaflets use fewer lengthwise strips while retaining
curved cross sections, keeping all 48 runtime models within the existing budget.
The enabled project plant has a new revision with the fuller branching structure;
all earlier saved revisions remain available.

The focused diversity suite checks real geometry at the new controls' limits,
three structural scales, exact parent/child attachment and decreasing branch
lengths, alongside the existing 48-model admission and budget checks. Maker and
anatomy regressions pass; final palette and actual-maker captures were inspected.

### Basic plant event animations

The live view consumes committed transfer projections and the existing specialist
activity readings through `scripts/presentation/plant_animation.gd`. Receiving
briefly swells/lifts the plant; releasing contracts and recoils; repairing gives
soft upward pulses; protecting broadens and braces; regulating uses an alternating
pulse. Weather continues to own idle wind. This is presentation of existing
mechanics, using the reconciled circulation/ecology evidence above.

Transfer sends use the recorded send tick. A receiving response requires
`credited_tick`, not a scheduled arrival. The saved active clock drives duration,
so pause freezes reactions and combat follows the continuing world. Loading a
new state clears old reactions. Reactions are transient, bounded to 128 active
cells and do not write saves, plant reserves, membership or event history.
Specialist activities use the existing bounded local inspection projection.

Chunk uploads retain compact cell/instance index groups for living bodies,
including procedural grass, authored terrestrial plants and existing pond plants.
Only reacting groups retain their rest transforms. Each frame derives its pose
from those originals around fixed ground pivots; completion restores them exactly.
Nonliving scenery stays unchanged. Meshes, shared materials, placement, picking
and navigation retain their static owners; the deformations are deliberately small.

In the maker, **Event animation preview** selects Idle, Receiving, Releasing,
Repairing, Protecting or Regulating, with strength (0â€“2) and duration (0.5â€“3 seconds)
sliders. Previews loop locally and never generate simulation events. The live
world exposes the same strength/duration controls on `world_solid.gd`.

`tests/plant_event_animation.gd` runs with the real compatibility renderer because
Godot's headless dummy renderer reports placeholder MultiMesh transforms. Its
45 checks cover timing, committed-credit gating, separate instances sharing one
mesh, fixed roots, paused clocks, exact restoration, activity selection, state
replacement and event bounds. `tools/review_plant_events.gd` captures all six
maker preview states into `artifacts/plant-event-*.png`.

Event-animation verification: the rendered 45-check event suite and 28-check maker
suite passed, pinned-engine import was clean, and the maker/world refresh journey
passed with its existing Canvas/ObjectDB shutdown warnings. Ownership and scoped
whitespace audits passed. The event renderer captured Idle plus all five responses
in the actual maker; these captures use strength 2 for review. Runtime defaults
remain strength 1 and 1.6 seconds.

### Complete live asset retirement

October 30 owner follow-up: live terrestrial trees and specialist bodies use only
admitted plant-library designs and the shared procedural palette. The chunk
renderer rejects imported tree/detail fallback calls and living composition
records outside the library. Old biome plants, tropical specialists, dead-tree
fallbacks and pond artwork no longer render in the expedition. Nonliving rocks
and the reviewed procedural grass remain. Rejected footprints stay empty rather
than bypassing protected spaces. Aquatic replacements remain deferred; existing
pond membership/reserves and ground endpoints remain under generation and saved
state ownership. Source assets and lab reference palettes remain on disk for
provenance and comparisons. No ecology or world-generation rules changed.

Retirement validation: 496 plant-diversity checks and 8,413 generated-biome
checks passed, including renderer rejection of old tree/specialist/pond bodies,
new-library picking/endpoints, shared grass ownership and deterministic rebuilds.
The maker/world refresh journey passed with its existing shutdown leak warnings.
The rendered procedural palette and maker capture completed; palette inspected.
Ownership and scoped whitespace checks passed. Editor import finished, but local
editor-settings saves and OpenGL shader-cache writes reported permission errors;
this is not a clean editor-validation claim or a full-suite/performance pass.

### Foliage crown correction — October 30, 2026

Reservoir crowns now retain paired leaves along secondary shoots and larger
terminal fans, rather than concentrating small leaves at the finest twig tips.
The maker groups fullness, density, size, architecture, asymmetry, curl and blade
shape under **Foliage**. These controls rebuild the existing outer body; leaves
keep the existing painted plant shader, shared weather uniforms, cutaway behavior,
baked library export and whole-plant event animation ownership.

Validation: 496 diversity/budget checks, 28 maker checks and 45 rendered event
animation checks passed. The event fixture now uses a real procedural library
tree through the current composed renderer, replacing its retired add_nature path.
The rendered 12-tree palette was inspected. Local user-directory/editor settings
and shader-cache permission errors prevent a clean editor-import claim.
Existing baked library revisions retain their saved geometry; load and save a new
revision in the maker to apply the fuller crown to an authored asset.

Physical plant size classes (October 30): Small, Medium and Large are independent
of circulation roles and Receiver specialties. Plant Maker class selection applies
a size; randomization stays within it. Tree height ranges are 3–5, 5–8 and 8–12
units; other plants use 0.04–0.3, 0.3–0.8 and 0.8–1.8. Height/spread remain
adjustable. Saved assets retain the class; older assets default to Medium without
changing dimensions. Reservoirs now have trunks and ascending scaffold tiers
in every biome, retaining their distinctive foliage and roots.

Role expression adds release blossoms to Emanators, collecting cups to Receivers,
shield surfaces to Wardens, soft reaching tendrils to Menders and repeated exchange
vanes to Regulators. These are adjustable visual cues on existing nodes, not new
mechanics. Organic softness now also rounds multi-joint stems while preserving
attachment anchors; the lab default is 0.9.

### Assigned colors and reaching tree limbs — October 30, 2026

Every plant recipe now assigns stem/bark, leaf and flower/accent palettes
independently. Surface colors use canopy-height and leaf-base-to-tip gradients;
color diversity adds subtle continuous patches. Diagnostic internal tissue retains
its existing neutral colors. Trees use earthly green, sage, gold and copper leaves
with brown, gray, red-brown or pale bark; their hue offset is limited to 12 degrees.
Smaller plants retain their broad habitat pigment and full hue range. Assignments
are primitive recipe fields, retained by the existing draft/game-asset save flow.

Reservoir limbs keep ascending bases, then reach farther and arch over toward
upper crown tips. `branch_reach` and `branch_arch` rebuild connected conduit and
outer branch paths together. Tree classes now target 3–5, 5–8 and 8–12 units;
the shared runtime variants target roughly 3.5, 6 and 10. Existing baked assets
keep their dimensions and geometry until deliberately resaved. Runtime view bounds
include the larger procedural crown. Full-footprint terrain/access checks still
apply and may reject a larger tree where space is insufficient.

Reference reviewed: H. Nuić and Ž. Mihajlović, *Algorithms for procedural generation
and display of trees*, MIPRO 2019, pp. 247–252 (owner-provided `19_Mipro_Nuic.pdf`).
Sections VI and VIII informed the restrained use of hierarchical branch growth and
curved branch rendering. This extends the existing bounded generator; it does not
implement the paper's voxel model, particle simulation or GPU geometry pipeline.

Validation for this color/tree follow-up: 637 diversity/color/budget checks and
21 size checks passed; the focused role/asset save check passed with independent
palette and gradient persistence. Pinned Godot 4.7.2 editor import passed. A
7-unit-height/6.5-unit-width natural-proportion specimen was rendered and visually
inspected both standalone and in the development workstation. The review opens
one fixture and rebuilds its specimen directly to avoid the previously observed
shared-panel full-reload stall; full panel reload remains a separate known issue.

Plant suite cleanup (October 30): **Plants / maker & library** starts with
**All biomes · side by side** and **All plant forms**, showing 24 editable previews.
The **All biomes · all plants** button returns to this overview from a saved/focused
selection. Shared sliders affect the visible designs; select one biome and form
before saving an individual asset. Save buttons disable in overview, and the store
rejects ambiguous multi-specimen saves before writing. Prior saved selections are
preserved when revisiting a session. The anatomy comparison station also defaults
to all biomes. Earlier procedural forms remain a reference station.

Size class, biome/role locks and cutaway have one visible control each; their
redundant generic Inspector-derived controls are hidden in the shared dock.
Randomize, size presets and library load rebuild the specimen in place, preserving
the editor controls rather than destroying their fixture during a button callback.
The full maker flow now passes 34 checks, including default overview, focused
saving, recipe restoration, seeded randomization and unlock behavior.

### Grass under the shared plant owner — October 30, 2026

`AuthoredPlantLibrary.add_cell` now selects and submits every live terrestrial
plant presentation, including built-in grass emanators. It resolves canonical
FloraTraits, selects an authored or procedural body, delegates individual blades
to `meadow_art.gd`, and keeps a ground endpoint when art is disabled or rejected.
Enabled matching authored emanators replace the default blades; specialist ground
cover shares its existing cell owner and leaves the specialist center open.
The specialized seven-triangle blade mesh, spatial batching, density thinning,
trail clearance and individual-root event poses remain rendering responsibilities.

The atmosphere calls the plant library once for weather; the library passes the
same active clock, direction and floating origin to grass and other plants. Grass
keeps its existing rain response and retains weather received before its first
material is created. No flora generation, save schema, circulation role, reserve,
repair rule or Vessel transaction changed.

Validation: `tests/grass_ecosystem.gd` passed 15 rendered checks spanning shared
placement, late material weather, event animation/restoration, density/visibility
independence, a real grass-to-tree conserved send, reload and arrival. Maker checks
passed (35), including authored grass replacement; generated-biome checks passed
(10,278). The integrated grass capture is `artifacts/grass-ecosystem.png`.
Ownership and scoped whitespace checks passed. The wider plant-Vastra suite passed
772 assertions but failed its starting-area rendered grass/tree-pair fixture in
both headless and rendered runs; no circulation-journey pass is claimed. Its grass
selection now uses canonical traits and animation membership rather than asset
name text. Local user-directory/shader-cache permission errors remain.

Comparative scale: the plant editor shows a world-unit height ruler and a neutral
1.8-unit standing figure by default. All visible samples use the same unit scale;
the all-forms overview uses each form's Small/Medium/Large game-height preset,
so a tree is not normalized to the same height as a ground plant. Focusing a form
restores its custom dimensions (or class defaults on first selection). Select a
single biome/form for a closer framed view. `show_scale_reference` can hide the
ruler/figure for extreme closeups; `reference_height` changes the reference figure.
Both belong to **Scale comparison**. Scale markers are viewer-owned and excluded
from saved plant meshes, gameplay geometry, flora membership and reserves.

Biome scene viewer and visual balance (October 30): **Biome scenes** is the default
layout, with each biome's tree and five ground-plant forms sharing a ground patch
at comparative scale. **Plant grid** restores individual specimen plots. Viewer
arrangement is an art comparison, not a replacement for generated-cell placement.
With the reference visible, the maker uses an orthographic camera so foreground
plants are not enlarged by perspective. The reference ruler aligns with tree
root depth and remains outside saved plant assets.

Trees now have connected secondary structural forks, with adjustable
`tree_fork_depth`, `tree_fork_spread` and `trunk_lean`. Forks taper toward smaller
children; foliage remains attached to their tips. Meadow crowns spread, Woodland
forks rise, Heath keeps its jointed form and Marsh keeps lower stilt roots with
shorter drooping curtains. Crown fullness and sparse woodland/heath Emanator
foliage were increased moderately. Anatomical plant materials reduce palette gain
from 1.4 to 1.1 to retain softer leaf/flower color and stem contrast. Existing
fullness, density, color and branch controls still apply. These are visual changes;
no reserves, circulation rules or generation membership change.

Validation after scene/fork/scale changes: maker 64 checks, diversity/color/mesh
budgets 736 checks, size extremes 21 checks and biome/anatomy 1,819 checks passed.
The viewer's four biome scenes and common-scale comparison were rendered directly
with the pinned engine. Scale figures, shared preview ground and scene labels are
not part of plant exports. Existing authored baked assets keep their meshes until
loaded and deliberately saved as a new revision.

Heath trunk joints were also trimmed to avoid a stack of oversized storage bulges.
Final pinned-engine import passed after two missing type annotations in the
concurrently introduced generic-foliage helper were corrected.

### Broad tree crowns — October 30, 2026

Owner clarification: wider trees means outstretched arms, spreading forks and
much fuller leaf coverage, with an epic tree silhouette. Reservoir scaffolds now
reach farther sideways with a lower rise and longer lower limbs. Leaf clusters
also fill the main arms and fork interiors instead of collecting only at tips.
The maker defaults use two fork generations and a 0.95-radian fork opening;
existing saved recipes retain their explicit controls when rebuilt.
The live palette uses six main arms, one structural fork generation and dense
one-generation leaf shoots to retain its existing 30,000-triangle admission cap.
These presentation changes preserve canonical flora and reserves and apply when
models are rebuilt (restart the expedition view or reopen the plant fixture).
Focused validation: `tests/plant_diversity.gd` passed 1,936 checks, zero failures.
The upper scaffold tier also grows into strong vertical crown arms while lower
arms retain their horizontal spread, following the owner's same-day clarification.

### Recursive branches and barrel reservoirs — October 30, 2026

Owner follow-up adds a second structural fork generation to live trees. Each
split produces smaller connected limbs; the wide lower arms and vertical upper
arms remain. Small forks use fewer curve subdivisions and tree leaf blades use
three strips to keep the existing live geometry cap. Live foliage fullness is
1.5. This supersedes the one-generation live recipe described above.
Reservoir storage bodies now have barrel sides with broad flat inset ends and a
bowed middle, including their cutaway tissue. Trunk base radius increases from
0.14 to 0.28 authoring units and tapers to 18 percent at the crown; the existing
stem thickness control scales it. Changes apply on model rebuild/restart.

### Candidate randomizer and official plants — October 30, 2026

The maker's first action row now exposes Randomize and Lock as official. Randomize
focuses a candidate when starting in the overview and clears the editing identity;
it cannot replace any saved official plant. Existing biome/role locks still apply
to focused selections. Tree rolls sample all three size classes. Lock as official
uses the existing validated, append-only library publisher and enables matching
world slots; the saved library marks these entries official. Load selected restores
an official recipe for intentional edits. Generic receiving foliage remains
draft-only; generic emanators can now use matching live ground-cover slots.
Trees now allow hue offsets up to 35 degrees and coherent leaf-color patches
within the crown. Live tree height targets span roughly 1.4–15 world units before
the existing width/proportion fitting and placement checks. The 12-unit width cap
continues to bound live admission. No randomization changes canonical flora or
reserves. Restart/rebuild models for palette changes; controls apply in the maker.
Validation: plant maker save/load/admission and official-preservation journey
passed 66 checks; plant diversity passed 1,505 checks. Direct3D 12 maker review
confirmed the quick actions are visible together in the editor. The renderer
reported its existing unavailable user shader-cache folder; the image rendered.

### Live organ attachments - October 30, 2026

Owner follow-up: tree release packets now select a real accepted leaf surface
facing the destination, and root packets select the destination-facing root tip
at both plants. Leaf attachments are separate presentation metadata, preserving
the structural anatomy graph and mesh/card rendering equivalence. The library
and new maker saves carry these attachments into the placed organ graph. The
68-definition runtime palette was rebuilt. Older authored saves retain their
explicit anchors until re-saved; wind deformation remains a limitation.

Focused checks: organ attachment routes across all four biomes passed; currents
113 checks, maker 83 checks and tree leaf cards 587 checks passed. The rendered
route overlay is `artifacts/tree-leaf-cards/vastra-routes.png`, reproduced with
`tools/review_tree_leaf_cards.gd -- --vastra-routes` (gold leaf paths, cyan root
paths; diagnostic lines, not a recording of live packet timing). Local Godot
also reports unavailable user-log/shader-cache directories.

Live conserved transfer paths leave release organs, enter receiving organs, and
use ground organs for root transfers. Procedural definitions and new plant-maker
saves carry the parent graph through placement to rendering. Paths follow storage,
collar and surface anchors inside each body. Filaments accept up to 64 points and
travel by path distance without smoothing across organs. Ledger recipients,
reserves and arrival times remain unchanged.

Existing baked definitions retain their four explicit organ anchors; re-save them
in the maker to include their internal graph. Absent art retains the canonical-cell
endpoint fallback. Following wind/event deformation remains a presentation limitation.

Validation: organ attachment regression passed (transformed intake, outlet, storage
and root routes); Vastra currents 129 checks passed; particle lab 295 checks passed.
The machine also reported a user-log write error; headless checks do not establish
rendered appearance.

## Sparse specialist ecology and natural previews — October 30, 2026

Owner clarification: most ground vegetation should be ordinary/generic, specialists
should also be rarer in the actual ecology, and areas need not contain every plant
type. Future populations may die out and arise; this change does not implement
birth, death, regrowth or a rule that restores an ideal mix.

New expeditions capture `ExpeditionSettings.flora_specialist_percent` (provisional
5%, range 0–25) into ExpeditionState. FloraTraits thins the earlier 25% class
assignment using an independent stable roll and smooth 32-cell geographic
potential. Potential can be zero. No class, patch or biome has a minimum count.
Ordinary results use the existing grass/generic emanator owner; trees keep their
reservoir role. Terrain, rendering, reserve absorption and specialist actions all
consume the same captured percentage. Tree membership, reserves, class abilities
and conserved-transfer rules are otherwise unchanged.

The state snapshot has an optional validated `flora_specialist_percent` field.
Existing version-20 snapshots without it restore 25%, reproducing their original
class assignment exactly; no stored plant, reserve or transfer is relabeled.
New snapshots retain their captured percentage across saves, settings changes and
load/reconstruction. Thus the new rarity applies to new expeditions; old saves
retain their established population. This is an explicit compatible policy capture,
not a terrain/save-version bump or an automatic conversion of established ecology.

The viewer now defaults to **Natural biome mix**: mostly generic foliage, optional
trees and occasional specialist examples drawn from seeded population samples.
It can omit classes entirely. **All plant designs** opens the complete reference
collection for editing, and **Plant grid** remains available. Preview sample count
and specialist percentage are separate viewer controls; they never write live
population or reserves. Preview foliage has isolated weather materials.

Validation for sparse specialists: rarity/policy compatibility **5,725** checks,
maker/natural-preview **83**, ecology **131**, conserved plant transfers **816**,
persistence foundation **76** and generated-geography placement **1,602** passed.
Across seeds 7, 19 and 2601026, the sampled specialist shares were 5.17%, 5.02%
and 5.28%, with 90, 77 and 62 sampled 16-cell areas containing none. All twenty
ordinary foliage designs still reach actual generated terrain. Direct rendering
showed 16–18 common foliage examples and 0–2 specialist forms per preview biome.
Pinned Godot import passed. Existing Canvas/ObjectDB shutdown warnings remain.
The broader Inspector suite has two unresolved movement-duration assertions
against the current movement implementation; its other twelve assertions passed.
This is not a full-validator or movement-validation pass.

## Visible canonical tree blockers — October 30, 2026

The invisible tiles reported during exploration came from tree blockers whose
normal canopy failed the 18-degree presentation slope/neighbor-footprint checks.
After normal library/procedural fitting fails, a canonical terrestrial tree tries
a narrow sapling from the same procedural palette. Its body fits within its own
blocking cell (at most 0.4 cells wide and 1.5 cells tall before sway margins).
It stays upright on an upward-facing slope; protected routes, camp, landmark,
cabin/site reservations and habitat checks still apply. Unsupported final
placements remain rejected. No retired models are revived.

The sapling keeps the cell's existing reservoir identity, membership, reserves,
organ anchors and picking owner; it creates no new gameplay obstacle or plant.
Rejected authored canopies can use this same presentation fallback. Invalid sand
blockers are corrected separately in generation version 14, as documented in
natural terrain. The focused real-world fixture covers 138 supported tree
blockers across two seeds, including 79 compact bodies, alongside protected-space
rejection and rendering/picking/registration checks.

## Production community layout — October 31, 2026

The interrupted production integration is now covered by
`tests/plant_community_integration.gd`. Generation 15 uses the shared candidate
layout for tree admission, with actual biome, slope, protected routes, authored
site reservations and the existing local catchment as context. Generic foliage
uses captured patch scale, coverage, canopy and drainage preferences. It remains
presentation on canonical cells; grass, specialist assignment and conserved
reserves keep their existing owners. Candidate suppression remains conservative,
and canopy influence is a placement preference, not simulated shade or growth.

`PlantCommunitySettings` supplies bounded Inspector controls; new expeditions
capture the values. Save format 5 validates and restores them, including when a
matching live terrain is reused. Differing community settings force independent
generation reconstruction. Earlier development saves are rejected under the
existing disposable-save policy. No migration or ecological rules are added.

The production integration suite passes 1,549 checks for populated canonical
state/save restoration, exact reconstruction after cache clearing and reversed
query order, differing-settings rejection, protected tree placement and zero
coverage. The current 11-seed generation suite passes 151 checks; foliage rollout
passes 9,165 and geographic foliage checks pass 1,341. These replace the older
generation's counts for this checkout, not its historical measurements.

Rendered route evidence lives under `artifacts/community-integration/after/`.
The meadow/woodland stops still fail the three-consecutive-capture Sol-free
criterion, and the woodland view remains open rather than enclosed. Production
layout and saved settings are implemented; habitat composition tuning and quiet
normal-play acceptance remain open. This is not a completed exploration-feel gate.

## Official plant catalog approval — October 30, 2026

The owner approved all 45 designs pictured in `SolHunter_Plant_Catalog.pdf` as the
official visual baseline. `resources/plants/official_catalog.json` records stable
design IDs, PDF pages, biome, independent role/class, captured dimensions/settings,
and SHA-256 hashes of the PDF and capture metadata. All 45 page/name mappings were
verified against the PDF; the roster contains 20 ordinary forms, 24 biome/role
forms and one saved design.

This advances the species checklist from an unapproved design collection to an
approved named visual roster. Initial species boundaries and bounded authoring variation are now implemented
in the Maker; their exact numeric envelopes remain art tuning. Approval does not complete missing conifer/willow/bare-tree,
scrub, grass, creeping-groundcover or marsh-family coverage. Four unclassed Receiver
visuals remain without a live class assignment. Runtime publication, the existing
saved plant manifest, population percentages and saved reserves are unchanged;
PDF suggestions are not treated as additional owner instructions.

## Internal plant fit — October 30, 2026

Owner follow-up clarifies that collision means **parts inside each plant**, not
neighboring plant placement. Leaves and other free surfaces should find room
around the connected structure without stretching, squashing or detaching their
shapes. Preserve intended attachments and enclosing storage tissue. Roots must
extend downward into soil instead of spreading as exposed horizontal spokes.
The original approved catalog remains the review baseline; corrected renders are
kept separately under `artifacts/plant-fit-review/`.


The shared builder now finishes structural tissue first, then checks free leaf
surfaces against that tissue and previously fitted leaves. A bounded deterministic
set of rigid rotations keeps each blade's attachment, dimensions, curvature and
texture intact. Optional blades that cannot fit are omitted rather than stretched
through another surface. Small petiole attachments and intentional enclosing tissue
remain connected. This is static model fitting, not a physics simulation of wind
or a general correction of intersecting authored scaffold branches.

Roots descend along their whole conductor path. New procedural definitions and
maker saves mark their authored soil plane with `roots_below_ground`; runtime and
natural previews ground those models at that plane. Height limits measure growth
above the plane, so deeper roots do not lift the plant or shorten its visible body.
Older baked assets retain their original fitting until deliberately revised; the
approved saved New plant mesh and original catalog are preserved. Rebuilding that
legacy recipe currently exceeds the existing 30,000-triangle publishing limit, so
it was not automatically substituted or published with altered branch settings.

Focused Godot 4.7.2 validation: internal-fit regression 423 checks, ordinary foliage
902, tree leaf cards 587, size range 21, maker 83, biome/anatomy 2,812 and foliage
rollout 8,928 passed. Engine import succeeded with repository-local application
data; script ownership passed for 190 scripts and UIDs. These checks preserve
canonical flora/reserves and cover old mesh-bottom compatibility. Earlier runs
using the default user directory reported log/cache write errors; the successful
isolated import supersedes the initial editor-directory failure. Rendered fitting
studies retain the engine's existing shutdown resource warnings. A full validator
pass and dynamic wind collision guarantees are not claimed.


## Official species presets and bounded copies — October 30, 2026

The Plant Maker's **Official species presets** selector contains all 45 approved
visual baselines. **Load official baseline** starts an independent copy; it never
overwrites the baseline or an existing library revision. Each has a stable species
ID, separate design ID, growth form, biome, circulation role and specialist class.
The source PDF, capture metadata and existing saved New plant are preserved.

The catalog owns initial per-species numeric envelopes. Height/spread generally
vary by 15%, foliage dimensions by 10–12%, branch/node counts by one and hue by
six degrees. Curvature, gradients and asymmetry have smaller bounded changes.
The actual sliders use each species' exact limits. Biome, base growth architecture,
role/class, palettes and size class stay fixed. **Randomize** produces a repeatable
individual inside those bounds; the individual seed is saved with its recipe.
**Customize freely as new design** detaches species identity and opens the full
controls for a new custom design. These envelopes are an initial authoring policy,
not an assertion that every possible seed has received visual approval.

Bound definitions validate species identity and recipe limits during save/load.
Four unclassed Receiver visuals can be saved as anatomy drafts, but cannot be
published until their ecological assignment is resolved. Loading presets does not
publish them or change live population frequencies. Existing saved definitions
without species metadata remain compatible.

For species exports above 30,000 triangles, the save path rebuilds the same procedural
paths with four (or three) radial tube faces instead of eight for the exported
copy, preserving source authoring geometry, materials and anatomy anchors.
Leaves retain their original detail; whole branches and roots are not decimated.
The existing 30,000-triangle/12-surface runtime admission limits remain in force. A specimen that cannot fit still reports an
optimization error. This does not retrofit old baked assets automatically.

Owner follow-up removes imported tree palettes entirely from active nature and
biome resources. Their compatibility fields remain empty and reject repopulation;
procedural plant-library trees retain canonical tree cells and ecological owners.
Source models and provenance remain on disk as historical assets.


Validation for official presets and tree-palette retirement: Godot 4.7.2 passed
533 species/palette/save checks, 83 Maker checks, the development workstation
journey, and 4,328 world-optimization checks. Script ownership passed for 190
scripts/UIDs; the authorized editor import completed without errors. The rendered
Woodland comparison preserves the connected silhouette at 24,866 export triangles
versus 54,304 in the authoring preview. Review images and logs are under
`artifacts/official-plants/`. The real project library manifest remained unchanged.

The broader biome scenery run is not clean: 9,688 checks reported 13 failures
(12 temporary/detailed terrain seam comparisons and one functional-plant endpoint
priority assertion). Those failures remain recorded in `biomes.log`; no full-suite
pass is claimed. World-optimization shutdown reports its existing Canvas/ObjectDB
leak warnings.

### Live official plants and Vastra verification — October 31, 2026

The owner's live-integration follow-up connects all 41 ecologically eligible
official baselines to existing biome/role/class slots. The four unassigned
Receiver studies remain excluded. Explicit enabled library designs retain
priority; canonical membership, specialist assignments, reserves and packet
timing remain owned by generation and expedition state. Trees expose accepted
leaf surfaces and destination-facing roots through the live chunk's transformed
organ graph. New maker saves carry the same attachments.

The initial live-integration bake contained 109 definitions (41 official, plus 68
bounded fallback definitions); the current vegetation revision below expands it.
Catalog inputs participate in the bake fingerprint. Candidate IDs
are cached per biome/role/class and cleared with the library, avoiding a catalog
copy for every generated plant cell.

That initial `tests/plant_live_integration.gd` run passed 311 checks across all official plants,
including eligibility, rendering budgets, placement, exact live chunk organ
handoff, tree leaf/root routes, current prebuilt asset loading and normal tree
selection in all four biomes.
Foliage rollout passes 8,943 checks; conserved Vastra currents pass 113 checks;
the authorized Godot 4.7.2 editor import and script ownership checks pass.
The actual world review captures all four habitats under
`artifacts/foliage-rollout/` and passes four habitat/four performance windows with
zero failures. Its reconstruction comparison uses a fixed central
16×16-cell area: peripheral chunks can differ with the live streaming schedule
and are unsuitable for comparing identical plant placement.


### Current vegetation presentation — October 31, 2026

Owner's latest visual direction supersedes the earlier oversized-tree and live
blade-grass studies. Tree form follows the supplied real-tree references while
retaining the project's authored leaves and biome palette families.

- Each biome has rounded, narrow and spreading procedural habits in small,
  medium and mature classes (base heights 2 / 7 / 14 cells, with seeded size
  variation). Biome-specific branch-rise ranges and individual variation control
  spread; primary limbs keep an upward tendency. Tree fitting remains uniform.
- A continuous tapered trunk skin and smooth bark collars join woody branches.
  Main stems claim space first, then optional side shoots, then leaves. Spatial
  branch-corridor checks try alternate directions and lengths. Leaves try local
  orientations and positions along supporting stems; blocked optional growth is
  omitted. Mandatory functional anatomy remains connected to its canonical owner.
- Side shoots and foliage occupy the middle and lower crown as well as the tips.
  Fine-leaf and curved plant-style leaf variants have separate geometry budgets.
  The latter use short leaf-bearing shoots to fill gaps without long bare limbs.
- The visible tree reservoir is a textured ring at the first branching junction.
  Other plant organs use supplied color and matching normal textures. Tree
  storage membership remains the existing cell reserve.
- Tree event-driven transform animation is disabled. Weather supplies trunk and
  foliage wind. Leaves retain reserve feedback: tip lift and color share a
  smooth 1.2-second interpolation, including interrupted transitions. Shader
  saturation spans pastel to stronger colors through a continuous spatial field.
- Live grass uses narrow procedural leaves at ground level, without visible
  woody scaffolds or pods. Foliage remains a separate population. Existing
  bodies keep their space; fallback cover occupies eligible emanator cells with
  seeded density and scale, using the same canonical ID and reserve. Grass uses
  the grass-distance control and native scenery culling. Existing blade studies
  remain separate fixtures with their source assets intact.
  Each admitted grass tile has a seeded count of 10–40 clumps, mixing leaf
  variants, scale and yaw on a shuffled jittered lattice within the tile.
  Clumps batch shared meshes and reference one canonical cell reserve and graph.
- Roots retain their authored soil plane; maximum burial defaults to 0.06 cells,
  capped at 10% of above-ground height so small cover stays visible. Growth stays
  upright on slopes and uses the saved walkable-slope limit.

Generation 16's larger biome regions and 35-degree slope defaults apply to new
expeditions. These appearance changes apply when scenery rebuilds; no flora
membership, ecological transfer or saved reserve rules were changed.

The bounded runtime palette contains 153 definitions, including 20 lightweight
cover designs. Raw meshes, picking bins and relevant LODs are baked; streamed
cells select shared models. Smooth reserve transitions run in the shader rather
than uploading every leaf every frame. Nearest-organ choices use a bounded cache.
Live tree packing excludes diagnostic interior tissue; bark, leaves and the
textured reservoir ring retain their shared shader surfaces and wind behavior.
The follow-up balances rounded/narrow/spreading habits around moderate, denser
crowns: smaller differences in spread and branch rise, shorter reach for the
widest limbs, and short leafy shoots on curved-leaf variants. Authored species
recipes retain their catalog values while live generation applies the same
balanced branch reach/rise. Bark UVs measure tube length and circumference;
the shader compensates for uniform instance scale in both color and normal maps.
Seeded `branch_curve` adds gentle lateral bends through shared limb sockets;
existing trunk curvature and upward growth remain in place.
Rendered previews are stored under ignored `artifacts/tree-revision/`; they are
review aids, with visual acceptance remaining the owner's decision.

Validation before the crown-balance/leaf-grass follow-up on Godot 4.7.2:
presentation 307, live integration
341, internal spacing 1,212, size ranges 23, diversity 1,039, foliage rollout
9,076, Vastra currents 157, nature-alpha contracts 41, plant animation 55 and
rendered full-3D 65 checks, all with zero failures. Rendered checks use D3D12;
dummy-renderer runs do not validate MultiMesh animation readback. Full-3D and
Vastra teardown retain the existing two Canvas/ObjectDB warnings. Final palette
fingerprint matches the settled source inputs. Close-camera, biome silhouette
and leaf-meter captures were inspected; day/night acceptance remains separate.

Crown-balance, curvature, bark mapping and leaf-grass follow-up: presentation
371, live integration 339, internal spacing/metric UVs 1,207, size ranges 23,
foliage rollout 9,076 and rendered full-3D 65 checks passed without failures.
That rebuilt palette matched its source fingerprint; grass peaked at 216 triangles
and one leaf surface per design. All four biome tree previews, enlarged grass
and the close gameplay capture were inspected. Existing teardown warnings remain.

The 10–40-clump grass follow-up reduces each shared clump to at most 54 triangles
on one leaf surface. Presentation 371, expanded live integration 726, Vastra
currents 165 and rendered full-3D 65 checks passed. Integration covers exact
count bounds, within-tile root spacing, mixed variants, deterministic rebuilds
and one connected cell owner. The final source fingerprint and gameplay capture
were verified; existing teardown warnings remain.


## Continuing close-up plant review — October 31, 2026

The owner requested that the existing review document remain the ongoing plant
review surface: `artifacts/plant-closeup-review/index.html`. Its 158 review IDs
are frozen in [the review registry](reference/plant_review_registry.json), mapped
to actual plant IDs rather than inferred from current catalog order. Original
pictures stay in place. New round captures live in their own revision folder;
the same document offers close-up pairs, original comparisons, biome/search
filters, decisions and per-plant notes. It works from a local file without a
server. Browser decisions are local drafts; Copy review and Save review JSON
hand them back to the owner/chat. Regeneration preserves decisions for the same
revision through browser storage. A new revision uses a new decision namespace.

Round 01 requests M12, M15, M19, M20, H10, H11, H12, H33, S04, S07, S10, S18,
S19, S33 and S34. General ordinary foliage drafts use M35 (Folded cluster) as the
bushiness reference, with fuller and shorter leaf-bearing growth and varied leaf
profiles. Selected leaf replacements use recorded deterministic seeds and
width/taper/lobing/curl settings. S07 is exempt from leaf randomization: its leaf
shape, scale, material/pigment settings and specimen seed stay fixed while trunk,
branch, crown and root proportions change. Keeping the leaf design does not mean
keeping its old positions on the rebuilt scaffold.

These revisions use the existing shared procedural builders. No new biological
rules or plant population slots are introduced. Proposed definitions are detached
from approved species and disabled for world admission. The approved catalog,
project library and runtime palette stay unchanged until the owner selects new
baselines. Four unclassed catalog studies remain study-only; grass is outside
this bushier-foliage pass. The frozen roster retains them for review.

Regenerate revised pictures with the pinned Godot 4.7.2 engine:

```powershell
& $godot --path . --script tools/review_plant_closeups.gd --windowed --resolution 1000x900
python tools/build_plant_review.py
& $godot --headless --path . --script tests/plant_review.gd
```

`tools/plant_review_definition.gd` reconstructs draft recipes from stored source
recipes/dimensions and shared builders. It never uses a stale source bake as
new live artwork. Captures record the exact resolved settings/seed and registry
hash. The gallery builder rejects a registry changed since capture, so text and
pictures cannot silently describe different proposals. Roster entries must not
be renumbered when adding plants or changing catalog order. Keep prior revision
folders and exported owner reviews; change the registry revision for another
round. New baseline publication is a separate explicit owner visual selection.

Validation: the focused draft journey passed 294 checks with zero failures,
including deterministic rebuilds, preserved S07 leaf parameters, unique IDs,
valid detached definitions, finite/budgeted geometry and unchanged production
authority hashes. Rendered close-up acceptance remains the owner's decision.


### Round 02, notes and accepted baselines - October 31, 2026

The duplicated round-01 response is recorded once under
`docs/reference/plant_review_rounds/round-01-decisions.json`. Every note applies,
including notes attached to accept or keep-original. Round 02 revises M12, M15,
M19, H11, H12, H33, S10, S18 and S19. H12/S19 retain their original structural
seed and palette while leaf shape changes. H33 now has actual pinnate fronds.

The six unconditional acceptances are M20, H10, S04, S07, S33 and S34.
`resources/plants/reviewed_baselines/library.json` maps existing plant IDs to their
accepted definitions. The normal library uses the fingerprint-verified baked
palette first, with reviewed definitions supplying bake/reconstruction inputs.
Species identity, biome, circulation, dimensions and reserve ownership remain
in their existing slots. The three named catalog records carry their accepted
recipes. Exact resolved recipe/seed metadata accompanies the models. Generation
fingerprints include the reviewed manifest and definition contents.

The same gallery includes editable **Ongoing preferences and art direction**.
General preferences persist across rounds in browser storage and are included
in Copy review and Save review JSON; per-plant notes stay beside each plant.
Preferences are initially seeded by the tracked registry. Original and round-01
comparisons remain, along with an archived round-01 document. Browser draft
choices never automatically publish models. The Plant Maker exposes a Fern
fronds switch using the shared generic-foliage builder. Godot editor Inspector
regeneration is not implemented; editing recipe dictionaries alone does not
rebuild meshes. Editor-plugin migration was discussed, not implemented.

Validation: round-02 review passed 265 checks, species authoring passed 533, and
the settled palette bake wrote 153 definitions without failures. Live integration
passed 810 of 813 checks; three grass-root spacing assertions failed. An isolated
comparison using the saved before-change library produced identical grass
positions and the same three spacing violations. Close-ups were inspected.
The nine adjusted plants remain pending the owner's next visual selection.


### Round-02 approval - October 31, 2026

The owner accepted M12, M15, M19, H11, H12, H33, S10, S18 and S19 without further
changes, and reaffirmed the saved preferences. The response is recorded once in
`docs/reference/plant_review_rounds/round-02-decisions.json`. Together with the
six round-01 acceptances, all 15 selected plants now have approved generation
baselines. The existing reviewed-definition manifest records each plant's actual
approval round. The nine newly approved bodies use the exact captured settings
and seeds; the six earlier approvals are retained. Named species recipes are
updated within their existing identities and slots. The gallery labels the
approved models and preserves originals, both rounds, preferences and notes.

Approval metadata changes no longer require rendering the same proposal again:
the gallery verifies captures against their archived input registry. Geometry
and recipe changes still require a fresh capture. The preferences remain the
ongoing direction; approval does not authorize another randomization pass.


Approval validation: plant review passed 313 checks, species authoring passed
533, and live plant integration passed 812 with zero failures. All 15 approved
IDs reach the fingerprint-verified runtime palette and retain the correct
approval-round metadata. A concurrent shared-library update invalidated the first
bake; the subsequent 153-definition bake matches settled inputs. The earlier
three grass-spacing failures are resolved in the updated shared library; this
approval change preserves that concurrent work. Baselines apply when scenery is
rebuilt or the game is restarted.

### Crowded specialist visibility — October 31, 2026

The owner's invisible-regulator screenshot reproduces beside player cell
`(82, -14)`, seed `2601026`. The canonical regulator at `(81, -14)` could be
inspected even though clearance rejected its broad model. Specialist placement
now tries a compact, proportion-preserving version of the same selected design
inside its own cell after the normal size attempts fail. Terrain, slope,
reserved-space and footprint checks remain required. Render geometry, picking
and transformed Vastra anatomy use the same fitted body; membership and reserves
do not change. This does not retire regulator species or substitute legacy art.
Existing chunks need a restart/rebuild to show the fix, without deleting saves.

Focused verification: `tests/plant_live_integration.gd` passed 822 checks,
including the screenshot cell and `(89, -9)`, visible/pickable compact geometry,
contained bounds and matching organ endpoints. Runtime palette rebuilt: 153
definitions, zero bake failures.
