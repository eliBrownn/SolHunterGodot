extends "res://tools/procedural_plant_lab.gd"
## Four habitats x three circulation roles, with three specialist receiver classes.
const AnatomyBuilder = preload("res://scripts/scenery/plant_vastra_anatomy_mesh.gd")
@export_group("Growth diversity")
@export_range(0,3,1) var branching_depth := 2
@export_range(0.2,1.3,0.05) var branching_spread := 0.75
@export_range(0.4,0.75,0.05) var branching_reduction := 0.62
@export_group("Foliage")
@export_range(0.0,2.0,0.1) var foliage_fullness := 1.0
@export_range(0.0,1.5,0.05) var role_expression := 1.0
@export_range(0.0,1.0,0.05) var organic_softness := 0.9
@export_enum("Habitat default", "Broad fans", "Divided fronds", "Succulent scales", "Long ribbons") var leaf_architecture := 0
@export_range(0.0,1.0,0.05) var branch_irregularity := 0.0
@export_range(0.0,1.0,0.05) var leaf_asymmetry := 0.0
@export_group("Color assignments")
@export_enum("Habitat", "Leaf green", "Spring green", "Deep green", "Sage", "Autumn gold", "Copper red") var foliage_palette := 0
@export_enum("Habitat", "Brown", "Weathered gray", "Redwood", "Pale birch") var bark_palette := 0
@export_enum("Habitat", "Cream", "Gold", "Rose", "Lavender", "Apricot", "White") var flower_palette := 0
@export_range(0.0,1.0,0.05) var color_gradient := 0.45
@export_range(0.0,1.0,0.05) var leaf_tip_gradient := 0.65
@export_range(0.6,2.0,0.05) var branch_reach := 1.65
@export_range(0.0,1.3,0.05) var branch_arch := 0.8
@export_group("Extreme variety")
@export_range(0.0,1.0,0.05) var color_diversity := 0.0
@export_range(-180,180,5) var hue_shift := 0.0
@export_range(0.0,2.0,0.1) var height_diversity := 1.0
@export_range(3,16,1) var node_count := 8
@export_range(0.4,1.8,0.05) var node_spacing := 1.0
@export_range(-1.0,1.0,0.05) var branch_twist := 0.0
@export_range(0.5,2.5,0.1) var node_bulk := 1.0
@export_range(0.3,2.5,0.1) var node_elongation := 1.0
@export_range(0,6,1) var node_ridges := 3
@export_group("Tree structure")
@export var tree_leaf_cards := true
@export_range(0,2,1) var tree_fork_depth := 2
@export_range(0.25,1.2,0.05) var tree_fork_spread := 0.95
@export_range(-0.25,0.25,0.01) var trunk_lean := 0.08
@export_group("Plant structure")
@export_range(0.05,12.0,0.05) var height_ratio := 1.0
@export_range(0.05,12.0,0.05) var spread_ratio := 1.0
@export_range(-0.3,0.8,0.05) var branch_rise := 0.3
@export_range(0.6,2.0,0.1) var stem_thickness := 1.0
@export_range(0.0,1.0,0.05) var radial_symmetry := 0.55
@export_group("Leaf shape")
@export_range(0.4,1.8,0.05) var leaf_width := 1.0
@export_range(0.3,2.3,0.05) var tip_taper := 0.75
@export_range(0,5,1) var leaf_lobes := 3
@export_range(0.0,0.7,0.05) var lobe_depth := 0.25
@export_range(0.0,1.2,0.05) var droop := 0.55
@export_range(3,12,1) var frond_pairs := 6
@export_range(0.0,2.0,0.1) var thorn_length := 1.0
@export_group("Vastra anatomy")
@export_range(0.6, 2.0, 0.1) var anatomy_thickness := 1.2
@export_range(0.5,1.5,0.05) var organ_height := 1.0
@export_range(0.5,1.6,0.05) var storage_size := 1.0
@export_range(0.5,1.8,0.05) var port_radius := 1.0
@export_range(0.5,1.5,0.05) var root_reach := 1.0
@export_group("Review")
@export_enum("Natural biome mix","Plant grid","All-design biome scenes") var scene_layout := 0
@export_range(0,32,1) var common_foliage_samples := 18
@export_range(0,25,1) var preview_specialist_percent := 5
@export var cutaway := false
@export var anatomy_labels := true
@export var silhouette_view := false
const SHAPE_DEFAULTS := {"height_ratio":1.0,"spread_ratio":1.0,"branch_rise":0.3,"stem_thickness":1.0,"radial_symmetry":0.55,"leaf_width":1.0,"tip_taper":0.75,"leaf_lobes":3,"lobe_depth":0.25,"droop":0.55,"frond_pairs":6,"thorn_length":1.0,"anatomy_thickness":1.2,"organ_height":1.0,"storage_size":1.0,"port_radius":1.0,"root_reach":1.0,"branch_count":8,"plant_size":1.0,"leaf_size":1.0,"foliage_density":1.0,"leaf_curl":0.35}
var biome_picker := OptionButton.new()
var role_picker := OptionButton.new()
var anatomy_note := Label.new()
var beds: Array[Dictionary] = []
var selected_biome := 0
var selected_role := 0
var common_preview_materials: Dictionary={}
var biome_stages := Node3D.new()
var biome_scene_bounds := AABB()
var view_target := Vector3(0,0.55,0)
const VARIETY_DEFAULTS := {"branching_depth":2,"branching_spread":0.75,"branching_reduction":0.62,"foliage_fullness":1.0,"organic_softness":0.7,"leaf_architecture":0,"branch_irregularity":0.0,"leaf_asymmetry":0.0,"color_diversity":0.0,"hue_shift":0.0,"height_diversity":1.0,"node_count":8,"node_spacing":1.0,"branch_twist":0.0,"node_bulk":1.0,"node_elongation":1.0,"node_ridges":3}
const PARAMETER_ORDER := ["foliage_palette","bark_palette","flower_palette","color_gradient","leaf_tip_gradient","branch_reach","branch_arch","color_diversity","hue_shift","height_diversity","node_count","node_spacing","branch_twist","node_bulk","node_elongation","node_ridges","height_ratio","spread_ratio","branch_rise","stem_thickness","radial_symmetry","leaf_width","tip_taper","leaf_lobes","lobe_depth","droop","frond_pairs","thorn_length","anatomy_thickness","organ_height","storage_size","port_radius","root_reach","generation_seed","branch_count","plant_size","leaf_size","foliage_density","leaf_curl","wind_strength","cutaway","anatomy_labels","silhouette_view","show_labels"]

