extends Control
## Standalone runtime authoring surface; all documents stay outside expedition saves.
const Document = preload("res://tools/sol_lab_document.gd")
const Body = preload("res://tools/sol_lab_body.gd")
const Variations = preload("res://tools/sol_lab_variations.gd")
const Panels = preload("res://tools/sol_lab_panels.gd")
const PARTS := ["Body", "Head", "Legs", "Tail", "Ears", "Wings", "Horns", "Fins", "Structure", "Core"]
const GROUPS := {"Body": ["body_length", "body_width", "body_height"], "Head": ["head_size", "muzzle_length", "head_offset"], "Core": ["core_size", "core_offset_x", "core_offset_y", "core_offset_z", "wisp_density", "wisp_length", "wisp_speed", "wisp_spread", "wisp_softness", "wisp_opacity", "wisp_glow"], "Legs": ["leg_length", "limb_spread"], "Tail": ["tail_length", "tail_angle"], "Ears": ["ear_length"], "Wings": ["wing_span"], "Horns": ["horn_length"], "Fins": ["fin_size"], "Structure": ["structure_size"]}
const FOLDER := "user://sol_lab"
var document: Dictionary = Document.fresh()
var saved: Dictionary = document.duplicate(true)
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var active_path := ""
var selected := "Body"
var updating := false
var yaw := 0.6
var pitch := 0.2
var distance := 5.5
var spinning := false
var viewport := SubViewport.new()
var preview := SubViewportContainer.new()
var camera := Camera3D.new()
var body := Body.new()
var name_field := LineEdit.new()
var notes := TextEdit.new()
var status := Label.new()
var title := Label.new()
var parameter_box := VBoxContainer.new()
var part_picker := ItemList.new()
var library := OptionButton.new()
var color_picker := ColorPickerButton.new()
var undo_button: Button
var redo_button: Button
var gallery := HBoxContainer.new()
var gallery_scroll := ScrollContainer.new()
var variation_label := Label.new()
var seed_control := SpinBox.new()
var strength_control := HSlider.new()
var candidates: Array[Dictionary] = []
var generation_parent: Dictionary = {}
var generation_setup: Dictionary = {}
var gallery_cameras: Array[Camera3D] = []
var panels: RefCounted
var workspace_tabs := TabContainer.new()
var section_picker := OptionButton.new()
var shape_dragging := false
var lab_session_path := FOLDER + "/editor_workspace.json"

func lab_session_snapshot() -> Dictionary:
	return {"version":1, "document":document.duplicate(true), "saved":saved.duplicate(true), "active_path":active_path, "selected":selected, "yaw":yaw, "pitch":pitch, "distance":distance, "spinning":spinning, "tab":workspace_tabs.current_tab, "undo":undo_stack.duplicate(true), "redo":redo_stack.duplicate(true)}

func lab_restore_session(state: Dictionary) -> bool:
	if state.get("version") != 1 or not Document.valid(state.get("document")): return false
	if not Document.valid(state.get("saved", state.document)): return false
	if not state.get("undo", []) is Array or not state.get("redo", []) is Array: return false
	for key in ["yaw", "pitch", "distance"]:
		var value: Variant = state.get(key, get(key))
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)): return false
	if float(state.get("distance", distance)) <= 0.0: return false
	document = Document.resolved(state.document)
	if document.has("exploration"): document.exploration.seed = int(document.exploration.seed)
	saved = state.get("saved", document).duplicate(true)
	active_path = str(state.get("active_path", ""))
	selected = str(state.get("selected", "Body"))
	if selected not in PARTS: selected = "Body"
	yaw = float(state.get("yaw", yaw))
	pitch = float(state.get("pitch", pitch))
	distance = float(state.get("distance", distance))
	spinning = bool(state.get("spinning", false))
	undo_stack.clear()
	redo_stack.clear()
	for value in state.get("undo", []):
		if Document.valid(value): undo_stack.append(value.duplicate(true))
	for value in state.get("redo", []):
		if Document.valid(value): redo_stack.append(value.duplicate(true))
	sync_controls()
	workspace_tabs.current_tab = clampi(int(state.get("tab", 0)), 0, workspace_tabs.get_tab_count()-1)
	section_picker.select(workspace_tabs.current_tab)
	move_camera()
	return true

