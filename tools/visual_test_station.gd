extends Node3D
## Presentation fixtures only. No expedition, weather simulation or balance writes.
@export_enum("Lighting", "Materials", "Water", "Readability", "Particle density") var station := 0
var camera := Camera3D.new()
var environment := Environment.new()
var sun := DirectionalLight3D.new()
var samples := Node3D.new()
var values: Dictionary = {}
var camera_yaw := 0.4
var camera_pitch := 0.42
var camera_distance := 15.0
var elapsed := 0.0
var controls := VBoxContainer.new()
var readout := Label.new()
var water: ShaderMaterial
var particles: GPUParticles3D
var blocker: MeshInstance3D
var actors: Array[Node3D] = []
var sky_material := ProceduralSkyMaterial.new()

func _ready() -> void:
 var world := WorldEnvironment.new()
 world.environment = environment
 environment.background_mode = Environment.BG_SKY
 environment.sky = Sky.new()
 environment.sky.sky_material = sky_material
 environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.ambient_light_color = Color("adb9ca")
 environment.ambient_light_energy = 0.6
 environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 add_child(world)
 sun.rotation_degrees = Vector3(-45, -30, 0)
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 100
 add_child(sun)
 add_child(camera)
 camera.current = true
 camera.far = 150
 add_child(samples)
 mesh(PlaneMesh.new(), Vector3.ZERO, Vector3(24, 1, 24), material(Color("414b50")))
 build_panel()
 match station:
  0: build_lighting()
  1: build_materials()
  2: build_water()
  3: build_readability()
  4: build_particles()
 update_camera()

func material(color: Color, roughness: float = 0.8, metallic: float = 0.0) -> StandardMaterial3D:
 var result := StandardMaterial3D.new()
 result.albedo_color = color
 result.roughness = roughness
 result.metallic = metallic
 return result

func mesh(shape: Mesh, at: Vector3, scale_value: Vector3, surface: Material) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 node.mesh = shape
 node.material_override = surface
 node.position = at
 node.scale = scale_value
 samples.add_child(node)
 return node

func label_3d(text: String, at: Vector3) -> void:
 var label := Label3D.new()
 label.text = text
 label.position = at
 label.font_size = 32
 label.pixel_size = 0.007
 label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 samples.add_child(label)

func build_panel() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var panel := PanelContainer.new()
 panel.position = Vector2(12, 12)
 panel.custom_minimum_size.x = 250
 layer.add_child(panel)
 var scroll := ScrollContainer.new()
 panel.add_child(scroll)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 scroll.add_child(controls)
 var resize := func(): panel.size = Vector2(265, maxf(200, get_viewport().get_visible_rect().size.y - 24))
 get_viewport().size_changed.connect(resize)
 resize.call()
 var heading := Label.new()
 heading.text = ["LIGHTING / SHADOWS", "MATERIAL RESPONSE", "WATER / SHORELINE", "SCALE / READABILITY", "PARTICLE DENSITY"][station]
 controls.add_child(heading)
 var help := Label.new()
 help.text = "Visual fixture · metres\nRight-drag orbit · wheel zoom"
 controls.add_child(help)
 readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 readout.custom_minimum_size.x = 245
 controls.add_child(readout)
 slider("Camera distance (m)", "distance", 4, 60, 0.5, camera_distance, func(value: float): camera_distance = value; update_camera())

func slider(title: String, key: String, low: float, high: float, step: float, initial: float, apply: Callable) -> void:
 var caption := Label.new()
 caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 caption.custom_minimum_size.x = 245
 controls.add_child(caption)
 var control := HSlider.new()
 control.name = key
 control.min_value = low
 control.max_value = high
 control.step = step
 control.value = initial
 controls.add_child(control)
 var update := func(value: float):
  values[key] = value
  caption.text = "%s: %.3f" % [title, value]
  apply.call(value)
 control.value_changed.connect(update)
 update.call(initial)

func button(text: String, action: Callable) -> void:
 var item := Button.new()
 item.text = text
 item.pressed.connect(action)
 controls.add_child(item)

