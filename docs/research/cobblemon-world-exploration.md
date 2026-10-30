# Research report 01: Cobblemon and the exploration loop

Researched October 29, 2026 for the [world/exploration roadmap](../world-exploration-roadmap.md).
Scope: primary-source desk research, comparison and proposed experiments. No
Cobblemon installation, instrumented playtest or source-code audit was performed.
The findings do not measure retention or establish why every player enjoys it.

## Why it matters to SolHunter

The useful comparison is a creature adventure embedded in an explorable world.
SolHunter's early game needs reasons to wander before its campaign exists.
Cobblemon puts finding and spending time with creatures into a sandbox that already
supports self-directed play. My design inference is that the relationship between
place, creature and personal goal is more relevant than its Pokémon battle rules.

The official Cobblemon site describes exploration, capture, wild battles and move
progression, plus following companions, shoulder-riding for some small Pokémon,
sleeping/faint animations and team interfaces. Those are verified advertised
features, not evidence of a complete simulated ecosystem. See the
[official feature overview](https://cobblemon.com/en).

Minecraft supplies substantial motivation underneath that layer. Mojang describes
a sandbox with no fixed goal, exploration, construction, crafting and survival.
Consequently, we cannot assume that adding creatures to procedural terrain gives
SolHunter the same breadth of activity. That comparison follows from
[Minecraft's own introduction](https://www.minecraft.net/en-us/article/what-minecraft).

My inference: SolHunter needs its own small, repeatable answer to "what do I want
to do next?" Its existing observation, companions, tactical encounters, discovery
and persistent local outcomes are promising foundations. Copying Minecraft's
construction or survival systems is not necessary to test that answer.

## Findings and applications

| Evidence | Design interpretation | Proposed SolHunter application |
| --- | --- | --- |
| Cobblemon's official feature overview connects exploration, capture and team development | A personal creature goal can give travel direction | Let an observed Sol or habitat clue suggest the player's next excursion, using approved species information |
| The official authoring guide defines spawn entries with reusable location presets, grounded/submerged contexts and rarity buckets | Different kinds of places can promise different encounters | Develop habitat-specific encounter identity using SolHunter's own ecology/species rules; do not import buckets or numerical odds |
| The official overview includes companions in the world and creature animations | Presence outside battle can help creatures feel like inhabitants | Improve visible idle behavior and companion continuity before adding many species |
| The official guide separates species authoring from spawn definitions and supports custom content | Reusable definitions can make content expansion manageable | Extend typed Godot species/site resources and the existing ownership hierarchy |
| Minecraft offers construction, crafting and survival independently of Cobblemon | The host game carries part of the sandbox | Test whether SolHunter's exploration and interaction loop stands on its own before scaling it |

Spawn/authoring evidence comes from the
[official custom Pokémon guide](https://www.cobblemon.com/en/guides).
The table's applications are proposals and interpretation, not Cobblemon claims
or approved additions to SolHunter mechanics.

## What the comparison changes in the roadmap

First, judge terrain by what it makes the player notice and choose. A woodland
edge, wetland and dry rise should suggest distinct experiences; recoloring the
same random scatter is insufficient. This is a proposed design criterion, not a
claim that every Cobblemon biome delivers it.

Second, make common inhabitants interesting. A rare encounter can be a highlight,
but the usual walk needs readable behavior, useful observations and places worth
remembering. Avoid depending on extremely low odds or repeated spawn refreshes to
make a sparse landscape feel substantial.

Third, generated quests should strengthen a functioning exploration loop. The
research does not establish generated quests as a base Cobblemon feature. For
SolHunter, they are an owner-directed extension: use actual local participants,
places and conditions to create optional purposes and persistent consequences.
Do not generate disconnected errands merely to fill travel time.

Fourth, make knowledge an outcome. A player who learns where a Sol belongs or
recognizes its behavior has gained something even without finishing a mission.
The journal should distinguish an actual observation from an unverified rumor.
This interpretation fits the proposed First Age feeling: people discovering a
world whose history has not yet been fully told. It does not canonize test saves.

## First experiment

Use the current refuge/woodland/pond/dryland slice and existing species. Run a
loose exploration session without a main-story objective. First record the current
experience; then compare one small improvement under the same seed and settings.

Proposed treatment: improve one visible route cue toward a habitat, support one
observable behavior with already approved content, and make its existing journal
record useful for choosing a return trip. Validate the species/habitat relationship
first; do not invent a new time/weather spawn rule for the experiment.

Record what attracted attention, whether the player voluntarily detoured, what
they learned, whether they wanted to revisit, and why they chose to stop. Compare
another seed so a hand-composed example does not masquerade as general generation.
If nothing invites exploration, improve world composition before adding a quest
marker or expanding the roster. This is a playtest proposal, not a completed result.

## Limits and follow-up

Server rules, modpacks and add-ons must be distinguished from base Cobblemon.
Do not infer breeding, automation, economies, gyms or quest generation from an
unrelated server guide. No exact release pin, species count, spawn probability,
population persistence model or complete behavior simulation is asserted here.
Several guessed official wiki URLs were inaccessible through the browsing tool;
those pages are not used as evidence. A hands-on base-mod observation would be
needed before making stronger claims about moment-to-moment feel.

SolHunter's mechanics continue to come from its Bible, owner decisions and
SolHunterSource reconciliation. In particular, ecological change, affinity,
relationships, rewards and spawning persistence cannot be copied from this study.
The actionable lesson is to test whether places and creatures generate personal
goals; the report does not establish a recipe for guaranteed fun.
