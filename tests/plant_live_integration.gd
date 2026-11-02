extends SceneTree
const Library = preload("res://scripts/scenery/plant_library.gd")
const Currents = preload("res://scripts/presentation/vastra_currents.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
var checks := 0
var failures := 0

class FlatTerrain extends WorldTerrain:
	var biome := 0
	var kind := "tree"
	func sample(_cell: Vector2i) -> Dictionary: return {"ground":biome,"obstacle":0,"walkable":true,"wetness":0.65,"trail_visible":false}
	func flora_kind(_cell: Vector2i,_data: Dictionary) -> String: return kind
	func scenery_reserved(_cell: Vector2i) -> bool: return false
	func route_axes(_cell: Vector2i,_margin: int=0) -> int: return 0
	func is_camp(_cell: Vector2i) -> bool: return false
	func is_landmark(_cell: Vector2i) -> bool: return false
	func surface_height(_point: Vector2) -> float: return 0.0
	func surface_normal(_point: Vector2) -> Vector3: return Vector3.UP
	func lake_distance(_cell: Vector2i) -> float: return 2.0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void: run.call_deferred()

func run() -> void:
	Library.refresh(["res://artifacts/no-live-test-library.json"])
	var renderer = Currents.new()
	var anatomy := {"organs":{"reserve":{"position":Vector3(0,1,0),"parent":""},"left":{"position":Vector3(-2,1,0),"parent":"reserve"},"right":{"position":Vector3(2,1,0),"parent":"reserve"},"root0":{"position":Vector3(0,-1,0),"parent":"reserve"}},"kind":"tree"}
	for mode in ["receive","release"]:
		check(renderer.directional_surface(anatomy,mode,Vector3(-3,1,0))=="left","Left-side interaction uses its nearest organ")
		check(renderer.directional_surface(anatomy,mode,Vector3(3,1,0))=="right","Right-side interaction uses its nearest organ")
	check(renderer.directional_surface(anatomy,"ground",Vector3(3,1,0))=="root0","Soil flows retain their root channel")
	var terrain := FlatTerrain.new(18)
	var admitted := 0
	for entry: Dictionary in Library.Species.all():
		var item: Resource = Library.official_definition(entry.design_id)
		if not entry.live_ecology_eligible:
			check(item == null,"Unassigned receiver stays out of the expedition")
			continue
		admitted += 1
		check(item != null and item.valid() and item.enabled_in_world,"Valid live definition: " + entry.design_id)
		if item == null: continue
		check(item.resource_path.begins_with(Library.PALETTE_DIRECTORY),"Live official art comes from the current prebuilt palette")
		var parts := Library.model(item)
		check(parts.supported and parts.triangles <= 30000 and parts.surfaces <= 12,"Live rendering budget: " + entry.design_id)
		check(item.species_id == entry.species_id and Library.Species.valid_recipe(item.recipe,entry.design_id),"Approved identity and recipe survive integration")
		terrain.biome = item.biome
		terrain.kind = "tree" if item.circulation_role == "reservoir" else "plant"
		var cell := Vector2i(60,60)
		var row := Library.fit_definition(terrain,cell,terrain.kind,item,false,0.0)
		check(not row.is_empty(),"Placeable in an unobstructed matching slot: " + entry.design_id)
		if row.is_empty(): continue
		var chunk := Chunk.new()
		chunk.add_composed_nature(row)
		var source: Dictionary = chunk.living_sources.get(cell,{})
		check(source.get("flora_id") == FloraCatalog.id_for(cell),"Live chunks retain canonical Vastra identity")
		check(source.get("organs",{}) == row.vastra_organs,"Live chunks carry exact transformed organs")
		if terrain.kind == "tree":
			for piece: Dictionary in parts.pieces:
				for surface in range(piece.mesh.get_surface_count()):
					check(piece.mesh.surface_get_material(surface) is ShaderMaterial,"Live tree scenes exclude diagnostic interior tissue")
			var endpoint: String = renderer.directional_surface(source,"release",Vector3(80,8,60))
			check(source.organs.has(endpoint),"Integrated tree uses a real nearby organ: " + entry.design_id)
			var route: PackedVector3Array = renderer.organ_route(source,endpoint)
			check(not route.is_empty() and route[-1].is_equal_approx(source.organs[endpoint].position),"Organ path ends on the selected anatomy")
			check(renderer.directional_surface(source,"ground",Vector3(80,0,60)).begins_with("root"),"Root flow uses an outward root")
		chunk.free()
	check(admitted == 41,"All 41 ecologically assigned official plants are admitted")
	# Owner screenshot: seed 2601026, beside (82,-14). The canonical regulator
	# survived clearance rejection while its broad model disappeared entirely.
	var production := WorldTerrain.new(2601026,load("res://resources/climate_settings.tres").parameters(),load("res://resources/terrain_exploration.tres").parameters(),load("res://resources/scenery/exploration_shelter.tres").parameters(),load("res://resources/plant_community_settings.tres").parameters())
	for cell: Vector2i in [Vector2i(81,-14),Vector2i(89,-9)]:
		var row := Library.placement(production,cell,production.sample(cell),"plant",true)
		check(not row.is_empty(),"Crowded regulator retains a visible body: %s" % cell)
		if row.is_empty(): continue
		check(row.bounds.position.x>=cell.x and row.bounds.end.x<=cell.x+1 and row.bounds.position.z>=cell.y and row.bounds.end.z<=cell.y+1,"Compact regulator remains inside its canonical cell")
		var chunk := Chunk.new()
		chunk.add_composed_nature(row)
		check(not chunk.batches.is_empty() and not chunk.pick_objects.is_empty(),"Compact regulator has both visible geometry and matching picking")
		check(chunk.living_sources[cell].organs==row.vastra_organs,"Compact regulator keeps its transformed Vastra anatomy")
		chunk.free()
	for biome in range(4):
		terrain.biome = biome
		terrain.kind = "tree"
		var cell := Vector2i(60,60)
		var row := Library.placement(terrain,cell,terrain.sample(cell),"tree",true)
		check(not row.is_empty() and (str(row.asset).contains("official_") or str(row.asset).contains("procedural_")),"Normal generation selects a current palette tree in biome %d" % biome)
	terrain.kind="plant"
	terrain.biome=0
	var cover_cell := Vector2i(60,60)
	while FloraTraits.role(terrain.world_seed,{"id":FloraCatalog.id_for(cover_cell),"cell":[cover_cell.x,cover_cell.y],"kind":"plant"})!="emanator" or not Library.placement(terrain,cover_cell,terrain.sample(cover_cell),"plant",true,0.0,1.0).is_empty(): cover_cell.x+=1
	var cover_chunk := Chunk.new()
	var style := NatureSettings.new()
	style.foliage_coverage=1.0
	style.meadow_enabled=true
	var cover_body := Library.add_cell(cover_chunk,terrain,cover_cell,terrain.sample(cover_cell),style)
	check(not cover_body.is_empty(),"Former grass cells receive foliage models")
	for key: String in cover_chunk.batches: check(not key.begins_with("nature_detail_meadow"),"Live ground cover contains no grass blade batches")
	check(cover_chunk.living_sources.size()==1 and cover_chunk.living_sources[cover_cell].flora_id==FloraCatalog.id_for(cover_cell),"Foliage ground cover retains one canonical plant owner")
	check(cover_body.get("grass_clumps",0)>=10 and cover_body.get("grass_clumps",0)<=40,"Each grass tile contains 10–40 clumps")
	check(cover_chunk.cosmetic_records.size()==cover_body.get("grass_clumps",0),"Grass tile emits exactly its selected clump count")
	var grass_variants := {}
	var grass_points: Array[Vector2]=[]
	for clump: Dictionary in cover_chunk.cosmetic_records:
		grass_variants[clump.asset]=true
		var point := Vector2(clump.transform.origin.x,clump.transform.origin.z)
		check(Rect2(Vector2(cover_cell),Vector2.ONE).has_point(point),"Grass clump stays inside its canonical tile")
		for previous: Vector2 in grass_points: check(point.distance_to(previous)>0.06,"Random grass spacing leaves room between clump roots")
		grass_points.append(point)
	check(grass_variants.size()>1,"Grass tiles mix leaf variants")
	var repeated := Chunk.new()
	Library.add_cell(repeated,terrain,cover_cell,terrain.sample(cover_cell),style)
	check(hash(repeated.cosmetic_records)==hash(cover_chunk.cosmetic_records),"Grass spacing and variation reconstruct from the tile seed")
	check(cover_chunk.living_sources[cover_cell].organs==cover_body.vastra_organs,"Grass clumps share one connected organ graph and reserve owner")
	cover_chunk.prepare_picking()
	check(cover_chunk.traversal_bounds.is_empty() and not cover_chunk.batches.is_empty(),"Visible leaf grass preserves the original passable ground-cover contract")
	check(cover_chunk.cosmetic_records.all(func(row: Dictionary) -> bool: return not row.has("vastra_organs")),"Placement history does not duplicate the canonical cell's organ graph")
	# Ground cover coexists with a full tree without replacing its endpoints.
	terrain.kind = "tree"
	var tree_chunk := Chunk.new()
	var tree_body := Library.add_cell(tree_chunk,terrain,cover_cell,terrain.sample(cover_cell),style)
	check(not tree_body.is_empty(),"Coexistence fixture admits a real tree")
	if not tree_body.is_empty():
		var undergrowth: Array = tree_chunk.cosmetic_records.filter(func(row: Dictionary) -> bool: return row.get("ground_cover",false))
		check(not undergrowth.is_empty(),"Grass grows beneath the canopy in the tree's own cell")
		check(tree_chunk.living_sources.size() == 1 and tree_chunk.living_sources[cover_cell].kind == "tree", "Coexisting grass retains one canonical tree owner")
		check(tree_chunk.living_sources[cover_cell].organs == tree_body.vastra_organs and tree_chunk.living_sources[cover_cell].anchor == tree_body.vastra_anchor,"Ground cover preserves tree anatomy and intake")
		var solids := Library.grass_solid_segments(tree_body,style)
		for clump: Dictionary in undergrowth:
			var point := Vector2(clump.transform.origin.x,clump.transform.origin.z)
			check(Library.grass_point_clear(point,0.0,solids),"Grass avoids the solid base and exposed root segments")
			check(float(clump.grass_height) >= style.grass_short_height.x and float(clump.grass_height) <= style.grass_tall_height.y,"Actual grass heights stay within configured short-to-tall ranges")
		var sparse := Chunk.new()
		var sparse_style: NatureSettings = style.duplicate()
		sparse_style.foliage_coverage = 0.2
		var sparse_body := Library.add_cell(sparse,terrain,cover_cell,terrain.sample(cover_cell),sparse_style)
		check(sparse_body.transform == tree_body.transform and sparse.living_sources[cover_cell] == tree_chunk.living_sources[cover_cell],"Changing visible grass density cannot change tree identity or its circulation graph")
		sparse.free()
	var boundary_a: Vector2 = Library.grass_height_range(Library.grass_patch(terrain,Vector2(15.999,8.0),style),style)
	var boundary_b: Vector2 = Library.grass_height_range(Library.grass_patch(terrain,Vector2(16.001,8.0),style),style)
	check(boundary_a.distance_to(boundary_b) < 0.001,"Grass stature varies continuously across a render-chunk boundary")
	var bad_grass: NatureSettings = style.duplicate()
	bad_grass.grass_medium_height = Vector2(0.4,0.1)
	check(not bad_grass.valid(),"Inverted grass height ranges are rejected")
	var leaf_source: ShaderMaterial = Library.model(Library.foliage_definition(0,0,"emanator",true)).pieces[0].mesh.surface_get_material(0)
	var fade_material: ShaderMaterial = Library.grass_material(leaf_source)
	check(fade_material != leaf_source and fade_material == Library.grass_material(leaf_source),"Grass fade materials are isolated from ordinary foliage and shared by source")
	Library.set_weather(Vector2.RIGHT,17.0,0.6,Vector2(32,-16))
	check(fade_material.get_shader_parameter("wind_time") == 17.0 and fade_material.get_shader_parameter("world_origin") == Vector2(32,-16),"Shared grass fade materials still consume weather time and floating-origin updates")
	tree_chunk.free()
	repeated.free()
	cover_chunk.free()
	for child in [renderer.batch,renderer.wisp_batch,renderer.particle_batch,renderer.previous_batch,renderer.previous_wisps,renderer.heatmap_batch]: child.free()
	renderer.free()
	print("LIVE PLANT INTEGRATION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
