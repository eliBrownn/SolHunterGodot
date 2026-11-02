# Development workstation

## Godot development lab plugin plan — October 31, 2026

Status: implementation has reached L5 engineering closure. L0–L4 are delivered;
owner usability acceptance remains open. The phase evidence and limits below
distinguish implemented behavior from owner sign-off.
This section owns the lab improvement sequence. The dated usage and validation
sections below describe existing behavior, not completion of this plan.
[PROJECT_STANDARD.md](PROJECT_STANDARD.md) owns workflow and hierarchy rules;
[the development plan](development-plan.md#unified-development-lab--october-31-2026)
links this work without replacing the nature expedition delivery sequence.

### Outcome and scope

Deliver a project-local **SolHunter Lab** main-screen editor plugin under
`addons/solhunter_lab/`, enabled through Godot's Project Settings → Plugins.
The editor workspace becomes the primary development/review entry point, with
one menu beside an isolated preview. This is a SolHunter-specific tool using
this project's resources, not a generic plugin or Asset Library release.

Refine the whole lab: make it faster, smaller in responsibility, easier to
navigate and automatically aligned with the systems it previews. All lab actions
belong in one consistent menu. Remove duplicate controls and competing panels
while preserving useful authoring, inspection, comparison and review functions.
This is a complete interface and ownership pass, not just a new station picker.

Use the game's top-down ownership principle: **lab → domain → station → preview
components**. Keep separate concerns connected through explicit references.
Share production builders, definitions and owner interfaces; keep lab scenarios,
drafts and synthetic supplies separate from production state and canon.

Sol Lab belongs in the same menu/navigation and common action patterns. Its
standalone scene, authoring owner and saved drafts remain separate; unify access
and presentation without requiring its simulation or persistence to merge with
Development Lab. Preserve standalone launch. The later October 31 owner decision
removes F8/F9 and lab buttons from normal gameplay; retain world-toggle fixtures
only as isolated test adapters, without reinstalling them in the main game.
The [Sol Lab plan](sol-lab.md) continues to own its authoring features.

### Godot plugin architecture and layout

Target the repository's pinned Godot 4.7.2 stable; do not change the engine pin
as part of this conversion. The editor shell, station definitions and isolated
runtime bridge are implemented. Keep shared development-tool owners outside
editor-only code; no new runtime game hierarchy is introduced.

| Path | Responsibility |
| --- | --- |
| `addons/solhunter_lab/plugin.cfg` | Project-local plugin identity, version and entry script |
| `addons/solhunter_lab/plugin.gd` | Thin `@tool EditorPlugin`: register/show/hide/free the Lab workspace and connect editor services |
| `addons/solhunter_lab/editor/` | Main-screen Control scene, single menu, preview host, editor persistence and authoring integration |
| `addons/solhunter_lab/stations/` | Lightweight station definitions and editor adapters, grouped by demonstrated domains |
| `tools/lab_station_catalogue.gd`, `lab_bridge_wire.gd`, `lab_bridge_runner.gd`, `lab_bridge_storage.gd` | Shared registry, bounded protocol and runtime adapter; no editor-class dependency |
| Existing `scenes/`, `tools/`, `scripts/` and `resources/` | Reused fixture entry points, production builders and authoritative definitions; move only with a verified consumer/UID migration |

Do not move production owners into `addons/` or make gameplay depend on
`EditorPlugin`, `EditorInterface` or editor-only classes. Extract shared lab
behavior only when both hosts need it; keep the plugin entry script small.
Record first-party provenance/license information with the adopted addon.

Follow Godot's [main-screen plugin lifecycle](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/making_main_screen_plugins.html):
create the panel in `_enter_tree()`, attach it to
`EditorInterface.get_editor_main_screen()`, expose `_has_main_screen()` and
`_get_plugin_name()`, and route visibility through `_make_visible()`.
Hide the workspace on initial registration. Hiding suspends its simulation and
rendering; disabling/reloading disconnects signals, cancels pending work, flushes
local drafts and frees only plugin-owned nodes. Re-enabling must not duplicate
panels, handlers or station instances. Never pause the editor's SceneTree or
change its global time scale to pause a preview.

#### Preview execution boundary

Every station declares an execution mode and required dependencies. Audit the
full script/resource chain before admitting an in-editor preview:

- **Editor preview:** a plugin-owned SubViewport with its own World3D, camera,
  environment and local simulation clock. Use tool-compatible adapters/builders
  and isolated resource copies. It must not attach to or modify the edited scene,
  call expedition save/load, depend on gameplay autoload side effects, or claim
  the editor's global input/audio listener. Route input only while its viewport
  has focus and bound audio through an explicit preview owner.
- **Runtime fixture:** launch the existing standalone scene in a separate game
  process for stations requiring runtime-only scripts, physics or gameplay
  services. The menu shows launch/running/stopped/error status and explains which
  controls are available only in that fixture. Standalone launch remains supported;
  the implemented versioned bridge exposes the existing runtime controls in the
  editor. New adapters must pass the same lifecycle/input/persistence checks.
  Do not imply that a runtime scene becomes interactive inside the plugin merely
  because its PackedScene can be loaded.

Godot's [tool-script execution rules](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html)
apply to instantiated script dependencies. Do not blanket-add `@tool` to runtime
systems. Prefer safe pure builders or narrow adapters; retain runtime execution
when that boundary cannot yet be proved. The Plant Maker proof must establish
this boundary before committing to in-editor hosting for other stations.

#### Editor authoring and storage

Preview edits operate on detached drafts, including nested mutable Resources;
ResourceLoader's cached production instances must not become writable preview
state. Keep local layout/selection in project-local editor metadata and retain
versioned appearance drafts, notes and captures in their existing local stores.
Inventory exact existing paths/schema before introducing an editor store. Import
compatible workspaces by copy with a migration marker; retain originals and
report unresolved values. Editor and runtime hosts must not concurrently write
the same draft file; use explicit handoff or separate sessions.

Use a lab-local undo stack for isolated tuning. An explicit **Save draft** saves
locally; a separate explicit production authoring action identifies destination,
changes and overwrite scope. For supported editor resource/scene edits use
Godot's [EditorPlugin undo/redo integration](https://docs.godotengine.org/en/stable/classes/class_editorplugin.html#class-editorplugin-method-get-undo-redo).
Disk writes need their own reviewed save/overwrite handling; do not promise that
editor undo reverses arbitrary file writes. Preserve existing plant selection
and publication gates. Plugin startup, discovery and dependency refresh never
publish a draft. Notify the editor filesystem after deliberate asset writes.

Use editor filesystem/resource notifications to invalidate the one station
catalogue and affected dependencies, coalescing import bursts. Keep layout state
separate from authored content and review evidence. Do not register editor UI
as a runtime autoload or change `run/main_scene`. Verify a normal game launch
with the plugin disabled and exclude editor-only implementation from release
exports after checking the runtime dependency graph.

### Diagnosis and measurement limits

The October 31 read-only inspection found these concrete sources of work:

- `tools/development_workstation.gd`: shared parameter application reloads the
  entire fixture; scene loading/instantiation is synchronous. Restoring saved
  selectors emits their handlers, which can trigger additional setup.
- `tools/lab_station_tools.gd`: control wording scans run every 0.25 seconds;
  selected-object bounds and selection geometry refresh every 0.2 seconds.
- The host renders its SubViewport continuously and saves workspace settings
  every two seconds. Plant previews update shader parameters each frame; the
  procedural plant fixture enables shadows and 4× MSAA.
- Historical `artifacts/plant-anatomy/report.json` records 4,769.226 ms to build
  24 specimens with 615,298 total vertices. It used the compatibility renderer
  and recorded zero host frame time, so it is build-cost evidence only.

The owner reports slow opening, tuning, navigation and animation. No live
profile was taken in this investigation. These paths are verified work, not a
measured ranking of current bottlenecks. Do not present the historical capture
as current Plant Maker FPS or assume UI scans dominate rendering.

### Ownership and module contracts

| Level | Owns | Boundary |
| --- | --- | --- |
| Editor plugin entry | Godot registration, visibility, editor notifications and teardown | Delegates lab behavior; no production or station rules |
| Lab shell | Single menu, station lifecycle, action routing, shared view/review services, aggregate work budgets | Wires modules; contains no plant/combat/terrain-specific simulation rules |
| Domain | Shared scenario setup, preview defaults and constraints for related stations | Add a domain layer only when it owns demonstrated shared behavior |
| Station definition and adapter | Stable ID, domain, title/help, scene reference, parameter bindings, scenarios, capabilities, dependency references and contract version | Describes supported behavior without teaching the shell station names |
| Preview components | Existing production builders/resources and bounded test-specific presentation | Production owners retain mechanics, generation and state authority |

Definitions also declare execution mode, editor compatibility and storage owner.
Discover them in the agreed station-definition directory through one catalogue;
use the same catalogue in standalone hosts where applicable rather than keeping
the existing hard-coded `FIXTURES` table as a second authority.
Navigation metadata must be readable without instantiating every scene. Optional
capabilities cover selection, camera framing, readings, replay, custom controls
and captures. Unsupported capabilities stay unavailable with a useful reason;
avoid guessing support from station names. Extend existing station hooks where
useful instead of introducing a universal framework or a second registry owner.

Each parameter has one stable key, label, scope, source binding, valid range,
default, help and update effect. Classify effects as presentation, simulation,
geometry or whole scenario. Identity/geometry changes invalidate their actual
dependents; color, camera and UI changes must not reroll unrelated geometry.

### One menu and a simpler interaction model

Use one collapsible panel beside the preview. Inside it, browse/search domains
and stations, then show the selected station/object and its relevant actions.
Keep location and back navigation visible. Tune, View, Compare, Speed and Review
are sections of this same menu, not separate overlapping windows. Put common
actions in one consistent location; shortcuts invoke those same actions.

Inventory every existing control before migration. Give each function one home;
merge duplicates, remove obsolete controls and explain any removed capability.
Fixtures contribute controls through the shared menu, rather than retaining a
second hosted toolbar. Standalone fixtures can reuse the same control descriptions.
Preserve gameplay-preview input through its owner rather than copying gameplay
rules into lab buttons. File/overwrite confirmations may use a focused dialog.

Show common controls first and disclose advanced groups as needed. Use plain
labels, short contextual help, meaningful defaults, visible values, numeric
sliders/knobs, boolean switches and discrete selectors. Keep exact number entry
as a secondary option. Distinguish reset value, reset group and restart scenario;
show their scope. Keep undo and draft/dirty status understandable.

Preserve compatible selection, camera, notes, menu location and scroll position
when navigating. Keep the preview usable at normal and compact window sizes,
with keyboard focus and readable disabled/loading/error states. Apply the same
navigation/action conventions to Sol Lab without exposing implementation terms.

### Responsiveness and bounded work

Apply parameter effects to the smallest affected owner. Batch restoration into
one transaction with signals suppressed until a single required refresh. A
slider updates its displayed value while dragging; expensive work applies on
release and superseded rebuild requests are coalesced or cancelled.

Cache reusable geometry by relevant recipe/dependency inputs with explicit size
and eviction bounds. Instantiate only the active station; release inactive GPU
and scene work according to measured budgets. Retain drafts independently of
scene lifetime. Use threaded resource loading where supported; keep scene-tree
and rendering operations on their required thread and budget incremental setup.
Show progress and keep navigation responsive during long preparation.

Replace polling with invalidation/events where possible: refresh control text
when controls change, bounds when geometry/transforms change and workspace saves
when data is dirty. Debounce disk writes and flush on deliberate transitions.
Animate/render continuously only when the station needs it; static previews
refresh on change. Hidden workspaces must not continue costly rendering or
simulation. Any preview quality preset is explicit and recorded in comparisons;
do not conceal a performance regression by silently reducing fidelity.

### Automatic discovery, synchronization and drift checks

1. Discover registered lightweight station definitions through one catalogue
   owner. A valid definition supplies its menu entry automatically; no central
   picker, purpose-description or capability switch needs a new station branch.
2. Bind controls to authoritative production resources/interfaces. Preview edits
   use isolated overrides; reset reads current production defaults. Discover
   newly exposed supported parameters through their bindings and metadata.
   New semantic scenarios still need an authored adapter; discovery cannot invent
   a useful preview or approve experimental mechanics.
3. Track explicit/transitive dependencies and contract versions. Refresh affected
   open previews at a safe boundary on supported resource change signals or
   reload; handle source/scene changes requiring restart clearly. Batch refreshes
   and preserve compatible overrides. Do not rebuild every station every frame.
4. Version drafts and reviews by stable station/parameter keys. Validate stored
   values against current bindings, retain unresolved values recoverably and
   explain incompatible settings. Mark affected screenshots, measurements and
   accepted local reviews stale when inputs change; preserve original evidence.
5. Validate discovery, unique IDs, scene references, adapters, declared dependencies
   and parameter bindings through the existing validation workflow. For features
   declared reviewable, require a station reference or explicit deferred reason.
   Run affected checks from dependencies, with broader checks for shared changes.

Automatic means discovery, dependency refresh and drift detection during lab use
and validation. It does not mean scheduled autonomous code changes, publishing
tuning, overwriting user drafts or changing production resources without an
explicit authoring action. Declare the source snapshot when live refresh is
unsupported rather than pretending the station is current.

### Delivery sequence and acceptance

The implementation uses the versioned runtime bridge permitted by this plan.
L0–L4 have implementation and validation evidence below; L5 is at the owner
usability-review gate. Keep this as the single lab status/evidence index.

| Phase | Deliverable | Exit evidence |
| --- | --- | --- |
| L0 — Baseline and editor feasibility | Inventory existing controls, dependency/storage owners and runtime-only assumptions; classify station execution modes | Reproducible Plant Maker, grass/Vastra and gameplay-preview costs; tool-compatibility audit; exact draft paths and known failures |
| L1 — Plugin shell and menu | Add addon registration, main-screen workspace, one menu/action map, isolated viewport and lifecycle handling | Enable → open → hide → disable → re-enable journey; normal/compact layouts; no duplicate nodes, global pause or edited-scene mutation |
| L2 — Plant Maker proof | Implement one editor-safe adapter, shared controls, selective updates, undo, draft persistence and dependency refresh | Rendered discover → tune → undo → compare → save/reopen journey; resource isolation, paired costs and no unrelated geometry reroll; retain runtime launch until parity |
| L3 — Shared domains and runtime launch | Migrate grass/Vastra, rendering benches and remaining fixtures by declared execution mode; integrate Sol Lab access | Capability-driven shell; useful runtime launch/status/return; separate Sol drafts and standalone journeys preserved; normal gameplay remains lab-free |
| L4 — Discovery and editor synchronization | Catalogue rescan, dependency invalidation, import/reload handling, draft compatibility and focused drift checks | New definition appears without shell edits; only dependents refresh; import bursts coalesce; stale/incompatible input reports clearly; reload retains drafts |
| L5 — Closure and adoption | Remove superseded hosted UI/code only after replacement parity; reconcile usage, ownership map and export boundary | Complete action inventory, plugin-disabled game smoke, editor-only export exclusion, warranted integration evidence and owner usability review |

At L0, record engine, renderer, revision/dirty inputs, hardware, viewport,
scenario, quality, warm/cold state and active background work. Measure repeated
opening, switching and parameter changes; collect idle and animated median/p95
frame times and separate CPU/GPU evidence where available. Establish numerical
budgets from this baseline before judging improvement; no invented FPS pass mark.
Record plugin/editor overhead separately from standalone runtime costs. Repeat
equivalent scenarios, viewport sizes and quality settings; editor FPS alone is
not a production performance claim.

Reuse the existing workstation, review journey, world-toggle, visual-station and
feature suites as relevant. Use disposable workspace paths for validation so
personal drafts and production assets remain untouched. Exercise cancellation,
failed station loading, stale review restoration and compact-menu navigation.
Run shared integration checks when lifecycle/persistence boundaries change.
Add focused plugin lifecycle, catalogue and detached-resource checks during
implementation to the existing validation entry point without weakening CI.
Import/headless checks alone do not prove editor UI behavior: exercise the actual
main-screen workspace, focus/input, disable/reload and draft recovery in Godot.
Documentation-only planning does not require a game-suite rerun.

Final acceptance requires all actions reachable through one menu; no duplicate
hosted fixture panels; understandable first-use and repeat-use journeys; measured
responsiveness within the recorded budgets; preserved drafts/reviews and
expedition isolation with lab-free normal startup; automatic station discovery and dependency drift detection;
and no change to production mechanics or data authority. Runtime-mode stations
must clearly disclose their separate window; L5 cannot claim one-menu tuning
parity for them without an implemented bridge or completed editor adapter.
Until that parity is accepted, keep the corresponding standalone controls.
The editor plugin is the target; the dated instructions below remain the current
runtime-lab usage until their replacements actually ship. Keep device/export
qualification separate from local desktop evidence.

### Current workflow and L5 evidence — October 31, 2026

Enable **SolHunter Lab** in Project Settings → Plugins (enabled in this project),
then choose its main-screen tab. Search/select a station and choose **Open in Lab**.
The editor expands the Lab workspace and restores the previous editor layout when
leaving it. Browse switches stations; the active lab has one control panel with
its existing Tune/Settings, View, Compare, Speed and Review functions. Sol authoring
retains its own Shape/Explore/Review sections and document owner. The controls
shown in the editor are the actual runtime controls, not a second set of guessed
parameter bindings. Standalone scenes and **Open standalone** remain available.

`tools/lab_station_catalogue.gd` is the single registry reader. The 29 original
workstation fixtures and Sol authoring are registered through lightweight JSON
under `addons/solhunter_lab/stations/`; one additional entry provides the explicit
standalone workstation fallback. The former `FIXTURES` dictionary is now a derived
compatibility view, and purpose text comes from the same definitions. Adding a
valid definition adds navigation without shell branches. Host/execution mode,
scene/key agreement, IDs, versions and declared dependency references are checked.

The editor-only client displays a runtime-owned SubViewport through a versioned,
token-authenticated loopback connection. `tools/lab_bridge_runner.gd` owns one
active host/fixture and reuses the existing builders, game services and authoring
handlers. The helper's native window stays hidden. The editor forwards input only
from its focused preview, with aspect/letterbox coordinate mapping; focus loss
releases held input. Dialogs/subwindows remain embedded in that runtime viewport.
No gameplay script is blanket-converted to `@tool`, and no preview enters the
edited scene or expedition. TCP framing has bounded queues/packet sizes and
incremental reads/writes, including packets larger than a socket buffer.

Dependency hashing runs on a file-only worker so browsing stays responsive.
Requests coalesce; Cancel opening cancels preparation or closes the runtime at
its next safe boundary, preserving local work. Hiding the workspace disables
runtime scene processing, viewport rendering, particle clocks and audio playback.
Disabling/reloading the plugin closes its connection and saves the runtime
workspace; a save failure keeps the authoring owner available for recovery.
Sockets and preview textures belong to the workspace lifetime, which avoids the
native shutdown crash found with globally retained bridge objects.

**Storage and authoring:** editor layout/selection/preview preferences use the
local ignored `.godot/editor/solhunter_lab_workspace.cfg`. The runtime workspace
uses `user://workstation/editor_bridge.cfg`, with its matching review store and
existing capture directory. Standalone `workspace.cfg`/`reviews.cfg` are preserved. On first use, missing
editor stores import copies of those files and write `.migration.json` provenance
markers; existing editor work is never overwritten. Explicit test paths do not
import personal workspaces.
Sol documents remain under `user://sol_lab`; the Sol owner also saves its editor
session (design, selection, camera, tab and up to 128 restart undo frames) in
`editor_workspace.json`. Domain navigation retains full in-memory history; an
incompatible session is preserved and new work uses a recovery sidecar.
Plant revisions/manifests remain
under `res://resources/plants` or `user://authored_plants`. Sol dirty documents
are saved through their existing owner before a domain switch/close. Production
publication still requires the existing explicit authoring/visual selection
workflow; opening, tuning, discovery and drift checks cannot publish anything.
Close independent standalone authoring instances before using the same library.

**Selective updates:** Plant Maker applies parameter batches in place. Wind,
event preview and review visibility do not rebuild meshes. Geometry/color recipes
rebuild station samples with their stable seeds; camera/control ownership survives.
Undo uses the same parameter owner. Compatible selection and wireframe/normal
inspection survive geometry edits and undo. Restore reconciles Plant Maker controls in
one silent transaction. Its recipe cache is bounded to 24 entries/200,000 vertices
and is released with the fixture. Full overview geometry work can still be costly;
the cache is particularly useful for focused specimens. Workspace writes are
input/dirty-driven and debounced, replacing unconditional two-second writes.
Control wording refreshes on invalidation rather than a 0.25-second whole-panel
scan; selection geometry refreshes only when its signature/readings need it.

**Drift and recovery:** fingerprints include station metadata, shared adapter
code, inherited/literal resource references, asset files and UID/import sidecars.
Dynamic dependencies must be declared in the station's `dependencies` list.
The running adapter retains its loaded snapshot; changed source is marked stale,
and Reload source saves work and launches a fresh process rather than pretending
cached scripts hot-reloaded. Only the active dependent preview is affected.
Unsupported saved fields/types/ranges and old control layouts remain recoverable
in `unresolved_settings`/`unresolved_controls`. Original review pictures/decisions
are preserved; incompatible reviews display a source-change/recheck notice.

**Review picture modes:** Interactive uses JPEG at 95%; Exact uses PNG. The
10/20 fps/on-demand selector controls editor picture transport, not simulation
speed or station render quality. Station captures retain their original PNG
path and renderer settings. These choices are visible and saved locally. The
rolling runtime timing display includes startup/edits and is not a steady-state
per-station GPU measurement.

| Phase | Delivered evidence | Remaining acceptance |
| --- | --- | --- |
| L0 | Source/ownership/storage inventory; paired full-reload/selective Plant Maker measurements; rendered grass, Vastra and gameplay-preview journeys | Desktop evidence only; no device/GPU budget claim |
| L1 | Real editor enable/show/hide/disable/re-enable, cancellation, focused input and compact layout checks; clean native process exit | Owner usability selection |
| L2 | Real Plant Maker tune → undo → baseline → switch → return → save/close; fixture/geometry identity retained on presentation edits | Owner visual/usability selection |
| L3 | All 30 registered stations admitted through the rendered bridge; screenshots and control inventory; separate Sol persistence and standalone paths retained | Concurrent new unregistered fixtures are outside this frozen migration scope |
| L4 | 4 MB fragmented-packet regression; invalid/duplicate metadata, inherited dependency drift, source-stale/fresh-process reload, saved-value admission and recovery checks | Dynamic dependencies need authored declarations; source reload is explicit |
| L5 | Duplicated registry/purpose ownership removed; workflow/tuning docs reconciled; focused regression, normal-game isolation and actual pack exclusion verified | Owner usability sign-off, followed by ordinary review/merge; no automatic merge |

The action inventory follows existing owners rather than inventing a framework:

| Functions | Owner / editor home |
| --- | --- |
| Station browse/search, loading, cancellation, source reload, lifecycle | Plugin shell and shared catalogue |
| Exported sliders, switches, selectors, presets, reset/undo and restart | Workstation plus station hooks / Settings |
| Selection, framing/orbit, labels, wireframe/normals and rulers | `lab_station_tools.gd` / View |
| Pause, single frame, repeat/time and before/after comparison | Workstation and `lab_review_tools.gd` / shared actions and Compare |
| Notes, captures, saved reviews, change notes and measurements | Existing review owner / Review and Speed |
| Plant forms, species constraints and append-only save/publish | Plant Maker/store and production builders / plant controls |
| Sol anatomy, visual core, locks, variations, gallery, undo and drafts | Sol document/body/panel owners / Sol authoring sections |

Rendered admission saved 25 additional station control inventories plus the five
core journeys under `artifacts/lab-phase-review/`. The standalone structure and
stone-obstacle previews added by concurrent feature work are explicitly deferred
from this original 30-station migration until their own admission validation;
they remain available through their standalone scenes. The continuing plant HTML
review gallery and its owner-selection/publication gates remain authoritative.

#### Measurements and reproducible checks

`tools/profile_lab_workflow.gd` compares the former full-fixture application path
with selective application, using the same 24-specimen seed-73 overview, 1280×800,
Godot 4.7.2, Forward+/D3D12, Ryzen 7 5800XT and RTX 3070. Three warm edits each:
full reload median **21,411.920 ms**, p95 **21,636.929 ms**; selective application
median **123.233 ms**, p95 **126.184 ms**. Cold construction was **23,330.319 ms**.
The 120-frame animated/paused samples were median **16.666 ms** with p95
**16.691 / 16.681 ms**, at a 60 fps cap. These are local desktop observations,
not uncapped throughput, isolated GPU timings or Thor acceptance; other editor/game
work may be active. Inputs/settings and all samples are in `baseline.json`.

The local presentation-edit gate is no fixture/mesh replacement and median apply
below 5% of the recorded full-reload median (1,070.596 ms). The 123.233 ms result
passes with large margin. Full overview opening retains a loading state and is
still expensive; do not claim that the 23-second cold path was eliminated or hide
it by reducing specimen count/fidelity. Later captures measured roughly 13–21 ms
for core JPEG readback/encoding; these single samples are not a transport SLA.

Evidence index (generated local artifacts, not a second roadmap):

- `artifacts/lab-baseline.log` and `artifacts/lab-phase-review/baseline.json`:
  paired performance evidence and its exact context.
- `artifacts/lab-all-stations.log`: 30-station rendered admission, zero failures;
  station pictures/control inventories remain under `lab-phase-review/`.
- `artifacts/lab-bridge-closure.log`: final real-fixture journey, zero failures;
  includes selective edit/undo, comparison, suspended rendering and safe close.
- `artifacts/lab-editor-final-review.log`: actual isolated editor lifecycle,
  cancellation, pointer mapping, source drift/reload, clean exit and binary-script
  pack exclusion; its printed project directory contains normal/compact images.
- `artifacts/lab-final-*.log` and `artifacts/lab-final2-*.log`: focused catalogue,
  protocol, workstation, review (84 checks), Sol Lab (36), Sol authoring (382) and
  retained world isolation (32) checks. The final `artifacts/lab-closure-*.log`
  batch passes catalogue, workstation, protocol/storage migration, Sol-session
  recovery and plant selection/inspection retention checks. The protocol test
  requires loopback access. `artifacts/lab-final-import.log` records the final
  project import/parse pass. `tools/validate.ps1` includes the new
  headless plugin/protocol, Sol-session and selective-update suites without removing
  existing CI checks.

Reproduce the editor/pack check with
`python tools/check_lab_plugin_editor.py --export-check --godot <engine>` and the
rendered journey with Godot's `--script tests/lab_bridge_journey.gd` (add
`-- --all-stations` for the full admission inventory). Use disposable profiles.
The editor exporter must remain enabled for its lab exclusions. It runs before
Godot's GDScript exporter so neither source nor generated bytecode/remap files
leak into the pack; runtime sentinel preservation is checked in a mounted pack.
The retained plant bake source remains excluded from broad tool removal because
PlantLibrary hashes it. The final repository ownership audit passes with 209
mapped scripts, 209 UIDs and zero failures. Concurrent scenery ownership entries
were reconciled by their separate work; those scripts were left untouched here.
The full game suite was not rerun.
This focused pack boundary is not qualification of a
full release export, redistribution rights or the target device.