func _ready() -> void:
	# The base form selector is replaced by independent biome/role selectors.
	family_picker.free()
	distance_value = 22.0
	pitch = 0.48
	yaw = 0.10
	super._ready()
	if silhouette_view:
		for child in get_children():
			if child is WorldEnvironment: child.environment.background_color = Color("dce1de")
		var ink := StandardMaterial3D.new()
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.albedo_color = Color("080d10")
		for bed in beds:
			apply_silhouette_material(bed.node.find_child("OuterGrowth",true,false),ink)
			apply_silhouette_material(bed.node.find_child("ConnectedVastraAnatomy",true,false),ink)

static func apply_silhouette_material(instance: MeshInstance3D, ink: Material) -> void:
	var has_cards := false
	for surface in range(instance.mesh.get_surface_count()):
		var material: Material=instance.mesh.surface_get_material(surface)
		if material is ShaderMaterial and material.shader.resource_path.ends_with("tree_leaf_cards.gdshader"): has_cards=true
	instance.material_override=null if has_cards else ink
	for surface in range(instance.mesh.get_surface_count()):
		var material: Material=instance.mesh.surface_get_material(surface)
		var replacement: Material=ink
		if ink!=null and material is ShaderMaterial and material.shader.resource_path.ends_with("tree_leaf_cards.gdshader"):
			replacement=material.duplicate()
			replacement.set_shader_parameter("silhouette_view",true)
		instance.set_surface_override_material(surface,replacement if has_cards else null)

