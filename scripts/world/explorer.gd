extends Node2D

var walking := false
var running := false
var facing := Vector2.DOWN
var elapsed := 0.0
var body: Sprite2D

func _ready() -> void:
	body = PackArt.sprite("TX Player/TX Player F")
	add_child(body)

func _process(delta: float) -> void:
	elapsed += delta
	var side := absf(facing.x) > absf(facing.y)
	var frame := "S" if side else ("B" if facing.y < 0 else "F")
	body.texture = PackArt.atlas("TX Player/TX Player " + frame)
	body.flip_h = side and facing.x < 0
	body.position.y = roundf(sin(elapsed * 17)) if walking else 0.0
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2(0, -2), 0, Vector2(11, 4))
	draw_circle(Vector2.ZERO, 1, Color(0.02, 0.04, 0.04, 0.35))
	draw_set_transform(Vector2.ZERO)
