extends Node
## Presentation-only adapter. Never reads or writes expedition saves or game tuning.
var host: Control
var camera: Camera3D
var initial_camera: Dictionary = {}
var view_camera: Dictionary = {}
var selected: Node3D
var subjects: Array[Dictionary] = []
var pivot := Vector3.ZERO
var orbit_distance := 10.0
var yaw := 0.0
var pitch := 0.4
var camera_active := false
var inspect_enabled := true
var labels_visible := true
var hints_visible := false
var view_mode := 0
var view_info := Label.new()
var view_switches: Dictionary = {}
var view_mode_picker := OptionButton.new()
var subject_picker := OptionButton.new()
var selection_lines: MeshInstance3D
var scale_lines: MeshInstance3D
var normal_lines: MeshInstance3D
var endpoint_markers: Node3D
var endpoint_toggle := CheckButton.new()
var saved_materials: Dictionary = {}
var original_labels: Dictionary = {}
var original_hints: Dictionary = {}
var selection_timer := 0.0
var wording_timer := 0.0
var overlays: Node3D
var controls_count := 0
var info_box: VBoxContainer
var selected_id := ""
var model_bounds: Dictionary = {}
var overlay_material := StandardMaterial3D.new()

func bind(workspace: Control, page: VBoxContainer) -> void:
	host = workspace
	page.add_child(view_info)
	view_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(subject_picker)
	subject_picker.item_selected.connect(func(index: int): choose_subject(index-1))
	var row := HFlowContainer.new()
	page.add_child(row)
	host.button(row, "Move closer", frame_selected)
	host.button(row, "Show whole scene", frame_all)
	host.button(row, "Reset view", reset_view)
	var angles := HFlowContainer.new()
	page.add_child(angles)
	for item in [["Front",0.0,0.15],["Side",PI/2,0.15],["Above",0.0,1.5]]:
		host.button(angles, item[0], func(): yaw = item[1]; pitch = item[2]; camera_active = true; update_camera())
	add_switch(page, "Click objects to select them", true, func(on: bool): inspect_enabled = on)
	add_switch(page, "Show names", true, set_labels)
	add_switch(page, "Show on-screen tips", false, set_hints)
	add_switch(page, "Show metre ruler", false, func(on: bool):
		if is_instance_valid(scale_lines): scale_lines.visible = on)
	var modes := view_mode_picker
	for title in ["Normal colors", "Mesh edges", "Surface direction"]: modes.add_item(title)
	page.add_child(modes)
	endpoint_toggle.text = "Show energy endpoints"
	page.add_child(endpoint_toggle)
	endpoint_toggle.toggled.connect(func(on: bool):
		if is_instance_valid(endpoint_markers): endpoint_markers.visible = on)
	modes.item_selected.connect(set_view_mode)
	var help := Label.new()
	help.text = "Right-drag: turn view · Middle-drag: move view · Wheel: zoom.\nPick an object to see its size and move closer. View tools change only this test."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(help)
	info_box = host.fold_section(page,"Test info",false)
	overlay_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	overlay_material.albedo_color = Color("f0ca76")
	overlay_material.no_depth_test = true

func add_switch(parent: Node, text: String, value: bool, action: Callable) -> void:
	var toggle := CheckButton.new()
	toggle.text = text
	toggle.button_pressed = value
	parent.add_child(toggle)
	view_switches[text] = toggle
	toggle.toggled.connect(action)

func before_load() -> void:
	restore_materials()
	selected = null
	subjects.clear()
	model_bounds.clear()
	original_labels.clear()
	original_hints.clear()
	if info_box:
		for child in info_box.get_children(): child.free()
	if is_instance_valid(overlays): overlays.free()
	camera = null

