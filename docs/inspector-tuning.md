# Adjusting the game in Godot

## Early moves, supply and hybrids — October 28

The 50-move library and explicit species kits follow
[early combat move principles](early-combat-moves.md). Select each `SolMove` in
`resources/move_library.tres`:

| Control | Allowed range / connected effect |
| --- | --- |
| Max Uses | 1–40 successful uses per encounter; independent per side and move identity |
| Action Points | 1–12 for active moves; exactly zero for automatic equipped passives |
| Damage Percent | 25–125% of shared direct damage; light early attacks use 40–70% |
| Secondary Effect / Power | None, one shared terrain tile, or a 1–20% buff/debuff/protection after the primary hit/heal |
| Passive Kind | Guard or renewal for a passive move; Power is HP blocked/healed per useful trigger |
| Description | Authored tactical purpose shown in battle/loadout tooltips |

Battle Settings also exposes Exhausted Move Fallback: Action Points (default 4,
1–12 and no higher than the turn budget), Damage Percent (40%, range 25–75%) and
Reach (1, range 1–3 clear cells). These apply at the next battle and are included
in displayed snapshots and development fixtures. Its zero power and absence of
imprint/Vastra activity are the fallback contract rather than separate sliders.

Costs, supply and effect metadata are snapshotted into remembered moves. Existing
individuals retain their definitions; use a new expedition to test edited library
values and the three new remembered alternatives per species. Spent uses reset
at battle entry, not each turn, and are not expedition-save attrition. Original
four-slot equipment and individual affinity remain unchanged. Reaction limits and
hybrid effects are connected domain rules, not presentation-only sliders.

## Eighteen-class first-form content

