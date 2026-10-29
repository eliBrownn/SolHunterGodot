extends "res://tools/profile_current_expedition.gd"
## Normal F5 journey plus input/menu, real battle outcomes and persistent ownership.
## No smoke mode, teleports, HP/loadout edits, injected capture rolls or speed-up.
var connected := {"checks": [], "battles": [], "capture_rolls": [], "unsupported": ["Peaceful acquisition", "Live relationship consequences", "Owned flight/swimming", "Authored Vastra disturbance example"]}
var initialized_review := false
var selected_identity := ""
var owned_facts: Dictionary = {}
var normal_travel_ready := false
var moving_camera_phase := 0

func _initialize() -> void:
	root.gui_embed_subwindows = true
	if root.get_property_list().any(func(row: Dictionary) -> bool: return row.name == "unfocusable"):
		root.set("unfocusable", true)
	create_timer(600).timeout.connect(func() -> void:
		push_error("Connected expedition timed out")
		quit(1))
	run.call_deferred()

func record(value: bool, description: String) -> void:
	connected.checks.append({"passed": value, "description": description})
	check(value, description)
	print("CONNECTED CHECK: %s · %s" % ["PASS" if value else "FAIL", description])
	if not value:
		var output := FileAccess.open(output_directory + "/failed-review.json", FileAccess.WRITE)
		if output != null: output.store_string(JSON.stringify(connected, "\t"))
		quit(1)

func observe() -> void:
	super.observe()
	if not normal_travel_ready or not world.moving or world.paused or world.encounter_active: return
	if moving_camera_phase == 0 and world.cell.x >= 14:
		var before: float = scene.view_azimuth
		var middle := InputEventMouseButton.new()
		middle.button_index = MOUSE_BUTTON_MIDDLE
		middle.position = root.get_visible_rect().size * Vector2(0.5, 0.6)
		middle.pressed = true
		root.push_input(middle, true)
		var motion := InputEventMouseMotion.new()
		motion.position = middle.position
		motion.relative = Vector2(160, 10)
		motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
		root.push_input(motion, true)
		middle.pressed = false
		root.push_input(middle, true)
		moving_camera_phase = 1
		record(not is_equal_approx(before, scene.view_azimuth), "Middle-drag changes the camera while real-time walking remains active")
	elif moving_camera_phase == 1 and world.cell.x >= 20:
		var home := InputEventKey.new()
		home.physical_keycode = KEY_HOME
		home.pressed = true
		root.push_input(home, true)
		home.pressed = false
		root.push_input(home, true)
		moving_camera_phase = 2
		record(is_equal_approx(scene.view_azimuth, scene.camera_azimuth), "Home resets the view during the same uninterrupted walking journey")

func capture(name: String) -> void:
	if name == "refuge" and not initialized_review:
		initialized_review = true
		report.method = "Normal F5 real-time input-action travel, unchanged AI/clock/contacts; synthetic joypad/native UI plus existing battle commands, real paced resolution and actual deterministic capture seeds. No HP/terrain/loadout/roll replacement. Controlled pilot/outcome suites remain separate. Screenshots/waits are included in diagnostic wall times; not owner/device acceptance."
		report["connected_review"] = connected
		world.menu.preferences_path = output_directory + "/menu.cfg"
		world.menu.save_path = output_directory + "/menu-save.json"
		world.menu.settings = world.menu.settings.duplicate(false)
		world.menu.settings.remember_layout = false
		world.menu.settings.text_scale = 1
		scene.gamepad.preferences_path = output_directory + "/controller.cfg"
		scene.gamepad.settings = ControllerSettings.new()
		scene.gamepad.settings.install_actions()
		record(world.terrain.generation_version == 7 and scene.sightings.settings.species_profiles_enabled and scene.sightings.settings.movement_enabled and scene.sightings.settings.wilderness_enabled, "Generation 7 and normal species profiles, movement and wilderness remain enabled")
		await personal_controls()
		await camera_controls()
		await encounter_cases()
		await dismiss_result()
		if world.cell != Vector2i.ZERO:
			connected["preflight_return"] = await traverse(Vector2i.ZERO)
		scene.battles.recover()
		await settle(20)
		owned_facts = identity_facts()
		record(not world.smoke_mode and world.persistent_state.active_sol_view().id == selected_identity, "Normal live play resumes with the same selected companion")
		normal_travel_ready = true
	if name == "restored":
		record(identity_facts() == owned_facts and world.persistent_state.active_sol_view().id == selected_identity, "Every owned identity, affinity, IV and movebook survives the complete return/save/new/load journey")
		record(scene.companion.identity == selected_identity, "Following presentation reconstructs the same selected owned individual")
		record(moving_camera_phase == 2, "The completed outbound/return journey included in-motion camera rotation and reset")
		await pad_press("menu")
		await choose("Save")
		await choose("Save expedition")
		record(not ExpeditionSave.read_save(world.menu.save_path).is_empty(), "Controller saves the completed normal expedition through the actual menu")
		await choose("Load expedition")
		record(identity_facts() == owned_facts and world.returned, "Controller menu load preserves the completed journey and all owned identities")
		await pad_press("back")
		await desktop_takeover()
		connected["final_progress"] = world.persistent_state.battle_progress()
	await super.capture(name)

