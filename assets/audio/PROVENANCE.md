# Approved sound assets

Imported October 29, 2026 following owner approval to find and apply audio assets.
`asset_manifest.json` records exact source URLs and SHA-256 values for the audio
and particle selection. Only selected files are imported, without plugin code.

| Directory | Author / source | License | Current use |
| --- | --- | --- | --- |
| `kenney_interface` | [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds), WAV packaging by [Calinou](https://github.com/Calinou/kenney-interface-sounds/tree/4596a49eaf5a533948d49a47467f606bcdea70ff) | CC0 1.0; included LICENSE.txt | Menu open/close, healing chime, outcome confirmation |
| `kenney_rpg` | [RPG Audio by Kenney Vleugels](https://kenney.nl/assets/rpg-audio), original publisher download | CC0 1.0; included License.txt | Footstep, damage impact and cloth movement effect |
| `ambient_sounds/wind.ogg` | [Wind in a Patagonian plain by felix.blume](https://freesound.org/people/felix.blume/sounds/139337/) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | Wilds atmosphere |
| `ambient_sounds/fireplace.ogg` | [Fireplace.wav by inchadney](https://freesound.org/people/inchadney/sounds/132534/) | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | Provisional refuge soundscape; not a simulated fire mechanic |
| `ambient_sounds/forest-rain.ogg` | [Forest Rain by Corsica_S](https://freesound.org/people/Corsica_S/sounds/169031/) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) | Rain layer |

Environmental Ogg files are copied unchanged from
[AmbientSounds at 7ef9aef](https://github.com/Muges/ambientsounds/tree/7ef9aefeeed93c37bca3cdb246a982dd1afce2f0).
That distributor converted/prepared the source recordings for repeating playback;
the included readme identifies the original recordings. Original Freesound license
pages were checked at import, including the specific CC BY 4.0 rain license.
SolHunter changes playback volume and enables Ogg looping; it does not edit these
audio files. Include the author, original sound link, license link and this
adaptation notice in distributed game credits when shipping the rain recording.
Retain this provenance and the included notices with source redistribution.

## Cue selection and limitations

`resources/audio/game_audio.tres` owns assignments and initial trims. Music and
continuous foliage detail remain empty rather than repurposing unrelated sounds.
The existing sound hierarchy, zoom blend, weather intensity, pause and voice
budgets still own playback. No new triggers or mechanics were introduced.
These selections are provisional art/audio direction; a listening pass is needed
for perceived loudness, repetition and loop seams on actual speakers/headphones.

The imported payload is approximately 8.5 MB of audio plus 0.33 MB of selected
particle artwork. No file exceeds 4 MB; no LFS pattern change is needed.
