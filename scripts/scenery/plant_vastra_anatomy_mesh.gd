extends "res://scripts/scenery/procedural_plant_mesh.gd"
## Proposed anatomical models of existing roles; no ecological transactions.
const BIOMES := ["Meadow", "Woodland", "Heath", "Marsh"]
const ROLES := ["Emanator", "Reservoir", "Receiver", "Warden", "Mender", "Regulator"]
const TINTS := [Color("c9d6a4"),Color("789d88"),Color("b8a685"),Color("8ca99c")]
const PIGMENTS := ["e6b846","bd4968","e58b54","6860b9","edf1d6","55b9b1","b7ced8","418b9d","8f3e68","bc885d","a996cd","83cbb6","b86c43","d8c29b","8b426a","72454c","e7c75c","dc6155","80cfb1","806aab","53b8cb","c48d51","668aca","e2ae9b"]
const PLANS := ["Golden ground fans","Crimson umbrella","Amber spiral bowl","Indigo shield fan","Ivory candelabra","Turquoise coil","Silver runners","Blue twin arch","Wine pendants","Bronze rib dome","Lavender hanging bells","Jade tiers","Rust antlers","Bone jointed caudex","Plum paddle cluster","Oxide thorn crown","Gold cushion blooms","Scarlet zigzag","Mint reed spires","Violet stilt curtain","Cyan trumpets","Copper sail wall","Blue wing blooms","Peach branching pipes"]
const HEIGHTS := [0.32,2.4,0.6,1.05,1.6,1.9,0.4,3.1,1.5,1.25,2.1,2.4,0.35,2.8,0.48,0.8,0.22,1.7,2.2,4.0,1.7,2.15,1.1,2.6]
const SPREADS := [1.1,1.15,0.9,1.1,0.72,0.52,1.2,1.1,0.85,1.1,0.85,0.8,1.0,1.1,0.78,0.9,1.15,0.55,0.48,1.1,0.9,1.0,1.2,0.8]
var foliage_branches: Array[Dictionary] = []
var organs: Array[Dictionary] = []
var leaf_surfaces: Array[Dictionary] = []
var links: Array[Dictionary] = []
var organ_positions: Dictionary = {}
var anatomy_scale := 1.0
var biome_index := 0
var role_index := 0
var tuning: Dictionary = {}
var pigment := Color.WHITE
var accent := Color.WHITE
var plan_index := 0
var growth_height := 1.0
var pending_leaves: Array[Dictionary] = []
var leaf_quads: Array[Dictionary] = []
var collecting_leaf := false
var surface_cells: Dictionary = {}
var spacing_triangles: Array[PackedVector3Array] = []
var spacing_bounds: Array[AABB] = []
var omitted_leaves := 0
var branch_corridors: Array[Dictionary]=[]
var branch_cells: Dictionary={}
var repositioned_branches := 0
var building_scaffold := false
var pending_supports: Array[Dictionary]=[]
var junction_radii: Dictionary={}
var bark_pigment := Color("71513b")
const LEAF_PALETTES := ["648541","9aaf54","375b39","a5aa7b","bc803c","864e40"]
# Curated habitat families, shared by live trees, specialists and undergrowth.
# An explicit index leaves authored maker recipes on their selected palette.
const BIOME_LEAF_PALETTES := [
	["78ad42","bed45b","d3aa38","429565","94bd51"],
	["32764e","58a879","8faa42","bb7841","397f80"],
	["9772ad","b6537b","cf9142","7d9345","87536e"],
	["398b80","67b6a1","a9bf48","508aab","bb9b54"]
]
const FLOWER_PALETTES := ["e8d6a4","d8b74c","be7980","9a84aa","ca8752","ece5d4"]

func create_sample(biome: int, role: int, specimen_seed: int, settings: Dictionary, materials: Array[Material]) -> Dictionary:
	tube_metric_uv=role==1
	if role==1:
		# The exposed reservoir collar shares the trunk wind and authored maps.
		materials[5]=materials[0].duplicate()
		materials[5].set_shader_parameter("palette_gain",1.25)
		for material: Material in materials:
			if material is ShaderMaterial and material.shader==preload("res://shaders/procedural_plant_foliage.gdshader"):
				material.set_shader_parameter("tree_surface",true)
	prepare(specimen_seed,settings,materials)
	tuning = settings
	pending_leaves.clear()
	surface_cells.clear()
	spacing_triangles.clear()
	spacing_bounds.clear()
	omitted_leaves=0
	branch_corridors.clear()
	branch_cells.clear()
	repositioned_branches=0
	building_scaffold=true
	pending_supports.clear()
	junction_radii.clear()
	organs.clear()
	leaf_surfaces.clear()
	foliage_branches.clear()
	links.clear()
	organ_positions.clear()
	biome_index = biome
	role_index = role
	plan_index = biome*6+role
	# The reviewed foliage family's soft habitat pigments also anchor role plants.
	var color_strength := option("color_diversity",0.0)
	pigment = TINTS[biome].lerp(Color(PIGMENTS[plan_index]),color_strength)
	pigment = Color.from_hsv(fposmod(pigment.h+option("hue_shift",0.0)/360.0,1.0),pigment.s,pigment.v)
	# Trees stay within familiar leaf/bark families even when hue is randomized.
	var leaf_choice := clampi(int(option("foliage_palette",0)),0,6)
	if role==1 or leaf_choice>0:
		var leaf_hex: String=LEAF_PALETTES[leaf_choice-1] if leaf_choice>0 else ["728647","4e7142","87865b","587553"][biome]
		pigment=Color(leaf_hex)
		pigment=Color.from_hsv(fposmod(pigment.h+(clampf(option("hue_shift",0.0),-35,35) if role==1 else option("hue_shift",0.0))/360.0,1.0),pigment.s,pigment.v)
	var biome_color := int(option("biome_palette_variant",-1))
	if biome_color>=0:
		pigment=Color(BIOME_LEAF_PALETTES[biome][posmod(biome_color,5)])
		pigment=Color.from_hsv(fposmod(pigment.h+(clampf(option("hue_shift",0.0),-35,35) if role==1 else option("hue_shift",0.0))/360.0,1.0),pigment.s,pigment.v)
	var bark_choice := clampi(int(option("bark_palette",0)),0,4)
	bark_pigment=Color(["71513b","898379","925c45","b8b1a0"][bark_choice-1] if bark_choice>0 else ["806044","655346","8c7960","726956"][biome])
	var flower_choice := clampi(int(option("flower_palette",0)),0,6)
	accent=Color(FLOWER_PALETTES[flower_choice-1 if flower_choice>0 else posmod(plan_index,6)])
	anatomy_scale = settings.get("anatomy_scale",1.0)
	var height: float = HEIGHTS[plan_index]
	height *= lerpf(1.0,0.72+float(posmod(specimen_seed,17))/28.0,option("height_diversity",1.0))
	var spread: float = SPREADS[plan_index]
	height *= option("height_ratio",1.0)
	if role==1: height*=1.35
	growth_height=height
	spread *= option("spread_ratio",1.0)
	add_organ("ground","Ground contact",Vector3(0,0.025,0),"",0.04)
	var root_count: int = [3,5,3,6][biome]
	for root in range(root_count):
		var angle := root*TAU/root_count + rng.randf_range(-0.15,0.15)
		var reach := spread*0.62*option("root_reach",1.0)
		var tip := radial(angle)*reach*0.55-Vector3.UP*maxf(0.12,reach*0.65)
		add_organ("root%d" % root,"Root exchange" if role == 1 else "Ground contact",tip,"ground",0.025)
		if role == 1: aperture(tip,Vector3.DOWN,0.07)
	add_organ("collar","Root collar",Vector3(0,0.14,0),"ground",0.18 if role==1 else 0.045,0.16 if role==1 else -1.0)
	var hub := Vector3(rng.randf_range(-0.055,0.055),height*(0.10 if role==1 else 0.22)*option("organ_height",1.0),0)
	add_organ("reserve","Storage tissue",hub,"collar",0.16 if role==1 else 0.025,0.15 if role==1 else -1.0)
	var core_radius := (0.12 if role==1 else 0.065)*option("storage_size",1.0)
	var core_height := (0.36 if role==1 else 0.16)*option("storage_size",1.0)
	if role!=1: chamber(hub,core_radius,core_height,4)
	# Storage is enclosed in a stem/basal body, visible internally in cutaway.
	if role!=1: chamber(hub,core_radius*1.45,core_height*1.1,0)
	build_growth_plan(height,spread)
	# Repeated shoots develop from existing conductors without creating reserves.
	var recursive_depth := clampi(int(option("plant_recursive_depth",0)),0,3)
	if role!=1 and recursive_depth>0:
		var attachments := organs.duplicate()
		var shoots := 0
		for organ: Dictionary in attachments:
			if organ.parent!="reserve" or organ.id in ["intake","outlet"]: continue
			var heading: Vector3=(organ.position-hub+Vector3.UP*0.2).normalized()
			grow_tree_forks(organ.id,heading,maxf(0.08,spread*0.22),recursive_depth,0)
			shoots+=1
			if shoots>=3: break
	# Main stems own their space before optional leaf-bearing supports are fitted.
	building_scaffold=false
	for support: Dictionary in pending_supports:
		if support.frond: frond(support.base,support.direction,support.reach,support.width)
		else: foliage_cluster(support.base,support.direction,support.reach)
	pending_supports.clear()
	flush_leaves()
	var combined := finish()
	var outer := ArrayMesh.new()
	var anatomy := ArrayMesh.new()
	for surface in range(combined.get_surface_count()):
		var index := int(combined.surface_get_name(surface))
		var destination := outer if index < 3 or index==6 else anatomy
		destination.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,combined.surface_get_arrays(surface))
		destination.surface_set_material(destination.get_surface_count()-1,combined.surface_get_material(surface))
	return {"body":outer,"anatomy":anatomy,"foliage_branches":foliage_branches.duplicate(true),"organs":organs.duplicate(true),"leaf_surfaces":leaf_surfaces.duplicate(true),"links":links.duplicate(true),"seed":specimen_seed,"biome":BIOMES[biome],"role":"emanator" if role==0 else ("reservoir" if role==1 else "receiver"),"class":ROLES[role].to_lower() if role>=3 else "","growth_plan":PLANS[plan_index],"pigment":pigment,"vertices":mesh_vertex_count(combined),"omitted_leaves":omitted_leaves,"repositioned_branches":repositioned_branches}

