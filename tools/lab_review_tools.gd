extends Node
## Local review records and guided presentation tests. No production tuning writes.
var host: Control
var tasks := OptionButton.new()
var task_help := Label.new()
var task_list: Array[Dictionary] = []
var task_content: VBoxContainer
var task_toggle: Button
var title := LineEdit.new()
var state := OptionButton.new()
var next_change := TextEdit.new()
var reviews := OptionButton.new()
var comparison_slider := HSlider.new()
var time_slider := HSlider.new()
var time_label := Label.new()
var records: Dictionary = {}
var review_path := "user://workstation/reviews.cfg"
var loaded_station := ""
var current_review := ""
var current_task := ""
var selected_time := 0.0
var actions: Array[Dictionary] = []
var saved_picture := TextureRect.new()
var capture_without_labels := false
var wipe_material := ShaderMaterial.new()

func bind(workspace: Control, settings_page: VBoxContainer, compare_page: VBoxContainer, review_page: VBoxContainer) -> void:
	host = workspace
	var wipe_shader := Shader.new()
	wipe_shader.code = "shader_type canvas_item; uniform float split=1.0; void fragment(){ vec4 image=texture(TEXTURE,UV); COLOR = abs(UV.x-split)<0.0015 ? vec4(0.95,0.8,0.45,1.0) : (UV.x <= split ? image : vec4(0.0)); }"
	wipe_material.shader = wipe_shader
	if Engine.has_meta("workstation_session_path") or not host.session_path.begins_with("user://"):
		review_path = host.session_path.get_basename() + "-reviews.cfg"
	var config := ConfigFile.new()
	if config.load(review_path) == OK: records = config.get_value("reviews", "records", {})
	var task_box: VBoxContainer = host.fold_section(settings_page, "Try a test", true)
	task_content = task_box
	task_toggle = settings_page.get_child(task_box.get_index()-1)
	settings_page.move_child(task_toggle,0)
	settings_page.move_child(task_box,1)
	task_box.add_child(tasks)
	task_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task_box.add_child(task_help)
	tasks.item_selected.connect(func(index: int): task_help.text = str(task_list[index].get("goal", "")))
	host.button(task_box, "Start this test", start_task)
	var repeat_box: VBoxContainer = host.fold_section(compare_page, "Match the view", true)
	host.button(repeat_box, "Use the before camera", func():
		if not host.baseline.is_empty(): host.apply_camera(host.baseline.get("camera_settings", {})))
	time_slider.min_value = 0
	time_slider.max_value = 10
	time_slider.step = 0.1
	time_slider.value_changed.connect(func(value: float):
		selected_time = value
		time_label.text = "Stop the test at %.1f seconds" % value)
	time_label.text = "Stop the test at 0.0 seconds"
	repeat_box.add_child(time_label)
	repeat_box.add_child(time_slider)
	host.button(repeat_box, "Restart and stop here", replay_to_time)
	var wipe_label := Label.new()
	wipe_label.text = "Drag to compare before and now"
	compare_page.add_child(wipe_label)
	comparison_slider.min_value = 0
	comparison_slider.max_value = 1
	comparison_slider.step = 0.01
	comparison_slider.value = 1
	compare_page.add_child(comparison_slider)
	comparison_slider.value_changed.connect(update_wipe)
	host.preview_stack.resized.connect(func(): update_wipe(comparison_slider.value))
	host.baseline_overlay.gui_input.connect(func(event: InputEvent):
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			comparison_slider.value = clampf(host.baseline_overlay.get_local_mouse_position().x / maxf(1,host.baseline_overlay.size.x),0,0.999)
			host.baseline_overlay.accept_event())
	var clean := CheckButton.new()
	clean.text = "Hide names and tips in pictures"
	review_page.add_child(clean)
	clean.toggled.connect(func(on: bool): capture_without_labels = on)
	var library: VBoxContainer = host.fold_section(review_page, "Saved reviews", true)
	var review_toggle := review_page.get_child(library.get_index()-1)
	review_page.move_child(review_toggle,0)
	review_page.move_child(library,1)
	title.placeholder_text = "Review name — e.g. Marsh grass in wind"
	library.add_child(title)
	for name in ["Needs changes", "Ready to check", "Accepted"]: state.add_item(name)
	library.add_child(state)
	next_change.custom_minimum_size.y = 90
	next_change.placeholder_text = "What should change next?"
	next_change.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	library.add_child(next_change)
	var row := HFlowContainer.new()
	library.add_child(row)
	host.button(row, "Save review", save_review)
	host.button(row, "Save a copy", func(): current_review = ""; save_review())
	library.add_child(reviews)
	saved_picture.custom_minimum_size.y = 130
	saved_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	saved_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	library.add_child(saved_picture)
	saved_picture.hide()
	var buttons := HFlowContainer.new()
	library.add_child(buttons)
	host.button(buttons, "Open review", open_review)
	host.button(buttons, "Write change note", write_change_note)
	host.button(buttons, "Open saved picture", open_saved_picture)
	var scope := Label.new()
	scope.text = "These are local test notes. Accepting a review does not change the game. A change note lists the proposed edits for review."
	scope.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	library.add_child(scope)
	refresh_reviews()

