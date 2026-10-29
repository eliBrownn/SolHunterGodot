# Ashquill first-form blockout

Owner decision, October 28, 2026: **direction B selected**, with the explicit
clarification that this is a **small, cute first-stage model**. The initial
silhouette board looks closer to mature-stage art; it does not approve those
proportions for this form or establish a final-stage design.

Current implementation: Upright downy bird with a proportionally larger head/eyes, small beak, rounded breast, soft crest and shorter arched tail. Two real support chains; wings and tail remain appendages.

Open [Ashquill workshop](../../../scenes/ashquill_workshop.tscn) with F6.
The authored [model scene](../../../scenes/sols/ashquill.tscn) uses
[its distinct builder](../../../scripts/sol_ashquill.gd). Original repository-authored
primitive geometry; no third-party model source. Art scale is provisionally 0.65,
not a final height or balance value. Inherited scale, idle strength/rate, action
duration, step distance/lift and turn response are adjustable; see the
[Inspector map](../../inspector-tuning.md#new-first-form-workshop-models).
Scene edits apply after restarting/rebuilding the workshop; no saved identity is
created. G cues signature, J attack, H hit, followed by recovery. M cycles routes.
Flight/swimming exercises do not grant these species traversal permissions.

The A/B descriptions below retain the review history. B is selected; model finish,
later forms, family count and final balance remain undecided. The owner requested
applying the creatures; this first form now has a connected gameplay record.

## Playable first-form integration

The [runtime record](../../../resources/sol_species/ashquill.tres) and shared catalog
use stable species ID `sol_species_0004` and lineage ID `sol_lineage_0004`, ordinary form 1,
footprint 1. Normal F5 play admits one authored sighting near trail x=22, with
Water affinity on that individual. Affinity does not come from its class.
The species uses its small 0.65-scale B model for exploration, battle, following
and party-menu previews. It has ground movement only; no inferred air/water mode.
Traversal clearance is conservatively 0.7 m radius and 0.6 m height.

Provisional reference profile at level 3, 100% natural potential, no training:

| HP | Attack | Defense | Special Attack | Special Defense | Speed |
| --- | --- | --- | --- | --- | --- |
| 40 | 14 | 12 | 20 | 16 | 22 |

Eligible existing moves: `strike`, `heat`, `wind`, `ward`, `focus`, `arc_bolt`, `rattle`.
The first four start equipped. This is editable playtest tuning, not final balance
or a new class/affinity rule. The existing class passive is reused unchanged.
The resource retains the existing provisional three-slot training-capacity
parameter; it does not register later forms, fix the final family count or author
evolution triggers. Resolve the family before later-form production.

Wild behavior reuses patrol/idle/flee; the companion's inherited
`ashquill_preens` idle branch cues the existing signature animation. This adds
no trust reward, weather detection or ecological world change. The trail placement
is for current play, not a claim that final habitat distribution is implemented.
Stat/move definitions apply at admission and saved traits persist. Existing
current-format expeditions gain the explicit sighting on load, through the existing
admission path. Rebuild/restart views for scene edits; keep final dimensions open.

Working name. CinderKin concept approved October 28, 2026; B selected and adapted
to the owner's small/cute first-form direction. See the [approved concept](../sol_bible.md#ashquill--cinderkin)
and [shared silhouette review](../../sol-creature-anatomy-review.md).

## Identity and family

| Field | Current specification |
| --- | --- |
| Approval scope | Small long-tailed bird, charcoal-textured layered feathers, soft crest, grooming and nesting direction; not a completed production model |
| Primary class | CinderKin; individual affinity remains independent |
| Species / lineage ID | `sol_species_0004` / `sol_lineage_0004`; unique keys checked before admission |
| Family / form count | Undecided; approved broad downy → crested → phoenixlike direction does not allocate three roster entries |
| Size progression | Small, cute first stage confirmed; three total forms would require small → medium → large; family count remains undecided |
| Exact size, later forms, evolution conditions | Undecided; neither board scale nor tail length establishes numeric canon |

## Review alternatives — B selected

**A — low bird with trailing tail (not selected).** An oval downy body leans forward
over two short, bent bird legs. A small beaked head sits ahead of the shoulders;
folded wings lie against the torso. Long overlapping tail feathers trail behind
with a slight droop. The crest is soft rather than a flame-shaped hard spike.
The low forward body and long rear counterweight remain clear as a black shape.
Signature pose: fluff the body into a rounder mass, turn the head and smooth one
wing while the long tail remains identifiable.

**B — upright bird with arched tail.** A deeper pear-shaped chest sits above two
longer jointed legs. A small head and swept soft crest top the front; long layered
tail feathers arch up and back without becoming a fan or an extra limb.
Signature pose: lower into a puffed resting posture and carefully smooth the
breast feathers. This tests a more watchful vertical silhouette, with extra risk
of resembling an ordinary ornamental bird at a distance.

Both preserve avian anatomy. CinderKin reads through the approved phoenix-inspired
body and charcoal/ash feather structure; detailed ash-born origin remains open.
Neither requires flames, Fire affinity, resurrection or admitted flight.

## Proposed materials, habitat and routine

Use matte charcoal feather surfaces with pale worn-looking edges and softer down
at the throat; exact colors remain art tuning. Distinguish feather layers by
geometry and restrained value breaks, with separate individual-affinity effects.
Proposed habitat: sheltered dry nesting pockets near exposed ground; actual biome
admission is undecided. Preserve the approved routine of fluffing, smoothing and
collecting shed down. Companion moment: inspect the ground beside a resting
traveler, fuss over it, then settle. This is an animation proposal without nest
resources, ecological modification or a new relationship system.

## Combat presentation and model plan

Combat role is undecided. A proposed presentation emphasis is quick peck/wing
feint accents, without assigning stats, moves, displacement or new effects.
The signature action remains grooming, separate from attack presentation.
Gameplay specification requires source reconciliation before authoring rules.

For either direction, use two registered leg support chains, separate head,
wing and tail controls. Tail feathers are appendages, not support contacts.
Workshop poses must include planted rest, crest-raised alert, alternating ground
steps, inside-foot turns with tail follow-through, grooming, attack accent,
compressed hit and return to rest. Verify tail sweep, crouch and wing opening in
the preview bounds and clearance envelope. Flight capability remains undecided.
The current blockout supplies those controls and poses. Final scale, finished art
and target-device performance remain unaccepted.

Status: approved concept and B selection; small first-form blockout integrated
through the shared catalog and normal game. Finished-art/model acceptance remains
open. See the [integration evidence](../../sol-creature-anatomy-review.md#applied-to-the-normal-game).

## Early combat alternatives — October 28, 2026

Owner-approved low-tier prototype additions: `ember_dart`, `smoulder`, `battle_cry`.
These are additional eligible and initially remembered options; the original four
equipped moves remain the default. Four slots remain the equipment limit.
Individual affinity stays independent. This extends the playable learnset,
not final species, evolution, or balance approval. See the
[early move design and limits](../../early-combat-moves.md).
