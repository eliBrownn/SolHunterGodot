extends "res://scripts/application/world_solid.gd"
## F6 writing preview over the actual expedition. Saves stay in a separate artifact path.
@export var preview_events: Array[StoryEvent] = []

func _ready() -> void:
	super._ready()
	DirAccess.make_dir_recursive_absolute("res://artifacts/story-preview")
	world.menu.save_path = "res://artifacts/story-preview/expedition.json"
	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x = 220
	world.hud.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	controls.position = Vector2(get_viewport().get_visible_rect().size.x - 240, 118)
	get_viewport().size_changed.connect(func() -> void:
		controls.position.x = get_viewport().get_visible_rect().size.x - 240)
	for content in preview_events:
		var button := Button.new()
		button.text = content.title if content != null else "Missing preview"
		controls.add_child(button)
		button.pressed.connect(func() -> void:
			if not story.play(content):
				world.message("Preview unavailable: finish prerequisites, leave menus or start a new expedition to replay."))
	var note := Label.new()
	note.text = "Preview save is separate"
	controls.add_child(note)

func _unhandled_input(input: InputEvent) -> void:
	if story != null and not story.window.visible and not input.is_echo():
		if input.is_action_pressed("save_expedition") or input.is_action_pressed("load_expedition"):
			if input.is_action_pressed("save_expedition"):
				world.save_game(world.menu.save_path)
			else:
				world.load_game(world.menu.save_path)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(input)
