extends Node2D

signal chunk_published(coord: Vector2i, cells: Array[Dictionary])
signal chunk_removed(coord: Vector2i)
signal rebuilt
signal state_replaced(state: ExpeditionState)
signal observe_requested
signal encounter_requested
signal withdraw_requested
signal player_step_completed(from: Vector2i, to: Vector2i)
signal companion_requested
signal refuge_recovery_requested
signal battle_input_requested(event: InputEvent)
var battle_input_consumed := false
var interaction_hint: Label
var hover_cell: Variant = null

const Hud = preload("res://scripts/ui/expedition_hud.gd")
const ChunkView = preload("res://scripts/presentation/terrain_chunk.gd")
const Explorer = preload("res://scripts/world/explorer.gd")
const StructureView = preload("res://scripts/scenery/structure_view.gd")
const CLIMATE_SETTINGS = preload("res://resources/climate_settings.tres")
const VASTRA_SETTINGS = preload("res://resources/vastra_settings.tres")
const EXPEDITION_SETTINGS = preload("res://resources/expedition_settings.tres")
const CHUNK_RADIUS := 3
# Tree upper pieces extend 120 pixels above their ground anchor.
const VIEW_PROP_MARGIN := 128.0

var host: Node3D
var expedition_settings: ExpeditionSettings = EXPEDITION_SETTINGS
var climate_settings: ClimateSettings = CLIMATE_SETTINGS
var terrain_settings: TerrainReliefSettings = preload("res://resources/terrain_rolling.tres")
var scenery_settings: ScenerySiteTemplate = preload("res://resources/scenery/woodland_shelter.tres")
var vastra_settings: VastraSettings = VASTRA_SETTINGS
var configuration_warnings: Dictionary = {}
var movement_library_validation := preload("res://scripts/core/runtime_validation_cache.gd").new()
var terrain := WorldTerrain.new()
var cell := Vector2i.ZERO
var destination := Vector2i.ZERO
var moving := false
var progress := 0.0
var visited := false
var returned := false
var chunks: Dictionary = {}
var pending: Array[Vector2i] = []
var last_chunk := Vector2i(999999, 999999)
var last_stream_key := ""
var pending_pointer_hint: Variant = null
var max_process_ms := 0.0
var max_simulation_ms := 0.0
var max_movement_ms := 0.0
var chunk_root := Node2D.new()
var actors := Node2D.new()
var explorer := Explorer.new()
var camera := Camera2D.new()
var place_props: Array[Node2D] = []
var hud := CanvasLayer.new()
var objective: Label
var location_label: Label
var toast: Label
var inspection: Label
var inspection_panel: PanelContainer
var inspection_card: PanelContainer
var diagnostic: Label
var pause_panel: PanelContainer
var journal_panel: PanelContainer
var journal_notes := RichTextLabel.new()
var confirmation := ConfirmationDialog.new()
var history := RichTextLabel.new()
var menu: Node
var accessibility: Node
var examine := false
var observation_menu := PopupMenu.new()
var observation_cell: Variant = null
var inspected_cell: Variant = null
var observation_subject := ""
var context_actions: Dictionary = {}
var context_state: ExpeditionState
var context_battle: TacticalBattle
var observation_member_id := ""
var inspected_subject := ""
var inspected_appearance := ""
var paused := false
var encounter_active := false
var toast_time := 0.0
var frame_times: Array[float] = []
var frame_time_cursor := 0
var diagnostic_elapsed := 0.25
var max_publish_ms := 0.0
var max_generation_ms := 0.0
var smoke_mode := false
var persistent_state := ExpeditionState.new()
var hover_outline := Line2D.new()

func _ready() -> void:
	bind_inputs()
	add_child(chunk_root)
	actors.y_sort_enabled = true
	add_child(actors)
	actors.add_child(explorer)
	add_child(camera)
	hover_outline.points = PackedVector2Array([Vector2.ZERO, Vector2(32, 0), Vector2(32, 32), Vector2(0, 32), Vector2.ZERO])
	hover_outline.width = 1.5
	hover_outline.default_color = Color("e1cd95")
	hover_outline.z_index = 10
	hover_outline.hide()
	add_child(hover_outline)
	host.add_child(hud)
	build_ui()
	new_expedition(int(expedition_parameters().initial_seed))

func bind_inputs() -> void:
	var bindings := {"west": [KEY_A, KEY_LEFT], "east": [KEY_D, KEY_RIGHT],
		"north": [KEY_W, KEY_UP], "south": [KEY_S, KEY_DOWN], "run": [KEY_SHIFT],
		"save_expedition": [KEY_F5], "load_expedition": [KEY_F9],
		"examine": [KEY_E], "pause_expedition": [KEY_ESCAPE],
		"diagnostics": [KEY_F3], "journal": [KEY_J], "field_menu": [KEY_R],
		"companion": [KEY_C], "refuge_recovery": [KEY_H]}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)

