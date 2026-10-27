class_name PackArt
extends RefCounted
## Rectangles and pivots come from the supplied Unity metadata, converted offline.
static var manifest: Dictionary = {}
static var atlases: Dictionary = {}

static func entry(key: String) -> Dictionary:
	if manifest.is_empty():
		manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/basic-pack/sprites.json")).sprites
	return manifest[key]

static func atlas(key: String) -> AtlasTexture:
	if not atlases.has(key):
		var data := entry(key)
		var texture := AtlasTexture.new()
		texture.atlas = load("res://assets/basic-pack/" + data.texture)
		texture.region = Rect2(data.rect[0], data.rect[1], data.rect[2], data.rect[3])
		atlases[key] = texture
	return atlases[key]

static func sprite(key: String, anchor: Vector2 = Vector2.ZERO) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = atlas(key)
	node.centered = false
	var pivot: Array = entry(key).pivot
	node.offset = -Vector2(pivot[0], pivot[1])
	node.position = anchor
	return node

