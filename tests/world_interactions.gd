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
func open_on(scene: Node3D, member: Dictionary) -> void:
	scene.sightings.sync_views()
	var pointer: Vector2 = scene.camera.unproject_position(member.sprite.global_position)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	event.position = pointer
	scene.world.handle_input(event)
func run() -> void:
	root.gui_embed_subwindows = true
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var first: Dictionary = scene.sightings.members[0]
	world.cell = first.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	first = scene.sightings.members[0]
	var before: Dictionary = world.persistent_state.snapshot()
	open_on(scene, first)
	check(world.observation_menu.visible and world.context_actions[1].id == first.id, "Right click offers Engage for the clicked Sol")
	check(world.observation_menu.get_item_index(2) == -1, "Context menu omits Cancel; clicking away and Back dismiss it")
	check(world.observation_menu.get_item_text(0).contains(first.entry.name) and world.observation_menu.get_item_text(1) == "Engage" and world.observation_menu.get_item_text(2) == "Observe", "Target heading replaces Choose Option and action labels omit repeated names")
	check(world.observation_menu.position.x > 100 and world.observation_menu.position.y > 100, "Context popup uses the visible HUD viewport instead of the hidden simulation viewport")
	check(world.observation_menu.get_item_text(1).begins_with("Engage") and world.context_actions[0].kind == "observe_sol" and world.context_actions[2].kind == "cancel", "Specific action precedes Observe; cancellation remains available internally")
	check(world.persistent_state.snapshot() == before and not world.encounter_active, "Opening a menu neither engages nor records a sighting")
	world.observation_menu.id_pressed.emit(2)
	check(not world.observation_menu.visible and world.persistent_state.snapshot() == before, "Cancel has no gameplay effect")
	open_on(scene, first)
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	world.handle_input(escape)
	check(not world.observation_menu.visible and not world.paused, "Escape dismisses the context menu before opening the field menu")
	open_on(scene, first)
	world.observation_menu.id_pressed.emit(0)
	check(world.persistent_state.has_discovery(first.id) and not world.encounter_active, "Observe records precisely the selected Sol without engaging")
	check(world.inspection_card.appearance.visible and world.inspection_card.appearance.text.contains("orb") and not world.inspection_card.metrics.visible and not world.inspection_card.access.visible, "Observe displays the current Sol appearance without environmental readings")
	var card: PanelContainer = world.inspection_card
	card.set_process(false)
	check(is_equal_approx(card.settings.observe_seconds, 3.0), "Observe defaults to a three-second lifetime")
	card._process(2.8)
	check(card.visible and card.modulate.a < 1.0 and card.modulate.a > 0, "Observe fades near the end of its three-second lifetime")
	card.pin.button_pressed = true
	card._process(5.0)
	check(card.visible and card.modulate.a == 1.0, "Pin restores opacity and prevents observation expiry")
	var journal_before: Dictionary = world.persistent_state.snapshot()
	card.journal.pressed.emit()
	check(world.menu.opened and world.menu.selected == "guide" and world.menu.guide_context.key == first.id and world.journal_notes.text.begins_with(first.entry.name), "Journal opens the observed individual's entry directly")
	world.menu.guide_back.pressed.emit()
	check(world.menu.guide_context.is_empty() and world.persistent_state.snapshot() == journal_before, "All entries returns to the journal list without mutating the expedition")
	world.menu.close()
	card.pin.button_pressed = false
	card._process(3.01)
	check(not card.visible and world.inspected_cell == null, "Unpinned observation expires and clears its inspection target")
	open_on(scene, first)
	world.observation_menu.id_pressed.emit(0)
	card.set_process(true)
	for index in range(2):
		card.pin.button_pressed = true
		open_on(scene, first)
		world.observation_menu.id_pressed.emit(0)
	for frame in range(6):
		await process_frame
	card.arrange_stack(80)
	check(card.stacked_cards.size() == 2 and card.pin.text.is_empty() and card.pin.icon != null, "Repeated observations stack and use an icon pin")
	var previous_bottom := 80.0
	for stacked in card.stacked_cards + [card]:
		check(stacked.heading.size.y > 0 and not stacked.heading.text.is_empty(), "Every stacked observation retains a visible target heading")
		check(stacked.position.y >= previous_bottom and stacked.get_rect().end.y <= stacked.get_viewport_rect().size.y, "Observation stack flows down without overlap and stays within the screen")
		previous_bottom = stacked.get_rect().end.y
	if OS.get_cmdline_user_args().has("--capture-interactions") and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/interactions")
		root.get_texture().get_image().save_png("res://artifacts/interactions/observe-stack.png")
	var selected_cell: Variant = world.inspected_cell
	card.stacked_cards[0].dismiss()
	check(world.inspected_cell == selected_cell and card.stacked_cards.size() == 1, "Closing an older observation preserves the current target and other cards")
	for stacked in card.stacked_cards.duplicate():
		stacked.dismiss()
	if OS.get_cmdline_user_args().has("--capture-interactions") and DisplayServer.get_name() != "headless":
		for frame in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/interactions")
		root.get_texture().get_image().save_png("res://artifacts/interactions/observe.png")
	open_on(scene, first)
	world.observation_menu.id_pressed.emit(1)
	check(scene.encounters.active_target.id == first.id and world.encounter_active, "Engage uses the existing encounter preview for the selected identity")
	scene.encounters.withdraw()
	# Two species on one cell test disambiguation without rewriting durable homes.
	var species := SolSpeciesDefinition.new()
	species.species_id = "bramblepup"
	species.lineage_id = "family_001"
	species.class_id = "beast"
	var identity: String = world.persistent_state.register_individual(species, first.home, "air")
	check(not identity.is_empty(), "Overlapping-target fixture admits a separate persistent individual")
	var orb := SolOrb.new()
	orb.configure("air", scene.sightings.visual_settings)
	scene.sightings.add_child(orb)
	var label := Label3D.new()
	orb.add_child(label)
	var extra := {"id": identity, "home": first.home, "sprite": orb, "label": label,
		"entry": scene.sightings.ENTRIES[1], "visual_cell": Vector2(first.home), "motion": SolMotionTrack.new()}
	extra.motion.reset(first.home)
	scene.sightings.members.append(extra)
	scene.sightings.members_by_id[identity] = extra
	open_on(scene, first)
	check(world.context_actions[11].id == identity and world.context_actions[10].id == identity, "Overlapping Sols receive distinct named Engage and Observe actions")
	world.observation_menu.id_pressed.emit(11)
	check(scene.encounters.active_target.id == identity, "Choosing a second overlapping Sol never engages the first/nearest Sol")
	scene.encounters.withdraw()
	open_on(scene, first)
	world.persistent_state.acquire(identity, "party")
	world.observation_menu.id_pressed.emit(11)
	check(not world.encounter_active, "A stale acquired target cannot engage a replacement or a different Sol")
	world.cell = first.home + Vector2i(-6, 0)
	world.destination = world.cell
	world.explorer.position = world.center(world.cell)
	world.camera.position = world.explorer.position
	open_on(scene, first)
	check(world.observation_menu.is_item_disabled(world.observation_menu.get_item_index(1)), "Distant engagement stays visible with a disabled range hint")
	world.observation_menu.id_pressed.emit(1)
	check(not world.encounter_active, "Execution rechecks range even if an unavailable action is invoked")
	world.cell = first.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	first = scene.sightings.members[0]
	open_on(scene, first)
	world.new_expedition(42)
	world.context_action(1)
	check(not world.encounter_active, "World replacement invalidates an old context action")
	if OS.get_cmdline_user_args().has("--capture-interactions") and DisplayServer.get_name() != "headless":
		first = scene.sightings.members[0]
		world.cell = first.home + Vector2i.LEFT
		world.destination = world.cell
		world.rebuild_world()
		first = scene.sightings.members[0]
		for frame in range(30):
			await process_frame
		open_on(scene, first)
		for frame in range(4):
			await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/interactions")
		root.get_texture().get_image().save_png("res://artifacts/interactions/sol-menu.png")
	world.observation_menu.hide()
	scene.environment.sky = null
	scene.free()
	print("WORLD INTERACTIONS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