func lab_save_workspace() -> bool:
	if not Document.valid(document): return false
	var state := lab_session_snapshot()
	# In-memory navigation keeps full history; restart storage has a finite budget.
	state.undo = state.undo.slice(maxi(0, state.undo.size()-128))
	state.redo = state.redo.slice(maxi(0, state.redo.size()-128))
	var file := FileAccess.open(lab_session_path, FileAccess.WRITE)
	if file == null:
		message("Could not save the editor workspace. Your draft remains open.")
		return false
	file.store_string(JSON.stringify(state, "  "))
	file.flush()
	var error := file.get_error()
	file.close()
	return error == OK

func lab_load_workspace() -> bool:
	if not FileAccess.file_exists(lab_session_path): return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(lab_session_path)) == OK and parser.data is Dictionary and lab_restore_session(parser.data): return true
	# Preserve an incompatible original; any new session gets a recovery sidecar.
	lab_session_path = FOLDER + "/editor_workspace_recovery_%d.json" % Time.get_ticks_usec()
	message("The previous editor workspace could not be restored. Its file is preserved; new work uses a recovery copy.")
	return false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var backdrop := ColorRect.new()
	backdrop.color = Color("111a24")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 16)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	title.add_theme_font_size_override("font_size", 26)
	layout.add_child(title)
	var toolbar := HFlowContainer.new()
	layout.add_child(toolbar)
	button(toolbar, "New draft", new_document)
	button(toolbar, "Bellroot concept test", open_bellroot_concept)
	button(toolbar, "Save revision", save_document)
	library.custom_minimum_size.x = 200
	toolbar.add_child(library)
	button(toolbar, "Open selected", open_selected)
	undo_button = button(toolbar, "Undo", undo)
	redo_button = button(toolbar, "Redo", redo)
	button(toolbar, "Capture + notes", capture)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(split)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 290
	split.add_child(sidebar)
	sidebar.add_child(section_picker)
	section_picker.item_selected.connect(func(index: int): workspace_tabs.current_tab = index)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	workspace_tabs.tabs_visible = false
	workspace_tabs.use_hidden_tabs_for_min_size = false
	workspace_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(workspace_tabs)
	var controls := VBoxContainer.new()
	controls.name = "Shape"
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 10)
	workspace_tabs.add_child(controls)
	label(controls, "DESIGN / modular anatomy")
	name_field.max_length = 80
	name_field.placeholder_text = "Design name"
	controls.add_child(name_field)
	name_field.text_changed.connect(func(value: String):
		if updating: return
		checkpoint()
		document.name = value
		refresh_title())
	label(controls, "Select a part here or click the creature")
	part_picker.custom_minimum_size.y = 140
	for part in PARTS: part_picker.add_item(part)
	controls.add_child(part_picker)
	part_picker.item_selected.connect(func(index: int): select_part(PARTS[index]))
	controls.add_child(parameter_box)
	button(controls, "Reset selected part", reset_part)
	var explore := VBoxContainer.new()
	explore.name = "Explore"
	workspace_tabs.add_child(explore)
	label(explore, "EXPLORE / keep the features you like")
	label(explore, "Seed (repeatable batch)")
	seed_control.min_value = 0
	seed_control.max_value = 999999
	seed_control.step = 1
	explore.add_child(seed_control)
	seed_control.value_changed.connect(func(value: float): set_exploration("seed", int(value)))
	explore.add_child(variation_label)
	strength_control.min_value = 0
	strength_control.max_value = 1
	strength_control.step = 0.01
	strength_control.custom_minimum_size.y = 28
	explore.add_child(strength_control)
	label(explore, "Lock features in Shape, then use Generate above the preview. Hover each candidate's button to compare values.")
	strength_control.set_meta("editing_gesture", false)
	strength_control.drag_started.connect(func():
		checkpoint()
		strength_control.set_meta("editing_gesture", true))
	strength_control.drag_ended.connect(func(_changed: bool): strength_control.set_meta("editing_gesture", false))
	strength_control.value_changed.connect(func(value: float): set_exploration("strength", value))
	label(controls, "Body color")
	controls.add_child(color_picker)
	color_picker.color_changed.connect(func(value: Color):
		if updating: return
		checkpoint()
		document.color = value.to_html(false)
		appearance_changed())
	notes.custom_minimum_size.y = 130
	notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	controls.add_child(notes)
	notes.text_changed.connect(func():
		if updating: return
		checkpoint()
		document.notes = notes.text.left(20000)
		refresh_title())
	var stage := VBoxContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(stage)
	var views := HFlowContainer.new()
	stage.add_child(views)
	button(views, "Perspective", func(): reset_camera())
	button(views, "Front", func(): yaw = 0.0; pitch = 0.0; move_camera())
	button(views, "Side", func(): yaw = PI * 0.5; pitch = 0.0; move_camera())
	var spin := CheckButton.new()
	spin.text = "Turntable"
	spin.toggled.connect(func(value: bool): spinning = value)
	views.add_child(spin)
	button(views, "Generate 6 variations", generate_variations)
	button(views, "Next seed + generate", next_variations)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.stretch = true
	preview.custom_minimum_size = Vector2(320, 180)
	stage.add_child(preview)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	preview.add_child(viewport)
	preview.gui_input.connect(preview_input)
	viewport.add_child(body)
	viewport.add_child(camera)
	camera.current = true
	camera.fov = 40.0
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("202e3e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c4d6e6")
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.shadow_enabled = true
	viewport.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "LabFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("344454")
	material.roughness = 1.0
	floor_mesh.material_override = material
	viewport.add_child(floor_mesh)
	gallery_scroll.custom_minimum_size.y = 165
	gallery_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	stage.add_child(gallery_scroll)
	gallery_scroll.add_child(gallery)
	gallery_scroll.visible = false
	label(stage, "Click: select part  •  Shift + left-drag: shape  •  Right-drag: orbit  •  Wheel: zoom  •  F: fit")
	label(stage, "Appearance authoring / use Review to export or apply a reviewed species design")
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status)
	panels = Panels.new()
	panels.build(self, workspace_tabs)
	for index in workspace_tabs.get_tab_count(): section_picker.add_item(workspace_tabs.get_tab_title(index))
	refresh_library()
	sync_controls()
	reset_camera()
	message("Ready. Shape a draft, add notes, then save a revision.")

