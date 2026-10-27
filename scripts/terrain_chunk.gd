extends Node2D
## Drawing uses prepared data only; it never generates neighboring terrain.
var cells: Array[Dictionary] = []

func _draw() -> void:
	for index in range(cells.size()):
		var data := cells[index]
		var p := Vector2(index % 16, floori(float(index) / 16)) * 32.0
		if data.ground == WorldTerrain.Ground.WATER:
			draw_rect(Rect2(p, Vector2(32, 32)), Color("254853").lightened(float(data.variation) * 0.008))
			draw_line(p + Vector2(4, 12 + data.variation), p + Vector2(23, 12 + data.variation), Color("47707a"), 1)
			draw_line(p + Vector2(12, 25), p + Vector2(28, 25), Color("355e6b"), 1)
		else:
			var tint: Color = data.tint
			draw_texture_rect(PackArt.atlas("TX Tileset Grass/TX Tileset Grass " + str(int(data.variation) % 4)), Rect2(p, Vector2(32, 32)), false, tint)
			if data.trail_visible:
				draw_texture_rect(PackArt.atlas("TX Tileset Grass/TX Tileset Grass Pavement " + str(int(data.variation) % 8)), Rect2(p, Vector2(32, 32)), false, Color("b2b29d"))
