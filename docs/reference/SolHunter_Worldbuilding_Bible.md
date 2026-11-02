# SolHunter — Complete Worldbuilding Bible & Research Compendium

Consolidated research edition · October 23, 2026

## Confirmed owner canon — Sol visual cores, October 30, 2026

Each Sol has a wispy, ball-shaped **visual core** with editable presentation
parameters, rendered using the game's existing particle approach. Owner
clarification: the earlier word “head” referred to this visual core; it does not
have to be the Sol's anatomical head. Core placement is independent of head
anatomy: a body may retain a separate physical head, use the core near its head,
or locate the core elsewhere on or around its body. This corrects the earlier
interpretation that every anatomical head must be replaced by particles.
Species-specific bodies remain distinct. Core size, placement, particle density,
wisp length, movement, softness, opacity and tint are art parameters. This visual
canon does not establish an affinity restriction, energy reserve, brain location,
Vastra transaction or combat mechanic. Individual affinity remains independent.

Vastra Canon v1.0 included

This is a consolidated record of the SolHunter worldbuilding, gameplay design, narrative research, ecological systems, and long-term development vision we've worked through.

I'll distinguish three levels of certainty throughout:

- Confirmed canon: Decisions you have explicitly approved.
- Provisional design: Agreed direction, but terminology, mechanics, or implementation details remain subject to revision.
- Deferred / unresolved: Concepts intentionally left for future design, or questions without a final answer.

Important source distinction: This is a comprehensive reconstruction from our available discussions and project context, not a verified verbatim transcription of every version of the repository's Bible. Where original wording is unavailable, I preserve the established meaning rather than pretending to quote an original document.

## Part I — The Identity of SolHunter

### 1. The central vision

SolHunter is a dark-fantasy creature-collecting tactical RPG set in a world where humanity coexists uneasily with living beings called Sols.

Its three equal gameplay pillars are:

1. Exploration: Discovering an interconnected world, its environments, settlements, mysteries, and inhabitants.
2. Sol collection and development: Encountering, understanding, bonding with, capturing, training, and evolving Sols.
3. Tactical combat: Using positioning, abilities, affinities, terrain, and strategic decisions in meaningful battles.

No single pillar is intended to overshadow the other two.

The game draws inspiration from classic creature-collecting RPGs while developing its own identity through ecological simulation, the ethics of Sol companionship, a living magical-energy system, and a story in which humanity's treatment of nature has tangible consequences.

### 2. Core themes

The established thematic foundation includes:

- Coexistence versus domination: Whether humans should control, cooperate with, or preserve the autonomy of Sols.
- Companionship versus ownership: A legal or magical contract does not automatically create trust.
- Ecological responsibility: Actions can improve or damage the living world.
- Appearance versus reality: An aggressive creature may be protecting its environment; a seemingly benevolent human may be exploiting it.
- Power and sacrifice: Great power can demand difficult, sometimes irreversible decisions.
- Letting go: Loving a companion may mean accepting its independent destiny.
- Consequences: Decisions should matter without turning ordinary gameplay into an unrecoverable punishment system.

The world should be morally complex without making every character or Sol morally ambiguous for its own sake.

### 3. Scope of Region One

# 151

Target Region One Sol roster

# 55

Region One level cap

# 18

Provisional class structure

The Region One scope target is approximately the length and completeness of a classic Pokémon FireRed-scale adventure, with a roster of 150 ordinary roster entries plus one additional Sol in the established planning target.

This is a design target, not a claim that all 151 creatures have been fully authored or implemented.

Region One should feel like a complete standalone adventure, while leaving room for future regions, expanded lore, advanced challenges, and eventual multiverse content.

## Part II — The World

### 4. Civilization and wilderness

SolHunter's world is a high-fantasy civilization powered by magical energy, now canonically named Vastra.

Human settlements contain infrastructure, protective barriers, specialized equipment, and technologies that harness ambient Vastra.

Beyond protected settlements, the wilderness is alive with Sol populations, ecological territories, environmental hazards, and places where the balance between humanity and nature has been disturbed.

Humans generally fear Sols, particularly those perceived as dangerous or aggressive. Solhunters occupy a socially significant role because they are willing and able to interact with these creatures.

Solhunters are highly regarded, though their behavior and ideology can differ considerably.

### 5. World geography and exploration

The intended world structure combines:

- Authored settlements, landmarks, important routes, and story locations.
- Procedural or dynamically populated wilderness.
- A seamless, radial exploration structure rather than a rigid sequence of isolated maps.
- Distinct environmental regions with their own ecology and hazards.
- Readable danger ratings and safe travel opportunities.
- Persistent consequences where practical, without permanently blocking essential progression.

The environment should reward curiosity and observation rather than forcing players into constant resource management.

### 6. Environmental territories

Ecological territories are distinct from technical world-streaming chunks.

A territory is a meaningful environmental region in which Sol populations, local resources, Vastra behavior, and ecological conditions can be tracked.

A streaming chunk is a technical unit for loading and simulating the game world.

Keeping these separate allows the game to maintain persistent ecological conditions without simulating every distant creature in full detail.

## Part III — Vastra: The Energy of the World

Confirmed foundational canon · Specification v1.0

### 7. Definition and pronunciation

Vastra — pronounced VAHS-trah, approximately /ˈvas.tra/ — is the pervasive, naturally replenishing energy that flows through SolHunter's world.

The name is Latin-inspired.

Previously explored terminology such as Miasma and Vaether has been superseded by Vastra. The spelling Vastrah is not established canon.

Vastra is not simply a conventional mana bar or spellcasting resource. It is an environmental, biological, technological, and narrative foundation of the world.

### 8. Natural behavior

Vastra:

- Flows and accumulates naturally.
- Replenishes over time.
- Disperses and redistributes toward local equilibrium.
- Exists at different concentrations in different environments.
- Supports Sol life and much of human civilization.
- Can be affected by affinity and local ecological conditions.

Every region has a natural equalization point.

Ordinary natural processes and noncombat Sol behavior maintain equilibrium. Human disruption and aggressive Vastra-powered Sol abilities can create ecological overload. Healing abilities can neutralize overload or push it below zero into restorative conditions (owner retcon, October 28, 2026).

This distinction is central to the setting.

### 9. The appearance of Vastra

Pure, affinity-neutral Vastra has a full-spectrum white-light identity, but normally appears transparent because of how Vastra interacts with light.

Affinity-aligned Vastra exhibits colors associated with different parts of the visible spectrum.

Vastra currents can be visibly perceived in the environment under normal conditions.

This provides a basis for environmental art direction, affinity effects, magical phenomena, and visual storytelling.

The initial eight-affinity palette was approved on October 27, 2026; see the owner-approved affinity and move rules below. Distinctive replacement names remain unresolved.

### 10. Concentration and overload

Each relevant environmental tile tracks two separate properties.

| Measurement          | Scale | Meaning                                            |
| -------------------- | ----- | -------------------------------------------------- |
| Vastra concentration | 0–100 | How much ambient energy is available locally       |
| Ecological overload  | Signed; limits remain tuning | Positive: destabilized; zero: neutral; negative: restorative |

These measurements are independent.

A naturally Vastra-rich region can be perfectly healthy. A region with relatively little ambient energy can still be severely damaged by human interference.

High concentration does not automatically mean ecological danger.

### 11. Natural equilibrium and replenishment

Each region has a natural replenishment budget.

Vastra naturally balances and disperses, but the precise replenishment and equalization rates vary according to the region and are configurable.

Ordinary natural processes and noncombat Sol behavior maintain or restore equilibrium. Aggressive Vastra-powered abilities can create overload; healing abilities reduce it independently of HP restored.

Natural disasters may redistribute Vastra, but do not independently create ecological overload.

Natural environmental change remains distinct from overload caused by human disruption or aggressive Vastra-powered combat abilities.

### 12. Ambient harvesting

Ambient Vastra can safely power nearly all modern technology in SolHunter's civilization.

Harvesting is sustainable when it remains within the region's replenishment capacity.

Excessive harvesting disrupts equilibrium and contributes to ecological overload.

Safe ambient harvesting and destructive extraction from a living Sol are fundamentally different practices.

Direct extraction from living Sols is inherently harmful and destructive.

The technology that may eventually separate an original Sol from a legendary manifestation is a different process and must not be conflated with destructive energy extraction.

### 13. Human exposure

Humans can suffer adverse effects from Vastra exposure.

High concentration and ecological overload produce distinct types of exposure effects, although their precise symptoms and numerical thresholds remain open for implementation.

The existing design includes disorientation, weakness, and potentially serious injury under severe exposure.

Protective clothing, masks, and settlement barriers help manage these risks.

Exposure should create meaningful exploration decisions without requiring constant oxygen, filter, or equipment-maintenance micromanagement.

### 14. Civilization and protective infrastructure

Vastra powers much of human technology.

Specialized instruments can measure local Vastra conditions.

City barriers filter and regulate incoming Vastra rather than necessarily eliminating it.

Different devices have different energy reserves and backup capabilities. An energy interruption therefore does not have to affect every technology in exactly the same way.

The precise design of technological devices and power networks remains future systems work.

### 15. Ecological overload

Positive overload arises from human-caused disruption, including unsustainable ambient harvesting, and from all aggressive Vastra-powered Sol abilities. Each ability authors its overload amount on the tiles its effect actually reaches; area abilities affect their covered tiles. Excessive Vessel defensive activity is an additional designed natural source under the later vegetation and Vessel response direction.

Overload spreads gradually to adjacent tiles.

Both positive and negative overload gradually return toward zero. Healing abilities reduce overload even when their targets have full health and can push it negative. Negative overload helps damaged habitats and Sol populations recover, with diminishing benefits. Concentration remains independent. Passive population-assisted recovery remains a separate system.

Earlier planning targeted ordinary recovery over approximately 1–3 in-game days. This remains a working tuning target rather than an immutable universal rule.

### 16. Sol-driven ecological recovery

Most Sols contribute to environmental restoration through their ordinary behavior.

The rate of passive recovery is related to the local Sol population, with diminishing returns based on ecological carrying capacity.

This means increasing a healthy local population can improve restoration, but overcrowding cannot produce unlimited healing.

Restoration remains possible without direct player intervention.

### 17. Storm generation

Simulation-generated Vastra storms require a contiguous 3×3 group of storm-eligible overloaded tiles.

A tile becomes eligible at a configurable overload threshold no greater than 100.

A qualifying group makes a storm possible; it does not guarantee one. Storm formation also depends on probability and environmental conditions.

### Storm eligibility footprint

Nine contiguous eligible tiles

Eligibility permits a probabilistic storm check; it does not automatically trigger a storm.

Large Sols can affect a 3×3 footprint and redistribute existing overload, potentially contributing to storm formation. Aggressive Vastra-powered abilities can also originate overload on their actual affected tiles.

Ordinary noncombat Sol activity does not independently generate overload. Aggressive Vastra-powered abilities do; healing abilities counteract it and can produce negative restorative conditions.

