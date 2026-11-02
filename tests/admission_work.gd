extends SceneTree
const Validation=preload("res://scripts/core/runtime_validation_cache.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var library: MoveLibrary=load("res://resources/move_library.tres").duplicate(true)
	var memo:=Validation.new()
	for species in ["seedmote","bramblepup","sol_species_0001","sol_species_0002"]:
		check(library.book(species)==library.book(species,memo),"Memoized admission builds the identical independent move book")
	check(memo.validation_runs==1,"One unchanged library admission validates once across species")
	var prior: int=library.moves[0].power
	library.moves[0].power=-1
	check(library.book("bramblepup",memo).is_empty(),"A direct nested move edit cannot bypass validation")
	library.moves[0].power=prior
	check(library.book("bramblepup",memo)==library.book("bramblepup"),"Restoring the move restores the exact book")
	check(memo.validation_runs==3,"Nested invalidation is detected in both directions")
	var scene: Node3D=load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	var world: Node2D=scene.world
	world.smoke_mode=true
	world.paused=true
	var actors: Node3D=scene.sightings
	var retained: Dictionary=actors.members[0]
	var identity: String=retained.id
	var resolved: Dictionary=actors.ecology_for(retained)
	var tuning: Resource=resolved.tuning
	var from: Vector2i=world.cell
	world.cell=Vector2i(16,world.terrain.trail_y(16))
	world.camera.position=world.center(world.cell)
	actors.admit_nearby(from,world.cell)
	check(actors.members_by_id.has(identity) and actors.members_by_id[identity].sprite==retained.sprite,"Admission retains the unchanged creature model")
	check(actors.ecology_for(actors.members_by_id[identity]).tuning==tuning,"Admission retains its unchanged resolved behavior tuning")
	for cached_id: String in actors.ecology_cache:
		check(actors.members_by_id.has(cached_id),"Behavior memo remains bounded by the current local membership")
	var before: Dictionary=world.persistent_state.snapshot()
	var original_radius: int=actors.settings.visible_radius
	actors.settings.visible_radius=original_radius-1
	actors.sync_views()
	check(actors.ecology_for(actors.members_by_id[identity]).tuning!=tuning,"Direct tuning edits invalidate retained behavior resolutions")
	actors.settings.visible_radius=original_radius
	actors.sync_views()
	check(actors.ecology_for(actors.members_by_id[identity]).tuning.visible_radius==original_radius,"In-place tuning restoration also invalidates the memo")
	check(world.persistent_state.snapshot()==before,"Behavior/view memo invalidation does not change saved individuals or simulation")
	var controller: Node=scene.battles
	var saved_book: Dictionary=world.persistent_state.movebook(identity)
	var validation_runs: int=controller.movebook_validation.validation_runs
	world.persistent_state._movebooks.erase(identity)
	controller.ensure_movebooks([identity])
	check(world.persistent_state.movebook(identity)==saved_book,"A new admission copies the exact species template into the individual ledger")
	check(controller.movebook_validation.validation_runs==validation_runs,"Unchanged species templates reuse the admitted library graph")
	check(controller.movebook_templates.size()<=SolSpeciesCatalog.MAX_SPECIES,"Species templates stay bounded by the library roster")
	var original_power: int=controller.library.moves[0].power
	controller.library.moves[0].power=-1
	world.persistent_state._movebooks.erase(identity)
	controller.ensure_movebooks([identity])
	check(world.persistent_state.movebook(identity).is_empty() and controller.movebook_templates.is_empty(),"Invalid nested library edits invalidate templates before they can be committed")
	controller.library.moves[0].power=original_power
	controller.ensure_movebooks([identity])
	check(world.persistent_state.snapshot()==before,"Template invalidation/restoration leaves complete individual and simulation state unchanged")


	world.persistent_state._movebooks.erase(identity)
	actors.admit_nearby(world.cell + Vector2i(16,0), world.cell)
	check(actors.pending_books.has(identity), "Revisiting an existing identity requeues a missing move book")
	for frame in range(actors.members.size() + actors.pending_books.size() + 1): actors.pump_admission()
	check(world.persistent_state.has_movebook(identity), "Deferred book preparation eventually finishes on revisit")
	# Force a presentation replacement while preserving exactly the same canonical roster.
	var canonical_before: Dictionary = world.persistent_state.snapshot()
	actors.rebuild(false, true)
	check(actors.members.size() > 1 and actors.members.all(func(member: Dictionary) -> bool: return member.pending_view and not member.sprite.visible), "Deferred admission retains all canonical members with hidden adapters")
	check(world.persistent_state.snapshot() == canonical_before, "Queuing models never changes saved individuals or decisions")
	var pending_before: int = actors.members.filter(func(member: Dictionary) -> bool: return member.pending_view).size()
	actors.pump_admission()
	var pending_after: int = actors.members.filter(func(member: Dictionary) -> bool: return member.pending_view).size()
	check(pending_before - pending_after == 1 and actors.last_admission_items == 1, "One frame prepares at most one new model")
	check(world.persistent_state.snapshot() == canonical_before, "Preparing a model leaves the authoritative snapshot identical")
	for frame in range(actors.members.size() + actors.pending_books.size() + 1): actors.pump_admission()
	check(actors.members.all(func(member: Dictionary) -> bool: return not member.pending_view and member.has("label")), "The bounded model queue eventually drains")
	actors.sync_views()
	if OS.get_cmdline_user_args().has("--capture-admission") and DisplayServer.get_name() != "headless":
		scene.process_mode = Node.PROCESS_MODE_DISABLED
		for frame in range(4): await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("res://artifacts/gameplay-hitch-followup/admission.png")
	check(actors.members_by_id.has(identity), "Presentation staging preserves roster identity")
	actors.rebuild(false, true)
	actors.pending_books.append("stale-test-identity")
	world.new_expedition(19)
	check(actors.pending_books.is_empty() and actors.admission_state == world.persistent_state, "New expeditions discard stale preparation work")
	var started:=Time.get_ticks_usec()
	for repeat in range(20): library.book("bramblepup")
	var full_ms: float=(Time.get_ticks_usec()-started)/1000.0
	started=Time.get_ticks_usec()
	for repeat in range(20): library.book("bramblepup",memo)
	var memo_ms: float=(Time.get_ticks_usec()-started)/1000.0
	scene.environment.sky=null
	scene.free()
	print("ADMISSION WORK: %d checks, %d failures; 20 books full validation %.3f ms vs memo %.3f ms"%[checks,failures,full_ms,memo_ms])
	quit(0 if failures==0 else 1)
