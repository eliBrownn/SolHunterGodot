class_name AuthoredPlantLibrary
extends RefCounted
## Authored designs and bounded procedural art on canonical slots. No ledger writes.
const Definition = preload("res://scripts/scenery/plant_definition.gd")
const Art = preload("res://scripts/scenery/nature_art.gd")
const Groundcover = preload("res://scripts/scenery/meadow_art.gd")
const Distribution = preload("res://scripts/scenery/foliage_distribution.gd")
const Species = preload("res://scripts/scenery/plant_species_catalog.gd")
static var official_entries: Dictionary = {}
static var official_slot_cache: Dictionary = {}
const MAX_INSTANCE_VARIATION := 0.25
const TREE_HEIGHTS := [2.0,7.0,14.0]
const GROUND_HEIGHTS := [0.08,0.5,1.5]
# Include recipe size variation and the largest permitted per-cell variation.
const PROCEDURAL_HEIGHT_BOUND := 14.0*1.25*(1.0+MAX_INSTANCE_VARIATION)*1.5 # Includes below-soil roots.
const PROCEDURAL_WIDTH_BOUND := 20.0*(1.0+MAX_INSTANCE_VARIATION)
static var entries: Array[Resource] = []
static var models: Dictionary = {}
static var grass_materials: Dictionary = {}
static var procedural_entries: Dictionary = {}
static var foliage_entries: Dictionary = {}
static var grass_fields: Dictionary = {}
static var loaded := false
static var revision := 0
static var largest_height := PROCEDURAL_HEIGHT_BOUND
static var largest_width := PROCEDURAL_WIDTH_BOUND
static var largest_foliage_height := 1.5*1.25*(1.0+MAX_INSTANCE_VARIATION)
static var largest_foliage_width := 12.0*(1.0+MAX_INSTANCE_VARIATION)
const REVIEWED_DIRECTORY := "res://resources/plants/reviewed_baselines"
static var reviewed_sources: Dictionary={}
static var reviewed_loaded:=false
const PALETTE_DIRECTORY := "res://resources/plants/runtime_palette"
const PALETTE_INPUTS := ["plant_library.gd", "plant_definition.gd", "procedural_plant_mesh.gd", "plant_vastra_anatomy_mesh.gd", "generic_foliage_mesh.gd", "nature_art.gd"]
static var use_baked_palette := true
static var palette_checked := false
static var palette_current := false
static var sources: Array[String] = ["res://resources/plants/library.json","user://authored_plants/library.json"]

static func refresh(manifests: Array[String] = []) -> void:
	if not manifests.is_empty(): sources = manifests.duplicate()
	entries.clear()
	largest_height=PROCEDURAL_HEIGHT_BOUND
	largest_width=PROCEDURAL_WIDTH_BOUND
	largest_foliage_height=1.5*1.25*(1.0+MAX_INSTANCE_VARIATION)
	largest_foliage_width=12.0*(1.0+MAX_INSTANCE_VARIATION)
	models.clear()
	grass_materials.clear()
	procedural_entries.clear()
	foliage_entries.clear()
	official_entries.clear()
	official_slot_cache.clear()
	palette_checked = false
	reviewed_loaded=false
	reviewed_sources.clear()
	var admitted := {}
	for path in sources:
		if not FileAccess.file_exists(path): continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary or data.get("version")!=1 or not data.get("plants") is Array: continue
		for location in data.plants.slice(0,512):
			if not location is String or not location.begins_with(path.get_base_dir()+"/") or not location.ends_with(".tres") or "/../" in location: continue
			if not ResourceLoader.exists(location): continue
			var item = ResourceLoader.load(location,"",ResourceLoader.CACHE_MODE_IGNORE)
			if item is Definition and item.valid(): admitted[item.plant_id] = item
	var keys := admitted.keys()
	keys.sort()
	for key in keys:
		entries.append(admitted[key])
		if admitted[key].enabled_in_world:
			largest_height=maxf(largest_height,admitted[key].world_height)
			largest_width=maxf(largest_width,admitted[key].world_width)
			if admitted[key].circulation_role != "reservoir":
				largest_foliage_height=maxf(largest_foliage_height,admitted[key].world_height)
				largest_foliage_width=maxf(largest_foliage_width,admitted[key].world_width)
	loaded = true
	revision += 1

static func all() -> Array[Resource]:
	if not loaded: refresh()
	return entries.duplicate()

## Bake tooling records the implementation inputs; stale/missing art is never trusted.
static func palette_fingerprint() -> String:
	var inputs := "palette-v2"
	inputs+=FileAccess.get_sha256(REVIEWED_DIRECTORY+"/library.json")
	for key: String in reviewed_manifest():
		inputs+=FileAccess.get_sha256(reviewed_sources[key].path)
	inputs+=FileAccess.get_sha256("res://shaders/tree_leaf_cards.gdshader")
	inputs+=FileAccess.get_sha256("res://shaders/procedural_plant_foliage.gdshader")
	inputs+=FileAccess.get_sha256("res://shaders/foliage_condition.gdshaderinc")
	for filename in PALETTE_INPUTS:
		inputs += FileAccess.get_sha256("res://scripts/scenery/" + filename)
	inputs += FileAccess.get_sha256("res://tools/bake_runtime_plants.gd")
	inputs += FileAccess.get_sha256(Species.PATH)
	inputs += FileAccess.get_sha256("res://scripts/scenery/plant_species_catalog.gd")
	inputs += FileAccess.get_sha256("res://scripts/presentation/mesh_picking.gd")
	inputs += FileAccess.get_sha256("res://scripts/sols/flora_traits.gd")
	return inputs.sha256_text()

## Explicit owner-reviewed bodies override only their existing ecological slot.
static func reviewed_manifest() -> Dictionary:
	if not reviewed_loaded:
		reviewed_loaded=true
		var path:=REVIEWED_DIRECTORY+"/library.json"
		if FileAccess.file_exists(path):
			var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
			if manifest is Dictionary and manifest.get("version")==1 and manifest.get("definitions") is Dictionary:
				reviewed_sources=manifest.definitions
	return reviewed_sources

