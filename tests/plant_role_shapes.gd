extends SceneTree
const Maker=preload("res://tools/plant_maker.gd")
const Store=preload("res://tools/plant_maker_store.gd")
var failures:=0
func check(ok: bool,message: String) -> void:
 if not ok:
  failures+=1
  push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var maker=Maker.new()
 maker.selected_biome=1
 root.add_child(maker)
 maker.selected_role=2
 maker.role_picker.select(2)
 maker.refresh_view()
 for category in range(3):
  maker.size_class=category
  var limits: Vector2=maker.size_class_range()
  check(limits.x<limits.y and limits.y<=12,"Tree class has bounded ordinary heights")
 maker.size_class=2
 maker.bark_palette=3
 maker.foliage_palette=4
 maker.flower_palette=2
 maker.color_gradient=0.7
 maker.world_height=6
 maker.world_width=4
 var saved: Dictionary=Store.save_plant(maker,"Role tree",false,"res://artifacts/plant-prototype/role-test")
 check(not saved.has("error"),"Role tree saves")
 if not saved.has("error"):
  var restored=ResourceLoader.load(saved.path,"",ResourceLoader.CACHE_MODE_IGNORE)
  check(restored.size_class==2 and restored.recipe.size_class==2,"Size class persists in asset and recipe")
  check(restored.recipe.bark_palette==3 and restored.recipe.foliage_palette==4 and restored.recipe.flower_palette==2 and restored.recipe.color_gradient==0.7,"Separate color assignments and gradient persist")
  check(restored.circulation_role=="reservoir","Physical class does not change circulation role")
 maker.free()
 print("PLANT ROLE SHAPES: %d failures"%failures)
 quit(1 if failures else 0)
