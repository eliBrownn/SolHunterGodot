# Vastra particle lab

Branch note: the standalone lab remains isolated, while the main-game particle
renderer is enabled separately on this branch. See [in-game integration](vastra-particles-game.md).

Isolated visual experiment requested October 29, 2026. Open
`scenes/vastra_particle_lab.tscn` in Godot 4.7.2 and press **F6** (Run Current Scene).
The main game does not load this scene. No expedition, ecology, weather, save or
Vessel implementation is modified or accessed.

The lab borrows the Vessel study's GPU head-and-fading-wake approach. Its own
motion and draw shaders explore landscape-scale currents rather than orb flight.
The stage uses five actual nature assets: ground foliage, flowers, two trees and
a flowering shrub. Their energy readings remain synthetic art fixtures.

## Visual target and interaction acceptance

Owner clarification, October 29, 2026: the current in-game Vastra appearance is
nearly the intended final look and is the reference for this experiment. The
purpose of trying particles is to retain that appearance while testing physical
presentation interaction with a moving player. The glowing head/wake studies
are exploratory renderings, not an approved new Vastra art direction.

Preserve the main game's soft refractive air, irregular fine filaments, flowing
mist and restrained lighting. Compare particle variants with that reference;
do not treat brighter orb trails or a different overall silhouette as success.
Production Vastra stays unchanged until separate adoption approval.

Particles alone do not establish physical interaction. The lab's current
character toggle is instantaneous analytic displacement; it is not a collision
or persistent wake demonstration. Next acceptance is a controllable character
parting/carrying the mist, local curls and a wake that survives passage and
settles over time, with height separation and pause/reset behavior. Use the
already approved mist-flow scope in the visual roadmap: presentation response,
without movement resistance, damage or changes to ecological energy. Adoption
requires both owner visual approval and a convincing moving interaction test.

## Plant nodes and transfers

Use the **Plant interactions** menu, choose **From** and **To**, then press
**Send / play interaction**. Each plant has a name and reserve reading; tree
labels also show root storage. The event readout shows dispatch and arrival,
plus stored-and-in-transit energy. The configured energy moves as a packet of
GPU heads and fading wakes between attachment points on the actual assets.

| Interaction | What to test |
| --- | --- |
| Single transfer | Ground plant or tree sends to a different tree. |
| Tree relay | A sends to the selected source tree; after arrival, that tree sends to the target tree. |
| Two plants converge | A and B send independently to the selected receiving tree. |
| Full tree → root overflow | The receiver starts full; its arriving energy appears in root storage. |
| Roots → nearby plant | A tree starts with root stock and sends a low path to a ground plant with room. |

**Transfer energy** and **Travel speed** apply on the next send. **Arc height**,
**Path width**, trail length, size, glow and colors can be changed during flight.
Root returns use a low 0.08-cell arc. Source/destination changes reset the node
fixture; **Reset nodes** restores its starting reserves. **Reset motion** resets
both ambient motion and plant transactions. Pause freezes both.

The reserve capacity of 100 and initial stocks are lab fixtures. Dispatch debits
the sender once, transit retains that amount, arrival credits the receiver, and
full trees retain overflow in roots. Empty sources and full root-return receivers
block a transfer without losing energy. A relay waits for arrival before emitting.
No automatic absorption, repair, recipient selection, feeding or living-world
simulation runs here. User-chosen endpoints and arbitrary packet amounts are
manual animation probes, not replacement production rules. Existing behavior is
referenced in `scripts/sols/plant_vastra.gd` and the roadmap's plant-transfer evidence.

**Clear view · isolate interaction** hides all plant models, the ground, the
character and ambient particles, leaving only the participating node markers,
readings and transfer particles. Toggle it off to restore the scene and previous
ambient visibility. This also works while paused or mid-transfer. The copied
parameter snapshot includes clear-view state.

Turn **Show ambient field** off to isolate the moving packet. Turn it back on to
compare the transfer against each ambient state. **Copy all test parameters**
copies a versioned JSON snapshot of field/interaction settings and endpoint names;
paste it into chat with feedback. It does not save or load a game or restore a
mid-flight simulation. Main-game and Vessel presentation remain separate.

## Filament appearance study

The default **In-game look · filament particles** replaces the circular head
sprites with elongated camera-facing fibers aligned to each GPU path tangent.
Overlapping particle histories create thin strands, with soft ends, layered dust,
refractive background offsets and complementary optical fringes. The noise volume
uses the same seed/construction as the production current material; the particle
fragment is an approximation of its folds/filaments, not a claim of pixel identity.
Emission defaults to zero, matching the restrained production direction.

Landscape currents now follow four stable connections between the actual plant
ports. Circulation/vortex remain optional synthetic pattern tests. The ambient
budget defaults to 128 heads to avoid turning the strands into a dense rope.
Manual packet transfers use the same filament rendering and retain their arrival
accounting. **Earlier glowing trail comparison** restores the prior sprite style.

**Filament length** (world cells) and **Refraction** (screen UV offset) apply live;
**Particle size** controls cross-flow thickness in filament mode. **Neutral field
optics** uses the current material's neutral blue/copper primary/complement
approach without assigning a new affinity. The eight palette choices remain.
The copied parameter snapshot includes appearance, pool budget and these controls.

