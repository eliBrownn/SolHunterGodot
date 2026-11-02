extends SceneTree
## Pure-query reuse, bounded caches, exact navigation/refill behavior and rejected art.
const Sightings=preload("res://scripts/sols/presentation/authored_sightings.gd")
const Art=preload("res://scripts/scenery/nature_art.gd")
var checks:=0
var failures:=0
var collision_calls:=0

class EmptyHomes extends Sightings:
	func build_wilderness_entry(_owner: Vector2i,_authored: Array,_policy: Variant) -> Dictionary:
		return {}

class WorldProbe extends Node2D:
	var terrain:=WorldTerrain.new(2601026)
	var cell:=Vector2i.ZERO
	var persistent_state:=ExpeditionState.new(2601026)

class AssetProbe extends NatureAssetEntry:
	var requests:=0
	func admitted_model() -> Dictionary:
		requests+=1
		return {}

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(message)

func _initialize() -> void: run.call_deferred()

func allowed(from: Vector2i,to: Vector2i) -> bool:
	collision_calls+=1
	return not (to.x==2 and to.y!=2) and from.distance_to(to)<=1.0

func run() -> void:
	var catalog_owner:=Sightings.new()
	catalog_owner.settings=load("res://resources/sol_world_sightings.tres")
	check(catalog_owner.settings_valid(),"Species catalog is admitted")
	var validations: int=catalog_owner.tuning_validation.validation_runs
	for repeat in range(4): catalog_owner.settings_valid()
	check(catalog_owner.tuning_validation.validation_runs==validations,"Live wildlife retains its catalog instead of invalidating validation with new resource IDs")
	catalog_owner.settings=null
	check(not catalog_owner.settings_valid() and catalog_owner.catalog_reference==null,"Removing wildlife settings releases the retained catalog")
	catalog_owner.free()
	var paired:="--paired" in OS.get_cmdline_user_args()
	var nav: Script=load("res://artifacts/runtime-hotpaths/reference_navigation.gd") if paired else SolLocalNavigation
	var homes: Script=load("res://artifacts/runtime-hotpaths/reference_sightings.gd") if paired else Sightings
	var refill: Script=load("res://artifacts/runtime-hotpaths/reference_refill.gd") if paired else ExpeditionState
	var tuning:=SightingSettings.new()
	var previous_calls:=0
	var current_calls:=0
	for budget in [4,16,64,128]:
		tuning.path_search_cells=budget
		for action in ["patrol","return","approach","flee","guard"]:
			for goal in [Vector2i(4,3),Vector2i(-4,-3),Vector2i(2,0),Vector2i.ZERO]:
				for offset in [Vector2i.ZERO,Vector2i(-16,16)]:
					for minimum in [0,2]:
						var occupied:={offset+Vector2i.DOWN:true}
						collision_calls=0
						var expected: Vector2i=nav.next_step(offset,offset,action,offset+goal,occupied,allowed,tuning,offset+Vector2i(3,0),minimum)
						previous_calls+=collision_calls
						collision_calls=0
						var actual:=SolLocalNavigation.next_step(offset,offset,action,offset+goal,occupied,allowed,tuning,offset+Vector2i(3,0),minimum)
						current_calls+=collision_calls
						check(actual==expected,"Early frontier rejection preserves ordered BFS decisions")
	check(current_calls<=previous_calls,"Full frontiers do not increase collision queries")
	if paired: check(current_calls<previous_calls,"Saturated search budgets eliminate discarded collision queries")
	var empty:=EmptyHomes.new()
	for index in range(129): empty.wilderness_entry(Vector2i(index,0),[],null)
	check(empty.wilderness_blocks.size()==empty.HOME_CACHE_LIMIT,"Home cache evicts one entry at its declared bound")
	var builds: int=empty.home_cache_builds
	empty.wilderness_entry(Vector2i(128,0),[],null)
	check(empty.home_cache_builds==builds,"Empty geographic blocks are cached too")
	empty.wilderness_entry(Vector2i.ZERO,[],null)
	check(empty.home_cache_builds==builds+1 and empty.wilderness_blocks.size()==128,"Evicted empty blocks reconstruct without flushing neighboring blocks")
	empty.free()
	var world:=WorldProbe.new()
	var settings: SightingSettings=load("res://resources/sol_world_sightings.tres")
	settings=settings.duplicate(true)
	var retained_catalog: Resource=settings.species_catalog
	var policy: Array=[]
	for pool in settings.habitat_encounters: policy.append(pool.snapshot())
	world.persistent_state.capture_habitat_encounters(policy)
	var reference: Node3D=homes.new()
	var current:=Sightings.new()
	var omitted:=0
	for y in range(-4,4):
		for x in range(-4,4):
			if posmod(x+y,2)==0: continue
			# No world is bound yet: excluded slots must skip terrain/model work.
			check(current.build_wilderness_entry(Vector2i(x,y),[],null).is_empty(),"Half-density omitted sectors skip admission, including negative coordinates")
			omitted+=1
	check(omitted==32,"Half of geographic home slots are omitted")
	for owner in [reference,current]:
		owner.world=world
		owner.settings=settings
	for at in [Vector2i.ZERO,Vector2i(16,0),Vector2i(32,0),Vector2i.ZERO,Vector2i(-16,-16),Vector2i(48,48)]:
		world.cell=at
		var expected: Array=reference.local_entries()
		var actual:=current.local_entries()
		check(actual==expected,"Cached block search preserves home order/species/affinity at %s"%at)
		var first_by_home: Dictionary = {}
		for entry: Dictionary in actual:
			var home: Vector2i = current.entry_home(entry)
			if first_by_home.has(home): continue
			first_by_home[home] = true
			var indexed: Dictionary = current.home_entry(home)
			check(indexed == entry, "Home lookup preserves first-entry order across sector changes")
			indexed["species"] = "caller mutation"
			check(current.home_entry(home) == entry, "Home lookup isolates callers from the retained home index")
		check(current.home_entry(Vector2i(999999,999999)).is_empty(), "Non-home inspection needs no population snapshot")
	check(current.home_cache_hits>=20,"Adjacent sector searches reuse their shared geographic blocks")
	builds=current.home_cache_builds
	settings.path_search_cells=63
	current.local_entries()
	check(current.home_cache_builds>builds,"Direct nested tuning edits invalidate home results")
	world.terrain=WorldTerrain.new(7)
	check(current.local_entries()==reference.local_entries(),"Terrain replacement invalidates cached home results")
	for entry: Dictionary in current.local_entries():
		check(current.home_entry(current.entry_home(entry)) == entry, "Terrain replacement refreshes the home index too")
	world.persistent_state=ExpeditionState.new(7)
	builds=current.home_cache_builds
	current.initialize_individuals(world.persistent_state)
	check(current.home_cache_builds>builds,"State replacement invalidates the geographic policy cache even when terrain is reused")
	builds=current.home_cache_builds
	var identities:=world.persistent_state.individual_ids()
	current.initialize_individuals(world.persistent_state)
	check(current.home_cache_builds==builds and world.persistent_state.individual_ids()==identities,"Same-state admission reuses homes without rerolling individuals")
	reference.free()
	current.free()
	var refill_old_ms:=0.0
	var refill_new_ms:=0.0
	for classified in [false,true]:
		for limit in [1,7,256,1024]:
			var actual:=ExpeditionState.new(17)
			var expected: RefCounted=refill.new(17)
			var definitions: Array[Dictionary]=[]
			for index in range(600): definitions.append({"id":FloraCatalog.id_for(Vector2i(index,0)),"cell":[index,0],"kind":"tree" if index%17==0 else "plant"})
			var ids: Array[String]=[]
			for row in definitions: ids.append(row.id)
			for owner in [actual,expected]:
				owner.configure_flora(VastraSettings.new().plant_parameters())
				owner.admit_flora(definitions)
				owner.set_flora_active(ids)
				if classified: owner.configure_ecology(VesselSettings.new().parameters())
				owner._flora.flights=[{"source":ids[1],"target":ids[2],"root":false,"amount":25,"sent":0,"arrival":4,"release_ticks":8,"delivered":0},{"source":ids[0],"target":ids[3],"root":true,"amount":20,"sent":0,"arrival":4}]
			var environment:=func(at: Vector2i) -> Dictionary: return {"concentration":posmod(at.x*19,101),"overload":0}
			for frame in range(64):
				for owner in [actual,expected]: owner.advance_time(1.0/120.0)
				var started:=Time.get_ticks_usec()
				var before: int=expected.advance_flora_refill(environment,limit)
				refill_old_ms+=(Time.get_ticks_usec()-started)/1000.0
				started=Time.get_ticks_usec()
				var after:=actual.advance_flora_refill(environment,limit)
				refill_new_ms+=(Time.get_ticks_usec()-started)/1000.0
				check(before==after and actual._flora==expected._flora and actual._flora_refill_cursor==expected._flora_refill_cursor,"Refill preserves exact credit, reservations, fractional time and round-robin progress")
				for index in [0,1,2,599]:
					var at := Vector2i(index,0)
					var reading: Dictionary = actual.flora_reading(at)
					check(actual.flora_reserve_fraction(at) == float(reading.energy)/maxf(1.0,float(reading.capacity)), "Light reserve reads match live trees/plants, held transfers and partial refill with ecology on/off")
			check(actual.flora_reserve_fraction(Vector2i(-1,-1)) < 0.0, "Missing plants remain distinguishable from empty reserves")
	var cell:=Vector2i.ZERO
	for x in range(64):
		var data:=world.terrain.sample(Vector2i(x,0))
		if data.obstacle==0:
			cell=Vector2i(x,0)
			break
	var asset:=AssetProbe.new()
	var patch:=NaturePatch.new()
	patch.habitats.assign([0,1,2,3,4,5])
	patch.entries.assign([asset])
	patch.density_percent=100
	var rejected:=NatureComposition.placement_for(world.terrain,cell,patch,1,100,0.0,false,false,false,false)
	check(rejected.is_empty() and asset.requests==0,"Rejected living art never prepares a model")
	asset.living=false
	NatureComposition.placement_for(world.terrain,cell,patch,1,100,0.0,false,false,false,false)
	check(asset.requests==1,"Nonliving dressing still follows the model-admission authority")
	var node:=MeshInstance3D.new()
	var mesh:=ArrayMesh.new()
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3.ZERO,Vector3.RIGHT,Vector3.UP,Vector3.BACK])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,StandardMaterial3D.new())
	node.mesh=mesh
	var scene:=PackedScene.new()
	scene.pack(node)
	node.free()
	check(Art.parts(scene).triangles==2,"ArrayMesh counts agree with indexed geometry without retrieving vertex arrays")
	world.free()
	print("RUNTIME WORK REUSE: %d checks, %d failures; collision queries %d -> %d; refill CPU %.3f -> %.3f ms"%[checks,failures,previous_calls,current_calls,refill_old_ms,refill_new_ms])
	quit(0 if failures==0 else 1)
