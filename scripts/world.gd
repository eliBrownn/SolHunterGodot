extends Node2D

const ChunkView = preload("res://scripts/terrain_chunk.gd")
const Explorer = preload("res://scripts/explorer.gd")
const CLIMATE_SETTINGS = preload("res://resources/climate_settings.tres")
const MOVE_SECONDS := 0.135
const CHUNK_RADIUS := 3

var host: Node3D
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
var diagnostic: Label
var pause_panel: PanelContainer
var journal_panel: PanelContainer
var confirmation := ConfirmationDialog.new()
var history := RichTextLabel.new()
var examine := false
var paused := false
var toast_time := 0.0
var frame_times: Array[float] = []
var max_publish_ms := 0.0
var max_generation_ms := 0.0
var smoke_mode := false
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
	new_expedition(2601026)

func bind_inputs() -> void:
	var bindings := {"west": [KEY_A, KEY_LEFT], "east": [KEY_D, KEY_RIGHT],
		"north": [KEY_W, KEY_UP], "south": [KEY_S, KEY_DOWN],
		"save_expedition": [KEY_F5], "load_expedition": [KEY_F9],
		"examine": [KEY_E], "pause_expedition": [KEY_ESCAPE],
		"diagnostics": [KEY_F3], "journal": [KEY_J]}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)

func key_label(action: String) -> String:
	var event: InputEventKey = InputMap.action_get_events(action)[0]
	return OS.get_keycode_string(event.physical_keycode)

func label(value: String, font_size: int = 16, color: Color = Color("dddac6")) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func panel_at(rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172321ec")
	style.border_color = Color("657263")
	style.set_border_width_all(1)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	hud.add_child(panel)
	return panel

func build_ui() -> void:
	var title := panel_at(Rect2(24, 24, 260, 92))
	var title_box := VBoxContainer.new()
	title.add_child(title_box)
	title_box.add_child(label("S O L H U N T E R", 23, Color("e1c791")))
	location_label = label("", 14)
	title_box.add_child(location_label)
	var mission := panel_at(Rect2(852, 24, 404, 92))
	var mission_box := VBoxContainer.new()
	mission.add_child(mission_box)
	mission_box.add_child(label("THE FIRST JOURNEY", 12, Color("b6bf9e")))
	objective = label("", 17)
	mission_box.add_child(objective)
	var footer := panel_at(Rect2(24, 726, 1232, 50))
	footer.add_child(label("WASD / arrows  Walk    Wheel  Zoom    %s  Examine    %s  Journal    %s  Save    %s  Load    Esc  Pause" % [key_label("examine"), key_label("journal"), key_label("save_expedition"), key_label("load_expedition")], 15))
	toast = label("", 18, Color("ead6a4"))
	toast.position = Vector2(42, 675)
	hud.add_child(toast)
	inspection = label("", 15)
	inspection.position = Vector2(42, 540)
	inspection.add_theme_color_override("font_shadow_color", Color.BLACK)
	inspection.add_theme_constant_override("shadow_offset_x", 1)
	inspection.add_theme_constant_override("shadow_offset_y", 1)
	hud.add_child(inspection)
	diagnostic = label("", 14)
	diagnostic.position = Vector2(26, 130)
	diagnostic.visible = false
	hud.add_child(diagnostic)
	journal_panel = panel_at(Rect2(852, 140, 404, 350))
	journal_panel.visible = false
	var journal_box := VBoxContainer.new()
	journal_panel.add_child(journal_box)
	journal_box.add_child(label("FIELD NOTES", 18, Color("e1c791")))
	history.custom_minimum_size = Vector2(360, 275)
	history.scroll_following = true
	history.add_theme_font_size_override("normal_font_size", 16)
	journal_box.add_child(history)
	pause_panel = panel_at(Rect2(440, 190, 400, 400))
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 14)
	pause_panel.add_child(menu)
	menu.add_child(label("REST A MOMENT", 24, Color("e1c791")))
	menu.add_child(label("Your expedition is paused.", 16))
	for item in [["Continue", toggle_pause], ["Save expedition", save_game], ["Load expedition", load_game], ["New expedition…", ask_new]]:
		var button := Button.new()
		button.text = item[0]
		button.custom_minimum_size.y = 42
		button.pressed.connect(item[1])
		menu.add_child(button)
	pause_panel.visible = false
	confirmation.title = "Start another expedition?"
	confirmation.dialog_text = "Unsaved travel will be lost. Your saved expedition stays available with F9."
	confirmation.confirmed.connect(func():
		new_expedition(posmod(terrain.world_seed + 104729, 2147483647))
		paused = false
		pause_panel.hide())
	hud.add_child(confirmation)