func after_load() -> void:
	camera = host.viewport.get_camera_3d()
	if camera == null:
		for node in host.descendants(host.fixture):
			if node is Camera3D: camera = node; break
	if camera:
		camera.h_offset = 0
		initial_camera = {"transform": camera.transform, "size": camera.size, "projection": camera.projection,"fov":camera.fov}
		orbit_distance = maxf(1.0, camera.position.length())
		pivot = camera.global_position - camera.global_basis.z * orbit_distance
		read_angles()
	camera_active = false
	view_camera.clear()
	dock_station()
	collect_subjects()
	var root_3d: Node = host.fixture
	if not root_3d is Node3D:
		for node in host.descendants(host.fixture):
			if node is Node3D: root_3d = node; break
	if root_3d is Node3D:
		overlays = Node3D.new()
		overlays.name = "LabViewHelpers"
		root_3d.add_child(overlays)
		selection_lines = make_lines(PackedVector3Array())
		scale_lines = make_ruler()
		scale_lines.hide()
		endpoint_markers = Node3D.new()
		endpoint_markers.name = "EnergyEndpoints"
		overlays.add_child(endpoint_markers)
		if host.active_key == "grass_blade_preview":
			for item in host.fixture.vastra_network.endpoints.values():
				add_endpoint(item.anchor,Color("83dbef"))
				add_endpoint(item.high_anchor,Color("f0cb76"))
		elif host.active_key == "vastra_particle_lab":
			for row in host.fixture.plant_nodes.rows: add_endpoint(row.port,Color("83dbef"))
		endpoint_markers.visible = endpoint_toggle.button_pressed
	endpoint_toggle.visible = host.active_key in ["grass_blade_preview","vastra_particle_lab"]
	set_hints(hints_visible)
	set_labels(labels_visible)
	refresh_subject_picker()
	simplify_controls()
	set_view_mode(view_mode)
	view_info.text = "Choose an object, or click it in the scene."

func dock_station() -> void:
	controls_count = 0
	if host.fixture.has_method("workstation_dock_controls"): return
	# Game HUDs are runtime UI, not lab control panels. Preserve those interactions.
	var gameplay := host.fixture.get("world") is Node
	var candidates: Array[Control] = []
	for node in host.descendants(host.fixture):
		if not node is Control or node is Window or node is TextureRect: continue
		if node.get_parent() is CanvasLayer or (node.get_parent() == host.fixture and host.fixture is Control):
			if node is Container or node is Label: candidates.append(node)
	if gameplay:
		candidates.clear()
		if host.active_key == "story_workshop":
			var world: Node = host.fixture.get("world")
			for child in world.hud.get_children():
				if child is VBoxContainer: candidates.append(child)
	for candidate in candidates:
		if not is_instance_valid(candidate): continue
		var has_controls := false
		for child in host.descendants(candidate):
			if child is BaseButton or child is Slider or child is SpinBox: has_controls = true; break
		var section: VBoxContainer = host.fold_section(host.station_box, "Test controls" if controls_count == 0 else "More test controls", true) if has_controls else info_box
		var content: Control = candidate
		if candidate is PanelContainer or candidate is MarginContainer:
			var boxes := candidate.find_children("*", "VBoxContainer", true, false)
			if not boxes.is_empty(): content = boxes[0]
		if content == candidate:
			# Keep a hidden shell so original viewport resize callbacks stay valid.
			var shell := Control.new()
			candidate.get_parent().add_child(shell)
		content.reparent(section)
		content.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		content.position = Vector2.ZERO
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if content != candidate: candidate.hide()
		reflow(content)
		controls_count += 1

