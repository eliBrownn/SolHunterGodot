extends SceneTree
const Library = preload("res://scripts/scenery/plant_library.gd")
const Builder = preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd")
var failures := 0
var checks := 0
class FlatTerrain extends WorldTerrain:
	var blocked := false
	var biome := 0
	var kind := "tree"
	func sample(_cell: Vector2i) -> Dictionary: return {"ground":biome,"obstacle":0,"walkable":true}
	func flora_kind(_cell: Vector2i,_data: Dictionary) -> String: return kind
	func scenery_reserved(_cell: Vector2i) -> bool: return blocked
	func route_axes(_cell: Vector2i,_margin: int=0) -> int: return 0
	func is_camp(_cell: Vector2i) -> bool: return false
	func is_landmark(_cell: Vector2i) -> bool: return false
	func surface_height(_point: Vector2) -> float: return 0.0
	func surface_normal(_point: Vector2) -> Vector3: return Vector3.UP
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	Library.refresh()
	var terrain := FlatTerrain.new(18)
	var cell := Vector2i(60,60)
	for biome in range(4):
		terrain.biome=biome
		for role in ["reservoir","warden","mender","regulator"]:
			var traits := {"role":"reservoir" if role=="reservoir" else "receiver","class":"" if role=="reservoir" else role}
			var signatures := {}
			for variant in range(3):
				var item: Resource = Library.procedural_definition(biome,traits,variant)
				check(item.valid(),"Generated definition validates")
				check(item.size_class==variant,"Physical class follows palette size independently of role")
				check(item==Library.procedural_definition(biome,traits,variant),"Palette reuses geometry")
				var parts: Dictionary = Library.model(item)
				check(parts.supported and parts.triangles<=30000 and parts.surfaces<=12,"Every palette model fits runtime budgets")
				var arrays := []
				for piece: Dictionary in parts.pieces:
					for surface in range(piece.mesh.get_surface_count()): arrays.append(piece.mesh.surface_get_arrays(surface))
				signatures[hash(arrays)]=true
			check(signatures.size()==3,"All three variants have distinct geometry")
		terrain.kind="tree"
		var record: Dictionary = Library.placement(terrain,cell,terrain.sample(cell),"tree",true)
		check(not record.is_empty(),"Procedural tree reaches live placement in each biome")
		if not record.is_empty():
			check(record.flora_id==FloraCatalog.id_for(cell) and record.high_anchor.is_finite(),"Canonical identity and crown remain connected")
		terrain.blocked=true
		check(Library.placement(terrain,cell,terrain.sample(cell),"tree",true).is_empty(),"Protected spaces reject procedural trees")
		terrain.blocked=false
		terrain.kind="plant"
		for specialist in FloraTraits.CLASSES:
			var at := cell
			while FloraTraits.category(terrain.world_seed,{"id":FloraCatalog.id_for(at),"cell":[at.x,at.y],"kind":"plant"})!=specialist: at.x+=1
			check(not Library.placement(terrain,at,terrain.sample(at),"plant",true).is_empty(),"Each specialist uses procedural placement")
	# Exercise renderer admission, including callers holding older resource palettes.
	var chunk := preload("res://scripts/presentation/solid_chunk.gd").new()
	var legacy := preload("res://assets/nature/CommonTree_1.gltf")
	chunk.add_nature(legacy,Vector3.ZERO,3.0,0.0,"tree")
	check(chunk.batches.is_empty() and chunk.pick_objects.is_empty(),"Legacy tree fallback cannot render or supply picking geometry")
	chunk.add_nature(preload("res://assets/nature/Plant_7.gltf"),Vector3.ZERO,0.5,0.0,"detail")
	check(chunk.batches.is_empty(),"Legacy specialist fallback cannot render")
	chunk.add_composed_nature({"living":true,"patch":"pond","asset":"legacy_pond"})
	check(chunk.batches.is_empty(),"Legacy living pond and biome dressing cannot render")
	terrain.kind="tree"
	var current := Library.placement(terrain,cell,terrain.sample(cell),"tree",true)
	chunk.add_composed_nature(current)
	check(not chunk.batches.is_empty() and not chunk.pick_objects.is_empty(),"Current library geometry reaches rendering and picking")
	check(chunk.living_sources.has(cell),"Current library body retains its canonical Vastra endpoint")
	chunk.free()
	var materials: Array[Material] = Builder.make_anatomy_materials()
	var builder = Builder.new()
	var baseline: Dictionary = builder.create_sample(1,3,72,{},materials)
	var repeat: Dictionary = builder.create_sample(1,3,72,{},materials)
	check(hash(baseline.organs)==hash(repeat.organs) and hash(baseline.links)==hash(repeat.links),"Seed reconstructs identical connected anatomy")
	var baseline_arrays := []
	for surface in range(baseline.body.get_surface_count()): baseline_arrays.append(baseline.body.surface_get_arrays(surface))
	for setting in [{"leaf_architecture":1},{"leaf_architecture":2},{"leaf_architecture":3},{"leaf_architecture":4},{"branch_irregularity":1.0},{"leaf_asymmetry":1.0},{"organic_softness":0.0},{"organic_softness":1.0},{"foliage_fullness":0.0},{"foliage_fullness":2.0},{"branching_depth":0},{"branching_depth":3},{"branching_spread":1.3},{"branching_reduction":0.4}]:
		var sample: Dictionary = builder.create_sample(1,3,72,setting,materials)
		var arrays := []
		for surface in range(sample.body.get_surface_count()): arrays.append(sample.body.surface_get_arrays(surface))
		check(hash(arrays)!=hash(baseline_arrays) or setting.get("leaf_architecture",0)==2,"Diversity control changes real geometry: "+str(setting))
		check(sample.body.get_aabb().size.is_finite(),"Extreme diversity remains finite")
	for biome in range(4):
		var tree: Dictionary=builder.create_sample(biome,1,72,{},materials)
		for link: Dictionary in tree.links:
			if str(link.to).begins_with("canopy"):
				var rise: Vector3=link.path.back()-link.path.front()
				check(rise.y>0 and link.path[1].y>link.path[0].y,"Reservoir scaffold climbs before reaching outward")
	var forked: Dictionary=builder.create_sample(1,1,72,{"tree_fork_depth":2},materials)
	var simple: Dictionary=builder.create_sample(1,1,72,{"tree_fork_depth":0},materials)
	var single_split: Dictionary=builder.create_sample(1,1,72,{"tree_fork_depth":1},materials)
	check(forked.organs.size()>single_split.organs.size(),"Second fractal generation adds connected branches beyond the first split")
	check(forked.organs.size()>simple.organs.size(),"Structural fork control adds real connected limbs")
	var organ_ids := {}
	for organ: Dictionary in forked.organs: organ_ids[organ.id]=true
	for organ: Dictionary in forked.organs:
		if organ.kind=="Branch fork": check(organ_ids.has(organ.parent),"Every visible tree split attaches to an existing limb")
	for role in range(6):
		var neutral: Dictionary=builder.create_sample(0,role,72,{"color_gradient":0.0,"color_diversity":0.0},materials)
		for assignments in [{"bark_palette":3},{"foliage_palette":5},{"flower_palette":posmod(role+1,6)+1},{"color_gradient":1.0}]:
			var settings: Dictionary={"color_gradient":0.0,"color_diversity":0.0}
			settings.merge(assignments,true)
			var colored: Dictionary=builder.create_sample(0,role,72,settings,materials)
			check(hash(neutral.organs)==hash(colored.organs),"Color changes leave anatomy unchanged for every role")
			var changed := false
			for surface in range(neutral.body.get_surface_count()):
				if hash(neutral.body.surface_get_arrays(surface)[Mesh.ARRAY_COLOR])!=hash(colored.body.surface_get_arrays(surface)[Mesh.ARRAY_COLOR]): changed=true
			# Reservoirs have no blossom surfaces in most biomes.
			check(changed or (assignments.has("flower_palette") and role in [1,3]),"Color assignment reaches rendered plant surfaces: "+str(role)+str(assignments))
	for role in [0,2,3,4,5]:
		var expressed: Dictionary=builder.create_sample(0,role,72,{"role_expression":1.0},materials)
		var plain: Dictionary=builder.create_sample(0,role,72,{"role_expression":0.0},materials)
		check(expressed.vertices>plain.vertices,"Role expression builds connected role-specific surfaces")
	var branching: Dictionary = builder.create_sample(1,1,72,{"branching_depth":3},materials)
	var depths := {}
	var ends := {}
	for branch: Dictionary in branching.foliage_branches:
		depths[branch.depth]=true
		if branch.depth<3:
			check(ends.has(branch.from),"Smaller branches attach exactly to a parent tip")
			if ends.has(branch.from): check(branch.length<ends[branch.from],"Each branching generation gets smaller")
		ends[branch.to]=branch.length
	check(depths.size()==3,"Three repeated structural scales are actually built")
	terrain.kind="plant"
	var grass_cell := cell
	while FloraTraits.role(terrain.world_seed,{"id":FloraCatalog.id_for(grass_cell),"cell":[grass_cell.x,grass_cell.y],"kind":"plant"})!="emanator": grass_cell.x+=1
	# Use an empty library so the assertion concerns the built-in palette only.
	Library.entries.clear()
	check(Library.placement(terrain,grass_cell,terrain.sample(grass_cell),"plant",true).is_empty(),"Approved grass keeps emanator ownership")
	Library.set_weather(Vector2.RIGHT,12.5,0.6)
	for parts: Dictionary in Library.models.values():
		for piece: Dictionary in parts.pieces:
			for surface in range(piece.mesh.get_surface_count()):
				var material: Material=piece.mesh.surface_get_material(surface)
				if material is ShaderMaterial: check(material.get_shader_parameter("wind_time")==12.5,"All procedural foliage receives weather")
	print("PLANT DIVERSITY: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)

