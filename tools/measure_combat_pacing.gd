extends SceneTree
## Repeatable scripted baseline, or --play --fixture=ordinary for an isolated manual probe.
const Fixture = preload("res://scripts/combat/combat_pacing_fixture.gd")
const Measurement = preload("res://scripts/combat/battle_pacing_measurement.gd")
const Policy = preload("res://tools/combat_pacing_policy.gd")
var scene: Node3D
var measured: BattlePacingMeasurement
var revision := "unlabelled-working-tree"
var output := "res://artifacts/combat-pacing/report.json"
var selected := "ordinary"
var manual := false
var timing := "default"
var reports: Array[Dictionary] = []
var elapsed := 0.0
var written := false
var auto_play := false
var used: Dictionary = {}
var captured := false
var reference := false
var legacy := false
var review: Window
var review_smoke := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--play": manual = true
		elif argument == "--auto-play": auto_play = true
		elif argument == "--reference": reference = true
		elif argument == "--legacy-policy": legacy = true
		elif argument == "--review-smoke": review_smoke = true
		elif argument.begins_with("--fixture="): selected = argument.trim_prefix("--fixture=")
		elif argument.begins_with("--timing="): timing = argument.trim_prefix("--timing=")
		elif argument.begins_with("--revision="): revision = argument.trim_prefix("--revision=")
		elif argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	root.close_requested.connect(finish_manual)
	run.call_deferred()

static func closest_release(battle: TacticalBattle) -> Vector2i:
	var tiles := battle.deployment_tiles()
	var result := tiles[0]
	for at in tiles:
		if TacticalBattle.distance(at, battle.enemy_cell) < TacticalBattle.distance(result, battle.enemy_cell): result = at
	return result

static func choose(battle: TacticalBattle, interactions: bool, used: Dictionary) -> Dictionary:
	if battle.phase == "deployment": return {"command": "deploy", "target": closest_release(battle), "reason": "Release near the opponent"}
	return Policy.choose(battle, interactions, used)

static func choose_legacy(battle: TacticalBattle, interactions: bool, used: Dictionary) -> Dictionary:
	if battle.phase == "deployment": return {"command": "deploy", "target": closest_release(battle)}
	for slot in range(battle.ally_moves.size()):
		var move: Dictionary = battle.ally_moves[slot]
		if move.effect == "heal" and battle.ally_hp <= int(battle.ally.max_hp) / 3 and battle.can_use(slot, battle.ally_cell):
			return {"command": "move_slot", "slot": slot, "target": battle.ally_cell}
		if interactions and move.id == "current" and not used.has("current") and battle.can_use(slot, battle.enemy_cell):
			used.current = true
			return {"command": "move_slot", "slot": slot, "target": battle.enemy_cell}
		if interactions and move.id == "charge" and not used.has("charge") and battle.fields.get(battle.enemy_cell, {}).get("kind") == "wet" and battle.can_use(slot, battle.enemy_cell):
			used.charge = true
			return {"command": "move_slot", "slot": slot, "target": battle.enemy_cell}
	for slot in range(battle.moves_for("ally").size()):
		if battle.moves_for("ally")[slot].effect == "damage" and battle.can_use(slot, battle.enemy_cell):
			return {"command": "move_slot", "slot": slot, "target": battle.enemy_cell}
	var best := battle.ally_cell
	var available := battle.reachable()
	for at: Vector2i in battle.approach_route("ally"):
		if available.has(at): best = at
	if best != battle.ally_cell: return {"command": "move", "target": best}
	return {"command": "wait"}

static func simulate(fixture: CombatPacingFixture, tuning: SolVisualSettings, context_revision: String, interactions: bool = false, limit: int = 120, legacy_policy: bool = false) -> Dictionary:
	var battle := fixture.build()
	if battle == null: return {"error": "Invalid fixture"}
	var playback := BattlePlayback.new()
	playback.bind(battle, tuning)
	var metrics := Measurement.new()
	var context := fixture.context(battle, tuning, context_revision)
	context.policy = ("legacy_terrain_then_attack" if interactions else "legacy_heal_below_third") if legacy_policy else ("safe_preparation_and_crossing" if interactions else "direct_effective_healing")
	context.policy_version = 1 if legacy_policy else 2
	context.action_economy = "shared_ap_speed_movement_v1"
	context.fixed_step_seconds = 1.0 / 60.0
	context.command_limit = limit
	metrics.bind(playback, context, true)
	var policy_used := {}
	for command in range(limit):
		var choice := choose_legacy(battle, interactions, policy_used) if legacy_policy else choose(battle, interactions, policy_used)
		metrics.append({"event": "policy_choice", "reason": choice.get("reason", "Legacy policy"), "command": choice.command})
		if not playback.submit(choice.command, choice.get("target", Vector2i.ZERO), int(choice.get("slot", -1))): break
		for frame in range(10000):
			if not playback.busy: break
			metrics.sample(1.0 / 60.0)
			playback.advance(1.0 / 60.0)
		if metrics.complete: break
	var report := metrics.report()
	report.policy_diagnostics = policy_used.duplicate(true)
	report.limit_reached = not metrics.complete
	metrics.unbind()
	playback.reset()
	return report

