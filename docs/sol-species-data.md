# Sol species data integration

October 28, 2026 — step two of the [Sol Bible production plan](reference/sol_bible.md#production-integration-plan).
Status: pilot data connected; final validation evidence is recorded in the Bible.
Names and numerical balance remain editable pilot tuning. Step two introduced
data integration; [step three](sol-creature-models.md) now supplies the creature
blockouts. Procedural ground travel and [wild flight/swimming](sol-flight-and-swimming.md)
are now connected. Later evolution forms remain pending.

## Normal-game rollout

Latest owner direction, October 28: one playable first form per current class.
The shared catalog and normal-world preset now contain eighteen representatives.
Twelve existing Bible candidates fill the remaining classes using distinct small
models, keys 0007–0018, ground-only traversal, existing move/passive rules and
authored companion gestures. Eldritch has its own identity with an unassigned
zero-effect passive; legacy Stonebound remains separate. See the
[class-coverage review](sol-class-coverage.md) and Bible index for current content.
The earlier six-species rollout below records that slice's history.

Owner follow-up, October 28: apply Ashquill, Rattlehorn and Rimefold to the game.
The shared catalog now has six records. The added three use their selected B
body plans with small/cute first-form proportions, stable IDs 0004–0006 and ground
movement. Normal trail placements are x=22/40/56, with Water/Earth/Air on those
individuals respectively. Existing species, starter choices and encounters remain.
The original three-species pilot scenes stay focused on their original slice;
normal F5 play includes all six. See the [applied anatomy review](sol-creature-anatomy-review.md#applied-to-the-normal-game)
and the three linked species sheets for provisional profiles, move pools and
family-count limitations. No world generation, capture or progression rule changes.

Owner direction, October 28, 2026: apply the implemented species/behavior work to
the actual game. `project.godot` still starts `scenes/world_3d.tscn`; that scene now
explicitly selects `resources/sol_world_sightings.tres` and the enabled owned
companion settings. Normal wilderness, species profiles, wandering and reactions
stay enabled. The new sighting preset retains the existing movement/rest/response
defaults and adds the three delivered catalog species; it does not use the
pilot presets that disable wilderness.

Crown-Ear is authored near trail x=12 with air affinity; Bellroot near x=34 with
fire affinity. Reedback has water affinity and a deterministic legal bank search
near trail x=18. These are individual placements, not species-affinity rules.
On the default seed 2601026 their homes are (12, 6), (34, 7), and (21, 31)
respectively; seed 17 resolves Reedback to (22, 27). Terrain remains authoritative:
no water or land is rewritten, and a seed with no supported bank omits that
placement. Editing the preset is ordinary Inspector authoring; existing admitted
individuals keep their saved identities and affinities.

The original Seedmote/Bramblepup individuals, ambient prototype wilderness,
starter choices and opening-story decisions remain intact. The added species use
their connected ecology profiles, own models and admitted flight/swimming policy.
They can use the existing encounter/capture/party workflow. **Sols > Set active**
then selects that actual owned individual for the
[companion system](owned-companion.md#owned-flight-and-swimming-integration),
including legal flight/swimming, rest and authored idle moments.

Current-format pre-rollout saves receive the new explicit placements on load
through the existing admission path. Existing records are not replaced; view
rebuilds do not duplicate individuals. Incompatible saves still follow the
project's normal new-expedition policy. The original
`resources/sighting_settings.tres` remains the legacy comparison/fixture preset;
edit **SolHunter3D > Expedition Tuning > Sighting Settings** or the new world
preset to tune normal F5 play. Pilot scenes remain separate controlled scenarios.

`tests/sol_game_rollout.gd` loads the actual configured main entry with no AI,
wilderness or ecology switch disabled. It verifies the default seed and seed 17,
legal identities/models/banks, profile/traversal resolution, normal save/load,
pre-rollout save admission and preserved original starter choices. Its initial
69 checks passed; evidence includes `artifacts/sol_game_rollout_test.log` and
`artifacts/sol_game_rollout_homes.json`. This is content/configuration and save
integration evidence, not owner experience or device acceptance.

## Connected authoring structure

The shared [catalog](../resources/sol_species/catalog.tres) contains eighteen
`SolSpeciesRecord` resources:

| Species | Stable runtime ID | Class display / retained ID | Resource |
| --- | --- | --- | --- |
| Crown-Ear | `sol_species_0001` | Beast / `beast` | [Crown-Ear](../resources/sol_species/crown_ear.tres) |
| Reedback | `sol_species_0002` | Abyssal / `tideborn` | [Reedback](../resources/sol_species/reedback.tres) |
| Bellroot | `sol_species_0003` | Bloom / `verdant` | [Bellroot](../resources/sol_species/bellroot.tres) |
| Ashquill | `sol_species_0004` | CinderKin / `cinderkin` | [Ashquill](../resources/sol_species/ashquill.tres) |
| Rattlehorn | `sol_species_0005` | Stormforged / `stormforged` | [Rattlehorn](../resources/sol_species/rattlehorn.tres) |
| Rimefold | `sol_species_0006` | Frostbound / `frostbound` | [Rimefold](../resources/sol_species/rimefold.tres) |
| New class-coverage batch | `sol_species_0007`–`sol_species_0018` | Remaining twelve current classes | [Canonical sheets and records](reference/sol_bible.md#authored-species-index) |

Each record connects taxonomy, the six reference-level stats, lineage capacity,
explicit eligible/initial moves, species-default ecology, and a presentation scene.
There is no species affinity property. Battle profiles require the actual
individual affinity as an argument; wild admission snapshots it before combat use.

`BattleSettings` and `MoveLibrary` reference the same catalog resource. Existing
prototype profiles/pools remain fallbacks for their original IDs; duplicate
definitions across a legacy pool/profile and the catalog are rejected. The catalog
is wired in authored `.tres` settings rather than statically preloaded by their
scripts. Standalone new settings resources can remain empty/legacy-compatible.

Sighting settings select the same file through **Species Catalog Path**. The
reference is resolved lazily and does not embed the catalog in duplicated movement
tuning. Concrete catalog/sighting scripts are checked before use. This boundary
uses validated Resource values rather than mutually dependent typed exports;
the original declarations reproducibly retained scenery resources at shutdown in
the geometry suite. No error filter or geometry test was weakened to resolve it.

All presentation contexts use `SolSpeciesView`: wild exploration, deployed combat
units, and selected companion previews. Pilot records now select the three
[articulated creature scenes](sol-creature-models.md), whose roots extend the
existing `SolOrb` contract. Missing/incompatible scene roots reject validation.
Existing species without a catalog entry use provisional creature models, preserving
their identity and individual affinity. The placeholder scene is also a creature.
See the [creature-design handoff](sol-creature-design-handoff.md) for replacement work.

## Reviewable pilot scene

Open [sol_species_pilot.tscn](../scenes/sol_species_pilot.tscn) and press F6.
It uses the existing full-3D world plus
[three explicit catalog sightings](../resources/sol_pilot_sightings.tres):
Crown-Ear at trail x=12, Reedback at x=18, Bellroot at x=34. Their authored
individual affinities are Air, Water, and Fire respectively; Bellroot remains
Bloom despite Fire affinity. These are fixtures, not species affinity weights.

The original three sightings and prototype starter chooser remain. Wilderness
admission is disabled in this scenario to make the six authored sightings easy to
review. The ordinary expedition now includes the trio through
`resources/sol_world_sightings.tres`, with Reedback placed beside generated water.
In this isolated trail scenario, all pilot homes
still need valid dry terrain; nothing changes the generator or fabricates water/
air navigation. Right-click Observe/Engage uses existing interaction authority;
battle, capture, party/storage, and save/load reuse existing domain commands.

This is a data test scene, not an implementation of the narrative storm rescue.
All gameplay presentations now use creature bodies; no identity falls back to an orb.

## Validation and admission contracts

- Reject duplicate IDs/names, conflicting primary classes or ordinary stages in
  one lineage, malformed reference stats/capacity, mismatched ecology, invalid
  starting pools, unknown moves, and missing/incompatible presentation resources.
- Reject missing/wrong catalog resources, malformed sighting resources, duplicate
  explicit homes, and collisions with the established authored trail homes. A
  colliding layout does not partially register new individuals.
- Preserve saved individual class, lineage, affinity, natural rolls, potency,
  reference stats, ownership, and movebooks. Live placement edits do not overwrite
  those fields or redirect behavior filters to a newly authored affinity.
- New stat/pool/default definitions apply at admission. Already admitted traits
  and movebooks are not regenerated from edited resources. Ecology tuning remains
  live through existing configuration invalidation; explicit missing named
  overrides still retain their authored fallback behavior.
- Approved class names are display metadata. Legacy `stonebound` is explicitly
  labeled legacy and is not aliased to Eldritch; the Eldritch class still needs its
  own mechanics and runtime identity work.
- Finite engineering ceilings remain: at most 512 catalog/combined move-pool
  entries, 512 explicit catalog sightings, 32 eligible/remembered pool entries per
  species, and four equipped moves. The earlier 64-species pool ceiling is lifted
  coherently for the 151-entry target, not removed without a bound.

## Editing and save timing

Edit the shared `.tres` record rather than copying its data into combat code,
move dictionaries, or encounter scripts. Keep the configured catalog references
aligned. Taxonomy/placement changes should be tested in a new expedition; they do
not relocate or rewrite saved identities. Rebuild views to see placement/label/
scene changes. Existing saved profile display names remain their admitted values.
Stat/pool changes apply to new admissions; growth/individual potential retain their
saved policies. No save/schema version changes or legacy migration system are
introduced by adding these species through current contracts.

Godot shares external resource references when using `duplicate(true)`. For an
isolated authoring/test scenario, explicitly copy editable records and ecology
profiles, or use the engine's appropriate deep-copy policy. Do not accidentally
edit the production catalog through a supposedly isolated settings copy. See
[Godot Resource duplication](https://docs.godotengine.org/en/4.6/classes/class_resource.html#class-resource-method-duplicate-deep).

## Evidence

`tests/sol_species_catalog.gd` is included in `tools/validate.ps1`. It exercises
reference rejection, a catalog beyond 64 entries, actual scene admission, battle,
capture, ownership, all three presentation paths, authored edits after admission,
and actual save/new/load. Its optional rendered `--capture` path produces a
dossier image for each acquired pilot under ignored `artifacts/sol_species_integration/`.
Full results and limitations are recorded in the Bible after validation.

Reference use: SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`,
`src/systems/world/sol_catalog.py`, plus the mechanics evidence from step one.
Its authored-reference validation informed the Godot-native structure; no private
catalog was copied. Older affinity lists, stat numbers, ability slots, and generation
logic were not imported. Godot remains world-generation authority.
