extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var scene: Node3D = (load("res://scenes/world_3d.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var visuals: SolVisualSettings = scene.sol_visual_settings
	check(visuals.valid() and scene.sightings.visual_settings == visuals, "Scene Inspector resource drives the live shared orb presentation")
	var members: Array = scene.sightings.members
	var grove: SolOrb = members[0].sprite
	var gale: SolOrb = members[2].sprite
	check(grove.affinity == "grove" and gale.affinity == "gale" and grove.tint != gale.tint, "Same-species Seedmotes use different individual affinities, not species or class colors")
	check(grove.motes.size() == visuals.effect_count and gale.motes.size() == visuals.effect_count, "Effects are bounded by the connected Inspector setting")
	var snapshot: Dictionary = world.persistent_state.snapshot()
	grove.animate(0, 1, 0.8)
	var before := grove.position.y
	var ground_before := grove.position.y + grove.shadow.position.y
	grove.animate(0.2, 1, 0.8)
	check(not is_equal_approx(before, grove.position.y) and is_equal_approx(ground_before, grove.position.y + grove.shadow.position.y), "Hover moves in real 3D height while the shadow stays on the ground")
	check(world.persistent_state.snapshot() == snapshot, "Cosmetic hover and effects do not mutate saved identity or simulation")
	var custom := SolVisualSettings.new()
	custom.palette["grove"] = Color.MAGENTA
	custom.effect_count = 0
	var orb := SolOrb.new()
	orb.configure("grove", custom)
	check(orb.tint == Color.MAGENTA and orb.motes.is_empty(), "Palette overrides and zero-effect tuning affect the actual visual")
	orb.free()
	orb = SolOrb.new()
	orb.configure("unknown_saved_affinity", visuals)
	check(orb.tint == Color("e6e9ee"), "Unknown saved affinities receive a neutral fallback without being reassigned")
	orb.free()
	custom.effect_count = 13
	check(not custom.valid(), "Invalid unbounded effect tuning is rejected")
	check(world.persistent_state.choose_starter(scene.battle_settings.starters[2].snapshot(), 2), "A Tide companion can enter the shared orb battle presentation")
	world.cell = members[2].home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_nearest()
	scene.encounters.battle_button.pressed.emit()
	var battle: Node = scene.battles
	check(battle.session != null and battle.session.enemy.affinity == "gale", "Wild combat profile retains the actual guarding individual's Gale affinity")
	battle.select_cell(battle.session.deployment_tiles()[0])
	var displayed: Dictionary = {}
	for child in battle.visuals.get_children():
		if child is SolOrb:
			displayed[child.affinity] = child.tint
	check(displayed.get("gale") == visuals.color_for("gale") and displayed.get("tide") == visuals.color_for("tide"), "Wild and deployed battle orbs use the same assigned-affinity palette")
	world.smoke_mode = false
	var elapsed: float = battle.visual_seconds
	battle._process(0.2)
	check(world.paused and battle.visual_seconds > elapsed, "Battle effects animate while the exploration simulation is paused")
	world.smoke_mode = true
	if OS.get_cmdline_user_args().has("--capture-orbs") and DisplayServer.get_name() != "headless":
		await capture("battle")
	battle.retreat()
	world.cell = scene.sightings.members[2].home + Vector2i(-2, -1)
	world.rebuild_world()
	if OS.get_cmdline_user_args().has("--capture-orbs") and DisplayServer.get_name() != "headless":
		await capture("gale")
	scene.free()
	print("SOL ORBS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)

func capture(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/orbs")
	for frame in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://artifacts/orbs/%s.png" % name)