func vertex(surface: int, at: Vector3, uv: Vector2, color: Color) -> void:
	var gradient := option("color_gradient",0.45)
	var canopy := clampf(at.y/maxf(0.01,growth_height),0.0,1.0)
	if surface==0:
		color=bark_pigment.darkened(gradient*0.18).lerp(bark_pigment.lightened(gradient*0.12),canopy)
	elif surface in [1,2,6]:
		var base := pigment if surface in [1,6] else accent
		var leaf_t := clampf((0.40-uv.y)/0.33,0.0,1.0)
		var blend := lerpf(canopy,leaf_t,option("leaf_tip_gradient",0.65))
		color=base.darkened(gradient*0.3).lerp(base.lightened(gradient*0.3),blend)
		# Coherent patches vary subtly; no independent random color at each vertex.
		var patch := sin(at.dot(Vector3(1.3,0.7,1.8))+float(plan_index))*option("color_diversity",1.0)*0.08
		color=color.lightened(patch) if patch>=0.0 else color.darkened(-patch)
		if role_index==1 and surface==1:
			var crown_patch := sin(at.dot(Vector3(0.8,0.45,1.1))+float(rng.seed%97))*option("color_diversity",1.0)
			color=Color.from_hsv(fposmod(color.h+crown_patch*0.045,1.0),clampf(color.s*(1.0+crown_patch*0.25),0,1),color.v)
	if surface in [1,6]:
		var leaf_field := sin(at.x*0.43+at.y*0.27)*cos(at.z*0.39+float(plan_index))
		color=Color.from_hsv(fposmod(color.h+leaf_field*0.035,1.0),color.s,color.v)
	if surface==6: color.a=(biome_index+0.5)/4.0
	super.vertex(surface,at,uv,color)

func add_organ(id: String, kind: String, at: Vector3, parent_id: String, radius: float, end_radius: float = -1.0) -> Vector3:
	if not parent_id.is_empty() and kind in ["Leaf conductor","Exchange node","Release tip","Receiving chamber","Side exchange"]:
		at=spaced_branch_tip(organ_positions[parent_id],at,radius*1.5)
	organs.append({"id":id,"kind":kind,"position":at,"parent":parent_id})
	organ_positions[id] = at
	if parent_id.is_empty(): return at
	var start: Vector3 = organ_positions[parent_id]
	var middle := start.lerp(at,0.5)
	middle += Vector3(at.z-start.z,0,start.x-at.x)*0.12*organic_softness
	if role_index==1 and at.y>start.y:
		middle = start.lerp(at,0.5)
		middle.x = lerpf(start.x,at.x,0.3)
		middle.z = lerpf(start.z,at.z,0.3)
		if kind=="Crown exchange":
			middle=start.lerp(at,0.55)+Vector3.UP*growth_height*0.015*option("branch_arch",0.8)
	middle += Vector3(at.z-start.z,0,start.x-at.x)*option("branch_twist",0.0)*(0.025 if role_index==1 else 0.2)
	var path: Array[Vector3] = [start,middle,at]
	var taper:=0.65 if role_index==1 and kind in ["Ascending scaffold","Crown exchange","Branch fork"] else 0.12
	if end_radius>=0.0: taper=end_radius/maxf(radius,0.00001)
	var curve_detail := 2 if kind=="Branch fork" else 0
	tube(path,radius*anatomy_scale*(0.45 if role_index==1 else 1.0),3,Color.WHITE,taper,curve_detail)
	links.append({"from":parent_id,"to":id,"path":path})
	# Outer stems follow the same connected skeleton.
	if kind != "Ground contact" and kind != "Root exchange" and not (role_index==1 and kind in ["Root collar","Storage tissue","Trunk junction","Crown conductor","Crown socket","Crown exchange"]):
		tube(path,radius*1.45*option("stem_thickness",1.0),0,Color("b8bb99"),taper,curve_detail)
		stem_joint(start,radius*1.5*option("stem_thickness",1.0))

	return at

