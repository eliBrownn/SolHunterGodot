extends VBoxContainer
## Read-only inspection is distinct from active-companion and transfer commands.
const Preview = preload("res://scripts/sol_model_preview.gd")
var menu: Node
var controller: Node
var world: Node2D
var roster := VBoxContainer.new()
var detail := VBoxContainer.new()
var layout := HBoxContainer.new()
var stacked := VBoxContainer.new()
var roster_panel := VBoxContainer.new()
var detail_scroll := ScrollContainer.new()
var list_scroll := ScrollContainer.new()
var preview: SubViewportContainer
var use_button: Button
var transfer_button: Button
var tabs: Dictionary = {}
var entries: Dictionary = {}
var selected_profile: Dictionary = {}
var information: Dictionary = {}
var info_groups: Dictionary = {}
var starter_mode := false
var adapting := false
func bind(owner_menu: Node) -> void:
	menu = owner_menu
	world = menu.world
	controller = world.host.battles
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	starter_mode = world.persistent_state.collection_view().owned.is_empty()
	add_theme_constant_override("separation", 10)
	add_child(layout)
	add_child(stacked)
	layout.add_theme_constant_override("separation", 14)
	stacked.add_theme_constant_override("separation", 14)
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stacked.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(roster_panel)
	layout.add_child(detail_scroll)
	roster_panel.add_theme_constant_override("separation", 8)
	var filters := HBoxContainer.new()
	roster_panel.add_child(filters)
	if not starter_mode:
		for location in ["party", "storage"]:
			var count := 0
			for id in world.persistent_state.collection_view().owned:
				if world.persistent_state.individual_view(id).location == location:
					count += 1
			var filter: Button = menu.button(str(location).capitalize(), set_filter.bind(location), filters)
			filter.tooltip_text = "%d Sols in %s" % [count, location]
			filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			filter.toggle_mode = true
			filter.set_pressed_no_signal(menu.sol_filter == location)
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.follow_focus = true
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_panel.add_child(list_scroll)
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster.add_theme_constant_override("separation", 4)
	list_scroll.add_child(roster)
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.follow_focus = true
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 6)
	detail_scroll.add_child(detail)
	resized.connect(adapt_layout.call_deferred)
	populate()
	adapt_layout.call_deferred()
func set_filter(location: String) -> void:
	remember_scroll()
	menu.sol_filter = location
	menu.sol_list_scroll = 0
	menu.refresh_page()
func remember_scroll() -> void:
	menu.sol_list_scroll = list_scroll.scroll_vertical
	menu.sol_detail_scroll = detail_scroll.scroll_vertical
func populate() -> void:
	var state: ExpeditionState = world.persistent_state
	var active := state.active_sol_view()
	if starter_mode:
		for index in range(controller.settings.starters.size()):
			var profile: BattleProfile = controller.settings.starters[index]
			var entry: Button = menu.button("%s\n%s · HP %d" % [profile.display_name, profile.affinity.capitalize(), profile.max_hp], inspect_starter.bind(index), roster)
			entry.toggle_mode = true
			entry.set_pressed_no_signal(index == menu.sol_starter)
			entries[str(index)] = entry
		show_details(controller.settings.starters[menu.sol_starter].snapshot())
	else:
		var owned: Dictionary = state.collection_view().owned
		var visible_ids: Array[String] = []
		for id in owned:
			if state.individual_view(id).location == menu.sol_filter:
				visible_ids.append(id)
		if not visible_ids.has(menu.sol_selection):
			menu.sol_selection = active.get("id", "") if visible_ids.has(active.get("id", "")) else (visible_ids[0] if not visible_ids.is_empty() else "")
		for id in visible_ids:
			var companion := state.companion_view(id)
			var status := " ★" if active.get("id", "") == id else ""
			var entry: Button = menu.button("%s%s\nLv %d · %d/%d" % [companion.profile.display_name, status, companion.profile.level, companion.hp, companion.profile.max_hp], inspect.bind(id), roster)
			entry.tooltip_text = "%s · %s\nHP %d/%d\n%s" % [str(companion.profile.affinity).capitalize(), str(companion.profile.class_id).capitalize(), companion.hp, companion.profile.max_hp, "Active companion" if active.get("id", "") == id else "Click to inspect; this does not change your active companion."]
			entry.toggle_mode = true
			entry.set_pressed_no_signal(id == menu.sol_selection)
			entries[id] = entry
		if menu.sol_selection.is_empty():
			detail.add_child(menu.caption("No Sols in %s." % menu.sol_filter, 20))
		else:
			show_details(state.companion_view(menu.sol_selection).profile)
	list_scroll.set_deferred("scroll_vertical", menu.sol_list_scroll)
	detail_scroll.set_deferred("scroll_vertical", menu.sol_detail_scroll)
