extends Node2D
## Visible footprint in the reference 2D view; prevents an invisible building blocker.

var footprint := Rect2i()

func _draw() -> void:
	var origin := -Vector2(footprint.size) * 32.0
	for y in range(footprint.size.y):
		for x in range(footprint.size.x):
			draw_texture_rect(PackArt.atlas("TX Tileset Wall/TX Tileset Wall_11"), Rect2(origin + Vector2(x, y) * 32.0, Vector2(32, 32)), false)
	draw_rect(Rect2(origin, Vector2(footprint.size) * 32.0), Color("534a3d"), false, 2.0)
