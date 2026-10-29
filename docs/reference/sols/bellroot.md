# Bellroot production sheet

Working name only. Species concept and Bloom placement approved October 28, 2026.
Status: connected runtime data, articulated blockout model and procedural ground
posing. Measurements, stats, moves and implementation details below are proposals.

See the [Sol Bible](../sol_bible.md#pilot-production-contract) for shared mechanics,
source evidence, unanswered questions, and acceptance requirements.

## Identity and roster

| Field | Specification |
| --- | --- |
| Stable runtime species ID | `sol_species_0003`; implemented in the shared catalog; independent of placeholder display name and journal number |
| Stable runtime lineage ID | `sol_lineage_0003` |
| Class | Bloom; current runtime class ID `verdant` |
| Ordinary stage | First of a proposed three-stage lineage; later species not registered or counted |
| Size progression | Small → medium → large for a three-stage lineage, per owner direction |
| Journal number / starter role | Unassigned; pilot selection is not a storm-rescuer assignment |
| Individual affinity | Independently assigned and saved; botanical anatomy is not an affinity restriction |
| Species innate ability | None proposed for the pilot; no unapproved second passive layered onto class behavior |
| Existing class passive | Rooted Renewal; retain current `verdant` effect, limits, and saved individual potency |

## Body, model, and scale

- **Approved defining idea:** a low bell-shaped living bulb on four thick root
  feet, with broad leaves hanging around its body. The creature is botanical.
- **Proposed anatomy:** flexible central stem/body support, small low face, four
  articulated root limbs, paired leaf layers forming a closable canopy. No human
  hands, fabricated pot, or carried plant is needed for its silhouette.
- **First-form scale proposal:** about 0.45 m tall with a 0.5 m canopy width;
  draft dimensions within the approved small category, not fixed numeric canon.
- **Footprint proposal:** one cell; validate root-foot reach and the closed/open
  canopy against real body clearance.
- **Mass:** author after proxy review; no unused physics-mass setting.
- **Materials:** substantial bulb/stem tissue, readable roots, and layered leaves;
  species markings remain readable under every individual affinity presentation.
- **Required rig controls:** root/body compression, head/face orientation, four
  root-limb chains/contact points, leaf bases, and secondary canopy joints.

## Movement and procedural locomotion

| Area | Draft specification |
| --- | --- |
| Modes | Ground travel only in the pilot; water and inaccessible terrain remain subject to authoritative traversal |
| Gait | Alternating root-foot steps with visible planting and restrained body compression; gait pattern is a visual-tuning proposal |
| Terrain response | Ground-contact sampling adapts roots and posture within the legal simulation footprint |
| Secondary motion | Leaves lag starts/turns, then settle with damping; closed-leaf rest remains an intentional authored pose |
| Transitions | Rest/unfold → grounded travel → stop/settle → rest; blocked travel must not keep stepping indefinitely |
| Procedural controls | Root spacing/reach, stride/cadence, lift/plant timing, body compression/lean, leaf damping, and rest blending |
| Boundaries | Tending does not modify terrain, grant rooting immunity, produce food, or create mandatory player upkeep |

Root feet conform visually to the terrain beneath committed travel. They do not
move the authoritative body, create extra reachable cells, or turn impassable
ground into valid navigation. Stop, pause, load, and combat transitions need safe
pose resets/blending without random jitter.

## Behavior, ecology, and companionship

| Field | Draft specification |
| --- | --- |
| Temperament | Neutral with stable individual variation |
| Runtime behavior branches | `patrol`, `idle`, `approach`; tending and leaf-closing rest specialize idle rather than adding multiple response primitives |
| Three readable patterns | Deliberate patrol; inspect/tend or close leaves during idle; cautious approach followed by a comfortable stop |
| Signature gesture | Carefully disentangles a bent stem before continuing; initially an animation/lore interaction |
| Rest | Folds leaf crown around itself while maintaining readable orientation and breathing-like plant motion |
| Companion moment | Pauses to inspect a plant, then catches up using a legal route; interruption must not strand the selected companion |
| Proposed habitat | Sheltered ground beside existing woodland/grassland vegetation and accessible paths |
| Ecology | Tends undergrowth through ordinary behavior; actual growth, restoration, resource creation, and ecological state changes are deferred |
| Encounter placement | Representative expedition woodland/path segment; proposed level 3–5; explicit test placement before weighted ambient admission |
| Hostility / capture | Preserve encounter, warning, capture, and holding-authority rules; a neutral approach is not automatic affection or acquisition |
| Social style | Solitary/loosely spaced visual direction; no new grouping system |

Initial timing and response distances inherit connected global tuning. Its gait
can feel deliberate without arbitrarily reducing combat movement or overriding
world movement cadence before balancing evidence exists.

## Combat and learnset

Owner-approved starting role: support and battlefield control (October 28, 2026).
Special-stat emphasis and numerical tuning remain provisional.
Draft profile at **level 3, 100% natural potential, zero training**:

| HP | Attack | Defense | Special Attack | Special Defense | Speed |
| --- | --- | --- | --- | --- | --- |
| 44 | 12 | 18 | 22 | 24 | 12 |

Strength: special resilience, healing, and battlefield options. Tradeoff: weak
physical offense and late initiative. Use current prototype growth (+2 HP and +1
to each other stat per level) for initial comparison. A high Special Attack stat
does not turn healing into damage or add an effect to physical Vine Whip; any
offensive special option must be explicitly learned/equipped.

| Existing move ID | Display / assigned affinity | Draft learning condition | Purpose |
| --- | --- | --- | --- |
| `vine_whip` | Vine Whip / Earth | Initially learned and equipped | Existing physical baseline attack |
| `barrier` | Raised Ground / Earth | Initially learned and equipped | Existing shared terrain condition |
| `mend` | Renewing Current / Water | Initially learned and equipped | Existing healing option |
| `wind` | Crosswind / Air | Initially learned and equipped | Existing battlefield condition |
| `arc_bolt` | Arc Bolt / Lightning | Level 4 | Existing special damage option |
| `ward` | Ward / Spectral | Level 8 | Existing protection effect |
| `focus` | Focus / Quantum | Level 14 | Existing Special Attack buff |

This explicit pool is a reversible pilot proposal; anatomy alone does not grant
spore poison, new plant attacks, or affinity-locked learning. Reuse actual move
definitions, four-slot equipment, and remembered-move continuity. Do not infer
additional power from a descriptive animation or species ecology.

## Ordinary evolution outline

1. **Small:** a walking bulb, four root feet, broad hanging leaves, and a low face.
2. **Medium:** a longer central stem and arching leaf frame; preserve deliberate
   stepping, canopy-closing rest, and the low recognizable face.
3. **Large:** a broad bell-shaped canopy supported by substantial root limbs;
   retain the tending gestures and layered botanical body.

Detailed later-form identities, measurements, stat profiles, and evolution
conditions remain unassigned. Apply the approved three-stage size direction and
existing identity/affinity/potential/training/move continuity. No ordinary stage
is silently classified as legendary or counted as a new candidate by this outline.

## Asset and integration work

- Model/scene, rig, textures, sounds, and species model assets: not created; runtime data is now connected. Existing
  Seedmote content remains separate and is not renamed into Bellroot.
- Essential clips/poses: open/closed rest, tending, comfortable approach stop,
  attack, hit, recovery, and a catch-up/check-back gesture. Blend procedural root
  stepping and canopy motion around these actions.
- Sound brief: soft root contacts, leaf rustle, a short low vocal/creak identity,
  and clear combat cues; assets remain open.
- Field Guide draft: "It takes its time with tangled growth. When it catches up
  to a traveler, its leaves are often carrying something the path left behind."
  Text remains editable and grants no item collection mechanic.
- Shared model selection needs both closed and open canopy bounds in exploration,
  combat, and the isolated menu preview.
- Acceptance: root contact on slopes, turns, blocked travel, canopy clipping,
  tending interruption, companion catch-up, combat, pause, hidden preview, and
  save/load. No rendered pilot validation exists yet.

## Remaining decisions

The role split is explicitly approved as the starting design. Exact dimensions
remain provisional within the small-first-stage rule. Later stage details, model
assets, animations, and species-specific interactions require production work and
visual review. Root-foot pose adaptation must preserve legal committed body
position and existing encounter/combat admission rules.

## Step-one handoff

Working production specification completed October 28, 2026 under the owner's
proceed/continue direction. Optional role/flight questions are resolved using the
documented recommended defaults. The verified baseline covers the current
expedition, not this unimplemented species. Numerical tuning remains reversible;
models, runtime resources, procedural locomotion, and connected acceptance are
implementation work in subsequent steps.

## Step-two data integration

The runtime definition is [Bellroot](../../../resources/sol_species/bellroot.tres)
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

## Early combat alternatives — October 28, 2026

Owner-approved low-tier prototype additions: `seed_dart`, `sprout_mend`, `stillwater`.
These are additional eligible and initially remembered options; the original four
equipped moves remain the default. Four slots remain the equipment limit.
Individual affinity stays independent. This extends the playable learnset,
not final species, evolution, or balance approval. See the
[early move design and limits](../../early-combat-moves.md).
