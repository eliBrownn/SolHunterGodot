extends Resource
## Rebuild-only object recipe. Dimensions use metres; no world placement is implied.
@export_enum("Barrier", "Corner", "Horseshoe", "Pillars", "Stepped outcrop", "Broken enclosure", "Monolith cluster", "Broken gateway", "Split ring", "Layered remnant") var family := 0
@export_range(0, 99999) var seed_value := 73
@export_range(2, 6) var length := 4
@export_range(1, 4) var courses := 3
@export_range(0.0, 1.0, 0.05) var brokenness := 0.3
@export_range(0, 12) var rubble_count := 5
@export_enum("Rock051", "Dark cliff", "Weathered rock", "Worn masonry", "Fractured rock") var surface_style := 0
@export_range(0.5, 4.0, 0.05) var object_scale := 1.0

func valid() -> bool:
	return surface_style in range(5) and rubble_count >= 0 and rubble_count <= 12 and family in range(10) and seed_value >= 0 and seed_value <= 99999 and length >= 2 and length <= 6 and courses >= 1 and courses <= 4 and is_finite(brokenness) and brokenness >= 0 and brokenness <= 1 and is_finite(object_scale) and object_scale >= 0.5 and object_scale <= 4
