extends SceneTree
const Generator = preload("res://scripts/scenery/procedural_stone_obstacle.gd")
const Recipe = preload("res://scripts/scenery/stone_obstacle_definition.gd")
func _initialize() -> void:
	for family in range(10):
		for seed_value in [0, 73, 99999]:
			var recipe := Recipe.new()
			recipe.family = family
			recipe.seed_value = seed_value
			var data := Generator.layout(recipe)
			assert(data == Generator.layout(recipe), "Reconstruction must be deterministic")
			var original_parts: Array = data.parts.filter(func(part): return not str(part.id).begins_with("rubble/"))
			recipe.rubble_count = 0
			var without_detail := Generator.layout(recipe)
			assert(original_parts == without_detail.parts, "Detail must not reroll structure")
			recipe.rubble_count = 5
			assert(data.bounds.size.is_finite() and data.bounds.size.x > 0 and data.bounds.size.y > 0)
			var ids := {}
			var columns := {}
			for part in data.parts:
				assert(not ids.has(part.id))
				ids[part.id] = true
				assert(part.at.is_finite() and part.size.is_finite())
				assert(part.size.x > 0 and part.size.y > 0 and part.size.z > 0)
				if family >= 6: continue
				var column := Vector2(part.at.x, part.at.z)
				assert(is_equal_approx(part.at.y - part.size.y / 2, columns.get(column, 0.0)), "Every stone must be supported")
				columns[column] = part.at.y + part.size.y / 2
			var object := Generator.build(data)
			assert(object.get_child_count() == data.parts.size())
			object.free()
	var invalid := Recipe.new()
	invalid.length = 100
	assert(Generator.layout(invalid).is_empty())
	print("Stone obstacle reconstruction, support, identity, build and invalid-input checks passed")
	quit()
