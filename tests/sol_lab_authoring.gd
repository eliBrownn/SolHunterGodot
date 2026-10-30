extends SceneTree
const Recipe = preload("res://scripts/sols/presentation/sol_design_recipe.gd")
const Shapes = preload("res://tools/sol_lab_shapes.gd")
const Builder = preload("res://scripts/sols/presentation/sol_design_body.gd")
const Library = preload("res://scripts/sols/presentation/sol_design_library.gd")
const Variations = preload("res://tools/sol_lab_variations.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	root.size = Vector2i(1440, 900)
	var lab = load("res://scenes/sol_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	var all_shapes: Array[Dictionary] = []
	var expected_classes: Array = ClassBuffSettings.IDS.duplicate()
	expected_classes.erase("stonebound")
	var seen_classes := []
	for row in Shapes.CLASSES:
		seen_classes.append(row[0])
		var shapes := Shapes.presets(row[0])
		check(shapes.size() >= 3, "%s needs at least three body shapes" % row[1])
		var silhouettes := {}
		for shape in shapes:
			check(Recipe.valid(shape), "%s must be a valid editable recipe" % shape.name)
			check(shape.design.class_id == row[0], "Shape class metadata must match its library category")
			silhouettes[shape.design.body_plan + "/" + shape.design.structure] = true
			lab.body.build(shape, "")
			check(lab.body.meshes.size() > 3 and lab.body.bounds().size.is_finite(), "Each body shape must produce finite visible anatomy")
			check(lab.body.visual_core != null and lab.body.visual_core.parameters.wisp_density >= 8, "Every class body shape must have a parameterized particle core")
			all_shapes.append(shape)
		check(silhouettes.size() >= 3, "%s requires three structural silhouettes" % row[1])
	seen_classes.sort()
	expected_classes.sort()
	check(seen_classes == expected_classes and all_shapes.size() >= 54, "Body library must cover all eighteen current classes")
	lab.document = Shapes.presets("beast")[0]
	lab.sync_controls()
	var panel = lab.panels
	panel.set_design("constraints", {"head_size": [0.45, 0.65]})
	panel.change_mode(1)
	check(Recipe.design(lab.document).mode == "individual" and panel.plan_picker.disabled, "Individual editing must inherit species anatomy")
	var batch := Variations.generate(lab.document, {"seed": 9, "strength": 1, "locks": {}})
	var constrained := true
	for item in batch: constrained = constrained and item.head_size >= 0.45 and item.head_size <= 0.65 and Recipe.valid(item)
	check(constrained, "Individual generation must honor species-specific limits")
	var invalid: Dictionary = lab.document.duplicate(true)
	invalid.head_size = 0.9
	check(not Recipe.valid(invalid), "Out-of-species individual anatomy must be rejected")
	invalid = lab.document.duplicate(true)
	invalid.design.modules.horns = true
	check(not Recipe.valid(invalid), "Individuals cannot replace inherited species anatomy")
	panel.set_design("affinity", "water")
	var water_color: Color = lab.body.meshes[0].material_override.albedo_color
	panel.set_design("affinity", "fire")
	check(lab.body.meshes[0].material_override.albedo_color == water_color, "Affinity must not recolor species skin")
	panel.change_mode(0)
	panel.set_design("core_anchor", "back")
	check(lab.body.visual_core.get_parent() == lab.body.torso and lab.body.visual_core.position.y > 0, "Visual core must support placement on the back independently of the head")
	panel.set_design("core_anchor", "head")
	check(lab.body.visual_core.get_parent() == lab.body.joints.Head, "Head attachment is an optional core anchor")
	panel.set_design("core_anchor", "chest")
	var modules: Dictionary = Recipe.design(lab.document).modules.duplicate(true)
	modules.anatomical_head = false
	panel.set_design("modules", modules)
	var head_meshes := 0
	for mesh in lab.body.meshes:
		if mesh.get_parent() == lab.body.joints.Head and mesh.get_meta("part") == "Head": head_meshes += 1
	check(lab.body.visual_core != null and head_meshes == 0, "A Sol can retain its visual core without an anatomical head")
	modules.anatomical_head = true
	panel.set_design("modules", modules)
	panel.set_design("pattern", "stripes")
	check(lab.body.meshes[0].material_override.albedo_texture != null, "Markings controls must change the actual material")
	panel.favorite()
	check(Recipe.design(lab.document).favorites.size() == 1, "Favorite must retain the current appearance")
	panel.set_design("pattern", "spots")
	panel.favorites.select(0)
	panel.open_favorite()
	check(Recipe.design(lab.document).pattern == "stripes", "Favorite must restore surfaces as well as proportions")
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color("cc9955"))
	var reference_path := "user://sol_lab/test_reference.png"
	image.save_png(reference_path)
	panel.attach_reference(reference_path)
	check(Recipe.design(lab.document).references.size() == 1 and panel.reference.texture != null, "Reference attachments must be copied and displayed")
	panel.part_notes.text = "Keep the sensory crown"
	panel.part_notes.text_changed.emit()
	check(Recipe.design(lab.document).annotations.get(lab.selected) == "Keep the sensory crown", "Part annotation must belong to the selected anatomy")
	for exercise in ["idle", "walk", "run", "turns", "slope", "flight", "swim", "attack", "hit", "signature"]:
		panel.exercise = exercise
		for frame in 20: panel.tick(0.016)
		check(lab.body.bounds().position.is_finite(), "Motion exercise %s must keep finite transforms" % exercise)
	panel.paused = true
	var stopped: float = panel.elapsed
	panel.tick(0.5)
	check(panel.elapsed == stopped, "Paused movement must not spend animation time")
	panel.exercise = "idle"
	lab.document = Shapes.presets("beast")[0]
	lab.sync_controls()
	panel.set_design("target_species", "sol_species_0001")
	check(panel.export_design(true).is_empty(), "Applying a draft must require explicit owner review")
	var catalog: Resource = load("res://resources/sol_species/catalog.tres")
	var entry: Resource = catalog.find("sol_species_0001")
	var mechanics: Dictionary = entry.battle_profile("water")
	panel.set_design("stage", "reviewed")
	var exported: Dictionary = panel.export_design(true)
	check(not exported.is_empty(), "Reviewed appearance must export and connect to its existing species")
	if not exported.is_empty():
		check(Library.approved_scene(exported.scene) != null, "Export must contain the supported shared presentation script")
		var record: Resource = entry.duplicate(true)
		record.presentation_scene = load(exported.scene)
		check(record.valid(), "Exported appearance must satisfy existing catalog admission")
		var model: SolOrb = SolSpeciesView.create(entry.species_id, "water", SolVisualSettings.new())
		root.add_child(model)
		check(model.get_script().resource_path.ends_with("sol_design_view.gd") and model.affinity == "water", "Normal gameplay factory must use approved art and existing individual affinity")
		for index in 12:
			model.sync_locomotion(Vector2(0, index * 0.02), 0.016, func(_at: Vector2) -> float: return 0.0)
			model.animate(index * 0.016, 0, 0)
		check(model.design_body.diagnostics().supports == 4, "Runtime appearance must use the shared articulated support rig")
		check(entry.battle_profile("water") == mechanics, "Appearance integration must preserve species mechanics")
		model.free()
		check(Library.set_override(entry.species_id, "") == OK, "Original species appearance must be restorable")
		check(Library.presentation(entry.species_id, entry.presentation_scene) == entry.presentation_scene, "Removing override must restore catalog presentation")
	var path := "user://sol_lab/authoring_roundtrip.json"
	for species in catalog.entries:
		var model: SolCreature = SolSpeciesView.create(species.species_id, "water", SolVisualSettings.new())
		root.add_child(model)
		check(model.visual_core != null and model.visual_core.swarm is GPUParticles3D, "Every existing catalog Sol must use the shared particle core")
		check(model.visual_core.get_parent() != model.head, "Default core placement must be independent of the anatomical head")
		check(model.visual_core.swarm.process_material.get_shader_parameter("sphere_group") == true, "Visual cores must use a spherical emission group")
		check(model.visual_core.core_tint == Color("d0eaf0"), "Core tint must not be inferred from individual affinity")
		var time_before: float = model.visual_core.elapsed
		model.animate(2.0, 0, 0)
		check(model.visual_core.elapsed == 2.0 and model.visual_core.elapsed != time_before, "Existing model animation clock must drive particle-core time")
		model.free()
	for id in ["seedmote", "bramblepup", "ashkit", "rillfin", "unknown_species"]:
		var model: SolCreature = SolSpeciesView.create(id, "water", SolVisualSettings.new())
		root.add_child(model)
		check(model.visual_core != null, "Legacy and unknown Sol bodies must also receive canonical particle cores")
		model.free()
	check(Recipe.write(path, lab.document) == OK and Recipe.read(path) == lab.document, "Full authoring metadata must survive save/load")
	if "--render" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://artifacts/sol-lab")
		await panel.set_baseline()
		check(panel.baseline_overlay.texture != null and panel.baseline == lab.document, "Baseline comparison must retain both image and recipe")
		for tab in lab.workspace_tabs.get_tab_count():
			lab.workspace_tabs.current_tab = tab
			lab.section_picker.select(tab)
			if lab.workspace_tabs.get_tab_title(tab) == "Shape": lab.select_part("Core")
			for frame in 3: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/sol-lab/authoring_%s.png" % lab.workspace_tabs.get_tab_title(tab).to_lower())
		panel.set_design("core_anchor", "back")
		lab.document.core_offset_x = 0.9
		lab.document.core_offset_y = 0.6
		lab.document.core_size = 0.5
		lab.appearance_changed()
		lab.sync_controls()
		lab.select_part("Core")
		lab.workspace_tabs.current_tab = 0
		lab.section_picker.select(0)
		lab.reset_camera()
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://artifacts/sol-lab/core_placement_example.png") == OK, "Review must show core placement independent of the physical head")
		lab.hide()
		await render_shapes(all_shapes)
	lab.free()
	await process_frame
	await process_frame
	print("SOL LAB AUTHORING: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func render_shapes(shapes: Array[Dictionary]) -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size = Vector2i.ZERO
	root.size = Vector2i(1980, 1320)
	var grid := GridContainer.new()
	grid.columns = 9
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(grid)
	for recipe in shapes:
		var card := VBoxContainer.new()
		grid.add_child(card)
		var label := Label.new()
		label.text = SolSpeciesCatalog.class_display_name(recipe.design.class_id) + " / " + recipe.name
		label.add_theme_font_size_override("font_size", 12)
		label.clip_text = true
		card.add_child(label)
		var container := SubViewportContainer.new()
		container.custom_minimum_size = Vector2(215, 185)
		container.stretch = true
		card.add_child(container)
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		container.add_child(viewport)
		var body := Builder.new()
		viewport.add_child(body)
		body.build(recipe, "")
		var bounds := body.bounds()
		var camera := Camera3D.new()
		camera.fov = 40
		viewport.add_child(camera)
		camera.position = bounds.get_center() + Vector3(0.7, 0.3, 1).normalized() * maxf(3.0, bounds.size.length() * 1.4)
		camera.look_at(bounds.get_center())
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("263442")
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color("c4d6e6")
		environment.environment.ambient_light_energy = 0.8
		viewport.add_child(environment)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45, -30, 0)
		viewport.add_child(light)
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png("res://artifacts/sol-lab/class_shapes.png") == OK, "54 body shapes must render to a review board")
	grid.free()
