extends Node3D
## Adapter for the supplied FBX: only the base outfit is worn. Source props stay intact.

const SOURCE_PATH := "res://assets/characters/basic_man/basic_man.fbx"
const REST_HEIGHT := 1.871309
var skeleton: Skeleton3D

func prepare(height: float) -> void:
	if not ResourceLoader.exists(SOURCE_PATH):
		var body := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.height=REST_HEIGHT
		capsule.radius=0.25
		body.mesh=capsule
		body.position.y=REST_HEIGHT*0.5
		var material := StandardMaterial3D.new()
		material.albedo_color=Color("bdc9c4")
		body.material_override=material
		add_child(body)
		scale=Vector3.ONE*height/REST_HEIGHT
		return
	var imported: Node3D = load(SOURCE_PATH).instantiate()
	add_child(imported)
	scale = Vector3.ONE * height / REST_HEIGHT
	skeleton = imported.get_node("metarig/Skeleton3D")
	for mesh in imported.find_children("*", "MeshInstance3D"):
		mesh.visible = mesh.name == &"Body"

func animation_library() -> AnimationLibrary:
	var library := AnimationLibrary.new()
	for clip in ["Idle_A", "Walking_A", "Running_A"]:
		var animation := Animation.new()
		animation.length = 2.4 if clip == "Idle_A" else 1.2
		animation.loop_mode = Animation.LOOP_LINEAR
		if skeleton==null:
			library.add_animation(clip,animation)
			continue
		for side in ["L", "R"]:
			var bone := skeleton.find_bone("upper_arm." + side)
			var rest := skeleton.get_bone_global_rest(bone).basis.orthonormalized()
			var local_rest := skeleton.get_bone_rest(bone).basis.orthonormalized()
			var forward := skeleton.global_basis.orthonormalized().inverse() * Vector3.FORWARD
			var right := skeleton.global_basis.orthonormalized().inverse() * Vector3.RIGHT
			var lower := Basis(forward, deg_to_rad(70.0 if side == "L" else -70.0))
			var track := animation.add_track(Animation.TYPE_ROTATION_3D)
			animation.track_set_path(track, NodePath("%s:upper_arm.%s" % [get_path_to(skeleton), side]))
			for key in range(5):
				var phase := float(key) / 4.0
				var amplitude := 2.0 if clip == "Idle_A" else (18.0 if clip == "Walking_A" else 28.0)
				var swing := Basis(right, deg_to_rad(sin(phase * TAU) * amplitude * (1.0 if side == "L" else -1.0)))
				var rotation := local_rest * rest.inverse() * swing * lower * rest
				animation.rotation_track_insert_key(track, phase * animation.length, rotation.get_rotation_quaternion())
		library.add_animation(clip, animation)
	return library
