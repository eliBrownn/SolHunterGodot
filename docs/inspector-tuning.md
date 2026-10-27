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
| Observation Distance | 3; 1–6 Manhattan cells | F selects a nearby settled-player sighting within this range and visibility radius. Applies to loaded sightings; retained first-seen journal records do not change. |
| Local Movement: Enabled / Interval Ticks | true / 1; 1–8 ticks | Run local responses once per interval of the 0.75-second active clock. Disable without resetting saved cells. |
| Home Radius / Movement Radius | 5 / 7; 1–5 / 4–16 Manhattan cells | Limit distance from fixed home and player-local simulation range. Smaller home range returns gradually; no ID change. |
| Comfort Distance / Flee Release Distance | 2 / 5; 1–3 / 2–8 cells | Neutral stopping distance and flight hysteresis. Release must be at least Reaction Distance. |
| Movement Blend Seconds | 0.2; 0.05–0.5 seconds | Visual interpolation per cell. Does not change authoritative movement cadence. |
| `resources/encounter_settings.tres`: Enabled / Automatic Contact | true / true | Manual R approach and warned later-contact entry for the authored guard. Loaded worlds use current settings; no identity change. |
| Warning / Contact / Interaction Distance | 3 / 1 / 3; 1–6 / 0–1 / 1–6 cells | Manhattan warning band, later-step automatic contact, and manual R selection. Warning must cover contact. |
| Withdrawal Safe Steps | 3; 1–8 successful steps | Prototype automatic re-entry protection. Runtime-only; manual approach remains available. |
| `resources/battle_settings.tres`: Enabled | true | Enable companion choice and Battle button. Applies at scene startup; disabling preserves saved companions. |
| Starters / Opponents | Three unique starters / 1–16 unique opponent profiles | Authored resolved profiles. Starters are snapshotted when explicitly chosen; opponents when a battle begins. Loaded chosen profiles retain saved values. |
| Arena Radius | 4; 3–6 cells | Half-width/height around trainer; default 9×9 arena. Applies to new battles, using existing terrain. |
| Movement Points / Release Range | 3 / 3; 1–8 / 1–4 cells | Shared cardinal movement per turn / Manhattan deployment distance. Snapshotted at battle entry. |
| `BattleProfile`: identity and display fields | Species, lineage, class, affinity, name, move name | Must be compatible with existing individual metadata. Changing resources does not rewrite saved individuals. |
| Level / Max HP | 3 starters, 1 wild / 36–50 HP; 1–55 / 1–1000 | Authored level and resolved health ceiling; no automatic level scaling. Selected starter profile and current HP persist. |
| Attack / Defense / Speed | Per-profile defaults; 0–1000 | Resolved physical stats and initiative. Saved for chosen starter; snapshotted per new wild battle. |
| Move Power / Move Range | 6 / 2; 1–100 / 1–6 cells | Neutral physical basic damage and Manhattan targeting, subject to terrain line blocking. |
| Root Sol Visual Settings | `resources/sol_visual_settings.tres` | Shared exploration/battle orb presentation. Restart or reconstruct views after changing visual values; no save migration or individual changes. |
| Diameter / Hover Height | 0.75 / 0.7; 0.3–1.2 / 0.35–1.5 world cells | Pixel sphere size and real 3D center height above ground. Existing sighting Bob Pixels/Cycles settings animate both wild and battle orbs. |
| Aura Opacity / Effect Count / Effect Speed | 0.22 / 5 / 0.6; 0–0.6 / 0–12 / 0–3 cycles per second | Halo strength and bounded decorative motes; zero opacity/count disables the corresponding effect, zero speed freezes effects. |
| Palette | Ten provisional affinity ID → color entries | Uses the saved individual's affinity, with neutral white for unknown IDs. Custom opaque colors are supported. Species/class never select the color. |

The subsequent [affinity and moves implementation](affinity-moves-imprints.md)
replaces the ten-color default palette with the eight approved color directions
(exact RGB remains art tuning), including animated pink/cyan Quantum orbs.

| Move Library control | Range / application |
| --- | --- |
| Root Move Library | `resources/move_library.tres`; restart after authoring changes. Invalid libraries fall back to the default prototype library. |
| Moves: ID / name / affinity / effect | Explicit authored identity and effect kind. Affinity is independent of the learner. Saved remembered definitions do not reroll. |
| Move power / reach / duration | 0–100 HP power or healing / 1–6 Manhattan cells / 1–1000 tactical rounds. Field actions currently affect a target and its legal cardinal neighbors. |
| Species Pools / Starting Moves | Up to 32 move IDs per species; starting moves must be in the pool. First four start equipped. Newly admitted books snapshot eligibility and initial definitions. |
| Recovery Interval | 1–1000 active 0.75-second ticks per recovery stage; default 8. Captured in each saved condition, so later edits do not rewrite existing recovery debt. |
| Field Damage | 0–10 HP per tactical round; default 2. Shared Fire/Lightning effects; applies to new battles. |
| Rough Cost | 1–4 movement points per cardinal tile; default 2. Applies to new battles. |
| Assisted / Resisted Cost | 0–1 / 1–4 movement points; defaults 0 / 2. Currents, winds and warp zones affect both sides. Applies to new battles. |

Move Library also exports World Condition Timing multipliers, each 0.25–4×:
rough 1.5×; favorable flow 0.75×, opposed flow 1.5×; vertical warp 0.5×,
horizontal warp 2×. The base Move Seconds remains adjustable. These are prototype
defaults, not finalized balance or a change to generated terrain legality.
Sol Visual Settings also exports Imprint Opacity (0–0.5, default 0.22); zero
hides the local ground tint without deleting saved affinity.

The [battle feedback slice](battle-feedback.md) adds Sol Visual Settings controls:

| Control | Default / range | Application |
| --- | --- | --- |
| Feedback Enabled | true | Suppress new floating cues when false; existing cues finish fading. |
| Feedback Seconds | 0.9; 0.25–2.5 seconds | Real-time cue lifetime, including while exploration is paused for battle. |
| Feedback Rise | 0.6; 0.1–2 world cells | Floating text travel; applies to active cues. |
| Feedback Limit | 16; 1–32 cues | Retire oldest cues on admission; bounds visual node growth. |
| Result Panel Enabled | true | Show the next runtime outcome recap. Does not affect commits, saves, or exploration pause. |

Battle settings are read for each new battle; restart after editing live resources
to refresh chooser labels and the Enabled switch. Current battle settings and
profiles are frozen for that battle. Refuge H recovery uses the chosen saved HP
ceiling. The same Withdrawal Safe Steps tuning controls saved post-battle
protection, while preview withdrawal protection remains runtime-only. See
[first playable battle](first-playable-battle.md) for provisional stat scope,
controls, persistence, and validation evidence.

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
