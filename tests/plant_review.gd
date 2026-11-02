extends SceneTree
const Draft=preload("res://tools/plant_review_definition.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error(message)
func signature(sample: Dictionary) -> int:
	var arrays:=[]
	for mesh in [sample.body,sample.anatomy]:
		for surface in range(mesh.get_surface_count()): arrays.append(mesh.surface_get_arrays(surface))
	return hash(arrays)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var config:=Draft.registry()
	var hashes: Dictionary={}
	for path in [Draft.Library.Species.PATH,"res://resources/plants/library.json",Draft.Library.PALETTE_DIRECTORY+"/manifest.json"]: hashes[path]=FileAccess.get_sha256(path)
	var ids: Dictionary={}
	var shapes: Dictionary={}
	var revisions:=0
	for row: Dictionary in config.roster:
		check(not ids.has(row.code),"Review IDs remain unique")
		ids[row.code]=row.plant_id
		if not Draft.revised(row,config): continue
		revisions+=1
		if row.code not in config.selected_codes: continue
		var result:=Draft.draft(row,config)
		check(not result.is_empty(),"Requested revision reconstructs: "+row.code)
		if result.is_empty(): continue
		var item: Resource=result.definition
		check(item.valid() and not item.enabled_in_world and item.catalog_design_id.is_empty(),"Review draft is valid and detached from production admission: "+row.code)
		check(item.biome==result.source.biome and item.circulation_role==result.source.circulation_role and item.specialist_class==result.source.specialist_class,"Revision preserves biome and ecological slot")
		check(result.source!=item and result.source.scene!=item.scene,"Revision builds a separate definition and scene")
		var triangles:=0
		for mesh in [result.sample.body,result.sample.anatomy]:
			check(mesh.get_aabb().size.is_finite(),"Finite review geometry")
			for surface in range(mesh.get_surface_count()): triangles+=mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
		check(triangles<=30000,"Review geometry stays within plant triangle budget: "+row.code+" / "+str(triangles))
		if config.overrides[row.code].get("base","")=="original":
			for key in ["hue_shift","foliage_palette","biome_palette_variant","branches","trunk_curve","trunk_lean","tree_fork_depth"]:
				check(result.settings.get(key)==result.source.recipe.get(key),"Leaf-only revision preserves original color/scaffold: "+row.code+" / "+key)
			check(result.seed==int(result.source.recipe.specimen_seed_override),"Leaf-only revision retains original structural seed")
		if result.settings.get("fern_growth",false):
			check(result.sample.organs.any(func(organ): return organ.kind=="Frond conductor"),"Fern revision builds true fronds rather than relabeling a bush")
		if row.code=="S07":
			for key in ["leaf_width","leaf_architecture","leaf_lobes","lobe_depth","tip_taper","droop","foliage_palette","biome_palette_variant"]:
				check(result.settings.get(key)==result.source.recipe.get(key),"S07 preserves leaf identity: "+key)
			check(is_equal_approx(float(result.settings.leaf_scale),float(result.source.recipe.leaf_size)) and is_equal_approx(float(result.settings.curl),float(result.source.recipe.leaf_curl)),"S07 retains leaf size and curl")
		else: shapes[hash([result.settings.get("leaf_architecture"),result.settings.get("leaf_width"),result.settings.get("tip_taper"),result.settings.get("leaf_lobes")])]=true
		if row.code in ["S07","H33"]:
			check(signature(result.sample)==signature(Draft.draft(row,config).sample),"Review seed reconstructs identical geometry: "+row.code)
	check(shapes.size()>=config.selected_codes.size()-1,"Reviewed candidates have varied leaf morphology")
	check(revisions==config.selected_codes.size() if not config.get("general_foliage_review",true) else revisions>config.selected_codes.size(),"Review scope matches this round")
	for code: String in config.get("accepted_codes",[]):
		var row: Dictionary={}
		for candidate: Dictionary in config.roster:
			if candidate.code==code: row=candidate; break
		var baseline: Resource=Draft.Library.reviewed_definition(row.plant_id)
		check(baseline!=null and baseline.valid(),"Accepted baseline is admitted: "+code)
		if config.status=="owner_approved":
			var baked: Resource=Draft.Library.baked_definition(row.plant_id)
			check(baked!=null and baked.get_meta("review_code","")==code,"Approved plant reaches the fingerprint-verified runtime bake: "+code)
			check(baseline.get_meta("review_revision","")==config.accepted_inputs[code].get("approval_revision","round-01"),"Published baseline retains its actual approval round")
		check(config.status=="owner_approved" or not config.overrides.has(code),"Accepted plants are tracked separately from pending proposals")
	for code in config.selected_codes: check(ids.has(code),"Requested code has a stable registry owner")
	for path in hashes: check(FileAccess.get_sha256(path)==hashes[path],"Reviews leave production authority untouched")
	print("PLANT REVIEW: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
