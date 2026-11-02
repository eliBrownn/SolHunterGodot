extends "res://scripts/scenery/plant_vastra_anatomy_mesh.gd"
## Shared foliage morphology. Receiver anatomy is a draft, not population admission.
const FORMS := [
	["Open fan", "Low rosette", "Cupped leaves", "Branching spray", "Folded cluster"],
	["Divided frond", "Layered leaves", "Hanging folds", "Arching stems", "Broad shade leaves"],
	["Compact cushion", "Curled thick leaves", "Overlapping scales", "Twisted low branches", "Upright folds"],
	["Upright sails", "Ribbon leaves", "Hollow sheaths", "Overlapping cups", "Arching narrow leaves"]
]
var variation := 0
var leaf_grass := false

func create_sample(biome: int, role: int, specimen_seed: int, settings: Dictionary, materials: Array[Material]) -> Dictionary:
	variation = clampi(int(settings.get("foliage_variation",0)),0,4)
	leaf_grass=bool(settings.get("groundcover_detail",false))
	var configured := settings.duplicate()
	configured["color_diversity"] = 0.0
	configured["hue_shift"] = clampf(float(settings.get("hue_shift",0)), -10,10)
	var result := super.create_sample(biome,0 if role==0 else 2,specimen_seed,configured,materials)
	result["growth_category"] = "generic_foliage"
	result["growth_plan"] = FORMS[biome][variation]
	result["variation"] = variation
	return result

func quad(surface: int, points: Array[Vector3], uvs: Array[Vector2], tint: Color) -> void:
	# Leaf grass keeps its connected graph without exposing woody shrub anatomy.
	if leaf_grass and surface!=1: return
	super.quad(surface,points,uvs,tint)

func build_growth_plan(height: float, spread: float) -> void:
	# The same connected basal graph supports every form. No specialist ornaments.
	height *= [0.8,1.0,0.5,1.0][biome_index]
	var hub: Vector3 = organ_positions.reserve
	var intake := hub+Vector3.UP*height*0.13
	if role_index==0: intake=Vector3(0,0.035,0)
	add_organ("intake","Ground intake" if role_index==0 else "Receiving surface",intake,"reserve",0.018)
	if not leaf_grass: aperture(intake,Vector3.UP,0.055)
	var outlet := hub+Vector3(spread*0.10,0.015,0)
	add_organ("outlet","Emanating opening" if role_index==0 else "Release opening",outlet,"reserve",0.012)
	if not leaf_grass: aperture(outlet,Vector3.RIGHT,0.035)
	if option("groundcover_detail",0.0)>0.0:
		for index in range(branches):
			var direction := radial(growth_angle(index,branches))
			var base := direction*rng.randf_range(0.015,0.08)+Vector3.UP*0.025
			var heading := direction*rng.randf_range(0.25,0.5)+Vector3.UP
			var length := height*rng.randf_range(0.9,1.35)
			base=add_organ("grass_leaf%d"%index,"Leaf conductor",base,"intake",0.004)
			blade(base,heading,length,length*0.3,0)
		return
	# Pinnate fronds retain the same basal owner and connected leaf conductors.
	# This explicit morphology is opt-in; ordinary and leaf-grass defaults stay put.
	if option("fern_growth",0.0)>0.5:
		for index in range(clampi(branches,3,10)):
			var direction := radial(growth_angle(index,branches))
			var base := hub+direction*spread*0.05
			base=add_organ("frond%d"%index,"Frond conductor",base,"reserve",0.009)
			frond(base,direction+Vector3.UP*(0.45+0.35*sin(index*1.7)),spread*(0.9+0.15*sin(index*2.3)),spread*0.40)
		return
	var count := clampi(int(branches*sqrt(maxf(0.0,foliage))*option("foliage_fullness",1.0)),3,12)
	var previous := "reserve"
	for index in range(count):
		var t := (index+1.0)/count
		var direction := radial(growth_angle(index,count))
		var reach := spread*rng.randf_range(0.82,1.08)
		var at := hub+direction*reach*0.4
		var parent := "reserve"
		# Five distinct scaffold arrangements, then habitat-specific leaf tissue.
		match variation:
			0: at = hub+direction*reach*0.45+Vector3.UP*height*0.15
			1: at = direction*reach*0.28+Vector3.UP*(0.10+height*t*0.45)
			2: at = hub+direction*reach*0.35+Vector3.UP*height*(0.25+0.35*t)
			3:
				at = direction*reach*(0.2+0.5*t)+Vector3.UP*height*sin(t*PI)*0.6
				if index%3!=0: parent=previous
			4: at = hub+direction*reach*0.18+Vector3.UP*height*(0.25+0.6*t)
		if biome_index==2: at.y=0.08+(at.y-0.08)*0.5
		if biome_index==3: at=at*Vector3(0.55,1.0,0.55)+Vector3.UP*height*0.20
		var id := "leaf_joint%d"%index
		at=add_organ(id,"Leaf conductor",at,parent,0.012)
		previous=id
		var length: float = reach*[0.65,0.55,0.5,0.42,0.65][variation]
		var rise: float = [0.2,-0.12,0.75,0.35,1.1][variation]
		var heading := direction+Vector3.UP*rise
		match biome_index:
			0:
				blade(at,heading,length*1.2,0.40 if variation!=4 else 0.22,0)
				blade(hub.lerp(at,0.55),heading.rotated(Vector3.UP,-0.45),length*0.85,0.26,0)
				if variation in [2,4]: blade(at,heading.rotated(Vector3.UP,0.4),length*0.9,0.22,0)
			1:
				if variation==0: frond(at,heading,length*1.3,0.38)
				elif variation==2:
					blade(at,direction-Vector3.UP*0.8,length,0.20,3)
				else:
					blade(at,heading,length,0.35 if variation==4 else 0.22,0)
					blade(at,heading.rotated(Vector3.UP,0.7),length*0.75,0.18,0)
			2:
				blade(at,heading,length*0.85,0.28,2)
				blade(at,heading.rotated(Vector3.UP,0.45),length*0.75,0.24,2)
				blade(hub.lerp(at,0.5),heading.rotated(Vector3.UP,-0.5),length*0.65,0.22,2)
				if variation==0: chamber(at,0.055,0.07,1)
			3:
				if variation in [2,3]:
					# A connected sheath ending in a modest living lip.
					var tip: Vector3 = spaced_branch_tip(at,at+Vector3.UP*length*0.6,0.085,true)
					if not tip.is_finite(): continue
					add_organ(id+"_sheath","Sheath conductor",tip,id,0.012)
					tube([at,at.lerp(tip,0.5),tip],0.085,1,Color.WHITE,0.8)
					aperture(tip,Vector3.UP,0.085 if variation==2 else 0.13)
					blade(at,direction+Vector3.UP*0.5,length,0.10,3)
				else:
					blade(at,heading+Vector3.UP*0.7,length*1.4,0.26 if variation==0 else 0.10,3)
					blade(hub.lerp(at,0.6),heading.rotated(Vector3.UP,0.45)+Vector3.UP*0.6,length,0.16 if variation==0 else 0.07,3)