func button(parent: Node, text: String, action: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 34
	control.pressed.connect(action)
	parent.add_child(control)
	return control

func label(parent: Node, text: String) -> void:
	var control := Label.new()
	control.text = text
	control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(control)

func checkpoint() -> void:
	undo_stack.append(document.duplicate(true))
	if undo_stack.size() > 100: undo_stack.pop_front()
	redo_stack.clear()

func refresh_title() -> void:
	title.text = "SOL LAB   /   " + document.name + ("  • unsaved" if document != saved else "")
	undo_button.disabled = undo_stack.is_empty()
	redo_button.disabled = redo_stack.is_empty()

func open_bellroot_concept() -> void:
	var window := Window.new()
	window.name = "BellrootConceptWindow"
	window.title = "Bellroot first-form concept / isolated test"
	window.size = Vector2i(1100, 760)
	add_child(window)
	var container := SubViewportContainer.new()
	container.stretch = true
	window.add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var world := SubViewport.new()
	world.size = window.size
	world.own_world_3d = true
	world.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(world)
	world.add_child(preload("res://scenes/bellroot_concept_preview.tscn").instantiate())
	window.close_requested.connect(window.queue_free)
	window.popup_centered()

func rebuild() -> void:
	body.build(document, selected)
	refresh_title()

func sync_controls() -> void:
	updating = true
	name_field.text = document.name
	notes.text = document.notes
	color_picker.color = Color.html(document.color)
	var setup: Dictionary = document.get("exploration", Variations.settings())
	seed_control.set_value_no_signal(setup.seed)
	strength_control.set_value_no_signal(setup.strength)
	variation_label.text = "Variation range / %d%%" % roundi(setup.strength * 100)
	updating = false
	select_part(selected)
	if panels != null: panels.sync()
	if setup.has("parent"):
		generation_parent = setup.parent.duplicate(true)
		generation_setup = setup.duplicate(true)
		candidates = Variations.generate(generation_parent, generation_setup)
		draw_gallery()
	else:
		clear_gallery()

func select_part(part: String) -> void:
	selected = part
	part_picker.select(PARTS.find(part))
	part_picker.ensure_current_is_visible()
	for child in parameter_box.get_children():
		parameter_box.remove_child(child)
		child.queue_free()
	label(parameter_box, "CORE / placement & wisps" if part == "Core" else part.to_upper() + " / proportions")
	for key: String in GROUPS[part]:
		var readout := Label.new()
		parameter_box.add_child(readout)
		var slider := HSlider.new()
		var bounds := Document.numeric_bounds(document, key)
		slider.min_value = bounds[0]
		slider.max_value = bounds[1]
		slider.step = 0.01
		if key == "wisp_density": slider.step = 1
		slider.value = document[key]
		slider.custom_minimum_size = Vector2(240, 28)
		readout.text = "%s  %.2f" % [key.replace("_", " ").capitalize(), slider.value]
		parameter_box.add_child(slider)
		var lock := CheckBox.new()
		lock.text = "Lock " + key.replace("_", " ")
		lock.clip_text = true
		lock.tooltip_text = "Keep " + key.replace("_", " ") + " when generating variations."
		var setup: Dictionary = document.get("exploration", Variations.settings())
		lock.button_pressed = setup.locks.get(key, false)
		parameter_box.add_child(lock)
		lock.toggled.connect(func(enabled: bool):
			checkpoint()
			var config: Dictionary = document.get("exploration", Variations.settings()).duplicate(true)
			config.locks[key] = enabled
			config.erase("parent")
			document.exploration = config
			clear_gallery()
			refresh_title())
		slider.set_meta("editing_gesture", false)
		slider.drag_started.connect(func():
			checkpoint()
			slider.set_meta("editing_gesture", true))
		slider.drag_ended.connect(func(_changed: bool): slider.set_meta("editing_gesture", false))
		slider.value_changed.connect(func(value: float):
			if not slider.get_meta("editing_gesture"): checkpoint()
			document[key] = value
			readout.text = "%s  %.2f" % [key.replace("_", " ").capitalize(), value]
			appearance_changed())
	rebuild()
	if panels != null: panels.sync()

func reset_part() -> void:
	checkpoint()
	for key in GROUPS[selected]:
		var bounds := Document.numeric_bounds(document, key)
		document[key] = clampf(Document.RANGES[key][2], bounds[0], bounds[1])
	appearance_changed()
	sync_controls()

func appearance_changed() -> void:
	if document.has("exploration"): document.exploration.erase("parent")
	if document.has("design"): document.design.stage = "draft"
	clear_gallery()
	rebuild()

func undo() -> void:
	if undo_stack.is_empty(): return
	redo_stack.append(document.duplicate(true))
	document = undo_stack.pop_back()
	sync_controls()

func redo() -> void:
	if redo_stack.is_empty(): return
	undo_stack.append(document.duplicate(true))
	document = redo_stack.pop_back()
	sync_controls()

func save_document() -> bool:
	if not Document.valid(document):
		message("Give this draft a name (1–80 characters) before saving.")
		return false
	var path := FOLDER.path_join("draft_%d_%d.json" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()])
	if Document.write(path, document) != OK:
		message("Could not save. Your current draft is still open.")
		return false
	active_path = path
	saved = document.duplicate(true)
	refresh_library()
	refresh_title()
	message("Saved revision: " + ProjectSettings.globalize_path(path))
	return true