## Review workspace rollout — October 30, 2026

### Creative additions — October 30, 2026

Use **Creative additions** in the lab's top bar to browse proposed new content.
The same entries appear under **Browse** and in the station picker. This section
reuses Settings, View, Compare and Review; saved drafts stay local to the lab.

The first entry, **Creative additions / relics**, shows seven original procedural
families. Choose the original trio or focus a marker, arch, foundation, split ring,
spire circle, courtyard or sanctum. Adjust the concentration, signed condition and response
strength sliders; toggle purpose labels. High concentration and disruption can
coexist. Compare the healthy, disrupted and restorative treatments and save feedback.

Procedural follow-up: **New design** advances the seed while retaining other
settings. **Design seed**, **Structure scale**, **Missing stonework** and **Rubble
pieces** control reproducible variations. A shared visual builder generates tapered,
chamfered stones, segmented arches and foundation courses. Separate structure,
breakage, surface and rubble streams keep dressing changes from rerolling the
parent layout. Changing Vastra conditions does not alter that layout. Seeds and
tuning save in the existing local station draft. World spawning remains planned.
The procedural journey verifies reproducibility, seed variation, independent
dressing/conditions, finite bounded geometry, outward normals and New design.
Godot 4.7.2 import, the rendered journey and the 185-script ownership audit passed.
Current procedural logs are `artifacts/relic-procedural-import.log` and
`artifacts/relic-procedural-render.log`; two seeded designs were visually reviewed.

