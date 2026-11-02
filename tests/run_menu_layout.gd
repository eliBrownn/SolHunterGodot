extends "res://tests/first_playable_battle.gd"
## Real readiness Run dialog under shared HUD typography and viewport changes.

func settle_layout() -> void:
	for frame in range(6): await process_frame

func run() -> void:
	root.gui_embed_subwindows = true
	root.size = Vector2i(1280, 800)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.menu.choose_starter(0)
	for member: Dictionary in scene.sightings.members:
		check(not member.label.visible, "Wild unit titles stay hidden")
	check(not scene.companion.caption.visible, "Companion title stays hidden")
	var controller: Node = scene.battles
	approach(world, scene)
	BattleTest.settle(controller)
	controller.select_cell(controller.session.deployment_tiles()[0])
	BattleTest.settle(controller)
	for side in controller.unit_views:
		check(controller.unit_views[side].sprite.find_children("*", "Label3D", false, false).is_empty(), "Battle units have no floating ALLY/WILD titles")
	var before: Dictionary = world.persistent_state.snapshot()
	for scale: float in [1.0, 2.0]:
		root.size = Vector2i(1280, 800) if scale == 1.0 else Vector2i(900, 600)
		world.menu.settings.text_scale = scale
		world.accessibility.set_text_scale(scale)
		await settle_layout()
		controller.request_retreat()
		world.accessibility.queue_update()
		await settle_layout()
		var dialog: ConfirmationDialog = controller.retreat_dialog
		check(dialog.visible and dialog.dialog_text.contains("withdrawal attempt"), "Run opens the real readiness withdrawal confirmation")
		for button: Button in [dialog.get_ok_button(), dialog.get_cancel_button()]:
			check(not button.text.is_empty() and button.is_visible_in_tree(), "Run confirmation actions have visible labels")
			var text_width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			check(button.autowrap_mode == TextServer.AUTOWRAP_OFF and button.size.x >= text_width + 8.0 and button.size.x > button.size.y and button.size.y < 80, "Confirmation buttons fit their labels as readable horizontal controls")
			check(Rect2(Vector2.ZERO, Vector2(dialog.size)).encloses(button.get_global_rect()), "Confirmation button fits within its dialog")
		if OS.get_cmdline_user_args().has("--capture-run-menu") and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			DirAccess.make_dir_recursive_absolute("res://artifacts/run-menu")
			root.get_texture().get_image().save_png("res://artifacts/run-menu/scale-%d.png" % int(scale))
		dialog.canceled.emit()
		dialog.hide()
	check(world.persistent_state.snapshot() == before, "Viewing and canceling Run never spends the readiness action")
	scene.free()
	print("RUN MENU LAYOUT: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
