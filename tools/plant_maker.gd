extends "res://tools/plant_biome_role_lab.gd"
## Side-by-side biome authoring; focused selections save one game-ready specimen. The library stores game assets, not lab presets.
const Species=preload("res://scripts/scenery/plant_species_catalog.gd")
const Store = preload("res://tools/plant_maker_store.gd")
const Library = preload("res://scripts/scenery/plant_library.gd")
const FoliageBuilder = preload("res://scripts/scenery/generic_foliage_mesh.gd")
@export_group("Official species")
@export var catalog_design_id := ""
@export var species_id := ""
@export_range(0,2147483646,1) var specimen_seed_override := 0
@export_group("Growth category")
@export_enum("Role forms","Generic foliage") var growth_category := 0
@export_enum("Emanator · live ground cover","Receiver · anatomy draft") var generic_circulation := 1
@export_enum("Variation 1","Variation 2","Variation 3","Variation 4","Variation 5") var foliage_variation := 0
@export var compare_foliage_variations := false
@export_group("Event animation preview")
@export_enum("Idle", "Receiving", "Releasing", "Repairing", "Protecting", "Regulating") var preview_event := 0
@export_range(0.0,2.0,0.1) var preview_animation_strength := 1.0
@export_range(0.5,3.0,0.1) var preview_animation_duration := 1.6
@export_group("Scale comparison")
@export var show_scale_reference := true
@export_range(0.5,3.0,0.1) var reference_height := 1.8
@export_group("World use")
@export_enum("Small","Medium","Large") var size_class := 1
@export_range(0.02,20.0,0.01) var world_height := 1.0
@export_range(0.02,12.0,0.01) var world_width := 1.0
@export var preserve_proportions := true
@export_range(1,100,1) var world_frequency := 12
@export_enum("Warden","Mender","Regulator") var receiver_class := 1
@export var preview_world_size := true
@export_group("Randomizer")
@export_range(0.25,1.0,0.05) var randomization_strength := 0.8
@export var keep_biome := true
@export var keep_role := true
var plant_name := "New plant"
var editing_id := ""
var save_root := "res://resources/plants"
var name_edit := LineEdit.new()
var library_picker := OptionButton.new()
var save_status := Label.new()
var loaded_plants: Array[Resource] = []
var fit_after_rebuild := false
var maker_panel: PanelContainer
var draft_button: Button
var publish_button: Button
var scale_reference := Node3D.new()
var role_dimensions: Dictionary = {}
var biome_palette_variant := -1
var built_selection := Vector2i(-1,-1)
var foliage_picker := OptionButton.new()
var species_picker := OptionButton.new()
var official_species: Array[Dictionary]=[]
var constraining_species:=false

func _init() -> void:
	selected_biome=0
	selected_role=0

func _ready() -> void:
	constrain_species()
	if growth_category==1: selected_role=1 if generic_circulation==0 else 3
	selected_biome=clampi(selected_biome,0,4)
	selected_role=clampi(selected_role,0,6)
	super._ready()
	if fit_after_rebuild: refit_after_rebuild.call_deferred()

func sample_seed(biome: int,role: int) -> int:
	return specimen_seed_override if specimen_seed_override>0 else super.sample_seed(biome,role)

func constrain_species() -> void:
	if catalog_design_id.is_empty() or constraining_species: return
	constraining_species=true
	var limited:=Species.constrain(recipe_values(),catalog_design_id)
	for key in limited:
		if get(key)!=limited[key]: set(key,limited[key]); remember(key,limited[key])
	constraining_species=false

func load_species(id: String) -> void:
	var entry:=Species.get_design(id)
	if entry.is_empty(): save_status.text="This official preset is unavailable."; return
	for index in range(official_species.size()):
		if official_species[index].design_id==id: species_picker.select(index); break
	var allowed:=recipe_values()
	for key in entry.baseline_recipe:
		if allowed.has(key): set(key,entry.baseline_recipe[key]); remember(key,get(key))
	editing_id=""
	plant_name=entry.display_name
	remember("plant_name",plant_name)
	remember("editing_id",editing_id)
	rebuild_maker()
	save_status.text="Official baseline loaded as a new copy. Randomize stays inside this species' limits."
	if not entry.live_ecology_eligible: save_status.text+="\nVisual approval is complete; a live Receiver class is still unassigned."

func detach_species() -> void:
	catalog_design_id=""
	species_id=""
	editing_id=""
	for key in ["catalog_design_id","species_id","editing_id"]: remember(key,get(key))
	rebuild_maker()
	save_status.text="Free customization: a new design. The approved preset stays unchanged."

func create_builder():
	return FoliageBuilder.new() if growth_category==1 else AnatomyBuilder.new()

func generation_settings() -> Dictionary:
	var settings := super.generation_settings()
	settings["foliage_variation"] = foliage_variation
	settings["biome_palette_variant"] = biome_palette_variant
	return settings

func workstation_reframe_on_change(key: String) -> bool:
	return key in ["world_height","world_width","preserve_proportions","preview_world_size","height_ratio","spread_ratio","plant_size","leaf_size"]

