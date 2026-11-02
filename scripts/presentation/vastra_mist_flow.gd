extends RefCounted
## Transient CPU reference field for the mist study. Coordinates are terrain cells,
## Y is world height, time is active seconds. No ecology, scene or save references.
const SIZE := Vector3i(17, 7, 17)
const CELL := 0.5
const STEP := 1.0 / 30.0
const COUNT := 2023
const MAX_STEPS := 4
const MAX_DISPLACEMENT := 0.7
var origin := Vector3.ZERO
var velocity := PackedVector3Array()
var displacement := PackedVector3Array()
var density := PackedFloat32Array()
var next_velocity := PackedVector3Array()
var next_displacement := PackedVector3Array()
var next_density := PackedFloat32Array()
var previous_body := Vector3.ZERO
var simulated_body := Vector3.ZERO
var initialized := false
var remainder := 0.0
var steps := 0
# Study defaults; not adopted gameplay controls.
var body_radius := 0.38
var body_height := 0.85
var drift := Vector3(0.08, 0.0, 0.025)

func _init() -> void:
	velocity.resize(COUNT)
	displacement.resize(COUNT)
	next_velocity.resize(COUNT)
	next_displacement.resize(COUNT)
	density.resize(COUNT)
	next_density.resize(COUNT)
	density.fill(1.0)

func index(x: int, y: int, z: int) -> int:
	return (z * SIZE.y + y) * SIZE.x + x

func reset(body: Vector3) -> void:
	previous_body = body
	simulated_body = body
	remainder = 0.0
	initialized = true
	origin = (body / CELL).floor() * CELL - Vector3(4, 0.5, 4)
	velocity.fill(Vector3.ZERO)
	displacement.fill(Vector3.ZERO)
	density.fill(1.0)

func shift_window(body: Vector3) -> void:
	var desired := (body / CELL).floor() * CELL - Vector3(4, 0.5, 4)
	var offset := Vector3i(((desired - origin) / CELL).round())
	if offset == Vector3i.ZERO:
		return
	for z in range(SIZE.z):
		for y in range(SIZE.y):
			for x in range(SIZE.x):
				var i := index(x, y, z)
				var old := Vector3i(x, y, z) + offset
				var inside := old.x >= 0 and old.x < SIZE.x and old.y >= 0 and old.y < SIZE.y and old.z >= 0 and old.z < SIZE.z
				var j := index(old.x, old.y, old.z) if inside else 0
				next_velocity[i] = velocity[j] if inside else Vector3.ZERO
				next_displacement[i] = displacement[j] if inside else Vector3.ZERO
				next_density[i] = density[j] if inside else 1.0
	var swap := velocity
	velocity = next_velocity
	next_velocity = swap
	swap = displacement
	displacement = next_displacement
	next_displacement = swap
	var scalar_swap := density
	density = next_density
	next_density = scalar_swap
	origin = desired

func advance(delta: float, body: Vector3, paused := false) -> void:
	if not body.is_finite() or not is_finite(delta) or delta < 0.0:
		return
	if not initialized or body.distance_to(previous_body) > 3.0:
		reset(body)
		return
	if paused:
		# Suppress a sweep from movement made while frozen.
		previous_body = body
		simulated_body = body
		return
	shift_window(body)
	var admitted := minf(delta, STEP * MAX_STEPS)
	var start_time := remainder
	remainder += admitted
	var consumed := 0.0
	while remainder + 0.0000001 >= STEP:
		consumed += STEP
		var fraction := clampf((consumed - start_time) / maxf(admitted, 0.000001), 0.0, 1.0)
		var target := previous_body.lerp(body, fraction)
		step_field(simulated_body, target)
		simulated_body = target
		remainder = maxf(0.0, remainder - STEP)
	previous_body = body