func after_load() -> void:
	var changed: bool = loaded_station != host.active_key
	loaded_station = host.active_key
	var selected_task := tasks.get_item_text(tasks.selected) if tasks.selected >= 0 else ""
	task_list = tasks_for(host.active_key)
	tasks.clear()
	for task in task_list: tasks.add_item(task.name)
	for i in range(tasks.item_count):
		if tasks.get_item_text(i) == selected_task and not changed: tasks.select(i)
	task_help.text = task_list[maxi(0,tasks.selected)].goal if not task_list.is_empty() else ""
	var supported: bool = host.active_key in ["grass_blade_preview", "vastra_particle_lab"]
	time_slider.editable = supported
	time_label.text = "Stop the test at %.1f seconds" % selected_time if supported else "This test can restart, but cannot replay an exact time."
	comparison_slider.set_value_no_signal(1)
	update_wipe(1)
	if changed:
		current_review = ""
		current_task = ""
		title.text = ""
		next_change.text = ""
		state.select(0)
		saved_picture.hide()
		restore_draft(host.sessions.get(host.active_key,{}).get("review_draft",{}))

func tasks_for(key: String) -> Array[Dictionary]:
	if key == "grass_blade_preview": return [
		{"name":"Grass in strong wind", "goal":"Check that blades bend clearly without hiding the ground or looking detached.", "settings":{"wind_strength":1.5,"wind_direction_degrees":35.0,"night_view":false,"vastra_visible":false}, "time":2.0},
		{"name":"Grass at night", "goal":"Can you tell each patch apart? Check blade edges and the glow against the ground.", "settings":{"night_view":true,"vastra_visible":true,"vastra_visibility":0.55}, "time":2.0},
		{"name":"Compare the four habitats", "goal":"Compare height, thickness and coverage using the same camera and clock.", "settings":{"wind_strength":0.0,"vastra_visible":false}, "time":0.0}]
	if key == "vastra_particle_lab": return [
		{"name":"Follow one energy transfer", "goal":"Follow energy from a tree to a ground plant. The path should start and end at the right plants.", "transfer":true, "clear":true, "time":1.0},
		{"name":"Check a quiet energy field", "goal":"Look for calm movement and readable plant shapes. Compare a small visibility change.", "preset":1,"time":2.0},
		{"name":"Check a busy energy field", "goal":"Check whether the plants remain visible when the effect becomes stronger.", "preset":4,"time":2.0}]
	var bench_tasks := {
		"lighting_test_station":[{"name":"Low sun and long shadows","goal":"Check that the cube, tree and rock keep clear shapes in low light.","live":{"sun_elevation":12.0,"sun_energy":1.2}},{"name":"Soft light and fog","goal":"Check how quickly shapes disappear with distance.","live":{"fog":0.04}}],
		"material_test_station":[{"name":"Compare surface shine","goal":"Compare the same shape across rough and shiny surfaces.","live":{"light_angle":-30.0,"light_energy":1.5}}],
		"water_test_station":[{"name":"Calm water","goal":"Check the shallow edge and foam with small ripples.","live":{"ripple_strength":0.006,"ripple_speed":0.6}},{"name":"Stronger ripples","goal":"Check that foam and depth stay readable as water movement increases.","live":{"ripple_strength":0.04,"ripple_speed":1.0}}],
		"readability_test_station":[{"name":"Partly hidden target","goal":"Can you still recognize the target behind a foreground object?","live":{"occluder_x":0.0,"occluder_height":2.0}},{"name":"Clear target","goal":"Use a clear view as the starting point for a visibility comparison.","live":{"occluder_height":0.0}}],
		"particle_density_station":[{"name":"Light particle load","goal":"Check appearance and speed with fewer particles.","live":{"active_particles":512.0}},{"name":"Heavy particle load","goal":"Check appearance and speed with more particles. This is a lab stress test.","live":{"active_particles":8192.0}}],
		"plant_biome_role_lab":[{"name":"Look inside a plant","goal":"Pick a plant, move closer, and check that its inner parts connect.","settings":{"cutaway":true}}],
		"procedural_plant_lab":[{"name":"Compare plant shapes","goal":"Pick a growth form and check its outline using the same random pattern.","settings":{"generation_seed":73}}],
		"relic_concept_preview":[
			{"name":"Healthy and rich","goal":"Can you read the motif without interpreting brightness as danger?","settings":{"concentration":90,"overload":0}},
			{"name":"Disturbed pattern","goal":"Compare the broken pattern with the healthy version at the same concentration.","settings":{"concentration":90,"overload":70}},
			{"name":"Restorative pattern","goal":"Review a distinct settling cue without implying stone repair.","settings":{"concentration":65,"overload":-65}},
			{"name":"Quiet discovery","goal":"Do the silhouettes still invite investigation when the response is faint?","settings":{"concentration":10,"overload":0}},
			{"name":"Intact layered ruin","goal":"Review the maximum layer range before breaking the stonework.","settings":{"display_family":3,"stone_courses":12,"damage":0.0,"break_variation":0.0}},
			{"name":"Uneven broken courses","goal":"Compare the surviving heights and square-cut etch-outs in black stone.","settings":{"display_family":3,"stone_courses":9,"damage":0.8,"break_variation":1.0}},
			{"name":"Skeletal remnants","goal":"Check the severe end of the missing-stonework range and its supported remnants.","settings":{"display_family":3,"stone_courses":12,"damage":2.0,"break_variation":1.0}}
		],
		"slope_animation_station":[{"name":"Watch feet on a slope","goal":"Look for sliding or feet passing through the ground.","settings":{"exercise":3,"walk_speed":0.3}}],
		"flight_animation_station":[{"name":"Watch takeoff and landing","goal":"Check the change from standing to flight and back.","settings":{"exercise":4}}],
		"swim_animation_station":[{"name":"Watch swimming","goal":"Check body height and movement against the waterline.","settings":{"exercise":5}}]
	}
	if bench_tasks.has(key):
		var result: Array[Dictionary] = []
		for task in bench_tasks[key]: result.append(task)
		return result
	return [{"name":"Check " + host.picker.get_item_text(host.picker.selected).split("/")[-1].strip_edges().to_lower(), "goal":host.station_purpose(key) + " Start with the same settings, take a before picture, then change one thing."}]

