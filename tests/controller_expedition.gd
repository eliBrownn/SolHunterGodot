extends SceneTree
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0
var scene: Node3D
var world: Node2D
var pad: Node

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(180).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func settle() -> void:
	for frame in range(5):
		await process_frame

func raw(button: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	var popup: Window = pad.visible_popup()
	if popup != null:
		popup.push_input(event, true)
	else:
		root.push_input(event, true)

func press(action: String) -> void:
	var button: int = pad.settings.buttons[action]
	raw(button, true)
	raw(button, false)
	await settle()

func direction(button: int) -> void:
	raw(button, true)
	raw(button, false)
	await settle()

func axis(index: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = index
	event.axis_value = value
	var popup: Window = pad.visible_popup()
	if popup != null:
		popup.push_input(event, true)
	else:
		root.push_input(event, true)

func target_tile(target: Vector2i) -> void:
	for attempt in range(scene.battles.session.cells.size() + 1):
		if scene.battles.cursor == target:
			return
		await press("next")
	check(false, "Controller targeting can reach the chosen legal tile")

func choose(text: String) -> bool:
	for attempt in range(140):
		var surface: Node = pad.ui_root()
		pad.focus.ensure(surface)
		var selected: Control = pad.focus.current
		if selected is BaseButton and text in selected.text:
			await press("confirm")
			return true
		await direction(JOY_BUTTON_DPAD_DOWN)
	check(false, "Controller focus can reach " + text)
	return false

func focus_slider(label: String) -> void:
	for attempt in range(140):
		pad.focus.ensure(pad.ui_root())
		if pad.focus.current is HSlider and pad.focus.current.get_meta("pad_label", "") == label:
			return
		await direction(JOY_BUTTON_DPAD_DOWN)
	check(false, "Controller can reach slider " + label)

func popup_choice(text: String) -> bool:
	var popup: PopupMenu = pad.visible_popup()
	for attempt in range(popup.item_count + 1):
		var index := popup.get_focused_item()
		if index >= 0 and text in popup.get_item_text(index):
			await press("confirm")
			return true
		await direction(JOY_BUTTON_DPAD_DOWN)
	check(false, "Controller popup can reach " + text)
	return false

func run() -> void:
	root.gui_embed_subwindows = true
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	scene = load("res://scenes/world_3d.tscn").instantiate()
	scene.sighting_settings = SightingSettings.new()
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	world = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	pad = scene.gamepad
	pad.preferences_path = "user://controller-check-%d.cfg" % Time.get_ticks_usec()
	pad.settings = ControllerSettings.new()
	pad.settings.install_actions()
	world.menu.settings.remember_layout = false
	world.menu.settings.text_scale = 1
	world.menu.reset_layout()
	world.menu.save_path = "user://controller-expedition-%d.json" % Time.get_ticks_usec()
	await settle()
	var state: ExpeditionState = world.persistent_state
	var before := state.snapshot()
	axis(JOY_AXIS_LEFT_X, 0.1)
	check(not pad.active and pad.movement_vector() == Vector2.ZERO, "Sub-deadzone drift cannot claim the controller or move the player")
	axis(JOY_AXIS_LEFT_X, 0.8)
	check(pad.active and pad.movement_vector().x > 0.5, "Analog stick activates radial, camera-relative movement")
	axis(JOY_AXIS_LEFT_X, 0)
	world.smoke_mode = false
	var initial_cell: Vector2i = world.cell
	axis(JOY_AXIS_LEFT_X, 1)
	await create_timer(float(world.expedition_parameters().move_seconds) * 2.3).timeout
	axis(JOY_AXIS_LEFT_X, 0)
	await create_timer(float(world.expedition_parameters().move_seconds) * 1.1).timeout
	check(world.cell != initial_cell and not world.moving, "Controller stick walking traverses the real expedition and settles after release")
	world.smoke_mode = true
	await press("menu")
	check(world.menu.opened and not world.paused, "Controller Menu opens the live field menu")
	axis(JOY_AXIS_LEFT_X, 1)
	check(pad.movement_vector() == Vector2.ZERO, "Menu navigation never leaks into player movement")
	var menu_cell: Vector2i = world.cell
	var menu_tick: int = world.persistent_state.activity_tick()
	world.smoke_mode = false
	await create_timer(0.85).timeout
	world.smoke_mode = true
	check(world.cell == menu_cell and world.persistent_state.activity_tick() > menu_tick, "Controller menu navigation blocks walking while exploration time remains live")
	axis(JOY_AXIS_LEFT_X, 0)
	await choose("Choose Bramblepup")
	check(not state.active_sol_view().is_empty() and not world.menu.opened, "Starter comparison and actual acquisition work with controller focus")
	var hero := state.active_sol_view()
	var reward := state.begin_battle(scene.sightings.members[2].id)
	check(state.complete_battle(reward, hero.hp, "victory", 0, {}, {"participated": true, "contributed": true, "enemy_level": 15}), "Existing outcome authority provides the personal-training fixture")
	await press("menu")
	await choose("Training")
	await choose("+1")
	check(state.stat_view(hero.id).training.max_hp == 1, "Controller training allocation invokes the real owned-Sol command")
	await choose("Moves")
	var book_before := state.movebook(hero.id)
	await choose("1 ·")
	check(pad.visible_popup() is PopupMenu, "Controller opens the actual move equipment dropdown")
	await popup_choice("Strike")
	check(state.movebook(hero.id) == book_before, "Controller confirms an equipment choice through the native dropdown")
	await choose("Options")
	await focus_slider("Stick deadzone")
	var old_deadzone: float = pad.settings.deadzone
	await direction(JOY_BUTTON_DPAD_RIGHT)
	check(pad.settings.deadzone > old_deadzone, "Controller adjusts a settings slider through focus navigation")
	await focus_slider("Text size")
	for increment in range(20):
		await direction(JOY_BUTTON_DPAD_RIGHT)
	check(world.menu.settings.text_scale == 2, "Controller can enable whole-HUD 200 percent text")
	check(pad.prompts.size.y < 64, "Enlarged controller prompts stay on one compact readable line")
	await choose("Controller guide")
	check(pad.detail_window.visible and pad.detail_text.text.contains("Triggers"), "Controller guide and non-hover detail window are accessible")
	await press("back")
	check(not pad.detail_window.visible and world.menu.opened, "Back closes only the top detail layer")
	await choose("Button bindings")
	await choose("Choose / interact")
	check(pad.listening == "confirm", "Controller remapping is reachable without a mouse")
	raw(JOY_BUTTON_RIGHT_SHOULDER, true)
	raw(JOY_BUTTON_RIGHT_SHOULDER, false)
	await settle()
	check(pad.settings.buttons.confirm == JOY_BUTTON_RIGHT_SHOULDER and pad.settings.buttons.next == JOY_BUTTON_A, "Conflicting button bindings swap without losing an action")
	var loaded := ControllerSettings.new()
	check(loaded.load_preferences(pad.preferences_path) and loaded.buttons == pad.settings.buttons, "Controller preferences survive a fresh settings instance")
	var saved_buttons := loaded.buttons.duplicate()
	var corrupt := ConfigFile.new()
	corrupt.load(pad.preferences_path)
	corrupt.set_value("controller", "deadzone", NAN)
	corrupt.save(pad.preferences_path)
	check(not loaded.load_preferences(pad.preferences_path) and loaded.buttons == saved_buttons, "Malformed controller preferences reject atomically")
	await choose("Reset controller settings")
	check(pad.settings.buttons == ControllerSettings.DEFAULT_BUTTONS, "Default controls can be restored entirely with the remapped controller")
	await choose("Button bindings")
	await choose("Save")
	before = state.snapshot()
	await choose("Save expedition")
	check(not ExpeditionSave.read_save(world.menu.save_path).is_empty(), "Controller Save writes the actual current expedition")
	await choose("New expedition")
	check(world.confirmation.visible, "Controller new-expedition action opens a confirmation")
	check(pad.focus.current == world.confirmation.get_cancel_button(), "Consequential confirmation initially selects Cancel")
	await press("back")
	check(not world.confirmation.visible and world.persistent_state == state, "Controller cancellation preserves the expedition")
	await choose("Load expedition")
	var after_load: Dictionary = world.persistent_state.snapshot()
	var clock_matches := absf(float(after_load.remainder_seconds) - float(before.remainder_seconds)) <= 0.000000001
	after_load.remainder_seconds = before.remainder_seconds # JSON floating-point round-trip tolerance only.
	check(after_load == before and clock_matches and not world.menu.opened, "Controller Load restores state through existing save admission")
	state = world.persistent_state
	await press("pause")
	check(world.paused and world.pause_panel.visible, "Dedicated controller pause freezes exploration")
	await choose("Resume")
	check(not world.paused, "Pause Resume is controller reachable")
	before = state.snapshot()
	await press("details")
	check(world.inspection_card.visible and world.inspection_card.metrics.visible and state.snapshot() == before, "World Details exposes full readings without hover or gameplay mutation")
	await press("back")
	check(not world.inspection_card.visible, "Back dismisses world inspection")
	pad.target_id = "unavailable-controller-target"
	before = state.snapshot()
	await press("confirm")
	check(not world.observation_menu.visible and state.snapshot() == before, "A stale controller identity cannot silently select another Sol or record a replacement")
	pad.target_id = ""
	var old_camera: float = scene.view_azimuth
	axis(JOY_AXIS_RIGHT_X, 1)
	pad._process(0.2)
	axis(JOY_AXIS_RIGHT_X, 0)
	check(scene.view_azimuth != old_camera and state.snapshot() == before, "Controller camera orbit is read-only")
	await press("reset_camera")
	check(is_equal_approx(scene.view_azimuth, scene.camera_azimuth), "Controller camera reset is connected")
	# Place the trainer near a known individual; all encounter/battle commands remain controller-only.
	var identity: String = scene.sightings.members[0].id
	world.cell = scene.sightings.members[0].home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	pad.target_cell = world.cell
	pad.target_id = ""
	pad.target_manual = false
	await press("targets")
	check(pad.target_id == identity, "Target cycling locks a specific visible Sol identity")
	await press("confirm")
	check(world.observation_menu.visible, "Controller Interact opens the existing context actions")
	await popup_choice("Observe")
	check(state.has_discovery(identity), "Controller observation records the actual targeted individual")
	await press("confirm")
	await popup_choice("Engage")
	check(world.encounter_active and scene.encounters.active_target.id == identity, "Controller Engage respects the selected identity")
	await choose("Battle")
	var battle: Node = scene.battles
	check(battle.session != null, "Controller starts the existing encounter battle")
	if battle.session == null:
		quit(1)
		return
	BattleTest.settle(battle)
	await press("next")
	await press("confirm")
	BattleTest.settle(battle)
	check(battle.session.phase == "active", "Controller target cycling and confirmation deploy the Sol")
	var cell: Vector2i = battle.session.ally_cell
	var remaining: int = battle.session.remaining
	await press("next")
	await press("confirm")
	BattleTest.settle(battle)
	check(battle.session.ally_cell != cell and battle.session.remaining < remaining, "Controller tile targeting moves through the authoritative shared budget")
	before = state.snapshot()
	await press("targets")
	check(pad.ui_root() == battle.combat_hud.tray and pad.movement_vector() == Vector2.ZERO, "Battle action focus is separate from world/tile movement")
	await press("details")
	check(pad.detail_window.visible and pad.detail_text.text.contains("Strike") and state.snapshot() == before, "Move information including unavailable actions is readable without hover")
	axis(JOY_AXIS_RIGHT_Y, 1)
	pad._process(1.0)
	axis(JOY_AXIS_RIGHT_Y, 0)
	check(pad.detail_text.get_parent().scroll_vertical > 0, "Controller right stick scrolls long non-hover move details")
	await press("back")
	await press("targets") # Return from the action ribbon to tile targeting.
	# Approach through real controller tile commands until the existing Strike is legal.
	for turn in range(6):
		if not battle.legal_targets(0).is_empty():
			break
		var closest: Vector2i = battle.session.ally_cell
		for at: Vector2i in battle.session.reachable():
			if TacticalBattle.distance(at, battle.session.enemy_cell) < TacticalBattle.distance(closest, battle.session.enemy_cell):
				closest = at
		if closest != battle.session.ally_cell:
			await target_tile(closest)
			await press("confirm")
			BattleTest.settle(battle)
		if battle.legal_targets(0).is_empty():
			await press("targets")
			await choose("End turn")
			BattleTest.settle(battle)
			await press("targets")
	var enemy_hp: int = battle.session.enemy_hp
	await press("targets")
	await choose("Strike")
	check(battle.aimed_slot == 0 and battle.session.enemy_hp == enemy_hp, "Controller move selection arms an authoritative preview without executing it")
	await press("back")
	check(battle.aimed_slot == -1 and battle.session.enemy_hp == enemy_hp, "Controller Back cancels aiming without spending an action")
	await press("targets")
	await choose("Strike")
	await press("confirm")
	var pending: Dictionary = battle.playback.current.duplicate(true)
	await press("details")
	battle.advance_resolution(10)
	check(battle.playback.current == pending and pad.detail_window.visible, "Controller battle Details suspends presentation without advancing consequences")
	await press("back")
	BattleTest.settle(battle)
	check(battle.session != null and battle.session.enemy_hp < enemy_hp, "A second explicit controller confirmation executes the selected attack")
	check(battle.capture_button.text == "Seal %.0f%% · %d AP" % [battle.session.capture_chance() * 100, battle.session.seal_action_points], "Device prompts never overwrite the live capture chance or cost")
	before = state.snapshot()
	await press("targets")
	await choose("More")
	await choose("Battle log")
	check(battle.combat_hud.log_panel.visible and state.snapshot() == before, "Controller battle log is read-only and reachable through More")
	await press("targets")
	await press("back")
	check(battle.battle_menu.visible and battle.session != null, "Back opens the battle menu without directly retreating")
	await choose("Retreat")
	check(battle.retreat_dialog.visible, "Controller retreat requires a confirmation")
	var confirm_button: int = pad.settings.buttons.confirm
	raw(confirm_button, true)
	raw(confirm_button, true)
	raw(confirm_button, false)
	await settle()
	check(battle.session != null, "An opening/held press cannot accidentally confirm retreat")
	if not battle.retreat_dialog.visible:
		await press("back")
		await choose("Retreat")
	await direction(JOY_BUTTON_DPAD_UP)
	await press("confirm")
	BattleTest.settle(battle)
	check(battle.session == null and state.battle_progress().retreats == 1, "Explicit controller confirmation commits retreat once")
	await choose("Continue exploring")
	check(not battle.feedback_view.result_panel.visible, "Controller can dismiss the result recap")
	await press("confirm")
	await popup_choice("Engage")
	await choose("Battle")
	BattleTest.settle(battle)
	await press("next")
	await press("confirm")
	BattleTest.settle(battle)
	var seal_battle: TacticalBattle = battle.session
	await press("targets")
	await choose("Seal ")
	BattleTest.settle(battle)
	check(seal_battle.capture_attempts == 1, "Controller Seal action executes exactly one real capture attempt")
	if battle.session != null:
		await press("menu")
		await choose("Retreat")
		await direction(JOY_BUTTON_DPAD_UP)
		await press("confirm")
		BattleTest.settle(battle)
	if battle.feedback_view.result_panel.visible:
		await choose("Continue exploring")
	axis(JOY_AXIS_LEFT_X, 1)
	pad.connection_changed(0, false)
	check(not pad.active and pad.movement_vector() == Vector2.ZERO and pad.held.is_empty(), "Disconnect clears movement, held buttons and repeat state")
	await press("menu")
	check(pad.active and world.menu.opened, "A fresh press can reconnect to menu navigation")
	await press("back")
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(10, 0)
	root.push_input(mouse, true)
	check(not pad.active and battle.attack_button.focus_mode == Control.FOCUS_NONE, "Mouse takeover restores desktop tactical-focus isolation")
	if OS.get_cmdline_user_args().has("--capture-controller") and DisplayServer.get_name() != "headless":
		await press("menu")
		await choose("Options")
		DirAccess.make_dir_recursive_absolute("res://artifacts/controller")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/controller/options.png")
	for path in [pad.preferences_path, world.menu.save_path, world.menu.save_path + ".bak", world.menu.save_path + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	scene.environment.sky = null
	scene.free()
	await settle()
	print("CONTROLLER EXPEDITION: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