func preserve_dirty() -> bool:
	return save_document() if document != saved else true

func new_document() -> void:
	if not preserve_dirty(): return
	document = Document.fresh()
	saved = document.duplicate(true)
	active_path = ""
	undo_stack.clear()
	redo_stack.clear()
	sync_controls()
	message("New draft. Previous changes were saved before switching.")

func refresh_library() -> void:
	library.clear()
	var files := DirAccess.get_files_at(FOLDER)
	files.sort()
	files.reverse()
	for file in files:
		if not file.begins_with("draft_") or not file.ends_with(".json"): continue
		var path := FOLDER.path_join(file)
		var value := Document.read(path)
		if value.is_empty(): continue
		var stamp := int(file.trim_prefix("draft_").get_slice("_", 0))
		library.add_item(value.name + " / " + Time.get_datetime_string_from_unix_time(stamp).replace("T", " ") + " UTC")
		library.set_item_metadata(library.item_count - 1, path)
		if path == active_path: library.select(library.item_count - 1)

func open_selected() -> void:
	if library.selected < 0: return
	var path: String = library.get_item_metadata(library.selected)
	var value := Document.read(path)
	if value.is_empty():
		message("This revision cannot be read. Current draft preserved.")
		return
	if not preserve_dirty(): return
	document = value
	saved = value.duplicate(true)
	active_path = path
	undo_stack.clear()
	redo_stack.clear()
	sync_controls()
	message("Opened " + value.name)

