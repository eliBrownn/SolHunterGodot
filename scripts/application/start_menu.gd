extends Control
## Startup owns the loading barrier; simulation and canonical admission retain their owners.
const GAME_SCENE := "res://scenes/world_3d.tscn"
@export_range(1.0, 3.0, 0.25) var play_generation_ms := 1.0
var game: Node3D
var loading := false
var entered := false
var rendering_prepared := false
var targets: Array[Vector2i] = []
var status: Label
var progress: ProgressBar
var actions: VBoxContainer
var loading_clock := 0.0
var completed := 0
var registration_stages: Array[String] = []
var save_path := "user://expedition.json"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)
	var background := ColorRect.new()
	background.color = Color("14251f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(440, 0)
	column.add_theme_constant_override("separation", 20)
	center.add_child(column)
	var title := Label.new()
	title.text = "SOLHUNTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	column.add_child(title)
	status = Label.new()
	status.text = "Return to the living world."
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status)
	progress = ProgressBar.new()
	progress.max_value = 64
	progress.show_percentage = false
	progress.hide()
	column.add_child(progress)
	actions = VBoxContainer.new()
	column.add_child(actions)
	for label in ["New Game", "Load Game", "Quit"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size.y = 48
		actions.add_child(button)
		if label == "Quit": button.pressed.connect(func() -> void: get_tree().quit())
		else: button.pressed.connect(begin.bind(label == "Load Game"))
	actions.get_child(0).grab_focus()

func begin(load_saved: bool = false) -> void:
	if loading or entered: return
	loading = true
	rendering_prepared = false
	actions.hide()
	progress.show()
	status.text = "Preparing the world…"
	# Display the loading screen before dependency loading and synchronous scene setup.
	await get_tree().process_frame
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
	var packed := load(GAME_SCENE) as PackedScene
	if packed == null:
		fail("The world could not be loaded.")
		return
	game = packed.instantiate()
	game.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(game)
	# Keep the overlay above the game's own HUD while preparing.
	move_child(game, 0)
	game.world.startup_loading = true
	if load_saved:
		var previous: Object = game.world.persistent_state
		game.world.load_game(save_path)
		if game.world.persistent_state == previous:
			fail("Save unavailable or incompatible. Choose New Game.")
			return
	loading_clock = game.world.persistent_state.activity_seconds()
	game.active_view = game.active_view.duplicate(true)
	game.active_view.chunk_preparation_jobs = 1
	game.active_view.spiral_chunk_loading = true
	game.active_view.max_resident_chunks = maxi(128, game.active_view.max_resident_chunks)
	var center: Vector2i = game.world.terrain.chunk_of(game.world.cell)
	targets.clear()
	for y in range(-3, 5):
		for x in range(-3, 5): targets.append(center + Vector2i(x, y))
	targets.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := maxi(absi(a.x-center.x),absi(a.y-center.y))
		var db := maxi(absi(b.x-center.x),absi(b.y-center.y))
		return da < db if da != db else (a.y < b.y if a.y != b.y else a.x < b.x))
	game.world.pending.clear()
	for coord in targets:
		game.nearby_stream_chunks[coord] = true
		if not game.world.chunks.has(coord): game.world.pending.append(coord)
	while is_instance_valid(game) and loading:
		game.world._process(0.0)
		completed = 0
		for coord in targets:
			if game.world.chunks.has(coord) and game.solid_chunks.has(coord): completed += 1
		progress.value = completed
		status.text = "Preparing terrain · %d / 64 chunks" % completed
		var flora_ready: bool = game.world.flora_catalog != null and game.world.flora_catalog.pending.is_empty()
		if completed == 64 and flora_ready: break
		if completed == 64: status.text = "Establishing plants and wildlife…"
		await get_tree().process_frame
	if not loading: return
	registration_stages.clear()
	for kind in ["plant", "tree"]:
		registration_stages.append(kind)
		status.text = "Registering grass and ground plants…" if kind == "plant" else "Registering trees and recipients…"
		var definitions: Array[Dictionary] = []
		for row: Dictionary in game.world.startup_flora_definitions.values():
			if row.kind == kind: definitions.append(row)
		definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
		for first in range(0, definitions.size(), 64):
			var batch: Array[Dictionary] = []
			for index in range(first, mini(first + 64, definitions.size())): batch.append(definitions[index])
			if not game.world.persistent_state.admit_flora(batch):
				fail("Plant registration could not finish. Please start again.")
				return
			await get_tree().process_frame
	status.text = "Connecting the local ecosystem…"
	game.world.persistent_state.set_flora_active(game.world.flora_catalog.active_ids())
	game.world.startup_flora_definitions.clear()
	registration_stages.append("connected")
	game.sightings.sync_views()
	status.text = "Preparing visual effects…"
	await prepare_rendering()
	if not loading or not is_instance_valid(game): return
	game.active_view.chunk_work_ms = play_generation_ms
	game.active_view.distant_chunk_work_ms = minf(0.5, play_generation_ms)
	game.active_view.chunks_per_frame = 1
	game.world.startup_loading = false
	# Reset the planning key so normal view-aware streaming takes over on movement.
	game.world.last_stream_key = ""
	game.process_mode = Node.PROCESS_MODE_INHERIT
	entered = true
	loading = false
	for child in get_children():
		if child != game: child.hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Real draws behind the opaque loading overlay, in the active world/viewport.
## No combat events, actors, clock advances or permanent preparation nodes.
func prepare_rendering() -> void:
	if not loading or entered: return
	if rendering_prepared: return
	if DisplayServer.get_name() == "headless":
		rendering_prepared = true # Stage skipped; this does not qualify GPU pipelines.
		return
	var prepared_game: Node3D = game
	if not is_instance_valid(prepared_game): return
	var samples := Node3D.new()
	samples.name = "LoadingRenderSamples"
	samples.process_mode = Node.PROCESS_MODE_DISABLED
	prepared_game.add_child(samples)
	# Camera-relative placement avoids terrain or scenery hiding the samples.
	samples.global_position = prepared_game.camera.global_transform * Vector3(0, 0, -4.0)
	var feedback: Node3D = prepared_game.battles.feedback_view
	for kind in ["damage", "vastra"]:
		var cue: Dictionary = feedback.create_cue({"kind":kind,"caption":"Vastra","amount":1,"affinity":"earth","cell":prepared_game.world.cell},samples,0)
		cue.label.text = "0123456789−+ Vastra"
		cue.node.position.x = -0.6 if kind == "damage" else 0.6
	for frame in range(12): await get_tree().process_frame
	if not is_instance_valid(prepared_game): return
	await RenderingServer.frame_post_draw
	for child in samples.get_children(): child.free()
	# Only variants identified by the previous first-use investigation.
	for species in ["sol_species_0010", "sol_species_0011"]:
		var model := SolSpeciesView.create(species, "earth", prepared_game.sol_visual_settings)
		if model == null: continue
		samples.add_child(model)
		model.ground_y = 0.0
		model.animate(0,0,0)
		for frame in range(8): await get_tree().process_frame
		if not is_instance_valid(prepared_game): return
		await RenderingServer.frame_post_draw
		model.free()
	samples.free()
	rendering_prepared = true

func fail(message: String) -> void:
	if is_instance_valid(game):
		game.free()
	game = null
	loading = false
	status.text = message
	progress.hide()
	actions.show()
	actions.get_child(0).grab_focus()
