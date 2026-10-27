# First authored Sol sightings

The main and comparison scenes show three provisional individuals on clear cells
along the eastern trail: Seedmote near x=8, Bramblepup near x=26, and another
Seedmote near x=48. Walk east to approach the first one. Upright nearest-filtered
sprites preserve the 2D look in 3D. Names and reaction labels appear within the
configured approach distance.

This initial D3 presentation slice does not add roaming, physical blocking,
combat, capture interaction, rewards, or Wild Examine statistics. Wary, Watching,
and Guarding are temporary authored proximity postures, not implemented flee/chase
AI or trust gains. Earlier manual/device and D1/D2 acceptance gates remain open.

## Evidence and provisional content

Non-generation reference: SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`, `src/systems/world/roaming.py`
for home/approach presentation, and `src/systems/world/sol_catalog.py` plus
`content/sols/demo_species.json` for the selected provisional species metadata.
Godot generation remains authoritative; the source generator and full private
catalog are not copied.

Seedmote retains family_010/verdant and Bramblepup family_001/beast; both are
ordinary form 1 with footprint 1. This does not ratify the full roster or evolution
levels. Grove/gale are explicit temporary authored affinities, not source affinity
rolls. The original code-native 16×16 pixel placeholders are not final species art.

## Identity and lifecycle

`authored_sightings.gd` contains a bounded three-entry manifest. Home x is fixed;
y follows the existing Godot trail center. Illegal homes are skipped without
terrain edits or relocation. Home/species changes require a compatibility review
and are not presentation sliders.

Registration occurs only at explicit startup and expedition state replacement
(new seed/load). An older expedition can receive this new authored content, but
never fabricated relationship history, trust, outcomes, or prior journal entries.
Existing individuals are reused, including owned ones; acquired homes are not
refilled. The next explicit save persists the records. Load does not rewrite files.

Rebuild only creates views of existing wild records. Acquisition immediately hides
the wild view and remains owned after save/load. This exercises the domain seam
without adding a capture action. Distance culling, animation, disabling, and chunk
eviction never remove records or affect ecology. These notable individuals are not
a complete ordinary-wildlife population and do not publish a population census.

## Tuning and validation

Root **Expedition Tuning → Sighting Settings** assigns
`resources/sighting_settings.tres`. Enabled applies on startup/new seed/load;
disabling hides views without deleting individuals. Visible Radius is 4–32 cells;
Reaction Distance is 1–6 Manhattan cells; Bob Pixels is 0–3 (zero disables it);
Bob Cycles is 0.1–3 per active second. Presentation settings also affect loaded
worlds. Pause freezes animation. Invalid initial resources fall back with a
warning; invalid runtime values hide views safely.

`tests/authored_sightings.gd` checks representative seeds, legal fixed homes,
billboards, proximity labels, pause/distance behavior, rebuild, ownership hiding,
repeated admission, and actual save/load. Legacy-domain, population, and natural
recovery fixtures disable authored content to preserve their isolated manually
constructed domain contracts.

Rendered verification on Godot 4.7.2/OpenGL/RTX 3070 passed 36 assertions and
produced `artifacts/sightings/seedmote.png` after checking clear trail placement:

```powershell
godot --path . --script tests/authored_sightings.gd -- --capture-sightings
```

This is scripted visual verification, not owner/manual acceptance. Actual
observation/encounter interaction, approved behavior/content, and production wild
population generation remain future work.

The final shared validator passed Godot 4.7.2 import and all 6,162 headless
assertions, including both scene journeys and 36 new sighting checks. The rendered
sighting suite separately passed 36 checks. Existing GPU-only checks from other
suites remain outside the headless total.

The subsequent [observation/journal slice](sol-observation-journal.md) adds F to
record a nearby individual and a persistent Sightings tab. It still adds no
roaming, battle, capture action, or relationship gain.