func reflow(root: Node) -> void:
	# Flow rows wrap rather than forcing a wide sidebar. Button connections survive.
	for node in host.descendants(root):
		if node is HBoxContainer:
			var flow := HFlowContainer.new()
			var parent: Node = node.get_parent()
			parent.add_child(flow)
			parent.move_child(flow, node.get_index())
			for child in node.get_children(): child.reparent(flow)
			node.hide()
		if node is Control:
			node.custom_minimum_size.x = minf(node.custom_minimum_size.x, 240)
		if node is Label:
			node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if node is OptionButton:
			node.clip_text = true
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func collect_subjects() -> void:
	if host.active_key == "grass_blade_preview":
		for node in host.fixture.get_children():
			if node is MultiMeshInstance3D: add_subject(node, str(node.name).replace("SingleBlades", " grass"))
	elif host.active_key == "vastra_particle_lab":
		var plants: Node = host.fixture.get("plant_nodes")
		for i in range(plants.get_child_count()):
			var child := plants.get_child(i)
			if child is Node3D and i < plants.NAMES.size(): add_subject(child, plants.NAMES[i])
	elif host.fixture.get("model") is Node3D:
		add_subject(host.fixture.get("model"), "Sol")
	elif host.fixture.get("beds") is Array:
		for bed in host.fixture.get("beds"):
			if bed is Dictionary and bed.get("node") is Node3D: add_subject(bed.node, "Plant " + str(subjects.size()+1))
	elif host.fixture.get("samples") is Node3D:
		for child in host.fixture.get("samples").get_children():
			if child is Node3D and bounds_for(child).size.length() > 0.02: add_subject(child, nice_name(child))
	if subjects.is_empty():
		var meshes: Array[Node] = host.descendants(host.fixture)
		for node in meshes:
			if subjects.size() >= 160: break
			if node is MeshInstance3D and node.mesh != null and node.is_visible_in_tree():
				var box := bounds_for(node)
				if box.size.y > 0.08 and box.size.length() < 50: add_subject(node, nice_name(node))

func nice_name(node: Node) -> String:
	var title := str(node.name)
	if title.begins_with("@") or title in ["MeshInstance3D", "Node3D"]: title = "Object " + str(subjects.size()+1)
	return title.replace("_", " ").capitalize()

func add_subject(node: Node3D, title: String) -> void:
	subjects.append({"node": node, "name": title, "id": str(host.fixture.get_path_to(node))})

func refresh_subject_picker() -> void:
	subject_picker.clear()
	subject_picker.add_item("Choose an object…")
	for item in subjects: subject_picker.add_item(item.name)

func bounds_for(node: Node3D) -> AABB:
	var result := AABB()
	var found := false
	for child in host.descendants(node):
		if child is GeometryInstance3D and child.is_visible_in_tree() and not child is Label3D:
			var local := AABB()
			if child is MeshInstance3D and child.mesh: local = child.get_aabb()
			elif child is MultiMeshInstance3D and child.multimesh: local = child.get_aabb()
			if local.size.length_squared() <= 0: continue
			var box: AABB = child.global_transform * local
			result = result.merge(box) if found else box
			found = true
	return result

func pick(at: Vector2) -> void:
	if not is_instance_valid(camera): return
	var origin := camera.project_ray_origin(at)
	var direction := camera.project_ray_normal(at)
	var nearest := INF
	var choice := -1
	for i in range(subjects.size()):
		var node: Node3D = subjects[i].node
		if not is_instance_valid(node) or not node.is_visible_in_tree(): continue
		var box := bounds_for(node).grow(0.03)
		var hit: Variant = box.intersects_ray(origin, direction)
		if hit is Vector3 and origin.distance_to(hit) < nearest:
			nearest = origin.distance_to(hit)
			choice = i
	choose_subject(choice)

func choose_subject(index: int) -> void:
	selected = subjects[index].node if index >= 0 and index < subjects.size() and is_instance_valid(subjects[index].node) else null
	selected_id = subjects[index].id if selected else ""
	subject_picker.select(index+1 if selected else 0)
	if not selected:
		view_info.text = "No object selected."
		if is_instance_valid(selection_lines): selection_lines.hide()
		return
	var bounds := bounds_for(selected)
	view_info.text = "%s\nSize: %.2f × %.2f × %.2f m" % [subjects[index].name, bounds.size.x, bounds.size.y, bounds.size.z]
	if host.active_key == "grass_blade_preview": view_info.text += "\nUse Appearance and Coverage to change all four grass patches."
	elif host.active_key == "vastra_particle_lab":
		var rows: Array = host.fixture.plant_nodes.rows
		if index < rows.size(): view_info.text += "\nEnergy: %.1f · Roots: %.1f" % [rows[index].energy, rows[index].roots]
	update_selection()

func update_selection() -> void:
	if not is_instance_valid(selected) or not is_instance_valid(selection_lines): return
	var bounds := bounds_for(selected).grow(0.04)
	selection_lines.mesh = line_mesh(box_edges(bounds))
	selection_lines.visible = true
	if view_mode == 2: draw_normals()

