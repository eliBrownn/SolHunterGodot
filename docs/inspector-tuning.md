# Adjusting the game in Godot

Open `scenes/world_3d.tscn`, select the **SolHunter3D** root, and expand
**Expedition Tuning** in the Inspector. The three resource fields are connected
to the simulation; expand a resource to edit its values. **Camera** contains the
existing elevation and azimuth controls. The comparison scene `scenes/world.tscn`
exposes the same controls.

You can also select the `.tres` files below in Godot's FileSystem dock. Save edits,
stop the game, and run again to apply them reliably. Editor changes are not
automatically synchronized into an already running game. Default resources are
shared: editing one affects scenes using that resource. To try a separate preset,
duplicate a `.tres` in Godot and assign it to the root's matching resource field,
or use Make Unique and save the result. Defaults preserve the current behavior.

| Resource / field | Default and range | Effect and save behavior |
| --- | --- | --- |
| `resources/expedition_settings.tres`: Initial Seed | 2601026; 0–2147483646 | Startup expedition seed. New Seed continues advancing from the current world's seed; loading uses the saved seed. |
| Move Seconds | 0.135; 0.04–1.0 seconds | Time per cardinal tile; lower is faster. Diagonal duration is multiplied by sqrt(2). Applies to loaded journeys too; does not change saved cells or terrain. |
| Territory Size | 16; 1–256 cells | Width/height of population home territories for new expeditions. Independent of rendering chunks. Existing saves retain their own territory size and IDs. |
| Population Cache Territories | 256; 1–1024 | Runtime summary capacity, applied when starting/replacing/loading state. Lower limits evict cached knowledge sooner, without deleting individuals or progress. Not ecological carrying capacity. |
| `resources/climate_settings.tres`: Moisture Frequency | 0.012; 0.001–0.1 | New expeditions only. Lower gives broader moisture/habitat regions; loaded saves retain climate. |
| Dry Threshold / Wet Threshold | 0.42 / 0.58; 0–1 | New expeditions only. Dry must be below wet; higher dry expands heath, lower wet expands marsh. Invalid combinations fall back with a warning. |
| `resources/vastra_settings.tres`: Recovery Interval Ticks | 120; 1–1000000 | Active ticks per healing interval. At the fixed 0.75-second activity tick, 120 is 90 active seconds. Applies to loaded worlds and their retained interval debt. |
| Recovery Points | 1; 0–100 | Overload points healed per interval. Zero disables healing; re-enabling can catch up retained known debt. Does not change concentration. |
| Tiles Per Tick | 32; 1–1024 | Maximum changed cells serviced per tick. Larger values reduce queue delay but cost more CPU. Applies to loaded worlds. |
| Root Camera Elevation | 35; 35–70 degrees | Applied at startup. Lower is closer to the plane; 35 is the selected low-angle presentation. |
| Root Camera Azimuth | 0; -45–45 degrees | Applied at startup. Zero preserves aligned world axes; changing it rotates the camera sideways. |
| `resources/sighting_settings.tres`: Enabled | true | Show/admit the three provisional sightings at startup/new seed/load. Disabling does not delete saved individuals. |
| Visible Radius / Reaction Distance | 14 / 3; 4–32 / 1–6 cells | Distance culling and Manhattan proximity labels. Presentation only, including loaded worlds. |
| Bob Pixels / Bob Cycles | 1 / 0.8; 0–3 pixels / 0.1–3 cycles per second | Idle animation amplitude/frequency. Zero pixels disables it; pause freezes it. No simulation or identity change. |

Hover properties for their Inspector tooltips. Recovery defaults are provisional
development tuning, not finalized ecological balance. Climate, movement, seed,
territory, cache, and recovery inputs are validated at runtime, including resources
assigned through code. Invalid expedition/recovery resources use defaults and warn
once per simulation instance; missing climate resources use the existing fallback.

`SolSpeciesDefinition` also appears as a creatable typed Resource with species,
lineage, class, ordinary form, and footprint fields. These are authored content
contracts, not an approved roster. Do not create a fourth ordinary form for a
legendary manifestation. Production regional capacities, harvesting budgets,
population recovery curves, and wildlife generators are not yet implemented as
connected authoring controls; this change adds no speculative sliders for them.

Schema/generation versions, identity formats, render chunk geometry, the activity
clock contract, and corruption/admission safety ceilings remain engineering
constraints. Changing those requires an explicit implementation/compatibility
change rather than treating them as balance values.

## Standard for future work

The [project standard](PROJECT_STANDARD.md) now requires future implemented tuning
to be exposed through typed resources or grouped scene-root properties, with
tooltips, units, ranges, validation, and documented application/save semantics.
Every feature PR should update this control map when adding or changing settings.

`tests/inspector_tuning.gd` validates actual root-resource wiring, changed movement,
world creation, recovery, cache eviction, saved identity/climate preservation,
invalid/missing resource fallback, and `.tres` serialization/reload. It runs in
`tools/validate.ps1`. This changes configuration access, not default game balance.

Validation passed Godot 4.7.2 import and all 6,126 headless assertions, including
14 tuning integration checks and both scene journeys. The tuning suite also
passed after moving its temporary resource fixture into unique user storage so
it does not depend on an ignored local artifacts folder. Existing GPU-only
checks remain outside this count; default presentation is unchanged.
