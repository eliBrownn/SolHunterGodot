extends SceneTree
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(150).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func settle() -> void:
	for frame in range(8):
		await process_frame

func click(button: Control) -> void:
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = button.get_global_rect().get_center()
		event.global_position = event.position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		root.push_input(event, true)

func reveal(control: Control) -> void:
	for repeat in range(2):
		var ancestor := control.get_parent()
		while ancestor != null:
			if ancestor is ScrollContainer:
				ancestor.ensure_control_visible(control)
			ancestor = ancestor.get_parent()
		await settle()

func visible_rect(control: Control) -> Rect2:
	var rect := control.get_global_rect().intersection(control.get_viewport_rect())
	var ancestor := control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents:
			rect = rect.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return rect

func training_button(menu: Node, action: String) -> Button:
	for button in menu.frame.find_children("*", "Button", true, false):
		if button.get_meta("training_action", "") == action:
			return button
	return null

func check_reachable(control: Control, message: String) -> void:
	var rect := visible_rect(control)
	check(control.is_visible_in_tree() and rect.has_point(control.get_global_rect().get_center()) and rect.size.y >= control.get_global_rect().size.y - 1 and rect.size.x >= control.get_global_rect().size.x - 1, message + " bounds=%s visible=%s shown=%s" % [control.get_global_rect(), rect, control.is_visible_in_tree()])

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var menu: Node = world.menu
	menu.settings.remember_layout = false
	menu.settings.text_scale = 1
	menu.reset_layout()
	menu.open("sols")
	menu.choose_starter(0)
	var state: ExpeditionState = world.persistent_state
	var hero := state.active_sol_view()
	var serial := state.begin_battle(scene.sightings.members[0].id)
	check(state.complete_battle(serial, hero.hp, "victory", 0, {}, {"participated": true, "contributed": true, "enemy_level": 25}), "Training fixture earns points through existing outcome authority")
	menu.open("sols")
	menu.sol_screen.set_tab("training")
	await settle()
	var original_max: int = state.active_sol_view().profile.max_hp
	var add := training_button(menu, "max_hp:10")
	check(add != null and not add.disabled, "Earned HP training is available")
	await reveal(add)
	add.grab_focus()
	click(add)
	await settle()
	var focus := root.gui_get_focus_owner()
	check(focus != null and focus.get_meta("training_action", "") == "max_hp:10", "Rebuilding training preserves an available focused action")
	add = training_button(menu, "max_hp:10")
	await reveal(add)
	click(add)
	await settle()
	var trained := state.active_sol_view()
	check(trained.profile.max_hp > original_max and menu.sol_screen.selected_profile.max_hp == trained.profile.max_hp, "Training refreshes the surrounding selected profile without changing tabs")
	check(menu.sol_screen.entries[hero.id].text.contains("%d/%d" % [trained.hp, trained.profile.max_hp]), "Roster HP refreshes with the same committed training values")
	var health: Array[Node] = menu.sol_screen.detail.find_children("*", "ProgressBar", true, false)
	check(not health.is_empty() and health[0].max_value == trained.profile.max_hp and health[0].value == trained.hp, "The surrounding health meter refreshes without healing")
	focus = root.gui_get_focus_owner()
	check(focus == menu.sol_screen.tabs.training, "An exhausted allocation action returns focus to the Training tab")
	var reset := training_button(menu, "reset")
	await reveal(reset)
	click(reset)
	await settle()
	for window in world.hud.get_children():
		if window is ConfirmationDialog and window.get_meta("field_menu_owned", false):
			window.confirmed.emit()
	await settle()
	check(state.active_sol_view().profile.max_hp == original_max and menu.sol_screen.selected_profile.max_hp == original_max, "Confirmed retraining refreshes the whole selected Sol display")
	menu.select_page("options")
	menu.text_slider.value = 200
	await settle()
	check(is_equal_approx(menu.settings.base_text_multiplier, 0.715), "Default interface typography increases the compact baseline by 10%")
	check(world.objective.get_theme_font_size("font_size") == 24 and scene.atmosphere_controller.status.get_theme_font_size("font_size") == 20, "The text preference scales exploration objectives and atmosphere HUD")
	check(scene.encounters.description.get_theme_font_size("font_size") == 24 and scene.battles.feedback_view.result_text.get_theme_font_size("font_size") == 21, "Encounter and result text share the same preference")
	check(world.observation_menu.get_theme_font_size("font_size") == 23, "Right-click menu text shares the preference")
	for size in [Vector2i(1280, 800), Vector2i(640, 400), Vector2i(800, 1000)]:
		root.size = size
		await settle()
		for section in ["sols", "bag", "trainer", "save", "options"]:
			menu.select_page(section)
			await settle()
			if section == "options":
				var slider_rows: Node = menu.text_slider.get_parent()
				var heading: HBoxContainer = slider_rows.get_child(menu.text_slider.get_index() - 1)
				var value_label: Label = heading.get_child(1)
				check(value_label.get_line_count() == 1 and value_label.size.x > 30, "Settings values remain readable on one line in %s" % size)
			if section == "sols":
				menu.sol_screen.set_tab("training")
				await settle()
				var last := training_button(menu, "reset")
				await reveal(last)
				check_reachable(last, "Training's final action is reachable at 200 percent text in %s" % size)
		for button in menu.navigation.values():
			await reveal(button)
			check_reachable(button, "Personal navigation remains reachable in %s" % size)
		if captures():
			await capture("personal-%dx%d" % [size.x, size.y])
	menu.close()
	world.toggle_pause()
	await settle()
	var resume: Button = world.pause_panel.find_children("*", "Button", true, false)[0]
	check_reachable(resume, "Enlarged pause/resume control fits")
	click(resume)
	check(not world.paused, "Actual enlarged Resume click returns to exploration")
	var target: Dictionary = scene.sightings.members[1]
	var target_id: String = target.id
	world.cell = target.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	for member in scene.sightings.members:
		if member.id == target_id:
			target = member
	scene.encounters.approach_individual(target_id)
	if scene.encounters.active_target.is_empty():
		print("Approach diagnostic: target=%s cell=%s current=%s flags=%s/%s/%s config=%s sightings=%s candidates=%s" % [target.id, world.cell, scene.sightings.current_cell(target), world.paused, world.moving, world.confirmation.visible, scene.encounters.settings.valid(), scene.sighting_settings.valid(), scene.encounters.candidates(3)])
	await settle()
	await reveal(scene.encounters.battle_button)
	check_reachable(scene.encounters.battle_button, "Enlarged encounter Battle action is reachable")
	click(scene.encounters.battle_button)
	await settle()
	var controller: Node = scene.battles
	check(controller.session != null, "Actual enlarged encounter button starts the existing battle")
	if controller.session == null:
		print("Encounter diagnostic: active=%s paused=%s target=%s panel=%s" % [world.encounter_active, world.paused, scene.encounters.active_target, scene.encounters.encounter_panel.get_rect()])
		quit(1)
		return
	var battle: TacticalBattle = controller.session
	BattleTest.settle(controller)
	controller.select_cell(battle.deployment_tiles()[0])
	BattleTest.settle(controller)
	await settle()
	var before := state.snapshot()
	var hud: CombatHud = controller.combat_hud
	check(controller.move_buttons[0].get_theme_font_size("font_size") == 19, "Combat move text scales without reducing the preference")
	menu.settings.text_scale = 1
	menu.apply_text_size()
	root.size = Vector2i(1280, 800)
	await settle()
	check(hud.top.size.y < 90 and hud.tray.size.y < 125, "Normal combat uses a compact health strip and action ribbon")
	check(not hud.status_label.visible and not hud.intent_label.visible and not hud.cards.enemy.metadata.visible, "Routine instructions and secondary metadata do not occupy the battlefield")
	if captures():
		await capture("combat-compact")
	menu.settings.text_scale = 2
	menu.apply_text_size()
	for size in [Vector2i(1280, 800), Vector2i(640, 400), Vector2i(800, 1000)]:
		root.size = size
		await settle()
		await reveal(controller.wait_button)
		check_reachable(controller.wait_button, "Combat End turn remains reachable at 200 percent text in %s" % size)
		check(hud.top.get_rect().end.y < hud.tray.position.y, "Enlarged combat controls preserve a visible battlefield in %s" % size)
	controller.open_battle_menu()
	await settle()
	for button in [hud.retreat_button, hud.log_toggle]:
		await reveal(button)
		check_reachable(button, "Secondary combat action %s is reachable through More" % button.text)
	await reveal(hud.log_toggle)
	click(hud.log_toggle)
	await settle()
	check(hud.log_panel.visible and state.snapshot() == before, "Actual enlarged Battle log click opens readable information without spending an action")
	if captures():
		await capture("combat-large")
	controller.open_battle_menu()
	await settle()
	var modal_buttons: Array[Node] = controller.battle_menu.find_children("*", "Button", true, false)
	await reveal(modal_buttons[-1])
	check_reachable(modal_buttons[-1], "The final battle-menu action remains reachable")
	controller.close_battle_menu()
	controller.retreat()
	BattleTest.settle(controller)
	await settle()
	var result_panel: PanelContainer = controller.feedback_view.result_panel
	check(controller.feedback_view.result_text.size.x > 200 and controller.feedback_view.result_text.get_line_count() < 60, "Result recap uses readable lines inside its scroll area at enlarged text")
	check(controller.visuals.get_child_count() == 0, "Battle completion removes tactical tiles and unit visuals")
	var continue_button: Button = result_panel.find_children("*", "Button", true, false)[0]
	await reveal(continue_button)
	check_reachable(continue_button, "The result recap can be dismissed at enlarged text")
	if captures():
		await capture("result-readable")
	click(continue_button)
	check(not result_panel.visible, "Actual enlarged Continue click dismisses the result")
	menu.settings.text_scale = 1
	menu.apply_text_size()
	await settle()
	check(world.objective.get_theme_font_size("font_size") == 12 and controller.move_buttons[0].get_theme_font_size("font_size") == 9, "Returning to normal text restores the smaller baseline without compounding")
	scene.environment.sky = null
	scene.free()
	await settle()
	print("UI PLAYTEST BLOCKERS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func captures() -> bool:
	return OS.get_cmdline_user_args().has("--capture-blockers") and DisplayServer.get_name() != "headless"

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/playtest-blockers")
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/playtest-blockers/" + name + ".png")