static func reviewed_definition(key: String) -> Resource:
	var record: Variant=reviewed_manifest().get(key)
	if not record is Dictionary: return null
	var path: String=record.get("path","")
	if not path.begins_with(REVIEWED_DIRECTORY+"/") or "/../" in path or not path.ends_with(".res") or not ResourceLoader.exists(path): return null
	var item: Resource=load(path)
	return item if item is Definition and item.plant_id==key and item.valid() and item.enabled_in_world else null

static func baked_definition(key: String) -> Resource:
	if not use_baked_palette: return null
	if not palette_checked:
		palette_checked = true
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_DIRECTORY + "/manifest.json")) if FileAccess.file_exists(PALETTE_DIRECTORY + "/manifest.json") else null
		# Exported scripts may be remapped/compiled; the bake is packaged with
		# that build. Development/editor binaries additionally check source hashes.
		palette_current = manifest is Dictionary and manifest.get("version", 0) == 1
		if palette_current and OS.has_feature("editor"):
			palette_current = manifest.get("fingerprint", "") == palette_fingerprint()
	if not palette_current: return null
	var path := PALETTE_DIRECTORY + "/" + key + ".res"
	if not ResourceLoader.exists(path): return null
	var item: Resource = load(path)
	if not item is Definition or item.plant_id != key or not item.valid(): return null
	return item

## Twenty shared designs with separate receiving-study and live emanator anatomy.
static func foliage_definition(biome: int, variation: int, circulation: String = "receiver", low_detail: bool = false, catalog: RefCounted = null) -> Resource:
	if catalog != null: return catalog.definition("foliage_%d_%d_%s%s" % [biome, variation, circulation, "_cover" if low_detail else ""])
	if biome not in [0,1,2,3] or variation<0 or variation>4: return null
	if circulation not in ["receiver","emanator"]: return null
	var key := "foliage_%d_%d"%[biome,variation]+("_emanator" if circulation=="emanator" else "")+("_cover" if low_detail else "")
	if foliage_entries.has(key): return foliage_entries[key]
	var baked := baked_definition(key)
	if baked != null:
		foliage_entries[key] = baked
		return baked
	var reviewed:=reviewed_definition(key)
	if reviewed!=null:
		foliage_entries[key]=reviewed
		return reviewed
	var builder = preload("res://scripts/scenery/generic_foliage_mesh.gd").new()
	builder.tube_sides=4
	var settings := {"foliage_variation":variation,"branches":7,"foliage":1.0,"anatomy_scale":1.2,"organic_softness":0.9,"branch_irregularity":0.15,"leaf_asymmetry":0.12,"height_diversity":0.25,"branching_depth":1,"plant_recursive_depth":1+variation%3,"tree_fractal_growth":true,"hue_shift":0.0,"biome_palette_variant":variation}
	if low_detail:
		builder.tube_sides=3
		settings.merge({"branches":7+variation%3,"foliage":1.0,"anatomy_scale":0.7,"plant_recursive_depth":0,"branching_depth":0,"leaf_width":0.22,"groundcover_detail":true},true)
	var specimen: Dictionary=builder.create_sample(biome,0 if circulation=="emanator" else 2,(382+variation)*10000+biome*101+(0 if circulation=="emanator" else 26),settings,builder.make_anatomy_materials())
	var root := Node3D.new()
	for mesh: ArrayMesh in [specimen.body,specimen.anatomy]:
		var node := MeshInstance3D.new()
		node.mesh=mesh
		root.add_child(node)
		node.owner=root
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	var item := Definition.new()
	item.plant_id=key
	item.display_name=specimen.growth_plan
	item.scene=packed
	item.growth_category="generic_foliage"
	item.biome=biome
	item.circulation_role=circulation
	item.enabled_in_world=circulation=="emanator"
	item.world_height=[0.45,0.7,0.25,0.9][biome]
	item.world_width=[0.8,0.9,0.6,0.6][biome]
	if low_detail:
		item.display_name="Leaf grass"
		item.world_height=[0.3,0.35,0.22,0.45][biome]
		item.world_width=0.4
	item.recipe=settings.duplicate()
	item.recipe["roots_below_ground"]=true
	item.recipe.merge({"growth_category":1,"generic_circulation":0 if circulation=="emanator" else 1,"selected_biome":biome+1,"selected_role":1 if circulation=="emanator" else 3,"generation_seed":382+variation,"branch_count":int(settings.branches),"anatomy_thickness":float(settings.anatomy_scale),"foliage_density":float(settings.foliage),"world_height":item.world_height,"world_width":item.world_width})
	var positions := {}
	for organ: Dictionary in specimen.organs: positions[organ.id]=organ.position
	item.organ_graph=specimen.organs.duplicate(true)
	item.organ_anchors={"ground":positions.ground,"receive":positions.intake,"release":positions.outlet,"crown":positions.reserve}
	foliage_entries[key]=item
	return item

static func model(item: Resource, catalog: RefCounted = null) -> Dictionary:
	if catalog != null: return catalog.models.get(item.plant_id, {})
	if not models.has(item.plant_id):
		models[item.plant_id] = Art.parts(item.scene) if item.get_meta("runtime_palette", false) else Art.compact_parts(item.scene)
		for piece: Dictionary in models[item.plant_id].pieces:
			preload("res://scripts/presentation/mesh_picking.gd").prepare(piece.mesh)
	return models[item.plant_id]

## Approved visual baselines occupy existing ecological slots, without new reserves.
static func live_meshes(sample: Dictionary, tree: bool) -> Array[ArrayMesh]:
	var result: Array[ArrayMesh]=[sample.body]
	if not tree:
		result.append(sample.anatomy)
		return result
	var exposed := ArrayMesh.new()
	for surface in range(sample.anatomy.get_surface_count()):
		var material: Material=sample.anatomy.surface_get_material(surface)
		if not material is ShaderMaterial: continue
		exposed.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,sample.anatomy.surface_get_arrays(surface))
		exposed.surface_set_material(exposed.get_surface_count()-1,material)
	if exposed.get_surface_count()>0: result.append(exposed)
	return result

