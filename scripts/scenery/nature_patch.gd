class_name NaturePatch
extends Resource
## Bounded visual treatment of existing habitats. No ecological state.
@export var patch_id := "woodland"
## Absolute cell rectangle; never relative to streaming chunks.
@export var bounds := Rect2i(20, 4, 24, 24)
## Existing habitat IDs. No relabeling or biome-generation override.
@export var habitats: Array[int] = [WorldTerrain.Ground.FOREST]
@export var entries: Array[NatureAssetEntry] = []
## Chance in percent within a stable three-cell cluster; rebuild to apply.
@export_range(0, 40) var density_percent := 24

func valid() -> bool:
	if patch_id.is_empty() or bounds.size.x < 4 or bounds.size.y < 4 or bounds.size.x > 128 or bounds.size.y > 128 or habitats.is_empty() or entries.is_empty() or entries.size() > 8 or density_percent < 0 or density_percent > 40:
		return false
	for habitat in habitats:
		if habitat < 0 or habitat > WorldTerrain.Ground.SAND:
			return false
	for entry in entries:
		if entry == null or not entry.valid():
			return false
	return true
