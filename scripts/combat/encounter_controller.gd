extends Node
## Runtime encounter preview: warnings never pause movement; explicit contact panels do.

var world: Node2D
var sightings: Node3D
var settings: EncounterSettings
var warning_panel: PanelContainer
var warning_label: Label
var encounter_panel: PanelContainer
var title: Label
var description: Label
var observe_button: Button
var withdraw_button: Button
var warning_id := ""
var warning_presented := false
var warning_step := -1
var warning_elapsed := 0.0
var steps := 0
var safe_steps := 0
var active_target: Dictionary = {}
var encounter_state: ExpeditionState
signal battle_requested(target: Dictionary)
signal battle_retreat_requested
var battle_running := false
var battle_button: Button

func bind(source: Node2D, actors: Node3D, tuning: EncounterSettings) -> void:
	world = source
	sightings = actors
	settings = tuning if tuning != null and tuning.valid() else EncounterSettings.new()
	if settings != tuning:
		push_warning("Invalid encounter settings; using prototype defaults.")
	warning_panel = world.panel_at(Rect2(280, 126, 550, 76))
	warning_label = world.label("", 16, Color("f4ce94"))
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_panel.add_child(warning_label)
	warning_panel.hide()
	encounter_panel = world.panel_at(Rect2(405, 190, 470, 410))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	encounter_panel.add_child(box)
	title = world.label("FACE TO FACE", 24, Color("e1c791"))
	box.add_child(title)
	description = world.label("", 17)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(420, 90)
	box.add_child(description)
	observe_button = Button.new()
	observe_button.text = "Record sighting"
	observe_button.custom_minimum_size.y = 42
	observe_button.pressed.connect(observe_target)
	box.add_child(observe_button)
	battle_button = Button.new()
	battle_button.text = "Battle"
	battle_button.custom_minimum_size.y = 42
	battle_button.pressed.connect(func() -> void:
		if not active_target.is_empty():
			battle_requested.emit(active_target.duplicate(true)))
	box.add_child(battle_button)
	withdraw_button = Button.new()
	withdraw_button.text = "Withdraw"
	withdraw_button.custom_minimum_size.y = 42
	withdraw_button.pressed.connect(withdraw)
	box.add_child(withdraw_button)
	encounter_panel.hide()
	world.encounter_requested.connect(approach_nearest)
	world.withdraw_requested.connect(withdraw)
	world.player_step_completed.connect(on_player_step)
	world.state_replaced.connect(reset)
	RenderingServer.frame_post_draw.connect(mark_warning_presented)

func reset(_state: ExpeditionState) -> void:
	clear_warning()
	steps = 0
	safe_steps = 0
	active_target.clear()
	encounter_state = null
	encounter_panel.hide()
	world.encounter_active = false
	battle_running = false

func _process(delta: float) -> void:
	if not active_target.is_empty():
		var record: Dictionary = world.persistent_state.individual_view(active_target.id)
		if world.persistent_state != encounter_state or not world.persistent_state.wild_available(active_target.id):
			withdraw()
		return
	refresh_warning()
	if warning_presented and warning_uncovered():
		warning_elapsed = minf(settings.warning_delay_seconds, warning_elapsed + maxf(0, delta))

func candidates(radius: int, hostile_only: bool = false) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not settings.valid() or not settings.enabled or not sightings.settings.valid() or not sightings.settings.enabled:
		return result
	for member in sightings.members:
		if not world.persistent_state.wild_available(member.id) or (hostile_only and not member.entry.get("hostile", false)):
			continue
		var travel: Dictionary = world.persistent_state.roaming_view(member.id).get("traversal", {})
		if hostile_only and not travel.is_empty() and travel.mode != "ground":
			continue
		var cell: Vector2i = sightings.current_cell(member)
		var distance: int = sightings.manhattan(cell, world.cell)
		if distance <= radius and Vector2(cell - world.cell).length() <= sightings.settings.visible_radius:
			result.append({"id": member.id, "name": member.entry.name, "cell": cell, "distance": distance})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.distance < b.distance if a.distance != b.distance else str(a.id) < str(b.id))
	return result

func clear_warning() -> void:
	warning_id = ""
	warning_presented = false
	warning_step = -1
	warning_elapsed = 0.0
	if warning_panel != null:
		warning_panel.hide()