Scripted narrative storms may bypass the procedural 3×3 requirement.

The broader storm design includes durations ranging from seconds to days, mostly authored dramatic events, and rare persistent environmental consequences. Essential story paths must remain accessible.

### 18. Vastra and combat

Vastra concentration provides an environmental damage-output bonus when the tile's affinity matches the individual Sol's affinity.

The proposed maximum is +99% damage.

The exact scaling curve is deliberately undecided.

The bonus does not increase all combat statistics and does not permanently modify the Sol's underlying stats.

For a large Sol occupying several tiles, the strongest matching tile is used. If none matches, no affinity-based environmental damage bonus applies.

A Sol in a Vastra-poor habitat remains healthy, but does not receive the same environmental combat advantage.

### 19. Vastra's mysteries

Vastra's ultimate origin is not established as a universally known fact.

Scholars hold competing theories.

Vastra is the common term, while different cultures may have their own regional names.

Whether Vastra itself is conscious remains intentionally ambiguous.

Legendary beings use Vastra as their medium of manifestation, but are not simply masses of energy.

These mysteries should remain meaningful parts of the world's mythology rather than being prematurely explained.

## Part IV — Sols: Biology, Identity, and Ecology

### 20. What is a Sol?

Sols are physical living creatures originating from Vastra.

They are not merely spells, illusions, summoned projections, or disposable collections of energy.

They possess individual identities, memories, personalities, instincts, and relationships.

Their connection to Vastra is fundamental to their biology, but does not eliminate their individuality.

**Owner creative direction, October 28, 2026:** SolHunter's creatures belong to
dark fantasy: danger, mystery and meaningful bonds. All final creature designs
should be original SolHunter beings with their own lore. Real-world folklore is
welcome inspiration, rather than a requirement to reproduce an existing creature.
Move away from literal real-world animals in most cases. Where animal anatomy is
an influence, its mythical/high-fantasy identity should shape the creature's body
and behavior. The owner's many-tailed fox example describes a mythic direction;
the phoenix-inspired Sol is a positive reference, not a mandate to copy a named
franchise design. First forms retain charm while clearly showing otherworldly
anatomy and behavior. The current playable models remain in use as development
proxies; their presence does not establish final creature designs.

Owner questionnaire follow-up: the world has a coherent underlying reality,
interpreted through different local folklore. Local beliefs can differ without
automatically making every story a separate literal origin or biological rule.

### 21. Early forms and physical development

The earliest evolutionary forms of Sols are often wisplike in appearance.

However, they are still physical and tangible beings with biological needs.

As they evolve, many become increasingly substantial and physically defined.

Evolution is not simply a change in combat statistics. It can also alter the creature's appearance, physical abilities, and relationship with its environment.

**Owner scale clarification, October 28:** the game's world scale is anchored to
small Sols, not humans. Humans are normally **smaller than small Sols**. Correct
the oversized human/player presentation downward against that reference; do not
scale Sols up to match the current human model. This clarification supersedes the
earlier rough comparison that the player should be around a small Sol's size.
Large Sols are massive and occupy a **3×3-tile footprint**. Exact heights,
human/Sol ratios and medium-form dimensions remain open. This is an art-scale
direction, not a claim that the runtime calibration has already been performed.

### 22. Sol species, classes, and affinities

Three concepts must remain separate:

| Concept  | Definition                                                            |
| -------- | --------------------------------------------------------------------- |
| Species  | A Sol's biological and evolutionary identity                          |
| Class    | The fixed primary classification assigned to a species lineage        |
| Affinity | An independently generated energy characteristic of an individual Sol |

A species has a fixed primary class throughout its ordinary evolution family.

Different individuals of the same species may possess different affinities.

An affinity is not automatically determined by a species' class.

Optional secondary classes and class changes in special evolution branches require explicit authoring.

### 23. The eighteen-class structure

The design establishes 18 class slots, originally organized using Pokémon's 18 types as a one-to-one reference framework.

This is an organizational comparison, not an instruction to copy Pokémon's type-effectiveness chart or elemental rules.

The provisional class names explicitly available from our discussions include:

| Reference category | SolHunter class | Intended identity                                                    |
| ------------------ | --------------- | -------------------------------------------------------------------- |
| Normal             | Beast           | Adaptable natural creatures without specialized origins              |
| Fire               | Cinderkin       | Ash-born and flame-origin creatures                                  |
| Ghost              | Wraithborn      | Supernatural or spectral identity; detailed definition not finalized |

The full set of 18 names is not reliably available in the material I can verify here, so I will not invent the missing fifteen.

The established naming direction favors evocative names such as Wraithborn, rather than generic elemental labels.

The names remain provisional until the roster is formally ratified.

### 24. Evolution

The established progression model includes:

- Three ordinary evolutionary forms.
- A unique fourth legendary form or manifestation associated with a lineage.
- A fixed primary species class across ordinary evolution.
- Individually determined affinities.
- Authored exceptions rather than unrestricted procedural class changes.

The fourth legendary form is not an ordinary evolution stage.

Typical starter progression has a working final ordinary evolution target around level 36.

Applicable pseudo-legendary lineages have a working progression target around level 55.

These are planning targets, not universal evolution requirements.

**Owner bond/evolution direction, October 28:** first forms are the forms an
average person ordinarily bonds with. Allowing a Sol to transform is a major
relationship decision. Transformation changes that bond, almost like a reset,
with remnants of the prior connection and memories that can be regained.
The Sol retains a recognizable personality core, with new instincts, needs and
unfamiliar behavior. The near-reset is a change in relationship and expression,
not a requirement to replace the individual with an unrelated personality.
This emotional cost and the benefits/work of developing a bond belong together;
evolution must not be presented as a consequence-free statistical upgrade.

Reaching maximum bond across all three ordinary stages should be a long,
difficult and rewarding accomplishment. Owner questionnaire follow-up: maximum
bond is **not required before ordinary evolution**; earlier evolution is allowed
with meaningful relationship tradeoffs. Missed earlier-stage bond milestones can
be recovered through difficult memory recovery in later forms. The greatest
rewards should emphasize unique relationship moments and meaningful teamwork
options. Bond development is driven primarily by species-specific care, shared
ordeals and consistent choices. Ordinary evolution is a mutual choice: the player
offers and the Sol must be willing. The post-evolution near-reset creates clear
limits on advanced teamwork until trust is rebuilt. These are design commitments,
not a numerical willingness/obedience system. Exact carryover, recovery activities,
milestones, specific rewards and
balancing remain open. No reset percentage, time requirement or numerical bond
formula is established by this direction. Capture/Seal and transfer
memory-continuity rules are separate; this does not resolve the open legendary
memory-inheritance question. This is approved design direction, not a claim that
the current runtime implements bond progression or evolution memory recovery.

### 25. Propagation and offspring

Compatible Sols from the same lineage can combine their energy to produce a new earliest-form Sol.

The process is supported by ambient Vastra.

This is not ordinary biological reproduction copied directly from real animals, nor a system for freely combining arbitrary species.

Established constraints include:

- No unrestricted cross-species hybrids.
- No automatically generated new classes.
- No alternate legendary branches produced through propagation.
- Offspring begin in the earliest ordinary form.
- Birthplace affinity has a dominant influence.
- Parental affinity contributes secondarily.

The exact inheritance weights and reproduction conditions remain unresolved.

### 26. Temperament

The ecosystem design uses three broad behavioral categories:

Avoidant: Creatures that prefer distance, retreat, or cautious observation.

Neutral: Creatures that tolerate nearby activity unless disturbed.

Assertive: Creatures that defend territory, confront intruders, or respond more forcefully.

Aggression is not synonymous with cruelty, evil, or ecological destructiveness.

Many aggressive Sols are natural guardians of their environments.

Some may be affectionate toward trusted companions while remaining territorial toward strangers.

Others may simply have difficult personalities.

### 27. Social organization

The current ecosystem framework includes:

- Solitary creatures.
- Paired creatures.
- Small groups.

Species can have different social preferences.

The immediate world should normally show approximately 2–4 nearby Sols, adjusted according to habitat and context.

Individual species should have a small, readable set of observable behaviors, generally two or three.

These limits support both gameplay readability and simulation performance.

### 28. Natural behavior

Sol behaviors may include movement, observation, territorial defense, avoidance, resting, social interaction, and ecological maintenance.

The objective is to make the world feel alive without requiring hundreds of simultaneously simulated AI agents.

Most Sols naturally contribute to environmental equilibrium.

A hostile encounter may therefore reveal something meaningful about the local ecology rather than simply providing another battle.

### 29. Persistent and notable Sols

Not every Sol must retain a complete individual simulation forever.

However, notable Sols can retain identity and memory across encounters.

A player might recognize a particular creature, learn its behavior, or receive information about it through NPC sightings and a field journal.

This gives the wilderness continuity without making the simulation prohibitively expensive.

### 30. Sol death

Ordinary combat defeat is exhaustion, not death.

A defeated Sol is generally recoverable.

Actual death is rare and associated with exceptional circumstances.

Natural death is peaceful and restorative. A Sol's energy helps heal and equalize its surroundings without a destructive explosion.

Unjust death can release destructive, destabilizing energy.

Intent and circumstances determine whether a death is unjust.

The detailed handling of predation, accidents, self-defense, and other exceptional situations remains a future classification task.

The original starter Sol is explicitly protected from death.

## Part V — Solhunters, Seals, and Relationships

### 31. The role of Solhunters

Solhunters are people capable of engaging with Sols in ways ordinary citizens often cannot.

They may explore dangerous environments, establish relationships, form contracts, participate in battles, and investigate ecological problems.

Their standing in society reflects the danger and significance of these activities.

Not every Solhunter shares the same beliefs about how humans should treat Sols.

### 32. Seals

A Seal is a small, paper-like magical artifact, comparable in physical presentation to a Post-it note.

It holds an actual Sol through a soul contract.

The Sol is not simply converted into data or recreated as a copy.

Its identity and memories persist.

The contract establishes a relationship of possession or holding authority, but does not guarantee trust, affection, or obedience.

### 33. Life inside a Seal

Sols can respond differently to being contained.

Some may be comfortable in the Seal's internal environment.

Others may become restless, resistant, or upset.

A Sol's personality and relationship with its holder affect its behavior.

The long-term vision includes more advanced resistance and escape behavior, but those systems are deferred.

### 34. Trust and obedience

A Sol may:

- Accept instructions willingly.
- Hesitate or resist.
- Refuse particular commands.
- Express dissatisfaction.
- Request release.

A holder may retain contractual authority even when trust is poor.

This distinction is intentional.

Ownership, control, trust, and companionship are not interchangeable.

The relationship system should make this visible through gameplay without turning every interaction into mandatory micromanagement.

### 35. Capture methods

Two major capture approaches are established.

Combat capture: The player battles a Sol and attempts to seal it.

The planning model includes a doubled base capture-rate factor, modified by individual statistics, level, personality, and other conditions.

Brutal attacks can reduce capture odds.

