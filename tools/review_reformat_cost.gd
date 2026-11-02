extends "res://tools/review_connected_expedition.gd"
## Reuse the real connected journey, adding matched menu/battle cost windows.
## Run unchanged against the preserved baseline and final project; no budget gate.

func personal_controls() -> void:
	await super.personal_controls()
	var started := Time.get_ticks_usec()
	world.menu.open("sols")
	report["sol_menu_open_cpu_ms"] = (Time.get_ticks_usec() - started) / 1000.0
	record(world.menu.opened and not world.paused, "Cost window uses the actual live Sol menu")
	report["sol_menu_frames"] = await settle(90)
	world.menu.close()

func begin(member: Dictionary) -> bool:
	var started := Time.get_ticks_usec()
	var entered: bool = await super.begin(member)
	if not report.has("battle_cost_windows"):
		report["battle_cost_windows"] = []
	if entered:
		var entry := {"identity": member.id, "entry_wall_ms": (Time.get_ticks_usec() - started) / 1000.0}
		entry["active_frames"] = await settle(90)
		report.battle_cost_windows.append(entry)
	return entered
