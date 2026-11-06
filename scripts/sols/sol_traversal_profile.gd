class_name SolTraversalProfile
extends Resource
## Admitted movement capability; independent of an individual's affinity.
@export_enum("ground", "flight", "swim") var kind := "ground"
## Flight rig-root height above ground/water, in metres; the sweep also reserves downstroke space.
@export_range(0.5, 1.5, 0.05) var altitude := 0.8
## Swimming body-root depth below the waterline, in metres.
@export_range(0.05, 0.3, 0.01) var draft := 0.18
## Conservative half-width of the complete creature, including appendages, in metres.
@export_range(0.1, 0.8, 0.01) var radius := 0.55
## Conservative body/appendage height above its root, in metres.
@export_range(0.3, 1.2, 0.05) var height := 0.65
## Maximum supported bank-to-water height difference, in metres.
@export_range(0.1, 0.6, 0.05) var shore_step := 0.4

func snapshot() -> Dictionary:
	return {"kind": kind, "altitude": altitude, "draft": draft, "radius": radius, "height": height, "shore_step": shore_step}

func valid() -> bool:
	return valid_policy(snapshot())

static func exact_keys(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

static func whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floor(float(value)) and value >= low and value <= high

static func valid_policy(value: Variant) -> bool:
	if not value is Dictionary or not exact_keys(value, ["kind", "altitude", "draft", "radius", "height", "shore_step"]) or value.kind not in ["ground", "flight", "swim"]:
		return false
	for row in [["altitude", 0.5, 1.5], ["draft", 0.05, 0.3], ["radius", 0.1, 0.8], ["height", 0.3, 1.2], ["shore_step", 0.1, 0.6]]:
		var number: Variant = value[row[0]]
		if (not number is float and not number is int) or not is_finite(float(number)) or number < row[1] or number > row[2]:
			return false
	return true

static func valid_state(value: Variant, tick: int, cell: Array) -> bool:
	if cell.size() != 2 or not whole(cell[0], -1000000, 1000000) or not whole(cell[1], -1000000, 1000000):
		return false
	if not value is Dictionary or not exact_keys(value, ["policy", "mode", "mode_tick", "from", "settle"]) or not valid_policy(value.policy) or value.policy.kind == "ground" or not value.settle is bool:
		return false
	var modes := ["ground", "takeoff", "air", "landing"] if value.policy.kind == "flight" else ["ground", "swim_enter", "wade", "swim", "swim_exit"]
	if value.mode not in modes or not whole(value.mode_tick, 0, tick) or not value.from is Array or value.from.size() != 2:
		return false
	for coordinate in value.from:
		if not whole(coordinate, -1000000, 1000000):
			return false
	return absi(int(value.from[0]) - int(cell[0])) + absi(int(value.from[1]) - int(cell[1])) <= 1
