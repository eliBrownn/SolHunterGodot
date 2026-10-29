class_name MenuSettings
extends Resource
## Defaults for the movable field menu; local preferences override these, never expedition saves.

## Show a gold ground ring beneath the pointed exploration target; presentation only, applies immediately.
@export var pointer_highlight := true
## Observe popup lifetime in real seconds, including its final fade; pinning suspends expiry.
@export_range(1.0, 10.0, 0.5) var observe_seconds := 3.0

## Collapsed inspection width at 100% text, in logical pixels; applies immediately. Details expand for readable readings.
@export_range(160, 360, 1) var inspection_width := 190
## Height of the thin 0–100 environmental meters in logical pixels; applies immediately.
@export_range(3, 10, 1) var inspection_meter_height := 4

## Combat action ribbon width at 100% text, in logical pixels; restart after editing.
@export_range(600, 1200, 10) var combat_width := 900
## Combined combat health-strip width at 100% text; clamps to the viewport. Restart after editing.
@export_range(600, 1200, 10) var combat_health_width := 860

## Unscaled menu size in viewport pixels. New/reset layouts use this size.
@export var window_size := Vector2(940, 620)
## Minimum unscaled menu size. Smaller viewports automatically reduce the effective scale.
@export var minimum_size := Vector2(660, 440)
## Presentation size multiplier. 0.7 makes the field menu 30% smaller; restart to apply.
@export_range(0.5, 1.0, 0.05) var size_multiplier := 0.7
## Requested UI scale relative to the compact base; in-game Options adjusts immediately.
@export_range(0.75, 1.25, 0.05) var ui_scale := 1.0
## Shared HUD/menu text multiplier; adjusts all screen-space interfaces immediately and is remembered locally.
@export_range(1.0, 2.0, 0.05) var text_scale := 1.0
## Base UI text size relative to authored fonts. 0.715 increases the compact baseline by 10%; restart after editing.
@export_range(0.5, 1.0, 0.005) var base_text_multiplier := preload("res://scripts/ui_text.gd").DEFAULT_BASE_MULTIPLIER
## Model-preview window height in logical pixels; applies when opening the Sols page.
@export_range(140, 320, 10) var preview_height := 140
## Preview camera span relative to model diameter; larger values leave more margin.
@export_range(2.0, 4.0, 0.1) var preview_framing := 2.5
## Background opacity only; text remains fully readable.
@export_range(0.7, 1.0, 0.05) var background_opacity := 0.97
## Remember menu layout/scale/opacity in user://menu_preferences.cfg, independently of expedition saves.
@export var remember_layout := true
@export_range(14, 20, 1) var font_size := 16
@export var background := Color("14251f")
@export var surface := Color("20382e")
@export var accent := Color("dbc48d")
@export var text := Color("edf0e5")

func valid() -> bool:
	for size in [window_size, minimum_size]:
		if not size.is_finite() or size.x < 620 or size.x > 1600 or size.y < 380 or size.y > 1000:
			return false
	for color in [background, surface, accent, text]:
		if not is_finite(color.r) or not is_finite(color.g) or not is_finite(color.b) or color.r < 0 or color.r > 1 or color.g < 0 or color.g > 1 or color.b < 0 or color.b > 1 or color.a != 1:
			return false
	return is_finite(observe_seconds) and observe_seconds >= 1.0 and observe_seconds <= 10.0 and is_finite(base_text_multiplier) and base_text_multiplier >= 0.5 and base_text_multiplier <= 1 and combat_width >= 600 and combat_width <= 1200 and combat_health_width >= 600 and combat_health_width <= 1200 and inspection_width >= 160 and inspection_width <= 360 and inspection_meter_height >= 3 and inspection_meter_height <= 10 and is_finite(text_scale) and text_scale >= 1 and text_scale <= 2 and preview_height >= 140 and preview_height <= 320 and is_finite(preview_framing) and preview_framing >= 2 and preview_framing <= 4 and is_finite(size_multiplier) and size_multiplier >= 0.5 and size_multiplier <= 1.0 and minimum_size.x <= window_size.x and minimum_size.y <= window_size.y and is_finite(ui_scale) and ui_scale >= 0.75 and ui_scale <= 1.25 and is_finite(background_opacity) and background_opacity >= 0.7 and background_opacity <= 1 and font_size >= 14 and font_size <= 20
