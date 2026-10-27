class_name ClimateSettings
extends Resource
## Defaults for new expeditions; existing saves retain their own values.

@export_range(0.001, 0.1, 0.001) var moisture_frequency := 0.012
@export_range(0.0, 1.0, 0.01) var dry_threshold := 0.42
@export_range(0.0, 1.0, 0.01) var wet_threshold := 0.58

func parameters() -> Dictionary:
	return {"moisture_frequency": moisture_frequency, "dry_threshold": dry_threshold, "wet_threshold": wet_threshold}