func key_label(action: String) -> String:
	if host != null and host.gamepad != null and host.gamepad.active:
		var menu_hint: String = host.gamepad.button_name("menu")
		return {"journal": menu_hint + " → Field Guide", "companion": menu_hint + " → Sols", "field_menu": menu_hint, "pause_expedition": host.gamepad.button_name("pause"), "save_expedition": menu_hint + " → Save", "load_expedition": menu_hint + " → Save"}.get(action, menu_hint)
	var event: InputEventKey = InputMap.action_get_events(action)[0]
	return OS.get_keycode_string(event.physical_keycode)

func label(value: String, font_size: int = 16, color: Color = Color("dddac6")) -> Label:
	return Hud.label(value, font_size, color)

func panel_at(rect: Rect2) -> PanelContainer:
	return Hud.panel_at(hud, rect)

func build_ui() -> void:
	Hud.build(self)

func resume_exploration(_state: ExpeditionState = null) -> void:
	paused = false
	pause_panel.hide()

func confirm_new_expedition() -> void:
	if encounter_active:
		return
	new_expedition(posmod(terrain.world_seed + 104729, 2147483647))
	resume_exploration()

func ask_new() -> void:
	if encounter_active:
		message("Withdraw before starting another expedition.", false)
		return
	confirmation.popup_centered(Vector2i(480, 160))

func toggle_pause() -> void:
	if encounter_active:
		return
	if menu.opened:
		menu.close()
	observation_menu.hide()
	paused = not paused
	pause_panel.visible = paused
	if paused:
		explorer.walking = false
		explorer.running = false
		host.camera_dragging = false
		hud.move_child(pause_panel, -1)

func new_expedition(seed_value: int) -> void:
	if encounter_active:
		message("Withdraw before starting another expedition.", false)
		return
	var settings: Dictionary = climate_settings.parameters() if climate_settings != null else {}
	if not WorldTerrain.valid_climate(settings):
		settings = WorldTerrain.default_climate()
		push_warning("Invalid climate settings; using defaults for this expedition.")
	var relief_parameters := terrain_settings.parameters() if terrain_settings != null and terrain_settings.valid() else WorldTerrain.default_relief()
	var site_parameters := scenery_settings.parameters() if scenery_settings != null and scenery_settings.valid() else WorldTerrain.default_scenery()
	var candidate := WorldTerrain.new(seed_value, settings, relief_parameters, site_parameters)
	if not candidate.essential_route_clear():
		candidate = WorldTerrain.new(seed_value, settings, WorldTerrain.default_relief(), site_parameters)
		push_warning("Terrain settings blocked the essential route; retrying with default Rolling relief.")
		if not candidate.essential_route_clear():
			message("This seed has no safe essential route. Current expedition kept.", false)
			return
	terrain = candidate
	replace_persistent_state(ExpeditionState.new(seed_value, int(expedition_parameters().territory_size)))
	persistent_state.observe_territory(Vector2i.ZERO)
	cell = Vector2i.ZERO
	destination = cell
	moving = false
	visited = false
	returned = false
	state_replaced.emit(persistent_state)
	history.clear()
	refresh_discoveries()
	rebuild_world()
	message("Follow the old stone trail east and find the waystone.")

func rebuild_world() -> void:
	pending_pointer_hint = null
	if host.has_method("cancel_stream_chunk"):
		host.cancel_stream_chunk()
	hover_cell = null
	if interaction_hint != null:
		interaction_hint.text = "Right-click to interact"
	inspected_cell = null
	observation_cell = null
	observation_menu.hide()
	for coord in chunks.keys():
		remove_chunk(coord)
	pending.clear()
	for prop in place_props:
		prop.free()
	place_props.clear()
	build_places()
	explorer.position = center(cell)
	explorer.walking = false
	camera.position = explorer.position
	last_chunk = Vector2i(999999, 999999)
	last_stream_key = ""
	plan_chunks()
	# Build only what can contribute to the first view. Distant chunks retain the
	# normal one-per-frame streaming budget instead of blocking load/new seed.
	var view_size := get_viewport_rect().size
	var visible_bounds := Rect2(camera.position - view_size * 0.5, view_size).grow(VIEW_PROP_MARGIN)
	var chunk_pixels := float(WorldTerrain.CHUNK_SIZE * WorldTerrain.CELL_SIZE)
	for coord: Vector2i in pending.duplicate():
		var chunk_bounds := Rect2(Vector2(coord) * chunk_pixels, Vector2.ONE * chunk_pixels)
		if (host.has_method("chunk_visible") and host.chunk_visible(coord)) or (not host.has_method("chunk_visible") and chunk_bounds.intersects(visible_bounds)):
			publish_chunk(coord)
			pending.erase(coord)
	update_hud()
	rebuilt.emit()

func center(at: Vector2i) -> Vector2:
	return Vector2(at) * 32.0 + Vector2(16, 16)

func add_prop(key: String, at: Vector2i) -> void:
	var sprite := PackArt.sprite(key, center(at))
	sprite.set_meta("asset_key", key)
	actors.add_child(sprite)
	place_props.append(sprite)

