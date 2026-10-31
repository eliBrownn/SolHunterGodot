# SolHunter — Complete Worldbuilding Bible & Research Compendium

Consolidated research edition · October 23, 2026

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

Ordinary natural processes and Sol behavior do not push Vastra beyond this point. Humanity, however, can disrupt equilibrium through its activities and its effects on nature.

This distinction is central to the setting.

### 9. The appearance of Vastra

Pure, affinity-neutral Vastra has a full-spectrum white-light identity, but normally appears transparent because of how Vastra interacts with light.

Affinity-aligned Vastra exhibits colors associated with different parts of the visible spectrum.

Vastra currents can be visibly perceived in the environment under normal conditions.

This provides a basis for environmental art direction, affinity effects, magical phenomena, and visual storytelling.

The exact color assigned to each affinity has not been fully established.

### 10. Concentration and overload

Each relevant environmental tile tracks two separate properties.

| Measurement          | Scale | Meaning                                            |
| -------------------- | ----- | -------------------------------------------------- |
| Vastra concentration | 0–100 | How much ambient energy is available locally       |
| Ecological overload  | 0–100 | How severely the environment has been destabilized |

These measurements are independent.

A naturally Vastra-rich region can be perfectly healthy. A region with relatively little ambient energy can still be severely damaged by human interference.

High concentration does not automatically mean ecological danger.

### 11. Natural equilibrium and replenishment

Each region has a natural replenishment budget.

Vastra naturally balances and disperses, but the precise replenishment and equalization rates vary according to the region and are configurable.

Nature and Sols maintain or restore equilibrium rather than creating unnatural excess.

Natural disasters may redistribute Vastra, but do not independently create ecological overload.

This creates a clear distinction between natural environmental change and human-caused destabilization.

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

Overload arises from human-caused disruption, including unsustainable ambient harvesting and other harmful effects on the environment.

Overload spreads gradually to adjacent tiles.

Natural ecological recovery reduces overload over time. Sol populations contribute to that process, and player or NPC intervention can accelerate it.

Earlier planning targeted ordinary recovery over approximately 1–3 in-game days. This remains a working tuning target rather than an immutable universal rule.

### 16. Sol-driven ecological recovery

Most Sols contribute to environmental restoration through their ordinary behavior.

The rate of passive recovery is related to the local Sol population, with diminishing returns based on ecological carrying capacity.

This means increasing a healthy local population can improve restoration, but overcrowding cannot produce unlimited healing.

Restoration remains possible without direct player intervention.

### 17. Storm generation

Accumulated-overload environmental Vastra storms require a contiguous 3×3 group of storm-eligible overloaded tiles. Battle-storm arenas use the separate formation rule in the owner-approved October 31, 2026 section below.

A tile becomes eligible at a configurable overload threshold no greater than 100.

A qualifying group makes a storm possible; it does not guarantee one. Storm formation also depends on probability and environmental conditions.

### Storm eligibility footprint

Nine contiguous eligible tiles

Eligibility permits a probabilistic storm check; it does not automatically trigger a storm.

Large Sols can affect a 3×3 footprint and redistribute existing human-caused overload, potentially contributing to storm formation.

Ordinary Sol activity does not independently generate unnatural overload.

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

### 21. Early forms and physical development

The earliest evolutionary forms of Sols are often wisplike in appearance.

However, they are still physical and tangible beings with biological needs.

As they evolve, many become increasingly substantial and physically defined.

Evolution is not simply a change in combat statistics. It can also alter the creature's appearance, physical abilities, and relationship with its environment.

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

The ordinary encounter baseline is one allied Sol against one opposing Sol. The owner-approved October 31, 2026 section below establishes readiness-based commander combat, live execution, automatic tactical pauses and possible 2v2 expansion.

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

The exact treatment of the player's refusal to release the starter for legendary ascension remains a major narrative dependency.

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

The exact story resolution when the player refuses remains unresolved.

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
- Exact affinity-color assignments.
- Vastra concentration-to-damage scaling formula.
- Storm thresholds, probabilities, severity, and cooldowns.
- Exact ecological carrying-capacity and restoration formulas.
- Detailed human exposure symptoms and protection thresholds.
- Precise propagation and affinity-inheritance weights.
- Classification of exceptional Sol deaths.
- Exact capture and transfer formulas.
- Final move, ability, IV/EV, and progression formulas.
- Legendary memory inheritance and bond requirements.
- Resolution of the main story when the starter's request is refused.
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

## Owner-approved battle storms and commander combat — October 31, 2026

Status: owner-approved design direction, not implemented mechanics or accepted
balance. This section supersedes earlier storm-origin restrictions for battle
storms and establishes readiness-based commander combat as the target. Existing
turn/AP combat and the disposable real-time trial remain implementation baselines.
Numerical timing, sizing and protection values remain unresolved.

### Commander timing in the actual world

