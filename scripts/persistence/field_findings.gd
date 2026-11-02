class_name FieldFindings
extends RefCounted
## Durable authored knowledge, separate from the bounded recent-sighting feed.
## Stored evidence is immutable; text/interpretation belongs to the authored catalog.
const CATALOG := {
	"plant_reserve": ["Living reserves", "A plant's stored energy is distinct from damage. Compare reserves before interpreting a sparse patch."],
	"water_approach": ["Waterside approach", "This bank can be approached on foot. Watch from dry ground before choosing a closer approach."],
	"circulation": ["Energy in transit", "A transfer connects actual plant reserves. Follow its endpoints rather than treating every bright strand as a warning."],
	"warning": ["Disturbance warning", "This place had an active warning. Inspect its current conditions before crossing; a remembered warning is not proof it remains dangerous."],
	"companion_listen": ["A companion's listening place", "Your companion can help read a visible local Sol from outside close approach distance. Watch its posture before deciding whether to approach or leave."],
	"companion_inspect": ["A companion's inspection place", "Your companion inspected the nearby plant. Compare its current reserve before deciding whether to wait or move on."]}

static func valid(data: Variant, tick: int) -> bool:
	if not data is Dictionary or data.size() > CATALOG.size(): return false
	for id in data:
		if not CATALOG.has(id): return false
		var row: Variant = data[id]
		if not row is Dictionary or not RecordShape.keys_match(row, ["cell", "tick", "source", "target", "value", "observation"]): return false
		if not row.cell is Array or row.cell.size() != 2: return false
		for coordinate in row.cell:
			if not SolSpeciesDefinition.whole(coordinate, -1000000, 1000000): return false
		if not SolSpeciesDefinition.whole(row.tick, 0, tick): return false
		if not row.source is String or row.source.is_empty() or row.source.length() > 160: return false
		var individual := SolIdentityContract.parse(row.source)
		var observed_cell := Vector2i(int(row.cell[0]), int(row.cell[1]))
		if individual.is_empty() and row.source != AffinityImprint.key(observed_cell): return false
		if id in ["companion_listen", "companion_inspect"] and individual.is_empty(): return false
		if id in ["plant_reserve", "water_approach", "circulation"] and not individual.is_empty(): return false
		if not row.target is String or row.target.length() > 160: return false
		var target_individual := SolIdentityContract.parse(row.target)
		if target_individual.is_empty() and not VastraCombat.valid_key(row.target): return false
		if id == "companion_listen" and (target_individual.is_empty() or row.target == row.source): return false
		if id in ["plant_reserve", "water_approach", "circulation", "companion_inspect"] and not target_individual.is_empty(): return false
		if id == "companion_inspect" and row.target != AffinityImprint.key(observed_cell): return false
		if not row.observation is String or row.observation.length() > 160: return false
		if not (row.value is float or row.value is int) or not is_finite(float(row.value)) or row.value < 0 or row.value > 1000000: return false
	return true

static func entries(data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in CATALOG:
		if not data.has(id): continue
		var row: Dictionary = data[id]
		var details: Array[String] = []
		match id:
			"plant_reserve", "companion_inspect": details.append("Observed plant reserve: %.1f Vastra." % float(row.value))
			"circulation":
				details.append("Observed transfer: %.1f Vastra in transit." % float(row.value))
				details.append("Recorded recipient: " + row.target.replace(":", ", "))
			"water_approach": details.append("An observation approach from dry ground.")
			"companion_listen": details.append("Your companion listened beside the visible local Sol.")
			"warning": details.append("A local Sol defended its territory." if not SolIdentityContract.parse(row.source).is_empty() else "Local conditions showed a disturbance warning.")
		if not row.observation.is_empty(): details.append(row.observation)
		result.append({"key": id, "title": CATALOG[id][0], "category": "Learned finding",
			"description": CATALOG[id][1], "details": details,
			"first_seen": row.cell.duplicate()})
	return result
