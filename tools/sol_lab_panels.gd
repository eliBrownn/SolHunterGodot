extends RefCounted
## Sol Lab workflow panels. All edits go through the lab's document and undo history.
const Recipe = preload("res://scripts/sols/presentation/sol_design_recipe.gd")
const Library = preload("res://scripts/sols/presentation/sol_design_library.gd")
const View = preload("res://scripts/sols/presentation/sol_design_view.gd")
const Shapes = preload("res://tools/sol_lab_shapes.gd")
var lab: Control
var updating := false
var controls: Dictionary = {}
var mode_picker: OptionButton
var plan_picker: OptionButton
var affinity_picker: OptionButton
var constraint_picker: OptionButton
var low := HSlider.new()
var high := HSlider.new()
var low_label := Label.new()
var high_label := Label.new()
var part_notes := TextEdit.new()
var reference := TextureRect.new()
var references := OptionButton.new()
var favorites := OptionButton.new()
var target := OptionButton.new()
var stage_picker: OptionButton
var measurements := Label.new()
var file_dialog := FileDialog.new()
var exercise := "idle"
var elapsed := 0.0
var paused := false
var speed := 0.3
var stride := 0.12
var lift := 0.08
var rate := 1.0
var scrub: HSlider
var affinity_root := Node3D.new()
var show_affinity := false
var baseline: Dictionary = {}
var baseline_view: Dictionary = {}
var baseline_overlay := TextureRect.new()
var scale_reference := Node3D.new()
var class_picker: OptionButton
var shape_picker := OptionButton.new()
var structure_picker: OptionButton
var core_picker: OptionButton