An individual readiness timeline governs combat, with live execution between
automatic tactical pauses. When an allied Sol needs an order, combat time stops
for positioning and move selection with route, cost and timing previews. Committed
orders execute through movement, preparation, impact and recovery. Success must
not depend on rapid input or animation playback speed. Ordinary encounters are
1v1, with possible 2v2 expansion using individual readiness. Exact movement/order
budgets, Speed conversion, interruptions, simultaneous-event ordering and the
future role of AP remain unresolved.

Combat uses the actual terrain, obstacles, elevation and Vastra at the encounter
location. The logical grid supports routes, footprints and previews; creatures
move smoothly in presentation. Godot world generation remains authoritative.
Combat owns participant state and combat-relevant local tiles; background systems
must not independently rewrite those same values. Completion reconciles changes
once with the continuing world.

### Storm formation, arena extent and disturbance

Battles are intended to be a principal source of encountered Vastra storms.
Sols committing to confrontation draw local currents into a turbulent circulation
that establishes the arena before the first damaging move. Formation need not
start at maximum ecological overload. Aggressive Vastra-powered abilities add
overload on their actually affected tiles and can intensify disturbance. Purely
non-Vastra physical attacks remain distinct; ordinary noncombat Sol behavior does
not thereby originate overload. Concentration remains independent of overload.

The storm gathers around existing geography and thematically binds a stable set
of battlefield tiles without moving or literally freezing the landscape. Larger
Sols invoke larger arenas. Establish the footprint once at formation, using the
largest participant and sufficient reachable fighting space for all participants.
Possible 2v2 encounters must fit without simply doubling a circular radius.
Perimeters follow traversable geography; ordinary movement does not resize them.
Exact sizing remains tuning.

Arena extent is separate from severity and lasting damage. Small encounters may
produce a low shimmering disturbance; major confrontations may produce violent
currents. Larger arenas do not automatically damage every enclosed tile. The
confrontation sustains the boundary, while overload expresses disturbance.
Restorative moves can calm conditions without deleting the arena mid-battle.

Battle storms have their own formation rule. The earlier probabilistic contiguous
3x3 overloaded-tile requirement continues to govern accumulated-overload
**environmental storms**, not battle-arena admission. Battles may leave conditions
supporting persistent environmental storms; not every storm must come from combat.
Authored narrative storms, including the opening, and other established storm
sources remain possible. This does not change ordinary weather or require every
duel to devastate a habitat.

### Hunter protection, gear and defeat

The hunter commands from a sheltered position at the storm margin rather than
acting as a second fighting unit. Mask and clothing manage baseline exposure;
the companion stabilizes tolerable flow around the hunter. Combat protection is
automatic, not a repeatedly refreshed shield or manually positioned bubble. This
explains both equipment and the hunter's separation from direct creature attacks.

Gear capabilities enable more hazardous encounters and regions. Observation
should communicate likely storm extent, severity and inadequate protection before
commitment, with warnings and opportunities to withdraw. Gear need not multiply
Sol damage. Preserve the prohibition on mandatory oxygen, filter replacement or
constant equipment maintenance. Protection tiers, thresholds and exact admission
rules remain unresolved.

Shelter beside a companion during its own battle differs from traversal of an
established environmental affinity storm. Ordinary battles remain possible between
different individual affinities. This extends rather than removes the existing
matching-affinity rule for ordinary storm traversal; it grants no universal storm
immunity or unrestricted passage. Quantum and pure-storm exceptions remain open.

When the last available fighting Sol is exhausted and protection can no longer
be sustained, protection breaks down and the hunter succumbs to the storm, losing
consciousness. Ordinary Sol defeat remains exhaustion, not death; blackout does
not establish permadeath. In possible 2v2 encounters, one exhausted ally does not
cause a wipe while another sustains protection. Reserve replacement eligibility
and timing must be defined before declaring all protection lost.

Recovery requires an authored rescue, extraction or other explanation; blackout
alone does not explain returning to refuge. Recovery mechanism, checkpoints,
penalties, item loss and costs remain unresolved.

### Tactical pauses, withdrawal and lasting aftermath

The storm supports a bounded battlefield, not literal time-stopping lore. Planning
holds participants, attacks and combat storm hazards at the same tactical instant.
Reading commands cannot accumulate exposure, advance attacks or escalate the
storm. The surrounding world and ambient presentation continue; the explicit
pause screen retains its separate behavior. Withdrawal is an explicit action
through the perimeter rather than an accidental click beyond it. Exact escape
and pursuit rules remain open.

When confrontation ends, sustaining circulation disperses but consequences
remain. Aggressive Vastra abilities leave overload on reached tiles. Healing
reduces overload independently of HP restored and can push it negative into
restorative conditions. Successful move activity determines lasting tile affinity
under the existing move-affinity/activity rules. Temporary conditions recover
without erasing that imprint. Dispersal does not reset terrain, cancel lasting
effects or replay completion transactions.

