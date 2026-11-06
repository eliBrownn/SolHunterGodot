class_name BattlePacingMeasurement
extends RefCounted
## Opt-in development measurement. Does not schedule, plan, mutate, or save battles.
const TRACE_LIMIT := 4096
var battle: TacticalBattle
var playback: BattlePlayback
var metadata: Dictionary = {}
var seconds := {"presentation": 0.0, "choice": 0.0, "commander": 0.0, "paused": 0.0, "result_pending": 0.0}
var configured_hold_seconds := 0.0
var accepted_commands := 0
var rejected_commands := 0
var turn_decisions := 0
var movement_decisions := 0
var repeated_commands := 0
var unchanged_operations := 0
var repeated_states := 0
var damage_free_turns := 0
var longest_damage_free_streak := 0
var damage_free_streak := 0
var enemy_actions := 0
var damage := {"ally": 0, "enemy": 0}
var healing := {"ally": 0, "enemy": 0}
var command_counts: Dictionary = {}
var move_counts := {"ally": {}, "enemy": {}}
var trace: Array[Dictionary] = []
var trace_truncated := false
var complete := false
var previous_command := ""
var operation := ""
var before := ""
var operation_damage := 0
var seen: Dictionary = {}
var scripted := false

func bind(source: BattlePlayback, context: Dictionary, automatic: bool = false) -> void:
	unbind()
	playback = source
	battle = source.battle
	metadata = context.duplicate(true)
	scripted = automatic
	# A measurement instance is single-use; callers create a fresh one per encounter.
	before = signature()
	playback.command_submitted.connect(command)
	playback.changed.connect(step)
	playback.settled.connect(settled)

func unbind() -> void:
	if playback != null:
		if playback.command_submitted.is_connected(command): playback.command_submitted.disconnect(command)
		if playback.changed.is_connected(step): playback.changed.disconnect(step)
		if playback.settled.is_connected(settled): playback.settled.disconnect(settled)
	playback = null

func sample(delta: float, paused: bool = false, commander_ready: bool = true, result_pending: bool = false) -> void:
	if complete or playback == null or not is_finite(delta) or delta < 0:
		return
	var category := "choice"
	if paused: category = "paused"
	elif result_pending: category = "result_pending"
	elif not commander_ready: category = "commander"
	elif playback.busy: category = "presentation"
	seconds[category] += delta

func command(name: String, target: Vector2i, slot: int, accepted: bool) -> void:
	if complete:
		return
	if not accepted:
		rejected_commands += 1
		append({"event": "rejected", "command": name, "target": str(target), "slot": slot})
		return
	accepted_commands += 1
	command_counts[name] = int(command_counts.get(name, 0)) + 1
	var key := "%s:%d:%s" % [name, slot, str(target)]
	if key == previous_command: repeated_commands += 1
	previous_command = key
	operation = name
	operation_damage = 0
	if name == "move": movement_decisions += 1
	elif name in ["move_slot", "wait", "capture"]: turn_decisions += 1
	append({"event": "accepted", "command": name, "target": str(target), "slot": slot, "round": battle.round_number})

func step(record: Dictionary) -> void:
	if complete:
		return
	configured_hold_seconds += playback.duration(record.kind)
	var cue: Dictionary = record.cue
	if cue.get("kind") == "damage" and damage.has(record.side):
		damage[record.side] += int(cue.amount)
		operation_damage += int(cue.amount)
	if cue.get("kind") == "heal" and healing.has(record.side):
		healing[record.side] += int(cue.amount)
	if record.kind == "action":
		if record.side == "enemy": enemy_actions += 1
		if move_counts.has(record.side):
			var counts: Dictionary = move_counts[record.side]
			counts[record.caption] = int(counts.get(record.caption, 0)) + 1
	append({"event": "resolution", "sequence": record.sequence, "action": record.action,
		"kind": record.kind, "side": record.side, "caption": record.caption, "cause": record.cause,
		"affected_cells": record.affected_cells.map(func(at: Vector2i) -> String: return str(at)),
		"cue": cue.duplicate(true), "ally_hp": record.snapshot.ally_hp, "enemy_hp": record.snapshot.enemy_hp,
		"ally_cell": str(record.snapshot.ally_cell), "enemy_cell": str(record.snapshot.enemy_cell),
		"actions_remaining": record.snapshot.actions_remaining, "free_movement_remaining": record.snapshot.remaining,
		"move_uses": record.snapshot.move_uses.duplicate(true),
		"hold_seconds": playback.duration(record.kind)})

func append(row: Dictionary) -> void:
	if trace.size() < TRACE_LIMIT: trace.append(row.duplicate(true))
	else: trace_truncated = true

func signature() -> String:
	# Relative field/footing lifetimes avoid hiding a cycle behind an increasing round number.
	var conditions: Array = []
	var tiles: Array = battle.fields.keys()
	tiles.sort()
	for at in tiles:
		var row: Dictionary = battle.fields[at].duplicate(true)
		row.expires = int(row.get("expires", 0)) - battle.round_number
		row.erase("round")
		conditions.append([at, row])
	return var_to_str([battle.phase, battle.turn, battle.ally_hp, battle.enemy_hp,
		battle.ally_cell, battle.enemy_cell, battle.statuses, conditions, battle.phasing,
		maxi(0, int(battle.anchored.ally) - battle.round_number + 1),
		maxi(0, int(battle.anchored.enemy) - battle.round_number + 1), battle.links, battle.disrupted, battle.passives.units,
		battle.actions_remaining, battle.remaining, battle.move_uses, battle.moved_this_turn, battle.passive_guard])

func settled() -> void:
	var after := signature()
	if before == after: unchanged_operations += 1
	before = after
	if operation in ["move_slot", "wait", "capture"]:
		if seen.has(after): repeated_states += 1
		seen[after] = true
		if operation_damage == 0:
			damage_free_turns += 1
			damage_free_streak += 1
			longest_damage_free_streak = maxi(longest_damage_free_streak, damage_free_streak)
		else: damage_free_streak = 0
	complete = battle.phase in ["victory", "exhaustion", "retreat", "captured"]

func report() -> Dictionary:
	var total := 0.0
	for amount in seconds.values(): total += float(amount)
	return {"schema": 1, "metadata": metadata.duplicate(true), "mode": "scripted" if scripted else "owner_playtest",
		"outcome": battle.phase, "complete": complete, "round_reached": battle.round_number,
		"accepted_commands": accepted_commands, "turn_decisions": turn_decisions, "movement_decisions": movement_decisions,
		"rejected_commands": rejected_commands, "repeated_commands": repeated_commands,
		"unchanged_operations": unchanged_operations, "repeated_state_visits": repeated_states,
		"damage_free_turns": damage_free_turns, "longest_damage_free_streak": longest_damage_free_streak,
		"enemy_action_announcements": enemy_actions, "command_counts": command_counts.duplicate(),
		"action_captions": move_counts.duplicate(true), "move_uses": battle.move_uses.duplicate(true), "damage_hp": damage.duplicate(), "healing_hp": healing.duplicate(),
		"seconds": seconds.duplicate(), "voluntary_choice_seconds": null if scripted else seconds.choice,
		"total_sampled_seconds": total, "configured_hold_seconds": configured_hold_seconds,
		"ally_hp": battle.ally_hp, "enemy_hp": battle.enemy_hp, "trace_truncated": trace_truncated, "trace": trace.duplicate(true)}