Rendered field and clear-view comparisons are recorded at
`artifacts/vastra-particle-lab/filament-field.png` and `filament-clear.png`.
These establish a reviewable visual approximation only. Persistent physical
interaction remains unproven; the main game rendering is unchanged.

## Ambient controls

- **1–6 / state menu:** low energy, ambient, rich/healthy, restorative, disturbed,
  all-affinity storm. Switching states resets motion to the same seed and time.
- **Pattern:** landscape currents, grove circulation or rising vortex. Patterns
  can be combined with every state.
- **Affinity:** eight existing palette colors or all affinities together.
- **Sliders:** concentration/coverage, independent signed overload, speed,
  turbulence, particle size, opacity, glow, trail length and field height.
  Changes apply immediately in this lab; no settings are saved. Scroll down
  past the plant controls to reach the ambient settings.
- **Character disturbance:** show a scale capsule and part particles around it.
  Enable walking to test passage through the field. This is instantaneous
  visual displacement, not a persistent mist/wake solver or gameplay behavior.
- **Night lighting:** compare visibility against a darker environment.
- **Space:** pause/resume motion. **R:** reset motion while keeping controls.
- **Right-drag:** orbit. **Wheel:** zoom. The control panel scrolls on small windows.

Concentration only changes optical coverage; rich/healthy is explicitly neutral
overload. Signed overload is a proposed visual turbulence input, independent of
concentration. Storm is an all-affinity visual sample, not a simulated disaster
or automatic positive overload. The Bible's existing distinction remains intact;
these samples establish no new mechanics or adopted animation states.

Root Inspector exports set the maximum head count (128), history samples (10)
and field radius (4 cells) before running. The default pool has 1,408 sprites;
the concentration slider controls its visible fraction. Head count is a rendering
budget, not a measure of ecological energy. The lab uses analytic GPU paths;
there is no terrain collision, gameplay integration or production performance claim.

## Focused verification

Rendered in Godot 4.7.2 with Direct3D 12. Exercised all six presets, all three
patterns, all nine color choices, concentration zero, both overload extremes,
pause/resume and reset; inspected the actual rendered panel and particle field.
The plant-node extension passed **295 focused checks** in
`tests/vastra_particle_lab.gd`: all five interactions, energy accounting during
travel, delayed credit, relay arrival order, overflow, full-receiver rejection,
pause and reset. The Direct3D 12 capture was visually inspected at
`artifacts/vastra-particle-lab/plant-transfers.png`. Run it with
`--script tests/vastra_particle_lab.gd -- --capture` for a fresh render.
No full suite requested or run. The earlier project-wide import reported the existing
`@export_file` comma errors in `scripts/scenery/vegetation_appearance.gd`; the
standalone lab does not depend on that script and runs independently.

### Reduced bristle appearance

Owner feedback: the first filament pass was too furry. The revised default uses
128 ambient heads and eight heads per manual packet, 1.1-cell filament length,
narrower cross sections, one dominant optical fiber and much less haze. Paths
share a gentle bend instead of independently fanning short hairs. Default path
width is 0.06 cells. Field and isolated rendered captures were inspected after
this visual-only tuning; no new full-suite run was needed.

### Curved filaments

Each particle now uses a 24-segment strip. Every vertex samples the same shared
path function as the GPU particle simulation, so an individual filament follows
the actual arc/bend rather than drawing a straight tangent-aligned streak.
Ambient and transfer paths share `vastra_particle_lab_paths.gdshaderinc` with the
draw shader. Arc height and path width still apply live to manual transfers;
filament length controls the span sampled along that curve. Endpoints clamp to
the selected path instead of extending beyond a plant or crossing a wrap seam.
The additional strip geometry is a lab experiment, not a production budget claim.

## Owner baseline, send pulse and reliable export

The owner-requested baseline was read directly from the open lab window on
October 29 and stored in `resources/vastra_particle_lab_baseline.json`. It is
loaded at startup and restored with **Restore your baseline**. The captured
values are authoritative for this lab only; new pulse/visibility sliders retain
their provisional defaults because they were not present in that window.

The observed baseline includes Single transfer with C → B selected. That exact
selection is preserved; sending from a tree to flowers requires the **Roots →
nearby plant** interaction, whose reset supplies root stock and receiver room.
The visual baseline is not permission to change production recipient rules.

Opacity now reaches zero. **Ambient visibility** and **Transfer visibility**
also independently range from zero to one. Zero means no optical fragments,
including refraction, while transfer accounting continues. **Send pulse strength**
and **Send pulse seconds** control a dispatch-triggered width/visibility surge
that decays down the moving packet, rather than introducing a new glowing orb.
Sending/arrival label cues remain available even when the optical effect is hidden.

Clipboard failure was reproduced: Windows returned Unable to open clipboard,
while the old button incorrectly announced success. Export now always opens
selectable JSON text and saves `artifacts/vastra-particle-lab/latest-settings.json`.
The **Copy again** action checks clipboard readback and reports failure honestly.
The displayed text and saved file are the fallback; the file can be read directly
in this chat. The synthetic verification export uses `copy-smoke.json` so it does
not overwrite an owner's latest saved settings.
