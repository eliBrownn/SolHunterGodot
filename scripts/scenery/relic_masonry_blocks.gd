extends RefCounted
## Individual relic masonry assets. No assemblies, placement or gameplay behavior.
const VERSION := 2
const Carving = preload("res://scripts/scenery/relic_carving.gd")
const KEYS := ["wedge", "keystone", "corner", "fork", "arc", "half_round", "hex_shaft", "obelisk", "split_slab", "chamfered_lintel", "stepped_cap", "broken_tooth"]

static func definition(key: String, seed_value: int = 73, scale_value: float = 1.0) -> Dictionary:
	if not key in KEYS or seed_value < 0 or seed_value > 99999 or not is_finite(scale_value) or scale_value < 0.25 or scale_value > 4: return {}
	var profile := PackedVector2Array()
	var height := 0.65
	var taper := 1.0
	var top_shift := Vector2.ZERO
	match key:
		"wedge": profile = PackedVector2Array([Vector2(-1,-0.6),Vector2(1,-0.6),Vector2(-1,0.6)])
		"keystone": profile = PackedVector2Array([Vector2(-0.5,-0.65),Vector2(0.5,-0.65),Vector2(0.95,0.65),Vector2(-0.95,0.65)])
		"corner": profile = PackedVector2Array([Vector2(-1,-1),Vector2(1,-1),Vector2(1,-0.35),Vector2(-0.35,-0.35),Vector2(-0.35,1),Vector2(-1,1)])
		"fork": profile = PackedVector2Array([Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(0.4,1),Vector2(0.4,-0.35),Vector2(-0.4,-0.35),Vector2(-0.4,1),Vector2(-1,1)])
		"arc":
			for i in range(9):
				var angle := lerpf(-PI * 0.7, PI * 0.1, i / 8.0)
				profile.append(Vector2(cos(angle),sin(angle))*1.25)
			for i in range(8,-1,-1):
				var angle := lerpf(-PI * 0.7, PI * 0.1, i / 8.0)
				profile.append(Vector2(cos(angle),sin(angle))*0.65)
		"half_round":
			for i in range(9): profile.append(Vector2(cos(i * PI / 8), sin(i * PI / 8)))
		"hex_shaft", "obelisk":
			height = 2.5
			taper = 0.25 if key == "obelisk" else 0.85
			for i in range(6): profile.append(Vector2(cos(i * TAU / 6),sin(i * TAU / 6))*0.6)
		"split_slab":
			profile = PackedVector2Array([Vector2(-1,-0.8),Vector2(1,-0.8),Vector2(1,0.25),Vector2(0.2,0.1),Vector2(0.4,0.7),Vector2(-0.3,0.45),Vector2(-1,0.8)])
			height = 0.3
		"chamfered_lintel":
			profile = PackedVector2Array([Vector2(-1.5,-0.2),Vector2(-1.2,-0.5),Vector2(1.2,-0.5),Vector2(1.5,-0.2),Vector2(1.5,0.2),Vector2(1.2,0.5),Vector2(-1.2,0.5),Vector2(-1.5,0.2)])
		"stepped_cap":
			profile = PackedVector2Array([Vector2(-1,-0.6),Vector2(-0.5,-0.6),Vector2(-0.5,-1),Vector2(0.5,-1),Vector2(0.5,-0.6),Vector2(1,-0.6),Vector2(1,0.6),Vector2(0.5,0.6),Vector2(0.5,1),Vector2(-0.5,1),Vector2(-0.5,0.6),Vector2(-1,0.6)])
			taper = 0.8
		"broken_tooth":
			profile = PackedVector2Array([Vector2(-0.7,-0.6),Vector2(0.7,-0.6),Vector2(0.6,0.7),Vector2(-0.55,0.5)])
			height = 1.8
			taper = 0.45
			top_shift = Vector2(0.3,0.1)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("masonry/%d/%s/%d" % [VERSION,key,seed_value])
	height *= scale_value
	for i in range(profile.size()): profile[i] *= scale_value
	return {"version": VERSION, "key": key, "seed": seed_value, "profile": profile, "height": height, "taper": taper, "top_shift": top_shift * scale_value, "support_anchor": Vector3.ZERO, "scale": scale_value, "bevel": 0.045 * scale_value, "etch_depth": 0.045 * scale_value}