func page(tabs: TabContainer, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = title
	box.add_theme_constant_override("separation", 10)
	tabs.add_child(box)
	return box

func option(parent: Node, label_text: String, values: Array, action: Callable) -> OptionButton:
	lab.label(parent, label_text)
	var picker := OptionButton.new()
	picker.clip_text = true
	for value in values: picker.add_item(str(value).replace("_", " ").capitalize())
	parent.add_child(picker)
	picker.item_selected.connect(func(index: int):
		if not updating: action.call(index))
	return picker

func scalar(parent: Node, key: String, label_text: String, minimum: float, maximum: float, value: float, action: Callable) -> HSlider:
	var readout := Label.new()
	parent.add_child(readout)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size.y = 28
	readout.text = "%s  %.2f" % [label_text, value]
	parent.add_child(slider)
	slider.value_changed.connect(func(number: float):
		readout.text = "%s  %.2f" % [label_text, number]
		if not updating: action.call(number))
	controls[key] = slider
	controls[key + "_readout"] = readout
	return slider

func build(owner: Control, tabs: TabContainer) -> void:
	lab = owner
	var body_library := page(tabs, "Bodies")
	var names := []
	for row in Shapes.CLASSES: names.append(row[1])
	class_picker = option(body_library, "Class / three editable body shapes each", names, func(_index: int): refresh_shapes())
	body_library.add_child(shape_picker)
	lab.button(body_library, "Start from selected body shape", apply_shape)
	lab.label(body_library, "54 anatomy studies across all 18 classes. These are starting points for your designs; selecting one does not admit a roster species or set its affinity.")
	refresh_shapes()
	var species := page(tabs, "Species")
	mode_picker = option(species, "Editing scope", ["Species", "Individual"], change_mode)
	lab.label(species, "Individual mode inherits anatomy and variation bounds. Switching back makes the current appearance a new species draft.")
	plan_picker = option(species, "Body plan", Recipe.PLANS, func(index: int): set_design("body_plan", Recipe.PLANS[index]))
	structure_picker = option(species, "Structural anatomy", Recipe.STRUCTURES, func(index: int): set_design("structure", Recipe.STRUCTURES[index]))
	core_picker = option(species, "Visual core anchor / separate from anatomy", ["chest", "head", "back", "root", "tail", "free"], func(index: int): set_design("core_anchor", ["chest", "head", "back", "root", "tail", "free"][index]))
	for module: String in Recipe.MODULES:
		var check := CheckBox.new()
		check.text = module.capitalize()
		species.add_child(check)
		controls["module_" + module] = check
		check.toggled.connect(func(enabled: bool):
			if updating: return
			var modules: Dictionary = Recipe.design(lab.document).modules.duplicate(true)
			modules[module] = enabled
			set_design("modules", modules))
	affinity_picker = option(species, "Individual affinity / independent of skin", Recipe.AFFINITIES, func(index: int): set_design("affinity", Recipe.AFFINITIES[index]))
	var aura := CheckBox.new()
	aura.text = "Preview affinity markers"
	species.add_child(aura)
	aura.toggled.connect(func(enabled: bool): show_affinity = enabled; refresh_affinity())
	lab.label(species, "Species variation bounds")
	constraint_picker = option(species, "Feature", Recipe.RANGES.keys(), func(_index: int): sync_bounds())
	species.add_child(low_label)
	species.add_child(low)
	species.add_child(high_label)
	species.add_child(high)
	low.step = 0.01
	high.step = 0.01
	low.value_changed.connect(func(number: float): change_bound(true, number))
	high.value_changed.connect(func(number: float): change_bound(false, number))
	lab.button(species, "Reset selected bounds", reset_bounds)
	var surfaces := page(tabs, "Surface")
	var head_color := ColorPickerButton.new()
	controls.core_tint = head_color
	lab.label(surfaces, "Visual core tint / independent of affinity")
	surfaces.add_child(head_color)
	head_color.color_changed.connect(func(value: Color):
		if not updating: set_design("core_tint", value.to_html(false)))
	var accent := ColorPickerButton.new()
	controls.accent = accent
	lab.label(surfaces, "Accent / markings color")
	surfaces.add_child(accent)
	accent.color_changed.connect(func(value: Color):
		if not updating: set_design("accent", value.to_html(false)))
	controls.pattern = option(surfaces, "Markings", ["plain", "stripes", "spots", "bands"], func(index: int): set_design("pattern", ["plain", "stripes", "spots", "bands"][index]))
	scalar(surfaces, "roughness", "Roughness", 0, 1, 0.85, func(value: float): set_design("roughness", value))
	var symmetry := CheckBox.new()
	symmetry.text = "Symmetrical proportions"
	controls.symmetry = symmetry
	surfaces.add_child(symmetry)
	symmetry.toggled.connect(func(enabled: bool):
		if not updating: set_design("symmetry", enabled))
	scalar(surfaces, "asymmetry", "Right-side asymmetry", 0, 1, 0, func(value: float): set_design("asymmetry", value))
	var silhouette := CheckBox.new()
	silhouette.text = "Silhouette view"
	surfaces.add_child(silhouette)
	silhouette.toggled.connect(func(enabled: bool): lab.body.silhouette = enabled; lab.rebuild())
	var motion := page(tabs, "Motion")
	option(motion, "Preview exercise", ["idle", "walk", "run", "turns", "slope", "flight", "swim", "signature", "attack", "hit"], func(index: int):
		exercise = ["idle", "walk", "run", "turns", "slope", "flight", "swim", "signature", "attack", "hit"][index]
		elapsed = 0
		lab.body.ground_motion.reset())
	var pause := CheckBox.new()
	pause.text = "Pause motion / scrub pose"
	motion.add_child(pause)
	pause.toggled.connect(func(enabled: bool): paused = enabled)
	scrub = scalar(motion, "scrub", "Pose time", 0, 8, 0, func(value: float): elapsed = value; lab.body.ground_motion.reset())
	scalar(motion, "rate", "Playback speed", 0.1, 2, 1, func(value: float): rate = value)
	scalar(motion, "speed", "Movement speed", 0.05, 2, 0.3, func(value: float): speed = value)
	scalar(motion, "stride", "Step distance", 0.04, 0.3, 0.12, func(value: float): set_motion("stride", value))
	scalar(motion, "lift", "Foot lift", 0, 0.15, 0.08, func(value: float): set_motion("lift", value))
	scalar(motion, "idle_rate", "Idle cycles / second", 0, 2, 0.6, func(value: float): set_motion("idle_rate", value))
	scalar(motion, "wingbeat_rate", "Wingbeats / second", 1, 6, 3, func(value: float): set_motion("wingbeat_rate", value))
	scalar(motion, "swim_rate", "Swim strokes / second", 0.5, 3, 1.5, func(value: float): set_motion("swim_rate", value))
	var skeleton := CheckBox.new()
	skeleton.text = "Show joint markers"
	motion.add_child(skeleton)
	skeleton.toggled.connect(func(enabled: bool): lab.body.skeleton = enabled; lab.rebuild())
	var ruler := CheckBox.new()
	ruler.text = "Show one-metre scale reference"
	ruler.button_pressed = true
	motion.add_child(ruler)
	ruler.toggled.connect(func(enabled: bool): scale_reference.visible = enabled)
	measurements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	motion.add_child(measurements)
	lab.label(motion, "Movement exercises are art previews; wings and fins do not grant gameplay traversal.")
	var review := page(tabs, "Review")
	lab.label(review, "Selected part / design annotation")
	part_notes.custom_minimum_size.y = 100
	part_notes.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	review.add_child(part_notes)
	part_notes.text_changed.connect(func():
		if updating: return
		lab.checkpoint()
		var settings := Recipe.design(lab.document)
		settings.annotations[lab.selected] = part_notes.text.left(5000)
		lab.document.design = settings
		lab.refresh_title())
	lab.label(review, "General design notes")
	lab.notes.reparent(review)
	lab.button(review, "Attach reference image", func(): file_dialog.popup_centered_ratio(0.7))
	review.add_child(references)
	references.item_selected.connect(func(_index: int): show_reference())
	lab.button(review, "Remove selected reference", remove_reference)
	reference.custom_minimum_size = Vector2(200, 150)
	reference.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reference.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	review.add_child(reference)
	lab.button(review, "Set comparison baseline", set_baseline)
	var comparison := CheckBox.new()
	comparison.text = "Show baseline image"
	review.add_child(comparison)
	comparison.toggled.connect(func(enabled: bool): baseline_overlay.visible = enabled and baseline_overlay.texture != null)
	lab.button(review, "Restore comparison baseline", func():
		if baseline.is_empty(): return
		lab.checkpoint()
		lab.document = baseline.duplicate(true)
		lab.sync_controls()
		lab.yaw = baseline_view.yaw
		lab.pitch = baseline_view.pitch
		lab.distance = baseline_view.distance
		lab.move_camera())
	lab.button(review, "Favorite current appearance", favorite)
	review.add_child(favorites)
	lab.button(review, "Open selected favorite", open_favorite)
	stage_picker = option(review, "Design stage", ["draft", "candidate", "reviewed"], func(index: int): set_design("stage", ["draft", "candidate", "reviewed"][index]))
	lab.label(review, "Gameplay appearance target / existing species")
	target.clip_text = true
	target.add_item("Scene export only / new species draft")
	target.set_item_metadata(0, "")
	var catalog: Resource = load("res://resources/sol_species/catalog.tres")
	for entry in catalog.entries:
		target.add_item(entry.display_name)
		target.set_item_metadata(target.item_count - 1, entry.species_id)
	review.add_child(target)
	target.item_selected.connect(func(index: int):
		if not updating: set_design("target_species", target.get_item_metadata(index)))
	lab.button(review, "Export editable scene + recipe", func(): export_design(false))
	lab.button(review, "Apply reviewed appearance to target", func(): export_design(true))
	lab.button(review, "Restore target's original appearance", clear_override)
	lab.label(review, "Applying affects newly created views of this species. Existing actors refresh on their next normal rebuild. Stats, identity and movement permissions remain catalog-owned.")
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Reference images"])
	lab.add_child(file_dialog)
	file_dialog.file_selected.connect(attach_reference)
	lab.viewport.add_child(affinity_root)
	lab.viewport.add_child(scale_reference)
	var pole := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.025, 1, 0.025)
	pole.mesh = box
	pole.position.y = 0.5
	var ruler_material := StandardMaterial3D.new()
	ruler_material.albedo_color = Color("e2d3a5")
	pole.material_override = ruler_material
	scale_reference.add_child(pole)
	var unit := Label3D.new()
	unit.text = "1 m"
	unit.position.y = 1.1
	unit.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	unit.font_size = 48
	unit.pixel_size = 0.003
	scale_reference.add_child(unit)
	lab.preview.add_child(baseline_overlay)
	baseline_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	baseline_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	baseline_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	baseline_overlay.stretch_mode = TextureRect.STRETCH_SCALE
	baseline_overlay.hide()
	sync()