func generation_settings() -> Dictionary:
	var result := {"tree_fork_depth":tree_fork_depth,"tree_fork_spread":tree_fork_spread,"trunk_lean":trunk_lean,"foliage_palette":foliage_palette,"bark_palette":bark_palette,"flower_palette":flower_palette,"color_gradient":color_gradient,"leaf_tip_gradient":leaf_tip_gradient,"branch_reach":branch_reach,"branch_arch":branch_arch,"role_expression":role_expression,"organic_softness":organic_softness,"leaf_architecture":leaf_architecture,"branch_irregularity":branch_irregularity,"leaf_asymmetry":leaf_asymmetry,"branches":branch_count,"leaf_scale":leaf_size,"foliage":foliage_density,"curl":leaf_curl,"anatomy_scale":anatomy_thickness}
	result["tree_leaf_cards"]=tree_leaf_cards
	for key in VARIETY_DEFAULTS: result[key] = get(key)
	for key in SHAPE_DEFAULTS:
		if key in ["branch_count","plant_size","leaf_size","foliage_density","leaf_curl","anatomy_thickness"]: continue
		result[key] = get(key)
	return result

func workstation_context() -> Dictionary:
	return {"selected_biome":selected_biome,"selected_role":selected_role}

func workstation_restore_context(context: Dictionary) -> void:
	selected_biome=clampi(int(context.get("selected_biome",selected_biome)),0,4)
	selected_role=clampi(int(context.get("selected_role",selected_role)),0,6)

