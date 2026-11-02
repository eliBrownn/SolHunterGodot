extends Node
## Window-local input interception runs before GUI handling in that viewport.
var router: Node
var surface: Window
func _input(event: InputEvent) -> void:
	router.handle_event(event, surface)