func chamber(at: Vector3, radius: float, height: float, surface: int) -> void:
	if surface==0:
		radius *= option("node_bulk",1.0)
		height *= option("node_elongation",1.0)
	for ring in range(6):
		for segment in range(12):
			var points: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for corner in [Vector2(ring,segment),Vector2(ring,segment+1),Vector2(ring+1,segment+1),Vector2(ring+1,segment)]:
				var latitude: float = PI*corner.x/6
				var longitude: float = TAU*corner.y/12
				var ridges := 1.0+(0.05 if role_index==1 else 0.13)*cos(longitude*option("node_ridges",3.0))*sin(latitude)
				var radial_profile := maxf(0.025,sin(latitude))
				var vertical_profile := cos(latitude)
				points.append(at+radial(longitude)*radius*radial_profile*ridges+Vector3.UP*vertical_profile*height*0.5)
				uvs.append(Vector2(0.11+cos(longitude)*0.025,0.2+sin(latitude)*0.08))
			quad(surface,points,uvs,Color.WHITE)

func option(key: String, fallback: float) -> float:
	return float(tuning.get(key,fallback))

func growth_angle(index: int, count: int) -> float:
	var symmetry := option("radial_symmetry",0.55)
	return sin(index*7.13+float(rng.seed%997))*option("branch_irregularity",0.0)*0.85+lerpf(index*2.399,index*TAU/maxi(1,count),symmetry)+rng.randf_range(-0.15,0.15)*(1.0-symmetry)

func aperture(at: Vector3, direction: Vector3, radius: float) -> void:
	# Physical lips and membranes replace the repeated wire-basket motif.
	radius *= option("port_radius",1.0)
	var axis := direction.normalized()
	var across := axis.cross(Vector3.FORWARD if absf(axis.y)>0.9 else Vector3.UP).normalized()
	var side := axis.cross(across).normalized()
	var lip: Array[Vector3] = []
	for index in range(13):
		var angle := index*TAU/12
		var squash := 0.38 if biome_index==2 else 1.0
		lip.append(at+(across*cos(angle)+side*sin(angle)*squash)*radius)
	tube(lip,0.018*anatomy_scale,5)
	for segment in range(12):
		var points: Array[Vector3] = []
		var uvs: Array[Vector2] = []
		for corner in [Vector2(segment,0),Vector2(segment+1,0),Vector2(segment+1,1),Vector2(segment,1)]:
			var angle: float = corner.x*TAU/12
			var t: float = corner.y
			var width := lerpf(0.45,1.0,t)
			var squash := 0.38 if biome_index==2 else 1.0
			points.append(at+(across*cos(angle)+side*sin(angle)*squash)*radius*width-axis*radius*(1.0-t)*1.1)
			uvs.append(Vector2(0.119+cos(angle)*0.035,0.23+sin(angle)*0.06))
		quad(1,points,uvs,accent)

func blade(base: Vector3, direction: Vector3, length: float, width: float, style: int = -1, surface: int = 1, segments: int = 12) -> void:
	pending_leaves.append({"base":base,"direction":direction,"length":length,"width":width,"style":style,"surface":surface,"segments":segments,"card":false})

func emit_blade(base: Vector3, direction: Vector3, length: float, width: float, style: int, surface: int, segments: int) -> void:
	# Small leaflets need fewer lengthwise strips; keep curved cross sections.
	if option("groundcover_detail",0.0)>0.0 and surface==1: segments=3
	elif segments==12 and width<=0.14: segments=6
	var family := biome_index if style<0 else style
	if surface==1 and int(option("leaf_architecture",0))>0: family = int(option("leaf_architecture",0))-1
	length *= leaf_scale
	width *= leaf_scale*option("leaf_width",1.0)
	var forward := direction.normalized()
	var across := forward.cross(Vector3.UP if absf(forward.y)<0.95 else Vector3.FORWARD).normalized()
	var normal := across.cross(forward).normalized()
	var path: Array[Vector3] = []
	for step in range(segments+1):
		var t := step/float(segments)
		var drop := option("droop",0.55)*(0.65 if family==3 else 0.16)
		var sway := sin(base.dot(Vector3(1.7,0.9,2.3))+forward.x*2.1)*organic_softness
		path.append(base+forward*length*t+Vector3.UP*length*(curl*sin(PI*t)*0.22-drop*t*t)+across*length*0.07*sway*sin(PI*t))
	var cross_strips := 1 if option("groundcover_detail",0.0)>0.0 else (2 if role_index==1 and segments<=6 else 4)
	for step in range(segments):
		for strip in range(cross_strips):
			var left := -1.0+strip*2.0/cross_strips
			var right := left+2.0/cross_strips
			var points: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			for corner in [Vector2(step,left),Vector2(step,right),Vector2(step+1,right),Vector2(step+1,left)]:
				var i := int(corner.x)
				var t := i/float(segments)
				var profile := maxf(0.015,pow(maxf(0.0,sin(PI*t)),option("tip_taper",0.75)))
				if family==0: profile *= 0.55+0.6*t
				if family==2: profile = maxf(0.02,1.0-t*t)*0.8
				var lobes := int(option("leaf_lobes",3))
				profile *= 1.0+corner.y*option("leaf_asymmetry",0.0)*0.45
				profile *= 1.0-option("lobe_depth",0.25)*(1.0-organic_softness*0.45)*pow(sin(t*PI*lobes),2)
				points.append(path[i]+across*corner.y*width*profile*0.5+normal*lerpf(absf(corner.y),corner.y*corner.y,organic_softness)*width*profile*0.14)
				uvs.append(Vector2(0.119+corner.y*0.045*maxf(0.01,sin(PI*t)),lerpf(0.40,0.07,t)))
			quad(surface,points,uvs,pigment if surface==1 else accent)
	# Tiny canopy ribs keep exact endpoints with fewer longitudinal samples;
	# spend the saved geometry on additional offshoots and actual leaf blades.
	tube([path[0],path[segments/2],path[segments]],0.006*anatomy_scale,3,Color.WHITE,0.12,2 if role_index==1 else 0)

func frond(base: Vector3,direction: Vector3,length: float,width: float) -> void:
	if building_scaffold:
		pending_supports.append({"frond":true,"base":base,"direction":direction,"reach":length,"width":width})
		return
	var count := int(option("frond_pairs",6))
	var tip := spaced_branch_tip(base,base+direction.normalized()*length+Vector3.UP*0.12,0.02,true)
	if not tip.is_finite(): return
	direction=(tip-base).normalized()
	var middle := base.lerp(tip,0.5)+Vector3.UP*0.15
	tube([base,middle,tip],0.013,0)
	stem_joint(base,0.015)
	for index in range(1,count+1):
		var t := index/float(count+1)
		var control := middle*2.0-(base+tip)*0.5
		var soft := base*(1.0-t)*(1.0-t)+control*2.0*t*(1.0-t)+tip*t*t
		var angular := base.lerp(middle,t*2.0) if t<=0.5 else middle.lerp(tip,t*2.0-1.0)
		var at := angular.lerp(soft,organic_softness)
		for side in [-1,1]:
			blade(at,direction.rotated(Vector3.UP,side*1.1)+Vector3.UP*0.12,width*(1.0-t)+0.08,0.10,1)

func spine(base: Vector3,direction: Vector3,length: float) -> void:
	var reach := length*option("thorn_length",1.0)
	if reach<0.001: return
	tube([base,base+direction.normalized()*reach],0.024,0,Color("d1c2a4"))

