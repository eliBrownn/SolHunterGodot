# Rattlehorn first-form blockout

Owner decision, October 28, 2026: **direction B selected**, with the explicit
clarification that this is a **small, cute first-stage model**. The initial
silhouette board looks closer to mature-stage art; it does not approve those
proportions for this form or establish a final-stage design.

Current implementation: Higher chest and narrow four-foot stance retained, with rounder juvenile proportions, larger face/eyes, two tiny rings per horn and a short filament mane. Three supports stay planted while the forefoot tests the ground.

Open [Rattlehorn workshop](../../../scenes/rattlehorn_workshop.tscn) with F6.
The authored [model scene](../../../scenes/sols/rattlehorn.tscn) uses
[its distinct builder](../../../scripts/sol_rattlehorn.gd). Original repository-authored
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

The [runtime record](../../../resources/sol_species/rattlehorn.tres) and shared catalog
use stable species ID `sol_species_0005` and lineage ID `sol_lineage_0005`, ordinary form 1,
footprint 1. Normal F5 play admits one authored sighting near trail x=40, with
Earth affinity on that individual. Affinity does not come from its class.
The species uses its small 0.65-scale B model for exploration, battle, following
and party-menu previews. It has ground movement only; no inferred air/water mode.
Traversal clearance is conservatively 0.5 m radius and 0.75 m height.

Provisional reference profile at level 3, 100% natural potential, no training:

| HP | Attack | Defense | Special Attack | Special Defense | Speed |
| --- | --- | --- | --- | --- | --- |
| 46 | 20 | 18 | 16 | 16 | 18 |

Eligible existing moves: `strike`, `charge`, `anchor`, `rattle`, `ward`, `arc_bolt`, `focus`.
The first four start equipped. This is editable playtest tuning, not final balance
or a new class/affinity rule. The existing class passive is reused unchanged.
The resource retains the existing provisional three-slot training-capacity
parameter; it does not register later forms, fix the final family count or author
evolution triggers. Resolve the family before later-form production.

Wild behavior reuses patrol/idle/guard; the companion's inherited
`rattlehorn_footing` idle branch cues the existing signature animation. This adds
no trust reward, weather detection or ecological world change. The trail placement
is for current play, not a claim that final habitat distribution is implemented.
Stat/move definitions apply at admission and saved traits persist. Existing
current-format expeditions gain the explicit sighting on load, through the existing
admission path. Rebuild/restart views for scene edits; keep final dimensions open.

Working name. Stormforged concept approved October 28, 2026; B selected and adapted
to the owner's small/cute first-form direction. See the
[approved concept](../sol_bible.md#rattlehorn--stormforged) and
[shared silhouette review](../../sol-creature-anatomy-review.md).

## Identity and family

| Field | Current specification |
| --- | --- |
| Approval scope | Compact sure-footed quadruped, short loose ring-built horns, springy filament mane and braced/test-footing behaviors |
| Primary class | Stormforged; individual affinity remains independent |
| Species / lineage ID | `sol_species_0005` / `sol_lineage_0005`; unique keys checked before admission |
| Family / form count | Undecided; the approved taller split-horn direction does not allocate later species |
| Size progression | Small, cute first stage confirmed; three total forms would require small → medium → large; family count remains undecided |
| Exact dimensions, later forms, evolution conditions | Undecided; board proportions are alternatives, not size specifications |

## Review alternatives — B selected

**A — wide, low chest (not selected).** A compact barrel body carries a heavy front
chest above four short, robust jointed legs. Separated cloven feet widen the base.
A blunt projecting muzzle and short ring-built horns sit ahead of a broken low
ridge of stiff neck/shoulder filaments. Keep daylight between body and feet so
the stance remains visible. Signature pose: plant all four feet wide, lower the
chest slightly and raise the mane while the horn rings tremble.

**B — elevated chest and narrow steps.** Longer, slimmer legs support a deep high
front chest tapering into smaller haunches. A lifted blunt head has short outward
ring horns, with a higher swept filament collar concentrated at the nape.
Signature pose: test unfamiliar footing with one forefoot while the other three
feet carry the body. Keep the trunk compact; avoid a generic long-backed goat.

Stormforged reads through the approved pressure-sensitive horn structure,
charge-responsive living mane and bracing response. These are biological design
intent; detailed storm origin remains open. The horns are organic keratin, not
metal coils or machine parts. No individual affinity or weather-detection power
is assigned. Ring motion may be a visual cue without a weather simulation rule.

## Proposed materials, habitat and routine

Use warm stone-gray hide, pale keratin rings with darker gaps, and coarse darker
filaments. Exact colors are provisional; the body must retain its identity with
any affinity effect. Proposed habitat: exposed rocky paths and ridges, subject
to later authored biome admission. Preserve the approved routine of testing
footing and bracing as pressure shifts. Companion moment: step toward a crossing,
test it, pause and look back. This does not grant route scouting, collision
changes or automatic traversal permission to the player.

## Combat presentation and model plan

Combat role is undecided. Proposed presentation emphasis: a planted frontal
challenge and short head/shoulder attack accent. Do not infer stun, charge damage,
weather bonuses, defensive stats or a new move. The signature action is the
braced mane-and-ring display. Source reconciliation precedes gameplay rules.

Register four distinct hip/knee/contact chains with diagonal support groups;
hoof geometry and neutral width must match the chosen stance. Give the head,
horn-ring segments and mane separate presentation controls. Workshop poses must
include weight-bearing rest, braced alert, walking weight shifts, planted turns,
signature display, short attack accent, hit compression and recovery. B's
forefoot test must shift weight onto three real contacts rather than hover the
body. Include the raised mane and head/horntip sweep in the animation envelope.
The current blockout supplies those controls and poses. Final scale, finished art
and target-device performance remain unaccepted.

Status: approved concept and B selection; small first-form blockout integrated
through the shared catalog and normal game. Finished-art/model acceptance remains
open. See the [integration evidence](../../sol-creature-anatomy-review.md#applied-to-the-normal-game).

## Early combat alternatives — October 28, 2026

Owner-approved low-tier prototype additions: `spark_jab`, `static_tap`, `tailwind_step`.
These are additional eligible and initially remembered options; the original four
equipped moves remain the default. Four slots remain the equipment limit.
Individual affinity stays independent. This extends the playable learnset,
not final species, evolution, or balance approval. See the
[early move design and limits](../../early-combat-moves.md).