func refit_after_rebuild() -> void:
	var host:=get_parent()
	while host!=null and not host.has_method("load_fixture"): host=host.get_parent()
	if host!=null and host.station_tools!=null: host.station_tools.reset_view()
	refresh_view()
	if host!=null: host.default_camera=host.camera_settings()

func workstation_context() -> Dictionary:
	var context := super.workstation_context()
	context.merge({"plant_name":plant_name,"editing_id":editing_id,"save_root":save_root})
	return context

func workstation_restore_context(context: Dictionary) -> void:
	super.workstation_restore_context(context)
	plant_name=str(context.get("plant_name",plant_name)).left(80)
	editing_id=str(context.get("editing_id",editing_id))
	save_root=str(context.get("save_root",save_root))
	fit_after_rebuild=bool(context.get("maker_fit_view",false))

func build_bed(biome: int) -> void:
	constrain_species()
	if biome>=4 or (selected_biome>0 and biome!=selected_biome-1): return
	built_selection=Vector2i(selected_biome,selected_role)
	var foliage_role := 0 if generic_circulation==0 else 2
	var roles: Array=([foliage_role] if growth_category==1 else (range(6) if selected_role==0 else [selected_role-1]))
	if growth_category==1 and compare_foliage_variations: roles=[foliage_role,foliage_role,foliage_role,foliage_role,foliage_role]
	var selected_variation := foliage_variation
	var variation_index := 0
	for role: int in roles:
		if growth_category==1 and compare_foliage_variations: foliage_variation=variation_index
		build_sample(biome,role)
		var bed: Dictionary=beds.back()
		if growth_category==1: bed["variation"]=foliage_variation
		variation_index+=1
		if preview_world_size:
			var bounds: AABB=bed.bounds
			var dimensions := preload("res://scripts/scenery/plant_definition.gd").new()
			dimensions.recipe={"roots_below_ground":true}
			dimensions.world_height=class_height(role) if selected_role==0 else world_height
			dimensions.world_width=dimensions.world_height*(0.9 if role==1 else 1.4) if selected_role==0 else world_width
			dimensions.preserve_proportions=preserve_proportions
			var size_scale: Vector3=dimensions.scale_for(bounds)
			bed.node.find_child("OuterGrowth",true,false).get_parent().scale=size_scale
			bed.bounds=AABB(bounds.position*size_scale/maxf(0.000001,plant_size),bounds.size*size_scale/maxf(0.000001,plant_size))
		var ground: MeshInstance3D=bed.node.find_child("SampleGround",true,false)
		var bounds: AABB=bed.bounds
		var radius:=maxf(0.02,maxf(bounds.size.x,bounds.size.z)*plant_size*0.65)
		ground.scale=Vector3(radius/1.25,clampf(radius,0.01,1.0),radius/1.25)
		ground.position.y=-0.08*ground.scale.y
		for child in bed.node.get_children():
			if child is Label3D: child.visible=selected_biome==0 or selected_role==0
	foliage_variation=selected_variation

func arrange_samples(visible_beds: Array[Dictionary],columns: int,horizontal_gap: float,depth_gap: float) -> void:
	if growth_category!=1:
		super.arrange_samples(visible_beds,columns,horizontal_gap,depth_gap)
		return
	# One row per habitat, five columns per family, at a common world scale.
	var saved_layout := scene_layout
	scene_layout=1
	var count := 5 if compare_foliage_variations else (4 if selected_biome==0 else 1)
	var width := 1.4
	var depth := 2.3
	for bed: Dictionary in visible_beds:
		width=maxf(width,bed.bounds.size.x*plant_size+0.8)
		depth=maxf(depth,bed.bounds.size.z*plant_size+0.9)
	super.arrange_samples(visible_beds,count,width,depth)
	scene_layout=saved_layout
	for bed: Dictionary in visible_beds:
		for child in bed.node.get_children():
			if child is Label3D:
				child.text=AnatomyBuilder.BIOMES[bed.biome]+"\n"+FoliageBuilder.FORMS[bed.biome][bed.variation]
				child.position=Vector3(0,0.05,maxf(0.15,bed.bounds.end.z*plant_size)+0.30)
				child.pixel_size=0.0035

func review_all_foliage() -> void:
	if not catalog_design_id.is_empty(): detach_species()
	growth_category=1
	compare_foliage_variations=true
	selected_biome=0
	selected_role=1 if generic_circulation==0 else 3
	for key in ["growth_category","compare_foliage_variations","selected_biome","selected_role"]: remember(key,get(key))
	rebuild_maker()

func update_camera() -> void:
	super.update_camera()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL if show_scale_reference else Camera3D.PROJECTION_PERSPECTIVE
	if show_scale_reference: camera.size=maxf(0.05,distance_value*2.0*tan(deg_to_rad(camera.fov*0.5)))

func class_height(role: int) -> float:
	return [4.0,6.5,10.0][size_class] if role==1 else [0.17,0.55,1.3][size_class]