func inspect_starter(index: int) -> void:
	remember_scroll()
	menu.sol_starter = index
	menu.sol_detail_scroll = 0
	menu.refresh_page()
func inspect(id: String) -> void:
	remember_scroll()
	menu.sol_selection = id
	menu.sol_detail_scroll = 0
	menu.refresh_page()
func set_tab(tab: String) -> void:
	remember_scroll()
	menu.sol_tab = tab
	menu.sol_detail_scroll = 0
	menu.refresh_page()
func set_info_section(section: String) -> void:
	remember_scroll()
	menu.sol_info_section = section
	menu.sol_detail_scroll = 0
	menu.refresh_page()
func show_details(profile: Dictionary) -> void:
	selected_profile = profile.duplicate(true)
	detail.add_child(menu.caption(str(profile.display_name), 24, menu.settings.accent))
	detail.add_child(menu.caption("%s" % str(profile.affinity).capitalize(), 16))
	var tab_row := HFlowContainer.new()
	detail.add_child(tab_row)
	for tab in (["summary", "details"] if starter_mode else ["summary", "details", "moves", "training"]):
		var button: Button = menu.button(str(tab).capitalize(), set_tab.bind(tab), tab_row)
		button.custom_minimum_size.x = 110
		button.toggle_mode = true
		button.set_pressed_no_signal(menu.sol_tab == tab)
		tabs[tab] = button
	var model_panel := PanelContainer.new()
	detail.add_child(model_panel)
	preview = Preview.new()
	preview.custom_minimum_size = Vector2(0, menu.settings.preview_height * (0.6 if menu.sol_tab == "details" else 1.0))
	model_panel.add_child(preview)
	preview.show_profile(profile, controller.sightings.visual_settings, menu.settings, controller.settings.species_catalog)
	preview.tooltip_text = "%s · Lv %d\n%s affinity · %s class" % [profile.display_name, int(profile.level), str(profile.affinity).capitalize(), SolSpeciesCatalog.class_display_name(profile.class_id)]
	if starter_mode:
		menu.button("Choose " + str(profile.display_name), menu.choose_starter.bind(menu.sol_starter), detail).tooltip_text = "Choose once for this expedition. Inspecting a starter does not commit the choice."
		if menu.sol_tab == "details":
			preload("res://scripts/sol_details.gd").build_starter(self, detail, profile)
		return
	var state: ExpeditionState = world.persistent_state
	var companion := state.companion_view(menu.sol_selection)
	var active := state.active_sol_view()
	var record := state.individual_view(menu.sol_selection)
	var health := ProgressBar.new()
	health.max_value = int(profile.max_hp)
	health.value = companion.hp
	health.custom_minimum_size.y = 8
	health.show_percentage = false
	detail.add_child(health)
	health.visible = menu.sol_tab != "details"
	health.tooltip_text = "HP %d / %d" % [companion.hp, profile.max_hp]
	if menu.sol_tab != "details":
		detail.add_child(menu.caption("%d / %d HP" % [companion.hp, profile.max_hp], 14))
	var actions := HFlowContainer.new()
	detail.add_child(actions)
	actions.visible = menu.sol_tab != "details"
	use_button = menu.button("Active" if active.id == menu.sol_selection else "Set active", activate, actions)
	use_button.custom_minimum_size.x = 110
	use_button.disabled = record.location != "party" or active.id == menu.sol_selection
	use_button.tooltip_text = "Already your active companion." if active.id == menu.sol_selection else ("Bring this Sol into your party first." if record.location != "party" else "Choose this Sol to accompany you and deploy in the next encounter.")
	transfer_button = menu.button("Store" if record.location == "party" else "Add to party", transfer, actions)
	var party_count := 0
	for id in state.collection_view().owned:
		if state.individual_view(id).location == "party":
			party_count += 1
	transfer_button.disabled = (record.location == "party" and party_count <= 1) or (record.location == "storage" and party_count >= CollectionProgress.PARTY_LIMIT)
	transfer_button.tooltip_text = "Keep at least one Sol in your party; party capacity is six."
	if world.terrain.is_camp(world.cell) and state.collection_view().owned.values().any(func(row: Dictionary) -> bool: return int(row.hp) < int(row.profile.max_hp)):
		var recover: Button = menu.button("Recover", recover_party, actions)
		recover.tooltip_text = "Recover party health at the refuge."
		recover.disabled = world.moving

	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	detail.add_child(body)
	if menu.sol_tab == "summary":
		var threshold: int = controller.progression.threshold_factor * int(profile.level) * int(profile.level)
		preview.tooltip_text += "\nXP %d / %d" % [companion.xp, threshold]
		body.add_child(menu.caption("Physical %d · Special %d · Speed %d" % [profile.attack, profile.special_attack, profile.speed], 16))
		var ability: ClassBuffDefinition = controller.settings.class_buffs.definition(profile.class_id)
		if ability != null:
			var ability_label: Label = menu.caption(ability.display_name, 16, menu.settings.accent)
			ability_label.tooltip_text = ability.description
			ability_label.mouse_filter = Control.MOUSE_FILTER_STOP
			body.add_child(ability_label)
		var count: int = world.persistent_state.movebook(menu.sol_selection).equipped.size()
		body.add_child(menu.caption("%d equipped moves · Details for combat, growth and history" % count, 14))
		for stat in SolStats.STATS:
			if stat != "max_hp":
				preview.tooltip_text += "\n%s: %d" % [str(stat).replace("_", " ").capitalize(), int(profile[stat])]
	elif menu.sol_tab == "details":
		information = preload("res://scripts/sol_details.gd").build(self, body)
	else:
		controller.loadout.render_into(body, menu.sol_selection, func(text: String) -> void:
			menu.feedback.text = text, menu.sol_tab)
