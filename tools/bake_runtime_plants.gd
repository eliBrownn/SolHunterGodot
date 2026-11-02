extends SceneTree
## Rebuild derived live art after changing the shared plant builders.
const Library = preload("res://scripts/scenery/plant_library.gd")
const Art = preload("res://scripts/scenery/nature_art.gd")
const Picking = preload("res://scripts/presentation/mesh_picking.gd")
var count := 0
var failed := false
var surfaces_removed := 0

func _initialize() -> void:
	run.call_deferred()

func bake(item: Resource) -> void:
	if not item.valid():
		push_error("Invalid palette definition: " + item.plant_id)
		failed = true
		return
	var model := Art.compact_parts(item.scene)
	var root := Node3D.new()
	# The builder's three neutral tissue materials differ only in albedo.
	# Carry that constant color in vertices and merge their geometry, preserving
	# the same normals, UVs, normal map and opaque/culling treatment.
	var tissue_builder := SurfaceTool.new()
	tissue_builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tissue_material: StandardMaterial3D
	var tissue_count := 0
	for piece: Dictionary in model.pieces:
		var material: Material = piece.mesh.surface_get_material(0)
		if material is StandardMaterial3D:
			if tissue_material == null:
				tissue_material = material.duplicate()
				tissue_material.albedo_color = Color.WHITE
				tissue_material.vertex_color_use_as_albedo = true
				tissue_material.vertex_color_is_srgb = true
				tissue_builder.set_material(tissue_material)
			var arrays: Array = piece.mesh.surface_get_arrays(0)
			var colors := PackedColorArray()
			colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
			colors.fill(material.albedo_color)
			arrays[Mesh.ARRAY_COLOR] = colors
			var colored := ArrayMesh.new()
			colored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			tissue_builder.append_from(colored, 0, piece.transform)
			tissue_count += 1
			continue
		var view := MeshInstance3D.new()
		view.mesh = piece.mesh
		view.transform = piece.transform
		root.add_child(view)
		view.owner = root
	if tissue_count > 0:
		var combined: ArrayMesh = tissue_builder.commit()
		var importer := ImporterMesh.new()
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, combined.surface_get_arrays(0), [], {}, tissue_material)
		importer.generate_lods(60.0, 25.0, [])
		var view := MeshInstance3D.new()
		view.mesh = importer.get_mesh()
		root.add_child(view)
		view.owner = root
		surfaces_removed += tissue_count - 1
	for view: MeshInstance3D in root.get_children():
		Picking.prepare(view.mesh)
		var bins: Array = []
		for row: Dictionary in Picking.surfaces[view.mesh.get_instance_id()]: bins.append(row.bins)
		view.mesh.set_meta("picking_bins_v1", bins)
	var scene := PackedScene.new()
	scene.pack(root)
	root.free()
	item.scene = scene
	item.set_meta("runtime_palette", true)
	var error := ResourceSaver.save(item, Library.PALETTE_DIRECTORY + "/" + item.plant_id + ".res", ResourceSaver.FLAG_COMPRESS)
	if error != OK:
		push_error("Palette save failed: " + item.plant_id)
		failed = true
	count += 1

func run() -> void:
	var source_fingerprint := Library.palette_fingerprint()
	Library.use_baked_palette = false
	Library.refresh()
	DirAccess.make_dir_recursive_absolute(Library.PALETTE_DIRECTORY)
	for entry: Dictionary in Library.Species.all():
		if entry.live_ecology_eligible: bake(Library.official_definition(entry.design_id))
	for biome in range(4):
		for variant in range(9):
			bake(Library.procedural_definition(biome, {"role":"reservoir", "class":""}, variant))
		for variant in range(3):
			for specialist in FloraTraits.CLASSES:
				bake(Library.procedural_definition(biome, {"role":"receiver", "class":specialist}, variant))
		for variation in range(5):
			bake(Library.foliage_definition(biome, variation, "emanator"))
			bake(Library.foliage_definition(biome, variation, "emanator",true))
	if source_fingerprint != Library.palette_fingerprint():
		push_error("Plant inputs changed during baking; rerun against settled sources")
		failed = true
	if not failed:
		var manifest := FileAccess.open(Library.PALETTE_DIRECTORY + "/manifest.json", FileAccess.WRITE)
		manifest.store_string(JSON.stringify({"version":1,"fingerprint":Library.palette_fingerprint(),"count":count}, "\t"))
		manifest.close()
	print("RUNTIME PLANT BAKE: %d definitions, %d material surfaces removed, failed=%s" % [count, surfaces_removed, failed])
	quit(1 if failed else 0)
