extends "res://tools/review_cohesive_sample.gd"
const Library=preload("res://scripts/scenery/plant_library.gd")

func foliage_records(core_only: bool = false) -> Dictionary:
	var records: Dictionary={}
	var core := Rect2i(world.cell-Vector2i(8,8),Vector2i(16,16))
	for chunk in scene.solid_root.get_children():
		if not "cosmetic_records" in chunk: continue
		for row: Dictionary in chunk.cosmetic_records:
			if core_only and not core.has_point(row.cell): continue
			if row.get("growth_category","")=="generic_foliage":
				records[str(row.cell)]=hash([row.asset,row.transform,row.bounds,row.flora_id,row.variation])
	return records

func run() -> void:
	output_directory="res://artifacts/foliage-rollout"
	DirAccess.make_dir_recursive_absolute(output_directory)
	Engine.max_fps=60
	root.size=Vector2i(1280,800)
	scene=load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	world=scene.world
	var performance_only := "--performance-only" in OS.get_cmdline_user_args()
	if performance_only:
		output_directory="res://artifacts/foliage-rollout/windowed-performance"
		DirAccess.make_dir_recursive_absolute(output_directory)
		root.mode=Window.MODE_WINDOWED
		root.size=Vector2i(1280,800)
	world.smoke_mode=true
	condition("clear")
	var candidates: Dictionary={}
	var pilot:=Vector2i.ZERO
	for y in range(-96,129,8):
		for x in range(-96,129,8):
			var at:=Vector2i(x,y)
			var ground: int=world.terrain.natural_ground(at)
			if ground not in [0,1,2,3] or not world.terrain.fits(at): continue
			var matching:=0
			var opposite:=0
			for offset in [Vector2i(8,0),Vector2i(-8,0),Vector2i(0,8),Vector2i(0,-8)]:
				var neighbor: int=world.terrain.natural_ground(at+offset)
				matching+=int(neighbor==ground)
				if ground in [0,1] and neighbor==1-ground: opposite+=1
			if not candidates.has(ground) or matching>candidates[ground].score: candidates[ground]={"cell":at,"score":matching}
			if ground==1 and opposite>0: pilot=at
	if pilot==Vector2i.ZERO and candidates.has(1): pilot=candidates[1].cell
	var base: NatureSettings=scene.active_nature.duplicate()
	var rows:=[]
	for biome in range(4):
		if performance_only: continue
		check(candidates.has(biome),"Generated review includes every terrestrial habitat")
		if not candidates.has(biome): continue
		scene.active_nature=base.duplicate()
		scene.nature_settings=scene.active_nature
		await fixture(candidates[biome].cell)
		await settle(60)
		await capture("biome_%d"%biome)
		rows.append({"biome":biome,"cell":str(world.cell),"foliage_bodies":foliage_records().size(),"geometry":geometry_counts()})
	var performance:=[]
	var expected: Dictionary={}
	var coverages: Array=[0.0,0.65,1.0,0.65]
	if performance_only: coverages=[0.0,0.65,0.0,0.65,1.0,0.65]
	for coverage in coverages:
		scene.active_nature=base.duplicate()
		scene.active_nature.foliage_coverage=coverage
		scene.nature_settings=scene.active_nature
		await fixture(pilot)
		await settle(90)
		var records:=foliage_records()
		if coverage==0.65:
			# Peripheral chunks follow the live camera/streaming schedule. Compare
			# the same fixed central cells, rather than unrelated loaded outskirts.
			var core_records := foliage_records(true)
			check(not core_records.is_empty(),"Pilot comparison contains central foliage")
			if expected.is_empty(): expected=core_records
			else: check(core_records==expected,"Returning to the same pilot reconstructs identical central foliage")
		var frames: Dictionary=await measured_frames(120)
		performance.append({"coverage":coverage,"cell":str(world.cell),"bodies":records.size(),"frames":frames,"geometry":geometry_counts(),"build_ms":fixture_build_ms})
		var snapshot: Dictionary=world.persistent_state.snapshot()
		world.rebuild_world()
		check(snapshot==world.persistent_state.snapshot(),"Visual rebuild cannot change saved ecosystem state")
		await capture("pilot_%s"%str(coverage).replace(".","_"))
	report={"seed":world.terrain.world_seed,"viewport":[root.size.x,root.size.y],"driver":RenderingServer.get_current_rendering_driver_name(),"biomes":rows,"pilot":str(pilot),"performance":performance,"failures":failures,"method":"Actual generated world, matched clear-noon camera; 120 paced frames per coverage after settling; presentation fixtures, not player enjoyment or hardware-independent performance acceptance."}
	FileAccess.open(output_directory+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	scene.environment.sky=null
	scene.free()
	print("FOLIAGE WORLD REVIEW: %d habitats, %d performance windows, %d failures"%[rows.size(),performance.size(),failures.size()])
	quit(1 if not failures.is_empty() else 0)
