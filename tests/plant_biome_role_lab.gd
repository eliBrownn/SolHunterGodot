extends SceneTree
const Builder = preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool,message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func mesh_signature(mesh: ArrayMesh) -> int:
	var data := []
	for index in range(mesh.get_surface_count()): data.append(mesh.surface_get_arrays(index))
	return hash(data)

func run() -> void:
	Engine.set_meta("workstation_session_path","res://artifacts/plant-diversity-anatomy-%d.cfg"%Time.get_ticks_usec())
	var workstation: Control = load("res://scenes/development_workstation.tscn").instantiate()
	root.add_child(workstation)
	workstation.picker.select(workstation.FIXTURES.keys().find("Plants / biomes & Vastra anatomy"))
	workstation.load_fixture()
	var lab: Node3D = workstation.fixture
	check(workstation.viewport.own_world_3d,"Anatomy study has its own world")
	check(lab.specimens.size()==24,"One sample for every biome and role/class combination")
	var settings := {"branches":8,"leaf_scale":1.0,"foliage":1.0,"curl":0.35,"anatomy_scale":1.2}
	var unique := {}
	var plans := {}
	var pigments := {}
	var structures := {}
	var minimum_height := INF
	var maximum_height := 0.0
	for data: Dictionary in lab.specimens:
		var biome: int = Builder.BIOMES.find(data.biome)
		var role: int = 0 if data.role=="emanator" else (1 if data.role=="reservoir" else (2 if data["class"].is_empty() else Builder.ROLES.find(str(data["class"]).capitalize())))
		var key := "%d:%d" % [biome,role]
		check(not unique.has(key),"Unique sample combination: "+key)
		unique[key] = true
		plans[data.growth_plan] = true
		pigments[str(data.pigment)] = true
		structures[data.organs.size()] = true
		var positions := {}
		for organ: Dictionary in data.organs:
			check(not positions.has(organ.id),"Unique anatomical organ ID")
			positions[organ.id] = organ.position
			check(organ.position.is_finite(),"Finite anatomical position")
		var reachable := {"ground":true}
		for iteration in range(data.organs.size()):
			for link: Dictionary in data.links:
				if reachable.has(link.from): reachable[link.to] = true
		check(reachable.size()==data.organs.size(),"Every organ connects to ground collar: "+key)
		for link: Dictionary in data.links:
			check(link.path.front()==positions[link.from] and link.path.back()==positions[link.to],"Rendered conductor path meets both anatomical anchors")
		var builder := Builder.new()
		var one := builder.create_sample(biome,role,data.seed,settings,lab.materials)
		var outer_bounds: AABB = one.body.get_aabb()
		minimum_height = minf(minimum_height,outer_bounds.size.y)
		maximum_height = maxf(maximum_height,outer_bounds.size.y)
		var again := builder.create_sample(biome,role,data.seed,settings,lab.materials)
		check(mesh_signature(one.body)==mesh_signature(again.body) and mesh_signature(one.anatomy)==mesh_signature(again.anatomy),"Seed reconstructs anatomy and outer growth")
		check(one.organs==again.organs and one.links==again.links,"Seed reconstructs organ identities and anchors")
		check(one.body.get_surface_count()>0 and one.anatomy.get_surface_count()>0,"Both cutaway and outer growth have geometry")
		check(one.vertices<90000,"Sample remains within anatomy lab geometry budget")
		var changed := builder.create_sample(biome,role,data.seed+1,settings,lab.materials)
		check(mesh_signature(one.body)!=mesh_signature(changed.body),"A different seed varies the same role/biome sample")
		for limits in [{"branches":3,"leaf_scale":0.5,"foliage":0.4,"curl":0.0,"anatomy_scale":0.6},{"branches":14,"leaf_scale":1.6,"foliage":1.8,"curl":1.0,"anatomy_scale":2.0}]:
			var upper: bool = limits.branches==14
			limits.merge({"height_ratio":1.8 if upper else 0.5,"spread_ratio":1.6 if upper else 0.5,"branch_rise":0.8 if upper else -0.3,"stem_thickness":2.0 if upper else 0.6,"radial_symmetry":1.0 if upper else 0.0,"leaf_width":1.8 if upper else 0.4,"tip_taper":2.3 if upper else 0.3,"leaf_lobes":5 if upper else 0,"lobe_depth":0.7 if upper else 0.0,"droop":1.2 if upper else 0.0,"frond_pairs":12 if upper else 3,"thorn_length":2.0 if upper else 0.0,"organ_height":1.5 if upper else 0.5,"storage_size":1.6 if upper else 0.5,"port_radius":1.8 if upper else 0.5,"root_reach":1.5 if upper else 0.5})
			limits.merge({"color_diversity":1.0 if upper else 0.0,"hue_shift":180 if upper else -180,"height_diversity":2.0 if upper else 0.0,"node_count":16 if upper else 3,"node_spacing":1.8 if upper else 0.4,"branch_twist":1.0 if upper else -1.0,"node_bulk":2.5 if upper else 0.5,"node_elongation":2.5 if upper else 0.3,"node_ridges":6 if upper else 0})
			var extreme := builder.create_sample(biome,role,data.seed,limits,lab.materials)
			var bounds: AABB = extreme.anatomy.get_aabb()
			check(bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.y>0,"Anatomy stays finite at slider limits")
			check(extreme.vertices<90000,"Slider limits preserve lab geometry budget: %s (%d vertices)" % [key,extreme.vertices])
	check(unique.size()==24,"Complete cross-biome coverage")
	check(plans.size()==24,"All samples use distinct authored growth plans")
	check(pigments.size()>=4,"Reviewed foliage pigments retain habitat variation across role plants")
	check(structures.size()>=6,"Growth plans vary anatomical node counts")
	check(maximum_height/minimum_height>5.0,"Collection includes a substantial physical height range")
	for control in [["height_ratio",0,0,1.6],["spread_ratio",0,0,1.5],["branch_rise",0,1,0.7],["stem_thickness",0,1,1.8],["radial_symmetry",0,0,0.0],["leaf_width",0,3,1.6],["tip_taper",0,3,2.0],["leaf_lobes",0,3,5],["lobe_depth",0,3,0.6],["droop",3,1,1.1],["frond_pairs",1,0,10],["thorn_length",2,3,0.0],["organ_height",0,2,1.4],["storage_size",0,2,1.5],["port_radius",3,2,1.6],["root_reach",0,2,1.4]]:
		var builder := Builder.new()
		var before := builder.create_sample(control[1],control[2],77,settings,lab.materials)
		var adjusted := settings.duplicate()
		adjusted[control[0]] = control[3]
		var after := builder.create_sample(control[1],control[2],77,adjusted,lab.materials)
		check(mesh_signature(before.body)!=mesh_signature(after.body) or mesh_signature(before.anatomy)!=mesh_signature(after.anatomy),"Control changes applicable geometry: "+str(control[0]))
	for control in [["color_diversity",0,0,0.0],["hue_shift",0,0,90.0],["height_diversity",0,1,0.0],["node_count",3,5,12],["node_spacing",0,0,1.7],["branch_twist",0,1,0.8],["node_bulk",2,3,2.0],["node_elongation",2,3,2.1],["node_ridges",2,3,0]]:
		var builder := Builder.new()
		var before := builder.create_sample(control[1],control[2],77,settings,lab.materials)
		var adjusted := settings.duplicate()
		adjusted[control[0]] = control[3]
		var after := builder.create_sample(control[1],control[2],77,adjusted,lab.materials)
		check(mesh_signature(before.body)!=mesh_signature(after.body) or mesh_signature(before.anatomy)!=mesh_signature(after.anatomy),"Variety control changes the generated specimen: "+str(control[0]))
	lab.biome_picker.select(0)
	lab.role_picker.select(4)
	lab.refresh_view()
	var visible := 0
	for bed in lab.beds:
		if bed.node.visible: visible += 1
	check(visible==4,"Role selector compares the same class across all biomes")
	lab.biome_picker.select(3)
	lab.refresh_view()
	visible = 0
	for bed in lab.beds:
		if bed.node.visible:
			visible += 1
			check(bed.labels.visible,"Single specimen shows organ annotations")
	check(visible==1,"Biome and role selectors isolate one sample")
	var toggle: CheckButton = workstation.find_child("Cutaway",true,false)
	toggle.button_pressed = true
	for bed in lab.beds:
		check(not bed.node.find_child("OuterGrowth",true,false).visible,"Cutaway exposes internal anatomy")
	workstation.overrides["branch_count"] = 12
	workstation.overrides["cutaway"] = true
	workstation.load_fixture()
	check(workstation.fixture.branch_count==12 and workstation.fixture.cutaway,"Sidebar tuning rebuilds anatomy fixture")
	check(workstation.fixture.biome_picker.selected==3 and workstation.fixture.role_picker.selected==4,"Rebuild preserves selected biome and specialist")
	check(workstation.report().readings.specimens.size()==24,"Report retains all anatomical graphs")
	workstation.overrides["silhouette_view"] = true
	workstation.overrides["height_ratio"] = 1.7
	workstation.load_fixture()
	check(workstation.fixture.beds[0].node.find_child("OuterGrowth",true,false).material_override!=null,"Silhouette comparison uses an explicit black material")
	var reset: Button = workstation.find_child("ResetShapeControls",true,false)
	reset.pressed.emit()
	await process_frame
	await process_frame
	check(workstation.fixture.height_ratio==1.0 and workstation.fixture.branch_count==8,"Shape reset restores generated defaults")
	workstation.free()
	await process_frame
	print("BIOME PLANT ANATOMY: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
