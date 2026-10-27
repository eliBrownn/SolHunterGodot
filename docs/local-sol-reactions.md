# Local Sol movement and reactions

The three authored trail Sols now react through actual local movement:
the wary Seedmote steps away, Bramblepup approaches to a comfortable distance,
and the guarding Seedmote holds its ground. Moved Sols can return toward home
after the player retreats. Their home IDs, affinities, ownership, and relationship
history do not change. This does not start battle or introduce capture rules.

## Reference and implemented scope

Source evidence is SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`, especially
`src/systems/ai/roaming.py`, `src/systems/ai/behavior.py`,
`src/systems/world/ecology_profiles.py`, and `tests/test_ecology_profiles.py`.
The source separates authored ecology policy from combat/capture identity,
uses bounded home leashes and occupancy reservations, and persists current
positions/actions. Godot generation remains the terrain/traversal authority.

This Godot slice implements the three explicit prototype responses, not the
complete source AI. Decisions use cardinal, strictly improving legal steps;
blocked goals wait instead of using the source's eight-way BFS detours. No idle
patrol goals, social following, per-individual trait variation, first-flight
relationship history, or automatic hostile encounter is added. Postures remain
provisional content, independent of any future combat/capture disposition.

Avoidant flight begins inside Reaction Distance and persists until Flee Release
Distance, avoiding immediate back-and-forth reversal. Neutral approach stops at
Comfort Distance. A guarding individual remains stationary. Distant individuals
are frozen with their state intact; there is no offline or distant roaming
simulation. A home-radius reduction permits gradual legal return, never teleport.

## Clock, terrain, and display ownership

The controller advances at most three individuals once per configured activity
interval. Each decision makes at most four legal-neighbor checks, respects the
Godot traversal contract, and reserves other local Sol cells plus the player's
current and already committed destination cells. Cornered Sols wait. Sol sprites
are still nonblocking for player traversal, so essential routes remain passable.
Movement neither changes concentration/overload nor implies ecological damage.

The persistent domain owns current cells/actions/ticks. View rebuild and visibility
changes never advance AI or reset positions. Presentation interpolates individual
cell steps and freezes while paused. A view reappearing after culling snaps to the
current saved position rather than drawing a straight catch-up path across old
terrain. Observation distance and first-seen coordinates use the authoritative
current cell, not home or interpolated sprite coordinates.

Exploration pause, deterministic smoke mode, disabled sightings/movement, and
invalid tuning stop controller updates. The existing two-tick frame-stall cap
still applies. Reload cannot execute the same decision tick twice. Old state
subscriptions detach at explicit state replacement; stale callbacks also check
the owning state before acting.

## Persistence

Domain version 5 adds a bounded `roaming` map referencing existing wild IDs with
current cell, action, and last decision tick. Outer save format remains 2. Domains
1–4 load without invented movement history; missing rows project their existing
homes until a later active decision. The technical saved home envelope is five
Manhattan cells, matching this prototype's stricter subset of the source leash.

Validation rejects orphan/owned rows, unknown fields/actions, malformed or future
ticks, and out-of-range coordinates before restoration. The save codec additionally
checks current cells against Godot terrain/footprint legality before writing or
loading a current-generation save. Terrain migration that makes a saved moved
position illegal fails safely rather than silently relocating that identity.
JSON integers normalize on restore. Acquisition retires wild movement state,
preserving the same owned individual and retained journal history.

## Inspector and verification

Under **Expedition Tuning → Sighting Settings → Local Movement**:

| Setting | Default / range | Meaning |
| --- | --- | --- |
| Movement Enabled | true | Stop/resume local decisions without resetting positions. |
| Movement Interval Ticks | 1 / 1–8 | One tick is 0.75 active seconds. Larger values slow decisions. |
| Home Radius | 5 / 1–5 | Manhattan leash; reductions return gradually. Saved IDs remain fixed. |
| Movement Radius | 7 / 4–16 | Update when current position or home is within this Manhattan player distance. |
| Comfort Distance | 2 / 1–3 | Neutral approach stopping distance. |
| Flee Release Distance | 5 / 2–8 | Flight hysteresis; must be at least Reaction Distance. |
| Movement Blend Seconds | 0.2 / 0.05–0.5 | Visual seconds per cell; does not alter decision cadence or legality. |

These settings apply to loaded worlds under the current policy and never reroll
identity. Idle Animation remains a separate Inspector group. Invalid initial
resources fall back; invalid runtime settings freeze movement and hide views.

`tests/local_sol_reactions.gd` covers flee/approach/guard, legal bounds, return,
cooldown, pause, distant/disabled behavior, blocked terrain, reconstruction,
real save/load, observation at moved cells, acquisition cleanup, schema upgrades,
malformed incoming/outgoing rollback, and terrain-invalid save rejection.
The final shared validator passed Godot 4.7.2 import and 6,251 headless assertions,
including both scene journeys and 51 movement checks. The rendered movement suite
separately passed 51 checks. Other suites' GPU-only checks are outside the
headless total.

Reproduce the inspected OpenGL/RTX 3070 capture with:

```powershell
godot --path . --script tests/local_sol_reactions.gd -- --capture-movement
```

Output: `artifacts/roaming/flee.png`. This is scripted verification, not manual
acceptance. D3 still needs actual encounter initiation/resolution and broader
authored behavior/content. Production wild generation and full milestone/device
acceptance remain open.

The subsequent [encounter-entry prototype](encounter-initiation.md) adds manual
approach and owner-approved warned guard contact, with record/withdraw choices.
Tactical battle and capture remain separate unimplemented systems.
