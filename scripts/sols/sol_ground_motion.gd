class_name SolGroundMotion
extends RefCounted
## Visual support/stride solver. Inputs are absolute committed display positions;
## outputs only affect model joints. Camera rebasing is never locomotion.

var chains: Array[Dictionary] = []
var initialized := false
var anchor := Vector2.ZERO
var surface_y := 0.0
var heading := 0.0
var speed := 0.0
var next_group := 0
var steps_started := 0

static func relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var result := Transform3D.IDENTITY
	var current := node
	while current != ancestor:
		result = current.transform * result
		current = current.get_parent() as Node3D
	return result

func add_chain(model: Node3D, hip: Node3D, knee: Node3D, foot: Node3D, group: int, inset: float = 1.0) -> void:
	var nominal := relative_transform(foot, model).origin
	nominal.x *= inset
	chains.append({"hip": hip, "knee": knee, "foot": foot, "group": group,
		"nominal": nominal, "planted": Vector3.ZERO, "from": Vector3.ZERO,
		"target": Vector3.ZERO, "progress": 1.0, "seconds": 0.12, "display": Vector3.ZERO})

func reset() -> void:
	initialized = false
	speed = 0.0
	next_group = 0

func nominal_position(chain: Dictionary, at: Vector2, sampler: Callable, scale_factor: float) -> Vector3:
	var offset: Vector3 = Basis(Vector3.UP, heading) * Vector3(chain.nominal.x, 0, chain.nominal.z)
	var point := at + Vector2(offset.x, offset.z)
	return Vector3(point.x, float(sampler.call(point)) + 0.008 * scale_factor, point.y)

func advance(at: Vector2, delta: float, sampler: Callable, scale_factor: float, step_distance: float, lift: float, turn_rate: float) -> void:
	if not sampler.is_valid() or not at.is_finite() or not is_finite(delta) or delta < 0:
		reset()
		return
	var change := at - anchor
	if not initialized or change.length() > 0.75 or (delta == 0 and change.length() > 0.001):
		anchor = at
		surface_y = sampler.call(at)
		for chain in chains:
			chain.planted = nominal_position(chain, at, sampler, scale_factor)
			chain.display = chain.planted
			chain.progress = 1.0
		initialized = true
		speed = 0.0
		return
	if delta == 0:
		return # Pause and stationary view rebuilds must not spend gait time.
	anchor = at
	surface_y = sampler.call(at)
	speed = change.length() / delta
	if speed > 0.001:
		heading = lerp_angle(heading, atan2(change.x, change.y), 1.0 - exp(-turn_rate * delta))
	var busy := false
	for chain in chains:
		if chain.progress < 1.0:
			chain.progress = minf(1.0, chain.progress + delta / chain.seconds)
			var t: float = chain.progress
			chain.display = Vector3(chain.from).lerp(chain.target, t)
			chain.display.y += sin(t * PI) * lift * scale_factor
			if t >= 1.0:
				chain.planted = chain.target
			else:
				busy = true
		else:
			chain.display = chain.planted
	if busy or speed <= 0.001:
		return # A stopped/blocked actor finishes its current step, then plants.
	var threshold := step_distance * scale_factor
	var needs_step := false
	for chain in chains:
		var nominal: Vector3 = Basis(Vector3.UP, heading) * chain.nominal
		var drift := Vector2(chain.planted.x - at.x - nominal.x, chain.planted.z - at.y - nominal.z)
		if int(chain.group) == next_group and drift.length() > threshold:
			needs_step = true
	if not needs_step:
		return
	for chain in chains:
		if int(chain.group) != next_group:
			continue
		chain.from = chain.planted
		chain.target = nominal_position(chain, at + change.normalized() * threshold * 0.75, sampler, scale_factor)
		chain.progress = 0.0
		chain.seconds = clampf(threshold / maxf(speed, 0.01), 0.025, 0.22)
		steps_started += 1
	next_group = 1 - next_group

static func solve_chain(hip: Node3D, knee: Node3D, foot: Node3D, target: Vector3, forward: Vector3) -> float:
	var start := hip.global_position
	var upper := knee.global_position - start
	var lower := foot.global_position - knee.global_position
	var a := upper.length()
	var b := lower.length()
	if minf(a, b) < 0.0001:
		return INF
	var offset := target - start
	var direction := offset.normalized() if offset.length() > 0.0001 else Vector3.DOWN
	var reach := clampf(offset.length(), absf(a - b) + 0.0001, a + b - 0.0001)
	var along := (a * a - b * b + reach * reach) / (2.0 * reach)
	var perpendicular := upper - direction * upper.dot(direction)
	if perpendicular.length() < 0.0001:
		perpendicular = forward - direction * forward.dot(direction)
	if perpendicular.length() < 0.0001:
		perpendicular = Vector3.RIGHT - direction * direction.x
	var bend := direction * along + perpendicular.normalized() * sqrt(maxf(0.0, a * a - along * along))
	hip.global_basis = Basis(Quaternion(upper.normalized(), bend.normalized())) * hip.global_basis
	var desired := start + direction * reach - knee.global_position
	var actual := foot.global_position - knee.global_position
	if minf(desired.length(), actual.length()) > 0.0001:
		knee.global_basis = Basis(Quaternion(actual.normalized(), desired.normalized())) * knee.global_basis
	return foot.global_position.distance_to(target)

func apply(model: Node3D, rig: Node3D, scale_factor: float, released: String = "") -> void:
	if not initialized or not model.is_inside_tree():
		return
	rig.rotation.y = heading
	model.position.y = surface_y
	for chain in chains:
		if str(chain.hip.name) == released:
			continue
		var foot_target: Vector3 = chain.display
		var local := Vector3(foot_target.x - anchor.x, foot_target.y - surface_y, foot_target.z - anchor.y)
		var forward := model.global_basis * (Basis(Vector3.UP, heading) * Vector3.BACK)
		chain.error = solve_chain(chain.hip, chain.knee, chain.foot, model.to_global(local), forward)
		# Keep the pad level after the limb bends; preserve the creature's art scale.
		chain.foot.global_basis = model.global_basis * Basis(Vector3.UP, heading).scaled(Vector3.ONE * scale_factor)
