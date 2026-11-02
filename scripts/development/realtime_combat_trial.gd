extends Node3D
## Disposable feel experiment. No ExpeditionState, rewards or production combat writes.
@export_range(1.0, 6.0, 0.1) var movement_speed := 3.0
@export_range(0.3, 2.0, 0.05) var enemy_warning := 0.85
@export_range(0.2, 2.0, 0.05) var attack_cooldown := 0.65
@export_range(0.25, 1.0, 0.05) var simulation_speed := 1.0

const LIBRARY = preload("res://resources/move_library.tres")
const COVER := Rect2(-0.65, -0.9, 1.3, 1.8)
const SLOW := Rect2(-4.8, 1.3, 4.0, 2.0)
const LIMIT := 5.5
const RADIUS := 0.28
var ally := Vector2(-3.5, 0)
var enemy := Vector2(3.5, 0)
var destination := Vector2(-3.5, 0)
var aim := Vector2(3.5, 0)
var hp := 44
var enemy_hp := 44
var elapsed := 0.0
var cooldown := 0.0
var enemy_delay := 1.0
var pending: Dictionary = {}
var warning: Dictionary = {}
var uses: Array[int] = []
var moves: Array[Dictionary] = []
var paused := false
var command_mode := false
var outcome := ""
var hits := 0
var dodges := 0
var casts := 0
var camera: Camera3D
var ally_model: SolOrb
var enemy_model: SolOrb
var ally_ring: MeshInstance3D
var enemy_ring: MeshInstance3D
var aim_ring: MeshInstance3D
var status: Label
var feedback: Label
var move_buttons: Array[Button] = []
var pause_button: Button
var note: TextEdit
var controls: PanelContainer
var creature_labels: Array[Label3D] = []

func _ready() -> void:
	for id in ["strike", "cinder_claw", "mend"]:
		moves.append(LIBRARY.find(id))
	build_arena()
	build_controls()
	restart_trial()

func restart_trial() -> void:
	reset_trial()
	paused = true
	feedback.text = "Choose your controls and tuning, then press Space or Start encounter."
	update_view(0)

func reset_trial() -> void:
	ally = Vector2(-3.5, 0)
	enemy = Vector2(3.5, 0)
	destination = ally
	hp = 44
	enemy_hp = 44
	elapsed = 0
	cooldown = 0
	enemy_delay = 1
	pending.clear()
	warning.clear()
	uses.clear()
	for move in moves: uses.append(SolMove.uses(move))
	paused = false
	outcome = ""
	hits = 0
	dodges = 0
	casts = 0
	if ally_model != null:
		ally_model.reset_locomotion()
		enemy_model.reset_locomotion()
		feedback.text = "Move around the stone cover. Orange circles mark the opponent's committed attack."
		update_view(0)

func legal(at: Vector2) -> bool:
	return absf(at.x) <= LIMIT - RADIUS and absf(at.y) <= LIMIT - RADIUS and not COVER.grow(RADIUS).has_point(at)

func move_actor(from: Vector2, toward: Vector2, speed: float, delta: float, other: Vector2) -> Vector2:
	var factor := 0.5 if SLOW.has_point(from) else 1.0
	var step := toward.limit_length(1.0) * speed * factor * delta
	var result := from
	# Axis sliding with bounded steps avoids crossing cover or another creature.
	for offset in [Vector2(step.x, 0), Vector2(0, step.y)]:
		var next: Vector2 = result + offset
		if legal(next) and next.distance_to(other) >= RADIUS * 2: result = next
	return result

func clear_line(from: Vector2, to: Vector2) -> bool:
	return line_clear_of(from, to, COVER)

func line_clear_of(from: Vector2, to: Vector2, rect: Rect2) -> bool:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in range(4):
		if Geometry2D.segment_intersects_segment(from, to, corners[i], corners[(i+1)%4]) != null: return false
	return not rect.has_point(from) and not rect.has_point(to)

