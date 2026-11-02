extends SceneTree
## Grass placement uses canonical triangle surfaces and honors specialized lab terrain.
const Art = preload("res://scripts/scenery/meadow_art.gd")
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
class ReviewTerrain extends WorldTerrain:
 func surface_height(_point: Vector2) -> float: return 37.0
 func surface_normal(_point: Vector2) -> Vector3: return Vector3.UP
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var settings: NatureSettings = load("res://resources/nature_biomes.tres").duplicate(true)
 settings.meadow_divisions = 16
 var blades := 0
 for terrain: WorldTerrain in [WorldTerrain.new(17),WorldTerrain.new(2601026),ReviewTerrain.new(17)]:
  var chunk := Chunk.new()
  for y in range(-6,6):
   for x in range(-6,6):
    var cell := Vector2i(x,y)
    Art.add_cell(chunk,terrain,cell,terrain.sample(cell),settings,true)
  var count := 0
  for batch: Array in chunk.batches.values():
   for entry: Dictionary in batch:
    count += 1
    var at: Vector3 = entry.transform.origin
    var point := Vector2(at.x,at.z)
    check(absf(at.y-terrain.surface_height(point)) < 0.00001,"Grass roots match the terrain surface, including lab overrides")
    check(terrain.surface_normal(point).y >= 0.8,"Grass respects triangle slope admission")
  check(count > 0,"Each terrain fixture exercises actual blades")
  blades += count
  chunk.free()
 print("GRASS SURFACE: %d checks, %d blades, %d failures" % [checks,blades,failures])
 quit(0 if failures == 0 else 1)