func reset_camera() -> void:
	yaw = 0.95
	pitch = 0.2
	var bounds: AABB = body.bounds()
	distance = maxf(4.5, bounds.size.length() * 1.7)
	move_camera()

func move_camera() -> void:
	var target: Vector3 = body.bounds().get_center()
	camera.position = target + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.look_at(target)
	for other in gallery_cameras:
		other.transform = camera.transform
		other.fov = camera.fov

func set_exploration(key: String, value: Variant) -> void:
	if updating: return
	if key != "strength" or not strength_control.get_meta("editing_gesture"): checkpoint()
	var setup: Dictionary = document.get("exploration", Variations.settings()).duplicate(true)
	setup[key] = value
	setup.erase("parent")
	document.exploration = setup
	variation_label.text = "Variation range / %d%%" % roundi(setup.strength * 100)
	clear_gallery()
	refresh_title()

func clear_gallery() -> void:
	candidates.clear()
	gallery_cameras.clear()
	for child in gallery.get_children():
		gallery.remove_child(child)
		child.queue_free()
	gallery_scroll.visible = false

func next_variations() -> void:
	seed_control.value = fposmod(seed_control.value + 1, 1000000)
	generate_variations()

func generate_variations() -> void:
	if not Document.valid(document):
		message("Give the draft a valid name before generating variations.")
		return
	checkpoint()
	generation_parent = document.duplicate(true)
	generation_parent.erase("exploration")
	generation_setup = document.get("exploration", Variations.settings()).duplicate(true)
	generation_setup.parent = generation_parent.duplicate(true)
	document.exploration = generation_setup.duplicate(true)
	candidates = Variations.generate(generation_parent, generation_setup)
	draw_gallery()
	refresh_title()
	message("Six variations from this draft. Use one to continue shaping; Undo restores the parent.")