func build_places() -> void:
	if terrain.scenery_site.get("admitted", false):
		for cell_at in terrain.scenery_site.blockers:
			var support := StructureView.new()
			support.footprint = Rect2i(cell_at, Vector2i.ONE)
			support.position = Vector2(cell_at + Vector2i.ONE) * 32.0
			actors.add_child(support)
			place_props.append(support)
	if terrain.cabin_footprint.has_area():
		var building := StructureView.new()
		building.footprint = terrain.cabin_footprint
		building.position = Vector2(terrain.cabin_footprint.end) * 32.0
		actors.add_child(building)
		place_props.append(building)
	add_prop("TX Props/TX Props Road Sign E", Vector2i(4, -2))
	add_prop("TX Props/TX Props Stone Bench S", Vector2i(-2, -2))
	add_prop("TX Props/TX Props Crate", Vector2i(-3, -1))
	add_prop("TX Props/TX Props Stone Lantern", Vector2i(1, -3))
	add_prop("TX Props/TX Props Altar", terrain.landmark() + Vector2i(0, -1))
	add_prop("TX Props/TX Props Rune Pillar X3", terrain.landmark() + Vector2i(-2, -2))
	add_prop("TX Props/TX Props Rune Pillar Broken", terrain.landmark() + Vector2i(2, -2))
	add_prop("TX Props/TX Props Road Sign W", terrain.landmark() + Vector2i(-4, 2))

func replace_persistent_state(state: ExpeditionState) -> void:
	if persistent_state.activity_advanced.is_connected(advance_environment):
		persistent_state.activity_advanced.disconnect(advance_environment)
	if persistent_state.discovery_recorded.is_connected(refresh_discoveries):
		persistent_state.discovery_recorded.disconnect(refresh_discoveries)
	persistent_state = state
	# Configure new individual admission before state_replaced listeners register wild Sols.
	if host != null and host.get("battle_settings") is BattleSettings:
		var battle_tuning: BattleSettings = host.get("battle_settings")
		if battle_tuning.valid():
			persistent_state.configure_sol_stats(battle_tuning.sol_stats, battle_tuning.class_buffs)
		if host.get("progression_settings") is ProgressionSettings:
			persistent_state.configure_progression(host.get("progression_settings"))
	persistent_state.set_population_cache_limit(expedition_parameters().population_cache_territories)
	persistent_state.activity_advanced.connect(advance_environment)
	persistent_state.discovery_recorded.connect(refresh_discoveries)

func warn_configuration_once(key: String, text: String) -> void:
	if not configuration_warnings.has(key):
		configuration_warnings[key] = true
		push_warning(text)

func expedition_parameters() -> Dictionary:
	if expedition_settings != null and expedition_settings.valid():
		return expedition_settings.parameters()
	warn_configuration_once("expedition", "Invalid expedition tuning; using default expedition settings.")
	return ExpeditionSettings.new().parameters()

func advance_environment(_tick: int) -> void:
	# No production regional profile is authored yet; baseline recovery needs none.
	var settings: Dictionary = vastra_settings.parameters() if vastra_settings != null else {}
	if vastra_settings == null or not vastra_settings.valid():
		warn_configuration_once("vastra", "Invalid Vastra tuning; using default recovery settings.")
		settings = VastraSettings.new().parameters()
	var tuning: VastraSettings = vastra_settings if vastra_settings != null and vastra_settings.valid() else VastraSettings.new()
	persistent_state.advance_environment(settings, Callable(), tuning)
	persistent_state.recover_affinity_conditions(tuning)

