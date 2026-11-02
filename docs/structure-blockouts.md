# Procedural structure blockout objects

Object-only authoring preview: run `scenes/structure_blockout_preview.tscn`.
Rows show boulder, roots, fallen trunk, tree, then bank, ridge, broken wall, arch.
No ground, encounter, placement, collision, cover rules or powered behavior is added.

Pipeline: `structure_blockout_definition.gd` Resource -> validated seeded
`procedural_structure_blockout.gd.layout()` -> detached part records -> `build()`.
Definitions expose family, seed, scale (metres multiplier), and bounded variation.
Rebuild to apply edits. Generation version 1 and family-specific random streams
keep unrelated families independent. Rendering consumes the record and never
owns generation decisions. Stable part IDs support later asset replacement.
The preview root exposes its seed; each object can also be built independently.
No generated geometry is committed, and no third-party assets are required.

These basic shapes establish visual silhouettes only. Terrain admission and
combat integration remain separate work under the existing world/relic roadmaps.
