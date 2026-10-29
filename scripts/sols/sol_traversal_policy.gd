class_name SolTraversalPolicy
extends RefCounted
## Shared bounded geometry checks. Rendering never owns travel permission.

static func water(terrain: WorldTerrain, cell: Vector2i) -> bool:
	return terrain.natural_ground(cell) == WorldTerrain.Ground.WATER

static func cell_valid(terrain: WorldTerrain, cell: Vector2i, state: Dictionary) -> bool:
	if state.is_empty() or state.mode in ["ground", "takeoff", "landing", "swim_exit"]:
		return terrain.fits(cell)
	if state.mode in ["wade", "swim", "swim_enter"]:
		return water(terrain, cell) and (state.mode != "swim" or terrain.display_height(Vector2(cell) + Vector2(0.5, 0.5)) - terrain.surface_height(Vector2(cell) + Vector2(0.5, 0.5)) >= float(state.policy.draft))
	return state.mode == "air" and terrain.sample(cell).obstacle == 0

static func box(at: Vector3, policy: Dictionary) -> AABB:
	var radius: float = policy.radius
	var lower := radius * (0.55 if policy.kind == "flight" else 0.1) # Include combined downstroke and banking.
	return AABB(at - Vector3(radius, lower, radius), Vector3(radius * 2, policy.height + lower, radius * 2))

static func corridor(start: Vector3, finish: Vector3, policy: Dictionary, geometry: Array, lift: float = 0.0) -> bool:
	var swept := box(start, policy).merge(box(finish, policy)).grow(0.015)
	swept.size.y += lift
	for obstacle: AABB in geometry:
		if swept.intersects(obstacle):
			return false
	return true

static func blocked(world: Node2D, cell: Vector2i) -> bool:
	return world.persistent_state.environment_view(cell, {}).get("conditions", {}).has("barrier")

static func can_land(world: Node2D, cell: Vector2i, state: Dictionary, occupied: Dictionary, geometry: Array) -> bool:
	if occupied.has(cell) or world.cell == cell or (world.moving and world.destination == cell) or not world.terrain.fits(cell) or blocked(world, cell):
		return false
	var at := Vector2(cell) + Vector2(0.5, 0.5)
	var low := Vector3(at.x, world.terrain.display_height(at) + 0.02, at.y)
	return corridor(low, low + Vector3.UP * (float(state.policy.altitude) if state.policy.kind == "flight" else 0.0), state.policy, geometry)

static func can_step(world: Node2D, from: Vector2i, to: Vector2i, state: Dictionary, geometry: Array) -> bool:
	if absi(to.x - from.x) + absi(to.y - from.y) != 1 or blocked(world, to):
		return false
	var terrain: WorldTerrain = world.terrain
	var policy: Dictionary = state.policy
	var a := Vector2(from) + Vector2(0.5, 0.5)
	var b := Vector2(to) + Vector2(0.5, 0.5)
	if policy.kind == "flight":
		if terrain.sample(to).obstacle != 0 or terrain.sample(from).obstacle != 0:
			return false # Solid columns remain conservative even if a mesh is thin.
		var start := Vector3(a.x, terrain.display_height(a) + float(policy.altitude), a.y)
		var finish := Vector3(b.x, terrain.display_height(b) + float(policy.altitude), b.y)
		if not corridor(start, finish, policy, geometry):
			return false
		var swept := box(start, policy).merge(box(finish, policy))
		for index in range(9):
			var t := float(index) / 8.0
			var center := a.lerp(b, t)
			var root_height := terrain.display_height(center) + float(policy.altitude)
			swept = swept.merge(box(Vector3(center.x, root_height, center.y), policy))
			var bottom := root_height - float(policy.radius) * 0.55
			for offset in [Vector2.ZERO, Vector2(-policy.radius, -policy.radius), Vector2(policy.radius, -policy.radius), Vector2(-policy.radius, policy.radius), Vector2(policy.radius, policy.radius)]:
				if terrain.display_height(center + offset) + 0.05 >= bottom:
					return false
		for obstacle: AABB in geometry:
			if swept.grow(0.015).intersects(obstacle):
				return false
		return true
	var from_water := water(terrain, from)
	var to_water := water(terrain, to)
	if not from_water and not to_water:
		return world.can_step(from, to)
	if (not from_water and not terrain.fits(from)) or (not to_water and not terrain.fits(to)):
		return false
	var a_height := terrain.display_height(a)
	var b_height := terrain.display_height(b)
	if absf(a_height - b_height) > float(policy.shore_step):
		return false
	var start := Vector3(a.x, maxf(terrain.surface_height(a), a_height - float(policy.draft)) if from_water else a_height, a.y)
	var finish := Vector3(b.x, maxf(terrain.surface_height(b), b_height - float(policy.draft)) if to_water else b_height, b.y)
	return corridor(start, finish, policy, geometry, 0.12 if from_water != to_water else 0.0)

static func water_mode(terrain: WorldTerrain, cell: Vector2i, policy: Dictionary) -> String:
	var at := Vector2(cell) + Vector2(0.5, 0.5)
	return "swim" if terrain.display_height(at) - terrain.surface_height(at) >= float(policy.draft) else "wade"