func growth(base: Vector3,direction: Vector3,length: float,width: float) -> void:
	var architecture := int(option("leaf_architecture",0))
	match biome_index if architecture==0 else architecture-1:
		0: blade(base,direction,length,width*1.35,0)
		1: frond(base,direction,length,width*1.4)
		2:
			blade(base,direction,length*0.65,width*0.9,2)
			spine(base+direction.normalized()*length*0.5,direction,0.18)
		3: blade(base,direction,length*1.3,width*0.45,3)

func blossom(at: Vector3,size: float) -> void:
	match biome_index:
		0:
			for petal in range(7): blade(at,radial(petal*TAU/7,0.15),size,size*0.65,0,2)
		1:
			for petal in range(4): blade(at,radial(petal*TAU/4,-1.0),size,size*0.42,3,2)
		2:
			for petal in range(3): blade(at,radial(petal*TAU/3,0.65),size*0.5,size*0.5,2,2)
		3:
			for petal in range(3): blade(at,radial(petal*TAU/3,1.4),size*1.2,size*0.35,3,2)

func build_growth_plan(height: float,spread: float) -> void:
	var hub: Vector3 = organ_positions.reserve
	var count := clampi(int(option("node_count",8)*branches/8.0*sqrt(foliage)),3,12)
	var spacing := option("node_spacing",1.0)
	# The graph is structural, not a request for extra reserves or transfer routes.
	if role_index==1:
		var crown := Vector3(height*option("trunk_lean",0.08),height*0.78,0)
		# One connected centerline owns both the trunk mesh and branch sockets.
		var trunk_parent := "reserve"
		var trunk_radius := 0.15
		var trunk_path: Array[Vector3]=[organ_positions.ground,organ_positions.collar,hub]
		var limb_count := clampi(count+2,5,8)
		var curve := option("trunk_curve",[0.045,0.035,0.065,0.025][biome_index])
		var phase := option("trunk_phase",float(rng.seed%997)*0.01)
		for joint in range(limb_count):
			var crown_start: float=[0.30,0.36,0.22,0.34][biome_index]
			crown_start=clampf(crown_start+[0.0,0.06,-0.05][clampi(int(option("crown_habit",0)),0,2)],0.2,0.6)
			var t := lerpf(crown_start,0.9,float(joint)/maxi(1,limb_count-1))
			var at := hub.lerp(crown,t)+Vector3(sin(t*PI+phase)-sin(phase),0,sin(t*PI*0.7+phase)-sin(phase))*height*curve
			trunk_path.append(at)
			var joint_id := "trunk_joint%d"%joint
			var next_radius := lerpf(0.15,0.08,t)
			add_organ(joint_id,"Trunk junction",at,trunk_parent,trunk_radius,next_radius)
			trunk_radius=next_radius
			trunk_parent=joint_id
		add_organ("crown","Crown conductor",crown,trunk_parent,trunk_radius,0.065)
		trunk_path.append(crown)
		tube(trunk_path,0.18*option("stem_thickness",1.0),0,Color.WHITE,0.36)
		# One textured living collar wraps the actual start of the crown.
		var ring_at: Vector3=organ_positions.trunk_joint0
		organs.append({"id":"reservoir_ring","kind":"Reservoir collar","position":ring_at,"parent":"trunk_joint0"})
		organ_positions["reservoir_ring"]=ring_at
		var axis := (trunk_path[4]-trunk_path[2]).normalized()
		var across := axis.cross(Vector3.FORWARD).normalized()
		var sideways := axis.cross(across).normalized()
		var ring_radius := 0.18*option("stem_thickness",1.0)*lerpf(1.0,0.36,3.0/float(trunk_path.size()-1))
		var ring_path: Array[Vector3]=[]
		for segment in range(17):
			var angle := TAU*segment/16.0
			ring_path.append(ring_at+(across*cos(angle)+sideways*sin(angle))*ring_radius)
		tube(ring_path,0.014*option("stem_thickness",1.0),5,Color.WHITE,1.0)

		if biome_index==3:
			for leg in range(5):
				var dir := radial(leg*TAU/5)
				tube([dir*spread+Vector3.UP*0.025,dir*spread*0.6+Vector3.UP*height*0.18,hub],0.08*option("stem_thickness",1.0),0)
		for index in range(limb_count):
			var angle := growth_angle(index,limb_count)
			var dir := radial(angle)
			var tier := float(index)/maxi(1,limb_count-1)
			var fork_id := "trunk_joint%d"%index
			var fork: Vector3 = organ_positions[fork_id]
			# Biome and seeded individual habit control spread; every leader still rises.
			var reach := spread*spacing*(1.1-tier*0.25)*option("branch_reach",1.65)*(1.0+sin(angle*2.3+float(rng.seed%997))*option("branch_irregularity",0.25)*0.2)
			var habit := clampi(int(option("crown_habit",0)),0,2)
			reach*= (1.15-tier*0.5) if habit==0 else (1.08-tier*0.45) if habit==1 else (1.22-tier*0.55)
			var rise := deg_to_rad(option("branch_rise_degrees",[48.0,64.0,42.0,67.0][biome_index])+sin(index*1.7+float(rng.seed%997))*4.0)
			var tip := fork+dir*reach*cos(rise)+Vector3.UP*(reach*sin(rise)+height*tier*0.10)
			tip=spaced_branch_tip(fork,tip,0.072*option("stem_thickness",1.0),true)
			if not tip.is_finite(): continue
			var id := "canopy%d"%index
			var branch_path: Array[Vector3]=[fork]
			var branch_parent := fork_id
			var branch_radius := 0.05
			for socket in range(2):
				var t := (socket+1)/3.0
				var bend := sin(t*PI)
				var at := fork.lerp(tip,t)+Vector3.UP*bend*height*0.018
				at+=radial(angle+PI*0.5)*reach*option("branch_curve",0.05)*bend*sin(angle*1.7+phase)
				var socket_id := "branch_socket_%d_%d"%[index,socket]
				add_organ(socket_id,"Crown socket",at,branch_parent,branch_radius,branch_radius*0.8)
				branch_path.append(at)
				branch_parent=socket_id
				branch_radius*=0.8
			add_organ(id,"Crown exchange",tip,branch_parent,branch_radius,branch_radius*0.7)
			branch_path.append(tip)
			tube(branch_path,0.072*option("stem_thickness",1.0),0,Color.WHITE,0.45)
			stem_joint(fork,0.074*option("stem_thickness",1.0))
			for socket in range(2):
				var at: Vector3=branch_path[socket+1]
				var side := -1.0 if socket==0 else 1.0
				foliage_cluster(at,radial(angle+side*0.8,0.15+socket*0.1),0.55+0.12*sin(index*1.3+socket))
			var fork_depth:=clampi(int(option("tree_fork_depth",2)),0,4 if option("tree_fractal_growth",0.0)>0.0 else 2)
			# The stored midpoint is an exact point on both rendered conductor tubes.
			if fork_depth>0:
				grow_tree_forks(id,(tip-fork).normalized(),maxf(0.25,spread*0.32),fork_depth,0)
			else:
				foliage_cluster(links.back().path[1],dir,0.65)
				foliage_cluster(tip,dir,0.85)
			if biome_index==1:
				frond(tip,dir,0.8,0.35)
			elif biome_index==2:
				blade(tip,dir,0.35,0.18,2)
			elif biome_index==3:
				for curtain in range(2): blade(tip,radial(angle+curtain*0.7,-0.65),height*0.34,0.26,3)
			else:
				for fan in range(3): blade(tip,radial(angle+fan*0.8,0.1),0.7,0.45,0)
		return
	var intake := hub+Vector3.UP*height*0.25
	if role_index>1:
		add_organ("intake","Receiving surface",intake,"reserve",0.022)
		aperture(intake,Vector3.UP,0.14)
		var outlet := hub+Vector3(spread*0.35,0.08,0)
		add_organ("outlet","Release opening",outlet,"reserve",0.02)
		aperture(outlet,Vector3.RIGHT,0.075)
	var previous := "reserve"
	for index in range(count):
		var t := (index+1)/float(count)
		var angle := growth_angle(index,count)
		var dir := radial(angle)
		var at := hub+dir*spread*spacing
		var parent := "reserve"
		var kind := "Release tip" if role_index==0 else "Exchange node"
		var id := ("release%d" if role_index==0 else "node%d")%index
		match role_index:
			0:
				match biome_index:
					0: at = hub+radial(angle,0.18)*spread*spacing
					1: at = dir*spread*spacing+Vector3.UP*(0.05+0.13*sin(index))
					2:
						at = Vector3((t-0.5)*spread*2,0.15+height*absf(sin(index*1.8)),sin(index*2.0)*0.35)
						if index%3!=0: parent = previous
					3: at = dir*spread*0.45+Vector3.UP*height*(0.4+0.6*absf(sin(index*1.7)))
			2:
				match biome_index:
					0: at = hub+radial(index*0.95,0)*spread*t*spacing+Vector3.UP*height*t
					1: at = Vector3((t-0.5)*spread*1.6,height*(0.5+0.35*sin(t*PI)),0)
					2: at = hub+radial(angle,0.12)*spread*0.65
					3: at = dir*spread*0.55+Vector3.UP*height*(0.55+0.4*sin(index*1.9)*sin(index*1.9))
			3:
				match biome_index:
					0: at = hub+Vector3(cos(PI*t)*spread,height*sin(PI*t),0.1)
					1: at = dir*spread*0.85+Vector3.UP*height*0.7
					2: at = hub+radial(angle,0.5)*spread*0.65
					3: at = Vector3((t-0.5)*spread*2,height*(0.65+0.35*sin(t*PI)),(index%2)*0.25)
			4:
				match biome_index:
					0: at = dir*spread*(0.35+0.3*(index%2))+Vector3.UP*height*(0.3+0.65*t)
					1: at = Vector3((t-0.5)*spread*2,height*sin(PI*t)*0.65+height*0.25,0)
					2: at = dir*spread*sqrt(t)+Vector3.UP*height*(0.35+0.4*sin(t*PI))
					3: at = Vector3((t-0.5)*spread*2,height*(0.25+0.3*sin(t*PI)),sin(index)*0.3)
			5:
				match biome_index:
					0: at = radial(t*TAU*1.8)*spread*0.6+Vector3.UP*height*t
					1: at = Vector3(0,height*t,0)
					2: at = Vector3((0.45 if index%2==0 else -0.45)*spread,height*t,0)
					3: at = Vector3(sin(index*2.0)*spread,height*t,cos(index*2.4)*spread*0.5)
				parent = previous
		at=add_organ(id,kind,at,parent,0.018 if role_index!=3 else 0.03)
		previous = id
		aperture(at,Vector3.UP,0.055 if role_index==0 else 0.09)
		decorate_node(at,hub,dir,index,height,spread)
		if role_index>0: foliage_cluster(at,dir,0.45 if role_index==4 else 0.55)

