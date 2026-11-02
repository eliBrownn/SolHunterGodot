extends SceneTree
## Development-only ownership, reservation, budget and rejection report.
func _initialize() -> void:
	var seeds := [0, 71, 2601026, 17]
	for seed_value in seeds:
		var terrain := WorldTerrain.new(seed_value)
		print("SCENERY REPORT seed=%d generation=%d\n%s" % [seed_value, terrain.generation_version, var_to_str(terrain.scenery_site)])
	quit()