func frame_selected() -> void:
	if not is_instance_valid(selected):
		host.message.text = "Choose an object first."
		return
	frame_bounds(bounds_for(selected))

func frame_all() -> void:
	var box := AABB()
	var found := false
	for item in subjects:
		if not is_instance_valid(item.node) or not item.node.is_visible_in_tree(): continue
		var next := bounds_for(item.node)
		box = box.merge(next) if found else next
		found = true
	if found: frame_bounds(box)

func frame_bounds(box: AABB) -> void:
	pivot = box.get_center()
	orbit_distance = maxf(0.2, box.size.length() * 1.5)
	if camera and camera.projection == Camera3D.PROJECTION_ORTHOGONAL: camera.size = maxf(0.1, box.size.length()*1.3)
	camera_active = true
	update_camera()

func read_angles() -> void:
	if not camera: return
	var offset := camera.global_position - pivot
	orbit_distance = maxf(0.1, offset.length())
	yaw = atan2(offset.x, offset.z)
	pitch = asin(clampf(offset.y / orbit_distance, -0.99, 0.99))

func update_camera() -> void:
	if not is_instance_valid(camera): return
	camera.global_position = pivot + Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*orbit_distance
	camera.look_at(pivot)
	camera.h_offset = 0
	ensure_view_distance()
	view_camera = snapshot_camera()

func ensure_view_distance() -> void:
	# Fixture framing can use a tiny near/far range. Shared orbit controls and
	# restored views must keep their own pivot inside the visible depth range.
	camera.far = maxf(camera.far, orbit_distance * 6.0)

func snapshot_camera() -> Dictionary:
	if not is_instance_valid(camera): return {}
	return {"transform": camera.transform, "size": camera.size, "projection": camera.projection, "fov":camera.fov, "pivot": pivot, "distance": orbit_distance, "yaw": yaw, "pitch": pitch, "active": camera_active, "selected": subject_picker.get_item_text(subject_picker.selected) if subject_picker.selected > 0 else ""}

func restore_camera(values: Dictionary) -> void:
	if not camera or not values.has("transform"): return
	camera.h_offset = 0
	camera.transform = values.transform
	camera.size = float(values.get("size", camera.size))
	camera.projection = int(values.get("projection", camera.projection))
	camera.fov = float(values.get("fov",camera.fov))
	pivot = values.get("pivot", pivot)
	orbit_distance = float(values.get("distance", orbit_distance))
	yaw = float(values.get("yaw", yaw))
	pitch = float(values.get("pitch", pitch))
	camera_active = bool(values.get("active", false))
	ensure_view_distance()
	view_camera = values.duplicate(true)
	for i in range(subjects.size()):
		if str(subjects[i].name) == str(values.get("selected","")): choose_subject(i); break

func reset_view() -> void:
	camera_active = false
	restore_camera(initial_camera)
	read_angles()
	view_camera.clear()

func _input(event: InputEvent) -> void:
	if not host or not is_instance_valid(host.fixture) or not host.is_visible_in_tree() or not camera: return
	if host.get_viewport().gui_get_focus_owner() is TextEdit or host.get_viewport().gui_get_focus_owner() is LineEdit: return
	if host.baseline_overlay.visible: return
	var container: Control = host.preview_stack.get_child(0)
	var mouse := host.get_global_mouse_position()
	if not container.get_global_rect().has_point(mouse): return
	if host.get_viewport().gui_get_hovered_control() != null:
		var hovered := host.get_viewport().gui_get_hovered_control()
		if hovered != container and not container.is_ancestor_of(hovered): return
	var handled := false
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			if not camera_active: read_angles()
			yaw -= event.relative.x * 0.008
			pitch = clampf(pitch + event.relative.y * 0.006, -1.5, 1.5)
			handled = true
		elif event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			pivot += (-camera.global_basis.x*event.relative.x + camera.global_basis.y*event.relative.y) * orbit_distance*0.0015
			handled = true
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			orbit_distance = clampf(orbit_distance * (0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1), 0.05, 1000.0)
			if camera.projection == Camera3D.PROJECTION_ORTHOGONAL: camera.size *= 0.9 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1
			handled = true
		elif event.button_index == MOUSE_BUTTON_LEFT and inspect_enabled:
			var local := (mouse - container.global_position) / container.size * Vector2(camera.get_viewport().size)
			pick(local)
			host.sidebar.current_tab = host.sidebar.get_tab_idx_from_control(host.sidebar.get_node("View"))
			handled = true
	if handled:
		camera_active = true
		update_camera()
		host.get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	selection_timer += _delta
	wording_timer += _delta
	if wording_timer > 0.25 and host and is_instance_valid(host.fixture):
		wording_timer = 0
		simplify_controls()
	if camera_active and is_instance_valid(camera) and not view_camera.is_empty():
		camera.transform = view_camera.transform
		camera.size = float(view_camera.size)
		ensure_view_distance()
	if selection_timer >= 0.2 and host and is_instance_valid(host.fixture):
		selection_timer = 0
		var stale := false
		for item in subjects:
			if not is_instance_valid(item.node): stale = true; break
		if stale:
			subjects.clear()
			collect_subjects()
			refresh_subject_picker()
			choose_subject(-1)
		elif is_instance_valid(selected):
			choose_subject(subject_picker.selected-1)