func start_task() -> void:
	if tasks.selected < 0: return
	var task: Dictionary = task_list[tasks.selected]
	host.restore_defaults()
	host.overrides = task.get("settings", {}).duplicate(true)
	host.load_fixture()
	# after_load refreshes the menu, so retain the chosen task explicitly.
	current_task = task.name
	host.set_paused(false)
	if host.active_key == "vastra_particle_lab":
		var lab: Node = host.fixture
		lab.frozen = false
		lab.apply_preset(int(task.get("preset",1)))
		lab.clear_toggle.button_pressed = bool(task.get("clear",false))
		if task.get("transfer",false):
			lab.plant_nodes.scenario.select(0)
			lab.plant_nodes.configure_scenario(0)
			lab.plant_nodes.source.select(2)
			lab.plant_nodes.target.select(0)
			lab.plant_nodes.controls["Transfer energy"].value = 20
			lab.plant_nodes.reset_nodes()
			lab.plant_nodes.play_scenario()
	for key in task.get("live",{}):
		var slider := host.station_box.find_child(str(key),true,false) as Range
		if slider: slider.value = float(task.live[key])
	if host.active_key in ["grass_blade_preview","vastra_particle_lab"]: host.station_tools.frame_all()
	host.notes.text = "Question: " + str(task.goal) + "\nExpected:\nObserved:\nNext change:"
	if task.has("time"):
		advance_to(float(task.time))
	else: host.set_paused(not host.active_key.contains("animation") and not host.active_key.contains("workshop"))
	task_toggle.button_pressed = false
	host.message.text = "Test ready. Take a before picture, then change one thing."

func replay_to_time() -> void:
	if host.active_key not in ["grass_blade_preview", "vastra_particle_lab"]:
		host.restart_fixture()
		host.message.text = "Restarted with the same settings. This test does not support exact-time replay."
		return
	var seconds := selected_time
	advance_to(seconds, true)
	host.message.text = "Stopped at %.1f seconds using the same starting settings." % seconds