func draw_gallery() -> void:
	gallery_cameras.clear()
	for child in gallery.get_children():
		gallery.remove_child(child)
		child.queue_free()
	gallery_scroll.visible = not candidates.is_empty()
	for index in range(-1, candidates.size()):
		var card := VBoxContainer.new()
		gallery.add_child(card)
		var container := SubViewportContainer.new()
		container.custom_minimum_size = Vector2(170, 115)
		container.stretch = true
		card.add_child(container)
		var view := SubViewport.new()
		view.own_world_3d = true
		view.render_target_update_mode = SubViewport.UPDATE_ONCE
		container.add_child(view)
		var specimen := Body.new()
		view.add_child(specimen)
		var recipe: Dictionary = generation_parent if index == -1 else candidates[index]
		specimen.build(recipe, "")
		var lens := Camera3D.new()
		view.add_child(lens)
		lens.current = true
		gallery_cameras.append(lens)
		# Share the same lighting resource, with independent worlds and cameras.
		var environment := WorldEnvironment.new()
		environment.environment = viewport.find_children("*", "WorldEnvironment", false, false)[0].environment
		view.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, -30, 0)
		view.add_child(light)
		view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		var caption := "Restore batch parent" if index == -1 else "Use variation %d" % (index + 1)
		var action := button(card, caption, func(): adopt_variation(index))
		var changes := PackedStringArray()
		for key in Document.RANGES:
			if not is_equal_approx(recipe[key], generation_parent[key]):
				changes.append("%s: %.2f → %.2f" % [key.replace("_", " "), generation_parent[key], recipe[key]])
		action.tooltip_text = "\n".join(changes) if not changes.is_empty() else "Identical to parent: all traits locked or range is zero."
	move_camera()

func adopt_variation(index: int) -> void:
	if index < -1 or index >= candidates.size() or generation_parent.is_empty(): return
	checkpoint()
	# Preserve current notes, name, color and exploration; adopt only proportions.
	var recipe: Dictionary = generation_parent if index == -1 else candidates[index]
	for key in Document.RANGES: document[key] = recipe[key]
	if document.has("design"): document.design.stage = "draft"
	sync_controls()
	message("Restored batch parent." if index == -1 else "Using variation %d. Edit it, save a revision, or generate a new batch from it." % (index + 1))

func preview_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and shape_dragging:
		var keys: Array = GROUPS[selected]
		var key: String = keys[0]
		var bounds := Document.numeric_bounds(document, key)
		document[key] = snappedf(clampf(document[key] + event.relative.x * 0.005 - event.relative.y * 0.002, bounds[0], bounds[1]), 0.01)
		appearance_changed()
		return
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
		yaw -= event.relative.x * 0.01
		pitch = clampf(pitch + event.relative.y * 0.01, -0.15, 1.2)
		move_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(2.5, distance - 0.3)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(12.0, distance + 0.3)
		if event.button_index == MOUSE_BUTTON_LEFT:
			var part := body.pick(camera, event.position * Vector2(viewport.size) / preview.size)
			if not part.is_empty(): select_part(part)
			if event.shift_pressed:
				checkpoint()
				shape_dragging = true
		move_camera()
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if shape_dragging:
			shape_dragging = false
			sync_controls()

func _process(delta: float) -> void:
	if panels != null: panels.tick(delta)
	if spinning:
		yaw += delta * 0.35
		move_camera()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit: return
	if event.keycode == KEY_F: reset_camera()
	if event.ctrl_pressed and event.keycode == KEY_S: save_document()
	if event.ctrl_pressed and event.keycode == KEY_Z: undo()
	if event.ctrl_pressed and event.keycode == KEY_Y: redo()

func capture() -> void:
	var snapshot := document.duplicate(true)
	var view := {"yaw": yaw, "pitch": pitch, "distance": distance, "selected_part": selected}
	await RenderingServer.frame_post_draw
	var path := FOLDER.path_join("review_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()])
	var image_result := viewport.get_texture().get_image().save_png(path + ".png")
	var file := FileAccess.open(path + ".json", FileAccess.WRITE)
	if file == null or image_result != OK:
		message("Capture could not be completed. Draft preserved.")
		return
	file.store_string(JSON.stringify({"document": snapshot, "view": view, "motion": {"exercise": panels.exercise, "seconds": panels.elapsed, "speed": panels.speed, "stride": panels.stride, "lift": panels.lift}, "diagnostics": body.diagnostics()}, "\t"))
	file.close()
	message("Review image + recipe + notes: " + ProjectSettings.globalize_path(path))

func message(text: String) -> void:
	status.text = text

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not preserve_dirty():
			message("Save failed. Correct the name or save the draft before closing.")
			return
		get_tree().quit()
