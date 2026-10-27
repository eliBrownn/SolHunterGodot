# D1 persistent foundation

This is the initial D1 data foundation, not completed creature gameplay. The live
exploration scene records visited territory cells and advances its activity clock.
No production Sol roster, wild spawning, capture procedure, combat, trust gains,
or population simulation is introduced. D0 manual/device acceptance remains open.

## Authority and source evidence

Godot generation version 5 remains the terrain authority. Non-generation contracts
were checked against `eliBrownn/SolHunterSource` at commit
`115f3e87acc1716c7113523567c01e1666681885` on
`backup/pre-world-redesign-2026-10-24`, following [mechanics reference](mechanics-reference.md):

- `src/systems/world/sol_identity.py` and `territories.py`: canonical seed/home/species
  identity, replacement generations, and home territories independent of render visibility.
- `docs/coordination/territory-population-summaries.md`: unknown population differs
  from known empty; reads do not generate populations or copy their authority.
- `src/systems/tactics/relationships.py` and
  `docs/coordination/sol-relationship-evidence.md`: optional explicit relationship
  evidence, bounded ordered memories, and no inferred friendship from capture.
- `config/development.py`: 16-cell home territories, 0.75-second activity interval,
  and at most two catch-up steps per update. These are development settings, not lore.

## Ownership and continuity

`ExpeditionState` owns observed territories, individual records, the activity clock,
and sparse concentration/overload changes. Render chunks can be discarded and rebuilt
without deleting these records. Read APIs return detached values; explicit mutations
validate before committing and emit signals only when state changes.

Home territories use floor division, including negative coordinates. Their configurable
size is independent of the 16-cell rendering chunk size. Discovery records do not claim
completed biome regions or populations: population and carrying capacity remain unknown.

Original IDs are `seed:col:row:species`; replacement generations use
`sol2:seed:col:row:generation:species`. Acquisition and movement between sealed, party,
and storage locations retain the original ID and home. Duplicate IDs and multiple
active wild generations for the same home/species are rejected. These APIs establish storage
contracts; they do not decide capture eligibility, release, or cross-holder policy.

`SolSpeciesDefinition` validates species/lineage/class metadata and ordinary forms.
A lineage retains its primary class; affinity belongs to the individual. Tests use
fixture content only. Legendary manifestation is not added as a fourth ordinary form.

Absent relationship evidence stays unknown. Explicit evidence may record trust
(including zero) and up to 32 ordered, uniquely identified memories. Existing memories
cannot be silently removed. No acquisition grants trust, obedience, or fabricated history.

The clock pauses with the world, preserves its fractional remainder, and drops excess
whole-step backlog after the two-step catch-up cap. There is no offline simulation.
Sparse environment overlays keep concentration and overload distinct and leave seeded
terrain generation intact. Ecology rates and disturbance behavior remain future work.

## Save contract and limits

Save format 2 originally introduced version-1 `world_state`; the subsequent
[human activity slice](vastra-human-activity.md) adds domain version 2 while retaining
version-1 compatibility. The subsequent [natural recovery slice](vastra-natural-recovery.md)
adds domain version 3 with compatibility for both previous domain versions.
The subsequent [observation journal](sol-observation-journal.md) adds domain
version 4 while retaining compatibility with domains 1–3.
The later [local-reaction slice](local-sol-reactions.md) adds domain version 5
for current wild positions/actions while retaining domains 1–4.
The [first playable battle](first-playable-battle.md) adds domain version 6 for
explicit starter identity/profile, retained health, result receipts, defeated
wild IDs, and protection steps. Domains 1–5 retain their history without an
inferred starter; active battle snapshots cannot be saved.
Format-1 saves upgrade in memory with
empty persistent history; generation 1–4 terrain migration remains independent and can
run in the same load. Loading preserves original file bytes. The next explicit save
retains the previous file as `.bak`. Python save importing is not implemented.

Loading checks the entire candidate before replacing the live world. Unknown versions,
invalid identities, duplicate ownership, inconsistent species definitions, malformed
relationships, invalid deltas, and oversized files are rejected. JSON whole-number
values are normalized back to integer fields so repeated reloads preserve identity.

Technical admission limits are 4,096 observed territories, 2,048 individual records,
8,192 changed cells, and a 16 MiB save file. These are engineering limits, not world or
collection rules. At capacity, new records fail without eviction or silent truncation.
The activity tick stays within JSON's exact integer range. Production scaling and
population persistence still require further D1 work.

## Validation and inspection

`tests/persistent_foundation.gd` exercises 79 assertions covering negative territories,
chunk-independent state, canonical IDs, ownership continuity, immutable reads, bounded
histories, sparse overlays, clock behavior, repeated scene reloads, malformed-save
rollback, file limits, legacy format migration, and combined terrain/save migration.
It is included in `tools/validate.ps1` alongside the existing suites.

F3 displays the activity tick, observed territory count, and recorded Sol count.
Normal play currently reports no Sol records; test fixtures are never spawned into
player expeditions. Live content and encounter integration are subsequent work.