**Send Vastra in** sends a finite packet from each visible relic's external test
supply through its mapped crevice veins to the shared node core. **Run purpose /
output** spends reserve on the selected purpose; automatic output is adjustable.
Markers default to clue reveal, arches to a relay receiver, and foundations to
layout reveal. Purpose can be selected independently of silhouette. Arrival, not
departure, completes each effect. **Reset test supply** explicitly restarts the
lab circuit. Rebuilding/switching a fixture also resets its test energy.

**Stone material** selects Black stone, Abyssal stone or Ash-black stone using the owner's
selected ambientCG Rock051 surface, with authored color/normal/roughness/AO/metalness
maps. **Ancient node carving** selects Square seal, Diamond seal or Narrow seal.
These preserve the logical Core/InputPort/OutputPort contract, while cutting the
visible node into its owning stone. Etch-outs have perpendicular 90-degree sidewalls
and flat bottoms cut into the stone, not attached tubes or strips. A masked light
pass on that same mesh confines the Vastra response to the recesses. Physical frames,
port collars, the central orb and in-world IN/OUT/readout labels have been removed.
Channels follow seeded fracture routes projected onto stone surfaces; this is not an
automatic mesh-crevice mapper. Readings include source, reserve, travelling energy,
receiver output and spent energy. Housing/material changes cannot reroll geometry.

