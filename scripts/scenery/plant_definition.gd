class_name AuthoredPlantDefinition
extends Resource
## Baked, script-free art plus an editable recipe. Saved cell ecology stays separate.
@export var catalog_design_id := ""
@export var species_id := ""
@export var format_version := 1
@export var plant_id := ""
@export var display_name := ""
@export var scene: PackedScene
## Morphology only; does not assign circulation or a specialist ability.
@export_enum("role_form","generic_foliage") var growth_category := "role_form"
@export_range(0,3,1) var biome := 0
@export_enum("emanator","reservoir","receiver") var circulation_role := "emanator"
@export_enum("Small","Medium","Large") var size_class := 1
@export var specialist_class := ""
@export var enabled_in_world := false
@export_range(1,100,1) var frequency_percent := 12
@export_range(0.02,40.0,0.01) var world_height := 0.6
@export_range(0.02,32.0,0.01) var world_width := 1.0
@export var preserve_proportions := true
## Maximum soil-plane burial in world cells, capped at 10% of above-ground height; rebuild applies.
@export_range(0.0,0.2,0.005) var root_burial := 0.06
@export var recipe: Dictionary = {}
@export var organ_anchors: Dictionary = {}
@export var organ_graph: Array[Dictionary] = []

func valid() -> bool:
	if not catalog_design_id.is_empty():
		var catalog=preload("res://scripts/scenery/plant_species_catalog.gd")
		var entry: Dictionary=catalog.get_design(catalog_design_id)
		if entry.is_empty() or species_id!=entry.species_id or not catalog.valid_recipe(recipe,catalog_design_id): return false
		if biome!=int(entry.baseline_recipe.selected_biome)-1 or growth_category!=entry.growth_category or circulation_role!=entry.circulation_role or specialist_class!=entry.specialist_class: return false
		if enabled_in_world and not entry.live_ecology_eligible: return false
		if size_class!=int(recipe.size_class) or preserve_proportions!=recipe.preserve_proportions: return false
		if not is_equal_approx(world_height,float(recipe.world_height)) or not is_equal_approx(world_width,float(recipe.world_width)): return false
	elif not species_id.is_empty(): return false
	if not is_finite(root_burial) or root_burial<0.0 or root_burial>0.2: return false
	if growth_category not in ["role_form","generic_foliage"]: return false
	# Live foliage uses existing emanator cells. Unclassed receiving studies stay drafts.
	if growth_category=="generic_foliage" and (not specialist_class.is_empty() or (enabled_in_world and circulation_role!="emanator")): return false
	if growth_category=="generic_foliage":
		if circulation_role not in ["receiver","emanator"] or int(recipe.get("growth_category",-1))!=1: return false
		if int(recipe.get("foliage_variation",-1)) not in [0,1,2,3,4]: return false
	if format_version!=1 or plant_id.is_empty() or plant_id.length()>80 or display_name.strip_edges().is_empty() or display_name.length()>80 or scene==null: return false
	for character in plant_id:
		if character not in "abcdefghijklmnopqrstuvwxyz0123456789_": return false
	if biome not in [0,1,2,3] or circulation_role not in ["emanator","reservoir","receiver"]: return false
	if specialist_class not in ["","warden","mender","regulator"]: return false
	if circulation_role!="receiver" and not specialist_class.is_empty(): return false
	if enabled_in_world and circulation_role=="receiver" and specialist_class.is_empty(): return false
	if size_class not in [0,1,2]: return false
	if frequency_percent<1 or frequency_percent>100: return false
	if not is_finite(world_height) or world_height<0.02 or world_height>40.0 or not is_finite(world_width) or world_width<0.02 or world_width>32.0: return false
	for key in ["ground","receive","release","crown"]:
		if not organ_anchors.get(key) is Vector3 or not organ_anchors[key].is_finite(): return false
	if int(recipe.get("selected_biome",0)) not in [1,2,3,4] or int(recipe.get("selected_role",0)) not in [1,2,3,4,5,6]: return false
	for key in recipe:
		if not key is String or key.length()>64: return false
		var value: Variant=recipe[key]
		if typeof(value) not in [TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]: return false
		if typeof(value) in [TYPE_INT,TYPE_FLOAT] and not is_finite(float(value)): return false
		if value is String and value.length()>128: return false
	return not recipe.is_empty()

func scale_for(bounds: AABB) -> Vector3:
	var width_scale := world_width/maxf(0.000001,maxf(bounds.size.x,bounds.size.z))
	var height_scale := world_height/maxf(0.000001,bounds.end.y if recipe.get("roots_below_ground",false) else bounds.size.y)
	return Vector3.ONE*minf(width_scale,height_scale) if preserve_proportions else Vector3(width_scale,height_scale,width_scale)

func ground_offset(bounds: AABB) -> Vector3:
	# Older baked assets keep their original mesh-bottom fitting. New recipes
	# explicitly retain the authored soil plane even when roots extend below it.
	if recipe.get("roots_below_ground",false):
		var soil: Vector3=organ_anchors.get("ground",Vector3.ZERO)
		return Vector3(soil.x,0.0,soil.z)
	return Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
