extends SceneTree
## Rebuild compact mipmapped color layers from the licensed 2K source library.
func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Baking the texture array requires a graphics-enabled renderer; existing palette was preserved")
		quit(1)
		return
	var ids := ["Grass001", "Grass004", "Grass005", "Ground019", "Ground037", "Ground048", "Ground054", "Rock020", "Rock028", "Rock029", "Rock030", "Rock035", "Rock051"]
	var channels := ["Color", "NormalGL", "Displacement"] if OS.get_cmdline_user_args().has("--with-relief") else ["Color"]
	for channel in channels:
		bake_channel(ids, channel)
	quit()

func bake_channel(ids: Array, channel: String) -> void:
	var images: Array[Image] = []
	for id in ids:
		var image := Image.new()
		var bytes := FileAccess.get_file_as_bytes("res://assets/terrain/ambientcg/%s/%s_2K-JPG_%s.jpg" % [id.to_lower(), id, channel])
		if image.load_jpg_from_buffer(bytes) != OK:
			quit(1)
			return
		image.resize(512, 512, Image.INTERPOLATE_LANCZOS)
		image.convert(Image.FORMAT_RGB8)
		image.generate_mipmaps()
		images.append(image)
	var palette := Texture2DArray.new()
	if palette.create_from_images(images) != OK or ResourceSaver.save(palette, "res://resources/terrain_palette.res" if channel == "Color" else ("res://resources/terrain_normals.res" if channel == "NormalGL" else "res://resources/terrain_heights.res"), ResourceSaver.FLAG_COMPRESS) != OK:
		quit(1)
		return
	print("Baked 13 mipmapped 512px terrain %s layers" % channel)