This is a bounded lab simulation, with no expedition harvesting, ecological writes,
save migration, repair or production rewards. The
[relic plan](relic-roadmap.md) retains the production integration sequence.
Review status does not approve test costs or adopt these examples into the game.
The expanded node journey covers seven families, three material/carving styles,
fixed ports, mapped route endpoints, finite supply, no early credit, purpose sinks,
exactly-once arrival, reset, and the real intake button. Node/material source maps
and the scene/script ownership map are checked separately. Current node logs are
`artifacts/relic-nodes-import.log` and `artifacts/relic-nodes-render.log`; screenshots
include `relic-node-style-*.png`, `relic-node-output-*.png` and
`relic-reference-family-*.png` under `artifacts/`.

Ancient-stone revision: `scripts/scenery/relic_carving.gd` projects the routes onto
admitted stone surfaces and cuts bounded, square-bottomed grooves and seal recesses into those
meshes. Rubble remains independent. Prepared meshes have a bounded 12-layout cache;
condition/energy changes update presentation without recarving. Authored normal maps
still provide fine stone relief. `tests/relic_concept_preview.gd` verifies actual
inward vertex displacement and absence of attached channel/housing geometry alongside
the prior energy checks. Final logs: `artifacts/relic-carving-render.log` and
`artifacts/relic-carving-import.log`; the native viewport close-up is
`artifacts/relic-ancient-stone.png`. This is focused lab validation.

