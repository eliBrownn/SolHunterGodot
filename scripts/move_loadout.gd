extends Node
## Outside-battle move learning and four-slot equipment. No automatic XP or learning-level rule.
var controller: Node
var world: Node2D
var panel: PanelContainer
var rows: VBoxContainer
var identity := ""
var opened := false

func bind(owner_controller: Node) -> void:
	controller = owner_controller
	world = controller.world
	panel = world.panel_at(Rect2(330, 155, 620, 530))
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	panel.add_child(rows)
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
	refresh()
	panel.show()

func refresh() -> void:
	for child in rows.get_children():
		child.free()
	var book: Dictionary = controller.source_state.movebook(identity)
	rows.add_child(world.label("COMPANION MOVES", 23, Color("e1c791")))
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
	var learning := OptionButton.new()
	var available: Array = []
	for id in book.pool:
		if not book.learned.has(id):
			var move: Dictionary = controller.library.find(id)
			if move.is_empty():
				continue
			available.append(id)
			learning.add_item("Learn %s · %s" % [move.name, str(move.affinity).capitalize()])
	rows.add_child(learning)
	var learn := Button.new()
	learn.text = "Learn selected species-pool move"
	learn.disabled = available.is_empty()
	learn.custom_minimum_size.y = 36
	learn.pressed.connect(func() -> void:
		if controller.source_state.learn_move(identity, controller.library.find(available[learning.selected])):
			refresh())
	rows.add_child(learn)
	rows.add_child(world.label("Learn from your species pool; swap remembered moves here.", 14))
	controller.button("Close · Escape", close, rows)

func close() -> void:
	if not opened:
		return
	opened = false
	panel.hide()
	world.encounter_active = false
	world.paused = false
