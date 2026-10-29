extends Node
## Shared text preference and bounded, scrollable HUD layout. No simulation ownership.
const Typography = preload("res://scripts/ui_text.gd")
var world: Node2D
var text_scale := -1.0
var pending := false

func bind(source: Node2D) -> void:
	world = source
	get_tree().node_added.connect(on_node_added)
	get_viewport().size_changed.connect(queue_update)
	queue_update()

func on_node_added(node: Node) -> void:
	if world.hud.is_ancestor_of(node):
		queue_update()

func queue_update() -> void:
	if not pending:
		pending = true
		apply_text.call_deferred()

func set_text_scale(value: float) -> void:
	if not is_equal_approx(value, text_scale):
		text_scale = value
		queue_update()

func wrap_panel(panel: PanelContainer) -> void:
	if panel.has_meta("hud_scroll") or panel.get_child_count() != 1:
		return
	var contents := panel.get_child(0) as Control
	if contents == null:
		return
	panel.remove_child(contents)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	scroll.add_child(contents)
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_fixed_widths(contents)
	panel.set_meta("hud_scroll", scroll)
	panel.set_meta("hud_contents", contents)

func clear_fixed_widths(node: Node) -> void:
	if node is Container or node is Label:
		node.custom_minimum_size.x = 0
	if node is ScrollContainer:
		node.follow_focus = true
	for child in node.get_children():
		clear_fixed_widths(child)

func apply_text() -> void:
	pending = false
	text_scale = world.menu.settings.text_scale
	for child in world.hud.get_children():
		# Personal screens and inspection retain their own responsive layouts.
		if child == world.menu.frame or child == world.menu.backdrop or child == world.inspection_card:
			continue
		if child is CombatHud:
			Typography.apply(child, text_scale, false, world.menu.settings.base_text_multiplier)
			child.fit_layout()
			continue
		if child is PanelContainer and child.has_meta("hud_authored_rect"):
			var rect: Rect2 = child.get_meta("hud_authored_rect")
			if rect.size.y >= 150:
				wrap_panel(child)
		Typography.apply(child, text_scale, true, world.menu.settings.base_text_multiplier)
		if child is Window:
			child.max_size = Vector2i(world.hud.get_viewport().get_visible_rect().size - Vector2(24, 24))
			if child is AcceptDialog:
				child.dialog_autowrap = true
		if child is Control and child.theme != null:
			child.theme.set_font_size("font_size", "TooltipLabel", roundi(world.menu.settings.font_size * text_scale * world.menu.settings.base_text_multiplier))
	fit_layout()

func _process(_delta: float) -> void:
	# Only geometry is refreshed each frame; font/tree work is coalesced on changes.
	fit_layout()

func fit_layout() -> void:
	if world == null or world.menu == null or text_scale < 1:
		return
	var bounds: Vector2 = world.hud.get_viewport().get_visible_rect().size
	var available: Vector2 = bounds - Vector2(48, 48)
	for child in world.hud.get_children():
		if not child is PanelContainer or not child.has_meta("hud_authored_rect"):
			continue
		var rect: Rect2 = child.get_meta("hud_authored_rect")
		var width := minf(rect.size.x * sqrt(text_scale), available.x)
		var height := minf(rect.size.y * sqrt(text_scale), available.y) if child.has_meta("hud_scroll") else 0.0
		child.size = Vector2(width, height)
		var at := rect.position
		if rect.position.y >= 700:
			at.y = bounds.y - child.size.y - 24
		elif rect.position.x >= 800:
			at.x = bounds.x - child.size.x - 24
		elif rect.size.y >= 150:
			at = (bounds - child.size) * 0.5
		child.position = at.clamp(Vector2(24, 24), (bounds - child.size - Vector2(24, 24)).max(Vector2(24, 24)))
	var location_panel := world.location_label.get_parent().get_parent() as Control
	world.location_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	location_panel.size = Vector2.ZERO
	var mission_panel := world.objective.get_parent().get_parent() as Control
	var middle_x := location_panel.get_rect().end.x + 24
	var middle_width := maxf(100, mission_panel.position.x - middle_x - 24)
	var clock_y := 24.0
	if world.host.get("view_hint") != null:
		var compass: Label = world.host.view_hint
		compass.position = Vector2(middle_x, 24)
		compass.size = Vector2(middle_width, 0)
		clock_y = compass.get_rect().end.y + 4
	if world.host.get("atmosphere_controller") != null:
		var clock: Label = world.host.atmosphere_controller.status
		clock.position = Vector2(middle_x, clock_y)
		clock.size = Vector2(middle_width, 0)
	world.inspection_card.arrange_stack(location_panel.get_rect().end.y + 12)
	world.diagnostic.size = Vector2(minf(available.x, 760 * sqrt(text_scale)), 0)
	world.menu.launcher.position = Vector2(bounds.x - world.menu.launcher.size.x - 24, mission_panel.get_rect().end.y + 12)
	var footer := world.interaction_hint.get_parent() as Control
	world.toast.size = Vector2(minf(available.x, 650 * sqrt(text_scale)), 0)
	world.toast.position = Vector2(24, bounds.y - world.toast.size.y - (footer.size.y + 36 if footer.visible else 24))
	if world.host.battles != null:
		var companion: Label = world.host.battles.companion_label
		companion.size = Vector2(world.toast.size.x, 0)
		companion.position = Vector2(24, world.toast.position.y - companion.size.y - 10)