Peaceful capture: The player uses deliberate noncombat interactions to establish a more cooperative sealing opportunity.

This approach is generally easier in terms of resistance but takes more time and interaction.

Under the current encounter design, aggressive Sols cannot be peacefully captured through the standard peaceful-capture route.

The exact mathematical formulas remain provisional.

### 36. Transfer of Sols

The research includes several transfer conditions:

| Transfer method                   | Proposed consequence                                                      |
| --------------------------------- | ------------------------------------------------------------------------- |
| Official transfer                 | Legal documentation, stamp, cost/tax, possible +3% universal stat benefit |
| Unapproved but nonforced transfer | Approximately 0% stat effect                                              |
| Forced transfer                   | Possible negative stat effect, provisionally around −3%                   |

These exact bonuses and penalties are not finalized canon.

The important established principle is that transfer circumstances can matter, but bonuses should not stack infinitely.

A Sol's memories and identity persist through transfer.

### 37. Ideological traits

Four broad ideological orientations have been explored:

| Trait       | Central attitude                                               |
| ----------- | -------------------------------------------------------------- |
| Control     | Sols should be managed or directed by humans                   |
| Autonomy    | Sol independence and self-determination should be protected    |
| Coexistence | Humans and Sols should build mutually beneficial relationships |
| Restoration | Damaged ecological relationships should be repaired            |

These are provisional trait names.

They are better treated as individual beliefs and behaviors than as four mandatory political factions.

A character may exhibit overlapping values, and relationships can evolve.

## Part VI — Combat and Progression

### 38. Tactical battle identity

The ordinary encounter baseline is one allied Sol against one opposing Sol.

Combat emphasizes tactical positioning rather than simply selecting the strongest attack.

Key considerations include:

- Positioning and movement.
- Terrain and tile affinity.
- Creature size and occupied footprint.
- Ability range and effects.
- Status conditions.
- Enemy reactions and readable AI behavior.
- Environmental Vastra bonuses.
- Strategic risk versus reward.

The exact grid dimensions, movement costs, and ability ranges remain subject to detailed design.

### 39. Abilities and moves

The planning structure includes approximately 36 innate abilities as a system target, with species-specific abilities and learnsets.

The distinction between abilities and moves should remain explicit in the final combat design.

Species-authored ultimate abilities are part of the progression vision.

Eligible ultimate abilities should be obtainable before the Region One final challenge, within the level-55 cap.

Not every Sol must receive an identical progression pattern.

### 40. Individual development

Individual Sol variation is important.

The design references IV/EV-like training and optimization systems, particularly for competitive and postgame content.

The exact formulas, inheritance, training limits, and stat distribution systems are not fully finalized.

These systems should support meaningful specialization without forcing every ordinary player to optimize perfectly.

### 41. Environmental damage bonuses

A matching tile affinity can amplify a Sol's damage output based on local Vastra concentration.

The maximum proposed bonus is +99%.

The scaling function remains open.

This modifier is temporary and applies to damage, not all statistics.

For larger Sols, the strongest matching tile within the creature's footprint determines the bonus.

This encourages positioning and environmental awareness.

### 42. Combat readability

Players should understand why important combat events occur.

Status effects, abilities, terrain advantages, and dangerous attacks require readable visual feedback.

AI opponents should respond intelligently without relying on invisible rules or arbitrary advantages.

The long-term competitive vision includes sophisticated opponents with exploitable weaknesses rather than unbeatable perfection.

## Part VII — The Player, Equipment, and Exploration

### 43. Player equipment

The established equipment model includes eight slots.

| Slot     | Function                               |
| -------- | -------------------------------------- |
| Mask     | Always-equipped protective slot        |
| Headgear | Head protection or utility             |
| Body     | Primary protective clothing            |
| Legs     | Lower-body protection                  |
| Boots    | Footwear and mobility                  |
| Gloves   | Hand protection or interaction bonuses |
| Necklace | Accessory effects                      |
| Ring     | Accessory effects                      |

Equipment can provide small passive bonuses, often around 1–2%, along with traits and Vastra resistance.

The intended aesthetic draws partly from Dune-like protective wilderness clothing.

### 44. Environmental protection

Equipment tiers provide different levels of protection from hazardous environments.

Severe storms should warn players and allow opportunities to retreat.

The design explicitly avoids making oxygen supplies, filter replacement, or constant equipment maintenance mandatory systems.

Environmental danger should enrich exploration rather than become a repetitive survival chore.

### 45. Player agency

The player should be able to influence the environment through choices, exploration, relationships, and optional restoration.

Ecological consequences matter, but the game should not routinely destroy the player's progress or create permanently ruined saves.

Major irreversible story decisions are an intentional exception.

### 46. Interface and presentation

The normal gameplay interface should remain relatively minimal.

Detailed Vastra concentration and overload information belongs in an Examine interface.

Important environmental warnings should remain visible enough to support informed decisions.

A field journal can record discoveries, Sol observations, ecological information, and NPC sightings.

### 47. Visual identity

The art direction includes:

- Dark-fantasy environments.
- Readable pixel-art presentation.
- A working 32×32 pixel-art planning reference.
- Modular character and Sol rendering.
- Equipment attachment points.
- Layered visual effects.
- Visually distinct abilities and environmental phenomena.

Actors and Sols should support modular visual elements rather than requiring every equipment combination to be drawn as an entirely separate sprite.

The precise art pipeline and final production resolution remain implementation decisions.

## Part VIII — Story, Antagonist, and Moral Conflict

### 48. The central conflict

SolHunter's primary narrative conflict concerns humanity's relationship with Sols and the natural world.

Civilization depends on Vastra.

Sols are living manifestations of the world's energy and participate in its equilibrium.

Humanity possesses the ability to exploit this system, including methods that harm Sols and destabilize nature.

The story explores the consequences of that power.

### 49. The primary antagonist

The established antagonist concept is an extremist who believes humanity must be eradicated to protect the natural world.

The antagonist understands Vastra technically.

Their goal is to exploit catastrophic energy releases from unjust Sol deaths, potentially on a massive scale, to produce a world-altering explosion or reset.

The intended result is the destruction of humanity.

The contradiction is deliberate: the antagonist claims to act for nature while pursuing a method that catastrophically damages it.

This is not a simple misunderstanding of Vastra.

The antagonist possesses technical knowledge but applies it toward an ethically destructive goal.

The antagonist's identity, organization, personal history, and exact method remain undecided.

### 50. Narrative ideology

The game's ideological tensions should emerge through individuals, relationships, and decisions rather than a simplistic good-versus-evil faction chart.

Control may be justified as protection.

Autonomy may conflict with immediate safety.

Coexistence requires compromise.

Restoration may demand sacrifice or responsibility for past harm.

The player should encounter these positions through characters and consequences.

### 51. Region One ending

Region One is intended to have one main ending with meaningful variations.

Humanity survives through responsible coexistence rather than complete domination or eradication.

The story should be complete enough to satisfy players even before future expansions.

The October 28 owner direction below establishes a viable, harder refusal route
with lasting relationship/story consequences; its exact scenes and consequences
remain a major narrative dependency.

## Part IX — Legendary Sols

### 52. What is a legendary Sol?

A legendary Sol is a unique primordial individual associated with a species lineage and a larger force of nature.

A legendary manifestation is not merely the original Sol transforming into a stronger ordinary evolution.

The legendary entity and the original Sol are distinct individuals.

The original Sol acts as a vessel or exit point through which the legendary entity can manifest.

Vastra serves as the medium of manifestation.

### 53. Legendary ascension

Each lineage has an authored fourth legendary form in the long-term design.

This form generally preserves the lineage's primary class.

Any class change must be specifically authored and must use an established class rather than inventing arbitrary new classifications.

The vessel's individual affinity is preserved.

Legendary ascension is a unique event, not a normal level-based evolution.

### 54. The starter's legendary destiny

The main Region One climax centers on the original starter Sol.

The starter may ask the player to let go so that the legendary entity can manifest.

The choice is intended to be emotionally significant and irreversible.

Accepting allows the ascension to occur and may eventually permit advanced separation of the original Sol from the legendary manifestation.

Refusing permanently forfeits the starter's legendary ascension in that save.

The original starter cannot die.

Owner clarification, October 28: victory remains possible without ascension,
demonstrating that the original Sol was capable either way; ascension would have
made the path easier. Refusal also has lasting relationship and story consequences.
Their exact form and the detailed ending remain unresolved; see the approved
opening/companionship direction below.

### 55. Separating the original Sol

Advanced late-game technology may allow the original Sol to be separated from the legendary manifestation.

The process preserves the original's identity.

It is not the same as destructive Vastra extraction from living Sols.

The exact timing, limitations, and prerequisites remain future design work.

### 56. Legendary uniqueness

Only one of each legendary individual exists within a given save's reality.

Other realities may contain their own corresponding legendary individuals.

This becomes important in the future multiverse framework.

The established long-term vision includes very late endgame acquisition of legendary beings, potentially one of each.

However, this must respect irreversible Region One decisions.

Unresolved conflict: A general postgame collection rule cannot silently override the permanent starter-legendary lockout caused by refusal.

### 57. Legendary memories and relationships

The original Sol and the legendary entity are distinct individuals.

Whether the legendary inherits memories, experiences, or emotional relationships from the vessel remains unresolved.

Perfect bond requirements and additional legendary eligibility conditions are also not fully established.

### 58. Advanced form-shifting

A hyperrare late-game device has been proposed that allows shifting among the three ordinary evolutionary forms.

This is distinct from legendary ascension.

The device's acquisition, restrictions, and competitive implications remain deferred.

## Part X — The Living Ecosystem

### 59. The ecological simulation philosophy

The living world should feel persistent, reactive, and believable without simulating every creature at maximum detail.

The player should observe meaningful behaviors and consequences.

The ecosystem should remain understandable enough for the player to learn its patterns.

The design deliberately avoids mandatory ecological micromanagement.

### 60. Population behavior

Local populations depend on habitat and environmental conditions.

Populations may be solitary, paired, or grouped.

Species exhibit a limited number of recognizable behaviors.

Encounters should feel connected to the world rather than being completely random.

### 61. Depletion and recovery

The player may influence local Sol populations through repeated encounters and captures.

Depletion should be recoverable.

Routine extinction is not an intended baseline mechanic.

The world can recover through reproduction, migration, ecological restoration, and time, according to future system rules.

Complex migration and nesting systems remain deferred.

### 62. Ecological territories

Territories provide the authority for population and environmental simulation.

They can maintain information about:

- Habitat and biome.
- Population composition.
- Local carrying capacity.
- Vastra concentration and overload.
- Environmental recovery.
- Notable Sols.
- Human disturbances.
- Recent ecological events.

The exact data structure remains an engineering decision.

### 63. Near and distant simulation

Nearby Sols can use detailed movement, animation, behavior, and interactions.

Distant territories can use lightweight aggregate simulation.

This prevents world size from requiring an impractical number of full AI agents.

Notable Sols should retain identity where narratively or mechanically important.

### 64. Ecological cycles