func set_labels(on: bool) -> void:
	labels_visible = on
	if view_switches.has("Show names"): view_switches["Show names"].set_pressed_no_signal(on)
	for node in host.descendants(host.fixture):
		if node is Label3D:
			if not original_labels.has(node): original_labels[node] = node.visible
			node.visible = bool(original_labels[node]) and on

func set_hints(on: bool) -> void:
	hints_visible = on
	if view_switches.has("Show on-screen tips"): view_switches["Show on-screen tips"].set_pressed_no_signal(on)
	for node in host.descendants(host.fixture):
		if node is CanvasLayer:
			# Docked controls live outside these layers and stay usable.
			if not original_hints.has(node): original_hints[node] = node.visible
			node.visible = on and bool(original_hints[node])

func restore_materials() -> void:
	for node in saved_materials:
		if is_instance_valid(node): node.material_override = saved_materials[node]
	saved_materials.clear()
	if is_instance_valid(normal_lines): normal_lines.free()

func set_view_mode(mode: int) -> void:
	restore_materials()
	view_mode = mode
	view_mode_picker.select(mode)
	if not is_instance_valid(host.fixture): return
	if mode == 0: return
	var material: ShaderMaterial = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded; void fragment(){ ALBEDO = NORMAL * 0.5 + 0.5; }" if mode == 2 else "shader_type spatial; render_mode unshaded, wireframe; void fragment(){ ALBEDO=vec3(0.85,0.9,0.8); }"
	material.shader = shader
	for node in host.descendants(host.fixture):
		if node is GeometryInstance3D and not node is Label3D and not overlays.is_ancestor_of(node):
			saved_materials[node] = node.material_override
			node.material_override = material
	if mode == 2: draw_normals()

func draw_normals() -> void:
	if not is_instance_valid(overlays) or not is_instance_valid(selected): return
	if is_instance_valid(normal_lines): normal_lines.free()
	var points := PackedVector3Array()
	for node in host.descendants(selected):
		if not node is MeshInstance3D or node.mesh == null: continue
		for surface in range(node.mesh.get_surface_count()):
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			if arrays.is_empty() or arrays[Mesh.ARRAY_NORMAL] == null: continue
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var stride := maxi(1, vertices.size()/128)
			for i in range(0, mini(vertices.size(),normals.size()), stride):
				var start: Vector3 = node.global_transform * vertices[i]
				points.append(start)
				points.append(start + (node.global_basis.inverse().transposed()*normals[i]).normalized()*0.12)
				if points.size() >= 1024: break
	if not points.is_empty(): normal_lines = make_lines(points)

func box_edges(box: AABB) -> PackedVector3Array:
	var points := PackedVector3Array()
	for pair in [[0,1],[0,2],[0,4],[1,3],[1,5],[2,3],[2,6],[3,7],[4,5],[4,6],[5,7],[6,7]]:
		points.append(box.get_endpoint(pair[0]))
		points.append(box.get_endpoint(pair[1]))
	return points

