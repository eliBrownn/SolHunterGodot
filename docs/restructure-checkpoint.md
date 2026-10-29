# Checkpoint before restructuring

October 28, 2026. Owner stopped feature development and requested a push of
finished work followed by a new branch for restructuring.

`codex/connected-polish` preserves the completed gameplay/source work accumulated
in the shared checkout, including exploration, creature presentation/behavior,
combat, controller support, optimization and the first story-tool increment.
This is a preservation checkpoint, not approval to merge or a final acceptance
of those systems. It includes the owner's existing roadmap deletion/renamed
working document without changing that work.

The actively edited `docs/story.md` and
`docs/reference/SolHunter_Worldbuilding_Bible.md` remain local and uncommitted.
The story-tool preview resources are development fixtures, not campaign prose.

The player GLBs, extracted texture and their import sidecars under
`assets/characters/rogue/` remain local. The supplied sky shader/cloud presets
under `assets/sky/`, and the derived `shaders/daylight_sky.gdshader` and UID,
also remain local. Their provenance records do not establish source
redistribution permission. Provenance documents are included; the nature subset
includes its verified CC0 license. No local asset was deleted or replaced.

Consequently this remote checkpoint is **not a self-contained runnable checkout**:
its player and sky references still require the withheld local packs. Resolve
redistribution permission or deliberately replace those assets before treating
the branch as a distributable build or merge-ready candidate.

Latest local evidence: Godot 4.7.2 passed 32 focused connected-polish checks and
2,506 existing 3D journey/save-load smoke checks. A final rendered writing preview
opened its embedded dialogue at 620×440 and was visually inspected. Those runs
used the local asset packs; they do not certify the asset-omitting remote tree.
The full suite and target-device acceptance were not run. Development stopped
at the owner's request; restructuring starts on a separate `codex/restructure`
branch from this checkpoint, retaining the local-only work in the checkout.