func workstation_parameter_info(key: String) -> Dictionary:
	var info := {
		"scene_layout":["View","Natural mix allows empty/sparse specialist areas. All-design scenes and Plant grid keep every reference form available."],
		"common_foliage_samples":["View","Potential ordinary plants in the natural preview. Seeded placement may leave gaps; this does not change the expedition."],
		"preview_specialist_percent":["View","Provisional specialist share for natural previews only. Actual ecology uses the expedition's saved population setting."],
		"tree_leaf_cards":["Tree structure","Use painted shader cutouts for small canopy leaves. Retains physical offshoots and connected anatomy; turn off to compare mesh leaves."],
		"tree_fork_depth":["Tree structure","Visible secondary limb splits. The first split adds three offshoots, then smaller paired forks. Zero keeps the simpler tree."],
		"tree_fork_spread":["Tree structure","Opening angle between structural tree forks."],
		"trunk_lean":["Tree structure","Bend the main trunk toward or away from its crown."],
		"foliage_palette":["Color assignments","Assign a familiar leaf palette. Habitat trees use biome greens; non-tree habitat colors retain their current character."],
		"bark_palette":["Color assignments","Assign bark independently of foliage and flowers."],
		"flower_palette":["Color assignments","Assign flower and accent colors independently."],
		"color_gradient":["Color assignments","Strength of dark-to-light gradients across bark, foliage and flowers. Zero is flat color."],
		"leaf_tip_gradient":["Color assignments","Blend canopy-height coloring toward leaf-base-to-tip coloring."],
		"branch_reach":["Plant structure","Tree scaffold reach beyond the trunk; keeps upward growth at branch bases."],
		"branch_arch":["Plant structure","Tree limbs rise before bending outward and over at their ends."],
		"leaf_size":["Foliage","Scale leaf blades independently of the plant's branches and organs."],
		"foliage_density":["Foliage","Density of leaves and growth groups. Changes apply after releasing the slider."],
		"leaf_curl":["Foliage","Curve leaf blades along their length."],
		"branching_depth":["Growth diversity","How many smaller branching generations grow from each foliage shoot. Zero keeps direct leaf clusters."],
		"branching_spread":["Growth diversity","Opening angle of repeated forks, in radians."],
		"branching_reduction":["Growth diversity","Length retained by each smaller branching generation."],
		"foliage_fullness":["Foliage","Fill existing branches and nodes with layered leaf clusters. Zero keeps only the base foliage."],
		"role_expression":["Growth diversity","Strength of role-specific flowers, collecting cups, shields, tendrils and exchange vanes."],
		"organic_softness":["Growth diversity","Blend angular bends into curved stems and rounded leaf cups. Endpoints stay attached to anatomy."],
		"leaf_architecture":["Foliage","Choose habitat foliage or override it with broad fans, divided fronds, succulent scales or long ribbons."],
		"branch_irregularity":["Growth diversity","Seeded uneven branch angles. Keeps the conducting skeleton connected."],
		"leaf_asymmetry":["Foliage","Unequal leaf halves for less uniform silhouettes."],
		"color_diversity":["Extreme variety","Blend between habitat greens and each growth plan's distinct physical pigment palette. Independent of affinity."],
		"hue_shift":["Extreme variety","Rotate physical leaf and petal pigment hue, in degrees. Does not change affinity."],
		"height_diversity":["Extreme variety","Strength of seeded height differences on top of each growth plan's own height."],
		"node_count":["Extreme variety","Number of primary anatomical joints or branch groups. Dense plans retain a geometry cap."],
		"node_spacing":["Extreme variety","Distance between structural groups; expressed differently by each growth plan."],
		"branch_twist":["Extreme variety","Sideways bend of conducting connections and their outer stems."],
		"node_bulk":["Extreme variety","Width of outer joint, chamber and pod bodies. No energy-capacity change."],
		"node_elongation":["Extreme variety","Stretch outer nodes from squat lobes to elongated capsules."],
		"node_ridges":["Extreme variety","Ribs around chamber bodies; zero gives a smooth surface."],
		"height_ratio":["Plant structure","Height relative to the biome's default form."],
		"spread_ratio":["Plant structure","Horizontal reach relative to the biome's default form."],
		"branch_rise":["Plant structure","Reservoir trees only: upward scaffold branch inclination."],
		"stem_thickness":["Plant structure","Thickness of outer stems; internal conducting tissue has its own control."],
		"radial_symmetry":["Plant structure","Low: spiral and irregular spacing. High: evenly spaced radial growth."],
		"leaf_width":["Foliage","Blade width, independently of leaf length."],
		"tip_taper":["Foliage","Controls the profile of each blade and how sharply it tapers."],
		"leaf_lobes":["Foliage","Number of repeated indentations along blade edges."],
		"lobe_depth":["Foliage","Depth of edge indentations; set zero for smooth edges."],
		"droop":["Foliage","Downward curve, strongest on marsh ribbons and hanging petals."],
		"frond_pairs":["Foliage","Woodland only: leaflet pairs along each frond."],
		"thorn_length":["Leaf shape","Heath only: thorn length multiplier; zero removes thorns."],
		"anatomy_thickness":["Vastra anatomy","Thickness of connected conducting tissue."],
		"organ_height":["Vastra anatomy","Position of the storage hub along the plant's height."],
		"storage_size":["Vastra anatomy","Physical storage tissue and its sheath; changes no energy capacity."],
		"port_radius":["Vastra anatomy","Receiving/releasing aperture width; changes no transfer rate."],
		"root_reach":["Vastra anatomy","Physical root-contact reach; changes no recipient range."],
		"cutaway":["Review","Hide outer growth and inspect internal structures."],
		"anatomy_labels":["Review","Organ annotations appear when a single sample is selected."],
		"silhouette_view":["Review","Show plant geometry in black to compare shapes without material colors."]}
	if info.has(key):
		var display_name := key.capitalize()
		if key=="branch_rise": display_name += " (trees)"
		if key=="frond_pairs": display_name += " (woodland)"
		if key=="thorn_length": display_name += " (heath)"
		return {"group":info[key][0],"help":info[key][1],"label":display_name,"order":PARAMETER_ORDER.find(key) if PARAMETER_ORDER.has(key) else 1000}
	return {"group":"Seed, size and motion","help":"Existing growth-form control. Changes apply after releasing the slider.","order":PARAMETER_ORDER.find(key) if PARAMETER_ORDER.has(key) else 1000}

func create_materials() -> void:
	materials = AnatomyBuilder.make_anatomy_materials()

func build_bed(biome: int) -> void:
	if biome >= 4: return
	for role in range(6): build_sample(biome,role)

func create_builder():
	return AnatomyBuilder.new()

func sample_seed(biome: int,role: int) -> int:
	return generation_seed*10000+biome*101+role*13

func sample_data(biome: int, role: int) -> Dictionary:
	var builder = create_builder()
	var specimen_seed := sample_seed(biome,role)
	return builder.create_sample(biome,role,specimen_seed,generation_settings(),materials)

