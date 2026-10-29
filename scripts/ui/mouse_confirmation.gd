extends ConfirmationDialog
## Mouse commits consequential world actions; keyboard can only dismiss the dialog.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode != KEY_ESCAPE:
		get_viewport().set_input_as_handled()
