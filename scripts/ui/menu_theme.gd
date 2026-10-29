extends RefCounted

static func box(color: Color, border: Color, radius: int = 5) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func build(settings: MenuSettings) -> Theme:
	var theme := Theme.new()
	theme.default_font_size = settings.font_size
	theme.set_stylebox("panel", "TooltipPanel", box(settings.background, settings.accent))
	theme.set_color("font_color", "TooltipLabel", settings.text)
	theme.set_font_size("font_size", "TooltipLabel", roundi(settings.font_size * settings.text_scale * settings.base_text_multiplier))
	theme.set_stylebox("panel", "AcceptDialog", box(settings.background, settings.accent))
	theme.set_stylebox("embedded_border", "Window", box(settings.background, settings.accent))
	theme.set_stylebox("embedded_unfocused_border", "Window", box(settings.background, settings.surface))
	theme.set_color("title_color", "Window", settings.text)
	theme.set_color("font_color", "Label", settings.text)
	theme.set_color("default_color", "RichTextLabel", settings.text)
	for type in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", type, box(Color.TRANSPARENT if type == "Button" else settings.surface, settings.surface.lightened(0.1)))
		theme.set_stylebox("hover", type, box(settings.surface.lightened(0.12), settings.accent))
		theme.set_stylebox("pressed", type, box(settings.accent, settings.accent))
		theme.set_stylebox("hover_pressed", type, box(settings.surface.lightened(0.12), settings.accent))
		theme.set_stylebox("disabled", type, box(settings.surface.darkened(0.25), settings.surface))
		var focus := box(Color.TRANSPARENT, settings.accent)
		focus.set_border_width_all(2)
		theme.set_stylebox("focus", type, focus)
		theme.set_color("font_color", type, settings.text)
		theme.set_color("font_hover_color", type, settings.text)
		theme.set_color("font_pressed_color", type, settings.background)
		theme.set_color("font_disabled_color", type, settings.text.darkened(0.45))
	theme.set_stylebox("panel", "PanelContainer", box(settings.surface.darkened(0.15), settings.surface.lightened(0.12)))
	theme.set_stylebox("background", "ProgressBar", box(settings.background, settings.surface, 5))
	theme.set_stylebox("fill", "ProgressBar", box(Color("81b990"), Color("81b990"), 5))
	for type in ["HScrollBar", "VScrollBar"]:
		var track := box(settings.background, settings.background, 4)
		track.set_content_margin_all(5)
		theme.set_stylebox("scroll", type, track)
		for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
			var grip := box(settings.surface.lightened(0.2), settings.surface.lightened(0.2), 4)
			grip.set_content_margin_all(5)
			theme.set_stylebox(state, type, grip)
	return theme
