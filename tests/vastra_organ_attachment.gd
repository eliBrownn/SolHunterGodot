extends SceneTree

func _initialize() -> void:
	var renderer = preload("res://scripts/presentation/vastra_currents.gd").new()
	var definition = preload("res://scripts/scenery/plant_definition.gd").new()
	definition.organ_anchors = {"ground":Vector3.ZERO,"receive":Vector3(1,2,0),"release":Vector3(-1,3,0),"crown":Vector3(0,4,0)}
	definition.organ_graph.assign([
		{"id":"ground","position":Vector3.ZERO,"parent":""},
		{"id":"collar","position":Vector3(0,0.5,0),"parent":"ground"},
		{"id":"reserve","position":Vector3(0,1,0),"parent":"collar"},
		{"id":"intake","position":Vector3(1,2,0),"parent":"reserve"},
		{"id":"outlet","position":Vector3(-1,3,0),"parent":"reserve"}])
	var transform := Transform3D(Basis(Vector3.UP,0.7).scaled(Vector3(2,3,2)),Vector3(20,5,-8))
	var organs: Dictionary = AuthoredPlantLibrary.world_organs(definition,transform)
	var asset := {"organs":organs}
	for endpoint in ["receive","release","ground"]:
		var route: PackedVector3Array = renderer.organ_route(asset,endpoint)
		assert(route[0].is_equal_approx(transform*Vector3(0,1,0)))
		assert(route[-1].is_equal_approx(transform*definition.organ_anchors[endpoint]))
		if endpoint=="ground": assert(route.size()==3 and route[1].is_equal_approx(transform*Vector3(0,0.5,0)))
	assert(renderer.organ_route({},"release").is_empty())
	var builder = preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").new()
	for biome in range(4):
		var sample: Dictionary = builder.create_sample(biome, 1, 73, {"tree_leaf_cards":true}, builder.make_anatomy_materials())
		assert(not sample.leaf_surfaces.is_empty())
		var tree_organs := {}
		for organ: Dictionary in sample.organs + sample.leaf_surfaces:
			tree_organs[organ.id] = {"position":transform * organ.position,"parent":organ.parent}
		var tree := {"organs":tree_organs,"kind":"tree"}
		for organ: Dictionary in sample.leaf_surfaces:
			if organ.kind != "Leaf release": continue
			var endpoint: String = renderer.directional_surface(tree,"release",transform * organ.position)
			assert(endpoint == organ.id)
			var route: PackedVector3Array = renderer.organ_route(tree,endpoint)
			assert(route[0].is_equal_approx(tree_organs.reserve.position))
			assert(route[-1].is_equal_approx(tree_organs[endpoint].position))
		for organ: Dictionary in sample.organs:
			if not str(organ.id).begins_with("root"): continue
			var endpoint: String = renderer.directional_surface(tree,"ground",transform * organ.position)
			assert(endpoint == organ.id)
			var route: PackedVector3Array = renderer.organ_route(tree,endpoint)
			assert(route[-1].is_equal_approx(transform * organ.position))
	for node in [renderer.batch,renderer.wisp_batch,renderer.particle_batch,renderer.previous_batch,renderer.previous_wisps,renderer.heatmap_batch]: node.free()
	renderer.free()
	print("VASTRA ORGAN ATTACHMENT: transformed intake, outlet, storage and root routes passed")
	quit()
