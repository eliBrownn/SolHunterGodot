extends Node3D
const MenuTheme = preload("res://scripts/menu_theme.gd")
## Cosmetic events and runtime-only result recap; never owns battle or save state.
var world: Node2D
var tuning: SolVisualSettings
var cues: Array[Dictionary] = []
var result_panel: PanelContainer
var result_title: Label
var result_text: Label
var result_help: Label

func bind(source: Node2D, settings: SolVisualSettings) -> void:
	world = source
	tuning = settings
	result_panel = world.panel_at(Rect2(24, 145, 360, 430))
	result_panel.theme = MenuTheme.build(MenuSettings.new())
	result_panel.add_theme_stylebox_override("panel", MenuTheme.box(Color("182c25"), Color("827651")))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	result_panel.add_child(box)
	result_title = world.label("", 23, Color("e1c791"))
	box.add_child(result_title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(320, 240)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	result_text = world.label("", 15)
	result_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_text.custom_minimum_size.x = 310
	result_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(result_text)
	result_help = world.label("F5 saves these results.", 14, Color("e1c791"))
	result_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(result_help)
	var close := Button.new()
	close.text = "Continue exploring"
	close.custom_minimum_size.y = 40
	close.pressed.connect(result_panel.hide)
	box.add_child(close)
	result_panel.hide()

func reset() -> void:
	for cue in cues:
		cue.node.free()
	cues.clear()
	result_panel.hide()

func receive(event: Dictionary) -> void:
	if not tuning.feedback_enabled:
		return
	while cues.size() >= tuning.feedback_limit:
		cues.pop_front().node.free()
	var anchor := Node3D.new()
	add_child(anchor)
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.shaded = false
	label.font_size = 32
	label.pixel_size = 0.018
	label.outline_size = 4
	label.render_priority = 2
	label.outline_render_priority = 1
	var caption: String = event.caption
	if caption.length() > 24:
		caption = caption.left(23) + "…"
	if event.kind == "damage":
		caption = "−%d" % int(event.amount)
	elif event.kind == "heal":
		caption = "+%d" % int(event.amount)
	label.text = caption
	label.modulate = Color("ffd9bf") if event.kind == "damage" else (Color("c0ffe0") if event.kind == "heal" else Color.WHITE)
	label.position.y = 1.65 + float(cues.size() % 3) * 0.24
	label.position.x = float(cues.size() % 3 - 1) * 0.25
	anchor.add_child(label)
	var pulse := Sprite3D.new()
	pulse.texture = ring_texture()
	pulse.pixel_size = 0.04
	pulse.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pulse.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pulse.shaded = false
	pulse.render_priority = -1
	pulse.position.y = tuning.hover_height
	pulse.modulate = tuning.color_for(event.affinity)
	anchor.add_child(pulse)
	if event.kind == "vastra":
		var current := MeshInstance3D.new()
		var ribbon := QuadMesh.new()
		ribbon.size = Vector2(1.25, 0.18)
		current.mesh = ribbon
		current.rotation.z = PI / 2.0
		current.position.y = 0.7
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/vastra_current.gdshader")
		material.set_shader_parameter("current_color", tuning.color_for(event.affinity))
		material.set_shader_parameter("opacity", 0.3)
		current.material_override = material
		anchor.add_child(current)
		anchor.set_meta("vastra_current", current)
	cues.append({"node": anchor, "label": label, "pulse": pulse, "cell": event.cell, "age": 0.0, "base_y": label.position.y, "kind": event.kind, "amount": event.amount})
	update_cues(0.0)

func _process(delta: float) -> void:
	update_cues(delta)

func update_cues(delta: float) -> void:
	for index in range(cues.size() - 1, -1, -1):
		var cue: Dictionary = cues[index]
		cue.age += delta
		if cue.node.has_meta("vastra_current"):
			var current: MeshInstance3D = cue.node.get_meta("vastra_current")
			(current.material_override as ShaderMaterial).set_shader_parameter("clock_seconds", float(cue.age) * 2.0)
		if cue.age >= tuning.feedback_seconds:
			cue.node.free()
			cues.remove_at(index)
			continue
		var fraction: float = cue.age / tuning.feedback_seconds
		var relative: Vector2 = world.center(cue.cell) - world.camera.position
		cue.node.position = Vector3(relative.x / 32.0, world.host.ground_height(Vector2(cue.cell) + Vector2(0.5, 0.5)) + 0.15, relative.y / 32.0)
		cue.label.position.y = cue.base_y + fraction * tuning.feedback_rise
		cue.label.modulate.a = 1.0 - fraction
		cue.label.outline_modulate.a = 1.0 - fraction
		cue.pulse.modulate.a = (1.0 - fraction) * 0.8
		cue.pulse.scale = Vector3.ONE * (0.65 + fraction * 0.8)

static func ring_texture() -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(24):
		for x in range(24):
			var radius := (Vector2(x, y) - Vector2(11.5, 11.5)).length()
			if radius >= 8 and radius <= 10:
				image.set_pixel(x, y, Color.WHITE)
	return ImageTexture.create_from_image(image)

func show_result(outcome: String, hero: Dictionary, imprint: Dictionary, counts: Dictionary, history: Array[String]) -> void:
	result_title.text = {"victory": "VICTORY", "exhaustion": "EXHAUSTION", "retreat": "SAFE RETREAT", "captured": "SOL SEALED"}[outcome]
	var lines: Array[String] = ["%s · Lv %d · HP %d/%d" % [hero.profile.display_name, int(hero.profile.level), int(hero.hp), int(hero.profile.max_hp)]]
	if imprint.is_empty():
		lines.append("No imprint: no successful moves.")
	else:
		lines.append("%s imprint · %d affected tiles" % [str(imprint.winner).capitalize(), imprint.tiles.size()])
		lines.append("Tile affinity remains. Terrain conditions recover.")
		lines.append("\nSuccessful moves:")
		var ids: Array = counts.keys()
		ids.sort()
		var leaders := 0
		for id in ids:
			lines.append("%s: %d" % [str(id).capitalize(), int(counts[id])])
			if counts[id] == counts[imprint.winner]:
				leaders += 1
		if leaders > 1 and not history.is_empty():
			lines.append("Tie: the latest move among the tied affinities chose %s." % str(imprint.winner).capitalize())
	if outcome == "captured":
		lines.append("The same individual is now held by a Seal. C opens your companions.")
	if outcome == "exhaustion":
		lines.append("\nBack at the refuge. Right-click your trainer and choose Recover party.")
	else:
		lines.append("\nYour companion's remaining health is retained.")
	result_help.text = "At refuge: H recovers · F5 saves." if outcome == "exhaustion" else "F5 saves these results."
	result_text.text = "\n".join(lines)
	result_panel.visible = tuning.result_panel_enabled
