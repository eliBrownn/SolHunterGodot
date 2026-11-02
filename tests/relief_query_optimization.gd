extends SceneTree
## Exact legacy ridge comparison, including support edges and cache eviction.
var checks := 0
var failures := 0

class ReferenceField extends TerrainHeightfield:
	func raw_height(at: Vector2) -> float:
		var base := noise_height(at) + mountain_height_at(at)
		var strength: float = _parameters.landform_strength
		if strength == 0: return base
		var form := landform_at(at)
		var local := (at - Vector2(form.center)).rotated(-float(form.angle))
		var radius := Vector2(local.x / 46.0, local.y / 34.0).length()
		if radius >= 1: return base
		var weight := 1.0 - smoothstep(0.65, 1.0, radius)
		match int(form.kind):
			0:
				var spine := pow(maxf(0.0, 1.0 - absf(local.y) / 18.0), 2.0)
				var ends := 1.0 - smoothstep(18.0, 46.0, absf(local.x))
				var saddle := lerpf(0.35, 1.0, smoothstep(0.0, 10.0, absf(local.x)))
				return base + strength * 5.0 * spine * ends * saddle * weight
			1: return base - strength * 3.5 * pow(1.0 - radius * radius, 2.0)
			2: return lerpf(base, float(form.level) + strength * 4.0, weight)
			3:
				var tiers := smoothstep(-22.0, -12.0, local.x) * 2.0 + smoothstep(4.0, 14.0, local.x) * 2.0
				return lerpf(base, float(form.level) + strength * tiers, weight)
		return base

	func mountain_height_at(at: Vector2) -> float:
		var amplitude: float = _parameters.mountain_height
		if amplitude == 0.0 or absf(at.y) <= 40.0: return 0.0
		var spacing: float = _parameters.mountain_spacing
		var parent := Vector2i((at / spacing).floor())
		var height := 0.0
		for y in range(-1, 2):
			for x in range(-1, 2):
				var key := parent + Vector2i(x, y)
				if not _ranges.has(key):
					var roll: int = ("mountain-v1:%d:%d:%d" % [_seed, key.x, key.y]).hash()
					if _ranges.size() >= 128: _ranges.erase(_ranges.keys()[0])
					_ranges[key] = {"center": (Vector2(key) + Vector2(0.35 + float(roll % 301) / 1000.0, 0.35 + float((roll / 307) % 301) / 1000.0)) * spacing,
						"angle": float((roll / 997) % 6283) / 1000.0, "phase": float(roll % 6283) / 1000.0}
				var form: Dictionary = _ranges[key]
				var local := (at - Vector2(form.center)).rotated(-float(form.angle))
				var along := local.x / (spacing * 0.65)
				if absf(along) >= 1.0: continue
				var crest := sin(along * 5.0 + float(form.phase)) * spacing * 0.025
				var across := absf(local.y - crest) / (spacing * 0.14)
				if across >= 1.0: continue
				var envelope := (1.0 - smoothstep(0.45, 1.0, absf(along))) * pow(1.0 - across * across, 2.0)
				var peaks := 0.65 + 0.35 * pow(sin(along * 9.0 + float(form.phase)), 2.0)
				height = maxf(height, amplitude * envelope * peaks)
		return height * smoothstep(40.0, 96.0, absf(at.y))

func _initialize() -> void: run.call_deferred()

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	var points := PackedVector2Array()
	for y in range(-20, 21):
		for x in range(-20, 21): points.append(Vector2(x * 71.25, y * 63.75))
	for y in [-1000000.0, -96.0, -40.001, -40.0, 0.0, 40.0, 40.001, 96.0, 1000000.0]:
		for x in [-1000000.0, -768.001, -256.0, -0.001, 0.0, 256.0, 768.001, 1000000.0]: points.append(Vector2(x, y))
	var populated := 0
	for seed_value in [0, 17, 2601026, 2147483646]:
		for spacing in [256.0, 384.0, 768.0]:
			var tuning: TerrainReliefSettings = load("res://resources/terrain_exploration.tres").duplicate()
			tuning.mountain_height = 24.0
			tuning.mountain_spacing = spacing
			var reference := ReferenceField.new(seed_value, tuning)
			var current := TerrainHeightfield.new(seed_value, tuning)
			for at in points:
				var expected := reference.raw_height(at)
				check(current.raw_height(at) == expected, "Raw relief matches before culling at %s" % at)
				if reference.mountain_height_at(at) > 0.0: populated += 1
			# Probe near both ends and sides of actual rotated ridge supports.
			var forms := reference._ranges.values()
			for form: Dictionary in forms:
				for along in [-1.001, -0.999, 0.0, 0.999, 1.001]:
					var crest: float = sin(along * 5.0 + float(form.phase)) * spacing * 0.025
					for across in [-1.001, -0.999, 0.0, 0.999, 1.001]:
						var at: Vector2 = Vector2(form.center) + Vector2(along * spacing * 0.65, crest + across * spacing * 0.14).rotated(float(form.angle))
						check(current.mountain_height_at(at) == reference.mountain_height_at(at), "Ridge support edges match exactly")
			var landforms := reference._landforms.values()
			for form: Dictionary in landforms:
				for angle in range(16):
					for radius in [0.999, 1.0, 1.001, 1.03, 1.5]:
						var direction := Vector2.from_angle(angle * TAU / 16.0)
						var at: Vector2 = Vector2(form.center) + (direction * Vector2(46.0, 34.0) * radius).rotated(float(form.angle))
						check(current.raw_height(at) == reference.raw_height(at), "Local landform support edges match exactly")
			check(current._ranges.size() <= 128, "Parent descriptor cache remains bounded after distant queries")
			check(current.snapshot() == reference.snapshot(), "Saved generation contract is unchanged")
	check(populated > 1000, "Comparison exercises contributing ridges as well as empty parents")
	if "--profile" in OS.get_cmdline_user_args(): profile(points)
	print("RELIEF QUERY OPTIMIZATION: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func profile(points: PackedVector2Array) -> void:
	var tuning: TerrainReliefSettings = load("res://resources/terrain_exploration.tres")
	var report := {"engine": Engine.get_version_info().string, "scope": "Paired raw-relief CPU queries; retained OS caches; not rendered FPS", "queries_per_run": points.size() * 4, "source_sha256": FileAccess.get_sha256("res://scripts/world/terrain_heightfield.gd"), "fixture_sha256": FileAccess.get_sha256("res://tests/relief_query_optimization.gd"), "parameters": tuning.parameters(), "runs": []}
	for repeat in range(4):
		var reference := ReferenceField.new(2601026, tuning)
		var current := TerrainHeightfield.new(2601026, tuning)
		var row := {}
		# Alternate order to reduce systematic warmup/order bias.
		for field in ([reference, current] if repeat % 2 == 0 else [current, reference]):
			var began := Time.get_ticks_usec()
			var total := 0.0
			for pass_index in range(4):
				for at in points: total += field.raw_height(at)
			row["reference_ms" if field == reference else "current_ms"] = (Time.get_ticks_usec() - began) / 1000.0
			row["reference_sum" if field == reference else "current_sum"] = total
		check(row.reference_sum == row.current_sum, "Paired CPU profile retains exact relief checksum")
		report.runs.append(row)
	DirAccess.make_dir_recursive_absolute("res://artifacts/relief-query-optimization")
	var file := FileAccess.open("res://artifacts/relief-query-optimization/profile.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("RELIEF PROFILE ", JSON.stringify(report))