func set_design(key: String, value: Variant) -> void:
	if updating: return
	lab.checkpoint()
	var settings := Recipe.design(lab.document)
	settings[key] = value
	if key != "stage": settings.stage = "draft"
	lab.document.design = settings
	if key == "stage": lab.refresh_title()
	else: lab.appearance_changed()
	sync()

func change_mode(index: int) -> void:
	lab.checkpoint()
	var settings := Recipe.design(lab.document)
	if index == 1:
		settings.species_base = Recipe.species_snapshot(lab.document)
		settings.mode = "individual"
	else:
		settings.mode = "species"
		settings.erase("species_base")
	settings.stage = "draft"
	lab.document.design = settings
	lab.appearance_changed()
	lab.sync_controls()

func sync_bounds() -> void:
	updating = true
	var key: String = Recipe.RANGES.keys()[maxi(0, constraint_picker.selected)]
	var bounds := Recipe.numeric_bounds(lab.document, key)
	for slider in [low, high]:
		slider.min_value = Recipe.RANGES[key][0]
		slider.max_value = Recipe.RANGES[key][1]
		slider.step = 1 if key == "wisp_density" else 0.01
		slider.editable = Recipe.design(lab.document).mode == "species"
	low.set_value_no_signal(bounds[0])
	high.set_value_no_signal(bounds[1])
	low_label.text = "Minimum  %.2f" % bounds[0]
	high_label.text = "Maximum  %.2f" % bounds[1]
	updating = false