func ask_new() -> void:
	confirmation.popup_centered(Vector2i(480, 160))

func toggle_pause() -> void:
	paused = not paused
	pause_panel.visible = paused

func new_expedition(seed_value: int) -> void:
	var settings: Dictionary = CLIMATE_SETTINGS.parameters()
	if not WorldTerrain.valid_climate(settings):
		settings = WorldTerrain.default_climate()
		push_warning("Invalid climate settings; using defaults for this expedition.")
	terrain = WorldTerrain.new(seed_value, settings)
	cell = Vector2i.ZERO
	destination = cell
	moving = false
	visited = false
	returned = false
	history.clear()
	rebuild_world()
	message("Follow the old stone trail east and find the waystone.")

func rebuild_world() -> void:
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
	plan_chunks()
	while not pending.is_empty():
		publish_chunk(pending.pop_front())
	update_hud()

func center(at: Vector2i) -> Vector2:
	return Vector2(at) * 32.0 + Vector2(16, 16)

func add_prop(key: String, at: Vector2i) -> void:
	var sprite := PackArt.sprite(key, center(at))
	actors.add_child(sprite)
	place_props.append(sprite)

func build_places() -> void:
	add_prop("TX Props/TX Props Road Sign E", Vector2i(4, -2))
	add_prop("TX Props/TX Props Stone Bench S", Vector2i(-2, -2))
	add_prop("TX Props/TX Props Crate", Vector2i(-3, -1))
	add_prop("TX Props/TX Props Stone Lantern", Vector2i(1, -3))
	add_prop("TX Props/TX Props Altar", terrain.landmark() + Vector2i(0, -1))
	add_prop("TX Props/TX Props Rune Pillar X3", terrain.landmark() + Vector2i(-2, -2))
	add_prop("TX Props/TX Props Rune Pillar Broken", terrain.landmark() + Vector2i(2, -2))
	add_prop("TX Props/TX Props Road Sign W", terrain.landmark() + Vector2i(-4, 2))

func _process(delta: float) -> void:
	if frame_times.size() >= 3600:
		frame_times.pop_front()
	frame_times.append(delta * 1000.0)
	if not paused and not smoke_mode:
		advance_movement(delta, Input.get_vector("west", "east", "north", "south"))
	if not pending.is_empty():
		publish_chunk(pending.pop_front())
	toast_time -= delta
	toast.visible = toast_time > 0
	inspect_mouse()
	if diagnostic.visible:
		var times := frame_times.duplicate()
		times.sort()
		diagnostic.text = "Frame ms · p95 %.1f / p99 %.1f / max %.1f\nGeneration max %.2f ms · publication max %.2f ms\n%d / 49 live chunks · %d queued\nSeed %d · generation %d · cell %s" % [times[int((times.size() - 1) * 0.95)], times[int((times.size() - 1) * 0.99)], times.back(), max_generation_ms, max_publish_ms, chunks.size(), pending.size(), terrain.world_seed, terrain.generation_version, cell]

func advance_movement(delta: float, direction: Vector2) -> void:
	var remaining := delta
	for iteration in range(8):
		if not moving:
			if direction.length_squared() < 0.1:
				break
			var step := Vector2i(signi(roundi(direction.x * 2)), signi(roundi(direction.y * 2)))
			if not terrain.can_step(cell, cell + step):
				break
			destination = cell + step
			progress = 0.0
			moving = true
			explorer.facing = Vector2(step)
		var duration := MOVE_SECONDS * (sqrt(2.0) if destination.x != cell.x and destination.y != cell.y else 1.0)
		var consumed := minf(remaining, (1.0 - progress) * duration)
		progress += consumed / duration
		remaining -= consumed
		explorer.position = center(cell).lerp(center(destination), minf(progress, 1.0))
		if progress >= 0.99999:
			cell = destination
			moving = false
			arrived()
		if remaining <= 0.00001:
			break
	explorer.walking = moving
	camera.position = explorer.position.round()
	plan_chunks()