Black-stone and range follow-up: the current generation version is 5. **Missing
stonework: intact → skeletal** spans 0–2; **Stone courses / layers** spans 2–12;
**Uneven break variation** spans 0–1. Seeded breaks remove upper courses before
lower support, with independent heights across walls, monoliths and spires. Arch
spring stones follow their surviving supports. Rubble remains independent and the
shared geometry ceiling is 160 pieces. **Square-cut etch depth (m)** spans 0.04–0.12.
Bottom faces of thin slabs are protected from a second excavation. Try the intact,
uneven-courses and skeletal presets alongside the four environmental presets.
Black-tinted Rock051, cooler fixture lighting and reduced neutral Vastra brightness
establish the ominous presentation without new gameplay effects. The focused
geometry/energy journey verifies perpendicular wall normals and constant-depth
floors; rendered range/close-up evidence and logs are under `artifacts/relic-square-*`.
Run `tests/relic_concept_preview.gd` for the section/filter, fixture, tuning,
independent-condition and draft-retention journey; a rendered run also writes
normal/compact-window captures under `artifacts/relic-*.png`.

Validation: Godot 4.7.2 import completed without engine/script errors; the existing
workstation journey and the Direct3D 12 relic journey both reported zero failures.
Normal 1600×1000 and compact 1100×720 captures were inspected. Logs are
`artifacts/relic-import.log`, `artifacts/relic-workstation.log` and
`artifacts/relic-render.log`. This is focused lab validation, not a full game pass.

The lab is a shared place to try a change, compare it, and save the result.
It keeps test data separate from the expedition and does not write production tuning.

### Start here