static func official_definition(id: String, catalog: RefCounted = null) -> Resource:
	if catalog != null: return catalog.definition("official_" + id)
	if official_entries.has(id): return official_entries[id]
	var entry := Species.get_design(id)
	if entry.is_empty() or not entry.live_ecology_eligible: return null
	var key := "official_" + id
	var baked := baked_definition(key)
	if baked != null:
		official_entries[id] = baked
		return baked
	var reviewed:=reviewed_definition(key)
	if reviewed!=null:
		official_entries[id]=reviewed
		return reviewed
	var recipe: Dictionary = entry.baseline_recipe.duplicate(true)
	var settings := recipe.duplicate(true)
	for alias: String in {"branches":"branch_count","leaf_scale":"leaf_size","foliage":"foliage_density","curl":"leaf_curl","anatomy_scale":"anatomy_thickness"}:
		var source: String = {"branches":"branch_count","leaf_scale":"leaf_size","foliage":"foliage_density","curl":"leaf_curl","anatomy_scale":"anatomy_thickness"}[alias]
		settings[alias] = recipe[source]
	if entry.circulation_role!="reservoir":
		settings.merge({"plant_recursive_depth":1+int(recipe.size_class),"tree_fractal_growth":true},true)
		settings["leaf_scale"] = float(settings.get("leaf_scale",1.0))*pow(0.8,int(recipe.size_class))
	else:
		# Balance live crowns without rewriting the authored species recipe.
		settings.merge({"branch_reach":1.2,"branch_rise_degrees":[50.0,55.0,48.0,57.0][int(recipe.selected_biome)-1],"branch_curve":0.05,"tree_fork_spread":0.72,"foliage_fullness":1.35},true)
	var builder = preload("res://scripts/scenery/generic_foliage_mesh.gd").new() if entry.growth_category == "generic_foliage" else preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").new()
	var sample: Dictionary
	for sides in [8,4,3]:
		builder.tube_sides = sides
		sample = builder.create_sample(int(recipe.selected_biome)-1,int(recipe.selected_role)-1,int(recipe.specimen_seed_override),settings,builder.make_anatomy_materials())
		var triangles := 0
		for mesh: ArrayMesh in live_meshes(sample,entry.circulation_role=="reservoir"):
			for surface in range(mesh.get_surface_count()): triangles += mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
		if triangles <= 30000: break
	var body := Node3D.new()
	for mesh: ArrayMesh in live_meshes(sample,entry.circulation_role=="reservoir"):
		var piece := MeshInstance3D.new()
		piece.mesh = mesh
		piece.scale = Vector3.ONE * float(recipe.plant_size)
		body.add_child(piece)
		piece.owner = body
	var item := Definition.new()
	item.scene = PackedScene.new()
	item.scene.pack(body)
	body.free()
	item.plant_id = key
	item.catalog_design_id = id
	item.species_id = entry.species_id
	item.display_name = entry.display_name
	item.growth_category = entry.growth_category
	item.biome = int(recipe.selected_biome)-1
	item.circulation_role = entry.circulation_role
	item.specialist_class = entry.specialist_class
	item.size_class = int(recipe.size_class)
	item.world_height = float(recipe.world_height)
	item.world_width = float(recipe.world_width)
	item.preserve_proportions = recipe.preserve_proportions
	item.frequency_percent = 100
	item.enabled_in_world = true
	item.recipe = recipe
	item.recipe["roots_below_ground"] = true
	item.organ_graph = sample.organs.duplicate(true)
	item.organ_graph.append_array(sample.get("leaf_surfaces", []))
	var positions := {}
	for organ: Dictionary in item.organ_graph:
		organ.position *= float(recipe.plant_size)
		positions[organ.id] = organ.position
	item.organ_anchors = {"ground":positions.ground,"receive":positions.get("intake",positions.get("reservoir_ring",positions.reserve)),"release":positions.get("outlet",positions.get("crown",positions.reserve)),"crown":positions.get("crown",positions.reserve)}
	official_entries[id] = item
	return item

static func official_candidates(biome: int, traits: Dictionary, catalog: RefCounted = null) -> Array[String]:
	if catalog != null: return catalog.official.get("%d:%s:%s" % [biome, traits.role, traits["class"]], [])
	var key := "%d:%s:%s" % [biome, traits.role, traits["class"]]
	if official_slot_cache.has(key): return official_slot_cache[key]
	var result: Array[String] = []
	for entry: Dictionary in Species.all():
		if entry.live_ecology_eligible and int(entry.baseline_recipe.selected_biome)-1 == biome and entry.circulation_role == traits.role and entry.specialist_class == traits["class"]:
			result.append(entry.design_id)
	result.sort()
	official_slot_cache[key] = result
	return result

## Canonical flora owns admission and reserves; grass clumps share that cell owner.
static func add_cell(chunk: Object,terrain: WorldTerrain,cell: Vector2i,data: Dictionary,settings: NatureSettings) -> Dictionary:
	var work := begin_cell(chunk,terrain,cell,data,settings)
	while not advance_cell(work): pass
	return work.body

## A cursor belongs to one unpublished chunk and never writes expedition state.
static func begin_cell(chunk: Object,terrain: WorldTerrain,cell: Vector2i,data: Dictionary,settings: NatureSettings, catalog: RefCounted = null) -> Dictionary:
	return {"chunk":chunk,"terrain":terrain,"cell":cell,"data":data,"settings":settings,"stage":0,"body":{},"grass":{},"catalog":catalog}

