extends SceneTree
## Headless atlas export and contract checks. Pass a folder and optional seeds after --.

const Plan := preload("res://scripts/world/world_map_plan.gd")
const SEEDS := [2601026, 41971, 73020]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var output := args[0] if not args.is_empty() else "res://artifacts/world-map-v%d" % Plan.VERSION
	var seeds: Array[int] = []
	for index in range(1, args.size()):
		if not args[index].is_valid_int():
			push_error("Invalid world seed: %s" % args[index])
			quit(1)
			return
		var seed := args[index].to_int()
		if seed not in seeds:
			seeds.append(seed)
	var proof_seeds := seeds.is_empty()
	if proof_seeds:
		seeds.assign(SEEDS)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) != OK:
		push_error("Unable to create atlas export folder.")
		quit(1)
		return
	var baseline := Plan.new(seeds[0])
	var data := baseline.export_layers()
	var repeat := Plan.new(seeds[0])
	if repeat.export_layers() != data or baseline.sample_world_cell(Plan.WORLD_ORIGIN - Vector2i.ONE).land:
		push_error("The map must be seed-stable and outside bounds must resolve to ocean.")
		quit(1)
		return
	var last_biomes: Array = []
	for seed in seeds:
		var plan := baseline if seed == seeds[0] else Plan.new(seed)
		var layers := data if seed == seeds[0] else plan.export_layers()
		var counts: Array[int] = []
		counts.resize(Plan.Biome.size())
		counts.fill(0)
		var ocean_border := true
		var samples_agree := true
		var river_cells := 0
		var irrigated_cells := 0
		var adjusted_biomes := 0
		var valid_water := true
		var valid_tundra := true
		var valid_biomes := true
		for index: int in layers.biome.size():
			var biome: int = layers.biome[index]
			counts[biome] += 1
			if biome != layers.natural_biome[index]:
				adjusted_biomes += 1
				valid_biomes = valid_biomes and layers.irrigation[index] > 0 and biome in [Plan.Biome.PLAINS, Plan.Biome.MARSH]
			if biome == Plan.Biome.TUNDRA:
				valid_tundra = valid_tundra and layers.elevation[index] >= Plan.TUNDRA_MIN_ELEVATION
			var x := index % Plan.SIZE.x
			var z := index / Plan.SIZE.x
			if x == 0 or z == 0 or x == Plan.SIZE.x - 1 or z == Plan.SIZE.y - 1:
				ocean_border = ocean_border and layers.biome[index] == Plan.Biome.OCEAN
			if layers.river_flow[index] > 0.0:
				river_cells += 1
				var outlet: int = layers.downstream[index]
				valid_water = valid_water and outlet >= 0 and (
					layers.biome[outlet] == Plan.Biome.OCEAN or layers.river_flow[outlet] > layers.river_flow[index])
			if layers.lake_level[index] > 0.0:
				valid_water = valid_water and layers.lake_level[index] > layers.elevation[index]
			if layers.irrigation[index] > 0:
				irrigated_cells += 1
				var intake: int = layers.irrigation[index] - 1
				var distance := absi(x - intake % Plan.SIZE.x) + absi(z - intake / Plan.SIZE.x)
				valid_water = valid_water and layers.river_flow[intake] > 0.0 and distance <= 8
				valid_water = valid_water and layers.elevation[index] <= layers.elevation[intake] + 0.00101
			if index % 97 == 0:
				var cell := Plan.WORLD_ORIGIN + Vector2i(x, z) * Plan.WORLD_CELLS_PER_SAMPLE
				var sample := plan.sample_world_cell(cell + Vector2i.ONE * (Plan.WORLD_CELLS_PER_SAMPLE / 2))
				samples_agree = samples_agree and sample.biome == layers.biome[index]
				samples_agree = samples_agree and sample.natural_biome == layers.natural_biome[index]
				samples_agree = samples_agree and is_equal_approx(sample.elevation, layers.elevation[index])
				samples_agree = samples_agree and is_equal_approx(sample.river_flow, layers.river_flow[index])
				samples_agree = samples_agree and (sample.irrigation_intake != null) == (layers.irrigation[index] > 0)
		var land: float = 1.0 - float(counts[Plan.Biome.OCEAN]) / layers.biome.size()
		var proof_coverage := land >= 0.24 and land <= 0.64 and not 0 in counts and river_cells > 100 and irrigated_cells > 20 and adjusted_biomes > 0
		if not ocean_border or not samples_agree or not valid_water or not valid_tundra or not valid_biomes or layers.biome == last_biomes or (proof_seeds and not proof_coverage):
			push_error("Atlas geography checks failed for %s: land %s, biomes %s" % [seed, land, counts])
			print("Water valid: ", valid_water, " | tundra elevation valid: ", valid_tundra, " | river samples: ", river_cells, " | irrigated samples: ", irrigated_cells)
			quit(1)
			return
		last_biomes = layers.biome
		var file := FileAccess.open(output.path_join("seed-%s.json" % seed), FileAccess.WRITE)
		if file == null:
			push_error("Unable to write atlas data for %s." % seed)
			quit(1)
			return
		file.store_string(JSON.stringify(layers))
		file.close()
		print("Atlas ", seed, " | land ", snappedf(land * 100.0, 0.1), "% | biome counts ", counts,
			" | river samples ", river_cells, " | irrigated samples ", irrigated_cells, " | adjusted biomes ", adjusted_biomes)
	quit()
