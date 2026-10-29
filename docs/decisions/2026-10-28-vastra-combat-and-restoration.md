# Vastra combat and restorative conditions

Date: October 28, 2026. Status: explicit owner retcon and implementation direction.
This supersedes the human-only overload-origin rule and unsigned overload scale.
The Bible remains the design authority; numerical defaults remain provisional.

## Approved rules

- All aggressive Vastra-powered abilities generate overload, in amounts authored
  per ability, on the tiles actually reached by their effects. Area abilities
  affect their covered tiles. Purely non-Vastra physical attacks are distinct.
- Healing abilities reduce overload independently of health restored, including
  at full HP, and may push it negative into a restorative condition.
- Negative overload helps damaged habitats and Sol populations recover with
  diminishing benefits. Both positive and negative overload relax toward zero.
- Concentration remains separate from overload. Rich healthy areas are possible.

## Approved presentation and delivery direction

Develop the storm opening and current connected expedition together. Vastra should
feel like a living energy connecting scenery, Sols and combat. Ordinary currents
are subtle light distortions with occasional luminous strands; richness and
disturbance strengthen their signs. Healthy flow is smooth; positive overload
tangles it with erratic surges. Matching environmental affinity briefly draws a
current toward the attacking Sol with a clear damage-bonus indicator.

The opening storm is uncanny and beautiful but threatening, revealing glimpses
of three rescuers: one scouts ahead, one stays beside the player, one watches
the rear, with distinct personalities. A companion notices the first ordinary
current clue. Refuge infrastructure visibly regulates incoming currents.
The exact clue and rescuer species were asked but not answered. Sound, barrier
flow details and everyday wildlife-current interactions remain unanswered.
Preserve the approved rescue → bonding/choice → mask → teaching battle → refuge
sequence. Do not invent exposure, failure, immunity or upkeep rules.

## Implementation and limits

See [Vastra integration](../vastra-integration.md) for the connected runtime,
Inspector settings, validation and remaining opening/content work. The initial
implementation uses a provisional -100..100 storage envelope, per-move positive
and negative changes, a tunable recovery response, and independent concentration.
These are development values, not finalized ecological or combat balance.

Read-only reference reconciliation used SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`, `src/systems/world/vastra.py`,
`vastra_recovery.py`, the caller `vastra_simulation.py`, and
`tests/test_vastra_recovery.py`. Its unsigned storage and
positive-only recovery are superseded by this explicit owner retcon. Preserve its
bounded elapsed-tick service, fractional interval progress, independent channels
and replay safeguards through Godot-native systems. Godot retains generation authority.
