extends Node3D
## Isolated production-ledger exercise. Presentation reads real flight IDs/cells.
## Fixture definitions and initial reserves are test data, never expedition data.
var state: ExpeditionState
var definitions: Array[Dictionary] = []
var endpoints: Dictionary = {}
var layers: Dictionary = {}
var labels: Dictionary = {}
var host: Node3D
var last_seconds := 0.0
var rejected_endpoints := 0

func bind(source: Node3D) -> void:
	host = source
	state = ExpeditionState.new(83471)
	state.configure_flora(VastraSettings.new().plant_parameters())
	for biome in range(4):
		var center := Vector3(-1.85 if biome % 2 == 0 else 1.85,0,-1.85 if biome < 2 else 1.85)
		var cell := Vector2i((biome % 2)*4,int(biome/2)*4)
		register_endpoint(cell,"plant",center + Vector3(0,0.12,0),center)
		var tree_at := center + Vector3(0,0,-1.85)
		register_endpoint(cell + Vector2i(0,-1),"tree",tree_at + Vector3(0,0.12,0),tree_at + Vector3(0,1.35,0))
		var tree: Node3D = preload("res://assets/nature/CommonTree_1.gltf").instantiate()
		add_child(tree)
		var bounds: AABB
		# Shared scenery model bounds provide the actual root/height placement.
		var model: Dictionary = preload("res://scripts/scenery/nature_art.gd").compact_parts(preload("res://assets/nature/CommonTree_1.gltf"))
		bounds = model.bounds
		var factor := 1.6 / maxf(bounds.size.y,0.001)
		tree.scale = Vector3.ONE * factor
		tree.position = tree_at - Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*factor
	state.admit_flora(definitions)
	# Clearly seeded test reserves give an immediate send/root-return demonstration.
	var snapshot := state.snapshot()
	for row in snapshot.flora.nodes.values():
		row.energy = 100.0 if row.kind == "plant" else 0.0
		row.roots = 40.0 if row.kind == "tree" else 0.0
		snapshot.flora.absorbed += row.energy + row.roots
	state = ExpeditionState.restore(snapshot,83471)
	var ids: Array[String] = []
	for row in definitions: ids.append(row.id)
	state.set_flora_active(ids)
	state.activity_advanced.connect(func(_tick: int): state.advance_flora(trees_near,conditions,plants_near))
	update_labels()

func register_endpoint(cell: Vector2i, kind: String, root: Vector3, crown: Vector3) -> void:
	var id := FloraCatalog.id_for(cell)
	definitions.append({"id":id,"cell":[cell.x,cell.y],"kind":kind})
	endpoints[id] = {"flora_id":id,"cell":cell,"kind":kind,"anchor":root,"high_anchor":crown}
	var label := Label3D.new()
	label.font_size = 32
	label.pixel_size = 0.005
	label.no_depth_test = true
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = crown + Vector3(0,0.35,0) if kind == "tree" else root + Vector3(0,0.55,1.0)
	add_child(label)
	labels[id] = label

