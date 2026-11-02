extends SceneTree
var failures := 0
func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		push_error(description)
func _initialize() -> void:
	create_timer(600).timeout.connect(func() -> void: quit(2))
	run.call_deferred()
func run() -> void:
	var menu = load("res://scenes/start_menu.tscn").instantiate()
	root.add_child(menu)
	var monitor := Timer.new()
	monitor.wait_time = 5.0
	monitor.autostart = true
	root.add_child(monitor)
	monitor.timeout.connect(func() -> void:
		for node in root.get_children():
			if node.get_script() == load("res://scripts/application/start_menu.gd") and is_instance_valid(node.game):
				print("GATE progress=",node.completed," pending=",node.game.world.pending.size()," paused=",node.game.world.paused," flora=",node.game.world.flora_catalog.pending.size() if node.game.world.flora_catalog else -1))
	check(menu.game == null and not menu.loading, "Menu starts before world construction")
	menu.save_path = "user://missing-startup-fixture.json"
	await menu.begin(true)
	check(menu.game == null and not menu.loading and menu.actions.visible, "Invalid save returns to menu")
	await menu.begin(false)
	check(menu.entered and menu.rendering_prepared and menu.completed == 64 and menu.targets.size() == 64, "Exactly 64 requested terrain chunks are ready")
	check(menu.game.world.persistent_state.activity_seconds() == menu.loading_clock, "Loading spends no simulation time")
	check(menu.game.world.flora_catalog.pending.is_empty(), "Canonical flora admission finishes before entry")
	check(menu.registration_stages == ["plant", "tree", "connected"] and menu.game.world.startup_flora_definitions.is_empty(), "Ground plants register before trees and network activation")
	check(menu.game.sightings.members.size() > 0, "Wildlife is established")
	check(menu.game.active_view.chunk_work_ms == 1.0 and menu.game.active_view.chunks_per_frame == 1, "Gameplay generation uses bounded slow pace")
	var clock: float = menu.game.world.persistent_state.activity_seconds()
	for frame in range(3): await process_frame
	check(menu.game.world.persistent_state.activity_seconds() > clock, "Simulation begins after entry")
	menu.game.world.save_game("user://startup-fixture.json")
	var saved_clock: float = menu.game.world.persistent_state.activity_seconds()
	menu.free()
	await process_frame
	menu = load("res://scenes/start_menu.tscn").instantiate()
	root.add_child(menu)
	menu.save_path = "user://startup-fixture.json"
	await menu.begin(true)
	check(menu.entered and menu.completed == 64, "Saved expedition enters through the same terrain gate")
	check(is_equal_approx(menu.loading_clock, saved_clock) and menu.game.world.persistent_state.activity_seconds() == menu.loading_clock, "Saved clock remains frozen throughout loading")
	print("STARTUP GATE: 11 checks, ",failures," failures")
	menu.free()
	quit(0 if failures == 0 else 1)
