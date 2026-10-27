extends Node
## Owned companion selection, storage and remembered four-slot equipment outside battle.
var controller: Node
var world: Node2D
var panel: PanelContainer
var rows: VBoxContainer
var identity := ""
var opened := false

func bind(owner_controller: Node) -> void:
	controller = owner_controller
	world = controller.world
	panel = world.panel_at(Rect2(280, 125, 720, 560))
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", 12)
	panel.add_child(frame)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(680, 450)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	rows = VBoxContainer.new()
	rows.custom_minimum_size.x = 655
	rows.add_theme_constant_override("separation", 10)
	scroll.add_child(rows)
	controller.button("Close · Escape", close, frame)
	panel.hide()
	world.withdraw_requested.connect(close)
	world.state_replaced.connect(func(_state: ExpeditionState) -> void: close())

func open(id: String) -> void:
	if controller.source_state.movebook(id).is_empty():
		world.message("This companion has no authored species move pool yet.", false)
		return
	identity = id
	opened = true
	world.encounter_active = true
	world.paused = true
	world.pause_panel.hide()
	world.journal_panel.hide()
	controller.feedback_view.result_panel.hide()
	refresh()
	panel.show()

func refresh() -> void:
	for child in rows.get_children():
		child.free()
	var book: Dictionary = controller.source_state.movebook(identity)
	rows.add_child(world.label("COMPANIONS & MOVES", 23, Color("e1c791")))
	var roster := OptionButton.new()
	var owned: Array = controller.source_state.collection_view().owned.keys()
	for id in owned:
		var companion: Dictionary = controller.source_state.companion_view(id)
		roster.add_item("%s · Lv %d · HP %d/%d · %s" % [companion.profile.display_name, int(companion.profile.level), int(companion.hp), int(companion.profile.max_hp), controller.source_state.individual_view(id).location])
	roster.select(owned.find(identity))
	roster.item_selected.connect(func(index: int) -> void:
		identity = owned[index]
		controller.source_state.select_companion(identity)
		refresh())
	rows.add_child(roster)
	var companion: Dictionary = controller.source_state.companion_view(identity)
	var threshold: int = controller.progression.threshold_factor * int(companion.profile.level) * int(companion.profile.level)
	rows.add_child(world.label("Level %d · XP %d%s · victory earns XP" % [int(companion.profile.level), int(companion.xp), " · at cap" if int(companion.profile.level) >= controller.progression.level_cap else "/%d" % threshold], 16))
	var location: String = controller.source_state.individual_view(identity).location
	controller.button("Store companion" if location == "party" else "Bring into party", func() -> void:
		if not controller.source_state.transfer_companion(identity, "storage" if location == "party" else "party"):
			world.message("Keep one companion in your party; party capacity is six.", false)
		refresh(), rows)
	controller.button("Use in next encounter", func() -> void:
		if controller.source_state.select_companion(identity):
			world.message("%s will deploy next." % companion.profile.display_name)
		else:
			world.message("Bring this companion into your party first.", false), rows)
	rows.add_child(world.label("Four equipped · remembered moves remain available", 16))
	var learned: Array = book.learned.keys()
	for slot in range(4):
		var options := OptionButton.new()
		options.custom_minimum_size.y = 36
		options.add_item("%d · Empty" % [slot + 1])
		for id in learned:
			var move: Dictionary = book.learned[id]
			options.add_item("%d · %s · %s" % [slot + 1, move.name, str(move.affinity).capitalize()])
		if slot < book.equipped.size():
			options.select(learned.find(book.equipped[slot]) + 1)
		options.item_selected.connect(func(index: int) -> void:
			var equipped: Array = controller.source_state.movebook(identity).equipped
			if index == 0:
				if slot < equipped.size():
					equipped.remove_at(slot)
			elif slot < equipped.size():
				equipped[slot] = learned[index - 1]
			else:
				equipped.append(learned[index - 1])
			if not controller.source_state.equip_moves(identity, equipped):
				world.message("Equip one to four distinct remembered moves.", false)
			refresh())
		rows.add_child(options)
	var pending: Array[String] = []
	for id in book.pool:
		if not book.learned.has(id):
			var move: Dictionary = controller.library.find(id)
			if move.is_empty():
				continue
			pending.append("Lv %d · %s · %s" % [int(companion.unlocks.get(id, 55)), move.name, str(move.affinity).capitalize()])
	if not pending.is_empty():
		rows.add_child(world.label("Future species moves", 18, Color("e1c791")))
		for description in pending:
			rows.add_child(world.label(description, 15))
	rows.add_child(world.label("Level-up learns moves; a full loadout keeps your four choices.", 14))

func close() -> void:
	if not opened:
		return
	opened = false
	panel.hide()
	world.encounter_active = false
	world.paused = false
