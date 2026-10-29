class_name SolIdentityContract
extends RefCounted
## Compatible home/generation ID construction; no identity reroll on acquisition.

static func make(seed_value: int, home: Vector2i, species: String, generation: int = 0) -> String:
	if seed_value < 0 or seed_value > 2147483646 or absi(home.x) > 1000000 or absi(home.y) > 1000000 or generation < 0 or generation > 2147483647 or not SolSpeciesDefinition.text(species):
		return ""
	if generation == 0:
		return "%d:%d:%d:%s" % [seed_value, home.x, home.y, species]
	return "sol2:%d:%d:%d:%d:%s" % [seed_value, home.x, home.y, generation, species]

static func parse(identity: Variant) -> Dictionary:
	if not SolSpeciesDefinition.text(identity, 512):
		return {}
	var replacement: bool = identity.begins_with("sol2:")
	var parts: PackedStringArray = identity.split(":", true, 5 if replacement else 3)
	if parts.size() != (6 if replacement else 4):
		return {}
	var start := 1 if replacement else 0
	for index in range(start, start + (4 if replacement else 3)):
		if not parts[index].is_valid_int():
			return {}
	var seed_value := int(parts[start])
	var home := Vector2i(int(parts[start + 1]), int(parts[start + 2]))
	var generation := int(parts[4]) if replacement else 0
	var species: String = parts[5] if replacement else parts[3]
	if replacement and generation == 0:
		return {}
	if make(seed_value, home, species, generation) != identity:
		return {}
	return {"seed": seed_value, "home": [home.x, home.y], "species_id": species, "generation": generation}