# Inset corresponding vertices so concave profiles retain their topology.
static func inset_profile(polygon: PackedVector2Array, distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(polygon.size()):
		var incoming := (polygon[i] - polygon[(i - 1 + polygon.size()) % polygon.size()]).normalized()
		var outgoing := (polygon[(i + 1) % polygon.size()] - polygon[i]).normalized()
		var n1 := Vector2(-incoming.y,incoming.x)
		var n2 := Vector2(-outgoing.y,outgoing.x)
		var bisector := (n1+n2).normalized()
		result.append(polygon[i] + bisector * minf(distance / maxf(0.25,bisector.dot(n1)),distance*2.5))
	return result

static func mesh(data: Dictionary) -> ArrayMesh:
	if data.is_empty(): return ArrayMesh.new()
	# Detail is generated in module units, then scaled uniformly with the base asset.
	var scale_value: float = data.scale
	var polygon: PackedVector2Array = data.profile.duplicate()
	for i in range(polygon.size()): polygon[i] /= scale_value
	var height: float = data.height / scale_value
	var shift: Vector2 = data.top_shift / scale_value
	var bevel: float = data.bevel / scale_value
	var inset := inset_profile(polygon,bevel)
	var crown := PackedVector2Array()
	for point in polygon: crown.append(point * data.taper + shift)
	var cap := inset_profile(crown,bevel)
	# Small seeded chips are restricted to crown edges; support surfaces stay flat.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("masonry/wear/%s/%d" % [data.key,data.seed])
	for i in range(cap.size()):
		if rng.randf() < 0.22: cap[i] = cap[i].lerp(crown[(i+1)%cap.size()],0.035)
	var rings: Array[PackedVector3Array] = []
	for index in range(4):
		var ring := PackedVector3Array()
		var profile: PackedVector2Array = [inset,polygon,crown,cap][index]
		var y: float = [0.0,bevel,height-bevel,height][index]
		for point in profile: ring.append(Vector3(point.x,y,point.y))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for pair in [[0,inset],[3,cap]]:
		var indices := Geometry2D.triangulate_polygon(pair[1])
		for i in range(0,indices.size(),3):
			for j in ([0,2,1] if pair[0] == 0 else [0,1,2]): surface.add_vertex(rings[pair[0]][indices[i+j]])
	for tier in range(3):
		for i in range(polygon.size()):
			var next := (i+1)%polygon.size()
			for point in [rings[tier][i],rings[tier][next],rings[tier+1][next],rings[tier][i],rings[tier+1][next],rings[tier+1][i]]: surface.add_vertex(point)
	surface.generate_normals()
	var base := surface.commit()
	var routes: Array[PackedVector3Array] = []
	# Common inset perimeter and right-angle side motifs give every module one language.
	var border := inset_profile(crown,0.17)
	var top_route := PackedVector3Array()
	for point in border: top_route.append(Vector3(point.x,height,point.y))
	top_route.append(top_route[0])
	routes.append(top_route)
	for i in range(polygon.size()):
		var a := polygon[i]
		var b := polygon[(i+1)%polygon.size()]
		if a.distance_to(b) < 0.85: continue
		var p := a.lerp(b,0.36)
		var q := a.lerp(b,0.64)
		# Follow the tapered face at each height rather than cutting empty air.
		var route := PackedVector3Array()
		for item in [[p,0.75],[p,0.48],[q,0.48],[q,0.25]]:
			var t: float = item[1]
			var point: Vector2 = item[0] * lerpf(1.0,data.taper,t) + shift*t
			route.append(Vector3(point.x,height*t,point.y))
		routes.append(route)
	var detailed := Carving.carve(base,routes,Vector3(0,-100,0),0,data.etch_depth/scale_value)
	var arrays := detailed.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()): vertices[i] *= scale_value
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return result

static func material() -> StandardMaterial3D:
	var surface: StandardMaterial3D = preload("res://scripts/scenery/structure_stone_materials.gd").create(0)
	surface.vertex_color_use_as_albedo = true
	surface.metallic_specular = 0.15
	return surface
