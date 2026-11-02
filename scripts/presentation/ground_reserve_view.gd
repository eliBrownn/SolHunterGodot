extends RefCounted
## Bounded read-only visual map. Geographic cells own reserves; terrain owns no energy.
const SIZE := 128
static var materials: Dictionary = {}
var image: Image
var texture: ImageTexture
var origin := Vector2i.ZERO
var state_id := 0
var cursor := 0
var last_tick := -1
var remaining := 0
var uploads := 0

static func register(material: ShaderMaterial) -> void:
	materials[material.get_instance_id()] = weakref(material)

func reset(at: Vector2i) -> void:
	origin = at
	image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBAF)
	image.fill(Color(1,1,-1,0))
	if texture == null: texture = ImageTexture.create_from_image(image)
	cursor = 0
	remaining = SIZE * SIZE

func move_window(at: Vector2i) -> void:
	var old := image
	var old_origin := origin
	reset(at)
	var overlap := Rect2i(at, Vector2i(SIZE,SIZE)).intersection(Rect2i(old_origin,Vector2i(SIZE,SIZE)))
	if overlap.has_area():
		image.blit_rect(old,Rect2i(overlap.position-old_origin,overlap.size),overlap.position-at)

func update(state: ExpeditionState, focus: Vector2i, settings: NatureSettings, limit: int = 256) -> void:
	var at := Vector2i(WorldTerrain.floor_div(focus.x,16)*16,WorldTerrain.floor_div(focus.y,16)*16)-Vector2i(SIZE/2,SIZE/2)
	var dirty := false
	if state_id != state.get_instance_id():
		state_id = state.get_instance_id()
		reset(at)
		last_tick = -1
		dirty = true
	elif origin != at:
		move_window(at)
		dirty = true
	var refill_step := floori(state.activity_seconds()/(ExpeditionContract.ACTIVITY_INTERVAL/6.0))
	if last_tick != refill_step:
		last_tick = refill_step
		remaining = SIZE * SIZE
	var seconds := state.activity_seconds()
	for index in range(mini(clampi(limit,1,256),remaining)):
		remaining -= 1
		var pixel := Vector2i(cursor % SIZE, cursor / SIZE)
		cursor = (cursor + 1) % (SIZE * SIZE)
		var fraction := state.flora_reserve_fraction(origin + pixel)
		var previous := image.get_pixelv(pixel)
		if fraction < 0.0:
			if previous.a > 0.5:
				image.set_pixelv(pixel,Color(1,1,-1,0))
				dirty = true
			continue
		fraction = clampf(fraction,0.0,1.0)
		if previous.a > 0.5 and is_equal_approx(previous.g,fraction): continue
		var blend := smoothstep(0.0,settings.reserve_transition_seconds,maxf(0.0,seconds-previous.b))
		var shown := lerpf(previous.r,previous.g,blend) if previous.a > 0.5 else fraction
		image.set_pixelv(pixel,Color(shown,fraction,seconds,1))
		dirty = true
	if dirty:
		texture.update(image)
		uploads += 1
	for id in materials.keys():
		var material: ShaderMaterial = materials[id].get_ref()
		if material == null:
			materials.erase(id)
			continue
		var signature := [get_instance_id(),origin,settings.reserve_saturation_floor,settings.reserve_transition_seconds]
		if material.get_meta("ground_reserve_binding",[]) != signature:
			material.set_meta("ground_reserve_binding",signature)
			material.set_shader_parameter("ground_reserve_map",texture)
			material.set_shader_parameter("ground_reserve_origin",Vector2(origin))
			material.set_shader_parameter("ground_reserve_enabled",true)
			material.set_shader_parameter("ground_reserve_saturation_floor",settings.reserve_saturation_floor)
			material.set_shader_parameter("ground_reserve_transition_seconds",settings.reserve_transition_seconds)
		material.set_shader_parameter("ground_reserve_seconds",seconds)