func _process(delta: float) -> void:
	var process_started := Time.get_ticks_usec()
	if pending_pointer_hint != null:
		var pointer: Vector2 = pending_pointer_hint
		pending_pointer_hint = null
		if not paused and not encounter_active and not observation_menu.visible and not (menu != null and menu.opened):
			update_pointer_hint(pointer)
	host.update_pointer_visual()
	if paused or encounter_active:
		explorer.running = false
	if frame_times.size() >= 3600:
		frame_times[frame_time_cursor] = delta * 1000.0
		frame_time_cursor = (frame_time_cursor + 1) % 3600
	else:
		frame_times.append(delta * 1000.0)
	if not paused and not smoke_mode:
		var simulation_started := Time.get_ticks_usec()
		persistent_state.advance_time(delta)
		max_simulation_ms = maxf(max_simulation_ms, (Time.get_ticks_usec() - simulation_started) / 1000.0)
		var movement := Input.get_vector("west", "east", "north", "south")
		if host.gamepad != null and host.gamepad.active:
			movement = host.gamepad.movement_vector()
		var movement_started := Time.get_ticks_usec()
		advance_movement(delta, host.movement_direction(movement))
		max_movement_ms = maxf(max_movement_ms, (Time.get_ticks_usec() - movement_started) / 1000.0)
	var build_budget: int = host.active_view.chunks_per_frame if host.has_method("stream_plan") else 1
	var deadline := Time.get_ticks_usec() + int(host.active_view.chunk_work_ms * 1000.0) if host.has_method("prepare_stream_chunk") else 0
	if host.has_method("prepare_stream_ground"):
		host.prepare_stream_ground(deadline)
	for index in range(mini(build_budget, pending.size())):
		if host.has_method("prepare_stream_chunk"):
			var prepared: Variant = host.prepare_stream_chunk(pending[0], deadline)
			if prepared == null:
				break
			publish_chunk(pending.pop_front(), prepared)
		else:
			publish_chunk(pending.pop_front())
	toast_time -= delta
	toast.visible = toast_time > 0 and (host.battles == null or host.battles.session == null)
	inspect_mouse()
	diagnostic_elapsed += maxf(0, delta)
	if diagnostic.visible and diagnostic_elapsed >= 0.25:
		diagnostic_elapsed = 0.0
		var times := frame_times.duplicate()
		times.sort()
		var limit: int = host.stream_capacity() if host.has_method("stream_capacity") else 49
		diagnostic.text = "Frame ms · p95 %.1f / p99 %.1f / max %.1f\nGeneration max %.2f ms · publication max %.2f ms\n%d / %d live chunks · %d queued\nSeed %d · generation %d · cell %s" % [times[int((times.size() - 1) * 0.95)], times[int((times.size() - 1) * 0.99)], times.back(), max_generation_ms, max_publish_ms, chunks.size(), limit, pending.size(), terrain.world_seed, terrain.generation_version, cell]
		if host.has_method("stream_plan"):
			diagnostic.text += "\n3D view %.0f° tilt · %.0f° orbit · %.0f cells zoom · %.0f cells far" % [host.view_elevation, host.view_azimuth, host.target_size, host.active_view.render_distance]
		if host.has_method("prepare_stream_chunk"):
			diagnostic.text += "\nStream preparation slice max %.2f ms · chunk geometry work max %.2f ms" % [host.max_stream_slice_ms, host.max_stream_geometry_ms]
		var stored := persistent_state.counts()
		diagnostic.text += "\nActivity tick %d · %d observed territories · %d recorded Sols" % [persistent_state.activity_tick(), stored.territories, stored.individuals]
	max_process_ms = maxf(max_process_ms, (Time.get_ticks_usec() - process_started) / 1000.0)

func advance_movement(delta: float, direction: Vector2) -> void:
	explorer.running = false
	if encounter_active or paused:
		return
	var remaining := delta
	for iteration in range(8):
		if not moving:
			if direction.length_squared() < 0.1:
				break
			var step := Vector2i(signi(roundi(direction.x * 2)), signi(roundi(direction.y * 2)))
			if not can_step(cell, cell + step):
				break
			destination = cell + step
			progress = 0.0
			moving = true
			explorer.facing = Vector2(step)
		var duration := float(expedition_parameters().move_seconds) * (sqrt(2.0) if destination.x != cell.x and destination.y != cell.y else 1.0)
		duration *= condition_move_multiplier(cell, destination)
		if (Input.is_action_pressed("run") or (host.gamepad != null and host.gamepad.sprinting())):
			duration /= float(expedition_parameters().run_multiplier)
		var consumed := minf(remaining, (1.0 - progress) * duration)
		progress += consumed / duration
		remaining -= consumed
		explorer.position = center(cell).lerp(center(destination), minf(progress, 1.0))
		if progress >= 0.99999:
			var previous := cell
			cell = destination
			moving = false
			arrived()
			player_step_completed.emit(previous, cell)
			if encounter_active:
				break
		if remaining <= 0.00001:
			break
	explorer.walking = moving
	explorer.running = moving and (Input.is_action_pressed("run") or (host.gamepad != null and host.gamepad.sprinting()))
	camera.position = explorer.position.round()
	plan_chunks()

func arrived() -> void:
	persistent_state.observe_territory(cell)
	if not visited and Vector2(cell - terrain.landmark()).length() < 4:
		visited = true
		message("Waystone reached. The trail leads home — return to the refuge.")
	if visited and not returned and terrain.is_camp(cell):
		returned = true
		message("Back at the refuge. Journey complete. Save with F5.")
	update_hud()

func plan_chunks() -> void:
	if host.has_method("stream_plan"):
		var key: String = host.stream_key()
		if key == last_stream_key:
			return
		last_stream_key = key
		var desired: Array[Vector2i] = host.stream_plan()
		var wanted := {}
		for coord in desired:
			wanted[coord] = true
		for coord: Vector2i in chunks.keys():
			if not wanted.has(coord):
				remove_chunk(coord)
		pending.clear()
		for coord in desired:
			if not chunks.has(coord):
				pending.append(coord)
		if host.has_method("cancel_stream_chunk") and host.stream_job != null and not pending.has(host.stream_job.coord):
			host.cancel_stream_chunk()
		return
	var current := terrain.chunk_of(cell)
	if current == last_chunk:
		return
	last_chunk = current
	for coord: Vector2i in chunks.keys():
		if absi(coord.x - current.x) > CHUNK_RADIUS or absi(coord.y - current.y) > CHUNK_RADIUS:
			remove_chunk(coord)
	pending.clear()
	for y in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
		for x in range(-CHUNK_RADIUS, CHUNK_RADIUS + 1):
			var coord := current + Vector2i(x, y)
			if not chunks.has(coord):
				pending.append(coord)
	pending.sort_custom(func(a: Vector2i, b: Vector2i): return a.distance_squared_to(current) < b.distance_squared_to(current))

