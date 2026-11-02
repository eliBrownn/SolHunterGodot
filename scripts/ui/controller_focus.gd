extends RefCounted
## Deterministic focus paths and focus memory, independent of tactical commands.
var root: Node
var current: Control
var remembered: Dictionary = {}
var formatter: Callable

func controls(node: Node, output: Array[Control]) -> void:
	if (node is CanvasItem and not node.is_visible_in_tree()) or (node is Window and not node.visible):
		return
	if node is BaseButton and not node.disabled or (node is HSlider and node.editable) or node is RichTextLabel:
		output.append(node)
	for child in node.get_children(true):
		if not child is Window:
			controls(child, output)

func key(control: Control) -> String:
	if control.has_meta("training_action"):
		return str(control.get_meta("training_action"))
	if control.has_meta("pad_label"):
		return str(control.get_meta("pad_label"))
	if control is OptionButton:
		return "option:" + (control.get_item_text(0) if control.item_count else "")
	if control is BaseButton:
		return str(control.text).get_slice("\n", 0)
	return control.get_class()

func select(control: Control) -> void:
	current = control
	control.focus_mode = Control.FOCUS_ALL
	control.grab_focus()
	if root != null:
		if not remembered.has(root.get_instance_id()) and remembered.size() >= 32:
			remembered.erase(remembered.keys()[0])
		remembered[root.get_instance_id()] = key(control)
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			reveal.call_deferred(parent, control)
		parent = parent.get_parent()

func reveal(scroll: ScrollContainer, control: Control) -> void:
	# Pages can rebuild before the deferred scroll runs.
	if is_instance_valid(scroll) and is_instance_valid(control) and scroll.is_ancestor_of(control):
		scroll.ensure_control_visible(control)

func ensure(surface: Node) -> Array[Control]:
	var items: Array[Control] = []
	if surface == null:
		root = null
		current = null
		return items
	controls(surface, items)
	if items.is_empty():
		root = surface
		current = null # Empty/new pages must never activate a control on the previous page.
		return items
	for index in range(items.size()):
		var node := items[index]
		if node is BaseButton and formatter.is_valid():
			var original: String = node.get_meta("pad_desktop_text", node.text)
			var formatted: String = formatter.call(original)
			if formatted != original:
				node.set_meta("pad_desktop_text", original)
				node.text = formatted
		node.focus_mode = Control.FOCUS_ALL
		var previous := items[posmod(index - 1, items.size())].get_path()
		var next := items[(index + 1) % items.size()].get_path()
		node.focus_neighbor_top = previous
		node.focus_neighbor_bottom = next
		node.focus_previous = previous
		node.focus_next = next
	if root != surface or not is_instance_valid(current) or not items.has(current):
		root = surface
		var wanted: String = remembered.get(surface.get_instance_id(), "")
		var initial := items[0]
		for node in items:
			if key(node) == wanted:
				initial = node
		var preferred: Variant = surface.get_meta("pad_default_focus") if surface.has_meta("pad_default_focus") else null
		if preferred is WeakRef and items.has(preferred.get_ref()):
			initial = preferred.get_ref()
		# Destructive dialogs start on Cancel, never on a consequential action.
		if surface is ConfirmationDialog:
			initial = surface.get_cancel_button()
		select(initial)
	return items

func move(surface: Node, direction: Vector2i) -> void:
	var items := ensure(surface)
	if items.is_empty():
		return
	if current is HSlider and direction.x != 0:
		current.value = clampf(current.value + direction.x * current.step, current.min_value, current.max_value)
		return
	var step := direction.y if direction.y != 0 else direction.x
	select(items[posmod(items.find(current) + step, items.size())])

func activate(surface: Node) -> void:
	ensure(surface)
	if not is_instance_valid(current):
		return
	var selected := current
	if selected is OptionButton:
		selected.show_popup()
	elif selected is Button and not selected.disabled:
		if selected.toggle_mode:
			selected.button_pressed = not selected.button_pressed
		if is_instance_valid(selected) and selected.is_inside_tree():
			selected.pressed.emit()

func scroll(surface: Node, amount: float) -> void:
	ensure(surface)
	if not is_instance_valid(current):
		return
	if current is RichTextLabel and current.scroll_active:
		current.get_v_scroll_bar().value += amount
		return
	var node: Node = current
	while node != null:
		if node is ScrollContainer:
			node.scroll_vertical += roundi(amount)
			return
		node = node.get_parent()
