# Reedback production sheet

Working name only. Species concept and Abyssal placement approved October 28, 2026.
Status: connected runtime data, articulated blockout model and procedural ground
posing, supported wading and wild surface swimming. Measurements, stats, moves and implementation details below are proposals.

See the [Sol Bible](../sol_bible.md#pilot-production-contract) for shared mechanics,
source evidence, unresolved questions, and acceptance requirements.

## Identity and roster

| Field | Specification |
| --- | --- |
| Stable runtime species ID | `sol_species_0002`; implemented in the shared catalog; separate from display name and journal number |
| Stable runtime lineage ID | `sol_lineage_0002` |
| Class | Abyssal; current runtime class ID `tideborn` |
| Ordinary stage | First of a proposed three-stage lineage; later species not registered or counted |
| Size progression | Small → medium → large for a three-stage lineage, per owner direction |
| Journal number / starter role | Unassigned; pilot selection is not a storm-rescuer assignment |
| Individual affinity | Independently assigned and saved; amphibious anatomy does not require Water affinity |
| Species innate ability | None proposed for the pilot; keep class and species abilities distinct |
| Existing class passive | Undertow; retain the current `tideborn` definition and saved individual potency |

## Body, model, and scale

- **Approved defining idea:** a squat amphibious quadruped with overlapping back
  plates, broad feet, and sparse reeds rooted in damp sediment between the plates.
- **Proposed anatomy:** four short weight-bearing limbs, broad webbed feet,
  compact neck, a muscular steering tail, and raised nostrils supporting a surface
  swimming silhouette. New anatomical details remain reviewable.
- **First-form scale proposal:** 0.6 m high and about 0.9 m long, within the small
  category. Numeric dimensions are art-tuning proposals, not accepted measurements.
- **Footprint proposal:** one cell; verify the tail, plate display, and turning
  sweep against actual body clearance before implementation.
- **Mass:** author after proxy scale review; do not add unused physics controls.
- **Materials:** substantial plate surfaces, softer joints, muted wet skin, and
  sparse flexible reeds. Reeds alone do not make this a Bloom species.
- **Required rig controls:** root/body, neck/head, four limb chains/contact feet,
  tail chain, plate-display pivots, and secondary reed controls.

## Movement and procedural locomotion

| Area | Draft specification |
| --- | --- |
| Modes | Ground travel and surface swimming, with explicit shoreline entry/exit |
| Ground posture | Low body, alternating planted feet, restrained body roll; visible weight shifts before turns |
| Swim posture | Body supported at the surface, coordinated limb strokes, steering tail, damped plate/reed motion |
| Transition | Approach legal water edge → enter swim state → swim → exit at a valid bank → grounded travel |
| Navigation | Reuse actual Godot ground/water information; define water occupancy, shore eligibility, and mode persistence before coding |
| Procedural controls | Foot spacing, stride, step lift, body lean/height response, stroke cadence, tail movement, plate/reed damping, shoreline blending |
| Boundaries | Diving, underwater encounters, water immunity, player transport, and new terrain generation are not specified by this pilot |

Surface swimming is a proposed minimum interpretation of swimming scope, not a
claim that underwater travel is approved. Blocked banks must produce a safe wait
or alternate legal route. Water-state combat admission still needs a decision
grounded in the existing encounter/battle contracts.

## Behavior, ecology, and companionship

| Field | Draft specification |
| --- | --- |
| Temperament | Neutral, with individual variation; defense display is not automatic hostility |
| Runtime behavior branches | `patrol`, `idle`, `guard`; guard is an existing neutral-compatible response, not a new encounter trigger |
| Three readable patterns | Short bank/water-edge patrol; plate/reed grooming during idle; planted plate-raising display when crowded |
| Signature gesture | Carefully combs growth from one plate with a foot, then lowers the plate |
| Rest | Body settles into a stable low pose; reeds and breathing remain restrained |
| Companion moment | Pauses at the bank, looks back, and resumes only along its own legal route; no expectation that the player can follow through water |
| Proposed habitat | Existing ponds, soft banks, and wetland edges where shore transitions are validated |
| Ecology | Carries wetland seeds in back sediment and reuses muddy resting hollows; initially visual/lore, without seed propagation or erosion simulation |
| Encounter placement | Representative expedition pond/bank segment; proposed level 3–5; explicit test placements before ambient weighting |
| Hostility / capture | Keep existing encounter, warning, and capture authority; species behavior must not silently change the hostile flag or Seal rules |
| Social style | Solitary or loosely spaced resting neighbors as visual direction; new social simulation is outside this sheet |

Initial detection/comfort/timing values inherit connected global settings. Make
new species overrides only after scale and shoreline behavior can be observed.

## Combat and learnset

Owner-approved starting role: durable and physical (October 28, 2026).
Defensive emphasis and numerical tuning remain provisional. Draft profile at **level 3, 100% natural potential, zero training**:

| HP | Attack | Defense | Special Attack | Special Defense | Speed |
| --- | --- | --- | --- | --- | --- |
| 54 | 22 | 24 | 14 | 20 | 10 |

Strength: physical durability and a useful basic attack. Tradeoff: late initiative
and limited special offense. Physical scale and swimming do not automatically
grant increased movement points or extra resistance. Initially inherit current
prototype growth (+2 HP and +1 to other stats per level) for comparison.

| Existing move ID | Display / assigned affinity | Draft learning condition | Purpose |
| --- | --- | --- | --- |
| `fin_strike` | Fin Strike / Water | Initially learned and equipped | Physical baseline attack |
| `current` | Current / Water | Initially learned and equipped | Shared battlefield condition |
| `ward` | Ward / Spectral | Initially learned and equipped | Existing protection effect |
| `anchor` | Stable Footing / Earth | Initially learned and equipped | Existing footing option |
| `mend` | Renewing Current / Water | Level 4 | Existing healing option |
| `barrier` | Raised Ground / Earth | Level 8 | Existing terrain condition |
| `rattle` | Rattle / Spectral | Level 14 | Existing Defense reduction |

Eligibility is an explicit species pool, independent of the individual's affinity.
Reuse current move effects and tuning; no permanent species water field or passive
healing is inferred. Four start equipped; later moves remain subject to existing
learning and equipment rules.

## Ordinary evolution outline

1. **Small:** a squat amphibious body with a few shallow plates and sparse reeds.
2. **Medium:** larger overlapping plates, clearer swimming tail, and a substantial
   back-growth silhouette; preserve face, broad feet, and grooming.
3. **Large:** a moving patch of wetland supported by a powerful amphibious body;
   retain the plate display, low gait, and visible animal face.

Later-form identities, measurements, stat baselines, and evolution conditions are
not assigned yet. The three-stage size rule is approved; details remain proposals.
Use the existing identity/affinity/potential/training/move continuity contracts
for authored evolution. No new species or legendary manifestation is counted by
this outline alone.

## Asset and integration work

- Model/scene, rig, textures, sounds, and species model assets: not created; runtime data is now connected. Preserve
  all existing prototype individuals and IDs.
- Essential clips/poses: ground rest, floating rest, grooming, plate display,
  water entry/exit, attack, hit, and recovery; procedural locomotion supplies
  continuous ground/swim travel.
- Sound brief: soft footfalls, plate movement, water entry/strokes, quiet reed
  movement, and a short species vocalization; final assets remain open.
- Field Guide draft: "It tends the wet growth between its plates with remarkable
  care. A raised back is a warning to give it room." Text remains editable.
- Shared model selection must work on land, at the water surface, in combat, and
  in a menu preview. Waterline and plate-display bounds require visual checks.
- Acceptance: shore approach/reversal, legal entry/exit, unavailable exit banks,
  body clearance, planted feet, floating pose, companion return, encounter entry,
  pause, and save/load. No rendered pilot evidence exists yet.

## Remaining decisions

The role split is explicitly approved as the starting design. Surface-swimming
scope follows the earlier proceed direction. First-form dimensions remain provisional within the small-first-stage
rule. Implement shoreline travel only where the actual terrain traversal/clearance
contract permits entry and exit. Preserve legal-arena and encounter admission
checks; do not force an invalid battle or teleport to a fabricated bank. Persist
and validate ground/swim state across load and transitions. Diving, player riding,
and swimming-based immunity are outside this specification. Actual rig, collision,
and movement adapter validation remain later implementation work.

## Step-one handoff

Working production specification completed October 28, 2026 under the owner's
proceed/continue direction. Optional role/flight questions are resolved using the
documented recommended defaults. The verified baseline covers the current
expedition, not this unimplemented species. Numerical tuning remains reversible;
models, runtime resources, procedural locomotion, and connected acceptance are
implementation work in subsequent steps.

## Step-two data integration

The runtime definition is [Reedback](../../../resources/sol_species/reedback.tres)
in the shared [catalog](../../../resources/sol_species/catalog.tres). Taxonomy,
level-3 stats, lineage capacity, explicit eligible/starting moves, ecology default,
and orb presentation routing are connected through that record. This species can
be encountered, battled, captured, selected, previewed, and saved in the isolated
[pilot scene](../../../scenes/sol_species_pilot.tscn). Existing saved individuals
retain their own affinity, reference stats, natural potential and movebooks.

This is data integration. Species-specific models, rigs, procedural locomotion,
actual flight/swimming, final evolution forms and their assets remain future
steps. The initial numeric profiles and move selection are adjustable pilot tuning.
See [integration details](../../sol-species-data.md) and the Bible's validation
record for evidence and limitations.

## Step-three model and rig

The species resource now selects its own scene under `scenes/sols/`, built from
original primitive 3D geometry with named articulated control pivots. Exploration,
combat and menu previews share it. Breathing, rest/alert posture, the signature
rest gesture and battle attack/hit recovery are generated visual poses. Model
size, silhouette, palette and timing remain reviewable art proposals.

The earlier step-one/two asset status above is historical. Four foot/contact
markers and the body-specific appendage chains are ready for the movement step;
rig availability does not establish foot planting, legal flight or swimming.
See [model documentation](../../sol-creature-models.md) and the
[Bible validation record](../sol_bible.md#step-three-creature-models-and-essential-poses).

## Step-four swimming

The runtime Traversal profile now admits wild wading and surface swimming
independently of affinity. Actual pond depths and bank heights control supported
entry/exit and the waterline; limb strokes and the steering tail follow saved
mode/clock. Blocked banks do not cause teleportation. The dedicated pond pilot
selects a real generated dry bank, while the original pilot retains its trail
home. The earlier pending-swimming notes are historical requirements. See
[flight/swimming implementation](../../sol-flight-and-swimming.md) for current
scope, including the retained ground contracts for tactical combat and owned follow.

## Early combat alternatives — October 28, 2026

Owner-approved low-tier prototype additions: `splash_jet`, `soothing_guard`, `stillwater`.
These are additional eligible and initially remembered options; the original four
equipped moves remain the default. Four slots remain the equipment limit.
Individual affinity stays independent. This extends the playable learnset,
not final species, evolution, or balance approval. See the
[early move design and limits](../../early-combat-moves.md).
