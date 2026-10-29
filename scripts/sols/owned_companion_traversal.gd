class_name OwnedCompanionTraversal
extends RefCounted
## Transient owned-view adapter over shared species clearance, modes and presentation.
## No wild home leash, domain writes, identity changes or teleport recovery.

var state: Dictionary = {}
var started := 0.0
var duration := 0.2

func reset(policy: Dictionary, cell: Vector2i) -> void:
	state = {} if policy.is_empty() or policy.kind == "ground" else {"policy": policy.duplicate(true), "mode": "ground", "mode_tick": 0, "from": [cell.x, cell.y], "settle": false}
	started = 0.0

func change(mode: String, from: Vector2i, seconds: float, step_seconds: float) -> void:
	state = SolTraversalPolicy.changed(state, mode, from, 0)
	started = seconds
	duration = step_seconds

func mode() -> String:
	return state.get("mode", "ground")

func grounded() -> bool:
	return mode() == "ground"

func transition() -> bool:
	return mode() in ["takeoff", "landing", "swim_enter", "swim_exit"]

func complete(world: Node2D, cell: Vector2i, occupied: Dictionary, geometry: Array, seconds: float) -> bool:
	if not transition():
		return true
	if seconds - started + 0.000001 < duration:
		return false
	if mode() in ["takeoff", "landing"]:
		var land := SolTraversalPolicy.can_land(world, cell, state, occupied, geometry)
		state.mode = ("air" if land else "ground") if mode() == "takeoff" else ("ground" if land else "air")
	else:
		state.mode = SolTraversalPolicy.water_mode(world.terrain, cell, state.policy) if SolTraversalPolicy.water(world.terrain, cell) else "ground"
	state.from = [cell.x, cell.y]
	return true

func advance(world: Node2D, cell: Vector2i, player: Vector2i, occupied: Dictionary, geometry: Array, ground_edge: Callable, settings: OwnedCompanionSettings, seconds: float, follow: bool, known_radius: int = 32) -> Vector2i:
	if state.is_empty():
		return OwnedCompanionPolicy.next_step(cell, player, occupied, ground_edge, settings) if follow else cell
	if not complete(world, cell, occupied, geometry, seconds):
		return cell
	if not follow:
		if mode() == "air" and SolTraversalPolicy.can_land(world, cell, state, occupied, geometry):
			change("landing", cell, seconds, settings.step_seconds)
		return cell # Unsupported landing waits in air/water rather than relocating.
	var edge := func(from: Vector2i, to: Vector2i) -> bool:
		# Ground parts of a swimming route also retain the full grounded body sweep.
		if state.policy.kind == "swim" and not SolTraversalPolicy.water(world.terrain, from) and not SolTraversalPolicy.water(world.terrain, to):
			return ground_edge.call(from, to)
		return SolRoamingPolicy.distance(to, cell) <= mini(settings.search_radius, known_radius) and SolTraversalPolicy.can_step(world, from, to, state, geometry)
	var target := OwnedCompanionPolicy.next_step(cell, player, occupied, edge, settings)
	if state.policy.kind == "flight":
		if mode() == "ground":
			if target != cell and SolTraversalPolicy.can_land(world, cell, state, occupied, geometry):
				change("takeoff", cell, seconds, settings.step_seconds)
				return cell
			return OwnedCompanionPolicy.next_step(cell, player, occupied, ground_edge, settings)
		if target != cell:
			change("air", cell, seconds, settings.step_seconds)
	elif target != cell:
		var from_water := SolTraversalPolicy.water(world.terrain, cell)
		var to_water := SolTraversalPolicy.water(world.terrain, target)
		change("swim_enter" if to_water and not from_water else "swim_exit" if from_water and not to_water else SolTraversalPolicy.water_mode(world.terrain, target, state.policy) if to_water else "ground", cell, seconds, settings.step_seconds)
	return target

func visual(terrain: WorldTerrain, cell: Vector2i, at: Vector2, seconds: float) -> Dictionary:
	if state.is_empty():
		return {}
	# Shared presentation uses active-tick units; owned display steps use seconds.
	var phase_seconds := (seconds - started) * ExpeditionContract.ACTIVITY_INTERVAL / maxf(0.001, duration)
	var result := SolTraversalPolicy.presentation(terrain, {"cell": [cell.x, cell.y], "traversal": state}, at, phase_seconds)
	result.clock = seconds
	return result