func build_sample(biome: int,role: int) -> void:
	var data := sample_data(biome, role)
	var bed := Node3D.new()
	bed.name = "%s%s" % [AnatomyBuilder.BIOMES[biome],AnatomyBuilder.ROLES[role]]
	samples.add_child(bed)
	var ground := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.25
	cylinder.bottom_radius = 1.29
	cylinder.height = 0.14
	cylinder.radial_segments = 36
	ground.mesh = cylinder
	ground.name="SampleGround"
	ground.position.y = -0.08
	var soil := StandardMaterial3D.new()
	soil.albedo_texture = preload("res://assets/terrain/ambientcg/ground048/Ground048_2K-JPG_Color.jpg")
	soil.normal_enabled = true
	soil.normal_texture = preload("res://assets/terrain/ambientcg/ground048/Ground048_2K-JPG_NormalGL.jpg")
	soil.albedo_color = [Color("d0c8a6"),Color("a7b4a4"),Color("c3ad92"),Color("a4b4ae")][biome]
	soil.roughness = 1
	ground.material_override = soil
	bed.add_child(ground)
	var plant := Node3D.new()
	plant.scale = Vector3.ONE*plant_size
	bed.add_child(plant)
	var body := MeshInstance3D.new()
	body.name = "OuterGrowth"
	body.mesh = data.body
	body.visible = not cutaway
	body.extra_cull_margin = 0.3
	plant.add_child(body)
	var anatomy := MeshInstance3D.new()
	anatomy.name = "ConnectedVastraAnatomy"
	anatomy.mesh = data.anatomy
	plant.add_child(anatomy)
	var labels := Node3D.new()
	labels.name = "OrganLabels"
	plant.add_child(labels)
	add_organ_labels(labels,data.organs)
	if show_labels:
		var label := Label3D.new()
		label.text = "%s\n%s" % [AnatomyBuilder.BIOMES[biome].to_upper(),str(data.growth_plan).to_upper() if data.get("growth_category","")=="generic_foliage" else AnatomyBuilder.ROLES[role].to_upper()]
		label.position = Vector3(0,0.14,1.18)
		label.font_size = 32
		label.pixel_size = 0.005
		label.outline_size = 6
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bed.add_child(label)
	var bounds: AABB = data.body.get_aabb().merge(data.anatomy.get_aabb())
	beds.append({"node":bed,"biome":biome,"role_index":role,"labels":labels,"bounds":bounds})
	data.erase("body")
	data.erase("anatomy")
	specimens.append(data)

func add_organ_labels(parent: Node3D,organ_data: Array) -> void:
	for organ: Dictionary in organ_data:
		if organ.id not in ["ground","reserve","intake","outlet","crown","release0","root0"]: continue
		if organ.id == "root0" and organ.kind != "Root exchange": continue
		var label := Label3D.new()
		label.text = organ.kind
		var at: Vector3 = organ.position
		var positions := {
			"ground":Vector3(-1.05,0.12,0.25),
			"reserve":Vector3(-1.05,0.5,0.2),
			"intake":Vector3(-1.05,maxf(0.9,at.y+0.25),0.15),
			"outlet":Vector3(1.05,0.5,0.15),
			"crown":Vector3(1.05,at.y+0.22,0.0),
			"release0":Vector3(1.05,at.y+0.25,0.1),
			"root0":Vector3(1.05,0.12,0.25)}
		label.position = positions[organ.id]
		label.font_size = 24
		label.pixel_size = 0.004
		label.outline_size = 6
		label.modulate = Color("f3e3bd")
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		parent.add_child(label)
		var leader := ImmediateMesh.new()
		var ink := StandardMaterial3D.new()
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ink.albedo_color = Color("cfbd94")
		leader.surface_begin(Mesh.PRIMITIVE_LINES,ink)
		leader.surface_add_vertex(at)
		leader.surface_add_vertex(at.lerp(label.position,0.9))
		leader.surface_end()
		var line := MeshInstance3D.new()
		line.mesh = leader
		parent.add_child(line)