Long-term planning includes ecological cycles, recovery, and more emergent relationships between species and habitats.

Concepts under exploration include food webs, ecological roles, territory relationships, and long-term population changes.

These should be introduced incrementally rather than all at once.

### 65. Ecological cause and effect

The intended design allows human activity to produce indirect environmental consequences.

A player or NPC might disturb an area, change its overload, influence nearby Sol behavior, and eventually contribute to storm conditions.

The resulting butterfly effect should arise from understandable systems rather than arbitrary punishment.

## Part XI — The Multiverse and Long-Term Vision

### 66. The multiverse reveal

A future major release is intended to reveal that players represent alternate versions of the same legendary Solhunter across different realities.

This gives online interactions an in-universe explanation.

The multiverse is a deferred major narrative feature, not something that must be fully implemented in Region One.

### 67. Online competitive battles

Players may eventually battle across realities.

Different players' legendary individuals can coexist in a battle because they originate from separate realities.

Each player's irreversible decisions remain part of their own reality.

Online systems should be architecturally considered early enough to avoid unnecessary future rewrites, but not implemented before the core single-player experience is stable.

### 68. Postgame superboss

The deferred postgame vision includes a Trainer Red-inspired superboss.

The opponent should feature:

- A carefully optimized team.
- Strong IV/EV-style development.
- Sophisticated tactical AI.
- Championship-caliber decision-making.
- Real, exploitable weaknesses.
- A difficult but beatable encounter.

This is intended as an aspirational challenge for highly invested players.

### 69. Competitive leaderboard

The long-term vision includes players building highly optimized teams and competing for top leaderboard positions.

This may also support community engagement and marketing in future expansions.

Exact ranking, anti-cheat, matchmaking, and reward systems remain undecided.

### 70. Hardcore Mode

Hardcore Mode is on the Afterburner, meaning it is a deferred future design.

No particular hardcore rules have been approved.

Permadeath, irreversible party loss, special difficulty multipliers, and other common hardcore conventions must not be treated as canon without further discussion.

Normal gameplay must remain unaffected until the mode is designed and authorized.

## Part XII — Technical Architecture and Development Research

### 71. Current technology

The project has been developed around Python and Pygame.

| Component                        | Established context                                    |
| -------------------------------- | ------------------------------------------------------ |
| Language                         | Python                                                 |
| Framework                        | Pygame 2.6.1                                           |
| Previously reported local Python | 3.8, 32-bit                                            |
| Packaging requirement            | Python 3.10+ in `setup.py`                             |
| Architecture                     | Event-driven pub/sub                                   |
| Automated testing                | `test_game.py`                                         |
| Documentation                    | Markdown reports and roadmap files                     |
| Art assets                       | Placeholder graphics required where assets are missing |
| Repository                       | `eliBrownn/SolHunterSource`                            |

The Python version mismatch is a known technical issue, not an approved decision to downgrade the project's requirements.

### 72. Event-driven architecture

The project uses a publish/subscribe design to decouple systems.

This is especially important because Vastra, Sol ecology, combat, world simulation, weather, and narrative consequences can affect one another.

For example, a human activity event may influence overload, which later affects ecology and storm eligibility.

Those systems should communicate through events rather than becoming a single tightly coupled module.

### 73. Modular game systems

The development research has emphasized reusable systems for:

- Entity and component management.
- Event handling.
- Asset loading and placeholders.
- Combat calculations.
- Sol attributes and relationships.
- Environmental simulation.
- Persistence and saving.
- Testing and diagnostics.
- Modular rendering and visual effects.

The architecture should support gradual expansion without requiring every system to be rewritten as new regions are added.

### 74. Vastra implementation architecture

The finalized Vastra design suggests several independently testable subsystems.

| System          | Responsibility                                             |
| --------------- | ---------------------------------------------------------- |
| Concentration   | Track ambient Vastra per tile                              |
| Equilibrium     | Redistribute and replenish Vastra                          |
| Harvesting      | Apply sustainable and excessive energy use                 |
| Overload        | Track ecological destabilization                           |
| Propagation     | Spread overload between adjacent tiles                     |
| Restoration     | Apply natural and population-based recovery                |
| Affinity combat | Calculate matching environmental damage bonuses            |
| Storms          | Detect qualifying 3×3 areas and evaluate storm probability |
| Exposure        | Determine human environmental effects                      |
| Examination     | Display environmental diagnostics                          |
| Persistence     | Save relevant environmental state                          |

These are recommended implementation boundaries, not claims that the corresponding modules already exist.

### 75. Performance principles

The game should prioritize efficient simulation, particularly for portable hardware such as the AYN Thor.

The design favors:

- Detailed simulation near the player.
- Aggregate simulation at a distance.
- Sparse, biome-sensitive Sol populations.
- Bounded environmental updates.
- Modular rendering.
- Configurable numerical parameters.
- Tests for critical interactions.

A living ecosystem should not require full simulation of every distant individual every frame.

### 76. Roadmap structure

Earlier roadmap work included a milestone structure from M0 through M10, covering the foundation, persistence, world, ecology, onboarding, combat, collection, narrative, UI, and release preparation.

The exact milestone definitions should be read from the authoritative roadmap before being treated as a verbatim schedule.

Vastra now needs to be incorporated across those systems, rather than implemented as an isolated late-game feature.

## Part XIII — Canon Register

This section separates what is approved from what is still under consideration.

### 77. Confirmed foundational canon

| Area                | Approved principle                                                  |
| ------------------- | ------------------------------------------------------------------- |
| Genre               | Dark-fantasy creature-collecting tactical RPG                       |
| Gameplay pillars    | Exploration, collection/development, tactical combat                |
| Region One          | Approximately 151 Sols, level cap 55                                |
| World               | Authored civilization and landmarks combined with living wilderness |
| Vastra              | Natural, replenishing energy that seeks equilibrium                 |
| Environmental model | Independent concentration and overload scales                       |
| Human impact        | Humanity can disrupt natural equilibrium                            |
| Harvesting          | Sustainable ambient harvesting safe; excessive use damaging         |
| Sol extraction      | Direct extraction from living Sols inherently harmful               |
| Sol identity        | Physical living beings with persistent individuality                |
| Class and affinity  | Species class fixed; individual affinity independent                |
| Evolution           | Three ordinary forms, distinct legendary fourth manifestation       |
| Propagation         | Compatible same-lineage energy-based reproduction                   |
| Natural death       | Peaceful, restorative, no explosion                                 |
| Unjust death        | Potentially destructive; intent and circumstances matter            |
| Ecological recovery | Natural recovery with population-based contribution                 |
| Aggressive Sols     | Often territorial protectors, not inherently evil                   |
| Seals               | Soul contracts holding actual Sols                                  |
| Relationships       | Contractual authority does not guarantee trust                      |
| Combat              | Tactical positioning and environmental interaction                  |
| Vastra damage bonus | Affinity-matched damage only, proposed +99% ceiling                 |
| Storms              | Probabilistic, requiring a qualifying 3×3 footprint in simulation   |
| Legendary identity  | Distinct primordial being manifested through a vessel               |
| Starter             | Cannot die; legendary choice has irreversible consequences          |
| Antagonist          | Technically knowledgeable extremist seeking humanity's destruction  |
| Region One outcome  | Humanity survives; ending variations                                |
| Long-term vision    | Multiverse and competitive systems deferred                         |

### 78. Provisional or partially approved design

| Area                       | Current position                                                       |
| -------------------------- | ---------------------------------------------------------------------- |
| Eighteen classes           | Structure established; full names and identities provisional           |
| Capture rates              | Working combat and peaceful capture models                             |
| Official transfers         | Possible stat bonus and administrative costs                           |
| Forced transfers           | Possible negative consequences                                         |
| Evolution levels           | Starter target around 36; applicable pseudo-legendary target around 55 |
| Ability roster             | Working target of 36 innate abilities                                  |
| Sol behaviors              | Limited readable behaviors per species                                 |
| Equipment bonuses          | Generally small passive effects                                        |
| Visual resolution          | 32×32 pixel-art planning reference                                     |
| Ordinary recovery time     | Approximately 1–3 in-game days                                         |
| Population simulation      | Detailed nearby, aggregated at distance                                |
| Regional ecological cycles | Incremental implementation                                             |

### 79. Explicitly unresolved questions

Open canon and implementation questions

These are genuine gaps, not decisions I have silently filled in.

- Full final names and definitions of all 18 classes.
- Distinctive display names for the approved eight-affinity roster; numerical color values remain editable art tuning.
- Vastra concentration-to-damage scaling formula.
- Storm thresholds, probabilities, severity, and cooldowns.
- Exact ecological carrying-capacity and restoration formulas.
- Detailed human exposure symptoms and protection thresholds.
- Precise propagation and affinity-inheritance weights.
- Classification of exceptional Sol deaths.
- Exact capture and transfer formulas.
- Final move, ability, IV/EV, and progression formulas.
- Legendary memory inheritance and bond requirements.
- Exact ending scenes and lasting relationship/story consequences for the approved harder-but-winnable starter-refusal route.
- Reconciliation of permanent legendary refusal with eventual collection goals.
- Antagonist identity and exact operational plan.
- Final multiverse, leaderboard, and Hardcore Mode mechanics.

## Part XIV — Recommended Development Priorities

Based on the approved design, the most practical development order is:

1\. Stabilize the foundation

Resolve critical code defects, version compatibility, saving, event handling, and automated testing before expanding complex gameplay.

2\. Establish world and Sol foundations

Implement reliable world tiles, entities, movement, encounter rules, and persistent ecological territories.

3\. Implement foundational Vastra simulation

Add concentration, equilibrium, replenishment, overload, and environmental examination before introducing complex storms.

4\. Complete the core gameplay loop

Connect exploration, Sol encounters, tactical battles, capture, relationships, and progression.

5\. Expand the living ecosystem

Add natural restoration, human disruption, overload propagation, storm eligibility, and persistent notable Sols.

6\. Deliver the Region One narrative

Integrate the antagonist, legendary storyline, major choices, authored locations, and complete ending.

7\. Polish and expand

Improve visuals, balance, accessibility, performance, and content. Preserve multiverse, hardcore, and major competitive features for later development.

## Part XV — The Complete Vision

SolHunter is a world where energy is not inherently dangerous, where nature is capable of maintaining its own balance, and where humanity's choices determine whether that balance is preserved or destroyed.

Sols are living beings rather than mere resources. They can be aggressive, affectionate, protective, resistant, curious, or difficult. Their value is not limited to how useful they are in combat.

A Solhunter's relationship with a Sol is not defined solely by the possession of a Seal. Trust must be earned, and even a trusted companion may possess a destiny that cannot be reduced to the player's wishes.

Vastra ties these ideas together.

It powers civilization, supports the ecology, shapes the battlefield, and provides the medium through which legendary beings can manifest. Its natural equilibrium contrasts with humanity's capacity to exploit it.

The antagonist represents the destructive extreme of that relationship: someone who claims to defend nature while treating living Sols as expendable instruments of catastrophic change.