1. Choose a test using **Browse**. Favorites and recent tests appear first.
2. Open **Try a test** in Settings and choose a starting scenario.
3. Use **View** to pick an object and **Move closer**, or click it in the scene.
4. In **Compare**, take a **before picture**, change a setting, and drag the
   comparison slider or the picture divider. Before is on the left; now is on the right.
5. In **Review**, name the experiment, record what happened and the next change,
   choose **Needs changes**, **Ready to check** or **Accepted**, then **Save review**.

### What each tab does

| Tab | Use it for |
| --- | --- |
| Settings | Guided tests, grouped sliders, exact number entry, single-value/group resets, undo, and saved settings with rename/delete |
| View | Object selection, size/readings, turn/pan/zoom, front/side/above views, whole-scene or selected-object framing, names/tips, metre ruler, mesh edges, surface direction, and energy endpoints where present |
| Compare | Before pictures, changed settings, matching camera, optional known-time replay, and a draggable before/now divider |
| Review | Named experiments, status, next action, saved pictures, clean captures, full-window captures and concrete change notes |
| Speed | A two-second warm-up plus at least five seconds of frame samples; average, slow-frame estimate and sample count |

Right-drag turns the camera, middle-drag moves it, and the wheel zooms. These
shared controls work while paused. Turn off **Click objects to select them** to
use a gameplay-backed preview's original click interactions. **Show on-screen tips**
also reveals those previews' runtime game interface; game menus retain their
original behavior and are not dismantled into lab controls.

Static art panels and station tuning controls are docked beside the preview,
including rendering benches, plants, forests, terrain, Vessels and Sol workshops.
Extra captions move to **View → Test info**. The underlying standalone scenes keep
their original interfaces. Custom Vastra docking remains supported.

### Repeatable tests and honest comparisons

Grass offers strong-wind, night and four-habitat tests. Vastra offers a known
single-transfer test and quiet/busy background energy. Rendering benches include
low sun, fog, calm/stronger water, clear/blocked targets and light/heavy particle
loads. Plant and animation stations have focused starting tests. Other previews
restart their existing defaults with a review prompt.

**Start this test** deliberately resets the current test settings and prepares the
scenario. The panel then folds away so tuning remains easy to reach. Grass and
Vastra can restart the same setup and advance their existing root simulation in
fixed 1/60-second steps to a chosen 0–10 second test time. A guided transfer repeats
its existing send action. No independent particle speed or invented ecological rule
is introduced. Other stations explain that they can restart but cannot reproduce
an exact simulation time. GPU rendering and shader TIME are not deterministic replay.

Before/now comparisons flag changes in camera, viewport size and settings. A
recorded picture can show a different animation time. The saved camera includes
projection, field of view and size as well as position/orientation. Object framing
uses visual bounds; it is an inspection aid, not gameplay picking or terrain admission.

Speed results include the whole host window rather than isolated GPU time. Changing
the camera, controls, viewport, pause state or station interrupts a measurement.
These results do not qualify target-device performance.

### Local storage and implementation handoff

Workspace preferences and per-station drafts save every two seconds to
`user://workstation/workspace.cfg`. Saved settings save immediately. Switching
stations retains each station's setup, notes, supported camera and draft review.

**Save review** writes `user://workstation/reviews.cfg` and review pictures under
`user://workstation/reviews/`. A review contains its question/observation notes,
settings, camera, before picture, current picture, review state and next change.
**Open review** restores those settings and pictures; the live simulation starts
again. The stored current picture remains available even when exact simulation
replay is unsupported. Saving a copy creates a separate record. A session-only
before picture becomes durable when its review is saved.

**Take picture** saves a preview PNG and JSON report under `user://workstation/`;
**Take full-screen picture** includes the lab interface. **Hide names and tips in
pictures** temporarily hides scene labels and view helpers and restores them after
capture. Reports record that choice. Baseline and saved-review captures support it.

**Write change note** writes a concrete local Markdown handoff with proposed setting
changes, live controls, observations and known source references. It uses the last
saved review, so save after editing its notes or settings. **Accepted** is a local
review state; it does not approve canon, update resource files, or apply values to
the game. Lab-only test reserves and optical settings must never be copied as
production mechanics. Changes to actual game settings remain separate reviewable
repository work.

### Ownership and integration

`tools/development_workstation.gd` owns layout, playback, parameters, comparison
reports and workspace preferences. `tools/lab_station_tools.gd` owns the hosted
panel adapter, common camera, visual bounds selection and reversible view helpers.
`tools/lab_review_tools.gd` owns guided tasks, known-time test stepping, the divider,
review records and change notes. Fixtures retain their simulation/presentation owners.

Custom stations may expose `workstation_parameter_info(key)`,
`workstation_dock_controls(host)` and `workstation_readings()`. Other stations use
the shared adapter without modifying their standalone scenes. Live control records
use stable names derived from control purpose/options, frozen on first use, plus
a station-script revision guard. The workspace revision is now `workspace-3`;
older live-control snapshots are skipped rather than applied to a changed layout.
Exported settings remain checked against the current fixture's supported properties.

Mesh-edge and surface-direction modes use temporary per-instance material overrides;
they do not edit source materials. They show base geometry and can omit the original
shader's vertex deformation. Selection bounds and endpoint markers are lab helpers,
not gameplay targets. Common camera control does not replace gameplay movement.

### Validation and reproduction

Run the pinned Godot 4.7.2 engine with:

- `--headless --path . --script tests/development_workstation.gd`
- `--headless --path . --script tests/lab_review_journey.gd`
- `--headless --path . --script tests/grass_blade_preview.gd`
- `--headless --path . --script tests/development_world_toggle.gd`

`tools/review_lab_upgrade.gd` renders desktop/1100×720 views, selection, mesh-edge and
surface-direction modes, the divider and named review UI. It verifies paired preview
capture and actual before-image/library reopening. It uses a separate artifact
workspace, not personal saved lab settings. Images/logs are under
`artifacts/development-workstation/upgraded-*` and `review-*.log`.

Verified with Godot 4.7.2: editor import passed with no engine/script errors;
the all-25-station journey passed 83 checks. A later focused journey passed 72
checks, including refreshed selection after changing biome pages. Workstation and
grass suites passed, the expedition round trip passed all 18 checks, and the
rendered review verified its saved images and reopened library. The short-window
render shows all five tabs without scrolling the tab strip. Logs are the
`review-*` files in the above artifact directory.

The full gameplay suite was not rerun for this development-UI change.

## Procedural plants

Choose **Plants / biomes & Vastra anatomy** for one proposed sample per
biome/role/class combination: 24 total across Meadow, Woodland, Heath and Marsh.
Use the biome and role selectors to compare a habitat, a role across habitats,
the full grid or one specimen. **See inside the plant** reveals connected
conducting tissue, storage and exchange surfaces; organ annotations appear for
individual samples. Sliders reshape anatomy and outer growth. Launch with
`-- --plant-anatomy`. These are static anatomy proposals, without live energy
transactions or newly approved species/abilities.

