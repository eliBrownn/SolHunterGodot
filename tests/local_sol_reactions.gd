extends SceneTree

class BlockedTerrain extends WorldTerrain:
	func can_step(_from: Vector2i, _to: Vector2i, _footprint: int = 1) -> bool:
		return false

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func put_player(world: Node2D, at: Vector2i) -> void:
	world.cell = at
	world.destination = at
	world.moving = false
	world.explorer.position = world.center(at)
	world.camera.position = world.explorer.position

func tick(world: Node2D) -> void:
	world.persistent_state.advance_time(0.75)

func run() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	scene.sighting_settings = SightingSettings.new()
	root.add_child(scene)
	var world: Node2D = scene.world
	var controller: Node3D = scene.sightings
	world.new_expedition(17)
	var member: Dictionary = controller.members[0]
	put_player(world, member.home + Vector2i.LEFT)
	tick(world)
	var state: ExpeditionState = world.persistent_state
	var moved: Vector2i = controller.current_cell(member)
	check(moved != member.home and state.roaming_view(member.id).action == "flee", "Avoidant Sol takes a real legal step away on the exploration clock")
	check(controller.manhattan(moved, world.cell) > 1 and world.terrain.can_step(member.home, moved), "Flight increases separation without crossing blocked terrain")
	member.sprite.visible = false
	controller.sync_views()
	check(member.visual_cell == Vector2(moved), "A reappearing view snaps to saved position instead of sliding from stale offscreen coordinates")
	check(state.individual_view(member.id).home == [member.home.x, member.home.y] and state.relationship_view(member.id) == null, "Movement changes neither fixed home identity nor unknown relationship")
	var before := state.snapshot()
	controller.advance_roaming(state.activity_tick())
	check(state.snapshot() == before, "The same activity tick cannot apply a second movement decision")
	world.rebuild_world()
	check(state.snapshot() == before and controller.current_cell(controller.members[0]) == moved, "Rebuilding the render view does not return a moved individual home")
	world.paused = true
	world._process(1.5)
	check(state.snapshot() == before, "Pause freezes local movement and cooldown time")
	world.paused = false
	for index in range(12):
		tick(world)
		var position: Vector2i = controller.current_cell(controller.members[0])
		check(controller.manhattan(position, member.home) <= 5 and world.terrain.fits(position) and position != world.cell, "Repeated local flight stays within legal home range without occupying the player")
	put_player(world, member.home + Vector2i(6, 0))
	for index in range(12):
		tick(world)
	check(controller.current_cell(controller.members[0]) == member.home, "Retreating beyond reaction range permits a legal return to home")
	world.new_expedition(17)
	member = controller.members[1]
	put_player(world, member.home + Vector2i(-3, 0))
	tick(world)
	moved = controller.current_cell(member)
	check(state != world.persistent_state and moved != member.home and world.persistent_state.roaming_view(member.id).action == "approach", "Neutral Sol approaches rather than fleeing")
	check(controller.manhattan(moved, world.cell) == scene.sighting_settings.comfort_distance, "Approach leaves the configured comfort distance")
	tick(world)
	check(controller.current_cell(member) == moved and world.persistent_state.roaming_view(member.id).action == "idle", "Neutral response rests at comfort distance")
	world.new_expedition(17)
	member = controller.members[2]
	put_player(world, member.home + Vector2i.LEFT)
	tick(world)
	check(controller.current_cell(member) == member.home and world.persistent_state.roaming_view(member.id).action == "guard", "Guarding Sol holds its ground without triggering battle")
	world.new_expedition(17)
	member = controller.members[0]
	put_player(world, member.home + Vector2i.LEFT)
	scene.sighting_settings.movement_interval_ticks = 3
	tick(world)
	tick(world)
	check(world.persistent_state.roaming_view(member.id).tick == -1, "Inspector movement cadence delays the initial decision for its full interval")
	tick(world)
	check(controller.current_cell(member) != member.home, "Configured movement cadence reaches the real simulation")
	scene.sighting_settings.movement_interval_ticks = 1
	scene.sighting_settings.movement_enabled = false
	before = world.persistent_state.snapshot()
	tick(world)
	check(world.persistent_state.snapshot().roaming == before.roaming, "Disabling local movement retains saved positions")
	scene.sighting_settings.movement_enabled = true
	world.new_expedition(17)
	member = controller.members[0]
	put_player(world, member.home + Vector2i.LEFT)
	world.terrain = BlockedTerrain.new(17)
	tick(world)
	check(controller.current_cell(member) == member.home, "A cornered Sol waits instead of teleporting through obstacles")
	world.new_expedition(17)
	member = controller.members[0]
	put_player(world, Vector2i(-100, -100))
	tick(world)
	check(world.persistent_state.snapshot().roaming.is_empty(), "Distant individuals do not acquire offscreen movement updates")
	put_player(world, member.home + Vector2i.LEFT)
	tick(world)
	world.smoke_mode = true
	state = world.persistent_state
	before = state.snapshot()
	var path := "user://local-sol-%d.json" % Time.get_ticks_usec()
	world.save_game(path)
	var original := FileAccess.get_file_as_string(path)
	world.new_expedition(42)
	world.load_game(path)
	check(world.persistent_state.snapshot() == before and world.persistent_state.counts().individuals == 3, "Actual load preserves positions, action ticks, and exactly three identities")
	controller.advance_roaming(world.persistent_state.activity_tick())
	check(world.persistent_state.snapshot() == before, "Reload cannot reapply an already serviced movement tick")
	var restored_cell: Vector2i = controller.current_cell(controller.members[0])
	put_player(world, restored_cell + Vector2i.LEFT)
	controller.observe_nearest()
	check(world.persistent_state.discovery_entries()[0].first_seen == [restored_cell.x, restored_cell.y], "Observation records the moved position rather than the fixed home")
	world.persistent_state.acquire(member.id, "party")
	check(world.persistent_state.roaming_view(member.id).is_empty() and not world.persistent_state.snapshot().roaming.has(member.id), "Acquisition retires only wild movement state while preserving the owned individual")
	verify_schema(before, original, path)
	var invalid: Dictionary = JSON.parse_string(original)
	var identity: String = invalid.world_state.roaming.keys()[0]
	invalid.world_state.roaming[identity].tick = invalid.world_state.activity_tick + 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid))
	file.close()
	var current: ExpeditionState = world.persistent_state
	var current_terrain: WorldTerrain = world.terrain
	var live_before := current.snapshot()
	world.load_game(path)
	check(world.persistent_state == current and world.terrain == current_terrain and current.snapshot() == live_before, "Malformed incoming movement cannot partially replace the live world")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(original)
	file.close()
	invalid = JSON.parse_string(original)
	var origin: Array = invalid.world_state.individuals[identity].home
	var blocked: Variant = null
	for y in range(-5, 6):
		for x in range(-5, 6):
			var cell := Vector2i(int(origin[0]) + x, int(origin[1]) + y)
			if absi(x) + absi(y) <= 5 and not world.terrain.fits(cell):
				blocked = cell
	check(blocked != null, "Blocked-position fixture exists within the legal saved home envelope")
	if blocked != null:
		invalid.world_state.roaming[identity].cell = [blocked.x, blocked.y]
		check(ExpeditionSave.write(invalid, path) == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == original, "Terrain-invalid saved positions reject despite structurally valid movement data")
	if OS.get_cmdline_user_args().has("--capture-movement") and DisplayServer.get_name() != "headless":
		world.new_expedition(17)
		member = controller.members[0]
		put_player(world, member.home + Vector2i.LEFT)
		world.rebuild_world()
		world.smoke_mode = false
		tick(world)
		controller.sync_views(1.0)
		world.smoke_mode = true
		DirAccess.make_dir_recursive_absolute("res://artifacts/roaming")
		for frame in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/roaming/flee.png")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	scene.free()
	print("LOCAL SOL REACTIONS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func verify_schema(snapshot: Dictionary, original: String, path: String) -> void:
	var seed_value := int(JSON.parse_string(original).seed)
	var old := snapshot.duplicate(true)
	old.version = 4
	old.erase("roaming")
	old.erase("battle")
	old.erase("movebooks")
	old.erase("affinity_tiles")
	old.erase("wild_population")
	var restored := ExpeditionState.restore(old, seed_value)
	check(restored != null and restored.snapshot().roaming.is_empty() and restored.snapshot().individuals == old.individuals, "Domain-v4 saves load at existing homes without invented movement history")
	var identity: String = snapshot.roaming.keys()[0]
	var malformed: Array[Dictionary] = []
	for field in ["cell", "tick", "action"]:
		var bad := snapshot.duplicate(true)
		bad.roaming[identity][field] = true
		malformed.append(bad)
	var bad := snapshot.duplicate(true)
	bad.roaming[identity].tick = snapshot.activity_tick + 1
	malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.roaming[identity].cell = [9999, 9999]
	malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.roaming["missing-id"] = bad.roaming[identity].duplicate(true)
	malformed.append(bad)
	bad = snapshot.duplicate(true)
	bad.individuals[identity].location = "party"
	malformed.append(bad)
	for data in malformed:
		check(ExpeditionState.restore(data, seed_value) == null, "Invalid, future, distant, orphan, or owned roaming state rejects before restoration")
		var save: Dictionary = JSON.parse_string(original)
		save.world_state = data
		check(ExpeditionSave.write(save, path) == ERR_INVALID_DATA and FileAccess.get_file_as_string(path) == original, "Malformed movement records cannot overwrite a valid slot")