The player stands between those possibilities.

Through exploration, companionship, battle, and difficult choices, the player experiences a world that responds to how it is treated.

The central promise of SolHunter is therefore more than collecting powerful creatures.

It is discovering what it means to live alongside beings that possess their own identities, their own purposes, and their own place in the natural world.

### Research completeness and source limitations

This message consolidates the major research and decisions available from our conversations, including the completed Vastra design review. It is substantial, but it should not be mistaken for a line-by-line reproduction of every historical Bible draft.

The exact complete 18-class roster, original narrative passages, detailed move lists, and some older technical specifications could not be reconstructed verbatim from the available material. I have intentionally left those gaps visible.

No project files or GitHub documents have been edited as part of this compilation.

SolHunter Worldbuilding Bible — consolidated research edition. Confirmed canon, provisional design, and deferred concepts remain distinct until incorporated into the authoritative project documents.

## Owner-approved affinity, move, and battle-imprint rules — October 27, 2026

These explicit owner decisions supersede earlier provisional affinity lists,
neutral-move assumptions, and any suggestion that battle imprints naturally revert.
They do not finalize unspecified numerical balance or distinctive replacement names.

### Affinity roster and identity

Each individual Sol has an affinity independent of its species and fixed class.
The ordinary roster is Fire, Water, Earth, Air, and Lightning. Void and Spectral
are rare special affinities; Quantum is the rarest. Special affinities offer
unusual capabilities with meaningful tradeoffs, not greater overall power.
Environment and combat are equally important uses, with combat emphasizing
terrain and battlefield conditions. Conditions generally affect both sides;
positioning determines the advantage.

| Working name | Approved color direction | Approved role |
| --- | --- | --- |
| Fire | Orange | Spreading heat, prepared bursts, smoke and embers |
| Water | Blue | Currents and wet terrain, with a smaller role for each |
| Earth | Ochre | Barriers, rough ground, stable footing |
| Air | Pale cyan | Directional winds, displacement, dispersing smoke |
| Lightning | Yellow | Conductive paths, warned charge/discharge zones, action and movement disruption |
| Void | Deep violet | Warp zones shorten some routes and lengthen others, affecting both sides |
| Spectral | Mint | Cross thin obstacles, but finish on legal open ground |
| Quantum | Shifting pink/cyan | Mix superposition, probability, and entanglement; player-chosen outcomes within clear limits, little randomness |

Explore distinctive names without changing these meanings. Exact rarity rates,
ability costs, durations, ranges, learning progression, and effect interactions
remain authoring/balance decisions. The October 28 retcon permits aggressive
Vastra-powered abilities to originate overload on affected tiles. Healing abilities
reduce it independently of HP restored and may create negative restorative conditions.

### Moves and species learnsets

A Sol equips at most four moves. Additional learned moves remain remembered and
can be swapped outside battle. A species has an explicit learnable move pool;
that pool determines eligibility even when a move differs from the individual's
affinity. Every move has an assigned affinity. Innate abilities remain distinct
from equipped combat moves.

### Battle activity and lasting tile affinity

Only successful moves contribute activity, using the move's assigned affinity,
not the acting Sol's affinity. A move is successful if it produces at least one
intended effect: damage, healing, status, or a terrain/field change. Movement,
deployment, and waiting contribute nothing. A successful move contributes one
activity event; hitting more tiles does not create extra move events.

Track the union of successful moves' target/effect tiles. Include the user's tile
only when the move affects it. At every resolved battle outcome—victory,
exhaustion, or retreat—the most active affinity replaces affinity on every tile
in that union. Break an activity-count tie using the latest successful move
belonging to one of the tied affinities. With no successful moves, there is no
imprint. This rule replaces the earlier acting-Sol contribution proposal.

The new tile affinity persists and does not naturally revert. Other terrain
conditions persist after battle and gradually recover through simulation.
Recovery must preserve the new affinity. Saving/loading must retain learned and
equipped moves, tile imprints, and remaining condition recovery without replaying
battle completion or reapplying environmental overload/restoration effects.

Owner-approved legacy migration: Grove → Earth, Ember → Fire, Tide → Water,
Gale → Air. Preserve individual identity, species/class, health, and progress.

## Owner-approved individual stats and class buffs — October 27, 2026

Sols have six core combat stats: HP, Attack, Defense, Special Attack, Special
Defense, and Speed. Each individual independently rolls lifelong 90–110%
natural potential for each stat, with results concentrated near 100%. There is
no shared potential budget: some individuals may be stronger overall. Species,
level, and locked IV percentages determine automatic natural growth.

Only battle training points are player-assigned. This supersedes the earlier
two-pool growth-point proposal and its separate +40% bonus. Training can add up
to 10% per stat, with a total budget sufficient to maximize three stats and
nothing left over. Capacity is 50%, 75%, then 100% across three ordinary forms;
shorter lines reach full capacity in their final available form, including
single-form species. Evolution preserves the same IVs.

Training requires direct contribution to defeating an opponent, including
effective healing, protection, debuffs, or terrain support as well as damage.
Stronger opponents grant more training; much weaker opponents eventually grant
none. Wild Sols have no training investment. Only training allocations can be
redistributed, through a limited item or paid service. Players can see exact
natural percentages and training bonuses separately.

Each class has its signature passive with potency varying between individuals.
Beast gains a 5–10% bonus for its occupied tile's affinity. Cinderkin's Kindling
has a fixed individual growth rate of 1–5% per attacking turn, retaining the
15% cap and reset on a non-attacking turn. Other accepted passive behaviors and
their adjustable initial ranges are recorded in [class buffs](../class-buffs.md).
Class remains separate from individual affinity and does not consume a move slot.
The current implementation interprets Beast as increasing direct damage from a
move matching the occupied tile's affinity, without requiring matching individual
affinity. This interpretation and unspecified balance values remain adjustable.

See [individual stats](../sol-stats.md) for implementation, save migration,
training controls, and the boundary between supported evolution preservation
and evolution content that still needs authoring.

## Owner-approved opening, companionship, and consequences — October 28, 2026

The owner authorized incorporating the creative questionnaire and subsequent
correction. These directions supersede earlier provisional opening and final
creature-presentation assumptions. They record design, not implementation.
See the [dated decision](../decisions/2026-10-28-opening-companionship-and-consequences.md)
for roadmap implications, source evidence and remaining gates.

### Opening and everyday companionship

Lead with unease and mystery. The player wakes in a Vastra storm, tries to escape,
and three Sols guide them to safety. One of those same individuals becomes the
starter; preserve that identity through rescue and companionship. The starter
shows curiosity and personality while accompanying the player.

Approved follow-up, October 28: storm escape teaches movement, sprinting and
basic storm escape through play. The rescuers mysteriously left their NPC owner
to save the player. After escape, that owner permits the player to keep one;
interactions suggest a bond and the player explicitly confirms the choice.
The NPC gives the player a first protective mask for Vastra storms, teaches the
basics and provides a first teaching battle, preparing them to cross the wilderness
and find the first refuge camp. Retain the actual rescuer's identity throughout.
The reason for the rescue, NPC/rescuer identities, protection efficacy, exposure,
failure/checkpoint rules, battle setup and contract transfer details remain open.
The mask does not establish immunity or mandatory consumable upkeep.

Patient, nondestructive and respectful behavior supports earning wild Sol trust,
analogous to earning an animal's trust. A Seal's holding authority still does not
guarantee affection or cooperation. Trust formulas and specific interactions
remain to be authored without compulsory repetitive upkeep.

Civilization's need for Vastra to run daily life grounds the human/habitat
conflict. Sustainable ambient harvesting remains safe; dependence alone does not
mean exploitation. The storm's origin, exposure effects, failure/checkpoint rules,
rescue species and detailed selection staging remain open. An authored narrative
storm remains distinct from ordinary weather and procedural storm admission.

### Creature presentation and adventure loop

Affinity orbs are placeholders. Each production Sol species has its own model,
behaviors and animations, while individual identity and independently assigned
affinity persist. This supersedes the earlier pixel/sprite pipeline as the final
presentation target; the approved full-3D direction continues.

Combat should connect strategic play, leveling, training, journal discoveries and
lore in a satisfying creature-collecting adventure. The owner's "classic Pokemon
2.0" description expresses that ambition, not copied mechanics or approval of new
reward formulas. Exact journal/lore triggers and encounter durations remain open.
Named creative references are Monster Hunter, Pokemon, Pokemon Legends: Arceus,
and The Legend of Zelda: Tears of the Kingdom; their precise stylistic roles
remain provisional.

Approved visual priority: strong stylized shapes and clear creature silhouettes.
Introduce civilization's Vastra dependence through protective refuge infrastructure;
contrast human order with living wilderness. Review a playable short route spanning
refuge, habitat and encounter. The first journal discovery reveals an observed Sol
behavior and useful habitat clue, without implying a numerical reward. Routine
victory should feel earned through understanding the opponent and terrain.

### Refusal, victory, and lasting consequences

Refusing the starter's legendary request permanently forfeits that starter's
legendary manifestation in that save. Victory without ascension remains possible
through a harder path, showing the original Sol was capable either way. Refusal
also produces lasting relationship and story consequences. The owner's temporary
selection of difficulty/access alone was withdrawn in favor of this broader
direction. Winning does not automatically erase those consequences. The approved
first narrative expression to explore is a changed but enduring relationship with
the starter; the exact consequences remain unresolved.

The original starter cannot die. Exact consequences, ending scenes and choice
warnings remain unresolved. Do not infer wider ecological damage, numerical trust
loss or random command refusal. Later in-game collection or separation must not
bypass the permanent lockout. External save editing/restoration contingencies are
still under consideration; no online requirement or anti-cheat system is approved.

### Release-device selection

AYN Thor remains the intended release platform. Select the configuration with the
largest verified unit sales when reliable evidence is available. This review did
not verify a model-level sales leader. Exact configuration, resolution, frame-rate
and memory budgets remain open; desktop results do not establish device acceptance.

## Owner-approved exploration, companionship and Vastra direction — October 28, 2026

Recorded at the owner's explicit request following the exploration/companionship
questionnaire. These are design commitments, not delivered runtime features.
Unresolved mechanics below remain open; candidate locations and reviewer
suggestions are not approved content merely because they were discussed.

### Vastra as the authoring anchor

Establish possible authored places and events across nature, people, quests,
Vastra phenomena and other parts of the adventure. Vastra intertwines with all
of these as the world's authoring anchor. For each authored place, establish:

- Its Vastra conditions: what sustains the place, what changes, and what
  inhabitants can perceive.
- Its ecology: how those conditions support particular Sols and their observable
  behavior.
- Its human relationship: how people live with, depend on, protect against or
  exploit those conditions.
- Its possibilities: discoveries, encounters, conflicts and choices arising
  from those relationships.
- Its continuity: what changes naturally or through player action, and what a
  return visit reveals.

