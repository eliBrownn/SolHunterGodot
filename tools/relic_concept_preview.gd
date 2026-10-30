extends Node3D
## Original geometry and synthetic readings only. No expedition or ecology writes.
const Relic = preload("res://scripts/scenery/procedural_relic.gd")
const RelicMaterials = preload("res://scripts/scenery/relic_materials.gd")
const Carving = preload("res://scripts/scenery/relic_carving.gd")
const FISSURE_GLOW = preload("res://shaders/relic_fissure_glow.gdshader")
const VASTRA_NODE = preload("res://scenes/relic_vastra_node.tscn")
@export_enum("Original trio", "Broken marker", "Ruined arch", "Foundation", "Split ring", "Spire circle", "Courtyard ruin", "Sanctum ruin") var display_family := 0
@export_range(0, 99999, 1) var generation_seed := 73
@export_range(0.6, 1.3, 0.05) var structure_scale := 1.0
@export_range(0.0, 2.0, 0.05) var damage := 0.45
@export_range(2, 12, 1) var stone_courses := 5
@export_range(0.0, 1.0, 0.05) var break_variation := 0.65
@export_range(0, 16, 1) var rubble_count := 6
@export_enum("Black stone", "Abyssal stone", "Ash-black stone") var material_style := 0
@export_range(0.04, 0.12, 0.01) var etch_depth := 0.1
@export_range(0.25, 3.0, 0.05) var texture_scale := 1.0
@export_enum("Square seal", "Diamond seal", "Narrow seal") var node_style := 0
@export_enum("Family defaults", "Reveal clue", "Relay Vastra", "Reveal layout") var output_purpose := 0
@export_range(1.0, 50.0, 1.0) var intake_amount := 20.0
@export_range(0.2, 3.0, 0.1) var packet_travel_seconds := 0.8
@export var automatic_output := true
@export_range(0, 100, 1) var concentration := 65
@export_range(-100, 100, 1) var overload := 0
@export_range(0.0, 2.0, 0.05) var response_strength := 0.8
@export var show_purpose_labels := true
var camera: Camera3D
var layouts: Dictionary = {}
var vastra_nodes: Array[Node3D] = []
var flow_readings: Label

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("202c34")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c4d5df")
	world.environment.ambient_light_energy = 0.5
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0)
	sun.light_color = Color("c6ceda")
	sun.light_energy = 1.2
	add_child(sun)
	camera = Camera3D.new()
	camera.position = Vector3(5, 11, 17)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 16.0 if display_family == 0 else 8.0
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0, 1, 0))
	box(self, "Study ground", Vector3(0, -0.18, 0), Vector3(23, 0.3, 12), material(Color("475844")))
	for family in range(1, 8):
		if display_family == 0 and family > 3: continue
		if display_family != 0 and display_family != family: continue
		var site := Node3D.new()
		site.name = ["Marker", "Arch", "Foundation", "SplitRing", "SpireCircle", "Courtyard", "Sanctum"][family - 1]
		site.position.x = float(family - 2) * 7.0 if display_family == 0 else 0.0
		add_child(site)
		var layout := Relic.layout(family, generation_seed, structure_scale, damage, rubble_count, stone_courses, break_variation)
		if layout.is_empty(): continue
		layouts[family] = layout
		var carved := Carving.prepare(layout, node_style, etch_depth)
		var glow := ShaderMaterial.new()
		glow.shader = FISSURE_GLOW
		for part in layout.parts:
			var piece := MeshInstance3D.new()
			piece.name = part.id
			piece.mesh = carved.meshes[part.id]
			piece.position = part.at
			piece.rotation = Vector3(0, part.yaw, part.roll)
			var stone := RelicMaterials.create(material_style, Color.WHITE.darkened(float(part.tone) * 0.18), texture_scale)
			if not str(part.id).begins_with("rubble_"): stone.next_pass = glow
			piece.material_override = stone
			site.add_child(piece)
		var node := VASTRA_NODE.instantiate()
		node.housing_style = node_style
		node.purpose = [0, 1, 2, 1, 2, 2, 0][family - 1] if output_purpose == 0 else output_purpose - 1
		node.travel_seconds = packet_travel_seconds
		node.automatic_output = automatic_output
		node.stone_glow = glow
		node.ambient_glow = float(concentration) / 100.0 * response_strength * 0.045 + maxf(0, -float(overload)) / 100.0 * 0.025
		node.disruption = maxf(0, float(overload)) / 100.0
		# Stable logical attachment contract; the visible node is cut into the stone.
		node.position = layout.node_anchor
		for point in carved.input_channel: node.input_channel.append(point - node.position)
		for point in carved.output_channel: node.output_channel.append(point - node.position)
		site.add_child(node)
		vastra_nodes.append(node)
		if show_purpose_labels:
			var top := 0.0
			for part in layout.parts: top = maxf(top, part.at.y + (part.size.y + part.size.x) * 0.5)
			caption(site, ["MARKER\nRecognize a motif · find a lead", "ARCH\nConnect the evidence · look beyond", "FOUNDATION\nInvestigate the place · compare traces", "SPLIT RING\nTrace the surviving connection", "SPIRE CIRCLE\nRead the gathering pattern", "COURTYARD\nInterpret the old layout", "SANCTUM\nInvestigate a focused clue"][family - 1], Vector3(0, maxf(6.4 * structure_scale, top + 0.6), 0))

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.9
	return result

