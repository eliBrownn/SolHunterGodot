extends "res://tests/plant_diversity.gd"
const Chunk = preload("res://scripts/presentation/solid_chunk.gd")
class Hillside extends FlatTerrain:
	func surface_normal(_point: Vector2) -> Vector3: return Vector3(-0.6,1,0).normalized()
func run() -> void:
	Library.refresh()
	var hillside := Hillside.new(18)
	var cell := Vector2i(60,60)
	var body := Library.placement(hillside,cell,hillside.sample(cell),"tree",true)
	check(not body.is_empty(),"A steep canonical tree cell retains a visible procedural body")
	if not body.is_empty():
		check(body.bounds.position.x>=cell.x and body.bounds.end.x<=cell.x+1 and body.bounds.position.z>=cell.y and body.bounds.end.z<=cell.y+1,"Constrained sapling occupies only its canonical blocking cell")
		var chunk := Chunk.new()
		chunk.cell_origin=Vector2i(48,48)
		chunk.add_composed_nature(body)
		check(not chunk.batches.is_empty() and not chunk.pick_objects.is_empty(),"Sapling reaches rendering and picking")
		check(chunk.living_sources.has(cell) and body.flora_id==FloraCatalog.id_for(cell),"Sapling keeps the original registered tree identity")
		chunk.free()
	hillside.blocked=true
	check(Library.placement(hillside,cell,hillside.sample(cell),"tree",true).is_empty(),"Compact tree never bypasses a protected-space rejection")
	var trees := 0
	var compact := 0
	for seed_value in [17,2601026]:
		var terrain := WorldTerrain.new(seed_value)
		for y in range(-76,-28):
			for x in range(-24,24):
				var at := Vector2i(x,y)
				var data := terrain.sample(at)
				if data.ground==WorldTerrain.Ground.SAND:
					check(data.obstacle!=1,"Sand cannot admit an unsupported tree blocker")
				if data.obstacle!=1: continue
				var before := data.duplicate(true)
				var record := Library.placement(terrain,at,data,"tree",true)
				trees+=1
				check(not record.is_empty(),"Every generated tree blocker has a current visible body at %s, seed %d"%[at,seed_value])
				check(terrain.sample(at)==before and not terrain.is_walkable(at),"Tree presentation preserves canonical terrain and movement")
				if not record.is_empty():
					check(record.category=="tree" and record.flora_id==FloraCatalog.id_for(at),"Visible body belongs to the same canonical tree")
					if record.bounds.size.y<=1.5: compact+=1
	check(trees>20 and compact>0,"Coverage exercises real tree blockers and constrained saplings")
	print("TREE VISIBILITY: %d checks, %d trees, %d compact, %d failures"%[checks,trees,compact,failures])
	quit(0 if failures==0 else 1)