Specific location rosters, events, quest structures and persistent outcomes still
need authoring. The framework does not approve the example catalogue discussed
in the questionnaire's surrounding conversation.

### Perceived danger and learning through Sols

Early exploration establishes fear of Vastra, reinforced by human interactions.
Humans view it as an opposing force to control and maintain. Sol interactions
can contradict that understanding if the player allows themselves to see it.
This is a narrative perspective, not a repeal of actual environmental hazards or
the established safety of sustainable ambient harvesting.

The opening's major storm is pure Vastra: all affinities together. After that
experience has instilled fear, a smaller forming storm matches the starter's
randomly assigned individual affinity, independently of its species or class.
The Sol approaches because it understands/is comfortable with the phenomenon
and wants to show the player that it can protect them and that the experience
need not be dangerous. Its intention relates to why it chose the player, while
the deeper reason remains ambiguous rather than fully explained.

The player explicitly agrees to follow. Vastra visibly flows around the player
and Sol; the energy remains present. The player may decline rather than being
forced immediately into the demonstration. Storms eventually prevent further
travel until the player listens to the Sol and learns the mechanic. Exact route
gates, repeat invitations and activities available before acceptance remain open.

Late-game interactions with Sols may establish immunity and show that flowing
with Vastra can be beneficial where humans push against it. The mechanism remains
unresolved. A lasting ability learned through companionship is narratively
interesting to the owner, not an approved ability or progression rule.

The small-storm scene does not establish universal protection, immunity to pure
Vastra, or a complete affinity/protection matrix. Range, duration, exposure,
failure/checkpoint rules, the protective mask's relationship to Sol protection,
and procedural storm admission still require specification. Pure Vastra's
all-affinity description does not add a ninth individual affinity or alter
existing combat-affinity rules.

### Companionship through understanding and treatment

Center companionship on treating the individual Sol well and understanding its
species. Use general core interaction systems with species specialties.
Discovery hints can reflect species knowledge, individual personality, treatment
and bond; exact dependencies, thresholds and whether hints can be missed or
misunderstood remain open.

Sols can hint toward rare Sols, rare items and special areas. Species have special
locations and events they can trigger. Communication develops as a byproduct of
finding places. Specific signals, interactions, triggers and rewards remain to
be authored rather than assumed from following or idle animations alone.

Both player and Sol should be customizable. Sol customization primarily expresses
combat features/development, such as bigger flames, with occasional cosmetics.
Exact unlocks, costs and effects remain open. Play is optional: enforcing it would
create unwanted barriers. This direction preserves species-specific care, shared
ordeals and consistent choices as the established foundation for bond development;
it does not approve mandatory repetitive upkeep or a numerical trust formula.

### Feedback retained for further decisions

Review suggestions were to preserve meaningful activity before the storm gate,
distinguish genuine danger from incomplete human understanding, and develop
everyday companionship between major story scenes. These are considerations for
the next questionnaire, not additional settled mechanics. Protection rules and
the first authored locations/events remain the next design questions.

### Follow-up answers: storm access and first discoveries

For ordinary affinity storms, matching individual affinity is required for a
Sol's protection; other affinities need another approach. The owner additionally
states that Quantum Sols have a built-in affinity boost to all. Their exceptional
storm relationship is clarified in the follow-up below; exact scope and magnitude
remain open. Do not infer pure-storm immunity or new combat bonuses.
This resolves the ordinary matching requirement above, while protection range,
duration and the remaining matrix details stay open.

The mask supports basic exposure, while Sol protection enables deeper passage.
Exact exposure limits and protection values remain open. Before accepting the
first storm invitation, players can explore the starting zone, participate in
basic battles and undertake basic quests teaching the basic mechanics.

The first species-specific location should trigger an event combining discovery
with learning about the Sol. The particular location and event are not yet
selected. The requested poor-treatment suggestions were subsequently reviewed;
the accepted direction is recorded below.

### Follow-up answers: respectful treatment and the storm spectrum

Use a gradual, recoverable response to poor treatment. A Sol first signals
discomfort. Repeatedly ignoring clear signals makes it less willing to initiate
optional discoveries or close interactions. Respecting its boundaries and
responding to species needs rebuilds cooperation through ordinary adventures,
without routine relationship decay or mandatory play.

The initial, revisable poor-treatment examples are repeatedly pushing onward
after clear distress, interrupting chosen rest, and forcing an interaction the
Sol has rejected. Exact signals, repetition thresholds, recovery pacing and
species/individual differences remain to be authored. This decision does not
establish combat-command refusal or penalties for a first misunderstanding.

Players learn needs through readable Sol behavior, supported by journal knowledge
gained through discovery. Interactions with people can also provide journal
entries and help the player understand a species.

Most Vastra storms result from the buildup of one affinity. Pure Vastra storms
are almost impossible to create by force; this is not an absolute impossibility
or a specification of a storm-generation recipe. Pure storms are typically hard
for a Sol with an assigned affinity to help the player traverse. Quantum Sols
are special in this regard because they synergize with the whole spectrum,
clarifying their exceptional all-affinity storm relationship above. Exact
protection efficacy, limits and pure-storm traversal requirements remain open;
this does not establish effortless passage or universal immunity for Quantum.

### Follow-up answers: exploration anchors and the first species discovery

After reaching the first refuge, a concrete local problem draws the player onward
and leads into a larger mystery. The specific problem, people involved and mystery
remain to be authored.

The first species-specific discovery begins with the companion leading the player
to a secluded place where its species gathers around a Vastra phenomenon. This
selects the encounter concept, not the species, phenomenon, gathering behavior or
reward. Those details remain open, as does how the location accommodates a starter
whose individual affinity is independent of species.

Combine fixed story anchors with seed-placed optional discoveries. Godot's
world-generation engine remains the generation authority. Placement constraints,
route guarantees and the technical treatment of fixed anchors still require
design; this direction is not an implemented generation change.

Revisiting discovered places should be worthwhile through changes in inhabitants,
Sol behavior and local conditions. Specific change triggers, timing and persistence
remain open. This answer does not establish bond or species requirements for
repeat access, or require every location to change on every visit.

### Follow-up answers: the gathering's healing phenomenon

For the first refuge problem, the owner selected both changed local Sol behavior
alarming residents and someone failing to return from a nearby site. The owner
explicitly clarified that "2/3" means options 2 and 3, not undecided alternatives.
The subsequent answer connects both elements in one investigation. The missing
person's name is Stephan. The specific connection and Stephan's fate remain open.

The secluded species gathering reveals how the species experiences and responds
to Vastra. Individuals of different affinities gather, causing a pure Vastra
healing phenomenon: the opposite of a Vastra storm. This is the owner's authored
event direction; it does not mean every mixed-affinity gathering automatically
creates such a phenomenon. It is a recurring natural event that humans seldom
witness or understand. Balanced circulation distinguishes the healing phenomenon
from a storm's unstable buildup. The required affinities, exact conditions and
recurrence interval remain open.

The player's involvement at the gathering is a choice. Available actions and
their consequences still need authoring; observation, participation or assistance
are not compulsory merely because they appeared as questionnaire suggestions.
The phenomenon visibly restores both the habitat and living beings present.
Exact ecological effects, safety and mechanical recovery benefits remain open.
Pure Vastra can appear in this healing event as well as in the opening storm;
the difference is balanced circulation versus unstable buildup.

The owner specifies that the phenomenon should be folklore. Develop its human
presentation through that framing; exact tales, names, tellers, local beliefs
and how accurately they describe the phenomenon remain to be authored. Preserve
the Bible's established distinction between a coherent underlying reality and
different local interpretations of it.

### Follow-up answers: conflicting folklore and gathering choices

Local folklore about the gathering has conflicting versions: a warning in some
households, a blessing in others. Specific accounts, their origins, names and
tellers remain to be authored. The missing person's connection to the folklore
remains open while these accounts are developed.

Develop gathering choices that let the player watch, join when invited, let their
Sol participate independently, or leave. The event continues without needing the
player. Choices change what the player experiences and learns; respectful
observation is not a failure. Exact interactions, discoveries, journal entries
and any later consequences remain open. This approves the participation approach,
not a requirement for every choice to grant identical information or rewards.

### Follow-up answers: the ancient grove and its inherited stories

The gathering takes place in an ancient grove reached by following Sols away
from familiar paths. The shared sign behind conflicting folklore is that Sols
fall silent and leave their familiar paths. Some households interpret this as
the Sols being lured away; others say they are answering a place of renewal.
Those who preserve the blessing version maintain an inherited custom without
fully understanding it. The custom's actual practice remains to be authored.

The inherited custom is a quiet vigil when the familiar Sols leave.

The owner approved developing the proposed joining scene: gathered Sols settle
among old roots while their different affinities become visible in currents
circulating through the clearing. The companion joins them, then turns back and
waits for the player's agreement. On acceptance, the player walks into the
clearing under their own control, accompanied by their Sol, as Vastra flows around
both. Nearby damaged leaves recover and a weary Sol gradually relaxes. The
companion settles beside the player, showing a comfort not seen during travel.
The player can remain or step away. Watching from the edge still reveals the
healing; joining offers a closer shared experience of the companion's relationship
with Vastra. Mechanical healing benefits, timing and species-specific staging
remain open.

Keep this grove visit focused on the Sols. Advance Stephan's search elsewhere;
do not place Stephan or a search-advancing trace in this first gathering visit.

### Stephan's narrative role

Stephan is a rival whose journey parallels the protagonist's. His disappearance
introduces him through the refuge investigation; his motives, background,
relationship with the player and eventual circumstances remain open. Rivalry
does not by itself establish antagonism, cruelty, a fixed ideology or a required
sequence of battles. His initial connection to the changed Sol behavior is
recorded below; the first grove visit remains focused on the Sols.

Stephan is initially unfamiliar to the player; their rivalry emerges after they
meet. The refuge considers him missing because he pursued an investigation
independently and has not returned. He already questions the accepted human view
of Vastra. His selected circumstances and the investigation's initial connection
are recorded below; his wider background and character arc remain open.

### Approved refuge investigation and trail meeting — October 28, 2026

Sols leave before the refuge's instruments detect anything unusual. Residents
fear approaching danger, and someone has begun shutting gates to keep familiar
Sols inside. Stephan suspects the instruments capture only part of what is
happening. He follows Sol behavior beyond the maintained routes. The player's
companion responds to something along the route he took.

The player finds Stephan safe on an ordinary wilderness trail where wild Sols
approach a particular stretch, hesitate and turn back. Nothing about the place
looks significant at first. He has spent hours watching. His own companion
refuses to cross; he respects its warning but is frustrated because he cannot
understand it. The player's companion notices the same boundary but responds
differently. Stephan notices immediately, giving them a shared mystery and a
reason to investigate together before their rivalry develops.

The ordinary trail replaces the proposed shelter setting. An abandoned research
center or facility is rejected for this meeting. The first healing-grove visit
remains separate from Stephan's search.

Approved companion response: the player's Sol hesitates, then follows the edge
of the boundary, stopping to listen at different points. It checks back toward
the player without crossing. What it senses remains open; Stephan's exact
dialogue and his companion's subsequent response are not yet selected.

