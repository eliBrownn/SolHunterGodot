extends SceneTree
## Isolated read-only photography. Jobs are authored by photograph_ecosystem.py.
const Library = preload("res://scripts/scenery/plant_library.gd")
const Art = preload("res://scripts/scenery/nature_art.gd")
const Particles = preload("res://scripts/presentation/vessel_particle_swarm.gd")
var stage: Node3D
var camera: Camera3D
var soil: MeshInstance3D
var appearance = preload("res://resources/vegetation_appearance.tres")
var environment: Environment
var output := "res://artifacts/ecosystem-review/"

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(1000, 900)
	stage = Node3D.new()
	root.add_child(stage)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	environment = env.environment
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("dbe2df")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.7
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	stage.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.15
	stage.add_child(light)
	camera = Camera3D.new()
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	stage.add_child(camera)
	soil = MeshInstance3D.new()
	soil.mesh = PlaneMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("dbe2df")
	mat.roughness = 1.0
	soil.material_override = mat
	stage.add_child(soil)
	Library.refresh(["res://resources/plants/library.json"])
	Library.set_weather(Vector2.ZERO, 0, 0)
	var jobs: Array = JSON.parse_string(FileAccess.get_file_as_string(output + "jobs.json"))
	for job: Dictionary in jobs:
		var body: Node3D
		var bounds: AABB
		if job.kind == "plant_study":
			# Reconstruct the retained authoring study directly. Do not bypass the
			# live catalog's deliberate exclusion of unclassed receivers.
			var entry: Dictionary = Library.Species.get_design(job.design)
			var settings: Dictionary = entry.captured_settings.duplicate(true)
			for key: String in settings:
				if settings[key] is float and settings[key] == floorf(settings[key]): settings[key] = int(settings[key])
			var builder = preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").new()
			builder.tube_sides = 4
			var biome := ["meadow", "woodland", "heath", "marsh"].find(entry.biome)
			var sample: Dictionary = builder.create_sample(biome, 2, int(entry.captured_seed), settings, builder.make_anatomy_materials())
			body = Node3D.new()
			for mesh: ArrayMesh in Library.live_meshes(sample, false):
				var piece := MeshInstance3D.new()
				piece.mesh = mesh
				body.add_child(piece)
				bounds = bounds.merge(mesh.get_aabb())
			stage.add_child(body)
		elif job.kind == "plant":
			var item: Resource = load(job.path)
			if item == null or item.scene == null:
				push_error("Missing plant " + job.code)
				quit(1)
				return
			var model: Dictionary = Library.model(item)
			body = item.scene.instantiate()
			stage.add_child(body)
			body.scale = item.scale_for(model.bounds)
			body.position = -(body.basis * item.ground_offset(model.bounds))
			bounds = body.transform * model.bounds
			if item.recipe.get("roots_below_ground", false):
				var top := bounds.end.y
				bounds.position.y = 0
				bounds.size.y = top
		elif job.kind == "vessel":
			body = Node3D.new()
			var swarm = Particles.new()
			swarm.member_count = int(job.members)
			swarm.spread = 0.0 if job.members == 1 else 0.18
			swarm.flight_radius = 0.025
			swarm.external_clock = true
			swarm.frozen = true
			swarm.anger = float(job.anger)
			swarm.affinity_tint = Color("e8d895")
			body.add_child(swarm)
			stage.add_child(body)
			swarm.set_visual_time(1.25)
			bounds = AABB(Vector3(-0.1, -0.1, -0.1), Vector3.ONE * 0.2) if job.members == 1 else AABB(Vector3(-0.3, -0.25, -0.3), Vector3(0.6, 1.0, 0.6))
		elif job.kind == "concept":
			body = load(job.path).new()
			body.call("configure", "neutral", SolVisualSettings.new())
			stage.add_child(body)
			body.call("animate", 1.25, 0, 0)
			bounds = body.call("preview_bounds")
			body.set_process(false)
		elif job.kind == "sol":
			var record: Resource = load(job.path)
			body = record.presentation_scene.instantiate()
			body.call("configure", "neutral", SolVisualSettings.new())
			stage.add_child(body)
			body.call("animate", 1.25, 0, 0)
			bounds = body.call("preview_bounds")
			body.set_process(false)
		else:
			var packed: PackedScene = load(job.path)
			var parts: Dictionary = Art.parts(packed)
			body = Node3D.new()
			var material: Material = appearance.material_for(packed, parts.bounds)
			for part: Dictionary in parts.pieces:
				var mesh := MeshInstance3D.new()
				mesh.mesh = part.mesh
				mesh.transform = part.transform
				if material != null: mesh.material_override = material
				body.add_child(mesh)
			stage.add_child(body)
			bounds = parts.bounds
		await capture(body, bounds, job)
		body.free()
		Library.models.clear()
		Art.cache.clear()
		Art.compact_cache.clear()
		print("ECOSYSTEM CAPTURED ", job.code)
	print("ECOSYSTEM PHOTOGRAPHY COMPLETE: ", jobs.size(), " isolated references")
	quit()

func capture(body: Node3D, bounds: AABB, job: Dictionary) -> void:
	environment.background_color = Color("18251f") if job.kind == "vessel" else Color("dbe2df")
	var span := maxf(0.01, maxf(bounds.size.y, maxf(bounds.size.x, bounds.size.z)))
	var center := bounds.get_center()
	soil.visible = job.kind != "vessel"
	soil.mesh.size = Vector2.ONE * span * 200
	soil.position = Vector3(center.x, bounds.position.y - span * 0.002, center.z)
	camera.near = span * 0.001
	camera.far = span * 50
	appearance.set_weather(Vector2.ZERO, 0, Vector2.ZERO)
	for view in range(2):
		var direction := Vector3(1, 0.55, 1 if view == 0 else -1).normalized()
		camera.position = center + direction * span * 4
		camera.look_at(center)
		var right := camera.global_basis.x
		var up := camera.global_basis.y
		var width := absf(right.x) * bounds.size.x + absf(right.y) * bounds.size.y + absf(right.z) * bounds.size.z
		var height := absf(up.x) * bounds.size.x + absf(up.y) * bounds.size.y + absf(up.z) * bounds.size.z
		camera.size = maxf(height, width / (1000.0 / 900)) * 1.2
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		if job.kind == "vessel":
			# Frame actual particle pixels, not the much wider flight safety AABB.
			var picture := root.get_texture().get_image()
			var background := picture.get_pixel(0, 0)
			var rect := Rect2i()
			var found := false
			for y in range(0, picture.get_height(), 4):
				for x in range(0, picture.get_width(), 4):
					var color := picture.get_pixel(x, y)
					if Vector3(color.r-background.r, color.g-background.g, color.b-background.b).length() < 0.09: continue
					if not found:
						rect = Rect2i(x, y, 4, 4)
						found = true
					else: rect = rect.expand(Vector2i(x, y))
			if found:
				var midpoint := Vector2(rect.get_center())
				var offset := camera.global_basis.x * ((midpoint.x-500.0)/1000.0*camera.size*1000.0/900.0) - camera.global_basis.y * ((midpoint.y-450.0)/900.0*camera.size)
				camera.position += offset
				camera.size *= maxf(float(rect.size.y)/900.0, float(rect.size.x)/1000.0) * 1.5
				for frame in range(5): await process_frame
				await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(output + job.code + "-%d.png" % view)
		if error != OK:
			push_error("Capture write failed " + job.code)
			quit(1)
			return