func advance_to(seconds: float, rebuild: bool = false) -> void:
	if host.active_key not in ["grass_blade_preview", "vastra_particle_lab"]: return
	if rebuild:
		# Replaying a guided test must start its send action again at zero.
		var controls: Dictionary = host.control_settings()
		var camera_setup: Dictionary = host.camera_settings()
		host.restart_fixture()
		host.restore_controls(controls)
		host.apply_camera(camera_setup)
		if host.active_key == "vastra_particle_lab" and current_task == "Follow one energy transfer": host.fixture.plant_nodes.play_scenario()
	host.set_paused(false)
	if host.fixture.get("frozen") is bool: host.fixture.set("frozen",false)
	var remaining := clampf(seconds,0,10)
	while remaining > 0.00001:
		var step := minf(remaining,1.0/60.0)
		host.fixture.call("_process",step)
		remaining -= step
	host.elapsed = seconds
	host.ticks = roundi(seconds*60)
	host.set_paused(true)
	selected_time = seconds
	time_slider.set_value_no_signal(seconds)
	time_label.text = "Stopped at %.1f seconds" % seconds

func update_wipe(value: float) -> void:
	if not host: return
	if not host.baseline_images.has(host.active_key):
		host.baseline_overlay.hide()
		return
	host.baseline_overlay.texture = host.baseline_images[host.active_key]
	wipe_material.set_shader_parameter("split",value)
	host.baseline_overlay.material = wipe_material
	host.baseline_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	host.baseline_overlay.visible = value < 1.0
	if value < 1: host.message.text = "Before on the left · Now on the right"

func save_review() -> void:
	if title.text.strip_edges().is_empty():
		host.message.text = "Give this review a name first."
		return
	if current_review.is_empty(): current_review = str(Time.get_ticks_usec()) + "-" + str(randi()%100000)
	var id := current_review
	var directory := review_path.get_base_dir() + "/reviews"
	DirAccess.make_dir_recursive_absolute(directory)
	var before := ""
	if host.baseline_images.has(host.active_key):
		before = directory + "/" + id + "-before.png"
		if host.baseline_images[host.active_key].get_image().save_png(before) != OK:
			host.message.text = "Could not save the before picture."
			return
	var report: Dictionary = host.report()
	var record := {"version":1,"station":host.active_key,"title":title.text.strip_edges(),"status":state.selected,"next":next_change.text,"notes":host.notes.text,"settings":host.exported_settings(host.fixture),"camera":host.camera_settings(),"controls":host.control_settings(),"control_revision":host.control_revision(),"baseline":host.baseline.duplicate(true),"before_image":before,"task":current_task,"time":selected_time,"updated":Time.get_datetime_string_from_system(),"report":report}
	if DisplayServer.get_name() != "headless":
		var station: String = host.active_key
		var hidden: Dictionary = host.station_tools.hide_for_picture() if capture_without_labels else {}
		await RenderingServer.frame_post_draw
		if station != host.active_key:
			if not hidden.is_empty(): host.station_tools.restore_after_picture(hidden)
			host.message.text = "The test changed while saving. Save the review again."
			return
		var current := directory + "/" + id + "-now.png"
		var current_picture: Image = host.viewport.get_texture().get_image()
		if not hidden.is_empty(): host.station_tools.restore_after_picture(hidden)
		if current_picture.save_png(current) != OK:
			host.message.text = "Could not save the review picture."
			return
		record["report"] = host.report()
		record["current_image"] = current
		saved_picture.texture = ImageTexture.create_from_image(Image.load_from_file(current))
		saved_picture.show()
	records[id] = record
	if not save_library(): return
	refresh_reviews()
	host.message.text = "Review saved: " + str(record.title)

func save_library() -> bool:
	var config := ConfigFile.new()
	config.set_value("reviews","records",records)
	DirAccess.make_dir_recursive_absolute(review_path.get_base_dir())
	if config.save(review_path) != OK:
		host.message.text = "Could not save reviews to this folder."
		return false
	return true

func refresh_reviews() -> void:
	reviews.clear()
	for id in records:
		var item: Dictionary = records[id]
		reviews.add_item(str(item.title) + " · " + ["Needs changes","Ready to check","Accepted"][clampi(int(item.status),0,2)])
		reviews.set_item_metadata(reviews.item_count-1,id)
		if str(id) == current_review: reviews.select(reviews.item_count-1)