func spaced_branch_tip(start: Vector3, proposed: Vector3, radius: float, optional: bool = false) -> Vector3:
	var delta := proposed-start
	if delta.length_squared()<0.000001: return proposed
	var sideways := delta.normalized().cross(Vector3.UP).normalized()
	if sideways.length_squared()<0.01: sideways=Vector3.RIGHT
	var selected := proposed
	var found := false
	for scale_factor in [1.0,0.85,0.7]:
		for angles: Vector2 in [Vector2.ZERO,Vector2(0.22,0),Vector2(-0.22,0),Vector2(0,0.16),Vector2(0,-0.16),Vector2(0.45,0.16),Vector2(-0.45,0.16),Vector2(0.75,0.28),Vector2(-0.75,0.28)]:
			var candidate: Vector3 = start+Basis(Vector3.UP,angles.x)*Basis(sideways,angles.y)*delta*scale_factor
			if delta.y>0.0 and candidate.y<=start.y: continue
			if branch_has_room(start,candidate,radius):
				selected=candidate
				found=true
				break
		if found: break
	if not found and not optional:
		# Functional organs keep their connections; search a wider growth envelope.
		for scale_factor in [1.15,1.4,1.8]:
			for yaw in [0.0,0.45,-0.45,0.9,-0.9,1.35,-1.35,2.2,-2.2,PI]:
				for pitch in [0.0,0.2,-0.2,0.45,-0.45,0.7,-0.7]:
					var candidate: Vector3=start+Basis(Vector3.UP,yaw)*Basis(sideways,pitch)*delta*scale_factor
					if candidate.y<minf(start.y,proposed.y): continue
					if branch_has_room(start,candidate,radius):
						selected=candidate
						found=true
						break
				if found: break
			if found: break
	if not found and optional: return Vector3.INF
	if not selected.is_equal_approx(proposed): repositioned_branches+=1
	var corridor := {"start":start,"end":selected,"radius":radius}
	var bounds := AABB(start,Vector3.ZERO).expand(selected).grow(radius+0.015)
	var index := branch_corridors.size()
	branch_corridors.append(corridor)
	for cell: Vector3i in triangle_cells(bounds):
		if not branch_cells.has(cell): branch_cells[cell]=[]
		branch_cells[cell].append(index)
	return selected

func branch_has_room(start: Vector3,finish: Vector3,radius: float) -> bool:
	var bounds := AABB(start,Vector3.ZERO).expand(finish).grow(radius+0.015)
	var visited := {}
	for cell: Vector3i in triangle_cells(bounds):
		for index: int in branch_cells.get(cell,[]):
			if visited.has(index): continue
			visited[index]=true
			var other: Dictionary=branch_corridors[index]
			var a := start
			var b := finish
			var c: Vector3=other.start
			var d: Vector3=other.end
			var clearance := radius+float(other.radius)+0.015
			var attachment := Geometry3D.get_closest_point_to_segment(a,c,d)
			if a.distance_to(attachment)<float(other.radius)*1.15 and a.distance_to(c)>clearance and a.distance_to(d)>clearance: continue
			# Adjacent tissues meet inside a shared fork collar, then separate.
			var collar := clearance*2.0
			if a.distance_to(c)<collar:
				a=a.move_toward(b,minf(collar,a.distance_to(b)*0.4))
				c=c.move_toward(d,minf(collar,c.distance_to(d)*0.4))
			elif a.distance_to(d)<collar:
				a=a.move_toward(b,minf(collar,a.distance_to(b)*0.4))
				d=d.move_toward(c,minf(collar,c.distance_to(d)*0.4))
			var closest := Geometry3D.get_closest_points_between_segments(a,b,c,d)
			if closest[0].distance_squared_to(closest[1])<clearance*clearance: return false
	return true