func refresh_warning() -> void:
	if world.encounter_active or world.paused or world.smoke_mode or not settings.valid() or not settings.enabled or not settings.automatic_contact or safe_steps > 0 or world.persistent_state.battle_grace() > 0 or world.terrain.is_camp(world.cell):
		clear_warning()
		return
	var threats := candidates(settings.warning_distance, true)
	if threats.is_empty():
		clear_warning()
		return
	var target := threats[0]
	if warning_id != target.id:
		warning_id = target.id
		warning_presented = false
		warning_step = steps
		warning_elapsed = 0.0
	warning_label.text = "%s is defending territory · %d tiles\nMove away to avoid contact." % [target.name, target.distance]
	warning_panel.show()

func warning_uncovered() -> bool:
	return not warning_id.is_empty() and warning_panel.is_visible_in_tree() and world.hud.visible and not world.paused and not world.journal_panel.visible and not world.confirmation.visible and (world.menu == null or not world.menu.opened) and not world.observation_menu.visible

func mark_warning_presented() -> void:
	# Actual post-draw acknowledgement; headless tests explicitly simulate this seam.
	if warning_uncovered():
		warning_presented = true

func on_player_step(_from: Vector2i, _to: Vector2i) -> void:
	steps += 1
	if world.persistent_state.battle_grace() > 0:
		world.persistent_state.consume_battle_grace()
		clear_warning()
		return
	if safe_steps > 0:
		safe_steps -= 1
		clear_warning()
		return
	if world.smoke_mode or world.paused or not settings.valid() or not settings.enabled or not settings.automatic_contact or world.terrain.is_camp(world.cell):
		clear_warning()
		return
	var targets := candidates(settings.warning_distance, true)
	if not targets.is_empty():
		var target := targets[0]
		if target.id == warning_id and warning_presented and warning_elapsed >= settings.warning_delay_seconds and steps > warning_step and target.distance <= settings.contact_distance:
			open_encounter(target)
			return
	refresh_warning()

func approach_nearest() -> void:
	if world.paused or world.moving or world.confirmation.visible or world.encounter_active:
		return
	var targets := candidates(settings.interaction_distance)
	if targets.is_empty():
		world.message("Stop closer to a Sol to approach it.", false)
		return
	open_encounter(targets[0])

func approach_individual(identity: String) -> void:
	# Context menus resolve the clicked identity again at execution, never nearest.
	if world.paused or world.moving or world.confirmation.visible or world.encounter_active:
		return
	for target in candidates(settings.interaction_distance):
		if target.id == identity:
			open_encounter(target)
			return
	world.message("Move closer and stop to engage this Sol.", false)

func open_encounter(target: Dictionary) -> void:
	if world.encounter_active or world.moving or not world.persistent_state.wild_available(target.id):
		return
	var travel: Dictionary = world.persistent_state.roaming_view(target.id).get("traversal", {})
	if not travel.is_empty() and travel.mode != "ground":
		world.persistent_state.request_ground(target.id)
		world.message("%s is returning toward land. Approach again once it is grounded." % str(target.name), false)
		return
	if world.menu != null and world.menu.opened:
		world.menu.close()
	active_target = target.duplicate(true)
	encounter_state = world.persistent_state
	world.encounter_active = true
	world.paused = true
	world.explorer.walking = false
	world.pause_panel.hide()
	world.journal_panel.hide()
	clear_warning()
	title.text = "FACE TO FACE · " + str(target.name)
	description.text = "%s watches your approach.\n\nRecord the sighting, deploy your companion, or withdraw." % target.name
	observe_button.disabled = world.persistent_state.has_discovery(target.id)
	encounter_panel.show()
	withdraw_button.grab_focus()

func observe_target() -> void:
	if active_target.is_empty() or world.persistent_state != encounter_state:
		return
	if world.persistent_state.record_sol_discovery(active_target.id, active_target.name, "It watched your face-to-face approach.", active_target.cell):
		observe_button.disabled = true
		world.message("Sighting recorded in Field Notes.")

func withdraw() -> void:
	if battle_running:
		battle_retreat_requested.emit()
		return
	if active_target.is_empty():
		return
	active_target.clear()
	encounter_state = null
	encounter_panel.hide()
	world.encounter_active = false
	world.paused = false
	safe_steps = settings.withdrawal_safe_steps if settings.valid() else 3
	clear_warning()
	world.message("You withdraw. Move away to give the Sol space.", false)
