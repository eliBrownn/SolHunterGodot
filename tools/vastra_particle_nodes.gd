extends Node3D
## Scripted visual transactions only. No ExpeditionState or production mechanics owner.
const NAMES := ["A · Ground plant", "B · Flowers", "C · Tree", "D · Tree", "E · Shrub"]
const POSITIONS := [Vector3(-2.7,0,0.6),Vector3(-0.7,0,2.0),Vector3(0.3,0,-1.7),Vector3(3.0,0,0.2),Vector3(2.1,0,2.5)]
const ART := ["Plant_1", "Flower_3_Group", "CommonTree_1", "CommonTree_3", "Bush_Common_Flowers"]
const HEIGHTS := [0.8,0.55,3.2,2.7,0.9]
const SCENARIOS := ["Single transfer", "Tree relay", "Two plants converge", "Full tree → root overflow", "Roots → nearby plant"]
var lab: Node3D
var rows: Array[Dictionary] = []
var flights: Array[Dictionary] = []
var scenario := OptionButton.new()
var source := OptionButton.new()
var target := OptionButton.new()
var readout := Label.new()
var send_button := Button.new()
var controls: Dictionary = {}
var events: Array[String] = []
var relay_pending := false
var total := 0.0
var received := 0

func bind(owner_lab: Node3D) -> void:
	lab=owner_lab
	for i in range(NAMES.size()):
		var marker := Node3D.new()
		marker.position=POSITIONS[i]
		add_child(marker)
		var packed: PackedScene=load("res://assets/nature/%s.gltf" % ART[i])
		var item: Node3D=packed.instantiate()
		marker.add_child(item)
		var bounds := asset_bounds(item,Transform3D.IDENTITY)
		var factor: float=HEIGHTS[i]/maxf(bounds.size.y,0.001)
		item.scale=Vector3.ONE*factor
		item.position.y=-bounds.position.y*factor
		var label := Label3D.new()
		label.font_size=40
		label.pixel_size=0.005
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test=true
		label.position.y=HEIGHTS[i]+0.3
		marker.add_child(label)
		var endpoint := MeshInstance3D.new()
		var dot := SphereMesh.new()
		dot.radius=0.065
		dot.height=0.13
		endpoint.mesh=dot
		endpoint.position=Vector3(0,HEIGHTS[i]*0.65,0)
		var ink := StandardMaterial3D.new()
		ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.albedo_color=Color("a4e8e0")
		endpoint.material_override=ink
		endpoint.hide()
		marker.add_child(endpoint)
		var port: Vector3=POSITIONS[i]+Vector3(0,HEIGHTS[i]*0.65,0)
		rows.append({"energy":0.0,"roots":0.0,"tree":i in [2,3],"label":label,"port":port,"pulse":0.0,"art":item,"endpoint":endpoint})

func asset_bounds(node: Node3D, parent_transform: Transform3D) -> AABB:
	var transform := parent_transform*node.transform
	var bounds := AABB()
	var found := false
	if node is MeshInstance3D:
		bounds=transform*node.get_aabb()
		found=true
	for child in node.get_children():
		if child is Node3D:
			var next := asset_bounds(child,transform)
			if next.size.length_squared()>0:
				bounds=bounds.merge(next) if found else next
				found=true
	return bounds

func build_controls(box: VBoxContainer) -> void:
	var title := Label.new()
	title.text="PLANT INTERACTIONS · scripted tests"
	box.add_child(title)
	for name in SCENARIOS: scenario.add_item(name)
	box.add_child(scenario)
	scenario.item_selected.connect(configure_scenario)
	var row := HBoxContainer.new()
	box.add_child(row)
	for name in NAMES:
		source.add_item("From: "+name)
		target.add_item("To: "+name)
	row.add_child(source)
	row.add_child(target)
	source.item_selected.connect(func(_index: int): reset_nodes())
	target.item_selected.connect(func(_index: int): reset_nodes())
	for spec in [["Transfer energy",5.0,100.0,5.0,40.0],["Travel speed",0.2,4.0,0.1,1.2],["Arc height",0.0,3.0,0.1,0.8],["Path width",0.0,0.8,0.02,0.06],["Transfer visibility",0.0,1.0,0.05,1.0],["Send pulse strength",0.0,3.0,0.1,1.0],["Send pulse seconds",0.1,2.0,0.1,0.6]]:
		var label := Label.new()
		box.add_child(label)
		var slider := HSlider.new()
		slider.min_value=spec[1]
		slider.max_value=spec[2]
		slider.step=spec[3]
		slider.value=spec[4]
		controls[spec[0]]=slider
		label.text="%s: %.2f" % [spec[0],spec[4]]
		slider.value_changed.connect(func(value: float): label.text="%s: %.2f" % [spec[0],value])
		box.add_child(slider)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	send_button.text="Send / play interaction"
	buttons.add_child(send_button)
	send_button.pressed.connect(play_scenario)
	var reset := Button.new()
	reset.text="Reset nodes"
	buttons.add_child(reset)
	reset.pressed.connect(reset_nodes)
	readout.add_theme_font_size_override("font_size",14)
	box.add_child(readout)
	controls["Travel speed"].tooltip_text="World cells per second; applies when sending the next packet."
	configure_scenario(0)

