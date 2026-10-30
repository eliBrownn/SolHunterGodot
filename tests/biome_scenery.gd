extends SceneTree
## Generated-habitat scenery admission and reconstruction, independent of saved ecology.
const Settings = preload("res://resources/nature_biomes.tres")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
const Art = preload("res://scripts/scenery/nature_art.gd")
const StreamingGround = preload("res://scripts/presentation/streaming_ground.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(120).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	check(Settings.valid(), "Normal biome resources pass admission")
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.6, 0.2, 1.0))
	var cutout := StandardMaterial3D.new()
	cutout.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	cutout.albedo_texture = ImageTexture.create_from_image(image)
	var adapted: BaseMaterial3D = Art.foliage_material(cutout)
	check(adapted != cutout and not cutout.albedo_texture.get_image().has_mipmaps(), "Foliage adaptation preserves source material and texture")
	check(adapted.albedo_texture.get_image().has_mipmaps(), "Foliage has filtered mip levels for distant cutouts")
	check(Art.foliage_material(cutout) == adapted, "Shared foliage materials reuse the same adaptation")
	var opaque := StandardMaterial3D.new()
	check(Art.foliage_material(opaque) == opaque, "Opaque bark and rocks retain their authored material")
	for biome in Settings.biomes:
		check(biome.trees.is_empty(), "Imported tree palettes remain retired")
		var source := Art.compact_parts(Settings.rocks[0])
		var original_material: Material = source.pieces[0].mesh.surface_get_material(0)
		var original_color: Color = original_material.albedo_color
		var colored := Art.tint_parts(source, biome.tree_tint)
		check(original_material.albedo_color == original_color, "Biome recoloring preserves the imported source material")
		check(colored.pieces[0].mesh != source.pieces[0].mesh and colored.pieces[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == source.pieces[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "Material variants retain exact source geometry for picking and clearance")
		var tree=preload("res://scripts/scenery/plant_library.gd").procedural_definition(biome.ground,{"role":"reservoir","class":""},0)
		check(Art.parts(tree.scene).supported, "Procedural biome tree supports rendering and picking")
		for entry in biome.details:
			check(not entry.admitted_model().is_empty(), "Authored biome plant fits its actual geometry contract: " + entry.scene.resource_path)
	var blade_biomes := {}
	var seen := {}
	var flora_habitats := {}
	var canonical_coverage := true
	var shared_tile_checked := false
	var specialist_count := 0
	var distant_specialists := false
	for seed_value in [2601026, 7, 19]:
		var terrain := WorldTerrain.new(seed_value)
		var selected := {}
		for y in range(-64, 97, 8):
			for x in range(-64, 129, 8):
				var cell := Vector2i(x, y)
				var habitat := terrain.natural_ground(cell)
				if Settings.biome_for(habitat) != null and not selected.has(habitat):
					selected[habitat] = terrain.chunk_of(cell)
		for habitat in selected:
			var coord: Vector2i = selected[habitat]
			var cells := terrain.extract_chunk(coord)
			for index in range(cells.size()):
				var cell: Vector2i = coord * 16 + Vector2i(index % 16, index / 16)
				var kind := terrain.flora_kind(cell, cells[index])
				if not kind.is_empty():
					if not flora_habitats.has(cells[index].ground): flora_habitats[cells[index].ground] = {"terrain": terrain, "cell": cell}
					canonical_coverage = canonical_coverage and (cells[index].ground not in [WorldTerrain.Ground.WATER, WorldTerrain.Ground.SAND] or terrain.authored_wetland_flora(cell) == kind)
			var chunk := Chunk.new()
			chunk.build(cells, terrain, coord, Settings)
			for view in chunk.get_children():
				if view is MultiMeshInstance3D and view.name.begins_with("nature_detail_meadow_") and view.multimesh.instance_count > 0:
					var ground := int(str(view.name).split("_")[3])
					blade_biomes[ground] = true
					check(view.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 21,"Live grass batches contain individual seven-triangle blades")
			for pick in chunk.pick_objects:
				check(not str(pick.get("subject", "")).contains("Grass_"),"Old authored grass is absent from active picked scenery")
			for index in range(cells.size()):
				var plant_cell := coord * 16 + Vector2i(index % 16, index / 16)
				if terrain.flora_kind(plant_cell, cells[index]) == "plant":
					check(chunk.living_sources.has(plant_cell), "Canonical plants retain Vastra endpoints even without cosmetic biome dressing")
			var records: Array = chunk.cosmetic_records.duplicate(true)
			for record in records:
				check(not record.get("living", true) or record.patch == "authored_plant", "Live plant records exclusively use the new library")
				check(record.asset not in preload("res://scripts/scenery/meadow_art.gd").SUPERSEDED_GRASS,"Superseded grass clumps cannot reach rendered scenery")
			for source_cell: Vector2i in chunk.living_sources:
				var endpoint: Dictionary = chunk.living_sources[source_cell]
				check(endpoint.flora_id == FloraCatalog.id_for(source_cell) and not terrain.flora_kind(source_cell, terrain.sample(source_cell)).is_empty(), "Every visible living endpoint references its canonical Vastra cell")
			for record: Dictionary in records:
				if record.get("living", false):
					check(chunk.living_sources.has(record.cell), "Every generated living plant has a Vastra presentation endpoint")
			for record: Dictionary in records:
				if record.patch == "authored_plant" and record.get("category", "detail") == "detail":
					specialist_count += 1
					if not shared_tile_checked:
						var sharing := Chunk.new()
						sharing.cell_origin = coord*16
						preload("res://scripts/scenery/meadow_art.gd").add_cell(sharing,terrain,record.cell,terrain.sample(record.cell),Settings)
						if not sharing.batches.is_empty():
							check(sharing.living_sources[record.cell].priority == -1,"Shared tile starts with a ground-cover endpoint")
							sharing.add_composed_nature(preload("res://scripts/scenery/plant_library.gd").placement(terrain,record.cell,terrain.sample(record.cell),"plant",true))
							check(sharing.living_sources.size() == 1 and sharing.living_sources[record.cell].flora_id == FloraCatalog.id_for(record.cell),"Grass and plant share exactly one canonical cell reserve")
							check(sharing.living_sources[record.cell].priority == 0,"The functional plant keeps endpoint ownership above grass")
							shared_tile_checked = true
						sharing.free()
					distant_specialists = distant_specialists or Vector2(record.cell).length_squared() > 144.0
			var incremental := Chunk.new()
			for first in range(0,256,16):
				incremental.build_cells(cells,terrain,coord,Settings,first,16)
			incremental.finish()
			check(records == incremental.cosmetic_records, "Streaming publication batches cannot change regional/grove child placements")
			incremental.free()
			var baseline := Chunk.new()
			baseline.build(cells, terrain, coord)
			check(chunk.obstacle_count == baseline.obstacle_count, "Biome art preserves generated blocker count")
			check(cells == terrain.extract_chunk(coord), "Scenery never changes habitat, routes or walkability")
			var coarse := StreamingGround.build(terrain, coord, 4, Settings)
			var legacy_coarse := StreamingGround.build(terrain, coord, 4)
			var coarse_arrays := coarse.surface_get_arrays(0)
			var legacy_arrays := legacy_coarse.surface_get_arrays(0)
			check(coarse_arrays[Mesh.ARRAY_VERTEX] == legacy_arrays[Mesh.ARRAY_VERTEX] and coarse_arrays[Mesh.ARRAY_INDEX] == legacy_arrays[Mesh.ARRAY_INDEX], "Biome tint preserves temporary ground geometry and water/trail layout")
			var vertex_colors := {}
			var seamless := true
			for child in chunk.get_children():
				if not child is MeshInstance3D or not str(child.name).begins_with("grass_"):
					continue
				var arrays: Array = child.mesh.surface_get_arrays(0)
				for index in range(arrays[Mesh.ARRAY_VERTEX].size()):
					var vertex: Vector3 = arrays[Mesh.ARRAY_VERTEX][index]
					var at := coord * 16 + Vector2i(roundi(vertex.x), roundi(vertex.z))
					var color: Color = arrays[Mesh.ARRAY_COLOR][index]
					if vertex_colors.has(at) and not vertex_colors[at].is_equal_approx(color):
						seamless = false
					vertex_colors[at] = color
			check(seamless, "Adjacent detailed tiles share identical boundary colors")
			var matched := 0
			var coarse_matches := true
			for index in range(coarse_arrays[Mesh.ARRAY_VERTEX].size()):
				var vertex: Vector3 = coarse_arrays[Mesh.ARRAY_VERTEX][index]
				var at := coord * 16 + Vector2i(roundi(vertex.x), roundi(vertex.z))
				if coarse_arrays[Mesh.ARRAY_TEX_UV][index].x != 0 or not vertex_colors.has(at) or absf(vertex.y - terrain.vertex_height(at)) > 0.001:
					continue
				matched += 1
				if not vertex_colors[at].is_equal_approx(coarse_arrays[Mesh.ARRAY_COLOR][index]):
					coarse_matches = false
			check(matched > 0 and coarse_matches, "Temporary and detailed terrain agree at shared dry ground vertices")
			baseline.free()
			chunk.free()
			var restored := Chunk.new()
			restored.build(terrain.extract_chunk(coord), terrain, coord, Settings)
			check(records == restored.cosmetic_records, "Evicted biome dressing reconstructs identical absolute placements")
			for record in records:
				if record.patch == "authored_plant":
					seen[["meadow", "woodland", "heath", "marsh"][terrain.sample(record.cell).ground]] = true
				check(not terrain.scenery_reserved(record.cell) and terrain.route_axes(record.cell, 1) == 0, "Cosmetic plants respect site and route access")
			restored.free()
	for name in ["meadow", "woodland", "heath", "marsh"]:
		check(seen.has(name), "Actual generated " + name + " publishes admitted plants")
	for habitat in [WorldTerrain.Ground.MEADOW, WorldTerrain.Ground.FOREST, WorldTerrain.Ground.HEATH, WorldTerrain.Ground.MARSH]:
		check(flora_habitats.has(habitat), "Every generated land biome admits canonical Vastra flora")
		check(blade_biomes.has(habitat), "Every land biome publishes procedural single blades")
		if not flora_habitats.has(habitat): continue
		var fixture: Dictionary = flora_habitats[habitat]
		var catalogue := FloraCatalog.new(fixture.terrain)
		catalogue.request(fixture.cell, 0, 0.0)
		for step in range(256):
			catalogue.advance(Time.get_ticks_usec() + 10000)
			if catalogue.pending.is_empty(): break
		check(catalogue.active_ids().has(FloraCatalog.id_for(fixture.cell)), "Each land biome reaches the active flora catalogue used by Vastra")
	check(canonical_coverage, "Water and sand admit only fixed authored wetland plants, never blanket terrestrial reserves")
	check(shared_tile_checked,"Generated specialist plants and grass share a tile without duplicate Vastra ownership")
	check(specialist_count > 24 and distant_specialists, "World scenery includes specialist bodies beyond the old nearest-24/12-cell player bubble")
	var rush_chunk := Chunk.new()
	rush_chunk.register_living_source(Vector2i.ZERO, "detail", "rush_cluster", Vector3.ZERO)
	check(rush_chunk.living_sources.has(Vector2i.ZERO), "Marsh rushes register as living Vastra presentation endpoints")
	rush_chunk.free()
	print("BIOME SCENERY: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
