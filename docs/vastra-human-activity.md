# Human Vastra activity foundation

Historical feature-slice record: controls, schema versions and validation below
refer to its original delivery. Current save admission uses format 4, generation
9 and world state 17; incompatible development saves require a new expedition.
See the [reformat evidence](reformat-roadmap.md#execution-and-evidence-index) and
[current controls/tuning](inspector-tuning.md) for the integrated project.

October 28 update: [signed Vastra integration](vastra-integration.md) permits Sol
combat abilities to create overload through the separate battle-result path.
This human-only command API now accepts signed environmental conditions and
receipts: disturbance can consume restorative conditions before becoming positive.
Earlier implementation counts below remain historical evidence.

This initial D2 slice adds an atomic domain API for authored human harvesting
and disturbance. It does not add a player tool, inventory rewards, production
regional budgets, replenishment, recovery, storms, or direct extraction from Sols.
Those remain separate implementation and content work.

## Reference and rules

The implementation reconciles Bible concentration/overload distinctions with
SolHunterSource commit `115f3e87acc1716c7113523567c01e1666681885`:
`src/systems/world/vastra_human_activity.py`, `vastra_simulation.py`,
`tests/test_vastra_human_activity.py`, and
`docs/coordination/vastra-human-activity.md`. These establish the existing command
contract, not finalized balance. Godot's seeded terrain remains authoritative;
the earlier regional ambient generator is not imported.

- Human producer kinds are player, NPC, and infrastructure. Natural, weather,
  and Sol producers cannot originate unnatural overload through this API.
- Ambient harvest removes concentration only when the full requested amount is
  available. All producers and cells in one stable authored region share a
  sustainable budget for the current saved activity tick.
- Sustainable harvest must add no overload. Excess requires an explicitly
  authored positive overload effect; missing consequences reject the whole event.
  There is no invented excess-to-overload formula.
- Disturbance adds authored overload without changing concentration. Overload
  saturates at 100 independently of concentration.
- Usage refreshes only when the activity clock advances, never on reads,
  rendering, retry, or reload. Unchanged concentration of 100 is not itself damage.

## Single authority and replay

`ExpeditionState.apply_human_activity(event, generated, region, budget)` prepares
and validates the candidate before installing both its tile delta and ledger.
Only then does it emit `environment_changed` and `human_activity_applied`.
Failure returns an empty dictionary and leaves tiles, usage, and sequence intact.
Success returns a detached concentration/overload/excess receipt with a replay flag.

Events identify a stable actor kind/ID and monotonically contiguous sequence,
starting at one. Retrying the latest identical event returns its original receipt
without needing current ambient conditions or applying anything again. Conflicting
payloads, gaps, and older sequences reject. Only the latest receipt per producer
is retained; older commands cannot become valid again.

This is a trusted single-player controller boundary. A future controller must bind
the actual actor, stable region, configured budget, and authored consequence. It
must not allocate a new actor ID on retry or choose a new region to evade usage.
No region assignment is inferred from render chunks or habitat noise. If an
interaction later grants items, its reward must coordinate atomically with the
receipt; these receipts grant no items or permission to construct hardware.

## Persistence and admission limits

Outer save format remains 2. Domain `world_state` version 2 adds `human_activity`
with the usage-window tick, regional spent counters, and event receipts. Domain
version 1 still loads with empty ledger history and unchanged existing deltas,
individuals, observations, and clock. Restoration normalizes JSON integer fields.
Malformed or future-window ledgers reject before live-world replacement or writing
over a valid save. New expeditions reset their own ledger. Loading leaves the
original file untouched; the normal next-save backup policy remains in effect.

At most 1,024 producers and 128 regional counters are retained. The existing
8,192-cell sparse-state cap also applies. Full capacities reject atomically
without evicting replay evidence. Counters use the exact JSON integer range,
matching Godot's persistent clock rather than Python's signed-64-bit ceiling.
These are engineering limits, not ecological balance or player collection rules.

## Verification and remaining work

`tests/human_vastra_activity.gd` supplies 80 checks covering shared budgets across
actors/cells, authored excess, concentration/overload independence, provenance,
invalid scalars, sequence/retry semantics, observer consistency, producer/region/tile
caps, detached reads, JSON/file round trips, domain-v1 compatibility, live scene
eviction/reload/new-seed behavior, and malformed incoming/outgoing rollback.
The suite runs through `tools/validate.ps1`.

Godot 4.7.2 import and all 5,966 headless assertions passed across the shared
suites, including both scene journeys. Existing GPU-only visual checks are
excluded from that count; this slice changes no rendering code.

The live scene already projects sparse Vastra changes through Examine. Normal
play does not produce human events yet: fixtures do not install production budgets
or impose costs on ordinary healing, movement, or terrain safety operations.
[Bounded natural replenishment and recovery](vastra-natural-recovery.md) now follow
this slice. Production human interactions still need authored content and
end-to-end acceptance. The subsequent domain version 3 retains these version-2
receipts while adding a saved natural schedule.
