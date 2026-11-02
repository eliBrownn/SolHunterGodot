extends "res://tools/procedural_plant_lab.gd"
## Synthetic, isolated habitat comparison; not production placement or live ecology.
const Community = preload("res://scripts/world/plant_community.gd")
const Library = preload("res://scripts/scenery/plant_library.gd")
@export_enum("Meadow", "Woodland", "Heath", "Marsh") var habitat := 1
@export_range(3.0,24.0,1.0) var patch_size := 10.0
@export_range(0.0,1.0,0.05) var coverage := 0.65
@export_range(0.5,4.0,0.1) var spacing := 2.0
@export_range(0.0,1.0,0.05) var canopy_influence := 0.65
@export_range(-128,128,16) var geographic_x := 0
@export_range(-128,128,16) var geographic_y := 0
var layout := Community.new()
var readings: Array[Dictionary] = []
var site_cache := {}

func _ready() -> void:
	layout.configure(generation_seed,patch_size,coverage,spacing,canopy_influence,habitat)
	distance_value = 40.0
	pitch = 0.85
	super._ready()

func site(cell: Vector2i) -> Dictionary:
	if site_cache.has(cell): return site_cache[cell]
	# Shared analytic landform for controlled comparisons; a protected curved path.
	var height := sin(cell.x*0.12)*0.55 + cos(cell.y*0.17)*0.4
	var path := 2.0*sin(cell.y*0.16)
	var result := {"admitted":absf(cell.x-path)>1.8, "wetness":clampf(0.5-height*0.4,0,1), "height":height}
	site_cache[cell] = result
	return result

func build_bed(index: int) -> void:
	if index > 1: return
	var started := Time.get_ticks_usec()
	var bed := Node3D.new()
	bed.position.x = -10.0 if index==0 else 10.0
	samples.add_child(bed)
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	var origin := Vector2i(geographic_x,geographic_y)
	for y in range(-8,8):
		for x in range(-8,8):
			for point in [Vector2(x,y),Vector2(x,y+1),Vector2(x+1,y),Vector2(x+1,y),Vector2(x,y+1),Vector2(x+1,y+1)]:
				var cell := Vector2i(point)+origin
				var context := site(cell)
				vertices.append(Vector3(point.x,context.height-0.04,point.y))
				colors.append(Color("91836b") if not context.admitted else Color("546b43"))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var ground := MeshInstance3D.new()
	ground.mesh = mesh
	var surface := StandardMaterial3D.new()
	surface.vertex_color_use_as_albedo = true
	surface.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ground.material_override = surface
	bed.add_child(ground)
	var count := 0
	var trees := 0
	var unique := {}
	for y in range(-8,8):
		for x in range(-8,8):
			var cell := origin+Vector2i(x,y)
			var proposal := layout.sample(cell,site,index==1)
			if proposal.is_empty(): continue
			var tree: bool = proposal.tree
			var item: Resource = Library.procedural_definition(habitat,{"role":"reservoir" if tree else "receiver", "class":"warden"},0 if tree else 1)
			var plant: Node3D = item.scene.instantiate()
			var model: Dictionary = Library.model(item)
			plant.scale = item.scale_for(model.bounds)
			# Fit the full visual footprint inside the proposal used by clearance checks.
			var width: float = maxf(model.bounds.size.x,model.bounds.size.z)*plant.scale.x
			plant.scale *= minf(1.0,float(proposal.radius)*2.0/maxf(width,0.001))
			plant.position = Vector3(x+0.5,proposal.height,y+0.5)
			plant.rotation.y = layout.roll(cell,71)*TAU
			bed.add_child(plant)
			unique[item.plant_id] = true
			count += 1
			if tree: trees += 1
	var label := Label3D.new()
	label.text = ("INDEPENDENT SCATTER" if index==0 else "PATCHES + NEIGHBORS")+"\n%d plants / %d trees / %d shared bodies"%[count,trees,unique.size()]
	label.position = Vector3(0,0,9.0)
	label.font_size = 38
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bed.add_child(label)
	readings.append({"mode":index,"plants":count,"trees":trees,"shared_bodies":unique.size(),"build_ms":(Time.get_ticks_usec()-started)/1000.0})

func build_controls() -> void:
	# Keep the inherited selector owned, although shared workstation controls replace it.
	add_child(family_picker)
	family_picker.hide()

func workstation_readings() -> Dictionary:
	return {"comparison":readings,"seed":generation_seed,"scope":"Synthetic habitat fixture; no canonical flora or expedition writes. Independent scatter is a control, not the production generator."}

func workstation_parameter_info(key: String) -> Dictionary:
	if key in ["branch_count","plant_size","leaf_size","foliage_density","leaf_curl","wind_strength","show_labels"]: return {"hidden":true}
	return {"group":"Coverage", "help":"Lab only. Rebuilds on slider release; identical seed and absolute coordinates reproduce placement."}