func identity_facts() -> Dictionary:
	var result := {}
	for identity in world.persistent_state.collection_view().owned:
		var row: Dictionary = world.persistent_state.individual_view(identity)
		result[identity] = {"species": row.species_id, "lineage": row.lineage_id, "class": row.class_id, "affinity": row.affinity, "ivs": world.persistent_state.stat_view(identity).ivs, "moves": world.persistent_state.movebook(identity)}
	return result

func route(target: Vector2i) -> Array[Vector2i]:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(-28, -36, 144, 73)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for y in range(grid.region.position.y, grid.region.end.y):
		for x in range(grid.region.position.x, grid.region.end.x):
			var at := Vector2i(x, y)
			var blocked: bool = world.persistent_state.environment_view(at, {}).get("conditions", {}).has("barrier")
			grid.set_point_solid(at, blocked or not world.terrain.fits(at))
	return grid.get_id_path(world.cell, target)

func pad_button(code: int) -> void:
	for down in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = 0
		event.button_index = code
		event.pressed = down
		var popup: Window = scene.gamepad.visible_popup()
		if popup != null:
			popup.push_input(event, true)
		else:
			root.push_input(event, true)
	await settle(3)

func pad_press(action: String) -> void:
	await pad_button(scene.gamepad.settings.buttons[action])

func choose(label: String) -> bool:
	for attempt in range(180):
		scene.gamepad.focus.ensure(scene.gamepad.ui_root())
		var control: Control = scene.gamepad.focus.current
		if is_instance_valid(control) and control is BaseButton and label in control.text:
			await pad_press("confirm")
			return true
		await pad_button(JOY_BUTTON_DPAD_DOWN)
	record(false, "Controller focus reaches " + label)
	return false

func desktop_takeover() -> void:
	var event := InputEventMouseMotion.new()
	event.relative = Vector2(12, 0)
	root.push_input(event, true)
	await settle(2)

