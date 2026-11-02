extends SceneTree
const Catalog=preload("res://scripts/scenery/plant_species_catalog.gd")
const Store=preload("res://tools/plant_maker_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var settings=preload("res://resources/nature_biomes.tres")
 check(settings.valid() and settings.common_trees.is_empty() and settings.hardy_trees.is_empty() and settings.nonliving_trees.is_empty(),"Active nature resources retire imported tree palettes")
 for path in ["meadow","woodland","heath","marsh","meadow_reviewed","woodland_reviewed"]:
  var biome=load("res://resources/scenery/biomes/"+path+".tres")
  check(biome.valid() and biome.trees.is_empty(),"Every biome resource retires imported trees")
 var invalid_settings=settings.duplicate(true)
 invalid_settings.common_trees.append(settings.rocks[0])
 check(not invalid_settings.valid(),"Retired tree slots cannot be repopulated")
 var entries:=Catalog.all()
 check(entries.size()==45,"Every approved design has an official preset")
 var ids: Dictionary={}
 for entry in entries:
  check(not ids.has(entry.species_id),"Species identity is stable and independent")
  ids[entry.species_id]=true
  check(Catalog.valid_recipe(entry.baseline_recipe,entry.design_id),"The captured baseline is inside its allowed envelope: "+entry.design_id)
  for seed_value in [1,27,913]:
   var varied:=Catalog.random_recipe(entry.design_id,seed_value)
   check(Catalog.valid_recipe(varied,entry.design_id),"Randomizer stays inside the family's envelope")
   check(varied==Catalog.random_recipe(entry.design_id,seed_value),"A seed recreates the same bounded variation")
   check(varied.selected_biome==entry.baseline_recipe.selected_biome and varied.selected_role==entry.baseline_recipe.selected_role,"Variation does not reroll habitat or ecological identity")
 var source:=Catalog.get_design("meadow_crimson_umbrella")
 source.baseline_recipe.world_height=999
 check(Catalog.get_design("meadow_crimson_umbrella").baseline_recipe.world_height!=999,"Callers cannot mutate approved baselines")
 var project_hash:=FileAccess.get_sha256("res://resources/plants/library.json")
 var maker=load("res://scenes/plant_maker.tscn").instantiate()
 root.add_child(maker)
 check(maker.species_picker.item_count==45,"All official presets are selectable in the editor")
 for id in ["meadow_open_fan","woodland_blue_twin_arch","marsh_cyan_trumpets","meadow_new_plant"]:
  maker.load_species(id)
  check(maker.specimens.size()==1 and maker.editing_id.is_empty(),"Loading an approved design creates a focused independent copy")
  check(Catalog.valid_recipe(maker.recipe_values(),id),"Editor restores the exact preset fields")
  check(maker.specimens[0].seed==maker.specimen_seed_override,"Catalog specimen seed reaches real geometry")
 maker.load_species("woodland_blue_twin_arch")
 maker.randomize_plant(55)
 var preview_triangles:=0
 for mesh_name in ["OuterGrowth","ConnectedVastraAnatomy"]: preview_triangles+=Store.triangle_count(maker.beds[0].node.find_child(mesh_name,true,false).mesh)
 maker.world_height=999
 maker.selected_biome=4
 maker.rebuild_maker()
 check(Catalog.valid_recipe(maker.recipe_values(),maker.catalog_design_id),"Manual geometry edits are constrained to the species")
 check(maker.selected_biome==2,"Manual edits cannot switch a bounded species' habitat")
 maker.save_root="res://artifacts/official-plants/test_%d"%Time.get_ticks_usec()
 var saved: Dictionary=maker.save_current(false)
 check(not saved.has("error"),"A bounded candidate saves through the normal asset flow: "+str(saved.get("error","")))
 if not saved.has("error"):
  var definition=ResourceLoader.load(saved.path,"",ResourceLoader.CACHE_MODE_IGNORE)
  var runtime_parts: Dictionary=preload("res://scripts/scenery/nature_art.gd").parts(definition.scene)
  check(runtime_parts.triangles<=30000,"Species export retains the runtime budget")
  var unchanged:=0
  for mesh_name in ["OuterGrowth","ConnectedVastraAnatomy"]: unchanged+=Store.triangle_count(maker.beds[0].node.find_child(mesh_name,true,false).mesh)
  check(unchanged==preview_triangles,"Export detail never changes the authoring specimen")
  check(definition.valid() and definition.species_id==maker.species_id,"Saved assets preserve validated species identity")
  maker.detach_species()
  maker.load_definition(definition)
  check(maker.specimen_seed_override==definition.recipe.specimen_seed_override,"Reload retains the individual's exact seed")
  var invalid=definition.duplicate(true)
  invalid.recipe.world_height=999
  check(not invalid.valid(),"Out-of-family saved recipes fail admission")
  var invalid_size=definition.duplicate(true)
  invalid_size.world_height=definition.world_height+0.1
  check(not invalid_size.valid(),"Published dimensions must match the bounded species recipe")
  var before: Dictionary=maker.recipe_values()
  maker.load_definition(invalid)
  check(maker.recipe_values()==before,"A rejected library file cannot detach the current species")
 maker.load_species("marsh_cyan_trumpets")
 check(maker.publish_button.disabled,"Official unclassed Receiver visuals do not acquire a live class")
 check(Store.save_plant(maker,"Unassigned",true,maker.save_root).has("error"),"Store prevents accidental publication of unassigned anatomy")
 var draft: Dictionary=maker.save_current(false)
 check(not draft.has("error") and draft.definition.specialist_class.is_empty(),"Unassigned Receiver anatomy remains a valid class-free draft")
 maker.detach_species()
 maker.world_height=15.0
 maker.rebuild_maker()
 check(maker.catalog_design_id.is_empty() and maker.editing_id.is_empty() and maker.world_height==15.0,"Free customization detaches the family and starts a new identity")
 check(FileAccess.get_sha256("res://resources/plants/library.json")==project_hash,"Preset and randomizer journeys never replace the real project library")
 maker.free()
 print("PLANT SPECIES: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
