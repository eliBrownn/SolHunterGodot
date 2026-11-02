class_name ExpeditionHud
extends RefCounted
## Owns shared HUD construction and styles; all expedition actions go to the world owner.

static func label(value: String, font_size: int = 16, color: Color = Color("dddac6")) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func panel_at(hud: CanvasLayer, rect: Rect2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_meta("hud_authored_rect", rect)
	panel.position = rect.position
	panel.size = rect.size
	# Keep HUD panels attached to the game viewport as the 3D aspect ratio changes.
	if rect.position.y >= 700:
		panel.anchor_right = 1
		panel.anchor_top = 1
		panel.anchor_bottom = 1
		panel.offset_left = rect.position.x
		panel.offset_right = rect.end.x - 1280
		panel.offset_top = rect.position.y - 800
		panel.offset_bottom = rect.end.y - 800
	elif rect.position.x >= 800:
		panel.anchor_left = 1
		panel.anchor_right = 1
		panel.offset_left = rect.position.x - 1280
		panel.offset_right = rect.end.x - 1280
	elif rect.position.x >= 350 and rect.size.x >= 400:
		panel.anchor_left = 0.5
		panel.anchor_right = 0.5
		panel.offset_left = rect.position.x - 640
		panel.offset_right = rect.end.x - 640
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172321ec")
	style.border_color = Color("657263")
	style.set_border_width_all(1)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	hud.add_child(panel)
	return panel

static func build(world: Node2D) -> void:
	world.hud.add_child(world.observation_menu)
	world.observation_menu.id_pressed.connect(world.context_action)
	var context_tuning: MenuSettings = world.host.menu_settings if world.host.menu_settings != null and world.host.menu_settings.valid() else MenuSettings.new()
	world.observation_menu.add_theme_font_size_override("font_size", context_tuning.font_size)
	world.observation_menu.add_theme_color_override("font_color", context_tuning.text)
	world.observation_menu.add_theme_color_override("font_hover_color", context_tuning.accent)
	world.observation_menu.add_theme_stylebox_override("panel", preload("res://scripts/ui/menu_theme.gd").box(context_tuning.background, context_tuning.accent, 4))
	world.observation_menu.add_theme_stylebox_override("hover", preload("res://scripts/ui/menu_theme.gd").box(context_tuning.surface.lightened(0.15), context_tuning.surface, 2))
	var title: PanelContainer = world.panel_at(Rect2(24, 24, 160, 44))
	var location_style := preload("res://scripts/ui/menu_theme.gd").box(Color("182c25"), Color("31453b"), 4)
	location_style.content_margin_left = 10
	location_style.content_margin_right = 10
	location_style.content_margin_top = 5
	location_style.content_margin_bottom = 5
	title.add_theme_stylebox_override("panel", location_style)
	var title_box := VBoxContainer.new()
	title.add_child(title_box)
	world.location_label = world.label("", 14)
	title_box.add_child(world.location_label)
	var mission: PanelContainer = world.panel_at(Rect2(852, 24, 404, 48))
	var mission_box := VBoxContainer.new()
	mission.add_child(mission_box)
	world.objective = world.label("", 17)
	mission_box.add_child(world.objective)
	var footer: PanelContainer = world.panel_at(Rect2(24, 738, 430, 38))
	world.interaction_hint = world.label("Right-click to interact", 16)
	world.interaction_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(world.interaction_hint)
	footer.hide()
	world.toast = world.label("", 18, Color("ead6a4"))
	world.toast.position = Vector2(42, 675)
	world.hud.add_child(world.toast)
	world.inspection_card = preload("res://scripts/ui/inspection_card.gd").new()
	world.hud.add_child(world.inspection_card)
	world.inspection_card.bind(world, world.host.menu_settings)
	world.inspection_panel = world.inspection_card
	world.inspection = world.inspection_card.details_label

	world.diagnostic = world.label("", 14)
	world.diagnostic.position = Vector2(26, 130)
	world.diagnostic.visible = false
	world.hud.add_child(world.diagnostic)
	# FieldMenu owns the visible Guide/Journal; pause has its own true pause layer.
	world.pause_panel = PanelContainer.new()
	world.pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world.pause_panel.theme = preload("res://scripts/ui/menu_theme.gd").build(world.host.menu_settings if world.host.menu_settings != null and world.host.menu_settings.valid() else MenuSettings.new())
	world.pause_panel.add_theme_stylebox_override("panel", preload("res://scripts/ui/menu_theme.gd").box(Color(0.02, 0.04, 0.03, 0.65), Color.TRANSPARENT))
	world.hud.add_child(world.pause_panel)
	var pause_center := CenterContainer.new()
	world.pause_panel.add_child(pause_center)
	var pause_card := PanelContainer.new()
	pause_card.custom_minimum_size = Vector2(340, 180)
	pause_center.add_child(pause_card)
	var pause_rows := VBoxContainer.new()
	pause_rows.add_theme_constant_override("separation", 12)
	pause_card.add_child(pause_rows)
	pause_rows.add_child(world.label("PAUSED", 24, Color("e1c791")))
	pause_rows.add_child(world.label("Exploration is paused.", 16))
	var resume := Button.new()
	resume.text = "Resume · Esc"
	resume.custom_minimum_size.y = 42
	resume.pressed.connect(world.toggle_pause)
	pause_rows.add_child(resume)
	world.pause_panel.hide()
	world.history.scroll_following = true
	world.menu = preload("res://scripts/ui/field_menu.gd").new()
	world.host.add_child(world.menu)
	world.menu.bind(world, world.host.menu_settings)
	world.state_replaced.connect(world.resume_exploration)
	world.confirmation.title = "Start another expedition?"
	world.confirmation.dialog_text = "Unsaved travel will be lost. Your saved expedition stays available with F9."
	world.confirmation.confirmed.connect(world.confirm_new_expedition)
	world.hud.add_child(world.confirmation)
	world.accessibility = preload("res://scripts/ui/hud_accessibility.gd").new()
	world.host.add_child(world.accessibility)
	world.accessibility.bind(world)
