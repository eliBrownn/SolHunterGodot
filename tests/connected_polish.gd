extends SceneTree
## One focused fixture: presentation, controller focus, story decisions and real save/load.
const BattleTest = preload("res://tests/battle_test_support.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	root.gui_embed_subwindows = true
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	root.unfocusable = true
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func settle(frames: int = 3) -> void:
	for frame in frames:
		await process_frame

func run() -> void:
	var first: StoryEvent = load("res://resources/story_preview/arrival.tres")
	var follow_up: StoryEvent = load("res://resources/story_preview/follow_up.tres")
	check(first.valid() and follow_up.valid(), "Inspector-authored dialogue fixtures validate")
	var state := ExpeditionState.new(17)
	check(not state.record_story_choice(follow_up, "finish"), "Unavailable event cannot commit a choice")
	check(not state.record_story_choice(first, "unknown") and state.story_view() == StoryLedger.empty(), "Unknown choice cannot partially mutate facts")
	check(state.record_story_choice(first, "acknowledge"), "Explicit decision commits its facts")
	check(not state.record_story_choice(first, "acknowledge"), "Completed event cannot be replayed or duplicate its effects")
	var view := state.story_view()
	view.facts.clear()
	check(state.story_view().facts.has("preview.read"), "Story views cannot mutate persistent state")
	var malformed := state.snapshot()
	malformed.story.decisions[first.id].tick = -1
	check(ExpeditionState.restore(malformed, 17) == null, "Malformed story save rejects before live-state replacement")
	var scene: Node3D = load("res://scenes/story_workshop.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	await settle()
	check(world.menu.save_path.begins_with("res://artifacts/story-preview/"), "Writing preview uses a separate save destination")
	var before: Dictionary = world.persistent_state.snapshot()
	check(scene.story.play(first) and world.paused, "Dialogue opens over the real expedition and suspends active time")
	if DisplayServer.get_name() != "headless":
		check(scene.story.window.size.x >= 320 and scene.story.window.size.y >= 200, "Dialogue sizes from the game display rather than the hidden simulation viewport")
	var previous: Vector2i = world.cell
	world.advance_movement(1, Vector2.RIGHT)
	check(world.cell == previous, "Dialogue cannot move the trainer")
	scene.story.window.hide()
	check(not world.paused and world.persistent_state.snapshot() == before, "Leaving dialogue resumes play without a saved decision")
	check(not scene.story.play(follow_up), "Conditional follow-up stays locked before acknowledgment")
	check(scene.story.play(first), "Unanswered dialogue can reopen")
	var pad: Node = scene.gamepad
	check(pad.visible_popup() == scene.story.window, "Existing controller router discovers dialogue automatically")
	pad.focus.ensure(scene.story.window)
	check(pad.focus.current is Button and pad.focus.current.text == "Leave for now", "Controller opens dialogue on Leave rather than selecting a consequence")
	pad.focus.move(scene.story.window, Vector2i.DOWN)
	pad.focus.activate(scene.story.window)
	check(not world.paused and world.persistent_state.story_view().facts.get("preview.read") == "yes", "Controller selection records a decision through the same persistent authority")
	check(scene.story.play(follow_up), "Recorded fact enables follow-up dialogue")
	check(scene.story.select("finish"), "Follow-up records its own stable decision")
	var old_surface := VBoxContainer.new()
	var empty_surface := VBoxContainer.new()
	world.hud.add_child(old_surface)
	world.hud.add_child(empty_surface)
	var stale := Button.new()
	old_surface.add_child(stale)
	var activations := [0]
	stale.pressed.connect(func() -> void: activations[0] += 1)
	pad.focus.ensure(old_surface)
	pad.focus.activate(empty_surface)
	check(activations[0] == 0 and pad.focus.current == null, "Empty controller pages cannot activate a previous page's button")
	var slider := HSlider.new()
	slider.editable = false
	empty_surface.add_child(slider)
	check(pad.focus.ensure(empty_surface).is_empty(), "Controller skips read-only sliders")
	old_surface.queue_free()
	empty_surface.queue_free()
	scene.view_elevation = 10
	scene.target_size = scene.active_view.maximum_distance
	scene.apply_camera()
	var camera_at: Vector2 = world.camera.position / 32 + Vector2(scene.camera.position.x, scene.camera.position.z)
	check(scene.camera.position.y >= world.terrain.surface_height(camera_at) + scene.active_view.ground_clearance - 0.0001, "Low camera stays above terrain")
	scene.camera_dragging = true
	scene.get_window().focus_exited.emit()
	check(not scene.camera_dragging, "Window focus loss releases orbit drag")
	scene.reset_camera()
	var species: SolSpeciesRecord = load("res://resources/sol_species/crown_ear.tres")
	check(world.persistent_state.choose_starter(species.battle_profile("air"), 0), "Connected fixture admits a real catalog companion")
	scene.companion._process(0.1)
	var companion: Node3D = scene.companion
	check(companion.sprite != null and companion.placed, "Selected companion appears in the expedition")
	var bounds: AABB = companion.sprite.preview_bounds()
	check(is_equal_approx(companion.caption.position.y, companion.sprite.position.y + bounds.end.y + companion.settings.caption_clearance), "Caption follows actual species height")
	check(not companion.caption.text.contains("Resting nearby"), "Routine caption stays short")
	var save_path := "res://artifacts/connected-polish/expedition.json"
	var expected: Dictionary = world.persistent_state.story_view()
	var identity: String = world.persistent_state.active_sol_view().id
	world.save_game(save_path)
	check(not ExpeditionSave.read_save(save_path).is_empty(), "Normal save writer accepts story and companion state")
	world.new_expedition(7)
	check(world.persistent_state.story_view() == StoryLedger.empty(), "New expedition clears story facts")
	world.load_game(save_path)
	check(world.persistent_state.story_view() == expected and world.persistent_state.active_sol_view().id == identity, "Actual file load restores choices and the same owned individual")
	scene.companion._process(0.1)
	var target: Dictionary = scene.sightings.members[0]
	world.cell = scene.sightings.current_cell(target) + Vector2i.LEFT
	world.destination = world.cell
	world.explorer.position = world.center(world.cell)
	world.camera.position = world.explorer.position
	scene.encounters.approach_individual(target.id)
	scene.encounters.battle_button.pressed.emit()
	var controller: Node = scene.battles
	check(controller.session != null, "Existing expedition encounter starts tactical combat")
	if controller.session != null:
		BattleTest.settle(controller)
		controller.select_cell(controller.session.deployment_tiles()[0])
		BattleTest.settle(controller)
		var battle: TacticalBattle = controller.session
		controller.aimed_slot = -1
		battle.actions_remaining = 0
		battle.remaining = 0
		controller.update_view()
		check(controller.combat_hud.target_label.visible and controller.combat_hud.target_label.text.contains("End turn"), "Spent battle budget visibly explains how to continue")
		check(not controller.combat_hud.status_label.visible and not controller.combat_hud.intent_label.visible, "Combat retains the compact HUD")
		if DisplayServer.get_name() != "headless":
			await settle(5)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/connected-polish/combat.png")
		controller.request_retreat()
		controller.retreat_dialog.confirmed.emit()
		BattleTest.settle(controller)
		controller.feedback_view.result_panel.hide()
	if DisplayServer.get_name() != "headless":
		# Reuse the same rendered scene for dialogue layout inspection.
		world.new_expedition(17)
		check(scene.story.play(first), "Writing preview reopens in a fresh expedition after battle")
		await settle(5)
		await RenderingServer.frame_post_draw
		check(scene.story.window.visible, "Dialogue remains open until the player leaves or chooses")
		root.get_texture().get_image().save_png("res://artifacts/connected-polish/dialogue.png")
		scene.story.window.hide()
	scene.queue_free()
	await settle()
	print("Connected polish: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
