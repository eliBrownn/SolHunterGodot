# In-game Vastra particle branch

Run `scenes/world_3d.tscn` in Godot 4.7.2. This branch enables GPU filament
particles for real exploration Vastra transfers; it is not a lab-only entry.
The full standalone lab and owner-captured baseline are also included.

## Runtime contract

`VastraCurrents` retains authoritative source selection, conserved transfer IDs,
scheduled arrival times, source/destination attachments, terrain-cleared curves,
Sol dissipation and active expedition time. `vastra_filament_renderer.gd` is a
bounded visual consumer. It cannot dispatch, consume or credit energy. Particle
slots are keyed by transfer ID and send tick and are retained between frames.
No active-time advance means no particle advance. Pending deliveries hold their
head at the recipient until the real credit. Floating-origin changes translate
both the path samples and Sol-clearing inputs into the same local frame.

Each optical particle is a 24-segment curved strip following the actual nine
terrain-following path points. The lab's optical shader supplies thin filaments,
soft refraction and complementary fringes; it is not the previous orb rendering.
The geometry helper and path sampler are shared with the full lab.

The branch uses the owner's optical baseline: thickness 0.20 cells, filament
length 2.00 cells, history 1.50 active seconds, refraction 0.010 and visibility
0.55, without emission. Synthetic lab vortex/layout, manual packet amounts and
night mode do not override real world geometry, energy, time or weather.

## Controls and comparison

Open `resources/vastra_particle_settings.tres` in the Inspector. `enabled` switches
between particles and original surfaces. Visibility and transfer visibility may
both reach zero, hiding refraction as well as the visible strands. Head/history
counts rebuild the bounded pool; the other optical settings update live. Send
pulse strength/duration control a finite departure surge. Defaults cap visible
transfers at twelve, with eight heads and ten history samples each (1056 sprites,
24 strip segments per sprite). These are provisional desktop budgets.

This integrates the rendering experiment only. Persistent player-driven fluid
wakes and physical response are still pending; particles alone do not prove them.
No ecological or movement rule is changed by enabling the renderer.

## Branch preparation

The running workspace had uncommitted current-world/plant-ledger dependencies.
They are checkpointed separately before the particle integration commit. Other
chats' worktrees and the original checkout remain untouched. The design Bible
is not edited in this branch. Optional source packs without redistribution rights
remain untracked: owner character, grass, tropical plants and supplied sky archive.
A capsule character fallback and an independently authored simple sky make this
source checkout usable without those files. Adopted nature/audio/effect dependencies
retain their CC0, MIT or CC BY notices alongside the copied subset.

## Focused evidence

Godot 4.7.2 Direct3D 12 `--script tests/plant_vastra.gd -- --capture-trajectories`
passed **337 checks** through the actual 3D expedition. This reuses the existing
plant charge/transfer/arrival journey and adds GPU identity, pool reuse, frozen
active-time, read-only ledger, zero visibility and legacy-comparison checks.
The real packet capture under `artifacts/plant-vastra/packet-in-transit.png` was
inspected. This is focused evidence, not a full-suite or device-performance pass.
The initial editor import reported a local safe-save directory warning; the final
rendered journey reported no script, shader or engine errors. Configured CI remains
unchanged and will run on push.
