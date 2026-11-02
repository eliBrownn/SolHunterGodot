# Runtime territory population summaries

This slice adds a bounded read API over complete, explicitly published home
definitions and existing persistent Sol records. It does not generate wildlife,
choose habitats, activate births, simulate migration, or enable population-assisted
recovery. The live exploration currently has no population producer or Sol roster.

## Reference and Godot authority

Behavior was reconciled with SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`, specifically
`src/systems/world/population_summary.py`, `tests/test_population_summary.py`,
`docs/coordination/territory-population-summaries.md`, and
`docs/coordination/population-restoration-transactions.md`.
Godot generation remains authoritative; the earlier home generator is not imported.
Source restoration evidence explicitly leaves production assistance gated on
authored carrying capacities, a diminishing-return curve, and event-order integration.
None is invented here.

## Publication and querying

`ExpeditionState.remember_population_territory(cell, complete_homes)` accepts at
most 256 distinct original home IDs belonging to that fixed territory. Each home
must already be represented by an explicit registered individual, including an
owned original or a registered replacement. Generation-zero IDs name the stable
home; current generations remain separate individuals. Duplicate coordinates,
replacement IDs used as home definitions, cross-seed/territory IDs, malformed
records, and oversized publications reject before changing the cache.

The trusted future producer must publish the complete territory definitions before
any viewport clipping, not merely the currently visible or notable individuals.
There is no general way to infer completeness from a sparse registry. Registering
an individual or visiting a territory alone never declares a known population.
An explicit empty publication means known zero; a cache miss returns an empty
dictionary meaning unknown. Reading a miss never generates or registers anything.

`population_summary(cell, carrying_capacities, region_resolver)` returns detached
territory ID, home-slot count, current available count, current activity tick,
carrying capacity, and effective population. An unavailable wild occupant counts
as zero for that known home. Acquisition removes availability without refilling it;
party/storage moves do not create a copy. An explicitly registered wild replacement
counts independently of its owned predecessor. Reads never activate a replacement.
Pending birth/depletion timing and habitat/thinning authoring are still future work.

This Godot slice deliberately accepts only registered homes, unlike the source's
generator-backed definitions for ordinary uninstantiated wildlife. It is suitable
for the explicit authored/fixture population slice, not yet a complete distant
population authority. The existing 2,048-individual admission ceiling still applies;
a later ordinary-wildlife producer needs a lightweight home/occupancy authority
rather than persisting every transient creature to fill this cache.

Availability comes from derived identity indexes maintained on registration,
acquisition, and restore. These indexes point to the authoritative persistent
records and are never copied ownership/count snapshots. A query checks only its
at-most-256 published homes, not every individual or visible actor. No terrain,
population-generation, or collection-scan callback is invoked.

## Capacity, bounds, and invalidation

Optional carrying capacities are an explicit region registry of integers 0–256,
with at most 128 entries. A trusted read-only region resolver is required when
that registry is nonempty; it receives the territory origin, including proper
negative-coordinate floor semantics, rather than the queried tile. It must not
generate terrain or mutate the world. An unconfigured region has unknown capacity.

Available population may exceed carrying capacity. Effective population is the
minimum of the two when capacity is known, otherwise unknown; zero is distinct
from unknown. This clamp is a future assistance input, not a recovery formula or
spawn limit. No production capacities are installed.

The runtime cache defaults to 256 territories. `set_population_cache_limit`
accepts 1–1,024; changing the limit invalidates old definitions. Publications update
recency and evict only runtime home references. Reads do not change recency.
Eviction loses knowledge, never owned individuals, home identity, or saved progress.

`invalidate_population_territory` explicitly retires definitions. Future changes
to habitat availability, spawn rules, or home authoring must invalidate affected
territories before republishing. Terrain editing and a population generator are
not currently implemented, so no speculative invalidation subscriptions are added.
Terrain/new-seed/save replacement already creates a new persistent-state object,
which starts with an empty runtime cache.

## Persistence and evidence

No save schema changes. Domain version remains 3 and outer save format remains 2.
Publishing/querying/evicting summaries leaves save output unchanged. Restoring
rebuilds derived home/occupant indexes from validated individuals but discards
runtime territory definitions; later explicit publication may restore knowledge.
Runtime cache presence or absence never modifies baseline ecological recovery.

`tests/population_summary.gd` provides 53 checks covering unknown versus empty,
complete-cell reads, negative territories, ownership/replacement continuity,
authored capacity lookup and clamping, malformed publication/settings, cache
bounds/invalidation, dense 256-home reads, and actual scene save/load/new-seed
behavior. It runs in the shared `tools/validate.ps1` entry point.

Pinned Godot 4.7.2 import and all 6,112 headless assertions passed, including
both scene journeys. Existing GPU-only checks remain outside this count; no
rendering code is changed by this slice.

The next population work needs an actual authored home producer and bounded
observation age/refresh policy. Production assisted restoration remains gated on
capacity/curve content and receipt/effect ordering. This API is not proof of a
completed population simulation, live encounters, or D1/D2 acceptance.
