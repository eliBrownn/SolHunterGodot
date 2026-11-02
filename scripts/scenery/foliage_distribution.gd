extends RefCounted
## Version-one visual communities on existing canonical cells. Never admits flora.
## Absolute geographic patches, independent of render chunks and query order.
const PATCH_CELLS := 16
const WIDTHS := [0.8,0.9,0.6,0.6]
static var fields: Dictionary = {}

static func proposal(terrain: WorldTerrain, cell: Vector2i, data: Dictionary, coverage: float, owned_field: FastNoiseLite = null) -> Dictionary:
	if coverage<=0.0 or data.ground not in [0,1,2,3]: return {}
	if owned_field == null and not fields.has(terrain.world_seed):
		if fields.size()>=4: fields.clear()
		var field := FastNoiseLite.new()
		field.seed=terrain.world_seed
		field.frequency=0.075
		fields[terrain.world_seed]=field
	var field: FastNoiseLite=owned_field if owned_field != null else fields[terrain.world_seed]
	var patch_cells := roundi(float(terrain.community_parameters.patch_size)*1.6)
	var region := Vector2i(WorldTerrain.floor_div(cell.x,patch_cells),WorldTerrain.floor_div(cell.y,patch_cells))
	var patch := region
	var weight := 0.0
	for y in range(-1,2):
		for x in range(-1,2):
			var owner := region+Vector2i(x,y)
			var center := (Vector2(owner)+Vector2(0.25+float(terrain.roll(owner,78201)%1000)/2000.0,0.25+float(terrain.roll(owner,78203)%1000)/2000.0))*patch_cells
			var radius := (0.375+float(terrain.roll(owner,78205)%600)/1600.0)*patch_cells
			var edge := field.get_noise_2d(cell.x,cell.y)*1.8
			var strength := clampf(1.0-(Vector2(cell)+Vector2(0.5,0.5)).distance_to(center)/(radius+edge),0.0,1.0)
			if strength>weight:
				weight=strength
				patch=owner
	var wetness := lerpf(float(data.get("wetness",terrain.wetness_at(cell))),terrain.community_drainage(cell),float(terrain.community_parameters.drainage_influence))
	# Continuous environmental preferences blend visual density at biome edges.
	var suitability := lerpf(0.6,1.0,wetness)
	if data.ground==2: suitability=lerpf(1.0,0.45,wetness)
	var bank := clampf((1.9-terrain.lake_distance(cell))/0.65,0.0,1.0)
	if data.ground in [1,3]: suitability=lerpf(suitability,1.0,bank)
	var density := clampf(coverage,0.0,1.0)*(0.025+weight*0.80)*suitability*float(terrain.community_parameters.coverage)/0.65
	if float(terrain.roll(cell,78207)%10000)/10000.0>=density: return {}
	# Existing nearby tree anchors influence understory; no new canopy population.
	var canopy := 0
	for offset in [Vector2i(2,0),Vector2i(-2,0),Vector2i(0,2),Vector2i(0,-2)]:
		if terrain.community_tree(cell+offset): canopy+=1
	if canopy>0 and terrain.roll(cell,78217)%100<int(canopy*8*float(terrain.community_parameters.canopy_influence)/0.65): return {}
	var base := terrain.roll(patch,78209)%5
	var variation: int = (base+[0,1,3][terrain.roll(cell,78211)%3])%5
	var size := lerpf(0.45,1.35,float(terrain.roll(cell,78213)%10001)/10000.0)
	return {"biome":int(data.ground),"variation":variation,"scale":size,"patch_id":patch,"weight":weight,"canopy":canopy,"bank":bank,"priority":terrain.roll(cell,78215),"radius":WIDTHS[data.ground]*size*0.5+0.24}

static func has_space(terrain: WorldTerrain,cell: Vector2i,current: Dictionary,coverage: float, owned_field: FastNoiseLite = null) -> bool:
	# Two cells cover the maximum combined footprint, including sway allowance.
	for y in range(-2,3):
		for x in range(-2,3):
			if x==0 and y==0: continue
			var at := cell+Vector2i(x,y)
			if Vector2(x,y).length()>=float(current.radius)+0.74: continue
			var data := terrain.sample(at)
			if terrain.flora_kind(at,data)!="plant": continue
			var traits := FloraTraits.describe(terrain.world_seed,{"id":FloraCatalog.id_for(at),"cell":[at.x,at.y],"kind":"plant"},terrain.flora_specialist_percent)
			if traits.role!="emanator": continue
			var other := proposal(terrain,at,data,coverage,owned_field)
			if other.is_empty() or Vector2(x,y).length()>=float(current.radius)+float(other.radius): continue
			if other.priority>current.priority or (other.priority==current.priority and (at.x<cell.x or (at.x==cell.x and at.y<cell.y))): return false
	return true
