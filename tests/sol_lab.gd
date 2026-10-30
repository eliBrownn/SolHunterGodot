extends SceneTree
const Document = preload("res://tools/sol_lab_document.gd")
const Variations = preload("res://tools/sol_lab_variations.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func run() -> void:
	var lab = load("res://scenes/sol_lab.tscn").instantiate()
	root.size = Vector2i(1440, 900)
	root.add_child(lab)
	await process_frame
	check(lab.viewport.own_world_3d, "Preview must own an isolated world")
	check(lab.body.meshes.size() > 5, "Connected body blockout must be visible")
	var start: Dictionary = lab.document.duplicate(true)
	lab.checkpoint()
	lab.document.body_length = 1.9
	lab.sync_controls()
	lab.undo()
	check(lab.document == start, "Undo must restore the appearance recipe")
	lab.redo()
	check(is_equal_approx(lab.document.body_length, 1.9), "Redo must restore the edit")
	lab.select_part("Head")
	check(lab.parameter_box.get_child_count() >= 4, "Part selection must expose slider and feature lock")
	var head_slider: HSlider = lab.parameter_box.get_child(2)
	head_slider.value = 0.8
	check(is_equal_approx(lab.document.head_size, 0.8), "Visible slider must edit the document")
	lab.undo()
	head_slider = lab.parameter_box.get_child(2)
	var history_count: int = lab.undo_stack.size()
	head_slider.drag_started.emit()
	head_slider.value = 0.65
	head_slider.value = 0.7
	head_slider.drag_ended.emit(true)
	check(lab.undo_stack.size() == history_count + 1, "A slider drag must use one undo step")
	lab.undo()
	var before: Dictionary = lab.document.duplicate(true)
	lab.checkpoint()
	lab.document.head_size = 0.9
	lab.reset_part()
	check(lab.document.body_length == before.body_length, "Part reset must preserve unrelated anatomy")
	var malformed := Document.fresh()
	malformed.leg_length = -5
	check(not Document.valid(malformed), "Reject invalid anatomy ranges")
	malformed = Document.fresh()
	malformed.body_length = "wrong"
	check(not Document.valid(malformed), "Reject wrong parameter types")
	malformed = Document.fresh()
	malformed.version = 999
	check(not Document.valid(malformed), "Reject unsupported document versions")
	var path := "user://sol_lab_test_%d.json" % Time.get_ticks_usec()
	check(Document.write(path, lab.document) == OK, "Draft must serialize")
	check(Document.read(path) == lab.document, "Saved draft must reproduce exactly")
	DirAccess.remove_absolute(path)
	var saved_path: String = lab.active_path
	check(lab.save_document(), "Revision save must succeed")
	check(lab.active_path != saved_path and Document.read(lab.active_path) == lab.document, "Revision must be independently reopenable")
	var revision: String = lab.active_path
	lab.new_document()
	check(lab.document == Document.fresh(), "New must start with defaults")
	lab.refresh_library()
	for index in lab.library.item_count:
		if lab.library.get_item_metadata(index) == revision: lab.library.select(index)
	lab.open_selected()
	check(lab.active_path == revision and lab.document.body_length == before.body_length, "Library must reopen saved appearance")
	DirAccess.remove_absolute(revision)
	# Assert picking against visible ellipsoid geometry rather than a part list.
	lab.reset_camera()
	var point: Vector2 = lab.camera.unproject_position(lab.body.visual_core.global_position)
	check(lab.body.pick(lab.camera, point) == "Core", "Clicking the wispy visual core must select Core")
	var parent := Document.fresh()
	var setup := Variations.settings()
	var batch := Variations.generate(parent, setup)
	check(batch == Variations.generate(parent, setup), "Same parent and seed must reproduce candidates")
	check(parent == Document.fresh(), "Generating must not mutate the parent")
	setup.locks.head_size = true
	var locked_batch := Variations.generate(parent, setup)
	var lock_ok := true
	var independent := true
	for index in batch.size():
		lock_ok = lock_ok and locked_batch[index].head_size == parent.head_size
		independent = independent and locked_batch[index].tail_length == batch[index].tail_length
	check(lock_ok, "Locked anatomy must stay exact")
	check(independent, "Locking a head must not reroll another feature")
	setup.seed = 2
	check(Variations.generate(parent, setup) != locked_batch, "Changing seed must explore a new batch")
	setup.strength = 0
	check(Variations.generate(parent, setup)[0] == parent, "Zero variation must preserve exact parent")
	setup.strength = 1
	var ranges_ok := true
	for number in 50:
		setup.seed = number
		for candidate in Variations.generate(parent, setup): ranges_ok = ranges_ok and Document.valid(candidate)
	check(ranges_ok, "Generated anatomy must respect all authoring ranges")
	lab.select_part("Head")
	var lock_control: CheckBox = lab.parameter_box.get_child(3)
	lock_control.button_pressed = true
	lab.generate_variations()
	check(lab.candidates.size() == 6 and lab.gallery.get_child_count() == 7, "Generate must show the parent alongside six visual candidates")
	var draft_before: Dictionary = lab.document.duplicate(true)
	var candidate_before: Dictionary = lab.candidates[0].duplicate(true)
	lab.adopt_variation(0)
	check(lab.document.tail_length == candidate_before.tail_length and lab.document.head_size == draft_before.head_size, "Adoption must use candidate proportions and honor locks")
	lab.undo()
	check(lab.document == draft_before, "Adoption must undo in one step")
	var recipe_path := "user://sol_lab_recipe_%d.json" % Time.get_ticks_usec()
	check(Document.write(recipe_path, lab.document) == OK, "Exploration recipe must save")
	var reopened := Document.read(recipe_path)
	check(not reopened.is_empty() and reopened == lab.document, "Exploration settings and parent must round-trip")
	check(Variations.generate(reopened.exploration.parent, reopened.exploration) == lab.candidates, "Reopened recipe must reproduce gallery")
	lab.document = reopened
	lab.sync_controls()
	check(lab.candidates == Variations.generate(reopened.exploration.parent, reopened.exploration), "Restoring a document must rebuild its gallery")
	lab.adopt_variation(0)
	lab.adopt_variation(-1)
	check(lab.document.body_length == draft_before.body_length, "Restore parent must recover original proportions")
	lab.select_part("Head")
	var edit_after_batch: HSlider = lab.parameter_box.get_child(2)
	edit_after_batch.value = 0.75
	check(lab.candidates.is_empty() and not lab.document.exploration.has("parent"), "Manual edits must discard stale generated candidates")
	lab.undo()
	check(lab.candidates.size() == 6, "Undoing manual edits must recover the previous batch")
	DirAccess.remove_absolute(recipe_path)
	var bad_recipe := Document.fresh()
	bad_recipe.exploration = {"seed": 1, "strength": "bad", "locks": {}}
	check(not Document.valid(bad_recipe), "Invalid exploration settings must be rejected")
	if "--render" in OS.get_cmdline_user_args():
		lab.notes.text = "Review capture smoke test"
		await lab.capture()
		var found_review := false
		for filename in DirAccess.get_files_at(lab.FOLDER):
			if not filename.begins_with("review_") or not filename.ends_with(".json"): continue
			var review_path: String = lab.FOLDER.path_join(filename)
			var review: Variant = JSON.parse_string(FileAccess.get_file_as_string(review_path))
			if review is Dictionary and review.document.notes == lab.document.notes:
				found_review = FileAccess.file_exists(review_path.trim_suffix(".json") + ".png")
		check(found_review, "Capture must pair an image with recipe and notes")
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://artifacts/sol-lab")
		check(root.get_texture().get_image().save_png("res://artifacts/sol-lab/workspace.png") == OK, "Workspace capture must save")
		root.size = Vector2i(1100, 720)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://artifacts/sol-lab/compact.png") == OK, "Compact workspace capture must save")
	print("SOL LAB: %d checks, %d failures" % [checks, failures])
	lab.free()
	await process_frame
	await process_frame
	quit(1 if failures else 0)