func sample(at: Vector3) -> Vector4:
	var p := (at - origin) / CELL
	if p.x < 0 or p.y < 0 or p.z < 0 or p.x >= SIZE.x - 1 or p.y >= SIZE.y - 1 or p.z >= SIZE.z - 1:
		return Vector4(0, 0, 0, 1)
	var base := Vector3i(p.floor())
	var f := p - Vector3(base)
	var result := Vector4.ZERO
	for z in range(2):
		for y in range(2):
			for x in range(2):
				var weight := (f.x if x else 1.0 - f.x) * (f.y if y else 1.0 - f.y) * (f.z if z else 1.0 - f.z)
				var i := index(base.x + x, base.y + y, base.z + z)
				var d := displacement[i]
				result += Vector4(d.x, d.y, d.z, density[i]) * weight
	return result

func step_field(from: Vector3, to: Vector3) -> void:
	var movement := to - from
	var speed := movement.length() / STEP
	var heading := movement.normalized()
	var side := Vector3(-heading.z, 0, heading.x)
	var segment_length := movement.length_squared()
	for z in range(SIZE.z):
		for y in range(SIZE.y):
			for x in range(SIZE.x):
				var i := index(x, y, z)
				var at := origin + Vector3(x, y, z) * CELL
				var left := velocity[index(maxi(x - 1, 0), y, z)]
				var right := velocity[index(mini(x + 1, SIZE.x - 1), y, z)]
				var down := velocity[index(x, maxi(y - 1, 0), z)]
				var up := velocity[index(x, mini(y + 1, SIZE.y - 1), z)]
				var rear := velocity[index(x, y, maxi(z - 1, 0))]
				var front := velocity[index(x, y, mini(z + 1, SIZE.z - 1))]
				# First-order upwind transport. Velocity cap keeps the summed CFL < 1.
				var transport := (velocity[i] + drift) * STEP / CELL
				var v := velocity[i]
				v += ((left if transport.x > 0 else right) - velocity[i]) * absf(transport.x)
				v += ((down if transport.y > 0 else up) - velocity[i]) * absf(transport.y)
				v += ((rear if transport.z > 0 else front) - velocity[i]) * absf(transport.z)
				v = v.lerp((left + right + down + up + rear + front) / 6.0, 0.12) * exp(-1.6 * STEP)
				var amount := 0.0
				if speed > 0.0001:
					var along := clampf((at - from).dot(movement) / maxf(segment_length, 0.000001), 0.0, 1.0)
					var closest := from.lerp(to, along)
					closest.y = clampf(at.y, closest.y + body_radius, closest.y + maxf(body_radius, body_height - body_radius))
					var radial := at - closest
					amount = 1.0 - smoothstep(body_radius * 0.4, body_radius + CELL, radial.length())
					# Drag, sideways parting and opposing curls. No elastic spring.
					var handed := 1.0 if radial.dot(side) >= 0.0 else -1.0
					var curl := side * handed * (-radial.dot(heading)) + heading * absf(radial.dot(side))
					v += (heading * 0.8 + radial.normalized() * 1.4 + curl * 2.2) * minf(speed, 5.0) * amount * STEP * 5.0
				v = v.limit_length(2.5)
				var transported := sample(at - (v + drift) * STEP)
				var d := (Vector3(transported.x, transported.y, transported.z) + v * STEP) * exp(-0.9 * STEP)
				var border := minf(minf(x, SIZE.x - 1 - x), minf(y, SIZE.y - 1 - y))
				border = minf(border, minf(z, SIZE.z - 1 - z))
				var fade := smoothstep(0.0, 2.0, border)
				next_velocity[i] = v * fade
				next_displacement[i] = d.limit_length(MAX_DISPLACEMENT) * fade
				var cleared := minf(transported.w, 1.0 - amount * minf(speed * 0.45, 0.9))
				next_density[i] = lerpf(1.0, lerpf(cleared, 1.0, 1.0 - exp(-0.8 * STEP)), fade)
	var swap := velocity
	velocity = next_velocity
	next_velocity = swap
	swap = displacement
	displacement = next_displacement
	next_displacement = swap
	var scalar_swap := density
	density = next_density
	next_density = scalar_swap
	steps += 1
