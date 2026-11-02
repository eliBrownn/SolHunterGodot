extends "res://tools/review_cohesive_sample.gd"
func run() -> void:
	output_directory="res://artifacts/foliage-rollout"
	scene=load("res://scenes/world_3d.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	world=scene.world
	world.smoke_mode=true
	condition("clear")
	await fixture(Vector2i(-8,128))
	scene.target_size=8.0
	scene.view_elevation=20.0
	scene.apply_camera()
	await settle(90)
	await capture("pilot_walking_height")
	scene.environment.sky=null
	scene.free()
	print("FOLIAGE CLOSE REVIEW: %d failures"%failures.size())
	quit(1 if not failures.is_empty() else 0)