func personal_controls() -> void:
	await pad_press("menu")
	record(world.menu.opened and not world.paused, "Controller opens the live menu during normal AI")
	await choose("Sols")
	await choose("Rillfin")
	await choose("Choose Rillfin")
	var active: Dictionary = world.persistent_state.active_sol_view()
	record(not active.is_empty(), "Controller starter comparison acquires an actual individual")
	if active.is_empty(): return
	selected_identity = active.id
	await settle(20)
	record(scene.companion.identity == active.id and scene.companion.placed, "Normal F5 presents the actual selected companion using its documented legacy orb fallback")
	await pad_press("menu")
	await choose("Options")
	var at: Vector2i = world.cell
	var tick: int = world.persistent_state.activity_tick()
	var axis := InputEventJoypadMotion.new()
	axis.device = 0
	axis.axis = JOY_AXIS_LEFT_X
	axis.axis_value = 1
	root.push_input(axis, true)
	await create_timer(0.85).timeout
	axis.axis_value = 0
	root.push_input(axis, true)
	record(world.cell == at and world.persistent_state.activity_tick() > tick, "Controller menu input blocks walking while normal world time continues")
	await capture("normal-controller-options")
	await pad_press("details")
	record(scene.gamepad.detail_window.visible, "Controller details are available without hovering")
	await pad_press("back")
	await pad_press("back")
	await pad_press("details")
	record(world.inspection_card.visible, "Controller terrain inspection opens in the live world")
	await capture("normal-inspection")
	await pad_press("back")
	await pad_press("pause")
	tick = world.persistent_state.activity_tick()
	await create_timer(0.85).timeout
	record(world.paused and world.persistent_state.activity_tick() == tick, "Controller true pause freezes the normal activity clock")
	await pad_press("back")
	await desktop_takeover()
	record(not scene.gamepad.active and not world.paused, "Desktop takeover resumes normal exploration")

func camera_controls() -> void:
	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.position = root.get_visible_rect().size * 0.5
	middle.pressed = true
	root.push_input(middle, true)
	var original: float = scene.view_azimuth
	for shift in [Vector2(400, -80), Vector2(-800, 0), Vector2(400, 80)]:
		var motion := InputEventMouseMotion.new()
		motion.relative = shift
		motion.position = middle.position
		motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
		root.push_input(motion, true)
		await settle(4)
		record(is_equal_approx(scene.environment.fog_depth_end, scene.active_view.render_distance - 4), "Live camera reversal retains a distant fixed fog horizon")
	middle.pressed = false
	root.push_input(middle, true)
	record(is_equal_approx(scene.view_azimuth, original), "Middle-drag traverses both orbit directions and returns")
	for code in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_UP]:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = code
		wheel.position = middle.position
		wheel.pressed = true
		root.push_input(wheel, true)
		await settle(3)
	var home := InputEventKey.new()
	home.physical_keycode = KEY_HOME
	home.pressed = true
	root.push_input(home, true)
	await settle(4)
	record(is_equal_approx(scene.target_size, scene.active_view.starting_distance), "Home restores the configured camera distance after wheel zoom")

func approach(member: Dictionary) -> bool:
	for attempt in range(6):
		await handle_route_contact()
		if not world.persistent_state.wild_available(member.id): return false
		var at: Vector2i = scene.sightings.current_cell(member)
		if SolRoamingPolicy.distance(world.cell, at) <= scene.encounters.settings.interaction_distance and not world.moving:
			scene.encounters.approach_individual(member.id)
			if world.encounter_active: return true
		var best: Vector2i = world.cell
		var closest := INF
		for y in range(-3, 4):
			for x in range(-3, 4):
				var candidate := at + Vector2i(x, y)
				if absi(x) + absi(y) != 2 or not world.terrain.fits(candidate): continue
				var distance := Vector2(candidate - world.cell).length_squared()
				if distance < closest:
					closest = distance
					best = candidate
		await traverse(best)
	return false

func ready() -> void:
	var deadline := Time.get_ticks_msec() + 30000
	while scene.battles.session != null and (scene.battles.playback.busy or not scene.battles.commander_ready()):
		if Time.get_ticks_msec() > deadline:
			record(false, "Real-time battle playback completes")
			return
		await process_frame

func begin(member: Dictionary) -> bool:
	if not await approach(member):
		record(false, "Selected moving individual remains reachable for engagement")
		return false
	scene.encounters.observe_target()
	scene.encounters.battle_button.pressed.emit()
	await ready()
	var controller: Node = scene.battles
	if controller.session == null:
		record(false, "Existing encounter admits a real tactical battle")
		scene.encounters.withdraw()
		return false
	var tiles: Array[Vector2i] = controller.session.deployment_tiles()
	tiles.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return controller.session.distance(a, controller.session.enemy_cell) < controller.session.distance(b, controller.session.enemy_cell))
	controller.select_cell(tiles[0])
	await ready()
	record(controller.session != null and controller.session.phase == "active", "Real-time commander arrival and deployment activate the battle")
	return controller.session != null

