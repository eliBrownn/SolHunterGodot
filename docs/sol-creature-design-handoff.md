# Handoff: design and build more Sol creatures

Current creative direction after that implementation: retain the existing models
for development, while designing original SolHunter lore creatures with folklore
inspiration. Most future designs move away from literal real-world animals;
animal influence should express a mythical/high-fantasy identity. Tone is dark
fantasy with danger, mystery and meaningful bonds. First forms keep charm and
clearly otherworldly anatomy/behavior. The world scale is anchored to small Sols;
humans are normally smaller. Correct oversized human presentation downward,
without enlarging Sols to match the player. Large Sols occupy 3×3 tiles.
Different local folklore interprets a coherent underlying reality.
Ordinary evolution retains a recognizable personality core with new instincts
and needs, while deeply changing the bond, with
remnants and recoverable memories; mastering all three stage bonds is a long,
difficult, rewarding goal. Maximum bond does not gate ordinary evolution; missed
earlier-stage milestones can be recovered later through difficult memory recovery.
Top rewards emphasize unique relationship moments and meaningful teamwork.
Bond development centers on species-specific care, shared ordeals and consistent
choices. Evolution is mutual, requiring the Sol's willingness; advanced teamwork
is limited after transformation until trust is rebuilt.
See the Bible's current owner direction. Implementation details are
in discussion; these statements do not authorize inventing a bond formula or
silently replacing current development models.

Latest owner direction, October 28: one playable first form per class. All eighteen
current classes now have catalog/sighting representatives, including twelve new
small/cute blockouts. The [class-coverage review](sol-class-coverage.md) links the
engine-rendered board, focused evidence, distinct support plans and remaining
design limits. The Sol Bible remains the canonical roster/sheet index. Eldritch
is a separate identity with a zero-effect unassigned passive; legacy Stonebound
is preserved. Continue by refining these first forms and authoring family/ability
decisions, rather than treating class coverage as final roster/art approval.

Owner direction, October 28, 2026: remove orb bodies, increase anatomical variety,
and make creatures fit different classes. Continue from the existing Bible and
working procedural movement. Offer concrete ideas; the owner supplies creative
feedback. Ask only when a missing decision changes the work.

## Read first

- [Project standard](PROJECT_STANDARD.md): organization, authority and validation.
- [Sol Bible](reference/sol_bible.md): class list, candidate roster and approvals.
- [Model creation guide](creating-sol-models.md): creating and testing another rig.
- [Species data](sol-species-data.md), [ground movement](sol-procedural-ground.md),
  [flight/swimming](sol-flight-and-swimming.md), and [owned companions](owned-companion.md).

The worldbuilding Bible remains the design authority. Consult SolHunterSource
under [mechanics-reference.md](mechanics-reference.md) for mechanics questions;
Godot remains world-generation authority.

## Decisions to preserve

The 18 classes are Beast, CinderKin, Abyssal, Bloom, Stormforged, Frostbound,
Warborn, Blight, Earthbound, Zephyr, Mindweaver, Chitin, Eldritch, Wraith,
Wyrmkin, Umbral, Construct and Feyborn. The Bible contains three initial candidates
per class. Its 54 concepts are candidates toward **151 roster entries**, not 54
automatically approved three-form families. All names remain placeholders.

Six concepts have approval: Crown-Ear (batlike Beast), Ashquill (CinderKin),
Reedback (Abyssal), Bellroot (Bloom), Rattlehorn (Stormforged), Rimefold (Frostbound).
Other candidates retain the Bible's approval labels. The playable trio is
Crown-Ear, Reedback and Bellroot. Roles start as fast/disruptive, durable/physical,
and support/control respectively. These are not newly selected narrative starters.

Three total forms progress small to medium to large. Two total forms can have
varied size progression. Non-evolving species have a predetermined size.
Approve family structure before filling evolution slots. Do not infer final
stats, exact dimensions or evolution conditions from provisional model scale.

Class describes the creature's design identity; individual affinity is independent.
Do not identify species by recoloring a common body. Bloom requires plant anatomy,
and Abyssal should read as biologically aquatic; reeds alone do not make Bloom.
Eldritch is a different design direction, not a renamed legacy Stonebound.