func change_bound(is_low: bool, number: float) -> void:
	if updating: return
	var key: String = Recipe.RANGES.keys()[constraint_picker.selected]
	var settings := Recipe.design(lab.document)
	if settings.mode != "species": return
	var bounds := Recipe.numeric_bounds(lab.document, key).duplicate()
	if is_low: bounds[0] = minf(number, bounds[1])
	else: bounds[1] = maxf(number, bounds[0])
	lab.checkpoint()
	settings.constraints[key] = bounds
	settings.stage = "draft"
	lab.document.design = settings
	lab.document[key] = clampf(lab.document[key], bounds[0], bounds[1])
	lab.appearance_changed()
	lab.sync_controls()

func reset_bounds() -> void:
	if Recipe.design(lab.document).mode != "species": return
	var key: String = Recipe.RANGES.keys()[constraint_picker.selected]
	var constraints: Dictionary = Recipe.design(lab.document).constraints.duplicate(true)
	constraints.erase(key)
	set_design("constraints", constraints)
	lab.select_part(lab.selected)

func sync() -> void:
	updating = true
	var settings := Recipe.design(lab.document)
	mode_picker.select(1 if settings.mode == "individual" else 0)
	plan_picker.select(Recipe.PLANS.find(settings.body_plan))
	plan_picker.disabled = settings.mode == "individual"
	structure_picker.select(Recipe.STRUCTURES.find(settings.structure))
	structure_picker.disabled = settings.mode == "individual"
	core_picker.select(["chest", "head", "back", "root", "tail", "free"].find(settings.core_anchor))
	core_picker.disabled = settings.mode == "individual"
	for module in Recipe.MODULES:
		controls["module_" + module].set_pressed_no_signal(settings.modules.get(module, false))
		controls["module_" + module].disabled = settings.mode == "individual"
	affinity_picker.select(Recipe.AFFINITIES.find(settings.affinity))
	affinity_picker.disabled = settings.mode != "individual"
	controls.accent.color = Color.html(settings.accent)
	controls.core_tint.color = Color.html(settings.core_tint)
	controls.pattern.select(["plain", "stripes", "spots", "bands"].find(settings.pattern))
	controls.roughness.value = settings.roughness
	controls.symmetry.set_pressed_no_signal(settings.symmetry)
	controls.asymmetry.value = settings.asymmetry
	stride = settings.motion.stride
	lift = settings.motion.lift
	for key in ["stride", "lift", "idle_rate", "wingbeat_rate", "swim_rate"]: controls[key].value = settings.motion[key]
	part_notes.text = settings.annotations.get(lab.selected, "")
	stage_picker.select(["draft", "candidate", "reviewed"].find(settings.stage))
	for index in target.item_count:
		if target.get_item_metadata(index) == settings.target_species: target.select(index)
	references.clear()
	for path in settings.references:
		references.add_item(path.get_file())
		references.set_item_metadata(references.item_count - 1, path)
	favorites.clear()
	for index in settings.favorites.size(): favorites.add_item("Favorite %d" % (index + 1))
	updating = false
	sync_bounds()
	show_reference()
	refresh_affinity()

func refresh_affinity() -> void:
	for child in affinity_root.get_children():
		affinity_root.remove_child(child)
		child.queue_free()
	if not show_affinity: return
	var visual: Resource = load("res://resources/sol_visual_settings.tres") if ResourceLoader.exists("res://resources/sol_visual_settings.tres") else SolVisualSettings.new()
	var color: Color = visual.color_for(Recipe.design(lab.document).affinity)
	for index in 8:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		marker.mesh = sphere
		marker.position = Vector3(cos(index * TAU / 8), 0.1, sin(index * TAU / 8)) * 1.3
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		marker.material_override = material
		affinity_root.add_child(marker)

