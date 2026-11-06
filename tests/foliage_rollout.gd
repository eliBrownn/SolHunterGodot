extends SceneTree
const Library=preload("res://scripts/scenery/plant_library.gd")
const Distribution=preload("res://scripts/scenery/foliage_distribution.gd")
const Chunk=preload("res://scripts/presentation/solid_chunk.gd")
var checks:=0
var failures:=0
class FlatTerrain extends WorldTerrain:
	var biome:=0
	var blocked: Dictionary={}
	func sample(cell: Vector2i) -> Dictionary:
		return {"ground":biome,"obstacle":0,"walkable":true,"wetness":0.65,"trail_visible":false}
	func flora_kind(_cell: Vector2i,_data: Dictionary) -> String: return "plant" if biome<4 else ""
	func scenery_reserved(cell: Vector2i) -> bool: return blocked.has(cell)
	func route_axes(_cell: Vector2i,_margin: int=0) -> int: return 0
	func is_camp(_cell: Vector2i) -> bool: return false
	func is_landmark(_cell: Vector2i) -> bool: return false
	func surface_height(_point: Vector2) -> float: return 0.0
	func surface_normal(_point: Vector2) -> Vector3: return Vector3.UP
	func lake_distance(_cell: Vector2i) -> float: return 2.0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(message)
func record(terrain: WorldTerrain,cell: Vector2i) -> Dictionary:
	return Library.placement(terrain,cell,terrain.sample(cell),"plant",true,0.12,0.65)
func stable(row: Dictionary) -> int:
	return hash([row.get("asset"),row.get("transform"),row.get("bounds"),row.get("flora_id"),row.get("community"),row.get("variation")])
func _initialize() -> void: run.call_deferred()
func run() -> void:
	Library.refresh(["res://artifacts/empty-foliage-rollout-library.json"])
	var selected: Dictionary={}
	for seed_value in [7,19,2601026]:
		var terrain:=FlatTerrain.new(seed_value)
		for biome in range(4):
			terrain.biome=biome
			var visible: Dictionary={}
			var forms: Dictionary={}
			var communities: Dictionary={}
			for y in range(-24,24):
				for x in range(-24,24):
					var cell:=Vector2i(x,y)
					var traits:=FloraTraits.describe(seed_value,{"id":FloraCatalog.id_for(cell),"cell":[x,y],"kind":"plant"})
					if traits.role!="emanator": continue
					var row:=record(terrain,cell)
					if row.is_empty(): continue
					visible[cell]=stable(row)
					forms[row.variation]=true
					var community: Vector2i=row.community
					if not communities.has(community): communities[community]={}
					communities[community][row.variation]=true
					check(row.flora_id==FloraCatalog.id_for(cell),"Foliage keeps its canonical owner")
					check(row.size_factor>=0.325 and row.size_factor<=1.10,"Bounded individual and smaller-fit sizes")
					selected={"terrain":terrain,"cell":cell,"row":row}
			check(visible.size()>10 and forms.size()==5,"All five live habitat designs appear across patches")
			for palette: Dictionary in communities.values(): check(palette.size()<=3,"Each community favors at most three forms")
			var cells:=visible.keys()
			cells.reverse()
			Distribution.fields.clear()
			for cell: Vector2i in cells: check(stable(record(terrain,cell))==visible[cell],"Reverse order and cache reconstruction retain placement")
			print("Foliage seed %d biome %d: %d bodies, %d forms"%[seed_value,biome,visible.size(),forms.size()])
	check(not selected.is_empty(),"Live test has a foliage body")
	if not selected.is_empty():
		var terrain: FlatTerrain=selected.terrain
		var cell: Vector2i=selected.cell
		var state:=ExpeditionState.new(terrain.world_seed)
		state.configure_flora(VastraSettings.new().plant_parameters())
		state.admit_flora([{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":"plant"}])
		var snapshot:=state.snapshot()
		var settings:=NatureSettings.new()
		settings.meadow_enabled=true
		settings.meadow_divisions=2
		var chunk:=Chunk.new()
		var row:=Library.add_cell(chunk,terrain,cell,terrain.sample(cell),settings)
		check(not row.is_empty() and chunk.living_sources.size()==1,"Grass and foliage share one ecological endpoint")
		check(chunk.living_sources[cell].anchor.is_equal_approx(row.vastra_anchor),"Foliage anatomy supplies the canonical visual anchor")
		var grass_present:=false
		for key: String in chunk.batches: grass_present=grass_present or key.begins_with("nature_detail_meadow")
		check(grass_present,"Reviewed blades remain visible around foliage")
		chunk.free()
		settings.foliage_coverage=0.0
		chunk=Chunk.new()
		Library.add_cell(chunk,terrain,cell,terrain.sample(cell),settings)
		check(chunk.living_sources.size()==1,"Disabling foliage does not remove membership")
		chunk.free()
		check(state.snapshot()==snapshot,"Rendering never changes saved reserves")
		var restored:=ExpeditionState.restore(snapshot,terrain.world_seed)
		check(restored!=null and restored.snapshot()==snapshot,"Canonical foliage cell survives save/load")
		terrain.blocked[cell]=true
		check(record(terrain,cell).is_empty(),"Protected center rejects every size alternative")
		terrain.biome=4
		check(record(terrain,cell).is_empty(),"Underwater foliage remains deferred")
	for biome in range(4):
		for variation in range(5):
			var item: Resource=Library.foliage_definition(biome,variation,"emanator")
			check(item.valid() and item.enabled_in_world and item.specialist_class.is_empty(),"Live design uses an existing emanator role without specialist abilities")
			check(item.organ_graph[0].id=="ground","Live design retains ground-connected anatomy")
			var connected: Dictionary={}
			for organ: Dictionary in item.organ_graph:
				check(organ.parent.is_empty() or connected.has(organ.parent),"Each live foliage organ has a connected parent")
				connected[organ.id]=true
			check(item.organ_anchors.receive.y<=0.1,"Emanator intake stays at ground contact")
	var maker: Node3D=load("res://scenes/plant_maker.tscn").instantiate()
	root.add_child(maker)
	maker.load_definition(Library.foliage_definition(1,0,"emanator"))
	check(maker.generic_circulation==0 and maker.specimens[0].role=="emanator","Maker reconstructs the live circulation anatomy")
	check(not maker.publish_button.disabled,"A focused emanator design can be enabled explicitly")
	var saved: Dictionary=preload("res://tools/plant_maker_store.gd").save_plant(maker,"Live foliage test",true,"res://artifacts/foliage-rollout/library_"+str(Time.get_ticks_usec()))
	check(saved.has("definition") and saved.definition.valid() and saved.definition.specialist_class.is_empty(),"Live foliage save retains role and no specialist class")
	maker.free()
	print("FOLIAGE ROLLOUT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
