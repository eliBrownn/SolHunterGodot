extends ConfirmationDialog
## Mouse commits consequential world actions; keyboard can only dismiss the dialog.
func _ready() -> void:
	# Native dialog button layout relies on the unwrapped text's minimum width.
	# Shared HUD typography must not turn these into narrow vertical columns.
	for button: Button in [get_ok_button(), get_cancel_button()]:
		button.set_meta("ui_keep_single_line", true)
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
		button.custom_minimum_size = Vector2(120, 36)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode != KEY_ESCAPE:
		get_viewport().set_input_as_handled()
