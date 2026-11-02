extends SceneTree
## Actual game-scene review captures. Isolated in-memory expedition; no save writes.

const OUTPUT := "res://artifacts/elevated_terrain"
var scene: Node3D
var world: Node2D

func _initialize() -> void:
	create_timer(150).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Elevated terrain captures require a real renderer")
		quit(1)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	scene = load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	world = scene.world
	world.smoke_mode = true
	world.new_expedition(2601026)
	await visit(Vector2i.ZERO, "refuge")
	scene.view_elevation = 22
	scene.view_azimuth = -65
	scene.apply_camera()
	await visit(Vector2i(32, world.terrain.trail_y(32)), "rolling_trail")
	var shore := Vector2i.ZERO
	for y in range(20, 80):
		for x in range(20, 80):
			var at := Vector2i(x, y)
			if world.terrain.natural_ground(at) == WorldTerrain.Ground.SAND and world.terrain.fits(at):
				shore = at
				break
		if shore != Vector2i.ZERO:
			break
	scene.view_elevation = 35
	scene.view_azimuth = 160
	scene.apply_camera()
	await visit(shore, "pond")
	scene.reset_camera()
	await visit(world.terrain.landmark() + Vector2i.LEFT * 3, "waystone")
	var member: Dictionary = scene.sightings.members[1]
	for candidate in scene.sightings.members:
		if not candidate.entry.has("home") and candidate.entry.x == 26:
			member = candidate
			break
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_individual(member.id)
	scene.encounters.battle_button.pressed.emit()
	if scene.battles.choosing:
		scene.battles.choose(0)
	if scene.battles.session == null:
		push_error("Elevated capture could not enter the live battle")
		scene.environment.sky = null
		scene.free()
		quit(1)
		return
	scene.battles.select_cell(scene.battles.session.deployment_tiles()[0])
	scene.battles.frame_battle()
	await settle()
	await shot("battle")
	scene.environment.sky = null
	scene.free()
	print("ELEVATED TERRAIN: refuge, rolling trail, pond, waystone and battle captured in " + OUTPUT)
	quit()

func settle() -> void:
	for frame in range(200):
		if world.pending.is_empty():
			break
		await process_frame
	scene.update_horizon(2.0)
	for frame in range(8):
		await process_frame

func visit(cell: Vector2i, name: String) -> void:
	world.cell = cell
	world.destination = cell
	world.rebuild_world()
	scene.sightings.admit_nearby(Vector2i.ZERO, cell)
	await settle()
	await shot(name)

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUTPUT + "/" + name + ".png")
	if error != OK:
		push_error("Could not write elevated capture: " + name)
