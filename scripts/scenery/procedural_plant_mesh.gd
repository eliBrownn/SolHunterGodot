extends RefCounted
## Shared procedural morphology builder. Each specimen owns four batched mesh surfaces.
## Local RNG streams keep geometry reproducible without touching world generation.
const LABELS := ["Broadleaf", "Conifer", "Shrub", "Fern", "Flowers", "Grass", "Reeds", "Vastra"]
var rng := RandomNumberGenerator.new()
var surfaces: Array[SurfaceTool] = []
var counts: Array[int] = [0, 0, 0, 0]
var leaf_scale := 1.0
var foliage := 1.0
var branches := 7
var curl := 0.35
var organic_softness := 0.7
## Export-only tessellation; topology, branch paths and organ anchors stay procedural.
var tube_sides := 8
var tube_metric_uv := false

func create(form: int, specimen_seed: int, settings: Dictionary, materials: Array[Material]) -> ArrayMesh:
	prepare(specimen_seed, settings, materials)
	match form:
		0, 1: tree(form == 1)
		2: shrub()
		3: fern()
		4: flowers()
		5: grass()
		6: reeds()
		7: vastra()
	return finish()

func prepare(specimen_seed: int, settings: Dictionary, materials: Array[Material]) -> void:
	rng.seed = specimen_seed
	organic_softness = clampf(float(settings.get("organic_softness",0.7)),0.0,1.0)
	leaf_scale = settings.get("leaf_scale", 1.0)
	foliage = settings.get("foliage", 1.0)
	branches = settings.get("branches", 7)
	curl = settings.get("curl", 0.35)
	counts.clear()
	surfaces.clear()
	for index in range(materials.size()):
		counts.append(0)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.set_material(materials[index])
		surfaces.append(surface)

func finish() -> ArrayMesh:
	var result := ArrayMesh.new()
	for index in range(surfaces.size()):
		if counts[index] == 0: continue
		surfaces[index].generate_normals()
		surfaces[index].generate_tangents()
		surfaces[index].index()
		surfaces[index].commit(result)
		result.surface_set_name(result.get_surface_count()-1, str(index))
	return result

func vertex(surface: int, at: Vector3, uv: Vector2, color: Color) -> void:
	surfaces[surface].set_smooth_group(0)
	surfaces[surface].set_uv(uv)
	surfaces[surface].set_color(color)
	surfaces[surface].add_vertex(at)
	counts[surface] += 1

func quad(surface: int, points: Array[Vector3], uvs: Array[Vector2], color: Color) -> void:
	# Clockwise front faces; foliage is double sided for its underside.
	for index in [0, 2, 1, 0, 3, 2]: vertex(surface, points[index], uvs[index], color)

