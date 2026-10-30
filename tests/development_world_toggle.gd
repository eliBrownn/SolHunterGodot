extends SceneTree
## The temporary lab is isolated; a return restores the same in-memory expedition.
var failures := 0
var checks := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	create_timer(90).timeout.connect(func(): quit(1))
	run.call_deferred()
func run() -> void:
	root.size = Vector2i(1440, 900)
	var workspace_path := "res://artifacts/development-workstation/roundtrip-%d.cfg" % Time.get_ticks_usec()
	Engine.set_meta("workstation_session_path", workspace_path)
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var switch: Node = scene.get_node("DevelopmentWorldToggle")
	check(not switch.in_lab and switch.lab == null, "Normal play does not instantiate the lab until requested")
	var snapshot: Dictionary = scene.world.persistent_state.snapshot()
	var saved_cell: Vector2i = scene.world.cell
	var saved_camera: Transform3D = scene.camera.transform
	var saved_hud: bool = scene.world.hud.visible
	var sentinel := GPUParticles3D.new()
	sentinel.speed_scale = 0.7
	scene.add_child(sentinel)
	var sound := AudioStreamPlayer.new()
	sound.stream = AudioStreamGenerator.new()
	scene.add_child(sound)
	sound.play()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F8
	key.pressed = true
	switch._input(key)
	check(switch.in_lab and switch.lab != null, "F8 enters the development lab world")
	check(switch.lab.viewport.own_world_3d, "The lab renders in a separate World3D")
	check(scene.process_mode == Node.PROCESS_MODE_DISABLED and not scene.visible and not scene.world.hud.visible, "Expedition processing and HUD are suspended")
	check(sentinel.speed_scale == 0.0 and sound.stream_paused, "Hidden expedition particles and audio are suspended")
	for frame in range(4): await process_frame
	check(scene.world.persistent_state.snapshot() == snapshot and scene.world.cell == saved_cell, "Lab time cannot advance or alter the expedition")
	check(scene.camera.transform == saved_camera, "Lab camera cannot move the expedition camera")
	var fixture: Node = switch.lab.fixture
	fixture.controls["Opacity"].value = 0.25
	switch.lab.notes.text = "Retain these lab notes"
	switch.lab.set_paused(true)
	# A gameplay-backed fixture uses the established workstation save/load guard.
	check(fixture.get_meta("development_workstation", false), "Fixtures retain workstation isolation metadata")
	if "--capture-lab-world" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/development-world")
		root.get_texture().get_image().save_png("res://artifacts/development-world/lab.png")
	switch.switch_button.pressed.emit()
	check(not switch.in_lab and not switch.lab.visible and not switch.lab_layer.visible, "Return button removes the lab and backdrop")
	check(scene.process_mode == Node.PROCESS_MODE_INHERIT and scene.visible and scene.world.hud.visible == saved_hud, "Original processing and visibility are restored")
	check(is_equal_approx(sentinel.speed_scale, 0.7) and not sound.stream_paused, "Original particle and audio states are restored")
	check(scene.world.persistent_state.snapshot() == snapshot, "Returning keeps the exact expedition state")
	switch.toggle_world()
	check(switch.lab.fixture == fixture and switch.lab.notes.text == "Retain these lab notes", "A second visit retains the lab instance and notes")
	check(is_equal_approx(fixture.controls["Opacity"].value, 0.25) and switch.lab.paused, "Lab tuning and pause choice survive a round trip")
	var names: Array = switch.lab.FIXTURES.keys()
	switch.lab.picker.select(names.find("World / cohesive sample"))
	switch.lab.overrides.clear()
	switch.lab.load_fixture()
	var hosted: Node3D = switch.lab.fixture
	check(hosted.world.in_development_workstation(), "Gameplay-backed lab worlds keep the save/load guard")
	check(not hosted.has_node("DevelopmentWorldToggle"), "Hosted game fixtures do not create nested lab switches")
	var forbidden := "res://artifacts/development-world/forbidden-%d.json" % Time.get_ticks_usec()
	hosted.world.save_game(forbidden)
	check(not FileAccess.file_exists(forbidden), "Lab worlds cannot write an expedition save")
	switch.toggle_world()
	check(scene.world.persistent_state.snapshot() == snapshot, "Repeated toggles cannot mutate expedition state")
	check(switch.sol_lab == null, "Sol Lab is created only when requested")
	key.physical_keycode = KEY_F9
	switch._input(key)
	check(switch.in_sol_lab and not switch.in_lab and switch.sol_lab != null, "F9 opens the separate Sol Lab from normal play")
	var sol: Control = switch.sol_lab
	check(sol.viewport.own_world_3d, "Sol Lab owns its preview world")
	check(scene.process_mode == Node.PROCESS_MODE_DISABLED and not scene.visible and not scene.world.hud.visible, "Sol Lab suspends the expedition and HUD")
	check(sentinel.speed_scale == 0.0 and sound.stream_paused, "Sol Lab suspends expedition effects and audio")
	sol.name_field.text = "Round-trip draft"
	sol.notes.text = "Keep this Sol draft between game visits"
	sol.checkpoint()
	sol.document.head_size = 0.8
	sol.sync_controls()
	sol.generate_variations()
	var recipe: Dictionary = sol.document.duplicate(true)
	var variants: Array = sol.candidates.duplicate(true)
	for frame in range(4): await process_frame
	check(scene.world.persistent_state.snapshot() == snapshot and scene.world.cell == saved_cell, "Sol Lab cannot advance expedition state")
	if "--capture-lab-world" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/development-world/sol-lab.png")
	switch.sol_button.pressed.emit()
	check(not switch.in_sol_lab and not sol.visible and not switch.sol_layer.visible, "Sol Lab return button hides its workspace")
	check(scene.visible and scene.world.hud.visible == saved_hud and scene.process_mode == Node.PROCESS_MODE_INHERIT, "Returning from Sol Lab restores gameplay")
	check(is_equal_approx(sentinel.speed_scale, 0.7) and not sound.stream_paused, "Returning from Sol Lab restores effects and audio")
	switch.toggle_sol_lab()
	check(switch.sol_lab == sol and sol.document == recipe and sol.candidates == variants, "Second visit retains Sol draft, notes and generated batch")
	switch.toggle_world()
	check(switch.in_lab and not switch.in_sol_lab and not sol.visible, "F8 can switch directly from Sol Lab to Development Lab")
	switch.toggle_sol_lab()
	check(switch.in_sol_lab and not switch.in_lab and not switch.lab.visible, "F9 can switch directly from Development Lab to Sol Lab")
	switch.toggle_sol_lab()
	check(scene.world.persistent_state.snapshot() == snapshot and scene.camera.transform == saved_camera, "Cross-lab visits preserve expedition and camera")
	scene.free()
	Engine.remove_meta("workstation_session_path")
	if FileAccess.file_exists(workspace_path): DirAccess.remove_absolute(workspace_path)
	await process_frame
	print("DEVELOPMENT WORLD: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
