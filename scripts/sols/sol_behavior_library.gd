class_name SolBehaviorLibrary
extends Resource
## Shared hierarchy; species choose branches, identity filters choose eligible descendants.

@export var definitions: Array[SolBehaviorDefinition] = []

func index() -> Dictionary:
	var result := {}
	for definition in definitions:
		if definition != null:
			result[definition.behavior_id] = definition
	return result

func lineage(id: String, entries: Dictionary) -> Array[SolBehaviorDefinition]:
	var chain: Array[SolBehaviorDefinition] = []
	var visited := {}
	while not id.is_empty():
		if visited.has(id) or not entries.has(id):
			return []
		visited[id] = true
		var definition: SolBehaviorDefinition = entries[id]
		chain.push_front(definition)
		id = definition.parent_id
	return chain

func valid() -> bool:
	var entries := index()
	if entries.size() != definitions.size():
		return false
	for definition in definitions:
		if definition == null or not definition.valid() or lineage(definition.behavior_id, entries).is_empty():
			return false
		var chain := lineage(definition.behavior_id, entries)
		# Ambient branches do not expose disconnected response controls.
		if chain[0].action in ["idle", "patrol"]:
			for field in SolBehaviorDefinition.LIMITS:
				if definition.get(field) != -1:
					return false
	return true

func action_for(id: String) -> String:
	var chain := lineage(id, index())
	return chain[0].action if not chain.is_empty() else ""

func select(branch: String, entry: Dictionary) -> Dictionary:
	var entries := index()
	var winner := {}
	for definition in definitions:
		var chain := lineage(definition.behavior_id, entries)
		var contains := false
		var eligible := true
		var specificity := 0
		for ancestor in chain:
			contains = contains or ancestor.behavior_id == branch
			eligible = eligible and ancestor.matches(entry)
			for filters in [ancestor.species_ids, ancestor.class_ids, ancestor.affinity_ids]:
				specificity += int(not filters.is_empty())
		if chain.is_empty() or not contains or not eligible:
			continue
		var rank := [definition.priority, specificity, chain.size()]
		var better := winner.is_empty()
		if not better:
			for i in range(3):
				if rank[i] != winner.rank[i]:
					better = rank[i] > winner.rank[i]
					break
				if i == 2:
					better = definition.behavior_id < winner.id
		if better:
			var overrides := {}
			for ancestor in chain:
				for field in SolBehaviorDefinition.LIMITS:
					if ancestor.get(field) != -1:
						overrides[field] = ancestor.get(field)
			winner = {"id": definition.behavior_id, "action": chain[0].action, "overrides": overrides, "rank": rank}
	return winner

func configuration() -> Array:
	var result: Array = []
	for definition in definitions:
		var fields: Array = []
		if definition != null:
			for field in preload("res://scripts/core/resource_storage_fields.gd").for_resource(definition):
				var value: Variant = definition.get(field)
				fields.append(value.duplicate() if value is PackedStringArray else value)
		result.append(fields)
	return result