## Current game and provisional art

F5 runs `scenes/world_3d.tscn`. Normal sightings use
`resources/sol_world_sightings.tres`, with wilderness enabled and the pilot trio
present. Reedback's home uses a real generated bank. The isolated species and
traversal pilot scenes remain available for focused review.

The shared `scripts/sols/presentation/sol_species_view.gd` factory serves wild Sols, combat, companion
and menu views. Catalog records use their own authored scene. Every other identity
gets a creature body, never an orb. The compatibility class name `SolOrb` still
exists underneath the rig for affinity effects and battle interfaces; it does not
mean a visible orb should return. The placeholder scene is also a creature.

`scripts/sols/presentation/sol_prototype_creature.gd` provides these **provisional** replacements:

| Existing identity | Existing class | Temporary anatomical direction |
| --- | --- | --- |
| Seedmote | Bloom (`verdant`) | Split seed husk, two root legs, leaf arms and cotyledons |
| Bramblepup | Beast | Long-backed quadruped hound, projecting muzzle, folded ears and brush tail |
| Ashkit | CinderKin | Upright feline, two support legs, free forepaws, ash ruff and cinder-shaped tuft |
| Rillfin | Abyssal (`tideborn`) | Low amphibious fish body, lateral fins, short supports and deep tail paddle |
| Unknown species | Unassigned | Neutral diagnostic creature; no inferred class or roster approval |

These art replacements preserve IDs, affinities, classes, stats and ownership.
They do not approve legacy species for the final roster. Rillfin's fins do not
automatically grant swimming: movement capabilities still require authored data.
Ground, low flight and surface swimming are connected for the supported pilot
species; owned companions share flight/swim policies. Tactical combat retains
its legal ground routing. Diving, riding and aerial combat remain future work.

## Next design batch

Work started October 28, 2026: the [first anatomy review](sol-creature-anatomy-review.md)
compares two proposed directions each for Ashquill, Rattlehorn and Rimefold against
the integrated and provisional creatures. Their linked Bible sheets preserve
concept approvals while leaving anatomy selection, family counts and runtime
admission open. Owner subsequently selected **B for all three**, clarifying that
these are **small, cute first forms** and the initial board looks closer to a
final stage. Distinct workshop blockouts now implement those juvenile proportions.
Owner subsequently requested applying the creatures; they are now registered
in the shared catalog and normal-game sightings, with existing gameplay rules.
Next action: refine the integrated first forms and resolve family structure
before later-form production.
The original concept board is not a first-form proportion target or engine validation.

1. Review the six approved concepts and the provisional legacy bodies together.
   Show silhouettes and class labels before spending time on detail.
2. Recommend Ashquill, Rattlehorn and Rimefold as the next production candidates:
   their CinderKin, Stormforged and Frostbound classes expand the playable coverage.
   Read their existing Bible concepts before suggesting refinements. Develop the
   anatomy from those concepts; do not replace them with decorated versions of one rig.
3. Present two anatomical directions per candidate, with a signature pose and a
   reason the design belongs to its class. Let owner feedback select/refine the
   direction before treating new anatomy or lineage choices as approved.
4. Compare the batch for silhouette, proportions, support count, head/body relation,
   surface structure and gait. At least one strong distinction must remain readable
   without color. Avoid making every class a small mammal with themed ears.
5. After that batch, choose candidates from classes with no playable representation,
   using the existing three-per-class list. Track candidate, approved concept,
   blockout, integrated and reviewed states separately.

## Deliverable for each selected species

Update its Bible sheet with approval state, primary class, family/form count,
size progression, silhouette/anatomy, material palette, habitat, readable routine,
companion interaction, combat role and signature action. Mark undecided details.
Ecological world changes are deferred; prioritize routines and companionship.

Make a distinct simple 3D blockout first. Use a scene root deriving from
`SolCreature`, overriding `build_model`, `animate_features` and `preview_bounds`. Register
real support joints for that anatomy: bipeds, quadrupeds and wing supports need
different chains. Keep procedural transforms separate from simulation coordinates.
Supply rest, alert, locomotion, turn, signature, attack, hit and recovery poses.
Check the full animation envelope, not only the neutral mesh bounds.