func tick(delta: float) -> void:
	if not paused: elapsed += delta * rate
	scrub.set_value_no_signal(fposmod(elapsed, 8))
	controls.scrub_readout.text = "Pose time  %.2f" % fposmod(elapsed, 8)
	lab.viewport.get_node("LabFloor").rotation.x = -atan(0.15) if exercise == "slope" else 0.0
	lab.body.animate_visual(elapsed, exercise, speed * (2 if exercise == "run" else 1), stride, lift)
	var readings: Dictionary = lab.body.diagnostics()
	scale_reference.position.x = lab.body.bounds().end.x + 0.25
	measurements.text = "%d parts / %d joints / %d supports\nHeight %.2f m / contact error %.3f m" % [readings.parts, readings.joints, readings.supports, readings.height, readings.max_contact_error]
	var modules: Dictionary = Recipe.design(lab.document).modules
	if exercise == "flight" and not modules.get("wings", false): measurements.text += "\nFlight pose needs wings for useful review."
	if readings.max_contact_error > 0.05: measurements.text += "\nContact exceeds 5 cm: adjust proportions or stride."

func attach_reference(path: String) -> void:
	var settings := Recipe.design(lab.document)
	if settings.references.size() >= 12: lab.message("Reference limit: remove an image before adding more."); return
	var image := Image.load_from_file(path)
	if image == null or image.is_empty(): lab.message("Could not read this reference image."); return
	if image.get_width() > 2048 or image.get_height() > 2048:
		var ratio := minf(2048.0 / image.get_width(), 2048.0 / image.get_height())
		image.resize(maxi(1, roundi(image.get_width() * ratio)), maxi(1, roundi(image.get_height() * ratio)))
	var folder := "user://sol_lab/references"
	DirAccess.make_dir_recursive_absolute(folder)
	var destination := folder.path_join("reference_%d.png" % Time.get_ticks_usec())
	if image.save_png(destination) != OK: lab.message("Could not copy this reference into the Sol library."); return
	settings.references.append(destination)
	set_design("references", settings.references)

func show_reference() -> void:
	reference.texture = null
	if references.selected < 0: return
	var image := Image.load_from_file(references.get_item_metadata(references.selected))
	if image != null: reference.texture = ImageTexture.create_from_image(image)

func remove_reference() -> void:
	if references.selected < 0: return
	var paths: Array = Recipe.design(lab.document).references.duplicate()
	paths.remove_at(references.selected)
	set_design("references", paths) # Earlier revisions may still reference the copied image.

func favorite() -> void:
	var settings := Recipe.design(lab.document)
	if settings.favorites.size() >= 24: lab.message("This draft has 24 favorites. Save a new branch to explore more."); return
	var snapshot: Dictionary = lab.document.duplicate(true)
	snapshot.erase("design")
	snapshot.erase("exploration")
	var appearance := {}
	for key in ["body_plan", "structure", "class_id", "core_anchor", "modules", "accent", "core_tint", "pattern", "roughness", "symmetry", "asymmetry"]: appearance[key] = settings[key]
	snapshot.appearance = appearance
	settings.favorites.append(snapshot)
	set_design("favorites", settings.favorites)

func open_favorite() -> void:
	if favorites.selected < 0: return
	var snapshot: Dictionary = Recipe.design(lab.document).favorites[favorites.selected]
	var candidate: Dictionary = lab.document.duplicate(true)
	for key in Recipe.RANGES: candidate[key] = snapshot.get(key, Recipe.RANGES[key][2])
	candidate.color = snapshot.color
	var settings := Recipe.design(candidate)
	settings.merge(snapshot.get("appearance", {}), true)
	candidate.design = settings
	if not Recipe.valid(candidate): lab.message("This favorite is outside the individual's species rules. Switch to Species to explore it."); return
	lab.checkpoint()
	lab.document = candidate
	lab.appearance_changed()
	lab.sync_controls()

