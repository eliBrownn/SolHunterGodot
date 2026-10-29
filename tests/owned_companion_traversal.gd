extends SceneTree

class ShoreTerrain extends WorldTerrain:
	func natural_ground(cell: Vector2i) -> int:
		return Ground.WATER if cell.x in [1, 2] else Ground.MEADOW
	func fits(cell: Vector2i, _footprint: int = 1) -> bool:
		return natural_ground(cell) != Ground.WATER
	func sample(cell: Vector2i) -> Dictionary:
		return {"ground": natural_ground(cell), "obstacle": 0}
	func display_height(_at: Vector2) -> float:
		return 0.4
	func surface_height(at: Vector2) -> float:
		return 0.0 if natural_ground(Vector2i(at.floor())) == Ground.WATER else 0.4

class ShoreWorld extends Node2D:
	var terrain := ShoreTerrain.new(17)
	var persistent_state := ExpeditionState.new(17)
	var cell := Vector2i(-1, 0)
	var destination := cell
	var moving := false
	var paused := false
	var encounter_active := false
	var camera := Node2D.new()
	var host: Node3D
	func can_step(from: Vector2i, to: Vector2i) -> bool:
		return terrain.fits(from) and terrain.fits(to) and SolRoamingPolicy.distance(from, to) == 1

class ClearHost extends Node3D:
	var sightings: Node3D
	var sol_visual_settings := SolVisualSettings.new()
	var sighting_settings := SightingSettings.new()
	var world: Node2D
	func ground_height(at: Vector2) -> float:
		return world.terrain.surface_height(at)

class EmptySightings extends Node3D:
	var members: Array = []

var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	create_timer(90).timeout.connect(func() -> void: quit(1))
	run.call_deferred()