## Placement, body submission, each grass clump and endpoint commit are separate
## cooperative operations. Cold resource loads/model generation remain atomic.
static func advance_cell(work: Dictionary) -> bool:
	var catalog: RefCounted = work.get("catalog")
	var chunk: Object = work.chunk
	var terrain: WorldTerrain = work.terrain
	var cell: Vector2i = work.cell
	var settings: NatureSettings = work.settings
	if work.stage == 0:
		var kind := terrain.flora_kind(cell,work.data)
		work["kind"] = kind
		if kind.is_empty(): return true
		var traits := FloraTraits.describe(terrain.world_seed,{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":kind},terrain.flora_specialist_percent)
		work["traits"] = traits
		work.body = placement(terrain,cell,work.data,kind,true,settings.plant_instance_variation,settings.foliage_coverage if settings.meadow_enabled else 0.0,settings.foliage_size_multiplier, catalog)
		work.stage = 1
		return false
	if work.stage == 1:
		var grass_cover := false
		if work.kind=="plant" and int(work.data.ground) in [0,1,2,3] and work.traits.role=="emanator" and work.body.is_empty() and settings.meadow_enabled and settings.foliage_coverage>0.0:
			var cover := foliage_definition(int(work.data.ground),terrain.roll(cell,771949)%5,"emanator",true, catalog)
			work.body=fit_definition(terrain,cell,work.kind,cover,false,0.0,lerpf(0.5,0.75,float(terrain.roll(cell,771953)%1001)/1000.0), false, catalog)
			grass_cover=not work.body.is_empty()
		work["grass_cover"] = grass_cover
		if not work.body.is_empty():
			if not grass_cover: chunk.add_composed_nature(work.body)
			if grass_cover or (settings.meadow_enabled and settings.foliage_coverage>0.0):
				work.grass=begin_grass_clumps(chunk,terrain,cell,int(work.data.ground),work.body,settings.foliage_coverage,settings,not grass_cover, catalog)
		work.stage = 2
		return false
	if work.stage == 2:
		if not work.grass.is_empty():
			if not advance_grass_clumps(work.grass): return false
			if work.grass_cover: work.body=work.grass.first
		work.stage = 3
		return false
	# Rendering density and rejected art never remove a canonical endpoint.
	if work.kind=="plant" and not chunk.living_sources.has(cell):
		var anchor := Vector3(cell.x+0.5,terrain.surface_height(Vector2(cell)+Vector2(0.5,0.5))+0.05,cell.y+0.5)
		chunk.register_living_source(cell,"detail",work.traits.name,anchor)
	return true

static func grass_patch(terrain: WorldTerrain, point: Vector2, settings: NatureSettings, catalog: RefCounted = null) -> float:
	if catalog != null: return clampf(0.5 + catalog.grass_field.get_noise_2d(point.x,point.y),0.0,1.0)
	var key := "%d:%.3f" % [terrain.world_seed,settings.grass_patch_cells]
	if not grass_fields.has(key):
		if grass_fields.size() >= 4: grass_fields.clear()
		var field := FastNoiseLite.new()
		field.seed = terrain.world_seed
		field.frequency = 1.0 / settings.grass_patch_cells
		grass_fields[key] = field
	return clampf(0.5 + grass_fields[key].get_noise_2d(point.x,point.y),0.0,1.0)

static func grass_height_range(weight: float, settings: NatureSettings) -> Vector2:
	return settings.grass_short_height.lerp(settings.grass_medium_height,smoothstep(0.0,0.5,weight)) if weight < 0.5 else settings.grass_medium_height.lerp(settings.grass_tall_height,smoothstep(0.5,1.0,weight))

static func grass_solid_segments(body: Dictionary, settings: NatureSettings) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var center := Vector3(body.cell.x+0.5,body.bounds.position.y,body.cell.y+0.5)
	var radius := maxf(settings.grass_base_clearance,minf(0.35,body.transform.basis.get_scale().x * 0.085))
	result.append({"a":center,"b":center,"radius":radius,"stem":true})
	var organs: Dictionary = body.get("vastra_organs",{})
	for id: String in organs:
		var organ: Dictionary = organs[id]
		if not "root" in str(organ.get("kind",id)).to_lower(): continue
		var parent: String = organ.get("parent","")
		if not organs.has(parent): continue
		result.append({"a":organs[parent].position,"b":organ.position,"radius":maxf(settings.grass_base_clearance,radius*0.6),"stem":false})
	return result

static func grass_point_clear(point: Vector2, surface: float, solids: Array[Dictionary]) -> bool:
	for segment in solids:
		var a := Vector2(segment.a.x,segment.a.z)
		var b := Vector2(segment.b.x,segment.b.z)
		var along := clampf((point-a).dot(b-a)/maxf(a.distance_squared_to(b),0.000001),0.0,1.0)
		var height := lerpf(segment.a.y,segment.b.y,along)
		# Buried transport roots do not clear a canopy-sized patch of grass.
		if not segment.stem and (height < surface-0.02 or height > surface+0.2): continue
		if point.distance_to(a.lerp(b,along)) < float(segment.radius): return false
	return true

static func add_grass_clumps(chunk: Object,terrain: WorldTerrain,cell: Vector2i,biome: int,admitted: Dictionary,coverage: float = 0.65,tuning: NatureSettings = null,preserve_body: bool = false) -> Dictionary:
	var work := begin_grass_clumps(chunk,terrain,cell,biome,admitted,coverage,tuning,preserve_body)
	while not advance_grass_clumps(work): pass
	return work.first

static func begin_grass_clumps(chunk: Object,terrain: WorldTerrain,cell: Vector2i,biome: int,admitted: Dictionary,coverage: float,tuning: NatureSettings,preserve_body: bool, catalog: RefCounted = null) -> Dictionary:
	var settings: NatureSettings = tuning if tuning != null else load("res://resources/nature_settings.tres")
	var random := RandomNumberGenerator.new()
	random.seed=terrain.roll(cell,771957)
	# Coverage thins clumps, rather than switching whole tiles on and off. A
	# world-anchored field gives neighboring cells a shared, softly varying sward.
	var fullness := grass_patch(terrain,Vector2(cell)+Vector2(0.5,0.5),settings, catalog)
	var solids: Array[Dictionary] = []
	if preserve_body: solids = grass_solid_segments(admitted,settings)
	var count := clampi(roundi(lerpf(24.0,36.0,fullness)*coverage),1,42)
	var slots := range(42)
	for index in range(slots.size()-1,0,-1):
		var other := random.randi_range(0,index)
		var value: int=slots[index]
		slots[index]=slots[other]
		slots[other]=value
	return {"chunk":chunk,"terrain":terrain,"cell":cell,"biome":biome,"admitted":admitted,"settings":settings,"preserve_body":preserve_body,"random":random,"solids":solids,"count":count,"slots":slots,"index":0,"first":{},"organs":{},"catalog":catalog}

## Exactly one candidate per call; rejected candidates retain the original RNG order.
static func advance_grass_clumps(work: Dictionary) -> bool:
	var catalog: RefCounted = work.get("catalog")
	var first: Dictionary=work.first
	var organs: Dictionary=work.organs
	var chunk: Object=work.chunk
	var preserve_body: bool=work.preserve_body
	if work.index>=work.count:
		if not first.is_empty() and not preserve_body:
			first.vastra_organs=organs
			chunk.living_sources[work.cell]["organs"]=organs
		return true
	var index: int=work.index
	work.index+=1
	var terrain: WorldTerrain=work.terrain
	var cell: Vector2i=work.cell
	var biome: int=work.biome
	var admitted: Dictionary=work.admitted
	var settings: NatureSettings=work.settings
	var random: RandomNumberGenerator=work.random
	var solids: Array[Dictionary]=work.solids
	var slots: Array=work.slots
	var count: int=work.count
	var item: Resource=foliage_definition(biome,random.randi_range(0,4),"emanator",true, catalog)
	var parts := model(item, catalog)
	var slot: int=slots[index]
	# Half-slot jitter keeps neighboring roots at least 0.9 / 7 * 0.5
	# cells apart; unrestricted jitter allowed adjacent slots to bunch together.
	var point := Vector2(cell)+Vector2(0.05,0.05)+Vector2((slot%7+random.randf_range(0.25,0.75))/7.0,(slot/7+random.randf_range(0.25,0.75))/6.0)*0.9
	if terrain.surface_normal(point).y<cos(deg_to_rad(float(terrain.relief.walkable_slope_degrees))): return false
	var surface := terrain.surface_height(point)
	if not grass_point_clear(point,surface,solids): return false
	var size: Vector3 = item.scale_for(parts.bounds)*random.randf_range(0.5,0.6)
	var heights := grass_height_range(grass_patch(terrain,point,settings, catalog),settings)
	var height := lerpf(heights.x,heights.y,random.randf())
	size.y = height / maxf(parts.bounds.end.y,0.001)
	var basis := Basis(Vector3.UP,random.randf_range(-PI,PI))*Basis.from_scale(size)
	var pose := Transform3D(basis,Vector3(point.x,surface,point.y))
	pose.origin-=basis*item.ground_offset(parts.bounds)
	pose.origin.y-=minf(item.root_burial,maxf(0.001,parts.bounds.end.y*size.y)*0.1)
	var row := admitted.duplicate()
	row.erase("vastra_organs")
	row.merge({"asset":item.plant_id,"model":parts,"transform":pose,"bounds":pose*parts.bounds,"growth_category":"generic_foliage","variation":int(item.recipe.foliage_variation),"grass_clumps":count,"ground_cover":true,"category":"detail","preserve_body":preserve_body,"grass_height":height,"vastra_anchor":pose*item.organ_anchors.receive},true)
	# One full organ graph per canonical cell, plus the actual attachment of
	# each extra clump. A full graph per blade population grows memory rapidly.
	if first.is_empty() and not preserve_body: row["vastra_organs"]=world_organs(item,pose)
	chunk.add_composed_nature(row)
	if first.is_empty():
		work.first=row
		first=row
		if not preserve_body:
			organs=row.vastra_organs.duplicate(true)
			work.organs=organs
	elif not preserve_body:
		organs["grass_clump%d"%index]={"position":row.vastra_anchor,"parent":"intake","kind":"Leaf conductor"}
	return false

static func placement(terrain: WorldTerrain,cell: Vector2i,data: Dictionary,kind: String, procedural_fallback: bool = false, instance_variation: float = 0.12, foliage_coverage: float = 0.0,foliage_size: float = 2.0, catalog: RefCounted = null) -> Dictionary:
	if catalog == null and not loaded: refresh()
	if data.ground not in [0,1,2,3] or terrain.flora_kind(cell,data)!=kind: return {}
	var traits := FloraTraits.describe(terrain.world_seed,{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":kind},terrain.flora_specialist_percent)
	var candidates: Array[Resource] = []
	for item in (catalog.entries if catalog != null else entries):
		if item.enabled_in_world and item.biome==data.ground and item.circulation_role==traits.role and item.specialist_class==traits["class"]: candidates.append(item)
	var selected: Resource
	var procedural := false
	if not candidates.is_empty():
		selected = candidates[terrain.roll(cell,771931)%candidates.size()]
		if terrain.roll(cell,771933)%100>=selected.frequency_percent: selected = null
	if selected==null and procedural_fallback and traits.role!="emanator":
		var official := official_candidates(int(data.ground),traits, catalog)
		selected = official_definition(official[terrain.roll(cell,771937)%official.size()], catalog) if not official.is_empty() else procedural_definition(int(data.ground),traits,terrain.roll(cell,771937)%3, catalog)
		procedural = true
	# Mix authored trees with size-dependent branching silhouettes on canonical slots.
	if kind=="tree" and procedural_fallback and candidates.is_empty() and terrain.roll(cell,771943)%100<65:
		selected = procedural_definition(int(data.ground),traits,terrain.roll(cell,771945)%9, catalog)
		procedural = true
	if selected==null and procedural_fallback and traits.role=="emanator" and foliage_coverage>0.0:
		var proposal := Distribution.proposal(terrain,cell,data,foliage_coverage,catalog.distribution_field if catalog != null else null)
		if proposal.is_empty() or not Distribution.has_space(terrain,cell,proposal,foliage_coverage,catalog.distribution_field if catalog != null else null): return {}
		selected=foliage_definition(int(proposal.biome),int(proposal.variation),"emanator", false, catalog)
		var official := official_candidates(int(proposal.biome),traits, catalog)
		if not official.is_empty(): selected = official_definition(official[int(proposal.variation)%official.size()], catalog)
		for smaller: float in [1.0,0.72,0.5]:
			var fitted := fit_definition(terrain,cell,kind,selected,false,0.0,float(proposal.scale)*smaller*foliage_size, false, catalog)
			if not fitted.is_empty():
				fitted.merge({"growth_category":"generic_foliage","variation":proposal.variation,"community":proposal.patch_id,"size_factor":float(proposal.scale)*smaller*foliage_size})
				return fitted
		return {}
	if selected==null: return {}
	if kind=="plant":
		selected = selected.duplicate(false)
		selected.world_height *= foliage_size
		selected.world_width *= foliage_size
	if procedural:
		for smaller: float in [1.0,0.72,0.5]:
			var fitted := fit_definition(terrain,cell,kind,selected,true,instance_variation,smaller, false, catalog)
			if not fitted.is_empty(): return fitted
		if kind=="tree" and selected.size_class>0:
			var small_tree: Resource=procedural_definition(int(data.ground),traits,0, catalog)
			var fitted := fit_definition(terrain,cell,kind,small_tree,true,instance_variation,0.72, false, catalog)
			if not fitted.is_empty(): return fitted
	else:
		var fitted := fit_definition(terrain,cell,kind,selected,false,instance_variation, 1.0, false, catalog)
		if not fitted.is_empty(): return fitted
	# A canonical tree already blocks this cell even if a broad canopy cannot fit.
	# Keep its body inside its own cell using the current procedural plant palette.
	if kind=="tree" and procedural_fallback:
		var sapling: Resource=procedural_definition(int(data.ground),traits,0, catalog)
		return fit_definition(terrain,cell,kind,sapling,true,instance_variation,1.0,true, catalog)
	# Canonical specialists remain visible when neighboring plants or paths leave
	# no room for their full silhouette. Keep the selected design inside its own
	# cell; the ordinary terrain/reservation checks still own admission.
	if kind=="plant" and procedural_fallback and traits.role!="emanator":
		return fit_definition(terrain,cell,kind,selected,procedural,instance_variation,1.0,true, catalog)
	return {}

static func fit_definition(terrain: WorldTerrain,cell: Vector2i,kind: String,selected: Resource,procedural: bool,instance_variation: float,size_multiplier: float = 1.0,confined_cell: bool = false, catalog: RefCounted = null) -> Dictionary:
	if selected == null: return {}
	var parts := model(selected, catalog)
	if not parts.supported or parts.pieces.is_empty() or parts.triangles>30000 or parts.surfaces>12: return {}
	var box: AABB = parts.bounds
	var size_scale: Vector3=selected.scale_for(box)
	if kind=="tree": size_scale=Vector3.ONE*minf(size_scale.x,minf(size_scale.y,size_scale.z))
	size_scale*=size_multiplier
	if procedural:
		# A presentation-only stream: never consumes RNG or changes canonical flora.
		var amount := clampf(instance_variation,0.0,MAX_INSTANCE_VARIATION)
		size_scale *= lerpf(1.0-amount,1.0+amount,float(terrain.roll(cell,771941)%10001)/10000.0)
	var point := Vector2(cell)+Vector2(0.5,0.5)
	var normal := terrain.surface_normal(point)
	if not normal.is_finite() or normal.y<=0.0: return {}
	if (not confined_cell or kind!="tree") and normal.y<cos(deg_to_rad(float(terrain.relief.walkable_slope_degrees))): return {}
	var orientation := Basis(Vector3.UP,float(terrain.roll(cell,771935)%6283)/1000.0)
	if confined_cell:
		var rotated: AABB = Transform3D(orientation*Basis.from_scale(size_scale),Vector3.ZERO)*box
		var narrow := minf(1.0,0.4/maxf(rotated.size.x,rotated.size.z))
		# Confined bodies retain their authored proportions.
		size_scale*=minf(narrow,1.5/maxf(rotated.size.y,0.001))
	# Gravitropic growth stays upright on slopes; the soil anchor follows height.
	var basis := orientation*Basis.from_scale(size_scale)
	var transform := Transform3D(basis,Vector3(point.x,terrain.surface_height(point),point.y))
	transform.origin -= basis*selected.ground_offset(box)
	var above_ground := box.end.y if selected.recipe.get("roots_below_ground",false) else box.size.y
	transform.origin.y -= minf(selected.root_burial,maxf(0.001,above_ground*size_scale.y)*0.1)
	# The authored soil plane is already aligned; only roots extend beneath it.
	var bounds: AABB = transform*box
	var sway_margin:=0.16+maxf(size_scale.x,size_scale.z)*0.12
	if confined_cell and (bounds.position.x-sway_margin<float(cell.x) or bounds.end.x+sway_margin>float(cell.x+1) or bounds.position.z-sway_margin<float(cell.y) or bounds.end.z+sway_margin>float(cell.y+1)): return {}
	# Canopies may overhang paths and understory; the trunk owns ground clearance.
	var footprint := AABB(Vector3(point.x-0.35,0,point.y-0.35),Vector3(0.7,1,0.7)) if kind=="tree" else bounds
	for y in range(floori(footprint.position.z-(0.05 if kind=="tree" else sway_margin)),ceili(footprint.end.z+(0.05 if kind=="tree" else sway_margin))):
		for x in range(floori(footprint.position.x-(0.05 if kind=="tree" else sway_margin)),ceili(footprint.end.x+(0.05 if kind=="tree" else sway_margin))):
			var at := Vector2i(x,y)
			if terrain.scenery_reserved(at) or terrain.route_axes(at,1)!=0 or terrain.is_camp(at) or terrain.is_landmark(at) or terrain.cabin_footprint.grow(1).has_point(at): return {}
			var sample := terrain.sample(at)
			if sample.ground not in [0,1,2,3] or (sample.obstacle!=0 and not (kind=="tree" and at==cell)): return {}
			if at!=cell and not sample.walkable: return {}
			if selected.growth_category=="generic_foliage" and at!=cell and terrain.flora_kind(at,sample)=="plant":
				var adjacent := FloraTraits.describe(terrain.world_seed,{"id":FloraCatalog.id_for(at),"cell":[at.x,at.y],"kind":"plant"},terrain.flora_specialist_percent)
				if adjacent.role=="receiver": return {}
	var category := "tree" if kind=="tree" else "detail"
	return {"asset":catalog.assets[selected.plant_id] if catalog != null else (selected.plant_id if selected.get_meta("runtime_palette", false) or selected.scene.resource_path.is_empty() else selected.scene.resource_path),"cell":cell,"transform":transform,"bounds":bounds,"patch":"authored_plant","living":true,"model":parts,"subject":selected.display_name,"category":category,"flora_id":FloraCatalog.id_for(cell),"vastra_organs":world_organs(selected,transform),"vastra_anchor":transform*selected.organ_anchors.receive,"high_anchor":transform*selected.organ_anchors.crown if kind=="tree" else Vector3.INF}

static func maximum_height() -> float:
	if not loaded: refresh()
	return maxf(largest_height,largest_foliage_height*3.0) # Inspector foliage scale ceiling.

static func maximum_width() -> float:
	if not loaded: refresh()
	return maxf(largest_width,largest_foliage_width*3.0)

## One fade material per grass source, shared across chunks. Ordinary foliage
## retains its original material; no per-instance shader buffer is allocated.
static func grass_material(source: ShaderMaterial) -> ShaderMaterial:
	if not grass_materials.has(source): grass_materials[source] = source.duplicate()
	return grass_materials[source]

static func apply_gust(material: ShaderMaterial, strength: float, seconds: float, cells: float) -> void:
	var signature := Vector3(strength,seconds,cells)
	if material.get_meta("gust_tuning",Vector3(-1,-1,-1)) == signature: return
	material.set_meta("gust_tuning",signature)
	material.set_shader_parameter("wind_gust_strength",strength)
	material.set_shader_parameter("wind_gust_seconds",seconds)
	material.set_shader_parameter("wind_gust_cells",cells)

static func set_weather(direction: Vector2,seconds: float,strength: float,origin: Vector2 = Vector2.ZERO,rain: float = 0.0,gust_strength: float = 0.7,gust_seconds: float = 8.0,gust_cells: float = 24.0) -> void:
	Groundcover.set_weather(direction,rain,seconds,origin)
	for parts: Dictionary in models.values():
		for piece: Dictionary in parts.pieces:
			for index in range(piece.mesh.get_surface_count()):
				var material: Material = piece.mesh.surface_get_material(index)
				if material is ShaderMaterial:
					apply_gust(material,gust_strength,gust_seconds,gust_cells)
					material.set_shader_parameter("wind_time",seconds)
					material.set_shader_parameter("wind_strength",clampf(strength,0,1))
					material.set_shader_parameter("wind_direction",direction.normalized() if direction.length_squared()>0.0001 else Vector2.ZERO)
					material.set_shader_parameter("world_origin",origin)
	for material: ShaderMaterial in grass_materials.values():
		apply_gust(material,gust_strength,gust_seconds,gust_cells)
		material.set_shader_parameter("wind_time",seconds)
		material.set_shader_parameter("wind_strength",clampf(strength,0,1))
		material.set_shader_parameter("wind_direction",direction.normalized() if direction.length_squared()>0.0001 else Vector2.ZERO)
		material.set_shader_parameter("world_origin",origin)

# A bounded shared palette, independent of world seed and streaming order.
# The canonical cell selects its variant; geometry never owns flora or reserves.
static func procedural_definition(biome: int, traits: Dictionary, variant: int, catalog: RefCounted = null) -> Resource:
	if catalog != null: return catalog.definition("procedural_%d_%d_%d" % [biome, 1 if traits.role == "reservoir" else 3 + FloraTraits.CLASSES.find(traits["class"]), variant])
	var size_variant := variant%3
	var role_index := 1 if traits.role=="reservoir" else 3+FloraTraits.CLASSES.find(traits["class"])
	var key := "procedural_%d_%d_%d"%[biome,role_index,variant]
	if procedural_entries.has(key): return procedural_entries[key]
	var baked := baked_definition(key)
	if baked != null:
		procedural_entries[key] = baked
		return baked
	var reviewed:=reviewed_definition(key)
	if reviewed!=null:
		procedural_entries[key]=reviewed
		return reviewed
	var random := RandomNumberGenerator.new()
	random.seed = 93017+biome*1009+role_index*71+variant*13
	var settings := {"branches":5,"foliage":0.65,"node_count":5,"frond_pairs":4,"leaf_architecture":0,"branch_irregularity":variant*0.3,"leaf_asymmetry":size_variant*0.25,"height_ratio":random.randf_range(0.6,1.5),"spread_ratio":random.randf_range(0.55,1.45),"branch_twist":random.randf_range(-0.6,0.6),"node_bulk":random.randf_range(0.7,1.5),"leaf_width":random.randf_range(0.65,1.4),"hue_shift":random.randf_range(-12.6,12.6)}
	if role_index!=1:
		settings.merge({"plant_recursive_depth":1+variant,"branching_depth":1,"tree_fractal_growth":true,"leaf_scale":pow(0.8,variant),"stem_thickness":pow(0.85,variant)},true)
	if role_index==1:
		settings.merge({"tree_leaf_cards":true,"foliage":1.25,"foliage_fullness":1.5,"node_count":5,"branches":4+variant*2,"tree_fractal_growth":true,"tree_fork_depth":1+variant,"leaf_scale":pow(0.65,variant),"stem_thickness":pow(0.72,variant),"tree_fork_spread":0.95,"branching_depth":1,"height_ratio":1.0+variant*0.35,"spread_ratio":random.randf_range(1.1,1.5)+variant*0.2},true)
	settings.merge({"foliage_palette":0,"biome_palette_variant":posmod(variant+role_index,5),"bark_palette":0,"flower_palette":random.randi_range(0,6),"color_gradient":random.randf_range(0.3,0.6),"branch_reach":random.randf_range(1.1,1.5),"branch_arch":random.randf_range(0.65,1.0)})
	if role_index==1:
		settings.merge({"branches":5+size_variant,"branching_depth":2,"tree_fork_depth":1+size_variant,"branch_twist":0.0,"branch_irregularity":0.18,"height_ratio":1.0,"spread_ratio":[1.35,1.15,1.5,0.95][biome]*random.randf_range(0.85,1.15),"crown_habit":variant/3,"branch_rise_degrees":random.randf_range([35.0,45.0,30.0,48.0][biome],[55.0,65.0,50.0,68.0][biome]),"trunk_lean":random.randf_range(-0.07,0.07),"trunk_curve":random.randf_range(0.025,0.07),"trunk_phase":random.randf_range(-PI,PI),"stem_thickness":pow(0.88,size_variant),"leaf_scale":pow(0.65,size_variant)},true)
	if role_index==1:
		var habit := variant/3
		settings["spread_ratio"]=[1.15,1.1,1.2,1.05][biome]*random.randf_range(0.95,1.05)*[1.0,0.95,1.08][habit]
		settings["branch_reach"]=random.randf_range(1.15,1.3)
		settings["branch_curve"]=random.randf_range(0.035,0.065)
		settings["tree_fork_spread"]=random.randf_range(0.65,0.8)
		settings["foliage_fullness"]=random.randf_range(1.35,1.6)
		settings["tree_leaf_cards"]=habit!=2
		if habit==2:
			# Keep plant-style leaves on short leafy shoots, rather than sparse bare forks.
			settings["foliage_fullness"]=1.25
			settings["branching_depth"]=1
		settings["branch_rise_degrees"] = random.randf_range([46.0,50.0,44.0,52.0][biome],[54.0,58.0,52.0,60.0][biome])+[0.0,2.0,-2.0][habit]
	var builder = preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").new()
	builder.tube_sides=3 if role_index!=1 else 4
	var specimen_seed := random.randi_range(1,10000)
	var sample: Dictionary = builder.create_sample(biome,role_index,specimen_seed,settings,preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").make_anatomy_materials())
	var root := Node3D.new()
	for mesh: ArrayMesh in live_meshes(sample,role_index==1):
		var node := MeshInstance3D.new()
		node.mesh = mesh
		root.add_child(node)
		node.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	var item := Definition.new()
	item.plant_id = key
	item.display_name = builder.PLANS[biome*6+role_index]
	item.scene = packed
	item.biome = biome
	item.circulation_role = traits.role
	item.specialist_class = traits["class"]
	item.size_class = size_variant
	if role_index==1: item.preserve_proportions = true
	item.world_height = (TREE_HEIGHTS[size_variant] if role_index==1 else GROUND_HEIGHTS[size_variant])*random.randf_range(0.7,1.25)
	var box: AABB=sample.body.get_aabb().merge(sample.anatomy.get_aabb())
	var natural_width:=item.world_height*maxf(box.size.x,box.size.z)/maxf(0.000001,box.end.y)
	var normal_width: float=([3.0,5.0,8.0][size_variant] if role_index==1 else [0.2,0.6,1.3][variant])*1.1
	item.world_width=clampf(natural_width if role_index==1 else minf(natural_width,normal_width),0.02,20.0 if role_index==1 else 12.0)
	item.frequency_percent = 100
	item.enabled_in_world = true
	item.recipe = settings.duplicate()
	item.recipe["roots_below_ground"]=true
	item.recipe.merge({"selected_biome":biome+1,"selected_role":role_index+1,"specimen_seed_override":specimen_seed})
	var positions := {}
	for organ: Dictionary in sample.organs: positions[organ.id] = organ.position
	item.organ_graph = sample.organs.duplicate(true)
	item.organ_graph.append_array(sample.get("leaf_surfaces", []))
	item.organ_anchors = {"ground":positions.ground,"receive":positions.get("intake",positions.get("reservoir_ring",positions.reserve)),"release":positions.get("outlet",positions.get("crown",positions.reserve)),"crown":positions.get("crown",positions.reserve)}
	procedural_entries[key] = item
	return item

## World-space anatomy belongs to the placed body, never to the saved ledger.
static func world_organs(item: Resource, transform: Transform3D) -> Dictionary:
	var result := {}
	for key in item.organ_anchors:
		result[key] = {"position":transform*item.organ_anchors[key],"parent":""}
	for organ: Dictionary in item.organ_graph:
		result[organ.id] = {"position":transform*organ.position,"parent":organ.parent}
	if result.has("reservoir_ring") and result.has("trunk_joint1"):
		# Match the authored collar's real radius/plane so external packets touch
		# its surface instead of fading into an occluded point inside the trunk.
		var joints := 0
		for id: String in result:
			if id.begins_with("trunk_joint"): joints += 1
		var scale_factor := float(item.recipe.get("plant_size",1.0))*transform.basis.x.length()
		var thickness := float(item.recipe.get("stem_thickness",1.0))
		result.reservoir_ring["surface_radius"] = (0.18*lerpf(1.0,0.36,3.0/float(joints+3))+0.014)*thickness*scale_factor
		result.reservoir_ring["axis"] = (result.trunk_joint1.position-result.reserve.position).normalized()
	return result