func run() -> void:
	if timing not in ["default", "concise"]:
		push_error("Unknown timing preset")
		quit(1)
		return
	if manual:
		if not selected in ["ordinary", "terrain", "major_probe"]:
			push_error("Unknown fixture")
			quit(1)
			return
		start_manual()
		return
	for name in ["ordinary", "terrain", "major_probe"]:
		var fixture: CombatPacingFixture = load("res://resources/combat_pacing/%s%s.tres" % ["baseline/" if reference else "", name])
		for interactions in [false, true]:
			var report := simulate(fixture, timing_settings(), revision, interactions, 120, legacy)
			reports.append(report)
			print("PACING %s / %s: %s, decisions %d+%d moves, R%d, holds %.2fs, sampled %.2fs, repeated states %d" % [name, report.metadata.policy, report.outcome, report.turn_decisions, report.movement_decisions, report.round_reached, report.configured_hold_seconds, report.seconds.presentation, report.repeated_state_visits])
	write_report()
	quit(1 if reports.any(func(row: Dictionary) -> bool: return row.get("limit_reached", true)) else 0)

func timing_settings() -> SolVisualSettings:
	return load("res://resources/combat_pacing/concise.tres").duplicate(true) if timing == "concise" else SolVisualSettings.new()

func start_manual() -> void:
	# The launcher supplies a disposable user-data directory; no personal expedition is loaded.
	scene = load("res://scenes/world_3d.tscn").instantiate()
	scene.sol_visual_settings = timing_settings()
	scene.sighting_settings = scene.sighting_settings.duplicate(true)
	scene.sighting_settings.wilderness_enabled = false
	scene.sighting_settings.movement_enabled = false
	root.add_child(scene)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 800)
	root.title = "SolHunter · %s pacing probe · %s timing · F8 records/exits" % [selected, timing]
	var world: Node2D = scene.world
	world.new_expedition(17)
	var fixture: CombatPacingFixture = load("res://resources/combat_pacing/%s%s.tres" % ["baseline/" if reference else "", selected])
	world.persistent_state.choose_starter(fixture.hero.snapshot(), 0)
	var member: Dictionary = scene.sightings.members[0]
	world.cell = member.home + Vector2i.LEFT
	world.destination = world.cell
	world.rebuild_world()
	scene.encounters.approach_individual(member.id)
	scene.encounters.battle_button.pressed.emit()
	var controller: Node = scene.battles
	if controller.session == null:
		push_error("Development encounter entry failed")
		quit(1)
		return
	var probe := fixture.build(world.cell - fixture.trainer_offset)
	controller.playback.reset()
	controller.session = probe
	scene.player_visual.reset_sideline()
	scene.player_visual.update_sideline(0.0)
	controller.playback.bind(probe, scene.sightings.visual_settings, controller.serial)
	controller.cursor = closest_release(probe)
	controller.update_view()
	controller.frame_battle()
	measured = Measurement.new()
	var context := fixture.context(probe, scene.sightings.visual_settings, revision)
	context.commander_run_speed = scene.battle_settings.commander_run_speed
	context.render_size = [root.size.x, root.size.y]
	context.note = "Synthetic probe with fixed class potency; no production major encounter. F8 or window close records unfinished runs."
	context.policy = "safe_preparation_and_crossing" if auto_play else "human"
	context.policy_version = 2 if auto_play else null
	measured.bind(controller.playback, context, auto_play)
	# Sample before the controller advances presentation this frame.
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	print("PLAYTEST %s: normal mouse/controller battle controls. F8 records and exits. Output: %s" % [selected, output])