func steering(from: Vector2, target: Vector2) -> Vector2:
	var rect := COVER.grow(RADIUS + 0.08)
	if line_clear_of(from, target, COVER.grow(RADIUS)): return (target-from).limit_length(1)
	# Tiny visibility graph around the one fixture obstacle; both control modes share admission.
	var nodes := [from, target, rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	var costs := {0: 0.0}
	var parents := {}
	var visited := {}
	for _iteration in range(nodes.size()):
		var chosen := -1
		for index: int in costs:
			if not visited.has(index) and (chosen == -1 or costs[index] < costs[chosen]): chosen = index
		if chosen == -1: break
		if chosen == 1: break
		visited[chosen] = true
		for index in range(nodes.size()):
			if index == chosen or not line_clear_of(nodes[chosen], nodes[index], COVER.grow(RADIUS)): continue
			var cost: float = costs[chosen] + Vector2(nodes[chosen]).distance_to(nodes[index])
			if not costs.has(index) or cost < costs[index]:
				costs[index] = cost
				parents[index] = chosen
	if not parents.has(1): return Vector2.ZERO
	var next := 1
	while parents[next] != 0: next = parents[next]
	return (Vector2(nodes[next])-from).limit_length(1)

func cast(slot: int) -> bool:
	if paused or not outcome.is_empty() or not pending.is_empty() or cooldown > 0 or slot < 0 or slot >= moves.size() or uses[slot] <= 0:
		return false
	var target := ally if slot == 2 else aim
	if slot == 2 and hp == 44:
		feedback.text = "Already at full health. Healing use retained."
		return false
	var reach := 1.5 if slot == 0 else 4.5
	if slot != 2 and (ally.distance_to(target) > reach or not clear_line(ally, target)):
		feedback.text = "Out of range or blocked by stone. Aim closer, or move around cover."
		return false
	uses[slot] -= 1
	casts += 1
	pending = {"slot": slot, "target": target, "left": 0.2 if slot == 0 else 0.45}
	cooldown = attack_cooldown
	ally_model.play_action("attack", elapsed)
	feedback.text = "%s — committed" % moves[slot].name
	return true

func tick(delta: float, movement := Vector2.ZERO) -> void:
	if paused or not outcome.is_empty(): return
	elapsed += delta
	cooldown = maxf(0, cooldown - delta)
	if command_mode: movement = steering(ally, destination)
	if pending.is_empty(): ally = move_actor(ally, movement, movement_speed, delta, enemy)
	if not pending.is_empty():
		pending.left -= delta
		if pending.left <= 0:
			var slot: int = pending.slot
			if slot == 2:
				hp = mini(44, hp + int(moves[slot].power))
				feedback.text = "Renewing Current restores %d HP" % int(moves[slot].power)
			elif enemy.distance_to(pending.target) <= (0.85 if slot == 0 else 1.1) and clear_line(ally, enemy):
				enemy_hp = maxi(0, enemy_hp - int(moves[slot].power))
				hits += 1
				enemy_model.play_action("hit", elapsed)
				feedback.text = "%s hits for %d" % [moves[slot].name, int(moves[slot].power)]
			else: feedback.text = "Miss — the opponent moved outside the committed area."
			pending.clear()
			if enemy_hp == 0: finish("Victory")
	if not outcome.is_empty(): return
	if not warning.is_empty():
		warning.left -= delta
		if warning.left <= 0:
			if ally.distance_to(warning.target) <= 1.15 and clear_line(enemy, ally):
				hp = maxi(0, hp - 6)
				ally_model.play_action("hit", elapsed)
				feedback.text = "Enemy Strike hits for 6"
			else:
				dodges += 1
				feedback.text = "Avoided the enemy's committed Strike"
			warning.clear()
			enemy_delay = 0.8
			if hp == 0: finish("Exhausted")
	else:
		enemy_delay -= delta
		if enemy.distance_to(ally) > 2.8 or not clear_line(enemy, ally):
			enemy = move_actor(enemy, steering(enemy, ally), movement_speed * 0.65, delta, ally)
		elif enemy_delay <= 0:
			warning = {"target": ally, "left": enemy_warning}
			enemy_model.play_action("attack", elapsed)

func finish(result: String) -> void:
	outcome = result
	pending.clear()
	warning.clear()
	feedback.text = "%s · %.1fs · %d/%d attacks hit · %d avoided. Restart to compare settings." % [result, elapsed, hits, casts, dodges]

func _process(delta: float) -> void:
	var movement := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).limit_length(1)
	var focus := get_viewport().gui_get_focus_owner()
	if note.has_focus() or focus is TextEdit or focus is LineEdit: movement = Vector2.ZERO
	var scaled := minf(delta, 0.05) * simulation_speed
	tick(scaled, movement)
	update_view(0 if paused or not outcome.is_empty() else scaled)

