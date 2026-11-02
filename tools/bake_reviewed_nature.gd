extends SceneTree
## Bake the supplied scenes' surface overrides into static meshes for NatureArt.
## Does not execute third-party scripts or change terrain/collision ownership.
var groups: Dictionary
var rocks := false

func _initialize() -> void:
	run.call_deferred()

func collect(node: Node, parent_transform: Transform3D) -> void:
	var transform := parent_transform
	if node is Node3D: transform *= node.transform
	if node is MeshInstance3D and node.mesh != null:
		for surface in range(node.mesh.get_surface_count()):
			var source: Material = node.get_active_material(surface)
			if not groups.has(source):
				var material := source.duplicate() as StandardMaterial3D
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				if rocks:
					material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					material.normal_scale = 0.25
					material.roughness = 1.0
				elif material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					material.alpha_scissor_threshold = 0.4
				var builder := SurfaceTool.new()
				builder.begin(Mesh.PRIMITIVE_TRIANGLES)
				builder.set_material(material)
				groups[source] = builder
			groups[source].append_from(node.mesh, surface, transform)
	for child in node.get_children(): collect(child, transform)

func run() -> void:
	var count := 0
	for group: String in ["foliage", "rocks"]:
		rocks = group == "rocks"
		var destination := "res://assets/nature_samples/" + group + "/Scenes"
		DirAccess.make_dir_recursive_absolute(destination)
		for filename in DirAccess.get_files_at("res://artifacts/visual_install/" + group):
			if not filename.ends_with(".tscn"): continue
			groups = {}
			var original: Node = load("res://artifacts/visual_install/" + group + "/" + filename).instantiate()
			collect(original, Transform3D.IDENTITY)
			var model := Node3D.new()
			model.name = filename.get_basename().to_pascal_case()
			for material in groups:
				var part := MeshInstance3D.new()
				part.mesh = groups[material].commit()
				model.add_child(part)
				part.owner = model
			var scene := PackedScene.new()
			assert(scene.pack(model) == OK)
			assert(ResourceSaver.save(scene, destination + "/" + filename) == OK)
			print(filename, " ", preload("res://scripts/scenery/nature_art.gd").parts(scene).bounds)
			model.free()
			original.free()
			count += 1
	print("REVIEWED NATURE: ", count, " static scenes baked with material overrides preserved")
	quit()