func tube(path: Array[Vector3], radius: float, surface: int = 0, tint: Color = Color.WHITE, end_ratio: float = 0.12, curve_detail: int = 0) -> void:
	if path.size()<2: return
	var curve: Array[Vector3] = path.duplicate()
	if path.size()==3 and organic_softness>0.0:
		curve.clear()
		# Interpolate the authored middle anchor with a smooth quadratic arc.
		var control := path[1]*2.0-(path[0]+path[2])*0.5
		var curve_steps := 8 if radius>0.04 else 4
		if curve_detail>0: curve_steps=maxi(2,curve_detail)
		for index in range(curve_steps+1):
			var t := index/float(curve_steps)
			var soft := path[0]*(1.0-t)*(1.0-t)+control*2.0*t*(1.0-t)+path[2]*t*t
			var angular := path[0].lerp(path[1],t*2.0) if t<=0.5 else path[1].lerp(path[2],t*2.0-1.0)
			curve.append(angular.lerp(soft,organic_softness))
	elif organic_softness>0.0 and path.size()>3:
		# Smooth every multi-joint stem, retaining all attachment anchors.
		curve.clear()
		for segment in range(path.size()-1):
			var before: Vector3=path[maxi(0,segment-1)]
			var start: Vector3=path[segment]
			var end: Vector3=path[segment+1]
			var after: Vector3=path[mini(path.size()-1,segment+2)]
			for step in range(2):
				var t := step/2.0
				var soft := start.cubic_interpolate(end,before,after,t)
				curve.append(start.lerp(end,t).lerp(soft,organic_softness))
		curve.append(path.back())
	var closed := curve[0].is_equal_approx(curve.back())
	var across_frames: Array[Vector3] = []
	var side_frames: Array[Vector3] = []
	for index in range(curve.size()):
		var tangent := (curve[mini(index+1,curve.size()-1)]-curve[maxi(0,index-1)]).normalized()
		if closed and index in [0,curve.size()-1]: tangent=(curve[1]-curve[curve.size()-2]).normalized()
		if tangent.length_squared()<0.0001: tangent=Vector3.UP
		var across: Vector3
		if index==0:
			across=tangent.cross(Vector3.RIGHT if absf(tangent.x)<0.9 else Vector3.FORWARD).normalized()
		else:
			var previous: Vector3=across_frames.back()
			across=(previous-tangent*previous.dot(tangent)).normalized()
			if across.length_squared()<0.0001: across=tangent.cross(Vector3.UP if absf(tangent.y)<0.9 else Vector3.RIGHT).normalized()
		if closed and index==curve.size()-1: across=across_frames[0]
		across_frames.append(across)
		side_frames.append(tangent.cross(across).normalized())
	var distance_along := 0.0
	for step in range(curve.size()-1):
		var next_distance := distance_along+curve[step].distance_to(curve[step+1])
		var r0 := radius*lerpf(1.0,end_ratio,float(step)/(curve.size()-1))
		var r1 := radius*lerpf(1.0,end_ratio,float(step+1)/(curve.size()-1))
		if closed:
			r0=radius
			r1=radius
		for ring in range(tube_sides):
			var a := TAU*ring/float(tube_sides)
			var b := TAU*(ring+1)/float(tube_sides)
			var start0 := across_frames[step]*cos(a)+side_frames[step]*sin(a)
			var start1 := across_frames[step]*cos(b)+side_frames[step]*sin(b)
			var end0 := across_frames[step+1]*cos(a)+side_frames[step+1]*sin(a)
			var end1 := across_frames[step+1]*cos(b)+side_frames[step+1]*sin(b)
			var uvs: Array[Vector2] = [Vector2(float(ring)/tube_sides,step*0.4),Vector2(float(ring+1)/tube_sides,step*0.4),Vector2(float(ring+1)/tube_sides,(step+1)*0.4),Vector2(float(ring)/tube_sides,(step+1)*0.4)]
			if tube_metric_uv and surface in [0,5]:
				# Bark repeats by surface distance, independently of curve tessellation.
				var u0 := float(ring)/tube_sides
				var u1 := float(ring+1)/tube_sides
				uvs=[Vector2(u0*TAU*r0,distance_along)*2.0,Vector2(u1*TAU*r0,distance_along)*2.0,Vector2(u1*TAU*r1,next_distance)*2.0,Vector2(u0*TAU*r1,next_distance)*2.0]
			if surface==3: uvs=[Vector2(0.10,0.2),Vector2(0.14,0.2),Vector2(0.14,0.3),Vector2(0.10,0.3)]
			quad(surface,[curve[step]+start0*r0,curve[step]+start1*r0,curve[step+1]+end1*r1,curve[step+1]+end0*r1],uvs,tint)
		distance_along=next_distance

func leaf(base: Vector3, direction: Vector3, length: float, width: float, surface: int = 1, tint: Color = Color.WHITE, twist: float = 0.0) -> void:
	var forward := direction.normalized()
	var right := forward.cross(Vector3.UP if absf(forward.y) < 0.95 else Vector3.FORWARD).normalized().rotated(forward, twist)
	var normal := right.cross(forward).normalized()
	# Sample the first painted green leaf in the supplied Leaves.png atlas.
	# Geometry follows its silhouette; inset UVs keep atlas neighbors out.
	for segment in range(6):
		var t0 := segment / 6.0
		var t1 := (segment + 1) / 6.0
		for half in [-1.0, 1.0]:
			var points: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for corner in [Vector2(t0, 0), Vector2(t0, half), Vector2(t1, half), Vector2(t1, 0)]:
				var t: float = corner.x
				var profile := maxf(0.012, pow(sin(PI * t), 0.8))
				var center := base + forward * (length * t) + Vector3.UP * (length * curl * sin(PI*t) * 0.25) - normal * (length * curl * t*t * 0.3)
				points.append(center + right * (corner.y * width * profile * 0.5) + normal * (absf(corner.y) * width * profile * 0.08))
				uvs.append(Vector2(0.119 + corner.y * 0.056 * profile, lerpf(0.421, 0.053, t)))
			quad(surface, points, uvs, tint)

