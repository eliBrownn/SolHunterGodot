extends SceneTree
## Exact previous query versus retained-resource/negative-result cache. CPU only.
func _initialize() -> void: run.call_deferred()

func previous_query(terrain: WorldTerrain,cell: Vector2i) -> String:
	if terrain._aquatic_flora_cache.has(cell): return terrain._aquatic_flora_cache[cell]
	var composition = load("res://resources/scenery/bounded_composition.tres")
	var patch = composition.patch_at(terrain,cell)
	if patch == null: return ""
	var record: Dictionary = composition.placement_for(terrain,cell,patch,3,68,0.0,false,true,false)
	var kind := "plant" if record.get("living",false) else ""
	if terrain._aquatic_flora_cache.size() >= 4096: terrain._aquatic_flora_cache.clear()
	terrain._aquatic_flora_cache[cell] = kind
	return kind

func run() -> void:
	var signature := FileAccess.get_sha256("res://scripts/world/terrain.gd")
	var results: Array = []
	var snapshots: Array = []
	for optimized in [false,true]:
		var terrain := WorldTerrain.new(2601026)
		if not optimized: terrain._wetland_composition = null
		var output: Array = []
		var began := Time.get_ticks_usec()
		for y in range(32,40):
			for x in range(16,32):
				var cell := Vector2i(x,y)
				output.append(terrain.authored_wetland_flora(cell) if optimized else previous_query(terrain,cell))
		results.append({"optimized":optimized,"queries":output.size(),"ms":(Time.get_ticks_usec()-began)/1000.0,"cached_cells":terrain._aquatic_flora_cache.size()})
		snapshots.append(output)
	var report := {"engine":Engine.get_version_info().string,"scope":"Paired 128-cell CPU query; OS caches retained; not FPS","runs":results,"equivalent":snapshots[0]==snapshots[1],"source_drift":signature!=FileAccess.get_sha256("res://scripts/world/terrain.gd")}
	DirAccess.make_dir_recursive_absolute("res://artifacts/bottleneck-fixes")
	var file := FileAccess.open("res://artifacts/bottleneck-fixes/wetland-pair.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("WETLAND CACHE PROFILE ",JSON.stringify(report))
	quit(0 if report.equivalent and not report.source_drift else 1)
