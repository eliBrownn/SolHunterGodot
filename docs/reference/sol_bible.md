# Sol Bible

SolHunter species, lineages, and roster authoring reference.

October 28 combat follow-up: species sheets now record additional low-tier move
alternatives under the owner's expanded combat direction. The connected
[early move library and design principles](../early-combat-moves.md) distinguish
finite active uses, equipped passive reactions and hybrid roles from native class
traits. These prototype learnsets do not promote provisional species or balance
to final approval.

Established: October 28, 2026, at the owner's request.
Status: authoring framework, creature-style principles, and six initial species
concepts approved. All species names are placeholders. Eighteen first-form records and
articulated blockouts are connected to normal gameplay. Crown-Ear and Reedback
retain their admitted low flight and surface swimming; the other sixteen are grounded.
Other species remain at their individually recorded design stages.
The 54-concept initial roster is populated across
all eighteen classes; six concepts are explicitly approved and forty-eight remain
proposed for individual review.

Owner follow-up, October 28: fill every class with **one playable first form**.
Twelve existing proposed candidates are selected for provisional implementation,
alongside the initial six. This authorizes playable coverage, not final concept,
family, naming or finished-art approval. See [the class review](../sol-class-coverage.md).

Continue production with the [creature-design handoff](../sol-creature-design-handoff.md).
Owner follow-up: no orb bodies, including fallbacks; new creatures need distinct
anatomy that fits different classes. Provisional legacy models do not constitute
approval of those species for the final roster.

## Purpose and authority

Build a roster of living creatures whose appearance, behavior, companionship,
ecology, combat, and evolution belong to the same world. Each entry should explain
why this Sol belongs in the adventure and what makes it worth knowing.

This is the working home for species briefs and the roster index. The
[worldbuilding Bible](SolHunter_Worldbuilding_Bible.md) governs overarching design;
this companion develops species details within it. Explicit owner decisions take
precedence. The [project standard](../PROJECT_STANDARD.md) governs repository and
Git workflow; this document does not replace it.

Use the [mechanics reference](../mechanics-reference.md) to resolve non-generation
mechanics before proposing replacements. Godot remains the world-generation
authority. Record source evidence and unresolved conflicts in the affected brief.
Do not copy private source catalogs or documents into this repository.

## Contents