func radial(angle: float, up: float = 0.0) -> Vector3:
	return Vector3(cos(angle), up, sin(angle))

func leaf_spray(at: Vector3, reach: float, amount: int, tint: Color = Color.WHITE) -> void:
	for index in range(maxi(1, int(amount * foliage))):
		var angle := rng.randf() * TAU
		var direction := radial(angle, rng.randf_range(-0.15, 1.1)).normalized()
		leaf(at + direction * rng.randf_range(0, reach * 0.3), direction, reach * leaf_scale * rng.randf_range(0.65, 1.1), reach * leaf_scale * 0.45, 1, tint, rng.randf_range(-0.6,0.6))

func tree(conifer: bool) -> void:
	var height := rng.randf_range(2.25, 2.85)
	var lean := radial(rng.randf()*TAU) * rng.randf_range(0.08,0.25)
	var trunk: Array[Vector3] = []
	for index in range(7):
		var t := index / 6.0
		trunk.append(lean * t*t + Vector3.UP * height*t)
	tube(trunk, 0.12)
	for index in range(branches):
		var t := lerpf(0.32, 0.9, float(index) / maxi(1,branches-1))
		var origin := lean*t*t + Vector3.UP*height*t
		var direction := radial(index * 2.399 + rng.randf_range(-0.25,0.25))
		var reach := (1.0-t)*1.5 + 0.2 if conifer else rng.randf_range(0.62,1.0)
		var tip := origin + direction*reach + Vector3.UP * (0.06 if conifer else 0.35)
		tube([origin, origin.lerp(tip,0.55) + Vector3.DOWN*0.08, tip], 0.045*(1.0-t)+0.012)
		if conifer:
			for twig in range(maxi(3,int(8*foliage))):
				var at := origin.lerp(tip,(twig+1)/float(maxi(3,int(8*foliage)) + 1))
				for side in [-1,1]:
					leaf(at, direction.rotated(Vector3.UP,side*0.7) + Vector3.UP*0.3, (0.45+0.3*(1.0-t))*leaf_scale,0.12*leaf_scale,1,Color("a3bd9e"))
		else:
			leaf_spray(tip, 0.65, 14)
			for side in [-1,1]:
				var fork := origin.lerp(tip,0.6) + direction.rotated(Vector3.UP,side*0.65)*0.42 + Vector3.UP*0.3
				tube([origin.lerp(tip,0.5),fork],0.018)
				leaf_spray(fork,0.48,7)
	leaf_spray(trunk[-1],0.48 if conifer else 0.65,9)

func shrub() -> void:
	for index in range(branches):
		var direction := radial(index*2.399 + rng.randf_range(-0.2,0.2))
		var end := direction*rng.randf_range(0.3,0.65) + Vector3.UP*rng.randf_range(0.55,1.0)
		tube([Vector3.ZERO, end*0.55, end],0.025)
		leaf_spray(end,0.4,9)
		leaf_spray(end*0.55,0.35,5)

func fern() -> void:
	for index in range(branches):
		var direction := radial(index*TAU/branches + rng.randf_range(-0.2,0.2))
		var path: Array[Vector3] = []
		for step in range(11):
			var t := step/10.0
			path.append(direction*t*0.9 + Vector3.UP*(sin(t*PI*0.75)*0.65))
		tube(path,0.012,0,Color("a3b77b"))
		for step in range(1,10):
			var t := step/10.0
			for side in [-1,1]:
				leaf(path[step], direction.rotated(Vector3.UP,side*1.0) + Vector3.UP*0.15, (0.36*(1.0-t)+0.06)*leaf_scale,0.13*leaf_scale*foliage,1,Color("afcb9e"))

