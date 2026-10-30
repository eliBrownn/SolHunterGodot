extends SceneTree
const Library=preload("res://scripts/scenery/plant_library.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	Library.refresh(["res://artifacts/empty-foliage-geography-library.json"])
	var total:=0
	var live_forms: Dictionary={}
	for seed_value in [7,19,2601026]:
		var terrain:=WorldTerrain.new(seed_value,{},load("res://resources/terrain_exploration.tres").parameters())
		var accepted:=0
		var trees:=0
		for y in range(-80,81,5):
			for x in range(-80,81,5):
				var cell:=Vector2i(x,y)
				var data:=terrain.sample(cell)
				var kind:=terrain.flora_kind(cell,data)
				if kind.is_empty(): continue
				var row:=Library.placement(terrain,cell,data,kind,true,0.12,0.65)
				if row.is_empty(): continue
				check(terrain.sample(cell)==data,"Foliage never mutates real generated terrain")
				check(row.flora_id==FloraCatalog.id_for(cell),"Real placement retains canonical membership")
				if kind=="tree": trees+=1
				if row.get("growth_category","")!="generic_foliage": continue
				accepted+=1
				live_forms[Vector2i(int(data.ground),int(row.variation))]=true
				var box: AABB=row.bounds
				var margin:=0.16+maxf(row.transform.basis.x.length(),row.transform.basis.z.length())*0.12
				for at_y in range(floori(box.position.z-margin),ceili(box.end.z+margin)):
					for at_x in range(floori(box.position.x-margin),ceili(box.end.x+margin)):
						var at:=Vector2i(at_x,at_y)
						check(terrain.route_axes(at,1)==0 and not terrain.scenery_reserved(at) and not terrain.is_camp(at) and not terrain.is_landmark(at),"Complete real-world footprint keeps protected access")
		check(accepted>0 and trees>0,"Real seed contains admitted foliage and visible tree bodies")
		total+=accepted
		print("Generated seed %d: %d foliage bodies, %d tree bodies in sparse geographic sample"%[seed_value,accepted,trees])
	check(live_forms.size()==20,"All twenty forms reach actual generated terrain across the review seeds")
	print("FOLIAGE GEOGRAPHY: %d checks, %d failures, %d foliage bodies, %d live forms"%[checks,failures,total,live_forms.size()])
	quit(1 if failures else 0)
