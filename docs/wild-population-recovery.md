# Repeatable authored wildlife homes

Wild victory now leaves a home depleted for a saved active-time delay, after
which a new individual may settle there. A successor has the same authored
species/home but a new canonical generation ID. The exhausted original remains
in history; this is not resurrection, a copy of an owned Sol, or a death rule.
Retreat and player exhaustion do not deplete the opponent's home.

## Play and authoring

The source-derived default is 2,400 active ticks: 30 minutes of exploration at
the existing 0.75-second activity tick. Pause, encounters, time while the game is
closed, render rebuilds, and load queries do not age or complete the wait. A large
elapsed delta still follows the existing bounded activity-clock contract.

Use the root's Wild Recovery Settings, or
`resources/wild_recovery_settings.tres`, to tune Interval Ticks (0–1,000,000) and
Local Radius (4–32 cells, default 14). Short test intervals are useful when
judging the loop. Zero disables new waits; already saved commitments retain
their deadlines and may still complete. Delay edits apply to newly scheduled
waits after the next active policy refresh; restart after Inspector edits for
consistent authoring. Existing saved deadlines never reroll.

Due homes activate only within the local radius, on legal open terrain, away
from current wild Sols, the player and the player's reserved movement target.
Recovering terrain barriers postpone activation. There is at most one active
wild occupant per home; long dormant time never accumulates a batch of births.
The new individual is admitted only on an explicit active simulation tick.

E inspection over a depleted authored home shows the exploration-time wait, or
that clear ground is needed. A nearby arrival produces a brief message. The
successor can be approached, observed and encountered under its own identity;
a guarding successor needs its own displayed warning and later contact step.
Stale panels cannot silently target the new occupant.

## Persistence and identity

Domain 8 adds `wild_population`, keyed by generation-zero home ID. Each row
stores the current/next generation, `ready_at` deadline, and committed active
flag. Generation-zero IDs remain unchanged; successors use existing `sol2:` IDs.
Admission atomically installs the new individual, fresh authored movebook,
active home row and derived home index. Loading reconstructs availability from
the retained individuals and depletion records; it never refills a home.

Victory schedules the next generation in the authoritative battle result
commit. Successful `acquire` also schedules depletion for future collection
flows; this slice adds no capture UI or new capture rule. Old owned records,
relationships, learned/equipped moves, Field Notes, and defeated individuals are
not rewritten. Saved battle imprints and condition recovery remain independent.
Runtime population caches continue to count the one current occupant, not the
retained history; census-definition caches themselves remain unsaved.

Domains 1–7 migrate without guessed depletion/capture timestamps. On the first
explicit local active revisit, an unavailable historical home starts a full
wait. Existing available successors keep their IDs. The next generation is
chosen after the latest retained individual. Zero-delay mode does not start
historical waits. Re-enabling starts a full wait rather than backdating it.

This remains a three-home authored prototype. Successors use their home's
authored species, affinity and provisional combat profiles; production affinity
inheritance/rarity, IV rolls, reproduction and migration are not introduced.
Generation here means successor identity, not an evolution stage. Existing
individual/admission and integer ceilings remain safety limits; at capacity a
pending admission waits rather than deleting history or duplicating an ID.

## Evidence and verification

Read-only SolHunterSource reference at commit
`115f3e87acc1716c7113523567c01e1666681885`:

- `src/systems/world/population_recovery.py`: delayed home replacement, local
  vacant activation, no retreat/defeat depletion, legacy full-wait handling,
  and preservation of saved commitments when delay is disabled.
- `config/development.py`: `WILD_RECOVERY_INTERVAL_TICKS = 2400`.
- `src/systems/world/sol_identity.py`: unchanged generation-zero IDs and distinct
  successor IDs.
- `tests/test_population_recovery.py`: identity, save/load, occupancy, warning,
  malformed-ledger and owned-individual preservation evidence.

Godot retains its generation, terrain legality, activity clock and identity
contracts. The Python generator and private files were not copied into this repo.

`tests/wild_population_recovery.gd` exercises depletion, retained history,
successive generations, active-time pause, pending/due reload, local/distant
admission, player/reserved-target/barrier blockers, separate sightings,
imprint preservation, fresh guard warnings, ownership, disabled timing, legacy
migration, and malformed ledgers. It runs in `tools/validate.ps1`.

```powershell
godot --path . --script tests/wild_population_recovery.gd -- --capture-recovery
```

This writes ignored `artifacts/recovery/successor.png` using a short test delay.
Scripted input/rendering does not establish export, physical-device,
accessibility, ecological balance, or full D3/D5 acceptance.

Godot 4.7.2 import and the shared validator passed all 6,501 headless checks,
including 53 recovery checks and both scene journeys. The rendered recovery
suite separately passed all 53 checks, and the successor capture was inspected.