func reference_objects() -> void:
 mesh(SphereMesh.new(), Vector3(0, 1, 0), Vector3.ONE * 2, material(Color("bdbcb3"), 0.3))
 mesh(BoxMesh.new(), Vector3(2, 0.5, 1), Vector3.ONE, material(Color("9a523d")))
 for path in ["res://assets/nature/CommonTree_1.gltf", "res://assets/nature/Rock_Medium_1.gltf"]:
  var model := load(path) as PackedScene
  if model:
   var node := model.instantiate() as Node3D
   samples.add_child(node)
   node.position = Vector3(-3, 0, -2) if "Tree" in path else Vector3(3, 0, -2)
 label_3d("1 m cube", Vector3(2, 1.3, 1))

func build_lighting() -> void:
 reference_objects()
 readout.text = "Compare silhouette, cast shadows and fog. These are art-rig settings, not the game's weather model."
 slider("Sun elevation (degrees)", "sun_elevation", 2, 90, 1, 45, func(v: float): sun.rotation_degrees.x = -v)
 slider("Sun azimuth (degrees)", "sun_azimuth", -180, 180, 1, -30, func(v: float): sun.rotation_degrees.y = v)
 slider("Direct light", "sun_energy", 0, 4, 0.05, 1.2, func(v: float): sun.light_energy = v)
 slider("Ambient fill", "ambient", 0, 2, 0.05, 0.6, func(v: float): environment.ambient_light_energy = v)
 slider("Fog density", "fog", 0, 0.15, 0.001, 0, func(v: float): environment.fog_enabled = v > 0; environment.fog_density = v)
 slider("Shadow opacity", "shadow", 0, 1, 0.05, 0.85, func(v: float): sun.shadow_opacity = v)
 button("Neutral daylight", func(): sun.light_color = Color.WHITE; sky_material.sky_top_color = Color("567ba8"))
 button("Warm sunset tint", func(): sun.light_color = Color("ffc08b"); sky_material.sky_top_color = Color("6c617f"))

func build_materials() -> void:
 readout.text = "Rows: metallic 0 / 0.5 / 1.\nColumns: roughness 0 / .25 / .5 / .75 / 1. Identical light and geometry."
 for row in range(3):
  for column in range(5):
   mesh(SphereMesh.new(), Vector3((column - 2) * 1.7, 0.7, (row - 1) * 2.4), Vector3.ONE * 1.4, material(Color("c39564"), column / 4.0, row / 2.0))
   label_3d("R %.2f / M %.1f" % [column / 4.0, row / 2.0], Vector3((column - 2) * 1.7, 1.8, (row - 1) * 2.4))
 slider("Light rotation", "light_angle", -180, 180, 1, -30, func(v: float): sun.rotation_degrees.y = v)
 slider("Direct light", "light_energy", 0, 4, 0.05, 1.5, func(v: float): sun.light_energy = v)

func build_water() -> void:
 readout.text = "Uses the game's pixel_water shader and depth/shore mask. Depth increases left to right; foam is enabled at the shallow edge."
 water = ShaderMaterial.new()
 water.shader = load("res://shaders/pixel_water.gdshader")
 water.set_shader_parameter("ripple_noise", load("res://resources/water_ripples.tres"))
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in range(32):
  var left := -5.0 + x * 10.0 / 32
  var right := -5.0 + (x + 1) * 10.0 / 32
  for point in [Vector3(left, 0.15, -3), Vector3(right, 0.15, 3), Vector3(right, 0.15, -3), Vector3(left, 0.15, -3), Vector3(left, 0.15, 3), Vector3(right, 0.15, 3)]:
   surface.set_normal(Vector3.UP)
   surface.set_uv2(Vector2((point.x + 5) * 0.1, 1))
   surface.add_vertex(point)
 mesh(surface.commit(), Vector3.ZERO, Vector3.ONE, water)
 for x in range(6): label_3d("%.1f m" % (x * 0.2), Vector3(-5 + x * 2, 0.4, 3.5))
 slider("Ripple strength", "ripple_strength", 0, 0.15, 0.001, 0.006, func(v: float): water.set_shader_parameter("ripple_strength", v))
 slider("Ripple speed", "ripple_speed", 0, 2, 0.05, 0.6, func(v: float): water.set_shader_parameter("ripple_speed", v))
 slider("Foam depth (m)", "foam_depth", 0.01, 0.15, 0.005, 0.06, func(v: float): water.set_shader_parameter("foam_depth", v))
 slider("Color depth range (m)", "depth_color_range", 0.1, 1, 0.025, 0.4, func(v: float): water.set_shader_parameter("depth_color_range", v))

