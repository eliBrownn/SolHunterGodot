extends Node
## Owned companion selection, storage and remembered four-slot equipment outside battle.
var controller: Node
var world: Node2D
var panel: PanelContainer
var rows: VBoxContainer
var identity := ""
var opened := false
var embedded_rows: VBoxContainer
var embedded_notice: Callable
var embedded_section := "all"

func render_into(target: VBoxContainer, id: String, notice: Callable = Callable(), section: String = "all") -> void:
	# Reuse the same owned-state commands inside FieldMenu without taking a
	# second encounter/pause lock or opening another floating panel.
	embedded_rows = target
	embedded_section = section
	embedded_notice = notice
	identity = id
	refresh()

func notify(text: String, record: bool = true) -> void:
	world.message(text, record)
	if not opened and embedded_notice.is_valid():
		embedded_notice.call(text)

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
	var display_rows: VBoxContainer = embedded_rows if is_instance_valid(embedded_rows) and not opened else rows
	for child in display_rows.get_children():
		display_rows.remove_child(child)
		child.queue_free() # A button may be rebuilding its own rows from its pressed signal.
	var book: Dictionary = controller.source_state.movebook(identity)
	if opened or embedded_section == "all":
		display_rows.add_child(world.label("COMPANIONS & MOVES", 23, Color("e1c791")))
		var roster := OptionButton.new()
		roster.fit_to_longest_item = false
		roster.clip_text = true
		var owned: Array = controller.source_state.collection_view().owned.keys()
		for id in owned:
			var companion: Dictionary = controller.source_state.companion_view(id)
			roster.add_item("%s · Lv %d · HP %d/%d · %s" % [companion.profile.display_name, int(companion.profile.level), int(companion.hp), int(companion.profile.max_hp), controller.source_state.individual_view(id).location])
		roster.select(owned.find(identity))
		roster.item_selected.connect(func(index: int) -> void:
			identity = owned[index]
			refresh())
		display_rows.add_child(roster)
	var companion: Dictionary = controller.source_state.companion_view(identity)
	if opened:
		var preview := preload("res://scripts/sol_model_preview.gd").new()
		preview.custom_minimum_size = Vector2(0, 160)
		display_rows.add_child(preview)
		preview.show_profile(companion.profile, controller.sightings.visual_settings, world.menu.settings, controller.settings.species_catalog)
	var threshold: int = controller.progression.threshold_factor * int(companion.profile.level) * int(companion.profile.level)
	display_rows.add_child(world.label("Level %d · XP %d%s · victory earns XP" % [int(companion.profile.level), int(companion.xp), " · at cap" if int(companion.profile.level) >= controller.progression.level_cap else "/%d" % threshold], 16))
	if opened or embedded_section in ["all", "training"]:
		build_stats(display_rows, companion)
	if not opened and embedded_section == "training":
		return
	if opened or embedded_section == "all":
		var location: String = controller.source_state.individual_view(identity).location
		controller.button("Store companion" if location == "party" else "Bring into party", func() -> void:
			if not controller.source_state.transfer_companion(identity, "storage" if location == "party" else "party"):
				notify("Keep one companion in your party; party capacity is six.", false)
			else:
				notify("Companion moved to %s." % ("storage" if location == "party" else "party"))
			refresh(), display_rows)
		controller.button("Use in next encounter", func() -> void:
			if controller.source_state.select_companion(identity):
				notify("%s will deploy next." % companion.profile.display_name)
			else:
				notify("Bring this companion into your party first.", false), display_rows)
	display_rows.add_child(world.label("Equipped moves", 16))
	var learned: Array = book.learned.keys()
	for slot in range(4):
		var options := OptionButton.new()
		options.fit_to_longest_item = false
		options.clip_text = true
		options.custom_minimum_size.y = 36
		options.tooltip_text = "Choose a remembered move for this slot."
		options.add_item("%d · Empty" % [slot + 1])
		for id in learned:
			var move: Dictionary = book.learned[id]
			options.add_item("%d · %s · %s" % [slot + 1, move.name, str(move.affinity).capitalize()])
			options.get_popup().set_item_tooltip(options.item_count - 1, controller.move_description(move))
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
				notify("Equip one to four distinct remembered moves.", false)
			else:
				notify("Equipped moves updated.")
			refresh())
		display_rows.add_child(options)
	var pending: Array[String] = []
	for id in book.pool:
		if not book.learned.has(id):
			var move: Dictionary = controller.library.find(id)
			if move.is_empty():
				continue
			pending.append("Lv %d · %s · %s" % [int(companion.unlocks.get(id, 55)), move.name, str(move.affinity).capitalize()])
	if not pending.is_empty():
		display_rows.add_child(world.label("Future species moves", 18, Color("e1c791")))
		for description in pending:
			display_rows.add_child(world.label(description, 15))


