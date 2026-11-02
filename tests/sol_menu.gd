extends SceneTree
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()
func settle() -> void:
	for frame in range(5):
		await process_frame
func gui_click(at: Vector2) -> void:
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
	var menu: Node = world.menu
	menu.settings.remember_layout = false
	menu.reset_layout()
	menu.open("sols")
	check(menu.sol_tab == "details", "The information-rich Sol overview is the default instead of the sparse quick summary")
	var before: Dictionary = world.persistent_state.snapshot()
	check(menu.sol_screen.starter_mode and menu.sol_screen.entries.size() == 3, "Starter comparison offers all authored companions")
	await settle()
	gui_click(menu.sol_screen.entries["2"].get_global_rect().get_center())
	await settle()
	check(menu.sol_screen.preview.profile.species_id == "rillfin" and before == world.persistent_state.snapshot(), "Starter inspection changes the model without granting a companion")
	menu.sol_screen.set_tab("details")
	await settle()
	check(menu.sol_screen.tabs.has("details") and state_is_unchanged(world, before), "Starter details remain available without inventing individual stats or committing a choice")
	if captures():
		await capture("starter")
	menu.sol_screen.set_tab("summary")
	menu.choose_starter(0)
	var state: ExpeditionState = world.persistent_state
	var hero: Dictionary = state.active_sol_view()
	var species := SolSpeciesDefinition.new()
	species.species_id = "seedmote"
	species.lineage_id = "family_010"
	species.class_id = "verdant"
	var identity := state.register_individual(species, Vector2i(100, 0), "water")
	state.admit_movebook(identity, scene.move_library.book("seedmote"))
	state.record_sol_discovery(identity, "Seedmote", "Watched beside the refuge.", Vector2i(100, 0))
	var profile: Dictionary = scene.battle_settings.opponents[1].snapshot()
	profile.affinity = "water"
	var serial := state.begin_battle(identity)
	check(state.complete_battle(serial, hero.hp, "captured", 0, {}, {"capture": {"profile": profile, "hp": 10, "unlocks": {}}}), "Fixture admits a second companion through existing capture authority")
	menu.open("sols")
	menu.sol_screen.inspect(identity)
	await settle()
	before = state.snapshot()
	check(state.active_sol_view().id == hero.id and menu.sol_selection == identity, "Inspecting a companion never changes the active battler")
	check(menu.sol_screen.preview.model.affinity == "water" and menu.sol_screen.preview.viewport.own_world_3d, "Preview uses the individual's actual affinity in an isolated 3D world")
	check(not world.paused and menu.sol_screen.preview.model.mesh == null and menu.sol_screen.preview.model.has_method("sync_locomotion") and not menu.sol_screen.preview.model.halo.visible, "Live menu shows the actual creature model without an orb or pausing exploration")
	menu.sol_screen.preview._process(0.25)
	check(state.snapshot() == before, "Model animation and camera fitting cannot mutate saved state")
	for aspect in [Vector2(360, 160), Vector2(160, 260)]:
		var preview: SubViewportContainer = menu.sol_screen.preview
		preview.size = aspect
		preview.fit_model()
		check(preview.camera.size >= preview.model.tuning.diameter * 2, "Preview leaves framing margin for model and effects at aspect %s" % aspect)
	menu.sol_screen.activate()
	check(state.active_sol_view().id == identity, "Explicit active action selects exactly the inspected companion")
	menu.sol_screen.transfer()
	await settle()
	check(state.individual_view(identity).location == "storage" and menu.sol_selection == identity and menu.sol_filter == "storage", "Transfer preserves inspected identity and follows it to storage")
	check(menu.sol_screen.use_button.disabled and state.active_sol_view().id == hero.id, "Stored Sol cannot deploy and existing authority chooses a party companion")
	menu.sol_screen.transfer()
	await settle()
	check(state.individual_view(identity).location == "party", "Bring into party uses the existing safe transfer command")
	menu.sol_screen.set_tab("moves")
	await settle()
	check(scene.battles.loadout.identity == identity and scene.battles.loadout.embedded_section == "moves", "Moves tab edits the inspected Sol rather than the active Sol")
	var options: OptionButton
	for node in scene.battles.loadout.embedded_rows.get_children():
		if node is OptionButton:
			options = node
			break
	check(options != null and not options.get_popup().get_item_tooltip(1).is_empty(), "Remembered moves explain their effects before equipment")
	menu.sol_screen.set_tab("training")
	await settle()
	check(scene.battles.loadout.embedded_section == "training", "Training tab retains the existing stats and allocation controls")
	before = state.snapshot()
	menu.sol_screen.set_tab("details")
	await settle()
	var info: Dictionary = menu.sol_screen.information
	check(info.has("Identity") and info.Identity.contains("Water") and info.Identity.contains(SolSpeciesCatalog.class_display_name(state.individual_view(identity).class_id)), "Details reports the selected individual's actual affinity and current class display name")
	check(info["Individual stats"].contains("Attack: %d" % state.companion_view(identity).profile.attack) and info["Individual stats"].contains("IV"), "Detailed stats use saved resolved values and individual potential")
	check(info["Training capacity"].contains("Unspent:") and info["Health and progression"].contains("XP remaining"), "Details explains training budgets and next-level progress")
	check(info.has("Class ability") and info["Class ability"].contains(scene.battle_settings.class_buffs.definition("verdant").description), "Class ability includes its actual authored effect")
	var equipped: String = state.movebook(identity).equipped[0]
	check(info["Equipped moves"].contains(scene.move_library.find(equipped).name) and info["Equipped moves"].contains("Range:"), "Equipped moves retain full effect and range explanations")
	check(info["Field notes"].contains("100, 0") and info["Field notes"].contains("Watched beside the refuge."), "Details shows actual recorded sighting evidence")
	check(info["Relationship record"].contains("No trust rating") and state.snapshot() == before, "Unknown trust stays unknown and browsing extensive details remains read-only")
	check(menu.sol_screen.info_groups.size() == 5 and info.has("Combat profile") and info.has("Loadout coverage"), "Dossier categories make combat, growth, moves and history directly accessible")
	menu.sol_screen.info_groups.growth.pressed.emit()
	await settle()
	var traits := state.stat_view(identity)
	var projected := SolStats.resolve(traits, int(state.companion_view(identity).profile.level) + 1)
	check(menu.sol_info_section == "growth" and menu.sol_screen.information["Growth projection"].contains("Attack: %d → %d" % [state.companion_view(identity).profile.attack, projected.attack]), "Growth projection uses the same saved-stat resolver as progression")
	check(menu.sol_screen.information["Individual potential"].contains("Highest IV:") and menu.sol_screen.information["Individual potential"].contains("Saved potential range:"), "Potential comparisons describe the individual's saved rolls and policy")
	if captures():
		await capture("growth")
	menu.sol_screen.info_groups.combat.pressed.emit()
	await settle()
	check(menu.sol_screen.information["Loadout coverage"].contains("/ 4 slots") and menu.sol_screen.information["Class ability"].contains("Current battle healing cap:"), "Combat dossier explains equipped capabilities and current passive limits")
	if captures():
		await capture("combat-info")
	menu.sol_screen.info_groups.history.pressed.emit()
	await settle()
	check(menu.sol_info_section == "history" and state.snapshot() == before, "Changing information categories never changes saved state")
	menu.sol_screen.info_groups.overview.pressed.emit()
	await settle()
	check(menu.sol_screen.information["Affinity and moves"].contains("Water") and menu.sol_screen.information["Readiness"].contains("Missing HP:"), "Overview connects individual affinity, move affinities and readiness")
	if captures():
		await capture("details")
	menu.sol_screen.set_tab("summary")
	await settle()
	check(menu.sol_screen.preview.tooltip_text.contains("class") and menu.sol_screen.preview.tooltip_text.contains("XP") and menu.sol_screen.preview.tooltip_text.contains("Attack") and not menu.sol_screen.entries[identity].tooltip_text.is_empty(), "Secondary companion information is available on hover")
	if captures():
		await capture("summary")
		var motion := InputEventMouseMotion.new()
		motion.position = menu.sol_screen.preview.get_global_rect().get_center()
		motion.global_position = motion.position
		root.push_input(motion, true)
		await create_timer(0.8).timeout
		await capture("hover")
	menu.sol_screen.detail_scroll.scroll_vertical = 50
	menu.close()
	menu.open("sols")
	await settle()
	check(menu.sol_selection == identity and menu.sol_tab == "summary", "Reopening the menu retains inspection and selected tab")
	menu.select_page("options")
	menu.text_slider.value = 200
	check(menu.settings.text_scale == 2, "Text-size control adjusts personal screens immediately")
	menu.select_page("sols")
	await settle()
	menu.apply_text_size()
	check(menu.title.get_theme_font_size("font_size") == 37 and menu.frame.theme.get_font_size("font_size", "TooltipLabel") == 23, "Personal screens and hover details share enlarged typography without compounding")
	menu.apply_text_size()
	check(menu.title.get_theme_font_size("font_size") == 37 and menu.sol_screen.stacked.visible, "Repeated text application stays stable and selects the compact layout")
	for window_size in [Vector2i(900, 600), Vector2i(700, 900)]:
		root.size = window_size
		await settle()
		menu.fit_layout()
		var bounds := Rect2(menu.frame.position, menu.frame.size * menu.frame.scale)
		check(bounds.end.x <= menu.frame.get_viewport_rect().size.x and bounds.end.y <= menu.frame.get_viewport_rect().size.y, "Large-text companion screen remains bounded at %s" % window_size)
		if captures():
			await capture("large-%dx%d" % [window_size.x, window_size.y])
	# Optional text preference validates atomically and remains compatible with v1 files.
	var path := "user://sol-menu-%d.cfg" % Time.get_ticks_usec()
	menu.preferences_path = path
	menu.settings.remember_layout = true
	menu.save_preferences()
	menu.settings.text_scale = 1
	check(menu.load_preferences() and menu.settings.text_scale == 2, "Text preference round-trips separately from expedition state")
	var bad := ConfigFile.new()
	bad.load(path)
	bad.set_value("menu", "text_scale", NAN)
	bad.save(path)
	check(not menu.load_preferences() and menu.settings.text_scale == 2, "Malformed text preference rejects atomically")
	menu.settings.remember_layout = false
	menu.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	world.new_expedition(42)
	check(menu.sol_selection.is_empty(), "New expedition clears old inspection identity")
	scene.free()
	print("SOL MENU: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
func captures() -> bool:
	return OS.get_cmdline_user_args().has("--capture-sol-menu") and DisplayServer.get_name() != "headless"
func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/sol-menu")
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/sol-menu/" + name + ".png")

func state_is_unchanged(world: Node2D, snapshot: Dictionary) -> bool:
	return world.persistent_state.snapshot() == snapshot
