class_name StoryLedger
extends RefCounted
## Bounded saved facts and immutable event decisions; presentation never owns this state.
const MAX_RECORDS := 1024

static func empty() -> Dictionary:
	return {"facts": {}, "decisions": {}}

static func valid_key(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 96:
		return false
	for index in value.length():
		var code: int = value.unicode_at(index)
		if not (code >= 97 and code <= 122 or code >= 48 and code <= 57 or code in [95, 45, 46, 58]):
			return false
	return true

static func valid_facts(data: Variant) -> bool:
	if not data is Dictionary or data.size() > MAX_RECORDS:
		return false
	for key in data:
		if not valid_key(key) or not data[key] is String or data[key].is_empty() or data[key].length() > 160:
			return false
	return true

static func valid(data: Variant, tick: int) -> bool:
	if not data is Dictionary or data.size() != 2 or not valid_facts(data.get("facts")) or not data.get("decisions") is Dictionary or data.decisions.size() > MAX_RECORDS:
		return false
	for key in data.decisions:
		var row: Variant = data.decisions[key]
		if not valid_key(key) or not row is Dictionary or row.size() != 2 or not valid_key(row.get("choice")) or not SolSpeciesDefinition.whole(row.get("tick"), 0, tick):
			return false
	return true

static func matches(facts: Dictionary, required: Dictionary) -> bool:
	for key in required:
		if facts.get(key) != required[key]:
			return false
	return true

static func select(data: Dictionary, event: Resource, choice_id: String, tick: int) -> Dictionary:
	if event == null or not event.has_method("available_choices") or not valid(data, tick):
		return {}
	for choice in event.available_choices(data):
		if choice.id == choice_id:
			var candidate := data.duplicate(true)
			candidate.facts.merge(choice.sets, true)
			candidate.decisions[event.id] = {"choice": choice.id, "tick": tick}
			return candidate if valid(candidate, tick) else {}
	return {}
