extends SceneTree
## Publish only the explicit owner-approved, unchanged entries in the review registry.
const Draft=preload("res://tools/plant_review_definition.gd")
const DIRECTORY="res://resources/plants/reviewed_baselines"
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var config:=Draft.registry()
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var manifest: Dictionary={"version":1,"definitions":{}}
	if FileAccess.file_exists(DIRECTORY+"/library.json"):
		manifest=JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY+"/library.json"))
	var publish_codes: Array=config.get("publish_codes",config.accepted_codes)
	for code: String in publish_codes:
		var row: Dictionary={}
		for candidate: Dictionary in config.roster:
			if candidate.code==code: row=candidate; break
		if row.is_empty() or not config.accepted_inputs.has(code): push_error("Missing approved input: "+code); quit(1); return
		var approved: Dictionary=config.accepted_inputs[code]
		var approval_revision: String=approved.get("approval_revision",config.revision)
		var publication: Dictionary={"revision":"approved_"+approval_revision,"overrides":{},"resolved_inputs":{code:{"settings":approved.settings,"seed":approved.seed}},"general_foliage_review":false}
		var result:=Draft.draft(row,publication)
		var item: Resource=result.definition
		var source: Resource=result.source
		item.plant_id=row.plant_id
		item.catalog_design_id=source.catalog_design_id
		item.species_id=source.species_id
		item.enabled_in_world=source.enabled_in_world
		if not item.catalog_design_id.is_empty():
			item.recipe=Draft.Library.Species.get_design(item.catalog_design_id).baseline_recipe.duplicate(true)
		else:
			item.recipe["specimen_seed_override"]=int(approved.seed)
		item.set_meta("review_code",code)
		item.set_meta("review_revision",approval_revision)
		item.set_meta("review_settings",approved.settings)
		if not item.valid(): push_error("Invalid approved definition: "+code); quit(1); return
		var path: String=DIRECTORY+"/"+item.plant_id+".res"
		if ResourceSaver.save(item,path,ResourceSaver.FLAG_COMPRESS)!=OK: push_error("Failed approval save: "+code); quit(1); return
		manifest.definitions[item.plant_id]={"path":path,"code":code,"revision":approval_revision}
	var file:=FileAccess.open(DIRECTORY+"/library.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest,"  "))
	file.close()
	print("PLANT REVIEW PUBLICATION: ",publish_codes.size()," owner-approved baselines")
	quit()