func extend_frame_bounds(bounds: AABB) -> AABB:
	bounds=super.extend_frame_bounds(bounds)
	if scale_reference.get_parent()==null:
		scale_reference.name="ScaleReference"
		add_child(scale_reference)
	for child in scale_reference.get_children(): child.free()
	scale_reference.visible=show_scale_reference
	if not show_scale_reference: return bounds
	var height:=maxf(2.0,ceilf(bounds.end.y))
	var reference_z:=0.0
	var reference_count:=0
	for bed: Dictionary in beds:
		if bed.node.visible and bed.role_index==1:
			reference_z+=bed.node.position.z
			reference_count+=1
	if reference_count==0: reference_z=bounds.get_center().z
	else: reference_z/=reference_count
	var origin:=Vector3(bounds.position.x-0.9,0,reference_z)
	scale_reference.position=origin
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color("b5af9e")
	material.roughness=1.0
	# Neutral standing figure: a size marker, never living scenery or Vastra.
	var body:=CapsuleMesh.new()
	body.radius=reference_height*0.1
	body.height=reference_height*0.48
	add_scale_mesh(body,Vector3(0,reference_height*0.58,0),material)
	var head:=SphereMesh.new()
	head.radius=reference_height*0.075
	head.height=head.radius*2.0
	add_scale_mesh(head,Vector3(0,reference_height-head.radius,0),material)
	for side in [-1,1]:
		var leg:=CylinderMesh.new()
		leg.top_radius=reference_height*0.04
		leg.bottom_radius=leg.top_radius
		leg.height=reference_height*0.38
		add_scale_mesh(leg,Vector3(side*reference_height*0.055,leg.height*0.5,0),material)
		var arm:=CapsuleMesh.new()
		arm.radius=reference_height*0.032
		arm.height=reference_height*0.34
		add_scale_mesh(arm,Vector3(side*reference_height*0.14,reference_height*0.59,0),material)
	var lines:=ImmediateMesh.new()
	var ink:=StandardMaterial3D.new()
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color=Color("e0cc97")
	lines.surface_begin(Mesh.PRIMITIVE_LINES,ink)
	lines.surface_add_vertex(Vector3(-0.5,0,0))
	lines.surface_add_vertex(Vector3(-0.5,height,0))
	for step in range(int(height)+1):
		lines.surface_add_vertex(Vector3(-0.62,step,0))
		lines.surface_add_vertex(Vector3(-0.38,step,0))
		var label:=Label3D.new()
		label.text=str(step)
		label.position=Vector3(-0.85,step,0)
		label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size=32
		label.pixel_size=0.009
		scale_reference.add_child(label)
	lines.surface_end()
	add_scale_mesh(lines,Vector3.ZERO,ink)
	var caption:=Label3D.new()
	caption.text=("%.1f-unit reference" if growth_category==1 else "WORLD UNITS\n%.1f-unit figure")%reference_height
	caption.position=Vector3(0,-0.7,0)
	caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	caption.font_size=32
	caption.pixel_size=0.004 if growth_category==1 else 0.009
	scale_reference.add_child(caption)
	return bounds.merge(AABB(origin+Vector3(-1.2,-1.0,-0.25),Vector3(1.7,height+1.3,0.5)))

func add_scale_mesh(mesh: Mesh,at: Vector3,material: Material) -> void:
	var instance:=MeshInstance3D.new()
	instance.mesh=mesh
	instance.material_override=material
	instance.position=at
	scale_reference.add_child(instance)

func frame_ground_radius() -> float:
	var radius := 0.02
	for bed: Dictionary in beds:
		var bounds: AABB=bed.bounds
		radius=maxf(radius,maxf(bounds.size.x,bounds.size.z)*plant_size*0.65)
	return radius

func rebuild_geometry() -> void:
	for child in samples.get_children(): child.free()
	beds.clear()
	specimens.clear()
	for biome in range(4): build_bed(biome)

