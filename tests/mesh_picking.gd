extends "res://tests/stutter_regressions.gd"
## Reuse exhaustive alpha picking to verify nearest-hit bin pruning.

func run() -> void:
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	image.set_pixel(1, 1, Color.TRANSPARENT)
	image.set_pixel(2, 2, Color.TRANSPARENT)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.albedo_texture = ImageTexture.create_from_image(image)
	var sphere := SphereMesh.new()
	sphere.radial_segments = 16
	sphere.rings = 8
	sphere.material = material
	var builder := SurfaceTool.new()
	builder.create_from(sphere, 0)
	builder.deindex()
	var unindexed := builder.commit()
	var box := BoxMesh.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 763190
	for mesh: Mesh in [sphere, unindexed, box]:
		var reference_mesh := mesh
		if mesh == unindexed:
			# The existing exhaustive helper expects an index buffer. Reindex
			# only its reference copy, leaving the production input unindexed.
			var reference_builder := SurfaceTool.new()
			reference_builder.create_from(mesh, 0)
			reference_builder.index()
			reference_mesh = reference_builder.commit()
		Picking.prepare(mesh)
		var rays: Array = []
		for row in Picking.surfaces[mesh.get_instance_id()]:
			for bin in row.bins:
				var bounds: AABB = bin.bounds
				# Include both boundary faces and the interior; an AABB hit from
				# inside must never be used as an entry-distance lower bound.
				for origin in [bounds.position, bounds.end, bounds.get_center()]:
					for direction in [Vector3.LEFT, Vector3.RIGHT, Vector3.UP, Vector3.DOWN, Vector3.FORWARD, Vector3.BACK]:
						rays.append([origin, direction])
		for index in range(600):
			var origin := Vector3(rng.randf_range(-2, 2), rng.randf_range(-2, 2), rng.randf_range(-2, 2))
			var target := Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.5))
			rays.append([origin, origin.direction_to(target)])
		for ray in rays:
			var expected: Variant = brute_ray(reference_mesh, ray[0], ray[1])
			var actual: Variant = Picking.ray(mesh, ray[0], ray[1])
			check((expected == null and actual == null) or (expected != null and actual != null and expected.is_equal_approx(actual)), "Pruned indexed/unindexed and alpha picking matches exhaustive triangles, including bin boundaries")
	print("MESH PICKING: %d checks, %d failures." % [checks, failures])
	quit(0 if failures == 0 else 1)
