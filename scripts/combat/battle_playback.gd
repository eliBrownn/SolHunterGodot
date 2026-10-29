class_name BattlePlayback
extends RefCounted
## Battle-local presentation of one atomic operation at a time. Never commits expedition state.
signal changed(step: Dictionary)
signal settled
## Optional development observers receive admission results without changing rule execution.
signal command_submitted(command: String, target: Vector2i, slot: int, accepted: bool)

var battle: TacticalBattle
var tuning: SolVisualSettings
var busy := false
var current: Dictionary = {}
var view: TacticalBattle
var pending: Array[Dictionary] = []
var seconds_left := 0.0
var collecting := false
var battle_serial := 0
var identities: Dictionary = {}

func bind(source: TacticalBattle, settings: SolVisualSettings, token: int = 0, units: Dictionary = {}) -> void:
	reset()
	battle = source
	tuning = settings if settings != null and settings.valid() else SolVisualSettings.new()
	battle_serial = token
	identities = units.duplicate()
	battle.automatic_enemies = false
	battle.resolution_event.connect(record)

func reset() -> void:
	if battle != null and battle.resolution_event.is_connected(record):
		battle.resolution_event.disconnect(record)
	battle = null
	view = null
	busy = false
	collecting = false
	current.clear()
	pending.clear()
	seconds_left = 0.0
	battle_serial = 0
	identities.clear()

func submit(command: String, target: Vector2i = Vector2i.ZERO, slot: int = -1, roll: float = 0.0) -> bool:
	if battle == null or busy:
		command_submitted.emit(command, target, slot, false)
		return false
	collecting = true
	var accepted := false
	match command:
		"deploy": accepted = battle.deploy(target)
		"move": accepted = battle.move_ally(target)
		"move_slot": accepted = battle.use_move(slot, target)
		"wait": accepted = battle.wait_turn()
		"capture": accepted = battle.attempt_capture(roll)
		"retreat": accepted = battle.retreat()
	if accepted:
		battle.outcome_record()
		battle.resolution("state", battle.turn, "")
	collecting = false
	if not accepted:
		pending.clear()
		command_submitted.emit(command, target, slot, false)
		return false
	busy = true
	command_submitted.emit(command, target, slot, true)
	show_next()
	return true

func record(step: Dictionary) -> void:
	if not collecting:
		return
	step = step.duplicate(true)
	step.battle_serial = battle_serial
	step.actor_id = identities.get(step.actor, "")
	step.recipient_id = identities.get(step.side, "")
	# Some status moves also issue the generic successful-field cue. Present that cause once.
	if not pending.is_empty() and step.kind == "effect":
		var last: Dictionary = pending.back()
		if last.kind == "effect" and last.action == step.action and last.cue == step.cue:
			pending[-1] = step.duplicate(true)
			return
	pending.append(step.duplicate(true))

func duration(kind: String) -> float:
	var value := 0.0
	var maximum := 1.0
	match kind:
		"action": value = tuning.action_cue_seconds
		"effect", "outcome", "consequence":
			value = tuning.consequence_seconds
			maximum = 1.5
		"movement":
			value = tuning.movement_step_seconds
			maximum = 0.5
		"turn": value = tuning.turn_handoff_seconds
	return clampf(value, 0.0, maximum) if is_finite(value) else 0.0

func show_next() -> void:
	if pending.is_empty():
		return
	current = pending.pop_front()
	view = battle.view_from(current.snapshot)
	seconds_left = duration(current.kind)
	changed.emit(current.duplicate(true))

func advance(delta: float) -> void:
	if not busy or not is_finite(delta) or delta < 0:
		return
	seconds_left -= delta
	if seconds_left > 0:
		return
	if not pending.is_empty():
		show_next()
		return # Even zero holds expose one record per update; large frames never skip causes.
	if battle.phase == "active" and battle.turn == "enemy":
		collecting = true
		battle.advance_enemy()
		battle.outcome_record()
		battle.resolution("state", battle.turn, "")
		collecting = false
		show_next()
		return
	busy = false
	view = null
	current.clear()
	settled.emit()