func remove_chunk(coord: Vector2i) -> void:
	chunks[coord].view.free()
	for node in chunks[coord].props:
		node.free()
	chunks.erase(coord)
	chunk_removed.emit(coord)

func publish_chunk(coord: Vector2i, prepared: Array[Dictionary] = []) -> void:
	var start := Time.get_ticks_usec()
	var data := terrain.extract_chunk(coord) if prepared.is_empty() else prepared
	max_generation_ms = maxf(max_generation_ms, (Time.get_ticks_usec() - start) / 1000.0)
	start = Time.get_ticks_usec()
	var view := ChunkView.new()
	view.cells = data
	view.position = Vector2(coord * 16 * 32)
	chunk_root.add_child(view)
	if host.has_method("stream_plan"):
		view.hide()
	var props: Array[Node2D] = []
	for index in range(data.size()):
		if host.has_method("stream_plan"):
			break # Solid view publishes prepared cells directly; no hidden duplicate sprite scenery.
		var at := coord * 16 + Vector2i(index % 16, floori(float(index) / 16))
		if data[index].obstacle not in [1, 2]:
			continue
		var root := Node2D.new()
		root.position = center(at)
		if data[index].obstacle == 1:
			root.add_child(PackArt.sprite("TX Plant/TX Tree T1 Lower"))
			root.add_child(PackArt.sprite("TX Plant/TX Tree T1 Upper", Vector2(0, -63)))
		else:
			root.add_child(PackArt.sprite("TX Props/TX Props Stone T7"))
		actors.add_child(root)
		props.append(root)
	chunks[coord] = {"view": view, "props": props}
	chunk_published.emit(coord, data)
	max_publish_ms = maxf(max_publish_ms, (Time.get_ticks_usec() - start) / 1000.0)

func update_hud() -> void:
	location_label.text = "Refuge" if terrain.is_camp(cell) else ("Waystone" if terrain.is_landmark(cell) else "The wilds")
	var target := Vector2i.ZERO if visited else terrain.landmark()
	var distance := roundi(Vector2(target - cell).length())
	objective.text = "Journey complete · explore freely" if returned else ("Return to the refuge · %d tiles" % distance if visited else "Find the eastern waystone · %d tiles" % distance)

func refresh_discoveries(_identity: String = "") -> void:
	if menu != null and not menu.guide_context.is_empty():
		menu.refresh_observed_entry()
		return
	var entries := persistent_state.discovery_entries()
	if entries.is_empty():
		journal_notes.text = "Right-click a Sol and choose Observe to record a sighting."
		return
	var rows := PackedStringArray()
	for entry in entries:
		var description: String = entry.description
		for detail: String in entry.details:
			description += "\n" + detail
		rows.append("%s\n%s\nFirst seen: %d, %d" % [entry.title, description, entry.first_seen[0], entry.first_seen[1]])
	journal_notes.text = "\n\n".join(rows)

func message(value: String, session_note: bool = true) -> void:
	if host != null and host.gamepad != null and host.gamepad.active:
		value = host.gamepad.input_text(value)
	toast.text = value
	toast_time = 7
	if session_note:
		history.append_text(value + "\n\n")

func save_game(path: String = ExpeditionSave.SAVE_PATH) -> void:
	if encounter_active:
		message("Withdraw before saving your expedition.", false)
		return
	var error := ExpeditionSave.write(ExpeditionSave.snapshot(terrain.world_seed, cell, visited, returned, terrain.generation_version, terrain.climate, persistent_state.snapshot(), terrain.relief, terrain.scenery_parameters), path)
	message("Expedition saved." if error == OK else "Save failed: " + error_string(error))

func load_game(path: String = ExpeditionSave.SAVE_PATH) -> void:
	if encounter_active:
		message("Withdraw before loading an expedition.", false)
		return
	var data := ExpeditionSave.read_save(path)
	if data.is_empty():
		message("Save unavailable or incompatible. Older development saves require a new expedition. Current expedition kept.")
		return
	var candidate_state := ExpeditionState.restore(data.world_state, int(data.seed))
	if candidate_state == null:
		message("Invalid persistent state. Current expedition kept.")
		return
	var candidate_terrain := WorldTerrain.new(int(data.seed), data.climate, data.relief, data.scenery)
	terrain = candidate_terrain
	replace_persistent_state(candidate_state)
	cell = Vector2i(int(data.player[0]), int(data.player[1]))
	destination = cell
	moving = false
	visited = data.landmark_visited
	returned = data.returned
	state_replaced.emit(persistent_state)
	refresh_discoveries()
	rebuild_world()
	if data.has("migrated_from"):
		message("Expedition updated to new terrain." + (" Your position moved to nearby dry ground." if data.migration_moved else ""))
	else:
		message("Expedition restored.")

func inspect_mouse() -> void:
	if (menu != null and menu.opened) or confirmation.visible or pause_panel.visible:
		inspection_panel.hide()
		hover_outline.hide()
		return
	# Keep the current target stable while the pointer operates the inspection card.
	if inspection_panel.visible and inspection_panel.get_global_rect().has_point(hud.get_viewport().get_mouse_position()):
		describe_cell(inspection_card.target_cell)
		return
	inspection.text = ""
	inspection_panel.hide()
	hover_outline.hide()
	if inspected_cell != null:
		describe_cell(inspected_cell)
		return
	if not examine or paused:
		return
	var point: Variant = host.pointer_world()
	if point == null:
		return
	describe_cell(Vector2i((point / 32.0).floor()))

