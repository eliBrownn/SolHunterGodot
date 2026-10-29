extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()
func settle() -> void:
	for frame in range(5):
		await process_frame
func click(at: Vector2) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event, true)
func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var card: PanelContainer = world.inspection_card
	var before: Dictionary = world.persistent_state.snapshot()
	world.inspected_cell = Vector2i.ZERO
	world.describe_cell(Vector2i.ZERO)
	await settle()
	var data: Dictionary = world.persistent_state.environment_view(Vector2i.ZERO, world.terrain.sample(Vector2i.ZERO))
	check(card.visible and not card.details_scroll.visible, "Inspection opens as a compact card with secondary details collapsed")
	check(card.readings.wetness.value.text == "%d / 100" % roundi(float(data.wetness) * 100) and card.readings.vastra.bar.value == int(data.concentration), "Environmental meters reflect the authoritative readings")
	check(card.heading.text == world.observation_name(Vector2i.ZERO).get_slice(" · ", 0) and not card.heading.text.contains("EXAMINE"), "One subject heading replaces the duplicated examination title")
	check(card.size.x <= 260 and card.size.y < 140, "Default card is narrower and shorter than the old text block")
	check(not card.metrics.visible and card.size.x <= 230 and card.size.y < 60, "Default inspection is a single slim line without environmental readings")
	var compact_height: float = card.size.y
	var pointer: Vector2 = scene.camera.unproject_position(scene.player_visual.global_position + Vector3.UP)
	world.open_observation(pointer)
	check(world.context_actions.has(6) and world.context_actions[6].kind == "inspect_details", "Right-click offers an explicit Details choice")
	world.context_action(6)
	await settle()
	check(not card.details_scroll.visible and card.metrics.visible and not card.more.visible and before == world.persistent_state.snapshot(), "Details shows graphs without Less or secondary text")
	click(card.close_button.get_global_rect().get_center())
	world.describe_cell(Vector2i.ZERO)
	await settle()
	check(not card.details_scroll.visible and not card.metrics.visible and card.size.y <= compact_height + 1, "Closing details permits a fresh compact inspection")
	# Reproduce the owner's sample without editing terrain or persistent state.
	var sample := {"ground": 1, "obstacle": 0, "walkable": true, "wetness": 0.49, "concentration": 41, "overload": 0, "conditions": {}}
	card.update_reading(Vector2i(-5, -9), "Woodland", "Woodland", sample, "")
	check(card.readings.wetness.value.text == "49 / 100" and card.readings.vastra.value.text == "41 / 100" and card.readings.overload.value.text == "0 / 100", "Sample retains all three exact readings including zero overload")
	check(card.access.text == "Passable", "Passability remains visible without invented danger thresholds")
	# Leave the sample static for the rendered capture; normal world inspection has
	# already exercised the real integration above.
	world.set_process(false)
	if captures():
		await capture("compact")
	sample.walkable = false
	sample.obstacle = 3
	sample.affinity = "fire"
	sample.conditions = {"heat": {"level": 2}}
	card.update_reading(Vector2i(-5, -9), "Refuge cabin", "Woodland", sample, "Recorded home recovery")
	card.more.button_pressed = true
	await settle()
	check(card.access.text == "Blocked" and card.access.tooltip_text.contains("Building") and card.details_label.text.contains("Fire") and card.details_label.text.contains("stage 2/3") and card.details_label.text.contains("Recorded home recovery"), "Building access, affinity, condition and wildlife facts remain available")
	if captures():
		await capture("details")
	world.menu.settings.text_scale = 2
	card.update_reading(Vector2i(-5, -9), "Refuge cabin", "Woodland", sample, "Recorded home recovery")
	await settle()
	check(card.readings.overload.label.autowrap_mode == TextServer.AUTOWRAP_OFF and card.size.x <= 540, "Large-text readings stay on one line in a bounded detail card")
	check(card.heading.get_theme_font_size("font_size") == 20 and card.readings.wetness.value.get_theme_font_size("font_size") == 19, "Inspection follows the user's text-size preference")
	root.size = Vector2i(900, 600)
	await settle()
	card.fit_card()
	check(card.get_rect().end.x <= card.get_viewport_rect().size.x and card.get_rect().end.y <= card.get_viewport_rect().size.y, "Expanded large-text card remains within the resized viewport")
	if captures():
		await capture("details-large")
	click(card.close_button.get_global_rect().get_center())
	await settle()
	check(not card.visible and not world.examine and world.inspected_cell == null and not world.hover_outline.visible, "Close dismisses the card and its target highlight")
	check(world.persistent_state.snapshot() == before, "Inspection controls never alter the expedition snapshot")
	# A lingering barrier blocks otherwise walkable terrain, including its final
	# recovery stage. Inspection must agree with the actual movement authority.
	var barrier_cell := Vector2i.RIGHT
	check(world.can_step(Vector2i.ZERO, barrier_cell), "Barrier fixture starts on traversable terrain")
	var barrier_snapshot := before.duplicate(true)
	barrier_snapshot.affinity_tiles[AffinityImprint.key(barrier_cell)] = {"affinity": "earth", "conditions": {"barrier": {"level": 3, "since": world.persistent_state.activity_tick(), "interval": 1, "direction": [0, 0]}}}
	world.persistent_state = ExpeditionState.restore(barrier_snapshot, 17)
	var barrier_before: Dictionary = world.persistent_state.snapshot()
	world.describe_cell(barrier_cell)
	await settle()
	check(not world.can_step(Vector2i.ZERO, barrier_cell) and card.access.text == "Blocked" and card.access.tooltip_text.contains("barrier"), "Inspection identifies the same lingering barrier that blocks movement")
	check(world.persistent_state.snapshot() == barrier_before, "Reading a lingering barrier leaves its saved recovery state intact")
	if captures():
		await capture("barrier")
	for tick in range(3):
		world.persistent_state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
		world.persistent_state.recover_affinity_conditions()
		world.describe_cell(barrier_cell)
		check(card.access.text == ("Blocked" if tick < 2 else "Passable") and world.can_step(Vector2i.ZERO, barrier_cell) == (tick == 2), "Inspection and traversal agree throughout barrier recovery")
	scene.free()
	print("INSPECTION CARD: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
func captures() -> bool:
	return OS.get_cmdline_user_args().has("--capture-inspection") and DisplayServer.get_name() != "headless"
func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/inspection")
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/inspection/" + name + ".png")
