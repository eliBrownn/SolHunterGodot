extends Node
## Keeps the expedition in memory while the isolated development world is open.
const LAB := "res://scenes/development_workstation.tscn"
var expedition: Node3D
var lab: Control
var in_lab := false
var switch_button := Button.new()
var layer := CanvasLayer.new()
var lab_layer := CanvasLayer.new()
var expedition_state: Dictionary = {}
var lab_state: Dictionary = {}
var sol_lab: Control
var in_sol_lab := false
var sol_state: Dictionary = {}
var sol_layer := CanvasLayer.new()
var sol_button := Button.new()

func bind(source: Node3D) -> void:
	expedition = source
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer.layer = 100
	add_child(layer)
	layer.add_child(switch_button)
	switch_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	switch_button.offset_left = -256
	switch_button.offset_top = -44
	switch_button.offset_right = -12
	switch_button.offset_bottom = -12
	switch_button.text = "Development lab [F8]"
	switch_button.pressed.connect(toggle_world)
	layer.add_child(sol_button)
	sol_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	sol_button.offset_left = -448
	sol_button.offset_top = -44
	sol_button.offset_right = -268
	sol_button.offset_bottom = -12
	sol_button.text = "Sol Lab [F9]"
	sol_button.pressed.connect(toggle_sol_lab)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_F9 or event.keycode == KEY_F9):
		get_viewport().set_input_as_handled()
		toggle_sol_lab()
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_F8 or event.keycode == KEY_F8):
		get_viewport().set_input_as_handled()
		toggle_world()

func toggle_world() -> void:
	if in_sol_lab: toggle_sol_lab()
	if in_lab:
		lab_state = suspend(lab)
		lab.hide()
		lab_layer.hide()
		restore(expedition, expedition_state)
		in_lab = false
		switch_button.text = "Development lab [F8]"
		DisplayServer.window_set_title("SolHunter")
	else:
		# Optional tools must not join the normal expedition's resource load.
		var packed: PackedScene
		if lab == null:
			packed = load(LAB) as PackedScene
			if packed == null: return
		expedition_state = suspend(expedition)
		if lab == null:
			lab = packed.instantiate()
			lab.process_mode = Node.PROCESS_MODE_ALWAYS
			lab_layer.layer = 90
			add_child(lab_layer)
			var backdrop := ColorRect.new()
			backdrop.color = Color("172329")
			backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lab_layer.add_child(backdrop)
			backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			lab_layer.add_child(lab)
			# Reserve a footer so the return control cannot cover lab notes/sliders.
			lab.offset_bottom = -54
		else:
			restore(lab, lab_state)
		lab_layer.show()
		lab.show()
		in_lab = true
		switch_button.text = "Return to expedition [F8]"
		DisplayServer.window_set_title("SolHunter — Development lab")

func toggle_sol_lab() -> void:
	if in_sol_lab:
		sol_state = suspend(sol_lab)
		sol_lab.hide()
		sol_layer.hide()
		restore(expedition, expedition_state)
		in_sol_lab = false
		sol_button.text = "Sol Lab [F9]"
		DisplayServer.window_set_title("SolHunter")
		return
	if in_lab: toggle_world()
	# Load before suspending the expedition so a missing scene cannot strand play.
	if sol_lab == null:
		var scene := load("res://scenes/sol_lab.tscn") as PackedScene
		if scene == null: return
		sol_lab = scene.instantiate()
		sol_lab.process_mode = Node.PROCESS_MODE_ALWAYS
		sol_layer.layer = 90
		add_child(sol_layer)
		var backdrop := ColorRect.new()
		backdrop.color = Color("111a24")
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sol_layer.add_child(backdrop)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sol_layer.add_child(sol_lab)
		sol_lab.offset_bottom = -54
	else:
		restore(sol_lab, sol_state)
	expedition_state = suspend(expedition)
	sol_layer.show()
	sol_lab.show()
	in_sol_lab = true
	sol_button.text = "Return to game [F9]"
	DisplayServer.window_set_title("SolHunter — Sol Lab")

func suspend(root: Node) -> Dictionary:
	var state := {"mode": root.process_mode, "layers": [], "particles": [], "audio": []}
	# Never suspend this switch or the lab while traversing the expedition owner.
	collect(root, state)
	root.process_mode = Node.PROCESS_MODE_DISABLED
	if root is Node3D:
		state["visible"] = root.visible
		root.hide()
	return state

func collect(node: Node, state: Dictionary) -> void:
	if node == self: return
	if node is CanvasLayer:
		state.layers.append([node, node.visible])
		node.hide()
	if node is GPUParticles3D or node is GPUParticles2D:
		state.particles.append([node, node.speed_scale])
		node.speed_scale = 0.0
	if node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D:
		state.audio.append([node, node.stream_paused])
		node.stream_paused = true
	for child in node.get_children(): collect(child, state)

func restore(root: Node, state: Dictionary) -> void:
	root.process_mode = state.mode
	if root is Node3D: root.visible = state.visible
	for entry in state.layers:
		if is_instance_valid(entry[0]): entry[0].visible = entry[1]
	for entry in state.particles:
		if is_instance_valid(entry[0]): entry[0].speed_scale = entry[1]
	for entry in state.audio:
		if is_instance_valid(entry[0]): entry[0].stream_paused = entry[1]
