# Crown-Ear production sheet

Working name only. Species concept and Beast placement approved October 28, 2026;
batlike anatomy explicitly required. Status: connected runtime data and articulated
blockout model, procedural ground posing and bounded wild flight. New measurements, stats, moves
and implementation details are proposals.

See the [Sol Bible](../sol_bible.md#pilot-production-contract) for shared mechanics,
source evidence, unresolved owner questions, and acceptance requirements.

## Identity and roster

| Field | Specification |
| --- | --- |
| Stable runtime species ID | `sol_species_0001`; implemented in the shared catalog; independent of placeholder name and journal number |
| Stable runtime lineage ID | `sol_lineage_0001`; one lineage, not three candidates combined |
| Class | Beast; current runtime class ID `beast` |
| Ordinary stage | First of a proposed three-stage lineage; later forms not yet registered or counted |
| Size progression | Small → medium → large for a three-stage lineage, per owner direction |
| Journal number / starter role | Unassigned; selection for pilot testing is not selection as a storm rescuer |
| Individual affinity | Independently assigned and saved; no species-locked affinity |
| Species innate ability | None proposed for the pilot; retain the existing class passive rather than adding an unreviewed second bonus |
| Existing class passive | Terrain Resonance; use the current Beast definition and saved individual potency |

## Body, model, and scale

- **Approved defining idea:** a batlike creature whose broad folded ears open into
  a listening crown around its face. Preserve its readable face and attentive pose.
- **Proposed body plan:** two hind legs and two wing-bearing forelimbs, flexible
  neck, compact torso, short tail, paired independently movable ears. Grounded
  travel can use the forelimb wrists and hind feet; this needs visual testing.
- **First-form scale proposal:** about 0.35 m standing height and 0.9 m fully spread
  wingspan. These are draft art dimensions within the approved small category,
  not an owner-approved numeric scale. Compare with the player before locking them.
- **Gameplay footprint proposal:** one cell. Validate body and wing clearance;
  visual wingspan must not silently exempt the creature from obstacle checks.
- **Mass:** author after model scale; no unimplemented physics-mass control.
- **Materials:** matte soft body, firmer ear ribs, thin wing membranes. Species
  markings must remain distinguishable across all individual affinity effects.
- **Required rig controls:** root, body, neck/head, ear bases/rims, paired wing
  chains/tips, wrist contacts, hind-leg chains/feet, and tail.

## Movement and procedural locomotion

| Area | Draft specification |
| --- | --- |
| Modes | Grounded movement plus bounded low flight; owner explicitly approved bounded altitude, defined clearance and legal landing spots on October 28, 2026 |
| Ground posture | Low body, weight shared across wrists/hind feet; planted contacts follow committed travel |
| Air posture | Wingbeat and body pitch respond to actual speed; bank through turns; ears orient without steering gameplay position |
| Transitions | Ground rest → takeoff → air travel → legal landing → grounded rest; interrupted/blocked transitions need a defined safe state |
| Navigation | Use the bounded flight contract below; actual terrain/collision integration remains implementation work |
| Procedural controls | Stride, contact lift/planting, body lean, wingbeat cadence/amplitude, banking, ear damping, and transition blending; expose only connected settings |
| Boundaries | No automatic immunity, obstacle bypass, mounted travel, or free combat movement follows from batlike anatomy |

Swimming is not part of this species' proposed pilot movement. Inaccessible
terrain must produce a legal wait/return decision, not a visual teleport.

## Behavior, ecology, and companionship

| Field | Draft specification |
| --- | --- |
| Temperament | Avoidant, with individual variation; cautious observation can coexist with familiar companionship |
| Runtime behavior branches | `patrol`, `idle`, `flee`; idle listening is a species animation/behavior specialization, not a fourth response |
| Three readable patterns | Quiet patrol; still listening-crown observation; cautious withdrawal when crowded |
| Signature gesture | Tilts the whole crown toward a sound, then looks back toward its companion |
| Rest | Ears partly folded, wings tucked; preserve visible breathing |
| Companion moment | Waits at a nearby legal perch/standing point, listening and checking back before resuming travel |
| Proposed habitat | Sheltered woodland edges with accessible ground resting places; perches must be actual reachable geometry |
| Ecology | Searches leaf litter and replaces disturbed cover; this is presentation/lore, without automatic terrain restoration |
| Encounter placement | Representative expedition woodland segment; proposed level 3–5; use explicit test placements before ambient weighting |
| Hostility / capture | Preserve existing encounter and capture authority. Avoidant behavior does not establish a new capture formula or guaranteed peaceful invitation |
| Social style | Solitary or loosely spaced as art direction; group simulation is not added by this sheet |

Behavior distance/timing overrides initially inherit connected global settings.
Tune species-specific values after actual scale and movement feel are established.
Do not create a full numerical tuning surface before its behavior is implemented.

## Combat and learnset

Owner-approved starting role: fast and disruptive (October 28, 2026).
Physical emphasis and numerical values remain provisional. The following is a reversible starting
profile at **level 3, 100% natural potential, zero training**; individual rolls and
the existing growth system apply separately. Speed changes initiative, not the
movement-point allowance.

| HP | Attack | Defense | Special Attack | Special Defense | Speed |
| --- | --- | --- | --- | --- | --- |
| 42 | 18 | 14 | 16 | 14 | 24 |

Strength: acts early and can reduce enemy Defense or shape terrain. Tradeoff:
lower durability; aerial presentation alone does not change target eligibility.
Use current prototype growth (+2 HP and +1 to each other stat per level) for initial
comparison; this is inherited tuning, not a new growth formula.

| Existing move ID | Display / assigned affinity | Draft learning condition | Purpose |
| --- | --- | --- | --- |
| `strike` | Strike / Earth | Initially learned and equipped | Physical baseline attack |
| `wind` | Crosswind / Air | Initially learned and equipped | Shared battlefield condition |
| `rattle` | Rattle / Spectral | Initially learned and equipped | Existing Defense reduction |
| `ward` | Ward / Spectral | Initially learned and equipped | Existing protection effect |
| `arc_bolt` | Arc Bolt / Lightning | Level 4 | Ranged special option |
| `focus` | Focus / Quantum | Level 8 | Existing Special Attack buff |
| `anchor` | Stable Footing / Earth | Level 14 | Existing footing option |

This seven-move pool is an explicit proposal independent of individual affinity.
Reuse existing effect/range/power/duration definitions without renaming their IDs
or inventing additional effects. Four moves start equipped; later learning retains
the four-slot limit. Signature species moves can follow after the pilot is tested.

## Ordinary evolution outline

1. **Small:** compact batlike first form with folded listening ears.
2. **Medium:** stronger torso and a structured sensory crown; keep the face,
   forelimb/wing arrangement, and listening pause recognizable.
3. **Large:** broad sensory mantle and substantial wing silhouette; retain the
   careful ground posture and companion check-back gesture.

Later-form names, IDs, dimensions, stat baselines, and triggers are not authored
yet. Three-stage size direction is approved; the detailed growth design remains a
proposal. Preserve individual ID, affinity, potential, training, class potency,
and remembered/equipped moves through authored evolution. No legendary form is
assigned by this ordinary outline.

## Asset and integration work

- Model/scene, material, rig, sounds, and resource paths: not created. No existing
  prototype species ID or saved individual is reassigned to this design.
- Essential clips/poses: rest, listening, takeoff, landing, attack, hit, recovery,
  and one check-back gesture. Blend procedural ground/air locomotion around them.
- Sound brief: soft wing membrane motion, distinct quiet listening/vocal cue,
  contact sounds, and attack/hit cues; no final sound assets selected.
- Field Guide draft: "It listens with its entire crown. When it trusts a traveler,
  it checks that they heard what it heard." Lore text remains editable.
- Encounter, combat, owned follow behavior, and model preview must reference the
  same species record; model bounds need folded and spread-wing review.
- Acceptance: check foot planting, clearance, takeoff/landing, corners, listening
  while stationary, interrupted travel, combat entry, hidden previews, pause, and
  save/load. Actual rendered evidence is not yet available.

## Bounded flight contract

The owner explicitly approved low flight with bounded altitude, defined obstacle
clearance and legal landing spots on October 28, 2026. Wild flight is now
implemented as recorded in the step-four section. Keep travel bounded to active, validated terrain
and a species habitat/home region using the existing bounded navigation approach.

- **Altitude proposal:** normal low-flight body clearance of 0.5–1.5 world units
  above the relevant terrain/water surface. Expose connected tuning when implemented;
  this is not a fixed flight speed, combat range, or approved balance constant.
- **Route legality:** validate the swept body/wing clearance against actual
  collision geometry and actor occupancy. Flight may cross water or low obstacles
  only when the air corridor is genuinely clear; walls, roofs, and tree geometry
  do not become passable because the destination cell is nearby.
- **Takeoff/landing:** launch from a legal supported ground position. Land only on
  open, dry, supported terrain with sufficient footprint and body clearance.
  Check the transition as well as its endpoint. Do not land in water or on another
  actor. If landing is unavailable, retain a legal air state and seek a reachable
  landing; bounded failure returns a safe wait instead of teleporting.
- **World ownership:** authoritative movement-mode/position state controls legal
  travel. Animation banking, wingbeats, ears, and foot placement follow it. No
  physics-driven displacement is added by the pose solver.
- **Encounters/combat:** preserve existing legal-arena and encounter admission
  checks. If the existing battle domain cannot admit the current situation, do
  not force an invalid battle or teleport to fabricate one. The pilot keeps the
  existing tactical movement/targeting rules; aerial poses alone add no immunity,
  additional movement points, or ability to bypass cover.
- **Persistence/lifecycle:** save the authoritative mode and enough admitted
  position/transition state for a legal reconstruction. Restore only after
  validation, without rerolling identity/affinity. Pause, culling, and preview
  creation must not advance movement; clear transient pose state on replacement.

Exact steering, contact sampling, search limits, and collision adapters will be
implemented and verified against Godot's terrain contracts. Remain within the
existing bounded simulation budget; this is low flight, not a new unlimited
vertical world, player flight system, or mounting mechanic.

## Remaining production work

No owner answer is required to continue the working specification. Numeric scale,
stat/move balance, rig contacts, and procedural coefficients remain reversible
implementation tuning. Create/test the assets and movement adapters in later
steps; concept approval does not certify a finished model or playable flight.

## Step-one handoff

Working production specification completed October 28, 2026 under the owner's
proceed/continue direction. Optional role/flight questions are resolved using the
documented recommended defaults. The verified baseline covers the current
expedition, not this unimplemented species. Numerical tuning remains reversible;
models, runtime resources, procedural locomotion, and connected acceptance are
implementation work in subsequent steps.

## Step-two data integration

The runtime definition is [Crown Ear](../../../resources/sol_species/crown_ear.tres)
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

## Step-four flight

The runtime Traversal profile now admits wild flight independently of affinity.
Takeoff, air travel and legal landing follow bounded navigation and actual scenery
clearance. Wingbeats, elbow/wrist membrane articulation, tucked legs and banking
follow saved mode/clock rather than driving the actor. Blocked landings wait or
seek another legal landing; manual encounter approach requests a return to land.
The earlier pending-flight notes are historical requirements. See
[flight/swimming implementation](../../sol-flight-and-swimming.md) for current
scope, including the retained ground contracts for tactical combat and owned follow.

## Early combat alternatives — October 28, 2026

Owner-approved low-tier prototype additions: `quick_fang`, `battle_cry`, `grit_guard`.
These are additional eligible and initially remembered options; the original four
equipped moves remain the default. Four slots remain the equipment limit.
Individual affinity stays independent. This extends the playable learnset,
not final species, evolution, or balance approval. See the
[early move design and limits](../../early-combat-moves.md).
