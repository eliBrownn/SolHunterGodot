extends Node
## Dedicated fresh-expedition review: begin beside the generated swimming home.
func _ready() -> void:
	get_parent().ready.connect(start_review, CONNECT_ONE_SHOT)

func start_review() -> void:
	var host := get_parent()
	var world: Node2D = host.world
	for member in host.sightings.members:
		if member.entry.species != "sol_species_0002":
			continue
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var at: Vector2i = member.home + direction * 2
			if world.terrain.fits(at):
				world.cell = at
				world.destination = at
				world.moving = false
				world.rebuild_world()
				world.message("Pond review: give Reedback room to wade and swim. Approach it to request a return to shore.", false)
				return