func flowers() -> void:
	for index in range(maxi(3,int(branches*foliage))):
		var base := radial(rng.randf()*TAU)*rng.randf_range(0.05,0.45)
		var tip := base + Vector3(rng.randf_range(-0.12,0.12),rng.randf_range(0.45,0.85),rng.randf_range(-0.12,0.12))
		tube([base,base.lerp(tip,0.55),tip],0.012,0,Color("95b377"))
		for side in [-1,1]: leaf(base.lerp(tip,0.35),Vector3(side,0.2,0.3),0.28*leaf_scale,0.13*leaf_scale)
		var petals := 5 + index%2
		for petal in range(petals):
			leaf(tip,radial(TAU*petal/petals,0.18),0.2*leaf_scale,0.17*leaf_scale,2,Color("f5d4e4"))
		# Small textured center, formed as three overlapping rounded lobes.
		for petal in range(3): leaf(tip+Vector3.UP*0.02,radial(TAU*petal/3,0.2),0.07,0.07,2,Color("f1ce72"))

func grass() -> void:
	for index in range(maxi(12,int(branches*7*foliage))):
		var direction := radial(rng.randf()*TAU, rng.randf_range(1.2,2.6))
		leaf(radial(rng.randf()*TAU)*rng.randf_range(0,0.45),direction,rng.randf_range(0.35,0.8)*leaf_scale,0.035*leaf_scale)

func reeds() -> void:
	for index in range(branches):
		var base := radial(rng.randf()*TAU)*rng.randf_range(0.08,0.45)
		var tip := base+Vector3(rng.randf_range(-0.08,0.08),rng.randf_range(1.0,1.5),rng.randf_range(-0.08,0.08))
		tube([base,tip],0.015,0,Color("a7b88c"))
		tube([tip-Vector3.UP*0.19,tip+Vector3.UP*0.02],0.045,0,Color("785d42"))
		for step in range(maxi(2,int(3*foliage))):
			leaf(base.lerp(tip,step*0.18+0.12),radial(index*2.399+step*2,1.3),0.7*leaf_scale,0.075*leaf_scale)

func vastra() -> void:
	# Provisional ribbon/filament morphology; no named species or origin claim.
	for index in range(branches):
		var direction := radial(index*2.399)
		var path: Array[Vector3] = []
		var height := rng.randf_range(0.55,1.15)
		for step in range(13):
			var t := step/12.0
			path.append(direction*(0.12+t*0.35) + Vector3.UP*(t*height) + direction.rotated(Vector3.UP,PI/2)*sin(t*PI)*curl*0.4)
		tube(path,0.024,3,Color("b8d6cf"))
		for step in range(3,maxi(4,int(10*foliage)),2):
			var at := path[mini(step,11)]
			leaf(at,direction.rotated(Vector3.UP,step*0.35)+Vector3.UP*0.7,0.25*leaf_scale,0.12*leaf_scale,3,Color("9bc3c4"))

static func make_materials() -> Array[Material]:
	var materials: Array[Material] = []
	var bark := StandardMaterial3D.new()
	bark.albedo_texture = preload("res://assets/nature/Bark_NormalTree.png")
	bark.normal_enabled = true
	bark.normal_texture = preload("res://assets/nature/Bark_NormalTree_Normal.png")
	bark.roughness = 0.95
	materials.append(bark)
	for index in range(3):
		var surface := ShaderMaterial.new()
		surface.shader = preload("res://shaders/procedural_plant_foliage.gdshader")
		surface.set_shader_parameter("painted_atlas", preload("res://assets/nature/Flowers.png") if index == 1 else preload("res://assets/nature/Leaves.png"))
		surface.set_shader_parameter("flower_surface", index == 1)
		surface.set_shader_parameter("vastra_surface", index == 2)
		materials.append(surface)
	return materials