The cause of the boundary and departures, what the player's companion senses,
search clues, instrument details, resident identities, Stephan's background and
companion species, and the subsequent rivalry remain open. This approves story
direction, not new detection, traversal or companion mechanics.

## Owner-approved Vastra visual direction — October 29, 2026

### Develop the look first

The owner wants to develop Vastra visually now, building the technical/code
approach around its appearance. Establish and review the look before expanding
the supporting systems. The existing short, isolated floating ribbons were
described as looking like strange parasites; they are not the intended visual
target. This direction is approved design, not a claim of implemented rendering
or completed discovery mechanics.

### Subtle quantum web

Vastra should visually resemble a subtle quantum web woven through the
environment: connected, mostly transparent moving air, with light catching its
edges. "Quantum web" describes its appearance; it establishes no new physics or
consciousness rules. Refraction, restrained chromatic aberration and reflected
light reveal its connections. Subtlety is essential: the landscape remains
dominant, and observation makes the web apparent.

Ordinary Vastra remains faintly visible away from discoveries. It becomes more
apparent the closer the player is. Limit its rendering to an adjustable radius
around the player and fade it smoothly with distance. Preserve the ability to
notice a gathering farther away within that radius; do not require unlimited
rendering distance to communicate a discovery.

Daylight reveals refraction and edge glints. Darkness reveals a faint affinity
glow. Preserve pure Vastra's normally transparent, full-spectrum white-light
identity and the approved affinity palette. Exact brightness, aberration,
opacity, viewing radius and transition distances remain visual tuning.

### Layered movement

Combine the three selected movement qualities: slow broad currents bending
around terrain with occasional eddies; smaller ripples and drifting glints;
and gentle surges with pauses, giving the landscape a breathing rhythm.
Use these at complementary scales so the result reads as connected environmental
flow rather than separate floating creatures. The exact rendering method is
open and should serve the approved look.

### Exploration purpose

Vastra's primary visual purpose is to draw attention toward places worth
exploring. Following a clue should offer a worthwhile discovery, while requiring
observation and exploration and leaving its safety uncertain. It is a reliable
reason for curiosity, not a promise of safety or an explicit route marker.

Flows converge or disappear into something intriguing. Stronger continuity and
convergence distinguish discovery currents from faint ambient movement. Either
nearby motion can lead the eye deeper into the landscape or a distant gathering
can invite the player to find a route there, depending on the place. Potential
destinations span Sol activity, unusual habitats, ruins, resources and danger.

Before arrival, the current suggests affinity and intensity while leaving the
discovery itself and its safety uncertain. At the destination, it can visibly
interact with the attracting feature by circling, entering, escaping or being
absorbed, or open into a larger local phenomenon the player can explore. Choose
the behavior to suit the discovery.

### Implementation boundaries and review

Build the presentation around this visual target. The existing ribbon mesh,
shader and placement pattern are implementation choices, not design constraints.
Keep rendering ownership separate from ecological state and preserve the
existing concentration/overload distinction. This approval does not define
new attraction, harvesting, reward, danger, discovery-placement or ecological
simulation rules; consult the mechanics reference before changing those systems.

Initial visual review should establish connected flow, subtle close-range
readability, smooth distance fading, daylight refraction and faint nighttime
affinity glow. Develop discovery convergence visually before claiming it is
connected to real generated destinations. Numerical tuning, web geometry,
lighting technique and the final code architecture remain to be developed.

### Step 2 owner clarification — October 29, 2026

Develop the web across scales, evolving from large forms into small detail rather
than displaying a single strand. Broad transparent folds should resolve into
finer web-like structures, refracting light with chromatic aberration. The
aberration has a primary color based on the local tile's affinity and a secondary
color complementary to that primary. This optical pairing does not create a
second tile affinity. Pure/neutral Vastra retains its transparent white identity.

The visible flow should travel toward places of higher Vastra concentration,
evoking a web of space. This approves a visual response to existing readings;
it does not redefine concentration transport or ecological simulation. Keep this
distinct from later connection to actual exploration discoveries.

The owner could not see the initial effect and clarified that visibility should
not require being extremely close. Start with an approximately 5–8 tile viewing
radius: readable within about five tiles, fading toward an eight-tile outer
boundary. Maintain the subtle appearance while making the effect perceptible at
ordinary exploration distance. Exact optical strengths remain tunable.

### Spatial web, living centers and exaggerated review — October 29, 2026

The owner rejected all three observed problems: repeating waves/loops, a pattern
laid flat across the ground, and separate ribbons rather than a connected field.
Develop an irregular spatial web with large and small connected branches, rising
into the environment. Give it a clear overall direction of flow, like a gentle
gravitational pull, and a gentle traveling pulse.

Concentration should gather around living objects rather than being centered on
the player, and remain faint where life is absent. The player controls the local
viewing window; plants and Sols provide world-anchored centers. Preserve the
independent local tile affinity and its complementary optical color pairing.
This is the visual-first direction; life-dependent simulation values, if added,
must be reconciled with the mechanics authority rather than inferred from visible
object counts.

After the first effect was too faint to see, the owner explicitly requested an
extreme visual preset that can be dialed back. Exaggerated refraction, color
separation and highlights are approved for this review, not a replacement of the
eventual subtle quantum-web target.

The owner further rejected squiggly motion and asked for currents of air using
air mechanics. Treat coherent flow as the foundation: steady directional air
movement, gentle three-axis drift and an inward attraction toward living centers,
with restrained variation rather than noise contours acting as the motion itself.
Slopes must not flatten or distort the pattern into a ground decal. The owner
also observed poor performance; keep visual iteration playable and measure the
cost rather than assuming that a small local radius is sufficient.

### Cosmic-web structure correction — October 29, 2026

The owner rejected the implemented airflow/ribbon prototype as still incorrect.
The underlying structure is an irregular cosmic web: broad regions narrowing
into fine connections around living things. Nearby living things share a broad
region; finer connections bridge between groups. This establishes group-scale
regions as the main structural level, rather than a separate node or halo for
each individual organism.

Treat the web as continuous three-dimensional density, with broad regions tapering,
branching and merging into finer connections. Light/refraction reveal this density.
The prior ribbon implementation and passing engineering checks do not establish
visual acceptance. Establish a structure study before another renderer rewrite.
Retain the previously selected local-affinity/complementary optical pairing,
subtle eventual appearance, faint empty space, living world anchors, coherent
flow, gentle pulse and starter 5–8 tile viewing radius.

### Approved structure image and signal motion — October 29, 2026

The owner confirmed that the generated
[cosmic-web structure study](visuals/vastra_cosmic_web_structure.png) represents
the idea: broad shared regions around nearby groups of living things, narrowing
into fine connections between groups. See its [reference and prompt](visuals/vastra_cosmic_web_structure.md).
Lower the image's visibility for the game and animate flow through that structure.

The owner separately confirmed that the existing in-game spatial warping is
mainly right. Preserve that optical distortion while changing the visible
structure and motion. The effect must be thin and wispy like energy, flowing
smoothly in a clear direction. The owner rejected motion like a moving blanket:
do not sway the whole visible carrier back and forth as the flow cue.

Use the analogy of a nervous system sending signals for motion: brief impulses
travel through fine connections, branch and merge, and arrive at shared living
regions. The underlying web remains faint between signals. This is a visual
analogy, not a decision that Vastra is conscious or that new neurological/gameplay
signal mechanics exist. Retain local-affinity primary and complementary secondary
optics, three-dimensional world anchoring and the player-local viewing radius.

### World-focused Vastra and resource re-evaluation — October 29, 2026

The owner's latest direction removes the player-local viewing radius, including
the earlier starter 5–8 tile radius. Vastra belongs to world locations and shared
living regions. The explorer does not center, create or intensify it. Ordinary
render culling and streaming remain presentation concerns, not an energy boundary.

The owner delegated visual judgment and supplied wind, distortion, PSX and
Rokojori resources for re-evaluation. Preserve the approved cosmic-web structure
and spatial warping while separating sparse moving wisps from quiet refractive
density. Keep raw concentration and revealed visual density distinguishable in
debug heatmaps; neither should invent simulation values.

Owner-authorized coordination clarified that vegetation supports richer visual
revelation and affinity color, while Sols dissipate the effect rather than acting
as positive emitters. This supersedes earlier Sol-centered visual attraction.
Ordinary exploration remains quiet; stronger existing concentration increases
aberration and motion smoothly. Event mechanics remain outside this visual pass.
See the [resource evaluation](../research/vastra-resource-evaluation.md) for the
delivery decision and the supplied assets' local-only source handling.

### Astral strands — October 29, 2026

Owner artistic note: Vastra should feel like strands of the Milky Way, astral
and space-like. Use layered translucent dust veils, irregular luminous threads,
dark gaps and occasional fine star-like glints to give the currents depth.
Keep the world-anchored cosmic-web structure and smooth directional flow.
Local tile affinity still supplies primary/complementary color; this reference
does not impose a universal purple/blue palette or change Vastra's cosmology.

### Continuous astral web — October 29, 2026

The owner noted that Vastra did not feel like a web connecting everything and
approved deeper, uneven translucent clouds around sparse luminous strands, with
softer, less constructed junctions. Read as one connected landscape field:
inter-grove currents remain perceptible through otherwise quiet open space,
alternate connections weave between living regions, and their meeting points
spread through each region instead of all converging on one bright hub.
Broad asymmetric bends and overlapping veils give depth without repeating
squiggles or moving the whole carrier. Individual plants must not be enclosed
in luminous cages. Preserve local affinity colors, directional travel, Sol
dissipation and the absence of a player-centered manifestation radius.

## Owner-approved living environments, Vessels and landmarks — October 29, 2026

Recorded with explicit owner authorization to update the Bible and roadmap after
the conceptual review. This section distinguishes approved direction from example
ideas; it establishes no numerical mechanics or implementation completion.
The [concept report](../living-world-concept-report.md) retains the discussion,
and the [world roadmap](../world-exploration-roadmap.md) owns delivery sequencing.

### A world active without Sols

Roads and wilderness should feel alive even when Sols are absent. Static trees,
small props and additional creature roaming alone do not satisfy this direction.
Prioritize Vastra, world generation, biome-specific natural activity, sound and
dynamic weather. Develop meadow and woodland first. Establish nature functioning
without people or negative human interference so later disruption has a clear
baseline. This is delivery scope, not a claim that the setting lacks civilization.

The world should be mostly welcoming, with localized danger. Places should retain
recognizable identity while activity varies on revisits. Mix observation with
opportunities to interact. Use quiet stretches, frequent small details and
concentrated focal moments as different pacing treatments rather than one uniform
event rate. Unusual places and Vastra clues invite detours; unusual Vastra should
offer decisions about approaching, avoiding or interacting. Exact actions and
hazards remain to be defined; unusual appearance does not establish danger.