func pointer_world(mouse: Vector2) -> Vector2:
	var hit: Variant = Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(mouse), camera.project_ray_normal(mouse))
	return Vector2(hit.x, hit.z) if hit != null else ally

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion: aim = pointer_world(event.position)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if command_mode:
			var target := pointer_world(event.position)
			if legal(target): destination = target
		else: cast(0)

func _input(event: InputEvent) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if note.has_focus() or focus is TextEdit or focus is LineEdit: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: cast(0)
			KEY_2: cast(1)
			KEY_3: cast(2)
			KEY_SPACE: toggle_pause()
			KEY_R: restart_trial()
			_: return
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	paused = not paused
	update_view(0)

func build_arena() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14
	camera.position = Vector3(0, 12, 9)
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-60, -25, 0)
	light.shadow_enabled = true
	add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("17232b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b7d3d5")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	box(Vector3(0, -0.12, 0), Vector3(11.6, 0.2, 11.6), Color("46594e"))
	box(Vector3(0, 0.65, 0), Vector3(COVER.size.x, 1.3, COVER.size.y), Color("525867"))
	box(Vector3(SLOW.get_center().x, 0.005, SLOW.get_center().y), Vector3(SLOW.size.x, 0.015, SLOW.size.y), Color("365c76"))
	ally_model = preload("res://scenes/sols/ashquill.tscn").instantiate()
	enemy_model = preload("res://scenes/sols/rattlehorn.tscn").instantiate()
	for model in [ally_model, enemy_model]:
		model.configure("fire" if model == ally_model else "earth", SolVisualSettings.new())
		model.scale = Vector3.ONE * 2.0 # Fixture readability only; no production size change.
		add_child(model)
		var nameplate := Label3D.new()
		nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nameplate.font_size = 32
		nameplate.pixel_size = 0.006
		nameplate.no_depth_test = true
		add_child(nameplate)
		creature_labels.append(nameplate)
	ally_ring = disc(Color(0.3, 0.85, 1, 0.6))
	enemy_ring = disc(Color(1, 0.35, 0.08, 0.7))
	aim_ring = disc(Color(0.9, 0.9, 0.7, 0.3))

func box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	mesh.position = at
	add_child(mesh)