- [Owner direction](#owner-direction)
- [Established design boundaries](#established-design-boundaries)
- [Working classes for review](#working-classes-for-review)
- [Roster accounting](#roster-accounting)
- [Roster index](#roster-index)
- [Coverage and first design batch](#coverage-and-first-design-batch)
- [Production integration plan](#production-integration-plan)
- [Pilot production sheets](#pilot-production-sheets)
- [Step-two species data integration](#step-two-species-data-integration)
- [Lineage brief template](#lineage-brief-template)
- [Species brief template](#species-brief-template)
- [Legendary manifestation template](#legendary-manifestation-template)
- [Review and delivery](#review-and-delivery)
- [Design records](#design-records)
- [Evidence and related references](#evidence-and-related-references)

## Owner direction

### Current creative target — original dark-fantasy beings

Owner clarification, October 28, 2026, after playable class coverage:

- Keep the present creatures in use for game development. Treat their current
  appearance as development proxies, not a final style/scale target.
- Everything should be original. Build SolHunter creatures with their own lore,
  inspired where useful by real-world folklore. Most future species should move
  away from literal real-world animals; animal influence should have a mythical
  or high-fantasy identity. The phoenix Sol is a positive reference.
- The selected tone is **dark fantasy: danger, mystery and meaningful bonds**.
- A coherent underlying reality is interpreted through different local folklore.
  Differences in stories do not automatically establish conflicting literal origins.
- Keep the charm of first forms, with clearly otherworldly anatomy and behavior.
  Small/cute does not mean an ordinary young animal with a themed accessory.
- The world scale is anchored to small Sols, not humans. The owner's correction
  is explicit: humans are normally smaller than small Sols, and it **does not**
  make sense to enlarge Sols to match the current player. Bring oversized human
  presentation down against the small-Sol/world reference. Large Sols occupy
  3×3 tiles and feel massive. Exact ratios and dimensions remain open; runtime
  scale has not been changed during this discussion.
- First forms are what average people bond with. Ordinary transformation changes
  the bond almost like a reset, with remnants and regainable memories. The choice
  to allow evolution should carry emotional weight alongside its benefits.
- Through evolution, retain a recognizable personality core while introducing
  new instincts, needs and unfamiliar behavior. Relationship rebuilding is not
  a requirement for an unrelated replacement personality.
- Maximum bond across all three ordinary stages should take a long time, be hard
  to achieve and be rewarding. The owner subsequently confirmed that maximum
  bond is not an ordinary-evolution requirement: earlier evolution remains
  possible with relationship tradeoffs. Missed earlier-stage milestones can be
  regained through difficult memory recovery in later forms. Greatest rewards
  emphasize unique relationship moments and meaningful teamwork options.
  Exact carryover, activities, reward content and numbers remain open.
- Bond progress should primarily come from species-specific care, shared ordeals
  and consistent choices. Evolution is mutual: the player offers and the Sol must
  be willing. The near-reset creates clear limits on advanced teamwork until
  trust is rebuilt. Specific willingness criteria and teamwork options remain open.

These directions are recorded in the worldbuilding Bible's living-identity,
physical-development and evolution sections. They guide the next design
discussion; no runtime model, scale, stat, save or bond behavior changed during
this discussion. Prior concept approvals remain historical approvals of their
recorded scope; revisit designs under this newer direction rather than silently
promoting existing prototypes into final lore creatures.

Reference check: SolHunterSource local ref
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`,
`src/systems/tactics/relationships.py`, `progression.py` and
`tests/test_sol_relationships.py` support bounded recorded trust/memories and
preservation across ownership boundaries. They do not establish a completed
evolution bond-reset/recovery system. Older provisional trust thresholds and
evolution triggers were not adopted as new design answers.

October 28, 2026, initial species-design questionnaire:

- Begin by defining the roster's overall creature style, before designing the
  three rescuers or developing existing prototype candidates.
- Start fresh. Retain earlier or existing species only when deliberately chosen;
  the old roster is not a default content backlog. This is a creative direction,
  not an instruction to delete working prototype content or saved identities.
- Include all three offered visual directions: endearing early forms that can
  grow formidable and mysterious; grounded creatures with restrained supernatural
  features; and creatures that are otherworldly from their earliest forms.
- The agent leads with ideas; the owner interjects and supplies creative feedback.
  Proposals remain labeled until the owner's response establishes approval.

Working interpretation: this permits breadth across the roster rather than
requiring every species to combine all three directions. No fixed proportions or
mandatory evolutionary aesthetic were established by that questionnaire. Later
concept approvals are recorded separately below.

### Species concept approvals and naming

October 28, 2026: the owner approved Crown-Ear, Ashquill, Reedback, Bellroot,
Rattlehorn, and Rimefold as presented in the first six-class review. Crown-Ear is
explicitly a **batlike creature**. Approval covers the presented concept direction
and class placement, not a completed species specification or unpresented mechanics.
All species names are placeholders until explicitly finalized. This includes
future concept names; working names do not establish runtime IDs.

Glass-Throat was outside the explicitly approved first review and remains proposed,
with positive directional feedback on the second batch. Batlike anatomy does
not by itself establish flight/traversal mechanics or change Crown-Ear's approved
Beast placement. Preserve the listening crown as its defining anatomical feature.

### Approved size progression

October 28, 2026: three-form lineages progress **small → medium → large**. The
owner clarified that **two total forms** can use varied authored size progressions.
A species that does not evolve has a predetermined authored size. Do not confuse
two total forms with two evolution events (which produce three forms).

These are category/progression decisions, not numeric height/mass limits or
permission for random individual body-size rolls. Set dimensions per species and
ordinary stage. The three pilot first forms are small; their draft measurements
still need model-scale review. All species names remain placeholders.

Owner follow-up, October 28: selected direction B for Ashquill, Rattlehorn and
Rimefold, then clarified that these are **small, cute first-stage models**. The
initial anatomy board looks closer to a final-stage treatment and must not set
their first-form proportions. Keep the upright bird/arched tail, higher-chested
quadruped and broad-forebody/fin-lobe body plans, with juvenile facial proportions
and reduced ornamentation. Their isolated blockouts do not approve family counts,
later-stage models, final dimensions or gameplay records. See the
[anatomy review](../sol-creature-anatomy-review.md#selected-first-form-blockouts).

### Approved creature-style principles

October 28, 2026: the owner agreed to the proposed visual foundation and asked to
continue. Approval covers these shared principles; the illustrative creatures in
that proposal were style examples, not selected species.

**Foundation:** Sols are living creatures whose anatomy reveals their relationship
with Vastra. Allow endearing, grounded/formidable, and strange/mysterious creatures
to coexist across the roster.

Apply this under the current original dark-fantasy direction above: grounded
means physical believability, not a requirement for literal real-world wildlife.

1. Use strong silhouettes readable at the actual exploration camera distance.
2. Build each creature around one defining anatomical idea; develop its movement,
   behavior, and abilities coherently from that idea.
3. Express personality through the body: posture, breathing, attention, grooming,
   hesitation, and other readable physical cues.
4. Evolution develops the original idea. Later forms can remain gentle, elegant,
   or peculiar as well as becoming formidable.
5. Species identity must survive every individual affinity. Anatomy, materials,
   and markings establish the creature; affinity adds another readable layer.

**Tone:** dark fantasy with danger, mystery and meaningful bonds; beauty can have
an unsettling edge. Friendly creatures can behave eerily;
frightening territorial creatures can show care. Preserve emotional range and the
distinction between intimidating appearance and moral character.

## Established design boundaries

These summarize existing direction; follow the linked authority if a summary
needs clarification. New concepts and numerical values require their own status.

| Area | Boundary | Authority |
| --- | --- | --- |
| Living identity | Sols are physical living beings with individual identities, memories, personalities, and relationships. Early forms can be wisplike while remaining tangible. | Worldbuilding Bible, Parts I and IV |
| Species and lineage | Each ordinary evolutionary species has its own identity within a lineage. The primary class stays fixed through ordinary evolution; exceptional secondary classes or class changes require explicit authoring. | Worldbuilding Bible, sections 22–24 |
| Individual affinity | Affinity is independent of species and class. Approved working affinities are Fire, Water, Earth, Air, Lightning, Void, Spectral, and Quantum; rarity and capabilities follow the latest approved affinity rules. | Worldbuilding Bible, October 27 affinity rules |
| Ordinary evolution | Three ordinary forms are the established model. Evolution should change physical presence and environmental relationships as well as combat. Starter final evolution around level 36 is a working target, not a universal trigger. | Worldbuilding Bible, sections 21 and 24 |
| Legendary manifestation | A unique primordial individual is associated with a lineage. Its manifestation is separate from ordinary evolution; current individual affinity is preserved. | Worldbuilding Bible, Part IX |
| Behavior | Avoidant, neutral, and assertive are broad temperament categories. Give a species generally two or three readable behaviors. Territorial aggression does not imply evil. | Worldbuilding Bible, sections 26–28 |
| Ecology | Most Sols contribute to equilibrium through ordinary noncombat behavior. Under the October 28 retcon, aggressive Vastra-powered abilities create overload on affected tiles; healing abilities can create negative restorative conditions independently of HP healed. Habitat design respects Godot's generation authority. | Worldbuilding Bible, Parts III–IV and [October 28 retcon](../decisions/2026-10-28-vastra-combat-and-restoration.md) |
| Combat | Six core stats: HP, Attack, Defense, Special Attack, Special Defense, Speed. Explicit species learnsets determine move eligibility; at most four moves are equipped. Innate abilities remain distinct from moves. | Worldbuilding Bible, October 27 affinity/move and stat/class rules |
| Companionship | Capture or holding authority does not guarantee affection or cooperation. Respectful behavior supports earned trust; formulas and specific interactions remain open. | [October 28 decision](../decisions/2026-10-28-opening-companionship-and-consequences.md) |
| Opening | Three actual Sol individuals guide the player out of the storm; one of those same individuals becomes the starter. Their species and selection presentation remain open. | October 28 decision |
| Presentation | Species have their own models, behaviors and animations. Owner follow-up removes orb bodies, including fallbacks; provisional creatures must vary anatomically and fit their classes. | October 28 decision and follow-up |

The eighteen class names are now selected for current authoring, with Earthbound
retained for now. Thematic boundaries still need review before final species
classification; Eldritch is an approved replacement direction requiring detail. Class, combat role, habitat, and affinity are
separate authoring fields; none substitutes for another.

## Working classes for review

Status: all eighteen current class names selected by the owner on October 28,
2026; Earthbound is retained for now. This is the current class decision record
and supersedes earlier naming proposals. Category details still need authoring. Runtime IDs
and passives remain unchanged; implementation changes require their own validation.
See [Godot class settings](../../scripts/class_buff_settings.gd) and
[class buffs](../class-buffs.md) for the current runtime mapping.

Owner direction: each species belongs to a class. Start with three species concepts
per class: **54 initial concept slots** across eighteen classes. Evolution grouping
remains open; this does not automatically commit to 54 three-form lineages.
Use the selected names below when expanding species concepts. Eldritch boundaries
and implementation remain separate work.

### Owner class decisions

Parenthetical examples are the owner's creative references for future species
ideas. They do not approve a particular species, evolution, ability, or imported
mythological rule. Preserve the supplied display styling, including CinderKin;
existing internal IDs remain separate.

| Class / slot | Existing runtime ID | Owner decision | Creative reference / scope |
| --- | --- | --- | --- |
| Beast | `beast` | Keep | Animal creatures. |
| CinderKin | `cinderkin` | Keep | Phoenix is an owner reference; rebirth mechanics are not established. |
| Abyssal | `tideborn` | Approved rename from Tideborn | Aquatic category; name alone does not restrict species to deep ocean. |
| Bloom | `verdant` | Approved rename from Verdant | Living plant and fungal bodies. |
| Stormforged | `stormforged` | Keep | Storm-shaped creatures. |
| Frostbound | `frostbound` | Keep | Winter/glacial creatures. |
| Warborn | `warborn` | Keep | Minotaurs and centaurs are owner references; avoid treating this as only generic aggression. |
| Blight | `blightborn` | Rename Blightborn to Blight | Existing category remains; display-name decision does not rewrite mechanics. |
| Earthbound | `earthbound` | Keep for now | Soil/subterranean working direction. |
| Zephyr | `skyborne` | Approved rename from Skyborne | Aerial category; individual affinity remains independent. |
| Mindweaver | `mindweaver` | Keep | Mental/dream/prophetic creatures. |
| Chitin | `swarmkin` | Approved rename from Swarmkin | Arthropod category, including solitary species. |
| Eldritch | No new runtime ID assigned; replaces the `stonebound` design slot | Replacement direction approved | Alien anatomy and unusual senses; distinct boundaries and mechanics still need authoring. |
| Wraith | `wraithborn` | Rename Wraithborn to Wraith | Spirit/phase category remains; tangible Sol nature still applies. |
| Wyrmkin | `wyrmkin` | Keep | Draconic lineages. |
| Umbral | `umbral` | Keep | Shadow/occult creatures. |
| Construct | `construct` | Keep | Living beings with made/assembled bodies. |
| Feyborn | `feyborn` | Keep | Fae/enchantment identity. |

### Naming review completed

The owner selected Abyssal, Zephyr, and Chitin, and retained Earthbound for now.
Bloom, Blight, Wraith, and the Eldritch replacement direction were approved in
prior review. Earlier alternative names are superseded; they are not parallel
class lists. Display-name approvals do not automatically rename saved runtime
identifiers or change existing class passives.

### Approved Eldritch replacement direction

Eldritch replaces the old mineral-focused StoneBound class direction in the design
roster. It covers alien anatomy and unusual senses. Boundaries with Mindweaver,
Umbral, and Feyborn, along with its class passive, remain to be authored. Approval
does not imply automatic rarity, superior power, or an individual affinity.

This is a category redesign, not a display alias for the old mineral class. The
existing `stonebound` runtime ID and passive have not been repurposed. Resolve
runtime identity and affected content explicitly when implementation is authorized.
Mineral-bodied species can still be considered where they genuinely fit another
class; the design decision alone does not delete prototype content.

### Category boundaries to review

- Earthbound is retained for now with its soil/subterranean working direction;
  Eldritch replaces the overlapping mineral-focused design slot.
- Wraith versus Umbral: spirit/phase existence versus shadow/occult origin.
- Bloom versus an animal carrying plants: plant/fungal tissue must be intrinsic
  to a Bloom body; incidental growth alone is insufficient.
- Warborn requires a more specific identity than aggression or combat competence.
- Habitat, appearance, combat role, and individual affinity do not automatically
  determine class. Each brief must explain its defining species identity.
- Element-themed class names do not restrict individual affinities; CinderKin can
  have Water affinity, for example.

### Class placement of the first sketches

| Concept | Proposed class | Fit / development needed |
| --- | --- | --- |
| Crown-Ear | Beast | Its sensory crown develops from animal anatomy and listening behavior. |
| Reedback | Abyssal | Develop a biologically amphibious marsh creature; reeds alone do not make it Bloom. |
| Glass-Throat | Mindweaver | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/glass_throat.md), [concept](#glass-throat--mindweaver) |

Crown-Ear and Reedback received concept/class approval in the first batch.
Glass-Throat remains proposed with positive directional feedback. All three names
are placeholders; no creature receives a class solely to fill a slot.

## Roster accounting

Region One's established planning target is **150 ordinary roster entries plus
one additional Sol**, with a level cap of 55. This is a scope target, not an
authored or implemented roster count.

- Track lineages, ordinary evolutionary species, legendary manifestations, and
  individual Sols separately. Use one species row per ordinary evolutionary form.
- Affinity variants and named individuals do not become additional species merely
  by receiving different affinity, names, personalities, or behavior overrides.
- Final journal numbering and the additional Sol's identity/counting treatment
  remain unresolved. Do not silently assign that slot to a legendary form.
- The earlier private demo has 150 provisional entries in 50 families. That is
  reference evidence, not approval of 50 final three-form families or permission
  to import the catalog wholesale.
- Add real candidates as they are reviewed. Do not fill the index with numbered
  empty entries or count templates and design-batch slots as species.

| Measure | Current status in this Bible |
| --- | --- |
| Region One target | 150 ordinary entries + 1 additional Sol |
| Fully authored lineage briefs | 0; three pilot evolutionary outlines drafted |
| Initial concept roster | 54 total: 3 per class; 6 explicitly approved and 48 proposed; all names placeholders |
| Species concept approvals | 6; final naming and production approval pending |
| Pilot production sheets | Step one complete; three runtime data records connected in step two; species models and locomotion still pending |
| Existing prototype species awaiting design review | Seedmote and Bramblepup, recorded below |
| Final journal numbers | Unassigned |
| Legendary manifestation briefs | None authored here |

The counts above describe this document's records, not a runtime asset audit.
Update them with the index when designs are added or approved.

## Roster index

Use stable existing identifiers for prototype records. For new concepts, keep a
working title until the design is ready for an explicit runtime ID. A display-name
change must not silently rename an existing saved identity. Journal numbers are
presentation metadata, separate from species IDs.

### Existing prototype candidates

These are implementation observations, not completed briefs or final-roster
approval. Their current routines are provisional tuning.

| Candidate | Existing species ID | Current default routine | Design status | Evidence |
| --- | --- | --- | --- | --- |
| Seedmote | `seedmote` | Avoidant; patrol, idle, flee | Prototype candidate; full lineage/species brief pending | [Ecology resource](../../resources/sol_ecology/seedmote.tres) |
| Bramblepup | `bramblepup` | Neutral; patrol, idle, approach | Prototype candidate; full lineage/species brief pending | [Ecology resource](../../resources/sol_ecology/bramblepup.tres) |

The existing `trail_guard` ecology profile is an individual override for a
Seedmote, not a third species. See [Sol ecology](../sol-ecology.md).

### Concept index

The initial concept roster is populated: **54 concepts, three per class**. Six
have explicit owner concept approval. The next six received positive directional
feedback; these and the forty-two additions remain proposed for individual review.
All names are placeholders. Crown-Ear, Reedback, and Bellroot have working runtime
records for the step-two pilot. Ashquill, Rattlehorn and Rimefold now have small/cute
first-form blockouts in the owner-selected B directions, connected to the shared
catalog and normal game after the owner's apply instruction. A later batch adds
twelve first forms for the remaining classes. Other concepts remain unimplemented. None is a
fully authored evolutionary family. Evolution directions do not count as
additional species yet.

| Working concept | Class | Review status | Record |
| --- | --- | --- | --- |
| Crown-Ear | Beast | Concept approved; name placeholder | [Concept](#initial-creature-concepts) |
| Tumbletusk | Beast | Proposed; name placeholder | [Concept](#tumbletusk--beast) |
| Ribbonhart | Beast | Proposed; name placeholder | [Concept](#ribbonhart--beast) |
| Ashquill | CinderKin | Concept approved; B selected; small first-form gameplay blockout; name placeholder | [Anatomy sheet](sols/ashquill.md), [approved concept](#ashquill--cinderkin) |
| Cindercoil | CinderKin | Proposed; name placeholder | [Concept](#cindercoil--cinderkin) |
| Hearthback | CinderKin | Proposed; name placeholder | [Concept](#hearthback--cinderkin) |
| Reedback | Abyssal | Concept approved; name placeholder | [Concept](#initial-creature-concepts) |
| Sievefin | Abyssal | Proposed; name placeholder | [Concept](#sievefin--abyssal) |
| Tideknell | Abyssal | Proposed; name placeholder | [Concept](#tideknell--abyssal) |
| Bellroot | Bloom | Concept approved; name placeholder | [Concept](#bellroot--bloom) |
| Sporecap | Bloom | Proposed; name placeholder | [Concept](#sporecap--bloom) |
| Thornlace | Bloom | Proposed; name placeholder | [Concept](#thornlace--bloom) |
| Rattlehorn | Stormforged | Concept approved; B selected; small first-form gameplay blockout; name placeholder | [Anatomy sheet](sols/rattlehorn.md), [approved concept](#rattlehorn--stormforged) |
| Drumwing | Stormforged | Proposed; name placeholder | [Concept](#drumwing--stormforged) |
| Coilwhisk | Stormforged | Proposed; name placeholder | [Concept](#coilwhisk--stormforged) |
| Rimefold | Frostbound | Concept approved; B selected; small first-form gameplay blockout; name placeholder | [Anatomy sheet](sols/rimefold.md), [approved concept](#rimefold--frostbound) |
| Snowmantle | Frostbound | Proposed; name placeholder | [Concept](#snowmantle--frostbound) |
| Frostspindle | Frostbound | Proposed; name placeholder | [Concept](#frostspindle--frostbound) |
| Browguard | Warborn | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/browguard.md), [concept](#browguard--warborn) |
| Reedrunner | Warborn | Proposed; name placeholder | [Concept](#reedrunner--warborn) |
| Knucklecrest | Warborn | Proposed; name placeholder | [Concept](#knucklecrest--warborn) |
| Bitterfrill | Blight | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/bitterfrill.md), [concept](#bitterfrill--blight) |
| Sourpouch | Blight | Proposed; name placeholder | [Concept](#sourpouch--blight) |
| Needlecrest | Blight | Proposed; name placeholder | [Concept](#needlecrest--blight) |
| Knucklemole | Earthbound | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/knucklemole.md), [concept](#knucklemole--earthbound) |
| Siltback | Earthbound | Proposed; name placeholder | [Concept](#siltback--earthbound) |
| Rootsnout | Earthbound | Proposed; name placeholder | [Concept](#rootsnout--earthbound) |
| Sailcrest | Zephyr | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/sailcrest.md), [concept](#sailcrest--zephyr) |
| Whirlfan | Zephyr | Proposed; name placeholder | [Concept](#whirlfan--zephyr) |
| Hookwing | Zephyr | Proposed; name placeholder | [Concept](#hookwing--zephyr) |
| Glass-Throat | Mindweaver | Proposed; positive direction feedback; name placeholder | [Concept](#glass-throat--mindweaver) |
| Drowseed | Mindweaver | Proposed; name placeholder | [Concept](#drowseed--mindweaver) |
| Cairneye | Mindweaver | Proposed; name placeholder | [Concept](#cairneye--mindweaver) |
| Claspback | Chitin | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/claspback.md), [concept](#claspback--chitin) |
| Spindlebug | Chitin | Proposed; name placeholder | [Concept](#spindlebug--chitin) |
| Shieldgrub | Chitin | Proposed; name placeholder | [Concept](#shieldgrub--chitin) |
| Foldling | Eldritch | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/foldling.md), [concept](#foldling--eldritch) |
| Wheel-Eye | Eldritch | Proposed; name placeholder | [Concept](#wheel-eye--eldritch) |
| Threadwake | Eldritch | Proposed; name placeholder | [Concept](#threadwake--eldritch) |
| Mournveil | Wraith | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/mournveil.md), [concept](#mournveil--wraith) |
| Hushbell | Wraith | Proposed; name placeholder | [Concept](#hushbell--wraith) |
| Afterpaw | Wraith | Proposed; name placeholder | [Concept](#afterpaw--wraith) |
| Pebblewyrm | Wyrmkin | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/pebblewyrm.md), [concept](#pebblewyrm--wyrmkin) |
| Fanwyrm | Wyrmkin | Proposed; name placeholder | [Concept](#fanwyrm--wyrmkin) |
| Hookscale | Wyrmkin | Proposed; name placeholder | [Concept](#hookscale--wyrmkin) |
| Shadepelt | Umbral | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/shadepelt.md), [concept](#shadepelt--umbral) |
| Duskmaw | Umbral | Proposed; name placeholder | [Concept](#duskmaw--umbral) |
| Umbrafold | Umbral | Proposed; name placeholder | [Concept](#umbrafold--umbral) |
| Kilnling | Construct | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/kilnling.md), [concept](#kilnling--construct) |
| Rivetback | Construct | Proposed; name placeholder | [Concept](#rivetback--construct) |
| Spindleheart | Construct | Proposed; name placeholder | [Concept](#spindleheart--construct) |
| Thimblehart | Feyborn | Proposed concept; playable first-form candidate; name placeholder | [Sheet](sols/thimblehart.md), [concept](#thimblehart--feyborn) |
| Glimmergrin | Feyborn | Proposed; name placeholder | [Concept](#glimmergrin--feyborn) |
| Knottail | Feyborn | Proposed; name placeholder | [Concept](#knottail--feyborn) |

### Class coverage

| Class | Concepts | Explicit concept approvals | Playable first form |
| --- | --- | --- | --- |
| Beast | 3 | 1 | [Crown-Ear](sols/crown_ear.md) |
| CinderKin | 3 | 1 | [Ashquill](sols/ashquill.md) |
| Abyssal | 3 | 1 | [Reedback](sols/reedback.md) |
| Bloom | 3 | 1 | [Bellroot](sols/bellroot.md) |
| Stormforged | 3 | 1 | [Rattlehorn](sols/rattlehorn.md) |
| Frostbound | 3 | 1 | [Rimefold](sols/rimefold.md) |
| Warborn | 3 | 0 | [Browguard](sols/browguard.md) |
| Blight | 3 | 0 | [Bitterfrill](sols/bitterfrill.md) |
| Earthbound | 3 | 0 | [Knucklemole](sols/knucklemole.md) |
| Zephyr | 3 | 0 | [Sailcrest](sols/sailcrest.md) |
| Mindweaver | 3 | 0 | [Glass-Throat](sols/glass_throat.md) |
| Chitin | 3 | 0 | [Claspback](sols/claspback.md) |
| Eldritch | 3 | 0 | [Foldling](sols/foldling.md) |
| Wraith | 3 | 0 | [Mournveil](sols/mournveil.md) |
| Wyrmkin | 3 | 0 | [Pebblewyrm](sols/pebblewyrm.md) |
| Umbral | 3 | 0 | [Shadepelt](sols/shadepelt.md) |
| Construct | 3 | 0 | [Kilnling](sols/kilnling.md) |
| Feyborn | 3 | 0 | [Thimblehart](sols/thimblehart.md) |

**Total:** 54 concepts, 6 explicit approvals, 48 proposals. This is a creative
coverage target, not 54 implemented species or 54 approved three-form families.

### Authored lineage index

No lineage briefs populated yet. Add rows with these columns when authoring begins:

| Working lineage / ID | Primary class | Ordinary species in order | Habitat / adventure placement | Design status | Brief |
| --- | --- | --- | --- | --- | --- |

### Authored species index

Eighteen concepts now have connected first-form runtime resources: six with explicit
concept approval and twelve proposed candidates selected for playable class coverage.
Their IDs are stable runtime species keys; numerical values remain pilot tuning.
All names are placeholders. Use the linked sheet as the canonical detailed record.

| Species / draft ID | Lineage / stage | Class | Design / delivery status | Production sheet |
| --- | --- | --- | --- | --- |
| Crown-Ear / `sol_species_0001` | `sol_lineage_0001` / first of proposed three forms | Beast | Concept approved; data, articulated blockout, procedural ground/low flight integrated | [Crown-Ear](sols/crown_ear.md) |
| Reedback / `sol_species_0002` | `sol_lineage_0002` / first of proposed three forms | Abyssal | Concept approved; data, articulated blockout, procedural ground/surface swimming integrated | [Reedback](sols/reedback.md) |
| Bellroot / `sol_species_0003` | `sol_lineage_0003` / first of proposed three forms | Bloom | Concept approved; data, articulated blockout and procedural ground movement integrated | [Bellroot](sols/bellroot.md) |
| Ashquill / `sol_species_0004` | `sol_lineage_0004` / first; final family count open | CinderKin | B selected; small/cute first-form data, ground blockout, capture, following and menu integration | [Ashquill](sols/ashquill.md) |
| Rattlehorn / `sol_species_0005` | `sol_lineage_0005` / first; final family count open | Stormforged | B selected; small/cute first-form data, ground blockout, capture, following and menu integration | [Rattlehorn](sols/rattlehorn.md) |
| Rimefold / `sol_species_0006` | `sol_lineage_0006` / first; final family count open | Frostbound | B selected; small/cute first-form data, ground blockout, capture, following and menu integration | [Rimefold](sols/rimefold.md) |
| Browguard / `sol_species_0007` | `sol_lineage_0007` / first; family count open | Warborn | Provisional playable coverage; distinct small model, catalog and normal sighting | [Browguard](sols/browguard.md) |
| Bitterfrill / `sol_species_0008` | `sol_lineage_0008` / first; family count open | Blight | Provisional playable coverage; distinct small model, catalog and normal sighting | [Bitterfrill](sols/bitterfrill.md) |
| Knucklemole / `sol_species_0009` | `sol_lineage_0009` / first; family count open | Earthbound | Provisional playable coverage; distinct small model, catalog and normal sighting | [Knucklemole](sols/knucklemole.md) |
| Sailcrest / `sol_species_0010` | `sol_lineage_0010` / first; family count open | Zephyr | Provisional playable coverage; distinct small model, catalog and normal sighting | [Sailcrest](sols/sailcrest.md) |
| Glass-Throat / `sol_species_0011` | `sol_lineage_0011` / first; family count open | Mindweaver | Provisional playable coverage; distinct small model, catalog and normal sighting | [Glass-Throat](sols/glass_throat.md) |
| Claspback / `sol_species_0012` | `sol_lineage_0012` / first; family count open | Chitin | Provisional playable coverage; distinct small model, catalog and normal sighting | [Claspback](sols/claspback.md) |
| Foldling / `sol_species_0013` | `sol_lineage_0013` / first; family count open | Eldritch | Provisional playable coverage; distinct small model, catalog and normal sighting | [Foldling](sols/foldling.md) |
| Mournveil / `sol_species_0014` | `sol_lineage_0014` / first; family count open | Wraith | Provisional playable coverage; distinct small model, catalog and normal sighting | [Mournveil](sols/mournveil.md) |
| Pebblewyrm / `sol_species_0015` | `sol_lineage_0015` / first; family count open | Wyrmkin | Provisional playable coverage; distinct small model, catalog and normal sighting | [Pebblewyrm](sols/pebblewyrm.md) |
| Shadepelt / `sol_species_0016` | `sol_lineage_0016` / first; family count open | Umbral | Provisional playable coverage; distinct small model, catalog and normal sighting | [Shadepelt](sols/shadepelt.md) |
| Kilnling / `sol_species_0017` | `sol_lineage_0017` / first; family count open | Construct | Provisional playable coverage; distinct small model, catalog and normal sighting | [Kilnling](sols/kilnling.md) |
| Thimblehart / `sol_species_0018` | `sol_lineage_0018` / first; family count open | Feyborn | Provisional playable coverage; distinct small model, catalog and normal sighting | [Thimblehart](sols/thimblehart.md) |

### Legendary manifestation index

No manifestation briefs populated yet. Track these separately from ordinary forms:

| Manifestation | Associated lineage | Primordial individual | Counting decision | Design status | Brief |
| --- | --- | --- | --- | --- | --- |

## Coverage and first design batch

Owner direction, October 28, 2026 supersedes the earlier proposed six-lineage
batch: distribute initial ideas across classes, starting with three per class.
See [working classes for review](#working-classes-for-review) for the selected
class names and approval status of the first sketches. Category boundaries
and individual species remain subject to review.

The initial three-per-class concept pass is populated. Next, review these designs
in manageable class batches, refine boundaries, and develop selected full briefs.
The 54 concept slots are not an immediate implementation commitment. Choose the
representative playable slice separately. Rescue/starter assignments remain open;
existing prototype species are retained only by deliberate choice.

For each batch, assess coverage across:

- Creature silhouettes, sizes, body plans, locomotion, and animation needs.
- Habitats and ecological contributions, including relationships with human use
  of Vastra and with other Sols.
- Temperaments, observation opportunities, and companionship expressions.
- Tactical strengths, exploitable weaknesses, learnsets, and class coverage.
- Early, middle, and late adventure discoveries; common, uncommon, and notable
  encounters, with numerical rates left to explicit tuning.
- Evolutionary continuity and the total production workload across all forms.

Beyond the initial three-per-class target, coverage is a review aid rather than
a quota requiring every possible combination.

## Production integration plan

Prepared October 28, 2026 following the owner's scope questionnaire. The scope
below is explicit owner direction. Species selection, implementation sequence,
module boundaries, and acceptance details are proposals until adopted; this plan
does not itself implement features or resolve unspecified movement/combat rules.

### Owner-selected scope

- Treat the 54 concepts as candidates. Select/develop families that fit the
  151-entry target rather than making every concept a three-form family.
- Test three contrasting approved species together before standardizing their
  production structure.
- Include ground movement, flight, and swimming in the first playable slice.
- Deliver readable routines and companion interactions first. World-changing
  ecological effects follow later.
- Use distinct simple 3D species models and essential animations, then refine
  them after testing. All species names remain placeholders.
- Owner addition: Sols need procedural movement. Include procedural locomotion
  in this first slice; the implementation approach below is proposed.

### Proposed pilot trio

| Approved concept | Class | Proposed test role |
| --- | --- | --- |
| Crown-Ear | Beast | Batlike anatomy, air movement, takeoff/landing, and listening behavior. Uses the documented bounded-low-flight working default; no automatic immunity or obstacle bypass. |
| Reedback | Abyssal | Ground/water movement, shoreline transitions, plate/grooming animation, and an amphibious companion. |
| Bellroot | Bloom | Ground movement, root-foot placement, leaf-closing rest, and readable tending gestures. |

This is a proposed implementation selection, not selection of the three storm
rescuers or an approval of starter roles. First-form models are the initial asset
scope; ordinary evolution plans must be recorded, but nine finished models are
not a prerequisite for testing these three forms.

### Phase 1 — complete three production sheets and record a baseline

Populate each selected species' stable species/lineage IDs, class mapping,
ordinary form, dimensions, footprint, movement modes, reference-level six stats,
growth, explicit learnset, starting equipped moves, behavior profile, encounter
placement, art/animation requirements, and an ordinary evolution outline.
Separate fixed species data from saved individual affinity, potential, ownership,
and relationship history. Stable IDs must not depend on finalizing display names.

Before prescribing new mechanics, consult relevant source implementations,
callers, tests, and later decisions under the mechanics-reference procedure.
Record the exact source revision and unresolved design conflicts. Godot retains
world-generation and terrain authority. Capture current connected expedition
behavior and relevant rendered performance as the comparison baseline.

Deliverable: three reviewable production sheets, a dependency/gap register, and
source/baseline evidence. Keep uncertain tuning explicitly provisional.

### Phase 2 — connect authored species data

Build on the existing Godot taxonomy, battle profiles, move library, ecology
profiles, and behavior hierarchy. Provide a consistent species lookup connecting
those resources to encounter content and visual scenes. Validate duplicate IDs,
missing references, class mappings, move eligibility, and lineage relationships.
Replace pilot-specific hardcoded content connections through this authoring path.

Expose approved display names over existing class IDs without silently rewriting
saved identities. Keep Eldritch's new identity/passive work explicit and separate
from this pilot, whose classes already have runtime counterparts. Review roster
admission ceilings, including the move library's current 64-species pool ceiling,
against the intended final roster before broad expansion; do not blindly remove
validation ceilings or treat them as balance controls.

Deliverable: all three pilots can be admitted and referenced through the same
authored data structure, with saved individual traits preserved.

### Phase 3 — simple species models and essential animation

Produce recognizable models for the pilot trio at agreed dimensions. Supply idle,
travel, rest, alert, attack, hit/recovery, and one signature interaction as needed;
add takeoff/landing or swimming transitions for the relevant bodies. Reuse rigs
where practical while retaining distinct silhouettes and motion.

Author rigs with the joints/contact points needed for procedural locomotion:
feet and body supports, wings, tails, and relevant flexible appendages. Identify
which poses are generated, which are authored, and how the two blend. Agree on
rig requirements before producing models so locomotion does not require redoing
otherwise finished assets.

Connect the same species model selection to exploration, combat, and the Sol menu
preview. Fit bounds to actual models, maintain individual affinity readability,
and document asset provenance. Models and animation remain presentation; they do
not own simulation positions, movement permissions, identity, or encounter state.

Deliverable: three identifiable creatures in all existing presentation contexts.

### Phase 4 — ground, flight, and swimming

Specify movement permissions before coding: legal destinations and occupancy,
body clearance, takeoff/landing, air height and blockers, water access, shoreline
entry/exit, follow/return behavior, encounter transitions, pause, and save/load.
Distinguish visual altitude from authoritative movement state. Do not infer flight
or swimming from class, animation, individual affinity, or the existing flee action.

Extend bounded navigation against Godot's actual terrain/traversal contract and
keep movement rules consistent across wild and owned pilot individuals. Define
how water/air states enter combat and recovery; any unresolved advantage, immunity,
mounting, or player shortcut requires its own supported design decision.

Deliverable: a connected test route with ground, air, and water movement plus
legal transitions, without clipping or identity/state loss. Use available Godot
terrain; the slice does not authorize replacing the generator.

### Procedural locomotion requirement

Owner direction, October 28, 2026: add procedural movement for Sols. Working
interpretation: responsive bodily locomotion and secondary motion, alongside the
existing autonomous navigation and behavior work. This is a species-production
requirement; specific algorithms and tuning below are implementation proposals.

Use a shared locomotion framework configured by species anatomy and movement
mode. Class and affinity do not determine limb count, gait, wing use, or swimming
style. Generate motion from actual travel, acceleration, turning, terrain contact,
and behavior intent, with authored clips for attacks, reactions, transitions, and
signature gestures where they provide better control.

| Proposed pilot | Procedural movement emphasis |
| --- | --- |
| Crown-Ear | Wingbeat cadence responding to travel, banking during turns, body settling on takeoff/landing, and responsive head/listening-crown motion. Exact aerodynamic behavior is not established. |
| Reedback | Alternating grounded steps and planted feet, body weight shift, terrain-aware posture, swimming limb/tail motion, and damped back-plate/reed movement. |
| Bellroot | Root-foot placement, stride and cadence tied to actual speed, body compression/sway, and restrained leaf follow-through during starts, turns, and stops. |

Keep authoritative navigation, collision, identity, encounters, and combat timing
in the gameplay systems. Procedural poses follow committed movement and must not
create extra travel, damage, obstacle bypass, ownership changes, or state rerolls.
Visual foot placement must not move the authoritative body onto illegal ground.
Rebuild transient pose state safely on load; handle pause, menu preview, combat
entry/exit, culling, and state replacement without old pose state leaking across
individuals. Distinguish free-flight navigation decisions from visual wing motion.

Store connected species locomotion tuning in typed Godot resources with Inspector
tooltips, ranges, units, and documented application timing. Candidate settings
include body/limb proportions, stride, cadence, foot lift/planting, lean, wingbeat,
swim undulation, appendage damping, and transition timing. Expose only controls
actually used by the implemented species, not every possible future anatomy.

Acceptance should inspect straight travel, corners, slopes, starts/stops,
blocked movement, resting, ground/air/water transitions, following, attacks,
pause/resume, and save/load. Look for foot sliding, floor penetration, snapping,
excessive bobbing, and incoherent limb timing. Compare rendered costs with the
same workload and use distance/visibility-based detail scaling; bounded work and
eventual AYN Thor acceptance remain required. Do not add random jitter as a
substitute for readable weight and responsive motion.

### Phase 5 — readable life and companionship

Connect two or three routines per species to the existing behavior hierarchy,
using shared actions and species-specific tuning/animation. Include readable
player reactions and an owned follow/wait/resume interaction with a curiosity or
resting moment. Distinguish behavior intent from its visual performance.

Examples are Crown-Ear orienting its listening crown, Reedback grooming its back,
and Bellroot inspecting a bent plant. These do not add soil restoration, seed
simulation, weather effects, compulsory care, or unapproved numerical trust rules.

Deliverable: each pilot feels distinct while wild and while accompanying the
player, with no decorative interaction silently changing ecological state.

### Phase 6 — connected validation and structure review

Exercise encounter, observation, existing capture/acquisition, party/storage,
companion travel, combat, move learning/equipment, model preview, pause, and
save/load across all three species. Add meaningful checks for resource references,
identity/affinity continuity, legal navigation, movement-mode transitions,
procedural pose lifecycle, and preview isolation. Run the required Godot validator and rendered feature checks.

Compare relevant frame-time, memory, streaming, and simulation costs against the
same baseline workload; keep AI/navigation/animation work bounded. Record controller
usability and eventual AYN Thor device acceptance separately from desktop results.
Owner review must assess appearance, movement, reactions, and attachment together.

Deliverable: test evidence, demonstrated connected play, measured limitations,
and a revised authoring template based on three genuinely different bodies.

### Expansion after the pilot

Apply the tested structure to reviewed candidates in manageable batches. Choose
families and ordinary stages while reconciling the 150 ordinary entries plus the
additional Sol, then assign journal numbers. Detail evolution species and their
assets as they enter production. Plan world-changing ecology, remaining specialist
traversal, Eldritch mechanics, and legendary manifestations as explicit follow-on
work. Do not claim the whole roster is implementation-ready from concept coverage.

## Pilot production sheets

Step one started October 28, 2026. Three canonical draft sheets are populated:
[Crown-Ear](sols/crown_ear.md), [Reedback](sols/reedback.md), and
[Bellroot](sols/bellroot.md). The species concepts/classes were approved earlier;
role and flight defaults are documented under proceed direction, and numerical
profiles remain adjustable pilot tuning. Step-one preparation is complete and
step-two data integration is connected. IDs are runtime species keys, not journal
numbers or replacements for existing prototype identities.

### Working defaults adopted after proceed direction

The owner instructed the agent to proceed after reviewing the draft status. Use
the recommended pilot defaults rather than keeping unanswered optional questions
as blockers. This is an implementation-planning assumption under that direction,
not a claim that the owner separately selected each numerical value.

- Crown-Ear: fast physical disruption, ground movement plus bounded low flight,
  legal dry landing locations, and obstacle/body-clearance validation.
- Reedback: durable physical defense, grounded travel and surface swimming with
  explicit legal shoreline entry/exit. Diving remains outside the pilot scope.
- Bellroot: support/battlefield control, grounded root-foot movement, and visual
  tending behavior without world-changing ecological effects.
- Keep draft level-3 stat profiles, seven-move pools, first-form dimensions, and
  shared growth as reversible starting tuning. Actual models/rigs will determine
  final contact points and geometry. All display names remain placeholders.

### Pilot production contract

The following contract separates established mechanics from draft authoring:

- **Identity:** keep stable individual ID, species/lineage/class, and ordinary form
  distinct. Affinity is an individual trait, not a species lock. Do not copy a
  prototype starter's fixed affinity into the species definition. `BattleProfile`
  currently includes affinity, so any eventual species authoring adapter must
  supply the actual individual's saved value when constructing an instance.
- **Stats:** six reference-level species values are proposed at level 3 before
  IVs/training. Existing independent potential rolls, training caps, and saved
  class potency remain authoritative. Prototype growth is +2 HP and +1 to each
  other stat per level; no new formula or separate stat-growth budget is added.
  Speed affects initiative separately from movement allowance.
- **Moves:** each sheet has seven explicit eligible moves, four initially learned
  and equipped, with three further moves at prototype levels 4, 8, and 14. All
  reuse current move IDs and effect definitions. Every move has its own affinity,
  independent of the individual's. These pools/learning conditions are draft
  content, not approved numerical balance or a full release learnset.
- **Abilities:** use the existing primary-class passive. Do not silently layer
  a new species innate bonus onto it. Signature innate abilities remain a later
  authoring decision; the pilot does not require an unimplemented ability system.
- **Behavior:** keep the existing idle fallback, patrol branch, and at most one
  response primitive per profile. Species listening/grooming/tending can specialize
  those branches in animation. Novel interactions and companion commands require
  implementation; a prose description is not evidence they already run.
- **Evolution:** first-form sheets propose three-stage lineages under the approved
  small/medium/large rule. Later IDs, precise dimensions, stats, triggers, and
  journal entries remain open. Existing authored evolution preserves birth/individual
  identity, class, affinity, potential, training, potency, and learned/equipped moves.
- **Movement:** navigation and committed state own legal travel. Procedural poses
  follow them. Ground/air/water state, clearance, legal transitions, and encounter
  admission need explicit integration; animation cannot grant movement permissions.
- **Tuning:** dimensions, stat tables, pools, placement levels, and species
  preferences are proposed. Implement only connected Inspector controls, document
  application timing, and preserve already saved individual traits.

### Step-one evidence and baseline inventory

Local checkout inspection: HEAD `96f384ffbd12c227b964b5f433a76901e8c3879f`
with substantial pre-existing working-tree changes on `codex/cohesive-world-sample`.
This is a working-tree inspection, not validation of a clean committed build.
Preserve other contributors' work. These files were read to establish current
contracts; their automated suites were not rerun. A rendered baseline attempt was
subsequently collected, with environment errors detailed below.

| Evidence | What it establishes for these drafts |
| --- | --- |
| `scripts/sol_species.gd`, `scripts/sol_identity.gd` | Existing taxonomy and stable individual identity contracts. |
| `scripts/battle_profile.gd`, `scripts/sol_stats.gd`, `scripts/progression_settings.gd` | Six reference-level stats, saved growth/potential, current prototype progression, separate initiative and movement. |
| `resources/move_library.tres`, `scripts/move_library.gd`, `scripts/sol_move.gd` | Existing effect IDs/affinities, explicit pools and starting moves, four-slot equipment, 4/8/14 prototype unlock policy through progression settings. |
| `scripts/sol_ecology_profile.gd`, `scripts/sol_behavior_definition.gd`, `resources/sol_ecology/behavior_library.tres` | Current profile/branch validation and species specializations over implemented actions. |
| `scripts/expedition_state.gd`, `tests/sol_stats_and_classes.gd` | Authored evolution and preservation checks; read, not rerun in this authoring pass. |
| `scripts/sol_local_navigation.gd`, `tests/sol_natural_movement.gd` | Current bounded traversal callback, pose/movement lifecycle checks; neither provides a complete new air/water mode contract. |
| Source commit `115f3e87acc1716c7113523567c01e1666681885`: `src/systems/ai/behavior.py`, `src/systems/world/ecology_profiles.py`, `tests/test_ecology_profiles.py`, `src/systems/tactics/sol_combat.py` | Read-only baseline: bounded legal movement, temperament/behavior whitelist, independent identity variation, four valid equipped moves. Older neutral-move/affinity/balance proposals do not override later owner decisions. |

These inspected source paths do not settle the new flight/swimming permissions;
the pilot contract below uses explicitly documented working defaults.
Recheck relevant callers, tests, and later source decisions before implementation.
Godot remains the terrain/world-generation authority.

### Rendered baseline attempt — October 28, 2026

Used the existing `tools/profile_current_expedition.gd` journey in two fresh
rendered processes, capped at 60 and uncapped, with pinned Godot
`4.7.2.stable.official.ed1daf0bf`, D3D12/Forward+, RTX 3070, and a 2560 × 1369
viewport. Existing route behavior, rather than the unimplemented pilot species,
was exercised. Both runs exited zero, recorded one automatic Sol contact, and
reported zero journey assertion failures, including pause and save/new/load
identity continuity. This is not combat, pilot-species, owner, or Thor acceptance.

| Run | Outbound p95 / p99 (ms) | Return p95 / p99 (ms) | Save / load (ms) |
| --- | --- | --- | --- |
| 60 FPS cap | 16.684 / 21.167 | 16.679 / 18.025 | 19.424 / 721.457 |
| Uncapped | 5.967 / 15.209 | 6.171 / 14.240 | 16.370 / 691.532 |

**Not a clean performance acceptance:** the standard profiling wrapper stopped
before launch because Windows denied its hardware-information query
(`Get-CimInstance`). The same existing rendered journey was then launched directly
with its normal arguments and hidden windows. Both direct runs emitted errors
writing `user://logs/godot.log` and creating the shader-cache directory. No cache
purge was performed. Missing shader caching can affect frame time and startup;
do not compare these figures as a clean before/after baseline or treat zero
assertion failures as an error-free engine run.

Local ignored evidence: `artifacts/current_expedition/sol_production_step1_20261028_a/`
contains `cap60-run1` and `cap0-run1` profiles, screenshots, stdout/stderr, and
test expedition files. The standard wrapper's full hardware/process-memory and
source-before/after manifest was not produced. Resolve writable log/cache access
and rerun the existing wrapper with source-stability and hardware metadata before
accepting a clean implementation-comparison baseline. No performance budget or
stable-source-run claim is made from this attempt.

### Step-one gap register

| Gap | Status / next action |
| --- | --- |
| Physical scale rule | Resolved by owner: three forms small/medium/large, two forms varied, non-evolving species fixed size. Numeric pilot dimensions remain proposed. |
| Combat-role split | Owner explicitly approved this starting design on October 28: fast/disruptive Crown-Ear, durable/physical Reedback, support/control Bellroot. Numerical tuning remains provisional. |
| Flight freedom | Owner explicitly approved low flight with bounded altitude, defined obstacle clearance and legal landing spots on October 28. See Crown-Ear's movement contract and the subsequent implementation record; numeric tuning remains provisional. |
| Swimming scope | Surface swimming and explicit legal shore transitions proposed. Diving, underwater encounters, and player transport have not been approved. |
| Air/water combat admission | Resolve against existing encounter/deployment rules before coding; do not infer immunities or force unsafe landings. |
| Models, rigs, and animation | Species-specific assets not made. Data routes to the shared orb placeholder scene in exploration/combat/menu; contact rigs and procedural locomotion remain later work. |
| Species registration | Three runtime resources now implement the stable pilot IDs; shared lookup, existing-profile admission, ecology, movebooks and placeholder view routing are connected. Dedicated scenario uses explicit dry test homes; habitat generation is unchanged. |
| Later ordinary stages | Direction drafted only; later identities and triggers need authoring without inflating the 54-candidate count. |
| Runtime baseline | Verified with the corrected standard wrapper in capped/uncapped fresh processes: zero exit codes, no engine errors, and unchanged source manifests. Earlier restricted attempts remain historical evidence. See baseline verification below. |
| Experience/device acceptance | Not tested; require connected owner review and separate controller/Thor evidence. |

Step-one working production records are populated and the optional role/flight
questions are resolved by documented defaults under the owner's proceed direction.
Step one is **complete as a working-specification handoff** after the verified
rendered baseline below. Numerical values stay adjustable; implementation must
exercise the actual terrain, collision, movement-mode, and saved-state contracts
described in these sheets. This closes authoring/baseline preparation, not pilot
gameplay, final art, balance, or release acceptance.

### Verified baseline and step-one handoff

The existing standard profiler was rerun with normal Windows access so it could
read hardware metadata and write Godot logs/shader caches. Its first normal-access
attempt (`sol_production_step1_20261028_b`) completed an error-free capped journey,
but the wrapper lost the child process exit status and stopped. The previous
wrapper content was preserved locally before a focused correction.

`tools/profile_current_expedition.ps1` now caches the process handle immediately,
records exit status once, rejects a missing status, and disposes the process after
successful recording. This follows the documented redirected-process handle issue
in [PowerShell #5421](https://github.com/PowerShell/PowerShell/issues/5421).
Syntax validation passed. Redirected child-process checks returned the expected
exit statuses 0 and 7, so a failure is not silently coerced to success.

The corrected standard wrapper completed both fresh-process runs under
`artifacts/current_expedition/sol_production_step1_20261028_c/`. Both runs had
exit code 0, zero engine errors, zero journey assertion failures, and unchanged
source-before/after manifests. The whole-run source manifest also remained
unchanged; documentation was subsequently updated to record these results.

Hardware/configuration: AMD Ryzen 7 5800XT, 34,266,968,064 bytes reported system
memory, RTX 3070 (driver 32.0.16.1047), Windows 11 Pro, Godot
4.7.2.stable.official.ed1daf0bf, D3D12/Forward+, 2560 × 1369 viewport. One fresh
process per cap; OS/driver caches were retained. This is a development baseline,
not an approved numeric performance budget or a target-device qualification.

| Run | Outbound p95 / p99 / max (ms) | Return p95 / p99 (ms) | Save / load (ms) | Sampled peak process memory (bytes) | Automatic contacts |
| --- | --- | --- | --- | --- | --- |
| 60 FPS cap | 16.691 / 20.852 / 39.322 | 16.685 / 19.277 | 19.081 / 710.637 | 671506432 | 0 |
| Uncapped | 6.293 / 16.327 / 970.871 | 6.554 / 15.551 | 17.224 / 714.237 | 673140736 | 1 |

The uncapped outbound window includes a roughly 971 ms maximum sample. Its cause
is not established by this run; investigate frame-time spikes when comparing
implementation results rather than treating good percentile figures as smoothness
acceptance. Screenshots/route transitions are part of this existing profiling
workload, and no GPU-memory measurement or long-duration cache-turnover study is
included. The capped run had no contact; the uncapped run recorded one and
withdrew. Neither run establishes combat or new-pilot traversal acceptance.

**Step-one deliverables complete:** three linked working production sheets,
reserved authoring IDs, provisional six-stat profiles and explicit learnsets,
anatomy/rig/procedural movement requirements, behavior/encounter directions,
ordinary evolution outlines, mechanics evidence, a gap register, and a verified
current-expedition baseline. No new species resources, models, or gameplay systems
were implemented. Step two is species-data integration; maintain the documented
movement and source-reconciliation requirements when coding it.

## Step-two species data integration

Owner direction: proceed with step two after the production-sheet handoff. See
[species data integration](../sol-species-data.md) for the implementation contract,
Inspector controls, save timing, review scene, and source evidence.

The shared [runtime catalog](../../resources/sol_species/catalog.tres) now connects
Crown-Ear, Reedback, and Bellroot to taxonomy, explicit six-stat reference profiles,
lineage capacity, seven-move pools/four starting moves, species-default ecology,
and a presentation scene. Actual individual affinity is supplied at admission;
there is no species affinity property. Existing individual records and schema
contracts are preserved. Approved class display names do not rename saved class IDs.

Open [sol_species_pilot.tscn](../../scenes/sol_species_pilot.tscn) with F6 to review
the three additional explicit sightings at trail x=12, 18, and 34 beside the
original three. This scenario is separate from the ordinary expedition. It keeps
the current prototype starter choices and uses dry legal homes until air/water
navigation exists. The configured Air/Water/Fire affinities are individual fixture
values; Bellroot remains Bloom with Fire affinity. Step two used orbs; step three
below replaces them with articulated creature blockouts.

Step-two work does not implement actual bat/plant/amphibian models, procedural
locomotion, flight, swimming, ecology state changes, later ordinary forms, or the
narrative rescue/starter assignment. The new resources expose only connected data
controls. The finite species/move-pool ceiling is now 512, allowing the 151-entry
target without leaving admission unbounded. The 54-concept design roster remains
three per class and does not become 54 implemented lineages.

Validation includes actual admission, battles, capture, selection, preview, saved
trait preservation during authoring edits, and save/new/load for all three pilots.
Malformed/mismatched references and duplicate definitions reject. An isolated
pre-integration control and field-level bisection located shutdown retention in
the new sighting/registry references. The final lazy file lookup and concrete
runtime resource validation remove that retention without altering scenery code
or weakening engine-error detection.

**Step-two validation complete, October 28, 2026:** the full
`tools/validate.ps1` run passed, including import, the 93-check species suite,
geometry/generation checks and both scene journeys. A separate rendered D3D12
run passed 96 checks, including three dossier captures. All three images were
visually reviewed: correct species labels, individual affinities and orb previews.
Logs and images are local ignored evidence under
`artifacts/sol_species_integration/` (`validate.log`,
`catalog_rendered.stdout.log`, `catalog_rendered.stderr.log`, and
`sol_species_0001.png` through `sol_species_0003.png`).

**Step-two deliverables complete:** shared authored species records, catalog
validation, connected encounter/combat/move/ecology/presentation paths, an
isolated review scene, Inspector documentation and save/load coverage. This is
functional data acceptance; creature models and procedural movement require
their own implementation and playtesting in the following steps.

## Step-three creature models and essential poses

The pilot trio now selects distinct original 3D scenes: [Crown-Ear](../../scenes/sols/crown_ear.tscn),
[Reedback](../../scenes/sols/reedback.tscn), and [Bellroot](../../scenes/sols/bellroot.tscn).
These are reviewable primitive blockouts with articulated Node3D control chains,
four contact markers each, fixed species palettes and independent affinity effects.
They share the existing presentation factory across exploration, combat and menus.
Shape, size and palette are provisional art tuning; implementation does not imply
owner approval of finished art. See [model/rig documentation](../sol-creature-models.md)
for controls, provenance, timing and limitations.

Generated breathing, attention, rest/alert postures and species gestures provide
the first essential animation. Battle effect/damage cues connect attack and
hit/recovery accents plus the existing impact effects. Preview framing now uses
creature envelopes. No new saved data, movement permissions or combat mechanics
are introduced. These control rigs use rigid pieces; wing membrane deformation,
terrain foot planting and actual travel animation belong to step four. Flight,
swimming and their transitions remain unimplemented.

**Validation, October 28, 2026:** the full `tools/validate.ps1` run passed import,
all regression suites and both scene journeys. Final focused checks passed
90 model checks and 102 catalog/journey checks, including actual battle pose cue
routing without persistent state changes. The rendered catalog journey passed
105 checks and captured all three owned-party previews. The model studio render
passed 91 checks. Art remains a blockout; these results do not certify ground
contacts, traversal clearance, final animation or target-device performance.
Local ignored logs and the studio image live under `artifacts/sol_creature_models/`;
the updated party captures live under `artifacts/sol_species_integration/`.

## Step-four first slice — procedural ground movement

The shared pilot rigs now receive committed absolute route positions, actual
terrain samples and movement time. They turn toward travel, alternate support
groups, lift swing feet, hold planted world contacts and solve hip/knee chains
without changing simulation cells. Stopping settles the current step; pause,
encounter entry and camera rebasing do not generate footsteps. Culling/load and
relocations reset presentation history. Tactical movement records also drive
the creature presentation without adding a new rule or delay.

This completes the first **ground presentation** slice, not the full ground/air/
water traversal phase. Flight, swimming, shoreline transitions, air clearance,
movement-mode persistence and related encounter admission remain follow-on work.
The support solver clamps unreachable targets; extreme speed/tuning and new rigs
still require visual review. Detailed behavior and limitations are in
[procedural ground movement](../sol-procedural-ground.md).

Owner requested reusable authoring documentation while continuing production.
[Creating another Sol model](../creating-sol-models.md) now provides the complete
workflow: adapting a pilot, writing a distinct builder, importing original rigid
geometry, required joints/contact groups, scale/bounds, species registration and
acceptance. Its sample custom quadruped was compiled and exercised with the actual
support driver. The isolated [model workshop](../../scenes/sol_model_workshop.tscn)
lets the owner assign a scene and review rest, walking, turns and slopes using F6
without creating individuals or changing saves. A skinned skeleton still needs a
bone adapter; the current rigid-joint solver does not automatically retarget one.

Focused validation passed **222 ground checks** at 30/60/144 FPS, both 0.3 m/s
review speed and the normal 1.33 m/s expedition speed, including planted-contact
error below 2.5 cm on the flat fixture and independent contact samples/reach on
the moderate slope. The catalog journey passed **108 checks**, including actual
battle interpolation and frozen presentation retaining rule-owned cells. Six
actual workshop captures cover all three creatures on flat and sloped ground.
These results do not certify every terrain shape, extreme tactical dash speed,
new body plan or target device. The full `tools/validate.ps1` run passed import,
all regression suites and both scene journeys. A final rendered D3D12 run also
passed all 222 procedural ground checks. Logs, the verified authoring example
and six workshop captures are local ignored evidence under
`artifacts/sol_procedural_ground/`.

## Step-four flight and swimming

Wild Crown-Ear now has ground, takeoff, air and landing modes. Wild Reedback has
ground, water entry, supported wading, swimming and shore exit. Bellroot stays
grounded. Their species records admit movement policies independently of affinity;
saved roaming state retains policy, mode, origin cell, mode-start tick and any
request to return to land. Domain version is **15**, with save format **3**.

Flight uses bounded paths and conservative body/wing sweeps against published
scenery geometry, terrain and actor reservations. Unpublished geometry causes a
wait. Landing requires a legal dry supported cell and clear vertical corridor;
an occupied/blocked landing retains air rather than teleporting. Swimming uses
generated pond levels and supported shallow edges, with legal bank entry/exit.
Godot's terrain engine remains the generation authority, including its current
version-seven geography. No pond or shore is fabricated by species placement.

Procedural wingbeats, articulated membranes, tucked legs, movement pitch/bank,
limb strokes and steering tail now follow mode and active clock. Rest, ground
support and combat poses remain connected. The model workshop includes Flight
and Swimming exercises. The original [pilot scene](../../scenes/sol_species_pilot.tscn)
retains its trail homes; the separate [pond pilot](../../scenes/sol_traversal_pilot.tscn)
starts a fresh seed-17 review beside Reedback's deterministic generated bank.

Manual approach to an airborne/waterborne Sol requests a return toward land;
it does not freeze exploration into an invalid encounter. Existing arena legality,
capture rules and combat movement remain in force once grounded. This is wild
traversal; the separate [owned-companion integration](../owned-companion.md) now
also supports the pilot flight/swim policies. Tactical battle routing retains
its ground contract. Diving, riding, aerial combat and player
swimming are not implemented by this work.

See [flight and swimming](../sol-flight-and-swimming.md) for the authoring fields,
behavior, persistence, source evidence and limitations. The
[model creation guide](../creating-sol-models.md) now explains capability admission
and envelope review as well as the rig controls.

**Validation complete, October 28, 2026:** the shared `tools/validate.ps1` run
passed import, all suites, geography/geometry checks and both scene journeys.
Final focused acceptance passed **85 checks**, including actual save-file IO,
mid-transition restoration, normal AI in real scenery, paused flight banking and
the combined bank/downstroke clearance envelope. Rendered D3D12 acceptance passed
**87 checks**, with two in-game captures; two workshop captures were also reviewed.
Logs and images are local ignored evidence under `artifacts/sol_air_water/`.

Validation used isolated workspace-local editor/runtime data. The existing
runtime-optimization fixture was updated from seed 19, rejected by generation 7's
essential-route check, to verified-valid seed 42; its assertion now also verifies
that the new expedition actually commits before checking stale-job cancellation.
No route protection or validation error filter was weakened. These desktop
checks do not establish target-device performance or arbitrary-rig acceptance.

## Lineage brief template

Copy this template into [Design records](#design-records) when beginning a lineage.
Replace every `TBD` with authored content or a specific unresolved decision. Keep
one full species brief per ordinary form; avoid repeating shared lineage facts.

### Lineage: TBD

| Field | Entry |
| --- | --- |
| Working name / lineage ID | TBD; distinguish draft label from existing runtime ID |
| Design status | Concept / Proposed / Approved / Deferred |
| Decision evidence / date | TBD; approval applies only to the recorded scope |
| Primary class | TBD; note whether its name and boundary are provisional |
| Creature idea | TBD; one sentence describing what this living being is |
| Reason to include | TBD; what this family adds to the adventure |
| Distinction from nearest roster neighbor | TBD |
| Ordinary species sequence | TBD; link each species brief |
| Shared visual identity | TBD; silhouette motif, anatomy, materials, and recognizable continuity |
| Physical and ecological development | TBD; how each form changes its life and habitat role |
| Habitat and human relationship | TBD; benefits, conflicts, and misconceptions |
| Companionship identity | TBD; how this lineage expresses personality without erasing individual variation |
| Tactical progression | TBD; what changes through evolution and what remains recognizable |
| Evolution triggers | TBD; label levels/conditions as proposed until approved |
| Authored exceptions | TBD; secondary classes, unusual branches, or deviations requiring decisions |
| Legendary association | TBD or none proposed; link a separate manifestation brief |
| Production approach | TBD; shared rigs/tools, species-specific assets, dependencies |
| Open decisions / next action | TBD |
| References | TBD; canon sections and exact source revision/path where relevant |

## Species brief template

### Species: TBD

#### Record and identity

| Field | Entry |
| --- | --- |
| Working name / species ID | TBD; retain existing runtime ID if already present |
| Lineage / ordinary form | TBD; link lineage brief |
| Journal number | Unassigned |
| Design status | Concept / Proposed / Approved / Deferred |
| Delivery status | Unimplemented / Prototype / Production assets integrated / Validated |
| Approval evidence / date | TBD |
| Player-facing description | TBD; a short description of the creature |
| Defining appeal | TBD; why a player would remember or befriend it |

#### Body and presentation

| Field | Entry |
| --- | --- |
| Silhouette and anatomy | TBD; distinguish it at normal exploration camera distance |
| Size and footprint | TBD; separate visual dimensions from occupied gameplay cells |
| Materials and markings | TBD; recognizable independently of affinity effects |
| Locomotion and grounding | TBD; walk, hop, fly, swim, or other authored movement; flag unsupported traversal |
| Procedural locomotion profile | TBD; anatomical joints/contact points, gait, terrain adaptation, ground/air/water motion, secondary motion, clip blending, tuning, and detail scaling |
| Model and rig | TBD; paths when assets exist, otherwise production requirements |
| Animation needs | TBD; idle, travel, reactions, combat, companionship, and species-specific actions as applicable |
| Sound and expression | TBD |
| Individual variation / affinity presentation | TBD; preserve species readability and independent affinity |

#### Ecology, observation, and companionship

| Field | Entry |
| --- | --- |
| Habitat and encounter placement | TBD; use current Godot environments, flag unsupported habitats |
| Encounter availability / rarity | TBD; distinguish authored story encounters from ambient populations |
| Ecological contribution | TBD; describe observable activity and distinguish lore from implemented effects |
| Broad temperament | TBD; avoidant / neutral / assertive |
| Two or three readable behaviors | TBD; describe what the player actually sees |
| Social preferences | TBD; solitary, paired, or small group; mark unsupported social behavior |
| Individual variation | TBD; stable personality differences within species tendencies |
| Response to the player | TBD; approach, avoidance, warning, and respectful interaction cues |
| Companion personality moment | TBD; an observable action that establishes attachment |
| Discovery / journal / lore | TBD; information revealed through meeting or observation, with unapproved rewards/triggers labeled |
| Rescue or story role | TBD or none proposed; named individuals tracked separately from the species |

#### Combat and development

| Field | Entry |
| --- | --- |
| Primary class / authored secondary class | TBD; inherit ordinary primary class from lineage |
| Tactical purpose | TBD; an authored combat description, separate from class |
| Strengths and weaknesses | TBD; include meaningful counterplay and tradeoffs |
| Six-stat profile and growth | TBD; HP, Attack, Defense, Special Attack, Special Defense, Speed; identify reference level and provisional values |
| Class passive / species innate ability | TBD; keep each distinct from equipped moves and identify implementation dependencies |
| Learnset and learning conditions | TBD; list moves explicitly using the table below |
| Initial equipped moves | TBD; at most four, drawn from eligible learned moves |
| Evolution destination and trigger | TBD; link target brief, mark unapproved conditions |
| Evolution continuity | Preserve individual identity, affinity, potential, training, and learned/equipped move continuity under the approved contracts |

| Learnable move / ID | Assigned affinity | Learning condition | Tactical purpose / tradeoff | Approval / implementation status |
| --- | --- | --- | --- | --- |

#### Production and acceptance

| Field | Entry |
| --- | --- |
| Runtime resource / scene links | TBD; connect taxonomy, combat, ecology, learnset, and visuals |
| Unsupported features / dependencies | TBD; proposed behavior is not implementation evidence |
| Asset provenance and redistribution rights | TBD before tracking/publishing third-party source assets |
| Technical review | TBD; collision, footprint, navigation, animation, culling, menu preview, and affinity readability |
| Connected expedition review | TBD; encounter, observation, interaction, combat/capture, party/menu, save/load |
| Identity and evolution validation | TBD; relevant automated checks and actual results |
| Performance evidence | TBD; workload, revision, hardware, renderer, settings, and measured costs; target-device acceptance separately |
| Owner experience review | TBD; date, outcome, remaining changes |
| Open decisions / next action | TBD |
| Evidence | TBD; canon/decisions and exact source paths/commits used |

## Legendary manifestation template

Use a separate record when this association is relevant. Do not automatically
create one for every unfinished lineage or count it as an ordinary fourth species.

### Manifestation: TBD

| Field | Entry |
| --- | --- |
| Working name / record ID | TBD |
| Associated lineage and primordial individual | TBD |
| Design status / approval evidence | TBD |
| Natural force and narrative meaning | TBD |
| Vessel and relationship prerequisites | TBD; distinguish existing canon from proposed conditions |
| Appearance, behavior, and tactical change | TBD |
| Class and affinity continuity | Preserve individual affinity; any class exception must be explicitly authored |
| Choice and consequences | TBD; starter designs must respect the approved permanent refusal and survival direction |
| Roster / journal counting decision | Unresolved until explicitly decided |
| Assets, implementation dependencies, and acceptance | TBD |
| References / open decisions | TBD |

## Review and delivery

Design approval and implementation are separate facts. An existing prototype can
have unapproved final design; an approved design can remain unimplemented.

1. **Concept:** complete the creature idea, distinctive appeal, lineage direction,
   and intended place in the roster. Check overlap with existing candidates.
2. **Proposed design:** populate the full lineage and species briefs, identify
   unresolved decisions, and review the evolution sequence together. Values may
   remain explicitly provisional where balance work is still needed.
3. **Approved design:** record the owner's decision, date, and exact scope. A
   proposed batch or an approved general direction does not approve every detail.
4. **Playable prototype:** connect authored data and exercise the species through
   the representative expedition. Use Inspector tuning for implemented controls.
5. **Production integration:** supply species-specific assets and readable
   behaviors, verify asset provenance, and review the creature in the actual world
   and menus.
6. **Validated delivery:** record relevant automated results, connected playtest
   evidence, owner experience review, and material limitations. Record target-device
   performance/input acceptance separately; desktop success does not establish it.

Update the brief, index, counts, and relevant implementation/tuning documentation
as part of the same change. No species is release-ready merely because its row
exists or its isolated tests pass. Runtime content remains in Godot resources;
this Markdown document is its design reference, not a runtime registry.

## Design records

The initial species concept roster is populated below. Three detailed pilot
production drafts are linked in the species index; final production approval,
full later-stage lineages, and legendary briefs remain open. Use the templates
above for subsequent records and keep one canonical detailed sheet per species. If records later need separate files, retain this Bible as the index and
link the single canonical brief for each entry rather than maintaining duplicates.

### Initial creature concepts

Crown-Ear and Reedback received concept and class-placement approval in the
six-class review; Glass-Throat remains proposed. These sketches are not complete
briefs, runtime identifiers, or starter assignments. All names are placeholders.
Affinities, numerical stats, learnsets, and evolution conditions remain unassigned.
Observable natural-history ideas are design direction, not implementation evidence.

| Working label | Anatomy and silhouette | Observable personality / ecological idea | Ordinary evolution direction |
| --- | --- | --- | --- |
| Crown-Ear | A small, batlike, low-bodied creature with broad folded ears; the ear edges open into a circular listening crown around its face. Soft body and firmer ear ribs keep the feature tangible. | Tilts its whole crown toward quiet sounds, then looks back toward a companion. Searches beneath leaf litter and carefully replaces disturbed cover. Its abrupt, total stillness supplies the unsettling edge. | Folded listening ears develop into a structured crown, then a broad, elegant sensory mantle; preserve its listening posture and recognizable face. |
| Reedback | A squat marsh quadruped with overlapping back plates and grooves that collect damp sediment; sparse reeds grow between the plates. Broad feet and a low head give it a distinct horizontal silhouette. | Grooms the growth on its back and settles into shallow mud. Proposed habitat role: carries wetland seeds between resting places. Territorial display raises the plates and exposes the larger body beneath. | A few shallow plates become a substantial layered back; reed growth and mature anatomy form a recognizable moving patch of wetland. |
| Glass-Throat | A delicate upright creature on three short legs, with a rounded head above a translucent throat chamber containing visible suspended anatomical rings. Opaque outer tissue keeps it readable at distance. | Turns its internal rings toward vibrations, taps the ground, and folds its legs beneath itself when comfortable. Its first movement after listening can be unexpectedly quick. Habitat/ecological contribution needs further authoring. | A simple chamber develops into a taller, rib-supported resonating structure; retain three-point grounding and the internal ring motif. |

Review goal: judge appeal, originality, silhouette, bodily plausibility, and tone
before assigning roster roles or expanding a sketch into its complete lineage.

### First species review batch — concepts approved

The owner approved all six presented concepts on October 28, 2026: Crown-Ear
(Beast, explicitly batlike), Ashquill (CinderKin), Reedback (Abyssal), Bellroot
(Bloom), Rattlehorn (Stormforged), and Rimefold (Frostbound). All species names
remain placeholders. Crown-Ear and Reedback retain the sketches above; the four
additional records follow. These are approved concept directions, not complete
species briefs, final naming, starter assignments, or implemented roster content.

The approval covers the presented anatomy, personality, and broad evolutionary
direction. Detailed biology/ecology, individual evolution species, progression
conditions, combat specifications, and production assets still need authoring.
No numerical combat rules, resurrection system, weather effects, generation rules,
or legendary forms were established. Individual affinity remains independent.

#### Ashquill — CinderKin

- **Defining body:** a small, long-tailed bird with overlapping charcoal-textured
  feathers and a soft crest. Pale feather edges reveal the layering without
  requiring a permanent flame effect. It is an approved phoenix-inspired concept using
  the owner's reference; final species naming and detailed biology remain open.
- **Readable behaviors:** fluffs into a round silhouette before carefully
  smoothing its feathers; collects its shed down to line a sheltered nest.
- **Personality:** fussy grooming gives way to an unexpectedly composed, watchful
  stillness. A possible companion moment is settling beside a resting traveler
  and fussing over the ground before sitting.
- **Proposed ecology:** reuses shed insulating feathers in nests and sheltered
  resting sites. The connection between ash-shaped anatomy and CinderKin origin
  needs fuller lore authoring; a particular affinity is not required.
- **Evolution direction:** downy bird, then long-legged crested bird, then a broad
  phoenixlike silhouette with layered tail fans. Preserve the feather layering
  and grooming gestures. No automatic resurrection is inferred.

#### Bellroot — Bloom

- **Defining body:** a low, bell-shaped living bulb raised on four thick root
  feet. A crown of broad leaves hangs around its body; the plant tissue forms
  the creature itself rather than being carried by an animal.
- **Readable behaviors:** uses its root tips to disentangle crowded seedlings;
  closes its leaf crown around itself when settling to rest.
- **Personality:** patient, absorbed in small tasks, and quietly stubborn. A
  possible companion moment is straightening a bent plant before catching up.
- **Proposed ecology:** tends small patches of undergrowth. This is natural-history
  and animation direction; any measurable growth/restoration effect needs its own
  mechanics specification.
- **Evolution direction:** walking bulb, then arching leafy form, then a broad
  bell-shaped canopy supported by substantial root limbs. Preserve the low face
  and deliberate tending gestures.

#### Rattlehorn — Stormforged

- **Defining body:** a compact, sure-footed quadruped with short horns formed from
  loosely nested keratin rings and a mane of stiff, springy filaments. The rings
  can visibly tremble and softly knock together.
- **Readable behaviors:** braces all four feet and raises its mane as pressure
  shifts; tests exposed footing with a forefoot before crossing.
- **Personality:** bold in exposed places, cautious about unfamiliar footing. A
  possible companion moment is stepping ahead, testing a crossing, and waiting.
- **Proposed biology/ecology:** pressure-sensitive horn structures and a
  charge-responsive mane connect its body to storm conditions. Its movement across
  rocky ground and intrinsic storm relationship need further authoring. Weather
  detection or effects are not implemented by this concept.
- **Evolution direction:** small ringed horns develop into tall split structures
  framed by a substantial filament mane. Preserve the braced posture and audible
  ring motif. Its own affinity remains independent of atmospheric charge.

#### Rimefold — Frostbound

- **Defining body:** a low, long-bodied amphibianlike creature with fleshy,
  translucent side fins that overlap like a folded blanket. Opaque central tissue
  preserves readability; the folds are living anatomy rather than ice armor.
- **Readable behaviors:** wraps its side fins closely around itself at rest;
  presses through loose snow using its low body and broad forelimbs.
- **Personality:** unhurried and tactile. A possible companion moment is unfolding
  one fin to investigate a nearby object, then carefully drawing it back.
- **Proposed ecology:** moves through cold wetland margins and snow pockets,
  maintaining shallow routes through loose surface cover. This does not add snow
  terrain, digging, collision changes, or habitat generation.
- **Evolution direction:** small folded fins become layered body-length mantles,
  then a broad, shield-shaped mature silhouette. Retain its low gait and wrapping
  behavior; cold-adapted anatomy does not mandate an individual affinity.

**Review status:** carry forward these six approvals while reviewing the
complete concept roster below. Develop full briefs in a separate pass and seek
feedback on material departures from approved concepts. Names and starter/story
roles remain open.

### Second species review batch — proposed

One concept each for Warborn, Blight, Earthbound, Zephyr, Mindweaver, and Chitin.
All names are placeholders. These sketches await owner feedback; approval of the
first batch does not extend to this one. No new runtime behavior, class passive,
combat effect, generation rule, or progression condition is established here.
Individual affinity remains independent of anatomy and class.

#### Browguard — Warborn

- **Defining body:** a stocky, calf-headed biped with a broad padded brow, short
  horns, thick forearms, and heavy hind feet. Its anatomy draws on the owner's
  minotaur reference; it does not wear manufactured armor or carry a weapon.
- **Readable behaviors:** practices controlled pushing against fallen logs;
  lowers its head and plants its feet when something approaches its space.
- **Personality:** proud, easily challenged, and capable of surprising gentleness.
  A possible companion gesture is leaning its padded brow against a trusted hand.
- **Class and ecological direction:** ritual contest and bracing anatomy develop
  the martial identity. Proposed natural history includes opening passages through
  fallen brush, without adding destruction or terrain mechanics.
- **Evolution direction:** a compact horned youngster develops a strong neck and
  forearm ridges, then an imposing minotaur silhouette. Keep the padded brow and
  deliberate bracing recognizable. Centaur-inspired designs remain available for
  a different future concept rather than combining both references automatically.

#### Bitterfrill — Blight

- **Defining body:** a soft-bodied, sluglike creature with a high folded dorsal
  frill and a blunt face. Rounded glands sit along the frill's edge; the silhouette
  reads as a rippling sail above a low creeping body.
- **Readable behaviors:** grazes decomposing plant matter; raises its frill and
  curls inward when disturbed.
- **Personality:** quiet and deliberate, with a suddenly conspicuous warning
  display. A possible companion gesture is settling nearby with its frill relaxed.
- **Class and ecological direction:** proposed toxin-producing biology and
  processing decaying growth tie its identity to Blight. Exact toxins, exposure,
  combat effects, and handling rules are unassigned.
- **Evolution direction:** one folded frill becomes a layered mantle with clear
  gland structures. Preserve the creeping gait, soft face, and change between
  relaxed and warning silhouettes.

#### Knucklemole — Earthbound

- **Defining body:** a low molelike creature whose oversized forepaws fold under
  its chest. Broad, shovel-shaped claws frame a small nose and recessed eyes.
- **Readable behaviors:** tests soil with its nose and forepaws; pushes loose earth
  aside in short, deliberate strokes before resting against the resulting bank.
- **Personality:** determined and tactile. A possible companion gesture is gently
  examining a boot with its broad paw before leaning against it.
- **Class and ecological direction:** subterranean anatomy and soil movement define
  its identity. Proposed activity aerates loose soil; actual digging, tunnels,
  terrain mutation, and traversal remain separate unimplemented features.
- **Evolution direction:** enlarged paws develop into powerful digging forelimbs
  and a wedge-shaped mature body. Preserve the tucked-paw resting posture and
  small, investigative nose; mineral armor is not needed to establish its class.

#### Sailcrest — Zephyr

- **Defining body:** a light-bodied gliding creature with broad wing membranes,
  small grasping feet, a narrow face, and a tall flexible steering crest along
  its tail. The wings and tail create a distinct kite-shaped silhouette.
- **Readable behaviors:** spreads its membranes and adjusts its tail before
  launching from a perch; folds around the perch when resting.
- **Personality:** alert and inquisitive, repeatedly tilting its body to inspect
  things below. A possible companion gesture is returning to a nearby perch and
  briefly spreading its wings toward the traveler.
- **Class and ecological direction:** specialized lift and steering anatomy make
  aerial life central to the proposed species. Proposed habitat is wind-exposed
  canopy and cliff edges; foraging airborne seeds and small insects provides an
  ecological direction for review. No flight navigation, travel shortcut, or Air affinity is
  guaranteed by this concept.
- **Evolution direction:** a broad-winged glider develops longer wing fingers and
  a sweeping tail crest. Keep the kite outline and tail-led turning motion.

#### Glass-Throat — Mindweaver

- **Defining body:** preserve the original three-legged form and translucent
  throat chamber with suspended anatomical rings. Add a proposed extrasensory
  identity: the rings orient in response to nearby emotional tension, rather than
  simply serving as sound detectors.
- **Readable behaviors:** stills and aligns its rings toward an unsettled creature;
  folds down beside a calm companion, its chamber pulsing in a slower rhythm.
- **Personality:** attentive and disconcertingly perceptive. A possible companion
  moment is settling beside the player before an outward sign of distress.
- **Class and ecological direction:** unusual perception supports Mindweaver.
  Proposed habitat is sheltered woodland hollows, with fallen-fruit foraging
  supporting seed dispersal. These additions remain for review. Emotion sensing is a
  proposed narrative/animation motif, not approved mind reading, control, status
  effects, or a gameplay detection system.
- **Evolution direction:** expand the throat chamber into a tall, rib-supported
  resonating structure while retaining three-point grounding and internal rings.
  This develops the existing concept rather than creating a thirteenth species.

#### Claspback — Chitin

- **Defining body:** a broad, six-legged beetlelike creature with overlapping back
  plates and hooked forelimbs. The forelimbs close together like a clasp; small
  feelers remain visible above them.
- **Readable behaviors:** folds and clips fallen leaves into a shelter; scrapes
  debris from the joints of its forelimbs after carrying material.
- **Personality:** industrious and particular about its resting place. A possible
  companion gesture is repeatedly bringing a leaf to the same favored camp spot.
- **Class and ecological direction:** articulated exoskeleton and specialized
  forelimbs establish Chitin identity. Shelter-building is proposed natural
  history; colony simulation, construction systems, and inventory collection are
  not introduced. This species can be solitary.
- **Evolution direction:** small clasping forelimbs develop into substantial,
  arching structures above a layered carapace. Preserve the broad body and closing
  gesture so the mature form feels related to the first.

**Review status:** the owner gave positive directional feedback and authorized
populating the Bible. Individual approvals for this batch are not yet recorded.
The expansion below covers the remaining classes and second/third concepts.

### Full initial roster expansion — proposed

Owner direction: populate the Bible following class review and positive feedback
on the second batch. These forty-two additions complete three concepts in each of
eighteen classes. Existing approvals are preserved; authorization to develop the
roster does not approve each new design. All names remain placeholders.

Each record specifies anatomy, two observable behaviors and a companionship
gesture, habitat/ecological direction, and ordinary evolutionary continuity.
These are proposed natural-history and presentation ideas, not runtime systems.
Affinity remains independent; class placement remains reviewable. Habitat mentions
do not add world-generation rules or establish terrain availability.

Evolution directions explore visual continuity. They do not assign additional
species, levels, secondary classes, legendary forms, or final journal numbers.
If all 54 concepts became separate three-form families, 162 ordinary entries would
exceed the 150-ordinary-entry target. Reconcile selection, evolutionary grouping,
and scope before developing the final numbered roster; do not silently expand it.

Numerical stat profiles, growth, passive/innate ability definitions, learnsets,
evolution triggers, encounters, trust interactions, footprints, assets, and
performance acceptance remain future brief work under existing mechanics
references. No new formula or gameplay subsystem is approved by this population.

#### Additional Beast concepts

##### Tumbletusk — Beast

- **Anatomy:** A round boar with a hinged snout shield and outward-curving tusks.
- **Behavior and companionship:** Rolls against trunks to groom; lifts its snout shield before investigating food. Offers its flank for a companion to scratch.
- **Habitat, ecology, and class fit:** Woodland margins; roots through fallen fruit and disperses seeds. Animal anatomy and social instincts define its class.
- **Evolution direction:** The facial plate and shoulders broaden; retain the snout-lifting and rolling gestures.

##### Ribbonhart — Beast

- **Anatomy:** A slender deerlike creature with branching antlers and flexible throat folds that fan into a social display.
- **Behavior and companionship:** Fans its throat folds to greet; freezes with one foreleg raised when uncertain. Matches a familiar traveler's pauses.
- **Habitat, ecology, and class fit:** Open woodland; browses shoots and carries burrs between clearings. The throat folds are living skin, independent of affinity.
- **Evolution direction:** The folds become a flowing mantle beneath an antler frame; retain the light gait and greeting display.

#### Additional CinderKin concepts

##### Cindercoil — CinderKin

- **Anatomy:** A short serpent with charcoal-textured scales, pale seams, and a broad ribbed hood.
- **Behavior and companionship:** Rubs loose scale flakes against stones; rests in a low spiral. Leaves space beside its coil near a familiar resting companion.
- **Habitat, ecology, and class fit:** Proposed ash-covered woodland edges; shed scales line shelters. Ash-related biology needs fuller lore without fixing individual affinity.
- **Evolution direction:** The hood develops layered ribs around a long sweeping body; preserve the spiral rest and pale seams.

##### Hearthback — CinderKin

- **Anatomy:** A low shell-backed reptile with porous dorsal ridges and a blunt expressive face.
- **Behavior and companionship:** Brushes debris from its back grooves; wedges beneath fallen timber to rest. Nudges bedding toward a preferred resting place.
- **Habitat, ecology, and class fit:** Proposed fire-scarred habitats; loosens brittle deadwood while foraging. This does not establish burning, heat damage, or mandatory Fire affinity.
- **Evolution direction:** The porous ridges become a vaulted layered back; retain the low face and careful bedding routine.

#### Additional Abyssal concepts

##### Sievefin — Abyssal

- **Anatomy:** A broad-headed swimmer with a fringed mouth, small elevated eyes, and large fanlike pectoral fins.
- **Behavior and companionship:** Fans sediment into its feeding fringe; folds its fins around itself at rest. Investigates a familiar hand with its fringe.
- **Habitat, ecology, and class fit:** Freshwater bottoms and sheltered estuaries; proposed filter feeding and sediment settling. Aquatic anatomy defines the class; filtration mechanics remain open.
- **Evolution direction:** The fringe and fins broaden into a graceful bottom-dwelling form; retain the wide face and deliberate fanning.

##### Tideknell — Abyssal

- **Anatomy:** A bell-headed soft-bodied swimmer with short grasping arms and a thick trailing mantle.
- **Behavior and companionship:** Grips shelter while watching currents; arranges shells around its resting hollow. Presents a shell to a familiar companion.
- **Habitat, ecology, and class fit:** Rock pools and submerged ledges; small-prey foraging and reuse of abandoned shells support an aquatic niche.
- **Evolution direction:** The mantle elongates and the arms develop patterned folds beneath a deep bell; retain shell arrangement and shelter-grasping.

#### Additional Bloom concepts

##### Sporecap — Bloom

- **Anatomy:** A mushroom-bodied creature with three thick stalk feet and a small face beneath an uneven cap.
- **Behavior and companionship:** Turns its cap toward damp air; shakes out trapped debris before resting. Shelters a companion's nearby belongings under its cap.
- **Habitat, ecology, and class fit:** Damp deadwood; proposed decomposer activity recycles nutrients. Spores do not establish poison, sleep, or reproduction mechanics.
- **Evolution direction:** The cap becomes a layered bracketlike canopy; preserve the three-foot stance and hidden face.

##### Thornlace — Bloom

- **Anatomy:** A vine-bodied quadruped whose limbs form living hoops around a soft central stem.
- **Behavior and companionship:** Untangles itself from neighboring growth; braces a leaning stem. Extends a looped limb toward a trusted companion.
- **Habitat, ecology, and class fit:** Thickets and disturbed woodland; supports surrounding small plants. Its tissues are botanical rather than an animal carrying foliage.
- **Evolution direction:** The hoops become intertwined arches beneath a lacework canopy; retain the visible stem and untangling gesture.

#### Additional Stormforged concepts

##### Drumwing — Stormforged

- **Anatomy:** A flightless bird with a round ribbed chest chamber and short stiff wings.
- **Behavior and companionship:** Taps its chest with its wing tips; crouches before gusts. Answers a familiar rhythm with a short tap sequence.
- **Habitat, ecology, and class fit:** Exposed scrub; proposed pressure-responsive anatomy connects it to storms. Forages windfallen litter; no weather UI or sonic combat effect is established.
- **Evolution direction:** The chest develops a large ribbed frame and the wings broad striking pads; retain the grounded stance and tapping.

##### Coilwhisk — Stormforged

- **Anatomy:** A long-bodied small mammal with spiraled whiskers and stiff ridged fur along its spine.
- **Behavior and companionship:** Combs its whiskers with its forepaws; turns its back to gusts. Touches whiskers to a familiar wrist.
- **Habitat, ecology, and class fit:** Storm-exposed grassland; proposed pressure/charge sensitivity guides sheltering and foraging. This does not set individual Lightning affinity.
- **Evolution direction:** Whisker spirals and back ridges become a flowing frame; retain the narrow face and low sheltering posture.

#### Additional Frostbound concepts

##### Snowmantle — Frostbound

- **Anatomy:** A compact woolly creature with six short limbs and overlapping shoulder folds held close by its lower limbs.
- **Behavior and companionship:** Packs snow around a resting hollow; tucks its limbs beneath its mantle. Leans its soft flank toward a resting companion.
- **Habitat, ecology, and class fit:** Cold uplands; proposed shallow shelters leave pockets for other life. Snow terrain and shelter bonuses are not introduced.
- **Evolution direction:** The mantle becomes a substantial layered coat; retain the six-limb arrangement and tucked rest.

##### Frostspindle — Frostbound

- **Anatomy:** A flightless long-legged wader with ankle scale fans, a narrow bill, and a short downy torso.
- **Behavior and companionship:** Spreads ankle fans before testing surface crust; rests on one folded leg. Carefully matches its pace to a companion.
- **Habitat, ecology, and class fit:** Cold wetland margins; feeds around shallow thaw pockets. Cold-adapted anatomy defines the class without requiring frozen tissue or an elemental affinity.
- **Evolution direction:** Legs and ankle fans lengthen beneath a dense ruff; retain measured stepping and the folded-leg posture.

#### Additional Warborn concepts

##### Reedrunner — Warborn

- **Anatomy:** A young centaurlike creature with a compact equine lower body, upright torso, expressive muzzle, and gripping forelimbs.
- **Behavior and companionship:** Practices coordinated steps around branches; holds its forelimbs against its chest during challenges. Waits for a companion at turns.
- **Habitat, ecology, and class fit:** Grassland margins; proposed ritual contests and trail maintenance develop the owner's centaur reference. No mounted travel, weapons, or new combat rules follow.
- **Evolution direction:** Torso and equine body develop a balanced centaur silhouette; preserve coordinated footwork and expressive muzzle.

##### Knucklecrest — Warborn

- **Anatomy:** A broad-armed apelike creature with thick forearm pads and a mobile crest above its eyes.
- **Behavior and companionship:** Presses padded knuckles together before a contest; braces branches while feeding. Offers a forearm beside rough footing.
- **Habitat, ecology, and class fit:** Woodland slopes; controlled contests establish social spacing. Martial bracing anatomy makes its class more specific than general aggression.
- **Evolution direction:** Forearm pads become pronounced ridges beneath a broad crest; preserve deliberate preparation and the protective arm arch.

#### Additional Blight concepts

##### Sourpouch — Blight

- **Anatomy:** A squat froglike creature with paired cheek pouches and broad expressive lips.
- **Behavior and companionship:** Wipes residue from its lips onto discarded bark; inflates its pouches when crowded. Relaxes into a flat loaf beside a companion.
- **Habitat, ecology, and class fit:** Wetland edges; proposed toxin-processing biology accompanies feeding on decaying material. Exact toxins, exposure rules, and combat effects remain open.
- **Evolution direction:** Cheek pouches develop layered side chambers; preserve the squat body and contrast between relaxed and warning silhouettes.

##### Needlecrest — Blight

- **Anatomy:** A long-snouted creature with a fan of quills connected to gland ridges across its shoulders.
- **Behavior and companionship:** Separates tangled quills with its hind feet; raises its crest when approached. Lowers the quills and noses a familiar sleeve.
- **Habitat, ecology, and class fit:** Dry scrub; proposed toxin-bearing quills deter threats while fruit feeding disperses seeds. Contact damage and poison application are not defined.
- **Evolution direction:** The shoulder fan becomes a layered protective crest; retain the small nose and deliberate grooming.

#### Additional Earthbound concepts

##### Siltback — Earthbound

- **Anatomy:** A broad low burrower with flexible back plates, digging forefeet, and a shovel-shaped tail pad.
- **Behavior and companionship:** Sweeps silt behind itself with its tail; rests pressed against a bank. Pats a cleared resting patch with its forefeet.
- **Habitat, ecology, and class fit:** Soft riverbanks; proposed burrows create sheltered hollows. Digging, erosion, and navigation effects require separate design.
- **Evolution direction:** Back plates and tail paddle broaden into a powerful earth-moving body; preserve the low gait and sweeping motion.

##### Rootsnout — Earthbound

- **Anatomy:** A piglike creature with a divided flexible snout and short hooked tusks.
- **Behavior and companionship:** Probes beneath surface litter; shakes soil from its whiskers. Follows a familiar traveler's footprints nose-first.
- **Habitat, ecology, and class fit:** Deep-soil woodland; specialized foraging loosens litter and redistributes seeds. Soil-adapted anatomy determines placement rather than its animal resemblance alone.
- **Evolution direction:** Snout tips and tusks develop a coordinated digging frame; retain the split nose and investigative gait.

#### Additional Zephyr concepts

##### Whirlfan — Zephyr

- **Anatomy:** A compact flyer with four broad wing fans around a central body and two small grasping feet.
- **Behavior and companionship:** Adjusts each wing fan before launch; folds them into a rosette on a perch. Rotates to follow a companion's movement.
- **Habitat, ecology, and class fit:** Cliffs and canopy edges; proposed aerial seed and small-invertebrate feeding. Four-wing flight remains a design concept rather than implemented traversal.
- **Evolution direction:** The fans develop distinct large lobes around a narrow body; retain independent wing gestures and the compact perched shape.

##### Hookwing — Zephyr

- **Anatomy:** A slender feathered flyer with long legs and hooked fingerlike wing tips, folding into a tall narrow outline.
- **Behavior and companionship:** Hooks a wing over a branch while settling; peers beneath leaves to feed. Hangs beside a familiar resting place with its head tilted.
- **Habitat, ecology, and class fit:** Canopy edges; proposed browsing and small-prey feeding vary aerial routines. Specialized grasping wings establish the concept's aerial identity.
- **Evolution direction:** Wing tips and legs lengthen into an elegant suspended form; retain the hooking rest and narrow face.

#### Additional Mindweaver concepts

##### Drowseed — Mindweaver

- **Anatomy:** A round furred creature with heavy eyelids and a crown of fleshy sensory lobes; its seedlike shape is not botanical tissue.
- **Behavior and companionship:** Folds its lobes inward to rest; turns them toward another sleeper. Settles into a slow rhythm beside a familiar companion.
- **Habitat, ecology, and class fit:** Quiet woodland hollows; proposed dream sensitivity shapes social resting. It forages fallen seeds; no sleep status or dream-access mechanics are specified.
- **Evolution direction:** The sensory crown unfolds into a layered halo; retain the sleepy eyes and curled rest.

##### Cairneye — Mindweaver

- **Anatomy:** A squat lizardlike creature with stacked translucent brow lenses above small side eyes.
- **Behavior and companionship:** Tilts its head until the lenses align; arranges pebbles around its resting spot. Follows a familiar companion's gaze.
- **Habitat, ecology, and class fit:** Rocky clearings; proposed perception of intention supports its anticipation motif. Foraging and reuse of loose material provide ordinary ecological activity; prediction rules remain open.
- **Evolution direction:** Lens plates form a tall ordered crest above a substantial body; retain head alignment and gaze-following.

#### Additional Chitin concepts

##### Spindlebug — Chitin

- **Anatomy:** A slender six-legged creature with comb-shaped forelimbs and a rounded silk-producing abdomen.
- **Behavior and companionship:** Combs fibers into shelter lining; plucks the threads before resting. Returns to repair the same favored resting corner.
- **Habitat, ecology, and class fit:** Woodland litter and roots; silk shelters reuse loose fibers. This does not establish crafting yields, colony simulation, or trap mechanics.
- **Evolution direction:** Abdomen and forelimb combs form a large spindle outline; preserve fiber-combing and the narrow body.

##### Shieldgrub — Chitin

- **Anatomy:** A stout larval creature with a broad collar plate and short gripping limbs; a small face peeks beneath the plate.
- **Behavior and companionship:** Feeds beneath decaying bark; closes its collar against disturbance. Rests near a companion with its face visible.
- **Habitat, ecology, and class fit:** Deadwood and leaf litter; proposed decomposition and shelter creation support habitat recovery. Plated arthropod anatomy defines its class.
- **Evolution direction:** The collar becomes a substantial forward shield on a segmented body; retain the visible face and gripping gait.

#### Additional Eldritch concepts

##### Foldling — Eldritch

- **Anatomy:** Three thick ribbonlike body bands surround a small central face and fold into a physically supported triangular bundle.
- **Behavior and companionship:** Unfolds one band at a time to inspect objects; closes into an unfamiliar resting shape. Opens a gap to watch a companion.
- **Habitat, ecology, and class fit:** Secluded rock hollows; proposed alien geometry supports crevice foraging. Its tangible body does not fold space or change reality.
- **Evolution direction:** Bands develop supporting ribs and longer articulated folds; retain the central face and sequential unfolding.

##### Wheel-Eye — Eldritch

- **Anatomy:** A radial creature with five short limbs and a ring of small flexible eye stalks around its central body.
- **Behavior and companionship:** Rotates its limbs before walking; closes eyes in sequence at rest. Leaves one eye turned toward a familiar companion.
- **Habitat, ecology, and class fit:** Deep-root cavities; unusual senses guide detritus foraging. Physical radial strangeness distinguishes its direction from mental powers or spirit existence.
- **Evolution direction:** The limb ring broadens beneath a layered eye crown; retain the rotating preparation gesture.

##### Threadwake — Eldritch

- **Anatomy:** A translucent low-bodied creature with four small feet and rows of fleshy filaments suspended inside a clear outer membrane.
- **Behavior and companionship:** Draws internal filaments together when disturbed; spreads them while grazing surfaces. Rests near a companion with the filaments moving slowly.
- **Habitat, ecology, and class fit:** Damp fissures; proposed surface-film grazing provides an ecological niche. All organs have living support; no detached body parts, portals, or intangibility are implied.
- **Evolution direction:** The membrane becomes a broad rippling mantle around the filament array; preserve internal motion and physical grounding.

#### Additional Wraith concepts

##### Mournveil — Wraith

- **Anatomy:** A rounded physical torso and short grasping arms lie beneath a drape of thin living tissue; the face appears when the veil lifts.
- **Behavior and companionship:** Examines abandoned resting places beneath its lifted veil; gathers dry leaves into a hollow. Sits near a companion with its face uncovered.
- **Habitat, ecology, and class fit:** Quiet ruins and woodland; proposed phase-associated lineage reuses deserted shelters. It is not established as a dead human or literal soul.
- **Evolution direction:** The veil develops trailing layers around a taller body; retain shy uncovering and visible hands.

##### Hushbell — Wraith

- **Anatomy:** A bell-shaped living torso on short legs, with small arms tucked beneath the rim and a soft throat opening.
- **Behavior and companionship:** Rocks gently before moving; draws its arms inward when disturbed. Rests near a companion with slow breathing visible.
- **Habitat, ecology, and class fit:** Sheltered stonework; proposed phase-associated natural history and crevice foraging. The bell is anatomy rather than a possessed manufactured object.
- **Evolution direction:** The torso becomes a broad bell with layered inner folds; preserve rocking and tucked arms.

##### Afterpaw — Wraith

- **Anatomy:** A low long creature with four soft feet and overlapping skin folds that briefly retain the outline of its previous pose as it turns.
- **Behavior and companionship:** Smooths its folds before walking; presses into narrow resting hollows. Lies along a companion's resting place with feet tucked away.
- **Habitat, ecology, and class fit:** Shaded crevices; proposed phase-associated biology supports the uncanny outline. Trailing folds do not establish clones, invulnerability, obstacle crossing, or time manipulation.
- **Evolution direction:** Skin folds lengthen into trailing panels; retain the deliberate turn and tucked rest.

#### Additional Wyrmkin concepts

##### Pebblewyrm — Wyrmkin

- **Anatomy:** A small draconic quadruped with rounded scales, blunt snout, soft horn buds, and a tightly curled tail.
- **Behavior and companionship:** Rests its forefeet on a favored stone; clears debris with its nose. Curls its tail around a familiar boot.
- **Habitat, ecology, and class fit:** Rocky grassland; ordinary foraging and seed movement provide an ecological niche. Draconic lineage, rather than stone-looking scales, determines placement.
- **Evolution direction:** Horn buds and scales develop a broad crest and plated tail; preserve the blunt face and tight tail curl.

##### Fanwyrm — Wyrmkin

- **Anatomy:** A long short-limbed draconic creature with a folded neck fan and broad cheek plates around a small face.
- **Behavior and companionship:** Opens its fan in social displays; coils beneath overhangs to rest. Partly opens its fan toward a trusted companion.
- **Habitat, ecology, and class fit:** Rocky waterways; proposed bank foraging and shelter reuse. Aquatic habits do not override draconic lineage, and no elemental breath is specified.
- **Evolution direction:** The fan develops a large ribbed collar around a substantial serpentine body; retain the partial greeting display.

##### Hookscale — Wyrmkin

- **Anatomy:** A climbing draconic youngster with hooked scales under its tail, grasping feet, and a curved brow above a short nose.
- **Behavior and companionship:** Anchors its tail before moving a foot; rubs its brow against bark. Hangs at eye level beside a familiar traveler.
- **Habitat, ecology, and class fit:** Tall woodland; fruit feeding redistributes canopy seeds. Authored draconic lineage defines the class without guaranteeing flight or a combat role.
- **Evolution direction:** Tail hooks and brow ridges develop around a long climbing body; retain tail-first anchoring.

#### Additional Umbral concepts

##### Shadepelt — Umbral

- **Anatomy:** A small quadruped with matte fur and long shoulder strands framing an expressive face in a dark outline.
- **Behavior and companionship:** Arranges its strands before resting; pauses where light meets shade. Exposes its face near a familiar companion.
- **Habitat, ecology, and class fit:** Twilight woodland edges; proposed shadow-associated lineage and seed foraging. Dark anatomy remains tangible and does not establish concealment or affinity effects.
- **Evolution direction:** Shoulder strands form a flowing mantle around a lean body; preserve the exposed face and boundary-pausing.

##### Duskmaw — Umbral

- **Anatomy:** A broad-mouthed low creature with matte throat lining, high-set eyes, and a hood of thick cheek folds.
- **Behavior and companionship:** Opens its mouth silently to warn; covers it with cheek folds at rest. Lowers its hood beside a trusted companion.
- **Habitat, ecology, and class fit:** Dark scrub hollows; proposed occult-origin lineage and scavenging. The mouth motif does not grant Void affinity or swallowing magic.
- **Evolution direction:** The cheek hood becomes a large folded frame; retain the silent warning and high-set eyes.

##### Umbrafold — Umbral

- **Anatomy:** A flat-bodied creature with four supporting feet and broad side membranes that fold into a small dark bundle.
- **Behavior and companionship:** Spreads membranes against shaded resting surfaces; folds them before walking. Lifts an edge when a companion settles nearby.
- **Habitat, ecology, and class fit:** Deep woodland floor; proposed shadow-shaped lineage and litter foraging. Physical membranes support tangible identity independent of individual affinity.
- **Evolution direction:** Membranes develop a scalloped outline around the grounded body; retain the bundle-shaped walking posture.

#### Additional Construct concepts

##### Kilnling — Construct

- **Anatomy:** Ceramiclike plates surround flexible living tissue in a rounded vessel-shaped torso with short hands and broad feet.
- **Behavior and companionship:** Smooths debris from plate seams; arranges small stones around its resting place. Taps its hands together to greet a companion.
- **Habitat, ecology, and class fit:** Old craft sites and clay-rich clearings are proposed settings; reuses loose material for shelter. A made-body origin needs authoring; a human creator is not established.
- **Evolution direction:** Plates form a broad articulated vessel frame; retain visible living seams and hand-tapping.

##### Rivetback — Construct

- **Anatomy:** A low many-legged creature with overlapping metal-like plates, flexible living seams, and rounded joint nodules resembling rivets.
- **Behavior and companionship:** Flexes its seams in sequence before walking; brushes grit away with rear limbs. Rests near a companion with relaxed joints.
- **Habitat, ecology, and class fit:** Abandoned workings and stony clearings; proposed debris foraging and sheltered nesting. Assembled body architecture defines the concept, without granting immunity or metal affinity.
- **Evolution direction:** Plate layers become a substantial articulated carapace; preserve flexible seams and sequential flexing.

##### Spindleheart — Construct

- **Anatomy:** A woven lattice body surrounds a visibly pulsing central organ; long arms and short legs attach at flexible joints.
- **Behavior and companionship:** Threads shed fibers into its lattice; folds its arms across its central chamber at rest. Offers loose fiber to a companion.
- **Habitat, ecology, and class fit:** Overgrown abandoned structures; proposed fiber gathering recycles loose plant material. The made living body does not establish a known creator or crafting system.
- **Evolution direction:** The lattice develops an intricate open frame around a protected core; preserve the visible pulse and folded-arm rest.

#### Additional Feyborn concepts

##### Thimblehart — Feyborn

- **Anatomy:** A tiny deerlike creature with cup-shaped antler tips, attentive eyes, and a fine neck mantle.
- **Behavior and companionship:** Places petals in its antler cups; watches new objects before approaching. Sets down a petal near a familiar companion.
- **Habitat, ecology, and class fit:** Flowering clearings; proposed fae-origin lineage and seed dispersal. Offerings do not establish binding bargains or automatic trust rewards.
- **Evolution direction:** Antler cups develop into a branching crown as the mantle lengthens; preserve the small offering gesture.

##### Glimmergrin — Feyborn

- **Anatomy:** A compact upright creature with a wide expressive face, folded ears, and overlapping skin panels resembling a short cloak.
- **Behavior and companionship:** Copies another creature's head tilt; wraps its cloak panels closely at rest. Returns a greeting with an exaggerated expression.
- **Habitat, ecology, and class fit:** Proposed enchanted-grove folklore supplies an origin context; fruit feeding disperses seeds. Mimicry does not establish illusion, disguise, or mind control.
- **Evolution direction:** Skin panels become a layered mantle around a graceful body; retain the broad face and expressive greeting.

##### Knottail — Feyborn

- **Anatomy:** A shrewlike creature whose long tail divides into soft ribbonlike tips capable of loosely braiding around one another.
- **Behavior and companionship:** Braids its tail while resting; arranges fallen stems into loops. Drapes a tail tip over a familiar nearby hand.
- **Habitat, ecology, and class fit:** Woodland paths and old boundary clearings; proposed fae lineage and fallen-material nesting. Knots are a behavior motif, not contracts or spell rules.
- **Evolution direction:** Tail tips form an intricate trailing braid around a compact body; preserve the tiny face and braiding rest.

### Review priorities after population

1. Review the second batch and the six remaining first-pass classes before
   comparing second/third concepts within classes. Give keep/revise/reject feedback.
2. Resolve Eldritch/Mindweaver/Umbral/Feyborn and Wraith/Construct boundaries using
   actual concepts; record defining anatomy/origin rather than classifying by
   color, one behavior, habitat alone, or individual affinity.
3. Compare silhouettes, body plans, locomotion, ecology, and personality across the
   roster. Note winged Beast versus Zephyr, aquatic Wyrmkin versus Abyssal, and
   assembled arthropodlike Construct versus Chitin in particular.
4. Choose a small connected production slice, develop full briefs, and reconcile
   its mechanics through the established source-selection procedure.
5. Establish final evolution grouping and roster accounting before numbering
   entries or committing production work for every possible later form.

## Evidence and related references

- [Worldbuilding Bible](SolHunter_Worldbuilding_Bible.md): overarching canon,
  roster target, taxonomy, ecology, evolution, and latest owner-approved rules.
- [Opening, companionship, and consequences](../decisions/2026-10-28-opening-companionship-and-consequences.md):
  the three rescuers, starter identity, production presentation, and legendary choice.
- [Sol ecology](../sol-ecology.md) and [behavior roadmap](../sol-behavior-roadmap.md):
  existing prototype routines and behavior/companionship limitations.
- [Sol stats](../sol-stats.md), [class buffs](../class-buffs.md), and
  [affinity moves](../affinity-moves-imprints.md): current Godot implementation
  boundaries; prototype values are not automatically final species balance.
- [Sol menu](../sol-menu.md) and [Inspector tuning](../inspector-tuning.md):
  model preview and connected authoring controls.
- [Mechanics reference](../mechanics-reference.md): source-selection and evidence
  procedure before implementing new non-generation rules.
- Earlier source inspection at commit `115f3e87acc1716c7113523567c01e1666681885`:
  `SOL_CLASS_AFFINITY_SPEC.md`, `src/systems/world/sol_catalog.py`, and
  `content/sols/demo_species.json` establish a provisional class list and demo
  catalog, not a ratified final roster. Older affinity/stat proposals are superseded
  where the Godot Bible records later owner decisions. Reconcile callers, tests,
  and later decisions before implementing affected mechanics.

### Authoring record

| Date | Scope | Evidence / effect |
| --- | --- | --- |
| 2026-10-28 | Owner requested a Sol Bible to populate after the roster-structure plan | Created the index, templates, proposed first-batch queue, and review process. No new species content or gameplay rules approved by this setup. |
| 2026-10-28 | Initial species-design questionnaire answered | Style first; start fresh with deliberate retention; allow all three visual directions; agent proposes and owner provides creative feedback. No individual species approved. |
| 2026-10-28 | Owner agreed to the proposed visual foundation and five shared principles | Recorded approved style and tone. Added three separately labeled proposed concept sketches for discussion; no species or starter assignments approved. |
| 2026-10-28 | Owner requested class review and three initial species per class | Recorded eighteen working categories, 54 concept slots, and proposed assignments for the first sketches. Replaced the earlier proposed six-lineage batch. Evolution grouping, category names, and species assignments remain for review. |
| 2026-10-28 | Owner requested class renaming before further species design | Added a proposed display-name pass based on approved creature style. Particular names remain for review; no runtime identifiers, class mechanics, or species approvals changed. |
| 2026-10-28 | Owner reviewed class names and supplied mythological references | Kept ten existing names, approved Blight and Wraith display names, left five renames and the StoneBound direction open. Recorded phoenix for CinderKin and minotaur/centaur for Warborn as creative references only. Superseded the earlier agent naming pass with this decision record. |
| 2026-10-28 | Owner approved Bloom and Eldritch | Bloom replaces Verdant as a display name. Eldritch replaces the old StoneBound class direction in design. Four names remain open; Chitin is directionally better but not final. Added another separately labeled naming round. |
| 2026-10-28 | Owner completed the current naming review | Approved Abyssal, Zephyr, and Chitin; retained Earthbound for now. All eighteen current names selected. Superseded remaining naming proposals; runtime IDs and mechanics unchanged. |
| 2026-10-28 | Owner asked to continue after selecting class names | Added Ashquill, Bellroot, Rattlehorn, and Rimefold as proposed sketches; grouped them with Crown-Ear and Reedback for a six-class first review. Added a seven-concept index including Glass-Throat. No species approved or runtime content added. |
| 2026-10-28 | Owner approved all six concepts in the first review batch | Recorded concept and class-placement approvals for Crown-Ear, Ashquill, Reedback, Bellroot, Rattlehorn, and Rimefold. Crown-Ear is batlike. All species names are placeholders; detailed specifications and implementation remain pending. Glass-Throat remains proposed. |
| 2026-10-28 | Owner authorized the next six-class concept batch | Proposed Browguard, Bitterfrill, Knucklemole, Sailcrest, and Claspback; developed the existing Glass-Throat concept for Mindweaver. Twelve concepts total, six approved and six proposed. All names remain placeholders; no runtime content or new mechanics implemented. |
| 2026-10-28 | Owner requested Bible population after positive directional feedback | Added forty-two proposed concepts to the existing twelve, reaching three per class and 54 total. Preserved six explicit approvals, indexed every concept, added class coverage and review priorities, and flagged evolution-count reconciliation. Names remain placeholders; no runtime implementation or new mechanics. |
| 2026-10-28 | Owner answered production-scope questionnaire | Recorded candidate-based 151-entry accounting, a contrasting three-species pilot, ground/flight/swimming, routines and companionship before ecological world effects, and simple 3D art. Added the proposed pilot trio and staged integration/validation plan; no gameplay implementation. |
| 2026-10-28 | Owner added procedural movement for Sols | Added procedural locomotion to the first slice, species rig/profile requirements, proposed pilot-specific ground/air/water motion, animation/gameplay authority boundaries, and acceptance/performance checks. Implementation remains pending. |
| 2026-10-28 | Owner started step one and supplied size rules | Created three linked pilot production drafts with reserved IDs, proposed anatomy/rigs, six-stat profiles, explicit existing move pools, behavior branches, encounter direction, and evolution outlines. Recorded three-stage size progression and clarified two-total-form variety. Combat role and flight answers plus rendered baseline remain pending; no runtime code or assets changed. |
| 2026-10-28 | Step-one rendered baseline attempted | Standard wrapper could not read Windows hardware metadata. Two direct rendered route runs completed with zero journey assertions and one contact each, but engine log/cache write errors prevent clean performance acceptance. Preserved local evidence and left the clean-baseline gate open. |
| 2026-10-28 | Owner instructed the agent to proceed | Adopted recommended pilot role split and bounded low flight as documented working assumptions. Optional unanswered questions no longer block authoring. Retained provisional dimensions/stats/moves and continued clean-baseline verification before closing step one. |
| 2026-10-28 | Step-one preparation completed under proceed/continue direction | Documented recommended role and bounded-flight defaults, fixed Windows redirected-process exit-status capture in the existing profiler, verified 0/7 exit probes and capped/uncapped clean source-stable journeys, and recorded the baseline and frame-time limitation. Three production working specifications ready for species-data integration; no species implementation. |
| 2026-10-28 | Owner authorized step-two data integration | Connected three pilot runtime resources/catalog, battle profiles, move pools, ecology, placeholder presentation paths and isolated sighting scene. Preserved existing identities/campaign content, lifted the bounded move-pool ceiling, and added admission/capture/save tests. Models and movement remain subsequent steps. Validation results recorded in the step-two section. |
| 2026-10-28 | Owner supplied explicit role and flight questionnaire answers | Approved the pilot role split as the starting design: Crown-Ear fast/disruptive, Reedback durable/physical, Bellroot support/battlefield control. Approved low flight with bounded altitude, defined obstacle clearance and legal landing spots. These replace earlier working assumptions; stats, exact dimensions, timing and finished art remain provisional. Existing implementation follows these directions. |
| 2026-10-28 | Owner selected anatomy B for Ashquill, Rattlehorn and Rimefold, then clarified small/cute first-stage proportions | Built three distinct isolated workshop models with juvenile proportions, actual support chains, essential poses and independent affinity effects. The initial board is too mature as a first-form target. Family counts, gameplay records, later forms and finished-model acceptance remain open; see the anatomy review for validation evidence. |
| 2026-10-28 | Owner requested applying the creatures | Connected Ashquill, Rattlehorn and Rimefold as small first forms in the normal catalog/sightings, combat, capture, selected following/gestures and menu previews. Stable keys 0004–0006 are reserved; existing species and starters remain. Reference tuning/training capacity is provisional, with final family counts and later forms open. Focused gameplay and rendered evidence is in the anatomy review. |
| 2026-10-28 | Owner requested filling each class and selected one playable first form per class | Added twelve existing candidates as provisional small/cute first forms, completing eighteen current playable classes with distinct models, records, sightings and companion gestures. Keys 0007–0018 are reserved. Existing concept approval labels remain; later forms/families, final balance and finished art are not approved by implementation. Eldritch is separate from legacy Stonebound and its passive is explicitly unassigned. See the class-coverage review for focused verification. |
