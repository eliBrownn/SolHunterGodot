# Rimefold first-form blockout

Owner decision, October 28, 2026: **direction B selected**, with the explicit
clarification that this is a **small, cute first-stage model**. The initial
silhouette board looks closer to mature-stage art; it does not approve those
proportions for this form or establish a final-stage design.

Current implementation: Broad forebody with a larger soft face/eyes and two smaller rounded fin lobes per side. Four supports stay planted while the leading left fin independently investigates. Opaque folds avoid transparency overhead in this blockout.

Open [Rimefold workshop](../../../scenes/rimefold_workshop.tscn) with F6.
The authored [model scene](../../../scenes/sols/rimefold.tscn) uses
[its distinct builder](../../../scripts/sol_rimefold.gd). Original repository-authored
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

The [runtime record](../../../resources/sol_species/rimefold.tres) and shared catalog
use stable species ID `sol_species_0006` and lineage ID `sol_lineage_0006`, ordinary form 1,
footprint 1. Normal F5 play admits one authored sighting near trail x=56, with
Air affinity on that individual. Affinity does not come from its class.
The species uses its small 0.65-scale B model for exploration, battle, following
and party-menu previews. It has ground movement only; no inferred air/water mode.
Traversal clearance is conservatively 0.65 m radius and 0.5 m height.

Provisional reference profile at level 3, 100% natural potential, no training:

| HP | Attack | Defense | Special Attack | Special Defense | Speed |
| --- | --- | --- | --- | --- | --- |
| 48 | 12 | 20 | 18 | 22 | 10 |

Eligible existing moves: `strike`, `current`, `ward`, `anchor`, `mend`, `barrier`, `rattle`.
The first four start equipped. This is editable playtest tuning, not final balance
or a new class/affinity rule. The existing class passive is reused unchanged.
The resource retains the existing provisional three-slot training-capacity
parameter; it does not register later forms, fix the final family count or author
evolution triggers. Resolve the family before later-form production.

Wild behavior reuses patrol/idle/approach; the companion's inherited
`rimefold_investigate` idle branch cues the existing signature animation. This adds
no trust reward, weather detection or ecological world change. The trail placement
is for current play, not a claim that final habitat distribution is implemented.
Stat/move definitions apply at admission and saved traits persist. Existing
current-format expeditions gain the explicit sighting on load, through the existing
admission path. Rebuild/restart views for scene edits; keep final dimensions open.

Working name. Frostbound concept approved October 28, 2026; B selected and adapted
to the owner's small/cute first-form direction. See the
[approved concept](../sol_bible.md#rimefold--frostbound) and
[shared silhouette review](../../sol-creature-anatomy-review.md).

## Identity and family

| Field | Current specification |
| --- | --- |
| Approval scope | Low long-bodied amphibianlike creature, fleshy translucent blanketlike side fins, opaque center, broad forelimbs and wrapping behavior |
| Primary class | Frostbound; individual affinity remains independent |
| Species / lineage ID | `sol_species_0006` / `sol_lineage_0006`; unique keys checked before admission |
| Family / form count | Undecided; approved increasing mantle/shield direction does not allocate later species |
| Size progression | Small, cute first stage confirmed; three total forms would require small → medium → large; family count remains undecided |
| Exact dimensions, later forms, evolution conditions | Undecided; no numeric dimensions are inferred from the drawing |

## Review alternatives — B selected

**A — long trunk and trailing folds (not selected).** A broad flat amphibian head
leads an elongated low torso and tapering tail. Two broad forelimbs carry the
front; a smaller visible hind pair supports the rear. Soft side fins run along
the body in overlapping lengthwise folds. Their edges trail and wrap beneath
the trunk; they do not form hard dorsal plates. Signature pose: settle low and
wrap both side fins snugly around the body, leaving the head and forefeet clear.

**B — broad forebody and overlapping fin lobes.** A wider flat head and larger
paddlelike front limbs lead a long rear trunk with smaller hind supports and a
shorter tapering tail. Rounded side-fin lobes overlap outward before folding
underneath. Preserve a long visible body axis beneath the broad front rather
than collapsing it into a turtle shape. Signature pose: keep four contacts down
and unfold one side-fin lobe toward a nearby object before drawing it back.

Frostbound reads through the approved cold-adapted wrapping anatomy and its
snow-pressing low posture. Cold-wetland biology and precise insulation mechanism
remain open. Fins are living tissue, not ice armor, a shell or external gills.
Affinity remains independent. Amphibianlike anatomy does not admit swimming,
diving, cold immunity or snow/terrain manipulation.

## Proposed materials, habitat and routine

Use a matte opaque central body and soft, slightly translucent fleshy edges;
provisional muted slate/pearl values keep the folds readable. Test opacity before
choosing transparent materials, since overlapping surfaces can obscure the body
and increase rendering cost. Exact colors and shaders remain undecided.
Proposed habitat: cold wetland margins and snow pockets, as in the approved
concept; no new terrain or generation support is added. Routine: press low
through loose cover, settle and wrap the fins. Companion moment: investigate a
small object by slowly extending a fin, then retract it. No ecological path
creation or new interaction reward is implied.

## Combat presentation and model plan

Combat role is undecided. Proposed presentation emphasis: low planted reactions
and deliberate forelimb/body accents, preserving a tactile personality. No
defensive stat profile, freezing effect, shield mechanic or move is assigned.
The signature action remains wrapping/unfolding. Source reconciliation precedes
gameplay rules.

Register four support chains, with larger forelimbs and smaller hindlimbs;
side fins remain independently controlled appendages. A long trunk may need
additional presentation pivots beyond the existing compact pilot body; evaluate
this in the workshop rather than promising solver compatibility. Required poses:
low rest, unfolded alert, slow alternating crawl, curved turn, fin wrap/investigate,
attack accent, hit compression and recovery. Test foot reach under body sway,
fin-ground clipping, self-intersection and the complete open-fin/tail envelope.
The current blockout supplies those controls and poses. Final scale, finished art
and target-device performance remain unaccepted.

Status: approved concept and B selection; small first-form blockout integrated
through the shared catalog and normal game. Finished-art/model acceptance remains
open. See the [integration evidence](../../sol-creature-anatomy-review.md#applied-to-the-normal-game).

## Early combat alternatives — October 28, 2026

Owner-approved low-tier prototype additions: `cold_snap`, `chilling_mist`, `grit_guard`.
These are additional eligible and initially remembered options; the original four
equipped moves remain the default. Four slots remain the equipment limit.
Individual affinity stays independent. This extends the playable learnset,
not final species, evolution, or balance approval. See the
[early move design and limits](../../early-combat-moves.md).
