extends NatureAssetEntry
## Exclusive entry snapshot: admission happened on the main owner.
var captured: Dictionary = {}

func admitted_model() -> Dictionary:
	return captured
