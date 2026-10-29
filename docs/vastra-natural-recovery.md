# Natural Vastra replenishment and recovery

October 28 update: [signed Vastra integration](vastra-integration.md) supersedes
the positive-only recovery description below. Both signs now relax toward zero;
negative values support bounded terrain-condition and wildlife-home recovery.
The earlier delivery evidence below is historical, not validation of this update.

The exploration activity clock now services a bounded, persistent queue of explicit
environment changes. Baseline ecological overload recovers without population
queries or player action. A separate concentration-balancing API accepts authored
regional profiles; production regional profiles have not yet been supplied.

## Reference and tuning

The contract follows SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`, specifically
`src/systems/world/vastra_recovery.py`, `vastra_simulation.py`,
`tests/test_vastra_recovery.py`, and
`docs/coordination/vastra-natural-recovery.md`, reconciled with the Bible's
independent concentration/overload and recoverability rules.

`resources/vastra_settings.tres` exposes the source development defaults:
one overload point per 120 activity ticks and at most 32 explicit cells serviced
per tick. At 0.75 active seconds per tick, this is 90 active seconds per point,
about 150 active minutes for a promptly serviced 100-point cell. These are
provisional values, not acceptance of the Bible's working in-game-day targets.
No day/night conversion or device-performance claim is introduced.

An interval may be 1–1,000,000 ticks, recovery points 0–100, and work limit
1–1,024 cells. Zero points disables healing; known interval debt remains for
possible later re-enabling. Changing tuning applies the current policy to existing
debt, following the source behavior. Invalid settings reject before mutation.

## Scheduling and ownership

`ExpeditionState` owns the queue, cursor, serviced-tick marker, and recovery epochs
alongside its existing sparse tile deltas. `VastraNatural` only prepares bounded
updates. The work loop touches at most the configured number of existing cells;
it neither scans the whole world nor generates terrain, wildlife, or new deltas.
All prepared changes commit before environment-change observers run.

Each damaged cell retains its last completed recovery interval. Whole elapsed
intervals are applied arithmetically in constant work while fractional intervals
survive. Relaxation never increases overload magnitude or changes concentration. Neutral cells
discard their epochs. Unknown legacy/manual damage age starts a full interval on
first processing, without invented retroactive healing.

Human events anchor new damage at the current activity tick. Further disturbances
and retries do not reset existing progress. Fully healed then newly damaged cells
start a new epoch. Human receipt history remains intact after natural recovery.

The queue rotates in stable order; render eviction/rebuild does not alter it.
Natural concentration balancing shares one configured budget per authored region
per tick, taking at most one point toward equilibrium per serviced cell. An
exhausted region leaves its next cell first for the following tick; recovery debt
is retained when this delays service. Unknown profiles do not block independent
overload recovery. A partial legacy delta without explicit concentration does not
receive a fabricated concentration default.

`advance_environment(policy, profile_resolver)` accepts a trusted, read-only
resolver for `{region, equilibrium, budget}`. It must not mutate the world and must
provide consistent profiles for a region. Neither chunk IDs nor habitat noise are
silently promoted into ecological regions. No resolver is installed in normal
play yet, so generated concentration remains unchanged unless explicitly modified.
This is equilibrium replenishment/balancing, not implemented spatial redistribution.

The live world connects one callback per persistent state to the existing activity
clock and disconnects it on replacement. Pause and deterministic smoke mode freeze
that clock as before. Long frame stalls retain the existing two-tick catch-up cap;
there is no offline simulation. Direct repeated service within one activity tick
is a no-op, including after save/load, preventing duplicate natural budget use.

## Save compatibility

Outer save format remains 2. Domain `world_state` version 3 adds `natural` with
the explicit queue order, cursor, last serviced tick, and sparse recovery epochs.
Queue order is saved explicitly so JSON dictionary sorting cannot restart service.
Domain versions 1 and 2 still load: existing deltas and human receipts remain,
queue order initializes from those saved deltas, and recovery ages remain unknown.

Validation rejects missing/duplicate/orphan queue entries, invalid cursors,
future timestamps, and epochs attached to absent or healthy cells before live
replacement or writing. JSON integer normalization preserves counters and epochs.
Loading changes no original file bytes; the existing next-save backup applies.
New expeditions reset their own scheduling state.

## Validation and remaining scope

`tests/vastra_natural.gd` covers concentration independence, partial intervals,
large elapsed debt, disabled/re-enabled healing, bounded regional work, malformed
profiles, fair saved continuation, legacy domains, human-event continuity,
live pause/callback replacement, render rebuild, file reload, and incoming/outgoing
corruption rollback. It runs in `tools/validate.ps1`.

Pinned Godot 4.7.2 import and all 6,059 headless assertions passed, including
93 natural Vastra checks and both scene journeys. Existing GPU-only visual checks
remain outside this count; this change does not modify rendering code.

Population-assisted recovery, carrying capacity, spatial equalization, production
regional profiles, and authored human interactions remain future work. Storms,
exposure, and a full D2 acceptance claim are outside this slice. The current game
does not produce damage through a player tool, so normal pristine expeditions
remain healthy; test fixtures exercise recovery without installing a production
disturbance mechanic.

The subsequent [population-summary slice](population-summaries.md) supplies a
bounded non-generating query contract. It does not enable assistance or use cache
presence to alter baseline recovery.