func run() -> void:
	var settings := OwnedCompanionSettings.new()
	var world := ShoreWorld.new()
	var catalog: SolSpeciesCatalog = load("res://resources/sol_species/catalog.tres")
	var flight := OwnedCompanionTraversal.new()
	flight.reset(catalog.find("sol_species_0001").traversal.snapshot(), Vector2i.ZERO)
	var target := flight.advance(world, Vector2i.ZERO, Vector2i(4, 0), {}, [], world.can_step, settings, 0.0, true)
	check(target == Vector2i.ZERO and flight.mode() == "takeoff", "Owned flight begins with a stationary, legally cleared takeoff")
	check(not flight.complete(world, Vector2i.ZERO, {}, [], 0.1), "Takeoff cannot spend its transition twice or finish early")
	check(flight.complete(world, Vector2i.ZERO, {}, [], 0.2) and flight.mode() == "air", "Configured step duration completes the launch")
	check(not world.can_step(Vector2i.ZERO, Vector2i(1, 0)), "Ordinary ground/player movement cannot cross the test water")
	target = flight.advance(world, Vector2i.ZERO, Vector2i(4, 0), {}, [], world.can_step, settings, 0.2, true)
	check(target == Vector2i(1, 0) and flight.mode() == "air", "Owned flyer can follow a shared legal air corridor across water")
	var visual := flight.visual(world.terrain, target, Vector2(1.0, 0.5), 0.3)
	check(visual.kind == "flight" and visual.amount == 1.0 and visual.height > 0.4, "Owned flight consumes the existing shared height/wingbeat presentation")
	flight.advance(world, target, Vector2i.ZERO, {}, [], world.can_step, settings, 0.4, false)
	check(flight.mode() == "air", "An unsupported water landing waits in air without relocating")
	flight.advance(world, Vector2i.ZERO, Vector2i(-1, 0), {}, [], world.can_step, settings, 0.6, false)
	check(flight.mode() == "landing", "A resting flyer descends only over legal land")
	check(flight.complete(world, Vector2i.ZERO, {Vector2i.ZERO: true}, [], 0.8) and flight.mode() == "air", "New landing occupancy aborts safely to flight")
	flight.advance(world, Vector2i.ZERO, Vector2i(-1, 0), {}, [], world.can_step, settings, 1.0, false)
	check(flight.complete(world, Vector2i.ZERO, {}, [], 1.2) and flight.grounded(), "A clear landing returns the owned flyer to ground rest")
	var obstruction: Array = [AABB(Vector3(-2, 0.6, -2), Vector3(8, 3, 5))]
	flight.reset(catalog.find("sol_species_0001").traversal.snapshot(), Vector2i.ZERO)
	target = flight.advance(world, Vector2i.ZERO, Vector2i(4, 0), {}, obstruction, func(_a: Vector2i, _b: Vector2i) -> bool: return false, settings, 0, true)
	check(target == Vector2i.ZERO and flight.grounded(), "Blocked wing/body clearance cannot launch or teleport")
	var swimmer := OwnedCompanionTraversal.new()
	swimmer.reset(catalog.find("sol_species_0002").traversal.snapshot(), Vector2i.ZERO)
	target = swimmer.advance(world, Vector2i.ZERO, Vector2i(4, 0), {}, [], world.can_step, settings, 0, true)
	check(target == Vector2i(1, 0) and swimmer.mode() == "swim_enter", "Owned Reedback enters water through the shared legal bank transition")
	visual = swimmer.visual(world.terrain, target, Vector2(1.0, 0.5), 0.1)
	check(visual.kind == "swim" and visual.amount > 0 and visual.amount < 1, "Water entry blends the actual shared swimming pose")
	check(swimmer.complete(world, target, {}, [], 0.2) and swimmer.mode() == "swim", "Deep water resolves to swimming after the transition")
	target = swimmer.advance(world, target, Vector2i(4, 0), {}, [], world.can_step, settings, 0.2, true)
	check(target == Vector2i(2, 0) and swimmer.mode() == "swim", "Owned swimming continues one legal cardinal step at a time")
	target = swimmer.advance(world, target, Vector2i(4, 0), {}, [], world.can_step, settings, 0.4, true)
	check(target == Vector2i(3, 0) and swimmer.mode() == "swim_exit", "Owned swimmer uses the bank exit instead of jumping to the player")
	check(swimmer.complete(world, target, {}, [], 0.6) and swimmer.grounded(), "Bank exit restores ground locomotion")
	# Exercise the actual owned component, actual identity and actual species model.
	var host := ClearHost.new()
	host.world = world
	world.host = host
	host.sightings = EmptySightings.new()
	host.add_child(host.sightings)
	root.add_child(host)
	world.cell = Vector2i(4, 0)
	world.destination = world.cell
	settings.admission_side = "west"
	check(world.persistent_state.choose_starter(catalog.find("sol_species_0002").battle_profile("fire"), 0), "Controller fixture owns a real Reedback with independent fire affinity")
	var companion: Node3D = load("res://scripts/owned_companion.gd").new()
	host.add_child(companion)
	companion.bind(world, settings)
	companion.set_process(false)
	var before := world.persistent_state.snapshot()
	var id: String = companion.identity
	check(companion.cell == Vector2i(3, 0), "Owned admission starts on the dry bank")
	world.cell = Vector2i(-1, 0)
	world.destination = world.cell
	var modes := {}
	for frame in range(20):
		companion._process(0.1)
		modes[companion.travel.mode()] = true
		if companion.travel.mode() == "swim_enter":
			var at: Vector2i = companion.cell
			var clock: float = companion.elapsed
			world.paused = true
			companion._process(0.1)
			check(companion.cell == at and companion.elapsed == clock, "Pause freezes owned water-transition time and location")
			world.paused = false
			world.encounter_active = true
			companion._process(0.1)
			check(not companion.sprite.visible and companion.elapsed == clock, "Encounter hides and freezes an in-water companion")
			world.encounter_active = false
	check(modes.has("swim_enter") and modes.has("swim") and modes.has("swim_exit") and companion.travel.grounded(), "Actual owned controller follows through entry, swimming, exit and ground rest")
	check(companion.cell == Vector2i.ZERO and companion.identity == id and companion.sprite.affinity == "fire", "Water follow retains the selected identity and actual independent affinity")
	check(world.persistent_state.snapshot() == before, "Owned traversal does not create save rows, grant capability from affinity, or alter ownership")
	world.persistent_state = ExpeditionState.new(17)
	world.cell = Vector2i(4, 0)
	world.destination = world.cell
	check(world.persistent_state.choose_starter(catalog.find("sol_species_0001").battle_profile("earth"), 0), "Second controller fixture owns a Crown-Ear independently of affinity")
	companion._process(0.1)
	id = companion.identity
	world.cell = Vector2i(-1, 0)
	world.destination = world.cell
	modes.clear()
	for frame in range(35):
		companion._process(0.1)
		modes[companion.travel.mode()] = true
	check(modes.has("takeoff") and modes.has("air") and modes.has("landing") and companion.travel.grounded(), "Actual selected Crown-Ear launches, crosses the water, lands and rests by its player")
	check(companion.cell == Vector2i.ZERO and companion.sprite.affinity == "earth" and companion.identity == id, "Owned flight preserves actual identity, independent affinity and a legal final ground cell")
	var restored := ExpeditionState.restore(world.persistent_state.snapshot(), 17)
	world.persistent_state = restored
	companion._process(0.1)
	check(restored != null and companion.identity == id and companion.travel.grounded(), "State replacement reconstructs owned travel on legal ground without restoring a stale air mode")
	host.free()
	world.camera.free()
	world.free()
	print("OWNED COMPANION TRAVERSAL: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