For admitted new species, author `SolSpeciesRecord`, traversal/ecology resources,
move data and catalog entry. Reserve unique stable species/lineage IDs after
checking current data; do not recycle existing IDs. New mechanics need source
evidence or an explicit owner decision. A presentation-only replacement for a
legacy identity should not silently rewrite its gameplay record.

Use the model workshop for isolated review, then check actual exploration,
Observe/Engage, combat, capture, party selection, following, menu previews and
save/load. Keep models adjustable through documented Inspector fields. Revisit
geometry and animation cost throughout; desktop success is not AYN Thor acceptance.

Use the project standard's [routine creature integration workflow](PROJECT_STANDARD.md#routine-creature-integration-and-proportionate-checks)
to select focused validation; the owner's later instruction supersedes a blanket
full-validator rerun for each creature. Broaden checks for shared logic or new rigs.
Add tests for genuinely new anatomy or capabilities rather than repeating shape
construction. Include useful rendered evidence. `tests/sol_creature_fallback.gd`
guards the no-orb fallback and can render the provisional lineup when run without
`--headless`. Retain the shared factory's no-orb contract in all future work.

## Verification for this handoff

The no-orb fallback suite passes 57 headless checks and 58 rendered checks,
covering identity/affinity preservation, anatomy-specific supports, procedural
walking, combat poses, preview envelopes, placeholder replacement and rejection
of orb-only catalog scenes. The rendered lineup is
`artifacts/sol_creature_fallback/provisional_models.png` (ignored review output).
The shared validation run also passed catalog (108), pilot models (93), ground
movement (222), flight/swimming (85), owned companion (40), owned traversal (30),
normal-game rollout (78), combat and full-3D suites. An old orb-only valid-root
fixture in `runtime_hot_paths.gd` was updated to a creature; its rerun passes 186 checks.

The complete validator is not yet clean: the continuation encountered an unrelated
terrain-material expectation in `tests/atmosphere.gd:93` (StandardMaterial3D versus
the current ShaderMaterial). That terrain test was left untouched. Review logs are
`artifacts/sol_air_water/no_orbs_validate.log`, `no_orbs_validate_remaining.log` and
`no_orbs_validate_final.log`; the latter records the remaining menu/world checks.
Those remaining world suites and the solid-scene journey pass. The menu check
initially caught cropped affinity-effect framing on the smaller creatures; the
preview now preserves effect margin alongside each body's own envelope, and the
rerun passes all 41 checks (`no_orbs_menu.log`). The atmosphere test remains the
only unresolved validation failure from this run.

### Direction-B first-form continuation

Owner selected B for Ashquill, Rattlehorn and Rimefold and clarified that they
must be small/cute first stages; the original board looks closer to final-stage
proportions. Their distinct workshop blockouts, scene links, controls and current
evidence are in the [anatomy review](sol-creature-anatomy-review.md#selected-first-form-blockouts).
The new suite passes 318 headless and 326 rendered checks; all three workshop
scenes start cleanly. Catalog/gameplay admission remains future work. The full
validator is not clean: this continuation encountered intermittent nonzero engine
exits after passing catalog/companion assertions, while isolated retries passed.
The earlier atmosphere material-type error also reproduces. Preserve those
limitations rather than promoting the blockouts to integrated/reviewed species.

### Applied normal-game continuation

Owner then requested applying the creatures. Ashquill, Rattlehorn and Rimefold
are now gameplay-integrated first forms through the shared catalog, with unique
species/lineage IDs 0004–0006 and normal trail sightings at x=22/40/56. All three
remain ground-only and preserve the small/cute B models. Existing creatures,
starters, affinities and saved identities are retained. Capture, party selection,
following/gestures, combat and menu previews use the same authored scenes.
See [applied anatomy integration](sol-creature-anatomy-review.md#applied-to-the-normal-game)
for source evidence, provisional stat/move/family details and current checks:
111 headless integration checks, 117 rendered checks, 111 rollout checks, 135
catalog checks, 423 new-anatomy checks and 222 original pilot ground checks pass.
Finished art, final balance/family structure and target-device acceptance remain open.
