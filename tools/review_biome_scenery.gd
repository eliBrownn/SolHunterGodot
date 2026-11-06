extends "res://tools/review_cohesive_sample.gd"
## Controlled art fixtures on actual generated habitats, not walking or behavior acceptance.

func run() -> void:
	output_directory = "res://artifacts/world_exploration/biome-art"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_directory = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps = 60
	scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	world = scene.world
	world.smoke_mode = true
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	condition("clear")
	var candidates := {}
	for y in range(-96, 129, 8):
		for x in range(-96, 129, 8):
			var at := Vector2i(x, y)
			var ground: int = world.terrain.natural_ground(at)
			if ground not in [0, 1, 2, 3] or not world.terrain.fits(at):
				continue
			var score := 0
			for dy in range(-6, 7, 3):
				for dx in range(-6, 7, 3):
					score += int(world.terrain.natural_ground(at + Vector2i(dx, dy)) == ground)
			if not candidates.has(ground) or score > candidates[ground].score:
				candidates[ground] = {"cell": at, "score": score}
	var views := []
	for ground in [0, 1, 2, 3]:
		check(candidates.has(ground), "Review seed contains the requested habitat")
		if not candidates.has(ground): continue
		await fixture(candidates[ground].cell)
		scene.sightings.admit_nearby(Vector2i(214748,214748), world.cell)
		scene.sightings.sync_views()
		world.update_hud()
		await settle(20)
		var name: String = world.HABITAT_NAMES[ground].to_lower()
		await capture(name)
		var residents: Array = []
		for member in scene.sightings.members:
			if member.entry.get("habitat_spawn", false):
				residents.append({"name": member.entry.name, "home": str(member.home), "species": member.entry.species, "reaction": scene.sightings.ecology_for(member).reaction})
		views.append({"habitat": name, "cell": str(world.cell), "label": world.location_label.text, "residents": residents,
			"seed": world.terrain.world_seed, "viewport": str(root.size), "local_matching_samples": candidates[ground].score})
	FileAccess.open(output_directory + "/views.json", FileAccess.WRITE).store_string(JSON.stringify(views, "\t"))
	scene.environment.sky = null
	scene.free()
	print("BIOME ART REVIEW: %d habitats, %d failures; controlled clear-noon fixtures, not normal-input travel" % [views.size(), failures.size()])
	quit(0 if failures.is_empty() else 1)