func stem_joint(at: Vector3,radius: float) -> void:
	if float(junction_radii.get(at,0.0))>=radius*0.95: return
	junction_radii[at]=radius
	var rings := 4 if radius>=0.04 else 3
	var sides := 6 if radius>=0.04 else 4
	for ring in range(rings):
		for segment in range(sides):
			var points: Array[Vector3]=[]
			var uvs: Array[Vector2]=[]
			for corner in [Vector2(ring,segment),Vector2(ring,segment+1),Vector2(ring+1,segment+1),Vector2(ring+1,segment)]:
				var latitude: float = PI*corner.x/rings
				var longitude: float = TAU*corner.y/sides
				points.append(at+radius*(radial(longitude)*sin(latitude)+Vector3.UP*cos(latitude)))
				var uv := Vector2(corner.y/sides,corner.x/rings)
				if tube_metric_uv: uv*=Vector2(TAU*radius,PI*radius)*2.0
				uvs.append(uv)
			quad(0,points,uvs,Color.WHITE)

func grow_tree_forks(parent_id: String,direction: Vector3,reach: float,depth: int,generation: int) -> void:
	var start: Vector3=organ_positions[parent_id]
	if role_index==1: stem_joint(start,0.024*pow(0.65,generation)*1.5*option("stem_thickness",1.0))
	var fractal := option("tree_fractal_growth",0.0)>0.0
	var opening:=option("tree_fork_spread",0.95)*pow(0.86,generation)
	for side in ([-1,0,1] if generation==0 else [-1,1]):
		var heading: Vector3=(direction.normalized().rotated(Vector3.UP,side*opening)+Vector3.UP*(0.18+generation*0.06)).normalized()
		var unequal: float=1.0+side*0.13+sin(start.y*2.7)*option("branch_irregularity",0.25)*0.2
		var tip: Vector3=start+heading*reach*unequal
		tip=spaced_branch_tip(start,tip,0.035*pow(0.65,generation)*option("stem_thickness",1.0),true)
		if not tip.is_finite(): continue
		var id:=parent_id+"_fork"+str(side+1)
		add_organ(id,"Branch fork",tip,parent_id,0.024*pow(0.65,generation)*option("stem_thickness",1.0))
		if generation==0 and (role_index==1 or not fractal): foliage_cluster(links.back().path[1],heading,0.55 if fractal else 0.72)
		if depth>1:
			grow_tree_forks(id,heading,reach*0.62,depth-1,generation+1)
		else:
			foliage_cluster(tip,heading,(0.7*pow(0.85,generation) if fractal and role_index==1 else maxf(0.15,reach*0.7) if fractal else 0.78*pow(0.8,generation)))

func decorate_node(at: Vector3,hub: Vector3,dir: Vector3,index: int,height: float,spread: float) -> void:
	var expression := option("role_expression",1.0)
	# Role surfaces belong to the existing exchange nodes; no extra reserves.
	if expression>0.0:
		match role_index:
			0:
				blossom(at,0.24*expression)
			2:
				for petal in range(4): blade(at,radial(petal*TAU/4,0.8),0.3*expression,0.22*expression,0,2)
			3:
				for shield in [-1,1]: blade(at,dir.rotated(Vector3.UP,shield*0.65)+Vector3.UP*0.3,0.4*expression,0.3*expression,0)
			4:
				for tendril in [-1,1]:
					var reach := dir.rotated(Vector3.UP,tendril*0.55)*0.35*expression
					tube([at,at+reach*0.6+Vector3.UP*0.12,at+reach-Vector3.UP*0.18],0.012,0)
			5:
				for vane in range(3): blade(at,radial(vane*TAU/3+index*0.6,0.25),0.3*expression,0.12*expression,3,2)
	match role_index:
		0:
			match biome_index:
				0: blade(hub,(at-hub).normalized(),hub.distance_to(at)*1.05,0.42,0)
				1:
					frond(at,dir,0.6,0.32)
					for side in [-1,1]: blade(hub.lerp(at,0.55),dir.rotated(Vector3.UP,side*0.8),0.28,0.14,1)
				2:
					for fork in [-1,1]: spine(at,dir.rotated(Vector3.UP,fork*0.8)+Vector3.UP,0.35)
					blade(hub.lerp(at,0.6),dir+Vector3.UP*0.3,0.3,0.2,2)
				3: blade(hub,(at-hub).normalized(),hub.distance_to(at),0.09,3)
		2:
			match biome_index:
				0: blade(at,dir+Vector3.UP*0.6,0.65,0.55,0)
				1:
					var end := at-Vector3.UP*height*0.25
					var id := "hanging%d"%index
					end=add_organ(id,"Receiving chamber",end,"node%d"%index,0.015)
					chamber(end,0.12,0.38,0)
					aperture(end,Vector3.DOWN,0.12)
				2: blade(at,dir+Vector3.UP*0.9,0.5,0.46,2)
				3:
					# Layered flared mouths, with stalks entering their narrow base.
					for tier in range(3): aperture(at+Vector3.UP*tier*0.12,Vector3.UP,0.12+tier*0.09)
		3:
			match biome_index:
				0: blade(hub,(at-hub).normalized(),hub.distance_to(at)*1.1,0.45,0)
				1:
					tube([hub,at+Vector3.UP*0.35,at,at*Vector3(1,0,1)+Vector3.UP*0.03],0.038,0)
					frond(at,dir-Vector3.UP,0.5,0.22)
				2:
					chamber(at,0.14,0.3,0)
					spine(at,dir+Vector3.UP*0.8,0.65)
				3: blade(at*Vector3(1,0,1),(at-at*Vector3(1,0,1)).normalized(),at.y,0.48,3)
		4:
			if biome_index==3:
				for wing in [-1,1]: blade(at,Vector3(wing,-0.1,0.2),0.65,0.27,3,2)
			else: blossom(at,0.33 if biome_index!=2 else 0.18)
			if biome_index==1: frond(hub,dir,0.4,0.2)
			elif biome_index==2: blade(hub,dir,0.4,0.22,2)
		5:
			match biome_index:
				0: blade(at,dir+Vector3.UP*0.4,0.35,0.14,0)
				1:
					for ring in range(5): blade(at,radial(ring*TAU/5,0.0),0.6,0.32,0)
				2:
					chamber(at,0.12,0.23,0)
					spine(at,dir+Vector3.UP,0.28)
				3:
					var end := at+dir*spread*0.45+Vector3.UP*0.15
					end=add_organ("branch%d"%index,"Side exchange",end,"node%d"%index,0.02)
					aperture(end,dir,0.1)
					blade(end,dir-Vector3.UP,0.45,0.14,3)

static func make_anatomy_materials() -> Array[Material]:
	var materials := make_materials()
	materials.resize(3)
	var bark := ShaderMaterial.new()
	bark.shader = preload("res://shaders/procedural_plant_foliage.gdshader")
	bark.set_shader_parameter("painted_atlas",preload("res://assets/nature/Bark_NormalTree.png"))
	bark.set_shader_parameter("authored_normal",preload("res://assets/nature/Bark_NormalTree_Normal.png"))
	bark.set_shader_parameter("bark_surface",true)
	bark.set_shader_parameter("palette_recolor",1.0)
	bark.set_shader_parameter("palette_gain",1.1)
	materials[0] = bark
	for index in [1,2]:
		materials[index].set_shader_parameter("palette_recolor",1.0)
		materials[index].set_shader_parameter("palette_gain",1.1)
	# Neutral tissue colors are diagnostic physical materials, never affinity cues.
	for color in [Color("c5b181"),Color("c9c2a6"),Color("bfa078")]:
		var tissue := StandardMaterial3D.new()
		tissue.albedo_color = color
		tissue.albedo_texture = preload("res://assets/nature/Bark_NormalTree.png")
		tissue.uv1_scale=Vector3(2.0,2.0,1.0)
		tissue.normal_enabled = true
		tissue.normal_texture = preload("res://assets/nature/Bark_NormalTree_Normal.png")
		tissue.normal_scale = 0.2
		tissue.roughness = 0.9
		tissue.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials.append(tissue)
	var leaf_cards := ShaderMaterial.new()
	leaf_cards.shader=preload("res://shaders/tree_leaf_cards.gdshader")
	leaf_cards.set_shader_parameter("painted_atlas",preload("res://assets/nature/Leaves.png"))
	materials.append(leaf_cards)
	return materials

