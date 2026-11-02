extends Resource
## Object-only blockout recipe. All dimensions are metres; rebuild to apply edits.
@export_enum("Boulder", "Root", "Fallen trunk", "Tree", "Bank", "Ridge", "Wall", "Arch") var family := 0
@export_range(0, 99999) var seed_value := 42
@export_range(0.25, 4.0, 0.05) var object_scale := 1.0
@export_range(0.0, 1.0, 0.05) var variation := 0.35

func valid() -> bool:
	return family >= 0 and family <= 7 and seed_value >= 0 and seed_value <= 99999 and is_finite(object_scale) and object_scale >= 0.25 and object_scale <= 4.0 and is_finite(variation) and variation >= 0 and variation <= 1