func build_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var frame := PanelContainer.new()
	frame.position = Vector2(12,12)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08,0.14,0.16,0.96)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: panel_style.set_content_margin(side,10)
	frame.add_theme_stylebox_override("panel",panel_style)
	layer.add_child(frame)
	var panel := VBoxContainer.new()
	frame.add_child(panel)
	var title := Label.new()
	title.text = "PLANTS / VASTRA ANATOMY"
	title.add_theme_font_size_override("font_size",18)
	panel.add_child(title)
	var hint := Label.new()
	hint.text = "Four biomes · six role/class samples\nRight-drag: orbit · Wheel: zoom"
	panel.add_child(hint)
	biome_picker.name = "Biome"
	biome_picker.add_item("All biomes")
	for biome in AnatomyBuilder.BIOMES: biome_picker.add_item(biome)
	panel.add_child(biome_picker)
	role_picker.name = "CirculationRoleAndClass"
	role_picker.add_item("All roles and classes")
	for role in AnatomyBuilder.ROLES: role_picker.add_item(role)
	panel.add_child(role_picker)
	biome_picker.item_selected.connect(func(_index: int): refresh_view())
	role_picker.item_selected.connect(func(_index: int): refresh_view())
	var isolate := CheckButton.new()
	isolate.name = "Cutaway"
	isolate.text = "Cutaway / expose anatomy"
	isolate.button_pressed = cutaway
	panel.add_child(isolate)
	isolate.toggled.connect(func(enabled: bool):
		cutaway = enabled
		remember("cutaway",enabled)
		for bed in beds:
			bed.node.find_child("OuterGrowth",true,false).visible = not cutaway)
	var reset := Button.new()
	reset.name = "ResetShapeControls"
	reset.text = "Reset shape controls"
	panel.add_child(reset)
	reset.pressed.connect(func():
		var defaults := SHAPE_DEFAULTS.merged(VARIETY_DEFAULTS)
		for key in defaults:
			set(key,defaults[key])
			remember(key,defaults[key])
		var host := get_parent()
		while host != null and not host.has_method("load_fixture"): host = host.get_parent()
		if host != null: host.load_fixture.call_deferred()
		else: get_tree().reload_current_scene.call_deferred())
	anatomy_note.text = ""
	panel.add_child(anatomy_note)
	var footer := Label.new()
	footer.text = "PROPOSED ANATOMY · Static structures / no simulated transfers"
	if silhouette_view: footer.add_theme_color_override("font_color",Color("21353a"))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	footer.offset_left = 16
	footer.offset_top = -30
	layer.add_child(footer)
	biome_picker.select(selected_biome)
	role_picker.select(selected_role)
	refresh_view()

func remember(key: String,value: Variant) -> void:
	var host := get_parent()
	while host != null and not host.has_method("load_fixture"): host = host.get_parent()
	if host != null: host.overrides[key] = value

func extend_frame_bounds(bounds: AABB) -> AABB:
	return bounds.merge(biome_scene_bounds) if scene_layout!=1 and biome_scene_bounds.has_volume() else bounds

## Preview population is a seeded sample, never a quota or a live flora owner.
func common_understory(biome: int,center: Vector3,radius: float) -> Dictionary:
	var common:=Node3D.new()
	common.name="CommonUnderstory%d"%biome
	biome_stages.add_child(common)
	var random:=RandomNumberGenerator.new()
	random.seed=generation_seed*1031+biome*719
	var roles := {}
	# Canopy examples are also optional in a natural scene, independent of classes.
	if random.randf() < [0.5,0.85,0.3,0.65][biome]: roles[1]=true
	var points: Array[Vector2]=[]
	for index in range(common_foliage_samples):
		var cell:=Vector2i(biome*256+index%6*3,index/6*3+generation_seed*32)
		var traits:=FloraTraits.describe(generation_seed,{"id":FloraCatalog.id_for(cell),"cell":[cell.x,cell.y],"kind":"plant"},preview_specialist_percent)
		if traits.role=="receiver":
			roles[3+FloraTraits.CLASSES.find(traits["class"])]=true
			continue
		var at:=Vector2.ZERO
		var fits:=false
		for attempt in range(24):
			at=Vector2.from_angle(random.randf()*TAU)*radius*sqrt(random.randf())*0.82
			if at.length()<0.5: continue
			fits=true
			for point in points:
				if point.distance_to(at)<0.6: fits=false; break
			if fits: break
		if not fits: continue
		points.append(at)
		var item: Resource=preload("res://scripts/scenery/plant_library.gd").foliage_definition(biome,random.randi_range(0,4),"emanator")
		var model: Dictionary=preload("res://scripts/scenery/plant_library.gd").model(item)
		var scale: Vector3=item.scale_for(model.bounds)*random.randf_range(0.65,1.0)
		var transform:=Transform3D(Basis(Vector3.UP,random.randf()*TAU)*Basis.from_scale(scale),center+Vector3(at.x,0,at.y))
		transform.origin-=transform.basis*item.ground_offset(model.bounds)
		var plant:=Node3D.new()
		plant.name="CommonFoliage%d"%index
		common.add_child(plant)
		for part: Dictionary in model.pieces:
			var mesh:=MeshInstance3D.new()
			mesh.mesh=part.mesh
			for surface in range(mesh.mesh.get_surface_count()):
				var material: Material=mesh.mesh.surface_get_material(surface)
				if material is ShaderMaterial:
					if not common_preview_materials.has(material): common_preview_materials[material]=material.duplicate()
					mesh.set_surface_override_material(surface,common_preview_materials[material])
			mesh.transform=transform*part.transform
			plant.add_child(mesh)
	return roles

