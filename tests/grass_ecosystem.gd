extends SceneTree
const Library = preload("res://scripts/scenery/plant_library.gd")
const Grass = preload("res://scripts/scenery/meadow_art.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
var checks := 0
var failures := 0
class FlatTerrain extends WorldTerrain:
	func sample(_cell: Vector2i) -> Dictionary: return {"ground":0,"obstacle":0,"walkable":true}
	func flora_kind(_cell: Vector2i,_data: Dictionary) -> String: return "plant"
	func scenery_reserved(_cell: Vector2i) -> bool: return false
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
	var terrain := FlatTerrain.new(18)
	var settings := NatureSettings.new()
	settings.foliage_coverage=0.0 # This fixture isolates blade behavior; foliage has its own rollout journey.
	settings.meadow_enabled=true
	settings.meadow_divisions=2
	var cell := Vector2i(60,60)
	while FloraTraits.role(18,{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":"plant"})!="emanator": cell.x+=1
	var state := ExpeditionState.new(18)
	state.configure_flora(VastraSettings.new().plant_parameters())
	state.admit_flora([{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":"plant"}])
	var saved := state.snapshot()
	Library.refresh(["res://artifacts/nonexistent-grass-test-library.json"])
	# Weather arrives before the first visible blade is constructed.
	Library.set_weather(Vector2.RIGHT,12.5,0.6,Vector2(64,32),0.8)
	var chunk := Chunk.new()
	root.add_child(chunk)
	Library.add_cell(chunk,terrain,cell,terrain.sample(cell),settings)
	check(not chunk.batches.is_empty(),"Shared plant entry renders the built-in grass emanator")
	check(chunk.living_sources.size()==1 and chunk.living_sources[cell].flora_id==FloraCatalog.id_for(cell),"All blades resolve to the admitted canonical reserve")
	check(Grass.material.get_shader_parameter("wind_time")==12.5 and Grass.material.get_shader_parameter("world_origin")==Vector2(64,32),"Late-created grass inherits shared weather and floating origin")
	check(Grass.material.get_shader_parameter("wind_strength")>1.0,"Grass retains its rain response under the shared weather owner")
	chunk.finish()
	if "--capture-grass" in OS.get_cmdline_user_args():
		root.size=Vector2i(800,600)
		var camera := Camera3D.new()
		root.add_child(camera)
		camera.position=Vector3(cell.x+1.4,0.9,cell.y+1.8)
		camera.look_at(Vector3(cell.x+0.5,0.2,cell.y+0.5))
		var light := DirectionalLight3D.new()
		root.add_child(light)
		light.rotation_degrees=Vector3(-50,-30,0)
		var surroundings := WorldEnvironment.new()
		surroundings.environment=Environment.new()
		surroundings.environment.background_mode=Environment.BG_COLOR
		surroundings.environment.background_color=Color("52676b")
		surroundings.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
		surroundings.environment.ambient_light_color=Color.WHITE
		surroundings.environment.ambient_light_energy=1.0
		root.add_child(surroundings)
		for frame in range(3): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/grass-ecosystem.png")
		camera.free()
		light.free()
		surroundings.free()
	check(chunk.plant_instances.has(cell),"Grass enters the shared plant event animation groups")
	var group: Dictionary=chunk.plant_instances[cell].values()[0]
	var rest: Transform3D=group.mesh.get_instance_transform(group.indices[0])
	chunk.apply_plant_animations({cell:{"kind":"receiving","start":0.0,"duration":1.6}},0.7,1.0)
	check(not group.mesh.get_instance_transform(group.indices[0]).is_equal_approx(rest),"Existing receiving animation moves the grass blades")
	chunk.apply_plant_animations({},2.0,1.0)
	check(group.mesh.get_instance_transform(group.indices[0]).is_equal_approx(rest),"Grass restores exactly after the event")
	chunk.free()
	for density in [2,4]:
		settings.meadow_divisions=density
		var view := Chunk.new()
		Library.add_cell(view,terrain,cell,terrain.sample(cell),settings)
		check(view.living_sources.size()==1,"Changing blade density cannot multiply ecological owners")
		view.free()
	settings.meadow_enabled=false
	var hidden := Chunk.new()
	Library.add_cell(hidden,terrain,cell,terrain.sample(cell),settings)
	check(hidden.batches.is_empty() and hidden.living_sources.has(cell),"Disabled grass retains its functional transfer endpoint")
	hidden.free()
	check(state.snapshot()==saved,"Rendering, density, weather and animation never mutate the saved ecosystem")
	check(ExpeditionState.restore(saved,18)!=null,"Grass identity survives the existing save validation")
	# Continue the same canonical grass reserve through a real conserved send,
	# reload in flight and arrival, independent of starting-area tree artwork.
	var tree_cell := cell+Vector2i.RIGHT
	var tree := {"id":FloraCatalog.id_for(tree_cell),"cell":[tree_cell.x,tree_cell.y],"kind":"tree"}
	state.admit_flora([tree])
	var charged := state.snapshot()
	charged.flora.nodes[FloraCatalog.id_for(cell)].energy=100.0
	charged.flora.absorbed=100.0
	charged.flora.policy.refill=0.0
	state=ExpeditionState.restore(charged,18)
	state.set_flora_active([FloraCatalog.id_for(cell)])
	var resolver := func(_at: Vector2i,_reach: float) -> Array: return [tree]
	var environment := func(at: Vector2i) -> Dictionary: return state.environment_view(at,{"concentration":50,"overload":0})
	state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
	state.advance_flora(resolver,environment)
	var ledger := state.flora_view()
	check(ledger.flights.size()==1 and ledger.flights[0].source==FloraCatalog.id_for(cell),"Rendered grass's canonical reserve emits through the existing plant circulation")
	if not ledger.flights.is_empty():
		var arrival: int=ledger.flights[0].arrival
		state=ExpeditionState.restore(state.snapshot(),18)
		while state.activity_tick()<arrival:
			state.advance_time(ExpeditionContract.ACTIVITY_INTERVAL)
			state.advance_flora(resolver,environment)
		ledger=state.flora_view()
		check(ledger.nodes[tree.id].energy==100.0 and ledger.flights.is_empty(),"Grass packet survives reload and credits the receiving tree once")
		check(PlantVastra.valid(ledger,state.activity_tick()),"Grass and tree retain a valid conserved ecosystem ledger")
	Library.refresh(["res://resources/plants/library.json","user://authored_plants/library.json"])
	print("GRASS ECOSYSTEM: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
