extends SceneTree
const Library = preload("res://scripts/scenery/plant_library.gd")
var failures := 0
func _initialize() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	run.call_deferred()
func check(condition: bool,message: String) -> void:
	if not condition:
		failures+=1
		push_error(message)
func run() -> void:
	Engine.set_meta("workstation_session_path","res://artifacts/plant-maker/world-workspace.cfg")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	scene.world.paused=true
	scene._process(0.0)
	var before: Dictionary = scene.world.persistent_state.snapshot()
	var terrain: WorldTerrain = scene.world.terrain
	var cell: Vector2i = scene.world.cell
	var camera: Transform3D = scene.camera.transform
	var revision: int = scene.authored_plant_revision
	var switch: Node = scene.get_node("DevelopmentWorldToggle")
	switch.toggle_world()
	Library.refresh()
	switch.toggle_world()
	scene._process(0.0)
	check(scene.authored_plant_revision!=revision,"Library revision is adopted by the live view")
	check(scene.world.terrain==terrain and scene.world.cell==cell,"Library refresh preserves terrain and explorer identity")
	check(scene.world.persistent_state.snapshot()==before,"Scenery refresh cannot change the expedition or Vastra ledger")
	check(scene.camera.transform==camera,"Scenery refresh preserves the camera")
	scene.free()
	await process_frame
	print("PLANT MAKER WORLD: %d failures"%failures)
	quit(1 if failures else 0)
