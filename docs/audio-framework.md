# Game audio framework

The cue routing and audio settings below apply to the inherited expedition. See the [map-first game](../README.md#play-the-map-first-build).

The scene's `audio_settings` selects `resources/audio/game_audio.tres`. Approved
Kenney one-shots and environmental recordings are assigned to its cue slots;
see [asset provenance](../assets/audio/PROVENANCE.md). Assign replacement
`AudioStream` assets in Godot;
unassigned slots and unknown cue requests remain silent. Restart the scene to
apply authored changes. These settings apply to both new and loaded expeditions.

## Ownership hierarchy

The scene owns one audio controller and its camera listener. The root settings
own the game mix, shared one-shot budget, fade duration and zoom endpoints.
Five categories inherit this policy: Music, Atmosphere, Details, Combat and UI.
Each category routes through the SolHunter root bus, which sends to Godot Master.
These named buses are created once when absent and reused across scene reloads.
They do not replace the project's bus layout or affect unrelated Master audio.

Cues reference one category and narrow it with a local trim at or below 0 dB.
Cues own streams, repetition, spatial playback, audible radius and cooldown.
They cannot override category routing, the shared budget or zoom volume policy.
Duplicate keys, unsupported categories, invalid ranges and positional continuous
beds reject the settings and fall back to a silent default policy.

Audio remains in `scripts/presentation/`. `game_audio.gd` owns playback and
preferences; `expedition_audio.gd` adapts existing game events and context.
Neither modifies expedition state or introduces gameplay rules. World-generation
and mechanics authorities remain with their existing owners.

## Camera listening and zoom

An active `AudioListener3D` is a child of the actual game camera. Positional
footsteps and combat effects therefore respond to camera distance and orbit.
Emitters remain aligned when the terrain presentation rebases its origin.

The camera distance also controls an inherited smooth mix. At the close endpoint
(provisional default 8 cells), Details has full category gain and Atmosphere uses
its close gain (35%). At the wide endpoint (35 cells), Atmosphere has full gain
and Details uses its wide gain (15%). In between, both blend smoothly. Positional
attenuation applies in addition to this mix. Category and root volume preferences
always apply; zoom never overrides mute. Music, Combat and UI do not inherit this
zoom blend. Continuous foliage detail is a close environmental bed, not a claim
that leaf collisions or vegetation interaction mechanics have been implemented.

## Connected cue slots

| Slots | Existing owner / trigger |
| --- | --- |
| `music_exploration`, `music_combat` | Battle controller's active session |
| `ambience_refuge`, `ambience_wilds` | Terrain's existing camp classification |
| `weather_rain` | Atmosphere controller's blended rain strength, including intensity |
| `foliage_detail` | Continuous Details bed, reduced at wide zoom |
| `footstep` | Completed player grid step, positioned in the existing world |
| `combat_damage`, `combat_heal`, `combat_effect` | Visible battle playback cue kind; optional other `combat_<kind>` slots can be authored |
| `combat_outcome` | Battle playback outcome step |
| `ui_open`, `ui_close` | Existing live field menu visibility |

Continuous music, environment, foliage and rain use four independent layers.
Each layer holds at most an incoming and outgoing player during a crossfade.
The root admits only these four layers, bounding continuous playback at eight
players in addition to the shared one-shot budget.
Loops should be enabled on the supplied stream/import for seamless playback;
completion also restarts a repeating cue. One-shots release on completion and
are dropped if the root budget is full. Cooldown is shared per cue. No random
audio selection touches world-generation randomness.

The existing true exploration pause holds beds and clears one-shots. The live
field menu leaves audio running. Active battles retain audio while their
controller owns the paused exploration state. State replacement clears old
one-shots; current context selects new beds on the next presentation update.
Scene destruction releases its players and listener. Named category buses remain
available for the next scene.

## Local controls and verification

Field menu → Options provides Master and five category volume sliders. Zero
mutes. Changes apply immediately and are remembered in
`user://audio_preferences.cfg`, separately from expedition saves. Invalid
preference values are ignored or clamped. Writes are delayed briefly while
sliders move and flushed on scene exit when pending.

`tests/audio_framework.gd` checks silent defaults, validation, hierarchy routing,
zoom/mute, shared voice admission, cooldown, emitter rebasing, crossfades,
rain-level inheritance, pause/resume, completion cleanup, preference restoration,
camera-listener ownership, Options integration and unchanged expedition state.
Transport fixtures push no audio buffers; assigned production streams are
checked for nonempty decoded duration before the isolated transport fixtures run.
Use existing field-menu, atmosphere, battle-sequencing and 3D journey suites for
the connected owners. The October 29 asset pass supplies menu, footstep, combat, refuge/wilds ambience
and rain streams with conservative per-cue trims. Music and foliage detail remain
unassigned. Audible balancing and seamless-loop acceptance remain owner review;
automated transport checks cannot establish sound quality.

October 29, 2026 local validation with Godot 4.7.2 stable: clean editor import;
audio framework 47 checks, field menu 37, atmosphere 33, combat sequencing 39,
and the solid 3D smoke journey 2,506, all with zero failures and no script/engine
errors. The atmosphere suite's deliberate invalid-setting warning is expected.
The rendered Options screen was inspected in `artifacts/audio-options.png`.
Ownership validation found 146 mapped scripts/UIDs and no failures. Logs are
under `artifacts/audio-*.log`. These are focused checks, not a full local run of
`tools/validate.ps1`; the new audio suite is also registered in that CI entry point.

Owner follow-up, October 29, 2026: footstep audio is disabled pending the owner's
request to revisit it. The `footstep` cue has no assigned stream; its hook and
licensed source asset remain available for later restoration.

## October 29 licensed asset integration

Owner-approved asset import adds ten assigned cues and four selected particle
textures. The audio manifest records 18 source-file hashes, verified after import.
Godot 4.7.2 editor import and the 47-check audio framework suite passed without
engine/script errors. The existing rendered affinity-effects suite passed 14
checks; battle and exploration captures under `artifacts/orbs/` were inspected.
Use Direct3D 12 on this machine; automatic Vulkan probing emits startup errors
before falling back to Direct3D. This is focused asset integration validation,
not a full-suite pass or an audible-quality acceptance.