func box(parent: Node3D, title: String, at: Vector3, size: Vector3, surface: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = surface
	mesh.position = at
	parent.add_child(mesh)
	return mesh

func caption(parent: Node3D, text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 40
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)

func workstation_dock_controls(host: Node) -> void:
	var heading := Label.new()
	heading.text = "RELICS · CONCEPT PREVIEW"
	host.add_child(heading)
	var guide: Node = host
	var workstation: Node = host
	while workstation != null and not workstation.has_method("fold_section"):
		workstation = workstation.get_parent()
	if workstation != null:
		for entry in [["Send Vastra in", "intake"], ["Run purpose / output", "operate"], ["Reset test supply", "reset_test"]]:
			var action := Button.new()
			action.text = entry[0]
			var method: String = entry[1]
			action.name = "RelicAction_" + method
			action.pressed.connect(func():
				var accepted := 0
				for node in vastra_nodes:
					if method == "intake":
						if node.intake(intake_amount): accepted += 1
					elif method == "operate":
						if node.operate(): accepted += 1
					else: node.reset_test(); accepted += 1
				workstation.message.text = ("Updated %d relics." % accepted if accepted > 0 else "No departure: check supply, reserve, and travelling packets.") + (" Resume or use One frame to advance packets." if workstation.paused else "")
				update_flow_readings())
			host.add_child(action)
		flow_readings = Label.new()
		flow_readings.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		host.add_child(flow_readings)
		update_flow_readings()
		var next := Button.new()
		next.name = "NextRelicDesign"
		next.text = "New design"
		next.tooltip_text = "Advance the design seed; keep your scale, damage and Vastra settings."
		next.pressed.connect(func(): workstation.apply_parameter("generation_seed", (generation_seed + 1) % 100000))
		host.add_child(next)
	if get_meta("development_workstation", false):
		# Use the workstation's existing folding UI; leave tuning immediately reachable.
		if workstation != null: guide = workstation.fold_section(host, "Concept guide", false)
	for text in ["Lab-only finite supply: send energy in, then spend it on the selected purpose. No expedition harvesting or ecological changes.", "Marker reveals a clue; arch relays energy to a receiver; foundation reveals a layout. Purpose is independently selectable.", "Ancient node carvings share the same logical Core, InputPort and OutputPort. Fissures and hollows are indents in the stone mesh, with light inside them.", "Test supply resets when rebuilding or switching the fixture. Pause stops packets. Costs and supply are provisional lab values."]:
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		guide.add_child(label)

func workstation_parameter_info(key: String) -> Dictionary:
	return {
		"stone_courses": {"label": "Stone courses / layers", "group": "Appearance", "order": -2},
		"break_variation": {"label": "Uneven break variation", "group": "Appearance", "order": -1},
		"etch_depth": {"label": "Square-cut etch depth (m)", "group": "Appearance", "order": -5},
		"material_style": {"label": "Stone material", "group": "Appearance", "order": -8},
		"texture_scale": {"label": "Material tiling", "group": "Appearance", "order": -7},
		"node_style": {"label": "Ancient node carving", "group": "Appearance", "order": -6},
		"generation_seed": {"label": "Design seed", "group": "Appearance", "order": -4, "help": "Same seed and controls reproduce the same stonework."},
		"structure_scale": {"label": "Structure scale", "group": "Appearance", "order": -3},
		"damage": {"label": "Missing stonework: intact → skeletal", "group": "Appearance", "order": -3, "help": "0 preserves courses; 1 creates severe breaks; 2 leaves low remnants. Does not reroll proportions or rubble."},
		"rubble_count": {"label": "Rubble pieces", "group": "Appearance", "order": 0, "help": "Decoration has a separate seeded stream; the main structure stays fixed."},
		"display_family": {"label": "Structure to view", "group": "Appearance", "order": 0},
		"show_purpose_labels": {"label": "Show gameplay purposes", "group": "Appearance", "order": 1},
		"concentration": {"label": "Test concentration / 100", "group": "Appearance", "order": 2, "help": "Synthetic ambient richness; high values do not mean damage."},
		"overload": {"label": "Test condition: restorative − / disrupted +", "group": "Appearance", "order": 3, "help": "Separate signed test input, not stored energy or a storm forecast."},
		"response_strength": {"label": "Visual response strength", "group": "Appearance", "order": 4},
		"output_purpose": {"label": "Relic output purpose", "group": "Vastra flow", "order": 10},
		"intake_amount": {"label": "Energy per intake", "group": "Vastra flow", "order": 11},
		"packet_travel_seconds": {"label": "Packet travel seconds", "group": "Vastra flow", "order": 12},
		"automatic_output": {"label": "Run purpose after intake", "group": "Vastra flow", "order": 13}
	}.get(key, {})

func workstation_readings() -> Dictionary:
	var flows: Array[Dictionary] = []
	for node in vastra_nodes: flows.append(node.reading())
	return {"scope": "concept_only", "generation_seed": generation_seed, "geometry_version": Relic.VERSION, "concentration": concentration, "overload": overload, "family": display_family, "flows": flows, "operations": "lab only"}

func _process(_delta: float) -> void:
	update_flow_readings()

func update_flow_readings() -> void:
	if not is_instance_valid(flow_readings): return
	var lines := PackedStringArray()
	for node in vastra_nodes:
		var state: Dictionary = node.reading()
		lines.append("%s: source %.0f · reserve %.0f · travelling %.0f · out %.0f · spent %.0f" % [state.purpose, state.source, state.reserve, state.in_flight, state.delivered, state.spent])
	flow_readings.text = "TEST SUPPLY · 100 per relic\n" + "\n".join(lines)
