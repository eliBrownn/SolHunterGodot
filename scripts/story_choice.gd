class_name StoryChoice
extends Resource
## Authored dialogue decision. No implicit rewards, relationship changes or quest rules.

@export var id := ""
@export_multiline var label := ""
## Required saved facts, expressed as exact string values. Empty means available.
@export var requires: Dictionary[String, String] = {}
## Facts assigned only after explicit selection. Closing dialogue assigns nothing.
@export var sets: Dictionary[String, String] = {}

func valid() -> bool:
	return StoryLedger.valid_key(id) and not label.strip_edges().is_empty() and label.length() <= 240 and StoryLedger.valid_facts(requires) and StoryLedger.valid_facts(sets)