func configure_scenario(index: int) -> void:
	source.disabled=index==2
	source.tooltip_text="Convergence uses A and B together." if index==2 else "Choose the sending node."
	source.select(2 if index in [1,4] else 0)
	target.select(4 if index==4 else (3 if index==1 else 2))
	reset_nodes()

func reset_nodes() -> void:
	for flight in flights: flight.node.queue_free()
	flights.clear()
	relay_pending=false
	received=0
	for i in range(rows.size()):
		rows[i].energy=100.0 if not rows[i].tree else 20.0
		rows[i].roots=80.0 if i==2 and scenario.selected==4 else 0.0
		rows[i].pulse=0.0
	if scenario.selected==3: rows[target.selected].energy=100.0
	if scenario.selected==4 and not rows[target.selected].tree: rows[target.selected].energy=20.0
	total=stored_total()
	events.clear()
	note("Ready · reserves reset, capacity 100")
	update_labels()
	update_visibility()

func stored_total() -> float:
	var sum := 0.0
	for row in rows: sum+=row.energy+row.roots
	for flight in flights:
		if not flight.arrived: sum+=flight.amount
	return sum

func note(message: String) -> void:
	events.append(message)
	if events.size()>4: events.pop_front()
	readout.text="%s\nStored + in transit: %.1f / %.1f" % ["\n".join(events),stored_total(),total]

func play_scenario() -> void:
	if lab.frozen:
		note("Resume motion before sending.")
		return
	if not flights.is_empty() or relay_pending:
		note("Wait for arrival, or reset nodes.")
		return
	var from: int=source.selected
	var to: int=target.selected
	var amount: float=controls["Transfer energy"].value
	if scenario.selected==1:
		if not rows[from].tree or not rows[to].tree or from==to:
			note("Relay: choose two different trees.")
			return
		# First charge the selected source tree from a visible ground plant.
		relay_pending=send(0,from,amount,false)
	elif scenario.selected==2:
		if not rows[to].tree:
			note("Convergence: choose a receiving tree.")
			return
		send(0,to,amount,false)
		send(1,to,amount,false)
	else:
		send(from,to,amount,scenario.selected==4)

func send(from: int, to: int, amount: float, roots: bool) -> bool:
	if from==to:
		note("Choose different source and destination nodes.")
		return false
	if roots and (not rows[from].tree or rows[to].tree):
		note("Root return: select a tree → ground plant.")
		return false
	if not roots and not rows[to].tree:
		note("Emission/relay target must be a tree.")
		return false
	var available: float=rows[from].roots if roots else rows[from].energy
	var admitted: float=minf(amount,available)
	if roots: admitted=minf(admitted,100.0-float(rows[to].energy))
	if admitted<=0:
		note("Source empty or receiver full · reset nodes.")
		return false
	if roots: rows[from].roots-=admitted
	else: rows[from].energy-=admitted
	var start: Vector3=rows[from].port
	var end: Vector3=rows[to].port
	if roots:
		start.y=0.12
		end.y=0.12
	var duration: float=start.distance_to(end)/controls["Travel speed"].value
	var node := GPUParticles3D.new()
	node.amount=8*(lab.trail_samples+1)
	node.lifetime=3600
	node.explosiveness=1.0
	node.local_coords=true
	node.fixed_fps=60
	node.use_fixed_seed=true
	node.seed=291030
	node.visibility_aabb=AABB(Vector3(-10,-2,-10),Vector3(20,15,20))
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var motion := ShaderMaterial.new()
	motion.shader=preload("res://shaders/vastra_particle_lab_transfer.gdshader")
	motion.set_shader_parameter("source_position",start)
	motion.set_shader_parameter("target_position",end)
	motion.set_shader_parameter("duration",duration)
	motion.set_shader_parameter("trail_samples",lab.trail_samples)
	node.process_material=motion
	var quad: ArrayMesh=lab.filament_mesh()
	var draw: ShaderMaterial=lab.draw.duplicate()
	draw.set_shader_parameter("transfer_packet",true)
	draw.set_shader_parameter("visibility_scale",controls["Transfer visibility"].value)
	draw.set_shader_parameter("pulse_strength",controls["Send pulse strength"].value)
	draw.set_shader_parameter("pulse_amount",1.0)
	draw.set_shader_parameter("source_position",start)
	draw.set_shader_parameter("target_position",end)
	quad.surface_set_material(0,draw)
	node.draw_pass_1=quad
	add_child(node)
	flights.append({"node":node,"motion":motion,"draw":draw,"clock":0.0,"duration":duration,"source":from,"target":to,"amount":admitted,"roots":roots,"arrived":false})
	rows[from].pulse=0.6
	note("%s → %s · %.0f sent" % [NAMES[from].substr(0,1),NAMES[to].substr(0,1),admitted])
	update_labels()
	return true

