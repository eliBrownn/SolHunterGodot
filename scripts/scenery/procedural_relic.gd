extends RefCounted
## Seeded visual geometry only. Site placement and Vastra transactions have other owners.
const VERSION := 5
const MAX_PARTS := 160

static func random_stream(seed_value: int, key: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("relic/%d/%s" % [seed_value, key])
	return rng

static func layout(family: int, seed_value: int, scale_value: float, damage: float, rubble: int, courses: int = 5, break_variation: float = 0.65) -> Dictionary:
	if family < 1 or family > 7 or seed_value < 0 or seed_value > 99999 or not is_finite(scale_value) or scale_value < 0.6 or scale_value > 1.3 or not is_finite(damage) or damage < 0 or damage > 2 or rubble < 0 or rubble > 16 or courses < 2 or courses > 12 or not is_finite(break_variation) or break_variation < 0 or break_variation > 1: return {}
	var rng := random_stream(seed_value, "family/%d/layout" % family)
	var width := rng.randf_range(0.88, 1.12)
	var height := rng.randf_range(0.85, 1.2)
	var depth := rng.randf_range(0.8, 1.15)
	var parts: Array[Dictionary] = []
	var marks: Array[Dictionary] = []
	if family == 1:
		add(parts, "footing", Vector3(0, 0.2, 0), Vector3(2.1 * width, 0.4, 1.6 * depth), seed_value)
		var h := 2.7 * height
		var remaining := remaining_courses(seed_value, "marker/break", courses, damage * 0.6, break_variation)
		for tier in range(remaining):
			add(parts, "upright_%d" % tier, Vector3(0, 0.4 + (tier + 0.5) * h / courses, 0), Vector3((1.2 - float(tier) / courses * 0.2) * width, h / courses - 0.015, 0.8 * depth), seed_value, 0.0, 0.08 if tier < remaining - 1 else 0.25)
		if remaining == courses and random_stream(seed_value, "marker/crown").randf() > damage:
			add(parts, "crown", Vector3(0, 0.4 + h + 0.12, 0), Vector3(0.85 * width, 0.24, 0.6 * depth), seed_value)
		for i in range(3): marks.append({"at": Vector3((i - 1) * 0.27 * width, 0.5 + h * 0.55, 0.405 * depth), "size": Vector3(0.055, h * (0.26 - i * 0.035), 0.025)})
	elif family == 2:
		var radius := 1.5 * width
		var spring := 1.9 * height
		var pier_courses := {}
		for side in [-1, 1]:
			pier_courses[side] = remaining_courses(seed_value, "pier/%d/break" % side, courses, maxf(0, damage - 1), break_variation)
			add(parts, "foot_%d" % side, Vector3(side * radius, 0.18, 0), Vector3(1.2, 0.36, 1.4 * depth), seed_value)
			for tier in range(pier_courses[side]):
				add(parts, "pier_%d_%d" % [side, tier], Vector3(side * radius, 0.36 + (tier + 0.5) * spring / courses, 0), Vector3(0.72, spring / courses - 0.015, 0.95 * depth), seed_value)
				marks.append({"at": Vector3(side * radius, 0.36 + (tier + 0.5) * spring / courses, 0.485 * depth), "size": Vector3(0.3, 0.07, 0.025)})
		var count := 9
		var left_reach := maxi(0, 4 - ceili(damage * lerpf(3.5, random_stream(seed_value, "arch/left_break").randf_range(2, 5), break_variation)))
		var right_reach := maxi(0, 4 - ceili(damage * lerpf(3.5, random_stream(seed_value, "arch/right_break").randf_range(2, 5), break_variation)))
		for i in range(count):
			var key := "arch_%d" % i
			# Surviving runs stay connected to their piers instead of floating over gaps.
			if i <= 4 and i > left_reach: continue
			if i >= 4 and count - 1 - i > right_reach: continue
			var angle := (i + 0.5) * PI / count
			var support := spring * float(pier_courses[1 if i < 4 else -1]) / courses
			add(parts, key, Vector3(cos(angle) * radius, 0.36 + support + sin(angle) * radius, 0), Vector3(0.65 * width, 0.55, depth), seed_value, angle - PI / 2)
	elif family == 3:
		for row in range(3):
			for column in range(4):
				add(parts, "slab_%d_%d" % [column, row], Vector3((column - 1.5) * 1.12 * width, 0.12, (row - 1) * 1.15 * depth), Vector3(1.08 * width, 0.24, 1.1 * depth), seed_value)
		for i in range(4):
			marks.append({"at": Vector3((i - 1.5) * 1.12 * width, 0.245, 0), "size": Vector3(0.7 * width, 0.025, 0.08)})
			for tier in range(remaining_courses(seed_value, "wall/%d/break" % i, courses, damage, break_variation)):
				var key := "wall_%d_%d" % [i, tier]
				add(parts, key, Vector3((i - 1.5) * 1.12 * width, 0.24 + (tier + 0.5) * 0.48 * height, -1.5 * depth), Vector3(1.08 * width, 0.46 * height, 0.55 * depth), seed_value)
		for i in range(2): add(parts, "side_%d" % i, Vector3(-2.0 * width, 0.5, (-0.6 + i) * depth), Vector3(0.5, 0.52, 0.85 * depth), seed_value)
	elif family == 4:
		add(parts, "ring_plinth", Vector3(0, 0.15, 0), Vector3(4.6 * width, 0.3, 2.6 * depth), seed_value)
		for i in range(16):
			# A split crown leaves two recognizable rising arms above a grounded lower ring.
			if i in [3, 4] or (damage > 0.65 and i in [2, 5]): continue
			var angle := (i + 0.5) * TAU / 16
			add(parts, "ring_segment_%d" % i, Vector3(cos(angle) * 1.55 * width, 1.9 + sin(angle) * 1.55, 0), Vector3(0.7 * width, 0.55, 0.85 * depth), seed_value, angle - PI / 2)
		for side in [-1, 1]:
			for tier in range(remaining_courses(seed_value, "monolith/%d/break" % side, courses, damage * 0.45, break_variation)):
				add(parts, "rear_monolith_%d_%d" % [side, tier], Vector3(-1.5 * width + side * 0.35, (tier + 0.5) * 4.6 * height / courses, -0.8 * depth), Vector3(0.62, 4.6 * height / courses - 0.02, 0.7), seed_value, 0, 0.1)
		for i in range(3): marks.append({"at": Vector3(-0.3 + i * 0.3, 0.45, 0.46 * depth), "size": Vector3(0.06, 0.25, 0.03)})
	elif family == 5:
		add(parts, "circle_dais", Vector3(0, 0.15, 0), Vector3(4.0 * width, 0.3, 3.7 * depth), seed_value, 0, 0.12)
		for i in range(4):
			var angle := PI / 4 + i * TAU / 4
			var h := rng.randf_range(2.8, 4.6) * height
			var at := Vector3(cos(angle) * 1.6 * width, 0.3 + h / 2, sin(angle) * 1.4 * depth)
			var surviving := remaining_courses(seed_value, "spire/%d/break" % i, courses, damage * 0.55, break_variation)
			for tier in range(surviving):
				var narrowing := 1.0 - float(tier) / courses * 0.65
				add(parts, "tapered_spire_%d_%d" % [i, tier], Vector3(at.x, 0.3 + (tier + 0.5) * h / courses, at.z), Vector3(0.85 * width * narrowing, h / courses - 0.018, 0.75 * depth * narrowing), seed_value, 0, 0.15)
			marks.append({"at": Vector3(at.x, 0.3 + h * 0.45, at.z + 0.38 * depth), "size": Vector3(0.055, h * 0.3, 0.025)})
		add(parts, "central_altar", Vector3(0, 0.6, 0), Vector3(1.0, 0.6, 0.9), seed_value)
	else:
		# Layered court and compact sanctum share the same generated gateway grammar.
		for tier in range(3):
			add(parts, "terrace_%d" % tier, Vector3(0, 0.1 + tier * 0.18, 0), Vector3((5.6 - tier * 0.5) * width, 0.2, (4.7 - tier * 0.5) * depth), seed_value)
		for row in range(3):
			for col in range(4):
				add(parts, "court_slab_%d_%d" % [row, col], Vector3((col - 1.5) * width, 0.57, (row - 1) * depth), Vector3(0.95 * width, 0.18, 0.95 * depth), seed_value)
		var gate := layout(2, seed_value, 0.8, damage, 0, courses, break_variation)
		for gate_part in gate.parts:
			var copy: Dictionary = gate_part.duplicate(true)
			copy.id = "gateway_" + copy.id
			copy.at += Vector3(0, 0.66, -0.7 * depth)
			parts.append(copy)
		for groove in gate.marks:
			marks.append({"at": groove.at + Vector3(0, 0.66, -0.7 * depth), "size": groove.size})
		if family == 6:
			for i in range(3):
				var h := (1.25 if i == 1 else 2.6) * height * float(remaining_courses(seed_value, "column/%d/break" % i, courses, damage * 0.65, break_variation)) / courses
				var at := Vector3((-2 if i < 2 else 2) * width, 0.66 + h / 2, (0.8 if i % 2 == 0 else -0.8) * depth)
				add(parts, "column_%d" % i, at, Vector3(0.5, h, 0.5), seed_value)
				parts[-1]["shape"] = "column"
				add(parts, "capital_%d" % i, Vector3(at.x, 0.66 + h, at.z), Vector3(0.85, 0.2, 0.85), seed_value)
				add(parts, "column_foot_%d" % i, Vector3(at.x, 0.74, at.z), Vector3(0.85, 0.16, 0.85), seed_value)
		else:
			for side in [-1, 1]:
				for tier in range(remaining_courses(seed_value, "sanctum/%d/break" % side, courses, damage * 0.7, break_variation)):
					add(parts, "sanctum_wall_%d_%d" % [side, tier], Vector3(side * 1.8 * width, 0.66 + (tier + 0.5) * 0.55, -0.7 * depth), Vector3(0.85, 0.52, 1.1), seed_value)
			add(parts, "offering_plinth", Vector3(0, 0.93, 0.6 * depth), Vector3(1.2, 0.55, 0.9), seed_value)
	# Decoration has its own stream: rubble count cannot change the parent structure.
	var scatter := random_stream(seed_value, "family/%d/rubble" % family)
	for i in range(rubble):
		var angle := scatter.randf_range(0, TAU)
		var radius := scatter.randf_range(3.6, 4.0) if family >= 6 else scatter.randf_range(2.5, 2.9)
		var size := Vector3(scatter.randf_range(0.18, 0.45), scatter.randf_range(0.14, 0.36), scatter.randf_range(0.2, 0.5))
		add(parts, "rubble_%d" % i, Vector3(cos(angle) * radius, size.y / 2, sin(angle) * radius), size, seed_value, 0, 0.35)
		parts[-1].yaw = scatter.randf_range(-PI, PI)
	for part in parts:
		part.at *= scale_value
		part.size *= scale_value
	for mark in marks:
		mark.at *= scale_value
		mark.size *= scale_value
	var node_anchor := Vector3(0, 0.95, 0.7)
	if family == 1: node_anchor = Vector3(0, 0.95, marks[0].at.z / scale_value - 0.1)
	elif family == 2: node_anchor = Vector3(marks[0].at.x / scale_value, 1.6, marks[0].at.z / scale_value - 0.1)
	elif family == 3: node_anchor = Vector3(0, 0.245, 1.3 * depth)
	elif family == 4: node_anchor = Vector3(-1.3 * width, 1.5, 0.425 * depth - 0.1)
	elif family == 5: node_anchor = Vector3(0, 0.65, 0.35)
	elif family == 6: node_anchor = Vector3(0, 0.66, 1.25 * depth)
	else: node_anchor = Vector3(0, 0.93, 0.6 * depth + 0.35)
	var contacts := channel_contacts(family, width, height, depth, node_anchor)
	var inlet := PackedVector3Array([node_anchor * scale_value + Vector3(-0.65, 0, 0.12)])
	for point in contacts[0]: inlet.append(point * scale_value)
	inlet.append(node_anchor * scale_value + Vector3(0, 0, 0.1))
	var outlet := PackedVector3Array([node_anchor * scale_value + Vector3(0, 0, 0.1)])
	for point in contacts[1]: outlet.append(point * scale_value)
	outlet.append(node_anchor * scale_value + Vector3(0.65, 0, 0.12))
	inlet = fracture_route(inlet, seed_value, "family/%d/inlet" % family)
	outlet = fracture_route(outlet, seed_value, "family/%d/outlet" % family)
	return {"version": VERSION, "family": family, "parts": parts, "marks": marks, "scale": scale_value, "courses": courses, "break_variation": break_variation, "node_anchor": node_anchor * scale_value, "input_channel": inlet, "output_channel": outlet}

static func remaining_courses(seed_value: int, key: String, count: int, damage: float, variation: float) -> int:
	var factor := lerpf(1.0, random_stream(seed_value, key).randf_range(0.55, 1.45), variation)
	return clampi(count - floori(damage * (count - 1) * factor), 1, count)

static func channel_contacts(family: int, width: float, height: float, depth: float, _anchor: Vector3) -> Array:
	# Routes are authored against the same joint dimensions as the stone grammar.
	# Node collars are connectors; the remaining points trace surface crevices.
	if family == 1:
		var z := 0.405 * depth
		var lower_joint := 0.4 + 2.7 * height / 3
		var upper_joint := 0.4 + 2 * 2.7 * height / 3
		return [[Vector3(-0.48 * width, lower_joint, z), Vector3(0, lower_joint, z)], [Vector3(0, upper_joint, z), Vector3(0.42 * width, upper_joint, z)]]
	if family == 2:
		var x := -1.5 * width
		var z := 0.485 * depth
		return [[Vector3(x - 0.3, 0.36 + 1.9 * height / 3, z), Vector3(x + 0.3, 0.36 + 1.9 * height / 3, z)], [Vector3(x - 0.3, 0.36 + 2 * 1.9 * height / 3, z), Vector3(x + 0.3, 0.36 + 2 * 1.9 * height / 3, z)]]
	if family == 4:
		return [[Vector3(-1.5 * width, 1.9, 0.44 * depth), Vector3(-1.1 * width, 0.8, 0.44 * depth)], [Vector3(-1.1 * width, 0.8, 0.44 * depth), Vector3(0, 0.36, 0.44 * depth)]]
	var floor_y := 0.245 if family == 3 else (0.31 if family == 5 else 0.67)
	var step_x := 1.12 * width if family == 3 else width
	var step_z := 0.575 * depth if family == 3 else 0.5 * depth
	return [[Vector3(-step_x, floor_y, step_z * 2), Vector3(-step_x, floor_y, step_z), Vector3(0, floor_y, step_z)], [Vector3(0, floor_y, -step_z), Vector3(step_x, floor_y, -step_z), Vector3(step_x, floor_y, step_z * 2)]]

static func fracture_route(route: PackedVector3Array, seed_value: int, key: String) -> PackedVector3Array:
	var rng := random_stream(seed_value, key)
	var result := PackedVector3Array([route[0]])
	for i in range(1, route.size()):
		var delta := route[i] - route[i - 1]
		var sideways := Vector3(-delta.y, delta.x, 0) if absf(delta.y) > 0.01 else Vector3(-delta.z, 0, delta.x)
		sideways = sideways.normalized() * minf(0.045, delta.length() * 0.05)
		for fraction in [0.33, 0.67]: result.append(route[i - 1].lerp(route[i], fraction) + sideways * rng.randf_range(-1, 1))
		result.append(route[i])
	return result

static func add(parts: Array[Dictionary], key: String, at: Vector3, size: Vector3, seed_value: int, roll: float = 0.0, taper: float = 0.05) -> void:
	if parts.size() >= MAX_PARTS: return
	var rng := random_stream(seed_value, key + "/surface")
	parts.append({"id": key, "at": at, "size": size, "roll": roll, "yaw": 0.0, "taper": taper, "bevel": rng.randf_range(0.05, 0.15), "tone": rng.randf_range(0.0, 0.6)})

static func stone_mesh(part: Dictionary) -> ArrayMesh:
	var size: Vector3 = part.size
	if part.get("shape", "stone") == "column":
		var column := CylinderMesh.new()
		column.top_radius = size.x * 0.43
		column.bottom_radius = size.x * 0.5
		column.height = size.y
		column.radial_segments = 12
		var result := ArrayMesh.new()
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, column.surface_get_arrays(0))
		return result
	var corners: Array[Vector3] = []
	# Three rectangular rings form a chamfered, tapered stone with flat face normals.
	for ring in range(3):
		var factor := 1.0 if ring < 2 else 1.0 - float(part.taper)
		var y := -0.5 if ring == 0 else (0.5 - float(part.bevel) if ring == 1 else 0.5)
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			corners.append(Vector3(corner.x * 0.5 * size.x * factor, y * size.y, corner.y * 0.5 * size.z * factor))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	# Indices are clockwise viewed from outside, matching Godot front faces.
	for triangle in [[0, 2, 1], [0, 3, 2], [8, 9, 10], [8, 10, 11]]:
		for index in triangle: surface.add_vertex(corners[index])
	for ring in range(2):
		for side in range(4):
			var a := ring * 4 + side
			var b := ring * 4 + (side + 1) % 4
			var c := b + 4
			var d := a + 4
			for index in [a, c, d, a, b, c]: surface.add_vertex(corners[index])
	surface.generate_normals()
	return surface.commit()