func mesh_vertex_count(mesh: ArrayMesh) -> int:
	var total := 0
	for surface in range(mesh.get_surface_count()): total += mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size()
	return total

func foliage_cluster(at: Vector3, direction: Vector3, reach: float) -> void:
	if building_scaffold:
		pending_supports.append({"frond":false,"base":at,"direction":direction,"reach":reach})
		return
	# Repeated smaller forks attach to existing anatomy; no new ecological slots.
	var fullness := option("foliage_fullness",1.0)*(1.15 if role_index==1 else 1.0)
	if fullness<=0.0: return
	var depth := clampi(int(option("branching_depth",2)),0,3)
	if depth>0:
		branching_shoot(at,direction,reach,depth,fullness)
	else:
		terminal_foliage(at,direction,reach,clampi(ceili(3.0*fullness*sqrt(foliage)),1,5))

func branching_shoot(base: Vector3,direction: Vector3,reach: float,depth: int,fullness: float) -> void:
	var forward := direction.normalized()
	var phase := sin(base.dot(Vector3(2.7,1.3,3.1))+depth*1.7)
	var up := Vector3.UP*(0.16 if role_index==1 else (0.12 if biome_index!=3 else -0.12))
	var tip := spaced_branch_tip(base,base+forward*reach+up*reach,reach*0.033,true)
	if not tip.is_finite(): return
	forward=(tip-base).normalized()
	var middle := base.lerp(tip,0.5)+Vector3.UP*reach*0.12*organic_softness
	var path: Array[Vector3] = [base,tip]
	if depth>1: path.insert(1,middle)
	var radius := reach*0.023
	tube(path,radius*1.4,0)
	stem_joint(base,radius*1.5)
	tube(path,radius*0.7,3)
	foliage_branches.append({"from":base,"to":tip,"depth":depth,"length":reach})
	# Fill the shoot itself, so recursive forks retain a leafy crown instead of
	# concentrating every blade on the smallest terminal twigs.
	if depth>1:
		var attachment := base.lerp(tip,0.55)
		for side in [-1.0,1.0]:
			var heading := forward.rotated(Vector3.UP,side*0.9)+Vector3.UP*0.25
			blade(attachment,heading,reach*0.95,reach*(0.65 if biome_index!=3 else 0.35),-1,1,3)
	if depth<=1:
		if role_index==1:
			for along in [0.35,0.7]:
				for side in [-1.0,1.0]:
					var leaf_direction := radial(atan2(forward.z,forward.x)+side*0.9,0.2)
					if option("tree_leaf_cards",1.0)>0.5: leaf_card(base.lerp(tip,along),leaf_direction,reach*1.3,reach*0.8)
					else: blade(base.lerp(tip,along),leaf_direction,reach*1.3,reach*0.8,-1,1,3)
		terminal_foliage(tip,forward,reach*1.5,clampi(ceili(fullness*sqrt(foliage))+(2 if role_index==1 else 0),1,5 if role_index==1 else 3))
		return
	var spread := option("branching_spread",0.75)
	var reduction := option("branching_reduction",0.62)
	var axis := forward.cross(Vector3.UP if absf(forward.y)<0.9 else Vector3.RIGHT).normalized()
	for side in [-1.0,1.0]:
		var child := forward.rotated(axis,side*spread).rotated(forward,phase*0.5+depth*0.65)
		branching_shoot(tip,child,reach*reduction,depth-1,fullness)

func terminal_foliage(at: Vector3,direction: Vector3,reach: float,amount: int) -> void:
	for leaf_index in range(amount):
		var fan := (leaf_index-(amount-1)*0.5)*(1.2 if role_index==1 else 0.9)
		var heading := direction.rotated(Vector3.UP,fan)+Vector3.UP*(0.15+0.15*sin(leaf_index*2.1))
		var length := reach*(0.8+0.15*sin(leaf_index*2.4+at.y))
		# Alternate rising and spreading leaves, as in the approved ground foliage.
		if role_index==1:
			var phase := sin(at.dot(Vector3(0.7,0.4,0.9)))
			heading=radial(atan2(direction.z,direction.x)+fan+phase*0.35,0.1+sin(leaf_index*1.7+phase)*0.45)
			length*=0.75+0.35*(0.5+0.5*sin(at.y+leaf_index*2.3))
		if role_index==1 and option("tree_leaf_cards",1.0)>0.5:
			leaf_card(at,heading,length,length*(0.75 if biome_index!=3 else 0.32))
		else:
			blade(at,heading,length,length*(0.65 if biome_index!=3 else 0.35),-1,1,3 if role_index==1 else 6)

func leaf_card(at: Vector3,direction: Vector3,length: float,width: float) -> void:
	pending_leaves.append({"base":at,"direction":direction,"length":length,"width":width,"card":true})

func emit_leaf_card(at: Vector3,direction: Vector3,length: float,width: float) -> void:
	var forward := direction.normalized()
	var side := forward.cross(Vector3.UP if absf(forward.y)<0.9 else Vector3.FORWARD).normalized()
	var tip := at+forward*length*leaf_scale
	var half_width := side*width*leaf_scale*option("leaf_width",1.0)*0.5
	# Two triangles carry a painted cutout; no camera-facing billboard rotation.
	quad(6,[at-half_width,at+half_width,tip+half_width,tip-half_width],[Vector2(0,1),Vector2(1,1),Vector2(1,0),Vector2(0,0)],pigment)

## Resolve rigid leaf orientations after all structural tissue exists. Roots and
## connected organ joints intentionally meet; free leaf surfaces must find room.
## No stretching, detached bases or rerolling of the structural graph is allowed.
func leaf_attachment_candidates(base: Vector3) -> Array[Vector3]:
	var candidates: Array[Vector3]=[base]
	var nearest := INF
	var support: Dictionary={}
	for branch: Dictionary in branch_corridors:
		var point := Geometry3D.get_closest_point_to_segment(base,branch.start,branch.end)
		var distance := base.distance_squared_to(point)
		if distance<nearest and distance<pow(float(branch.radius)+0.04,2):
			nearest=distance
			support=branch
	if support.is_empty(): return candidates
	var point := Geometry3D.get_closest_point_to_segment(base,support.start,support.end)
	var offset := minf(0.08,support.start.distance_to(support.end)*0.1)
	for endpoint: Vector3 in [support.start,support.end]:
		candidates.append(point.move_toward(endpoint,offset)+(base-point))
	return candidates