func describe_cell(hovered: Vector2i) -> void:
	var data := persistent_state.environment_view(hovered, terrain.sample(hovered))
	hover_outline.position = Vector2(hovered) * 32
	hover_outline.show()
	var names := ["Meadow", "Woodland", "Heath", "Marsh", "Water", "Shore"]
	var subject := inspected_subject if inspected_cell == hovered and not inspected_subject.is_empty() else observation_name(hovered)
	var recovery_text := ""
	var wildlife: Variant = host.get("wild_recovery") if host != null else null
	if wildlife != null:
		recovery_text = wildlife.describe_home(hovered)
	inspection_card.update_reading(hovered, subject, names[data.ground], data, recovery_text)
	inspection_card.show_appearance(inspected_appearance if inspected_cell == hovered else "")

func observation_name(at: Vector2i) -> String:
	var battle: Variant = host.battles.display_battle() if host.battles != null else null
	if battle != null:
		if at == battle.trainer:
			return "Trainer · Outside command position"
		if at == battle.enemy_cell:
			return "%s · %s · HP %d/%d" % [battle.enemy.display_name, str(battle.enemy.affinity).capitalize(), battle.enemy_hp, battle.enemy.max_hp]
		if battle.phase != "deployment" and at == battle.ally_cell:
			return "%s · %s · HP %d/%d" % [battle.ally.display_name, str(battle.ally.affinity).capitalize(), battle.ally_hp, battle.ally.max_hp]
	if host.sightings != null:
		for member in host.sightings.members:
			if member.sprite.visible and host.sightings.current_cell(member) == at:
				return "%s · %s" % [member.entry.name, str(member.sprite.affinity).capitalize()]
	if at == cell and battle == null:
		return "Trainer · Exploring the wilderness."
	var data := terrain.sample(at)
	if data.obstacle > 0:
		return ["", "Tree", "Rock", "Refuge cabin"][data.obstacle]
	if at == terrain.landmark():
		return "Waystone · A landmark on the old trail."
	for prop in place_props:
		if Vector2i((prop.position / 32.0).floor()) == at:
			return str(prop.get_meta("asset_key", "World object")).get_file().replace("TX ", "").replace("_", " ")
	return "Old stone trail" if data.trail_visible else ["Meadow", "Woodland", "Heath", "Marsh", "Water", "Shore"][data.ground]

func context_item(text: String, id: int, action: Dictionary, disabled: bool = false, hint: String = "") -> void:
	observation_menu.add_item(text, id)
	var index := observation_menu.get_item_index(id)
	observation_menu.set_item_disabled(index, disabled)
	observation_menu.set_item_tooltip(index, hint)
	context_actions[id] = action

func open_observation(pointer: Vector2, target_override: Variant = null, identity: String = "", primary: bool = false) -> void:
	observation_menu.hide()
	var at: Variant = target_override if target_override != null else host.pointer_cell(pointer)
	if at == null:
		return
	if not identity.is_empty():
		var found := false
		for member in host.sightings.members:
			if member.id == identity and member.sprite.visible and persistent_state.wild_available(identity):
				at = host.sightings.current_cell(member)
				found = true
				break
		if not found:
			message("That Sol is no longer available. Select another target.", false)
			return
	observation_cell = at
	observation_member_id = ""
	observation_subject = host.pointer_subject if target_override == null and host.has_method("pointer_object_cell") and not host.pointer_subject.is_empty() else observation_name(at)
	context_state = persistent_state
	context_battle = host.battles.session if host.battles != null else null
	context_actions.clear()
	observation_menu.clear()
	var targets: Array[Dictionary] = []
	# All individuals at the selected cell get their own named actions.
	# A foreground scenery hit retains its own actions rather than selecting through it.
	if context_battle == null and (target_override != null or not (host.has_method("pointer_object_cell") and not host.pointer_subject.is_empty())):
		for member in host.sightings.members:
			if member.sprite.visible and host.sightings.current_cell(member) == at and persistent_state.wild_available(member.id) and (identity.is_empty() or member.id == identity):
				targets.append(member)
	if not targets.is_empty():
		for index in range(targets.size()):
			var member: Dictionary = targets[index]
			var target_name := "%s · %s" % [member.entry.name, str(member.sprite.affinity).capitalize()]
			observation_menu.add_separator(target_name)
			var base := index * 10
			var available: bool = not paused and not encounter_active and not moving and host.encounters.settings.valid() and host.encounters.settings.enabled and host.sightings.manhattan(host.sightings.current_cell(member), cell) <= host.encounters.settings.interaction_distance
			var reason := ""
			if not available:
				reason = " (move closer)"
				if moving:
					reason = " (stop moving)"
				elif paused or encounter_active:
					reason = " (busy)"
				elif not host.encounters.settings.valid() or not host.encounters.settings.enabled:
					reason = " (unavailable)"
			context_item("Engage" + reason, base + 1, {"kind": "engage", "id": member.id}, not available, "Approach this Sol to choose battle, observation or withdrawal.")
			context_item("Observe", base, {"kind": "observe_sol", "id": member.id})
			context_item("Details", base + 6, {"kind": "inspect_sol", "id": member.id})
	else:
		observation_menu.add_separator(observation_subject.get_slice(" · ", 0))
		if at == cell and context_battle == null and not encounter_active:
			context_item("Your Sols", 3, {"kind": "sols"})
			context_item("Field Guide", 4, {"kind": "guide"})
			if terrain.is_camp(cell):
				context_item("Recover party", 5, {"kind": "recover"})
		context_item("Observe", 0, {"kind": "observe"})
		context_item("Details", 6, {"kind": "inspect_details"})
	context_actions[2] = {"kind": "cancel"}
	observation_menu.add_theme_font_size_override("font_separator_size", maxi(8, roundi(observation_menu.get_theme_font_size("font_size") * 0.8)))
	if primary:
		for index in observation_menu.item_count:
			if not observation_menu.is_item_separator(index) and not observation_menu.is_item_disabled(index):
				context_action(observation_menu.get_item_id(index))
				break
		return
	observation_menu.reset_size()
	var bounds := Vector2i(hud.get_viewport().get_visible_rect().size)
	observation_menu.popup(Rect2i(Vector2i(pointer), Vector2i.ZERO))
	# PopupMenu computes its content size on popup; clamp only after that calculation.
	observation_menu.position = Vector2i(pointer).clamp(Vector2i.ZERO, (bounds - observation_menu.size).max(Vector2i.ZERO))

