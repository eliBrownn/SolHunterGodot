extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func child(id: String, parent: String) -> SolBehaviorDefinition:
	var result := SolBehaviorDefinition.new()
	result.behavior_id = id
	result.parent_id = parent
	return result

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var settings := SightingSettings.new().duplicate(true) as SightingSettings
	var library := settings.behavior_library
	var entry := {"species": "seedmote", "class": "verdant", "affinity": "earth", "reaction": "Wary"}
	var profile := settings.ecology_profiles[0]
	profile.caution_variation_cells = 0
	profile.spacing_variation_cells = 0
	check(settings.valid(), "Default hierarchical resources validate")
	var resolved := SolEcology.resolve("hierarchy", entry, settings)
	check(resolved.selected_behaviors.flee == "seedmote_flee", "Species selects its child of the shared flee primitive")
	var variant := child("verdant_flight", "seedmote_flee")
	variant.class_ids = ["verdant"]
	variant.reaction_distance = 4
	library.definitions.append(variant)
	var earth := child("earth_verdant_flight", "verdant_flight")
	earth.affinity_ids = ["earth"]
	earth.flee_release_distance = 7
	library.definitions.append(earth)
	check(settings.valid(), "Species, class and affinity can specialize the same inherited branch")
	resolved = SolEcology.resolve("hierarchy", entry, settings)
	check(resolved.selected_behaviors.flee == earth.behavior_id and resolved.tuning.reaction_distance == 4 and resolved.tuning.flee_release_distance == 7, "Child inherits parent tuning and overrides its own flight release")
	var decision := SolEcology.decide("hierarchy", Vector2i.ZERO, Vector2i.ZERO, Vector2i(3, 0), {"action": "idle"}, 1, resolved)
	check(decision.action == "flee", "Inherited threshold changes the real response at three cells")
	var air_entry := entry.duplicate()
	air_entry.affinity = "air"
	var air := SolEcology.resolve("hierarchy", air_entry, settings)
	check(air.selected_behaviors.flee == variant.behavior_id and air.tuning.flee_release_distance == settings.flee_release_distance, "Mismatching affinity falls back to the eligible parent")
	air_entry["class"] = "beast"
	air = SolEcology.resolve("hierarchy", air_entry, settings)
	check(air.selected_behaviors.flee == "seedmote_flee" and air.tuning.reaction_distance == settings.reaction_distance, "Ancestor class restrictions also bind descendants")
	check(air.samples == resolved.samples, "Specializations cannot reroll immutable individual samples")
	var before := library.configuration()
	earth.affinity_ids[0] = "water"
	check(before != library.configuration(), "In-place filter edits invalidate the cached configuration")
	earth.affinity_ids[0] = "earth"
	var tie := child("aaa_earth_flight", "verdant_flight")
	tie.affinity_ids = ["earth"]
	tie.reaction_distance = 2
	library.definitions.append(tie)
	check(library.select("flee", entry).id == tie.behavior_id, "Equal-ranked branches have a stable alphabetical winner")
	library.definitions.reverse()
	check(library.select("flee", entry).id == tie.behavior_id, "Resource order cannot change branch selection")
	earth.priority = 1
	check(library.select("flee", entry).id == earth.behavior_id, "Authored priority resolves overlapping specializations")
	profile.behaviors = ["idle", "patrol", "verdant_flight"]
	check(settings.valid() and SolEcology.resolve("hierarchy", entry, settings).behaviors.has("flee"), "Species can pull a specific branch directly from the library")
	profile.behaviors = ["idle", "flee", "verdant_flight"]
	check(not settings.valid(), "Two branches of the same primitive cannot double-apply tuning")
	profile.behaviors = ["idle", "patrol", "flee"]
	var bad := child("bad", "missing")
	library.definitions.append(bad)
	check(not settings.valid(), "Missing parents reject")
	bad.parent_id = "bad"
	check(not settings.valid(), "Self cycles reject without hanging")
	bad.parent_id = earth.behavior_id
	earth.parent_id = "bad"
	check(not settings.valid(), "Multi-node cycles reject")
	earth.parent_id = "verdant_flight"
	bad.parent_id = "flee"
	bad.action = "guard"
	check(not settings.valid(), "Children cannot silently replace their inherited movement primitive")
	bad.action = "inherit"
	bad.routine_ticks = 0
	check(not settings.valid(), "Invalid response override ranges reject")
	bad.routine_ticks = -1
	bad.parent_id = "patrol"
	bad.attention_ticks = 3
	check(not settings.valid(), "Ambient branches reject unused response controls")
	library.definitions.erase(bad)
	profile.behaviors = ["idle", "patrol", "missing"]
	check(not settings.valid(), "Unknown species behavior selections reject")
	profile.behaviors = ["idle", "patrol", "guard"]
	check(not settings.valid(), "Inheritance preserves temperament validation")
	profile.behaviors = ["idle", "patrol", "flee"]
	resolved = SolEcology.resolve("hierarchy", entry, settings)
	decision = SolEcology.decide("hierarchy", Vector2i.ZERO, Vector2i(6, 0), Vector2i(7, 0), {"action": "idle"}, 1, resolved)
	check(decision.action == "return", "Home-boundary safety outranks inherited reactions")
	check(settings.valid(), "All temporary invalid authoring has been restored")
	settings.wilderness_enabled = false
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = settings
	root.add_child(scene)
	scene.world.new_expedition(17)
	var member: Dictionary = scene.sightings.members[0]
	scene.sightings.refresh_ecology_cache()
	var first: Dictionary = scene.sightings.ecology_for(member)
	var snapshot: Dictionary = scene.world.persistent_state.snapshot()
	earth.reaction_distance = 5
	scene.sightings.refresh_ecology_cache()
	var next: Dictionary = scene.sightings.ecology_for(member)
	check(first.tuning.reaction_distance == 4 and next.tuning.reaction_distance == 5, "Editing a nested child refreshes actual loaded-world behavior")
	check(snapshot == scene.world.persistent_state.snapshot(), "Hierarchy/cache resolution never mutates saved identity or movement")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
	scene.environment.sky = null
	scene.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
	print("Sol behavior hierarchy: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