func flush_leaves() -> void:
	for request: Dictionary in pending_leaves:
		var accepted := false
		collecting_leaf=true
		leaf_quads.clear()
		if request.card: emit_leaf_card(request.base,request.direction,request.length,request.width)
		else: emit_blade(request.base,request.direction,request.length,request.width,request.style,request.surface,request.segments)
		collecting_leaf=false
		var original_quads := leaf_quads.duplicate(true)
		for base: Vector3 in leaf_attachment_candidates(request.base):
			for angles: Vector2 in [Vector2.ZERO,Vector2(0.18,0),Vector2(-0.18,0),Vector2(0,0.18),Vector2(0,-0.18),Vector2(0.35,0.22),Vector2(-0.35,0.22),Vector2(0.35,-0.22),Vector2(-0.35,-0.22),Vector2(0.6,0.35),Vector2(-0.6,0.35),Vector2(0.75,-0.45),Vector2(-0.75,-0.45)]:
				var heading: Vector3=request.direction.normalized().rotated(Vector3.UP,angles.x)
				var axis := heading.cross(Vector3.UP).normalized()
				if axis.length_squared()<0.01: axis=Vector3.RIGHT
				var rotation := Basis(axis,angles.y)*Basis(Vector3.UP,angles.x)
				leaf_quads.clear()
				for original: Dictionary in original_quads:
					var part := original.duplicate()
					var points: Array[Vector3]=[]
					for point: Vector3 in original.points: points.append(base+rotation*(point-request.base))
					part.points=points
					leaf_quads.append(part)
				if not leaf_has_room(base,maxf(0.015,request.length*leaf_scale*0.12)): continue
				for part: Dictionary in leaf_quads:
					quad(part.surface,part.points,part.uvs,part.tint)
				if role_index == 1: register_leaf_outlet(base)
				accepted=true
				break
			if accepted: break
		# An optional crowded blade is left out instead of being squashed or torn.
		if not accepted: omitted_leaves+=1
	leaf_quads.clear()
	pending_leaves.clear()

func register_leaf_outlet(base: Vector3) -> void:
	# Record a real accepted leaf surface, including its collision-avoidance rotation.
	var parent_id := ""
	var nearest := INF
	for organ: Dictionary in organs:
		if organ.kind not in ["Crown exchange","Crown socket","Branch fork"]: continue
		var distance: float = base.distance_squared_to(organ.position)
		if distance < nearest:
			nearest = distance
			parent_id = organ.id
	if parent_id.is_empty(): return
	var surface := Vector3.ZERO
	var vertices := 0
	for part: Dictionary in leaf_quads:
		for point: Vector3 in part.points:
			surface += point
			vertices += 1
	if vertices == 0: return
	# The blade center stays inside painted cutouts; card corners can be transparent.
	surface /= float(vertices)
	# Presentation anchors add no tissue, reserve, randomness or simulation node.
	# Every accepted blade has an outlet, even when many share one branch socket.
	var leaf_id := str(leaf_surfaces.size()/2)
	var petiole := "petiole_" + leaf_id
	var outlet := "leaf_" + leaf_id
	leaf_surfaces.append({"id":petiole,"kind":"Leaf attachment","position":base,"parent":parent_id})
	leaf_surfaces.append({"id":outlet,"kind":"Leaf release","position":surface,"parent":petiole})

func quad(surface: int, points: Array[Vector3], uvs: Array[Vector2], tint: Color) -> void:
	if collecting_leaf:
		leaf_quads.append({"surface":surface,"points":points,"uvs":uvs,"tint":tint})
		return
	super.quad(surface,points,uvs,tint)
	if surface not in [0,1,2,6]: return
	for indices: Vector3i in [Vector3i(0,2,1),Vector3i(0,3,2)]:
		var triangle := PackedVector3Array([points[indices.x],points[indices.y],points[indices.z]])
		var bounds := triangle_bounds(triangle)
		var id := spacing_triangles.size()
		spacing_triangles.append(triangle)
		spacing_bounds.append(bounds)
		for cell: Vector3i in triangle_cells(bounds):
			if not surface_cells.has(cell): surface_cells[cell]=[]
			surface_cells[cell].append(id)

func leaf_has_room(base: Vector3, attachment_radius: float) -> bool:
	for part: Dictionary in leaf_quads:
		if part.surface not in [1,2,6]: continue
		for indices: Vector3i in [Vector3i(0,2,1),Vector3i(0,3,2)]:
			var triangle := PackedVector3Array([part.points[indices.x],part.points[indices.y],part.points[indices.z]])
			# Permit the small shared petiole/organ attachment, never the leaf body.
			if (triangle[0]+triangle[1]+triangle[2]).distance_to(base*3.0)<attachment_radius*3.0: continue
			var bounds := triangle_bounds(triangle)
			var visited := {}
			for cell: Vector3i in triangle_cells(bounds):
				for id: int in surface_cells.get(cell,[]):
					if visited.has(id): continue
					visited[id]=true
					if not bounds.intersects(spacing_bounds[id]): continue
					if triangles_cross(triangle,spacing_triangles[id],base,attachment_radius): return false
	return true

static func triangle_bounds(triangle: PackedVector3Array) -> AABB:
	return AABB(triangle[0],Vector3.ZERO).expand(triangle[1]).expand(triangle[2]).grow(0.0001)

static func triangle_cells(bounds: AABB) -> Array[Vector3i]:
	var cells: Array[Vector3i]=[]
	var low := Vector3i((bounds.position*2.0).floor())
	var high := Vector3i((bounds.end*2.0).floor())
	for z in range(low.z,high.z+1):
		for y in range(low.y,high.y+1):
			for x in range(low.x,high.x+1): cells.append(Vector3i(x,y,z))
	return cells

static func triangles_cross(a: PackedVector3Array,b: PackedVector3Array,attachment: Vector3=Vector3.ZERO,attachment_radius: float=-1.0) -> bool:
	for index in range(3):
		var hit: Variant=Geometry3D.segment_intersects_triangle(a[index],a[(index+1)%3],b[0],b[1],b[2])
		if hit!=null and hit.distance_to(attachment)>attachment_radius: return true
		hit=Geometry3D.segment_intersects_triangle(b[index],b[(index+1)%3],a[0],a[1],a[2])
		if hit!=null and hit.distance_to(attachment)>attachment_radius: return true
	# Parallel/copanar faces need a 2D check; segment/triangle alone misses them.
	var normal := (a[1]-a[0]).cross(a[2]-a[0]).normalized()
	if normal.length_squared()<0.5: return false
	for point: Vector3 in b:
		if absf(normal.dot(point-a[0]))>0.00001: return false
	var u := (a[1]-a[0]).normalized()
	var v := normal.cross(u)
	var aa := PackedVector2Array()
	var bb := PackedVector2Array()
	for point: Vector3 in a: aa.append(Vector2(point.dot(u),point.dot(v)))
	for point: Vector3 in b: bb.append(Vector2(point.dot(u),point.dot(v)))
	for i in range(3):
		if Geometry2D.is_point_in_polygon(aa[i],bb) and a[i].distance_to(attachment)>attachment_radius: return true
		if Geometry2D.is_point_in_polygon(bb[i],aa) and b[i].distance_to(attachment)>attachment_radius: return true
		for j in range(3):
			var hit: Variant=Geometry2D.segment_intersects_segment(aa[i],aa[(i+1)%3],bb[j],bb[(j+1)%3])
			if hit!=null:
				var world_hit: Vector3=u*hit.x+v*hit.y+normal*normal.dot(a[0])
				if world_hit.distance_to(attachment)>attachment_radius: return true
	return false
