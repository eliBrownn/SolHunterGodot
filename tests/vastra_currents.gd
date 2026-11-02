extends SceneTree
const Currents = preload("res://scripts/presentation/vastra_currents.gd")
var checks := 0
var failures := 0

class ProjectionHost extends Node3D:
	var solid_chunks := {}
	var solid_root := Node3D.new()
	var active_view := View3DSettings.new()
	var camera := Camera3D.new()
	var view_revision := 0
	func ground_height(_at: Vector2) -> float: return 0.0
	func chunk_visible(coord: Vector2i) -> bool:
		return preload("res://scripts/presentation/view_streaming.gd").visible(camera,Vector2(coord*16),16.0,1.0,-2.0)

class ProjectionState extends ExpeditionState:
	var packets: Array[Dictionary] = []
	func flora_transfers() -> Array[Dictionary]: return packets.duplicate(true)

class ProjectionWorld extends Node2D:
	var host: Node3D
	var terrain := WorldTerrain.new(17)
	var camera := Camera2D.new()

func render_range_contract() -> void:
	var host := ProjectionHost.new()
	host.active_view.vastra_distance = 24.0 # This fixture explicitly tests a 24-cell optical radius.
	root.add_child(host)
	host.add_child(host.solid_root)
	host.add_child(host.camera)
	host.camera.position = Vector3(0,12,14)
	host.camera.far = 160.0
	host.camera.look_at(Vector3(0,0,-12))
	host.active_view.render_distance = 128.0
	var world := ProjectionWorld.new()
	world.host = host
	world.add_child(world.camera)
	var renderer := Currents.new()
	renderer.world = world
	renderer.state = ExpeditionState.new(17)
	renderer.tuning = VastraSettings.new()
	renderer.tuning.current_region_limit = 1
	var flights: Array[Dictionary] = []
	for cell in [Vector2i(0,-2),Vector2i(0,-80)]:
		var coord := world.terrain.chunk_of(cell)
		var chunk := preload("res://scripts/presentation/solid_chunk.gd").new()
		chunk.cell_origin = coord*16
		chunk.tile_count = 256
		host.add_child(chunk)
		host.solid_chunks[coord] = chunk
		for at in [cell,cell+Vector2i.RIGHT]:
			chunk.register_living_source(at,"detail","grass",Vector3(at.x+0.5,0.2,at.y+0.5))
		var source := {"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":"plant"}
		var target := {"id":FloraCatalog.id_for(cell+Vector2i.RIGHT),"cell":[cell.x+1,cell.y],"kind":"plant"}
		for index in range(20 if cell.y == -2 else 1):
			flights.append({"id":flights.size()+1,"source_node":source,"target_node":target,"distance":1.0})
	var before: Dictionary = renderer.state.snapshot()
	renderer.update_render_bounds()
	check(not renderer.active_bounds().has_point(Vector2i(0,-80)) and renderer.stream_extent() == 24,"Vastra coverage is capped near the player independently of the terrain horizon")
	var anchors: Array = renderer.collect_living_anchors()
	check(not anchors.is_empty() and not anchors.any(func(anchor: Vector4)->bool: return anchor.z < -70.0),"Nearby anchors remain while distant published sources do not enter the optical working set")
	var admitted: Array = renderer.distribute_visible_flights(flights)
	check(admitted.size() == 20 and not admitted.any(func(flight: Dictionary)->bool: return flight.source_node.cell[1] == -80),"Distant transfers remain simulated without consuming the nearby render budget")
	var expired: Dictionary = flights[0].duplicate(true)
	expired.merge({"sent":-20,"arrival":-19,"release_ticks":2,"pending":false}) # Optical input only, never a ledger packet.
	var expired_list: Array[Dictionary] = [expired]
	check(renderer.distribute_visible_flights(expired_list).is_empty(),"Finished invisible trains do not consume visible transfer slots")
	expired.pending = true
	check(renderer.distribute_visible_flights(expired_list).size()==1,"A delayed uncredited train retains its intake endpoint until real completion")
	host.camera.look_at(Vector3(0,0,60))
	check(not renderer.flight_in_view(flights.back()),"Render-frustum changes reject off-screen transfers without moving their endpoints")
	check(renderer.state.snapshot() == before,"Changing camera and visual allocation never changes energy or ecological state")
	var shared_a := {"id":1001,"amount":30.0,"root":false,"source_node":{"cell":[0,0]},"target_node":{"cell":[4,0]}}
	var shared_b := {"id":1002,"amount":70.0,"root":false,"source_node":{"cell":[1,0]},"target_node":{"cell":[5,0]}}
	var route_a: PackedVector3Array = renderer.shared_transfer_points(Vector3(0,0.1,0),Vector3(4,1,0),shared_a)
	var route_b: PackedVector3Array = renderer.shared_transfer_points(Vector3(1,0.1,0),Vector3(5,1,0),shared_b)
	check(route_a.slice(7,10)==route_b.slice(7,10),"Different real-source branches converge onto an identical shared corridor after rounded junctions")
	check(route_a[0]==Vector3(0,0.1,0) and route_a[-1]==Vector3(4,1,0),"Shared routing retains exact external endpoints")
	var angular := PackedVector3Array([Vector3(0,1,0),Vector3(2,1,0),Vector3(2,1,2),Vector3(4,1,2)])
	var curved: PackedVector3Array = renderer.smooth_stream_path(angular)
	check(curved.size()>angular.size() and curved.size()<=64 and curved[0]==angular[0] and curved[-1]==angular[-1],"Cubic vector paths preserve exact ports within the shared GPU path limit")
	var corner := curved.find(angular[1])
	check(corner>0 and (curved[corner]-curved[corner-1]).angle_to(curved[corner+1]-curved[corner])<0.9,"Cubic tangents soften a right-angle turn instead of retaining a rigid corner")
	for junction_record: Dictionary in renderer.shared_junctions.values():
		check(junction_record.incoming==100.0 and junction_record.outgoing==100.0 and junction_record.packets.size()==2,"Merging and splitting preserve the sum of distinct packet amounts")
	renderer.shared_transfer_points(Vector3.ZERO,Vector3(4,1,0),shared_a)
	check(renderer.shared_junctions.values()[0].incoming==100.0,"Rebuilding a packet cannot duplicate junction energy")
	var tree_asset := {"kind":"tree","organs":{"reservoir_ring":{"position":Vector3(0,1,0)},"leaf_0":{"position":Vector3(1,1,0)}}}
	check(renderer.directional_surface(tree_asset,"receive",Vector3(1,1,0))=="reservoir_ring","Tree intake selects its integrated ring even when a leaf is closer")
	tree_asset.organs.reservoir_ring["surface_radius"] = 0.2
	tree_asset.organs.reservoir_ring["axis"] = Vector3.UP
	check(renderer.external_port(tree_asset,"reservoir_ring",Vector3(3,2,0),Vector3.ZERO).is_equal_approx(Vector3(0.2,1,0)),"The arrival endpoint lies on the collar's facing surface, not inside the trunk")
	tree_asset.organs["branch_socket"]={"position":Vector3(5,1,0)}
	tree_asset.organs["leaf_1"]={"position":Vector3(-2,2,0)}
	tree_asset.organs["leaf_2"]={"position":Vector3(0,3,2)}
	for leaf: String in ["leaf_0","leaf_1","leaf_2"]:
		check(renderer.directional_surface(tree_asset,"release",tree_asset.organs[leaf].position)==leaf,"Every leaf can be selected as the nearest onward outlet")
	check(renderer.directional_surface(tree_asset,"release",Vector3(5,1,0))=="leaf_0","A closer bare branch cannot replace a real leaf outlet")
	var anatomy := preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd").new()
	anatomy.organs=[{"id":"socket","kind":"Crown socket","position":Vector3.ZERO}]
	for leaf in range(3):
		anatomy.leaf_quads=[{"points":[Vector3(leaf,1,0),Vector3(leaf,2,0)]}]
		anatomy.register_leaf_outlet(Vector3(leaf,0,0))
	check(anatomy.leaf_surfaces.size()==6,"Three accepted leaves sharing one socket retain three distinct connected outlets")
	var leaf_ids := {}
	for organ: Dictionary in anatomy.leaf_surfaces: leaf_ids[organ.id]=true
	check(leaf_ids.size()==6,"Leaf and petiole identities remain unique across a shared socket")
	check(renderer.state.snapshot()==before,"Shared junction accounting remains a read-only transport projection")
	var high_path := PackedVector3Array([Vector3(180,210,-160),Vector3(220,260,-200)])
	var path_bounds: AABB = preload("res://scripts/presentation/vastra_filament_renderer.gd").bounds_for_path(high_path,3.0)
	check(path_bounds.has_point(high_path[0]) and path_bounds.has_point(high_path[1]),"Filament culling follows the real distant/elevated path rather than a fixed origin box")
	# Synthetic optical fixture only: exercise the real particle-node upload.
	# No packet is inserted into the simulation ledger.
	renderer.material.shader = load("res://shaders/vastra_current.gdshader")
	renderer.build_optical_noise()
	renderer.tuning.particle_filaments = VastraParticleSettings.new()
	renderer.network_edges = [{"flight":{"id":999,"sent":0,"arrival":20},"points":high_path}]
	var filaments := preload("res://scripts/presentation/vastra_filament_renderer.gd").new()
	renderer.add_child(filaments)
	filaments.sync(renderer)
	check(filaments.layers.is_empty(),"Distant paths cannot allocate production particle layers")
	var near_path := PackedVector3Array([Vector3(1,210,-2),Vector3(3,260,-4)])
	renderer.network_edges[0].points = near_path
	filaments.sync(renderer)
	check(filaments.layers.size() == 1,"Nearby elevated paths retain production filament rendering")
	if not filaments.layers.is_empty():
		var actual_bounds: AABB = filaments.layers.values()[0].node.visibility_aabb
		check(actual_bounds.has_point(near_path[0]) and actual_bounds.has_point(near_path[1]),"Production particle culling encloses nearby elevated endpoints")
		renderer.network_edges[0].flight["release_ticks"] = 8
		filaments.sync(renderer)
		check(filaments.layers.values()[0].motion.get_shader_parameter("release_seconds")==6.0,"Particle departures use the saved six-second physical release window")
		check(filaments.layers.values()[0].motion.get_shader_parameter("head_count")==renderer.tuning.particle_filaments.heads,"All optical heads distribute across the real release window")
		check(filaments.layers.values()[0].motion.get_shader_parameter("filament_length")==renderer.tuning.particle_filaments.filament_length,"Intake clipping keeps each strip alive until its own tail crosses")
		check(filaments.layers.values()[0].draw.get_shader_parameter("effect_range") == 24.0 and filaments.layers.values()[0].draw.get_shader_parameter("effect_fade") == 6.0,"Live filament optics fade over the outer six cells of the 24-cell radius")
	for generation in range(40):
		renderer.network_edges[0].flight.id = 10000 + generation
		filaments.sync(renderer)
		check(filaments.layers.size() <= renderer.tuning.particle_filaments.transfer_limit * 2 and filaments.get_child_count() <= renderer.tuning.particle_filaments.transfer_limit * 2,"Packet churn bounds active, fading and queued-for-deletion particle nodes")
	for child in [renderer.batch,renderer.wisp_batch,renderer.particle_batch,renderer.previous_batch,renderer.previous_wisps,renderer.heatmap_batch]: child.free()
	renderer.free()
	world.free()
	host.free()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func staged_transfer_contract() -> void:
	var host := ProjectionHost.new()
	root.add_child(host)
	host.add_child(host.solid_root)
	host.add_child(host.camera)
	host.camera.position = Vector3(0,12,14)
	host.camera.look_at(Vector3(0,0,-12))
	var world := ProjectionWorld.new()
	world.host = host
	world.add_child(world.camera)
	var renderer := Currents.new()
	renderer.world = world
	renderer.state = ProjectionState.new(17)
	renderer.tuning = VastraSettings.new()
	var chunk := preload("res://scripts/presentation/solid_chunk.gd").new()
	chunk.cell_origin = Vector2i(0,-16)
	chunk.tile_count = 256
	host.add_child(chunk)
	host.solid_chunks[Vector2i(0,-1)] = chunk
	for cell in [Vector2i(0,-2),Vector2i(1,-2)]:
		chunk.register_living_source(cell,"detail","grass",Vector3(cell.x+0.5,0.2,cell.y+0.5))
	for index in range(12):
		renderer.state.packets.append({"id":index+1,"source":"0:-2","target":"1:-2","source_node":{"id":"0:-2","cell":[0,-2],"kind":"plant"},"target_node":{"id":"1:-2","cell":[1,-2],"kind":"plant"},"distance":1.0,"root":false,"amount":10.0,"sent":0,"arrival":3,"pending":true})
	renderer.update_render_bounds()
	var anchors := renderer.collect_living_anchors()
	var scans: int = renderer.anchor_scan_builds
	check(renderer.collect_living_anchors() == anchors and renderer.anchor_scan_builds == scans, "Stable published source membership reuses the anchor scan")
	chunk.register_living_source(Vector2i(0,-2),"detail","grass",Vector3(0.5,0.3,-1.5),Vector3.INF,true,1)
	renderer.collect_living_anchors()
	check(renderer.anchor_scan_builds == scans+1, "Same-size source replacement invalidates anchor preparation")
	var previous_data: RefCounted = chunk.preparation
	var replacement := preload("res://scripts/presentation/chunk_build_data.gd").new()
	replacement.living_sources = previous_data.living_sources
	replacement.living_regions = previous_data.living_regions
	replacement.living_source_revision = previous_data.living_source_revision
	replacement.cell_origin = previous_data.cell_origin
	replacement.tile_count = previous_data.tile_count
	chunk.preparation = replacement
	renderer.collect_living_anchors()
	check(renderer.anchor_scan_builds == scans+2, "Prepared-data replacement invalidates even when revision and population size match")

	var route := PackedVector3Array([Vector3(0,0.1,-2),Vector3(2,0.2,-3),Vector3(4,0.4,-2)])
	for root_flow in [false,true]:
		for limit in [16,32,64]:
			var original: PackedVector3Array = renderer.build_smooth_stream_path(route,root_flow,limit)
			var cached: PackedVector3Array = renderer.smooth_stream_path(route,root_flow,limit)
			check(cached == original, "Memoized smoothing retains exact original samples and endpoints")
			var builds: int = renderer.smooth_curve_builds
			cached[1] = Vector3(900,900,900)
			check(renderer.smooth_stream_path(route,root_flow,limit) == original and renderer.smooth_curve_builds == builds, "Repeated smoothing reuses derived geometry and isolates caller mutation")
	var builds: int = renderer.smooth_curve_builds
	renderer.tuning.current_ground_clearance += 0.02
	renderer.smooth_stream_path(route)
	check(renderer.smooth_curve_builds == builds+1, "Direct clearance tuning invalidates smoothed geometry")
	world.terrain = WorldTerrain.new(19)
	renderer.smooth_stream_path(route)
	check(renderer.smooth_curve_builds == builds+2, "Terrain replacement invalidates smoothed paths")
	for index in range(270):
		var changed := route.duplicate()
		changed[1].x += index*0.01
		renderer.smooth_stream_path(changed)
	check(renderer.smooth_curve_cache.size() <= 256, "Retained smoothed geometry stays bounded")
	var before := renderer.state.snapshot()
	renderer.build_transfer_network(null,false)
	var expected: Array = renderer.network_edges.duplicate(true)
	var junctions: Dictionary = renderer.shared_junctions.duplicate(true)
	var smoothing_before: int = renderer.smooth_curve_builds
	check(expected.size() == 12, "The staged fixture contains actual visible prepared packet paths")
	renderer.tuning.current_paths_per_frame = 1
	renderer.begin_transfer_network(null)
	renderer.pump_transfer_network()
	check(renderer.last_transfer_paths == 1 and not renderer.transfer_job.is_empty(), "One frame services only the configured packet-path allowance")
	check(renderer.network_edges == expected, "Partial preparation retains the previous complete visible network")
	for frame in range(24):
		renderer.pump_transfer_network()
		check(renderer.last_transfer_paths <= 1, "Every preparation frame respects the path-count cap")
	check(renderer.transfer_job.is_empty() and renderer.network_edges == expected and renderer.shared_junctions == junctions, "Staged publication exactly matches immediate paths, endpoints and junction accounting")
	check(renderer.smooth_curve_builds == smoothing_before, "Unchanged network replacement reuses all retained smoothed paths")
	renderer.begin_transfer_network(null)
	renderer.pump_transfer_network()
	renderer.mark_dirty()
	check(renderer.transfer_job.is_empty() and renderer.network_edges == expected, "Invalidated work cannot publish a partial or stale network")
	check(renderer.state.snapshot() == before, "Staging and invalidation never alter the authoritative ledger")
	renderer.begin_transfer_network(null)
	renderer.pump_transfer_network()
	renderer.on_state(ProjectionState.new(19))
	check(renderer.transfer_job.is_empty() and renderer.network_edges.is_empty(), "State replacement discards queued and visible paths from the previous expedition")
	for child in [renderer.batch,renderer.wisp_batch,renderer.particle_batch,renderer.previous_batch,renderer.previous_wisps,renderer.heatmap_batch]: child.free()
	renderer.free()
	world.free()
	host.free()

