extends RefCounted
## Explicitly finish presentation for existing final-state fixtures, without real-time sleeps.
static func settle(controller: Node) -> void:
	for step in range(1024):
		if not controller.playback.busy and controller.commander_ready():
			return
		controller.advance_resolution(10.0)
	push_error("Battle presentation did not settle within the fixture bound.")

static func approach_attack(controller: Node) -> void:
	# Outside deployment can require legal approach movement before a close-range attack.
	for turn in range(12):
		if controller.session == null or not controller.legal_targets(0).is_empty():
			return
		var battle: TacticalBattle = controller.session
		var closest := battle.ally_cell
		for at: Vector2i in battle.reachable():
			if battle.can_use_for("ally", 0, battle.enemy_cell, at):
				controller.select_cell(at)
				settle(controller)
				return
			if TacticalBattle.distance(at, battle.enemy_cell) < TacticalBattle.distance(closest, battle.enemy_cell):
				closest = at
		if closest != battle.ally_cell:
			controller.select_cell(closest)
			settle(controller)
		controller.wait_turn()
		settle(controller)
