extends SceneTree
const Flow = preload("res://scripts/presentation/vastra_mist_flow.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func strength(flow: RefCounted) -> float:
	var sum := 0.0
	for v: Vector3 in flow.velocity: sum += v.length_squared()
	return sum

func journey(fps: int, speed: float) -> RefCounted:
	var flow := Flow.new()
	flow.reset(Vector3(-1, 0, 0))
	for frame in range(fps):
		flow.advance(1.0 / fps, Vector3(-1 + speed * float(frame + 1) / fps, 0, 0))
	return flow

func _initialize() -> void:
	var idle := Flow.new()
	idle.reset(Vector3.ZERO)
	for frame in range(30): idle.advance(1.0 / 30.0, Vector3.ZERO)
	check(strength(idle) == 0.0, "Stationary body must not inject motion")
	check(idle.density.count(1.0) == Flow.COUNT, "Idle must not clear density")
	var walk := journey(30, 1.0)
	var run := journey(30, 2.5)
	check(strength(walk) > 0.01, "Walk leaves motion")
	check(strength(run) > strength(walk), "Running has a stronger disturbance")
	var crossing := Flow.new()
	crossing.reset(Vector3(-1, 0, 0))
	crossing.advance(Flow.STEP, Vector3(1, 0, 0))
	check(crossing.sample(Vector3(0, 0.5, 0)).w < 0.8, "Fast crossing affects the swept interior, not only the endpoint")
	var high: Vector4 = walk.sample(Vector3(0, 2.3, 0))
	check(Vector3(high.x, high.y, high.z).length() < 0.005 and high.w > 0.99, "High mist is separated from ground contact")
	var sixty := journey(60, 1.0)
	var fifteen := journey(15, 1.0)
	check(walk.steps == 30 and sixty.steps == 30 and fifteen.steps == 30, "Fixed step count at 15/30/60 Hz")
	var difference := 0.0
	for i in range(Flow.COUNT): difference = maxf(difference, walk.velocity[i].distance_to(sixty.velocity[i]))
	check(difference < 0.0001, "Equivalent fixed-step route at 30/60 Hz")
	difference = 0.0
	for i in range(Flow.COUNT): difference = maxf(difference, walk.velocity[i].distance_to(fifteen.velocity[i]))
	check(difference < 0.0001, "Equivalent fixed-step route at 15/30 Hz")
	var before := strength(walk)
	walk.advance(Flow.STEP, walk.previous_body)
	check(strength(walk) > 0.01, "Wake persists after stopping")
	for frame in range(180): walk.advance(Flow.STEP, walk.previous_body)
	check(strength(walk) < before * 0.001, "Wake dissipates without elastic return forcing")
	var retained: Vector4 = run.sample(Vector3(0.5, 0.5, 0))
	run.shift_window(run.previous_body + Vector3(0.5, 0, 0))
	check(run.sample(Vector3(0.5, 0.5, 0)).is_equal_approx(retained), "World-space overlap preserved across cell shift")
	var frozen: PackedVector3Array = run.velocity.duplicate()
	run.advance(1.0, run.previous_body, true)
	check(run.velocity == frozen, "Pause freezes state")
	var old_steps: int = run.steps
	run.advance(10.0, run.previous_body)
	check(run.steps - old_steps <= Flow.MAX_STEPS, "Stalled frames have capped work")
	for i in range(Flow.COUNT):
		check(run.velocity[i].is_finite() and run.displacement[i].is_finite() and run.displacement[i].length() <= Flow.MAX_DISPLACEMENT + 0.00001 and run.density[i] >= 0.0 and run.density[i] <= 1.0, "Finite bounded field")
	run.advance(Flow.STEP, Vector3(100, 0, 100))
	check(strength(run) == 0.0 and run.density.count(1.0) == Flow.COUNT, "Teleport resets without a long sweep")
	run.advance(NAN, Vector3.ZERO)
	run.advance(Flow.STEP, Vector3(INF, 0, 0))
	check(strength(run) == 0.0, "Invalid input leaves safe state")
	print("VASTRA MIST FLOW: ", checks, " checks; ", failures, " failures")
	quit(0 if failures == 0 else 1)
