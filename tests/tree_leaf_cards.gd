extends SceneTree
const Builder=preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd")
const Lab=preload("res://tools/plant_biome_role_lab.gd")
var failures:=0
var checks:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(message)
func triangles(sample: Dictionary) -> int:
	var total:=0
	for mesh: ArrayMesh in [sample.body,sample.anatomy]:
		for surface in range(mesh.get_surface_count()): total+=mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
	return total
func _initialize() -> void:
	var builder:=Builder.new()
	for biome in range(4):
		var settings: Dictionary={"tree_leaf_cards":false,"branches":6,"foliage":1.25,"node_count":5,"tree_fork_depth":2,"branching_depth":1,"foliage_fullness":1.5}
		var mesh: Dictionary=builder.create_sample(biome,1,73,settings,builder.make_anatomy_materials())
		settings["tree_leaf_cards"]=true
		var cards: Dictionary=builder.create_sample(biome,1,73,settings,builder.make_anatomy_materials())
		check(hash(mesh.organs)==hash(cards.organs) and hash(mesh.links)==hash(cards.links),"Leaf rendering preserves the connected organ graph")
		check(triangles(cards)<triangles(mesh)*0.85,"Cards materially reduce canopy geometry")
		check(triangles(cards)<=30000,"Dense card canopy fits the runtime model budget")
		var card_surface:=false
		for surface in range(cards.body.get_surface_count()):
			var material: Material=cards.body.surface_get_material(surface)
			if material is ShaderMaterial and material.shader.resource_path.ends_with("tree_leaf_cards.gdshader"):
				card_surface=true
				var arrays: Array=cards.body.surface_get_arrays(surface)
				for color: Color in arrays[Mesh.ARRAY_COLOR]:
					if floori(color.a*4.0)!=biome: check(false,"Habitat atlas selection stays per card")
		check(card_surface,"Card geometry belongs to outer growth")
		var instance:=MeshInstance3D.new()
		instance.mesh=cards.body
		var ink:=StandardMaterial3D.new()
		Lab.apply_silhouette_material(instance,ink)
		check(instance.material_override==null,"Card silhouettes retain per-surface cutout materials")
		var silhouette_card:=false
		for surface in range(instance.mesh.get_surface_count()):
			var material: Material=instance.get_surface_override_material(surface)
			if material is ShaderMaterial: silhouette_card=bool(material.get_shader_parameter("silhouette_view"))
		check(silhouette_card,"Card silhouette keeps the alpha-cutout shader")
		Lab.apply_silhouette_material(instance,null)
		check(instance.get_surface_override_material(0)==null,"Normal review restores original surfaces")
		instance.free()
		var reached: Dictionary={"ground":true}
		for link: Dictionary in cards.links:
			check(reached.has(link.from),"Each conductor has a rooted parent")
			reached[link.to]=true
		check(reached.size()==cards.organs.size(),"All organs remain connected to ground")
		for surface in range(cards.anatomy.get_surface_count()):
			var material: Material=cards.anatomy.surface_get_material(surface)
			check(not material is ShaderMaterial or not material.shader.resource_path.ends_with("tree_leaf_cards.gdshader"),"Leaf cards are absent from anatomy cutaway")
		var attachments:=[]
		for organ: Dictionary in cards.organs: attachments.append(organ.position)
		for link: Dictionary in cards.links: attachments.append(link.path[1])
		var ends: Dictionary={}
		for shoot: Dictionary in cards.foliage_branches:
			if shoot.depth==1: check(attachments.has(shoot.from) or ends.has(shoot.from),"Canopy shoots start on a real conductor attachment")
			ends[shoot.to]=true
		var branches:=0
		for organ: Dictionary in cards.organs:
			if organ.kind=="Branch fork": branches+=1
		check(branches>=30,"Dense trees retain many connected offshoots")
		print("Biome %d: mesh %d triangles, cards %d triangles; %d offshoots"%[biome,triangles(mesh),triangles(cards),branches])
	print("TREE LEAF CARDS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