func _process(delta: float) -> bool:
	if measured == null: return false
	if written:
		if Input.is_physical_key_pressed(KEY_F8) and review == null: quit()
		return false
	elapsed += delta
	var controller: Node = scene.battles
	if auto_play and not captured and controller.commander_ready():
		captured = true
		capture.call_deferred()
	measured.sample(delta, controller.modal_open() or scene.world.observation_menu.visible,
		controller.commander_ready(), controller.completion_failed)
	if auto_play and controller.session != null and not controller.playback.busy and controller.commander_ready():
		var choice := choose(controller.session, true, used)
		measured.append({"event": "policy_choice", "reason": choice.get("reason", ""), "command": choice.command})
		match choice.command:
			"deploy", "move": controller.select_cell(choice.target)
			"move_slot":
				controller.choose_move(choice.slot)
				controller.select_cell(choice.target)
			"wait": controller.wait_turn()
	if measured.complete:
		var report := measured.report()
		report.receipt_status = "rejected" if controller.completion_failed else ("committed" if controller.session == null else "pending")
		report.owner_feedback = null
		reports.append(report)
		write_report()
		measured.unbind()
		print("Pacing result recorded: %s. F8 exits." % output)
		if auto_play and not review_smoke: quit(1 if controller.completion_failed else 0)
		else: show_review()
	elif Input.is_physical_key_pressed(KEY_F8) or elapsed >= (120 if auto_play else 1200):
		finish_manual()
	return false

func finish_manual() -> void:
	if written:
		quit()
		return
	if measured == null: return
	var report := measured.report()
	report.limit_reached = elapsed >= (120 if auto_play else 1200)
	reports.append(report)
	write_report()
	measured.unbind()
	quit()

func capture() -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() != "headless":
		root.get_texture().get_image().save_png("res://artifacts/combat-pacing/%s-playtest.png" % selected)

func show_review() -> void:
	review = Window.new()
	review.title = "%s · pacing playtest notes" % selected.capitalize()
	review.theme = scene.battles.combat_hud.theme
	review.min_size = Vector2i(600, 440)
	review.size = Vector2i(620, 460)
	review.exclusive = true
	# Existing controller routing discovers native windows under the world HUD.
	scene.world.hud.add_child(review)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + edge, 16)
	review.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	var pace := OptionButton.new()
	var clarity := OptionButton.new()
	pace.custom_minimum_size.y = 42
	clarity.custom_minimum_size.y = 42
	for item in ["Pacing · choose an answer", "Too quick to follow", "About right", "Too much waiting"]: pace.add_item(item)
	for item in ["Clarity · choose an answer", "I could follow who acted and what changed", "Some causes or handoffs were unclear"]: clarity.add_item(item)
	box.add_child(pace)
	box.add_child(clarity)
	var label := Label.new()
	label.text = "Which choice mattered? What felt repetitive or unclear?\nNotes are optional. Closing this window skips notes."
	box.add_child(label)
	var notes := TextEdit.new()
	notes.custom_minimum_size.y = 160
	notes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(notes)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var save := Button.new()
	save.text = "Save notes and exit"
	save.custom_minimum_size.y = 42
	save.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(save)
	save.pressed.connect(func() -> void:
		reports.back().owner_feedback = {"pace": null if pace.selected == 0 else pace.get_item_text(pace.selected),
			"clarity": null if clarity.selected == 0 else clarity.get_item_text(clarity.selected), "notes": notes.text,
			"fixture_acceptance": "not_requested", "recorded_at_utc": Time.get_datetime_string_from_system(true)}
		write_report()
		quit())
	var skip := Button.new()
	skip.text = "Skip notes"
	skip.custom_minimum_size.y = 42
	buttons.add_child(skip)
	skip.pressed.connect(func() -> void: quit())
	review.close_requested.connect(func() -> void: quit())
	review.visibility_changed.connect(func() -> void:
		if not review.visible: quit()) # Controller Back hides native windows.
	review.popup_centered()
	pace.grab_focus()
	if review_smoke: verify_review.call_deferred(pace)

func verify_review(pace: OptionButton) -> void:
	await process_frame
	var pad: Node = scene.gamepad
	if not review.visible or not pace.has_focus() or reports.back().owner_feedback != null or not review.has_meta("pad_bridge") or pad.ui_root() != review:
		push_error("Review must open with keyboard/controller focus and unanswered owner feedback")
		quit(1)
		return
	# Exercise real window-local controller routing without answering for the owner.
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = 0
		event.button_index = JOY_BUTTON_DPAD_DOWN
		event.pressed = pressed
		review.push_input(event, true)
	for frame in range(3): await process_frame
	if not pad.active or pad.ui_root() != review or reports.back().owner_feedback != null:
		push_error("Controller routing must keep review focus and leave owner feedback unanswered")
		quit(1)
		return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/combat-pacing-v2/review.png")
	print("PACING REVIEW: visible, keyboard/controller routing works, owner answers remain null.")
	review.hide()

func write_report() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write pacing report: %s" % output)
		quit(1)
		return
	file.store_string(JSON.stringify({"reports": reports}, "\t"))
	written = true