func context_action(id: int) -> void:
	observation_menu.hide()
	if not context_actions.has(id):
		return
	var action: Dictionary = context_actions[id]
	# A popup never retains authority across load, rebuild or battle transitions.
	if action.kind == "cancel":
		return
	if observation_cell == null or context_state != persistent_state or confirmation.visible or (menu != null and menu.opened):
		return
	var battle: TacticalBattle = host.battles.session if host.battles != null else null
	if battle != context_battle or (encounter_active and battle == null):
		return
	if action.kind in ["engage", "observe_sol", "inspect_sol"]:
		var selected: Dictionary = {}
		for member in host.sightings.members:
			if member.id == action.id and member.sprite.visible and persistent_state.wild_available(member.id):
				selected = member
				break
		if selected.is_empty():
			message("That Sol is no longer available.", false)
			return
		if action.kind == "engage":
			host.encounters.approach_individual(action.id)
		else:
			observation_cell = host.sightings.current_cell(selected)
			observation_subject = "%s · %s" % [selected.entry.name, str(selected.sprite.affinity).capitalize()]
			observation_member_id = action.id
			if action.kind == "observe_sol":
				observe_cell()
			else:
				show_inspection_details()
	elif action.kind == "observe":
		observe_cell()
	elif action.kind == "inspect_details":
		show_inspection_details()
	elif not paused and not moving and not encounter_active and observation_cell == cell:
		if action.kind in ["sols", "guide"]:
			menu.open(action.kind)
		elif action.kind == "recover" and terrain.is_camp(cell):
			refuge_recovery_requested.emit()

func show_inspection_details() -> void:
	inspected_appearance = ""
	inspected_cell = observation_cell
	inspected_subject = observation_subject
	describe_cell(inspected_cell)
	inspection_card.more.button_pressed = true

func observe_cell(_id: int = 0) -> void:
	inspection_card.archive_observation()
	inspection_card.more.button_pressed = false
	if observation_cell == null or confirmation.visible:
		return
	inspected_cell = observation_cell
	inspected_subject = observation_subject
	inspected_appearance = appearance_description(inspected_cell, observation_subject)
	inspection_card.begin_observation()
	describe_cell(inspected_cell)
	if not paused and host.sightings != null:
		for member in host.sightings.members:
			if member.sprite.visible and host.sightings.current_cell(member) == inspected_cell and (observation_member_id.is_empty() or member.id == observation_member_id):
				host.sightings.observe_member(member)
				break

func appearance_description(at: Vector2i, subject: String) -> String:
	for member in host.sightings.members:
		if member.sprite.visible and host.sightings.current_cell(member) == at and (observation_member_id.is_empty() or member.id == observation_member_id):
			return "%s has a distinct body shape, surrounded by %s energy." % [member.entry.name, str(member.sprite.affinity)]
	var name := subject.get_slice(" · ", 0)
	var descriptions := {
		"Tree": "A tree with a solid trunk and a leafy canopy.",
		"Rock": "Exposed stone with an uneven surface.",
		"Refuge cabin": "A small cabin with solid walls and a pitched roof.",
		"Waystone": "An upright stone marker beside the old trail.",
		"Trainer": "A traveler wearing wilderness gear.",
		"Meadow": "Open ground covered in low grass.",
		"Woodland": "Grassy ground dotted with trees and undergrowth.",
		"Heath": "Open ground with sparse, low vegetation.",
		"Marsh": "Damp ground mixed with low vegetation.",
		"Water": "A stretch of water covering the ground.",
		"Shore": "A strip of ground at the water's edge.",
		"Old stone trail": "A worn path paved with uneven stone."
	}
	if descriptions.has(name):
		return descriptions[name]
	var lower := name.to_lower()
	if "tree" in lower or "pine" in lower or "oak" in lower:
		return descriptions.Tree
	if "rock" in lower or "stone" in lower or "boulder" in lower:
		return descriptions.Rock
	if "bush" in lower or "shrub" in lower or "fern" in lower or "grass" in lower:
		return "A clump of low-growing vegetation."
	if "flower" in lower:
		return "Small flowers growing close to the ground."
	return "You look over the %s." % lower