Observation should support behavioral understanding, further exploration and
personal journal memories. Distinct companion travel habits support individuality.
Occasional major ecological moments can become focal points; ordinary natural
variation remains distinct from overload or human damage. Existing Vastra canon,
including aggressive combat's overload effects, remains in force.

### Vessels: placeholder name for small Vastra-born wildlife

The owner establishes small wildlife distinct from Sols that come from and run on
Vastra. Their placeholder name is **Vessels**. They can be vessels of Vastra and
serve as an intermediary in environmental cueing. Particle-system wildlife is
the intended presentation concept, not a finalized taxonomy or simulation design.

Their behavior can make local conditions perceptible. Biome-specific gathering,
settling, dispersal and sheltering are candidate treatments, not approved rules.
Their lifespan, intelligence, formation/dispersal process, individual persistence,
player interactions and exact distinction from Sol biology remain unresolved.
Temporary lives and absence of individual identity are not established canon.
Actual energy transport, consumption or replenishment requires a separate
specification; visible movement must not invent concentration or overload changes.

### Landmarks as terrain, lore and event hosts

Combine authored landmark identities with generated variations. Major landmarks
join recognizable terrain, lore and event potential. They can express natural
history or an unexplained past, favoring environmental interpretation and mystery.
Distinguish observable evidence, possible interpretation and confirmed knowledge.
Smaller ambient activity should remain between events, at condition-appropriate
intensity; a quiet state need not mean an inactive place.

Weather, time, local Vastra and Vessel activity provide event conditions. Signs
should be recognizable while allowing surprise. Some events unfold independently;
handling of consequential events depends on their lasting-state implications.
Player participation can produce different outcomes. Eligibility, departure,
nonparticipation, recurrence and persistence require event-specific authoring.
No universal pause-until-arrival rule or missed-event penalty is established.

Landmark identity remains stable while situations change. Geographic placement,
ambient activity, event rules and saved outcomes have separate owners connected
through references. Godot remains generation authority; placement must preserve
required access. Conceptual landmark design resumes, while physical rollout of
the downloaded placeholder library remains on hold.

### Event ideas retained as provisional

The owner suggested Sols gathering to heal a wounded ally, playful Sol travel
through a wormhole to another location, territorial behavior and Sol dens, and
explicitly described these as ideas rather than concrete designs. Sanctuary,
passage, territory and den are proposed authoring families, not approved sites.

These new ideas do not replace the previously approved secluded gathering and
pure Vastra healing phenomenon above. Whether a wounded-ally event is related is
unresolved. Its caregiving, healing effects and player role need authoring.
The wormhole's literal nature, player traversal, destinations and lore are open;
no portal mechanic is approved. Den occupancy and territorial responses require
mechanics reconciliation. Natural landmark examples such as root hollows,
split-stone passages, meadow basins and exposed ridges remain proposals.


### Plant Vastra circulation and natural repair — October 29, 2026

Owner-confirmed direction: plants accumulate their own stored Vastra gradually
from local ambient Vastra. At a reserve of 100 they can send a visible strand to a
nearby tree and provide it with energy. Recipient selection is unbiased by need:
it must not default to the least-charged, damaged or otherwise needy tree. Trees
also relay energy onward when full, including toward trees already charged.

Owner-confirmed hierarchy requirement, October 29, 2026: every generated living
plant participates in the Vastra system through its canonical geographic identity,
including grass, small vegetation, trees and generated water/bank plants. This is
foundational to circulation, natural repair and vegetation/Vessel interaction.
Generation owns membership; the expedition owns saved energy; rendered clumps and
particles reference that state. Visual density must not create extra reserves or
exclude a plant from the system. Registration does not imply that every plant is
always charged, acting or simulated offscreen. Implementation ownership and
acceptance are specified in the
[vegetation registration contract](../vastra-integration.md#generated-vegetation-registration-and-system-hierarchy).

This is a natural balancing and self-repair mechanism, not plant/tree experience
levels. Stored plant energy, ambient concentration and ecological overload are
separate quantities. Natural circulation does not originate ecological overload.
Energy can be spent on local repair, so injury can retain and consume energy that
healthy objects would otherwise circulate. The exact costs, rates and repair scope
remain provisional authoring values rather than new canon.

The existing approved visual treatment remains: low flows close to the ground,
rarer larger flows to high tree points, traveling peaks, fading tails and restrained
motes. In actual play a visible transfer represents an actual energy packet; the
camera and particle budget do not generate, repeat or redirect energy. This
mechanic supersedes the earlier cosmetic preference for flow toward higher
concentration and the provisional destination-as-generator description. A receiving
tree receives and may relay energy; it does not create that incoming packet.

See [Vastra integration](../vastra-integration.md#plant-energy-circulation-and-natural-repair--october-29-2026)
for the initial implementation, provisional policy, source reconciliation and
remaining scope. Separate landmark/Vessel ideas retain their prior distinctions.

### Tree overflow, root circulation and Sol food — October 29, 2026

Owner-confirmed follow-up: an object's stored Vastra must not accumulate beyond
100. Trees expel received excess around themselves in root-like outward flows;
nearby plants can take it in, and Sols absorb excess Vastra as a food source.
Vastra visibly travels from its actual source to its actual recipient as conserved
quantities, like packets of data. A strand reaches point B before ending and
tapers more on longer journeys. Wider irregular wiggles remain distinct from
filament thickness.

Stored reserve, expelled root stock, in-flight energy and energy consumed by Sols
are separate accounts. Natural overflow/feeding does not originate ecological
overload or imply new experience levels. This approves feeding as an energy sink;
hunger/starvation rules, HP/XP rewards and final metabolic balance remain open.
The owner explicitly approved the associated development save-format change.
See [root overflow and Sol feeding](../vastra-integration.md#root-overflow-and-sol-feeding--october-29-2026)
for the implemented conservation model and provisional tuning.

### Vegetation and Vessel response — October 29, 2026

Owner direction: grass emanates Vastra from the earth as the local start of flow;
trees stockpile and release it; Vessels are usually swarm-like and serve as the
environment's immune response. The owner authorized further design refinement,
including visuals and Observe. This records design, not runtime implementation.

Separate growth form, circulation role, class and species. Working specialist
classes are Warden (protection), Mender (repair) and Regulator (flow and signal
moderation). Use one primary class per specialist species; ordinary vegetation
may be unclassed. Classes do not determine affinity. Classed trees still stockpile.
Preserve reserve cap 100, outward root overflow, Sol feeding, energy accounting
and unbiased tree recipient selection. Earth emanation leaves ultimate origin open.

Transfers may carry expiring ecological information alongside energy. Information
does not supply energy or establish consciousness. Vessels respond to encountered
conditions; excessive sustained defensive activity can originate overload and
provide a natural storm pathway. This explicitly extends section 15's overload
sources. Ordinary swarming, feeding, root overflow, concentration and weather do
not independently originate overload. Existing contiguous 3x3 eligibility,
conditions, chance and protected access remain; other storm origins remain too.
A storm does not guarantee cleansing or ecological benefit.

Responses require finite recruitment, paid actions, reassessment, expiring alarms
and a recovery period. Healthy places remain stable without all three classes.
Lifecycle, individual identity, splitting/merging and player handling remain open.
Earlier cue-only Vessel scope is superseded to this extent, not implemented.

Motion, grouping, plant activity and appropriate sound distinguish ordinary,
response, escalation and recovery states. Large/bright swarms alone are not danger.
Preserve affinity color; readability cannot depend on color or sound alone.
Observe distinguishes visible action, learned function and inference. Details
retains available exact local readings; neither reveals unseen causes or storm
certainty. Actual local danger needs a direct readable warning plus ambient cues.
Menus and rendering consume authoritative state; they cannot create events.

See [the refined concept](../living-world-concept-report.md#14-vegetation-signals-and-vessel-response)
and [delivery sequence](../world-exploration-roadmap.md#vegetation-and-vessel-response-follow-up).
Quantitative tuning, species and art acceptance remain open.

## Owner-approved relic direction — October 30, 2026

Relic structures use a shared procedural system and react to Vastra. They can
take in Vastra and produce an output according to the individual relic's authored
purpose. Keep a consistent Vastra node and input/output connection contract across
visual styles. Vastra runs through veins mapped along the relic's crevices.

Owner refinement: these crevices are angled indents in the relic's stone rather
than separate attached objects. Favor an ancient, weathered appearance over a
technological one. The consistent node is a functional connection contract; it
does not require visible machinery, metal frames, collars or technical labels.

Owner follow-up: use ominous black stone and hard 90-degree etch-outs, with
perpendicular sides and flat cut floors. Expand the range and variation of missing
stonework layers. These are visual/authoring directions, not new destruction,
repair, danger or affinity rules. Retain the selected Rock051 surface maps beneath
the black-stone treatment and keep Vastra light restrained inside the cuts.

The owner's four supplied images guide possible silhouettes: broken stone rings,
tapered spire groups, layered courtyards and compact shrine-like ruins. These
references establish no particular builders, religion, portal, levitation or
universal green affinity. Their underlying commercial assets are not adopted.

The Development Lab currently explores original procedural geometry, authored
stone maps, recessed node carvings and finite input/output examples. Clue reveal,
energy relay and layout reveal are provisional lab-purpose examples; costs,
production intake sources, persistence and ecological consequences need authored
integration. Preserve concentration/overload independence, capped stored reserves,
conserved transfers, existing plant/Vastra owners and required access. See the
[relic plan](../relic-roadmap.md) for scope and delivery status.

### Owner-approved ordinary foliage and sparse specialists — October 30, 2026

Most ground vegetation should be ordinary/generic plants. Warden, Mender and
Regulator plants should be rarer in the actual ecology, rather than equally
represented everywhere. A biome or local area need not contain a complete mix.
The owner expects populations eventually to die out and arise through their
mechanics; birth/death/regrowth remains future work, not an implemented balancing
or automatic replenishment rule. New-expedition specialist rarity is provisionally
5% on average with geographic variation; this is tuning, not a finalized canon
number. Preserve established saved roles/reserves and the existing division of
emanator, reservoir and receiver/specialist responsibilities. Implementation and
compatibility evidence remain in `docs/procedural-plants.md`.

### Owner-approved official plant catalog — October 30, 2026

The owner designated the 45 pictured designs in
`artifacts/plant-catalog/SolHunter_Plant_Catalog.pdf` as official plants. This
approves their visual baselines: twenty ordinary foliage designs, twenty-four
biome/role designs and one existing saved library design. The page-indexed roster,
captured settings and source hashes are recorded in
`resources/plants/official_catalog.json`.

Official visual approval is separate from species variation boundaries, ecological
roles, specialist abilities, publication and population frequency. The four
unclassed Receiver designs are official visuals with live ecological assignment
still open; approval does not automatically grant a specialist class. The catalog's
suggested fitting/default settings remain reference suggestions. Existing sparse
specialist population policy and saved reserves remain unchanged. Initial species variation envelopes are implemented as bounded Maker presets;
their numeric limits remain art tuning. Remaining missing growth families still
require authoring.