func recover_party() -> void:
	controller.recover()
	menu.feedback.text = world.toast.text
	remember_scroll()
	menu.refresh_page()
func activate() -> void:
	if world.persistent_state.select_companion(menu.sol_selection):
		menu.feedback.text = "%s is your active companion." % selected_profile.display_name
	remember_scroll()
	menu.refresh_page()
func transfer() -> void:
	var state: ExpeditionState = world.persistent_state
	var destination := "storage" if state.individual_view(menu.sol_selection).location == "party" else "party"
	if state.transfer_companion(menu.sol_selection, destination):
		menu.feedback.text = "Companion moved to " + destination + "."
		menu.sol_filter = destination
	remember_scroll()
	menu.refresh_page()
func adapt_layout() -> void:
	if not is_inside_tree() or adapting:
		return
	adapting = true
	var compact: bool = size.x < 600 * menu.settings.text_scale
	var destination: BoxContainer = stacked if compact else layout
	if roster_panel.get_parent() != destination:
		roster_panel.reparent(destination)
		detail_scroll.reparent(destination)
	layout.visible = not compact
	stacked.visible = compact
	roster_panel.custom_minimum_size.x = 0 if compact else 170 * menu.settings.text_scale
	roster_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
	list_scroll.custom_minimum_size.y = 110 if compact else 260
	detail_scroll.custom_minimum_size.y = 320
	adapting = false
