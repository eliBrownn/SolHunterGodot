# SolHunter Lab

First-party, project-local Godot 4.7.2 editor plugin for SolHunter. No third-party
code or assets are bundled; repository licensing applies, and the addon grants
no separate rights to game assets.

Enable **SolHunter Lab** in **Project → Project Settings → Plugins**, then choose
its main-screen tab. Select a station and **Open in Lab**. The editor hosts the
existing lab controls through an isolated runtime bridge. **Browse stations**
changes stations; **View** exposes picture quality, refresh rate and timing.
**Save & close preview** saves local work and closes the helper. **Reload source**
starts a fresh helper after a dependency change. Source preparation is cancellable;
long runtime builds close at their next safe boundary.

The Lab expands the editor workspace while active and restores the prior layout
on leaving. Focused preview input maps to the actual runtime UI and 3D viewport.
Hiding pauses processing/rendering/particles/audio; disabling closes the helper
and releases sockets/textures. A save failure retains an authoring recovery path.
Standalone scenes and the explicit standalone fallback remain available. Close
independent authoring instances before using the same draft/library storage.

The shared registry reader is `tools/lab_station_catalogue.gd`; definitions under
`stations/` supply stable IDs, scene references, execution/storage owners and
optional explicit dependencies. The 29 workstation fixtures and separate Sol
workspace share this navigation. Invalid metadata is reported without loading a
scene into the editor. Runtime authoring stays in `tools/lab_bridge_runner.gd`
and the existing fixture owners; gameplay does not depend on editor classes.

Editor preferences use ignored `.godot/editor/solhunter_lab_workspace.cfg`;
bridge workspaces use `user://workstation/editor_bridge.cfg`. Missing editor stores copy existing standalone workspace/review files once, with
provenance markers; existing editor work is never overwritten. Sol restores its
editor design/selection/camera/history through its own `editor_workspace.json`.
Existing standalone stores, Sol drafts and plant publication owners remain separate. Opening/tuning
cannot automatically publish production assets or alter expedition state.

Interactive pictures use JPEG 95%; Exact uses PNG. The 10/20 fps/on-demand choice
controls picture transport, not simulation speed or station capture fidelity.
The original station PNG capture/review functions remain available. Full Plant
Maker overview construction is still expensive; compatible presentation edits
apply in place rather than rebuilding the scene.

The enabled plugin filters lab/editor/test/tool files before Godot's bytecode
exporter so generated remaps are excluded too. The bake source used by the current
PlantLibrary signature is retained. Verify with:

```
python tools/check_lab_plugin_editor.py --export-check --godot <Godot executable>
```

This creates a disposable project/profile under `artifacts/`. Real-fixture
integration uses `tests/lab_bridge_journey.gd`; add `-- --all-stations` for the
full admission inventory. Full release/device qualification remains separate.
Status, evidence and remaining owner usability acceptance live in
[the lab plan](../../docs/development-workstation.md#current-workflow-and-l5-evidence--october-31-2026).