func arrange_samples(visible_beds: Array[Dictionary],columns: int,horizontal_gap: float,depth_gap: float) -> void:
	if biome_stages.get_parent()==null:
		biome_stages.name="BiomePreviewStages"
		add_child(biome_stages)
	for child in biome_stages.get_children(): child.free()
	common_preview_materials.clear()
	biome_stages.visible=scene_layout!=1
	biome_scene_bounds=AABB()
	for bed: Dictionary in visible_beds:
		bed.node.find_child("SampleGround",true,false).visible=scene_layout==1
		for child in bed.node.get_children():
			if child is Label3D:
				if not child.has_meta("grid_text"):
					child.set_meta("grid_text",child.text)
					child.set_meta("grid_position",child.position)
				if scene_layout==1: child.position=child.get_meta("grid_position")
				child.text=child.get_meta("grid_text") if scene_layout==1 else AnatomyBuilder.ROLES[bed.role_index]
				child.visible=show_labels
	if scene_layout==1:
		for index in range(visible_beds.size()):
			visible_beds[index].node.position=Vector3((index%columns-(columns-1)*0.5)*horizontal_gap,0,(floori(float(index)/columns)-(ceilf(float(visible_beds.size())/columns)-1)*0.5)*depth_gap)
		return
	var groups := {}
	var radius := 2.0
	for bed: Dictionary in visible_beds:
		if not groups.has(bed.biome): groups[bed.biome]=[]
		groups[bed.biome].append(bed)
		radius=maxf(radius,maxf(bed.bounds.size.x,bed.bounds.size.z)*plant_size*0.7+0.8)
	var index := 0
	var offsets := [Vector2(-0.65,0.5),Vector2(0,-0.2),Vector2(0.65,0.3),Vector2(-0.75,-0.3),Vector2(0.05,0.8),Vector2(0.7,-0.4)]
	for biome: int in groups:
		var center:=Vector3((index-(groups.size()-1)*0.5)*(radius*2.0+1.2),0,0)
		var beds_in_biome: Array=groups[biome]
		var natural_roles := {}
		if scene_layout==0 and role_picker.selected==0:
			natural_roles=common_understory(biome,center,radius)
		for bed: Dictionary in beds_in_biome:
			var offset: Vector2=offsets[bed.role_index] if beds_in_biome.size()>1 else Vector2.ZERO
			bed.node.position=center+Vector3(offset.x,0,offset.y)*radius*0.8
			if scene_layout==0 and role_picker.selected==0: bed.node.visible=natural_roles.has(bed.role_index)
			for child in bed.node.get_children():
				if child is Label3D:
					child.position=Vector3(0,0.08,maxf(0.15,bed.bounds.end.z*plant_size)+0.15)
		var ground:=MeshInstance3D.new()
		var disk:=CylinderMesh.new()
		disk.top_radius=radius
		disk.bottom_radius=radius*1.01
		disk.height=0.12
		disk.radial_segments=48
		ground.mesh=disk
		ground.material_override=beds_in_biome[0].node.find_child("SampleGround",true,false).material_override
		ground.position=center-Vector3.UP*0.07
		biome_stages.add_child(ground)
		var title:=Label3D.new()
		title.text=AnatomyBuilder.BIOMES[biome].to_upper()
		title.position=center+Vector3(0,0.1,radius+0.4)
		title.font_size=48
		title.pixel_size=0.012
		title.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		biome_stages.add_child(title)
		var area:=AABB(center+Vector3(-radius,-0.3,-radius),Vector3(radius*2,2.0,radius*2+0.9))
		biome_scene_bounds=area if index==0 else biome_scene_bounds.merge(area)
		index+=1