The revised samples have distinct habitat growth structures: meadow fans,
woodland divided fronds, thorned heath cushions and marsh pitchers/stilts/ribbons.
The sidebar now groups 24 numeric controls, with help on parameter labels.
**Reset shape controls** restores the shape defaults. **Silhouette view** compares
plant outlines on a pale backdrop; selecting a role across all biomes places
its four samples side by side. Biome-specific controls identify their scope.

Choose **Plants / procedural forms** for the October 30 morphology proof: eight
growth forms with three seeded variants each, generated using existing painted
leaf/flower/bark textures and authored bark/ground normal maps. Select a form for
close review; right-drag to orbit and scroll to zoom. Sidebar sliders adjust seed,
branch count, plant/leaf size, foliage, curl and wind. **New seed variations**
rebuilds the specimens. Launch with `-- --plant-prototype` to select this fixture.
See [procedural plants](procedural-plants.md) for scope, checklist and validation.
This is an isolated art study; species and production rollout remain open.

## Standalone access and retained switch tests

Owner direction, October 31: labs have been removed from the main game. Normal
startup has no Development/Sol Lab footer buttons or F8/F9 lab handlers. All lab
code and standalone scenes remain. Open `scenes/development_workstation.tscn` or
`scenes/sol_lab.tscn` directly with F6; see [Sol Lab](sol-lab.md) for its workflow.

The former in-game switch remains in `tools/development_world_toggle.gd` for
explicit isolated tests. Its tests install the adapter themselves; normal startup
does not reference it. The following suspension contract describes that retained
test adapter, not current main-game access.

The expedition stays in memory with its clock, movement, input, GPU particles,
audio and HUD suspended while the lab is open. Returning restores its previous
processing/visibility/audio state, including an already-open pause screen. No
expedition save/load or regeneration is used to switch worlds. The lab instance,
selected fixture, parameter changes, notes and lab pause choice survive visits
until the game closes. The lab has its own World3D, and gameplay-backed fixtures
retain their existing save/load block. Hosted fixtures do not create nested world
switches. This does not adopt experimental lab effects into production Vastra.

`tools/development_world_toggle.gd` owns the temporary switch. The workstation's
mixed indentation errors are corrected so it loads under the pinned Godot version.
Run `tests/development_world_toggle.gd` for isolation/round-trip checks; add
`-- --capture-lab-world` with Direct3D 12 for an actual toggle-world screenshot.


Open `scenes/development_workstation.tscn` and press F6. This is the single
development entry point; the game keeps its normal main scene. Existing lab,
preview and workshop scenes are reusable fixtures inside its isolated viewport.
Use the selector to switch between particles, vessels, forest looks, biome assets,
landforms, cohesive world, creature exercises and gameplay pilots. Only one fixture
runs at a time. Grass uses grouped shared controls; Vastra docks its live controls
outside the preview. Other art stations use the shared panel adapter; runtime game menus retain their original interactions.

The lab uses the normal field menu's shared theme and `resources/menu_settings.tres`
palette. The fixture toolbar wraps, and the review sidebar scrolls on shorter
windows. Boolean parameters use switches; ranged numeric parameters use labeled sliders
that apply on release. Other scalar parameters accept Enter or Apply to rebuild. Restart retains applied settings, camera, notes and baseline. The visual review script `tools/review_workstation.gd` writes a preview
to `artifacts/development-workstation/preview.png`.

UI polish validation: Godot 4.7.2 import passed; the workstation suite passed
with zero failures and the expedition/lab round trip passed all 18 checks.
The shared-theme layout and paired capture were inspected using the OpenGL
compatibility renderer. The full game suite was not rerun for this UI change.

Pause stops the fixture subtree and GPU particle speed; Step advances one host
frame and pauses again. This is a visual frame step, not a deterministic physics
replay. Shader TIME effects can keep animating while node processing is paused.
Restart reconstructs the current fixture, retaining its setup.
Switching stations preserves each station's setup, notes and session baseline. Scalar exported parameters are editable
in the sidebar and applied by rebuilding; range hints clamp numeric input.
Resource parameters remain available in the fixture's Godot Inspector.

Record expected behavior, observed behavior and the next change in Test Notes.
Take before picture records the image and numerical/context report. Copy test details includes
notes, fixture variables, live slider/preset/toggle values, camera transform,
elapsed test time and viewport dimensions. The baseline appears in subsequent
reports. Host frame mean is wall frame time, including editor/render overhead,
not an isolated GPU benchmark. Draw calls and object counts are viewport readings.

Take picture saves a paired PNG and JSON report under `user://workstation/`.
The sidebar shows the absolute path. Share that pair for visual discussion; the
JSON records context rather than promising a complete replay of arbitrary fixtures.
Reports and captures are local development artifacts, not gameplay saves.
Gameplay-backed pilots block expedition save/load while hosted here; normal game
save/load stays unchanged. Story preview still creates its own artifact directory.

Validation: run Godot headless with `--path . --script tests/development_workstation.gd`.
For visual review, run the workstation, adjust a particle preset, pause, annotate,
capture, switch to a creature exercise, then reset and resume.

Temporary-world validation: Godot 4.7.2 editor import passed; the standalone
workstation suite passed; the real Direct3D 12 toggle journey passed **18 checks**,
including frozen expedition state, particle/audio restoration, retained lab tuning
and notes, hosted save blocking and no nested switches. The actual lab view was
inspected at `artifacts/development-world/lab.png`. Full-suite validation was not
run for this temporary world entry.

## Additional visual stations

Eight more selector entries support focused review:

| Station | Useful comparisons and controls |
| --- | --- |
| Lighting / shadows | Sun angle, energy, ambient fill, fog, shadow opacity, warm/neutral tint; shared cube, sphere, tree and rock references |
| Materials / response grid | Fifteen identical spheres across roughness and metallic values; rotate the light under identical conditions |
| Water / depth and foam | Actual game water shader on a known 0–1 m depth ramp; tune ripple speed/strength, foam width and color depth |
| Readability / scale and occlusion | Same 1.8 m silhouette at three depths; adjust foreground blocker position/height, target brightness, FOV and viewing distance |
| Particles / density and overdraw | Fixed-seed 128–8192 transparent particles; tune size/opacity and compare host frame metrics with a baseline |
| Animation / slope and actions | Rattlehorn on the existing slope route; clickable signature/attack/hit and movement-speed controls |
| Animation / flight | Sailcrest takeoff/flight/landing through the existing workshop traversal contract |
| Animation / swimming | Rimefold in the existing workshop swimming fixture |

