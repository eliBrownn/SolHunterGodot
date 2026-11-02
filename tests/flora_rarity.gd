extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func definition(at: Vector2i) -> Dictionary:
 return {"id":FloraCatalog.id_for(at),"cell":[at.x,at.y],"kind":"plant"}
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var legacy_only: Dictionary={}
 for seed_value in [7,19,2601026]:
  var count:=0
  var total:=0
  var patches: Dictionary={}
  var classes: Dictionary={}
  for y in range(-192,192,2):
   for x in range(-192,192,2):
    var row:=definition(Vector2i(x,y))
    var traits:=FloraTraits.describe(seed_value,row)
    var legacy:=FloraTraits.describe(seed_value,row,25)
    var patch:=Vector2i(WorldTerrain.floor_div(x,16),WorldTerrain.floor_div(y,16))
    if not patches.has(patch): patches[patch]=0
    if traits.role=="receiver":
     count+=1
     patches[patch]+=1
     classes[traits["class"]]=true
     check(traits==legacy,"Retained specialists keep their old class")
    elif legacy.role=="receiver" and seed_value==7: legacy_only=row
    total+=1
  var percent:=count*100.0/total
  check(percent>2.5 and percent<7.5,"Regional specialist share stays near the provisional five percent")
  check(classes.size()==3,"All specialist classes remain possible without quotas")
  check(patches.values().has(0),"Some areas contain no specialists")
  print("Seed %d: %.2f%% specialists; %d empty sampled areas"%[seed_value,percent,patches.values().count(0)])
 var row:=legacy_only
 check(not row.is_empty(),"Fixture includes a plant changed by the new rarity")
 check(FloraTraits.role(7,row,0)=="emanator","Zero specialist chance allows ordinary-only areas")
 var legacy_state:=ExpeditionState.new(7,16,25)
 legacy_state.configure_flora(VastraSettings.new().plant_parameters())
 legacy_state.configure_ecology(VesselSettings.new().parameters())
 legacy_state.admit_flora([row])
 var saved:=legacy_state.snapshot()
 saved.flora.nodes[row.id].energy=37.0
 saved.flora.absorbed=37.0
 saved.erase("flora_specialist_percent")
 var restored:=ExpeditionState.restore(saved,7)
 check(restored!=null,"Existing saves without the rarity field remain readable")
 if restored!=null:
  check(restored.flora_specialist_percent()==25,"Existing saves retain the old population policy")
  check(restored.flora_view()==saved.flora,"Restoration does not alter stored reserves or transfers")
  check(restored.flora_reading(Vector2i(row.cell[0],row.cell[1])).traits.role=="receiver","Existing specialist stays a specialist")
 var current:=ExpeditionState.new(7,16,2)
 var again:=ExpeditionState.restore(current.snapshot(),7)
 check(again!=null and again.flora_specialist_percent()==2,"New expedition rarity survives save/load")
 for invalid in [-1,26,1.5,"5"]:
  var broken:=current.snapshot()
  broken.flora_specialist_percent=invalid
  check(not ExpeditionState.valid_snapshot(broken,7),"Invalid saved rarity is rejected")
 var terrain:=WorldTerrain.new(7)
 check(terrain.flora_specialist_percent==5,"New terrain uses the same population default")
 print("FLORA RARITY: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)

