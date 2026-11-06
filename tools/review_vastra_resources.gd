extends SceneTree
## Independent local resource comparison. Does not load game code or saves.
const PATHS := [
	"res://Vefects/Wind VFX/VFX/Particles/VFX_Wind_Flows_01.tscn",
	"res://Vefects/Wind VFX/VFX/Particles/VFX_Wind_Flows_Trails_01.tscn",
	"res://Vefects/Distortion VFX/VFX/Particles/VFX_Distortion_Flat_06.tscn",
	"res://Vefects/Distortion VFX/VFX/Particles/VFX_Distortion_Flat_11.tscn",
]

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(9, 7, 14)
	camera.look_at(Vector3(0, 2, 0))
	camera.current = true
	var sky := WorldEnvironment.new()
	sky.environment = Environment.new()
	sky.environment.background_mode = Environment.BG_COLOR
	sky.environment.background_color = Color("293b48")
	sky.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.environment.ambient_light_color = Color("b9cdd3")
	stage.add_child(sky)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	stage.add_child(sun)
	for x in range(-8, 9):
		for z in range(-8, 9):
			var tile := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(1, 0.1, 1)
			tile.mesh = mesh
			tile.position = Vector3(x, 0, z)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color("53704d") if (x + z) % 2 == 0 else Color("a09b71")
			tile.material_override = material
			stage.add_child(tile)
	for at in [Vector3(-3, 1, 0), Vector3(0, 1, -3), Vector3(3, 1, 0)]:
		var landmark := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.height = 2
		mesh.top_radius = 0.3
		mesh.bottom_radius = 0.6
		landmark.mesh = mesh
		landmark.position = at
		stage.add_child(landmark)
	for path in PATHS:
		var effect: Node3D = load(path).instantiate()
		stage.add_child(effect)
		effect.position = Vector3(0, 2, 0)
		# Local fixture overrides only: bring the hundred-unit showcase into view.
		if "Wind" in path:
			for child in effect.get_children():
				if child is GPUParticles3D:
					child.process_material = child.process_material.duplicate()
					child.process_material.set_shader_parameter("shape_scale", Vector3(12, 4, 12))
					child.process_material.set_shader_parameter("shape_position", Vector3.ZERO)
					child.restart()
		for frame in range(120):
			await process_frame
		var filename: String = path.get_file().get_basename()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://" + filename + ".png")
		if "--animate" in OS.get_cmdline_user_args():
			DirAccess.make_dir_recursive_absolute("res://frames/" + filename)
			for frame in range(24):
				await create_timer(0.1).timeout
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://frames/%s/%03d.png" % [filename, frame])
		print("Captured ", filename)
		effect.queue_free()
		await process_frame
	quit()