func disc(color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := CylinderMesh.new()
	shape.top_radius = 1
	shape.bottom_radius = 1
	shape.height = 0.012
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = material
	add_child(mesh)
	return mesh

func label(parent: Node, text: String) -> Label:
	var node := Label.new()
	node.text = text
	parent.add_child(node)
	return node

func button(parent: Node, text: String, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.pressed.connect(action)
	parent.add_child(node)
	return node

func slider(parent: Node, title: String, low: float, high: float, step: float, property: String) -> void:
	var caption := label(parent, "")
	var node := HSlider.new()
	node.min_value = low
	node.max_value = high
	node.step = step
	node.value = get(property)
	node.custom_minimum_size.x = 260
	caption.text = "%s: %.2f" % [title, node.value]
	node.value_changed.connect(func(value: float): set(property, value); caption.text = "%s: %.2f" % [title, value])
	parent.add_child(node)

func build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	controls = PanelContainer.new()
	controls.position = Vector2(14, 14)
	layer.add_child(controls)
	var column := VBoxContainer.new()
	controls.add_child(column)
	label(column, "REAL-TIME COMBAT · EXPERIMENT")
	label(column, "Ashquill vs Rattlehorn · temporary rules\nWASD move · aim with mouse · 1/2/3 moves\nSpace pause · R restart · blue ground slows both")
	var mode := OptionButton.new()
	mode.add_item("Direct control — WASD + mouse aim")
	mode.add_item("Command Sol — click destination + 1/2/3")
	mode.item_selected.connect(func(index: int): command_mode = index == 1; destination = ally)
	column.add_child(mode)
	slider(column, "Movement m/s", 1, 6, 0.1, "movement_speed")
	slider(column, "Enemy warning seconds", 0.3, 2, 0.05, "enemy_warning")
	slider(column, "Move cooldown seconds", 0.2, 2, 0.05, "attack_cooldown")
	slider(column, "Simulation speed", 0.25, 1, 0.05, "simulation_speed")
	status = label(column, "")
	for slot in range(moves.size()):
		move_buttons.append(button(column, "%d · %s" % [slot+1, moves[slot].name], func(): cast(slot)))
	pause_button = button(column, "Pause [Space]", toggle_pause)
	button(column, "Restart encounter [R]", restart_trial)
	note = TextEdit.new()
	note.placeholder_text = "What felt good? What became repetitive?\nDid you feel connected to your Sol?"
	note.custom_minimum_size = Vector2(290, 70)
	column.add_child(note)
	button(column, "Save trial notes", save_notes)
	feedback = Label.new()
	feedback.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	feedback.offset_left = 20
	feedback.offset_right = -20
	feedback.offset_top = -64
	feedback.add_theme_font_size_override("font_size", 20)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(feedback)

func save_notes() -> void:
	DirAccess.make_dir_recursive_absolute("user://combat_trials")
	var path := "user://combat_trials/%s-%d.json" % [Time.get_datetime_string_from_system().replace(":", "-"), Time.get_ticks_msec()]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		feedback.text = "Could not save notes: %s" % error_string(FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify({"mode": "command" if command_mode else "direct", "elapsed": elapsed, "outcome": outcome, "hp": hp, "enemy_hp": enemy_hp, "hits": hits, "casts": casts, "avoided": dodges, "movement_speed": movement_speed, "enemy_warning": enemy_warning, "attack_cooldown": attack_cooldown, "simulation_speed": simulation_speed, "notes": note.text}, "\t"))
	feedback.text = "Saved: " + ProjectSettings.globalize_path(path)

func workstation_dock_controls(parent: Control) -> void:
	controls.reparent(parent)
	controls.position = Vector2.ZERO
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _exit_tree() -> void:
	# Docked controls are outside the fixture tree. Their callbacks must not outlive it.
	if is_instance_valid(controls) and not is_ancestor_of(controls): controls.queue_free()

func update_view(delta: float) -> void:
	for pair in [[ally_model, ally], [enemy_model, enemy]]:
		var model: SolOrb = pair[0]
		var at: Vector2 = pair[1]
		model.position = Vector3(at.x, 0, at.y)
		model.ground_y = 0
		model.sync_locomotion(at, delta, func(_at: Vector2): return 0.0)
		model.animate(elapsed, 0, 0)
	for index in range(creature_labels.size()):
		var at := ally if index == 0 else enemy
		creature_labels[index].position = Vector3(at.x, 1.0, at.y)
		creature_labels[index].text = "%s · %d HP" % ["Ashquill" if index == 0 else "Rattlehorn", hp if index == 0 else enemy_hp]
	ally_ring.visible = not pending.is_empty() and pending.get("slot", 2) != 2
	if ally_ring.visible:
		ally_ring.position = Vector3(pending.target.x, 0.04, pending.target.y)
		ally_ring.scale = Vector3(0.85 if pending.slot == 0 else 1.1, 1, 0.85 if pending.slot == 0 else 1.1)
	enemy_ring.visible = not warning.is_empty()
	if enemy_ring.visible:
		enemy_ring.position = Vector3(warning.target.x, 0.045, warning.target.y)
		enemy_ring.scale = Vector3(1.15, 1, 1.15)
	aim_ring.position = Vector3(aim.x, 0.025, aim.y)
	aim_ring.scale = Vector3(0.2, 1, 0.2)
	status.text = "Ashquill %d/44    Rattlehorn %d/44\n%.1fs · %s" % [hp, enemy_hp, elapsed, outcome if not outcome.is_empty() else "PAUSED" if paused else "FIGHT"]
	pause_button.text = ("Start encounter [Space]" if elapsed == 0 else "Resume [Space]") if paused else "Pause [Space]"
	for slot in range(move_buttons.size()):
		move_buttons[slot].text = "%d · %s · %d uses%s" % [slot+1, moves[slot].name, uses[slot], " · %.1fs" % cooldown if cooldown > 0 else ""]
		move_buttons[slot].disabled = paused or not outcome.is_empty() or uses[slot] == 0 or cooldown > 0 or not pending.is_empty()