static func changed(state: Dictionary, mode: String, from: Vector2i, tick: int) -> Dictionary:
	var result := state.duplicate(true)
	if result.mode != mode:
		result.mode_tick = tick
	result.mode = mode
	result.from = [from.x, from.y]
	return result

static func presentation(terrain: WorldTerrain, row: Dictionary, at: Vector2, seconds: float) -> Dictionary:
	if not row.has("traversal"):
		return {}
	var state: Dictionary = row.traversal
	var progress := clampf((seconds - int(state.mode_tick) * ExpeditionContract.ACTIVITY_INTERVAL) / ExpeditionContract.ACTIVITY_INTERVAL, 0.0, 1.0)
	var amount := 0.0
	if state.mode in ["air", "swim"]:
		amount = 1.0
	elif state.mode in ["takeoff", "swim_enter"]:
		amount = progress
	elif state.mode in ["landing", "swim_exit"]:
		amount = 1.0 - progress
	var height := terrain.display_height(at)
	if state.policy.kind == "flight":
		height += float(state.policy.altitude) * amount
	elif state.mode in ["swim_enter", "swim_exit"]:
		var start := Vector2(state.from[0], state.from[1]) + Vector2(0.5, 0.5)
		var finish := Vector2(row.cell[0], row.cell[1]) + Vector2(0.5, 0.5)
		var a := maxf(terrain.surface_height(start), terrain.display_height(start) - float(state.policy.draft)) if state.mode == "swim_exit" else terrain.display_height(start)
		var b := maxf(terrain.surface_height(finish), terrain.display_height(finish) - float(state.policy.draft)) if state.mode == "swim_enter" else terrain.display_height(finish)
		height = lerpf(a, b, progress) + sin(progress * PI) * 0.12
	elif state.mode in ["swim", "wade"]:
		height = maxf(terrain.surface_height(at), height - float(state.policy.draft))
		amount = clampf((terrain.display_height(at) - terrain.surface_height(at)) / float(state.policy.draft), 0.0, 1.0)
	return {"mode": state.mode, "kind": state.policy.kind, "amount": amount, "height": height, "clock": seconds}

static func landing_goal(world: Node2D, position: Vector2i, home: Vector2i, state: Dictionary, occupied: Dictionary, geometry: Array) -> Vector2i:
	if can_land(world, home, state, occupied, geometry):
		return home
	for distance in range(1, 6):
		for y in range(-distance, distance + 1):
			for x in range(-distance, distance + 1):
				var candidate := position + Vector2i(x, y)
				if absi(x) + absi(y) != distance or SolRoamingPolicy.distance(candidate, home) > ExpeditionContract.MAX_ROAMING_DISTANCE:
					continue
				if can_land(world, candidate, state, occupied, geometry):
					return candidate
	return position

static func advance(world: Node2D, position: Vector2i, home: Vector2i, action: String, goal: Vector2i, state: Dictionary, occupied: Dictionary, geometry: Array, tuning: SightingSettings, tick: int, minimum_player_distance: int = 0) -> Dictionary:
	var travel := state.duplicate(true)
	var others := occupied.duplicate()
	others.erase(position)
	var result := {"target": position, "traversal": travel}
	var legal_ground := can_land(world, position, travel, others, geometry)
	if travel.mode == "ground" and travel.settle:
		if tick - int(travel.mode_tick) <= 4:
			return result
		travel.settle = false
	if travel.mode == "takeoff":
		result.traversal = changed(travel, "air" if legal_ground else "ground", position, tick)
		return result
	if travel.mode == "landing":
		result.traversal = changed(travel, "ground" if legal_ground else "air", position, tick)
		return result
	if travel.mode == "swim_enter":
		result.traversal = changed(travel, water_mode(world.terrain, position, travel.policy), position, tick)
		return result
	if travel.mode == "swim_exit":
		if legal_ground:
			result.traversal = changed(travel, "ground", position, tick)
		return result
	if travel.policy.kind == "flight" and travel.mode == "air" and (action == "idle" or travel.settle):
		if legal_ground:
			result.traversal = changed(travel, "landing", position, tick)
			return result
		goal = landing_goal(world, position, home, travel, others, geometry)
		action = "return"
	elif travel.policy.kind == "swim" and travel.settle and travel.mode in ["swim", "wade"]:
		goal = landing_goal(world, position, home, travel, others, geometry)
		action = "return"
	var edge := func(from: Vector2i, to: Vector2i) -> bool:
		return can_step(world, from, to, travel, geometry)
	var target := SolLocalNavigation.next_step(position, home, action, goal, occupied, edge, tuning, world.cell, minimum_player_distance)
	if target == position:
		return result
	if travel.policy.kind == "flight":
		if travel.mode == "ground":
			if legal_ground:
				result.traversal = changed(travel, "takeoff", position, tick)
			return result
		result.target = target
		result.traversal = changed(travel, "air", position, tick)
	else:
		result.target = target
		var mode := "swim_enter" if water(world.terrain, target) and not water(world.terrain, position) else "swim_exit" if not water(world.terrain, target) and water(world.terrain, position) else water_mode(world.terrain, target, travel.policy) if water(world.terrain, target) else "ground"
		result.traversal = changed(travel, mode, position, tick)
	return result