func build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var frame := PanelContainer.new()
	maker_panel=frame
	frame.position = Vector2(12,12)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("182c31")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(side,10)
	frame.add_theme_stylebox_override("panel",style)
	layer.add_child(frame)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 300
	frame.add_child(box)
	var title := Label.new()
	title.text = "PLANT EDITOR & LIBRARY"
	title.add_theme_font_size_override("font_size",19)
	box.add_child(title)
	var help := Label.new()
	help.text = "Compare biomes, then focus a plant to save.\nChanges apply to every visible preview."
	box.add_child(help)
	var official_title:=Label.new()
	official_title.text="OFFICIAL SPECIES PRESETS"
	box.add_child(official_title)
	species_picker.name="OfficialSpeciesPreset"
	official_species=Species.all()
	for entry: Dictionary in official_species:
		species_picker.add_item(entry.biome.capitalize()+" · "+entry.display_name)
		if entry.design_id==catalog_design_id: species_picker.select(species_picker.item_count-1)
	box.add_child(species_picker)
	maker_button(box,"Load official baseline",func():
		if species_picker.selected>=0: load_species(official_species[species_picker.selected].design_id))
	maker_button(box,"Customize freely as new design",detach_species)
	var quick_actions := HBoxContainer.new()
	box.add_child(quick_actions)
	var random_button := maker_button(quick_actions,"Randomize",func(): randomize_plant())
	random_button.name="QuickRandomize"
	random_button.tooltip_text="Make a new candidate. Saved official plants stay unchanged."
	publish_button=maker_button(quick_actions,"Lock as official",func(): save_current(true))
	publish_button.name="LockOfficialPlant"
	maker_button(box,"All plant designs",func():
		if not catalog_design_id.is_empty(): detach_species()
		scene_layout=2
		remember("scene_layout",scene_layout)
		biome_picker.select(0)
		role_picker.select(0)
		if growth_category==1:
			compare_foliage_variations=true
			remember("compare_foliage_variations",true)
			rebuild_geometry()
		refresh_view()
		refresh_parameter_dock())
	var foliage_review := maker_button(box,"Review all 20 foliage designs",review_all_foliage)
	foliage_review.name="ReviewAllFoliage"
	maker_button(box,"Natural biome mix",func():
		if not catalog_design_id.is_empty(): detach_species()
		scene_layout=0
		remember("scene_layout",scene_layout)
		biome_picker.select(0)
		role_picker.select(0)
		refresh_view()
		refresh_parameter_dock())
	biome_picker.name="Biome"
	role_picker.name="CirculationRoleAndClass"
	biome_picker.add_item("All biomes · side by side")
	for biome in AnatomyBuilder.BIOMES: biome_picker.add_item(biome)
	biome_picker.select(selected_biome)
	box.add_child(biome_picker)
	role_picker.add_item("All plant forms")
	for role in AnatomyBuilder.ROLES: role_picker.add_item(role)
	role_picker.select(selected_role)
	box.add_child(role_picker)
	foliage_picker.name="FoliageVariation"
	box.add_child(foliage_picker)
	foliage_picker.item_selected.connect(func(index: int):
		compare_foliage_variations=index==0
		if index>0: foliage_variation=index-1
		remember("compare_foliage_variations",compare_foliage_variations)
		remember("foliage_variation",foliage_variation)
		rebuild_maker())
	biome_picker.item_selected.connect(func(_index: int): refresh_view())
	role_picker.item_selected.connect(func(_index: int): refresh_view(); refresh_parameter_dock())
	name_edit.name = "PlantName"
	name_edit.placeholder_text = "Name your plant"
	name_edit.max_length = 80
	name_edit.text = plant_name
	box.add_child(name_edit)
	var classes := OptionButton.new()
	for class_title in ["Small plants", "Medium plants", "Large plants"]: classes.add_item(class_title)
	classes.disabled=not catalog_design_id.is_empty()
	classes.name="SizeClassPicker"
	classes.select(size_class)
	box.add_child(classes)
	classes.item_selected.connect(apply_size_class)
	var sizes := OptionButton.new()
	sizes.add_item("Size preset…")
	for preset_title in ["Tiny · 0.05","Groundcover · 0.2","Low plant · 0.6","Shrub · 1.5","Small tree · 3.5","Tree · 7","Exceptional · 20"]: sizes.add_item(preset_title)
	box.add_child(sizes)
	sizes.item_selected.connect(func(index: int):
		if index>0: apply_size_preset(index-1))
	name_edit.text_changed.connect(func(value: String): plant_name=value; remember("plant_name",value))
	var locks := HBoxContainer.new()
	box.add_child(locks)
	for key in ["keep_biome","keep_role"]:
		var lock := CheckButton.new()
		lock.text="Keep biome" if key=="keep_biome" else "Keep role"
		lock.button_pressed=get(key)
		lock.toggled.connect(func(enabled: bool): set(key,enabled); remember(key,enabled))
		locks.add_child(lock)
	var location := OptionButton.new()
	location.add_item("Project plant library")
	location.add_item("Personal plant library")
	location.select(0 if save_root.begins_with("res://") else 1)
	box.add_child(location)
	location.item_selected.connect(func(index: int): save_root="res://resources/plants" if index==0 else "user://authored_plants"; remember("save_root",save_root))
	var row := HBoxContainer.new()
	box.add_child(row)
	draft_button=maker_button(row,"Save draft",func(): save_current(false))
	var cut := CheckButton.new()
	cut.name = "Cutaway"
	cut.text = "Inspect anatomy"
	cut.button_pressed = cutaway
	box.add_child(cut)
	cut.toggled.connect(func(enabled: bool):
		cutaway=enabled
		remember("cutaway",enabled)
		for bed in beds: bed.node.find_child("OuterGrowth",true,false).visible=not enabled)
	var silhouette := CheckButton.new()
	silhouette.name="SilhouetteView"
	silhouette.text="Compare silhouettes"
	silhouette.button_pressed=silhouette_view
	box.add_child(silhouette)
	silhouette.toggled.connect(func(enabled: bool):
		silhouette_view=enabled
		remember("silhouette_view",enabled)
		refresh_view())
	var library_title := Label.new()
	library_title.text = "SAVED PLANT LIBRARY"
	box.add_child(library_title)
	library_picker.name = "SavedPlants"
	box.add_child(library_picker)
	row = HBoxContainer.new()
	box.add_child(row)
	maker_button(row,"Load selected",load_selected)
	maker_button(row,"New copy",func(): editing_id=""; plant_name=name_edit.text+" copy"; name_edit.text=plant_name; remember("editing_id",""); remember("plant_name",plant_name); save_status.text="New identity: saving will preserve the original plant.")
	save_status.name = "SaveStatus"
	save_status.custom_minimum_size.x = 300
	save_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status.text = "Randomize a candidate, name it, then Lock as official to save it for the world. Saved plants survive every roll."
	box.add_child(save_status)
	box.add_child(anatomy_note)
	refresh_library()
	refresh_view()