func build_readability() -> void:
 readout.text = "Same 1.8 m target at 3 depths. Move the occluder and compare contrast, perspective and label legibility."
 for index in range(3):
  var actor := mesh(CapsuleMesh.new(), Vector3((index - 1) * 2.5, 0.9, -index * 5), Vector3(0.7, 0.9, 0.7), material(Color("dbb174")))
  actors.append(actor)
  label_3d("Target %d · 1.8 m" % (index + 1), actor.position + Vector3(0, 1.5, 0))
 blocker = mesh(BoxMesh.new(), Vector3(0, 1, 1), Vector3(1.5, 2, 0.25), material(Color("434838")))
 slider("Occluder position (m)", "occluder_x", -6, 6, 0.1, 0, func(v: float): blocker.position.x = v)
 slider("Occluder height (m)", "occluder_height", 0, 4, 0.1, 2, func(v: float): blocker.scale.y = maxf(v, 0.001); blocker.position.y = v / 2)
 slider("Field of view", "fov", 25, 90, 1, 48, func(v: float): camera.fov = v)
 slider("Target brightness", "contrast", 0.1, 1, 0.05, 0.8, func(v: float):
  for actor in actors: (actor.material_override as StandardMaterial3D).albedo_color = Color(v, v * 0.8, v * 0.55))

func build_particles() -> void:
 readout.text = "Synthetic overdraw/density fixture. Compare appearance with host frame time and draw counts; this is not a target-device benchmark."
 particles = GPUParticles3D.new()
 particles.amount = 8192
 particles.lifetime = 3
 particles.use_fixed_seed = true
 particles.seed = 291030
 particles.preprocess = 3
 particles.visibility_aabb = AABB(Vector3(-10, -2, -10), Vector3(20, 15, 20))
 var motion := ParticleProcessMaterial.new()
 motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
 motion.emission_box_extents = Vector3(4, 0.1, 4)
 motion.direction = Vector3.UP
 motion.initial_velocity_min = 1
 motion.initial_velocity_max = 2
 motion.gravity = Vector3.ZERO
 particles.process_material = motion
 var quad := QuadMesh.new()
 quad.size = Vector2(0.08, 0.08)
 var surface := material(Color("82e3c6"))
 surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 surface.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
 surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 surface.albedo_color.a = 0.4
 quad.material = surface
 particles.draw_pass_1 = quad
 samples.add_child(particles)
 slider("Active particles", "active_particles", 128, 8192, 128, 1024, func(v: float): particles.amount_ratio = v / 8192)
 slider("Particle size (m)", "particle_size", 0.02, 0.8, 0.01, 0.08, func(v: float): quad.size = Vector2.ONE * v)
 slider("Opacity", "opacity", 0.05, 1, 0.05, 0.4, func(v: float): surface.albedo_color.a = v)
 button("Restart fixed seed", func(): particles.restart())

func update_camera() -> void:
 if not is_inside_tree(): return
 var target := Vector3(0, 1, -2)
 camera.position = target + Vector3(sin(camera_yaw) * cos(camera_pitch), sin(camera_pitch), cos(camera_yaw) * cos(camera_pitch)) * camera_distance
 camera.look_at(target)
 camera.h_offset = -1.5

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
  camera_yaw -= event.relative.x * 0.007
  camera_pitch = clampf(camera_pitch + event.relative.y * 0.005, 0.1, 1.4)
  update_camera()
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera_distance = maxf(4, camera_distance * 0.9)
  elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera_distance = minf(60, camera_distance * 1.1)
  values["distance"] = camera_distance
  controls.get_node("distance").set_value_no_signal(camera_distance)
  update_camera()

func workstation_readings() -> Dictionary:
 return {"station": station, "parameters": values.duplicate(), "camera_distance_m": camera_distance, "camera_fov": camera.fov, "sun_tint": str(sun.light_color), "synthetic_fixture": true}