func advance(delta: float) -> void:
	var finished: Array[Dictionary]=[]
	for flight in flights:
		flight.clock+=delta
		flight.draw.set_shader_parameter("visibility_scale",controls["Transfer visibility"].value)
		flight.draw.set_shader_parameter("pulse_strength",controls["Send pulse strength"].value)
		flight.draw.set_shader_parameter("pulse_amount",exp(-flight.clock / controls["Send pulse seconds"].value))
		flight.motion.set_shader_parameter("elapsed",flight.clock)
		flight.motion.set_shader_parameter("arc_height",0.08 if flight.roots else controls["Arc height"].value)
		flight.draw.set_shader_parameter("arc_height",0.08 if flight.roots else controls["Arc height"].value)
		flight.draw.set_shader_parameter("path_width",controls["Path width"].value)
		flight.motion.set_shader_parameter("path_width",controls["Path width"].value)
		flight.motion.set_shader_parameter("trail_seconds",lab.controls["Trail seconds"].value)
		for key in ["particle_size","opacity","glow","all_affinities","tint","appearance","filament_length","refraction","animation_time"]:
			flight.draw.set_shader_parameter(key,lab.draw.get_shader_parameter(key))
		if not flight.arrived and flight.clock>=flight.duration+0.25:
			flight.arrived=true
			var row: Dictionary=rows[flight.target]
			var overflow: float=maxf(0.0,row.energy+flight.amount-100.0)
			row.energy=minf(100.0,row.energy+flight.amount)
			row.roots+=overflow
			row.pulse=1.0
			received+=1
			note("%s received %.0f%s" % [NAMES[flight.target].substr(0,1),flight.amount," · roots +%.0f" % overflow if overflow>0 else ""])
		if flight.clock>flight.duration+0.3+lab.controls["Trail seconds"].value: finished.append(flight)
	for flight in finished:
		flights.erase(flight)
		flight.node.queue_free()
	if relay_pending and flights.is_empty():
		relay_pending=false
		send(source.selected,target.selected,controls["Transfer energy"].value,false)
	for row in rows: row.pulse=maxf(0.0,row.pulse-delta)
	update_labels()

func update_labels() -> void:
	for i in range(rows.size()):
		var row: Dictionary=rows[i]
		row.label.text="%s\n%.0f / 100%s" % [NAMES[i],row.energy," · roots %.0f" % row.roots if row.tree else ""]
		row.endpoint.scale=Vector3.ONE*(1.0+row.pulse*0.4)
		row.label.modulate=Color("fff1a6") if row.pulse>0 else Color("d4ece6")

func settings() -> Dictionary:
	var values := {}
	for key in controls: values[key]=controls[key].value
	return {"interaction":SCENARIOS[scenario.selected],"source":NAMES[source.selected],"target":NAMES[target.selected],"values":values}

func update_visibility() -> void:
	var participants: Array[int]=[source.selected,target.selected]
	if scenario.selected==1: participants.append(0)
	if scenario.selected==2: participants.append_array([0,1])
	for i in range(rows.size()):
		var row: Dictionary=rows[i]
		row.art.visible=not lab.clear_view
		row.endpoint.visible=lab.clear_view and i in participants
		row.label.visible=not lab.clear_view or i in participants
		# Put the reading next to the actual root port for the root-return sample.
		var low: bool=scenario.selected==4 and i in participants
		row.endpoint.position.y=0.12 if low else HEIGHTS[i]*0.65
		row.label.position.y=(0.4 if low else HEIGHTS[i]*0.65+0.3) if lab.clear_view else HEIGHTS[i]+0.3