func arrived() -> void:
	if not visited and Vector2(cell - terrain.landmark()).length() < 4:
		visited = true
		message("Waystone reached. The trail leads home — return to the refuge.")
	if visited and not returned and terrain.is_camp(cell):
		returned = true
		message("Back at the refuge. Journey complete. Save with F5.")
	update_hud()

func plan_chunks() -> void:
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

func publish_chunk(coord: Vector2i) -> void:
	var start := Time.get_ticks_usec()
	var data := terrain.extract_chunk(coord)
	max_generation_ms = maxf(max_generation_ms, (Time.get_ticks_usec() - start) / 1000.0)
	start = Time.get_ticks_usec()
	var view := ChunkView.new()
	view.cells = data
	view.position = Vector2(coord * 16 * 32)
	chunk_root.add_child(view)
	var props: Array[Node2D] = []
	for index in range(data.size()):
		var at := coord * 16 + Vector2i(index % 16, floori(float(index) / 16))
		if data[index].obstacle == 0:
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
	max_publish_ms = maxf(max_publish_ms, (Time.get_ticks_usec() - start) / 1000.0)

func update_hud() -> void:
	location_label.text = "Refuge" if terrain.is_camp(cell) else ("Waystone" if terrain.is_landmark(cell) else "The wilds")
	var target := Vector2i.ZERO if visited else terrain.landmark()
	var distance := roundi(Vector2(target - cell).length())
	objective.text = "Journey complete · explore freely" if returned else ("Return to the refuge · %d tiles" % distance if visited else "Find the eastern waystone · %d tiles" % distance)

func message(value: String) -> void:
	toast.text = value
	toast_time = 7
	history.append_text(value + "\n\n")

func save_game(path: String = ExpeditionSave.SAVE_PATH) -> void:
	var error := ExpeditionSave.write(ExpeditionSave.snapshot(terrain.world_seed, cell, visited, returned, terrain.generation_version, terrain.climate), path)
	message("Expedition saved." if error == OK else "Save failed: " + error_string(error))

func load_game(path: String = ExpeditionSave.SAVE_PATH) -> void:
	var data := ExpeditionSave.read_save(path)
	if data.is_empty():
		message("No valid compatible save found. Current expedition kept.")
		return
	terrain = WorldTerrain.new(int(data.seed), data.climate)
	cell = Vector2i(int(data.player[0]), int(data.player[1]))
	destination = cell
	moving = false
	visited = data.landmark_visited
	returned = data.returned
	rebuild_world()
	if data.has("migrated_from"):
		message("Expedition updated to new terrain." + (" Your position moved to nearby dry ground." if data.migration_moved else ""))
	else:
		message("Expedition restored.")

func inspect_mouse() -> void:
	inspection.text = ""
	hover_outline.hide()
	if not examine or paused:
		return
	var point: Variant = host.pointer_world()
	if point == null:
		return
	var hovered := Vector2i((point / 32.0).floor())
	var data := terrain.sample(hovered)
	hover_outline.position = Vector2(hovered) * 32
	hover_outline.show()
	var names := ["Meadow", "Woodland", "Heath", "Marsh", "Water", "Shore"]
	inspection.text = "EXAMINE · %s %s\nWetness %d / 100\nVastra concentration %d / 100\nEcological overload %d / 100\n%s" % [names[data.ground], hovered, roundi(data.wetness * 100), data.concentration, data.overload, "Passable" if data.walkable else "Blocked"]

func handle_input(event: InputEvent) -> void:
	if confirmation.visible or (event is InputEventKey and event.echo):
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
		if event.is_action_pressed("examine"):
			examine = not examine
		if event.is_action_pressed("journal"):
			journal_panel.visible = not journal_panel.visible

