extends Node3D
## Reusable node and bounded LAB transaction model. Expedition integration is separate.
const CAPACITY := 100.0
const PURPOSES := [preload("res://resources/scenery/relic_clue.tres"), preload("res://resources/scenery/relic_relay.tres"), preload("res://resources/scenery/relic_layout.tres")]
@export_enum("Square seal", "Diamond seal", "Narrow seal") var housing_style := 0
@export_enum("Reveal clue", "Relay Vastra", "Reveal layout") var purpose := 0
@export_range(0.2, 3.0, 0.1) var travel_seconds := 0.8
@export var automatic_output := true
var source := 100.0
var reserve := 0.0
var delivered := 0.0
var spent := 0.0
var incoming: Dictionary = {}
var outgoing: Dictionary = {}
var operation_count := 0
var info: Label3D
var intake_head: MeshInstance3D
var output_head: MeshInstance3D
var effect: Node3D
var inbound_trail: MeshInstance3D
var outbound_trail: MeshInstance3D
var input_channel := PackedVector3Array()
var output_channel := PackedVector3Array()
var stone_glow: ShaderMaterial
var ambient_glow := 0.015
var disruption := 0.0
@onready var input_port: Marker3D = $InputPort
@onready var output_port: Marker3D = $OutputPort

func _ready() -> void:
	purpose = clampi(purpose, 0, 2)
	housing_style = clampi(housing_style, 0, 2)
	var energy := surface(Color("e1e8ed"), true)
	var core := Marker3D.new()
	core.name = "Core"
	core.position = Vector3(0, 0, 0.1)
	add_child(core)
	if input_channel.is_empty(): input_channel = PackedVector3Array([input_port.position, Vector3(0, 0, 0.1)])
	if output_channel.is_empty(): output_channel = PackedVector3Array([Vector3(0, 0, 0.1), output_port.position])
	var orb := SphereMesh.new()
	orb.radius = 0.035
	orb.height = 0.07
	intake_head = place("Inbound packet", orb, source_anchor(), energy)
	output_head = place("Outbound packet", orb, output_port.position, energy)
	inbound_trail = place("Inbound strand", ImmediateMesh.new(), Vector3.ZERO, energy)
	outbound_trail = place("Outbound strand", ImmediateMesh.new(), Vector3.ZERO, energy)
	effect = Node3D.new()
	effect.name = "PurposeOutput"
	effect.position = destination_anchor()
	add_child(effect)
	info = caption("", Vector3(0, 0.72, 0))
	info.hide()
	refresh()

func source_anchor() -> Vector3:
	return Vector3(-1.65, 0.15, 0.45)

func destination_anchor() -> Vector3:
	return Vector3(1.65, 0.15, 0.45)

func intake(amount: float) -> bool:
	if not is_finite(amount) or amount <= 0 or not incoming.is_empty() or source < amount or reserve + amount > CAPACITY: return false
	source -= amount
	incoming = {"amount": amount, "elapsed": 0.0}
	refresh()
	return true

func operate() -> bool:
	var definition: Resource = PURPOSES[purpose]
	if not definition.valid(): return false
	var cost: float = definition.energy_cost
	if not outgoing.is_empty() or reserve < cost or (definition.output_kind == "transfer" and delivered + cost > CAPACITY): return false
	reserve -= cost
	outgoing = {"amount": cost, "elapsed": 0.0, "kind": definition.output_kind}
	refresh()
	return true

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not is_finite(delta) or delta < 0: return
	# Settle existing departures first so newly created packets have actual travel time.
	if not outgoing.is_empty():
		outgoing.elapsed += delta
		if outgoing.elapsed >= travel_seconds:
			if outgoing.kind == "transfer": delivered += outgoing.amount
			else: spent += outgoing.amount
			outgoing.clear()
			operation_count += 1
	if not incoming.is_empty():
		incoming.elapsed += delta
		if incoming.elapsed >= travel_seconds:
			reserve += incoming.amount
			incoming.clear()
	if automatic_output: operate()
	refresh()

func accounting_total() -> float:
	return source + reserve + delivered + spent + float(incoming.get("amount", 0.0)) + float(outgoing.get("amount", 0.0))

func reset_test() -> void:
	source = 100
	reserve = 0
	delivered = 0
	spent = 0
	operation_count = 0
	incoming.clear()
	outgoing.clear()
	refresh()

func reading() -> Dictionary:
	return {"purpose": PURPOSES[purpose].display_name, "purpose_id": PURPOSES[purpose].purpose_id, "source": source, "reserve": reserve, "in_flight": float(incoming.get("amount", 0.0)) + float(outgoing.get("amount", 0.0)), "delivered": delivered, "spent": spent, "operations": operation_count, "total": accounting_total()}

func refresh() -> void:
	if not is_instance_valid(info): return
	info.text = "%s\nReserve %.0f / 100" % [PURPOSES[purpose].display_name, reserve]
	effect.visible = operation_count > 0
	intake_head.visible = not incoming.is_empty()
	output_head.visible = not outgoing.is_empty()
	inbound_trail.visible = intake_head.visible
	outbound_trail.visible = output_head.visible
	if intake_head.visible:
		var progress := clampf(incoming.elapsed / travel_seconds, 0, 1)
		var route := PackedVector3Array([source_anchor()])
		route.append_array(input_channel)
		intake_head.position = sample_channel(route, progress)
		draw_trail(inbound_trail, route, progress)
	if output_head.visible:
		var progress := clampf(outgoing.elapsed / travel_seconds, 0, 1)
		var route := output_channel.duplicate()
		route.append(destination_anchor())
		output_head.position = sample_channel(route, progress)
		draw_trail(outbound_trail, route, progress)
	if stone_glow:
		var strength := ambient_glow + reserve / CAPACITY * 0.12
		if PURPOSES[purpose].output_kind != "transfer" and operation_count > 0: strength += 0.16
		stone_glow.set_shader_parameter("glow_strength", strength)
		stone_glow.set_shader_parameter("disruption", disruption)
		stone_glow.set_shader_parameter("packet_active", intake_head.visible or output_head.visible)
		stone_glow.set_shader_parameter("packet_position", intake_head.global_position if intake_head.visible else output_head.global_position)

func sample_channel(route: PackedVector3Array, progress: float) -> Vector3:
	var total := 0.0
	for i in range(1, route.size()): total += route[i - 1].distance_to(route[i])
	var remaining := total * clampf(progress, 0, 1)
	for i in range(1, route.size()):
		var length := route[i - 1].distance_to(route[i])
		if remaining <= length and length > 0: return route[i - 1].lerp(route[i], remaining / length)
		remaining -= length
	return route[-1]

func draw_trail(item: MeshInstance3D, route: PackedVector3Array, progress: float) -> void:
	var mesh := item.mesh as ImmediateMesh
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(17): mesh.surface_add_vertex(sample_channel(route, lerpf(maxf(0, progress - 0.4), progress, float(i) / 16)))
	mesh.surface_end()

func surface(color: Color, glow: bool) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.emission_enabled = glow
	result.emission = color
	result.emission_energy_multiplier = 1.5
	return result

func place(title: String, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = title
	item.mesh = mesh
	item.position = at
	item.material_override = material
	add_child(item)
	return item

func caption(text: String, at: Vector3) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 32
	label.pixel_size = 0.006
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	return label
