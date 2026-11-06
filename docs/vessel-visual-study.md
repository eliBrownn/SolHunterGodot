# Woodland Vessel visual study

This is an isolated study of Vessel appearance. Its visuals are separate from the map-first storm field test. See the [map-first game](../README.md#play-the-map-first-build).

Owner-directed art test, October 29, 2026. Latest direction replaces the insect
concept with small glowing orbs and fading trails, entirely through particles.
Retain fluid three-axis flight and the anger-dependent light distortion test.
No new lifecycle, energy or ecological rule is established.

Run `scenes/vessel_preview.tscn` with F6. Keys 1/2/3 show one orb, 128 orbs or
2,048 orbs. Drag to orbit, wheel to zoom, Space holds the visual clock, N switches
lighting, A cycles preview anger in 25% steps and R resets the selected view.
The on-screen Anger and Maximum color separation sliders update immediately.
The meter reports the applied per-channel offset in screen pixels:
maximum separation multiplied by anger squared. Zero anger gives zero separation;
0.5 anger with a 4 px maximum gives 1 px red/blue offsets in opposite directions.
The meter spans the full 0–24 px tuning range. Values survive view switches but
are not saved between sessions.
The preview starts at 50% anger and 12 px maximum separation, making the applied
3 px separation visible immediately. The orb floats above the reference rock.
Close inspection uses a 6 cm flight radius; other views use 10 cm. Controls are
temporary and do not access expedition state.

`vessel_particle_swarm.gd` is one GPUParticles3D emitter with two shared
two-triangle billboard passes. Each Vessel uses one bright head and ten progressively smaller,
fainter wake particles: 11, 1,408 or 22,528 total particles in the three views.
The GPU process shader samples the same seeded curved path at successively older
times. This reconstructs a short visual wake without per-member CPU history or
nodes. It is not a physical smoke simulation. Wake duration defaults to 0.65 s.
A 3,600-second pool lifetime is only an engine reuse interval, not biology; the
index-based path stays continuous on reuse. A fixed AABB includes spawn spread,
flight and halo padding. The process shader uses the shared preview clock, not TIME.

The drawing shader makes round bright centers, soft halos and fading wakes.
Emission plus preview bloom supplies glow, without individual light nodes or
lighting nearby surfaces. A direct soft radial mask on a 12 cm head billboard
warps the background and splits its RGB channels, drawn before the 6 cm orb/wake
sprites. Three screen samples are used for each head's mask; trail samples discard
the lens pass. Warp strength is `refraction_pixels * (0.005 + 1.995 * anger²)`
times radial falloff, with a 14 px base default. Background RGB separation uses
maximum separation × anger² times the same falloff; the displayed meter is its
peak per-channel offset. Warp rises continuously from 0.07 px calm to 7.05 px at
half anger and 28 px at full anger. The live readout shows peak warp alongside
color separation, both following the same anger slider immediately.
Glow also gains colored fringes. Screen copies and transparent
pixel overlap have costs beyond the draw-call count; transparent neighbors cannot
be refracted through Godot's opaque screen capture.

Inspector exports on the emitter own count, scale, spread, tint, flight radius,
speed, wake sample count and duration, and distortion pixels. Restart/recreate
after editing these. Anger and maximum aberration update immediately. These are
art controls only.
Owner-authorized live promotion now connects the same emitter and shaders through
`scenes/vessel_particle_swarm.tscn` and `vessel_swarms.gd`. The live renderer owns
group placement, visibility, affinity and response-derived anger, and supplies
the saved active clock. Its capped 24 heads/group and existing group/plant/picking
contracts remain. The earlier insect art files remain unused by the live swarms;
no cleanup/deletion is included. See [Vastra integration](vastra-integration.md#player-facing-delivery).
Live visual anger blends toward its existing state-derived target using active
seconds, so warp changes smoothly and stops blending during explicit pause.

Validation: Godot 4.7.2 Forward+ / Direct3D 12 rendered 1, 128 and 2,048 orbs;
the emitter added two draw calls at all three densities. Captures were inspected,
including fixed-pose calm/50%/100% anger comparisons. World-image differences
were verified separately from caption changes, and two shared-clock poses checked
GPU motion. This is desktop render evidence, not target-device or frame-time
acceptance. Run `tools/review_vessel_preview.gd`; outputs are ignored under
`artifacts/vessels/`. No full regression-suite claim.

Meter follow-up: the rendered review also exercises both sliders, verifies the
shader's live maximum separation, checks the meter calculation at zero and half
anger, and checks retention across density switches. The world-image comparison
excludes the expanded controls so UI changes cannot satisfy the visual check.
The direct-mask revision captures the world without UI and verifies that bright
orb pixels remain, guarding against the background mask erasing the luminous head.

Live promotion validation: `tests/vessel_ecology.gd` passed 71 checks headlessly
and in a Forward+ / Direct3D 12 game-scene render. Checks cover the GPU pool,
external saved clock, unchanged snapshot during rendering, Observe/Details,
group picking and existing ecology rules. The connected capture was inspected
at `artifacts/vessel-response/connected.png`. An initial rendered attempt had
stale shader-cache read/write errors; rerunning with the fresh ignored
`.godot/vessel-live-user` profile completed cleanly. This is focused evidence,
not a full-suite or target-device pass.

The editor import registered the new scripts/shaders and generated UID sidecars,
but reported a Windows safe-save permission error. It is not claimed as a clean
editor-import pass; the subsequent real-render checks completed without errors.
