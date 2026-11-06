# SolHunter Gameplay

SolHunter starts in the **map-first world**. Open `project.godot` in Godot 4.7.2
and press **F5**, or run `godot --path .` from the project folder. The default
scene is `scenes/gameplay_foundation.tscn`.

## Play the map-first build

| Control | Action |
| --- | --- |
| WASD, arrows, or left stick | Move relative to the camera, including diagonals |
| Hold Shift | Sprint while moving |
| Middle-mouse drag | Orbit and tilt the camera |
| Mouse wheel | Zoom |
| Home | Reset the camera |

You start on a dry coast near the edge of the map. The Quaternius mannequin
plays authored idle, walk, and sprint animations. Releasing movement settles
the player at the nearest cell center. The HUD shows the local biome and FPS.
You can travel across land, rivers, lakes, and oceans.

Every launch generates a fresh world. To replay a map and its storm layout, pass
a fixed seed.

```powershell
godot --path . -- --world-seed=2601026
```

## How the world is built

Godot generates a Plan v7 atlas before terrain streams. The atlas sets
continental geography, mountains, climate, drainage, water levels, natural
biomes, and irrigation. Local terrain adds relief within that plan and uses
the same height samples for movement, water banks, and chunk boundaries.
Nearby terrain streams in 64×64-cell chunks with eight coarser horizon rings.

Terrain uses plain biome colors and mesh lighting. Every land biome can use
the full ground plant and custom expedition tree
palette by default. Each tree species has its own allowed biomes. Local
conditions shape density, and the biome shifts foliage hue. Authored branches
and crowns guide the [solid polygon tiers](docs/world-map-proposal.md#tree-species-and-vector-lods),
with sparse groves continuing through the terrain horizon rings.
Plants and trees are 50% larger by default. Use [Plant Coverage and Plant Scale](docs/inspector-tuning.md#map-first-vegetation)
to adjust density and size.
The bundled atlas shader renders water. The optional
[EmacEArt Cool Water pack](docs/water-appearance.md#cool-water-in-the-map-first-build)
adds close water effects when installed locally. Seeded Vastra vortices appear
near the player as a visual field test. Plant ecology, Sol encounters, combat,
campaign events, and expedition save/load belong to separate fixtures and design
records. The project uses the `SolHunter-Gameplay` Godot user-data directory.

See the [map generator and atlas proof](docs/world-map-proposal.md), the
[active exploration roadmap](docs/world-exploration-roadmap.md), and the
[project standard](docs/PROJECT_STANDARD.md).

## Validate the map-first build

GitHub Actions uses the pinned Godot 4.7.2 release to import the project and
run the seeded gameplay test. Run the same checks locally from PowerShell.

```powershell
./tools/validate.ps1 -Godot 'C:\path\to\Godot_console.exe' -GameplayOnly
```

Omit `-Godot` when `godot` is on PATH. The test exercises the configured startup
scene, seed replay, coastal spawn, terrain streaming, movement and animation,
the expedition tree palette, plant patch reconstruction, and persistent storm sites. See
[Reproduce the proof](docs/world-map-proposal.md#reproduce-the-proof) for atlas
exports across several seeds.

## Expedition fixtures and authoring tools

Open `scenes/world_3d.tscn` and press **F6** to run the inherited expedition
fixture. Its refuge and waystone route, field menu, Sol interactions, tactical
combat, and saves are documented in the
[expedition integration review](docs/expedition-integration.md) and the
[older terrain guide](docs/natural-terrain.md). See the
[field menu guide](docs/field-menu.md) for expedition controls and
[Inspector tuning](docs/inspector-tuning.md) for fixture settings.
Omit `-GameplayOnly` to run the full validator, including the inherited suites.

Open the [development workstation](docs/development-workstation.md),
[Sol Lab](docs/sol-lab.md), or [Vastra Particle Lab](docs/vastra-particle-lab.md)
as a standalone scene with **F6**. Use the
[Sol authoring guide](docs/creating-sol-models.md) and the
[Sol Bible](docs/reference/sol_bible.md) for creature work. The
[Worldbuilding Bible](docs/reference/SolHunter_Worldbuilding_Bible.md)
governs design. See the [repository roadmap](ROADMAP.md) for repository work.
