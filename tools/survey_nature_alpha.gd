extends SceneTree
## N0 authoring evidence only. Reads generated terrain; never changes an expedition.
## Run: Godot --headless --path . --script tools/survey_nature_alpha.gd
const AREA := Rect2i(-12, -24, 109, 89)
const DIRECTIONS := [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
var terrain: WorldTerrain
var routes: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func pair(at: Vector2i) -> Array:
	return [at.x, at.y]

func reachable(footprint: int) -> Dictionary:
	var parents := {}
	if not terrain.fits(Vector2i.ZERO, footprint): return parents
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	parents[Vector2i.ZERO] = Vector2i.ZERO
	var index := 0
	while index < queue.size():
		var at := queue[index]
		index += 1
		for direction: Vector2i in DIRECTIONS:
			var next := at + direction
			# Keep the entire footprint in the surveyed area, including its far edge.
			if not AREA.encloses(Rect2i(next, Vector2i.ONE * footprint)) or parents.has(next): continue
			if terrain.can_step(at, next, footprint):
				parents[next] = at
				queue.append(next)
	return parents

func path_to(at: Vector2i, parents: Dictionary) -> Array:
	var path: Array = []
	if not parents.has(at): return path
	while true:
		path.push_front(pair(at))
		if at == Vector2i.ZERO: break
		at = parents[at]
	return path

func candidate(at: Vector2i, evidence: Dictionary) -> Dictionary:
	return {"place_reference": "%d/cell/%d:%d" % [terrain.world_seed, at.x, at.y],
		"cell": pair(at), "evidence": evidence,
		"outbound_cardinal_path": path_to(at, routes[1]),
		"three_cell_path": path_to(at, routes[3]),
		"return": "Reverse the recorded path; terrain.can_step verified in both directions.",
		"status": "geography candidate; no authored behavior or payoff inferred"}

func run() -> void:
	var settings: ExpeditionSettings = load("res://resources/expedition_settings.tres")
	var climate: ClimateSettings = load("res://resources/climate_settings.tres")
	var entry := (load("res://scenes/world_3d.tscn") as PackedScene).get_state()
	var relief: TerrainReliefSettings = load("res://resources/terrain_rolling.tres")
	var scenery: ScenerySiteTemplate = load("res://resources/scenery/woodland_shelter.tres")
	for index in range(entry.get_node_property_count(0)):
		var value: Variant = entry.get_node_property_value(0, index)
		match entry.get_node_property_name(0, index):
			"terrain_settings": relief = value
			"scenery_settings": scenery = value
			"expedition_settings": settings = value
			"climate_settings": climate = value
	terrain = WorldTerrain.new(settings.initial_seed, climate.parameters(), relief.parameters(), scenery.parameters())
	if not terrain.essential_route_clear(): terrain = WorldTerrain.new(settings.initial_seed, climate.parameters(), WorldTerrain.default_relief(), scenery.parameters())
	terrain.flora_specialist_percent = settings.flora_specialist_percent
	routes[1] = reachable(1)
	routes[3] = reachable(3)
	var grove: Dictionary = {}
	var bank: Dictionary = {}
	var best_grove := -INF
	var best_bank := INF
	var tree_cells := {}
	for y in range(AREA.position.y, AREA.end.y):
		for x in range(AREA.position.x, AREA.end.x):
			var cell := Vector2i(x, y)
			if terrain.flora_kind(cell, terrain.sample(cell)) == "tree": tree_cells[cell] = true
	# Stable scan/tie order. Prefer large-companion access; never invent a plant ID.
	for at: Vector2i in routes[1]:
		if at.distance_to(Vector2i.ZERO) < 10.0 or at.length() > 48.0: continue
		var trees: Array = []
		for y in range(-3, 4):
			for x in range(-3, 4):
				var cell := at + Vector2i(x, y)
				if not AREA.has_point(cell): continue
				if tree_cells.has(cell): trees.append(AffinityImprint.key(cell))
		var score := float(trees.size()) - at.length() * 0.03 + (5.0 if routes[3].has(at) else 0.0)
		if trees.size() >= 3 and score > best_grove:
			best_grove = score
			grove = candidate(at, {"generated_tree_cell_ids": trees, "radius_cells": 3,
				"live_reserves": "not sampled; generation does not prove saturation or active transfer"})
		var water_distance := terrain.lake_distance(at)
		var bank_score := at.length() + (0.0 if routes[3].has(at) else 100.0)
		if water_distance > 1.0 and water_distance < 1.5 and bank_score < best_bank:
			best_bank = bank_score
			bank = candidate(at, {"basin_normalized_distance": water_distance,
				"participants": [], "habitat_behavior": "requires actual sighting/behavior admission"})
	var valid: bool = terrain.essential_route_clear() and not routes[1].is_empty()
	for footprint in [1, 3]:
		for at: Vector2i in routes[footprint]:
			var previous: Vector2i = routes[footprint][at]
			if at != previous and not terrain.can_step(at, previous, footprint): valid = false
	var hashes := {}
	for folder in ["scripts/world", "scripts/scenery", "resources/scenery"]:
		fingerprint(folder, hashes)
	for file in ["scenes/world_3d.tscn", "resources/expedition_settings.tres", "resources/climate_settings.tres", "resources/terrain_rolling.tres", "resources/terrain_exploration.tres", "resources/plant_community_settings.tres", "tools/survey_nature_alpha.gd"]:
		hashes[file] = FileAccess.get_sha256("res://" + file)
	var report := {"schema": 1, "seed": terrain.world_seed, "generation": terrain.generation_version,
		"engine": Engine.get_version_info().string, "bounds": [AREA.position.x, AREA.position.y, AREA.size.x, AREA.size.y],
		"inputs": {"climate": terrain.climate, "relief": terrain.relief, "community": terrain.community_parameters,
			"scenery": terrain.scenery_parameters, "expedition": settings.parameters(), "source_sha256": hashes},
		"reachable_cells": {"player": routes[1].size(), "three_cell_companion": routes[3].size()},
		"bidirectional_paths_valid": valid, "circulation_grove": grove, "waterside_habitat": bank,
		"rest_origin": candidate(Vector2i.ZERO, {"existing_camp": true, "recovery": "N3 must verify NPC-independent recovery; no new rest rules"}),
		"disturbed_crossing": {"status": "unassigned; no actual disturbance or participant verified"},
		"limits": ["Generated defaults only, not a loaded save or normal-input play review.",
			"Cardinal cell clearance excludes runtime actors, ecological barriers and continuous body collision.",
			"No participants, alarms, reserves, rewards or weather routines are synthesized.",
			"Hashes describe survey inputs, not a reviewed combined build or distributable asset set."]}
	DirAccess.make_dir_recursive_absolute("res://artifacts/nature_alpha")
	var output := FileAccess.open("res://artifacts/nature_alpha/n0-survey.json", FileAccess.WRITE)
	if output == null:
		push_error("Cannot write N0 survey")
		quit(1)
		return
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("N0 SURVEY: player=%d large=%d grove=%s bank=%s paths=%s" % [routes[1].size(), routes[3].size(), grove.get("cell", []), bank.get("cell", []), valid])
	quit(0 if valid else 1)

func fingerprint(folder: String, result: Dictionary) -> void:
	for file in DirAccess.get_files_at("res://" + folder):
		if file.get_extension() in ["gd", "tres"]:
			var path := folder + "/" + file
			result[path] = FileAccess.get_sha256("res://" + path)
	for child in DirAccess.get_directories_at("res://" + folder):
		fingerprint(folder + "/" + child, result)