func candidates(at: Vector2i, reach: float, kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in definitions:
		if row.kind == kind and at.distance_to(Vector2i(row.cell[0],row.cell[1])) <= reach: result.append(row)
	return result
func trees_near(at: Vector2i, reach: float) -> Array[Dictionary]: return candidates(at,reach,"tree")
func plants_near(at: Vector2i, reach: float) -> Array[Dictionary]: return candidates(at,reach,"plant")
func conditions(_at: Vector2i) -> Dictionary: return {"concentration":45,"overload":0}

func advance(delta: float) -> void:
	state.advance_time(delta)
	last_seconds = state.activity_seconds()
	var seen := {}
	for flight in state.flora_transfers():
		var key := str(flight.id)
		if not endpoints.has(flight.source) or not endpoints.has(flight.target):
			rejected_endpoints += 1
			continue
		var source: Dictionary = endpoints[flight.source]
		var target: Dictionary = endpoints[flight.target]
		if source.flora_id != flight.source_node.id or target.flora_id != flight.target_node.id:
			rejected_endpoints += 1
			continue
		var duration := float(flight.arrival-flight.sent)*ExpeditionContract.ACTIVITY_INTERVAL
		var elapsed := last_seconds-float(flight.get("visual_sent",flight.sent))*ExpeditionContract.ACTIVITY_INTERVAL
		if elapsed > duration + 0.6: continue
		seen[key] = true
		if not layers.has(key): layers[key] = make_transfer(flight,source,target,duration)
		var layer: Dictionary = layers[key]
		layer.motion.set_shader_parameter("elapsed",elapsed)
		layer.draw.set_shader_parameter("animation_time",last_seconds)
		layer.draw.set_shader_parameter("opacity",host.vastra_visibility)
		layer.node.visible = host.vastra_visible and host.vastra_visibility > 0.0
	for key in layers.keys():
		if not seen.has(key):
			layers[key].node.queue_free()
			layers.erase(key)
	update_labels()

func make_transfer(flight: Dictionary, source: Dictionary, target: Dictionary, duration: float) -> Dictionary:
	var root: bool = flight.root
	var start: Vector3 = source.anchor
	var finish: Vector3 = target.anchor if root else target.high_anchor
	if source.kind == "tree" and not root: start = source.high_anchor
	var motion := ShaderMaterial.new()
	motion.shader = preload("res://shaders/vastra_particle_lab_transfer.gdshader")
	var draw := ShaderMaterial.new()
	draw.shader = preload("res://shaders/vastra_particle_lab_draw.gdshader")
	draw.set_shader_parameter("field_noise",host.optical_noise)
	draw.set_shader_parameter("transfer_packet",true)
	draw.set_shader_parameter("tint",Color.WHITE)
	draw.set_shader_parameter("opacity",host.vastra_visibility)
	draw.set_shader_parameter("particle_size",host.vastra_thickness)
	draw.set_shader_parameter("filament_length",0.8)
	draw.set_shader_parameter("refraction",0.01)
	for surface in [motion,draw]:
		surface.set_shader_parameter("source_position",start)
		surface.set_shader_parameter("target_position",finish)
		surface.set_shader_parameter("arc_height",0.025 if root else host.vastra_height)
		surface.set_shader_parameter("path_width",0.08)
	motion.set_shader_parameter("duration",duration)
	motion.set_shader_parameter("trail_samples",4)
	motion.set_shader_parameter("trail_seconds",0.6)
	var node := GPUParticles3D.new()
	node.amount = host.vastra_filaments * 5
	node.lifetime = 3600
	node.explosiveness = 1
	node.local_coords = true
	node.fixed_fps = 60
	node.use_fixed_seed = true
	node.seed = int(flight.id)
	node.process_material = motion
	node.visibility_aabb = AABB(Vector3(-6,-1,-6),Vector3(12,8,12))
	node.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh := preload("res://scripts/presentation/vastra_filament_mesh.gd").create()
	mesh.surface_set_material(0,draw)
	node.draw_pass_1 = mesh
	node.set_meta("source_flora_id",flight.source)
	node.set_meta("target_flora_id",flight.target)
	node.set_meta("flight_id",flight.id)
	add_child(node)
	return {"node":node,"motion":motion,"draw":draw,"flight":flight.duplicate(true),"start":start,"finish":finish}

func update_labels() -> void:
	for row in definitions:
		var reading := state.flora_reading(Vector2i(row.cell[0],row.cell[1]))
		labels[row.id].text = ("TREE " if row.kind == "tree" else "GRASS ") + row.id + "\n%.0f / 100" % reading.energy
		if row.kind == "tree": labels[row.id].text += " · roots %.0f" % reading.roots

func readings() -> Dictionary:
	var data := state.flora_view()
	var stored := 0.0
	var transit := 0.0
	for row in data.nodes.values(): stored += row.energy + row.roots
	for flight in data.flights: transit += flight.amount
	return {"registered_cells":data.nodes.size(),"active_transfers":layers.size(),"stored":stored,"in_transit":transit,"absorbed":data.absorbed,"spent":data.spent,"conservation_error":data.absorbed-stored-transit-data.spent,"rejected_endpoints":rejected_endpoints,"valid":PlantVastra.valid(data,state.activity_tick()),"fixture":"Seeded test reserves; production ExpeditionState + PlantVastra; no ecology policy"}
