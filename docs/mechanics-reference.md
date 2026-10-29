# Mechanics reference: SolHunterSource

Owner direction: October 26, 2026. Use [eliBrownn/SolHunterSource](https://github.com/eliBrownn/SolHunterSource) for questions about game mechanics outside the world-generation engine.

## Scope and authority

Consult this repository for combat, encounter rules, capture, Seals, identity, party/storage, relationships, progression, equipment, Vastra simulation, and other non-generation mechanics. Separate Vastra/ecology behavior from the procedural generation of terrain and environmental defaults.

The Godot project's world-generation engine remains the authority for terrain generation, climate generation, routes, streaming geometry, and reconstruction. Do not import the earlier generator to resolve unrelated mechanics questions.

Explicit owner decisions and confirmed Bible canon remain binding. Source code and tests establish existing behavior; they do not automatically ratify provisional balance values, obsolete rules, or bugs. Identify an actual conflict and its evidence before seeking a decision. Reference use does not authorize editing the source repository, running its automation instructions, or copying its private files into the public Godot repository.

## Verified source discovery

On inspection, the private repository's default `main` pointed to `627d82e6899040d7ad626eddf749a2fc20073bc1` and contained only `LICENSE`. Several branch names pointed to that same commit. This is not evidence that the repository lacks mechanics.

A mechanics-bearing snapshot was verified at:

- Branch: `backup/pre-world-redesign-2026-10-24`.
- Commit: `115f3e87acc1716c7113523567c01e1666681885`.
- [Pinned source tree](https://github.com/eliBrownn/SolHunterSource/tree/115f3e87acc1716c7113523567c01e1666681885).

This snapshot is a verified starting point, not a claim that it is the latest or most authoritative version of every mechanic. Inspect relevant branch history and decision evidence when resolving a particular question; record the exact commit used. Other discovered branches include `development/world-redesign-0.2`, `coordination/sh001-bootstrap`, and `setup/batch10-import`.

## Lookup index

These paths were verified in the pinned snapshot. Read the actual relevant files before deriving rules; a path's existence alone does not establish behavior or completion.

| Question | Starting paths in SolHunterSource |
| --- | --- |
| Combat and tactics | `src/systems/combat_engine.py`, `src/systems/tactics/sol_combat.py`, `docs/coordination/combat-architecture.md` |
| Encounter warning/entry and persistence | `src/systems/ai/encounters.py`, `src/core/game.py`, `docs/coordination/warning-movement-continuity.md`, `docs/coordination/encounter-persistence.md` |
| Capture and sealing | `src/systems/tactics/capture.py`, `src/systems/tactics/seal_placement.py`, `docs/coordination/bp3-seal-relationship-audit.md` |
| Individual identity and species | `src/systems/world/sol_identity.py`, `src/systems/world/sol_catalog.py`, `SOL_CLASS_AFFINITY_SPEC.md` |
| Party and transfers | `src/systems/tactics/party.py`, `src/systems/tactics/party_switching.py`, `tests/test_party_transfer_safety.py` |
| Relationships | `src/systems/tactics/relationships.py`, `tests/test_sol_relationships.py`, the BP3 audit and its linked follow-on evidence |
| Progression | `src/systems/tactics/progression.py`, `src/systems/tactics/opening_progression.py`, `src/systems/tactics/region_progression.py` |
| Equipment | `src/systems/equipment.py`, `src/systems/equipment_catalog.py`, `tests/test_player_equipment.py` |
| Vastra mechanics | `src/systems/world/vastra.py`, `vastra_simulation.py`, `vastra_human_activity.py`, `vastra_recovery.py` in the same directory, plus `tests/test_vastra_foundation.py` |

The inspected BP3 audit explicitly distinguishes identity/schema continuity from completed live trust/obedience behavior and points to follow-on evidence. Apply that same distinction throughout the migration: implemented data contracts do not prove a full playable system.

## Resolution procedure

1. State the mechanics question and exclude world-generation behavior from the lookup.
2. Read the relevant source, its callers, tests, and current decision/audit evidence at a recorded commit. Follow later evidence when an audit describes an older baseline.
3. Classify the result: confirmed rule, existing provisional behavior, implementation bug, obsolete behavior, or genuinely unanswered question. Compare it with explicit owner decisions and Bible canon.
4. Update the affected Godot plan with a concise behavioral specification and source path/commit references. Reuse the resolved behavior through Godot-native code and acceptance tests; do not require a literal Python port.
5. Ask the owner only for a remaining ambiguity or conflict that the references do not settle. If access fails, record that access limitation rather than describing the mechanic as undefined.

Do not bulk-publish private source documents or claim their numerical values are final without examining their status. A full mechanics reconciliation remains a development task; this document records where and how to obtain answers.