func open_review() -> void:
	if reviews.selected < 0: return
	var id: String = reviews.get_item_metadata(reviews.selected)
	var saved: Dictionary = records[id].duplicate(true)
	if int(saved.get("version",0)) != 1 or not host.FIXTURES.values().has(saved.get("station")):
		host.message.text = "This review uses an unavailable test or file version."
		return
	host.picker.select(host.FIXTURES.values().find(saved.station))
	host.load_fixture()
	host.overrides = saved.settings.duplicate(true)
	host.load_fixture()
	host.apply_camera(saved.camera)
	if saved.get("control_revision","") == host.control_revision(): host.restore_controls(saved.controls)
	host.notes.text = saved.notes
	var view: Dictionary = saved.get("report",{}).get("view_options",{})
	host.station_tools.set_labels(bool(view.get("names",true)))
	host.station_tools.set_hints(bool(view.get("tips",false)))
	host.station_tools.set_view_mode(int(view.get("mode",0)))
	if is_instance_valid(host.station_tools.scale_lines): host.station_tools.scale_lines.visible = bool(view.get("ruler",false))
	host.station_tools.endpoint_toggle.button_pressed = bool(view.get("endpoints",false))
	host.baseline = saved.get("baseline",{}).duplicate(true)
	if FileAccess.file_exists(saved.get("before_image","")):
		var image := Image.load_from_file(saved.before_image)
		if image: host.baseline_images[host.active_key] = ImageTexture.create_from_image(image)
	else:
		host.baseline.clear()
		host.baseline_images.erase(host.active_key)
	host.baseline_view.texture = host.baseline_images.get(host.active_key)
	host.refresh_compare()
	current_review = id
	current_task = str(saved.get("task",""))
	selected_time = float(saved.get("time",0))
	title.text = saved.title
	state.select(clampi(int(saved.status),0,2))
	next_change.text = saved.next
	if FileAccess.file_exists(saved.get("current_image","")):
		saved_picture.texture = ImageTexture.create_from_image(Image.load_from_file(saved.current_image))
		saved_picture.show()
	host.message.text = "Review opened. Settings and pictures restored; the live test starts again."

func write_change_note() -> void:
	if current_review.is_empty() or not records.has(current_review):
		host.message.text = "Save this review first, then write a change note."
		return
	var item: Dictionary = records[current_review]
	var sources := {
		"grass_blade_preview": ["scripts/scenery/grass_blade_mesh.gd", "resources/meadow_appearance.tres"],
		"water_test_station": ["shaders/pixel_water.gdshader"],
		"forest_style_preview": ["resources/painterly_foliage.tres"],
		"plant_biome_role_lab": ["docs/procedural-plants.md"],
		"vastra_particle_lab": ["resources/vastra_particle_lab_baseline.json"]
	}
	var text: String = "# " + str(item.title) + "\n\nReview state: " + ["Needs changes","Ready to check","Accepted"][int(item.status)] + "\n\n## Next change\n\n" + str(item.next) + "\n\n## Observation\n\n" + str(item.notes) + "\n\n## Proposed test settings\n\n"
	var before: Dictionary = item.get("baseline",{}).get("setup",{})
	for key in item.settings:
		if not before.has(key) or item.settings[key] != before[key]: text += "- " + host.simple_parameter_name(str(key)) + ": " + (str(before[key])+" -> " if before.has(key) else "") + str(item.settings[key]) + "\n"
	text += "\nLive test controls: " + str(item.controls) + "\n"
	text += "\n## Implementation references\n\n"
	for path in sources.get(item.station,[]):
		if FileAccess.file_exists("res://" + path): text += "- " + path + "\n"
	text += "\nThese are lab settings, not a direct production patch. Review each mapping, preserve gameplay owners, and validate the actual game change before applying it.\n"
	var path := review_path.get_base_dir() + "/reviews/" + current_review + "-change.md"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		host.message.text = "Could not write the change note."
		return
	file.store_string(text)
	file.close()
	host.message.text = "Change note saved: " + ProjectSettings.globalize_path(path)


func draft() -> Dictionary:
	return {"title":title.text,"status":state.selected,"next":next_change.text,"review_id":current_review,"task":current_task,"time":selected_time}

func restore_draft(saved: Dictionary) -> void:
	title.text = str(saved.get("title",""))
	state.select(clampi(int(saved.get("status",0)),0,2))
	next_change.text = str(saved.get("next",""))
	current_review = str(saved.get("review_id",""))
	current_task = str(saved.get("task",""))
	selected_time = float(saved.get("time",0))

func open_saved_picture() -> void:
	if reviews.selected < 0: return
	var record: Dictionary = records[reviews.get_item_metadata(reviews.selected)]
	if FileAccess.file_exists(record.get("current_image","")): OS.shell_open(ProjectSettings.globalize_path(record.current_image))