func run() -> void:
	staged_transfer_contract()
	if OS.get_cmdline_user_args().has("--staging-only"):
		print("VASTRA STAGING: %d checks, %d failures." % [checks, failures])
		quit(0 if failures == 0 else 1)
		return
	render_range_contract()
	var sparse := ExpeditionState.new(17)
	for cell in [Vector2i(-14, 0), Vector2i(0, -14), Vector2i(1, 2), Vector2i(14, 0), Vector2i(15, 0)]:
		sparse.set_environment(cell, {"overload": -20})
	var dense := ExpeditionState.restore(sparse.snapshot(), 17)
	for index in range(220):
		dense.set_environment(Vector2i(100 + index, 100), {"overload": 10})
	check(sparse.vastra_changes_near(Vector2i.ZERO, 14) == dense.vastra_changes_near(Vector2i.ZERO, 14), "Sparse and dense lookup preserve identical local cells and row order")
	check(sparse.vastra_changes_near(Vector2i.ZERO, 14).size() == 4, "The radius includes boundary cells and excludes outside cells")
	check(ExpeditionState.new(17).vastra_changes_near(Vector2i.ZERO, 14).is_empty(), "An untouched world has no changed current sites")
	var scene: Node3D = load("res://scenes/world_3d.tscn").instantiate()
	scene.vastra_settings = load("res://resources/vastra_settings.tres").duplicate(true)
	scene.vastra_settings.currents_enabled = true
	scene.vastra_settings.current_limit = 24
	scene.vastra_settings.current_region_limit = 4
	# The optional mote layer is explicitly enabled only for transport fixtures.
	scene.vastra_settings.current_particle_limit = 64
	# Explicitly exercise the optional lighting while production defaults stay off.
	scene.vastra_settings.current_light_limit = 6
	root.add_child(scene)
	var world: Node2D = scene.world
	world.smoke_mode = true
	world.new_expedition(17)
	var currents: Node3D
	for child in scene.get_children():
		if child.get_script() == Currents:
			currents = child
	currents.study_mode = true
	currents.mark_dirty()
	currents.set_process(false)
	currents._process(0.6)
	var buried_start := Vector3(5.5, -1.0, 10.5)
	var buried_finish := Vector3(13.5, -1.0, 10.5)
	var surface_path: PackedVector3Array = currents.transfer_points(buried_start,buried_finish,73,false,true)
	check(surface_path.size() > 9 and surface_path.size() <= 41, "Root spans sample terrain densely within the bounded path budget")
	for point in surface_path:
		check(is_equal_approx(point.y,scene.ground_height(Vector2(point.x,point.z))+currents.tuning.current_ground_clearance), "External root span, including emergence and arrival, follows terrain")
	check(currents.transfer_points(buried_start,buried_finish,73,false,true) == surface_path, "Cached root spans preserve exact terrain projection")
	var sideways := 0.0
	for point in surface_path: sideways = maxf(sideways,absf(point.z-buried_start.z))
	check(sideways > 0.05, "Ground strands bend away from straight grid lines")
	var aerial_path: PackedVector3Array = currents.transfer_points(buried_start,buried_finish,73,false)
	check(aerial_path[0] == buried_start and aerial_path[-1] == buried_finish, "Root-mode caching cannot change non-root endpoint attachments")
	check(not scene.environment.glow_enabled, "The game environment keeps post-processing glow disabled")
	check(currents.glow_lights.size() == currents.MAX_GLOW_LIGHTS, "Vastra scenery lights use a fixed bounded pool")
	var light_snapshot: Dictionary = world.persistent_state.snapshot()
	var saved_count: int = currents.particle_batch.multimesh.visible_instance_count
	currents.particle_batch.visible = true
	currents.particle_batch.multimesh.visible_instance_count = 1
	currents.particle_batch.multimesh.set_instance_transform(0, Transform3D(Basis.IDENTITY, Vector3(0, 1, 0)))
	currents.particle_batch.multimesh.set_instance_color(0, Color(0.2, 0.6, 0.9, 0.5))
	currents.material.set_shader_parameter("layer_visibility", 1.0)
	currents.material.set_shader_parameter("sol_count", 0)
	currents.update_glow_lights()
	check(currents.glow_lights[0].visible and currents.glow_lights[0].light_energy > 0 and not currents.glow_lights[0].shadow_enabled, "A visible mote casts real local light without shadow-map cost")
	currents.material.set_shader_parameter("layer_visibility", 0.0)
	currents.update_glow_lights()
	check(not currents.glow_lights[0].visible, "An invisible transition does not leave scenery lit")
	currents.material.set_shader_parameter("layer_visibility", 1.0)
	scene.vastra_settings.current_light_limit = 0
	currents.update_glow_lights()
	check(currents.glow_lights.all(func(light: OmniLight3D) -> bool: return not light.visible), "Zero light budget clears every pooled light")
	scene.vastra_settings.current_light_limit = 6
	currents.particle_batch.multimesh.visible_instance_count = saved_count
	currents.last_particle_clock = -INF
	currents.sync_wisps()
	check(world.persistent_state.snapshot() == light_snapshot, "Vastra lighting never changes saved ecology or expedition state")
	check(not currents.heatmap_batch.visible and currents.heatmap_batch.mesh == null and currents.network_nodes.size() <= scene.vastra_settings.current_limit and currents.batch.mesh.get_surface_count() == 1, "Connected currents share a single bounded geometry batch")
	check(is_equal_approx(float(currents.material.get_shader_parameter("distortion")), scene.vastra_settings.current_distortion), "Refraction settings reach the live shader without a player-radius uniform")
	check(currents.material.get_shader_parameter("wind_velocity") == scene.vastra_settings.current_wind_velocity and is_equal_approx(float(currents.material.get_shader_parameter("pulse_strength")), scene.vastra_settings.current_pulse_strength), "Airflow and pulse settings reach the live shader")
	check(is_equal_approx(currents.reach_at_height(scene.vastra_settings.current_range_height) / currents.reach_at_height(0.0), 5.0), "The tallest flow tier reaches about five times farther than the ground tier")
	var small_count := 0
	var large_count := 0
	for edge: Dictionary in currents.network_edges:
		var physical_length := 0.0
		for i in range(1, edge.points.size()): physical_length += edge.points[i].distance_to(edge.points[i - 1])
		check(physical_length <= edge.range_limit + 0.001, "Actual curved strand length stays within its height-dependent reach")
		var destination: Dictionary = edge.destination_asset
		var expected_key: Vector2i = edge.b if edge.end_phase > edge.start_phase else edge.a
		check(not destination.is_empty() and destination.id == currents.node_assets[expected_key].id, "The future charge destination is the real asset at the animated arrival end")
		if edge.kind == "small":
			small_count += 1
			check(currents.is_grass_source(edge.points[0]) and currents.is_grass_source(edge.points[-1]) and edge.points[0].distance_to(edge.points[-1]) <= scene.vastra_settings.current_ground_reach + 0.001, "Small strands connect actual nearby grass clumps")
			for i in range(1, edge.points.size() - 1):
				var point: Vector3 = edge.points[i]
				check(absf(point.y - world.host.ground_height(Vector2(point.x, point.z)) - scene.vastra_settings.current_ground_clearance) <= 0.021, "Common small strands hug the generated terrain with almost no arc")
		elif edge.kind == "large":
			large_count += 1
			check(currents.source_assets[edge.points[0]].kind == "tree" and currents.source_assets[edge.points[-1]].kind == "tree" and edge.points[0] == currents.source_assets[edge.points[0]].high_anchor and edge.points[-1] == currents.source_assets[edge.points[-1]].high_anchor, "Large arcs join real treetops rather than arbitrary air points")
	check(small_count > large_count and large_count <= scene.vastra_settings.current_canopy_links, "Grass strands are more common than globally bounded canopy arcs")
	var charge_hooks: Array[Dictionary] = currents.charge_destinations()
	check(not charge_hooks.is_empty() and not charge_hooks[0].has("charge"), "Charge destinations expose future roles without inventing charge quantities")
	var source_fixture: Dictionary = currents.source_assets.duplicate(true)
	var anchor_fixture: Array[Vector4] = currents.living_anchors.duplicate()
	currents.source_assets.clear()
	currents.living_anchors.clear()
	for center_x in [0.0, 10.0]:
		var tree_ground: float = world.host.ground_height(Vector2(center_x, 0))
		var tree_point := Vector3(center_x, tree_ground + 0.9, 0)
		var crown := Vector3(center_x, tree_ground + 3.0, 0)
		var tree_asset := {"id": "fixture_tree_" + str(center_x), "kind": "tree", "anchor": tree_point, "high_anchor": crown, "cell": Vector2i(int(center_x), 0)}
		currents.source_assets[tree_point] = tree_asset
		currents.source_assets[crown] = tree_asset
		currents.living_anchors.append(Vector4(tree_point.x, tree_point.y, tree_point.z, 0.9))
		for offset in [0.1, 0.6, 1.1]:
			var point := Vector3(center_x + offset, world.host.ground_height(Vector2(center_x + offset, 0)) + 0.08, 0)
			currents.source_assets[point] = {"id": "fixture_grass_" + str(point.x), "kind": "detail", "anchor": point, "high_anchor": point, "cell": Vector2i(floori(point.x), 0)}
			currents.living_anchors.append(Vector4(point.x, point.y, point.z, 0.55))
	currents.build_network(null)
	var fixture_canopies := 0
	for edge: Dictionary in currents.network_edges:
		if edge.kind != "large": continue
		fixture_canopies += 1
		check(edge.points[4].y > edge.points[0].lerp(edge.points[-1], 0.5).y + 0.5 and edge.points[0].distance_to(edge.points[-1]) > 7.5, "Rare large currents arch above real crown endpoints and travel farther than grass currents")
	check(fixture_canopies == 1, "Two eligible nearby tree crowns admit one rare canopy connection")
	currents.living_anchors.assign(anchor_fixture)
	currents.source_assets = source_fixture
	currents.build_network(null)
	var anchors: Array[Vector4] = currents.living_anchors.duplicate()
	var terminates_at_asset := true
	var endpoint_count := 0
	for group: Dictionary in currents.living_groups:
		var key: Vector2i = group.id * 16
		if not currents.network_nodes.has(key): continue
		endpoint_count += 1
		var endpoint: Vector3 = currents.network_nodes[key]
		var matched := false
		for anchor in anchors:
			matched = matched or endpoint.is_equal_approx(Vector3(anchor.x, anchor.y, anchor.z))
		terminates_at_asset = terminates_at_asset and matched and endpoint.is_equal_approx(group.focus)
	check(terminates_at_asset and endpoint_count > 0, "Each local connection terminates at a specific published living asset")
	for cell in [Vector2i(-21, 8), Vector2i.ZERO, Vector2i(47, -34)]:
		var reading: Dictionary = currents.sample_for(cell)
		var full: Dictionary = world.terrain.sample(cell)
		check(reading.concentration == full.concentration and reading.affinity == full.affinity, "Lightweight optical channels exactly match the full generator")
	currents.finish_transition()
	currents.refresh()
	check(currents.previous_batch.mesh != null and is_zero_approx(float(currents.material.get_shader_parameter("layer_visibility"))), "Replacing geometry retains the previous view while the new view fades in")
	currents.advance_transition(0.15)
	var new_weight := float(currents.material.get_shader_parameter("layer_visibility"))
	var previous_material: ShaderMaterial = currents.previous_batch.material_override
	check(new_weight > 0 and new_weight < 1 and is_equal_approx(new_weight + float(previous_material.get_shader_parameter("layer_visibility")), 1.0), "Current admission blends complementary weights instead of popping between meshes")
	currents.advance_transition(0.4)
	check(currents.previous_batch.mesh == null and is_equal_approx(float(currents.material.get_shader_parameter("layer_visibility")), 1.0), "Completed transitions release the bounded previous geometry")
	check(is_equal_approx(float(currents.material.get_shader_parameter("strand_shake")), scene.vastra_settings.current_strand_shake), "Strand ripple tuning reaches the shader")
	currents.material.set_shader_parameter("clock_seconds", 10.0)
	currents.sync_wisps()
	var mote_count: int = currents.particle_batch.multimesh.visible_instance_count
	check(currents.particle_batch.visible and mote_count > 0 and mote_count <= scene.vastra_settings.current_particle_limit and currents.particle_batch.multimesh.instance_count == Currents.MAX_PARTICLES, "Peak motes use one fixed-capacity batch with a bounded visible count")
	var mote: Transform3D = currents.particle_batch.multimesh.get_instance_transform(0)
	currents.sync_wisps()
	check(currents.particle_batch.multimesh.get_instance_transform(0) == mote, "An unchanged optical clock cannot advance particles")
	scene.vastra_settings.current_particle_limit = 0
	currents.sync_wisps()
	check(not currents.particle_batch.visible and currents.particle_batch.multimesh.visible_instance_count == 0, "A zero particle budget immediately hides all motes")
	scene.vastra_settings.current_particle_limit = 64
	currents.sync_wisps()
	check(currents.particle_batch.visible and currents.particle_batch.multimesh.visible_instance_count == mote_count, "Re-enabling motes restores the same paused-clock positions")
	var before: Dictionary = world.persistent_state.snapshot()
	var refreshed: int = currents.refresh_count
	var builds: int = currents.sample_builds
	for frame in range(180):
		currents._process(1.0 / 60.0)
	check(currents.refresh_count == refreshed and currents.sample_builds == builds, "Stationary unchanged frames do not rebuild readings or terrain samples")
	check(world.persistent_state.snapshot() == before, "Rendering and its cache never mutate persistent state")
	var target: Vector2i = world.cell
	world.persistent_state.set_environment(target, {"overload": 60})
	currents._process(0.6)
	check(currents.sites.has(target) and currents.refresh_count > refreshed, "An off-grid overload change invalidates local web readings")
	var cached: int = currents.sample_builds
	world.persistent_state.set_environment(target, {"overload": -40})
	currents._process(0.6)
	check(currents.sample_builds == cached, "Signed environmental changes reuse immutable generated terrain")
	var junctions := {}
	var connected := {}
	for edge: Dictionary in currents.network_edges:
		for endpoint: String in ["a", "b"]:
			var key: Vector2i = edge[endpoint]
			var point: Vector3 = edge.points[0] if endpoint == "a" else edge.points[-1]
			check(not junctions.has(key) or junctions[key].is_equal_approx(point), "Branches share identical world-space endpoints")
			junctions[key] = point
		connected[edge.a] = true
		connected[edge.b] = true
	check(connected.size() == currents.network_nodes.size(), "Every selected junction participates in the web")
	var degrees := {}
	var finite_space := true
	for edge: Dictionary in currents.network_edges:
		degrees[edge.a] = int(degrees.get(edge.a, 0)) + 1
		degrees[edge.b] = int(degrees.get(edge.b, 0)) + 1
		for point: Vector3 in edge.points:
			finite_space = finite_space and point.is_finite()
	check(degrees.values().max() >= 3, "The web includes branching junctions")
	var forests := {}
	for key: Vector2i in currents.network_nodes:
		forests[key] = key
	var local_cycles := false
	var landscape_bridges := 0
	for edge: Dictionary in currents.network_edges:
		if edge.bridge:
			landscape_bridges += 1
			continue
		var a: Vector2i = edge.a
		var b: Vector2i = edge.b
		while forests[a] != a:
			a = forests[a]
		while forests[b] != b:
			b = forests[b]
		local_cycles = local_cycles or a == b
		forests[a] = b
	check(not local_cycles, "Local tributaries remain open instead of enclosing individual groves")
	check(landscape_bridges <= scene.vastra_settings.current_region_limit * (scene.vastra_settings.current_web_links + 1) + scene.vastra_settings.current_canopy_links, "Landscape links remain sparse instead of forcing distant ground patches to connect")
	check(currents.network_edges.size() <= currents.network_nodes.size() + scene.vastra_settings.current_region_limit * scene.vastra_settings.current_web_links, "Extra landscape connections remain bounded by the region budget")
	check(finite_space, "Spatial paths remain finite across terrain relief")
	check(currents.secondary_links == large_count, "Secondary threads accompany only admitted canopy arcs")
	check(currents.flow_distances.size() == currents.network_nodes.size(), "Every main junction has a route to the shared concentration focus")
	var converges := true
	for edge: Dictionary in currents.network_edges:
		if edge.bridge:
			check(absf(edge.end_phase - edge.start_phase) >= edge.points[0].distance_to(edge.points[-1]) * 0.99, "Long bridges retain a metric travel phase even between similarly scored groves")
		else:
			converges = converges and edge.flow_direction == signf(float(currents.flow_distances[edge.a]) - float(currents.flow_distances[edge.b]))
	check(converges, "Every link carries a consistent inward flow phase")

	var reached := {currents.network_edges[0].a: true}
	for iteration in range(currents.network_nodes.size()):
		for edge: Dictionary in currents.network_edges:
			if reached.has(edge.a) or reached.has(edge.b):
				reached[edge.a] = true
				reached[edge.b] = true
	check(reached.size() >= 2, "Each displayed flow joins real endpoints; disconnected local grass flows are allowed")
	var stable_nodes: Dictionary = currents.network_nodes.duplicate(true)
	var stable_phases: Dictionary = currents.flow_distances.duplicate(true)
	var stable_colors: PackedColorArray = currents.batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var stable_origin: Vector2i = currents.batch_origin
	world.cell += Vector2i(18, 0)
	currents.refresh()
	check(currents.network_nodes == stable_nodes and currents.flow_distances == stable_phases, "Crossing a geographic boundary cannot move retained regions or reroute their phases")
	check(currents.batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] == stable_colors, "Explorer travel cannot change a fixed world's optical density")
	world.cell -= Vector2i(18, 0)
	currents.refresh()
	check(currents.batch_origin == stable_origin, "Floating origin follows geographic cells reversibly")
	check(currents.wisp_batch.mesh != currents.batch.mesh and currents.wisp_material.get_shader_parameter("wisp_layer") == true, "Sparse wisps and broad density use separate geometry and materials")
	var fixed_key: Vector2i = currents.network_edges[0].a
	var fixed_neighbor: Vector2i = currents.network_edges[0].b
	var fixed_points: PackedVector3Array = currents.edge_points(fixed_key, fixed_neighbor)
	world.cell += Vector2i.RIGHT
	currents._process(0.6)
	check(fixed_points == currents.edge_points(fixed_key, fixed_neighbor), "Walking changes local selection without moving existing paths")
	world.cell -= Vector2i.RIGHT
	currents._process(0.6)
	check(currents.batch.custom_aabb.has_point(currents.network_vertices[0] + Vector3.UP * 0.025), "Culling bounds include animated web geometry")
	check(currents.batch.mesh.get_aabb().size.y > scene.vastra_settings.current_hover_height, "Shared refractive density occupies a volume above terrain")
	var clear_vertices := true
	for local_vertex: Vector3 in currents.network_vertices:
		var vertex := local_vertex + Vector3(currents.batch_origin.x, 0, currents.batch_origin.y)
		clear_vertices = clear_vertices and vertex.y >= world.host.ground_height(Vector2(vertex.x, vertex.z)) + scene.vastra_settings.current_ground_clearance - 0.001
	check(clear_vertices, "Every carrier bank clears terrain rather than slicing into slopes")
	check(currents.network_vertices.size() <= scene.vastra_settings.current_region_limit * 117 + 81, "Density geometry has a bounded per-region and bridge budget")
	var actual_anchors: Array[Vector4] = currents.living_anchors.duplicate()
	currents.living_anchors.assign([Vector4(-3, 1, 0, 1), Vector4(-2, 1, 0, 1), Vector4(4, 1, 0, 1)])
	var grouped: Array[Dictionary] = currents.group_living_sources()
	check(grouped.size() == 2, "Nearby living things share a region and separated groups remain distinct")
	var member_counts: Array[int] = []
	for group in grouped:
		member_counts.append(int(group.members))
	check(member_counts.has(2) and member_counts.has(1), "Regional density groups preserve their actual source membership")
	currents.living_anchors.assign([Vector4(-1, 1, 0, 1), Vector4(2, 1, 0, 1)])
	world.persistent_state.set_environment(Vector2i(-1, 0), {"concentration": 5})
	world.persistent_state.set_environment(Vector2i(2, 0), {"concentration": 95})
	currents.build_network(null)
	check(is_equal_approx(currents.flow_focus.x, 2.0), "Overall flow selects the living region with higher saved concentration")
	var bridge_count := 0
	for edge: Dictionary in currents.network_edges:
		bridge_count += 1 if edge.bridge else 0
	check(bridge_count > 0, "Finer bridges connect the shared living regions")
	world.persistent_state.set_environment(Vector2i(-1, 0), {"concentration": 95})
	world.persistent_state.set_environment(Vector2i(2, 0), {"concentration": 5})
	currents.build_network(null)
	check(is_equal_approx(currents.flow_focus.x, -1.0), "Changing concentration moves the shared focus between living regions")
	# Selection may admit another geographic owner without changing retained content.
	var saved_regions: int = scene.vastra_settings.current_region_limit
	var saved_camera: Vector2 = world.camera.position
	scene.vastra_settings.current_region_limit = 2
	currents.living_anchors.assign([Vector4(1, 1, 1, 0.55), Vector4(2, 1, 1, 0.55), Vector4(20, 1, 1, 0.55), Vector4(21, 1, 1, 0.55), Vector4(80, 1, 1, 0.55), Vector4(81, 1, 1, 0.55)])
	world.camera.position = Vector2.ZERO
	currents.build_network(null)
	for edge: Dictionary in currents.network_edges:
		if edge.bridge:
			var midpoint: Vector3 = edge.points[4]
			var local_support: float = currents.field_strength(midpoint, currents.living_groups)
			check(currents.life_strength(midpoint) > local_support + 0.1, "A link remains visible between distant groves instead of fading into isolated halos")
			var saved_connection: float = scene.vastra_settings.current_connection_visibility
			scene.vastra_settings.current_connection_visibility = 0.0
			check(is_equal_approx(currents.life_strength(midpoint), local_support), "Zero connection visibility removes corridor support without changing living regions")
			scene.vastra_settings.current_connection_visibility = saved_connection
	var retained_key := Vector2i(20, 1) * 16
	var retained_point: Vector3 = currents.network_nodes[retained_key]
	var retained_phase: float = currents.flow_distances[retained_key]
	world.camera.position = Vector2(60, 0) * 32.0
	currents.build_network(null)
	check(currents.network_nodes.has(retained_key) and currents.network_nodes[retained_key] == retained_point and currents.flow_distances[retained_key] == retained_phase, "View selection changes preserve a retained region's exact placement and phase")
	check(currents.network_nodes.size() <= scene.vastra_settings.current_limit, "Changing visible geographic groups respects the global node budget")
	world.camera.position = saved_camera
	scene.vastra_settings.current_region_limit = saved_regions
	currents.living_anchors.clear()
	check(is_equal_approx(currents.life_strength(Vector3.ZERO), scene.vastra_settings.current_empty_visibility), "Absent life leaves only faint ambient visibility")
	currents.living_anchors.assign([Vector4(0, 1, 0, 1)])
	currents.living_groups = currents.group_living_sources()
	check(currents.life_strength(Vector3(0, 1, 0)) > currents.life_strength(Vector3(20, 1, 20)), "The field is stronger around life than in empty space")
	currents.living_anchors.assign(actual_anchors)
	currents.living_groups = currents.group_living_sources()
	before = world.persistent_state.snapshot()
	currents._process(0.6)
	check(world.persistent_state.snapshot() == before, "Concentration-directed refraction leaves simulated energy unchanged")
	var saved_speed: float = scene.vastra_settings.current_flow_speed
	scene.vastra_settings.current_flow_speed = 0.0
	var frozen: float = currents.optical_seconds
	world.persistent_state.advance_time(0.8)
	currents._process(0.6)
	check(currents.optical_seconds == frozen, "Zero flow speed freezes the optical clock even while exploration advances")
	scene.vastra_settings.current_flow_speed = saved_speed
	scene.vastra_settings.current_aberration = -1.0
	currents._process(0.6)
	check(not currents.batch.visible, "Invalid live optical settings suspend rendering")
	scene.vastra_settings.current_aberration = 0.35
	currents._process(0.6)
	check(currents.batch.visible, "Corrected optical settings restore rendering")
	var natural_vertex: Vector3 = currents.network_vertices[0] + Vector3(currents.batch_origin.x, 0, currents.batch_origin.y)
	var natural_cell := Vector2i(floori(natural_vertex.x), floori(natural_vertex.z))
	var natural_color: Color = scene.sightings.visual_settings.color_for(world.terrain.sample(natural_cell).affinity).srgb_to_linear()
	var natural_colors: PackedColorArray = currents.batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	check(Vector3(natural_colors[0].r, natural_colors[0].g, natural_colors[0].b).distance_to(Vector3(natural_color.r, natural_color.g, natural_color.b)) < 0.007, "Unimprinted Vastra optics use generated tile affinity")
	var affinity_fixture: Dictionary = world.persistent_state.snapshot()
	var first_world: Vector3 = currents.network_vertices[0] + Vector3(currents.batch_origin.x, 0, currents.batch_origin.y)
	var affinity_cell := Vector2i(floori(first_world.x), floori(first_world.z))
	affinity_fixture.affinity_tiles[AffinityImprint.key(affinity_cell)] = {"affinity": "water", "conditions": {}}
	var affinity_state := ExpeditionState.restore(affinity_fixture, 17)
	check(affinity_state != null, "Local-affinity optical fixture uses a valid saved state")
	world.replace_persistent_state(affinity_state)
	world.state_replaced.emit(affinity_state)
	currents._process(0.6)
	var vertex_colors: PackedColorArray = currents.batch.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var expected_primary: Color = scene.sightings.visual_settings.color_for("water").srgb_to_linear()
	check(Vector3(vertex_colors[0].r, vertex_colors[0].g, vertex_colors[0].b).distance_to(Vector3(expected_primary.r, expected_primary.g, expected_primary.b)) < 0.007, "The optical primary comes from the local tile affinity palette")


	# The first displayed frame may emit the ordinary startup viewport rebuild.
	currents._process(0.6)
	refreshed = currents.refresh_count
	world.persistent_state.set_environment(target + Vector2i(100, 100), {"overload": 30})
	currents._process(0.6)
	check(currents.refresh_count == refreshed, "Distant changes do not invalidate local current readings")
	var battle := TacticalBattle.new()
	battle.action_serial = 1
	battle.vastra_overloads[AffinityImprint.key(target + Vector2i.RIGHT)] = 70
	battle.tile_overloads[target + Vector2i.RIGHT] = 70
	var entry_clock: float = currents.optical_seconds
	var entry_seconds: float = world.persistent_state.activity_seconds()
	scene.battles.visual_seconds = 120.0
	scene.battles.session = battle
	currents._process(0.6)
	check(is_equal_approx(currents.optical_seconds, entry_clock), "Entering combat cannot add the accumulated battle clock to optical phase")
	world.persistent_state.advance_time(0.1)
	currents._process(0.1)
	check(is_equal_approx(currents.optical_seconds - entry_clock, 0.1 * saved_speed), "Combat advances optics exactly once through active expedition time")
	check(currents.sites.has(target + Vector2i.RIGHT), "Uncommitted combat environmental effects remain visible")
	scene.battles.session = null
	currents._process(0.6)
	world.persistent_state.advance_time(0.1)
	currents._process(0.1)
	check(is_equal_approx(currents.optical_seconds - entry_clock, (world.persistent_state.activity_seconds() - entry_seconds) * saved_speed), "Leaving combat continues flow without a catch-up freeze")
	var old: ExpeditionState = world.persistent_state
	world.new_expedition(18)
	currents._process(0.6)
	check(currents.state == world.persistent_state and not old.environment_changed.is_connected(currents.on_environment), "State replacement disconnects old invalidation callbacks")
	refreshed = currents.refresh_count
	old.set_environment(target, {"overload": 90})
	currents._process(0.6)
	check(currents.refresh_count == refreshed, "A replaced state's later changes cannot refresh the live view")
	var debug_before: Dictionary = world.persistent_state.snapshot()
	scene.vastra_settings.current_debug_view = 1
	currents._process(0.6)
	check(currents.heatmap_batch.visible and not currents.batch.visible and currents.heatmap_batch.mesh.get_surface_count() == 1, "Concentration heatmap replaces normal optics only when requested")
	check(currents.heatmap_material.get_shader_parameter("density_mode") == 1, "Actual concentration heatmap selection reaches its shader")
	scene.vastra_settings.current_debug_view = 2
	currents._process(0.6)
	check(currents.heatmap_material.get_shader_parameter("density_mode") == 2, "Revealed-field heatmap uses the same nature and Sol mask projection")
	check(world.persistent_state.snapshot() == debug_before, "Switching heatmaps never changes concentration or ecological state")
	scene.vastra_settings.current_debug_view = 0
	currents._process(0.6)
	check(not currents.heatmap_batch.visible and currents.batch.visible, "Normal wispy presentation returns after closing the heatmap")
	if not scene.sightings.members.is_empty():
		var sprite: Node3D = scene.sightings.members[0].sprite
		var original_position := sprite.position
		var original_visibility := sprite.visible
		var nature_before: Array[Vector4] = currents.collect_living_anchors()
		sprite.position = Vector3(currents.flow_focus.x - world.camera.position.x / 32.0, currents.flow_focus.y, currents.flow_focus.z - world.camera.position.y / 32.0)
		sprite.visible = true
		currents.update_sol_voids()
		check(currents.collect_living_anchors() == nature_before, "A Sol cannot create or increase a positive nature anchor")
		check(int(currents.material.get_shader_parameter("sol_count")) > 0 and int(currents.heatmap_material.get_shader_parameter("sol_count")) > 0, "Sol dissipation is connected to both optics and the revealed-field map")
		sprite.position = original_position
		sprite.visible = original_visibility
		currents.update_sol_voids()
	var original: Vector2i = world.cell
	for index in range(80):
		world.cell = original + Vector2i(index * 3, 0)
		currents._process(1.0 / 60.0)
	check(currents.samples.size() <= Currents.SAMPLE_CACHE_LIMIT and currents.sample_order.size() <= Currents.SAMPLE_CACHE_LIMIT, "Long travel keeps generated sample memory bounded")
	check(currents.junction_cache.size() <= 128 and currents.edge_cache.size() <= 256, "Long travel bounds immutable junction and path caches")
	check(currents.batch.custom_aabb.position.length() < 64.0 and currents.batch.custom_aabb.size.length() < 100.0, "Travel keeps GPU instance bounds local rather than accumulating world-coordinate offsets")
	world.cell = original
	currents._process(0.6)
	cached = currents.sample_builds
	world.rebuilt.emit()
	currents._process(0.6)
	check(currents.sample_builds > cached, "Rebuilding the same terrain instance invalidates cached geometry")
	var enabled_count: int = scene.vastra_settings.current_limit
	scene.vastra_settings.current_limit = 0
	currents._process(0.6)
	check(not currents.batch.visible and not currents.wisp_batch.visible and not currents.heatmap_batch.visible, "Zero budget hides every visual and diagnostic layer")
	check(currents.glow_lights.all(func(light: OmniLight3D) -> bool: return not light.visible), "Disabling Vastra also disables its scenery lights")
	scene.vastra_settings.current_limit = enabled_count
	currents._process(0.6)
	check(currents.batch.visible and currents.wisp_batch.visible, "Restoring the budget restores both visual layers")
	if OS.get_cmdline_user_args().has("--capture-glow"):
		DirAccess.make_dir_recursive_absolute("res://artifacts/vastra-optimization")
		for frame in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/vastra-optimization/rendered.png")
		# Close night comparison makes both HDR bloom and actual scenery lighting visible.
		scene.process_mode = Node.PROCESS_MODE_DISABLED
		scene.atmosphere_settings.cycle_enabled = false
		scene.atmosphere_settings.starting_phase = 0.0
		scene.apply_atmosphere_settings()
		world.hud.hide()
		currents.finish_transition()
		var best_clock := 0.0
		var best_count := -1
		for phase in range(24):
			currents.material.set_shader_parameter("clock_seconds", float(phase))
			currents.sync_wisps()
			if currents.particle_batch.multimesh.visible_instance_count > best_count:
				best_clock = float(phase)
				best_count = currents.particle_batch.multimesh.visible_instance_count
		currents.material.set_shader_parameter("clock_seconds", best_clock)
		currents.sync_wisps()
		if best_count > 0:
			var focus: Vector3 = currents.global_position + currents.particle_batch.multimesh.get_instance_transform(0).origin
			scene.camera.position = focus + Vector3(3.5, 2.0, 4.5)
			scene.camera.look_at(focus)
		DirAccess.make_dir_recursive_absolute("res://artifacts/vastra-glow")
		var selected_lights: Array = currents.glow_lights.filter(func(light: OmniLight3D) -> bool: return light.visible)
		for lighting in [true, false]:
			for light: OmniLight3D in currents.glow_lights:
				light.visible = lighting and selected_lights.has(light)
			for frame in range(4): await process_frame
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png("res://artifacts/vastra-glow/night-%s.png" % ("lit" if lighting else "emission-only"))
	scene.queue_free()
	await process_frame
	print("VASTRA CURRENTS: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