Restrained fights can leave modest disturbance; repeated destructive battles can
leave a lingering hazard. Peaceful relationships avoid creating a battle storm.
Exact dissipation, persistent-hazard escalation and recovery rates remain open.
Formation, escalation, dispersal and aftermath belong to one connected world
system rather than disposable arena effects.

## Owner-approved foliage, overflow and Vastra instability — October 31, 2026

Status: approved design and visual direction, not runtime implementation. This
refines the overload presentation language and extends Sol-core presentation.
Stored energy, ambient concentration, ecological overload and signal overload
remain distinct; shared visuals do not make them interchangeable quantities.

### Plant reserve, leaf color and posture

Plants and trees express their individual stored Vastra through leaf saturation
and posture. Low reserves produce softer, pastel foliage and lower leaf posture;
higher reserves enrich saturation and lift/perk up the leaves. This describes
foliage posture, not whole-plant levitation or experience levels. Preserve each
species' authored palette and anatomy rather than turning all charged plants
green. Reserve is not a direct reading of ambient concentration, injury or habitat
damage; low reserve alone does not establish illness or death. Exact response
curves, movement limits and saturation ranges remain art tuning.

### Outward overflow and tile capacity

Use **overflow** for energy beyond storage capacity, distinct from ecological
**overload**. Plants and trees release incoming excess into outward flows around
themselves, extending the existing root-like tree circulation. Emission in all
directions describes distribution around the source, not duplicated energy.
Outgoing strands divide the available surplus; nearby recipients can receive it
through actual conserved transfers. Natural overflow alone does not originate
ecological overload.

Stored object reserves remain capped at 100. The owner's tile direction is to
release incoming excess beyond a capacity of 100, but the tile's energy account
must be specified before implementation: whether this is a stored tile reserve
or an extension of ambient concentration remains unresolved. Do not interpret
signed ecological overload above 100 as surplus fuel, silently introduce a new
tile reserve, or clip/delete energy instead of accounting for outward transfer.

### Distortion identifies unstable Vastra activity

Use the Vessel light-warping/chromatic-aberration effect as the common thematic
language for overload and instability. Plants and tiles do not produce distortion
auras merely because they are full, overflowing or have a high ecological overload
reading. Distortion belongs to unstable Vastra activity and overloaded carried
signals, including affected strands, rather than the plant or terrain surface
itself. Ordinary energy circulation remains visually distinct from instability;
richness, brightness or fullness alone does not establish danger.

Vastra transfers can carry important ecological information alongside energy.
This develops the existing expiring-signal direction; information supplies no
energy, remote omniscience or proof of Vastra consciousness. Signal overload is
a separate concept whose causes, thresholds and consequences require definition.
Conflicting messages, excessive intensity and repeated alarms are possibilities,
not settled triggers. Preserve real source/recipient accounting and existing
signal identity, expiry and replay safeguards.

### Sol visual cores, emotion and possible detonation

Every Sol has the established wispy, ball-shaped visual core, also called its
Sol Orb. It remains part of a species-specific creature design, with placement
independent of anatomical head and individual affinity independent of species.
The description of Sols as large Vessels is a visual analogy, not a declaration
that the two are biologically identical.

During anger, aggression and battle, the core expresses increasing instability
through the same Vessel warping/chromatic-aberration language. Separate ordinary
focused battle energy from dangerous escalation: stronger, erratic distortion
communicates increasing anger or loss of regulation, rather than implying that
every battle-ready Sol is about to explode. This extends the earlier visual-only
core canon with emotional/behavioral presentation; it does not establish a core
energy reserve, brain location or a new combat resource.

Anger-driven instability is a proposed root of possible overload detonation,
not an automatic explosion rule. Detonation trigger, energy source, thresholds,
survivability and environmental consequences remain unresolved. Distinguish any
future living-Sol detonation from the existing unjust-death energy release.
Ordinary combat defeat remains exhaustion; anger alone does not establish death,
permadeath or a new failure penalty.

### Owner-approved escalation chain — October 31, 2026

Disruption -> escalating signals -> Vessel/Sol response -> aggressive energy
release -> ecological overload -> storm risk.

This is the approved causal design for response-driven escalation, not a guarantee
that every signal or response reaches a storm. Signals communicate conditions;
they do not create energy. Anger alone does not thereby add ecological overload:
the aggressive release is a distinct step. Its exact admission rules remain open.

Ordinary fullness follows a separate safe path:
full reserve -> outward overflow -> redistribution.

A healthy, energy-rich location is not inherently distressed. Normal overflow is
not itself an overload source. Distortion indicates instability rather than mere
fullness. Established direct overload sources remain valid; this chain is not a
mandatory prerequisite for every aggressive ability or human-caused disturbance.
Battle-arena formation retains its separate confrontation rule and can precede
high ecological overload; this chain describes escalation and environmental storm
risk, not a replacement admission rule for every battle.

Signal-overload triggers, escalation thresholds, stabilization/interruption
mechanisms and detonation consequences remain unresolved. They require authored
rules before runtime implementation.
