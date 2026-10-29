class_name SceneryRequiredSpaces
extends Resource
## Shared authored observation spaces; no dependency on visual or species assets.
const RADIUS := 2
@export var world_seed := 2601026
@export var woodland: Array[Vector2i] = []
@export var dryland: Array[Vector2i] = []
@export var wetland: Array[Vector2i] = []

func anchors_for(patch_id: String) -> Array[Vector2i]:
	match patch_id:
		"woodland": return woodland
		"dryland": return dryland
		"wetland": return wetland
	return []

func parameters() -> Dictionary:
	var spaces: Array = []
	for anchors in [woodland, dryland, wetland]:
		for anchor in anchors:
			spaces.append([anchor.x - RADIUS, anchor.y - RADIUS, RADIUS * 2 + 1, RADIUS * 2 + 1])
	return {"clearing_seed": world_seed, "clearings": spaces}