func workstation_dock_controls(parent: Node) -> void:
	# Use the workstation's scrolling editor dock; standalone F6 keeps its panel.
	if is_instance_valid(maker_panel) and maker_panel.get_parent()!=parent:
		maker_panel.get_parent().remove_child(maker_panel)
		parent.add_child(maker_panel)
		maker_panel.position=Vector2.ZERO
		maker_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL

func maker_button(parent: Node,text: String,callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func randomize_plant(random_seed: int = -1) -> void:
	if not catalog_design_id.is_empty():
		var varied:=Species.random_recipe(catalog_design_id,random_seed if random_seed>=0 else Time.get_ticks_usec())
		var allowed:=recipe_values()
		var envelope: Dictionary=Species.get_design(catalog_design_id).variation_limits
		for key in varied:
			if allowed.has(key) and (envelope.fixed.has(key) or envelope.numeric_ranges.has(key) or key=="specimen_seed_override"):
				set(key,varied[key]); remember(key,get(key))
		editing_id=""
		remember("editing_id",editing_id)
		rebuild_maker()
		save_status.text="New variation within the official species limits. The approved baseline is unchanged."
		return
	specimen_seed_override=0
	remember("specimen_seed_override",0)
	# Every roll is a new candidate, never a revision of a saved official design.
	editing_id=""
	remember("editing_id",editing_id)
	var random := RandomNumberGenerator.new()
	random.seed = random_seed if random_seed>=0 else Time.get_ticks_usec()
	var choices := {"height_ratio":[0.5,1.8],"spread_ratio":[0.5,1.6],"branch_rise":[-0.3,0.8],"stem_thickness":[0.6,2.0],"radial_symmetry":[0.0,1.0],"leaf_width":[0.4,1.8],"tip_taper":[0.3,2.3],"lobe_depth":[0.0,0.7],"droop":[0.0,1.2],"thorn_length":[0.0,2.0],"organ_height":[0.5,1.5],"storage_size":[0.5,1.6],"port_radius":[0.5,1.8],"root_reach":[0.5,1.5],"hue_shift":[-180.0,180.0],"height_diversity":[0.0,2.0],"node_spacing":[0.4,1.8],"branch_twist":[-1.0,1.0],"node_bulk":[0.5,2.5],"node_elongation":[0.3,2.5],"leaf_size":[0.5,1.6],"foliage_density":[0.4,1.8],"leaf_curl":[0.0,1.0]}
	for key in choices:
		var endpoints: Array = choices[key]
		var value := lerpf(float(get(key)),random.randf_range(endpoints[0],endpoints[1]),randomization_strength)
		set(key,value)
		remember(key,value)
	for key in ["node_count","branch_count","leaf_lobes","frond_pairs","node_ridges"]:
		var value := random.randi_range(3,10) if key in ["node_count","branch_count","frond_pairs"] else random.randi_range(0,5)
		set(key,value)
		remember(key,value)
	organic_softness=random.randf_range(0.6,1.0)
	remember("organic_softness",organic_softness)
	leaf_architecture=random.randi_range(0,4)
	branch_irregularity=random.randf()
	leaf_asymmetry=random.randf()
	for key in ["leaf_architecture","branch_irregularity","leaf_asymmetry"]: remember(key,get(key))
	color_diversity=1.0
	generation_seed=random.randi_range(1,1000)
	if not keep_biome or selected_biome==0: selected_biome=random.randi_range(1,4)
	if not keep_role or selected_role==0: selected_role=random.randi_range(1,6)
	if growth_category==1:
		selected_role=1 if generic_circulation==0 else 3
		foliage_variation=random.randi_range(0,4)
		remember("foliage_variation",foliage_variation)
	if selected_role==2:
		hue_shift=clampf(hue_shift,-35.0,35.0)
		branch_reach=random.randf_range(1.0,1.6)
		branch_arch=random.randf_range(0.5,1.1)
		tree_fork_depth=2
		node_count=5
		branch_count=6
		branching_depth=1
		foliage_density=1.25
		foliage_fullness=1.5
		for key in ["node_count","branch_count","branching_depth","foliage_density","foliage_fullness"]: remember(key,get(key))
		tree_fork_spread=random.randf_range(0.4,1.0)
		trunk_lean=random.randf_range(-0.12,0.15)
	foliage_palette=random.randi_range(0,6)
	bark_palette=random.randi_range(0,4)
	flower_palette=random.randi_range(0,6)
	color_gradient=random.randf_range(0.25,0.7)
	leaf_tip_gradient=random.randf_range(0.3,0.9)
	for key in ["tree_fork_depth","tree_fork_spread","trunk_lean","hue_shift","branch_reach","branch_arch","foliage_palette","bark_palette","flower_palette","color_gradient","leaf_tip_gradient"]: remember(key,get(key))
	var limits := size_class_range()
	if selected_role==2:
		size_class=random.randi_range(0,2)
		remember("size_class",size_class)
		limits=size_class_range()
	world_height=random.randf_range(limits.x,limits.y)
	world_width=world_height*(0.9 if selected_role==2 else 1.4)
	for key in ["color_diversity","generation_seed","selected_biome","selected_role","world_height","world_width"]: remember(key,get(key))
	biome_picker.select(selected_biome)
	role_picker.select(selected_role)
	remember("maker_fit_view",true)
	rebuild_maker()

# Physical size is independent of circulation role and Receiver specialty.
func size_class_range() -> Vector2:
	return [Vector2(3.0,5.0),Vector2(5.0,8.0),Vector2(8.0,12.0)][size_class] if selected_role==2 else [Vector2(0.04,0.3),Vector2(0.3,0.8),Vector2(0.8,1.8)][size_class]

func apply_size_class(index: int) -> void:
	size_class=clampi(index,0,2)
	var limits := size_class_range()
	world_height=(limits.x+limits.y)*0.5
	world_width=world_height*(0.9 if selected_role==2 else 1.4)
	for key in ["size_class","world_height","world_width"]: remember(key,get(key))
	remember("maker_fit_view",true)
	rebuild_maker()

func apply_size_preset(index: int) -> void:
	world_height=[0.05,0.2,0.6,1.5,3.5,7.0,20.0][clampi(index,0,6)]
	var source: MeshInstance3D=beds[0].node.find_child("OuterGrowth",true,false)
	var box: AABB=source.mesh.get_aabb()
	var natural_width:=world_height*maxf(box.size.x,box.size.z)/maxf(0.000001,box.size.y)
	world_width=clampf(natural_width,0.02,12.0)
	preserve_proportions=natural_width<=12.0 and natural_width>=0.02
	for key in ["world_height","world_width","preserve_proportions"]: remember(key,get(key))
	remember("maker_fit_view",true)
	rebuild_maker()

func refresh_parameter_dock() -> void:
	var host := get_parent()
	while host!=null and not host.has_method("load_fixture"): host=host.get_parent()
	if host!=null: host.build_parameters.call_deferred()

func rebuild_maker() -> void:
	constrain_species()
	# Keep the editor alive while randomizing/loading; do not destroy its controls
	# from a pending button callback during a whole-workstation reload.
	biome_picker.select(selected_biome)
	role_picker.select(selected_role)
	name_edit.text=plant_name
	var classes := maker_panel.find_child("SizeClassPicker",true,false) as OptionButton
	if classes!=null:
		classes.select(size_class)
		classes.disabled=not catalog_design_id.is_empty()
	var cut := maker_panel.find_child("Cutaway",true,false) as CheckButton
	if cut!=null: cut.set_pressed_no_signal(cutaway)
	var silhouette := maker_panel.find_child("SilhouetteView",true,false) as CheckButton
	if silhouette!=null: silhouette.set_pressed_no_signal(silhouette_view)
	rebuild_geometry()
	refresh_view()
	refit_after_rebuild()
	var host := get_parent()
	while host!=null and not host.has_method("load_fixture"): host=host.get_parent()
	if host!=null: host.build_parameters.call_deferred()

func refresh_view() -> void:
	if not catalog_design_id.is_empty():
		constrain_species()
		biome_picker.select(selected_biome)
		role_picker.select(selected_role)
	if biome_picker.selected<0 or role_picker.selected<0: return
	var previous_role := selected_role
	if previous_role>0: role_dimensions[previous_role]=Vector2(world_height,world_width)
	selected_biome=biome_picker.selected
	selected_role=role_picker.selected
	role_picker.disabled=growth_category==1 or not catalog_design_id.is_empty()
	biome_picker.disabled=not catalog_design_id.is_empty()
	foliage_picker.disabled=not catalog_design_id.is_empty()
	if growth_category==1:
		selected_role=1 if generic_circulation==0 else 3
		role_picker.select(selected_role)
	if selected_role>0 and selected_role!=previous_role:
		var height:=class_height(selected_role-1)
		var dimensions: Vector2=role_dimensions.get(selected_role,Vector2(height,height*(0.9 if selected_role==2 else 1.4)))
		world_height=dimensions.x
		world_width=dimensions.y
		remember("world_height",world_height)
		remember("world_width",world_width)
	if built_selection!=Vector2i(selected_biome,selected_role): rebuild_geometry()
	super.refresh_view()
	apply_review_materials()
	if growth_category==1 and compare_foliage_variations:
		pitch=0.85
		update_camera()
	if scene_layout==0 and selected_role==0:
		anatomy_note.text="Natural mix: ordinary foliage and occasional specialists.\nSome designs may be absent; All plant designs shows every form."
	elif selected_biome==0 or selected_role==0:
		anatomy_note.text="Editing %d previews at a common scale.\nSize class sets each form’s game height.\nChoose one biome and form to save a plant."%beds.size()
	else:
		anatomy_note.text=AnatomyBuilder.BIOMES[selected_biome-1]+" · "+AnatomyBuilder.ROLES[selected_role-1]
		if selected_role==3: anatomy_note.text += "\nWorld class: "+["Warden","Mender","Regulator"][receiver_class]
	if growth_category==1:
		anatomy_note.text=("Comparing %d foliage designs"%specimens.size() if compare_foliage_variations else "Generic foliage · variation %d/5"%(foliage_variation+1))+("\nEmanating ground cover; shares canonical cells with grass." if generic_circulation==0 else "\nDraft receiving anatomy; no specialist ability or live population.")
		if selected_biome>0 and not compare_foliage_variations: anatomy_note.text=FoliageBuilder.FORMS[selected_biome-1][foliage_variation]+"\n"+anatomy_note.text
	foliage_picker.visible=growth_category==1
	foliage_picker.clear()
	foliage_picker.add_item("All five foliage variations")
	for index in range(5): foliage_picker.add_item(FoliageBuilder.FORMS[selected_biome-1][index] if selected_biome>0 else "Variation %d across biomes"%(index+1))
	foliage_picker.select(0 if compare_foliage_variations else foliage_variation+1)
	var focused := selected_biome>0 and selected_role>0 and specimens.size()==1
	var species:=Species.get_design(catalog_design_id)
	if not species.is_empty(): anatomy_note.text+="\nSpecies: "+species.display_name+" · bounded variation"
	for button: Button in [draft_button,publish_button]:
		if button!=null:
			button.disabled=not focused
			button.tooltip_text="Save this plant" if focused else "Choose one biome and plant form to save."
	if publish_button!=null and not species.is_empty() and not species.live_ecology_eligible:
		publish_button.disabled=true
		publish_button.tooltip_text="Official visual design; live ecological assignment is still open."
	if growth_category==1 and generic_circulation==1 and publish_button!=null:
		publish_button.disabled=true
		publish_button.tooltip_text="Foliage designs can be saved as drafts. World population integration is a later step."

func apply_review_materials() -> void:
	var ink: StandardMaterial3D
	if silhouette_view:
		ink=StandardMaterial3D.new()
		ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.albedo_color=Color("080d10")
	for child in get_children():
		if child is WorldEnvironment: child.environment.background_color=Color("dce1de") if silhouette_view else Color("202e36")
	for bed: Dictionary in beds:
		if growth_category==1: bed.node.find_child("SampleGround",true,false).visible=not silhouette_view
		for part in ["OuterGrowth","ConnectedVastraAnatomy"]:
			apply_silhouette_material(bed.node.find_child(part,true,false),ink)
		for child in bed.node.get_children():
			if child is Label3D: child.modulate=Color("21353a") if silhouette_view else Color.WHITE

func recipe_values() -> Dictionary:
	var recipe := {"selected_biome":selected_biome,"selected_role":selected_role,"biome_palette_variant":biome_palette_variant}
	for property in get_property_list():
		if int(property.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE and int(property.usage)&PROPERTY_USAGE_EDITOR:
			var value: Variant = get(property.name)
			if typeof(value) in [TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]: recipe[property.name]=value
	return recipe

func save_current(enable: bool) -> Dictionary:
	var result := Store.save_plant(self,name_edit.text,enable,save_root,editing_id)
	if result.has("error"):
		save_status.text = result.error
		return result
	editing_id = result.id
	remember("editing_id",editing_id)
	save_status.text = ("Locked as official and enabled in matching world slots. Randomize to try another plant without changing this one." if enable else "Draft saved. Load it here to keep editing.")+"\nEditable settings and a reusable plant scene are saved."
	refresh_library()
	return result

func refresh_library() -> void:
	library_picker.clear()
	loaded_plants = Library.all()
	for item in loaded_plants:
		library_picker.add_item(item.display_name+(" · official" if item.enabled_in_world else " · draft"))
		if item.plant_id==editing_id: library_picker.select(library_picker.item_count-1)
	if loaded_plants.is_empty(): library_picker.add_item("No saved plants yet")

func load_selected() -> void:
	if loaded_plants.is_empty() or library_picker.selected<0: return
	load_definition(loaded_plants[library_picker.selected])

func load_definition(definition: Resource) -> void:
	if not definition.valid(): save_status.text="This saved plant failed validation."; return
	catalog_design_id=""
	species_id=""
	specimen_seed_override=0
	biome_palette_variant=-1
	# Older recipes predate this category and must not inherit the current mode.
	growth_category=1 if definition.growth_category=="generic_foliage" else 0
	generic_circulation=0 if definition.circulation_role=="emanator" else 1
	remember("generic_circulation",generic_circulation)
	foliage_variation=0
	compare_foliage_variations=false
	remember("growth_category",growth_category)
	remember("foliage_variation",foliage_variation)
	remember("compare_foliage_variations",false)
	var allowed := recipe_values()
	for key in definition.recipe:
		if not allowed.has(key): continue
		set(key,definition.recipe[key])
		remember(key,definition.recipe[key])
	plant_name = definition.display_name
	editing_id = definition.plant_id
	remember("plant_name",plant_name)
	remember("editing_id",editing_id)
	if not definition.resource_path.is_empty():
		save_root=definition.resource_path.get_base_dir().get_base_dir().get_base_dir()
		remember("save_root",save_root)
	remember("maker_fit_view",true)
	rebuild_maker()

func workstation_parameter_info(key: String) -> Dictionary:
	if key in ["catalog_design_id","species_id"]: return {"hidden":true}
	if key=="specimen_seed_override": return {"min":1 if not catalog_design_id.is_empty() else 0,"group":"Official species","label":"Individual seed","help":"Zero uses the ordinary seed sequence. Official presets retain their exact specimen seed; randomization creates a repeatable individual."}
	if not catalog_design_id.is_empty():
		var species:=Species.get_design(catalog_design_id)
		if not species.is_empty():
			if key in species.variation_limits.fixed or key=="generation_seed": return {"hidden":true}
			if species.variation_limits.numeric_ranges.has(key):
				var info: Dictionary=super.workstation_parameter_info(key)
				var limits: Array=species.variation_limits.numeric_ranges[key]
				info.merge({"min":limits[0],"max":limits[1],"help":"Allowed variation for "+species.display_name+": "+str(limits[0])+" to "+str(limits[1])+". Customize freely to create a separate design."},true)
				return info
	if key=="generic_circulation": return {"group":"Growth category","hidden":growth_category!=1,"help":"Live foliage shares existing grass/emanator cells. Receiver anatomy remains draft-only; neither form gains specialist abilities.","order":-59}
	if key in ["foliage_variation","compare_foliage_variations"]: return {"hidden":true}
	if key=="growth_category": return {"group":"Growth category","help":"Generic foliage offers five related forms per biome. Compare all five or focus a named design. Emanators can use live ground-cover slots; receiving studies remain drafts. No specialist class is assigned.","order":-60}
	if growth_category==1 and key in ["receiver_class","world_frequency","preview_event","role_expression"]: return {"hidden":true}
	if key in ["show_scale_reference","reference_height"]: return {"group":"Scale comparison","help":"Show a height ruler in world units and a reference figure. All visible plants share this scale; selecting a form frames it more closely.","order":-25+["show_scale_reference","reference_height"].find(key)}
	if selected_role==0 and key in ["world_height","world_width","preserve_proportions"]: return {"hidden":true}
	if key in ["size_class","keep_biome","keep_role","cutaway","silhouette_view"]: return {"hidden":true}
	if key in ["preview_event","preview_animation_strength","preview_animation_duration"]: return {"group":"Event animation preview","help":"Review a basic plant event response. Preview loops locally; live reactions use committed game events.","order":-40+["preview_event","preview_animation_strength","preview_animation_duration"].find(key)}
	if key in ["randomization_strength","keep_biome","keep_role"]: return {"group":"Randomizer","help":"Control the randomizer. Locked biome/role selections are preserved; saved recipes keep the resulting values.","order":-30+["randomization_strength","keep_biome","keep_role"].find(key)}
	var world := {"size_class":"Physical size category. Use the Small/Medium/Large picker to apply dimensions; the randomizer follows this category.","world_height":"Game height: 0.02–20 world units, for every plant role. With natural proportions enabled, width may further limit the size.","world_width":"Game spread: 0.02–12 world units. Protected paths and terrain still govern whether the footprint fits.","preserve_proportions":"Keep natural proportions while fitting both dimensions. Turn off to set height and spread independently.","world_frequency":"Percent of matching canonical cells considered for this plant. Does not add flora or reserves.","receiver_class":"For the unclassed Receiver base form: choose which existing specialist class should use this design.","preview_world_size":"Preview the fitted game dimensions instead of the raw authoring size."}
	if world.has(key): return {"group":"World use","help":world[key],"label":key.capitalize(),"order":-20+world.keys().find(key),"exponential":key in ["world_height","world_width"]}
	return super.workstation_parameter_info(key)

func _process(delta: float) -> void:
	super._process(delta)
	var kind: String=preload("res://scripts/presentation/plant_animation.gd").KINDS[preview_event]
	var age := fmod(elapsed,preview_animation_duration+0.8)
	var shape := preload("res://scripts/presentation/plant_animation.gd").pose(kind,age,preview_animation_duration,preview_animation_strength)
	for bed: Dictionary in beds:
		var plant: Node3D=bed.node.find_child("OuterGrowth",true,false).get_parent()
		if not plant.has_meta("event_rest"): plant.set_meta("event_rest",plant.transform)
		plant.transform=Transform3D(shape,Vector3.ZERO)*plant.get_meta("event_rest")