New benches support right-drag orbit and wheel zoom. Their controls change only
the current fixture, and reset restores defaults. Reports include station-specific
readings via `workstation_readings()`, including live values and animation identity.
Lighting presets are an art rig, not a replacement weather simulation. Particle
counts are a synthetic visual load, not a target-device performance qualification.
The readability targets are calibration silhouettes, not gameplay targeting logic.
Water depth values are an authored test mask rather than generated river geometry.

Run `tests/visual_stations.gd` for the new stations' focused validation.

## Single-blade grass prototype

Choose **Grass / single blades** in the lab selector. Four side-by-side patches
compare meadow, woodland, heath and marsh. Each instance is one tapered,
seven-triangle blade. Right-drag orbits; the wheel zooms. Sidebar sliders
control blades per square metre, blade height/width/curve, wind strength and wind
direction; releasing a slider rebuilds while retaining other applied values. Density and
size inherit provisional biome multipliers. Pause freezes the wind clock.

This isolated art fixture consumes the existing meadow shader through private
materials. It does not change production grass, weather, generation or Vastra.
Production rollout must use existing terrain admission and canonical cell flora
endpoints; visual blade counts must never multiply cell reserves. Lab samples
have no expedition or ecological ledger.

Launch directly selected with `scenes/development_workstation.tscn -- --grass-prototype`.
`tools/review_grass_blades.gd` captures the lab and a paired settings report under
`artifacts/grass-prototype/`; `-- --keep-open` leaves that review window open.
Focused validation: `tests/grass_blade_preview.gd`.

Owner review, October 30, 2026: approved the four-biome single-blade grass
prototype as an acceptable starting point. Preserve the individual-blade approach
and usable slider controls as the basis for further refinement. This approval
covers the lab prototype; production rollout, final biome styling and tuning
remain unfinished. The prototype remains isolated from expedition ecology.

### Grass with Vastra comparison — October 30, 2026

**Grass / single blades** now uses an isolated `ExpeditionState` and the existing
`PlantVastra` transactions. This supersedes the earlier arbitrary patch-local
paths. Four illustrated grass cells and four visible tree receivers have explicit
cell IDs and root/crown anchors. All blades in a patch share its one reserve.
Every visible packet comes from `flora_transfers()`, with matching source/target
IDs, authoritative send/arrival ticks and an endpoint belonging to its actual
receiver. Tree-root returns land at the grass roots; plant emissions land at the
receiving tree. No transfer means no transfer particle. Live labels show reserves
and root stock; the HUD reports stored/in-transit energy and conservation error.

Fixture cells, display spacing and initial test reserves are authored lab data.
They demonstrate the existing generic plant cycle without an expedition,
generated-world catalogue, classified specialist ecology or Sol-feeding subjects.
They do not prove those other recipients have visual coverage. Production
admission, ecology and save rules are unchanged. Optical settings never choose
recipients or amounts. The simulation-speed slider advances the whole isolated
clock (including wind and transactions); it cannot independently speed up a
particle's arrival. The height slider controls the optical path arc, keeping the
source and receiver endpoints fixed. Night/visibility switches remain cosmetic.

Sliders expose visibility, path arc height, thickness, filament count and shared
simulation speed alongside the approved grass controls. Pause freezes both
transaction time and GPU particles. The shared Vastra lab noise helper is static
so this fixture can reuse it without creating unused UI. Focused tests prove
source/target identity, root/crown endpoint selection, real root-return packets,
visibility independence and conserved state through arrivals and repeated sends.

Live rollout, October 30, 2026: the approved blade mesh and four-biome styling now
ship in the normal game through `MeadowArt`. Production and lab share
`grass_blade_mesh.gd`; lab controls and seeded reserves remain isolated. This
supersedes the earlier note that production rollout was unfinished. Old grass
clumps are retired from live palettes/rendering. See
[the rollout record](reviewed-world-visuals.md#single-blade-grass-rollout--october-30-2026).

Plant suite cleanup (October 30): **Plants / maker & library** starts with
**All biomes · side by side** and **All plant forms**, showing 24 editable previews.
The **All biomes · all plants** button returns to this overview from a saved/focused
selection. Shared sliders affect the visible designs; select one biome and form
before saving an individual asset. Save buttons disable in overview, and the store
rejects ambiguous multi-specimen saves before writing. Prior saved selections are
preserved when revisiting a session. The anatomy comparison station also defaults
to all biomes. Earlier procedural forms remain a reference station.

Size class, biome/role locks and cutaway have one visible control each; their
redundant generic Inspector-derived controls are hidden in the shared dock.
Randomize, size presets and library load rebuild the specimen in place, preserving
the editor controls rather than destroying their fixture during a button callback.
The full maker flow now passes 34 checks, including default overview, focused
saving, recipe restoration, seeded randomization and unlock behavior.

Comparative scale: the plant editor shows a world-unit height ruler and a neutral
1.8-unit standing figure by default. All visible samples use the same unit scale;
the all-forms overview uses each form's Small/Medium/Large game-height preset,
so a tree is not normalized to the same height as a ground plant. Focusing a form
restores its custom dimensions (or class defaults on first selection). Select a
single biome/form for a closer framed view. `show_scale_reference` can hide the
ruler/figure for extreme closeups; `reference_height` changes the reference figure.
Both belong to **Scale comparison**. Scale markers are viewer-owned and excluded
from saved plant meshes, gameplay geometry, flora membership and reserves.

Biome scene viewer and visual balance (October 30): **Biome scenes** is the default
layout, with each biome's tree and five ground-plant forms sharing a ground patch
at comparative scale. **Plant grid** restores individual specimen plots. Viewer
arrangement is an art comparison, not a replacement for generated-cell placement.
With the reference visible, the maker uses an orthographic camera so foreground
plants are not enlarged by perspective. The reference ruler aligns with tree
root depth and remains outside saved plant assets.

Trees now have connected secondary structural forks, with adjustable
`tree_fork_depth`, `tree_fork_spread` and `trunk_lean`. Forks taper toward smaller
children; foliage remains attached to their tips. Meadow crowns spread, Woodland
forks rise, Heath keeps its jointed form and Marsh keeps lower stilt roots with
shorter drooping curtains. Crown fullness and sparse woodland/heath Emanator
foliage were increased moderately. Anatomical plant materials reduce palette gain
from 1.4 to 1.1 to retain softer leaf/flower color and stem contrast. Existing
fullness, density, color and branch controls still apply. These are visual changes;
no reserves, circulation rules or generation membership change.


Official plant editing (October 30): open **Plants → Maker & library**, choose an
entry under **Official species presets**, then **Load official baseline**. The
45 presets load as independent copies with bounded visible sliders and a saved
individual seed. Randomize stays in that species; **Customize freely as new
design** opens the full range. Save uses the existing library workflow. Four
unassigned Receiver forms remain draft-only. See [procedural plants](procedural-plants.md)
for the identity and export contracts.
