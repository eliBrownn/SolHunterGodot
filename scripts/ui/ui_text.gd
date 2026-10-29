extends RefCounted
## Shared interface typography; base sizes are remembered to prevent compounding.
const DEFAULT_BASE_MULTIPLIER := 0.715
static func apply(node: Node, scale: float, reflow_labels: bool = true, base_multiplier: float = DEFAULT_BASE_MULTIPLIER) -> void:
	if node is Control:
		var keys: Array[String] = []
		if node is RichTextLabel:
			keys.assign(["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"])
		elif node is Label or node is BaseButton or node is LineEdit or node is PopupMenu:
			keys.assign(["font_size"])
		for key in keys:
			var meta := "ui_base_" + key
			if not node.has_meta(meta):
				node.set_meta(meta, node.get_theme_font_size(key))
			var desired := maxi(1, roundi(int(node.get_meta(meta)) * scale * base_multiplier))
			if node.get_theme_font_size(key) != desired:
				node.add_theme_font_size_override(key, desired)
		if node is Label and reflow_labels and not node.get_meta("ui_keep_single_line", false):
			node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if node is Button and not node is OptionButton:
			node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if not node.has_meta("ui_base_min_width"):
				node.set_meta("ui_base_min_width", node.custom_minimum_size.x)
			var authored: float = node.get_meta("ui_base_min_width")
			node.custom_minimum_size.x = (authored if authored > 0 else 100.0) * scale
	if node is PopupMenu:
		if not node.has_meta("ui_base_font_size"):
			node.set_meta("ui_base_font_size", node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size", roundi(int(node.get_meta("ui_base_font_size")) * scale * base_multiplier))
	if node is OptionButton:
		var popup: PopupMenu = node.get_popup()
		if not popup.has_meta("ui_base_font_size"):
			popup.set_meta("ui_base_font_size", popup.get_theme_font_size("font_size"))
		var desired := roundi(int(popup.get_meta("ui_base_font_size")) * scale * base_multiplier)
		if popup.get_theme_font_size("font_size") != desired:
			popup.add_theme_font_size_override("font_size", desired)
	for child in node.get_children(true):
		apply(child, scale, reflow_labels, base_multiplier)
