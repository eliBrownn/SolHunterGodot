class_name StoryEvent
extends Resource
## Reusable authored conversation/interaction. IDs remain stable across text revisions.

@export var id := ""
@export var title := ""
@export var speaker := ""
@export_multiline var text := ""
## Required saved facts; never infer NPC knowledge from a global discovery.
@export var requires: Dictionary[String, String] = {}
@export var choices: Array[StoryChoice] = []

func valid() -> bool:
	if not StoryLedger.valid_key(id) or title.strip_edges().is_empty() or title.length() > 160 or speaker.length() > 120 or text.strip_edges().is_empty() or text.length() > 12000 or not StoryLedger.valid_facts(requires) or choices.is_empty() or choices.size() > 8:
		return false
	var seen := {}
	for choice in choices:
		if choice == null or not choice.valid() or seen.has(choice.id):
			return false
		seen[choice.id] = true
	return true

func available(ledger: Dictionary) -> bool:
	return valid() and not ledger.decisions.has(id) and StoryLedger.matches(ledger.facts, requires)

func available_choices(ledger: Dictionary) -> Array[StoryChoice]:
	var result: Array[StoryChoice] = []
	if available(ledger):
		for choice in choices:
			if StoryLedger.matches(ledger.facts, choice.requires):
				result.append(choice)
	return result