func update_pointer_hint(pointer: Vector2) -> void:
	if interaction_hint == null or host == null:
		return
	hover_cell = host.pointer_cell(pointer)
	if hover_cell == null:
		interaction_hint.text = ""
		interaction_hint.get_parent().hide()
		return
	var subject: String = host.pointer_subject if host.has_method("pointer_object_cell") and not host.pointer_subject.is_empty() else observation_name(hover_cell)
	interaction_hint.text = subject.get_slice(" · ", 0) + " · Right-click"
	interaction_hint.get_parent().tooltip_text = subject
	interaction_hint.get_parent().visible = subject not in ["Meadow", "Woodland", "Heath", "Marsh", "Water", "Shore", "Old stone trail"]

func handle_input(event: InputEvent) -> void:
	if host != null and host.story != null and host.story.window.visible:
		return
	if confirmation.visible or (event is InputEventKey and event.echo):
		return
	if menu != null and menu.opened:
		if event.is_action_pressed("pause_expedition"):
			toggle_pause()
		else:
			menu.handle_input(event)
		return
	if observation_menu.visible and event.is_action_pressed("pause_expedition"):
		observation_menu.hide()
		return
	if host.battles != null and host.battles.session != null and host.battles.modal_open():
		host.battles.handle_input(event)
		return
	if observation_menu.visible:
		return
	if event is InputEventMouseMotion and not encounter_active and not paused:
		pending_pointer_hint = event.position # Coalesce high-rate mouse events into one pick per frame.
	if event is InputEventMouseButton and event.double_click:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and (not paused or (host.battles != null and host.battles.session != null)):
		open_observation(event.position)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		inspected_cell = null
		if not encounter_active and not paused:
			open_observation(event.position, null, "", true)
			return
	if encounter_active:
		battle_input_consumed = false
		battle_input_requested.emit(event)
		if battle_input_consumed or not encounter_active:
			return
		if event.is_action_pressed("pause_expedition"):
			withdraw_requested.emit()
		elif event.is_action_pressed("save_expedition"):
			save_game()
		elif event.is_action_pressed("load_expedition"):
			load_game()
		return
	if event.is_action_pressed("pause_expedition"):
		toggle_pause()
	elif event.is_action_pressed("save_expedition"):
		save_game()
	elif event.is_action_pressed("load_expedition"):
		load_game()
	elif event.is_action_pressed("diagnostics"):
		diagnostic.visible = not diagnostic.visible
	elif not paused:
		if event.is_action_pressed("field_menu"):
			menu.open()
		if event.is_action_pressed("companion"):
			menu.open("sols")
		if event.is_action_pressed("refuge_recovery"):
			refuge_recovery_requested.emit()
		if event.is_action_pressed("examine"):
			inspected_cell = null
			inspection_card.more.button_pressed = false
			examine = not examine
		if event.is_action_pressed("journal"):
			menu.open("guide")


func can_step(from: Vector2i, to: Vector2i) -> bool:
	if not terrain.can_step(from, to):
		return false
	var conditions: Dictionary = persistent_state.environment_view(to, {}).get("conditions", {})
	if conditions.has("barrier"):
		return false
	if from.x != to.x and from.y != to.y:
		for side in [Vector2i(from.x, to.y), Vector2i(to.x, from.y)]:
			if persistent_state.environment_view(side, {}).get("conditions", {}).has("barrier"):
				return false
	return true

func condition_move_multiplier(from: Vector2i, to: Vector2i) -> float:
	var conditions: Dictionary = persistent_state.environment_view(to, {}).get("conditions", {})
	if not conditions.has("rough") and not conditions.has("warp") and not conditions.has("wet") and not conditions.has("wind"):
		return 1.0
	var library: MoveLibrary = host.get("move_library") if host != null else null
	if not movement_library_validation.check(library, [preload("res://resources/sol_ecology/behavior_library.tres")]):
		library = preload("res://resources/move_library.tres")
	if conditions.has("rough"):
		return library.world_rough_multiplier
	if conditions.has("warp"):
		return library.world_warp_short if from.x == to.x else library.world_warp_long
	for kind in ["wet", "wind"]:
		if conditions.has(kind):
			var d: Array = conditions[kind].direction
			var delta := to - from
			var dot := delta.x * int(d[0]) + delta.y * int(d[1])
			return library.world_flow_assisted if dot > 0 else (library.world_flow_resisted if dot < 0 else 1.0)
	return 1.0
