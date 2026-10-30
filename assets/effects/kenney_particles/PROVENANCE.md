# Kenney particle selection

Source: [Kenney Particle Pack, Godot Asset Library](https://godotengine.org/asset-library/asset/784).
Author: Kenney (Kenney.nl). License: CC0 1.0, included in LICENSE.txt.
Copied unchanged from [Calinou's packaging at ab708663](https://github.com/Calinou/kenney-particle-pack/tree/ab7086639ee73be31abd87feb21bf1402d4e8144)
on October 29, 2026 with owner approval. Source URLs and hashes are recorded in
`assets/audio/asset_manifest.json` alongside the companion audio import.

`spark_01.png` is the default Sol affinity-mote artwork. The existing individual
affinity palette supplies its tint and the existing mote count/animation owns its
budget. Texture resolution is compensated to preserve its world-space footprint.
Clear `SolVisualSettings.effect_texture` to restore the original pixel patterns.
`light_01.png` now supplies the bounded Vastra peak-mote layer. Its existing
per-strand phase and tier control placement and size; `current_particle_limit`
controls the global visible budget. `magic_01.png` and `smoke_01.png` remain a
retained selection for subsequent effects authoring.
