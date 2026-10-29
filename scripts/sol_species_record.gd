class_name SolSpeciesRecord
extends SolSpeciesDefinition
## Connected species content. Affinity and individual traits deliberately do not live here.

## Editable working name; changing it never renames the stable species ID.
@export var display_name := ""
## Reference level for these six species stats; new individuals snapshot their resolved profile.
@export_range(1, 55) var reference_level := 3
@export_range(1, 1000) var max_hp := 44
@export_range(0, 1000) var attack := 18
@export_range(0, 1000) var defense := 18
@export_range(0, 1000) var special_attack := 18
@export_range(0, 1000) var special_defense := 18
@export_range(0, 1000) var speed := 18
## Planned ordinary lineage length, used for existing training capacity. Does not author evolution triggers.
@export_range(1, 3) var evolution_forms := 3
## Explicit eligible move IDs from the shared MoveLibrary, independent of individual affinity.
@export var learnable_moves: PackedStringArray = []
## Initially remembered moves; the first four are equipped under the existing contract.
@export var starting_moves: PackedStringArray = []
## Species default behavior; per-individual named overrides remain in sighting settings.
@export var ecology: SolEcologyProfile
## Actual presentation scene used in exploration, combat and previews.
@export var presentation_scene: PackedScene
## Species movement capability. New wild admissions snapshot it; affinity never supplies a mode.
@export var traversal: SolTraversalProfile = SolTraversalProfile.new()

func valid() -> bool:
	if traversal == null or not traversal.valid():
		return false
	if not super.valid() or not species_id.is_valid_identifier() or species_id.length() > 80 or not lineage_id.is_valid_identifier() or lineage_id.length() > 80:
		return false
	if not text(display_name, 80) or display_name != display_name.strip_edges() or class_id not in ClassBuffSettings.IDS or not whole(evolution_forms, ordinary_form, 3):
		return false
	if not whole(reference_level, 1, 55) or not whole(max_hp, 1, 1000):
		return false
	for value in [attack, defense, special_attack, special_defense, speed]:
		if not whole(value, 0, 1000):
			return false
	for values in [learnable_moves, starting_moves]:
		if values.is_empty() or values.size() > 32:
			return false
		var seen := {}
		for id in values:
			if not id.is_valid_identifier() or id.length() > 80 or seen.has(id):
				return false
			seen[id] = true
	for id in starting_moves:
		if not learnable_moves.has(id):
			return false
	if ecology == null or ecology.species_id != species_id or not ecology.species_default or not ecology.valid(preload("res://resources/sol_ecology/behavior_library.tres")):
		return false
	return presentation_valid()

func presentation_valid() -> bool:
	if presentation_scene == null or not presentation_scene.can_instantiate():
		return false
	# Inspect the packed root script without allocating animated nodes during live settings checks.
	var scene_state := presentation_scene.get_state()
	var root_script: Script
	for index in range(scene_state.get_node_property_count(0)):
		if scene_state.get_node_property_name(0, index) == "script":
			root_script = scene_state.get_node_property_value(0, index) as Script
	while root_script != null:
		if root_script.resource_path == "res://scripts/sol_creature.gd":
			return creature_configuration_valid(scene_state)
		root_script = root_script.get_base_script()
	return false

func creature_configuration_valid(scene_state: SceneState) -> bool:
	var values := {"body_plan": 0, "model_scale": 1.0, "idle_strength": 1.0, "idle_rate": 0.6, "action_seconds": 0.45, "step_distance": 0.06, "step_lift": 0.045, "turn_response": 12.0, "wingbeat_rate": 3.0, "swim_stroke_rate": 1.5}
	for index in range(scene_state.get_node_property_count(0)):
		var key := scene_state.get_node_property_name(0, index)
		if values.has(key):
			values[key] = scene_state.get_node_property_value(0, index)
	if not whole(values.body_plan, 0, 2):
		return false
	for row in [["model_scale", 0.5, 1.5], ["idle_strength", 0.0, 2.0], ["idle_rate", 0.0, 2.0], ["action_seconds", 0.1, 1.0], ["step_distance", 0.04, 0.3], ["step_lift", 0.0, 0.15], ["turn_response", 1.0, 30.0], ["wingbeat_rate", 1.0, 6.0], ["swim_stroke_rate", 0.5, 3.0]]:
		var value: Variant = values[row[0]]
		if (not value is float and not value is int) or not is_finite(float(value)) or value < row[1] or value > row[2]:
			return false
	return true

func battle_profile(assigned_affinity: String) -> Dictionary:
	var affinity := AffinityImprint.canonical(assigned_affinity)
	if not valid() or affinity not in AffinityImprint.IDS:
		return {}
	return {"species_id": species_id, "display_name": display_name, "lineage_id": lineage_id,
		"class_id": class_id, "affinity": affinity, "level": reference_level,
		"max_hp": max_hp, "attack": attack, "defense": defense,
		"special_attack": special_attack, "special_defense": special_defense, "speed": speed,
		"move_name": starting_moves[0].replace("_", " ").capitalize(), "move_power": 6, "move_range": 2}