func close() -> void:
	if not opened:
		return
	opened = false
	panel.hide()
	world.encounter_active = false
	world.paused = false


func build_stats(target: VBoxContainer, companion: Dictionary) -> void:
	var state: ExpeditionState = controller.source_state
	var traits := state.stat_view(identity)
	if traits.is_empty():
		return
	var record := state.individual_view(identity)
	var caps := SolStats.capacity(traits, int(record.ordinary_form))
	var unspent := int(traits.earned) - SolStats.spent(traits)
	target.add_child(world.label("Individual stats · natural potential stays fixed for life", 17, Color("e1c791")))
	var definition: ClassBuffDefinition = controller.settings.class_buffs.definition(record.class_id)
	if definition != null:
		var unit := " tiles" if record.class_id == "skyborne" else (" turns" if record.class_id == "feyborn" else "%")
		var text := "%s · %s%s" % [definition.display_name, str(traits.potency), unit]
		if record.class_id == "earthbound":
			text = "Surefooted · difficult ground costs normal movement"
		var passive_label: Label = world.label(text, 16)
		passive_label.tooltip_text = definition.description
		target.add_child(passive_label)
	target.add_child(world.label("Training earned %d/%d · unspent %d · per-stat cap %d" % [traits.earned, caps.total, unspent, caps.stat], 15))
	var natural := traits.duplicate(true)
	for stat in SolStats.STATS:
		natural.training[stat] = 0
	var baseline := SolStats.resolve(natural, int(companion.profile.level))
	for stat in SolStats.STATS:
		var line := HBoxContainer.new()
		target.add_child(line)
		var title := "HP" if stat == "max_hp" else str(stat).replace("_", " ").capitalize()
		var description: Label = world.label("%s  %d · IV %d%% · natural %d · training +%.1f%%" % [title, companion.profile[stat], traits.ivs[stat], baseline[stat], SolStats.bonus(traits, stat)], 14)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(description)
		for increment in [1, 10]:
			var add: Button = controller.button("+%d" % increment, func() -> void:
				if state.allocate_training(identity, stat, increment):
					notify("Training allocated to " + title + ".", false)
				refresh(), line)
			add.custom_minimum_size = Vector2(48, 30)
			add.set_meta("training_action", stat + ":" + str(increment))
			add.disabled = unspent < increment or int(traits.training[stat]) + increment > int(caps.stat)
	var inspected_identity := identity
	var reset: Button = controller.button("Reset training · costs 1 retraining item · %d remaining" % state.retraining_items(), func() -> void:
		var dialog := ConfirmationDialog.new()
		dialog.title = "Reset training?"
		dialog.set_meta("field_menu_owned", not opened)
		dialog.dialog_text = "Consume one retraining item and return all allocated training points. Natural IVs and level growth stay fixed."
		world.hud.add_child(dialog)
		dialog.confirmed.connect(func() -> void:
			if controller.source_state == state and state.reset_training(inspected_identity):
				notify("Training points returned for redistribution.")
			refresh()
			dialog.queue_free())
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered(Vector2i(520, 160)), target)
	reset.disabled = state.retraining_items() <= 0 or SolStats.spent(traits) == 0
	reset.set_meta("training_action", "reset")