func export_design(apply: bool) -> Dictionary:
	var settings := Recipe.design(lab.document)
	if not Recipe.valid(lab.document): lab.message("The design has invalid anatomy or inherited bounds."); return {}
	if apply and (settings.stage != "reviewed" or settings.target_species.is_empty() or settings.mode != "species"):
		lab.message("Choose an existing species target and mark a species design Reviewed before applying its appearance.")
		return {}
	if apply:
		var catalog: Resource = load("res://resources/sol_species/catalog.tres")
		var entry: Resource = catalog.find(settings.target_species)
		if entry == null or (not settings.class_id.is_empty() and settings.class_id != entry.class_id):
			lab.message("The selected appearance class must match the existing target species class.")
			return {}
	var folder := Library.ROOT.path_join("design_%d" % Time.get_ticks_usec())
	if DirAccess.make_dir_recursive_absolute(folder) != OK: lab.message("Could not create the export folder."); return {}
	var model := View.new()
	model.appearance_recipe = Recipe.species_snapshot(lab.document)
	model.appearance_recipe.design.stage = settings.stage
	model.step_distance = settings.motion.stride
	model.step_lift = settings.motion.lift
	model.idle_rate = settings.motion.idle_rate
	model.wingbeat_rate = settings.motion.wingbeat_rate
	model.swim_stroke_rate = settings.motion.swim_rate
	var packed := PackedScene.new()
	var result := packed.pack(model)
	model.free()
	var scene_path := folder.path_join("appearance.tscn")
	if result != OK or ResourceSaver.save(packed, scene_path) != OK or Recipe.write(folder.path_join("recipe.json"), lab.document) != OK:
		lab.message("Could not finish the appearance export.")
		return {}
	if apply and Library.set_override(settings.target_species, scene_path) != OK:
		lab.message("Exported the scene, but could not apply its local appearance override.")
		return {}
	var reference_files := []
	for path in settings.references:
		var image := Image.load_from_file(path)
		var filename := "reference_%d.png" % reference_files.size()
		if image != null and image.save_png(folder.path_join(filename)) == OK: reference_files.append(filename)
	var review := {"name": lab.document.name, "class_id": settings.class_id, "stage": settings.stage, "notes": lab.document.notes, "annotations": settings.annotations, "references": reference_files, "scene": "appearance.tscn", "recipe": "recipe.json", "view": {"yaw": lab.yaw, "pitch": lab.pitch, "distance": lab.distance}}
	if DisplayServer.get_name() != "headless":
		var image: Image = lab.viewport.get_texture().get_image()
		if image != null and image.save_png(folder.path_join("preview.png")) == OK: review["preview"] = "preview.png"
	var review_file := FileAccess.open(folder.path_join("review.json"), FileAccess.WRITE)
	if review_file != null:
		review_file.store_string(JSON.stringify(review, "\t"))
		review_file.close()
	lab.message(("Applied local appearance. " if apply else "Exported candidate. ") + ProjectSettings.globalize_path(folder))
	return {"scene": scene_path, "recipe": folder.path_join("recipe.json")}

func clear_override() -> void:
	var id: String = Recipe.design(lab.document).target_species
	if id.is_empty(): return
	if Library.set_override(id, "") == OK: lab.message("Restored the target's original appearance for newly created views.")

func refresh_shapes() -> void:
	shape_picker.clear()
	var row: Array = Shapes.CLASSES[maxi(0, class_picker.selected)]
	for preset in Shapes.presets(row[0]): shape_picker.add_item(preset.name)

func apply_shape() -> void:
	var row: Array = Shapes.CLASSES[maxi(0, class_picker.selected)]
	var values := Shapes.presets(row[0])
	if shape_picker.selected < 0 or not lab.preserve_dirty(): return
	lab.checkpoint()
	lab.document = values[shape_picker.selected].duplicate(true)
	lab.active_path = ""
	lab.selected = "Body"
	lab.sync_controls()
	lab.reset_camera()
	lab.message("Loaded " + row[1] + " / " + lab.document.name + ". Your previous dirty draft was saved before switching.")

func set_baseline() -> void:
	await RenderingServer.frame_post_draw
	baseline = lab.document.duplicate(true)
	baseline_view = {"yaw": lab.yaw, "pitch": lab.pitch, "distance": lab.distance}
	baseline_overlay.texture = ImageTexture.create_from_image(lab.viewport.get_texture().get_image())
	lab.message("Baseline image and design recorded for this session. Toggle Show baseline image to compare.")

func set_motion(key: String, value: float) -> void:
	var settings: Dictionary = Recipe.design(lab.document)
	settings.motion[key] = value
	set_design("motion", settings.motion)