The shared `resources/sol_species/catalog.tres` now has one first-form record per
current class. Records 0007–0018 link twelve distinct `scenes/sols/` models,
provisional reference stats, seven-move pools, ecology and ground traversal.
See the [Sol Bible index](reference/sol_bible.md#authored-species-index) for canonical
sheets. Existing typed stat, pool, temperament and clearance controls apply;
admitted individuals retain saved stats/moves/affinity. Models use inherited
scale (0.65), idle/action/step/turn controls and apply after view rebuild/restart.
Resize or reshape a body only with a corresponding clearance/envelope review.

The normal-world preset authors each additional trail home and that individual's
affinity. The companion behavior resource selects `<species>_moment` idle branches;
existing global rest/moment timing controls remain connected. All twelve new
traversal policies are ground-only. Habitat text or gliding anatomy is not an
unused flight, digging or ecological slider.

Class settings include a separate Eldritch definition at fixed zero potency.
Nonzero bounds reject while its passive remains unauthored; this is an admission
constraint, not a promised balance control. Legacy Stonebound keeps its existing
definition. An eventual Eldritch passive requires authored mechanics and an
intentional change to that constraint.

## Combat action budget — October 28

| Control | Default / range | Connected effect |
| --- | --- | --- |
| Battle Settings / Action Points | 6 / 1–12 points | Shared turn budget, refilled only when an actor starts its turn |
| Battle Settings / Speed Per Movement Point | 10 / 1–100 Speed | Effective Speed per free movement point, rounded down at turn start |
| Battle Settings / Movement Points | 3 / 1–8 points | Cap on Speed-derived free movement, before class/disruption adjustments; extra movement spends AP |
| Battle Settings / Seal Action Points | 4 / 1–12 points | Seal affordability/cost; failure still ends the turn |
| Move Library / each SolMove / Action Points | attacks/healing 4, setup 2 / 1–12 points | Cost of each accepted move; positive costs bound repeated actions |

Battle settings apply at the next battle, including after loading an expedition.
Move costs are snapshotted in admitted/learned movebooks; start a new expedition
to review library authoring changes. Missing snapshot costs use effect defaults.
The AP HUD, route preview, enemy planning and domain execution share these values.
Speed changes do not refill movement mid-turn. See [turn rules](combat-action-budget.md).

## Vastra combat and restorative conditions — October 28

`resources/vastra_settings.tres` now connects signed relaxation (both signs toward
zero), restorative maximum bonus and half-strength, environmental concentration
damage scaling, and local current enable/count/radius/opacity/refraction. Numeric
defaults remain provisional. Simulation settings apply to active ticks, including
loaded worlds; restart to change current enable/count. Radius, opacity, refraction
and palette edits apply within 0.5 seconds. Currents sample only a
bounded local view and never write ecological state.

`SolMove` resources in `resources/move_library.tres` expose Vastra Powered,
Aggressive (for terrain/support abilities), Overload Points and Restoration Points.
Aggressive damage, poison and debuff effects are inferred from their effect type.
Amounts apply per actually affected tile; healing works independently of HP healed.
Saved movebook snapshots retain authored values; omitted fields use the new
provisional defaults. Start a new expedition to review changed library authoring.
The signed storage envelope is currently -100..100, not finalized balance.
See [Vastra integration](vastra-integration.md) for ownership and acceptance limits.

Current rendering uses one shared geometry/material batch and a bounded derived
terrain cache. These are implementation limits, not new gameplay tuning controls;
concentration, signed overload and recovery continue to read the saved authority.

## New first-form workshop models

Ashquill, Rattlehorn and Rimefold have isolated review scenes under `scenes/`:
`ashquill_workshop.tscn`, `rattlehorn_workshop.tscn`, `rimefold_workshop.tscn`.
Open one with F6. Their Model Scene fields point to distinct direction-B builders
under `scenes/sols/`; select that model scene's root to edit inherited typed
controls. Their models are now also connected to normal gameplay through the
shared catalog, retaining their small first-stage scene settings.

| Control | Units / allowed range | Connected effect |
| --- | --- | --- |
| Model Scale | uniform multiplier, 0.5–1.5; authored default 0.65 | Small first-form visual scale; not final height, footprint or evolution logic |
| Idle Strength / Rate | multiplier 0–2 / cycles per second 0–2 | Breathing, attention and appendage motion |
| Action Seconds | seconds, 0.1–1 | Attack/hit/signature and recovery envelope; no battle delay |
| Step Distance | metres, 0.04–0.3 | Support step threshold; Ashquill 0.06, Rattlehorn 0.05, Rimefold 0.04 before art scale |
| Step Lift | metres, 0–0.15 | Swing-foot lift; authored 0.045 / 0.03 / 0.02 respectively |
| Turn Response | inverse seconds, 1–30 | Visual turning from committed displacement |

The workshop validates inherited model tuning before building. Restart/rebuild
after editing scene files. The workshop's Walk Speed (0.1–2 m/s), Exercise and
Affinity fields affect only review. G/J/H cue signature/attack/hit. No flight or
swimming capability is implied by anatomy or by an isolated workshop exercise.
See [anatomy review](sol-creature-anatomy-review.md) for selection and evidence.

### Applied species records and sightings

Edit `resources/sol_species/ashquill.tres`, `rattlehorn.tres`, or `rimefold.tres`
for reference-level stats, existing-move pools, ecology and ground traversal
clearance. These are the existing typed Inspector controls and runtime validation;
no second balance table or species-affinity setting was introduced. Provisional
reference stats/moves apply to new admissions, while saved individual traits and
movebooks remain intact. The existing training-capacity value is provisional,
not an approved family count. Scene scale changes apply after view rebuild/restart.

`resources/sol_world_sightings.tres` now includes the three explicit homes at
trail x=22/40/56 and their individual affinities. Placement edits do not relocate
saved identities; new species are admitted through normal new/load initialization.
`resources/owned_companion_behaviors.tres` selects preening, testing footing and
fin investigation for the new species. Global rest/moment timing remains in
the existing companion settings. All three are ground-only in this slice.

## Existing game controls

Normal F5 play now explicitly uses `resources/sol_world_sightings.tres` for
**Expedition Tuning > Sighting Settings**, plus the enabled companion settings.
This adds Crown-Ear, legal-bank Reedback and Bellroot while retaining wilderness
and the existing behavior defaults. Tune the new world preset for the normal
game; `resources/sighting_settings.tres` remains the legacy comparison preset.
See [normal-game rollout](sol-species-data.md#normal-game-rollout) for placements,
save admission and ownership continuity.

Owned companion controls are now under **Expedition Tuning > Companion Settings**:
selected owned following with species flight/swimming, preferred admission side,
stop/resume distances, step duration, bounded search/culling, idle timing and
inherited species moments.
See [owned companion](owned-companion.md) for ranges, save/load reconstruction,
application timing and traversal scope. Species resources tune altitude, draft and
body clearance on selection/load; Step Seconds tunes owned transitions. Ownership
and combat remain unchanged.


Combat phase 3 adds development-only recipes under `resources/combat_pacing/`.
Open an ordinary/terrain/major recipe in the Inspector to edit existing profiles,
up to four move IDs per side, fixed individual class potency (1–10), arena offsets,
blocked/wet/heat cells and initial field lifetime (1–20 tactical rounds). Recipes
validate before building and apply to the next probe only; production encounters
and saves do not consume them. The optional `concise.tres` uses the existing
Sol Visual Settings pacing properties (0.15/0.25/0.08/0.15 real seconds for
action/consequence/movement/turn). Select it through the fixture runner's
`-Timing concise`; production defaults are unchanged. See
[encounter pacing measurements](combat-pacing.md) for launch commands, complete
measurement definitions, provisional results and the open owner acceptance gate.

Wild Sol behavior now has an inherited library at **Sighting Settings > Species
Behavior > Behavior Library** (`resources/sol_ecology/behavior_library.tres`).
Species profiles select branch IDs; children inherit a root's movement primitive
and can specialize its response tuning using species/class/affinity filters.
Each response override uses -1 for inheritance. Priority resolves overlap, with
stable specificity/depth/ID tie breaks. Nested live edits refresh on the next
decision; existing deadlines finish first. See [Sol ecology](sol-ecology.md#inherited-behavior-library--october-28-2026)
for exact units, ranges, validation, and the distinction between territorial
defense and future pursuit. No save-version change or new affinity ability.

The [activity correction](sol-activity.md) fixes indefinite near-player watching
and static guards. **Player Reactions** adds Attention Ticks (2, 0–16), Routine
Ticks (6, 1–16), and Guard Standoff Distance (2, 1–3 cells). **Wandering** adds
Patrol Rest Chance (0.35, 0–1) and Blocked Goal Retry Ticks (2, 1–8); global Rest
Min/Max Ticks now default to 1/3. Existing deadlines finish before edited durations
apply; new decisions/goals use live tuning. Current state domain is 14, save format
3, generation 6. See the linked document for exact behavior and acceptance evidence.

The [natural movement pass](sol-natural-movement.md) replaces Movement Blend
Seconds with **Movement Travel Fraction** (default 1, range 0.25–1 of the decision
interval), adds **Patrol Goal Min Fraction** (0.5, range 0.2–1 of patrol radius),
and uses domain 13 for the saved patrol counter. Queued steps keep their duration;
new goals/steps use live tuning. World save format remains 3, generation 6.

Wild Sol phase 4 adds **Sighting Settings > Species Behavior** and editable
`resources/sol_ecology/` profiles for behavior sets, caution/spacing/activity
variation, patrol radius scaling, and rest scaling. See
[Sol ecology](sol-ecology.md) for defaults, ranges, live edits, and identity rules.

Wild Sol phase 3 adds **Sighting Settings > Player Reactions** (release distance,
approach resumption, reposition cooldown, settling ticks) and **Encounter Settings
> Warning Delay Seconds**. See [Sol player reactions](sol-player-reactions.md) for
defaults, ranges, validation relationships, and loaded-save behavior. Current AI
response state was introduced in domain version 12; the domain-11 notes below describe the
earlier autonomous-wandering delivery.

Open `scenes/world_3d.tscn`, select the **SolHunter3D** root, and expand
**Expedition Tuning** in the Inspector for simulation resources. **Camera**
contains orbit/tilt/sensitivity, **Player** contains model height, and **3D View**
contains View Settings, Nature Settings and Atmosphere Settings. Expand a resource to edit its values.
**Interface** contains Menu Settings for the field menu's authored defaults.
The comparison scene `scenes/world.tscn` retains an orthographic terrain reference;
the default game view is perspective.

You can also select the `.tres` files below in Godot's FileSystem dock. Save edits,
stop the game, and run again to apply them reliably. Editor changes are not
automatically synchronized into an already running game. Default resources are
shared: editing one affects scenes using that resource. To try a separate preset,
duplicate a `.tres` in Godot and assign it to the root's matching resource field,
or use Make Unique and save the result. Defaults preserve the current behavior.

| Resource / field | Default and range | Effect and save behavior |
| --- | --- | --- |
| Terrain study root / Presets | `scenes/terrain_preview.tscn`; Very gentle / Rolling / Upper relief | F6 shape study only; does not change F5 terrain or expedition saves. See [terrain preview](terrain-preview.md). |
| Terrain study / Study Seed | 2601026; 0–2147483646 | Restart the preview to apply. Same seed across all comparison presets. |
| Root Terrain Settings | `resources/terrain_rolling.tres` | New expeditions use copied relief parameters; current saves restore theirs. See [natural terrain](natural-terrain.md). |
| Terrain relief / Broad Scale, Broad Amplitude | 144 cells (64–256); Rolling 3.2 cells (0–8) | Broad independently seeded landforms; amplitude is not measured peak-to-trough relief. New expedition applies edits; preview rebuild applies them to the study. |
| Terrain relief / Detail Scale, Detail Amplitude | 48 cells (16–96); Rolling 0.55 cells (0–2) | Secondary landform channel, copied into the expedition's saved relief parameters and the preview snapshot. |
| Terrain relief / Micro Amplitude, Warp Amplitude | Rolling 0.06 cells (0–0.15); 8 cells (0–16) | Eight-cell micro sampling scale; broad-channel displacement. Zero warp disables it. New expeditions only; saved parameters are retained on load. |
| Terrain relief / Walkable Slope Degrees | 25 degrees; 15–35 | Both triangles of each standing cell must pass; shared traversal and spawn/battle admission use it. Saved per expedition. Unsafe essential-route settings fall back to Rolling. |
| Root Menu Settings | `resources/menu_settings.tres` | Restart after editing. Validated defaults for the unified field menu; local remembered preferences override size, position, scale and opacity. Reset Menu Layout restores authored defaults. No gameplay save changes. |
| Window Size / Minimum Size | (940,620) / (660,440) unscaled viewport pixels | Finite bounds: width 620–1600, height 380–1000; minimum must fit within window size. Drag the corner to resize live. Narrow viewports reduce effective scale and clamp position, with scrollable navigation/content. |
| UI Scale / Background Opacity | 1.0 / 0.97; 0.75–1.25 / 0.7–1.0 | Options applies these live and remembers them in `user://menu_preferences.cfg`. Opacity affects the panel background; text stays opaque. |
| Remember Layout / Font Size / Colors | true / 16 (14–20) / forest, gold, light text | Startup theme settings. Colors must be finite opaque RGB 0–1. Disabling Remember Layout suppresses preference reads/writes. |
| `resources/expedition_settings.tres`: Initial Seed | 2601026; 0–2147483646 | Startup expedition seed. New Seed continues advancing from the current world's seed; loading uses the saved seed. |
| Move Seconds | 0.195; 0.04–1.0 seconds | Time per cardinal tile; lower is faster. Walking and running are about 30% slower following owner feedback on October 28. Diagonal duration is multiplied by sqrt(2). Applies to loaded journeys too; does not change saved cells or terrain. |
| Territory Size | 16; 1–256 cells | Width/height of population home territories for new expeditions. Independent of rendering chunks. Existing saves retain their own territory size and IDs. |
| Population Cache Territories | 256; 1–1024 | Runtime summary capacity, applied when starting/replacing/loading state. Lower limits evict cached knowledge sooner, without deleting individuals or progress. Not ecological carrying capacity. |
| `resources/climate_settings.tres`: Moisture Frequency | 0.012; 0.001–0.1 | New expeditions only. Lower gives broader moisture/habitat regions; loaded saves retain climate. |
| Dry Threshold / Wet Threshold | 0.42 / 0.58; 0–1 | New expeditions only. Dry must be below wet; higher dry expands heath, lower wet expands marsh. Invalid combinations fall back with a warning. |
| `resources/vastra_settings.tres`: Recovery Interval Ticks | 120; 1–1000000 | Active ticks per healing interval. At the fixed 0.75-second activity tick, 120 is 90 active seconds. Applies to loaded worlds and their retained interval debt. |
| Recovery Points | 1; 0–100 | Signed overload magnitude returned toward zero per interval. Zero disables relaxation; re-enabling can catch up retained known debt. Does not change concentration. |
| Tiles Per Tick | 32; 1–1024 | Maximum changed cells serviced per tick. Larger values reduce queue delay but cost more CPU. Applies to loaded worlds. |
| Root Camera Elevation | Script default 35; 10–80 degrees | Starting tilt; scene overrides remain authoritative. Middle-drag adjusts live; Home restores the authored value. Runtime adjustment is not saved. |
| Root Camera Azimuth | 0; -180–180 degrees | Starting orbit; zero aligns world axes. Middle-drag adjusts live; Home restores it. Runtime adjustment is not saved. |
| Root Camera Drag Sensitivity | 0.25; 0.05–1 degrees per mouse pixel | Middle-drag orbit/tilt speed. Read live; invalid values fall back to 0.25. Wheel dolly works during combat; Home restores View Settings' Starting Distance. |
| Root Player Height | 1.7; 1.2–2.4 world cells | Scales the supplied rogue model at startup. Presentation only; no saved identity or collision change. |
| Root Nature Settings | `resources/nature_settings.tres` | Common/hardy trees, rocks and undergrowth PackedScene palettes. Applies to rebuilt chunks after restart; deterministic visual selection from existing terrain data. Invalid settings use defaults. No save changes. |
| Tree / Rock / Undergrowth Height | 3.5 / 0.65 / 0.35; 2–7 / 0.3–1.2 / 0.1–0.8 world cells | Normalizes imported models before deterministic per-cell size variation. Rebuild/restart to apply. |
| Hardy Trees palette | Olive dry-tree placeholder and supplied dead tree | Red twisted-tree foliage removed from the active palette. Cosmetic only; restart/rebuild applies it to current or loaded worlds. See [placeholder assets](../assets/biome_placeholders/README.md). |
| Undergrowth Percent | 12; 0–40 percent | Nonblocking visual decoration on free ground outside routes/refuge/landmark. Zero removes decoration on rebuild; obstacle placement and path legality stay authoritative. |
| Root View Settings | `resources/view_3d_settings.tres` | Restart after editing, or call `apply_view_settings()` on the running root to reconfigure. Pure presentation; no save/identity/generation changes. Invalid policy falls back to defaults. |
| Field of View | 50; 35–75 vertical degrees | Perspective camera FOV. Replans the visible terrain and tall-asset coverage. |
| Starting / Minimum / Maximum Distance | 22 / 8 / 40; 8–40 / 5–20 / 20–48 world cells | Camera orbit/dolly distance. Minimum ≤ Starting ≤ Maximum; maximum must be at least 4 cells inside Render Distance. Home restores Starting Distance. Runtime zoom is not saved. |
| Render Distance | 72; 48–128 world cells | Camera far clipping depth, frustum streaming extent, and distant fog. Larger values increase terrain/asset work. Turn, tilt, zoom and viewport resize all replan coverage. |
| Stream Margin / Chunks Per Frame | 8 / 1; 4–16 cells / 1–4 chunks | Prefetch margin and runtime detailed terrain/scenery publication budget. Visible startup/rebuild coverage is prepared synchronously. Near player and camera neighborhoods stay resident; distant chunks are evicted. Temporary ground covers visible queued chunks during turns. |
| Stream Ground Step | 4; 1 / 2 / 4 / 8 cells | Sample spacing for temporary, noncolliding ground while detailed chunks are queued. Coarser samples reduce camera-turn work; skirts conceal seams. Samples use the active world's generated heights/water. Restart/reapply view settings; not saved. |
| Detail Distance / Shadow Distance | 0 / 48; 0–128 / 16–80 cells | Zero keeps decoration with trees to the horizon; positive values enable whole-chunk decoration culling. Directional shadows are clamped to the far clip. |
| Fog Start Fraction | 0.8; 0.4–0.85 | Clear-weather fog begins at this fraction of the fixed horizon, fully opaque 4 cells before the far clip. At the default 72-cell view, begin/end are 54.4/68 cells from the camera. Turns and loading queues do not pull fog closer. Rain retains its separate earlier-onset multiplier. Restart/reapply view settings; not saved. |
| Sky Shader / Cloud Primary / Cloud Secondary | `shaders/daylight_sky.gdshader` / clouds 01 / clouds 07 | Day/night shader uses the supplied procedural cloud presets. Seven presets remain available. Atmosphere Settings drives sun/moon, current sky colors and weather. |
| Horizon Color / Sky Color | `#b7d4ed` / `#4387c8`; opaque RGB 0–1 | Daytime horizon/fog and upper-sky endpoints; blended with night/sunset/weather colors. Sky remains visible above the fog. |
| Cloud Density / Cloud Wind | 0.65 / (0.1, 0.035); 0–1 / -2–2 each component | Connected sky shader uniforms. Density zero clears clouds; wind zero freezes their translation. Cosmetic, not saved. |
| Root Atmosphere Settings | `resources/atmosphere_settings.tres` | Restart after editing, or call `apply_atmosphere_settings()` on the running root. Validated copy drives the actual lights, sky, rain and status display. No schema change; visual phase derives from saved active time. |
| Cycle Enabled / Day Seconds / Starting Phase | true / 1200 / 0.38; 120–7200 seconds / 0–1 phase | Full cycle duration in active exploration seconds. Phase 0 midnight, 0.25 sunrise, 0.5 noon, 0.75 sunset. Disable cycle for fixed-time authoring. Policy edits recalculate appearance without rewriting saved time. |
| Sun Elevation / Azimuth / Energy / Color | 55° / -30° / 1.25 / `#fff1d9`; 25–80° / -180–180° / 0–3 | Maximum altitude, world arc heading, relative daylight strength and daytime color. Visible sun and cast shadows share the same direction. |
| Moon Energy / Color | 0.32 / `#a7c9f0`; 0–0.8 | Moon opposite the sun; below-horizon light disables. No lunar phase calendar is implied. |
| Day / Night Ambient | 0.6 / 0.28; 0–2 / 0–0.6 | Relative fill-light energy, with editable day/night colors. Smoothly blends through twilight. |
| Exposure / Shadow Opacity / Shadow Blur | 1.05 / 0.8 / 1.5; 0.5–1.5 / 0–1 / 0.5–3 | Scene exposure and light shadow controls. HUD text remains independent. Sun/moon share View Settings' shadow distance. |
| Night Sky / Night Horizon / Sunset Horizon | `#07162e` / `#263c59` / `#efaa7e` | Opaque 0–1 colors. Horizon fog follows the current blended sky, including rain. |
| Horizon Curve / Cloud Scale / Cloud Softness | 0.4 / 0.16 / 0.12; 0.2–1.2 / 0.05–0.5 / 0.04–0.3 | Sky gradient height, projected cloud size and cloud edge softness. Cloud projection fades before its horizon clamp. |
| Weather / Weather Seconds / Transition Seconds | auto / 300 / 20; auto, clear, cloudy, rain / 60–1800 / 1–60 seconds | Automatic choice is stable for seed and saved time interval. Transition must fit within the interval. Forced modes apply immediately for authoring. |
| Clear / Cloudy / Rain Weight | 0.5 / 0.3 / 0.2; each 0–1 | Relative automatic-weather weights; at least one must be positive. No simulation RNG or world mutation occurs. |
| Rain Fog Fraction / Rain Particles | 0.75 / 500; 0.4–1 / 0–1200 | Earlier fog onset in rain / bounded nearby CPU streaks. Zero particles disables streaks while preserving rainy sky and lighting. Particle animation is cosmetic and not serialized. |
| `resources/sighting_settings.tres`: Enabled / Wilderness Enabled | true / true | Show/admit trail sightings and local prototype wilderness Sols. Disabling does not delete saved individuals. |
| Visible Radius / Reaction Distance | 28 / 3; 4–32 / 1–6 cells | Euclidean distance culling / base Manhattan detection band. Species profiles can adjust detection within valid bounds. |
| Bob Pixels / Bob Cycles | 1 / 0.8; 0–3 pixels / 0.1–3 cycles per second | Idle animation amplitude/frequency. Zero pixels disables it; pause freezes it. No simulation or identity change. |
| Observation Distance | 3; 1–6 Manhattan cells | Right-click Observe selects the pointed sighting. Recording requires a settled player within range and visibility radius. Distant and combat inspection show details without recording. Retained first-seen records do not change. |
| Local Movement: Enabled / Interval Ticks | true / 1; 1–8 ticks | Run local responses once per interval of the 0.75-second active clock. Disable without resetting saved cells. |
| Home Radius / Movement Radius | 5 / 28; 1–5 / 4–32 Manhattan cells | Limit distance from fixed home and player-local simulation range. Smaller home range returns gradually; no ID change. |
| Comfort Distance / Flee Release Distance | 2 / 5; 1–3 / 2–8 cells | Neutral stopping distance and flight hysteresis. Release must be at least Reaction Distance. |
| Movement Travel Fraction | 1; 0.25–1 of decision interval | Each queued legal step fills this fraction of cadence × 0.75 active seconds. New steps use edits; authoritative movement cadence is unchanged. |
| `resources/encounter_settings.tres`: Enabled / Automatic Contact | true / true | Right-click Engage and warned later-contact entry for the authored guard. Loaded worlds use current settings; no identity change. R opens the field menu. |
| Warning / Contact / Interaction Distance | 3 / 1 / 3; 1–6 / 0–1 / 1–6 cells | Manhattan warning band, later-step automatic contact, and selected-Sol Engage range. Warning must cover contact. |
| Withdrawal Safe Steps | 3; 1–8 successful steps | Prototype automatic re-entry protection. Runtime-only; manual approach remains available. |
| `resources/battle_settings.tres`: Enabled | true | Enable companion choice and Battle button. Applies at scene startup; disabling preserves saved companions. |
| Starters / Opponents | Three unique starters / 1–16 unique opponent profiles | Species reference profiles. Starters snapshot on choice; wild profiles on explicit individual profile admission. Saved individuals retain their reference stats, IVs and growth. |
| Arena Radius | 4; 3–6 cells | Half-width/height around trainer; default 9×9 arena. Applies to new battles, using existing terrain. |
| Movement Points / Release Range | 3 / 3; 1–8 / 1–4 cells | Shared cardinal movement per turn / Manhattan deployment distance. Snapshotted at battle entry. |
| `BattleProfile`: identity and display fields | Species, lineage, class, affinity, name, move name | Must be compatible with existing individual metadata. Changing resources does not rewrite saved individuals. |
| Level / Max HP | 3 starters, 1 wild / 36–50 species HP; 1–55 / 1–1000 | Reference level and species health before individual IVs/training. Natural level growth is automatic. Reference profile, resolved stats and current HP persist. |
| Attack / Defense / Special Attack / Special Defense / Speed | Per-profile defaults; 0–1000 | Species offense/protection and initiative before IVs/training. Special fields permit -1 to inherit authored physical values. Explicit special values remain independent of affinity. |
| Evolution Forms | 3; 1–3 | Number of ordinary forms; final available form unlocks full training capacity. Saved at profile admission, including single-form lines. Does not invent evolution content. |
| Move Power / Move Range | 6 / 2; 1–100 / 1–6 cells | Neutral physical basic damage and Manhattan targeting, subject to terrain line blocking. |
| Root Sol Visual Settings | `resources/sol_visual_settings.tres` | Shared exploration/battle sphere meshes, halos and effects. Restart or reconstruct views after changing visual values; no save migration or individual changes. |
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
Sol Visual Settings also exports Imprint Opacity (0–0.5, default 0: hidden after combat); zero
hides the local ground tint without deleting saved affinity.

The [battle feedback slice](battle-feedback.md) adds Sol Visual Settings controls:

| Control | Default / range | Application |
| --- | --- | --- |
| Feedback Enabled | true | Suppress new floating cues when false; existing cues finish fading. |
| Feedback Seconds | 0.9; 0.25–2.5 seconds | Real-time cue lifetime, including while exploration is paused for battle. |
| Feedback Rise | 0.6; 0.1–2 world cells | Floating text travel; applies to active cues. |
| Feedback Limit | 16; 1–32 cues | Retire oldest cues on admission; bounds visual node growth. |
| Result Panel Enabled | true | Show the next runtime outcome recap. Does not affect commits, saves, or exploration pause. |

The [wild recovery slice](wild-population-recovery.md) adds the root's Wild
Recovery Settings resource (`resources/wild_recovery_settings.tres`):

| Control | Default / range | Application |
| --- | --- | --- |
| Interval Ticks | 2400; 0–1000000 active ticks | 30 minutes at 0.75 seconds/tick. New victory/acquisition and historical-revisit waits capture an absolute deadline. Zero disables new waits, preserving old commitments. |
| Local Radius | 14; 4–32 cells | Due authored homes activate only within this distance, on free legal ground. Does not change IDs or deadlines. |

Restart after editing for consistent policy setup; live changes refresh on the
next active tick. Saved deadlines retain their original timing. Invalid initial
resources fall back with a warning; invalid live settings suspend admission.

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

The [AI, Seal and progression slice](ai-seals-progression.md) adds:

| Control | Default / range | Application |
| --- | --- | --- |
| Battle Settings: Seal Power | 10; 1–100 | Frozen per new battle; same probability in preview and execution. Supply remains unlimited testing supply. |
| Battle Settings: Commander Run Speed | 6; 1–10 world cells per real second | Applies to the next battle's validated outside route. Deployment waits for arrival; no exploration ticks or Sol movement costs. |
| AI Hazard Weight | 2; 0–10 | Penalty per expected shared field damage; lethal risk is tripled. Frozen per new battle. |
| AI Heal Weight | 0.25; 0–2 | Source aggressive heal benefit relative to damage; frozen per new battle. |
| AI Field Weight | 2; 0–10 | Provisional useful shared terrain benefit; damaging fields multiply this by 1.5. Frozen per new battle. |
| Root Progression Settings (`resources/progression_settings.tres`): Threshold Factor | 10; 1–100 | Cumulative XP threshold = factor × current level². Restart/load refreshes policy, retaining saved XP and stats. |
| Victory Base / XP Per Enemy Level / Minimum XP | 4 / 3 / 5; each 0–100 | Participating victory reward = max(minimum, base + enemy level × per level). Restart/load refreshes policy. |
| Level Cap | 55; 1–55 | Future growth ceiling; existing higher-level profiles are never downgraded. Restart/load refreshes policy. |
| HP Growth / Stat Growth | 2 / 1; each 0–10 | Species-level increments before IVs/training, including special stats. Snapshotted for new individuals; loaded individuals retain saved growth. HP gained through actual leveling preserves existing damage. |
| Unlock Levels | [4, 8, 14]; three strictly increasing levels 1–55 | Provisional first/second/rest additional species moves. Captured on first individual schedule admission, including capture. Existing saved schedules and remembered moves are preserved. |

Unlock scheduling follows explicit species pool order. Species pools and starting
move definitions remain in Move Library. Individual potential/training and explicit
authored evolution preservation are now implemented as described below; opening
quests, production evolution content and finite Seal economy remain separate.

## Combat interface presentation

The existing root Sol Visual Settings resource also drives the polished
[combat HUD](combat-polish.md). These presentation values apply to the live view,
not to saved individuals, combat rules, or generation.

| Control | Default / application |
| --- | --- |
| Health Bar Seconds | 0.3; 0–1 real seconds. Animation toward the currently presented resolution step's HP; zero snaps. Numeric HP is exact for that same step. |
| Target Previews / Preview Opacity | true / 0.5; opacity 0.1–0.8. Read-only movement routes and move-area overlays. Refresh targeting after changing preview settings. |
| Damage Preview | true. Exact direct damage and remaining HP for legal aimed attacks, using the execution calculation. |
| Impact Seconds | 0.3; 0–0.6 real seconds. Cosmetic damage/heal flash and squash; zero disables. Feedback Enabled also disables these reactions. |
| Action Cue Seconds | 0.35; 0–1 real seconds. Hold the acting Sol/move cue before revealing consequences. |
| Consequence Seconds | 0.6; 0–1.5 real seconds. Hold damage/healing/field or outcome feedback. |
| Movement Step Seconds | 0.16; 0–0.5 real seconds per displayed legal waypoint. Does not alter movement cost. |
| Turn Handoff Seconds | 0.4; 0–1 real seconds. Identify the next actor without changing initiative. |

The Battle Pacing group drives [sequenced resolution](combat-sequencing.md).
Its four durations apply when the next record starts; active holds keep their
existing duration. Values are provisional presentation tuning, never saved into
individuals. Zero holds still process records in order with command admission
gated. Invalid resources fall back at playback admission; runtime duration edits
are clamped to their ranges and nonfinite values act as zero. The battle menu
pauses the sequence. These settings do not alter status/field turn lifetimes.

## Individual stats and class buffs

`BattleSettings.sol_stats` links `resources/sol_stat_settings.tres`;
`BattleSettings.class_buffs` links `resources/class_buff_settings.tres`. Both are
typed, validated Resources. See [individual stats](sol-stats.md) and
[class buffs](class-buffs.md) for rules and migration behavior.

| Control | Default / application |
| --- | --- |
| IV Min / Max / Samples | 90 / 110 / 3 averaged samples, inclusive integer percent. Independent streams per stat; more samples concentrate rolls near the center. New individuals only; resolved IVs persist. |
| Points Per Stat / Trained Stats / Training Percent | 100 / 3 / 10%; defines full per-stat and total training budgets. Saved per individual; no separate growth-point pool. |
| First / Second Form Percent | 50 / 75; final available form always 100. Applies to earned total and per-stat caps. Saved per individual. |
| Weak Level Gap / Training Reward | 10 / 5; no training at or below the negative gap; otherwise max(1, reward + level difference). Saved per individual; requires an effective contribution to victory. |
| Retraining Items | 3; 0–99. Supplied once for a new expedition; consumed/reset count persists on load. Bag and companion controls show actual supply. |
| Class Definitions | Eighteen typed `ClassBuffDefinition` subresources: ID, name, description, inclusive min/max potency. Percentage points except Skyborne tiles and Feyborn extra turns. Resolved potency persists; edits affect new individuals. Earthbound is binary utility (0–0). |
| Kindling Cap / Verdant Healing Cap | 15 / 15 percent. Snapshot at battle preparation; accumulation/healing counters reset only for a new battle. |
| Momentum Tiles / Low Health Percent / Wyrm Health Percent | 2 cells / 50 / 75 percent. Snapshot at battle preparation. |
| Wraith Distance / Isolation Distance | 3 / 2 Manhattan cells. Snapshot at battle preparation. |
| SolMove Category / Stat / Effect | Physical or special damage category; target stat for buff/debuff; damage/heal/field/phase/quantum/anchor/buff/debuff/poison/protect. Saved movebooks retain definitions. New prototype unlocks use the same authoring path. |

Stats resolve from the saved reference profile, saved level-growth increments,
locked IVs, and training allocation. No setting rerolls an existing individual.
Allocation/reset cannot heal, run during battle, or exceed earned/stage budgets.

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

## Wilderness and image quality (October 27, 2026)

`SightingSettings.wilderness_enabled` enables persistent prototype wildlife beyond
three trail encounters. Default visibility is 28 cells. Admission happens on
expedition initialization/load and exploration steps, never camera or render
rebuilds. Wilderness home layout v1 uses one legal dry home per 16-cell sector;
existing individuals, captures, depletion and recovery retain their saved IDs.
The current Bramblepup/Seedmote roster and four affinities are provisional content,
not a completed biome ecology system. Disabling wilderness hides its local views
without deleting saved individuals. The existing 2,048-individual admission ceiling
still applies.

`View3DSettings` exposes Ambient Occlusion (on), Occlusion Radius (1.2 cells),
Occlusion Intensity (1.4), and Multisample Antialiasing (2x). Restart or call
`apply_view_settings()` to apply. Desktop rendering uses Forward+; image quality
and performance should be assessed on the target GPU. Detail Distance defaults
to 36 cells; zero follows trees to the streamed terrain horizon. Picking uses
the same cutoff. These provisional presentation defaults reduce distant small
decoration and antialiasing work without changing terrain or species identities.

`View3DSettings.chunk_work_ms` defaults to 4 ms (1–8 ms) for later streamed
chunk preparation. Reapply view settings to change it. Generation and geometry
are prepared one cell at a time, after warming cold road dependencies one region
at a time. Instance filling and picking-index preparation
yield in groups of 32; surface uploads remain atomic and can finish after the
deadline. Temporary-ground builds share this deadline and resume on later frames,
including when the camera stops. `chunks_per_frame` still caps
completed publications. Initial visible coverage and explicit rebuilds remain
synchronous. These are local presentation settings, not expedition save data.
See [runtime optimization](runtime-optimization.md) for validation and limits.

`View3DSettings.stream_ground_cache_chunks` retains up to 64 recently hidden
temporary-ground chunks by default (0-256). Zero disables retention. Reapplying
view settings applies a new limit on the next synchronization; changing terrain
source or temporary sample spacing clears retained geometry. This trades bounded
local presentation memory for less camera-reversal mesh construction and is not
saved in the expedition. Visible pending terrain receives coverage over budgeted
slices, rather than forcing every newly visible chunk into one frame.

`View3DSettings.stream_detail_cache_chunks` retains up to 32 hidden detailed
chunks by default (0–128); zero disables retention. Reapply to change capacity.
Camera reversals restore their existing geometry and prepared cells. Retained
chunks never participate in picking or traversal clearance until republished.
World rebuilds clear the cache; routine evictions spread disposal over frames.
Shared static nature meshes are merged by material for rendering while original
per-part picking and traversal bounds remain unchanged.

Hover events are coalesced to one exact scenery pick per frame; clicks still
resolve their target immediately. Shared mesh-space triangle bins skip unrelated
triangles, and nature textures are decoded before play rather than on first hover.
Companion validation reuses the existing nested-edit-aware admission cache;
ecology configuration snapshots are rebuilt only when admission revisions change.
Local-home layouts also reuse a terrain/sector/configuration cache. Crossing a
sector retains unchanged Sol models and motion tracks; combat admission processes
only newly registered identities. Explicit world rebuilds still reconstruct views.
Wild-home recovery skips already occupied homes and memoizes move-library admission;
its saved deadlines and activation rules are unchanged.

Battle Settings' Commander Run Speed now drives the player model's sideline
speed. [Combat consequences and command positions](combat-consequences.md)
supersede the earlier cosmetic nearest-exit walk: the trainer runs to the farthest
usable side, deployment waits for arrival, release range uses that actual command
position, and the old tile is free. No valid outside route/release space rejects
entry. Ordinary return retains the route when walkable; a blocked return remains
outside without deleting the imprint. Defeat retains refuge relocation.

Mechanics reference inspected at SolHunterSource commit
`115f3e87acc1716c7113523567c01e1666681885`: `src/systems/world/sol_catalog.py`
(first-stage pools and deterministic individual affinity) and
`src/systems/ai/encounters.py` (saved identity, warning and contact policy).
Godot terrain remains the home-placement authority. Sector density and the small
available roster are explicitly provisional; existing encounter rules are retained.

Additional read-only source evidence: local SolHunterSource revision
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4`,
`tests/test_entity_spawn_density.py`, `tests/test_encounter_aftermath.py`, and
`docs/coordination/encounter-persistence.md`: stable home membership, preserving
owned records, saved aftermath protection and avoiding duplicate acquisition.
These are continuity constraints, not approval of legacy generation or density.

Validation: `tools/validate.ps1` passed with Godot 4.7.2, including the new 18-check
wilderness/presentation suite and both exploration journeys. A rendered Forward+
run of `tests/full_3d.gd -- --capture-3d` passed 43 checks; camp and observation
captures are in ignored `artifacts/full3d/`. Desktop selected Direct3D 12 after
Vulkan initialization was unavailable on this machine.

## Running

Hold Shift with WASD/arrows to run; releasing Shift restores walking even during
a step. `ExpeditionSettings.run_multiplier` is provisional 1.75x (range 1–3),
applied immediately to loaded and new expeditions. Cardinal/diagonal duration,
terrain penalties, collision and per-step encounter checks use the same movement
path. Walking uses `Walking_A`; running uses `Running_A`. Menus and combat block
running. No stamina system or save-format change is introduced.

Read-only reference search at SolHunterSource revision
`d6f0902d77ed46a2f7d251c354792a4cc9210bc4` found no existing sprint/Shift/run-speed
implementation under `src/`. The modifier and provisional multiplier implement
the owner's explicit running request without adding resource costs.

## Right-click interaction menu

The context menu shares `MenuSettings` font size, background, surface, accent and
text colors (startup/restart). It uses `EncounterSettings.interaction_distance`
for selected-Sol Engage and `SightingSettings.observation_distance` for recording
selected-Sol observations. These remain Manhattan cell distances; out-of-range
Engage is visibly disabled and revalidated when invoked. No new balance sliders
or saved interaction rules are introduced. See the
[right-click behavior and research](decisions/2026-10-27-full-3d-and-controls.md#right-click-world-interaction-october-27-follow-up).

## Autonomous Sol wandering

Under **Expedition Tuning > Sighting Settings > Wandering**:

| Setting | Provisional default / range | Connected behavior |
| --- | --- | --- |
| Wander Enabled | true | Enable autonomous patrol/rest, including safe local routines after bounded near-player attention. |
| Wander Radius | 3 / 1–5 cells | Next goal's Manhattan distance from home, capped by Home Radius. |
| Patrol Goal Min Fraction | 0.5 / 0.2–1 | Minimum distance from current cell to the next goal as a fraction of effective patrol radius, rounded up. |
| Rest Min / Max Ticks | 1 / 3; each 1–64 | Duration when an arrival/expiry elects to rest; profile-scaled. Max must be at least min. Each tick is 0.75 active seconds. |
| Patrol Rest Chance | 0.35 / 0–1 | Deterministic chance to rest between goals; otherwise continue moving. |
| Blocked Goal Retry Ticks | 2 / 1–8 | Abandon a stationary patrol goal promptly. Decisions remain quantized by movement cadence. |
| Goal Timeout Ticks | 12 / 1–64 | Abandon an unreachable goal after this many active ticks. |
| Path Search Cells | 64 / 4–128 | Maximum visited cells per cardinal obstacle search. |

Existing Local Movement controls still govern decision cadence, home bounds,
reaction distances, and interpolation. Movement Radius now defaults to 28 cells
(range 4–32) so visible trail/wilderness Sols can be active before close approach.
The activity radius is Manhattan distance; visibility uses Euclidean distance.

Changes apply to loaded worlds without rerolling identity. New radii/rest durations
and timeouts apply to the next goal/rest; existing deadlines finish first. Lowering
Home Radius retires an out-of-range goal and returns the individual legally.
Disabling wandering preserves position and clears the interrupted goal on the next
decision; existing proximity reactions and return-home behavior continue. Disabling
Movement Enabled freezes all local decisions, including timers stored in their rows;
on resumption, deadlines are compared with the current exploration tick. There is
no movement catch-up. Invalid runtime settings suspend local AI. No new species,
social, weather, or relationship mechanics are introduced.

Implementation ownership: `sol_roaming_policy.gd` chooses actions/goals,
`sol_local_navigation.gd` resolves legal steps, `ExpeditionState` stores patrol
memory, and `authored_sightings.gd` orchestrates updates and presents saved state.
The original wandering delivery used domain version 11 and outer format 2.
Current AI state uses domain 14 (patrol, attention/routine and blocked-route state), expedition format 3,
and generation 6. Older outer formats/generations are rejected under the current
development policy. The five-cell saved home envelope and deadline corruption
ceiling remain engineering constraints. See the [roadmap audit](sol-behavior-roadmap.md#current-audit--october-28-2026)
for acceptance status. The [natural pass](sol-natural-movement.md) closes the
skipped-turn regression with queued legal-step replay; readability/device review
and owner movement-feel acceptance remain open.

## Mouse-first pointer presentation

Interface → Menu Settings → Pointer Highlight toggles the exploration ground
ring immediately. It is presentation-only and does not affect expedition saves.
The ring uses Menu Settings Accent at startup. Combat uses the same configured
Menu Settings theme. Input policy is documented in [UI/UX roadmap](ui-ux-roadmap.md);
full cross-screen text scaling remains phase 4.

## Live compact menu and smooth player turning

Interface → Menu Settings → Size Multiplier defaults to 0.7 (30% smaller in each
dimension), range 0.5–1.0. It multiplies the saved local menu scale rather than
rewriting preferences. Restart after editing this resource default. Options still
adjusts the relative menu scale immediately. R toggles this non-pausing menu;
Escape opens a separate pause screen. Encounter pause ownership is unchanged.

Player → Player Turn Speed Degrees defaults to 540 degrees/second, range 90–1440.
Changes apply immediately to the actual model, including its sideline walk.
Rotation follows the shortest arc and is independent of frame rate. It changes
presentation only; tile traversal, collision and saved positions remain authoritative.
The standalone window starts maximized to the available screen and remains
resizable, with a 640×400 minimum size. Physical startup-size overrides are removed;
canvas scaling expands to the screen aspect ratio. Startup display changes apply
on the next launch.

## Companion preview and interface text

Interface → Menu Settings adds Text Scale (1–2, default 1), Preview Height
(140–320 logical pixels, default 140), and Preview Framing (2–4 model diameters,
default 2.5). Options → Text size overrides Text Scale live and remembers it in
local preferences; it affects the screen-space HUD as well as personal screens. Reopen Sols
after changing preview defaults. Preview models use the existing Sol Visual Settings
palette, diameter and effects. No identity or expedition-save tuning is added.
See [Sol menu](sol-menu.md).

## Compact world inspection

Interface → Menu Settings → Inspection Width sets the collapsed strip width
(default 190, range 160–360 logical pixels at 100% text). Inspection Meter Height
sets the expanded reading bars (default 4, range 3–10 logical pixels). Both apply
immediately. The default strip shows only the subject and passability; right-click
→ Details opens readings and secondary facts. The detail card grows for larger
text, clamps within the viewport and scrolls its secondary facts. These settings
only affect presentation and do not alter expedition saves.

## Compact combat layout

Interface → Menu Settings → Combat Width sets the action-ribbon width at 100%
text (default 900, range 600–1200 logical pixels). Combat Health Width sets the
combined health-strip width (default 860, same range). Restart after editing these
resource defaults. Both layouts grow for the text preference, clamp to the current
viewport, and derive height from visible content; enlarged action content can
scroll. Secondary combat actions are under More · Esc. These are presentation
settings and do not alter tactical rules or expedition saves.

## Bounded cohesive scenery sample

Open `scenes/cohesive_world_sample.tscn` → 3D View → Nature Settings → Composition,
or `resources/nature_cohesive_sample.tres`. The optional composition selects a
seed and up to three absolute patch rectangles. Each patch exposes admitted
existing habitat IDs, density (0–40%), scene entries and fixed review clearings.
Entries expose Ground/Bank/Water, authored uniform scale, maximum horizontal
width/height in cells, terrain slope in degrees and static part/surface/triangle
admission limits. No height normalization is applied to these entries.
Composition → Orientation Marker reuses a sign on existing legal ground.
Restart/rebuild applies these cosmetic changes, including on loaded expeditions;
generation, collisions and saved identity/ecology remain unchanged. The normal
world now uses the owner-approved three bounded treatments for seed 2601026.
Other areas/seeds retain existing dressing. See [sample contract and review](cohesive-world-sample.md).


## Smaller interface text and controller defaults

Interface → Menu Settings → Base Text Multiplier defaults to **0.715**: the previous 0.65 compact
baseline increased by 10% (28.5% below authored sizes). Restart after editing this resource.
The existing 100–200% Text Size preference multiplies this smaller baseline,
including menus, inspection, combat, prompts and tooltips; repeated application
does not compound the reduction.

Interface → Controller Settings exposes deadzone, camera speed, repeat delay,
repeat interval and camera inversion. Options adjusts deadzone, camera speed,
inversion and button bindings immediately. These local preferences live in
`user://controller_preferences.cfg`, independently of expedition saves.
See [controller input](controller-input.md).

## Species catalog pilot — step two

See [species data integration](sol-species-data.md) and the
[Sol Bible](reference/sol_bible.md#pilot-production-sheets).
The connected catalog is `resources/sol_species/catalog.tres`; its three records
are shared by the battle settings and move library. Sighting settings select the
same file through Species Catalog Path, keeping the registry out of duplicated
movement tuning. All names and initial numerical values remain provisional.

| Inspector location / field | Connected effect | Application timing |
| --- | --- | --- |
| Battle Settings / Move Library > Species Catalog > Entries | Shared species taxonomy, six-stat reference profiles, lineage capacity, move pools, ecology and presentation lookup | Validate before admission; use matching catalog references |
| Catalog record > Display Name / species ID / lineage ID / class ID / ordinary form / footprint | Labels and authored identity of new individuals; class names displayed through approved metadata | Do not rename saved IDs. Test taxonomy edits in a new expedition |
| Catalog record > Reference Level / six stats / Evolution Forms | Existing individual-stat admission and training capacity | New admissions snapshot values; existing saved traits do not reroll |
| Catalog record > Learnable Moves / Starting Moves | Explicit eligible/remembered pool; first four start equipped | New movebook admissions; existing saved books retain their pool and definitions |
| Catalog record > Ecology | Existing profile/behavior hierarchy and bounded individual variation | Live decision/view configuration invalidation; existing committed legs/rests finish under current policy |
| Catalog record > Presentation Scene | Same species presentation choice in exploration, battle and preview | View reconstruction; pilots use articulated creature scenes. This does not enable unimplemented locomotion |
| Sighting Settings > Species Catalog Path | Resolves the shared resource without retaining a registry inside each movement-tuning copy | Validation at runtime; keep aligned with battle/move settings |
| Sighting Settings > Catalog Sightings | Explicit species ID, trail X and individual affinity for test/story placements | New expedition recommended; existing saved identities/affinities never relocate or reroll |

`resources/sol_pilot_sightings.tres` and `scenes/sol_species_pilot.tscn` provide the
review scenario. The ordinary expedition retains its original placements. Missing,
wrong-type, conflicting or incompatible resources reject; there are no unused
flight/swimming/procedural-animation controls in this data-only step.

## Pilot creature models - step three

See [creature models](sol-creature-models.md). Select a root under `scenes/sols/`.
Body Plan selects the species mesh builder. Model Scale controls uniform art size;
Idle Strength/Rate control breathing, attention and rest gestures. Action Seconds
controls cosmetic attack/hit recovery. These scene defaults apply when views are
rebuilt. Each control is connected; none changes saved traits or movement legality.
Affinity motes keep using shared Sol Visual Settings. Legacy orb hover, diameter
and bob do not lift or resize the pilot bodies. Procedural travel controls belong
to the next implementation step.
## Routes and ponds — generation 7

Water and bank art tuning lives in `resources/water_appearance.tres`: Deep/Shallow
Color, Wet/Dry Bank Color, Bank Blend Height (metres), Depth Color Range (metres),
Foam Depth (metres), Ripple Strength (normal-only) and Ripple Speed (clock multiplier).
These affect the actual terrain/water materials on rebuild/restart and are cosmetic,
separate from saved generation controls. See [water appearance](water-appearance.md).

World root → Expedition Tuning → Terrain Settings exposes Route Bend (0.5–1.5),
Pond Scale (0.6–1.2) and Pond Candidates (1–3). They change selected district road
bends, pond radii and maximum candidates. Conflicts can omit candidates; the
essential approach retains its admission check. These saved generation settings
apply on a new expedition. Loaded current-generation saves retain their values.
See [route and pond diversity](route-pond-diversity.md).

## Procedural creature ground motion controls

See [the ground pass](sol-procedural-ground.md) and [model creation](creating-sol-models.md).
Select a root under `scenes/sols/`: Step Distance is the distance in metres before
the next support group steps; Step Lift is swing height in metres; Turn Response
is the visual heading response in inverse seconds. Art scale applies to distances.
These scene defaults apply when model views are rebuilt; runtime validation
rejects non-finite/out-of-range values. They do not affect navigation permissions.

For independent authoring, open `scenes/sol_model_workshop.tscn`. Model Scene,
Exercise, Walk Speed and Affinity affect only that isolated test scene. Restart it
after Inspector edits. M cycles its exercises, Space pauses and R resets.

## Sol flight and swimming

See [flight/swimming](sol-flight-and-swimming.md). In a species record, Traversal
selects ground, flight or swim and exposes root altitude, maximum draft, radius,
height and maximum bank step in metres. New wild admissions snapshot this policy;
saved wild individuals retain it. Test policy edits in a fresh expedition.

Creature roots expose Wingbeat Rate and Swim Stroke Rate in cycles per second.
Those control connected procedural poses after view reconstruction, not navigation
speed or combat balance. The model workshop also offers Flight and Swimming.

Catalog sightings can select a deterministic bank placement near their Trail X
anchor, with a bounded Bank Radius. This affects explicit home admission; no
terrain is rewritten. The separate pond pilot uses this setting and a review-only
fresh start near Reedback. Ordinary expedition spawn and pilot homes stay intact.


Provisional creature art: scripts/sol_prototype_creature.gd exposes Prototype Kind
(Unassigned/Seedmote/Bramblepup/Ashkit/Rillfin) alongside the inherited model and
procedural pose settings. The shared view factory selects the kind for existing
species IDs; it does not change class, stats or movement capability. Rebuild views
after editing defaults. Gameplay no longer uses orb bodies or hovering; affinity
palette and motes still apply. See [the design handoff](sol-creature-design-handoff.md).


Menu Settings → Observe Seconds defaults to 3 real seconds (1–10); changes apply
to the next observation or unpin. The final 0.35 seconds fade out. Pin suspends
expiry. This affects presentation only and does not modify expedition saves.

View 3D Settings → Ground Clearance keeps the camera endpoint at least 0.6 cells
above terrain (0.1–3.0). Reapply view settings after editing. It does not remove
intervening hills or scenery. Owned Companion Settings → Caption Clearance adds
0.25 cells above species bounds (0.05–1.0); Routine Captions restores repeated
Following/Resting subtitles if desired. Both companion controls apply live.

The [story workshop](story-tools.md) exposes Preview Events on its root. StoryEvent
and StoryChoice resources expose IDs, prose, prerequisites and assigned facts;
edits apply on the next opening. Saved decisions retain their stable IDs. The
normal game has no automatically enabled campaign events.