func refresh_view() -> void:
	selected_biome = biome_picker.selected
	selected_role = role_picker.selected
	remember("selected_biome",selected_biome)
	remember("selected_role",selected_role)
	var visible_beds: Array[Dictionary] = []
	for bed in beds:
		bed.node.visible = (biome_picker.selected==0 or bed.biome==biome_picker.selected-1) and (role_picker.selected==0 or bed.role_index==role_picker.selected-1)
		if bed.node.visible: visible_beds.append(bed)
	var columns := (6 if biome_picker.selected==0 else 3) if role_picker.selected==0 else (4 if biome_picker.selected==0 else 1)
	var horizontal_gap := 3.1
	var depth_gap := 3.6
	for bed in visible_beds:
		horizontal_gap = maxf(horizontal_gap,bed.bounds.size.x*plant_size+0.8)
		depth_gap = maxf(depth_gap,bed.bounds.size.z*plant_size+0.9)
	arrange_samples(visible_beds,columns,horizontal_gap,depth_gap)
	visible_beds=visible_beds.filter(func(bed: Dictionary) -> bool: return bed.node.visible)
	var framed := AABB()
	var first := true
	for index in range(visible_beds.size()):
		var bed: Dictionary = visible_beds[index]
		bed.labels.visible = anatomy_labels and visible_beds.size()==1
		var local_bounds: AABB = bed.bounds
		var actual := AABB(local_bounds.position*plant_size+bed.node.position,local_bounds.size*plant_size)
		var radius:=frame_ground_radius()
		var floor_depth:=maxf(0.002,minf(0.2,radius*0.2))
		actual = actual.merge(AABB(bed.node.position+Vector3(-radius,-floor_depth*0.5,-radius),Vector3(radius*2,floor_depth,radius*2)))
		framed = actual if first else framed.merge(actual)
		first = false
	framed=extend_frame_bounds(framed)
	view_target = framed.get_center()
	var aspect := maxf(0.5,float(get_viewport().size.x)/maxf(1,get_viewport().size.y))
	distance_value = maxf(framed.size.x/aspect,framed.size.y+framed.size.z*0.65)/ (2*tan(deg_to_rad(camera.fov*0.5)))*1.35+maxf(0.025,framed.size.length()*0.05)
	pitch = 0.65 if visible_beds.size()>6 else 0.46
	if role_picker.selected>0 and biome_picker.selected==0: pitch = 0.3
	yaw = 0.10
	anatomy_note.text = ""
	if visible_beds.size()==1:
		var role: int = visible_beds[0].role_index
		anatomy_note.text = "Role: %s" % ("Emanator" if role==0 else ("Reservoir" if role==1 else "Receiver"))
		if role>=3: anatomy_note.text += " · Class: " + AnatomyBuilder.ROLES[role]
		anatomy_note.text += "\n" + AnatomyBuilder.PLANS[visible_beds[0].biome*6+role]
	update_camera()

func update_camera() -> void:
	camera.near=maxf(0.0001,minf(0.05,distance_value*0.001))
	camera.far=maxf(10.0,distance_value*6.0)
	var target := view_target
	camera.position = target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance_value
	camera.look_at(target)

func frame_ground_radius() -> float:
	return 1.3

func _process(delta: float) -> void:
	elapsed += delta
	for material in materials+common_preview_materials.values():
		if material is ShaderMaterial:
			material.set_shader_parameter("wind_time",elapsed)
			material.set_shader_parameter("wind_strength",wind_strength)

func workstation_readings() -> Dictionary:
	return {"specimens":specimens,"build_ms":build_ms,"seed":generation_seed,"scope":"Static proposed anatomy; no live reserves, transfers or new abilities", "visible_biome":biome_picker.get_item_text(biome_picker.selected),"visible_role":role_picker.get_item_text(role_picker.selected),"cutaway":cutaway}