func move_closer() -> void:
	var controller: Node = scene.battles
	if controller.session == null: return
	var battle: TacticalBattle = controller.session
	var best: Vector2i = battle.ally_cell
	for at: Vector2i in battle.reachable():
		if battle.distance(at, battle.enemy_cell) < battle.distance(best, battle.enemy_cell): best = at
	if best != battle.ally_cell:
		controller.select_cell(best)
		await ready()

func use_move(slot: int, target_enemy: bool) -> bool:
	var controller: Node = scene.battles
	if controller.session == null: return false
	var targets: Array[Vector2i] = controller.legal_targets(slot)
	if targets.is_empty(): return false
	var target: Vector2i = controller.session.enemy_cell if target_enemy else controller.session.ally_cell
	if not targets.has(target): target = targets[0]
	controller.choose_move(slot)
	controller.select_cell(target)
	await ready()
	return true

func dismiss_result() -> void:
	if scene.battles.feedback_view.result_panel.visible:
		await pad_press("back")
	await desktop_takeover()

func encounter_cases() -> void:
	var first: Dictionary = scene.sightings.members[0]
	var second: Dictionary = scene.sightings.members[1]
	if await approach(first):
		scene.encounters.observe_target()
		record(world.persistent_state.has_discovery(first.id), "Face-to-face observation records the actual moving individual")
		await capture("normal-observation")
		scene.encounters.withdraw()
		record(not world.encounter_active and not world.paused, "Face-to-face withdrawal resumes the same expedition")
	if await begin(first):
		await move_closer()
		var direct := await use_move(0, true)
		record(direct, "Normal equipped direct move executes through preview and target commands")
		var field := await use_move(1, false)
		record(field, "Normal equipped current changes terrain through the existing field authority")
		await capture("normal-battle-actions")
		if scene.battles.session != null:
			scene.battles.request_retreat()
			await pad_button(JOY_BUTTON_DPAD_UP)
			await pad_press("confirm")
			await ready()
			record(scene.battles.session == null and world.persistent_state.battle_progress().last_result.outcome == "retreat", "Controller-confirmed retreat commits once after real paced consequences")
			connected.battles.append(world.persistent_state.battle_progress().last_result)
	await dismiss_result()
	await traverse(Vector2i.ZERO)
	scene.battles.recover()
	if await begin(first):
		await move_closer()
		await use_move(0, true)
		for attempt in range(20):
			var battle: TacticalBattle = scene.battles.session
			if battle == null: break
			if battle.ally_hp < int(battle.ally.max_hp) * 0.6:
				await use_move(2, false)
				if scene.battles.session == null: break
			connected.capture_rolls.append({"seed": battle.capture_seed, "attempt": battle.capture_attempts, "chance": battle.capture_chance(), "enemy_id": first.id})
			scene.battles.capture_button.pressed.emit()
			await ready()
		var progress: Dictionary = world.persistent_state.battle_progress()
		connected.battles.append(progress.last_result)
		record(progress.last_result.outcome == "captured" and not world.persistent_state.companion_view(first.id).is_empty(), "Actual seeded Seal attempts acquire the same individual without overriding odds, HP or rolls")
		await capture("normal-seal-result")
	await dismiss_result()
	await traverse(Vector2i.ZERO)
	scene.battles.recover()
	if await begin(second):
		for turn in range(80):
			if scene.battles.session == null: break
			scene.battles.wait_button.pressed.emit()
			await ready()
		var progress: Dictionary = world.persistent_state.battle_progress()
		connected.battles.append(progress.last_result)
		record(progress.last_result.outcome == "exhaustion" and world.cell == Vector2i.ZERO and world.persistent_state.active_sol_view().hp == 0, "Normal opponent actions cause recoverable exhaustion and return the same companion to refuge")
		await capture("normal-exhaustion")
	await dismiss_result()
	scene.battles.recover()
	record(world.persistent_state.active_sol_view().hp > 0, "Existing refuge recovery restores the exhausted party without changing identities")