func line_mesh(points: PackedVector3Array) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	if not points.is_empty():
		mesh.surface_begin(Mesh.PRIMITIVE_LINES, overlay_material)
		for point in points: mesh.surface_add_vertex(point)
		mesh.surface_end()
	return mesh

func make_lines(points: PackedVector3Array) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = line_mesh(points)
	overlays.add_child(node)
	node.top_level = true
	return node

func make_ruler() -> MeshInstance3D:
	var points := PackedVector3Array([Vector3.ZERO,Vector3(0,2,0)])
	for i in range(21):
		var height := i*0.1
		points.append(Vector3(-0.05,height,0))
		points.append(Vector3(0.05,height,0))
	return make_lines(points)


func control_map() -> Dictionary:
	var result := {}
	var occurrences := {}
	for root in [host.fixture, host.station_box]:
		for node in host.descendants(root):
			if not (node is OptionButton or node is Slider or node is SpinBox or (node is BaseButton and node.toggle_mode and not node.has_meta("lab_fold"))): continue
			if node.has_meta("lab_control_key"):
				result[str(node.get_meta("lab_control_key"))] = node
				continue
			var key := ""
			if node is OptionButton:
				var options: Array[String] = []
				for i in range(node.item_count): options.append(node.get_item_text(i))
				key = "choice:" + "|".join(options)
			elif node is BaseButton: key = "switch:" + node.text
			else:
				var title := str(node.name)
				if title.begins_with("@") or title in ["HSlider","SpinBox"]:
					for i in range(node.get_index()-1,-1,-1):
						var previous: Node = node.get_parent().get_child(i)
						if previous is Label:
							title = previous.text.split(":")[0]
							break
				key = "number:" + title
			key = key.strip_edges()
			var count := int(occurrences.get(key,0))
			occurrences[key] = count+1
			var identifier := key + (" #"+str(count+1) if count>0 else "")
			while result.has(identifier):
				count += 1
				identifier = key + " #" + str(count+1)
			node.set_meta("lab_control_key",identifier)
			result[identifier] = node
	return result

func hide_for_picture() -> Dictionary:
	var saved := {"labels":labels_visible,"hints":hints_visible,"helpers":is_instance_valid(overlays) and overlays.visible}
	set_labels(false)
	set_hints(false)
	if is_instance_valid(overlays): overlays.hide()
	return saved

func restore_after_picture(saved: Dictionary) -> void:
	set_labels(bool(saved.get("labels",true)))
	set_hints(bool(saved.get("hints",false)))
	if is_instance_valid(overlays): overlays.visible = bool(saved.get("helpers",true))



func simplify_controls() -> void:
	var phrases := {
		"Clear view · isolate interaction":"Only show the chosen transfer",
		"In-game look · filament particles":"Game-style energy trails",
		"Earlier glowing trail comparison":"Earlier glow style",
		"Send / play interaction":"Send energy",
		"Reset nodes":"Reset plant energy",
		"Transfer energy":"Energy to send",
		"Arc height":"Curve height",
		"Path width":"Side-to-side spread",
		"Send pulse strength":"Flash strength on send",
		"Send pulse seconds":"Flash time (seconds)",
		"Show ambient field":"Show background energy",
		"Copy all test parameters":"Copy these settings",
		"Restore your baseline":"Use original look",
		"Ambient visibility":"Background visibility",
		"Filament length":"Trail length",
		"Concentration":"Energy amount",
		"Refraction":"Background distortion",
		"Cutaway / expose anatomy":"See inside the plant",
		"New seed variations":"Make new variations",
		"ART PROOF · Vastra forms provisional · Underwater deferred":"Plant shapes for review · not final designs",
		"Texture filtering":"Texture sharpness"
	}
	for root in [host.station_box, host.parameter_box]:
		for node in host.descendants(root):
			if not (node is Label or node is BaseButton): continue
			var text: String = node.text
			for phrase in phrases: text = text.replace(phrase, phrases[phrase])
			if node.text != text: node.text = text


func add_endpoint(at: Vector3, color: Color) -> void:
	var marker := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.06
	shape.height = 0.12
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	shape.material = material
	marker.mesh = shape
	endpoint_markers.add_child(marker)
	marker.top_level = true
	marker.global_position = at
